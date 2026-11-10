import '../../../../core/utils/json_value_utils.dart';

/// نطاق التقرير — بأي شيء يسأل المستخدم بالضبط
/// The report scope: what exactly the user is asking about.
///
/// ── النطاق يقرّر كل شيء بعده: حركة صنف فرعي جدول واحد، وحركة صنف رئيسي قسم لكل فرع،
///    وحركة مجموعة فرعية قسم لكل صنف رئيسي، وحركة مجموعة رئيسية قسم لكل مجموعة فرعية.
/// ── The scope decides everything after it: a branch statement is one table, an item statement
///    sections per branch, a sub-group statement per main item, a main-group one per sub group.
enum StoreReportScope {
  branch('branch', 'صنف فرعي', false),
  item('item', 'صنف رئيسي', true),
  subGroup('subgroup', 'مجموعة فرعية', true),
  mainGroup('group', 'مجموعة رئيسية', true);

  const StoreReportScope(this.code, this.label, this.sectioned);

  final String code;
  final String label;

  /// هل يُعرض هذا النطاق كأقسام متتابعة برصيد لكل قسم؟
  /// Whether this report renders as successive sections with a balance per section.
  final bool sectioned;

  /// اسم **وحدة القسم** في هذا النطاق — ما يتكرّر في التقرير ويحمل إحصاءه
  /// The name of the SECTION UNIT in this scope — what repeats in the report and carries
  /// its own statistics.
  ///
  /// ── حركة صنف رئيسي تُقسَّم للفروع، وحركة مجموعة فرعية للأصناف الرئيسية، وحركة مجموعة
  ///    رئيسية للمجموعات الفرعية — والفرق بين الثلاثة هو هذا الاسم وحده في الواجهة.
  /// ── An item statement sections by branches, a sub-group statement by main items and a
  ///    main-group statement by sub groups — the only difference on screen is this name.
  String get sectionLabel => switch (this) {
    StoreReportScope.branch => 'الصنف الفرعي',
    StoreReportScope.item => 'الصنف الفرعي',
    StoreReportScope.subGroup => 'الصنف الرئيسي',
    StoreReportScope.mainGroup => 'المجموعة الفرعية',
  };

  /// جمع وحدة القسم — عنوان الإحصاء الختامي: «إجمالي كل الأصناف الفرعية» لا «إجمالي كل
  /// الصنف الفرعي»
  /// The plural of the section unit — the closing band's caption. Without it the grand total
  /// would be titled with a singular, which reads as one section rather than all of them.
  String get sectionPlural => switch (this) {
    StoreReportScope.branch => 'الأصناف الفرعية',
    StoreReportScope.item => 'الأصناف الفرعية',
    StoreReportScope.subGroup => 'الأصناف الرئيسية',
    StoreReportScope.mainGroup => 'المجموعات الفرعية',
  };

  static StoreReportScope fromCode(String? code) {
    for (final scope in values) {
      if (scope.code == code) return scope;
    }

    return branch;
  }
}

/// نوع التقرير: عرض حركة تفصيلي أو خلاصة مجمّعة
/// The report kind: a detailed movement view or an aggregated summary.
enum StoreReportKind {
  movement('movement', 'عرض حركة'),
  summary('summary', 'خلاصة');

  const StoreReportKind(this.code, this.label);

  final String code;
  final String label;
}

/// مستوى التجميع في الخلاصة — تركيب مركّب من الرموز التي يعرفها الخادم
/// The summary's aggregation level: a composite of the tokens the server recognises.
///
/// ── الرموز حرفياً كما في القائمة البيضاء بالخادم (`item|sub|store|subgroup|group|category`)
///    مفصولة بنجمة: أي رمز آخر يُهمل هناك ولا يصل إلى SQL.
/// ── The codes are literally the server whitelist tokens joined by `*`; anything else is
///    dropped server-side and never reaches the SQL.
enum StoreReportGroupBy {
  itemStore('item*store', 'صنف × مخزن'),
  store('store', 'المخزن'),
  sub('sub', 'صنف فرعي'),
  subStore('sub*store', 'صنف فرعي × مخزن'),
  item('item', 'صنف رئيسي'),
  itemSub('item*sub', 'صنف رئيسي × صنف فرعي'),
  subGroup('subgroup', 'مجموعة فرعية'),
  mainGroup('group', 'مجموعة رئيسية'),
  subGroupItem('subgroup*item', 'مجموعة فرعية × صنف رئيسي'),
  subGroupSub('subgroup*sub', 'مجموعة فرعية × صنف فرعي'),
  subGroupStore('subgroup*store', 'مجموعة فرعية × مخزن'),
  groupSubGroup('group*subgroup', 'مجموعة رئيسية × مجموعة فرعية'),
  category('category', 'الفئة');

