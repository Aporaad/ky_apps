import '../../../../core/utils/json_value_utils.dart';

/// الصنف الرئيسي — صف من `ACCOUNTS.SANFS` مع اسم المجموعة/النوع/الفئة/الوحدة والنمط
/// The main item — an ACCOUNTS.SANFS row with its group/type/category/unit/style names.
///
/// ── لماذا النمط (`styl_no`) إلزامي؟ لأن `ITEM_MOVEMENT_D` تربط `sanfs.styl_no` بـ
///    `style.shape_style_no`؛ صنف بلا نمط لا يظهر في أي حركة ولا في أي رصيد.
/// ── Why is the style mandatory? The movement view joins sanfs.styl_no to
///    style.shape_style_no, so an item without a style never appears in any movement.
class ItemModel {
  const ItemModel({
    required this.sanfNo,
    required this.partNo,
    required this.name,
    this.sanfCode,
    this.groupNo,
    this.groupName,
    this.typeNo,
    this.typeName,
    this.catNo,
    this.categoryName,
    this.unitNo,
    this.unitName,
    this.salePrice = 0,
    this.buyPrice = 0,
    this.cap = 0,
    this.mainColor,
    this.styleNo,
    this.styleName,
    this.active = true,
    this.subs = 0,
    this.qty = 0,
    this.value = 0,
    this.cost = 0,
  });

  final int sanfNo;
  final String partNo;
  final String name;
  final String? sanfCode;
  final int? groupNo;
  final String? groupName;
  final int? typeNo;
  final String? typeName;
  final int? catNo;
  final String? categoryName;
  final int? unitNo;
  final String? unitName;
  final double salePrice;
  final double buyPrice;
  final double cap;
  final String? mainColor;
  final int? styleNo;
  final String? styleName;
  final bool active;

  /// عدد الأصناف الفرعية — يُعرض كشارة على الصف
  /// Sub-item count, shown as a chip on the row.
  final int subs;
  final double qty;
  final double value;
  final double cost;

  /// هل الصنف برصيد سالب؟ (41 صفاً في القاعدة الحالية)
  /// Is the item under a negative balance? (41 rows in the live data.)
  bool get isNegative => qty < 0;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      sanfNo: JsonValues.asInt(json['SANF_NO'] ?? json['sanf_no']),
      partNo: JsonValues.textOrEmpty(json['PART_NO'] ?? json['part_no']),
      name: JsonValues.arabicOrEmpty(json['SANF_NAME'] ?? json['sanf_name']),
      sanfCode: JsonValues.asText(json['SANF_CODE'] ?? json['sanf_code']),
      groupNo: JsonValues.asIntOrNull(json['GROUPNO'] ?? json['groupno']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeNo: JsonValues.asIntOrNull(json['TYPE_NO'] ?? json['type_no']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      catNo: JsonValues.asIntOrNull(json['CAT_NO'] ?? json['cat_no']),
      categoryName: JsonValues.asArabic(
        json['CATEGORY_NAME'] ?? json['category_name'],
      ),
      unitNo: JsonValues.asIntOrNull(json['UNIT_NO'] ?? json['unit_no']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
      salePrice:
          JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ?? 0,
      buyPrice:
          JsonValues.asDoubleOrNull(json['BUY_PRICE'] ?? json['buy_price']) ?? 0,
      cap: JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0,
      mainColor: JsonValues.asArabic(json['MAIN_COLOR'] ?? json['main_color']),
      styleNo: JsonValues.asIntOrNull(json['STYL_NO'] ?? json['styl_no']),
      styleName: JsonValues.asArabic(json['STYLE_NAME'] ?? json['style_name']),
      active: JsonValues.asFlag(json['ACTIVE'] ?? json['active'], fallback: true),
      subs: JsonValues.asInt(json['SUBS'] ?? json['subs']),
      qty: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      value: JsonValues.asDoubleOrNull(json['VALUE'] ?? json['value']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['COST'] ?? json['cost']) ?? 0,
    );
  }
}

/// الصنف الفرعي — `ACCOUNTS.SANFS_D` (باركود/لون/مقاس)
/// The sub item — ACCOUNTS.SANFS_D (barcode / colour / size).
class ItemSubModel {
  const ItemSubModel({
    required this.sanfDno,
    required this.sanfNo,
    this.partNo,
    this.name,
    this.code,
    this.barcode,
    this.len = 0,
    this.wid = 0,
    this.colorNo = 0,
    this.price = 0,
    this.unitNo,
    this.active = true,
  });

