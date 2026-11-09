import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';
import '../../data/models/measurement_model_ref.dart';

/// يبني ملف PDF لمقاسات موديل واحد: الترويسة الموحّدة + بيانات العميل والمستفيد + جدول
/// المقاسات + المواصفات + جدول الأقمشة + تذييل التوقيعات.
/// Builds the one-model measurements PDF: the unified letterhead, the customer/beneficiary block,
/// the measurements table, the specs, the fabrics table and the signature footer.
///
/// يستخدم نفس وحدات التقارير المشتركة (`report_pdf_page.dart` + `report_pdf_arabic.dart`) فيطابق
/// المطبوع بقية كشوف التطبيق ويبقى تنسيقه موحّداً.
/// It reuses the shared report modules so the printout matches the app's other statements.
///
/// الملف يطبع السجل كاملاً لا ما هو ظاهر على الشاشة: مرشّحات الشاشة أداة قراءة (إخفاء قسم أو
/// تضييق الأقمشة)، وطباعة سجل ناقص بسبب فلتر منسي خطأ في الورق لا في العرض.
/// The file prints the whole record, not the visible screen: the on-screen filters are a reading
/// aid (hiding a section, narrowing the fabrics), and printing an incomplete record because a
/// filter was left on would put the mistake on paper rather than on screen.
///
/// المال الوحيد المطبوع سعرُ القطعة (`SANF_PRICE`) لأنه عمود طلبه المستخدم صراحة؛ أما
/// إجمالي الفاتورة وخصمها وصافيها ومدفوعها فلا تُطبع ولا تُرسل أصلاً: المطبوع مقاسات
/// ومواصفات وأقمشة، لا كشف حساب.
/// The only money printed is the piece price (SANF_PRICE), a column the user asked for by name.
/// The bill total, its discount, net and paid amounts are neither printed nor even sent: this is
/// a measurements sheet, not an account statement.
Future<Uint8List> buildCustomerMeasurementPdf({
  required ReportLetterheadInfo letterhead,
  required MeasurementSubject subject,
  String? currency,
  String? printedBy,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);

  final header = subject.detail.header;
  final model = subject.model;

  // رقم الموديل قد يغيب مع موديل فارغ (استجابة بلا صفوف)، فيُطبع العنوان بدونه بدل «موديل 0»
  // The model number can be absent on an empty response, so the title drops it rather than
  // printing "model 0".
  final seqNo = model?.seqNo ?? 0;
  final title =
      'مقاسات ${header.custName.isEmpty ? 'العميل' : header.custName}'
      '${seqNo == 0 ? '' : ' — موديل $seqNo'}';

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح — يحمي التقارير متعددة الموديلات من سقف الحزمة الافتراضي
      // Explicit page ceiling — protects multi-model reports from the package default.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: title,
        logo: logo,
        metaSection: _metaSection(subject, printedBy),
      ),
      footer: (context) => buildReportPdfFooter(context, currency: currency),
      build: (context) => [
        _subjectBlock(subject),
        if (model != null) ...[
          pw.SizedBox(height: 10),
          _sectionTitle('تفاصيل المقاسات', model.seqNo),
          _measurementsTable(model, subject.detail.measureLabels),
          pw.SizedBox(height: 10),
          _sectionTitle('مواصفات الموديل', model.seqNo),
          _specsBlock(model),
          pw.SizedBox(height: 10),
          _sectionTitle('الأقمشة الخاصة بالموديل', model.seqNo),
          _fabricsTable(model),
        ],
        pw.SizedBox(height: 12),
        pdfSignatures(),
      ],
    ),
  );

  return doc.save();
}

/// صف البيانات العلوي: العميل والهاتف والموديل والحالة ووقت الطباعة
/// The top meta row: customer, phone, model, stage and print time.
pw.Widget _metaSection(MeasurementSubject subject, String? printedBy) {
  final header = subject.detail.header;
  final model = subject.model;

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
                  'الموديل: ${model?.seqNo ?? '—'}',
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
                header.ordsName ??
                    (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
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
          'فاتورة ${header.referenceLabel}   |   '
          'الرقم اليدوي: ${header.manualLabel}   |   '
          'القطع: ${model?.piecesCount ?? header.piecesCount}',
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

/// ترويسة قسم داخل الملف — سطر واحد قبل جدولَه
/// An in-file section header: one line above its table.
pw.Widget _sectionTitle(String label, int seqNo) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      pdfArabic('$label — موديل $seqNo'),
      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
      textDirection: kPdfShapedTextDirection,
    ),
  );
}

