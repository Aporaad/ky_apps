import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../employee_portal/domain/portal_section_titles.dart';
import '../../domain/home_card_size.dart';
import '../../domain/home_shortcut.dart';
import 'home_tokens.dart';

/// بطاقة اختصار: أيقونة صلبة، عنوان، وسطر القسم — موزّعة على كامل البطاقة
/// A shortcut card: a solid icon tile, a title, and the section caption, spread across the tile.
///
/// لماذا `spaceEvenly` لا التوسيط؟ في بطاقة 190dp كان المحتوى يشغل 100dp ويترك 90dp بيضاء في
/// المنتصف — وهي «البطاقة الوفت» التي اشتكى منها المستخدم. التوزيع المتساوي يمدّ الفراغ على
/// الفواصل كلها فلا بقعة ميتة، ويتركّز المحتوى بصريًا في البطاقة.
/// Why `spaceEvenly` rather than centring? In a 190dp tile the content took 100dp and left 90dp of
/// white in the middle — the hollow card the user reported. Even distribution spreads that slack
/// across every gap, so there is no dead patch and the content reads as filling the tile.
class HomeShortcutCard extends StatefulWidget {
  const HomeShortcutCard({
    super.key,
    required this.shortcut,
    required this.size,
    required this.onTap,
    this.onLongPress,
  });

  final HomeShortcut shortcut;

  /// كثافة البطاقة ونسبتها — تأتي من تخصيص المستخدم
  /// Card density and ratio — driven by the user's customisation.
  final HomeCardSize size;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<HomeShortcutCard> createState() => _HomeShortcutCardState();
}

