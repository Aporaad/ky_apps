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
import '../../../../core/utils/report_pdf_grid.dart';
import '../../../../core/utils/report_pdf_letterhead.dart';
import '../../../../core/utils/report_pdf_page.dart';
import '../../data/models/order_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';
import '../../data/repositories/store_result.dart';
import '../widgets/store_ui.dart';
import 'report_columns.dart';
import 'report_parameters.dart';
import 'report_totals.dart';
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

/// الورق طولي A4 كما في مستندات المخزن — لا أفقي
/// The sheet is portrait A4, like the stock documents — never landscape.
///
/// ── كانت صفحة التقرير أفقية (842×595) والطابعة/المعاينة ورقها طولي، فتُصغَّر
///    الصفحة إلى عرض الورقة ويصير ارتفاعها 420 نقطة من 842: نصف الورقة محتوى
///    ونصفها بياض، والبقية تُدفع إلى صفحة تالية — وهو عطل «التقرير في نص الصفحة».
///    حين يطابق مقاس الصفحة مقاس الورقة يمتلئ الورق من أوله إلى آخره.
/// ── The report page was landscape (842×595) while the printer/preview paper is portrait, so
///    the sheet was scaled down to the paper's width and became 420 pt of an 842 pt page:
///    half content, half blank, the rest pushed to another page. Matching the page size to
///    the paper is what fills the sheet.
const double _reportSideMargin = 16;

/// هامش صفحة التقرير: ضيّق على الجانبين لتأخذ الأعمدة نصيبها، وأعرض أعلاها للترويسة
/// The report page margin: narrow at the sides so columns get their share, taller on top
/// for the letterhead.
const pw.EdgeInsets _reportPageMargin = pw.EdgeInsets.fromLTRB(
  _reportSideMargin,
  20,
  _reportSideMargin,
  16,
);

