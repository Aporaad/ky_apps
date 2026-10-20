import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة التخزين الآمن لحفظ التوكن وبيانات الاعتماد المشفرة
/// Secure storage service to manage encrypted tokens and credentials
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _tokenKey = 'ky_auth_token';
  static const String _userTypeKey = 'ky_user_type';
  static const String _userDataKey = 'ky_user_data';
  static const String _apiBaseUrlKey = 'ky_api_base_url';
  // مفاتيح المقاييس الحيوية
  static const String _biometricEnabledKey = 'ky_biometric_enabled';
  static const String _biometricUserIdKey = 'ky_biometric_user_id';
  // مفاتيح حالة IBAC — تُقرأ وحدها عند إعادة التشغيل فلا نفتح حزمة المستخدم كاملة لكل قرار حجب
  // IBAC state keys — read on their own after a restart, so gating never needs the whole user blob.
  static const String _permissionsKey = 'ky_user_permissions';
  static const String _isAdminKey = 'ky_is_admin';
  static const String _sessionExpiresAtKey = 'ky_session_expires_at';

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
  /// ومعه حالة IBAC: الصلاحيات تتبع الجلسة، وابقاؤها بعد الخروج يجعل الواجهة ترسم أقساماً
  /// للمستخدم التالي على هذا الجهاز قبل أن تُقرأ منحُه الفعلية.
  /// Clear the session data on logout, keeping the API URL. IBAC state goes too: cached grants
  /// would otherwise render the next user's screen before their real grants are read.
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _permissionsKey);
    await _storage.delete(key: _isAdminKey);
    await _storage.delete(key: _sessionExpiresAtKey);
    // لا نمسح بيانات البصمة عند الخروج حتى يستطيع المستخدم الدخول بها مجدداً
  }

  // ── حالة الصلاحيات والجلسة (IBAC) ────────────────────────

  /// حفظ أكواد صلاحيات المستخدم الحالي بصيغة JSON
  /// Store the current user's permission codes as JSON.
  Future<void> savePermissions(List<String> codes) async {
    await _storage.write(key: _permissionsKey, value: jsonEncode(codes));
  }

  /// قراءة الأكواد المخزّنة؛ أي نص تالف يعني «لا صلاحيات» لا استثناءً
  /// Read the stored codes; corrupt text means "no permissions", never an exception.
  Future<List<String>> getPermissions() async {
    final raw = await _storage.read(key: _permissionsKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      // التخزين الآمن قد يُبتر أو يُقرأ من إصدار قديم: الرفض الافتراضي أأمن من الانهيار
      // The secure blob can be truncated or written by an older build: deny, don't crash.
      return const [];
    }
  }

  /// حفظ صفة مدير النظام (قرار D1: تتجاوز جدول المنح في الخادم والواجهة معاً)
  /// Persist the system-admin flag (decision D1: it bypasses the grant table on both sides).
  Future<void> saveIsAdmin(bool isAdmin) async {
    await _storage.write(key: _isAdminKey, value: isAdmin ? '1' : '0');
  }

  /// قراءة صفة المدير — الغياب يعني false اتباعاً للرفض الافتراضي
  /// Read the admin flag; absence means false, keeping deny-by-default.
  Future<bool> getIsAdmin() async {
    final val = await _storage.read(key: _isAdminKey);
    return val == '1';
  }

  /// حفظ نهاية الجلسة الحالية كنص `YYYY-MM-DD HH:MM:SS` كما أرسلها الخادم
  /// Store the current session deadline exactly as the server sent it.
  Future<void> saveSessionExpiresAt(String? expiresAt) async {
    if (expiresAt == null || expiresAt.isEmpty) {
      await _storage.delete(key: _sessionExpiresAtKey);
      return;
    }

    await _storage.write(key: _sessionExpiresAtKey, value: expiresAt);
  }

  /// قراءة نص نهاية الجلسة (null = بلا نهاية معلومة)
  /// Read the stored deadline text (null means nothing was asserted).
  Future<String?> getSessionExpiresAt() async {
    return await _storage.read(key: _sessionExpiresAtKey);
  }

  /// حذف حالة IBAC وحدها عند فشل تحديث الصلاحيات بعد 401
  /// Drop only the IBAC state when a post-401 permission refresh fails.
  Future<void> clearPermissions() async {
    await _storage.delete(key: _permissionsKey);
    await _storage.delete(key: _isAdminKey);
    await _storage.delete(key: _sessionExpiresAtKey);
  }

  // ── البصمة والمصادقة الحيوية ─────────────────────────────

  /// حفظ حالة تفعيل البصمة
  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? '1' : '0',
    );
  }

  /// قراءة حالة تفعيل البصمة
  Future<bool> getBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == '1';
  }

  /// حفظ معرّف المستخدم لاستخدامه في تسجيل الدخول بالبصمة
  Future<void> saveUserId(int userId) async {
    await _storage.write(
      key: _biometricUserIdKey,
      value: userId.toString(),
    );
  }

  /// قراءة معرّف المستخدم المخزّن
  Future<int?> getUserId() async {
    final val = await _storage.read(key: _biometricUserIdKey);
    return val != null ? int.tryParse(val) : null;
  }

  /// مسح بيانات البصمة من التخزين المحلي (عند إلغاء التسجيل)
  Future<void> clearBiometricData() async {
    await _storage.delete(key: _biometricEnabledKey);
    await _storage.delete(key: _biometricUserIdKey);
  }

  /// مسح كافة البيانات تماماً من الذاكرة بما فيها عنوان الـ API
  Future<void> purgeEverything() async {
    await _storage.deleteAll();
  }
}

