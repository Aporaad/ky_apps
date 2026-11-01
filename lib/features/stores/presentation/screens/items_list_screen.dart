import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/items_providers.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';

/// قائمة الأصناف الرئيسية — أهم شاشة في القسم
/// The main items list — the most important screen of the module.
///
/// ── لماذا «رئيسية» ولماذا لوحة تفصيل منفصلة؟ لأن الصنف في هذا المخطط كائنان: `SANFS` الرأس
///    و`SANFS_D` الأصناف الفرعية (باركود/لون/مقاس) التي تحمل الحركة فعلياً. القائمة تعرض
///    الرؤوس؛ واختيار صنف يفتح تفصيله الفرعي وأرصدته وحركته.
/// ── Why "main" and why a separate detail screen? An item is two objects here: the SANFS
///    header and the SANFS_D sub items that actually carry movement. The list shows headers;
///    picking one opens its sub items, balances and movement.
class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  final TextEditingController _search = TextEditingController();

  /// الصنف المعروض في اللوحة الجانبية (تخطيط عريض فقط)
  /// The item shown in the side panel (wide layout only).
  int? _selectedSanfNo;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(itemsListProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(itemsListProvider);
    final notifier = ref.read(itemsListProvider.notifier);
    final reference = ref.watch(storeReferenceProvider).value;
    final canCreate = auth.can(Perm.storesItemsCreate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأصناف'),
        actions: [
          IconButton(
            tooltip: state.selectionMode ? 'إنهاء التحديد' : 'تحديد متعدد',
            onPressed: notifier.toggleSelectionMode,
            icon: Icon(
              state.selectionMode
                  ? Icons.close_rounded
                  : Icons.checklist_rounded,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'ترتيب',
            onSelected: notifier.sortBy,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'name', child: Text('بالاسم')),
              PopupMenuItem(value: 'part', child: Text('بالكود')),
              PopupMenuItem(value: 'qty', child: Text('بالكمية')),
              PopupMenuItem(value: 'value', child: Text('بالقيمة')),
            ],
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('صنف جديد'),
            )
          : null,
      body: Column(
        children: [
          _topBar(state, notifier, reference),
          if (state.selectionMode) _selectionBar(state, notifier, auth),
          Expanded(child: _splitBody(state, notifier, auth)),
        ],
      ),
    );
  }

  Widget _topBar(
    ItemsListState state,
    ItemsListNotifier notifier,
    StoreReference? reference,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              onSubmitted: notifier.search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الكود...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: state.filtersCount > 0,
            label: Text('${state.filtersCount}'),
            child: OutlinedButton.icon(
              onPressed: reference == null
                  ? null
                  : () => _openFilters(context, reference),
              icon: const Icon(Icons.filter_list_rounded, size: 17),
              label: const Text('تصفية'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionBar(
    ItemsListState state,
    ItemsListNotifier notifier,
    dynamic auth,
  ) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            'محدد: ${state.selected.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: notifier.selectAll,
            child: const Text('تحديد الكل'),
          ),
          TextButton(
            onPressed: notifier.clearSelection,
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  /// تخطيط رئيسي-تفصيلي: على الشاشات العريضة قائمة ولوحة تفصيل جنباً إلى جنب
  /// Master-detail: on wide screens the list and the detail panel sit side by side.
  ///
  /// ── لماذا؟ لأن مراجعة صنف تعني التنقل بين عشرات الرؤوس مقارنةً بفرعيها وأرصدتها؛ فتح شاشة
  ///    كاملة لكل صنف يقتل هذا التنقل. على عروض أقل من `splitBreakpoint` يُعاد النقل لشاشة تفصيل.
  /// ── Why? Reviewing items means hopping across dozens of headers to compare sub items and
  ///    balances; a full-screen push per item kills that. Below `splitBreakpoint` we push.
  Widget _splitBody(
    ItemsListState state,
    ItemsListNotifier notifier,
    dynamic auth,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // وضع التحديد المتعدد لا يقبل لوحة تفصيل: كل نقرة يجب أن تصب في التحديد
        // Multi-select mode leaves no room for a detail panel: every tap must select.
        final wide =
            constraints.maxWidth >= ItemDetailScreen.splitBreakpoint &&
            !state.selectionMode;

        if (!wide) return _body(state, notifier, auth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _body(state, notifier, auth)),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              flex: 6,
              child: _selectedSanfNo == null
                  ? const StoreEmptyState(
                      icon: Icons.touch_app_outlined,
                      title: 'اختر صنفاً',
                      description:
                          'يظهر هنا تفصيل الصنف: أصنافه الفرعية ووحداته وأرصدته وحركته.',
                    )
                  : ItemDetailScreen(
                      key: ValueKey<int>(_selectedSanfNo!),
                      sanfNo: _selectedSanfNo!,
                      embedded: true,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(
    ItemsListState state,
    ItemsListNotifier notifier,
    dynamic auth,
  ) {
    if (state.isLoading) return const StoreLoading();

    if (state.error != null) {
      return StoreErrorState(message: state.error!, onRetry: notifier.load);
    }

    if (state.items.isEmpty) {
      return StoreEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد أصناف',
        description: state.search.isEmpty
            ? 'أضف أول صنف ليظهر في المستندات والأرصدة.'
            : 'لا نتائج مطابقة للبحث أو التصفية.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = state.items[index];

                return _ItemCard(
                  item: item,
                  selectionMode: state.selectionMode,
                  selected: state.selected.contains(item.sanfNo),
                  canUpdate: ref.read(authNotifierProvider).can(Perm.storesItemsUpdate),
                  canDelete: ref.read(authNotifierProvider).can(Perm.storesItemsDelete),
                  onTap: () {
                    if (state.selectionMode) {
                      notifier.toggleSelected(item.sanfNo);

                      return;
                    }

                    _select(item);
                  },
                  onEdit: () => _openForm(context, item: item),
                  onDelete: () => _confirmDelete(context, notifier, item),
                );
              },
            ),
          ),
        ),
        _pager(state, notifier),
      ],
    );
  }

  Widget _pager(ItemsListState state, ItemsListNotifier notifier) {
    if (state.pages <= 1) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'إجمالي ${state.total} صنف',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.page > 1
                ? () => notifier.goToPage(state.page - 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text(
            'صفحة ${state.page} من ${state.pages} · ${state.total} صنف',
            style: const TextStyle(fontSize: 11.5),
          ),
          IconButton(
            onPressed: state.page < state.pages
                ? () => notifier.goToPage(state.page + 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }

  /// اختيار صنف: في التخطيط العريض يُعرض في اللوحة الجانبية، وعلى الجوال يُنقل إليه
  /// Pick an item: the side panel on wide screens, a pushed screen on phones.
  void _select(ItemModel item) {
    final wide =
        MediaQuery.sizeOf(context).width >= ItemDetailScreen.splitBreakpoint;

    if (!wide) {
      _openDetail(context, item);

      return;
    }

    setState(() => _selectedSanfNo = item.sanfNo);
  }

  Future<void> _openDetail(BuildContext context, ItemModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(sanfNo: item.sanfNo)),
    );

    if (!mounted) return;

    ref.read(itemsListProvider.notifier).refreshCurrent();
  }

  Future<void> _openForm(BuildContext context, {ItemModel? item}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)),
    );

    if (!mounted) return;

    ref.read(itemsListProvider.notifier).refreshCurrent();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemsListNotifier notifier,
    ItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف صنف'),
        content: Text(
          'سيُحذف الصنف «${item.name}» مع أصنافه الفرعية ووحداته. '
          'لا يمكن حذف صنف له حركة مخزنية — عطّله بدلاً من حذفه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await notifier.remove(item.sanfNo);

    // الحارس على `context` لا على `State.mounted`: هذا هو الشرط الذي يفحصه المحلل،
    // وهو الأصح لأن الخطر هو استخدام context بعد await.
    // Guard on context, not State.mounted: that is what the analyzer verifies and what the
    // risk actually is — a context used after an await.
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'تم حذف الصنف' : result.displayMessage),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }

  /// نافذة تصفية الأصناف: مجموعة → فرعية · فئة · وحدة · الحالة
  /// The item filter sheet: group → sub group · category · unit · status.
  Future<void> _openFilters(
    BuildContext context,
    StoreReference reference,
  ) async {
    final state = ref.read(itemsListProvider);
    var groupNo = state.groupNo;
    var typeNo = state.typeNo;
    var catNo = state.catNo;
    var unitNo = state.unitNo;
    var active = state.active;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final types = reference.typesOfGroup(groupNo);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              14,
              14,
              MediaQuery.viewInsetsOf(context).bottom + 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تصفية الأصناف',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _dropdown<int>(
                  label: 'المجموعة الرئيسية',
                  value: groupNo,
                  items: [
                    for (final group in reference.groups)
                      DropdownMenuItem(
                        value: group.groupNo,
                        child: Text(group.groupName),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    groupNo = value;
                    typeNo = null;
                  }),
                ),
                const SizedBox(height: 10),
                _dropdown<int>(
                  label: 'المجموعة الفرعية',
                  value: typeNo,
                  items: [
                    for (final type in types)
                      DropdownMenuItem(
                        value: type.typeNo,
                        child: Text(type.typeName),
                      ),
                  ],
                  onChanged: (value) => setState(() => typeNo = value),
                ),
                const SizedBox(height: 10),
                _dropdown<int>(
                  label: 'الفئة',
                  value: catNo,
                  items: [
                    for (final category in reference.categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => catNo = value),
                ),
                const SizedBox(height: 10),
                _dropdown<int>(
                  label: 'الوحدة',
                  value: unitNo,
                  items: [
                    for (final unit in reference.units)
                      DropdownMenuItem(
                        value: unit.unitNo,
                        child: Text(unit.unitName),
                      ),
                  ],
                  onChanged: (value) => setState(() => unitNo = value),
                ),
                const SizedBox(height: 10),
                _dropdown<String>(
                  label: 'الحالة',
                  value: active,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('الكل')),
                    DropdownMenuItem(value: '1', child: Text('نشط')),
                    DropdownMenuItem(value: '0', child: Text('معطّل')),
                  ],
                  onChanged: (value) => setState(() => active = value ?? 'all'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(itemsListProvider.notifier)
                              .applyFilters(
                                active: 'all',
                                clearGroup: true,
                                clearType: true,
                                clearCat: true,
                                clearUnit: true,
                              );
                        },
                        child: const Text('مسح التصفية'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(itemsListProvider.notifier)
                              .applyFilters(
                                groupNo: groupNo,
                                typeNo: typeNo,
                                catNo: catNo,
                                unitNo: unitNo,
                                active: active,
                              );
                        },
                        child: const Text('تطبيق'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

/// بطاقة صنف في القائمة
/// One item card in the list.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.canUpdate,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemModel item;
  final bool selectionMode;
  final bool selected;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.07)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 19,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الكود ${item.partNo} · رقم ${item.sanfNo}'
                          '${item.unitName != null ? ' · ${item.unitName}' : ''}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!selectionMode && (canUpdate || canDelete))
                    PopupMenuButton<String>(
                      tooltip: 'إجراءات',
                      onSelected: (value) {
                        if (value == 'view') onTap();
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.visibility_outlined, size: 18),
                            title: Text('عرض'),
                          ),
                        ),
                        if (canUpdate)
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined, size: 18),
                              title: Text('تعديل'),
                            ),
                          ),
                        if (canDelete)
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.error,
                              ),
                              title: Text(
                                'حذف',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.groupName != null)
                    StoreTag(
                      label: item.groupName!,
                      icon: Icons.folder_outlined,
                    ),
                  if (item.typeName != null)
                    StoreTag(
                      label: item.typeName!,
                      icon: Icons.subdirectory_arrow_left_rounded,
                      color: AppColors.info,
                    ),
                  if (item.categoryName != null)
                    StoreTag(
                      label: item.categoryName!,
                      icon: Icons.public_rounded,
                      color: AppColors.secondary,
                    ),
                  StoreTag(
                    label: '${item.subs} فرعي',
                    icon: Icons.qr_code_2_rounded,
                    color: AppColors.secondary,
                  ),
                  StoreTag(
                    label: StoreFormat.qty(item.qty),
                    icon: Icons.inventory_2_outlined,
                    color: item.isNegative ? AppColors.error : AppColors.success,
                  ),
                  StoreTag(
                    label: StoreFormat.money(item.value),
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                  ),
                  if (!item.active)
                    const StoreTag(
                      label: 'معطّل',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
