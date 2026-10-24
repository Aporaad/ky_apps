import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// نماذج بيانات الشجرة المحاسبية
// ACCOUNT > ACC_MAIN > ACC_SUB > ACC_SUB_GROUP > CHART_ACC
// ================================================================

/// القسم الرئيسي (ACCOUNT)
class AccountModel {
  final int accNo;
  final String accName;
  final double? balance;
  final int? curNo;

  const AccountModel({
    required this.accNo,
    required this.accName,
    this.balance,
    this.curNo,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        accNo: _parseInt(json['acc_no']) ?? 0,
        accName: ArabicEncodingUtils.fix(json['acc_name']),
        balance: _parseDouble(json['balance']),
        curNo: _parseInt(json['cur_no']),
      );
}

/// الحساب الفرعي (ACC_MAIN)
class AccMainModel {
  final int accNo;
  final int accSub;
  final String subName;
  final double? balance;
  final int? curNo;

  const AccMainModel({
    required this.accNo,
    required this.accSub,
    required this.subName,
    this.balance,
    this.curNo,
  });

  factory AccMainModel.fromJson(Map<String, dynamic> json) => AccMainModel(
        accNo: _parseInt(json['acc_no']) ?? 0,
        accSub: _parseInt(json['acc_sub']) ?? 0,
        subName: ArabicEncodingUtils.fix(json['sub_name']),
        balance: _parseDouble(json['balance']),
        curNo: _parseInt(json['cur_no']),
      );
}

/// الحساب الجزئي (ACC_SUB)
class AccSubModel {
  final int accSub;
  final int accPart;
  final String partName;
  final double? balance;
  final int? curNo;

  const AccSubModel({
    required this.accSub,
    required this.accPart,
    required this.partName,
    this.balance,
    this.curNo,
  });

  factory AccSubModel.fromJson(Map<String, dynamic> json) => AccSubModel(
        accSub: _parseInt(json['acc_sub']) ?? 0,
        accPart: _parseInt(json['acc_part']) ?? 0,
        partName: ArabicEncodingUtils.fix(json['part_name']),
        balance: _parseDouble(json['balance']),
        curNo: _parseInt(json['cur_no']),
      );
}

/// مجموعة الحسابات الجزئي (ACC_SUB_GROUP)
class AccSubGroupModel {
  final int groupId;
  final int accPart;
  final String accGroupName;

  const AccSubGroupModel({
    required this.groupId,
    required this.accPart,
    required this.accGroupName,
  });

  factory AccSubGroupModel.fromJson(Map<String, dynamic> json) => AccSubGroupModel(
        groupId: _parseInt(json['group_id']) ?? 0,
        accPart: _parseInt(json['acc_part']) ?? 0,
        accGroupName: ArabicEncodingUtils.fix(json['acc_group_name']),
      );
}

/// عقدة الشجرة المحاسبية (تستخدم في عرض الشجرة)
///
/// عقدة هيكلية قادمة من `/accounts/tree`: الأقسام والفروع والأجزاء والمجموعات،
/// وأحياناً ورقة مالية واحدة مُدرَجة داخل الهيكل (حساب العملاء المعروض).
/// A structural node from `/accounts/tree`; financial leaves normally arrive lazily
/// through `/accounts/tree/children`, except the single in-structure chart leaf.
class AccountTreeNode {
  final String id;
  final String name;
  final String level; // account | main | sub | group | chart
  final int? accNo;
  final int? accSub;
  final int? accPart;
  final int? groupId;

  /// الرصيد الصافي المحسوب من الحركات (ENTRY_SUB) — لا من عمود BALANCE المخزّن.
  /// Net balance rolled up from movements, never the stale stored BALANCE column.
  final double? balance;
  final double? debit;
  final double? credit;
  final int? movements;
  final bool? isStoppped;

  /// مسار الأسماء للأب (الأصول / الأصول الثابتة / أراضي) ومسار الأرقام (1 / 12 / 120).
  final String parentPath;
  final String codePath;

  /// الرصيد المخزّن في الجدول — يُعرض للمقارنة فقط في ورقة التفاصيل.
  final double? storedBalance;
  final int? curNo;
  final int? childrenCount;

  /// هل للعقدة أبناء يُجلبون عند التوسيع؟ مجموعة لها حسابات، وجزئي له مجموعات أو
  /// حسابات مباشرة. Whether expanding this node can fetch anything at all.
  final bool hasChildren;

