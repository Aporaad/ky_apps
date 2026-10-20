import 'arabic_encoding_utils.dart';

/// قراءة آمنة من حمولة JSON قادمة من أوراكل عبر الـ API
/// Defensive reads from JSON payloads that originate in Oracle.
///
/// لماذا ملف مشترك بدل مساعدات خاصة داخل كل نموذج؟ أعمدة IBAC خمسة نماذج تقرأ نفس الأشكال
/// (رقمٌ قد يصل نصاً، ومنطقيٌ يصل 1/0، وتاريخٌ يصل فارغاً أو `false`)، وتكرار أربع دوال في كل
/// ملف — كما فعلت نماذج العملاء والعاملين — يجعل أي تصحيح لقراءةٍ ما يحتاج خمس بقع بدل واحدة.
/// The IBAC models all read the same shapes (numbers arriving as text, booleans as 1/0, dates as
/// empty or `false`). Repeating four helpers per file, as the customer/worker models do, would
/// turn one fix into five patches.
class JsonValues {
  JsonValues._();

  /// عدد صحيح مع قيمة احتياطية؛ القيم الكسرية تُقتص لا تُقرَّب
  /// Integer with a fallback; fractional values are truncated, never rounded up.
  static int asInt(dynamic value, {int fallback = 0}) =>
      asIntOrNull(value) ?? fallback;

  /// عدد صحيح أو null — للأكواد التي يعني غيابها شيئاً مختلفاً عن الصفر (`branch_no`)
  /// Integer or null, where absence means something other than zero (`branch_no`).
  static int? asIntOrNull(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();

    return int.tryParse(value.toString().trim());
  }

  /// عدد عشري أو null
  /// Decimal or null.
  static double? asDoubleOrNull(dynamic value) {
    if (value == null || value == false) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(value.toString().trim());
  }

  /// منطقية بصمت آمن: كل ما ليس صريحاً في الصدق يعني false، وهو نفس رفض الخادم الافتراضي
  /// Boolean, silently: anything not explicitly truthy is false, mirroring server-side denial.
  static bool asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();

      return text == '1' || text == 'true' || text == 'yes' || text == 'on';
    }

    return false;
  }

  /// 1/0 بصيغة عددية — الأعمدة الرقمية في أوراكل لا تصل منطقية أبداً
  /// Numeric 0/1: Oracle number columns never arrive as booleans.
  static bool asFlag(dynamic value, {bool fallback = false}) {
    if (value == null || value == false) return fallback;

    return asBool(value);
  }

  /// نص خام بلا تصحيح عربي — للأرقام والرموز اللاتينية ومسارات الملفات
  /// Raw text with no Arabic repair — for ids, Latin codes, and platform names.
  static String? asText(dynamic value, {bool trim = true}) {
    if (value == null || value == false) return null;
    final text = value.toString();
    final out = trim ? text.trim() : text;

    return out.isEmpty ? null : out;
  }

  /// نص عربي بعد تصحيح بايتات CP1256 — إلزامي لكل حقل قد يعرض بالعربية
  /// Arabic text after the CP1256 repair pass — mandatory for any field shown in Arabic.
  ///
  /// الخادم يصلّي العربية في أغلب المسارات، لكن `fix()` عديمة التأثير على النص السليم (فهي لا
  /// تمسّ محارف U+0600 وما فوق)، فتمريره على نص مُصلَّح لا يفسده وتكراره يغطي أي مسار قرأ خاماً.
  /// The server usually repairs Arabic, but `fix()` is a no-op on healthy text (it only maps the
  /// 0x80–0xFF range), so applying it again is harmless and covers any raw read path.
  static String? asArabic(dynamic value) {
    final text = asText(value);
    if (text == null) return null;

    return ArabicEncodingUtils.fix(text);
  }

  /// نص عربي مضمون غير فارغ — للحقول التي تعرض دوماً (الاسم اللاتيني مثلاً)
  /// Guaranteed non-empty Arabic text, for fields always rendered (the Latin name, say).
  static String arabicOrEmpty(dynamic value) =>
      asArabic(value) ?? '';

  /// نص خام مضمون غير فارغ
  /// Guaranteed non-empty raw text.
  static String textOrEmpty(dynamic value) => asText(value) ?? '';

  /// قائمة أكواد/نصوص من قائمة JSON، مع إسقاط العناصر الفارغة بدل أن ينفجر العرض
  /// A list of codes/text from JSON, dropping empty entries instead of throwing at parse time.
  static List<String> asStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  /// قائمة أرقام المعرّفات — تُقرأ من `granted_ids`
  /// A list of numeric ids, read from `granted_ids`.
  static List<int> asIntList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map(asIntOrNull)
        .whereType<int>()
        .toList(growable: false);
  }

  /// تاريخ نصه `YYYY-MM-DD HH:MM:SS` أو ISO، أو null عند أي قراءة غير مفهومة
  /// A `YYYY-MM-DD HH:MM:SS` or ISO date, or null for anything unreadable.
  ///
  /// أعمدة DATE الفارغة في أوراكل قد تصل `false` أو نصاً فارغاً أو `0000-00-00`، وأيّ منها يجب
  /// أن يسقط إلى null لا أن ينفجر في واجهة تعرض «لا يوجد».
  /// Empty Oracle DATE columns arrive as `false`, `''`, or `0000-00-00`; all must fall to null
  /// rather than throw in a screen that renders "none".
  static DateTime? asDate(dynamic value) {
    final text = asText(value);
    if (text == null || text.startsWith('0000')) return null;

    return DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  /// عرض الوقت للتاريخ القادم من الخادم، بصيغة `YYYY-MM-DD HH:MM` أو '—' عند الغياب
  /// Display a server date as `YYYY-MM-DD HH:MM`, or '—' when absent.
  static String formatDate(dynamic value, {bool withTime = true}) {
    final date = value is DateTime ? value : asDate(value);
    if (date == null) return '—';

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    if (!withTime) return '$y-$m-$d';

    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');

    return '$y-$m-$d $hh:$mm';
  }
}
