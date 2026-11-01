import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/store_orders_repository.dart';
import '../../data/repositories/store_result.dart';

/// مستودع الأوامر
/// The orders repository.
final storeOrdersRepositoryProvider = Provider<StoreOrdersRepository>((ref) {
  return StoreOrdersRepository(client: ref.watch(dioClientProvider));
});

/// حالة قائمة الأوامر لنوع واحد في كل مرة
/// The order-list state for one kind at a time.
///
/// ── لماذا ليست عائلة (family) لكل نوع؟ لأن الشاشة تُفتح لنوع واحد فقط، ولا تُعرض قائمتان
///    في نفس الوقت؛ والاحتفاظ بـ `kind` داخل الحالة يجعل الترتيب والترقيم مشتركين بلا تكرار.
/// ── Why not a per-kind family? The screen opens for one kind only and never shows two lists
///    at once; keeping `kind` inside the state lets paging and sorting be shared without
///    duplicating the notifier three times.
class OrdersListState {
  const OrdersListState({
    this.kind = StoreOrderKind.receive,
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.storeNo,
    this.from,
    this.to,
    this.sort = 'date',
    this.dir = 'desc',
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.selected = const {},
    this.selectionMode = false,
    this.busy = false,
  });

  final StoreOrderKind kind;
  final List<StoreOrderModel> orders;
  final bool isLoading;
  final String? error;
  final String search;
  final int? storeNo;
  final DateTime? from;
  final DateTime? to;
  final String sort;
  final String dir;
  final int page;
  final int pages;
  final int total;

  /// أرقام المستندات المحددة للإجراءات الجماعية
  /// The selected document numbers for bulk actions.
  final Set<int> selected;
  final bool selectionMode;
  final bool busy;

  int get filtersCount {
    var count = 0;
    if (storeNo != null) count++;
    if (from != null) count++;
    if (to != null) count++;

    return count;
  }

  double get totalNet => orders.fold(0, (sum, order) => sum + order.net);

  OrdersListState copyWith({
    StoreOrderKind? kind,
    List<StoreOrderModel>? orders,
    bool? isLoading,
    bool? busy,
    bool? selectionMode,
    String? search,
    String? sort,
    String? dir,
    String? error,
    int? storeNo,
    int? page,
    int? pages,
    int? total,
    DateTime? from,
    DateTime? to,
    Set<int>? selected,
    bool clearError = false,
    bool clearStore = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return OrdersListState(
      kind: kind ?? this.kind,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      selectionMode: selectionMode ?? this.selectionMode,
      search: search ?? this.search,
      sort: sort ?? this.sort,
      dir: dir ?? this.dir,
      error: clearError ? null : error ?? this.error,
      storeNo: clearStore ? null : storeNo ?? this.storeNo,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
      selected: selected ?? this.selected,
    );
  }
}

class OrdersListNotifier extends Notifier<OrdersListState> {
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  /// الشاشة تنادي [bind] قبل [load] لتحديد النوع المعروض
  /// The screen calls bind before load to declare the displayed kind.
  @override
  OrdersListState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    return const OrdersListState(isLoading: true);
  }

  StoreOrdersRepository get _repository => ref.read(storeOrdersRepositoryProvider);

  void bind(StoreOrderKind kind) {
    if (state.kind == kind && state.orders.isNotEmpty) return;

    state = OrdersListState(kind: kind, isLoading: true);
    Future.microtask(() => load());
  }

  Future<void> load({bool keepPage = false}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final version = ++_searchVersion;

    final page = keepPage ? state.page : 1;
    state = state.copyWith(isLoading: true, clearError: true, page: page);

    try {
      final result = await _repository.fetchOrders(
        state.kind,
        search: state.search,
        storeNo: state.storeNo,
        from: state.from,
        to: state.to,
        page: page,
        sort: state.sort,
        dir: state.dir,
        cancelToken: _cancelToken,
      );

      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(
        orders: result.items,
        isLoading: false,
        page: result.page,
        pages: result.pages,
        total: result.total,
      );
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim(), selected: const {});

    return load();
  }

