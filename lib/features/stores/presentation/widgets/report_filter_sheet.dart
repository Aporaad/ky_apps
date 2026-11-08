import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/items_providers.dart';
import '../widgets/store_ui.dart';
import 'multi_select_field.dart';

/// نافذة معطيات تقرير المخازن
/// The stores-report parameters sheet.
///
/// ── كل حقول التصفية متعدّدة الاختيار أو تحمل «لاشي»: «لاشي» ليست غياب اختيار بل قرار صريح
///    بأن هذا البُعد لا يقيّد التقرير، فتُسقط من الاستعلام ولا تُرسل كقيمة وهمية.
/// ── Every filter is multi-valued or carries an explicit "None". "None" is not a missing
///    choice but a decision that the dimension must not constrain the report, so it is dropped
///    from the query instead of sent as a phantom value.
///
/// ── القوائم مطوية دائماً: ست حقول يعرض كل منها قائمته كاملة لا تدخل شاشة هاتف، وفتح الحقل
///    هو ما يُظهر خياراته.
/// ── The lists stay collapsed: six fields each showing their whole list would never fit a
///    phone; opening a field is what reveals its options.
class ReportFilterSheet extends ConsumerStatefulWidget {
  const ReportFilterSheet({
    super.key,
    required this.initial,
    required this.reference,
  });

  final StoreReportFilter initial;
  final StoreReference reference;

  /// يفتح النافذة ويعيد المعطيات الجديدة، أو `null` عند الإلغاء
  /// Opens the sheet and returns the new parameters, or `null` when cancelled.
  static Future<StoreReportFilter?> show(
    BuildContext context, {
    required StoreReportFilter initial,
    required StoreReference reference,
  }) {
    return showModalBottomSheet<StoreReportFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          ReportFilterSheet(initial: initial, reference: reference),
    );
  }

  @override
  ConsumerState<ReportFilterSheet> createState() => _ReportFilterSheetState();
}

class _ReportFilterSheetState extends ConsumerState<ReportFilterSheet> {
  /// نص «لاشي» الموحّد — يظهر على وجه الحقل بدل فراغ يُقرأ كنسيان
  /// The single "None" caption — shown on the field face instead of a blank that reads as an
  /// oversight.
  static const String _none = 'لاشي';

  late StoreReportKind _kind = widget.initial.kind;
  late DateTime _from = widget.initial.from;
  late DateTime _to = widget.initial.to;
  late StoreReportGroupBy _groupBy = widget.initial.groupBy;
  late List<int> _storeNos = [...widget.initial.storeNos];
  late List<int> _groupNos = [...widget.initial.groupNos];
  late List<int> _itemTypeNos = [...widget.initial.itemTypeNos];
  late int? _catNo = widget.initial.catNo;
  late int? _sanfNo = widget.initial.sanfNo;
  late String? _sanfName = widget.initial.sanfName;
  late int? _sanfDno = widget.initial.sanfDno;
  late String? _sanfDnoLabel = widget.initial.sanfDnoLabel;
  late List<int> _movementTypeNos = [...widget.initial.movementTypeNos];

  /// الفترة «مُخصَّصة» فقط إذا غيّرها المستخدم فعلاً: المدى الافتراضي جزء من تعريف
  /// التقرير لا من نتائجه، فلا يُطبع في الترويسة كأنه اختيار
  /// The period counts as customised only when the user actually changed it: the default
  /// window is part of the report's definition, not a result, so it must not print as a choice.
  late bool _customPeriod = widget.initial.customPeriod;
  String? _error;

  // ─────────────────── معطيات الحقول من حزمة المراجع ───────────────────
  /// المخازن الأرشيفية تبقى قابلة للاختيار في تقرير الحركة: تاريخها ما زال في القاعدة،
  /// ومن الطبيعي طلب تقرير عن فترة قبل الأرشفة؛ فيُكتفى بوَسمها ليعرف المستخدم موضعه
  /// Archived stores stay selectable in a movement report: their history is still in the
  /// database and a report over the pre-archive period is legitimate — so they are labelled
  /// rather than removed.
  List<MultiOption> get _storeOptions => [
    for (final store in widget.reference.stores)
      MultiOption(
        '${store.storeNo}',
        store.archived ? '${store.storeName} (أرشيفي)' : store.storeName,
      ),
  ];

