import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// نافذة اختيار أعمدة التقرير — إظهار/إخفاء مع «لاشي» و«الكل»
/// The report columns sheet: show/hide with a "None" and an "All" shortcut.
///
/// ── ودجت مشتركة لأن كشف الحركة والتقرير جدول واحد: اختلاف أداة الأعمدة بين شاشتين يعني
///    أن المستخدم يفقد سيطرته في إحداهما بلا سبب مفهوم.
/// ── Shared because the statement and the report are one table: a different column tool on
///    each screen would silently take control away from the user in one of them.
///
/// ── «لاشي» هنا تعني الافتراضي لا جدولاً بلا أعمدة؛ والقالب نفسه يرفض الفراغ ويعود إليه.
/// ── "None" means the defaults here, not an empty grid — and the template refuses emptiness
///    by falling back anyway.
class ReportColumnsSheet extends StatefulWidget {
  const ReportColumnsSheet({
    super.key,
    required this.labels,
    required this.defaults,
    required this.initial,
    this.title = 'أعمدة العرض',
  });

  final List<(String, String)> labels;

  /// الافتراضي من القالب نفسه — معرّفاته لا تُنسخ هنا
  /// The defaults come from the template: its ids are not copied out here.
  final List<String> defaults;
  final Set<String> initial;
  final String title;

  static Future<Set<String>?> show(
    BuildContext context, {
    required List<(String, String)> labels,
    required List<String> defaults,
    required Set<String> initial,
    String title = 'أعمدة العرض',
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReportColumnsSheet(
        labels: labels,
        defaults: defaults,
        initial: initial,
        title: title,
      ),
    );
  }

  @override
  State<ReportColumnsSheet> createState() => _ReportColumnsSheetState();
}

class _ReportColumnsSheetState extends State<ReportColumnsSheet> {
  late Set<String> _chosen = {...widget.initial};

  /// الظاهر فعلاً: المحدّد صريحاً، أو الافتراضي ما لم يلمس المستخدم شيئاً
  /// What is really on: the explicit picks, or the defaults until the user touches anything.
  Set<String> get _effective =>
      _chosen.isEmpty ? widget.defaults.toSet() : _chosen;

  @override
  Widget build(BuildContext context) {
    final all = {
      for (final entry in widget.labels)
        entry.$1,
    };

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
                onPressed: () => setState(() => _chosen = {...all}),
                child: const Text('الكل', style: TextStyle(fontSize: 11.5)),
              ),
              TextButton(
                // عودة للافتراضي — هذا معنى «لاشي» في الأعمدة لا جدول بلا أعمدة
                // Back to the defaults: what "None" means for columns, not a table with none.
                onPressed: () => setState(() => _chosen = {}),
                child: const Text('لاشي', style: TextStyle(fontSize: 11.5)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          Text(
            'الظاهر ${_effective.length} من ${all.length}'
            '${_chosen.isEmpty ? ' (الافتراضي)' : ''}',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in widget.labels)
                    FilterChip(
                      label: Text(entry.$2, style: const TextStyle(fontSize: 11)),
                      selected: _effective.contains(entry.$1),
                      onSelected: (selected) => setState(() {
                        // من حالة «الافتراضي» يجب أن ينتقل النقر الأول إلى مجموعة صريحة،
                        // وإلا بدت الاستجابة معكوسة على Chip يبدو مختاراً
                        // Out of the "defaults" state the first tap must materialise an explicit
                        // set, or a chip that looks selected would toggle backwards.
                        final base = {..._effective};

                        if (selected) {
                          base.add(entry.$1);
                        } else {
                          base.remove(entry.$1);
                        }

                        _chosen = base;
                      }),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _chosen),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }
}
