import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/tailoring_parse.dart';

/// بطاقة فاتورة في قائمة الاختيار — ثلاثة أعمدة ثابتة العرض لا تتجاوز أي مساحة
/// A bill card in the selection list — three fixed-width zones that never overflow.
///
/// الشكوى كانت تجاوزاً بسيطاً (`RenderFlex overflowed by 2.4–7.5 px`) واسم عميل مقصوصاً.
/// الحل: منطقة يمين بعرض صريح لكل عناصرها، واسم العميل داخل `FittedBox` يصغّر خطّه ليتّسع
/// الشطر كله في سطر واحد (لا قصّ ولا نقاط)، وسطر البيانات يلتفّ وحده عند الحاجة.
/// The reported defect was a small overflow (2.4–7.5 px) and a clipped customer name. The fix:
/// an explicitly sized right zone for all its items, and the customer name inside a `FittedBox`
/// that shrinks the font so the whole line fits on one row (no ellipsis), while the meta line
/// wraps on its own when needed.
class BillListTile extends StatelessWidget {
  final CuttingBillSummary bill;
  final VoidCallback onTap;

  /// هل تُعرض خانات المال؟ (صلاحية `tailoring.payments_view` غير مطلوبة هنا لأن الصافي
  /// من الـ VIEW لا من SALES_BILL، لكن الشاشة المضيفة تُمرّر الرأي).
  /// Whether money fields are shown; the host screen passes its own decision.
  final bool showMoney;

  const BillListTile({
    super.key,
    required this.bill,
    required this.onTap,
    this.showMoney = true,
  });

  /// عرض عمود الأرقام (شارات + صافي + حالة) — ثابت كي لا يزاحم اسم العميل
  /// The width of the numbers column (badges + net + state) — fixed so it never squeezes the name.
  static const double _numbersWidth = 66;

  @override
  Widget build(BuildContext context) {
    final statusColor = bill.isDelivered ? AppColors.success : AppColors.warning;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: AppColors.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        _numberSquare(),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _identityColumn()),
                        const SizedBox(width: 2),
                        _numbersColumn(statusColor),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// مربّع رقم الفاتورة وسنتها — عرض ثابت 54
  /// The bill-number square with its year — a fixed 54 width.
  Widget _numberSquare() {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${bill.billNo}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// الاسم الكامل في سطر واحد مع تصغير خطّه + سطر البيانات
  /// The full name on one line with a shrinking font, plus the data line.
  Widget _identityColumn() {
    final name = bill.custName.isEmpty ? 'عميل غير مسمّى' : bill.custName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // الاسم كامل دائماً: يصغر الخط بدل أن يُقصّ
        // The name is always complete: the font shrinks instead of the text being cut.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              name,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        // سطر البيانات يلتفّ بنفسه عند ضيق المساحة ولا يزاحم أحداً
        // The data line wraps by itself when space is tight and never competes.
        Wrap(
          spacing: 8,
          runSpacing: 1,
          children: [
            if (bill.telNo1 != null) _meta(Icons.phone_rounded, bill.telNo1!),
            if (bill.date != null) _meta(Icons.event_rounded, bill.date!),            
            // if (bill.manualBillNo != null)
            //   _meta(Icons.tag_rounded, 'يدوي ${bill.manualBillNo}'),
          ],
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.textSecondary),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// عمود الأرقام بعرض ثابت: شارات العدّ + الصافي + الحالة — كلها داخل `FittedBox`
  /// The fixed-width numbers column: count badges, net and state — all inside `FittedBox`.
  Widget _numbersColumn(Color statusColor) {
    return SizedBox(
      width: _numbersWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 3,
            runSpacing: 2,
            children: [
              _badge('${bill.modelsCount} موديل', AppColors.info),
              _badge('${bill.piecesCount} قطعة', AppColors.secondary),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showMoney && bill.net != null) ...[
                  Text(
                    tailoringNumber(bill.net),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  bill.isDelivered ? 'مُسلَّمة' : 'قيد التنفيذ',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
        maxLines: 1,
      ),
    );
  }
}
