import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_model_item.dart';
import 'tailoring_cells.dart';

/// القسم 4: الموديلات والمستفيدون — جدول مصغّر: رأس واحد ثم صف لكل موديل
/// Section 4: the models and beneficiaries — a mini table: one header, then a row per model.
///
/// رأس الأعمدة (الموديل · المستفيد · القطع · الملاحظة) يظهر **مرة واحدة**، وكل خلية داخل
/// `FittedBox` في سطر واحد: لا نصّ مخفي ولا «الق...» في الرأس — الخط يصغر ليتّسع النص كاملاً
/// مهما ضاقت المساحة أو كبر حجم الخط.
/// The column header (model · beneficiary · pieces · note) appears **once**, and every cell sits
/// in a one-line `FittedBox`: no hidden text and no "الق…" in the header — the font shrinks so
/// the whole text fits however narrow the width or large the type scale.
///
/// المستفيد الفارغ يعني أن الموديل للعميل نفسه، ولا يعني «لا بيانات»: يُعرض اسم العميل الأصلي
/// بدلاً من فراغ يوهم بفقدان المعلومة.
/// An empty beneficiary means the model belongs to the customer himself, not "no data": the
/// customer's own name is shown instead of a blank that looks like missing information.
class ModelSelectorStrip extends StatelessWidget {
  final List<CuttingModelItem> models;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// اسم العميل الأصلي — بديل المستفيد حين يكون الموديل للعميل نفسه
  /// The original customer name — the beneficiary fallback when the model is the customer's own.
  final String? customerName;

  const ModelSelectorStrip({
    super.key,
    required this.models,
    required this.selectedIndex,
    required this.onSelected,
    this.customerName,
  });

  /// أوزان الأعمدة: علامة الاختيار 22px · الموديل 2.4 · المستفيد 4 · القطع 1.4 · الملاحظة 4.2
  /// Column weights: a 22px selection mark · model 2.4 · beneficiary 4 · pieces 1.4 · note 4.2
  static const List<double> _weights = [2.4, 4.0, 1.4, 4.2];
  static const List<String> _headings = ['الموديل', 'المستفيد', 'القطع', 'الملاحظة'];

  /// عرض عمود علامة الصح في بداية السطر
  /// The width of the leading check-mark column.
  static const double _checkWidth = 24;

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

    // هل يحمل أي موديل مستفيداً خاصاً؟ العمود يظهر دائماً لكن قيمه تعود لاسم العميل عند الغياب
    // Does any model carry its own beneficiary? The column always shows; empty values fall back
    // to the customer's name.
    final fallback = _clean(customerName);

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: {
        0: const FixedColumnWidth(_checkWidth),
        for (var i = 0; i < _weights.length; i++)
          i + 1: FlexColumnWidth(_weights[i]),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: tailoringGridRule, width: 1),
        verticalInside: BorderSide(color: tailoringGridRule, width: 1),
      ),
      children: [
        // رأس الأعمدة — مرة واحدة فقط (العمود الأول لعلامة الاختيار بلا عنوان)
        // The column header — once only (the first column carries the mark, with no title).
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceSubtle),
          children: [
            const SizedBox.shrink(),
            for (final heading in _headings) _headerCell(heading),
          ],
        ),
        for (var i = 0; i < models.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i == selectedIndex
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : (i.isEven ? AppColors.surface : const Color(0xFFF7F9FB)),
            ),
            children: [
              // علامة صح في بداية سطر الموديل المحدد
              // A check mark at the start of the selected model's row.
              _checkCell(i == selectedIndex),
              _valueCell(
                i,
                _clean(models[i].typeName) ?? '—',
                color: AppColors.primary,
                weight: FontWeight.w800,
              ),
              // المستفيد، وإن غاب فاسم العميل الأصلي
              // The beneficiary, or the original customer's name when it is absent.
              _valueCell(
                i,
                _clean(models[i].beneficiary) ?? fallback ?? '—',
                color: _clean(models[i].beneficiary) == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
              _valueCell(i, '${models[i].piecesCount}', numeric: true),
              // ملاحظة الموديل من `MODEL_NOTES` في العرض فقط، وإن غابت تبقى الخلية فارغة
              // The model note comes from the view's `MODEL_NOTES` only; when absent the cell
              // stays empty (no placeholder, no bill note).
              _valueCell(i, _clean(models[i].specs.notes) ?? ''),
            ],
          ),
      ],
    );
  }

  /// خلية علامة الاختيار: صح أخضر للمحدد، وفراغ لغيره
  /// The selection cell: a green check for the chosen model, empty otherwise.
  Widget _checkCell(bool selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: selected
          ? Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: AppColors.success,
            )
          : const SizedBox.shrink(),
    );
  }

  /// خلية رأس: خط صغير عريض داخل تصغير تلقائي فلا يُقصّ العنوان
  /// A header cell: a small bold label inside automatic scaling so the title is never cut.
  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// خلية قيمة: سطر واحد يصغر خطّه ليتّسع النص كاملاً
  /// A value cell: one line whose font shrinks so the whole text fits.
  Widget _valueCell(
    int rowIndex,
    String text, {
    Color? color,
    FontWeight weight = FontWeight.w700,
    bool numeric = false,
  }) {
    return InkWell(
      onTap: () => onSelected(rowIndex),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Align(
          heightFactor: 1,
          alignment:
              numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                numeric ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: weight,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// النص الفارغ أو المزيّف بـ«لا يوجد» لا يُعدّ قيمة
  /// An empty text, or the legacy "لا يوجد", is not a value.
  static String? _clean(String? text) {
    final value = text?.trim();
    if (value == null || value.isEmpty || value == 'لا يوجد') return null;
    return value;
  }
}
