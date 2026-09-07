import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../widgets/collapsible_side_drawer.dart';
import 'sections/home_dashboard_section.dart';
import 'sections/sales_section.dart';
import 'sections/tailoring_section.dart';
import 'sections/accounts_section.dart';
import 'sections/customers_section.dart';
import 'sections/stores_section.dart';
import 'sections/management_section.dart';
import 'sections/settings_section.dart';

/// الهيكل الرئيسي لبوابة الموظف مع القائمة الجانبية والشريط العلوي
/// Main Employee Portal Layout with Collapsible Drawer and Top Bar
class EmployeeMainLayout extends ConsumerStatefulWidget {
  const EmployeeMainLayout({super.key});

  @override
  ConsumerState<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends ConsumerState<EmployeeMainLayout> {
  int _currentIndex = 0;
  bool _isCollapsed = false;

  final List<Widget> _sections = const [
    HomeDashboardSection(),
    SalesSection(),
    TailoringSection(),
    AccountsSection(),
    CustomersSection(),
    StoresSection(),
    ManagementSection(),
    SettingsSection(),
  ];

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('تسجيل خروج'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'الموظف';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          CollapsibleSideDrawer(
            selectedIndex: _currentIndex,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            isCollapsed: _isCollapsed,
            onToggleCollapse: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            onLogout: _handleLogout,
            employeeName: displayName,
          ),

          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'بوابة الموظف',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'متصل بقاعدة أوراكل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      if (user?.branchNo != null) ...[
                        Chip(
                          avatar: const Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text('فرع رقم: ${user!.branchNo}'),
                          backgroundColor: AppColors.surfaceSubtle,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        const SizedBox(width: 12),
                      ],

                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          color: AppColors.error,
                        ),
                        tooltip: 'خروج',
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _sections,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
