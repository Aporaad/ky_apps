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

    test('sends the stores as one comma list and omits an empty scope', () {
      expect(
        StoreReportFilter(
          from: from,
          to: to,
          storeNos: const [1, 3],
        ).toQuery()['store_nos'],
        '1,3',
      );

      // القائمة الفارغة تعني «كل المخازن» لا «لا مخازن» — و«لاشي» في الواجهة تعني هذا بالضبط
      // An empty list means "all stores", never "no stores" — which is exactly what the UI's
      // "None" choice means.
      expect(
        StoreReportFilter(from: from, to: to).toQuery().containsKey('store_nos'),
        isFalse,
      );
    });

    test('sends groups and sub groups as lists, never as a single pick', () {
      final query = StoreReportFilter(
        from: from,
        to: to,
        groupNos: const [2, 5],
        itemTypeNos: const [101, 102, 103],
      ).toQuery();

      expect(query['group_nos'], '2,5');
      expect(query['item_type_nos'], '101,102,103');

      // الوسيط المفرد لم يعد يُرسل: الخادم يظل يقبله للجهد القديم، لكن العميل لا يخلط المصدرين
      // The singular params are gone from the client: the server still accepts them for old
      // callers, but one client must not send two spellings of the same filter.
      expect(query.containsKey('group_no'), isFalse);
      expect(query.containsKey('type_no'), isFalse);
    });

    test('carries every dimension the sheet offers', () {
      final query = StoreReportFilter(
        from: from,
        to: to,
        groupNos: const [1],
        itemTypeNos: const [101],
        catNo: 4,
        sanfNo: 656,
        sanfDno: 2010602208,
      ).toQuery();

      expect(query['group_nos'], '1');
      expect(query['item_type_nos'], '101');
      expect(query['cat_no'], 4);
      expect(query['sanf_no'], 656);
      expect(query['sanf_dno'], 2010602208);
    });

    test('names the aggregation level only where a level means something', () {
      final summary = StoreReportFilter(
        kind: StoreReportKind.summary,
        from: from,
        to: to,
        groupBy: StoreReportGroupBy.group,
      );

      expect(summary.toQuery()['group_by'], 'group');
      expect(summary.usesGroupBy, isTrue);

      // «عرض حركة» لا يجمع أصلاً، فمستوى التجميع فيه ضجيج في الاستعلام
      // A movement view never aggregates, so a grouping level there is query noise.
      final movement = StoreReportFilter(from: from, to: to);

      expect(movement.toQuery().containsKey('group_by'), isFalse);
    });

    test('counts only the constraints that actually constrain', () {
      expect(StoreReportFilter(from: from, to: to).constraintCount, 0);

      expect(
        StoreReportFilter(
          from: from,
          to: to,
          storeNos: const [1, 2],
          groupNos: const [3],
          sanfNo: 656,
        ).constraintCount,
        3,
      );

      // أنواع الحركة لا تُحسب في الخلاصة: هي موجودة في النموذج لكنها لا تعمل فيه
      // Movement types are not counted for a summary: they exist on the model but do nothing.
      expect(
        StoreReportFilter(
          kind: StoreReportKind.summary,
          from: from,
          to: to,
          movementTypeNos: const [12],
        ).constraintCount,
        0,
      );
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

    test('can clear an item and its branch without touching the rest', () {
      final base = StoreReportFilter(
        from: from,
        to: to,
        groupNos: const [1],
        itemTypeNos: const [101],
        sanfNo: 656,
        sanfName: 'قماش',
        sanfDno: 201,
        sanfDnoLabel: 'أزرق',
      );

      final cleared = base.copyWith(clearSanf: true, clearSanfDno: true);

      expect(cleared.groupNos, [1]);
      expect(cleared.itemTypeNos, [101]);
      expect(cleared.sanfNo, isNull);

      // اسم الصنف يسبق صاحبه: بلاهما معاً تعرض الترويسة المطبوعة رقمًا يتيمًا
      // The item name goes with the item: leaving it behind would print an orphan in the header.
      expect(cleared.sanfName, isNull);
      expect(cleared.sanfDno, isNull);
      expect(cleared.sanfDnoLabel, isNull);
    });
  });
}
