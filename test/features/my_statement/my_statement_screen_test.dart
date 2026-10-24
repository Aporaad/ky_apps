import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/app_config/data/models/app_config_model.dart';
import 'package:ky_apps/features/app_config/presentation/providers/app_config_notifier.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/my_statement/presentation/screens/my_financial_statement_screen.dart';
import 'package:ky_apps/features/my_statement/presentation/screens/my_work_statement_screen.dart';

/// Auth stub: `build()` returns a fixed state, so no secure-storage or Dio call runs.
/// A null `user` means `accNo == null`, which short-circuits the statement notifiers
/// into their "no linked account" error before any repository/Dio is touched.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier();
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true).withPermissions(
        const PermissionSnapshot(
            userId: 1, isAdmin: true, permissions: <String>[]),
      );
}

/// App-config stub: returns defaults synchronously instead of hydrating from the
/// server, so the letterhead reads never schedule a network round-trip.
class _StubAppConfigNotifier extends AppConfigNotifier {
  @override
  AppConfigState build() => AppConfigState(
        config: AppConfigModel.defaults(),
        loading: false,
      );
}

void _useTabletViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('MyFinancialStatementScreen', () {
    testWidgets('shows the fixed identity bar and never an account picker',
        (WidgetTester tester) async {
      _useTabletViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
            appConfigNotifierProvider
                .overrideWith(() => _StubAppConfigNotifier()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: MyFinancialStatementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The personal variant replaces the selectable account field with a static
      // identity label, so the current employee can only ever see their own account.
      expect(find.text('كشف حسابي المالي'), findsOneWidget);
      expect(find.text('كشف حسابي المالي — الموظف الحالي'), findsOneWidget);

      // The account-statement picker affordance from the original screen must be gone.
      expect(find.text('اضغط لاختيار الحساب المالي...'), findsNothing);
    });

    testWidgets('surfaces a clear message when no account is linked',
        (WidgetTester tester) async {
      _useTabletViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
            appConfigNotifierProvider
                .overrideWith(() => _StubAppConfigNotifier()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: MyFinancialStatementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('لا يوجد حساب مالي مرتبط'), findsOneWidget);
    });
  });

  group('MyWorkStatementScreen', () {
    testWidgets('builds with no worker selector and its own title',
        (WidgetTester tester) async {
      _useTabletViewport(tester);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _StubAuthNotifier()),
            appConfigNotifierProvider
                .overrideWith(() => _StubAppConfigNotifier()),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            home: MyWorkStatementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No worker id / type is passed; the header is the personal "my work" title.
      expect(find.text('كشف عملي'), findsOneWidget);
      expect(find.text('الموظف الحالي'), findsOneWidget);
    });
  });
}