  /// عدد الحسابات المالية تحت العقدة كاملة (بمن فيهم المخفيين من العرض).
  final int? accountCount;

  /// الحسابات المباشرة للجزئي التي بلا مجموعة (GROUP_ID IS NULL).
  final int? directCount;

  /// حسابات داخل النطاق مستثناة من العرض (عملاء 123) لكن أرصدتها مجمّعة.
  final int? hiddenAccounts;
  final double? limitedBalance;
  final String? accDate;
  final int? seq;
  final List<AccountTreeNode> children;

  const AccountTreeNode({
    required this.id,
    required this.name,
    required this.level,
    this.accNo,
    this.accSub,
    this.accPart,
    this.groupId,
    this.balance,
    this.debit,
    this.credit,
    this.movements,
    this.isStoppped,
    this.parentPath = '',
    this.codePath = '',
    this.storedBalance,
    this.curNo,
    this.childrenCount,
    this.hasChildren = false,
    this.accountCount,
    this.directCount,
    this.hiddenAccounts,
    this.limitedBalance,
    this.accDate,
    this.seq,
    this.children = const [],
  });

  factory AccountTreeNode.fromJson(Map<String, dynamic> json) {
    final childrenList = (json['children'] as List? ?? [])
        .map((c) => AccountTreeNode.fromJson(c as Map<String, dynamic>))
        .toList();

    // المفاتيح قد تصل من Oracle بأحرف كبيرة أو من Laravel بأحرف صغيرة
    // Keys may arrive upper-cased (Oracle) or lower-cased (Laravel envelope).
    dynamic pick(String lower, [String? upper]) =>
        json[lower] ?? json[upper ?? lower.toUpperCase()];

    final stopping = pick('stopping_acc');

    return AccountTreeNode(
      id: pick('id')?.toString() ?? '',
      name: ArabicEncodingUtils.fix(pick('name')),
      level: pick('level')?.toString() ?? 'chart',
      accNo: _parseInt(pick('acc_no')),
      accSub: _parseInt(pick('acc_sub')),
      accPart: _parseInt(pick('acc_part')),
      groupId: _parseInt(pick('group_id')),
      balance: _parseDouble(pick('balance')),
      debit: _parseDouble(pick('debit')),
      credit: _parseDouble(pick('credit')),
      movements: _parseInt(pick('movements')) ?? _parseInt(pick('mov_count')),
      isStoppped: stopping != null && stopping != 0,
      parentPath: ArabicEncodingUtils.fix(pick('parent_path')),
      codePath: pick('code_path')?.toString() ?? '',
      storedBalance: _parseDouble(pick('stored_balance')),
      curNo: _parseInt(pick('cur_no')),
      childrenCount: _parseInt(pick('children_count')) ?? childrenList.length,
      hasChildren:
          pick('has_children') == true ||
          _parseInt(pick('direct_count')) != null ||
          childrenList.isNotEmpty,
      accountCount: _parseInt(pick('account_count')),
      directCount: _parseInt(pick('direct_count')),
      hiddenAccounts: _parseInt(pick('hidden_accounts')),
      limitedBalance: _parseDouble(pick('limited_balance')),
      accDate: pick('acc_date')?.toString(),
      seq: _parseInt(pick('seq')),
      children: childrenList,
    );
  }

  /// هل العقدة ورقة لا توسيع بعدها؟ الأوراق المالية والجزئي الفارغ لا زر توسيع لهما.
  bool get isLeaf => !hasChildren && children.isEmpty;

  bool get isFinancialLeaf => level == 'chart';

  /// معرّف الفلترة: مستوى + رقم — يُستخدم لكاش الأبناء وحالة التوسيع.
  String get expandKey => id;

  /// الأبناء القابلون للعرض: المجموعات والحسابات المُدرَجة داخل الهيكل.
  List<AccountTreeNode> get visibleChildren => children;

  /// البحث داخل الشجرة المُحمَّلة فقط (البحث الخادمي يغطي الباقي).
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (name.toLowerCase().contains(q)) return true;
    if (codePath.toLowerCase().contains(q)) return true;
    if (accNo?.toString().contains(q) ?? false) return true;
    return children.any((c) => c.matchesSearch(q));
  }

