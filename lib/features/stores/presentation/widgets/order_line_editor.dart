import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../providers/items_providers.dart';
import 'store_ui.dart';

/// سطر مسودة في نموذج المستند — قبل الحفظ
/// A draft line inside the document form — before saving.
class OrderLineDraft {
  OrderLineDraft({
    required this.item,
    required this.sub,
    required this.qty,
    required this.price,
    this.available,
    this.unitName,
    this.subPartNo,
    this.category,
    this.colorName,
    this.cap = 1,
    this.shelfNo = 0,
    this.colorNo = 0,
  });

  final ItemModel item;
  final ItemSubModel sub;
  double qty;
  double price;

  /// الوحدة والتصنيف واللون: خانات يطبعها المستند، وبعضها قابل للتحرير كما في النظام المكتبي
  /// Unit, classification and colour are document boxes; some of them are editable there.
  final String? unitName;
  final String? subPartNo;
  String? category;
  final String? colorName;

  /// المتاح في المخزن المختار لحظة الإضافة — للتحقق الفوري
  /// The available quantity in the chosen store at insert time, for instant validation.
  double? available;

  /// عبوة (كمية القطع في العبوة) — منها تُحسب القطعة
  /// Pack size, from which the piece count is derived.
  double cap;
  int shelfNo;
  int colorNo;

  double get total => qty * price;

  /// قطعة = الكمية × العبوة، وهو ما يظهر في عمود «قطعة» بالمستند
  /// Pieces = quantity × pack, the document's «قطعة» column.
  double get pcs => qty * cap;

  String get sizeLabel => sub.sizeLabel;

  String get unitLabel => unitName ?? item.unitName ?? '—';

  String get key => '${item.sanfNo}|${sub.sanfDno}';
}

/// محرر سطور المستند: إضافة سطر عبر منتقي صنف → صنف فرعي، وتعديل الكمية والسعر
/// The document line editor: add a line through an item → sub item picker, then edit
/// quantity and price.
///
/// ── لماذا الإضافة تمرّ بصنف فرعي إجبارياً؟ لأن الخادم والـ VIEW يرفضان أي سطر بلا
///    `SANF_DNO` — والأسوأ أنه كان سيُحفظ بلا أثر على الرصيد. فالمنتقي لا يسمح بتخطّيها.
/// ── Why force a sub item? Both the server and the view reject a line without SANF_DNO —
///    and worse, it would otherwise save with no effect on stock. The picker never skips it.
class OrderLineEditor extends ConsumerWidget {
  const OrderLineEditor({
    super.key,
    required this.lines,
    required this.storeNo,
    required this.onChanged,
    this.priceLabel = 'السعر',
  });

