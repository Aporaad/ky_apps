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
/// to their real (unreached) behaviour. Only the five methods the group screen
/// actually invokes are replaced — every one returns canned data instead of
/// hitting Dio.
class _FakeRepo extends AccountRepository {
  _FakeRepo()
      : super(
          client: DioClient(
            storage: SecureStorageService(),
            baseUrl: 'http://127.0.0.1',
          ),
        );

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
    CancelToken? cancelToken,
  }) async =>
      const TrialBalanceReport(
        scopeLevel: 'group',
        scopeLabel: 'مجموعة 1',
        asOfDate: '21/10/2026',
        rows: [
          TrialBalanceRow(
            accNo: 12910217,
            accName: 'موظف تجريبي',
            curCode: 'YR',
            localDebit: 100.0,
            localCredit: 50.0,
            foreignDebit: 0.0,
            foreignCredit: 0.0,
            balance: 50.0,
            currentBalance: 50.0,
          ),
        ],
        totals: TrialBalanceTotals(
          localDebit: 100.0,
          localCredit: 50.0,
          foreignDebit: 0.0,
          foreignCredit: 0.0,
          balance: 50.0,
        ),
      );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AccountRepository repo,
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
      child: const MaterialApp(
        locale: Locale('ar'),
        home: AccountGroupStatementScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AccountGroupStatementScreen', () {
    testWidgets('renders empty state before any scope is chosen',
        (WidgetTester tester) async {
      await _pumpScreen(tester, repo: _FakeRepo());

      expect(find.text('كشف حساب مجموعة حسابات جزئية'), findsOneWidget);
      expect(find.text('لم يُختر نطاق بعد'), findsOneWidget);
      // Print/export buttons are hidden while there is no data on screen.
      expect(find.byIcon(Icons.print_outlined), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
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

      // Open the account dropdown and pick the fake entry.
      await tester.tap(find.text('حساب رئيسي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 - قسم الأمانة').first);
      await tester.pumpAndSettle();

      // The stub returns a fixed TrialBalanceReport — its row label should now
      // appear inside the trial-balance table, and print/export buttons show.
      expect(find.text('موظف تجريبي'), findsOneWidget);
      expect(find.byIcon(Icons.print_outlined), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });
  });
}
