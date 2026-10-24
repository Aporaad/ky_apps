import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';

/// اختبارات الحامل الكسول للشجرة: الهيكل، كاش الأبناء بترقيم صفحات، حارس سباق
/// البحث، وإلغاء الطلبات عند الخروج — بلا شبكة فعلية.
/// Lazy notifier tests: skeleton load, per-node children cache with paging, the
/// search race guard, and CancelToken disposal. Dio is never touched — the stub
/// repository answers with canned pages whose completion is delayed on purpose.
void main() {
  AccountTreeNode groupNode({int groupId = 3, int accPart = 1291}) =>
      AccountTreeNode(
        id: 'group_$groupId',
        name: 'موظفون',
        level: 'group',
        groupId: groupId,
        accPart: accPart,
        hasChildren: true,
        accountCount: 108,
      );

  group('AccountTreeNotifier', () {
    test('loads the skeleton once and clears it on reload', () async {
      final repo = _FakeTreeRepo(
        tree: [
          AccountTreeNode(id: 'acc_1', name: 'الأصول', level: 'account'),
        ],
      );
      final notifier = AccountTreeNotifier(repo);

      await notifier.loadTree();
      expect(notifier.state.tree, hasLength(1));
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(repo.treeCalls, 2); // مرة في البناء ومرة في الطلب الصريح

      await notifier.loadTree(fromDate: '2024-01-01', toDate: '2024-12-31');
      expect(notifier.state.fromDate, '2024-01-01');
      expect(repo.lastFromDate, '2024-01-01');
      expect(repo.lastToDate, '2024-12-31');
      expect(notifier.state.tree, hasLength(1));
    });

    test('surfacing an error keeps the screen usable', () async {
      final repo = _FakeTreeRepo(tree: const [], treeFailure: 'تعذر الاتصال');
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, contains('تعذر الاتصال'));
      expect(notifier.state.tree, isEmpty);
    });

    test('expanding a group fetches its first page into the cache', () async {
      final group = groupNode();
      final repo = _FakeTreeRepo(
        tree: [
          AccountTreeNode(
            id: 'acc_1',
            name: 'الأمانة',
            level: 'account',
            hasChildren: true,
            children: [group],
          ),
        ],
      );
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      await notifier.toggleExpand(group);

      expect(notifier.state.expanded, contains('group_3'));
      expect(notifier.state.childrenLoaded('group_3'), isTrue);
      expect(notifier.state.childrenOf('group_3'), hasLength(2));
      expect(notifier.state.childTotal('group_3'), 60);
      expect(notifier.state.hasMoreChildren('group_3'), isTrue);
      expect(notifier.state.isLoadingChildren('group_3'), isFalse);
      expect(repo.lastChildrenLevel, 'group');
      expect(repo.lastChildrenGroupId, 3);
      expect(repo.lastChildrenPage, 1);
    });

    test('load-more appends the next page instead of replacing it', () async {
      final group = groupNode();
      final repo = _FakeTreeRepo(
        tree: [group],
        pages: {
          1: const [
            AccountLeafModel(accNo: 1, accName: 'أول'),
            AccountLeafModel(accNo: 2, accName: 'ثانٍ'),
          ],
          2: const [
            AccountLeafModel(accNo: 3, accName: 'ثالث'),
            AccountLeafModel(accNo: 4, accName: 'رابع'),
          ],
        },
      );
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      await notifier.toggleExpand(group);
      expect(notifier.state.childrenOf('group_3').map((l) => l.accNo), [1, 2]);

      await notifier.loadMore(group);
      expect(notifier.state.childrenOf('group_3').map((l) => l.accNo), [1, 2, 3, 4]);
      expect(repo.lastChildrenPage, 2);

      // الطي لا يمسح الكاش: إعادة الفتح لا تعيد الطلب
      notifier.collapse(group);
      expect(notifier.state.expanded, isNot(contains('group_3')));
      expect(notifier.state.childrenLoaded('group_3'), isTrue);

      final callsBefore = repo.childrenCalls;
      await notifier.toggleExpand(group);
      expect(repo.childrenCalls, callsBefore + 1); // إعادة جلب الصفحة الأولى
    });

    test('a failing children page is reported per node, not globally', () async {
      final group = groupNode();
      final repo = _FakeTreeRepo(
        tree: [group],
        childrenFailure: 'تعذر جلب الحسابات',
      );
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      await notifier.toggleExpand(group);

      expect(notifier.state.childError('group_3'), contains('تعذر جلب الحسابات'));
      expect(notifier.state.isLoadingChildren('group_3'), isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.childrenOf('group_3'), isEmpty);
    });

    test('reloadNode drops the cache and refetches page one', () async {
      final group = groupNode();
      final repo = _FakeTreeRepo(tree: [group]);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      await notifier.toggleExpand(group);
      await notifier.loadMore(group);
      final afterPaging = repo.childrenCalls;

      await notifier.reloadNode(group);
      expect(repo.childrenCalls, afterPaging + 1);
      expect(repo.lastChildrenPage, 1);
      expect(notifier.state.childrenOf('group_3'), hasLength(2));
    });

    test('a partial account with direct accounts fetches level=sub', () async {
      final sub = AccountTreeNode(
        id: 'sub_110',
        name: 'أراضي',
        level: 'sub',
        accPart: 110,
        directCount: 4,
        hasChildren: true,
      );
      final repo = _FakeTreeRepo(tree: [sub]);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      expect(AccountTreeNotifier.isFinancialHost(sub), isTrue);
      await notifier.toggleExpand(sub);
      expect(repo.lastChildrenLevel, 'sub');
      expect(repo.lastChildrenAccPart, 110);
    });

    test('the search race guard ignores a stale response', () async {
      final repo = _FakeTreeRepo(tree: const []);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      // الطلب الأبطأ يُطلق أولاً ثم يلحقه الأسرع؛ النتيجة القديمة يجب أن تُرمى
      final slow = repo.armSearch('بطيء', const [
        AccountTreeNode(id: 'chart_1', name: 'نتيجة قديمة', level: 'chart'),
      ], delay: const Duration(milliseconds: 40));
      final fast = repo.armSearch('سريع', const [
        AccountTreeNode(id: 'chart_2', name: 'نتيجة حديثة', level: 'chart'),
      ], delay: const Duration(milliseconds: 5));

      notifier.runSearch('بطيء');
      notifier.runSearch('سريع');

      await fast;
      expect(notifier.state.searchResults.map((n) => n.name), ['نتيجة حديثة']);

      await slow;
      await pumpEventQueue();
      // استجابة الأقدم وصلت متأخرة ولم تطمس الأحدث
      expect(notifier.state.searchResults.map((n) => n.name), ['نتيجة حديثة']);
      expect(notifier.state.isSearching, isFalse);
    });

    test('clearing the search cancels the in-flight query', () async {
      final repo = _FakeTreeRepo(tree: const []);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      final pending = repo.armSearch('جارٍ', const [
        AccountTreeNode(id: 'chart_9', name: 'لا تصل', level: 'chart'),
      ], delay: const Duration(milliseconds: 30));

      notifier.runSearch('جارٍ');
      expect(notifier.state.isSearching, isTrue);

      notifier.clearSearch();
      expect(notifier.state.searchQuery, '');
      expect(notifier.state.isSearching, isFalse);
      expect(notifier.state.searchResults, isEmpty);
      expect(repo.lastSearchToken?.isCancelled, isTrue);

      await pending;
      await pumpEventQueue();
      expect(notifier.state.searchResults, isEmpty);
    });

    test('dispose cancels the tree, search and every children request', () async {
      final repo = _FakeTreeRepo(tree: const []);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      final treeToken = repo.lastTreeToken!;
      repo.armSearch('بحث', const [], delay: const Duration(milliseconds: 50));
      notifier.runSearch('بحث');
      final searchToken = repo.lastSearchToken!;

      notifier.dispose();

      expect(treeToken.isCancelled, isTrue);
      expect(searchToken.isCancelled, isTrue);
      expect(notifier.mounted, isFalse);
    });

    test('findById walks the loaded skeleton only', () async {
      final group = groupNode();
      final root = AccountTreeNode(
        id: 'acc_1',
        name: 'الأمانة',
        level: 'account',
        hasChildren: true,
        children: [
          AccountTreeNode(
            id: 'main_12',
            name: 'فرع',
            level: 'main',
            hasChildren: true,
            children: [group],
          ),
        ],
      );
      final repo = _FakeTreeRepo(tree: [root]);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      expect(notifier.findById('group_3')?.name, 'موظفون');
      expect(notifier.findById('acc_1')?.level, 'account');
      expect(notifier.findById('missing'), isNull);
      // الحالة الخاصة بها تملك التمشية نفسها (لا نسخة ثانية في الـ notifier)
      expect(notifier.state.findById('group_3')?.groupId, 3);
    });

    test('expandToLevel opens structural levels without touching leaves',
        () async {
      final group = groupNode();
      final sub = AccountTreeNode(
        id: 'sub_1291',
        name: 'جزئي',
        level: 'sub',
        accPart: 1291,
        hasChildren: true,
        children: [group],
      );
      final main = AccountTreeNode(
        id: 'main_12',
        name: 'فرع',
        level: 'main',
        hasChildren: true,
        children: [sub],
      );
      final root = AccountTreeNode(
        id: 'acc_1',
        name: 'قسم',
        level: 'account',
        hasChildren: true,
        children: [main],
      );
      final repo = _FakeTreeRepo(tree: [root]);
      final notifier = AccountTreeNotifier(repo);
      await notifier.loadTree();

      await notifier.expandToLevel(2);

      expect(notifier.state.expanded, containsAll(['acc_1', 'main_12', 'sub_1291']));
      expect(notifier.state.expanded, isNot(contains('group_3')));
      expect(notifier.state.childrenLoaded('sub_1291'), isFalse);
    });
  });
}

