import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/worker_work_report_model.dart';

/// جدول "كشف العمل" - الأعمدة الخمسة المطابقة لتقرير أوراكل (FOR_CUTTER_TAILOR / FOR_TAILOR):
/// التاريخ | الموديل | العدد | السعر | الإجمالي + سطرا الإجمالي (إجمالي العدد / الإجمالي لكم).
///
/// The work-statement table — the same five columns the legacy Oracle report prints,
/// followed by the two total lines (total count / total amount). Rendered RTL by the
/// ambient Directionality, so the first logical column (التاريخ) sits at the right edge.
class WorkerWorkReportTable extends StatelessWidget {
  final List<WorkerWorkRow> rows;
  final double totalCount;
  final double totalAmount;

  const WorkerWorkReportTable({
    super.key,
    required this.rows,
    required this.totalCount,
    required this.totalAmount,
  });

  static const Color _borderColor = Color(0xFF4B5563);
  static const Color _headerBg = Color(0xFFD4A853); // ذهبي مطابق لقالب أوراكل

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 650;
        final isVeryCompact = width < 450;

        final headerSize = isVeryCompact ? 10.0 : (isCompact ? 11.5 : 13.0);
        final dataSize = isVeryCompact ? 9.5 : (isCompact ? 11.0 : 12.0);
        final vPad = isVeryCompact ? 4.0 : (isCompact ? 5.0 : 6.5);
        final hPad = isVeryCompact ? 1.5 : (isCompact ? 3.0 : 5.0);

        return Table(
          border: TableBorder.all(color: _borderColor, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(1.5), // التاريخ
            1: FlexColumnWidth(1.6), // الموديل
            2: FlexColumnWidth(1.0), // العدد
            3: FlexColumnWidth(1.3), // السعر
            4: FlexColumnWidth(1.5), // الإجمالي
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // رأس الجدول الذهبي
            TableRow(
              decoration: const BoxDecoration(color: _headerBg),
              children: [
                _headerCell('التاريخ', headerSize, vPad, hPad),
                _headerCell('الموديل', headerSize, vPad, hPad),
                _headerCell('العدد', headerSize, vPad, hPad),
                _headerCell('السعر', headerSize, vPad, hPad),
                _headerCell('الإجمالي', headerSize, vPad, hPad),
              ],
            ),

            // أسطر البيانات
            ...rows.map(
              (row) => TableRow(
                decoration: const BoxDecoration(color: Colors.white),
                children: [
                  _dataCell(row.date, dataSize, vPad, hPad),
                  _dataCell(row.styleName, dataSize, vPad, hPad, alignRight: false),
                  _dataCell(_formatNumber(row.count), dataSize, vPad, hPad),
                  _dataCell(_formatNumber(row.unitPrice), dataSize, vPad, hPad),
                  _dataCell(
                    _formatNumber(row.total),
                    dataSize,
                    vPad,
                    hPad,
                    bold: true,
                  ),
                ],
              ),
            ),

            // سطر إجمالي العدد
            if (rows.isNotEmpty)
              _totalRow(
                label: 'إجــمالي العدد',
                value: _formatNumber(totalCount),
                size: dataSize,
                vPad: vPad,
                hPad: hPad,
                highlight: false,
              ),

            // سطر الإجمالي لكم (المبلغ) - مطابق للصورة
            if (rows.isNotEmpty)
              _totalRow(
                label: 'الإجمــالي',
                value: _formatNumber(totalAmount),
                size: dataSize,
                vPad: vPad,
                hPad: hPad,
                highlight: true,
              ),
          ],
        );
      },
    );
  }

  Widget _headerCell(String text, double size, double vPad, double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double size,
    double vPad,
    double hPad, {
    bool bold = false,
    bool alignRight = false,
  }) {
    final child = Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: Colors.black87,
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: alignRight ? child : Center(child: child),
    );
  }

  /// سطر إجمالي يمتد عبر عمود البيان (الموديل) ويظهر القيمة في عمود الإجمالي.
  /// A totals row: label spans the model column, the value sits under الإجمالي.
  TableRow _totalRow({
    required String label,
    required String value,
    required double size,
    required double vPad,
    required double hPad,
    required bool highlight,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: highlight ? _headerBg.withValues(alpha: 0.25) : const Color(0xFFF3F4F6),
      ),
      children: [
        _dataCell('', size, vPad, hPad),
        Padding(
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF6B2D1B) : Colors.black87,
            ),
          ),
        ),
        _dataCell('', size, vPad, hPad),
        _dataCell('', size, vPad, hPad),
        Padding(
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                color: highlight ? AppColors.error : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// تنسيق الأرقام بفاصلة الآلاف (أرقام لاتينية كما في الكشف الأصلي).
  static String _formatNumber(num value) {
    if (value == 0) return '0';
    final isInt = value == value.roundToDouble();
    final abs = value.abs();
    final core = isInt
        ? abs.toInt().toString()
        : abs.toStringAsFixed(2);
    final grouped = core.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return value < 0 ? '-$grouped' : grouped;
  }
}
