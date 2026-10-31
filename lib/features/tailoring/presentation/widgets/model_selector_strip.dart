import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';

/// القسم 4: الموديلات والمستفيدون — جدول مصغّر: رأس واحد ثم صف لكل موديل
/// Section 4: the models and beneficiaries — a mini table: one header, then a row per model.
///
/// رأس الأعمدة (الموديل · المستفيد · القطع · الملاحظة) يظهر **مرة واحدة** أعلى القائمة، وكل
/// موديل في سطر: اسم نوعه فقط (قطري/حجازي/عماني…) · المستفيد إن وُجد · عدد القطع · ملاحظته.
/// حُذف رقم الموديل وكلمة «موديل» وحقل المرحلة بطلب المستخدم، والمستفيد الفارغ لا يُعرض له
/// شيء أصلاً.
/// The column header (model · beneficiary · pieces · note) appears **once** at the top, and each
/// model occupies one row: its type name only (Qatari/Hejazi/Omani…), the beneficiary when it
/// exists, the piece count and its note. The model number, the word "موديل" and the stage column
/// were removed at the user's request, and an empty beneficiary shows nothing at all.
class ModelSelectorStrip extends StatelessWidget {
  final List<CuttingModelItem> models;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ModelSelectorStrip({
    super.key,
    required this.models,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return Text(
        'لا توجد موديلات في هذه الفاتورة',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }

    // هل يحمل أي موديل مستفيداً؟ العمود يظهر فقط إن كان له وجود
    // Does any model carry a beneficiary? The column only exists when it is populated.
    final hasBeneficiary = models.any((m) => _clean(m.beneficiary) != null);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _headerRow(hasBeneficiary),
          for (var i = 0; i < models.length; i++) ...[
            Container(height: 0.7, color: AppColors.border),
            _ModelRow(
              model: models[i],
              selected: i == selectedIndex,
              showBeneficiary: hasBeneficiary,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }

  /// رأس الأعمدة: يظهر مرة واحدة فقط أعلى القائمة
  /// The column header: rendered once above the list.
  Widget _headerRow(bool hasBeneficiary) {
    return Container(
      color: AppColors.surfaceSubtle,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _head('الموديل')),
            _divider(),
            if (hasBeneficiary) ...[
              Expanded(flex: 5, child: _head('المستفيد')),
              _divider(),
            ],
            Expanded(flex: 2, child: _head('القطع')),
            _divider(),
            Expanded(flex: 6, child: _head('الملاحظة')),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  Widget _head(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _divider() =>
      Container(width: 0.7, color: AppColors.border.withValues(alpha: 0.9));

  /// النص الفارغ أو المزيّف بـ«لا يوجد» لا يُعدّ قيمة
  /// An empty text, or the legacy "لا يوجد", is not a value.
  static String? _clean(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty || value == 'لا يوجد') return null;
    return value;
  }
}

class _ModelRow extends StatelessWidget {
  final CuttingModelItem model;
  final bool selected;
  final bool showBeneficiary;
  final VoidCallback onTap;

  const _ModelRow({
    required this.model,
    required this.selected,
    required this.showBeneficiary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final beneficiary = ModelSelectorStrip._clean(model.beneficiary);
    final typeName = ModelSelectorStrip._clean(model.typeName) ?? '—';
    final note = ModelSelectorStrip._clean(model.specs.notes) ?? '—';

    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _cell(
                  typeName,
                  color: AppColors.primary,
                  weight: FontWeight.w800,
                ),
              ),
              _divider(),
              if (showBeneficiary) ...[
                Expanded(
                  flex: 5,
                  child: _cell(beneficiary ?? '—'),
                ),
                _divider(),
              ],
              Expanded(flex: 2, child: _cell('${model.piecesCount}')),
              _divider(),
              Expanded(flex: 6, child: _cell(note)),
              // علامة الاختيار: الأولوية للون والخط، والعلامة تأكيد بصري
              // The selection mark: colour and weight lead, the check confirms.
              SizedBox(
                width: 18,
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: AppColors.primary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: weight,
            color: color ?? AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 0.7, color: AppColors.border.withValues(alpha: 0.9));
}
