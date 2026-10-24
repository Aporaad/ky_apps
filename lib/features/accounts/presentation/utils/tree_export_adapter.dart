import '../../data/models/account_model.dart';
import '../../data/models/tree_export_row_model.dart';
import 'account_tree_flatten.dart';

/// تحويل صفوف التصدير القادمة من الخادم إلى صفوف العرض التي تبني المستندات.
/// Adapts server export rows to the [AccountTreeRow] shape the PDF/XLSX builders eat.
///
/// لماذا التحويل لا مُولّد جديد؟ builder المستندات يقرأ `row.title / code / debit /
/// balance / levelLabel / parentPath` من `AccountTreeNode` أو `AccountLeafModel`.
/// الإبقاء على نوع واحد للصفوف يعني أن المطبوعة والشاشة ترسمان من نفس المنطق، فلا
/// تتباعدان — وهو الخطأ الذي جعل التصدير القديم يطبع ما تيسّر من الشاشة.
///
/// One row type for both surfaces: keeping a second document model would let print
/// and screen drift apart again, which is exactly the bug being fixed here.
AccountTreeRow treeExportRowToDisplay(TreeExportRow row) {
  if (row.isLedger) {
    return AccountTreeRow.leaf(
      depth: row.depth,
      hostId: 'export_${row.rootAccNo ?? 0}',
      leaf: AccountLeafModel(
        accNo: row.accNo ?? 0,
        accName: row.name,
        groupId: row.groupId,
        seq: row.seq,
        debit: row.debit,
        credit: row.credit,
        net: row.balance,
        movements: row.movements,
        storedBalance: row.storedBalance ?? 0,
        limitedBalance: row.limitedBalance,
        stopped: row.isStopped,
        accDate: row.accDate,
        parentPath: row.parentPath,
        curNo: row.curNo,
      ),
    );
  }

  // مستوى هيكلي: الحساب الرئيسي/الفرعي/الجزئي/المجموعة. `children` فارغ عمداً —
  // المطبوعة مسطّحة بالفعل، ولا توسيع كسول فيها.
  // Structural level. `children` is empty on purpose: the document is already flat,
  // so there is no lazy expansion to hang off it.
  return AccountTreeRow.structural(
    depth: row.depth,
    node: AccountTreeNode(
      id: 'export_${row.level}_${row.code}',
      name: row.name,
      level: row.level,
      accNo: row.level == 'chart' ? row.accNo : (row.accNo ?? row.rootAccNo),
      accSub: row.accSub,
      accPart: row.accPart,
      groupId: row.groupId,
      balance: row.balance,
      debit: row.debit,
      credit: row.credit,
      movements: row.movements,
      isStoppped: row.isStopped ? true : null,
      parentPath: row.parentPath,
      codePath: row.codePath,
      storedBalance: row.storedBalance,
      curNo: row.curNo,
      childrenCount: row.childrenCount,
      accountCount: row.accountCount,
    ),
  );
}

/// تحويل الكتلة كلها — مع إسقاط أي صف بلا اسم حتى لا يطبع المستند سطراً فارغاً.
List<AccountTreeRow> treeExportRowsToDisplay(List<TreeExportRow> rows) => [
  for (final row in rows)
    if (row.name.isNotEmpty) treeExportRowToDisplay(row),
];

/// ملخص نصّي يُطبع أسفل المستند: ماذا يحتوي هذا الملف تحديداً.
/// A one-line scope statement for the document footer, taken from the server's own
/// `meta.level_counts` when available — so a printed page states its contents rather
/// than making the reader guess from what happened to be expanded on screen.
String describeTreeExport({
  required TreeExportScope scope,
  required int totalRows,
  required Map<String, int> levelCounts,
}) {
  final parts = <String>[
    for (final level in TreeExportLevel.values)
      if (levelCounts[level.code] != null)
        '${level.labelAr}: ${levelCounts[level.code]}',
  ];
  final head = parts.isEmpty ? scope.describe() : '${scope.describe()} • ${parts.join(' • ')}';
  return '$head • إجمالي الصفوف: $totalRows';
}
