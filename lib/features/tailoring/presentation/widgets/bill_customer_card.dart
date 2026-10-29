import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import 'tailoring_section_card.dart';

/// القسم 2: بيانات العميل — الاسم بجانب عنوان القسم، وثلاثة حقول في سطر واحد
/// Section 2: the customer data — the name beside the section title, three fields on one line.
///
/// اسم العميل في شريط العنوان نفسه (trailing) لأنه هوية القسم، ثم صف واحد: الهاتف · رقم
/// العميل · رقم الحساب. العنوان حُذف بطلب المستخدم.
/// The customer's name sits in the title bar itself (trailing) because it is the section's
/// identity, then one row: phone · customer number · account number. The address was removed
/// at the user's request.
class BillCustomerCard extends StatelessWidget {
  final CuttingBillHeader header;

  const BillCustomerCard({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    final name = header.custName.isEmpty ? 'عميل غير مسمّى' : header.custName;

    return TailoringSectionCard(
      title: 'بيانات العميل',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      // الاسم بجانب العنوان: خط ثقيل ولون أساسي ليُقرأ قبل أي رقم
      // The name beside the title: a heavy weight and the primary colour so it reads first.
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
        ),
      ),
      child: TailoringInfoGrid(
        singleRow: true,
        minCellWidth: 104,
        children: [
          TailoringInfoTile(
            label: 'الهاتف',
            value: header.telNo1,
            icon: Icons.phone_rounded,
          ),
          TailoringInfoTile(
            label: 'رقم العميل',
            value: header.custNo?.toString(),
            icon: Icons.person_outline_rounded,
          ),
          TailoringInfoTile(
            label: 'رقم الحساب',
            value: header.accNo?.toString(),
            icon: Icons.account_balance_rounded,
          ),
        ],
      ),
    );
  }
}
