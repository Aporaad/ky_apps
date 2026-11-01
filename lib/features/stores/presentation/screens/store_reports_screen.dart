import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/items_providers.dart';
import '../providers/reports_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';

/// تقارير المخازن — عرض حركة أو خلاصة بمعطيات تُختار في نافذة منبثقة
/// The stores reports — a movement view or a summary whose parameters are chosen in a sheet.
///
/// ── النافذة تُفتح تلقائياً عند الدخول: التقرير بلا مدى زمني وبلا مخزن يمسح الـ VIEW كاملة
///    ويُنتج آلاف السطور التي لا يقرأها أحد. الفتح التلقائي يجعل التحديد خطوة لا خياراً.
/// ── The sheet opens automatically on entry: an unbounded, store-less report scans the whole
///    view and returns thousands of rows nobody reads. Auto-opening makes the selection a step,
///   not an option.
class StoreReportsScreen extends ConsumerStatefulWidget {
  const StoreReportsScreen({super.key});

  @override
  ConsumerState<StoreReportsScreen> createState() => _StoreReportsScreenState();
}

class _StoreReportsScreenState extends ConsumerState<StoreReportsScreen> {
  bool _busy = false;
  bool _autoOpened = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _openFilter());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeReportProvider);
    final notifier = ref.read(storeReportProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesReportsPrint);
    final canExport = auth.can(Perm.storesReportsExport);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقارير المخازن'),
        actions: [
          IconButton(
            tooltip: 'معطيات التقرير',
            onPressed: _openFilter,
            icon: const Icon(Icons.tune_rounded),
          ),
          if (canPrint)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _busy ? null : () => _export(print: true),
              icon: const Icon(Icons.print_outlined),
            ),
          if (canExport)
            PopupMenuButton<String>(
              tooltip: 'تصدير',
              onSelected: (value) async {
                if (value == 'pdf') await _export();
                if (value == 'xlsx') await _exportXlsx();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('مشاركة PDF')),
                PopupMenuItem(value: 'xlsx', child: Text('مشاركة Excel')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _summaryBar(state),
          Expanded(child: _body(state, notifier)),
          _totalsBar(state),
        ],
      ),
    );
  }

  Widget _summaryBar(StoreReportState state) {
    final filter = state.filter;
    final reference = ref.watch(storeReferenceProvider).value;

    if (filter == null) {
      return Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Text(
          'لم تُحدَّد معطيات بعد — اضغط «معطيات التقرير»',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
      );
    }

    final storeLabel = filter.storeNos.isEmpty
        ? 'كل المخازن'
        : filter.storeNos
              .map((no) => reference?.storeById(no)?.storeName ?? '$no')
              .join('، ');

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StoreTag(
            label: filter.kind.label,
            icon: filter.kind == StoreReportKind.movement
                ? Icons.timeline_rounded
                : Icons.summarize_rounded,
            color: AppColors.primary,
          ),
          StoreTag(
            label: '${filter.fromText} ← ${filter.toText}',
            icon: Icons.date_range_rounded,
          ),
          StoreTag(label: storeLabel, icon: Icons.warehouse_outlined),
          if (state.truncated)
            const StoreTag(
              label: 'النتائج مقتطعة — ضيّق المدى',
              color: AppColors.warning,
              icon: Icons.warning_amber_rounded,
            ),
        ],
      ),
    );
  }

  Widget _body(StoreReportState state, StoreReportNotifier notifier) {
    if (state.filter == null) {
      return StoreEmptyState(
        icon: Icons.tune_rounded,
        title: 'حدّد معطيات التقرير',
        description:
            'نوع التقرير والفترة والمخازن والمجموعات والفئات والأصناف وأنواع الحركة.',
        actionLabel: 'معطيات التقرير',
        onAction: _openFilter,
      );
    }

    if (state.isLoading) return const StoreLoading(message: 'جارٍ تجهيز التقرير...');

    if (state.error != null) {
      return StoreErrorState(
        message: state.error!,
        onRetry: () => notifier.run(state.filter!),
      );
    }

    if (state.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا نتائج',
        description: 'لا حركة مطابقة للمعطيات المحددة في هذه الفترة.',
      );
    }

    return ReportZoomView(
      child: state.kind == StoreReportKind.movement
          ? _movementList(state.movementRows)
          : _summaryList(state.summaryRows),
    );
  }

  Widget _movementList(List<StockMovementRow> rows) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        final row = rows[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.itemName ?? 'صنف ${row.sanfNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${row.dateLabel} · مستند ${row.docNo ?? '—'}'
                      ' · ${row.typeName ?? '—'} · ${row.storeName ?? ''}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  row.qtyIn == 0 ? '—' : StoreFormat.qty(row.qtyIn),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  row.qtyOut == 0 ? '—' : StoreFormat.qty(row.qtyOut),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Text(
                  StoreFormat.money(row.lineValue),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryList(List<StockSummaryRow> rows) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        final row = rows[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.itemName ?? 'صنف ${row.sanfNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${row.partNo ?? '—'} · ${row.storeName ?? row.storeNo}'
                      ' · ${row.uomCode ?? ''}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  StoreFormat.qty(row.qtyIn),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.success),
                ),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  StoreFormat.qty(row.qtyOut),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
              SizedBox(
                width: 65,
                child: Text(
                  StoreFormat.qty(row.netQty),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                child: Text(
                  StoreFormat.money(row.netValue),
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _totalsBar(StoreReportState state) {
    if (!state.hasRun || state.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.kind == StoreReportKind.movement ? state.movementRows.length : state.summaryRows.length} سطر',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Text(
            'وارد ${StoreFormat.qty(state.totalIn)}',
            style: const TextStyle(fontSize: 11, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Text(
            'صادر ${StoreFormat.qty(state.totalOut)}',
            style: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
          const Spacer(),
          Text(
            StoreFormat.money(state.totalValue),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// النافذة المنبثقة لمعطيات التقرير
  /// The report parameters sheet.
  Future<void> _openFilter() async {
    if (_autoOpened) {
      // لا نعيد الفتح تلقائياً بعد أول مرة، لكن الزر يفتحها دائماً
      // Auto-open happens once; the button always opens it.
    }
    _autoOpened = true;

    final reference = ref.read(storeReferenceProvider).value;

    if (reference == null) return;

    final current =
        ref.read(storeReportProvider).filter ??
        StoreReportFilter(
          from: DateTime.now().subtract(const Duration(days: 30)),
          to: DateTime.now(),
        );

    final result = await showModalBottomSheet<StoreReportFilter>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportFilterSheet(initial: current, reference: reference),
    );

    if (result == null) return;

    await ref.read(storeReportProvider.notifier).run(result);
  }

  Future<void> _export({bool print = false}) async {
    final state = ref.read(storeReportProvider);

    if (state.filter == null || _busy) return;

    if (state.movementRows.isEmpty && state.summaryRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا نتائج للتصدير')),
      );

      return;
    }

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: state.filter!,
        movementRows: state.movementRows,
        summaryRows: state.summaryRows,
        totalIn: state.totalIn,
        totalOut: state.totalOut,
        totalValue: state.totalValue,
      );

      final fileName =
          'store-report-${state.filter!.kind.code}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
        await ref.read(storeReportProvider.notifier).logExport('print');
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
        await ref.read(storeReportProvider.notifier).logExport('export');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر التصدير: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportXlsx() async {
    final state = ref.read(storeReportProvider);

    if (state.filter == null || _busy) return;

    setState(() => _busy = true);

    try {
      final isMovement = state.kind == StoreReportKind.movement;

      final bytes = buildStoreRowsXlsx(
        sheetName: isMovement ? 'حركة' : 'خلاصة',
        headers: isMovement
            ? const [
                'التاريخ',
                'المستند',
                'نوع الحركة',
                'المخزن',
                'الكود',
                'الصنف',
                'الوحدة',
                'وارد',
                'صادر',
                'القيمة',
              ]
            : const [
                'الكود',
                'الصنف',
                'الوحدة',
                'المخزن',
                'وارد',
                'صادر',
                'الصافي',
                'القيمة',
              ],
        rows: isMovement
            ? [
                for (final row in state.movementRows)
                  [
                    row.dateLabel,
                    row.docNo?.toString() ?? '',
                    row.typeName ?? '',
                    row.storeName ?? '',
                    row.partNo ?? '',
                    row.itemName ?? '',
                    row.uomCode ?? '',
                    StoreFormat.qty(row.qtyIn),
                    StoreFormat.qty(row.qtyOut),
                    StoreFormat.money(row.lineValue),
                  ],
              ]
            : [
                for (final row in state.summaryRows)
                  [
                    row.partNo ?? '',
                    row.itemName ?? '',
                    row.uomCode ?? '',
                    row.storeName ?? '',
                    StoreFormat.qty(row.qtyIn),
                    StoreFormat.qty(row.qtyOut),
                    StoreFormat.qty(row.netQty),
                    StoreFormat.money(row.netValue),
                  ],
              ],
      );

      await StoreExporter.shareXlsx(
        bytes: bytes,
        fileName: 'store-report-${StoreExporter.stamp()}.xlsx',
        subject: 'تقرير مخازن — ${state.filter!.kind.label}',
      );

      await ref.read(storeReportProvider.notifier).logExport('export');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر التصدير: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// نافذة معطيات التقرير — كل المعطيات في مكان واحد
/// The report parameters sheet — every filter in one place.
class _ReportFilterSheet extends ConsumerStatefulWidget {
  const _ReportFilterSheet({required this.initial, required this.reference});

  final StoreReportFilter initial;
  final StoreReference reference;

  @override
  ConsumerState<_ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends ConsumerState<_ReportFilterSheet> {
  late StoreReportKind _kind = widget.initial.kind;
  late DateTime _from = widget.initial.from;
  late DateTime _to = widget.initial.to;
  late List<int> _storeNos = [...widget.initial.storeNos];
  late int? _groupNo = widget.initial.groupNo;
  late int? _typeNo = widget.initial.typeNo;
  late int? _catNo = widget.initial.catNo;
  late int? _sanfNo = widget.initial.sanfNo;
  late List<int> _movementTypeNos = [...widget.initial.movementTypeNos];
  String? _sanfName;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    final types = reference.typesOfGroup(_groupNo);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        14,
        14,
        MediaQuery.viewInsetsOf(context).bottom + 14,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'معطيات التقرير',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // نوع التقرير
            SegmentedButton<StoreReportKind>(
              segments: const [
                ButtonSegment(
                  value: StoreReportKind.movement,
                  label: Text('عرض حركة'),
                  icon: Icon(Icons.timeline_rounded, size: 16),
                ),
                ButtonSegment(
                  value: StoreReportKind.summary,
                  label: Text('خلاصة'),
                  icon: Icon(Icons.summarize_rounded, size: 16),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (value) => setState(() => _kind = value.first),
            ),
            const SizedBox(height: 12),

            // التاريخ من - إلى
            Row(
              children: [
                Expanded(
                  child: _dateField('من', _from, (value) => _from = value),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateField('إلى', _to, (value) => _to = value),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // المخازن: الكل أو تحديد متعدد
            Row(
              children: [
                const Text(
                  'المخازن',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _storeNos = []),
                  child: const Text('الكل'),
                ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final store in reference.stores)
                  FilterChip(
                    label: Text(
                      store.storeName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _storeNos.contains(store.storeNo),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _storeNos = [..._storeNos, store.storeNo];
                      } else {
                        _storeNos = _storeNos
                            .where((no) => no != store.storeNo)
                            .toList();
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // المجموعة الرئيسية → الفرعية
            _dropdown<int>(
              label: 'المجموعة الرئيسية',
              value: _groupNo,
              items: [
                for (final group in reference.groups)
                  DropdownMenuItem(
                    value: group.groupNo,
                    child: Text(group.groupName),
                  ),
              ],
              onChanged: (value) => setState(() {
                _groupNo = value;
                _typeNo = null;
              }),
            ),
            const SizedBox(height: 10),
            _dropdown<int>(
              label: 'المجموعة الفرعية',
              value: _typeNo,
              items: [
                for (final type in types)
                  DropdownMenuItem(
                    value: type.typeNo,
                    child: Text(type.typeName),
                  ),
              ],
              onChanged: (value) => setState(() => _typeNo = value),
            ),
            const SizedBox(height: 10),
            _dropdown<int>(
              label: 'الفئة',
              value: _catNo,
              items: [
                for (final category in reference.categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) => setState(() => _catNo = value),
            ),
            const SizedBox(height: 12),

            // الصنف الرئيسي ثم الفرعي
            OutlinedButton.icon(
              onPressed: _pickItem,
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text(
                _sanfNo == null
                    ? 'تحديد الصنف الرئيسي (اختياري)'
                    : 'الصنف: ${_sanfName ?? _sanfNo}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_sanfNo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _sanfNo = null;
                    _sanfName = null;
                  }),
                  child: const Text('مسح الصنف'),
                ),
              ),
            const SizedBox(height: 12),

            // نوع الحركة: يظهر في «عرض حركة» فقط
            if (_kind == StoreReportKind.movement) ...[
              const Text(
                'نوع الحركة (متعدد)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final type in reference.movementTypes)
                    FilterChip(
                      label: Text(
                        type.typeName,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _movementTypeNos.contains(type.typeNo),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _movementTypeNos = [
                            ..._movementTypeNos,
                            type.typeNo,
                          ];
                        } else {
                          _movementTypeNos = _movementTypeNos
                              .where((no) => no != type.typeNo)
                              .toList();
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'بلا تحديد = كل أنواع الحركة',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'الخلاصة تجمع كل أنواع الحركة بطبيعتها، فتصفية النوع تُلغى هنا.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(fontSize: 11.5, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('عرض التقرير'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime value,
    void Function(DateTime value) onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );

        if (picked != null) setState(() => onPicked(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          StoreFormat.date(value),
          style: const TextStyle(fontSize: 12.5),
        ),
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

  Future<void> _pickItem() async {
    final picked = await showModalBottomSheet<ItemModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ItemPickerSheet(),
    );

    if (picked == null) return;

    setState(() {
      _sanfNo = picked.sanfNo;
      _sanfName = picked.name;
    });
  }

  void _submit() {
    if (_from.isAfter(_to)) {
      setState(() => _error = 'تاريخ البداية بعد تاريخ النهاية');

      return;
    }

    final days = _to.difference(_from).inDays;

    if (days > widget.reference.maxRangeDays) {
      setState(
        () => _error =
            'المدى أكبر من الحد المسموح (${widget.reference.maxRangeDays} يوماً)',
      );

      return;
    }

    Navigator.pop(
      context,
      StoreReportFilter(
        kind: _kind,
        from: _from,
        to: _to,
        storeNos: _storeNos,
        groupNo: _groupNo,
        typeNo: _typeNo,
        catNo: _catNo,
        sanfNo: _sanfNo,
        movementTypeNos: _kind == StoreReportKind.movement
            ? _movementTypeNos
            : const [],
      ),
    );
  }
}

/// منتقي صنف للتصفية
/// An item picker for the filter.
class _ItemPickerSheet extends ConsumerStatefulWidget {
  const _ItemPickerSheet();

  @override
  ConsumerState<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends ConsumerState<_ItemPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<ItemModel> _items = const [];
  bool _loading = true;

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
          .fetchItems(search: search, limit: 80);

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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onSubmitted: _load,
              decoration: InputDecoration(
                hintText: 'بحث عن صنف...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const StoreLoading()
                : _items.isEmpty
                ? const StoreEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا نتائج',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        subtitle: Text(
                          '${item.partNo} · ${item.unitName ?? ''}',
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        onTap: () => Navigator.pop(context, item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
