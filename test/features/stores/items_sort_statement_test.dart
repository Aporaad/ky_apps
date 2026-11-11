import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/item_model.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/presentation/providers/items_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/reports_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/stores/presentation/screens/item_detail_screen.dart';
import 'package:ky_apps/features/stores/presentation/screens/items_list_screen.dart';
import 'package:ky_apps/features/stores/presentation/screens/store_reports_screen.dart';

/// ترتيب الأصناف وتوجيه كشف الحركة إلى قالب التقارير
/// Item sorting and routing the movement statement into the report template.
///
/// ── ما يحرسه هذا الملف نقطتان طلبهما المستخدم حرفياً:
///    ١) لكل خيار ترتيب اتجاهٌ تصاعدي/تنازلي يُبدَّل ولا يضيع — في التبويبين معاً، بعد أن
///       كانت الورقة القديمة تُعيد كل اختيار إلى «تصاعدي» والثانية بلا فرز أصلاً.
///    ٢) النقر على «كشف حركة» — من إجراء البطاقة في أي تبويب — يفتح تقرير المخازن نفسه
///       بمعطياته الجاهزة (نطاق صنف رئيسي / نطاق صنف فرعي)، لا شاشة كشف موازية.
/// ── Two user-requested behaviours are guarded here:
///    1) Every sort option carries a reachable ascending/descending direction, in BOTH tabs —
///       the old sheet reset every pick to ascending, and the branches tab had no sort at all.
///    2) Tapping "movement statement" from a card opens the stores-reports template itself,
///       preset to the item's or the branch's scope — never a parallel weaker screen.
class _SeededMain extends ItemsListNotifier {
  _SeededMain(this.applied);

  final List<(String, String)> applied;

  @override
  ItemsListState build() => const ItemsListState(
    items: [ItemModel(sanfNo: 5, partNo: 'A1', name: 'صنف تجربة')],
    total: 1,
  );

  @override
  Future<void> load({bool keepPage = false}) async {}

  @override
  Future<void> applyDefaults(StoreReference reference) async {}

  @override
  Future<void> sortBy(String field, String dir) async {
    state = state.copyWith(sort: field, dir: dir);
    applied.add((field, dir));
  }

  @override
  Future<void> toggleSortDir() async {
    state = state.copyWith(dir: state.dir == 'asc' ? 'desc' : 'asc');
    applied.add(('__toggle__', state.dir));
  }

  /// الحالة مزروعة عمداً، فتفريغ الشاشة عند الفتح يبقى بلا أثر هنا
  /// The state is seeded on purpose, so the screen's open-time wipe is a no-op.
  @override
  void resetTransient({bool reload = false}) {}
}

class _SeededSub extends SubItemsListNotifier {
  @override
  SubItemsListState build() => const SubItemsListState(
    rows: [
      ItemSubModel(sanfDno: 77, sanfNo: 5, parentName: 'صنف تجربة', qty: 4),
    ],
    total: 1,
  );

  @override
  Future<void> load({bool keepPage = false}) async {}

  @override
  Future<void> applyDefaults(StoreReference reference) async {}

  /// الحالة مزروعة كما في القائمة الرئيسية
  /// Seeded state, same as the main list.
  @override
  void resetTransient({bool reload = false}) {}
}

/// تقرير خامل: الاختبار يحرس المعطيات الماررة للتنقل لا شبكة التقرير نفسها،
/// ولو تُرك النوتيفر الحقيقي لأرسل طلباً حياً يترك مؤقّتاً معلّقاً بعد الاختبار
/// An inert report: the test guards the parameters passed to navigation, not the report's
/// network. Left real, the notifier would fire a live request and leave a pending timer.
class _InertReport extends StoreReportNotifier {
  @override
  StoreReportState build() => const StoreReportState();

  @override
  Future<void> run(StoreReportFilter filter) async {}
}

