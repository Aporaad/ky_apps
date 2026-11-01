import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';
import 'store_result.dart';

/// أمر مقروء: رأسه وسطوره
/// A read order: its header and lines.
class StoreOrderDetail {
  const StoreOrderDetail({required this.header, this.lines = const []});

  final StoreOrderModel header;
  final List<StoreOrderLineModel> lines;
}

/// مستودع أوامر المخازن الثلاثة — توريد · صرف · تحويل
/// The three inventory document kinds — receive · issue · transfer.
///
/// ── مسار واحد لكل نوع يُبنى من [StoreOrderKind.code]، فلا تتفرّع الطلبات هنا؛ الاختلاف كله
///    في الحقول المرسلة التي يبنيها نموذج الإدخال.
/// ── One path per kind built from StoreOrderKind.code, so the requests never branch here;
///    the only difference lives in the payload the form assembles.
class StoreOrdersRepository {
  StoreOrdersRepository({required this.client});

  final DioClient client;

  Future<StorePage<StoreOrderModel>> fetchOrders(
    StoreOrderKind kind, {
    String search = '',
    int? storeNo,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 50,
    String sort = 'date',
    String dir = 'desc',
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeOrders(kind.code),
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          if (storeNo != null) 'store_no': storeNo,
          if (from != null) 'from': _dateText(from),
          if (to != null) 'to': _dateText(to),
          'page': page,
          'limit': limit,
          'sort': sort,
          'dir': dir,
        },
        cancelToken: cancelToken,
      );

      return StorePage.parse<StoreOrderModel>(
        response.data as Map<String, dynamic>,
        StoreOrderModel.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StorePage<StoreOrderModel>();
      rethrow;
    }
  }

  Future<StoreOrderDetail?> fetchOrder(
    StoreOrderKind kind,
    int billNo, {
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeOrder(kind.code, billNo),
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      if (body['success'] != true || data is! Map<String, dynamic>) return null;

      final rawHeader = data['header'];

      if (rawHeader is! Map<String, dynamic>) return null;

      final rawLines = data['lines'];

      return StoreOrderDetail(
        header: StoreOrderModel.fromJson(rawHeader),
        lines: rawLines is List
            ? rawLines
                  .whereType<Map<String, dynamic>>()
                  .map(StoreOrderLineModel.fromJson)
                  .toList(growable: false)
            : const [],
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return null;
      rethrow;
    }
  }

  Future<StoreResult> createOrder(
    StoreOrderKind kind,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.post(
        ApiConstants.storeOrders(kind.code),
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateOrder(
    StoreOrderKind kind,
    int billNo,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.put(
        ApiConstants.storeOrder(kind.code, billNo),
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteOrder(StoreOrderKind kind, int billNo) async {
    try {
      final response = await client.dio.delete(
        ApiConstants.storeOrder(kind.code, billNo),
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  static String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
}
