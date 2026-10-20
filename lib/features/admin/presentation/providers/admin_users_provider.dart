import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/admin_result.dart';
import '../../data/models/app_user_model.dart';
import '../../data/models/paged_result.dart';
import '../../data/repositories/admin_user_repository.dart';

/// مزود مستودع إدارة المستخدمين
/// Admin user repository provider.
final adminUserRepositoryProvider = Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(client: ref.watch(dioClientProvider));
});

/// حالة قائمة المستخدمين في شاشة الإدارة
/// State of the admin user list.
class AdminUsersState {
  final List<AppUserModel> users;
  final bool isLoading;
  final String? error;

  /// البحث والحالة والنوع والمديرون فقط — كلها معامالات query لا فلترة محلية
  /// Search, status, type, and admins-only are all query params, never local filtering.
  final String search;
  final String status;
  final String userType;
  final bool adminOnly;
  final String sort;
  final String direction;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.status = 'all',
    this.userType = 'all',
    this.adminOnly = false,
    this.sort = 'user_id',
    this.direction = 'asc',
    this.page = 1,
    this.limit = 100,
    this.total = 0,
    this.pages = 0,
  });

  bool get hasMore => page < pages;

  /// هل توجد فلاتر فعلية؟ تُظهر زر «مسح الفلاتر» ورسالة الفراغ المناسبة
  /// Are any filters actually on? Drives the clear-filters button and the right empty message.
  bool get hasActiveFilters =>
      search.isNotEmpty || status != 'all' || userType != 'all' || adminOnly;

  AdminUsersState copyWith({
    List<AppUserModel>? users,
    bool? isLoading,
    String? error,
    String? search,
    String? status,
    String? userType,
    bool? adminOnly,
    String? sort,
    String? direction,
    int? page,
    int? limit,
    int? total,
    int? pages,
    bool clearError = false,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      status: status ?? this.status,
      userType: userType ?? this.userType,
      adminOnly: adminOnly ?? this.adminOnly,
      sort: sort ?? this.sort,
      direction: direction ?? this.direction,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
    );
  }
}

/// مُحمِّل قائمة المستخدمين: فلترة وفرز وتصفح عند الخادم، وحراسة تسابق على البحث
/// Loads the user list — filtering, sorting, and paging live server-side, with a race guard.
///
/// سبب الحراسة: كل ضغطة في شريط البحث تُطلق طلباً، والرد المتأخر لطلب قديم كان سيدسّ نتائج
/// بحثٍ ألغاه المستخدم أصلاً أسفل القائمة. نفس نمط `ChartAccountsNotifier`.
/// The guard exists because every keystroke fires a request, and a late reply to an abandoned
/// search would land under the list. Same pattern as ChartAccountsNotifier.
class AdminUsersNotifier extends Notifier<AdminUsersState> {
  CancelToken? _cancelToken;
  int _requestVersion = 0;

  @override
  AdminUsersState build() {
    // إلغاء أي طلب جارٍ عند تفكيك المزود: لا كتابة على حالة بعد التفكيك ولا طلب يتيم
    // Cancel any in-flight request when the provider is disposed: no post-dispose writes, no orphans.
    ref.onDispose(() => _cancelToken?.cancel('provider-disposed'));
    Future.microtask(() => load(refresh: true));

    return const AdminUsersState(isLoading: true);
  }

  AdminUserRepository get _repo => ref.read(adminUserRepositoryProvider);

  /// تحميل الصفحة الحالية بالإعدادات الجارية
  /// Load the current page with the settings in effect.
  Future<void> load({bool refresh = false}) async {
    // إلغاء الطلب السابق قبل بدء جديد: طلبان متزامنان على نفس القائمة يعنيان سباقاً على الحالة
    // Cancel the in-flight request: two concurrent list calls would race over the same state.
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    final version = ++_requestVersion;

    state = refresh
        ? state.copyWith(isLoading: true, clearError: true, users: const [])
        : state.copyWith(isLoading: true, clearError: true);

    try {
      final PagedResult<AppUserModel> result = await _repo.fetchUsers(
        search: state.search,
        status: state.status,
        userType: state.userType,
        adminOnly: state.adminOnly,
        sort: state.sort,
        direction: state.direction,
        page: state.page,
        limit: state.limit,
        cancelToken: token,
      );

      if (version != _requestVersion) return;

      state = state.copyWith(
        users: result.items,
        total: result.total,
        pages: result.pages,
        page: result.page,
        limit: result.limit,
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      // الإلغاء ليس خطأ يعرض للمستخدم — هو نتيجة طبيعية لضغطات سريعة
      // A cancellation is not a user-visible error; it is the normal outcome of fast typing.
      if (CancelToken.isCancel(e)) return;
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل المستخدمين: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل المستخدمين: $e',
      );
    }
  }

