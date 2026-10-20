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

/// واجهة قسم العملاء الرئيسية - تعرض بطاقات العمليات
class CustomersDashboardScreen extends StatelessWidget {
  const CustomersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;

    final cards = _buildActionCards(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          _buildHeader(context),
          SizedBox(height: isMobile ? 20 : 28),

          // شبكة البطاقات
          LayoutBuilder(
            builder: (ctx, constraints) {
              final crossAxisCount =
                  constraints.maxWidth < 480
                      ? 1
                      : constraints.maxWidth < 800
                      ? 2
                      : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.55,
                ),
                itemBuilder: (_, i) => cards[i],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.people_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدارة العملاء',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'سجل وإدارة بيانات العملاء وأرصدتهم',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildActionCards(BuildContext context) {
    return [
      _CustomerActionCard(
        title: 'إضافة عميل',
        subtitle: 'تسجيل عميل جديد في النظام',
        icon: Icons.person_add_rounded,
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 247, 247, 249), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            ),
      ),
      _CustomerActionCard(
        title: 'تعديل عميل',
        subtitle: 'تحديث بيانات عميل موجود',
        icon: Icons.edit_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllCustomersScreen()),
            ),
      ),
    ];
  }
}

/// بطاقة عملية العميل
class _CustomerActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CustomerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CustomerActionCard> createState() => _CustomerActionCardState();
}

class _CustomerActionCardState extends State<_CustomerActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.965,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 24),
                    ),

                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                // شريط الوصف مرّن بطبيعته: عرض البطاقة يتغيّر بين أعمدة الشبكة، والنص قد يطول
                // عن دائرته — فكان يتجاوز حدود البطاقة (42 بكسل على المكتب في اختبار الانحدار)
                // The subtitle pill is inherently stretchy: card width varies across grid columns and
                // the text can be longer than the pill, so it overflowed its card (42 px on desktop).
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
