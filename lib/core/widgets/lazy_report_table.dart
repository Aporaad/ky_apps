import 'package:flutter/material.dart';

/// جدول تقرير **كسول**: رأس مثبّت أعلى، صفوف تُبنى عند ظهورها فقط، وتذييل مثبّت
/// أسفل. الشرائح الثلاث تشترك في خريطة `columnWidths` نفسها فيبقى الشكل جدولاً
/// واحداً متصلاً.
///
/// A **lazy** report table: pinned header rows, rows built only when they scroll
/// into view, and pinned footer rows. All three slices share one `columnWidths`
/// map so the result still reads as a single continuous table.
///
/// السبب: بناء آلاف الصفوف داخل `Table` واحد يُنشئ فقرة أصلية (`ui.Paragraph`)
/// لكل خلية فينفد heap الجهاز ويُقتل التطبيق. هنا عدد الخلايا الحيّة ثابت مهما
/// بلغ عدد الصفوف.
/// Why: building thousands of rows inside one `Table` allocates a native
/// paragraph per cell until the device heap is exhausted. Here the number of live
/// cells stays constant no matter how many rows the report holds.
class LazyReportTable extends StatefulWidget {
  /// صفوف مثبّتة أعلى (الرأس + أي صف افتتاحي / opening rows pinned on top).
  final List<TableRow> headerRows;

  /// صفوف مثبّتة أسفل (الإجماليات / totals pinned at the bottom).
  final List<TableRow> footerRows;

  /// عدد صفوف البيانات / how many data rows exist.
  final int rowCount;

  /// يبني صفاً واحداً بفهرسه / builds a single row by index.
  final TableRow Function(int index) rowBuilder;

  /// أوزان الأعمدة المشتركة بين الشرائح / column widths shared by every slice.
  final Map<int, TableColumnWidth> columnWidths;

  /// ارتفاع منطقة الصفوف؛ `null` = 55% من الشاشة محصورة بين 240 و760.
  /// Rows viewport height; `null` = 55% of the screen, clamped to 240..760.
  final double? rowsHeight;

  final Color borderColor;

  const LazyReportTable({
    super.key,
    required this.headerRows,
    required this.footerRows,
    required this.rowCount,
    required this.rowBuilder,
    required this.columnWidths,
    this.rowsHeight,
    this.borderColor = const Color(0xFF4B5563),
  });

  @override
  State<LazyReportTable> createState() => _LazyReportTableState();
}

class _LazyReportTableState extends State<LazyReportTable> {
  /// متحكّم واحد يُمرَّر للـ Scrollbar والـ ListView معاً.
  /// One controller shared by the Scrollbar and the ListView.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _slice(List<TableRow> rows) {
    return Table(
      border: TableBorder.all(
        color: widget.borderColor,
        width: 1,
        style: BorderStyle.solid,
      ),
      columnWidths: widget.columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // قائمة داخل Column مفتوح الارتفاع تحتاج ارتفاعاً صريحاً، وإلا فشل التخطيط.
        // A ListView inside an unbounded Column needs an explicit height.
        final height = widget.rowsHeight ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (MediaQuery.sizeOf(context).height * 0.55)
                    .clamp(240.0, 760.0)
                    .toDouble());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.headerRows.isNotEmpty) _slice(widget.headerRows),
            SizedBox(
              height: height,
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scroll,
                  cacheExtent: 600,
                  itemCount: widget.rowCount,
                  itemBuilder: (context, index) =>
                      _slice([widget.rowBuilder(index)]),
                ),
              ),
            ),
            if (widget.footerRows.isNotEmpty) _slice(widget.footerRows),
          ],
        );
      },
    );
  }
}
