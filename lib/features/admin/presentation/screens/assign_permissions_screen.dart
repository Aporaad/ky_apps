import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/permissions_notifier.dart';
import '../providers/admin_users_provider.dart';
import '../providers/assign_permissions_provider.dart';
import '../widgets/permissions_picker_widget.dart';

/// شاشة منح الصلاحيات لمستخدم — تُفتح من أيقونة «صلاحيات» في البطاقة
/// The grant-permissions screen for one user, opened from the card's shield action.
///
/// تدير الحالة `assignPermissionsProvider` لا حالة محلية: الحفظ يستبدل المنح كاملة عند الخادم،
/// وأي دمج محلي في الشاشة كان سيخفي أن الإرسال قائمة كاملة لا فرقاً.
/// State lives in the provider, not the screen: saving replaces the whole grant set server-side,
/// and local merging in the widget would hide that the payload is a full list, not a diff.
class AssignPermissionsScreen extends ConsumerStatefulWidget {
  final int userId;

  /// الاسم للعرض فقط — يُمرَّر من البطاقة فلا تنتظر الشاشة شبكة لعنوانها
  /// The display name, passed from the card so the header needs no extra request.
  final String userName;

  const AssignPermissionsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<AssignPermissionsScreen> createState() =>
      _AssignPermissionsScreenState();
}

class _AssignPermissionsScreenState extends ConsumerState<AssignPermissionsScreen> {
  String? _banner;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(assignPermissionsProvider.notifier).load(widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignPermissionsProvider);
    final notifier = ref.read(assignPermissionsProvider.notifier);
    final grantor = ref.watch(authNotifierProvider);

    final targetIsAdmin = state.user?.isAdmin ?? false;

