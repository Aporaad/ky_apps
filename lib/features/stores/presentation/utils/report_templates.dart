import '../../data/models/report_model.dart';

/// قالب تقرير واحد: عموده الأساسية، واختياراته، ومستويات جمعه
/// One report template: its basic columns, its options and its grouping levels.
///
/// ── لماذا جدول قوالب لا أعمدة واحدة لكل التقارير؟ لأن «حركة صنف فرعي» و«خلاصة مجموعة
///    رئيسية» سؤالاان مختلفان تماماً: الأول سطور حركة برصيد جارٍ، والثاني أرقام مجمّعة
///    بمستويات تجميع متعددة. توحيد القالب يعني إما أعمدة زائدة أو أعمدة ناقصة في أحدهما.
/// ── Why a table of templates rather than one column set? "A branch movement statement" and
///    "a main-group summary" are different questions: the first is movement lines with a
///    running balance, the second is aggregated figures with several grouping levels. One
///    shared shape would over-column one and under-column the other.
class ReportTemplate {
  const ReportTemplate({
    required this.scope,
    required this.kind,
    required this.basic,
    required this.optional,
    this.groupings = const [],
  });

  final StoreReportScope scope;
  final StoreReportKind kind;

  /// الأعمدة الأساسية — تظهر دائماً ولا تُخفى لأنها تعريف التقرير
  /// The basic columns: always shown, because they define what the report is.
  final List<String> basic;

  /// الأعمدة القابلة للتخصيص — يضيفها المستخدم عند الحاجة فقط
  /// The customizable columns: added only when the user needs them.
  final List<String> optional;

  /// مستويات التجميع المتاحة (الخلاصة وحدها) — كل تقرير يعرض ما يسأله فعلاً
  /// The grouping levels offered — summary reports only, and each offers what it can answer.
  final List<StoreReportGroupBy> groupings;

  String get title => kind == StoreReportKind.movement
      ? 'تقرير حركة ${scope.label}'
      : 'تقرير خلاصة ${scope.label}';

  bool get sectioned => kind == StoreReportKind.movement && scope.sectioned;

  /// المعرّفات الظاهرة عند أول تشغيل: الأساسية وحدها — فلا أعمدة لم يطلبها أحد
  /// What is shown on first run: the basic columns only — nothing the user did not ask for.
  Set<String> get defaultIds => basic.toSet();
}

/// كتالوج تقارير المخازن — ثمانية قوالب: أربعة حركة وأربعة خلاصة
/// The stores-report catalog: eight templates — four movement, four summary.
class ReportTemplates {
  ReportTemplates._();

  /// الأعمدة الأساسية لحركة الأصناف — بأسماء الميدان نفسه
  /// The basic movement columns, in the words the floor itself uses.
  static const List<String> _movementBasic = <String>[
    'type',
    'date',
    'doc',
    'qty',
    'cost',
    'value',
    'balance',
  ];

  /// ما يُضاف عند الطلب: من المخزن إلى قيمة الرصيد إلى بقية الأوصاف
  /// What may be added on request: store, balance value and the rest of the descriptions.
  static const List<String> _movementOptional = <String>[
    'no',
    'store',
    'balanceValue',
    'item',
    'part',
    'branch',
    'color',
    'unit',
    'in',
    'out',
    'net',
    'group',
    'sub',
    'category',
  ];

  static const List<String> _summaryBasic = <String>[
    'part',
    'label',
    'unit',
    'cost',
    'in',
    'out',
    'net',
    'balance',
  ];

  static const List<String> _summaryOptional = <String>[
    'no',
    'store',
    'opening',
    'inValue',
    'outValue',
    'balanceValue',
    'category',
    'group',
    'sub',
    'lines',
  ];

  static const List<ReportTemplate> all = <ReportTemplate>[
    // ─── الحركة: صنف فرعي جدول واحد بلا أقسام، والبقية قسم لكل عنصر أوسع ───
    // Movement: a branch is one flat table; wider scopes become one section per element.
    ReportTemplate(
      scope: StoreReportScope.branch,
      kind: StoreReportKind.movement,
      basic: _movementBasic,
      optional: _movementOptional,
    ),
    ReportTemplate(
      scope: StoreReportScope.item,
      kind: StoreReportKind.movement,
      basic: _movementBasic,
      optional: _movementOptional,
    ),
    ReportTemplate(
      scope: StoreReportScope.subGroup,
      kind: StoreReportKind.movement,
      basic: _movementBasic,
      optional: _movementOptional,
    ),
    ReportTemplate(
      scope: StoreReportScope.mainGroup,
      kind: StoreReportKind.movement,
      basic: _movementBasic,
      optional: _movementOptional,
    ),

    // ─── الخلاصة: مستويات التجميع تُعرض لكل نطاق لأن ما يصلح للصنف لا يصلح للمجموعة ───
    // Summary: grouping levels are per scope — what is right for an item is wrong for a group.
    ReportTemplate(
      scope: StoreReportScope.branch,
      kind: StoreReportKind.summary,
      basic: _summaryBasic,
      optional: _summaryOptional,
      groupings: [StoreReportGroupBy.itemStore, StoreReportGroupBy.store],
    ),
    ReportTemplate(
      scope: StoreReportScope.item,
      kind: StoreReportKind.summary,
      basic: _summaryBasic,
      optional: _summaryOptional,
      groupings: [
        StoreReportGroupBy.sub,
        StoreReportGroupBy.subStore,
        StoreReportGroupBy.store,
      ],
    ),
    ReportTemplate(
      scope: StoreReportScope.subGroup,
      kind: StoreReportKind.summary,
      basic: _summaryBasic,
      optional: _summaryOptional,
      groupings: [
        StoreReportGroupBy.item,
        StoreReportGroupBy.sub,
        StoreReportGroupBy.store,
        StoreReportGroupBy.itemSub,
        StoreReportGroupBy.itemStore,
        StoreReportGroupBy.subStore,
      ],
    ),
    ReportTemplate(
      scope: StoreReportScope.mainGroup,
      kind: StoreReportKind.summary,
      basic: _summaryBasic,
      optional: _summaryOptional,
      groupings: [
        StoreReportGroupBy.subGroup,
        StoreReportGroupBy.item,
        StoreReportGroupBy.sub,
        StoreReportGroupBy.store,
        StoreReportGroupBy.subGroupItem,
        StoreReportGroupBy.subGroupSub,
        StoreReportGroupBy.subGroupStore,
        StoreReportGroupBy.subStore,
      ],
    ),
  ];

  /// قالب المعطيات الحالية: واحد من الكتالوج دائماً، لا توليف حر للأعمدة
  /// The template behind a filter: always one of the catalog, never a free column mix.
  static ReportTemplate of(StoreReportFilter filter) {
    for (final template in all) {
      if (template.scope == filter.scope && template.kind == filter.kind) {
        return template;
      }
    }

    return all.first;
  }

  /// الأعمدة التي تُرسم: الأساسية دائماً + ما اختاره المستخدم من القائمة الاختيارية
  /// The columns drawn: the basic ones always, plus whatever the user picked as optional.
  static List<String> visibleIds(
    ReportTemplate template, {
    Set<String> chosen = const {},
  }) {
    return [
      ...template.basic,
      for (final id in template.optional)
        if (chosen.contains(id) && !template.basic.contains(id)) id,
    ];
  }
}
