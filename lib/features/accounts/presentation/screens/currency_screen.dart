import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/currency_model.dart';
import '../providers/currency_provider.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateMonthDay(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// واجهة التحكم بالعملات واسعار الصرف ومتابعة تحديثاتها السعرية
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
    final mainNameCtrl = TextEditingController(text: currency?.mainCurName ?? '');
    final subNameCtrl = TextEditingController(text: currency?.subCurName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add_circle_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isEdit ? 'تعديل عملة' : 'إضافة عملة جديدة'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم العملة (مثال: ريال يمني)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'الرجاء إدخال الاسم' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز العملة (مثال: YER / SAR / USD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: mainNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'العملة الرئيسية (ريال)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: subNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'العملة الفرعية (فلس/سنت)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
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
                    SnackBar(content: Text(res.message.isEmpty ? 'تم التعديل بنجاح' : res.message)),
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
                    SnackBar(content: Text(res.message.isEmpty ? 'تمت إضافة العملة بنجاح' : res.message)),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
        title: const Text('العملات وأسعار الصرف'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(currenciesProvider.notifier).loadCurrencies(),
          ),
        ],
      ),
      body: currenciesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : currenciesState.error != null
              ? Center(
                  child: Text('خطأ: ${currenciesState.error}', style: const TextStyle(color: AppColors.error)),
                )
              : currenciesState.currencies.isEmpty
                  ? const Center(
                      child: Text('لا توجد عملات مضافة بعد', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currenciesState.currencies.length,
                      itemBuilder: (context, index) {
                        final currency = currenciesState.currencies[index];
                        final isRising = currency.isRising;
                        final isFalling = currency.isFalling;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 1.5,
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        currency.code ?? currency.curName.substring(0, 1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currency.curName,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          if (currency.mainCurName != null)
                                            Text(
                                              'الواحدة: ${currency.mainCurName} | الأجزاء: ${currency.subCurName ?? '-'}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                      onPressed: () => _showAddEditCurrencyDialog(currency: currency),
                                    ),
                                  ],
                                ),

                                const Divider(height: 24),

                                // سعر الصرف الحالي والتغيير
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'سعر الصرف الحالي',
                                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currency.currentPrice.toStringAsFixed(2),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isRising
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : isFalling
                                                ? AppColors.error.withValues(alpha: 0.1)
                                                : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isRising
                                                ? Icons.trending_up
                                                : isFalling
                                                    ? Icons.trending_down
                                                    : Icons.trending_flat,
                                            size: 16,
                                            color: isRising
                                                ? Colors.green
                                                : isFalling
                                                    ? AppColors.error
                                                    : Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${currency.changePercent.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isRising
                                                  ? Colors.green
                                                  : isFalling
                                                      ? AppColors.error
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () => _showRateHistorySheet(currency),
                                      icon: const Icon(Icons.history, size: 16),
                                      label: const Text('سجل أسعار الصرف'),
                                      style: OutlinedButton.styleFrom(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCurrencyDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملة جديدة'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

/// أسعار الصرف التاريخية وسجل التحديثات للعملة
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
        SnackBar(content: Text(res.message.isEmpty ? 'تم تحديث سعر الصرف بنجاح' : res.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(currencyPricesProvider(widget.currency.curNo));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سجل أسعار صرف: ${widget.currency.curName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // نموذج إضافة سعر جديد
          Card(
            color: AppColors.background,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'السعر الجديد (مثال: 530)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14),
                          const SizedBox(width: 4),
                          Text(_formatDateMonthDay(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addPrice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('حفظ السعر'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('سجل تحديثات السعر السابقة:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Expanded(
            child: pricesAsync.when(
              data: (data) {
                final list = data['data'] as List<CurrencyPriceModel>? ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('لا توجد أسعار سابقة مسجلة لهذه العملة'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = list[idx];
                    return ListTile(
                      leading: const Icon(Icons.history_toggle_off, color: AppColors.primary),
                      title: Text(
                        'السعر: ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('التاريخ: ${item.dayDate}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        onPressed: () async {
                          final repo = ref.read(currencyRepositoryProvider);
                          await repo.deletePrice(widget.currency.curNo, item.seq);
                          ref.invalidate(currencyPricesProvider(widget.currency.curNo));
                          ref.read(currenciesProvider.notifier).loadCurrencies();
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('خطأ: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
