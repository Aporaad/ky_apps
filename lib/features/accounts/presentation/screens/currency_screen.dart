import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/currency_model.dart';
import '../providers/currency_provider.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// واجهة العملات وأسعار الصرف - تصميم منظم وعصري
class CurrencyScreen extends ConsumerStatefulWidget {
  const CurrencyScreen({super.key});

  @override
  ConsumerState<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends ConsumerState<CurrencyScreen> {
  void _showAddEditCurrencyDialog({CurrencyModel? currency}) {
    final isEdit = currency != null;
    final nameCtrl = TextEditingController(text: currency?.curName ?? '');
    final codeCtrl = TextEditingController(text: currency?.code ?? '');
    final mainNameCtrl =
        TextEditingController(text: currency?.mainCurName ?? '');
    final subNameCtrl = TextEditingController(text: currency?.subCurName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        title: Row(
          children: [
            Icon(
              isEdit ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEdit ? 'تعديل عملة' : 'إضافة عملة جديدة',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                _buildDialogField(
                  controller: nameCtrl,
                  label: 'اسم العملة',
                  hint: 'مثال: ريال يمني',
                  icon: Icons.label_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'الرجاء إدخال الاسم' : null,
                ),
                const SizedBox(height: 10),
                _buildDialogField(
                  controller: codeCtrl,
                  label: 'رمز العملة',
                  hint: 'YER / SAR / USD',
                  icon: Icons.code_rounded,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogField(
                        controller: mainNameCtrl,
                        label: 'الوحدة الرئيسية',
                        hint: 'ريال',
                        icon: Icons.monetization_on_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDialogField(
                        controller: subNameCtrl,
                        label: 'الوحدة الفرعية',
                        hint: 'فلس/سنت',
                        icon: Icons.money_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final notifier = ref.read(currenciesProvider.notifier);
              if (isEdit) {
                final res = await notifier.updateCurrency(currency.curNo, {
                  'cur_name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  'main_cur_name': mainNameCtrl.text.trim(),
                  'sub_cur_name': subNameCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res.message.isEmpty ? 'تم التعديل بنجاح' : res.message,
                      ),
                    ),
                  );
                }
              } else {
                final newCur = CurrencyModel(
                  curNo: 0,
                  curName: nameCtrl.text.trim(),
                  code: codeCtrl.text.trim(),
                  mainCurName: mainNameCtrl.text.trim(),
                  subCurName: subNameCtrl.text.trim(),
                );
                final res = await notifier.addCurrency(newCur);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res.message.isEmpty
                            ? 'تمت إضافة العملة بنجاح'
                            : res.message,
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(isEdit ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _showRateHistorySheet(CurrencyModel currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RateHistoryModal(currency: currency),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'العملات وأسعار الصرف',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () =>
                ref.read(currenciesProvider.notifier).loadCurrencies(),
          ),
        ],
      ),
      body: currenciesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : currenciesState.error != null
          ? Center(
              child: Text(
                'خطأ: ${currenciesState.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            )
          : currenciesState.currencies.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
              itemCount: currenciesState.currencies.length,
              itemBuilder: (context, index) {
                final currency = currenciesState.currencies[index];
                return _buildCurrencyCard(currency);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCurrencyDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملة'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCurrencyCard(CurrencyModel currency) {
    final isRising = currency.isRising;
    final isFalling = currency.isFalling;
    final changeColor = isRising
        ? const Color(0xFF2E7D32)
        : isFalling
        ? AppColors.error
        : AppColors.textMuted;
    final changeIcon = isRising
        ? Icons.trending_up_rounded
        : isFalling
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // سطر العملة الرئيسي
            Row(
              children: [
                // شارة العملة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      currency.code?.isNotEmpty == true
                          ? currency.code!
                          : currency.curName.substring(0, 1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // اسم العملة ووصفها
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency.curName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (currency.mainCurName != null)
                        Text(
                          '${currency.mainCurName} / ${currency.subCurName ?? '-'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),

                // زر التعديل
                InkWell(
                  onTap: () => _showAddEditCurrencyDialog(currency: currency),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // سطر أسعار الصرف
            Row(
              children: [
                // السعر الحالي
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'سعر الصرف الحالي',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.currentPrice.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // مؤشر التغيير
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: changeColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(changeIcon, size: 14, color: changeColor),
                      const SizedBox(width: 3),
                      Text(
                        '${currency.changePercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // زر السجل
                OutlinedButton.icon(
                  onPressed: () => _showRateHistorySheet(currency),
                  icon: const Icon(Icons.history_rounded, size: 14),
                  label: const Text(
                    'سجل الأسعار',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(fontSize: 12.5),
        prefixIcon: Icon(icon, size: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد عملات مضافة',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اضغط على زر + لإضافة عملة جديدة',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// نافذة سجل أسعار الصرف
class _RateHistoryModal extends ConsumerStatefulWidget {
  final CurrencyModel currency;

  const _RateHistoryModal({required this.currency});

  @override
  ConsumerState<_RateHistoryModal> createState() => _RateHistoryModalState();
}

class _RateHistoryModalState extends ConsumerState<_RateHistoryModal> {
  final _priceCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPrice() async {
    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال سعر صرف صحيح')),
      );
      return;
    }

    final repo = ref.read(currencyRepositoryProvider);
    final dateStr = _formatDateDash(_selectedDate);
    final res = await repo.addPrice(widget.currency.curNo, price, dateStr);

    if (mounted) {
      _priceCtrl.clear();
      ref.invalidate(currencyPricesProvider(widget.currency.curNo));
      ref.read(currenciesProvider.notifier).loadCurrencies();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message.isEmpty ? 'تم تحديث سعر الصرف بنجاح' : res.message,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(
      currencyPricesProvider(widget.currency.curNo),
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس النافذة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'سجل أسعار: ${widget.currency.curName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // نموذج إضافة سعر جديد
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل سعر صرف جديد',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'السعر الجديد (مثال: 530)',
                          hintStyle: const TextStyle(fontSize: 12.5),
                          prefixIcon: const Icon(
                            Icons.price_change_outlined,
                            size: 17,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(9),
                          color: AppColors.surface,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatDateShort(_selectedDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addPrice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text(
                        'حفظ',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // عنوان السجل
          Row(
            children: [
              const Icon(
                Icons.list_alt_outlined,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              const Text(
                'السجل التاريخي للأسعار',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // قائمة الأسعار
          Expanded(
            child: pricesAsync.when(
              data: (data) {
                final list =
                    data['data'] as List<CurrencyPriceModel>? ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد أسعار سابقة مسجلة لهذه العملة',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = list[idx];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.price_change_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        '${item.price.toStringAsFixed(2)} ر.ي',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        item.dayDate,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        onPressed: () async {
                          final repo = ref.read(currencyRepositoryProvider);
                          await repo.deletePrice(
                            widget.currency.curNo,
                            item.seq,
                          );
                          ref.invalidate(
                            currencyPricesProvider(widget.currency.curNo),
                          );
                          ref.read(currenciesProvider.notifier).loadCurrencies();
                        },
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
