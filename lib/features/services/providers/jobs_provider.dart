import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/job_run_model.dart';
import '../data/models/oracle_job_model.dart';
import '../data/repositories/service_result.dart';
import 'services_providers.dart';

/// حالة قائمة المهام — تحميل/نجاح/فارغ/خطأ + وضع «كل المهام»
/// Jobs-list state — loading/empty/error + a "show all jobs" toggle.
class JobsState {
  final List<OracleJobModel> jobs;
  final bool isLoading;
  final String? error;

  /// افتراضيًا نعرض مهام الرسائل فقط؛ والمفعّل يعرض كل مهام المستخدم
  /// By default only the messaging jobs; enabled lists every USER_SCHEDULER_JOBS row.
  final bool showAll;

  const JobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.error,
    this.showAll = false,
  });

  JobsState copyWith({
    List<OracleJobModel>? jobs,
    bool? isLoading,
    String? error,
    bool? showAll,
    bool clearError = false,
  }) {
    return JobsState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      showAll: showAll ?? this.showAll,
    );
  }
}

class JobsNotifier extends Notifier<JobsState> {
  @override
  JobsState build() {
    Future.microtask(() => load());
    return const JobsState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await ref
          .read(jobRepositoryProvider)
          .fetchJobs(all: state.showAll);
      state = state.copyWith(jobs: list, isLoading: false);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل المهام / Failed to load jobs',
      );
    }
  }

  void toggleShowAll(bool value) {
    state = state.copyWith(showAll: value);
    load();
  }

  Future<ServiceResult> create(Map<String, dynamic> payload) async {
    final result = await ref.read(jobRepositoryProvider).create(payload);
    if (result.success) await load();
    return result;
  }

  Future<ServiceResult> update(String name, Map<String, dynamic> payload) async {
    final result = await ref.read(jobRepositoryProvider).update(name, payload);
    if (result.success) await load();
    return result;
  }

  Future<ServiceResult> toggle(String name, bool enabled) async {
    final result = await ref.read(jobRepositoryProvider).toggle(name, enabled);
    if (result.success) await load();
    return result;
  }

  Future<ServiceResult> remove(String name) async {
    final result = await ref.read(jobRepositoryProvider).delete(name);
    if (result.success) await load();
    return result;
  }
}

final jobsProvider = NotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

/// سجل تشغيل مهمة — autoDispose بعائلة اسم المهمة (لا يُبقى حيًا بلا شاشة تراقبه)
/// Job run history — autoDispose keyed by job name, so nothing stays alive unwatched.
final jobHistoryProvider = FutureProvider.autoDispose
    .family<List<JobRunModel>, String>((ref, jobName) async {
  return ref.read(jobRepositoryProvider).fetchHistory(jobName);
});
