import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/responsive.dart';
import '../../data/models/customer_model.dart';
import '../widgets/customer_picker_screen.dart';
import 'add_customer_screen.dart';
import 'edit_customer_screen.dart';
import 'delete_customer_screen.dart';
import 'all_customers_screen.dart';
import 'customer_statement_screen.dart';

/// واجهة قسم العملاء الرئيسية - بطاقات عمليات مرتبة بألوان وأحجام التطبيق الرسمية
class CustomersDashboardScreen extends StatelessWidget {
  const CustomersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    final actions = _buildActions(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          _buildHeader(context),
          SizedBox(height: isMobile ? 18 : 24),

          // شبكة البطاقات
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount =
                  constraints.maxWidth < 480
                      ? 1
                      : constraints.maxWidth < 820
                      ? 2
                      : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio:
                      crossAxisCount == 1 ? 3.6 : (crossAxisCount == 2 ? 2.7 : 2.4),
                ),
                itemBuilder: (_, i) => actions[i],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
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
              Icons.people_rounded,
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
                  'إدارة العملاء',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'سجل وإدارة بيانات العملاء وأرصدتهم',
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
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      _CustomerActionCard(
        title: 'إضافة عميل',
        subtitle: 'تسجيل عميل جديد في النظام',
        icon: Icons.person_add_rounded,
        badge: 'إضافة',
        accent: AppColors.success,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            ),
      ),
      _CustomerActionCard(
        title: 'تعديل عميل',
        subtitle: 'تحديث بيانات عميل موجود',
        icon: Icons.edit_rounded,
        badge: 'تعديل',
        accent: AppColors.info,
        onTap: () async {
          final picked = await Navigator.of(context).push<CustomerModel>(
            MaterialPageRoute(
              builder:
                  (_) => const CustomerPickerScreen(
                    title: 'اختر العميل للتعديل',
                    subtitle: 'ابحث عن العميل الذي تريد تعديل بياناته',
                    icon: Icons.edit_rounded,
                  ),
            ),
          );
          if (picked != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditCustomerScreen(customer: picked),
              ),
            );
          }
        },
      ),
      _CustomerActionCard(
        title: 'حذف عميل',
        subtitle: 'إزالة عميل من النظام',
        icon: Icons.person_remove_rounded,
        badge: 'حذف',
        accent: AppColors.error,
        onTap: () async {
          final picked = await Navigator.of(context).push<CustomerModel>(
            MaterialPageRoute(
              builder:
                  (_) => const CustomerPickerScreen(
                    title: 'اختر العميل للحذف',
                    subtitle: 'ابحث وحدد العميل المراد حذفه',
                    icon: Icons.person_remove_rounded,
                  ),
            ),
          );
          if (picked != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeleteCustomerScreen(customer: picked),
              ),
            );
          }
        },
      ),
      _CustomerActionCard(
        title: 'كشف حساب',
        subtitle: 'عرض حركات وأرصدة العميل',
        icon: Icons.account_balance_wallet_rounded,
        badge: 'تقرير',
        accent: AppColors.accent,
        onTap: () async {
          final picked = await Navigator.of(context).push<CustomerModel>(
            MaterialPageRoute(
              builder:
                  (_) => const CustomerPickerScreen(
                    title: 'اختر العميل لكشف الحساب',
                    subtitle: 'ابحث بالاسم أو الرقم لعرض كشف حسابه',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
            ),
          );
          if (picked != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (_) => CustomerStatementScreen(
                      custNo: picked.custNo,
                      custName: picked.custName,
                      accNo: picked.accNo,
                    ),
              ),
            );
          }
        },
      ),
      _CustomerActionCard(
        title: 'كل العملاء',
        subtitle: 'استعراض قائمة العملاء كاملة',
        icon: Icons.people_alt_rounded,
        badge: 'استعراض',
        accent: AppColors.primary,
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
            ),
      ),
    ];
  }
}

/// بطاقة عملية العميل — تصميم مسطح أنيق يعتمد لوناً دلالياً من لوحة التطبيق الرسمية
class _CustomerActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final Color accent;
  final VoidCallback onTap;

  const _CustomerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
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
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
