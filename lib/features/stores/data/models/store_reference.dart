import '../../../../core/utils/json_value_utils.dart';
import 'store_model.dart';

/// النمط/الطراز — `ACCOUNTS.STYLE` (`SHAPE_STYLE_NO`)
/// The style — ACCOUNTS.STYLE (SHAPE_STYLE_NO).
///
/// ──النمط ليس ترفاً: `ITEM_MOVEMENT_D` تجمع `sanfs.styl_no` بـ`sanfs.styl_no`،
///   وصنف بلا نمط لا ينتمي إلى أي صف حركة ولا رصيد.
class StoreStyleModel {
  const StoreStyleModel({
    required this.id,
    required this.name,
    this.code,
    this.groupNo,
    this.typeNo,
  });

  final int id;
  final String name;
  final String? code;
  final int? groupNo;
  final int? typeNo;

  factory StoreStyleModel.fromJson(Map<String, dynamic> json) {
    return StoreStyleModel(
      id: JsonValues.asInt(json['ID'] ?? json['id']),
      name: JsonValues.arabicOrEmpty(json['NAME'] ?? json['name']),
      code: JsonValues.asText(json['CODE'] ?? json['code']),
      groupNo: JsonValues.asIntOrNull(json['GROUP_NO'] ?? json['group_no']),
      typeNo: JsonValues.asIntOrNull(json['TYPE_NO'] ?? json['type_no']),
    );
  }
}

/// مجموعة رئيسية — `ACCOUNTS.GROUP1`
/// A main group — ACCOUNTS.GROUP1.
class StoreGroupModel {
  const StoreGroupModel({
    required this.groupNo,
    required this.groupName,
    this.types = 0,
    this.items = 0,
    this.active = true,
  });

  final int groupNo;
  final String groupName;
  final int types;
  final int items;
  final bool active;

  factory StoreGroupModel.fromJson(Map<String, dynamic> json) {
    return StoreGroupModel(
      groupNo: JsonValues.asInt(json['GROUP_NO'] ?? json['ID'] ?? json['id']),
      groupName: JsonValues.arabicOrEmpty(
        json['GROUP_NAME'] ?? json['NAME'] ?? json['name'],
      ),
      types: JsonValues.asInt(json['TYPES'] ?? json['types']),
      items: JsonValues.asInt(json['ITEMS'] ?? json['items']),
      active: JsonValues.asFlag(json['ACTIVE'] ?? json['active'], fallback: true),
    );
  }
}

/// مجموعة فرعية (نوع) — `ACCOUNTS.TYPES`
/// A sub group (type) — ACCOUNTS.TYPES.
class StoreTypeModel {
  const StoreTypeModel({
    required this.typeNo,
    required this.typeName,
    required this.groupNo,
    this.groupName,
    this.items = 0,
  });

  final int typeNo;
  final String typeName;
  final int groupNo;
  final String? groupName;
  final int items;

  factory StoreTypeModel.fromJson(Map<String, dynamic> json) {
    return StoreTypeModel(
      typeNo: JsonValues.asInt(json['TYPE_NO'] ?? json['ID'] ?? json['id']),
      typeName: JsonValues.arabicOrEmpty(
        json['TYPE_NAME'] ?? json['NAME'] ?? json['name'],
      ),
      groupNo: JsonValues.asInt(json['GROUP_NO'] ?? json['group_no']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      items: JsonValues.asInt(json['ITEMS'] ?? json['items']),
    );
  }
}

/// الفئة (بلد المنشأ) — `ACCOUNTS.CATEGORY`
/// The category (country of origin) — ACCOUNTS.CATEGORY.
class StoreCategoryModel {
  const StoreCategoryModel({
    required this.id,
    required this.name,
    this.catNo,
    this.items = 0,
  });

  /// `SEQ` هو المفتاح الرئيسي، و`CAT_NO` هو الرقم الذي تحمله الأصناف
  /// SEQ is the primary key while CAT_NO is the number items carry.
  final int id;
  final String name;
  final int? catNo;
  final int items;

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) {
    return StoreCategoryModel(
      id: JsonValues.asInt(json['ID'] ?? json['id'] ?? json['SEQ'] ?? json['seq']),
      name: JsonValues.arabicOrEmpty(
        json['NAME'] ?? json['name'] ?? json['CATEGORY'] ?? json['category'],
      ),
      catNo: JsonValues.asIntOrNull(json['CAT_NO'] ?? json['cat_no']),
      items: JsonValues.asInt(json['ITEMS'] ?? json['items']),
    );
  }
}

