import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/workers/data/models/worker_group_work_report_model.dart';

// ================================================================
// اختبارات موديل كشف عمل المجموعة (FOR_CUTTER_CALC)
// Group work-report model tests — mirrors the individual work report suite.
// ================================================================

void main() {
  group('WorkerGroupWorkRow.fromJson', () {
    test('parses lowercase keys and repairs mojibake in worker name + style', () {
      // الأرقام قد تصل كنصوص من أوراكل — المعالجة الدفاعية إلزامية.
      // الاسم والموديل نص عربي بايتات CP1256 — يجب تمريرهما على ArabicEncodingUtils.fix.
      // السطر مُجمّع لكل (عامل + موديل) بلا تاريخ لكل سجل.
      final row = WorkerGroupWorkRow.fromJson({
        'worker_name': 'ÇÕíá ãÌíÈ ÇáÔãíÑí', // => "اصيل مجيب الشميري"
        'style_name': 'ÞØÑí', // => "قطري"
        'count': '6',
        'unit_price': '350',
        'total': '2100',
      });

      expect(row.workerName, 'اصيل مجيب الشميري');
      expect(row.styleName, 'قطري');
      expect(row.count, 6.0);
      expect(row.unitPrice, 350.0);
      expect(row.total, 2100.0);
    });

    test('parses uppercase Oracle keys and real numeric types', () {
      final row = WorkerGroupWorkRow.fromJson({
        'WORKER_NAME': 'ÍÌÇÒí', // => "حجازي"
        'STYLE_NAME': 'ÍÌÇÒí', // => "حجازي"
        'QTY': 7,
        'UNIT_PRICE': 700.0,
        'TOTAL': 4900.0,
      });

      expect(row.workerName, 'حجازي');
      expect(row.styleName, 'حجازي');
      expect(row.count, 7.0);
      expect(row.unitPrice, 700.0);
      expect(row.total, 4900.0);
    });

    test('missing numeric fields default to 0.0', () {
      final row = WorkerGroupWorkRow.fromJson({});
      expect(row.workerName, '');
      expect(row.styleName, '');
      expect(row.count, 0.0);
      expect(row.unitPrice, 0.0);
      expect(row.total, 0.0);
    });
  });

  group('WorkerGroupWorkReport.fromJson', () {
    test('builds the full envelope (group + data + summary)', () {
      final report = WorkerGroupWorkReport.fromJson({
        'success': true,
        'group': 'cutters',
        'data': [
          {
            'worker_name': 'ãÌíÈ ÇáÔãíÑí - ÞÕÇÕ', // => "مجيب الشميري - قصاص"
            'style_name': 'ÞØÑí', // => "قطري"
            'count': 19,
            'unit_price': 400,
            'total': 7600,
          },
          {
            'worker_name': 'ãÌíÈ ÇáÔãíÑí - ÞÕÇÕ',
            'style_name': 'ÞØÑí ÌÇåÒ', // => "قطري جاهز"
            'count': 5,
            'unit_price': 250,
            'total': 1250,
          },
        ],
        'summary': {
          'total_count': 24,
          'total_amount': 8850,
          'from_date': '22/06/2026',
          'to_date': '25/06/2026',
          'worker_count': 4,
        },
      });

      expect(report.group, 'cutters');
      expect(report.fromDate, '22/06/2026');
      expect(report.toDate, '25/06/2026');
      expect(report.workerCount, 4);
      expect(report.totalCount, 24.0);
      expect(report.totalAmount, 8850.0);
      expect(report.rows.length, 2);
      expect(report.rows.first.workerName, 'مجيب الشميري - قصاص');
      expect(report.rows.first.styleName, 'قطري');
      expect(report.rows.last.styleName, 'قطري جاهز');
    });

    test('empty data yields zero rows and zero totals', () {
      final report = WorkerGroupWorkReport.fromJson({
        'group': 'tailors',
        'data': <Object>[],
        'summary': {
          'total_count': 0,
          'total_amount': 0,
          'worker_count': 0,
        },
      });

      expect(report.group, 'tailors');
      expect(report.rows, isEmpty);
      expect(report.totalCount, 0.0);
      expect(report.totalAmount, 0.0);
      expect(report.workerCount, 0);
    });

    test('missing summary defaults to zeros, not null', () {
      // الاستجابة قد تصل بلا summary (شبكة مقطوعة جزئياً) — الموديل لا يجب أن يفشل.
      final report = WorkerGroupWorkReport.fromJson({
        'group': 'cutters',
        'data': [
          {'worker_name': 'ØÇÍÏ', 'count': 1, 'total': 350},
        ],
      });

      expect(report.rows.length, 1);
      expect(report.totalCount, 0.0);
      expect(report.totalAmount, 0.0);
      expect(report.workerCount, 0);
      expect(report.fromDate, '');
      expect(report.toDate, '');
    });
  });
}
