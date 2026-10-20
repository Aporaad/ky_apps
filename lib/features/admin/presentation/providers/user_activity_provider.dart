import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_activity_model.dart';
import '../../data/repositories/admin_user_repository.dart';
import 'admin_users_provider.dart';

/// نافذة زمنية لفلترة السجل — chips أعلى الشاشة
/// Time window for the trail — the chips at the top of the screen.
enum ActivityWindow {
  today('اليوم'),
  week('هذا الأسبوع'),
  month('هذا الشهر'),
  all('كل السجل');

  const ActivityWindow(this.label);
  final String label;
}

/// حالة سجل نشاط مستخدم
/// A user's activity trail state.
class UserActivityState {
  final List<UserActivityModel> rows;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int userId;
  final int page;
  final int limit;
  final int total;
  final int pages;
  final ActivityWindow window;

  const UserActivityState({
    this.rows = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.userId = 0,
    this.page = 1,
    this.limit = 50,
    this.total = 0,
    this.pages = 0,
    this.window = ActivityWindow.all,
  });

  bool get hasMore => page < pages;

  /// السجل المرئي بعد النافذة الزمنية
  /// The visible trail after applying the time window.
  List<UserActivityModel> get visibleRows {
    if (window == ActivityWindow.all) return rows;
    final since = windowStart;

    return rows
        .where((row) => row.createdOn != null && row.createdOn!.isAfter(since))
        .toList(growable: false);
  }

  /// بداية النافذة من ساعة الجهاز — نفس الوقت الذي قارنت به أوراكل وقت السطر
  /// Window start from the device clock — the same local frame Oracle wrote the row in.
  DateTime get windowStart {
    final now = DateTime.now();

    return switch (window) {
      ActivityWindow.today => DateTime(now.year, now.month, now.day),
      ActivityWindow.week => DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 6),
      ),
      ActivityWindow.month => DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 29),
      ),
      ActivityWindow.all => DateTime(2000),
    };
  }

  UserActivityState copyWith({
    List<UserActivityModel>? rows,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? userId,
    int? page,
    int? limit,
    int? total,
    int? pages,
    ActivityWindow? window,
    bool clearError = false,
  }) {
    return UserActivityState(
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      userId: userId ?? this.userId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
      window: window ?? this.window,
    );
  }
}

/// محمّل سجل النشاط — لكل مستخدم، ولا سجل عام في الخادم
/// Loads an activity trail per user; the server exposes no general trail.
///
/// ملاحظة توثيقية: لا يوجد `GET /activity` عام في `routes/api.php`، فـ «سجل النشاط العام» في
/// لوحة الإدارة يفتح شاشة اختيار مستخدم ثم هذا السجل. اخترت ذلك على اختراع مسار غير موجود أو
/// على حذف البطاقة: المسار غير المكتوب يفشل عند التشغيل، والبطاقة المحذوفة تفقد الشاشة غرضها.
/// There is no public /activity route, so the dashboard's general-trail card opens a user picker
/// first. That beat inventing an endpoint that would fail at runtime, and beat deleting the card.
class UserActivityNotifier extends Notifier<UserActivityState> {
  CancelToken? _cancelToken;
  int _requestVersion = 0;

  @override
  UserActivityState build() {
    ref.onDispose(() => _cancelToken?.cancel('provider-disposed'));

    return const UserActivityState();
  }

  AdminUserRepository get _repo => ref.read(adminUserRepositoryProvider);

  /// تحميل صفحة أولى لمستخدم — تستدعيها الشاشة عند بنائها
  /// Load the first page for a user — the screen calls this when it builds.
  Future<void> loadFor(int userId) async {
    if (userId <= 0) {
      state = state.copyWith(
        isLoading: false,
        rows: const [],
        error: 'لم يُحدَّد مستخدم لعرض سجله',
      );

      return;
    }

    final version = ++_requestVersion;
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;

    state = state.copyWith(
      userId: userId,
      isLoading: true,
      page: 1,
      rows: const [],
      clearError: true,
    );

    try {
      final result = await _repo.fetchActivity(
        userId,
        page: 1,
        limit: state.limit,
        cancelToken: token,
      );
      if (version != _requestVersion) return;

      state = state.copyWith(
        rows: result.items,
        total: result.total,
        pages: result.pages,
        page: result.page,
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل السجل: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل السجل: $e',
      );
    }
  }

  /// تحميل المزيد — يلحق الصفحات تلبيةً لـ «تحميل بالمزيد» في الخطة
  /// Load more — appends pages, satisfying the plan's infinite-scroll requirement.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final token = CancelToken();
    _cancelToken = token;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _repo.fetchActivity(
        state.userId,
        page: state.page + 1,
        limit: state.limit,
        cancelToken: token,
      );

      state = state.copyWith(
        rows: [...state.rows, ...result.items],
        page: result.page,
        total: result.total,
        pages: result.pages,
        isLoadingMore: false,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: 'تعذّر تحميل المزيد: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: 'تعذّر تحميل المزيد: $e',
      );
    }
  }

  /// تغيير النافذة الزمنية: لا طلب جديد لأن الخادم لا يقبل معامل تاريخ
  /// Changing the window sends no request — the server takes no date parameter.
  void setWindow(ActivityWindow window) =>
      state = state.copyWith(window: window);
}

final userActivityProvider =
    NotifierProvider<UserActivityNotifier, UserActivityState>(
      UserActivityNotifier.new,
    );
