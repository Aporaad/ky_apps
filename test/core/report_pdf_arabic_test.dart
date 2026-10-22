import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_pdf_arabic.dart';

void main() {
  group('pdfArabic — Arabic shaping for PDF (fix "ي" collision)', () {
    test('shapes pure-Arabic complaint words into presentation forms', () {
      // كل كلمة عربية يجب أن تتحول إلى أشكال اتصالّية (U+FED0..FEFF / FE70..FEAF)
      for (final word in ['قطري', 'حجازي', 'الشميري', 'الكبودي للخياطة الرجالية']) {
        final shaped = pdfArabic(word);
        expect(shaped, isNotEmpty);
        // وجود محرف في نطاق Arabic Presentation Forms يدل على نجاح التشكيل
        final hasPresentationForm =
            shaped.runes.any((r) => r >= 0xFE70 && r <= 0xFEFF);
        expect(hasPresentationForm, isTrue,
            reason: '«$word» لم يُشكَّل إلى صور اتصالّية: $shaped');
      }
    });

    test('leaves non-Arabic strings untouched (numbers, English, codes)', () {
      for (final s in ['', '123', '1,234.50', 'ABC', 'CUT-01', '780154000']) {
        expect(pdfArabic(s), s, reason: 'يجب ألّا يتغيّر النص غير العربي: $s');
      }
    });

    test('reverses word order so RTL prints right-first (fixes reversal bug)',
        () {
      // «كشف مجموعة عمل القصاصين» — convert يوصل الحروف لكنه يُبقي ترتيب الكلمات
      // منطقياً، لذا نعكس ترتيب الكلمات ليصبح أول كلمات الناتج هو آخر كلمات المدخل.
      // convert joins letters but keeps logical word order; pdfArabic reverses the
      // words so the LAST logical word becomes the FIRST output token (visual RTL).
      const phrase = 'كشف مجموعة عمل القصاصين';
      final tokens = pdfArabic(phrase).split(' ');
      // عدد الكلمات محفوظ (لا دمج ولا فقدان)
      // Word count is preserved (no merging or loss).
      expect(tokens.length, phrase.split(' ').length);
      // أول رمز في الناتج = تشكيل آخر كلمة منطقية (القصاصين)، وآخرها = كشف
      // First output token = shaping of the last logical word; last = first word.
      expect(tokens.first, pdfArabic('القصاصين'));
      expect(tokens.last, pdfArabic('كشف'));
    });
  });
}
