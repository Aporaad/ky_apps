import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_palette.dart';

/// السمة المركزية للتطبيق مع تطبيق الخط العربي الموحد ودعم RTL
/// Centralized App Theme with unified Arabic typography and RTL support
///
/// تُبنى السمة من `AppPalette` الزمني حتى تعكس تهيئة التطبيق (الألوان الخمسة + الخط)
/// القادمة من الخادم. الدالة `build()` هي المصدر الفعلي؛ و`lightTheme` بقِيَت كـgetter
/// يفوّض إليها للتوافق مع الاستدعاءات القديمة.
/// The theme is built from the runtime [AppPalette] so it reflects the server-driven
/// app config (five colors + font). [build] is the real source; [lightTheme] is kept as
/// a delegating getter for backward compatibility with existing call sites.
class AppTheme {
  /// يبني `ThemeData` من الألوان والخط الحاليين في `AppPalette`
  /// Builds [ThemeData] from the current [AppPalette] colors and font.
  static ThemeData build() {
    final baseTextTheme = ThemeData.light().textTheme;
    final font = AppPalette.fontFamily;
    // Cairo أصبح عائلة مضمّنة بأوزانها الحقيقية (400/700) في pubspec، فنستخدمها
    // مباشرة بلا تنزيل شبكي وبلا «عريض اصطناعي» — وهذا هو جوهر إصلاح تشوّه «و» و«ص»
    // في العناوين والنصوص العريضة. بقية الخطوط المختارة تبقى عبر google_fonts.
    // Cairo is now a bundled family with real weights, so we use it directly — no
    // network download and no synthetic bold (the root cause of the و/ص distortion).
    final fontFamily = _isBundledCairo(font) ? 'Cairo' : GoogleFonts.getFont(font).fontFamily;
    // تطبيق الخط المختار على كامل الـ TextTheme (Cairo افتراضياً)
    // Apply the selected font across the whole TextTheme (Cairo by default).
    final arabicTextTheme = baseTextTheme.apply(
      fontFamily: fontFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: arabicTextTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: _font(
          font,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          // لا يمكن استخدام const هنا لأن اللون ديناميكي / color is dynamic now
          borderSide: BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: _font(
          font,
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: _font(
          font,
          color: AppColors.textMuted,
          fontSize: 13,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _font(
            font,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  /// السمة الفاتحة — تفوّض إلى `build()` للتوافق مع الاستدعاءات القائمة
  /// Light theme — delegates to [build] for compatibility with existing call sites.
  static ThemeData get lightTheme => build();

  /// هل الخط المختار هو Cairo المضمّن؟ (مقارنة غير حساسة لحالة الأحرف والمسافات)
  /// Whether the selected font is the bundled Cairo (case/whitespace-insensitive).
  static bool _isBundledCairo(String font) =>
      font.trim().toLowerCase() == 'cairo';

  /// يبني TextStyle لعائلة الخط المختارة: Cairo المضمّن يُستخدم مباشرة بوزنه
  /// الحقيقي (عائلة Flutter مُسجّلة في pubspec) فيجنّب العريض الاصطناعي والتنزيل
  /// الشبكي؛ وبقية الخطوط تمرّ عبر google_fonts كما هي.
  /// Builds a TextStyle for the selected family: bundled Cairo is used directly with
  /// its real weight (registered in pubspec) — avoiding synthetic bold and network
  /// download; other fonts still go through google_fonts.
  static TextStyle _font(
    String font, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    if (_isBundledCairo(font)) {
      return TextStyle(
        fontFamily: 'Cairo',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.getFont(
      font,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
    );
  }
}
