import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_piece_item.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_cells.dart';
import 'tailoring_section_card.dart';

/// القسم 7: أقمشة الموديل المختار — بنفس شكل قسم الأقمشة في شاشة «مقاسات العملاء»
/// Section 7: the selected model's fabrics — the same shape as the fabrics section of the
/// customer-measurements screen.
///
/// كل قماش بطاقةٌ مستقلة: سطر أول بأعمدة (رقم الطلب `OHDID` · القماش · العرض · اللون · هنش ·
/// ياردة · السعر) بفواصل ظاهرة، ثم خط فاصل، ثم سطر ثانٍ (القصّاص · الخيّاط · المرحلة).
/// الخطوط أكبر وأثقل من الطقم الأصلي، والقيم تُصغَّر بدل أن تُقصّ، فلا تمرير أفقي ولا معلومة
/// مخفية. والبطاقة قابلة للضغط: اختيارها يغيّر سجل الحركة في القسم الثامن.
/// Every fabric is its own card: a first line of columns (order id · fabric · width · colour ·
/// hinsh · yards · price) with visible rules, a divider, then a second line (cutter · tailor ·
/// stage). The type is larger and heavier than the original kit, values scale down instead of
/// being cut, so there is no horizontal scroll and no hidden information. The card is tappable:
/// choosing it switches the movement log in section eight.
class ModelFabricsTable extends StatelessWidget {
  final CuttingModelItem model;

  /// القماش المختار (OHDID) — يُبرز بطاقته ويقود سجل الحركة
  /// The selected fabric (OHDID) — it highlights its card and drives the movement log.
  final int? selectedOhdId;

  /// عند اختيار قماش
  /// Fired when a fabric is chosen.
  final ValueChanged<int?>? onSelected;

  const ModelFabricsTable({
    super.key,
    required this.model,
    this.selectedOhdId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TailoringSectionCard(
      title: 'الأقمشة — موديل ${model.typeName}  , رقم ${model.seqNo}',
      icon: Icons.dry_cleaning_rounded,
      accent: AppColors.accentLight,
      trailing: TailoringChip(
        label: '${model.piecesCount} قطعة',
        color: AppColors.accent,
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < model.pieces.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  _FabricCard(
                    piece: model.pieces[i],
                    selected: model.pieces[i].ohdId != null &&
                        model.pieces[i].ohdId == selectedOhdId,
                    onTap: onSelected == null
                        ? null
                        : () => onSelected!(model.pieces[i].ohdId),
                  ),
                ],
              ],
            ),
    );
  }
}

/// بطاقة قماش واحد: سطر البيانات ثم سطر المسؤولية والمرحلة
/// One fabric card: the data line, then the responsibility and stage line.
class _FabricCard extends StatelessWidget {
  final CuttingPieceItem piece;
  final bool selected;
  final VoidCallback? onTap;

  const _FabricCard({
    required this.piece,
    required this.selected,
    this.onTap,
  });

