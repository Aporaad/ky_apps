import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_user_model.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_filter_sheet.dart';
import '../widgets/user_card.dart';
import 'add_user_screen.dart';
import 'assign_permissions_screen.dart';
import 'edit_user_screen.dart';
import 'user_activity_screen.dart';

/// شاشة إدارة المستخدمين — القائمة مع البحث والفلترة والفرز والتصفح
/// The admin users screen: the list with search, filters, sorting, and paging.
///
/// القائمة لا تُفلتَر ولا تُفرَز محلياً إطلاقاً: الخادم هو الذي يترتيب ويعُدّ، والقطع المحلي
/// لصفحة واحدة يُظهر «عرض 20 من 20» بينما القاعدة تحوي المئات. البحث يمرّ للمزوّد بعد 300ms
/// من السكون، وهو نفس تأخير شاشة العملاء.
/// Nothing is filtered or sorted client-side: the server orders and counts, and slicing locally
/// would claim «عرض 20 من 20» while the table holds hundreds. Search reaches the notifier after
/// 300 ms of silence, the same delay the customers screen uses.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // القائمة تُحمَّل من `build()` المزود؛ هنا فقط تُسرق القيمة الجارية لو رُجع للشاشة
    // The notifier loads in its own build(); this only re-syncs the field when returning here.
    final current = ref.read(adminUsersProvider).search;
    if (current.isNotEmpty) _searchCtrl.text = current;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// بحث مؤجَّل 300ms — كل ضغطة على لوحة المفاتيح كانت ستطلق طلباً كاملاً إلى القاعدة
  /// 300 ms debounced search — otherwise every keystroke fires a full query.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(adminUsersProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final notifier = ref.read(adminUsersProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          if (state.hasActiveFilters)
            IconButton(
              tooltip: 'مسح الفلاتر والبحث',
              icon: const Icon(Icons.filter_alt_off_outlined),
              // `clearFilters` يترك البحث عمداً، فالزر الذي يقول «مسح» يجب أن يمسح الاثنين
              // clearFilters keeps the search term on purpose, so this button clears both.
              onPressed: () {
                _searchCtrl.clear();
                notifier.setSearch('');
                notifier.clearFilters();
              },
            ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width < 600 ? 12 : 20,
            vertical: 12,
          ),
          child: Column(
            children: [
              _TopBar(
                onAdd: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddUserScreen()),
                  );
                  // العودة من الإنشاء: القائمة تحمل الأرقام الجديدة، فتحديثها أرخص من خطأ «موجود»
                  // Coming back from create: refresh so the new row and its counters are true.
                  if (mounted) await notifier.refresh();
                },
              ),
              const SizedBox(height: 12),
              _SearchBar(
                controller: _searchCtrl,
                state: state,
                onChanged: _onSearchChanged,
                onClear: () {
                  _searchCtrl.clear();
                  notifier.setSearch('');
                },
                onFilter: () async {
                  final choice = await showAdminFilterSheet(
                    context,
                    AdminUserFilterChoice(
                      status: state.status,
                      userType: state.userType,
                      adminOnly: state.adminOnly,
                    ),
                  );
                  if (choice == null || !mounted) return;
                  await notifier.applyFilters(
                    status: choice.status,
                    userType: choice.userType,
                    adminOnly: choice.adminOnly,
                  );
                },
                onSort: () async {
                  final picked = await showUserSortSheet(
                    context,
                    sort: state.sort,
                    direction: state.direction,
                  );
                  if (picked == null || !mounted) return;
                  await notifier.applySort(picked.column, picked.direction);
                },
              ),
              const SizedBox(height: 10),
              _CountLine(state: state),
              const SizedBox(height: 8),
              Expanded(child: _Body(state: state, notifier: notifier)),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط الإضافة أعلى القائمة — خلف حاجز `users.create` كما طلبت الخطة
/// The add-user bar above the list, behind the users.create gate.
class _TopBar extends StatelessWidget {
  final Future<void> Function() onAdd;

  const _TopBar({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'الحسابات التي تدخل التطبيق وتُمنح الصلاحيات',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        PermissionGate(
          code: Perm.usersCreate,
          child: FilledButton.icon(
            onPressed: () => onAdd(),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text('إضافة مستخدم'),
          ),
        ),
      ],
    );
  }
}