/// كتلة العميل والمستفيد: من قيس له، ومن الفاتورة باسمه، وما الموديل
/// The customer/beneficiary block: who was measured, who owns the bill, and which model.
///
/// المطبوع يكرّر رأس الشاشة: العنوان والفرع ومجموعة الحساب وشكل الموديل ورقمه تُسقط هنا أيضاً،
/// فتسمية «المقاسات» لا تحتاج ما لا يقرؤه خيّاط.
/// The printout mirrors the screen: address, branch, account group, model shape and model number
/// are dropped there too — a measurements sheet never needs what no tailor reads.
pw.Widget _subjectBlock(MeasurementSubject subject) {
  final header = subject.detail.header;
  final model = subject.model;

  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ReportPdfColors.border, width: 0.5),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _kvRow(
          'العميل',
          header.custName.isEmpty ? '—' : header.custName,
          'رقم العميل',
          header.custNo?.toString() ?? '—',
        ),
        _kvRow(
          'الهاتف',
          header.telNo1 ?? header.telNo2 ?? '—',
          'رقم الحساب',
          header.accNo?.toString() ?? '—',
        ),
        _kvRow(
          'المستفيد',
          model?.beneficiary ?? 'بلا مستفيد محدّد',
          'نوع الموديل',
          model?.typeName ?? '—',
        ),
        _kvRow(
          'تاريخ الفاتورة',
          header.date ?? '—',
          'عدد القطع',
          '${model?.piecesCount ?? 0}',
        ),
        _kvRow(
          'فاتورة رقم',
          header.referenceLabel,
          'الرقم اليدوي',
          header.manualLabel,
        ),
        _kvRow(
          'الحالة',
          header.ordsName ??
              (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
          '',
          '',
        ),
      ],
    ),
  );
}

/// سطر تسمية/قيمة مزدوج داخل الكتلة / a doubled label/value row
pw.Widget _kvRow(String label1, String value1, String label2, String value2) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: _kv(label1, value1)),
        pw.SizedBox(width: 8),
        pw.Expanded(
          flex: 3,
          child: label2.isEmpty ? pw.SizedBox() : _kv(label2, value2),
        ),
      ],
    ),
  );
}

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

/// جدول المقاسات: أربعة مقاسات في الصف، فاثنا عشر خانة في ثلاثة أسطر
/// The measurements table: four measurements per row, so twelve slots fit in three lines.
///
/// تُطبع الخانات المعبّأة فقط؛ الفراغ في الورق لا يحمل معلومة ويزحم الصفحة. والتسميات من
/// `GENERAL_LABELS_CODING` عبر الخادم، فلا اسم مقاس يُخترع في الملف.
/// Only filled slots print: blank paper carries no information and crowds the page. Labels come
/// from GENERAL_LABELS_CODING through the server, so the file never invents a measurement name.
pw.Widget _measurementsTable(
  CuttingModelItem model,
  Map<String, String> labels,
) {
  final pairs = <(String, String)>[];

  for (var i = 1; i <= 12; i++) {
    final key = 'L$i';
    final value = model.measurements[key];
    if (value == null) continue;
    pairs.add((labels[key] ?? key, tailoringNumber(value)));
  }

  if (pairs.isEmpty) {
    return pw.Text(
      pdfArabic('لا توجد مقاسات مسجّلة لهذا الموديل'),
      style: const pw.TextStyle(
        fontSize: 8,
        color: ReportPdfColors.subtleText,
      ),
      textDirection: kPdfShapedTextDirection,
    );
  }

  final rows = <pw.TableRow>[];

  // أربعة أزواج في الصف: تسمية ثم قيمة، وكل صف مستقل حتى لو انتهى العدد عند غير أربعة
  // Four pairs per row — label then value — and the short last row stays intact.
  for (var start = 0; start < pairs.length; start += 4) {
    final slice = pairs.sublist(
      start,
      (start + 4).clamp(0, pairs.length),
    );
    final cells = <pw.Widget>[];

    for (final (label, value) in slice) {
      cells.add(pdfTh(label, fontSize: 7.5));
      cells.add(pdfTd(value, bold: true));
    }

    // إكمال الصف بأزواج فارغة: جدول بلا عمود ناقص لا ينزلق فيه رقم
    // Empty pairs pad the row: a missing column would let figures slide under wrong labels.
    for (var pad = slice.length; pad < 4; pad++) {
      cells.add(pdfTh('—', fontSize: 7.5));
      cells.add(pdfTd(''));
    }

    rows.add(pw.TableRow(children: reversedCells(cells)));
  }

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.6),
      1: pw.FlexColumnWidth(0.9),
      2: pw.FlexColumnWidth(1.6),
      3: pw.FlexColumnWidth(0.9),
      4: pw.FlexColumnWidth(1.6),
      5: pw.FlexColumnWidth(0.9),
      6: pw.FlexColumnWidth(1.6),
      7: pw.FlexColumnWidth(0.9),
    },
    children: rows,
  );
}

