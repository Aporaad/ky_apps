import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// معالج وسيط مركزي للتعامل مع أخطاء الـ API (مثل 401 Unauthorized)
/// Centralized interceptor for API errors like 401 Unauthorized
class ErrorInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final void Function()? onUnauthorized;

  ErrorInterceptor(this._storage, {this.onUnauthorized});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // حذف التوكن المنتهي الصلاحية وتسجيل الخروج التلقائي
      await _storage.clearAll();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
