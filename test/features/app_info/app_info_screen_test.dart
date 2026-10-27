import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/app_info.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/admin/data/models/admin_result.dart';
import 'package:ky_apps/features/app_config/data/models/app_config_model.dart';
import 'package:ky_apps/features/app_config/presentation/providers/app_config_notifier.dart';
import 'package:ky_apps/features/app_info/presentation/screens/app_info_screen.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/auth/presentation/widgets/api_password_dialog.dart';
import 'package:ky_apps/features/support/data/repositories/support_repository.dart';
import 'package:ky_apps/features/support/presentation/providers/support_inquiry_provider.dart';

/// مخزن في الذاكرة: لا قناة منصة ولا قرص
/// An in-memory store: no platform channel and no disk.
class _MemoryStorage extends SecureStorageService {}

/// تهيئة ثابتة معلومة القيم — الشاشة تقرأ منها اسم الشركة والخدمات
/// A fixed, known config — the screen reads the company identity out of it.
class _StubAppConfig extends AppConfigNotifier {
  _StubAppConfig(this._config);

  final AppConfigModel _config;

  @override
  AppConfigState build() =>
      AppConfigState(config: _config, loading: false);

  /// التحقق المحلي مستبدل: الحوار يُختبر بوجوده لا بمنطق كلمة السر
  /// Local verification is stubbed: the dialog is tested for its presence, not its password logic.
  @override
  Future<bool> verifyApiSettingsPassword(String password) async => false;
}

/// زائر قبل الدخول: النموذج يعرض الاسم والهاتف
/// A visitor before login: the form shows the name and phone fields.
class _StubAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

/// مستودع يعدّ النداءات ويرفض الإرسال — لإثبات أن التحقق المحلي يسبق الشبكة
/// A repository that counts calls and refuses to send — proves local validation precedes the
/// network round-trip.
class _RecordingSupportRepository extends SupportRepository {
  _RecordingSupportRepository()
    : super(client: DioClient(storage: _MemoryStorage()));

  int calls = 0;

  @override
  Future<AdminResult<Map<String, dynamic>>> submitInquiry({
    String? name,
    String? phone,
    required String message,
    String? appVersion,
    String? platform,
    CancelToken? cancelToken,
  }) async {
    calls++;

    return const AdminResult(success: false, message: 'لا شبكة في الاختبار');
  }
}

