import '../../../../core/utils/arabic_encoding_utils.dart';

// ================================================================
// كشف عمل المجموعة — جميع القصاصين أو جميع الخياطين في فترة محددة
// Group work report — all cutters or all tailors in a date range
// مُجمّع لكل (عامل + موديل): سطر واحد لكل عامل وموديل يجمع العدد والمبلغ عبر الفترة.
// Aggregated per (worker + style): one row combining count and amount across the period.
// الأعمدة: الاسم | الموديل | العدد | السعر | الإجمالي
// Columns: Name | Style | Count | Price | Total
// ================================================================

/// سطر مجمّع واحد في كشف عمل المجموعة (لكل عامل + موديل)
/// One aggregated row of the group work report — per (worker + style).
class WorkerGroupWorkRow {
  final String workerName;
  final String styleName;
  final double count;
  final double unitPrice;
  final double total;

  const WorkerGroupWorkRow({
    required this.workerName,
    required this.styleName,
    required this.count,
    required this.unitPrice,
    required this.total,
  });

  factory WorkerGroupWorkRow.fromJson(Map<String, dynamic> json) {
    return WorkerGroupWorkRow(
      // قراءة مزدوجة للمفاتيح (snake_case من الـ API أو UPPERCASE من أوراكل الخام)
      // Double-case key reads (snake_case from API or UPPERCASE from raw Oracle)
      workerName: ArabicEncodingUtils.fix(
        json['worker_name'] ?? json['WORKER_NAME'] ?? '',
      ),
      styleName: ArabicEncodingUtils.fix(
        json['style_name'] ?? json['STYLE_NAME'] ?? json['Style_Name'] ?? '',
      ),
      count: _parseDouble(json['count'] ?? json['COUNT'] ?? json['QTY'] ?? json['qty']),
      unitPrice: _parseDouble(
        json['unit_price'] ?? json['UNIT_PRICE'] ?? json['price'] ?? json['PRICE'],
      ),
      total: _parseDouble(json['total'] ?? json['TOTAL'] ?? json['amount'] ?? json['AMOUNT']),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

/// كشف عمل المجموعة الكامل — يعرض جميع الأسطر مع الإجماليات وعدد العمال
/// The full group work report — all rows with totals and worker count.
class WorkerGroupWorkReport {
  final String group;
  final String fromDate;
  final String toDate;
  final List<WorkerGroupWorkRow> rows;
  final double totalCount;
  final double totalAmount;
  final int workerCount;

  const WorkerGroupWorkReport({
    required this.group,
    required this.fromDate,
    required this.toDate,
    required this.rows,
    required this.totalCount,
    required this.totalAmount,
    required this.workerCount,
  });

  /// يبني التقرير من استجابة الـ API (group + data + summary)
  /// Builds from the API response envelope: `group`, `data` (rows) and `summary`.
  factory WorkerGroupWorkReport.fromJson(Map<String, dynamic> json) {
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final data = (json['data'] as List?) ?? const [];

    return WorkerGroupWorkReport(
      group: (json['group'] ?? json['GROUP'] ?? '').toString(),
      fromDate: (summary['from_date'] ?? summary['FROM_DATE'] ?? '').toString(),
      toDate: (summary['to_date'] ?? summary['TO_DATE'] ?? '').toString(),
      rows: data
          .map((e) => WorkerGroupWorkRow.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      totalCount: _parseDouble(summary['total_count'] ?? summary['TOTAL_COUNT']),
      totalAmount: _parseDouble(summary['total_amount'] ?? summary['TOTAL_AMOUNT']),
      workerCount: _parseInt(summary['worker_count'] ?? summary['WORKER_COUNT']) ?? 0,
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }
}
