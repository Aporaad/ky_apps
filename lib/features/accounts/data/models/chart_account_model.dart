import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// نموذج الحساب المالي (CHART_ACC)
// ================================================================

/// الحساب المالي الفردي من CHART_ACC
class ChartAccountModel {
  final int accNo;
  final String accName;
  final double? balance;
  final String? accDate;
  final int? seq;
  final int? groupId;
  final double? limitedBalance;
  final int? stoppingAcc;

  const ChartAccountModel({
    required this.accNo,
    required this.accName,
    this.balance,
    this.accDate,
    this.seq,
    this.groupId,
    this.limitedBalance,
    this.stoppingAcc,
  });

  bool get isStopped => stoppingAcc != null && stoppingAcc != 0;

  factory ChartAccountModel.fromJson(Map<String, dynamic> json) => ChartAccountModel(
        accNo: _parseInt(json['acc_no']) ?? 0,
        accName: ArabicEncodingUtils.fix(json['acc_name']),
        balance: _parseDouble(json['balance']),
        accDate: json['acc_date']?.toString(),
        seq: _parseInt(json['seq']),
        groupId: _parseInt(json['group_id']),
        limitedBalance: _parseDouble(json['limited_balance']),
        stoppingAcc: _parseInt(json['stopping_acc']),
      );

  Map<String, dynamic> toJsonForApi() => {
        'acc_name': accName,
        if (balance != null) 'balance': balance,
        if (groupId != null) 'group_id': groupId,
        if (limitedBalance != null) 'limited_balance': limitedBalance,
        if (stoppingAcc != null) 'stopping_acc': stoppingAcc,
      };

  ChartAccountModel copyWith({
    int? accNo,
    String? accName,
    double? balance,
    String? accDate,
    int? seq,
    int? groupId,
    double? limitedBalance,
    int? stoppingAcc,
  }) =>
      ChartAccountModel(
        accNo: accNo ?? this.accNo,
        accName: accName ?? this.accName,
        balance: balance ?? this.balance,
        accDate: accDate ?? this.accDate,
        seq: seq ?? this.seq,
        groupId: groupId ?? this.groupId,
        limitedBalance: limitedBalance ?? this.limitedBalance,
        stoppingAcc: stoppingAcc ?? this.stoppingAcc,
      );
}

// ================================================================
// نموذج كشف الحساب
// ================================================================

/// حركة واحدة في كشف الحساب
class AccountTransactionModel {
  final String? date;
  final String? description;
  final double? debit;
  final double? credit;
  final double? balance;

  const AccountTransactionModel({
    this.date,
    this.description,
    this.debit,
    this.credit,
    this.balance,
  });

  factory AccountTransactionModel.fromJson(Map<String, dynamic> json) =>
      AccountTransactionModel(
        date: json['date']?.toString(),
        description: ArabicEncodingUtils.fix(json['description']),
        debit: _parseDouble(json['debit']),
        credit: _parseDouble(json['credit']),
        balance: _parseDouble(json['balance']),
      );
}

/// بيانات كشف الحساب الكاملة
class AccountStatementData {
  final Map<String, dynamic>? account;
  final List<AccountTransactionModel> transactions;
  final double? currentBalance;
  final int totalRecords;

  const AccountStatementData({
    this.account,
    this.transactions = const [],
    this.currentBalance,
    this.totalRecords = 0,
  });

  factory AccountStatementData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final txList = (data['transactions'] as List? ?? [])
        .map((t) => AccountTransactionModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return AccountStatementData(
      account: data['account'] as Map<String, dynamic>?,
      transactions: txList,
      currentBalance: _parseDouble(summary['current_balance']),
      totalRecords: _parseInt(summary['total_records']) ?? 0,
    );
  }
}

// ======================== Helper Parsers ========================

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
