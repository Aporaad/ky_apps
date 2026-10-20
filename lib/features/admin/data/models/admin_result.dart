import 'package:dio/dio.dart';

/// نتيجة عملية كتابة في طبقة الإدارة (إنشاء/تعديل/منح/حذف/حفظ)
/// The result of an admin write operation (create/update/grant/delete/save).
///
/// لماذا صنف واحد لأربعة مستودعات بدل `CustomerResult` خاص بكل واحدة؟ لأن رسائل الخادم هنا
/// جزء من الأمان: 403 «لا تملك صلاحية…» و409 «الاسم مستخدم» و422 بصيغة `errors.unknown_codes`
/// يجب أن تصل للمستخدم كما هي، وتكرار تفكيك `DioException` أربع مرات يعني أربع نسخ قد تسقط
/// واحدة منها رسالة الحجب وتكتفي بـ «خطأ في الشبكة».
/// One type for four repositories because the server's messages are part of the security story:
/// the 403 denial, the 409 duplicate name, and 422 payloads like errors.unknown_codes must reach
/// the user verbatim. Repeating the DioException unpacking four times means four copies, and one
/// of them will collapse a denial into a generic network error.
class AdminResult<T> {
  final bool success;
  final String message;

  /// الحِمل المفكَّك عند النجاح — null للعمليات التي لا تعيد شيئاً
  /// The decoded payload on success; null for operations that return nothing.
  final T? data;

  /// أخطاء التحقق كما أرسلها الخادم: حقل → قائمة رسائل
  /// Validation errors as the server sent them: field → list of messages.
  final Map<String, List<String>> errors;

  /// رمز الاستجابة، و0 يعني أن الفشل شبكة لا خادم (انقطاع/مهلة)
  /// The HTTP status; 0 means the failure was the network itself, not a server refusal.
  final int statusCode;

  const AdminResult({
    required this.success,
    this.message = '',
    this.data,
    this.errors = const {},
    this.statusCode = 200,
  });

  bool get isForbidden => statusCode == 403;

  bool get isConflict => statusCode == 409;

  bool get isValidation => statusCode == 422;

  /// هل انقطعت الشبكة؟ للتمييز بين «اقتباس غير مسموح» و«الخادم بعيد» في نفس البطاقة
  /// Did the network fail? Distinguishes «not allowed» from «server unreachable» on one card.
  bool get isNetworkFailure => statusCode == 0;

  /// رسالة العرض: نص الخادم، وإلا أول خطأ تحققي، وإلا النص الاحتياطي
  /// The message to display: the server's text, else the first validation error, else the fallback.
  String get displayMessage {
    if (message.trim().isNotEmpty) return message.trim();
    for (final list in errors.values) {
      if (list.isNotEmpty && list.first.trim().isNotEmpty) return list.first.trim();
    }

    return 'فشلت العملية';
  }

  /// رسالة خطأ حقل بعينه — لشريط الخطأ تحت خانة الاسم أو خانة الصلاحيات
  /// The error for one field, shown under that input rather than as a banner.
  String? errorFor(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) return null;

    return list.first;
  }

  /// قراءة استجابة ناجحة بحمولة موحّدة
  /// Read a successful response with a uniform envelope.
  static AdminResult<R> fromBody<R>(
    Map<String, dynamic> body, {
    R Function(Map<String, dynamic> data)? mapper,
    int statusCode = 200,
  }) {
    final ok = body['success'] == true;
    final data = body['data'];

    return AdminResult<R>(
      success: ok,
      message: (body['message'] ?? '').toString(),
      data: ok && mapper != null && data is Map<String, dynamic>
          ? mapper(data)
          : null,
      errors: _errorsOf(body),
      statusCode: statusCode,
    );
  }

  /// قراءة استجابة بحمولة خام بلا نمذجة — لعمليات مثل التعطيل التي تعيد `{is_activated, sessions_ended}`
  /// Read a response with the raw payload — for operations like toggling that return small facts
  /// which belong to no model row.
  static AdminResult<Map<String, dynamic>> raw(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    final data = body['data'];

    return AdminResult<Map<String, dynamic>>(
      success: body['success'] == true,
      message: (body['message'] ?? '').toString(),
      data: data is Map<String, dynamic> ? data : const {},
      errors: _errorsOf(body),
      statusCode: statusCode,
    );
  }

  /// أخطاء الخادم لمستدٍ يحتاجها مفصولة عن الرسالة العامة (حقول الإعدادات، مثلًا)
  /// Field errors for a caller that needs them apart from the general message (settings keys, say).
  static Map<String, List<String>> errorsOf(Map<String, dynamic> body) => _errorsOf(body);

  /// تفكيك فشل من `DioException`: الاحتفاظ برسالة الخادم ورمزه وأخطائه
  /// Unpack a DioException, preserving the server's message, status, and field errors.
  static AdminResult<R> failure<R>(DioException error, {String fallback = 'خطأ في الشبكة'}) {
    final response = error.response;
    final body = response?.data;
    final map = body is Map<String, dynamic>
        ? body
        : body is Map
        ? Map<String, dynamic>.from(body)
        : const <String, dynamic>{};

    if (map.isNotEmpty) {
      return AdminResult<R>(
        success: false,
        // رسالة الخادم أولى لأنها تشرح القرار الأمني (403 باسم الصلاحية الناقصة)
        // The server message comes first: it names the missing permission on a 403.
        message: (map['message'] ?? '').toString(),
        errors: _errorsOf(map),
        statusCode: response?.statusCode ?? 0,
      );
    }

    // بلا استجابة: انقطاع أو مهلة — والرمز 0 يمنع الخلط بينه وبين رفض الخادم
    // No response at all: timeout or offline. Status 0 keeps that distinct from a server refusal.
    return AdminResult<R>(
      success: false,
      message: error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionTimeout
          ? 'انتهت مهلة الاتصال بالخادم / Request timed out'
          : fallback,
      statusCode: 0,
    );
  }

  /// أخطاء الخادم قد تصل `{حقل: [نص]}` أو `{حقل: نص}` — والحالتان مرئيتان في هذه المتحكمات
  /// Server errors arrive as {field: [text]} or {field: text}; both shapes occur in these controllers.
  static Map<String, List<String>> _errorsOf(Map<String, dynamic> body) {
    final raw = body['errors'];
    if (raw is! Map) return const {};

    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      final field = key?.toString();
      if (field == null) return;
      if (value is List) {
        out[field] = value.map((item) => item?.toString() ?? '').toList();
      } else {
        out[field] = [(value?.toString() ?? '')];
      }
    });

    return out;
  }
}
