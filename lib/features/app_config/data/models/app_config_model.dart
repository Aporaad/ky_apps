import 'dart:ui' show Color;

import '../../../../core/theme/app_palette.dart';

/// نموذج تهيئة التطبيق (هوية الشركة + المظهر) — غير قابل للتغيير
/// Application configuration model (company identity + theming) — immutable.
///
/// يُقرأ من الحمولة العامة `GET /app-config` (مفاتيح snake_case) ويُكتب عبر
/// `PUT /app-config`. الألوان تُخزَّن ككائنات `Color` بعد تحليل الصيغة السداسية،
/// مع fallback للقيم الافتراضية عند أي قيمة ناقصة أو تالفة — لا ننهار أبداً على بيانات الخادم.
/// Read from the public payload (`snake_case`) and written back via PUT. Colors are parsed
/// from `#RRGGBB` into [Color] objects with a default fallback: we never crash on server data.
class AppConfigModel {
  const AppConfigModel({
    required this.companyName,
    required this.companyAddress,
    required this.companyWebsite,
    required this.companyPhone,
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.fontFamily,
    this.companyNameEn = '',
    this.companyAddressEn = '',
  });

  // ── معلومات الشركة / company info ────────────────────────
  final String companyName;
  final String companyAddress;
  final String companyWebsite;
  final String companyPhone;

  /// النسخة الإنجليزية للاسم والعنوان — تُعرض يسار ترويسة التقارير.
  /// تُقرأ من مفتاحي `company_name_en` / `company_address_en` إن أرسلهما الخادم، وإلا
  /// تُعوَّض بالافتراضي المضمّن هنا؛ وأي عنوان إنجليزي فارغ تتكفل به الترويسة المطبوعة.
  /// English name/address, shown on the left of the report letterhead. They come from the
  /// `company_name_en` / `company_address_en` keys when the server sends them, otherwise from the
  /// defaults baked into this model — and a blank English address makes the letterhead fall back to
  /// the wording of the printed header.
  final String companyNameEn;
  final String companyAddressEn;

  /// اسم التطبيق الظاهر في الشريط العلوي/nice title
  final String appName;

  // ── الألوان الخمسة / the five theme colors ───────────────
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;

  /// عائلة الخط المختارة (ضمن القائمة المسموحة) / selected font family
  final String fontFamily;

  /// القيم الافتراضية — مطابقة لـ `AppConfig::DEFAULTS` في الخادم و`AppPalette` في العميل
  /// Defaults — mirror the server `AppConfig::DEFAULTS` and the client `AppPalette`.
  factory AppConfigModel.defaults() {
    return AppConfigModel(
      companyName: 'الكبودي للخياطة الرجالية',
      companyAddress: '',
      companyWebsite: '',
      companyPhone: '',
      appName: 'الكبودي للخياطة الرجاليه',
      companyNameEn: "ALKABODI FOR MEN's TAILORING",
      companyAddressEn: '',
      primaryColor: AppPalette.primary,
      secondaryColor: AppPalette.accent,
      backgroundColor: AppPalette.background,
      textPrimaryColor: AppPalette.textPrimary,
      textSecondaryColor: AppPalette.textSecondary,
      fontFamily: AppPalette.fontFamily,
    );
  }

  /// تحليل الحمولة العامة القادمة من الخادم (مفاتيح snake_case)
  /// Parse the public payload from the server (snake_case keys).
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    // الحمولة قد تكون داخل غلاف `{success, data}` أو مفكوكة مباشرة — نتعامل مع الاثنين
    // The payload may be wrapped in `{success, data}` or already unwrapped — handle both.
    final Map<String, dynamic> src;
    if (json['data'] is Map<String, dynamic>) {
      src = json['data'] as Map<String, dynamic>;
    } else {
      src = json;
    }

