import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_cells.dart';
import 'tailoring_section_card.dart';

/// القسم 3: تفاصيل الدفع — كل الأرقام في **سطر وصف واحد دائماً**
/// Section 3: the payment details — every figure on **one row always**.
///
/// الحجب الحقيقي على الخادم: بلا صلاحية `tailoring.payments_view` يصل `payment = null` ولا
/// تُعرض أرقام أصلاً.
/// The real block is server-side: without `payments_view` the block arrives null and no figure
/// is shown at all.
///
/// التنسيق: الشبكة تُطلب بـ`rows: 1` فتأخذ كل خانة حصّة متساوية، والتسمية والقيمة تُصغَّران
/// معاً داخل `FittedBox`، فلا عمود يلتفّ ولا نصّ يُقصّ ولا يختفي عند كبر حجم الخط أو المساحة.
/// Layout: the grid asks for `rows: 1` so every cell takes an equal share, and both label and
/// value shrink together inside a `FittedBox` — no column wraps, no text is cut, and nothing
/// disappears when the type scale or the width grows.
class BillPaymentCard extends StatelessWidget {
  final CuttingBillPayment? payment;

  const BillPaymentCard({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final data = payment;

    if (data == null) {
      return TailoringSectionCard(
        title: 'تفاصيل الدفع',
        icon: Icons.payments_rounded,
        accent: AppColors.warning,
        child: TailoringCellGrid(
          rows: 1,
          minCellWidth: 300,
          cells: const [
            TailoringCell(
              label: 'الصلاحية',
              value: 'لا تملك صلاحية عرض تفاصيل دفع فاتورة التفصيل',
              icon: Icons.lock_outline_rounded,
            ),
          ],
        ),
      );
    }

    return TailoringSectionCard(
      title: 'تفاصيل الدفع',
      icon: Icons.payments_rounded,
      accent: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TailoringCellGrid(
            // سطر واحد: ثلاثة حقول مالية فقط — الإجمالي · العربون · المتبقي (+ رقم السند)
            // One row: three money fields only — total · deposit · remaining (+ voucher no).
            rows: 1,
            minCellWidth: 80,
            cells: [
              TailoringCell(
                label: 'الإجمالي',
                value: tailoringNumber(data.total),
                numeric: true,
              ),
              // العربون = المبلغ المدفوع (AMOUNT_PAID) وحده، بلا مدفوعات أخرى
              // The deposit is AMOUNT_PAID alone, without the other payments.
              TailoringCell(
                label: 'العربون',
                value: tailoringNumber(data.paid),
                numeric: true,
              ),
              // المتبقي = الإجمالي − العربون فقط (يُحسب على الخادم)
              // The remaining is total − deposit only (computed server-side).
              TailoringCell(
                label: 'المتبقي',
                value: tailoringNumber(data.remaining),
                numeric: true,
                // صفر أو سالب ⇒ مسدَّد (أخضر)، موجب ⇒ باقٍ على العميل (أحمر)
                // Zero or negative means settled (green); positive is still owed (red).
                valueColor: (data.remaining ?? 0) <= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
              TailoringCell(
                label: 'رقم السند',
                value: data.voucherNo,
                numeric: true,
              ),
            ],
          ),
          // إشارة الرصيد السالب تُشرح صراحةً بدل ترك المستخدم يقرأ السالب خطأ
          // The negative balance is explained instead of leaving the sign to be misread.
          
        ],
      ),
    );
  }
}
