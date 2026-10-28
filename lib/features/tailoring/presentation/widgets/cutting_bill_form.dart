import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/presentation/widgets/customer_picker_screen.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_piece_item.dart';
import '../../data/models/tailoring_reference_model.dart';
import 'tailoring_section_card.dart';

/// نموذج فاتورة التفصيل — نموذج أولي للقراءة فقط
/// The cutting-bill form — a read-only prototype.
///
/// الحقول كلها حقيقية الشكل ومربوطة بقواميس النظام (الأنواع والأشكال وتسميات المقاسات)،
/// لكن لا شيء يُحفظ: زر الحفظ معطّل بصراحة، ولا يُرسل أي طلب إلى الخادم.
/// The fields mirror the real shape and are wired to the system dictionaries (types, shapes,
/// measurement labels), but nothing is ever saved: the save button is plainly disabled and no
/// request leaves the device.
///
/// التشغيل المحلي للحقول ليس حفظاً: اختيار نوع أو كتابة مقاس يبقى في حالة الواجهة فقط.
/// Local interaction is not persistence: picking a type or typing a measurement lives in the
/// widget state only.
class CuttingBillForm extends StatefulWidget {
  /// تفصيل فاتورة موجود — يُعبَّأ النموذج منه في وضع التعديل
  /// An existing bill's detail — the form pre-fills from it in edit mode.
  final CuttingBillDetail? initial;

  /// مرجعيات الأنواع والأشكال والتسميات
  /// The types, shapes and labels reference data.
  final TailoringReference reference;

  /// نص الشريط الثابت أسفل النموذج
  /// The fixed bar's text at the bottom of the form.
  final String footerNote;

  const CuttingBillForm({
    super.key,
    this.initial,
    this.reference = TailoringReference.empty,
    required this.footerNote,
  });

  @override
  State<CuttingBillForm> createState() => _CuttingBillFormState();
}

class _CuttingBillFormState extends State<CuttingBillForm> {
  // ── بيانات الفاتورة / the bill data ──
  late final TextEditingController _manualNo;
  late final TextEditingController _date;
  late final TextEditingController _refNo;
  late final TextEditingController _details;
  late final TextEditingController _customer;

  bool _urgent = false;
  CustomerModel? _pickedCustomer;

  // ── الموديلات / the models ──
  late List<_FormModel> _models;
  int _selectedModel = 0;

  @override
  void initState() {
    super.initState();

    final header = widget.initial?.header;
    _manualNo = TextEditingController(text: header?.manualBillNo?.toString() ?? '');
    _date = TextEditingController(text: header?.date ?? '');
    _refNo = TextEditingController(text: header?.refNo ?? '');
    _details = TextEditingController(text: header?.details ?? '');
    _customer = TextEditingController(text: header?.custName ?? '');
    _urgent = header?.urgent ?? false;

    final existing = widget.initial?.models ?? const <CuttingModelItem>[];
    _models = existing.isEmpty
        ? [_FormModel.empty()]
        : existing.map(_FormModel.fromModel).toList();
  }

  @override
  void dispose() {
    _manualNo.dispose();
    _date.dispose();
    _refNo.dispose();
    _details.dispose();
    _customer.dispose();
    for (final model in _models) {
      model.dispose();
    }
    super.dispose();
  }

