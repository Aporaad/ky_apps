/// ترجمة موعد الجلسة القادم من ساعة الخادم إلى ساعة الجهاز
/// Translates the server-clock session deadline onto the device clock.
///
/// لماذا؟ الخادم يرسل `X-Session-Expires-At` كنص `YYYY-MM-DD HH:MM:SS` على ساعة أوراكل بلا أي
/// علامة منطقة زمنية. لو قارنه الحارس المحلي بـ `DateTime.now()` مباشرةً فأي اختلاف بين ساعتين
/// (منطقة، ساعة يدويّة مضبوطة خطأ، أو فرق ثوانٍ تراكمي) يتحول إلى قرار طرد: جهازٌ ساعته متأخرة
/// بساعة يُطرد مستخدمه فوراً، وجهازٌ متقدمة بساعة يبقى موصولاً بعد الموعد.
/// Why: the server sends the deadline as plain text on the Oracle clock with no zone marker. If the
/// local watchdog compares it straight against `DateTime.now()`, any disagreement between the two
/// clocks becomes an eviction decision — a device an hour behind is kicked instantly, a device an
/// hour ahead stays signed in past the real deadline.
///
/// الحل: قياس الإزاحة `serverNow - deviceNow` من ترويسة `X-Server-Now` التي ترافق الموعد في نفس
/// الرد، ثم طرحها من الموعد. يبقى القياس كله على ساعة الجهاز، فلا يعود لاختلاف الساعتين أي أثر.
/// The fix: measure the offset from the `X-Server-Now` header that rides on the same response, then
/// subtract it. Everything after that is compared on the device clock alone, so a clock mismatch
/// stops mattering.
class SessionClock {
  SessionClock._();

  /// تحويل نص الخادم إلى وقت. يُرجع null إن كان النص فارغاً أو غير مقروء.
  /// Parse the server's date text; null when it is absent or unreadable.
  static DateTime? parseServerText(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    // لا علامة منطقة في النص: يُقرأ كوقت محلي ثم تُصحّح الإزاحة بدالة resolve أدناه
    // The text carries no zone marker: read as local, then corrected by resolve() below.
    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  /// موعد النهاية على ساعة الجهاز، أو null حين لا يوجد موعد معلوم.
  /// The deadline expressed on the device clock, or null when nothing was asserted about expiry.
  ///
  /// `serverNowText` اختيارية: عند غياب الترويسة (خادم أقدم لم يُحدَّث بعد) نتصرف كما كان يُعمل
  /// سابقاً ونعتبر الساعتين متطابقتين — فتظل الخطة تعمل على بيئات لم يُنشر لها الـ API بعد.
  /// `serverNowText` is optional: without it (an API build that predates the header) we assume the
  /// clocks agree, exactly as before, so the fix degrades gracefully on un-deployed back ends.
  static DateTime? resolve({
    required String? deadlineText,
    String? serverNowText,
    DateTime? deviceNow,
  }) {
    final serverDeadline = parseServerText(deadlineText);
    if (serverDeadline == null) return null;

    final now = deviceNow ?? DateTime.now();
    final serverNow = parseServerText(serverNowText);
    if (serverNow == null) return serverDeadline;

    // الإزاحة موجبة حين ساعة الخادم متقدمة؛ تُطرح من الموعد فنتحصل عليه بوقت الجهاز
    // Positive when the server clock runs ahead; subtracting it lands the deadline on device time.
    return serverDeadline.subtract(serverNow.difference(now));
  }
}
