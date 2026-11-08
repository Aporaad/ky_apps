import '../../data/models/report_model.dart';
import '../widgets/store_ui.dart';

/// عمود واحد في قالب التقرير: هويّة، عنوان، عرض نسبي، وقراءة الصف
/// One report column: identity, caption, relative width and the row reader.
///
/// ── لماذا تعريف مشترك؟ لأن الشاشة و PDF و Excel ثلاثة مستهلكين لجدول واحد؛ وأي تعريف
///    مستقل لكل منهم يعني أن ما يراه المستخدم ليس ما يطبعه ولا ما يصدّره.
/// ── Why one shared definition? The screen, the PDF and the Excel are three consumers of a
///    single table; separate definitions would mean what the user sees is not what they print
///    or export.
///
/// ── القارئ يستقبل الفهرس أيضاً: عمود «م.» يحتاج ترقيم الظاهر لا محتوى الصف.
/// ── The reader also receives the index: the serial column needs the row's position, not its
///    contents.
class ReportColumn<T> {
  const ReportColumn({
    required this.id,
    required this.label,
    required this.read,
    this.weight = 1,
    this.numeric = false,
    this.defaultOn = false,
  });

  final String id;
  final String label;
  final String Function(T row, int index) read;

  /// الوزن النسبي داخل الجدول — لا بكسلات ثابتة لأن الأعمدة قابلة للإخفاء
  /// Relative weight — never fixed pixels, because columns can be hidden.
  final double weight;

  /// الأرقام تُحاذى يساراً والنصوص يميناً في واجهة RTL
  /// Numbers align to the left, text to the right, in an RTL face.
  final bool numeric;
  final bool defaultOn;
}

/// قوالب أعمدة تقارير المخازن
/// The column templates for the stores reports.
class ReportColumns {
  ReportColumns._();

  /// أعمدة عرض الحركة — لكل احتمال ينتجه معطٍ عمود يُظهره عند الحاجة
  /// Movement columns: whatever a parameter can produce has a column to show it.
  static List<ReportColumn<StockMovementRow>> movement() {
    return const [
      ReportColumn(
        id: 'no',
        label: 'م.',
        weight: 0.4,
        numeric: true,
        defaultOn: true,
        read: _mvNo,
      ),
      ReportColumn(
        id: 'date',
        label: 'التاريخ',
        weight: 1.1,
        defaultOn: true,
        read: _mvDate,
      ),
      ReportColumn(
        id: 'doc',
        label: 'المستند',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _mvDoc,
      ),
      ReportColumn(
        id: 'type',
        label: 'نوع الحركة',
        weight: 1.3,
        defaultOn: true,
        read: _mvType,
      ),
      ReportColumn(
        id: 'store',
        label: 'المخزن',
        weight: 1.2,
        defaultOn: true,
        read: _mvStore,
      ),
      ReportColumn(
        id: 'part',
        label: 'الكود',
        weight: 0.9,
        defaultOn: true,
        read: _mvPart,
      ),
      ReportColumn(
        id: 'item',
        label: 'الصنف',
        weight: 1.7,
        defaultOn: true,
        read: _mvItem,
      ),
      ReportColumn(
        id: 'branch',
        label: 'الصنف الفرعي',
        weight: 1.3,
        defaultOn: true,
        read: _mvBranch,
      ),
      ReportColumn(
        id: 'color',
        label: 'اللون',
        weight: 0.9,
        read: _mvColor,
      ),
      ReportColumn(
        id: 'group',
        label: 'المجموعة',
        weight: 1.1,
        read: _mvGroup,
      ),
      ReportColumn(
        id: 'sub',
        label: 'المجموعة الفرعية',
        weight: 1.2,
        read: _mvSub,
      ),
      ReportColumn(
        id: 'category',
        label: 'الفئة',
        weight: 1,
        read: _mvCategory,
      ),
      ReportColumn(
        id: 'unit',
        label: 'الوحدة',
        weight: 0.7,
        read: _mvUnit,
      ),
      ReportColumn(
        id: 'in',
        label: 'وارد',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _mvIn,
      ),
      ReportColumn(
        id: 'out',
        label: 'صادر',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _mvOut,
      ),
      ReportColumn(
        id: 'net',
        label: 'الصافي',
        weight: 0.9,
        numeric: true,
        read: _mvNet,
      ),
      ReportColumn(
        id: 'cost',
        label: 'التكلفة',
        weight: 1,
        numeric: true,
        read: _mvCost,
      ),
      ReportColumn(
        id: 'value',
        label: 'القيمة',
        weight: 1.1,
        numeric: true,
        defaultOn: true,
        read: _mvValue,
      ),
    ];
  }

