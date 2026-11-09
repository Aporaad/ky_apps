import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// نتيجة نافذة الأعمدة: ترتيب الأعمدة الظاهرة، وحقول الإحصاءات الظاهرة
/// The columns sheet's result: the order of the visible columns and the visible statistic fields.
///
/// ── لماذا كائن نتيجة لا مجموعة معرّفات؟ لأن الترتيب صار جزءاً من الجواب، ومجموعة `Set`
///    لا تحفظ ترتيباً — فيعود كل عمود إلى مكانه الأول بعد كل تعديل.
/// ── Why an object rather than a plain id set? Order is now part of the answer, and a `Set`
///    keeps none — so every column would snap back to its template position after each edit.
class ReportColumnsChoice {
  const ReportColumnsChoice({
    required this.columnIds,
    required this.statIds,
  });

  /// الأعمدة الظاهرة بترتيب المستخدم نفسه
  /// The visible columns, in the user's own order.
  final List<String> columnIds;

  /// حقول الإحصاءات الظاهرة — قائمة فارغة تعني «أخفها كلها»
  /// The visible statistics fields — an empty list means "hide them all".
  final List<String> statIds;
}

/// نافذة تخصيص الجدول — إظهار وإخفاء وترتيب الأعمدة، وإظهار/إخفاء حقول الإحصاءات
/// The table customiser — show, hide and reorder columns, and show/hide the statistic fields.
///
/// ── لا عمود مقفل: «نوع الحركة» عمود أساسي في القالب، لكن محاسباً يراجع أرصدة مخزن واحد
///    قد لا يريده على ورقة ضيقة. القفل كان يفرض رغبة القالب على من يقرأ الورقة.
/// ── No locked column: "movement type" is a template basic, yet an accountant reviewing one
///    store's balances may not want it on a narrow sheet. Locking forced the template's taste
///    on whoever reads the paper.
///
/// ── الترتيب بأسهم لا بسحب: السحب على قائمة طويلة داخل نافذة سفلية يخطئ الهدف كثيراً
///    (ويضيع الصف بين الإصبع والشاشة)، والسهم ينقل صفاً واحداً بضغطة لا لبس فيها.
/// ── Order moves with arrows, not drag: dragging inside a tall bottom sheet misses its
///    target often and drops the row off-screen; an arrow moves exactly one row per tap.
class ReportColumnsSheet extends StatefulWidget {
  const ReportColumnsSheet({
    super.key,
    required this.labels,
    required this.visible,
    this.statLabels = const [],
    this.visibleStats,
    this.title = 'أعمدة العرض',
  });

  /// كل الأعمدة المتاحة بترتيب القالب — تُستخدم لإلحاق المخفي في نهاية القائمة
  /// Every available column in template order — used to append the hidden ones at the end.
  final List<(String, String)> labels;

  /// الظاهر حالياً بترتيبه — أو الافتراضي عند أول فتح
  /// What is visible right now, in its order — or the default on first open.
  final List<String> visible;

  /// حقول الإحصاءات المتاحة بترتيبها الثابت
  /// The available statistic fields in their fixed order.
  final List<(String, String)> statLabels;

  /// الظاهر من حقول الإحصاءات — `null` تعني «كلها» قبل أن يلمس المستخدم شيئاً
  /// The visible statistic fields — null means "all of them" before the user touches anything.
  final List<String>? visibleStats;

  final String title;

  static Future<ReportColumnsChoice?> show(
    BuildContext context, {
    required List<(String, String)> labels,
    required List<String> visible,
    List<(String, String)> statLabels = const [],
    List<String>? visibleStats,
    String title = 'أعمدة العرض',
  }) {
    return showModalBottomSheet<ReportColumnsChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReportColumnsSheet(
        labels: labels,
        visible: visible,
        statLabels: statLabels,
        visibleStats: visibleStats,
        title: title,
      ),
    );
  }

  @override
  State<ReportColumnsSheet> createState() => _ReportColumnsSheetState();
}

class _ReportColumnsSheetState extends State<ReportColumnsSheet> {
  /// كل الصفوف بترتيبها: الظاهر أولاً بترتيبه ثم المخفي بترتيب القالب
  /// Every row in its order: the visible ones first in their order, then the hidden ones.
  late List<String> _order;

  late Set<String> _on;

  late Set<String> _stats;

  @override
  void initState() {
    super.initState();

    // التهيئة هنا لا في تعريف الحقول: `widget` غير متاح وقت إنشاء الحقول
    // Initialised here, not at the field declarations: `widget` is not available that early.
    _on = {...widget.visible};
    _order = _initialOrder();
    _stats = widget.visibleStats == null
        ? {for (final entry in widget.statLabels) entry.$1}
        : {...widget.visibleStats!};
  }

