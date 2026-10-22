import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/worker_group_work_report_model.dart';

/// جدول "كشف عمل المجموعة" — خمسة أعمدة مُجمّعة لكل (عامل + موديل):
/// الاسم | الموديل | العدد | السعر | الإجمالي + سطرا الإجمالي.
///
/// The group work-report table — five columns aggregated per (worker + style):
/// Name | Style | Count | Price | Total, followed by two totals rows.
///
/// مدموج بصرياً: عمود "الاسم" يُعرض مرة واحدة لكل عامل ويمتد رأسياً فوق كل
/// أسطر موديلاته، بدلاً من تكرار الاسم في كل سطر. (Flutter Table لا يدعم الدمج
/// الرأسي، لذلك نبني كل كتلة عامل عبر IntrinsicHeight + Row لتحقيق ذلك.)
/// The worker-name cell is merged (rowspan-like): it appears once per worker and
/// stretches vertically over all of that worker's style rows instead of repeating.
/// Rendered RTL by the ambient Directionality.
class WorkerGroupWorkReportTable extends StatelessWidget {
  final List<WorkerGroupWorkRow> rows;
  final double totalCount;
  final double totalAmount;
  final int workerCount;

  const WorkerGroupWorkReportTable({
    super.key,
    required this.rows,
    required this.totalCount,
    required this.totalAmount,
    required this.workerCount,
  });

  static const Color _borderColor = Color(0xFF4B5563);
  static const Color _headerBg = Color(0xFFD4A853); // ذهبي مطابق لقالب أوراكل

  // نسب الأعمدة — تُستخدم في الرأس وكل كتلة عامل وسطري الإجمالي لضمان تطابق
  // المحاذاة الأفقية. عمود الاسم flex منفصل، وبقية الأعمدة داخل Expanded واحد
  // مقسومة بنفس النسب، والنسب تُركّب ضربياً فتتطابق الأعمدة تماماً.
  static const int _nameFlex = 22;
  static const int _styleFlex = 16;
  static const int _countFlex = 10;
  static const int _priceFlex = 12;
  static const int _totalFlex = 14;
  static const int _restFlex = _styleFlex + _countFlex + _priceFlex + _totalFlex; // 52

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 650;
        final isVeryCompact = width < 450;

        final headerSize = isVeryCompact ? 9.5 : (isCompact ? 11.0 : 12.5);
        final dataSize = isVeryCompact ? 9.0 : (isCompact ? 10.5 : 11.5);
        final vPad = isVeryCompact ? 3.5 : (isCompact ? 5.0 : 6.0);
        final hPad = isVeryCompact ? 1.5 : (isCompact ? 3.0 : 4.5);

        final groups = _groupByWorker(rows);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // رأس الجدول الذهبي
              _headerRow(headerSize, vPad, hPad),

              // كتلة لكل عامل: اسم مدموج رأسياً + أسطر موديلاته
              ...groups.map(
                (g) => _workerBlock(g, dataSize, vPad, hPad),
              ),

