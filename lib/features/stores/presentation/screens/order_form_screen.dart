import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json_value_utils.dart';
import '../../data/models/item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/models/store_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/orders_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/store_document_layout.dart';
import '../widgets/order_line_editor.dart';
import '../widgets/store_ui.dart';

/// نموذج إنشاء/تعديل مستند مخزني — بترتيب خانات النظام المكتبي نفسه
/// The create/edit form for a stock document — laid out in the desktop form's own order.
///
/// ── لماذا هذا الترتيب وليس «نموذجاً أحدث»؟ لأن من يُدخل هذه المستندات اليوم يعمل على شاشة
///    النظام المكتبي، وقد حفظ موضع كل خانة بعينه: رقم الفاتورة ونوعها يميناً، ثم التاريخ، ثم
///    المخزن وحسابه، ثم صفا العملة، ثم اختيار العملة المحاسبية، ثم البيان، ثم السطور بأعمدتها،
///    ثم المجاميع، ثم ذيل الإدخال والتعديل. أي ترتيب آخر يجبر المستخدم على البحث عن الحقل بدل
///    أن يمدّ يده إليه — والخطأ في حقل مالي ليس إزعاجاً بل قيد خاطئ في المخزون.
/// ── Why this order rather than a "modern" form? The people entering these documents work on
///    the desktop screen today and have memorised every box: bill number and type first, then
///    the date, then the store and its account, then the two currency rows, then which currency
///    the amounts are reckoned in, then the description, then the lines grid, then totals, then
///    the entry/edit audit strip. Any other order makes the user hunt for a field instead of
///    reaching for it — and a wrong field here is not an annoyance but a bad stock posting.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, required this.kind, this.billNo});

  final StoreOrderKind kind;
  final int? billNo;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  // ── حقول الرأس كما في النموذج المكتبي / the header boxes of the desktop form ──
  final TextEditingController _party = TextEditingController();
  final TextEditingController _partyBill = TextEditingController();
  final TextEditingController _detailes = TextEditingController();
  final TextEditingController _discount = TextEditingController(text: '0');
  final TextEditingController _discountRate = TextEditingController(text: '0');
  final TextEditingController _curPrice = TextEditingController(text: '1');
  final TextEditingController _curPrice1 = TextEditingController(text: '1');

  int? _storeNo;
  int? _storeTo;
  DateTime _date = DateTime.now();
  int _billType = 1;
  int _selectOne = 1;
  int _curNo = 1;
  int _curNo1 = 1;
  int? _accNo;
  int? _accNo1;
  String? _accName;
  String? _accName1;
  List<OrderLineDraft> _lines = const [];

  /// الرأس المحمَّل للعرض فقط — شريط التدقيق في أسفل النموذج
  /// The loaded header, kept only to render the audit strip at the foot of the form.
  StoreOrderModel? _loaded;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  late final CancelToken _cancel = CancelToken();

  bool get _isEdit => widget.billNo != null;

  /// تعريف نوع المستند — مصدر الحقول المعروضة في هذا النموذج
  /// The kind's profile — the source of the fields this form shows.
  StoreDocProfile get _profile => StoreDocProfile.of(widget.kind);

  @override
  void initState() {
    super.initState();

    if (_isEdit) Future.microtask(_loadOrder);
  }

  @override
  void dispose() {
    _cancel.cancel();
    _party.dispose();
    _partyBill.dispose();
    _detailes.dispose();
    _discount.dispose();
    _discountRate.dispose();
    _curPrice.dispose();
    _curPrice1.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);

    try {
      final detail = await ref
          .read(storeOrdersRepositoryProvider)
          .fetchOrder(widget.kind, widget.billNo!);

      if (!mounted) return;

      if (detail == null) {
        setState(() {
          _loading = false;
          _error = 'المستند غير موجود';
        });

        return;
      }

      final header = detail.header;

      // سطور المستند تُحفظ بالأرقام فقط، فنعيد بناء نموذج مصغّر للصنف والصنف الفرعي
      // لعرضها في المحرر بدون طلب إضافي لكل سطر.
      // Saved lines carry numbers only, so a minimal item/sub model is rebuilt for the
      // editor instead of one request per line.
      final lines = detail.lines
          .map(
            (line) => OrderLineDraft(
              item: ItemModel(
                sanfNo: line.sanfNo,
                partNo: line.partNo ?? '',
                name: line.sanfName ?? 'صنف ${line.sanfNo}',
                unitName: line.unitName,
              ),
              sub: ItemSubModel(
                sanfDno: line.sanfDno,
                sanfNo: line.sanfNo,
                partNo: line.subPartNo,
                name: line.subName,
                price: line.price,
                len: line.lengthFrom,
                wid: line.lengthTo,
                colorNo: line.colorNo,
                cap: line.cap,
                category: line.category,
                colorName: line.colorName,
              ),
              qty: line.qty,
              price: line.price,
              unitName: line.unitName,
              subPartNo: line.subPartNo,
              category: line.category,
              colorName: line.colorName,
              cap: line.cap > 0 ? line.cap : 1,
              shelfNo: line.shelfNo,
              colorNo: line.colorNo,
            ),
          )
          .toList();

      setState(() {
        _loaded = header;
        _storeNo = header.storeNo;
        _storeTo = header.storeTo;
        _date = header.date ?? DateTime.now();
        _billType = header.billType;
        _selectOne = header.selectOne;
        _curNo = header.curNo;
        _curNo1 = header.curNo1;
        _curPrice.text = StoreFormat.qty(header.curPrice);
        _curPrice1.text = StoreFormat.qty(header.curPrice1);
        _accNo = header.accNo > 0 ? header.accNo : null;
        _accNo1 = header.accNo1 > 0 ? header.accNo1 : null;
        _accName = header.accName;
        _accName1 = header.accName1;
        _party.text = header.partyName ?? '';
        _partyBill.text = header.partyBill ?? '';
        _detailes.text = header.detailes ?? '';
        _discount.text = header.discount.toStringAsFixed(2);
        _discountRate.text = StoreFormat.qty(header.discountRate);
        _lines = lines;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reference = ref.watch(storeReferenceProvider);
    final kind = widget.kind;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit
              ? 'تعديل ${kind.documentLabel} ${widget.billNo}'
              : 'تسجيل ${kind.documentLabel} جديد',
        ),
        actions: [
          if (!_isEdit)
            IconButton(
              tooltip: 'نموذج فارغ جديد',
              onPressed: _saving ? null : _reset,
              icon: const Icon(Icons.note_add_outlined),
            ),
        ],
      ),
      body: reference.when(
        loading: () => const StoreLoading(),
        error: (error, _) => StoreErrorState(message: error.toString()),
        data: (refs) {
          if (_loading) return const StoreLoading();

          final usable = refs.usableStores;

          if (usable.isEmpty) {
            return const StoreEmptyState(
              icon: Icons.warehouse_outlined,
              title: 'لا مخازن فعّالة',
              description:
                  'كل المخازن المسجّلة أرشيفية، ولا تُنشأ مستندات على المخازن الأرشيفية.',
            );
          }

          _storeNo ??= usable.first.storeNo;

          final total = _lines.fold<double>(0, (sum, line) => sum + line.total);
          final discount = double.tryParse(_discount.text.trim()) ?? 0;
          final net = (total - discount).clamp(0, double.infinity).toDouble();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _headerPanel(refs, usable),
                    const SizedBox(height: 12),
                    OrderLineEditor(
                      lines: _lines,
                      storeNo: _storeNo,
                      onChanged: (lines) => setState(() => _lines = lines),
                      priceLabel:
                          kind == StoreOrderKind.transfer ? 'التكلفة' : 'السعر',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.error,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (_loaded != null) _auditStrip(_loaded!),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              _totalsBar(total, discount, net),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────── لوحة رأس المستند ───────────────────────

  /// لوحة الرأس بكل خانات النموذج المكتبي، مرتّبة كما هي على شاشته
  /// The header panel with every box of the desktop form, in its order.
  Widget _headerPanel(StoreReference refs, List<StoreModel> usable) {
    final profile = StoreDocProfile.of(widget.kind);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StoreSectionHeader(
            title: 'بيانات ${profile.title}',
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: 12),
          // 1) رقم الفاتورة · نوعها · رقم المرجع · التاريخ — كل خانة حيث توجد في نوعها
          // Each box appears only where its own kind has it.
          _fieldRow([
            _readOnlyBox(
              label: 'رقم الفاتورة',
              value: _isEdit ? '${widget.billNo}' : 'يُحدَّد عند الحفظ',
            ),
            if (profile.hasBillType)
              _dropdownBox<int>(
                label: 'نوع الفاتورة',
                value: _billType,
                items: [
                  const DropdownMenuItem(value: 1, child: Text('نقد')),
                  const DropdownMenuItem(value: 2, child: Text('آجل')),
                ],
                onChanged: (value) => setState(() => _billType = value ?? 1),
              ),
            // رقم المرجع يُحرَّر في التوريد فقط: عمود الصرف رقم تسلسلي داخلي
            // The reference is editable on receive only: the issue column is an internal serial.
            if (profile.hasReference && profile.referenceWritable)
              _textFieldBox(
                label: 'رقم المرجع',
                controller: _partyBill,
                hint: '—',
              ),
            _dateBox(),
          ]),
          const SizedBox(height: 10),
          // 2) المخازن: المصدر والهدف في التحويل، ومخزن واحد في التوريد والصرف
          // Stores: source and target for a transfer, one store otherwise.
          _fieldRow([
            _dropdownBox<int>(
              label: profile.hasTargetStore ? 'من مخزن *' : 'إسم المخزن *',
              value: _storeNo,
              items: [
                for (final store in usable)
                  DropdownMenuItem(
                    value: store.storeNo,
                    child: Text(store.storeName),
                  ),
              ],
              onChanged: (value) => setState(() {
                _storeNo = value;

                if (_storeTo == value) _storeTo = null;
              }),
            ),
            if (profile.hasTargetStore)
              _dropdownBox<int>(
                label: 'إلى مخزن *',
                value: _storeTo,
                items: [
                  for (final store in usable)
                    if (store.storeNo != _storeNo)
                      DropdownMenuItem(
                        value: store.storeNo,
                        child: Text(store.storeName),
                      ),
                ],
                onChanged: (value) => setState(() => _storeTo = value),
              ),
            _accountBox(
              label: 'حساب المخزن',
              accNo: _accNo,
              name: _accName,
              onPicked: (account) => setState(() {
                _accNo = account?.accNo;
                _accName = account?.name;
              }),
            ),
          ]),
          const SizedBox(height: 10),
          // 3) الطرف وحسابه المقابل — التوريد له مورد، والصرف له جهة مستلمة، والتحويل لا طرف له
          // Party and counter account: supplier on receive, receiver on issue, none on transfer.
          if (profile.hasParty)
            _fieldRow([
              Expanded(
                child: TextFormField(
                  controller: _party,
                  decoration: _input('إسم ${profile.partyLabel ?? 'الطرف'} *'),
                ),
              ),
              _accountBox(
                label: 'حساب دائن',
                accNo: _accNo1,
                name: _accName1,
                onPicked: (account) => setState(() {
                  _accNo1 = account?.accNo;
                  _accName1 = account?.name;
                }),
              ),
            ])
          else
            _accountBox(
              label: 'حساب دائن',
              accNo: _accNo1,
              name: _accName1,
              onPicked: (account) => setState(() {
                _accNo1 = account?.accNo;
                _accName1 = account?.name;
              }),
            ),
          // 4) صفا العملة وخيار العملة المحاسبية — للتوريد والصرف فقط
          // The two currency rows and the currency-basis choice: receive/issue only.
          if (profile.hasCurrencyPair) ...[
            const SizedBox(height: 10),
            for (final row in [
              (label: 'العملة', no: _curNo, price: _curPrice, second: false),
              (
                label: 'العملة الثانية',
                no: _curNo1,
                price: _curPrice1,
                second: true,
              ),
            ])
              Padding(
                padding: EdgeInsets.only(bottom: row.second ? 10 : 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: row.no,
                        isExpanded: true,
                        decoration: _input(row.label),
                        items: [
                          for (final currency in refs.currencies)
                            DropdownMenuItem(
                              value: currency.curNo,
                              child: Text(currency.name),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => row.second
                              ? _curNo1 = value ?? 1
                              : _curNo = value ?? 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: row.price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _input('سعر العملة'),
                      ),
                    ),
                  ],
                ),
              ),
            _currencyChoice(),
          ],
          const SizedBox(height: 10),
          // 5) البيان
          TextFormField(
            controller: _detailes,
            maxLines: 2,
            decoration: _input('البيان'),
          ),
        ],
      ),
    );
  }

  /// اختيار العملة المحاسبية — الراديو الذي في أسفل رأس النموذج
  /// The currency-basis radio at the foot of the desktop header.
  Widget _currencyChoice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<int>(
              value: 1,
              groupValue: _selectOne,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'كل المبالغ في الفاتورة بالعملة المحلية',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (value) => setState(() => _selectOne = value ?? 1),
            ),
          ),
          Expanded(
            child: RadioListTile<int>(
              value: 2,
              groupValue: _selectOne,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'كل المبالغ في الفاتورة بعملة الحساب المدين',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (value) => setState(() => _selectOne = value ?? 2),
            ),
          ),
        ],
      ),
    );
  }

  /// شريط التدقيق: من أدخل المستند ومتى، ومن عدّله آخر مرة
  /// The audit strip: who entered the document and when, and who last edited it.
  Widget _auditStrip(StoreOrderModel header) {
    final rows = <(String, String)>[
      ('تاريخ الإدخال', header.dateLabel),
      ('الإدخال بواسطة', header.createdByName ?? '—'),
      ('الوقت', header.theTime ?? '—'),
      if (header.hasEditStamp) ...[
        ('تاريخ التعديل', JsonValues.formatDate(header.lastUpdatedOn, withTime: false)),
        ('التعديل بواسطة', header.lastUpdatedByName ?? '—'),
        ('وقت التعديل', header.lastUpdateTime ?? '—'),
      ],
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'سجل الإدخال والتعديل',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final row in rows)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${row.$1}: ',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      row.$2,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────── المجاميع والحفظ ───────────────────────

  Widget _totalsBar(double total, double discount, double net) {
    final rate = double.tryParse(_discountRate.text.trim()) ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // خانات المجاميع: الخصم في التوريد والصرف فقط — التحويل لا خصم له
          // The totals boxes: discount on receive/issue only; a transfer has none.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _readOnlyBox(
                  label: 'الإجمالي',
                  value: StoreFormat.money(total),
                ),
              ),
              if (_profile.hasDiscount) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _discountRate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: _input('نسبة الخصم %'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: _input('مبلغ الخصم'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: _readOnlyBox(
                  label: 'صافي المبلغ',
                  value: StoreFormat.money(net),
                  emphasise: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // نسبة الخصم تُحسب على الخادم من المبلغ، لكن العرض هنا يشرح للمستخدم ما سيحدث
          // The server recomputes the money; showing the derived figure here explains the result.
          if (rate > 0 && discount == 0)
            Text(
              'نسبة $rate% من الإجمالي ≈ ${StoreFormat.money(total * rate / 100)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('خروج'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(total, discount),
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
                  label: Text(_isEdit ? 'حفظ التعديل' : 'حفظ المستند'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(double total, double discount) async {
    final kind = widget.kind;
    final profile = StoreDocProfile.of(kind);

    if (_storeNo == null) {
      setState(() => _error = 'المخزن مطلوب');

      return;
    }

    if (kind.hasTargetStore && _storeTo == null) {
      setState(() => _error = 'المخزن الهدف مطلوب للتحويل');

      return;
    }

    if (kind.hasParty && _party.text.trim().isEmpty) {
      setState(
        () => _error = kind == StoreOrderKind.receive
            ? 'اسم المورد مطلوب'
            : 'اسم الجهة المستلمة مطلوب',
      );

      return;
    }

    if (_lines.isEmpty) {
      setState(() => _error = 'يجب إضافة سطر واحد على الأقل');

      return;
    }

    if (_lines.any((line) => line.qty <= 0)) {
      setState(() => _error = 'كل سطر يحتاج كمية أكبر من صفر');

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'store_no': _storeNo,
      if (kind.hasTargetStore) 'store_to': _storeTo,
      'dat': StoreFormat.date(_date),
      if (kind.hasParty) 'party_name': _party.text.trim(),
      if (kind.hasParty) 'party_bill': _partyBill.text.trim(),
      'detailes': _detailes.text.trim(),
      'discount': discount,
      'discount_rate': double.tryParse(_discountRate.text.trim()) ?? 0,
      // الحقول المشتركة تُرسل فقط لمن يملكها: نوع الفاتورة للتحويل لا معنى له،
      // وصف العملة يُرسل للتوريد والصرف فقط
      // Shared fields travel only to the kinds that own them: a transfer has no bill type, and the
      // currency rows belong to receive/issue.
      if (profile.hasBillType) 'bill_type': _billType,
      if (profile.hasCurrencyPair) ...{
        'select_one': _selectOne,
        'cur_no': _curNo,
        'cur_price': double.tryParse(_curPrice.text.trim()) ?? 1,
        'cur_no1': _curNo1,
        'cur_price1': double.tryParse(_curPrice1.text.trim()) ?? 1,
      },
      if (_accNo != null) 'acc_no': _accNo,
      if (_accNo1 != null) 'acc_no1': _accNo1,
      'lines': [
        for (final line in _lines)
          {
            'sanf_no': line.item.sanfNo,
            'sanf_dno': line.sub.sanfDno,
            'qty': line.qty,
            'price': line.price,
            'cap': line.cap,
            'pcs': line.pcs,
            'shelf_no': line.shelfNo,
            'color_no': line.colorNo,
            if (line.category != null && line.category!.isNotEmpty)
              'category': line.category,
          },
      ],
    };

    final repository = ref.read(storeOrdersRepositoryProvider);
    final result = _isEdit
        ? await repository.updateOrder(kind, widget.billNo!, payload)
        : await repository.createOrder(kind, payload);

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.success) {
      ref.read(ordersListProvider.notifier).load();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'تم تعديل المستند بنجاح' : 'تم حفظ المستند بنجاح',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _error = result.displayMessage);
    }
  }

  /// تفريغ النموذج للبدء في مستند جديد — كما يفعل زر «جديد» في النظام
  /// Clear the form to start a new document, like the desktop's «جديد» button.
  void _reset() {
    setState(() {
      _loaded = null;
      _party.clear();
      _partyBill.clear();
      _detailes.clear();
      _discount.text = '0';
      _discountRate.text = '0';
      _curPrice.text = '1';
      _curPrice1.text = '1';
      _storeTo = null;
      _billType = 1;
      _selectOne = 1;
      _curNo = 1;
      _curNo1 = 1;
      _accNo = null;
      _accNo1 = null;
      _accName = null;
      _accName1 = null;
      _lines = const [];
      _error = null;
    });
  }

  // ─────────────────────── لبنات الحقول ───────────────────────

  /// صف خانات متساوية العرض — الشبكة هي ما يجعل النموذج يبدو كالنظام لا كقائمة حقول
  /// A row of equally sized boxes — the grid is what makes this read as the system's form.
  Widget _fieldRow(List<Widget> cells) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: cells[i]),
          ],
        ],
      ),
    );
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    isDense: true,
    border: const OutlineInputBorder(),
  );

  Widget _readOnlyBox({
    required String label,
    required String value,
    bool emphasise = false,
  }) {
    return InputDecorator(
      decoration: _input(label),
      child: Text(
        value,
        style: TextStyle(
          fontSize: emphasise ? 12.5 : 11.5,
          fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
          color: emphasise ? AppColors.primary : AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _textFieldBox({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _input(label).copyWith(hintText: hint),
    );
  }

  Widget _dateBox() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );

        if (picked != null) setState(() => _date = picked);
      },
      child: InputDecorator(
        decoration: _input('التاريخ'),
        child: Text(
          StoreFormat.date(_date),
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _dropdownBox<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: _input(label),
      items: items,
      onChanged: onChanged,
    );
  }

  /// خانة حساب مع مُنتقي بحث — «>>» الذي في النموذج المكتبي
  /// An account box with a search picker — the «>>» button of the desktop form.
  Widget _accountBox({
    required String label,
    required int? accNo,
    required String? name,
    required ValueChanged<StoreAccountOption?> onPicked,
  }) {
    return TextFormField(
      readOnly: true,
      showCursor: true,
      initialValue: name ?? (accNo == null ? '' : '$accNo'),
      decoration: _input(label).copyWith(
        hintText: 'اختر حساباً',
        suffixIcon: IconButton(
          tooltip: 'بحث في دليل الحسابات',
          onPressed: () async {
            final picked = await _pickAccount(label);

            if (picked != null) onPicked(picked);
          },
          icon: const Icon(Icons.search_rounded, size: 18),
        ),
      ),
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
    );
  }

  /// نافذة بحث الحساب: تكتب اسماً أو رقماً فتظهر النتائج، والنقر يختار ويغلق
  /// The account search sheet: type a name or number, tap a result to choose it.
  Future<StoreAccountOption?> _pickAccount(String title) async {
    return showModalBottomSheet<StoreAccountOption>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AccountPickerSheet(title: title),
    );
  }
}

