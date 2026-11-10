import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/tailoring_reference_model.dart';

/// خط سير حالات القماش — المراحل من قاموس ORDSTATE الحقيقي
/// The fabric workflow path — the stages come from the real ORDSTATE dictionary.
///
/// لا تُكتب المراحل في الشاشة: تُقرأ من القاموس مرتّبة برقمها، فيرافق أي تعديل يقوم به
/// النظام القديم على الحالات يتغيّر الخط تلقائياً بلا تعديل كود.
/// The stages are never hard-coded: they are read from the dictionary in numeric order, so any
/// change the legacy system makes to the stages is reflected without a code change.
///
/// العرض المطبَّق: تُظهر الشاشة كل المراحل المنجزة مع **مرحلة واحدة قادمة** فقط، وتُخفي
/// البقية خلف زر «إظهار» صغير يكشفها عند النقر. وبجانب اسم كل مرحلة تُعرض بياناتها (تاريخها
/// ومنفّذها) إن وصلت من سجل حركة القماش.
/// The applied display: every completed stage plus **one upcoming** is shown, the rest hidden
/// behind a small "show" button that reveals them on tap. Beside each stage name its own data
/// (its date and executor) appears when the fabric's movement log supplies it.
class WorkflowStepper extends StatefulWidget {
  /// المراحل الفعّالة مرتّبة — تُمرَّر من المرجعيات
  /// The active stages in order — passed in from the reference data.
  final List<TailoringStage> stages;

  /// الحالة الحالية للقماش (ORDSID)؛ الصفر يعني «بلا حالة»
  /// The fabric's current stage (ORDSID); zero means "no stage".
  final int currentOrdsid;

  /// بيانات كل مرحلة بمفتاحها: نصّ قصير (تاريخ · منفّذ) يظهر بجانب الاسم
  /// Per-stage data keyed by ORSID: a short text (date · executor) shown beside the name.
  final Map<int, String>? stageMeta;

  const WorkflowStepper({
    super.key,
    required this.stages,
    required this.currentOrdsid,
    this.stageMeta,
  });

  @override
  State<WorkflowStepper> createState() => _WorkflowStepperState();
}

class _WorkflowStepperState extends State<WorkflowStepper> {
  /// هل كُشفت المراحل المخفية؟
  /// Whether the hidden stages have been revealed.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final stages = widget.stages;
    if (stages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد حالات سير معرّفة في القاموس',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    final currentIndex = _currentIndex();

    // الظاهر = كل المنجزة + الحالية + مرحلة واحدة قادمة (فهرس currentIndex+1)
    // Visible = every completed stage + the current + one upcoming (index currentIndex+1).
    final reached = currentIndex < 0 ? -1 : currentIndex;
    final collapsedCount = (reached + 2).clamp(1, stages.length);
    final showAll = _expanded || collapsedCount >= stages.length;
    final shownCount = showAll ? stages.length : collapsedCount;
    final hiddenCount = stages.length - shownCount;

    return Column(
      children: [
        for (var i = 0; i < shownCount; i++)
          _StepRow(
            stage: stages[i],
            index: i,
            // الخط الرابط يختفي فقط بعد آخر مرحلة عند كشف الكل
            // The connector lane ends only after the last stage once everything is shown.
            isLast: showAll && i == stages.length - 1,
            state: _stateFor(i, currentIndex),
            meta: widget.stageMeta?[stages[i].ordsid],
          ),
        if (hiddenCount > 0)
          _ToggleRow(
            label: 'إظهار المراحل التالية (${hiddenCount > 1 ? '$hiddenCount مراحل' : 'مرحلة واحدة'})',
            icon: Icons.expand_more_rounded,
            onTap: () => setState(() => _expanded = true),
          ),
        if (_expanded && stages.length > collapsedCount)
          _ToggleRow(
            label: 'إخفاء المراحل',
            icon: Icons.expand_less_rounded,
            onTap: () => setState(() => _expanded = false),
          ),
      ],
    );
  }

  int _currentIndex() {
    if (widget.currentOrdsid == 0) return -1;

    final exact = widget.stages.indexWhere((s) => s.ordsid == widget.currentOrdsid);
    if (exact >= 0) return exact;

    // الحالة بين مرحلتين معروفتين: تُحسب منتهية كل ما قبلها
    // A stage between two known ones: everything before it counts as completed.
    var last = -1;
    for (var i = 0; i < widget.stages.length; i++) {
      if (widget.stages[i].ordsid < widget.currentOrdsid) last = i;
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

/// صف مرحلة: المؤشر والخط، الاسم، وبجانبه بياناتها (تاريخ · منفّذ) عند توفرها
/// A stage row: marker and lane, the name, and beside it its data (date · executor) when present.
class _StepRow extends StatelessWidget {
  final TailoringStage stage;
  final int index;
  final bool isLast;
  final _StepState state;
  final String? meta;

  const _StepRow({
    required this.stage,
    required this.index,
    required this.isLast,
    required this.state,
    this.meta,
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
                    color: color.withValues(
                        alpha: state == _StepState.pending ? 0.08 : 0.15),
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
                  // بيانات المرحلة بجانب اسمها: تاريخها ومنفّذها من سجل حركة القماش
                  // The stage's data beside its name: its date and executor from the fabric log.
                  if (meta != null && meta!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        meta!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

/// زر صغير لكشف/طيّ المراحل المتبقية
/// A small button to reveal or collapse the remaining stages.
class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2, start: 34),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
