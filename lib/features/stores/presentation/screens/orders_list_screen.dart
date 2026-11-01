import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/order_model.dart';
import '../providers/orders_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';
import 'order_form_screen.dart';
import 'order_view_screen.dart';

/// قائمة أوامر المخازن — تُستخدم للأوامر الثلاثة بمعامل النوع
/// The inventory orders list — shared by the three kinds through one parameter.
class OrdersListScreen extends ConsumerStatefulWidget {
  const OrdersListScreen({super.key, required this.kind});

  final StoreOrderKind kind;

  @override
  ConsumerState<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends ConsumerState<OrdersListScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(ordersListProvider.notifier).bind(widget.kind),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(ordersListProvider);
    final notifier = ref.read(ordersListProvider.notifier);
    final kind = widget.kind;
    final canCreate = _can(auth, kind, 'create');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(kind.title),
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
              PopupMenuItem(value: 'date', child: Text('بالتاريخ')),
              PopupMenuItem(value: 'no', child: Text('بالرقم')),
              PopupMenuItem(value: 'net', child: Text('بالصافي')),
            ],
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_rounded),
              label: Text('${kind.documentLabel} جديد'),
            )
          : null,
      body: Column(
        children: [
          _toolbar(context, state, notifier),
          if (state.selectionMode)
            _selectionBar(context, state, notifier, auth),
          Expanded(child: _body(context, state, notifier, auth)),
        ],
      ),
    );
  }

  /// شريط التحديد المتعدد — الأجراءات الجماعية تعمل على ما اختاره المستخدم فقط
  /// The multi-select bar — bulk actions apply to what the user picked, nothing else.
  ///
  /// ── الطباعة والتصدير جماعياً يعملان على رؤوس المستندات المحددة لا على سطورها: هذا ما
  ///    يحتاجه المراجع (قائمة تشغيلية)، وفي حالة الحذف يُطلب تأكيد صريح لأن الحذف فيزيائي.
  /// ── Bulk print/export act on the selected document *headers*, which is what a reviewer
  ///    needs, and delete demands explicit confirmation because it is physical.
  Widget _selectionBar(
    BuildContext context,
    OrdersListState state,
    OrdersListNotifier notifier,
    dynamic auth,
  ) {
    final kind = state.kind;
    final selectedOrders = state.orders
        .where((order) => state.selected.contains(order.billNo))
        .toList(growable: false);
    final canDelete = _can(auth, kind, 'delete');
    final hasSelection = selectedOrders.isNotEmpty;

    return Container(
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'محدد: ${state.selected.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: notifier.selectAll,
            child: const Text('تحديد الكل', style: TextStyle(fontSize: 11.5)),
          ),
          TextButton(
            onPressed: notifier.invertSelection,
            child: const Text('عكس', style: TextStyle(fontSize: 11.5)),
          ),
          TextButton(
            onPressed: notifier.clearSelection,
            child: const Text('مسح', style: TextStyle(fontSize: 11.5)),
          ),
          IconButton(
            tooltip: 'طباعة المحدد',
            visualDensity: VisualDensity.compact,
            onPressed: hasSelection && !state.busy
                ? () => _bulkExport(context, kind, selectedOrders, print: true)
                : null,
            icon: const Icon(Icons.print_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'تصدير المحدد',
            visualDensity: VisualDensity.compact,
            onPressed: hasSelection && !state.busy
                ? () => _bulkExport(context, kind, selectedOrders)
                : null,
            icon: const Icon(Icons.ios_share_rounded, size: 19),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'حذف المحدد',
              visualDensity: VisualDensity.compact,
              onPressed: hasSelection && !state.busy
                  ? () => _confirmBulkDelete(context, notifier, selectedOrders)
                  : null,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  /// طباعة/تصدير المستندات المحددة كقائمة واحدة
  /// Print or export the selected documents as one list.
  Future<void> _bulkExport(
    BuildContext context,
    StoreOrderKind kind,
    List<StoreOrderModel> orders, {
    bool print = false,
  }) async {
    if (orders.isEmpty) return;

    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.read(appConfigNotifierProvider).config,
    );

    try {
      final bytes = await buildStoreOrderListPdf(
        letterhead: letterhead,
        kind: kind,
        orders: orders,
      );

      final fileName = 'store-${kind.code}-list-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تجهيز القائمة: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// حذف جماعي بتأكيد صريح — الحذف فيزيائي ولا يمكن التراجع عنه
  /// Bulk delete behind an explicit confirmation — physical and irreversible.
  Future<void> _confirmBulkDelete(
    BuildContext context,
    OrdersListNotifier notifier,
    List<StoreOrderModel> orders,
  ) async {
    if (orders.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستندات المحددة'),
        content: Text(
          'سيُحذف ${orders.length} مستند حذفاً نهائياً، '
          'وسيُلغى أثرها على أرصدة المخزن فوراً. لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await notifier.removeMany(
      orders.map((order) => order.billNo),
    );

    if (!context.mounted) return;

    final failed = result.failed > 0
        ? ' · فشل ${result.failed}'
        : '';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.deleted == 0
              ? result.message ?? 'لم يُحذف أي مستند'
              : 'حُذف ${result.deleted} مستند$failed',
        ),
        backgroundColor: result.deleted == 0
            ? AppColors.error
            : result.failed > 0
            ? AppColors.warning
            : AppColors.success,
      ),
    );
  }

  Widget _toolbar(
    BuildContext context,
    OrdersListState state,
    OrdersListNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: notifier.search,
              decoration: InputDecoration(
                hintText: 'بحث بالرقم أو الطرف أو البيان...',
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
              onPressed: () => _openFilters(context),
              icon: const Icon(Icons.filter_list_rounded, size: 17),
              label: const Text('تصفية'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    OrdersListState state,
    OrdersListNotifier notifier,
    dynamic auth,
  ) {
    if (state.isLoading) return const StoreLoading();

    if (state.error != null) {
      return StoreErrorState(message: state.error!, onRetry: notifier.load);
    }

    if (state.orders.isEmpty) {
      return StoreEmptyState(
        icon: widget.kind.icon,
        title: 'لا توجد ${widget.kind.title}',
        description: state.search.isEmpty && state.filtersCount == 0
            ? 'ابدأ بإنشاء أول مستند.'
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
              itemCount: state.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = state.orders[index];

                return _OrderCard(
                  order: order,
                  kind: widget.kind,
                  selectionMode: state.selectionMode,
                  selected: state.selected.contains(order.billNo),
                  canUpdate: _can(auth, widget.kind, 'update'),
                  canDelete: _can(auth, widget.kind, 'delete'),
                  onTap: () {
                    if (state.selectionMode) {
                      notifier.toggleSelected(order.billNo);

                      return;
                    }

                    _openView(context, order.billNo);
                  },
                  onEdit: () => _openForm(context, billNo: order.billNo),
                  onDelete: () => _confirmDelete(context, notifier, order),
                );
              },
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                '${state.total} مستند · صافي ${StoreFormat.money(state.totalNet)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const Spacer(),
              if (state.pages > 1) ...[
                IconButton(
                  onPressed: state.page > 1
                      ? () => notifier.goToPage(state.page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                ),
                Text(
                  '${state.page}/${state.pages}',
                  style: const TextStyle(fontSize: 11),
                ),
                IconButton(
                  onPressed: state.page < state.pages
                      ? () => notifier.goToPage(state.page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// بوابات الصلاحيات لكل نوع مستند — صريحة لا مبنية بتركيب النص
  /// Per-document-kind grants, written explicitly instead of built from strings.
  ///
  /// ── سبب الصراحة: تركيب الكود بـ`'stores.${...}_$action'` يعمل اليوم لأن أسماء الأفعال
  ///    متطابقة، لكن إن غُيّر اسم فعل في الكتالوج يوماً سيمرّ الحجب بصمت (الخادم يرفض،
  ///    والقائمة تُظهر الزر). القائمة الصريحة تجعل أي انحراف خطأً ظاهراً في التحليل.
  /// ── Why explicit? Building the code by concatenation works today only because the action
  ///    names happen to match; a future catalog rename would silently pass here while the
  ///    server refuses. An explicit table makes any drift a visible analyzer error.
  bool _can(dynamic auth, StoreOrderKind kind, String action) {
    final code = switch (kind) {
      StoreOrderKind.receive => switch (action) {
        'create' => Perm.storesReceivingCreate,
        'update' => Perm.storesReceivingUpdate,
        _ => Perm.storesReceivingDelete,
      },
      StoreOrderKind.issue => switch (action) {
        'create' => Perm.storesIssuingCreate,
        'update' => Perm.storesIssuingUpdate,
        _ => Perm.storesIssuingDelete,
      },
      StoreOrderKind.transfer => switch (action) {
        'create' => Perm.storesTransferCreate,
        'update' => Perm.storesTransferUpdate,
        _ => Perm.storesTransferDelete,
      },
    };

    return auth.can(code);
  }

  Future<void> _openView(BuildContext context, int billNo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderViewScreen(kind: widget.kind, billNo: billNo),
      ),
    );

    if (!mounted) return;

    ref.read(ordersListProvider.notifier).load(keepPage: true);
  }

  Future<void> _openForm(BuildContext context, {int? billNo}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(kind: widget.kind, billNo: billNo),
      ),
    );

    if (!mounted) return;

    ref.read(ordersListProvider.notifier).load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    OrdersListNotifier notifier,
    StoreOrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستند'),
        content: Text(
          'سيُحذف المستند رقم ${order.reference} حذفاً نهائياً، '
          'وسيُلغى أثره على أرصدة المخزن فوراً. لا يمكن التراجع.',
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

    final result = await notifier.remove(order.billNo);

    // الحارس على `context` لا على `State.mounted` — نفس قاعدة شاشة الأصناف
    // Guard on context, not State.mounted — the same rule as the items screen.
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'تم حذف المستند' : result.displayMessage),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }

  /// تصفية القائمة: مخزن · فترة
  /// List filters: store · period.
  Future<void> _openFilters(BuildContext context) async {
    final reference = ref.read(storeReferenceProvider).value;
    final state = ref.read(ordersListProvider);

    if (reference == null) return;

    int? storeNo = state.storeNo;
    DateTime? from = state.from;
    DateTime? to = state.to;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
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
                'تصفية المستندات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: storeNo,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'المخزن',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final store in reference.stores)
                    DropdownMenuItem(
                      value: store.storeNo,
                      child: Text(store.storeName),
                    ),
                ],
                onChanged: (value) => setState(() => storeNo = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context,
                      label: 'من',
                      value: from,
                      onPicked: (value) => setState(() => from = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateField(
                      context,
                      label: 'إلى',
                      value: to,
                      onPicked: (value) => setState(() => to = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(ordersListProvider.notifier)
                            .applyFilters(
                              clearStore: true,
                              clearFrom: true,
                              clearTo: true,
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
                            .read(ordersListProvider.notifier)
                            .applyFilters(storeNo: storeNo, from: from, to: to);
                      },
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );

        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value == null ? '—' : StoreFormat.date(value),
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/// بطاقة مستند في القائمة
/// One document card in the list.
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.kind,
    required this.selectionMode,
    required this.selected,
    required this.canUpdate,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final StoreOrderModel order;
  final StoreOrderKind kind;
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
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
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
                        color: selected ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      order.reference,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.dateLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    StoreFormat.money(order.net),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
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
              const SizedBox(height: 6),
              Text(
                kind.hasParty
                    ? (order.partyName ?? '—')
                    : 'إلى: ${order.storeToName ?? '—'}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StoreTag(
                    label: order.storeName ?? 'مخزن ${order.storeNo}',
                    icon: Icons.warehouse_outlined,
                  ),
                  StoreTag(
                    label: '${order.lines} سطر',
                    icon: Icons.list_alt_rounded,
                    color: AppColors.info,
                  ),
                  if (order.detailes != null)
                    StoreTag(
                      label: order.detailes!,
                      icon: Icons.notes_rounded,
                      color: AppColors.secondary,
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
