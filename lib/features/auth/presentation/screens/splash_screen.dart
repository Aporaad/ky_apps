import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../providers/auth_notifier.dart';

/// شاشة البداية لفحص حالة المصادقة والتوجيه التلقائي
/// Splash Screen to verify authentication state and navigate accordingly
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) {
      context.go('/employee');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // نقرأ اسم الشركة من التهيئة فينعكس أي تغيير فوراً على شاشة البداية
    // Read the company name from config so any change reflects on the splash immediately.
    final companyName =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.companyName));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الشعار الموحّد — محلي إن وُجد وإلا الأصل المضمّن
            // Unified logo — local file when present, otherwise the bundled asset.
            AppLogo(
              width: 370,
              height: 300,
            ),
            const SizedBox(height: 24),
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'KY Enterprise Accounts',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
