import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/chart_account_model.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_statement_pdf_builder.dart';
import '../utils/statement_date_parser.dart';
import '../widgets/account_statement_report_footer.dart';
import '../widgets/account_statement_report_table.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateSlash(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// شاشة كشف حساب مالي - قالب تقرير أوراكل acc_report.pdf
class AccountStatementScreen extends ConsumerStatefulWidget {
  final int? initialAccNo;
  final String? initialAccName;

  const AccountStatementScreen({
    super.key,
    this.initialAccNo,
    this.initialAccName,
  });

  @override
  ConsumerState<AccountStatementScreen> createState() =>
      _AccountStatementScreenState();
}

class _AccountStatementScreenState extends ConsumerState<AccountStatementScreen> {
  int? _selectedAccNo;
  String _selectedAccName = '';

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  bool _filtersVisible = true;
  AccountStatementData _statementData = const AccountStatementData();
  ChartAccountModel? _selectedAccount;

  @override
  void initState() {
    super.initState();
    if (widget.initialAccNo != null) {
      _selectedAccNo = widget.initialAccNo;
      _selectedAccName = widget.initialAccName ?? '';
      _loadStatement();
    }
  }

  Future<void> _loadStatement() async {
    if (_selectedAccNo == null) return;
    setState(() => _isLoading = true);
    final repo = ref.read(accountRepositoryProvider);
    try {
      final res = await repo.fetchAccountStatement(
        _selectedAccNo!,
        fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
        toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
      );
      setState(() {
        _statementData = res;
        _isLoading = false;
        // الخادم يحسب النافذة الافتراضية (آخر 30 يوم قبل آخر حركة) عند غياب
        // التواريخ - تُعرض هنا ليتمكن المستخدم من رؤيتها/تعديلها يدوياً بعد ذلك.
        // لا نعبّئ إلا إذا نجح تحليل التاريخين معاً حتى لا يبقى أحدهما معلّقاً.
        // Only auto-fill when BOTH dates parse — avoids half-set filter state.
        if (res.defaulted && res.fromDate != null && res.toDate != null) {
          final parsedFrom = _parseServerDate(res.fromDate!);
          final parsedTo = _parseServerDate(res.toDate!);
          if (parsedFrom != null && parsedTo != null) {
            _fromDate = parsedFrom;
            _toDate = parsedTo;
          }
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب كشف الحساب: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// حدود السنوات المقبولة — انظر `statement_date_parser.dart` للمنطق المشترك.
  /// See `statement_date_parser.dart` for the shared bounds logic.
  DateTime? _parseServerDate(String raw) => parseStatementServerDate(raw);

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
      _loadStatement();
    }
  }

  void _showAccountPickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AccountPickerBottomSheet(
        onSelected: (acc) {
          Navigator.pop(ctx);
          setState(() {
            _selectedAccNo = acc.accNo;
            _selectedAccName = acc.accName;
            _selectedAccount = acc;
          });
          _loadStatement();
        },
      ),
    );
  }

  /// هوية ترويسة التقرير من إعدادات التطبيق (اسم الشركة/العنوان/التواصل) — تُقرأ عند
  /// الطباعة/التصدير، أما الشاشة فتراقب نفس المزود في `build`.
  /// Report letterhead identity from app config, read imperatively for print/export.
  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

  Future<void> _printReport() async {
    final bytes = await buildAccountStatementPdf(
      letterhead: _letterheadInfo(),
      account: _selectedAccount,
      statement: _statementData,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf() async {
    final bytes = await buildAccountStatementPdf(
      letterhead: _letterheadInfo(),
      account: _selectedAccount,
      statement: _statementData,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'account-$_selectedAccNo-statement.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _selectedAccNo != null &&
        !_isLoading &&
        _statementData.transactions.isNotEmpty;

    // تراقب الشركة كما تُعدَّل من شاشة التهيئة، فتنعكس على الترويسة فوراً
    // Watches the configured identity so a branding edit repaints the letterhead at once.
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider.select((s) => s.config)),
    );

    final fromDateLabel = _fromDate != null
        ? _formatDateSlash(_fromDate!)
        : (_statementData.fromDate ?? 'من تاريخ');
    final toDateLabel = _toDate != null
        ? _formatDateSlash(_toDate!)
        : (_statementData.toDate ?? 'إلى تاريخ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'كشف حساب مالي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(_filtersVisible ? Icons.filter_alt : Icons.filter_alt_outlined, size: 20),
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
            onPressed: _loadStatement,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtersVisible) _buildFilterBar(fromDateLabel, toDateLabel),

          Expanded(
            child: _selectedAccNo == null
                ? _buildEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'لم يُختر حساب بعد',
                    subtitle: 'اضغط على حقل الحساب أعلاه لاختيار حساب مالي',
                  )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _statementData.transactions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'لا توجد حركات',
                    subtitle: 'لا توجد حركات مسجلة لهذا الحساب في الفترة المحددة',
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 5),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Card(
                          // padding: const EdgeInsets.symmetric(horizontal: 3),
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: Colors.white,
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AccountStatementLetterhead(
                                  letterhead: letterhead,
                                  accName: _selectedAccName,
                                  accNo: _selectedAccNo!,
                                  currency: _statementData.currency,
                                  fromDate: fromDateLabel,
                                  toDate: toDateLabel,
                                ),
                                AccountStatementReportTable(
                                  transactions: _statementData.transactions,
                                  openingBalance: _statementData.openingBalance ?? 0,
                                  finalBalance: _statementData.finalBalance ?? 0,
                                  totalDebit: _statementData.totalDebit ?? 0,
                                  totalCredit: _statementData.totalCredit ?? 0,
                                ),
                                AccountStatementReportFooter(
                                  openingBalance: _statementData.openingBalance ?? 0,
                                  totalDebit: _statementData.totalDebit ?? 0,
                                  totalCredit: _statementData.totalCredit ?? 0,
                                  finalBalance: _statementData.finalBalance ?? 0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(String fromDateLabel, String toDateLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _showAccountPickerDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedAccNo != null
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(10),
                color: _selectedAccNo != null
                    ? AppColors.primary.withValues(alpha: 0.04)
                    : AppColors.background,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _selectedAccNo != null ? AppColors.primary : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedAccNo != null
                          ? '[$_selectedAccNo] $_selectedAccName'
                          : 'اضغط لاختيار الحساب المالي...',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            _selectedAccNo != null ? FontWeight.bold : FontWeight.normal,
                        color:
                            _selectedAccNo != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: _selectedAccNo != null ? AppColors.primary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: fromDateLabel,
                  hasValue: _fromDate != null,
                  icon: Icons.calendar_today,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: toDateLabel,
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
                    _loadStatement();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.error,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
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
          color: hasValue ? AppColors.primary.withValues(alpha: 0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: hasValue ? AppColors.primary : AppColors.textMuted,
            ),
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
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// قائمة سفلية لاختيار الحساب المالي
class _AccountPickerBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<ChartAccountModel> onSelected;

  const _AccountPickerBottomSheet({required this.onSelected});

  @override
  ConsumerState<_AccountPickerBottomSheet> createState() =>
      _AccountPickerBottomSheetState();
}

class _AccountPickerBottomSheetState extends ConsumerState<_AccountPickerBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartAccountsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'اختر الحساب المالي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                ref.read(chartAccountsProvider.notifier).loadAccounts(search: val.trim());
              });
            },
            decoration: InputDecoration(
              hintText: 'بحث باسم الحساب أو رقمه...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: chartState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chartState.accounts.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حسابات مطابقة',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: chartState.accounts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final acc = chartState.accounts[idx];
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          acc.accName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          'رقم: ${acc.accNo}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        trailing: acc.balance != null
                            ? Text(
                                '${acc.balance!.toStringAsFixed(2)} ر.ي',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: (acc.balance ?? 0) >= 0
                                      ? const Color(0xFF2E7D32)
                                      : AppColors.error,
                                ),
                              )
                            : null,
                        onTap: () => widget.onSelected(acc),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