/// كتلة المواصفات: نصوص الموديل كما خزّنها النظام القديم + ملاحظته
/// The specs block: the model's texts as the legacy system stored them, plus its note.
pw.Widget _specsBlock(CuttingModelItem model) {
  final specs = model.specs;
  final chips = specs.textChips;

  if (chips.isEmpty && specs.notes == null) {
    return pw.Text(
      pdfArabic('لا توجد مواصفات مسجّلة لهذا الموديل'),
      style: const pw.TextStyle(
        fontSize: 8,
        color: ReportPdfColors.subtleText,
      ),
      textDirection: kPdfShapedTextDirection,
    );
  }

  final rows = <pw.Widget>[];

  for (var start = 0; start < chips.length; start += 3) {
    final slice = chips.sublist(start, (start + 3).clamp(0, chips.length));
    final cells = <pw.Widget>[];

    for (final (label, value) in slice) {
      cells.add(pdfTh(label, fontSize: 7.5));
      cells.add(pdfTd(value));
    }

    for (var pad = slice.length; pad < 3; pad++) {
      cells.add(pdfTh('—', fontSize: 7.5));
      cells.add(pdfTd(''));
    }

    rows.add(
      pw.Table(
        border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.4),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(1.4),
          3: pw.FlexColumnWidth(2.2),
          4: pw.FlexColumnWidth(1.4),
          5: pw.FlexColumnWidth(2.2),
        },
        children: [pw.TableRow(children: reversedCells(cells))],
      ),
    );

    if (start + 3 < chips.length) rows.add(pw.SizedBox(height: 3));
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      ...rows,
      if (specs.notes != null) ...[
        pw.SizedBox(height: 4),
        pw.Text(
          pdfArabic('ملاحظة: ${specs.notes}'),
          style: const pw.TextStyle(fontSize: 8),
          textDirection: kPdfShapedTextDirection,
        ),
      ],
    ],
  );
}

/// جدول الأقمشة: رقم الطلب · القماش · العرض · اللون · هنش · يارد · السعر · القصّاص · الخيّاط · المرحلة
/// The fabrics table: order id, cloth, width, colour, hinsh, yards, price, cutter, tailor, stage.
///
/// «العرض» هو `CLOTH_TYPE`: قيمته في القاعدة «عرضية/عادية» لا نوع قماش، وتسميته «النوع» كانت
/// تضلّل من يقرأ الورقة. الرف والمصدر حُذفا بطلب صريح.
/// "Width" is CLOTH_TYPE — its live values are عرضية/عادية, so calling that column "type" misled
/// the reader. Shelf and source were removed on request.
pw.Widget _fabricsTable(CuttingModelItem model) {
  if (model.pieces.isEmpty) {
    return pw.Text(
      pdfArabic('لا توجد قطع مسجّلة لهذا الموديل'),
      style: const pw.TextStyle(
        fontSize: 8,
        color: ReportPdfColors.subtleText,
      ),
      textDirection: kPdfShapedTextDirection,
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
      children: reversedCells([
        pdfTh('رقم الطلب'),
        pdfTh('القماش'),
        pdfTh('العرض'),
        pdfTh('اللون'),
        pdfTh('هنش'),
        pdfTh('ياردة'),
        pdfTh('السعر'),
        pdfTh('القصّاص'),
        pdfTh('الخيّاط'),
        pdfTh('المرحلة'),
      ]),
    ),
  ];

  for (final piece in model.pieces) {
    rows.add(
      pw.TableRow(
        children: reversedCells([
          pdfTd('${piece.ohdId ?? piece.seqNo1}', bold: true),
          pdfTd(piece.clothName ?? '—'),
          pdfTd(piece.clothType ?? '—'),
          pdfTd(piece.colorText ?? '—'),
          pdfTd(tailoringNumber(piece.hinsh)),
          pdfTd(tailoringNumber(piece.yards)),
          pdfTd(tailoringNumber(piece.price, decimals: 2)),
          pdfTd(piece.cutterName ?? '—'),
          // «غير مسند» بدل «لا يوجد» الحرفية القادمة من النظام القديم
          // "غير مسند" instead of the legacy literal "لا يوجد".
          pdfTd(piece.hasTailor ? piece.tailorName! : 'غير مسند'),
          pdfTd(piece.stage.label),
        ]),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.3),
      1: pw.FlexColumnWidth(2.4),
      2: pw.FlexColumnWidth(1.2),
      3: pw.FlexColumnWidth(1.2),
      4: pw.FlexColumnWidth(0.8),
      5: pw.FlexColumnWidth(0.9),
      6: pw.FlexColumnWidth(1.1),
      7: pw.FlexColumnWidth(1.5),
      8: pw.FlexColumnWidth(1.5),
      9: pw.FlexColumnWidth(1.3),
    },
    children: rows,
  );
}