/// Repository stub extending the real one: the tree, children and search verbs are
/// answered from memory, with optional latency so the race and cancel paths run.
class _FakeTreeRepo extends AccountRepository {
  _FakeTreeRepo({
    required List<AccountTreeNode> tree,
    Map<int, List<AccountLeafModel>> pages = const {},
    this.treeFailure,
    this.childrenFailure,
  }) : _tree = tree,
       _pages = pages.isEmpty
           ? const {
               1: [
                 AccountLeafModel(accNo: 1, accName: 'أول'),
                 AccountLeafModel(accNo: 2, accName: 'ثانٍ'),
               ],
               2: [AccountLeafModel(accNo: 3, accName: 'ثالث')],
             }
           : pages,
       super(
         client: DioClient(
           storage: SecureStorageService(),
           baseUrl: 'http://127.0.0.1',
         ),
       );

  final List<AccountTreeNode> _tree;
  final Map<int, List<AccountLeafModel>> _pages;
  final String? treeFailure;
  final String? childrenFailure;

  int treeCalls = 0;
  int childrenCalls = 0;
  CancelToken? lastTreeToken;
  CancelToken? lastSearchToken;
  String? lastFromDate;
  String? lastToDate;
  String? lastChildrenLevel;
  int? lastChildrenGroupId;
  int? lastChildrenAccPart;
  int lastChildrenPage = 0;

