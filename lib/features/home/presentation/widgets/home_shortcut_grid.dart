import 'package:flutter/material.dart';

import '../../domain/home_shortcut.dart';
import 'home_shortcut_card.dart';
import 'home_tokens.dart';

/// شبكة الاختصارات المربّعة — العمود المحسوب هو ما يجعلها مربّعة فعلًا
/// The square shortcut grid — the computed column count is what makes the squares real.
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
    required this.onOpen,
    this.onLongPress,
  });

  final List<HomeShortcut> shortcuts;
  final void Function(HomeShortcut shortcut) onOpen;
  final void Function(HomeShortcut shortcut)? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (shortcuts.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final gap = HomeTokens.gap(screenWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: shortcuts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: HomeTokens.columns(constraints.maxWidth),
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            // مربّعة: الضلعان يُشتقّان من نفس القياس
            // Square: both edges derive from the same measurement.
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            final longPress = onLongPress;

            return HomeShortcutCard(
              key: ValueKey(shortcut.id),
              shortcut: shortcut,
              onTap: () => onOpen(shortcut),
              onLongPress: longPress == null ? null : () => longPress(shortcut),
            );
          },
        );
      },
    );
  }
}
