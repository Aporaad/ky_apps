import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import 'customer_statement_screen.dart';
import 'edit_customer_screen.dart';

/// شاشة عرض جميع العملاء مع البحث والفرز والإجراءات السريعة
class AllCustomersScreen extends ConsumerStatefulWidget {
  const AllCustomersScreen({super.key});

  @override
  ConsumerState<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends ConsumerState<AllCustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
            Icon(Icons.people_alt_rounded, color: Color(0xFFD97706), size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قائمة العملاء',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'جميع العملاء المسجلين في النظام',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(customersListProvider.notifier).loadCustomers(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (q) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      ref.read(customersListProvider.notifier).search(q);
                    });
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الرقم...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchCtrl.clear();
                              ref.read(customersListProvider.notifier).search('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                if (!state.isLoading && state.error == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'إجمالي العملاء: ${state.customers.length}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        if (state.searchQuery.isNotEmpty) ...[
                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                          Text(
                            'نتائج البحث عن: "${state.searchQuery}"',
                            style: TextStyle(fontSize: 12, color: AppColors.accent),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // القائمة
          Expanded(child: _buildContent(context, state)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CustomersListState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text('جارٍ تحميل قائمة العملاء...', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.error),
              const SizedBox(height: 14),
              Text(state.error!, textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(customersListProvider.notifier).loadCustomers(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text('لا يوجد عملاء',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              state.searchQuery.isNotEmpty
                  ? 'لا توجد نتائج للبحث عن "${state.searchQuery}"'
                  : 'لا يوجد عملاء مسجلون في النظام',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final crossCount = constraints.maxWidth > 700 ? 2 : 1;
        if (crossCount == 2) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: state.customers.length,
            itemBuilder: (_, i) => _CustomerCard(customer: state.customers[i]),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.customers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _CustomerCard(customer: state.customers[i]),
        );
      },
    );
  }
}

/// بطاقة عميل في شاشة كل العملاء
class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: customer.isStopped
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // رقم العميل
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: customer.isStopped
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${customer.custNo}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: customer.isStopped ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.custName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.tel1 != null)
                        Text(
                          customer.tel1!,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                if (customer.isStopped)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'موقوف',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ),
              ],
            ),
            if (customer.addr != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.addr!,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // أزرار الإجراءات السريعة
            Row(
              children: [
                _actionBtn(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'كشف',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerStatementScreen(
                        custNo: customer.custNo,
                        custName: customer.custName,
                        accNo: customer.accNo,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _actionBtn(
                  icon: Icons.edit_rounded,
                  label: 'تعديل',
                  color: AppColors.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditCustomerScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
