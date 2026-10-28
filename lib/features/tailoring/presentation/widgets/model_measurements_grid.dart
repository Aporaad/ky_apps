import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_section_card.dart';

/// القسم 5: مقاسات الموديل المختار — L1..L12 بتسمياتها الحقيقية
/// Section 5: the selected model's measurements — L1..L12 with their real labels.
///
/// التسميات تأتي من `GENERAL_LABELS_CODING` عبر الخادم، لا من الشاشة، فإضافة تسمية جديدة
/// في القاعدة تظهر هنا بلا تعديل كود.
/// The labels come from `GENERAL_LABELS_CODING` through the server, not from the screen, so a
/// label added in the database appears here without a code change.
///
/// الفراغ مخفي افتراضياً لأن المقاسات غير المستخدمة تضخّم الجدول بلا فائدة، ومفتاح
/// «إظهار الكل» يعيدها لمن يريد رؤية كل الخانات.
/// Blanks are hidden by default because unused measurements bloat the grid for nothing; the
/// "show all" switch brings them back for whoever wants every slot.
///
/// الاثنا عشر مقاساً تُعرض في صف واحد على الشاشات العريضة، كلٌّ في خانة مسوّرة بعرض متساوٍ،
/// فتُقارَن القيم رأسياً بسهولة بدل قراءتها في صناديق متفرّقة.
/// The twelve measurements share one row on wide screens, each in an equal bordered cell, so
/// values compare vertically at a glance instead of being read in scattered boxes.
class ModelMeasurementsGrid extends StatefulWidget {
  final CuttingModelItem model;

  /// تسميات L1..L12 من الخادم
  /// L1..L12 labels from the server.
  final Map<String, String> labels;

  const ModelMeasurementsGrid({
    super.key,
    required this.model,
    required this.labels,
  });

  @override
  State<ModelMeasurementsGrid> createState() => _ModelMeasurementsGridState();
}

class _ModelMeasurementsGridState extends State<ModelMeasurementsGrid> {
  bool _showAll = false;

  @override
  void didUpdateWidget(covariant ModelMeasurementsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // تغيير الموديل يعيد الوضع الافتراضي كي لا ينتقل «إظهار الكل» بين موديلات مختلفة
    // Switching models restores the default so "show all" never carries across models.
    if (oldWidget.model.seqNo != widget.model.seqNo) _showAll = false;
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final keys = <String>[
      for (var i = 1; i <= 12; i++) 'L$i',
    ];

    final visibleKeys = _showAll
        ? keys
        : keys.where((k) => model.measurements[k] != null).toList();

    return TailoringSectionCard(
      title: 'المقاسات — موديل ${model.seqNo}',
      icon: Icons.straighten_rounded,
      accent: AppColors.info,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TailoringChip(
            label: '${model.filledMeasurementsCount}/12',
            color: AppColors.info,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => setState(() => _showAll = !_showAll),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              child: Row(
                children: [
                  Icon(
                    _showAll
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 12,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _showAll ? 'إخفاء الفراغ' : 'إظهار الكل',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: visibleKeys.isEmpty
          ? const Text(
              'لا توجد مقاسات مسجّلة لهذا الموديل',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            )
          : TailoringInfoGrid(
              singleRow: true,
              minCellWidth: 74,
              children: [
                for (final key in visibleKeys)
                  TailoringInfoTile(
                    label: _labelFor(key),
                    value: model.measurements[key] == null
                        ? '—'
                        : tailoringNumber(model.measurements[key]),
                    valueColor: model.measurements[key] == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
              ],
            ),
    );
  }

  /// تسمية المقياس مع الرجوع إلى مفتاحه عند غياب التسمية في القاعدة
  /// The measurement's label, falling back to its key when the database has none.
  String _labelFor(String key) {
    final label = widget.labels[key];
    return (label == null || label.trim().isEmpty) ? key : label;
  }
}
