import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../data/models/chart_account_model.dart';
import '../widgets/account_statement_report_table.dart' show formatStatementAmount;

/// يبني ملف PDF لتقرير "كشف حساب مالي" (التقرير 1) بنفس هيكل الجدول/التذييل
/// المعروض على الشاشة، باستخدام عناصر `pw` من حزمة `pdf` مع خط Cairo المضمّن
/// عبر [ReportPdfFonts] لضمان تشكيل العربية واتجاهها بشكل صحيح.
///
/// أعمدة الجدول معكوسة ترتيباً بصرياً لأن `pw.Table` يرسم دائماً يسار→يمين،
/// بينما التقرير العربي (وشاشة Flutter) يرسل أول عمود (السند) إلى أقصى اليمين.
///
/// يُستخدم من زرّي الطباعة (`Printing.layoutPdf`) والتصدير
/// (`Printing.sharePdf`) في `AccountStatementScreen`.
Future<Uint8List> buildAccountStatementPdf({
  required ReportLetterheadInfo letterhead,
  required ChartAccountModel? account,
  required AccountStatementData statement,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);

  // شعار الترويسة في وسط الشريط — null آمن إذا تعذّرت قراءة الأصل
  final logo = await loadPdfLetterheadLogo(height: 46);

  final accName =
      statement.account?['acc_name']?.toString() ?? (account?.accName ?? '');
  final accNo =
      statement.account?['acc_no']?.toString() ??
          (account?.accNo.toString() ?? '');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'كشف حساب مالي',
        logo: logo,
        metaSection: _metaSection(accNo, accName, statement),
      ),
      footer: (context) =>
          buildReportPdfFooter(context, currency: statement.currency),
      build: (context) => [
        _table(statement),
        pw.SizedBox(height: 10),
        _totalsAndSignatures(statement),
      ],
    ),
  );

  return doc.save();
}

/// صف معلومات الحساب والتواريخ / Account & dates meta section
pw.Widget _metaSection(
    String accNo, String accName, AccountStatementData statement) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              pdfArabic('الحساب: [$accNo] $accName'),
              style: const pw.TextStyle(fontSize: 10),
              textDirection: kPdfShapedTextDirection,
            ),
          ),
          if (statement.currency != null && statement.currency!.isNotEmpty)
            pw.Text(
              pdfArabic(statement.currency!),
              style: const pw.TextStyle(fontSize: 10),
              textDirection: kPdfShapedTextDirection,
            ),
        ],
      ),
      pw.SizedBox(height: 2),
      pdfDateRangeRow(
        fromDate: statement.fromDate,
        toDate: statement.toDate,
        rightNote: 'توقيت الإصدار: ${_nowStamp()}',
      ),
    ],
  );
}

// ─── جدول الحركات (أعمدة معكوسة لـ RTL) / Transactions table (reversed for RTL) ──
//
// pw.Table يرسم children يسار→يمين دائماً. لترتيب عربي صحيح (السند يميناً
// والرصيد يساراً) نعكس قائمة الأطفال في كل صف.
pw.Widget _table(AccountStatementData statement) {
  final rows = statement.transactions;

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    // الأعمدة بعد العكس: [الرصيد | دائن | مدين | البيان | تأريخه | النوع | السند]
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4), // الرصيد (was 6)
      1: pw.FlexColumnWidth(1.35), // دائن (was 5)
      2: pw.FlexColumnWidth(1.35), // مدين (was 4)
      3: pw.FlexColumnWidth(2.8), // البيان (was 3, center stays)
      4: pw.FlexColumnWidth(1.2), // تأريخه (was 2)
      5: pw.FlexColumnWidth(1.1), // النوع (was 1)
      6: pw.FlexColumnWidth(0.9), // السند (was 0)
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // رأس الجدول — مرتبة من اليسار إلى اليمين بصرياً (معكوسة)
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
      // سطر الرصيد الافتتاحي
      pw.TableRow(
        children: reversedCells([
          pdfTd(''),
          pdfTd(''),
          pdfTd(''),
          pdfTd('رصيد افتتاحي',
              bold: true, color: ReportPdfColors.accentBlue),
          pdfTd(
            formatStatementAmount(
                (statement.openingBalance ?? 0) >= 0
                    ? statement.openingBalance ?? 0
                    : 0),
            bold: true,
            color: ReportPdfColors.dangerRed,
          ),
          pdfTd(
            formatStatementAmount(
                (statement.openingBalance ?? 0) < 0
                    ? (statement.openingBalance ?? 0).abs()
                    : 0),
            bold: true,
            color: ReportPdfColors.dangerRed,
          ),
          pdfTd(formatStatementAmount(statement.openingBalance), bold: true),
        ]),
      ),
      // أسطر الحركات
      ...rows.map((tx) {
        return pw.TableRow(
          children: reversedCells([
            pdfTd(
              tx.subEntryNo?.isNotEmpty == true
                  ? tx.subEntryNo!
                  : (tx.entryNo?.toString() ?? ''),
            ),
            pdfTd(tx.entryTypeName ?? ''),
            pdfTd(tx.date ?? ''),
            pdfTd(tx.description ?? '', align: pw.TextAlign.right),
            pdfTd(formatStatementAmount(tx.debit)),
            pdfTd(formatStatementAmount(tx.credit)),
            pdfTd(formatStatementAmount(tx.balance), bold: true),
          ]),
        );
      }),
      // سطر الإجمالي
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
        children: reversedCells([
          pdfTd(''),
          pdfTd(''),
          pdfTd(''),
          pdfTd('اجمالي العمليات', bold: true),
          pdfTd(formatStatementAmount(statement.totalDebit), bold: true),
          pdfTd(formatStatementAmount(statement.totalCredit), bold: true),
          pdfTd(formatStatementAmount(statement.finalBalance), bold: true),
        ]),
      ),
    ],
  );
}

// ─── الملخص والتوقيعات / Totals box + signatures ────────────────────────────────
pw.Widget _totalsAndSignatures(AccountStatementData statement) {
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
              _totalsRow('الرصيد الافتتاحي',
                  formatStatementAmount(statement.openingBalance)),
              _totalsDivider(),
              _totalsRow('إجمالي المدين',
                  formatStatementAmount(statement.totalDebit)),
              _totalsDivider(),
              _totalsRow('إجمالي الدائن',
                  formatStatementAmount(statement.totalCredit)),
              _totalsDivider(),
              _totalsRow('الرصيد النهائي',
                  formatStatementAmount(statement.finalBalance),
                  highlight: true),
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
            pdfArabic(label),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textDirection: kPdfShapedTextDirection,
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
            textDirection: kPdfShapedTextDirection,
          ),
        ),
      ),
    ],
  );
}

String _nowStamp() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