void main() {
  test('كشف حركة صنف رئيسي: نطاق صنف مقيد بصنفه بلا مدى مخصص', () {
    final filter = StoreReportFilter.forItemStatement(
      sanfNo: 5,
      itemName: 'صنف تجربة',
    );

    expect(filter.kind, StoreReportKind.movement);
    expect(filter.scope, StoreReportScope.item);
    expect(filter.sanfNo, 5);
    expect(filter.sanfName, 'صنف تجربة');
    expect(filter.sanfDno, isNull);
    // المدى الافتراضي للتقرير جزء من تعريفه لا اختيار المستخدم، فلا يُطبع في العنوان
    // The default window belongs to the report's definition, so the title omits it.
    expect(filter.customPeriod, isFalse);
    expect(filter.toQuery()['scope'], 'item');
    expect(filter.toQuery()['sanf_no'], 5);
  });

  test('كشف حركة صنف فرعي: نطاق فرع مقيد بفرعه وعنوانه', () {
    final filter = StoreReportFilter.forBranchStatement(
      sanfNo: 5,
      sanfDno: 77,
      branchLabel: 'أحمر مقاس 58',
    );

    expect(filter.scope, StoreReportScope.branch);
    expect(filter.sanfDno, 77);
    expect(filter.sanfDnoLabel, 'أحمر مقاس 58');
    // الفرع يُرسل للخادم في قيد مستقل عن قيد الصنف الأب
    // The branch travels as its own constraint, beside the parent item's.
    expect(filter.toQuery()['scope'], 'branch');
    expect(filter.toQuery()['sanf_dno'], 77);
    expect(filter.toQuery()['sanf_no'], 5);
  });

  testWidgets('ورقة الترتيب: الخيار النشط معلَّم والاتجاه يُبدَّل ولا يُصفَّر', (
    tester,
  ) async {
    final applied = <(String, String)>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsListProvider.overrideWith(() => _SeededMain(applied)),
          subItemsListProvider.overrideWith(_SeededSub.new),
          storeReferenceProvider.overrideWith((ref) async => const StoreReference()),
        ],
        child: const MaterialApp(home: ItemsListScreen()),
      ),
    );
    await tester.pump();

    // زر الترتيب ظاهر في تبويب الرئيسية
    await tester.tap(find.byTooltip('ترتيب'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب الأصناف'), findsOneWidget);
    // الحالة الافتراضية (name/asc): الخيار النشط يحمل سهم التصاعد وتسمية الوضع الحالي
    expect(find.text('بالاسم (تصاعدي)'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    // التنازلي كان الوصول إليه مستحيلاً في الورقة القديمة — الآن بزر اتجاه صريح
    // Descending was unreachable in the old sheet; now an explicit direction button.
    // السهم العلوي فريد في رأس الورقة (الخيار النشط يستخدم علامة الصح لا السهم)
    // The header arrow is unique in the sheet (the active option uses a check, not an arrow).
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(applied.last, ('__toggle__', 'desc'));

    await tester.tap(find.byTooltip('ترتيب'));
    await tester.pumpAndSettle();

    // الخيار المطبَّق أخيراً يبقى هو المعلَّم عند إعادة فتح الورقة — لا تُعاد للافتراضي
    // The last applied option stays ticked when the sheet reopens — never reset to default.
    expect(find.text('بالاسم (تنازلي)'), findsOneWidget);

    // اختيار خيار جديد يرث الاتجاه الحالي بدل أن يُصفَّره
    // A new pick inherits the current direction instead of resetting it.
    await tester.tap(find.text('بالرصيد'));
    await tester.pumpAndSettle();
    expect(applied.last, ('qty', 'desc'));
  });

  testWidgets('تبويب الفروع له ورقة ترتيب بخياراتها الخاصة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsListProvider.overrideWith(() => _SeededMain(<(String, String)>[])),
          subItemsListProvider.overrideWith(_SeededSub.new),
          storeReferenceProvider.overrideWith((ref) async => const StoreReference()),
        ],
        child: const MaterialApp(home: ItemsListScreen()),
      ),
    );
    await tester.pump();

    // التنقل لتبويب الأصناف الفرعية — كان بلا أي خيار فرز
    // Switch to the branches tab — it previously offered no sorting at all.
    await tester.tap(find.text('الأصناف الفرعية'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ترتيب'));
    await tester.pumpAndSettle();

    expect(find.text('ترتيب الأصناف الفرعية'), findsOneWidget);
    expect(find.text('باسم الصنف الرئيسي (تصاعدي)'), findsOneWidget);
    expect(find.text('برقم الصنف الفرعي'), findsOneWidget);
  });

  testWidgets('كشف حركة الفرع من بطاقته يفتح قالب التقارير بمعطياته', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsListProvider.overrideWith(() => _SeededMain(<(String, String)>[])),
          subItemsListProvider.overrideWith(_SeededSub.new),
          storeReportProvider.overrideWith(_InertReport.new),
          storeReferenceProvider.overrideWith((ref) async => const StoreReference()),
        ],
        child: const MaterialApp(home: ItemsListScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('الأصناف الفرعية'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('كشف حركة الفرع'));
    await tester.pumpAndSettle();

    // الشاشة المفتوحة هي تقارير المخازن نفسها، ومعطياتها نطاق فرع مقيد بالفرع
    // The screen opened is the stores-reports screen itself, preset to this branch.
    final screen = tester.widget<StoreReportsScreen>(find.byType(StoreReportsScreen));
    final filter = screen.initialFilter;

    expect(filter, isNotNull);
    expect(filter!.scope, StoreReportScope.branch);
    expect(filter.sanfNo, 5);
    expect(filter.sanfDno, 77);
    expect(find.text('كشف حركة صنف فرعي'), findsOneWidget);
  });

  testWidgets('كشف حركة الصنف الرئيسي من إجراء بطاقته يفتح قالب صنف رئيسي', (
    tester,
  ) async {
    // سطح جوال معلن: فوق الحد العريض تُفتح اللوحة الجانبية فيصبح زر «إجراءات» مكرراً
    // Declared phone surface: above the wide breakpoint the side panel appears and the
    // "actions" button would no longer be unique.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(
      ItemDetailScreen.splitBreakpoint - 200,
      900,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemsListProvider.overrideWith(() => _SeededMain(<(String, String)>[])),
          subItemsListProvider.overrideWith(_SeededSub.new),
          storeReportProvider.overrideWith(_InertReport.new),
          storeReferenceProvider.overrideWith((ref) async => const StoreReference()),
        ],
        child: const MaterialApp(home: ItemsListScreen()),
      ),
    );
    await tester.pump();

    // بوابة الجوال أولًا: على الجوال النقر على البطاقة نفسها ينقل إلى التفصيل،
    // فيبقى مسار القائمة الوحيد إلى الكشف هو إجراء «كشف حركة» نفسه
    // Phone gate first: on a phone tapping the card navigates to the detail, so the
    // list's only statement path is the card's own "movement statement" action.
    expect(tester.view.physicalSize.width,
        lessThan(ItemDetailScreen.splitBreakpoint));

    await tester.tap(find.byTooltip('إجراءات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('كشف حركة'));
    await tester.pumpAndSettle();

    final screen = tester.widget<StoreReportsScreen>(find.byType(StoreReportsScreen));
    final filter = screen.initialFilter;

    expect(filter, isNotNull);
    expect(filter!.scope, StoreReportScope.item);
    expect(filter.sanfNo, 5);
    expect(filter.sanfName, 'صنف تجربة');
    expect(find.text('كشف حركة صنف رئيسي'), findsOneWidget);
  });
}
