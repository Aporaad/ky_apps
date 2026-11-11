import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/auth/presentation/providers/permissions_notifier.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';
import 'package:ky_apps/main.dart';

import '../support/quiet_network.dart';

/// مصادقة قابلة للقلب: تبني حالة «مُصادق» ثم تُسقِطها كما تُسقطها النهاية الحقيقية
/// A togglable auth stub: builds a signed-in state, then drops it the way a real
/// session end does. Only `isAuthenticated` changes, which is exactly what the
/// `KyApp` listener selects on.
class _ToggleAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => stubAdminState();

  /// محاكاة الخروج: تغيير الحالة فقط، بلا `clearAll()` يمس التخزين الآمن
  /// Simulated sign-out: state only, no `clearAll()` touching secure storage.
  void signOut() => state = state.copyWith(isAuthenticated: false);
}

/// صلاحيات خاملة — البناء الحقيقي يجدول مزامنة شبكة لا داع لها هنا
/// Idle permissions: the real build schedules a network sync this test does not need.
class _IdlePermissionsNotifier extends PermissionsNotifier {
  @override
  PermissionsState build() =>
      const PermissionsState(hasSynced: true, isSyncing: false);
}

void main() {
  // التطبيق كله في هذا الاختبار: البوابة مفتوحة، ثم سقوط الجلسة من مكان واحد
  /// The whole application here: the portal is open, then the session falls through
  /// the one path `KyApp` owns.
  testWidgets('signing out wipes every section through the app listener',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late WidgetRef ref;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioClientProvider.overrideWithValue(quietDioClient()),
          secureStorageProvider.overrideWithValue(SecureStorageService()),
          authNotifierProvider.overrideWith(() => _ToggleAuthNotifier()),
          permissionsNotifierProvider.overrideWith(
            () => _IdlePermissionsNotifier(),
          ),
        ],
        child: Consumer(
          builder: (context, widgetRef, _) {
            ref = widgetRef;
            return const KyApp();
          },
        ),
      ),
    );

    // شاشة البوابة بعد مهلة الإقلاع
    // The portal, once the splash delay elapses.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    ref.read(cuttingBillsListProvider.notifier).search('خالد');
    await tester.pump();
    expect(ref.read(cuttingBillsListProvider).query, 'خالد');

    // السقوط كما يحدث في المسارات الثلاثة: من «مُصادق» إلى لا مُصادق
    // The fall exactly as the three session endings produce it: signed-in to signed-out.
    (ref.read(authNotifierProvider.notifier) as _ToggleAuthNotifier).signOut();
    await tester.pumpAndSettle();

    expect(
      ref.read(cuttingBillsListProvider).query,
      '',
      reason: 'الخروج من أي مسار يجب أن يُمحى معه بحث كل قسم',
    );
  });
}
