import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_letterhead_info.dart';
import 'report_pdf_arabic.dart';
import 'report_pdf_letterhead.dart';

/// وحدة الترويسة والتذييل الموحّدة لكل تقارير PDF — تُستهلك من كل مولّدات PDF
/// (كشف حساب مالي، ميزان مراجعة، كشف عميل، كشف عامل) لضمان توحيد الشكل
/// ومنع تكرار الكود.
///
/// Unified PDF report header/footer module — consumed by every PDF builder
/// (account statement, group trial balance, customer statement, worker statement)
/// to guarantee a consistent look and DRY code across all reports.
///
/// RTL Table columns note: `pw.Table` always lays children left→right regardless
/// of the page textDirection. Arabic reports must REVERSE their column lists so that
/// the first logical column (السند) appears at the RIGHT edge (matching the on-screen
/// Flutter `Table` which IS RTL-aware). Use [reversedCells] helper below.

// ─── ألوان التقارير الموحّدة / Unified report colors ───────────────────────────
class ReportPdfColors {
  static const PdfColor headerBg = PdfColor.fromInt(0xFFD4A853);
  static const PdfColor border = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor subtleText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor rowStripe = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor accentBlue = PdfColor.fromInt(0xFF0369A1);
  static const PdfColor dangerRed = PdfColor.fromInt(0xFFDC2626);
}

// ─── الترويسة الموحّدة / Unified header ─────────────────────────────────────────

/// يبني ترويسة صفحة PDF موحّدة: شريط ثلاثي الأعمدة (عربي/شعار/إنجليزي) + عنوان
/// التقرير + صف معلومات خاص بالتقرير (يُمرَّر من المستدعي) + حد سفلي.
/// Builds the unified PDF page header: three-column letterhead band (Arabic/logo/English)
/// + report title + a report-specific meta row (supplied by the caller) + bottom border.
pw.Widget buildReportPdfHeader({
  required ReportLetterheadInfo letterhead,
  required String title,
  required pw.Widget metaSection,
  pw.Widget? logo,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(width: 1, color: ReportPdfColors.border),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // الشريط الثلاثي الأعمدة / Three-column branding band
        reportPdfLetterheadBranding(letterhead, logo: logo),
        pw.SizedBox(height: 6),
        // عنوان التقرير / Report title
        pw.Text(
          pdfArabic(title),
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          // النص مُشكَّل مسبقاً بترتيب مرئي → يُعرض ltr حتى لا يعيد المحرك ترتيبه
          textDirection: kPdfShapedTextDirection,
        ),
        pw.SizedBox(height: 4),
        // صف المعلومات الخاص بالتقرير / Report-specific meta
        metaSection,
      ],
    ),
  );
}

// ─── التذييل الموحّد / Unified footer ────────────────────────────────────────────

/// يبني تذييل صفحة PDF موحّد: اسم العملة (اختياري) + ترقيم الصفحات.
/// Builds the unified PDF page footer: currency label (optional) + page numbering.
pw.Widget buildReportPdfFooter(pw.Context context, {String? currency}) {
  return pw.Container(
    alignment: pw.Alignment.center,
    margin: const pw.EdgeInsets.only(top: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          pdfArabic(
              currency != null && currency.isNotEmpty ? 'العملة: $currency' : ''),
          style: const pw.TextStyle(fontSize: 7),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic('صفحة ${context.pageNumber} من ${context.pagesCount}'),
          style: const pw.TextStyle(fontSize: 7),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
    ),
  );
}

// ─── مساعد عكس أعمدة الجدول / RTL column reversal helper ────────────────────────

/// يعكس ترتيب قائمة خلايا الصف لأن `pw.Table` يرسم دائماً يسار→يمين بغض النظر
/// عن اتجاه الصفحة. التقارير العربية تحتاج العمود الأول (السند) في أقصى اليمين.
/// Reverses the cell list because `pw.Table` always draws children left→right
/// regardless of page textDirection. Arabic reports need the first logical column
/// (السند) at the RIGHT edge.
List<pw.Widget> reversedCells(List<pw.Widget> cells) => cells.reversed.toList();

// ─── مساعدات خلية الجدول المشتركة / Shared table cell helpers ───────────────────

/// رأس عمود موحد / Unified table header cell
pw.Widget pdfTh(String text, {double fontSize = 8.5}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    child: pw.Center(
      child: pw.Text(
        pdfArabic(text),
        style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold),
        textDirection: kPdfShapedTextDirection,
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

/// خلية بيانات موحّدة / Unified table data cell
pw.Widget pdfTd(
  String text, {
  double fontSize = 8,
  bool bold = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.center,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
    child: text.isEmpty
        ? pw.SizedBox()
        : pw.Text(
            pdfArabic(text),
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
            textDirection: kPdfShapedTextDirection,
            textAlign: align,
          ),
  );
}

// ─── صف التواريخ المشترك / Shared date-range meta row ───────────────────────────

/// يبني صف "من تاريخ ... إلى تاريخ" مع خيار نص إضافي على اليسار (توقيت/مرجع).
/// Builds the "from date ... to date" row with an optional left-side note.
pw.Widget pdfDateRangeRow({
  required String? fromDate,
  required String? toDate,
  String? rightNote,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        pdfArabic(fromDate != null && toDate != null
            ? 'من تاريخ: $fromDate   إلى تاريخ: $toDate'
            : 'كل الحركات (بدون تحديد فترة)'),
        style: const pw.TextStyle(fontSize: 9),
        textDirection: kPdfShapedTextDirection,
      ),
      if (rightNote != null)
        pw.Text(
          pdfArabic(rightNote),
          style: const pw.TextStyle(
              fontSize: 8, color: ReportPdfColors.subtleText),
          textDirection: kPdfShapedTextDirection,
        ),
    ],
  );
}

// ─── التوقيعات المشتركة / Shared signature slots ────────────────────────────────

/// ثلاثة خانات توقيعة + سطر إخلاء مسؤولية 15 يوماً.
/// Three signature slots + the 15-day review notice line.
pw.Widget pdfSignatures() {
  return pw.Column(
    children: [
      pw.SizedBox(height: 20),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          _signatureSlot('توقيع المحاسب'),
          _signatureSlot('توقيع أمين الصندوق'),
          _signatureSlot('توقيع المدير'),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Center(
        child: pw.Text(
          pdfArabic(
              'يجب مراجعة هذا الكشف خلال 15 يوماً من تاريخ إصداره، وما بعد ذلك يُعتبر معتمداً.'),
          style: const pw.TextStyle(
              fontSize: 7.5, color: ReportPdfColors.subtleText),
          textDirection: kPdfShapedTextDirection,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}

pw.Widget _signatureSlot(String label) {
  return pw.Column(
    children: [
      pw.Container(width: 110, height: 0.5, color: PdfColors.grey600),
      pw.SizedBox(height: 3),
      pw.Text(
        pdfArabic(label),
        style: const pw.TextStyle(fontSize: 8),
        textDirection: kPdfShapedTextDirection,
      ),
    ],
  );
}
