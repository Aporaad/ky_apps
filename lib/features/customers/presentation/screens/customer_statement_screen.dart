import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_statement_model.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_picker_screen.dart';

// ================================================================
// شاشة اختيار العميل لكشف الحساب
// ================================================================
class CustomerStatementPickerScreen extends ConsumerStatefulWidget {
  const CustomerStatementPickerScreen({super.key});

  @override
  ConsumerState<CustomerStatementPickerScreen> createState() =>
      _CustomerStatementPickerScreenState();
}

class _CustomerStatementPickerScreenState
    extends ConsumerState<CustomerStatementPickerScreen> {
  Future<void> _pickCustomer() async {
    final picked = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder:
            (_) => const CustomerPickerScreen(
              title: 'اختر العميل لكشف الحساب',
              subtitle: 'ابحث بالاسم أو الرقم أو رقم الهاتف لعرض كشف الحساب',
              icon: Icons.account_balance_wallet_rounded,
            ),
      ),
    );
    if (picked != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => CustomerStatementScreen(
                custNo: picked.custNo,
                custName: picked.custName,
                accNo: picked.accNo,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF6B2D1B),
              size: 22,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كشف حساب عميل',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'عرض كشف الحساب بالنموذج المعتمد',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B2D1B).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: Color(0xFF6B2D1B),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'عرض كشف حساب العميل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'حدد العميل لعرض تقرير كشف حسابه بالتنسيق الرسمي لشركة الكبودي للخياطة الرجالية مع إمكانية التصفية بالتواريخ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _pickCustomer,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text(
                      'اختيار العميل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B2D1B),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// شاشة عرض كشف الحساب بالتنسيق المعتمد والتجاوب الكامل
// ================================================================
class CustomerStatementScreen extends ConsumerStatefulWidget {
  final int custNo;
  final String? custName;
  final int? accNo;

  const CustomerStatementScreen({
    super.key,
    required this.custNo,
    this.custName,
    this.accNo,
  });

  @override
  ConsumerState<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState
    extends ConsumerState<CustomerStatementScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showFilterPanel = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadData();
    });
  }

  void _loadData() {
    final fromStr =
        _fromDate != null
            ? '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}'
            : null;
    final toStr =
        _toDate != null
            ? '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}'
            : null;

    ref
        .read(customerStatementProvider.notifier)
        .loadStatement(widget.custNo, fromDate: fromStr, toDate: toStr);
  }

  Future<void> _selectDate(bool isFrom) async {
    final initial =
        isFrom
            ? (_fromDate ?? DateTime(2026, 1, 1))
            : (_toDate ?? DateTime(2026, 12, 31));
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

  void _setQuickRange(String type) {
    final now = DateTime(2026, 9, 8);
    setState(() {
      if (type == 'all') {
        _fromDate = null;
        _toDate = null;
      } else if (type == 'month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month + 1, 0);
      } else if (type == 'year') {
        _fromDate = DateTime(now.year, 1, 1);
        _toDate = DateTime(now.year, 12, 31);
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerStatementProvider);

    final rawName =
        widget.custName ??
        (state.customer != null
            ? (state.customer!['CUST_NAME'] ??
                    state.customer!['cust_name'] ??
                    '')
                .toString()
            : 'عميل رقم ${widget.custNo}');
    final displayName = ArabicEncodingUtils.fix(rawName);

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
            const Text(
              'كشف حساب عميل',
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
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // شريط فلترة التواريخ
          if (_showFilterPanel) _buildDateFilterBar(),

          // محتوى كشف الحساب
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
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
                  'الكل',
                  _fromDate == null && _toDate == null,
                  () => _setQuickRange('all'),
                ),
                const SizedBox(width: 6),
                _quickFilterChip(
                  'الشهر الحالي',
                  false,
                  () => _setQuickRange('month'),
                ),
                const SizedBox(width: 6),
                _quickFilterChip(
                  'العام الحالي',
                  false,
                  () => _setQuickRange('year'),
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
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final text =
        date != null
            ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
            : 'غير محدد';

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
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.textMuted,
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
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CustomerStatementState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B2D1B)),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل كشف الحساب...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: AppColors.error,
              ),
              const SizedBox(height: 14),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
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

    // استخراج بيانات الترويسة وتصحيح ترميزها
    final custData = state.customer ?? {};
    final rawName =
        widget.custName ??
        (custData['CUST_NAME'] ?? custData['cust_name'] ?? 'عميل غير محدد')
            .toString();
    final displayName = ArabicEncodingUtils.fix(rawName);

    final displayCode =
        (custData['CUST_NO'] ?? custData['cust_no'] ?? widget.custNo)
            .toString();
    final displayAccNo =
        (custData['ACC_NO'] ?? custData['acc_no'] ?? widget.accNo ?? '12310000')
            .toString();

    final summary = state.summary ?? {};
    final fromDate =
        (summary['from_date'] ??
                (_fromDate != null
                    ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                    : '16/03/2026'))
            .toString();
    final toDate =
        (summary['to_date'] ??
                (_toDate != null
                    ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                    : '07/06/2026'))
            .toString();
    final currency = (summary['currency'] ?? 'يمني YR').toString();
    final accountTitle =
        (summary['account_title'] ?? '$displayAccNo عملاء الكبودي للخياطة')
            .toString();

    final totalDebit = (summary['total_debit'] ?? 0.0) as num;
    final totalCredit = (summary['total_credit'] ?? 0.0) as num;
    final openingBalance = (summary['opening_balance'] ?? 0.0) as num;
    final finalBalance = (summary['final_balance'] ?? 0.0) as num;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 980),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD0D5DD), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ترويسة كشف الحساب الرسمية المتجاوبة
              _buildOfficialHeader(context),
              const SizedBox(height: 14),

              // 2. شريط بيانات العميل والحساب والتواريخ
              _buildCustomerMetaBar(
                customerName: displayName,
                customerCode: displayCode,
                currency: currency,
                accountTitle: accountTitle,
                fromDate: fromDate,
                toDate: toDate,
              ),
              const SizedBox(height: 12),

              // 3. جدول كشف الحساب مع شريط التمرير الأفقي لمنع أي تجاوز
              _buildStatementTableLayout(
                rows: state.rows,
                totalDebit: totalDebit.toDouble(),
                totalCredit: totalCredit.toDouble(),
                openingBalance: openingBalance.toDouble(),
                finalBalance: finalBalance.toDouble(),
              ),

              const SizedBox(height: 16),

              // 4. ملخص الأرصدة أسفل الجدول (الرصيد الافتتاحي والنهائي)
              _buildBottomBalanceSummary(
                openingBalance: openingBalance.toDouble(),
                finalBalance: finalBalance.toDouble(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // الترويسة الرسمية المتجاوبة تماماً مع مختلف أحجام الشاشات
  // -------------------------------------------------------------
  Widget _buildOfficialHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // اسم الشركة بالعربي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Al-Kaboudy',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7A4B29),
                        ),
                      ),
                      Text(
                        'الكبـودي',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4A1A0B),
                        ),
                      ),
                      const Text(
                        'لـلـخـيـاطـة الـرجـالـيـة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B2D1B),
                        ),
                      ),
                    ],
                  ),
                  // الشعار الهندسي K.Y
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFB8860B).withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFFFF9EE),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond_outlined,
                          size: 22,
                          color: Color(0xFF8B4513),
                        ),
                        Text(
                          'K.Y',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5A1E14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // البانر البني المتجاوب
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1208),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Column(
                  children: [
                    Text(
                      'صنعاء - خط المطار - الجراف - جوار بيت الشيخ الشايف',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '780 154 000 - 780 164 000 ✆',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFE082),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // عرض الشاشات العريضة (Desktop / Tablet)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // اليمين: عنوان الشركة والشعار النصي
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Al-Kaboudy',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A4B29),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'الكبـودي',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4A1A0B),
                    ),
                  ),
                  const Text(
                    'لـلـخـيـاطـة الـرجـالـيـة',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B2D1B),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // الوسط: الشعار الهندسي K.Y
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFFFF9EE),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.diamond_outlined,
                        size: 26,
                        color: Color(0xFF8B4513),
                      ),
                      Text(
                        'K.Y',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF5A1E14),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // اليسار: البانر البني
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A1208),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF8B3A2B), width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'صنعاء - خط المطار - الجراف - جوار بيت الشيخ الشايف',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '780 154 000 - 780 164 000 ✆',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFE082),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // شريط بيانات العميل والحساب
  // -------------------------------------------------------------
  Widget _buildCustomerMetaBar({
    required String customerName,
    required String customerCode,
    required String currency,
    required String accountTitle,
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
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // اليمين: كشف حساب عميل + الاسم + الرقم
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'كشف حساب عميل  ',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Flexible(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                customerCode,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626), // أحمر مطابق للصورة
                ),
              ),
            ],
          ),

          // العملة
          Text(
            currency,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),

          // رقم واسم الحساب
          Text(
            ArabicEncodingUtils.fix(accountTitle),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),

          // نطاق التاريخ
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'من تاريخ  ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                fromDate,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'إلى تاريخ  ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                toDate,
                style: const TextStyle(
                  fontSize: 12.5,
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
  // جدول كشف الحساب
  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // جدول كشف الحساب المتجاوب بالكامل مع أبعاد الشاشة
  // -------------------------------------------------------------
  Widget _buildStatementTableLayout({
    required List<CustomerStatementModel> rows,
    required double totalDebit,
    required double totalCredit,
    required double openingBalance,
    required double finalBalance,
  }) {
    const borderColor = Color(0xFF4B5563);
    const headerBgColor = Color(0xFFD4A853);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 650;
        final isVeryCompact = screenWidth < 450;

        final headerFontSize = isVeryCompact ? 10.0 : (isCompact ? 11.5 : 13.0);
        final dataFontSize = isVeryCompact ? 9.5 : (isCompact ? 11.0 : 12.0);
        final cellVPad = isVeryCompact ? 4.0 : (isCompact ? 5.0 : 6.5);
        final cellHPad = isVeryCompact ? 1.5 : (isCompact ? 3.0 : 5.0);

        return Table(
          border: TableBorder.all(
            color: borderColor,
            width: 1,
            style: BorderStyle.solid,
          ),
          columnWidths: const {
            0: FlexColumnWidth(0.9),  // السند
            1: FlexColumnWidth(1.1),  // النوع
            2: FlexColumnWidth(1.2),  // تأريخه
            3: FlexColumnWidth(2.8),  // البيان
            4: FlexColumnWidth(1.35), // مدين
            5: FlexColumnWidth(1.35), // دائن
            6: FlexColumnWidth(1.4),  // الرصيد
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // 1. رأس الجدول
            TableRow(
              decoration: const BoxDecoration(color: headerBgColor),
              children: [
                _tableHeaderCell('السند', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('النوع', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('تأريخه', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('البيان', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('مدين', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('دائن', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableHeaderCell('الرصيد', fontSize: headerFontSize, vPad: cellVPad, hPad: cellHPad),
              ],
            ),

            // 2. سطر الرصيد الافتتاحي
            TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell(
                  'رصيد افتتاحي',
                  isCenter: true,
                  textColor: const Color(0xFF0369A1),
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                ),
                _tableDataCell(
                  _formatAmount(openingBalance),
                  isCenter: true,
                  textColor: const Color(0xFFDC2626),
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  '0',
                  isCenter: true,
                  textColor: const Color(0xFFDC2626),
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                ),
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
              ],
            ),

            // 3. أسطر الحركات
            ...rows.map((row) {
              final debitVal =
                  row.debit ?? ((row.entryMnt ?? 0) > 0 ? row.entryMnt! : 0.0);
              final creditVal =
                  row.credit ??
                  ((row.entryMnt ?? 0) < 0 ? (row.entryMnt!).abs() : 0.0);
              final balVal = row.balanceS ?? 0.0;

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
                    _formatAmount(debitVal),
                    isCenter: true,
                    fontSize: dataFontSize,
                    vPad: cellVPad,
                    hPad: cellHPad,
                    fitBox: true,
                  ),
                  _tableDataCell(
                    _formatAmount(creditVal),
                    isCenter: true,
                    fontSize: dataFontSize,
                    vPad: cellVPad,
                    hPad: cellHPad,
                    fitBox: true,
                  ),
                  _tableDataCell(
                    _formatAmount(balVal),
                    isCenter: true,
                    isBold: true,
                    fontSize: dataFontSize,
                    vPad: cellVPad,
                    hPad: cellHPad,
                    fitBox: true,
                  ),
                ],
              );
            }),

            // 4. سطر إجمالي العمليات
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
              children: [
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell('', isCenter: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
                _tableDataCell('اجمالي العمليات', isCenter: true, isBold: true, fontSize: dataFontSize, vPad: cellVPad, hPad: cellHPad),
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
                  totalCredit > 0 ? '${_formatAmount(totalCredit)}-' : '0',
                  isCenter: true,
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
                _tableDataCell(
                  _formatAmount(finalBalance),
                  isCenter: true,
                  isBold: true,
                  fontSize: dataFontSize,
                  vPad: cellVPad,
                  hPad: cellHPad,
                  fitBox: true,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // صناديق الملخص أسفل الجدول
  // -------------------------------------------------------------
  Widget _buildBottomBalanceSummary({
    required double openingBalance,
    required double finalBalance,
  }) {
    const borderColor = Color(0xFF4B5563);
    const goldBgColor = Color(0xFFD4A853);

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            // سطر الرصيد الافتتاحي
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'الرصيد الافتتاحي',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 32, color: borderColor),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatAmount(openingBalance),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // سطر الرصيد النهائي
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    color: goldBgColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'الرصيد النهائي',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 32, color: borderColor),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _formatAmount(finalBalance),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFDC2626), // أحمر بارز
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(
    String text, {
    double fontSize = 13,
    double vPad = 7,
    double hPad = 4,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _tableDataCell(
    String text, {
    bool isCenter = true,
    Color? textColor,
    bool isBold = false,
    double fontSize = 12,
    double vPad = 6,
    double hPad = 6,
    bool fitBox = false,
  }) {
    Widget content = Text(
      text,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: textColor ?? Colors.black87,
      ),
    );

    if (fitBox) {
      content = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: isCenter ? Alignment.center : Alignment.centerRight,
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
      child: content,
    );
  }

  static String _formatAmount(double? amount) {
    if (amount == null || amount == 0) return '0';

    final isNegative = amount < 0;
    final absVal = amount.abs();

    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write(',');
      }
    }
    final formattedInt = buffer.toString().split('').reversed.join('');
    final res =
        decimalPart == '00' ? formattedInt : '$formattedInt.$decimalPart';
    return isNegative ? '-$res' : res;
  }
}
