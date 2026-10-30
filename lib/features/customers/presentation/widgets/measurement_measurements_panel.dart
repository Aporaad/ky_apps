import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';
import 'measurement_kit.dart';

/// القسم الثاني: تفاصيل المقاسات L1..L12 بتسمياتها من القاعدة
/// Section two: the L1..L12 measurements, labelled from the database dictionary.
///
/// التسميات تأتي من `GENERAL_LABELS_CODING` عبر الخادم لا من ثوابت في الشاشة، فإضافة تسمية
/// في القاعدة تظهر هنا بلا تعديل كود. والفارغ يُخفى ما لم يطلب الناظر إظهاره: موديل يستخدم
/// أربعة مقاسات من اثني عشر لا يحتاج ثمانية أرقام «—» تسرق نصف الارتفاع.
/// Labels come from GENERAL_LABELS_CODING through the server, so a new dictionary label appears
/// without a code change. Blanks are hidden unless asked for: a model using four of twelve slots
/// should not spend half the sheet on eight dashes.
class MeasurementMeasurementsPanel extends StatelessWidget {
  final CuttingModelItem model;
  final Map<String, String> labels;

  /// إظهار الخانات الفارغة — قرار عرض يأتي من شريط الفلترة لا من هنا
  /// Showing blank slots is a display decision owned by the filter bar, not by this panel.
  final bool showEmptySlots;

  const MeasurementMeasurementsPanel({
    super.key,
    required this.model,
    required this.labels,
    this.showEmptySlots = false,
  });

  @override
  Widget build(BuildContext context) {
    final keys = <String>[for (var i = 1; i <= 12; i++) 'L$i'];
    final visible = showEmptySlots
        ? keys
        : keys.where((key) => model.measurements[key] != null).toList();

    return MeasurementSectionCard(
      title: 'تفاصيل المقاسات',
      icon: Icons.straighten_rounded,
      accent: AppColors.info,
      subtitle: tailoringJoin([model.beneficiary, model.typeName]),
      trailing: MeasurementBadge(
        label: '${model.measurements.length}/12',
        color: AppColors.info,
      ),
      child: visible.isEmpty
          ? const _EmptyLine(text: 'لا توجد مقاسات مسجّلة لهذا الموديل')
          : MeasurementFieldGrid(
              // الخانات أصغر عرضاً: المقاس رقم وقِطعٌ قليلة الأرقام، والسبع في الصف تُبقي
              // الاثني عشر في سطرين.
              // Narrow cells: a measurement is a short number, and seven per row keeps twelve in two lines.
              minCellWidth: 86,
              fields: [
                for (final key in visible)
                  MeasurementField(
                    label: _labelFor(key),
                    value: model.measurements[key] == null
                        ? null
                        : tailoringNumber(model.measurements[key]!, decimals: 2),
                    numeric: true,
                    valueColor: model.measurements[key] == null
                        ? null
                        : AppColors.textPrimary,
                  ),
              ],
            ),
    );
  }

  /// التسمية الحقيقية، والمفتاح حرفياً عند غيابها — لا اختراع لاسم مقاس
  /// The real label, or the raw key when the dictionary has none: a measurement name is never invented.
  String _labelFor(String key) {
    final label = labels[key];

    return (label == null || label.trim().isEmpty) ? key : label;
  }
}

/// سطر فراغ واحد بحجم نص مقروء — لا صندوق داخل صندوق
/// One readable empty line — not a box inside a box.
class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
