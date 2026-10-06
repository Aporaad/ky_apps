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

/// واجهة قسم الحسابات والمالية - تصميم عصري، منظم ومتناسق الأحجام
class AccountsDashboardScreen extends ConsumerStatefulWidget {
  const AccountsDashboardScreen({super.key});

  @override
  ConsumerState<AccountsDashboardScreen> createState() =>
      _AccountsDashboardScreenState();
}

class _AccountsDashboardScreenState
    extends ConsumerState<AccountsDashboardScreen> {
  final TextEditingController _quickSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartAccountsProvider.notifier).loadAccounts();
      ref.read(accountTreeProvider.notifier).loadTree();
      ref.read(currenciesProvider.notifier).loadCurrencies();
    });
  }

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
  }

  void _showEditAccountSelectionDialog(BuildContext context) {
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
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
                    ref
                        .read(chartAccountsProvider.notifier)
                        .loadAccounts(search: val.trim());
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث باسم أو رقم الحساب...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.accounts.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد حسابات مطابقة للبحث',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.accounts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final acc = state.accounts[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_note_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                acc.accName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                'رقم الحساب: ${acc.accNo}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
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
  Widget build(BuildContext context) {
    final treeState = ref.watch(accountTreeProvider);
    final currenciesState = ref.watch(currenciesProvider);
    final chartState = ref.watch(chartAccountsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الصفحة المصغر والأنيق
            Container(
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إدارة الحسابات والمالية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'الشجرة المحاسبية، كشوفات الحساب، العملات والصرف',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    tooltip: 'تحديث البيانات',
                    onPressed: () {
                      ref.read(chartAccountsProvider.notifier).loadAccounts();
                      ref.read(accountTreeProvider.notifier).loadTree();
                      ref.read(currenciesProvider.notifier).loadCurrencies();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // شريط إحصائيات سريع متوازن الحجم
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatCard(
                    title: 'الحسابات',
                    value: '${chartState.accounts.length}',
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatCard(
                    title: 'العملات',
                    value: '${currenciesState.currencies.length}',
                    icon: Icons.currency_exchange_rounded,
                    accentColor: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCompactStatCard(
                    title: 'أقسام الشجرة',
                    value: '${treeState.tree.length}',
                    icon: Icons.account_tree_rounded,
                    accentColor: const Color(0xFF7B1FA2),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // قسم 1: التقارير والكشوفات المالية
            _buildSectionHeader(
              title: 'التقارير والكشوفات المالية',
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 520 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 3.4 : 2.5,
                  children: [
                    _buildModernActionTile(
                      title: 'كشف حساب مالي',
                      subtitle: 'عرض حركات المدين والدائن والأرصدة',
                      icon: Icons.receipt_long_rounded,
                      badgeText: 'عام',
                      badgeColor: const Color(0xFFE65100),
                      iconColor: const Color(0xFFE65100),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountStatementScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernActionTile(
                      title: 'كشف حساب تحليلي مفصل',
                      subtitle: 'تصفية حسب المستويات والفئات والعملات',
                      icon: Icons.query_stats_rounded,
                      badgeText: 'متقدم',
                      badgeColor: const Color(0xFF6A1B9A),
                      iconColor: const Color(0xFF6A1B9A),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const AccountStatementDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // قسم 2: الشجرة المحاسبية وإدارة الحسابات
            _buildSectionHeader(
              title: 'الهيكل المحاسبي وإدارة الحسابات',
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 520 ? 3 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 1 ? 3.4 : 2.1,
                  children: [
                    _buildModernActionTile(
                      title: 'الشجرة المحاسبية',
                      subtitle: 'هيكل الشجرة وفروع الحسابات',
                      icon: Icons.account_tree_rounded,
                      badgeText: 'الهيكل',
                      badgeColor: const Color(0xFF1565C0),
                      iconColor: const Color(0xFF1565C0),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountTreeScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernActionTile(
                      title: 'إضافة حساب جديد',
                      subtitle: 'إنشاء حساب مالي أو مجموعة جزئية',
                      icon: Icons.add_circle_outline_rounded,
                      badgeText: 'جديد',
                      badgeColor: const Color(0xFF00897B),
                      iconColor: const Color(0xFF00897B),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateAccountScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModernActionTile(
                      title: 'تعديل بيانات حساب',
                      subtitle: 'تعديل الأسماء وسقف الأرصدة',
                      icon: Icons.edit_note_rounded,
                      badgeText: 'تعديل',
                      badgeColor: const Color(0xFF00695C),
                      iconColor: const Color(0xFF00695C),
                      onTap: () => _showEditAccountSelectionDialog(context),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // قسم 3: العملات وأسعار الصرف
            _buildSectionHeader(
              title: 'العملات وأسعار الصرف',
              icon: Icons.currency_exchange_outlined,
            ),
            const SizedBox(height: 8),
            _buildModernActionTile(
              title: 'دليل العملات وأسعار الصرف اليومية',
              subtitle:
                  'إدارة العملات المعتمدة وسجل تحديثات أسعار الصرف والتنبيهات',
              icon: Icons.price_change_rounded,
              badgeText: 'الصرف',
              badgeColor: const Color(0xFF2E7D32),
              iconColor: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CurrencyScreen()),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
