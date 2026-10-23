import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج المزود — يطابق جدول ACCOUNTS.PROVIDERS
/// Provider model — mirrors the Oracle ACCOUNTS.PROVIDERS table.
///
/// الاعتبارات (userName/password) تصل مقنّعة `***` إلا لمن يملك صلاحية الكشف؛ النموذج يخزّنها كما
/// جاءت دون افتراض أنها صالحة للكتابة.
/// Credentials arrive masked `***` unless the reveal permission is held; the model stores whatever
/// the server sent without assuming it is write-ready.
class ProviderModel {
  final int providerId;
  final String providerName;
  final int status;
  final String? userName;
  final String? password;
  final String? url;
  final String? type;
  final String? createdAt;
  final String? updatedAt;

  const ProviderModel({
    required this.providerId,
    required this.providerName,
    this.status = 1,
    this.userName,
    this.password,
    this.url,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  bool get isEnabled => status == 1;

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    // الخادم (yajra-oci8) يُرجع أسماء الأعمدة بحروف صغيرة snake_case (`provider_id`)،
    // تمامًا كما في بقية الموديلات (CustomerModel). نُبقي UPPER كاحتياط.
    return ProviderModel(
      providerId: _parseInt(json['PROVIDER_ID'] ?? json['provider_id']) ?? 0,
      providerName: ArabicEncodingUtils.fix(
        json['PROVIDER_NAME'] ?? json['provider_name'],
      ),
      status: _parseInt(json['STATUS'] ?? json['status']) ?? 1,
      userName: _parseString(json['USER_NAME'] ?? json['user_name'], isArabic: false),
      password: _parseString(json['PASSWORD'] ?? json['password'], isArabic: false),
      url: _parseString(json['URL'] ?? json['url'], isArabic: false),
      type: _parseString(json['TYPE'] ?? json['type']),
      createdAt: _parseString(json['CREATED_AT'] ?? json['created_at'], isArabic: false),
      updatedAt: _parseString(json['UPDATED_AT'] ?? json['updated_at'], isArabic: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'PROVIDER_ID': providerId,
        'PROVIDER_NAME': providerName,
        'STATUS': status,
        'USER_NAME': userName,
        'PASSWORD': password,
        'URL': url,
        'TYPE': type,
      };

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