/// العرض المتاح للمحتوى — منه تُحسب عروض الأعمدة، فلا تُقاس الخانات على عرضٍ
/// وتُطبع على عرضٍ غيره
/// The width left for content — column widths are computed from it, so nothing is measured
/// on one width and printed on another.
double get _reportContentWidth =>
    pdfGridContentWidth(PdfPageFormat.a4, sideMargin: _reportSideMargin);

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
      // سقف الصفحات الصريح — بدون الرجوع إلى سقف الحزمة الافتراضي
      // Explicit page ceiling — never fall back to the package default.
      maxPages: kReportPdfMaxPages,
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
///
/// ── الأعمدة تأتي من نفس قالب الشاشة: ما يحدّده المستخدم على الشاشة هو ما يُطبع، لا
///    جدول ثابت كُتب بيد مختلفة.
/// ── Columns come from the screen's own template: what the user shows on screen is what
///    prints, not a second hard-coded table.
Future<Uint8List> buildStoreReportPdf({
  required ReportLetterheadInfo letterhead,
  required StoreReportFilter filter,
  StoreReference? reference,
  required List<StockMovementRow> movementRows,
  required List<StockSummaryRow> summaryRows,
  /// إحصاء التقرير نفسه — نفس مصدر شريط الشاشة، فلا يلفظ الورق لفظاً غيره
  /// The report's own statistics — the screen strip's very source, so paper cannot word
  /// them differently.
  required ReportStats stats,
  List<String>? columnIds,
  List<String>? statIds,
  /// أقسام التقرير الموسّع بترتيبها — فارغة في التقرير المسطّح
  /// The scoped report's sections in order — empty for a flat report.
  ///
  /// ── المطبوع هو الشاشة: تصدير «حركة صنف رئيسي» جدولاً واحداً كان يُسقط التقسيم الذي هو
  ///    كل التقرير، فيخرج المستند مطابقاً لـ«حركة صنف فرعي» تماماً.
  /// ── The printout is the screen: exporting an item statement as one table dropped the
  ///    sectioning that *is* the report, and the document came out identical to a branch one.
  List<ReportSection<StockMovementRow>> sections = const [],
  /// رصيد الفترة السابقة في التقرير المسطّح — أول سطر في الجدول
  /// The pre-period balance of a flat report — the table's opening line.
  Map<String, String>? opening,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final isMovement = filter.kind == StoreReportKind.movement;
  final title = ReportTitles.of(filter, reference: reference);

  // العرض المتاح بعد هامشي الورقة: هو المقياس الذي تُحسب عليه كل الخانات
  // The width left after the margins — the measure every cell is computed on.
  final width = _reportContentWidth;

  /// هل يبقى حقل الإحصاء هذا في المطبوع؟ نفس معرّفات نافذة الأعمدة
  /// Whether this statistic survives into the printout — the columns sheet's own ids.
  bool on(String id) => statIds == null || statIds.contains(id);

  // عنوان الشريط كما على الشاشة تماماً: في التقرير الموسّع إجمالي كل الأقسام
  // The strip's caption exactly as the screen words it: in a sectioned report it totals
  // every section.
  final statsTitle = isMovement && sections.isNotEmpty
      ? 'إحصاءات التقرير — إجمالي كل ${filter.scope.sectionPlural}'
      : 'إحصاءات التقرير';

  final movementColumns = _movementColumns(columnIds);
  final summaryColumns = _summaryColumns(filter.groupBy, columnIds);

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح: سقف الحزمة الافتراضي (20 صفحة للعنصر الواحد) كان يُسقط
      // تقارير المخازن الكبيرة فلا تُطبَع ولا تُصدَّر إطلاقاً.
      // Explicit page ceiling: the package default (20 pages per single widget) aborted
      // large store reports, so nothing was printed or exported at all.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: _reportPageMargin,
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        // 1) الترويسة الرسمية و 2) عنوان التقرير مركّب من أضيق بُعد مُختار
        // 1) the official letterhead and 2) a title composed from the narrowest chosen dimension.
        title: title.headline,
        logo: logo,
        // الفترة والمخازن تظهران عند التخصيص فقط — كما في الشاشة تمامًا
        // The period and the stores appear only when customised — exactly as on screen.
        metaSection: _reportTitleLines(title),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        // 3) الجدول: كامل السطور على صفحات المستند لا في صندوق ثابت، وسطر تجميع في آخره.
        //    التقرير الموسّع يُطبع أقساماً كما يُقرأ: عنوان القسم، جدوله، إحصاءه — ثم الذي يليه.
        // 3) the table: every row across the document's pages, never a fixed box, with its
        //    totals row last. A scoped report prints in sections exactly as it reads: heading,
        //    table, its own statistics — then the next one.
        if (isMovement && sections.isNotEmpty)
          for (final section in sections) ...[
            _pdfSectionHeading(
              '${filter.scope.sectionLabel}: ${section.label}',
              '${section.rows.length} حركة',
            ),
            buildStoreReportGrid<StockMovementRow>(
              columns: movementColumns,
              rows: section.rows,
              totals: ReportTotals.movement(section.rows),
              opening: on('opening')
                  ? ReportTotals.opening(section.stats)
                  : null,
              width: width,
            ),
            pw.SizedBox(height: 2),
            _pdfSectionStats(section.stats, statIds),
            pw.SizedBox(height: 10),
          ]
        else if (isMovement)
          buildStoreReportGrid<StockMovementRow>(
            columns: movementColumns,
            rows: movementRows,
            totals: ReportTotals.movement(movementRows),
            opening: on('opening') ? opening : null,
            width: width,
          )
        else
          buildStoreReportGrid<StockSummaryRow>(
            columns: summaryColumns,
            rows: summaryRows,
            totals: ReportTotals.summary(summaryRows),
            width: width,
          ),
        pw.SizedBox(height: 10),
        // 4) ملخص الجدول بعد المتن لا قبله، وبالحقول التي أبقاها المستخدم فقط
        // 4) the table summary, after the body rather than stealing its place, carrying only
        //    the fields the user kept.
        _reportStatsStrip(statsTitle, stats, statIds),
        pw.SizedBox(height: 12),
        // 5) التذييل الرسمي — مخازن: أمين المخزن
        // 5) the official footer — stores: the storekeeper's slot.
        pdfSignatures(keeper: 'توقيع أمين المخزن'),
      ],
    ),
  );

  return doc.save();
}

/// أعمدة الحركة لقالب الشاشة نفسها — بنفس ترتيب المستخدم لا بترتيب القالب
/// The movement columns exactly as the screen's template resolves them, in the user's order.
List<ReportColumn<StockMovementRow>> _movementColumns(List<String>? columnIds) {
  final template = ReportColumns.movement();

  return ReportColumns.ordered(
    template,
    columnIds ?? ReportColumns.defaultIds(template),
  );
}

/// أعمدة الخلاصة حسب مستوى التجميع — عنوان العمود الأول يتبدّل معه
/// The summary columns for the aggregation level; the first column's caption follows it.
List<ReportColumn<StockSummaryRow>> _summaryColumns(
  StoreReportGroupBy level,
  List<String>? columnIds,
) {
  final template = ReportColumns.summary(level);

  return ReportColumns.ordered(
    template,
    columnIds ?? ReportColumns.defaultIds(template),
  );
}