  final int sanfDno;
  final int sanfNo;
  final String? partNo;
  final String? name;
  final String? code;
  final String? barcode;
  final double len;
  final double wid;
  final int colorNo;
  final double price;
  final int? unitNo;
  final bool active;

  /// المقاس بصيغة `الطول×العرض` كما يعرضه النظام القديم
  /// The size as `length×width`, the way the legacy system prints it.
  String get sizeLabel {
    final l = len == 0 ? '0' : _trim(len);
    final w = wid == 0 ? '0' : _trim(wid);

    return '$l×$w';
  }

  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();

    return value.toStringAsFixed(2);
  }

  factory ItemSubModel.fromJson(Map<String, dynamic> json) {
    return ItemSubModel(
      sanfDno: JsonValues.asInt(json['SANF_DNO'] ?? json['sanf_dno']),
      sanfNo: JsonValues.asInt(json['SANF_NO'] ?? json['sanf_no']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      name: JsonValues.asArabic(json['SANF_DNAME'] ?? json['sanf_dname']) ??
          JsonValues.asArabic(json['SANF_NAME'] ?? json['sanf_name']),
      code: JsonValues.asText(json['SANF_COCE'] ?? json['sanf_coce']),
      barcode: JsonValues.asText(json['BARACOCE']),
      len: JsonValues.asDoubleOrNull(json['LEN'] ?? json['len']) ?? 0,
      wid: JsonValues.asDoubleOrNull(json['WID'] ?? json['wid']) ?? 0,
      colorNo: JsonValues.asInt(json['COLOR_NO'] ?? json['color_no']),
      price: JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ?? 0,
      unitNo: JsonValues.asIntOrNull(json['UNIT_NO'] ?? json['unit_no']),
      active: JsonValues.asFlag(json['ACTIVE'] ?? json['active'], fallback: true),
    );
  }
}

/// وحدة الصنف وسعره — `ACCOUNTS.PARTIAL_SANFS`
/// An item unit and its price — ACCOUNTS.PARTIAL_SANFS.
class ItemUnitModel {
  const ItemUnitModel({
    required this.seqNo,
    required this.sanfNo,
    required this.cap,
    required this.price,
    this.unitNo,
    this.unitName,
  });

  final int seqNo;
  final int sanfNo;

  /// معامل التحويل: كم وحدة أساسية في هذه الوحدة
  /// Conversion factor: how many base units this unit holds.
  final double cap;
  final double price;
  final int? unitNo;
  final String? unitName;

  factory ItemUnitModel.fromJson(Map<String, dynamic> json) {
    return ItemUnitModel(
      seqNo: JsonValues.asInt(json['SEQ_NO'] ?? json['seq_no']),
      sanfNo: JsonValues.asInt(json['SANF_NO'] ?? json['sanf_no']),
      cap: JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0,
      price: JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ?? 0,
      unitNo: JsonValues.asIntOrNull(json['UNIT_NO'] ?? json['unit_no']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
    );
  }
}

/// رصيد صنف في مخزن — صف `AVVG` مجمّع
/// An item balance in one store — an aggregated AVVG row.
class ItemBalanceModel {
  const ItemBalanceModel({
    required this.storeNo,
    required this.storeName,
    this.qty = 0,
    this.cost = 0,
    this.value = 0,
  });

  final int storeNo;
  final String storeName;
  final double qty;
  final double cost;
  final double value;

  factory ItemBalanceModel.fromJson(Map<String, dynamic> json) {
    return ItemBalanceModel(
      storeNo: JsonValues.asInt(json['INV_ID'] ?? json['inv_id']),
      storeName: JsonValues.arabicOrEmpty(
        json['INVNAME'] ?? json['invname'] ?? json['INV_NAME'] ?? json['inv_name'],
      ),
      qty: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      cost: JsonValues.asDoubleOrNull(json['COST'] ?? json['cost']) ?? 0,
      value: JsonValues.asDoubleOrNull(json['VALUE'] ?? json['value']) ?? 0,
    );
  }
}
