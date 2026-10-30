import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/cutting_piece_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';
import 'measurement_kit.dart';

/// القسم الرابع: الأقمشة الخاصة بالموديل — كل قماش في سطرين
/// Section four: the model's fabrics — every fabric on exactly two lines.
///
/// السطر الأول هوية القماش وكميته وسعره: رقم الطلب (`OHDID`) · القماش · العرض · اللون ·
/// هنش · ياردة · السعر. والسطر الثاني مسؤولو التنفيذ ومرحلتها: القصّاص · الخيّاط · المرحلة.
/// تقسيم كهذا يبقي كل عمود على محاذاته عبر الأقمشة، وهو ما يعجز عنه جدول بعشرة أعمدة على جوال.
/// Line one is the fabric's identity, quantity and price: order number (OHDID), cloth, width,
/// colour, hinsh, yards, price. Line two is who executed it and how far: cutter, tailor, stage.
/// The split keeps every column aligned down the list, which a ten-column table cannot do on a phone.
///
/// «العرض» هو `CLOTH_TYPE` نفسه: قيمته في القاعدة «عرضية/عادية» لا نوع قماش، فتسميته «النوع»
/// كانت تضلّل القارئ.
/// "Width" is CLOTH_TYPE itself: its values are عرضية/عادية in the live data, so labelling that
/// column "type" was actively misleading.
class MeasurementFabricsPanel extends StatelessWidget {
  final CuttingModelItem model;

  const MeasurementFabricsPanel({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return MeasurementSectionCard(
      title: 'الأقمشة الخاصة بالموديل',
      icon: Icons.dry_cleaning_rounded,
      accent: AppColors.accentLight,
      subtitle: tailoringJoin([model.beneficiary, model.typeName]),
      trailing: MeasurementBadge(
        label: '${model.pieces.length} قطعة',
        color: AppColors.accentLight,
      ),
      child: model.pieces.isEmpty
          ? Text(
              'لا توجد قطع مسجّلة لهذا الموديل',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            )
          // عمود واحد بعرض أدنى: المحاذاة أهم من حشو الشاشة، والتكبير بالإصبع يعوّض الضيق
          // One column with a floor width: alignment beats stuffing the viewport, and pinch zoom
          // covers the rest on a narrow screen.
          // العرض محسوب لا «غير محدد»: التمرير الأفقي يعطي الابن عرضاً لا نهائياً، و`Expanded`
          // داخل عرض لا نهائي يسقط التخطيط قبل أن يرسم حرفاً.
          // The width is computed, never unbounded: a horizontal scroller hands its child infinite
          // width, and Expanded inside that blows up the layout before a single glyph is drawn.
          : LayoutBuilder(
              builder: (ctx, constraints) {
                const minWidth = 700.0;
                final width = constraints.maxWidth < minWidth
                    ? minWidth
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < model.pieces.length; i++) ...[
                          if (i > 0) const SizedBox(height: 6),
                          _FabricCard(piece: model.pieces[i], index: i),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// بطاقة قماش واحد بسطرين مفصولين بخطّ
/// One fabric as two lines separated by a rule.
class _FabricCard extends StatelessWidget {
  final CuttingPieceItem piece;
  final int index;

  const _FabricCard({required this.piece, required this.index});

  @override
  Widget build(BuildContext context) {
    final tone = AppColors.accentLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // السطر الأول: هوية القماش وكميته وسعره
          // Line one: the fabric itself, its quantity and its price.
          Container(
            color: tone.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            // IntrinsicHeight لأن الصفوف داخل تمرير رأسي لا محدود: `stretch` بلا ارتفاع
            // محسوب ترمي القيود غير الصالحة قبل أن تُرسم الخلية الأولى.
            // IntrinsicHeight because these rows live in an unbounded vertical scroller:
            // `stretch` without a computed height hands children invalid constraints before
            // the first cell is ever painted.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _cell('#${index + 1}', flex: 1, accent: tone),
                  _rule(),
                  _cell(
                    'رقم الطلب',
                    value: piece.ohdId?.toString(),
                    flex: 2,
                    numeric: true,
                  ),
                  _rule(),
                  _cell('القماش', value: piece.clothName, flex: 4),
                  _rule(),
                  _cell('العرض', value: piece.clothType, flex: 2.4),
                  _rule(),
                  _cell('اللون', value: piece.colorText, flex: 2.4),
                  _rule(),
                  _cell(
                    'هنش',
                    value: tailoringNumber(piece.hinsh),
                    flex: 1.8,
                    numeric: true,
                  ),
                  _rule(),
                  _cell(
                    'ياردة',
                    value: tailoringNumber(piece.yards),
                    flex: 1.8,
                    numeric: true,
                  ),
                  _rule(),
                  _cell(
                    'السعر',
                    value: tailoringNumber(piece.price, decimals: 2),
                    flex: 2.4,
                    numeric: true,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: tone.withValues(alpha: 0.28)),
          // السطر الثاني: المسؤولون والمرحلة
          // Line two: the people responsible and the stage reached.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ترتيب الخانات يترك مجالاً لشارة المرحلة دون قصّ النص
                  // This order leaves the stage chip its own room instead of clipping a name.
                  _cell(
                    'القصّاص',
                    value: piece.cutterName,
                    flex: 3,
                    icon: Icons.content_cut_rounded,
                  ),
                  _rule(),
                  _cell(
                    'الخيّاط',
                    // «غير مسند» لا «—»: الخيّاط غير المسند قرار إنتاجي لا معلومة ناقصة
                    // "Unassigned" is a production state, not a missing value.
                    value: piece.hasTailor ? piece.tailorName : 'غير مسند',
                    flex: 3,
                    icon: Icons.design_services_rounded,
                    valueColor: piece.hasTailor ? null : AppColors.textSecondary,
                  ),
                  _rule(),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'المرحلة',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          MeasurementBadge(
                            label: piece.stage.label,
                            color: _stageColor(piece.stage),
                            solid: piece.stage == CuttingPieceStage.delivered,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// خانة بسطر تسمية وفوقه/إليه قيمة، بعرض نسبي ثابت عبر كل البطاقات
  /// A labelled cell with a fixed flex, so columns line up across every fabric card.
  Widget _cell(
    String label, {
    String? value,
    required double flex,
    bool numeric = false,
    IconData? icon,
    Color? valueColor,
    Color? accent,
  }) {
    return Expanded(
      flex: flex.round(),
      child: MeasurementField(
        label: label,
        value: value,
        icon: icon,
        numeric: numeric,
        valueColor: valueColor,
      ),
    );
  }

  /// خط فصل رأسي — هو «الفاصل بين الحقول» المطلوب، لا فراغ يُفهم ظنًّا
  /// The vertical rule: the requested field separator, not whitespace left to guesswork.
  Widget _rule() => Container(width: 1, color: AppColors.border);

  Color _stageColor(CuttingPieceStage stage) => switch (stage) {
    CuttingPieceStage.delivered => AppColors.success,
    CuttingPieceStage.tailored => AppColors.info,
    CuttingPieceStage.cut => AppColors.warning,
    CuttingPieceStage.waiting => AppColors.textSecondary,
  };
}
