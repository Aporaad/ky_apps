import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/home_card_size.dart';

/// رموز تصميم الواجهة الرئيسية: مسافات وأنصاف أقطار وظلال وتدرّجات وحساب الأعمدة
/// Home design tokens: spacing, radii, shadows, gradients, and the column calculation.
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
  static const double contentMaxWidth = 1240;

  static const double cardRadius = 18;
  static const double badgeRadius = 14;
  static const double captionSize = 10.5;

  /// أقصى عدد أعمدة مسموح — سبعة تصنع بطاقات أضيق من نصّها
  /// Highest allowed column count — seven makes tiles narrower than their own labels.
  static const int maxColumns = 6;

  /// أقل عدد أعمدة مسموح: عمود واحد يحوّل الشبكة إلى قائمة ويُفقدها معناها
  /// Lowest allowed column count: a single column turns the grid into a list.
  static const int minColumns = 2;

  static const Duration press = Duration(milliseconds: 120);
  static const Duration hover = Duration(milliseconds: 160);

  /// حشو الصفحة الجانبي حسب عرض الشاشة
  /// Horizontal page padding by screen width.
  static double pagePadding(double width) {
    if (width < 600) return 16;
    if (width < 1100) return 24;

    return 32;
  }

  /// عدد الأعمدة: العدد المثبّت يتقدّم، وإلا يُشتق من حدّ ضلع الحجم الحالي
  /// Columns: a pinned count wins, otherwise derived from the current size's minimum edge.
  ///
  /// 320dp بالحجم المتوسط ⇒ عمودان بضلع 137، و1240dp ⇒ ستة بضلع 190.
  /// 320dp at medium ⇒ two columns of 137, 1240dp ⇒ six of 190.
  /// أقل ضلع تُقرأ عنده البطاقة: تحته تختنق الأيقونة والعنوان
  /// The narrowest edge at which a card still reads: below it the icon and title choke.
  /// أرضية صلبة: تحتها تصير البطاقة أيقونةً بلا عنوان. عند 72dp يعمل الوضع المصغّر في البطاقة
  /// A hard floor: below it a card is an icon with no title. At 72dp the card's micro mode works.
  static const double minReadableTile = 72;

  static int columns(
    double width, {
    required HomeCardSize size,
    int fixed = 0,
  }) {
    // سقف العدّ من الأرضية الصلبة لا من حدّ الحجم: الاختيار الصريح يجب أن يُرى، ثم تُصغّر
    // البطاقة داخليًا (وضع مصغّر) بدل أن يُلغى الاختيار بصمت
    // The count ceiling uses the hard floor, not the size's target: an explicit choice must be
    // visible, and the card then shrinks internally (micro mode) instead of being silently voided.
    const floor = HomeTokens.minReadableTile;
    const floorGap = 8.0;
    final ceiling = ((width + floorGap) / (floor + floorGap)).floor().clamp(
      minColumns,
      maxColumns,
    );

    if (fixed >= minColumns && fixed <= maxColumns) {
      return fixed.clamp(minColumns, ceiling);
    }

    final fit = ((width + size.gap) / (size.minTile + size.gap)).floor();

    return fit.clamp(minColumns, ceiling);
  }

  /// ظل البطاقة: ساكن وخفيف، ويرتفع عند التحويم على سطح المكتب
  /// Card shadow: light at rest, lifted on desktop hover.
  static List<BoxShadow> cardShadow({bool hover = false}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: hover ? 0.10 : 0.045),
        blurRadius: hover ? 20 : 10,
        offset: Offset(0, hover ? 7 : 2),
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
