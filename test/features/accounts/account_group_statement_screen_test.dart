import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/models/account_group_statement_model.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:ky_apps/features/accounts/presentation/screens/account_group_statement_screen.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_group_statement_report_table.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/tree_export_menu.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// Notifier stub: `build()` returns the pre-set state so no secure-storage or
/// Dio call is made — same pattern as the admin/responsive widget tests.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _adminState() =>
    const AuthState(isAuthenticated: true).withPermissions(
      const PermissionSnapshot(
          userId: 1, isAdmin: true, permissions: <String>[]),
    );

/// Repository stub extending the real one so un-overridden members fall back
/// to their real (unreached) behaviour.
///
/// يحاكي الخادم فعلياً: `scopeRows` هو عدد صفوف النطاق كاملاً، و`limit` سقفه
/// `pageSize`. بهذا تختبر الشاشة ترقيماً حقيقياً — التحميل التدريجي وحدّ
/// الـ2000 — لا مجرد استجابة ثابتة.
/// Acts as a tiny paging server: `scopeRows` is the whole scope, `limit` is
/// capped at `pageSize`, so the screen's chunking and the 2000-row cap are
/// exercised for real instead of against a canned reply.
class _FakeRepo extends AccountRepository {
  _FakeRepo({this.scopeRows = 1})
      : super(
          client: DioClient(
            storage: SecureStorageService(),
            baseUrl: 'http://127.0.0.1',
          ),
        );

  /// سقف الصفحة الواحدة كما على الخادم (AccountController::getGroupStatement).
  /// Per-page cap, mirroring the server's own ceiling.
  static const int pageSize = 1000;

  /// عدد صفوف النطاق كاملاً / rows in the whole scope.
  final int scopeRows;

  /// كم طلباً وصل للخادم، وبأي حدّ — يثبت أن الشاشة تُرقّم لا تجلب الكل.
  int statementCalls = 0;
  final List<int?> requestedLimits = <int?>[];

  /// عند تعيينه: الصفحات بعد الأولى تنتظر فكّه — به نلتقط حالة «التدريج»
  /// بينما القسم التالي في الطريق. `Completer` لا `Future.delayed`: الزمن
  /// المُصطنع في الاختبار يُقدَّم تلقائياً فتُفلت أي مهلة زمنية.
  /// When set, pages after the first wait for it, so the streaming state can be
  /// observed mid-flight. A Completer, not a delay — test time is advanced
  /// automatically, so any duration would elapse before the assertion.
  Completer<void>? gate;

  @override
  Future<List<AccountModel>> fetchAccounts({CancelToken? cancelToken}) async =>
      const [AccountModel(accNo: 5, accName: 'قسم الأمانة')];

  @override
  Future<List<AccMainModel>> fetchAccMain(
          {int? accNo, CancelToken? cancelToken}) async =>
      const [AccMainModel(accNo: 5, accSub: 12, subName: 'حسابات فرعية')];

  @override
  Future<List<AccSubModel>> fetchAccSub(
          {int? accSub, CancelToken? cancelToken}) async =>
      const [AccSubModel(accSub: 12, accPart: 1291, partName: 'حساب جزئي')];

  @override
  Future<List<AccSubGroupModel>> fetchAccSubGroup(
          {int? accPart, CancelToken? cancelToken}) async =>
      const [
        AccSubGroupModel(groupId: 44, accPart: 1291, accGroupName: 'مجموعة 1')
      ];