  List<MultiOption> get _groupOptions => [
    for (final group in widget.reference.groups)
      MultiOption('${group.groupNo}', group.groupName),
  ];

  /// فروع المجموعات المختارة فقط — وإذا لم تُختر مجموعة: كل الفروع
  /// Only the sub groups of the chosen main groups — and when none is chosen, all of them.
  List<MultiOption> get _subGroupOptions => [
    for (final type in widget.reference.typesOfGroups(_groupNos))
      MultiOption('${type.typeNo}', type.typeName),
  ];

  List<MultiOption> get _movementTypeOptions => [
    for (final type in widget.reference.movementTypes)
      MultiOption('${type.typeNo}', type.typeName),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          _titleRow(),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<StoreReportKind>(
                    segments: const [
                      ButtonSegment(
                        value: StoreReportKind.movement,
                        label: Text('عرض حركة'),
                        icon: Icon(Icons.timeline_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: StoreReportKind.summary,
                        label: Text('خلاصة'),
                        icon: Icon(Icons.summarize_rounded, size: 16),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (value) =>
                        setState(() => _kind = value.first),
                  ),
                  const SizedBox(height: 12),
                  _dateRow(),
                  const SizedBox(height: 8),
                  _quickRanges(),
                  const SizedBox(height: 12),

                  MultiSelectField(
                    label: 'المخازن',
                    options: _storeOptions,
                    selected: _idsToText(_storeNos),
                    itemIcon: Icons.warehouse_outlined,
                    onChanged: (values) =>
                        setState(() => _storeNos = _textToIds(values)),
                  ),
                  const SizedBox(height: 10),

                  MultiSelectField(
                    label: 'المجموعة الرئيسية',
                    options: _groupOptions,
                    selected: _idsToText(_groupNos),
                    itemIcon: Icons.category_outlined,
                    onChanged: (values) => setState(() {
                      _groupNos = _textToIds(values);
                      // تغيير الآباء يُسقط ما لم يعد ابناً لهم، وإلا بقي قيدٌ خفيّ يفسد التقرير
                      // A new parent set drops sub groups that no longer belong; otherwise a
                      // hidden stale constraint would quietly corrupt the report.
                      _itemTypeNos = _pruneSubGroups(_groupNos);
                    }),
                  ),
                  const SizedBox(height: 10),

                  MultiSelectField(
                    label: 'المجموعة الفرعية',
                    options: _subGroupOptions,
                    selected: _idsToText(_itemTypeNos),
                    itemIcon: Icons.subdirectory_arrow_right_rounded,
                    onChanged: (values) =>
                        setState(() => _itemTypeNos = _textToIds(values)),
                  ),
                  const SizedBox(height: 10),

                  _categoryField(),
                  const SizedBox(height: 12),

                  _itemFields(),
                  const SizedBox(height: 12),

                  if (_kind == StoreReportKind.movement)
                    MultiSelectField(
                      label: 'نوع الحركة',
                      options: _movementTypeOptions,
                      selected: _idsToText(_movementTypeNos),
                      itemIcon: Icons.swap_vert_rounded,
                      onChanged: (values) => setState(
                        () => _movementTypeNos = _textToIds(values),
                      ),
                    )
                  else
                    _groupByField(),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          _actions(),
        ],
      ),
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _titleRow() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'معطيات التقرير',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        // إعادة الضبط تمسح كل القيود دفعة واحدة — «لاشي» في كل حقل
        // Reset clears every constraint at once — "None" in each field.
        TextButton(
          onPressed: _reset,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text(
            'لاشي / إعادة ضبط',
            style: TextStyle(fontSize: 11),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, size: 20),
        ),
      ],
    );
  }

  void _reset() {
    setState(() {
      _storeNos = const [];
      _groupNos = const [];
      _itemTypeNos = const [];
      _catNo = null;
      _sanfNo = null;
      _sanfName = null;
      _sanfDno = null;
      _sanfDnoLabel = null;
      _movementTypeNos = const [];
      _groupBy = StoreReportGroupBy.item;
      _error = null;
    });
  }

  Widget _dateRow() {
    return Row(
      children: [
        Expanded(child: _dateField('من', _from, (value) => _from = value)),
        const SizedBox(width: 8),
        Expanded(child: _dateField('إلى', _to, (value) => _to = value)),
      ],
    );
  }

  /// مدى جاهزة: أكثر ما يُطلب قبل أي تخصيص
  /// Quick ranges: the commonest asks before any customisation.
  Widget _quickRanges() {
    final today = DateTime.now();

    final presets = <(String, int)>[
      ('اليوم', 0),
      ('أسبوع', 6),
      ('شهر', 29),
      ('ثلاثة أشهر', 91),
    ];

    return Wrap(
      spacing: 6,
      children: [
        for (final preset in presets)
          ActionChip(
            label: Text(preset.$1, style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onPressed: () => setState(() {
              _from = today.subtract(Duration(days: preset.$2));
              _to = today;
              // المدى الجاهز تخصيص صريح: لم يعد المستخدم على الافتراضي
              // A preset is still an explicit choice: the user is no longer on the default.
              _customPeriod = true;
            }),
          ),
      ],
    );
  }

  Widget _categoryField() {
    return DropdownButtonFormField<int?>(
      value: _catNo,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'الفئة',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        // «لاشي» أول خيار: بلا فئة يعني كل الفئات
        // "None" is the first choice: no category means every category.
        const DropdownMenuItem<int?>(value: null, child: Text(_none)),
        for (final category in widget.reference.categories)
          DropdownMenuItem<int?>(value: category.id, child: Text(category.name)),
      ],
      onChanged: (value) => setState(() => _catNo = value),
    );
  }

  /// الصنف الرئيسي ثم فرعه — منتقيان بحثهما خدوي والنشط فقط
  /// The main item then its branch: two pickers, debounced search, active records only.
  Widget _itemFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _pickItem,
          icon: const Icon(Icons.inventory_2_outlined, size: 16),
          label: Text(
            _sanfNo == null
                ? 'الصنف الرئيسي — $_none'
                : 'الصنف: ${_sanfName ?? _sanfNo}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (_sanfNo != null)
          _clearRow('مسح الصنف', () => setState(() {
            _sanfNo = null;
            _sanfName = null;
            // مسح الأب يُبطل ابنه حتماً: فرع بلا صنف لا يعني شيئاً في الاستعلام
            // Clearing the parent must clear the branch: a branch with no item means nothing
            // to the query.
            _sanfDno = null;
            _sanfDnoLabel = null;
          })),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickBranch,
          icon: const Icon(Icons.account_tree_outlined, size: 16),
          label: Text(
            _sanfDno == null
                ? 'الصنف الفرعي — $_none'
                : 'الفرع: ${_sanfDnoLabel ?? _sanfDno}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (_sanfDno != null)
          _clearRow('مسح الفرع', () => setState(() {
            _sanfDno = null;
            _sanfDnoLabel = null;
          })),
      ],
    );
  }

  Widget _clearRow(String label, VoidCallback onTap) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _groupByField() {
    return DropdownButtonFormField<StoreReportGroupBy>(
      value: _groupBy,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'مستوى التجميع',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        for (final level in StoreReportGroupBy.values)
          DropdownMenuItem(
            value: level,
            child: Text(level.label, style: const TextStyle(fontSize: 12.5)),
          ),
      ],
      onChanged: (value) =>
          setState(() => _groupBy = value ?? StoreReportGroupBy.item),
    );
  }

  Widget _dateField(
    String label,
    DateTime value,
    void Function(DateTime value) onPicked,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          setState(() {
            onPicked(picked);
            _customPeriod = true;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          StoreFormat.date(value),
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('عرض التقرير'),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── المنتقيات ───────────────────────

  Future<void> _pickItem() async {
    // الصنف الفرعي المختار يبقى صالحاً فقط إن بقي أبوه هو نفسه
    // The chosen branch stays valid only if its parent is still the same item.
    final previousParent = _sanfNo;

    final picked = await showModalBottomSheet<ItemModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ItemPickerSheet(),
    );

    if (picked == null) return;

    setState(() {
      _sanfNo = picked.sanfNo;
      _sanfName = picked.name;

      if (previousParent != null && previousParent != picked.sanfNo) {
        _sanfDno = null;
        _sanfDnoLabel = null;
      }
    });
  }

  Future<void> _pickBranch() async {
    final picked = await showModalBottomSheet<ItemSubModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BranchPickerSheet(parentSanfNo: _sanfNo),
    );

    if (picked == null) return;

    setState(() {
      _sanfDno = picked.sanfDno;
      _sanfDnoLabel = picked.pickerLabel;
    });
  }

  // ─────────────────────── helpers ───────────────────────

  List<int> _pruneSubGroups(List<int> groupNos) {
    final allowed =
        widget.reference.typesOfGroups(groupNos).map((t) => t.typeNo).toSet();

    return [
      for (final typeNo in _itemTypeNos)
        if (allowed.contains(typeNo)) typeNo,
    ];
  }

  static List<String> _idsToText(List<int> ids) => [
    for (final id in ids) '$id',
  ];

  static List<int> _textToIds(List<String> values) => [
    for (final value in values)
      if (int.tryParse(value) != null) int.parse(value),
  ];

  void _submit() {
    if (_from.isAfter(_to)) {
      setState(() => _error = 'تاريخ البداية بعد تاريخ النهاية');

      return;
    }

    final days = _to.difference(_from).inDays;

    if (days > widget.reference.maxRangeDays) {
      setState(
        () => _error =
            'المدى أكبر من الحد المسموح (${widget.reference.maxRangeDays} يوماً)',
      );

      return;
    }

    Navigator.pop(
      context,
      StoreReportFilter(
        kind: _kind,
        from: _from,
        to: _to,
        storeNos: _storeNos,
        groupNos: _groupNos,
        itemTypeNos: _itemTypeNos,
        catNo: _catNo,
        sanfNo: _sanfNo,
        sanfName: _sanfName,
        sanfDno: _sanfDno,
        sanfDnoLabel: _sanfDnoLabel,
        movementTypeNos: _kind == StoreReportKind.movement
            ? _movementTypeNos
            : const [],
        groupBy: _groupBy,
        customPeriod: _customPeriod,
      ),
    );
  }
}

