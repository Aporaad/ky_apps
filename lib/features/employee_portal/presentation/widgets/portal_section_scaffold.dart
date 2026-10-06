import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// إطار عمل بسيط لأقسام بوابة الموظف العامة (غير قوائم البيانات)
/// مثل: لوحة الرئيسية، الإدارة، المبيعات، التفصيل، المخازن
/// لا يحتوي على شريط بحث أو أزرار CRUD افتراضية
class PortalSectionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? content;
  final String? emptyTitle;
  final String? emptyDescription;
  final List<Widget>? actions;

  const PortalSectionScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.content,
    this.emptyTitle,
    this.emptyDescription,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width < 600 ? 16.0 : 24.0;
    final vPad = size.width < 600 ? 14.0 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (vPad * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // رأس القسم
                  _SectionHeader(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    actions: actions,
                    theme: theme,
                    textScaler: textScaler,
                    screenWidth: size.width,
                  ),
                  SizedBox(height: vPad),

                  // المحتوى أو الحالة الفارغة الافتراضية
                  Expanded(
                    child: content ?? _DefaultEmptyContent(
                      icon: icon,
                      title: emptyTitle ?? title,
                      description: emptyDescription ?? subtitle,
                      textScaler: textScaler,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// رأس القسم المتجاوب
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget>? actions;
  final ThemeData theme;
  final TextScaler textScaler;
  final double screenWidth;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.theme,
    required this.textScaler,
    required this.screenWidth,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = screenWidth < 600;
    final scaledTitle = textScaler.scale(isNarrow ? 18.0 : 20.0).clamp(14.0, 26.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.5 : 12.5).clamp(10.0, 16.0);

    final titleCol = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: isNarrow ? 18 : 22),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: scaledTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: scaledSub,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    if (actions == null || actions!.isEmpty) {
      return titleCol;
    }

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleCol,
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions!),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleCol),
        const SizedBox(width: 12),
        Wrap(spacing: 8, runSpacing: 8, children: actions!),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// حالة الفراغ الافتراضية
// ─────────────────────────────────────────────
class _DefaultEmptyContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final TextScaler textScaler;

  const _DefaultEmptyContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.textScaler,
  });

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(15.0).clamp(12.0, 20.0);
    final scaledDesc = textScaler.scale(12.5).clamp(10.0, 16.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scaledTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scaledDesc,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
