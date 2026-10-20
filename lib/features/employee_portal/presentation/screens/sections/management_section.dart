import 'package:flutter/material.dart';
import '../../../../admin/presentation/screens/management_dashboard_screen.dart';

/// قسم الإدارة في الدرج — يفتح لوحة الإدارة مباشرة
/// The drawer's management section: it opens the management dashboard directly.
///
/// كان هذا القسم هيكلاً فارغاً من `PortalSectionScaffold`؛ الحجة الآن أن اللوحة نفسها تعرض
/// حالتها الفارغة المفسَّرة حين لا صلاحية، بدل نص «قيد التطوير» لا يشرح شيئاً.
/// This section used to be an empty PortalSectionScaffold. The dashboard now renders its own
/// explained empty state when no permission is held, instead of a «under development» line.
class ManagementSection extends StatelessWidget {
  const ManagementSection({super.key});

  @override
  Widget build(BuildContext context) => const ManagementDashboardScreen();
}