/// نافذة اختيار حساب من دليل الحسابات
/// The chart-of-accounts picker sheet.
class _AccountPickerSheet extends ConsumerStatefulWidget {
  const _AccountPickerSheet({required this.title});

  final String title;

  @override
  ConsumerState<_AccountPickerSheet> createState() => _AccountPickerSheetState();
}

class _AccountPickerSheetState extends ConsumerState<_AccountPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final CancelToken _cancel = CancelToken();

  List<StoreAccountOption> _accounts = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _query(''));
  }

  @override
  void dispose() {
    _cancel.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _query(String value) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await ref
          .read(storesRepositoryProvider)
          .searchAccounts(value, cancelToken: _cancel);

      if (!mounted) return;

      setState(() {
        _accounts = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                onSubmitted: _query,
                decoration: InputDecoration(
                  labelText: 'بحث بالاسم أو الرقم — ${widget.title}',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const StoreLoading(message: 'جارٍ جلب الحسابات...')
                  : _error != null
                  ? StoreErrorState(message: _error!, onRetry: () => _query(_search.text))
                  : _accounts.isEmpty
                  ? const StoreEmptyState(
                      icon: Icons.account_tree_outlined,
                      title: 'لا حسابات مطابقة',
                      description: 'اكتب جزءاً من اسم الحساب أو رقمه الكامل.',
                    )
                  : ListView.separated(
                      itemCount: _accounts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final account = _accounts[index];

                        return ListTile(
                          dense: true,
                          title: Text(account.name),
                          subtitle: Text('${account.accNo}'),
                          onTap: () => Navigator.pop(context, account),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
