import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/chart_account_model.dart';
import '../providers/accounts_provider.dart';

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateSlash(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// شاشة كشف حساب مالي - تصميم منظم وعصري
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

class _AccountStatementScreenState
    extends ConsumerState<AccountStatementScreen> {
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
    final double totalDebit = _statementData.transactions
        .fold(0, (sum, t) => sum + (t.debit ?? 0));
    final double totalCredit = _statementData.transactions
        .fold(0, (sum, t) => sum + (t.credit ?? 0));
    final double netBalance =
        _statementData.currentBalance ?? (totalDebit - totalCredit);
    final txCount = _statementData.transactions.length;

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
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'تحديث',
            onPressed: _loadStatement,
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── شريط الفلتر المدمج ───
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اختيار الحساب
                InkWell(
                  onTap: _showAccountPickerDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                          color: _selectedAccNo != null
                              ? AppColors.primary
                              : AppColors.textMuted,
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
                              fontWeight: _selectedAccNo != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedAccNo != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: _selectedAccNo != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // نطاق التاريخ
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: _fromDate != null
                            ? _formatDateSlash(_fromDate!)
                            : 'من تاريخ',
                        hasValue: _fromDate != null,
                        icon: Icons.calendar_today,
                        onTap: () => _pickDate(isFrom: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        label: _toDate != null
                            ? _formatDateSlash(_toDate!)
                            : 'إلى تاريخ',
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
          ),

          // ─── شريط ملخص الأرقام (يظهر عند اختيار الحساب) ───
          if (_selectedAccNo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              color: AppColors.background,
              child: Row(
                children: [
                  _buildSummaryChip(
                    label: 'إجمالي المدين',
                    value: totalDebit.toStringAsFixed(2),
                    color: const Color(0xFF1565C0),
                    icon: Icons.arrow_circle_up_outlined,
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryChip(
                    label: 'إجمالي الدائن',
                    value: totalCredit.toStringAsFixed(2),
                    color: const Color(0xFFE65100),
                    icon: Icons.arrow_circle_down_outlined,
                  ),
                  const SizedBox(width: 6),
                  _buildSummaryChip(
                    label: 'الرصيد',
                    value: netBalance.toStringAsFixed(2),
                    color: netBalance >= 0
                        ? const Color(0xFF2E7D32)
                        : AppColors.error,
                    icon: Icons.account_balance_outlined,
                    isBold: true,
                  ),
                  if (txCount > 0) ...[
                    const SizedBox(width: 6),
                    _buildSummaryChip(
                      label: 'عدد الحركات',
                      value: '$txCount',
                      color: const Color(0xFF6A1B9A),
                      icon: Icons.list_alt_outlined,
                    ),
                  ],
                ],
              ),
            ),

          // ─── قائمة الحركات ───
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
                    subtitle:
                        'لا توجد حركات مسجلة لهذا الحساب في الفترة المحددة',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    itemCount: _statementData.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _statementData.transactions[index];
                      final isDebit =
                          (tx.debit ?? 0) > 0;
                      final txColor = isDebit
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFE65100);
                      final txAmount = isDebit
                          ? tx.debit!
                          : (tx.credit ?? 0);
                      final balance = tx.balance ?? 0;

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
                              // أيقونة نوع الحركة
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: txColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isDebit
                                      ? Icons.arrow_circle_up_rounded
                                      : Icons.arrow_circle_down_rounded,
                                  color: txColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // البيان والتاريخ
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description ?? '-',
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
                                      tx.date ?? '-',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // المبلغ والرصيد
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isDebit ? '+' : '-'}${txAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: txColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
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
          color: hasValue
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: hasValue ? AppColors.primary : AppColors.textMuted,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    bool isBold = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w700,
                  color: color,
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

class _AccountPickerBottomSheetState
    extends ConsumerState<_AccountPickerBottomSheet> {
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
          // رأس القائمة
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

          // بحث
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
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

          // القائمة
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
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final acc = chartState.accounts[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