  /// أعمدة الخلاصة — العمود الأول يتبدّل عنوانه ومحتواه مع مستوى التجميع
  /// Summary columns: the first one follows the chosen aggregation level.
  static List<ReportColumn<StockSummaryRow>> summary(StoreReportGroupBy level) {
    return [
      ReportColumn(
        id: 'no',
        label: 'م.',
        weight: 0.4,
        numeric: true,
        defaultOn: true,
        read: _smNo,
      ),
      ReportColumn(
        id: 'label',
        label: switch (level) {
          StoreReportGroupBy.store => 'المخزن',
          StoreReportGroupBy.group => 'المجموعة الرئيسية',
          StoreReportGroupBy.subgroup => 'المجموعة الفرعية',
          StoreReportGroupBy.category => 'الفئة',
          StoreReportGroupBy.item => 'الصنف',
        },
        weight: 1.8,
        defaultOn: true,
        read: (row, index) => row.labelFor(level),
      ),
      const ReportColumn(
        id: 'part',
        label: 'الكود',
        weight: 0.9,
        defaultOn: true,
        read: _smPart,
      ),
      ReportColumn(
        id: 'store',
        label: 'المخزن',
        weight: 1.1,
        defaultOn: level == StoreReportGroupBy.item,
        read: _smStore,
      ),
      ReportColumn(
        id: 'group',
        label: 'المجموعة',
        weight: 1.1,
        read: _smGroup,
      ),
      ReportColumn(
        id: 'sub',
        label: 'المجموعة الفرعية',
        weight: 1.2,
        read: _smSub,
      ),
      ReportColumn(
        id: 'category',
        label: 'الفئة',
        weight: 1,
        read: _smCategory,
      ),
      const ReportColumn(
        id: 'unit',
        label: 'الوحدة',
        weight: 0.7,
        defaultOn: true,
        read: _smUnit,
      ),
      const ReportColumn(
        id: 'in',
        label: 'وارد',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _smIn,
      ),
      const ReportColumn(
        id: 'out',
        label: 'صادر',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _smOut,
      ),
      const ReportColumn(
        id: 'net',
        label: 'الصافي',
        weight: 0.9,
        numeric: true,
        defaultOn: true,
        read: _smNet,
      ),
      const ReportColumn(
        id: 'cost',
        label: 'التكلفة',
        weight: 1,
        numeric: true,
        read: _smCost,
      ),
      const ReportColumn(
        id: 'value',
        label: 'القيمة',
        weight: 1.1,
        numeric: true,
        defaultOn: true,
        read: _smValue,
      ),
      const ReportColumn(
        id: 'lines',
        label: 'عدد السطور',
        weight: 0.9,
        numeric: true,
        read: _smLines,
      ),
    ];
  }

  /// المعرّفات الظاهرة افتراضياً — تُستخدم أول مرة قبل أن يغيّر المستخدم شيئاً
  /// The ids shown on first use, before the user changes anything.
  static List<String> defaultIds<T>(List<ReportColumn<T>> columns) => [
    for (final column in columns)
      if (column.defaultOn) column.id,
  ];

  /// المعرّفات كلها — خيار «كل الأعمدة» في نافذة الأعمدة
  /// Every id — the "all columns" choice in the columns sheet.
  static List<String> allIds<T>(List<ReportColumn<T>> columns) => [
    for (final column in columns)
      column.id,
  ];

