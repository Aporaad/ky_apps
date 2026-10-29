import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/presentation/widgets/model_fabrics_table.dart';
import '../../../tailoring/presentation/widgets/model_measurements_grid.dart';
import '../../../tailoring/presentation/widgets/model_specs_panel.dart';
import '../../data/models/measurement_model_ref.dart';
import '../../data/repositories/customer_measurement_repository.dart';
import '../providers/customer_measurement_providers.dart';
import '../utils/customer_measurement_pdf_builder.dart';
import '../widgets/measurement_filter_bar.dart';
import '../widgets/measurement_subject_card.dart';

/// شاشة عرض المقاسات — الهدف من القسم كله
/// The measurements view screen — the point of the whole section.
///
/// الأقسام الأربعة بترتيبها المطلوب: التفاصيل الأساسية للعميل/المستفيد · تفاصيل المقاسات ·
/// معلومات مواصفات الموديل · الأقمشة الخاصة بالموديل. وكلها داخل `ReportZoomView` (تكبير
/// بالإصبع وبالأزرار مع نسبة ظاهرة) كما في بقية شاشات التقارير.
/// The four sections in the requested order: the customer/beneficiary basics, the measurements,
/// the model specs and the model's fabrics. All of it sits inside `ReportZoomView` (pinch and
/// button zoom with a live percentage), exactly like every other report screen.
///
/// الفلترة زرّ في الشريط العلوي يُظهر ويخفي شريط المرشّحات: القرار قرار قراءة، ولا شيء فيه
/// يلمس البيانات.
/// Filtering is one AppBar button that shows or hides the filter bar: a reading decision that
/// touches no data.
class MeasurementViewScreen extends ConsumerStatefulWidget {
  /// المفتاح الرباعي المطلوب عرضه — قد يتغيّر داخلياً عند التنقل بين موديلات الفاتورة
  /// The requested four-part key — it may change internally when moving between a bill's models.
  ///
  /// اسمه `modelKey` لا `key`: الاسم الثاني مملوك لـ `Widget.key` ولا يجوز تظليله بنوع آخر.
  /// It is named `modelKey`, not `key`: that name belongs to `Widget.key` and must not be shaded
  /// by another type.
  final MeasurementKey modelKey;
  final String custName;

  const MeasurementViewScreen({
    super.key,
    required this.modelKey,
    this.custName = '',
  });

  @override
  ConsumerState<MeasurementViewScreen> createState() =>
      _MeasurementViewScreenState();
}

class _MeasurementViewScreenState extends ConsumerState<MeasurementViewScreen> {
  /// الموديل المعروض الآن: يبدأ بالمطلوب ويتبدّل بمنتقي المستفيدين في شريط الفلترة
  /// The model on screen now: it starts at the requested one and moves with the filter bar's
  /// beneficiary picker.
  late MeasurementKey _activeKey = widget.modelKey;

  /// شريط الفلترة مخفي افتراضياً: المقاسات هي الهدف، والفلترة أداة عند الطلب
  /// The filter bar starts hidden: the measurements are the point, filtering is on demand.
  bool _showFilters = false;

