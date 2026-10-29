import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_movement_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import 'tailoring_section_card.dart';

/// القسم 8: سجل حركة أقمشة الموديل المختار — يُحمَّل عند فتح القسم فقط
/// Section 8: the selected model's fabric movement log — loaded only when the section opens.
///
/// **السجل يخصّ القماش (OHDID) لا الموديل**: لذلك يُطلب بأرقام طلبات أقمشة الموديل، وكل حركة
/// صف واحد بأعمدة ظاهرة: الحالة · التاريخ · العدد · المنفذ · ملاحظة.
/// **The log belongs to the fabric (OHDID), not the model**: it is requested with the model's
/// fabric order ids, and every movement is a single row with visible columns: state · date ·
/// quantity · executor · note.
class ModelMovementsTable extends ConsumerWidget {
  /// الموديل المختار — تُستخرج منه أرقام طلبات أقمشته
  /// The selected model — its fabric order ids are derived from it.
  final CuttingModelItem? model;

  /// رقم الفاتورة وسنتها — مفتاح الطلب
  /// The bill number and year — the request key.
  final int billNo;
  final int year;

  /// أرقام طلبات صريحة — تتجاوز أرقام الموديل عند العرض على مستوى الفاتورة
  /// Explicit order ids — they override the model's own when rendering bill-wide.
  final List<int>? ohdIds;

  /// عنوان القسم؛ يعود إلى تسمية الموديل عند غيابه
  /// The section title; falls back to the model's label when absent.
  final String? title;

  const ModelMovementsTable({
    super.key,
    required this.model,
    required this.billNo,
    required this.year,
    this.ohdIds,
    this.title,
  });

  /// أرقام الطلبات المطلوبة: الصريحة ثم أقمشة الموديل
  /// The requested order ids: the explicit ones first, then the model's fabrics.
  List<int> get _orderIds => ohdIds ?? model?.movementOhdIds ?? const <int>[];

  /// عنوان القسم: الصريح ثم الموديل ثم اسم عام
  /// The section title: explicit, then the model's, then a generic one.
  String get _title {
    if (title != null) return title!;
    final model = this.model;
    return model == null ? 'سجل الحركة' : 'سجل الحركة — موديل ${model.seqNo}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderIds = _orderIds;

    if (orderIds.isEmpty) {
      return TailoringSectionCard(
        title: _title,
        icon: Icons.history_rounded,
        accent: AppColors.primaryLight,
        child: Text(
          'لا توجد أقمشة تحمل رقم طلب لهذا الموديل',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final async = ref.watch(
      cuttingMovementsProvider(
        CuttingMovementsKey(billNo: billNo, year: year, ohdIds: orderIds),
      ),
    );

    return TailoringSectionCard(
      title: _title,
      icon: Icons.history_rounded,
      accent: AppColors.primaryLight,
      trailing: async.maybeWhen(
        data: (rows) => TailoringChip(
          label: '${rows.length} حركة',
          color: AppColors.primaryLight,
        ),
        orElse: () => const SizedBox.shrink(),
      ),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => _buildError(context, ref, error),
        data: (rows) => rows.isEmpty
            ? Text(
                'لا توجد حركات مسجّلة على أقمشة هذا الموديل',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              )
            : LayoutBuilder(
                builder: (ctx, constraints) {
                  // صف واحد لكل حركة في كل الأحجام — تُقرأ الحركة أفقياً كما يُقرأ كشف حساب
                  // One row per movement at every size — read horizontally like a ledger line.
                  const minWidth = 700.0;
                  final width = constraints.maxWidth < minWidth
                      ? minWidth
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: width, child: _buildTable(rows)),
                  );
                },
              ),
      ),
    );
  }

  /// الخطأ لا يترك القسم فارغاً صامتاً — له نصّ وإعادة محاولة
  /// An error never leaves the section silently blank — it gets text and a retry.
  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(
            error is TailoringException
                ? error.displayMessage
                : 'تعذّر تحميل سجل الحركة',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => ref.invalidate(
              cuttingMovementsProvider(
                CuttingMovementsKey(
                  billNo: billNo,
                  year: year,
                  ohdIds: _orderIds,
                ),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  /// خمسة أعمدة فقط: الحالة · التاريخ · العدد · المنفذ · ملاحظة
  /// Five columns only: state · date · quantity · executor · note.
  Widget _buildTable(List<CuttingMovement> rows) {
    return Table(
      border: TableBorder.all(
        color: AppColors.border,
        width: 0.7,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.6),
        1: FixedColumnWidth(90),
        2: FixedColumnWidth(62),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(2.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceSubtle),
          children: [
            _th('الحالة'),
            _th('التاريخ'),
            _th('العدد'),
            _th('المنفذ'),
            _th('ملاحظة'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFBFC),
            ),
            children: [
              _td(rows[i].stageLabel, strong: true),
              _td(rows[i].dateLabel),
              _td(rows[i].qtyLabel),
              _td(rows[i].executorLabel),
              _td(rows[i].noteLabel),
            ],
          ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _td(String text, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
