import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';
import '../providers/currency_provider.dart';
import 'account_statement_detail_screen.dart';
import 'account_statement_screen.dart';
import 'account_tree_screen.dart';
import 'create_account_screen.dart';
import 'currency_screen.dart';
import 'edit_account_screen.dart';

/// الشاشة الرئيسية ولوحة التحكم بقسم الحسابات
class AccountsDashboardScreen extends ConsumerWidget {
  const AccountsDashboardScreen({super.key});

  void _showEditAccountSelectionDialog(BuildContext context, WidgetRef ref) {
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(chartAccountsProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'اختر الحساب المراد تعديله',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) {
                    ref.read(chartAccountsProvider.notifier).loadAccounts(search: val.trim());
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث باسم أو رقم الحساب...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.accounts.isEmpty
                          ? const Center(child: Text('لا توجد حسابات'))
                          : ListView.separated(
                              itemCount: state.accounts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final acc = state.accounts[index];
                                return ListTile(
                                  leading: const Icon(Icons.edit_note, color: AppColors.primary),
                                  title: Text(acc.accName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('رقم الحساب: ${acc.accNo}'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EditAccountScreen(
                                          accNo: acc.accNo,
                                          accName: acc.accName,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeState = ref.watch(accountTreeProvider);
    final currenciesState = ref.watch(currenciesProvider);
    final chartState = ref.watch(chartAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان الرئيسي والوصف
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'إدارة الحسابات والشجرة المحاسبية',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'التحكم بالحسابات المالية، الكشوفات التفصيلية، والعملات مع الربط المباشر بـ Oracle',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // شريط الإحصائيات السريعة
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'الحسابات المالية',
                    value: '${chartState.accounts.length}',
                    subtitle: 'حساب مسجل',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'العملات النشطة',
                    value: '${currenciesState.currencies.length}',
                    subtitle: 'عملة مفعلة',
                    icon: Icons.currency_exchange,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'الشجرة المحاسبية',
                    value: '${treeState.tree.length}',
                    subtitle: 'أقسام رئيسية',
                    icon: Icons.account_tree_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'الخدمات والعمليات المحاسبية الرئيسية',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // بطاقات الأقسام والتطبيقات
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    // 1. إنشاء حساب
                    _buildFeatureCard(
                      context,
                      title: 'إنشاء حساب',
                      description: 'تتيح إنشاء "مجموعات الحسابات الجزئية" و "الحسابات المالية" والسلسلة الأب',
                      icon: Icons.add_card,
                      gradientColors: [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
                        );
                      },
                    ),

                    // 2. تعديل حساب
                    _buildFeatureCard(
                      context,
                      title: 'تعديل حساب',
                      description: 'تعديل بيانات وأسماء وسقف الأرصدة وتوقيف الحسابات المالية',
                      icon: Icons.edit_calendar,
                      gradientColors: [const Color(0xFF00897B), const Color(0xFF00695C)],
                      onTap: () => _showEditAccountSelectionDialog(context, ref),
                    ),

                    // 3. كشف حساب
                    _buildFeatureCard(
                      context,
                      title: 'كشف حساب',
                      description: 'عرض الحركات اليومية والمدين والدائن (مثل كشف حساب الموظفين والقصاصين)',
                      icon: Icons.receipt_long,
                      gradientColors: [const Color(0xFFFB8C00), const Color(0xFFEF6C00)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AccountStatementScreen()),
                        );
                      },
                    ),

                    // 4. كشف حساب مفصل
                    _buildFeatureCard(
                      context,
                      title: 'كشف حساب مفصل',
                      description: 'كشف بخيارات متقدمة وتصفية متعددة للمستويات والعملات والتاريخ',
                      icon: Icons.analytics,
                      gradientColors: [const Color(0xFF8E24AA), const Color(0xFF6A1B9A)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AccountStatementDetailScreen()),
                        );
                      },
                    ),

                    // 5. الشجرة المحاسبية
                    _buildFeatureCard(
                      context,
                      title: 'الشجرة المحاسبية',
                      description: 'عرض هيكل الشجرة مرتب ومنظم مع استثناء العملاء ما عدا "عملاء الكبودي لخياطة" (12310000)',
                      icon: Icons.account_tree,
                      gradientColors: [const Color(0xFF3949AB), const Color(0xFF283593)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AccountTreeScreen()),
                        );
                      },
                    ),

                    // 6. العملات وأسعار الصرف
                    _buildFeatureCard(
                      context,
                      title: 'العملات وأسعار الصرف',
                      description: 'إدارة العملات وسجل تحديثات أسعار الصرف اليومية والتنبيهات السعرية',
                      icon: Icons.price_change,
                      gradientColors: [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CurrencyScreen()),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
