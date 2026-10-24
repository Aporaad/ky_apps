import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_tree_flatten.dart';

/// ورقة تفاصيل الحساب — كل الحقول المتاحة من أعمدة CHART_ACC/ACC_* الموجودة
/// + الرصيد المحسوب من الحركات. تُفتح بالنقر الطويل أو زر `i`.
///
/// لا تُضاف أعمدة جديدة: قاعدة البيانات تراثية وليست ملكنا للترحيل، فالتفاصيل
/// = الأعمدة الحالية + المشتق من ENTRY_SUB (الرصيد المحسوب وعدد الحركات).
///
/// الأزرار لا تستورد شاشات الكشف بنفسها: المبلّغات تمرّ من الشاشة الأم، فتبقى
/// الورقة ورقةً ولا تنشأ حلقة استيراد بين الورقة والشاشات التي تفتحها.
/// Actions are callbacks from the calling screen: importing the statement screens
/// here would create an import cycle and duplicate permission logic.
class AccountDetailsSheet extends ConsumerStatefulWidget {
  final AccountTreeRow row;

  /// كشف الحساب: مالي للورفة الفردية، ومجموعات لغير ذلك — يقرره الأب بالمستوى.
  final void Function(BuildContext context, AccountTreeRow row) onReveal;
  final void Function(BuildContext context, int accNo, String accName)? onEdit;

  const AccountDetailsSheet({
    required this.row,
    required this.onReveal,
    this.onEdit,
    super.key,
  });

  @override
  ConsumerState<AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends ConsumerState<AccountDetailsSheet> {
  Map<String, dynamic>? _detail;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // الهيكل والصفوف المحمّلة تحمل حقولها أصلاً؛ التفريد المفرد للحساب المالي
    // الذي وصل من `/tree/children` بلا بعض الحقول (سقف الرصيد، التاريخ…).
    if (widget.row.leaf != null) _loadDetail();
  }

