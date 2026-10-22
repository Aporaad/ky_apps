import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../../accounts/presentation/widgets/account_statement_report_table.dart'
    show formatStatementAmount;
import '../../data/models/worker_group_work_report_model.dart';

/// يبني ملف PDF لتقرير "كشف عمل المجموعة" بخمسة أعمدة مُجمّعة لكل (عامل + موديل)
/// (الاسم | الموديل | العدد | السعر | الإجمالي)
/// مع الترويسة والتذييل الرسميين الموحدين.
///
/// Builds the group work-report PDF with five aggregated columns per (worker + style):
/// Name | Style | Count | Price | Total, using the unified header/footer/signature module.
Future<Uint8List> buildWorkerGroupWorkReportPdf({
  required ReportLetterheadInfo letterhead,
  required String title,
  required String groupLabel,
  required String fromDate,
  required String toDate,
  required List<WorkerGroupWorkRow> rows,
  required double totalCount,
  required double totalAmount,
  required int workerCount,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: title,
        logo: logo,
        metaSection: _metaSection(groupLabel, fromDate, toDate, workerCount),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        _table(rows, totalCount, totalAmount),
        pw.SizedBox(height: 12),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف معلومات المجموعة والتواريخ
pw.Widget _metaSection(
  String groupLabel,
  String fromDate,
  String toDate,
  int workerCount,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pdfArabic('المجموعة: $groupLabel'),
            style: const pw.TextStyle(fontSize: 10),
            textDirection: kPdfShapedTextDirection,
          ),
          pw.Text(
            pdfArabic('عدد  $groupLabel: $workerCount'),
            style: const pw.TextStyle(fontSize: 10),
            textDirection: kPdfShapedTextDirection,
          ),
        ],
      ),
      pw.SizedBox(height: 2),
      pdfDateRangeRow(fromDate: fromDate, toDate: toDate),
    ],
  );
}

// ─── جدول كشف عمل المجموعة (5 أعمدة مُجمّعة، معكوسة لـ RTL) ──────────────────────
pw.Widget _table(List<WorkerGroupWorkRow> rows, double totalCount, double totalAmount) {
  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4), // الإجمالي (يظهر يساراً بعد العكس)
      1: pw.FlexColumnWidth(1.2), // السعر
      2: pw.FlexColumnWidth(1.0), // العدد
      3: pw.FlexColumnWidth(1.6), // الموديل
      4: pw.FlexColumnWidth(2.2), // الاسم (يظهر يميناً بعد العكس)
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // رأس الجدول الذهبي
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('الاسم'),
          pdfTh('الموديل'),
          pdfTh('العدد'),
          pdfTh('السعر'),
          pdfTh('الإجمالي'),
        ]),
      ),
      // أسطر البيانات — اسم العامل يُطبع مرة واحدة أعلى مجموعته، ويُترك فارغاً
      // في بقية أسطر نفس العامل (محاكاة للدمج الرأسي، إذ لا يدعم PDF الدمج).
      // The worker name is printed on the first row of each group and left blank on
      // the following rows of the same worker (rowspan is unsupported in the PDF table).
      for (int i = 0; i < rows.length; i++)
        pw.TableRow(
          children: reversedCells([
            pdfTd(
              (i == 0 || rows[i].workerName != rows[i - 1].workerName)
                  ? rows[i].workerName
                  : '',
              align: pw.TextAlign.right,
              bold: true,
            ),
            pdfTd(rows[i].styleName, align: pw.TextAlign.right),
            pdfTd(formatStatementAmount(rows[i].count)),
            pdfTd(formatStatementAmount(rows[i].unitPrice)),
            pdfTd(formatStatementAmount(rows[i].total), bold: true),
          ]),
        ),
      // سطر إجمالي العدد — القيمة في عمود العدد
      if (rows.isNotEmpty)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
          children: reversedCells([
            pdfTd('إجــمالي العدد', bold: true, align: pw.TextAlign.right),
            pdfTd(''),
            pdfTd(formatStatementAmount(totalCount), bold: true),
            pdfTd(''),
            pdfTd(''),
          ]),
        ),
      // سطر الإجمالي لكم (المبلغ) — القيمة في عمود الإجمالي
      if (rows.isNotEmpty)
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
          children: reversedCells([
            pdfTd('الإجمــالي', bold: true, align: pw.TextAlign.right),
            pdfTd(''),
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
