import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/job_run_model.dart';
import '../../../providers/jobs_provider.dart';

/// سجل تشغيل مهمة (USER_SCHEDULER_JOB_RUN_DETAILS) — قراءة فقط
/// A job's run history (USER_SCHEDULER_JOB_RUN_DETAILS) — read-only.
///
/// يراقب `jobHistoryProvider(name)` وهو autoDispose، فلا يبقى الطلب حيًا بعد إغلاق الشاشة.
/// It watches jobHistoryProvider(name), which is autoDispose — the fetch does not outlive the screen.
class JobHistoryScreen extends ConsumerWidget {
  const JobHistoryScreen({required this.jobName, super.key});

  final String jobName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(jobHistoryProvider(jobName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('سجل: $jobName'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(jobHistoryProvider(jobName)),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('فشل تحميل السجل', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(jobHistoryProvider(jobName)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (runs) => runs.isEmpty
            ? const Center(
                child: Text('لا توجد عمليات تشغيل مسجّلة',
                    style: TextStyle(color: AppColors.textMuted)),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(jobHistoryProvider(jobName)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: runs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RunCard(run: runs[i]),
                ),
              ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({required this.run});

  final JobRunModel run;

  @override
  Widget build(BuildContext context) {
    final color = run.succeeded ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                run.succeeded ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                run.succeeded ? 'نجح' : ' فشل',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
              const Spacer(),
              if (run.runDuration != null)
                Text('⏱ ${run.runDuration}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          if (run.logDate != null) ...[
            const SizedBox(height: 4),
            Text(run.logDate!,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
          if (run.status != null) _line('الحالة', run.status!),
          if (run.error != null) _line('الخطأ', run.error!, isError: true),
          if (run.additionalInfo != null) _line('معلومات', run.additionalInfo!),
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool isError = false}) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 11.5,
            color: isError ? AppColors.error : AppColors.textSecondary,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
