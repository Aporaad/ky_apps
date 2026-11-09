import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// إطار موحّد لكل أقسام شاشة الاستعراض: عنوان بأيقونة + محتوى
/// The unified frame of every section on the view screen: an icon+title bar and content.
///
/// توحيد الإطار يعني أن الأقسام الثمانية تُقرأ كسجل واحد لا كثمانية صُنعها أشخاص مختلفون.
/// The shared frame makes the eight sections read as one record rather than eight hand-built boxes.
class TailoringSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  /// عنصر إضافي في شريط العنوان (شارة عدد، زر صغير…)
  /// An extra item in the title bar (a count chip, a small button…).
  final Widget? trailing;

  /// عنصر يلتصق بالعنوان مباشرةً (اسم العميل بجانب «بيانات العميل»)
  /// An item glued to the title itself (the customer's name beside "بيانات العميل").
  final Widget? titleTrailing;

  /// لون التمييز — يتغيّر ليدل على نوع القسم (مال، مواصفات، حركة…)
  /// The accent colour, signalling the section's nature (money, specs, movement…).
  ///
  /// `null` يعني اللون الأساسي للحظة الرسم، لأن اللون الأساسي ديناميكي ولا يصلح قيمةً افتراضية
  /// `const`. `null` means the primary colour at paint time, because that colour is dynamic and
  /// cannot be a `const` default value.
  final Color? accent;

  const TailoringSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.titleTrailing,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            // شريط عنوان بسطر واحد وحشو رأسي 5 فقط بدل 9
            // A single-line title bar padded 5 vertically instead of 9.
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(color: accent.withValues(alpha: 0.18)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                // العنوان وما يلتصق به داخل مساحة مرنة واحدة: لا تجاوز على أي عرض
                // The title and whatever is glued to it live in one flexible space, so no
                // width can overflow.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ),
                      if (titleTrailing != null) ...[
                        const SizedBox(width: 8),
                        Flexible(child: titleTrailing!),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  // سقف عرض للذيل مع تصغير تلقائي: الشارة لا تدفع السطر إلى التجاوز
                  // عند تكبير الخط
                  // A width cap with automatic scaling: the chip never pushes the row into
                  // overflow when the text scale grows.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 168),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 5, 7, 7),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// خانة حقل: التسمية في سطرها والقيمة تحتها
/// A field cell: the label on its own line, the value beneath it.
///
/// الترتيب فوق/تحت يضمن أن الخانات المتجاورة تبدأ من خطّ واحد وتنتهي عند خطّ واحد، فالصف
/// المكوّن من ست خانات يبدو جدولاً منضبطاً لا نصوصاً متفرّقة. القصّ على سطر واحد يمنع أي
/// تجاوز أفقي عند أضيق الشاشات.
/// The stacked order keeps neighbouring cells starting and ending on the same lines, so a row
/// of six cells reads as a tidy table rather than scattered text. Single-line truncation
/// removes any horizontal overflow on the narrowest screens.
class TailoringInfoTile extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;
  final Color? valueColor;

  /// بقيت للتوافق: الشبكة الجديدة تحكم عرض الخانة بأعمدتها المتساوية
  /// Kept for compatibility: the new grid gives every cell an equal column width.
  final bool fullWidth;

  const TailoringInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    // تسمية واضحة: ثانوي غامق + وزن ثقيل يكسر بهتان السابق
                    // A clear label: a dark secondary tone with a heavy weight instead of
                    // the previous faded look.
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }
}

/// شبكة حقول متناظرة: أعمدة متساوية العرض تفصل بينها خطوط رقيقة
/// A symmetrical field grid: equal-width columns separated by hairline dividers.
///
/// الخانات تُوزَّع على عدد أعمدة ثابت لكل صف، فلا يبقى فراغ متبقٍّ في نهاية السطر (وهو ما
/// كان يبدو عشوائياً في التوزيع السابق). عدد الأعمدة يتبع العرض المتاح، و`singleRow` تطلب
/// صفاً واحداً عندما يتّسع المكان لكل الخانات.
/// Cells are spread over a fixed column count per row, so no ragged gap is left at the end of
/// a row (which is what looked random before). The column count follows the available width,
/// and `singleRow` asks for one line when the space can hold every cell.
class TailoringInfoGrid extends StatelessWidget {
  final List<Widget> children;

