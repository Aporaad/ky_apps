import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
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

/// الهيكل الرئيسي لبوابة الموظف المتجاوب بالكامل مع مختلف أحجام الشاشات
/// Main Employee Portal Layout with Responsive Sidebar / Drawer and Top Bar
class EmployeeMainLayout extends ConsumerStatefulWidget {
  const EmployeeMainLayout({super.key});

  @override
  ConsumerState<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends ConsumerState<EmployeeMainLayout> {
  int _currentIndex = 0;
  bool _isCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final isMobile = Responsive.isMobile(context);

    // واجهة القائمة الجانبية المشتركة
    final sideDrawer = CollapsibleSideDrawer(
      selectedIndex: _currentIndex,
      onIndexChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      isCollapsed: isMobile ? false : _isCollapsed,
      isDrawerMode: isMobile,
      onToggleCollapse: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      onLogout: _handleLogout,
      employeeName: displayName,
    );

    if (isMobile) {
      // 📱 تخطيط الهواتف المحمولة (Mobile Layout)
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: Drawer(
          width: 280,
          child: SafeArea(child: sideDrawer),
        ),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
            tooltip: 'القائمة الرئيسية',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'بوابة الموظف',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            if (user?.branchNo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'فرع ${user!.branchNo}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(
                Icons.power_settings_new_rounded,
                color: AppColors.error,
                size: 22,
              ),
              tooltip: 'خروج',
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _sections,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex < 4 ? _currentIndex : 4,
          onDestinationSelected: (idx) {
            if (idx == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              setState(() {
                _currentIndex = idx;
              });
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale_rounded),
              label: 'المبيعات',
            ),
            NavigationDestination(
              icon: Icon(Icons.content_cut_outlined),
              selectedIcon: Icon(Icons.content_cut_rounded),
              label: 'التفصيل',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'الحسابات',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_rounded),
              label: 'المزيد',
            ),
          ],
        ),
      );
    }

    // 💻 تخطيط الأجهزة اللوحية والمكتبية (Tablet & Desktop Layout)
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          sideDrawer,
          Expanded(
            child: Column(
              children: [
                // الشريط العلوي للشاشات الكبيرة مع حماية تامة ضد التجاوز
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'بوابة الموظف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 10),
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
