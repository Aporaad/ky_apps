import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tailoring/data/models/cutting_bill_detail_model.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/cutting_piece_item.dart';
import 'measurement_kit.dart';

/// القسم الأول: بيانات العميل ثم المستفيد/الموديل ثم الطلب — بلا تكرار للاسم
/// Section one: the customer, then the beneficiary and model, then the order — no repeated name.
///
/// اسم العميل يظهر أعلى الشاشة في شريط العنوان وحده، وإعادته داخل «بيانات العميل» كانت تجعل
/// نفس الكلمة مرتين في شاشة واحدة. وأرقام العميل الثلاثة (الهاتف، رقم العميل، رقم الحساب) في
/// صف واحد كما طُلب. والمستفيد الغائب يُخفى تماماً لا يُستبدل بنص اعتذاري.
/// The customer's name belongs to the screen title only; repeating it inside "customer data"
/// showed the same word twice on one screen. The three customer numbers sit on one row as
/// asked. And an absent beneficiary is hidden outright, not replaced by an apologetic label.
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
      icon: Icons.badge_rounded,
      accent: AppColors.accent,
      trailingText: header.referenceLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── العميل: صف واحد لا أكثر ────────────────────────────────────────
          MeasurementGroupLabel(text: 'العميل', color: AppColors.accent),
          MeasurementFieldGrid(
            singleRow: true,
            minCellWidth: 96,
            fields: [
              MeasurementField(
                label: 'رقم الهاتف',
                value: header.telNo1 ?? header.telNo2,
                icon: Icons.phone_rounded,
                numeric: true,
              ),
              MeasurementField(
                label: 'رقم العميل',
                value: header.custNo?.toString(),
                icon: Icons.tag_rounded,
                numeric: true,
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

          // ── المستفيد والموديل ─────────────────────────────────────────────
          MeasurementGroupLabel(
            text: 'المستفيد والموديل',
            color: AppColors.info,
          ),
          MeasurementFieldGrid(
            minCellWidth: 104,
            fields: [
              // لا مستفيد ⇒ لا خانة: الغياب يُخفى ولا يُعلَن
              // No beneficiary means no cell at all: absence is hidden, not announced.
              if (model?.beneficiary != null)
                MeasurementField(
                  label: 'اسم المستفيد',
                  value: model!.beneficiary,
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

          // ── الفاتورة والطلب ────────────────────────────────────────────────
          MeasurementGroupLabel(
            text: 'الفاتورة والطلب',
            color: AppColors.primary,
          ),
          MeasurementFieldGrid(
            minCellWidth: 104,
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
