import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/worker_work_report_model.dart';
import '../providers/worker_work_report_provider.dart';
import '../utils/worker_work_report_pdf_builder.dart';
import '../widgets/worker_work_report_table.dart';

/// شاشة "كشف حساب العمل" للقصاص والخياط — منسوخة من تقرير أوراكل
/// FOR_CUTTER_TAILOR / FOR_TAILOR بجدول كشف العمل فقط (تاريخ|موديل|عدد|سعر|إجمالي).
/// The work-report screen for cutters/tailors — mirrors the legacy Oracle report's
/// WORK table only (never the financial statement). Default period = the last day
/// that actually has a work record (resolved server-side on the first load).
class WorkerWorkReportScreen extends ConsumerStatefulWidget {
  final int workerId;
  final WorkerType workerType;
  final String workerName;
  final int? accNo;

  const WorkerWorkReportScreen({
    super.key,
    required this.workerId,
    required this.workerType,
    required this.workerName,
    this.accNo,
  });

  @override
  ConsumerState<WorkerWorkReportScreen> createState() =>
      _WorkerWorkReportScreenState();
}

class _WorkerWorkReportScreenState extends ConsumerState<WorkerWorkReportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilterPanel = true;

  // هل التحميل الجاري هو "الافتراضي" (بلا تواريخ مرسلة)؟ عند رجوع رد الخادم
  // نعكس الفترة التي اعتمدها (تاريخ آخر سجل عمل) على حقول الفلتر تلقائياً.
  bool _awaitingDefaultDates = false;

  /// عنوان التقرير حسب نوع العامل (يظهر في الترويسة وشريط الـ AppBar والـ PDF)
  String get _title => 'كشف حساب عمل ${widget.workerType.label}';

  @override
  void initState() {
    super.initState();
    // الفترة الافتراضية تُترك فارغة عمداً ليحدّدها الخادم عند أول تحميل:
    // يبحث عن تاريخ آخر سجل عمل للقصاص/الخياط ويعتمده (من = إلى = ذلك اليوم).
    _fromDate = null;
    _toDate = null;
    Future.microtask(_loadData);
  }

  @override
  void dispose() {
    // إلغاء الطلبات الجارية عبر Notifier (ref.onDispose) — لا حاجة لمنطق إضافي هنا.
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// تحليل تاريخ بصيغة dd/mm/yyyy (نفس صيغة الخادم) إلى DateTime، أو null عند تعذّر ذلك.
  DateTime? _parseDmy(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    final y = int.tryParse(parts[2].trim());
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  void _loadData() {
    // نتذكّر إن كان هذا طلباً افتراضياً (بلا تواريخ) لنعكس فترة الخادم على الحقول لاحقاً.
    _awaitingDefaultDates = _fromDate == null && _toDate == null;
    ref.read(workerWorkReportProvider.notifier).loadReport(
      widget.workerType,
      widget.workerId,
      fromDate: _fromDate != null ? _fmt(_fromDate!) : null,
      toDate: _toDate != null ? _fmt(_toDate!) : null,
    );
  }

  Future<void> _selectDate(bool isFrom) async {
    final initial =
        isFrom ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
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

  /// نطاقات جاهزة: اليوم / أسبوع / شهر / سنة / الكل — مع تحديث فوري.
  void _setQuickRange(String type) {
    final now = DateTime.now();
    setState(() {
      switch (type) {
        case 'today':
          _fromDate = now;
          _toDate = now;
        case 'week':
          _fromDate = now.subtract(const Duration(days: 7));
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

  /// يجمع بيانات الكشف الحالية لبناء PDF — يستخدم نفس ترويسة الشاشة لضمان التطابق.
  Future<Uint8List> _buildPdfBytes(WorkerWorkReport report) async {
    return buildWorkerWorkReportPdf(
      letterhead: _letterheadInfo(),
      title: _title,
      workerName: report.workerName,
      accNo: report.accNo.isNotEmpty
          ? report.accNo
          : (widget.accNo?.toString() ?? ''),
      currency: report.currency,
      fromDate: report.fromDate,
      toDate: report.toDate,
      rows: report.rows,
      totalCount: report.totalCount,
      totalAmount: report.totalAmount,
    );
  }

  Future<void> _printReport(WorkerWorkReport? report) async {
    if (report == null) return;
    final bytes = await _buildPdfBytes(report);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf(WorkerWorkReport? report) async {
    if (report == null) return;
    final bytes = await _buildPdfBytes(report);
    final accNo = report.accNo.isNotEmpty
        ? report.accNo
        : widget.workerId.toString();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'work-$accNo-report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workerWorkReportProvider);
    final report = state.report;

    // عند أول تحميل (بلا تواريخ) يعيّن الخادم الفترة على "تاريخ آخر سجل عمل".
    // نعكس تلك الفترة المعتمدة على حقول الفلتر ليبقى العرض مطابقاً للتقرير.
    ref.listen(workerWorkReportProvider, (previous, next) {
      if (!_awaitingDefaultDates) return;
      final applied = next.report;
      if (applied != null &&
          applied.fromDate.isNotEmpty &&
          applied.toDate.isNotEmpty) {
        final from = _parseDmy(applied.fromDate);
        final to = _parseDmy(applied.toDate);
        if (from != null && to != null) {
          setState(() {
            _fromDate = from;
            _toDate = to;
          });
        }
        _awaitingDefaultDates = false;
      }
    });

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              widget.workerName,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // زرّا الطباعة والتصدير — يظهران فقط لمن يحمل الصلاحية
          PermissionGate(
            code: Perm.accountsPrint,
            child: IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'طباعة',
              onPressed: () => _printReport(report),
            ),
          ),
          PermissionGate(
            code: Perm.accountsExport,
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              tooltip: 'تصدير PDF',
              onPressed: () => _exportPdf(report),
            ),
          ),
          // زر إظهار/إخفاء فلتر التواريخ
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
          if (_showFilterPanel) _buildDateFilterBar(),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  // ─── شريط فلترة التواريخ (من/إلى + نطاقات جاهزة) ────────────────────────────
  Widget _buildDateFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateField(
                  label: 'من تاريخ',
                  date: _fromDate,
                  onTap: () => _selectDate(true),
                  onClear: () {
                    setState(() => _fromDate = null);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField(
                  label: 'إلى تاريخ',
                  date: _toDate,
                  onTap: () => _selectDate(false),
                  onClear: () {
                    setState(() => _toDate = null);
                    _loadData();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
        return same(_fromDate, now.subtract(const Duration(days: 7))) &&
            same(_toDate, now);
      case 'month':
        return _fromDate != null &&
            _fromDate!.year == now.year &&
            _fromDate!.month == now.month &&
            _fromDate!.day == 1 &&
            same(_toDate, now);
      case 'year':
        return _fromDate != null &&
            _fromDate!.year == now.year &&
            _fromDate!.month == 1 &&
            _fromDate!.day == 1 &&
            _toDate != null &&
            _toDate!.year == now.year &&
            _toDate!.month == 12 &&
            _toDate!.day == 31;
      case 'all':
        return _fromDate != null && _fromDate!.year == 2000 && same(_toDate, now);
      default:
        return false;
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final text = date != null ? _fmt(date) : 'غير محدد';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: date != null ? const Color(0xFF6B2D1B) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color:
                  date != null ? const Color(0xFF6B2D1B) : AppColors.textMuted,
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
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: date != null
                          ? const Color(0xFF6B2D1B)
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
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
  Widget _buildBody(WorkerWorkReportState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B2D1B)),
            SizedBox(height: 16),
            Text(
              'جاري تحميل كشف العمل...',
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
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
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

  // ─── ورقة التقرير: ترويسة رسمية + شريط بيانات + الجدول + تذييل التوقيعات ─────
  Widget _buildReportSheet(WorkerWorkReport report) {
    // مشاهدة الإعدادات تعيد رسم الترويسة فور أي حفظ من شاشة تهيئة التطبيق
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider).config,
    );
    final accNo = report.accNo.isNotEmpty
        ? report.accNo
        : (widget.accNo?.toString() ?? '');

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. الترويسة الرسمية الموحّدة (عربي/شعار/إنجليزي)
                ReportLetterheadBranding(info: letterhead),
                const SizedBox(height: 8),
                // 2. عنوان التقرير
                Center(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B2D1B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // 3. شريط بيانات العامل والحساب والعملة والفترة
                _metaBar(report, accNo),
                const SizedBox(height: 14),
                // 4. جدول كشف العمل
                WorkerWorkReportTable(
                  rows: report.rows,
                  totalCount: report.totalCount,
                  totalAmount: report.totalAmount,
                ),
                const SizedBox(height: 22),
                // 5. التذييل الرسمي: التوقيعات + إشعار 15 يوماً
                _signatureFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaBar(WorkerWorkReport report, String accNo) {
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
                'كشف له:  ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Flexible(
                child: Text(
                  report.workerName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                accNo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                report.currency,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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

  // ─── التذييل الرسمي: ثلاثة توقيعات + إشعار المصادقة خلال 15 يوماً ─────────────
  Widget _signatureFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _sigSlot('توقيع المحاسب'),
            _sigSlot('توقيع أمين الصندوق'),
            _sigSlot('توقيع المدير'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '(يعتبر هذا الكشف صحيحاً ومصدقاً عليه إذا لم يصلنا أي اعتراض خطي خلال فترة 15 يوماً من تاريخه)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// خانة توقيع مرنة — تأخذ ثلث العرض المتاح لتجنّب تجاوز الحافة على الشاشات الضيّقة.
  Widget _sigSlot(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: double.infinity,
              child: Divider(color: Color(0xFF6B7280), thickness: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
