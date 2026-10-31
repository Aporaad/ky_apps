import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// شعار واتساب الرسمي — بديل صريح للرمز العام `Icons.chat_rounded`
/// The official WhatsApp mark — an explicit replacement for the generic `Icons.chat_rounded`.
///
/// Material Icons لا تحوي شعار واتساب، وفقاعة دردشة عامة لا يقرأها المستخدم كواتساب. لذلك يأتي
/// الشعار من خط العلامات الرسمي (Font Awesome Brands)، ويُقلَّم عند البناء إلى هذا الرمز وحده.
/// Material Icons carries no WhatsApp logo, and a generic chat bubble is not read as WhatsApp. The
/// mark therefore comes from the official brand font, tree-shaken at build time to this one glyph.
///
/// يُستعمل في ثلاثة مواضع: سطر اسم المطور، وقسم الاستفسار والمساعدة، وأسفل بطاقة الدخول.
/// It is used in three places: the developer row, the inquiry section, and under the login card.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({
    this.size = 18,
    this.color = AppColors.whatsapp,
    super.key,
  });

  final double size;

  /// لون الشعار — أخضر واتساب الرسمي افتراضاً
  /// The mark's color — the official WhatsApp green by default.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      FontAwesomeIcons.whatsapp,
      size: size,
      color: color,
      // الشعار بلا نص بجانبه، فيُعلَن لقارئ الشاشة بهذا الوسم
      // The mark stands alone, so it is announced to screen readers through this label.
      semanticLabel: 'واتساب',
    );
  }
}
