import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';
import 'package:ky_apps/features/stores/presentation/providers/stock_sheet_providers.dart';

/// اختبارات كشف الجرد — الحساب في الذاكرة فقط
/// Stocktake sheet tests — the arithmetic lives in memory only.
///
/// ── القاعدة التي تحرسها هذه الاختبارات: الكشف **لا يحفظ** ولا **يرحّل**. كل ما يفعله أنه
///    يقارن رصيد النظام بكمية أدخلها المستخدم ويحسب الفرق وقيمته. أي إضافة كتابة هنا تعني
///    خرق قرار المستخدم (D9 + D13)، فيفشل الاختبار.
/// ── The rule these guard: the sheet never saves and never posts. It only compares the system
///    quantity with a user-typed count and derives the variance and its value. Any write added
///    here breaks the user's decision and must fail the test.
void main() {
  StockSheetRow row({
    double systemQty = 10,
    double cost = 1000,
    int sanfNo = 1,
    int storeNo = 1,
  }) {
    return StockSheetRow(
      sanfNo: sanfNo,
      storeNo: storeNo,
      itemName: 'صنف $sanfNo',
      systemQty: systemQty,
      cost: cost,
    );
  }

  group('StockSheetState variance', () {
    test('an untouched line counts as the system quantity', () {
      final first = row();
      final state = StockSheetState(rows: [first]);

      expect(state.isCounted(first), isFalse);
      expect(state.countedOf(first), 10);
      expect(state.varianceOf(first), 0);
      expect(state.varianceValue, 0);
    });

    test('a surplus is positive and a shortage is negative', () {
      final surplus = row(sanfNo: 1);
      final shortage = row(sanfNo: 2);

      final state = StockSheetState(
        rows: [surplus, shortage],
        counted: {
          surplus.key: 12,
          shortage.key: 7,
        },
      );

      expect(state.varianceOf(surplus), 2);
      expect(state.varianceValueOf(surplus), 2000);
      expect(state.varianceOf(shortage), -3);
      expect(state.varianceValueOf(shortage), -3000);

      // صافي قيمة الفرق = 2000 - 3000
      // Net variance value = 2000 - 3000.
      expect(state.varianceValue, -1000);
      expect(state.varianceLines, 2);
    });

    test('equal counts are not counted as a variance line', () {
      final first = row();
      final state = StockSheetState(
        rows: [first],
        counted: {first.key: 10},
      );

      expect(state.isCounted(first), isTrue);
      expect(state.varianceLines, 0);
    });

    test('the variance-only filter hides untouched and zero-variance lines', () {
      final matched = row(sanfNo: 1);
      final untouched = row(sanfNo: 2);
      final equal = row(sanfNo: 3);

      final state = StockSheetState(
        rows: [matched, untouched, equal],
        counted: {matched.key: 15, equal.key: 10},
        countFilter: StockCountFilter.variance,
      );

      expect(state.visibleRows, hasLength(1));
      expect(state.visibleRows.single.sanfNo, 1);
    });

    test('surplus and shortage split the variance instead of merging it', () {
      final up = row(sanfNo: 1);
      final down = row(sanfNo: 2);

      final base = StockSheetState(
        rows: [up, down],
        counted: {up.key: 15, down.key: 4},
      );

      expect(
        base.copyWith(countFilter: StockCountFilter.surplus).visibleRows,
        [up],
      );
      expect(
        base.copyWith(countFilter: StockCountFilter.shortage).visibleRows,
        [down],
      );
      // «بفرق فقط» يحتفظ بالاثنين معاً
      // "Any variance" keeps both together.
      expect(
        base.copyWith(countFilter: StockCountFilter.variance).visibleRows,
        hasLength(2),
      );
    });

    test('the uncounted filter shows exactly the lines nobody touched', () {
      final touched = row(sanfNo: 1);
      final untouched = row(sanfNo: 2);

      final state = StockSheetState(
        rows: [touched, untouched],
        counted: {touched.key: 15},
        countFilter: StockCountFilter.uncounted,
      );

      expect(state.visibleRows, [untouched]);
    });

    test('the all filter keeps every line', () {
      final state = StockSheetState(
        rows: [row(sanfNo: 1), row(sanfNo: 2)],
        counted: {row(sanfNo: 1).key: 15},
      );

      expect(state.visibleRows, hasLength(2));
    });

    test('a line note stays in the state and never becomes a count', () {
      final line = row(sanfNo: 1);
      final blank = row(sanfNo: 2);

      final state = StockSheetState(rows: [line, blank]);

      expect(state.hasNotes, isFalse);
      expect(state.noteOf(line), isEmpty);

      // الملاحظة لا تُعدّ سطراً ولا تحرّك الفرق
      // A note neither counts a line nor moves the variance.
      final noted = state.copyWith(notes: {line.key: 'الصندوق تالف'});

      expect(noted.hasNotes, isTrue);
      expect(noted.noteOf(line), 'الصندوق تالف');
      expect(noted.isCounted(line), isFalse);
      expect(noted.varianceLines, 0);
      expect(noted.varianceValue, 0);
    });

    test('the same item in two stores keeps two independent lines', () {
      final storeOne = row(sanfNo: 1, storeNo: 1);
      final storeThree = row(sanfNo: 1, storeNo: 3);

      expect(storeOne.key, isNot(storeThree.key));

      final state = StockSheetState(
        rows: [storeOne, storeThree],
        counted: {storeOne.key: 4},
      );

      expect(state.varianceOf(storeOne), -6);
      expect(state.varianceOf(storeThree), 0);
    });
  });
}
