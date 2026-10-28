import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import 'tailoring_section_card.dart';

/// القسم 2: بيانات العميل — من الـ VIEW، والعنوان والهاتف الثاني من صف SALES_BILL
/// Section 2: the customer data — from the view; address and second phone from SALES_BILL.
///
/// كل حقول العميل في صف واحد على الشاشات العريضة (`singleRow`)، وكل حقل في خانة مسوّرة
/// بعرض متساوٍ، فتُقرأ الكتلة كسطر بيانات واحد لا كفقرات متتابعة.
/// Every customer field sits on one row on wide screens (`singleRow`), each inside an equal,
/// bordered cell, so the block reads as a single data line rather than stacked paragraphs.
class BillCustomerCard extends StatelessWidget {
  final CuttingBillHeader header;

  const BillCustomerCard({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    return TailoringSectionCard(
      title: 'بيانات العميل',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      child: TailoringInfoGrid(
        singleRow: true,
        minCellWidth: 104,
        children: [
          TailoringInfoTile(
            label: 'الاسم',
            value: header.custName.isEmpty ? 'عميل غير مسمّى' : header.custName,
            icon: Icons.badge_rounded,
          ),
          TailoringInfoTile(
            label: 'الهاتف',
            value: header.telNo1,
            icon: Icons.phone_rounded,
          ),
          if (header.telNo2 != null)
            TailoringInfoTile(
              label: 'هاتف آخر',
              value: header.telNo2,
              icon: Icons.phone_iphone_rounded,
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
          if (header.address != null)
            TailoringInfoTile(
              label: 'العنوان',
              value: header.address,
              icon: Icons.location_on_rounded,
            ),
        ],
      ),
    );
  }
}
