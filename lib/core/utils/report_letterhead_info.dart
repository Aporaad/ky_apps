// تُقيم هذه الطبقة في `lib/core` لأن الترويسة المشتركة تستهلكها كل التقارير:
// الحسابات والعملاء والعاملين (شاشةً وطباعةً)، فلا يصح حبسها داخل ميزة واحدة.
// This lives in `lib/core` because every report shares the letterhead: accounts, customers and
// workers (on screen and in PDF), so it must not be locked inside one feature.
import '../../features/app_config/data/models/app_config_model.dart';

/// بيانات ترويسة التقارير الرسمية — اسم الشركة والعنوان وأرقام التواصل،
/// بنسختين: عربية (عمود اليمين) وإنجليزية (عمود اليسار) حول شعار المنتصف.
/// Report letterhead identity: company name, address and contact numbers — in two
/// versions, Arabic (the right column) and English (the left column) around the logo.
///
/// مصدرها `APP_SETTINGS` (مفاتيح `company_*`) كما تصل من `GET /app-config` عبر
/// [AppConfigModel]، فلا نص شركة مكتوب داخل الشاشة أو داخل مولّد الـ PDF. تُبنى مرة
/// واحدة في الشاشة وتُمرَّر إلى الترويسة المعروضة وإلى مولّد التقرير المطابق لها،
/// فيبقى ما يراه المستخدم وما يُطبع متطابقين حرفياً.
/// Sourced from `APP_SETTINGS` (`company_*` keys) through the public app-config payload:
/// no company text is hardcoded in a screen or in a PDF builder. The screen builds it once
/// and passes the same object to the on-screen letterhead and to the PDF builder, so what is
/// viewed and what is printed stay byte-for-byte identical.
///
/// حين يكون حقل غير مضبوط بعد في الإعدادات، تُستخدم قيم الترويسة المطبوعة الافتراضية
/// (الثوابت `kFallback*`) Matching the company's printed letterhead. A blank setting falls
/// back to that template value, so a report never prints a half-empty header.
class ReportLetterheadInfo {
  const ReportLetterheadInfo({
    required this.companyName,
    required this.address,
    required this.phone,
    required this.website,
    this.companyNameEn = '',
    this.addressEn = '',
  });

  /// قراءة الهوية من تهيئة التطبيق الفعّالة
  /// Read the identity from the effective app configuration.
  factory ReportLetterheadInfo.fromConfig(AppConfigModel config) {
    return ReportLetterheadInfo(
      companyName: config.companyName,
      companyNameEn: config.companyNameEn,
      address: config.companyAddress,
      addressEn: config.companyAddressEn,
      phone: config.companyPhone,
      website: config.companyWebsite,
    );
  }

  // ── قيم الترويسة المطبوعة الافتراضية / printed-letterhead fallbacks ──
  static const String kFallbackNameAr = 'الكبودي للخياطة الرجالية';
  static const String kFallbackNameEn = "ALKABODI FOR MEN's TAILORING";
  static const String kFallbackAddressAr = 'الجرhف - شارع بيت الشايف';
  static const String kFallbackAddressEn = 'Airport Street - Next to Al-shayef House';
  static const String kFallbackPhone = '780154000 - 780164000 - 777430907';

  final String companyName;
  final String companyNameEn;
  final String address;
  final String addressEn;
  final String phone;
  final String website;

  /// الحقل كما ضُبط، أو قيمة الترويسة المطبوعة إن كان فارغاً
  /// The configured value, or the printed-letterhead value when it is blank.
  String get nameAr => _orFallback(companyName, kFallbackNameAr);
  String get nameEn => _orFallback(companyNameEn, kFallbackNameEn);
  String get addressAr => _orFallback(address, kFallbackAddressAr);
  String get addressEnOrFallback => _orFallback(addressEn, kFallbackAddressEn);
  String get phoneNumbers => _orFallback(phone, kFallbackPhone);

  /// سطور عمود اليمين (عربي): الاسم، ثم تحته العنوان، ثم أرقام التواصل.
  /// أرقام الهاتف تُعرض بالأرقام الهندية (٠١٢٣…) كما في الترويسة المطبوعة.
  /// The right-hand (Arabic) column: name, then address, then contact numbers —
  /// phone digits rendered as Arabic-Indic numerals exactly like the printed header.
  List<String> get arabicLines => [
        nameAr,
        if (addressAr.isNotEmpty) addressAr,
        if (phoneNumbers.isNotEmpty)
          'هاتف: ${toArabicIndicDigits(phoneNumbers)}',
        if (website.isNotEmpty) 'الموقع: $website',
      ];

  /// سطور عمود اليسار (إنجليزي): نفس المعلومات بالترتيب نفسه.
  /// The left-hand (English) column: the same information in the same order.
  List<String> get englishLines => [
        nameEn,
        if (addressEnOrFallback.isNotEmpty) addressEnOrFallback,
        if (phoneNumbers.isNotEmpty) 'Tel: $phoneNumbers',
        if (website.isNotEmpty) 'Web: $website',
      ];

  static String _orFallback(String value, String fallback) =>
      value.trim().isEmpty ? fallback : value.trim();
}

/// تحويل الأرقام اللاتينية في نص إلى أرقام هندية (٠١٢٣٤٥٦٧٨٩) لعرض عربي مطابق
/// للترويسة المطبوعة؛ باقي المحارف يمر كما هو.
/// Converts Latin digits inside a string into Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩) so the
/// Arabic side of the letterhead matches the printed header; every other character passes.
String toArabicIndicDigits(String value) {
  const latin = '0123456789';
  const indic = '٠١٢٣٤٥٦٧٨٩';

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final index = latin.indexOf(char);
    buffer.write(index >= 0 ? indic[index] : char);
  }
  return buffer.toString();
}
