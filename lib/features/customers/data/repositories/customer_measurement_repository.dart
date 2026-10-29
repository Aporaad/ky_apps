import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/measurement_customer_model.dart';
import '../models/measurement_model_ref.dart';

/// خطأ المقاسات مع علم «خارج نطاق الواجهة»
/// The measurements error, carrying the "outside the view" flag.
///
/// الموديلات التي لا تُسند إلى قصّاص وخيّاط لا تظهر في الواجهة أصلاً، فغيابها ليس خطأ شبكة
/// ولا خطأ مستخدم: الشاشة تعرض حالة فراغ تشرح السبب بدل رسالة فشل عامة.
/// Models never assigned to a cutter and a tailor do not appear in the view at all, so their
/// absence is neither a network nor a user fault: the screen explains it instead of failing.
///
/// نفس شكل خطأ قسم التفصيل لأن المصدر واحد، وهو مُعرَّف هنا كي لا يستورد نموذج ميزة أخرى
/// طبقةَ بياناتها.
/// The same shape as the tailoring error, since the source is one view — declared here so this
/// feature's data layer never imports another feature's.
class MeasurementException implements Exception {
  final String message;
  final bool notFoundInView;

  const MeasurementException(this.message, {this.notFoundInView = false});

  /// رسالة صريحة للمستخدم / an explicit message for the user
  String get displayMessage => message;

  @override
  String toString() => message;
}

/// مستودع مقاسات العملاء — الطبقة الوحيدة التي تلمس Dio في هذه الميزة
/// The customer-measurements repository — the only layer of this feature that touches Dio.
///
/// ثلاثة مسارات قراءة ومسار تدقيق واحد، كلها خلف `customers.measurements_*`. القرار الحقيقي
/// للخادم؛ هذا المستودع يقرأ ما يصل إليه فقط.
/// Three reads and one audit route, all behind `customers.measurements_*`. The server decides
/// access; this repository only reads what it is allowed to receive.
class CustomerMeasurementRepository {
  final DioClient client;

  CustomerMeasurementRepository({required this.client});

  /// قائمة العملاء — الأحدث نشاطاً أولاً، مع البحث بالاسم/الهاتف/المستفيد
  /// The customer list — most recent first, searchable by name, phone or beneficiary.
  Future<MeasurementCustomerPage> fetchCustomers({
    String search = '',
    String sort = 'date_desc',
    int page = 1,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.measurementCustomers,
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'sort': sort,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw MeasurementException(
          (body['message'] ?? 'تعذّر جلب قائمة العملاء').toString(),
        );
      }

      final meta = (body['meta'] as Map?) ?? const {};
      final items = (body['data'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => MeasurementCustomer.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();

      return MeasurementCustomerPage(
        items: items,
        total: _asInt(meta['total']),
        page: _asInt(meta['page'], fallback: page),
        pages: _asInt(meta['pages']),
        limit: _asInt(meta['limit'], fallback: limit),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _toException(e, 'تعذّر جلب قائمة العملاء');
    }
  }

  /// موديلات عميل واحد — الأحدث أولاً، مع بحث المستفيد والنطاق الزمني
  /// One customer's models — newest first, with a beneficiary search and a date range.
  Future<MeasurementModelsPage> fetchModels({
    required int custNo,
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'date_desc',
    int page = 1,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.measurementModels(custNo),
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (fromDate != null) 'from_date': _isoDate(fromDate),
          if (toDate != null) 'to_date': _isoDate(toDate),
          'sort': sort,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw MeasurementException(
          (body['message'] ?? 'تعذّر جلب موديلات العميل').toString(),
        );
      }

      final meta = (body['meta'] as Map?) ?? const {};
      final items = (body['data'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MeasurementModelRef.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return MeasurementModelsPage(
        items: items,
        total: _asInt(meta['total']),
        page: _asInt(meta['page'], fallback: page),
        pages: _asInt(meta['pages']),
        limit: _asInt(meta['limit'], fallback: limit),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;
      throw _toException(e, 'تعذّر جلب موديلات العميل');
    }
  }

  /// تفصيل موديل واحد: العميل/المستفيد + المقاسات + المواصفات + الأقمشة
  /// One model in full: the subject, the measurements, the specs and the fabrics.
  Future<MeasurementSubject> fetchModel(
    MeasurementKey key, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.measurementModel(
          key.custNo,
          key.billNo,
          key.year,
          key.seqNo,
        ),
        cancelToken: cancelToken,
      );

      final body = resp.data as Map<String, dynamic>;

      if (body['success'] != true) {
        throw MeasurementException(
          (body['message'] ?? 'تعذّر جلب مقاسات الموديل').toString(),
          notFoundInView: body['not_found_in_view'] == true,
        );
      }

      final data = body['data'];

      return MeasurementSubject.fromJson(
        Map<String, dynamic>.from(data as Map? ?? const {}),
        custNo: key.custNo,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) rethrow;

      // 404 هنا يعني «خارج نطاق الواجهة» أو «الموديل لا يعود لهذا العميل» لا «رابط خاطئ».
      // A 404 here means "outside the view" or "this model is not this customer's", not a bad URL.
      final data = e.response?.data;
      if (e.response?.statusCode == 404 && data is Map) {
        throw MeasurementException(
          (data['message'] ?? 'الموديل غير موجود').toString(),
          notFoundInView: data['not_found_in_view'] == true,
        );
      }

      throw _toException(e, 'تعذّر جلب مقاسات الموديل');
    }
  }

  /// تسجيل حدث طباعة أو تصدير — يُستدعى بلا انتظار ولا يُفشل الإجراء عند فشله
  /// Record a print or export event — fired without awaiting, never failing the action.
  ///
  /// السجل صف واحد في APP_USER_ACTIVITY ولا يمسّ أي جدول إرث.
  /// The record is one APP_USER_ACTIVITY row and touches no legacy table.
  Future<bool> recordActivity(
    MeasurementKey key, {
    required String action,
  }) async {
    try {
      final resp = await client.dio.post(
        ApiConstants.measurementActivity(
          key.custNo,
          key.billNo,
          key.year,
          key.seqNo,
        ),
        data: {'action': action},
      );
      final body = resp.data;

      return body is Map && body['success'] == true;
    } catch (_) {
      // التدقيق لا يُفشل الطباعة ولا التصدير — نفس قاعدة بقية شاشات التقارير.
      // Auditing never fails a print or an export — the rule on every other report screen.
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
  static MeasurementException _toException(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return MeasurementException(data['message'].toString());
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const MeasurementException(
        'انتهت مهلة الاتصال بالخادم — تحقّق من الشبكة وأعد المحاولة',
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const MeasurementException(
        'تعذّر الوصول إلى الخادم — تحقّق من الاتصال',
      );
    }

    return MeasurementException(fallback);
  }
}
