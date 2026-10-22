import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../data/models/account_group_statement_model.dart';
import '../widgets/account_statement_report_table.dart' show formatStatementAmount;

/// يبني ملف PDF لتقرير "كشف حساب مجموعة حسابات جزئية" (التقرير 2 - ميزان
/// المراجعة) بنفس هيكل الجدول ثنائي الطبقات المعروض على الشاشة، بتنسيق A4 عرضي.
///
/// أعمدة الجدول معكوسة ترتيباً بصرياً لأن `pw.Table` يرسم دائماً يسار→يمين،
/// بينما التقرير العربي يرسل أول عمود (رقم الحساب) إلى أقصى اليمين.
Future<Uint8List> buildAccountGroupStatementPdf({
  required ReportLetterheadInfo letterhead,
  required TrialBalanceReport report,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);

  final logo = await loadPdfLetterheadLogo(height: 42);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'كشف حساب مجموعة حسابات جزئية',
        logo: logo,
        metaSection: _metaSection(report),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        _table(report),
        pw.SizedBox(height: 10),
        _totalRow(report),
        // تذييل التوقيعات الموحّد — كان مفقوداً في هذا التقرير
        // Unified signature footer — previously missing on this report.
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف معلومات النطاق والتواريخ / Scope & dates meta section
pw.Widget _metaSection(TrialBalanceReport report) {
  final scopeLabel = report.scopeLabel.isNotEmpty
      ? 'مجموعة حسابات: ${report.scopeLabel}'
      : 'ميزان مراجعة';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Text(
        pdfArabic(scopeLabel),
        style: const pw.TextStyle(fontSize: 11),
        textDirection: kPdfShapedTextDirection,
      ),
      pw.SizedBox(height: 2),
      pdfDateRangeRow(
        fromDate: report.fromDate,
        toDate: report.toDate,
        rightNote: 'بتاريخ: ${report.asOfDate}',
      ),
    ],
  );
}

// ─── جدول ميزان المراجعة (أعمدة معكوسة لـ RTL) / Trial balance table (reversed) ──
//
// الأعمدة الأصلية (يمين→يسار منطقياً):
// [رقم الحساب | إسم الحساب | العملة | مدين محلي | دائن محلي | مدين أجنبي | دائن أجنبي | الرصيد]
// بعد العكس للـ pw.Table (الذي يرسم يسار→يمين):
// [الرصيد | دائن أجنبي | مدين أجنبي | دائن محلي | مدين محلي | العملة | إسم الحساب | رقم الحساب]
pw.Widget _table(TrialBalanceReport report) {
  const cellStyle = 7.5;

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    // الأعمدة بعد العكس (الفلكسات معكوسة)
    columnWidths: const {
      0: pw.FlexColumnWidth(1.5), // الرصيد (was 7)
      1: pw.FlexColumnWidth(1.4), // دائن أجنبي (was 6)
      2: pw.FlexColumnWidth(1.4), // مدين أجنبي (was 5)
      3: pw.FlexColumnWidth(1.4), // دائن محلي (was 4)
      4: pw.FlexColumnWidth(1.4), // مدين محلي (was 3)
      5: pw.FlexColumnWidth(0.8), // العملة (was 2)
      6: pw.FlexColumnWidth(3.2), // إسم الحساب (was 1)
      7: pw.FlexColumnWidth(1.2), // رقم الحساب (was 0)
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // الطبقة الأولى: ترويسة مجمّعة
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('', fontSize: 8),
          pdfTh('إسم الحساب', fontSize: 8),
          pdfTh('العملة', fontSize: 8),
          pdfTh('عملة محلية', fontSize: 8),
          pdfTh('', fontSize: 8),
          pdfTh('عملة أجنبية', fontSize: 8),
          pdfTh('', fontSize: 8),
          pdfTh('الرصيد', fontSize: 8),
        ]),
      ),
      // الطبقة الثانية: مدين/دائن
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('رقم الحساب', fontSize: 8),
          pdfTh('', fontSize: 8),
          pdfTh('', fontSize: 8),
          pdfTh('مدين', fontSize: 8),
          pdfTh('دائن', fontSize: 8),
          pdfTh('مدين', fontSize: 8),
          pdfTh('دائن', fontSize: 8),
          pdfTh('', fontSize: 8),
        ]),
      ),
      // أسطر الحسابات
      ...report.rows.map((row) {
        return pw.TableRow(
          children: reversedCells([
            pdfTd(row.accNo.toString(), fontSize: cellStyle),
            pdfTd(row.accName, fontSize: cellStyle, align: pw.TextAlign.right),
            pdfTd(row.curCode, fontSize: cellStyle),
            pdfTd(formatStatementAmount(row.localDebit), fontSize: cellStyle),
            pdfTd(formatStatementAmount(row.localCredit), fontSize: cellStyle),
            pdfTd(formatStatementAmount(row.foreignDebit), fontSize: cellStyle),
            pdfTd(formatStatementAmount(row.foreignCredit), fontSize: cellStyle),
            pdfTd(formatStatementAmount(row.balance),
                fontSize: cellStyle, bold: true),
          ]),
        );
      }),
    ],
  );
}

// ─── سطر الإجمالي العام / Grand total row ───────────────────────────────────────
pw.Widget _totalRow(TrialBalanceReport report) {
  const style = pw.TextStyle(fontSize: 8.5);

  return pw.Container(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(width: 1, color: ReportPdfColors.border),
      ),
    ),
    padding: const pw.EdgeInsets.only(top: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          pdfArabic('إجمالي حسابات ${report.asOfDate}'),
          style: style.copyWith(fontWeight: pw.FontWeight.bold),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic(
              'محلي: مدين ${formatStatementAmount(report.totals.localDebit)} / دائن ${formatStatementAmount(report.totals.localCredit)}'),
          style: style,
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic(
              'أجنبي: مدين ${formatStatementAmount(report.totals.foreignDebit)} / دائن ${formatStatementAmount(report.totals.foreignCredit)}'),
          style: style,
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic('الرصيد: ${formatStatementAmount(report.totals.balance)}'),
          style: style.copyWith(
              fontWeight: pw.FontWeight.bold, color: ReportPdfColors.dangerRed),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
    ),
  );
}
