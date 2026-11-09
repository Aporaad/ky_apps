import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/report_columns.dart';

/// جدول تقرير المخازن — كامل السطور في تدفق الصفحة، بلا صندوق ثابت ولا تمرير داخلي
/// The stores-report table: every row inside the page's own flow — no fixed box, no inner scroll.
///
/// ── لماذا لا `LazyReportTable`؟ لأنه يعطي السطور صندوقًا بارتفاع ثابت يتمرّر داخله، فتضيع
///    بقية السجل عن النظر ويُقصّ المستند. المطلوب أن يتمدّد الجدول على قدر صفوفه وأن يتحرّك
///    القارئ مع الصفحة نفسها، لا مع نافذة داخلها.
/// ── Why not `LazyReportTable`? It gives the rows a fixed-height box that scrolls inside it, so
///    the rest of the record stays out of sight and the document is cut short. The table must
///    grow with its own rows and move with the page, not with a window inside the page.
///
/// ── الذاكرة تظل محفوظة: الصفوف تُبنى على دفعات ويُوسَّع النطاق تلقائياً كلما اقترب القارئ
///    من الأسفل، فلا آلاف الخلايا تُبنى دفعة واحدة (سبب قتل التطبيق المعروف في القسم).
/// ── Memory stays bounded: rows are built in batches and the range grows automatically as the
///    reader nears the bottom, so thousands of cells are never built at once — the known cause
///    of killed apps in this module.
class ReportDataTable<T> extends StatefulWidget {
  const ReportDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.opening,
    this.totals,
  });

  final List<ReportColumn<T>> columns;
  final List<T> rows;

  /// سطر «رصيد سابق» أول الجدول فوق أول حركة — به يبدأ عمود الرصيد فعلياً من رصيد
  /// الفترة السابقة لا من أول حركة فيها.
  /// The «رصيد سابق» line above the first movement — the running balance column visibly
  /// starts on the period's opening balance instead of on its first movement.
  ///
  /// ── بمعرّفات الأعمدة كسطر التجميع: العمود الذي يقرأه المستخدم هو نفسه الذي يحمل الرقم،
  ///    فإخفاء عمود أو إعادة ترتيبه لا يزيح الرصيد عن مكانه.
  /// ── Keyed by column id exactly like the totals row: the column the user reads is the one
  ///    carrying the figure, so hiding or reordering a column never moves the balance.
  final Map<String, String>? opening;

  /// سطر التجميع في نهاية الجدول — بمعرّفات الأعمدة، وما لا مجموع له يبقى فارغاً
  /// The totals row at the table's end — keyed by column id; anything without a meaningful
  /// total stays blank rather than carrying a made-up figure.
  final Map<String, String>? totals;

  @override
  State<ReportDataTable<T>> createState() => _ReportDataTableState<T>();
}

class _ReportDataTableState<T> extends State<ReportDataTable<T>> {
  /// حجم الدفعة — 120 صفاً يظل خفيفاً ويملأ شاشة الهاتف أكثر من مرة
  /// Batch size — 120 rows stays light yet fills a phone screen more than once.
  static const int _chunk = 120;

  /// متى نضيف دفعة قبل أن يصل القارئ إلى النهاية تمامًا
  /// How far before the bottom the next batch is added.
  static const double _preload = 600;

  int _built = _chunk;
  ScrollPosition? _position;