  /// أوزان السطر الأول: رقم الطلب وافر لأن قيمه الحقيقية تبلغ 11 رقماً
  /// First-line weights: the order id gets room because its live values run to 11 digits.
  static const List<double> _firstWeights = [2.2, 2.6, 0.9,0.9, 0.9, 1.0, 1.3];
  static const List<String> _firstLabels = [
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
    final tone = selected ? AppColors.primary : AppColors.accentLight;
    // خلايا الصف الثاني وأوزانها تُحسب مرة واحدة هنا، فلا يقرأ البناء أوزاناً قديمة
    // The second-row cells and weights are computed once here, so the build never reads stale ones.
    final (secondWeights, secondCells) = _secondRow();
    final values = <String?>[
      piece.ohdId?.toString() ?? '${piece.seqNo1}',
      piece.clothName,
      // العرض رقم (58/45/38) من MULTI_CLOTHS، وبغيابه يعود وصف القماش بدل خانة فارغة
      // The width is the number (58/45/38) from MULTI_CLOTHS; when it is absent the cloth
      // description is shown instead of an empty cell.
      piece.clothWidth ?? piece.clothType,
      // اللون النصّي إن وُجد، وإلا رقم اللون كما تخزّنه القاعدة (CLOTHS_COLOR)
      // The colour text when present, otherwise the stored colour number (CLOTHS_COLOR).
      piece.colorText ?? piece.colorNo?.toString(),
      tailoringNumber(piece.hinsh),
      tailoringNumber(piece.yards),
      // السعر صفر يعني «غير مسعّر» لا «مجاناً»: تُعرض شرطة بدل رقم مضلّل
      // A zero price means "not priced", not "free": a dash replaces the misleading number.
      (piece.price == null || piece.price == 0)
          ? null
          : tailoringNumber(piece.price, decimals: 2),
    ];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? tone.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? tone : tone.withValues(alpha: 0.45),
              width: selected ? 1.6 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: tone.withValues(alpha: selected ? 0.16 : 0.10),
                padding: EdgeInsets.zero,
                child: TailoringCellRow(
                  weights: _firstWeights,
                  cells: [
                    for (var i = 0; i < values.length; i++)
                      TailoringCell(
                        compact: true,
                        label: _firstLabels[i],
                        value: values[i],
                        numeric: i != 1 && i != 3,
                        valueColor: i == 6 ? AppColors.primary : null,
                      ),
                  ],
                ),
              ),
              Container(height: 1.2, color: tone.withValues(alpha: 0.45)),
              Padding(
                padding: EdgeInsets.zero,
                child: TailoringCellRow(
                  weights: secondWeights,
                  cells: secondCells,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stageColor(CuttingPieceStage stage) => switch (stage) {
    CuttingPieceStage.delivered => AppColors.success,
    CuttingPieceStage.tailored => AppColors.info,
    CuttingPieceStage.cut => AppColors.warning,
    CuttingPieceStage.waiting => AppColors.textSecondary,
  };

  /// خلايا الصف الثاني وأوزانها معاً — تُبنى ديناميكياً لأن الحقل الفارغ لا يظهر إطلاقاً،
  /// فعدد الأعمدة يتغيّر من قطعة لأخرى ويُدوَّر معه التوزيع. الإرجاع كسجل واحد لأن
  /// الأوزان والخلايا يجب أن يَبقَيا بنفس الطول دائماً.
  /// The second-row cells and weights together — built dynamically because an empty field never
  /// shows, so the column count varies per piece and the spread follows it. They are returned as
  /// one record because the weights and the cells must always share the same length.
  (List<double>, List<TailoringCell>) _secondRow() {
    final cells = <TailoringCell>[];
    final weights = <double>[];

    void add(double weight, TailoringCell cell) {
      weights.add(weight);
      cells.add(cell);
    }

    // نوع التجهيز: نص القاعدة كما هو (`FIXED_FLEXED`) — لا يظهر إن غاب
    // Preparation type: the stored FIXED_FLEXED text — hidden when absent.
    if ((piece.fixType ?? '').trim().isNotEmpty) {
      add(
        1.7,
        TailoringCell(
          compact: true,
          label: 'نوع التجهيز',
          value: piece.fixType,
          icon: Icons.category_rounded,
        ),
      );
    }

    // رقم التطريز (`ENTRY_NO`) — لا يظهر إن غاب
    // The embroidery number (ENTRY_NO) — hidden when absent.
    if (piece.embroideryNo != null) {
      add(
        1.2,
        TailoringCell(
          compact: true,
          label: 'رقم التطريز',
          value: '${piece.embroideryNo}',
          numeric: true,
        ),
      );
    }

    // خبنة دبل: علامة صح عند 1، والعمود يختفي كلياً عند 0 أو الغياب
    // Double habna: a check when 1, and the whole column disappears at 0 or when absent.
    if (piece.hasDoubleHabna) {
      add(
        1.0,
        TailoringCell(
          compact: true,
          label: 'خبنة دبل',
          value: '✓',
          valueColor: AppColors.success,
        ),
      );
    }

    piece.cutterName != null?add(
      1.9,
      TailoringCell(
        compact: true,
        label: 'القصّاص',
        value: piece.cutterName,
        icon: Icons.content_cut_rounded,
      ),
    ):null;
    piece.hasTailor?add(
      1.9,
      TailoringCell(
        compact: true,
        label: 'الخيّاط',
        // «غير مسند» لا «—»: غير المسند حالة إنتاجية لا معلومة ناقصة
        // "Unassigned" is a production state, not a missing value.
        value: piece.hasTailor ? piece.tailorName : 'غير مسند',
        icon: Icons.design_services_rounded,
        valueColor: piece.hasTailor ? null : AppColors.textSecondary,
      ),
    ):Null;
    add(
      1.3,
      TailoringCell(
        compact: true,
        label: 'المرحلة',
        value: piece.stage.label,
        valueColor: _stageColor(piece.stage),
      ),
    );

    return (weights, cells);
  }
}
