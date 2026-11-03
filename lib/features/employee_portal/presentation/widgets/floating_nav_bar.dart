import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/portal_sections.dart';

/// شريط التنقل السفلي العائم بأسلوب «الكبسولة»
/// Floating pill-shaped bottom navigation bar (capsule style).
///
/// التصميم: كبسولة عائمة بحواف كاملة الاستدارة، أيقونات خطية فقط بلا تسميات،
/// مع هالة خفيفة حول الأيقونة المختارة. كل الألوان تُقرأ من `AppColors` الزمني (الذي يعكس
/// تهيئة التطبيق القادمة من الخادم عبر `AppPalette`) — لا لون ثابت هنا إطلاقاً.
/// Design: a floating capsule with fully rounded corners, line icons only (no labels),
/// and a soft halo behind the selected icon. Every color comes from the runtime
/// [AppColors] facade — the same server-configurable palette the rest of the app uses —
/// never a fixed hue.
///
/// لا يعرف هذا الودجت شيئاً عن الصلاحيات: القائمة تصله مفلترة من الهيكل المضيف،
/// تماماً كما كان يفعل `NavigationBar` سابقاً.
/// This widget knows nothing about permissions: the list arrives already filtered by the
/// host shell, exactly like the old `NavigationBar` did.
class FloatingNavBar extends StatelessWidget {
  /// الأقسام الظاهرة في الشريط — نفس كائنات السجل المركزي
  /// The bar sections — the very same registry objects the drawer reads.
  final List<PortalSection> sections;

  /// الفهرس المختار حالياً داخل [sections]
  /// The currently selected index within [sections].
  final int selectedIndex;

  /// يُستدعى عند اختيار تبويب
  /// Called when a tab is tapped.
  final ValueChanged<int> onDestinationSelected;

  const FloatingNavBar({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  // ── أبعاد ثابتة للتصميم / fixed design dimensions ──
  static const double _barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final count = sections.length;
    // حماية: شريط بلا وجهتين لا معنى له — الهيكل المضيف يتحقق أصلاً
    // Guard: a bar below two destinations is meaningless — the host already checks.
    if (count == 0) return const SizedBox.shrink();

    // ظل ناعم مشتق من لون النص الأساسي بدل أسود ثابت — يتناسق مع أي سمة مُهيّأة
    // Soft shadow derived from the palette text color instead of fixed black.
    final shadowColor = AppColors.textPrimary.withValues(alpha: 0.18);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: SizedBox(
          height: _barHeight,
          // جسم الكبسولة — سطح فاتح من السمة مع حدود خفيفة تفرّقه عن الخلفية
          // The capsule body — the themed surface plus a light border that separates it.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(_barHeight / 2),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                for (int i = 0; i < count; i++)
                  Expanded(
                    child: _NavBarItem(
                      section: sections[i],
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عنصر تبويب واحد: أيقونة خطية + هالة اختيار + نبضة تكبير عند التنشيط
/// A single tab: line icon, selection halo, and a small scale pulse when activated.
class _NavBarItem extends StatelessWidget {
  final PortalSection section;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // الأيقونة: الخطية للنشيط وغيره معاً — الأسلوب الخطي هو جوهر التصميم
    // Outlined icon for both states; the line style is the point of the design.
    final IconData icon = section.icon;

    return Semantics(
      button: true,
      selected: selected,
      label: section.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(31),
        child: SizedBox(
          height: FloatingNavBar._barHeight,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // هالة بلون التطبيق الأساسي الشفاف حول المحدد فقط
                // A translucent primary halo behind the selected icon only.
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 23,
                // المحدد بالأساسي وغيره بلون النص الخافت — كلاهما من السمة الزمني
                // Active in the primary color, inactive in the muted text tint — both themed.
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

