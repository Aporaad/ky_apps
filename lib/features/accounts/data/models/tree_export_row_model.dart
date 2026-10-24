import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// صفوف تصدير الشجرة المسطّحة + نطاق التصدير + دليل عملات النموذج
// ================================================================

/// مستويات الشجرة التي يختار المستخدم طباعتها/تصديرها.
/// The five tree levels the user can opt into for a print/export job. Order matters:
/// it is the document order, and the server walks the hierarchy in exactly this order.
enum TreeExportLevel {
  /// الحساب الرئيسي (ACCOUNT) — القسم
  account('account', 'الحسابات الرئيسة', 'الأقسام العليا في الدليل'),
  /// الحساب الفرعي (ACC_MAIN)
  main('main', 'الحسابات الفرعية', 'فروع داخل كل قسم'),
  /// الحساب الجزئي (ACC_SUB)
  sub('sub', 'الحسابات الجزئية', 'أجزاء داخل كل فرع'),
  /// مجموعة الحسابات (ACC_SUB_GROUP)
  group('group', 'المجموعات', 'مجموعات داخل كل جزئي'),
  /// الحساب المالي (CHART_ACC) — الورقة التي لها حركات
  chart('chart', 'الحسابات المالية', 'حسابات دفتر الأستاذ النهائية');

  const TreeExportLevel(this.code, this.labelAr, this.hintAr);

  /// الرمز المرسل للخادم — ASCII ثابت، لا نص عربي في المعرّفات.
  final String code;
  final String labelAr;
  final String hintAr;

  static List<TreeExportLevel> parseCodes(Iterable<String> codes) {
    final out = <TreeExportLevel>[];
    for (final level in TreeExportLevel.values) {
      if (codes.contains(level.code)) out.add(level);
    }
    return out;
  }

  /// رموز مجموعة مستويات — تُستعمل لبناء معامل `levels` في الطلب.
  static List<String> codesOf(Iterable<TreeExportLevel> levels) =>
      levels.map((l) => l.code).toList();
}

/// نطاق طلب التصدير: أي المستويات، أي قسم، هل تدخل حسابات العملاء، هل تُخفى
/// الأرصدة الصفرية، وما الفترة المحسوبة عليها الأرصدة.
/// The export request. Deliberately a value object: the sheet builds one, the
/// repository turns it into query params, and the meta echo makes the produced
/// document self-describing (the footer can quote exactly what was exported).
class TreeExportScope {
  final List<TreeExportLevel> levels;
  final int? sectionAccNo;
  final bool includeCustomers;
  final bool hideZeroBalances;
  final String? fromDate;
  final String? toDate;

  const TreeExportScope({
    required this.levels,
    this.sectionAccNo,
    this.includeCustomers = false,
    this.hideZeroBalances = false,
    this.fromDate,
    this.toDate,
  });

  /// النطاق الافتراضي = كل المستويات بلا استثناء: الشكوى الأصلية كانت أن المطبوعة
  /// كانت تتضمن الحسابات الرئيسة فقط.
  /// Default is every level — the reported bug was a printout of main accounts only.
  static const TreeExportScope all = TreeExportScope(levels: TreeExportLevel.values);

  bool get containsCustomers =>
      levels.contains(TreeExportLevel.chart) && includeCustomers;

  TreeExportScope copyWith({
    List<TreeExportLevel>? levels,
    Object? sectionAccNo = _unset,
    bool? includeCustomers,
    bool? hideZeroBalances,
    Object? fromDate = _unset,
    Object? toDate = _unset,
  }) => TreeExportScope(
    levels: levels ?? this.levels,
    sectionAccNo: sectionAccNo == _unset
        ? this.sectionAccNo
        : sectionAccNo as int?,
    includeCustomers: includeCustomers ?? this.includeCustomers,
    hideZeroBalances: hideZeroBalances ?? this.hideZeroBalances,
    fromDate: fromDate == _unset ? this.fromDate : fromDate as String?,
    toDate: toDate == _unset ? this.toDate : toDate as String?,
  );

  /// معرّف الفلاتر للنص التوضيحي أسفل المستند — يصف المطبوعة نفسها، لا حالة الشاشة.
  /// Describes the document, so a printed page states what it contains.
  String describe() {
    final parts = <String>[
      'المستويات: ${levels.map((l) => l.labelAr).join(' • ')}',
    ];
    if (sectionAccNo != null) parts.add('القسم $sectionAccNo');
    if (includeCustomers) parts.add('شامل حسابات العملاء');
    if (hideZeroBalances) parts.add('مُخفيت الأرصدة الصفرية');
    if (fromDate != null || toDate != null) {
      parts.add('الفترة ${fromDate ?? '…'} ← ${toDate ?? '…'}');
    }
    return parts.join(' • ');
  }

  Map<String, dynamic> toQuery() => {
    'levels': levels.map((l) => l.code).join(','),
    if (sectionAccNo != null) 'section': sectionAccNo,
    'include_customers': includeCustomers ? '1' : '0',
    'hide_zero': hideZeroBalances ? '1' : '0',
    if (fromDate != null) 'from_date': fromDate,
    if (toDate != null) 'to_date': toDate,
  };

  static const Object _unset = Object();
}

