import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/tailoring_parse.dart';

/// بطاقة فاتورة في قائمة الاختيار — بنفس شكل بطاقة العميل في شاشة «مقاسات العملاء»
/// A bill card in the selection list — the same shape as the customer card in the measurements
/// screen.
///
/// شريط لوني على الحافة اليمنى، مربّع رقم الفاتورة، اسم العميل بسطر عريض، سطر ثانوي
/// (التاريخ · الهاتف · اليدوي)، ثم عمود يمين بالعدّادات والصافي وسهم الفتح. كل التفاصيل
/// السابقة عادت ظاهرة، والبطاقة مفصولة عن أختها بمسافة لا بجدول.
/// An accent rail on the right edge, the bill number in a square, the customer's name in a bold
/// line, a secondary line (date · phone · manual), then a right column with the counters, the net
/// and an opening chevron. Every earlier detail is back and the cards are separated by spacing,
/// not by a table.
class BillListTile extends StatelessWidget {
  final CuttingBillSummary bill;
  final VoidCallback onTap;

  /// هل تُعرض خانات المال؟ (صلاحية `tailoring.payments_view` غير مطلوبة هنا لأن الصافي
  /// من الـ VIEW لا من SALES_BILL، لكن الشاشة المضيفة تُمرّر الرأي).
  /// Whether money fields are shown; the host screen passes its own decision.
  final bool showMoney;

  const BillListTile({
    super.key,
    required this.bill,
    required this.onTap,
    this.showMoney = true,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = bill.isDelivered ? AppColors.success : AppColors.warning;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط لوني يقول «هذه بطاقة تُفتح» بدل فراغ يُخمَّن
                // An accent rail says "this card opens" instead of leaving it to guesswork.
                Container(width: 4, color: AppColors.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        _numberSquare(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                bill.custName.isEmpty ? 'عميل غير مسمّى' : bill.custName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              _metaLine(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _counters(statusColor),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// مربّع رقم الفاتورة: الرقم كبير والرقم اليدوي تحته مباشرةً
  /// The bill-number square: the number large with the manual number right beneath it.
  Widget _numberSquare() {
    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${bill.billNo}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            'سنة ${bill.year}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// السطر الثانوي: التاريخ · الهاتف · الرقم اليدوي — كلها ظاهرة كما كانت
  /// The secondary line: date · phone · manual number — all visible as before.
  Widget _metaLine() {
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        if (bill.date != null)
          _meta(Icons.event_rounded, bill.date!),
        if (bill.telNo1 != null)
          _meta(Icons.phone_rounded, bill.telNo1!),
        if (bill.manualBillNo != null)
          _meta(Icons.tag_rounded, 'يدوي ${bill.manualBillNo}'),
      ],
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// عمود العدّادات: موديلات · قطع · صافي · حالة
  /// The counters column: models · pieces · net · state.
  Widget _counters(Color statusColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _badge('${bill.modelsCount} موديل', AppColors.info),
            const SizedBox(width: 4),
            _badge('${bill.piecesCount} قطعة', AppColors.secondary),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMoney && bill.net != null) ...[
              Text(
                tailoringNumber(bill.net),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 3),
            Text(
              bill.isDelivered ? 'مُسلَّمة' : 'قيد التنفيذ',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: statusColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
