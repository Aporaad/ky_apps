import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/worker_model.dart';

/// أيقونات إجراءات العامل: كشف حساب - كشف عمل/حضور - تعديل - تعطيل - حذف
/// كل أيقونة خلف صلاحيتها الدقيقة، وتُلغى تماماً بلا منح (لا تعطيل) حتى لا يلمّح الواجهة
/// بشيء محجوب. الوحدة مشتقّة من نوع العامل: employees / cutters / tailors.
/// Every icon sits behind its own precise grant and is removed entirely when absent (never
/// disabled). The module comes from the worker type: employees / cutters / tailors.
class WorkerActionIcons extends ConsumerWidget {
  final WorkerModel worker;
  final VoidCallback? onStatement;
  final VoidCallback? onWorkReport;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  /// تسمية الزر الثاني: "كشف حضور" للموظفين، "كشف عمل" للباقين
  final String workReportLabel;

  const WorkerActionIcons({
    super.key,
    required this.worker,
    this.onStatement,
    this.onWorkReport,
    this.onEdit,
    this.onToggle,
    this.onDelete,
    this.workReportLabel = 'كشف عمل',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDisabled = worker.isDisabled;
    // البادئة حسب نوع العامل، مطابقة لتسمية أفعال الصلاحيات في الكتالوج
    // The prefix follows the worker type, matching the catalog's action naming.
    final module = worker.type.apiPath;
    final auth = ref.watch(authNotifierProvider);

    // كل صف = (الكود المطلوب، الرمز). الأزرار التي بلا كود تُعرض دائماً؛ والمسنودة تُحجب
    // إذا لم تُمنح. الترتيب محفوظ كما كان.
    // Each row is (required code, button). Coded buttons hide without the grant; order preserved.
    final actions = <(String?, Widget)>[
      (
        '$module.statement_financial',
        _ActionBtn(
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف حساب',
          color: AppColors.primary,
          onTap: onStatement,
        ),
      ),
      (
        '$module.statement_work',
        _ActionBtn(
          icon: worker.type == WorkerType.employee
              ? Icons.calendar_month_rounded
              : Icons.assignment_rounded,
          tooltip: workReportLabel,
          color: const Color(0xFF0D9488),
          onTap: onWorkReport,
        ),
      ),
      (
        '$module.update',
        _ActionBtn(
          icon: Icons.edit_rounded,
          tooltip: 'تعديل',
          color: const Color(0xFFF59E0B),
          onTap: onEdit,
        ),
      ),
      (
        '$module.toggle',
        _ActionBtn(
          icon: isDisabled
              ? Icons.play_circle_rounded
              : Icons.pause_circle_rounded,
          tooltip: isDisabled ? 'تفعيل' : 'تعطيل',
          color: isDisabled ? AppColors.success : const Color(0xFF6B7280),
          onTap: onToggle,
        ),
      ),
      (
        '$module.delete',
        _ActionBtn(
          icon: Icons.delete_rounded,
          tooltip: 'حذف',
          color: AppColors.error,
          onTap: onDelete,
        ),
      ),
    ];

    // فلترة المسموح بها فقط ثم إعادة الفواصل بينها حتى لا تظهر مسافة زائدة
    // Keep only allowed actions, then re-insert gaps so no trailing spacer shows.
    final allowed = actions
        .where((entry) => entry.$1 == null || auth.can(entry.$1!))
        .map((entry) => entry.$2)
        .toList();

    if (allowed.isEmpty) return const SizedBox.shrink();

    final spaced = <Widget>[];
    for (var i = 0; i < allowed.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 4));
      spaced.add(allowed[i]);
    }

    return Row(mainAxisSize: MainAxisSize.min, children: spaced);
  }
}

/// زر أيقونة صغير مع Tooltip
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
