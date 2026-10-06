import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الرئيسية - لوحة المعلومات والإحصائيات
/// لا تحتوي على قائمة بيانات لذا تستخدم PortalSectionScaffold
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'الرئيسية',
      subtitle: 'لوحة المعلومات والإحصائيات العامة',
      icon: Icons.dashboard_outlined,
      emptyTitle: 'لوحة الإحصائيات',
      emptyDescription: 'سيتم هنا عرض ملخص المبيعات والأرباح والإحصائيات اليومية',
    );
  }
}
