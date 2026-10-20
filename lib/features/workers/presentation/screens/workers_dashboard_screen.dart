import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/employees_list_screen.dart';
import '../screens/cutters_list_screen.dart';
import '../screens/tailors_list_screen.dart';

/// لوحة تحكم "جاري العاملين" - تعرض 3 بطاقات رئيسية
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
                    Icon(
                      Icons.groups_2_rounded,
                      color: Color(0xFF6B21A8),
                      size: 22,
                    ),
                    SizedBox(width: 10),
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
                            style: TextStyle(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة القسم
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B21A8), Color(0xFF9333EA)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B21A8).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              //'جاري العاملين'
              child: const Row(
                children: [
                  Icon(Icons.groups_2_rounded, color: Colors.white, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جاري العاملين',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'إدارة شاملة للموظفين والقصاصين والخياطين',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // عنوان البطاقات
            Text(
              'اختر الفئة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // بطاقة الموظفين
            _WorkerCategoryCard(
              icon: Icons.badge_rounded,
              title: 'الموظفين',
              subtitle: 'إدارة بيانات الموظفين وكشف الحضور والحساب',
              color: const Color(0xFF1E3A8A),
              lightColor: const Color(0xFF3B82F6),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmployeesListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 14),

            // بطاقة القصاصين
            _WorkerCategoryCard(
              icon: Icons.content_cut_rounded,
              title: 'القصاصين',
              subtitle: 'إدارة بيانات القصاصين وكشف العمل والحساب',
              color: const Color(0xFF065F46),
              lightColor: const Color(0xFF10B981),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CuttersListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 14),

            // بطاقة الخياطين
            _WorkerCategoryCard(
              icon: Icons.checkroom_rounded,
              title: 'الخياطين',
              subtitle: 'إدارة بيانات الخياطين وكشف العمل والحساب',
              color: const Color(0xFF7C2D12),
              lightColor: const Color(0xFFF97316),
              onTap:
                  () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TailorsListScreen(),
                    ),
                  ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// بطاقة فئة العاملين
class _WorkerCategoryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color lightColor;
  final VoidCallback onTap;

  const _WorkerCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.lightColor,
    required this.onTap,
  });

  @override
  State<_WorkerCategoryCard> createState() => _WorkerCategoryCardState();
}

class _WorkerCategoryCardState extends State<_WorkerCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // أيقونة الفئة
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.lightColor],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              // النص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // سهم التنقل
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: widget.color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
