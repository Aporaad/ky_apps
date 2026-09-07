import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// معالج وسيط لحقن التوكن تلقائياً في ترويسات الطلبات
/// Interceptor to automatically attach Bearer token to API requests
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }
}
