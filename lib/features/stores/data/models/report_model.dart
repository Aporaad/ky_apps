import '../../../../core/utils/json_value_utils.dart';

/// نوع التقرير: عرض حركة تفصيلي أو خلاصة مجمّعة
/// The report kind: a detailed movement view or an aggregated summary.
enum StoreReportKind {
  movement('movement', 'عرض حركة'),
  summary('summary', 'خلاصة');

  const StoreReportKind(this.code, this.label);

  final String code;
  final String label;
}

/// مستوى التجميع في الخلاصة
/// The aggregation level of a summary report.
///
/// ── «خلاصة» سؤال واحد بصيغتين: ما تحرك لكل صنف في كل مخزن؟ أم ما تحرك لمجموعة كاملة؟
///    الاختيار صريح الآن بدل أن يكون قراراً ثابتاً في الكود.
/// ── "Summary" is one question in two forms: what moved per item per store, or what moved
///    across a whole group? The level is now chosen, not hard-coded.
enum StoreReportGroupBy {
  item('item', 'الصنف × المخزن'),
  store('store', 'المخزن'),
  group('group', 'المجموعة الرئيسية'),
  subgroup('subgroup', 'المجموعة الفرعية'),
  category('category', 'الفئة');

  const StoreReportGroupBy(this.code, this.label);

  final String code;
  final String label;
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
    this.groupBy = StoreReportGroupBy.item,
    this.customPeriod = false,
  });

  final StoreReportKind kind;
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

  StoreReportFilter copyWith({
    StoreReportKind? kind,
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
    );
  }
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

  /// عنوان العمود الأول حسب مستوى التجميع — «الصنف» لا معنى له حين تُجمع بالمخزن
  /// The first column's caption for the aggregation level: "item" is meaningless when the
  /// report is grouped by store.
  String labelFor(StoreReportGroupBy level) => switch (level) {
    StoreReportGroupBy.store => storeName ?? 'مخزن $storeNo',
    StoreReportGroupBy.group => groupName ?? '—',
    StoreReportGroupBy.subgroup => typeName ?? '—',
    StoreReportGroupBy.category => category ?? '—',
    StoreReportGroupBy.item => itemName ?? partNo ?? 'صنف $sanfNo',
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
