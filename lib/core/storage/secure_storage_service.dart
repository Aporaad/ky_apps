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
  /// نفس الموعد لكن بوقت الجهاز — يقرؤه الحارس المحلي مباشرةً
  /// The same deadline expressed in device time — what the local watchdog actually compares against
  static const String _sessionDeadlineLocalKey = 'ky_session_deadline_local';
  // مفاتيح تهيئة التطبيق — على مستوى الجهاز، تبقى بعد تسجيل الخروج كالرابط المخصص
  // App-config keys — device-level, kept across logout just like the custom API URL.
  static const String _appConfigKey = 'ky_app_config'; // كاش JSON للتهيئة العامة
  static const String _appLogoPathKey = 'ky_app_logo_path'; // مسار ملف الشعار المحلي
  static const String _apiPasswordHashKey = 'ky_api_pw_hash'; // تجزئة محلية للاحتياط دون اتصال

  // تخطيط الواجهة الرئيسية — تفضيل مستخدم لا حالة جلسة: يبقى بعد الخروج، ويُفصل بحارس
  // `user_id` داخل البلوب نفسه، ويمسحه `purgeEverything` وحده.
  // Home layout — a user preference, not session state: survives logout, separated by the
  // `user_id` guard inside the blob, and wiped only by `purgeEverything`.
  static const String _homeLayoutKey = 'ky_home_layout';

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
    await _storage.delete(key: _sessionDeadlineLocalKey);
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

  /// حفظ موعد النهاية بوقت الجهاز (`toIso8601String` لوقت محلي بلا علامة منطقة)
  /// Store the deadline converted to device time, so the watchdog never compares two different clocks.
  Future<void> saveSessionDeadlineLocal(String? isoText) async {
    if (isoText == null || isoText.isEmpty) {
      await _storage.delete(key: _sessionDeadlineLocalKey);
      return;
    }

    await _storage.write(key: _sessionDeadlineLocalKey, value: isoText);
  }

  /// قراءة موعد النهاية بوقت الجهاز
  /// Read the device-clock deadline text.
  Future<String?> getSessionDeadlineLocal() async {
    return await _storage.read(key: _sessionDeadlineLocalKey);
  }

  /// حذف حالة IBAC وحدها عند فشل تحديث الصلاحيات بعد 401
  /// Drop only the IBAC state when a post-401 permission refresh fails.
  Future<void> clearPermissions() async {
    await _storage.delete(key: _permissionsKey);
    await _storage.delete(key: _isAdminKey);
    await _storage.delete(key: _sessionExpiresAtKey);
    await _storage.delete(key: _sessionDeadlineLocalKey);
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

  // ── تهيئة التطبيق (الشعار/الألوان/بيانات الشركة) ─────────
  // App configuration (logo / colors / company info).

  /// حفظ كاش التهيئة العامة كنص JSON (تُطبَّق عند الإقلاع قبل الوصول للخادم)
  /// Persist the public config cache as JSON (applied at boot before the server is reached).
  Future<void> saveAppConfig(String json) async {
    await _storage.write(key: _appConfigKey, value: json);
  }

  /// قراءة كاش التهيئة (null = لا كاش بعد)
  /// Read the config cache (null means nothing cached yet).
  Future<String?> getAppConfig() async {
    return await _storage.read(key: _appConfigKey);
  }

  /// حذف كاش التهيئة
  /// Delete the config cache.
  Future<void> deleteAppConfig() async {
    await _storage.delete(key: _appConfigKey);
  }

  /// حفظ المسار المطلق لملف الشعار المحفوظ محلياً على الجهاز
  /// Store the absolute path of the locally-saved logo file.
  Future<void> saveAppLogoPath(String path) async {
    await _storage.write(key: _appLogoPathKey, value: path);
  }

  /// قراءة مسار الشعار المحلي (null = استخدام الشعار الافتراضي من الأصول)
  /// Read the local logo path (null means fall back to the bundled asset).
  Future<String?> getAppLogoPath() async {
    return await _storage.read(key: _appLogoPathKey);
  }

  /// حذف مسار الشعار المحلي
  /// Delete the local logo path.
  Future<void> deleteAppLogoPath() async {
    await _storage.delete(key: _appLogoPathKey);
  }

  /// حفظ التجزئة المحلية (SHA-256) لكلمة سر إعدادات API للاستخدام دون اتصال
  /// Store the local SHA-256 fallback hash of the API-settings password for offline use.
  Future<void> saveApiPasswordHash(String hash) async {
    await _storage.write(key: _apiPasswordHashKey, value: hash);
  }

  /// قراءة التجزئة المحلية لكلمة سر إعدادات API
  /// Read the local API-settings password hash.
  Future<String?> getApiPasswordHash() async {
    return await _storage.read(key: _apiPasswordHashKey);
  }

  /// حذف التجزئة المحلية لكلمة سر إعدادات API
  /// Delete the local API-settings password hash.
  Future<void> deleteApiPasswordHash() async {
    await _storage.delete(key: _apiPasswordHashKey);
  }

  // ── تخطيط الواجهة الرئيسية (الاختصارات) ──────────────────
  // Home layout (shortcuts).

  /// حفظ تخطيط الرئيسية كنص JSON
  /// Persist the home layout as JSON text.
  Future<void> saveHomeLayout(String json) async {
    await _storage.write(key: _homeLayoutKey, value: json);
  }

  /// قراءة التخطيط المخزّن (null = لم يخصّص المستخدم بعد)
  /// Read the stored layout (null means the user has not customised yet).
  Future<String?> getHomeLayout() async {
    return await _storage.read(key: _homeLayoutKey);
  }

  /// حذف التخطيط — للعودة إلى أول تشغيل
  /// Delete the layout, returning to first run.
  Future<void> deleteHomeLayout() async {
    await _storage.delete(key: _homeLayoutKey);
  }
}

