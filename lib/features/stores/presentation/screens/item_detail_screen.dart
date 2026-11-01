import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/store_items_repository.dart';
import '../providers/items_providers.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';
import 'item_form_screen.dart';

/// تفصيل صنف: بياناته · أصنافه الفرعية · وحداته وأسعاره · أرصدته · حركته
/// Item detail: header · sub items · units and prices · balances · movement.
///
/// ── الأصناف الفرعية ليست تفصيلاً تجميلياً: كل سطر مستند يشير إلى `SANF_DNO`، فبلا صنف فرعي
///    لا يمكن توريد الصنف ولا صرفه، ولا يظهر في أي رصيد.
/// ── Sub items are not decoration: every document line points at a SANF_DNO, so without one
///    the item cannot be received, issued, nor appear in any balance.
///
/// ── `embedded` يجعل نفس المحتوى يُركَّب داخل لوحة جنباً إلى جنب مع القائمة على الشاشات
///    العريضة (بلا Scaffold ولا شريط تطبيق مكرر)، ويبقى شاشة مستقلة على الجوال.
/// ── `embedded` mounts the same content inside the side-by-side panel on wide screens
///    (without a second Scaffold or app bar) while staying a standalone screen on phones.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({
    super.key,
    required this.sanfNo,
    this.embedded = false,
  });

  final int sanfNo;
  final bool embedded;

  /// انتقال التخطيط العريض الذي تركّب هذه اللوحة
  /// The wide layout that mounts this panel.
  static const double splitBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(itemDetailProvider(sanfNo));
    final auth = ref.watch(authNotifierProvider);
    final canUpdate = auth.can(Perm.storesItemsUpdate);
    final canCreate = auth.can(Perm.storesItemsCreate);

    final body = detail.when(
      loading: () => const StoreLoading(),
      error: (error, _) => StoreErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(itemDetailProvider(sanfNo)),
      ),
      data: (bundle) {
        if (bundle == null) {
          return const StoreEmptyState(
            icon: Icons.search_off_rounded,
            title: 'الصنف غير موجود',
          );
        }

        return DefaultTabController(
          length: 5,
          child: Column(
            children: [
              // في التخطيط الجانبي لا يوجد شريط تطبيق، فيحمل رأس اللوحة زر التعديل
              // In the side panel there is no app bar, so the panel header carries edit.
              _header(
                bundle,
                onEdit: embedded && canUpdate
                    ? () => _editItem(context, ref, bundle.item)
                    : null,
              ),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'البيانات'),
                  Tab(text: 'الأصناف الفرعية'),
                  Tab(text: 'الوحدات والأسعار'),
                  Tab(text: 'الأرصدة'),
                  Tab(text: 'الحركة'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BasicsTab(item: bundle.item),
                    _SubsTab(
                      sanfNo: sanfNo,
                      subs: bundle.subs,
                      canCreate: canCreate,
                      canUpdate: canUpdate,
                      canDelete: auth.can(Perm.storesItemsDelete),
                    ),
                    _UnitsTab(
                      sanfNo: sanfNo,
                      units: bundle.units,
                      canUpdate: canUpdate,
                      reference: ref.watch(storeReferenceProvider).value,
                    ),
                    _BalancesTab(balances: bundle.balances),
                    _MovementsTab(sanfNo: sanfNo),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          detail.value?.item.name ?? 'صنف $sanfNo',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (canUpdate && detail.value != null)
            IconButton(
              tooltip: 'تعديل الصنف',
              onPressed: () => _editItem(context, ref, detail.value!.item),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: body,
    );
  }

  /// فتح نموذج التعديل ثم تحديث اللوحة والقائمة معاً
  /// Open the edit form, then refresh the panel and the list together.
  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    ItemModel item,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );

    ref.invalidate(itemDetailProvider(sanfNo));
    ref.read(itemsListProvider.notifier).refreshCurrent();
  }

  Widget _header(ItemDetail bundle, {VoidCallback? onEdit}) {
    final item = bundle.item;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StoreTag(
                label: StoreFormat.qty(bundle.totalQty),
                icon: Icons.inventory_2_outlined,
                color: bundle.totalQty < 0 ? AppColors.error : AppColors.success,
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'تعديل الصنف',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StoreTag(label: 'كود ${item.partNo}', icon: Icons.qr_code_rounded),
              if (item.unitName != null)
                StoreTag(label: item.unitName!, icon: Icons.straighten_rounded),
              if (item.styleName != null)
                StoreTag(
                  label: item.styleName!,
                  icon: Icons.style_outlined,
                  color: AppColors.info,
                ),
              if (!item.active)
                const StoreTag(label: 'معطّل', color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

/// تبويب البيانات الأساسية
/// The basics tab.
class _BasicsTab extends StatelessWidget {
  const _BasicsTab({required this.item});

  final ItemModel item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _row('المجموعة الرئيسية', item.groupName ?? '—'),
        _row('المجموعة الفرعية', item.typeName ?? '—'),
        _row('الفئة', item.categoryName ?? '—'),
        _row('الوحدة', item.unitName ?? '—'),
        _row('النمط', item.styleName ?? '—'),
        _row('كود الصنف', item.partNo),
        _row('الرمز', item.sanfCode ?? '—'),
        _row('سعر البيع', StoreFormat.money(item.salePrice)),
        _row('سعر الشراء', StoreFormat.money(item.buyPrice)),
        _row('معامل التحويل', StoreFormat.qty(item.cap)),
        _row('اللون الأساسي', item.mainColor ?? '—'),
        _row('عدد الأصناف الفرعية', '${item.subs}'),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// تبويب الأصناف الفرعية
/// The sub items tab.
class _SubsTab extends ConsumerWidget {
  const _SubsTab({
    required this.sanfNo,
    required this.subs,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
  });

  final int sanfNo;
  final List<ItemSubModel> subs;
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (canCreate)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: OutlinedButton.icon(
              onPressed: () => _openSubDialog(context, ref, null),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('صنف فرعي جديد'),
            ),
          ),
        Expanded(
          child: subs.isEmpty
              ? const StoreEmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'لا أصناف فرعية',
                  description:
                      'بلا صنف فرعي لا يمكن توريد الصنف أو صرفه ولا يظهر في الأرصدة.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final sub = subs[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'مقاس ${sub.sizeLabel} · لون ${sub.colorNo}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'باركود ${sub.barcode ?? '—'} · ${sub.sanfDno}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!sub.active)
                            const StoreTag(label: 'معطّل', color: AppColors.warning),
                          if (canUpdate || canDelete)
                            PopupMenuButton<String>(
                              tooltip: 'إجراءات',
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _openSubDialog(context, ref, sub);
                                } else if (value == 'delete') {
                                  final result = await ref
                                      .read(storeItemsRepositoryProvider)
                                      .deleteSub(sanfNo, sub.sanfDno);

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result.success
                                            ? 'تم حذف الصنف الفرعي'
                                            : result.displayMessage,
                                      ),
                                      backgroundColor: result.success
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  );

                                  ref.invalidate(itemDetailProvider(sanfNo));
                                }
                              },
                              itemBuilder: (context) => [
                                if (canUpdate)
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('تعديل'),
                                  ),
                                if (canDelete)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('حذف'),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openSubDialog(
    BuildContext context,
    WidgetRef ref,
    ItemSubModel? sub,
  ) async {
    final barcode = TextEditingController(text: sub?.barcode ?? '');
    final len = TextEditingController(text: StoreFormat.qty(sub?.len ?? 0));
    final wid = TextEditingController(text: StoreFormat.qty(sub?.wid ?? 0));
    final color = TextEditingController(text: (sub?.colorNo ?? 0).toString());
    final price = TextEditingController(
      text: (sub?.price ?? 0).toStringAsFixed(2),
    );
    String? error;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(sub == null ? 'صنف فرعي جديد' : 'تعديل الصنف الفرعي'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: barcode,
                  decoration: const InputDecoration(
                    labelText: 'الباركود',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: len,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الطول',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: wid,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'العرض',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: color,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'رقم اللون',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        error = null;
                      });

                      final payload = <String, dynamic>{
                        'barcode': barcode.text.trim(),
                        'len': double.tryParse(len.text.trim()) ?? 0,
                        'wid': double.tryParse(wid.text.trim()) ?? 0,
                        'color_no': int.tryParse(color.text.trim()) ?? 0,
                        'price': double.tryParse(price.text.trim()) ?? 0,
                      };

                      final repository = ref.read(storeItemsRepositoryProvider);
                      final result = sub == null
                          ? await repository.createSub(sanfNo, payload)
                          : await repository.updateSub(sanfNo, sub.sanfDno, payload);

                      if (!context.mounted) return;

                      setState(() => saving = false);

                      if (result.success) {
                        ref.invalidate(itemDetailProvider(sanfNo));
                        Navigator.pop(context);
                      } else {
                        setState(() => error = result.displayMessage);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    barcode.dispose();
    len.dispose();
    wid.dispose();
    color.dispose();
    price.dispose();
  }
}

/// تبويب الوحدات والأسعار
/// The units and prices tab.
class _UnitsTab extends ConsumerWidget {
  const _UnitsTab({
    required this.sanfNo,
    required this.units,
    required this.canUpdate,
    required this.reference,
  });

  final int sanfNo;
  final List<ItemUnitModel> units;
  final bool canUpdate;
  final dynamic reference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (canUpdate && reference != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: OutlinedButton.icon(
              onPressed: () => _openUnitDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('وحدة وسعر جديد'),
            ),
          ),
        Expanded(
          child: units.isEmpty
              ? const StoreEmptyState(
                  icon: Icons.straighten_rounded,
                  title: 'لا وحدات مسجّلة',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: units.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final unit = units[index];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  unit.unitName ?? 'وحدة ${unit.unitNo}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'معامل ${StoreFormat.qty(unit.cap)} · '
                                  'السعر ${StoreFormat.money(unit.price)}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canUpdate)
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: () async {
                                final result = await ref
                                    .read(storeItemsRepositoryProvider)
                                    .deleteUnit(sanfNo, unit.cap);

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result.success
                                          ? 'تم حذف الوحدة'
                                          : result.displayMessage,
                                    ),
                                    backgroundColor: result.success
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                );

                                ref.invalidate(itemDetailProvider(sanfNo));
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openUnitDialog(BuildContext context, WidgetRef ref) async {
    final units = (reference.units as List<dynamic>);
    var unitNo = units.isNotEmpty ? units.first.unitNo as int : 1;
    final cap = TextEditingController(text: '1');
    final price = TextEditingController(text: '0');
    String? error;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('وحدة وسعر'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: unitNo,
                  decoration: const InputDecoration(
                    labelText: 'الوحدة',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final unit in units)
                      DropdownMenuItem(
                        value: unit.unitNo as int,
                        child: Text(unit.unitName as String),
                      ),
                  ],
                  onChanged: (value) => setState(() => unitNo = value ?? 1),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'معامل التحويل',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        error = null;
                      });

                      final result = await ref
                          .read(storeItemsRepositoryProvider)
                          .createUnit(sanfNo, {
                            'unit_no': unitNo,
                            'cap': double.tryParse(cap.text.trim()) ?? 0,
                            'price': double.tryParse(price.text.trim()) ?? 0,
                          });

                      if (!context.mounted) return;

                      setState(() => saving = false);

                      if (result.success) {
                        ref.invalidate(itemDetailProvider(sanfNo));
                        Navigator.pop(context);
                      } else {
                        setState(() => error = result.displayMessage);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    cap.dispose();
    price.dispose();
  }
}

/// تبويب الأرصدة
/// The balances tab.
class _BalancesTab extends StatelessWidget {
  const _BalancesTab({required this.balances});

  final List<ItemBalanceModel> balances;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.inventory_outlined,
        title: 'لا رصيد لهذا الصنف',
        description: 'لم تُسجَّل أي حركة تُنتج رصيداً في أي مخزن.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: balances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final balance = balances[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  balance.storeName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StoreTag(
                label: StoreFormat.qty(balance.qty),
                color: balance.qty < 0 ? AppColors.error : AppColors.success,
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(width: 6),
              StoreTag(label: StoreFormat.money(balance.value)),
            ],
          ),
        );
      },
    );
  }
}

/// تبويب الحركة (كارت الصنف)
/// The movement tab (the item card).
class _MovementsTab extends ConsumerWidget {
  const _MovementsTab({required this.sanfNo});

  final int sanfNo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movements = ref.watch(itemMovementsProvider(sanfNo));

    return movements.when(
      loading: () => const StoreLoading(),
      error: (error, _) => StoreErrorState(
        message: error.toString(),
        onRetry: () => ref.invalidate(itemMovementsProvider(sanfNo)),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const StoreEmptyState(
            icon: Icons.timeline_rounded,
            title: 'لا حركات',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) => _movementRow(rows[index]),
        );
      },
    );
  }

  Widget _movementRow(StockMovementRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                row.dateLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.typeName ?? 'حركة ${row.typeNo}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StoreTag(
                label: StoreFormat.qty(row.netQty),
                color: row.netQty < 0 ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'مستند ${row.docNo ?? '—'} · ${row.storeName ?? 'مخزن ${row.storeNo}'}'
            ' · ${StoreFormat.money(row.lineValue)}',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
