import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_section_card.dart';

/// القسم 1: بيانات الفاتورة والطلب — كلها من الـ VIEW + صف SALES_BILL الواحد
/// Section 1: the invoice and order data — all from the view plus the single SALES_BILL row.
///
/// الترتيب: شريط هوية واحد (رقم الفاتورة · اليدوي · التاريخ · عاجل) ثم حقول الطلب في شبكة
/// بأعمدة متساوية تفصلها خطوط، ثم البيان في خانة تمتد على الصف. الحقول لم تُحذف — أُعيد
/// ترتيبها في صفوف منظّمة بدل التوزيع المتفرّق.
/// The order: one identity strip (bill number · manual · date · urgent), then the order fields
/// in an equal-column grid separated by hairlines, then the note on a full-width cell. No field
/// was dropped — the set was merely re-arranged into regular rows.
class BillHeaderCard extends StatelessWidget {
  final CuttingBillHeader header;

  /// اسم العملة كما يظهر في العملة الافتراضية… يُترك الرقم عند غياب التسمية
  /// The currency name; the number is used when no name is available.
  final String? currencyLabel;

  const BillHeaderCard({super.key, required this.header, this.currencyLabel});

  @override
  Widget build(BuildContext context) {
    return TailoringSectionCard(
      title: 'بيانات الفاتورة والطلب',
      icon: Icons.description_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── شريط الهوية: شارات في سطر واحد ──────────────────────────────────
          // The identity strip: chips on a single line.
          Wrap(
            spacing: 6,
            runSpacing: 3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _identity(header.referenceLabel, color: AppColors.primary, bold: true),
              _identity(header.manualLabel, color: AppColors.textSecondary),
              _identity(header.date ?? '—', color: AppColors.textSecondary),
              if (header.urgent)
                _identity('عاجل', color: AppColors.error, bold: true),
            ],
          ),
          const SizedBox(height: 5),

          // ── حقول الطلب في شبكة منضبطة ────────────────────────────────────────
          // The order fields in a regular grid.
          TailoringInfoGrid(
            minCellWidth: 118,
            children: [
              TailoringInfoTile(
                label: 'السنة',
                value: '${header.year}',
                icon: Icons.calendar_month_rounded,
              ),
              TailoringInfoTile(
                label: 'مرجع الفاتورة',
                value: header.refNo,
                icon: Icons.link_rounded,
              ),
              TailoringInfoTile(
                label: 'تاريخ التسليم',
                value: header.handingDate,
                icon: Icons.local_shipping_rounded,
              ),
              TailoringInfoTile(
                label: 'الاستحقاق',
                value: header.givingDate,
                icon: Icons.schedule_rounded,
              ),
              if (currencyLabel != null)
                TailoringInfoTile(
                  label: 'العملة',
                  value: currencyLabel,
                  icon: Icons.payments_rounded,
                ),
              TailoringInfoTile(
                label: 'الحالة',
                value:
                    header.ordsName ??
                    (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
                icon: Icons.flag_rounded,
                valueColor: header.handingDone
                    ? AppColors.success
                    : AppColors.warning,
              ),
              TailoringInfoTile(
                label: 'الموديلات',
                value: '${header.modelsCount}',
                icon: Icons.checkroom_rounded,
              ),
              TailoringInfoTile(
                label: 'القطع',
                value: '${header.piecesCount}',
                icon: Icons.layers_rounded,
              ),
            ],
          ),

          // ── البيان: خانة تمتد على عرض الصف ───────────────────────────────────
          // The note: a cell spanning the full row.
          if (header.details != null && header.details!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            TailoringInfoGrid(
              minCellWidth: 4000,
              children: [
                TailoringInfoTile(
                  label: 'البيان',
                  value: header.details,
                  icon: Icons.notes_rounded,
                ),
              ],
            ),
          ],

          if (header.createdBy != null || header.lastUpdatedBy != null) ...[
            const SizedBox(height: 3),
            Text(
              tailoringJoin([
                if (header.createdBy != null) 'أنشأها: ${header.createdBy}',
                if (header.lastUpdatedBy != null)
                  'آخر تعديل: ${header.lastUpdatedBy}',
              ]),
              style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// شارة هوية صغيرة
  /// A small identity chip.
  Widget _identity(String text, {required Color color, bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
