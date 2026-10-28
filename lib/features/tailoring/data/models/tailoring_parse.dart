import '../../../../core/utils/arabic_encoding_utils.dart';

/// مساعدات قراءة حقول التفصيل — مشتركة بين نماذج الميزة كلها
/// Tailoring field readers — shared by every model of the feature.
///
/// مصدر البيانات أوراكل: المفاتيح قد تصل بأي حالة، والأرقام نصوصاً، والعربية بايتات
/// CP1256 مشوّهة، والتواريخ قد تحمل `Z`. التطبيع كله هنا لا في الواجهة.
/// The source is Oracle: keys arrive in either case, numbers as strings, Arabic as CP1256
/// mojibake bytes and dates may carry `Z`. All normalisation lives here, not in the UI.

/// قيمة حقل من خريطة JSON بحثاً عن الحالتين (كبرى/صغرى)
/// A field value looked up in both key cases (upper/lower).
dynamic tailoringField(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  if (json.containsKey(lower)) return json[lower];
  final upper = key.toUpperCase();
  if (json.containsKey(upper)) return json[upper];
  return null;
}

/// رقم صحيح مع دعم النص والأرقام العشرية
/// An integer supporting strings and decimal values.
int? tailoringInt(Map<String, dynamic> json, String key) {
  final v = tailoringField(json, key);
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString().trim());
}

/// رقم عشري مع دعم النص والعرب
/// A decimal supporting strings and prepared ints.
double? tailoringDouble(Map<String, dynamic> json, String key) {
  final v = tailoringField(json, key);
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return double.tryParse(s);
}

/// نص بعد إصلاح الترميز — الفارغ يصبح `null` لا سلسلة فارغة
/// A text with its encoding repaired; blank becomes `null`, never an empty string.
String? tailoringText(Map<String, dynamic> json, String key) {
  final v = tailoringField(json, key);
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  final fixed = ArabicEncodingUtils.fix(s).trim();
  return fixed.isEmpty ? null : fixed;
}

/// نص غير عربي (أرقام هواتف، أكواد، أسماء أعلام لاتينية) بلا تصحيح ترميز
/// A non-Arabic text (phone numbers, codes) with no encoding repair.
String? tailoringPlainText(Map<String, dynamic> json, String key) {
  final v = tailoringField(json, key);
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// تاريخ من نص ISO قد يحمل وقتاً أو لاحقة `Z`
/// A date from an ISO string that may carry a time or a `Z` suffix.
DateTime? tailoringDate(Map<String, dynamic> json, String key) {
  final s = tailoringPlainText(json, key);
  if (s == null) return null;
  return DateTime.tryParse(s);
}

/// تاريخ للعرض بصيغة يوم/شهر/سنة — من نص جاهز أو من تاريخ خام
/// A display date (DD/MM/YYYY) from a prepared string or from a raw date.
String? tailoringDisplayDate(
  Map<String, dynamic> json,
  String key, {
  String? rawKey,
}) {
  final prepared = tailoringPlainText(json, key);
  if (prepared != null) return prepared;
  if (rawKey == null) return null;
  final raw = tailoringDate(json, rawKey);
  if (raw == null) return null;
  return '${raw.day.toString().padLeft(2, '0')}/'
      '${raw.month.toString().padLeft(2, '0')}/${raw.year}';
}

/// تنسيق رقم للعرض: بلا كسور زائدة، وبفاصلة الآلاف عند الحاجة
/// Format a number for display: no trailing decimals, thousands separators as needed.
String tailoringNumber(double? value, {int decimals = 0}) {
  if (value == null) return '';
  final isWhole = value == value.truncateToDouble();
  final fixed = value.abs().toStringAsFixed(isWhole ? 0 : decimals);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  final joined = parts.length > 1 ? '$buffer.${parts[1]}' : buffer.toString();
  return value < 0 ? '-$joined' : joined;
}

/// ضمّ نصين غير فارغين بفاصل — يُسقط الفراغ بدل ترك شرطة معلّقة
/// Join two non-empty texts with a separator, dropping blanks instead of hanging separators.
String tailoringJoin(List<String?> parts, {String separator = ' · '}) {
  final kept = parts.whereType<String>().where((p) => p.trim().isNotEmpty);
  return kept.join(separator);
}
