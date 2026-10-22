import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/account_group_statement_model.dart';
import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_group_statement_pdf_builder.dart';
import '../utils/group_statement_scope.dart';
import '../utils/statement_date_parser.dart';
import '../widgets/account_group_statement_report_table.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateSlash(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// شاشة "كشف حساب مجموعة حسابات جزئية" (ميزان المراجعة) - التقرير 2.
/// أربع قوائم منسدلة متسلسلة + نطاق تواريخ اختياري (بلا افتراضي تلقائي، خلافًا
/// للتقرير الأول) يعرض كل الحركات عند تركه فارغًا، مطابق لـ TRIAL_BALANCE_REPORT.pdf.
class AccountGroupStatementScreen extends ConsumerStatefulWidget {
  const AccountGroupStatementScreen({super.key});

  @override
  ConsumerState<AccountGroupStatementScreen> createState() =>
      _AccountGroupStatementScreenState();
}

class _AccountGroupStatementScreenState
    extends ConsumerState<AccountGroupStatementScreen> {
  int? _accNo;
  int? _accSub;
  int? _accPart;
  int? _groupId;

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  bool _filtersVisible = true;
  TrialBalanceReport _report = TrialBalanceReport.empty;
  String? _error;

  // أعلام التهيئة التلقائية للاختيار الافتراضي (أول حساب رئيسي ثم أول فرعي ثم أول
  // جزئي) مرة واحدة فقط حتى لا يُفرض الاختيار مجدداً بعد تدخّل المستخدم.
  // One-shot flags for the initial auto-selection (first main → first sub → first
  // part) so the default is never re-imposed after the user interacts.
  bool _autoSelectedAccNo = false;
  bool _autoSelectedAccSub = false;
  bool _autoSelectedAccPart = false;

  Future<void> _loadReport() async {
    final scope = resolveStatementScope(
      accNo: _accNo,
      accSub: _accSub,
      accPart: _accPart,
      groupId: _groupId,
    );
    if (scope == null) {
      setState(() {
        _report = TrialBalanceReport.empty;
        _error = 'يجب اختيار حساب رئيسي على الأقل لتحديد نطاق التقرير';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = ref.read(accountRepositoryProvider);
    try {
      final res = await repo.fetchGroupStatement(
        accNo: scope.accNo,
        accSub: scope.accSub,
        accPart: scope.accPart,
        groupId: scope.groupId,
        fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
        toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
      );
      setState(() {
        _report = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'خطأ في جلب التقرير: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب التقرير: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onAccNoChanged(int? value) {
    setState(() {
      _accNo = value;
      _accSub = null;
      _accPart = null;
      _groupId = null;
    });
    if (value != null) _loadReport();
  }

  void _onAccSubChanged(int? value) {
    setState(() {
      _accSub = value;
      _accPart = null;
      _groupId = null;
    });
    if (value != null) _loadReport();
  }

  void _onAccPartChanged(int? value) {
    setState(() {
      _accPart = value;
      _groupId = null;
    });
    if (value != null) _loadReport();
  }

  void _onGroupChanged(int? value) {
    setState(() => _groupId = value);
    // إعادة التحميل دائماً حتى عند التفرير (null) — يجب أن يعود التقرير
    // لمستوى الحساب الجزئي إذا لم تُختر مجموعة
    // Always reload — even when clearing to null, the report must fall back
    // to the accPart-level scope when no group is selected.
    _loadReport();
  }

  /// يطبّق الاختيار الافتراضي مرة واحدة عند تحميل القوائم: أول حساب رئيسي، ثم
  /// أول حساب فرعي تابعه، ثم أول حساب جزئي تابعه، وبعدها يُجلب التقرير لمستوى
  /// الجزئي مباشرة.
  /// Applies the one-shot default selection: first main account → first sub
  /// account under it → first partial account under that, then loads the report
  /// at the partial scope.
  void _maybeApplyDefaults(
    AsyncValue<List<AccountModel>> accountsAsync,
    AsyncValue<List<AccMainModel>>? accMainAsync,
    AsyncValue<List<AccSubModel>>? accSubAsync,
  ) {
    // المرحلة 1: اختيار أول حساب رئيسي دون جلب بعد (ننتظر الفرعي ثم الجزئي).
    // Stage 1: pick the first main without loading yet — we wait for sub, then part.
    if (!_autoSelectedAccNo) {
      final list = accountsAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccNo = true;
      if (list.isNotEmpty && _accNo == null) {
        final firstAccNo = list.first.accNo;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _accNo = firstAccNo);
        });
      }
      return;
    }

    // المرحلة 2: اختيار أول حساب فرعي (بدون جلب — ننتظر الجزئي).
    // Stage 2: pick the first sub without loading yet — we wait for the part.
    if (!_autoSelectedAccSub && _accNo != null && accMainAsync != null) {
      final list = accMainAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccSub = true;
      final firstSub = list.isNotEmpty ? list[1].accSub : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _accSub = firstSub);
        // إن لم توجد حسابات فرعية، لا يوجد مستوى جزئي نُجلب له — نجلب فوراً.
        // No sub accounts exist, so there is no part to wait for — load now.
        if (firstSub == null) _loadReport();
      });
      return;
    }

    // المرحلة 3: اختيار أول حساب جزئي ثم جلب التقرير مرة واحدة.
    // Stage 3: pick the first partial account then load the report once.
    if (!_autoSelectedAccPart && _accSub != null && accSubAsync != null) {
      final list = accSubAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccPart = true;
      final firstPart = list.isNotEmpty ? list[1].accPart : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _accPart = firstPart);
        _loadReport();
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    // نقصّ initialDate داخل نطاق الـ picker احتياطاً — الـ assertion الخاص
    // بـ Material ينهار إذا تجاوز التاريخ المبدئي firstDate/lastDate.
    // Clamp the initial date into the picker's legal range as a hard guard:
    // Material asserts initialDate ∈ [firstDate, lastDate].
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);
    final initial = clampToDatePickerRange(
      (isFrom ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadReport();
    }
  }

  /// هوية ترويسة التقرير من إعدادات التطبيق — تُقرأ عند الطباعة/التصدير،
  /// بينما تراقبها الشاشة في `build`.
  /// Report letterhead identity from app config, read imperatively for print/export.
  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

  Future<void> _printReport() async {
    final bytes = await buildAccountGroupStatementPdf(
      letterhead: _letterheadInfo(),
      report: _report,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf() async {
    final bytes = await buildAccountGroupStatementPdf(
      letterhead: _letterheadInfo(),
      report: _report,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'group-statement.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final hasData = !_isLoading && !_report.isEmpty && _error == null;

    // تراقب الهوية كما تُعدَّل من شاشة التهيئة فتنعكس على الترويسة فوراً
    // Watches the configured identity so a branding edit repaints the letterhead at once.
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider.select((s) => s.config)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'كشف حساب مجموعة حسابات جزئية',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
                _filtersVisible ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 20),
            tooltip: _filtersVisible ? 'إخفاء الفلترة' : 'إظهار الفلترة',
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
          ),
          if (hasData) ...[
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
          ],
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'تحديث',
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtersVisible) _buildFilterBar(),
          Expanded(child: _buildBody(hasData, letterhead)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCascadeDropdownRow(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _fromDate != null ? _formatDateSlash(_fromDate!) : 'من تاريخ',
                  hasValue: _fromDate != null,
                  icon: Icons.calendar_today,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: _toDate != null ? _formatDateSlash(_toDate!) : 'إلى تاريخ',
                  hasValue: _toDate != null,
                  icon: Icons.event_outlined,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    _loadReport();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.clear_rounded,
                        color: AppColors.error, size: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'اترك الفترة فارغة لعرض كل الحركات عبر كامل السجل التاريخي',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadeDropdownRow() {
    final accountsAsync = ref.watch(parentAccountsProvider);
    final accMainAsync =
        _accNo != null ? ref.watch(parentAccMainProvider(_accNo)) : null;
    final accSubAsync = _accSub != null ? ref.watch(parentAccSubProvider(_accSub)) : null;
    final accGroupAsync =
        _accPart != null ? ref.watch(parentAccSubGroupProvider(_accPart)) : null;

    // اختيار افتراضي لأول حساب رئيسي ثم أول فرعي ثم أول جزئي عند التحميل الأولي
    // Default-select the first main, then the first sub, then the first part on load.
    _maybeApplyDefaults(accountsAsync, accMainAsync, accSubAsync);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _cascadeDropdown<AccountModel>(
          label: 'حساب رئيسي',
          items: accountsAsync.asData?.value ?? const [],
          selectedId: _accNo,
          idOf: (e) => e.accNo,
          labelOf: (e) => '${e.accNo} - ${ArabicEncodingUtils.fix(e.accName)}',
          isLoading: accountsAsync.isLoading,
          onChanged: _onAccNoChanged,
        ),
        if (accMainAsync != null)
          _cascadeDropdown<AccMainModel>(
            label: 'حساب فرعي',
            items: accMainAsync.asData?.value ?? const [],
            selectedId: _accSub,
            idOf: (e) => e.accSub,
            labelOf: (e) => ArabicEncodingUtils.fix(e.subName),
            isLoading: accMainAsync.isLoading,
            onChanged: _onAccSubChanged,
          ),
        if (accSubAsync != null)
          _cascadeDropdown<AccSubModel>(
            label: 'حساب جزئي',
            items: accSubAsync.asData?.value ?? const [],
            selectedId: _accPart,
            idOf: (e) => e.accPart,
            labelOf: (e) => ArabicEncodingUtils.fix(e.partName),
            isLoading: accSubAsync.isLoading,
            onChanged: _onAccPartChanged,
          ),
        if (accGroupAsync != null)
          _cascadeDropdown<AccSubGroupModel>(
            label: 'مجموعات الحساب الجزئي (اختياري)',
            items: accGroupAsync.asData?.value ?? const [],
            selectedId: _groupId,
            idOf: (e) => e.groupId,
            labelOf: (e) => ArabicEncodingUtils.fix(e.accGroupName),
            isLoading: accGroupAsync.isLoading,
            onChanged: _onGroupChanged,
            allowClear: true,
          ),
      ],
    );
  }

  Widget _cascadeDropdown<T>({
    required String label,
    required List<T> items,
    required int? selectedId,
    required int Function(T) idOf,
    required String Function(T) labelOf,
    required bool isLoading,
    required ValueChanged<int?> onChanged,
    bool allowClear = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      child: isLoading
          ? const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : DropdownButtonFormField<int>(
              value: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              items: [
                if (allowClear)
                  const DropdownMenuItem<int>(
                      value: null, child: Text('— بدون اختيار —')),
                ...items.map(
                  (item) => DropdownMenuItem<int>(
                    value: idOf(item),
                    child: Text(
                      labelOf(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
    );
  }

  Widget _buildBody(bool hasData, ReportLetterheadInfo letterhead) {
    if (_accNo == null) {
      return _buildEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'لم يُختر نطاق بعد',
        subtitle: 'اختر حساباً رئيسياً على الأقل لعرض ميزان المراجعة',
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'تعذّر جلب التقرير',
        subtitle: _error!,
      );
    }
    if (!hasData) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد حسابات في هذا النطاق',
        subtitle: 'النطاق المحدد لا يحتوي أي حسابات مالية مسجلة',
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3,
      // تمرير طبيعي للصفحة كاملة مع تذييل في نهاية المحتوى (لا A4 على الشاشة)
      // Natural full-page scroll with the footer at content end (no on-screen A4).
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ReportA4Sheet(
          orientation: ReportSheetOrientation.landscape,
          maxPageWidth: 1100,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF4B5563), width: 1.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // الترويسة ثلاثية الأعمدة: الكتلة العربية + الشعار + الكتلة
                        // الإنجليزية، من إعدادات التطبيق — نفس الكائن الذي يذهب إلى PDF
                        // Three-column band (Arabic / logo / English) from app config —
                        // the same object handed to the PDF.
                        ReportLetterheadBranding(info: letterhead),
                        const SizedBox(height: 6),
                        const Text(
                          'كشف حساب مجموعة حسابات جزئية',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مجموعة حسابات: ${ArabicEncodingUtils.fix(_report.scopeLabel)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _report.fromDate != null && _report.toDate != null
                                    ? 'من تاريخ: ${_report.fromDate}   إلى تاريخ: ${_report.toDate}'
                                    : 'كل الحركات (بدون تحديد فترة)',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black87),
                              ),
                            ),
                            Text(
                              'بتاريخ: ${_report.asOfDate}',
                              style: const TextStyle(
                                  fontSize: 10.5, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AccountGroupStatementReportTable(report: _report),
                ],
              ),
            ),
            footer: const ReportSignatureFooter(),
          ),
        ),
      );
  }

  Widget _buildDateButton({
    required String label,
    required bool hasValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              hasValue ? AppColors.primary.withValues(alpha: 0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                hasValue ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14, color: hasValue ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: hasValue ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
