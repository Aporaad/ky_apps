import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/cutting_piece_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';
import 'measurement_kit.dart';

/// القسم الرابع: الأقمشة الخاصة بالموديل — كل قماش في سطرين داخل عرض الشاشة
/// Section four: the model's fabrics — every fabric on two lines, inside the screen's width.
///
/// السطر الأول هوية القماش وكميته وسعره: رقم الطلب (`OHDID`) · القماش · العرض · اللون ·
/// هنش · ياردة · السعر. والسطر الثاني التنفيذ: القصّاص · الخيّاط · المرحلة.
/// لا عمود ترقيم (#) ولا تمرير أفقي: كل الأعمدة تُرى دفعة واحدة لأن القارئ الذي يقارن
/// قماشين لا يجب أن يحرّك الشاشة ليراهما معاً.
/// Line one is the fabric, its quantity and price: order id (OHDID), cloth, width, colour, hinsh,
/// yards, price. Line two is the execution: cutter, tailor, stage. There is no row-number column
/// and no horizontal scrolling: every column is visible at once, because someone comparing two
/// fabrics must not have to slide the screen to see both.
///
/// «العرض» هو `CLOTH_TYPE`: قيمه في القاعدة «عرضية/ضيقة» لا نوع قماش، فتسميته «النوع» كانت
/// تضلّل. والرف والمصدر محذوفان بطلب صريح.
/// "Width" is CLOTH_TYPE — its stored values are عرضية/ضيقة, so "type" misled; shelf and source
/// are removed on request.
class MeasurementFabricsPanel extends StatelessWidget {
  final CuttingModelItem model;

  const MeasurementFabricsPanel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return MeasurementSectionCard(
      title: 'الأقمشة الخاصة بالموديل',
      icon: Icons.dry_cleaning_rounded,
      accent: AppColors.accentLight,
      trailingText: '${model.pieces.length} قطعة',
      child: model.pieces.isEmpty
          ? Text(
              'لا توجد قطع مسجّلة لهذا الموديل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < model.pieces.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _FabricCard(piece: model.pieces[i]),
                ],
              ],
            ),
    );
  }
}

/// بطاقة قماش واحد: سطر للأعمدة السبعة، وخط فاصل، ثم سطر المسؤولية والمرحلة
/// One fabric card: seven columns, a rule, then the responsibility and stage line.
class _FabricCard extends StatelessWidget {
  final CuttingPieceItem piece;

  const _FabricCard({required this.piece});

  /// أوزان الأعمدة: رقم الطلب يأخذ نصيباً وافراً لأنه في القاعدة 11 رقماً (مثال حيّ
  /// 26211325025) وكسره بالاقصاء أسوأ من اقصاء اسم القماش، فالاسم يطول ويقصر أما الرقم فمعرّف.
  /// Column weights: the order id gets generous room because live values run to 11 digits
  /// (26211325025 for example), and ellipsing an identifier is worse than ellipsing a cloth
  /// name — names vary, identifiers do not.
  static const List<double> _firstLineWeights = [2.4, 2.2, 1.3, 1.3, 0.9, 1.0, 1.3];
  static const List<String> _firstLineLabels = [
    'رقم الطلب',
    'القماش',
    'العرض',
    'اللون',
    'هنش',
    'ياردة',
    'السعر',
  ];

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.accentLight;
    final values = <String?>[
      piece.ohdId?.toString() ?? '${piece.seqNo1}',
      piece.clothName,
      piece.clothType,
      piece.colorText,
      tailoringNumber(piece.hinsh),
      tailoringNumber(piece.yards),
      tailoringNumber(piece.price, decimals: 2),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: tone.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spread(
                  [
                    for (var i = 0; i < values.length; i++)
                      MeasurementField(
                        label: _firstLineLabels[i],
                        value: values[i],
                        dense: true,
                        numeric: i != 1 && i != 3,
                        valueColor: i == 6 ? AppColors.primary : null,
                      ),
                  ],
                  _firstLineWeights,
                ),
              ),
            ),
          ),
          Container(height: 1.2, color: tone.withValues(alpha: 0.45)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spread(
                  [
                    MeasurementField(
                      label: 'القصّاص',
                      value: piece.cutterName,
                      dense: true,
                      icon: Icons.content_cut_rounded,
                    ),
                    piece.hasTailor?MeasurementField(
                      label: 'الخيّاط',
                      // «غير مسند» لا «—»: غير المسند حالة إنتاجية لا معلومة ناقصة
                      // "Unassigned" is a production state, not a missing value.
                      value: piece.hasTailor ? piece.tailorName : 'غير مسند',
                      dense: true,
                      icon: Icons.design_services_rounded,
                      valueColor: piece.hasTailor
                          ? null
                          : AppColors.textSecondary,
                    ):const SizedBox.shrink(),
                    
                    
                    _StageCell(piece: piece),
                  ],
                  const [2.4, 2.4, 1.6],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// توزيع الخلايا بأوزانها مع خط رفيع بينها — بلا أي عمود ترقيم
  /// Lays the cells out at their weights with hairlines between them — no row-number column.
  List<Widget> _spread(List<Widget> cells, List<double> weights) {
    final children = <Widget>[];

    for (var i = 0; i < cells.length; i++) {
      children.add(
        Expanded(flex: (weights[i] * 10).round(), child: cells[i]),
      );

      if (i != cells.length - 1) {
        children.add(Container(width: 1, color: gridRule));
      }
    }

    return children;
  }
}

/// خلية المرحلة: تسمية فوق شارة ملوّنة — كبقية خانات السطر الثاني لا كعنصر معلّق
/// The stage cell: a label over a coloured badge, aligned with the rest of line two.
class _StageCell extends StatelessWidget {
  final CuttingPieceItem piece;

  const _StageCell({required this.piece});

  @override
  Widget build(BuildContext context) {
    final stage = piece.stage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'المرحلة',
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          MeasurementBadge(
            label: stage.label,
            color: fabricStageColor(stage),
            // التسليم وحده يُملأ اللون: هو الحالة «المنتهية» في السجل
            // Only delivery fills solid: it is the finished state of the record.
            solid: stage == CuttingPieceStage.delivered,
          ),
        ],
      ),
    );
  }
}

/// لون المرحلة بلوحة التطبيق — نفس دلالة الألوان في كل شاشات التفصيل
/// The stage colour from the app palette, carrying the same meaning across the tailoring screens.
Color fabricStageColor(CuttingPieceStage stage) => switch (stage) {
  CuttingPieceStage.delivered => AppColors.success,
  CuttingPieceStage.tailored => AppColors.info,
  CuttingPieceStage.cut => AppColors.warning,
  CuttingPieceStage.waiting => AppColors.textSecondary,
};
