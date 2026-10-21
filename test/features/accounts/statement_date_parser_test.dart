import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/accounts/presentation/utils/statement_date_parser.dart';

void main() {
  group('parseStatementServerDate — regression: PHP format bug', () {
    // الخادم كان يرسل format('YYYY-MM-DD') بدل format('Y-m-d') — في PHP كل Y
    // تُكرّر السنة، وM اسم الشهر وD اسم اليوم، فينتج "2025202520252025-MarMar-SatSat".
    // العميل القديم كان يحلّلها إلى DateTime(93422) وينهار منتقي التاريخ.
    // The server sent format('YYYY-MM-DD') garbage; the old client parsed it
    // into DateTime(93422) and crashed showDatePicker's initialDate assertion.
    test('rejects the PHP repeated-format-letter garbage string', () {
      expect(
        parseStatementServerDate('2025202520252025-MarMar-SatSat'),
        isNull,
      );
      expect(
        parseStatementServerDate('2025202520252025-AprApr-TueTue'),
        isNull,
      );
    });

    test('rejects a directly absurd year like 93422', () {
      expect(parseStatementServerDate('93422-12-11'), isNull);
      expect(parseStatementServerDate('11/12/93422'), isNull);
    });

    test('rejects corrupt Oracle year 0025 rows', () {
      // ENTRY_MAIN يحتوي صفوفاً بتواريخ فاسدة (سنة 0025) — يجب تجاهلها
      // بدل تعبئتها في فلترة الشاشة وإنهاء منتقي التاريخ من جهة firstDate.
      // ENTRY_MAIN contains corrupt rows (year 0025) — ignore them instead of
      // letting them crash the picker from the firstDate side.
      expect(parseStatementServerDate('0025-06-18'), isNull);
      expect(parseStatementServerDate('18/06/0025'), isNull);
    });

    test('rejects malformed input shapes', () {
      expect(parseStatementServerDate(''), isNull);
      expect(parseStatementServerDate('not-a-date'), isNull);
      expect(parseStatementServerDate('2025-04'), isNull);
      expect(parseStatementServerDate('16-03-2025-01'), isNull);
    });

    test('parses valid ISO dates (YYYY-MM-DD)', () {
      final d = parseStatementServerDate('2025-03-16');
      expect(d, isNotNull);
      expect(d!.year, 2025);
      expect(d.month, 3);
      expect(d.day, 16);
    });

    test('parses valid printed-report dates (DD/MM/YYYY)', () {
      final d = parseStatementServerDate('16/03/2025');
      expect(d, isNotNull);
      expect(d!.year, 2025);
      expect(d.month, 3);
      expect(d.day, 16);
    });

    test('parses dash-variant DD-MM-YYYY', () {
      final d = parseStatementServerDate('15-04-2025');
      expect(d, isNotNull);
      expect(d!.year, 2025);
      expect(d.day, 15);
    });
  });

  group('clampToDatePickerRange — picker assertion guard', () {
    test('clamps a year-93422 date down to lastDate', () {
      final garbage = DateTime(93422, 12, 11);
      final clamped = clampToDatePickerRange(
        garbage,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      expect(clamped, DateTime(2030));
    });

    test('clamps a pre-2020 date up to firstDate', () {
      final corrupt = DateTime(25, 6, 18); // صف Oracle فاسد / corrupt row
      final clamped = clampToDatePickerRange(
        corrupt,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      expect(clamped, DateTime(2020));
    });

    test('leaves an in-range date untouched', () {
      final normal = DateTime(2025, 4, 15);
      final clamped = clampToDatePickerRange(
        normal,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      expect(clamped, normal);
    });

    test('uses the default 2020–2030 range when omitted', () {
      expect(
        clampToDatePickerRange(DateTime(1999)),
        DateTime(2020),
      );
      expect(
        clampToDatePickerRange(DateTime(2050)),
        DateTime(2030),
      );
    });
  });
}
