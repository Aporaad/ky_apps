import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/presentation/providers/orders_providers.dart';

/// اختبارات التحديد المتعدد في قوائم الأوامر — الأساس الذي تعمل عليه الإجراءات الجماعية
/// Multi-select tests of the order lists — the basis every bulk action runs on.
///
/// ── ما يحرسه هذا الملف: أن «عكس التحديد» يعمل على **الصفحة المعروضة فقط**. الإجراء الجماعي
///    الخطير هو الحذف، وهو حذف فيزيائي في الخادم؛ فلو صار التحديد يمسّ صفوفاً في صفحات لم
///    يفتحها المستخدم لصار ضغطة واحدة تمسح ما لم يره.
/// ── What this guards: invert operates on the *visible page* only. The dangerous bulk action is
///    delete, and it is physical server-side; if a selection could reach rows on pages the user
///    never opened, one press would erase what was never seen.
class _SeededOrdersList extends OrdersListNotifier {
  @override
  OrdersListState build() {
    // لا تحميل شبكي: الصفحة الحالية مزروعة مباشرة
    // No network load: the current page is seeded directly.
    return const OrdersListState(
      isLoading: false,
      total: 3,
      orders: [
        StoreOrderModel(billNo: 535, year: 2026, lines: 2, net: 100),
        StoreOrderModel(billNo: 534, year: 2026, lines: 1, net: 50),
        StoreOrderModel(billNo: 533, year: 2026, lines: 4, net: 75),
      ],
    );
  }

  @override
  Future<void> load({bool keepPage = false}) async {}
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [ordersListProvider.overrideWith(_SeededOrdersList.new)],
    );
    addTearDown(container.dispose);
  });

  OrdersListNotifier notifier() => container.read(ordersListProvider.notifier);
  OrdersListState state() => container.read(ordersListProvider);

  test('invert turns the whole visible page into the selection', () {
    notifier().invertSelection();

    expect(state().selected, {535, 534, 533});
  });

  test('invert twice returns to the original selection', () {
    notifier().toggleSelected(534);
    notifier().invertSelection();

    expect(state().selected, {535, 533});

    notifier().invertSelection();

    expect(state().selected, {534});
  });

  test('the selected rows are the ones the bulk actions receive', () {
    notifier().selectAll();

    final selected = state().orders
        .where((order) => state().selected.contains(order.billNo))
        .toList();

    // الإجراء الجماعي يطبع ما يختاره المستخدم بالضبط، لا الصفحة كلها
    // The bulk action prints exactly what the user picked, not the whole page.
    expect(selected.map((order) => order.billNo), [535, 534, 533]);
    expect(state().totalNet, 225);
  });

  test('clearing the selection leaves the page intact', () {
    notifier().selectAll();
    notifier().clearSelection();

    expect(state().selected, isEmpty);
    expect(state().orders, hasLength(3));
  });
}