void main() {
  /// تهيئة معلومة القيم: كل حقول الشركة مضبوطة — مرجع تتنوّع عنه بقية الحالات
  /// A known config with every company field set — the baseline the other cases vary from.
  AppConfigModel fullConfig() => AppConfigModel.defaults().copyWith(
    companyName: 'شركة الكبودي للخياطة',
    companyAddress: 'صنعاء - شارع المطار',
    companyWebsite: 'example.com',
    companyPhone: '01234567',
    companyServices: 'خياطة رجالية وتفصيل كروت وبدلات رسمية.',
  );

  /// شاشة عريضة عالية: الأقسام الثلاثة كلها مرئية بلا تمرير فاللمس يصل إلى هدفه
  /// A tall, wide surface: all three sections are visible without scrolling, so taps land.
  ///
  /// [size] يُصغَّر إلى مقاس هاتف في اختبار تجاوب بطاقات الشركة
  /// [size] shrinks to a phone-sized surface in the company-card responsiveness check.
  void useSurface(WidgetTester tester, [Size size = const Size(1000, 2400)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<({_RecordingSupportRepository repo})> pumpScreen(
    WidgetTester tester, {
    bool allowApiUnlock = false,
    AppConfigModel? config,
    Size surface = const Size(1000, 2400),
  }) async {
    useSurface(tester, surface);

    final repo = _RecordingSupportRepository();
    final effective = config ?? fullConfig();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(_MemoryStorage()),
          appConfigNotifierProvider.overrideWith(() => _StubAppConfig(effective)),
          authNotifierProvider.overrideWith(_StubAuth.new),
          supportRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: AppInfoScreen(allowApiUnlock: allowApiUnlock),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (repo: repo);
  }

  group('AppInfoScreen', () {
    testWidgets('يعرض الأقسام الثلاثة وبيانات الشركة من التهيئة', (tester) async {
      await pumpScreen(tester);

      expect(find.text('معلومات البرنامج والدعم'), findsOneWidget);
      expect(find.text('معلومات الشركة'), findsOneWidget);
      expect(find.text('معلومات المطور'), findsOneWidget);
      expect(find.text('الاستفسار والحصول على مساعدة'), findsOneWidget);

      // الاسم مرة واحدة فقط: الترويسة تعرض الشعار، وبطاقة الشركة تعرض الاسم
      // The name appears exactly once: the header carries the logo, the company card the name.
      expect(find.text('شركة الكبودي للخياطة'), findsOneWidget);
      expect(find.text('صنعاء - شارع المطار'), findsOneWidget);
      expect(find.text('example.com'), findsOneWidget);
      expect(find.text('01234567'), findsOneWidget);
      expect(find.text('خياطة رجالية وتفصيل كروت وبدلات رسمية.'), findsOneWidget);

      // تسميات بطاقات البيانات ونبذة الخدمات
      // The detail-tile labels and the services panel heading.
      expect(find.text('العنوان'), findsOneWidget);
      expect(find.text('الموقع الإلكتروني'), findsOneWidget);
      expect(find.text('الهاتف'), findsOneWidget);
      expect(find.text('نبذة عن خدماتنا'), findsOneWidget);

      // الاسم الإنجليزي يأتي من القاعدة تحت العربي — لا سطر عربي ثانٍ مكرر
      // The Latin name comes from the database under the Arabic one — no duplicated Arabic line.
      expect(find.text("ALKABODI FOR MEN's TAILORING"), findsOneWidget);

      // اسم المطور ورقمه وزر واتساب
      // The developer's name, number, and WhatsApp button.
      expect(find.text(kDeveloperName), findsOneWidget);
      expect(find.text(kDeveloperPhoneDisplay), findsOneWidget);
      expect(find.text('واتساب'), findsWidgets);
    });

    testWidgets('الحقول الفارغة لا ترسم بطاقات ولا فقرة خدمات', (tester) async {
      // اسم وهاتف فقط: بقية الحقول فارغة في قاعدة البيانات
      // Only a name and a phone: every other field is blank in the database.
      final config = AppConfigModel.defaults().copyWith(
        companyName: 'شركة الكبودي للخياطة',
        companyAddress: '',
        companyAddressEn: '',
        companyWebsite: '',
        companyPhone: '01234567',
        companyServices: '',
      );

      await pumpScreen(tester, config: config);

      expect(find.text('شركة الكبودي للخياطة'), findsOneWidget);
      expect(find.text('الهاتف'), findsOneWidget);

      // لا بطاقة فارغة ولا لوحة خدمات فارغة: الحقل الشاغر يُخفى لا يُplaceholder
      // No empty tile and no empty services panel: a blank field is hidden, not stubbed.
      expect(find.text('العنوان'), findsNothing);
      expect(find.text('الموقع الإلكتروني'), findsNothing);
      expect(find.text('نبذة عن خدماتنا'), findsNothing);
    });

    testWidgets('بلا أي بيانات تُعرض حالة الفراغ لا بطاقة صامتة', (tester) async {
      final config = AppConfigModel.defaults().copyWith(
        companyName: '',
        companyNameEn: '',
        companyAddress: '',
        companyAddressEn: '',
        companyWebsite: '',
        companyPhone: '',
        companyServices: '',
      );

      await pumpScreen(tester, config: config);

      expect(find.text('لم تُضف بيانات الشركة بعد'), findsOneWidget);
      expect(find.text('نبذة عن خدماتنا'), findsNothing);
    });

    testWidgets('بطاقات الشركة تنزل إلى عمود واحد على شاشة هاتف بلا تجاوز', (
      tester,
    ) async {
      // مقاس هاتف ضيّق: شبكة العمودين يجب أن تنزل إلى عمود واحد
      // A narrow phone: the two-column grid has to fall back to a single column.
      await pumpScreen(tester, surface: const Size(360, 2400));

      expect(tester.takeException(), isNull);
      expect(find.text('صنعاء - شارع المطار'), findsOneWidget);

      // في العمود الواحد تتراكم البطاقات رأسياً فالموقع تحت العنوان
      // In a single column the tiles stack, so the website sits below the address.
      final address = tester.getTopLeft(find.text('العنوان'));
      final website = tester.getTopLeft(find.text('الموقع الإلكتروني'));
      expect(website.dy, greaterThan(address.dy));
    });

    testWidgets('خمس نقرات على الاسم تفتح حوار كلمة السر حين يُسمح بالفتح', (
      tester,
    ) async {
      await pumpScreen(tester, allowApiUnlock: true);

      expect(find.byType(ApiPasswordDialog), findsNothing);

      // أربع نقرات لا تكفي
      // Four taps are not enough.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(kDeveloperName));
        await tester.pump();
      }
      expect(find.byType(ApiPasswordDialog), findsNothing);

      await tester.tap(find.text(kDeveloperName));
      await tester.pumpAndSettle();

      expect(find.byType(ApiPasswordDialog), findsOneWidget);
      expect(find.text('كلمة سر إعدادات الـ API'), findsOneWidget);
    });

    testWidgets('بوابة الموظف: خمس نقرات لا تفتح شيئاً', (tester) async {
      await pumpScreen(tester, allowApiUnlock: false);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text(kDeveloperName));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(find.byType(ApiPasswordDialog), findsNothing);
    });

    testWidgets('إرسال فارغ يعرض رسائل التحقق بلا أي طلب شبكة', (tester) async {
      final h = await pumpScreen(tester);

      await tester.ensureVisible(find.text('إرسال الاستفسار'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إرسال الاستفسار'));
      await tester.pump();

      expect(find.text('اكتب الاسم (محرفان على الأقل)'), findsOneWidget);
      expect(find.text('رقم الهاتف من 7 إلى 15 رقماً'), findsOneWidget);
      expect(find.text('اكتب استفسارك (10 محارف على الأقل)'), findsOneWidget);

      // الشبكة لم تُلمس: التحقق المحلي أوقف الطلب قبل المستودع
      // The network was never touched: local validation stopped the request before the repository.
      expect(h.repo.calls, 0);
    });

    testWidgets('لا يعرض رسائل التحقق قبل أول إرسال', (tester) async {
      await pumpScreen(tester);

      expect(find.text('اكتب الاسم (محرفان على الأقل)'), findsNothing);
      expect(find.text('اكتب استفسارك (10 محارف على الأقل)'), findsNothing);
    });
  });
}
