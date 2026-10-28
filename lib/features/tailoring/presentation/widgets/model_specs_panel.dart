import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import 'tailoring_section_card.dart';

/// القسم 6: مواصفات الموديل المختار — خصائص القطعة نفسها
/// Section 6: the selected model's specs — the properties of the garment itself.
///
/// المقصود بالمواصفات هنا: نوع الرقبة · نوع الكم · الكباك · الجيوب · نوع الجبزور · نوع
/// الأزرار وعددها · جيب الجوال · جيب القلم · الحجازي. أما نوع الموديل وشكله ورقم الشكل فهي
/// تعريف الموديل ومكانه سطر الموديل في القسم الرابع، لا مواصفات قطعة.
/// The specs here are the garment's own properties: neck type, sleeve type, cuff, pockets,
/// gabzor type, button type and count, mobile pocket, pen pocket, hejazi. The model type, its
/// shape and the shape number identify the model and live in the model line of section four —
/// they are not garment specs.
///
/// الأكواد الرقمية (نموذج الرقبة/الجبزور/الجيب…) تُعرض كما هي في حاشية صغيرة: ترجمتها إلى
/// أسماء تحتاج قاموس أشكال لا يملكه المشروع الآن، فتحويلها بالتخمين خطأ.
/// The numeric codes (neck/gabzor/pocket shape…) appear as-is in a small footnote: naming them
/// needs a shape dictionary the project does not have yet, so guessing would be wrong.
class ModelSpecsPanel extends StatelessWidget {
  final CuttingModelItem model;

  const ModelSpecsPanel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final specs = model.specs;

    return TailoringSectionCard(
      title: 'المواصفات — موديل ${model.seqNo}',
      icon: Icons.tune_rounded,
      accent: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (specs.textChips.isEmpty)
            const Text(
              'لا توجد مواصفات مسجّلة لهذا الموديل',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            )
          else
            // كل مواصفة في خانة مسوّرة: التسمية فوق والقيمة تحتها، فتُقرأ المواصفات صفاً واحداً
            // Each spec in a bordered cell — label above, value below — so specs read as one row.
            TailoringInfoGrid(
              singleRow: true,
              minCellWidth: 96,
              children: [
                for (final (label, value) in specs.textChips)
                  TailoringInfoTile(
                    label: label,
                    value: value,
                    icon: Icons.check_circle_outline_rounded,
                    valueColor: AppColors.textPrimary,
                  ),
              ],
            ),

          // الملاحظة سطرية: أيقونة + نص في صف واحد بأقصى سطرين
          // The note is linear: one icon and the text on a single row, two lines at most.
          if (specs.notes != null) ...[
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.sticky_note_2_rounded,
                  size: 12,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    specs.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // الأكواد الرقمية في حاشية واحدة رقيقة
          // The numeric codes in one thin footnote line.
          if (specs.numericCodes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'أكواد الأشكال:',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                for (final (label, code) in specs.numericCodes)
                  Text(
                    '$label $code',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
