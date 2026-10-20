import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_form_widget.dart';
import '../widgets/customer_picker_screen.dart';

/// شاشة تعديل بيانات عميل - تبدأ باختيار العميل ثم تعديله
class EditCustomerScreen extends ConsumerStatefulWidget {
  final CustomerModel? customer;

  const EditCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  CustomerModel? _selectedCustomer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
  }

  Future<void> _pickCustomer() async {
    final picked = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder: (_) => const CustomerPickerScreen(
          title: 'اختر العميل للتعديل',
          subtitle: 'ابحث عن العميل الذي تريد تعديل بياناته',
          icon: Icons.edit_rounded,
        ),
      ),
    );
    if (picked != null) {
      setState(() => _selectedCustomer = picked);
    }
  }

  Future<void> _handleUpdate(Map<String, dynamic> data) async {
    if (_selectedCustomer == null) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final result = await repo.updateCustomer(_selectedCustomer!.custNo, data);
      if (!mounted) return;
      if (result.success) {
        ref.read(customersListProvider.notifier).loadCustomers(refresh: true);
        _showSuccess('تم تعديل بيانات العميل بنجاح!');
        Navigator.pop(context);
      } else {
        _showError(result.message);
      }
    } catch (e) {
      if (mounted) _showError('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
      ),
    );
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
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تعديل بيانات عميل',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'تحديث معلومات العميل في قاعدة البيانات',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _selectedCustomer == null
          ? _buildPickerPrompt()
          : Column(
              children: [
                // بطاقة العميل المختار
                _buildSelectedCustomerBanner(),
                Expanded(
                  child: CustomerFormWidget(
                    initialData: _selectedCustomer,
                    submitLabel: 'حفظ التعديلات',
                    submitColor: AppColors.accent,
                    onSubmit: _handleUpdate,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
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
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded,
                  size: 52, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            Text(
              'اختر العميل للتعديل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابحث وحدد العميل الذي تريد تعديل بياناته',
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
                  backgroundColor: AppColors.accent,
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

  Widget _buildSelectedCustomerBanner() {
    final c = _selectedCustomer!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.custName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'رقم العميل: ${c.custNo} ${c.tel1 != null ? "• ${c.tel1}" : ""}',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _pickCustomer,
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('تغيير', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
