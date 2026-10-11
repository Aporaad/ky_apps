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
    // 1. معالجة طلبات الإلغاء بسلاسة (DioExceptionType.cancel) دون رمي استثناءات غير متوقعة للمنقح
    if (err.type == DioExceptionType.cancel) {
      return handler.resolve(
        Response(
          requestOptions: err.requestOptions,
          data: const <String, dynamic>{
            'success': false,
            'cancelled': true,
            'data': <dynamic>[],
            'meta': <String, dynamic>{},
          },
          statusCode: 200,
        ),
      );
    }

    // 2. معالجة انتهاء الجلسة 401
    if (err.response?.statusCode == 401) {
      // حذف التوكن المنتهي الصلاحية وتسجيل الخروج التلقائي
      await _storage.clearAll();
      onUnauthorized?.call();
    }
    return handler.next(err);
  }
}
