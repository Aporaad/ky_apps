import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/core/utils/session_clock.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/auth/presentation/providers/permissions_notifier.dart';
import 'package:ky_apps/features/employee_portal/presentation/screens/employee_main_layout.dart';

/// مزود مصادقة بحالة ثابتة — بلا فحص حالة وبلا شبكة
/// Stub auth notifier with a fixed state: no status check, no network.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// مزود صلاحيات خامل — يعيد حالة جاهزة دون تشغيل أي جلب شبكي في البناء
/// Idle permissions notifier: returns a ready state without firing any network in build().
///
/// الغرض إبقاء فرع «شبكة الأمان» قابلاً للرسم في اختبار الودجت: البناء الحقيقي يجدول
/// `refresh()` الذي يلمس Dio والتخزين الآمن — لا محل لهما في اختبار تخطيط.
/// The real build schedules a network refresh, which a layout test must not depend on.
class _IdlePermissionsNotifier extends PermissionsNotifier {
  _IdlePermissionsNotifier({this.synced = true});

  /// هل وصلت لقطة من قبل؟ true → صياغة «لم تُمنح» الإدارية، false → «جارٍ التحميل»
  /// Whether a snapshot has ever arrived — picks which of the two guidance headlines renders.
  final bool synced;

  @override
  PermissionsState build() {
    return PermissionsState(hasSynced: synced, isSyncing: false);
  }
}

/// حالة مصادقة بمنح معيّنة، كما تبنيها الاستعادة من الخادم تماماً
/// An authenticated state carrying given grants, built the way the real restore path builds it.
AuthState _stateWith({required List<String> codes, bool isAdmin = false}) {
  return const AuthState(isAuthenticated: true).withPermissions(
    PermissionSnapshot(userId: 1, isAdmin: isAdmin, permissions: codes),
  );
}

/// مزود مصادقة يُسجّل استدعاءات الخروج الصامت بدل لمس التخزين الآمن
/// Auth stub that records silent logouts instead of touching secure storage (unavailable in a widget test).
class _RecordingAuthNotifier extends AuthNotifier {
  _RecordingAuthNotifier(this._initial);

  final AuthState _initial;

  /// كم مرة دعت الواجهة إلى خروج صامت بلا منح
  /// How many times the layout asked for a silent, no-grants logout.
  int silentLogouts = 0;

  @override
  AuthState build() => _initial;

  @override
  void forceLogout({String? reason, bool silent = false}) {
    if (silent) silentLogouts++;
    // محاكاة السقوط: تغيير الحالة فقط، بلا `clearAll()` يمس شريان اختبار الودجت
    // Simulate the fall: change state only, no storage wipe a widget test cannot serve.
    state = _initial.copyWith(isAuthenticated: false, permissions: const {});
  }
}

Future<void> _pumpLayout(
  WidgetTester tester, {
  required AuthState state,
  bool synced = true,
  Size size = const Size(1280, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(state)),
        permissionsNotifierProvider.overrideWith(
          () => _IdlePermissionsNotifier(synced: synced),
        ),
      ],
      child: const MaterialApp(home: EmployeeMainLayout()),
    ),
  );
  await tester.pumpAndSettle();
}

/// مضخخة تُعيد نسخة المصادقة المسجِّلة ليقرأ الاختبار كم خرج بصمت
/// Pump that hands back the recording auth notifier so the test can read its logout count.
Future<_RecordingAuthNotifier> _pumpLayoutRecording(
  WidgetTester tester, {
  required AuthState state,
  bool synced = true,
  bool settle = true,
  Size size = const Size(1280, 800),
}) async {
  final recorder = _RecordingAuthNotifier(state);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => recorder),
        permissionsNotifierProvider.overrideWith(
          () => _IdlePermissionsNotifier(synced: synced),
        ),
      ],
      child: const MaterialApp(home: EmployeeMainLayout()),
    ),
  );

  // الانتظار المحايد يرسم مؤشر تحميل لا يهدأ: `pumpAndSettle` لن يستقر أبداً،
  // فيُكتفى بإطار واحد يشغّل نِدّ ما بعد البناء.
  // A loading spinner never settles, so settle:false pumps a single frame instead.
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return recorder;
}

