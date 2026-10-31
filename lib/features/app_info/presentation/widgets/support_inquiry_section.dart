import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../support/presentation/widgets/support_inquiry_form.dart';
import '../utils/external_links.dart';
import 'app_info_card.dart';
import 'whatsapp_icon.dart';

/// قسم «الاستفسار والحصول على مساعدة» — قناة تواصل مباشرة ثم نموذج يُحفظ في قاعدة البيانات
/// The "inquiry & help" section — a direct contact channel, then a form stored in the database.
///
/// **القناة المباشرة تخص الشركة لا المطور**: الرقم يأتي من `company_phone` في `APP_SETTINGS`،
/// وقسم «معلومات المطور» له رقمه الخاص ومكانه. تخليط الرقمين كان يوجّه شكوى العميل إلى مهندس
/// البرمجة بدل الجهة التي تبيع وتُفصّل.
/// **The direct channel belongs to the company, not the developer**: the number comes from
/// `company_phone` in `APP_SETTINGS`, while the developer section keeps its own number. Mixing the
/// two sent the customer's complaint to the software engineer instead of the shop.
///
/// النموذج يبقى تحت القناة المباشرة لأنه يصل إلى أي شخص حتى لو لم يكن أحد متاحاً على الهاتف،
/// ويعمل قبل الدخول أيضاً: الزائر يكتب اسمه وهاتفه ويُحفظ كزائر.
/// The form stays below the direct channel because it reaches a human even when nobody is on the
/// phone, and it works before login too — a guest writes a name and a phone and is stored as a guest.
class SupportInquirySection extends ConsumerWidget {
  const SupportInquirySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `contactPhone` لا `companyPhone`: يعود للرقم الافتراضي المضمّن إن كان المخزَّن فارغاً،
    // فلا يختفي زر التواصل لمجرد انقطاع الخادم أو كاش قديم.
    // `contactPhone` rather than `companyPhone`: it falls back to the baked-in number when the
    // stored value is blank, so the contact button never disappears because of a downed server.
    final phone = ref.watch(
      appConfigNotifierProvider.select((s) => s.config.contactPhone),
    );

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
                child: Tooltip(
                  // الضغط المطوّل يكشف الرقم المكتوب: الزر بنص «اتصال» وحده لا يقول أي رقم
                  // A long-press reveals the number itself: the “call” label alone never says which.
                  message: 'اتصال بالشركة: $phone',
                  child: OutlinedButton.icon(
                    onPressed: () => ExternalLinks.openTel(context, phone),
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
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Tooltip(
                  message: 'واتساب الشركة: $phone',
                  child: OutlinedButton.icon(
                    // واتساب الشركة: الرابط يُبنى من رقمها المطبَّع (`wa.me` لا يقبل `+`)
                    // The company's WhatsApp: the link is built from its normalised number.
                    onPressed: () => ExternalLinks.openWhatsappTo(context, phone),
                    icon: const WhatsAppIcon(size: 18),
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
