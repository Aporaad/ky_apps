import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_tree_flatten.dart' show formatTreeAmount;

/// شاشة تعديل حساب مالي — تُحمّل قيمته الحالية ثم تحرّر حقول CHART_ACC الموجودة.
/// Edit screen for one financial account. It fetches the current row first and
/// pre-fills every field: the previous version left them blank, so a save wrote an
/// empty name/limit over real data unless the user re-typed everything.
///
/// تغيير الأب مقتصر على المجموعة داخل نفس الحساب الجزئي: رقم الحساب مبني على بادئة
/// جزئه (أول ثلاثة أرقام)، فنقله لجزء آخر يعني إعادة ترقيم يكسر مراجع ENTRY_SUB
/// القائمة عليها.
/// Re-parenting is limited to another group inside the same partial account: the
/// account number embeds the part prefix, so moving it across parts means renumbering
/// and every ENTRY_SUB reference would break.
class EditAccountScreen extends ConsumerStatefulWidget {
  final int accNo;
  final String accName;

  const EditAccountScreen({
    super.key,
    required this.accNo,
    required this.accName,
  });

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _limitedBalanceController;
  late final TextEditingController _seqController;

  bool _isStopped = false;
  bool _isSubmitting = false;
  bool _isLoadingDetail = true;
  String? _loadError;

  DateTime? _accDate;
  int? _accPart;
  int? _groupId;
  bool _directUnderPart = false;

  /// عملة الحساب — مشتقّة من الخانة الرابعة من رقمه، للقراءة فقط.
  /// The account's currency, read from the 4th digit of its number. Display-only:
  /// editing it would mean renumbering the account, which breaks ENTRY_SUB.
  int? _curNo;

