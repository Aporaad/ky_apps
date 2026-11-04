import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/store_result.dart';
import '../providers/items_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';

/// كشف حركة صنف — الصنف الرئيسي بكامل فروعه أو فرع واحد
/// An item movement statement — the main item with all branches, or one branch.
///
/// ── لماذا شاشة مستقلة وليس تبويباً داخل تفصيل الصنف؟ لأن الكشف يُطبع ويُصدَّر ويُقارَن
///    بفترتين، وهذا عمل مراجعة لا تصفّح. التبويب كان يخفي الطباعة والمدى الزمني.
/// ── Why a separate screen instead of a tab inside the item detail? A statement is printed,
///    exported and compared across periods — that is review work, not browsing. A tab hid the
///    date range and the print action.
class ItemMovementScreen extends ConsumerStatefulWidget {
  const ItemMovementScreen({
    super.key,
    required this.sanfNo,
    required this.itemName,
    this.subDno,
    this.subLabel,
  });

  final int sanfNo;
  final String itemName;

  /// فرع محدد: أيقونة كشف الحركة بجانب الصنف الفرعي تفتح فرعه هو فقط
  /// A specific branch: the statement icon beside a sub item opens only that branch.
  final int? subDno;
  final String? subLabel;

  @override
  ConsumerState<ItemMovementScreen> createState() => _ItemMovementScreenState();
}

class _ItemMovementScreenState extends ConsumerState<ItemMovementScreen> {
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;

  String get _branchLabel => widget.subDno == null
      ? 'كل الفروع'
      : (widget.subLabel ?? 'فرع ${widget.subDno}');

  String get _rangeText {
    if (_from == null && _to == null) return 'كل الفترات';

    final from = _from == null ? 'البداية' : StoreFormat.date(_from);
    final to = _to == null ? 'اليوم' : StoreFormat.date(_to);

    return 'من $from إلى $to';
  }

  ItemStatementKey get _key => (
    sanfNo: widget.sanfNo,
    subDno: widget.subDno,
    from: _from,
    to: _to,
    storeNo: null,
  );

