import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import 'tailoring_cells.dart';
import 'tailoring_section_card.dart';

/// القسم 2: بيانات العميل — الاسم بجانب العنوان، وثلاثة حقول في **سطر واحد دائماً**
/// Section 2: the customer data — the name beside the title and three fields on **one row always**.
///
/// «سطر واحد» ليست رجاءً بل قاعدة: الشبكة تُطلب بـ`rows: 1`، فعدد الأعمدة يُحسب من عدد
/// الحقول لا من عرض الشاشة، وكل قيمة داخل `FittedBox` تصغّر خطّها ليتّسع النص كاملاً بدل
/// أن يختفي أو يلتفّ. النتيجة سطر واحد على 320 و360 و1024 مهما كبر حجم الخط.
/// "One row" is a rule, not a wish: the grid is asked for `rows: 1`, so the column count comes
/// from the field count rather than the screen width, and every value sits in a `FittedBox` that
/// shrinks its font so the whole text fits instead of vanishing or wrapping. One row at 320,
/// 360 and 1024 no matter how large the text scale is.
class BillCustomerCard extends StatelessWidget {
  final CuttingBillHeader header;

  /// فتح كشف حساب العميل عند النقر على اسمه — `null` لمن لا يملك الصلاحية
  /// Opens the customer's statement when the name is tapped; `null` without the grant, so the
  /// name simply stays plain text.
  final VoidCallback? onStatementTap;

  const BillCustomerCard({super.key, required this.header, this.onStatementTap});

  @override
  Widget build(BuildContext context) {
    final name = header.custName.isEmpty ? 'عميل غير مسمّى' : header.custName;
    final tappable = onStatementTap != null;

    return TailoringSectionCard(
      title: 'بيانات العميل',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      // الاسم ملتصق بالعنوان مباشرةً ولا يُقصّ: يُصغَّر خطّه عند الضيق
      // The name is glued to the title and never clipped: its font shrinks when space is tight.
      titleTrailing: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: tappable
            // اختصار انتقال: النقر على الاسم يفتح كشف حساب العميل
            // A navigation shortcut: tapping the name opens the customer's statement.
            ? InkWell(
                onTap: onStatementTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        name,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Text(
                name,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
      ),
      child: TailoringCellGrid(
        // سطر واحد دائم مهما ضاق العرض أو كبر الخط
        // Always one row however narrow the width or large the type scale.
        rows: 1,
        minCellWidth: 84,
        cells: [
          TailoringCell(
            label: 'الهاتف',
            value: header.telNo1,
            icon: Icons.phone_rounded,
          ),
          TailoringCell(
            label: 'رقم العميل',
            value: header.custNo?.toString(),
            icon: Icons.person_outline_rounded,
          ),
          TailoringCell(
            label: 'رقم الحساب',
            value: header.accNo?.toString(),
            icon: Icons.account_balance_rounded,
            numeric: true,
          ),
        ],
      ),
    );
  }
}
