import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// فتح الروابط الخارجية من شاشة معلومات البرنامج والدعم
/// Opening external links from the app-info & support screen.
///
/// لماذا لا `canLaunchUrl` أولاً؟ لأنها تعيد `false` على أندرويد 11+ حين لا يكون التطبيق
/// مُعلَناً في `<queries>` — فتُخفي زرّاً يعمل فعلاً. البدء بالمحاولة ثم عرض رسالة عند الفشل
/// يترك الحكم لنظام التشغيل نفسه.
/// Why not `canLaunchUrl` first? On Android 11+ it returns false when the manifest's `<queries>`
/// does not declare the scheme — hiding a button that would actually work. Attempting the launch
/// and reporting a failure leaves the verdict to the OS itself.
class ExternalLinks {
  ExternalLinks._();

  /// فتح مستند بالرابط (موقع الشركة مثلاً)
  /// Open a web URL (the company website, for instance).
  static Future<void> openUrl(BuildContext context, String? url) async {
    final target = _normalize(url);
    if (target == null) return;

    await _launch(context, target);
  }

  /// فتح تطبيق الهاتف على رقم معيّن
  /// Open the dialer on a given number.
  static Future<void> openTel(BuildContext context, String? phone) async {
    final target = buildTelUri(phone);
    if (target == null) return;

    await _launch(context, target);
  }

  /// بناء رابط `tel:` من رقم قد يكون محلياً (بلا مفتاح دولة) أو دولياً كاملاً
  /// Build a `tel:` URI from a number that may be local (no country code) or fully international.
  ///
  /// لماذا التطبيع؟ الهاتف في `APP_SETTINGS` يُكتب كما ينطقه الناس — `780154000` لا
  /// `+967780154000` — وتمريره بـ `+` كما هو ينتج `+780154000`، وهو رقم لا وجود له في أي شبكة
  /// فيفتح المتصفح/الطالب على خطأ. اليمن هو بلد النشاط، فالرقم المحلي يُكمَّل بـ `967` مع حذف
  /// صفر البداية إن وُجد، والرقم الذي يحمل مفتاح الدولة (12 خانة فأكثر أو يبدأ بـ 967) يبقى كما هو.
  /// Why normalise? The phone is stored as people say it — `780154000`, not `+967780154000` — and
  /// prefixing a bare `+` yields `+780154000`, a number no network has. Yemen is the country of
  /// operation, so a local number gains `967` (its leading trunk zero dropped), while a number that
  /// already carries a country code (12+ digits, or starting with 967) is left untouched.
  ///
  /// يعيد `null` حين لا يبقى أي رقم بعد التنقية — لا نفتح طالباً فارغاً.
  /// Returns null when no digits survive, so no empty dialer is opened.
  static Uri? buildTelUri(String? phone) {
    final digits = internationalDigits(phone);
    if (digits == null) return null;

    return Uri(scheme: 'tel', path: '+$digits');
  }

  /// أرقام الرقم بصيغته الدولية بلا `+` — أساس `tel:` و`wa.me` معاً
  /// The number's digits in international form without `+` — the base for both `tel:` and `wa.me`.
  ///
  /// دالة نقية عامة كي تُختبر وحدها وكي يستعملها مسار واتساب بنفس القواعد بلا تكرار.
  /// A public pure function so it can be tested alone and reused by the WhatsApp path verbatim.
  static String? internationalDigits(String? phone) {
    final digits = _digitsOf(phone);
    if (digits == null) return null;

    return _withCountryCode(digits);
  }

  /// فتح محادثة واتساب مع رقم هاتف (رقم الشركة في قاعدة البيانات مثلاً)
  /// Open a WhatsApp chat with a phone number (the company number from the database, say).
  ///
  /// `wa.me` لا يقبل `+` ولا مسافات: الرابط يُبنى من الأرقام الدولية وحدها.
  /// `wa.me` accepts neither `+` nor spaces, so the link is built from the international digits.
  static Future<void> openWhatsappTo(BuildContext context, String? phone) async {
    final digits = internationalDigits(phone);
    if (digits == null) return;

    await _launch(context, Uri.parse('https://wa.me/$digits'));
  }

  /// إكمال مفتاح الدولة للرقم المحلي (967 — اليمن)
  /// Complete the country code for a local number (967 — Yemen).
  static String _withCountryCode(String digits) {
    // بادئة الاتصال الدولية المكتوبة `00` تُحذف قبل أي فحص
    // A dialled international prefix written as `00` is stripped before any check.
    final international = digits.startsWith('00') ? digits.substring(2) : digits;

    if (international.startsWith('967') || international.length >= 12) {
      return international;
    }

    final withoutTrunk = international.startsWith('0')
        ? international.substring(1)
        : international;

    return '967$withoutTrunk';
  }

  /// فتح موقع الشركة على خرائط جوجل بالبحث عن عنوانها المخزَّن في قاعدة البيانات
  /// Open the company's location in Google Maps by searching its database-stored address.
  ///
  /// لا نحتاج إحداثيات: البحث بالنص يفتح الخريطة على أقرب مطابقة للعنوان، وهو أنفع من مصفوفة
  /// lat/long في جدول الإعدادات لا يملؤها أحد.
  /// No coordinates are needed: a text search drops the map on the closest match for the address,
  /// which is more useful than a lat/long pair in the settings table that nobody would fill.
  static Future<void> openMap(BuildContext context, String? address) async {
    final text = (address ?? '').trim();
    if (text.isEmpty) return;

    final query = Uri.encodeComponent(text);

    await _launch(
      context,
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
    );
  }

  /// فتح واتساب على رابط `wa.me`
  /// Open WhatsApp through a `wa.me` link.
  static Future<void> openWhatsapp(BuildContext context, String url) async {
    await _launch(context, Uri.parse(url));
  }

  /// إطلاق الرابط بالخارج مع رسالة فشل واحدة موحّدة
  /// Launch the URL externally, with one shared failure message.
  static Future<void> _launch(BuildContext context, Uri uri) async {
    var launched = false;

    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (launched || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح الرابط على هذا الجهاز')),
    );
  }

  /// رابط الموقع: نضيف `https://` إن جاء الخادم بعنوان بلا بروتوكول، ونرفض ما ليس رابطاً
  /// Site URL: prepend `https://` when the server stored a bare host, and reject anything that
  /// is not a URL at all.
  static Uri? _normalize(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) return null;

    final withScheme = text.contains('://') ? text : 'https://$text';
    final uri = Uri.tryParse(withScheme);

    if (uri == null || uri.host.isEmpty) return null;

    return uri;
  }

  /// أرقام فقط من رقم مكتوب بمسافات أو شرطات
  /// Digits only, from a number written with spaces or dashes.
  static String? _digitsOf(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');

    return digits.isEmpty ? null : digits;
  }
}
