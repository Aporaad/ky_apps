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
  });

  final List<ReportColumn<T>> columns;
  final List<T> rows;

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

  /// أوزان الأعمدة النسبية — واحدة في كل كتلة فتقرأ كجدول متصل لا مخطط أعمدة منفصلة
  /// The relative column widths — identical in every block, so the blocks read as one table.
  Map<int, TableColumnWidth> get _widths => {
    for (int i = 0; i < widget.columns.length; i++)
      i: FlexColumnWidth(widget.columns[i].weight),
  };

  @override
  Widget build(BuildContext context) {
    // ── لا عرض لانهائي هنا: لا `SingleChildScrollView` أفقي يهدي `Table` عرضًا بلا نهاية
    //    فينهار التخطيط — الجدول يأخذ عرض الصفحة دائمًا ويتكيّف مقياس الخط معه.
    // ── No infinite width here: no horizontal viewport feeding `Table` an endless width and
    //    crashing the layout. The table always takes the page's width and the type scale adapts.
    return LayoutBuilder(
      builder: (context, constraints) {
        final styles = _Styles(constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 720.0, widget.columns.length);

        // الدفعة لا تتجاوز الموجود: وإلا قُرىء فهرس خارج الصفوف وانفجر RangeError
        // A batch never exceeds what exists: otherwise an index past the end is read and
        // RangeError explodes — the crash this guard was written for.
        final shown = math.min(_built, widget.rows.length);
        final blocks = <Widget>[];

        for (int start = 0; start < shown; start += _chunk) {
          final end = math.min(start + _chunk, shown);

          blocks.add(
            _block(
              start: start,
              end: end,
              styles: styles,
              // الرأس مرة واحدة في أول الجدول، والملخص مكوّن مستقل بعده
              // The head appears once at the top; the summary is its own component after it.
              withHead: start == 0,
            ),
          );
        }

        if (shown < widget.rows.length) {
          blocks.add(_loadingMore(remaining: widget.rows.length - shown));
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: blocks,
        );
      },
    );
  }

  Widget _block({
    required int start,
    required int end,
    required _Styles styles,
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
      columnWidths: _widths,
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
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: EdgeInsets.symmetric(
        horizontal: styles.padding,
        vertical: styles.padding,
      ),
      child: Text(
        column.label,
        textAlign: column.numeric ? TextAlign.center : TextAlign.right,
        style: TextStyle(
          fontSize: styles.headSize,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _bodyCell(ReportColumn<T> column, String text, _Styles styles) {
    // السالب علامة خطر في المخزون: كمية كانت أو قيمة
    // A negative is the risk mark in inventory: quantity or value alike.
    final isNegative = column.numeric && text.trim().startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: styles.padding,
        vertical: styles.padding,
      ),
      child: Text(
        text,
        textAlign: column.numeric ? TextAlign.left : TextAlign.right,
        // الالتفاف لا الاقتطاع: كل نص كامل أمام القارئ مهما طال أو ضاقت الشاشة
        // Wrapping, never ellipsis: the whole text in front of the reader, long or narrow.
        softWrap: true,
        style: TextStyle(
          fontSize: styles.fontSize,
          fontWeight: isNegative ? FontWeight.w700 : FontWeight.w500,
          color: isNegative ? AppColors.error : AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// مقياس الجدول المشتق من عرض الشاشة وعدد الأعمدة
/// The table's metrics derived from the screen width and the column count.
///
/// ── لا بكسلات ثابتة: عمودان على هاتف وثمانية عشر على تقرير واحد — العرض يقسم والأرقام
///    تتبع، فلا يضيع حرف ولا يحتاج القارئ تمريرًا جانبيًا.
/// ── No fixed pixels: two columns on a phone and eighteen in one report — the width is split
///    and the numbers follow, so nothing is lost and no sideways scroll is ever needed.
class _Styles {
  _Styles(double width, int columnCount)
    : fontSize = _pickFont(width, columnCount),
      padding = _pickPadding(width, columnCount);

  final double fontSize;
  final double padding;

  double get headSize => fontSize + 0.5;

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
