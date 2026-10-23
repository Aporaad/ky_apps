import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج إعدادات الشركة — singleton جدول ACCOUNTS.CORP (بلا مفتاح)
/// Corporate settings model — the keyless ACCOUNTS.CORP singleton.
class CorpModel {
  final String? corpName;
  final String? corpAddr;
  final String? corpTel1;
  final String? corpTel2;
  final int? sanfType;
  final String? filePath;

  const CorpModel({
    this.corpName,
    this.corpAddr,
    this.corpTel1,
    this.corpTel2,
    this.sanfType,
    this.filePath,
  });

  factory CorpModel.fromJson(Map<String, dynamic> json) {
    // CORP عبر yajra يعود بحروف صغيرة snake_case (`corp_name`).
    return CorpModel(
      corpName: _parseString(json['CORP_NAME'] ?? json['corp_name']),
      corpAddr: _parseString(json['CORP_ADDR'] ?? json['corp_addr']),
      corpTel1: _parseString(json['CORP_TEL1'] ?? json['corp_tel1'], isArabic: false),
      corpTel2: _parseString(json['CORP_TEL2'] ?? json['corp_tel2'], isArabic: false),
      sanfType: _parseInt(json['SANF_TYPE'] ?? json['sanf_type']),
      filePath: _parseString(json['FILE_PATH'] ?? json['file_path'], isArabic: false),
    );
  }

  /// نسخة قابلة للترسل إلى الخادم بمفاتيح الطلبsnake_case
  /// Serializable payload using the request's snake_case keys.
  Map<String, dynamic> toPayload() => {
        'corp_name': corpName,
        'corp_addr': corpAddr,
        'corp_tel1': corpTel1,
        'corp_tel2': corpTel2,
        'sanf_type': sanfType,
        'file_path': filePath,
      };

  CorpModel copyWith({
    String? corpName,
    String? corpAddr,
    String? corpTel1,
    String? corpTel2,
    int? sanfType,
    String? filePath,
  }) {
    return CorpModel(
      corpName: corpName ?? this.corpName,
      corpAddr: corpAddr ?? this.corpAddr,
      corpTel1: corpTel1 ?? this.corpTel1,
      corpTel2: corpTel2 ?? this.corpTel2,
      sanfType: sanfType ?? this.sanfType,
      filePath: filePath ?? this.filePath,
    );
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
