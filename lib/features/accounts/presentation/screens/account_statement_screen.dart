import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/chart_account_model.dart';
import '../providers/accounts_provider.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateSlash(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// شاشة كشف حساب (مثل كشف حساب الموظفين والقصاصين)
class AccountStatementScreen extends ConsumerStatefulWidget {
  final int? initialAccNo;
  final String? initialAccName;

  const AccountStatementScreen({
    super.key,
    this.initialAccNo,
    this.initialAccName,
  });

  @override
  ConsumerState<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends ConsumerState<AccountStatementScreen> {
  int? _selectedAccNo;
  String _selectedAccName = '';

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _isLoading = false;
  AccountStatementData _statementData = const AccountStatementData();

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

    setState(() {
      _isLoading = true;
    });

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
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب كشف الحساب: $e'), backgroundColor: AppColors.error),
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
          });
          _loadStatement();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalDebit = _statementData.transactions.fold(0, (sum, t) => sum + (t.debit ?? 0));
    final double totalCredit = _statementData.transactions.fold(0, (sum, t) => sum + (t.credit ?? 0));
    final double netBalance = _statementData.currentBalance ?? (totalDebit - totalCredit);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كشف حساب مالي'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة الكشف',
            onPressed: _selectedAccNo == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('جاري إرسال كشف حساب $_selectedAccName للطباعة')),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatement,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط اختيار الحساب والتاريخ
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                // اختيار الحساب
                InkWell(
                  onTap: _showAccountPickerDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.background,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedAccNo != null
                                ? '[$_selectedAccNo] $_selectedAccName'
                                : 'اضغط لاختيار الحساب المالي المراد الكشف عنه...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _selectedAccNo != null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedAccNo != null ? Colors.black : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // أزرار اختيار التاريخ
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fromDate != null ? _formatDateSlash(_fromDate!) : 'من تاريخ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: false),
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          _toDate != null ? _formatDateSlash(_toDate!) : 'إلى تاريخ',
                        ),
                      ),
                    ),
                    if (_fromDate != null || _toDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.error),
                        onPressed: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                          });
                          _loadStatement();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          // بطاقات الملخص السريع
          if (_selectedAccNo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'إجمالي المدين',
                      '${totalDebit.toStringAsFixed(2)} ر.ي',
                      Colors.blue,
                      Icons.arrow_upward,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'إجمالي الدائن',
                      '${totalCredit.toStringAsFixed(2)} ر.ي',
                      Colors.orange,
                      Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'الرصيد الحالي',
                      '${netBalance.toStringAsFixed(2)} ر.ي',
                      netBalance >= 0 ? Colors.green : AppColors.error,
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
            ),

          // جدول العمليات والحركات
          Expanded(
            child: _selectedAccNo == null
                ? const Center(
                    child: Text(
                      'اختر حساباً مالياً للبدء بعرض كشف الحساب',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  )
                : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _statementData.transactions.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد حركات سجلت لهذا الحساب في الفترة المحددة',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppColors.surface),
                                columns: const [
                                  DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('البيان / الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('مدين (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('دائن (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _statementData.transactions.map((tx) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(tx.date ?? '-')),
                                      DataCell(Text(tx.description ?? '-')),
                                      DataCell(
                                        Text(
                                          tx.debit != null && tx.debit! > 0
                                              ? tx.debit!.toStringAsFixed(2)
                                              : '-',
                                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          tx.credit != null && tx.credit! > 0
                                              ? tx.credit!.toStringAsFixed(2)
                                              : '-',
                                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          tx.balance != null ? tx.balance!.toStringAsFixed(2) : '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: (tx.balance ?? 0) >= 0 ? Colors.green.shade800 : AppColors.error,
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

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// قائمة سفلية لاختيار الحساب المالي من بين الحسابات المحاسبية
class _AccountPickerBottomSheet extends ConsumerStatefulWidget {
  final ValueChanged<ChartAccountModel> onSelected;

  const _AccountPickerBottomSheet({required this.onSelected});

  @override
  ConsumerState<_AccountPickerBottomSheet> createState() => _AccountPickerBottomSheetState();
}

class _AccountPickerBottomSheetState extends ConsumerState<_AccountPickerBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartState = ref.watch(chartAccountsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'اختر الحساب المالي',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              ref.read(chartAccountsProvider.notifier).loadAccounts(search: val.trim());
            },
            decoration: InputDecoration(
              hintText: 'بحث باسم الحساب أو رقم الحساب...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: chartState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chartState.accounts.isEmpty
                    ? const Center(child: Text('لا توجد حسابات مطابقة'))
                    : ListView.separated(
                        itemCount: chartState.accounts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final acc = chartState.accounts[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surfaceSubtle,
                              child: const Icon(Icons.account_balance, color: AppColors.primary, size: 20),
                            ),
                            title: Text(acc.accName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('رقم الحساب: ${acc.accNo}'),
                            trailing: acc.balance != null
                                ? Text(
                                    '${acc.balance!.toStringAsFixed(2)} ر.ي',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
