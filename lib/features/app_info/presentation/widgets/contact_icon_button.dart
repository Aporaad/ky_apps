import 'package:flutter/material.dart';

/// زر تواصل دائري صغير بأيقونة وحدها — بلا نص ظاهر
/// A small circular contact button: an icon alone, with no visible label.
///
/// يُستعمل في موضعين: صف اسم المطور (اتصال/واتساب) وأسفل بطاقة الدخول (التواصل مع الشركة).
/// الحجم الافتراضي 36 بكسل — أصغر من هدف اللمس القياسي (48) بطلب صريح من المستخدم، فيُعوَّض
/// المعنى بـ `Tooltip` يُقرأ بالضغط المطوّل ويُعلَن لقارئ الشاشة.
/// It serves two places: the developer-name row (call/WhatsApp) and the bottom of the login card
/// (contacting the company). The default 36 px is smaller than the 48 px standard target — an
/// explicit request — so the meaning is carried by a [Tooltip] on long-press and to screen readers.
class ContactIconButton extends StatelessWidget {
  const ContactIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
    this.size = 36,
    super.key,
  });

  /// الرمز داخل الزر — `Icon` عادي أو شعار علامة مثل `WhatsAppIcon`
  /// The glyph inside the button — a plain [Icon] or a brand mark such as `WhatsAppIcon`.
  ///
  /// ودجت لا `IconData`: شعار واتساب الرسمي يأتي من خط علامات لا من `Icons`، فلو حُصر الحقُّل
  /// بـ `IconData` لتعذّر تمريره إلا بتحايل.
  /// A widget rather than an `IconData`: the official WhatsApp mark comes from a brand font, not
  /// from `Icons`, so an `IconData` field could not carry it.
  final Widget icon;

  /// نص التلميح — يُقرأ بالضغط المطوّل ولا يُرسم فوق الصفحة
  /// The tooltip text — read on long-press and never painted over the page.
  final String tooltip;

  /// لون الأيقونة وخلفيتها الشفافة (الأساسي للاتصال، أخضر واتساب للمراسلة)
  /// The icon color and its translucent background (primary for calls, WhatsApp green for chat).
  final Color color;

  final VoidCallback? onPressed;

  /// قطر الزر — 36 افتراضياً
  /// The button's diameter — 36 by default.
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 2);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
