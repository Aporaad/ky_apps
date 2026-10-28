import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/cutting_movement_model.dart';
import '../../data/models/tailoring_reference_model.dart';
import '../../data/repositories/tailoring_repository.dart';

// ================================================================
// المستودع
// ================================================================

/// مزود مستودع التفصيل — عميل Dio المركزي
/// The tailoring repository provider — the shared Dio client.
final tailoringRepositoryProvider = Provider<TailoringRepository>((ref) {
  return TailoringRepository(client: ref.watch(dioClientProvider));
});

// ================================================================
// قائمة الفواتير
// ================================================================

/// حالة قائمة فواتير التفصيل مع البحث والفلترة الزمنية والتصفح اللانهائي
/// The cutting-bill list state with search, date range and infinite paging.
class CuttingBillsListState {
  final List<CuttingBillSummary> items;
  final bool isLoading;

  /// تحميل صفحة تالية مع بقاء الصفوف المعروضة
  /// Loading the next page while the shown rows stay in place.
  final bool isLoadingMore;
  final String? error;
  final String query;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final bool hasMore;
  final int total;

  const CuttingBillsListState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.hasMore = false,
    this.total = 0,
  });

  /// هل الفلتر الزمني مطبَّق؟ — يُستخدم لإظهار زر «مسح الفلتر»
  /// Is a date range applied? — drives the "clear filter" button.
  bool get hasRange => fromDate != null || toDate != null;

  /// حالة فراغ بلا خطأ وبلا تحميل
  /// An empty state with no error and no loading.
  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  CuttingBillsListState copyWith({
    List<CuttingBillSummary>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    DateTime? fromDate,
    DateTime? toDate,
    int? page,
    bool? hasMore,
    int? total,
    bool clearError = false,
    bool clearRange = false,
  }) {
    return CuttingBillsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      fromDate: clearRange ? null : fromDate ?? this.fromDate,
      toDate: clearRange ? null : toDate ?? this.toDate,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
    );
  }
}

/// إدارة قائمة الفواتير: تحميل أول، بحث مؤجَّل، فلترة زمنية، وتحميل المزيد
/// The bill list manager: first load, debounced search, date range and load-more.
class CuttingBillsListNotifier extends Notifier<CuttingBillsListState> {
  /// حجم الصفحة — 20 توازن بين زمن الاستجابة على أوراكل وطول القائمة
  /// The page size — 20 balances the Oracle response time against list length.
  static const int pageSize = 20;

  /// تأخير البحث — 300ms كما في بقية شاشات البحث بالتطبيق
  /// The search debounce — 300ms, matching the app's other search screens.
  static const Duration debounce = Duration(milliseconds: 300);

  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  @override
  CuttingBillsListState build() {
    // لا انتظار داخل build: التحميل الأول يُجدول بعده لا فيه، فما تجمّد الشاشة.
    // No awaiting inside build: the first load is scheduled after it, never inside it.
    Future.microtask(load);

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _cancelToken?.cancel();
    });

    return const CuttingBillsListState(isLoading: true);
  }

  TailoringRepository get _repo => ref.read(tailoringRepositoryProvider);

  /// تحميل الصفحة الأولى بمعايير الحالة الحالية
  /// Load the first page with the state's current criteria.
  Future<void> load() async {
    _debounceTimer?.cancel();
    await _fetch(page: 1);
  }

  /// إعادة التحميل من الصفر مع إفراغ القائمة — زر التحديث
  /// Reload from scratch, clearing the list — the refresh action.
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

  /// مسح البحث والفلتر معاً
  /// Clear both the search and the date range.
  Future<void> clearFilters() async {
    _debounceTimer?.cancel();
    state = state.copyWith(query: '', clearRange: true, clearError: true);
    await _fetch(page: 1);
  }

  /// تطبيق نطاق زمني (أحدهما قد يكون `null`) ثم إعادة التحميل
  /// Apply a date range (either end may be `null`), then reload.
  Future<void> setRange(DateTime? from, DateTime? to) async {
    _debounceTimer?.cancel();
    state = CuttingBillsListState(
      query: state.query,
      fromDate: from,
      toDate: to,
      isLoading: true,
    );
    await _fetch(page: 1);
  }

  /// تحميل الصفحة التالية وإلحاقها بالقائمة
  /// Load the next page and append it.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    await _fetch(page: state.page + 1, append: true);
  }

  /// الجلب الفعلي — نسخة الاستعلام تُحرس كي لا تطمس نتيجة قديمة نتيجة أحدث
  /// The actual fetch — the query version is guarded so a stale result never
  /// overwrites a newer one.
  Future<void> _fetch({required int page, bool append = false}) async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;

    // بصمة الطلب: تغيّر أي معيار بعد الإرسال يُلغي قبول الرد
    // The request fingerprint: any criterion changing after sending invalidates the reply.
    final fingerprint = '${state.query}|${state.fromDate}|${state.toDate}|$page';

    state = append
        ? state.copyWith(isLoadingMore: true, clearError: true)
        : state.copyWith(isLoading: true, isLoadingMore: false, clearError: true);

    try {
      final result = await _repo.fetchBills(
        search: state.query,
        fromDate: state.fromDate,
        toDate: state.toDate,
        page: page,
        limit: pageSize,
        cancelToken: token,
      );

      if (fingerprint != '${state.query}|${state.fromDate}|${state.toDate}|$page') {
        return;
      }

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
      if (fingerprint != '${state.query}|${state.fromDate}|${state.toDate}|$page') {
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e is TailoringException
            ? e.displayMessage
            : 'تعذّر تحميل فواتير التفصيل — أعد المحاولة',
      );
    }
  }
}

