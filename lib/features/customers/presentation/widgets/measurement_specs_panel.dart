import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import 'measurement_kit.dart';

/// القسم الثالث: مواصفات الموديل — خصائص الثوب نفسه فقط
/// Section three: the model's specifications — the properties of the garment itself.
///
/// المطلوب صراحةً: نوع الأزرار · نوع الكم · نوع الرقبة · الجيوب · نوع الجبزور · جيب الجوال ·
/// جيب القلم · الحجازي · الملاحظة. وأُخرجت منها «نوع الموديل» و«الشكل» و«رقم الشكل» لأنها
/// تعريف الموديل لا مواصفته: رقم الشكل كود في قاموس أشكال لا يملكه المشروع بعد، وعرضه
/// «مواصفة» يوحي بأنه قرار خياطة وهو مجرد مرجع رقمي.
/// Asked for explicitly: button type, sleeve, neck, pockets, gabzor, mobile/pen pocket, hejazi
/// and the note. Model type, shape and shape number are excluded — they identify the model rather
/// than specify the garment, and a shape number is a dictionary code the project does not have
/// yet, so showing it as a "specification" would imply a tailoring decision it never carried.
class MeasurementSpecsPanel extends StatelessWidget {
  final CuttingModelItem model;

  const MeasurementSpecsPanel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final specs = model.specs;
    final items = <(String, String?, IconData?)>[
      ('نوع الرقبة', specs.neckType, Icons.accessibility_new_rounded),
      ('نوع الكم', specs.tipperType, Icons.straighten_rounded),
      ('نوع الكباك', specs.comCabakType, Icons.settings_brightness_rounded),
      ('الجيوب', specs.pocketOrWithout, Icons.category_rounded),
      ('نوع الجبزور', specs.gabzorType, Icons.brush_rounded),
      ('نوع الأزرار', specs.buttonType, Icons.radio_button_checked_rounded),
      ('عدد الأزرار', specs.buttonNo, Icons.format_list_numbered_rounded),
      ('جيب الجوال', specs.mobilePocket, Icons.smartphone_rounded),
      ('جيب القلم', specs.penPocket, Icons.edit_rounded),
      ('نوع الحجازي', specs.hegaziType, Icons.pattern_rounded),
    ];

    // الفارغ لا يُعرض: اثنتا عشرة خانة «—» تحوّل المواصفات إلى جدول فراغات
    // Blanks are not shown: twelve dashes turn the specs into a table of nothing.
    final filled = items
        .where((item) => item.$2 != null && item.$2!.trim().isNotEmpty)
        .toList();

    return MeasurementSectionCard(
      title: 'مواصفات الموديل',
      icon: Icons.tune_rounded,
      accent: AppColors.secondary,
      child: filled.isEmpty && specs.notes == null
          ? Text(
              'لا توجد مواصفات مسجّلة لهذا الموديل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (filled.isNotEmpty)
                  MeasurementFieldGrid(
                    minCellWidth: 126,
                    fields: [
                      for (final (label, value, icon) in filled)
                        MeasurementField(
                          label: label,
                          value: value,
                          icon: icon,
                        ),
                    ],
                  ),
                if (specs.notes != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sticky_note_2_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            specs.notes!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
