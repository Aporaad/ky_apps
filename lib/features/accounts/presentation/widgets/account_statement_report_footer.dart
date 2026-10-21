import 'package:flutter/material.dart';
import 'account_statement_report_table.dart';

/// تذييل كشف الحساب المالي — إجماليات + خانة التوقيعات + إخلاء المسؤولية
/// + ترقيم الصفحة، مطابقة لتذييل acc_report.pdf. يُبنى كـ Widget مستقل ليُستخدم
/// في الشاشة نفسها وفي مولّد الـ PDF بنفس التنسيق.
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
    final now = DateTime.now();
        final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 5, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── صناديق الإجماليات ──
          // صندوق مرن بعرض 200–260: لا يفيض على الشاشات الضيقة عند تكبير الخط.
          // Flexible 200–260px totals box — never overflows on narrow screens.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Flexible(child: _buildTotalsBox()),
            ],
          ),

          const SizedBox(height: 20),

          // ── خانة التوقيعات ──
          // ثلاث خانات Expanded بدل ثلاث خانات ثابتة 120px (كانت تفيض 44px
          // عند 1.25×) — كل خانة تتمدد بالتساوي ضمن العرض المتاح.
          // Three Expanded slots instead of three fixed 120px slots (which
          // overflowed 44px at 1.25× text scale) — equal share of the width.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(child: _SignatureSlot(label: 'توقيع المحاسب')),
              SizedBox(width: 8),
              Expanded(child: _SignatureSlot(label: 'توقيع أمين الصندوق')),
              SizedBox(width: 8),
              Expanded(child: _SignatureSlot(label: 'توقيع المدير')),
            ],
          ),

          const SizedBox(height: 12),

          // ── إخلاء المسؤولية + ترقيم الصفحة ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'يجب مراجعة هذا الكشف خلال 15 يوماً من تاريخ إصداره، وما بعد ذلك يُعتبر معتمداً.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),              
            ],
          ),
          Text(
                'توقيت الإصدار: $timestamp',
                style: const TextStyle(
                  fontSize: 7,
                  color: Colors.black54,
                ),
              )
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

class _SignatureSlot extends StatelessWidget {
  final String label;

  const _SignatureSlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // خط التوقيع يتمدد بعرض الخانة كاملة بدل عرض ثابت 120px
        // The signature line stretches to the slot's full width.
        Container(
          width: double.infinity,
          height: 1,
          color: Colors.black54,
        ),
        const SizedBox(height: 4),
        // تصغير تلقائي لملصق التوقيع عند تكبير الخط حتى لا يفيض أبداً
        // Auto-shrink the label under large text scales — never overflows.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
