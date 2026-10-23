import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/corp_model.dart';
import '../models/service_model.dart';
import 'service_result.dart';

/// مستودع إعدادات الخدمات — CORP (singleton) + SERVICES (قاموس)
/// Service-config repository — the CORP singleton and the SERVICES dictionary.
class ServiceConfigRepository {
  final DioClient client;

  ServiceConfigRepository({required this.client});

  Future<Map<String, dynamic>?> fetchConfig({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get('/service-config', cancelToken: cancelToken);
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final corp = body['corp'];
        final services = (body['services'] as List? ?? [])
            .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'corp': corp != null ? CorpModel.fromJson(corp as Map<String, dynamic>) : null,
          'services': services,
        };
      }
      return null;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  Future<ServiceResult> updateCorp(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('/service-config/corp', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> createService(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post('/services', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> deleteService(int id) async {
    try {
      final resp = await client.dio.delete('/services/$id');
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
