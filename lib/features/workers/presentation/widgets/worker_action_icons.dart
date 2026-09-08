import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/worker_model.dart';

/// أيقونات إجراءات العامل: كشف حساب - كشف عمل/حضور - تعديل - تعطيل - حذف
class WorkerActionIcons extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDisabled = worker.isDisabled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // كشف الحساب
        _ActionBtn(
          icon: Icons.receipt_long_rounded,
          tooltip: 'كشف حساب',
          color: AppColors.primary,
          onTap: onStatement,
        ),
        const SizedBox(width: 4),

        // كشف عمل / كشف حضور
        _ActionBtn(
          icon: worker.type == WorkerType.employee
              ? Icons.calendar_month_rounded
              : Icons.assignment_rounded,
          tooltip: workReportLabel,
          color: const Color(0xFF0D9488),
          onTap: onWorkReport,
        ),
        const SizedBox(width: 4),

        // تعديل
        _ActionBtn(
          icon: Icons.edit_rounded,
          tooltip: 'تعديل',
          color: const Color(0xFFF59E0B),
          onTap: onEdit,
        ),
        const SizedBox(width: 4),

        // تعطيل / تفعيل
        _ActionBtn(
          icon: isDisabled
              ? Icons.play_circle_rounded
              : Icons.pause_circle_rounded,
          tooltip: isDisabled ? 'تفعيل' : 'تعطيل',
          color: isDisabled ? AppColors.success : const Color(0xFF6B7280),
          onTap: onToggle,
        ),
        const SizedBox(width: 4),

        // حذف
        _ActionBtn(
          icon: Icons.delete_rounded,
          tooltip: 'حذف',
          color: AppColors.error,
          onTap: onDelete,
        ),
      ],
    );
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
