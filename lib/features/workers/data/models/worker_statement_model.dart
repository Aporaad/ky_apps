import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج بيانات كشف الحساب للعمال
class WorkerStatementModel {
  final String? entryNo;
  final String? subEntryNo;
  final String? entryDate;
  final String? entryTypeName;
  final String? details;
  final double balanceS;
  final double entryMnt;
  final double debit;
  final double credit;
  final int? accNo;

  const WorkerStatementModel({
    this.entryNo,
    this.subEntryNo,
    this.entryDate,
    this.entryTypeName,
    this.details,
    required this.balanceS,
    required this.entryMnt,
    required this.debit,
    required this.credit,
    this.accNo,
  });

  factory WorkerStatementModel.fromJson(Map<String, dynamic> json) {
    return WorkerStatementModel(
      entryNo: _parseString(json['entry_no'] ?? json['ENTRY_NO'], isArabic: false),
      subEntryNo: _parseString(json['sub_entry_no'] ?? json['SUB_ENTRY_NO'], isArabic: false),
      entryDate: _parseString(json['entry_date'] ?? json['ENTRY_DATE'], isArabic: false),
      entryTypeName: ArabicEncodingUtils.fix(json['entry_type_name'] ?? json['ENTRY_TYPE_NAME']),
      details: ArabicEncodingUtils.fix(json['details'] ?? json['DETAILS']),
      balanceS: _parseDouble(json['balance_s'] ?? json['BALANCE_S']),
      entryMnt: _parseDouble(json['entry_mnt'] ?? json['ENTRY_MNT']),
      debit: _parseDouble(json['debit'] ?? json['DEBIT']),
      credit: _parseDouble(json['credit'] ?? json['CREDIT']),
      accNo: _parseInt(json['acc_no'] ?? json['ACC_NO']),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String? _parseString(dynamic v, {bool isArabic = true}) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return isArabic ? ArabicEncodingUtils.fix(s) : s;
  }
}
