import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_tokens.dart';

/// حالة فارغة واحدة الشكل لكل مواقف الرئيسية: لا منح، أو تصفية بلا نتيجة
/// One empty state for every home dead-end: no grants, or a filter with no result.
///
/// الحالة الفارغة هنا ليست زينة: الحجب الافتراضي يعني أن موظفًا جديدًا قد يصل إلى صفحة بلا
/// بطاقة واحدة، ولو تُركت بيضاء لقرأها عطلًا في النظام لا نقصًا في صلاحياته.
/// It is not decoration: deny-by-default means a freshly created employee can land on a page with
/// no card at all, and a blank page would read as an outage rather than a missing grant.
class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleSize = textScaler.scale(14.5).clamp(12.0, 20.0);
    final messageSize = textScaler.scale(12.0).clamp(10.0, 16.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: messageSize,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
