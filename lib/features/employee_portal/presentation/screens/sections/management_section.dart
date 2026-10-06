import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الإدارة - ليست قائمة بيانات لذا تستخدم PortalSectionScaffold
class ManagementSection extends StatelessWidget {
  const ManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'الإدارة',
      subtitle: 'صلاحيات المستخدمين والتقارير الرقابية',
      icon: Icons.admin_panel_settings_outlined,
      emptyTitle: 'لوحة الإدارة والرقابة',
      emptyDescription: 'ستتضمن هنا إدارة صلاحيات المستخدمين والتقارير الإدارية',
    );
  }
}