/// أسطر العنوان التكميلية في رأس الـ PDF — لا شيء إن لم يُخصِّص المستخدم شيئًا
/// The title's follow-up lines in the PDF head — nothing if the user customised nothing.
///
/// ── لا جدول معطيات هنا: المستند الرسمي يقول «ماذا» في عنوانه، وتكرار تسعة قيود قبل
///    الجدول كان يزحزح المتن ويحوّل المطبوع إلى نموذج إدخال
/// ── No parameters table here: an official document says "what" in its own title, and
///    repeating nine constraints above the grid pushed the body down and turned the print
///    back into an input form.
pw.Widget _reportTitleLines(ReportTitle title) {
  final lines = <String>[
    if (title.period != null) title.period!,
    if (title.stores != null) title.stores!,
  ];

  if (lines.isEmpty) {
    return pw.SizedBox.shrink();
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      for (final line in lines)
        pw.Text(
          pdfArabic(line),
          textDirection: kPdfShapedTextDirection,
          style: const pw.TextStyle(fontSize: 8.5),
        ),
    ],
  );
}

/// شريط إحصاءات المطبوع — خانات مثل الشاشة حرفياً: نفس الحقول ونفس الألفاظ
/// The printout's statistics strip — the screen's chips literally: same fields, same wording.
///
/// ── كان سطراً واحداً بصياغة أخرى («صادر» حيث تقرأ الشاشة «المنصرف»): ورقة لا تطابق
///    الشاشة في اللفظ لا يُطمأن إلى أرقامها مهما حسُن إطارها.
/// ── It used to be one differently worded sentence («صادر» where the screen reads
///    «المنصرف»); a sheet that disagrees with the screen in wording makes its own figures
///    suspect, however tidy its frame.
pw.Widget _reportStatsStrip(String title, ReportStats stats, List<String>? statIds) {
  return pdfStatsStrip(
    title: title,
    fields: _statBoxes(
      ReportStatFields.visible(ReportStatFields.of(stats), statIds),
    ),
  );
}

/// حقول الشاشة جاهزة للخانات — عنوان وقيمة ولون بلا أي ترجمة ثانية
/// The screen's fields turned into print boxes — caption, value and colour, never a second
/// translation of any of them.
List<PdfStatBox> _statBoxes(List<ReportStatField> fields) {
  return [
    for (final field in fields)
      PdfStatBox(
        field.label,
        field.value,
        tone: field.color,
        emphasis: field.emphasis,
      ),
  ];
}

/// جدول التقرير في المطبوع — `pw.Table` واحدة برأس واحد وسطر واحد لكل خانة
/// The report's print table — ONE `pw.Table`, one head, one line per cell.
///
/// ── `<T>` وليس `Object`: قارئ العمود دالة تستقبل صف نوعها، وإمحاء النوع يرمي
///    `is not a subtype` عند أول خلية تُبنى في الملف.
/// ── `<T>`, not `Object`: a column's reader takes its own row type, and erasing it throws
///    "is not a subtype" on the first cell the document builds.
///
/// ── الأعمدة تُعكس لأن `pw.Table` يرسم أبناءه يساراً→يمين دائماً، فيقع أول عمود
///    منطقياً (النوع/السند) أقصى اليمين كما على الشاشة.
/// ── Columns are reversed because `pw.Table` always draws children left→right: the first
///    logical column lands at the far right, exactly where the screen puts it.
/// عامة لا خاصة: الاختبار يقرأ بنية الجدول من هنا، وشبكة بلا اختبار هي ما جعل
/// عطل «الرأس في كل صفحة» يعيش دورات كاملة بلا كاشف
/// Public on purpose: the test reads this table's structure through this function, and an
/// untested grid is why the repeated-head defect survived whole rounds undetected.
pw.Table buildStoreReportGrid<T>({
  required List<ReportColumn<T>> columns,
  required List<T> rows,
  required double width,
  Map<String, String>? totals,
  Map<String, String>? opening,
}) {
  final ordered = columns.reversed.toList(growable: false);

  return pdfReportGrid(
    columns: [
      for (final column in ordered)
        PdfGridColumn(
          label: column.label,
          numeric: column.numeric,
          weight: column.weight,
        ),
    ],
    // السطور نصاً جاهزاً: نفس ما يقرأه العمود على الشاشة بلا صيغة ثانية
    // Rows as display text: the very string the column reads on screen, no second format.
    rows: [
      for (int index = 0; index < rows.length; index++)
        [
          for (final column in ordered) column.read(rows[index], index),
        ],
    ],
    opening: opening == null ? null : _bandCells(ordered, opening, 'رصيد سابق'),
    totals: totals == null ? null : _bandCells(ordered, totals, 'الإجمالي'),
    width: width,
  );
}

