import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../accounts/data/models/chart_account_model.dart';
import '../../../accounts/presentation/utils/account_statement_pdf_builder.dart';
import '../../../accounts/presentation/utils/statement_date_parser.dart';
import '../../../accounts/presentation/widgets/account_statement_report_footer.dart';
import '../../../accounts/presentation/widgets/account_statement_report_table.dart';
import '../providers/my_statement_provider.dart';

String _formatDateSlash(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// شاشة كشف حسابي المالي — نسخة مبسطة بدون منتقي الحساب
/// Personal financial statement screen — simplified without the account picker.
///
/// تفتح مباشرة كشف حساب الموظف الحالي (ACC_NO من الجلسة) وتُخفي قائمة اختيار الحساب
/// so the user can only see their own account.
class MyFinancialStatementScreen extends ConsumerStatefulWidget {
  const MyFinancialStatementScreen({super.key});

  @override
  ConsumerState<MyFinancialStatementScreen> createState() =>
      _MyFinancialStatementScreenState();
}

class _MyFinancialStatementScreenState
    extends ConsumerState<MyFinancialStatementScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _filtersVisible = true;

  @override
  void initState() {
    super.initState();
    // المزود غير `autoDispose` و`build()` لا يُعاد، فكشف آخر مستخدم على نفس
    // الجهاز كان يُرسم قبل وصول رد الطلب الجديد. التصفير ثم الجلب يضمن أن ما
    // يُعرض يخص من سجّل دخوله الآن.
    // The provider is not autoDispose and `build()` never re-runs, so the last
    // user's statement on this device was drawn before the fresh reply landed.
    // Reset then load so what is displayed belongs to whoever signed in now.
    Future.microtask(() {
      final notifier = ref.read(myFinancialStatementProvider.notifier);
      notifier.resetTransient();
      notifier.load();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
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
      ref.read(myFinancialStatementProvider.notifier).load(
            from: _fromDate,
            to: _toDate,
          );
    }
  }

  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

  Future<void> _printReport(AccountStatementData statementData) async {
    final bytes = await buildAccountStatementPdf(
      letterhead: _letterheadInfo(),
      account: null,
      statement: statementData,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf(AccountStatementData statementData) async {
    final bytes = await buildAccountStatementPdf(
      letterhead: _letterheadInfo(),
      account: null,
      statement: statementData,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'my-financial-statement.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myFinancialStatementProvider);
    final statementData =
        state.data is AccountStatementData ? state.data as AccountStatementData : const AccountStatementData();
    final hasData = !state.isLoading &&
        state.error == null &&
        statementData.transactions.isNotEmpty;

    // تراقب هوية الشركة لترويسة التقرير
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider.select((s) => s.config)),
    );

    final fromDateLabel = _fromDate != null
        ? _formatDateSlash(_fromDate!)
        : (statementData.fromDate ?? 'من تاريخ');
    final toDateLabel = _toDate != null
        ? _formatDateSlash(_toDate!)
        : (statementData.toDate ?? 'إلى تاريخ');

    // بيانات الحساب من الاستجابة (لا يحتاج المستخدم لمنتقي)
    final accNo = statementData.account?['acc_no']?.toString() ?? '';
    final accName = statementData.account?['acc_name']?.toString() ?? 'حسابي المالي';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'كشف حسابي المالي',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
                _filtersVisible ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 20),
            tooltip: _filtersVisible ? 'إخفاء الفلترة' : 'إظهار الفلترة',
            onPressed: () =>
                setState(() => _filtersVisible = !_filtersVisible),
          ),
          if (hasData) ...[
            PermissionGate(
              code: Perm.accountsPrint,
              child: IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                tooltip: 'طباعة',
                onPressed: () => _printReport(statementData),
              ),
            ),
            PermissionGate(
              code: Perm.accountsExport,
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                tooltip: 'تصدير PDF',
                onPressed: () => _exportPdf(statementData),
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'تحديث',
            onPressed: () => ref
                .read(myFinancialStatementProvider.notifier)
                .load(from: _fromDate, to: _toDate),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtersVisible)
            _buildFilterBar(fromDateLabel, toDateLabel),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildErrorState(state.error!)
                    : statementData.transactions.isEmpty
                        ? _buildEmptyState()
                        : ReportZoomView(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 5),
                              child: ReportA4Sheet(
                                orientation:
                                    ReportSheetOrientation.portrait,
                                maxPageWidth: 900,
                                header: AccountStatementLetterhead(
                                  letterhead: letterhead,
                                  accName: accName,
                                  accNo: int.tryParse(accNo) ?? 0,
                                  currency: statementData.currency,
                                  fromDate: fromDateLabel,
                                  toDate: toDateLabel,
                                ),
                                body: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      AccountStatementReportTable(
                                        transactions:
                                            statementData.transactions,
                                        openingBalance:
                                            statementData.openingBalance ?? 0,
                                        finalBalance:
                                            statementData.finalBalance ?? 0,
                                        totalDebit:
                                            statementData.totalDebit ?? 0,
                                        totalCredit:
                                            statementData.totalCredit ?? 0,
                                      ),
                                      AccountStatementReportFooter(
                                        openingBalance:
                                            statementData.openingBalance ?? 0,
                                        totalDebit:
                                            statementData.totalDebit ?? 0,
                                        totalCredit:
                                            statementData.totalCredit ?? 0,
                                        finalBalance:
                                            statementData.finalBalance ?? 0,
                                      ),
                                    ],
                                  ),
                                ),
                                footer: const ReportSignatureFooter(),
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
          // عرض الحساب بشكل ثابت بدون إمكانية التغيير (لا يوجد منتقي)
          // Display the account as a fixed label — no picker, no change option.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withValues(alpha: 0.04),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    color: Color(0xFF1E4D7B), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'كشف حسابي المالي — الموظف الحالي',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
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
                    ref
                        .read(myFinancialStatementProvider.notifier)
                        .load();
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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  hasValue ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: hasValue
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: hasValue
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(myFinancialStatementProvider.notifier)
                  .load(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              child: Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد حركات',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'لا توجد حركات مسجلة في الفترة المحددة',
              textAlign: TextAlign.center,
              style: TextStyle(
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
