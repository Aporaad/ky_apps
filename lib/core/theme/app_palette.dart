import 'package:flutter/material.dart';

/// حامل الألوان الزمني للتطبيق
/// Runtime color holder for the application.
///
/// الهدف: فصل «القيم القابلة للتغيير» (ألوان السمة + الخط) عن `AppColors` الثابت.
/// الغرض: `AppColors` يبقى الواجهة المستخدمة في كل الشاشات، وكل حقل ديناميكي فيه
/// يفوّض إلى `AppPalette` هنا. عند تحميل التهيئة من الخادم أو الكاش تُحدَّث هذه
/// الحقول قبل بناء `ThemeData`، فتسري على كامل التطبيق بعد إعادة التشغيل.
/// Purpose: keep the changeable theme values (colors + font) separate from the
/// static `AppColors` facade. The five dynamic fields delegate here. Server/cache
/// config updates these before the theme is built, so they apply app-wide on restart.
class AppPalette {
  AppPalette._();

  // ── القيم الافتراضية الحالية (تطابق `AppConfig::DEFAULTS` في الخادم) ──
  // Current defaults — must match the server `AppConfig::DEFAULTS`.
  static const Color _defaultPrimary = Color.fromRGBO(162, 126, 78, 1); // #A27E4E
  static const Color _defaultAccent = Color(0xFF0D9488); // secondary
  static const Color _defaultBackground = Color(0xFFF8FAFC);
  static const Color _defaultTextPrimary = Color(0xFF0F172A);
  static const Color _defaultTextSecondary = Color(0xFF475569);

  /// اللون الأساسي / primary
  static Color primary = _defaultPrimary;

  /// اللون الثانوي (accent) / secondary
  static Color accent = _defaultAccent;

  /// لون الخلفية / background
  static Color background = _defaultBackground;

  /// لون النص الرئيسي / main text
  static Color textPrimary = _defaultTextPrimary;

  /// لون النص العادي / normal text
  static Color textSecondary = _defaultTextSecondary;

  /// اللون الداكن المشتق — يُستخدم كرأس لوحة ونصوص داكنة، وافتراضياً يطابق النص الرئيسي
  /// Derived dark color — defaults to the main text color.
  static Color primaryDark = _defaultTextPrimary;

  /// عائلة الخط الحالية (Cairo افتراضياً) / active font family
  static String fontFamily = 'Cairo';

  /// هل تم ضبط الألوان يدوياً (للتشخيص) / whether palette was customized
  static bool get customized =>
      primary != _defaultPrimary ||
      accent != _defaultAccent ||
      background != _defaultBackground ||
      textPrimary != _defaultTextPrimary ||
      textSecondary != _defaultTextSecondary;

  /// إعادة تعيين كل الحقول إلى القيم الافتراضية (تُستدعى قبل تطبيق تهيئة جديدة)
  /// Reset every field to its default. Called before applying a fresh config.
  static void resetToDefaults() {
    primary = _defaultPrimary;
    accent = _defaultAccent;
    background = _defaultBackground;
    textPrimary = _defaultTextPrimary;
    textSecondary = _defaultTextSecondary;
    primaryDark = _defaultTextPrimary;
    fontFamily = 'Cairo';
  }

  /// تحويل لون سداسي `#RRGGBB` إلى `Color` مع الرجوع للقيمة الافتراضية عند الفشل
  /// Parse a `#RRGGBB` hex string into a [Color], falling back to [fallback].
  static Color parseHex(String? hex, Color fallback) {
    if (hex == null) return fallback;
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length != 6) return fallback;
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(0xFF000000 | value);
  }

  /// تطبيق مجموعة ألوان كاملة من قيم سداسية (قادمة من الخادم/الكاش) دفعة واحدة
  /// Apply a full color set from hex values (server/cache) in one call.
  static void applyColors({
    String? primaryHex,
    String? secondaryHex,
    String? backgroundHex,
    String? textPrimaryHex,
    String? textSecondaryHex,
    String? font,
  }) {
    primary = parseHex(primaryHex, _defaultPrimary);
    accent = parseHex(secondaryHex, _defaultAccent);
    background = parseHex(backgroundHex, _defaultBackground);
    textPrimary = parseHex(textPrimaryHex, _defaultTextPrimary);
    textSecondary = parseHex(textSecondaryHex, _defaultTextSecondary);
    // اللون الداكن يتبع النص الرئيسي افتراضياً ليبقى متناسقاً
    // The dark color follows the main text so the palette stays coherent.
    primaryDark = textPrimary;
    if (font != null && font.trim().isNotEmpty) {
      fontFamily = font.trim();
    }
  }
}
