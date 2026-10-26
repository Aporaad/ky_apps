import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
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

/// تهيئة خاملة: لا كاش ولا خادم — تكفي شاشة الدخول باسم شركة افتراضي
/// Idle app config: no cache, no server — the login screen only needs a default company name.
class _StubAppConfig extends AppConfigNotifier {
  @override
  AppConfigState build() => AppConfigState(
    config: AppConfigModel.defaults(),
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
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageProvider.overrideWithValue(_MemoryStorage()),
            authNotifierProvider.overrideWith(
              () => _StubAuth(AuthState(lastUsername: lastUsername)),
            ),
            appConfigNotifierProvider.overrideWith(_StubAppConfig.new),
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
  });
}
