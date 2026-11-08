import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// خيار واحد داخل حقل الاختيار المتعدد
/// One option inside a multi-select field.
class MultiOption {
  const MultiOption(this.value, this.label);

  final String value;
  final String label;
}

/// حقل اختيار متعدد بقائمة منسدلة — القيمة الحالية تظهر في الزر always، والقائمة نفسها
/// لا تُبنى ولا تُعرض إلا عند فتح الحقل.
///
/// A multi-select field with a drop-down panel. The current choice is always readable on the
/// field itself; the option list is neither built nor shown until the field is opened, which is
/// what keeps a six-field parameters sheet short enough to fit a phone screen.
///
/// ── «لاشي» اختيار صريح لا غياب اختيار: يمسح كل المحدى ويعني «بلا قيد» في الاستعلام، فلا
///    يحتاج المستخدم ليخبر النظام أنه لا يريد تضييقاً.
/// ── "None" is an explicit choice, not a missing one: it clears the selection and means
///    "unconstrained" in the query, so the user never has to guess how to say "no filter".
class MultiSelectField extends StatefulWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.searchable = true,
    this.itemIcon,
  });

  final String label;
  final List<MultiOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool searchable;

  /// أيقونة صغيرة أمام كل خيار — تمييز المخزن عن الصنف بلا قراءة النص
  /// A leading icon per option — tell a store from an item without reading the text.
  final IconData? itemIcon;

  @override
  State<MultiSelectField> createState() => _MultiSelectFieldState();
}

class _MultiSelectFieldState extends State<MultiSelectField> {
  bool _open = false;
  String _query = '';

  /// الوصف المختصر على وجه الحقل: لا شيء · الكل · أسماء المحددين · «n محدد»
  /// The short summary on the field face: none · all · the chosen names · "n selected".
  String get _summaryText {
    if (widget.selected.isEmpty) return 'لاشي';

    if (widget.selected.length == widget.options.length && widget.options.isNotEmpty) {
      return 'الكل (${widget.options.length})';
    }

    final chosen = [
      for (final option in widget.options)
        if (widget.selected.contains(option.value)) option.label,
    ];

    if (chosen.isEmpty) return '${widget.selected.length} محدد';

    if (chosen.length <= 2) return chosen.join('، ');

    return '${chosen.take(2).join('، ')} +${chosen.length - 2}';
  }

  List<MultiOption> get _visibleOptions {
    if (_query.trim().isEmpty) return widget.options;

    final needle = _query.trim();

    return [
      for (final option in widget.options)
        if (option.label.contains(needle)) option,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.selected.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── وجه الحقل: زر واحد يفتح ويغلق، والقائمة خلفه لا بجانبه
        // ── The field face: one button opens and closes it; the list sits behind it.
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(
                color: _open ? AppColors.primary : AppColors.border,
                width: _open ? 1.4 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        // `textSecondary` قيمة مشتقة لا ثابتة، فلا تصلح داخل const
                        // textSecondary is a derived value, not a constant, so it cannot sit in const.
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _summaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: hasSelection
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasSelection)
                  // مسح سريع بلا فتح القائمة — أكثر ما يُخطئ المستخدم هو نسيان محدد قديم
                  // Clearing without opening the panel — the commonest mistake is a stale filter.
                  IconButton(
                    onPressed: () => widget.onChanged(const []),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    tooltip: 'لاشي',
                  ),
                Icon(
                  _open
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),

        // ── اللوحة: لا تُبنى أصلاً وهي مغلقة، فلا تكلفة على الشاشة ولا على القراءة
        // ── The panel is not even built while closed: no layout cost, no scrolling noise.
        if (_open)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'المتاح: ${widget.options.length}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => widget.onChanged(const []),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('لاشي', style: TextStyle(fontSize: 11.5)),
                    ),
                    TextButton(
                      onPressed: () => widget.onChanged(
                        [for (final o in widget.options) o.value],
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('الكل', style: TextStyle(fontSize: 11.5)),
                    ),
                  ],
                ),
                if (widget.searchable && widget.options.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'بحث…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ),
                ConstrainedBox(
                  // سقف واضح مع تمرير داخلي: قائمة بمئات الأصناف لا تدفع الأزرار خارج الشاشة
                  // A hard cap with internal scrolling: a list of hundreds of items must not
                  // push the action buttons off the screen.
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final option in _visibleOptions)
                          CheckboxListTile(
                            value: widget.selected.contains(option.value),
                            onChanged: (checked) => _toggle(option.value, checked ?? false),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            title: Text(
                              option.label,
                              style: const TextStyle(fontSize: 12),
                            ),
                            secondary: widget.itemIcon == null
                                ? null
                                : Icon(widget.itemIcon, size: 15, color: AppColors.textMuted),
                          ),
                        if (_visibleOptions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'لا نتائج مطابقة',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _toggle(String value, bool on) {
    final next = <String>[...widget.selected];

    if (on) {
      if (!next.contains(value)) next.add(value);
    } else {
      next.remove(value);
    }

    widget.onChanged(next);
  }
}