/// شريط البحث + أيقونتا الفلترة والفرز
/// Search field plus the filter and sort icons.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AdminUsersState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Future<void> Function() onFilter;
  final Future<void> Function() onSort;

  const _SearchBar({
    required this.controller,
    required this.state,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final activeFilters = AdminUserFilterChoice(
      status: state.status,
      userType: state.userType,
      adminOnly: state.adminOnly,
    ).activeCount;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم المستخدم…',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: state.search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: onClear,
                      tooltip: 'مسح البحث',
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconButtonBadge(
          icon: Icons.filter_alt_outlined,
          count: activeFilters,
          tooltip: 'فلترة',
          onPressed: onFilter,
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'فرز (${state.sort})',
          icon: const Icon(Icons.sort_rounded),
          onPressed: () => onSort(),
        ),
      ],
    );
  }
}

/// زر فلترة يحمل عدد الفلاتر المفتوحة — حتى لا يُنسى فلتر فعّال ويبدو الصفّ خطأً
/// A filter button carrying the active-filter count, so a live filter is never forgotten.
class _IconButtonBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final String tooltip;
  final Future<void> Function() onPressed;

  const _IconButtonBadge({
    required this.icon,
    required this.count,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: count > 0 ? AppColors.primary : null),
      onPressed: () => onPressed(),
    );
    if (count == 0) return button;

    return Badge.count(count: count, child: button);
  }
}

/// سطر «عرض N من E» — يعدّ الصفحة لا القاعدة، فيُقال ذلك صراحة
/// The «showing N of E» line — N is the page, and the label says so.
class _CountLine extends StatelessWidget {
  final AdminUsersState state;

  const _CountLine({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.users.isEmpty) return const SizedBox.shrink();

    final shown = state.users.length;

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'عرض $shown من ${state.total} حساباً · صفحة ${state.page} من ${state.pages == 0 ? 1 : state.pages}',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}

/// جسم الشاشة بالحالات الأربع: تحميل / بيانات / فارغ / خطأ
/// The body with the four mandated states: loading, data, empty, error.
class _Body extends ConsumerWidget {
  final AdminUsersState state;
  final AdminUsersNotifier notifier;

  const _Body({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.users.isEmpty) {
      return _ErrorState(message: state.error!, onRetry: notifier.refresh);
    }

    if (state.users.isEmpty) {
      return _EmptyState(hasFilters: state.hasActiveFilters, notifier: notifier);
    }

    final currentUserId = ref.watch(
      authNotifierProvider.select((auth) => auth.user?.id),
    );

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: state.users.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.users.length) {
            return _NextPageButton(
              page: state.page,
              pages: state.pages,
              notifier: notifier,
            );
          }
          final user = state.users[index];

