import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../../data/models/tree_export_row_model.dart';

/// نافذة تحديد نطاق الطباعة/التصدير: أي المستويات، أي قسم، هل تدخل حسابات العملاء.
/// The export scope sheet.
///
/// لماذا؟ كان التصدير يطبع ما تعرضه الشاشة، والشجرة كسولة — فخرجت المطبوعة بالحسابات
/// الرئيسة فقط. الآن يسأل المستندُ المستخدمَ عن مستوياته قبل أن يطلبها من القاعدة.
///
/// Export used to serialize the visible scroll position, so a collapsed tree printed
/// its section headers and nothing else. This sheet asks the document what it should
/// contain, and that answer goes to the server as the query.
Future<TreeExportScope?> showTreeExportScopeSheet(
  BuildContext context, {
  required TreeExportScope initial,
  required List<AccountTreeNode> sections,
  String? periodLabel,
}) {
  return showModalBottomSheet<TreeExportScope>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _TreeExportScopeSheet(
      initial: initial,
      sections: sections,
      periodLabel: periodLabel,
    ),
  );
}

class _TreeExportScopeSheet extends StatefulWidget {
  const _TreeExportScopeSheet({
    required this.initial,
    required this.sections,
    this.periodLabel,
  });

  final TreeExportScope initial;
  final List<AccountTreeNode> sections;
  final String? periodLabel;

  @override
  State<_TreeExportScopeSheet> createState() => _TreeExportScopeSheetState();
}

class _TreeExportScopeSheetState extends State<_TreeExportScopeSheet> {
  late TreeExportScope _scope = widget.initial;

  bool _holds(TreeExportLevel level) => _scope.levels.contains(level);

  void _toggleLevel(TreeExportLevel level, bool on) {
    final next = <TreeExportLevel>[..._scope.levels];
    if (on) {
      next.add(level);
      // إعادة ترتيب حسب ترتيب الهرم: المطبوعة تُقرأ من الأعلى إلى الأسفل دائماً.
      next.sort((a, b) => a.index.compareTo(b.index));
    } else {
      next.remove(level);
    }
    // لا نطاق فارغ: كان ليُنتج ملفاً بصفر أسطر بلا رسالة تشرح السبب.
    setState(() => _scope = _scope.copyWith(
      levels: next.isEmpty ? TreeExportLevel.values : next,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final chartOn = _holds(TreeExportLevel.chart);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نطاق الطباعة والتصدير',
                // textPrimary ديناميكي (يُقرأ من AppPalette) فلا يصلح داخل const.
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'المستويات المختارة تُطلب من الخادم مباشرة، فلا علاقة لها بما هو موسَّع على الشاشة.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),

              // ─── المستويات ───
              const _SectionLabel('المستويات'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final level in TreeExportLevel.values)
                    FilterChip(
                      selected: _holds(level),
                      onSelected: (v) => _toggleLevel(level, v),
                      label: Text(level.labelAr, style: const TextStyle(fontSize: 11.5)),
                      avatar: Icon(
                        level == TreeExportLevel.chart
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_tree_outlined,
                        size: 15,
                        color: _holds(level) ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── القسم ───
              const _SectionLabel('القسم (اختياري)'),
              DropdownButtonFormField<int?>(
                value: _scope.sectionAccNo,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'كل الأقسام',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('كل الأقسام', style: TextStyle(fontSize: 12.5)),
                  ),
                  for (final section in widget.sections)
                    DropdownMenuItem<int?>(
                      value: section.accNo,
                      child: Text(
                        '${section.accNo ?? ''} — ${section.name}',
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _scope = _scope.copyWith(sectionAccNo: v)),
              ),
              const SizedBox(height: 14),

              // ─── خيارات الصفوف ───
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('تضمين حسابات العملاء',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: Text(
                  chartOn
                      ? 'أكثر من عشرين ألف حساب — الملف سيكون كبيراً'
                      : 'غير فعّال بدون مستوى «الحسابات المالية»',
                  style: const TextStyle(fontSize: 10.5),
                ),
                value: chartOn && _scope.includeCustomers,
                onChanged: chartOn
                    ? (v) => setState(
                        () => _scope = _scope.copyWith(includeCustomers: v),
                      )
                    : null,
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('إخفاء الأرصدة الصفرية',
                    style: TextStyle(fontSize: 12.5)),
                subtitle: const Text(
                  'يحذف صفوف العرض صفريّة الرصيد، ولا يغيّر تجميع الأبناء',
                  style: TextStyle(fontSize: 10.5),
                ),
                value: _scope.hideZeroBalances,
                onChanged: (v) => setState(
                  () => _scope = _scope.copyWith(hideZeroBalances: v),
                ),
              ),
              if (widget.periodLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'الأرصدة عن الفترة: ${widget.periodLabel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),
              // ملخص ما سيُطبع — يقرأه المستخدم قبل أن ينتظر ملفاً لا يريده.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _scope.describe(),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, _scope),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('تأكيد'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        // لون النص الأساسي ديناميكي (يُقرأ من AppPalette) فلا يدخل في const.
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
