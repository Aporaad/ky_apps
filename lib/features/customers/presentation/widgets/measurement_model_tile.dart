import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_model_ref.dart';
import 'measurement_kit.dart';

/// بطاقة موديل في نافذة اختيار الموديلات
/// A model card inside the model-picker sheet.
///
/// العميل قد يملك آلاف الموديلات (أقصى مقيس في القاعدة الحيّة 2,169 لعميل واحد)، فالسطر يحمل
/// ما يميّز الموديل فقط: المستفيد، النوع، التاريخ، الفاتورة، القطع والمرحلة — بتباين عالٍ
/// لأن القائمة الطويلة تُقرأ بالمسح البصري لا بالتدقيق.
/// A customer can own thousands of models (the live maximum is 2,169), so the row carries only
/// what distinguishes one: beneficiary, type, date, bill, pieces and stage — at high contrast,
/// because a long list is scanned, not studied.
class MeasurementModelTile extends StatelessWidget {
  final MeasurementModelRef model;
  final VoidCallback onTap;

  /// اسم العميل — البديل الوحيد عند غياب المستفيد: لا نص «بلا مستفيد» في القائمة
  /// The customer's name — the only fallback when a model has no beneficiary. The list never
  /// prints "no beneficiary"; it prints the name the row already belongs to.
  final String customerName;

  const MeasurementModelTile({
    super.key,
    required this.model,
    required this.onTap,
    this.customerName = '',
  });

  @override
  Widget build(BuildContext context) {
    final tone = _stageColor(model);
    final title = model.beneficiary ??
        (customerName.isEmpty ? model.displayName : customerName);

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
                Container(width: 4, color: tone),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: tone.withValues(alpha: 0.32)),
                          ),
                          child: Icon(
                            Icons.checkroom_rounded,
                            size: 18,
                            color: tone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${model.displayName} · فاتورة ${model.billLabel} · '
                                '${model.piecesCount} قطعة',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              model.date ?? '—',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            MeasurementBadge(
                              label: model.stageLabel,
                              color: tone,
                              solid: model.isComplete,
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
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

  /// لون المرحلة بلوحة التطبيق — نفس دلالة الألوان في جدول الأقمشة
  /// The stage colour from the app palette, carrying the same meaning as in the fabrics panel.
  Color _stageColor(MeasurementModelRef model) {
    if (model.handingDone) return AppColors.success;
    if (model.tailorDone) return AppColors.info;
    if (model.cuttingDone) return AppColors.warning;

    return AppColors.textSecondary;
  }
}
