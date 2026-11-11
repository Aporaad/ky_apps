/// هوية الطابع الرسمي للتقارير — اسم المستخدم الذي يطبع/يصدّر التقرير حالياً.
/// The official printing identity for reports — the user currently printing/exporting.
///
/// ── لماذا حامل مركزي ساكن؟ مولّدات PDF دوال نقية بلا وصول إلى Riverpod ولا إلى `context`،
///    والتذييل الرسمي (`ReportSignatureFooter` على الشاشة و`pdfSignatures()` في الـ PDF) مكانٌ
///    واحد يُستهلك من كل تقارير النظام. الحامل يضمن أن الشاشة والمُخرَج المطبوع يعرضان الاسم
///    نفسه في اللحظة نفسها، وأن أي تقرير جديد يرث الحقل تلقائياً بلا تمرير معاملات.
/// ── Why one static holder? The PDF builders are pure functions with no Riverpod or widget
///    context, while the official footer (`ReportSignatureFooter` on screen and `pdfSignatures()`
///    in the PDF) is a single place consumed by every report in the system. This holder keeps the
///    viewed and printed name identical at the same instant, and any new report inherits the field
///    with zero parameter plumbing.
///
/// الكاتب الوحيد هو `AuthNotifier` عند كل انتقال لحالة الدخول (نجاح دخول عادي/بصمة، استعادة
/// جلسة عند الإقلاع، خروج عادي/إجباري) — فلا تتسرب هوية مستخدم إلى جلسة تالية على نفس الجهاز.
/// The only writer is `AuthNotifier` on every auth transition (password or biometric sign-in,
/// session restore at boot, normal or forced logout), so one user's identity never leaks into the
/// next session on the same device.
class ReportPrintIdentity {
  /// خاص — الكلاس واجهة ساكنة تُستخدم من كل الطبقات ولا تُبنى منها instances
  /// Private — this class is a static facade used across layers; it is never instantiated.
  ReportPrintIdentity._();

  static String? _printedBy;

  /// اسم الطابع الحالي، أو null قبل تسجيل الدخول — يُعرض حينها التذييل بلا سطر «بواسطة».
  /// The current printer's name, or null before sign-in — the footer then omits the «بواسطة» line.
  static String? get printedBy => _printedBy;

  /// تسجيل هوية الطابع بعد دخول ناجح أو استعادة جلسة. القيم الفارغة/المسافات تعني «لا اسم».
  /// Record the printing identity after a successful sign-in or session restore; blank text
  /// (whitespace only) means no name is asserted and is stored as null.
  static void set(String? displayName) {
    final name = displayName?.trim() ?? '';
    _printedBy = name.isEmpty ? null : name;
  }

  /// مسح الهوية عند الخروج — حتى لا يُطبع اسم المستخدم القديم على مستندات من جلسة جديدة.
  /// Clear on logout, so a previous user's name never appears on documents printed in a later
  /// session on a shared device.
  static void clear() => _printedBy = null;
}