  /// اختيار عميل من الشاشة الموجودة — يملأ الاسم فقط (نموذج أولي بلا حفظ)
  /// Pick a customer from the existing screen — fills the name only (prototype, no save).
  Future<void> _pickCustomer() async {
    final picked = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder: (_) => const CustomerPickerScreen(
          title: 'اختر العميل',
          subtitle: 'ابحث بالاسم أو الرقم لاختيار صاحب الفاتورة',
          icon: Icons.person_search_rounded,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _pickedCustomer = picked;
      _customer.text = picked.custName;
    });
  }

  /// إضافة موديل معطّلة في النموذج الأولي — تُشرح بدل تعطيل صامت
  /// Adding a model is disabled in the prototype — explained instead of silently dead.
  void _addModelDisabled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('إضافة موديل غير مفعّلة في النموذج الأولي'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _models[_selectedModel];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPrototypeBanner(),
          const SizedBox(height: 12),
          _buildCustomerSection(),
          const SizedBox(height: 12),
          _buildOrderSection(),
          const SizedBox(height: 12),
          _buildModelsSection(model),
          const SizedBox(height: 12),
          _buildMeasurementsSection(model),
          const SizedBox(height: 12),
          _buildFabricsSection(model),
        ],
      ),
    );
  }

  /// شريط النموذج الأولي: إفصاح صريح أن الحفظ غير مفعّل
  /// The prototype banner: a plain disclosure that saving is off.
  Widget _buildPrototypeBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.construction_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'نموذج أولي — الحفظ غير مفعّل ولا تُكتب أي بيانات في النظام',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return TailoringSectionCard(
      title: 'العميل',
      icon: Icons.person_rounded,
      accent: AppColors.accent,
      trailing: widget.initial == null
          ? null
          : TailoringChip(
              label: 'رقم العميل',
              value: widget.initial!.header.custNo?.toString(),
              color: AppColors.accent,
            ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _field(
                  'اسم العميل',
                  _customer,
                  readOnly: true,
                  hint: 'لم يُحدَّد عميل',
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickCustomer,
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('اختيار', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.border),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          if (_pickedCustomer != null && _pickedCustomer!.tel1 != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _pickedCustomer!.tel1!,
                  style:  TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSection() {
    return TailoringSectionCard(
      title: 'بيانات الطلب',
      icon: Icons.description_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _field('الرقم اليدوي', _manualNo, numeric: true)),
              const SizedBox(width: 8),
              Expanded(child: _field('التاريخ', _date, hint: 'يوم/شهر/سنة')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('مرجع الفاتورة', _refNo)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                       Text(
                        'مستعجل',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Switch(
                        value: _urgent,
                        onChanged: (v) => setState(() => _urgent = v),
                        activeColor: AppColors.warning,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field('البيان', _details, maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildModelsSection(_FormModel model) {
    return TailoringSectionCard(
      title: 'الموديلات والمستفيدون',
      icon: Icons.checkroom_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TailoringChip(label: '${_models.length} موديل', color: AppColors.primary),
          const SizedBox(width: 6),
          InkWell(
            onTap: _addModelDisabled,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 13, color: AppColors.textMuted),
                  SizedBox(width: 3),
                  Text(
                    'إضافة',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار الموديل للتحرير — نفس نمط شاشة الاستعراض
          // Picking the model to edit — the same pattern as the view screen.
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var i = 0; i < _models.length; i++)
                ChoiceChip(
                  label: Text(
                    'موديل ${_models[i].seqNo}',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  selected: i == _selectedModel,
                  onSelected: (_) => setState(() => _selectedModel = i),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _field('اسم المستفيد', model.beneficiary),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _typePicker(model)),
              const SizedBox(width: 8),
              Expanded(child: _shapePicker(model)),
            ],
          ),
          // مقاسات الموديل الأصلية تظهر للقراءة عند التعديل بلا حقول جديدة
          // The original measurements show read-only when editing, with no extra fields.
          if (model.originalPiecesCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'قطع هذا الموديل في النظام: ${model.originalPiecesCount}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typePicker(_FormModel model) {
    final types = widget.reference.activeTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الموديل',
          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        DropdownButtonFormField<int>(
          value: model.typeNo,
          isDense: true,
          style:  TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          decoration: _inputDecoration(),
          items: types
              .map(
                (type) => DropdownMenuItem<int>(
                  value: type.typeNo,
                  child: Text(
                    type.typeName ?? 'نوع ${type.typeNo}',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            model.typeNo = value;
            model.shapeStyleNo = null;
          }),
        ),
      ],
    );
  }

  Widget _shapePicker(_FormModel model) {
    final styles = widget.reference.stylesForType(model.typeNo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شكل الموديل',
          style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        DropdownButtonFormField<int>(
          value: model.shapeStyleNo,
          isDense: true,
          style:  TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
          decoration: _inputDecoration(),
          items: styles
              .map(
                (style) => DropdownMenuItem<int>(
                  value: style.shapeStyleNo,
                  child: Text(
                    style.styleName ?? 'شكل ${style.shapeStyleNo}',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => model.shapeStyleNo = value),
        ),
      ],
    );
  }

  Widget _buildMeasurementsSection(_FormModel model) {
    return TailoringSectionCard(
      title: 'المقاسات',
      icon: Icons.straighten_rounded,
      accent: AppColors.info,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final columns = constraints.maxWidth < 420
              ? 2
              : (constraints.maxWidth < 720 ? 3 : 4);
          final keys = [for (var i = 1; i <= 12; i++) 'L$i'];

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in keys)
                SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelFor(key),
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      TextField(
                        controller: model.measurements[key],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(fontSize: 12.5),
                        decoration: _inputDecoration(hint: '—'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// تسمية المقياس الحقيقية من GENERAL_LABELS_CODING مع الرجوع إلى مفتاحه
  /// The real measurement label from GENERAL_LABELS_CODING, falling back to its key.
  String _labelFor(String key) {
    final label = widget.reference.measureLabels[key];
    return (label == null || label.trim().isEmpty) ? key : label;
  }

  Widget _buildFabricsSection(_FormModel model) {
    final pieces = model.originalPieces;

    return TailoringSectionCard(
      title: 'الأقمشة',
      icon: Icons.dry_cleaning_rounded,
      accent: AppColors.accentLight,
      child: pieces.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'إضافة الأقمشة غير مفعّلة في النموذج الأولي',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          : Column(
              children: [
                for (final piece in pieces)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.checkroom_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${piece.clothName ?? 'قماش غير محدد'}'
                            '${piece.colorText == null ? '' : ' — ${piece.colorText}'}',
                            style:  TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          piece.hasTailor ? piece.tailorName! : 'غير مسند',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surfaceSubtle,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    bool numeric = false,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: TextStyle(
            fontSize: 12.5,
            color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
          ),
          decoration: _inputDecoration(hint: hint),
        ),
      ],
    );
  }
}

/// موديل داخل النموذج: حقوله الخاصة وحالته
/// A model inside the form: its own fields and state.
class _FormModel {
  final int seqNo;
  final TextEditingController beneficiary;
  final Map<String, TextEditingController> measurements;

  /// قطع الموديل كما هي في النظام — تُعرض للقراءة في قسم الأقمشة عند التعديل
  /// The model's pieces as stored — shown read-only in the fabrics section when editing.
  final List<CuttingPieceItem> originalPieces;

  int? typeNo;
  int? shapeStyleNo;

  _FormModel({
    required this.seqNo,
    required this.beneficiary,
    required this.measurements,
    this.originalPieces = const [],
    this.typeNo,
    this.shapeStyleNo,
  });

  /// نموذج فارغ للإضافة — 12 خانة مقاس بلا قيم
  /// An empty model for the add flow — twelve blank measurement slots.
  factory _FormModel.empty() {
    return _FormModel(
      seqNo: 1,
      beneficiary: TextEditingController(),
      measurements: {
        for (var i = 1; i <= 12; i++) 'L$i': TextEditingController(),
      },
    );
  }

  /// نموذج مُعبّأ من موديل حقيقي — وضع التعديل
  /// A model filled from a real one — the edit flow.
  factory _FormModel.fromModel(CuttingModelItem model) {
    return _FormModel(
      seqNo: model.seqNo,
      beneficiary: TextEditingController(text: model.beneficiary ?? ''),
      measurements: {
        for (var i = 1; i <= 12; i++)
          'L$i': TextEditingController(
            text: _measureText(model.measurements['L$i']),
          ),
      },
      originalPieces: model.pieces,
      typeNo: model.shapeStyleNo,
      shapeStyleNo: model.shapeStyleNo,
    );
  }

  /// المقاس نصاً بلا كسور زائدة — 58 لا 58.0
  /// The measurement as text without stray decimals — 58 rather than 58.0.
  static String _measureText(double? value) {
    if (value == null) return '';
    final isWhole = value == value.roundToDouble();
    return isWhole ? value.toInt().toString() : value.toString();
  }

  /// عدد القطع الأصلية
  /// The original piece count.
  int get originalPiecesCount => originalPieces.length;

  void dispose() {
    beneficiary.dispose();
    for (final controller in measurements.values) {
      controller.dispose();
    }
  }
}
