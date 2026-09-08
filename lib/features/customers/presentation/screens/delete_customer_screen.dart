import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_picker_screen.dart';

/// شاشة حذف عميل - اختيار العميل ثم تأكيد الحذف
class DeleteCustomerScreen extends ConsumerStatefulWidget {
  const DeleteCustomerScreen({super.key});

  @override
  ConsumerState<DeleteCustomerScreen> createState() => _DeleteCustomerScreenState();
}

class _DeleteCustomerScreenState extends ConsumerState<DeleteCustomerScreen> {
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;

  Future<void> _pickCustomer() async {
    final picked = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder: (_) => const CustomerPickerScreen(
          title: 'اختر العميل للحذف',
          subtitle: 'ابحث وحدد العميل الذي تريد حذفه',
          icon: Icons.person_remove_rounded,
        ),
      ),
    );
    if (picked != null) {
      setState(() => _selectedCustomer = picked);
    }
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedCustomer == null) return;

    // حوار تأكيد الحذف
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_forever_rounded,
              color: AppColors.error, size: 32),
        ),
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCustomer!.custName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.tag_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        'رقم العميل: ${_selectedCustomer!.custNo}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'هل أنت متأكد من حذف هذا العميل؟\nهذا الإجراء لا يمكن التراجع عنه!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final result = await repo.deleteCustomer(_selectedCustomer!.custNo);
      if (!mounted) return;
      if (result.success) {
        ref.read(customersListProvider.notifier).loadCustomers(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('تم حذف العميل بنجاح!'),
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message)),
            ]),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حذف عميل',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'إزالة العميل من قاعدة البيانات',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _selectedCustomer == null
          ? _buildPickerPrompt()
          : _buildConfirmationView(),
    );
  }

  Widget _buildPickerPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_rounded,
                  size: 52, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'اختر العميل للحذف',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابحث وحدد العميل الذي تريد حذفه من النظام',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _pickCustomer,
                icon: const Icon(Icons.search_rounded),
                label: const Text(
                  'بحث واختيار العميل',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationView() {
    final c = _selectedCustomer!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بطاقة بيانات العميل المختار
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.error, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.custName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'رقم العميل: ${c.custNo}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _infoRow(Icons.phone_rounded, 'الهاتف 1', c.tel1 ?? 'غير مسجل'),
                if (c.tel2 != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.phone_android_rounded, 'الهاتف 2', c.tel2!),
                ],
                if (c.addr != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on_rounded, 'العنوان', c.addr!),
                ],
                if (c.accNo != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.numbers_rounded, 'رقم الحساب', c.accNo.toString()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // تحذير
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تحذير: لا يمكن التراجع عن حذف العميل وستُفقد جميع بياناته!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.error,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickCustomer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('تغيير العميل'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _confirmAndDelete,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_forever_rounded),
                  label: Text(
                    _isLoading ? 'جارٍ الحذف...' : 'حذف العميل',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
