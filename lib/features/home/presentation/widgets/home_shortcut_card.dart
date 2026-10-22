import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../employee_portal/domain/portal_section_titles.dart';
import '../../domain/home_shortcut.dart';
import 'home_tokens.dart';

/// بطاقة اختصار مربّعة: شارة أيقونة، عنوان من سطرين، وسطر القسم
/// A square shortcut card: icon badge, two-line title, and the section caption.
///
/// التحويم والضغط يُداران محليًا: الشبكة تعيد بناء أبنائها عند كل تغيير في التصفية، وحالة
/// التحويم في الأب كانت ستُعيد بناء ثلاثين بطاقة مقابل مؤشر فأرة واحد.
/// Hover and press states are local: the grid rebuilds its children on every filter change, and
/// keeping hover in the parent would rebuild thirty cards for one mouse pointer.
class HomeShortcutCard extends StatefulWidget {
  const HomeShortcutCard({
    super.key,
    required this.shortcut,
    required this.onTap,
    this.onLongPress,
  });

  final HomeShortcut shortcut;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<HomeShortcutCard> createState() => _HomeShortcutCardState();
}

class _HomeShortcutCardState extends State<HomeShortcutCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shortcut = widget.shortcut;
    final accent = HomeTokens.sectionColor(shortcut.sectionId);
    final sectionTitle = PortalSectionTitles.of(shortcut.sectionId);
    final textScaler = MediaQuery.textScalerOf(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: HomeTokens.press,
        curve: Curves.easeOut,
        child: Semantics(
          button: true,
          label: '${shortcut.title} — $sectionTitle',
          child: AnimatedContainer(
            duration: HomeTokens.press,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
              border: Border.all(
                color:
                    _hovered
                        ? accent.withValues(alpha: 0.45)
                        : AppColors.border,
                width: _hovered ? 1.4 : 1,
              ),
              boxShadow: HomeTokens.cardShadow(hover: _hovered),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
              child: InkWell(
                borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onHighlightChanged: (value) {
                  if (_pressed != value) setState(() => _pressed = value);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // البطاقة تحتها 150dp تعني جهازًا ضيقًا: يُخفى سطر القسم ويصغر العنوان
                      // A tile under 150dp means a narrow device: hide the caption, shrink the title.
                      final compact = constraints.maxHeight < 150;
                      final titleSize = textScaler
                          .scale(compact ? 12.5 : HomeTokens.titleSize)
                          .clamp(10.5, 18.0);
                      final captionSize = textScaler
                          .scale(HomeTokens.captionSize)
                          .clamp(9.0, 13.0);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _IconBadge(
                                icon: shortcut.icon,
                                color: accent,
                                compact: compact,
                              ),
                              const Spacer(),
                              if (shortcut.underDevelopment)
                                _ComingSoonBadge(compact: compact),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            shortcut.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              sectionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: captionSize,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }
}

/// صندوق الأيقونة الملوّن — تعبئة 12% تحفظ تباين النص فوق الأبيض
/// The tinted icon box — a 12% fill keeps text contrast safe on white.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final box = compact ? 38.0 : HomeTokens.iconBox;

    return ExcludeSemantics(
      child: Container(
        width: box,
        height: box,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(HomeTokens.badgeRadius),
        ),
        child: Icon(
          icon,
          color: color,
          size: compact ? 19 : HomeTokens.iconSize,
        ),
      ),
    );
  }
}

/// شارة «قيد التطوير» — تقول الحقيقة بدل أن تُخفي القسم أو تُوهم بأنه جاهز
/// The "under development" badge — tells the truth instead of hiding the section or faking it.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        compact ? 'قريبًا' : 'قيد التطوير',
        style: TextStyle(
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w600,
          color: AppColors.warning,
        ),
      ),
    );
  }
}
