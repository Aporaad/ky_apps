import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_cells.dart';
import 'tailoring_section_card.dart';

/// القسم 5: تفاصيل مقاسات الموديل المختار — بنفس شكل قسم «تفاصيل المقاسات» في شاشة
/// «مقاسات العملاء»، لكن بخطوط أكبر وأثقل
/// Section 5: the selected model's measurement details — the same shape as the "measurement
/// details" section of the customer-measurements screen, but with larger, heavier type.
///
/// التسميات تأتي من `GENERAL_LABELS_CODING` عبر الخادم لا من ثوابت في الشاشة. والخانات
/// شبكةٌ بأعمدة متساوية وفواصل رأسية وأفقية ظاهرة، والقيمة بوزن 900 وحجم 13 مع تصغير تلقائي
/// بدل القصّ، فتبقى كل التسميات والأرقام مقروءة على أي عرض.
/// Labels come from GENERAL_LABELS_CODING through the server, never from screen constants. The
/// cells form a grid of equal columns with visible vertical and horizontal rules; the value is
/// w900 at 13 with automatic scale-down instead of truncation, so every label and figure stays
/// readable at any width.
///
/// الفراغ مخفي افتراضياً لأن المقاسات غير المستخدمة تضخّم الجدول بلا فائدة، ومفتاح
/// «إظهار الكل» يعيدها لمن يريد رؤية كل الخانات.
/// Blanks are hidden by default because unused measurements bloat the grid for nothing; the
/// "show all" switch brings them back.
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

    final visibleKeys =
        _showAll ? keys : keys.where((k) => model.measurements[k] != null).toList();

    return TailoringSectionCard(
      title: 'تفاصيل المقاسات — موديل ${model.seqNo}',
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
                      fontWeight: FontWeight.w800,
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
          ? Text(
              'لا توجد مقاسات مسجّلة لهذا الموديل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          : TailoringCellGrid(
              // خانات أصغر عرضاً: المقاس رقم قصير، فالسبع في الصف تُبقي الاثني عشر في سطرين
              // Narrow cells: a measurement is a short number, so seven per row keep twelve in
              // two lines.
              minCellWidth: 88,
              cells: [
                for (final key in visibleKeys)
                  TailoringCell(
                    label: _labelFor(key),
                    value: model.measurements[key] == null
                        ? null
                        : tailoringNumber(model.measurements[key]!, decimals: 2),
                    numeric: true,
                  ),
              ],
            ),
    );
  }

  /// التسمية الحقيقية، والمفتاح حرفياً عند غيابها — لا اختراع لاسم مقاس
  /// The real label, or the raw key when the dictionary has none: a name is never invented.
  String _labelFor(String key) {
    final label = widget.labels[key];
    return (label == null || label.trim().isEmpty) ? key : label;
  }
}
