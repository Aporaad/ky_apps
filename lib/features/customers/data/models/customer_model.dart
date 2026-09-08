import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج بيانات العميل مع دعم كامل لبيانات جدول CUST في أوراكل
/// Customer data model mapped to Oracle CUST table
class CustomerModel {
  final int custNo;
  final String custName;
  final String? addr;
  final String? tel1;
  final String? tel2;
  final String? postbox;
  final String? email;
  final String? fax;
  final int? accNo;
  final int? accno;
  final double? limitedBalance;
  final String? preCustName;
  final int? stoppingCust;

  const CustomerModel({
    required this.custNo,
    required this.custName,
    this.addr,
    this.tel1,
    this.tel2,
    this.postbox,
    this.email,
    this.fax,
    this.accNo,
    this.accno,
    this.limitedBalance,
    this.preCustName,
    this.stoppingCust,
  });

  /// هل العميل موقوف؟
  bool get isStopped => (stoppingCust ?? 0) != 0;

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      custNo: _parseInt(json['CUST_NO'] ?? json['cust_no']) ?? 0,
      custName: ArabicEncodingUtils.fix(json['CUST_NAME'] ?? json['cust_name']),
      addr: _parseString(json['ADDR'] ?? json['addr']),
      tel1: _parseString(json['TEL1'] ?? json['tel1'], isArabic: false),
      tel2: _parseString(json['TEL2'] ?? json['tel2'], isArabic: false),
      postbox: _parseString(json['POSTBOX'] ?? json['postbox'], isArabic: false),
      email: _parseString(json['EMAIL'] ?? json['email'], isArabic: false),
      fax: _parseString(json['FAX'] ?? json['fax'], isArabic: false),
      accNo: _parseInt(json['ACC_NO'] ?? json['acc_no']),
      accno: _parseInt(json['ACCNO'] ?? json['accno']),
      limitedBalance: _parseDouble(json['LIMITED_BALANCE'] ?? json['limited_balance']),
      preCustName: _parseString(json['PRE_CUST_NAME'] ?? json['pre_cust_name']),
      stoppingCust: _parseInt(json['STOPPING_CUST'] ?? json['stopping_cust']),
    );
  }

  Map<String, dynamic> toJson() => {
        'CUST_NO': custNo,
        'CUST_NAME': custName,
        'ADDR': addr,
        'TEL1': tel1,
        'TEL2': tel2,
        'POSTBOX': postbox,
        'EMAIL': email,
        'FAX': fax,
        'ACC_NO': accNo,
        'LIMITED_BALANCE': limitedBalance,
        'PRE_CUST_NAME': preCustName,
        'STOPPING_CUST': stoppingCust,
      };

  CustomerModel copyWith({
    int? custNo,
    String? custName,
    String? addr,
    String? tel1,
    String? tel2,
    String? postbox,
    String? email,
    String? fax,
    int? accNo,
    int? accno,
    double? limitedBalance,
    String? preCustName,
    int? stoppingCust,
  }) {
    return CustomerModel(
      custNo: custNo ?? this.custNo,
      custName: custName ?? this.custName,
      addr: addr ?? this.addr,
      tel1: tel1 ?? this.tel1,
      tel2: tel2 ?? this.tel2,
      postbox: postbox ?? this.postbox,
      email: email ?? this.email,
      fax: fax ?? this.fax,
      accNo: accNo ?? this.accNo,
      accno: accno ?? this.accno,
      limitedBalance: limitedBalance ?? this.limitedBalance,
      preCustName: preCustName ?? this.preCustName,
      stoppingCust: stoppingCust ?? this.stoppingCust,
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
