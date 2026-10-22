import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../widgets/account_statement_report_table.dart' show formatStatementAmount;

/// يبني ملف PDF لتقرير "كشف حساب تحليلي مفصل" (التقرير 2 التحليلي) بنفس البيانات
/// المعروضة على الشاشة: `summary` + `transactions`. يستخدم عناصر `pw` الموحّدة
/// مع خط Cairo المضمّن عبر [ReportPdfFonts]، وترويسة/تذييل/توقيعات موحّدة من
/// [report_pdf_page]، وتشكيل العربية المسبق عبر [pdfArabic] (حل تضارب حرف الياء).
///
/// أعمدة الجدول معكوسة ترتيباً بصرياً لأن `pw.Table` يرسم دائماً يسار→يمين، بينما
/// التقرير العربي (وشاشة Flutter) يرسل أول عمود (التأريخ) إلى أقصى اليمين.
///
/// يُستهلك من زرّي الطباعة (`Printing.layoutPdf`) والتصدير (`Printing.sharePdf`)
/// في `AccountStatementDetailScreen`، فيطابق المطبوع ما يراه المستخدم تماماً.
///
/// Builds the analytical detailed statement PDF from the SAME data the on-screen
/// report shows (`summary` + `transactions`), using the shared unified header /
/// footer / signatures and pre-shaped Arabic so print equals the screen.
Future<Uint8List> buildAccountStatementDetailPdf({
  required ReportLetterheadInfo letterhead,
  required String scopeLabel,
  required Map<String, dynamic> summary,
  required List<dynamic> transactions,
  String? currency,
  String? fromDate,
  String? toDate,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);

  // شعار الترويسة في وسط الشريط — null آمن إذا تعذّرت قراءة الأصل
  final logo = await loadPdfLetterheadLogo(height: 46);

  final rows = transactions.cast<Map<String, dynamic>>();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'كشف حساب تحليلي مفصل',
        logo: logo,
        metaSection: _metaSection(scopeLabel, currency, fromDate, toDate),
      ),
      footer: (context) => buildReportPdfFooter(context, currency: currency),
      build: (context) => [
        _table(rows, summary),
        pw.SizedBox(height: 10),
        _totals(summary),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف معلومات النطاق والتواريخ والعملة / Scope, dates & currency meta section
pw.Widget _metaSection(
  String scopeLabel,
  String? currency,
  String? fromDate,
  String? toDate,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              pdfArabic('النطاق: $scopeLabel'),
              style: const pw.TextStyle(fontSize: 10),
              textDirection: kPdfShapedTextDirection,
            ),
          ),
          if (currency != null && currency.isNotEmpty)
            pw.Text(
              pdfArabic(currency),
              style: const pw.TextStyle(fontSize: 10),
              textDirection: kPdfShapedTextDirection,
            ),
        ],
      ),
      pw.SizedBox(height: 2),
      pdfDateRangeRow(
        fromDate: fromDate,
        toDate: toDate,
        rightNote: 'توقيت الإصدار: ${_nowStamp()}',
      ),
    ],
  );
}

// ─── جدول الحركات التحليلية (أعمدة معكوسة لـ RTL) / Analytical transactions table ──
//
//pw.Table يرسم children يسار→يمين دائماً. لترتيب عربي صحيح (التأريخ يميناً
//والرصيد يساراً) نعكس قائمة الأطفال في كل صف.
pw.Widget _table(
  List<Map<String, dynamic>> rows,
  Map<String, dynamic> summary,
) {
  num v(String key) => (summary[key] as num?) ?? 0;

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    // الأعمدة بعد العكس: [الرصيد | دائن | مدين | البيان | التأريخ]
    columnWidths: const {
      0: pw.FlexColumnWidth(1.5), // الرصيد (was 4)
      1: pw.FlexColumnWidth(1.3), // دائن (was 3)
      2: pw.FlexColumnWidth(1.3), // مدين (was 2)
      3: pw.FlexColumnWidth(3.6), // البيان (was 1, center stays)
      4: pw.FlexColumnWidth(1.3), // التأريخ (was 0)
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // رأس الجدول — مرتب بصرياً يميناً→يساراً (معكوس)
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('التأريخ'),
          pdfTh('البيان'),
          pdfTh('مدين'),
          pdfTh('دائن'),
          pdfTh('الرصيد'),
        ]),
      ),
      // أسطر الحركات
      if (rows.isEmpty)
        pw.TableRow(
          children: reversedCells([
            pdfTd(''),
            pdfTd('لا توجد حركات ضمن النطاق المحدد', align: pw.TextAlign.center),
            pdfTd(''),
            pdfTd(''),
            pdfTd(''),
          ]),
        )
      else
        ...rows.map((tx) {
          final debit = (tx['debit'] as num?)?.toDouble() ?? 0;
          final credit = (tx['credit'] as num?)?.toDouble() ?? 0;
          final balance = (tx['balance'] as num?)?.toDouble() ?? 0;
          return pw.TableRow(
            children: reversedCells([
              pdfTd(tx['date']?.toString() ?? ''),
              pdfTd(tx['description']?.toString() ?? '',
                  align: pw.TextAlign.right),
              pdfTd(formatStatementAmount(debit)),
              pdfTd(formatStatementAmount(credit)),
              pdfTd(formatStatementAmount(balance), bold: true),
            ]),
          );
        }),
      // سطر الإجمالي
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.rowStripe),
        children: reversedCells([
          pdfTd(''),
          pdfTd('اجمالي العمليات', bold: true),
          pdfTd(formatStatementAmount(v('total_debit').toDouble()), bold: true),
          pdfTd(formatStatementAmount(v('total_credit').toDouble()), bold: true),
          pdfTd(formatStatementAmount(v('net_movement').toDouble()), bold: true),
        ]),
      ),
    ],
  );
}

// ─── صندوق الملخص / Totals box ──────────────────────────────────────────────────
pw.Widget _totals(Map<String, dynamic> summary) {
  num v(String key) => (summary[key] as num?) ?? 0;
  return pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Container(
      width: 240,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: ReportPdfColors.border, width: 0.5),
      ),
      child: pw.Column(
        children: [
          _totalsRow('عدد الحركات', '${v('total_records').toInt()}'),
          _totalsDivider(),
          _totalsRow('إجمالي المدين', formatStatementAmount(v('total_debit').toDouble())),
          _totalsDivider(),
          _totalsRow('إجمالي الدائن', formatStatementAmount(v('total_credit').toDouble())),
          _totalsDivider(),
          _totalsRow('صافي الحركة', formatStatementAmount(v('net_movement').toDouble()),
              highlight: true),
        ],
      ),
    ),
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
