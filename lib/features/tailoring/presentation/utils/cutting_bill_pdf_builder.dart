import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/tailoring_parse.dart';

/// يبني ملف PDF لفاتورة التفصيل: الترويسة الموحّدة + كتلة الفاتورة/العميل + كتلة الدفع
/// + جدول الموديلات + جدول الأقمشة + تذييل التوقيعات.
/// Builds the cutting-bill PDF: the unified letterhead, the invoice/customer block, the payment
/// block, the models table, the fabrics table and the signature footer.
///
/// يستخدم نفس وحدات التقارير المشتركة (`report_pdf_page.dart` + `report_pdf_arabic.dart`)
/// فيطابق المطبوع بقية كشوف التطبيق ويبقى تنسيقه موحّداً.
/// It reuses the shared report modules so the printout matches the app's other statements.
///
/// كتلة الدفع تُطبع فقط إذا وصلت من الخادم؛ وبلا صلاحية `tailoring.payments_view` تكون
/// `payment` فارغة فيُطبع الملف بلا أي رقم مالي — الحجب لا يُلتف عليه بالطباعة.
/// The payment block prints only when the server sent it; without `tailoring.payments_view`
/// `payment` is null and no figure is printed — printing is not a way around the block.
Future<Uint8List> buildCuttingBillPdf({
  required ReportLetterheadInfo letterhead,
  required CuttingBillDetail detail,
  String? currency,
  String? printedBy,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final title = 'فاتورة تفصيل رقم ${detail.header.referenceLabel}';

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح — فاتورة بموديلات وأقمشة كثيرة تتجاوز السقف الافتراضي
      // Explicit page ceiling — a bill with many models/fabrics beats the default.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: title,
        logo: logo,
        metaSection: _metaSection(detail, printedBy),
      ),
      footer: (context) => buildReportPdfFooter(
        context,
        currency: currency,
      ),
      build: (context) => [
        _invoiceAndCustomerBlock(detail),
        if (detail.payment != null) ...[
          pw.SizedBox(height: 8),
          _paymentBlock(detail.payment!),
        ],
        pw.SizedBox(height: 10),
        _modelsTable(detail),
        pw.SizedBox(height: 10),
        _fabricsTable(detail),
        pw.SizedBox(height: 12),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف البيانات العلوي: العميل والهاتف والحالة وتاريخ الطباعة
/// The top meta row: customer, phone, stage and print time.
pw.Widget _metaSection(CuttingBillDetail detail, String? printedBy) {
  final header = detail.header;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              pdfArabic(
                tailoringJoin([
                  'العميل: ${header.custName.isEmpty ? '—' : header.custName}',
                  if (header.telNo1 != null) 'هاتف: ${header.telNo1}',
                  'التاريخ: ${header.date ?? '—'}',
                ], separator: '   |   '),
              ),
              style: const pw.TextStyle(fontSize: 9),
              textDirection: kPdfShapedTextDirection,
            ),
          ),
          pw.Text(
            pdfArabic(
              tailoringJoin([
                header.ordsName ?? (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
                if (printedBy != null) 'طُبعت بواسطة: $printedBy',
              ], separator: '   |   '),
            ),
            style: const pw.TextStyle(fontSize: 9),
            textDirection: kPdfShapedTextDirection,
          ),
        ],
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        pdfArabic(
          'الرقم اليدوي: ${header.manualLabel}   |   الموديلات: ${header.modelsCount}'
          '   |   القطع: ${header.piecesCount}',
        ),
        style: const pw.TextStyle(
          fontSize: 8,
          color: ReportPdfColors.subtleText,
        ),
        textDirection: kPdfShapedTextDirection,
      ),
    ],
  );
}