  const StoreReportGroupBy(this.code, this.label);

  final String code;
  final String label;

  /// عنوان العمود الأول في الخلاصة: «الشيء الذي جُمِّعت له السطور» لا تسمية ثابتة
  /// The summary's first column caption: whatever the rows were grouped by — never a
  /// hard-coded word.
  ///
  /// ── العنوان يأتي مع مستوى التجميع وإلا قرأ المراجع عمود «الصنف» وهو في الحقيقة عمود
  ///    الفروع، فيكون الرقم صحيحاً والقراءة غلط.
  /// ── Without it a reader would see a column headed "item" holding branch rows: right
  ///    numbers, wrong meaning.
  String get subjectLabel => switch (this) {
    StoreReportGroupBy.itemStore => 'الصنف',
    StoreReportGroupBy.item => 'الصنف الرئيسي',
    StoreReportGroupBy.sub => 'الصنف الفرعي',
    StoreReportGroupBy.subStore => 'الصنف الفرعي',
    StoreReportGroupBy.itemSub => 'الصنف الفرعي',
    StoreReportGroupBy.store => 'المخزن',
    StoreReportGroupBy.subGroup => 'المجموعة الفرعية',
    StoreReportGroupBy.mainGroup => 'المجموعة الرئيسية',
    StoreReportGroupBy.groupSubGroup => 'المجموعة الفرعية',
    StoreReportGroupBy.subGroupItem => 'الصنف الرئيسي',
    StoreReportGroupBy.subGroupSub => 'الصنف الفرعي',
    StoreReportGroupBy.subGroupStore => 'المخزن',
    StoreReportGroupBy.category => 'الفئة',
  };

  /// هل يحمل هذا المستوى فروعه كأعمدة مستقلة؟ (يعني عمود الفرع واللون)
  /// Whether this level keeps branches as their own columns (so a branch and colour column).
  bool get hasBranch => switch (this) {
    StoreReportGroupBy.sub ||
    StoreReportGroupBy.subStore ||
    StoreReportGroupBy.itemSub ||
    StoreReportGroupBy.subGroupSub => true,
    _ => false,
  };
}

/// معطيات التقرير التي تختارها النافذة المنبثقة
/// The report parameters chosen in the filter sheet.
///
/// ── `movementTypeNos` لا تُرسل في «خلاصة»: الخلاصة تجمع كل أنواع الحركة بطبيعتها، وفلترة
///    نوعٍ فيها تعطي وارداً/صادراً ناقصاً يخالف معنى الرصيد.
/// ── movementTypeNos is never sent for a summary: a summary aggregates all movement types,
///    and filtering one type there would produce a partial in/out that contradicts the balance.
///
/// ── المخازن والمجموعات والفرعيات قوائم لا مفردات: تقرير واحد يغطي ثلاث مجموعات أو مخزنين
///    معاً، و«لاشي» يعني بلا قيد لا «اختر شيئاً».
/// ── Stores, groups and sub groups are lists, not singles: one report may cover three groups
///    or two stores, and "None" means unconstrained — not "pick something".
class StoreReportFilter {
  const StoreReportFilter({
    this.kind = StoreReportKind.movement,
    this.scope = StoreReportScope.branch,
    required this.from,
    required this.to,
    this.storeNos = const [],
    this.groupNos = const [],
    this.itemTypeNos = const [],
    this.catNo,
    this.sanfNo,
    this.sanfName,
    this.sanfDno,
    this.sanfDnoLabel,
    this.movementTypeNos = const [],
    this.groupBy = StoreReportGroupBy.itemStore,
    this.customPeriod = false,
  });

