import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/widgets/api_password_dialog.dart';
import '../../../settings/presentation/screens/api_settings_screen.dart';
import '../utils/developer_tap_unlock.dart';
import '../widgets/company_info_section.dart';
import '../widgets/developer_info_section.dart';
import '../widgets/support_inquiry_section.dart';

/// شاشة «معلومات البرنامج والدعم» — الأقسام الثلاثة في صفحة واحدة رسمية
/// The "app info & support" screen — the three sections on one official page.
///
/// تُفتح من مكانين: زر على شاشة الدخول ([allowApiUnlock] = true، فتُتاح بوابة إعدادات الـ API
/// السرّية)، وعنصر «معلومات التطبيق» في إعدادات الموظف ([allowApiUnlock] = false، فلا نقر خفي
/// ولا وصول إلى إعدادات الخادم). نفس القسم المرئي في الحالتين — الفرق في البوابة وحدها.
/// It is opened from two places: a button on the login screen ([allowApiUnlock] = true, so the
/// hidden API-settings gate is live) and the "app info" tile in employee settings
/// ([allowApiUnlock] = false, so there is no hidden tap and no route to server settings). The
/// visible content is identical — only the gate differs.
class AppInfoScreen extends ConsumerStatefulWidget {
  const AppInfoScreen({super.key, this.allowApiUnlock = false});

  /// هل يُسمح بفتح إعدادات الـ API بعد خمس نقرات على اسم المطور؟ (شاشة الدخول فقط)
  /// Whether five taps on the developer's name may unlock the API settings (login screen only).
  final bool allowApiUnlock;

  @override
  ConsumerState<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends ConsumerState<AppInfoScreen> {
  /// عدّاد النقرات الخفي — يعيش مع الشاشة، فالخروج منها يلغي كل تقدّم حصل
  /// The hidden tap counter — lives with the screen, so leaving it discards any progress made.
  final DeveloperTapUnlock _unlock = DeveloperTapUnlock();

  @override
  Widget build(BuildContext context) {
    final companyName =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.companyName));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('معلومات البرنامج والدعم'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  const CompanyInfoSection(),
                  const SizedBox(height: 12),
                  DeveloperInfoSection(
                    // null يعطّل النقر تماماً في بوابة الموظف
                    // null disables tapping outright on the employee-portal path.
                    onDeveloperNameTap: widget.allowApiUnlock
                        ? _handleDeveloperUnlock
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const SupportInquirySection(),
                  const SizedBox(height: 16),
                  _footer(companyName),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// رأس الشاشة: الشعار ثم شارة الإصدار — بلا اسم الشركة
  /// The screen header: the logo, then the version badge — without the company name.
  ///
  /// الاسم يعيش في بطاقة «معلومات الشركة» وحدها: تكراره هنا كان يعرضه مرتين في نفس النافذة،
  /// والترويسة الرسمية تذكر الاسم مرة واحدة بعد الشعار.
  /// The name lives in the "company information" card alone: repeating it here printed it twice in
  /// one viewport, while an official letterhead states the name once, after the logo.
  Widget _header() {
    return Column(
      children: [
        const AppLogo(width: 150, height: 100),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v$kAppVersionBadge',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// التذييل: النسخة والحقوق — السنة من ساعة الجهاز
  /// The footer: version and copyright — the year comes from the device clock.
  Widget _footer(String companyName) {
    final name = companyName.trim();
    final year = DateTime.now().year;

    return Column(
      children: [
        Text(
          'الإصدار v$kAppVersionBadge',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          name.isEmpty
              ? 'جميع الحقوق محفوظة © $year'
              : 'جميع الحقوق محفوظة © $name $year',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// بوابة إعدادات الـ API: خمس نقرات خلال 3 ثوانٍ ثم كلمة السر — في كل مرة
  /// The API-settings gate: five taps within 3 seconds, then the password — every single time.
  ///
  /// لا يُحفَظ أي إذن بعد النجاح: العدّاد يُصفَّر، والخروج من الشاشة يُلغي البوابة، والحوار
  /// إلزامي عند كل دخول. هذا هو الفارق بين «وصول سرّي» و«وصول دائم مكشوف».
  /// No grant survives success: the counter resets, leaving the screen voids the gate, and the
  /// dialog is mandatory on every entry. That is the difference between a hidden door and a
  /// permanently open one.
  Future<void> _handleDeveloperUnlock() async {
    if (!widget.allowApiUnlock || !_unlock.registerTap()) return;

    final allowed = await ApiPasswordDialog.show(context);
    if (!allowed || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ApiSettingsScreen()),
    );
  }
}
