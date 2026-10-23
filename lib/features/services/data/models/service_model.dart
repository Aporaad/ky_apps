import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج الخدمة — قاموس ACCOUNTS.SERVICES
/// Service dictionary model — ACCOUNTS.SERVICES.
class ServiceModel {
  final int serviceId;
  final String serviceName;
  final String? serviceType;
  final String? createdAt;

  const ServiceModel({
    required this.serviceId,
    required this.serviceName,
    this.serviceType,
    this.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // SERVICES عبر yajra يعود بحروف صغيرة snake_case (`service_id`, `service_name`).
    return ServiceModel(
      serviceId: _parseInt(json['SERVICE_ID'] ?? json['service_id']) ?? 0,
      serviceName: ArabicEncodingUtils.fix(
        json['SERVICE_NAME'] ?? json['service_name'],
      ),
      serviceType: _parseString(json['SERVICE_TYPE'] ?? json['service_type']),
      createdAt: _parseString(json['CREATED_AT'] ?? json['created_at'], isArabic: false),
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