  /// نتائج بحث مؤجَّلة زمنياً حتى يُختبر حارس السباق بترتيب وصول معكوس.
  final Map<String, List<AccountTreeNode>> _plannedSearch = {};
  final Map<String, Duration> _searchDelay = {};

  Future<void> armSearch(String query, List<AccountTreeNode> results, {Duration delay = Duration.zero}) {
    _plannedSearch[query] = results;
    _searchDelay[query] = delay;
    return Future<void>.delayed(delay * 2);
  }

  @override
  Future<List<AccountTreeNode>> fetchAccountTree({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    treeCalls++;
    lastTreeToken = cancelToken;
    lastFromDate = fromDate;
    lastToDate = toDate;
    await Future<void>.delayed(Duration.zero);
    if (cancelToken != null && cancelToken.isCancelled) {
      throw DioException(
        requestOptions: RequestOptions(path: '/accounts/tree'),
        type: DioExceptionType.cancel,
      );
    }
    if (treeFailure != null) throw Exception(treeFailure);
    return _tree;
  }

  @override
  Future<TreeChildrenResult> fetchTreeChildren({
    required String level,
    int? groupId,
    int? accPart,
    String search = '',
    String sort = 'acc_no',
    String dir = 'asc',
    int page = 1,
    int limit = 50,
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    childrenCalls++;
    lastChildrenLevel = level;
    lastChildrenGroupId = groupId;
    lastChildrenAccPart = accPart;
    lastChildrenPage = page;
    await Future<void>.delayed(Duration.zero);
    if (childrenFailure != null) throw Exception(childrenFailure);
    final leaves = _pages[page] ?? const <AccountLeafModel>[];
    return TreeChildrenResult(
      leaves: leaves,
      total: 60,
      page: page,
      limit: limit,
      totalPages: 30,
      hasMore: page < 2,
    );
  }

  @override
  Future<List<AccountTreeNode>> searchAccounts(
    String query, {
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    lastSearchToken = cancelToken;
    final delay = _searchDelay[query] ?? Duration.zero;
    await Future<void>.delayed(delay);
    if (cancelToken != null && cancelToken.isCancelled) {
      throw DioException(
        requestOptions: RequestOptions(path: '/accounts/search'),
        type: DioExceptionType.cancel,
      );
    }
    return _plannedSearch[query] ?? const [];
  }
}