/// بناء شبكة من أعمدة منطقية (أولها أقصى اليمين) — العكس الذي يطلبه `pw.Table` داخلي
/// Builds a grid from LOGICAL columns (the first sits at the far right); the reversal
/// `pw.Table` needs stays internal, so a caption can never land over another column's values.
///
/// ── كان كشف الجرد ينعكس رؤوسه وحده فتُقرأ قيمته تحت عنوان عمود آخر؛ الترتيب المنطقي
///    واحد للعناوين والقيم يستحيل معه هذا الانزياح.
/// ── The stocktake sheet used to reverse only its headers, printing each figure under another
///    column's caption; one logical order for captions and values makes that shift impossible.
pw.Widget _pdfGridFromLogical({
  required List<PdfGridColumn> columns,
  required List<List<String>> rows,
  required double width,
}) {
  return pdfReportGrid(
    columns: columns.reversed.toList(growable: false),
    rows: [
      for (final row in rows) row.reversed.toList(growable: false),
    ],
    width: width,
  );
}

/// قيم شريط (الافتتاح أو المجاميع) بترتيب الأعمدة المعروض — أول خانة بلا رقم تحمل الاسم
/// A band's figures in display order — the first column without a figure carries the label.
///
/// ── قاعدة الشاشة نفسها: الكلمة لا تُضاف عموداً زائداً، والرقم يبقى في عموده
/// ── The screen's own rule: the word never adds a column, and the figure stays in its own.
List<String> _bandCells<T>(
  List<ReportColumn<T>> ordered,
  Map<String, String> figures,
  String label,
) {
  final cells = <String>[];
  var labelled = false;

  for (final column in ordered) {
    final figure = (figures[column.id] ?? '').trim();

    if (figure.isEmpty && !labelled) {
      labelled = true;
      cells.add(label);
    } else {
      cells.add(figure);
    }
  }

  return cells;
}

/// عنوان قسم في المطبوع — يحمل اسم وحدة القسم (الصنف الفرعي / الرئيسي / المجموعة الفرعية)
/// A section heading in the printout — carrying the section unit's own name.
///
/// ── بدونه تصير أقسام التقرير جدولاً واحداً متصلاً في الورق: القارئ لا يعرف أين انتهى فرع
///    وبدأ آخر، وهو الفرق الوحيد بين هذه التقارير الأربعة.
/// ── Without it the sections merge into one continuous table on paper: the reader cannot tell
///    where a branch ended and another began — the one difference between these four reports.
pw.Widget _pdfSectionHeading(String label, String count) {
  const palette = PdfGridPalette();

  return pw.Container(
    // نفس شريط الشاشة: أساسي فاتر وعنوان بلون السمة وعدد باهت — بلا ذهبي ثقيل
    // The screen's own band: a pale primary ground, a themed caption and a muted count.
    color: palette.sectionBand,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          pdfArabic(label),
          textDirection: kPdfShapedTextDirection,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: palette.headText,
          ),
        ),
        pw.Text(
          pdfArabic(count),
          textDirection: kPdfShapedTextDirection,
          style: pw.TextStyle(fontSize: 7.5, color: palette.muted),
        ),
      ],
    ),
  );
}

/// إحصاء القسم في المطبوع — سطر واحد رقيق يُغلق ذيل جدول القسم، بخانات الشاشة نفسها
/// A section's statistics in the printout — one thin line closing that section's table foot,
/// drawn with the screen's own fields.
///
/// ── نفس حقول الشاشة ومعرّفاتها: حقل أخفاه المستخدم لا يظهر في الورق
/// ── The screen's own fields under the same ids: a field the user hid never reaches paper.
///
/// ── أربعة أرقام لا تسعة: إحصاء القسم يجيب «من أين بدأ وأين انتهى وكم تحرّك»، ولا يعيد
///    إحصاء التقرير كاملاً في ذيل كل فرع.
/// ── Four figures, not nine: a section answers "where it began, where it ended, how much
///    moved", and does not repeat the report summary under every branch.
pw.Widget _pdfSectionStats(ReportStats stats, List<String>? statIds) {
  return pdfStatsStrip(
    title: '',
    compact: true,
    fields: _statBoxes(
      ReportStatFields.visible(ReportStatFields.section(stats), statIds),
    ),
  );
}