  MeasurementFilters _filters = MeasurementFilters.defaults;

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
    final async = ref.watch(customerMeasurementProvider(_activeKey));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(async),
      body: Column(
        children: [
          if (_showFilters)
            _buildFilterBar(async.value),
          Expanded(child: _buildBody(async)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(AsyncValue<MeasurementSubject> async) {
    final subject = async.value;
    final header = subject?.detail.header;
    final model = subject?.model;
    final custName = (header?.custName.isNotEmpty ?? false)
        ? header!.custName
        : widget.custName;

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
          const Icon(
            Icons.straighten_rounded,
            color: Color(0xFFD97706),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  custName.isEmpty ? 'مقاسات العميل' : 'مقاسات $custName',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _subtitle(header?.referenceLabel, model),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // إظهار/إخفاء الفلترة — نقطة صغيرة تخبر أن مرشّحاً مطبّقاً والشريط مغلق
        // Show/hide filters — a dot says a filter is applied while the bar is closed.
        IconButton(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Badge(
            isLabelVisible: _filters.isDirty && !_showFilters,
            smallSize: 7,
            label: const Text('1', style: TextStyle(fontSize: 7)),
            child: Icon(
              _showFilters
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_off_rounded,
              size: 21,
            ),
          ),
          tooltip: _showFilters ? 'إخفاء الفلترة' : 'إظهار الفلترة',
        ),
        PermissionGate(
          code: Perm.customersMeasurementsPrint,
          child: IconButton(
            onPressed: subject == null || _busy ? null : () => _print(subject),
            icon: const Icon(Icons.print_rounded, size: 21),
            tooltip: 'طباعة',
          ),
        ),
        PermissionGate(
          code: Perm.customersMeasurementsExport,
          child: IconButton(
            onPressed: subject == null || _busy ? null : () => _export(subject),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 21),
            tooltip: 'تصدير PDF',
          ),
        ),
        IconButton(
          onPressed: () =>
              ref.invalidate(customerMeasurementProvider(_activeKey)),
          icon: const Icon(Icons.refresh_rounded, size: 21),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  String _subtitle(String? billLabel, CuttingModelItem? model) {
    final beneficiary = model?.beneficiary;
    final parts = <String>[
      if (beneficiary != null) beneficiary,
      if (billLabel != null) 'فاتورة $billLabel',
      if (model != null) 'موديل ${model.seqNo}',
    ];

    return parts.isEmpty ? 'مقاسات الموديل' : parts.join(' · ');
  }

  /// شريط الفلترة — يُمرَّر إليه الإخوة لمنتقي المستفيد إن تعدّدوا
  /// The filter bar — given the bill's other models so the beneficiary picker can appear.
  Widget _buildFilterBar(MeasurementSubject? subject) {
    return MeasurementFilterBar(
      value: _filters,
      onChanged: (next) => setState(() => _filters = next),
      siblings: subject?.siblings ?? const [],
      // بلا حزمة محمّلة لا منتقي: لا شيء يُختار بعد
      // With no loaded bundle there is nothing to pick, so the picker is simply absent.
      onSelectSibling: subject == null
          ? null
          : (seqNo) {
              if (seqNo == _activeKey.seqNo) return;
              // المفتاح الجديد يُحمّل موديل آخر من نفس الفاتورة بنفس العميل
              // The new key loads another model of the same bill under the same customer.
              setState(() => _activeKey = subject.keyFor(seqNo));
            },
    );
  }

  Widget _buildBody(AsyncValue<MeasurementSubject> async) {
    return async.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل المقاسات...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
      error: (error, _) => _buildError(error),
      data: (subject) => _buildContent(subject),
    );
  }

  Widget _buildError(Object error) {
    final isNotFound = error is MeasurementException && error.notFoundInView;
    final message = error is MeasurementException
        ? error.displayMessage
        : 'تعذّر تحميل المقاسات';

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
              isNotFound ? 'الموديل غير متاح للعرض' : 'تعذّر تحميل المقاسات',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNotFound
                  ? 'هذا الموديل ليس ضمن بيانات التفصيل المُسندة إلى قصّاص وخيّاط، أو أنه لا '
                        'يعود لهذا العميل. قد يكون الرقم صحيحاً لكنه خارج نطاق العرض.'
                  : message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(customerMeasurementProvider(_activeKey)),
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

  Widget _buildContent(MeasurementSubject subject) {
    final model = subject.model;

    if (model == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.straighten_rounded,
                size: 56,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 14),
              Text(
                'لا مقاسات لهذا الموديل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'الفاتورة لا تحمل موديلاً في مصدر البيانات، فلا مقاسات تُعرض.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // الأقسام الأربعة كما تُعرض، ثم تُرتَّب حسب العرض المتاح
    // The four sections as shown, then laid out for the width on offer.
    final subjectCard = MeasurementSubjectCard(
      header: subject.detail.header,
      model: model,
    );
    final measurementsCard = ModelMeasurementsGrid(
      model: model,
      labels: subject.detail.measureLabels,
    );
    final specsCard = ModelSpecsPanel(model: model);
    final fabricsCard = ModelFabricsTable(
      // بحث الأقمشة مرشّح عرض محلي: نسخة من الموديل بقطع مطابقة لا طلب شبكة جديد
      // The fabric search is a local view filter: a copy of the model with matching pieces, not
      // a new network request.
      model: _filterFabrics(model),
      // السعر ليس من هذا القسم: عمود فارغ دائماً في مطبوع المقاسات أسطرُ ضائعة
      // Prices are not part of this section: an always-empty column is wasted lines.
      showPrice: false,
    );

    return ReportZoomView(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            // العتبة 980 كبقية التقارير: صفوف على الحاسب وعمود واحد على الجوال
            // The 980 threshold, as in the other reports: rows on desktop, one column on mobile.
            final wide = constraints.maxWidth >= 980;
            const gap = SizedBox(height: 8);

            final tail = <Widget>[
              if (_filters.showMeasurements) ...[
                gap,
                measurementsCard,
              ],
              if (_filters.showSpecs) ...[gap, specsCard],
              if (_filters.showFabrics) ...[gap, fabricsCard],
            ];

            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [subjectCard, ...tail],
              );
            }

            // العريض: المقاسات والمواصفات جنباً إلى جنب لتقليل الارتفاع — وهو مطلوب الشاشة
            // On wide screens measurements and specs share a row, cutting the height the request
            // asked to minimise.
            final showPair = _filters.showMeasurements && _filters.showSpecs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                subjectCard,
                if (showPair) ...[
                  gap,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: measurementsCard),
                      const SizedBox(width: 8),
                      Expanded(flex: 7, child: specsCard),
                    ],
                  ),
                  if (_filters.showFabrics) ...[gap, fabricsCard],
                ] else
                  ...tail,
              ],
            );
          },
        ),
      ),
    );
  }

  /// نسخة من الموديل بقطع مطابقة لبحث القماش — بلا المس ببيانات الأصلية
  /// A copy of the model carrying only the pieces matching the fabric search — the original data
  /// is never mutated.
  CuttingModelItem _filterFabrics(CuttingModelItem model) {
    final query = _filters.clothQuery.trim();
    if (query.isEmpty) return model;

    final lower = query.toLowerCase();
    final matched = model.pieces
        .where(
          (piece) =>
              (piece.clothName?.toLowerCase().contains(lower) ?? false) ||
              (piece.clothType?.toLowerCase().contains(lower) ?? false) ||
              (piece.colorText?.toLowerCase().contains(lower) ?? false),
        )
        .toList();

    return CuttingModelItem(
      seqNo: model.seqNo,
      beneficiary: model.beneficiary,
      typeName: model.typeName,
      shapeName: model.shapeName,
      shapeStyleNo: model.shapeStyleNo,
      qty: model.qty,
      measurements: model.measurements,
      specs: model.specs,
      pieces: matched,
    );
  }

  /// ملف واحد يُستخدم للطباعة وللتصدير معاً
  /// One file is used for both printing and exporting.
  Future<Uint8List> _buildPdf(MeasurementSubject subject) {
    return buildCustomerMeasurementPdf(
      letterhead: _letterhead(),
      subject: subject,
      printedBy: _printedBy(),
    );
  }

  Future<void> _print(MeasurementSubject subject) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf(subject);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
      _recordActivity('print');
    } catch (_) {
      _showMessage('تعذّرت الطباعة — تحقّق من إعدادات الطابعة');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(MeasurementSubject subject) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdf(subject);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'customer-measurements-${_activeKey.custNo}-${_activeKey.billNo}'
            '-${_activeKey.year}-${_activeKey.seqNo}.pdf',
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
    ref.read(customerMeasurementRepositoryProvider).recordActivity(
      _activeKey,
      action: action,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