  @override
  Widget build(BuildContext context) {
    final statement = ref.watch(itemStatementProvider(_key));
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesReportsPrint);
    final canExport = auth.can(Perm.storesReportsExport);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كشف حركة الصنف'),
        actions: [
          IconButton(
            tooltip: 'المدى الزمني',
            onPressed: () => _pickRange(context),
            icon: const Icon(Icons.date_range_rounded),
          ),
          if (canPrint)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _busy ? null : () => _export(statement.value, print: true),
              icon: const Icon(Icons.print_outlined),
            ),
          if (canExport)
            IconButton(
              tooltip: 'تصدير Excel',
              onPressed: _busy ? null : () => _exportXlsx(statement.value),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: statement.when(
              loading: () => const StoreLoading(
                message: 'جارٍ تجهيز كشف الحركة...',
              ),
              error: (error, _) => StoreErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(itemStatementProvider(_key)),
              ),
              data: (data) {
                if (data.isEmpty) {
                  // ── بلا المدى الزمني في الرسالة حين لا مدى محدداً: «في المدى المحدد» توحي
                  //    بأن المستخدم اختار مدى وهو لم يختر، والحقيقة أن الصنف بلا حركة إطلاقاً.
                  // ── Do not blame a range the user never picked: "in the selected range" reads
                  //    like a filter problem when the truth is the item has no movement at all.
                  return StoreEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'لا حركات',
                    description: _from == null && _to == null
                        ? 'لم يُورَّد هذا الصنف ولا يُصرف منه بعد، فرصيد صفر هنا صحيح لا ناقص. '
                              'اختر مدى زمنياً لعرض ما سبق.'
                        : 'لا حركة في المدى المحدد ($_rangeText). وسّع المدى أو أعد الضبط.',
                  );
                }

                return ReportZoomView(child: _table(data.rows));
              },
            ),
          ),
          statement.maybeWhen(
            data: (data) => data.isEmpty ? const SizedBox.shrink() : _totals(data),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// ترويسة الكشف: الصنف والفرع والمدى — تُقرأ قبل أي جدول
  /// The statement header: the item, the branch and the range — read before any table.
  Widget _header() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
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
                label: _branchLabel,
                icon: widget.subDno == null
                    ? Icons.account_tree_outlined
                    : Icons.subdirectory_arrow_left_rounded,
                color: AppColors.primary,
              ),
              StoreTag(
                label: _rangeText,
                icon: Icons.date_range_rounded,
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// جدول الحركة: التاريخ · المستند · النوع · المخزن · الفرع · وارد · صادر · التكلفة · القيمة
  /// The movement table: date · document · type · store · branch · in · out · cost · value.
  Widget _table(List<StockMovementRow> rows) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final row = rows[index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: row.netQty < 0
                  ? AppColors.error.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 74,
                child: Text(
                  row.dateLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${row.typeName ?? 'حركة'} · ${row.storeName ?? row.storeNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'مستند ${row.docNo ?? '—'} · ${row.subLabel}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.netQty == 0 ? '0' : StoreFormat.qty(row.netQty),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: row.netQty < 0
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                  Text(
                    StoreFormat.money(row.lineValue),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// شريط المجاميع — من الخادم لا من السطور المعروضة
  /// The totals bar — server totals, never the visible rows.
  Widget _totals(MovementStatement data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${data.lines} سطر',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Text(
            'وارد ${StoreFormat.qty(data.qtyIn)}',
            style: const TextStyle(fontSize: 11, color: AppColors.success),
          ),
          const SizedBox(width: 8),
          Text(
            'صادر ${StoreFormat.qty(data.qtyOut)}',
            style: const TextStyle(fontSize: 11, color: AppColors.error),
          ),
          const Spacer(),
          Text(
            StoreFormat.money(data.value),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// اختيار المدى الزمني — بلا مدى يُمسح الـ VIEW كاملة
  /// Pick the date range — an unbounded statement scans the whole view.
  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'مدى كشف الحركة',
      saveText: 'تطبيق',
    );

    if (picked == null) return;

    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
  }

  Future<void> _export(MovementStatement? data, {bool print = false}) async {
    if (data == null || data.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final bytes = await buildItemStatementPdf(
        letterhead: letterhead,
        itemName: widget.itemName,
        branchLabel: _branchLabel,
        rangeText: _rangeText,
        rows: data.rows,
        qtyIn: data.qtyIn,
        qtyOut: data.qtyOut,
        netQty: data.netQty,
        totalValue: data.value,
      );

      final fileName =
          'item-movement-${widget.sanfNo}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تجهيز الكشف: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportXlsx(MovementStatement? data) async {
    if (data == null || data.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final bytes = buildStoreRowsXlsx(
        sheetName: 'حركة الصنف',
        headers: const [
          'التاريخ',
          'المستند',
          'نوع الحركة',
          'المخزن',
          'الفرع',
          'وارد',
          'صادر',
          'الصافي',
          'التكلفة',
          'القيمة',
        ],
        rows: [
          for (final row in data.rows)
            [
              row.dateLabel,
              '${row.docNo ?? ''}',
              row.typeName ?? '',
              row.storeName ?? '',
              row.subLabel,
              StoreFormat.qty(row.qtyIn),
              StoreFormat.qty(row.qtyOut),
              StoreFormat.qty(row.netQty),
              StoreFormat.money(row.cost),
              StoreFormat.money(row.lineValue),
            ],
        ],
      );

      await StoreExporter.shareXlsx(
        bytes: bytes,
        fileName: 'item-movement-${widget.sanfNo}-${StoreExporter.stamp()}.xlsx',
        subject: 'كشف حركة ${widget.itemName}',
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
