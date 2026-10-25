import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/accounts_provider.dart';

/// أنواع الإنشاء الأربعة في الشجرة المحاسبية.
/// The four creatable kinds. Declared here because this screen owns the fields of
/// every kind; the tree screen imports it for its FAB picker, so the dependency
/// stays one-way (tree → form) instead of an import cycle.
enum AccountCreateKind { chart, group, sub, main }

IconData accountCreateIcon(AccountCreateKind kind) => switch (kind) {
  AccountCreateKind.chart => Icons.bookmark_add_outlined,
  AccountCreateKind.group => Icons.group_add_outlined,
  AccountCreateKind.sub => Icons.snippet_folder_outlined,
  AccountCreateKind.main => Icons.landscape_outlined,
};

String accountCreateTitle(AccountCreateKind kind) => switch (kind) {
  AccountCreateKind.chart => 'حساب مالي',
  AccountCreateKind.group => 'مجموعة حسابات',
  AccountCreateKind.sub => 'حساب جزئي',
  AccountCreateKind.main => 'حساب فرعي',
};

String accountCreateTable(AccountCreateKind kind) => switch (kind) {
  AccountCreateKind.chart => 'CHART_ACC',
  AccountCreateKind.group => 'ACC_SUB_GROUP',
  AccountCreateKind.sub => 'ACC_SUB',
  AccountCreateKind.main => 'ACC_MAIN',
};

String accountCreateHint(AccountCreateKind kind) => switch (kind) {
  AccountCreateKind.chart => 'حساب فعلي تُسجَّل له الحركات',
  AccountCreateKind.group => 'مجموعة داخل حساب جزئي',
  AccountCreateKind.sub => 'قسم تفصيلي تحت حساب فرعي',
  AccountCreateKind.main => 'فرع تحت قسم رئيسي',
};

Color accountCreateColor(AccountCreateKind kind) => switch (kind) {
  AccountCreateKind.chart => const Color(0xFF1565C0),
  AccountCreateKind.group => const Color(0xFF6A1B9A),
  AccountCreateKind.sub => const Color(0xFF00695C),
  AccountCreateKind.main => const Color(0xFFE65100),
};

/// شاشة إنشاء عنصر في الشجرة المحاسبية — أربعة أنواع وسلسلة أبوية كاملة.
/// Create screen for the chart of accounts: four kinds, one smart parent chain, and
/// a server-derived number preview.
///
/// الحقول محدودة بأعمدة الجداول الفعلية: لا تُضاف أعمدة جديدة لأن قاعدة البيانات
/// تراثية وليست ملكنا للترحيل — لذلك لا يوجد حقل «ملاحظة» رغم فائدته.
/// Fields are capped to the real columns: the legacy database is not ours to migrate,
/// so there is no free-text notes field even though it would be useful.
class CreateAccountScreen extends ConsumerStatefulWidget {
  final AccountCreateKind initialKind;

  /// تهيئة مبدئية من سلسلة الشجرة: النقر على عقدة ثم «إنشاء داخلها» يمرّر أرقامها
  /// فيُفتح النموذج وقد اكتمل أبواه الأعمق.
  /// Optional seed from a tree node: the deepest parent ids are prefilled so the
  /// chain is already resolved when the form opens.
  final int? initialAccNo;
  final int? initialAccSub;
  final int? initialAccPart;
  final int? initialGroupId;

  const CreateAccountScreen({
    this.initialKind = AccountCreateKind.chart,
    this.initialAccNo,
    this.initialAccSub,
    this.initialAccPart,
    this.initialGroupId,
    super.key,
  });

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late AccountCreateKind _kind = widget.initialKind;

  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitedBalanceController = TextEditingController();
  final _seqController = TextEditingController();

