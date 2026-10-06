import 'package:flutter/material.dart';
import '../../widgets/data_list_scaffold.dart';

/// واجهة قسم التفصيل - قائمة بيانات لذا تستخدم DataListScaffold
class TailoringSection extends StatelessWidget {
  const TailoringSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DataListScaffold(
      title: 'التفصيل',
      subtitle: 'كروت التفصيل والمقاسات',
      icon: Icons.content_cut_outlined,
      searchHint: 'بحث في كروت التفصيل والقياسات...',
      emptyTitle: 'لا توجد كروت تفصيل',
      emptyDescription: 'ستظهر هنا سجلات التفصيل والقياسات وحالات الإنجاز',
      emptyActionLabel: 'إضافة كرت تفصيل',
    );
  }
}
