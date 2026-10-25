import 'package:flutter/material.dart';
import 'account_statement_report_table.dart';

/// تذييل كشف الحساب المالي — إجماليات فقط، مطابقة لتذييل acc_report.pdf.
/// يُبنى كـ Widget مستقل ليُستخدم في الشاشة نفسها وفي مولّد الـ PDF بنفس التنسيق.
/// Statement footer — totals box only. Signature slots and the disclaimer band
/// were removed by design (decision recorded in commit ec37748); restore them
/// from git history if the printed format demands it again.
class AccountStatementReportFooter extends StatelessWidget {
  final double openingBalance;
  final double totalDebit;
  final double totalCredit;
  final double finalBalance;

  const AccountStatementReportFooter({
    super.key,
    required this.openingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.finalBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 5, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── صناديق الإجماليات ──
          // صندوق مرن بعرض 100–160: لا يفيض على الشاشات الضيقة عند تكبير الخط.
          // Flexible 100–160px totals box — never overflows on narrow screens.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Flexible(child: _buildTotalsBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsBox() {
    return Container(
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 160),
      decoration: BoxDecoration(
        border: Border.all(color: kStatementBorderColor, width: 1),
      ),
      child: Column(
        children: [
          _totalsRow('الرصيد الافتتاحي', formatStatementAmount(openingBalance),
              highlight: false),
          _divider(),
          _totalsRow('إجمالي المدين', formatStatementAmount(totalDebit), highlight: false),
          _divider(),
          _totalsRow('إجمالي الدائن', formatStatementAmount(totalCredit), highlight: false),
          _divider(),
          _totalsRow('الرصيد النهائي', formatStatementAmount(finalBalance), highlight: true),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: kStatementBorderColor);

  Widget _totalsRow(String label, String value, {required bool highlight}) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            color: highlight ? kStatementHeaderBgColor : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(width: 1, height: 30, color: kStatementBorderColor),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: highlight ? 8.5 : 8,
                fontWeight: FontWeight.w900,
                color: highlight ? const Color(0xFFDC2626) : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
