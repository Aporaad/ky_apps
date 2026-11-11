import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// شبكة صامتة للاختبارات: مغلف نجاح فارغ لكل طلب، ومسارات الطلبات تُسجَّل لاختبار
/// «هل جُلب شيء؟» — بلا منصة، بلا تخزين آمن، وبلا شبكة حقيقية.
/// A quiet test network: every request answers an empty success envelope and the
/// requested paths are logged so tests can assert "was anything fetched?" — with no
/// platform, no secure storage and no real network.
class QuietAdapter implements HttpClientAdapter {
  QuietAdapter({this.log});

  /// مسارات كل طلب وصل — يُفرَّغ قبل الخطوة المقيسة
  /// The path of every request that arrived — cleared before the measured step.
  final List<String>? log;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    log?.add(options.path);

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'message': '',
        'data': <dynamic>[],
        'meta': {
          'total': 0,
          'page': 1,
          'limit': 20,
          'pages': 0,
          'total_pages': 0,
          'has_more': false,
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// عميل Dio بلا معترضات: لا `AuthInterceptor` يلمس التخزين، ولا مؤقتات زمنية تبقى بعد الاختبار
/// A Dio client with no interceptors: no `AuthInterceptor` touching storage, and no
/// timeout timers left behind after the test.
DioClient quietDioClient({List<String>? log}) {
  final client = DioClient(
    storage: SecureStorageService(),
    baseUrl: 'http://127.0.0.1',
  );
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = QuietAdapter(log: log);
  return client;
}

/// بديل المصادقة: حالة جاهزة من `build()` — بلا تخزين آمن وبلا حارس موعد الجلسة
/// Auth stub: `build()` returns the ready state — no secure storage, no session watchdog.
class StubAuthNotifier extends AuthNotifier {
  StubAuthNotifier(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;
}

/// حالة مدير معتمد — بوابات الصلاحيات تُمرَّر بلا منح فردية
/// A signed-in admin — every gate passes because of the admin flag, no grants needed.
AuthState stubAdminState({String? lastUsername}) {
  final state = const AuthState(isAuthenticated: true).withPermissions(
    const PermissionSnapshot(
      userId: 1,
      isAdmin: true,
      permissions: <String>[],
    ),
  );
  return lastUsername == null
      ? state
      : state.copyWith(lastUsername: () => lastUsername);
}

/// كل تجاوزات المزودات التي تحتاجها الاختبارات: شبكة صامتة، تخزين لا يُنادى، ومصادقة جاهزة
/// Every provider override the tests need: quiet network, storage never called, ready auth.
///
/// التجاوز نفسه يتكرّر في البنّاءين أدناه بدل تصديره: نوع `Override` غير مُصدَّر
/// من `flutter_riverpod`، فالشكل الحرفي وحده يعمل في موضعه.
/// The same three overrides appear in both builders below instead of being exported:
/// `Override` is not exported by `flutter_riverpod`, so only the literal works in place.
ProviderContainer quietContainer({List<String>? log, AuthState? auth}) {
  return ProviderContainer(
    overrides: [
      dioClientProvider.overrideWithValue(quietDioClient(log: log)),
      secureStorageProvider.overrideWithValue(SecureStorageService()),
      authNotifierProvider.overrideWith(
        () => StubAuthNotifier(auth ?? stubAdminState()),
      ),
    ],
  );
}

/// `ProviderScope` جاهز بنفس التجاوزات — للاختبارات التي تحتاج `WidgetRef` حياً
/// A ready `ProviderScope` with the same overrides — for tests that need a live `WidgetRef`.
Widget quietScope({
  required Widget child,
  List<String>? log,
  AuthState? auth,
}) {
  return ProviderScope(
    overrides: [
      dioClientProvider.overrideWithValue(quietDioClient(log: log)),
      secureStorageProvider.overrideWithValue(SecureStorageService()),
      authNotifierProvider.overrideWith(
        () => StubAuthNotifier(auth ?? stubAdminState()),
      ),
    ],
    child: child,
  );
}