    return PopScope(
      // الحماية من الفقد: الخروج مع تحديد غير محفوظ يترك المستخدم يظن أن الصلاحيات حُفظت
      // Loss guard: leaving with an unsaved selection would leave the user believing it persisted.
      canPop: !state.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard(context);
        // `context.mounted` لا `mounted` المزود: السؤال عن السياق لا عن الحالة
        // context.mounted, not the notifier's mounted: the question is about the BuildContext.
        if (leave && context.mounted) Navigator.of(context).pop(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('صلاحيات المستخدم'),
          actions: [
            if (state.isDirty)
              TextButton(
                onPressed: state.isSaving ? null : () => notifier.clearAll(),
                child: const Text('مسح التحديد'),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => notifier.load(widget.userId),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                          child: Column(
                            children: [
                              _Head(
                                userName: widget.userName,
                                state: state,
                                targetIsAdmin: targetIsAdmin,
                              ),
                              if (_banner != null) ...[
                                const SizedBox(height: 10),
                                _Banner(
                                  message: _banner!,
                                  tone: AppColors.error,
                                  onClose: () => setState(() => _banner = null),
                                ),
                              ],
                              if (state.error != null && state.user == null)
                                _LoadError(
                                  message: state.error!,
                                  onRetry: () => notifier.load(widget.userId),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (state.user != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
                            child: PermissionsPickerWidget(
                              selected: state.selected,
                              onToggle: notifier.toggle,
                              // المعالج الوسيط لأن المزود يأخذ `on` اسمياً والمكوّن يرها موقعياً
                              // The adapter exists because the notifier takes a named `on` flag
                              // while the picker passes it positionally.
                              onSetMany: (codes, select) =>
                                  notifier.setCodes(codes, on: select),
                              grantorPermissions: grantor.permissions,
                              grantorIsAdmin: grantor.isAdmin,
                              disabled: targetIsAdmin,
                              hint: targetIsAdmin
                                  ? 'هذا حساب مدير النظام: يملك كل الصلاحيات بلا منح من الجدول.'
                                  : 'المنح مباشرة لهذا المستخدم — لا أدوار في النظام.',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _SaveBar(
                state: state,
                targetIsAdmin: targetIsAdmin,
                onSave: () => _save(notifier),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// الحفظ مع تأكيد إنهاء الجلسات — تغيير المنح بلا إنهاء يترك جلسة تمارس صلاحيات سحبت للتو
  /// Save with a session-termination confirmation: changing grants without ending sessions would
  /// leave a live token exercising rights just revoked.
  Future<void> _save(AssignPermissionsNotifier notifier) async {
    final targetIsAdmin = _targetIsAdmin();
    final confirmed = await _confirmSave(
      context,
      mentionSessions: !targetIsAdmin,
    );
    if (!confirmed || !mounted) return;

    setState(() => _banner = null);
    final result = await notifier.save(widget.userId, logoutOthers: !targetIsAdmin);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _banner = result.displayMessage);

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message.trim().isEmpty ? 'تم حفظ الصلاحيات' : result.message.trim()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    // إعادة تحميل قائمة المستخدمين: عدّاد «صلاحيات: N» مصدره الخادم
    // Reload the list: the card's grant count is server-derived.
    ref.read(adminUsersProvider.notifier).refresh();

    // تعديل المستخدم منحَ نفسه؟ تُعاد المزامنة فوراً حتى تظهر الأقسام الجديدة بلا إعادة دخول
    // Editing one's own grants? Re-sync at once so newly granted sections appear without a re-login
    final selfId = ref.read(authNotifierProvider).user?.id;
    if (selfId == widget.userId) {
      await ref.read(permissionsNotifierProvider.notifier).refreshNow();
      // الشاشة قد تُغلق أثناء المزامنة؛ لا سياق بعدئذٍ
      // The screen can close mid-sync, so there is no context to use afterwards
      if (!mounted) return;
    }

    Navigator.of(context).pop(true);
  }

  /// حالة مدير الهدف تُقرأ من المزود لا من البطاقة — البطاقة قد تكون قديمة بعد تعديل النوع
  /// The target's admin flag comes from the provider, not the (possibly stale) card row.
  bool _targetIsAdmin() =>
      ref.read(assignPermissionsProvider).user?.isAdmin ?? false;
}

/// رأس الشاشة: الاسم، شارة الحساسية، وعدّاد المنح الممنوحة
/// The header: name, a sensitive-state badge, and the granted-count.
class _Head extends StatelessWidget {
  final String userName;
  final AssignPermissionsState state;
  final bool targetIsAdmin;

  const _Head({
    required this.userName,
    required this.state,
    required this.targetIsAdmin,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (targetIsAdmin)
                _Pill(label: 'مدير النظام', color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 16,
                color: targetIsAdmin ? AppColors.accent : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  targetIsAdmin
                      ? 'يتجاوز جدول المنح — كل الأكواد مسموحة له أصلًا'
                      : '${state.selectedCount} صلاحيّة ممنوحة',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (state.isDirty)
                const _Pill(label: 'غير محفوظ', color: AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }
}

/// شارة صغيرة ملوّنة
/// A small coloured pill.
class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

/// شريط الحفظ السفلي — ثابت لأن المنح كثيرة والتأكيد النهائي يجب أن يبقى تحت الإصبع
/// The pinned save bar: the catalog is long, and the final action must stay under the thumb.
class _SaveBar extends StatelessWidget {
  final AssignPermissionsState state;
  final bool targetIsAdmin;
  final VoidCallback onSave;

  const _SaveBar({
    required this.state,
    required this.targetIsAdmin,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final shadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, -2),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [shadow],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: state.isSaving || !state.isDirty ? null : onSave,
          icon: state.isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            state.isSaving
                ? 'جارٍ الحفظ…'
                : targetIsAdmin
                ? 'حفظ منح المدير (اختياري)'
                : state.isDirty
                ? 'حفظ الصلاحيات'
                : 'لم يتغيّر شيء',
          ),
        ),
      ),
    );
  }
}

/// شريط رسالة داخل الشاشة
/// An in-screen message banner.
class _Banner extends StatelessWidget {
  final String message;
  final Color tone;
  final VoidCallback onClose;

  const _Banner({
    required this.message,
    required this.tone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: tone, fontSize: 13, height: 1.45),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: Icon(Icons.close_rounded, size: 18, color: tone),
          ),
        ],
      ),
    );
  }
}

/// فشل تحميل المنح — الشاشة لا تعرض كتالوجاً فارغاً فتوهم أن المستخدم بلا صلاحيات
/// A failed grants load: showing an empty catalog would falsely imply the user has no permissions.
class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

/// تأكيد الحفظ — وينبّه لإنهاء الجلسات لأن الخادم يفعل ذلك افتراضياً
/// The save confirmation — it warns about session termination because the server does that by
/// default.
Future<bool> _confirmSave(BuildContext context, {required bool mentionSessions}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حفظ الصلاحيات'),
      content: Text(
        mentionSessions
            ? 'سيُستبدل كل منح هذا المستخدم، وستُنهى جلساته المفتوحة تلقائياً ليعود '
              'بصلاحياته الجديدة في طلبه التالي.'
            : 'سيُستبدل كل منح هذا المستخدم. أثر ذلك محدود لأن مدير النظام يتجاوز جدول المنح.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('حفظ'),
        ),
      ],
    ),
  ).then((value) => value == true);
}

/// تأكيد مغادرة التحديد غير المحفوظ
/// Confirm leaving with an unsaved selection.
Future<bool> _confirmDiscard(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تغييرات غير محفوظة'),
      content: const Text(
        'غيّرت التحديد ولم تحفظه. إذا خرجت الآن ستبقى الصلاحيات كما هي عند الخادم.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('البقاء'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('خروج بلا حفظ'),
        ),
      ],
    ),
  ).then((value) => value == true);
}
