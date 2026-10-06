import 'package:flutter/material.dart';
import '../../widgets/data_list_scaffold.dart';

/// واجهة قسم المبيعات - تعرض قائمة بيانات لذا تستخدم DataListScaffold
class SalesSection extends StatelessWidget {
  const SalesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const DataListScaffold(
      title: 'المبيعات',
      subtitle: 'فواتير المبيعات والمدفوعات',
      icon: Icons.point_of_sale_outlined,
      searchHint: 'بحث برقم الفاتورة أو اسم العميل...',
      emptyTitle: 'لا توجد فواتير بعد',
      emptyDescription: 'ستظهر هنا فواتير المبيعات والمعاملات المالية',
      emptyActionLabel: 'إنشاء فاتورة',
    );
  }
}
