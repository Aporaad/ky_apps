import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../../accounts/presentation/widgets/account_statement_report_table.dart'
    show formatStatementAmount;
import '../../data/models/worker_work_report_model.dart';

/// يبني ملف PDF لتقرير "كشف حساب العمل" (قصاص/خياط) بنفس جدول الكشف بخمسة أعمدة
/// المعروض على الشاشة (التاريخ | الموديل | العدد | السعر | الإجمالي) مع الترويسة
/// والتذييل الرسميين الموحدين - مطابقاً لقالب أوراكل FOR_CUTTER_TAILOR / FOR_TAILOR.
///
/// Builds the work-report PDF with the same five-column table from the screen,
/// using the unified header/footer/signature module — mirroring the legacy Oracle template.
Future<Uint8List> buildWorkerWorkReportPdf({
  required ReportLetterheadInfo letterhead,
  required String title,
  required String workerName,
  required String accNo,
  required String currency,
  required String fromDate,
  required String toDate,
  required List<WorkerWorkRow> rows,
  required double totalCount,
  required double totalAmount,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: title,
        logo: logo,
        metaSection: _metaSection(workerName, accNo, currency, fromDate, toDate),
      ),
      footer: (context) => buildReportPdfFooter(context, currency: currency),
      build: (context) => [
        _table(rows, totalCount, totalAmount),
        pw.SizedBox(height: 12),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف بيانات العامل والتواريخ / Worker meta + date-range row
pw.Widget _metaSection(
  String workerName,
  String accNo,
  String currency,
  String fromDate,
  String toDate,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'كشف له: $workerName  |  حساب: $accNo',
              style: const pw.TextStyle(fontSize: 10),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          if (currency.isNotEmpty)
            pw.Text(
              currency,
              style: const pw.TextStyle(fontSize: 10),
              textDirection: pw.TextDirection.rtl,
            ),
        ],
      ),
      pw.SizedBox(height: 2),
      pdfDateRangeRow(fromDate: fromDate, toDate: toDate),
    ],
  );
}

// ─── جدول كشف العمل (أعمدة معكوسة لـ RTL) ─────────────────────────────────────
pw.Widget _table(List<WorkerWorkRow> rows, double totalCount, double totalAmount) {
  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.2), // الإجمالي (يظهر يساراً بعد العكس)
      1: pw.FlexColumnWidth(1.3), // السعر
      2: pw.FlexColumnWidth(1.0), // العدد
      3: pw.FlexColumnWidth(1.6), // الموديل
      4: pw.FlexColumnWidth(1.5), // التاريخ (يظهر يميناً بعد العكس)
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // رأس الجدول الذهبي — revertedCells يضع التاريخ في أقصى اليمين
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('التاريخ'),
          pdfTh('الموديل'),
          pdfTh('العدد'),
          pdfTh('السعر'),
          pdfTh('الإجمالي'),
        ]),
      ),
      // أسطر البيانات
      ...rows.map(
        (row) => pw.TableRow(
          children: reversedCells([
            pdfTd(row.date),
            pdfTd(row.styleName, align: pw.TextAlign.center),
            pdfTd(formatStatementAmount(row.count)),
            pdfTd(formatStatementAmount(row.unitPrice)),
            pdfTd(formatStatementAmount(row.total), bold: true),
          ]),
        ),
      ),
      // سطر إجمالي العدد
      if (rows.isNotEmpty)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
          children: reversedCells([
            pdfTd(''),
            pdfTd('إجــمالي العدد', bold: true, align: pw.TextAlign.right),
            pdfTd(''),
            pdfTd(''),
            pdfTd(formatStatementAmount(totalCount), bold: true),
          ]),
        ),
      // سطر الإجمالي لكم (المبلغ)
      if (rows.isNotEmpty)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
          children: reversedCells([
            pdfTd(''),
            pdfTd('الإجمــالي لكم', bold: true, align: pw.TextAlign.right),
            pdfTd(''),
            pdfTd(''),
            pdfTd(
              formatStatementAmount(totalAmount),
              bold: true,
              color: ReportPdfColors.dangerRed,
            ),
          ]),
        ),
    ],
  );
}
