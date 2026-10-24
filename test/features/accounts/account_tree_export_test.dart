import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/data/models/tree_export_row_model.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:ky_apps/features/accounts/presentation/screens/account_tree_screen.dart';
import 'package:ky_apps/features/accounts/presentation/utils/account_tree_flatten.dart';
import 'package:ky_apps/features/accounts/presentation/utils/tree_export_adapter.dart';
import 'package:ky_apps/features/accounts/presentation/utils/tree_row_layout.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_tree_row_tile.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/tree_export_menu.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// اختبارات نطاق الطباعة/التصدير وقياسات السطر.
/// Covers the two defects the fix targeted:
///  * export used to serialize the visible scroll position, so a collapsed tree
///    printed its section headers only — the scope is now a request, and the rows
///    come back from the server;
///  * the row hardcoded its pixel chrome, so the account name lost its space and
///    ellipsized — the metrics now resolve once and are shared with the header.

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _stateWith(List<String> codes) =>
    AuthState(isAuthenticated: true, isAdmin: false).withPermissions(
      PermissionSnapshot(userId: 2, isAdmin: false, permissions: codes),
    );

/// هيكل من مستويين: قسم ومجموعته. التوسيع الكلّي لا يُظهر الابن إلا بعد الفتح.
const AccountTreeNode _group = AccountTreeNode(
  id: 'group_3',
  name: 'موظفون',
  level: 'group',
  groupId: 3,
  accPart: 1291,
  hasChildren: true,
  balance: 800,
);

const AccountTreeNode _section = AccountTreeNode(
  id: 'acc_1',
  name: 'قسم الأمانة',
  level: 'account',
  accNo: 1,
  balance: 800,
  hasChildren: true,
  children: [_group],
);

/// صفوف خادم نموذجية: قسم هيكلي ثم ورقة مالية تحتة.
List<TreeExportRow> _serverRows() => const [
  TreeExportRow(
    depth: 0,
    level: 'account',
    code: '1',
    accNo: 1,
    name: 'قسم الأمانة',
    parentPath: '',
    codePath: '1',
    debit: 900,
    credit: 100,
    balance: 800,
    movements: 12,
    childrenCount: 3,
    accountCount: 108,
    rootAccNo: 1,
  ),
  TreeExportRow(
    depth: 3,
    level: 'chart',
    code: '12310001',
    accNo: 12310001,
    name: 'موظف تجريبي',
    parentPath: 'قسم الأمانة / موظفون',
    codePath: '1.12.1291.12310001',
    debit: 500,
    credit: 0,
    balance: 500,
    movements: 7,
    storedBalance: 480,
    curNo: 2,
    rootAccNo: 1,
  ),
];

class _FakeExportRepo extends AccountRepository {
  _FakeExportRepo({this.exportRows = const [], this.exportFailure})
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  final List<TreeExportRow> exportRows;
  final String? exportFailure;

  int exportCalls = 0;
  TreeExportScope? lastScope;

  @override
  Future<List<AccountTreeNode>> fetchAccountTree({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return const [_section];
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
    await Future<void>.delayed(Duration.zero);
    return TreeChildrenResult(
      leaves: const [
        AccountLeafModel(accNo: 12310001, accName: 'موظف تجريبي', net: 500),
      ],
      total: 1,
      page: page,
      limit: limit,
      totalPages: 1,
      hasMore: false,
    );
  }

  @override
  Future<List<TreeExportRow>> fetchTreeExport(
    TreeExportScope scope, {
    CancelToken? cancelToken,
  }) async {
    exportCalls++;
    lastScope = scope;
    await Future<void>.delayed(Duration.zero);
    // فشل حقيقي كالذي يرد من الـ API: DioException بجسم فيه رسالة عربية،
    // لأن القائمة تعرض رسالة الخادم نفسها بدل نصها العام.
    if (exportFailure != null) {
      final options = RequestOptions(path: '/accounts/export-tree');
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 403,
          data: {'success': false, 'message': exportFailure},
        ),
      );
    }
    return exportRows;
  }
}

/// قائمة القسم في شريط الفلاتر.
/// The section dropdown, identified by its «كل الأقسام» item: DropdownButton shows
/// the item whose value matches a null [value] instead of its hint, so the hint
/// text is never in the tree while the filter is inactive.
final Finder _sectionDropdown = find.byWidgetPredicate((w) {
  if (w is! DropdownButton<int?>) return false;
  final items = w.items;
  if (items == null) return false;
  return items.any(
    (i) => i.child is Text && (i.child as Text).data == 'كل الأقسام',
  );
});

