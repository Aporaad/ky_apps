import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/report_model.dart';
import 'store_result.dart';

/// نتيجة تقرير: صفوفه وبياناته الوصفية (فترة · مجاميع · اقتطاع)
/// A report result: its rows plus the meta (period, totals, truncation).
class StoreReportResult<T> {
  const StoreReportResult({this.rows = const [], this.meta = const {}});

  final List<T> rows;
  final Map<String, dynamic> meta;

  double get totalIn => _double('qty_in');

  double get totalOut => _double('qty_out');

  double get totalValue => _double('value');

  int get totalRows => meta['total'] is num ? (meta['total'] as num).toInt() : rows.length;

  bool get truncated => meta['truncated'] == true;

  /// إحصاءات التقرير الكاملة — يرسلها الخادم جاهزاً لا يُشتق من السطور
  /// The report's full statistics — shipped ready by the server, never derived from the rows.
  ReportStats get stats => ReportStats.fromMap(
    meta['totals'] is Map ? Map<String, dynamic>.from(meta['totals'] as Map) : null,
  );

  /// إحصاء كل قسم في التقارير الموسعة، بترتيب ظهورها في السطور
  /// Each section's statistics, in the order the rows present them.
  List<ReportStats> get sectionStats => [
    for (final entry in meta['sections'] is List ? (meta['sections'] as List) : const [])
      if (entry is Map) ReportStats.fromMap(Map<String, dynamic>.from(entry)),
  ];

  /// عناوين الأقسام بترتيبها — يطابق sectionStats حرفياً لأنهما من نفس القائمة
  /// The section labels in order — matched to [sectionStats] because both come from one list.
  List<String> get sectionLabels => [
    for (final entry in meta['sections'] is List ? (meta['sections'] as List) : const [])
      if (entry is Map) (entry['label'] ?? entry['LABEL'] ?? '').toString(),
  ];

  String get scope => (meta['scope'] ?? '').toString();

  double _double(String key) {
    final value = meta[key];

    return value is num ? value.toDouble() : 0;
  }
}

/// مستودع التقارير والأرصدة وكشف الجرد
/// The reports, balances and stocktake repository.
class StoreReportsRepository {
  StoreReportsRepository({required this.client});

  final DioClient client;

  /// الأرصدة الحالية من `AVVG`
  /// Current balances from AVVG.
  Future<StoreReportResult<StockBalanceRow>> fetchBalances({
    String search = '',
    List<int> storeNos = const [],
    int? groupNo,
    int? typeNo,
    String only = 'all',
    int page = 1,
    int limit = 200,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeBalances,
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          if (storeNos.isNotEmpty) 'store_no': storeNos.join(','),
          if (groupNo != null) 'group_no': groupNo,
          if (typeNo != null) 'type_no': typeNo,
          if (only != 'all') 'only': only,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );

      return _parse<StockBalanceRow>(
        response.data as Map<String, dynamic>,
        StockBalanceRow.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StoreReportResult<StockBalanceRow>();
      rethrow;
    }
  }

  /// عرض الحركة التفصيلي
  /// The detailed movement view.
  Future<StoreReportResult<StockMovementRow>> fetchMovement(
    StoreReportFilter filter, {
    int limit = 2000,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeReportMovement,
        queryParameters: {...filter.toQuery(), 'limit': limit},
        cancelToken: cancelToken,
      );

      return _parse<StockMovementRow>(
        response.data as Map<String, dynamic>,
        StockMovementRow.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return const StoreReportResult<StockMovementRow>();
      }
      rethrow;
    }
  }

  /// خلاصة الحركة
  /// The movement summary.
  Future<StoreReportResult<StockSummaryRow>> fetchSummary(
    StoreReportFilter filter, {
    int limit = 2000,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeReportSummary,
        queryParameters: {...filter.toQuery(), 'limit': limit},
        cancelToken: cancelToken,
      );

      return _parse<StockSummaryRow>(
        response.data as Map<String, dynamic>,
        StockSummaryRow.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return const StoreReportResult<StockSummaryRow>();
      }
      rethrow;
    }
  }

  /// كشف الجرد الحيّ — قراءة فقط، لا كتابة ولا ترحيل
  /// The live stocktake sheet — read-only, no write and no posting.
  Future<StoreReportResult<StockSheetRow>> fetchStockSheet({
    List<int> storeNos = const [],
    int? groupNo,
    String search = '',
    DateTime? date,
    int limit = 3000,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeStockSheet,
        queryParameters: {
          if (storeNos.isNotEmpty) 'store_no': storeNos.join(','),
          if (groupNo != null) 'group_no': groupNo,
          if (search.isNotEmpty) 'search': search,
          if (date != null) 'date': dateText(date),
          'limit': limit,
        },
        cancelToken: cancelToken,
      );

      return _parse<StockSheetRow>(
        response.data as Map<String, dynamic>,
        StockSheetRow.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StoreReportResult<StockSheetRow>();
      rethrow;
    }
  }

  /// تسجيل حدث طباعة/تصدير — لا يغيّر أي رصيد
  /// Record a print/export event — never changes any balance.
  Future<void> logAction({
    required String path,
    required String action,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      await client.dio.post(path, data: {'action': action, ...extra});
    } on DioException {
      // السجل ثانوي: فشل تسجيله لا يفسد تجربة الطباعة
      // The audit row is secondary: a failure must not break the print experience.
    }
  }

  static String dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  static StoreReportResult<T> _parse<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
  ) {
    final raw = body['data'];
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final rows = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(parse)
              .toList(growable: false)
        : <T>[];

    return StoreReportResult<T>(rows: rows, meta: meta);
  }
}

/// نتيجة موحّدة لعمليات الأرصدة التي لا تكتب شيئاً — تُستخدم لتمرير رسالة الخطأ للشاشة
/// A shared result for read-only balance calls, carrying the error message to the screen.
class StoreReadResult {
  const StoreReadResult({this.ok = true, this.message});

  final bool ok;
  final String? message;

  static const StoreReadResult success = StoreReadResult();

  factory StoreReadResult.failed(String message) =>
      StoreReadResult(ok: false, message: message);
}

/// تحويل استثناء شبكة إلى نص عربي مقروء لشاشة القراءة
/// Turn a network exception into a readable message for a read-only screen.
String storeErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }

    return error.message ?? 'تعذر الاتصال بالخادم';
  }

  return StoreResult.failure(error.toString()).message;
}
