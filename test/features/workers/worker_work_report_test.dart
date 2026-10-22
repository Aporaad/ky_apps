import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/workers/data/models/worker_work_report_model.dart';

void main() {
  group('WorkerWorkRow.fromJson', () {
    test('parses lowercase keys with numbers arriving as strings', () {
      // أوراكل تُرجع الأرقام كنصوص — يجب أن يتعامل الموديل معها دفاعياً.
      final row = WorkerWorkRow.fromJson({
        'date': '03/07/2026',
        'style_name': 'ÞØÑí', // bytes CP1256 => "قطري"
        'count': '10',
        'unit_price': '400',
        'total': '4000',
      });

      expect(row.date, '03/07/2026');
      expect(row.styleName, 'قطري');
      expect(row.count, 10.0);
      expect(row.unitPrice, 400.0);
      expect(row.total, 4000.0);
    });

    test('parses uppercase Oracle keys and real numeric types', () {
      final row = WorkerWorkRow.fromJson({
        'WORK_DATE': '04/07/2026',
        'STYLE_NAME': 'ÍÌÇÒí', // => "حجازي"
        'QTY': 5,
        'UNIT_PRICE': 700.0,
        'TOTAL': 3500.0,
      });

      expect(row.date, '04/07/2026');
      expect(row.styleName, 'حجازي');
      expect(row.count, 5.0);
      expect(row.unitPrice, 700.0);
      expect(row.total, 3500.0);
    });

    test('missing numeric fields default to 0.0', () {
      final row = WorkerWorkRow.fromJson({'date': '05/07/2026'});
      expect(row.count, 0.0);
      expect(row.unitPrice, 0.0);
      expect(row.total, 0.0);
    });
  });

  group('WorkerWorkReport.fromJson', () {
    test('builds the full envelope (worker + data + summary)', () {
      final report = WorkerWorkReport.fromJson({
        'success': true,
        'worker': {'id': 6, 'name': 'ÎÇÏÍ', 'acc_no': 12910001}, // => "خادح"
        'data': [
          {
            'date': '03/07/2026',
            'style_name': 'ÞØÑí',
            'count': 10,
            'unit_price': 400,
            'total': 4000,
          },
          {
            'date': '03/07/2026',
            'style_name': 'ÞØÑí ÌÇåÒ', // => "قطري جاهز"
            'count': 2,
            'unit_price': 250,
            'total': 500,
          },
        ],
        'summary': {
          'total_count': 12,
          'total_amount': 4500,
          'from_date': '03/07/2026',
          'to_date': '03/07/2026',
          'currency': 'ÑíÇá íãäí YR',
        },
      });

      expect(report.workerName, 'خادح');
      expect(report.accNo, '12910001');
      expect(report.rows.length, 2);
      expect(report.rows.first.styleName, 'قطري');
      expect(report.rows.last.styleName, 'قطري جاهز');
      expect(report.totalCount, 12.0);
      expect(report.totalAmount, 4500.0);
      expect(report.fromDate, '03/07/2026');
      expect(report.toDate, '03/07/2026');
    });

    test('empty data yields zero rows', () {
      final report = WorkerWorkReport.fromJson({
        'worker': {'name': 'ØÇÍÏ', 'acc_no': 1},
        'data': <Object>[],
        'summary': {'total_count': 0, 'total_amount': 0},
      });

      expect(report.rows, isEmpty);
      expect(report.totalCount, 0.0);
      expect(report.totalAmount, 0.0);
    });
  });
}
