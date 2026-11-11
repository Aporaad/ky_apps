import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_section_card.dart';

/// القسم 1: بيانات الفاتورة والطلب — كلها من الـ VIEW + صف SALES_BILL الواحد
/// Section 1: the invoice and order data — all from the view plus the single SALES_BILL row.
///
/// شريط هوية واحد (رقم الفاتورة · اليدوي · التاريخ · مستعجل) ثم حقول الطلب في **صفّين فقط**
/// بأعمدة متساوية، ثم البيان في خانة تمتد على الصف. السنة والفرع والمجموعة حُذفت بطلب
/// المستخدم لأنها لا تُحتاج في الاستعراض.
/// One identity strip (bill number · manual · date · urgent), then the order fields in **exactly
/// two rows** of equal columns, then the note on a full-width cell. The year, branch and group
/// were removed at the user's request because the review does not need them.
class BillHeaderCard extends StatelessWidget {
  final CuttingBillHeader header;

  /// اسم العملة كما يظهر في العملة الافتراضية… يُترك الرقم عند غياب التسمية
  /// The currency name; the number is used when no name is available.
  final String? currencyLabel;

  const BillHeaderCard({super.key, required this.header, this.currencyLabel});

  @override
  Widget build(BuildContext context) {
    // خلايا السطر النصي: البيان ثم ملاحظة المستعجل — كلٌّ يظهر إن كانت له قيمة فقط،
    // والملاحظة لا تُعرض إلا على فاتورة مستعجلة.
    // The text-line cells: the note then the urgent note — each shows only with a value, and the
    // note appears only on an urgent bill.
    String billKindName ;
    switch(header.billKind){
     case 1:
      billKindName=' عادية';
      break;
     case 2:      
      billKindName=' موقفة';
      break;
    case 3:
      billKindName= 'ملغية';
      break;
    case 4:
      billKindName=' معلقة';
      break;
    default:
    billKindName='';
    }
    final noteTiles = <Widget>[
      if ((header.details ?? '').trim().isNotEmpty)
        TailoringInfoTile(
          label: 'البيان',
          value: header.details,
          icon: Icons.notes_rounded,
        ),
      if (header.urgent && (header.urgentNote ?? '').trim().isNotEmpty)
        TailoringInfoTile(
          label: 'ملاحظة المستعجل',
          value: header.urgentNote,
          icon: Icons.local_fire_department_rounded,
          valueColor: AppColors.error,
        ),
    ];

    // سطر التوقيع: الإنشاء والتعديل والطباعة في سطر واحد بلا سطر جديد
    // The footer line: creation, update and printing together on one single line.
    final printedSegment = (header.printedAt ?? '').trim().isNotEmpty ||
            (header.printedBy ?? '').trim().isNotEmpty
        ? 'تم الطباعه في :${_orDash(header.printedAt)}  من قبل :${_orDash(header.printedBy)}'
        : null;

    final footerLine = tailoringJoin([
      if (header.createdBy != null) 'أنشأها: ${header.createdBy}',
      if (header.lastUpdatedBy != null) 'آخر تعديل: ${header.lastUpdatedBy}',
      if (printedSegment != null) printedSegment,
    ]);

    return TailoringSectionCard(
      title: 'بيانات الفاتورة والطلب',
      icon: Icons.description_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── شريط الهوية ─────────────────────────────────────────────────────
          // The identity strip.
          Wrap(
            spacing: 3,
            runSpacing: 1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _identity(header.referenceLabel, color: AppColors.primary, bold: true),
             // _identity('يدوي ${header.manualLabel}', color: AppColors.textPrimary),
              _identity(header.date ?? '—', color: AppColors.textPrimary),
              // نوع الفاتورة بجانب التاريخ — ولا يظهر إن لم تكن له قيمة
              // The bill kind sits beside the date, and never shows when it has no value.
              if (header.billKind != null)
                _identity(
                  'فاتورة ${billKindName}',
                  color: AppColors.info,
                ),
              if (header.urgent)
                _identity('مستعجل', color: AppColors.error, bold: true),
            ],
          ),
          const SizedBox(height: 5),

          // ── حقول الطلب: صفّان فقط ───────────────────────────────────────────
          // The order fields: two rows only.
          TailoringInfoGrid(
            rows: 2,
            children: [
              TailoringInfoTile(
                label: 'الرقم اليدوي',
                value: header.manualLabel,
                icon: Icons.link_rounded,
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
              // if (currencyLabel != null)
              //   TailoringInfoTile(
              //     label: 'العملة',
              //     value: currencyLabel,
              //     icon: Icons.payments_rounded,
              //   ),
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
              // TailoringInfoTile(
              //   label: 'الموديلات',
              //   value: '${header.modelsCount}',
              //   icon: Icons.checkroom_rounded,
              // ),
              TailoringInfoTile(
                label: 'عدد الثياب',
                value: '${header.piecesCount}',
                icon: Icons.layers_rounded,
              ),
            ],
          ),

          // ── البيان وملاحظة المستعجل: سطر واحد جنباً إلى جنب ────────────────────
          // The note and the urgent note share one row, side by side.
          // الحقل لا يظهر إلا إن كان له قيمة، والملاحظة لا تُعرض إلا على فاتورة مستعجلة.
          // A field shows only when it carries a value, and the note only on an urgent bill.
          if (noteTiles.isNotEmpty) ...[
            const SizedBox(height: 4),
            TailoringInfoGrid(
              // صفّ واحد دائم: البيان ثم ملاحظة المستعجل في نفس السطر بلا سطر جديد
              // Always one row: the note and the urgent note on the same line.
              rows: 1,
              minCellWidth: 150,
              children: noteTiles,
            ),
          ],

          if (footerLine.isNotEmpty) ...[
            const SizedBox(height: 3),
            // لا قصّ ولا سطر جديد: النص يتقلّص ليبقى كاملاً في سطر واحد
            // No clipping and no new line: the text shrinks so it stays whole on one line.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                footerLine,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// شرطة عند غياب القيمة — الحقل الفارغ لا يظهر أصلاً، وهذا احتياط للنص المركّب
  /// A dash when the value is missing: empty fields never render, this guards the joined line.
  static String _orDash(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '—' : text;
  }

  /// شارة هوية صغيرة — نصّ بخط ثقيل لأنها تحمل رقم الفاتورة وتاريخها
  /// A small identity chip — a heavy weight because it carries the bill number and date.
  Widget _identity(String text, {required Color color, bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
