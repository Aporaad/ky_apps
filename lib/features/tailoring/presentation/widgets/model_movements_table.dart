import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_movement_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import 'tailoring_section_card.dart';

/// القسم 8: سجل حركة **القماش المحدد** (OHDID) — لا الموديل
/// Section 8: the movement log of the **selected fabric** (OHDID) — not the model.
///
/// السجل يُطلب برقم طلب القماش المختار من قائمة الأقمشة، ويتغيّر بتغيّر الاختيار. والأعمدة
/// خمسة فقط: الحالة · التاريخ · العدد · المنفذ · ملاحظة، وكل حركة في صف واحد ظاهرة الأعمدة،
/// بأعمدة مرنة ونصوص تلتفّ فلا حاجة لتمرير أفقي.
/// The log is requested with the order id of the fabric selected in the fabrics list and changes
/// with that selection. Only five columns: state · date · quantity · executor · note; each
/// movement is one row with every column visible, using flex columns and wrapping text so no
/// horizontal scroll is needed.
class ModelMovementsTable extends ConsumerWidget {
  /// الموديل المختار — تُستخرج منه أقمشته عند غياب `ohdId`
  /// The selected model — its fabrics are derived from it when `ohdId` is absent.
  final CuttingModelItem? model;

  /// رقم الفاتورة وسنتها — مفتاح الطلب
  /// The bill number and year — the request key.
  final int billNo;
  final int year;

  /// القماش المحدد (OHDID) — مصدر السجل وحيد
  /// The selected fabric (OHDID) — the single source of the log.
  final int? ohdId;

  /// أرقام طلبات صريحة — تتجاوز الاختيار عند العرض على مستوى الفاتورة
  /// Explicit order ids — they override the selection when rendering bill-wide.
  final List<int>? ohdIds;

  /// اسم القماش المحدد — يُعرض في العنوان ليعرف المستخدم سجل أي قماش يرى
  /// The selected fabric's name — shown in the title so the user knows whose log this is.
  final String? fabricName;

  /// عنوان القسم؛ يعود إلى تسمية الموديل عند غيابه
  /// The section title; falls back to the model's label when absent.
  final String? title;

  const ModelMovementsTable({
    super.key,
    required this.model,
    required this.billNo,
    required this.year,
    this.ohdId,
    this.ohdIds,
    this.fabricName,
    this.title,
  });

  /// أرقام الطلبات المطلوبة: الصريحة، ثم القماش المحدد، ثم كل أقمشة الموديل
  /// The requested order ids: the explicit ones, then the selected fabric, then the model's.
  List<int> get _orderIds {
    if (ohdIds != null) return ohdIds!;
    final single = ohdId;
    if (single != null && single > 0) return [single];
    return model?.movementOhdIds ?? const <int>[];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderIds = _orderIds;

    final sectionTitle = title ??
        (fabricName == null ? 'سجل الحركة' : 'سجل الحركة — $fabricName');

    if (orderIds.isEmpty) {
      return TailoringSectionCard(
        title: sectionTitle,
        icon: Icons.history_rounded,
        accent: AppColors.primaryLight,
        child: Text(
          'اختر قماشاً من قسم الأقمشة لعرض سجل حركته',
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
      title: sectionTitle,
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
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => _buildError(ref, error),
        data: (rows) => rows.isEmpty
            ? Text(
                'لا توجد حركات مسجّلة على هذا القماش',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              )
            : _buildRows(rows),
      ),
    );
  }

  /// الخطأ لا يترك القسم فارغاً صامتاً — له نصّ وإعادة محاولة
  /// An error never leaves the section silently blank — it gets text and a retry.
  Widget _buildError(WidgetRef ref, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          const SizedBox(height: 4),
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

  /// رأس الأعمدة مرة واحدة + صف لكل حركة، بأعمدة مرنة ونصوص كاملة
  /// One header plus a row per movement, with flex columns and untruncated text.
  Widget _buildRows(List<CuttingMovement> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: AppColors.surfaceSubtle,
            child: _row(
              cells: const ['الحالة', 'التاريخ', 'العدد', 'المنفذ', 'ملاحظة'],
              header: true,
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            Container(
              height: 0.7,
              color: AppColors.border.withValues(alpha: 0.9),
            ),
            Container(
              color: i.isEven ? AppColors.surface : const Color(0xFFF7F9FB),
              child: _row(
                cells: [
                  rows[i].stageLabel,
                  rows[i].dateLabel,
                  rows[i].qtyLabel,
                  rows[i].executorLabel,
                  rows[i].noteLabel,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// صف بأعمدة مرنة: كل خلية تلتفّ على سطرين عند الحاجة بدل القصّ
  /// A flex-column row: each cell wraps to two lines when needed instead of being cut.
  Widget _row({required List<String> cells, bool header = false}) {
    const flexes = [1.6, 1.2, 0.7, 1.4, 2.6];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: (flexes[i] * 10).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                cells[i],
                textAlign: TextAlign.center,
                softWrap: true,
                style: header
                    ? TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                      )
                    : TextStyle(
                        fontSize: 11,
                        fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
