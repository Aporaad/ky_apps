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

  /// ── الرصيد هنا **مجموع أرصدة فروعه**، وهو تعريف المستخدم للرصيد ومصدره `ITEM_MOVEMENT_D`.
  /// ── The balance here is the sum of its branches — the user's own definition, sourced from
  ///    ITEM_MOVEMENT_D.
  final double qty;
  final double value;
  final double cost;

  /// هل الصنف برصيد سالب؟ (95 صفاً سالباً في القاعدة الحالية)
  /// Is the item under a negative balance? (95 such rows in the live data.)
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
          JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ??
          0,
      buyPrice:
          JsonValues.asDoubleOrNull(json['BUY_PRICE'] ?? json['buy_price']) ??
          0,
      cap: JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0,
      // ── العمود الحقيقي في `ACCOUNTS.SANFS` هو `MCOLOR` (لا `MAIN_COLOR`).
      //    نقرأ الجديد أولاً ونُبقي القديم كاحتياط لخادم أقدم.
      // ── The real column on `ACCOUNTS.SANFS` is `MCOLOR` (not `MAIN_COLOR`).
      //    Read the real one first and keep the old key as a fallback.
      mainColor: JsonValues.asArabic(
        json['MCOLOR'] ??
            json['mcolor'] ??
            json['MAIN_COLOR'] ??
            json['main_color'],
      ),
      styleNo: JsonValues.asIntOrNull(json['STYL_NO'] ?? json['styl_no']),
      styleName: JsonValues.asArabic(json['STYLE_NAME'] ?? json['style_name']),
      active: JsonValues.asFlag(
        json['ACTIVE'] ?? json['active'],
        fallback: true,
      ),
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
    this.unitName,
    this.cap = 0,
    this.category,
    this.colorName,
    this.active = true,
    this.qty = 0,
    this.value = 0,
    this.parentName,
    this.parentPartNo,
    this.groupNo,
    this.typeNo,
    this.groupName,
    this.typeName,
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

  /// اسم الوحدة — بدونه يعرض تفصيل الفرع رقم وحدة غامضاً مثل `3`
  /// The unit name; without it the branch detail shows an opaque unit number like `3`.
  final String? unitName;

  /// عبوة الصنف الفرعي (`SANFS_D.CAP`) — منها تبدأ خانتا «عبوة/قطعة» في السطر
  /// The sub item's pack size, which seeds the line's pack and pieces boxes.
  final double cap;

  /// التصنيف والنص اللوني كما يخزّنهما الصنف الفرعي — عمودان في المستند المطبوع
  /// Classification and colour text carried by the sub item — two document columns.
  final String? category;
  final String? colorName;
  final bool active;

  /// رصيد الفرع وقيمته — من `ITEM_MOVEMENT_D` عبر `P_CODE` لأن `AVVG` لا تعرف الأصناف الفرعية،
  /// وهو نفس المصدر الذي يُبنى منه رصيد الصنف الأب فتتطابق اللائحتان.
  /// The branch's balance and value, from ITEM_MOVEMENT_D via P_CODE — AVVG has no branch
  /// dimension. It is the same source the parent's balance rolls up from, so both lists agree.
  final double qty;
  final double value;

  /// بيانات الصنف الرئيسي الحاضن — لازمة لتبويب «الأصناف الفرعية» الذي يعرض كل الفروع معاً
  /// The hosting main item — needed by the sub-items tab, which lists every branch at once.
  final String? parentName;
  final String? parentPartNo;
  final int? groupNo;
  final int? typeNo;
  final String? groupName;
  final String? typeName;

  /// هل الفرع برصيد سالب؟ يُعرض بلون تحذيري كما في قائمة الأصناف
  /// Is the branch under a negative balance? Shown in the warning colour, like the item list.
  bool get isNegative => qty < 0;

  /// وصف اللون مع بديل نصي: `COLOR_NO = 0` شائع في البيانات فيُعرض النص المخزَّن
  /// The colour label with a text fallback: COLOR_NO = 0 is common, so the stored text is used.
  String get colorLabel {
    final name = colorName?.trim();

    if (name != null && name.isNotEmpty) return name;

    return colorNo == 0 ? '1' : 'لون $colorNo';
  }

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
      name:
          JsonValues.asArabic(json['SANF_DNAME'] ?? json['sanf_dname']) ??
          JsonValues.asArabic(json['SANF_NAME'] ?? json['sanf_name']),
      code: JsonValues.asText(json['SANF_COCE'] ?? json['sanf_coce']),
      barcode: JsonValues.asText(json['BARACOCE'] ?? json['baracoce']),
      len: JsonValues.asDoubleOrNull(json['LEN'] ?? json['len']) ?? 0,
      wid: JsonValues.asDoubleOrNull(json['WID'] ?? json['wid']) ?? 0,
      colorNo: JsonValues.asInt(json['COLOR_NO'] ?? json['color_no']),
      colorName: JsonValues.asArabic(json['COLOR_NAME'] ?? json['color_name']),
      category: JsonValues.asArabic(json['CATEGORY'] ?? json['category']),
      price:
          JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ??
          0,
      unitNo: JsonValues.asIntOrNull(json['UNIT_NO'] ?? json['unit_no']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
      cap: JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0,
      active: JsonValues.asFlag(
        json['ACTIVE'] ?? json['active'],
        fallback: true,
      ),
      qty: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      value: JsonValues.asDoubleOrNull(json['VALUE'] ?? json['value']) ?? 0,
      // `SANFS_D.SANF_NAME` اسم الفرع نفسه، والأب يأتي موسوماً بـ`PARENT_NAME` — قراءته من
      // `SANF_NAME` كان يجعل تفصيل الفرع يعرض اسم أبيه كأنه اسمه
      // SANFS_D.SANF_NAME is the branch's own name and the parent arrives tagged as PARENT_NAME;
      // reading SANF_NAME made the branch detail show its parent's name as its own.
      parentName: JsonValues.asArabic(
        json['PARENT_NAME'] ??
            json['parent_name'] ??
            json['SANF_NAME'] ??
            json['sanf_name'],
      ),
      parentPartNo: JsonValues.asText(
        json['ITEM_PART_NO'] ?? json['item_part_no'],
      ),
      groupNo: JsonValues.asIntOrNull(json['GROUPNO'] ?? json['groupno']),
      typeNo: JsonValues.asIntOrNull(json['TYPE_NO'] ?? json['type_no']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
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
      price:
          JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ??
          0,
      unitNo: JsonValues.asIntOrNull(json['UNIT_NO'] ?? json['unit_no']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
    );
  }
}