/// صف واحد من `/accounts/export-tree` — مستطّل، بكل مستويات الهيكل والأوراق المالية.
/// One flat row from the export endpoint. Structural levels and ledger leaves share
/// this shape; [level] says which, and the builders read only what they need.
class TreeExportRow {
  final int depth;
  final String level;
  final String code;
  final int? accNo;
  final int? accSub;
  final int? accPart;
  final int? groupId;
  final String name;
  final String parentPath;
  final String codePath;
  final double debit;
  final double credit;
  final double balance;
  final int movements;
  final double? storedBalance;
  final double? limitedBalance;
  final int? stoppingAcc;
  final int? seq;
  final int? curNo;
  final String? accDate;
  final int accountCount;
  final int childrenCount;

  /// القسم المالك لهذا الصف. ضروري لأن accNo يعني شيئاً مختلفاً عند مستوى الأوراق
  /// (رقم الحساب نفسه) عنه عند المستويات الهيكلية (رقم القسم).
  /// The owning section. `accNo` alone cannot express it: at leaf level it is the
  /// ledger number, not the section number.
  final int? rootAccNo;

  const TreeExportRow({
    required this.depth,
    required this.level,
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.movements,
    this.accNo,
    this.accSub,
    this.accPart,
    this.groupId,
    this.parentPath = '',
    this.codePath = '',
    this.storedBalance,
    this.limitedBalance,
    this.stoppingAcc,
    this.seq,
    this.curNo,
    this.accDate,
    this.accountCount = 0,
    this.childrenCount = 0,
    this.rootAccNo,
  });

  factory TreeExportRow.fromJson(Map<String, dynamic> json) {
    // قراءة مزدوجة للحالة: الوسائط تصل من Laravel بأحرف صغيرة، وأي تمرير خام من
    // Oracle قد يصل بأحرف كبيرة — نفس convention بقية نماذج المشروع.
    dynamic pick(String lower, [String? upper]) =>
        json[lower] ?? json[upper ?? lower.toUpperCase()];

    return TreeExportRow(
      depth: _parseInt(pick('depth')) ?? 0,
      level: pick('level')?.toString() ?? 'chart',
      code: pick('code')?.toString() ?? '',
      accNo: _parseInt(pick('acc_no')),
      accSub: _parseInt(pick('acc_sub')),
      accPart: _parseInt(pick('acc_part')),
      groupId: _parseInt(pick('group_id')),
      // كل نص عربي يمر بإصلاح الترميز: Oracle يخزّن CP1256 ويُنقل كـ mojibake.
      name: ArabicEncodingUtils.fix(pick('name')),
      parentPath: ArabicEncodingUtils.fix(pick('parent_path')),
      codePath: pick('code_path')?.toString() ?? '',
      debit: _parseDouble(pick('debit')) ?? 0,
      credit: _parseDouble(pick('credit')) ?? 0,
      balance: _parseDouble(pick('balance')) ?? 0,
      movements: _parseInt(pick('movements')) ?? 0,
      storedBalance: _parseDouble(pick('stored_balance')),
      limitedBalance: _parseDouble(pick('limited_balance')),
      stoppingAcc: _parseInt(pick('stopping_acc')),
      seq: _parseInt(pick('seq')),
      curNo: _parseInt(pick('cur_no')),
      accDate: pick('acc_date')?.toString(),
      accountCount: _parseInt(pick('account_count')) ?? 0,
      childrenCount: _parseInt(pick('children_count')) ?? 0,
      rootAccNo: _parseInt(pick('root_acc_no')),
    );
  }

  bool get isLedger => level == 'chart';

  bool get isStopped => stoppingAcc != null && stoppingAcc != 0;

  /// تسمية المستوى بالعربية — نفس ترميز الشاشة حتى لا تختلف المطبوعة عنها.
  String get levelLabel => switch (level) {
    'account' => 'رئيسي',
    'main' => 'فرعي',
    'sub' => 'جزئي',
    'group' => 'مجموعة',
    _ => 'حساب',
  };

  /// مسار مختصر يُطبع بجانب الاسم حين لا يسع السطر الاسم وحده.
  String get shortParent => parentPath.isEmpty ? '' : parentPath.split(' / ').last;
}

/// عنصر دليل عملة لملء حقل العملة في نموذجي الإنشاء والتعديل.
/// A currency option for the account form's picker. Deliberately two fields only:
/// `/accounts/currencies` returns what the form actually needs, and it is granted by
/// the *accounts* permissions — `currencies.view` would 403 for an accounts-only user
/// and leave the picker empty while asking them to choose.
class CurrencyOptionModel {
  final int curNo;
  final String curName;

  const CurrencyOptionModel({required this.curNo, required this.curName});

  factory CurrencyOptionModel.fromJson(Map<String, dynamic> json) =>
      CurrencyOptionModel(
        curNo: _parseInt(json['cur_no'] ?? json['CUR_NO']) ?? 0,
        curName: ArabicEncodingUtils.fix(json['cur_name'] ?? json['CUR_NAME']),
      );

  /// «١ — يمني»: الرقم مطلوب لأن ما يُخزَّن في الجدول هو CUR_NO لا الاسم.
  String get display => '$curNo — $curName';

  @override
  bool operator ==(Object other) =>
      other is CurrencyOptionModel &&
      other.curNo == curNo &&
      other.curName == curName;

  @override
  int get hashCode => Object.hash(curNo, curName);
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
