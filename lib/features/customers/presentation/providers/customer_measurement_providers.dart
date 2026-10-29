import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/measurement_customer_model.dart';
import '../../data/models/measurement_model_ref.dart';
import '../../data/repositories/customer_measurement_repository.dart';

// ================================================================
// المستودع / the repository
// ================================================================

/// مزود مستودع المقاسات — عميل Dio المركزي نفسه، لا نسخة ثانية
/// The measurements repository provider — the same shared Dio client, never a second one.
final customerMeasurementRepositoryProvider =
    Provider<CustomerMeasurementRepository>((ref) {
      return CustomerMeasurementRepository(client: ref.watch(dioClientProvider));
    });

// ================================================================
// قائمة العملاء / the customer list
// ================================================================

/// حالة قائمة عملاء المقاسات: بحث وترتيب وتحميل صفحة تالية
/// The measurements customer list: search, sort and next-page loading.
class MeasurementCustomersState {
  final List<MeasurementCustomer> items;
  final bool isLoading;

  /// تحميل صفحة تالية مع بقاء الصفوف المعروضة
  /// Loading a next page while the visible rows stay put.
  final bool isLoadingMore;
  final String? error;
  final String query;
  final String sort;
  final int page;
  final bool hasMore;
  final int total;

  const MeasurementCustomersState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.sort = 'date_desc',
    this.page = 1,
    this.hasMore = false,
    this.total = 0,
  });

  /// حالة فراغ بلا خطأ وبلا تحميل — تُظهر رسالة «لا مقاسات لهذا البحث»
  /// An empty state with neither error nor loading — shows "no measurements for this search".
  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  /// هل البحث مطبَّق؟ — لزر «مسح الفلتر» في الشريط
  /// Is a search applied? Drives the "clear filter" button.
  bool get isFiltered => query.isNotEmpty;

  MeasurementCustomersState copyWith({
    List<MeasurementCustomer>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    String? sort,
    int? page,
    bool? hasMore,
    int? total,
    bool clearError = false,
  }) {
    return MeasurementCustomersState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

/// إدارة قائمة العملاء: تحميل أول، بحث مؤجَّل، ترتيب وتصفح
/// The customer list manager: first load, debounced search, sorting and paging.
///
/// نمط `CuttingBillsListNotifier` نفسه: `build()` لا ينتظر، بل يجدّل التحميل بعده، لكل شاشة
/// في التطبيق نفس السلوك (لا تجمّد أثناء البناء).
/// The same pattern as the cutting-bill list: `build()` never awaits — it schedules the first
/// load, which is how every screen in the app avoids freezing during build.
class MeasurementCustomersNotifier extends Notifier<MeasurementCustomersState> {
  /// حجم الصفحة — 30 يوازن بين زمن الاستجابة على أوراكل وطول القائمة
  /// The page size — 30 balances Oracle response time against list length.
  static const int pageSize = 30;

  /// تأجيل البحث 300ms كما في كل شاشات البحث بالتطبيق
  /// The 300ms search debounce used by every search screen here.
  static const Duration debounce = Duration(milliseconds: 300);

  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  MeasurementCustomersState build() {
    Future.microtask(load);

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });

    return const MeasurementCustomersState(isLoading: true);
  }

  CustomerMeasurementRepository get _repo =>
      ref.read(customerMeasurementRepositoryProvider);

  /// تحميل الصفحة الأولى بمعايير الحالة الحالية
  /// Load the first page with the state's current criteria.
  Future<void> load() async {
    _debounceTimer?.cancel();
    await _fetch(page: 1);
  }

  /// إعادة التحميل من الصفر مع إفراغ القائمة — زر التحديث والسحب للتحديث
  /// Reload from scratch with an empty list — the refresh button and pull-to-refresh.
  Future<void> refresh() async {
    state = state.copyWith(items: const [], clearError: true);
    await load();
  }

  /// بحث مؤجَّل: كل ضغطة مفتاح تُلغي المؤقّت السابق
  /// Debounced search: each keystroke cancels the previous timer.
  void search(String query) {
    final trimmed = query.trim();
    if (trimmed == state.query) return;

    state = state.copyWith(query: trimmed);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _fetch(page: 1));
  }

  /// تغيير الترتيب (الأحدث/الأقدم/الاسم) — يعيد التحميل من الصفحة الأولى
  /// Change the sort (newest/oldest/name) — reloads from the first page.
  Future<void> setSort(String sort) async {
    if (sort == state.sort) return;
    _debounceTimer?.cancel();
    state = state.copyWith(sort: sort);
    await _fetch(page: 1);
  }

  /// مسح البحث والعودة إلى الترتيب الافتراضي
  /// Clear the search and return to the default sort.
  Future<void> clearFilters() async {
    _debounceTimer?.cancel();
    state = state.copyWith(query: '', sort: 'date_desc', clearError: true);
    await _fetch(page: 1);
  }

  /// تحميل الصفحة التالية وإلحاقها
  /// Load the next page and append it.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _fetch(page: state.page + 1, append: true);
  }

  /// الجلب الفعلي — بصمة الطلب تحرس فلا تطمس نتيجة قديمة نتيجةً أحدث
  /// The actual fetch — the request fingerprint keeps a stale reply from overwriting a new one.
  Future<void> _fetch({required int page, bool append = false}) async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;

    final fingerprint = '${state.query}|${state.sort}|$page';

    state = append
        ? state.copyWith(isLoadingMore: true, clearError: true)
        : state.copyWith(
            isLoading: true,
            isLoadingMore: false,
            clearError: true,
          );

    try {
      final result = await _repo.fetchCustomers(
        search: state.query,
        sort: state.sort,
        page: page,
        limit: pageSize,
        cancelToken: token,
      );

      if (fingerprint != '${state.query}|${state.sort}|$page') return;

      state = state.copyWith(
        items: append ? [...state.items, ...result.items] : result.items,
        isLoading: false,
        isLoadingMore: false,
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
        clearError: true,
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (fingerprint != '${state.query}|${state.sort}|$page') return;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e is MeasurementException
            ? e.displayMessage
            : 'تعذّر تحميل قائمة العملاء — أعد المحاولة',
      );
    }
  }
}