  List<String> _initialOrder() {
    final known = {for (final entry in widget.labels) entry.$1};
    final visible = [
      for (final id in widget.visible)
        if (known.contains(id)) id,
    ];

    return [
      ...visible,
      for (final entry in widget.labels)
        if (!visible.contains(entry.$1)) entry.$1,
    ];
  }

  String _labelOf(String id) {
    for (final entry in widget.labels) {
      if (entry.$1 == id) return entry.$2;
    }

    return id;
  }

  /// نقل صف خطوة واحدة — الحدود تحمي أول وآخر صف من نقلة تفسد الترتيب
  /// Move a row one step; the bounds keep the first and last row from corrupting the list.
  void _move(int index, int delta) {
    final target = index + delta;

    if (target < 0 || target >= _order.length) return;

    setState(() {
      final moved = _order.removeAt(index);
      _order.insert(target, moved);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        MediaQuery.viewInsetsOf(context).bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _on = {for (final entry in widget.labels) entry.$1};
                }),
                child: const Text('الكل', style: TextStyle(fontSize: 11.5)),
              ),
              TextButton(
                // «لاشي» للمجاميع تعني «أخفِ الشريط»، وللأعمدة لا معنى لجدول بلا أعمدة
                // "None" for the statistics means "hide the strip"; a column-less table
                // has no meaning, so the apply button refuses it instead.
                onPressed: () => setState(() => _on = {}),
                child: const Text('لاشي', style: TextStyle(fontSize: 11.5)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          Text(
            'الظاهر ${_on.length} من ${widget.labels.length} — '
            'استخدم الأسهم لتغيير ترتيب الأعمدة',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < _order.length; i++) _columnRow(i),
                  if (widget.statLabels.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // لا const: `textPrimary` قيمة مشتقة من لوحة الألوان لا ثابت
                    // No const: textPrimary is a derived palette value, not a literal.
                    Text(
                      'حقول الإحصاءات',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // المستخدم يرى خمسة حقول فقط، فالسطر يقول له أين ذهب الباقي بدل أن يظنّه ضائعاً
                    // The user sees five fields only, so this line says where the rest went
                    // rather than letting them think it is lost.
                    const Text(
                      'الظاهر افتراضياً: السابق · وارد · منصرف · الصافي · الرصيد الحالي — '
                      'والباقي مخفي حتى تختاره، والاختيار يسري على الشاشة والمطبوع',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final entry in widget.statLabels)
                          FilterChip(
                            label: Text(
                              entry.$2,
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: _stats.contains(entry.$1),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _stats.add(entry.$1);
                              } else {
                                _stats.remove(entry.$1);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          _stats = {for (final entry in widget.statLabels) entry.$1};
                        }),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: const Text(
                          'إظهار كل الإحصاءات',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_on.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'اختر عموداً واحداً على الأقل — الجدول بلا أعمدة لا يقول شيئاً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppColors.error),
              ),
            ),
          ElevatedButton(
            onPressed: _on.isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    ReportColumnsChoice(
                      columnIds: [
                        for (final id in _order)
                          if (_on.contains(id)) id,
                      ],
                      statIds: [
                        for (final entry in widget.statLabels)
                          if (_stats.contains(entry.$1)) entry.$1,
                      ],
                    ),
                  ),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  /// صف عمود: مربع اختيار، ثم الاسم، ثم سهمان لنقله
  /// A column row: a checkbox, the caption, then two arrows to move it.
  Widget _columnRow(int index) {
    final id = _order[index];

    return InkWell(
      onTap: () => setState(() {
        if (_on.contains(id)) {
          _on.remove(id);
        } else {
          _on.add(id);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Checkbox(
              value: _on.contains(id),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (selected) => setState(() {
                if (selected == true) {
                  _on.add(id);
                } else {
                  _on.remove(id);
                }
              }),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _labelOf(id),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: _on.contains(id)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: _on.contains(id)
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            _arrow(Icons.keyboard_arrow_up_rounded, 'أعلى', index, -1),
            _arrow(Icons.keyboard_arrow_down_rounded, 'أسفل', index, 1),
          ],
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, String tooltip, int index, int delta) {
    final enabled = index + delta >= 0 && index + delta < _order.length;

    return IconButton(
      tooltip: 'نقل $tooltip',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      iconSize: 18,
      onPressed: enabled ? () => _move(index, delta) : null,
      icon: Icon(icon),
    );
  }
}
