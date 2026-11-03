import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_letterhead_info.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/presentation/utils/store_export.dart';

/// تصدير مستند المخزن — الحارس الذي كان غائباً تماماً
/// Exporting a stock document — the guard that never existed.
///
/// ── لماذا هذا الملف؟ لأن الطباعة والتصدير كانا بلا اختبار واحد، فسقط التصدير على المستخدم
///    برسالة «تعذر التصدير: Unsupported operation: Cannot add to a fixed-length list» ولم
///    يكشفه أي اختبار: كل ما كان مُختبَراً هو النماذج والأعمدة، لا مولّد الـ PDF نفسه.
/// ── Why this file: printing and exporting had no test at all, so the export failed on the
///    user with "Cannot add to a fixed-length list" and nothing caught it: models and columns
///    were tested, the PDF builder was not.
///
/// ── الاختبار يبني الـ PDF فعلياً للأنواع الثلاثة: خطوط عربية من الأصول، ترويسة، جدول،
///    تفاصيل مالية وتوقيعات — وأي استثناء في أي طبقة يُسقطه.
/// ── It really builds the PDF for all three kinds: Arabic fonts from assets, letterhead,
///    table, money block and signatures — any exception in any layer fails it.
void main() {
  // الخطوط تُقرأ من أصول مُضمَّنة، فتلزم تهيئة ربط الاختبار
  // Fonts come from bundled assets, so the test binding must be initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  const letterhead = ReportLetterheadInfo(
    companyName: ReportLetterheadInfo.kFallbackNameAr,
    address: ReportLetterheadInfo.kFallbackAddressAr,
    phone: ReportLetterheadInfo.kFallbackPhone,
    website: '',
    companyNameEn: ReportLetterheadInfo.kFallbackNameEn,
    addressEn: ReportLetterheadInfo.kFallbackAddressEn,
  );

  // فاتورة 535 كما هي في قاعدة التطبيق: صافي 303,100
  // Bill 535 as it is in the app's database.
  final header = StoreOrderModel(
    billNo: 535,
    year: 2026,
    date: DateTime(2026, 10, 31),
    storeNo: 4,
    storeName: 'مخزن بضاعة جاهزة للبيع',
    storeTo: 1,
    storeToName: 'المحل الرئيسي',
    partyName: 'تسوية حساب انتاج الجاهز',
    partyBill: '963',
    billType: 2,
    sanfNums: 36,
    total: 303100,
    discount: 0,
    net: 303100,
    curNo: 1,
    curName: 'يمني',
    curPrice: 1,
    accName: 'مخزون البضاعة',
    detailes: 'فاتورة توريد مخزني آجل رقم 535',
    trInvMId: 265471,
    lines: 36,
  );

  const lines = [
    StoreOrderLineModel(
      sanfNo: 567,
      sanfDno: 2010100231,
      sanfName: 'ملون تايلندي',
      partNo: '20101002',
      subName: 'ملون تايلندي طقطق',
      unitName: 'ثوب',
      colorName: 'أبيض',
      qty: 7,
      price: 6500,
      total: 45500,
      cap: 1,
      pcs: 7,
      stkCost: 6100,
    ),
  ];

  test('every document kind exports a real PDF', () async {
    for (final kind in StoreOrderKind.values) {
      final bytes = await buildStoreOrderPdf(
        letterhead: letterhead,
        kind: kind,
        header: header,
        lines: lines,
      );

      // توقيع ملف PDF + حجم معقول: مستند فارغ يعني أن الطبقات لم تُرسم
      // The PDF signature plus a sane size: an empty file means nothing was drawn.
      expect(
        String.fromCharCodes(bytes.take(5)),
        '%PDF-',
        reason: 'المخرج ليس ملف PDF لـ $kind',
      );
      expect(
        bytes.length,
        greaterThan(2000),
        reason: 'ملف $kind أصغر من أن يحمل ترويسة وجدولاً وتوقيعات',
      );
    }
  });

  test('a 36-line document fits two pages instead of three', () async {
    // ── العطل الذي شكا منه المستخدم: الجدول ينتهي في نصف الورقة وتُدفع بقية السطور لصفحة
    //    أخرى. السبب أن `fromTextArray` كان يعطي كل عمود عرضاً متساوياً، فتتسطر أسماء
    //    الأصناف على عدة أسطر ويصير الصف ~50 نقطة. بضبط عروض الأعمدة بنِسَب المستند
    //    عاد الصف رقيقاً فصارت الصفحة الأولى ممتلئة والمستند صفحتين (36 سطراً هنا).
    // ── The defect the user reported: the table ended mid-sheet and the remaining rows were
    //    pushed to another page. Cause: `fromTextArray` gave every column an equal width, so
    //    item names wrapped onto several lines and a row became ~50pt. With the document's own
    //    column weights the row is thin again, page one fills, and 36 lines take two pages.
    final many = [
      for (var i = 0; i < 36; i++)
        StoreOrderLineModel(
          sanfNo: 567 + i,
          sanfDno: 2010100000 + i,
          sanfName: 'ملون تايلندي',
          partNo: '2010100${i % 10}',
          subName: 'ملون تايلندي طقطق رقم $i',
          unitName: 'ثوب',
          colorName: 'أبيض',
          qty: 7,
          price: 6500,
          total: 45500,
          cap: 1,
          pcs: 7,
          stkCost: 6100,
        ),
    ];

    final bytes = await buildStoreOrderPdf(
      letterhead: letterhead,
      kind: StoreOrderKind.receive,
      header: header,
      lines: many,
    );

    final pages = RegExp(
      r'/Type\s*/Page[^s]',
    ).allMatches(String.fromCharCodes(bytes)).length;

    expect(
      pages,
      2,
      reason: '36 سطراً تستهلك $pages صفحة — الصفحة الأولى لا تمتلئ',
    );
  });

  test('the sheet is A4 portrait, not landscape', () async {
    // ── الطلب الصريح: A4 **طولية**. الأفقي كان يُصغّر المستند عند الطباعة على ورق طولي،
    //    فالمقاس هنا جزء من العقد لا تفصيلاً تجميلياً.
    // ── The explicit requirement: A4 **portrait**. Landscape shrank the document when printed
    //    on portrait paper, so the page size is part of the contract, not decoration.
    final bytes = await buildStoreOrderPdf(
      letterhead: letterhead,
      kind: StoreOrderKind.receive,
      header: header,
      lines: lines,
    );

    final box = RegExp(
      r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)',
    ).firstMatch(String.fromCharCodes(bytes));

    expect(box, isNotNull, reason: 'لا يوجد MediaBox في المستند');

    final width = double.parse(box!.group(1)!);
    final height = double.parse(box.group(2)!);

    expect(
      height,
      greaterThan(width),
      reason: 'الورقة $width×$height — يجب أن تكون طولية (الارتفاع أكبر من العرض)',
    );
    expect(width.round(), 595, reason: 'عرض A4 الطولية 595 نقطة');
    expect(height.round(), 842, reason: 'ارتفاع A4 الطولية 842 نقطة');
  });

  test('a document with a single line still exports', () async {
    final bare = StoreOrderModel(
      billNo: 71,
      year: 2026,
      date: DateTime(2026, 10, 28),
      storeNo: 4,
      storeName: 'مخزن بضاعة جاهزة للبيع',
      storeTo: 1,
      storeToName: 'المحل الرئيسي',
      total: 130000,
      net: 130000,
      curName: 'يمني',
      trInvMId: 265471,
      sanfNums: 1,
    );

    final bytes = await buildStoreOrderPdf(
      letterhead: letterhead,
      kind: StoreOrderKind.transfer,
      header: bare,
      lines: lines,
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
