import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/app_info.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/core/widgets/app_logo.dart';
import 'package:ky_apps/features/app_config/data/models/app_config_model.dart';
import 'package:ky_apps/features/app_config/presentation/providers/app_config_notifier.dart';
import 'package:ky_apps/features/auth/data/models/auth_response.dart';
import 'package:ky_apps/features/auth/data/models/user_model.dart';
import 'package:ky_apps/features/auth/data/repositories/auth_repository.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/auth/presentation/screens/login_screen.dart';

/// مخزن في الذاكرة: لا قناة منصة ولا قرص
/// An in-memory store: no platform channel and no disk.
class _MemoryStorage extends SecureStorageService {
  String? username;

  @override
  Future<void> saveLastUsername(String username) async =>
      this.username = username.trim().isEmpty ? null : username.trim();

  @override
  Future<String?> getLastUsername() async => username;

  @override
  Future<void> deleteLastUsername() async => username = null;

  /// `clearAll()` الحقيقي يمسح مفاتيح الجلسة ويُبقي الاسم — نُحاكي أثره بلا مساس بالاسم
  /// The real clearAll() drops session keys and keeps the name — simulate exactly that.
  @override
  Future<void> clearAll() async {}
}

/// مصادقة ثابتة: الحالة تُبنى مباشرة بدل `checkAuthStatus`
/// Fixed auth: the state is built directly instead of running `checkAuthStatus`.
class _StubAuth extends AuthNotifier {
  _StubAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// تهيئة خاملة: لا كاش ولا خادم — تكفي شاشة الدخول باسم شركة افتراضي ورقم تواصل
/// Idle app config: no cache, no server — the login screen needs a company name and contact number.
class _StubAppConfig extends AppConfigNotifier {
  _StubAppConfig({this.companyPhone = ''});

  /// رقم الشركة الذي تستعمله أيقونتا التواصل أسفل البطاقة (فارغ = لا أيقونات)
  /// The company number behind the two contact icons under the card (blank = no icons).
  final String companyPhone;

  @override
  AppConfigState build() => AppConfigState(
    config: AppConfigModel.defaults().copyWith(companyPhone: companyPhone),
    loading: false,
  );
}

/// مصادقة تُبقي الحالة قابلة للتغيير من الاختبار — لإثبات وصول الاسم متأخراً
/// Auth that lets the test change the state — used to prove the late-arrival prefill.
class _MutableAuth extends AuthNotifier {
  _MutableAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void remember(String? username) =>
      state = state.copyWith(lastUsername: () => username);
}

/// مصادقة حقيقية بلا شبكة وبلا بصمة: `login` وحدها تحت الاختبار
/// Real notifier with no network and no biometrics, so only `login` runs for real.
class _LoginOnlyAuth extends AuthNotifier {
  _LoginOnlyAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;

  /// `local_auth` قناة منصة لا تعمل في اختبار الوحدة — تُعطَّل هنا وحدها
  /// local_auth is a platform channel unavailable in a unit test — disabled here only.
  @override
  Future<void> refreshBiometricStatus() async {}
}

/// مستودع مصادقة مزيّف: يرد باستجابة مُعدّة مسبقاً ويسجّل ما كُتب في الحقل
/// Fake auth repository: replies with a prepared response and records the typed input.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({required this.response, required _MemoryStorage storage})
    : super(client: DioClient(storage: storage), storage: storage);

  final AuthResponse response;

  /// آخر اسم كُتب في الحقل ووصل إلى المستودع
  /// The last username the screen handed to the repository.
  String? typed;

  @override
  Future<AuthResponse> login({
    required String username,
    required String password,
    required String userType,
  }) async {
    typed = username;
    return response;
  }

  /// بلا شبكة: `clearAll()` في المخزن الذاكري لا يمس الاسم أصلاً
  /// No network: the in-memory store's `clearAll()` leaves the remembered name alone.
  @override
  Future<void> logout() async {}
}

/// بيانات مستخدم نجح دخوله — الاسم الرسمي هنا هو ما يُحفظ
/// A signed-in user payload — its canonical username is what gets remembered.
UserModel _user(String username) =>
    UserModel(id: 7, username: username, nameAr: 'خالد');

