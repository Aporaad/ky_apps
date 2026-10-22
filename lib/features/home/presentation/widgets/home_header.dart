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

/// ترويسة الرئيسية: بطاقة ترحيب بتدرّج خفيف، تحمل التحية والتاريخ وزر التخصيص
/// The home header: a welcome card with a soft gradient carrying the greeting, the date, and the
/// customisation action.
///
/// صارت بطاقة لا سطرًا عائمًا: صفحة تبدأ بمربّع ملوّن ثم شبكة بطاقات تحتاج رأسًا يجمعها بصريًا،
/// وإلا قرأ المستخدم التحية كعنصر منفصل عن الصفحة.
/// It is a card rather than a floating line: a page that opens with a tinted square and a card grid
/// needs a head that binds them, or the greeting reads as unrelated to the page.
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

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.07),
            Colors.white,
          ],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 46 : 54,
            height: compact ? 46 : 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: HomeTokens.cardShadow(),
            ),
            child: Icon(
              Icons.space_dashboard_rounded,
              color: Colors.white,
              size: compact ? 23 : 27,
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
                    fontSize: titleSize-5,
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
                    fontSize: subtitleSize-3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            // زر أبيض على تدرّج فاتح: الزر الممتلئ بلون داكن كان يقرأ كبقعة غريبة
            // A white button on the light gradient: a filled dark button read as a stray blob.
            Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.30),
                ),
              ),
              child: IconButton(
                onPressed: onCustomize,
                tooltip: 'تخصيص الاختصارات',
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: onCustomize,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text(
                'تخصيص',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
