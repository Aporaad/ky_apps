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

/// شاشة متابعة سير فاتورة تفصيل — التتبّع على مستوى **القماش** لا الموديل ولا الفاتورة.
/// The cutting-bill progress screen — tracking is per **fabric**, not per model or bill.
///
/// رأس الشاشة جدول أقمشة الفاتورة بخمسة أعمدة فقط (رقم الطلب · الموديل · العميل/المستفيد ·
/// اسم القماش · اللون)، وكل صف قابل للتحديد. المخطط وسجل الحركة يُبنى كلُّهما على رقم طلب
/// القماش المحدد (OHDID) وحده، لأن الحركة تخصّ القماش لا الموديل ولا الفاتورة.
/// The header is the bill's fabrics table with five columns only (order id · model ·
/// customer/beneficiary · cloth name · colour), every row selectable. The workflow chart and the
/// movement log are both built on the selected fabric's order id (OHDID) alone, because the
/// movement belongs to the fabric, not the model or the bill.
class CuttingBillProgressScreen extends ConsumerStatefulWidget {
  /// هوية الفاتورة المركّبة (رقم، سنة)
  /// The composite bill identity (number, year).
  final CuttingBillKey billKey;

  const CuttingBillProgressScreen({super.key, required this.billKey});

  @override
  ConsumerState<CuttingBillProgressScreen> createState() =>
      _CuttingBillProgressScreenState();
}

