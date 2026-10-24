import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:ky_apps/features/accounts/presentation/screens/account_tree_screen.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_tree_row_tile.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/tree_export_menu.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// اختبار شاشة الشجرة المعاد بناؤها: قائمة مسطّحة واحدة، توسيع كسول يجلب صفحة
/// أبناء، زر الكشف حسب الصلاحية، وقائمة التصدير حسب الصلاحية.
/// Rebuilt tree screen: one flat ListView, expansion that pulls a page of leaves,
/// the per-row reveal button gated by permission, and the export menu gated too.
/// Dio is stubbed at the repository seam.

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _stateWith(List<String> codes, {bool isAdmin = false}) =>
    AuthState(isAuthenticated: true, isAdmin: isAdmin).withPermissions(
      PermissionSnapshot(
        userId: isAdmin ? 1 : 2,
        isAdmin: isAdmin,
        permissions: codes,
      ),
    );

AccountTreeNode _group() => const AccountTreeNode(
  id: 'group_3',
  name: 'موظفون',
  level: 'group',
  groupId: 3,
  accPart: 1291,
  accountCount: 108,
  hasChildren: true,
  debit: 900,
  credit: 100,
  balance: 800,
  movements: 12,
);

AccountTreeNode _root() => AccountTreeNode(
  id: 'acc_1',
  name: 'قسم الأمانة',
  level: 'account',
  accNo: 1,
  balance: 800,
  hasChildren: true,
  children: [_group()],
);

/// Stub repository: skeleton, one page of leaves, and search — all canned.
class _FakeTreeRepo extends AccountRepository {
  _FakeTreeRepo({this.tree = const [], this.treeFailure})
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  final List<AccountTreeNode> tree;
  final String? treeFailure;

  int childrenCalls = 0;
  String? lastChildrenLevel;

