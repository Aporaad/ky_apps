import 'package:dio/dio.dart';

/// نتيجة موحّدة لكل عمليات الكتابة في قسم المخازن
/// One uniform result for every write operation in the stores module.
///
/// ── لماذا موحّدة؟ لأن رسائل الخطأ هنا ليست تجميلاً: الخادم يرفض المخزن الأرشيفي، والسطر بلا
///    صنف فرعي، والرصيد غير الكافي، وتعارض الاسم/الكود الفريد كلها برسائل عربية مقصودة يجب
///    أن تصل للمستخدم كما هي — لا أن تُستبدل بـ«حدث خطأ».
/// ── Why uniform? The server's rejections here are deliberate Arabic messages (archived store,
///    a line without a sub item, insufficient stock, a unique name/part-number clash) and they
///    must reach the user verbatim, not be replaced by "something went wrong".
class StoreResult {
  const StoreResult({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  /// أول رسالة حقل من `errors` — تُعرض تحت الحقل المخصص
  /// The first field error, rendered under its field.
  String? get firstFieldError {
    final bag = errors;

    if (bag == null) return null;

    for (final value in bag.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }

    return null;
  }

  /// نص واحد صالح للعرض في لقطة (snackbar)
  /// A single line fit for a snackbar.
  String get displayMessage => firstFieldError ?? message;

  factory StoreResult.fromBody(Map<String, dynamic> body) {
    final errors = body['errors'];

    return StoreResult(
      success: body['success'] == true,
      message: (body['message'] ?? '').toString(),
      data: body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : null,
      errors: errors is Map<String, dynamic> ? errors : null,
    );
  }

  factory StoreResult.failure(String message) =>
      StoreResult(success: false, message: message);

  /// بناء نتيجة من استثناء Dio مع الحفاظ على رسالة الخادم
  /// Build a failure from a Dio exception, preserving the server's message.
  factory StoreResult.fromDio(DioException error) {
    final response = error.response?.data;
    final message = response is Map<String, dynamic>
        ? (response['message'] ?? error.message ?? 'خطأ في الشبكة').toString()
        : (error.message ?? 'خطأ في الشبكة');

    final errors = response is Map<String, dynamic> ? response['errors'] : null;

    return StoreResult(
      success: false,
      message: message,
      errors: errors is Map<String, dynamic> ? errors : null,
    );
  }
}

/// حزمة صفحة: عناصر + إجمالي + بيانات وصفية
/// A page bundle: items, total and meta.
class StorePage<T> {
  const StorePage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.meta = const {},
  });

  final List<T> items;
  final int total;
  final int page;
  final int pages;
  final Map<String, dynamic> meta;

  bool get isEmpty => items.isEmpty;

  static StorePage<T> parse<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parseItem,
  ) {
    final raw = body['data'];
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(parseItem)
              .toList(growable: false)
        : <T>[];

    return StorePage<T>(
      items: items,
      total: meta['total'] is num ? (meta['total'] as num).toInt() : items.length,
      page: meta['page'] is num ? (meta['page'] as num).toInt() : 1,
      pages: meta['pages'] is num ? (meta['pages'] as num).toInt() : 1,
      meta: meta,
    );
  }
}
