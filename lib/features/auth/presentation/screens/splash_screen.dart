import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../providers/auth_notifier.dart';

/// شاشة البداية: تفحص حالة المصادقة وتوجّه تلقائياً، بتصميم متحرك يأخذ ألوان التطبيق الرسمية
/// Splash Screen: verifies authentication and navigates automatically, with an animated
/// design built on the app's official colors and sizes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _checkNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNavigation() async {
    await Future.delayed(const Duration(milliseconds: 2000));
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
        ref.watch(
          appConfigNotifierProvider.select((s) => s.config.companyName),
        );

    return Scaffold(
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.surface,
                AppColors.primary.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // زخرفة هادئة بألوان السمة في الأعلى والأسفل
              // Subtle theme-tinted ornaments top and bottom.
              Positioned(
                top: -60,
                right: -60,
                child: _orb(AppColors.primary, 180, 0.10),
              ),
              Positioned(
                bottom: -70,
                left: -70,
                child: _orb(AppColors.accent, 200, 0.10),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الشعار داخل بطاقة بيضاء محاطة بهالة اللون الأساسي
                      // Logo in a white card wrapped in a primary-colored glow ring.
                      ScaleTransition(
                        scale: _scale,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                blurRadius: 34,
                                spreadRadius: 4,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const AppLogo(width: 150, height: 124),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SlideTransition(
                        position: _slide,
                        child: Column(
                          children: [
                            Text(
                              companyName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'KY Enterprise Accounts',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // فاصل اللون الرئيسي القصير
                            // Short primary accent divider.
                            Container(
                              width: 46,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 46),
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