  final StoreReportKind kind;

  /// نطاق التقرير: يقرّر الأعمدة الأساسية، وتقسيم الأقسام، والإحصاءات
  /// The report scope: it decides the basic columns, the sections and the statistics.
  final StoreReportScope scope;
  final DateTime from;
  final DateTime to;
  final List<int> storeNos;
  final List<int> groupNos;
  final List<int> itemTypeNos;
  final int? catNo;
  final int? sanfNo;

  /// اسم الصنف المختار — الطابعة تعرض الاسم لا الرقم
  /// The picked item's name: the printed sheet shows a name, never a bare number.
  final String? sanfName;
  final int? sanfDno;
  final String? sanfDnoLabel;
  final List<int> movementTypeNos;
  final StoreReportGroupBy groupBy;

  /// هل خصّص المستخدم الفترة بنفسه؟ العنوان الرسمي لا يذكر المدى إلا إذا خصّصه،
  /// فالافتراضي جزء من معنى التقرير لا من نتائجه
  /// Did the user customise the period? The official title prints the range only when they did:
  /// the default window belongs to the report's meaning, not to its result.
  final bool customPeriod;

  String get fromText => _dateText(from);

  String get toText => _dateText(to);

  /// هل نوع الحركة فعّال في هذا النوع من التقارير؟
  /// Is the movement-type filter meaningful for this report kind?
  bool get usesMovementTypes => kind == StoreReportKind.movement;

  bool get usesGroupBy => kind == StoreReportKind.summary;

  /// عدد القيود الفعلية — يظهر في شريط المعطيات وفي الترويسة المطبوعة
  /// How many constraints are actually in force — shown on the meta band and the print header.
  int get constraintCount {
    var count = 0;
    if (storeNos.isNotEmpty) count++;
    if (groupNos.isNotEmpty) count++;
    if (itemTypeNos.isNotEmpty) count++;
    if (catNo != null) count++;
    if (sanfNo != null) count++;
    if (sanfDno != null) count++;
    if (usesMovementTypes && movementTypeNos.isNotEmpty) count++;

    return count;
  }

  bool get isValid => !from.isAfter(to);

  /// كشف حركة صنف رئيسي — نفس قالب «تقارير المخازن» يفتح مباشرة بمعطياته
  /// A main-item movement statement — the very stores-reports template, opened with its params.
  ///
  /// ── لماذا مصنع هنا لا وسيط في الشاشة؟ لأن المعطيات هي التقرير نفسه: نطاق صنف مقيد
  ///    بصنفه، والمدى الافتراضي للتقرير (٣٠ يوماً) يبقى «غير مخصص» حتى لا يُطبع في العنوان
  ///    كان المستخدم اختاره.
  /// ── Why a factory rather than screen flags? The parameters *are* the report: an item scope
  ///    bound to its item, and the report's own default 30-day window stays "not customised"
  ///    so the title never prints a range nobody picked.
  factory StoreReportFilter.forItemStatement({
    required int sanfNo,
    required String itemName,
  }) {
    final now = DateTime.now();

    return StoreReportFilter(
      kind: StoreReportKind.movement,
      scope: StoreReportScope.item,
      from: now.subtract(const Duration(days: 30)),
      to: now,
      sanfNo: sanfNo,
      sanfName: itemName,
    );
  }

  /// كشف حركة صنف فرعي — نطاق فرع مقيد بفرعه، والعنوان يسمّي الفرع نفسه
  /// A sub-item (branch) statement — a branch scope bound to that branch, titled by the branch.
  factory StoreReportFilter.forBranchStatement({
    required int sanfNo,
    required int sanfDno,
    required String branchLabel,
  }) {
    final now = DateTime.now();

    return StoreReportFilter(
      kind: StoreReportKind.movement,
      scope: StoreReportScope.branch,
      from: now.subtract(const Duration(days: 30)),
      to: now,
      sanfNo: sanfNo,
      sanfDno: sanfDno,
      sanfDnoLabel: branchLabel,
    );
  }

