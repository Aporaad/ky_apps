import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/customer_model.dart';

/// نموذج بيانات العميل المشترك - يُستخدم في شاشتي الإضافة والتعديل
class CustomerFormWidget extends StatefulWidget {
  final CustomerModel? initialData;
  final String submitLabel;
  final Color submitColor;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
  final bool isLoading;

  const CustomerFormWidget({
    super.key,
    this.initialData,
    required this.submitLabel,
    required this.submitColor,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CustomerFormWidget> createState() => _CustomerFormWidgetState();
}

class _CustomerFormWidgetState extends State<CustomerFormWidget> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _custName;
  late final TextEditingController _addr;
  late final TextEditingController _tel1;
  late final TextEditingController _tel2;
  late final TextEditingController _postbox;
  late final TextEditingController _email;
  late final TextEditingController _fax;
  late final TextEditingController _accNo;
  late final TextEditingController _limitedBalance;
  late final TextEditingController _preCustName;
  bool _stoppingCust = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _custName = TextEditingController(text: d?.custName ?? '');
    _addr = TextEditingController(text: d?.addr ?? '');
    _tel1 = TextEditingController(text: d?.tel1 ?? '');
    _tel2 = TextEditingController(text: d?.tel2 ?? '');
    _postbox = TextEditingController(text: d?.postbox ?? '');
    _email = TextEditingController(text: d?.email ?? '');
    _fax = TextEditingController(text: d?.fax ?? '');
    _accNo = TextEditingController(text: d?.accNo?.toString() ?? '');
    _limitedBalance = TextEditingController(
      text: d?.limitedBalance?.toString() ?? '',
    );
    _preCustName = TextEditingController(text: d?.preCustName ?? '');
    _stoppingCust = (d?.stoppingCust ?? 0) != 0;
  }

  @override
  void dispose() {
    for (final c in [
      _custName,
      _addr,
      _tel1,
      _tel2,
      _postbox,
      _email,
      _fax,
      _accNo,
      _limitedBalance,
      _preCustName,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final data = {
      'cust_name': _custName.text.trim(),
      'addr': _addr.text.trim().isEmpty ? null : _addr.text.trim(),
      'tel1': _tel1.text.trim().isEmpty ? null : _tel1.text.trim(),
      'tel2': _tel2.text.trim().isEmpty ? null : _tel2.text.trim(),
      'postbox': _postbox.text.trim().isEmpty ? null : _postbox.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'fax': _fax.text.trim().isEmpty ? null : _fax.text.trim(),
      'acc_no':
          _accNo.text.trim().isEmpty ? null : int.tryParse(_accNo.text.trim()),
      'limited_balance':
          _limitedBalance.text.trim().isEmpty
              ? null
              : double.tryParse(_limitedBalance.text.trim()),
      'pre_cust_name':
          _preCustName.text.trim().isEmpty ? null : _preCustName.text.trim(),
      'stopping_cust': _stoppingCust ? 1 : 0,
    };
    await widget.onSubmit(data);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // معلومات أساسية
            _buildSectionTitle('المعلومات الأساسية', Icons.person_rounded),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _custName,
              label: 'اسم العميل *',
              hint: 'أدخل الاسم الكامل للعميل',
              icon: Icons.badge_rounded,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'اسم العميل مطلوب'
                          : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _preCustName,
              label: 'الاسم السابق',
              hint: 'الاسم القديم للعميل (إن وجد)',
              icon: Icons.history_rounded,
            ),
            const SizedBox(height: 20),

            // معلومات الاتصال
            _buildSectionTitle('معلومات الاتصال', Icons.contact_phone_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _tel1,
                    label: 'هاتف 1',
                    hint: '05xxxxxxxx',
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _tel2,
                    label: 'هاتف 2',
                    hint: '05xxxxxxxx',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _fax,
              label: 'فاكس',
              hint: 'رقم الفاكس',
              icon: Icons.print_rounded,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _email,
              label: 'البريد الإلكتروني',
              hint: 'example@mail.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final emailRegex = RegExp(r'^[\w-.]+@[\w-]+\.[a-z]{2,}$');
                if (!emailRegex.hasMatch(v.trim())) {
                  return 'تنسيق البريد الإلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // العنوان والمعلومات المالية
            _buildSectionTitle(
              'العنوان والمعلومات المالية',
              Icons.account_balance_rounded,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addr,
              label: 'العنوان',
              hint: 'عنوان العميل',
              icon: Icons.location_on_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _postbox,
              label: 'صندوق البريد',
              hint: 'رقم صندوق البريد',
              icon: Icons.mail_rounded,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _accNo,
                    label: 'رقم الحساب',
                    hint: 'رقم حساب العميل',
                    icon: Icons.numbers_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (int.tryParse(v.trim()) == null) {
                        return 'رقم الحساب غير صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _limitedBalance,
                    label: 'الحد الائتماني',
                    hint: '0.00',
                    icon: Icons.account_balance_wallet_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (double.tryParse(v.trim()) == null) {
                        return 'قيمة غير صحيحة';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // حالة العميل
            Container(
              decoration: BoxDecoration(
                color:
                    _stoppingCust
                        ? AppColors.error.withValues(alpha: 0.06)
                        : AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _stoppingCust
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: SwitchListTile(
                value: _stoppingCust,
                onChanged: (v) => setState(() => _stoppingCust = v),
                title: Text(
                  _stoppingCust ? 'العميل موقوف' : 'العميل نشط',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _stoppingCust ? AppColors.error : AppColors.success,
                  ),
                ),
                subtitle: Text(
                  _stoppingCust
                      ? 'لن يتمكن العميل من إجراء معاملات'
                      : 'العميل مفعّل ويمكنه إجراء المعاملات',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _stoppingCust
                            ? AppColors.error.withValues(alpha: 0.7)
                            : AppColors.success.withValues(alpha: 0.7),
                  ),
                ),
                secondary: Icon(
                  _stoppingCust
                      ? Icons.block_rounded
                      : Icons.check_circle_rounded,
                  color: _stoppingCust ? AppColors.error : AppColors.success,
                ),
                activeColor: AppColors.error,
                inactiveThumbColor: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),

            // زر الإرسال
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: widget.isLoading ? null : _handleSubmit,
                icon:
                    widget.isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.save_rounded),
                label: Text(
                  widget.isLoading ? 'جارٍ الحفظ...' : widget.submitLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.submitColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        labelStyle: const TextStyle(fontSize: 13),
        hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
      ),
    );
  }
}