  /// رقم العملة — يُختار من دليل CURRENCY لا أن يُكتب يدوياً.
  /// The chosen CUR_NO. Null until picked: a stale typed number used to become a
  /// silent wrong currency (or a nonexistent one).
  ///
  /// إلزامي للحساب المالي: لا عمود عملة في CHART_ACC، بل الخانة الرابعة من رقم
  /// الحساب هي العملة (251|2|0016 = الجزء 251 بعملة رقم 2) — فلا رقم صحيح دونها.
  /// Mandatory for a chart account: its currency is a digit of its number, not a
  /// column, so there is no valid number to offer before a currency is chosen.
  int? _currencyNo;

  int? _selectedAccNo;
  int? _selectedAccSub;
  int? _selectedAccPart;
  int? _selectedGroupId;

  /// حساب مالي بلا مجموعة: CHART_ACC.GROUP_ID يقبل NULL (20,671 صفاً كذلك أصلاً)،
  /// فيُنشأ تحت الجزئي مباشرة بترقيم البادئة نفسها.
  /// A chart account with NULL GROUP_ID hangs directly under the partial account —
  /// the legacy table already stores 20,671 such rows, so it is a valid shape.
  bool _directUnderPart = false;

  bool _stopping = false;
  DateTime? _accDate;
  bool _isSubmitting = false;

  /// معاينة الرقم المتوقع: تُجلب من الخادم عند اكتمال الأبوين المطلوبين.
  int? _nextNumber;
  bool _previewLoading = false;
  Timer? _previewDebounce;
  int _previewSeq = 0;

  @override
  void initState() {
    super.initState();
    _selectedAccNo = widget.initialAccNo;
    _selectedAccSub = widget.initialAccSub;
    _selectedAccPart = widget.initialAccPart;
    _selectedGroupId = widget.initialGroupId;
    _refreshPreview();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _nameController.dispose();
    _balanceController.dispose();
    _limitedBalanceController.dispose();
    _seqController.dispose();
    super.dispose();
  }

  // ─── السلسلة الأبوية: كل تغيير يُعيد ضبط النسل ──────────────────────────────
  void _pickAccNo(int? value) => setState(() {
    _selectedAccNo = value;
    _selectedAccSub = null;
    _selectedAccPart = null;
    _selectedGroupId = null;
    _schedulePreview();
  });

  void _pickAccSub(int? value) => setState(() {
    _selectedAccSub = value;
    _selectedAccPart = null;
    _selectedGroupId = null;
    _schedulePreview();
  });

  void _pickAccPart(int? value) => setState(() {
    _selectedAccPart = value;
    _selectedGroupId = null;
    _schedulePreview();
  });

  void _pickGroup(int? value) => setState(() {
    _selectedGroupId = value;
    _schedulePreview();
  });

  /// اختيار العملة: يُعيد المعاينة لأن العملة خانة من الرقم — تبديلها يبدّل الرقم
  /// المتوقع فوراً، وإلا عُرض رقم عملةٍ غير المختارة.
  /// Changing the currency changes a digit of the number itself, so the preview must
  /// be re-fetched — otherwise the strip keeps showing another currency's number.
  void _pickCurrency(int? value) {
    setState(() => _currencyNo = value);
    _schedulePreview();
  }

  void _pickKind(AccountCreateKind kind) => setState(() {
    _kind = kind;
    _schedulePreview();
  });

  /// مستوى الأب الأعمق المطلوب لكل نوع — يبني عدد القوائم الظاهرة وشريط المسار.
  int get _requiredDepth => switch (_kind) {
    // ACCOUNT
    AccountCreateKind.main => 1,
    // ACCOUNT → ACC_MAIN
    AccountCreateKind.sub => 2,
    // ACCOUNT → ACC_MAIN → ACC_SUB
    AccountCreateKind.group => 3,
    // … → ACC_SUB_GROUP (أو مباشر تحت الجزئي)
    AccountCreateKind.chart => 4,
  };

  bool get _canPreview => switch (_kind) {
    AccountCreateKind.main => _selectedAccNo != null,
    AccountCreateKind.sub => _selectedAccSub != null,
    AccountCreateKind.group => _selectedAccPart != null,
    // لا رقم لحساب مالي قبل اختيار العملة: الخانة الرابعة منه هي العملة نفسها.
    AccountCreateKind.chart =>
      _currencyNo != null &&
      (_selectedGroupId != null || (_directUnderPart && _selectedAccPart != null)),
  };

