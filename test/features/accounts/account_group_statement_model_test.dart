import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/accounts/data/models/account_group_statement_model.dart';

/// اختبارات ترقيم ميزان المراجعة: قراءة `meta` ودمج الصفحات تدريجياً.
/// Trial-balance pagination: reading `meta` and merging streamed pages.
///
/// الخطأ الذي تمنعه هذه الاختبارات: جمع إجماليات كل صفحة (فتتضاعف الأرقام)،
/// أو فقدان عدد صفوف النطاق بعد الصفحة الأولى (فلا يعرف أحد أنه ناقص).
/// These guard against two regressions: summing page totals (which multiplies
/// the figures) and losing the scope-wide count after page 1.
TrialBalanceRow _row(int accNo) => TrialBalanceRow(
      accNo: accNo,
      accName: 'حساب $accNo',
      curCode: 'YR',
      localDebit: 10,
      localCredit: 4,
      foreignDebit: 0,
      foreignCredit: 0,
      balance: 6,
      periodBalance: 2,
    );

Map<String, dynamic> _payload({
  required List<int> accNos,
  Map<String, dynamic>? meta,
}) =>
    {
      'success': true,
      'data': {
        'scope_level': 'group',
        'scope_label': 'مجموعة 1',
        'as_of_date': '26/10/2026',
        'has_period': false,
        'rows': [
          for (final no in accNos)
            {'acc_no': no, 'acc_name': 'حساب $no', 'cur_code': 'YR', 'balance': 6},
        ],
        'totals': {'local_debit': 100, 'balance': 60},
      },
      if (meta != null) 'meta': meta,
    };

void main() {
  group('TrialBalanceReport.fromJson — pagination meta', () {
    test('reads the scope-wide count and page bounds from meta', () {
      final report = TrialBalanceReport.fromJson(_payload(
        accNos: [101, 102],
        meta: {
          'total': 20774,
          'page': 3,
          'limit': 1000,
          'total_pages': 21,
          'has_more': true,
        },
      ));

      expect(report.rows.length, 2);
      expect(report.total, 20774);
      expect(report.page, 3);
      expect(report.limit, 1000);
      expect(report.totalPages, 21);
      expect(report.hasMore, isTrue);
      // جزء من نطاق أكبر بكثير
      expect(report.isPartial, isTrue);
      expect(report.loadRatio, closeTo(2 / 20774, 1e-9));
    });

    test('falls back to the response size when meta is absent', () {
      // خادم أقدم لا يرسل meta: لا يجوز أن يظهر الرقم صفراً ولا أن يُفهم
      // النطاق كاملاً خطأً.
      // An older server without meta must not read as "zero rows" or "complete".
      final report = TrialBalanceReport.fromJson(_payload(accNos: [1, 2, 3]));

      expect(report.total, 3);
      expect(report.hasMore, isFalse);
      expect(report.isPartial, isFalse);
      expect(report.loadRatio, 1.0);
    });

    test('treats has_more "1" (Oracle string) as true', () {
      final report = TrialBalanceReport.fromJson(_payload(
        accNos: [1],
        meta: {'total': 2, 'has_more': '1'},
      ));
      expect(report.hasMore, isTrue);
    });
  });

  group('TrialBalanceReport.appendPage', () {
    final firstPage = TrialBalanceReport(
      scopeLevel: 'group',
      scopeLabel: 'مجموعة 1',
      asOfDate: '26/10/2026',
      hasPeriod: true,
      rows: [_row(1), _row(2)],
      totals: const TrialBalanceTotals(
        localDebit: 500,
        localCredit: 200,
        balance: 300,
        periodBalance: 120,
      ),
      total: 5,
      page: 1,
      limit: 2,
      totalPages: 3,
      hasMore: true,
    );

    test('appends rows and keeps the first page totals', () {
      final secondPage = TrialBalanceReport(
        rows: [_row(3), _row(4)],
        totals: const TrialBalanceTotals(localDebit: 500, balance: 300),
        total: 5,
        page: 2,
        limit: 2,
        totalPages: 3,
        hasMore: true,
      );

      final merged = firstPage.appendPage(secondPage);

      expect(merged.rows.map((r) => r.accNo), [1, 2, 3, 4]);
      // الإجماليات محسوبة على النطاق كاملاً في الخادم — لا تُجمع مع بعضها
      // Totals cover the whole scope already; they must never be summed.
      expect(merged.totals.localDebit, 500);
      expect(merged.totals.balance, 300);
      expect(merged.totals.periodBalance, 120);
      expect(merged.total, 5);
      expect(merged.page, 2);
      expect(merged.totalPages, 3);
      expect(merged.hasMore, isTrue);
      // حقول النطاق تُحفظ من الصفحة الأولى
      expect(merged.scopeLabel, 'مجموعة 1');
      expect(merged.hasPeriod, isTrue);
    });

    test('keeps the known scope count when a page omits it', () {
      final lastPage = TrialBalanceReport(
        rows: [_row(5)],
        page: 3,
        limit: 2,
        totalPages: 3,
        hasMore: false,
      );

      final merged = firstPage.appendPage(lastPage);

      expect(merged.total, 5, reason: 'total=0 من الخادم يعني «لم يُعدّ»');
      expect(merged.rows.length, 3);
      expect(merged.hasMore, isFalse);
      expect(merged.isPartial, isTrue);
    });

    test('a complete merge is no longer partial', () {
      final rest = TrialBalanceReport(
        rows: [_row(3), _row(4), _row(5)],
        total: 5,
        page: 2,
        limit: 3,
        totalPages: 2,
        hasMore: false,
      );

      final merged = firstPage.appendPage(rest);

      expect(merged.rows.length, 5);
      expect(merged.total, 5);
      expect(merged.isPartial, isFalse);
      expect(merged.loadRatio, 1.0);
    });
  });
}