  Future<void> applyFilters({
    int? storeNo,
    DateTime? from,
    DateTime? to,
    bool clearStore = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) async {
    state = state.copyWith(
      storeNo: storeNo,
      from: from,
      to: to,
      clearStore: clearStore,
      clearFrom: clearFrom,
      clearTo: clearTo,
      selected: const {},
    );

    return load();
  }

  Future<void> sortBy(String field) async {
    final ascending = state.sort == field ? state.dir == 'asc' : true;

    state = state.copyWith(sort: field, dir: ascending ? 'asc' : 'desc');

    return load();
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);

    return load(keepPage: true);
  }

  void toggleSelectionMode() =>
      state = state.copyWith(selectionMode: !state.selectionMode, selected: const {});

  void toggleSelected(int billNo) {
    final selected = {...state.selected};

    if (!selected.remove(billNo)) selected.add(billNo);

    state = state.copyWith(selected: selected);
  }

  void selectAll() =>
      state = state.copyWith(selected: state.orders.map((o) => o.billNo).toSet());

  void clearSelection() => state = state.copyWith(selected: const {});

  /// عكس التحديد — المحدد يُلغى وغير المحدد من الصفحة الحالية يُحدَّد
  /// Invert the selection: what is selected drops out and the rest of the page comes in.
  ///
  /// ── يُحسب من الصفحة المعروضة فقط لأن الإجراءات الجماعية تعمل على ما يراه المستخدم؛
  ///    تحديد صفوف في صفحات لم يفتحها يجعل الضغط على «حذف» يمسح أكثر مما قصد.
  /// ── Scoped to the visible page on purpose: bulk actions must touch what the user sees;
  ///    selecting unopened pages makes one delete press erase more than intended.
  void invertSelection() {
    final visible = state.orders.map((order) => order.billNo).toSet();

    state = state.copyWith(selected: visible.difference(state.selected));
  }

  /// حذف جماعي — كل مستند يُحذف بطلبه، والنتيجة تُجمع بدل إسقاط الكل عند أول فشل
  /// Bulk delete: each document gets its own request and failures are counted, not fatal.
  ///
  /// ── لماذا لا نُسقط الدفعة كلها عند أول فشل؟ لأن الحذف الفيزيائي لا يمكن التراجع عنه،
  ///    فإيقاف المنتصف يترك المستخدم بلا معرفة ما حُذف فعلاً وما بقي.
  /// ── Why not abort the whole batch on the first failure? Physical deletes cannot be undone,
  ///    so stopping halfway leaves the user unable to tell what actually went and what stayed.
  Future<({int deleted, int failed, String? message})> removeMany(
    Iterable<int> billNos,
  ) async {
    final targets = billNos.toList(growable: false);

    if (targets.isEmpty) {
      return (deleted: 0, failed: 0, message: null);
    }

    state = state.copyWith(busy: true);

    var deleted = 0;
    String? message;

    for (final billNo in targets) {
      final result = await _repository.deleteOrder(state.kind, billNo);

      if (result.success) {
        deleted++;
      } else {
        message ??= result.displayMessage;
      }
    }

    state = state.copyWith(
      busy: false,
      selected: const {},
      selectionMode: false,
    );

    if (deleted > 0) await load(keepPage: true);

    return (
      deleted: deleted,
      failed: targets.length - deleted,
      message: message,
    );
  }

  /// حذف مستند — الحذف في الخادم فيزيائي ويُلغي أثره على الرصيد
  /// Delete a document — physical server-side, which is what removes its stock effect.
  Future<StoreResult> remove(int billNo) async {
    state = state.copyWith(busy: true);

    final result = await _repository.deleteOrder(state.kind, billNo);

    state = state.copyWith(busy: false);

    if (result.success) await load(keepPage: true);

    return result;
  }
}

final ordersListProvider = NotifierProvider<OrdersListNotifier, OrdersListState>(
  OrdersListNotifier.new,
);

/// أمر واحد بسطوره — عائلة بمفتاح رقم المستند
/// One order with its lines — a family keyed by the bill number.
final orderDetailProvider =
    FutureProvider.family<StoreOrderDetail?, ({StoreOrderKind kind, int billNo})>((
      ref,
      key,
    ) async {
      return ref
          .watch(storeOrdersRepositoryProvider)
          .fetchOrder(key.kind, key.billNo);
    });
