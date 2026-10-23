import 'package:flutter/material.dart';

import '../../../../services/presentation/screens/services_dashboard_screen.dart';

/// واجهة قسم «الخدمات والمزودين» — محوّل رفيع إلى لوحة القسم الحقيقية
/// The «الخدمات والمزودين» section shell — a thin adapter to the real dashboard screen.
///
/// على عكس أقسام «جارية التطوير» التي تعرض حالة فارغة، هذا القسم حقيقي: يسلّم مباشرةً إلى
/// `ServicesDashboardScreen` التي تدير بلاطاتها الخمس خلف بواباتها الخاصة.
/// Unlike the «under development» sections that render an empty state, this section is real: it hands
/// off straight to `ServicesDashboardScreen`, whose five tiles are each behind their own gate.
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServicesDashboardScreen();
  }
}
