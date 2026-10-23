import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/permission_codes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/permission_gate.dart';
import '../../../data/models/oracle_job_model.dart';
import '../../../providers/jobs_provider.dart';
import 'job_form_screen.dart';
import 'job_history_screen.dart';

/// قائمة المهام الزمنية (DBMS_SCHEDULER) — تفعيل/تعطيل/تعديل/حذف + سجل التشغيل
/// Scheduler-jobs list — enable/disable/update/delete plus run history.
///
/// افتراضيًا تعرض مهام الرسائل الثلاث فقط؛ ومفتاح «كل المهام» يوسّع النطاق إلى USER_SCHEDULER_JOBS.
/// By default only the three messaging jobs; the "all jobs" switch widens to USER_SCHEDULER_JOBS.
class JobsListScreen extends ConsumerWidget {
  const JobsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobsProvider);
    final notifier = ref.read(jobsProvider.notifier);

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
        title: const Text('المهام الزمنية'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      floatingActionButton: PermissionGate(
        code: Perm.jobsCreate,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JobFormScreen()),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: Column(
        children: [
          PermissionGate(
            code: Perm.jobsView,
            child: SwitchListTile(
              title: const Text('عرض كل مهام المستخدم'),
              subtitle: const Text('إيقافها يحصر القائمة في مهام الرسائل'),
              value: state.showAll,
              onChanged: notifier.toggleShowAll,
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(
                        child: ElevatedButton(
                          onPressed: notifier.load,
                          child: Text('${state.error} — إعادة المحاولة'),
                        ),
                      )
                    : state.jobs.isEmpty
                        ? const Center(
                            child: Text('لا توجد مهام',
                                style: TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: state.jobs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _JobCard(job: state.jobs[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});

  final OracleJobModel job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(jobsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.jobName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (job.enabled ? AppColors.success : AppColors.textMuted)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  job.enabled ? 'مُفعّلة' : 'مُعطّلة',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: job.enabled ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (job.repeatInterval != null) ...[
            const SizedBox(height: 6),
            _row(Icons.schedule_rounded, job.repeatInterval!),
          ],
          if (job.jobAction != null) _row(Icons.terminal_rounded, job.jobAction!),
          if (job.state != null) _row(Icons.flag_rounded, job.state!),
          const SizedBox(height: 10),
          Row(
            children: [
              _action(context, Icons.history_rounded, 'السجل', AppColors.info,
                  () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => JobHistoryScreen(jobName: job.jobName)),
                      )),
              const SizedBox(width: 8),
              PermissionGate(
                code: Perm.jobsUpdate,
                child: _action(context, Icons.edit_rounded, 'تعديل', AppColors.accent,
                    () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => JobFormScreen(job: job)),
                        )),
              ),
              const Spacer(),
              PermissionGate(
                code: Perm.jobsToggle,
                child: IconButton(
                  tooltip: job.enabled ? 'تعطيل' : 'تفعيل',
                  iconSize: 20,
                  icon: Icon(
                    job.enabled ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: job.enabled ? AppColors.success : AppColors.textMuted,
                  ),
                  onPressed: () async {
                    final res = await notifier.toggle(job.jobName, !job.enabled);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(res.message)));
                    }
                  },
                ),
              ),
              PermissionGate(
                code: Perm.jobsDelete,
                child: IconButton(
                  tooltip: 'حذف',
                  iconSize: 20,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref, notifier),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );

  Widget _action(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, JobsNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: Text('حذف المهمة «${job.jobName}»؟ تُرفض إن كانت قيد التشغيل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await notifier.remove(job.jobName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      }
    }
  }
}