  StoreReportFilter copyWith({
    StoreReportKind? kind,
    StoreReportScope? scope,
    DateTime? from,
    DateTime? to,
    List<int>? storeNos,
    List<int>? groupNos,
    List<int>? itemTypeNos,
    int? catNo,
    int? sanfNo,
    String? sanfName,
    int? sanfDno,
    String? sanfDnoLabel,
    List<int>? movementTypeNos,
    StoreReportGroupBy? groupBy,
    bool? customPeriod,
    bool clearCat = false,
    bool clearSanf = false,
    bool clearSanfDno = false,
  }) {
    return StoreReportFilter(
      kind: kind ?? this.kind,
      scope: scope ?? this.scope,
      from: from ?? this.from,
      to: to ?? this.to,
      storeNos: storeNos ?? this.storeNos,
      groupNos: groupNos ?? this.groupNos,
      itemTypeNos: itemTypeNos ?? this.itemTypeNos,
      catNo: clearCat ? null : catNo ?? this.catNo,
      sanfNo: clearSanf ? null : sanfNo ?? this.sanfNo,
      sanfName: clearSanf ? null : sanfName ?? this.sanfName,
      sanfDno: clearSanfDno ? null : sanfDno ?? this.sanfDno,
      sanfDnoLabel: clearSanfDno ? null : sanfDnoLabel ?? this.sanfDnoLabel,
      movementTypeNos: movementTypeNos ?? this.movementTypeNos,
      groupBy: groupBy ?? this.groupBy,
      customPeriod: customPeriod ?? this.customPeriod,
    );
  }

  /// معاملات الاستعلام المشتركة — تُستهلك في المستودع مباشرة
  /// The shared query parameters, consumed directly by the repository.
  Map<String, dynamic> toQuery() => {
    'from': fromText,
    'to': toText,
    // النطاق يُرسل دائماً: الخادم يستنتجه من الفلاتر وقد لا يطابق ما قصده المستخدم
    // The scope is always sent: the server can infer one from the filters that is not what the
    // user actually meant.
    'scope': scope.code,
    if (storeNos.isNotEmpty) 'store_nos': storeNos.join(','),
    if (groupNos.isNotEmpty) 'group_nos': groupNos.join(','),
    if (itemTypeNos.isNotEmpty) 'item_type_nos': itemTypeNos.join(','),
    if (catNo != null) 'cat_no': catNo,
    if (sanfNo != null) 'sanf_no': sanfNo,
    if (sanfDno != null) 'sanf_dno': sanfDno,
    if (usesMovementTypes && movementTypeNos.isNotEmpty)
      'type_nos': movementTypeNos.join(','),
    if (usesGroupBy) 'group_by': groupBy.code,
  };

  static String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
}

/// صف رصيد: صنف × مخزن من `AVVG`
/// A balance row: item × store from AVVG.
class StockBalanceRow {
  const StockBalanceRow({
    required this.sanfNo,
    this.partNo,
    this.itemName,
    this.uomCode,
    this.storeNo = 0,
    this.storeName,
    this.qty = 0,
    this.cost = 0,
    this.value = 0,
    this.groupNo,
    this.groupName,
    this.typeNo,
    this.typeName,
    this.category,
  });

  final int sanfNo;
  final String? partNo;
  final String? itemName;
  final String? uomCode;
  final int storeNo;
  final String? storeName;
  final double qty;
  final double cost;
  final double value;
  final int? groupNo;
  final String? groupName;
  final int? typeNo;
  final String? typeName;
  final String? category;

  bool get isNegative => qty < 0;

