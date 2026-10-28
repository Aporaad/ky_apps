import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/tailoring_reference_model.dart';

/// خط سير حالات الفاتورة — المراحل من قاموس ORDSTATE الحقيقي
/// The invoice workflow path — the stages come from the real ORDSTATE dictionary.
///
/// لا تُكتب المراحل في الشاشة: تُقرأ من القاموس مرتّبة برقمها، فيرافق أي تعديل يقوم به
/// النظام القديم على الحالات يتغيّر الخط تلقائياً بلا تعديل كود.
/// The stages are never hard-coded: they are read from the dictionary in numeric order, so any
/// change the legacy system makes to the stages is reflected without a code change.
class WorkflowStepper extends StatelessWidget {
  /// المراحل الفعّالة مرتّبة — تُمرَّر من المرجعيات
  /// The active stages in order — passed in from the reference data.
  final List<TailoringStage> stages;

  /// الحالة الحالية للفاتورة (ORDSDID)؛ الصفر يعني «بلا حالة»
  /// The bill's current stage (ORDSDID); zero means "no stage".
  final int currentOrdsid;

  const WorkflowStepper({
    super.key,
    required this.stages,
    required this.currentOrdsid,
  });

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد حالات سير معرّفة في القاموس',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    // موقع الحالة الحالية: مطابقة تامة، وإلا موضعها النسبي بين المراحل المرتّبة
    // The current stage's position: an exact match, otherwise its relative place among
    // the ordered stages.
    final currentIndex = _currentIndex();

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _StepRow(
            stage: stages[i],
            index: i,
            isLast: i == stages.length - 1,
            state: _stateFor(i, currentIndex),
          ),
      ],
    );
  }

  int _currentIndex() {
    if (currentOrdsid == 0) return -1;

    final exact = stages.indexWhere((s) => s.ordsid == currentOrdsid);
    if (exact >= 0) return exact;

    // الحالة بين مرحلتين معروفتين: تُحسب منتهية كل ما قبلها
    // A stage between two known ones: everything before it counts as completed.
    var last = -1;
    for (var i = 0; i < stages.length; i++) {
      if (stages[i].ordsid < currentOrdsid) last = i;
    }
    return last;
  }

  _StepState _stateFor(int index, int currentIndex) {
    if (currentIndex < 0) return _StepState.pending;
    if (index < currentIndex) return _StepState.done;
    if (index == currentIndex) return _StepState.current;
    return _StepState.pending;
  }
}

enum _StepState { done, current, pending }

class _StepRow extends StatelessWidget {
  final TailoringStage stage;
  final int index;
  final bool isLast;
  final _StepState state;

  const _StepRow({
    required this.stage,
    required this.index,
    required this.isLast,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => AppColors.success,
      _StepState.current => AppColors.warning,
      _StepState.pending => AppColors.textMuted,
    };

    final icon = switch (state) {
      _StepState.done => Icons.check_rounded,
      _StepState.current => Icons.play_arrow_rounded,
      _StepState.pending => Icons.circle_outlined,
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عمود المؤشر والخط: يجعل القراءة من أعلى إلى أسفل بلا التباس
          // The marker/lane column makes the reading top-down unambiguous.
          SizedBox(
            width: 26,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: state == _StepState.pending ? 0.08 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.2),
                  ),
                  child: Icon(icon, size: 12, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: state == _StepState.done
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.ordsname ?? 'حالة ${stage.ordsid}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: state == _StepState.pending
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: state == _StepState.pending
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (state == _StepState.current)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'الحالية',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '${stage.ordsid}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (stage.nextOrdsid != null)
                    Text(
                      'التالية: ${stage.nextOrdsid}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
