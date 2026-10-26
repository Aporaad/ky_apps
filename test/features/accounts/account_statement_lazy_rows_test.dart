import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/widgets/lazy_report_table.dart';
import 'package:ky_apps/features/accounts/data/models/chart_account_model.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_statement_report_table.dart';

/// كشف بحجم حقيقي: آلاف الحركات — الحالة التي كانت تعرض 50 سطراً فقط، والتي كانت
/// تُفجّر الذاكرة لو بُنيت كلها داخل `Table` واحد.
/// A real-size statement: thousands of movements — the case that used to show only
/// 50 rows, and that would exhaust the heap if every row lived in one `Table`.
const int _rowCount = 3000;

/// نص وصف الحركة رقم `i` (يبدأ من 1) — يُستخدم للتأكد من ظهور الصف المطلوب وحده.
/// Description text of movement `i` (1-based) — asserts one specific row is live.
String _desc(int i) => 'حركة رقم $i';

List<AccountTransactionModel> _bulkTransactions(int count) {
  return List<AccountTransactionModel>.generate(
    count,
    (i) => AccountTransactionModel(
      entryNo: 4250000000 + i,
      subEntryNo: '${40000 + i}',
      date: '01/02/2025',
      entryTypeName: 'قيد يومية',
      description: _desc(i + 1),
      debit: i.isEven ? 1000 : 0,
      credit: i.isEven ? 0 : 1000,
      balance: 0,
    ),
  );
}

/// يُركّب الجدول داخل حاوية غير محدودة الارتفاع (كما في `ReportA4Sheet`) لاختبار
/// مسار الارتفاع الاحتياطي.
/// Mounts the table inside an unbounded-height parent (like `ReportA4Sheet`) so the
/// fallback-height path is the one under test.
Future<void> _pumpReport(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _statementTable() {
  return AccountStatementReportTable(
    transactions: _bulkTransactions(_rowCount),
    openingBalance: 0,
    finalBalance: 0,
    totalDebit: 1500000,
    totalCredit: 1500000,
  );
}

void main() {
  group('Account statement table — all rows, flat memory', () {
    testWidgets('builds 3000 movements lazily: very few live tables',
        (WidgetTester tester) async {
      await _pumpReport(tester, _statementTable());

      // الرأس + الرصيد الافتتاحي + شريحة لكل صف مبني + الإجمالي.
      // Header + opening + one slice per built row + totals.
      final tables = find.byType(Table).evaluate().length;
      expect(tables, lessThan(80),
          reason: 'building 3000 rows at once is what exhausted the heap; '
              'live tables now: $tables');

      // الرأس والافتتاحي والإجماليات ثابتة الظهور في كل الأحوال.
      // Header, opening and totals are always on screen.
      expect(find.text('السند'), findsOneWidget);
      expect(find.text('رصيد افتتاحي'), findsOneWidget);
      expect(find.text('اجمالي العمليات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('first movement is built, the last one is not built yet',
        (WidgetTester tester) async {
      await _pumpReport(tester, _statementTable());

      expect(find.text(_desc(1)), findsOneWidget);
      // آخر صف في الكشف خارج الشاشة: لم يُبنَ بعد.
      // The very last row is off-screen: not built yet.
      expect(find.text(_desc(_rowCount)), findsNothing);
    });

    testWidgets('scrolling to the end reveals the last movement — no truncation',
        (WidgetTester tester) async {
      await _pumpReport(tester, _statementTable());

      // التمرير داخل منطقة الصفوف وحدها (لا صفحة التقرير كلها).
      // Scroll the rows viewport only (not the whole report page).
      final rowsList = find
          .descendant(
            of: find.byType(AccountStatementReportTable),
            matching: find.byType(Scrollable),
          )
          .first;

      await tester.scrollUntilVisible(
        find.text(_desc(_rowCount)),
        2000,
        scrollable: rowsList,
        maxScrolls: 200,
      );
      await tester.pumpAndSettle();

      // الصف الأخير موجود فعلاً — لا سقف 50 ولا 15 صفاً في الصفحة.
      // The last row really is present — no 50-row cap and no 15-row pager.
      expect(find.text(_desc(_rowCount)), findsOneWidget);
      // والعناصر الحيّة ما زالت محدودة (افتراضية، لا بناء كامل).
      // Live cells are still bounded (virtualized, not fully built).
      expect(find.byType(Table).evaluate().length, lessThan(80));
    });

    testWidgets('LazyReportTable keeps header and footer pinned with 5000 rows',
        (WidgetTester tester) async {
      await _pumpReport(
        tester,
        LazyReportTable(
          headerRows: [
            TableRow(
              children: [
                for (var i = 0; i < 3; i++) tableHeaderCell('رأس $i'),
              ],
            ),
          ],
          footerRows: [
            TableRow(
              children: [
                for (var i = 0; i < 3; i++) tableDataCell('تذييل $i', isBold: true),
              ],
            ),
          ],
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          rowCount: 5000,
          rowBuilder: (index) => TableRow(
            children: [
              for (var i = 0; i < 3; i++) tableDataCell('صف $index خلية $i'),
            ],
          ),
        ),
      );

      expect(find.text('رأس 0'), findsOneWidget);
      expect(find.text('تذييل 2'), findsOneWidget);
      expect(find.text('صف 0 خلية 0'), findsOneWidget);
      expect(find.text('صف 4999 خلية 0'), findsNothing);
      expect(find.byType(Table).evaluate().length, lessThan(80));
      expect(tester.takeException(), isNull);
    });
  });
}
