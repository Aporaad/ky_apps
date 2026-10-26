import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// كشف حساب مجموعة حسابات جزئية (ميزان المراجعة)
// ================================================================
// Mirrors GET /accounts/group-statement response shape produced by
// AccountController::getGroupStatement, with defensive dual-case key reads
// and ArabicEncodingUtils.fix() on every text field, matching the existing
// chart_account_model.dart / CustomerStatementModel parsing conventions.

/// سطر واحد في ميزان المراجعة — حساب مالي واحد مع مجاميع الفترة
/// ورصيده النهائي الدائم.
///
/// كل الأرقام في `localDebit/localCredit/foreignDebit/foreignCredit` وكذلك
/// `periodBalance` تخصّ الفترة المختارة (أو كامل السجل عند تركها فارغة)، أما
/// `balance` فهو **الرصيد النهائي** للحساب على كامل حركاته ولا يتغير بتغيير الفترة.
/// One trial-balance line: period DR/CR figures plus two balances — `periodBalance`
/// for the selected window and `balance` for the account's final balance, which is
/// independent of the date filter.
class TrialBalanceRow {
  final int accNo;
  final String accName;
  final String curCode;
  final double localDebit;
  final double localCredit;
  final double foreignDebit;
  final double foreignCredit;

  /// الرصيد النهائي للحساب (صافي كل حركاته من ENTRY_MNT) — لا يُقرأ من
  /// `CHART_ACC.BALANCE` ولا من `BALANCE_S` المخزّنين.
  final double balance;

  /// صافي حركة الفترة المختارة — يُعرض في عمود «رصيد الفترة» المنفصل.
  final double periodBalance;

  const TrialBalanceRow({
    required this.accNo,
    required this.accName,
    required this.curCode,
    required this.localDebit,
    required this.localCredit,
    required this.foreignDebit,
    required this.foreignCredit,
    required this.balance,
    this.periodBalance = 0,
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
        periodBalance:
            _parseDouble(json['period_balance'] ?? json['PERIOD_BALANCE']) ?? 0,
      );
}

/// ملخص إجماليات ميزان المراجعة (سطر "الإجمالي" أسفل الجدول).
///
/// `balance` إجمالي الأرصدة النهائية، و`periodBalance` إجمالي أرصدة الفترة —
/// يظهر الثاني في عمود «رصيد الفترة» فقط عند تحديد فترة.
class TrialBalanceTotals {
  final double localDebit;
  final double localCredit;
  final double foreignDebit;
  final double foreignCredit;

  /// إجمالي الرصيد النهائي لكل الحسابات في النطاق.
  final double balance;

  /// إجمالي «رصيد الفترة» لكل الحسابات في النطاق.
  final double periodBalance;

  const TrialBalanceTotals({
    this.localDebit = 0,
    this.localCredit = 0,
    this.foreignDebit = 0,
    this.foreignCredit = 0,
    this.balance = 0,
    this.periodBalance = 0,
  });

