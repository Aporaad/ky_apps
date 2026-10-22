import 'package:flutter/material.dart';

import '../../domain/home_card_size.dart';
import '../../domain/home_shortcut.dart';
import 'home_shortcut_card.dart';
import 'home_tokens.dart';

/// شبكة الاختصارات المربّعة — العمود المحسوب والحجم هما ما يجعلانها مربّعة ومرتّبة
/// The square shortcut grid — the computed column count and size are what keep it square and tidy.
///
/// `shrinkWrap` + `NeverScrollableScrollPhysics` إلزاميان: الشبكة تعيش داخل `SingleChildScrollView`
/// واحدة، وشبكة قابلة للتمرير داخلها تعني تمريرًا متداخلًا أو تجاوزًا — وهو نمط الفشل المتكرر
/// في هذا المشروع.
/// Both flags are mandatory: the grid lives inside a single `SingleChildScrollView`, and a
/// scrollable grid inside it means nested scrolling or overflow — this project's recurring failure.
class HomeShortcutGrid extends StatelessWidget {
  const HomeShortcutGrid({
    super.key,
    required this.shortcuts,
    required this.size,
    required this.columns,
    required this.onOpen,
    this.onLongPress,
  });

  final List<HomeShortcut> shortcuts;
  final HomeCardSize size;

  /// عدد مثبّت من المستخدم، و`0` تعني «تلقائي» (يُشتق من الحجم وعرض المحتوى)
  /// A user-pinned column count; `0` means automatic (derived from size and content width).
  final int columns;

  final void Function(HomeShortcut shortcut) onOpen;
  final void Function(HomeShortcut shortcut)? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: shortcuts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: HomeTokens.columns(
              constraints.maxWidth,
              size: size,
              fixed: columns,
            ),
            crossAxisSpacing: size.gap,
            mainAxisSpacing: size.gap,
            // النسبة من الحجم: العرض يحكمه عدد الأعمدة، والارتفاع هنا — فالحجم يُرى دائمًا
            // The ratio comes from the size: columns set the width, this sets the height, so a
            // size change is always visible even when the column count is pinned.
            childAspectRatio: size.ratio,
          ),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            final longPress = onLongPress;

            return HomeShortcutCard(
              key: ValueKey(shortcut.id),
              shortcut: shortcut,
              size: size,
              onTap: () => onOpen(shortcut),
              onLongPress: longPress == null ? null : () => longPress(shortcut),
            );
          },
        );
      },
    );
  }
}
