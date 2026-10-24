import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/account_model.dart';
import '../../data/models/chart_account_model.dart';
import '../../data/models/tree_export_row_model.dart';
import '../../data/repositories/account_repository.dart';

/// مزود مستودع الحسابات
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return AccountRepository(client: client);
});

/// حالة قائمة الشجرة المحاسبية — تحميل كسول مستوى-بمستوى.
/// Lazy chart-of-accounts state: the structure skeleton arrives in one request and
/// financial leaves are paged per node, so the screen stays a pure projection of
/// state (thousands of rows rendered as one flat list).
class AccountTreeState {
  final bool isLoading;
  final String? error;
  final List<AccountTreeNode> tree;

  /// معرّفات العقد المفتوحة (acc_1 / main_12 / sub_120 / group_5).
  final Set<String> expanded;

  /// كاش أبناء كل عقدة: صفحة الحسابات المالية المحمّلة لها.
  final Map<String, List<AccountLeafModel>> childrenCache;
  final Map<String, int> childPages;
  final Map<String, int> childTotals;
  final Map<String, bool> childHasMore;
  final Set<String> loadingChildren;

  /// خطأ تحميل الأبناء لكل عقدة على حدة — الشجرة تبقى عاملة behind عقدة فاشلة.
  final Map<String, String> childErrors;

  /// نتائج البحث الخادمي (كل المستويات): لا تُحمَّل الشجرة من أجله.
  final String searchQuery;
  final List<AccountTreeNode> searchResults;
  final bool isSearching;
  final String? searchError;

  /// ترتيب الأبناء داخل العقدة — ترتيب خادمي لأن الحسابات لا تُحمَّل كلها.
  final String sort;
  final String dir;

  /// فترة الأرصدة المجمّعة: null = كامل السجل التاريخي.
  final String? fromDate;
  final String? toDate;

  const AccountTreeState({
    this.isLoading = false,
    this.error,
    this.tree = const [],
    this.expanded = const {},
    this.childrenCache = const {},
    this.childPages = const {},
    this.childTotals = const {},
    this.childHasMore = const {},
    this.loadingChildren = const {},
    this.childErrors = const {},
    this.searchQuery = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
    this.sort = 'acc_no',
    this.dir = 'asc',
    this.fromDate,
    this.toDate,
  });

  int childTotal(String id) => childTotals[id] ?? 0;

  bool hasMoreChildren(String id) => childHasMore[id] ?? false;

  bool isLoadingChildren(String id) => loadingChildren.contains(id);

  List<AccountLeafModel> childrenOf(String id) => childrenCache[id] ?? const [];

  String? childError(String id) => childErrors[id];

  bool childrenLoaded(String id) => childrenCache.containsKey(id);

  /// بحث عن عقدة هيكلية بمعرّفها داخل الهيكل المحمّل. وجوده على الحالة لأن
  /// الشاشة تحتاجه لكل سطر «تحميل المزيد»/خطأ — لا مبرر لقراءة المزوّد هناك.
  /// Deep lookup of a structural node by id. Lives on the state so the list view
  /// can resolve host nodes without touching the notifier for every row.
  AccountTreeNode? findById(String id) {
    AccountTreeNode? walk(AccountTreeNode node) {
      if (node.id == id) return node;
      for (final c in node.children) {
        final hit = walk(c);
        if (hit != null) return hit;
      }
      return null;
    }

    for (final n in tree) {
      final hit = walk(n);
      if (hit != null) return hit;
    }
    return null;
  }

  /// عدد العقد الهيكلية المحمّلة (للترويسة ولتقدير كلفة «توسيع الكل»).
  int get structuralNodeCount {
    int walk(AccountTreeNode node) =>
        1 + node.children.fold(0, (sum, c) => sum + walk(c));
    return tree.fold(0, (sum, n) => sum + walk(n));
  }

  AccountTreeState copyWith({
    bool? isLoading,
    Object? error = _unset,
    List<AccountTreeNode>? tree,
    Set<String>? expanded,
    Map<String, List<AccountLeafModel>>? childrenCache,
    Map<String, int>? childPages,
    Map<String, int>? childTotals,
    Map<String, bool>? childHasMore,
    Set<String>? loadingChildren,
    Map<String, String>? childErrors,
    String? searchQuery,
    List<AccountTreeNode>? searchResults,
    bool? isSearching,
    Object? searchError = _unset,
    String? sort,
    String? dir,
    Object? fromDate = _unset,
    Object? toDate = _unset,
  }) {
    return AccountTreeState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      tree: tree ?? this.tree,
      expanded: expanded ?? this.expanded,
      childrenCache: childrenCache ?? this.childrenCache,
      childPages: childPages ?? this.childPages,
      childTotals: childTotals ?? this.childTotals,
      childHasMore: childHasMore ?? this.childHasMore,
      loadingChildren: loadingChildren ?? this.loadingChildren,
      childErrors: childErrors ?? this.childErrors,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError: searchError == _unset
          ? this.searchError
          : searchError as String?,
      sort: sort ?? this.sort,
      dir: dir ?? this.dir,
      fromDate: fromDate == _unset ? this.fromDate : fromDate as String?,
      toDate: toDate == _unset ? this.toDate : toDate as String?,
    );
  }

  /// فاصل بين «لم يُمرَّر» و«مُرِّر بقيمة null» في copyWith للحقول الاختيارية.
  static const Object _unset = Object();
}

