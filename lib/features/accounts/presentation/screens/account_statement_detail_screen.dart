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
import '../providers/accounts_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/account_statement_detail_pdf_builder.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateShort(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// شاشة كشف حساب مفصل تحليلي - تصميم محكم ومنظم
class AccountStatementDetailScreen extends ConsumerStatefulWidget {
  const AccountStatementDetailScreen({super.key});

  @override
  ConsumerState<AccountStatementDetailScreen> createState() =>
      _AccountStatementDetailScreenState();
}

class _AccountStatementDetailScreenState
    extends ConsumerState<AccountStatementDetailScreen> {
  String _selectedType = 'chart';
  final TextEditingController _idController = TextEditingController();
  int? _selectedCurrencyNo;

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  Map<String, dynamic> _resultData = {};

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetailedStatement() async {
    setState(() => _isLoading = true);
    final repo = ref.read(accountRepositoryProvider);
    try {
      final res = await repo.fetchDetailedStatement(
        type: _selectedType,
        id: _idController.text.trim().isNotEmpty
            ? _idController.text.trim()
            : null,
        fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
        toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
        curNo: _selectedCurrencyNo,
      );
      setState(() {
        _resultData = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في استخراج الكشف المفصل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  static const Map<String, String> _typeLabels = {
    'all': 'كافة الحسابات',
    'chart': 'حساب مالي فردي',
    'group': 'مجموعة حسابات',
    'sub': 'حساب جزئي',
    'main': 'حساب فرعي',
    'account': 'قسم رئيسي',
  };

  // ─── مساعدات التقرير (ترويسة/نطاق/عملة) / Report helpers ──────────────────────

  /// هوية ترويسة التقرير من إعدادات التطبيق — تُقرأ عند الطباعة/التصدير.
  /// Report letterhead identity from app config, read imperatively for print/export.
  ReportLetterheadInfo _letterheadInfo() => ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

  /// وصف النطاق المحدد (المستوى + المعرف) لعرضه في الترويسة.
  /// Human-readable scope (level label + id) shown in the header.
  String _scopeLabel() {
    final level = _typeLabels[_selectedType] ?? _selectedType;
    final id = _idController.text.trim();
    return id.isNotEmpty ? '$level — الرقم: $id' : level;
  }

  /// اسم العملة المحددة إن وُجدت / selected currency label, if any.
  String? _currencyLabel() {
    if (_selectedCurrencyNo == null) return null;
    final list = ref.read(currenciesProvider).currencies;
    for (final c in list) {
      if (c.curNo == _selectedCurrencyNo) {
        return '${c.curName}${c.code != null ? ' (${c.code})' : ''}';
      }
    }
    return null;
  }

  Map<String, dynamic> get _summary =>
      (_resultData['data'] as Map<String, dynamic>?)?['summary']
          as Map<String, dynamic>? ??
      {};

  List<dynamic> get _transactions =>
      (_resultData['data'] as Map<String, dynamic>?)?['transactions']
          as List? ??
      const [];

  /// يبني الـ PDF من نفس بيانات الشاشة — يطابق الاستعراض تماماً.
  /// Builds the PDF from the exact on-screen data, so print equals the view.
  Future<Uint8List> _buildPdf() => buildAccountStatementDetailPdf(
        letterhead: _letterheadInfo(),
        scopeLabel: _scopeLabel(),
        summary: _summary,
        transactions: _transactions,
        currency: _currencyLabel(),
        fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
        toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
      );

  Future<void> _printReport() async {
    final bytes = await _buildPdf();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _exportPdf() async {
    final bytes = await _buildPdf();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'account-statement-detail.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);
    // تراقب هوية الشركة من الإعدادات لتنعكس فوراً على ترويسة الورقة
    // Watches the configured identity so a branding edit repaints the sheet header.
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider.select((s) => s.config)),
    );
    final data = _resultData['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final transactions = (data['transactions'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'كشف حساب تحليلي مفصل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          if (transactions.isNotEmpty) ...[
            // طباعة — محمية بصلاحية كشف الحساب (كبقية التقارير)
            PermissionGate(
              code: Perm.accountsStatement,
              child: IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                tooltip: 'طباعة',
                onPressed: _printReport,
              ),
            ),
            // تصدير PDF — محمي بصلاحية كشف الحساب
            PermissionGate(
              code: Perm.accountsStatement,
              child: IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                tooltip: 'تصدير PDF',
                onPressed: _exportPdf,
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ─── لوحة الإعدادات والخيارات ───
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إعدادات الكشف التحليلي',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),

                // مستوى التقرير + الرقم المحدد
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildDropdownField<String>(
                        label: 'مستوى التقرير',
                        value: _selectedType,
                        items: _typeLabels.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(
                                  e.value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                    ),
                    if (_selectedType != 'all') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: _buildTextField(
                          controller: _idController,
                          label: 'رقم / معرف الحساب',
                          keyboardType: TextInputType.number,
                          icon: Icons.tag_rounded,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // العملة + التاريخ
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildDropdownField<int?>(
                        label: 'العملة',
                        value: _selectedCurrencyNo,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'جميع العملات',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...currenciesState.currencies.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.curNo,
                              child: Text(
                                '${c.curName} (${c.code ?? ''})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedCurrencyNo = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildSmallDateButton(
                        label: _fromDate != null
                            ? _formatDateShort(_fromDate!)
                            : 'من',
                        hasValue: _fromDate != null,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: _buildSmallDateButton(
                        label: _toDate != null
                            ? _formatDateShort(_toDate!)
                            : 'إلى',
                        hasValue: _toDate != null,
                        onTap: () => _pickDate(isFrom: false),
                      ),
                    ),
                    if (_fromDate != null || _toDate != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => setState(() {
                          _fromDate = null;
                          _toDate = null;
                        }),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.clear,
                            color: AppColors.error,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // زر الاستخراج
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchDetailedStatement,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.analytics_outlined, size: 16),
                    label: Text(
                      _isLoading
                          ? 'جاري الاستخراج...'
                          : 'عرض الكشف التحليلي',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── ملخص النتائج ───
          if (summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Row(
                children: [
                  _buildSummaryPill(
                    '${summary['total_records'] ?? 0}',
                    'حركة',
                    const Color(0xFF6A1B9A),
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryPill(
                    '${summary['total_debit'] ?? 0}',
                    'مدين',
                    const Color(0xFF1565C0),
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryPill(
                    '${summary['total_credit'] ?? 0}',
                    'دائن',
                    const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryPill(
                    '${summary['net_movement'] ?? 0}',
                    'صافي',
                    const Color(0xFF2E7D32),
                    isBold: true,
                  ),
                ],
              ),
            ),

          // ─── قائمة النتائج — كورقة تقرير A4 موحّدة (ترويسة + توقيعات) ───
          // Results shown as a unified A4 sheet: letterhead band + title + scope
          // meta on top, the transactions in the scrollable body, signatures pinned
          // to the page bottom — mirroring the exported/printed PDF.
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? _buildEmptyState()
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3,
                    // تمرير طبيعي للصفحة كاملة — بلا A4 مقصوص على الشاشة
                    // Natural full-page scroll — no clipped on-screen A4.
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ReportA4Sheet(
                        orientation: ReportSheetOrientation.portrait,
                        header: ReportLetterheadBranding(info: letterhead),
                        title: const Text(
                          'كشف حساب تحليلي مفصل',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        meta: _buildScopeMetaBar(),
                        body: _buildTransactionsList(transactions),
                        footer: const ReportSignatureFooter(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// شريط بيانات النطاق/الفترة أعلى المتن داخل الورقة — يطابق Meta في الـ PDF.
  /// Scope/period meta band at the top of the sheet body — matches the PDF meta.
  Widget _buildScopeMetaBar() {
    final rangeLabel = _fromDate != null && _toDate != null
        ? 'من ${_formatDateDash(_fromDate!)} إلى ${_formatDateDash(_toDate!)}'
        : 'كل الحركات (بدون تحديد فترة)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'النطاق: ${_scopeLabel()}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            rangeLabel,
            style: const TextStyle(fontSize: 10.5, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// قائمة حركات الكشف التحليلي داخل متن الورقة / The transactions list, sheet body.
  Widget _buildTransactionsList(List<dynamic> transactions) {
    // القائمة داخل متن تقرير ذي ارتفاع طبيعي غير محدود → يجب إغلاق تمريرها الداخلي
    // وتمددها بحجم محتواها ليتم تمرير الصفحة كاملة من الخارج لا الجدول وحده.
    // The list sits inside the report sheet whose height is naturally unbounded, so it
    // must shrink-wrap and disable its own scroll — the whole page scrolls, not just rows.
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final item = transactions[index] as Map<String, dynamic>;
        final debit = (item['debit'] as num?)?.toDouble() ?? 0;
        final credit = (item['credit'] as num?)?.toDouble() ?? 0;
        final balance = (item['balance'] as num?)?.toDouble() ?? 0;
        final isDebit = debit > 0;
        final color =
            isDebit ? const Color(0xFF1565C0) : const Color(0xFFE65100);

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isDebit
                        ? Icons.arrow_circle_up_rounded
                        : Icons.arrow_circle_down_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description']?.toString() ?? '-',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['date']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isDebit
                          ? '+${debit.toStringAsFixed(2)}'
                          : '-${credit.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      'رصيد: ${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: balance >= 0
                            ? const Color(0xFF2E7D32)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        isDense: true,
      ),
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required TextInputType keyboardType,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        isDense: true,
      ),
    );
  }

  Widget _buildSmallDateButton({
    required String label,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(9),
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
              Icons.calendar_today_outlined,
              size: 12,
              color: hasValue ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: hasValue ? AppColors.primary : AppColors.textMuted,
                fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(
    String value,
    String label,
    Color color, {
    bool isBold = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.query_stats_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اضبط الخيارات أعلاه',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'اختر مستوى التقرير والفترة الزمنية ثم اضغط "عرض الكشف التحليلي"',
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
