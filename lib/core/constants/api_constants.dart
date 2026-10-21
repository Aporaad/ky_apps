/// ثوابت الروابط والإعدادات الخاصة بواجهة الـ API
/// API endpoints and configuration constants
class ApiConstants {
  // الرابط الأساسي للـ API
  // الرابط الأساسي الافتراضي للـ API
  static const String defaultBaseUrl = 'http://192.168.0.11:8000/api';
  static const String baseUrl = defaultBaseUrl;

  // مسار فحص الاتصال بالخادم
  static const String testConnectionEndpoint = '/hello';

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // حالة الصلاحيات الحالية — تُقرأ عند الدخول وعند رجوع التطبيق من الخلفية
  // Current IBAC state — read at sign-in and when the app returns to the foreground.
  static const String permissions = '/auth/permissions';

  // تهيئة التطبيق (الهوية/المظهر) — عامة للقراءة، ومحمية للكتابة
  // App config (identity/theming) — public read, protected writes.
  // كلمة سر إعدادات API أصبحت محلية بالكامل — لا تحقق ولا تغيير عبر الخادم، لأن شاشة
  // إعدادات API يجب أن تُفتح حتى عندما يكون رابط الخادم خاطئ أو غير متصل.
  // The API-settings password is fully local now — never verified/changed via the server,
  // because the API-settings screen must open even when the server URL is wrong or offline.
  static const String appConfig = '/app-config';

  // مسارات المقاييس الحيوية
  static const String biometricLogin    = '/auth/biometric/login';
  static const String biometricRegister = '/auth/biometric/register';
  static const String biometricRevoke   = '/auth/biometric/revoke';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration testTimeout = Duration(seconds: 7);
}