  @override
  Future<List<AccountTreeNode>> fetchAccountTree({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (treeFailure != null) throw Exception(treeFailure);
    return tree;
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
    await Future<void>.delayed(Duration.zero);
    return TreeChildrenResult(
      leaves: const [
        AccountLeafModel(accNo: 12910001, accName: 'موظف تجريبي', net: 800),
      ],
      total: 108,
      page: page,
      limit: limit,
      totalPages: 3,
      hasMore: page < 3,
    );
  }

  @override
  Future<List<AccountTreeNode>> searchAccounts(
    String query, {
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return const [
      AccountTreeNode(
        id: 'chart_11010001',
        name: 'نقدية بالصندوق',
        level: 'chart',
        accNo: 11010001,
        parentPath: 'الأصول / النقدية',
        balance: 42,
      ),
    ];
  }
}

Future<_Harness> _pumpTree(
  WidgetTester tester, {
  required AccountRepository repo,
  required List<String> codes,
  bool isAdmin = false,
  Size surface = const Size(1200, 900),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(_stateWith(codes, isAdmin: isAdmin))),
        accountRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(locale: Locale('ar'), home: AccountTreeScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(tester, repo);
}

class _Harness {
  _Harness(this.tester, this.repo);
  final WidgetTester tester;
  final AccountRepository repo;

  /// فتح سطر هيكلي بالنقر على اسمه.
  /// Tapping a row: the row also carries a double-tap-to-reveal gesture, so Flutter
  /// holds the single tap until the double-tap window (300ms) expires. Pumping past it
  /// is what a real user waits through — `pumpAndSettle()` alone returns too early.
  Future<void> expand(String label) async {
    await tester.tap(find.text(label).first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('AccountTreeScreen', () {
    testWidgets('renders one flat ListView of compact structural rows', (tester) async {
      await _pumpTree(tester, repo: _FakeTreeRepo(tree: [_root()]), codes: const ['accounts.view']);

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('الشجرة المحاسبية'), findsOneWidget);
      expect(find.text('قسم الأمانة'), findsOneWidget);
      // لم يُفتح الأب بعد: عقدة الابن غير موجودة في القائمة المسطّحة
      expect(find.text('موظفون'), findsNothing);
      expect(find.byType(AccountTreeRowTile), findsOneWidget);
    });

    testWidgets('expanding a group lazily fetches its leaves', (tester) async {
      final repo = _FakeTreeRepo(tree: [_root()]);
      final h = await _pumpTree(tester, repo: repo, codes: const ['accounts.view']);

      await h.expand('قسم الأمانة');
      expect(find.text('موظفون'), findsOneWidget);
      expect(repo.childrenCalls, 0); // المجموعة لم تُفتح بعد

      await h.expand('موظفون');
      expect(repo.childrenCalls, 1);
      expect(repo.lastChildrenLevel, 'group');
      expect(find.text('موظف تجريبي'), findsOneWidget);
    });

    testWidgets('group grant reveals structural rows only', (tester) async {
      // صلاحية كشف المجموعات: عين لكل سطر هيكلي، ولا عين للورقة المالية
      final repo = _FakeTreeRepo(tree: [_root()]);
      final h = await _pumpTree(
        tester,
        repo: repo,
        codes: const ['accounts.view', 'accounts.statement_group'],
      );

      // مغلق: سطر القسم وحده ⇒ عين واحدة
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsOneWidget);

      await h.expand('قسم الأمانة');
      // القسم والمجموعة سطران هيكليان ⇒ عينان، والورقة لم تُحمَّل بعد
      expect(find.text('موظفون'), findsOneWidget);
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNWidgets(2));
      expect(repo.childrenCalls, 0);

      await h.expand('موظفون');
      // الورقة تحتاج accounts.statement_financial ⇒ سطر بلا عين
      expect(find.text('موظف تجريبي'), findsOneWidget);
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNWidgets(2));
    });

    testWidgets('financial grant reveals leaves only, not structure', (tester) async {
      final repo = _FakeTreeRepo(tree: [_root()]);
      final h = await _pumpTree(
        tester,
        repo: repo,
        codes: const ['accounts.view', 'accounts.statement_financial'],
      );

      await h.expand('قسم الأمانة');
      // الأسطر الهيكلية لا تملك كشف المجموعات ⇒ لا أزرار كشف إطلاقاً
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNothing);

      await h.expand('موظفون');
      expect(find.text('موظف تجريبي'), findsOneWidget);
      // الورقة المالية وحدها لها زر الكشف
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsOneWidget);
      // بلا accounts.export / accounts.print لا قائمة تصدير إطلاقاً
      expect(find.byType(TreeExportMenu), findsNothing);
      expect(find.byIcon(Icons.ios_share_rounded), findsNothing);
    });

    testWidgets('export menu renders with the export grant', (tester) async {
      await _pumpTree(
        tester,
        repo: _FakeTreeRepo(tree: [_root()]),
        codes: const ['accounts.view', 'accounts.export'],
      );

      expect(find.byType(TreeExportMenu), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    });

    testWidgets('admin bypass reveals every row type', (tester) async {
      final repo = _FakeTreeRepo(tree: [_root()]);
      final h = await _pumpTree(tester, repo: repo, codes: const [], isAdmin: true);

      // الإدارة ترى قائمة التصدير بلا صلاحية صريحة، ثم لكل سطر زر كشف
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);

      await h.expand('قسم الأمانة');
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNWidgets(2));

      await h.expand('موظفون');
      // القسم + المجموعة + الورقة المالية — الجميع قابل للكشف للإدارة
      expect(find.text('موظف تجريبي'), findsOneWidget);
      expect(find.byIcon(Icons.remove_red_eye_rounded), findsNWidgets(3));
    });

    testWidgets('empty skeleton and error states are distinct', (tester) async {
      await _pumpTree(tester, repo: _FakeTreeRepo(), codes: const ['accounts.view']);
      expect(find.text('لا توجد حسابات في الهيكل'), findsOneWidget);

      final failing = _FakeTreeRepo(treeFailure: 'تعذّر الوصول للخادم');
      await _pumpTree(tester, repo: failing, codes: const ['accounts.view']);
      expect(find.text('إعادة المحاولة'), findsWidgets);
    });

    testWidgets('server search replaces the tree with flat results', (tester) async {
      final repo = _FakeTreeRepo(tree: [_root()]);
      await _pumpTree(tester, repo: repo, codes: const ['accounts.view']);

      await tester.enterText(find.byType(TextField).first, 'نقدية');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('نقدية بالصندوق'), findsOneWidget);
      expect(find.text('قسم الأمانة'), findsNothing);
    });
  });
}