final measurementCustomersProvider =
    NotifierProvider<MeasurementCustomersNotifier, MeasurementCustomersState>(
      MeasurementCustomersNotifier.new,
    );

// ================================================================
// موديلات العميل / the customer's models
// ================================================================

/// حالة موديلات عميل بعينه: بحث، نطاق زمني، ترتيب وتصفح
/// The models of one specific customer: search, date range, sorting and paging.
///
/// القائمة مُزوِّد عائلة (`family`) لا قائمة عامة واحدة: حالة بحث العميل «أ» يجب ألا تنتقل
/// إلى شاشة العميل «ب» عند الرجوع للخلف، فذاكرة محضومة لكل عميل بأمرٍ من منطق التنقل نفسه.
/// The list is a `family` provider, not one global list: customer A's search state must never
/// surface on customer B's screen when navigating back — per-customer memory is what the
/// navigation flow itself demands.
class CustomerModelsState {
  final List<MeasurementModelRef> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String query;
  final String sort;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final bool hasMore;
  final int total;

  const CustomerModelsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.sort = 'date_desc',
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.hasMore = false,
    this.total = 0,
  });

  bool get hasRange => fromDate != null || toDate != null;

  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  CustomerModelsState copyWith({
    List<MeasurementModelRef>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    String? sort,
    DateTime? fromDate,
    DateTime? toDate,
    int? page,
    bool? hasMore,
    int? total,
    bool clearError = false,
    bool clearRange = false,
  }) {
    return CustomerModelsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      fromDate: clearRange ? null : fromDate ?? this.fromDate,
      toDate: clearRange ? null : toDate ?? this.toDate,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

/// إدارة موديلات عميل — الوسائط (رقم العميل) تُمرَّر في الباني كما في `WorkersListNotifier`
/// The models manager — the argument (the customer number) is a constructor parameter, as in
/// `WorkersListNotifier`.
class CustomerModelsNotifier extends Notifier<CustomerModelsState> {
  static const int pageSize = 30;
  static const Duration debounce = Duration(milliseconds: 300);

  /// رقم العميل الذي تُحصَر هذه القائمة فيه — لا يُقرأ من الاستجابة
  /// The customer this list is scoped to — never read back from a response.
  final int custNo;

  CustomerModelsNotifier(this.custNo);

  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  CustomerModelsState build() {
    Future.microtask(load);

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });

    return const CustomerModelsState(isLoading: true);
  }

  CustomerMeasurementRepository get _repo =>
      ref.read(customerMeasurementRepositoryProvider);

  Future<void> load() async {
    _debounceTimer?.cancel();
    await _fetch(page: 1);
  }

  Future<void> refresh() async {
    state = state.copyWith(items: const [], clearError: true);
    await load();
  }

  void search(String query) {
    final trimmed = query.trim();
    if (trimmed == state.query) return;

    state = state.copyWith(query: trimmed);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => _fetch(page: 1));
  }

  Future<void> setSort(String sort) async {
    if (sort == state.sort) return;
    _debounceTimer?.cancel();
    state = state.copyWith(sort: sort);
    await _fetch(page: 1);
  }

  /// تطبيق نطاق زمني (طرفاه اختياريان) ثم إعادة التحميل
  /// Apply a date range (either end optional), then reload.
  Future<void> setRange(DateTime? from, DateTime? to) async {
    _debounceTimer?.cancel();
    state = CustomerModelsState(
      query: state.query,
      sort: state.sort,
      fromDate: from,
      toDate: to,
      isLoading: true,
    );
    await _fetch(page: 1);
  }

  Future<void> clearFilters() async {
    _debounceTimer?.cancel();
    state = CustomerModelsState(
      sort: state.sort,
      query: '',
      isLoading: true,
    );
    await _fetch(page: 1);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _fetch(page: state.page + 1, append: true);
  }

  /// البصمة تشمل العميل: قائمتان متزامنتان لعميلين مختلفين لا تخلط إحداهما بالأخرى.
  /// The fingerprint includes the customer, so two concurrent lists for different customers
  /// can never cross-write.
  String get _signature =>
      '$custNo|${state.query}|${state.sort}|${state.fromDate}|${state.toDate}';

  Future<void> _fetch({required int page, bool append = false}) async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;

    final fingerprint = '$_signature|$page';

    state = append
        ? state.copyWith(isLoadingMore: true, clearError: true)
        : state.copyWith(
            isLoading: true,
            isLoadingMore: false,
            clearError: true,
          );

    try {
      final result = await _repo.fetchModels(
        custNo: custNo,
        search: state.query,
        fromDate: state.fromDate,
        toDate: state.toDate,
        sort: state.sort,
        page: page,
        limit: pageSize,
        cancelToken: token,
      );

      if (fingerprint != '$_signature|$page') return;

      state = state.copyWith(
        items: append ? [...state.items, ...result.items] : result.items,
        isLoading: false,
        isLoadingMore: false,
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
        clearError: true,
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (fingerprint != '$_signature|$page') return;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e is MeasurementException
            ? e.displayMessage
            : 'تعذّر تحميل موديلات العميل — أعد المحاولة',
      );
    }
  }
}

final customerModelsProvider =
    NotifierProvider.family<CustomerModelsNotifier, CustomerModelsState, int>(
      CustomerModelsNotifier.new,
    );

// ================================================================
// تفصيل موديل واحد / one model in full
// ================================================================

/// تفصيل موديل بمفتاحه الرباعي — يُحمَّل عند فتح الشاشة فقط
/// One model's detail by its four-part key — loaded only when its screen opens.
///
/// `autoDispose` لأن الشاشة تحزم حزمة واحدة ثم تُغلق، والمقاسات بيانات شخصية فلا تبقى في
/// الذاكرة بعد أن ينتهي النظر فيها.
/// `autoDispose`: the screen holds one bundle then closes, and measurements are personal data —
/// they should not outlive the looking.
final customerMeasurementProvider =
    FutureProvider.autoDispose.family<MeasurementSubject, MeasurementKey>(
      (ref, key) async {
        final token = CancelToken();
        ref.onDispose(token.cancel);

        return ref.read(customerMeasurementRepositoryProvider).fetchModel(
          key,
          cancelToken: token,
        );
      },
    );
