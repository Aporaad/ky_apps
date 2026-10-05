import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم التفصيل المتجاوبة
class TailoringSection extends StatelessWidget {
  const TailoringSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'التفصيل',
      subtitle: 'إدارة مقاسات وتفصيل الأزياء',
      icon: Icons.content_cut_outlined,
      searchHint: 'بحث في طلبات التفصيل والمقاسات...',
      emptyTitle: 'سجلات التفصيل ',
      emptyDescription: 'استعراض بيانات كروت التفصيل، القياسات، وحالات الإنجاز',
    );
  }
}
