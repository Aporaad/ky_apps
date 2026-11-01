import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/store_model.dart';
import '../providers/stores_providers.dart';

/// نموذج إضافة/تعديل مخزن
/// The add/edit store form.
///
/// ── الحقول الأربعة المحاسبية (مخزون · تكلفة · خصم · فروق تكلفة) تُعرض كما هي لأن النظام
///    القديم يربط كل مخزن بحساباته؛ تركها فارغة يجعل القيود المحاسبية للمستندات ناقصة.
/// ── The four GL account fields are exposed as-is: the legacy system binds each store to its
///    accounts, and leaving them empty produces incomplete accounting entries.
class StoreFormScreen extends ConsumerStatefulWidget {
  const StoreFormScreen({super.key, this.store});

  final StoreModel? store;

  @override
  ConsumerState<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends ConsumerState<StoreFormScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.store?.storeName ?? '',
  );
  late final TextEditingController _location = TextEditingController(
    text: widget.store?.location ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.store?.note ?? '',
  );
  late final TextEditingController _invAcc = TextEditingController(
    text: widget.store?.invAccNo?.toString() ?? '',
  );
  late final TextEditingController _costAcc = TextEditingController(
    text: widget.store?.costAccNo?.toString() ?? '',
  );
  late final TextEditingController _discountAcc = TextEditingController(
    text: widget.store?.discountAccNo?.toString() ?? '',
  );
  late final TextEditingController _diffAcc = TextEditingController(
    text: widget.store?.diffCostAcc?.toString() ?? '',
  );

  String? _nameError;
  bool _saving = false;

  bool get _isEdit => widget.store != null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _note.dispose();
    _invAcc.dispose();
    _costAcc.dispose();
    _discountAcc.dispose();
    _diffAcc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEdit ? 'تعديل مخزن' : 'مخزن جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(
              controller: _name,
              label: 'اسم المخزن *',
              error: _nameError,
              icon: Icons.warehouse_outlined,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _location,
              label: 'الموقع',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _note,
              label: 'ملاحظة',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 18),
            Text(
              'الحسابات المحاسبية',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تُستخدم في قيود المستندات القديمة. اتركها فارغة إن لم تكن معروفة.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            _field(
              controller: _invAcc,
              label: 'حساب المخزون',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _costAcc,
              label: 'حساب التكلفة',
              icon: Icons.calculate_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _discountAcc,
              label: 'حساب الخصم',
              icon: Icons.percent_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _field(
              controller: _diffAcc,
              label: 'حساب فروق التكلفة',
              icon: Icons.compare_arrows_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 17),
                    label: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? error,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();

    if (name.isEmpty) {
      setState(() => _nameError = 'اسم المخزن مطلوب');

      return;
    }

    setState(() {
      _nameError = null;
      _saving = true;
    });

    final payload = <String, dynamic>{
      'store_name': name,
      'loc': _location.text.trim(),
      'note': _note.text.trim(),
      'inv_acc_no': _intOrNull(_invAcc.text),
      'cost_acc_no': _intOrNull(_costAcc.text),
      'discount_acc_no': _intOrNull(_discountAcc.text),
      'diff_cost_acc': _intOrNull(_diffAcc.text),
    };

    final result = await ref
        .read(storesListProvider.notifier)
        .save(storeNo: widget.store?.storeNo, payload: payload);

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context);
      return;
    }

    setState(() => _nameError = result.firstFieldError);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.displayMessage),
        backgroundColor: AppColors.error,
      ),
    );
  }

  int? _intOrNull(String value) {
    final text = value.trim();

    return text.isEmpty ? null : int.tryParse(text);
  }
}
