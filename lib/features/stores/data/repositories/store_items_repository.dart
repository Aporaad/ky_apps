import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/json_value_utils.dart';
import '../models/item_model.dart';
import '../models/report_model.dart';
import 'store_result.dart';

/// حزمة تفصيل الصنف: رأسه + أصنافه الفرعية بكمياتها + وحداته وأسعاره
/// The item detail bundle: header, sub items with their quantities, units and prices.
class ItemDetail {
  const ItemDetail({
    required this.item,
    this.subs = const [],
    this.units = const [],
  });

  final ItemModel item;
  final List<ItemSubModel> subs;
  final List<ItemUnitModel> units;

  /// إجمالي رصيد الصنف — مجموع أرصدة فروعه، وهو تعريف المستخدم للرصيد
  /// The item's balance: the sum of its branches, which is the user's own definition.
  ///
  /// ── لا `AVVG`: نفس الأرقام لكن من `ITEM_MOVEMENT_D` مباشرة، لأن تجميع `AVVG` يكلّف
  ///    14,589 مللي مقابل 1,552 مللي لتجميع الحركة بالفرع.
  /// ── Not AVVG: the same numbers from ITEM_MOVEMENT_D directly, because rolling up AVVG costs
  ///    14,589ms against 1,552ms for the per-branch movement aggregate.
  double get totalQty => subs.fold(0, (sum, sub) => sum + sub.qty);

  /// إجمالي قيمة الرصيد من قيم الفروع
  /// The total stock value, rolled up from the branches.
  double get totalValue => subs.fold(0, (sum, sub) => sum + sub.value);
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

  /// قائمة الأصناف الرئيسية — مع أرصدتها دائماً
  /// The main items list — always with its balances.
  ///
  /// ── الرصيد الآن رخيص (تجميع الحركة بالفرع ≈ ١.٥ ثانية)، فلم تعد هناك حاجة إلى جعله اختيارياً:
  ///    المستخدم يريد رصيد الصنف في واجهة الأصناف نفسها، لا في شاشة الأرصدة.
  /// ── Balance is cheap now (branch movement rollup ≈ 1.5s), so making it optional is moot: the
  ///    user wants an item's balance on the items screen itself, not on the balances screen.
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

