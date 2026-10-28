import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// بطاقة عملية داخل لوحة قسم التفصيل — نفس تصميم بطاقات الأقسام الأخرى
/// An action card inside the tailoring dashboard — the same design as the other sections.
///
/// [isPrototype] يضيف شارة «نموذج أولي» دائمة على البطاقة، لأن ثلاث شاشات من الأربع
/// واجهات قراءة فقط بلا حفظ؛ إخفاء ذلك عن المستخدم يجعل الواجهة تكذب.
/// [isPrototype] adds a permanent prototype chip: three of the four screens are read-only
/// mock-ups, and hiding that from the user would make the UI lie.
class TailoringActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final Color accent;
  final VoidCallback onTap;

  /// شارة إضافية دائمة: «نموذج أولي»
  /// An extra permanent chip: "prototype".
  final bool isPrototype;

  const TailoringActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.accent,
    required this.onTap,
    this.isPrototype = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style:  TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _chip(badge, accent),
                        // if (isPrototype) ...[
                        //   const SizedBox(width: 4),
                        //   _chip('نموذج أولي', AppColors.warning),
                        // ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accent.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
