import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/features/admin/data/models/app_user_model.dart';
import 'package:ky_apps/features/admin/presentation/providers/security_settings_provider.dart';
import 'package:ky_apps/features/admin/presentation/widgets/user_form_widget.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// بديل ثابت للمصادقة: `build()` يعيد حالة جاهزة فلا تشغيل للتخزين الآمن أو الشبكة.
/// A fixed auth stub: `build()` returns a ready state, so no secure-storage or Dio runs.
class _StubAuth extends AuthNotifier {
  _StubAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

/// بديل لإعدادات الأمان: حدّ كلمة المرور الافتراضي بلا جلب من الخادم.
/// A security-settings stub: the default password floor with no server fetch.
class _StubSecurity extends SecuritySettingsNotifier {
  @override
  SecuritySettingsState build() =>
      const SecuritySettingsState(settings: [], isLoading: false);
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required AuthState auth,
  AppUserModel? existing,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuth(auth)),
        securitySettingsProvider.overrideWith(() => _StubSecurity()),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: UserFormWidget(
              existing: existing,
              onSubmit: (_) async {},
              onValidationError: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('UserFormWidget — financial account (ACC_NO) field', () {
    testWidgets('an admin sees the clickable picker, distinct from the cash field',
        (tester) async {
      await _pumpForm(
        tester,
        auth: const AuthState(isAuthenticated: true, isAdmin: true),
      );

      // الحقلان منفصلان: النقدي (الصندوق) والمالي (ACC_NO).
      // Two distinct fields: the cash/treasury one and the financial/ledger one.
      expect(find.text('رقم الحساب النقدي (الصندوق)'), findsOneWidget);
      expect(find.text('الحساب المالي'), findsOneWidget);

      // بلا ربط بعد: يظهر نصّ الفتح لا قيمة، ولا حقل رقمي يدوي.
      // Unlinked yet: the open-affordance shows, and there is no manual numeric field.
      expect(find.text('اضغط لاختيار الحساب المالي...'), findsOneWidget);
      expect(find.text('رقم الحساب في شجرة الحسابات (ACC_NO)'), findsNothing);
    });

    testWidgets('a linked account shows its bound state and an unlink action',
        (tester) async {
      await _pumpForm(
        tester,
        auth: const AuthState(isAuthenticated: true, isAdmin: true),
        existing: const AppUserModel(
          userId: 5,
          userNameEn: 'khaled',
          cashAccNo: 77,
          accNo: 500,
        ),
      );

      // اسم الحساب غير معلوم قبل الاختيار، فيُعرض رقم الحساب المرتبط فعلياً.
      // The name is unknown until picked, so the linked number is what renders.
      expect(find.text('مرتبط بالحساب 500'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('a user who cannot read the chart gets the numeric fallback',
        (tester) async {
      await _pumpForm(
        tester,
        // لا accounts.view ولا accounts.statement_financial ⇒ لا منتقي.
        auth: const AuthState(
          isAuthenticated: true,
          isAdmin: false,
          permissions: <String>{Perm.usersUpdate},
        ),
        existing: const AppUserModel(userId: 5, userNameEn: 'khaled', accNo: 500),
      );

      // المنفذ يبقى متاحاً: حقل رقمي يدوي بدل فاتحة كانت ستصطدم بـ 403.
      // The capability survives: a manual numeric field instead of a sheet that would 403.
      expect(find.text('رقم الحساب في شجرة الحسابات (ACC_NO)'), findsOneWidget);
      expect(find.text('اضغط لاختيار الحساب المالي...'), findsNothing);
    });
  });
}
