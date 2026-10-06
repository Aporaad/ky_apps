import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/employee_portal/presentation/screens/employee_main_layout.dart';
import '../features/settings/presentation/screens/api_settings_screen.dart';
import '../features/settings/presentation/screens/security_settings_screen.dart';

/// موجه التطبيق المركزي (GoRouter)
/// Centralized App Router with protected navigation
final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/employee',
      builder: (context, state) => const EmployeeMainLayout(),
    ),
    // إعدادات الـ API فقط (تُفتح من شاشة تسجيل الدخول وقسم الإعدادات)
    GoRoute(
      path: '/api-settings',
      builder: (context, state) => const ApiSettingsScreen(),
    ),
    // إعدادات الأمان: البصمة وكلمة المرور (تُفتح من قسم الإعدادات فقط)
    GoRoute(
      path: '/security-settings',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
  ],
);
