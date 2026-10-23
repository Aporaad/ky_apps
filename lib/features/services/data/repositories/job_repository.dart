import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/job_run_model.dart';
import '../models/oracle_job_model.dart';
import 'service_result.dart';

/// مستودع المهام الزمنية — يدير مهام `DBMS_SCHEDULER` عبر الخادم
/// Scheduler-jobs repository — manages DBMS_SCHEDULER jobs through the backend.
class JobRepository {
  final DioClient client;

  JobRepository({required this.client});

  Future<List<OracleJobModel>> fetchJobs({
    bool all = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/jobs',
        queryParameters: {'all': all ? '1' : '0'},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        return list
            .map((e) => OracleJobModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  Future<List<JobRunModel>> fetchHistory(
    String jobName, {
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/jobs/$jobName/history',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        return list.map((e) => JobRunModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  Future<ServiceResult> create(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post('/jobs', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> update(String jobName, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('/jobs/$jobName', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> toggle(String jobName, bool enabled) async {
    try {
      final resp = await client.dio.patch('/jobs/$jobName/toggle', data: {
        'enabled': enabled,
      });
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> delete(String jobName) async {
    try {
      final resp = await client.dio.delete('/jobs/$jobName');
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }
}
