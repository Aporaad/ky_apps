import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'home_tokens.dart';

/// أسماء أيام الأسبوع بالعربية، بترتيب `DateTime.weekday` (الاثنين = 1)
/// Arabic weekday names, in `DateTime.weekday` order (Monday = 1).
const List<String> _weekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// أسماء الشهور الميلادية كما تُكتب في المراسلات العربية
/// Gregorian month names as written in Arabic correspondence.
const List<String> _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// التاريخ بصيغة «الخميس 22 أكتوبر 2026»
/// The date as «الخميس 22 أكتوبر 2026».
///
/// يدوي بلا `intl`: الحزمة غير معلنة في `pubspec.yaml`، واستيرادها المباشر يخالف قاعدة
/// «لا تبعيات جديدة» ويكسر `depend_on_referenced_packages`.
/// Hand-rolled without `intl`: the package is not declared in `pubspec.yaml`, and importing it
/// directly breaks the no-new-dependencies rule and `depend_on_referenced_packages`.
String arabicDate(DateTime date) {
  final weekday = _weekdays[(date.weekday - 1).clamp(0, 6)];
  final month = _months[(date.month - 1).clamp(0, 11)];

  return '$weekday ${date.day} $month ${date.year}';
}

/// التحية حسب ساعة الجهاز
/// The greeting, by the device clock.
String greetingForHour(int hour) {
  if (hour < 12) return 'صباح الخير';
  if (hour < 17) return 'مساء الخير';

  return 'مساء النور';
}

/// ترويسة الرئيسية: تحية الموظف وتاريخ اليوم وزر التخصيص
/// The home header: the employee's greeting, today's date, and the customise action.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.displayName,
    required this.onCustomize,
    this.branchNo,
    this.now,
  });

  final String displayName;
  final VoidCallback onCustomize;
  final int? branchNo;

  /// يُمرَّر في الاختبارات لتثبيت التاريخ؛ وفي التشغيل هو `DateTime.now()`
  /// Injected by tests to pin the date; at runtime it is `DateTime.now()`.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final moment = now ?? DateTime.now();
    final name = displayName.trim().isEmpty ? 'الموظف' : displayName.trim();

    final greeting = greetingForHour(moment.hour);
    final date = arabicDate(moment);
    final subtitle = branchNo == null ? date : '$date · فرع $branchNo';

    final titleSize = textScaler.scale(compact ? 17.0 : 19.0).clamp(13.0, 24.0);
    final subtitleSize = textScaler
        .scale(compact ? 11.0 : 12.0)
        .clamp(9.5, 15.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 44 : 50,
          height: compact ? 44 : 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(HomeTokens.badgeRadius),
          ),
          child: Icon(
            Icons.space_dashboard_rounded,
            color: Colors.white,
            size: compact ? 22 : 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting، $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onCustomize,
          tooltip: 'تخصيص الاختصارات',
          icon: const Icon(Icons.tune_rounded, size: 20),
        ),
      ],
    );
  }
}
