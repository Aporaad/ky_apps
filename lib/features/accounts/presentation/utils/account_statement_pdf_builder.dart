import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../data/models/chart_account_model.dart';
import '../widgets/account_statement_report_table.dart' show formatStatementAmount;
import 'report_pdf_fonts.dart';

/// يبني ملف PDF لتقرير "كشف حساب مالي" (التقرير 1) بنفس هيكل الجدول/التذييل
/// المعروض على الشاشة، باستخدام عناصر `pw` من حزمة `pdf` مع خط Cairo المضمّن
/// عبر [ReportPdfFonts] لضمان تشكيل العربية واتجاهها بشكل صحيح.
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
  // The band's center logo; null-safe when the asset cannot be read.
  final logo = await loadPdfLetterheadLogo(height: 46);

  final accName =
      statement.account?['acc_name']?.toString() ?? (account?.accName ?? '');
  final accNo =
      statement.account?['acc_no']?.toString() ?? (account?.accNo.toString() ?? '');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => _letterhead(letterhead, accNo, accName, statement, logo),
      footer: (context) => _pageFooter(context, statement.currency),
      build: (context) => [
        _table(statement),
        pw.SizedBox(height: 10),
        _totalsAndSignatures(statement),
      ],
    ),
  );

  return doc.save();
}

class _PdfColors {
  static const PdfColor headerBg = PdfColor.fromInt(0xFFD4A853);
  static const PdfColor border = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor subtleText = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor rowStripe = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor accentBlue = PdfColor.fromInt(0xFF0369A1);
  static const PdfColor dangerRed = PdfColor.fromInt(0xFFDC2626);
}

pw.Widget _letterhead(
    ReportLetterheadInfo letterhead,
    String accNo,
    String accName,
    AccountStatementData statement,
    pw.Widget? logo) {
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
          'كشف حساب مالي',
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'الحساب: [$accNo] $accName',
                style: const pw.TextStyle(fontSize: 10),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            if (statement.currency != null && statement.currency!.isNotEmpty)
              pw.Text(
                statement.currency!,
                style: const pw.TextStyle(fontSize: 10),
                textDirection: pw.TextDirection.rtl,
              ),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'من تاريخ: ${statement.fromDate ?? '-'}   إلى تاريخ: ${statement.toDate ?? '-'}',
              style: const pw.TextStyle(fontSize: 9),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              'توقيت الإصدار: ${_nowStamp()}',
              style: const pw.TextStyle(fontSize: 8, color: _PdfColors.subtleText),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _pageFooter(pw.Context context, String? currency) {
  return pw.Container(
    alignment: pw.Alignment.center,
    margin: const pw.EdgeInsets.only(top: 6),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          currency != null && currency.isNotEmpty ? 'العملة: $currency' : '',
          style: const pw.TextStyle(fontSize: 7),
          textDirection: pw.TextDirection.rtl,
        ),
        pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    ),
  );
}

pw.Widget _table(AccountStatementData statement) {
  const headerStyle = pw.TextStyle(fontSize: 8.5);
  const cellStyle = pw.TextStyle(fontSize: 8);

  final rows = statement.transactions;

  return pw.Table(
    border: pw.TableBorder.all(color: _PdfColors.border, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(0.9),
      1: pw.FlexColumnWidth(1.1),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(2.8),
      4: pw.FlexColumnWidth(1.35),
      5: pw.FlexColumnWidth(1.35),
      6: pw.FlexColumnWidth(1.4),
    },
    defaultColumnWidth: const pw.FlexColumnWidth(1),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _PdfColors.headerBg),
        children: [
          _th('السند', headerStyle),
          _th('النوع', headerStyle),
          _th('تأريخه', headerStyle),
          _th('البيان', headerStyle),
          _th('مدين', headerStyle),
          _th('دائن', headerStyle),
          _th('الرصيد', headerStyle),
        ],
      ),
      pw.TableRow(
        children: [
          _td('', cellStyle),
          _td('', cellStyle),
          _td('', cellStyle),
          _td(
            'رصيد افتتاحي',
            cellStyle,
            bold: true,
            color: _PdfColors.accentBlue,
          ),
          _td(
            formatStatementAmount(
                (statement.openingBalance ?? 0) >= 0 ? statement.openingBalance ?? 0 : 0),
            cellStyle,
            bold: true,
            color: _PdfColors.dangerRed,
          ),
          _td(
            formatStatementAmount(
                (statement.openingBalance ?? 0) < 0 ? (statement.openingBalance ?? 0).abs() : 0),
            cellStyle,
            bold: true,
            color: _PdfColors.dangerRed,
          ),
          _td(
            formatStatementAmount(statement.openingBalance),
            cellStyle,
            bold: true,
          ),
        ],
      ),
      ...rows.map((tx) {
        return pw.TableRow(
          children: [
            _td(
              tx.subEntryNo?.isNotEmpty == true
                  ? tx.subEntryNo!
                  : (tx.entryNo?.toString() ?? ''),
              cellStyle,
            ),
            _td(tx.entryTypeName ?? '', cellStyle),
            _td(tx.date ?? '', cellStyle),
            _td(tx.description ?? '', cellStyle, align: pw.TextAlign.right),
            _td(formatStatementAmount(tx.debit), cellStyle),
            _td(formatStatementAmount(tx.credit), cellStyle),
            _td(formatStatementAmount(tx.balance), cellStyle, bold: true),
          ],
        );
      }),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _PdfColors.rowStripe),
        children: [
          _td('', cellStyle),
          _td('', cellStyle),
          _td('', cellStyle),
          _td('اجمالي العمليات', cellStyle, bold: true),
          _td(formatStatementAmount(statement.totalDebit), cellStyle, bold: true),
          _td(formatStatementAmount(statement.totalCredit), cellStyle, bold: true),
          _td(formatStatementAmount(statement.finalBalance), cellStyle, bold: true),
        ],
      ),
    ],
  );
}

pw.Widget _th(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
    padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
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

pw.Widget _totalsAndSignatures(AccountStatementData statement) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _PdfColors.border, width: 0.5),
          ),
          child: pw.Column(
            children: [
              _totalsRow('الرصيد الافتتاحي', formatStatementAmount(statement.openingBalance)),
              _totalsDivider(),
              _totalsRow('إجمالي المدين', formatStatementAmount(statement.totalDebit)),
              _totalsDivider(),
              _totalsRow('إجمالي الدائن', formatStatementAmount(statement.totalCredit)),
              _totalsDivider(),
              _totalsRow('الرصيد النهائي', formatStatementAmount(statement.finalBalance),
                  highlight: true),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 30),
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
          'يجب مراجعة هذا الكشف خلال 15 يوماً من تاريخ إصداره، وما بعد ذلك يُعتبر معتمداً.',
          style: const pw.TextStyle(fontSize: 7.5, color: _PdfColors.subtleText),
          textDirection: pw.TextDirection.rtl,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}

pw.Widget _totalsDivider() => pw.Container(height: 0.5, color: _PdfColors.border);

pw.Widget _totalsRow(String label, String value, {bool highlight = false}) {
  return pw.Row(
    children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          color: highlight ? _PdfColors.headerBg : PdfColors.white,
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
      pw.Container(width: 0.5, height: 20, color: _PdfColors.border),
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
              color: highlight ? _PdfColors.dangerRed : PdfColors.black,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
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
        label,
        style: const pw.TextStyle(fontSize: 8),
        textDirection: pw.TextDirection.rtl,
      ),
    ],
  );
}

String _nowStamp() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