  @override
  void initState() {
    super.initState();

    // السجلات الصغيرة هي الغالب على كشوف الفروع: لا سبب لبناء دفعة كاملة عند فتح الشاشة
    // Small records are the norm for branch statements: there is no reason to aim for a full
    // batch when the screen opens.
    _built = math.min(_chunk, widget.rows.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // الجدول لا يملك التمرير: يركب على تمرير الصفحة التي هو داخلها
    // The table owns no scrolling; it rides the page's scroll position it sits inside.
    final next = Scrollable.maybeOf(context)?.position;

    if (!identical(next, _position)) {
      _position?.removeListener(_onScroll);
      _position = next;
      _position?.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(ReportDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // صفوف جديدة أو أعمدة جديدة = منظر جديد: لا يُعقل أن يبقى مقصوصاً عند الدفعة القديمة
    // Fresh rows or fresh columns are a new view: it must not stay clipped at the old batch.
    if (!identical(oldWidget.rows, widget.rows) ||
        !identical(oldWidget.columns, widget.columns)) {
      _built = math.min(_chunk, widget.rows.length);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final position = _position;

    if (position == null || _built >= widget.rows.length) return;

    if (position.pixels + _preload >= position.maxScrollExtent) {
      setState(() {
        _built = math.min(_built + _chunk, widget.rows.length);
      });
    }
  }

  /// عروض الأعمدة بالبكسل — تُحسب مرة واحدة من عرض الجدول نفسه
  /// The column widths in pixels — computed once from the table's own width.
  ///
  /// ── لماذا بكسلات محسوبة لا `FlexColumnWidth`؟ لأن كل كتلة (الرأس والافتتاح والسطور
  ///    والمجاميع) جدولٌ مستقل، و`Flex` يقرّب كسر البكسل في كل كتلة على حدة فينزاح عمود
  ///    بكسل عن عمود. الحساب هنا مرة واحدة، وآخر عمود يأخذ الباقي، فتتوافق الكتل بالبكسل.
  /// ── Why computed pixels rather than `FlexColumnWidth`? Every block (head, opening, body,
  ///    totals) is its own table, and flex rounds the fraction separately in each one, so a
  ///    column drifts a pixel from its neighbour. One calculation here, the last column takes
  ///    the remainder, and the blocks line up to the pixel.
  List<double> _columnWidths(double width) {
    final columns = widget.columns;

    if (columns.isEmpty) return const [];

    final total = columns.fold<double>(0, (sum, column) => sum + column.weight);

    // المفتاح: العرض + أوزان الأعمدة نفسها. إخفاء عمود أو إعادة ترتيبه يغيّر الوزن فيُعاد الحساب
    // The key: the width plus the columns' own weights. Hiding or reordering a column changes
    // the weights, so the calculation is redone instead of serving a stale layout.
    final caption = '$width—${columns.map((column) => column.weight).join(',')}';

    final cached = _widthCache;
    if (cached != null && cached.$1 == caption) return cached.$2;

    final widths = <double>[];
    var used = 0.0;

    for (int i = 0; i < columns.length; i++) {
      final isLast = i == columns.length - 1;
      final share = total <= 0
          ? width / columns.length
          : width * columns[i].weight / total;

      // الحصة الأخيرة تستوعب الباقي: مجموع العروض = عرض الجدول بلا كسر ضائع
      // The final share absorbs the remainder: the widths add up to the table's width.
      final value = isLast
          ? math.max(width - used, _minColumn)
          : math.max(share.floorToDouble(), _minColumn);

      widths.add(value);
      used += value;
    }

    _widthCache = (caption, widths);
    return widths;
  }

  /// حدّ أدنى لعمود واحد — تحته لا يظهر حرف أصلاً
  /// A floor for one column — below it not a single letter fits.
  static const double _minColumn = 16;

  /// مفتاح آخر حساب + نتيجته: إعادة الحساب عند كل دفعة تُبطئ التمرير بلا فائدة
  /// The last calculation's key and result: recomputing on every batch slows the scroll.
  (String, List<double>)? _widthCache;

  Map<int, TableColumnWidth> _widthsFor(List<double> widths) {
    return {
      for (int i = 0; i < widths.length; i++) i: FixedColumnWidth(widths[i]),
    };
  }

  /// نسبة تصغير موحّدة: أصغر نسبة تجعل كل عنوان رأس وكل رقم تجميع في سطر واحد
  /// A single shrink ratio: the smallest one that keeps every heading and every aggregate
  /// on one line inside its own cell.
  ///
  /// ── القياس على الرأس والمجاميع لا على كل سطر: القيمة الشاذة الطويلة في سطر واحد يجب أن
  ///    تصغُر هي وحدها، لا أن تصغُر معها كل أرقام التقرير.
  /// ── Measuring the headings and the aggregates, not every row: one freakishly long value
  ///    must shrink alone, never drag the whole report's figures down with it.
  double _fitFactor({
    required BuildContext context,
    required double width,
    required double fontSize,
    required double padding,
  }) {
    final columns = widget.columns;

    if (columns.isEmpty) return 1;

    final total = columns.fold<double>(0, (sum, column) => sum + column.weight);
    final scaler = MediaQuery.textScalerOf(context);
    final family = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    var fit = 1.0;

    for (final column in columns) {
      final budget = (total <= 0 ? width / columns.length : width * column.weight / total)
          - (padding * 2)
          - 1;

      if (budget <= 0) return _minFit;

      final probes = <String>[
        column.label,
        if (widget.totals?[column.id] != null) widget.totals![column.id]!,
        if (widget.opening?[column.id] != null) widget.opening![column.id]!,
      ];

      for (final probe in probes) {
        final text = probe.trim();

        if (text.isEmpty) continue;

        final need = _measure(text, fontSize, family, scaler);

        if (need <= budget) continue;

        final ratio = budget / need;

        if (ratio < fit) fit = ratio;
      }
    }

    return fit;
  }

  /// أدنى تصغير مسموح — تحته يصبح النص زينة لا معلومة، والخانة الضيقة تُعالَج بالقصّ اللطيف
  /// The smallest allowed shrink — below it text is decoration, and a tight cell is handled
  /// by the per-cell gentle scale-down instead.
  static const double _minFit = 0.62;

  /// عرض نص واحد بخط الجدول — قياس فعلي لا تقدير بعدد الحروف
  /// One text's width at the table's font — a real measurement, not a letter-count guess.
  ///
  /// ── هامش 6% فوق المقاس: تقدير الخط قد يختلف عن الخط المرسوم فعلاً عند غياب الخط المضمّن
  /// ── A 6% margin over the measured width: the fallback face can differ from the one drawn.
  double _measure(String text, double fontSize, String? family, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: family,
        ),
      ),
      textDirection: TextDirection.rtl,
      textScaler: scaler,
      maxLines: 1,
    )..layout();

    final width = painter.width;
    painter.dispose();

    return width * 1.06;
  }

  @override
  Widget build(BuildContext context) {
    // ── لا عرض لانهائي هنا: لا `SingleChildScrollView` أفقي يهدي `Table` عرضًا بلا نهاية
    //    فينهار التخطيط — الجدول يأخذ عرض الصفحة دائمًا ويتكيّف مقياس الخط معه.
    // ── No infinite width here: no horizontal viewport feeding `Table` an endless width and
    //    crashing the layout. The table always takes the page's width and the type scale adapts.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 720.0;

        // مقياس واحد للجدول كله: العنوان والرقم بحجم واحد، ويصغُر الجميع معاً حين تضيق الخانة
        // — فتبقى الصفوف متساوية بدل أن يتشوّه عنوان أو يتكسّر رقم على سطرين.
        // One scale for the whole table: caption and figure share a size, and the whole table
        // shrinks together when a cell is tight — so rows stay equal instead of a heading
        // deforming or a figure splitting across two lines.
        final styles = _Styles.forTable(
          width: width,
          columnCount: widget.columns.length,
          scaler: MediaQuery.textScalerOf(context),
          fit: (fontSize, padding) => _fitFactor(
            context: context,
            width: width,
            fontSize: fontSize,
            padding: padding,
          ),
        );

        final widths = _columnWidths(width);

        // الدفعة لا تتجاوز الموجود: وإلا قُرىء فهرس خارج الصفوف وانفجر RangeError
        // A batch never exceeds what exists: otherwise an index past the end is read and
        // RangeError explodes — the crash this guard was written for.
        final shown = math.min(_built, widget.rows.length);
        final blocks = <Widget>[];

        // جدول بلا سطور لكن برصيد سابق (كل حركات القسم خارج المدى) ما زال له رأس وسطر
        // افتتاح: إخفاؤه يوهم بأن القسم غير موجود.
        // A section with no rows but with an opening balance (every movement falls outside
        // the window) still keeps its head and its opening line; hiding them would imply the
        // section does not exist.
        if (shown == 0 && widget.opening != null) {
          blocks.add(
            _block(
              start: 0,
              end: 0,
              styles: styles,
              widths: widths,
              withHead: true,
            ),
          );
        }

        for (int start = 0; start < shown; start += _chunk) {
          final end = math.min(start + _chunk, shown);

          blocks.add(
            _block(
              start: start,
              end: end,
              styles: styles,
              widths: widths,
              // الرأس مرة واحدة في أول الجدول، والملخص مكوّن مستقل بعده
              // The head appears once at the top; the summary is its own component after it.
              withHead: start == 0,
            ),
          );
        }

        if (shown < widget.rows.length) {
          blocks.add(_loadingMore(remaining: widget.rows.length - shown));
        }

        // سطر التجميع آخر ما يُبنى فيبقى آخر ما يُقرأ، فوق أي دفعة لم تُوسَّع بعد
        // The totals row is built last so it reads last, even above a batch not yet expanded.
        if (widget.totals != null) {
          blocks.add(_totalsBlock(styles, widths));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: blocks,
        );
      },
    );
  }

  /// سطر الرصيد السابق — «رصيد سابق» في أول عمود فارغ، والرقم في عمود الرصيد
  /// The opening line — "رصيد سابق" in the first empty column, the figure in the balance column.
  ///
  /// ── نفس قاعدة سطر التجميع: الكلمة في أول خانة لا رقم لها، فلا عمود زائد يُفسد المحاذاة.
  /// ── The same rule as the totals row: the word goes in the first column with no figure, so
  ///    no extra column breaks the grid's alignment.
  TableRow _openingRow(_Styles styles) {
    final opening = widget.opening!;

    final texts = <String>[];
    var labelled = false;

    for (final column in widget.columns) {
      final figure = (opening[column.id] ?? '').trim();

      if (figure.isEmpty && !labelled) {
        labelled = true;
        texts.add('رصيد سابق');
      } else {
        texts.add(figure);
      }
    }

    return TableRow(
      children: [
        for (int i = 0; i < widget.columns.length; i++)
          _Cell(
            text: texts[i],
            styles: styles,
            align: _alignOf(widget.columns[i], header: false),
            ltr: widget.columns[i].numeric,
            weight: FontWeight.w800,
            color: AppColors.textPrimary,
            // لون أفتح من سطر التجميع: السابق مقدّمة لا خلاصة، ولا يجوز أن يبدو خاتمة
            // Lighter than the totals row: an opening is a preface, not a conclusion, and it
            // must not read like the report's last line.
            background: AppColors.border.withValues(alpha: 0.28),
          ),
      ],
    );
  }

  /// سطر المجاميع — نفس عرض الأعمدة وحدودها فتقرأ الصفوف كأنها جدول واحد
  /// The totals row — identical widths and borders, so the blocks still read as one table.
  ///
  /// ── «الإجمالي» يقع في أول عمود لا مجموع له (نوع الحركة أو التاريخ)، فلا نحتاج عموداً
  ///    زائداً يعبث بمحاذاة الجدول كله.
  /// ── "الإجمالي" sits in the first column without a total (type or date), so no extra
  ///    column is needed to break the alignment of the whole grid.
  Widget _totalsBlock(_Styles styles, List<double> widths) {
    final totals = widget.totals!;

    // أول عمود لا مجموع له يحمل كلمة «الإجمالي»، وما بعده أرقام المجاميع فقط
    // The first column with no total carries the word "الإجمالي"; the rest carry figures.
    final texts = <String>[];
    var labelled = false;

    for (final column in widget.columns) {
      final figure = (totals[column.id] ?? '').trim();

      if (figure.isEmpty && !labelled) {
        labelled = true;
        texts.add('الإجمالي');
      } else {
        texts.add(figure);
      }
    }

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.6),
      columnWidths: _widthsFor(widths),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            for (int i = 0; i < widget.columns.length; i++)
              _totalCell(widget.columns[i], texts[i], styles),
          ],
        ),
      ],
    );
  }

  Widget _totalCell(ReportColumn<T> column, String text, _Styles styles) {
    return _Cell(
      text: text,
      styles: styles,
      align: _alignOf(column, header: false),
      ltr: column.numeric,
      weight: FontWeight.w800,
      color: AppColors.primary,
      background: AppColors.primary.withValues(alpha: 0.12),
    );
  }

  Widget _block({
    required int start,
    required int end,
    required _Styles styles,
    required List<double> widths,
    required bool withHead,
  }) {
    final rows = <TableRow>[
      if (withHead)
        TableRow(
          children: [
            for (final column in widget.columns)
              _headCell(column, styles),
          ],
        ),
      // الافتتاح بعد الرأس وقبل أول حركة: هو نقطة الصفر التي يُبنى عليها العمود
      // The opening sits after the head and before the first movement: it is the zero point
      // the whole column is built on.
      if (withHead && widget.opening != null) _openingRow(styles),
      for (int index = start; index < end; index++)
        TableRow(
          children: [
            for (int i = 0; i < widget.columns.length; i++)
              _bodyCell(
                widget.columns[i],
                widget.columns[i].read(widget.rows[index], index),
                styles,
              ),
          ],
        ),
    ];

    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.6),
      columnWidths: _widthsFor(widths),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  Widget _loadingMore({required int remaining}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            '... عرض المزيد — المتبقي $remaining صفاً',
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headCell(ReportColumn<T> column, _Styles styles) {
    return _Cell(
      text: column.label,
      styles: styles,
      align: _alignOf(column, header: true),
      ltr: false,
      weight: FontWeight.w800,
      color: AppColors.primary,
      background: AppColors.primary.withValues(alpha: 0.08),
    );
  }

  Widget _bodyCell(ReportColumn<T> column, String text, _Styles styles) {
    // السالب علامة خطر في المخزون: كمية كانت أو قيمة
    // A negative is the risk mark in inventory: quantity or value alike.
    final isNegative = column.numeric && text.trim().startsWith('-');

    return _Cell(
      text: text,
      styles: styles,
      align: _alignOf(column, header: false),
      ltr: column.numeric,
      weight: isNegative ? FontWeight.w700 : FontWeight.w500,
      color: isNegative ? AppColors.error : AppColors.textPrimary,
    );
  }

  /// محاذاة الخانة: الأرقام من طرف السطر والنصوص من أوّله، والرأس الرقمي في الوسط
  /// The cell's alignment: figures at the line's end and text at its start, while a numeric
  /// heading sits in the middle where the column's figures are read as a block.
  AlignmentGeometry _alignOf(ReportColumn<T> column, {required bool header}) {
    if (!column.numeric) return AlignmentDirectional.centerStart;

    return header
        ? AlignmentDirectional.center
        : AlignmentDirectional.centerEnd;
  }
}

