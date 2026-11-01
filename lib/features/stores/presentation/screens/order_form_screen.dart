import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/store_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/orders_providers.dart';
import '../providers/stores_providers.dart';
import '../widgets/order_line_editor.dart';
import '../widgets/store_ui.dart';

/// نموذج إنشاء/تعديل مستند مخزني (توريد · صرف · تحويل)
/// The create/edit form for a stock document (receive · issue · transfer).
///
/// ── المجاميع تُعرض هنا للمستخدم فقط؛ الخادم يعيد حسابها من السطور ولا يقبل رقماً من العميل.
/// ── The totals shown here are for the user; the server recomputes them from the lines and
///    never accepts an amount from the client.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, required this.kind, this.billNo});

  final StoreOrderKind kind;
  final int? billNo;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final TextEditingController _party = TextEditingController();
  final TextEditingController _detailes = TextEditingController();
  final TextEditingController _discount = TextEditingController(text: '0');

  int? _storeNo;
  int? _storeTo;
  DateTime _date = DateTime.now();
  List<OrderLineDraft> _lines = const [];

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.billNo != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) Future.microtask(_loadOrder);
  }

  @override
  void dispose() {
    _party.dispose();
    _detailes.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);

    try {
      final detail = await ref
          .read(storeOrdersRepositoryProvider)
          .fetchOrder(widget.kind, widget.billNo!);

      if (!mounted) return;

      if (detail == null) {
        setState(() {
          _loading = false;
          _error = 'المستند غير موجود';
        });

        return;
      }

      // سطور المستند تُحفظ بالأرقام فقط، فنعيد بناء نموذج مصغّر للصنف والصنف الفرعي
      // لعرضها في المحرر بدون طلب إضافي لكل سطر.
      // Saved lines carry numbers only, so a minimal item/sub model is rebuilt for the
      // editor instead of one request per line.
      final lines = detail.lines
          .map(
            (line) => OrderLineDraft(
              item: ItemModel(
                sanfNo: line.sanfNo,
                partNo: line.partNo ?? '',
                name: line.sanfName ?? 'صنف ${line.sanfNo}',
                unitName: line.unitName,
              ),
              sub: ItemSubModel(
                sanfDno: line.sanfDno,
                sanfNo: line.sanfNo,
                price: line.price,
              ),
              qty: line.qty,
              price: line.price,
            ),
          )
          .toList();

      setState(() {
        _storeNo = detail.header.storeNo;
        _storeTo = detail.header.storeTo;
        _date = detail.header.date ?? DateTime.now();
        _party.text = detail.header.partyName ?? '';
        _detailes.text = detail.header.detailes ?? '';
        _discount.text = detail.header.discount.toStringAsFixed(2);
        _lines = lines;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reference = ref.watch(storeReferenceProvider);
    final kind = widget.kind;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'تعديل ${kind.documentLabel} ${widget.billNo}-'
              : '${kind.documentLabel} جديد',
        ),
      ),
      body: reference.when(
        loading: () => const StoreLoading(),
        error: (error, _) => StoreErrorState(message: error.toString()),
        data: (refs) {
          if (_loading) return const StoreLoading();

          final usable = refs.usableStores;

          if (usable.isEmpty) {
            return const StoreEmptyState(
              icon: Icons.warehouse_outlined,
              title: 'لا مخازن فعّالة',
              description:
                  'كل المخازن المسجّلة أرشيفية، ولا تُنشأ مستندات على المخازن الأرشيفية.',
            );
          }

          _storeNo ??= usable.first.storeNo;

          final total = _lines.fold<double>(0, (sum, line) => sum + line.total);
          final discount = double.tryParse(_discount.text.trim()) ?? 0;
          final net = (total - discount).clamp(0, double.infinity).toDouble();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    _headerCard(refs, usable),
                    const SizedBox(height: 14),
                    OrderLineEditor(
                      lines: _lines,
                      storeNo: _storeNo,
                      onChanged: (lines) => setState(() => _lines = lines),
                      priceLabel:
                          kind == StoreOrderKind.transfer ? 'التكلفة' : 'السعر',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.error,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              _totalsBar(total, discount, net),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCard(StoreReference refs, List<StoreModel> usable) {
    final kind = widget.kind;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StoreSectionHeader(
            title: 'بيانات المستند',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _storeNo,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: kind.hasTargetStore ? 'من مخزن *' : 'المخزن *',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final store in usable)
                DropdownMenuItem(
                  value: store.storeNo,
                  child: Text(store.storeName),
                ),
            ],
            onChanged: (value) => setState(() {
              _storeNo = value;

              if (_storeTo == value) _storeTo = null;
            }),
          ),
          if (kind.hasTargetStore) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _storeTo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'إلى مخزن *',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                for (final store in usable)
                  if (store.storeNo != _storeNo)
                    DropdownMenuItem(
                      value: store.storeNo,
                      child: Text(store.storeName),
                    ),
              ],
              onChanged: (value) => setState(() => _storeTo = value),
            ),
          ],
          if (kind.hasParty) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _party,
              decoration: InputDecoration(
                labelText: kind == StoreOrderKind.receive
                    ? 'المورد *'
                    : 'الجهة المستلمة *',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'التاريخ',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      StoreFormat.date(_date),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _discount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'الخصم',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'البيان',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalsBar(double total, double discount, double net) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'الإجمالي ${StoreFormat.money(total)}',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Text(
                'الخصم ${StoreFormat.money(discount)}',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                'الصافي ${StoreFormat.money(net)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(total, discount),
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
                  label: const Text('حفظ المستند'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(double total, double discount) async {
    final kind = widget.kind;

    if (_storeNo == null) {
      setState(() => _error = 'المخزن مطلوب');

      return;
    }

    if (kind.hasTargetStore && _storeTo == null) {
      setState(() => _error = 'المخزن الهدف مطلوب للتحويل');

      return;
    }

    if (kind.hasParty && _party.text.trim().isEmpty) {
      setState(
        () => _error = kind == StoreOrderKind.receive
            ? 'اسم المورد مطلوب'
            : 'اسم الجهة المستلمة مطلوب',
      );

      return;
    }

    if (_lines.isEmpty) {
      setState(() => _error = 'يجب إضافة سطر واحد على الأقل');

      return;
    }

    if (_lines.any((line) => line.qty <= 0)) {
      setState(() => _error = 'كل سطر يحتاج كمية أكبر من صفر');

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'store_no': _storeNo,
      if (kind.hasTargetStore) 'store_to': _storeTo,
      'dat': StoreFormat.date(_date),
      if (kind.hasParty) 'party_name': _party.text.trim(),
      'detailes': _detailes.text.trim(),
      'discount': discount,
      'lines': [
        for (final line in _lines)
          {
            'sanf_no': line.item.sanfNo,
            'sanf_dno': line.sub.sanfDno,
            'qty': line.qty,
            'price': line.price,
          },
      ],
    };

    final repository = ref.read(storeOrdersRepositoryProvider);
    final result = _isEdit
        ? await repository.updateOrder(kind, widget.billNo!, payload)
        : await repository.createOrder(kind, payload);

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.success) {
      ref.read(ordersListProvider.notifier).load();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'تم تعديل المستند بنجاح' : 'تم حفظ المستند بنجاح',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _error = result.displayMessage);
    }
  }
}