  Future<void> _loadDetail() async {
    final accNo = widget.row.leaf?.accNo ?? widget.row.node?.accNo;
    if (accNo == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(accountRepositoryProvider);
      final detail = await repo.fetchChartAccountDetail(accNo);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detail = detail;
        _error = detail == null ? 'تعذّر جلب تفاصيل الحساب' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  dynamic _field(String lower, [String? upper]) {
    final d = _detail;
    if (d == null) return null;
    return d[lower] ?? d[upper ?? lower.toUpperCase()];
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final node = row.node;
    final leaf = row.leaf;

    final accNo = _field('acc_no') ?? leaf?.accNo ?? node?.accNo;
    final name = _field('acc_name')?.toString() ?? row.title;
    final groupId = _field('group_id') ?? node?.groupId;
    final limited = _field('limited_balance') ?? node?.limitedBalance ?? leaf?.limitedBalance;
    final stopping = (_field('stopping_acc') ?? (leaf?.stopped == true ? 1 : 0));
    final accDate = _field('acc_date')?.toString() ?? leaf?.accDate ?? node?.accDate;
    final seq = _field('seq') ?? leaf?.seq ?? node?.seq;
    final curNo = node?.curNo;

    final storedBalance = _field('balance') ?? node?.storedBalance ?? leaf?.storedBalance;
    final computed = row.balance ?? node?.balance ?? leaf?.net;
    final debit = row.debit ?? node?.debit ?? leaf?.debit;
    final credit = row.credit ?? node?.credit ?? leaf?.credit;
    final movements = row.node?.movements ?? leaf?.movements;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            const _SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 18,
                    color: row.levelColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تفاصيل ${row.levelLabel}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                children: [
                  _FieldRow(label: 'الرقم', value: accNo?.toString() ?? '—'),
                  _FieldRow(label: 'الاسم', value: name),
                  _FieldRow(label: 'المستوى', value: row.levelLabel),
                  _FieldRow(
                    label: 'سلسلة الآباء',
                    value: (node?.parentPath.isNotEmpty ?? false)
                        ? node!.parentPath
                        : (leaf?.parentPath.isNotEmpty ?? false)
                        ? leaf!.parentPath
                        : (node?.codePath.isNotEmpty ?? false)
                        ? node!.codePath
                        : '—',
                  ),
                  _FieldRow(label: 'مسار الأرقام', value: node?.codePath ?? '—'),
                  _FieldRow(
                    label: 'المجموعة',
                    value: groupId == null
                        ? 'بلا مجموعة (حساب مباشر)'
                        : '$groupId',
                  ),
                  const SizedBox(height: 8),
                  _MoneyBlock(
                    stored: storedBalance?.toString(),
                    computed: computed,
                    debit: debit,
                    credit: credit,
                    movements: movements,
                    limitedBalance: limited is num
                        ? limited.toDouble()
                        : double.tryParse(limited?.toString() ?? ''),
                  ),
                  const SizedBox(height: 8),
                  _FieldRow(
                    label: 'سقف الرصيد',
                    value: limited?.toString() ?? 'غير محدود',
                  ),
                  _FieldRow(
                    label: 'الحالة',
                    value: (stopping?.toString() == '1') ? 'موقوف' : 'نشط',
                    color: (stopping?.toString() == '1')
                        ? AppColors.error
                        : AppColors.success,
                  ),
                  _FieldRow(label: 'تاريخ الإنشاء', value: accDate ?? '—'),
                  _FieldRow(label: 'SEQ', value: seq?.toString() ?? '—'),
                  _FieldRow(label: 'العملة', value: curNo?.toString() ?? '—'),
                  _FieldRow(
                    label: 'عدد الأبناء',
                    value: node == null
                        ? '—'
                        : '${node.childrenCount ?? node.children.length}',
                  ),
                  if ((node?.hiddenAccounts ?? 0) > 0)
                    _FieldRow(
                      label: 'حسابات مخفية من العرض',
                      value:
                          '${node!.hiddenAccounts} — أرصدتها داخل التجميع ولا تظهر في الشجرة',
                      color: AppColors.warning,
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onReveal(context, row);
                        },
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                        label: const Text('كشف الحساب'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.onEdit != null)
                      PermissionGate(
                        code: Perm.accountsUpdate,
                        child: IconButton.outlined(
                          onPressed: accNo == null
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  widget.onEdit!(
                                    context,
                                    int.parse(accNo.toString()),
                                    name,
                                  );
                                },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          tooltip: 'تعديل',
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
}

/// فتح الورقة من الشاشة: المبلّغات تُمرَّر كما هي إلى أزرار الورقة.
Future<void> showAccountDetailsSheet(
  BuildContext context, {
  required AccountTreeRow row,
  required void Function(BuildContext context, AccountTreeRow row) onReveal,
  void Function(BuildContext context, int accNo, String accName)? onEdit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        AccountDetailsSheet(row: row, onReveal: onReveal, onEdit: onEdit),
  );
}

// ─── عناصر بصرية صغيرة / small visual pieces ──────────────────────────────────
class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _FieldRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// كتلة الرصيد: المحسوب من الحركات هو الأساس، والمخزّن للمقارنة فقط.
class _MoneyBlock extends StatelessWidget {
  final String? stored;
  final double? computed;
  final double? debit;
  final double? credit;
  final int? movements;
  final double? limitedBalance;

  const _MoneyBlock({
    required this.stored,
    required this.computed,
    required this.debit,
    required this.credit,
    required this.movements,
    required this.limitedBalance,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, {Color? color}) => Container(
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
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );

    final net = computed ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'الرصيد المحسوب من الحركات',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            tile('مدين', debit == null ? '—' : formatTreeAmount(debit!)),
            tile('دائن', credit == null ? '—' : formatTreeAmount(credit!)),
            tile(
              'الرصيد',
              formatTreeAmount(net),
              color: net > 0
                  ? AppColors.success
                  : (net < 0 ? AppColors.error : AppColors.textMuted),
            ),
            tile('الحركات', '${movements ?? 0}'),
            tile(
              'المخزّن (للمقارنة)',
              stored == null ? '—' : (stored!.isEmpty ? '—' : stored!),
            ),
          ],
        ),
      ],
    );
  }
}