void main() {
  // ── مرحلة 4: تحصين حارس الجلسة من اختلاف ساعة الخادم/الجهاز ──
  // Phase 4: the session watchdog survives a device/server clock mismatch.
  group('SessionClock — deadline on the device clock', () {
    test('unreadable or absent deadline text yields no deadline', () {
      expect(SessionClock.parseServerText(null), isNull);
      expect(SessionClock.parseServerText(''), isNull);
      expect(SessionClock.parseServerText('   '), isNull);
      expect(SessionClock.parseServerText('not a date'), isNull);

      expect(
        SessionClock.resolve(deadlineText: null),
        isNull,
        reason: 'no deadline asserted → watchdog must not evict',
      );
    });

    test('without X-Server-Now the deadline is taken at face value', () {
      // خادم أقدم لا يرسل الترويسة: نتعامل كما كان — الساعتان متطابقتان
      // An older API sends no header: assume the clocks agree, exactly as before.
      final deadline = SessionClock.resolve(
        deadlineText: '2026-10-23 22:00:00',
        deviceNow: DateTime(2026, 10, 23, 21, 0, 0),
      );

      expect(deadline, DateTime(2026, 10, 23, 22, 0, 0));
    });

    test('a device ahead of the server is not evicted before the real deadline', () {
      // الجهاز متقدم ساعتين: لو قورن نص الموعد (بساعة الخادم) بـ `DateTime.now()` مباشرةً لانتهت
      // الجلسة مبكراً — وهذا وجه من العطل المُبلَّغ به. الإزاحة `serverNow - deviceNow = -2h` تُضاف
      // للموعد فيسقط على ساعة الجهاز الصحيحة ويبقى المتبقي نفسه (ساعة) لا يصفرّ.
      // A device two hours ahead would be thrown out early by a naive comparison. The negative
      // offset pushes the deadline onto the device clock so the same real time remains.
      final deviceNow = DateTime(2026, 10, 23, 23, 0, 0); // device runs 2h fast
      // مهلة الخادم بعد ساعة من وقته (21:00) = 22:00 خادم، أي 00:00 على ساعة الجهاز المتقدمة
      final deadline = SessionClock.resolve(
        deadlineText: '2026-10-23 22:00:00',
        serverNowText: '2026-10-23 21:00:00',
        deviceNow: deviceNow,
      );

      expect(deadline, DateTime(2026, 10, 24, 0, 0, 0));
      // لم تنتهِ بعد على ساعة الجهاز، مع أن naive compare كان يرى 22:00 < 23:00 ويطرد فوراً
      expect(deadline!.isAfter(deviceNow), isTrue);
      expect(deadline.difference(deviceNow), const Duration(hours: 1));
    });

    test('the offset is measured against device-now, then subtracted', () {
      // صيغة عامة: resolve == deadline - (serverNow - deviceNow)
      final deviceNow = DateTime(2026, 10, 23, 10, 0, 0);
      // ساعة الخادم متقدمة ساعتين على الجهاز ⇒ إزاحة +2h تُطرح من الموعد
      final deadlineText = '2026-10-23 14:00:00'; // server-clock deadline, 2h from serverNow

      final resolved = SessionClock.resolve(
        deadlineText: deadlineText,
        serverNowText: '2026-10-23 12:00:00',
        deviceNow: deviceNow,
      );

      // 14:00 server = 12:00 device (offset -2h) ⇒ متبقي ساعتان على ساعة الجهاز (10:00 → 12:00)
      expect(resolved, DateTime(2026, 10, 23, 12, 0, 0));
      expect(resolved!.difference(deviceNow), const Duration(hours: 2));
    });
  });

  // ── مرحلة 3: بلا منح صالحة ⇒ عودة صامتة إلى الدخول، لا إلى «الإعدادات» ──
  // Phase 3: with no valid grants the user is returned silently to login — never parked on settings.
  group('EmployeeMainLayout — no valid grants returns to login, never to settings', () {
    testWidgets(
      'a confirmed empty-grant session logs out silently, with no warning screen',
      (tester) async {
        // موظف مُصادق أجاب الخادم فعلاً عن منحها بالفراغ: لا شاشة تنبيه — إنهاء الجلسة بهدوء
        // A non-admin the server confirmed holds no grants: no alert, just a quiet session end.
        final recorder = await _pumpLayoutRecording(
          tester,
          state: _stateWith(codes: const [], isAdmin: false),
          synced: true,
        );

        expect(tester.takeException(), isNull);

        // لا «لا قسم متاح» ولا عنوان بوابة — بل خروج صامت واحد يُسمعه `KyApp` ويوجّه للدخول
        expect(find.byType(NoSectionAvailable), findsNothing);
        expect(find.text('بوابة الموظف'), findsNothing);
        expect(recorder.silentLogouts, 1);
      },
    );

    testWidgets('the redirect fires exactly once, not on every rebuild', (
      tester) async {
      // الحماية من التكرار: بعد الخروج تسقط الحالة إلى «غير مُصادق» وتُعاد البوابة بناءً؛
      // بلا ضابط «مرة واحدة» لانهارت في طرد متكرر داخل اختبار الودجت (وبلا موجه في الإنتاج).
      // Fire-once guard: after the fall the state rebuilds; without the latch it would loop.
      final recorder = await _pumpLayoutRecording(
        tester,
        state: _stateWith(codes: const [], isAdmin: false),
        synced: true,
      );

      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(recorder.silentLogouts, 1);
    });

    testWidgets('a not-yet-resolved empty session waits neutrally, no logout yet', (
      tester) async {
      // لم تصل اللقطة بعد: الانتظار المحايد يمنع طرد جلسةٍ منحُها على وشك الوصول
      // Not resolved yet: the neutral wait must not bounce a session whose grants are imminent.
      final recorder = await _pumpLayoutRecording(
        tester,
        state: _stateWith(codes: const [], isAdmin: false),
        synced: false,
        // مؤشر التحميل لا يستقر ⇒ إطار واحد يكفي لتقييم هذه الحالة
        settle: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NoSectionAvailable), findsNothing);
      expect(recorder.silentLogouts, 0);
    });

    testWidgets('an admin with no listed codes still gets the full portal', (
      tester) async {
      // تجاوز المدير الكامل: `isAdmin` يفتح كل الأقسام بلا منح، فلا تُفعَّل شبكة الأمان
      // The IS_ADMIN bypass opens every section without grants, so the safety net stays silent.
      await _pumpLayout(
        tester,
        state: _stateWith(codes: const [], isAdmin: true),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('بوابة الموظف'), findsOneWidget);
      expect(find.byType(NoSectionAvailable), findsNothing);
    });

    testWidgets('a user with a real grant renders the portal, not the safety net', (
      tester) async {
      await _pumpLayout(
        tester,
        state: _stateWith(codes: const [Perm.customersView]),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('بوابة الموظف'), findsOneWidget);
      expect(find.byType(NoSectionAvailable), findsNothing);
    });
  });
}