/// صف في قائمة منتقي — النموذج يُحمَل مع الصف فلا يُستعاد بالمعرّف بعد ذلك
/// One picker row — the model rides along with it, so nothing has to be looked up by id later.
class _PickRow {
  const _PickRow({
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.model,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final Object? model;
}

/// خليط منتقي البحث: حقل خدع 300ms و«لاشي» أول السطر وإلغاء ما لم يُقرأ بعد
/// The shared search-picker mixin: a 300 ms debounced field, "None" as the first row, and
/// cancellation of anything still in flight.
///
/// ── سباق النتائج هو الخطأ الكلاسيكي هنا: طلب الأقدم يصل بعد الأحدث فيعرض قائمة قديمة.
/// ── The classic bug here is a race: the older request answering after the newer one would
///    leave a stale list on screen. A version counter and a cancel token close it.
mixin _SearchPicker<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final TextEditingController _search = TextEditingController();
  List<_PickRow> _rows = const [];
  bool _loading = true;
  Timer? _debounce;
  CancelToken? _cancel;
  int _version = 0;

  String get title;

  String get hint;

  Future<List<_PickRow>> fetch(String search, CancelToken token);

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _load(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    // خدع كما في بقية القسم: بحث حرف بحرف على آلاف السطور يخنق الشبكة
    // Debounced like the rest of the module: a per-keystroke search over thousands of rows
    // would choke the network.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(value.trim()));
  }

  Future<void> _load(String search) async {
    _debounce?.cancel();
    _cancel?.cancel();
    _cancel = CancelToken();

    final version = ++_version;
    setState(() => _loading = true);

    try {
      final rows = await fetch(search, _cancel!);

      if (!mounted || version != _version) return;

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      if (!mounted || version != _version) return;

      setState(() => _loading = false);
    } catch (_) {
      if (!mounted || version != _version) return;

      setState(() => _loading = false);
    }
  }

  /// هيكل المنتقي الموحد — العناوين تختلف والمصدر فقط
  /// The one picker shape — only the title and the source differ.
  Widget buildPicker(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _search,
              onChanged: _onQuery,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          // «لاشي» أول السطر دائماً: الأكثر استخداماً يجب أن يكون الأقرب
          // "None" is always the first row: the most-used choice should be the closest.
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            leading: const Icon(Icons.block_rounded, size: 18),
            title: const Text('لاشي', style: TextStyle(fontSize: 12.5)),
            subtitle: const Text(
              'بلا تقييد على هذا الحقل',
              style: TextStyle(fontSize: 10.5),
            ),
            onTap: () => Navigator.pop(context, null),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const StoreLoading()
                : _rows.isEmpty
                ? const StoreEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'لا نتائج مطابقة',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = _rows[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          row.title,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        subtitle: Text(
                          row.subtitle,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        trailing: row.trailing == null
                            ? null
                            : Text(
                                row.trailing!,
                                // `AppColors.primary` قيمة مشتقة من لوحة ألوان الفرع، فلا const
                                // AppColors.primary is derived, so this style cannot be const.
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                        onTap: () => Navigator.pop(context, row.model),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// منتقي الصنف الرئيسي — النشط فقط
/// The main-item picker: active items only.
///
/// ── صنف موقوف لا حركة له في أي مدى يُطلب عملياً، وإدراجه يعني تقريراً فارغاً يظنه المستخدم
///   عطبا.
/// ── A discontinued item has no movement in any range anyone actually asks about; listing it
///    yields an empty report the user reads as a defect.
class _ItemPickerSheet extends ConsumerStatefulWidget {
  const _ItemPickerSheet();

  @override
  ConsumerState<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends ConsumerState<_ItemPickerSheet>
    with _SearchPicker<_ItemPickerSheet> {
  @override
  String get title => 'الصنف الرئيسي';

  @override
  String get hint => 'بحث بالاسم أو الكود…';

  @override
  Future<List<_PickRow>> fetch(String search, CancelToken token) async {
    final page = await ref
        .read(storeItemsRepositoryProvider)
        .fetchItems(
          search: search,
          active: '1',
          limit: 120,
          cancelToken: token,
        );

    return [
      for (final item in page.items)
        _PickRow(
          title: item.name,
          subtitle: '${item.partNo} · ${item.groupName ?? ''}',
          trailing: StoreFormat.qty(item.qty),
          model: item,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => buildPicker(context);
}

/// منتقي الصنف الفرعي — فروع الصنف المختار إن حُدد، وكل النشط وإلا
/// The branch picker: the chosen item's branches, or every active branch when none is set.
class _BranchPickerSheet extends ConsumerStatefulWidget {
  const _BranchPickerSheet({this.parentSanfNo});

  final int? parentSanfNo;

  @override
  ConsumerState<_BranchPickerSheet> createState() => _BranchPickerSheetState();
}

class _BranchPickerSheetState extends ConsumerState<_BranchPickerSheet>
    with _SearchPicker<_BranchPickerSheet> {
  @override
  String get title =>
      widget.parentSanfNo == null ? 'الصنف الفرعي' : 'فروع الصنف';

  @override
  String get hint => 'بحث بالاسم أو الكود…';

  @override
  Future<List<_PickRow>> fetch(String search, CancelToken token) async {
    final page = await ref
        .read(storeItemsRepositoryProvider)
        .fetchSubItems(
          search: search,
          // بلا أب محدّد: كل فرع نشط، والباحث يختار منه
          // With no parent chosen: every active branch, and the searcher picks from it.
          sanfNo: widget.parentSanfNo,
          active: '1',
          limit: 120,
          cancelToken: token,
        );

    return [
      for (final branch in page.items)
        _PickRow(
          title: branch.pickerLabel,
          subtitle: branch.parentName ?? '',
          trailing: StoreFormat.qty(branch.qty),
          model: branch,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => buildPicker(context);
}