Future<void> _pumpTree(
  WidgetTester tester, {
  required AccountRepository repo,
  Size surface = const Size(1200, 900),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(_stateWith(const ['accounts.view', 'accounts.export', 'accounts.print'])),
        ),
        accountRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(locale: Locale('ar'), home: AccountTreeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// فتح القائمة ثم اختيار الطباعة: تُعرض نافذة النطاق قبل أي طلب.
Future<void> _openScopeSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.ios_share_rounded));
  await tester.pumpAndSettle();
  await tester.tap(find.text('طباعة الشجرة'));
  await tester.pumpAndSettle();
}

void main() {
  group('TreeExportScope', () {
    test('the default scope is every level, not the section headers', () {
      // الشكوى الأصلية: المطبوعة كانت بالحسابات الرئيسة فقط.
      expect(TreeExportScope.all.levels, TreeExportLevel.values);
      expect(TreeExportScope.all.includeCustomers, isFalse);
    });

    test('toQuery sends the level codes the server understands', () {
      const scope = TreeExportScope(
        levels: [TreeExportLevel.account, TreeExportLevel.chart],
        sectionAccNo: 123,
        includeCustomers: true,
        hideZeroBalances: true,
      );
      expect(scope.toQuery(), {
        'levels': 'account,chart',
        'section': 123,
        'include_customers': '1',
        'hide_zero': '1',
      });
    });

    test('customers only count when the ledger level is present', () {
      // حسابات العملاء أوراق في CHART_ACC: بلا المستوى لا معنى للتضمين.
      const withLeaves = TreeExportScope(
        levels: [TreeExportLevel.chart],
        includeCustomers: true,
      );
      const withoutLeaves = TreeExportScope(
        levels: [TreeExportLevel.account],
        includeCustomers: true,
      );
      expect(withLeaves.containsCustomers, isTrue);
      expect(withoutLeaves.containsCustomers, isFalse);
    });

    test('describe() states what the printed page contains', () {
      const scope = TreeExportScope(
        levels: [TreeExportLevel.account, TreeExportLevel.main],
        sectionAccNo: 5,
        hideZeroBalances: true,
      );
      final text = scope.describe();
      expect(text, contains('الحسابات الرئيسة'));
      expect(text, contains('القسم 5'));
      expect(text, contains('الأرصدة الصفرية'));
    });
  });

  group('TreeExportRow', () {
    test('reads uppercase Oracle keys and numeric strings alike', () {
      // نفس دفاع بقية النماذج: الأرقام تصل أحياناً نصوصاً والمفاتيح بأحرف كبيرة.
      final row = TreeExportRow.fromJson(const {
        'DEPTH': '2',
        'LEVEL': 'chart',
        'CODE': '12310001',
        'ACC_NO': '12310001',
        'NAME': 'موظف',
        'BALANCE': '1500.5',
        'MOVEMENTS': '9',
        'CUR_NO': '2',
        'ROOT_ACC_NO': '123',
      });
      expect(row.depth, 2);
      expect(row.accNo, 12310001);
      expect(row.balance, 1500.5);
      expect(row.movements, 9);
      expect(row.curNo, 2);
      expect(row.rootAccNo, 123);
      expect(row.isLedger, isTrue);
      expect(row.levelLabel, 'حساب');
    });

    test('root_acc_no survives where acc_no is the ledger number', () {
      // عند مستوى الأوراق acc_no رقم الحساب لا رقم القسم — فالفلترة على root.
      final row = TreeExportRow.fromJson(const {
        'level': 'chart',
        'code': '11010001',
        'acc_no': '11010001',
        'name': 'نقدية بالصندوق',
        'root_acc_no': 1,
      });
      expect(row.accNo, 11010001);
      expect(row.rootAccNo, 1);
    });
  });

  group('treeExportRowsToDisplay', () {
    test('maps structural rows and leaves onto one display type', () {
      final rows = treeExportRowsToDisplay(_serverRows());
      expect(rows, hasLength(2));

      final section = rows.first.node!;
      expect(section.level, 'account');
      expect(section.childrenCount, 3);
      expect(section.accountCount, 108);

      final leaf = rows.last.leaf!;
      expect(leaf.accNo, 12310001);
      expect(leaf.net, 500);
      expect(leaf.parentPath, 'قسم الأمانة / موظفون');
    });

    test('drops a nameless row instead of printing a blank line', () {
      final rows = treeExportRowsToDisplay(const [
        TreeExportRow(
          depth: 0,
          level: 'account',
          code: '9',
          name: '',
          debit: 0,
          credit: 0,
          balance: 0,
          movements: 0,
        ),
      ]);
      expect(rows, isEmpty);
    });

    test('the footer summary quotes the server level counts', () {
      final text = describeTreeExport(
        scope: TreeExportScope.all,
        totalRows: 2,
        levelCounts: const {'account': 1, 'chart': 1},
      );
      expect(text, contains('الحسابات الرئيسة: 1'));
      expect(text, contains('الحسابات المالية: 1'));
      expect(text, contains('إجمالي الصفوف: 2'));
    });
  });

  group('TreeRowMetrics', () {
    test('the name keeps its floor at every density on a narrow phone', () {
      // كان الاسم يُقصّ على الهاتف: القياسات تُطفئ الاختياري حتى يبلغ الاسم أرضيته.
      for (final width in [320.0, 360.0, 420.0, 600.0]) {
        for (final density in TreeDensity.values) {
          final m = TreeRowMetrics.resolve(width: width, density: density);
          expect(
            m.nameW,
            greaterThanOrEqualTo(96),
            reason: 'width $width / ${density.name} left only ${m.nameW}px for the name',
          );
        }
      }
    });

    test('extra columns appear only when there is room for them', () {
      final phone = TreeRowMetrics.resolve(width: 400, density: TreeDensity.compact);
      final tablet = TreeRowMetrics.resolve(width: 900, density: TreeDensity.compact);
      expect(phone.showColumns, isFalse);
      expect(phone.showBadge, isFalse);
      expect(tablet.showColumns, isTrue);
      expect(tablet.showBadge, isTrue);
    });

    test('the action slot fits three buttons so the balance column stays put', () {
      // فتحة ثابتة لثلاثة أزرار: سطر بزرّ وسطر بثلاثة يرصّان الرصيد في العمود نفسه.
      final m = TreeRowMetrics.resolve(width: 1280, density: TreeDensity.standard);
      expect(m.showActions, isTrue);
      expect(m.actionsW, greaterThanOrEqualTo(m.actionSide * 3));
      expect(m.badgeW, greaterThan(0));
    });

    testWidgets('status rows survive every density — the 52px clamp crash', (
      tester,
    ) async {
      // العطل الذي أبلغ عنه المستخدم: «Invalid argument: 52» لحظة النقر على زر
      // فتح/إغلاق ظهور الحسابات الفرعية. ما ينهار ليس صفوف الحساب بل **صفوف الحالة**
      // (جارٍ التحميل / تحميل المزيد / خطأ) — وهي الوحيدة التي تظهر وقت التوسيع،
      // وكان ارتفاعها `clamp(metrics.height, 46)`: على الكثافة الواسعة يصبح الحد
      // الأدنى 52 والأعلى 46، و`num.clamp` يرمي ArgumentError عندئذٍ.
      // Status rows are what a click on expand-all renders, and the old
      // clamp(metrics.height, 46) threw once the density grew past the cap.
      for (final density in TreeDensity.values) {
        final metrics = TreeRowMetrics.resolve(width: 420, density: density);
        for (final row in [
          AccountTreeRow.loading(hostId: 'account:1', depth: 1),
          AccountTreeRow.loadMore(hostId: 'account:1', depth: 1),
          AccountTreeRow.rowError(hostId: 'account:1', depth: 1),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('ar'),
              home: Scaffold(body: AccountTreeRowTile(row: row, metrics: metrics)),
            ),
          );
          await tester.pumpAndSettle();

          // لا استثناء، والطول لا يقلّ عن كثافة الصفوف التي يليها.
          expect(
            tester.takeException(),
            isNull,
            reason: '${density.name} / ${row.kind.name}',
          );
          expect(
            tester.getSize(find.byType(AccountTreeRowTile)).height,
            greaterThanOrEqualTo(density.height),
            reason: '${density.name} / ${row.kind.name}',
          );
        }
      }
    });

    test('densities differ in height and font, smallest first', () {
      // ترتيب الإعلان هو ترتيب الكثافة: أصغر → أكبر، بلا مفاجأة في القائمة.
      final heights = TreeDensity.values.map((d) => d.height).toList();
      for (var i = 1; i < heights.length; i++) {
        expect(
          heights[i],
          greaterThan(heights[i - 1]),
          reason: '${TreeDensity.values[i].name} after ${TreeDensity.values[i - 1].name}',
        );
      }
      expect(TreeDensity.ultra.height, lessThan(TreeDensity.relaxed.height));
      expect(TreeDensity.fromCompact(true), TreeDensity.compact);
    });
  });

  group('export scope sheet on the tree screen', () {
    testWidgets('exporting asks for a scope instead of reading the screen', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      // الشجرة مغلقة: ما على الشاشة سطر واحد، ومع ذلك لم يُطلب أي شيء بعد.
      expect(find.byType(TreeExportMenu), findsOneWidget);
      expect(repo.exportCalls, 0);

      await _openScopeSheet(tester);
      expect(find.text('نطاق الطباعة والتصدير'), findsOneWidget);
      expect(find.text('الحسابات المالية'), findsOneWidget);
      expect(repo.exportCalls, 0); // لا طلب قبل التأكيد

      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(repo.exportCalls, 1);
      expect(repo.lastScope!.levels, TreeExportLevel.values);
    });

    testWidgets('the section filtered on screen seeds the sheet', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      // فلترة القسم على الشاشة…
      // الحقل يعرض «كل الأقسام» (العنصر ذي القيمة الفارغة) لا تلميح «القسم»،
      // فتُعرَّف القائمة المنسدلة بقيمة عناصرها لا بتلميح الاسم.
      await tester.tap(_sectionDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 — قسم الأمانة').last);
      await tester.pumpAndSettle();

      await _openScopeSheet(tester);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      // …ينتقل كنطاق مبدئي، مع أن المستخدم يظل يغيّره في النافذة.
      expect(repo.lastScope!.sectionAccNo, 1);
    });

    testWidgets('unchecking a level leaves it out of the request', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);
      await _openScopeSheet(tester);

      await tester.tap(find.text('المجموعات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(repo.lastScope!.levels, isNot(contains(TreeExportLevel.group)));
      expect(repo.lastScope!.levels, hasLength(TreeExportLevel.values.length - 1));
    });

    testWidgets('cancelling the sheet sends no request', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      await _openScopeSheet(tester);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(repo.exportCalls, 0);
    });

    testWidgets('a server refusal is shown, not swallowed', (tester) async {
      // رفض الخادم (صلاحية/خطأ) كان سينتهي بصمت أو باستثناء: رسالة الخادم
      // العربية هي ما يصل المستخدم، ولا يُفتح أي ملف.
      final repo = _FakeExportRepo(
        exportFailure: 'لا تملك صلاحية تصدير الشجرة المحاسبية',
      );
      await _pumpTree(tester, repo: repo);
      await _openScopeSheet(tester);
      await tester.tap(find.text('تأكيد'));
      await tester.pumpAndSettle();

      expect(repo.exportCalls, 1);
      expect(
        find.text('لا تملك صلاحية تصدير الشجرة المحاسبية'),
        findsOneWidget,
      );
      expect(find.text('نطاق الطباعة والتصدير'), findsNothing);
    });
  });

  group('open/collapse of sub-accounts', () {
    testWidgets('the app bar toggle opens every branch and closes them again', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      // مغلق: سطر القسم وحده، والزر يدعو لفتح الأبناء.
      // By tooltip, not by icon: the filters bar carries the same unfold icon.
      expect(find.text('قسم الأمانة'), findsOneWidget);
      expect(find.byTooltip('فتح ظهور الحسابات الفرعية'), findsOneWidget);

      await tester.tap(find.byTooltip('فتح ظهور الحسابات الفرعية'));
      await tester.pumpAndSettle();

      // مفتوح: الفروع المحمّلة تظهر والزر ينقلب إلى إغلاق.
      expect(find.text('موظفون'), findsOneWidget);
      expect(find.byTooltip('إغلاق ظهور الحسابات الفرعية'), findsOneWidget);

      await tester.tap(find.byTooltip('إغلاق ظهور الحسابات الفرعية'));
      await tester.pumpAndSettle();
      expect(find.text('موظفون'), findsNothing);
      expect(find.byTooltip('فتح ظهور الحسابات الفرعية'), findsOneWidget);
    });

    testWidgets('each expandable row carries its own open/close handle', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      await tester.tap(find.byTooltip('فتح ظهور الحسابات الفرعية'));
      await tester.pumpAndSettle();

      // مقبض لكل عقدة فيها أبناء: التوسيع لم يعد معلقاً على نقر الصف وحده.
      expect(find.byTooltip('إخفاء الحسابات الفرعية'), findsWidgets);
    });

    testWidgets('the density sheet offers all five sizes and the pick resizes rows', (tester) async {
      final repo = _FakeExportRepo(exportRows: _serverRows());
      await _pumpTree(tester, repo: repo);

      await tester.tap(find.byTooltip('خيارات العرض'));
      await tester.pumpAndSettle();
      for (final density in TreeDensity.values) {
        expect(find.text(density.labelAr), findsOneWidget, reason: density.name);
      }

      await tester.tap(find.text(TreeDensity.relaxed.labelAr));
      await tester.pumpAndSettle();

      // الاختيار يغيّر ارتفاع السطر فعلاً، لا اسمه فقط.
      final size = tester.getSize(find.byType(AccountTreeRowTile).first);
      expect(size.height, TreeDensity.relaxed.height);
    });
  });
}
