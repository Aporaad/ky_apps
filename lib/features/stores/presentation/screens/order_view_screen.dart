import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/store_orders_repository.dart';
import '../providers/orders_providers.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';

/// استعراض مستند مخزني — قراءة وطباعة وتصدير
/// Viewing a stock document — read, print and export.
class OrderViewScreen extends ConsumerStatefulWidget {
  const OrderViewScreen({super.key, required this.kind, required this.billNo});

  final StoreOrderKind kind;
  final int billNo;

  @override
  ConsumerState<OrderViewScreen> createState() => _OrderViewScreenState();
}

class _OrderViewScreenState extends ConsumerState<OrderViewScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
      orderDetailProvider((kind: widget.kind, billNo: widget.billNo)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.kind.documentLabel} ${widget.billNo}'),
        actions: [
          IconButton(
            tooltip: 'طباعة',
            onPressed: _busy ? null : () => _export(detail.value, print: true),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'مشاركة PDF',
            onPressed: _busy ? null : () => _export(detail.value),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const StoreLoading(),
        error: (error, _) => StoreErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(
            orderDetailProvider((kind: widget.kind, billNo: widget.billNo)),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const StoreEmptyState(
              icon: Icons.description_outlined,
              title: 'المستند غير موجود',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _headerCard(data.header),
              const SizedBox(height: 12),
              _linesCard(data.lines),
              const SizedBox(height: 12),
              _totalsCard(data.header),
              const SizedBox(height: 14),
              const Text(
                'هذا المستند يحرّك أرصدة المخزن فور حفظه؛ حذفه يلغي أثره تماماً.',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCard(StoreOrderModel header) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  header.reference,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                header.dateLabel,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (header.createdByName != null)
                StoreTag(
                  label: header.createdByName!,
                  icon: Icons.person_outline_rounded,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _row(
            widget.kind.hasTargetStore ? 'من مخزن' : 'المخزن',
            header.storeName ?? '${header.storeNo}',
          ),
          if (widget.kind.hasTargetStore)
            _row('إلى مخزن', header.storeToName ?? '${header.storeTo ?? '—'}'),
          if (widget.kind.hasParty)
            _row(
              widget.kind == StoreOrderKind.receive ? 'المورد' : 'الجهة المستلمة',
              header.partyName ?? '—',
            ),
          _row('عدد الأصناف', '${header.sanfNums}'),
          if (header.detailes != null) _row('البيان', header.detailes!),
        ],
      ),
    );
  }

  Widget _linesCard(List<StoreOrderLineModel> lines) {
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
          StoreSectionHeader(
            title: 'السطور (${lines.length})',
            icon: Icons.list_alt_rounded,
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            const Text(
              'لا سطور',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            )
          else
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            line.sanfName ?? 'صنف ${line.sanfNo}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${line.partNo ?? '—'} · ${line.sanfDno}'
                            '${line.unitName != null ? ' · ${line.unitName}' : ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${StoreFormat.qty(line.qty)} × ${StoreFormat.money(line.price)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: Text(
                        StoreFormat.money(line.total),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _totalsCard(StoreOrderModel header) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row('الإجمالي', StoreFormat.money(header.total)),
          _row('الخصم', StoreFormat.money(header.discount)),
          const Divider(height: 14),
          Row(
            children: [
              const Text(
                'الصافي',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                StoreFormat.money(header.net),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(StoreOrderDetail? data, {bool print = false}) async {
    if (data == null || _busy) return;

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final bytes = await buildStoreOrderPdf(
        letterhead: letterhead,
        kind: widget.kind,
        header: data.header,
        lines: data.lines,
      );

      final fileName =
          'store-${widget.kind.code}-${data.header.reference}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
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
}
