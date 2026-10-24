import 'package:excel/excel.dart';

import '../utils/account_tree_flatten.dart';

/// يبني ملف XLSX حقيقي للشجرة المحاسبية: ورقة «الشجرة» بنفس أعمدة الشاشة + مسار الأب
/// وعدد الحركات، وورقة «ملخص» بعدّاد المستويات ومجاميع مدين/دائن/الرصيد.
/// Builds a real .xlsx (Dart-native `excel` package, so Arabic survives without any
/// platform plugin): a "الشجرة" sheet mirroring the on-screen rows plus parent path
/// and movement counts, and a "ملخص" sheet with per-level counts and DR/CR/net totals.
///
/// التصدير يطابق المعروض: الصفوف المسطّحة بعد الفلاتر وتوسيع العقد، والأرصدة هي
/// المجمّعة من ENTRY_SUB لا عمود BALANCE المخزّن.
///
/// ملاحظة عن الحزمة: `appendRow` لا يقبل تنسيقاً للخلايا في excel 4.0.6، فالرأس
/// يُكتب أولاً ثم تُطبَّق `CellStyle` عبر `updateCell` بـ `CellIndex` — وإلا يظهر
/// الملف بلا تمييز للعناوين ويخلط المستخدم الأعمدة.
List<int> buildAccountTreeXlsx({
  required List<AccountTreeRow> rows,
  String? periodLabel,
}) {
  final excel = Excel.createExcel();
  final tree = excel[kTreeSheet];
  final summary = excel[kSummarySheet];

  // الورقة الافتراضية التي تنشئها الحزمة فارغة — تُحذف كي لا يفتح المستخدم صفحة عبث
  excel.delete('Sheet1');

  const headers = [
    'الرقم',
    'الاسم',
    'المستوى',
    'مسار الأب',
    'مدين',
    'دائن',
    'الرصيد',
    'عدد الحركات',
    'الرصيد المخزّن',
  ];

  tree.appendRow([for (final h in headers) TextCellValue(h)]);
  for (var i = 0; i < headers.length; i++) {
    tree.setColumnWidth(i, i == 1 ? 44 : (i == 3 ? 34 : 16));
    tree.updateCell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      TextCellValue(headers[i]),
      cellStyle: _headerStyle,
    );
  }

  var totalDebit = 0.0;
  var totalCredit = 0.0;
  var totalNet = 0.0;
  final levelCounts = <String, int>{};
  var leafCount = 0;
  var structuralCount = 0;

  for (final row in rows) {
    if (row.kind != AccountTreeRowKind.structural &&
        row.kind != AccountTreeRowKind.leaf) {
      continue;
    }

    final debit = row.debit ?? 0;
    final credit = row.credit ?? 0;
    final net = row.balance ?? 0;
    final level = row.levelLabel;

    // المجاميع تُحسب من الأوراق فقط حتى لا يتكرر رصيد الأب مع أبنائه
    if (row.kind == AccountTreeRowKind.leaf) {
      totalDebit += debit;
      totalCredit += credit;
      totalNet += net;
      leafCount++;
    } else {
      structuralCount++;
    }
    levelCounts[level] = (levelCounts[level] ?? 0) + 1;

    tree.appendRow([
      TextCellValue(row.code),
      TextCellValue('${'   ' * row.depth}${row.title}'),
      TextCellValue(level),
      TextCellValue(row.node?.parentPath ?? row.leaf?.parentPath ?? ''),
      DoubleCellValue(debit),
      DoubleCellValue(credit),
      DoubleCellValue(net),
      IntCellValue(row.node?.movements ?? row.leaf?.movements ?? 0),
      TextCellValue('${row.node?.storedBalance ?? row.leaf?.storedBalance ?? 0}'),
    ]);
  }

  // ─── ورقة الملخص ────────────────────────────────────────────────────────────
  summary.setColumnWidth(0, 26);
  summary.setColumnWidth(1, 22);
  summary.setColumnWidth(2, 26);
  summary.setColumnWidth(3, 22);

  summary.appendRow([TextCellValue('ملخص الشجرة المحاسبية')]);
  _styleCell(summary, 0, 0, cellStyle: _titleStyle);
  if (periodLabel != null) {
    summary.appendRow([TextCellValue('فترة الأرصدة'), TextCellValue(periodLabel)]);
  }
  summary.appendRow([
    TextCellValue('تاريخ التوليد'),
    TextCellValue(
      DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
    ),
  ]);
  summary.appendRow([
    TextCellValue('عدد الأسطر المحمّلة'),
    IntCellValue(rows.length),
    TextCellValue('عدد الحسابات المالية'),
    IntCellValue(leafCount),
  ]);
  summary.appendRow([
    TextCellValue('عدد العقد الهيكلية'),
    IntCellValue(structuralCount),
    TextCellValue(''),
    TextCellValue(''),
  ]);
  summary.appendRow([TextCellValue('')]);

  // موقع سطر الترويسة يتزحزح مع/بدون سطر الفترة — يُؤخذ من maxRows لا من ثابت.
  final levelHeaderRow = summary.maxRows;
  summary.appendRow([TextCellValue('المستوى'), TextCellValue('العدد')]);
  _styleCell(summary, 0, levelHeaderRow, cellStyle: _headerStyle);
  _styleCell(summary, 1, levelHeaderRow, cellStyle: _headerStyle);
  levelCounts.forEach((level, count) {
    summary.appendRow([TextCellValue(level), IntCellValue(count)]);
  });

  summary.appendRow([TextCellValue('')]);
  final totalsStart = summary.maxRows;
  summary.appendRow([TextCellValue('إجمالي مدين الحسابات'), DoubleCellValue(totalDebit)]);
  summary.appendRow([TextCellValue('إجمالي دائن الحسابات'), DoubleCellValue(totalCredit)]);
  summary.appendRow([TextCellValue('صافي الرصيد'), DoubleCellValue(totalNet)]);
  for (var r = totalsStart; r < summary.maxRows; r++) {
    _styleCell(summary, 0, r, cellStyle: _boldStyle);
    _styleCell(summary, 1, r, cellStyle: _boldStyle);
  }

  final bytes = excel.save(fileName: 'chart-of-accounts.xlsx');
  return bytes ?? const <int>[];
}

const String kTreeSheet = 'الشجرة';
const String kSummarySheet = 'ملخص';

// ألوان الرأس مطابقة لـ AppColors (primary / surfaceSubtle) ليطابق الملف الشاشة.
// Excel wants AARRGGBB without '#'.
final CellStyle _headerStyle = CellStyle(
  bold: true,
  backgroundColorHex: ExcelColor.fromHexString('FFE2E8F0'),
  fontColorHex: ExcelColor.fromHexString('FF1D4ED8'),
);

final CellStyle _titleStyle = CellStyle(
  bold: true,
  fontSize: 14,
  fontColorHex: ExcelColor.fromHexString('FF1D4ED8'),
);

final CellStyle _boldStyle = CellStyle(bold: true);

/// إعادة كتابة الخلية بنفس قيمتها مع تنسيق — الحزمة لا توفّر setter للتنسيق فقط.
void _styleCell(Sheet sheet, int column, int row, {required CellStyle cellStyle}) {
  final index = CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row);
  final cell = sheet.cell(index);
  sheet.updateCell(index, cell.value, cellStyle: cellStyle);
}

/// اسم ملف مؤرّخ: chart-of-accounts-20250612-1430.xlsx
String accountTreeXlsxFileName([DateTime? now]) {
  final d = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'chart-of-accounts-${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}.xlsx';
}
