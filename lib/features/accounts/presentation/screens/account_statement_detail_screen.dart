import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';
import '../providers/currency_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);
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
          if (transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'طباعة وتصدير',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('جاري إعداد التقرير المالي المفصل للطباعة'),
                  ),
                );
              },
            ),
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

          // ─── قائمة النتائج ───
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : transactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item =
                          transactions[index] as Map<String, dynamic>;
                      final debit = (item['debit'] as num?)?.toDouble() ?? 0;
                      final credit = (item['credit'] as num?)?.toDouble() ?? 0;
                      final balance =
                          (item['balance'] as num?)?.toDouble() ?? 0;
                      final isDebit = debit > 0;
                      final color = isDebit
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFE65100);

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                  ),
          ),
        ],
      ),
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