  /// تحديث بعد العودة من شاشة منح أو إنشاء — يعيد نفس الصفحة والفلاتر
  /// Reload after returning from the grant or create screen — keeps page and filters.
  Future<void> refresh() => load(refresh: true);

  /// البحث — يستدعى بعد تأخير 300ms في الشاشة لا هنا
  /// Search — the screen debounces; this method just applies it.
  Future<void> setSearch(String value) async {
    final query = value.trim();
    if (query == state.search) return;
    state = state.copyWith(search: query, page: 1);
    await load(refresh: true);
  }

  /// تطبيق مجموعة فلاتر دفعة واحدة ثم تحميل
  /// Apply a filter batch at once, then load.
  Future<void> applyFilters({
    String? status,
    String? userType,
    bool? adminOnly,
  }) async {
    state = state.copyWith(
      status: status ?? state.status,
      userType: userType ?? state.userType,
      adminOnly: adminOnly ?? state.adminOnly,
      page: 1,
    );
    await load(refresh: true);
  }

  /// مسح الفلاتر مع إبقاء البحث — زر «مسح الفلاتر» في حالة الفراغ
  /// Clear the filters but keep the search term, as the empty-state button promises.
  Future<void> clearFilters() async {
    state = state.copyWith(
      status: 'all',
      userType: 'all',
      adminOnly: false,
      page: 1,
    );
    await load(refresh: true);
  }

  /// الفرز: العمود نفسه يعكس الاتجاه، وعمود جديد يبدأ تصاعدياً
  /// Sorting: repeating a column flips its direction; a new column starts ascending.
  Future<void> sortBy(String column) async {
    final direction = state.sort == column && state.direction == 'asc'
        ? 'desc'
        : 'asc';
    state = state.copyWith(sort: column, direction: direction, page: 1);
    await load(refresh: true);
  }

  /// تطبيق فرز من ورقة الفرز: العمود والاتجاه كما اختارهما المستخدم
  /// Apply a sort picked in the sheet — column and direction exactly as chosen, without the
  /// flip-on-repeat rule `sortBy` uses for header taps.
  Future<void> applySort(String column, String direction) async {
    if (column == state.sort && direction == state.direction) return;
    state = state.copyWith(
      sort: column,
      direction: direction == 'desc' ? 'desc' : 'asc',
      page: 1,
    );
    await load(refresh: true);
  }

  /// الانتقال لصفحة (1-based) مع تجاهل الأرقام الخارجة عن المدى
  /// Go to a 1-based page, ignoring out-of-range numbers.
  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page);
    await load(refresh: true);
  }

  /// تعطيل/تفعيل ثم تحديث القائمة، مع إرجاع رسالة الخادم للعرض
  /// Toggle, then reload — the server message is returned for the snackbar.
  Future<AdminResult<Map<String, dynamic>>> toggleUser(int userId) async {
    final result = await _repo.toggleUser(userId);
    if (result.success) await load();

    return result;
  }

  /// حذف ثم تحديث — والحذف عند الخادم ينهي جلسات المستخدم أيضاً
  /// Delete, then reload — deletion also ends the user's sessions server-side.
  Future<AdminResult<Map<String, dynamic>>> deleteUser(int userId) async {
    final result = await _repo.deleteUser(userId);
    if (result.success) await load();

    return result;
  }
}

final adminUsersProvider = NotifierProvider<AdminUsersNotifier, AdminUsersState>(
  AdminUsersNotifier.new,
);
