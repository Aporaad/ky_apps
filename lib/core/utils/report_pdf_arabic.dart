import 'package:pdf/widgets.dart' as pw;
// nolint: implementation_imports — نستخدم مُشكِّل العربية الداخلي نفسه الذي
// يعتمد عليه مولّد PDF، لضمان تطابق التشكيل مع ما يرسمه المحرك فعلياً.
// We reuse the exact Arabic shaper the pdf engine itself relies on, so the shaping
// matches what the renderer draws. Single localized implementation import (pinned pdf).
import 'package:pdf/src/pdf/font/arabic.dart' as arabic_shaper; // ignore: implementation_imports

/// يُشكِّل النص العربي إلى أشكاله الاتصالّية (presentation forms) وبترتيب العرض
/// الصحيح (يميناً→يساراً) قبل تمريره إلى `pdf`.
///
/// السبب: حزمة `pdf` افتراضياً (`use_bidi=true, use_arabic=false`) تمرّر النص العربي
/// عبر `bidi.logicalToVisual` وهو يعيد ترتيب الكلمات دون وصل الحروف، فيظهر حرف
/// الياء/الألف المقصورة متضارباً في كلمات مثل «قطري»، «حجازي»، «الشميري».
///
/// دالة `arabic_shaper.convert` توصل الحروف داخل كل كلمة لكنها تُبقي ترتيب الكلمات
/// منطقياً (أول كلمة يساراً)، فينقلب الشكل عند العرض. لذلك نعكس ترتيب الكلمات بعد
/// التشكيل ليصبح الترتيب مرئياً صحيحاً، ثم يُعرض باتجاه `ltr` حتى لا يعيد محرك `pdf`
/// ترتيبه مرة أخرى (المسار rtl يطبّق Bidi تلقائياً فيضاعف العكس). النصوص غير العربية
/// (أرقام/إنجليزي/أكواد) تبقى كما هي.
///
/// Shapes Arabic into joined presentation forms AND fixes word order. `convert` joins
/// the letters within each word but keeps words in logical order (first word rendered
/// leftmost), which appears reversed. We therefore reverse the word sequence so the
/// string is in true visual order, then callers render it with `ltr` so the engine does
/// not run `logicalToVisual` again (double reversal). Non-Arabic strings are untouched.
String pdfArabic(String text) {
  if (text.isEmpty || !_hasArabic(text)) {
    return text;
  }
  final shaped = arabic_shaper.convert(text);
  // عكس ترتيب الكلمات لتحويل الناتج من ترتيب منطقي إلى ترتيب مرئي صحيح (RTL).
  // Reverse the word sequence to turn convert's logical word order into visual order.
  return shaped.split(' ').reversed.join(' ');
}

/// هل يحتوي النص على محرف عربي واحد على الأقل (U+0600..U+06FF)؟
/// Whether the string contains at least one Arabic character (Arabic block).
bool _hasArabic(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) {
      return true;
    }
  }
  return false;
}

/// اتجاه عرض موحّد لكل نصوص PDF المشكَّلة: ltr حتى لا يعيد المحرك ترتيب النص المُشكَّل
/// مسبقاً. المُحاذاة تُضبط عبر `textAlign` فقط.
/// Unified render direction for pre-shaped PDF text: ltr so the engine never re-orders an
/// already-shaped string. Positioning is controlled solely through `textAlign`.
const pw.TextDirection kPdfShapedTextDirection = pw.TextDirection.ltr;
