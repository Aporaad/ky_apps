import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';

/// شاشة تعديل الحساب المحاسبي - تصميم منظم ومحكم
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

    setState(() => _isSubmitting = true);

    final repo = ref.read(accountRepositoryProvider);

    Map<String, dynamic> updateData = {
      'acc_name': _nameController.text.trim(),
      'stopping_acc': _isStopped ? 1 : 0,
    };

    if (_balanceController.text.trim().isNotEmpty) {
      updateData['balance'] = double.tryParse(_balanceController.text.trim());
    }
    if (_limitedBalanceController.text.trim().isNotEmpty) {
      updateData['limited_balance'] =
          double.tryParse(_limitedBalanceController.text.trim());
    }

    final res = await repo.updateChartAccount(widget.accNo, updateData);

    setState(() => _isSubmitting = false);

    if (res.success && mounted) {
      ref.read(accountTreeProvider.notifier).loadTree();
      ref.read(chartAccountsProvider.notifier).loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message.isEmpty ? 'تم تعديل الحساب بنجاح' : res.message,
          ),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تعديل الحساب #${widget.accNo}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة معلومات الحساب
              _buildSectionCard(
                title: 'معرّف الحساب',
                icon: Icons.fingerprint_rounded,
                iconColor: AppColors.primary,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${widget.accNo}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.accName,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // بيانات الحساب
              _buildSectionCard(
                title: 'بيانات الحساب',
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFF1565C0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: _buildInputDecoration(
                        label: 'اسم الحساب المالي',
                        icon: Icons.label_outline,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'الرجاء إدخال اسم الحساب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _balanceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 13.5),
                            decoration: _buildInputDecoration(
                              label: 'الرصيد الجديد',
                              hint: 'اتركه فارغاً للإبقاء على الرصيد الحالي',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _limitedBalanceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 13.5),
                            decoration: _buildInputDecoration(
                              label: 'سقف الرصيد',
                              hint: 'الحد الائتماني الأقصى',
                              icon: Icons.shield_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // حالة الحساب
              _buildSectionCard(
                title: 'حالة الحساب',
                icon: Icons.toggle_on_outlined,
                iconColor: _isStopped ? AppColors.error : const Color(0xFF2E7D32),
                child: InkWell(
                  onTap: () => setState(() => _isStopped = !_isStopped),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isStopped
                                    ? 'الحساب موقوف'
                                    : 'الحساب نشط',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isStopped
                                      ? AppColors.error
                                      : const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'عند توقيف الحساب لن يظهر في التعاملات اليومية السريعة',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isStopped,
                          onChanged: (val) =>
                              setState(() => _isStopped = val),
                          activeColor: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitEdit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'جاري التعديل...' : 'تحديث بيانات الحساب',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 12.5),
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}