// ─── كتلة الفاتورة/العميل ──────────────────────────────────────────────────────
pw.Widget _invoiceAndCustomerBlock(CuttingBillDetail detail) {
  final header = detail.header;

  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ReportPdfColors.border, width: 0.5),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _kvRow('رقم الفاتورة', header.referenceLabel, 'التاريخ', header.date ?? '—'),
        _kvRow('الرقم اليدوي', header.manualLabel,'—','—'),
        _kvRow(
          'العميل',
          header.custName.isEmpty ? '—' : header.custName,
          'رقم العميل',
          header.custNo?.toString() ?? '—',
        ),
        _kvRow('الهاتف', header.telNo1 ?? '—', 'رقم الحساب', header.accNo?.toString() ?? '—'),      
        _kvRow('مرجع الفاتورة', header.refNo ?? '—', 'الاستحقاق', header.givingDate ?? '—'),
        _kvRow(
          'تاريخ التسليم',
          header.handingDate ?? '—',
          'مستعجل',
          header.urgent ? 'نعم' : 'لا',
        ),
        if (header.details != null)
          _kvRow('البيان', header.details!, '', ''),
      ],
    ),
  );
}

/// سطر تسمية/قيمة مزدوج داخل الكتلة
/// A doubled label/value row inside the block.
pw.Widget _kvRow(String label1, String value1, String label2, String value2) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: _kv(label1, value1),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 3,
          child: label2.isEmpty ? pw.SizedBox() : _kv(label2, value2),
        ),
      ],
    ),
  );
}

/// خلية تسمية/قيمة واحدة — التسمية بخط صغير والقيمة أعرض
/// One label/value cell — small label, bolder value.
pw.Widget _kv(String label, String value) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        pdfArabic('$label: '),
        style: const pw.TextStyle(
          fontSize: 7.5,
          color: ReportPdfColors.subtleText,
        ),
        textDirection: kPdfShapedTextDirection,
      ),
      pw.Expanded(
        child: pw.Text(
          pdfArabic(value),
          style: const pw.TextStyle(fontSize: 8),
          textDirection: kPdfShapedTextDirection,
        ),
      ),
    ],
  );
}

// ─── كتلة الدفع ─────────────────────────────────────────────────────────────────
pw.Widget _paymentBlock(CuttingBillPayment payment) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ReportPdfColors.border, width: 0.5),
      borderRadius: pw.BorderRadius.circular(3),
      color: ReportPdfColors.rowStripe,
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          pdfArabic('تفاصيل الدفع'),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(child: _money('الإجمالي', payment.total)),
            pw.Expanded(child: _money('الخصم', payment.discount)),
            pw.Expanded(child: _money('الصافي', payment.net)),
            pw.Expanded(child: _money('المدفوع', payment.paidTotal)),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Expanded(
              child: _money(
                payment.balanceLabel,
                payment.remaining == null ? null : (payment.remaining!).abs(),
                highlight: true,
              ),
            ),
            pw.Expanded(
              child: _kv('الاستحقاق', payment.givingDate ?? '—'),
            ),
            pw.Expanded(
              child: _kv(
                'السند',
                payment.settlementLabel.isEmpty ? '—' : payment.settlementLabel,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _money(String label, double? value, {bool highlight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          pdfArabic(label),
          style: const pw.TextStyle(
            fontSize: 7,
            color: ReportPdfColors.subtleText,
          ),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic(value == null ? '—' : tailoringNumber(value)),
          style: pw.TextStyle(
            fontSize: highlight ? 9 : 8.5,
            fontWeight: pw.FontWeight.bold,
            color: highlight ? ReportPdfColors.accentBlue : PdfColors.black,
          ),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
    ),
  );
}

// ─── جدول الموديلات ─────────────────────────────────────────────────────────────
/// أعمدة معكوسة كي يظهر «رقم الموديل» في أقصى اليمين مطابقاً للشاشة
/// Columns are reversed so the model number sits at the right edge, matching the screen.
pw.Widget _modelsTable(CuttingBillDetail detail) {
  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4),
      1: pw.FlexColumnWidth(1.4),
      2: pw.FlexColumnWidth(0.7),
      3: pw.FlexColumnWidth(0.9),
      4: pw.FlexColumnWidth(1.2),
      5: pw.FlexColumnWidth(4.4),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
        children: reversedCells([
          pdfTh('م'),
          pdfTh('المستفيد'),
          pdfTh('العدد'),
          pdfTh('المرحلة'),
          pdfTh('النوع/الشكل'),
          pdfTh('المقاسات والمواصفات'),
        ]),
      ),
      ...detail.models.map(
        (model) => pw.TableRow(
          children: reversedCells([
            pdfTd('${model.seqNo}'),
            pdfTd(model.beneficiary ?? '—'),
            pdfTd('${model.qty}'),
            pdfTd(model.stage.label),
            pdfTd(tailoringJoin([model.typeName, model.shapeName], separator: ' / ')),
            pdfTd(
              _modelSummary(model, detail.measureLabels),
              align: pw.TextAlign.right,
              fontSize: 7,
            ),
          ]),
        ),
      ),
    ],
  );
}

