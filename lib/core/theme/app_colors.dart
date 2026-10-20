import 'package:flutter/material.dart';
import 'app_palette.dart';

/// لوحة الألوان الموحدة للتطبيق
/// Application unified color palette
///
/// الحقول الخمسة القابلة للتهيئة (الأساسي/الثانوي/الخلفية/النص الرئيسي/النص العادي
/// بالإضافة إلى اللون الداكن المشتق) أصبحت `getter` تفوّض إلى `AppPalette` الزمني
/// لتعكس تهيئة التطبيق القادمة من الخادم. بقية الألوان ثابتة `const`.
/// The five configurable fields delegate to the runtime [AppPalette] so they reflect
/// server-driven app config; the remaining colors stay compile-time `const`.
class AppColors {
  // الألوان الأساسية / base colors
  // ديناميكية — تُقرأ من `AppPalette` لتعكس التهيئة الحالية / dynamic, read from AppPalette
  static Color get primary => AppPalette.primary;
  static const Color primaryLight = Color(0xFF3B82F6);
  static Color get primaryDark => AppPalette.primaryDark;

  // الألوان الثانوية والتمييز / secondary & accent
  static Color get accent => AppPalette.accent; // زمردي / تيل
  static const Color accentLight = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF64748B);

  // خلفيات الواجهات / backgrounds
  static Color get background => AppPalette.background;
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9);

  // ألوان الحالات
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ألوان النصوص / text colors
  // ديناميكية — تُقرأ من `AppPalette` / dynamic, read from AppPalette
  static Color get textPrimary => AppPalette.textPrimary;
  static Color get textSecondary => AppPalette.textSecondary;
  static const Color textMuted = Color(0xFF94A3B8);

  // الحدود والفواصل
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}
