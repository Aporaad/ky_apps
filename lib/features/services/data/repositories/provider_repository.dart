import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/provider_model.dart';
import '../models/provider_subscription_model.dart';
import 'service_result.dart';

/// مستودع المزودين واشتراكاتهم — Dio هو طبقة الشبكة الوحيدة
/// Providers & subscriptions repository — Dio is the only network layer.
class ProviderRepository {
  final DioClient client;

  ProviderRepository({required this.client});

  Future<List<ProviderModel>> fetchProviders({
    String search = '',
    int page = 1,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/providers',
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
        return list
            .map((e) => ProviderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  Future<ProviderModel?> fetchProvider(int id, {CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get('/providers/$id', cancelToken: cancelToken);
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return ProviderModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  Future<ServiceResult> createProvider(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post('/providers', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['provider_id'],
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> updateProvider(int id, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('/providers/$id', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> toggleProvider(int id) async {
    try {
      final resp = await client.dio.patch('/providers/$id/toggle');
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['status'],
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> deleteProvider(int id) async {
    try {
      final resp = await client.dio.delete('/providers/$id');
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<List<ProviderSubscriptionModel>> fetchSubscriptions(
    int providerId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/providers/$providerId/subscriptions',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        return list
            .map((e) => ProviderSubscriptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  Future<ServiceResult> createSubscription(
    int providerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await client.dio.post(
        '/providers/$providerId/subscriptions',
        data: data,
      );
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> deleteSubscription(int dtlId) async {
    try {
      final resp = await client.dio.delete('/provider-subscriptions/$dtlId');
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
