import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_piece_item.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_section_card.dart';

/// القسم 7: أقمشة الموديل المختار — صف لكل قطعة (ثوب)
/// Section 7: the selected model's fabrics — one row per piece.
///
/// عملية على الحاسب، وبطاقات على الجوال: جدول بـ 12 عموداً على شاشة هاتف يحتاج تمريراً
/// أفقياً يخفي هوية القطعة، فالبطاقة تحفظ الربط بين القماش وصاحبه ومرحلته.
/// A table on desktop and cards on mobile: a 12-column table on a phone forces horizontal
/// scrolling that hides the piece's identity, so the card keeps fabric, assignee and stage together.
class ModelFabricsTable extends StatelessWidget {
  final CuttingModelItem model;

  const ModelFabricsTable({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return TailoringSectionCard(
      title: 'الأقمشة — موديل ${model.seqNo}',
      icon: Icons.dry_cleaning_rounded,
      accent: AppColors.accentLight,
      trailing: TailoringChip(
        label: '${model.piecesCount} قطعة',
        color: AppColors.accent,
      ),
      child: model.pieces.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'لا توجد قطع مسجّلة لهذا الموديل',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          : LayoutBuilder(
              builder: (ctx, constraints) {
                // صف أفقي لكل قطعة في كل الأحجام: البطاقات على الجوال كانت تضاعف الارتفاع
                // وتكسر محاذاة الأعمدة، والجدول يُقرأ سطراً بسطر كما يطلب المستخدم.
                // One horizontal row per piece at every size: the mobile cards doubled the
                // height and broke column alignment, while the table reads line by line.
                const minWidth = 760.0;
                final width = constraints.maxWidth < minWidth
                    ? minWidth
                    : constraints.maxWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: width, child: _buildTable()),
                );
              },
            ),
    );
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(
        color: AppColors.border,
        width: 0.7,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FixedColumnWidth(46),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.1),
        4: FixedColumnWidth(48),
        5: FixedColumnWidth(48),
        6: FlexColumnWidth(1.3),
        7: FixedColumnWidth(52),
        8: FlexColumnWidth(1.4),
        9: FlexColumnWidth(1.4),
        10: FixedColumnWidth(64),
        11: FixedColumnWidth(76),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceSubtle),
          children: [
            _th('#'),
            _th('القماش'),
            _th('النوع'),
            _th('اللون'),
            _th('هنش'),
            _th('يارد'),
            _th('المصدر'),
            _th('الرف'),
            _th('القصّاص'),
            _th('الخيّاط'),
            _th('السعر'),
            _th('المرحلة'),
          ],
        ),
        for (var i = 0; i < model.pieces.length; i++)
          TableRow(
            // تخطيط الصفوف بالتناوب: يفصل الأقمشة البصرية بلا حدود إضافية
            // Alternating row striping separates the fabrics visually without extra borders.
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFBFC),
            ),
            children: [
              _td('${model.pieces[i].seqNo1}'),
              _td(model.pieces[i].clothName ?? '—'),
              _td(model.pieces[i].clothType ?? '—'),
              _td(model.pieces[i].colorText ?? '—'),
              _td(tailoringNumber(model.pieces[i].hinsh)),
              _td(tailoringNumber(model.pieces[i].yards)),
              _td(model.pieces[i].sourceLabel.isEmpty ? '—' : model.pieces[i].sourceLabel),
              _td(model.pieces[i].shelfNo ?? '—'),
              _td(model.pieces[i].cutterName ?? '—'),
              // الخيّاط غير المسند يُكتب «غير مسند» بدل شرطة: الشرطة تُقرأ «لا بيانات»
              // An unassigned tailor reads "غير مسند" rather than a dash, which reads as "no data".
              _td(model.pieces[i].hasTailor ? model.pieces[i].tailorName! : 'غير مسند'),
              _td(tailoringNumber(model.pieces[i].price)),
              _stageCell(model.pieces[i].stage),
            ],
          ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _td(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _stageCell(CuttingPieceStage stage) {
    final color = stageColor(stage);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            stage.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// لون المرحلة الموحّد بين الجدول والبطاقات
/// The stage colour, unified between the table and the cards.
Color stageColor(CuttingPieceStage stage) => switch (stage) {
  CuttingPieceStage.delivered => AppColors.success,
  CuttingPieceStage.tailored => AppColors.info,
  CuttingPieceStage.cut => AppColors.warning,
  CuttingPieceStage.waiting => AppColors.textMuted,
};