  AccountTreeNode filterBySearch(String query) {
    if (query.isEmpty) return this;
    final filteredChildren = children
        .map((c) => c.filterBySearch(query))
        .where((c) => c.matchesSearch(query))
        .toList();
    return AccountTreeNode(
      id: id,
      name: name,
      level: level,
      accNo: accNo,
      accSub: accSub,
      accPart: accPart,
      groupId: groupId,
      balance: balance,
      debit: debit,
      credit: credit,
      movements: movements,
      isStoppped: isStoppped,
      parentPath: parentPath,
      codePath: codePath,
      storedBalance: storedBalance,
      curNo: curNo,
      childrenCount: childrenCount,
      hasChildren: hasChildren,
      accountCount: accountCount,
      directCount: directCount,
      hiddenAccounts: hiddenAccounts,
      limitedBalance: limitedBalance,
      accDate: accDate,
      seq: seq,
      children: filteredChildren,
    );
  }
}

/// الحساب المالي (CHART_ACC) كما يصل من `/accounts/tree/children` و`/accounts/search`.
/// A financial ledger account inside the tree: its own balances, computed from movements.
class AccountLeafModel {
  final int accNo;
  final String accName;
  final int? groupId;
  final int? seq;
  final double debit;
  final double credit;
  final double net;
  final int movements;
  final double storedBalance;
  final double? limitedBalance;
  final bool stopped;
  final String? accDate;
  final String parentPath;

  /// رقم العملة — مُشتق من الخانة الرابعة من acc_no في الخادم (لا عمود لها هنا).
  /// The currency, derived server-side from the 4th digit of acc_no; CHART_ACC
  /// stores no currency column, the number itself carries it.
  final int? curNo;

  const AccountLeafModel({
    required this.accNo,
    required this.accName,
    this.groupId,
    this.seq,
    this.debit = 0,
    this.credit = 0,
    this.net = 0,
    this.movements = 0,
    this.storedBalance = 0,
    this.limitedBalance,
    this.stopped = false,
    this.accDate,
    this.parentPath = '',
    this.curNo,
  });

  factory AccountLeafModel.fromJson(Map<String, dynamic> json) {
    dynamic pick(String lower, [String? upper]) =>
        json[lower] ?? json[upper ?? lower.toUpperCase()];

    double d(String lower, [String? upper]) =>
        _parseDouble(pick(lower, upper)) ?? 0;

    return AccountLeafModel(
      accNo: _parseInt(pick('acc_no')) ?? 0,
      accName: ArabicEncodingUtils.fix(pick('acc_name') ?? pick('name')),
      groupId: _parseInt(pick('group_id')),
      seq: _parseInt(pick('seq')),
      debit: d('debit', 'DR'),
      credit: d('credit', 'CR'),
      // الصافي له ثلاثة أسماء: net/NET من تجميع الحركات، وbalance/BALANCE من غلاف
      // `/accounts/tree/children` — fall back بالترتيب حتى لا يضيع الرصيد إلى صفر
      net:
          _parseDouble(
            pick('net') ?? pick('NET') ?? pick('balance') ?? pick('BALANCE'),
          ) ??
          0,
      // عدد الحركات يصل بأربعة أسماء حسب المصدر: movements في الغلاف، وMOV_COUNT/CNT
      // من aliases تجميع ENTRY_SUB مباشرة
      movements:
          _parseInt(
            pick('movements') ??
                pick('MOV_COUNT') ??
                pick('mov_count') ??
                pick('CNT'),
          ) ??
          0,
      storedBalance: d('stored_balance', 'BALANCE'),
      limitedBalance: _parseDouble(pick('limited_balance')),
      stopped: pick('stopping_acc') != null && pick('stopping_acc') != 0,
      accDate: pick('acc_date')?.toString(),
      parentPath: ArabicEncodingUtils.fix(pick('parent_path')),
      // الخادم يشتقها من الخانة الرابعة؛ احتياطٌ محلي لنفس القاعدة إن وصل رقم
      // دون cur_no (مصادر أقدم) — القراءة الحرفية للرقم، لا إعادة توليد له.
      curNo:
          _parseInt(pick('cur_no')) ?? _currencyFromNumber(_parseInt(pick('acc_no'))),
    );
  }

  /// اشتقاق العملة من رقم الحساب: الخانة الرابعة من اليسار (251|2|0016 → 2).
  /// Mirror of the server's currencyOfChartNumber for sources that send only the
  /// number — a positional read of an existing number, never a new numbering rule.
  static int? _currencyFromNumber(int? accNo) {
    if (accNo == null) return null;
    final digits = accNo.toString();
    if (digits.length < 4) return null;
    final cur = int.tryParse(digits[3]);
    return (cur != null && cur > 0) ? cur : null;
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
