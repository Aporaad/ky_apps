import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import 'store_result.dart';

/// حزمة تفصيل الصنف: رأسه + أصنافه الفرعية + وحداته + أرصدته
/// The item detail bundle: header, sub items, units and balances.
class ItemDetail {
  const ItemDetail({
    required this.item,
    this.subs = const [],
    this.units = const [],
    this.balances = const [],
  });

  final ItemModel item;
  final List<ItemSubModel> subs;
  final List<ItemUnitModel> units;
  final List<ItemBalanceModel> balances;

  /// إجمالي الرصيد في كل المخازن
  /// The total balance across every store.
  double get totalQty => balances.fold(0, (sum, row) => sum + row.qty);
}

/// مستودع الأصناف
/// The items repository.
///
/// ── إنشاء الصنف يكتب ثلاثTables في الخادم (SANFS + SANFS_D + PARTIAL_SANFS) لأن الصنف
///    بلا صنف فرعي لا يصلح لمستند ولا لرصيد.
/// ── Item creation writes three tables server-side (SANFS + SANFS_D + PARTIAL_SANFS):
///    an item without a sub item cannot be used by any document nor reach any balance.
class StoreItemsRepository {
  StoreItemsRepository({required this.client});

  final DioClient client;

  Future<StorePage<ItemModel>> fetchItems({
    String search = '',
    int page = 1,
    int limit = 50,
    int? groupNo,
    int? typeNo,
    int? catNo,
    int? unitNo,
    String active = 'all',
    String sort = 'name',
    String dir = 'asc',
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeItems,
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
          if (groupNo != null) 'group_no': groupNo,
          if (typeNo != null) 'type_no': typeNo,
          if (catNo != null) 'cat_no': catNo,
          if (unitNo != null) 'unit_no': unitNo,
          if (active != 'all') 'active': active,
          'sort': sort,
          'dir': dir,
        },
        cancelToken: cancelToken,
      );

      return StorePage.parse<ItemModel>(
        response.data as Map<String, dynamic>,
        ItemModel.fromJson,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StorePage<ItemModel>();
      rethrow;
    }
  }

  /// تفصيل صنف واحد
  /// One item's detail.
  Future<ItemDetail?> fetchItem(int sanfNo, {CancelToken? cancelToken}) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeItem(sanfNo),
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final data = body['data'];

      if (body['success'] != true || data is! Map<String, dynamic>) return null;

      final rawItem = data['item'];

      if (rawItem is! Map<String, dynamic>) return null;

      List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
        final raw = data[key];

        if (raw is! List) return const [];

        return raw
            .whereType<Map<String, dynamic>>()
            .map(parse)
            .toList(growable: false);
      }

      return ItemDetail(
        item: ItemModel.fromJson(rawItem),
        subs: list('subs', ItemSubModel.fromJson),
        units: list('units', ItemUnitModel.fromJson),
        balances: list('balances', ItemBalanceModel.fromJson),
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return null;
      rethrow;
    }
  }

  Future<StoreResult> createItem(Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.post(
        ApiConstants.storeItems,
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateItem(
    int sanfNo,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.put(
        ApiConstants.storeItem(sanfNo),
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteItem(int sanfNo) async {
    try {
      final response = await client.dio.delete(ApiConstants.storeItem(sanfNo));

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  // ── الأصناف الفرعية / sub items ───────────────────────────

  Future<StoreResult> createSub(int sanfNo, Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.post(
        ApiConstants.storeItemSubs(sanfNo),
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> updateSub(
    int sanfNo,
    int sanfDno,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await client.dio.put(
        '${ApiConstants.storeItemSubs(sanfNo)}/$sanfDno',
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteSub(int sanfNo, int sanfDno) async {
    try {
      final response = await client.dio.delete(
        '${ApiConstants.storeItemSubs(sanfNo)}/$sanfDno',
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  // ── الوحدات والأسعار / units and prices ───────────────────

  Future<StoreResult> createUnit(int sanfNo, Map<String, dynamic> payload) async {
    try {
      final response = await client.dio.post(
        ApiConstants.storeItemUnits(sanfNo),
        data: payload,
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  Future<StoreResult> deleteUnit(int sanfNo, double cap) async {
    try {
      final response = await client.dio.delete(
        '${ApiConstants.storeItemUnits(sanfNo)}/$cap',
      );

      return StoreResult.fromBody(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      return StoreResult.fromDio(error);
    }
  }

  /// كارت الصنف
  /// The item movement card.
  Future<List<StockMovementRow>> fetchMovements(
    int sanfNo, {
    int? storeNo,
    DateTime? from,
    DateTime? to,
    int limit = 200,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeItemMovements(sanfNo),
        queryParameters: {
          'limit': limit,
          if (storeNo != null) 'store_no': storeNo,
          if (from != null) 'from': _dateText(from),
          if (to != null) 'to': _dateText(to),
        },
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];

      if (body['success'] != true || raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(StockMovementRow.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      rethrow;
    }
  }

  static String _dateText(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }
}