  /// تطبيق اختيار المستخدم على التعريف مع الحفاظ على ترتيب القالب الأصلي
  /// Apply the user's choice to the definition, keeping the template's own order.
  static List<ReportColumn<T>> visible<T>(
    List<ReportColumn<T>> columns,
    Set<String> chosen,
  ) {
    final picked = [
      for (final column in columns)
        if (chosen.contains(column.id)) column,
    ];

    // جدول بلا أعمدة مستحيل: إن أخفى المستخدم كل شيء تعود الأعمدة الافتراضية
    // A column-less table is impossible: hide everything and the defaults come back.
    return picked.isEmpty ? defaultColumns(columns) : picked;
  }

  static List<ReportColumn<T>> defaultColumns<T>(List<ReportColumn<T>> columns) => [
    for (final column in columns)
      if (column.defaultOn) column,
  ];
}

// ─── قراءات الحركة / movement readers ───────────────────────────────────────
// دوال مجردة حتى يبقى تعريف الأعمدة const وقارئ الرقم التسلسلي لا استثناء فيه.
// Bare functions so the template stays const and the serial reader is no special case.

String _mvNo(StockMovementRow row, int index) => '${index + 1}';

String _mvDate(StockMovementRow row, int index) => row.dateLabel;

String _mvDoc(StockMovementRow row, int index) => row.docNo?.toString() ?? '—';

String _mvType(StockMovementRow row, int index) => row.typeName ?? '—';

String _mvStore(StockMovementRow row, int index) => row.storeName ?? '${row.storeNo}';

String _mvPart(StockMovementRow row, int index) => row.partNo ?? '—';

String _mvItem(StockMovementRow row, int index) =>
    row.itemName ?? 'صنف ${row.sanfNo}';

String _mvBranch(StockMovementRow row, int index) =>
    row.sanfDno == null ? '—' : row.subLabel;

String _mvColor(StockMovementRow row, int index) => row.colorName ?? '—';

String _mvGroup(StockMovementRow row, int index) => row.groupName ?? '—';

String _mvSub(StockMovementRow row, int index) => row.typeNameDetail ?? '—';

String _mvCategory(StockMovementRow row, int index) => row.category ?? '—';

String _mvUnit(StockMovementRow row, int index) => row.uomCode ?? '—';

String _mvIn(StockMovementRow row, int index) =>
    row.qtyIn == 0 ? '—' : StoreFormat.qty(row.qtyIn);

String _mvOut(StockMovementRow row, int index) =>
    row.qtyOut == 0 ? '—' : StoreFormat.qty(row.qtyOut);

String _mvNet(StockMovementRow row, int index) => StoreFormat.qty(row.netQty);

String _mvCost(StockMovementRow row, int index) => StoreFormat.money(row.cost);

String _mvValue(StockMovementRow row, int index) =>
    StoreFormat.money(row.lineValue);

// ─── قراءات الخلاصة / summary readers ───────────────────────────────────────
String _smNo(StockSummaryRow row, int index) => '${index + 1}';

String _smPart(StockSummaryRow row, int index) => row.partNo ?? '—';

String _smStore(StockSummaryRow row, int index) =>
    row.storeName ?? '${row.storeNo}';

String _smGroup(StockSummaryRow row, int index) => row.groupName ?? '—';

String _smSub(StockSummaryRow row, int index) => row.typeName ?? '—';

String _smCategory(StockSummaryRow row, int index) => row.category ?? '—';

String _smUnit(StockSummaryRow row, int index) => row.uomCode ?? '—';

String _smIn(StockSummaryRow row, int index) => StoreFormat.qty(row.qtyIn);

String _smOut(StockSummaryRow row, int index) => StoreFormat.qty(row.qtyOut);

String _smNet(StockSummaryRow row, int index) => StoreFormat.qty(row.netQty);

String _smCost(StockSummaryRow row, int index) => StoreFormat.money(row.cost);

String _smValue(StockSummaryRow row, int index) =>
    StoreFormat.money(row.netValue);

String _smLines(StockSummaryRow row, int index) => '${row.rowsCount}';
