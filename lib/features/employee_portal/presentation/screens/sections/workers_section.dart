import 'package:flutter/material.dart';
import '../../../../../features/workers/presentation/screens/workers_dashboard_screen.dart';

/// واجهة قسم "جاري العاملين" - تعرض لوحة تحكم العاملين
class WorkersSection extends StatelessWidget {
  const WorkersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkersDashboardScreen();
  }
}
