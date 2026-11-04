import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../providers/items_providers.dart';
import '../providers/stores_providers.dart';

/// نموذج إضافة/تعديل صنف رئيسي
/// The add/edit main item form.
///
/// ── النمط (`styl_no`) إلزامي في هذا النموذج ولو كان عموده يقبل الفراغ: الـ VIEW
///    `ITEM_MOVEMENT_D` تربط `sanfs.styl_no = style.shape_style_no`، فصنف بلا نمط لا يدخل
///    أي حركة ولا أي رصيد — أي صنف «موجود وغير موجود» في الوقت نفسه.
/// ── The style is mandatory here even though its column allows null: the movement view joins
///    on sanfs.styl_no, so an item without a style enters no movement and no balance at all.
///
/// ── حقول الأصناف الفرعية تظهر عند الإنشاء فقط: التعديل لا يعيد كتابة أصناف موجودة، ولها
///    تبويبها المستقل في شاشة التفصيل.
/// ── The sub-item fields only appear on create: editing never rewrites existing sub items,
///    which have their own tab on the detail screen.
class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final ItemModel? item;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  late final TextEditingController _partNo = TextEditingController(
    text: widget.item?.partNo ?? '',
  );
  late final TextEditingController _name = TextEditingController(
    text: widget.item?.name ?? '',
  );
  late final TextEditingController _salePrice = TextEditingController(
    text: (widget.item?.salePrice ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _buyPrice = TextEditingController(
    text: (widget.item?.buyPrice ?? 0).toStringAsFixed(2),
  );
  late final TextEditingController _cap = TextEditingController(
    text: (widget.item?.cap ?? 1).toString(),
  );
  late final TextEditingController _code = TextEditingController(
    text: widget.item?.sanfCode ?? '',
  );
  late final TextEditingController _mainColor = TextEditingController(
    text: widget.item?.mainColor ?? '',
  );
  late final TextEditingController _len = TextEditingController(text: '0');
  late final TextEditingController _wid = TextEditingController(text: '0');
  late final TextEditingController _colorNo = TextEditingController(text: '0');
  late final TextEditingController _barcode = TextEditingController();

  int? _groupNo;
  int? _typeNo;
  int? _catNo;
  int? _unitNo;
  int? _styleNo;

  bool _saving = false;
  String? _formError;

  /// هل زُرعت الافتراضيات؟ تُزرع مرة واحدة بعد وصول المراجع، لا في كل بناء
  /// Were the defaults seeded? Seeded once after the reference arrives, never on every build.
  bool _seeded = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _groupNo = item?.groupNo;
    _typeNo = item?.typeNo;
    _catNo = item?.catNo;
    _unitNo = item?.unitNo;
    _styleNo = item?.styleNo;
  }

  @override
  void dispose() {
    _partNo.dispose();
    _name.dispose();
    _salePrice.dispose();
    _buyPrice.dispose();
    _cap.dispose();
    _code.dispose();
    _mainColor.dispose();
    _len.dispose();
    _wid.dispose();
    _colorNo.dispose();
    _barcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reference = ref.watch(storeReferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEdit ? 'تعديل صنف' : 'صنف جديد')),
      body: reference.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر تحميل المراجع: $error',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (refs) {
          // ── الافتراضيات تُزرع مرة واحدة فقط: إعادة زرعها في كل بناء تلغي ما اختاره المستخدم
          //    وتجعل القوائم تقفز من تحت يده.
          // ── Defaults are seeded exactly once: reseeding on every build would overwrite the
          //    user's own choices and make the lists jump underneath them.
          if (!_seeded) {
            _seeded = true;

            if (!_isEdit) {
              if (_groupNo == null && refs.groups.isNotEmpty) {
                _groupNo = refs.groups.first.groupNo;
              }

              if (_typeNo == null) {
                final groupTypes = refs.typesOfGroup(_groupNo);

                if (groupTypes.isNotEmpty) _typeNo = groupTypes.first.typeNo;
              }

              if (_styleNo == null) {
                final typeStyles = refs.stylesOfType(_typeNo);

                if (typeStyles.isNotEmpty) _styleNo = typeStyles.first.id;
              }

              if (_unitNo == null && refs.units.isNotEmpty) {
                _unitNo = refs.units.first.unitNo;
              }

              if (_catNo == null && refs.categories.isNotEmpty) {
                _catNo = refs.categories.first.id;
              }
            }
          }

          final types = refs.typesOfGroup(_groupNo);

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _text(_name, 'اسم الصنف *', Icons.inventory_2_outlined),
              const SizedBox(height: 10),
              _text(_partNo, 'كود الصنف (PART_NO) *', Icons.qr_code_rounded),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      _salePrice,
                      'سعر البيع *',
                      Icons.sell_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _text(
                      _buyPrice,
                      'سعر الشراء',
                      Icons.shopping_cart_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _dropdown<int>(
                label: 'المجموعة الرئيسية *',
                value: _groupNo,
                items: [
                  for (final group in refs.groups)
                    DropdownMenuItem(
                      value: group.groupNo,
                      child: Text(group.groupName),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _groupNo = value;
                  // التغيير يُسلسل افتراضاته: أول نوع ثم أول نمط تحته
                  // A change cascades its own defaults: the first type, then its first style.
                  final groupTypes = refs.typesOfGroup(value);
                  _typeNo = groupTypes.isEmpty ? null : groupTypes.first.typeNo;

                  final typeStyles = refs.stylesOfType(_typeNo);
                  _styleNo = typeStyles.isEmpty ? null : typeStyles.first.id;
                }),
              ),
              const SizedBox(height: 10),
              _dropdown<int>(
                label: 'المجموعة الفرعية *',
                value: _typeNo,
                items: [
                  for (final type in types)
                    DropdownMenuItem(
                      value: type.typeNo,
                      child: Text(type.typeName),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _typeNo = value;
                  final typeStyles = refs.stylesOfType(value);
                  _styleNo = typeStyles.isEmpty ? null : typeStyles.first.id;
                }),
              ),
              const SizedBox(height: 10),
              _dropdown<int>(
                label: 'الفئة',
                value: _catNo,
                items: [
                  for (final category in refs.categories)
                    DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                ],
                onChanged: (value) => setState(() => _catNo = value),
              ),
              const SizedBox(height: 10),
              _dropdown<int>(
                label: 'الوحدة *',
                value: _unitNo,
                items: [
                  for (final unit in refs.units)
                    DropdownMenuItem(
                      value: unit.unitNo,
                      child: Text(unit.unitName),
                    ),
                ],
                onChanged: (value) => setState(() => _unitNo = value),
              ),
              const SizedBox(height: 10),
              // النمط يُختار من STYLE التابع للنوع — وهو شرط ظهور الصنف في الحركة
              // The style comes from STYLE for the chosen type — the condition that makes
              // the item appear in movement at all.
              _dropdown<int>(
                label: 'النمط * — شرط ظهور الصنف في الحركة',
                value: _styleNo,
                items: [
                  for (final style in refs.stylesOfType(_typeNo))
                    DropdownMenuItem(
                      value: style.id,
                      child: Text(style.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _styleNo = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _text(
                      _cap,
                      'معامل التحويل',
                      Icons.straighten_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _text(_code, 'الرمز', Icons.tag_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _text(_mainColor, 'اللون الأساسي', Icons.palette_outlined),
              if (!_isEdit) ...[
                const SizedBox(height: 18),
                Text(
                  'أول صنف فرعي (باركود/لون/مقاس)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مطلوب — كل سطر مستند يشير إلى صنف فرعي، وبلا صنف فرعي لا يظهر الصنف في الأرصدة.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _text(
                        _len,
                        'الطول',
                        Icons.swap_horiz_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _text(
                        _wid,
                        'العرض',
                        Icons.swap_vert_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _text(
                        _colorNo,
                        'رقم اللون',
                        Icons.color_lens_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _text(_barcode, 'الباركود', Icons.qr_code_2_rounded),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 11.5),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 17),
                      label: const Text('حفظ'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _text(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  /// القائمة المنسدلة الآمنة — قيمة غير موجودة بين العناصر تُعامل كغير مختارة
  /// The safe dropdown — a value absent from the items is treated as unselected.
  ///
  /// ── هذا هو سبب انهيار شاشة «صنف جديد»: `DropdownButtonFormField` يتحقق في `assert` بأن
  ///    القيمة موجودة **مرة واحدة بالضبط** بين عناصره. أي قيمة من بيانات قديمة أو من مجموعة
  ///    لم تعد تُرجع أنواعاً كانت تُسقط الـ assert فيظهر خطأ فوري وتخرج الشاشة.
  /// ── This is what crashed the "new item" screen: DropdownButtonFormField asserts its value
  ///    appears *exactly once* among its items. Any stale value — or a group that returns no
  ///    types — tripped the assert, so the screen threw immediately on open.
  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    final matched = value != null &&
        items.where((item) => item.value == value).length == 1;

    return DropdownButtonFormField<T>(
      value: matched ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final partNo = _partNo.text.trim();

    if (name.isEmpty || partNo.isEmpty) {
      setState(() => _formError = 'اسم الصنف وكوده مطلوبان');

      return;
    }

    if (_typeNo == null || _unitNo == null || _styleNo == null) {
      setState(
        () => _formError =
            'المجموعة الفرعية والوحدة والنمط مطلوبة — النمط شرط ظهور الصنف في الحركة',
      );

      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = <String, dynamic>{
      'sanf_name': name,
      'part_no': partNo,
      'sanf_price': double.tryParse(_salePrice.text.trim()) ?? 0,
      'buy_price': double.tryParse(_buyPrice.text.trim()) ?? 0,
      'unit_no': _unitNo,
      'group_no': _groupNo,
      'type_no': _typeNo,
      'cat_no': _catNo,
      'styl_no': _styleNo,
      'cap': double.tryParse(_cap.text.trim()) ?? 1,
      'sanf_code': _code.text.trim(),
      if (_mainColor.text.trim().isNotEmpty) 'mcolor': _mainColor.text.trim(),
      if (!_isEdit) ...{
        'len': double.tryParse(_len.text.trim()) ?? 0,
        'wid': double.tryParse(_wid.text.trim()) ?? 0,
        'color_no': int.tryParse(_colorNo.text.trim()) ?? 0,
        'barcode': _barcode.text.trim(),
      },
    };

    final repository = ref.read(storeItemsRepositoryProvider);
    final result = _isEdit
        ? await repository.updateItem(widget.item!.sanfNo, payload)
        : await repository.createItem(payload);

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.success) {
      ref.invalidate(storeReferenceProvider);
      ref.read(itemsListProvider.notifier).refreshCurrent();
      Navigator.pop(context);
    } else {
      setState(() => _formError = result.displayMessage);
    }
  }
}
