import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الإعدادات المتجاوبة
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PortalSectionScaffold(
      title: 'الإعدادات',
      subtitle: 'تخصيص النظام وإعدادات الربط والشبكة',
      icon: Icons.settings_outlined,
      searchHint: 'بحث في الإعدادات...',
      content: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إعدادات الاتصال والشبكة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppColors.primary),
                ),
                title: const Text(
                  'إعدادات خادم الـ API',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'تغيير رابط الـ API الأساسي وفحص الاتصال بالخادم',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.push('/api-settings'),
              ),
              const SizedBox(height: 16),
              const Text(
                'تفضيلات المظهر واللغة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.language_rounded, color: AppColors.accent),
                ),
                title: const Text(
                  'اللغة واتجاه الواجهة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'اللغة العربية (RTL) مفعلة افتراضياً',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
