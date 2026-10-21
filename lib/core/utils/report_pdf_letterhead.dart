import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

import 'report_letterhead_info.dart';

/// ترويسة تقرير PDF بنفس الأعمدة الثلاثة التي ترسمها الشاشة: يمين عربي، وسط للشعار،
/// يسار إنجليزي — نفس المصدر ([ReportLetterheadInfo]) ونفس الترتيب، فيتطابق المطبوع
/// مع المعروض.
/// The PDF report letterhead with the same three columns the screen draws: Arabic on the
/// right, the logo in the center, English on the left — same source object, same order, so
/// what prints matches what is shown.
///
/// [logo] اختياري: حين تُحمَّل صورة الشعار تُرسم في المنتصف، وإلا يبقى العمود الأوسط
/// فارغاً ولا يفشل توليد التقرير بسبب أصل غير متاح.
/// [logo] is optional: when the logo bytes are available they are drawn in the middle,
/// otherwise the center cell stays empty and the report never fails over a missing asset.
pw.Widget reportPdfLetterheadBranding(
  ReportLetterheadInfo info, {
  pw.Widget? logo,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      // اليمين (بداية RTL): الكتلة العربية
      // Right side (RTL start): the Arabic block.
      pw.Expanded(flex: 5, child: _pdfInfoColumn(info.arabicLines, true)),
      pw.SizedBox(width: 10),

      // المنتصف: الشعار
      // Center: the logo.
      pw.Expanded(
        flex: 4,
        child: pw.Container(
          alignment: pw.Alignment.center,
          child: logo ?? pw.SizedBox.shrink(),
        ),
      ),
      pw.SizedBox(width: 10),

      // اليسار: الكتلة الإنجليزية باتجاه LTR حتى لا تنعكس كلماتها داخل صفحة RTL
      // Left side: the English block, LTR so its words never mirror inside an RTL page.
      pw.Expanded(flex: 4, child: _pdfInfoColumn(info.englishLines, false)),
    ],
  );
}

/// عمود واحد من أسطر الترويسة: أولها اسم الشركة بخط أعرض وبقية الأسطر تفاصيل أصغر.
/// One letterhead column: the first line is the bolder company name, the rest are detail.
pw.Widget _pdfInfoColumn(List<String> lines, bool arabic) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      for (int i = 0; i < lines.length; i++) ...[
        if (i > 0) pw.SizedBox(height: 2),
        pw.Text(
          lines[i],
          style: pw.TextStyle(
            fontSize: i == 0 ? 9.5 : 7.5,
            fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          // الاتجاه صريح هنا لا موروث: الصفحة كلها RTL والكتلة الإنجليزية يجب أن تبقى LTR
          // Explicit, not inherited: the page is RTL while the English block must stay LTR.
          textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          textAlign: pw.TextAlign.center,
        ),
      ],
    ],
  );
}

/// تحميل شعار الترويسة من أصول Flutter كصورة PDF؛ يعيد null عند أي فشل في القراءة
/// حتى لا يتعطل توليد التقرير بسبب أصل ناقص.
/// Loads the letterhead logo from the Flutter asset bundle as a PDF image; returns null on
/// any failure so a missing asset can never break report generation.
Future<pw.Widget?> loadPdfLetterheadLogo({
  String asset = 'assets/logo3.jpg',
  double height = 46,
}) async {
  try {
    final data = await rootBundle.load(asset);
    final image = pw.MemoryImage(data.buffer.asUint8List());

    return pw.SizedBox(
      height: height,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  } catch (_) {
    return null;
  }
}
