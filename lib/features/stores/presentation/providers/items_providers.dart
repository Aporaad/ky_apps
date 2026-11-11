import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';
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

  /// هل طُبّقت التصفية الافتراضية؟ تُطبَّق مرة واحدة لكل جلسة شاشة
  /// Whether the default filter was applied — once per screen session.
  bool _defaultsApplied = false;

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

  /// تفريغ البحث والتصفية عند مغادرة القسم أو نهاية الجلسة.
  /// Clears the search and every filter when the section closes or the session ends.
  ///
  /// تُعاد عداد `_defaultsApplied` إلى false حتى تُفرَض التصفية الافتراضية
  /// من جديد عند العودة إلى القسم (نفس السلوك الذي رآه المستخدم أول مرة).
  /// `_defaultsApplied` is reset so the default filter re-imposes on the next
  /// entry, matching what the user saw on their very first visit.
  ///
  /// `reload` — الشاشة تبقى mounted داخل `IndexedStack` فلا يُعاد `initState`؛
  ///    الجلب ضروري لعرض القائمة كاملة بدل نتائج البحث القديمة.
  /// `reload` — the screen stays mounted inside the `IndexedStack` and
  ///    `initState` never reruns; refetching is what shows the unfiltered list
  ///    in place of the last search's rows.
  void resetTransient({bool reload = false}) {
    _searchVersion++;
    _cancelToken?.cancel('screen-exited');
    _defaultsApplied = false;
    state = const ItemsListState(isLoading: true);
    if (reload) Future.microtask(load);
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

  Future<void> sortBy(String field, String dir) async {
    state = state.copyWith(sort: field, dir: dir);

    return load();
  }

  /// تبديل الاتجاه دون تغيير الحقل — يستخدمه زر «تصاعدي/تنازلي» في ورقة الترتيب
  /// Toggle direction without changing the field — used by the direction button in the sheet.
  Future<void> toggleSortDir() async {
    state = state.copyWith(dir: state.dir == 'asc' ? 'desc' : 'asc');

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

  /// التصفية الافتراضية: النشط فقط · أول مجموعة رئيسية · أول مجموعة فرعية منها · كل الفئات
  /// The default filter: active only, the first main group, its first sub group, all categories.
  ///
  /// ── لماذا مرة واحدة فقط؟ لأن المستخدم قد يمسح التصفية عمداً؛ إعادة فرضها بعد كل بناء تجعل
  ///    زر «مسح التصفية» بلا أثر ويوهمه أن التطبيق لا يستجيب.
  /// ── Why exactly once? The user may deliberately clear the filter; re-imposing it on every
  ///    build would make "clear filter" a no-op and look like the app ignores them.
  Future<void> applyDefaults(StoreReference reference) async {
    if (_defaultsApplied) return;

    _defaultsApplied = true;

    // ── لا نُطبّق تصفية على مجموعة برقم غير صالح: المجموعة 0 تعني «لا نتائج» دائماً، فيظهر
    //    التطبيق كأنه لا يملك أصنافاً. عند غياب مجموعة صالحة نُحمّل بلا تصفية بدل قائمة فارغة.
    // ── Never filter on an invalid group number: group 0 always means "no rows", which makes the
    //    app look like it has no items at all. With no usable group we load unfiltered instead.
    final usable = reference.groups
        .where((group) => group.groupNo > 0)
        .toList(growable: false);

    if (usable.isEmpty) {
      await load();

      return;
    }

    final group = usable.first;
    final types = reference
        .typesOfGroup(group.groupNo)
        .where((type) => type.typeNo > 0)
        .toList(growable: false);

    state = state.copyWith(
      active: '1',
      groupNo: group.groupNo,
      typeNo: types.isEmpty ? null : types.first.typeNo,
      // الفئات: لا قيد — المستخدم طلب عرض كل الفئات افتراضياً
      // Categories: unconstrained — every category is shown by default.
      clearCat: true,
      clearUnit: true,
      clearError: true,
      selected: const {},
    );

    await load();
  }
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

// ================================================================
// كشف حركة الصنف (تقرير)
// The item movement statement (a report)
// ================================================================

/// مفتاح كشف الحركة: صنف + فرع اختياري + مدى تاريخي + مخزن
/// The movement statement key: an item, an optional branch, a date range and a store.
typedef ItemStatementKey = ({
  int sanfNo,
  int? subDno,
  DateTime? from,
  DateTime? to,
  int? storeNo,
});

/// كشف حركة صنف — عائلة لأن كل تركيبة معطيات تقرير مستقل
/// An item's movement statement — a family, because each parameter set is its own report.
final itemStatementProvider =
    FutureProvider.family<MovementStatement, ItemStatementKey>((ref, key) async {
      return ref
          .watch(storeItemsRepositoryProvider)
          .fetchMovementStatement(
            key.sanfNo,
            subDno: key.subDno,
            from: key.from,
            to: key.to,
            storeNo: key.storeNo,
          );
    });

// ================================================================
// تبويب الأصناف الفرعية
// The sub-items tab
// ================================================================

class SubItemsListState {
  const SubItemsListState({
    this.rows = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.groupNo,
    this.typeNo,
    this.active = 'all',
    this.sort = 'parent',
    this.dir = 'asc',
    this.page = 1,
    this.pages = 1,
    this.total = 0,
  });

  final List<ItemSubModel> rows;
  final bool isLoading;
  final String? error;
  final String search;
  final int? groupNo;
  final int? typeNo;
  final String active;
  final String sort;
  final String dir;
  final int page;
  final int pages;
  final int total;

  int get filtersCount {
    var count = 0;
    if (groupNo != null) count++;
    if (typeNo != null) count++;
    if (active != 'all') count++;

    return count;
  }

  SubItemsListState copyWith({
    List<ItemSubModel>? rows,
    bool? isLoading,
    String? error,
    String? search,
    int? groupNo,
    int? typeNo,
    String? active,
    String? sort,
    String? dir,
    int? page,
    int? pages,
    int? total,
    bool clearError = false,
    bool clearGroup = false,
    bool clearType = false,
  }) {
    return SubItemsListState(
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      groupNo: clearGroup ? null : groupNo ?? this.groupNo,
      typeNo: clearType ? null : typeNo ?? this.typeNo,
      active: active ?? this.active,
      sort: sort ?? this.sort,
      dir: dir ?? this.dir,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
    );
  }
}

class SubItemsListNotifier extends Notifier<SubItemsListState> {
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  /// التصفية الافتراضية تُطبَّق مرة واحدة، كما في تبويب الأصناف الرئيسية
  /// The default filter applies once, exactly like the main items tab.
  bool _defaultsApplied = false;

  @override
  SubItemsListState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    return const SubItemsListState();
  }

  StoreItemsRepository get _repository =>
      ref.read(storeItemsRepositoryProvider);

  Future<void> load({bool keepPage = false}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final version = ++_searchVersion;

    final page = keepPage ? state.page : 1;
    state = state.copyWith(isLoading: true, clearError: true, page: page);

    try {
      final result = await _repository.fetchSubItems(
        search: state.search,
        page: page,
        groupNo: state.groupNo,
        typeNo: state.typeNo,
        active: state.active,
        sort: state.sort,
        dir: state.dir,
        cancelToken: _cancelToken,
      );

      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(
        rows: result.items,
        total: result.total,
        pages: result.pages,
        isLoading: false,
      );
    } catch (error) {
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim());

    return load();
  }

  /// تفريغ البحث والتصفية عند مغادرة القسم أو نهاية الجلسة.
  /// Clears the search and every filter when the section closes or the session ends.
  ///
  /// نفسها قواعد `ItemsListNotifier.resetTransient` — إعادة ضبط العداد الافتراضي
  /// ثم تصفير الحالة، والجلب عند التبديل لا عند نهاية الجلسة.
  /// Mirrors `ItemsListNotifier.resetTransient` exactly — the defaults flag goes
  /// back to false, the state resets, and a refetch fires on a tab switch only.
  void resetTransient({bool reload = false}) {
    _searchVersion++;
    _cancelToken?.cancel('screen-exited');
    _defaultsApplied = false;
    state = const SubItemsListState(isLoading: true);
    if (reload) Future.microtask(load);
  }

  Future<void> applyFilters({
    int? groupNo,
    int? typeNo,
    String? active,
    bool clearGroup = false,
    bool clearType = false,
  }) async {
    // تغيير المجموعة الرئيسية يُبطل الفرعية التابعة لها
    // Changing the main group invalidates its sub group.
    state = state.copyWith(
      groupNo: groupNo,
      typeNo: clearGroup ? null : typeNo,
      active: active,
      clearGroup: clearGroup,
      clearType: clearGroup ? true : clearType,
    );

    return load();
  }

  Future<void> sortBy(String field, String dir) async {
    state = state.copyWith(sort: field, dir: dir);

    return load();
  }

  /// تبديل الاتجاه دون تغيير الحقل
  /// Toggle direction without changing the field.
  Future<void> toggleSortDir() async {
    state = state.copyWith(dir: state.dir == 'asc' ? 'desc' : 'asc');

    return load();
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);

    return load(keepPage: true);
  }

  /// التصفية الافتراضية: النشط فقط · أول مجموعة · أول فرعية منها
  /// The default filter: active only, the first group and its first sub group.
  Future<void> applyDefaults(StoreReference reference) async {
    if (_defaultsApplied) return;

    _defaultsApplied = true;

    // نفس حارس تبويب الرئيسية: لا تصفية على مجموعة برقم غير صالح
    // The same guard as the main tab: never filter on an invalid group number.
    final usable = reference.groups
        .where((group) => group.groupNo > 0)
        .toList(growable: false);

    if (usable.isEmpty) {
      await load();

      return;
    }

    final group = usable.first;
    final types = reference
        .typesOfGroup(group.groupNo)
        .where((type) => type.typeNo > 0)
        .toList(growable: false);

    state = state.copyWith(
      active: '1',
      groupNo: group.groupNo,
      typeNo: types.isEmpty ? null : types.first.typeNo,
      clearError: true,
    );

    await load();
  }
}

final subItemsListProvider =
    NotifierProvider<SubItemsListNotifier, SubItemsListState>(
      SubItemsListNotifier.new,
    );
