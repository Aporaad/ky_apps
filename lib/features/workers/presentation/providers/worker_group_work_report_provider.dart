import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/worker_group_work_report_model.dart';
import '../../data/repositories/worker_repository.dart';
import 'workers_provider.dart';

// ================================================================
// كشف عمل المجموعة (القصاصين / الخياطين)
// Group work report state — all cutters or all tailors
// ================================================================

class WorkerGroupWorkReportState {
  final bool isLoading;
  final String? error;
  final WorkerGroupWorkReport? report;

  const WorkerGroupWorkReportState({
    this.isLoading = false,
    this.error,
    this.report,
  });

  WorkerGroupWorkReportState copyWith({
    bool? isLoading,
    String? Function()? error,
    WorkerGroupWorkReport? report,
  }) {
    return WorkerGroupWorkReportState(
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      report: report ?? this.report,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => report != null && report!.rows.isEmpty;
}

/// Notifier لكشف عمل المجموعة — نمط Notifier + CancelToken مطابق لـ WorkerWorkReportNotifier
/// Group work report notifier — mirrors WorkerWorkReportNotifier pattern with CancelToken.
class WorkerGroupWorkReportNotifier extends Notifier<WorkerGroupWorkReportState> {
  CancelToken? _cancelToken;

  @override
  WorkerGroupWorkReportState build() {
    // إلغاء أي طلب معلّق عند تفكيك الشاشة
    ref.onDispose(() => _cancelToken?.cancel('screen disposed'));
    return const WorkerGroupWorkReportState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  /// تحميل كشف عمل المجموعة بفترة محددة. التواريخ بصيغة dd/mm/yyyy.
  /// Load the group work report for a date window. Dates use dd/mm/yyyy.
  Future<void> loadReport(
    WorkerType type, {
    String? fromDate,
    String? toDate,
  }) async {
    // إلغاء الطلب السابق قبل إطلاق الجديد
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final result = await _repo.fetchGroupWorkReport(
        type,
        fromDate: fromDate,
        toDate: toDate,
        cancelToken: token,
      );
      if (result == null) return;
      state = state.copyWith(
        isLoading: false,
        report: result,
        error: () => null,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        error: () => 'فشل تحميل كشف عمل المجموعة: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'فشل تحميل كشف عمل المجموعة: ${e.toString()}',
      );
    }
  }
}

final workerGroupWorkReportProvider =
    NotifierProvider<WorkerGroupWorkReportNotifier, WorkerGroupWorkReportState>(
      WorkerGroupWorkReportNotifier.new,
    );