  /// أقل عرض مقبول للخانة — يحدّد عدد الأعمدة على الشاشات الضيقة
  /// The smallest acceptable cell width — decides the column count on narrow screens.
  final double minCellWidth;

  /// تطلب صفاً واحداً على الشاشات العريضة (العميل، الدفع…)
  /// Asks for a single row on wide screens (customer, payment…).
  final bool singleRow;

  /// عدد صفوف مطلوب: يُحسب عدد الأعمدة منه (صفّان لبيانات الفاتورة مثلاً)
  /// A required row count: the column count is derived from it (two rows for the bill data).
  final int? rows;

  const TailoringInfoGrid({
    super.key,
    required this.children,
    this.minCellWidth = 112,
    this.singleRow = false,
    this.rows,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final width = constraints.maxWidth;
        final count = children.length;

        // صف واحد إن اتّسع لكل خانة بحد أدنى مقبول، وإلا أعمدة متساوية حسب العرض
        // One row when every cell still gets a readable minimum, otherwise equal columns.
        var columns = (width / minCellWidth).floor().clamp(1, count);
        if (singleRow && width >= 600) {
          final fitsOneRow = (width / 76).floor();
          if (fitsOneRow >= count) columns = count;
        }

        // صفوف مطلوبة صراحةً: عدد الأعمدة هو ما يجعلها كذلك
        // Explicitly required rows: the column count is what produces them.
        final wantedRows = rows;
        if (wantedRows != null && wantedRows > 0) {
          columns = (count / wantedRows).ceil().clamp(1, count);
        }

        final rowWidgets = <Widget>[];
        for (var start = 0; start < count; start += columns) {
          final cells = children.sublist(
            start,
            (start + columns).clamp(0, count),
          );
          rowWidgets.add(_row(cells, columns));
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            // إطار وفواصل أوضح: حدّ 0.9 بشفافية كاملة ليفصل الحقول بصرياً
            // A clearer frame and dividers: 0.9px at full opacity to separate the fields.
            border: Border.all(color: AppColors.border, width: 0.9),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rowWidgets.length; i++) ...[
                if (i > 0) _divider(horizontal: true),
                rowWidgets[i],
              ],
            ],
          ),
        );
      },
    );
  }

  /// صف واحد: خانات متساوية العرض بينها فواصل رأسية
  /// One row: equal-width cells with vertical dividers between them.
  Widget _row(List<Widget> cells, int columns) {
    final widgets = <Widget>[];

    for (var i = 0; i < cells.length; i++) {
      widgets.add(Expanded(child: cells[i]));
      if (i != cells.length - 1) widgets.add(_divider(horizontal: false));
    }

    // الخانات الناقصة في الصف الأخير تُملأ بفراغ كي لا تتمدد الخانات السابقة
    // The short last row is padded so its cells do not stretch.
    for (var i = cells.length; i < columns; i++) {
      widgets.add(Expanded(child: SizedBox()));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      ),
    );
  }

  Widget _divider({required bool horizontal}) {
    // فاصل واضح بلون الحدّ الكامل بدل خطّ شبه شفاف لا يُرى
    // A visible divider in the full border colour instead of an almost invisible line.
    final color = AppColors.border;
    return horizontal
        ? Container(height: 0.9, color: color)
        : Container(width: 0.9, color: color);
  }
}

/// شارة نصية صغيرة
/// A small text chip.
class TailoringChip extends StatelessWidget {
  final String label;
  final String? value;

  /// لون الشارة؛ `null` يعني اللون الأساسي للحظة الرسم
  /// The chip's colour; `null` means the primary colour at paint time.
  final Color? color;

  const TailoringChip({
    super.key,
    required this.label,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.primary;
    final text = value == null || value!.trim().isEmpty
        ? label
        : '$label: ${value!.trim()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          // شارة أوضح: حجم أكبر ووزن أثقل ليقاوم الخلفية الفاتحة
          // A clearer chip: a larger size and a heavier weight against the light tint.
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
