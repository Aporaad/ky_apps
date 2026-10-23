import 'package:dio/dio.dart';

/// نتيجة عملية كتابة موحّدة لطبقة الخدمات
/// Unified write-result for the services layer.
class ServiceResult {
  final bool success;
  final String message;
  final dynamic data;

  const ServiceResult({required this.success, required this.message, this.data});
}

/// استخراج رسالة خطأ ثنائية اللغة من استجابة Dio
/// Extract the bilingual error message from a Dio response.
String dioErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  return e.message ?? 'خطأ في الشبكة / Network error';
}