class AccountTreeNotifier extends StateNotifier<AccountTreeState> {
  final AccountRepository _repo;

  /// إلغاء الطلب الجاري عند إعادة التحميل أو خروج الشاشة: استجابة متأخرة لا يجوز
  /// أن تطمس النتيجة الأحدث.
  CancelToken? _treeToken;
  CancelToken? _searchToken;
  final Map<String, CancelToken> _childrenTokens = {};
  int _searchVersion = 0;

  /// سقف التحميل التلقائي عند «توسيع الكل»: فوقه تُترك الحسابات للفتح اليدوي،
  /// لأن ألف مجموعة تعني ألف طلب في لحظة واحدة.
  static const int _autoLoadCap = 30;

  AccountTreeNotifier(this._repo) : super(const AccountTreeState()) {
    loadTree();
  }

  /// جلب الهيكل + الأرصدة المجمّعة. يُفرَّغ كاش الأبناء لأن الفترة تتغير غالباً.
  Future<void> loadTree({
    String? fromDate,
    String? toDate,
    bool keepExpansion = false,
  }) async {
    _treeToken?.cancel('superseded');
    _cancelAllChildren();
    final token = CancelToken();
    _treeToken = token;

    final from = fromDate ?? state.fromDate;
    final to = toDate ?? state.toDate;

    state = state.copyWith(
      isLoading: true,
      error: null,
      fromDate: from,
      toDate: to,
      childrenCache: const {},
      childPages: const {},
      childTotals: const {},
      childHasMore: const {},
      loadingChildren: const {},
      childErrors: const {},
      expanded: keepExpansion ? state.expanded : const <String>{},
    );

    try {
      final tree = await _repo.fetchAccountTree(
        fromDate: from,
        toDate: to,
        cancelToken: token,
      );
      if (token.isCancelled) return;
      state = state.copyWith(isLoading: false, tree: tree);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// هل للعقدة أبناء ماليون يُجلبون من الخادم؟ المجموعة دائماً، والجزئي إن له
  /// حسابات مباشرة بلا مجموعة.
  static bool isFinancialHost(AccountTreeNode node) =>
      node.level == 'group' ||
      (node.level == 'sub' && (node.directCount ?? 0) > 0);

  /// بحث عن عقدة بمعرّفها — تفويض للحالة حتى لا تتكرر التمشية في مكانين.
  AccountTreeNode? findById(String id) => state.findById(id);

  Future<void> toggleExpand(AccountTreeNode node) async {
    final key = node.id;
    if (state.expanded.contains(key)) {
      state = state.copyWith(
        expanded: state.expanded.difference({key}),
      );
      return;
    }
    state = state.copyWith(expanded: {...state.expanded, key});
    if (isFinancialHost(node)) await loadChildren(node);
  }

  void collapse(AccountTreeNode node) {
    state = state.copyWith(expanded: state.expanded.difference({node.id}));
  }

  /// جلب صفحة أبناء لعقدة: حسابات المجموعة أو الحسابات المباشرة للجزئي.
  Future<void> loadChildren(AccountTreeNode node, {bool append = false}) async {
    final key = node.id;
    if (state.loadingChildren.contains(key)) return;

    _childrenTokens[key]?.cancel('superseded');
    final token = CancelToken();
    _childrenTokens[key] = token;

    final page = append ? (state.childPages[key] ?? 0) + 1 : 1;

    state = state.copyWith(
      loadingChildren: {...state.loadingChildren, key},
      childErrors: Map.of(state.childErrors)..remove(key),
    );

    try {
      final res = await _repo.fetchTreeChildren(
        level: node.level == 'group' ? 'group' : 'sub',
        groupId: node.groupId,
        accPart: node.accPart,
        sort: state.sort,
        dir: state.dir,
        page: page,
        fromDate: state.fromDate,
        toDate: state.toDate,
        cancelToken: token,
      );
      if (token.isCancelled) return;

      final previous = append
          ? (state.childrenCache[key] ?? const <AccountLeafModel>[])
          : const <AccountLeafModel>[];

      state = state.copyWith(
        childrenCache: Map.of(state.childrenCache)
          ..[key] = [...previous, ...res.leaves],
        childPages: Map.of(state.childPages)..[key] = res.page,
        childTotals: Map.of(state.childTotals)..[key] = res.total,
        childHasMore: Map.of(state.childHasMore)..[key] = res.hasMore,
        loadingChildren: state.loadingChildren.difference({key}),
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(
        loadingChildren: state.loadingChildren.difference({key}),
        childErrors: Map.of(state.childErrors)..[key] = e.toString(),
      );
    } finally {
      _childrenTokens.remove(key);
    }
  }

  Future<void> loadMore(AccountTreeNode node) =>
      loadChildren(node, append: true);

  /// إعادة تحميل أبناء عقدة بعد إنشاء أو تعديل حساب داخلها.
  Future<void> reloadNode(AccountTreeNode node) async {
    final key = node.id;
    state = state.copyWith(
      childrenCache: Map.of(state.childrenCache)..remove(key),
      childPages: Map.of(state.childPages)..remove(key),
      childHasMore: Map.of(state.childHasMore)..remove(key),
      childTotals: Map.of(state.childTotals)..remove(key),
    );
    await loadChildren(node);
  }

  /// تغيير الترتيب: تُعاد قراءة العقد المحمّلة فقط، لا الشجرة كلها.
  Future<void> setSort(String sort, String dir) async {
    state = state.copyWith(sort: sort, dir: dir);
    final nodes = <AccountTreeNode>[];
    for (final key in state.childrenCache.keys.toList()) {
      final node = findById(key);
      if (node != null) nodes.add(node);
    }
    for (final node in nodes) {
      await reloadNode(node);
    }
  }

  /// توسيع/طي الكل على المستويات الهيكلية: 0 = الأقسام … 3 = المجموعات، و-1 = طي الكل.
  /// «توسيع الكل» لا يفتح الأوراق المالية — تُحمَّل بترقيم عند فتح عقدها.
  Future<void> expandToLevel(int maxLevel) async {
    if (maxLevel < 0) {
      state = state.copyWith(expanded: const <String>{});
      return;
    }

    final ids = <String>{};
    void walk(AccountTreeNode node, int depth) {
      if (depth > maxLevel) return;
      ids.add(node.id);
      for (final c in node.children) {
        walk(c, depth + 1);
      }
    }

    for (final n in state.tree) {
      walk(n, 0);
    }
    state = state.copyWith(expanded: ids);

    // تحميل تلقائي محدود بالمجموعات فقط: عددها صغير في القاعدة التراثية (12)،
    // وما زاد على السقف يُترك للفتح اليدوي حتى لا ننشر مئات الطلبات دفعة واحدة.
    var pending = 0;
    for (final id in ids) {
      if (pending >= _autoLoadCap) break;
      final node = findById(id);
      if (node == null || node.level != 'group') continue;
      if (state.childrenCache.containsKey(id)) continue;
      pending++;
      unawaited(loadChildren(node));
    }
  }

  /// توسيع المسار الكامل لعقدة نتيجة بحث: codePath = "1 / 12 / 120 / G5".
  Future<void> revealPath(AccountTreeNode node) async {
    final parts = node.codePath
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final ids = {...state.expanded};
    for (final p in parts) {
      if (p.startsWith('G')) {
        ids.add('group_${p.substring(1)}');
      } else if (p.length == 1) {
        ids.add('acc_$p');
      } else if (p.length == 2) {
        ids.add('main_$p');
      } else if (p.length == 3) {
        ids.add('sub_$p');
      }
    }
    state = state.copyWith(expanded: ids);

    // العقدة المضيفة للأبناء: مجموعتها إن كانت ضمن مجموعة، وجزئيها إن كان مباشراً
    final hostId = node.groupId != null
        ? 'group_${node.groupId}'
        : (node.accPart != null ? 'sub_${node.accPart}' : null);
    final host = hostId == null ? null : findById(hostId);
    if (host != null &&
        isFinancialHost(host) &&
        !state.childrenCache.containsKey(host.id)) {
      await loadChildren(host);
    }
  }

  /// بحث خادمي بحارس سباق: النتيجة الأقدم تُتجاهل فلا تومض ثم تختفي.
  Future<void> runSearch(String query) async {
    final trimmed = query.trim();
    final version = ++_searchVersion;

    if (trimmed.isEmpty) {
      _searchToken?.cancel('empty');
      state = state.copyWith(
        searchQuery: '',
        searchResults: const [],
        isSearching: false,
        searchError: null,
      );
      return;
    }

    _searchToken?.cancel('superseded');
    final token = CancelToken();
    _searchToken = token;
    state = state.copyWith(
      searchQuery: trimmed,
      isSearching: true,
      searchError: null,
    );

    try {
      final results = await _repo.searchAccounts(trimmed, cancelToken: token);
      if (version != _searchVersion || token.isCancelled) return;
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (e) {
      if (version != _searchVersion) return;
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(isSearching: false, searchError: e.toString());
    }
  }

  void clearSearch() {
    _searchVersion++;
    _searchToken?.cancel('cleared');
    state = state.copyWith(
      searchQuery: '',
      searchResults: const [],
      isSearching: false,
      searchError: null,
    );
  }

  void _cancelAllChildren() {
    for (final token in _childrenTokens.values) {
      token.cancel('superseded');
    }
    _childrenTokens.clear();
  }

  @override
  void dispose() {
    _treeToken?.cancel('disposed');
    _searchToken?.cancel('disposed');
    _cancelAllChildren();
    super.dispose();
  }
}

final accountTreeProvider =
    StateNotifierProvider<AccountTreeNotifier, AccountTreeState>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return AccountTreeNotifier(repo);
    });

/// حالة قائمة الحسابات المالية (CHART_ACC)
class ChartAccountsState {
  final bool isLoading;
  final String search;
  final List<ChartAccountModel> accounts;
  final Map<String, dynamic> meta;
  final String? error;

  const ChartAccountsState({
    this.isLoading = false,
    this.search = '',
    this.accounts = const [],
    this.meta = const {},
    this.error,
  });

  ChartAccountsState copyWith({
    bool? isLoading,
    String? search,
    List<ChartAccountModel>? accounts,
    Map<String, dynamic>? meta,
    String? error,
  }) {
    return ChartAccountsState(
      isLoading: isLoading ?? this.isLoading,
      search: search ?? this.search,
      accounts: accounts ?? this.accounts,
      meta: meta ?? this.meta,
      error: error,
    );
  }
}

class ChartAccountsNotifier extends StateNotifier<ChartAccountsState> {
  final AccountRepository _repo;
  int _searchVersion = 0;

  ChartAccountsNotifier(this._repo) : super(const ChartAccountsState()) {
    loadAccounts();
  }

  Future<void> loadAccounts({String? search, int page = 1}) async {
    final query = search ?? state.search;
    final currentVersion = ++_searchVersion;
    state = state.copyWith(isLoading: true, search: query, error: null);
    try {
      final res = await _repo.fetchChartAccounts(search: query, page: page);
      if (currentVersion == _searchVersion) {
        state = state.copyWith(
          isLoading: false,
          accounts: res['data'] as List<ChartAccountModel>? ?? [],
          meta: res['meta'] as Map<String, dynamic>? ?? {},
        );
      }
    } catch (e) {
      if (currentVersion == _searchVersion) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }
}

final chartAccountsProvider =
    StateNotifierProvider<ChartAccountsNotifier, ChartAccountsState>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return ChartAccountsNotifier(repo);
    });

/// مزودي الأقسام والحسابات للأب
final parentAccountsProvider = FutureProvider<List<AccountModel>>((ref) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccounts();
});