final cuttingBillsListProvider =
    NotifierProvider<CuttingBillsListNotifier, CuttingBillsListState>(
      CuttingBillsListNotifier.new,
    );

// ================================================================
// تفصيل فاتورة واحدة
// ================================================================

/// تفصيل فاتورة بالهوية المركّبة (رقم، سنة)
/// One bill's detail by the composite identity (number, year).
///
/// `autoDispose` لأن الشاشة تحجز نسخة واحدة ثم تُغلق؛ ولا داعي لإبقاء الفواتير مفتوحة.
/// `autoDispose` because the screen holds one detail then closes; bills need not stay cached.
final cuttingBillDetailProvider =
    FutureProvider.autoDispose.family<CuttingBillDetail, CuttingBillKey>((
      ref,
      key,
    ) async {
      final token = CancelToken();
      ref.onDispose(token.cancel);

      return ref
          .read(tailoringRepositoryProvider)
          .fetchBill(key.billNo, key.year, cancelToken: token);
    });

// ================================================================
// سجل حركة الموديل المختار
// ================================================================

/// مفتاح طلب سجل الحركة: الفاتورة + أرقام قطع الموديل المختار
/// The movement request key: the bill plus the selected model's piece numbers.
class CuttingMovementsKey {
  final int billNo;
  final int year;
  final List<int> seqNos;

  const CuttingMovementsKey({
    required this.billNo,
    required this.year,
    required this.seqNos,
  });

  /// «رقم/سنة:قطع» — شكل ثابت يُستخدم لمقارنة المفاتيح
  /// A stable shape used to compare keys.
  String get id => '$billNo/$year:${seqNos.join(",")}';

  @override
  bool operator ==(Object other) => other is CuttingMovementsKey && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// سجل حركة القطع المختارة — يُحمَّل فقط عند فتح قسم الحركة
/// The selected pieces' movement log — loaded only when its section opens.
final cuttingMovementsProvider = FutureProvider.autoDispose
    .family<List<CuttingMovement>, CuttingMovementsKey>((ref, key) async {
      if (key.seqNos.isEmpty) return const [];

      final token = CancelToken();
      ref.onDispose(token.cancel);

      return ref
          .read(tailoringRepositoryProvider)
          .fetchMovements(
            key.billNo,
            key.year,
            key.seqNos,
            cancelToken: token,
          );
    });

// ================================================================
// المرجعيات
// ================================================================

/// تسميات المقاسات + الأنواع + الأشكال + الحالات — مشتركة بين الشاشات
/// Measurement labels, types, shapes and stages — shared across the screens.
///
/// لا `autoDispose`: المرجعيات شبه ثابتة ويستفيد منها كل فتح لاحق.
/// Not `autoDispose`: the reference data is near-static and every later open reuses it.
final tailoringReferenceProvider = FutureProvider<TailoringReference>((ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);

  return ref.read(tailoringRepositoryProvider).fetchReference(cancelToken: token);
});
