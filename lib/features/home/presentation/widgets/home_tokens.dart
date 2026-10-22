import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// رموز تصميم الواجهة الرئيسية: مسافات وأنصاف أقطار وظلال وحساب الأعمدة
/// Home design tokens: spacing, radii, shadows, and the column calculation.
///
/// في ملف واحد لأن الرئيسية كلها تُقاس من هنا: بطاقة تُعدّل حشوها بمعزل عن الشبكة تنحرف عن
/// جارتها عند أول تغيير. ولا لون صلب هنا — كل لون يُقرأ من [AppColors] ليبقى تابعًا لتهيئة
/// الشركة القادمة من الخادم.
/// One file because the whole screen is measured from here: a card that adjusts its own padding in
/// isolation drifts from its neighbours at the first change. No literal colours — everything reads
/// [AppColors] so it follows the server-driven company theme.
class HomeTokens {
  HomeTokens._();

  /// أقصى عرض للمحتوى: الشبكة على سطح مكتب عريض تتوقف عن التمدد
  /// Content ceiling: the grid stops stretching on a wide desktop.
  static const double contentMaxWidth = 1180;

  static const double cardRadius = 16;
  static const double badgeRadius = 14;
  static const double iconBox = 44;
  static const double iconSize = 22;

  /// أصغر ضلع مسموح للبطاقة — الحدّ الذي يحتمل عنوانًا من سطرين عند تكبير الخط 1.25
  /// Smallest allowed tile edge — the size that still fits a two-line title at text scale 1.25.
  static const double minTile = 150;

  static const Duration press = Duration(milliseconds: 120);
  static const double titleSize = 13.5;
  static const double captionSize = 10.5;

  /// حشو الصفحة الجانبي حسب عرض الشاشة
  /// Horizontal page padding by screen width.
  static double pagePadding(double width) {
    if (width < 600) return 16;
    if (width < 1100) return 20;

    return 24;
  }

  /// الفراغ بين البطاقات
  /// Gap between tiles.
  static double gap(double width) {
    if (width < 600) return 12;
    if (width < 1100) return 14;

    return 16;
  }

  /// عدد الأعمدة: يضمن ألّا ينزل ضلع البطاقة تحت [minTile]، ويقبل حده الأدنى عمودين
  /// Columns: never lets a tile fall below [minTile], and floors at two columns.
  ///
  /// 320dp ⇒ عمودان بضلع 137 (أضيق جهاز مدعوم)، و1180dp ⇒ ستة أعمدة بضلع 181.
  /// 320dp ⇒ two columns of 137 (the narrowest supported device), 1180dp ⇒ six of 181.
  static int columns(double width) {
    const gap = 14.0;
    final fit = ((width + gap) / (minTile + gap)).floor();

    return fit.clamp(2, 6);
  }

  /// ظل البطاقة: ساكن وخفيف، ويرتفع قليلًا عند التحويم على سطح المكتب
  /// Card shadow: light at rest, slightly lifted on desktop hover.
  static List<BoxShadow> cardShadow({bool hover = false}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: hover ? 0.08 : 0.04),
        blurRadius: hover ? 14 : 8,
        offset: Offset(0, hover ? 4 : 2),
      ),
    ];
  }

  /// لون القسم: من ألوان التطبيق الدلالية القائمة فقط
  /// Section colour: from the app's existing semantic palette only.
  static Color sectionColor(String sectionId) {
    switch (sectionId) {
      case 'sales':
      case 'workers':
        return AppColors.success;
      case 'tailoring':
      case 'stores':
        return AppColors.warning;
      case 'management':
        return AppColors.info;
      case 'settings':
        return AppColors.accent;
      case 'home':
        return AppColors.primaryDark;
      default:
        return AppColors.primary;
    }
  }
}
