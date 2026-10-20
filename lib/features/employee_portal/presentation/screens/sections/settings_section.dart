import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/constants/permission_codes.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/permission_gate.dart';
import '../../../../app_config/presentation/screens/app_config_screen.dart';

/// واجهة قسم الإعدادات - تصميم مستقل ومقسم إلى أقسام واضحة
/// لا تستخدم PortalSectionScaffold لأنها ليست قائمة بيانات
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isNarrow = size.width < 600;
    final hPad = isNarrow ? 14.0 : 24.0;
    final vPad = isNarrow ? 12.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── رأس الصفحة ───────────────────────────────────
            _SettingsPageHeader(textScaler: textScaler, isNarrow: isNarrow),
            SizedBox(height: isNarrow ? 16 : 22),

            // ─── على الشاشات الواسعة: عمودان جانباً لجنب ─────
            if (!isNarrow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العمود الأيسر
                  Expanded(
                    child: Column(
                      children: [
                        // 1. إعدادات الـ API
                        _ApiSettingsCard(textScaler: textScaler, isNarrow: isNarrow),
                        const SizedBox(height: 16),
                        // 1ب. تهيئة التطبيق (الشركة/المظهر) — خلف app_config.update
                        _AppConfigCard(textScaler: textScaler, isNarrow: isNarrow),
                        const SizedBox(height: 16),
                        // 2. إعدادات الأمان والبصمة
                        _SecuritySettingsCard(
                          textScaler: textScaler,
                          isNarrow: isNarrow,
                          context: context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // العمود الأيمن
                  Expanded(
                    child: Column(
                      children: [
                        // 3. الإعدادات العامة
                        _GeneralSettingsCard(textScaler: textScaler, isNarrow: isNarrow),
                      ],
                    ),
                  ),
                ],
              )
            else
              // ─── على الشاشات الضيقة: عمود واحد ─────────────
              Column(
                children: [
                  _ApiSettingsCard(textScaler: textScaler, isNarrow: isNarrow),
                  const SizedBox(height: 14),
                  _AppConfigCard(textScaler: textScaler, isNarrow: isNarrow),
                  const SizedBox(height: 14),
                  _SecuritySettingsCard(
                    textScaler: textScaler,
                    isNarrow: isNarrow,
                    context: context,
                  ),
                  const SizedBox(height: 14),
                  _GeneralSettingsCard(textScaler: textScaler, isNarrow: isNarrow),
                ],
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// رأس الصفحة
// ─────────────────────────────────────────────
class _SettingsPageHeader extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _SettingsPageHeader({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(isNarrow ? 18.0 : 21.0).clamp(14.0, 26.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.5 : 13.0).clamp(10.0, 16.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_rounded,
            color: AppColors.primary,
            size: isNarrow ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: TextStyle(
                  fontSize: scaledTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'تخصيص النظام والاتصال والأمان والمظهر',
                style: TextStyle(
                  fontSize: scaledSub,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// القسم الأول: إعدادات الـ API (الاتصال بالخادم)
// ─────────────────────────────────────────────
class _ApiSettingsCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _ApiSettingsCard({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledSection = textScaler.scale(isNarrow ? 13.0 : 14.0).clamp(11.0, 18.0);

    // لا تظهر بطاقة اتصال الـ API في البوابة إلا لحامل `app_config.api_manage`
    // The API-connection card renders in the portal only for `app_config.api_manage` holders.
    return PermissionGate(
      code: Perm.appConfigApiManage,
      child: _SettingsGroup(
        icon: Icons.dns_rounded,
        iconColor: AppColors.primary,
        title: 'إعدادات الاتصال بالخادم',
        titleFontSize: scaledSection,
        borderColor: AppColors.primary.withValues(alpha: 0.2),
        headerColor: AppColors.primary.withValues(alpha: 0.05),
        children: [
          _SettingsTile(
            icon: Icons.api_rounded,
            iconColor: AppColors.primary,
            title: 'رابط خادم الـ API',
            subtitle: 'تغيير وفحص عنوان الخادم الأساسي',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: () => context.push('/api-settings'),
            textScaler: textScaler,
            isNarrow: isNarrow,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// القسم 1ب: تهيئة التطبيق (هوية الشركة والمظهر) — خلف app_config.update
// App configuration (company identity and theming) — behind app_config.update
// ─────────────────────────────────────────────
class _AppConfigCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _AppConfigCard({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledSection = textScaler.scale(isNarrow ? 13.0 : 14.0).clamp(11.0, 18.0);

    return PermissionGate(
      code: Perm.appConfigUpdate,
      child: _SettingsGroup(
        icon: Icons.palette_rounded,
        iconColor: AppColors.accent,
        title: 'تهيئة التطبيق',
        titleFontSize: scaledSection,
        borderColor: AppColors.accent.withValues(alpha: 0.2),
        headerColor: AppColors.accent.withValues(alpha: 0.05),
        children: [
          _SettingsTile(
            icon: Icons.business_center_rounded,
            iconColor: AppColors.accent,
            title: 'معلومات الشركة والمظهر',
            subtitle: 'الاسم والعنوان والشعار والألوان والخط',
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            // دفع أمرِي كما هو العرف في بقية الميزات (لا مسارات جديدة في GoRouter)
            // Pushed imperatively like every other feature (no new GoRouter routes).
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AppConfigScreen(),
              ),
            ),
            textScaler: textScaler,
            isNarrow: isNarrow,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// القسم الثاني: إعدادات الأمان (البصمة)
// ─────────────────────────────────────────────
class _SecuritySettingsCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;
  final BuildContext context;

  const _SecuritySettingsCard({
    required this.textScaler,
    required this.isNarrow,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    final scaledSection = textScaler.scale(isNarrow ? 13.0 : 14.0).clamp(11.0, 18.0);

    return _SettingsGroup(
      icon: Icons.security_rounded,
      iconColor: const Color(0xFF6D28D9),
      title: 'الأمان والمصادقة',
      titleFontSize: scaledSection,
      borderColor: const Color(0xFF6D28D9).withValues(alpha: 0.2),
      headerColor: const Color(0xFF6D28D9).withValues(alpha: 0.05),
      children: [
        _SettingsTile(
          icon: Icons.fingerprint_rounded,
          iconColor: const Color(0xFF6D28D9),
          title: 'بصمة الإصبع / Face ID',
          subtitle: 'تفعيل أو إيقاف تسجيل الدخول بالمقاييس الحيوية',
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () => context.push('/security-settings'),
          textScaler: textScaler,
          isNarrow: isNarrow,
        ),
        const _SettingsDivider(),
        _SettingsTile(
          icon: Icons.lock_reset_rounded,
          iconColor: AppColors.warning,
          title: 'تغيير كلمة المرور',
          subtitle: 'تحديث كلمة مرور حسابك',
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () => context.push('/security-settings'),
          textScaler: textScaler,
          isNarrow: isNarrow,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// القسم الثالث: الإعدادات العامة (اللغة، الثيم، الخط)
// ─────────────────────────────────────────────
class _GeneralSettingsCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _GeneralSettingsCard({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledSection = textScaler.scale(isNarrow ? 13.0 : 14.0).clamp(11.0, 18.0);

    return _SettingsGroup(
      icon: Icons.tune_rounded,
      iconColor: AppColors.accent,
      title: 'الإعدادات العامة والمظهر',
      titleFontSize: scaledSection,
      borderColor: AppColors.accent.withValues(alpha: 0.2),
      headerColor: AppColors.accent.withValues(alpha: 0.05),
      children: [
        // اللغة
        _SettingsTile(
          icon: Icons.language_rounded,
          iconColor: AppColors.accent,
          title: 'اللغة واتجاه الواجهة',
          subtitle: 'اللغة العربية (RTL) - مفعلة افتراضياً',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'عربي',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: null,
          textScaler: textScaler,
          isNarrow: isNarrow,
        ),
        const _SettingsDivider(),

        // الثيم / الوضع الليلي
        _SettingsTile(
          icon: Icons.dark_mode_outlined,
          iconColor: const Color(0xFF0EA5E9),
          title: 'الوضع الليلي',
          subtitle: 'التبديل بين المظهر الفاتح والداكن',
          trailing: Switch.adaptive(
            value: false,
            activeColor: AppColors.primary,
            onChanged: (v) {},
          ),
          onTap: null,
          textScaler: textScaler,
          isNarrow: isNarrow,
        ),
        const _SettingsDivider(),

        // حجم الخط
        _FontSizeTile(textScaler: textScaler, isNarrow: isNarrow),

        const _SettingsDivider(),

        // معلومات التطبيق
        _SettingsTile(
          icon: Icons.info_outline_rounded,
          iconColor: AppColors.textMuted,
          title: 'معلومات التطبيق',
          subtitle: 'الإصدار الحالي والرخصة',
          trailing: const Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {},
          textScaler: textScaler,
          isNarrow: isNarrow,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// مكونات مشتركة للإعدادات
// ─────────────────────────────────────────────

/// مجموعة إعدادات بعنوان وبطاقة
class _SettingsGroup extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double titleFontSize;
  final Color borderColor;
  final Color headerColor;
  final List<Widget> children;

  const _SettingsGroup({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleFontSize,
    required this.borderColor,
    required this.headerColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // رأس المجموعة
            Container(
              color: headerColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // محتوى المجموعة
            ...children,
          ],
        ),
      ),
    );
  }
}

/// عنصر إعداد واحد (Tile)
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextScaler textScaler;
  final bool isNarrow;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textScaler,
    required this.isNarrow,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(isNarrow ? 13.0 : 13.5).clamp(11.0, 17.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.0 : 11.5).clamp(9.0, 14.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: scaledTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: scaledSub,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// فاصل بين عناصر الإعدادات
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 14,
      endIndent: 14,
    );
  }
}

/// عنصر تحكم خاص بحجم الخط
class _FontSizeTile extends StatefulWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _FontSizeTile({required this.textScaler, required this.isNarrow});

  @override
  State<_FontSizeTile> createState() => _FontSizeTileState();
}

class _FontSizeTileState extends State<_FontSizeTile> {
  double _fontSize = 1.0; // 1.0 = افتراضي

  @override
  Widget build(BuildContext context) {
    final scaledTitle = widget.textScaler.scale(widget.isNarrow ? 13.0 : 13.5).clamp(11.0, 17.0);
    final scaledSub = widget.textScaler.scale(widget.isNarrow ? 11.0 : 11.5).clamp(9.0, 14.0);

    final labels = ['صغير', 'افتراضي', 'كبير'];
    final vals = [0.85, 1.0, 1.15];
    final idx = vals.indexWhere((v) => (v - _fontSize).abs() < 0.05);
    final label = idx >= 0 ? labels[idx] : 'مخصص';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.text_fields_rounded,
                    color: AppColors.accent, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حجم الخط',
                      style: TextStyle(
                        fontSize: scaledTitle,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'الحجم الحالي: $label',
                      style: TextStyle(
                        fontSize: scaledSub,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.accent,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              inactiveTrackColor: AppColors.border,
            ),
            child: Slider(
              value: _fontSize,
              min: 0.85,
              max: 1.15,
              divisions: 2,
              onChanged: (v) => setState(() => _fontSize = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
