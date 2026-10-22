import 'package:flutter/material.dart';

import '../../admin/data/models/app_user_model.dart';
import '../../admin/presentation/screens/user_activity_screen.dart';
import '../../admin/presentation/widgets/user_picker_screen.dart';
import '../../customers/data/models/customer_model.dart';
import '../../customers/presentation/screens/customer_statement_screen.dart';
import '../../customers/presentation/screens/edit_customer_screen.dart';
import '../../customers/presentation/widgets/customer_picker_screen.dart';

/// التدفّقات التي تحتاج معطى قبل الشاشة: منتقي ثم وجهة
/// Flows that need a datum before the screen: a picker, then the destination.
///
/// دوال عليا لا كلاشرات، لأن الكتالوج `const`: الكلاشر ليس تعبيرًا ثابتًا، ومرجع الدالة العليا هو.
/// Top-level functions rather than closures, because the catalog is `const`: a closure is not a
/// constant expression, while a reference to a top-level function is.
///
/// نسخة مطابقة لما تفعله بطاقات لوحة العملاء (`customers_dashboard_screen.dart`) ولوحة الإدارة
/// (`management_dashboard_screen.dart`) — لا منطق جديد، ولا مسار موازٍ.
/// A faithful copy of what the customers and admin dashboards already do — no new logic and no
/// parallel route.

/// كشف حساب عميل: اختيار عميل ثم كشفه
/// Customer statement: pick a customer, then open the statement.
Future<void> openCustomerStatement(BuildContext context) async {
  final picked = await Navigator.of(context).push<CustomerModel>(
    MaterialPageRoute(
      builder:
          (_) => const CustomerPickerScreen(
            title: 'اختر العميل لكشف الحساب',
            subtitle: 'ابحث بالاسم أو الرقم لعرض كشف حسابه',
            icon: Icons.receipt_long_rounded,
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => CustomerStatementScreen(
            custNo: picked.custNo,
            custName: picked.custName,
            accNo: picked.accNo,
          ),
    ),
  );
}

/// تعديل عميل: اختيار عميل ثم نموذج التعديل
/// Customer edit: pick a customer, then the edit form.
Future<void> openCustomerEdit(BuildContext context) async {
  final picked = await Navigator.of(context).push<CustomerModel>(
    MaterialPageRoute(
      builder:
          (_) => const CustomerPickerScreen(
            title: 'اختر العميل للتعديل',
            subtitle: 'ابحث عن العميل الذي تريد تعديل بياناته',
            icon: Icons.edit_note_rounded,
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: picked)),
  );
}

/// سجل نشاط مستخدم: الاختيار أولًا لأن الخادم لا يقدّم سجلًا عامًا
/// User activity: the pick comes first because the server exposes no general trail.
Future<void> openUserActivity(BuildContext context) async {
  final picked = await Navigator.of(context).push<AppUserModel>(
    MaterialPageRoute(
      builder:
          (_) => const UserPickerScreen(
            title: 'سجل النشاط',
            subtitle: 'اختر مستخدمًا لعرض سجل عملياته',
          ),
    ),
  );
  if (picked == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => UserActivityScreen(
            userId: picked.userId,
            userName: picked.displayName,
          ),
    ),
  );
}
