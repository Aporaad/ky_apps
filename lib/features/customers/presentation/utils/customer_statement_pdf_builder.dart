import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../../accounts/presentation/widgets/account_statement_report_table.dart'
    show formatStatementAmount;
import '../../data/models/customer_statement_model.dart';

/// يبني ملف PDF لتقرير "كشف حساب عميل" بنفس هيكل الجدول السباعي (السند | النوع |
/// تأريخه | البيان | مدين | دائن | الرصيد) المعروض على الشاشة، مع الترويسة الموحدة
/// والتذييل الرسمي والتوقيعات.
///
/// Builds the "Customer Statement" PDF with the same seven-column table layout
/// (voucher | type | date | description | debit | credit | balance) shown on screen,
/// using the unified header/footer module and signature block.
Future<Uint8List> buildCustomerStatementPdf({
  required ReportLetterheadInfo letterhead,
  required String customerName,
  required String customerCode,
  required String currency,
  required String fromDate,
  required String toDate,
  required List<CustomerStatementModel> rows,
  required double openingBalance,
  required double totalDebit,
  required double totalCredit,
  required double finalBalance,
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
        title: 'كشف حساب عميل',
        logo: logo,
        metaSection: _metaSection(customerName, customerCode, currency, fromDate, toDate),
      ),
      footer: (context) => buildReportPdfFooter(context, currency: currency),
      build: (context) => [
        _table(rows, openingBalance, totalDebit, totalCredit, finalBalance),
        pw.SizedBox(height: 10),
        _totalsAndSignatures(openingBalance, totalDebit, totalCredit, finalBalance),
      ],
    ),
  );

  return doc.save();
}

/// صف بيانات العميل والتواريخ / Customer meta & dates row
pw.Widget _metaSection(
  String customerName,
  String customerCode,
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
              'العميل: $customerName  ($customerCode)',
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

// ─── جدول كشف الحساب (أعمدة معكوسة لـ RTL) ────────────────────────────────────
pw.Widget _table(
  List<CustomerStatementModel> rows,
  double openingBalance,
  double totalDebit,
  double totalCredit,
  double finalBalance,
) {
  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4),  // الرصيد
      1: pw.FlexColumnWidth(1.35), // دائن
      2: pw.FlexColumnWidth(1.35), // مدين
      3: pw.FlexColumnWidth(2.8),  // البيان
      4: pw.FlexColumnWidth(1.2),  // تأريخه
      5: pw.FlexColumnWidth(1.1),  // النوع
      6: pw.FlexColumnWidth(0.9),  // السند
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // رأس الجدول / Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('السند'),
          pdfTh('النوع'),
          pdfTh('تأريخه'),
          pdfTh('البيان'),
          pdfTh('مدين'),
          pdfTh('دائن'),
          pdfTh('الرصيد'),
        ]),
      ),
      // سطر الرصيد الافتتاحي / Opening balance
      pw.TableRow(
        children: reversedCells([
          pdfTd(''),
          pdfTd(''),
          pdfTd(''),
          pdfTd('رصيد افتتاحي', bold: true, color: ReportPdfColors.accentBlue),
          pdfTd(
            formatStatementAmount(openingBalance >= 0 ? openingBalance : 0),
            bold: true,
            color: ReportPdfColors.dangerRed,
          ),
          pdfTd(
            formatStatementAmount(openingBalance < 0 ? openingBalance.abs() : 0),
            bold: true,
            color: ReportPdfColors.dangerRed,
          ),
          pdfTd(formatStatementAmount(openingBalance), bold: true),
        ]),
      ),
      // أسطر الحركات / Transaction rows
      ...rows.map((row) {
        final debitVal = row.debit ??
            ((row.entryMnt ?? 0) > 0 ? row.entryMnt! : 0.0);
        final creditVal = row.credit ??
            ((row.entryMnt ?? 0) < 0 ? (row.entryMnt!).abs() : 0.0);
        final balVal = row.balanceS ?? 0.0;

        return pw.TableRow(
          children: reversedCells([
            pdfTd(row.subEntryNo ?? row.entryNo ?? ''),
            pdfTd(row.entryTypeName ?? ''),
            pdfTd(row.entryDate ?? ''),
            pdfTd(row.details ?? '', align: pw.TextAlign.right),
            pdfTd(formatStatementAmount(debitVal)),
            pdfTd(formatStatementAmount(creditVal)),
            pdfTd(formatStatementAmount(balVal), bold: true),
          ]),
        );
      }),
      // سطر الإجمالي / Totals row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
        children: reversedCells([
          pdfTd(''),
          pdfTd(''),
          pdfTd(''),
          pdfTd('اجمالي العمليات', bold: true),
          pdfTd(formatStatementAmount(totalDebit), bold: true),
          pdfTd(formatStatementAmount(totalCredit), bold: true),
          pdfTd(formatStatementAmount(finalBalance), bold: true),
        ]),
      ),
    ],
  );
}

// ─── الملخص والتوقيعات / Totals box + signatures ────────────────────────────────
pw.Widget _totalsAndSignatures(
  double openingBalance,
  double totalDebit,
  double totalCredit,
  double finalBalance,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: ReportPdfColors.border, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _totalsRow('الرصيد الافتتاحي', formatStatementAmount(openingBalance)),
              _totalsDivider(),
              _totalsRow('إجمالي المدين', formatStatementAmount(totalDebit)),
              _totalsDivider(),
              _totalsRow('إجمالي الدائن', formatStatementAmount(totalCredit)),
              _totalsDivider(),
              _totalsRow('الرصيد النهائي', formatStatementAmount(finalBalance), highlight: true),
            ],
          ),
        ),
      ),
      pdfSignatures(),
    ],
  );
}

pw.Widget _totalsDivider() =>
    pw.Container(height: 0.5, color: ReportPdfColors.border);

pw.Widget _totalsRow(String label, String value, {bool highlight = false}) {
  return pw.Row(
    children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          color: highlight ? ReportPdfColors.headerBg : PdfColors.white,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          alignment: pw.Alignment.center,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ),
      pw.Container(width: 0.5, height: 20, color: ReportPdfColors.border),
      pw.Expanded(
        flex: 2,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(
            value,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: highlight ? 9.5 : 8.5,
              fontWeight: pw.FontWeight.bold,
              color: highlight ? ReportPdfColors.dangerRed : PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      ),
    ],
  );
}
