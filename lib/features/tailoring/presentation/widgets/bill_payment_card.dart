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
            // سطر واحد: الحقول كلها في صف واحد بحصص متساوية وقيم مقياسية
            // One row: all fields in a single line with equal shares and scaled values.
            rows: 1,
            minCellWidth: 80,
            cells: [
              TailoringCell(
                label: 'الإجمالي',
                value: tailoringNumber(data.total),
                numeric: true,
              ),
              TailoringCell(
                label: 'الخصم',
                value: tailoringNumber(data.discount),
                numeric: true,
              ),
              // الصافي = الإجمالي − الخصم (يُحسب على الخادم، لا من عمود NET الخام)
              // The net is total − discount (computed server-side, not the raw NET column).
              TailoringCell(
                label: 'الصافي',
                value: tailoringNumber(data.net),
                numeric: true,
              ),
              TailoringCell(
                label: 'المدفوع',
                value: tailoringNumber(data.paidTotal),
                numeric: true,
              ),
              // مدفوعات أخرى تظهر فقط عند وجودها، لتتّضح معادلة المتبقي = الصافي − المدفوع − الأخرى
              // Other payments appear only when present, so remaining = net − paid − others is clear.
              if ((data.othersPayments ?? 0) != 0)
                TailoringCell(
                  label: 'مدفوعات أخرى',
                  value: tailoringNumber(data.othersPayments),
                  numeric: true,
                ),
              // المتبقي = الصافي − المدفوع − المدفوعات الأخرى (يُحسب على الخادم)
              // The remaining is net − paid − others (computed server-side).
              TailoringCell(
                label: data.balanceLabel,
                value: data.balanceValue,
                numeric: true,
                // الرصيد السالب دفعة مقدمة — لونه أخضر لأنه لصالح العميل لا عليه
                // A negative balance is an advance — green because it favours the customer.
                valueColor: data.isAdvance
                    ? AppColors.success
                    : (data.remaining == 0 ? AppColors.success : AppColors.error),
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
