import 'dart:ui' show Color;

import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';

/// صفوف الشجرة المسطّحة — الحالة الوحيدة التي يحتاجها العرض.
/// The flattened row list: one `ListView.builder` over these rows instead of a nested
/// `Column` per node, which is what made 21k nodes unusable. The tree stays a tree in
/// the provider; only the render model is flat.
class AccountTreeRow {
  final AccountTreeRowKind kind;

  /// عمود المسافة البادئة (0 = جذر) — يُستخدم لرسم الخط الإرشادي Level guide indent.
  final int depth;

  /// العقدة الهيكلية أو الورقة المالية — أحدهما فقط غير null.
  final AccountTreeNode? node;
  final AccountLeafModel? leaf;

  /// معرّف الأب لعقدة «المزيد»/«جارٍ التحميل» / the host node for paging rows.
  final String? hostId;

  const AccountTreeRow._({
    required this.kind,
    required this.depth,
    this.node,
    this.leaf,
    this.hostId,
  });

  factory AccountTreeRow.structural({
    required AccountTreeNode node,
    required int depth,
  }) => AccountTreeRow._(
    kind: AccountTreeRowKind.structural,
    depth: depth,
    node: node,
    hostId: node.id,
  );

  factory AccountTreeRow.leaf({
    required AccountLeafModel leaf,
    required int depth,
    required String hostId,
  }) => AccountTreeRow._(
    kind: AccountTreeRowKind.leaf,
    depth: depth,
    leaf: leaf,
    hostId: hostId,
  );

  factory AccountTreeRow.loading({required String hostId, required int depth}) =>
      AccountTreeRow._(
        kind: AccountTreeRowKind.loading,
        depth: depth,
        hostId: hostId,
      );

  factory AccountTreeRow.loadMore({required String hostId, required int depth}) =>
      AccountTreeRow._(
        kind: AccountTreeRowKind.loadMore,
        depth: depth,
        hostId: hostId,
      );

  factory AccountTreeRow.rowError({required String hostId, required int depth}) =>
      AccountTreeRow._(
        kind: AccountTreeRowKind.rowError,
        depth: depth,
        hostId: hostId,
      );

  /// رقم السطر للعرض: رقم الحساب المالي أو رقم الهيكل/المجموعة.
  String get code =>
      node != null
      ? _nodeCode(node!)
      : (leaf?.accNo.toString() ?? '');

  String get title => node?.name ?? leaf?.accName ?? '';

  double? get balance => node?.balance ?? leaf?.net;

  double? get debit => node?.debit ?? leaf?.debit;

  double? get credit => node?.credit ?? leaf?.credit;

  String get levelLabel =>
      node != null ? levelBadgeLabel(node!.level) : 'حساب';

  Color get levelColor =>
      node != null ? levelBadgeColor(node!.level) : AppColors.secondary;

  static String _nodeCode(AccountTreeNode n) {
    switch (n.level) {
      case 'group':
        return 'G${n.groupId ?? ''}';
      case 'sub':
        return '${n.accPart ?? ''}';
      case 'main':
        return '${n.accSub ?? ''}';
      case 'chart':
        return '${n.accNo ?? ''}';
      default:
        return '${n.accNo ?? ''}';
    }
  }
}

enum AccountTreeRowKind { structural, leaf, loading, loadMore, rowError }

/// فلاتر العرض — كلها client-side على الصفوف المحمّلة، ما عدا البحث فهو خادمي.
/// Display filters. Everything except search is applied to already-loaded rows:
/// search hits the server because 20k accounts are never all in memory.
class AccountTreeFilters {
  final String search;
  final int? sectionAccNo;

  /// أقصى مستوى معروض: 0 أقسام … 3 مجموعات، وnull = بلا سقف.
  final int? maxLevel;
  final bool hideZeroBalances;
  final bool showStopped;
  final bool sortBalanceDesc;

  const AccountTreeFilters({
    this.search = '',
    this.sectionAccNo,
    this.maxLevel,
    this.hideZeroBalances = false,
    this.showStopped = true,
    this.sortBalanceDesc = false,
  });

  AccountTreeFilters copyWith({
    String? search,
    Object? sectionAccNo = _unset,
    Object? maxLevel = _unset,
    bool? hideZeroBalances,
    bool? showStopped,
    bool? sortBalanceDesc,
  }) {
    return AccountTreeFilters(
      search: search ?? this.search,
      sectionAccNo: sectionAccNo == _unset
          ? this.sectionAccNo
          : sectionAccNo as int?,
      maxLevel: maxLevel == _unset ? this.maxLevel : maxLevel as int?,
      hideZeroBalances: hideZeroBalances ?? this.hideZeroBalances,
      showStopped: showStopped ?? this.showStopped,
      sortBalanceDesc: sortBalanceDesc ?? this.sortBalanceDesc,
    );
  }

  static const Object _unset = Object();

  bool get hasActiveFilter =>
      search.isNotEmpty ||
      sectionAccNo != null ||
      maxLevel != null ||
      hideZeroBalances ||
      !showStopped;
}

