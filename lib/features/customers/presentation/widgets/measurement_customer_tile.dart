import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_customer_model.dart';

/// بطاقة عميل في قائمة «مقاسات العملاء» — اسم وهاتف وعدّادات وآخر نشاط
/// A customer card in the measurements list — name, phone, counters and the last activity.
///
/// الصف مضغوط عمداً: القائمة قد تحمل آلاف العملاء، فكل سطر إضافي يعني آلاف الأسطر قبل أن يصل
/// المستخدم إلى اسمه.
/// The row is deliberately tight: this list can hold thousands of customers, so every extra line
/// is thousands of lines before the user reaches the name they came for.
class MeasurementCustomerTile extends StatelessWidget {
  final MeasurementCustomer customer;
  final VoidCallback onTap;

  const MeasurementCustomerTile({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              // رقم العميل في دائرة: بديل ثابت عن الأفاتار بلا أي صورة
              // The customer number in a disc: a stable avatar-free stand-in.
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${customer.custNo}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customer.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (customer.telNo1 != null) ...[
                          const Icon(
                            Icons.phone_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            customer.telNo1!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 7),
                        ],
                        Text(
                          customer.lastDate ?? '—',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // عدّ الموديلات هو الدلالة العملية: كم مرة فُصّل لهذا العميل
              // The model count is the meaningful figure: how often this customer was tailored for.
              _CountBadge(
                label: '${customer.modelsCount}',
                caption: 'موديل',
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شارة عدد + تسمية صغيرة / a count with a tiny caption
class _CountBadge extends StatelessWidget {
  final String label;
  final String caption;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.caption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            caption,
            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
