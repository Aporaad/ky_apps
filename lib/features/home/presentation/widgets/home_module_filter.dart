import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../employee_portal/domain/portal_section_titles.dart';

/// شرائح تصفية الأقسام: «الكل» ثم الأقسام التي لها اختصار ظاهر فقط
/// Section filter chips: "all", then only the sections that actually have a visible shortcut.
///
/// لا تُعرض شريحة لقسم فارغ: شريحة تعطي صفر نتيجة تبدو عطلًا لا تصفية.
/// No chip for an empty section: a chip that yields zero results reads as a bug, not a filter.
class HomeModuleFilter extends StatelessWidget {
  const HomeModuleFilter({
    super.key,
    required this.sectionIds,
    required this.selected,
    required this.onChanged,
  });

  final List<String> sectionIds;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // RTL يقلب الاتجاه تلقائيًا: أول شريحة تظهر يمينًا بلا `reverse` يدوي
      // RTL flips the axis by itself: the first chip lands on the right with no manual reverse.
      child: Row(
        children: [
          _Chip(
            label: 'الكل',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final id in sectionIds) ...[
            const SizedBox(width: 8),
            _Chip(
              label: PortalSectionTitles.of(id),
              selected: selected == id,
              onTap: () => onChanged(id),
            ),
          ],
        ],
      ),
    );
  }
}

/// شريحة واحدة — لون واحد وحدّ واحد، فلا تختلف عن جارتها بحسب الحالة إلا بالتشديد
/// One chip — a single colour and border; state only tightens them.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.10),
      side: BorderSide(
        color:
            selected
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