/// تسطيح الشجرة مع الأبناء المحمّلين كسولاً وتطبيق الفلاتر.
/// Flattens the skeleton plus lazily-loaded leaves and applies the display filters.
/// Expanded nodes with no cache yet still emit their host row, so the spinner row
/// (`loading`) appears while the first page is in flight.
List<AccountTreeRow> flattenAccountTree({
  required List<AccountTreeNode> tree,
  required Set<String> expanded,
  required Map<String, List<AccountLeafModel>> childrenCache,
  required Set<String> loadingChildren,
  required Map<String, bool> childHasMore,
  required AccountTreeFilters filters,
}) {
  final rows = <AccountTreeRow>[];
  final query = filters.search.trim().toLowerCase();

  bool structuralMatches(AccountTreeNode node) {
    if (filters.sectionAccNo != null && _sectionOf(node) != filters.sectionAccNo) {
      return false;
    }
    if (filters.hideZeroBalances && (node.balance ?? 0).abs() < 0.005) {
      return false;
    }
    if (query.isNotEmpty) {
      // الفلترة النصية على الهيكل المحمّل فقط — البحث الشامل يذهب للنتائج الخادمية
      // Text filter over loaded structure only; deep search uses the server results.
      if (!node.name.toLowerCase().contains(query) &&
          !node.codePath.toLowerCase().contains(query) &&
          !node.children.any((c) => structuralMatches(c))) {
        return false;
      }
    }
    return true;
  }

  void walk(AccountTreeNode node, int depth) {
    if (filters.maxLevel != null && depth > filters.maxLevel!) return;
    if (!structuralMatches(node)) return;

    rows.add(AccountTreeRow.structural(node: node, depth: depth));
    if (!expanded.contains(node.id)) return;

    for (final child in node.children) {
      walk(child, depth + 1);
    }

    final host = _isFinancialHost(node) ? node : null;
    if (host == null) return;

    final leaves = childrenCache[host.id];
    if (leaves == null) {
      if (loadingChildren.contains(host.id)) {
        rows.add(AccountTreeRow.loading(hostId: host.id, depth: depth + 1));
      } else if (!_nothingToLoad(host)) {
        // عقدة مفتوحة بلا كاش: سطر فارغ يكفي، والضغط على التوسيع يجلب الصفحة
        rows.add(AccountTreeRow.loadMore(hostId: host.id, depth: depth + 1));
      }
      return;
    }

    var visible = leaves;
    if (!filters.showStopped) {
      visible = visible.where((l) => !l.stopped).toList();
    }
    if (filters.hideZeroBalances) {
      visible = visible.where((l) => l.net.abs() >= 0.005).toList();
    }
    if (query.isNotEmpty) {
      visible = visible
          .where(
            (l) =>
                l.accName.toLowerCase().contains(query) ||
                l.accNo.toString().contains(query),
          )
          .toList();
    }
    if (filters.sortBalanceDesc) {
      visible = [...visible]..sort((a, b) => b.net.abs().compareTo(a.net.abs()));
    }

    for (final leaf in visible) {
      rows.add(
        AccountTreeRow.leaf(leaf: leaf, depth: depth + 1, hostId: host.id),
      );
    }

    if (loadingChildren.contains(host.id)) {
      rows.add(AccountTreeRow.loading(hostId: host.id, depth: depth + 1));
    } else if (childHasMore[host.id] == true) {
      rows.add(AccountTreeRow.loadMore(hostId: host.id, depth: depth + 1));
    }
  }

  for (final node in tree) {
    walk(node, 0);
  }
  return rows;
}

/// عقدة مضيفة للأبناء الماليين: المجموعة دائماً، والجزئي إن له حسابات مباشرة.
bool _isFinancialHost(AccountTreeNode node) =>
    node.level == 'group' ||
    (node.level == 'sub' && (node.directCount ?? 0) > 0);

/// مجموعة معلوم أنها بلا حسابات — لا حاجة لسطر «تحميل» لها.
bool _nothingToLoad(AccountTreeNode node) =>
    node.level == 'group' && (node.accountCount ?? 0) == 0;

/// قسم العقدة (رقم ACCOUNT الذي تنتمي إليه) لفلتر «القسم».
int? _sectionOf(AccountTreeNode node) {
  if (node.level == 'account') return node.accNo;
  final first = node.codePath.split('/').first.trim();
  return int.tryParse(first);
}

/// شارات المستوى — ألوان ثابتة تجعل مستوى السطر مقروءاً بلا قراءة النص.
String levelBadgeLabel(String level) => switch (level) {
  'account' => 'قسم',
  'main' => 'فرعي',
  'sub' => 'جزئي',
  'group' => 'مجموعة',
  'chart' => 'حساب',
  _ => level,
};

Color levelBadgeColor(String level) => switch (level) {
  'account' => AppColors.primary,
  'main' => const Color(0xFF4F46E5),
  'sub' => AppColors.accentLight,
  'group' => AppColors.warning,
  'chart' => AppColors.secondary,
  _ => AppColors.textMuted,
};

/// تنسيق أرقام بمجمّع آلاف وخانتين عشريتين — بلا اعتماد على intl.
/// Amount formatting without `intl`: grouping separator + two decimals, sign kept.
String formatTreeAmount(num value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    grouped.write(digits[i]);
    final remaining = digits.length - 1 - i;
    if (remaining > 0 && remaining % 3 == 0) grouped.write(',');
  }
  return '${value.isNegative ? '-' : ''}$grouped.${parts.last}';
}