void main() {
  group('usernameToRemember', () {
    test('الاسم الرسمي القادم من الخادم يفوز على ما كتبه المستخدم', () {
      expect(usernameToRemember(canonical: 'khaled', typed: 'خالد'), 'khaled');
      expect(usernameToRemember(canonical: ' khaled ', typed: '1234'), 'khaled');
    });

    test('الاسم الرسمي الفارغ يترك النص المكتوب (بعد trim)', () {
      expect(usernameToRemember(canonical: '   ', typed: ' 1234 '), '1234');
      expect(usernameToRemember(canonical: null, typed: 'خالد'), 'خالد');
    });

    test('مسافات فقط في الاثنين تعني «لا شيء يُحفظ»', () {
      expect(usernameToRemember(canonical: null, typed: '   '), isNull);
      expect(usernameToRemember(canonical: '', typed: ''), isNull);
    });
  });

  group('AuthNotifier.lastUsername', () {
    /// حاوية مع مخزن في الذاكرة وحالة ثابتة — بلا شبكة وبلا قرص
    /// Container with an in-memory store and a fixed state: no network, no disk.
    ({ProviderContainer container, _MemoryStorage storage, AuthNotifier notifier})
    harness(String? remembered) {
      final storage = _MemoryStorage()..username = remembered;
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authNotifierProvider.overrideWith(
            () => _StubAuth(
              AuthState(isAuthenticated: true, lastUsername: remembered),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      return (
        container: container,
        storage: storage,
        notifier: container.read(authNotifierProvider.notifier),
      );
    }

    test('الخروج الإجباري لا يطمس آخر اسم نجح تسجيله', () {
      final h = harness('khaled');

      h.notifier.forceLogout();

      final state = h.container.read(authNotifierProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.lastUsername, 'khaled');
      expect(h.storage.username, 'khaled');
    });

    test('forgetLastUsername يمسح المفتاح والحالة معاً', () async {
      final h = harness('khaled');

      await h.notifier.forgetLastUsername();

      expect(h.storage.username, isNull);
      expect(h.container.read(authNotifierProvider).lastUsername, isNull);
    });
  });

  group('login يحفظ الاسم بعد النجاح فقط', () {
    /// حاوية كاملة: تخزين في الذاكرة + مستودع مزيّف + متحكّم حقيقي بلا بصمة
    /// Full harness: in-memory storage, fake repository and the real notifier without biometrics.
    ({
      ProviderContainer container,
      _MemoryStorage storage,
      _FakeAuthRepository repository,
      AuthNotifier notifier,
    })
    harness(AuthResponse response, {String? remembered, bool signedIn = false}) {
      final storage = _MemoryStorage()..username = remembered;
      final repository = _FakeAuthRepository(
        response: response,
        storage: storage,
      );
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(repository),
          authNotifierProvider.overrideWith(
            () => _LoginOnlyAuth(
              AuthState(isAuthenticated: signedIn, lastUsername: remembered),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      return (
        container: container,
        storage: storage,
        repository: repository,
        notifier: container.read(authNotifierProvider.notifier),
      );
    }

    test('النجاح يحفظ الاسم الرسمي في القرص والحالة', () async {
      final h = harness(
        AuthResponse(
          success: true,
          message: 'تم تسجيل الدخول',
          token: 'token',
          user: _user('khaled'),
        ),
      );

      final ok = await h.notifier.login(username: 'خالد', password: 'secret');

      expect(ok, isTrue);
      expect(h.repository.typed, 'خالد');
      expect(h.storage.username, 'khaled');
      expect(
        h.container.read(authNotifierProvider).lastUsername,
        'khaled',
      );
    });

    test('اسم رسمي فارغ يترك ما كتبه المستخدم', () async {
      final h = harness(
        AuthResponse(
          success: true,
          message: 'تم تسجيل الدخول',
          token: 'token',
          user: _user(''),
        ),
      );

      await h.notifier.login(username: ' 1234 ', password: 'secret');

      expect(h.storage.username, '1234');
      expect(h.container.read(authNotifierProvider).lastUsername, '1234');
    });

    test('محاولة فاشلة لا تُبدّل الاسم المحفوظ ولا حالة العرض', () async {
      final h = harness(
        const AuthResponse(success: false, message: 'بيانات الدخول غير صحيحة'),
        remembered: 'khaled',
      );

      final ok = await h.notifier.login(username: 'typo', password: 'secret');

      expect(ok, isFalse);
      expect(h.storage.username, 'khaled');
      expect(h.container.read(authNotifierProvider).lastUsername, 'khaled');
    });

    test('الخروج العادي يُبقي الاسم جاهزاً لشاشة الدخول التالية', () async {
      final h = harness(
        const AuthResponse(success: false, message: ''),
        remembered: 'khaled',
        signedIn: true,
      );

      await h.notifier.logout();

      final state = h.container.read(authNotifierProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.lastUsername, 'khaled');
      expect(h.storage.username, 'khaled');
    });
  });

  group('LoginScreen', () {
    /// ضخّ شاشة الدخول بحالة مصادقة تحمل الاسم المحفوظ (أو لا تحمله)
    /// Pump the login screen with an auth state that carries the remembered name, or none.
    Future<void> pumpLogin(
      WidgetTester tester, {
      String? lastUsername,
      String companyPhone = '',
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(_MemoryStorage()),
            authNotifierProvider.overrideWith(
              () => _StubAuth(AuthState(lastUsername: lastUsername)),
            ),
            appConfigNotifierProvider.overrideWith(
              () => _StubAppConfig(companyPhone: companyPhone),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('يعبّئ آخر اسم مستخدم تلقائياً', (tester) async {
      await pumpLogin(tester, lastUsername: 'khaled');

      expect(find.text('khaled'), findsOneWidget);
      // زر المسح يظهر لأن الاسم محفوظ والحقل غير فارغ
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('لا يعبّئ شيئاً حين لا يوجد اسم محفوظ', (tester) async {
      await pumpLogin(tester);

      expect(find.text('khaled'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('زر المسح يفرّغ الحقل ويُزيل الاسم المحفوظ', (tester) async {
      await pumpLogin(tester, lastUsername: 'khaled');

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('khaled'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('يعبّئ الحقل لو وصل الاسم بعد بناء الشاشة', (tester) async {
      final notifier = _MutableAuth(const AuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(_MemoryStorage()),
            authNotifierProvider.overrideWith(() => notifier),
            appConfigNotifierProvider.overrideWith(_StubAppConfig.new),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('khaled'), findsNothing);

      // الإقلاع البطيء: الاسم يصل بعد رسم الشاشة — يجب أن يُعبّأ لا أن يُهمل
      // Slow boot: the name arrives after the screen is painted — it must still be applied.
      notifier.remember('khaled');
      await tester.pump();

      expect(find.text('khaled'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('أيقونة معلومات البرنامج والدعم في الشريط العلوي بلا نص', (
      tester,
    ) async {
      await pumpLogin(tester);

      // أيقونة وحدها في الشريط العلوي (أعلى اليسار في RTL)، بلا زر عريض ولا نص ظاهر
      // A lone icon in the app bar (top-left in RTL): no wide button, no visible label.
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byTooltip('معلومات البرنامج والدعم'), findsOneWidget);
      expect(find.text('معلومات البرنامج والدعم'), findsNothing);
      expect(find.byIcon(Icons.support_agent_rounded), findsNothing);

      // الأيقونة داخل الـ AppBar لا داخل البطاقة
      // The icon lives in the AppBar, not in the card body.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.info_outline_rounded),
        ),
        findsOneWidget,
      );

      // الأيقونة القديمة أُزيلت: لم يبقَ في الشاشة طريق مباشر إلى إعدادات الخادم
      // The old icon is gone: no direct route to the server settings is left on this screen.
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
      expect(find.byTooltip('إعدادات خادم الـ API'), findsNothing);

      // سطر الإصدار أُزيل من هنا: معلومات النسخة في شاشة «معلومات البرنامج والدعم»
      // The version line is gone from here: version info lives on the app-info screen.
      expect(find.text('الإصدار v$kAppVersionBadge'), findsNothing);
    });

    testWidgets('أيقونتا اتصال وواتساب أسفل البطاقة حين يُضبط رقم الشركة', (
      tester,
    ) async {
      await pumpLogin(tester, companyPhone: '780154000');

      // أيقونتان صغيرتان فقط، بلا نص ظاهر — لكل واحدة تلميح يعلن وظيفتها
      // Two small icons only, no visible text — each carries a tooltip announcing its job.
      expect(find.byIcon(Icons.call_outlined), findsOneWidget);
      expect(find.byIcon(Icons.chat_rounded), findsOneWidget);
      expect(find.byTooltip('اتصال بالشركة'), findsOneWidget);
      expect(find.byTooltip('واتساب الشركة'), findsOneWidget);
      expect(find.text('اتصال بالشركة'), findsNothing);

      // مكان سطر الإصدار القديم: الأيقونتان تحت زر «دخول» مباشرة
      // The old version line's place: the icons sit right under the sign-in button.
      final buttonBottom = tester.getBottomLeft(find.text('دخول')).dy;
      final callCenter = tester.getCenter(find.byTooltip('اتصال بالشركة')).dy;
      expect(callCenter, greaterThan(buttonBottom));
    });

    testWidgets('بلا رقم شركة مضبوط لا تُعرض أيقونات تواصل', (tester) async {
      await pumpLogin(tester);

      // حقل فارغ في القاعدة = لا أيقونتان عاطلتان توهمان بالنقر
      // A blank database field means no dead icons pretending to be tappable.
      expect(find.byTooltip('اتصال بالشركة'), findsNothing);
      expect(find.byTooltip('واتساب الشركة'), findsNothing);
    });

    testWidgets('بطاقة الدخول تظهر كاملة على شاشة هاتف بلا تمرير', (tester) async {
      // مقاس هاتف شائع: 360×640 — الطول الذي كانت البطاقة تتجاوزه قبل التصغير
      // A common phone size, 360×640 — the height the card used to overflow before scaling.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLogin(tester, companyPhone: '780154000');

      expect(tester.takeException(), isNull);

      // البطاقة كلها داخل النافذة: كل عنصر — من الشعار إلى أيقونتي التواصل — بلا تمرير
      // The whole card is inside the window: every element, from the logo to the contact icons,
      // with no scrolling.
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getRect(find.byType(Card)).bottom,
        lessThanOrEqualTo(screenHeight),
      );
      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('دخول'), findsOneWidget);
      expect(find.byTooltip('اتصال بالشركة'), findsOneWidget);
      expect(find.byTooltip('واتساب الشركة'), findsOneWidget);
    });
  });
}