final parentAccMainProvider = FutureProvider.family<List<AccMainModel>, int?>((
  ref,
  accNo,
) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccMain(accNo: accNo);
});

final parentAccSubProvider = FutureProvider.family<List<AccSubModel>, int?>((
  ref,
  accSub,
) async {
  final repo = ref.watch(accountRepositoryProvider);
  return repo.fetchAccSub(accSub: accSub);
});

final parentAccSubGroupProvider =
    FutureProvider.family<List<AccSubGroupModel>, int?>((ref, accPart) async {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.fetchAccSubGroup(accPart: accPart);
    });

/// دليل العملات لحقل العملة في نموذج إنشاء الحساب.
/// Currency directory backing the account form's picker.
///
/// لماذا لا `currenciesProvider` القائم؟ طريقه `/currencies` خلف `currencies.view`،
/// فمستخدمٌ بصلاحية `accounts.create` وحدها يقابل قائمة فارغة مع أن النموذج يطلب
/// منه أن يختار — المسار الجديد `/accounts/currencies` يُمنح بصلاحيات الحسابات نفسها.
/// The existing provider reads `/currencies`, which needs `currencies.view`; an
/// accounts-only user would get an empty picker on a field that asks them to choose.
final accountCurrencyOptionsProvider =
    FutureProvider<List<CurrencyOptionModel>>((ref) async {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.fetchCurrencyOptions();
    });
