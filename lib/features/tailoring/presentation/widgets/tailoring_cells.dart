import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// خلية حقل بنفس روح طقم شاشة «مقاسات العملاء» لكن بخطوط أكبر وأثقل
/// A field cell in the spirit of the measurements kit but with larger, heavier type.
///
/// التسمية `textSecondary` بوزن 700 والقيمة `textPrimary` بوزن 900 أكبر بثلاث درجات، والقيمة
/// تُصغَّر تلقائياً (`FittedBox`) عند ضيق الخانة بدل أن تُقصّ — فلا معلومة تختفي على أي عرض.
/// The label is `textSecondary` at w700 and the value `textPrimary` at w900, three steps larger;
/// the value scales down instead of being cut, so no information disappears at any width.
class TailoringCell extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final Color? valueColor;

  /// محاذاة الأرقام إلى نهاية الخانة حتى تُقرأ الأعمدة تقميماً
  /// Numbers align to the cell's end so a column of figures reads like a column.
  final bool numeric;

  const TailoringCell({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!.trim();
    final isBlank = text == '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 10, color: AppColors.textSecondary),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                    height: 0.8,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment:
                numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isBlank
                      ? AppColors.textMuted
                      : (valueColor ?? AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// صف أعمدة بأوزانها وخطوط فاصلة — كل الأعمدة داخل عرض الشاشة بلا تمرير أفقي
/// A weighted row with rule separators — every column inside the screen width, no horizontal scroll.
class TailoringCellRow extends StatelessWidget {
  final List<TailoringCell> cells;
  final List<double> weights;

  const TailoringCellRow({
    super.key,
    required this.cells,
    required this.weights,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (var i = 0; i < cells.length; i++) {
      if (i > 0) children.add(Container(width: 1, color: tailoringGridRule));
      children.add(
        Expanded(flex: (weights[i] * 10).round(), child: cells[i]),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// شبكة خانات متساوية العرض بفواصل رأسية وأفقية ظاهرة
/// An equal-width cell grid with visible vertical and horizontal rules.
class TailoringCellGrid extends StatelessWidget {
  final List<TailoringCell> cells;

  /// أقل عرض للخانة — يحدّد عدد الأعمدة
  /// The minimum cell width — it decides the column count.
  final double minCellWidth;

  /// صف واحد عند اتساع المكان لكل الخانات
  /// One row when the width can hold every cell.
  final bool singleRow;

  /// عدد صفوف مطلوب صراحةً
  /// An explicitly required row count.
  final int? rows;

  const TailoringCellGrid({
    super.key,
    required this.cells,
    this.minCellWidth = 70,
    this.singleRow = false,
    this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;

        var columns = (width / minCellWidth).floor().clamp(1, cells.length);
        if (singleRow && width >= 600) {
          final fits = (width / 78).floor();
          if (fits >= cells.length) columns = cells.length;
        }
        final wanted = rows;
        if (wanted != null && wanted > 0) {
          columns = (cells.length / wanted).ceil().clamp(1, cells.length);
        }

        final rowWidgets = <Widget>[];
        for (var start = 0; start < cells.length; start += columns) {
          rowWidgets.add(
            _row(
              cells.sublist(start, (start + columns).clamp(0, cells.length)),
              columns,
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: tailoringGridRule, width: 1.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rowWidgets.length; i++) ...[
                if (i > 0) Container(height: 0.1, color: tailoringGridRule),
                rowWidgets[i],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(List<TailoringCell> rowCells, int columns) {
    final children = <Widget>[];

    for (var i = 0; i < rowCells.length; i++) {
      if (i > 0) children.add(Container(width: 1, color: tailoringGridRule));
      children.add(Expanded(child: rowCells[i]));
    }

    for (var i = rowCells.length; i < columns; i++) {
      children.add(const Expanded(child: SizedBox()));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// لون فواصل الشبكة — رمادي مزرق واضح على الأبيض، كقاعدة طقم المقاسات
/// The grid rule colour: a blue-grey that is visible on white, matching the measurements kit.
Color get tailoringGridRule => AppColors.secondary.withValues(alpha: 0.35);
