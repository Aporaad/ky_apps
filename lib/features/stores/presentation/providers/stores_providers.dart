import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/store_model.dart';
import '../../data/models/store_reference.dart';
import '../../data/repositories/store_result.dart';
import '../../data/repositories/stores_repository.dart';

/// مستودع المخازن — حقنة واحدة يستهلكها كل مزود في القسم
/// The stores repository — a single injection consumed by every provider here.
final storesRepositoryProvider = Provider<StoresRepository>((ref) {
  return StoresRepository(client: ref.watch(dioClientProvider));
});

// ================================================================
// المراجع المشتركة (مخازن · مجموعات · أنواع · فئات · وحدات · أنواع حركة)
// The shared reference bundle
// ================================================================

/// حزمة المراجع — تُبنى مرة لكل جلسة لأنها لا تتغير إلا بإدارة المرجعيات، وتُبطل يدوياً
/// The reference bundle — built once per session because it only changes when the catalogs
/// are edited, and is invalidated explicitly by those edits.
final storeReferenceProvider = FutureProvider<StoreReference>((ref) async {
  final repository = ref.watch(storesRepositoryProvider);
  final reference = await repository.fetchReference();

  return reference ?? const StoreReference();
});

// ================================================================
// قائمة المخازن
// The store list
// ================================================================

class StoresListState {
  const StoresListState({
    this.stores = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.busy = false,
  });

  final List<StoreModel> stores;
  final bool isLoading;
  final String? error;
  final String search;

  /// عملية كتابة جارية (حفظ/حذف) — تُعطّل الأزرار وحدها دون إخفاء القائمة
  /// A write in flight; disables the buttons without hiding the list.
  final bool busy;

  int get archivedCount => stores.where((store) => store.archived).length;

  /// الأصناف ذات الرصيد السالب في المخازن الفعّالة — مؤشر إنذار لا يُخفى
  /// Items sitting below zero across the active stores — a warning KPI, never hidden.
  int get negativeCount => stores
      .where((store) => !store.archived)
      .fold(0, (sum, store) => sum + store.negative);

  double get totalValue =>
      stores.where((store) => !store.archived).fold(0, (sum, store) => sum + store.value);

  StoresListState copyWith({
    List<StoreModel>? stores,
    bool? isLoading,
    bool? busy,
    String? search,
    String? error,
    bool clearError = false,
  }) {
    return StoresListState(
      stores: stores ?? this.stores,
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      search: search ?? this.search,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class StoresListNotifier extends Notifier<StoresListState> {
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  @override
  StoresListState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    Future.microtask(() => load());

    return const StoresListState(isLoading: true);
  }

  StoresRepository get _repository => ref.read(storesRepositoryProvider);

  Future<void> load() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final version = ++_searchVersion;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final stores = await _repository.fetchStores(
        search: state.search,
        cancelToken: _cancelToken,
      );

      // حارس `ref.mounted`: المزود قد يُغلق أثناء الطلب (خروج من الشاشة أو دورة اختبار)،
      // وكتابة الحالة بعده ترمي UnmountedRefException.
      // The ref.mounted guard: the provider may be disposed while the request is in flight
      // (leaving the screen, or a test teardown), and writing to state then throws.
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(stores: stores, isLoading: false);
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim());

    return load();
  }

  Future<StoreResult> save({
    int? storeNo,
    required Map<String, dynamic> payload,
  }) async {
    state = state.copyWith(busy: true);

    final result = storeNo == null
        ? await _repository.createStore(payload)
        : await _repository.updateStore(storeNo, payload);

    state = state.copyWith(busy: false);

    if (result.success) {
      await load();
      ref.invalidate(storeReferenceProvider);
    }

    return result;
  }

  Future<StoreResult> remove(int storeNo) async {
    state = state.copyWith(busy: true);

    final result = await _repository.deleteStore(storeNo);

    state = state.copyWith(busy: false);

    if (result.success) {
      await load();
      ref.invalidate(storeReferenceProvider);
    }

    return result;
  }
}

final storesListProvider = NotifierProvider<StoresListNotifier, StoresListState>(
  StoresListNotifier.new,
);

// ================================================================
// أمناء المخازن
// Store keepers
// ================================================================

class KeepersState {
  const KeepersState({
    this.keepers = const [],
    this.isLoading = false,
    this.error,
    this.busy = false,
  });

  final List<StoreKeeperModel> keepers;
  final bool isLoading;
  final String? error;
  final bool busy;

