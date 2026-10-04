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
class AccountTreeNode {
  final String id;
  final String name;
  final String level; // account | main | sub | group | chart
  final int? accNo;
  final int? accSub;
  final int? accPart;
  final int? groupId;
  final double? balance;
  final bool? isStoppped;
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
    this.isStoppped,
    this.children = const [],
  });

  factory AccountTreeNode.fromJson(Map<String, dynamic> json) {
    final childrenList = (json['children'] as List? ?? [])
        .map((c) => AccountTreeNode.fromJson(c as Map<String, dynamic>))
        .toList();

    return AccountTreeNode(
      id: json['id']?.toString() ?? '',
      name: ArabicEncodingUtils.fix(json['name']),
      level: json['level']?.toString() ?? 'chart',
      accNo: _parseInt(json['acc_no']),
      accSub: _parseInt(json['acc_sub']),
      accPart: _parseInt(json['acc_part']),
      groupId: _parseInt(json['group_id']),
      balance: _parseDouble(json['balance']),
      isStoppped: json['stopping_acc'] != null && json['stopping_acc'] != 0,
      children: childrenList,
    );
  }

  bool get isLeaf => children.isEmpty;

  /// البحث في الشجرة
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (name.toLowerCase().contains(q)) return true;
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
      isStoppped: isStoppped,
      children: filteredChildren,
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
