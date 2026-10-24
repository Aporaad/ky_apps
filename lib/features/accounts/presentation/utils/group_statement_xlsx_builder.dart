import 'package:excel/excel.dart';

import '../../data/models/account_group_statement_model.dart';

/// يبني ملف XLSX لميزان مراجعة مجموعة حسابات جزئية — نفس أعمدة الجدول في الشاشة.
/// Builds a real .xlsx for the group trial balance (GET /accounts/group-statement):
/// one sheet mirroring the on-screen columns (local + foreign DR/CR, balance,
/// movement balance) with a totals row, and a small «ملخص» sheet with the scope,
/// period and headline totals.
///
/// الأرقام تُكتب خلايا رقمية لا نصوصاً، فيستطيع المحاسب أن يجمع عليها مباشرة في
/// Excel بدل أن يستخرج نصاً منسّقاً بالفواصل.
/// Values are written as numeric cells, not thousands-formatted strings, so the
/// accountant can sum them in Excel without unformatting text first.
List<int> buildGroupStatementXlsx({required TrialBalanceReport report}) {
  final excel = Excel.createExcel();
  final sheet = excel[kBalanceSheet];
  final summary = excel[kSummarySheet];
  excel.delete('Sheet1');

  const headers = [
    'رقم الحساب',
    'اسم الحساب',
    'العملة',
    'مدين (محلي)',
    'دائن (محلي)',
    'مدين (أجنبي)',
    'دائن (أجنبي)',
    'الرصيد',
    'رصيد الحركة',
  ];

  sheet.appendRow([for (final h in headers) TextCellValue(h)]);
  for (var i = 0; i < headers.length; i++) {
    sheet.setColumnWidth(i, i == 1 ? 44 : 16);
    _styleCell(sheet, i, 0, cellStyle: _headerStyle);
  }

  for (final row in report.rows) {
    sheet.appendRow([
      TextCellValue(row.accNo.toString()),
      TextCellValue(row.accName),
      TextCellValue(row.curCode),
      DoubleCellValue(row.localDebit),
      DoubleCellValue(row.localCredit),
      DoubleCellValue(row.foreignDebit),
      DoubleCellValue(row.foreignCredit),
      DoubleCellValue(row.balance),
      DoubleCellValue(row.currentBalance),
    ]);
  }

  final totalsRow = sheet.maxRows;
  sheet.appendRow([
    TextCellValue('الإجمالي'),
    TextCellValue('${report.rows.length} حساب'),
    TextCellValue(''),
    DoubleCellValue(report.totals.localDebit),
    DoubleCellValue(report.totals.localCredit),
    DoubleCellValue(report.totals.foreignDebit),
    DoubleCellValue(report.totals.foreignCredit),
    DoubleCellValue(report.totals.balance),
    DoubleCellValue(0),
  ]);
  for (var c = 0; c < headers.length; c++) {
    _styleCell(sheet, c, totalsRow, cellStyle: _totalsStyle);
  }

  // ─── ورقة الملخص ────────────────────────────────────────────────────────────
  summary.setColumnWidth(0, 26);
  summary.setColumnWidth(1, 34);

  summary.appendRow([TextCellValue('ميزان مراجعة مجموعة حسابات جزئية')]);
  _styleCell(summary, 0, 0, cellStyle: _titleStyle);
  summary.appendRow([TextCellValue('النطاق'), TextCellValue(report.scopeLabel)]);
  summary.appendRow([TextCellValue('مستوى النطاق'), TextCellValue(report.scopeLevel)]);
  summary.appendRow([
    TextCellValue('الفترة'),
    TextCellValue(
      report.fromDate != null && report.toDate != null
          ? '${report.fromDate} → ${report.toDate}'
          : 'كل الحركات (بدون فترة)',
    ),
  ]);
  summary.appendRow([TextCellValue('تاريخ التقرير'), TextCellValue(report.asOfDate)]);
  summary.appendRow([TextCellValue('عدد الحسابات'), IntCellValue(report.rows.length)]);
  summary.appendRow([TextCellValue('')]);

  final totalsStart = summary.maxRows;
  summary.appendRow([
    TextCellValue('إجمالي مدين (محلي)'),
    DoubleCellValue(report.totals.localDebit),
  ]);
  summary.appendRow([
    TextCellValue('إجمالي دائن (محلي)'),
    DoubleCellValue(report.totals.localCredit),
  ]);
  summary.appendRow([
    TextCellValue('إجمالي مدين (أجنبي)'),
    DoubleCellValue(report.totals.foreignDebit),
  ]);
  summary.appendRow([
    TextCellValue('إجمالي دائن (أجنبي)'),
    DoubleCellValue(report.totals.foreignCredit),
  ]);
  summary.appendRow([TextCellValue('صافي الرصيد'), DoubleCellValue(report.totals.balance)]);
  for (var r = totalsStart; r < summary.maxRows; r++) {
    _styleCell(summary, 0, r, cellStyle: _boldStyle);
    _styleCell(summary, 1, r, cellStyle: _boldStyle);
  }

  final bytes = excel.save(fileName: 'group-statement.xlsx');
  return bytes ?? const <int>[];
}

const String kBalanceSheet = 'الميزان';
const String kSummarySheet = 'ملخص';

String groupStatementXlsxFileName([DateTime? now]) {
  final d = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'group-statement-${d.year}${two(d.month)}${two(d.day)}-${two(d.hour)}${two(d.minute)}.xlsx';
}

// AARRGGBB بلا '#'، وألوان مطابقة لرأس الجدول على الشاشة.
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

final CellStyle _totalsStyle = CellStyle(
  bold: true,
  backgroundColorHex: ExcelColor.fromHexString('FFF1F5F9'),
);

/// appendRow لا يقبل تنسيقاً في excel 4.0.6، فتُعاد كتابة الخلية بقيمتها مع التنسيق.
void _styleCell(Sheet sheet, int column, int row, {required CellStyle cellStyle}) {
  final index = CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row);
  final cell = sheet.cell(index);
  sheet.updateCell(index, cell.value, cellStyle: cellStyle);
}
