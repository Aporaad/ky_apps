import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج اشتراك مزود — يطابق ACCOUNTS.PROVIDERS_DTL
/// Provider subscription model — mirrors ACCOUNTS.PROVIDERS_DTL.
class ProviderSubscriptionModel {
  final int id;
  final int providerId;
  final int? serviceId;
  final int status;
  final String? userName;
  final String? password;
  final String? url;
  final String? body;
  final String? token;

  const ProviderSubscriptionModel({
    required this.id,
    required this.providerId,
    this.serviceId,
    this.status = 1,
    this.userName,
    this.password,
    this.url,
    this.body,
    this.token,
  });

  bool get isEnabled => status == 1;

  factory ProviderSubscriptionModel.fromJson(Map<String, dynamic> json) {
    // مفاتيح الخادم فعلية بحروف صغيرة snake_case (`provider_id`)؛ UPPER/camelCase احتياط.
    return ProviderSubscriptionModel(
      id: _parseInt(json['ID'] ?? json['id']) ?? 0,
      providerId: _parseInt(json['PROVIDER_ID'] ?? json['provider_id']) ?? 0,
      serviceId: _parseInt(json['SERVICE_ID'] ?? json['service_id']),
      status: _parseInt(json['STATUS'] ?? json['status']) ?? 1,
      userName: _parseString(json['USER_NAME'] ?? json['user_name'], isArabic: false),
      password: _parseString(json['PASSWORD'] ?? json['password'], isArabic: false),
      url: _parseString(json['URL'] ?? json['url'], isArabic: false),
      body: _parseString(json['BODY'] ?? json['body']),
      token: _parseString(json['TOKEN'] ?? json['token'], isArabic: false),
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
