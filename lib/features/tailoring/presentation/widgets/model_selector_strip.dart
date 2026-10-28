import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_piece_item.dart';
import 'tailoring_section_card.dart';

/// القسم 4: شريط اختيار الموديل — الاختيار يقود أقسام المقاسات والمواصفات والأقمشة والحركة
/// Section 4: the model selector — the choice drives the measurements, specs, fabrics and
/// movement sections.
///
/// كل موديل في سطر واحد منضبط: رقمه · نوعه (قطري/حجازي/عماني…) · المستفيد · عدد القطع ·
/// المرحلة. والمستفيد بلا اسم لا يُعرض له عمود أصلاً — لا كلمة «بلا مستفيد» ولا خانة فارغة،
/// فالسطر يبقى نظيفاً بلا معلومة كاذبة.
/// Each model occupies one tidy line: its number · its type (Qatari/Hejazi/Omani…) · the
/// beneficiary · the piece count · the stage. A model with no beneficiary gets no column at
/// all — no "بلا مستفيد" and no blank cell, so the line stays clean of false information.
class ModelSelectorStrip extends StatelessWidget {
  final List<CuttingModelItem> models;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ModelSelectorStrip({
    super.key,
    required this.models,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return const Text(
        'لا توجد موديلات في هذه الفاتورة',
        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < models.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == models.length - 1 ? 0 : 4),
            child: _ModelRow(
              model: models[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
            ),
          ),
      ],
    );
  }
}

class _ModelRow extends StatelessWidget {
  final CuttingModelItem model;
  final bool selected;
  final VoidCallback onTap;

  const _ModelRow({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(model.stage);
    final beneficiary = _clean(model.beneficiary);
    final typeName = _clean(model.typeName);

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.06)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.2 : 0.7,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // رقم الموديل: عمود ثابت يسهل مسحه بالعين على كل الصفوف
                // The model number: a fixed column the eye can scan down every row.
                Container(
                  width: 64,
                  alignment: Alignment.center,
                  color: selected
                      ? AppColors.primary
                      : AppColors.surfaceSubtle,
                  child: Text(
                    'موديل ${model.seqNo}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (typeName != null) ...[
                  _divider(),
                  Expanded(
                    flex: 3,
                    child: TailoringInfoTile(
                      label: 'نوع الموديل',
                      value: typeName,
                      valueColor: AppColors.primary,
                    ),
                  ),
                ],
                if (beneficiary != null) ...[
                  _divider(),
                  Expanded(
                    flex: 5,
                    child: TailoringInfoTile(
                      label: 'المستفيد',
                      value: beneficiary,
                    ),
                  ),
                ],
                _divider(),
                Expanded(
                  flex: 2,
                  child: TailoringInfoTile(
                    label: 'القطع',
                    value: '${model.piecesCount}',
                  ),
                ),
                _divider(),
                Expanded(
                  flex: 3,
                  child: TailoringInfoTile(
                    label: 'المرحلة',
                    value: model.stage.label,
                    valueColor: stageColor,
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// فاصل رأسي بين خانات السطر
  /// A vertical divider between the row's cells.
  Widget _divider() =>
      Container(width: 0.7, color: AppColors.border.withValues(alpha: 0.9));

  /// النص الفارغ أو المزيّف بـ«لا يوجد» لا يُعدّ قيمة
  /// An empty text, or the legacy "لا يوجد", is not a value.
  String? _clean(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty || value == 'لا يوجد') return null;
    return value;
  }

  Color _stageColor(CuttingPieceStage stage) {
    return switch (stage) {
      CuttingPieceStage.delivered => AppColors.success,
      CuttingPieceStage.tailored => AppColors.info,
      CuttingPieceStage.cut => AppColors.warning,
      CuttingPieceStage.waiting => AppColors.textMuted,
    };
  }
}
