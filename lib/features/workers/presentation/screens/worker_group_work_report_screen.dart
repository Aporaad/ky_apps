import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/worker_group_work_report_model.dart';
import '../../data/models/worker_model.dart';
import '../providers/worker_group_work_report_provider.dart';
import '../utils/worker_group_work_report_pdf_builder.dart';
import '../widgets/worker_group_work_report_table.dart';

/// شاشة "كشف عمل مجموعة" — تعرض أعمال جميع القصاصين أو جميع الخياطين في فترة محددة.
/// مُجمّعة لكل (عامل + موديل): سطر واحد يجمع العدد والمبلغ عبر الفترة، بجدول خمسة أعمدة
/// (الاسم | الموديل | العدد | السعر | الإجمالي).
///
/// Group work report screen — shows all cutters' or all tailors' work in a date range,
/// aggregated per (worker + style) into a five-column table.
/// Default period = last 7 days from today.
class WorkerGroupWorkReportScreen extends ConsumerStatefulWidget {
  const WorkerGroupWorkReportScreen({super.key});

  @override
  ConsumerState<WorkerGroupWorkReportScreen> createState() =>
      _WorkerGroupWorkReportScreenState();
}

class _WorkerGroupWorkReportScreenState
    extends ConsumerState<WorkerGroupWorkReportScreen> {
  // المجموعة المختارة: قصاصين أو خياطين
  WorkerType _selectedGroup = WorkerType.cutter;

  // الفترة الزمنية — الافتراضي آخر 7 أيام
  late DateTime _fromDate;
  late DateTime _toDate;

  bool _showFilterPanel = true;

  @override
  void initState() {
    super.initState();
    // الفترة الافتراضية: آخر 7 أيام من اليوم الحالي
    final now = DateTime.now();
    _fromDate = now.subtract(const Duration(days: 6));
    _toDate = now;
    Future.microtask(_loadData);
  }

  String _groupLabel() {
    switch (_selectedGroup) {
      case WorkerType.cutter:
        return 'القصاصين';
      case WorkerType.tailor:
        return 'الخياطيين';
      case WorkerType.employee:
        return '';
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _loadData() {
    ref.read(workerGroupWorkReportProvider.notifier).loadReport(
      _selectedGroup,
      fromDate: _fmt(_fromDate),
      toDate: _fmt(_toDate),
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      helpText: isFrom ? 'اختر تاريخ البداية' : 'اختر تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'تحديد',
    );
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
      _loadData();
    }
  }

  /// نطاقات جاهزة: اليوم / أسبوع / شهر / سنة / الكل
  void _setQuickRange(String type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case 'today':
          _fromDate = now;
          _toDate = now;
        case 'week':
          _fromDate = now.subtract(const Duration(days: 6));
          _toDate = now;
        case 'month':
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = now;
        case 'year':
          _fromDate = DateTime(now.year, 1, 1);
          _toDate = DateTime(now.year, 12, 31);
        case 'all':
          _fromDate = DateTime(2000, 1, 1);
          _toDate = now;
      }
    });
    _loadData();
  }

  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
    ref.read(appConfigNotifierProvider).config,
  );

  Future<Uint8List> _buildPdfBytes(WorkerGroupWorkReport report) async {
    return buildWorkerGroupWorkReportPdf(
      letterhead: _letterheadInfo(),
      title: 'كشف عمل مجموعة ${_groupLabel()}',
      groupLabel: _groupLabel(),
      fromDate: report.fromDate,
      toDate: report.toDate,
      rows: report.rows,
      totalCount: report.totalCount,
      totalAmount: report.totalAmount,
      workerCount: report.workerCount,
    );
  }

  Future<void> _printReport(WorkerGroupWorkReport? report) async {
    if (report == null) return;
    final bytes = await _buildPdfBytes(report);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf(WorkerGroupWorkReport? report) async {
    if (report == null) return;
    final bytes = await _buildPdfBytes(report);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'group-work-${_selectedGroup.apiPath}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workerGroupWorkReportProvider);
    final report = state.report;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'كشف عمل مجموعة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // زر الطباعة
          PermissionGate(
            code: Perm.accountsPrint,
            child: IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'طباعة',
              onPressed: () => _printReport(report),
            ),
          ),
          // زر التصدير
          PermissionGate(
            code: Perm.accountsExport,
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              tooltip: 'تصدير PDF',
              onPressed: () => _exportPdf(report),
            ),
          ),
          // زر إظهار/إخفاء الفلتر
          IconButton(
            onPressed: () =>
                setState(() => _showFilterPanel = !_showFilterPanel),
            icon: Icon(
              _showFilterPanel
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color: _showFilterPanel
                  ? const Color(0xFF6B2D1B)
                  : AppColors.textMuted,
            ),
            tooltip: 'تصفية التواريخ',
          ),
          // زر التحديث
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          if (_showFilterPanel) _buildFilterBar(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  // ─── شريط الفلترة: مجموعة + تواريخ + نطاقات جاهزة ────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اختيار المجموعة
          Row(
            children: [
              const Text(
                'المجموعة: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WorkerType>(
                    value: _selectedGroup,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WorkerType.cutter,
                        child: Row(
                          children: [
                            Icon(Icons.content_cut_rounded, size: 18, color: Color(0xFF059669)),
                            SizedBox(width: 8),
                            Text('القصاصين'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: WorkerType.tailor,
                        child: Row(
                          children: [
                            Icon(Icons.design_services_outlined, size: 18, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Text('الخياطيين'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && val != _selectedGroup) {
                        setState(() => _selectedGroup = val);
                        _loadData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // تواريخ من / إلى
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'من تاريخ',
                  date: _fromDate,
                  onTap: () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'إلى تاريخ',
                  date: _toDate,
                  onTap: () => _selectDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // نطاقات جاهزة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'فترة سريعة: ',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _chip('اليوم', _isPreset('today'), () => _setQuickRange('today')),
                _chip('أسبوع', _isPreset('week'), () => _setQuickRange('week')),
                _chip('الشهر', _isPreset('month'), () => _setQuickRange('month')),
                _chip('السنة', _isPreset('year'), () => _setQuickRange('year')),
                _chip('الكل', _isPreset('all'), () => _setQuickRange('all')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isPreset(String type) {
    final now = DateTime.now();
    bool same(DateTime? a, DateTime? b) =>
        a != null &&
        b != null &&
        a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
    switch (type) {
      case 'today':
        return same(_fromDate, now) && same(_toDate, now);
      case 'week':
        return same(_fromDate, now.subtract(const Duration(days: 6))) &&
            same(_toDate, now);
      case 'month':
        return _fromDate.year == now.year &&
            _fromDate.month == now.month &&
            _fromDate.day == 1 &&
            same(_toDate, now);
      case 'year':
        return _fromDate.year == now.year &&
            _fromDate.month == 1 &&
            _fromDate.day == 1 &&
            _toDate.year == now.year &&
            _toDate.month == 12 &&
            _toDate.day == 31;
      case 'all':
        return _fromDate.year == 2000 && same(_toDate, now);
      default:
        return false;
    }
  }

  Widget _dateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6B2D1B)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: Color(0xFF6B2D1B),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    _fmt(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B2D1B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6B2D1B) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF6B2D1B)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ─── الجسم: أربع حالات (تحميل/خطأ/فراغ/نجاح) ────────────────────────────────
  Widget _buildBody(WorkerGroupWorkReportState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B2D1B)),
            SizedBox(height: 16),
            Text(
              'جاري تحميل كشف عمل المجموعة...',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (state.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B2D1B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final report = state.report;
    if (report == null) {
      return const Center(
        child: Text(
          'لا توجد بيانات',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }

    if (report.rows.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد عمليات عمل مسجلة في هذه الفترة',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }

    return _buildReportSheet(report);
  }

  // ─── ورقة التقرير: ترويسة + شريط بيانات + الجدول + تذييل التوقيعات ──────────
  Widget _buildReportSheet(WorkerGroupWorkReport report) {
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider).config,
    );

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3,
      // تمرير طبيعي للصفحة كاملة — لا ارتفاع A4 مقصوص ولا تجميد للتذييل
      // Natural full-page scroll — no clipped A4 height, no frozen footer.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: ReportA4Sheet(
          orientation: ReportSheetOrientation.landscape,
          // 1. الترويسة الرسمية الموحّدة
          header: ReportLetterheadBranding(info: letterhead),
          // 2. عنوان التقرير
          title: Center(
            child: Text(
              'كشف عمل مجموعة ${_groupLabel()}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6B2D1B),
              ),
            ),
          ),
          // 3. شريط بيانات المجموعة والفترة
          meta: _metaBar(report),
          // 4. جدول كشف عمل المجموعة — يتمرّر داخل المتن
          body: SingleChildScrollView(
            child: WorkerGroupWorkReportTable(
              rows: report.rows,
              totalCount: report.totalCount,
              totalAmount: report.totalAmount,
              workerCount: report.workerCount,
            ),
          ),
          // 5. التذييل الرسمي الموحّد: التوقيعات + إشعار 15 يوماً
          footer: const ReportSignatureFooter(),
        ),
      ),
    );
  }

  Widget _metaBar(WorkerGroupWorkReport report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2D9CC)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'المجموعة:  ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                _groupLabel(),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                'عدد ${_groupLabel()}:  ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${report.workerCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'من  ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                report.fromDate,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'إلى  ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                report.toDate,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
