import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/accounts/data/models/account_group_statement_model.dart';
import 'package:ky_apps/features/accounts/data/models/chart_account_model.dart';

void main() {
  group('AccountTransactionModel.fromJson', () {
    test('reads lowercase keys as-is', () {
      final tx = AccountTransactionModel.fromJson({
        'entry_no': 1234567,
        'sub_entry_no': '11234',
        'date': '01/02/2024',
        'entry_type_name': 'قيد يومية',
        'description': 'بيان الحركة',
        'debit': 100.0,
        'credit': 0.0,
        'balance': 100.0,
      });

      expect(tx.entryNo, 1234567);
      expect(tx.subEntryNo, '11234');
      expect(tx.date, '01/02/2024');
      expect(tx.entryTypeName, 'قيد يومية');
      expect(tx.description, 'بيان الحركة');
      expect(tx.debit, 100.0);
      expect(tx.balance, 100.0);
    });

    test('reads uppercase Oracle keys', () {
      final tx = AccountTransactionModel.fromJson({
        'ENTRY_NO': 7654321,
        'SUB_ENTRY_NO': '11111',
        'ENTRY_DATE': '15/03/2024',
        'ENTRY_TYPE_NAME': 'سند',
        'DETAILS': 'مقبوضات',
        'ENTRY_MNT': -50.0,
        'BALANCE_S': 450.0,
      });

      expect(tx.entryNo, 7654321);
      expect(tx.subEntryNo, '11111');
      expect(tx.date, '15/03/2024');
      expect(tx.entryTypeName, 'سند');
      expect(tx.description, 'مقبوضات');
      // ENTRY_MNT is negative — server maps it to credit at the response layer
      // already, but the raw BALANCE_S fallback should still parse fine.
      expect(tx.balance, 450.0);
    });

    test('applies Arabic encoding fix on mojibake text', () {
      // Byte 0xDE in Windows-1256 = 'ق'. When the API proxies raw Oracle bytes
      // as Latin-1, the client sees U+00DE ('Þ'). ArabicEncodingUtils maps it
      // back to the correct Arabic letter.
      final mojibake = 'ÞØ¨'; // => 'ق' + 'ط' after the CP-1256 lookup table
      final tx = AccountTransactionModel.fromJson({
        'entry_type_name': mojibake,
      });

      // ArabicEncodingUtils should transform those bytes back into real Arabic.
      expect(tx.entryTypeName, isNot(mojibake));
      expect(tx.entryTypeName!.contains('ق'), isTrue);
    });
  });

  group('AccountStatementData.fromJson', () {
    test('parses extended summary fields', () {
      final data = AccountStatementData.fromJson({
        'success': true,
        'data': {
          'account': {'acc_no': 12910217, 'acc_name': 'جاري العاملين'},
          'transactions': [
            {
              'entry_no': 1,
              'sub_entry_no': '10001',
              'date': '01/01/2024',
              'entry_type_name': 'قيد يومية',
              'description': 'بيان ١',
              'debit': 100.0,
              'credit': 0.0,
              'balance': 100.0,
            },
          ],
          'summary': {
            'opening_balance': 500.0,
            'final_balance': 600.0,
            'total_debit': 100.0,
            'total_credit': 0.0,
            'current_balance': 600.0,
            'total_records': 1,
            'currency': 'يمني YR',
            'from_date': '2024-01-01',
            'to_date': '2024-02-01',
            'defaulted': true,
          },
        },
      });

      expect(data.openingBalance, 500.0);
      expect(data.finalBalance, 600.0);
      expect(data.totalDebit, 100.0);
      expect(data.totalCredit, 0.0);
      expect(data.currency, 'يمني YR');
      expect(data.fromDate, '2024-01-01');
      expect(data.toDate, '2024-02-01');
      expect(data.defaulted, isTrue);
      expect(data.transactions.length, 1);
      expect(data.transactions.first.entryNo, 1);
    });

    test('empty currency string is normalized to null (not empty string)', () {
      final data = AccountStatementData.fromJson({
        'data': {
          'summary': {'currency': ''},
        },
      });
      expect(data.currency, isNull);
    });
  });

  group('TrialBalanceRow.fromJson', () {
    test('parses lowercase keys', () {
      final row = TrialBalanceRow.fromJson({
        'acc_no': 12910217,
        'acc_name': 'أحمد',
        'cur_code': 'YR',
        'local_debit': 1000.0,
        'local_credit': 500.0,
        'foreign_debit': 0.0,
        'foreign_credit': 0.0,
        'balance': 500.0,
        'current_balance': 500.0,
      });

      expect(row.accNo, 12910217);
      expect(row.accName, 'أحمد');
      expect(row.curCode, 'YR');
      expect(row.localDebit, 1000.0);
      expect(row.localCredit, 500.0);
      expect(row.balance, 500.0);
    });

    test('parses uppercase Oracle keys and defaults cur_code to YR', () {
      final row = TrialBalanceRow.fromJson({
        'ACC_NO': 1,
        'ACC_NAME': 'test',
        'LOCAL_DEBIT': 10,
        'LOCAL_CREDIT': 5,
        'FOREIGN_DEBIT': 0,
        'FOREIGN_CREDIT': 0,
        'BALANCE': 5,
        'CURRENT_BALANCE': 5,
      });

      expect(row.accNo, 1);
      expect(row.curCode, 'YR');
      expect(row.localDebit, 10.0);
    });
  });

  group('TrialBalanceReport.fromJson', () {
    test('parses full envelope with totals and rows', () {
      final report = TrialBalanceReport.fromJson({
        'success': true,
        'data': {
          'scope_level': 'sub',
          'scope_label': 'جاري العاملين',
          'as_of_date': '21/10/2026',
          'from_date': null,
          'to_date': null,
          'rows': [
            {
              'acc_no': 12910217,
              'acc_name': 'موظف أ',
              'cur_code': 'YR',
              'local_debit': 100.0,
              'local_credit': 50.0,
              'foreign_debit': 0.0,
              'foreign_credit': 0.0,
              'balance': 50.0,
              'current_balance': 50.0,
            },
            {
              'acc_no': 12910218,
              'acc_name': 'موظف ب',
              'cur_code': 'YR',
              'local_debit': 200.0,
              'local_credit': 0.0,
              'foreign_debit': 0.0,
              'foreign_credit': 0.0,
              'balance': 200.0,
              'current_balance': 200.0,
            },
          ],
          'totals': {
            'local_debit': 300.0,
            'local_credit': 50.0,
            'foreign_debit': 0.0,
            'foreign_credit': 0.0,
            'balance': 250.0,
          },
        },
      });

      expect(report.scopeLevel, 'sub');
      expect(report.scopeLabel, 'جاري العاملين');
      expect(report.asOfDate, '21/10/2026');
      expect(report.rows.length, 2);
      expect(report.totals.localDebit, 300.0);
      expect(report.totals.localCredit, 50.0);
      expect(report.totals.balance, 250.0);
      expect(report.isEmpty, isFalse);
    });

    test('empty returns isEmpty true', () {
      const report = TrialBalanceReport.empty;
      expect(report.isEmpty, isTrue);
      expect(report.rows, isEmpty);
    });
  });
}
