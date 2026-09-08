import 'package:flutter/material.dart';
import '../../data/models/worker_model.dart';
import 'workers_list_screen.dart';

/// شاشة قائمة الخياطين
class TailorsListScreen extends StatelessWidget {
  const TailorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkersListScreen(
      workerType: WorkerType.tailor,
      title: 'الخياطين',
      addLabel: 'إضافة خياط',
      accentColor: Color(0xFF7C2D12),
      lightColor: Color(0xFFF97316),
      icon: Icons.checkroom_rounded,
      workReportLabel: 'كشف عمل',
    );
  }
}
