import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// نماذج بيانات العملات وأسعار الصرف
// CURRENCY + CUR_CODE + CUR_PRICE
// ================================================================

/// نموذج العملة الكاملة (CURRENCY + CUR_CODE + آخر سعر)
class CurrencyModel {
  final int curNo;
  final String curName;
  final String? code;
  final String? mainCurName;
  final String? subCurName;
  final double currentPrice;
  final double previousPrice;
  final double changePercent;
  final String? lastDate;

  const CurrencyModel({
    required this.curNo,
    required this.curName,
    this.code,
    this.mainCurName,
    this.subCurName,
    this.currentPrice = 0,
    this.previousPrice = 0,
    this.changePercent = 0,
    this.lastDate,
  });

  bool get isRising => changePercent > 0;
  bool get isFalling => changePercent < 0;

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
        curNo: _parseInt(json['cur_no']) ?? 0,
        curName: ArabicEncodingUtils.fix(json['cur_name']),
        code: json['code']?.toString(),
        mainCurName: ArabicEncodingUtils.fix(json['main_cur_name']),
        subCurName: ArabicEncodingUtils.fix(json['sub_cur_name']),
        currentPrice: _parseDouble(json['current_price']) ?? 0,
        previousPrice: _parseDouble(json['previous_price']) ?? 0,
        changePercent: _parseDouble(json['change_percent']) ?? 0,
        lastDate: json['last_date']?.toString(),
      );

  Map<String, dynamic> toJsonForCreate() => {
        'cur_name': curName,
        'code': code,
        'main_cur_name': mainCurName,
        'sub_cur_name': subCurName,
      };

  Map<String, dynamic> toJsonForUpdate() => {
        if (curName.isNotEmpty) 'cur_name': curName,
        if (code != null) 'code': code,
        if (mainCurName != null) 'main_cur_name': mainCurName,
        if (subCurName != null) 'sub_cur_name': subCurName,
      };

  CurrencyModel copyWith({
    int? curNo,
    String? curName,
    String? code,
    String? mainCurName,
    String? subCurName,
    double? currentPrice,
    double? previousPrice,
    double? changePercent,
    String? lastDate,
  }) =>
      CurrencyModel(
        curNo: curNo ?? this.curNo,
        curName: curName ?? this.curName,
        code: code ?? this.code,
        mainCurName: mainCurName ?? this.mainCurName,
        subCurName: subCurName ?? this.subCurName,
        currentPrice: currentPrice ?? this.currentPrice,
        previousPrice: previousPrice ?? this.previousPrice,
        changePercent: changePercent ?? this.changePercent,
        lastDate: lastDate ?? this.lastDate,
      );
}

/// نموذج سعر الصرف (CUR_PRICE)
class CurrencyPriceModel {
  final int seq;
  final int curNo;
  final double price;
  final String dayDate;

  const CurrencyPriceModel({
    required this.seq,
    required this.curNo,
    required this.price,
    required this.dayDate,
  });

  factory CurrencyPriceModel.fromJson(Map<String, dynamic> json) =>
      CurrencyPriceModel(
        seq: _parseInt(json['seq']) ?? 0,
        curNo: _parseInt(json['cur_no']) ?? 0,
        price: _parseDouble(json['price']) ?? 0,
        dayDate: json['day_date']?.toString() ?? '',
      );
}

// ======================== Helper Parsers ========================

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
