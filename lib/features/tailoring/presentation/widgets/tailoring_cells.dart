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

  /// وضع مدمج: تسمية في سطر واحد تُصغَّر لتتّسع، وحشو أقل، وقيمة أصغر — يُزيل الفراغ
  /// الميّت أسفل الخلايا ويقلّص ارتفاع البطاقة
  /// A compact mode: a single-line label that scales to fit, tighter padding and a smaller
  /// value — it removes the dead space under the cells and shortens the card.
  final bool compact;

  const TailoringCell({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.numeric = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!.trim();
    final isBlank = text == '—';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 3 : 4,
        vertical: compact ? 2 : 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: compact ? 9 : 10,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 2),
              ],
              // التسمية في سطر واحد دائماً: تُصغَّر بدل أن تلتفّ فتُطيل الخانة
              // The label is always one line: it shrinks instead of wrapping and stretching the cell.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: compact ? 8.5 : 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 1 : 2),
          // heightFactor: 1 يمنع الخلية من التمدد رأسياً لتملأ ارتفاع الصف — فالارتفاع
          // يتبع المحتوى فقط ولا يبقى فراغ أسفل النص
          // heightFactor: 1 stops the cell from stretching to the row's height, so the height
          // follows the content only and no empty band is left under the text.
          Align(
            heightFactor: 1,
            alignment:
                numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
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
    // `Table` تحسب ارتفاع الصف من محتواه: لا تمدد رأسياً ولا فراغ أسفل الخلايا،
    // وحدودها ترسم الفواصل الرأسية بطول الصف كاملاً.
    // A Table sizes the row to its content: no vertical stretching and no empty band under the
    // cells, while its border draws the vertical rules across the full row height.
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: {
        for (var i = 0; i < cells.length; i++)
          i: FlexColumnWidth(weights[i]),
      },
      border: TableBorder(
        verticalInside: BorderSide(color: tailoringGridRule, width: 1),
      ),
      children: [TableRow(children: cells)],
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

        // جدول واحد لكل الشبكة: ارتفاع كل صف من محتواه فقط، والفواصل أفقياً ورأسياً
        // A single table for the whole grid: each row is as tall as its content and the rules are
        // drawn both ways.
        final tableRows = <TableRow>[];
        for (var start = 0; start < cells.length; start += columns) {
          final slice = cells.sublist(
            start,
            (start + columns).clamp(0, cells.length),
          );
          tableRows.add(
            TableRow(
              children: [
                for (final cell in slice) cell,
                for (var i = slice.length; i < columns; i++)
                  const SizedBox.shrink(),
              ],
            ),
          );
        }

        return Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          columnWidths: {
            for (var i = 0; i < columns; i++) i: const FlexColumnWidth(1),
          },
          border: TableBorder.all(
            color: tailoringGridRule,
            width: 1,
            borderRadius: BorderRadius.circular(9),
          ),
          children: tableRows,
        );
      },
    );
  }
}

/// لون فواصل الشبكة — رمادي مزرق واضح على الأبيض، كقاعدة طقم المقاسات
/// The grid rule colour: a blue-grey that is visible on white, matching the measurements kit.
Color get tailoringGridRule => AppColors.secondary.withValues(alpha: 0.35);
