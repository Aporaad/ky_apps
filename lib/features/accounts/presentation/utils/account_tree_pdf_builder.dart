import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../utils/account_tree_flatten.dart';

/// يبني تقرير PDF للشجرة المحاسبية (A4 عمودي) من قائمة الصفوف المسطّحة المعروضة.
/// Builds the chart-of-accounts PDF from the same flat rows the screen shows, so the
/// printed report is exactly what the user sees: filters, expansion state and the
/// aggregated balances from ENTRY_SUB — not the stale stored BALANCE columns.
///
/// ترتيب الأعمدة معكوس لأن `pw.Table` يرسم يسار→يمين دائماً بينما التقرير العربي
/// يرسل العمود الأول (الرقم) إلى أقصى اليمين.
Future<Uint8List> buildAccountTreePdf({
  required ReportLetterheadInfo letterhead,
  required List<AccountTreeRow> rows,
  required String title,
  String? periodLabel,
  String? filterNote,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 42);

  // الأسطر غير النصية (تحميل/خطأ) لا محل لها في تقرير مطبوع
  final dataRows = rows
      .where(
        (r) => r.kind == AccountTreeRowKind.structural || r.kind == AccountTreeRowKind.leaf,
      )
      .toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: title,
        logo: logo,
        metaSection: _metaSection(periodLabel, filterNote, dataRows.length),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        _table(dataRows),
        pw.SizedBox(height: 12),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _metaSection(String? periodLabel, String? filterNote, int count) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        pdfArabic('عدد الأسطر: $count'),
        style: const pw.TextStyle(fontSize: 10),
        textDirection: kPdfShapedTextDirection,
      ),
      if (periodLabel != null) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          pdfArabic('فترة الأرصدة: $periodLabel'),
          style: const pw.TextStyle(fontSize: 10),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
      if (filterNote != null && filterNote.isNotEmpty) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          pdfArabic('الفلاتر: $filterNote'),
          style: const pw.TextStyle(fontSize: 9),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
    ],
  );
}

// ─── الجدول: الرقم | الاسم | المستوى | مدين | دائن | الرصيد ───────────────────
pw.Widget _table(List<AccountTreeRow> rows) {
  const cellFont = 8.0;

  // بعد العكس للترتيب البصري: [الرصيد | دائن | مدين | المستوى | الاسم | الرقم]
  pw.TableRow headerRow() => pw.TableRow(
    decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
    children: reversedCells([
      pdfTh('الرقم', fontSize: 8.5),
      pdfTh('الاسم', fontSize: 8.5),
      pdfTh('المستوى', fontSize: 8.5),
      pdfTh('مدين', fontSize: 8.5),
      pdfTh('دائن', fontSize: 8.5),
      pdfTh('الرصيد', fontSize: 8.5),
    ]),
  );

  pw.TableRow bodyRow(AccountTreeRow row) {
    final balance = row.balance ?? 0;
    final isLeaf = row.kind == AccountTreeRowKind.leaf;
    final depth = row.depth;

    final nameCell = pw.Padding(
      padding: pw.EdgeInsets.only(right: depth * 8),
      child: pw.Text(
        pdfArabic(row.title),
        style: pw.TextStyle(
          fontSize: cellFont,
          fontWeight: isLeaf ? pw.FontWeight.normal : pw.FontWeight.bold,
        ),
        textDirection: kPdfShapedTextDirection,
      ),
    );

    return pw.TableRow(
      children: reversedCells([
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(row.code, style: const pw.TextStyle(fontSize: cellFont)),
        ),
        nameCell,
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(
            pdfArabic(row.levelLabel),
            style: const pw.TextStyle(fontSize: 7.5),
            textDirection: kPdfShapedTextDirection,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(
            _amt(row.debit),
            style: const pw.TextStyle(fontSize: cellFont),
            textAlign: pw.TextAlign.left,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(
            _amt(row.credit),
            style: const pw.TextStyle(fontSize: cellFont),
            textAlign: pw.TextAlign.left,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: pw.Text(
            _amt(balance),
            style: pw.TextStyle(
              fontSize: cellFont,
              fontWeight: pw.FontWeight.bold,
              color: balance.abs() < 0.005
                  ? PdfColors.grey600
                  : (balance > 0 ? PdfColors.green800 : PdfColors.red800),
            ),
            textAlign: pw.TextAlign.left,
          ),
        ),
      ]),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.1), // الرصيد
      1: pw.FlexColumnWidth(1.1), // دائن
      2: pw.FlexColumnWidth(1.1), // مدين
      3: pw.FlexColumnWidth(0.8), // المستوى
      4: pw.FlexColumnWidth(3.2), // الاسم
      5: pw.FlexColumnWidth(1.0), // الرقم
    },
    children: [headerRow(), ...rows.map(bodyRow)],
  );
}

String _amt(num? value) {
  if (value == null || value.abs() < 0.005) return '—';
  return formatTreeAmount(value);
}
