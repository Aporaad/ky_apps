import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج سطر كشف حساب العميل - مرتبط باستعلام الـ Entry_Sub
/// Customer account statement line model
class CustomerStatementModel {
  final String? entryNo;
  final String? subEntryNo;
  final String? entryDate;
  final String? entryTypeName;
  final String? details;
  final double? balanceS;
  final double? entryMnt;
  final double? debit;
  final double? credit;
  final String? custName;
  final int? custNo;
  final int? custAccNo;
  final int? subAccNo;

  const CustomerStatementModel({
    this.entryNo,
    this.subEntryNo,
    this.entryDate,
    this.entryTypeName,
    this.details,
    this.balanceS,
    this.entryMnt,
    this.debit,
    this.credit,
    this.custName,
    this.custNo,
    this.custAccNo,
    this.subAccNo,
  });

  factory CustomerStatementModel.fromJson(Map<String, dynamic> json) {
    final entryMntVal = _parseDouble(json['ENTRY_MNT'] ?? json['entry_mnt']);
    final debitVal = _parseDouble(json['DEBIT'] ?? json['debit']) ??
        (entryMntVal != null && entryMntVal > 0 ? entryMntVal : 0.0);
    final creditVal = _parseDouble(json['CREDIT'] ?? json['credit']) ??
        (entryMntVal != null && entryMntVal < 0 ? entryMntVal.abs() : 0.0);

    return CustomerStatementModel(
      entryNo: _parseString(json['ENTRY_NO'] ?? json['entry_no'], isArabic: false),
      subEntryNo: _parseString(json['SUB_ENTRY_NO'] ?? json['sub_entry_no'], isArabic: false),
      entryDate: _parseString(json['ENTRY_DATE'] ?? json['entry_date'], isArabic: false),
      entryTypeName: _parseString(json['ENTRY_TYPE_NAME'] ?? json['entry_type_name']),
      details: _parseString(json['DETAILS'] ?? json['details']),
      balanceS: _parseDouble(json['BALANCE_S'] ?? json['balance_s']),
      entryMnt: entryMntVal,
      debit: debitVal,
      credit: creditVal,
      custName: _parseString(json['CUST_NAME'] ?? json['cust_name']),
      custNo: _parseInt(json['CUST_NO'] ?? json['cust_no']),
      custAccNo: _parseInt(json['ACC_NO'] ?? json['acc_no']),
      subAccNo: _parseInt(json['ENTRY_SUB_ACC_NO'] ?? json['entry_sub_acc_no']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? _parseString(dynamic v, {bool isArabic = true}) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return isArabic ? ArabicEncodingUtils.fix(s) : s;
  }
}