/// الوحدة — `ACCOUNTS.UNITS`
/// A unit of measure — ACCOUNTS.UNITS.
class StoreUnitModel {
  const StoreUnitModel({
    required this.unitNo,
    required this.unitName,
    this.items = 0,
  });

  final int unitNo;
  final String unitName;
  final int items;

  factory StoreUnitModel.fromJson(Map<String, dynamic> json) {
    return StoreUnitModel(
      unitNo: JsonValues.asInt(json['UNIT_NO'] ?? json['ID'] ?? json['id']),
      unitName: JsonValues.arabicOrEmpty(
        json['UNIT_NAME'] ?? json['NAME'] ?? json['name'],
      ),
      items: JsonValues.asInt(json['ITEMS'] ?? json['items']),
    );
  }
}

/// نوع حركة مخزنية — `ACCOUNTS.TRANS_TYPE`
/// A stock movement type — ACCOUNTS.TRANS_TYPE.
class StoreMovementTypeModel {
  const StoreMovementTypeModel({
    required this.typeNo,
    required this.typeName,
    this.inout = 0,
  });

  final int typeNo;
  final String typeName;

  /// 1 وارد · -1 صادر
  /// 1 inbound · -1 outbound.
  final int inout;

  bool get isInbound => inout > 0;

  factory StoreMovementTypeModel.fromJson(Map<String, dynamic> json) {
    return StoreMovementTypeModel(
      typeNo: JsonValues.asInt(json['TYPE_NO'] ?? json['type_no']),
      typeName: JsonValues.arabicOrEmpty(json['TYPE_NAME'] ?? json['type_name']),
      inout: JsonValues.asInt(json['INOUT'] ?? json['inout']),
    );
  }
}

/// حزمة المراجع التي تُغذّي كل نوافذ التصفية في القسم — طلب واحد
/// The reference bundle behind every filter sheet in the module — one round-trip.
class StoreReference {
  const StoreReference({
    this.stores = const [],
    this.groups = const [],
    this.types = const [],
    this.categories = const [],
    this.units = const [],
    this.movementTypes = const [],
    this.styles = const [],
    this.excludedStores = const [],
    this.maxRangeDays = 731,
  });

  final List<StoreModel> stores;
  final List<StoreGroupModel> groups;
  final List<StoreTypeModel> types;
  final List<StoreCategoryModel> categories;
  final List<StoreUnitModel> units;
  final List<StoreMovementTypeModel> movementTypes;
  final List<StoreStyleModel> styles;

  /// المخازن الأرشيفية التي لا تدخل في الأرصدة
  /// Archived stores that never carry a balance.
  final List<int> excludedStores;
  final int maxRangeDays;

  /// المخازن التي تقبل مستندات جديدة
  /// The stores that accept new documents.
  List<StoreModel> get usableStores =>
      stores.where((store) => store.acceptsDocuments).toList(growable: false);

  StoreModel? storeById(int? storeNo) {
    if (storeNo == null) return null;

    for (final store in stores) {
      if (store.storeNo == storeNo) return store;
    }

    return null;
  }

  /// المجموعات الفرعية التابعة لمجموعة رئيسية
  /// The sub groups of one main group.
  List<StoreTypeModel> typesOfGroup(int? groupNo) {
    if (groupNo == null) return types;

    return types.where((type) => type.groupNo == groupNo).toList(growable: false);
  }

  /// الأنماط التابعة لمجموعة فرعية
  /// The styles of one sub group.
  List<StoreStyleModel> stylesOfType(int? typeNo) {
    if (typeNo == null) return styles;

    return styles.where((style) => style.typeNo == typeNo).toList(growable: false);
  }

  factory StoreReference.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = json[key];

      if (raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false);
    }

    return StoreReference(
      stores: list('stores', StoreModel.fromJson),
      groups: list('groups', StoreGroupModel.fromJson),
      types: list('types', StoreTypeModel.fromJson),
      categories: list('categories', StoreCategoryModel.fromJson),
      units: list('units', StoreUnitModel.fromJson),
      movementTypes: list('movement_types', StoreMovementTypeModel.fromJson),
      styles: list('styles', StoreStyleModel.fromJson),
      excludedStores: JsonValues.asIntList(json['excluded_stores']),
      maxRangeDays: JsonValues.asInt(json['max_range_days'], fallback: 731),
    );
  }
}
