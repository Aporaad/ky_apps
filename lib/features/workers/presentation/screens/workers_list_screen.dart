import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/worker_model.dart';
import '../providers/workers_provider.dart';
import '../widgets/worker_action_icons.dart';
import 'add_edit_worker_screen.dart';
import 'worker_statement_screen.dart';
import 'worker_work_report_screen.dart';

/// شاشة قائمة العمال المشتركة (تعمل للموظفين والقصاصين والخياطين)
class WorkersListScreen extends ConsumerStatefulWidget {
  final WorkerType workerType;
  final String title;
  final String addLabel;
  final Color accentColor;
  final Color lightColor;
  final IconData icon;
  final String workReportLabel;

  const WorkersListScreen({
    super.key,
    required this.workerType,
    required this.title,
    required this.addLabel,
    required this.accentColor,
    required this.lightColor,
    required this.icon,
    this.workReportLabel = 'كشف عمل',
  });

  @override
  ConsumerState<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends ConsumerState<WorkersListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showDisabled = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(workersListProvider(widget.workerType).notifier).search(query);
      }
    });
  }

  void _goToStatement(WorkerModel worker) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerStatementScreen(
          workerId: worker.id,
          workerType: worker.type,
          workerName: worker.name,
          accNo: worker.accNo,
        ),
      ),
    );
  }

  void _goToEdit(WorkerModel worker) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddEditWorkerScreen(
              workerType: widget.workerType,
              existingWorker: worker,
            ),
          ),
        )
        .then((_) => ref.read(workersListProvider(widget.workerType).notifier).loadWorkers(refresh: true));
  }

  void _goToAdd() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => AddEditWorkerScreen(workerType: widget.workerType),
          ),
        )
        .then((_) => ref.read(workersListProvider(widget.workerType).notifier).loadWorkers(refresh: true));
  }

  Future<void> _confirmDelete(WorkerModel worker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${worker.name}" نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final repo = ref.read(workerRepositoryProvider);
    final result = await repo.deleteWorker(widget.workerType, worker.id);

    if (!mounted) return;

    if (result.success) {
      ref.read(workersListProvider(widget.workerType).notifier).removeWorker(worker.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleStatus(WorkerModel worker) async {
    final repo = ref.read(workerRepositoryProvider);
    final result = await repo.toggleWorker(widget.workerType, worker.id);

    if (!mounted) return;

    if (result.success) {
      ref.read(workersListProvider(widget.workerType).notifier)
          .updateWorkerStatus(worker.id, result.data?.toString() ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workersListProvider(widget.workerType));

    final displayedWorkers = _showDisabled
        ? state.workers
        : state.workers.where((w) => !w.isDisabled).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(widget.icon, color: widget.accentColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!state.isLoading && state.error == null)
                    Text(
                      '${displayedWorkers.length} عامل',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // فلتر: إظهار/إخفاء المعطلين
          IconButton(
            icon: Icon(
              _showDisabled ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: _showDisabled ? AppColors.warning : AppColors.textMuted,
            ),
            tooltip: _showDisabled ? 'إخفاء المعطلين' : 'إظهار المعطلين',
            onPressed: () => setState(() => _showDisabled = !_showDisabled),
          ),
          // تحديث
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
            tooltip: 'تحديث',
            onPressed: () =>
                ref.read(workersListProvider(widget.workerType).notifier).loadWorkers(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // زر إضافة + بحث
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // زر إضافة
                ElevatedButton.icon(
                  onPressed: _goToAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(widget.addLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // حقل بحث
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'بحث بالاسم أو الرقم...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(workersListProvider(widget.workerType).notifier)
                                    .search('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _onSearchChanged(v);
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // قائمة العمال
          Expanded(
            child: _buildBody(state, displayedWorkers),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(WorkersListState state, List<WorkerModel> workers) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('جاري التحميل...', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(workersListProvider(widget.workerType).notifier).loadWorkers(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط على زر الإضافة لإضافة عامل جديد',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(workersListProvider(widget.workerType).notifier).loadWorkers(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: workers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _WorkerListTile(
          worker: workers[index],
          accentColor: widget.accentColor,
          lightColor: widget.lightColor,
          workReportLabel: widget.workReportLabel,
          onStatement: () => _goToStatement(workers[index]),
          onWorkReport: () => _goToWorkReport(workers[index]),
          onEdit: () => _goToEdit(workers[index]),
          onToggle: () => _toggleStatus(workers[index]),
          onDelete: () => _confirmDelete(workers[index]),
        ),
      ),
    );
  }

  void _goToWorkReport(WorkerModel worker) {
    // كشف العمل متاح للقصاص والخياط فقط؛ الموظفون ("كشف حضور") ما زالوا خارج النطاق.
    // Work report covers cutters/tailors only; employees ("attendance") remain out of scope.
    if (worker.type == WorkerType.employee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.workReportLabel} لـ ${worker.name} - قيد التطوير'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkerWorkReportScreen(
          workerId: worker.id,
          workerType: worker.type,
          workerName: worker.name,
          accNo: worker.accNo,
        ),
      ),
    );
  }
}

// ================================================================
// بطاقة الموظف في القائمة
// ================================================================

class _WorkerListTile extends StatelessWidget {
  final WorkerModel worker;
  final Color accentColor;
  final Color lightColor;
  final String workReportLabel;
  final VoidCallback? onStatement;
  final VoidCallback? onWorkReport;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const _WorkerListTile({
    required this.worker,
    required this.accentColor,
    required this.lightColor,
    required this.workReportLabel,
    this.onStatement,
    this.onWorkReport,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = worker.isDisabled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDisabled
            ? const Color(0xFFF8FAFC)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDisabled ? AppColors.border : accentColor.withValues(alpha: 0.15),
          width: isDisabled ? 1 : 1.5,
        ),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصف الأول: الاسم + حالة
          Row(
            children: [
              // أيقونة رمز الهوية
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? AppColors.textMuted.withValues(alpha: 0.15)
                      : accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    worker.name.isNotEmpty ? worker.name[0] : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDisabled ? AppColors.textMuted : accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDisabled
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: isDisabled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        // شارة الحالة
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isDisabled ? 'معطل' : 'فعال',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDisabled
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'رقم: ${worker.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker.accNo != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'حساب: ${worker.accNo}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (worker.phone1 != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.phone_outlined,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              worker.phone1!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // الصف الثاني: أيقونات الإجراءات
          WorkerActionIcons(
            worker: worker,
            workReportLabel: workReportLabel,
            onStatement: onStatement,
            onWorkReport: onWorkReport,
            onEdit: onEdit,
            onToggle: onToggle,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
