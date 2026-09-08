import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم المخازن المتجاوبة
class StoresSection extends StatelessWidget {
  const StoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'المخازن',
      subtitle: 'مراقبة حركة الأصناف والمخزون',
      icon: Icons.inventory_2_outlined,
      searchHint: 'بحث بكود الصنف أو الاسم...',
      emptyTitle: 'أرصدة المخزون جاهزة للربط مع قاعدة بيانات Oracle',
      emptyDescription: 'استعراض كميات الأصناف، أسعار التكلفة، وجرد المستودعات عبر الـ API',
    );
  }
}
