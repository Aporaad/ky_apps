import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';

/// اختبارات معطيات تقرير المخازن — نافذة التحديد قبل أي استعلام
/// Store report parameter tests — the filter sheet in front of any query.
///
/// ── القاعدة التي يحرسها هذا الملف: «نوع الحركة» يخصّ «عرض حركة» وحده. الخلاصة تجمع كل
///    أنواع الحركة بطبيعتها، فتمرير الفلتر فيها يعيد وارداً/صادراً ناقصاً يخالف الرصيد الذي
///    تعرضه بقية الشاشات.
/// ── The rule this file guards: the movement-type filter belongs to the movement view only.
///    A summary aggregates every type by definition, so passing the filter there yields a
///    partial in/out that contradicts the balance every other screen shows.
void main() {
  final from = DateTime(2026, 10, 1);
  final to = DateTime(2026, 10, 31);

  group('movement type filter', () {
    test('is meaningful only for a movement view', () {
      final movement = StoreReportFilter(
        kind: StoreReportKind.movement,
        from: from,
        to: to,
      );

      final summary = StoreReportFilter(
        kind: StoreReportKind.summary,
        from: from,
        to: to,
      );

      expect(movement.usesMovementTypes, isTrue);
      expect(summary.usesMovementTypes, isFalse);
    });

    test('is sent as a comma list for a movement view', () {
      final filter = StoreReportFilter(
        from: from,
        to: to,
        movementTypeNos: const [12, 13, 5],
      );

      expect(filter.toQuery()['type_nos'], '12,13,5');
    });

    test('is dropped for a summary even when the user left types selected', () {
      final filter = StoreReportFilter(
        kind: StoreReportKind.summary,
        from: from,
        to: to,
        movementTypeNos: const [12, 13],
      );

      expect(filter.toQuery().containsKey('type_nos'), isFalse);
    });
  });

  group('period and scope', () {
    test('is valid only when the start is not after the end', () {
      expect(StoreReportFilter(from: from, to: to).isValid, isTrue);
      expect(StoreReportFilter(from: from, to: from).isValid, isTrue);
      expect(StoreReportFilter(from: to, to: from).isValid, isFalse);
    });

    test('serialises the period as YYYY-MM-DD', () {
      final query = StoreReportFilter(from: from, to: to).toQuery();

      expect(query['from'], '2026-10-01');
      expect(query['to'], '2026-10-31');
    });

    test('sends the stores as one comma-separated value and omits an empty scope', () {
      expect(
        StoreReportFilter(from: from, to: to, storeNos: const [1, 3]).toQuery()['store_no'],
        '1,3',
      );

      // القائمة الفارغة تعني «كل المخازن» لا «لا مخازن»
      // An empty list means "all stores", never "no stores".
      expect(
        StoreReportFilter(from: from, to: to).toQuery().containsKey('store_no'),
        isFalse,
      );
    });

    test('carries every dimension the sheet offers', () {
      final query = StoreReportFilter(
        from: from,
        to: to,
        groupNo: 1,
        typeNo: 101,
        catNo: 4,
        sanfNo: 656,
        sanfDno: 2010602208,
      ).toQuery();

      expect(query['group_no'], 1);
      expect(query['type_no'], 101);
      expect(query['cat_no'], 4);
      expect(query['sanf_no'], 656);
      expect(query['sanf_dno'], 2010602208);
    });
  });

  group('copyWith', () {
    test('keeps the existing values when only the kind changes', () {
      final base = StoreReportFilter(
        from: from,
        to: to,
        storeNos: const [1],
        movementTypeNos: const [12],
      );

      final switched = base.copyWith(kind: StoreReportKind.summary);

      expect(switched.kind, StoreReportKind.summary);
      expect(switched.storeNos, [1]);
      expect(switched.from, from);
    });

    test('can clear a single dimension without touching the rest', () {
      final base = StoreReportFilter(
        from: from,
        to: to,
        groupNo: 1,
        typeNo: 101,
        sanfNo: 656,
      );

      final cleared = base.copyWith(clearType: true, clearSanf: true);

      expect(cleared.groupNo, 1);
      expect(cleared.typeNo, isNull);
      expect(cleared.sanfNo, isNull);
    });
  });
}
