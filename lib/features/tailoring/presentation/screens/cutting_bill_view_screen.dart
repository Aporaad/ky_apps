import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/cutting_bill_detail_model.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../../data/repositories/tailoring_repository.dart';
import '../providers/tailoring_providers.dart';
import '../utils/cutting_bill_pdf_builder.dart';
import '../widgets/bill_customer_card.dart';
import '../widgets/bill_header_card.dart';
import '../widgets/bill_payment_card.dart';
import '../widgets/model_fabrics_table.dart';
import '../widgets/model_measurements_grid.dart';
import '../widgets/model_movements_table.dart';
import '../widgets/model_selector_strip.dart';
import '../widgets/model_specs_panel.dart';
import '../widgets/tailoring_section_card.dart';
import 'cutting_bill_progress_screen.dart';

/// شاشة استعراض فاتورة التفصيل — الهدف الأساسي من القسم
/// The cutting-bill view screen — the section's primary target.
///
/// الأقسام الثمانية بالترتيب المطلوب: بيانات الفاتورة والطلب · بيانات العميل · تفاصيل الدفع
/// · الموديلات والمستفيدون · المقاسات · المواصفات · الأقمشة · سجل الحركة؛ واختيار الموديل
/// يقود الأقسام من الرابع إلى الثامن.
/// The eight sections in the required order: invoice/order data, customer, payment, models,
/// measurements, specs, fabrics, movement log; the model choice drives sections four to eight.
///
/// المحتوى كله داخل `ReportZoomView` (تكبير بالإصبع وبالأزرار مع نسبة ظاهرة) كما في كل
/// شاشات التقارير بالتطبيق.
/// Everything sits inside `ReportZoomView` (pinch and button zoom with a live percentage),
/// exactly like every other report screen in the app.
class CuttingBillViewScreen extends ConsumerStatefulWidget {
  /// هوية الفاتورة المركّبة (رقم، سنة) — لا الرقم وحده
  /// The composite bill identity (number, year) — never the number alone.
  final CuttingBillKey billKey;

  const CuttingBillViewScreen({super.key, required this.billKey});

  @override
  ConsumerState<CuttingBillViewScreen> createState() =>
      _CuttingBillViewScreenState();
}

class _CuttingBillViewScreenState extends ConsumerState<CuttingBillViewScreen> {
  /// الموديل المختار — صفر يعني الأول
  /// The selected model — zero means the first.
  int _selectedModel = 0;

  /// القماش المختار (OHDID) — سجل الحركة يخصّ القماش لا الموديل
  /// The selected fabric (OHDID) — the movement log belongs to the fabric, not the model.
  int? _selectedFabricOhd;

  /// منع الضغط المزدوج على أزرار الطباعة أثناء بناء الملف
  /// Guards against a double press on the print buttons while the file is built.
  bool _busy = false;

  ReportLetterheadInfo _letterhead() => ReportLetterheadInfo.fromConfig(
    ref.read(appConfigNotifierProvider).config,
  );

