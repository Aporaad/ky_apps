import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/store_items_repository.dart';
import '../../data/repositories/store_result.dart';

/// مستودع الأصناف
/// The items repository.
final storeItemsRepositoryProvider = Provider<StoreItemsRepository>((ref) {
  return StoreItemsRepository(client: ref.watch(dioClientProvider));
});

/// مرشّح الصنف الرئيسي/الفرعي — يُستخدم في التقارير أيضاً
/// The main/sub item picker — reused by the reports too.
class ItemsListState {
  const ItemsListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.groupNo,
    this.typeNo,
    this.catNo,
    this.unitNo,
    this.active = 'all',
    this.sort = 'name',
    this.dir = 'asc',
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.selected = const {},
    this.selectionMode = false,
    this.busy = false,
  });

  final List<ItemModel> items;
  final bool isLoading;
  final String? error;
  final String search;
  final int? groupNo;
  final int? typeNo;
  final int? catNo;
  final int? unitNo;
  final String active;
  final String sort;
  final String dir;
  final int page;
  final int pages;
  final int total;

  /// معرّفات الأصناف المحددة في وضع التحديد المتعدد
  /// The ids selected while the multi-select mode is on.
  final Set<int> selected;
  final bool selectionMode;
  final bool busy;

  int get filtersCount {
    var count = 0;
    if (groupNo != null) count++;
    if (typeNo != null) count++;
    if (catNo != null) count++;
    if (unitNo != null) count++;
    if (active != 'all') count++;

    return count;
  }

  List<ItemModel> get selectedItems =>
      items.where((item) => selected.contains(item.sanfNo)).toList(growable: false);

  ItemsListState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    bool? busy,
    bool? selectionMode,
    String? search,
    String? active,
    String? sort,
    String? dir,
    String? error,
    int? groupNo,
    int? typeNo,
    int? catNo,
    int? unitNo,
    int? page,
    int? pages,
    int? total,
    Set<int>? selected,
    bool clearError = false,
    bool clearGroup = false,
    bool clearType = false,
    bool clearCat = false,
    bool clearUnit = false,
  }) {
    return ItemsListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      selectionMode: selectionMode ?? this.selectionMode,
      search: search ?? this.search,
      active: active ?? this.active,
      sort: sort ?? this.sort,
      dir: dir ?? this.dir,
      error: clearError ? null : error ?? this.error,
      groupNo: clearGroup ? null : groupNo ?? this.groupNo,
      typeNo: clearType ? null : typeNo ?? this.typeNo,
      catNo: clearCat ? null : catNo ?? this.catNo,
      unitNo: clearUnit ? null : unitNo ?? this.unitNo,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      selected: selected ?? this.selected,
    );
  }
}

class ItemsListNotifier extends Notifier<ItemsListState> {
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  @override
  ItemsListState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    Future.microtask(() => load());

    return const ItemsListState(isLoading: true);
  }

  StoreItemsRepository get _repository => ref.read(storeItemsRepositoryProvider);

  Future<void> load({bool keepPage = false}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final version = ++_searchVersion;

    final page = keepPage ? state.page : 1;
    state = state.copyWith(isLoading: true, clearError: true, page: page);

    try {
      final result = await _repository.fetchItems(
        search: state.search,
        page: page,
        groupNo: state.groupNo,
        typeNo: state.typeNo,
        catNo: state.catNo,
        unitNo: state.unitNo,
        active: state.active,
        sort: state.sort,
        dir: state.dir,
        cancelToken: _cancelToken,
      );

      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(
        items: result.items,
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
    int? groupNo,
    int? typeNo,
    int? catNo,
    int? unitNo,
    String? active,
    bool clearGroup = false,
    bool clearType = false,
    bool clearCat = false,
    bool clearUnit = false,
  }) async {
    state = state.copyWith(
      groupNo: groupNo,
      typeNo: typeNo,
      catNo: catNo,
      unitNo: unitNo,
      active: active,
      clearGroup: clearGroup,
      clearType: clearType,
      clearCat: clearCat,
      clearUnit: clearUnit,
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

  void toggleSelectionMode() {
    state = state.copyWith(
      selectionMode: !state.selectionMode,
      selected: const {},
    );
  }

  void toggleSelected(int sanfNo) {
    final selected = {...state.selected};

    if (!selected.remove(sanfNo)) selected.add(sanfNo);

    state = state.copyWith(selected: selected);
  }

  void selectAll() {
    state = state.copyWith(
      selected: state.items.map((item) => item.sanfNo).toSet(),
    );
  }

  void clearSelection() => state = state.copyWith(selected: const {});

  Future<StoreResult> remove(int sanfNo) async {
    state = state.copyWith(busy: true);

    final result = await _repository.deleteItem(sanfNo);

    state = state.copyWith(busy: false);

    if (result.success) await load(keepPage: true);

    return result;
  }

  /// إعادة جلب الصنف المحدد فقط بعد تعديله — بدل إعادة تحميل الصفحة كاملة
  /// Refresh a single edited item instead of reloading the whole page.
  Future<void> refreshCurrent() => load(keepPage: true);
}

final itemsListProvider = NotifierProvider<ItemsListNotifier, ItemsListState>(
  ItemsListNotifier.new,
);

/// تفصيل صنف واحد — عائلة بمفتاح رقم الصنف
/// One item's detail — a family keyed by the item number.
final itemDetailProvider = FutureProvider.family<ItemDetail?, int>((
  ref,
  sanfNo,
) async {
  return ref.watch(storeItemsRepositoryProvider).fetchItem(sanfNo);
});

/// كارت الصنف
/// The item movement card.
final itemMovementsProvider =
    FutureProvider.family<List<StockMovementRow>, int?>((ref, sanfNo) async {
      if (sanfNo == null) return const [];

      return ref.watch(storeItemsRepositoryProvider).fetchMovements(sanfNo);
    });
