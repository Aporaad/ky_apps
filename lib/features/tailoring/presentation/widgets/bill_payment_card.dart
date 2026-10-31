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
/// الأرقام الأساسية فقط في صف واحد: الإجمالي · الخصم · الصافي · المدفوع · المتبقي · رقم
/// السند (والمدفوعات الأخرى عند وجودها). حُذفت سعر العملة والاستحقاق وطريقة الدفع بطلب
/// المستخدم.
/// Only the core figures on one row: total · discount · net · paid · balance · voucher (plus
/// other payments when present). The currency price, due date and payment method were removed
/// at the user's request.
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
            minCellWidth:50,
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
              TailoringInfoTile(
                label: 'رقم السند',
                value: data.voucherNo,
                icon: Icons.receipt_rounded,
              ),
            ],
          ),                    
        ],
      ),
    );
  }
}
