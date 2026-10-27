import 'package:flutter/material.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../support/presentation/widgets/support_inquiry_form.dart';
import '../utils/external_links.dart';
import 'app_info_card.dart';

/// قسم «الاستفسار والحصول على مساعدة» — قناة تواصل مباشرة ثم نموذج يُحفظ في قاعدة البيانات
/// The "inquiry & help" section — a direct contact channel, then a form stored in the database.
///
/// القناة المباشرة أولاً لأنها الأسرع، والنموذج تحتها لأنها القناة التي تصل إلى أي شخص حتى لو لم
/// يكن أحد متاحاً على الهاتف. القسم يعمل قبل الدخول أيضاً: الزائر يكتب اسمه وهاتفه ويُحفظ كزائر.
/// Direct contact comes first because it is fastest; the form sits below because it reaches a
/// human even when nobody is on the phone. The section works before login too — a guest writes a
/// name and a phone and is stored as a guest.
class SupportInquirySection extends StatelessWidget {
  const SupportInquirySection({super.key});

  @override
  Widget build(BuildContext context) {
    return AppInfoCard(
      title: 'الاستفسار والحصول على مساعدة',
      icon: Icons.support_agent_rounded,
      tint: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'للاقتراحات أو الشكاوى أو طلب المساعدة، تواصل معنا مباشرة أو أرسل استفسارك '
            'وسيصلك الرد في أقرب وقت.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.65,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ExternalLinks.openTel(context, kDeveloperPhone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: const Text('اتصال'),
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
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ExternalLinks.openWhatsapp(context, kDeveloperWhatsappUrl),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('واتساب'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.whatsapp,
                    side: BorderSide(color: AppColors.whatsapp),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          const SupportInquiryForm(),
        ],
      ),
    );
  }
}