          return UserCard(
            user: user,
            onAction: (action, target) => _handle(
              context,
              ref,
              action,
              target,
              notifier,
              isSelf: currentUserId == target.userId,
            ),
          );
        },
      ),
    );
  }

  /// توزيع أفعال البطاقة — كل فعل يعيد القائمة عند الحاجة ويُظهر رسالة الخادم
  /// Card action dispatch: each path reloads when needed and shows the server's own message.
  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    UserCardAction action,
    AppUserModel user,
    AdminUsersNotifier notifier, {
    required bool isSelf,
  }) async {
    switch (action) {
      case UserCardAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditUserScreen(user: user)),
        );
        notifier.refresh();

      case UserCardAction.permissions:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AssignPermissionsScreen(userId: user.userId, userName: user.displayName),
          ),
        );
        // عدّاد «صلاحيات: N» في البطاقة يأتي من الخادم، فلا يُحدَّث محلياً بعد الحفظ
        // The grant count comes from the server, so it is re-read rather than patched locally.
        notifier.refresh();

      case UserCardAction.activity:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                UserActivityScreen(userId: user.userId, userName: user.displayName),
          ),
        );

      case UserCardAction.toggle:
        await _toggle(context, notifier, user, isSelf);

      case UserCardAction.delete:
        await _delete(context, notifier, user);
    }
  }

  /// تعطيل/تفعيل بعد تأكيد — والخادم يُنهي جلسات المستخدم المعطَّل في العملية نفسها
  /// Toggle after confirmation — the server ends that user's sessions in the same call.
  Future<void> _toggle(
    BuildContext context,
    AdminUsersNotifier notifier,
    AppUserModel user,
    bool isSelf,
  ) async {
    final turning = user.isActivated;
    final confirmed = await _confirm(
      context,
      title: turning ? 'تعطيل الحساب' : 'تفعيل الحساب',
      message: turning
          ? 'سيُمنع «${user.displayName}» من الدخول، وستُنهى جميع جلساته الحالية فوراً.'
          : 'سيعود «${user.displayName}» قادراً على الدخول بجلسة جديدة.',
      confirmLabel: turning ? 'تعطيل' : 'تفعيل',
      danger: turning,
    );
    if (!confirmed || !context.mounted) return;

    final result = await notifier.toggleUser(user.userId);
    if (!context.mounted) return;
    _showResult(context, success: result.success, message: result.displayMessage);
  }

  /// حذف بعد تأكيد مشدّد — الحذف يمسح المنح والتوكنات ويُبقي سجل التدقيق
  /// Delete after a firm confirmation — deletion clears grants and tokens but keeps the audit.
  Future<void> _delete(
    BuildContext context,
    AdminUsersNotifier notifier,
    AppUserModel user,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'حذف المستخدم نهائياً',
      message:
          'سيُحذف «${user.displayName}» مع كل صلاحياته وجلساته. لا يمكن التراجع عن هذا الإجراء، '
          'وستبقى سجلات نشاطه في التدقيق فقط.',
      confirmLabel: 'حذف',
      danger: true,
    );
    if (!confirmed || !context.mounted) return;

    final result = await notifier.deleteUser(user.userId);
    if (!context.mounted) return;
    _showResult(context, success: result.success, message: result.displayMessage);
  }
}

/// زر الصفحة التالية — يبقى في آخر القائمة بدل شريط تنقّل ينفجر عرضاً على الهاتف
/// Next-page button at the tail of the list, instead of a navigation bar that overflows on phones.
class _NextPageButton extends StatelessWidget {
  final int page;
  final int pages;
  final AdminUsersNotifier notifier;

  const _NextPageButton({
    required this.page,
    required this.pages,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => notifier.goToPage(page + 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text('الصفحة التالية (${page + 1}/$pages)'),
          ),
        ],
      ),
    );
  }
}

/// حالة الخطأ مع إعادة محاولة
/// The error state with a retry.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _CenteredNotice(
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
      title: 'تعذّر تحميل المستخدمين',
      body: message,
      actionLabel: 'إعادة المحاولة',
      onAction: () => onRetry(),
    );
  }
}

/// حالة الفراغ — وتختلف رسالتها عند وجود فلاتر لأن السبب مختلف
/// The empty state, whose wording changes under filters because the cause differs.
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final AdminUsersNotifier notifier;

  const _EmptyState({required this.hasFilters, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return _CenteredNotice(
      icon: hasFilters ? Icons.filter_alt_off_outlined : Icons.group_outlined,
      color: AppColors.textMuted,
      title: hasFilters ? 'لا يوجد مستخدمون مطابقون' : 'لا يوجد مستخدمون بعد',
      body: hasFilters
          ? 'جرّب توسيع الفلاتر أو مسح البحث الحالي.'
          : 'أضف أول مستخدم ليتمكن فريقك من الدخول إلى التطبيق.',
      actionLabel: hasFilters ? 'مسح الفلاتر' : null,
      onAction: hasFilters ? notifier.clearFilters : null,
    );
  }
}

/// لوحة مركزية مشتركة للحالتين — تفادياً لانزلاق نصّي بين نسختين من نفس التخطيط
/// One shared centered panel, so the two states cannot drift apart in layout.
class _CenteredNotice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredNotice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 44, color: color),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 14),
          Center(
            child: FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );
  }
}

/// نافذة تأكيد موحّدة لأفعال البطاقة الخطرة
/// One confirmation dialog for the card's risky actions.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final tone = danger ? AppColors.error : AppColors.primary;

  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: tone),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return answer == true;
}

/// رسالة نتيجة العملية — بلون النجاح أو الفشل، ورسالة الخادم كما هي لا ترجمة محلية
/// The operation result snackbar — the server's own text, never a locally invented one.
void _showResult(
  BuildContext context, {
  required bool success,
  required String message,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