      return _uniqueBy(
        StorePage.parse<ItemModel>(
          response.data as Map<String, dynamic>,
          ItemModel.fromJson,
        ),
        _distinctItems,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StorePage<ItemModel>();
      rethrow;
    }
  }

  /// إعادة الصفحة بمفاتيح فريدة فقط إن وجد تكرار — بلا نسخ بلا داعٍ
  /// Rebuild the page with unique keys only when something repeated — no copying otherwise.
  static StorePage<T> _uniqueBy<T>(
    StorePage<T> page,
    List<T> Function(List<T>) distinct,
  ) {
    final items = distinct(page.items);

    if (items.length == page.items.length) return page;

    return StorePage<T>(
      items: items,
      total: page.total,
      page: page.page,
      pages: page.pages,
      meta: page.meta,
    );
  }

  /// ── إزالة التكرار بمعرّف الفرع: طبقة حماية ثانية فوق ضمان الخادم (التجميع بـ`SANF_DNO`).
  ///    العرض الذي يُظهر الفرع مرتين يُفقد المستخدم ثقته في الأرقام كلها، فالحارس رخيص ومطلوب.
  /// ── De-duplication by branch id: a second guard above the server's own guarantee (grouping by
  ///    SANF_DNO). A list that shows a branch twice destroys trust in every number on screen, so
  ///    the guard is cheap and worth having.
  static List<ItemSubModel> _distinctBranches(List<ItemSubModel> rows) {
    final seen = <int>{};

    return [
      for (final row in rows)
        if (seen.add(row.sanfDno)) row,
    ];
  }

  /// نفس الحارس للأصناف الرئيسية بمعرّفها
  /// The same guard for main items, keyed by their own id.
  static List<ItemModel> _distinctItems(List<ItemModel> rows) {
    final seen = <int>{};

    return [
      for (final row in rows)
        if (seen.add(row.sanfNo)) row,
    ];
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
        // إزالة التكرار حتى لو ضاعف رابطٌ الصفوف: التفصيل لا يعرض الفرع مرتين
        // De-duplicated even if a join multiplies rows: a branch is never shown twice here.
        subs: _distinctBranches(list('subs', ItemSubModel.fromJson)),
        units: list('units', ItemUnitModel.fromJson),
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

  Future<StoreResult> createSub(
    int sanfNo,
    Map<String, dynamic> payload,
  ) async {
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

  Future<StoreResult> createUnit(
    int sanfNo,
    Map<String, dynamic> payload,
  ) async {
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

  /// تبويب الأصناف الفرعية — كل الفروع بصفحات
  /// The sub-items tab — every branch, paged.
  Future<StorePage<ItemSubModel>> fetchSubItems({
    String search = '',
    int page = 1,
    int limit = 50,
    int? groupNo,
    int? typeNo,
    String active = 'all',
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeSubItems,
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
          if (groupNo != null) 'group_no': groupNo,
          if (typeNo != null) 'type_no': typeNo,
          if (active != 'all') 'active': active,
        },
        cancelToken: cancelToken,
      );

      return _uniqueBy(
        StorePage.parse<ItemSubModel>(
          response.data as Map<String, dynamic>,
          ItemSubModel.fromJson,
        ),
        _distinctBranches,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const StorePage<ItemSubModel>();
      rethrow;
    }
  }

  /// كارت الصنف
  /// The item movement card.
  Future<List<StockMovementRow>> fetchMovements(
    int sanfNo, {
    int? storeNo,
    int? subDno,
    DateTime? from,
    DateTime? to,
    int limit = 200,
    CancelToken? cancelToken,
  }) async {
    final statement = await fetchMovementStatement(
      sanfNo,
      storeNo: storeNo,
      subDno: subDno,
      from: from,
      to: to,
      limit: limit,
      cancelToken: cancelToken,
    );

    return statement.rows;
  }

  /// كشف حركة كامل: السطور + مجاميع محسوبة على الخادم
  /// The full movement statement: rows plus server-side totals.
  ///
  /// ── المجاميع من الخادم لا من السطور المعروضة: الصفوف تُقصّ بحدّ `limit`، فجمعها في العميل
  ///    يعطي رصيداً كاذباً بمجرد أن تتجاوز الحركات هذا الحد.
  /// ── Totals come from the server, never from the visible rows: rows are capped by `limit`,
  ///    so summing them client-side silently lies once movements exceed the cap.
  Future<MovementStatement> fetchMovementStatement(
    int sanfNo, {
    int? storeNo,
    int? subDno,
    DateTime? from,
    DateTime? to,
    int limit = 500,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await client.dio.get(
        ApiConstants.storeItemMovements(sanfNo),
        queryParameters: {
          'limit': limit,
          if (storeNo != null) 'store_no': storeNo,
          if (subDno != null) 'sub_dno': subDno,
          if (from != null) 'from': _dateText(from),
          if (to != null) 'to': _dateText(to),
        },
        cancelToken: cancelToken,
      );

      final body = response.data as Map<String, dynamic>;
      final raw = body['data'];

      if (body['success'] != true || raw is! List) {
        return const MovementStatement();
      }

      final rows = raw
          .whereType<Map<String, dynamic>>()
          .map(StockMovementRow.fromJson)
          .toList(growable: false);

      final meta = body['meta'];
      final totals = meta is Map ? meta['totals'] : null;
      final map = totals is Map ? totals : const {};

      double total(String upper, String lower) =>
          JsonValues.asDoubleOrNull(map[upper] ?? map[lower]) ?? 0;

      return MovementStatement(
        rows: rows,
        qtyIn: total('QTY_IN', 'qty_in'),
        qtyOut: total('QTY_OUT', 'qty_out'),
        netQty: total('QTY_NET', 'qty_net'),
        value: total('VALUE', 'value'),
        lines: JsonValues.asInt(map['LINES'] ?? map['lines']),
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const MovementStatement();
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
