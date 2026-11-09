import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/models/cutting_model_item.dart';
import '../../data/models/cutting_piece_item.dart';
import '../../data/models/tailoring_reference_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import '../widgets/model_movements_table.dart';
import '../widgets/tailoring_section_card.dart';
import '../widgets/workflow_stepper.dart';

/// شاشة متابعة سير فاتورة تفصيل — نموذج أولي ببيانات حقيقية
/// The cutting-bill progress screen — a prototype backed by real data.
///
/// المراحل تُقرأ من قاموس `ORDSTATE` الفعلي، وحالة كل قطعة من أعلام الإنجاز في الـ VIEW،
/// وسجل الحركة من `CUTING_TRANSD`. ما هو «قيد التطوير» هو نقل الحالة بين المراحل فقط:
/// الأزرار معطّلة صراحةً ولا يُرسل أي إجراء إلى الخادم.
/// The stages come from the live `ORDSTATE` dictionary, each piece's state from the view's
/// completion flags, and the log from `CUTING_TRANSD`. Only the stage transition is still under
/// development: its buttons are plainly disabled and nothing is sent to the server.
class CuttingBillProgressScreen extends ConsumerWidget {
  /// هوية الفاتورة المركّبة (رقم، سنة)
  /// The composite bill identity (number, year).
  final CuttingBillKey billKey;

  const CuttingBillProgressScreen({super.key, required this.billKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(cuttingBillDetailProvider(billKey));
    final reference = ref.watch(tailoringReferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.timeline_rounded, color: AppColors.warning, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة سير فاتورة ${billKey.id}',
                    style:  TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'نموذج أولي — نقل الحالات غير مفعّل',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(cuttingBillDetailProvider(billKey));
              ref.invalidate(tailoringReferenceProvider);
            },
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: PermissionGate(
        code: Perm.tailoringProgress,
        hide: false,
        onDenied: const _NoProgressGrant(),
        child: detail.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 14),
                Text(
                  'جارٍ تحميل سير الفاتورة...',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          error: (error, _) => _buildError(context, ref, error),
          data: (data) => _buildBody(
            context,
            data,
            reference.value ?? TailoringReference.empty,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CuttingBillDetail detail,
    TailoringReference reference,
  ) {
    // كل قطع الفاتورة مسطّحة: سجل الحركة واحد للفاتورة كلها لا طلب لكل موديل
    // Every piece of the bill, flattened: one movement request for the whole bill rather than
    // one per model.
    final pieces = <(CuttingModelItem, CuttingPieceItem)>[
      for (final model in detail.models)
        for (final piece in model.pieces) (model, piece),
    ];
    // سجل الحركة يُطلب بأرقام طلبات الأقمشة (OHDID) لا بأرقام الموديلات
    // The movement log is requested by fabric order ids (OHDID), not model numbers.
    final ohdIds = pieces
        .map((row) => row.$2.ohdId)
        .whereType<int>()
        .where((n) => n > 0)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // _buildPrototypeBanner(),
          // const SizedBox(height: 12),
          TailoringSectionCard(
            title: 'خط سير الحالات',
            icon: Icons.route_rounded,
            accent: AppColors.warning,
            trailing: TailoringChip(
              label: detail.header.ordsName ?? 'الحالة',
              value: detail.header.ordsdid == 0
                  ? 'غير محددة'
                  : '${detail.header.ordsdid}',
              color: AppColors.warning,
            ),
            child: WorkflowStepper(
              stages: reference.activeStages,
              currentOrdsid: detail.header.ordsdid,
            ),
          ),
          const SizedBox(height: 12),
          TailoringSectionCard(
            title: 'حالة القطع',
            icon: Icons.checkroom_rounded,
            accent: AppColors.primary,
            trailing: TailoringChip(
              label: '${pieces.length} قطعة',
              color: AppColors.primary,
            ),
            child: _PieceStatusList(rows: pieces),
          ),
          const SizedBox(height: 12),
          ModelMovementsTable(
            model: null,
            billNo: billKey.billNo,
            year: billKey.year,
            ohdIds: ohdIds,
            title: 'سجل حركة أقمشة الفاتورة',
          ),
          const SizedBox(height: 12),
          _buildActionsCard(detail),
        ],
      ),
    );
  }

