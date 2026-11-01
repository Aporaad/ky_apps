import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/report_model.dart';
import '../providers/stock_sheet_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';

/// كشف الجرد — عدّ حيّ بلا حفظ وبلا ترحيل
/// The stocktake sheet — a live count with no persistence and no posting.
///
/// ── الشاشة تقرأ رصيد النظام من `AVVG`، وتترك «الكمية الفعلية» في ذاكرتها فقط. لا يوجد هنا
///    أي طلب كتابة، ولا يوجد زر ترحيل — بقرار المستخدم (D9 + D13).
/// ── The screen reads system quantities from AVVG and keeps the counted quantity in memory
///    only. There is no write request here and no posting button — the user's decision.
class StockSheetScreen extends ConsumerStatefulWidget {
  const StockSheetScreen({super.key});

  @override
  ConsumerState<StockSheetScreen> createState() => _StockSheetScreenState();
}

class _StockSheetScreenState extends ConsumerState<StockSheetScreen> {
  final TextEditingController _search = TextEditingController();
  final Map<String, TextEditingController> _countedControllers = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => ref.read(stockSheetProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();

    for (final controller in _countedControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockSheetProvider);
    final notifier = ref.read(stockSheetProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesStocktakePrint);
    final canExport = auth.can(Perm.storesStocktakeExport);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كشف الجرد'),
        actions: [
          IconButton(
            tooltip: 'المخازن والتاريخ',
            onPressed: () => _openFilters(context, notifier),
            icon: const Icon(Icons.tune_rounded),
          ),
          if (canPrint)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _busy ? null : () => _export(print: true),
              icon: const Icon(Icons.print_outlined),
            ),
          if (canExport)
            IconButton(
              tooltip: 'تصدير Excel',
              onPressed: _busy ? null : _exportXlsx,
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          _banner(state),
          _toolbar(state, notifier),
          Expanded(child: _body(state, notifier)),
          _totals(state),
        ],
      ),
    );
  }

  /// تنبيه ثابت: الكشف استرشادي ولا يغيّر الأرصدة
  /// A permanent note: the sheet is advisory and never changes balances.
  Widget _banner(StockSheetState state) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'كشف جرد استرشادي — لا يُرحَّل ولا يغيّر الأرصدة، والكميات الفعلية لا تُحفظ.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ),
          if (state.countedLines > 0)
            TextButton(
              onPressed: ref.read(stockSheetProvider.notifier).clearAllCounted,
              child: const Text('مسح العدّ', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _toolbar(StockSheetState state, StockSheetNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: notifier.search,
                  decoration: InputDecoration(
                    hintText: 'بحث بالصنف أو الكود...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // العدد الكلي مقابل المعروض بعد التصفية — بدونه يصير «لا سطور» غامضاً
              // Total vs shown after filtering — without it an empty list is ambiguous.
              Text(
                '${state.visibleRows.length}/${state.rows.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in StockCountFilter.values) ...[
                  ChoiceChip(
                    label: Text(
                      filter.label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: state.countFilter == filter,
                    onSelected: (_) => notifier.setCountFilter(filter),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(StockSheetState state, StockSheetNotifier notifier) {
    if (state.isLoading) {
      return const StoreLoading(message: 'جارٍ تجهيز كشف الجرد...');
    }

    if (state.error != null) {
      return StoreErrorState(message: state.error!, onRetry: notifier.load);
    }

    final rows = state.visibleRows;

    if (rows.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.fact_check_outlined,
        title: 'لا سطور',
        description: 'اختر مخزناً فيه رصيد، أو ألغِ تصفية «بفرق فقط».',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) => _row(state, notifier, rows[index]),
    );
  }

  Widget _row(StockSheetState state, StockSheetNotifier notifier, StockSheetRow row) {
    final variance = state.varianceOf(row);
    final hasVariance = state.isCounted(row) && variance != 0;

    _countedControllers.putIfAbsent(
      row.key,
      () => TextEditingController(
        text: state.isCounted(row) ? StoreFormat.qty(state.countedOf(row)) : '',
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasVariance
              ? (variance > 0 ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.itemName ?? 'صنف ${row.sanfNo}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${row.partNo ?? '—'} · ${row.storeName ?? row.storeNo}'
                      ' · ${row.uomCode ?? ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StoreTag(
                label: 'النظام ${StoreFormat.qty(row.systemQty)}',
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _countedControllers[row.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: const InputDecoration(
                    labelText: 'الفعلي',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    final value = double.tryParse(text.trim());

                    if (value == null) {
                      notifier.clearCounted(row);
                    } else {
                      notifier.setCounted(row, value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الفرق: ${StoreFormat.qty(variance)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: variance == 0
                            ? AppColors.textMuted
                            : variance > 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      'القيمة: ${StoreFormat.money(variance * row.cost)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    // سبب الفرق أهم من الفرق نفسه وقت المراجعة
                    // The reason behind a variance matters more than the number when reviewing.
                    if (state.noteOf(row).isNotEmpty)
                      Text(
                        state.noteOf(row),
                        style: const TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: AppColors.info,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ملاحظة السطر',
                visualDensity: VisualDensity.compact,
                onPressed: () => _editNote(context, notifier, row),
                icon: Icon(
                  state.noteOf(row).isEmpty
                      ? Icons.note_add_outlined
                      : Icons.sticky_note_2_rounded,
                  size: 17,
                  color: state.noteOf(row).isEmpty ? null : AppColors.info,
                ),
              ),
              if (state.isCounted(row))
                IconButton(
                  tooltip: 'مسح العدّ',
                  onPressed: () {
                    _countedControllers[row.key]?.clear();
                    notifier.clearCounted(row);
                  },
                  icon: const Icon(Icons.backspace_outlined, size: 17),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// ملاحظة السطر — نص حر يعيش في الحالة فقط
  /// The line note — free text that lives in the state only.
  Future<void> _editNote(
    BuildContext context,
    StockSheetNotifier notifier,
    StockSheetRow row,
  ) async {
    final controller = TextEditingController(text: ref.read(stockSheetProvider).noteOf(row));

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ملاحظة السطر — ${row.itemName ?? row.partNo ?? ''}',
          style: const TextStyle(fontSize: 13),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'سبب الفرق مثلا: الصندوق تالف، أو العدّ غير مكتمل',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('مسح'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;

    notifier.setNote(row, result);
  }

  Widget _totals(StockSheetState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.rows.length} سطر',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Text(
            'مُعدَّد ${state.countedLines}',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Text(
            'بفرق ${state.varianceLines}',
            style: const TextStyle(fontSize: 11, color: AppColors.warning),
          ),
          const Spacer(),
          Text(
            StoreFormat.money(state.varianceValue),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: state.varianceValue == 0
                  ? AppColors.textSecondary
                  : state.varianceValue > 0
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// اختيار المخازن وتاريخ العدّ
  /// Choose the stores and the counting date.
  Future<void> _openFilters(
    BuildContext context,
    StockSheetNotifier notifier,
  ) async {
    final reference = ref.read(storeReferenceProvider).value;
    final state = ref.read(stockSheetProvider);

    if (reference == null) return;

    var storeNos = [...state.storeNos];
    var date = state.date ?? DateTime.now();

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
                'المخازن وتاريخ العدّ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'بلا تحديد = كل المخازن',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  children: [
                    for (final store in reference.stores)
                      CheckboxListTile(
                        dense: true,
                        value: storeNos.contains(store.storeNo),
                        title: Text(
                          store.storeName,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        subtitle: store.archived
                            ? const Text(
                                'أرشيفي — لا رصيد له',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.warning,
                                ),
                              )
                            : null,
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            storeNos.add(store.storeNo);
                          } else {
                            storeNos.remove(store.storeNo);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2015),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) setState(() => date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'تاريخ العدّ',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    StoreFormat.date(date),
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  notifier.load(storeNos: storeNos, date: date);
                },
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('تحميل الكشف'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export({bool print = false}) async {
    final state = ref.read(stockSheetProvider);

    if (state.rows.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final reference = ref.read(storeReferenceProvider).value;
      final storesLabel = state.storeNos.isEmpty
          ? 'كل المخازن'
          : state.storeNos
                .map((no) => reference?.storeById(no)?.storeName ?? '$no')
                .join('، ');

      final bytes = await buildStockSheetPdf(
        letterhead: letterhead,
        rows: state.visibleRows,
        counted: state.counted,
        notes: state.notes,
        date: state.date,
        storesLabel: storesLabel,
      );

      final fileName = 'store-count-sheet-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
        await ref.read(stockSheetProvider.notifier).logExport('print');
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
        await ref.read(stockSheetProvider.notifier).logExport('export');
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
    final state = ref.read(stockSheetProvider);

    if (state.rows.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final bytes = buildStoreRowsXlsx(
        sheetName: 'جرد',
        headers: const [
          'الكود',
          'الصنف',
          'الوحدة',
          'المخزن',
          'رصيد النظام',
          'الكمية الفعلية',
          'الفرق',
          'قيمة الفرق',
          'ملاحظة السطر',
        ],
        rows: [
          for (final row in state.visibleRows)
            [
              row.partNo ?? '',
              row.itemName ?? '',
              row.uomCode ?? '',
              row.storeName ?? '',
              StoreFormat.qty(row.systemQty),
              state.isCounted(row) ? StoreFormat.qty(state.countedOf(row)) : '',
              StoreFormat.qty(state.varianceOf(row)),
              StoreFormat.money(state.varianceValueOf(row)),
              state.noteOf(row),
            ],
        ],
      );

      await StoreExporter.shareXlsx(
        bytes: bytes,
        fileName: 'store-count-sheet-${StoreExporter.stamp()}.xlsx',
        subject: 'كشف جرد مخزني',
      );

      await ref.read(stockSheetProvider.notifier).logExport('export');
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