/// خانة الجدول: سطر واحد بارتفاع ثابت، والنص يصغُر ليدخل بدل أن يلتفّ سطرين
/// A table cell: one line of a fixed height, and the text scales down to fit rather than
/// wrapping onto a second line.
///
/// ── لماذا التصغير لا الالتفاف؟ «المستند» تُكسر إلى «المستن» و«د» و«-12,985.76» إلى
///    «-12,985.7» و«6»، فيصير الرأس معطوباً والرقم مقروءاً خطأً. سطر واحد ثابت يبقي
///    الصف منسجماً مهما كبُر الخط أو ضاقت الشاشة.
/// ── Why scale down rather than wrap? A caption breaks into half-words and a figure splits
///    mid-digit, so the head looks corrupted and the number reads wrong. One fixed line keeps
///    every row in step no matter the font size or the screen's width.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.text,
    required this.styles,
    required this.align,
    required this.color,
    required this.weight,
    this.background,
    this.ltr = false,
  });

  final String text;
  final _Styles styles;
  final AlignmentGeometry align;
  final Color color;
  final FontWeight weight;
  final Color? background;

  /// الأرقام تُقرأ من اليسار: «-4,418.39» ولا تُقلب إلى «4,418.39-» مع اتجاه الواجهة
  /// Figures read left-to-right: "-4,418.39", never flipped to "4,418.39-" by the RTL face.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: styles.cellHeight,
      color: background,
      padding: EdgeInsets.symmetric(horizontal: styles.padding),
      alignment: align,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: align,
        child: Text(
          text,
          // سطر واحد دائماً: لا التفاف، ولا سطر ثانٍ يُفسد تناسق الصف
          // Always one line: no wrapping and no second line to unbalance the row.
          maxLines: 1,
          softWrap: false,
          textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
          style: TextStyle(
            fontSize: styles.fontSize,
            fontWeight: weight,
            color: color,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}

/// مقياس الجدول المشتق من عرض الشاشة وعدد الأعمدة ومقياس خط النظام
/// The table's metrics derived from the screen width, the column count and the platform's
/// text scale.
///
/// ── لا بكسلات ثابتة: عمودان على هاتف وثمانية عشر على تقرير واحد — العرض يقسم والأرقام
///    تتبع، فلا يضيع حرف ولا يحتاج القارئ تمريرًا جانبيًا.
/// ── No fixed pixels: two columns on a phone and eighteen in one report — the width is split
///    and the figures follow, so nothing is lost and no sideways scroll is ever needed.
///
/// ── ومقياس الخط يدخل في الحساب: تكبير خط النظام يكبّر الحرف، فإن لم يتّسع له العمود صغُر
///    الحجم قبل الرسم بدل أن يُكسر النص على سطرين ويختلّ الصف.
/// ── The text scale is part of the calculation: enlarging the system font enlarges the glyph,
///    and when a column cannot hold it the size is reduced before drawing rather than letting
///    the text wrap onto a second line and unbalance the row.
class _Styles {
  const _Styles._({
    required this.fontSize,
    required this.padding,
    required this.scaler,
  });

  /// مقياس الجدول من الحدّ الأعلى الذي يسمح به العرض، مصغّراً بنسبة الاتّساع الفعلية
  /// The table's scale from the widest the width allows, shrunk by the real fitting ratio.
  factory _Styles.forTable({
    required double width,
    required int columnCount,
    required TextScaler scaler,
    required double Function(double fontSize, double padding) fit,
  }) {
    final base = _pickFont(width, columnCount);
    final padding = _pickPadding(width, columnCount);
    final ratio = fit(base, padding).clamp(_minFit, 1.0);

    return _Styles._(
      fontSize: base * ratio,
      padding: padding,
      scaler: scaler,
    );
  }

  /// أدنى نسبة تصغير — تحتها يُسلَّم الحرف لتصغير الخانة الواحدة عند الرسم
  /// The lowest shrink ratio — below it the cell's own scale-down takes over at paint time.
  static const double _minFit = 0.62;

  final double fontSize;
  final double padding;

  /// مقياس خط النظام: به يُحسب ارتفاع الصف فيكبر مع الحرف ولا يُقصّ
  /// The platform's text scale: it drives the row height so the row grows with the glyph
  /// instead of clipping it.
  final TextScaler scaler;

  /// ارتفاع موحّد لكل خلية — سطر واحد يكبر مع مقياس الخط ولا يلتفّ أبداً
  /// One uniform height for every cell — a single line that grows with the text scale and
  /// never wraps.
  double get cellHeight {
    final line = fontSize * scaler.scale(1.0) * 1.55;

    return line + padding * 1.6;
  }

  static double _pickFont(double width, int columnCount) {
    final perColumn = columnCount == 0 ? width : width / columnCount;

    // سقف أدنى 7.5pt: تحته يصبح النص زينة لا معلومة
    // A 7.5pt floor: below that the text is decoration, not information.
    if (perColumn >= 88) return 11;
    if (perColumn >= 68) return 10;
    if (perColumn >= 52) return 9;
    if (perColumn >= 40) return 8;

    return 7.5;
  }

  static double _pickPadding(double width, int columnCount) {
    final perColumn = columnCount == 0 ? width : width / columnCount;

    if (perColumn >= 68) return 5;
    if (perColumn >= 46) return 3.5;

    return 2;
  }
}
