import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/employees_list_screen.dart';
import '../screens/cutters_list_screen.dart';
import '../screens/tailors_list_screen.dart';
import '../screens/worker_group_work_report_screen.dart';

/// لوحة تحكم "جاري العاملين" - بطاقات فئات مرتبة بألوان وأحجام التطبيق الرسمية
class WorkersDashboardScreen extends StatelessWidget {
  const WorkersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          canPop
              ? AppBar(
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
                    Icon(Icons.groups_2_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'جاري العاملين',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'إدارة الموظفين والقصاصين والخياطين',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة القسم — بطاقة مسطحة بألوان السمة الرسمية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups_2_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جاري العاملين',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'إدارة شاملة للموظفين والقصاصين والخياطين',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // عنوان البطاقات
            Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'اختر الفئة',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // بطاقة الموظفين
            _WorkerCategoryCard(
              icon: Icons.badge_rounded,
              title: 'الموظفين',
              subtitle: 'إدارة بيانات الموظفين وكشف الحضور والحساب',
              badge: 'موظفون',
              accent: AppColors.info,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployeesListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 12),

            // بطاقة القصاصين
            _WorkerCategoryCard(
              icon: Icons.content_cut_rounded,
              title: 'القصاصين',
              subtitle: 'إدارة بيانات القصاصين وكشف العمل والحساب',
              badge: 'قصاصون',
              accent: AppColors.success,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CuttersListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 12),

            // بطاقة الخياطين
            _WorkerCategoryCard(
              icon: Icons.checkroom_rounded,
              title: 'الخياطين',
              subtitle: 'إدارة بيانات الخياطين وكشف العمل والحساب',
              badge: 'خياطون',
              accent: AppColors.warning,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TailorsListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 12),

            // بطاقة كشف عمل مجموعة
            _WorkerCategoryCard(
              icon: Icons.summarize_rounded,
              title: 'كشف عمل مجموعة',
              subtitle: 'عرض أعمال جميع القصاصين أو الخياطين لفترة محددة',
              badge: 'تقارير',
              accent: AppColors.primary,
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkerGroupWorkReportScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

/// بطاقة فئة العاملين — تصميم مسطح موحد يعتمد لوناً دلالياً من لوحة التطبيق الرسمية
class _WorkerCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final VoidCallback onTap;

  const _WorkerCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: accent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