  factory TrialBalanceTotals.fromJson(Map<String, dynamic> json) =>
      TrialBalanceTotals(
        localDebit: _parseDouble(json['local_debit'] ?? json['LOCAL_DEBIT']) ?? 0,
        localCredit: _parseDouble(json['local_credit'] ?? json['LOCAL_CREDIT']) ?? 0,
        foreignDebit: _parseDouble(json['foreign_debit'] ?? json['FOREIGN_DEBIT']) ?? 0,
        foreignCredit: _parseDouble(json['foreign_credit'] ?? json['FOREIGN_CREDIT']) ?? 0,
        balance: _parseDouble(json['balance'] ?? json['BALANCE']) ?? 0,
        periodBalance:
            _parseDouble(json['period_balance'] ?? json['PERIOD_BALANCE']) ?? 0,
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

  /// هل اختار المستخدم فترة؟ يتحكم في إظهار عمود «رصيد الفترة» في الجدول
  /// وفي ملفات PDF/Excel — يُقرأ من الخادم (`has_period`) ويُستنتج من التواريخ
  /// أيضاً حتى لا يعتمد العرض على مفتاح واحد.
  /// Whether a period was chosen; drives the extra «period balance» column.
  final bool hasPeriod;
  final List<TrialBalanceRow> rows;
  final TrialBalanceTotals totals;

  /// عدد صفوف النطاق كاملاً كما يعده الخادم (`meta.total`)، لا عدد الصفوف
  /// الواصلة في هذه الاستجابة — هو ما يقرر إن كان النطاق «واسعاً جداً».
  /// Two totals exist on purpose: `total` counts the WHOLE scope on the server
  /// (so a huge scope is known before downloading it), `rows.length` counts what
  /// this response actually carried.
  final int total;

  /// رقم آخر صفحة وُصلت، وحجمها، وعدد صفحات النطاق، وهل بقي المزيد.
  /// Last page received, its size, the scope's page count, and whether more remain.
  final int page;
  final int limit;
  final int totalPages;
  final bool hasMore;

  const TrialBalanceReport({
    this.scopeLevel = '',
    this.scopeLabel = '',
    this.asOfDate = '',
    this.fromDate,
    this.toDate,
    this.hasPeriod = false,
    this.rows = const [],
    this.totals = TrialBalanceTotals.empty,
    this.total = 0,
    this.page = 1,
    this.limit = 0,
    this.totalPages = 1,
    this.hasMore = false,
  });

  bool get isEmpty => rows.isEmpty;

  /// هل وصل جزء من النطاق فقط؟ (الخادم يعرف أكثر مما حُمِّل بعد)
  /// True when only part of the scope has been downloaded so far.
  bool get isPartial => total > 0 && rows.length < total;

  /// نسبة التحميل التدريجي 0..1 — تقود شريط التقدّم.
  /// Progressive download ratio, clamped to 0..1 for the progress bar.
  double get loadRatio {
    if (total <= 0) return rows.isEmpty ? 0 : 1;
    return (rows.length / total).clamp(0.0, 1.0);
  }

  /// نص الفترة الموحّد للشاشة و PDF و Excel — يحتمل تاريخاً واحداً فقط.
  /// Shared period label for screen, PDF and Excel; handles one-sided dates.
  String get periodLabel {
    if (fromDate != null && toDate != null) {
      return 'من تاريخ: $fromDate   إلى تاريخ: $toDate';
    }
    if (fromDate != null) return 'من تاريخ: $fromDate';
    if (toDate != null) return 'إلى تاريخ: $toDate';
    return 'كل الحركات (بدون تحديد فترة)';
  }

  /// يضيف صفحة تالية إلى هذا التقرير — التحميل التدريجي على أقسام.
  ///
  /// الإجماليات تبقى من الصفحة الأولى لأنها محسوبة على النطاق كاملاً في
  /// الخادم؛ جمع إجمالي كل صفحة كان سيضاعف الرقم. حقول النطاق (الاسم/الفترة)
  /// تبقى أيضاً، والميتاداتا تُحدَّث من الصفحة الأحدث.
  /// Appends the next page. Totals are deliberately kept from the FIRST page:
  /// the server computes them over the whole scope, so adding page totals would
  /// double-count. Scope labels stay; only pagination meta advances.
  TrialBalanceReport appendPage(TrialBalanceReport next) {
    return TrialBalanceReport(
      scopeLevel: scopeLevel.isEmpty ? next.scopeLevel : scopeLevel,
      scopeLabel: scopeLabel.isEmpty ? next.scopeLabel : scopeLabel,
      asOfDate: asOfDate.isEmpty ? next.asOfDate : asOfDate,
      fromDate: fromDate ?? next.fromDate,
      toDate: toDate ?? next.toDate,
      hasPeriod: hasPeriod || next.hasPeriod,
      rows: [...rows, ...next.rows],
      totals: totals,
      // 0 يعني «الخادم لم يعدّ» — عندها نحتفظ بالرقم المعروف سابقاً.
      total: next.total > 0 ? next.total : total,
      page: next.page,
      limit: next.limit > 0 ? next.limit : limit,
      totalPages: next.totalPages > 0 ? next.totalPages : totalPages,
      hasMore: next.hasMore,
    );
  }

  factory TrialBalanceReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rowList = (data['rows'] as List? ?? [])
        .map((e) => TrialBalanceRow.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalsJson = data['totals'] as Map<String, dynamic>?;
    final fromDate = (data['from_date'] ?? data['FROM_DATE'])?.toString();
    final toDate = (data['to_date'] ?? data['TO_DATE'])?.toString();
    final periodFlag = data['has_period'] ?? data['HAS_PERIOD'];

    // الميتاداتا هي مصدر الحقيقة لعدد صفوف النطاق كاملاً وحدود الترقيم؛ عند
    // غيابها (خادم أقدم) نسقط إلى حجم هذه الاستجابة حتى لا يظهر الرقم صفراً.
    // `meta` is the authority for the scope-wide count and the page bounds; an
    // older server that omits it falls back to this response's own size.
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    final total = _parseInt(meta['total']) ?? rowList.length;
    final page = _parseInt(meta['page']) ?? 1;
    final limit = _parseInt(meta['limit']) ?? rowList.length;
    final totalPages = _parseInt(meta['total_pages']) ?? 1;
    final hasMoreFlag = meta['has_more'] ?? meta['HAS_MORE'];

    return TrialBalanceReport(
      scopeLevel: (data['scope_level'] ?? data['SCOPE_LEVEL'] ?? '').toString(),
      scopeLabel: ArabicEncodingUtils.fix(data['scope_label'] ?? data['SCOPE_LABEL']),
      asOfDate: (data['as_of_date'] ?? data['AS_OF_DATE'] ?? '').toString(),
      fromDate: fromDate,
      toDate: toDate,
      hasPeriod: periodFlag == true ||
          periodFlag == 1 ||
          periodFlag == '1' ||
          fromDate != null ||
          toDate != null,
      rows: rowList,
      totals: totalsJson != null
          ? TrialBalanceTotals.fromJson(totalsJson)
          : TrialBalanceTotals.empty,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
      hasMore: hasMoreFlag == true || hasMoreFlag == 1 || hasMoreFlag == '1',
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
