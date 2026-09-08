import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/worker_statement_model.dart';
import '../../data/repositories/worker_repository.dart';

// ================================================================
// Provider المستودع
// ================================================================

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return WorkerRepository(client: client);
});

// ================================================================
// حالة قائمة العمال
// ================================================================

class WorkersListState {
  final List<WorkerModel> workers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int page;
  final bool hasMore;
  final WorkerType type;

  const WorkersListState({
    this.workers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.page = 1,
    this.hasMore = true,
    required this.type,
  });

  WorkersListState copyWith({
    List<WorkerModel>? workers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? page,
    bool? hasMore,
    WorkerType? type,
    bool clearError = false,
  }) {
    return WorkersListState(
      workers: workers ?? this.workers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      type: type ?? this.type,
    );
  }
}

// ================================================================
// Notifier إدارة قائمة العمال
// ================================================================

class WorkersListNotifier extends Notifier<WorkersListState> {
  final WorkerType workerType;

  WorkersListNotifier(this.workerType);

  @override
  WorkersListState build() {
    Future.microtask(() => loadWorkers());
    return WorkersListState(isLoading: true, type: workerType);
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadWorkers({bool refresh = false}) async {
    if (refresh) {
      state = WorkersListState(isLoading: true, type: workerType);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list = await _repo.fetchWorkers(
        workerType,
        search: state.searchQuery,
        page: 1,
      );
      state = state.copyWith(
        workers: list,
        isLoading: false,
        page: 1,
        hasMore: list.length >= 100,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل القائمة: ${e.toString()}',
      );
    }
  }

  Future<void> search(String query) async {
    final currentQuery = query.trim();
    state = state.copyWith(
      searchQuery: currentQuery,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _repo.fetchWorkers(
        workerType,
        search: currentQuery,
        page: 1,
      );
      if (state.searchQuery == currentQuery) {
        state = state.copyWith(
          workers: list,
          isLoading: false,
          page: 1,
          hasMore: list.length >= 100,
        );
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (state.searchQuery == currentQuery) {
        state = state.copyWith(
          isLoading: false,
          error: 'خطأ في البحث: ${e.toString()}',
        );
      }
    }
  }

  /// تحديث حالة عامل في القائمة بعد toggle
  void updateWorkerStatus(int workerId, String newStatus) {
    final updated =
        state.workers.map((w) {
          if (w.id == workerId) return w.copyWith(status: newStatus);
          return w;
        }).toList();
    state = state.copyWith(workers: updated);
  }

  /// حذف عامل من القائمة
  void removeWorker(int workerId) {
    final updated = state.workers.where((w) => w.id != workerId).toList();
    state = state.copyWith(workers: updated);
  }
}

final workersListProvider =
    NotifierProvider.family<WorkersListNotifier, WorkersListState, WorkerType>(
      WorkersListNotifier.new,
    );

// ================================================================
// كشف حساب العامل
// ================================================================

class WorkerStatementState {
  final bool isLoading;
  final String? error;
  final List<WorkerStatementModel> rows;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? worker;

  const WorkerStatementState({
    this.isLoading = false,
    this.error,
    this.rows = const [],
    this.summary,
    this.worker,
  });

  WorkerStatementState copyWith({
    bool? isLoading,
    String? error,
    List<WorkerStatementModel>? rows,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? worker,
    bool clearError = false,
  }) {
    return WorkerStatementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      rows: rows ?? this.rows,
      summary: summary ?? this.summary,
      worker: worker ?? this.worker,
    );
  }
}

class WorkerStatementNotifier extends Notifier<WorkerStatementState> {
  @override
  WorkerStatementState build() {
    return const WorkerStatementState(isLoading: false);
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadStatement(
    WorkerType type,
    int workerId, {
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.fetchStatement(
        type,
        workerId,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (result != null) {
        state = state.copyWith(
          isLoading: false,
          rows: result['rows'] as List<WorkerStatementModel>,
          summary: result['summary'] as Map<String, dynamic>?,
          worker:
              result['worker'] != null
                  ? Map<String, dynamic>.from(result['worker'] as dynamic)
                  : null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'لا توجد بيانات لهذا العامل',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل كشف الحساب: ${e.toString()}',
      );
    }
  }
}

final workerStatementProvider =
    NotifierProvider<WorkerStatementNotifier, WorkerStatementState>(
      WorkerStatementNotifier.new,
    );
