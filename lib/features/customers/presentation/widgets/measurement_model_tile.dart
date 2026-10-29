import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_model_ref.dart';

/// بطاقة موديل في قائمة موديلات العميل — الأحدث أولاً، بسطر واحد لكل موديل
/// A model card in the customer's list — newest first, one row per model.
///
/// العميل قد يملك آلاف الموديلات (أقصى قياس في القاعدة الحيّة: 2,169 موديلاً لعميل واحد)،
/// فالبطاقة تُظهر ما يميّز الموديل فقط: المستفيد، النوع، التاريخ، الفاتورة، القطع والمرحلة.
/// A customer can own thousands of models (the live maximum is 2,169 for one customer), so the
/// card shows only what distinguishes a model: beneficiary, type, date, bill, pieces and stage.
class MeasurementModelTile extends StatelessWidget {
  final MeasurementModelRef model;
  final VoidCallback onTap;

  const MeasurementModelTile({
    super.key,
    required this.model,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(model);

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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: stageColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 18,
                  color: stageColor,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // المستفيد أولًا: هو من تُقاس له الثياب، والنوع يليه
                    // The beneficiary first — the person measured — then the garment type.
                    Text(
                      model.beneficiaryLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${model.displayName} · فاتورة ${model.billLabel} · '
                      '${model.piecesCount} قطعة',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    model.date ?? '—',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      model.stageLabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: stageColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
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

  /// لون المرحلة — نفس دلالة ألوان المراحل في قسم التفصيل
  /// The stage colour — the same meaning the tailoring section gives its stages.
  Color _stageColor(MeasurementModelRef model) {
    if (model.handingDone) return AppColors.success;
    if (model.tailorDone) return AppColors.info;
    if (model.cuttingDone) return AppColors.warning;

    return AppColors.textMuted;
  }
}