  void _schedulePreview() {
    // تأنٍّ 350ms: المستشعرات تتتابع عند اختيار القسم ثم الفرعي ثم الجزئي، وكل
    // استدعاء بلا إلغاء يترك سباقاً يعرض رقم نوعٍ غير المختار.
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _refreshPreview);
  }

  Future<void> _refreshPreview() async {
    if (!_canPreview) {
      if (_nextNumber != null) setState(() => _nextNumber = null);
      return;
    }
    final version = ++_previewSeq;
    setState(() => _previewLoading = true);
    final repo = ref.read(accountRepositoryProvider);
    final number = await repo.fetchNextNumber(
      level: _kind.name,
      accNo: _selectedAccNo,
      accSub: _selectedAccSub,
      accPart: _selectedAccPart,
      groupId: _directUnderPart ? null : _selectedGroupId,
      curNo: _kind == AccountCreateKind.chart ? _currencyNo : null,
    );
    if (!mounted || version != _previewSeq) return;
    setState(() {
      _previewLoading = false;
      _nextNumber = number;
    });
  }

  // ─── الإرسال ────────────────────────────────────────────────────────────────
  String? _validateParent() {
    if (_kind != AccountCreateKind.main && _selectedAccNo == null) {
      return 'الرجاء اختيار القسم الرئيسي';
    }
    if ((_kind == AccountCreateKind.sub ||
            _kind == AccountCreateKind.group ||
            _kind == AccountCreateKind.chart) &&
        _selectedAccSub == null) {
      return 'الرجاء اختيار الحساب الفرعي';
    }
    if ((_kind == AccountCreateKind.group ||
            _kind == AccountCreateKind.chart) &&
        _selectedAccPart == null) {
      return 'الرجاء اختيار الحساب الجزئي';
    }
    if (_kind == AccountCreateKind.chart &&
        !_directUnderPart &&
        _selectedGroupId == null) {
      return 'الرجاء اختيار مجموعة الحسابات أو تفعيل الحساب المباشر';
    }
    // العملة ليست ترفاً في الحساب المالي: هي الخانة الرابعة من رقمه، وبلا اختيارها
    // لا رقم يُمنح — والخادم يردّ 422 لو أرسل الطلب دونها.
    // A chart account has no number at all before its currency is chosen.
    if (_kind == AccountCreateKind.chart && _currencyNo == null) {
      return 'الرجاء اختيار العملة — هي الخانة الرابعة من رقم الحساب';
    }
    return null;
  }

  /// يحفظ ثم يُمهّد لنوع متكرر (حساب مالي/مجموعة داخل نفس الأب) أو يغلق الشاشة.
  Future<void> _submit({required bool keepOpen}) async {
    final parentError = _validateParent();
    if (parentError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(parentError)));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = ref.read(accountRepositoryProvider);
    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim());
    // العملة مرقّمة في الجدول بـ CUR_NO، لكن ما يُرسل هو رقم عنصر مختار من الدليل
    // لا نص حرّ: لا يوجد رقم «غير موجود» بعد الآن. للحساب المالي تُرسل دائماً
    // لأن التحقق أعلاها منع إرسال الطلب دونها.
    final curNo = _currencyNo;

    final res = switch (_kind) {
      AccountCreateKind.main => await repo.createAccMain(
        accNo: _selectedAccNo!,
        subName: name,
        balance: balance,
        curNo: curNo,
      ),
      AccountCreateKind.sub => await repo.createAccSub(
        accSub: _selectedAccSub!,
        partName: name,
        balance: balance,
        curNo: curNo,
      ),
      AccountCreateKind.group => await repo.createSubGroup(
        name: name,
        accPart: _selectedAccPart!,
      ),
      AccountCreateKind.chart => await repo.createChartAccount(
        name: name,
        // مضمونة غير-null بالتحقق السابق: الخانة الرابعة من الرقم تُشتق منها
        curNo: curNo!,
        groupId: _directUnderPart ? null : _selectedGroupId,
        accPart: _directUnderPart ? _selectedAccPart : null,
        balance: balance,
        limitedBalance: double.tryParse(_limitedBalanceController.text.trim()),
        stoppingAcc: _stopping ? 1 : 0,
        seq: int.tryParse(_seqController.text.trim()),
        accDate: _accDate == null ? null : _isoDate(_accDate!),
      ),
    };

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.error),
      );
      return;
    }

    // تحديث الشجرة مع إبقاء التوسيع: المستخدم يتابع داخل نفس الفرع الذي فتحه.
    ref.read(accountTreeProvider.notifier).loadTree(keepExpansion: true);
    if (_kind == AccountCreateKind.chart) {
      ref.read(chartAccountsProvider.notifier).loadAccounts();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res.message.isEmpty
              ? 'تم إنشاء ${accountCreateTitle(_kind)} بنجاح'
              : res.message,
        ),
      ),
    );

    if (keepOpen) {
      _nameController.clear();
      _balanceController.clear();
      _limitedBalanceController.clear();
      _seqController.clear();
      _schedulePreview();
    } else {
      Navigator.pop(context, true);
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final wide = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'إنشاء ${accountCreateTitle(_kind)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 980 : 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kindPicker(),
                    const SizedBox(height: 12),
                    _pathBar(),
                    const SizedBox(height: 12),
                    _parentChain(),
                    const SizedBox(height: 12),
                    _dataCard(),
                    if (_kind == AccountCreateKind.chart) ...[
                      const SizedBox(height: 12),
                      _chartExtras(),
                    ],
                    const SizedBox(height: 88),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _stickyActions(),
    );
  }

  // ─── منتقي الأنواع ──────────────────────────────────────────────────────────
  Widget _kindPicker() {
    return _SectionCard(
      title: 'العنصر المطلوب إنشاؤه',
      icon: Icons.category_outlined,
      iconColor: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoAcross = constraints.maxWidth > 420;
          final items = AccountCreateKind.values
              .map((k) => _kindCard(k, twoAcross))
              .toList();
          if (!twoAcross) {
            return Column(
              children: [
                for (final item in items) Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: item,
                ),
              ],
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                SizedBox(width: (constraints.maxWidth - 8) / 2, child: item),
            ],
          );
        },
      ),
    );
  }

  Widget _kindCard(AccountCreateKind kind, bool twoAcross) {
    final selected = _kind == kind;
    final color = accountCreateColor(kind);
    return InkWell(
      onTap: () => _pickKind(kind),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              accountCreateIcon(kind),
              color: selected ? color : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accountCreateTitle(kind),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: selected ? color : AppColors.textPrimary,
                    ),
                  ),
                  if (!twoAcross)
                    Text(
                      accountCreateHint(kind),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── شريط المسار + معاينة الرقم ─────────────────────────────────────────────
  Widget _pathBar() {
    final segments = <String>[
      if (_selectedAccNo != null) 'القسم ${_selectedAccNo.toString()}',
      if (_selectedAccSub != null) 'الفرعي ${_selectedAccSub.toString()}',
      if (_selectedAccPart != null) 'الجزئي ${_selectedAccPart.toString()}',
      if (_selectedGroupId != null && !_directUnderPart)
        'المجموعة ${_selectedGroupId.toString()}',
      if (_directUnderPart) 'مباشر بلا مجموعة',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accountCreateIcon(_kind),
                size: 16,
                color: accountCreateColor(_kind),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  segments.isEmpty
                      ? 'اختر السلسلة الأبوية بالأسفل'
                      : segments.join('  ›  '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'الرقم المتوقع: ',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              if (_previewLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  _nextNumber?.toString() ?? '—',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _nextNumber == null
                        ? AppColors.textMuted
                        : accountCreateColor(_kind),
                  ),
                ),
              // الحساب المالي: الرقم لا يُعرف قبل اختيار العملة، فهي خانة منه لا
              // حقل بجانبه — فلا يُترك المستخدم أمام «—» بلا شرح.
              // Explains why the strip stays empty until a currency is picked.
              if (_kind == AccountCreateKind.chart && _currencyNo == null) ...[
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'يُحدَّد باختيار العملة',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                accountCreateTable(_kind),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── السلسلة الأبوية ────────────────────────────────────────────────────────
  Widget _parentChain() {
    final accountsAsync = ref.watch(parentAccountsProvider);
    final accMainAsync = ref.watch(parentAccMainProvider(_selectedAccNo));
    final accSubAsync = ref.watch(parentAccSubProvider(_selectedAccSub));
    final groupAsync = ref.watch(parentAccSubGroupProvider(_selectedAccPart));

    return _SectionCard(
      title: 'السلسلة الأبوية',
      icon: Icons.account_tree_outlined,
      iconColor: const Color(0xFF00695C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _chainLevel(
            label: '1. القسم الرئيسي (ACCOUNT)',
            icon: Icons.folder_special_outlined,
            iconColor: Colors.indigo,
            asyncList: accountsAsync,
            value: _selectedAccNo,
            codeOf: (dynamic a) => a.accNo as int?,
            nameOf: (dynamic a) => a.accName as String?,
            onChanged: _pickAccNo,
            errorHint: 'تعذّر تحميل الأقسام',
          ),
          if (_selectedAccNo != null && _requiredDepth >= 2) ...[
            const SizedBox(height: 10),
            _chainLevel(
              label: '2. الحساب الفرعي (ACC_MAIN)',
              icon: Icons.folder_outlined,
              iconColor: Colors.blue,
              asyncList: accMainAsync,
              value: _selectedAccSub,
              codeOf: (dynamic m) => m.accSub as int?,
              nameOf: (dynamic m) => m.subName as String?,
              onChanged: _pickAccSub,
              errorHint: 'تعذّر تحميل الفروع',
            ),
          ],
          if (_selectedAccSub != null && _requiredDepth >= 3) ...[
            const SizedBox(height: 10),
            _chainLevel(
              label: '3. الحساب الجزئي (ACC_SUB)',
              icon: Icons.snippet_folder_outlined,
              iconColor: Colors.teal,
              asyncList: accSubAsync,
              value: _selectedAccPart,
              codeOf: (dynamic s) => s.accPart as int?,
              nameOf: (dynamic s) => s.partName as String?,
              onChanged: _pickAccPart,
              errorHint: 'تعذّر تحميل الأجزاء',
            ),
          ],
          if (_selectedAccPart != null && _requiredDepth >= 4) ...[
            const SizedBox(height: 10),
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
                if (_directUnderPart) _selectedGroupId = null;
                _schedulePreview();
              }),
            ),
            if (!_directUnderPart)
              _chainLevel(
                label: '4. مجموعة الحسابات (ACC_SUB_GROUP)',
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.amber.shade800,
                asyncList: groupAsync,
                value: _selectedGroupId,
                codeOf: (dynamic g) => g.groupId as int?,
                nameOf: (dynamic g) => g.accGroupName as String?,
                onChanged: _pickGroup,
                errorHint: 'تعذّر تحميل المجموعات',
              ),
          ],
        ],
      ),
    );
  }

  /// قائمة مستوى واحد من السلسلة — النماذج المختلفة للحقول الأربعة تشترك في
  /// (رقم، اسم) فقط، فيُمرَّر الاستخراج بدوال صغيرة بدل أربع نسخ من الـ when().
  Widget _chainLevel({
    required String label,
    required IconData icon,
    required Color iconColor,
    required AsyncValue<List<dynamic>> asyncList,
    required int? value,
    required int? Function(dynamic) codeOf,
    required String? Function(dynamic) nameOf,
    required void Function(int?) onChanged,
    required String errorHint,
  }) {
    return asyncList.when(
      data: (list) => _dropdown<int>(
        label: label,
        icon: icon,
        iconColor: iconColor,
        value: value,
        items: [
          for (final item in list)
            _item(codeOf(item), '${codeOf(item)} - ${nameOf(item) ?? ''}'),
        ],
        onChanged: onChanged,
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (err, _) => _levelError(errorHint, '$err'),
    );
  }

  Widget _levelError(String hint, String detail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$hint — $detail',
        style: const TextStyle(fontSize: 11, color: AppColors.error),
      ),
    );
  }

  // ─── بيانات العنصر ──────────────────────────────────────────────────────────
  Widget _dataCard() {
    final isChart = _kind == AccountCreateKind.chart;
    final nameLabel = switch (_kind) {
      AccountCreateKind.chart => 'اسم الحساب المالي',
      AccountCreateKind.group => 'اسم مجموعة الحسابات',
      AccountCreateKind.sub => 'اسم الحساب الجزئي',
      AccountCreateKind.main => 'اسم الحساب الفرعي',
    };
    // SUB_NAME/PART_NAME تراثياً 30 حرفاً، وACC_NAME وACC_GROUP_NAME أطول.
    final maxName = isChart
        ? 150
        : _kind == AccountCreateKind.group
        ? 100
        : 30;

    return _SectionCard(
      title: 'بيانات ${accountCreateTitle(_kind)}',
      icon: Icons.edit_note_rounded,
      iconColor: const Color(0xFFE65100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            maxLength: maxName,
            style: const TextStyle(fontSize: 13.5),
            decoration: _input(
              label: nameLabel,
              icon: Icons.label_outline,
              counterText: '',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم' : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _input(
                    label: 'الرصيد الافتتاحي',
                    hint: 'اختياري',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  validator: _numericValidator,
                ),
              ),
              if (isChart) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _limitedBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(fontSize: 13.5),
                    decoration: _input(
                      label: 'سقف الرصيد',
                      hint: 'اختياري',
                      icon: Icons.shield_outlined,
                    ),
                    validator: _numericValidator,
                  ),
                ),
              ],
            ],
          ),
          // سطر العملة مستقلّ ويظهر في كل نموذج: سابقاً كان يُخفى على الحساب المالي
          // والمجموعة بحجة أن جدولهما لا يملك عمود CUR_NO، فكان أول ما يسأل عنه
          // المستخدم «أين حقل العملة؟». الآن منتقىً في الحساب المالي والحساب الفرعي
          // والجزئي، وشرحٌ لمصدرها في المجموعة (وهي الوحيدة التي لا رقم لها أصلاً).
          const SizedBox(height: 10),
          _currencyRow(),
        ],
      ),
    );
  }

  /// سطر العملة: منتقي في كل مستوى يملك عملة — والحساب المالي منه رغم أن جدولـه
  /// لا يملك عمود CUR_NO، لأن عملته مشفَّرة في الخانة الرابعة من رقمه.
  /// A real picker everywhere a currency exists. A chart account has no CUR_NO
  /// column yet still owns a currency: it is the 4th digit of ACC_NO, so the
  /// choice is written into the number instead of a column. Only the group level
  /// has neither number nor column, and says so instead of pretending to inherit.
  Widget _currencyRow() {
    if (_kind == AccountCreateKind.group) return _groupCurrencyNote();
    return _currencyField();
  }

  /// مجموعة الحسابات: لا رقم لها يُرمَّز فيها ولا عمود يخزّنها، فعملتها فعلاً
  /// عملة الحساب الجزئي الذي يعلوها — تُعرض هنا كمعلومة لا كحقل يُملأ.
  /// Groups own no number and no column, so their currency genuinely comes from the
  /// part above; shown as information because there is nothing to send.
  Widget _groupCurrencyNote() {
    // `.value` لا `when()`: الحقل وصفي، فلا يُنتظر من تحميل دليل أو سلسلة أن
    // يوقف بناء النموذج — غائبٌ اليوم يعني «غير محددة» لا شاشة خطأ.
    final parts = ref.watch(parentAccSubProvider(_selectedAccSub)).value;
    final currencies = ref.watch(accountCurrencyOptionsProvider).value;
    int? curNo;
    if (_selectedAccPart != null && parts != null) {
      for (final s in parts) {
        if (s.accPart == _selectedAccPart) curNo = s.curNo;
      }
    }
    String name = '';
    if (currencies != null) {
      for (final c in currencies) {
        if (c.curNo == curNo) name = c.curName;
      }
    }
    final text = _selectedAccPart == null
        ? 'تظهر بعد اختيار الحساب الجزئي'
        : curNo == null
        ? 'بدون عملة على الحساب الجزئي'
        : (name.isEmpty ? 'رقم $curNo' : '$curNo — $name');

    return InputDecorator(
      decoration: _input(
        label: 'العملة (عن الحساب الجزئي صاحب المجموعة)',
        icon: Icons.info_outline,
      ),
      child: Text(
        text,
        // لا `const`: AppColors.textPrimary قيمةٌ ديناميكية من لوحة الألوان، فلا
        // تصلح داخل ثابت — نفس الفخ الذي أوقعته `textPrimary` في نافذة النطاق.
        style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// حقل العملة: قائمة منسدلة من دليل CURRENCY، لا إدخال رقم خام.
  /// Currency picker fed by `/accounts/currencies`.
  ///
  /// لماذا؟ CUR_NO رقم مجهري في جدول العملات: كان المستخدم يكتب «2» فلا يظهر له أي
  /// اسم، وأي خطأ يعني عملة أخرى صامتة أو رقماً لا وجود له. القائمة تُظهر
  /// «2 — دولار» وتضمن أن ما يُرسل موجود فعلاً في الدليل.
  ///
  /// A raw number field asked staff to memorise an id and offered no confirmation
  /// that it exists. The picker shows the name next to the number, so a wrong
  /// currency stops being a silent data-entry failure.
  ///
  /// الحساب المالي: إلزامي — يُبنى منه الرقم. الفرعي والجزئي: اختياري، لأن
  /// عمودهما CUR_NO يقبل الفراغ ودليلهما قد يفشل في التحميل فلا يُعطَّل الإنشاء.
  /// Mandatory for a chart account (it is a digit of its number); optional for the
  /// structural levels, whose nullable column and possibly-failing directory must
  /// not block creating a node.
  Widget _currencyField() {
    final mandatory = _kind == AccountCreateKind.chart;
    final label = mandatory
        ? 'العملة * (الخانة الرابعة من رقم الحساب)'
        : 'العملة';

    return ref.watch(accountCurrencyOptionsProvider).when(
      loading: () => _currencyPlaceholder('جارٍ تحميل العملات…', spinning: true),
      error: (err, _) => _currencyFieldRetry(err),
      data: (currencies) {
        // DropdownButton يفرض أن قيمته أحد عناصره: إن حُذفت العملة من الدليل أثناء
        // فتح النموذج تُعرض «—» بدل أن ينهار السطر كله.
        // Guard against the assert, not just the stale value.
        final known = currencies.any((c) => c.curNo == _currencyNo);
        return _dropdown<int?>(
          label: label,
          icon: Icons.payments_outlined,
          iconColor: AppColors.primary,
          value: known ? _currencyNo : null,
          items: [
            // «بدون عملة» لم يعد خياراً ممكناً في الحساب المالي: لا رقم بلا عملة.
            // The empty slot is only offered where the column really is nullable.
            if (!mandatory)
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('بدون عملة', style: TextStyle(fontSize: 12.5)),
              ),
            for (final c in currencies)
              DropdownMenuItem<int?>(
                value: c.curNo,
                child: Text(
                  c.display,
                  style: const TextStyle(fontSize: 12.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _pickCurrency,
        );
      },
    );
  }

  /// دليل العملات لم يُحمَّل: خطأ الشبكة ليس سبباً لمنع إنشاء حساب فرعي أو جزئي،
  /// أما الحساب المالي فيبقى الرقم مجهول حتى يُجلب الدليل — لذلك يُعرض زر إعادة
  /// المحاولة لا حقل معطّل بلا شرح.
  /// A failed directory degrades to a retry affordance rather than a dead field.
  ///
  /// الـ 404 يُسمّى باسمه: نسخة API أقدم لا انقطاع شبكة، وإعادة المحاولة لن تنفع.
  /// A 404 is named as such — an older API build, where retrying changes nothing.
  Widget _currencyFieldRetry(Object? error) {
    final isMissingEndpoint =
        error is DioException && error.response?.statusCode == 404;
    final label = isMissingEndpoint
        ? 'تعذّر جلب العملات — الخادم لا يعرف /accounts/currencies (404)'
        : 'تعذّر جلب العملات — انقر للمحاولة ثانية';
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => ref.invalidate(accountCurrencyOptionsProvider),
      child: _currencyPlaceholder(label, spinning: false),
    );
  }

  /// نفس شكل بقية حقوف السطر، حتى أثناء التحميل أو عند فشله — لا يقصر الحقل ويتحوّل
  /// الصف إلى أعمدة غير متساوية.
  Widget _currencyPlaceholder(String text, {required bool spinning}) {
    return InputDecorator(
      decoration: _input(label: 'العملة', icon: Icons.payments_outlined),
      child: Row(
        children: [
          if (spinning) ...[
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// الحقول الخاصة بالحساب المالي فقط — SEQ/STOPPING_ACC/ACC_DATE أعمدة CHART_ACC
  /// حقيقية كانت تُترك للافتراضي، والآن تُعرض لأن المستخدم يطلبها.
  Widget _chartExtras() {
    return _SectionCard(
      title: 'حقول إضافية (اختيارية)',
      icon: Icons.tune_rounded,
      iconColor: Colors.blueGrey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _seqController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: _input(
                    label: 'التسلسل SEQ',
                    hint: 'اختياري',
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
                    decoration: _input(
                      label: 'تاريخ الإنشاء',
                      icon: Icons.event_outlined,
                    ),
                    child: Text(
                      _accDate == null ? 'الافتراضي (اليوم)' : _isoDate(_accDate!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: _stopping,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('حساب موقوف', style: TextStyle(fontSize: 12.5)),
            subtitle: const Text(
              'STOPPING_ACC = 1 — يظهر محذوراً في الشجرة ولا يُستخدم للحركات الجديدة',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
            ),
            onChanged: (v) => setState(() => _stopping = v),
          ),
          const SizedBox(height: 4),
          const Text(
            'الحقول محدودة بأعمدة CHART_ACC الفعلية: قاعدة البيانات تراثية ولا تُضاف أعمدة.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

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

  // ─── شريط الإجراءات اللاصق ──────────────────────────────────────────────────
  Widget _stickyActions() {
    // زر «حفظ» يُرسم لكل أنواع الحسابات لا للمكرر منها فقط؛ كان الحارس
    // `if (repeatable)` يغلّفه بالخطأ فيحرم main/sub/part من الحفظ.
    // The Save button must render for EVERY kind, not only the repeatable ones:
    // the `if (repeatable)` guard wrongly wrapped it, hiding it on main/sub/part.
    return Container(
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
              onPressed: _isSubmitting ? null : () => _submit(keepOpen: false),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(_isSubmitting ? 'جاري الحفظ…' : 'حفظ'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── عناصر مساعدة ───────────────────────────────────────────────────────────
  DropdownMenuItem<int> _item(int? value, String label) =>
      DropdownMenuItem<int>(value: value, child: Text(label));

  String? _numericValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim()) == null ? 'أدخل رقماً صحيحاً' : null;
  }

  String? _integerValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return int.tryParse(v.trim()) == null ? 'أدخل رقماً صحيحاً' : null;
  }

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required Color iconColor,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, color: iconColor, size: 17),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      value: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
    );
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

/// بطاقة قسم بعنوان ملوّن — نفس نمط الشاشات الحالية في المشروع.
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
