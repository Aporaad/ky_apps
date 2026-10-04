import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';

/// شاشة تعديل الحساب المحاسبي (CHART_ACC)
class EditAccountScreen extends ConsumerStatefulWidget {
  final int accNo;
  final String accName;

  const EditAccountScreen({
    super.key,
    required this.accNo,
    required this.accName,
  });

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _limitedBalanceController;

  bool _isStopped = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accName);
    _balanceController = TextEditingController();
    _limitedBalanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitedBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final repo = ref.read(accountRepositoryProvider);

    Map<String, dynamic> updateData = {
      'acc_name': _nameController.text.trim(),
      'stopping_acc': _isStopped ? 1 : 0,
    };

    if (_balanceController.text.trim().isNotEmpty) {
      updateData['balance'] = double.tryParse(_balanceController.text.trim());
    }

    if (_limitedBalanceController.text.trim().isNotEmpty) {
      updateData['limited_balance'] = double.tryParse(_limitedBalanceController.text.trim());
    }

    final res = await repo.updateChartAccount(widget.accNo, updateData);

    setState(() {
      _isSubmitting = false;
    });

    if (res.success && mounted) {
      ref.read(accountTreeProvider.notifier).loadTree();
      ref.read(chartAccountsProvider.notifier).loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message.isEmpty ? 'تم تعديل الحساب بنجاح' : res.message)),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('تعديل الحساب: ${widget.accNo}'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الحساب: ${widget.accNo}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الحساب المالي',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.edit),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'الرجاء إدخال اسم الحساب';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'الرصيد الحرفي الجديد (أتركه فارغاً للإبقاء على الرصيد الحالي)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _limitedBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'سقف الرصيد / الحد الائتماني',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.shield_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('توقيف الحساب (Stopping Account)'),
                        subtitle: const Text('عند توقيف الحساب لن يظهر في التعاملات اليومية السريعة'),
                        value: _isStopped,
                        activeColor: AppColors.error,
                        onChanged: (val) {
                          setState(() {
                            _isStopped = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitEdit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSubmitting ? 'جاري التعديل...' : 'تحديث بيانات الحساب',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
