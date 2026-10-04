import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';

/// شاشة إنشاء حساب جديد (تتيح إنشاء مجموعة حسابات جزئي أو حساب مالي)
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // نوع الحساب المراد إنشاؤه: 'group' (مجموعة حسابات جزئي) أو 'chart' (حساب مالي)
  String _accountType = 'chart';

  // الحقول النصية
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitedBalanceController = TextEditingController();

  // القيم المختارة في الشجرة الهرمية للأب
  int? _selectedAccNo; // Level 1: ACCOUNT
  int? _selectedAccSub; // Level 2: ACC_MAIN
  int? _selectedAccPart; // Level 3: ACC_SUB (الحساب الجزئي)
  int? _selectedGroupId; // Level 4: ACC_SUB_GROUP (مجموعة الحسابات)

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
        const SnackBar(content: Text('الرجاء اختيار مجموعة الحسابات الجزئية الأب')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final repo = ref.read(accountRepositoryProvider);

    if (_accountType == 'group') {
      final res = await repo.createSubGroup(
        name: _nameController.text.trim(),
        accPart: _selectedAccPart!,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (res.success && mounted) {
        ref.read(accountTreeProvider.notifier).loadTree();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isEmpty ? 'تم إنشاء مجموعة الحسابات بنجاح' : res.message)),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
        );
      }
    } else {
      final balance = double.tryParse(_balanceController.text.trim());
      final limitedBalance = double.tryParse(_limitedBalanceController.text.trim());

      final res = await repo.createChartAccount(
        name: _nameController.text.trim(),
        groupId: _selectedGroupId!,
        balance: balance,
        limitedBalance: limitedBalance,
      );

      setState(() {
        _isSubmitting = false;
      });

      if (res.success && mounted) {
        ref.read(accountTreeProvider.notifier).loadTree();
        ref.read(chartAccountsProvider.notifier).loadAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isEmpty ? 'تم إنشاء الحساب المالي بنجاح' : res.message)),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentAccountsAsync = ref.watch(parentAccountsProvider);
    final parentAccMainAsync = ref.watch(parentAccMainProvider(_selectedAccNo));
    final parentAccSubAsync = ref.watch(parentAccSubProvider(_selectedAccSub));
    final parentAccSubGroupAsync = ref.watch(parentAccSubGroupProvider(_selectedAccPart));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اختيار نوع الحساب
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الإضافة المطلوبة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('حساب مالي'),
                              subtitle: const Text('CHART_ACC'),
                              value: 'chart',
                              groupValue: _accountType,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _accountType = val!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('مجموعة حسابات جزئية'),
                              subtitle: const Text('ACC_SUB_GROUP'),
                              value: 'group',
                              groupValue: _accountType,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _accountType = val!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // تحديد الحسابات الأب
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الحساب الأب والسلسلة المحاسبية',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Level 1: القسم الرئيسي (ACCOUNT)
                      parentAccountsAsync.when(
                        data: (accounts) => DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                            labelText: '1. القسم الرئيسي (ACCOUNT)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.folder_special, color: Colors.indigo),
                          ),
                          value: _selectedAccNo,
                          items: accounts.map((a) {
                            return DropdownMenuItem<int>(
                              value: a.accNo,
                              child: Text('${a.accNo} - ${a.accName}'),
                            );
                          }).toList(),
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
                        error: (err, _) => Text('خطأ في تحميل الحسابات الرئيسية: $err'),
                      ),

                      const SizedBox(height: 16),

                      // Level 2: الحساب الفرعي (ACC_MAIN)
                      if (_selectedAccNo != null)
                        parentAccMainAsync.when(
                          data: (mainList) => DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: '2. الحساب الفرعي (ACC_MAIN)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.folder, color: Colors.blue),
                            ),
                            value: _selectedAccSub,
                            items: mainList.map((m) {
                              return DropdownMenuItem<int>(
                                value: m.accSub,
                                child: Text('${m.accSub} - ${m.subName}'),
                              );
                            }).toList(),
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

                      if (_selectedAccSub != null) const SizedBox(height: 16),

                      // Level 3: الحساب الجزئي (ACC_SUB)
                      if (_selectedAccSub != null)
                        parentAccSubAsync.when(
                          data: (subList) => DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: '3. الحساب الجزئي (ACC_SUB)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.snippet_folder, color: Colors.teal),
                            ),
                            value: _selectedAccPart,
                            items: subList.map((s) {
                              return DropdownMenuItem<int>(
                                value: s.accPart,
                                child: Text('${s.accPart} - ${s.partName}'),
                              );
                            }).toList(),
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

                      if (_accountType == 'chart' && _selectedAccPart != null) const SizedBox(height: 16),

                      // Level 4: مجموعة الحسابات الجزئية (ACC_SUB_GROUP) - مطلوب فقط في حالة الحساب المالي
                      if (_accountType == 'chart' && _selectedAccPart != null)
                        parentAccSubGroupAsync.when(
                          data: (groupList) => DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: '4. مجموعة الحسابات (ACC_SUB_GROUP)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.create_new_folder, color: Colors.amber),
                            ),
                            value: _selectedGroupId,
                            items: groupList.map((g) {
                              return DropdownMenuItem<int>(
                                value: g.groupId,
                                child: Text('${g.groupId} - ${g.accGroupName}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedGroupId = val;
                              });
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Text('خطأ: $err'),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // التفاصيل والاسم
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 1,
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بيانات الحساب',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: _accountType == 'group' ? 'اسم مجموعة الحسابات' : 'اسم الحساب المالي',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.edit_note),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم';
                          }
                          return null;
                        },
                      ),
                      if (_accountType == 'chart') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _balanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'الرصيد الافتتاحي (اختياري)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _limitedBalanceController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'سقف الرصيد / الحد (اختياري)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.shield_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting
                        ? 'جاري التنسيق والحفظ...'
                        : (_accountType == 'group' ? 'حفظ مجموعة الحسابات' : 'حفظ الحساب المالي'),
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
