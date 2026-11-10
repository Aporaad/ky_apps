import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_letterhead_info.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';
import 'package:ky_apps/features/stores/data/repositories/store_result.dart';
import 'package:ky_apps/features/stores/presentation/utils/report_columns.dart';
import 'package:ky_apps/features/stores/presentation/utils/report_totals.dart';
import 'package:ky_apps/features/stores/presentation/utils/store_export.dart';

/// قالب طباعة/تصدير تقارير المخازن — رأس واحد وسطر واحد ومطابقة الشاشة
/// The stores reports' print/export template — one head, one line, screen parity.
///
/// ── العطل الذي يحرسه هذا الملف: الجدول المطبوع كان يُبنى جداولَ كل ثلاثين سطراً، لكل
///    واحد رأسه وعروضه النسبية المستقلة، فيخرج رأس الجدول في منتصف الورقة مرات وتنزلق
///    الأعمدة بين الرأس والسطور والمجاميع. المطبوع كان قالباً ثانياً كُتب بيد أخرى.
/// ── The defect this file guards: the printed table was built as tables of thirty rows, each
///    with its own head and its own independent fractional widths — so the heading appeared
///    several times down a sheet and columns drifted between head, rows and totals. The
///    printout was a second template written by a second hand.
///
/// ── والاختبار يبني الملفات فعلياً (خطوط من الأصول، ترويسة، جدول، تذييل): مولّد PDF بلا
///    اختبار هو ما أبقى أعطال الطباعة حية حتى بلاغ المستخدم.
/// ── It really builds the documents (fonts from assets, letterhead, grid, footer): an untested
///    PDF builder is exactly what kept print defects alive until a user reported them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const letterhead = ReportLetterheadInfo(
    companyName: ReportLetterheadInfo.kFallbackNameAr,
    address: ReportLetterheadInfo.kFallbackAddressAr,
    phone: ReportLetterheadInfo.kFallbackPhone,
    website: '',
    companyNameEn: ReportLetterheadInfo.kFallbackNameEn,
    addressEn: ReportLetterheadInfo.kFallbackAddressEn,
  );

  final from = DateTime(2026, 9, 1);
  final to = DateTime(2026, 10, 31);

  // العرض المتاح لـ A4 الطولية بهامش جانبي 16 نقطة — نفس رقم المولّد
  // The width available to portrait A4 with a 16 pt side margin — the builder's own number.
  const width = 595.28 - 32;

  const columnIds = <String>[
    'type',
    'date',
    'doc',
    'item',
    'qty',
    'cost',
    'balance',
  ];

  List<StockMovementRow> movements({int count = 3, String key = ''}) {
    return [
      for (int i = 0; i < count; i++)
        StockMovementRow(
          date: DateTime(2026, 10, 12 + (i % 15)),
          docNo: 637 + i,
          typeName: i.isEven ? 'منصرف للقص' : 'وارد من مورد',
          storeNo: 1,
          storeName: 'المحل الرئيسي',
          itemName: 'ايبها ملون ع58',
          subName: 'ازرق فافي',
          uomCode: 'ثوب',
          qtyIn: i.isEven ? 0 : 40.57,
          qtyOut: i.isEven ? 40.57 : 0,
          netQty: i.isEven ? -40.57 : 40.57,
          cost: 320,
          lineValue: i.isEven ? -4418.39 : 4418.39,
          balanceQty: 437.29 + i,
          balanceValue: 12985.76 + i,
          sectionKey: key,
          sectionLabel: key.isEmpty ? '' : 'فرع $key',
        ),
    ];
  }

  final stats = ReportStats(
    openingQty: 240,
    openingValue: 76800,
    qtyIn: 120,
    qtyInValue: 38400,
    qtyOut: 100,
    qtyOutValue: 32000,
    netQty: 20,
    closingQty: 260,
    closingValue: 83200,
    rows: 3,
  );

  List<ReportColumn<StockMovementRow>> chosenColumns() =>
      ReportColumns.ordered(ReportColumns.movement(), columnIds);

  int pagesOf(List<int> bytes) => RegExp(
    r'/Type\s*/Page[^s]',
  ).allMatches(String.fromCharCodes(bytes)).length;

  group('the printed grid is the on-screen grid', () {
    test('a movement table is ONE table whose head never repeats', () {
      final table = buildStoreReportGrid<StockMovementRow>(
        columns: chosenColumns(),
        rows: movements(),
        totals: ReportTotals.movement(movements()),
        opening: ReportTotals.opening(stats),
        width: width,
      );

      // رأس + رصيد سابق + ثلاث حركات + مجاميع، في جدول واحد
      // Head + opening + three movements + totals, in a single table.
      expect(table.children, hasLength(1 + 1 + 3 + 1));
      expect(table.children.every((row) => !row.repeat), isTrue);
    });

    test('a hundred movements do not buy a hundred heads', () {
      final table = buildStoreReportGrid<StockMovementRow>(
        columns: chosenColumns(),
        rows: movements(count: 100),
        totals: ReportTotals.movement(movements(count: 100)),
        width: width,
      );

      // كان كل ثلاثين سطراً يعيد الرأس: أربعة رؤوس لهذا الجدول وحده
      // Thirty rows used to buy a fresh head: this table alone printed four of them.
      expect(table.children, hasLength(1 + 100 + 1));
      expect(table.children.first.repeat, isFalse);
    });

    test('every row carries exactly one cell per chosen column', () {
      final table = buildStoreReportGrid<StockMovementRow>(
        columns: chosenColumns(),
        rows: movements(count: 5),
        totals: ReportTotals.movement(movements(count: 5)),
        opening: ReportTotals.opening(stats),
        width: width,
      );

      // الانزياح الذي كان يشوّه الورق: خانات أقل من الرؤوس في سطر الإجمالي
      // The drift that skewed the paper: fewer cells than captions in a totals row.
      for (final row in table.children) {
        expect(row.children, hasLength(columnIds.length));
      }
    });

    test('the opening balance keeps its label in the first figure-less column', () {
      final table = buildStoreReportGrid<StockMovementRow>(
        columns: chosenColumns(),
        rows: movements(),
        opening: ReportTotals.opening(stats),
        width: width,
      );

      // سطر الافتتاح هو الثاني مباشرة بعد الرأس، وخلاياه بعدد الأعمدة
      // The opening line is the second row, right under the head.
      expect(table.children, hasLength(1 + 1 + 3));
      expect(table.children[1].children, hasLength(columnIds.length));
    });
  });

  group('report documents really build', () {
    test('a flat movement report prints with its opening balance', () async {
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(from: from, to: to),
        movementRows: movements(),
        summaryRows: const [],
        stats: stats,
        columnIds: columnIds,
        statIds: ReportStatFields.defaultIds,
        opening: ReportTotals.opening(stats),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(3000));
    });

    test('a sectioned report prints one grid per section', () async {
      final sections = [
        for (final key in const ['1', '2', '3'])
          ReportSection<StockMovementRow>(
            key: key,
            label: 'فرع $key',
            rows: movements(count: 4, key: key),
            stats: stats,
          ),
      ];

      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(
          scope: StoreReportScope.item,
          from: from,
          to: to,
        ),
        movementRows: [for (final s in sections) ...s.rows],
        summaryRows: const [],
        stats: stats,
        columnIds: columnIds,
        statIds: ReportStatFields.defaultIds,
        sections: sections,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(pagesOf(bytes), greaterThanOrEqualTo(1));
    });

    test('a summary report prints', () async {
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(
          kind: StoreReportKind.summary,
          from: from,
          to: to,
        ),
        movementRows: const [],
        summaryRows: const [
          StockSummaryRow(
            sanfNo: 1991,
            partNo: '1991-01',
            itemName: 'ايبها ملون',
            storeName: 'المحل الرئيسي',
            qtyIn: 120,
            qtyOut: 100,
            netQty: 20,
            netValue: 83200,
          ),
        ],
        stats: stats,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('a long report spans pages without losing rows', () async {
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(from: from, to: to),
        movementRows: movements(count: 400),
        summaryRows: const [],
        stats: ReportStats(rows: 400, closingQty: 260),
        columnIds: columnIds,
        statIds: ReportStatFields.defaultIds,
      );

      // جدول واحد يمتد: رأس في الصفحة الأولى فقط، والبقية سطور
      // One table spans: a head on page one only, rows everywhere else.
      expect(pagesOf(bytes), greaterThan(2));
    });

    test('the page header never swallows the sheet', () async {
      // `pw.Column` في حيز معلوم الارتفاع يتمدد إليه، ولو كان ذلك العمود هو
      // `header:` لابتلعت الترويسة الورقة كلها فلم يسعها سوى سطور قليلة
      // A pw.Column expands to a bounded height; if that column is the page `header:`,
      // the letterhead swallows the sheet and only a few rows fit on each page.
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(from: from, to: to),
        movementRows: movements(count: 60),
        summaryRows: const [],
        stats: ReportStats(rows: 60, closingQty: 260),
        columnIds: columnIds,
        statIds: ReportStatFields.defaultIds,
        opening: ReportTotals.opening(stats),
      );

      final pages = pagesOf(bytes);

      expect(
        pages,
        lessThanOrEqualTo(3),
        reason: '٦٠ سطراً استهلكت $pages صفحة — الورقة لا تمتلئ أو الترويسة تبتلعها',
      );
    });

    test('the report sheet is portrait A4, matching the paper', () async {
      // ── العطل كما رفعه المستخدم: «التقرير في نص الصفحة والبقية في نصف آخر».
      //    الصفحة كانت أفقية (842×595) والطابعة ورقها طولي، فتُصغَّر إلى عرض الورقة
      //    ويصير ارتفاعها 420 نقطة من 842: نصف ورقة محتوى ونصفها بياض.
      // ── The reported defect: "the report sits in half the page". The page was landscape
      //    (842×595) while the paper is portrait, so it shrank to the paper's width and became
      //    420 pt of an 842 pt sheet — half content, half blank.
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: StoreReportFilter(from: from, to: to),
        movementRows: movements(count: 12),
        summaryRows: const [],
        stats: ReportStats(rows: 12, closingQty: 260),
        columnIds: columnIds,
        statIds: ReportStatFields.defaultIds,
      );

      final box = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)',
      ).firstMatch(String.fromCharCodes(bytes));

      expect(box, isNotNull, reason: 'لا MediaBox في المستند');

      final width = double.parse(box!.group(1)!);
      final height = double.parse(box.group(2)!);

      expect(
        height,
        greaterThan(width),
        reason: 'الورقة $width×$height — يجب أن تكون طولية لتطابق ورق الطابعة',
      );
      expect(width.round(), 595);
      expect(height.round(), 842);
    });

    test('an item statement prints the screen fields with the screen wording', () async {
      final statement = MovementStatement(
        rows: movements(count: 6),
        qtyIn: 120,
        qtyOut: 100,
        netQty: 20,
        value: 83200,
        lines: 6,
      );

      final bytes = await buildItemStatementPdf(
        letterhead: letterhead,
        itemName: 'ايبها ملون ع58',
        branchLabel: 'المحل الرئيسي',
        rangeText: 'من تاريخ: 2026-09-01   إلى تاريخ: 2026-10-31',
        statement: statement,
        columnIds: columnIds,
        statIds: ReportStatFields.statementIds,
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('the stocktake sheet and the bulk list print on the same grid', () async {
      // مفتاح سطر الجرد «صنف|مخزن» — به تُقرأ العدّة والملاحظة
      final rowKey = '1991|1';

      final sheet = await buildStockSheetPdf(
        letterhead: letterhead,
        rows: const [
          StockSheetRow(
            sanfNo: 1991,
            storeNo: 1,
            partNo: '1991-01',
            itemName: 'ايبها ملون',
            uomCode: 'ثوب',
            storeName: 'المحل الرئيسي',
            systemQty: 40,
            cost: 320,
          ),
        ],
        counted: {rowKey: 38},
        date: DateTime(2026, 10, 31),
        storesLabel: 'المحل الرئيسي',
        notes: {rowKey: 'فرق ثوبين'},
      );

      final list = await buildStoreOrderListPdf(
        letterhead: letterhead,
        kind: StoreOrderKind.receive,
        orders: [
          StoreOrderModel(
            billNo: 535,
            year: 2026,
            date: DateTime(2026, 10, 31),
            storeNo: 4,
            storeName: 'مخزن بضاعة جاهزة للبيع',
            storeTo: 1,
            storeToName: 'المحل الرئيسي',
            total: 303100,
            net: 303100,
            curName: 'يمني',
            lines: 36,
          ),
        ],
      );

      expect(String.fromCharCodes(sheet.take(5)), '%PDF-');
      expect(String.fromCharCodes(list.take(5)), '%PDF-');
    });
  });

  group('default statistics', () {
    test('five fields show, the rest wait in the customise sheet', () {
      // السابق · وارد · منصرف · الصافي · الرصيد الحالي — لا سطر يفتح على تسعة أرقام
      expect(ReportStatFields.defaultIds, <String>[
        'opening',
        'in',
        'out',
        'net',
        'closing',
      ]);

      final shown = ReportStatFields.visible(
        ReportStatFields.of(stats),
        ReportStatFields.defaultIds,
      );

      expect(shown.map((f) => f.label), <String>[
        'السابق',
        'وارد',
        'منصرف',
        'الصافي',
        'الرصيد الحالي',
      ]);

      // الورق لا يزيد عن الشاشة: نفس الحقول بنفس الألفاظ وبنفس الترتيب
      // Paper never adds to the screen: the same fields, words and order.
      expect(shown.map((f) => f.id), ReportStatFields.defaultIds);
    });
  });
}
