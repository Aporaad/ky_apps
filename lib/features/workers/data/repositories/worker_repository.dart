import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/worker_model.dart';
import '../models/worker_statement_model.dart';

/// نتيجة عملية العامل
class WorkerResult {
  final bool success;
  final String message;
  final dynamic data;

  const WorkerResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// مستودع بيانات العمال - يتصل بالـ API وسيرفر أوراكل
class WorkerRepository {
  final DioClient client;

  WorkerRepository({required this.client});

  /// إلغاء جميع الطلبات الجارية
  void cancel() {
    // دعم دالة الإلغاء العامة عند الحاجة
  }

  /// جلب قائمة العمال
  Future<List<WorkerModel>> fetchWorkers(
    WorkerType type, {
    String search = '',
    int page = 1,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/workers/${type.apiPath}',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        return list.map((e) => _parseWorker(type, e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// إضافة عامل جديد
  Future<WorkerResult> createWorker(WorkerModel worker) async {
    try {
      final resp = await client.dio.post(
        '/workers/${worker.type.apiPath}',
        data: worker.toJsonForApi(),
      );
      final body = resp.data as Map<String, dynamic>;
      return WorkerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['id'],
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ??
          e.message ??
          'خطأ في الشبكة';
      return WorkerResult(success: false, message: msg.toString());
    }
  }

  /// تعديل بيانات عامل
  Future<WorkerResult> updateWorker(WorkerModel worker) async {
    try {
      final resp = await client.dio.put(
        '/workers/${worker.type.apiPath}/${worker.id}',
        data: worker.toJsonForApi(),
      );
      final body = resp.data as Map<String, dynamic>;
      return WorkerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ??
          e.message ??
          'خطأ في الشبكة';
      return WorkerResult(success: false, message: msg.toString());
    }
  }

  /// حذف عامل
  Future<WorkerResult> deleteWorker(WorkerType type, int id) async {
    try {
      final resp = await client.dio.delete('/workers/${type.apiPath}/$id');
      final body = resp.data as Map<String, dynamic>;
      return WorkerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ??
          e.message ??
          'خطأ في الشبكة';
      return WorkerResult(success: false, message: msg.toString());
    }
  }

  /// تغيير حالة عامل (تعطيل/تفعيل)
  Future<WorkerResult> toggleWorker(WorkerType type, int id) async {
    try {
      final resp = await client.dio.patch('/workers/${type.apiPath}/$id/toggle');
      final body = resp.data as Map<String, dynamic>;
      return WorkerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['new_status'],
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ??
          e.message ??
          'خطأ في الشبكة';
      return WorkerResult(success: false, message: msg.toString());
    }
  }

  /// كشف حساب عامل
  Future<Map<String, dynamic>?> fetchStatement(
    WorkerType type,
    int id, {
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/workers/${type.apiPath}/$id/statement',
        queryParameters: {
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final rows = (body['data'] as List? ?? [])
            .map((e) => WorkerStatementModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'worker': body['worker'],
          'rows': rows,
          'summary': body['summary'],
        };
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  WorkerModel _parseWorker(WorkerType type, Map<String, dynamic> json) {
    switch (type) {
      case WorkerType.employee:
        return WorkerModel.fromEmployeeJson(json);
      case WorkerType.cutter:
        return WorkerModel.fromCutterJson(json);
      case WorkerType.tailor:
        return WorkerModel.fromTailorJson(json);
    }
  }
}
