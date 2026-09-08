import 'package:flutter/material.dart';
import '../../data/models/worker_model.dart';
import 'workers_list_screen.dart';

/// شاشة قائمة القصاصين
class CuttersListScreen extends StatelessWidget {
  const CuttersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkersListScreen(
      workerType: WorkerType.cutter,
      title: 'القصاصين',
      addLabel: 'إضافة قصاص',
      accentColor: Color(0xFF065F46),
      lightColor: Color(0xFF10B981),
      icon: Icons.content_cut_rounded,
      workReportLabel: 'كشف عمل',
    );
  }
}