  /// إفصاح صريح أن نقل المراحل لم يُنفَّذ بعد
  /// A plain disclosure that the stage transition is not implemented yet.
  // Widget _buildPrototypeBanner() {
  //   return Container(
  //     padding: const EdgeInsets.all(11),
  //     decoration: BoxDecoration(
  //       color: AppColors.warning.withValues(alpha: 0.1),
  //       borderRadius: BorderRadius.circular(11),
  //       border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
  //     ),
  //     child: Row(
  //       children: [
  //         const Icon(Icons.construction_rounded, size: 18, color: AppColors.warning),
  //         const SizedBox(width: 8),
  //         // const Expanded(
  //         //   child: Text(
  //         //     'قيد التطوير — المراحل والحركات المعروضة حقيقية، أما أزرار نقل الحالة فغير مفعّلة '
  //         //     'ولا تُكتب أي بيانات في النظام',
  //         //     style: TextStyle(
  //         //       fontSize: 11.5,
  //         //       fontWeight: FontWeight.bold,
  //         //       color: AppColors.warning,
  //         //     ),
  //         //   ),
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  /// أزرار الإجراء — معطّلة بشرح بدل تعطيل صامت
  /// The action buttons — disabled with an explanation rather than a silent dead state.
  Widget _buildActionsCard(CuttingBillDetail detail) {
    return TailoringSectionCard(
      title: 'إجراءات السير',
      icon: Icons.play_circle_outline_rounded,
      accent: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.header.ordsName == null
                ? 'الحالة الحالية غير معروفة — لا توجد حالة مُسجّلة على الفاتورة'
                : 'الفاتورة الآن: ${detail.header.ordsName}',
            style:  TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in const [
                ('تسليم للقص', Icons.inventory_2_outlined),
                ('تم القص', Icons.content_cut_rounded),
                ('تسليم للخياط', Icons.local_laundry_service_outlined),
                ('تم التسليم', Icons.local_shipping_outlined),
              ])
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(action.$2, size: 15),
                  label: Text(action.$1, style: const TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    disabledForegroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.border),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'نقل الحالة يحتاج مسار كتابة على الخادم لم يُنفَّذ بعد؛ الأزرار تبقى معطّلة حتى تنفيذه.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final isNotFound = error is TailoringException && error.notFoundInView;
    final message = error is TailoringException
        ? error.displayMessage
        : 'تعذّر تحميل سير الفاتورة';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotFound ? Icons.playlist_remove_rounded : Icons.wifi_off_rounded,
              size: 54,
              color: isNotFound ? AppColors.textMuted : AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              isNotFound ? 'الفاتورة غير متاحة للمتابعة' : 'تعذّر تحميل سير الفاتورة',
              style:  TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNotFound
                  ? 'هذه الفاتورة ليست ضمن الفواتير المُسندة إلى قصّاص وخيّاط، وهي التي '
                        'يعرضها مصدر البيانات. الرقم قد يكون صحيحاً لكن الفاتورة خارج نطاق العرض.'
                  : message,
              textAlign: TextAlign.center,
              style:  TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(cuttingBillDetailProvider(billKey)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة كل قطعة من الـ VIEW — جدول على العريض وبطاقات على الضيق
/// Each piece's state from the view — a table when wide, cards when narrow.
class _PieceStatusList extends StatelessWidget {
  final List<(CuttingModelItem, CuttingPieceItem)> rows;

  const _PieceStatusList({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا توجد قطع في هذه الفاتورة',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStageSummary(),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (ctx, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : 8),
                      child: _PieceCard(
                        model: rows[i].$1,
                        piece: rows[i].$2,
                      ),
                    ),
                ],
              );
            }
            return _buildTable();
          },
        ),
      ],
    );
  }

  /// ملخّص المراحل بشرائح — يعطي صورة فورية قبل قراءة الصفوف
  /// The stage summary as chips — an instant picture before reading the rows.
  Widget _buildStageSummary() {
    final counts = <CuttingPieceStage, int>{};
    for (final row in rows) {
      counts.update(row.$2.stage, (v) => v + 1, ifAbsent: () => 1);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final stage in CuttingPieceStage.values)
          if ((counts[stage] ?? 0) > 0)
            TailoringChip(
              label: stage.label,
              value: '${counts[stage]}',
              color: _stageColor(stage),
            ),
      ],
    );
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(
        color: AppColors.border,
        width: 0.7,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FixedColumnWidth(62),
        1: FixedColumnWidth(62),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.6),
        4: FlexColumnWidth(1.4),
        5: FlexColumnWidth(1.4),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceSubtle),
          children: [
            _th('الموديل'),
            _th('القطعة'),
            _th('القماش'),
            _th('المرحلة'),
            _th('القصّاص'),
            _th('الخيّاط'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFBFC),
            ),
            children: [
              _td('${rows[i].$1.seqNo}'),
              _td('${rows[i].$2.seqNo1}'),
              _td(rows[i].$2.label),
              _td(
                rows[i].$2.stage.label,
                color: _stageColor(rows[i].$2.stage),
              ),
              _td(rows[i].$2.cutterName ?? 'غير مسند'),
              _td(
                rows[i].$2.hasTailor ? rows[i].$2.tailorName! : 'غير مسند',
                color: rows[i].$2.hasTailor ? null : AppColors.textMuted,
              ),
            ],
          ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:  TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _td(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: color ?? AppColors.textPrimary,
          fontWeight: color == null ? FontWeight.normal : FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// بطاقة قطعة واحدة على الشاشات الضيقة
/// One piece's card on narrow screens.
class _PieceCard extends StatelessWidget {
  final CuttingModelItem model;
  final CuttingPieceItem piece;

  const _PieceCard({required this.model, required this.piece});

  @override
  Widget build(BuildContext context) {
    final color = _stageColor(piece.stage);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'موديل ${model.seqNo} — قطعة ${piece.seqNo1}',
                  style:  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TailoringChip(label: piece.stage.label, color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            piece.label,
            style:  TextStyle(fontSize: 11, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 10,
            runSpacing: 3,
            children: [
              _meta(Icons.content_cut_rounded, piece.cutterName ?? 'غير مسند'),
              _meta(
                Icons.local_laundry_service_outlined,
                piece.hasTailor ? piece.tailorName! : 'غير مسند',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          text,
          style:  TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// لون المرحلة — يتدرّج من الرمادي إلى الأخضر بحسب تقدّم القطعة
/// The stage colour — from grey to green as the piece advances.
Color _stageColor(CuttingPieceStage stage) {
  return switch (stage) {
    CuttingPieceStage.waiting => AppColors.textMuted,
    CuttingPieceStage.cut => AppColors.info,
    CuttingPieceStage.tailored => AppColors.primaryLight,
    CuttingPieceStage.delivered => AppColors.success,
  };
}

/// منع صريح: الشاشة كلها ضمن صلاحية `tailoring.progress`
/// An explicit denial: the whole screen sits inside `tailoring.progress`.
class _NoProgressGrant extends StatelessWidget {
  const _NoProgressGrant();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:  [
            Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'لا تملك صلاحية متابعة سير فواتير التفصيل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'راجع مدير النظام لمنحك صلاحية «متابعة سير فاتورة التفصيل»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
