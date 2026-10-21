import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../data/models/account_group_statement_model.dart';
import 'account_statement_report_table.dart';

/// جدول "كشف حساب مجموعة حسابات جزئية" (ميزان المراجعة) - ترويسة ثنائية
/// الطبقات تطابق TRIAL_BALANCE_REPORT.pdf: عمودان مجمّعان "عملة محلية"
/// و"عملة أجنبية" فوق كل منهما "مدين/دائن"، بجانب رقم الحساب واسمها ورمز
/// العملة والرصيد، مع سطر إجمالي عام أسفل الجدول.
class AccountGroupStatementReportTable extends StatelessWidget {
  final TrialBalanceReport report;

  const AccountGroupStatementReportTable({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = statementTableMetrics(constraints.maxWidth);
        final headerFontSize = m.header * 0.9;

        return Table(
          border: TableBorder.all(
            color: kStatementBorderColor,
            width: 1,
            style: BorderStyle.solid,
          ),
          columnWidths: const {
            0: FlexColumnWidth(1.2), // رقم الحساب
            1: FlexColumnWidth(3.2), // إسم الحساب
            2: FlexColumnWidth(0.8), // العملة
            3: FlexColumnWidth(1.4), // مدين محلي
            4: FlexColumnWidth(1.4), // دائن محلي
            5: FlexColumnWidth(1.4), // مدين أجنبي
            6: FlexColumnWidth(1.4), // دائن أجنبي
            7: FlexColumnWidth(1.5), // الرصيد
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // الطبقة الأولى: التجميع "عملة محلية" / "عملة أجنبية"
            TableRow(
              decoration: const BoxDecoration(color: kStatementHeaderBgColor),
              children: [
                tableHeaderCell('رقم الحساب', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('إسم الحساب', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('العملة', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('عملة محلية', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                const SizedBox(height: 4),
                tableHeaderCell('عملة أجنبية', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                const SizedBox(height: 4),
                tableHeaderCell('الرصيد', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
              ],
            ),
            // الطبقة الثانية: مدين/دائن لكل عملة
            TableRow(
              decoration: const BoxDecoration(color: kStatementHeaderBgColor),
              children: [
                tableHeaderCell('', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('مدين', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('دائن', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('مدين', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('دائن', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
                tableHeaderCell('', fontSize: headerFontSize, vPad: m.vPad, hPad: m.hPad),
              ],
            ),

            ...report.rows.map((row) {
              return TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  tableDataCell(row.accNo.toString(), fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(
                    ArabicEncodingUtils.fix(row.accName),
                    isCenter: false,
                    fontSize: m.data,
                    vPad: m.vPad,
                    hPad: m.hPad,
                  ),
                  tableDataCell(row.curCode, fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
                  tableDataCell(formatStatementAmount(row.localDebit), fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(row.localCredit), fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(row.foreignDebit), fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(row.foreignCredit), fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(row.balance), isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                ],
              );
            }),

            // سطر الإجمالي العام
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
              children: [
                tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
                tableDataCell(
                  'إجمالي حسابات ${report.asOfDate}',
                  isCenter: true,
                  isBold: true,
                  fontSize: m.data,
                  vPad: m.vPad,
                  hPad: m.hPad,
                ),
                tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
                tableDataCell(formatStatementAmount(report.totals.localDebit), isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                tableDataCell(formatStatementAmount(report.totals.localCredit), isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                tableDataCell(formatStatementAmount(report.totals.foreignDebit), isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                tableDataCell(formatStatementAmount(report.totals.foreignCredit), isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                tableDataCell(
                  formatStatementAmount(report.totals.balance),
                  isBold: true,
                  textColor: const Color(0xFFDC2626),
                  fontSize: m.data,
                  vPad: m.vPad,
                  hPad: m.hPad,
                  fitBox: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
