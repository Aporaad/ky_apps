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

/// مولّد PDF لمستند مخزني (توريد · صرف · تحويل)
/// The PDF builder of one stock document (receive · issue · transfer).
Future<Uint8List> buildStoreOrderPdf({
  required ReportLetterheadInfo letterhead,
  required StoreOrderKind kind,
  required StoreOrderModel header,
  required List<StoreOrderLineModel> lines,
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
        title: '${kind.documentLabel} رقم ${header.reference}',
        logo: logo,
        metaSection: _orderMeta(kind, header),
      ),
      footer: (context) => buildReportPdfFooter(context),
      build: (context) => [
        _orderTable(lines),
        pw.SizedBox(height: 10),
        _orderTotals(header),
        pw.SizedBox(height: 22),
        _signatures(kind),
      ],
    ),
  );

  return doc.save();
}

/// ترويسة معطيات المستند
/// The document meta block.
pw.Widget _orderMeta(StoreOrderKind kind, StoreOrderModel header) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pdfArabic('${kind.hasTargetStore ? 'من مخزن' : 'المخزن'}: ${header.storeName ?? header.storeNo}'),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            pdfArabic('التاريخ: ${header.dateLabel}'),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            pdfArabic(
              kind.hasTargetStore
                  ? 'إلى مخزن: ${header.storeToName ?? header.storeTo ?? '—'}'
                  : '${kind == StoreOrderKind.receive ? 'المورد' : 'الجهة المستلمة'}: ${header.partyName ?? '—'}',
            ),
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            pdfArabic('عدد الأصناف: ${header.sanfNums}'),
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
      if (header.detailes != null) ...[
        pw.SizedBox(height: 3),
        pw.Text(
          pdfArabic('البيان: ${header.detailes}'),
          style: pw.TextStyle(
            fontSize: 9.5,
            color: ReportPdfColors.subtleText,
          ),
        ),
      ],
    ],
  );
}

/// جدول سطور المستند — الأعمدة معكوسة لأن `pw.Table` يرسم LTR داخل صفحة RTL
/// The document lines table — columns are reversed because pw.Table lays out LTR inside
/// an RTL page.
pw.Widget _orderTable(List<StoreOrderLineModel> lines) {
  final headers = [
    'م',
    'الكود',
    'الصنف',
    'الوحدة',
    'الكمية',
    'السعر',
    'الإجمالي',
  ];

  return pw.TableHelper.fromTextArray(
    border: pw.TableBorder.all(color: ReportPdfColors.border, width: 0.5),
    headerDecoration: const pw.BoxDecoration(color: ReportPdfColors.headerBg),
    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    cellStyle: const pw.TextStyle(fontSize: 8.5),
    cellAlignment: pw.Alignment.centerRight,
    headers: headers.reversed
        .map((header) => pdfArabic(header))
        .toList(growable: false),
    data: [
      for (var index = 0; index < lines.length; index++)
        [
          StoreFormat.money(lines[index].total),
          StoreFormat.money(lines[index].price),
          StoreFormat.qty(lines[index].qty),
          pdfArabic(lines[index].unitName ?? '—'),
          pdfArabic(lines[index].sanfName ?? '—'),
          lines[index].partNo ?? '—',
          '${index + 1}',
        ],
    ],
  );
}

/// مجاميع المستند
/// The document totals.
pw.Widget _orderTotals(StoreOrderModel header) {
  return pw.Container(
    alignment: pw.Alignment.centerLeft,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          pdfArabic('الإجمالي: ${StoreFormat.money(header.total)}'),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          pdfArabic('الخصم: ${StoreFormat.money(header.discount)}'),
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          pdfArabic('الصافي: ${StoreFormat.money(header.net)}'),
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
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
            pw.Text(pdfArabic(label), style: const pw.TextStyle(fontSize: 9)),
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
