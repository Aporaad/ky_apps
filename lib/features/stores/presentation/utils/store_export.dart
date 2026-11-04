import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/utils/report_pdf_arabic.dart';
import '../../../../core/utils/report_pdf_fonts.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../data/models/order_model.dart';
import '../../data/models/report_model.dart';
import '../widgets/store_ui.dart';
import 'store_document_layout.dart';

/// مصدّر قسم المخازن: PDF للطباعة والمشاركة، وXLSX للمشاركة
/// The stores exporter: PDF for print/share and XLSX for share.
///
/// ── الطباعة والتصدير كلاهما يقرأ الترويسة من إعدادات التطبيق (`ReportLetterheadInfo`) حتى
///    يخرج المستند بهوية الشركة نفسها التي تظهر في كشوف الحسابات.
/// ── Both printing and export read the letterhead from app config so the output carries the
///    same company identity the statement reports use.
class StoreExporter {
  StoreExporter._();

  /// طباعة PDF مباشرة
  /// Print a PDF directly.
  static Future<void> print({
    required Uint8List bytes,
    required String fileName,
  }) {
    return Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
  }

  /// مشاركة PDF
  /// Share a PDF.
  static Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  /// مشاركة XLSX — الحزمة تبني البايتات فقط، فتُكتب إلى مساحة التطبيق ثم تُشارك
  /// Share an XLSX: the package only builds bytes, so the file is written to the app
  /// documents directory and then shared.
  static Future<void> shareXlsx({
    required List<int> bytes,
    required String fileName,
    required String subject,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }

  /// اسم ملف آمن من التاريخ
  /// A file-name-safe date stamp.
  static String stamp() {
    final now = DateTime.now();

    return '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}

/// مولّد PDF لمستند مخزني — نسخة طبق الأصل من قالب «استعراض التوريد»
/// The stock-document PDF — a faithful replica of the receive-invoice template.
///
/// ── القالب المطلوب حرفياً: عنوان المستند، خانات الرأس (رقم الفاتورة · نوعها · التاريخ ·
///    المورد/المخزن · الحسابات · العملة)، جدول السطور بكل أعمدة النظام (المقاسات والتصنيف
///    واللون والرف والعبوة والقطعة)، ثم شريط المجاميع (الإجمالي · نسبة الخصم · مبلغ الخصم ·
///    صافي المبلغ) مع المبلغ بالحروف، ثم التوقيعات — وكل ذلك فوق ترويسة التطبيق الموحّدة
///    وتذييله بترقيم الصفحات.
/// ── The requested template, literally: the document title, the header boxes, the full ERP line
///    grid (sizes, classification, colour, shelf, pack, pieces), the totals strip with the amount
///    in words, then signatures — all on the app's unified letterhead and paged footer.
Future<Uint8List> buildStoreOrderPdf({
  required ReportLetterheadInfo letterhead,
  required StoreOrderKind kind,
  required StoreOrderModel header,
  required List<StoreOrderLineModel> lines,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final columns = storeDocumentColumns(kind);
  final title = StoreDocProfile.of(kind).title;

  doc.addPage(
    pw.MultiPage(
      // ── طولية A4: الورقة تُطبع على A4 طولية كما يطلب المستخدم؛ الأفقي كان يُصغّر
      //    المستند عند الطباعة على ورق طولي.
      // ── Portrait A4: the sheet prints on portrait A4 as requested; landscape shrank the
      //    document when printed on portrait paper.
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
      textDirection: pw.TextDirection.rtl,
      // ── الترويسة الكاملة صارت **محتوى** الصفحة الأولى، لا ترويسة متكررة في كل صفحة.
      //    السبب مقاس: `header` يُقتطع من مساحة الصفحة قبل وضع المحتوى، و`pw.Column` في
      //    الـ`pdf` يتمدد افتراضياً إلى أقصى ارتفاع متاح — فكانت الترويسة تبتلع الصفحة الأولى،
      //    ينتهي الجدول في منتصف الورقة وتُدفع بقية السطور إلى صفحة ثالثة. المتكرر الآن سطر رقيق.
      // ── The full letterhead is now **content** of page one, not a repeated header. The reason
      //    is measurable: `header` is subtracted from the page before content is placed, and a
      //    `pw.Column` in `pdf` expands to the maximum available height by default — so the
      //    header swallowed page one, the table ended mid-sheet and the remaining rows were
      //    pushed onto a third page. Only a thin title line repeats now.
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox.shrink()
          : pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  pdfArabic('$title رقم ${header.reference}'),
                  style: const pw.TextStyle(fontSize: 10),
                  textDirection: kPdfShapedTextDirection,
                ),
                pw.Divider(thickness: 0.6, color: ReportPdfColors.border),
              ],
            ),
      footer: (context) => buildReportPdfFooter(
        context,
        currency: header.curName == null ? null : 'العملة: ${header.curName}',
      ),
      build: (context) => [
        // الصفحة الأولى: الترويسة الرسمية ثم شريط التفاصيل، ثم الجدول مباشرةً
        // Page one: the official letterhead then the detail strip, then the table at once.
        buildReportPdfHeader(
          letterhead: letterhead,
          title: '$title — رقم ${header.reference}',
          logo: logo,
          metaSection: _orderMeta(kind, header),
        ),
        // الجدول يُمرَّر كاملاً: `MultiPage` يقسمه ويُملئ كل صفحة قبل الانتقال للتالية
        // The whole table is handed over: MultiPage splits it and fills each page before
        // moving on, leaving no gap at the bottom of the sheet.
        _orderTable(columns, lines),
        pw.SizedBox(height: 10),
        _orderTotals(kind, header),
        pw.SizedBox(height: 14),
        _signatures(kind),
      ],
    ),
  );

  return doc.save();
}

/// شريط تفاصيل المستند في المطبوع — صف واحد ومن نفس مصدر الشاشة
/// The document meta strip in the printout — one row, from the same source as the screen.
///
/// ── جدول لا `Row`: الـ`Row` مع `stretch` يحتاج ارتفاعاً معلوماً، وترويسة `MultiPage` بلا
///    ارتفاع محدود، فينهار التوليد بـ«height (Infinity) exceed a page height». الجدول يحسب
///    ارتفاع الصف من أطول خلية فيعطي نفس شكل الشاشة بلا هذا الخطر.
/// ── A table, not a `Row`: a stretched Row needs a known height, and a `MultiPage` header has
///    none, so generation dies with "height (Infinity) exceed a page height". A table derives
///    the row height from its tallest cell and reproduces the on-screen strip safely.
pw.Widget _orderMeta(StoreOrderKind kind, StoreOrderModel header) {
  final cells = storeDocumentMeta(kind, header);

  return pw.Table(
    // ── الجدول يرسم من اليسار دائماً، فتُعكس الخانات كي يقع «تاريخ الفاتورة» في أقصى اليمين
    // ── A table always lays children left-to-right, so the cells are reversed to put the
    //    invoice date at the far right.
    children: [
      pw.TableRow(
        children: [
          for (final cell in cells.reversed)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: ReportPdfColors.border,
                  width: 0.35,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    pdfArabic(cell.$1),
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: ReportPdfColors.subtleText,
                    ),
                    textDirection: kPdfShapedTextDirection,
                  ),
                  pw.Text(
                    pdfArabic(cell.$2),
                    style: const pw.TextStyle(fontSize: 8.5),
                    textDirection: kPdfShapedTextDirection,
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

/// جدول سطور المستند — الأعمدة من مصدر التخطيط المشترك، ومعكوسة لأن `pw.Table` يرسم LTR
/// The lines table — columns come from the shared layout and are reversed because pw.Table
/// always lays children out left-to-right inside an RTL page.
pw.Widget _orderTable(
  List<StoreDocColumn> columns,
  List<StoreOrderLineModel> lines,
) {
  // الأعمدة تُعكس لأن `pw.Table` يرسم دائماً يسار←يمين
  // The columns are reversed because `pw.Table` always draws left→right.
  final ordered = columns.reversed.toList();

  return pw.TableHelper.fromTextArray(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    headerDecoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
    headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 7),
    // ── الاتجاه صريح ltr في الخلايا والعناوين: النص يصل مُشكَّلاً ومرتّباً مرئياً من
    //    `pdfArabic`، فلو ورث اتجاه الصفحة rtl لأعاد المحرك ترتيبه بعكس ثانٍ فتظهر الحروف
    //    معكوسة («ﻢﺋﺎﻘﻟﺍ» بدل «القائم»). ولذلك تُثبّت المحاذاة يميناً يدوياً لأن ltr
    //    يُحوّل `topLeft` إلى محاذاة يسار.
    // ── Explicit ltr in cells and headers: `pdfArabic` hands over already-shaped text in
    //    visual order; inheriting the page's rtl would make the engine reverse it a second
    //    time and every word appears mirrored. Alignment is pinned right manually because ltr
    //    would turn `topLeft` into a left alignment.
    headerDirection: kPdfShapedTextDirection,
    tableDirection: kPdfShapedTextDirection,
    cellAlignment: pw.Alignment.topRight,
    // ── الحد الأدنى لارتفاع الخلية: صف رقيق كما في الطبعة، لا صف يتضخم بحشوة افتراضية.
    // ── A small minimum cell height: a thin row as the printout has, not one inflated by
    //    default padding.
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
    headerPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    // ── توزيع العرض بنسب المستند: بدونها يعطي `fromTextArray` كل عمود عرضاً متساوياً،
    //    فتتسطر أسماء الأصناف على أربعة أسطر ويصير الصف ~50 نقطة، فلا تسع الصفحة إلا
    //    خمسة سطور ويُدفع الباقي إلى صفحات أخرى مع فراغ أسفل الورقة.
    // ── Widths follow the document weights. Without them `fromTextArray` gives every column
    //    an equal width, so item names wrap onto four lines and a row becomes ~50pt; the page
    //    then holds five rows and the rest is pushed to another page with a blank gap.
    columnWidths: {
      for (var i = 0; i < ordered.length; i++)
        i: pw.FlexColumnWidth(ordered[i].weight),
    },
    headers: ordered.map((column) => pdfArabic(column.title)).toList(),
    data: [
      for (final line in lines)
        ordered.map((column) => pdfArabic(column.value(line))).toList(),
    ],
  );
}

/// شريط المجاميع + المبلغ بالحروف — ذيل القالب، والخصم حيث يوجد فقط
/// The totals strip plus the amount in words — the template's footer, with the discount only
/// where the kind actually has one.
pw.Widget _orderTotals(StoreOrderKind kind, StoreOrderModel header) {
  final figures = <(String, String, bool)>[
    ('الإجمالي', StoreFormat.money(header.total), false),
    ('مبلغ الخصم', storeDiscountText(header), false),
    ('صافي المبلغ', StoreFormat.money(header.net), true),
  ];

  return pw.Table(
    // ── الجدول لا `Row` لنفس السبب: الارتفاع يُحسب من أطول خلية ولا يحتاج `stretch`
    // ── A table, not a Row, for the same reason: height comes from the tallest cell.
    columnWidths: const {
      0: pw.FlexColumnWidth(5),
      1: pw.FlexColumnWidth(6),
    },
    children: [
      pw.TableRow(
        children: [
          // اليسار: الإجمالي · الخصم · الصافي — نفس ترتيب الشاشة
          // Left: total · discount · net — the same order as the screen.
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              for (var index = 0; index < figures.length; index++) ...[
                if (index > 0) pw.SizedBox(height: 4),
                _orderFigureBox(
                  figures[index].$1,
                  figures[index].$2,
                  figures[index].$3,
                ),
              ],
            ],
          ),
          // اليمين: المبلغ كتابةً ثم البيان
          // Right: the amount in words, then the description.
          _orderWords(header),
        ],
      ),
    ],
  );
}

/// المبلغ كتابةً والبيان في عمود واحد — أطول حقلين، فلهما العمود الأوسع
/// The amount in words and the description in one column — the two longest fields.
pw.Widget _orderWords(StoreOrderModel header) {
  final note = header.detailes;

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ReportPdfColors.border, width: 0.4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          pdfArabic('المبلغ كتابةً'),
          style: const pw.TextStyle(fontSize: 7, color: ReportPdfColors.subtleText),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          pdfArabic(
            StoreFormat.amountInWords(header.net, currencyName: header.curName),
          ),
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          textDirection: kPdfShapedTextDirection,
        ),
        if (note != null && note.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            pdfArabic('البيان'),
            style: const pw.TextStyle(
              fontSize: 7,
              color: ReportPdfColors.subtleText,
            ),
            textDirection: kPdfShapedTextDirection,
          ),
          pw.Text(
            pdfArabic(note),
            style: const pw.TextStyle(fontSize: 8),
            textDirection: kPdfShapedTextDirection,
          ),
        ],
      ],
    ),
  );
}

