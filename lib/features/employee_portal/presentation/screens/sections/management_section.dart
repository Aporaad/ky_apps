import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الإدارة المتجاوبة
class ManagementSection extends StatelessWidget {
  const ManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'الإدارة',
      subtitle: 'صلاحيات المستخدمين والتقارير الرقابية',
      icon: Icons.admin_panel_settings_outlined,
      searchHint: 'بحث في المستخدمين أو السجلات...',
      emptyTitle: 'شاشة الإدارة والرقابة جاهزة للربط مع قاعدة بيانات Oracle',
      emptyDescription: 'استعراض صلاحيات الفروع والمستخدمين وتقارير الأداء المالي عبر الـ API',
    );
  }
}
