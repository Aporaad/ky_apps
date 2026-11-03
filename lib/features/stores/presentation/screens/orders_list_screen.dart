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

/// بطاقة مستند في القائمة — قالب رسمي واحد للأوامر الثلاثة
/// A document card in the list — one formal template shared by the three order kinds.
///
/// ── لماذا شبكة مُساواة لا رصّ شرائح حر؟ لأن القائمة تُقرأ عمودياً: المستخدم يقارن أرقام
///    المخازن والمبالغ سطراً بسطر. الرصّ الحر (Wrap) يجعل كل بطاقة بارتفاع مختلف فتتفكك
///    المقارنة. هنا خانات متساوية بحدود، وشريط مبالغ بثلاث خانات محاذية، وذيل تدقيق.
/// ── Why an aligned grid rather than a free-flowing chip wrap? A list is read vertically: the
///    user compares stores and figures line against line. A free wrap gives every card a
///    different height and breaks that comparison. Here: equal bordered cells, a three-cell
///    money strip, and an audit footer.
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

  /// لون التمييز لكل نوع مستند — يبقى النوع متعرَّفاً بلمحة حتى بعد التمرير السريع
  /// The kind's accent, so the document type stays recognisable at a glance.
  Color get _accent => switch (kind) {
    StoreOrderKind.receive => AppColors.success,
    StoreOrderKind.issue => AppColors.warning,
    StoreOrderKind.transfer => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          // ── IntrinsicHeight ضروري هنا: `Row` بـ`CrossAxisAlignment.stretch` داخل قائمة بارتفاع
          //    غير محدود يطلب ارتفاعاً لا نهائياً لشريط النوع، فيرمي
          //    «BoxConstraints forces an infinite height» وتملأ الشاشة خطأً أحمر.
          // ── IntrinsicHeight is required: a stretched Row inside an unbounded-height list asks
          //    for an infinite height for the kind rail, throwing "BoxConstraints forces an
          //    infinite height" and filling the screen with a red error box.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط النوع على حافة البطاقة (يظهر يميناً في RTL)
                // The kind rail on the card edge — it lands on the right under RTL.
                Container(width: 4, color: _accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _titleRow(),
                        const SizedBox(height: 8),
                        _infoRow(),
                        const SizedBox(height: 8),
                        _moneyRow(),
                        if (order.detailes != null &&
                            order.detailes!.isNotEmpty) ...[
                          const SizedBox(height: 7),
                          _noteLine(order.detailes!),
                        ],
                        const SizedBox(height: 6),
                        _auditLine(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// سطر العنوان: المربع المحدّد (إن كان وضع التحديد) + أيقونة النوع + الرقم + الإجراءات
  /// Title line: selection box, kind icon, reference, and the per-row actions.
  Widget _titleRow() {
    return Row(
      children: [
        if (selectionMode)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(kind.icon, size: 17, color: _accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${kind.documentLabel} رقم ${order.billNo}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${order.dateLabel} · ${order.reference}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // نوع الفاتورة كما في النظام المكتبي: نقد / آجل
        // The bill type as the desktop prints it: cash or credit.
        _pill(
          label: order.billTypeLabel,
          icon: order.billType == 2
              ? Icons.schedule_rounded
              : Icons.payments_outlined,
          color: order.billType == 2 ? AppColors.warning : AppColors.success,
        ),
        if (!selectionMode) _actions(),
      ],
    );
  }

  /// خانات البيانات المتساوية: المخزن · الطرف/الهدف · الأصناف والكمية
  /// Equal data cells: store · party or destination · item and quantity count.
  Widget _infoRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _cell(
              label: kind.hasTargetStore ? 'من مخزن' : 'المخزن',
              value: order.storeName ?? 'مخزن ${order.storeNo}',
              icon: Icons.warehouse_outlined,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _cell(
              label: kind.hasTargetStore
                  ? 'إلى مخزن'
                  : kind == StoreOrderKind.receive
                  ? 'المورد'
                  : 'الجهة المستلمة',
              value: order.partyLabel(kind),
              icon: kind.hasTargetStore
                  ? Icons.call_made_rounded
                  : Icons.badge_outlined,
            ),
          ),
          _vDivider(),
          Expanded(
            child: _cell(
              label: 'السطور / الكمية',
              value: '${order.lines} · ${StoreFormat.qty(order.qtySum)}',
              icon: Icons.list_alt_rounded,
            ),
          ),
        ],
      ),
    );
  }

  /// شريط المبالغ: الإجمالي · الخصم · الصافي في ثلاث خانات محاذية
  /// The money strip: total, discount and net in three aligned cells.
  Widget _moneyRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _moneyCell(
                label: 'الإجمالي',
                value: StoreFormat.money(order.total),
              ),
            ),
            _vDivider(),
            Expanded(
              child: _moneyCell(
                label: 'الخصم${order.discountRate > 0 ? ' (${StoreFormat.qty(order.discountRate)}%)' : ''}',
                value: StoreFormat.money(order.discount),
              ),
            ),
            _vDivider(),
            Expanded(
              child: _moneyCell(
                label: 'الصافي',
                value: StoreFormat.money(order.net),
                emphasis: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// البيان — سطر واحد مقصوص، لأن البطاقة ليست شاشة تفصيل
  /// The description — one clipped line; the card is not a detail screen.
  Widget _noteLine(String note) {
    return Row(
      children: [
        const Icon(Icons.notes_rounded, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            note,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// ذيل التدقيق: من أدخل المستند ومتى، ومن عدّله آخر مرة إن وُجد
  /// Audit footer: who entered the document and when, plus the last edit when there is one.
  Widget _auditLine() {
    final editor = order.lastUpdatedByName;

    return Row(
      children: [
        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            editor == null
                ? 'أدخلة: ${order.createdByName ?? '—'} · ${order.createdStamp}'
                : 'أدخلة: ${order.createdByName ?? '—'} · عُدّل بواسطة $editor',
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// إجراءات ظاهرة بجانب كل أمر (عرض · تعديل · حذف) بدل قائمة مخفية
  /// Actions visible beside every document (view · edit · delete), not hidden in a menu.
  Widget _actions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'عرض',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          onPressed: onTap,
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        if (canUpdate)
          IconButton(
            tooltip: 'تعديل',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        if (canDelete)
          IconButton(
            tooltip: 'حذف',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }

  Widget _cell({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _moneyCell({
    required String label,
    required String value,
    bool emphasis = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasis ? 12.5 : 11.5,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
              color: emphasis ? AppColors.primary : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 2), color: AppColors.border);
}