  KeepersState copyWith({
    List<StoreKeeperModel>? keepers,
    bool? isLoading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return KeepersState(
      keepers: keepers ?? this.keepers,
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class KeepersNotifier extends Notifier<KeepersState> {
  CancelToken? _cancelToken;

  @override
  KeepersState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    Future.microtask(() => load());

    return const KeepersState(isLoading: true);
  }

  StoresRepository get _repository => ref.read(storesRepositoryProvider);

  Future<void> load() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final keepers = await _repository.fetchKeepers(cancelToken: _cancelToken);

      if (!ref.mounted) return;

      state = state.copyWith(keepers: keepers, isLoading: false);
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      if (!ref.mounted) return;

      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<StoreResult> save({
    int? empNo,
    required Map<String, dynamic> payload,
  }) async {
    state = state.copyWith(busy: true);

    final result = empNo == null
        ? await _repository.createKeeper(payload)
        : await _repository.updateKeeper(empNo, payload);

    state = state.copyWith(busy: false);

    if (result.success) await load();

    return result;
  }

  Future<StoreResult> remove(int empNo) async {
    state = state.copyWith(busy: true);

    final result = await _repository.deleteKeeper(empNo);

    state = state.copyWith(busy: false);

    if (result.success) await load();

    return result;
  }
}

final keepersProvider = NotifierProvider<KeepersNotifier, KeepersState>(
  KeepersNotifier.new,
);

// ================================================================
// المرجعيات: مجموعات · أنواع · فئات · وحدات
// Catalogs: groups · types · categories · units
// ================================================================

class CatalogsState {
  const CatalogsState({
    this.groups = const [],
    this.types = const [],
    this.categories = const [],
    this.units = const [],
    this.isLoading = false,
    this.error,
    this.busy = false,
  });

  final List<StoreGroupModel> groups;
  final List<StoreTypeModel> types;
  final List<StoreCategoryModel> categories;
  final List<StoreUnitModel> units;
  final bool isLoading;
  final String? error;
  final bool busy;

  CatalogsState copyWith({
    List<StoreGroupModel>? groups,
    List<StoreTypeModel>? types,
    List<StoreCategoryModel>? categories,
    List<StoreUnitModel>? units,
    bool? isLoading,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return CatalogsState(
      groups: groups ?? this.groups,
      types: types ?? this.types,
      categories: categories ?? this.categories,
      units: units ?? this.units,
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CatalogsNotifier extends Notifier<CatalogsState> {
  @override
  CatalogsState build() {
    Future.microtask(() => load());

    return const CatalogsState(isLoading: true);
  }

  StoresRepository get _repository => ref.read(storesRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // الأربعة في موازاة: قسم المرجعيات شاشة واحدة تعرضها كلها
      // All four in parallel: the catalogs screen shows them together.
      final results = await Future.wait([
        _repository.fetchCatalog('groups', StoreGroupModel.fromJson),
        _repository.fetchCatalog('types', StoreTypeModel.fromJson),
        _repository.fetchCatalog('categories', StoreCategoryModel.fromJson),
        _repository.fetchCatalog('units', StoreUnitModel.fromJson),
      ]);

      if (!ref.mounted) return;

      state = state.copyWith(
        groups: results[0] as List<StoreGroupModel>,
        types: results[1] as List<StoreTypeModel>,
        categories: results[2] as List<StoreCategoryModel>,
        units: results[3] as List<StoreUnitModel>,
        isLoading: false,
      );
    } catch (error) {
      if (!ref.mounted) return;

      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<StoreResult> create(String kind, Map<String, dynamic> payload) async {
    state = state.copyWith(busy: true);

    final result = await _repository.createCatalog(kind, payload);

    state = state.copyWith(busy: false);

    if (result.success) {
      await load();
      ref.invalidate(storeReferenceProvider);
    }

    return result;
  }

  Future<StoreResult> update(
    String kind,
    int id,
    Map<String, dynamic> payload,
  ) async {
    state = state.copyWith(busy: true);

    final result = await _repository.updateCatalog(kind, id, payload);

    state = state.copyWith(busy: false);

    if (result.success) {
      await load();
      ref.invalidate(storeReferenceProvider);
    }

    return result;
  }

  Future<StoreResult> remove(String kind, int id) async {
    state = state.copyWith(busy: true);

    final result = await _repository.deleteCatalog(kind, id);

    state = state.copyWith(busy: false);

    if (result.success) {
      await load();
      ref.invalidate(storeReferenceProvider);
    }

    return result;
  }
}

final catalogsProvider = NotifierProvider<CatalogsNotifier, CatalogsState>(
  CatalogsNotifier.new,
);