  factory StockBalanceRow.fromJson(Map<String, dynamic> json) {
    return StockBalanceRow(
      sanfNo: JsonValues.asInt(json['I_CODE'] ?? json['i_code']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      itemName: JsonValues.asArabic(json['ITEM_NAME'] ?? json['item_name']),
      uomCode: JsonValues.asArabic(json['UOM_CODE'] ?? json['uom_code']),
      storeNo: JsonValues.asInt(json['INV_ID'] ?? json['inv_id']),
      storeName: JsonValues.asArabic(json['INVNAME'] ?? json['invname']),
      qty: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['COST'] ?? json['cost']) ?? 0,
      value: JsonValues.asDoubleOrNull(json['VALUE'] ?? json['value']) ?? 0,
      groupNo: JsonValues.asIntOrNull(json['GROUPNO'] ?? json['groupno']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeNo: JsonValues.asIntOrNull(json['TYPE_NO'] ?? json['type_no']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      category: JsonValues.asArabic(json['CAT'] ?? json['cat']),
    );
  }
}

/// صف حركة مخزنية تفصيلي
/// A detailed stock movement row.
class StockMovementRow {
  const StockMovementRow({
    this.date,
    this.docNo,
    this.typeNo,
    this.typeName,
    this.storeNo = 0,
    this.storeName,
    this.sanfNo = 0,
    this.sanfDno,
    this.partNo,
    this.itemName,
    this.uomCode,
    this.qtyIn = 0,
    this.qtyOut = 0,
    this.netQty = 0,
    this.cost = 0,
    this.lineValue = 0,
    this.groupName,
    this.typeNameDetail,
    this.category,
    this.subName,
    this.colorName,
    this.balanceQty = 0,
    this.balanceValue = 0,
    this.sectionKey = '',
    this.sectionLabel = '',
  });

  final DateTime? date;
  final int? docNo;
  final int? typeNo;
  final String? typeName;
  final int storeNo;
  final String? storeName;
  final int sanfNo;
  final int? sanfDno;
  final String? partNo;
  final String? itemName;
  final String? uomCode;
  final double qtyIn;
  final double qtyOut;
  final double netQty;
  final double cost;
  final double lineValue;
  final String? groupName;
  final String? typeNameDetail;
  final String? category;

  /// اسم الفرع الذي حرّك السطر — كشف حركة الصنف الرئيسي «بكامل فروعه» يحتاج تمييز السطر
  /// The branch that moved the line — the main item's statement must name its branches.
  final String? subName;
  final String? colorName;

  /// ── الرصيد الجاري داخل قسم السطر: السابق + تراكم الصافي حتى هذا السطر.
  /// ── The running balance inside the row's section: its opening plus the net up to this line.
  ///    يُحسب في الخادم لا على الشاشة، لأن الرصيد رقم مالي لا زينة عرض.
  ///    It is computed server-side: a balance is a financial figure, not a display detail.
  final double balanceQty;
  final double balanceValue;

  /// مفتاح القسم وعنوانه — حركة صنف رئيسي تُقسَّم لكل فرع، ومجموعة فرعية لكل صنف
  /// The section's key and label: an item statement splits per branch, a sub group per item.
  final String sectionKey;
  final String sectionLabel;

  /// وصف الفرع كما يُعرض: الاسم أو المقاس، ثم اللون إن وُجد
  /// The branch label: its name or size, then its colour when present.
  String get subLabel {
    final name = subName?.trim();

    if (name != null && name.isNotEmpty) return name;

    if (sanfDno != null) return 'فرع $sanfDno';

    return '—';
  }

  String get dateLabel => JsonValues.formatDate(date, withTime: false);

  factory StockMovementRow.fromJson(Map<String, dynamic> json) {
    return StockMovementRow(
      date: JsonValues.asDate(json['I_DATE'] ?? json['i_date']),
      docNo: JsonValues.asIntOrNull(json['DOC_NO'] ?? json['doc_no']),
      typeNo: JsonValues.asIntOrNull(json['TYPE_NO'] ?? json['type_no']),
      typeName: JsonValues.asArabic(json['TR_INV_TYPE_NAME'] ?? json['tr_inv_type_name']),
      storeNo: JsonValues.asInt(json['INV_ID'] ?? json['inv_id']),
      storeName: JsonValues.asArabic(json['INV_NAME'] ?? json['inv_name']),
      sanfNo: JsonValues.asInt(json['I_CODE'] ?? json['i_code']),
      sanfDno: JsonValues.asIntOrNull(json['P_CODE'] ?? json['p_code']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      itemName: JsonValues.asArabic(json['IT_NAME'] ?? json['it_name']),
      uomCode: JsonValues.asArabic(json['UOM_CODE'] ?? json['uom_code']),
      qtyIn: JsonValues.asDoubleOrNull(json['QTY_IN'] ?? json['qty_in']) ?? 0,
      qtyOut: JsonValues.asDoubleOrNull(json['QTY_OUT'] ?? json['qty_out']) ?? 0,
      netQty: JsonValues.asDoubleOrNull(json['P_QTY'] ?? json['p_qty']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['STK_COST'] ?? json['stk_cost']) ?? 0,
      lineValue:
          JsonValues.asDoubleOrNull(json['LINE_VALUE'] ?? json['line_value']) ?? 0,
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeNameDetail: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      category: JsonValues.asArabic(json['CAT_NAME'] ?? json['cat_name']),
      subName: JsonValues.asArabic(
        json['SUB_NAME'] ?? json['sub_name'] ?? json['SANF_DNAME'] ?? json['sanf_dname'],
      ),
      colorName: JsonValues.asArabic(
        json['COLOR_NAME'] ?? json['color_name'],
      ),
      balanceQty: JsonValues.asDoubleOrNull(json['BALANCE_QTY'] ?? json['balance_qty']) ?? 0,
      balanceValue:
          JsonValues.asDoubleOrNull(json['BALANCE_VALUE'] ?? json['balance_value']) ?? 0,
      sectionKey:
          JsonValues.asText(json['SECTION_KEY'] ?? json['section_key']) ?? '',
      sectionLabel:
          JsonValues.asArabic(json['SECTION_LABEL'] ?? json['section_label']) ?? '',
    );
  }
}

/// إحصاءات تقرير أو قسم: السابق والوارد والمنصرف والصافي والحالي
/// Statistics for a report or one of its sections: opening, in, out, net and closing.
///
/// ── تُحسب في الخادم وتُرسل جاهزة: الرصيد السابق يحتاج مجموع كل ما قبل الفترة، وهو رقم
///    لا يمكن اشتقاقه من السطور المعروضة وحدها بأي حال.
/// ── Computed on the server and shipped ready: the opening balance is the sum of everything
///    before the period, which cannot be derived from the visible rows under any circumstances.
class ReportStats {
  const ReportStats({
    this.openingQty = 0,
    this.openingValue = 0,
    this.qtyIn = 0,
    this.qtyInValue = 0,
    this.qtyOut = 0,
    this.qtyOutValue = 0,
    this.netQty = 0,
    this.closingQty = 0,
    this.closingValue = 0,
    this.rows = 0,
  });

  final double openingQty;

  /// قيمة الرصيد السابق — الرصيد الحالي قيمةً يُبنى عليها لا يبدأ من صفر
  /// The opening balance's value — the closing value is carried on it, not started from zero.
  final double openingValue;
  final double qtyIn;
  final double qtyInValue;
  final double qtyOut;
  final double qtyOutValue;
  final double netQty;
  final double closingQty;
  final double closingValue;
  final int rows;

  factory ReportStats.fromMap(Map<String, dynamic>? map) {
    double pick(String key) => JsonValues.asDoubleOrNull(
      map?[key] ?? map?[key.toUpperCase()],
    ) ?? 0;

    return ReportStats(
      openingQty: pick('opening_qty'),
      openingValue: pick('opening_value'),
      qtyIn: pick('qty_in'),
      qtyInValue: pick('qty_in_value'),
      qtyOut: pick('qty_out'),
      qtyOutValue: pick('qty_out_value'),
      netQty: pick('net_qty'),
      closingQty: pick('closing_qty'),
      closingValue: pick('closing_value'),
      rows: JsonValues.asInt(map?['rows'] ?? map?['ROWS']),
    );
  }
}

/// قسم في تقرير موسّع: عنوانه وإحصاؤه وسطور
/// A section of a scoped report: its label, its statistics and its rows.
///
/// ── حركة صنف رئيسي تعرض كل فرع في قسم، وحركة مجموعة فرعية كل صنف رئيسي، وحركة مجموعة
///    رئيسية كل مجموعة فرعية — والإحصاء يقف نهاية كل قسم لا في آخر التقرير وحده، وإلا
///    احتاج المراجع أن يجمع الأقسام بيد.
/// ── An item statement shows each branch as a section, a sub-group statement each main item,
///    a main-group statement each sub group — and the statistics stop at the end of every
///    section, not only at the end of the report, or a reviewer would add sections by hand.
class ReportSection<T> {
  const ReportSection({
    required this.key,
    required this.label,
    required this.rows,
    required this.stats,
  });

  final String key;
  final String label;
  final List<T> rows;
  final ReportStats stats;
}

/// صف خلاصة: وارد/صادر/صافي لكل صنف ومخزن
/// A summary row: inbound/outbound/net per item and store.
class StockSummaryRow {
  const StockSummaryRow({
    this.sanfNo = 0,
    this.partNo,
    this.itemName,
    this.uomCode,
    this.storeNo = 0,
    this.storeName,
    this.groupName,
    this.typeName,
    this.category,
    this.qtyIn = 0,
    this.qtyOut = 0,
    this.netQty = 0,
    this.cost = 0,
    this.netValue = 0,
    this.rowsCount = 0,
    this.openingQty = 0,
    this.closingQty = 0,
    this.inValue = 0,
    this.outValue = 0,
    this.subDno,
    this.subName,
  });

  final int sanfNo;
  final String? partNo;
  final String? itemName;
  final String? uomCode;
  final int storeNo;
  final String? storeName;
  final String? groupName;
  final String? typeName;
  final String? category;
  final double qtyIn;
  final double qtyOut;
  final double netQty;
  final double cost;
  final double netValue;
  final int rowsCount;

  /// ── الرصيد السابق والحالي لكل سطر خلاصة: السابق من ما قبل الفترة، والحالي منه + الصافي.
  /// ── A summary row's opening and closing balance: the opening from before the period, the
  ///    closing as that opening plus the period net — both computed on the server.
  final double openingQty;
  final double closingQty;

  /// قيمة الوارد وقيمة المنصرف منفصلتان: «صافي القيمة» رقم لا يخبر المراجع عن اتجاه الحركة
  /// Inbound and outbound values kept apart: a net value alone tells a reviewer nothing about
  /// which way the stock actually moved.
  final double inValue;
  final double outValue;

  /// الصنف الفرعي كمجمّع محتمل في خلاصة الصنف الرئيسي
  /// The branch, which may itself be the grouping key of a main-item summary.
  final int? subDno;
  final String? subName;

  /// عنوان العمود الأول حسب مستوى التجميع — «الصنف» لا معنى له حين تُجمع بالمخزن
  /// The first column's caption for the aggregation level: "item" is meaningless when the
  /// report is grouped by store.
  String labelFor(StoreReportGroupBy level) => switch (level) {
    StoreReportGroupBy.store => storeName ?? 'مخزن $storeNo',
    StoreReportGroupBy.mainGroup => groupName ?? '—',
    StoreReportGroupBy.subGroup => typeName ?? '—',
    StoreReportGroupBy.groupSubGroup => typeName ?? '—',
    StoreReportGroupBy.category => category ?? '—',
    StoreReportGroupBy.sub => subName ?? 'فرع ${subDno ?? 0}',
    StoreReportGroupBy.subStore => subName ?? 'فرع ${subDno ?? 0}',
    StoreReportGroupBy.itemSub => subName ?? 'فرع ${subDno ?? 0}',
    StoreReportGroupBy.subGroupSub => subName ?? 'فرع ${subDno ?? 0}',
    StoreReportGroupBy.item => itemName ?? partNo ?? 'صنف $sanfNo',
    StoreReportGroupBy.itemStore => itemName ?? partNo ?? 'صنف $sanfNo',
    StoreReportGroupBy.subGroupItem => itemName ?? partNo ?? 'صنف $sanfNo',
    StoreReportGroupBy.subGroupStore => storeName ?? 'مخزن $storeNo',
  };

  factory StockSummaryRow.fromJson(Map<String, dynamic> json) {
    return StockSummaryRow(
      sanfNo: JsonValues.asInt(json['I_CODE'] ?? json['i_code']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      itemName: JsonValues.asArabic(json['ITEM_NAME'] ?? json['item_name']),
      uomCode: JsonValues.asArabic(json['UOM_CODE'] ?? json['uom_code']),
      storeNo: JsonValues.asInt(json['INV_ID'] ?? json['inv_id']),
      storeName: JsonValues.asArabic(json['INV_NAME'] ?? json['inv_name']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      category: JsonValues.asArabic(json['CAT_NAME'] ?? json['cat_name']),
      qtyIn: JsonValues.asDoubleOrNull(json['QTY_IN'] ?? json['qty_in']) ?? 0,
      qtyOut: JsonValues.asDoubleOrNull(json['QTY_OUT'] ?? json['qty_out']) ?? 0,
      netQty: JsonValues.asDoubleOrNull(json['NET_QTY'] ?? json['net_qty']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['COST'] ?? json['cost']) ?? 0,
      netValue:
          JsonValues.asDoubleOrNull(json['NET_VALUE'] ?? json['net_value']) ?? 0,
      rowsCount: JsonValues.asInt(json['ROWS_COUNT'] ?? json['rows_count']),
      openingQty:
          JsonValues.asDoubleOrNull(json['OPENING_QTY'] ?? json['opening_qty']) ?? 0,
      closingQty:
          JsonValues.asDoubleOrNull(json['CLOSING_QTY'] ?? json['closing_qty']) ?? 0,
      inValue: JsonValues.asDoubleOrNull(json['IN_VALUE'] ?? json['in_value']) ?? 0,
      outValue: JsonValues.asDoubleOrNull(json['OUT_VALUE'] ?? json['out_value']) ?? 0,
      subDno: JsonValues.asIntOrNull(json['P_CODE'] ?? json['p_code']),
      subName: JsonValues.asArabic(json['SUB_NAME'] ?? json['sub_name']),
    );
  }
}

/// سطر كشف الجرد — رصيد النظام فقط، والكمية الفعلية تُدخل في الشاشة ولا تُحفظ
/// A stocktake line — the system quantity only; the counted quantity lives in the screen
/// state and is never persisted.
class StockSheetRow {
  const StockSheetRow({
    required this.sanfNo,
    required this.storeNo,
    this.partNo,
    this.itemName,
    this.uomCode,
    this.storeName,
    this.systemQty = 0,
    this.cost = 0,
    this.systemValue = 0,
    this.groupName,
    this.typeName,
    this.category,
  });

  final int sanfNo;
  final int storeNo;
  final String? partNo;
  final String? itemName;
  final String? uomCode;
  final String? storeName;
  final double systemQty;
  final double cost;
  final double systemValue;
  final String? groupName;
  final String? typeName;
  final String? category;

  /// مفتاح فريد للسطر داخل الكشف (صنف × مخزن)
  /// A unique row key inside the sheet (item × store).
  String get key => '$sanfNo|$storeNo';

  factory StockSheetRow.fromJson(Map<String, dynamic> json) {
    return StockSheetRow(
      sanfNo: JsonValues.asInt(json['I_CODE'] ?? json['i_code']),
      storeNo: JsonValues.asInt(json['INV_ID'] ?? json['inv_id']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      itemName: JsonValues.asArabic(json['ITEM_NAME'] ?? json['item_name']),
      uomCode: JsonValues.asArabic(json['UOM_CODE'] ?? json['uom_code']),
      storeName: JsonValues.asArabic(json['INVNAME'] ?? json['invname']),
      systemQty: JsonValues.asDoubleOrNull(json['SYSTEM_QTY'] ?? json['system_qty']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['COST'] ?? json['cost']) ?? 0,
      systemValue:
          JsonValues.asDoubleOrNull(json['SYSTEM_VALUE'] ?? json['system_value']) ?? 0,
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      category: JsonValues.asArabic(json['CAT'] ?? json['cat']),
    );
  }
}
