import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الرئيسية المتجاوبة
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    //الواح
    return const PortalSectionScaffold(
      title: 'الرئيسية',
      subtitle: 'لوحة المعلومات والإحصائيات العامة',
      icon: Icons.dashboard_outlined,
      searchHint: 'بحث في الرئيسية...',
      emptyTitle: 'لوحة المعلومات ',
      emptyDescription: 'يمكن استعراض الجداول والإحصائيات ',
    );
  }
}
