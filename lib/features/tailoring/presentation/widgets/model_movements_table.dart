import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_movement_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import 'tailoring_section_card.dart';

/// القسم 8: سجل حركة الموديل المختار — يُحمَّل عند فتح القسم فقط
/// Section 8: the selected model's movement log — loaded only when the section opens.
///
/// الواجهة تحمل الحالة الحالية بلا تاريخ انتقالات، فالسجل يأتي من قراءة تكميلية
/// (`CUTING_TRANSD` + `ORDSTATE`) بأرقام قطع الموديل التي يحملها العميل أصلاً.
/// The view carries the current stage with no transition history, so the log comes from a
/// supplementary read keyed by the piece numbers the client already holds.
class ModelMovementsTable extends ConsumerWidget {
  /// الموديل المختار — يُستخدم لاستخراج أرقام قطعه وللتسمية
  /// The selected model — used to derive its piece numbers and for the title.
  ///
  /// يُمرَّر `null` عند عرض حركة الفاتورة كاملة، وتُغذّى الأرقام عبر `seqNos`.
  /// Passed `null` when showing the whole bill's movements, with the numbers fed via `seqNos`.
  final CuttingModelItem? model;

  /// رقم الفاتورة وسنتها — مفتاح الطلب
  /// The bill number and year — the request key.
  final int billNo;
  final int year;

  /// أرقام القطع صريحةً — تتجاوز أرقام الموديل عند العرض على مستوى الفاتورة
  /// Explicit piece numbers — they override the model's own when rendering bill-wide.
  final List<int>? seqNos;

  /// عنوان القسم؛ يعود إلى تسمية الموديل عند غيابه
  /// The section title; falls back to the model's label when absent.
  final String? title;

  const ModelMovementsTable({
    super.key,
    required this.model,
    required this.billNo,
    required this.year,
    this.seqNos,
    this.title,
  });

  /// أرقام القطع المطلوبة: الصريحة ثم الموديل
  /// The requested piece numbers: the explicit ones first, then the model's.
  List<int> get _pieceNumbers =>
      seqNos ?? model?.movementSeqNos ?? const <int>[];

  /// عنوان القسم: الصريح ثم الموديل ثم اسم عام
  /// The section title: explicit, then the model's, then a generic one.
  String get _title {
    if (title != null) return title!;
    final model = this.model;
    return model == null ? 'سجل الحركة' : 'سجل الحركة — موديل ${model.seqNo}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pieceNumbers = _pieceNumbers;

    if (pieceNumbers.isEmpty) {
      return TailoringSectionCard(
        title: _title,
        icon: Icons.history_rounded,
        accent: AppColors.primaryLight,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'لا توجد أرقام قطع لهذا الموديل لطلب سجل حركته',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      );
    }

    final async = ref.watch(
      cuttingMovementsProvider(
        CuttingMovementsKey(billNo: billNo, year: year, seqNos: pieceNumbers),
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
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'لا توجد حركات مسجّلة على قطع هذا الموديل',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              )
            : LayoutBuilder(
                builder: (ctx, constraints) {
                  // صف واحد لكل حركة في كل الأحجام — تُقرأ الحركة أفقياً كما يُقرأ كشف حساب
                  // One row per movement at every size — read horizontally like a ledger line.
                  const minWidth = 640.0;
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
            style: const TextStyle(fontSize: 12, color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => ref.invalidate(
              cuttingMovementsProvider(
                CuttingMovementsKey(
                  billNo: billNo,
                  year: year,
                  seqNos: _pieceNumbers,
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

  Widget _buildTable(List<CuttingMovement> rows) {
    return Table(
      border: TableBorder.all(
        color: AppColors.border,
        width: 0.7,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.6),
        2: FlexColumnWidth(1.6),
        3: FixedColumnWidth(66),
        4: FlexColumnWidth(2),
        5: FixedColumnWidth(70),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceSubtle),
          children: [
            _th('التاريخ'),
            _th('الحالة'),
            _th('القسم'),
            _th('العدد'),
            _th('ملاحظة'),
            _th('الترحيل'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFBFC),
            ),
            children: [
              _td(rows[i].date ?? '—'),
              _td(rows[i].stageLabel),
              _td(rows[i].deptName ?? '—'),
              _td(rows[i].qty == null ? '—' : rows[i].quantityLabel),
              _td(rows[i].details ?? '—'),
              _td(rows[i].postedLabel),
            ],
          ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:  TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _td(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:  TextStyle(fontSize: 11, color: AppColors.textPrimary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
