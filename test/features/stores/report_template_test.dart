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
import 'package:ky_apps/features/stores/presentation/utils/report_totals.dart';
import 'package:ky_apps/features/stores/presentation/utils/store_export.dart';
import 'package:ky_apps/features/stores/presentation/widgets/multi_select_field.dart';
import 'package:ky_apps/features/stores/presentation/widgets/report_data_table.dart';
import 'package:ky_apps/features/stores/presentation/widgets/report_stats_band.dart';
import 'package:ky_apps/features/stores/presentation/widgets/store_ui.dart';

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
        bySub.firstWhere((column) => column.id == 'branch').defaultOn,
        isTrue,
      );

      final byItemStore = ReportColumns.summary(StoreReportGroupBy.itemStore);

      expect(
        byItemStore.firstWhere((column) => column.id == 'branch').defaultOn,
        isFalse,
      );
    });
  });

  group('column order', () {
    test('draw the columns in the user order, not the template order', () {
      final ordered = ReportColumns.ordered(
        ReportColumns.movement(),
        const ['balance', 'date', 'qty'],
      );

      expect(
        ordered.map((column) => column.id).toList(),
        ['balance', 'date', 'qty'],
      );
    });

    test('drop an id the template does not know instead of drawing a blank column', () {
      final ordered = ReportColumns.ordered(
        ReportColumns.movement(),
        const ['tax', 'balance'],
      );

      expect(ordered.map((column) => column.id).toList(), ['balance']);
    });

    test('fall back to the defaults when nothing survives', () {
      final columns = ReportColumns.movement();

      // جدول بلا أعمدة مستحيل: معرّفات لا تخصّه تعني الافتراضي لا جدولاً فارغاً
      // A column-less table is impossible: foreign ids mean the defaults, not an empty grid.
      expect(
        ReportColumns.ordered(columns, const ['tax']).map((column) => column.id),
        ReportColumns.defaultIds(columns),
      );
    });
  });

  group('totals and statistics', () {
    test('sum the quantity and money columns of a movement, never cost or balance', () {
      final totals = ReportTotals.movement(const [
        StockMovementRow(
          sanfNo: 10,
          qtyIn: 10,
          qtyOut: 4,
          netQty: 6,
          cost: 20,
          lineValue: 120,
          balanceQty: 99,
        ),
        StockMovementRow(
          sanfNo: 10,
          qtyIn: 5,
          qtyOut: 1,
          netQty: 4,
          cost: 20,
          lineValue: 80,
          balanceQty: 103,
        ),
      ]);

      expect(totals['no'], '2');
      expect(totals['in'], '15');
      expect(totals['out'], '5');
      expect(totals['qty'], '10');
      expect(totals['value'], '200.00');

      // التكلفة سعر وحدة والرصيد رقم متراكم: جمعهما يقول رقماً كاذباً
      // Cost is a unit price and the balance already accumulates: summing either lies.
      expect(totals.containsKey('cost'), isFalse);
      expect(totals.containsKey('balance'), isFalse);
    });

    test('sum the closing balances of a summary but never the unit cost', () {
      final totals = ReportTotals.summary(const [
        StockSummaryRow(
          sanfNo: 10,
          qtyIn: 10,
          qtyOut: 4,
          netQty: 6,
          cost: 20,
          netValue: 120,
          openingQty: 30,
          closingQty: 36,
          inValue: 200,
          outValue: 80,
        ),
      ]);

      expect(totals['opening'], '30');
      expect(totals['balance'], '36');
      expect(totals['inValue'], '200.00');
      expect(totals['outValue'], '80.00');
      expect(totals.containsKey('cost'), isFalse);
    });

    test('build the statistics fields under the ids the columns sheet hides', () {
      const stats = ReportStats(
        openingQty: 12,
        qtyIn: 40,
        qtyOut: 25,
        netQty: 15,
        closingQty: 27,
        closingValue: 0,
        rows: 8,
      );

      final fields = ReportStatFields.of(stats);

      expect(fields.map((field) => field.id), containsAll(<String>['opening', 'in']));
      // قيمة صفرية لا تملأ شريطاً مختصراً بضجيج
      // A zero value must not fill a compact strip with noise.
      expect(fields.any((field) => field.id == 'closingValue'), isFalse);

      // الإخفاء بالمعرّف نفسه: ما أخفاه المستخدم لا يعود من طريق آخر
      // Hiding works by the same id: what the user hid does not return by another route.
      final kept = ReportStatFields.visible(fields, const ['in', 'net']);

      expect(kept.map((field) => field.id).toList(), ['in', 'net']);
      expect(ReportStatFields.visible(fields, const []), isEmpty);
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

    test('keep every id unique and start from the basics, never lock them', () {
      for (final template in ReportTemplates.all) {
        // معرّف مكرّر يجعل اختيار المستخدم والترتيب وقراءة الجدول تلتقط العمود الخطأ
        // A repeated id makes the user's pick, the order and the table's reader resolve the
        // wrong column — the reason the summary branch id changed from `sub` to `branch`.
        expect(template.basic.toSet().length, template.basic.length);
        expect(template.optional.toSet().length, template.optional.length);

        // لا عمود في القائمتين معاً: العمود إما أساسي وإما اختياري، لا الاثنان
        // No column lives in both lists: a column is either basic or optional.
        expect(
          template.optional.toSet().intersection(template.basic.toSet()),
          isEmpty,
        );

        // الأساسيات هي نقطة البداية، ويستطيع المستخدم إخفاءها بعد ذلك
        // The basics are the starting point, and the user may hide them afterwards.
        expect(template.defaultIds, template.basic);
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

  // ── الشكوى: عند تكبير الشاشة والخط تخرج رؤوس الأعمدة عن مواضعها وتتشوّه أرقام النهاية.
  //    الجذر أن الخانة كانت تلتفّ: «المستند» تُكسر إلى «المستن» و«د»، و«-12,985.76» تُقسم
  //    نصفين، فيختلف ارتفاع الصف وتنزاح الخانات. الحل: سطر واحد ثابت الارتفاع يوافق خانته.
  // ── The complaint: enlarging the screen and the font pushed the headings out of place and
  //    deformed the closing figures. The root cause was wrapping: a caption broke in half and
  //    a figure split across two lines, so rows changed height and cells drifted. The fix: one
  //    line of fixed height that fits its own cell.
  group('table geometry', () {
    Widget frame(
      Widget body, {
      double width = 380,
      double scale = 1.25,
    }) {
      return MaterialApp(
        locale: const Locale('ar', 'SA'),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: SizedBox(width: width, child: body),
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<ReportColumn<StockMovementRow>> picked(List<String> ids) {
      return ReportColumns.visible(ReportColumns.movement(), ids.toSet());
    }

    const layoutIds = <String>[
      'type',
      'date',
      'doc',
      'qty',
      'cost',
      'value',
      'balance',
    ];

    final rows = <StockMovementRow>[
      StockMovementRow(
        typeName: 'منصرف للقص',
        date: DateTime(2026, 10, 12),
        docNo: 10101052301,
        qtyOut: 3.28,
        netQty: -3.28,
        cost: 1347.07,
        lineValue: -4418.39,
        balanceQty: 437.29,
      ),
      StockMovementRow(
        typeName: 'منصرف للقص',
        date: DateTime(2026, 10, 17),
        docNo: 10101052303,
        qtyOut: 2.69,
        netQty: -2.69,
        cost: 1347.07,
        lineValue: -3623.62,
        balanceQty: 434.6,
      ),
    ];

    testWidgets('every cell stays on one line under a large font on a phone', (
      tester,
    ) async {
      await tester.pumpWidget(
        frame(
          ReportDataTable<StockMovementRow>(
            columns: picked(layoutIds),
            rows: rows,
            opening: const {'balance': '440.57'},
            totals: const {
              'qty': '-9.64',
              'value': '-12,985.76',
              'balance': '430.93',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final cells = find.descendant(
        of: find.byType(ReportDataTable<StockMovementRow>),
        matching: find.byType(Text),
      );

      for (final widget in tester.widgetList<Text>(cells)) {
        // سطر واحد دائماً: الالتفاف هو ما شوّه الرأس وقسم الرقم
        // Always one line: wrapping is what deformed the head and split the figure.
        expect(widget.maxLines, 1);
        expect(widget.softWrap, isFalse);
      }
    });

    testWidgets('the head, the opening, the rows and the totals are one cell tall', (
      tester,
    ) async {
      await tester.pumpWidget(
        frame(
          ReportDataTable<StockMovementRow>(
            columns: picked(layoutIds),
            rows: rows,
            opening: const {'balance': '440.57'},
            totals: const {'balance': '430.93'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // ارتفاع الخانة واحد في كل الكتل: لا صف أعلى من صف، ولا صف يُكسَر نصفين.
      // (خط الاختبار مربّع بعرض 1em للحرف، فلا يُقاس عليه تصغير الرأس في التطبيق.)
      // One cell height in every block: no row taller than another and none split in two.
      // (The harness font is square at 1em per glyph, so the real heading fit is not
      // measurable here — the invariant guarded is the uniform height.)
      double heightOf(String text) => tester
          .getRect(
            find.ancestor(
              of: find.text(text).first,
              matching: find.byType(Container),
            ).first,
          )
          .height;

      final heights = <double>[
        heightOf('المستند'), // الرأس — the head
        heightOf('440.57'), // الافتتاح — the opening
        heightOf('منصرف للقص'), // سطر حركة — a movement row
        heightOf('الإجمالي'), // المجاميع — the totals
      ];

      for (final height in heights) {
        // فرق عشر البكسل تسامح حسابي لا اختلاف تصميم
        // A tenth of a pixel is arithmetic slack, not a design difference.
        expect(height, closeTo(heights.first, 0.1));
      }

      expect(heights.first, greaterThan(10));
    });

    testWidgets('the head and the totals row share the same column track', (
      tester,
    ) async {
      await tester.pumpWidget(
        frame(
          ReportDataTable<StockMovementRow>(
            columns: picked(layoutIds),
            rows: rows,
            opening: const {'balance': '440.57'},
            totals: const {'balance': '430.93'},
          ),
          width: 1100,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // الرأس والمجاميع كتلتان مستقلتان: بكسلات محسوبة مرة واحدة تجعلهما على مسار واحد.
      // نقارن حدود الخانة لا مركز النص، لأن الرأس الرقمي في الوسط والأرقام في الطرف.
      // The head and the totals are separate blocks: pixels computed once put both on one
      // track. The cell's bounds are compared, not the text's centre, because a numeric
      // heading sits in the middle while its figures sit at the line's end.
      Rect trackOf(String text) => tester.getRect(
        find.ancestor(of: find.text(text).first, matching: find.byType(Container)).first,
      );

      final head = trackOf('الرصيد');
      final total = trackOf('430.93');

      expect(head.left, closeTo(total.left, 1.0));
      expect(head.right, closeTo(total.right, 1.0));
    });

    testWidgets('a negative figure reads left to right, minus first', (
      tester,
    ) async {
      await tester.pumpWidget(
        frame(
          ReportDataTable<StockMovementRow>(
            columns: picked(layoutIds),
            rows: rows,
            totals: const {'qty': '-9.64'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // اتجاه الواجهة عربي، والرقم لا يُقلب: «-3.28» ولا «3.28-»
      // The interface is Arabic, but the figure is not mirrored: "-3.28", never "3.28-".
      final cell = tester.widget<Text>(find.text('-3.28').first);

      expect(cell.textDirection, TextDirection.ltr);
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

  group('section unit of every scope', () {
    // ── الحارس الذي كان ناقصاً: التقرير الموسّع كان يعرض «القسم» دائماً، فيبدو «حركة صنف
    //    رئيسي» مطابقاً لـ«حركة صنف فرعي» — والتقارير الأربعة إنما وُجدت ليفترق بعضها عن بعض.
    // ── The guard that was missing: a scoped report always said "القسم", so an item statement
    //    read exactly like a branch statement — and these four reports exist to differ.
    test('names the element each movement report splits by', () {
      expect(StoreReportScope.branch.sectionLabel, 'الصنف الفرعي');
      expect(StoreReportScope.item.sectionLabel, 'الصنف الفرعي');
      expect(StoreReportScope.subGroup.sectionLabel, 'الصنف الرئيسي');
      expect(StoreReportScope.mainGroup.sectionLabel, 'المجموعة الفرعية');
    });

    test('plurals title the closing total, never a singular', () {
      expect(StoreReportScope.item.sectionPlural, 'الأصناف الفرعية');
      expect(StoreReportScope.subGroup.sectionPlural, 'الأصناف الرئيسية');
      expect(StoreReportScope.mainGroup.sectionPlural, 'المجموعات الفرعية');
    });

    test('the section unit differs from the report it is opened from', () {
      // كل تقرير يجمّع ما دونه: الصنف الرئيسي يجمع فروعه، والمجموعة الرئيسية مجموعاتها
      // Every report aggregates what sits beneath it, never itself.
      for (final scope in StoreReportScope.values) {
        if (!scope.sectioned) continue;
        expect(scope.sectionLabel, isNot(scope.label));
      }
    });
  });

  group('opening balance', () {
    test('is the first figure of the balance column, not zero', () {
      final stats = ReportStats.fromMap(const <String, dynamic>{
        'opening_qty': 251711.69,
        'opening_value': 900000,
        'qty_in': 18135.32,
        'qty_out': 7890.02,
        'net_qty': 10245.3,
        'closing_qty': 261956.99,
      });

      expect(stats.openingQty, 251711.69);
      expect(stats.openingValue, 900000);

      // السطر الأول يحمل نفس رقم الافتتاح لا صفراً
      // The opening line carries the opening figure itself, never a zero.
      final line = ReportTotals.opening(stats);

      expect(line['balance'], StoreFormat.qty(251711.69));
      expect(line['balanceValue'], StoreFormat.money(900000));
    });

    test('leaves the value column empty when no value balance exists', () {
      final line = ReportTotals.opening(
        const ReportStats(openingQty: 40),
      );

      expect(line['balance'], '40');
      // حقل قيمة لا رقم له لا يُملأ برقم مُختلق
      // A value with no figure behind it is never filled with an invented one.
      expect(line.containsKey('balanceValue'), isFalse);
    });

    testWidgets('prints a "رصيد سابق" line above the first movement', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar', 'SA'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                width: 360,
                height: 720,
                child: ReportZoomView(
                  child: SingleChildScrollView(
                    child: ReportA4Sheet(
                      body: ReportDataTable<StockMovementRow>(
                        columns: ReportColumns.visible(
                          ReportColumns.movement(),
                          ReportColumns.defaultIds(
                            ReportColumns.movement(),
                          ).toSet(),
                        ),
                        rows: <StockMovementRow>[
                          StockMovementRow(
                            itemName: 'قماش كوري',
                            typeName: 'وارد شراء',
                            qtyIn: 12,
                            netQty: 12,
                            balanceQty: 252,
                            lineValue: 15000,
                          ),
                        ],
                        opening: const <String, String>{'balance': '240'},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('رصيد سابق'), findsOneWidget);
      expect(find.text('240'), findsOneWidget);
    });
  });

  group('section keys', () {
    test('are read beside the labels so stats pair with their rows', () {
      final result = StoreReportResult<StockMovementRow>(
        meta: const <String, dynamic>{
          'scope': 'subgroup',
          'sections': [
            <String, dynamic>{
              'key': '11',
              'label': 'قطن صيفي',
              'opening_qty': 6.05,
              'closing_qty': 5.95,
            },
            <String, dynamic>{
              'key': '16',
              'label': 'سوبر',
              'opening_qty': 8,
              'closing_qty': 4.44,
            },
          ],
        },
      );

      expect(result.sectionKeys, ['11', '16']);
      expect(result.sectionLabels, ['قطن صيفي', 'سوبر']);
      expect(result.sectionStats.last.openingQty, 8);
    });
  });

  // ── إحصاء القسم سطر لا تقرير: أربعة أرقام فقط، بلا «السطور» ولا «الصافي» ولا قيم
  // ── A section's statistics are a line, not a report: four figures only, with no rows,
  //    net or value fields copied down from the report summary.
  group('section statistics', () {
    const stats = ReportStats(
      openingQty: 240,
      openingValue: 1200,
      qtyIn: 50,
      qtyInValue: 500,
      qtyOut: 30,
      qtyOutValue: 300,
      netQty: 20,
      closingQty: 260,
      closingValue: 1400,
      rows: 9,
    );

    test('are exactly the four figures a section is asked about', () {
      final ids = ReportStatFields.section(stats).map((field) => field.id);

      expect(ids, ['opening', 'in', 'out', 'closing']);
      expect(ReportStatFields.sectionIds, ['opening', 'in', 'out', 'closing']);

      // ما ليس من الأربعة يسقط: التقرير وحده هو من يُسأل عن قيم الوارد والمنصرف
      // Whatever is not one of the four drops out: only the report is asked about values.
      for (final surplus in ['rows', 'net', 'inValue', 'outValue', 'closingValue']) {
        expect(ids, isNot(contains(surplus)));
      }
    });

    test('print as four figures and nothing else', () {
      // لا «الصافي» ولا «قيمة الرصيد» في الورق: نص السطر يطابق الشاشة حرفاً بحرف
      // No net and no closing value on paper: the line matches the screen word for word.
      final line = sectionStatsLine(stats, null);

      expect(line, 'السابق 240 · الوارد 50 · المنصرف 30 · الرصيد الحالي 260');
      expect(line.contains('الصافي'), isFalse);
      expect(line.contains('قيمة'), isFalse);
    });

    test('drop a figure the user hid, and only that one', () {
      // حقل أخفاه المستخدم لا يعود من أي منفذ — شاشة أو ورق
      // A field the user hid never comes back through any output.
      expect(
        sectionStatsLine(stats, const ['opening', 'closing']),
        'السابق 240 · الرصيد الحالي 260',
      );
    });

    testWidgets('are drawn on one line instead of a full report strip',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar', 'SA'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ReportStatsBand.compact(
                title: 'إحصاءات الصنف الفرعي',
                fields: ReportStatFields.section(stats),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('إحصاءات الصنف الفرعي'), findsOneWidget);
      expect(find.text('السابق'), findsOneWidget);
      expect(find.text('الرصيد الحالي'), findsOneWidget);

      // حقول التقرير الكامل لا تنزل إلى سطر القسم
      // Report-wide fields never descend into a section's line.
      expect(find.text('السطور'), findsNothing);
      expect(find.text('الصافي'), findsNothing);
    });
  });
}

void _ignore(List<String> values) {}
