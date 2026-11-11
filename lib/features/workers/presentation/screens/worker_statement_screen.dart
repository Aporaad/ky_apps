import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/lazy_report_table.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/worker_model.dart';
import '../../data/models/worker_statement_model.dart';
import '../providers/workers_provider.dart';
import '../utils/worker_statement_pdf_builder.dart';

/// شاشة كشف حساب العامل (موظف / قصاص / خياط)
/// مصممة ومطابقة تماماً لنموذج كشف الحساب المعتمد ومتجاوبة بالكامل بدون تمرير أفقي
class WorkerStatementScreen extends ConsumerStatefulWidget {
  final int workerId;
  final WorkerType workerType;
  final String workerName;
  final int? accNo;

  const WorkerStatementScreen({
    super.key,
    required this.workerId,
    required this.workerType,
    required this.workerName,
    this.accNo,
  });

  @override
  ConsumerState<WorkerStatementScreen> createState() =>
      _WorkerStatementScreenState();
}

class _WorkerStatementScreenState extends ConsumerState<WorkerStatementScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilterPanel = true;


  @override
  void initState() {
    super.initState();
    // المزود غير `autoDispose`: كشف العامل السابق بقي في `state` حتى بعد
    // إغلاق الشاشة، فظهرت نتائج عاملٍ آخر لحظة قبل وصول الطلب الجديد.
    // `resetTransient` لا `reload` — التحميل يتبع بمعطيات هذه الشاشة.
    // The provider is not autoDispose: the previous worker's statement sat in
    // `state` after the screen closed, so another worker's rows flashed before
    // the new request landed. Reset without reload — `_loadData` follows with
    // this screen's own arguments.
    //
    // النداء مؤجَّل إلى microtask: تعديل مزود أثناء بناء الشجرة يُطلق
    // شرط Riverpod «modify a provider while the widget tree is building».
    // Deferred to a microtask: mutating a provider mid-build trips Riverpod's
    // "modify a provider while the widget tree is building" assertion.
    Future.microtask(() {
      if (!mounted) return;
      ref.read(workerStatementProvider.notifier).resetTransient();
      _loadData();
    });
  }

  void _loadData() {
    final fromStr =
        _fromDate != null
            ? '${_fromDate!.day.toString().padLeft(2, '0')}/${_fromDate!.month.toString().padLeft(2, '0')}/${_fromDate!.year}'
            : null;
    final toStr =
        _toDate != null
            ? '${_toDate!.day.toString().padLeft(2, '0')}/${_toDate!.month.toString().padLeft(2, '0')}/${_toDate!.year}'
            : null;


    ref
        .read(workerStatementProvider.notifier)
        .loadStatement(
          widget.workerType,
          widget.workerId,
          fromDate: fromStr,
          toDate: toStr,
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
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadData();
    }
  }

  void _setQuickRange(String type, Map<String, dynamic>? summary) {
    setState(() {
      if (type == 'all') {
        _fromDate = null;
        _toDate = null;
      } else if (type == '30days') {
        final toDateVal = _toDate ?? DateTime.now();
        _fromDate = toDateVal.subtract(const Duration(days: 30));
      } else if (type == 'month') {
        final now = DateTime.now();
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month + 1, 0);
      } else if (type == 'year') {
        final now = DateTime.now();
        _fromDate = DateTime(now.year, 1, 1);
        _toDate = DateTime(now.year, 12, 31);
      }
    });
    _loadData();
  }

  /// هوية ترويسة التقرير من إعدادات التطبيق (تُقرأ أمراً للطباعة/التصدير)
  /// Report letterhead identity from app config (read imperatively for print/export).
  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

  /// يجمع بيانات الكشف الحالية من الـ provider لبناء ملف PDF.
  /// Gathers the current statement data from the provider to build the PDF.
  Future<Uint8List> _buildPdfBytes() async {
    final state = ref.read(workerStatementProvider);
    final summary = state.summary ?? {};
    final workerInfo = state.worker ?? {};
    final name = ArabicEncodingUtils.fix(
      workerInfo['name']?.toString() ?? widget.workerName,
    );
    final accNo =
        workerInfo['acc_no']?.toString() ??
        widget.accNo?.toString() ??
        '';
    final currency = (summary['currency'] ?? 'يمني YR').toString();
    final fromDate = (summary['from_date'] ?? '').toString();
    final toDate = (summary['to_date'] ?? '').toString();
    final openingBalance = (summary['opening_balance'] as num? ?? 0.0)
        .toDouble();
    final totalDebit = (summary['total_debit'] as num? ?? 0.0).toDouble();
    final totalCredit = (summary['total_credit'] as num? ?? 0.0).toDouble();
    final finalBalance = (summary['final_balance'] as num? ?? 0.0).toDouble();

    return buildWorkerStatementPdf(
      letterhead: _letterheadInfo(),
      workerName: name,
      workerTypeLabel: widget.workerType.label,
      accNo: accNo,
      currency: currency,
      fromDate: fromDate,
      toDate: toDate,
      rows: state.rows,
      openingBalance: openingBalance,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      finalBalance: finalBalance,
    );
  }

  Future<void> _printReport() async {
    final bytes = await _buildPdfBytes();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf() async {
    final state = ref.read(workerStatementProvider);
    final workerInfo = state.worker ?? {};
    final accNo =
        workerInfo['acc_no']?.toString() ??
        widget.accNo?.toString() ??
        widget.workerId.toString();
    final bytes = await _buildPdfBytes();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'worker-$accNo-statement.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workerStatementProvider);
    final summary = state.summary;
    final workerInfo = state.worker;

    final displayName = ArabicEncodingUtils.fix(
      workerInfo?['name']?.toString() ?? widget.workerName,
    );
    final displayAccNo =
        workerInfo?['acc_no']?.toString() ?? widget.accNo?.toString() ?? '';

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
              'كشف حساب ${widget.workerType.label}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              displayName,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // زرّا الطباعة والتصدير — يظهران فقط لمن يحمل الصلاحية
          // Print/export buttons — rendered only for permitted users.
          PermissionGate(
            code: Perm.accountsPrint,
            child: IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'طباعة',
              onPressed: _printReport,
            ),
          ),
          PermissionGate(
            code: Perm.accountsExport,
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              tooltip: 'تصدير PDF',
              onPressed: _exportPdf,
            ),
          ),
          // زر إظهار/إخفاء فلتر التواريخ
          IconButton(
            onPressed:
                () => setState(() => _showFilterPanel = !_showFilterPanel),
            icon: Icon(
              _showFilterPanel
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
              color:
                  _showFilterPanel
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
          // شريط فلترة التواريخ
          if (_showFilterPanel) _buildDateFilterBar(summary),

          // محتوى كشف الحساب
          Expanded(
            child: _buildBody(
              context,
              state,
              displayName,
              displayAccNo,
              summary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(Map<String, dynamic>? summary) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // من تاريخ
              Expanded(
                child: _buildDatePickerField(
                  label: 'من تاريخ',
                  date: _fromDate,
                  defaultHint: summary?['from_date']?.toString(),
                  onTap: () => _selectDate(true),
                  onClear: () {
                    setState(() => _fromDate = null);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 10),
              // إلى تاريخ
              Expanded(
                child: _buildDatePickerField(
                  label: 'إلى تاريخ',
                  date: _toDate,
                  defaultHint: summary?['to_date']?.toString(),
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
          // خيارات التصفية السريعة
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
                _quickFilterChip(
                  'آخر 30 يوم',
                  false,
                  () => _setQuickRange('30days', summary),
                ),
                const SizedBox(width: 6),
                _quickFilterChip(
                  'الشهر الحالي',
                  false,
                  () => _setQuickRange('month', summary),
                ),
                const SizedBox(width: 6),
                _quickFilterChip(
                  'العام الحالي',
                  false,
                  () => _setQuickRange('year', summary),
                ),
                const SizedBox(width: 6),
                _quickFilterChip(
                  'كل الحركات',
                  _fromDate == null && _toDate == null,
                  () => _setQuickRange('all', summary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    String? defaultHint,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final text =
        date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : (defaultHint ?? 'غير محدد');

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
                      color:
                          date != null
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

  Widget _quickFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B2D1B) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF6B2D1B) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WorkerStatementState state,
    String displayName,
    String displayAccNo,
    Map<String, dynamic>? summary,
  ) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B2D1B)),
            SizedBox(height: 16),
            Text(
              'جاري تحميل كشف الحساب...',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
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

    final rows = state.rows;
    if (rows.isEmpty && summary == null) {
      return const Center(
        child: Text(
          'لا توجد حركات مسجلة لهذا العامل في هذه الفترة',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }

    final fromDateStr =
        summary?['from_date']?.toString() ??
        (_fromDate != null
            ? '${_fromDate!.day.toString().padLeft(2, '0')}/${_fromDate!.month.toString().padLeft(2, '0')}/${_fromDate!.year}'
            : '');
    final toDateStr =
        summary?['to_date']?.toString() ??
        (_toDate != null
            ? '${_toDate!.day.toString().padLeft(2, '0')}/${_toDate!.month.toString().padLeft(2, '0')}/${_toDate!.year}'
            : '');
    final currency = summary?['currency']?.toString() ?? 'يمني YR';

    final totalDebit = (summary?['total_debit'] as num?)?.toDouble() ?? 0.0;
    final totalCredit = (summary?['total_credit'] as num?)?.toDouble() ?? 0.0;
    final openingBalance =
        (summary?['opening_balance'] as num?)?.toDouble() ?? 0.0;
    final finalBalance = (summary?['final_balance'] as num?)?.toDouble() ?? 0.0;

    return ReportZoomView(
      // تمرير طبيعي للصفحة كاملة — التذييل في نهاية المحتوى، بلا A4 على الشاشة
      // Natural full-page scroll — footer at content end, no on-screen A4.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ReportA4Sheet(
          orientation: ReportSheetOrientation.portrait,
          maxPageWidth: 1000,
          // الترويسة — الشريط الثلاثي الموحد (يمين عربي / شعار / يسار إنجليزي)
          header: _buildReportHeader(),
          // شريط بيانات العامل ورقم الحساب ونطاق التاريخ
          meta: _buildWorkerMetaBar(
            workerName: displayName,
            accNo: displayAccNo,
            currency: currency,
            fromDate: fromDateStr,
            toDate: toDateStr,
          ),
          // المتن — الجدول المتجاوب + التنقل + ملخص الأرصدة (قابل للتمرير)
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3. جدول كشف الحساب المتجاوب بالكامل (بدون تمرير أفقي)
                _buildStatementTableLayout(
                  rows: rows,
                  totalDebit: totalDebit,
                  totalCredit: totalCredit,
                  openingBalance: openingBalance,
                  finalBalance: finalBalance,
                ),


                const SizedBox(height: 16),

                // 5. صناديق ملخص الرصيد الافتتاحي والنهائي المطابقة للصورة
                _buildSummaryFooter(
                  openingBalance: openingBalance,
                  finalBalance: finalBalance,
                ),
              ],
            ),
          ),
          // 6. التذييل الرسمي — خانات التوقيع + إشعار 15 يوماً (مثبّت أسفل الورقة)
          footer: const ReportSignatureFooter(),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // الترويسة الرسمية — الشريط الثلاثي الأعمدة الموحَّد لكل التقارير
  // Official header — the same three-column band every report draws.
  //
  // كانت تُرسم يدوياً باسم وعنوان ثابتين؛ الآن تُقرأ من `APP_SETTINGS` (مفاتيح
  // company_*) عبر `ReportLetterheadBranding` فلا تختلف عن ترويسة شاشات الحسابات.
  // It used to be hand-drawn from hardcoded strings; it now comes from APP_SETTINGS
  // (the company_* keys) through ReportLetterheadBranding, identical to the accounts reports.
  // -------------------------------------------------------------
  Widget _buildReportHeader() {
    // مشاهدة الإعدادات تعيد رسم الترويسة فور أي حفظ من شاشة تهيئة التطبيق
    // Watching the config repaints the band right after a save in the settings screen.
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider).config,
    );

    return ReportLetterheadBranding(info: letterhead);
  }

  // -------------------------------------------------------------
  // شريط بيانات العامل والحساب ونطاق التاريخ
  // -------------------------------------------------------------
  Widget _buildWorkerMetaBar({
    required String workerName,
    required String accNo,
    required String currency,
    required String fromDate,
    required String toDate,
  }) {
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
          // اليمين: كشف حساب + اسم العامل
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'كشف حساب  ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Flexible(
                child: Text(
                  workerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // الوسط: رقم الحساب والعملة
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
                currency,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // اليسار: نطاق التاريخ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'من تاريخ  ',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                fromDate,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'إلى  ',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                toDate,
                style: const TextStyle(
                  fontSize: 8,
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

  // -------------------------------------------------------------
  // جدول كشف الحساب المتجاوب بالكامل مع أبعاد الشاشة
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // جدول الكشف — رأس مثبّت + صفوف كسولة + إجماليات مثبّتة
  // Statement table — pinned header + lazy rows + pinned totals.
  //
  // كان يبني كل الصفوف داخل `Table` واحد ثم يقصّها إلى 15 صفاً في الصفحة، فكان
  // الكشف إمّا يُخفي حركات الفترة أو يستنزف الذاكرة الأصلية عند عرضها كلها.
  // الآن تُبنى الصفوف عند ظهورها فقط، ويُعرض كل سطر في الفترة بلا استثناء.
  // It built all rows in one Table and then sliced 15 per page, so a wide period
  // either hid movements or exhausted the native heap. Rows are now built on demand
  // and every row of the period is shown.
  // -------------------------------------------------------------
  Widget _buildStatementTableLayout({
    required List<WorkerStatementModel> rows,
    required double totalDebit,
    required double totalCredit,
    required double openingBalance,
    required double finalBalance,
  }) {
    const headerBgColor = Color(0xFFD4A853); // اللون الذهبي المطابق للصورة
    const totalsBgColor = Color(0xFFF3F4F6);
    const openingColor = Color(0xFF0369A1);
    const amountRed = Color(0xFFDC2626);

    // أوزان الأعمدة مشتركة بين الشرائح الثلاث فتبقى الأرقام متحاذية.
    // Column weights shared by all three slices keep the amounts aligned.
    const columnWidths = <int, TableColumnWidth>{
      0: FlexColumnWidth(0.85), // السند
      1: FlexColumnWidth(1.15), // النوع
      2: FlexColumnWidth(1.0), // تأريخه
      3: FlexColumnWidth(3.3), // البيان
      4: FlexColumnWidth(1.2), // مدين
      5: FlexColumnWidth(1.2), // دائن
      6: FlexColumnWidth(1.45), // الرصيد
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 650;
        final isVeryCompact = screenWidth < 450;

        // أحجام النص والحشوات مطابقة لجدولي كشف العميل وكشف الحساب المالي
        // حتى يبدو شكل التقارير المالية واحداً على كل الشاشات.
        // Font sizes and paddings mirror the customer and account statement
        // tables so every financial report looks identical.
        final headerFontSize = isVeryCompact ? 9.5 : (isCompact ? 10.5 : 11.5);
        final dataFontSize = isVeryCompact ? 8.5 : (isCompact ? 9.5 : 10.5);
        final cellVPad = isVeryCompact ? 3.0 : (isCompact ? 3.5 : 4.5);
        final cellHPad = isVeryCompact ? 1.5 : (isCompact ? 2.5 : 4.0);

        Widget cell(String text, {bool center = true}) => _tableDataCell(
              text,
              isCenter: center,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
            );

        // 1) رأس الجدول الذهبي
        final headerRow = TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _tableHeaderCell('السند',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('النوع',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('تأريخه',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('البيان',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('مدين',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('دائن',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
            _tableHeaderCell('الرصيد',
                fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
          ],
        );

        // 2) سطر الرصيد الافتتاحي (مثبّت أعلى القائمة)
        final openingRow = TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: [
            cell(''),
            cell(''),
            cell(''),
            _tableDataCell(
              'رصيد افتتاحي',
              isCenter: true,
              textColor: openingColor,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
            ),
            _tableDataCell(
              openingBalance != 0.0 ? _formatAmount(openingBalance) : '',
              isCenter: true,
              textColor: amountRed,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
              fitBox: true,
            ),
            cell(''),
            cell(''),
          ],
        );

        // 3) سطر إجمالي العمليات (مثبّت أسفل القائمة)
        final totalsRow = TableRow(
          decoration: const BoxDecoration(color: totalsBgColor),
          children: [
            cell(''),
            cell(''),
            cell(''),
            _tableDataCell(
              'اجمالي العمليات',
              isCenter: true,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
            ),
            _tableDataCell(
              _formatAmount(totalDebit),
              isCenter: true,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
              fitBox: true,
            ),
            _tableDataCell(
              _formatAmount(totalCredit),
              isCenter: true,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
              fitBox: true,
            ),
            _tableDataCell(
              _formatAmount(totalDebit - totalCredit),
              isCenter: true,
              isBold: true,
              fontSize: dataFontSize,
              vPad: cellVPad,
              hPad: cellHPad,
              fitBox: true,
            ),
          ],
        );

        return LazyReportTable(
          headerRows: [headerRow, openingRow],
          footerRows: [totalsRow],
          columnWidths: columnWidths,
          rowCount: rows.length,
          rowBuilder: (index) {
            final row = rows[index];
            final debitVal = row.debit > 0
                ? row.debit
                : (row.entryMnt > 0 ? row.entryMnt : 0.0);
            final creditVal = row.credit > 0
                ? row.credit
                : (row.entryMnt < 0 ? row.entryMnt.abs() : 0.0);

            return TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [
                _tableDataCell(
                  row.subEntryNo ?? row.entryNo ?? '',
                  isCenter: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  ArabicEncodingUtils.fix(row.entryTypeName ?? ''),
                  isCenter: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                ),
                _tableDataCell(
                  row.entryDate ?? '',
                  isCenter: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  ArabicEncodingUtils.fix(row.details ?? ''),
                  isCenter: false,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                ),
                _tableDataCell(
                  debitVal > 0 ? _formatAmount(debitVal) : '',
                  isCenter: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  creditVal > 0 ? _formatAmount(creditVal) : '',
                  isCenter: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  _formatAmount(row.balance),
                  isCenter: true,
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // صناديق ملخص الرصيد الافتتاحي والنهائي المطابقة للصورة
  // -------------------------------------------------------------
  Widget _buildSummaryFooter({
    required double openingBalance,
    required double finalBalance,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صندوق الرصيد الافتتاحي
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4B5563), width: 1),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                color: const Color(0xFFE5E7EB),
                child: const Text(
                  'الرصيد الافتتاحي',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Text(
                    _formatAmount(openingBalance),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // صندوق الرصيد النهائي (المحدد بلون مميز مطابق للصورة)
        Container(
          width: 260,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF4B5563), width: 1),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                color: const Color(0xFFD4A853), // ذهبي مطابق للصورة
                child: const Text(
                  'الرصيد النهائي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 8,
                  ),
                  child: Text(
                    _formatAmount(finalBalance),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFDC2626), // أحمر عريض مطابق للصورة
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // خلايا الجدول
  Widget _tableHeaderCell(
    String text, {
    required double fontSize,
    required double vPad,
    required double hPad,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _tableDataCell(
    String text, {
    required bool isCenter,
    Color? textColor,
    bool isBold = false,
    required double fontSize,
    required double vPad,
    required double hPad,
    bool fitBox = false,
  }) {
    final widget = Text(
      text,
      textAlign: isCenter ? TextAlign.center : TextAlign.right,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: textColor ?? Colors.black87,
      ),
    );

    return Container(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child:
          isCenter
              ? (fitBox
                  ? FittedBox(fit: BoxFit.scaleDown, child: widget)
                  : Center(child: widget))
              : (fitBox
                  ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: widget,
                  )
                  : widget),
    );
  }

  String _formatAmount(double amount) {
    if (amount == 0.0) return '0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return isNegative ? '-$parts' : parts;
  }
}
