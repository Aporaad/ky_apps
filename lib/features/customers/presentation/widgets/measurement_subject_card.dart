import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_bill_detail_model.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/presentation/widgets/tailoring_section_card.dart';

/// القسم 1: التفاصيل الأساسية للعميل والمستفيد في كتلة واحدة
/// Section 1: the customer's and the beneficiary's basics in a single block.
///
/// الطلب كان «التفاصيل الأساسية للعميل/المستفيد» لا قسمين، فمَن أُخذت مقاساته (المستفيد)
/// ومَن الفاتورة باسمه (العميل) يظهران معاً: قد يختلفان، وفصلهما كان يجبر القارئ على المطابقة
/// بعينيه بين كتلتين.
/// The request was "the customer's/beneficiary's basics", not two sections, so the measured
/// person and the paying party appear together: they can differ, and splitting them would force
/// the eye to cross-check two blocks.
///
/// كل حقل في خانة الشبكة نفسها (`TailoringInfoGrid`) التي تستخدمها بقية تقارير التطبيق، فلا
/// شكل موازٍ لهذا القسم.
/// Every field sits in the same `TailoringInfoGrid` the app's other reports use — no parallel
/// styling for this section.
class MeasurementSubjectCard extends StatelessWidget {
  final CuttingBillHeader header;
  final CuttingModelItem? model;

  const MeasurementSubjectCard({
    super.key,
    required this.header,
    this.model,
  });

  @override
  Widget build(BuildContext context) {
    return TailoringSectionCard(
      title: 'بيانات العميل والمستفيد',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      trailing: TailoringChip(
        label: header.referenceLabel,
        color: AppColors.primary,
      ),
      child: TailoringInfoGrid(
        minCellWidth: 104,
        children: [
          // ── العميل / the customer ──────────────────────────────────────────
          TailoringInfoTile(
            label: 'العميل',
            value: header.custName.isEmpty ? 'عميل غير مسمّى' : header.custName,
            icon: Icons.badge_rounded,
          ),
          TailoringInfoTile(
            label: 'رقم العميل',
            value: header.custNo?.toString(),
            icon: Icons.tag_rounded,
          ),
          TailoringInfoTile(
            label: 'الهاتف',
            value: header.telNo1 ?? header.telNo2,
            icon: Icons.phone_rounded,
          ),
          if (header.telNo2 != null && header.telNo1 != null)
            TailoringInfoTile(
              label: 'هاتف آخر',
              value: header.telNo2,
              icon: Icons.phone_iphone_rounded,
            ),
          if (header.address != null)
            TailoringInfoTile(
              label: 'العنوان',
              value: header.address,
              icon: Icons.location_on_rounded,
            ),
          TailoringInfoTile(
            label: 'رقم الحساب',
            value: header.accNo?.toString(),
            icon: Icons.account_balance_rounded,
          ),
          if (header.groupNo != null)
            TailoringInfoTile(
              label: 'مجموعة الحساب',
              value: '${header.groupNo}',
            ),

          // ── المستفيد والموديل / the beneficiary and the model ──────────────
          TailoringInfoTile(
            label: 'المستفيد',
            // شرطة واحدة تُقرأ «لا بيانات»: الاسم الحرفي أصدق من فراغ مُبهَم
            // A bare dash reads as "no data"; naming the absence is more honest.
            value: model?.beneficiary ?? 'بلا مستفيد محدّد',
            icon: Icons.person_outline_rounded,
          ),
          TailoringInfoTile(
            label: 'نوع الموديل',
            value: model?.typeName,
            icon: Icons.checkroom_rounded,
          ),
          if (model?.shapeName != null)
            TailoringInfoTile(
              label: 'شكل الموديل',
              value: model?.shapeName,
              icon: Icons.category_rounded,
            ),
          TailoringInfoTile(
            label: 'رقم الموديل',
            value: model == null ? null : '${model!.seqNo}',
          ),
          TailoringInfoTile(
            label: 'عدد القطع',
            value: model == null ? null : '${model!.piecesCount}',
          ),

          // ── الفاتورة والحالة / the bill and its stage ──────────────────────
          TailoringInfoTile(
            label: 'تاريخ الفاتورة',
            value: header.date,
            icon: Icons.event_rounded,
          ),
          TailoringInfoTile(
            label: 'الرقم اليدوي',
            value: header.manualBillNo?.toString(),
          ),
          TailoringInfoTile(
            label: 'الحالة',
            value: header.ordsName ?? (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
            valueColor: header.handingDone ? AppColors.success : AppColors.warning,
          ),
          if (header.branchNo != null)
            TailoringInfoTile(label: 'الفرع', value: header.branchLabel),
          if (header.givingDate != null)
            TailoringInfoTile(
              label: 'تاريخ الاستحقاق',
              value: header.givingDate,
              icon: Icons.event_available_rounded,
            ),
        ],
      ),
    );
  }
}
