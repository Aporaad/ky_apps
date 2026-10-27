import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// ط¨ط·ط§ظ‚ط© ظ…ظˆط­ظ‘ط¯ط© ظ„ط£ظ‚ط³ط§ظ… ط´ط§ط´ط© آ«ظ…ط¹ظ„ظˆظ…ط§طھ ط§ظ„ط¨ط±ظ†ط§ظ…ط¬ ظˆط§ظ„ط¯ط¹ظ…آ»
/// The shared card used by every section of the app-info & support screen.
///
/// ط§ظ„ط´ظƒظ„ ظˆط§ط­ط¯ ظپظٹ ط§ظ„ط£ظ‚ط³ط§ظ… ط§ظ„ط«ظ„ط§ط«ط© â€” ط¨ط·ط§ظ‚ط© ط¨ظٹط¶ط§ط،طŒ ط±ط£ط³ ط¨ط¹ظ†ظˆط§ظ† ظˆط£ظٹظ‚ظˆظ†ط© ط¯ط§ط®ظ„ ظ…ط±ط¨ط¹ ظ…ظ„ظˆظ‘ظ† ط´ظپط§ظپطŒ
/// ط«ظ… ط§ظ„ظ…ط­طھظˆظ‰ â€” ظ„ط£ظ† ط§ظ„ط´ط§ط´ط© ط§ظ„ط±ط³ظ…ظٹط© طھظڈظ‚ط±ط£ ظƒطµظپط­ط© ظˆط§ط­ط¯ط© ظ„ط§ ظƒط«ظ„ط§ط« ظ„ظˆط­ط§طھ ظ…ط®طھظ„ظپط©.
/// One shape across the three sections â€” a white card with a titled header whose icon sits in a
/// tinted square, then the content â€” because an official screen reads as one page, not as three
/// unrelated panels.
class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    required this.title,
    required this.icon,
    required this.child,
    this.tint,
    this.action,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// ظ„ظˆظ† ط£ظٹظ‚ظˆظ†ط© ط§ظ„ط±ط£ط³ ظˆط®ظ„ظپظٹطھظ‡ط§ ط§ظ„ط´ظپط§ظپط© â€” `null` ظٹط¹ظ†ظٹ ظ„ظˆظ† ط§ظ„طھط·ط¨ظٹظ‚ ط§ظ„ط£ط³ط§ط³ظٹ
  /// The tint of both the header icon and its translucent square; null means the primary color.
  ///
  /// `null` ظ„ط§ `AppColors.primary` ظƒظ‚ظٹظ…ط© ط§ظپطھط±ط§ط¶ظٹط©: ط§ظ„ظ„ظˆظ† ط§ظ„ط£ط³ط§ط³ظٹ `getter` ظٹظ‚ط±ط£ ط§ظ„طھظ‡ظٹط¦ط© ط§ظ„ط²ظ…ظ†ظٹط©طŒ
  /// ظˆظ‚ظٹظ…ط© ط§ظپطھط±ط§ط¶ظٹط© ظپظٹ ظˆط³ظٹط· `const` ظ„ط§ طھظ‚ط¨ظ„ ط¥ظ„ط§ ط«ط§ط¨طھط§ظ‹.
  /// Null rather than AppColors.primary as the default: the primary color is a getter over the
  /// runtime palette, and a const constructor's default must be a compile-time constant.
  final Color? tint;

  /// ط¹ظ†طµط± ط±ط£ط³ظٹظ‘ ط§ط®طھظٹط§ط±ظٹ (ط²ط± طھط­ط¯ظٹط« ظ…ط«ظ„ط§ظ‹) ظٹظڈط¹ط±ط¶ ظپظٹ ظ†ظ‡ط§ظٹط© طµظپ ط§ظ„ط¹ظ†ظˆط§ظ†
  /// An optional header action (a refresh button, say) shown at the end of the title row.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 19, color: tint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}
