import '../../../../core/utils/arabic_encoding_utils.dart';

/// نوع العامل
enum WorkerType { employee, cutter, tailor }

extension WorkerTypeExtension on WorkerType {
  String get label {
    switch (this) {
      case WorkerType.employee:
        return 'موظف';
      case WorkerType.cutter:
        return 'قصاص';
      case WorkerType.tailor:
        return 'خياط';
    }
  }

  String get apiPath {
    switch (this) {
      case WorkerType.employee:
        return 'employees';
      case WorkerType.cutter:
        return 'cutters';
      case WorkerType.tailor:
        return 'tailors';
    }
  }
}

/// نموذج بيانات العامل - يدعم الموظفين والقصاصين والخياطين
class WorkerModel {
  final int id;
  final String name;
  final String? phone1;
  final String? phone2;
  final String? email;
  final String? status;
  final String? notes;
  final int? accNo;
  final int? curNo;
  final WorkerType type;

  // حقول خاصة بالموظفين فقط
  final String? jobType;
  final String? empClass;
  final String? wagesType;
  final double? salary;
  final double? piecePrice;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.type,
    this.phone1,
    this.phone2,
    this.email,
    this.status,
    this.notes,
    this.accNo,
    this.curNo,
    this.jobType,
    this.empClass,
    this.wagesType,
    this.salary,
    this.piecePrice,
  });

  /// هل العامل معطل؟
  bool get isDisabled {
    if (status == null || status!.isEmpty) return false;
    return status!.contains('معطل') || status!.contains('موقوف');
  }

  /// إنشاء نموذج موظف من JSON
  factory WorkerModel.fromEmployeeJson(Map<String, dynamic> json) {
    return WorkerModel(
      type: WorkerType.employee,
      id: _parseInt(json['EMP_NO'] ?? json['emp_no']) ?? 0,
      name: ArabicEncodingUtils.fix(json['EMP_NAME'] ?? json['emp_name']),
      phone1: _parseString(json['EMP_PHONE1'] ?? json['emp_phone1'], isArabic: false),
      phone2: _parseString(json['EMP_PHONE2'] ?? json['emp_phone2'], isArabic: false),
      email: _parseString(json['EMP_EMAIL'] ?? json['emp_email'], isArabic: false),
      status: _parseString(json['EMP_STATUS'] ?? json['emp_status']),
      notes: _parseString(json['NOTES1'] ?? json['notes1']),
      accNo: _parseInt(json['ACC_NO'] ?? json['acc_no']),
      curNo: _parseInt(json['CUR_NO'] ?? json['cur_no']),
      jobType: _parseString(json['JOP_TYPE'] ?? json['jop_type']),
      empClass: _parseString(json['EMP_CLASS'] ?? json['emp_class']),
      wagesType: _parseString(json['WAGES_TYPE'] ?? json['wages_type']),
      salary: _parseDouble(json['SALARY'] ?? json['salary']),
      piecePrice: _parseDouble(json['PIECE_PRICE'] ?? json['piece_price']),
    );
  }

  /// إنشاء نموذج قصاص من JSON
  factory WorkerModel.fromCutterJson(Map<String, dynamic> json) {
    return WorkerModel(
      type: WorkerType.cutter,
      id: _parseInt(json['CUTTER_NO'] ?? json['cutter_no']) ?? 0,
      name: ArabicEncodingUtils.fix(json['CUTTER_NAME'] ?? json['cutter_name']),
      phone1: _parseString(json['CUTTER_PHONE1'] ?? json['cutter_phone1'], isArabic: false),
      phone2: _parseString(json['CUTTER_PHONE2'] ?? json['cutter_phone2'], isArabic: false),
      email: _parseString(json['CUTTER_EMAIL'] ?? json['cutter_email'], isArabic: false),
      status: _parseString(json['CUTTER_STATUS'] ?? json['cutter_status']),
      notes: _parseString(json['NOTES1'] ?? json['notes1']),
      accNo: _parseInt(json['ACC_NO'] ?? json['acc_no']),
      curNo: _parseInt(json['CUR_NO'] ?? json['cur_no']),
    );
  }

  /// إنشاء نموذج خياط من JSON
  factory WorkerModel.fromTailorJson(Map<String, dynamic> json) {
    return WorkerModel(
      type: WorkerType.tailor,
      id: _parseInt(json['TAILOR_NO'] ?? json['tailor_no']) ?? 0,
      name: ArabicEncodingUtils.fix(json['TAILOR_NAME'] ?? json['tailor_name']),
      phone1: _parseString(json['TAILOR_PHONE1'] ?? json['tailor_phone1'], isArabic: false),
      phone2: _parseString(json['TAILOR_PHONE2'] ?? json['tailor_phone2'], isArabic: false),
      email: _parseString(json['TAILOR_EMAIL'] ?? json['tailor_email'], isArabic: false),
      status: _parseString(json['TAILOR_STATUS'] ?? json['tailor_status']),
      notes: _parseString(json['NOTES1'] ?? json['notes1']),
      accNo: _parseInt(json['ACC_NO'] ?? json['acc_no']),
      curNo: _parseInt(json['CUR_NO'] ?? json['cur_no']),
    );
  }

  Map<String, dynamic> toJsonForApi() {
    switch (type) {
      case WorkerType.employee:
        return {
          'EMP_NAME': name,
          if (phone1 != null) 'EMP_PHONE1': phone1,
          if (phone2 != null) 'EMP_PHONE2': phone2,
          if (email != null) 'EMP_EMAIL': email,
          if (status != null) 'EMP_STATUS': status,
          if (notes != null) 'NOTES1': notes,
          if (accNo != null) 'ACC_NO': accNo,
          if (jobType != null) 'JOP_TYPE': jobType,
          if (empClass != null) 'EMP_CLASS': empClass,
          if (wagesType != null) 'WAGES_TYPE': wagesType,
          if (salary != null) 'SALARY': salary,
          if (piecePrice != null) 'PIECE_PRICE': piecePrice,
        };
      case WorkerType.cutter:
        return {
          'CUTTER_NAME': name,
          if (phone1 != null) 'CUTTER_PHONE1': phone1,
          if (phone2 != null) 'CUTTER_PHONE2': phone2,
          if (email != null) 'CUTTER_EMAIL': email,
          if (status != null) 'CUTTER_STATUS': status,
          if (notes != null) 'NOTES1': notes,
          if (accNo != null) 'ACC_NO': accNo,
        };
      case WorkerType.tailor:
        return {
          'TAILOR_NAME': name,
          if (phone1 != null) 'TAILOR_PHONE1': phone1,
          if (phone2 != null) 'TAILOR_PHONE2': phone2,
          if (email != null) 'TAILOR_EMAIL': email,
          if (status != null) 'TAILOR_STATUS': status,
          if (notes != null) 'NOTES1': notes,
          if (accNo != null) 'ACC_NO': accNo,
        };
    }
  }

  WorkerModel copyWith({
    int? id,
    String? name,
    String? phone1,
    String? phone2,
    String? email,
    String? status,
    String? notes,
    int? accNo,
    int? curNo,
    WorkerType? type,
    String? jobType,
    String? empClass,
    String? wagesType,
    double? salary,
    double? piecePrice,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      accNo: accNo ?? this.accNo,
      curNo: curNo ?? this.curNo,
      type: type ?? this.type,
      jobType: jobType ?? this.jobType,
      empClass: empClass ?? this.empClass,
      wagesType: wagesType ?? this.wagesType,
      salary: salary ?? this.salary,
      piecePrice: piecePrice ?? this.piecePrice,
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
