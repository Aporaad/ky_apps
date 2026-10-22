import '../../../../core/utils/arabic_encoding_utils.dart';

/// سطر واحد في كشف العمل (تاريخ | موديل | عدد | سعر | إجمالي)
/// One row of the work report — the same five columns the legacy Oracle work table prints.
class WorkerWorkRow {
  final String date;
  final String styleName;
  final double count;
  final double unitPrice;
  final double total;

  const WorkerWorkRow({
    required this.date,
    required this.styleName,
    required this.count,
    required this.unitPrice,
    required this.total,
  });

  factory WorkerWorkRow.fromJson(Map<String, dynamic> json) {
    return WorkerWorkRow(
      // قراءة مزدوجة للمفاتيح (snake_case من الـ API أو UPPERCASE من أوراكل الخام)
      date: _parseString(json['date'] ?? json['DATE'] ?? json['WORK_DATE'] ?? json['work_date']),
      // الموديل نص عربي → إصلاح الترميز إلزامي (يصل أحياناً بايتات CP1256)
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

  static String _parseString(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }
}

/// كشف العمل الكامل للعامل (القصاص/الخياط) مع الترويسة والإجماليات
/// The whole work report for a worker (cutter/tailor): header identity, rows and totals.
class WorkerWorkReport {
  final int? workerId;
  final String workerName;
  final String accNo;
  final String currency;
  final String fromDate;
  final String toDate;
  final List<WorkerWorkRow> rows;
  final double totalCount;
  final double totalAmount;

  const WorkerWorkReport({
    this.workerId,
    required this.workerName,
    required this.accNo,
    required this.currency,
    required this.fromDate,
    required this.toDate,
    required this.rows,
    required this.totalCount,
    required this.totalAmount,
  });

  /// يبني التقرير من استجابة الـ API الموحّدة (worker + data + summary)
  /// Builds from the unified API envelope: `worker`, `data` (rows) and `summary`.
  factory WorkerWorkReport.fromJson(Map<String, dynamic> json) {
    final worker = (json['worker'] as Map?)?.cast<String, dynamic>() ?? const {};
    final summary = (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final data = (json['data'] as List?) ?? const [];

    return WorkerWorkReport(
      workerId: _parseInt(worker['id'] ?? worker['ID']),
      workerName: ArabicEncodingUtils.fix(worker['name'] ?? ''),
      accNo: (worker['acc_no'] ?? worker['ACC_NO'] ?? '').toString(),
      currency: ArabicEncodingUtils.fix(
        summary['currency'] ?? 'يمني YR',
      ),
      fromDate: (summary['from_date'] ?? summary['FROM_DATE'] ?? '').toString(),
      toDate: (summary['to_date'] ?? summary['TO_DATE'] ?? '').toString(),
      rows: data
          .map((e) => WorkerWorkRow.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      totalCount: _parseDouble(summary['total_count'] ?? summary['TOTAL_COUNT']),
      totalAmount: _parseDouble(summary['total_amount'] ?? summary['TOTAL_AMOUNT']),
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
