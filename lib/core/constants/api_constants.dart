/// ثوابت الروابط والإعدادات الخاصة بواجهة الـ API
/// API endpoints and configuration constants
class ApiConstants {
  // الرابط الأساسي للـ API
  // الرابط الأساسي الافتراضي للـ API
  static const String defaultBaseUrl = 'http://192.168.0.9:8000/api';
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

  // الكشوفات الشخصية — خاص بالموظف الحالي
  // Personal statements — scoped to the logged-in employee.
  static const String myFinancialStatement = '/my-statement/financial';
  static const String myWorkStatement = '/my-statement/work';

  // استفسارات الدعم — الإرسال عام (يعمل قبل الدخول)، والقراءة والرد خلف صلاحية support.*
  // Support inquiries — submission is public (works before login); listing and replying
  // sit behind the support.* grants.
  static const String supportInquiries = '/support/inquiries';

  // قسم التفصيل — كل المسارات خلف صلاحية tailoring.* والقراءة فقط من الـ VIEW.
  // Tailoring — every route sits behind tailoring.* grants and reads the view only.
  // هوية الفاتورة مركّبة (رقم، سنة) لأن رقم الفاتورة وحده غير فريد.
  // The bill identity is the composite (number, year) because the number alone is not unique.
  static const String tailoringBills = '/tailoring/bills';
  static const String tailoringReference = '/tailoring/reference';

  static String tailoringBill(int billNo, int year) =>
      '$tailoringBills/$billNo/$year';

  static String tailoringMovements(int billNo, int year) =>
      '$tailoringBills/$billNo/$year/movements';

  static String tailoringActivity(int billNo, int year) =>
      '$tailoringBills/$billNo/$year/activity';

  // مقاسات العملاء — داخل قسم العملاء، تُقرأ من واجهة فواتير التفصيل نفسها.
  // Customer measurements — inside the customers section, read from the same cutting-bill view.
  // المفتاح رباعي (عميل، فاتورة، سنة، موديل): رقم الفاتورة وحده غير فريد، والموديل يُعرَّف
  // بـ SEQ_NO داخل الفاتورة، وعميل يطابق رقماً لا يملك الموديل يُرفض.
  // The key is four-part (customer, bill, year, model): a bill number is not unique on its own,
  // a model is SEQ_NO inside the bill, and a customer who does not own the model is refused.
  static const String measurementCustomers = '/customers/measurements';

  static String measurementModels(int custNo) =>
      '$measurementCustomers/$custNo/models';

  static String measurementModel(
    int custNo,
    int billNo,
    int year,
    int seqNo,
  ) => '$measurementCustomers/$custNo/models/$billNo/$year/$seqNo';

  static String measurementActivity(
    int custNo,
    int billNo,
    int year,
    int seqNo,
  ) => '${measurementModel(custNo, billNo, year, seqNo)}/activity';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration testTimeout = Duration(seconds: 7);
}