class _CuttingBillProgressScreenState
    extends ConsumerState<CuttingBillProgressScreen> {
  /// القماش المحدد (OHDID) — يقود المخطط والسجل معاً
  /// The selected fabric (OHDID) — it drives both the chart and the log.
  int? _selectedOhdId;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(cuttingBillDetailProvider(widget.billKey));
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
            const Icon(Icons.timeline_rounded,
                color: AppColors.warning, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'متابعة سير فاتورة ${widget.billKey.id}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'التتبّع على مستوى القماش المحدد',
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
              ref.invalidate(cuttingBillDetailProvider(widget.billKey));
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
          error: (error, _) => _buildError(context, error),
          data: (data) => _buildBody(
            data,
            reference.value ?? TailoringReference.empty,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CuttingBillDetail detail, TailoringReference reference) {
    // أقمشة الفاتورة كلها مسطّحة: صف لكل قطعة عبر كل الموديلات
    // Every fabric of the bill, flattened: one row per piece across all models.
    final fabrics = <_ProgressFabric>[
      for (final model in detail.models)
        for (final piece in model.pieces)
          _ProgressFabric(
            model: model,
            piece: piece,
            customerName: detail.header.custName,
          ),
    ];

    // التحديد الافتراضي: أول قماش يحمل رقم طلب صالحاً (OHDID)
    // Default choice: the first fabric carrying a valid order id (OHDID).
    final firstValid = fabrics
        .map((f) => f.ohdId)
        .firstWhere((id) => id != null && id > 0, orElse: () => null);
    final selectedOhdId = _selectedOhdId ?? firstValid;
    _ProgressFabric? selected;
    for (final f in fabrics) {
      if (f.ohdId != null && f.ohdId == selectedOhdId) {
        selected = f;
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // رأس الشاشة: جدول أقمشة الفاتورة بخمسة أعمدة، قابل للتحديد
          // The header: the bill fabrics table with five columns, selectable.
          TailoringSectionCard(
            title: 'أقمشة الفاتورة',
            icon: Icons.dry_cleaning_rounded,
            accent: AppColors.accentLight,
            trailing: TailoringChip(
              label: '${fabrics.length} قماش',
              color: AppColors.accent,
            ),
            child: _FabricsFlowTable(
              fabrics: fabrics,
              selectedOhdId: selectedOhdId,
              onSelected: (ohdId) => setState(() => _selectedOhdId = ohdId),
            ),
          ),
          const SizedBox(height: 12),

          // المخطط: سير الحالات للقماش المحدد وحده
          // The chart: the workflow path of the selected fabric alone.
          TailoringSectionCard(
            title: selected == null
                ? 'مخطط سير القماش'
                : 'مخطط سير القماش — ${selected.clothLabel}',
            icon: Icons.route_rounded,
            accent: AppColors.warning,
            trailing: selected == null
                ? null
                : TailoringChip(
                    label: selected.piece.stage.label,
                    color: _stageColor(selected.piece.stage),
                  ),
            child: _buildChart(selectedOhdId, reference),
          ),
          const SizedBox(height: 12),

          // السجل: حركة القماش المحدد (OHDID) — لا الموديل ولا الفاتورة
          // The log: the selected fabric's movements (OHDID) — not the model, not the bill.
          ModelMovementsTable(
            model: null,
            billNo: widget.billKey.billNo,
            year: widget.billKey.year,
            ohdId: selectedOhdId,
            fabricName: selected?.clothLabel,
            title: selected == null
                ? 'سجل حركة القماش المحدد'
                : 'سجل حركة القماش — ${selected.clothLabel}',
          ),
          const SizedBox(height: 12),

          _buildActionsCard(detail),
        ],
      ),
    );
  }

  /// المخطط مبنيٌّ على حالة القماش المحدد: أعلى حالة reached في سجل حركته
  /// The chart reflects the selected fabric's stage: the highest stage in its movement log.
  Widget _buildChart(int? selectedOhdId, TailoringReference reference) {
    if (selectedOhdId == null || selectedOhdId <= 0) {
      return Text(
        'اختر قماشاً من الجدول أعلاه لعرض مخطط سيره',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }

    final movements = ref.watch(
      cuttingMovementsProvider(
        CuttingMovementsKey(
          billNo: widget.billKey.billNo,
          year: widget.billKey.year,
          ohdIds: [selectedOhdId],
        ),
      ),
    );

    // الحالة الحالية للقماش = أكبر ORDSID بين حركاته (المراحل رقمية متصاعدة)،
    // وبيانات كل مرحلة = تاريخها ومنفّذها من سجل حركتها.
    // The fabric's current stage = the greatest ORDSID among its movements (stages ascend), and
    // each stage's data = its date and executor from its movement.
    int currentOrdsid = 0;
    final stageMeta = <int, String>{};
    movements.maybeWhen(
      data: (rows) {
        for (final r in rows) {
          if (r.ordsid > currentOrdsid) currentOrdsid = r.ordsid;
          final info = <String>[
            if (r.dateLabel != '—') r.dateLabel,
            if (r.executorLabel != '—') r.executorLabel,
          ].join(' · ');
          if (info.isNotEmpty) stageMeta[r.ordsid] = info;
        }
      },
      orElse: () {},
    );

    return WorkflowStepper(
      stages: reference.activeStages,
      currentOrdsid: currentOrdsid,
      stageMeta: stageMeta,
    );
  }

  /// أزرار الإجراء — معطّلة بشرح: نقل الحالة يحتاج مسار كتابة على الخادم لم يُنفَّذ بعد
  /// Action buttons — disabled with an explanation: the transition needs a server write path.
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
                ? 'الحالة الحالية للفاتورة غير معروفة'
                : 'الفاتورة الآن: ${detail.header.ordsName}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildError(BuildContext context, Object error) {
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
              style: TextStyle(
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
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(cuttingBillDetailProvider(widget.billKey)),
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

/// قماش واحد في شاشة المتابعة — يجمع بيانات الصف من الموديل والقطعة والترويسة
/// One fabric in the progress screen — it joins the row data from the model, piece and header.
class _ProgressFabric {
  final CuttingModelItem model;
  final CuttingPieceItem piece;
  final String? customerName;

  const _ProgressFabric({
    required this.model,
    required this.piece,
    required this.customerName,
  });

  int? get ohdId => piece.ohdId;

  /// رقم الطلب — OHDID، وبغيابه رقم القطعة
  /// The order id — OHDID, falling back to the piece number when absent.
  String get orderLabel => piece.ohdId?.toString() ?? '${piece.seqNo1}';

  /// الموديل — نوع الموديل أو رقمه
  /// The model — its type name, or its number.
  String get modelLabel => model.displayName;

  /// العميل أو المستفيد: المستفيد إن وُجد، وإلا اسم العميل الأصلي
  /// Customer or beneficiary: the beneficiary when present, else the original customer name.
  String get personLabel {
    final beneficiary = model.beneficiary?.trim();
    if (beneficiary != null && beneficiary.isNotEmpty) return beneficiary;
    final customer = customerName?.trim();
    if (customer != null && customer.isNotEmpty) return customer;
    return '—';
  }

  /// اسم القماش / the cloth name
  String get clothLabel =>
      (piece.clothName?.trim().isNotEmpty ?? false) ? piece.clothName!.trim() : '—';

  /// اللون: النص ثم رقم اللون كما تخزّنه القاعدة
  /// The colour: its text, else the stored colour number.
  String get colorLabel {
    final text = piece.colorText?.trim();
    if (text != null && text.isNotEmpty) return text;
    return piece.colorNo?.toString() ?? '—';
  }
}

/// جدول أقمشة الفاتورة: خمسة أعمدة فقط، وكل صف قابل للتحديد ليقود المخطط والسجل
/// The bill fabrics table: five columns only, and every row is selectable to drive the chart/log.
class _FabricsFlowTable extends StatelessWidget {
  final List<_ProgressFabric> fabrics;
  final int? selectedOhdId;
  final ValueChanged<int?> onSelected;

  const _FabricsFlowTable({
    required this.fabrics,
    required this.selectedOhdId,
    required this.onSelected,
  });

  // الأعمدة الخمسة المطلوبة فقط — الأوزان تُعطي رقم الطلب والموديل والشخص حيّزاً كافياً
  // The five requested columns only — weights give the order id, model and person enough room.
  static const List<String> _headings = [
    'رقم الطلب',
    'الموديل',
    'العميل/المستفيد',
    'اسم القماش',
    'اللون',
  ];
  static const List<double> _weights = [1.7, 1.5, 2.1, 1.9, 1.1];

  @override
  Widget build(BuildContext context) {
    if (fabrics.isEmpty) {
      return Text(
        'لا توجد أقمشة في هذه الفاتورة',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: AppColors.surfaceSubtle,
            child: _row(_headings, header: true),
          ),
          for (var i = 0; i < fabrics.length; i++) ...[
            Container(
              height: 0.7,
              color: AppColors.border.withValues(alpha: 0.9),
            ),
            _FabricRow(
              fabric: fabrics[i],
              selected: fabrics[i].ohdId != null &&
                  fabrics[i].ohdId == selectedOhdId,
              onTap: () => onSelected(fabrics[i].ohdId),
              cells: [
                fabrics[i].orderLabel,
                fabrics[i].modelLabel,
                fabrics[i].personLabel,
                fabrics[i].clothLabel,
                fabrics[i].colorLabel,
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// صف بأعمدة مرنة — كل قيمة في سطر واحد داخل تصغير تلقائي فلا التفاف ولا قصّ
  /// A flex-column row — every value on one line inside automatic scaling, so nothing wraps or cuts.
  Widget _row(List<String> cells, {bool header = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: (_weights[i] * 100).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  cells[i],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: header
                      ? TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        )
                      : TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// صف قماش قابل للضغط مع تمييز التحديد
/// A tappable fabric row with a selection highlight.
class _FabricRow extends StatelessWidget {
  final _ProgressFabric fabric;
  final bool selected;
  final VoidCallback onTap;
  final List<String> cells;

  const _FabricRow({
    required this.fabric,
    required this.selected,
    required this.onTap,
    required this.cells,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.08)
          : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  // إطار يوضّح القماش المحدد دون الاعتماد على اللون وحده
                  // A border marks the chosen fabric without relying on colour alone.
                  border: Border.all(color: AppColors.primary, width: 1.4),
                  color: AppColors.primary.withValues(alpha: 0.06),
                )
              : null,
          child: _rowContent(),
        ),
      ),
    );
  }

  Widget _rowContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: (_FabricsFlowTable._weights[i] * 100).round(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  cells[i],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// لون المرحلة — يتدرّج من الرمادي إلى الأخضر بحسب تقدّم القماش
/// The stage colour — grey to green as the fabric advances.
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
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'لا تملك صلاحية متابعة سير فواتير التفصيل',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
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