    return AppConfigModel(
      companyName: _readString(src['company_name'], 'الكبودي للخياطة الرجالية'),
      companyAddress: _readString(src['company_address'], ''),
      companyWebsite: _readString(src['company_website'], ''),
      companyPhone: _readString(src['company_phone'], ''),
      appName: _readString(src['app_name'], 'الكبودي للخياطة الرجاليه'),
      // قراءة بفتحتي حالة كما في بقية النماذج: الخادم يمرّر صفوف أوراكل الخام
      // Dual-case read like every other model: the API proxies raw Oracle rows.
      companyNameEn: _readString(
        src['company_name_en'] ?? src['COMPANY_NAME_EN'],
        'ALKABODI FOR MEN\'s TAILORING',
      ),
      companyAddressEn: _readString(
        src['company_address_en'] ?? src['COMPANY_ADDRESS_EN'],
        '',
      ),
      primaryColor: _parseHexColor(
        src['theme_primary_color'],
        AppPalette.primary,
      ),
      secondaryColor: _parseHexColor(
        src['theme_secondary_color'],
        AppPalette.accent,
      ),
      backgroundColor: _parseHexColor(
        src['theme_background_color'],
        AppPalette.background,
      ),
      textPrimaryColor: _parseHexColor(
        src['theme_text_primary_color'],
        AppPalette.textPrimary,
      ),
      textSecondaryColor: _parseHexColor(
        src['theme_text_secondary_color'],
        AppPalette.textSecondary,
      ),
      fontFamily: _readString(src['theme_font_family'], 'Cairo'),
    );
  }

  /// تحويل النموذج إلى JSON للكتابة عبر `PUT /app-config` (سداسي `#RRGGBB`)
  /// Serialize for the PUT body — colors as `#RRGGBB`, snake_case keys.
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'company_name': companyName,
      'company_address': companyAddress,
      'company_website': companyWebsite,
      'company_phone': companyPhone,
      'company_name_en': companyNameEn,
      'company_address_en': companyAddressEn,
      'app_name': appName,
      'theme_primary_color': _colorToHex(primaryColor),
      'theme_secondary_color': _colorToHex(secondaryColor),
      'theme_background_color': _colorToHex(backgroundColor),
      'theme_text_primary_color': _colorToHex(textPrimaryColor),
      'theme_text_secondary_color': _colorToHex(textSecondaryColor),
      'theme_font_family': fontFamily,
    };
  }

  /// نسخة معدّلة جزئياً — تُستخدم في شاشة التهيئة أثناء التحرير
  /// Partial copy — used by the config screen while editing.
  AppConfigModel copyWith({
    String? companyName,
    String? companyAddress,
    String? companyWebsite,
    String? companyPhone,
    String? appName,
    String? companyNameEn,
    String? companyAddressEn,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    String? fontFamily,
  }) {
    return AppConfigModel(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyPhone: companyPhone ?? this.companyPhone,
      appName: appName ?? this.appName,
      companyNameEn: companyNameEn ?? this.companyNameEn,
      companyAddressEn: companyAddressEn ?? this.companyAddressEn,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  /// دفع الألوان والخط إلى `AppPalette` الزمني (تُستدعى قبل بناء السمة/إعادة التشغيل)
  /// Push colors + font into the runtime [AppPalette] (called before building the theme).
  void applyToPalette() {
    AppPalette.applyColors(
      primaryHex: _colorToHex(primaryColor),
      secondaryHex: _colorToHex(secondaryColor),
      backgroundHex: _colorToHex(backgroundColor),
      textPrimaryHex: _colorToHex(textPrimaryColor),
      textSecondaryHex: _colorToHex(textSecondaryColor),
      font: fontFamily,
    );
  }

  // ── مساعدات التحليل الآمن / safe parsing helpers ─────────

  /// نص مع fallback — يتجاهل null والفارغ البحت
  /// String with fallback — ignores null and blank text.
  static String _readString(Object? value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  /// تحليل لون سداسي `#RRGGBB` مع الرجوع إلى [fallback] عند أي صيغة غير صالحة
  /// Parse a `#RRGGBB` color, falling back to [fallback] on any invalid input.
  static Color _parseHexColor(Object? value, Color fallback) {
    if (value == null) return fallback;
    final cleaned = value.toString().trim().replaceFirst('#', '');
    if (cleaned.length != 6) return fallback;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }

  /// تحويل `Color` إلى سداسي `#RRGGBB` (قناة الشفافية مُهملة — الخادم يتوقع RGB فقط)
  /// Convert a [Color] to `#RRGGBB` (alpha dropped — the server expects RGB only).
  static String _colorToHex(Color color) {
    // في هذا الإصدار r/g/b قيمها double بين 0.0 و1.0 — نضرب في 255 مع تقريب
    // In this SDK r/g/b are doubles in 0.0..1.0 — scale by 255 with rounding.
    String two(double v) =>
        (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${two(color.r)}${two(color.g)}${two(color.b)}'.toUpperCase();
  }
}
