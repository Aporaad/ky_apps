import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// فحص داخلي: نتأكّد أن الخط المضمّن يغطي صور العربية الاتصالّية التي يُنتجها pdfArabic
import 'package:pdf/src/pdf/font/ttf_parser.dart';
import 'package:pdf/src/widgets/font.dart' show TtfFont;
import 'package:ky_apps/core/utils/report_pdf_arabic.dart';
import 'package:ky_apps/core/utils/report_pdf_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportPdfFonts — bundled Cairo (offline, no network)', () {
    test('loads Cairo from local assets and it covers all shaped Arabic',
        () async {
      // الأصل مضمّن: يجب أن يُقرأ من الحزمة بدون أي تنزيل شبكي.
      final data = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final font = TtfFont(data);
      final parser = TtfParser(font.data);
      final map = parser.charToGlyphIndexMap;

      // كلمات حقيقية تمر عبر مسار pdfArabic الإنتاجي في كل الكشوفات.
      for (final phrase in [
        'كشف حساب عميل',
        'كشف حساب مالي',
        'رصيد افتتاحي',
        'اجمالي العمليات',
        'يمني YR',
        'توقيع المحاسب',
      ]) {
        final shaped = pdfArabic(phrase);
        final missing = shaped.runes.where((r) => !map.containsKey(r)).toList();
        expect(missing, isEmpty,
            reason: '«$phrase» فيه رموز غير مغطّاة في خط Cairo: $missing');
      }
    });

    test('theme() resolves offline and loads the bundled Cairo font', () async {
      final theme = await ReportPdfFonts.theme();
      expect(theme, isNotNull);
      // الخط المُحمَّل من الأصل المحلّي يجب أن يكون Cairo وليس Helvetica الافتراضي.
      final font = await ReportPdfFonts.regular;
      expect(font.fontName, contains('Cairo'));
    });
  });
}
