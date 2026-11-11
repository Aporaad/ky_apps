import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/presentation/providers/orders_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/stores/presentation/screens/orders_list_screen.dart';

/// اختبار شاشة قائمة الأوامر — تُرسم فعلاً ولا ترمي عطب تخطيط
/// Tests of the orders list screen — it actually renders instead of throwing a layout fault.
///
/// ── لماذا هذا الملف؟ لأن الشاشة كانت تعرض خطأً أحمر بدل البطاقات، والبيانات كانت تصل
///    سليمة (`success: true`) — أي أن العطب كان في التخطيط لا في الشبكة. اختبارات المزوّد
///    والنماذج لا ترى هذا؛ لا بد من تركيب الشاشة نفسها وطلب إطار رسم.
/// ── Why this file: the screen showed a red error box while the data arrived fine
///    (`success: true`) — the fault was layout, not network. Provider and model tests cannot
///    see that; only mounting the screen and asking for a frame can.
///
/// ── العطب الذي يحرسه: `Row` بـ`CrossAxisAlignment.stretch` داخل قائمة بارتفاع غير محدود
///    يطلب ارتفاعاً لا نهائياً (`BoxConstraints forces an infinite height`).
/// ── The defect it guards: a stretched Row inside an unbounded-height list asks for an
///    infinite height.
class _SeededOrders extends OrdersListNotifier {
  @override
  OrdersListState build() {
    // لا تحميل شبكي: صفحة مزروعة تحمل بطاقات الأنواع الثلاثة كما تصل من الخادم
    // No network load: a seeded page carrying all three kinds as the server sends them.
    return const OrdersListState(
      kind: StoreOrderKind.transfer,
      isLoading: false,
      total: 3,
      orders: [
        // تحويل: بلا طرف، وبمخزنين ومسلسل، ولا خصم
        // Transfer: no party, two stores and a serial, no discount.
        StoreOrderModel(
          billNo: 71,
          year: 2026,
          storeNo: 4,
          storeName: 'مخزن بضاعة جاهزة للبيع',
          storeTo: 1,
          storeToName: 'المحل الرئيسي',
          sanfNums: 1,
          total: 130000,
          discount: 0,
          net: 130000,
          detailes: 'تحويل مخزني منصرف من 4 الى 1',
          curName: 'يمني',
          entryNo: 2260009806,
          trInvMId: 265471,
          lines: 1,
          qtySum: 20,
          theTime: '05:42:12 PM',
        ),
        // توريد: طرف + رقم مرجع + نوع آجل + خصم
        // Receive: a party, a reference, a credit bill type and a discount.
        StoreOrderModel(
          billNo: 535,
          year: 2026,
          storeNo: 4,
          storeName: 'مخزن بضاعة جاهزة للبيع',
          partyName: 'تسوية حساب انتاج الجاهز',
          partyBill: '963',
          billType: 2,
          sanfNums: 1,
          total: 303100,
          discount: 0,
          net: 303100,
          detailes: 'فاتورة توريد مخزني آجل رقم 535',
          curName: 'يمني',
          lines: 36,
          qtySum: 54,
          createdByName: 'محمد الشرفي',
          theTime: '04:38:40 PM',
        ),
        // صرف: جهة مستلمة، ومرجع للقراءة فقط
        // Issue: a receiver, and a read-only reference.
        StoreOrderModel(
          billNo: 301,
          year: 2026,
          storeNo: 1,
          storeName: 'المحل الرئيسي',
          partyName: 'قسم الانتاج',
          billType: 2,
          sanfNums: 6,
          total: 294000,
          discount: 0,
          net: 294000,
          curName: 'يمني',
          entryNo: 147000,
          lines: 6,
          qtySum: 6,
          theTime: '08:41:04 PM',
        ),
      ],
    );
  }

  @override
  Future<void> load({bool keepPage = false}) async {}

  /// الحالة مزروعة عمداً، فتفريغ الشاشة عند الفتح يجب أن يمرّ بلا أثر هنا.
  /// الواقعي يجلب قائمة جديدة بعد التصفير، وهذا البديل لا يملك شبكة أصلاً.
  /// The state is seeded on purpose, so the screen's open-time wipe must be a no-op.
  /// The real notifier refetches after wiping; this stub has no network at all.
  @override
  void resetTransient({bool reload = false}) {}

  /// الشاشة تنادي `bind` عند الفتح؛ نتركها بلا تحميل لأن الحالة مزروعة
  /// The screen calls `bind` on open; leave it alone because the state is already seeded.
  @override
  void bind(StoreOrderKind kind) {}
}

void main() {
  Widget host(StoreOrderKind kind) {
    return ProviderScope(
      overrides: [
        ordersListProvider.overrideWith(_SeededOrders.new),
        storeReferenceProvider.overrideWith(
          (ref) async => const StoreReference(),
        ),
      ],
      child: MaterialApp(home: OrdersListScreen(kind: kind)),
    );
  }

  testWidgets('the card is drawn instead of a red layout error', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(StoreOrderKind.transfer));
    await tester.pump();

    // لا استثناء تخطيط: هذا هو جوهر الاختبار
    // No layout exception: this is the whole point of the test.
    expect(tester.takeException(), isNull);

    // والبطاقة تحمل بيانات المستند كما وصلت من الخادم
    // And the card carries the document data exactly as it arrived.
    expect(find.textContaining('رقم 71'), findsOneWidget);
    // اسم المخزن يتكرر في أكثر من بطاقة لأن بطاقتين تخصّان المخزن 4
    // The store name repeats because two cards belong to store 4.
    expect(find.text('مخزن بضاعة جاهزة للبيع'), findsWidgets);
    expect(find.text('المحل الرئيسي'), findsWidgets);
    expect(find.text('130,000.00'), findsWidgets);
  });

  testWidgets('every kind renders its card without a layout fault', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);

    // الأنواع الثلاثة تستخدم نفس البطاقة، فأي فرع منها قد ينفرد بالعطب
    // All three share one card, so any of its branches can break on its own.
    for (final kind in StoreOrderKind.values) {
      await tester.pumpWidget(host(kind));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'عطب تخطيط في $kind');
    }
  });

  testWidgets('the same screen renders on a phone width', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(StoreOrderKind.transfer));
    await tester.pump();

    // الشريط الجانبي للبطاقة لا يُسحق المحتوى على عرض ضيق
    // The card's kind rail must not crush the content at a narrow width.
    expect(tester.takeException(), isNull);
    expect(find.textContaining('رقم 71'), findsOneWidget);
  });
}
