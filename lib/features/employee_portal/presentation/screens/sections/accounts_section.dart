import 'package:flutter/material.dart';
import '../../widgets/portal_section_scaffold.dart';

/// واجهة قسم الحسابات المتجاوبة
class AccountsSection extends StatelessWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const PortalSectionScaffold(
      title: 'الحسابات',
      subtitle: 'إدارة السندات وقيود اليومية',
      icon: Icons.account_balance_outlined,
      searchHint: 'بحث في الحسابات والسندات...',
      emptyTitle: 'سجلات الحسابات والقيود جاهزة للربط مع قاعدة بيانات Oracle',
      emptyDescription: 'استعراض شجرة الحسابات، كشوفات الأرصدة، وسندات القبض والصرف عبر الـ API',
    );
  }
}
