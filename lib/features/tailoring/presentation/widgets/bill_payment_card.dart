import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/tailoring_parse.dart';
import 'tailoring_section_card.dart';

/// القسم 3: تفاصيل الدفع — تُغلَّف بـ `PermissionGate(tailoring.payments_view)`
/// Section 3: the payment details — wrapped in `PermissionGate(tailoring.payments_view)`.
///
/// الحجب الحقيقي على الخادم: بلا الصلاحية يصل `payment = null` ولا تُعرض أرقام أصلاً.
/// The real block is server-side: without the grant `payment` arrives null and no figures
/// are shown at all.
///
/// كل الأرقام في صف واحد من خانات متساوية (`singleRow`)، فالعمود المالي يُقرأ أفقياً من
/// الإجمالي إلى المتبقي كما تُقرأ قائمة حساب.
/// Every figure sits on one row of equal cells (`singleRow`), so the money column reads
/// horizontally from the total to the balance, the way an account line is read.
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
        child: const TailoringInfoGrid(
          minCellWidth: 4000,
          children: [
            TailoringInfoTile(
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
          TailoringInfoGrid(
            singleRow: true,
            minCellWidth: 96,
            children: [
              TailoringInfoTile(
                label: 'الإجمالي',
                value: tailoringNumber(data.total),
                icon: Icons.summarize_rounded,
              ),
              TailoringInfoTile(
                label: 'الخصم',
                value: tailoringNumber(data.discount),
                icon: Icons.remove_circle_outline_rounded,
              ),
              TailoringInfoTile(
                label: 'الصافي',
                value: tailoringNumber(data.net),
                icon: Icons.calculate_rounded,
              ),
              TailoringInfoTile(
                label: 'المدفوع',
                value: tailoringNumber(data.paidTotal),
                icon: Icons.price_check_rounded,
              ),
              if (data.othersPayments != null && (data.othersPayments ?? 0) != 0)
                TailoringInfoTile(
                  label: 'مدفوعات أخرى',
                  value: tailoringNumber(data.othersPayments),
                  icon: Icons.add_card_rounded,
                ),
              TailoringInfoTile(
                label: data.balanceLabel,
                value: data.balanceValue,
                icon: Icons.account_balance_wallet_rounded,
                // الرصيد السالب دفعة مقدمة — لونه أخضر لأنه لصالح العميل لا عليه
                // A negative balance is an advance — green because it favours the customer.
                valueColor: data.isAdvance
                    ? AppColors.success
                    : (data.remaining == 0 ? AppColors.success : AppColors.error),
              ),
              if (data.currencyPrice != null && data.currencyPrice != 0)
                TailoringInfoTile(
                  label: 'سعر العملة',
                  value: tailoringNumber(data.currencyPrice, decimals: 2),
                  icon: Icons.currency_exchange_rounded,
                ),
              TailoringInfoTile(
                label: 'الاستحقاق',
                value: data.givingDate,
                icon: Icons.schedule_rounded,
              ),
              TailoringInfoTile(
                label: 'طريقة الدفع',
                value: data.paymentMethod,
                icon: Icons.credit_card_rounded,
              ),
              TailoringInfoTile(
                label: 'رقم السند',
                value: data.voucherNo,
                icon: Icons.receipt_rounded,
              ),
            ],
          ),
          // إشارة الرصيد السالب تُشرح صراحةً بدل ترك المستخدم يقرأ السالب خطأ
          // The negative balance is explained instead of leaving the sign to be misread.
          if (data.isAdvance) ...[
            const SizedBox(height: 3),
            Text(
              'دفع العميل أكثر من الصافي بمقدار ${data.balanceValue} — رصيد مقدم لصالحه',
              style: const TextStyle(fontSize: 10.5, color: AppColors.success),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
