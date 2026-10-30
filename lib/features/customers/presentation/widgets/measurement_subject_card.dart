import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_bill_detail_model.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/cutting_piece_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';
import 'measurement_kit.dart';

/// القسم الأول: التفاصيل الأساسية للعميل والمستفيد
/// Section one: the customer's and the beneficiary's basics.
///
/// مجموعات منفصلة بعناوين — «العميل» و«المستفيد والموديل» و«الفاتورة والطلب» — فالحقول المتجاورة
/// بلا تسمية مجموعة تُقرأ كتكتلة واحدة لا كسجل. وقد حُذفت الحقول التي لا معنى لها في هذا
/// السياق: العنوان، مجموعة الحساب، شكل الموديل، رقم الموديل، والفرع.
/// Fields are split under group captions — customer, beneficiary and model, bill and order —
/// because adjacent values without a caption read as one blob, not as a record. The fields with
/// no business here were dropped outright: address, account group, model shape, model number and
/// branch.
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
    return MeasurementSectionCard(
      title: 'بيانات العميل والمستفيد',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      subtitle: tailoringJoin([
        header.custName.isEmpty ? null : header.custName,
        model?.beneficiary,
      ]),
      trailing: MeasurementBadge(
        label: header.referenceLabel,
        color: AppColors.accent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeasurementGroupLabel(
            text: 'العميل',
            color: AppColors.accent,
          ),
          MeasurementFieldGrid(
            fields: [
              MeasurementField(
                label: 'اسم العميل',
                value: header.custName.isEmpty ? 'عميل غير مسمّى' : header.custName,
                icon: Icons.badge_rounded,
              ),
              MeasurementField(
                label: 'رقم العميل',
                value: header.custNo?.toString(),
                icon: Icons.tag_rounded,
                numeric: true,
              ),
              MeasurementField(
                label: 'الهاتف',
                // الهاتفان في خانة واحدة: خانة «هاتف آخر» فارغة تساوي صفًا مهدوراً
                // Both phones share one cell: an empty "second phone" cell is a wasted line.
                value: tailoringJoin(
                  [header.telNo1, header.telNo2],
                  separator: ' / ',
                ),
                icon: Icons.phone_rounded,
              ),
              MeasurementField(
                label: 'رقم الحساب',
                value: header.accNo?.toString(),
                icon: Icons.account_balance_rounded,
                numeric: true,
              ),
            ],
          ),
          const SizedBox(height: 10),

          MeasurementGroupLabel(
            text: 'المستفيد والموديل',
            color: AppColors.info,
          ),
          MeasurementFieldGrid(
            fields: [
              MeasurementField(
                label: 'المستفيد',
                // شرطة واحدة تُقرأ «لا بيانات»: تسمية الغياب أصدق من فراغ مبهم
                // A bare dash reads as "no data"; naming the absence is more honest.
                value: model?.beneficiary ?? 'بلا مستفيد محدّد',
                icon: Icons.person_outline_rounded,
              ),
              MeasurementField(
                label: 'نوع الموديل',
                value: model?.typeName,
                icon: Icons.checkroom_rounded,
              ),
              MeasurementField(
                label: 'عدد القطع',
                value: model == null ? null : '${model!.piecesCount}',
                icon: Icons.content_paste_rounded,
                numeric: true,
              ),
              MeasurementField(
                label: 'مرحلة الموديل',
                value: model?.stage.label,
                valueColor: _stageColor(model),
              ),
            ],
          ),
          const SizedBox(height: 10),

          MeasurementGroupLabel(
            text: 'الفاتورة والطلب',
            color: AppColors.primary,
          ),
          MeasurementFieldGrid(
            fields: [
              MeasurementField(
                label: 'تاريخ الفاتورة',
                value: header.date,
                icon: Icons.event_rounded,
              ),
              MeasurementField(
                label: 'الرقم اليدوي',
                value: header.manualBillNo?.toString(),
                numeric: true,
              ),
              MeasurementField(
                label: 'حالة السير',
                value: header.ordsName ??
                    (header.handingDone ? 'تم التسليم' : 'قيد التنفيذ'),
                valueColor: header.handingDone
                    ? AppColors.success
                    : AppColors.warning,
              ),
              if (header.givingDate != null)
                MeasurementField(
                  label: 'تاريخ الاستحقاق',
                  value: header.givingDate,
                  icon: Icons.event_available_rounded,
                ),
              if (header.refNo != null)
                MeasurementField(
                  label: 'مرجع الفاتورة',
                  value: header.refNo,
                ),
              if (header.details != null)
                MeasurementField(
                  label: 'البيان',
                  value: header.details,
                  icon: Icons.notes_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// لون المرحلة بلوحة التطبيق نفسها — لا لون مخترع للودجت
  /// The stage colour from the app palette, never a widget-local invention.
  Color? _stageColor(CuttingModelItem? model) {
    if (model == null) return null;

    return switch (model.stage) {
      CuttingPieceStage.delivered => AppColors.success,
      CuttingPieceStage.tailored => AppColors.info,
      CuttingPieceStage.cut => AppColors.warning,
      CuttingPieceStage.waiting => AppColors.textSecondary,
    };
  }
}
