import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/worker_work_report_model.dart';
import '../../data/repositories/worker_repository.dart';
import 'workers_provider.dart';

// ================================================================
// كشف عمل العامل (القصاص / الخياط)
// Worker work report state — cutters & tailors only
// ================================================================

class WorkerWorkReportState {
  final bool isLoading;
  final String? error;
  final WorkerWorkReport? report;

  const WorkerWorkReportState({
    this.isLoading = false,
    this.error,
    this.report,
  });

  WorkerWorkReportState copyWith({
    bool? isLoading,
    String? Function()? error,
    WorkerWorkReport? report,
  }) {
    return WorkerWorkReportState(
      isLoading: isLoading ?? this.isLoading,
      // الإغلاق (closure) يسمح بتمرير null لمسح الخطأ — حيلة copyWith للحقول القابلة للعدم
      error: error != null ? error() : this.error,
      report: report ?? this.report,
    );
  }

  bool get hasError => error != null;
  bool get isEmpty => report != null && report!.rows.isEmpty;
}

/// Notifier غير عائلي بنمط WorkerStatementNotifier الحالي، يضيف CancelToken لإلغاء
/// الطلبات عند إغلاق الشاشة (يمنع أخطاء "بعد dispose" ونتائج البحث القديمة).
/// A plain Notifier mirroring WorkerStatementNotifier, with a CancelToken that aborts
/// in-flight requests on dispose — the project's established fix for stale results.
class WorkerWorkReportNotifier extends Notifier<WorkerWorkReportState> {
  CancelToken? _cancelToken;

  @override
  WorkerWorkReportState build() {
    // إلغاء أي طلب معلّق عند تفكيك الشاشة / تبديل العامل
    ref.onDispose(() => _cancelToken?.cancel('screen disposed'));
    return const WorkerWorkReportState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  /// تحميل كشف العمل بفترة محددة. التواريخ بصيغة dd/mm/yyyy. فارغة ⇒ افتراضي الخادم (آخر يوم سجل عمل).
  /// Load the work report for a date window. Dates use dd/mm/yyyy; empty ⇒ server default (last work-record day).
  Future<void> loadReport(
    WorkerType type,
    int workerId, {
    String? fromDate,
    String? toDate,
  }) async {
    // إلغاء الطلب السابق قبل إطلاق الجديد (حارس ضد سباق البحث/الفلاتر)
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    final token = _cancelToken!;

    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final result = await _repo.fetchWorkReport(
        type,
        workerId,
        fromDate: fromDate,
        toDate: toDate,
        cancelToken: token,
      );
      if (result == null) return; // ملغى أو success=false صامت
      state = state.copyWith(
        isLoading: false,
        report: result,
        error: () => null,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        error: () => 'فشل تحميل كشف العمل: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'فشل تحميل كشف العمل: ${e.toString()}',
      );
    }
  }
}

final workerWorkReportProvider =
    NotifierProvider<WorkerWorkReportNotifier, WorkerWorkReportState>(
      WorkerWorkReportNotifier.new,
    );