  final List<OrderLineDraft> lines;
  final int? storeNo;
  final ValueChanged<List<OrderLineDraft>> onChanged;
  final String priceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // العنوان يحمل Expanded داخله، فلا يجوز وضعه في Row بلا Expanded وإلا صار
            // عرضُه غير محدود؛ التعليف هنا يمنع انفجار التخطيط على أي شاشة.
            // The header contains its own Expanded, so it needs a bounded width inside a Row;
            // wrapping it here is what keeps the layout from throwing on any screen.
            const Expanded(
              child: StoreSectionHeader(
                title: 'الأصناف',
                icon: Icons.list_alt_rounded,
              ),
            ),
            TextButton.icon(
              onPressed: storeNo == null
                  ? null
                  : () => _addLine(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('إضافة سطر'),
            ),
          ],
        ),
        if (lines.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.playlist_add_rounded,
                  size: 26,
                  color: AppColors.textMuted,
                ),
                SizedBox(height: 6),
                Text(
                  'لا سطور بعد — ابدأ بإضافة صنف',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < lines.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _LineCard(
                line: lines[index],
                priceLabel: priceLabel,
                onQtyChanged: (value) => _mutate(index, (line) => line.qty = value),
                onPriceChanged: (value) =>
                    _mutate(index, (line) => line.price = value),
                // العبوة تتغيّر يدوياً كما في خانتها في النموذج المكتبي، والقطعة تُشتق منها
                // Pack is edited by hand exactly as the desktop box allows; pieces derive from it.
                onCapChanged: (value) => _mutate(
                  index,
                  (line) => line.cap = value > 0 ? value : 1,
                ),
                onRemove: () {
                  final updated = [...lines]..removeAt(index);
                  onChanged(updated);
                },
              ),
            ),
      ],
    );
  }

  void _mutate(int index, void Function(OrderLineDraft line) change) {
    final updated = [...lines];
    change(updated[index]);
    onChanged(updated);
  }

  Future<void> _addLine(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<_PickedLine>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(storeNo: storeNo!),
    );

    if (picked == null) return;

    // منع تكرار السطر نفسه: نفس الصنف الفرعي في مستند واحد يجعل الرصيد محسوباً مرتين
    // في التصور الذهني للمستخدم. نزيد الكمية بدلاً من إضافة سطر ثانٍ.
    // No duplicate lines: the same sub item twice in one document double-counts in the
    // user's mind; its quantity is increased instead.
    final existing = lines.indexWhere((line) => line.key == picked.key);

    if (existing >= 0) {
      final updated = [...lines];
      updated[existing].qty += picked.qty;
      onChanged(updated);

      return;
    }

    onChanged([
      ...lines,
      OrderLineDraft(
        item: picked.item,
        sub: picked.sub,
        qty: picked.qty,
        price: picked.price,
        available: picked.available,
        // العبوة الافتراضية من الصنف نفسه: 1 إن لم يُسجّل، فلا يبقى عمود «عبوة» فارغاً
        // The pack size defaults to the item's own, or 1, so the pack column is never blank.
        cap: picked.sub.cap > 0 ? picked.sub.cap : 1,
        unitName: picked.item.unitName,
        subPartNo: picked.sub.partNo,
        colorNo: picked.sub.colorNo,
        category: picked.sub.category,
        colorName: picked.sub.colorName,
      ),
    ]);
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.line,
    required this.priceLabel,
    required this.onQtyChanged,
    required this.onPriceChanged,
    required this.onCapChanged,
    required this.onRemove,
  });

  final OrderLineDraft line;
  final String priceLabel;
  final ValueChanged<double> onQtyChanged;
  final ValueChanged<double> onPriceChanged;
  final ValueChanged<double> onCapChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final shortage = line.available != null && line.qty > line.available!;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: shortage ? AppColors.error : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  // اسم الصنف الفرعي أولاً: هو ما يطبعه المستند، والرئيسي يُذكر تحته بالكود
                  // The sub-item name first: that is what the document prints; the main item
                  // is identified by its code beneath.
                  line.sub.name ?? line.item.name,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: AppColors.error,
                ),
                tooltip: 'حذف السطر',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          _attributeStrip(line),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _number(
                  label: 'الكمية',
                  value: line.qty,
                  onChanged: onQtyChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _number(
                  label: priceLabel,
                  value: line.price,
                  onChanged: onPriceChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _number(
                  label: 'عبوة',
                  value: line.cap,
                  onChanged: onCapChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'الإجمالي / قطعة',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${StoreFormat.money(line.total)} · ${StoreFormat.qty(line.pcs)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (line.available != null) ...[
            const SizedBox(height: 6),
            Text(
              shortage
                  ? 'الكمية أكبر من المتاح (${StoreFormat.qty(line.available!)})'
                  : 'المتاح في المخزن: ${StoreFormat.qty(line.available!)}',
              style: TextStyle(
                fontSize: 10,
                color: shortage ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// شريط خواص الصنف الفرعي — نفس أعمدة جدول النظام: الوحدة · طول · عرض · التصنيف · اللون · الرف
  /// The sub-item attribute strip — the legacy grid's own columns, shelf included.
  ///
  /// يُعرض ولا يُحرَّر إلا حيث يحرره النظام: الرف والتصنيف قابلان للتعديل هنا لأن المستند
  /// يخزّنهما في السطر نفسه، فتركهما للقراءة فقط يعني أن المستخدم لا يستطيع تصحيحهما.
  /// Only what the desktop lets you edit here is editable: shelf and classification live on the
  /// line itself, so locking them would leave the user unable to correct a document.
  static Widget _attributeStrip(OrderLineDraft line) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          _chip('الوحدة', line.unitLabel),
          _chip('طول', StoreFormat.qty(line.sub.len)),
          _chip('عرض', StoreFormat.qty(line.sub.wid)),
          _chip('الفرعي', line.subPartNo ?? '${line.sub.sanfDno}'),
          _chip('اللون', line.colorName ?? '${line.colorNo}'),
        ],
      ),
    );
  }

  static Widget _chip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _number({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return TextFormField(
      initialValue: StoreFormat.qty(value),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 12.5),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      onChanged: (text) => onChanged(double.tryParse(text.trim()) ?? 0),
    );
  }
}

class _PickedLine {
  const _PickedLine({
    required this.item,
    required this.sub,
    required this.qty,
    required this.price,
    this.available,
  });

  final ItemModel item;
  final ItemSubModel sub;
  final double qty;
  final double price;
  final double? available;

  String get key => '${item.sanfNo}|${sub.sanfDno}';
}

/// منتقي الصنف ثم الصنف الفرعي
/// The item → sub item picker.
class _ItemPickerSheet extends ConsumerStatefulWidget {
  const _ItemPickerSheet({required this.storeNo});

  final int storeNo;

  @override
  ConsumerState<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends ConsumerState<_ItemPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<ItemModel> _items = const [];
  bool _loading = true;
  ItemModel? _selected;

  @override
  void initState() {
    super.initState();

    Future.microtask(_load);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([String search = '']) async {
    setState(() => _loading = true);

    try {
      final page = await ref
          .read(storeItemsRepositoryProvider)
          .fetchItems(search: search, limit: 60);

      if (!mounted) return;

      setState(() {
        _items = page.items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selected == null
                          ? 'اختر الصنف'
                          : 'اختر الصنف الفرعي — ${_selected!.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selected != null)
                    TextButton(
                      onPressed: () => setState(() => _selected = null),
                      child: const Text('رجوع'),
                    ),
                ],
              ),
            ),
            if (_selected == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _search,
                  onSubmitted: _load,
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الكود...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const StoreLoading()
                  : _selected == null
                  ? _itemList()
                  : _SubPicker(
                      item: _selected!,
                      storeNo: widget.storeNo,
                      onPick: (sub, qty, price, available) => Navigator.pop(
                        context,
                        _PickedLine(
                          item: _selected!,
                          sub: sub,
                          qty: qty,
                          price: price,
                          available: available,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemList() {
    if (_items.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا نتائج',
        description: 'جرّب كوداً أو اسماً آخر.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name, style: const TextStyle(fontSize: 12.5)),
          subtitle: Text(
            '${item.partNo} · ${StoreFormat.qty(item.qty)}',
            style: const TextStyle(fontSize: 10.5),
          ),
          trailing: const Icon(Icons.chevron_left_rounded, size: 18),
          onTap: () => setState(() => _selected = item),
        );
      },
    );
  }
}

/// قائمة الأصناف الفرعية مع الكمية المتاحة في المخزن
/// The sub item list with the quantity available in the store.
class _SubPicker extends ConsumerStatefulWidget {
  const _SubPicker({
    required this.item,
    required this.storeNo,
    required this.onPick,
  });

  final ItemModel item;
  final int storeNo;
  final void Function(ItemSubModel sub, double qty, double price, double? available)
  onPick;

  @override
  ConsumerState<_SubPicker> createState() => _SubPickerState();
}

class _SubPickerState extends ConsumerState<_SubPicker> {
  final Map<int, TextEditingController> _qty = {};
  final Map<int, TextEditingController> _price = {};
  bool _loading = true;
  List<ItemSubModel> _subs = const [];

  @override
  void initState() {
    super.initState();

    Future.microtask(_load);
  }

  @override
  void dispose() {
    for (final controller in _qty.values) {
      controller.dispose();
    }
    for (final controller in _price.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await ref
        .read(storeItemsRepositoryProvider)
        .fetchItem(widget.item.sanfNo);

    if (!mounted) return;

    setState(() {
      _subs = detail?.subs.where((sub) => sub.active).toList(growable: false) ??
          const [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const StoreLoading();

    if (_subs.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.qr_code_2_rounded,
        title: 'لا أصناف فرعية',
        description:
            'هذا الصنف بلا صنف فرعي، فلا يمكن إضافته إلى مستند. أضف صنفاً فرعياً أولاً.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      itemCount: _subs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final sub = _subs[index];
        _qty.putIfAbsent(sub.sanfDno, () => TextEditingController(text: '1'));
        _price.putIfAbsent(
          sub.sanfDno,
          () => TextEditingController(
            text: (sub.price > 0 ? sub.price : widget.item.salePrice)
                .toStringAsFixed(2),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'مقاس ${sub.sizeLabel} · لون ${sub.colorNo}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    sub.barcode ?? '—',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qty[sub.sanfDno],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الكمية',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _price[sub.sanfDno],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'السعر',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      final qty = double.tryParse(
                        _qty[sub.sanfDno]!.text.trim(),
                      ) ?? 0;
                      final price = double.tryParse(
                        _price[sub.sanfDno]!.text.trim(),
                      ) ?? 0;

                      if (qty <= 0) return;

                      widget.onPick(sub, qty, price, null);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
