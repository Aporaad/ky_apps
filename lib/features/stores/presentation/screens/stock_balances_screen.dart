import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/report_model.dart';
import '../providers/reports_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';

/// أرصدة الأصناف في المخازن — من `AVVG` مباشرة
/// Item balances per store — straight from AVVG.
///
/// ── الرصيد هنا هو نفسه الذي يقرأه أمر الصرف عند التحقق من الكفاية، فلا يمكن أن تظهر
///    كمية «متاحة» في الشاشة ويُرفض الصرف بسببها.
/// ── The balance here is the same one the issue order checks against, so the screen can never
///    show a quantity the server then refuses.
class StockBalancesScreen extends ConsumerStatefulWidget {
  const StockBalancesScreen({super.key});

  @override
  ConsumerState<StockBalancesScreen> createState() => _StockBalancesScreenState();
}

class _StockBalancesScreenState extends ConsumerState<StockBalancesScreen> {
  final TextEditingController _search = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => ref.read(balancesProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(balancesProvider);
    final notifier = ref.read(balancesProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final canExport = auth.can(Perm.storesReportsExport);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('أرصدة المخازن'),
        actions: [
          if (canExport)
            PopupMenuButton<String>(
              tooltip: 'تصدير',
              onSelected: (value) => _export(value == 'print'),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'print',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.print_outlined, size: 18),
                    title: Text('طباعة'),
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.ios_share_rounded, size: 18),
                    title: Text('تصدير Excel'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _toolbar(state, notifier),
          Expanded(
            child: state.isLoading
                ? const StoreLoading()
                : state.error != null
                ? StoreErrorState(message: state.error!, onRetry: notifier.load)
                : state.rows.isEmpty
                ? const StoreEmptyState(
                    icon: Icons.inventory_outlined,
                    title: 'لا أرصدة',
                    description: 'لا توجد صفوف رصيد مطابقة للمعطيات الحالية.',
                  )
                : _table(state, notifier),
          ),
          _totals(state),
        ],
      ),
    );
  }

  Widget _toolbar(BalancesState state, BalancesNotifier notifier) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openFilters(context, notifier),
                icon: const Icon(Icons.filter_list_rounded, size: 17),
                label: const Text('تصفية'),
              ),
            ],
          ),
          if (state.filtersCount > 0) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                if (state.storeNos.isNotEmpty)
                  StoreTag(
                    label: '${state.storeNos.length} مخزن',
                    icon: Icons.warehouse_outlined,
                  ),
                if (state.only != 'all')
                  StoreTag(
                    label: state.only == 'positive' ? 'موجب فقط' : 'سالب فقط',
                    color: state.only == 'positive'
                        ? AppColors.success
                        : AppColors.error,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _table(BalancesState state, BalancesNotifier notifier) {
    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        itemCount: state.rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final row = state.rows[index];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: row.isNegative
                    ? AppColors.error.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(
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
                      const SizedBox(height: 2),
                      Text(
                        '${row.partNo ?? '—'} · ${row.storeName ?? row.storeNo}'
                        '${row.groupName != null ? ' · ${row.groupName}' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${StoreFormat.qty(row.qty)} ${row.uomCode ?? ''}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: row.isNegative
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      StoreFormat.money(row.value),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.success,
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

  Widget _totals(BalancesState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.total} سطر',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Text(
            'كمية ${StoreFormat.qty(state.totalQty)}',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          if (state.negative > 0) ...[
            const SizedBox(width: 8),
            StoreTag(
              label: '${state.negative} سالب',
              color: AppColors.error,
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFilters(
    BuildContext context,
    BalancesNotifier notifier,
  ) async {
    final reference = ref.read(storeReferenceProvider).value;
    final state = ref.read(balancesProvider);

    if (reference == null) return;

    var storeNos = [...state.storeNos];
    var only = state.only;

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
                'تصفية الأرصدة',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'المخازن (الكل عند عدم التحديد)',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              SizedBox(
                height: 180,
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
              DropdownButtonFormField<String>(
                value: only,
                decoration: const InputDecoration(
                  labelText: 'الرصيد',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'positive', child: Text('موجب فقط')),
                  DropdownMenuItem(value: 'negative', child: Text('سالب فقط')),
                ],
                onChanged: (value) => setState(() => only = value ?? 'all'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        notifier.applyFilters(storeNos: const [], only: 'all');
                      },
                      child: const Text('مسح'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        notifier.applyFilters(storeNos: storeNos, only: only);
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

  /// تصدير الأرصدة — Excel أو طباعة PDF
  /// Export balances — Excel or PDF print.
  Future<void> _export(bool print) async {
    final state = ref.read(balancesProvider);

    if (state.rows.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      if (print) {
        final letterhead = ReportLetterheadInfo.fromConfig(
          ref.read(appConfigNotifierProvider).config,
        );

        // إعادة استخدام مولّد تقرير الخلاصة: الأرصدة عرض «خلاصة» للحظة الراهنة
        // The summary report builder is reused: balances are a summary of "now".
        final bytes = await buildStoreReportPdf(
          letterhead: letterhead,
          filter: StoreReportFilter(
            kind: StoreReportKind.summary,
            from: DateTime.now(),
            to: DateTime.now(),
          ),
          movementRows: const [],
          summaryRows: [
            for (final row in state.rows)
              StockSummaryRow(
                sanfNo: row.sanfNo,
                partNo: row.partNo,
                itemName: row.itemName,
                uomCode: row.uomCode,
                storeNo: row.storeNo,
                storeName: row.storeName,
                netQty: row.qty,
                cost: row.cost,
                netValue: row.value,
              ),
          ],
          // أرصدة اللحظة لا حركة فيها: الشريط يحمل الرصيد الحالي وقيمته فقط، ولا يختلق
          // واردًا ولا منصرفًا لا وجود لهما في هذا العرض
          // Balances are "now" with nothing moved: the strip carries the closing quantity and
          // its value only, inventing no inbound or outbound that this view never showed.
          stats: ReportStats(
            rows: state.rows.length,
            closingQty: state.rows.fold<double>(0, (sum, row) => sum + row.qty),
            closingValue: state.totalValue,
          ),
          statIds: const ['closing', 'closingValue'],
        );

        await StoreExporter.print(
          bytes: bytes,
          fileName: 'store-balances-${StoreExporter.stamp()}.pdf',
        );
      } else {
        final bytes = buildStoreRowsXlsx(
          sheetName: 'الأرصدة',
          headers: const [
            'الكود',
            'الصنف',
            'الوحدة',
            'المخزن',
            'الكمية',
            'التكلفة',
            'القيمة',
          ],
          rows: [
            for (final row in state.rows)
              [
                row.partNo ?? '',
                row.itemName ?? '',
                row.uomCode ?? '',
                row.storeName ?? '',
                StoreFormat.qty(row.qty),
                StoreFormat.money(row.cost),
                StoreFormat.money(row.value),
              ],
          ],
        );

        await StoreExporter.shareXlsx(
          bytes: bytes,
          fileName: 'store-balances-${StoreExporter.stamp()}.xlsx',
          subject: 'أرصدة المخازن',
        );
      }

      await ref.read(storeReportsRepositoryProvider).logAction(
        path: '/stores/reports/export-log',
        action: print ? 'print' : 'export',
        extra: {'report': 'balances'},
      );
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
