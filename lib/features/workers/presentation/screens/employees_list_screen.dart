import 'package:flutter/material.dart';
import '../../data/models/worker_model.dart';
import 'workers_list_screen.dart';

/// شاشة قائمة الموظفين
class EmployeesListScreen extends StatelessWidget {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkersListScreen(
      workerType: WorkerType.employee,
      title: 'الموظفين',
      addLabel: 'إضافة موظف',
      accentColor: Color(0xFF1E3A8A),
      lightColor: Color(0xFF3B82F6),
      icon: Icons.badge_rounded,
      workReportLabel: 'كشف حضور',
    );
  }
}
