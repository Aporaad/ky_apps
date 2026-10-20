import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';

/// شاشة إنشاء حساب جديد - تصميم منظم ومحكم
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  String _accountType = 'chart';

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitedBalanceController = TextEditingController();

  int? _selectedAccNo;
  int? _selectedAccSub;
  int? _selectedAccPart;
  int? _selectedGroupId;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitedBalanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_accountType == 'group' && _selectedAccPart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار الحساب الجزئي الأب')),
      );
      return;
    }

    if (_accountType == 'chart' && _selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار مجموعة الحسابات الجزئية الأب'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repo = ref.read(accountRepositoryProvider);

    if (_accountType == 'group') {
      final res = await repo.createSubGroup(
        name: _nameController.text.trim(),
        accPart: _selectedAccPart!,
      );
      setState(() => _isSubmitting = false);

      if (res.success && mounted) {
        ref.read(accountTreeProvider.notifier).loadTree();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message.isEmpty ? 'تم إنشاء مجموعة الحسابات بنجاح' : res.message,
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
    } else {
      final balance = double.tryParse(_balanceController.text.trim());
      final limitedBalance =
          double.tryParse(_limitedBalanceController.text.trim());

      final res = await repo.createChartAccount(
        name: _nameController.text.trim(),
        groupId: _selectedGroupId!,
        balance: balance,
        limitedBalance: limitedBalance,
      );

      setState(() => _isSubmitting = false);

      if (res.success && mounted) {
        ref.read(accountTreeProvider.notifier).loadTree();
        ref.read(chartAccountsProvider.notifier).loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.message.isEmpty ? 'تم إنشاء الحساب المالي بنجاح' : res.message,
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
  }

  @override
  Widget build(BuildContext context) {
    final parentAccountsAsync = ref.watch(parentAccountsProvider);
    final parentAccMainAsync = ref.watch(parentAccMainProvider(_selectedAccNo));
    final parentAccSubAsync = ref.watch(parentAccSubProvider(_selectedAccSub));
    final parentAccSubGroupAsync =
        ref.watch(parentAccSubGroupProvider(_selectedAccPart));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'إنشاء حساب جديد',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              // ─── اختيار نوع الحساب ───
              _buildSectionCard(
                title: 'نوع الحساب المطلوب إنشاؤه',
                icon: Icons.category_outlined,
                iconColor: AppColors.primary,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeOption(
                        value: 'chart',
                        label: 'حساب مالي',
                        subtitle: 'CHART_ACC',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeOption(
                        value: 'group',
                        label: 'مجموعة جزئية',
                        subtitle: 'ACC_SUB_GROUP',
                        icon: Icons.create_new_folder_outlined,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── سلسلة الحسابات الأب ───
              _buildSectionCard(
                title: 'الحساب الأب والسلسلة المحاسبية',
                icon: Icons.account_tree_outlined,
                iconColor: const Color(0xFF00695C),
                child: Column(
                  children: [
                    // المستوى 1
                    parentAccountsAsync.when(
                      data: (accounts) => _buildDropdown<int>(
                        label: '1. القسم الرئيسي (ACCOUNT)',
                        icon: Icons.folder_special_outlined,
                        iconColor: Colors.indigo,
                        value: _selectedAccNo,
                        items: accounts
                            .map(
                              (a) => DropdownMenuItem<int>(
                                value: a.accNo,
                                child: Text('${a.accNo} - ${a.accName}'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAccNo = val;
                            _selectedAccSub = null;
                            _selectedAccPart = null;
                            _selectedGroupId = null;
                          });
                        },
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) =>
                          Text(
                            'خطأ في تحميل الحسابات: $err',
                            style: const TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                    ),

                    // المستوى 2
                    if (_selectedAccNo != null) ...[
                      const SizedBox(height: 10),
                      parentAccMainAsync.when(
                        data: (mainList) => _buildDropdown<int>(
                          label: '2. الحساب الفرعي (ACC_MAIN)',
                          icon: Icons.folder_outlined,
                          iconColor: Colors.blue,
                          value: _selectedAccSub,
                          items: mainList
                              .map(
                                (m) => DropdownMenuItem<int>(
                                  value: m.accSub,
                                  child: Text('${m.accSub} - ${m.subName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedAccSub = val;
                              _selectedAccPart = null;
                              _selectedGroupId = null;
                            });
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('خطأ: $err'),
                      ),
                    ],

                    // المستوى 3
                    if (_selectedAccSub != null) ...[
                      const SizedBox(height: 10),
                      parentAccSubAsync.when(
                        data: (subList) => _buildDropdown<int>(
                          label: '3. الحساب الجزئي (ACC_SUB)',
                          icon: Icons.snippet_folder_outlined,
                          iconColor: Colors.teal,
                          value: _selectedAccPart,
                          items: subList
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.accPart,
                                  child: Text('${s.accPart} - ${s.partName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedAccPart = val;
                              _selectedGroupId = null;
                            });
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('خطأ: $err'),
                      ),
                    ],

                    // المستوى 4 (للحساب المالي فقط)
                    if (_accountType == 'chart' && _selectedAccPart != null) ...[
                      const SizedBox(height: 10),
                      parentAccSubGroupAsync.when(
                        data: (groupList) => _buildDropdown<int>(
                          label: '4. مجموعة الحسابات (ACC_SUB_GROUP)',
                          icon: Icons.create_new_folder_outlined,
                          iconColor: Colors.amber.shade800,
                          value: _selectedGroupId,
                          items: groupList
                              .map(
                                (g) => DropdownMenuItem<int>(
                                  value: g.groupId,
                                  child: Text('${g.groupId} - ${g.accGroupName}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedGroupId = val);
                          },
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (err, _) => Text('خطأ: $err'),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ─── بيانات الحساب ───
              _buildSectionCard(
                title: 'بيانات الحساب الجديد',
                icon: Icons.edit_note_rounded,
                iconColor: const Color(0xFFE65100),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: _buildInputDecoration(
                        label: _accountType == 'group'
                            ? 'اسم مجموعة الحسابات'
                            : 'اسم الحساب المالي',
                        icon: Icons.label_outline,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'الرجاء إدخال الاسم';
                        }
                        return null;
                      },
                    ),
                    if (_accountType == 'chart') ...[
                      const SizedBox(height: 10),
                      Row(
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
                                label: 'الرصيد الافتتاحي',
                                hint: 'اختياري',
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
                                hint: 'اختياري',
                                icon: Icons.shield_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    _isSubmitting
                        ? 'جاري الحفظ...'
                        : (_accountType == 'group'
                            ? 'حفظ مجموعة الحسابات'
                            : 'حفظ الحساب المالي'),
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

  Widget _buildTypeOption({
    required String value,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _accountType == value;
    return InkWell(
      onTap: () => setState(() => _accountType = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isSelected
                          ? color.withValues(alpha: 0.7)
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
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

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required Color iconColor,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, color: iconColor, size: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
