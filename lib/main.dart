import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/restart_widget.dart';
import 'features/app_config/presentation/providers/app_config_notifier.dart';
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
