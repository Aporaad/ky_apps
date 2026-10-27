import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../utils/external_links.dart';
import 'app_info_card.dart';

/// قسم «معلومات المطور» — الاسم والهاتف وزر واتساب
/// The "developer information" section — name, phone, and the WhatsApp button.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ExternalLinks.openTel(context, kDeveloperPhone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text(kDeveloperPhoneDisplay),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      ExternalLinks.openWhatsapp(context, kDeveloperWhatsappUrl),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('واتساب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsapp,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
