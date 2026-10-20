import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/admin_result.dart';
import '../../data/models/app_session_model.dart';
import '../../data/repositories/session_repository.dart';

/// مزود مستودع الجلسات
/// Sessions repository provider.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(client: ref.watch(dioClientProvider));
});

/// حالة شاشة الجلسات النشطة
/// Active sessions screen state.
class ActiveSessionsState {
  final List<AppSessionModel> sessions;
  final bool isLoading;
  final String? error;
  final String status;
  final String search;

  /// تضييق على مستخدم بعينه — من فلتر الشاشة عند اختيار اسم مستخدم
  /// Narrowed to one user — chosen through the screen's own user filter.
  final int? userId;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const ActiveSessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.status = 'all',
    this.search = '',
    this.userId,
    this.page = 1,
    this.limit = 50,
    this.total = 0,
    this.pages = 0,
  });

  bool get hasMore => page < pages;

  int get activeCount => sessions.where((session) => session.isActive).length;

  ActiveSessionsState copyWith({
    List<AppSessionModel>? sessions,
    bool? isLoading,
    String? error,
    String? status,
    String? search,
    int? userId,
    int? page,
    int? limit,
    int? total,
    int? pages,
    bool clearError = false,

    /// `copyWith` الاعتيادي يعجز عن مسح `userId` لأن null يعني «أبقِ القديم»
    /// Plain `copyWith` cannot clear `userId`, since null means "keep the old value".
    bool clearUserId = false,
  }) {
    return ActiveSessionsState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      status: status ?? this.status,
      search: search ?? this.search,
      userId: clearUserId ? null : userId ?? this.userId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
    );
  }
}

/// محمّل الجلسات — قراءة من جدول توكنات Sanctum عبر الخادم
/// Loads sessions from Sanctum's token table through the API.
class ActiveSessionsNotifier extends Notifier<ActiveSessionsState> {
  CancelToken? _cancelToken;
  int _requestVersion = 0;

  @override
  ActiveSessionsState build() {
    ref.onDispose(() => _cancelToken?.cancel('provider-disposed'));

    return const ActiveSessionsState();
  }

  SessionRepository get _repo => ref.read(sessionRepositoryProvider);

  /// التحميل — تُستدعى من الشاشة بعد البناء مباشرة (وليس في `build`)
  /// Load — called by the screen right after build, not from `build()` itself.
  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    final version = ++_requestVersion;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.fetchSessions(
        userId: state.userId,
        status: state.status,
        search: state.search,
        page: state.page,
        limit: state.limit,
        cancelToken: token,
      );

      if (version != _requestVersion) return;
      state = state.copyWith(
        sessions: result.items,
        total: result.total,
        pages: result.pages,
        page: result.page,
        limit: result.limit,
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل الجلسات: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      if (version != _requestVersion) return;
      state = state.copyWith(isLoading: false, error: 'تعذّر تحميل الجلسات: $e');
    }
  }

  /// فلترة بالحالة (`all|active|expired|disabled`) عند الخادم
  /// Filter by status at the server: all, active, expired, or disabled.
  Future<void> setStatus(String status) async {
    if (status == state.status) return;
    state = state.copyWith(status: status, page: 1);
    await load();
  }

  Future<void> setSearch(String value) async {
    final query = value.trim();
    if (query == state.search) return;
    state = state.copyWith(search: query, page: 1);
    await load();
  }

  /// تضييق الشاشة على مستخدم — والقيمة null تعيد القائمة كاملة
  /// Narrow the screen to one user; null restores the full list.
  Future<void> focusUser(int? userId) async {
    state = userId == null
        ? state.copyWith(userId: null, clearUserId: true, page: 1)
        : state.copyWith(userId: userId, page: 1);
    await load();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page);
    await load();
  }

  /// إنهاء جلسة واحدة ثم إعادة التحميل — لأن الصف يبقى في القاعدة بحالة `expired`
  /// Terminate one session, then reload — the row stays in the table as expired.
  Future<AdminResult<Map<String, dynamic>>> terminate(int tokenId) async {
    final result = await _repo.terminateSession(tokenId);
    if (result.success) await load();

    return result;
  }

  /// إنهاء كل جلسات مستخدم — الإجراء بعد تعطيل حساب أو سحب صلاحيات
  /// End every session of a user — the action after deactivating or stripping rights.
  Future<AdminResult<Map<String, dynamic>>> terminateUser(int userId) async {
    final result = await _repo.terminateUserSessions(userId);
    if (result.success) await load();

    return result;
  }
}

final activeSessionsProvider =
    NotifierProvider<ActiveSessionsNotifier, ActiveSessionsState>(
      ActiveSessionsNotifier.new,
    );
