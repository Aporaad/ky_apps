import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة التخزين الآمن لحفظ التوكن وبيانات الاعتماد المشفرة
/// Secure storage service to manage encrypted tokens and credentials
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _tokenKey = 'ky_auth_token';
  static const String _userTypeKey = 'ky_user_type';
  static const String _userDataKey = 'ky_user_data';
  static const String _apiBaseUrlKey = 'ky_api_base_url';

  /// حفظ رمز الوصول (Token)
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// قراءة رمز الوصول
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// حذف رمز الوصول
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// حفظ نوع المستخدم (موظف / عميل)
  Future<void> saveUserType(String userType) async {
    await _storage.write(key: _userTypeKey, value: userType);
  }

  /// قراءة نوع المستخدم
  Future<String?> getUserType() async {
    return await _storage.read(key: _userTypeKey);
  }

  /// حفظ بيانات المستخدم بصيغة JSON
  Future<void> saveUserData(String json) async {
    await _storage.write(key: _userDataKey, value: json);
  }

  /// قراءة بيانات المستخدم المخزنة
  Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  /// حفظ عنوان ورابط الـ API المخصص
  Future<void> saveApiBaseUrl(String url) async {
    await _storage.write(key: _apiBaseUrlKey, value: url);
  }

  /// قراءة عنوان ورابط الـ API المخصص
  Future<String?> getApiBaseUrl() async {
    return await _storage.read(key: _apiBaseUrlKey);
  }

  /// حذف عنوان ورابط الـ API المخصص (للعودة للافتراضي)
  Future<void> deleteApiBaseUrl() async {
    await _storage.delete(key: _apiBaseUrlKey);
  }

  /// مسح بيانات جلسة المستخدم المخزنة عند تسجيل الخروج مع الاحتفاظ بعنوان الـ API
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _userDataKey);
  }

  /// مسح كافة البيانات تماماً من الذاكرة بما فيها عنوان الـ API
  Future<void> purgeEverything() async {
    await _storage.deleteAll();
  }
}

