/// حدود السنوات المقبولة لكشوف الحسابات — تحمي من التواريخ المشوهة القادمة
/// من الخادم (مثل "2025202520252025-MarMar-SatSat" الناتجة عن خطأ PHP
/// `format('YYYY-MM-DD')` والتي كانت تُطبَّع كـ DateTime(93422) وتكسر
/// منتقي التاريخ على العميل).
///
/// Accepted year bounds for statement dates — guards against malformed server
/// dates (the PHP `format('YYYY-MM-DD')` bug produced strings that normalized
/// into absurd years like 93422 and crashed showDatePicker).
DateTime _minValidDate = DateTime(1900);
DateTime _maxValidDate = DateTime(2100, 12, 31);

/// يحلّل نص تاريخ قادم من الخادم: يقبل YYYY-MM-DD و DD/MM/YYYY و DD-MM-YYYY.
/// يُرجع null لأي قيمة مشوهة أو خارج نطاق 1900–2100 حتى لا يتسرّب تاريخ
/// عبثي إلى حالة الشاشة أو إلى `showDatePicker` (الذي ينهار إذا خرج
/// initialDate عن firstDate/lastDate).
///
/// Parses a server date string: accepts YYYY-MM-DD, DD/MM/YYYY and DD-MM-YYYY.
/// Returns null for malformed or out-of-range values so an absurd date can
/// never leak into screen state or into `showDatePicker` (which asserts
/// initialDate ∈ [firstDate, lastDate]).
DateTime? parseStatementServerDate(String raw) {
  if (raw.trim().isEmpty) return null;

  final normalized = raw.trim().replaceAll('/', '-');
  final parts = normalized.split('-');
  if (parts.length != 3) return null;

  final DateTime parsed;
  if (parts[0].length == 4) {
    // YYYY-MM-DD (النافذة الافتراضية التي يعيدها الخادم بصيغة ISO)
    parsed = DateTime(
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  } else {
    // DD-MM-YYYY / DD/MM/YYYY (الصيغة التي يستخدمها التقرير المطبوع)
    parsed = DateTime(
      int.tryParse(parts[2]) ?? 0,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[0]) ?? 1,
    );
  }

  // نرفض أي تاريخ خارج النطاق المنطقي (سنة 93422، أو 0025 من صفوف Oracle
  // فاسدة) — الأفضل تجاهل التاريخ كلياً من إفساد حالة الفلاتر.
  // Reject out-of-range dates (year 93422 from garbage, year 0025 from
  // corrupt Oracle rows) — ignoring the date beats corrupting filter state.
  if (parsed.isBefore(_minValidDate) || parsed.isAfter(_maxValidDate)) {
    return null;
  }
  return parsed;
}

/// نقصّ التاريخ المبدئي داخل النطاق القانوني لمنتقي التواريخ — Material
/// يفترض أن initialDate يقع بين firstDate و lastDate وإلا انهار الـ picker
/// (assertion في date_picker.dart).
///
/// Clamps the initial date into the picker's legal range — Material asserts
/// initialDate ∈ [firstDate, lastDate] or showDatePicker throws.
DateTime clampToDatePickerRange(
  DateTime candidate, {
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(2020);
  final last = lastDate ?? DateTime(2030);
  if (candidate.isBefore(first)) return first;
  if (candidate.isAfter(last)) return last;
  return candidate;
}
