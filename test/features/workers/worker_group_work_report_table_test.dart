import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/workers/data/models/worker_group_work_report_model.dart';
import 'package:ky_apps/features/workers/presentation/widgets/worker_group_work_report_table.dart';

// ================================================================
// اختبارات العرض لجدول "كشف عمل المجموعة" — التحقق من الدمج الرأسي
// Rendering tests for the group work-report table: the worker name must
// appear once and stretch over all of that worker's style rows.
// ================================================================

void main() {
  Future<void> _pump(WidgetTester tester, List<WorkerGroupWorkRow> rows) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 800,
              child: WorkerGroupWorkReportTable(
                rows: rows,
                totalCount: rows.fold<double>(0, (s, r) => s + r.count),
                totalAmount: rows.fold<double>(0, (s, r) => s + r.total),
                workerCount: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders merged table without layout exceptions', (tester) async {
    await _pump(tester, const [
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'قطري', count: 10, unitPrice: 400, total: 4000),
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'حجازي', count: 5, unitPrice: 700, total: 3500),
      WorkerGroupWorkRow(workerName: 'خالد', styleName: 'قطري', count: 3, unitPrice: 400, total: 1200),
    ]);

    expect(tester.takeException(), isNull);
    // الأعمدة والرأس
    expect(find.text('الاسم'), findsOneWidget);
    expect(find.text('الموديل'), findsOneWidget);
    expect(find.text('الإجمالي'), findsOneWidget);
  });

  testWidgets('worker name appears once even with multiple styles', (tester) async {
    await _pump(tester, const [
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'قطري', count: 10, unitPrice: 400, total: 4000),
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'حجازي', count: 5, unitPrice: 700, total: 3500),
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'قطري جاهز', count: 2, unitPrice: 250, total: 500),
    ]);

    expect(tester.takeException(), isNull);
    // اسم "علي" يظهر مرة واحدة فقط رغم ثلاثة موديلات (الدمج الرأسي)
    expect(find.text('علي'), findsOneWidget);
    // لكن كل موديل يبقى في سطر مستقل
    expect(find.text('قطري'), findsOneWidget);
    expect(find.text('حجازي'), findsOneWidget);
    expect(find.text('قطري جاهز'), findsOneWidget);
  });

  testWidgets('shows the two totals rows', (tester) async {
    // ثلاثة أسطر لعاملين: العدد الكلي 18، والمبلغ الكلي 8,700 (لا يظهران إلا في سطري الإجمالي)
    await _pump(tester, const [
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'قطري', count: 10, unitPrice: 400, total: 4000),
      WorkerGroupWorkRow(workerName: 'علي', styleName: 'حجازي', count: 5, unitPrice: 700, total: 3500),
      WorkerGroupWorkRow(workerName: 'خالد', styleName: 'قطري', count: 3, unitPrice: 400, total: 1200),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('18'), findsOneWidget); // إجمالي العدد
    expect(find.text('8,700'), findsOneWidget); // إجمالي المبلغ
  });
}