  @override
  Future<TrialBalanceReport> fetchGroupStatement({
    int? accNo,
    int? accSub,
    int? accPart,
    int? groupId,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
    bool includeTotals = true,
    CancelToken? cancelToken,
  }) async {
    final pageNo = page ?? 1;
    if (pageNo > 1 && gate != null) await gate!.future;

    // يُعدّ بعد البوابة: العدّاد يعني «استجابة سُلّمت» لا «طلب بدأ».
    // Counted after the gate: the counter means "response served", not "started".
    statementCalls++;
    requestedLimits.add(limit);

    // `null` يعني «بلا ترقيم» — كل الصفوف، كما يفعل الخادم (limit=0).
    // null means unpaginated, exactly like the server's limit=0.
    final effective = (limit == null || limit <= 0)
        ? (scopeRows > 0 ? scopeRows : 1)
        : (limit > pageSize ? pageSize : limit);
    final from = (pageNo - 1) * effective;
    final to = from + effective > scopeRows ? scopeRows : from + effective;

    return TrialBalanceReport(
      scopeLevel: 'group',
      scopeLabel: 'مجموعة 1',
      asOfDate: '21/10/2026',
      rows: [
        for (var i = from; i < to; i++)
          TrialBalanceRow(
            accNo: 12910217 + i,
            accName: 'موظف تجريبي',
            curCode: 'YR',
            localDebit: 100,
            localCredit: 50,
            foreignDebit: 0,
            foreignCredit: 0,
            balance: 50,
            periodBalance: 50,
          ),
      ],
      totals: const TrialBalanceTotals(
        localDebit: 100,
        localCredit: 50,
        foreignDebit: 0,
        foreignCredit: 0,
        balance: 50,
      ),
      total: scopeRows,
      page: pageNo,
      limit: effective,
      totalPages: effective > 0 ? (scopeRows / effective).ceil() : 1,
      hasMore: to < scopeRows,
    );
  }
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AccountRepository repo,
  Duration fetchDelay = Duration.zero,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider
            .overrideWith(() => _StubAuthNotifier(_adminState())),
        accountRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: AccountGroupStatementScreen(fetchDelay: fetchDelay),
      ),
    ),
  );

  if (fetchDelay == Duration.zero) {
    await tester.pumpAndSettle();
    return;
  }

  // مع مهلة حقيقية: `pumpAndSettle` يقدّم الساعة فيُطلق المؤقّت ويكفي أن
  // تتوقف عند حالة الانتظار — لذا نُقدّم إطارات بلا زمن.
  // With a real quiet period, `pumpAndSettle` advances the clock and fires the
  // timer; pump frames without elapsed time so the screen stays in "waiting".
  for (var i = 0; i < 10; i++) {
    await tester.pump();
  }
}

