import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/theme/app_colors.dart';
import 'package:ky_apps/core/widgets/report_a4_sheet.dart';
import 'package:ky_apps/core/widgets/report_zoom_view.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';
import 'package:ky_apps/features/stores/data/models/store_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/data/repositories/store_reports_repository.dart';
import 'package:ky_apps/features/stores/presentation/utils/report_columns.dart';
import 'package:ky_apps/features/stores/presentation/utils/report_parameters.dart';
import 'package:ky_apps/features/stores/presentation/utils/report_templates.dart';
import 'package:ky_apps/features/stores/presentation/widgets/multi_select_field.dart';
import 'package:ky_apps/features/stores/presentation/widgets/report_data_table.dart';

/// قالب تقارير المخازن: الأعمدة والمعطيات وحقول الاختيار المتعدد
/// The stores-report template: columns, parameters and the multi-select fields.
///
/// ── ما يحرسه هذا الملف هو ما شكا المستخدم منه ثلاث مرات: جدول لا يُظهر الفرع، وترويسة
///    تطبع تاريخين فقط من تسعة قيود، وحقل تصفية يعرض قائمته دائماً فلا تكفي الشاشة.
/// ── What this file guards is exactly what the user reported three times: a table with no
///    branch column, a header printing two of nine constraints, and a filter field that keeps
///    its list open so the screen never fits.
void main() {
  final from = DateTime(2026, 10, 1);
  final to = DateTime(2026, 10, 31);

  group('movement columns', () {
    test('offer a column for every dimension the parameters can filter', () {
      final ids = ReportColumns.movement().map((column) => column.id).toSet();

      expect(
        ids,
        containsAll(<String>[
          'no',
          'date',
          'doc',
          'type',
          'store',
          'item',
          'branch',
          'color',
          'group',
          'sub',
          'category',
          'unit',
          'in',
          'out',
          'net',
          'cost',
          'value',
        ]),
      );
    });

    test('number rows by position, not by contents', () {
      final columns = ReportColumns.movement();
      final serial = columns.firstWhere((column) => column.id == 'no');
      final row = StockMovementRow(sanfNo: 10);

      expect(serial.read(row, 0), '1');
      expect(serial.read(row, 41), '42');
    });

    test('name the branch only when the movement actually carries one', () {
      final branch = ReportColumns.movement().firstWhere(
        (column) => column.id == 'branch',
      );

      // حركة بلا P_CODE هي صنف عام لا فرع: النسبة هنا تعني «غير مطبَّق» لا «فارغ»
      // A movement with no P_CODE is a plain item, not a branch: a dash means "not applicable".
      expect(branch.read(StockMovementRow(sanfNo: 10), 0), '—');
      expect(
        branch.read(StockMovementRow(sanfNo: 10, sanfDno: 201, subName: 'أزرق فافي'), 0),
        'أزرق فافي',
      );
    });

    test('hide an optional column when the user unchecks it', () {
      final columns = ReportColumns.movement();
      final chosen = ReportColumns.defaultIds(columns).toSet()..remove('branch');

      final visible = ReportColumns.visible(columns, chosen);

      expect(visible.map((column) => column.id), isNot(contains('branch')));
      expect(visible.map((column) => column.id), contains('date'));
    });

    test('refuse an empty table by falling back to the defaults', () {
      final columns = ReportColumns.movement();

      // «لاشي» في الأعمدة تعني الافتراضي، لا جدولاً بلا أعمدة يرسم نفسه فارغاً
      // "None" for columns means the defaults, not a table with nothing in it.
      expect(ReportColumns.visible(columns, const <String>{}).length, greaterThan(1));
    });
  });

  group('summary columns', () {
    test('follow the aggregation level for caption and content', () {
      final byStore = ReportColumns.summary(StoreReportGroupBy.store);
      final label = byStore.firstWhere((column) => column.id == 'label');

      expect(label.label, 'المخزن');
      expect(label.read(StockSummaryRow(storeNo: 7, storeName: 'المخزن الرئيسي'), 0),
          'المخزن الرئيسي');

      final byGroup = ReportColumns.summary(StoreReportGroupBy.mainGroup);

      expect(
        byGroup.firstWhere((column) => column.id == 'label').label,
        'المجموعة الرئيسية',
      );
      expect(
        byGroup.firstWhere((column) => column.id == 'label').read(
              StockSummaryRow(groupName: 'أقمشة'),
              0,
            ),
        'أقمشة',
      );
    });

    test('keep the store column on when the level is item × store', () {
      final columns = ReportColumns.summary(StoreReportGroupBy.itemStore);
      final store = columns.firstWhere((column) => column.id == 'store');

      expect(store.defaultOn, isTrue);

      // صنف رئيسي وحده بلا مخزن في المفتاح: عمود المخزن اختياري لا أساسي
      // A bare main item has no store in its key: the store column is optional there.
      final byItem = ReportColumns.summary(StoreReportGroupBy.item);

      expect(
        byItem.firstWhere((column) => column.id == 'store').defaultOn,
        isFalse,
      );

      // الخلاصة بالمخزن وحده لا تحتاج عمود مخزن يكرر عمود العنوان
      // A store-level summary does not need a store column repeating its own label column.
      final byStore = ReportColumns.summary(StoreReportGroupBy.store);

      expect(
        byStore.firstWhere((column) => column.id == 'store').defaultOn,
        isFalse,
      );
    });

    test('offer a branch column only where the branch is the grouping key', () {
      final bySub = ReportColumns.summary(StoreReportGroupBy.sub);

      expect(
        bySub.firstWhere((column) => column.id == 'sub').defaultOn,
        isTrue,
      );

      final byItemStore = ReportColumns.summary(StoreReportGroupBy.itemStore);

      expect(
        byItemStore.firstWhere((column) => column.id == 'sub').defaultOn,
        isFalse,
      );
    });
  });

  group('parameters', () {
    test('print every dimension, naming the unconstrained ones', () {
      final parameters = ReportParameters.of(
        StoreReportFilter(from: from, to: to),
      );

      expect(parameters.length, greaterThanOrEqualTo(9));
      expect(
        parameters.where((p) => p.value == ReportParameters.unconstrained).length,
        greaterThanOrEqualTo(6),
      );
    });

    test('resolve chosen ids to their reference names', () {
      const reference = StoreReference(
        stores: [
          StoreModel(storeNo: 3, storeName: 'مخزن الأقمشة'),
        ],
        groups: [
          StoreGroupModel(groupNo: 7, groupName: 'أقمشة صوف'),
        ],
      );

      final parameters = ReportParameters.of(
        StoreReportFilter(
          from: from,
          to: to,
          storeNos: const [3],
          groupNos: const [7],
        ),
        reference: reference,
      );

      expect(
        parameters.firstWhere((p) => p.label == 'المخازن').value,
        'مخزن الأقمشة',
      );
      expect(
        parameters.firstWhere((p) => p.label == 'المجموعة الرئيسية').value,
        'أقمشة صوف',
      );
    });

    test('fall back to the raw id when a reference row is missing', () {
      // مرجع لا يعرّف المجموعة لا يعني تقريراً بلا معلومة: الرقم خير من الفراغ
      // A reference that lacks the group must not blank the report: an id beats nothing.
      final parameters = ReportParameters.of(
        StoreReportFilter(from: from, to: to, groupNos: const [999]),
      );

      expect(
        parameters.firstWhere((p) => p.label == 'المجموعة الرئيسية').value,
        '999',
      );
    });

    test('mark movement types inert inside a summary', () {
      final summary = ReportParameters.of(
        StoreReportFilter(
          kind: StoreReportKind.summary,
          from: from,
          to: to,
          movementTypeNos: const [12],
        ),
      );

      final types = summary.firstWhere((p) => p.label == 'أنواع الحركة');

      expect(types.isActive, isFalse);

      // القيد الحقيقي وحده يُحسب: وسم في شريط المعطيات لا يظهر وهو لا يعمل
      // Only live constraints count: a chip must not appear for something that does nothing.
      final movement = ReportParameters.of(
        StoreReportFilter(
          from: from,
          to: to,
          movementTypeNos: const [12],
        ),
      );

      expect(
        movement.firstWhere((p) => p.label == 'أنواع الحركة').isActive,
        isTrue,
      );
    });

    test('name the aggregation level for a summary only', () {
      expect(
        ReportParameters.of(
          StoreReportFilter(
            kind: StoreReportKind.summary,
            from: from,
            to: to,
            groupBy: StoreReportGroupBy.subGroup,
          ),
        ).any((p) => p.label == 'مستوى التجميع'),
        isTrue,
      );

      expect(
        ReportParameters.of(StoreReportFilter(from: from, to: to)).any(
          (p) => p.label == 'مستوى التجميع',
        ),
        isFalse,
      );
    });

    test('print the chosen item and branch by name, not by number', () {
      final parameters = ReportParameters.of(
        StoreReportFilter(
          from: from,
          to: to,
          sanfNo: 656,
          sanfName: 'قماش كوري',
          sanfDno: 201,
          sanfDnoLabel: 'كحلي 3×4',
        ),
      );

      expect(
        parameters.firstWhere((p) => p.label == 'الصنف الرئيسي').value,
        'قماش كوري',
      );
      expect(
        parameters.firstWhere((p) => p.label == 'الصنف الفرعي').value,
        'كحلي 3×4',
      );
    });
  });

  group('multi-select field', () {
    const options = [
      MultiOption('1', 'مخزن الأقمشة'),
      MultiOption('2', 'مخزن الإكسسوار'),
      MultiOption('3', 'مخزن التغليف'),
    ];

    Widget host(Widget child) => MaterialApp(
      locale: const Locale('ar', 'SA'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );

    testWidgets('shows "None" and keeps its list collapsed until opened', (tester) async {
      await tester.pumpWidget(
        host(
          const MultiSelectField(
            label: 'المخازن',
            options: options,
            selected: [],
            onChanged: _ignore,
          ),
        ),
      );

      // وجه الحقل وحده: لا Checkbox واحد قبل الفتح
      // Only the field face: not a single checkbox before it is opened.
      expect(find.text('لاشي'), findsOne);
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('المخازن'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsNWidgets(options.length));
    });

    testWidgets('summarises the selection instead of leaving a blank', (tester) async {
      await tester.pumpWidget(
        host(
          const MultiSelectField(
            label: 'المخازن',
            options: options,
            selected: ['2'],
            onChanged: _ignore,
          ),
        ),
      );

      expect(find.text('مخزن الإكسسوار'), findsOne);
      expect(find.text('لاشي'), findsNothing);
    });

    testWidgets('reports "all" rather than listing every name', (tester) async {
      await tester.pumpWidget(
        host(
          MultiSelectField(
            label: 'المخازن',
            options: [
              for (int i = 1; i <= 20; i++) MultiOption('$i', 'مخزن $i'),
            ],
            selected: [
              for (int i = 1; i <= 20; i++) '$i',
            ],
            onChanged: _ignore,
          ),
        ),
      );

      expect(find.text('الكل (20)'), findsOne);
    });

    testWidgets('clears back to "None" from the field itself', (tester) async {
      List<String> emitted = const [];

      await tester.pumpWidget(
        host(
          MultiSelectField(
            label: 'المخازن',
            options: options,
            selected: const ['1'],
            onChanged: (values) => emitted = values,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(emitted, isEmpty);
    });

    testWidgets('emits the toggled set when an option is picked', (tester) async {
      List<String>? emitted;

      await tester.pumpWidget(
        host(
          MultiSelectField(
            label: 'المخازن',
            options: options,
            selected: const ['1'],
            onChanged: (values) => emitted = values,
          ),
        ),
      );

      await tester.tap(find.text('المخازن'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('مخزن التغليف'));
      await tester.pump();

      expect(emitted, containsAll(<String>['1', '3']));
    });

    testWidgets('offers "none" and "all" shortcuts inside the panel', (tester) async {
      List<String>? emitted;

      await tester.pumpWidget(
        host(
          MultiSelectField(
            label: 'المخازن',
            options: options,
            selected: const ['1'],
            onChanged: (values) => emitted = values,
          ),
        ),
      );

      await tester.tap(find.text('المخازن'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('الكل'));
      await tester.pump();

      expect(emitted, hasLength(options.length));
    });
  });

  group('report templates', () {
    test('offers exactly the eight reports the user listed', () {
      expect(ReportTemplates.all, hasLength(8));

      final keys = {
        for (final t in ReportTemplates.all)
          '${t.scope.code}/${t.kind.code}',
      };

      // قالب واحد لكل نطاق وكل نوع: لا تكرار ولا نقص
      // One template per scope and kind: nothing repeated, nothing missing.
      expect(keys, hasLength(8));
    });

    test('the movement reports are titled by scope, in the words of the floor', () {
      expect(
        ReportTemplates.of(
          StoreReportFilter(
            scope: StoreReportScope.branch,
            from: from,
            to: to,
          ),
        ).title,
        'تقرير حركة صنف فرعي',
      );

      expect(
        ReportTemplates.of(
          StoreReportFilter(
            scope: StoreReportScope.mainGroup,
            kind: StoreReportKind.summary,
            from: from,
            to: to,
          ),
        ).title,
        'تقرير خلاصة مجموعة رئيسية',
      );
    });

    test('movement basics are the seven columns the floor reads', () {
      for (final template in ReportTemplates.all) {
        if (template.kind != StoreReportKind.movement) continue;

        expect(
          template.basic,
          containsAll(<String>['type', 'date', 'doc', 'qty', 'cost', 'value', 'balance']),
        );
      }
    });

    test('basics cannot be hidden and optional never repeats a basic', () {
      for (final template in ReportTemplates.all) {
        // لا عمود أساسي في القائمة الاختيارية: وإلا ظن المستخدم أنه يستطيع إخفاءه
        // No basic column may hide in the optional list, or the user would think it optional.
        expect(
          template.optional.toSet().intersection(template.basic.toSet()),
          isEmpty,
        );

        final visible = ReportTemplates.visibleIds(template, chosen: const {'no'});

        for (final id in template.basic) {
          expect(visible, contains(id));
        }
      }
    });

    test('only the wider movement reports split into sections', () {
      final branch = ReportTemplates.of(
        StoreReportFilter(from: from, to: to),
      );
      final item = ReportTemplates.of(
        StoreReportFilter(scope: StoreReportScope.item, from: from, to: to),
      );

      expect(branch.sectioned, isFalse);
      expect(item.sectioned, isTrue);

      // الخلاصة لا تُقسَّم أبداً: هي أصلاً أرقام مجمّعة لا سطور حركة
      // A summary is never sectioned: it is aggregated figures, not movement lines.
      for (final template in ReportTemplates.all) {
        if (template.kind == StoreReportKind.summary) {
          expect(template.sectioned, isFalse);
        }
      }
    });

    test('each summary offers only the groupings that make sense for it', () {
      StoreReportGroupBy first(StoreReportScope scope) => ReportTemplates.of(
        StoreReportFilter(
          kind: StoreReportKind.summary,
          scope: scope,
          from: from,
          to: to,
        ),
      ).groupings.first;

      expect(first(StoreReportScope.branch), StoreReportGroupBy.itemStore);
      expect(first(StoreReportScope.item), StoreReportGroupBy.sub);
      expect(first(StoreReportScope.subGroup), StoreReportGroupBy.item);
      expect(first(StoreReportScope.mainGroup), StoreReportGroupBy.subGroup);

      // خلاصة المجموعة الرئيسية تعرض أوسع قائمة تجميع: هي أعلى هرم الأسئلة
      // The main-group summary offers the widest list: it sits at the top of the question tree.
      expect(
        ReportTemplates.of(
          StoreReportFilter(
            kind: StoreReportKind.summary,
            scope: StoreReportScope.mainGroup,
            from: from,
            to: to,
          ),
        ).groupings,
        hasLength(8),
      );
    });

    test('grouping codes are the server whitelist tokens joined by a star', () {
      // الوسيط الذي يرسله العميل يجب أن يفكّه الخادم بالترميز نفسه، بلا ترجمة وسطى
      // What the client sends must decode on the server with the same tokens, no mapping layer.
      expect(StoreReportGroupBy.itemStore.code, 'item*store');
      expect(StoreReportGroupBy.subGroupItem.code, 'subgroup*item');
      expect(StoreReportGroupBy.groupSubGroup.code, 'group*subgroup');

      for (final level in StoreReportGroupBy.values) {
        for (final token in level.code.split('*')) {
          expect(
            <String>['item', 'sub', 'store', 'subgroup', 'group', 'category'],
            contains(token),
          );
        }
      }
    });
  });

  group('statistics from the server', () {
    test('a movement row carries its running balance and section', () {
      final row = StockMovementRow.fromJson(const <String, dynamic>{
        'I_CODE': '1991',
        'P_CODE': '10101052301',
        'P_QTY': '-3.28',
        'BALANCE_QTY': '120.5',
        'BALANCE_VALUE': '162340.5',
        'SECTION_KEY': '10101052301',
        'SECTION_LABEL': 'ابها ملون 11-1',
      });

      expect(row.balanceQty, 120.5);
      expect(row.balanceValue, 162340.5);
      expect(row.sectionKey, '10101052301');
      expect(row.sectionLabel, 'ابها ملون 11-1');
    });

    test('a summary row closes where it opened plus the period net', () {
      final row = StockSummaryRow.fromJson(const <String, dynamic>{
        'I_CODE': '1991',
        'OPENING_QTY': '10',
        'NET_QTY': '-2.5',
        'CLOSING_QTY': '7.5',
        'IN_VALUE': '1000',
        'OUT_VALUE': '250',
        'P_CODE': '201',
        'SUB_NAME': 'ازرق',
      });

      expect(row.openingQty, 10);
      expect(row.closingQty, 7.5);

      // الحالي = السابق + الصافي: مطابقة حسابية بلا اعتماد على مكتبة
      // Closing equals opening plus net: an arithmetic identity with no library needed.
      final drift = row.openingQty + row.netQty - row.closingQty;

      expect(drift > -0.0001 && drift < 0.0001, isTrue);
      expect(row.inValue, 1000);
      expect(row.subName, 'ازرق');
    });

    test('statistics parse the server meta for sections and totals', () {
      final result = StoreReportResult<StockMovementRow>(
        meta: <String, dynamic>{
          'scope': 'item',
          'totals': <String, dynamic>{
            'opening_qty': 100,
            'qty_in': 40,
            'qty_in_value': 12000,
            'qty_out': 15,
            'qty_out_value': 4500,
            'net_qty': 25,
            'closing_qty': 125,
            'closing_value': 7500,
            'rows': 17,
          },
          'sections': <dynamic>[
            <String, dynamic>{
              'key': '201',
              'label': 'فرع اول',
              'opening_qty': 60,
              'qty_in': 25,
              'qty_out': 5,
              'net_qty': 20,
              'closing_qty': 80,
              'rows': 9,
            },
            <String, dynamic>{
              'key': '202',
              'label': 'فرع ثاني',
              'opening_qty': 40,
              'qty_in': 15,
              'qty_out': 10,
              'net_qty': 5,
              'closing_qty': 45,
              'rows': 8,
            },
          ],
        },
      );

      expect(result.scope, 'item');
      expect(result.stats.closingQty, 125);
      expect(result.stats.qtyInValue, 12000);
      expect(result.sectionStats, hasLength(2));
      expect(result.sectionLabels, ['فرع اول', 'فرع ثاني']);

      // الإحصاءات تُقرأ من نفس القائمة: لا انفصال بين العنوان والرقم
      // Labels and stats come from one list: they can never drift apart.
      expect(result.sectionStats.first.closingQty, 80);
      expect(result.sectionStats.last.rows, 8);
    });
  });

  group('report table layout', () {
    // ── الحارس الذي كان ناقصاً: تمرير أفقي بلا عرض محدد يعطي `Table` عرضاً لانهائياً
    //   فينهار التخطيط على الجهاز فقط — والاختبارات السابقة كانت تفحص التعريف لا التخطيط.
    // ── The guard that was missing: a horizontal scroller without a definite width hands the
    //    `Table` an infinite width and the layout blows up on the device only — the earlier
    //    tests checked the column definition, never the layout itself.
    Widget sheet(Widget body) => MaterialApp(
      locale: const Locale('ar', 'SA'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SizedBox(
            width: 360,
            height: 720,
            child: ReportZoomView(
              child: SingleChildScrollView(
                child: ReportA4Sheet(body: body),
              ),
            ),
          ),
        ),
      ),
    );

    List<ReportColumn<StockMovementRow>> picked(List<String> ids) {
      // بلا `.cast<Object>`: القارئ يفقد نوعه وقت التشغيل فتفشل كل خلية
      // No .cast<Object>: an erased reader loses its type at runtime and every cell fails.
      return ReportColumns.visible(ReportColumns.movement(), ids.toSet());
    }

    // صفوف نموذجية: سطر صادر بقيمة سالبة وسطر وارد — تغطي الحالتين معًا
    // Sample rows: one outbound line with a negative value and one inbound — both at once.
    final rows = <StockMovementRow>[
      StockMovementRow(
        sanfNo: 1991,
        sanfDno: 10101052301,
        itemName: 'ابها ملون ع58-1',
        storeName: 'المحل الرئيسي',
        typeName: 'منصرف للقص',
        subName: 'ابها ملون ع58-11-1',
        qtyOut: 3.28,
        netQty: -3.28,
        lineValue: -4418.39,
      ),
      StockMovementRow(
        sanfNo: 1219,
        itemName: 'قماش كوري',
        storeName: 'مخزن البيت',
        qtyIn: 12,
        netQty: 12,
        lineValue: 15000,
      ),
    ];

    testWidgets('renders the default columns without throwing', (tester) async {
      await tester.pumpWidget(
        sheet(
          ReportDataTable<StockMovementRow>(
            columns: picked(ReportColumns.defaultIds(ReportColumns.movement())),
            rows: rows,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('الصنف'), findsWidgets);
      expect(find.text('ابها ملون ع58-1'), findsWidgets);
      // الترقيم من موضع الصف لا من محتواه
      // Numbering comes from position, not contents.
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('renders every column at once — the case that crashed', (tester) async {
      await tester.pumpWidget(
        sheet(
          ReportDataTable<StockMovementRow>(
            columns: picked(ReportColumns.allIds(ReportColumns.movement())),
            rows: rows,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // عمود لا يظهر إلا عند طلبه صراحةً: اللون والمجموعة والفئة
      // Columns that only appear when asked for explicitly: colour, group, category.
      expect(find.text('اللون'), findsWidgets);
      expect(find.text('الفئة'), findsWidgets);
    });

    testWidgets('keeps a negative value visible and marked as a risk', (tester) async {
      await tester.pumpWidget(
        sheet(
          ReportDataTable<StockMovementRow>(
            // الصافي عمود اختياري في الافتراضي، ويُطلب هنا صراحةً ليحمل السالب
            // The net column is off by default; it is asked for explicitly to carry the negative.
            columns: picked([
              ...ReportColumns.defaultIds(ReportColumns.movement()),
              'net',
            ]),
            rows: rows,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('-3.28'), findsWidgets);
      expect(find.text('-4,418.39'), findsWidgets);

      // السالب لا يُطبع بلون عادي: الرصيد السالب علامة مراجعة في المخزون
      // A negative is not printed in an ordinary colour: under-zero stock is a review flag.
      final cell = tester.widget<Text>(find.text('-3.28').first);

      expect(cell.style?.color, AppColors.error);
      expect(cell.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('fills the width without a horizontal scroller', (tester) async {
      await tester.pumpWidget(
        sheet(
          ReportDataTable<StockMovementRow>(
            columns: picked(ReportColumns.allIds(ReportColumns.movement())),
            rows: rows,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // الجدول يأخذ عرضه كاملاً: لا ScrollView أفقي يهدي `Table` عرضًا لانهائيًا
      // The table takes its full width: no horizontal viewport feeding Table an infinite width.
      expect(
        find.descendant(
          of: find.byType(ReportDataTable<StockMovementRow>),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('grows with its rows instead of a fixed inner scroller', (tester) async {
      // صفوف كثيرة: يجب أن تتمدّد على الصفحة لا أن تُحبس في صندوق بتمرير داخلي
      // Many rows: they must extend down the page, not get locked in an inner scrolling box.
      final many = <StockMovementRow>[
        for (int i = 0; i < 40; i++)
          StockMovementRow(
            sanfNo: 1000 + i,
            itemName: 'صنف $i',
            qtyIn: 1,
            netQty: 1,
          ),
      ];

      await tester.pumpWidget(
        sheet(
          ReportDataTable<StockMovementRow>(
            columns: picked(const ['no', 'item']),
            rows: many,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // لا تمرير داخلي ولا شريط تمرير داخل الجدول: الصفحة وحدها تتمّر
      // No inner scrolling and no scrollbar inside the table: only the page moves.
      expect(
        find.descendant(
          of: find.byType(ReportDataTable<StockMovementRow>),
          matching: find.byType(Scrollbar),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(ReportDataTable<StockMovementRow>),
          matching: find.byType(ListView),
        ),
        findsNothing,
      );

      // كل الصفوف موجودة في الشجرة: لا صفحة مبتورة ولا سطر مفقود
      // Every row exists in the tree: no truncated document and no lost line.
      expect(find.text('صنف 39'), findsOne);
      expect(find.text('40'), findsWidgets);
    });
  });

  group('report title', () {
    const reference = StoreReference(
      stores: [
        StoreModel(storeNo: 1, storeName: 'المحل الرئيسي'),
        StoreModel(storeNo: 3, storeName: 'مخزن البيت'),
      ],
      groups: [
        StoreGroupModel(groupNo: 1, groupName: 'الاقمشة والمواد الخام'),
      ],
      types: [
        StoreTypeModel(typeNo: 101, typeName: 'الاقمشة', groupNo: 1),
      ],
    );

    test('names the narrowest chosen dimension, branch first', () {
      final title = ReportTitles.of(
        StoreReportFilter(
          from: from,
          to: to,
          sanfNo: 1991,
          sanfName: 'ابها ملون',
          sanfDno: 10101052301,
          sanfDnoLabel: 'ابها ملون 11-1',
        ),
        reference: reference,
      );

      expect(title.headline, 'كشف حركة صنف فرعي : ابها ملون 11-1');
    });

    test('falls back through item then sub group then main group', () {
      expect(
        ReportTitles.of(
          StoreReportFilter(from: from, to: to, sanfNo: 1991, sanfName: 'ابها ملون'),
          reference: reference,
        ).headline,
        'كشف حركة صنف : ابها ملون',
      );

      expect(
        ReportTitles.of(
          StoreReportFilter(from: from, to: to, itemTypeNos: const [101]),
          reference: reference,
        ).headline,
        'كشف حركة مجموعة فرعية : الاقمشة',
      );

      expect(
        ReportTitles.of(
          StoreReportFilter(from: from, to: to, groupNos: const [1]),
          reference: reference,
        ).headline,
        'كشف حركة مجموعة رئيسية : الاقمشة والمواد الخام',
      );

      // لا تخصيص: العنوان يبقى بلا قيمة مضافة، لا «: » معلّقة في الهواء
      // Unconstrained: the title carries no dangling colon with nothing after it.
      expect(
        ReportTitles.of(StoreReportFilter(from: from, to: to)).headline,
        'كشف حركة المخازن',
      );
    });

    test('uses the summary wording for a summary report', () {
      final title = ReportTitles.of(
        StoreReportFilter(
          kind: StoreReportKind.summary,
          from: from,
          to: to,
          groupNos: const [1],
        ),
        reference: reference,
      );

      expect(title.headline, 'خلاصة حركة مجموعة رئيسية : الاقمشة والمواد الخام');
    });

    test('shows the period only when the user customised it', () {
      final plain = StoreReportFilter(from: from, to: to);
      final custom = plain.copyWith(customPeriod: true);

      expect(ReportTitles.of(plain).period, isNull);
      expect(ReportTitles.of(custom).period, '2026-10-01 — 2026-10-31');
    });

    test('shows the stores line only when stores were narrowed', () {
      final all = ReportTitles.of(StoreReportFilter(from: from, to: to));
      final some = ReportTitles.of(
        StoreReportFilter(from: from, to: to, storeNos: const [1, 3]),
        reference: reference,
      );

      expect(all.stores, isNull);
      expect(some.stores, 'من مخزن: المحل الرئيسي، مخزن البيت');
    });

    test('keeps the statement title identical to the printed one', () {
      // الشاشة والـ PDF يبنيان العنوان من نفس الدالة فلا يتفارق مستندان
      // The screen and the PDF build the title from one function, so two documents cannot drift.
      final branch = ReportTitles.statement(
        itemName: 'ابها ملون',
        branchLabel: 'ابها ملون 11-1',
        branchOnly: true,
      );
      final item = ReportTitles.statement(
        itemName: 'ابها ملون',
        branchLabel: 'كل الفروع',
        branchOnly: false,
      );

      expect(branch.headline, 'كشف حركة صنف فرعي : ابها ملون 11-1');
      expect(item.headline, 'كشف حركة صنف : ابها ملون');
      expect(item.period, isNull);
    });
  });

  group('sub group cascade', () {
    const reference = StoreReference(
      groups: [
        StoreGroupModel(groupNo: 1, groupName: 'أقمشة'),
        StoreGroupModel(groupNo: 2, groupName: 'إكسسوار'),
      ],
      types: [
        StoreTypeModel(typeNo: 10, typeName: 'صوف', groupNo: 1),
        StoreTypeModel(typeNo: 11, typeName: 'قطن', groupNo: 1),
        StoreTypeModel(typeNo: 20, typeName: 'أزرار', groupNo: 2),
      ],
    );

    test('narrows sub groups to the chosen main groups', () {
      expect(
        reference.typesOfGroups(const [2]).map((type) => type.typeNo),
        [20],
      );

      expect(
        reference.typesOfGroups(const [1, 2]).map((type) => type.typeNo),
        [10, 11, 20],
      );
    });

    test('treats "None" as no constraint, not as an empty list', () {
      // فارغ في الحقل يعني كل الفروع، وإلا كان الافتراضي تقريراً أبداً بلا نتائج
      // An empty field means every sub group; otherwise the default report would always be
      // empty.
      expect(reference.typesOfGroups(const []), hasLength(3));
    });

    test('never repeats a sub group that two main groups share', () {
      const shared = StoreReference(
        types: [
          StoreTypeModel(typeNo: 5, typeName: 'موحد', groupNo: 1),
          StoreTypeModel(typeNo: 5, typeName: 'موحد', groupNo: 2),
        ],
      );

      expect(shared.typesOfGroups(const [1, 2]), hasLength(1));
    });
  });
}

void _ignore(List<String> values) {}