  /// الرصيد المحسوب من الحركات — يُعرض للاسترشاد فقط ولا يُحرَّر يدوياً.
  double? _computedBalance;
  double? _debit;
  double? _credit;
  int? _movements;
  String? _parentPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accName);
    _balanceController = TextEditingController();
    _limitedBalanceController = TextEditingController();
    _seqController = TextEditingController();
    _loadDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitedBalanceController.dispose();
    _seqController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final repo = ref.read(accountRepositoryProvider);
    try {
      final detail = await repo.fetchChartAccountDetail(widget.accNo);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _isLoadingDetail = false;
          _loadError = 'تعذّر جلب بيانات الحساب الحالية';
        });
        return;
      }
      dynamic pick(String lower, [String? upper]) =>
          detail[lower] ?? detail[upper ?? lower.toUpperCase()];

      final stopping = pick('stopping_acc');
      final accDate = pick('acc_date')?.toString();
      final limited = pick('limited_balance');
      final balance = pick('balance');

      setState(() {
        _isLoadingDetail = false;
        _nameController.text = (pick('acc_name')?.toString() ?? widget.accName);
        final storedBalance = balance is num ? balance.toDouble() : null;
        _balanceController.text = (storedBalance == null || storedBalance == 0)
            ? ''
            : _trimNumber(storedBalance);
        _limitedBalanceController.text = limited == null
            ? ''
            : _trimNumber((limited as num).toDouble());
        _seqController.text = pick('seq')?.toString() ?? '';
        _isStopped = stopping != null && stopping != 0;
        _groupId = pick('group_id') == null ? null : (pick('group_id') as num).toInt();
        _directUnderPart = _groupId == null;
        _accPart = pick('acc_part') == null ? null : (pick('acc_part') as num).toInt();
        //_curNo من الخادم؛ احتياطٌ محلي من الرقم نفسه إن وصل مصدرٌ أقدم بلا cur_no.
        _curNo =
            pick('cur_no') == null
                ? _currencyFromNumber(widget.accNo)
                : (pick('cur_no') as num).toInt();
        _parentPath = pick('parent_path')?.toString();
        _computedBalance = pick('computed_balance') == null
            ? null
            : (pick('computed_balance') as num).toDouble();
        _debit = pick('debit') == null ? null : (pick('debit') as num).toDouble();
        _credit = pick('credit') == null ? null : (pick('credit') as num).toDouble();
        _movements = pick('movements') == null
            ? null
            : (pick('movements') as num).toInt();
        if (accDate != null && accDate.length >= 10) {
          _accDate = DateTime.tryParse(accDate.substring(0, 10));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetail = false;
        _loadError = '$e';
      });
    }
  }

  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// اشتقاق العملة من رقم الحساب (الخانة الرابعة من اليسار) — احتياط عند غياب cur_no.
  /// Positional read of the account's own number; a fallback, never a new numbering rule.
  static int? _currencyFromNumber(int accNo) {
    final digits = accNo.toString();
    if (digits.length < 4) return null;
    final cur = int.tryParse(digits[3]);
    return (cur != null && cur > 0) ? cur : null;
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(accountRepositoryProvider);

    final data = <String, dynamic>{
      'acc_name': _nameController.text.trim(),
      'stopping_acc': _isStopped ? 1 : 0,
      if (_seqController.text.trim().isNotEmpty)
        'seq': int.tryParse(_seqController.text.trim()),
      if (_accDate != null) 'acc_date': _isoDate(_accDate!),
      if (_limitedBalanceController.text.trim().isNotEmpty)
        'limited_balance': double.tryParse(_limitedBalanceController.text.trim()),
      if (_balanceController.text.trim().isNotEmpty)
        'balance': double.tryParse(_balanceController.text.trim()),
      // المجموعة تُرسل دائماً: التغيير إلى مجموعة أخرى أو إلى «مباشر» (null)
      'group_id': _directUnderPart ? null : _groupId,
    };

    final res = await repo.updateChartAccount(widget.accNo, data);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      // refreshNode وحده لا يكفي: الاسم الجديد قد يغيّر ترتيب العقدة في الهيكل.
      ref.read(accountTreeProvider.notifier).loadTree(keepExpansion: true);
      ref.read(chartAccountsProvider.notifier).loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message.isEmpty ? 'تم تعديل الحساب بنجاح' : res.message,
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickAccDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _accDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _accDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final wide = !Responsive.isMobile(context);
    final groupsAsync = ref.watch(parentAccSubGroupProvider(_accPart));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'تعديل الحساب #${widget.accNo}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 880 : 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _identityCard(),
                        const SizedBox(height: 12),
                        _computedBalancesCard(),
                        if (_loadError != null) ...[
                          const SizedBox(height: 12),
                          _warningBar(_loadError!),
                        ],
                        const SizedBox(height: 12),
                        _dataCard(),
                        const SizedBox(height: 12),
                        _parentCard(groupsAsync),
                        const SizedBox(height: 12),
                        _statusCard(),
                        const SizedBox(height: 88),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _stickyActions(),
    );
  }

  Widget _identityCard() => _SectionCard(
    title: 'معرّف الحساب',
    icon: Icons.fingerprint_rounded,
    iconColor: AppColors.primary,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#${widget.accNo}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _parentPath ?? '',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  /// الرصيد المحسوب من ENTRY_SUB للقراءة فقط — عمود BALANCE المخزّن ليس حقيقة.
  Widget _computedBalancesCard() => _SectionCard(
    title: 'الرصيد من الحركات (للقراءة فقط)',
    icon: Icons.calculate_outlined,
    iconColor: const Color(0xFF00695C),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _moneyTile('مدين', _debit),
        _moneyTile('دائن', _credit),
        _moneyTile(
          'الرصيد',
          _computedBalance,
          color: (_computedBalance ?? 0) > 0
              ? AppColors.success
              : ((_computedBalance ?? 0) < 0 ? AppColors.error : null),
        ),
        _moneyTile('عدد الحركات', null, text: '${_movements ?? 0}'),
      ],
    ),
  );

  Widget _moneyTile(String label, double? value, {String? text, Color? color}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            text ?? (value == null ? '—' : formatTreeAmount(value)),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCard() => _SectionCard(
    title: 'بيانات الحساب',
    icon: Icons.edit_note_rounded,
    iconColor: const Color(0xFF1565C0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _nameController,
          maxLength: 150,
          style: const TextStyle(fontSize: 13.5),
          decoration: _input(
            label: 'اسم الحساب المالي',
            icon: Icons.label_outline,
            counterText: '',
          ),
          validator: (val) =>
              (val == null || val.trim().isEmpty) ? 'الرجاء إدخال اسم الحساب' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13.5),
                decoration: _input(
                  label: 'الرصيد المخزّن BALANCE',
                  hint: 'افتح الحقل للتعديل اليدوي',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                validator: _numericValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _limitedBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 13.5),
                decoration: _input(
                  label: 'سقف الرصيد',
                  hint: 'الحد الأقصى',
                  icon: Icons.shield_outlined,
                ),
                validator: _numericValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _seqController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13.5),
                decoration: _input(
                  label: 'التسلسل SEQ',
                  icon: Icons.format_list_numbered_rtl,
                ),
                validator: _integerValidator,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _pickAccDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: _input(label: 'تاريخ الإنشاء', icon: Icons.event_outlined),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _accDate == null ? '—' : _isoDate(_accDate!),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_accDate != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () => setState(() => _accDate = null),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _currencyTile(),
      ],
    ),
  );

  /// شريط العملة للقراءة فقط: لا عمود CUR_NO في CHART_ACC، فهي مشفَّرة في الخانة
  /// الرابعة من رقم الحساب، وتغييرها يعني إعادة ترقيم تكسر مراجع الحركات.
  /// Read-only currency strip: it lives inside the number, so editing it here would
  /// mean renumbering an account whose movements already reference the current number.
  Widget _currencyTile() {
    final currencies = ref.watch(accountCurrencyOptionsProvider).value;
    String name = '';
    if (currencies != null) {
      for (final c in currencies) {
        if (c.curNo == _curNo) name = c.curName;
      }
    }
    final label = _curNo == null
        ? 'رقم بلا خانة عملة معروفة'
        : (name.isEmpty ? 'رقم ${_curNo}' : '$_curNo — $name');
    return InputDecorator(
      decoration: _input(
        label: 'العملة (من رقم الحساب — للعرض فقط)',
        icon: Icons.payments_outlined,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _parentCard(AsyncValue<List<dynamic>> groupsAsync) {
    return _SectionCard(
      title: 'المجموعة الأب',
      icon: Icons.account_tree_outlined,
      iconColor: const Color(0xFF6A1B9A),
      child: _accPart == null
          ? const Text(
              'تعذّر تحديد الحساب الجزئي لهذا الحساب، فلا يمكن تغيير مجموعته.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الحساب الجزئي: ${_accPart.toString()} — ${_parentPath ?? ''}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _directUnderPart,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'حساب مباشر تحت الجزئي (بلا مجموعة)',
                    style: TextStyle(fontSize: 11.5),
                  ),
                  onChanged: (v) => setState(() {
                    _directUnderPart = v ?? false;
                    if (_directUnderPart) _groupId = null;
                  }),
                ),
                if (!_directUnderPart)
                  groupsAsync.when(
                    data: (list) => DropdownButtonFormField<int?>(
                      decoration: _input(
                        label: 'نقل إلى مجموعة',
                        icon: Icons.inventory_2_outlined,
                      ),
                      value: _groupId,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 13),
                      items: [
                        for (final g in list)
                          DropdownMenuItem<int?>(
                            value: (g.groupId as int?),
                            child: Text('${g.groupId} - ${g.accGroupName ?? ''}'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _groupId = v),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                    error: (e, _) => Text(
                      'تعذّر تحميل المجموعات: $e',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _statusCard() => _SectionCard(
    title: 'حالة الحساب',
    icon: Icons.toggle_on_outlined,
    iconColor: _isStopped ? AppColors.error : const Color(0xFF2E7D32),
    child: SwitchListTile(
      value: _isStopped,
      contentPadding: EdgeInsets.zero,
      title: Text(
        _isStopped ? 'الحساب موقوف' : 'الحساب نشط',
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: _isStopped ? AppColors.error : const Color(0xFF2E7D32),
        ),
      ),
      subtitle: const Text(
        'STOPPING_ACC — التوقف يُخرج الحساب من الاختيارات اليومية',
        style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
      ),
      onChanged: (v) => setState(() => _isStopped = v),
    ),
  );

  Widget _warningBar(String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 11.5, color: AppColors.warning),
          ),
        ),
        TextButton(onPressed: _loadDetail, child: const Text('إعادة المحاولة')),
      ],
    ),
  );

  Widget _stickyActions() => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _submitEdit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_isSubmitting ? 'جاري الحفظ…' : 'حفظ التعديلات'),
          ),
        ),
      ],
    ),
  );

  String? _numericValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim()) == null ? 'أدخل رقماً صحيحاً' : null;
  }

  String? _integerValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return int.tryParse(v.trim()) == null ? 'أدخل رقماً صحيحاً' : null;
  }

  InputDecoration _input({
    required String label,
    String? hint,
    required IconData icon,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      counterText: counterText,
      labelStyle: const TextStyle(fontSize: 12.5),
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 17),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}

/// بطاقة قسم بعنوان ملوّن — نمط شاشات الحسابات نفسه.
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}