  String? _printedBy() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return null;
    return user.nameAr ?? user.nameEn ?? user.username;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cuttingBillDetailProvider(widget.billKey));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(async),
      body: async.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'جارٍ تحميل فاتورة التفصيل...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        error: (error, _) => _buildError(error),
        data: _buildBody,
      ),
    );
  }

  AppBar _buildAppBar(AsyncValue<CuttingBillDetail> async) {
    final detail = async.value;

    return AppBar(
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
          const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706), size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail == null
                      ? 'فاتورة تفصيل'
                      : 'فاتورة تفصيل ${detail.header.referenceLabel}',
                  style:  TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail == null
                      ? widget.billKey.id
                      : tailoringHeaderSubtitle(detail),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // الفلترة/المعلومات: فتح شاشة المتابعة لنفس الفاتورة
        // Filter/info: open the same bill's progress screen.
        PermissionGate(
          code: Perm.tailoringProgress,
          child: IconButton(
            onPressed: detail == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CuttingBillProgressScreen(billKey: widget.billKey),
                    ),
                  ),
            icon: const Icon(Icons.timeline_rounded, size: 21),
            tooltip: 'متابعة سير الفاتورة',
          ),
        ),
        PermissionGate(
          code: Perm.tailoringPrint,
          child: IconButton(
            onPressed: detail == null || _busy ? null : () => _print(detail),
            icon: const Icon(Icons.print_rounded, size: 21),
            tooltip: 'طباعة',
          ),
        ),
        PermissionGate(
          code: Perm.tailoringExport,
          child: IconButton(
            onPressed: detail == null || _busy ? null : () => _export(detail),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 21),
            tooltip: 'تصدير PDF',
          ),
        ),
        IconButton(
          onPressed: () =>
              ref.invalidate(cuttingBillDetailProvider(widget.billKey)),
          icon: const Icon(Icons.refresh_rounded, size: 21),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
    final isNotFound = error is TailoringException && error.notFoundInView;
    final message = error is TailoringException
        ? error.displayMessage
        : 'تعذّر تحميل فاتورة التفصيل';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNotFound
                  ? Icons.playlist_remove_rounded
                  : Icons.wifi_off_rounded,
              size: 54,
              color: isNotFound ? AppColors.textMuted : AppColors.error,
            ),
            const SizedBox(height: 14),
            Text(
              isNotFound ? 'الفاتورة غير متاحة للعرض' : 'تعذّر تحميل الفاتورة',
              style:  TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNotFound
                  ? 'هذه الفاتورة ليست ضمن الفواتير المُسندة إلى قصّاص وخيّاط، وهي الفواتير '
                        'التي يعرضها مصدر البيانات. الرقم قد يكون صحيحاً لكن الفاتورة خارج نطاق العرض.'
                  : message,
              textAlign: TextAlign.center,
              style:  TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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

  Widget _buildBody(CuttingBillDetail detail) {
    // اختيار الموديل محروس: الفاتورة قد تُحدَّث ويقلّ عدد الموديلات
    // The selection is guarded: a refresh can leave fewer models than the index.
    final modelIndex = detail.models.isEmpty
        ? 0
        : _selectedModel.clamp(0, detail.models.length - 1);
    final model = detail.models.isEmpty ? null : detail.models[modelIndex];

    // القماش المختار: يبقى ما دام ضمن الموديل، وإلا يُعرض أول قماش بدل سجل فارغ
    // The selected fabric: kept while it belongs to the model, otherwise the first fabric is
    // shown instead of an empty log.
    final selectedFabric = model == null || model.pieces.isEmpty
        ? null
        : model.pieces.firstWhere(
            (p) => p.ohdId != null && p.ohdId == _selectedFabricOhd,
            orElse: () => model.pieces.first,
          );

    // ── الأقسام كما تُعرض، ثم تُرتَّب حسب العرض المتاح ───────────────────────
    // The sections as they are rendered, then laid out according to the width on offer.

    // 1 · بيانات الفاتورة والطلب
    final headerCard = BillHeaderCard(header: detail.header);
    // 2 · بيانات العميل
    final customerCard = BillCustomerCard(header: detail.header);
    // 3 · تفاصيل الدفع — الصلاحية تُغلّف البطاقة، والخادم يحجبها أصلاً
    // The gate wraps the card and the server blocks it anyway — both layers.
    final paymentCard = PermissionGate(
      code: Perm.tailoringPaymentsView,
      child: BillPaymentCard(payment: detail.payment),
    );
    // 4 · الموديلات والمستفيدون
    final modelsCard = TailoringSectionCard(
      title: 'الموديلات والمستفيدون',
      icon: Icons.checkroom_rounded,
      trailing: TailoringChip(
        label: '${detail.models.length} موديل · ${detail.piecesCount} قطعة',
        color: AppColors.primary,
      ),
      child: ModelSelectorStrip(
        models: detail.models,
        selectedIndex: modelIndex,
        // اسم العميل الأصلي بديلاً عن المستفيد الفارغ (الموديل للعميل نفسه)
        // The original customer name replaces an empty beneficiary (the model is his own).
        customerName: detail.header.custName,
        // تغيير الموديل يعيد اختيار القماش إلى أوله
        // Switching the model resets the fabric choice to its first fabric.
        onSelected: (i) => setState(() {
          _selectedModel = i;
          _selectedFabricOhd = null;
        }),
      ),
    );

    // 7 · الأقمشة — قائمة قابلة للتحديد (الاختيار يقود سجل الحركة)
    // The fabrics — a selectable list (the choice drives the movement log).
    final fabricsCard = model == null
        ? null
        : ModelFabricsTable(
            model: model,
            selectedOhdId: selectedFabric?.ohdId,
            onSelected: (id) => setState(() => _selectedFabricOhd = id),
          );

    // 8 · سجل حركة القماش المختار فقط
    // The selected fabric's movement log only.
    final movementsCard = model == null
        ? null
        : ModelMovementsTable(
            model: model,
            billNo: detail.header.billNo,
            year: detail.header.year,
            ohdId: selectedFabric?.ohdId,
            fabricName: selectedFabric == null
                ? null
                : '${selectedFabric.clothName ?? 'قماش'} · ${selectedFabric.ohdId ?? '—'}',
          );

    return ReportZoomView(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // العتبة 980: على الحاسب تُصفّ الأقسام في صفوف أفقية، وعلى الجوال عمود واحد
            // The 980 threshold: rows on desktop, a single column on a phone.
            final wide = constraints.maxWidth >= 980;
            const gap = SizedBox(height: 6);

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerCard,
                  gap,
                  customerCard,
                  gap,
                  paymentCard,
                  gap,
                  modelsCard,
                  if (model != null) ...[
                    gap,
                    ModelMeasurementsGrid(
                      model: model,
                      labels: detail.measureLabels,
                    ),
                    gap,
                    ModelSpecsPanel(model: model),
                    gap,
                    fabricsCard!,
                    gap,
                    movementsCard!,
                  ],
                ],
              );
            }

            // العريض: الأقسام 1–4 بعرض الصف كاملاً فيصطفّ كل قسم في سطر واحد منضبط، ثم
            // المقاسات والمواصفات جنباً إلى جنب، ثم الأقمشة والحركة (كلتاهما جدول بصفوف).
            // On wide screens sections 1–4 take the full row so each fits one tidy line, then
            // measurements and specs share a row, then the fabrics and movement tables.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerCard,
                gap,
                customerCard,
                gap,
                paymentCard,
                gap,
                modelsCard,
                if (model != null) ...[
                  gap,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: ModelMeasurementsGrid(
                          model: model,
                          labels: detail.measureLabels,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(flex: 7, child: ModelSpecsPanel(model: model)),
                    ],
                  ),
                  gap,
                  fabricsCard!,
                  gap,
                  movementsCard!,
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// بناء الملف نفسه للطباعة والتصدير
  /// Build the same file for both printing and export.
  Future<Uint8List> _buildPdf(CuttingBillDetail detail) {
    return buildCuttingBillPdf(
      letterhead: _letterhead(),
      detail: detail,
      printedBy: _printedBy(),
    );
  }

  Future<void> _print(CuttingBillDetail detail) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf(detail);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      _recordActivity('print');
    } catch (_) {
      _showMessage('تعذّرت الطباعة — تحقّق من إعدادات الطابعة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(CuttingBillDetail detail) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf(detail);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'cutting-bill-${detail.header.billNo}-${detail.header.year}.pdf',
      );
      _recordActivity('export');
    } catch (_) {
      _showMessage('تعذّر تصدير الملف');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// تسجيل حدث الطباعة/التصدير — بلا انتظار ولا يُفشل الإجراء
  /// Record the print/export event — not awaited, never failing the action.
  void _recordActivity(String action) {
    ref
        .read(tailoringRepositoryProvider)
        .recordActivity(
          widget.billKey.billNo,
          widget.billKey.year,
          action: action,
        );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// سطر تحت العنوان: العميل ثم الحالة
/// The subtitle line: customer, then the stage.
String tailoringHeaderSubtitle(CuttingBillDetail detail) {
  final customer = detail.header.custName.isEmpty
      ? 'عميل غير مسمّى'
      : detail.header.custName;
  final stage =
      detail.header.ordsName ??
      (detail.header.handingDone ? 'تم التسليم' : 'قيد التنفيذ');
  return '$customer · $stage';
}