void main() {
  group('AccountGroupStatementScreen', () {
    testWidgets(
        'auto-selects the first main/sub/part and loads the default report',
        (WidgetTester tester) async {
      await _pumpScreen(tester, repo: _FakeRepo());

      // The title appears both in the AppBar and in the loaded report header.
      expect(find.text('كشف حساب مجموعة حسابات جزئية'), findsWidgets);
      // The screen now defaults to the first main → first sub → first part
      // account, so it loads immediately instead of showing the "no scope"
      // placeholder.
      expect(find.text('لم يُختر نطاق بعد'), findsNothing);
      expect(find.text('موظف تجريبي'), findsOneWidget);
      // With data on screen, the shared print/PDF/Excel menu appears.
      expect(find.byType(GroupStatementExportMenu), findsOneWidget);
      expect(find.byIcon(Icons.ios_share_rounded), findsOneWidget);
    });

    testWidgets('collapsible filter bar toggles via the appbar icon',
        (WidgetTester tester) async {
      await _pumpScreen(tester, repo: _FakeRepo());

      // Initially visible: date labels shown.
      expect(find.text('من تاريخ'), findsOneWidget);
      expect(find.text('إلى تاريخ'), findsOneWidget);

      // Tap toggle: hide filters.
      await tester.tap(find.byIcon(Icons.filter_alt));
      await tester.pumpAndSettle();
      expect(find.text('من تاريخ'), findsNothing);
      expect(find.text('إلى تاريخ'), findsNothing);

      // Tap toggle again: show filters.
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      expect(find.text('من تاريخ'), findsOneWidget);
      expect(find.text('إلى تاريخ'), findsOneWidget);
    });

    testWidgets('picking the top-level account triggers the report',
        (WidgetTester tester) async {
      await _pumpScreen(tester, repo: _FakeRepo());

      // The screen already auto-selected the first main + sub. Open the main
      // dropdown by its widget (the first DropdownButtonFormField) and re-pick
      // the fake entry from the menu overlay (`.last` targets the open list).
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 - قسم الأمانة').last);
      await tester.pumpAndSettle();

      // The stub returns a fixed TrialBalanceReport — its row label should now
      // appear inside the trial-balance table, and the export menu shows.
      expect(find.text('موظف تجريبي'), findsOneWidget);
      expect(find.byType(GroupStatementExportMenu), findsOneWidget);
    });

    testWidgets('the shared menu offers print, PDF and Excel', (tester) async {
      await _pumpScreen(tester, repo: _FakeRepo());

      await tester.tap(find.byIcon(Icons.ios_share_rounded));
      await tester.pumpAndSettle();

      // الطباعة من صلاحية الطباعة، وPDF/Excel من صلاحية التصدير — والإدارة تملكهما
      expect(find.text('طباعة الميزان'), findsOneWidget);
      expect(find.text('تصدير PDF'), findsOneWidget);
      expect(find.text('تصدير Excel'), findsOneWidget);
    });
  });

  // ================================================================
  // مهلة الاختيار — لا طلب قبل 3 ثوانٍ من آخر تغيير
  // ================================================================
  group('AccountGroupStatementScreen quiet period', () {
    testWidgets('waits the full 3 seconds before the first request',
        (tester) async {
      final repo = _FakeRepo();
      await _pumpScreen(
        tester,
        repo: repo,
        fetchDelay: AccountGroupStatementScreen.defaultFetchDelay,
      );

      // لم يُطلب شيء بعد — الشاشة تقول إنها تنتظر إكمال الاختيار.
      expect(repo.statementCalls, 0);
      expect(find.text('بانتظار اكتمال اختيارك'), findsOneWidget);

      // 2.9 ثانية: ما زال ينتظر
      await tester.pump(const Duration(milliseconds: 2900));
      expect(repo.statementCalls, 0);

      // 0.2 ثانية أخرى: تجاوزنا الثلاث ثوانٍ → الطلب يُرسل
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(repo.statementCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('a second change restarts the quiet period instead of queuing',
        (tester) async {
      final repo = _FakeRepo();
      await _pumpScreen(
        tester,
        repo: repo,
        fetchDelay: AccountGroupStatementScreen.defaultFetchDelay,
      );

      await tester.pump(const Duration(milliseconds: 2000));
      // تغيير جديد قبل انتهاء المهلة: يبدأ العدّ من جديد
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 - قسم الأمانة').last);
      await tester.pumpAndSettle();

      await tester.pump(const Duration(milliseconds: 2000));
      expect(repo.statementCalls, 0);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.statementCalls, greaterThanOrEqualTo(1));
    });
  });

  // ================================================================
  // الأقسام التدريجية وحدّ الـ2000
  // ================================================================
  group('AccountGroupStatementScreen progressive loading', () {
    testWidgets('appends the remaining chunks page by page', (tester) async {
      final repo = _FakeRepo(scopeRows: 1500);
      final gate = Completer<void>();
      repo.gate = gate;

      await _pumpScreen(tester, repo: repo, fetchDelay: Duration.zero);

      // القسم الأول وحده وصل: 1000 من 1500 وشريط تقدّم ظاهر.
      expect(repo.statementCalls, 1);
      expect(
        find.text('جارٍ عرض الأقسام تدريجياً — 1000 من 1500 حساب'),
        findsOneWidget,
      );

      // فكّ البوابة → القسم الثاني (500) يُضاف ويختفي شريط التقدّم.
      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.statementCalls, 2);
      expect(find.textContaining('جارٍ عرض الأقسام تدريجياً'), findsNothing);
      // الجدول ما زال يعمل بعد الإضافة.
      expect(find.byType(AccountGroupStatementReportTable), findsOneWidget);
    });

    testWidgets('stops at the 2000-row cap and shows the wide-scope banner',
        (tester) async {
      final repo = _FakeRepo(scopeRows: 20774);
      await _pumpScreen(tester, repo: repo);

      // قسم واحد فقط نزل، ولا متابعة تلقائية لنطاق بهذا الحجم.
      expect(repo.statementCalls, 1);
      expect(find.text('النطاق واسع جدًا، اختر مجموعة أدق'), findsOneWidget);
      expect(find.text('تصدير كامل من الخادم'), findsOneWidget);
      expect(find.text('عرض كل الصفوف تدريجياً'), findsOneWidget);
      // لا شريط تقدّم تدريجي: لم نبدأ التنزيل الكامل.
      expect(find.textContaining('جارٍ عرض الأقسام'), findsNothing);
    });

    testWidgets('the full-export button opens the shared export menu',
        (tester) async {
      final repo = _FakeRepo(scopeRows: 20774);
      await _pumpScreen(tester, repo: repo);

      await tester.tap(find.text('تصدير كامل من الخادم'));
      await tester.pumpAndSettle();

      expect(find.text('طباعة الميزان'), findsOneWidget);
      expect(find.text('تصدير Excel'), findsOneWidget);
    });

    testWidgets('"show all" streams the remaining chunks on demand',
        (tester) async {
      final repo = _FakeRepo(scopeRows: 2500);
      await _pumpScreen(tester, repo: repo);

      expect(find.text('النطاق واسع جدًا، اختر مجموعة أدق'), findsOneWidget);
      expect(repo.statementCalls, 1);

      await tester.tap(find.text('عرض كل الصفوف تدريجياً'));
      await tester.pumpAndSettle();

      // ثلاثة أقسام (1000+1000+500) بعد الضغط الصريح
      expect(repo.statementCalls, 3);
      expect(find.text('النطاق واسع جدًا، اختر مجموعة أدق'), findsNothing);
    });
  });

  // ================================================================
  // عمود «رصيد الفترة» — يظهر فقط عند الفلترة بفترة
  // ================================================================
  // The extra «period balance» column must appear only when a period is selected,
  // and the «الرصيد» column must keep showing the account's final balance.
  group('AccountGroupStatementReportTable period column', () {
    const row = TrialBalanceRow(
      accNo: 12910217,
      accName: 'موظف تجريبي',
      curCode: 'YR',
      localDebit: 700.0,
      localCredit: 0.0,
      foreignDebit: 0.0,
      foreignCredit: 0.0,
      balance: 900.0,
      periodBalance: 100.0,
    );

    // الجدول كسول ويحتاج ارتفاعاً معلوماً — لا يُوضع في تمرير غير محدود.
    // The table is lazy: it needs a bounded height, never an unbounded scroll.
    Future<void> pumpTable(WidgetTester tester, TrialBalanceReport report) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: AccountGroupStatementReportTable(report: report),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('hides the period column when no period is selected',
        (tester) async {
      await pumpTable(
        tester,
        const TrialBalanceReport(
          rows: [row],
          totals: TrialBalanceTotals(balance: 800.0, periodBalance: 300.0),
        ),
      );

      expect(find.text('رصيد الفترة'), findsNothing);
      // الرصيد النهائي معروض في كل الحالات
      expect(find.text('الرصيد'), findsOneWidget);
      expect(find.text('900'), findsOneWidget);
      expect(find.text('100'), findsNothing);
    });

    testWidgets('shows the period column before the balance when filtered',
        (tester) async {
      await pumpTable(
        tester,
        const TrialBalanceReport(
          fromDate: '2026-01-01',
          toDate: '2026-12-31',
          hasPeriod: true,
          rows: [row],
          totals: TrialBalanceTotals(balance: 800.0, periodBalance: 300.0),
        ),
      );

      expect(find.text('رصيد الفترة'), findsOneWidget);
      // رصيد الفترة للصف والإجمالي
      expect(find.text('100'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      // والرصيد النهائي بقي ظاهراً ولم يُستبدل برصيد الفترة
      expect(find.text('900'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
    });

    testWidgets('builds only the visible rows of a very large report',
        (tester) async {
      // 5000 صف كانت تُبنى كاملةً = 45 ألف خلية = سبب الـOOM الأصلي.
      // 5000 eager rows meant 45k cells — the original OOM.
      final report = TrialBalanceReport(
        total: 5000,
        page: 1,
        limit: 5000,
        totalPages: 1,
        rows: [
          for (var i = 0; i < 5000; i++)
            TrialBalanceRow(
              accNo: 12910000 + i,
              accName: 'حساب $i',
              curCode: 'YR',
              localDebit: 1,
              localCredit: 0,
              foreignDebit: 0,
              foreignCredit: 0,
              balance: 1,
            ),
        ],
      );

      await pumpTable(tester, report);

      // الترويسة + سطر الإجمالي + حفنة صفوف مرئية فقط — لا 5002 جدولاً.
      // A header, a totals row and a handful of visible rows — not 5002 tables.
      final tables = tester.widgetList(find.byType(Table)).length;
      expect(tables, lessThan(60));
      expect(find.text('حساب 1'), findsOneWidget);
      // صف بعيد جداً غير مبني إطلاقاً
      expect(find.text('حساب 4999'), findsNothing);
    });
  });
}
