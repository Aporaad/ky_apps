import 'package:flutter/material.dart';

import '../../../../tailoring/presentation/screens/tailoring_dashboard_screen.dart';

/// واجهة قسم التفصيل - تعرض لوحة تحكم التفصيل الكاملة
/// The tailoring section — renders the full tailoring dashboard.
///
/// كانت هذه الشاشة `DataListScaffold` فارغة؛ الآن تُسلّم العرض إلى لوحة القسم التي تجمع
/// بطاقات العمليات الأربع، فيبقى الدرج والرئيسية يشيران إلى وجهة واحدة.
/// This screen used to be an empty `DataListScaffold`; it now hands the view to the section
/// dashboard holding the four action cards, so the drawer and the home grid open one destination.
class TailoringSection extends StatelessWidget {
  const TailoringSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const TailoringDashboardScreen();
  }
}
