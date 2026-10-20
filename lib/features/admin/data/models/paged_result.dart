/// نتيجة مؤرَّقة كما يبنيها `meta` في متحكمات الإدارة
/// A paged result as built by the `meta` block of the admin controllers.
///
/// المتحكمات الأربعة (`UserAdminController`, `SessionAdminController`, سجل النشاط) تُرجع
/// `{total, page, limit, pages}` — وهو شكل العملاء/العاملين لا شكل الحسابات/العملات. السبب أن هذه
/// الطبقة كتبت كلها في مرحلتين متتاليتين بنمط واحد، فالقارئ هنا واحد ولا داعي لشكلين.
/// These controllers all return {total, page, limit, pages} — the customer/worker shape, not the
/// account/currency one — because this layer was written in two consecutive phases in one style.
class PagedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int pages;

  const PagedResult({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 100,
    this.pages = 0,
  });

  const PagedResult.empty()
    : items = const [],
      total = 0,
      page = 1,
      limit = 100,
      pages = 0;

  /// هل توجد صفحة تالية؟ من `pages` المعلَن لا من حجم الدفعة: صفحة أخيرة ناقصة تبدو فارغة وإلا
  /// Is there a next page? Decided by the announced `pages`, not by the batch size, so a short
  /// last page isn't mistaken for another one being available.
  bool get hasMore => page < pages;

  /// سطر الحالة «عرض N من E» كما في قائمة العملاء
  /// The «عرض N من E» status line used by the admin lists.
  String get summaryLabel => 'عرض ${items.length} من $total';

  /// قراءة الاستجابة موحّدة: `data` مصفوفة و`meta` أعداد
  /// Read the response uniformly: data is a list, meta holds the counters.
  static PagedResult<R> fromJson<R>(
    Map<String, dynamic> body,
    R Function(Map<String, dynamic> row) mapper,
  ) {
    final rows = body['data'];
    final raw = body['meta'];
    final meta = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};

    return PagedResult<R>(
      items: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(mapper)
                .toList(growable: false)
          : const [],
      total: _int(meta['total']),
      page: _int(meta['page'], fallback: 1),
      limit: _int(meta['limit'], fallback: 100),
      pages: _int(meta['pages']),
    );
  }

  /// قراءة عدد من `meta` بحذر: قد يصل نصاً من أوراكل أو غائباً كلياً
  /// Read a meta counter cautiously: Oracle may send it as text or omit it entirely.
  static int _int(dynamic value, {int fallback = 0}) {
    if (value == null || value == false) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString()) ?? fallback;
  }
}
