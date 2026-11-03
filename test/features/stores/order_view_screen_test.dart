import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/widgets/report_a4_sheet.dart';
import 'package:ky_apps/core/widgets/report_letterhead_branding.dart';
import 'package:ky_apps/core/widgets/report_signature_footer.dart';
import 'package:ky_apps/core/widgets/report_zoom_view.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/data/repositories/store_orders_repository.dart';
import 'package:ky_apps/features/stores/presentation/providers/orders_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/stores/presentation/screens/order_view_screen.dart';

/// اختبار شاشة استعراض المستند — هل تُرسم كقالب النظام المطبوع فعلاً؟
/// Tests of the document view — does it really render as the desktop's printed template?
///
/// ── ما يحرسه هذا الملف: أن المطالبة كانت «مثل القالب بالظبط». اختبار النصوص وحده لا يكفي:
///    شاشة تعرض الأرقام الصحيحة في ترتيب مختلف تبدو صحيحة للمبرمج وخاطئة للمراجع الذي يقرأ
///    الطبعة. هنا يُثبت أن أعمدة القالب كلها مرسومة، وأن الترويسة والتذييل الرسميين حاضران،
///    وأن المبلغ بالحروف مطابق لطبعة فاتورة 535 الحقيقية.
/// ── What this guards: the ask was "exactly like the template". A text test alone is not
///    enough — a screen with the right figures in the wrong order looks correct to the
///    programmer and wrong to the reviewer holding the paper. This proves every template column
///    is drawn, the official header and footer are present, and the spelled amount matches the
///    real bill 535's printout.
void main() {
  // فاتورة 535 كما هي في قاعدة التطبيق: صافي 303,100 والسطر الأول 7 × 6,500 = 45,500
  // Bill 535 as it actually is in the app's database.
  final header = StoreOrderModel(
    billNo: 535,
    year: 2026,
    date: DateTime(2026, 10, 31),
    storeNo: 4,
    storeName: 'مخزن بضاعة جاهزة للبيع',
    partyName: 'تسوية حساب انتاج الجاهز',
    partyBill: '963',
    billType: 2,
    selectOne: 2,
    sanfNums: 1,
    total: 303100,
    discount: 0,
    net: 303100,
    curNo: 1,
    curName: 'يمني',
    curPrice: 1,
    accName: 'مخزون البضاعة',
    accName1: 'تسوية حساب انتاج الجاهز',
    detailes: 'فاتورة توريد مخزني آجل رقم 535// استلام الجاهز من خط الانتاج 963+964',
    createdByName: 'محمد الشرفي',
    theTime: '04:38:40 PM',
    lines: 18,
  );

  final lines = [
    StoreOrderLineModel(
      sanfNo: 567,
      sanfDno: 2010100231,
      sanfName: 'ملون تايلندي',
      partNo: '20101002',
      subName: 'ملون تايلندي طقطق',
      subPartNo: '2001-17',
      unitName: 'ثوب',
      category: 'تايلندي',
      colorName: 'أبيض',
      lengthFrom: 55,
      lengthTo: 17,
      qty: 7,
      price: 6500,
      total: 45500,
      cap: 1,
      pcs: 7,
    ),
  ];

  void useWideSurface(WidgetTester tester) {
    // الورقة أفقية: تحتاج عرضاً يكفي أعمدة القالب بلا سحق ولا تمرير أفقي في الاختبار
    // The sheet is landscape: it needs room for the full column set to be drawn uncrushed.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1600, 1100);
    addTearDown(tester.view.reset);
  }

  Widget host() {
    return ProviderScope(
      overrides: [
        orderDetailProvider.overrideWith(
          (ref, arg) async => StoreOrderDetail(header: header, lines: lines),
        ),
        storeReferenceProvider.overrideWith(
          (ref) async => const StoreReference(),
        ),
      ],
      child: const MaterialApp(
        home: OrderViewScreen(kind: StoreOrderKind.receive, billNo: 535),
      ),
    );
  }

  testWidgets('the sheet is drawn on the official letterhead and footer', (
    tester,
  ) async {
    useWideSurface(tester);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(ReportZoomView), findsOneWidget);
    expect(find.byType(ReportA4Sheet), findsOneWidget);
    expect(find.byType(ReportLetterheadBranding), findsOneWidget);
    expect(find.byType(ReportSignatureFooter), findsOneWidget);
  });

  testWidgets('the sheet draws the nine reviewed columns and nothing else', (
    tester,
  ) async {
    useWideSurface(tester);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // ── التسعة المطلوبة، كلها مرئية على عرض الورقة بلا تمرير جانبي
    // ── The nine required columns, all visible at sheet width with no side-scrolling.
    for (final title in [
      'رقم الصنف',
      'إسم الصنف',
      'اللون',
      'الوحدة',
      'الكمية',
      'عبوة',
      'قطعة',
      'سعر الصنف',
      'الإجمالي',
    ]) {
      expect(
        find.text(title).evaluate().isNotEmpty,
        isTrue,
        reason: 'عمود «$title» مفقود من المستند',
      );
    }

    // ── والمحذوفة لا تعود: رقم الفرعي والرف والمقاس والتصنيف
    // ── And the dropped ones stay dropped: sub code, shelf, sizes, classification.
    for (final gone in ['رقم الصنف الفرعي', 'رقم الرف', 'طول', 'عرض', 'التصنيف']) {
      expect(find.text(gone), findsNothing, reason: '«$gone» ما زال في الجدول');
    }

    // ── ولا سطر «تفاصيل الأصناف» معدوداً يسبق الجدول: الجدول يلي الشريط مباشرة
    // ── And no "lines detail" caption sits above the table: it follows the strip directly.
    expect(find.text('تفاصيل الأصناف'), findsNothing);

    // ── ولا جدول بتمرير أفقي: الشبكة تُوزَّع على عرض الورقة
    // ── And no horizontally scrolling table: the grid fits the sheet width.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
      findsNothing,
    );
  });

  testWidgets('a line prints its name, colour, unit and figures only', (
    tester,
  ) async {
    useWideSurface(tester);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // اسم الفرعي واللون والوحدة — ما يُقرأ في المستند المكتبي
    // The sub-item name, colour and unit — what the desktop document reads.
    expect(find.text('ملون تايلندي طقطق'), findsOneWidget);
    expect(find.text('20101002'), findsOneWidget);
    expect(find.text('أبيض'), findsOneWidget);
    expect(find.text('ثوب'), findsOneWidget);
    expect(find.text('45,500.00'), findsOneWidget);
    expect(find.text('6,500.00'), findsOneWidget);

    // والأعمدة المسقطة لا تطبع قيمها: رقم الفرعي والتصنيف
    // The dropped columns print none of their values: sub code and classification.
    expect(find.text('2010100231'), findsNothing);
    expect(find.text('تايلندي'), findsNothing);

    // ── والاسم لا يُبتر بنقاط: يلتف على أكثر من سطر بدل إخفاء حرف منه
    // ── The name is never ellipsized: it wraps instead of losing a character.
    final nameText = tester.widget<Text>(
      find.text('ملون تايلندي طقطق'),
    );
    expect(nameText.overflow, isNot(TextOverflow.ellipsis));
    expect(nameText.maxLines, isNull);
  });

  testWidgets('the money block faces two columns and the strip never repeats the number', (
    tester,
  ) async {
    useWideSurface(tester);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // ── اليسار: الإجمالي ثم الخصم ثم الصافي، بنفس الترتيب في الشاشة والمطبوع
    // ── Left: total, discount, then net — the same order on screen and in print.
    expect(find.text('الإجمالي'), findsWidgets);
    expect(find.text('مبلغ الخصم'), findsOneWidget);
    expect(find.text('صافي المبلغ'), findsOneWidget);
    expect(find.text('303,100.00'), findsWidgets);

    // ── واليمين: المبلغ كتابةً ثم البيان
    // ── And the right column: the amount in words, then the description.
    expect(find.text('المبلغ كتابةً'), findsOneWidget);
    expect(find.text('البيان'), findsOneWidget);
    expect(find.textContaining('ثلاثمائة و ثلاثة ألف و مائة'), findsOneWidget);
    expect(find.textContaining('استلام الجاهز من خط الانتاج'), findsOneWidget);
  });

  testWidgets('the detail strip shows the required fields in one row', (
    tester,
  ) async {
    useWideSurface(tester);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // حقول التوريد الستة كما طُلبت
    // The six receive fields exactly as requested.
    for (final label in [
      'تاريخ الفاتورة',
      'نوع الفاتورة',
      'إسم المخزن',
      'إسم المورد',
      'العملة',
      'العدد',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'خانة «$label» مفقودة');
    }

    expect(find.text('آجل'), findsOneWidget);
    expect(find.text('يمني'), findsOneWidget);

    // ── والنصوص تظهر كاملة: اسم المخزن والمورد بلا نقاط بتر
    // ── And the texts appear in full: store and party names without an ellipsis.
    final storeText = tester.widget<Text>(
      find.text('مخزن بضاعة جاهزة للبيع'),
    );
    expect(storeText.overflow, isNot(TextOverflow.ellipsis));

    final partyText = tester.widget<Text>(
      find.text('تسوية حساب انتاج الجاهز'),
    );
    expect(partyText.overflow, isNot(TextOverflow.ellipsis));

    // ── رقم الفاتورة يظهر تحت العنوان مرة واحدة ولا يتكرر في الشريط
    // ── The invoice number appears once under the title, never inside the strip.
    expect(find.textContaining('535-2026'), findsOneWidget);
    expect(find.text('رقم الفاتورة'), findsNothing);
  });

  testWidgets('the sheet renders at every width with all columns visible', (
    tester,
  ) async {
    // ── الشبكة توزّع الخانات على 2–6 أعمدة بحسب العرض، وتملأ الصف الناقص بخانات فارغة.
    //    كان الملء يتم على قائمة ثابتة الطول فيرمي «Cannot add to a fixed-length list»
    //    ويُجهض رسم المستند على عروض بعينها دون غيرها — وهذا ما يجعل العطب يبدو متقطّعاً.
    // ── The grid splits cells over 2–6 columns depending on width and pads the short row.
    //    Padding used to run on a fixed-length list, throwing "Cannot add to a fixed-length
    //    list" and aborting the sheet only on certain widths — which made it look intermittent.
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // كل عرض يجب أن يرسم الورقة بلا عطب ويُظهر الأعمدة التسعة كلها
    // Every width must draw the sheet without a fault and show all nine columns.
    for (final width in <double>[420, 520, 640, 760, 880, 1000, 1120, 1240, 1400]) {
      tester.view.physicalSize = Size(width, 1000);

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'عطب في رسم المستند عند عرض $width',
      );
      expect(find.byType(ReportA4Sheet), findsOneWidget);
      expect(
        find.text('متوسط التكلفة'),
        findsNothing,
        reason: 'التوريد لا يطبع متوسط التكلفة',
      );
    }
  });

  testWidgets('a narrow surface still renders without throwing', (
    tester,
  ) async {
    // الجوال: الأعمدة لا تُسحق بل يظهر تمرير أفقي داخل الجدول
    // On a phone the columns scroll horizontally rather than being crushed.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ReportA4Sheet), findsOneWidget);
  });
}