/// خانة رقم مالي في المطبوع — الاسم ثم القيمة
/// A money box in the printout — label then figure.
pw.Widget _orderFigureBox(String label, String value, bool emphasise) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: ReportPdfColors.border, width: 0.4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          pdfArabic(label),
          style: const pw.TextStyle(fontSize: 7, color: ReportPdfColors.subtleText),
          textDirection: kPdfShapedTextDirection,
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: emphasise ? 9.5 : 8.5,
            fontWeight: emphasise ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
          textDirection: pw.TextDirection.ltr,
        ),
      ],
    ),
  );
}

/// توقيعات المستند المخزني
/// The stock document signatures.
pw.Widget _signatures(StoreOrderKind kind) {
  final labels = kind.hasParty
      ? ['أمين المخزن', 'المراجع', kind == StoreOrderKind.receive ? 'المورد' : 'المستلم']
      : ['أمين المخزن المُرسل', 'أمين المخزن المستلم', 'المراجع'];

  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      for (final label in labels)
        pw.Column(
          children: [
            pw.Text(
              pdfArabic(label),
              style: const pw.TextStyle(fontSize: 9),
              textDirection: kPdfShapedTextDirection,
            ),
            pw.SizedBox(height: 22),
            pw.Container(
              width: 100,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: ReportPdfColors.border, width: 0.6),
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

/// مولّد PDF لتقارير المخازن (حركة · خلاصة)
/// The PDF builder of the stores reports (movement · summary).
Future<Uint8List> buildStoreReportPdf({
  required ReportLetterheadInfo letterhead,
  required StoreReportFilter filter,
  required List<StockMovementRow> movementRows,
  required List<StockSummaryRow> summaryRows,
  required double totalIn,
  required double totalOut,
  required double totalValue,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final isMovement = filter.kind == StoreReportKind.movement;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'تقرير المخازن — ${filter.kind.label}',
        logo: logo,
        metaSection: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              pdfArabic('من ${filter.fromText} إلى ${filter.toText}'),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              pdfArabic(
                'المخازن: ${filter.storeNos.isEmpty ? 'الكل' : filter.storeNos.join('، ')}',
              ),
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ],
        ),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        if (isMovement) _movementTable(movementRows) else _summaryTable(summaryRows),
        pw.SizedBox(height: 8),
        pw.Text(
          pdfArabic(
            'وارد ${StoreFormat.qty(totalIn)} · '
            'صادر ${StoreFormat.qty(totalOut)} · '
            'القيمة ${StoreFormat.money(totalValue)}',
          ),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  return doc.save();
}

/// مولّد PDF لقائمة أوامر مُحدَّدة (الإجراء الجماعي: طباعة المحدد)
/// The PDF builder of a set of selected orders (bulk print).
///
/// ── لماذا مولّد مستقل ولا يُعاد استخدام مستند واحد؟ لأن الإجراء الجماعي يطبع **رؤوساً**
///    لا سطوراً: قائمة تُراجع سريعاً (الرقم/التاريخ/المخزن/الطرف/العدد/الصافي). طباعة كل مستند
///    بسطوره في ملف واحد تُنتج عشرات الصفحات التي لا تُراجع.
/// ── Why a separate builder instead of reusing the single-document one? A bulk action prints
///    *headers*, not lines: a list you can scan (reference/date/store/party/lines/net). Printing
///    each document with its lines would produce dozens of pages nobody reviews.
Future<Uint8List> buildStoreOrderListPdf({
  required ReportLetterheadInfo letterhead,
  required StoreOrderKind kind,
  required List<StoreOrderModel> orders,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final totalNet = orders.fold<double>(0, (sum, order) => sum + order.net);
  final totalLines = orders.fold<int>(0, (sum, order) => sum + order.lines);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: '${kind.title} — ${orders.length} مستند',
        logo: logo,
        metaSection: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              pdfArabic('الصافي الكلي: ${StoreFormat.money(totalNet)}'),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              pdfArabic('إجمالي السطور: $totalLines'),
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ],
        ),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(
            color: ReportPdfColors.border,
            width: 0.4,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: ReportPdfColors.headerBg,
          ),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          // ── اتجاه صريح: النص مُشكَّل مسبقاً بـ`pdfArabic`، ووراثة rtl تعكسه ثانية
          // ── Explicit direction: the text is pre-shaped by `pdfArabic`; inheriting rtl re-reverses it.
          headerDirection: kPdfShapedTextDirection,
          tableDirection: kPdfShapedTextDirection,
          cellAlignment: pw.Alignment.topRight,
          headers: [
            'المستند',
            'التاريخ',
            'المخزن',
            kind.hasParty ? 'الطرف' : 'إلى مخزن',
            'السطور',
            'الإجمالي',
            'الخصم',
            'الصافي',
          ]
              .reversed
              .map((header) => pdfArabic(header))
              .toList(growable: false),
          data: [
            for (final order in orders)
              [
                order.reference,
                order.dateLabel,
                order.storeName ?? '${order.storeNo}',
                order.partyLabel(kind),
                '${order.lines}',
                StoreFormat.money(order.total),
                StoreFormat.money(order.discount),
                StoreFormat.money(order.net),
              ].reversed.map((cell) => pdfArabic(cell)).toList(growable: false),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          pdfArabic(
            'عدد المستندات ${orders.length} · '
            'إجمالي السطور $totalLines · '
            'الصافي ${StoreFormat.money(totalNet)}',
          ),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _movementTable(List<StockMovementRow> rows) {
  final headers = [
    'التاريخ',
    'المستند',
    'نوع الحركة',
    'المخزن',
    'الكود',
    'الصنف',
    'الوحدة',
    'وارد',
    'صادر',
    'القيمة',
  ];

  return pw.TableHelper.fromTextArray(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    headerDecoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
    headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 7.5),
    headerDirection: kPdfShapedTextDirection,
    tableDirection: kPdfShapedTextDirection,
    cellAlignment: pw.Alignment.topRight,
    headers: headers.reversed
        .map((header) => pdfArabic(header))
        .toList(growable: false),
    data: [
      for (final row in rows)
        [
          StoreFormat.money(row.lineValue),
          row.qtyOut == 0 ? '—' : StoreFormat.qty(row.qtyOut),
          row.qtyIn == 0 ? '—' : StoreFormat.qty(row.qtyIn),
          pdfArabic(row.uomCode ?? '—'),
          pdfArabic(row.itemName ?? '—'),
          row.partNo ?? '—',
          pdfArabic(row.storeName ?? '—'),
          pdfArabic(row.typeName ?? '—'),
          row.docNo?.toString() ?? '—',
          row.dateLabel,
        ],
    ],
  );
}

pw.Widget _summaryTable(List<StockSummaryRow> rows) {
  final headers = [
    'الكود',
    'الصنف',
    'الوحدة',
    'المخزن',
    'وارد',
    'صادر',
    'الصافي',
    'القيمة',
  ];

  return pw.TableHelper.fromTextArray(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
    headerDecoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
    headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 8),
    headerDirection: kPdfShapedTextDirection,
    tableDirection: kPdfShapedTextDirection,
    cellAlignment: pw.Alignment.topRight,
    headers: headers.reversed
        .map((header) => pdfArabic(header))
        .toList(growable: false),
    data: [
      for (final row in rows)
        [
          StoreFormat.money(row.netValue),
          StoreFormat.qty(row.netQty),
          StoreFormat.qty(row.qtyOut),
          StoreFormat.qty(row.qtyIn),
          pdfArabic(row.storeName ?? '—'),
          pdfArabic(row.uomCode ?? '—'),
          pdfArabic(row.itemName ?? '—'),
          row.partNo ?? '—',
        ],
    ],
  );
}

/// مولّد PDF لكشف الجرد — بلا أي ترحيل، توقيعان فقط
/// The stocktake sheet PDF — nothing is posted, two signatures only.
Future<Uint8List> buildStockSheetPdf({
  required ReportLetterheadInfo letterhead,
  required List<StockSheetRow> rows,
  required Map<String, double> counted,
  required DateTime? date,
  required String storesLabel,
  Map<String, String> notes = const {},
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);

  double countedOf(StockSheetRow row) => counted[row.key] ?? row.systemQty;
  double varianceOf(StockSheetRow row) => countedOf(row) - row.systemQty;

  // عمود الملاحظة يظهر فقط إن كتب أحدهم ملاحظة، وإلا فهو عرض مهدور في كشف مطبوع
  // The notes column appears only when someone wrote a note; otherwise it is wasted width.
  final hasNotes = notes.values.any((note) => note.trim().isNotEmpty);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'كشف جرد مخزني (استرشادي)',
        logo: logo,
        metaSection: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              pdfArabic('تاريخ العدّ: ${StoreFormat.date(date)} · المخازن: $storesLabel'),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              pdfArabic('كشف للمعاينة والطباعة فقط — لا يُرحَّل ولا يغيّر الأرصدة'),
              style: pw.TextStyle(
                fontSize: 9,
                color: ReportPdfColors.dangerRed,
              ),
            ),
          ],
        ),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.4),
          headerDecoration: const pw.BoxDecoration(
            color: ReportPdfColors.headerBg,
          ),
          headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDirection: kPdfShapedTextDirection,
          tableDirection: kPdfShapedTextDirection,
          cellAlignment: pw.Alignment.topRight,
          headers: [
            if (hasNotes) 'ملاحظة السطر',
            'الفرق',
            'قيمة الفرق',
            'الفعلي',
            'رصيد النظام',
            'الوحدة',
            'الصنف',
            'الكود',
            'المخزن',
          ].reversed.map((header) => pdfArabic(header)).toList(growable: false),
          data: [
            for (final row in rows)
              [
                if (hasNotes) pdfArabic(notes[row.key] ?? '—'),
                StoreFormat.money(varianceOf(row) * row.cost),
                StoreFormat.qty(varianceOf(row)),
                StoreFormat.qty(countedOf(row)),
                StoreFormat.qty(row.systemQty),
                pdfArabic(row.uomCode ?? '—'),
                pdfArabic(row.itemName ?? '—'),
                row.partNo ?? '—',
                pdfArabic(row.storeName ?? '—'),
              ],
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            for (final label in ['أمين المخزن', 'المراجع', 'المدير'])
              pw.Column(
                children: [
                  pw.Text(pdfArabic(label), style: const pw.TextStyle(fontSize: 9)),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    width: 110,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(
                          color: ReportPdfColors.border,
                          width: 0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );

  return doc.save();
}

/// مولّد PDF لكشف حركة صنف (الصنف الرئيسي بكامل فروعه أو فرع واحد)
/// The PDF builder of an item movement statement (the main item with all branches, or one branch).
///
/// ── الأعمدة تشمل «الفرع» دائماً: كشف الصنف الرئيسي يجمع حركات كل فروعه، وبلا هذا العمود
///    يصبح السطر بلا هوية ويسأل المراجع «أي فرع تحرّك؟».
/// ── The branch column is always present: a main item's statement merges all its branches, and
///    without it a line has no identity, leaving the reviewer asking which branch moved.
Future<Uint8List> buildItemStatementPdf({
  required ReportLetterheadInfo letterhead,
  required String itemName,
  required String branchLabel,
  required String rangeText,
  required List<StockMovementRow> rows,
  required double qtyIn,
  required double qtyOut,
  required double netQty,
  required double totalValue,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(20),
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        title: 'كشف حركة صنف — $itemName',
        logo: logo,
        metaSection: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              pdfArabic('الفرع: $branchLabel'),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              pdfArabic(rangeText),
              style: const pw.TextStyle(fontSize: 9.5),
            ),
          ],
        ),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(
            color: ReportPdfColors.border,
            width: 0.4,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: ReportPdfColors.headerBg,
          ),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
          cellStyle: const pw.TextStyle(fontSize: 7.5),
          headers: [
            'التاريخ',
            'المستند',
            'نوع الحركة',
            'المخزن',
            'الفرع',
            'وارد',
            'صادر',
            'التكلفة',
            'القيمة',
          ]
              .reversed
              .map((header) => pdfArabic(header))
              .toList(growable: false),
          data: [
            for (final row in rows)
              [
                row.dateLabel,
                '${row.docNo ?? ''}',
                row.typeName ?? '—',
                row.storeName ?? '${row.storeNo}',
                row.subLabel,
                row.qtyIn == 0 ? '' : StoreFormat.qty(row.qtyIn),
                row.qtyOut == 0 ? '' : StoreFormat.qty(row.qtyOut),
                StoreFormat.money(row.cost),
                StoreFormat.money(row.lineValue),
              ].reversed.map((cell) => pdfArabic(cell)).toList(growable: false),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          pdfArabic(
            'الأسطر ${rows.length} · '
            'وارد ${StoreFormat.qty(qtyIn)} · '
            'صادر ${StoreFormat.qty(qtyOut)} · '
            'الصافي ${StoreFormat.qty(netQty)} · '
            'القيمة ${StoreFormat.money(totalValue)}',
          ),
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  return doc.save();
}

/// مولّد XLSX لتقارير المخازن والأرصدة
/// The XLSX builder of the stores reports and balances.
List<int> buildStoreRowsXlsx({
  required String sheetName,
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final excel = Excel.createExcel();
  final sheet = excel[sheetName];

  // الحزمة تعمل LTR، فنكتب الأعمدة بالترتيب المنطقي (الأول = أقصى اليسار).
  // The package is LTR, so columns are written in logical order (first = far left).
  sheet.appendRow(headers.map<CellValue?>(TextCellValue.new).toList());

  for (final row in rows) {
    sheet.appendRow(row.map<CellValue?>(TextCellValue.new).toList());
  }

  final bytes = excel.save();

  return bytes ?? <int>[];
}
