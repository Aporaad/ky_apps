import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

/// عميل Dio المركزي الموحد لإدارة جميع طلبات الشبكة
/// Centralized Dio client for managing network requests
class DioClient {
  late final Dio dio;
  final SecureStorageService storage;
  final void Function()? onUnauthorized;

  DioClient({required this.storage, this.onUnauthorized, String? baseUrl}) {
    final initialUrl = (baseUrl != null && baseUrl.isNotEmpty)
        ? baseUrl
        : ApiConstants.defaultBaseUrl;

    dio = Dio(
      BaseOptions(
        baseUrl: initialUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage),
      ErrorInterceptor(storage, onUnauthorized: onUnauthorized),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ),
    ]);
  }

  /// الحصول على الرابط الأساسي الحالي
  String get baseUrl => dio.options.baseUrl;

  /// تحديث رابط الخادم فورياً في الـ Dio
  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl.trim();
  }

  /// تهيئة الرابط الأساسي من الذاكرة المشفرة إذا كان موجوداً
  Future<void> initializeBaseUrl() async {
    final savedUrl = await storage.getApiBaseUrl();
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      dio.options.baseUrl = savedUrl.trim();
    }
  }
}
