import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../utils/external_links.dart';
import 'app_info_card.dart';
import 'contact_icon_button.dart';

/// قسم «معلومات المطور» — الاسم وفي سطره نفسه أيقونتا اتصال وواتساب
/// The "developer information" section — the name with the call and WhatsApp icons on its own row.
///
/// اسم المطور هو هدف النقر الخفي الذي يفتح إعدادات الـ API خمس مرات (من شاشة الدخول وحدها).
/// لا يظهر أي أثر بصري للنقر: لا عدّاد ولا رسالة ولا اهتزاز — الطلب يمرّ بلا إعلان.
/// The developer's name is the hidden tap target that unlocks the API settings after five taps
/// (from the login screen only). No visual trace is left behind — no counter, no message, no
/// haptic — the request passes unannounced.
class DeveloperInfoSection extends StatelessWidget {
  const DeveloperInfoSection({
    this.onDeveloperNameTap,
    super.key,
  });

  /// يُستدعى عند كل نقرة على الاسم — `null` يعني أن النقر معطّل تماماً (بوابة الموظف)
  /// Called on every tap on the name — null disables tapping outright (the employee portal path).
  final VoidCallback? onDeveloperNameTap;

  @override
  Widget build(BuildContext context) {
    return AppInfoCard(
      title: 'معلومات المطور',
      icon: Icons.person_outline_rounded,
      tint: AppColors.accent,
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppColors.surfaceSubtle,
            child: Icon(
              Icons.engineering_rounded,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              // التصرف الافتراضي (opaque) يجعل مساحة الاسم كلها هدفاً، لا الحروف وحدها
              // Opaque hit-testing turns the whole name area into the target, not just glyphs.
              behavior: HitTestBehavior.opaque,
              onTap: onDeveloperNameTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kDeveloperName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تطوير وبرمجة التطبيق',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // أيقونتان صغيرتان بدل الزرّين العريضين: السطر يحمل الاسم والتواصل معاً،
          // ونص التلميح يحمل الرقم كما يُقرأ (لا اسم زر مكرّر يستهلك عرض السطر).
          // Two small icons replace the two wide buttons: the row now carries the name and the
          // contact side by side, and the tooltip holds the number as written — no duplicated
          // button label eating the row's width.
          ContactIconButton(
            icon: Icons.call_outlined,
            tooltip: kDeveloperPhoneDisplay,
            color: AppColors.primary,
            onPressed: () => ExternalLinks.openTel(context, kDeveloperPhone),
          ),
          const SizedBox(width: 8),
          ContactIconButton(
            icon: Icons.chat_rounded,
            tooltip: 'واتساب',
            color: AppColors.whatsapp,
            onPressed: () =>
                ExternalLinks.openWhatsapp(context, kDeveloperWhatsappUrl),
          ),
        ],
      ),
    );
  }
}
