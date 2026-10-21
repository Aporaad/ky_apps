import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/restart_widget.dart';
import 'features/app_config/presentation/providers/app_config_notifier.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // نهيّئ لوحة الألوان من الكاش قبل أول بناء للسمة حتى يظهر الشكل الصحيح من البداية
  // Seed the palette from cache before the first theme build, so the correct look shows
  // from the very first frame (before the server sync completes).
  await bootstrapAppConfig();
  runApp(const ProviderScope(child: RestartWidget(child: KyApp())));
}

/// التطبيق الرئيسي مع دعم التعريب الكامل واتجاه RTL
/// Main Application with full Arabic localization and RTL support
///
/// أصبح `ConsumerWidget` يراقب تهيئة التطبيق فيُعيد بناء السمة والعنوان فور تغيّرهما.
/// Now a [ConsumerWidget] that watches the app config, rebuilding the theme and title live.
class KyApp extends ConsumerWidget {
  const KyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // نراقب التهيئة: أي حفظ جديد يعيد بناء ThemeData من `AppPalette` المحدَّث
    // Watch the config: any save rebuilds ThemeData from the updated AppPalette.
    final appName =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.appName));

    // أي سقوط من «مُصادق» إلى «غير مُصادق» يذهب لشاشة الدخول، من أي مسار جاء
    // Any fall from signed-in to signed-out routes to the login screen, wherever it came from.
    //
    // centralized هنا لأن مخرجات الجلسة ثلاث: إنهاء المدير للجلسة (401 من أول طلب)، ومهلة الخمول
    // (حارس محلي بلا طلب أصلاً)، وتسجيل الخروج العادي. ترك التوجيه لكل شاشة يعني مساراً ناقصاً
    // دائماً — وهو سبب بقاء الشاشات مرسومة بعد انتهاء الجلسة.
    // It lives here because the session ends three ways: an admin terminating it (a 401 on the next
    // request), an idle timeout (a local check with no request at all), and a normal logout. Letting
    // each screen navigate is how one of them always ends up missing — and why dead sessions kept
    // drawing the portal.
    ref.listen(
      authNotifierProvider.select((s) => s.isAuthenticated),
      (previous, next) {
        if (previous == true && !next) appRouter.go('/login');
      },
    );

    return MaterialApp.router(
      title: appName,
      debugShowCheckedModeBanner: false,
      // السمة تُبنى من اللوحة الزمنية لتعكس الألوان/الخط الحاليين
      // The theme is built from the runtime palette to reflect current colors/font.
      theme: AppTheme.build(),
      routerConfig: appRouter,
      // التعريب ودعم اتجاه الواجهة من اليمين إلى اليسار (RTL)
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // ضبط سقف آمن لتكبير الخطوط لتفادي مشاكل Overflow في الشاشات الصغيرة
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
