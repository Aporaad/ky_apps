import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/item_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/presentation/providers/items_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/stores/presentation/screens/item_detail_screen.dart';
import 'package:ky_apps/features/stores/presentation/screens/items_list_screen.dart';

/// اختبارات التخطيط الرئيسي-التفصيلي لشاشة الأصناف
/// Tests of the items master-detail layout.
///
/// ── ما يحرسه هذا الملف: أن الشاشة العريضة تعرض لوحة تفصيل بجانب القائمة (فلا يُفتح صنف في
///    سياق منفصل ويضيع مكانك في القائمة)، وأن الجوال يبقى قائمةً واحدة بلا لوحة تحاصر الشاشة
///    الصغيرة. الحدّ واحد (`ItemDetailScreen.splitBreakpoint`) ومُقاس في الاختبارين معاً حتى لا
///    ينحرف أحدهما عن الآخر.
/// ── What this guards: a wide surface shows a detail panel beside the list (so opening an item
///    does not lose your place), while a phone stays a single list. Both tests read the same
///    `ItemDetailScreen.splitBreakpoint` so the two branches cannot drift apart.
class _SeededItemsList extends ItemsListNotifier {
  @override
  ItemsListState build() {
    // لا تحميل شبكي في الاختبار: الحالة مزروعة مباشرة
    // No network load in the test: the state is seeded directly.
    return const ItemsListState(
      total: 2,
      items: [
        ItemModel(sanfNo: 666, partNo: '20106001', name: 'قماش تايلندي', unitName: 'ثوب'),
        ItemModel(sanfNo: 667, partNo: '20106002', name: 'قماش صوفي', unitName: 'ثوب'),
      ],
    );
  }

  @override
  Future<void> load({bool keepPage = false}) async {}
}

void main() {
  Widget host() {
    return ProviderScope(
      overrides: [
        itemsListProvider.overrideWith(_SeededItemsList.new),
        storeReferenceProvider.overrideWith((ref) async => const StoreReference()),
      ],
      child: const MaterialApp(home: ItemsListScreen()),
    );
  }

  testWidgets('a wide surface puts the detail panel beside the list', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(
      ItemDetailScreen.splitBreakpoint + 200,
      900,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();

    // اللوحة موجودة وتدعو للاختيار بدل أن تكون فارغة
    // The panel exists and invites a pick instead of sitting blank.
    expect(find.text('اختر صنفاً'), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });

  testWidgets('a phone surface keeps the list alone', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(
      ItemDetailScreen.splitBreakpoint - 200,
      900,
    );
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pump();

    // لا لوحة على الجوال — الصنف يُفتح في شاشة مستقلة
    // No panel on a phone — the item opens as its own screen.
    expect(find.text('اختر صنفاً'), findsNothing);
    expect(find.text('قماش تايلندي'), findsOneWidget);
  });

  testWidgets('the split breakpoint stays above the app phone breakpoint', (
    tester,
  ) async {
    // الجوال < 768، فيجب أن تكون اللوحة الجانبية أعرض من ذلك وإلا صارت قاعدة لا استثناء
    // Phones are < 768, so the side panel must break wider than that.
    expect(ItemDetailScreen.splitBreakpoint, greaterThan(768));
  });
}
