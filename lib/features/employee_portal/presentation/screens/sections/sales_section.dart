import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم المبيعات المتجاوبة
class SalesSection extends StatelessWidget {
  const SalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'المبيعات',
      subtitle: 'إدارة الفواتير والطلبات اليومية',
      icon: Icons.point_of_sale_outlined,
      searchHint: 'بحث في فواتير المبيعات...',
      emptyTitle: 'سجلات المبيعات ',
      emptyDescription: 'يمكن استعراض فواتير العملاء وسندات القبض المباشرة ',
    );
  }
}