/// سطر إحصاء القسم نصاً — يقرأه الـ PDF والـ Excel من مصدر واحد
/// A section's statistics as one line — read by the PDF and the Excel from one place.
///
/// ── النص واحد لا نسختان: اختلاف صياغة بين الورق والملف يجعل المراجع يشك في الرقم نفسه
/// ── One string, not two copies: a wording difference between paper and file makes the
///    reviewer doubt the figure itself.
///
/// ── والحقول هنا هي الأربعة نفسها التي يرسمها العميل (`ReportStatFields.sectionIds`):
///    سابق · وارد · منصرف · رصيد حالي — فلا يزيد الورق على الشاشة.
/// ── The fields here are the same four the client draws (`ReportStatFields.sectionIds`):
///    opening · in · out · closing — so paper never carries more than the screen.
String sectionStatsLine(ReportStats stats, List<String>? statIds) {
  bool on(String id) => statIds == null || statIds.contains(id);

  final parts = <String>[
    if (on('opening')) 'السابق ${StoreFormat.qty(stats.openingQty)}',
    if (on('in')) 'الوارد ${StoreFormat.qty(stats.qtyIn)}',
    if (on('out')) 'المنصرف ${StoreFormat.qty(stats.qtyOut)}',
    if (on('closing')) 'الرصيد الحالي ${StoreFormat.qty(stats.closingQty)}',
  ];

  return parts.join(' · ');
}

/// مولّد XLSX لتقرير المخازن — ورقة السطور وورقة المعطيات والمجاميع
/// The stores-report XLSX: a rows sheet plus a parameters-and-totals sheet.
///
/// ── ورقة المعطيات ليست ترفاً: ملف يُفتح بعد أسبوع بلا الفترة ولا المخازن ولا الأعمدة
///    التي صُدِّرت به لا يُحكم عليه.
/// ── The parameters sheet is not decoration: a file opened a week later with no period,
///    store list or column set is a file nobody can judge.
List<int> buildStoreReportXlsx({
  required StoreReportFilter filter,
  StoreReference? reference,
  required List<StockMovementRow> movementRows,
  required List<StockSummaryRow> summaryRows,
  required double totalIn,
  required double totalOut,
  required double totalValue,
  List<String>? columnIds,
  // أقسام التقرير الموسّع — والملف يُبنى مثل الشاشة: قسم، جدوله، إحصاؤه
  // The scoped report's sections — the file is built like the screen: section, table, stats.
  List<ReportSection<StockMovementRow>> sections = const [],
  /// رصيد الفترة السابقة في التقرير المسطّح
  /// The pre-period balance of a flat report.
  Map<String, String>? opening,
}) {
  final isMovement = filter.kind == StoreReportKind.movement;
  final count = isMovement ? movementRows.length : summaryRows.length;

  final excel = Excel.createExcel();
  final sheet = excel[isMovement ? 'حركة' : 'خلاصة'];

  // النوع يبقى حقيقيًا هنا أيضًا: قارئ محاك يرمي `is not a subtype` عند أول صّف
  // The type stays real here too: an erased reader throws on the first cell written.
  if (isMovement && sections.isNotEmpty) {
    for (final section in sections) {
      _appendColumns<StockMovementRow>(
        sheet,
        _movementColumns(columnIds),
        section.rows,
        ReportTotals.movement(section.rows),
        opening: ReportTotals.opening(section.stats),
        heading: <String>[
          '${filter.scope.sectionLabel}: ${section.label}',
          '${section.rows.length} حركة',
        ],
        // السطر نفسه الذي في الـ PDF بالعنوان نفسه: ملف يُقرأ بجانب ورق لا يخالفه
        // The very line the PDF carries, caption included: a file read beside paper never
        // contradicts it.
        // statsLine: 'إحصاءات ${filter.scope.sectionLabel}: '
        //     '${sectionStatsLine(section.stats, null)}',
      );
    }
  } else if (isMovement) {
    _appendColumns<StockMovementRow>(
      sheet,
      _movementColumns(columnIds),
      movementRows,
      ReportTotals.movement(movementRows),
      opening: opening,
    );
  } else {
    _appendColumns<StockSummaryRow>(
      sheet,
      _summaryColumns(filter.groupBy, columnIds),
      summaryRows,
      ReportTotals.summary(summaryRows),
    );
  }

  final meta = excel['المعطيات'];

  meta.appendRow([TextCellValue('البند'), TextCellValue('القيمة')]);

  for (final parameter in ReportParameters.of(filter, reference: reference)) {
    meta.appendRow([
      TextCellValue(parameter.label),
      TextCellValue(
        parameter.isActive ? parameter.value : '${parameter.value} —',
      ),
    ]);
  }

  meta.appendRow([]);
  meta.appendRow([
    TextCellValue('عدد السطور'),
    TextCellValue('${count}'),
  ]);
  meta.appendRow([
    TextCellValue('وارد / صادر / صافي'),
    TextCellValue(
      '${StoreFormat.qty(totalIn)} / ${StoreFormat.qty(totalOut)} / '
      '${StoreFormat.qty(totalIn - totalOut)}',
    ),
  ]);
  meta.appendRow([
    TextCellValue('القيمة'),
    TextCellValue(StoreFormat.money(totalValue)),
  ]);

  return excel.save() ?? <int>[];
}

