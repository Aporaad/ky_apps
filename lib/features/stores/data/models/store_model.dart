import '../../../../core/utils/json_value_utils.dart';

/// مخزن — صف من جدول `ACCOUNTS.STORES` مع مؤشرات محسوبة من `AVVG`
/// A store — one ACCOUNTS.STORES row plus indicators derived from AVVG.
///
/// `archived` ليس عموداً في القاعدة: الخادم يوسم المخازن 2 · 11 · 12 لأن `ITEM_MOVEMENT_D`
/// تستثنيها من حساب الأرصدة، وإخفاء هذا الوسم يجعل المستخدم يظن أن بضاعة المخزن ضاعت.
/// `archived` is not a column: the server flags stores 2 · 11 · 12 because the movement view
/// excludes them from balances. Hiding the flag would make lost-looking stock unexplainable.
class StoreModel {
  const StoreModel({
    required this.storeNo,
    required this.storeName,
    this.location,
    this.note,
    this.invAccNo,
    this.costAccNo,
    this.discountAccNo,
    this.diffCostAcc,
    this.items = 0,
    this.qty = 0,
    this.value = 0,
    this.keepers = 0,
    this.negative = 0,
    this.archived = false,
  });

  final int storeNo;
  final String storeName;
  final String? location;
  final String? note;
  final int? invAccNo;
  final int? costAccNo;
  final int? discountAccNo;
  final int? diffCostAcc;
  final int items;
  final double qty;
  final double value;
  final int keepers;

  /// عدد صفوف الصنف×مخزن ذات رصيد سالب في هذا المخزن
  /// How many item × store rows sit below zero in this store.
  final int negative;
  final bool archived;

  /// هل يقبل هذا المخزن مستندات جديدة؟ (الأرشيفي لا يقبل)
  /// Can this store receive new documents? (archived stores cannot.)
  bool get acceptsDocuments => !archived;

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      storeNo: JsonValues.asInt(json['STORE_NO'] ?? json['store_no']),
      storeName: JsonValues.arabicOrEmpty(json['STORE_NAME'] ?? json['store_name']),
      location: JsonValues.asArabic(json['LOC'] ?? json['loc']),
      note: JsonValues.asArabic(json['NOTE'] ?? json['note']),
      invAccNo: JsonValues.asIntOrNull(json['INV_ACC_NO'] ?? json['inv_acc_no']),
      costAccNo: JsonValues.asIntOrNull(json['COST_ACC_NO'] ?? json['cost_acc_no']),
      discountAccNo: JsonValues.asIntOrNull(
        json['DISCOUNT_ACC_NO'] ?? json['discount_acc_no'],
      ),
      diffCostAcc: JsonValues.asIntOrNull(
        json['DIFF_COST_ACC'] ?? json['diff_cost_acc'],
      ),
      items: JsonValues.asInt(json['ITEMS'] ?? json['items']),
      qty: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      value: JsonValues.asDoubleOrNull(json['VALUE'] ?? json['value']) ?? 0,
      keepers: JsonValues.asInt(json['KEEPERS'] ?? json['keepers']),
      negative: JsonValues.asInt(json['NEGATIVE'] ?? json['negative']),
      archived: JsonValues.asFlag(json['ARCHIVED'] ?? json['archived']),
    );
  }

  Map<String, dynamic> toJson() => {
    'store_no': storeNo,
    'store_name': storeName,
    'loc': location,
    'note': note,
    'inv_acc_no': invAccNo,
    'cost_acc_no': costAccNo,
    'discount_acc_no': discountAccNo,
    'diff_cost_acc': diffCostAcc,
  };
}

/// أمين مخزن — `ACCOUNTS.STORE_EMP` (المفتاح `EMP_NO` والفريد `EMP_NAME`)
/// A store keeper — ACCOUNTS.STORE_EMP (primary key EMP_NO, unique EMP_NAME).
class StoreKeeperModel {
  const StoreKeeperModel({
    required this.empNo,
    required this.empName,
    required this.storeNo,
    this.storeName,
  });

  final int empNo;
  final String empName;
  final int storeNo;
  final String? storeName;

  factory StoreKeeperModel.fromJson(Map<String, dynamic> json) {
    return StoreKeeperModel(
      empNo: JsonValues.asInt(json['EMP_NO'] ?? json['emp_no']),
      empName: JsonValues.arabicOrEmpty(json['EMP_NAME'] ?? json['emp_name']),
      storeNo: JsonValues.asInt(json['STORE_NO'] ?? json['store_no']),
      storeName: JsonValues.asArabic(json['STORE_NAME'] ?? json['store_name']),
    );
  }
}