class _HomeShortcutCardState extends State<HomeShortcutCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shortcut = widget.shortcut;
    final size = widget.size;
    final accent = HomeTokens.sectionColor(shortcut.sectionId);
    final sectionTitle = PortalSectionTitles.of(shortcut.sectionId);
    final textScaler = MediaQuery.textScalerOf(context);

    // سطر القسم يُخفى حين يكرّر العنوان: «العملاء» تحت «العملاء» حشو بصري لا معلومة
    // The caption is hidden when it repeats the title: «العملاء» under «العملاء» is visual noise.
    final captionText = sectionTitle == shortcut.title ? null : sectionTitle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: HomeTokens.press,
        curve: Curves.easeOut,
        child: Semantics(
          button: true,
          label: '${shortcut.title} — $sectionTitle',
          child: AnimatedContainer(
            duration: HomeTokens.hover,
            curve: Curves.easeOut,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // أبيض موحّد لكل البطاقات: تلوين كل قسم بدرجة مختلفة هو ما جعل الشبكة تبدو غير منسّقة
              // Uniform white for every card: tinting each section differently is what made the
              // grid read as uncoordinated.
              color: Colors.white,
              borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
              border: Border.all(
                color:
                    _hovered
                        ? accent.withValues(alpha: 0.55)
                        : AppColors.border,
                width: _hovered ? 1.4 : 1,
              ),
              boxShadow: HomeTokens.cardShadow(hover: _hovered),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onHighlightChanged: (value) {
                  if (_pressed != value) setState(() => _pressed = value);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // القياسات مشتقّة من عرض البطاقة لا من الحجم وحده: بطاقة 190dp تحتاج أيقونة
                    // وخطًا أكبر من بطاقة 120dp، وإلا بدت الأولى فارغة والثانية مخنوقة
                    // Metrics derive from the tile's width, not the size setting alone: a 190dp
                    // tile needs a bigger icon and type than a 120dp one, or the first looks empty
                    // and the second cramped.
                    final width = constraints.maxWidth;
                    final micro = width < 96;
                    final density =
                        size == HomeCardSize.small
                            ? 0.94
                            : size == HomeCardSize.large
                            ? 1.06
                            : 1.0;

                    final titleSize = textScaler
                        .scale(
                          micro
                              ? 9.5
                              : (width * 0.075 * density).clamp(9.5, 16.0),
                        )
                        .clamp(9.0, 19.0);
                    final captionSize = textScaler
                        .scale((width * 0.055).clamp(9.0, 12.0))
                        .clamp(8.5, 14.0);
                    final padding =
                        micro ? 5.0 : (width * 0.05).clamp(7.0, 13.0);
                    final gap = micro ? 3.0 : 10.0;
                    final lineHeight = titleSize * 1.25;
                    // سطران في الوضع المصغّر يحتاجان ارتفاعًا؛ وتحتهما سطر واحد أنظف من قصّ
                    // حرفين ظاهرين. والهامش 6dp يمتصّ فروق مقاييس الخط الحقيقية عن الحساب
                    // Two lines need height in micro mode; below that one line beats clipping.
                    // The 6dp margin absorbs real font metrics exceeding the arithmetic estimate.
                    final titleLines =
                        micro ? (constraints.maxHeight >= 74 ? 2 : 1) : 2;
                    const safety = 6.0;

                    /// ما تبقّى للأيقونة بعد الحشو وسطرَي العنوان (واختياريًا سطر القسم)
                    /// What is left for the icon after padding, two title lines, and optionally
                    /// the caption line.
                    double iconRoom({required bool withCaption}) =>
                        constraints.maxHeight -
                        padding * 2 -
                        gap -
                        lineHeight * titleLines -
                        safety -
                        (withCaption ? 3 + captionSize : 0);

                    // سطر القسم يُسقط أولًا، ثم تُق shrink الأيقونة إن ضاقت المساحة — الترتيب
                    // مقصود: النص أهم من حجم الأيقونة، والتجاوز أسوأ من الاثنين
                    // The caption goes first, then the icon shrinks if space is still short —
                    // deliberate order: text matters more than icon size, and overflow is worse
                    // than both.
                    final baseIcon =
                        micro
                            ? 24.0
                            : (width * 0.40 * density).clamp(24.0, 76.0);

                    // سطر القسم يُحجز دائمًا لمقاسٍ معيّن — حتى حين يغيب نصّه — فتتساوى ارتفاعات
                    // الكتل، وتصطفّ الأيقونات على خط واحد، ويبقى التوسيط متوازنًا. وإن ضاقت
                    // البطاقة عن الحجز أُسقط كلّيًا بدل أن يختنق المحتوى.
                    // The caption line is always reserved for a given size — even when its text is
                    // absent — so block heights match, icons align, and centring stays balanced.
                    // If the tile cannot afford the reservation it is dropped entirely rather than
                    // squeezing the content.
                    // الحجز مشروط بوجود نصّ فعلي: حجز سطر فارغ كان يُزيح المحتوى المرئي عن
                    // مركز البطاقة — والتوازن البصري أولى من تساوي الارتفاعات تمامًا
                    // The reservation requires actual text: reserving an empty line pushed the
                    // visible content off the card's centre — visual balance beats exact equality.
                    var reserveCaption =
                        !micro && size.showCaption && captionText != null;
                    var iconBox = baseIcon
                        .clamp(16.0, iconRoom(withCaption: reserveCaption))
                        .clamp(16.0, 76.0);
                    if (reserveCaption && iconBox < 22) {
                      reserveCaption = false;
                      iconBox = baseIcon
                          .clamp(16.0, iconRoom(withCaption: false))
                          .clamp(16.0, 76.0);
                    }
                    final displayCaption =
                        reserveCaption && captionText != null;

                    return Padding(
                      padding: EdgeInsets.all(padding),
                      // توسيط عمودي: الكتلة في منتصف البطاقة بفراغ متساوٍ أعلاها وأسفلها.
                      // كانت المحاذاة العلوية تحلّ اصطفاف الأيقونات لكنها تركت ثلث البطاقة
                      // فارغًا في الأسفل — والآن يضمن الحجز الثابت أن الكتل متساوية الارتفاع،
                      // فيتحقّق الاصطفاف والتوازن معًا.
                      // Vertical centring: the block sits in the middle with equal space above and
                      // below. Top alignment fixed icon alignment but left a third of the card empty
                      // at the bottom; the fixed reservation now keeps block heights equal, so
                      // alignment and balance hold at once.
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _IconBadge(
                            icon: shortcut.icon,
                            color: accent,
                            box: iconBox,
                            micro: micro,
                            badge: shortcut.underDevelopment,
                          ),
                          SizedBox(height: gap),
                          // ارتفاع ثابت = سطران: عنوان من سطر واحد يحتلّ المساحة نفسها فلا
                          // تنزاح الكتلة عن مركزها ولا يخرج جارها عن الخط
                          // A fixed height of two lines: a one-line title occupies the same space,
                          // so the block never drifts off centre and neighbours stay on the line.
                          SizedBox(
                            // +2: مقاييس الخط الحقيقية تزيد جزءًا عن الحساب، وبدونها
                            // يئنّ السطر الثاني فيُقصّ العنوان إلى سطر واحد بثلاث نقاط
                            // +2: real font metrics exceed the arithmetic, and without it the
                            // second line is squeezed and the title collapses to one line.
                            height: lineHeight * titleLines + 2,
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                shortcut.title,
                                textAlign: TextAlign.center,
                                maxLines: titleLines,
                                // الحجم محسوب يدويًا ومقيّد أعلاه؛ تمرير المقياس المحيط مرّة
                                // ثانية يكبّر الخط إلى 1.56 على 1.25 ويتجاوز البطاقة
                                // The size is computed and clamped above; letting the ambient
                                // scaler apply again would reach 1.56 at 1.25 and overflow.
                                textScaler: TextScaler.noScaling,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ),
                          if (reserveCaption)
                            SizedBox(
                              height: 3 + captionSize + 2,
                              child: Align(
                                alignment: Alignment.center,
                                child:
                                    displayCaption
                                        ? Text(
                                          captionText,
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          textScaler: TextScaler.noScaling,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: captionSize,
                                            color: AppColors.textSecondary,
                                          ),
                                        )
                                        : const SizedBox.shrink(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }
}

/// صندوق الأيقونة الصلب: لون القسم معتّقًا قليلًا نحو النص، وأيقونة بيضاء
/// The solid icon tile: the section colour deepened toward the text colour, with a white icon.
///
/// التعبئة الشفافة (14%) كانت تُنتج أيقونات باهتة على أبيض. تعميق اللون بـ18% نحو `textPrimary`
/// يعطي لونًا مشبعًا مقروءًا مع الأيقونة البيضاء، ويبقى مشتقًّا من لوحة التطبيق لا لونًا مُبتكرًا.
/// The old 14% tint produced washed-out icons on white. Deepening the colour 18% toward
/// `textPrimary` yields a saturated tile that reads with a white icon, still derived from the app
/// palette rather than a new colour.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.box,
    required this.micro,
    required this.badge,
  });

  final IconData icon;
  final Color color;
  final double box;
  final bool micro;

  /// شارة «قيد التطوير» تلتصق بزاوية الصندوق فلا تزاحم المحتوى المتوسّط
  /// The "under development" badge rides the tile's corner so it never crowds the content.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final tile = Color.lerp(color, AppColors.textPrimary, 0.18) ?? color;
    final radius = micro ? 8.0 : (box * 0.3).clamp(10.0, 18.0);

    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: tile.withValues(alpha: 0.30),
                  blurRadius: micro ? 4 : 9,
                  offset: Offset(0, micro ? 1 : 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: box * 0.5),
          ),
          if (badge)
            PositionedDirectional(
              top: -4,
              start: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  'قريبًا',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: micro ? 7 : 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
