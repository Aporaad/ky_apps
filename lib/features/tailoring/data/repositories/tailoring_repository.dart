import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/cutting_bill_detail_model.dart';
import '../models/cutting_bill_summary_model.dart';
import '../models/cutting_movement_model.dart';
import '../models/tailoring_reference_model.dart';

/// خطأ قسم التفصيل مع علم «غير موجودة في الـ VIEW»
/// A tailoring error carrying the "not in the view" flag.
///
/// الفواتير غير المُسندة لقصّاص وخيّاط لا تظهر في الـ VIEW أصلاً، فهذا ليس خطأ شبكة
/// ولا خطأ مستخدم؛ الشاشة تعرض حالة فراغ تفسيرية بدل رسالة فشل.
/// Bills with no cutter/tailor never appear in the view at all, so this is neither a network
/// nor a user error; the screen shows an explanatory empty state rather than a failure.
class TailoringException implements Exception {
  final String message;

  /// الفاتورة غير موجودة ضمن نطاق الـ VIEW (استجابة 404 بعلم خاص)
  /// The bill is outside the view's scope (a 404 carrying a dedicated flag).
  final bool notFoundInView;

  const TailoringException(this.message, {this.notFoundInView = false});

  /// رسالة صريحة للمستخدم / an explicit message for the user
  String get displayMessage => message;

  @override
  String toString() => message;
}

/// مستودع قسم التفصيل — قراءة فقط من مسارات `tailoring/*`
/// The tailoring repository — read-only over the `tailoring/*` routes.
///
/// كل مفتاح تنقل مركّب (رقم، سنة) لأن رقم الفاتورة وحده غير فريد.
/// Every navigation key is the composite (number, year) because the number alone is not unique.
class TailoringRepository {
  final DioClient client;

  TailoringRepository({required this.client});

  /// قائمة الفواتير: الأحدث أولاً مع البحث والفلترة الزمنية والتصفح
  /// The bill list: newest first, with search, date range and paging.
  Future<CuttingBillPage> fetchBills({
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.tailoringBills,
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (fromDate != null) 'from_date': _isoDate(fromDate),
          if (toDate != null) 'to_date': _isoDate(toDate),
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw TailoringException(
          (body['message'] ?? 'تعذّر جلب فواتير التفصيل').toString(),
        );
      }

      final meta = (body['meta'] as Map?) ?? const {};
      final items = (body['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CuttingBillSummary.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      return CuttingBillPage(
        items: items,
        total: _asInt(meta['total']),
        page: _asInt(meta['page'], fallback: page),
        pages: _asInt(meta['pages']),
        limit: _asInt(meta['limit'], fallback: limit),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _toException(e, 'تعذّر جلب فواتير التفصيل');
    }
  }

  /// تفصيل فاتورة واحدة بهويتها المركّبة
  /// One bill in full by its composite identity.
  Future<CuttingBillDetail> fetchBill(
    int billNo,
    int year, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.tailoringBill(billNo, year),
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;

      if (body['success'] != true) {
        throw TailoringException(
          (body['message'] ?? 'تعذّر جلب فاتورة التفصيل').toString(),
          notFoundInView: body['not_found_in_view'] == true,
        );
      }

      return CuttingBillDetail.fromJson(
        Map<String, dynamic>.from(body['data'] as Map? ?? const {}),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;

      // 404 هنا يعني «خارج نطاق الـ VIEW» لا «خطأ رابط» — تُميَّز لتُشرح للمستخدم.
      // A 404 here means "outside the view's scope", not "bad URL" — it is distinguished
      // so the screen can explain it.
      final data = e.response?.data;
      if (e.response?.statusCode == 404 && data is Map) {
        throw TailoringException(
          (data['message'] ?? 'الفاتورة غير موجودة').toString(),
          notFoundInView: data['not_found_in_view'] == true,
        );
      }

      throw _toException(e, 'تعذّر جلب فاتورة التفصيل');
    }
  }

  /// سجل حركة قطع الموديل المختار
  /// The movement log of the selected model's pieces.
  ///
  /// الأرقام تأتي من صفوف الـ VIEW التي يحملها العميل فعلاً، فلا قراءة إضافية لمعرفتها.
  /// The numbers come from the view rows the client already holds, so no extra read is needed.
  Future<List<CuttingMovement>> fetchMovements(
    int billNo,
    int year,
    List<int> seqNos, {
    CancelToken? cancelToken,
  }) async {
    if (seqNos.isEmpty) return const [];

    try {
      final resp = await client.dio.get(
        ApiConstants.tailoringMovements(billNo, year),
        queryParameters: {'seq_nos': seqNos.join(',')},
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw TailoringException(
          (body['message'] ?? 'تعذّر جلب سجل الحركة').toString(),
        );
      }

      return (body['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CuttingMovement.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _toException(e, 'تعذّر جلب سجل الحركة');
    }
  }

  /// المرجعيات المشتركة بين شاشة الاستعراض والنماذج الأولية
  /// The reference data shared by the view screen and the prototype forms.
  Future<TailoringReference> fetchReference({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.tailoringReference,
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw TailoringException(
          (body['message'] ?? 'تعذّر جلب مرجعيات التفصيل').toString(),
        );
      }

      return TailoringReference.fromJson(
        Map<String, dynamic>.from(body['data'] as Map? ?? const {}),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _toException(e, 'تعذّر جلب مرجعيات التفصيل');
    }
  }

  /// تسجيل حدث طباعة أو تصدير — يُستدعى بلا انتظار ولا يُفشل الإجراء عند فشله
  /// Record a print or export event — fired without awaiting, never failing the action.
  ///
  /// السجل صف واحد في APP_USER_ACTIVITY ولا يمسّ أي جدول إرث.
  /// The record is one APP_USER_ACTIVITY row and touches no legacy table.
  Future<bool> recordActivity(
    int billNo,
    int year, {
    required String action,
  }) async {
    try {
      final resp = await client.dio.post(
        ApiConstants.tailoringActivity(billNo, year),
        data: {'action': action},
      );
      final body = resp.data;
      return body is Map && body['success'] == true;
    } catch (_) {
      // التدقيق لا يُفشل الطباعة أو التصدير — نفس قاعدة باقي شاشات التقارير.
      // Auditing never fails the print or export — the same rule as the other reports.
      return false;
    }
  }

  /// تحويل تاريخ إلى `YYYY-MM-DD` كما يقبله الخادم
  /// Convert a date to the `YYYY-MM-DD` the server accepts.
  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// قراءة رقم من بيانات التصفح التي قد تصل نصاً
  /// Read a paging number that may arrive as a string.
  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  /// توحيد أخطاء Dio في خطأ واحد مفهوم
  /// Unify Dio failures into one readable error.
  static TailoringException _toException(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return TailoringException(data['message'].toString());
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TailoringException(
        'انتهت مهلة الاتصال بالخادم — تحقّق من الشبكة وأعد المحاولة',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const TailoringException(
        'تعذّر الوصول إلى الخادم — تحقّق من الاتصال',
      );
    }

    return TailoringException(fallback);
  }
}
