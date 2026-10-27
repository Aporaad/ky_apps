/// عدّاد النقرات الخفي لفتح إعدادات الـ API من اسم المطور
/// The hidden tap counter that unlocks the API settings from the developer's name.
///
/// القاعدة: خمس نقرات متتالية خلال ثلاث ثوانٍ تُعتبر طلباً؛ أي فجوة أطول تُصفّر العدّاد،
/// فالضغطات العَرَضية أثناء التمرير لا تفتح شيئاً. المنطق هنا نقيّ تماماً (ساعة قابلة للحقن)
/// كي يُختبر بلا واجهة ولا انتظار حقيقي.
/// The rule: five consecutive taps within three seconds count as a request; a longer gap resets
/// the counter, so incidental taps while scrolling open nothing. The logic is deliberately pure
/// (injectable clock) so it can be tested with no UI and no real waiting.
class DeveloperTapUnlock {
  DeveloperTapUnlock({
    this.required = 5,
    this.window = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// عدد النقرات المطلوب لإتمام الطلب
  /// How many taps complete the request.
  final int required;

  /// أقصى فجوة مسموحة بين نقرتين قبل التصفير
  /// The longest gap allowed between two taps before the counter resets.
  final Duration window;

  final DateTime Function() _now;

  int _count = 0;
  DateTime? _lastTap;

  /// عدد النقرات المتراكمة حتى الآن — للعرض/التصحيح فقط
  /// The taps accumulated so far — for display/debugging only.
  int get count => _count;

  /// تسجيل نقرة؛ تعيد `true` عند اكتمال العدد، وتُصفّر العدّاد فوراً بعد النجاح
  /// Register a tap; returns true when the count completes, and resets immediately on success.
  ///
  /// التصفير بعد النجاح مقصود: الفتح التالي يحتاج خمس نقرات جديدة كاملة، فلا يُترك عدّاد
  /// «شبه مكتمل» يفتح الشاشة بنقرة واحدة لاحقاً.
  /// The reset on success is deliberate: the next unlock needs five fresh taps, so no
  /// "almost complete" counter is left behind to open the screen with one stray tap later.
  bool registerTap() {
    final now = _now();
    final previous = _lastTap;

    if (previous == null || now.difference(previous) > window) {
      _count = 1;
      _lastTap = now;

      // طلب من نقرة واحدة ممكن فقط إن كان `required` مساوياً 1
      // A one-tap request is possible only when `required` is 1.
      if (_count >= required) {
        _count = 0;
        _lastTap = null;

        return true;
      }

      return false;
    }

    _count++;
    _lastTap = now;

    if (_count < required) return false;

    _count = 0;
    _lastTap = null;

    return true;
  }

  /// تصفير يدوي — عند مغادرة الشاشة أو إلغاء المحاولة
  /// Manual reset — when leaving the screen or abandoning the attempt.
  void reset() {
    _count = 0;
    _lastTap = null;
  }
}
