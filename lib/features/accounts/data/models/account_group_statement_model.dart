import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// كشف حساب مجموعة حسابات جزئية (ميزان المراجعة)
// ================================================================
// Mirrors GET /accounts/group-statement response shape produced by
// AccountController::getGroupStatement, with defensive dual-case key reads
// and ArabicEncodingUtils.fix() on every text field, matching the existing
// chart_account_model.dart / CustomerStatementModel parsing conventions.

/// سطر واحد في ميزان المراجعة — حساب مالي واحد مع مجاميعه.
class TrialBalanceRow {
  final int accNo;
  final String accName;
  final String curCode;
  final double localDebit;
  final double localCredit;
  final double foreignDebit;
  final double foreignCredit;
  final double balance;
  final double currentBalance;

  const TrialBalanceRow({
    required this.accNo,
    required this.accName,
    required this.curCode,
    required this.localDebit,
    required this.localCredit,
    required this.foreignDebit,
    required this.foreignCredit,
    required this.balance,
    required this.currentBalance,
  });

  factory TrialBalanceRow.fromJson(Map<String, dynamic> json) => TrialBalanceRow(
        accNo: _parseInt(json['acc_no'] ?? json['ACC_NO']) ?? 0,
        accName: ArabicEncodingUtils.fix(json['acc_name'] ?? json['ACC_NAME']),
        curCode: (json['cur_code'] ?? json['CUR_CODE'] ?? 'YR').toString(),
        localDebit: _parseDouble(json['local_debit'] ?? json['LOCAL_DEBIT']) ?? 0,
        localCredit: _parseDouble(json['local_credit'] ?? json['LOCAL_CREDIT']) ?? 0,
        foreignDebit: _parseDouble(json['foreign_debit'] ?? json['FOREIGN_DEBIT']) ?? 0,
        foreignCredit: _parseDouble(json['foreign_credit'] ?? json['FOREIGN_CREDIT']) ?? 0,
        balance: _parseDouble(json['balance'] ?? json['BALANCE']) ?? 0,
        currentBalance: _parseDouble(json['current_balance'] ?? json['CURRENT_BALANCE']) ?? 0,
      );
}

/// ملخص إجماليات ميزان المراجعة (سطر "الإجمالي" أسفل الجدول).
class TrialBalanceTotals {
  final double localDebit;
  final double localCredit;
  final double foreignDebit;
  final double foreignCredit;
  final double balance;

  const TrialBalanceTotals({
    this.localDebit = 0,
    this.localCredit = 0,
    this.foreignDebit = 0,
    this.foreignCredit = 0,
    this.balance = 0,
  });

  factory TrialBalanceTotals.fromJson(Map<String, dynamic> json) =>
      TrialBalanceTotals(
        localDebit: _parseDouble(json['local_debit'] ?? json['LOCAL_DEBIT']) ?? 0,
        localCredit: _parseDouble(json['local_credit'] ?? json['LOCAL_CREDIT']) ?? 0,
        foreignDebit: _parseDouble(json['foreign_debit'] ?? json['FOREIGN_DEBIT']) ?? 0,
        foreignCredit: _parseDouble(json['foreign_credit'] ?? json['FOREIGN_CREDIT']) ?? 0,
        balance: _parseDouble(json['balance'] ?? json['BALANCE']) ?? 0,
      );

  static const TrialBalanceTotals empty = TrialBalanceTotals();
}

/// تقرير ميزان المراجعة الكامل لمجموعة حسابات جزئية.
class TrialBalanceReport {
  final String scopeLevel;
  final String scopeLabel;
  final String asOfDate;
  final String? fromDate;
  final String? toDate;
  final List<TrialBalanceRow> rows;
  final TrialBalanceTotals totals;

  const TrialBalanceReport({
    this.scopeLevel = '',
    this.scopeLabel = '',
    this.asOfDate = '',
    this.fromDate,
    this.toDate,
    this.rows = const [],
    this.totals = TrialBalanceTotals.empty,
  });

  bool get isEmpty => rows.isEmpty;

  factory TrialBalanceReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rowList = (data['rows'] as List? ?? [])
        .map((e) => TrialBalanceRow.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalsJson = data['totals'] as Map<String, dynamic>?;

    return TrialBalanceReport(
      scopeLevel: (data['scope_level'] ?? data['SCOPE_LEVEL'] ?? '').toString(),
      scopeLabel: ArabicEncodingUtils.fix(data['scope_label'] ?? data['SCOPE_LABEL']),
      asOfDate: (data['as_of_date'] ?? data['AS_OF_DATE'] ?? '').toString(),
      fromDate: (data['from_date'] ?? data['FROM_DATE'])?.toString(),
      toDate: (data['to_date'] ?? data['TO_DATE'])?.toString(),
      rows: rowList,
      totals: totalsJson != null
          ? TrialBalanceTotals.fromJson(totalsJson)
          : TrialBalanceTotals.empty,
    );
  }

  static const TrialBalanceReport empty = TrialBalanceReport();
}

// ======================== Helper Parsers ========================
// Same implementations as chart_account_model.dart — kept local to this file
// to avoid a cross-model import for two tiny helpers, matching how the other
// account models already duplicate these private helpers per-file.

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
