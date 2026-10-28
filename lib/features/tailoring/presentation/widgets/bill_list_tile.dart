import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/tailoring_parse.dart';

/// بطاقة فاتورة تفصيل واحدة في القائمة
/// One cutting-bill card in the list.
///
/// تُظهر ما تحمله الواجهة فقط: الرقم والسنة والرقم اليدوي والتاريخ والعميل والهاتف
/// وعدد الموديلات والقطع والصافي وحالة التسليم — كلها من صفوف الـ VIEW.
/// It shows only what the view carries: number, year, manual number, date, customer, phone,
/// model/piece counts, net and delivery state — all from the view rows.
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

  @override
  Widget build(BuildContext context) {
    final statusColor = bill.isDelivered ? AppColors.success : AppColors.warning;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _numberBadge(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bill.custName.isEmpty ? 'عميل غير مسمّى' : bill.custName,
                      style:  TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _chip(
                    bill.isDelivered ? 'تم التسليم' : 'قيد التنفيذ',
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                children: [
                  if (bill.date != null) _meta(Icons.event_rounded, bill.date!),
                  if (bill.telNo1 != null)
                    _meta(Icons.phone_rounded, bill.telNo1!),
                  _meta(
                    Icons.checkroom_rounded,
                    '${bill.modelsCount} موديل · ${bill.piecesCount} قطعة',
                  ),
                  if (bill.manualBillNo != null)
                    _meta(Icons.tag_rounded, 'يدوي ${bill.manualBillNo}'),
                ],
              ),
              if (showMoney && bill.net != null) ...[
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الصافي',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        tailoringNumber(bill.net),
                        style:  TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// شارة رقم الفاتورة مع السنة — الهوية المركّبة كاملة
  /// The bill-number badge with its year — the full composite identity.
  Widget _numberBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        bill.referenceLabel,
        style:  TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style:  TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