/// سطر المقاسات والمواصفات مجمّعاً لموديل واحد
/// The measurements and specs of one model, folded into one cell.
///
/// الجدول لا يحتمل 12 عموداً للمقاسات مع أعمدة المواصفات، فتُدمج في خلية نصية واحدة
/// بالتسميات الحقيقية — نفس ما تعرضه الشاشة بالضبط.
/// The table cannot hold 12 measurement columns beside the spec columns, so they are folded
/// into one text cell using the real labels — exactly what the screen shows.
String _modelSummary(CuttingModelItem model, Map<String, String> labels) {
  final measures = <String>[];

  for (var i = 1; i <= 12; i++) {
    final key = 'L$i';
    final value = model.measurements[key];
    if (value == null) continue;
    final label = labels[key] ?? key;
    measures.add('$label ${tailoringNumber(value)}');
  }

  final specs = model.specs.textChips
      .map((chip) => '${chip.$1}: ${chip.$2}')
      .toList();

  return tailoringJoin([
    measures.isEmpty ? null : 'مقاسات: ${measures.join(' · ')}',
    specs.isEmpty ? null : 'مواصفات: ${specs.join(' · ')}',
    model.specs.notes == null ? null : 'ملاحظة: ${model.specs.notes}',
  ], separator: '\n');
}

// ─── جدول الأقمشة ──────────────────────────────────────────────────────────────
/// جدول الأقمشة: صف لكل قطعة مع رقم موديلها لأن الفاتورة تحمل أكثر من موديل
/// The fabrics table: one row per piece with its model number, since a bill has several models.
pw.Widget _fabricsTable(CuttingBillDetail detail) {
  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
      children: reversedCells([
        pdfTh('القطعة'),
        pdfTh('الموديل'),
        pdfTh('القماش'),
        pdfTh('النوع'),
        pdfTh('اللون'),
        pdfTh('هنش'),
        pdfTh('يارد'),
        pdfTh('القصّاص'),
        pdfTh('الخيّاط'),
        pdfTh('المرحلة'),
      ]),
    ),
  ];

  for (final model in detail.models) {
    for (final piece in model.pieces) {
      rows.add(
        pw.TableRow(
          children: reversedCells([
            pdfTd('${piece.seqNo1}'),
            pdfTd('${model.seqNo}'),
            pdfTd(piece.clothName ?? '—'),
            pdfTd(piece.clothType ?? '—'),
            pdfTd(piece.colorText ?? '—'),
            pdfTd(tailoringNumber(piece.hinsh)),
            pdfTd(tailoringNumber(piece.yards)),
            pdfTd(piece.cutterName ?? '—'),
            // «غير مسند» بدل «لا يوجد» الحرفية القادمة من النظام القديم
            // "غير مسند" instead of the legacy literal "لا يوجد".
            pdfTd(piece.hasTailor ? piece.tailorName! : 'غير مسند'),
            pdfTd(piece.stage.label),
          ]),
        ),
      );
    }
  }

  if (rows.length == 1) {
    return pw.Text(
      pdfArabic('لا توجد قطع مسجّلة على هذه الفاتورة'),
      style: const pw.TextStyle(fontSize: 8, color: ReportPdfColors.subtleText),
      textDirection: kPdfShapedTextDirection,
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(0.9),
      1: pw.FlexColumnWidth(0.9),
      2: pw.FlexColumnWidth(2.6),
      3: pw.FlexColumnWidth(1.6),
      4: pw.FlexColumnWidth(1.4),
      5: pw.FlexColumnWidth(0.9),
      6: pw.FlexColumnWidth(0.9),
      7: pw.FlexColumnWidth(1.6),
      8: pw.FlexColumnWidth(1.6),
      9: pw.FlexColumnWidth(1.4),
    },
    children: rows,
  );
}