/// كتابة قسم واحد في ورقة Excel: عنوانه ثم رأسه ثم افتتاحه ثم سطوره ثم تجميعه ثم إحصاءه
/// Write one section into an Excel sheet: heading, head, opening, rows, totals, statistics.
///
/// ── الحزمة LTR فتُكتب الأعمدة بالترتيب المنطقي (الأول = أقصى اليسار)، وهو ترتيب
///    شاشة التقرير لا العكس الذي يحتاجه الـ PDF
/// ── The package is LTR, so columns go in logical order (first = far left) — the screen's
///    order, not the reversed one the PDF needs.
///
/// ── كل جزء اختياري لأن الأداة نفسها تخدم التقارير الأربعة: تقرير الصنف الفرعي المسطّح
///    لا عنوان قسم له ولا إحصاء، والتقرير المتشعب له الثلاثة.
/// ── Every part is optional because one helper serves all four reports: the flat branch
///    statement has no section heading and no statistics, the sectioned ones have both.
void _appendColumns<T>(
  Sheet sheet,
  List<ReportColumn<T>> columns,
  List<T> rows,
  Map<String, String> totals, {
  Map<String, String>? opening,
  List<String>? heading,
  String? statsLine,
}) {
  // عنوان القسم قبل رأس الأعمدة — نفس ترتيب الورق
  // The section heading before the column head — the paper's own order.
  if (heading != null && heading.isNotEmpty) {
    sheet.appendRow([
      for (final cell in heading) TextCellValue(cell),
    ]);
  }

  sheet.appendRow([
    for (final column in columns)
      TextCellValue(column.label),
  ]);

  // صف «رصيد سابق» قبل أول حركة: أول عمود لا رقم له يأخذ العنوان، وبه يبدأ عمود الرصيد
  // The opening row before the first movement: the first column with no figure takes the
  // caption, and the balance column starts from it.
  if (opening != null) {
    var captioned = false;
    final line = <TextCellValue>[];

    for (final column in columns) {
      final figure = opening[column.id];

      if (figure != null) {
        line.add(TextCellValue(figure));
      } else if (!captioned) {
        captioned = true;
        line.add(TextCellValue('رصيد سابق'));
      } else {
        line.add(TextCellValue(''));
      }
    }

    sheet.appendRow(line);
  }

  for (int index = 0; index < rows.length; index++) {
    sheet.appendRow([
      for (final column in columns)
        TextCellValue(column.read(rows[index], index)),
    ]);
  }

  sheet.appendRow([
    for (final column in columns)
      TextCellValue(totals[column.id] ?? ''),
  ]);

  // سطر إحصاء القسم ثم سطر فارغ: الفاصل هو ما يفصل قسمين متتاليين في ورقة واحدة
  // The section's statistics line then a blank line: the gap is what separates two sections.
  if (statsLine != null && statsLine.trim().isNotEmpty) {
    sheet.appendRow([TextCellValue(statsLine)]);
    sheet.appendRow([TextCellValue('')]);
  }
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

  // العرض المتاح بعد هامشي الورقة — مقياس الخانات جميعاً
  // The width left after the margins — the measure of every cell.
  final width = _reportContentWidth;

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح: سقف الحزمة الافتراضي (20 صفحة للعنصر الواحد) كان يُسقط
      // تقارير المخازن الكبيرة فلا تُطبَع ولا تُصدَّر إطلاقاً.
      // Explicit page ceiling: the package default (20 pages per single widget) aborted
      // large store reports, so nothing was printed or exported at all.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: _reportPageMargin,
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
        // القائمة تُطبع بشبكة التقارير نفسها: رأس واحد لا يتكرر، وخانة بسطر واحد
        // The list prints with the reports' own grid: one head that never repeats,
        // and one line per cell.
        _pdfGridFromLogical(
          width: width,
          columns: [
            const PdfGridColumn(label: 'المستند', weight: 1.1),
            const PdfGridColumn(label: 'التاريخ', weight: 1),
            const PdfGridColumn(label: 'المخزن', weight: 1.5),
            PdfGridColumn(
              label: kind.hasParty ? 'الطرف' : 'إلى مخزن',
              weight: 1.6,
            ),
            const PdfGridColumn(label: 'السطور', numeric: true, weight: 0.7),
            const PdfGridColumn(label: 'الإجمالي', numeric: true, weight: 1.1),
            const PdfGridColumn(label: 'الخصم', numeric: true, weight: 1),
            const PdfGridColumn(label: 'الصافي', numeric: true, weight: 1.1),
          ],
          rows: [
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
              ],
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

  // العرض المتاح بعد هامشي الورقة — مقياس الخانات جميعاً
  // The width left after the margins — the measure of every cell.
  final width = _reportContentWidth;

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح: سقف الحزمة الافتراضي (20 صفحة للعنصر الواحد) كان يُسقط
      // تقارير المخازن الكبيرة فلا تُطبَع ولا تُصدَّر إطلاقاً.
      // Explicit page ceiling: the package default (20 pages per single widget) aborted
      // large store reports, so nothing was printed or exported at all.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: _reportPageMargin,
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
        // شبكة واحدة: رأس لا يتكرر، وخانة بسطر واحد، وعناوين لا تنزلق عن قيمها
        // One grid: a head that never repeats, one line per cell, captions over their values.
        _pdfGridFromLogical(
          width: width,
          columns: [
            const PdfGridColumn(label: 'المخزن', weight: 1.2),
            const PdfGridColumn(label: 'الكود', weight: 0.9),
            const PdfGridColumn(label: 'الصنف', weight: 2),
            const PdfGridColumn(label: 'الوحدة', weight: 0.6),
            const PdfGridColumn(label: 'رصيد النظام', numeric: true, weight: 1),
            const PdfGridColumn(label: 'الفعلي', numeric: true, weight: 1),
            const PdfGridColumn(label: 'قيمة الفرق', numeric: true, weight: 1),
            const PdfGridColumn(label: 'الفرق', numeric: true, weight: 0.9),
            if (hasNotes) const PdfGridColumn(label: 'ملاحظة السطر', weight: 1.6),
          ],
          rows: [
            for (final row in rows)
              [
                row.storeName ?? '—',
                row.partNo ?? '—',
                row.itemName ?? '—',
                row.uomCode ?? '—',
                StoreFormat.qty(row.systemQty),
                StoreFormat.qty(countedOf(row)),
                StoreFormat.money(varianceOf(row) * row.cost),
                StoreFormat.qty(varianceOf(row)),
                if (hasNotes) notes[row.key] ?? '—',
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
  /// الكشف نفسه — نفس مصدر جدول الشاشة وشريطها، فلا يتفارق الورق عنها لفظاً ولا رقماً
  /// The statement itself — the screen's own source for both its table and its strip, so
  /// paper cannot drift from it in wording or in figures.
  required MovementStatement statement,
  List<String>? columnIds,
  List<String>? statIds,
  bool branchOnly = false,
  bool customPeriod = false,
}) async {
  final theme = await ReportPdfFonts.theme();
  final doc = pw.Document(theme: theme);
  final logo = await loadPdfLetterheadLogo(height: 46);
  final columns = _movementColumns(columnIds);
  final rows = statement.rows;

  // العرض المتاح بعد هامشي الورقة — مقياس الخانات جميعاً
  // The width left after the margins — the measure of every cell.
  final width = _reportContentWidth;

  // نفس عنوان الشاشة بالضبط: لا يطبع الـ PDF «كشف حركة صنف» بينما تعرض الشاشة «صنف فرعي»
  // The screen's exact title: the PDF must not print "an item statement" while the screen
  // shows "a sub-item statement".
  final title = ReportTitles.statement(
    itemName: itemName,
    branchLabel: branchLabel,
    branchOnly: branchOnly,
    period: customPeriod ? rangeText : null,
  );

  doc.addPage(
    pw.MultiPage(
      // سقف الصفحات الصريح: سقف الحزمة الافتراضي (20 صفحة للعنصر الواحد) كان يُسقط
      // تقارير المخازن الكبيرة فلا تُطبَع ولا تُصدَّر إطلاقاً.
      // Explicit page ceiling: the package default (20 pages per single widget) aborted
      // large store reports, so nothing was printed or exported at all.
      maxPages: kReportPdfMaxPages,
      pageFormat: PdfPageFormat.a4,
      margin: _reportPageMargin,
      textDirection: pw.TextDirection.rtl,
      header: (context) => buildReportPdfHeader(
        letterhead: letterhead,
        // 1) الترويسة الرسمية و2) عنوان الكشف + المدى عند التخصيص فقط
        // 1) the official letterhead and 2) the statement title, with the range only if set.
        title: title.headline,
        logo: logo,
        metaSection: _reportTitleLines(title),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        // 3) جدول الكشف — `pw.Table` واحدة تقسمها MultiPage على الصفحات برأس واحد
        // 3) the statement table — one `pw.Table` that MultiPage splits across pages, head once.
        buildStoreReportGrid<StockMovementRow>(
          columns: columns,
          rows: rows,
          totals: ReportTotals.movement(rows),
          width: width,
        ),
        pw.SizedBox(height: 10),
        // 4) ملخص الكشف بعد الجدول — بالحقول التي أبقاها المستخدم فقط
        // 4) the statement summary, after the table, with only the fields the user kept.
        _statementSummaryStrip(statement, statIds),
        pw.SizedBox(height: 12),
        // 5) التذييل الرسمي — كشف مخزني: أمين المخزن
        // 5) the official footer — a stores statement: the storekeeper's slot.
        pdfSignatures(keeper: 'توقيع أمين المخزن'),
      ],
    ),
  );

  return doc.save();
}

/// شريط ملخص الكشف في المطبوع — خانات الشاشة نفسها وبأسمائها
/// The statement's printed summary — the screen's own chips under the screen's own names.
///
/// ── كان السطر يعيد صياغة الحقول («صادر» حيث تقرأ الشاشة «المنصرف»): اللفظ حين يفترق
///    يُشكّك في الرقم نفسه، وهذا أخطر من أي سطر ملتوٍ.
/// ── The line used to re-word the fields («صادر» where the screen reads «المنصرف»); a
///    different word makes the reader doubt the figure itself — worse than a crooked row.
pw.Widget _statementSummaryStrip(
  MovementStatement statement,
  List<String>? statIds,
) {
  return pdfStatsStrip(
    title: 'إحصاءات الكشف',
    fields: _statBoxes(
      ReportStatFields.visible(
        ReportStatFields.statement(statement),
        statIds,
      ),
    ),
  );
}

/// كشف الحركة بصيغة XLSX — بنفس أعمدة الشاشة وبنفس المجاميع
/// The movement statement as XLSX — the screen's columns and the screen's totals.
List<int> buildItemStatementXlsx({
  required String itemName,
  required String branchLabel,
  required String rangeText,
  required List<StockMovementRow> rows,
  required double qtyIn,
  required double qtyOut,
  required double netQty,
  required double totalValue,
  List<String>? columnIds,
}) {
  final columns = _movementColumns(columnIds);
  final excel = Excel.createExcel();
  final sheet = excel['حركة الصنف'];

  // سطر التجميع من السطور نفسها: نفس ما يراه المستخدم في ذيل الجدول
  // The totals row comes from the rows themselves: exactly what the on-screen table shows.
  _appendColumns<StockMovementRow>(
    sheet,
    columns,
    rows,
    ReportTotals.movement(rows),
  );

  final meta = excel['المعطيات'];

  meta.appendRow([TextCellValue('البند'), TextCellValue('القيمة')]);
  meta.appendRow([TextCellValue('الصنف'), TextCellValue(itemName)]);
  meta.appendRow([TextCellValue('الفرع'), TextCellValue(branchLabel)]);
  meta.appendRow([TextCellValue('المدى'), TextCellValue(rangeText)]);
  meta.appendRow([TextCellValue('عدد السطور'), TextCellValue('${rows.length}')]);
  meta.appendRow([
    TextCellValue('وارد / صادر / صافي'),
    TextCellValue(
      '${StoreFormat.qty(qtyIn)} / ${StoreFormat.qty(qtyOut)} / '
      '${StoreFormat.qty(netQty)}',
    ),
  ]);
  meta.appendRow([
    TextCellValue('القيمة'),
    TextCellValue(StoreFormat.money(totalValue)),
  ]);

  return excel.save() ?? <int>[];
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
