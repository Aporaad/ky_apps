import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../data/models/account_group_statement_model.dart';
import '../widgets/account_statement_report_table.dart' show formatStatementAmount;
import 'report_pdf_fonts.dart';

/// يبني ملف PDF لتقرير "كشف حساب مجموعة حسابات جزئية" (التقرير 2 - ميزان
/// المراجعة) بنفس هيكل الجدول ثنائي الطبقات المعروض على الشاشة (`عملة محلية`
/// و`عملة أجنبية` فوق `مدين/دائن`)، عبر خط Cairo المضمّن من [ReportPdfFonts].
Future<Uint8List> buildAccountGroupStatementPdf({
  required ReportLetterheadInfo letterhead,
  required TrialBalanceReport report,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);

  // شعار الترويسة في وسط الشريط — null آمن إذا تعذّرت قراءة الأصل
  // The band's center logo; null-safe when the asset cannot be read.
  final logo = await loadPdfLetterheadLogo(height: 42);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => _letterhead(letterhead, report, logo),
      footer: (context) => _pageFooter(context),
      build: (context) => [_table(report), pw.SizedBox(height: 10), _totalRow(report)],
    ),
  );

  return doc.save();
}

class _PdfColors {
  static const PdfColor headerBg = PdfColor.fromInt(0xFFD4A853);
  static const PdfColor border = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor subtleText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor dangerRed = PdfColor.fromInt(0xFFDC2626);
}

pw.Widget _letterhead(
    ReportLetterheadInfo letterhead,
    TrialBalanceReport report,
    pw.Widget? logo) {
  final scopeLabel = report.scopeLabel.isNotEmpty
      ? 'مجموعة حسابات: ${report.scopeLabel}'
      : 'ميزان مراجعة';

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(width: 1, color: _PdfColors.border),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // ترويسة بثلاثة أعمدة (عربي / الشعار / إنجليزي) من إعدادات التطبيق —
        // نفس الكائن الذي ترسمه الشاشة
        // Three-column letterhead (Arabic / logo / English) from app config —
        // the very object the screen renders.
        reportPdfLetterheadBranding(letterhead, logo: logo),
        pw.SizedBox(height: 6),
        pw.Text(
          'كشف حساب مجموعة حسابات جزئية',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          scopeLabel,
          style: const pw.TextStyle(fontSize: 11),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              report.fromDate != null && report.toDate != null
                  ? 'من تاريخ: ${report.fromDate}   إلى تاريخ: ${report.toDate}'
                  : 'كل الحركات (بدون تحديد فترة)',
              style: const pw.TextStyle(fontSize: 9),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              'بتاريخ: ${report.asOfDate}',
              style: const pw.TextStyle(fontSize: 8, color: _PdfColors.subtleText),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pageFooter(pw.Context context) {
  return pw.Container(
    alignment: pw.Alignment.center,
    margin: const pw.EdgeInsets.only(top: 6),
    child: pw.Text(
      'صفحة ${context.pageNumber} من ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 7),
      textDirection: pw.TextDirection.rtl,
    ),
  );
}

pw.Widget _table(TrialBalanceReport report) {
  const subHeaderStyle = pw.TextStyle(fontSize: 8);
  const cellStyle = pw.TextStyle(fontSize: 7.5);

  return pw.Table(
    border: pw.TableBorder.all(color: _PdfColors.border, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.2), // رقم الحساب
      1: pw.FlexColumnWidth(3.2), // اسم الحساب
      2: pw.FlexColumnWidth(0.8), // العملة
      3: pw.FlexColumnWidth(1.4), // مدين محلي
      4: pw.FlexColumnWidth(1.4), // دائن محلي
      5: pw.FlexColumnWidth(1.4), // مدين أجنبي
      6: pw.FlexColumnWidth(1.4), // دائن أجنبي
      7: pw.FlexColumnWidth(1.5), // الرصيد
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      // الطبقة الأولى من الترويسة: مجمّعة "عملة محلية" / "عملة أجنبية"
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _PdfColors.headerBg),
        children: [
          _th('', subHeaderStyle),
          _th('إسم الحساب', subHeaderStyle),
          _th('العملة', subHeaderStyle),
          _th('عملة محلية', subHeaderStyle),
          _th('', subHeaderStyle),
          _th('عملة أجنبية', subHeaderStyle),
          _th('', subHeaderStyle),
          _th('الرصيد', subHeaderStyle),
        ],
      ),
      // الطبقة الثانية: مدين/دائن لكل من المحلي والأجنبي
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _PdfColors.headerBg),
        children: [
          _th('رقم الحساب', subHeaderStyle),
          _th('', subHeaderStyle),
          _th('', subHeaderStyle),
          _th('مدين', subHeaderStyle),
          _th('دائن', subHeaderStyle),
          _th('مدين', subHeaderStyle),
          _th('دائن', subHeaderStyle),
          _th('', subHeaderStyle),
        ],
      ),

      ...report.rows.map((row) {
        return pw.TableRow(
          children: [
            _td(row.accNo.toString(), cellStyle),
            _td(row.accName, cellStyle, align: pw.TextAlign.right),
            _td(row.curCode, cellStyle),
            _td(formatStatementAmount(row.localDebit), cellStyle),
            _td(formatStatementAmount(row.localCredit), cellStyle),
            _td(formatStatementAmount(row.foreignDebit), cellStyle),
            _td(formatStatementAmount(row.foreignCredit), cellStyle),
            _td(formatStatementAmount(row.balance), cellStyle, bold: true),
          ],
        );
      }),
    ],
  );
}

pw.Widget _totalRow(TrialBalanceReport report) {
  const style = pw.TextStyle(fontSize: 8.5);

  return pw.Container(
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(width: 1, color: _PdfColors.border),
      ),
    ),
    padding: const pw.EdgeInsets.only(top: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'إجمالي حسابات ${report.asOfDate}',
          style: style.copyWith(fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'محلي: مدين ${formatStatementAmount(report.totals.localDebit)} / دائن ${formatStatementAmount(report.totals.localCredit)}',
          style: style,
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'أجنبي: مدين ${formatStatementAmount(report.totals.foreignDebit)} / دائن ${formatStatementAmount(report.totals.foreignCredit)}',
          style: style,
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'الرصيد: ${formatStatementAmount(report.totals.balance)}',
          style: style.copyWith(fontWeight: pw.FontWeight.bold, color: _PdfColors.dangerRed),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    ),
  );
}

pw.Widget _th(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
    child: pw.Center(
      child: pw.Text(
        text,
        style: style.copyWith(fontWeight: pw.FontWeight.bold),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

pw.Widget _td(
  String text,
  pw.TextStyle style, {
  bool bold = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.center,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 2),
    child: text.isEmpty
        ? pw.SizedBox()
        : pw.Text(
            text,
            style: style.copyWith(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color ?? PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: align,
          ),
  );
}
