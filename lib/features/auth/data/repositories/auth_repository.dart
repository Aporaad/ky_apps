import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// مستودع إدارة عمليات المصادقة
/// Authentication Repository
class AuthRepository {
  final DioClient _client;
  final SecureStorageService _storage;

  AuthRepository({
    required DioClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  /// تسجيل الدخول
  Future<AuthResponse> login({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          'user_type': userType,
        },
      );

      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (authResponse.success && authResponse.token != null) {
        await _storage.saveToken(authResponse.token!);
        await _storage.saveUserType(userType);
        if (authResponse.user != null) {
          await _storage.saveUserData(jsonEncode(authResponse.user!.toJson()));
        }
      }

      return authResponse;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = 'تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقاً';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMsg = errorData['message'].toString();
      }
      return AuthResponse(success: false, message: errorMsg);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// التحقق مما إذا كان المستخدم مسجل دخول بالفعل
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// جلب بيانات المستخدم المخزنة محلياً
  Future<UserModel?> getCachedUser() async {
    final data = await _storage.getUserData();
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {
      // تجاهل أخطاء الشبكة أثناء الخروج
    } finally {
      await _storage.clearAll();
    }
  }
}