              // سطرا الإجمالي (على كامل عرض الجدول)
              if (rows.isNotEmpty)
                _totalRow(
                  label: 'إجــمالي العدد',
                  value: _formatNumber(totalCount),
                  valueColumn: 1, // داخل بقية الأعمدة: 0=الموديل 1=العدد 2=السعر 3=الإجمالي
                  size: dataSize,
                  vPad: vPad,
                  hPad: hPad,
                  highlight: false,
                ),
              if (rows.isNotEmpty)
                _totalRow(
                  label: 'الإجمــالي',
                  value: _formatNumber(totalAmount),
                  valueColumn: 3,
                  size: dataSize,
                  vPad: vPad,
                  hPad: hPad,
                  highlight: true,
                ),
            ],
          ),
        );
      },
    );
  }

  /// تجميع الأسطر المتتالية حسب اسم العامل (الترتيب من الخادم: عامل ثم موديل).
  List<_WorkerGroup> _groupByWorker(List<WorkerGroupWorkRow> rows) {
    final groups = <_WorkerGroup>[];
    for (final row in rows) {
      if (groups.isNotEmpty && groups.last.name == row.workerName) {
        groups.last.rows.add(row);
      } else {
        groups.add(_WorkerGroup(row.workerName, [row]));
      }
    }
    return groups;
  }

  // رأس الجدول: الاسم + (الموديل | العدد | السعر | الإجمالي)
  Widget _headerRow(double size, double vPad, double hPad) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: _nameFlex,
              child: _gridHeaderCell('الاسم', size, vPad, hPad, hasEndDivider: true),
            ),
            Expanded(
              flex: _restFlex,
              child: Row(
                children: [
                  Expanded(
                    flex: _styleFlex,
                    child: _gridHeaderCell('الموديل', size, vPad, hPad, hasEndDivider: true),
                  ),
                  Expanded(
                    flex: _countFlex,
                    child: _gridHeaderCell('العدد', size, vPad, hPad, hasEndDivider: true),
                  ),
                  Expanded(
                    flex: _priceFlex,
                    child: _gridHeaderCell('السعر', size, vPad, hPad, hasEndDivider: true),
                  ),
                  Expanded(
                    flex: _totalFlex,
                    child: _gridHeaderCell('الإجمالي', size, vPad, hPad, hasEndDivider: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // كتلة عامل واحد: خلية الاسم الممتدة رأسياً + عمود لأسطر الموديلات
  Widget _workerBlock(_WorkerGroup group, double size, double vPad, double hPad) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // خلية الاسم — تمتد فوق كل أسطر العامل وتُعرض مرة واحدة فقط
          Expanded(
            flex: _nameFlex,
            child: Container(
              decoration: const BoxDecoration(
                border: BorderDirectional(
                  end: BorderSide(color: _borderColor, width: 1),
                  bottom: BorderSide(color: _borderColor, width: 1),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
              alignment: Alignment.center,
              child: Text(
                group.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // بقية الأعمدة — سطر لكل موديل
          Expanded(
            flex: _restFlex,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: group.rows
                  .map(
                    (row) => _styleRow(row, size, vPad, hPad),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // سطر موديل واحد داخل كتلة العامل
  Widget _styleRow(WorkerGroupWorkRow row, double size, double vPad, double hPad) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _styleFlex,
            child: _gridDataCell(row.styleName, size, vPad, hPad, alignRight: true, hasEndDivider: true),
          ),
          Expanded(
            flex: _countFlex,
            child: _gridDataCell(_formatNumber(row.count), size, vPad, hPad, hasEndDivider: true),
          ),
          Expanded(
            flex: _priceFlex,
            child: _gridDataCell(_formatNumber(row.unitPrice), size, vPad, hPad, hasEndDivider: true),
          ),
          Expanded(
            flex: _totalFlex,
            child: _gridDataCell(
              _formatNumber(row.total),
              size,
              vPad,
              hPad,
              bold: true,
              hasEndDivider: false,
            ),
          ),
        ],
      ),
    );
  }

  /// سطر إجمالي على كامل العرض — التسمية في عمود الاسم والقيمة في العمود الرقمي.
  Widget _totalRow({
    required String label,
    required String value,
    required int valueColumn,
    required double size,
    required double vPad,
    required double hPad,
    required bool highlight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: highlight ? _headerBg.withValues(alpha: 0.25) : const Color(0xFFF3F4F6),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عمود الاسم يحمل التسمية بمحاذاة اليمين
            Expanded(
              flex: _nameFlex,
              child: Container(
                decoration: const BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
                alignment: Alignment.centerRight,
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
            ),
            // بقية الأعمدة — القيمة في العمود المحدد
            Expanded(
              flex: _restFlex,
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++)
                    Expanded(
                      flex: i == 0
                          ? _styleFlex
                          : i == 1
                              ? _countFlex
                              : i == 2
                                  ? _priceFlex
                                  : _totalFlex,
                      child: i == valueColumn
                          ? Padding(
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
                            )
                          : _gridDataCell('', size, vPad, hPad, hasEndDivider: i < 3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridHeaderCell(
    String text,
    double size,
    double vPad,
    double hPad, {
    bool hasEndDivider = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hasEndDivider
            ? const BorderDirectional(
                end: BorderSide(color: _borderColor, width: 1))
            : null,
      ),
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

  Widget _gridDataCell(
    String text,
    double size,
    double vPad,
    double hPad, {
    bool bold = false,
    bool alignRight = false,
    bool hasEndDivider = false,
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
    return Container(
      decoration: BoxDecoration(
        border: hasEndDivider
            ? const BorderDirectional(
                end: BorderSide(color: _borderColor, width: 1))
            : null,
      ),
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: alignRight ? child : Center(child: child),
    );
  }

  /// تنسيق الأرقام بفاصلة الآلاف
  static String _formatNumber(num value) {
    if (value == 0) return '0';
    final isInt = value == value.roundToDouble();
    final abs = value.abs();
    final core = isInt ? abs.toInt().toString() : abs.toStringAsFixed(2);
    final grouped = core.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return value < 0 ? '-$grouped' : grouped;
  }
}

/// مجموعة أسطر تعود لعامل واحد (الاسم + موديلاته) — للدمج الرأسي لعمود الاسم.
class _WorkerGroup {
  final String name;
  final List<WorkerGroupWorkRow> rows;

  _WorkerGroup(this.name, this.rows);
}
