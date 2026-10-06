import 'package:flutter/material.dart';
import '../../widgets/data_list_scaffold.dart';

/// واجهة قسم المخازن - قائمة بيانات لذا تستخدم DataListScaffold
class StoresSection extends StatelessWidget {
  const StoresSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DataListScaffold(
      title: 'المخازن',
      subtitle: 'مراقبة حركة الأصناف والمخزون',
      icon: Icons.inventory_2_outlined,
      searchHint: 'بحث بكود الصنف أو الاسم...',
      emptyTitle: 'لا توجد أصناف مخزنية',
      emptyDescription: 'ستظهر هنا كميات الأصناف وأسعار التكلفة وجرد المستودعات',
      emptyActionLabel: 'إضافة صنف',
    );
  }
}
