import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/accounts_provider.dart';
import '../providers/currency_provider.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateMonthDay(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// شاشة كشف حساب مفصل (خيارات متقدمة)
class AccountStatementDetailScreen extends ConsumerStatefulWidget {
  const AccountStatementDetailScreen({super.key});

  @override
  ConsumerState<AccountStatementDetailScreen> createState() =>
      _AccountStatementDetailScreenState();
}

class _AccountStatementDetailScreenState
    extends ConsumerState<AccountStatementDetailScreen> {
  // تصفية حسب مستوى الحساب
  String _selectedType = 'chart'; // all, chart, group, sub, main, account
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
    setState(() {
      _isLoading = true;
    });

    final repo = ref.read(accountRepositoryProvider);

    try {
      final res = await repo.fetchDetailedStatement(
        type: _selectedType,
        id:
            _idController.text.trim().isNotEmpty
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
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);
    final data = _resultData['data'] as Map<String, dynamic>? ?? {};
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final transactions = (data['transactions'] as List? ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كشف حساب مفصل - خيارات متقدمة'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة وتصدير الكشف',
            onPressed:
                transactions.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'جاري إعداد التقرير المالي المفصل للطباعة والتصدير',
                            ),
                          ),
                        );
                      },
          ),
        ],
      ),
      body: Column(
        children: [
          // لوحة التصفية والخيارات المتقدمة
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خيارات التقرير المفصل',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // مستوى التقرير
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'مستوى التقرير',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('كافة الحسابات'),
                          ),
                          DropdownMenuItem(
                            value: 'chart',
                            child: Text('حساب مالي فردي'),
                          ),
                          DropdownMenuItem(
                            value: 'group',
                            child: Text('مجموعة حسابات'),
                          ),
                          DropdownMenuItem(
                            value: 'sub',
                            child: Text('حساب جزئي'),
                          ),
                          DropdownMenuItem(
                            value: 'main',
                            child: Text('حساب فرعي'),
                          ),
                          DropdownMenuItem(
                            value: 'account',
                            child: Text('قسم رئيسي'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedType = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // رقم/معرف الحساب Target ID
                    if (_selectedType != 'all')
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _idController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'رقم / معرف الحساب',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    // فلترة بالعملة
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int?>(
                        decoration: InputDecoration(
                          labelText: 'العملة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedCurrencyNo,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('جميع العملات'),
                          ),
                          ...currenciesState.currencies.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.curNo,
                              child: Text('${c.curName} (${c.code ?? ''})'),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCurrencyNo = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // نطاق التاريخ
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: true),
                        child: Text(
                          _fromDate != null
                              ? _formatDateMonthDay(_fromDate!)
                              : 'من تاريخ',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(isFrom: false),
                        child: Text(
                          _toDate != null
                              ? _formatDateMonthDay(_toDate!)
                              : 'إلى تاريخ',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchDetailedStatement,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(
                      _isLoading
                          ? 'جاري التحليل واستخراج البيان...'
                          : 'عرض التقرير المفصل',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // الملخص والإحصائيات
          if (summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'عدد الحركات',
                    '${summary['total_records'] ?? 0}',
                  ),
                  _buildStatItem(
                    'إجمالي المدين',
                    '${summary['total_debit'] ?? 0}',
                  ),
                  _buildStatItem(
                    'إجمالي الدائن',
                    '${summary['total_credit'] ?? 0}',
                  ),
                  _buildStatItem(
                    'صافي الحركة',
                    '${summary['net_movement'] ?? 0}',
                    isBold: true,
                  ),
                ],
              ),
            ),

          // جدول البيانات المفصلة
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'اضبط الخيارات واضغط "عرض التقرير المفصل" لاستخراج البيانات',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.surface,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'التاريخ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'بيان الحركة',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'مدين',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'دائن',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'الرصيد التراكمي',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows:
                                transactions.map<DataRow>((tx) {
                                  final item = tx as Map<String, dynamic>;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          item['date']?.toString() ?? '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item['description']?.toString() ??
                                              '-',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item['debit'] != null
                                              ? item['debit'].toString()
                                              : '-',
                                          style: const TextStyle(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item['credit'] != null
                                              ? item['credit'].toString()
                                              : '-',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item['balance'] != null
                                              ? item['balance'].toString()
                                              : '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {bool isBold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }
}
