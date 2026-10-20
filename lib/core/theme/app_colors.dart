import 'package:flutter/material.dart';

/// لوحة الألوان الموحدة للتطبيق
/// Application unified color palette
class AppColors {
  // الألوان الأساسية
  //static const Color primary = Color(0xFF932639); // أزرق كحلي ملكي
  // static const Color primary = Color(0xFF5e1f10);
  static const Color primary = Color.fromRGBO(162, 126, 78,1);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF0F172A);

  // الألوان الثانوية والتمييز
  static const Color accent = Color(0xFF0D9488); // زمردي / تيل
  static const Color accentLight = Color(0xFF14B8A6);
  static const Color secondary = Color(0xFF64748B);

  // خلفيات الواجهات
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9);

  // ألوان الحالات
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // الحدود والفواصل
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
}
