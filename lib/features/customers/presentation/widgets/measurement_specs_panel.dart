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
    // الترتيب بطلب المستخدم: نوع الأزرار · نوع الكم · نوع الرقبة · جيب جانبي · نوع الجبزور ·
    // جيب الصدر، ثم بقية ما تحمله القاعدة فعلياً.
    // The user's own order first (button, sleeve, neck, side pocket, gabzor, chest pocket), then
    // whatever else the database actually stores.
    //
    // «جيب جانبي» هو `POCKET_OR_WITHOUT`: قيمه في القاعدة الحيّة «جيوب / بدون / جيوب شمال /
    // جيوب يمين» (83,395 من 84,971 صفاً) فهو فعلاً حالة الجيب الجانبي. و«جيب الصدر» لا عمود
    // نصي له: أقرب ما يُسجَّل له `SHAPE_POCKET_UP_NO` (مُعرَّف الجيب العلوي) ويظهر عند وجوده
    // فقط. أما `PEN_POCKET` ففارغ في كل الصفوف (0 من 84,971) فأُزيل من القائمة: خانة لا تمتلئ
    // أبداً ليست معلومة، وهي ضريبة بصرية على شاشة طلبت الاختصار.
    // "Side pocket" is POCKET_OR_WITHOUT — its live values are جيوب/بدون/جيوب شمال/جيوب يمين
    // (83,395 of 84,971 rows), so it really is the side-pocket state. "Chest pocket" has no text
    // column; the nearest recorded thing is SHAPE_POCKET_UP_NO (the upper-pocket id), shown only
    // when present. PEN_POCKET is empty in every single row (0 of 84,971), so it is dropped: a
    // cell that can never fill is not information, and it costs height on a screen built to be
    // compact.
    final items = <(String, String?, IconData?)>[
      ('نوع الكم', specs.comCabakType!, Icons.check_circle_outline),
      if (specs.neckType != null) ('نوع الرقبة', specs.neckType!,Icons.check_circle_outline),
      if (specs.pocketOrWithout != null) ('الجيوب', specs.pocketOrWithout!, Icons.check_circle_outline),
      if (specs.gabzorType != null) ('نوع الجبزور', specs.gabzorType!, Icons.check_circle_outline),
      if (specs.mobilePocket != null) ('جيب الصدر ', specs.mobilePocket!, Icons.check_circle_outline),
      if (specs.buttonType != null) ('نوع الأزرار', specs.buttonType!, Icons.check_circle_outline),
      if (specs.buttonNo != null) ('رقم الأزرار', specs.buttonNo!, Icons.check_circle_outline),
      if (specs.shapeGabzorNo != null && specs.shapeGabzorNo==1) ('جبزور يد', '✔️', null),
      if (specs.tipperType != null) (' فئة الخياط', specs.tipperType!, null),
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
