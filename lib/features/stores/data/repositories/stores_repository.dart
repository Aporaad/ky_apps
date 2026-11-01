import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/store_model.dart';
import '../models/store_reference.dart';
import 'store_result.dart';

/// مستودع المخازن: المخازن نفسها وأمناؤها والمراجع المشتركة
/// The stores repository: stores, keepers and the shared reference bundle.
///
/// ── الطبقة الوحيدة التي تلمس Dio في هذا القسم. الشاشات والمزودات لا تعرف شيئاً عن الشبكة.
/// ── The only layer that touches Dio in this module; screens and notifiers never do.
class StoresRepository {
  StoresRepository({required this.client});

  final DioClient client;

  /// قائمة المخازن مع مؤشراتها
  /// The store list with its indicators.
  Future<List<StoreModel>> fetchStores({
    String search = '',
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.stores,
        queryParameters: {if (search.isNotEmpty) 'search': search},
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];

      if (body['success'] != true || raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(StoreModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      rethrow;
    }
  }

  Future<StoreResult> createStore(Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.post(ApiConstants.stores, data: payload);

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateStore(int storeNo, Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.put(
        '${ApiConstants.stores}/$storeNo',
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteStore(int storeNo) async {
    try {
      final response = await client.dio.delete('${ApiConstants.stores}/$storeNo');

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  // ── أمناء المخازن / store keepers ─────────────────────────

  Future<List<StoreKeeperModel>> fetchKeepers({CancelToken? cancelToken}) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeKeepers,
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];

      if (body['success'] != true || raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(StoreKeeperModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      rethrow;
    }
  }

  Future<StoreResult> createKeeper(Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.post(
        ApiConstants.storeKeepers,
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateKeeper(int empNo, Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.put(
        '${ApiConstants.storeKeepers}/$empNo',
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteKeeper(int empNo) async {
    try {
      final response = await client.dio.delete(
        '${ApiConstants.storeKeepers}/$empNo',
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  // ── المراجع / reference ───────────────────────────────────

  /// حزمة المراجع الكاملة — تُطلب مرة واحدة عند فتح أي شاشة تحتاج قوائم منسدلة
  /// The full reference bundle, requested once by any screen that needs dropdowns.
  Future<StoreReference?> fetchReference({CancelToken? cancelToken}) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeReference,
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      if (body['success'] != true || data is! Map<String, dynamic>) return null;

      return StoreReference.fromJson(data);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return null;
      rethrow;
    }
  }

  // ── المرجعيات / catalogs ──────────────────────────────────

  /// جلب مرجعية واحدة كنماذج مطبوعة النوع
  /// Fetch one catalog as typed models.
  Future<List<T>> fetchCatalog<T>(
    String kind,
    T Function(Map<String, dynamic>) parse, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        '${ApiConstants.stores}/catalogs/$kind',
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];

      if (body['success'] != true || raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(parse)
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      rethrow;
    }
  }

  Future<StoreResult> createCatalog(
    String kind,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.post(
        '${ApiConstants.stores}/catalogs/$kind',
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateCatalog(
    String kind,
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.put(
        '${ApiConstants.stores}/catalogs/$kind/$id',
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteCatalog(String kind, int id) async {
    try {
      final response = await client.dio.delete(
        '${ApiConstants.stores}/catalogs/$kind/$id',
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }
}
