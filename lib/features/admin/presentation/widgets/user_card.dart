import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_user_model.dart';

/// أفعال بطاقة المستخدم — مصدر واحد يخدم الشريط العريض وقائمة الإجراءات الضيقة
/// Card actions — one source feeding both the wide action row and the narrow overflow menu.
enum UserCardAction { edit, permissions, toggle, delete, activity }

/// وصف فعل: التسمية والأيقونة والصلاحية المطلوبة
/// An action's label, icon, and the permission it requires.
class _ActionSpec {
  final UserCardAction action;
  final String label;
  final IconData icon;
  final String code;

  const _ActionSpec(
    this.action,
    this.label,
    this.icon,
    this.code,
  );
}

/// الترتيب كما طلبته الخطة: تعديل · صلاحيات · تعطيل/تفعيل · حذف · سجل نشاط
/// The order the plan specifies: edit, permissions, toggle, delete, activity.
const List<_ActionSpec> _specs = [
  _ActionSpec(UserCardAction.edit, 'تعديل', Icons.edit_rounded, Perm.usersUpdate),
  _ActionSpec(
    UserCardAction.permissions,
    'صلاحيات',
    Icons.admin_panel_settings_rounded,
    Perm.usersPermissionsManage,
  ),
  _ActionSpec(
    UserCardAction.toggle,
    'تعطيل',
    Icons.block_rounded,
    Perm.usersToggle,
  ),
  _ActionSpec(
    UserCardAction.delete,
    'حذف',
    Icons.delete_outline_rounded,
    Perm.usersDelete,
  ),
  _ActionSpec(
    UserCardAction.activity,
    'سجل نشاط',
    Icons.history_rounded,
    Perm.usersActivityView,
  ),
];

/// بطاقة مستخدم في قائمة الإدارة
/// A user card in the admin list.
///
/// الأزرار الخمسة كلها خلف `PermissionGate`: الحجب هنا يقرأ نفس المنح التي فرضها الخادم، فلا
/// يظهر زر يردّ عليه بـ 403. وعلى الشاشات الضيقة تتحوّل إلى `PopupMenuButton` لأن خمسة أزرار
/// نصية في صف واحد تنفجر `RenderFlex` — وهو نمط الفشل المسجّل في `responsive_layout_test`.
/// Every button sits behind a PermissionGate, so the client hides exactly what the server refuses.
/// On narrow screens they collapse into a popup menu, because five text buttons in one row blow up
/// RenderFlex — the failure mode this repo already regression-tests.
class UserCard extends ConsumerWidget {
  final AppUserModel user;
  final void Function(UserCardAction action, AppUserModel user) onAction;

  const UserCard({
    required this.user,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 640;

    // قراءة انتقائية: البطاقة إعادة رسمها رخيص لكن حالة المصادقة تتغير كثيراً
    // A targeted read: redrawing a card is cheap, but auth state changes often.
    final currentUserId = ref.watch(
      authNotifierProvider.select((auth) => auth.user?.id),
    );
    final isSelf = currentUserId != null && user.userId == currentUserId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: user.isActivated ? AppColors.border : AppColors.warning,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(user: user, isSelf: isSelf),
              const SizedBox(width: 12),
              Expanded(child: _Identity(user: user, isSelf: isSelf)),
            ],
          ),
          const SizedBox(height: 12),
          if (isNarrow)
            _OverflowMenu(
              user: user,
              isSelf: isSelf,
              onAction: onAction,
            )
          else
            _ActionRow(user: user, isSelf: isSelf, onAction: onAction),
        ],
      ),
    );
  }
}

/// الأفاتار: رقم المستخدم، وأحمر عند التعطيل — تمييز بصري سريع في قائمة طويلة
/// Avatar: the user number, red when deactivated — a fast visual cue in a long list.
class _Avatar extends StatelessWidget {
  final AppUserModel user;
  final bool isSelf;

  const _Avatar({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final color = !user.isActivated
        ? AppColors.error
        : user.isAdmin
        ? AppColors.accent
        : AppColors.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isSelf ? Border.all(color: color, width: 1.6) : null,
      ),
      child: Center(
        child: Text(
          '${user.userId}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// الاسم والسطر الثانوي والشارات
/// Name, secondary line, and badges.
class _Identity extends StatelessWidget {
  final AppUserModel user;
  final bool isSelf;

  const _Identity({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelf) ...[
              const SizedBox(width: 6),
              const _Badge(label: 'أنت', color: AppColors.info),
            ],
          ],
        ),
        if (user.userNameEn.trim().isNotEmpty &&
            user.userNameEn.trim() != user.displayName) ...[
          const SizedBox(height: 2),
          Text(
            user.userNameEn.trim(),
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 5),
        Text(
          'رقم ${user.userId} · ${user.branchLabel} · ${user.userTypeLabel}',
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Badge(
              label: user.isActivated ? 'نشط' : 'معطّل',
              color: user.isActivated ? AppColors.success : AppColors.error,
            ),
            if (user.isAdmin)
              _Badge(label: 'مدير النظام', color: AppColors.accent),
            // العدد من صف القائمة مباشرة: الخادم يحسبه، والواجهة لا تعدّ من جديد
            // The count comes from the list row: the server computes it, the client never re-counts.
            _Badge(
              label: 'صلاحيات: ${user.grantsCount}',
              color: AppColors.textSecondary,
            ),
            if (user.biometricEnabled)
              _Badge(label: 'بصمة', color: AppColors.primary),
          ],
        ),
      ],
    );
  }
}

/// شريط الأزرار للشاشات العريضة
/// The button row for wide screens.
class _ActionRow extends StatelessWidget {
  final AppUserModel user;
  final bool isSelf;
  final void Function(UserCardAction action, AppUserModel user) onAction;

  const _ActionRow({
    required this.user,
    required this.isSelf,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final spec in _specs)
          PermissionGate(
            code: spec.code,
            child: _ActionButton(
              spec: _labelFor(spec, user),
              enabled: _isEnabled(spec.action, isSelf),
              blockedReason: _blockedReason(spec.action, isSelf),
              onTap: () => onAction(spec.action, user),
            ),
          ),
      ],
    );
  }
}

/// قائمة الإجراءات للشاشات الضيقة
/// The overflow menu for narrow screens.
class _OverflowMenu extends ConsumerWidget {
  final AppUserModel user;
  final bool isSelf;
  final void Function(UserCardAction action, AppUserModel user) onAction;

  const _OverflowMenu({
    required this.user,
    required this.isSelf,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // عناصر القائمة لا تقبل التفافاً حولها كويدجت، فيُفلتر كل بند بصلاحية مباشرة من نفس
    // مصدر القرار (`AuthState.can`) الذي يقرأه `PermissionGate` — لا منطقان للحجب
    // Menu items cannot be wrapped per-item widgets, so each entry is filtered by the very same
    // decision source (AuthState.can) that PermissionGate reads — never a second gating logic.
    final allowed = _specs
        .where((spec) => ref.can(spec.code))
        .toList(growable: false);

    if (allowed.isEmpty) {
      return const Text(
        'لا صلاحيات إجراء على هذا الحساب لدى حسابك',
        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PopupMenuButton<UserCardAction>(
        position: PopupMenuPosition.under,
        onSelected: (action) => onAction(action, user),
        itemBuilder: (menuContext) => [
          for (final spec in allowed)
            PopupMenuItem<UserCardAction>(
              enabled: _isEnabled(spec.action, isSelf),
              value: spec.action,
              child: Row(
                children: [
                  Icon(
                    spec.icon,
                    size: 17,
                    color: _isEnabled(spec.action, isSelf)
                        ? AppColors.textSecondary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _labelFor(spec, user).label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'إجراءات',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر إجراء واحد — معطّل بسبب الحماية الذاتية لا بسبب الصلاحية
/// One action button; disabled by self-protection, never by a missing permission (that hides it).
class _ActionButton extends StatelessWidget {
  final _ActionSpec spec;
  final bool enabled;
  final String? blockedReason;
  final VoidCallback onTap;

  const _ActionButton({
    required this.spec,
    required this.enabled,
    required this.onTap,
    this.blockedReason,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (spec.action == UserCardAction.delete
              ? AppColors.error
              : AppColors.primary)
        : AppColors.textMuted;

    final button = InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.07 : 0.04),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );

    if (!enabled && blockedReason != null) {
      return Tooltip(message: blockedReason!, child: button);
    }

    return button;
  }
}

/// تعطيل/تفعيل الاسم حسب الحالة الحالية — البطاقة تعرض الفعل لا الاسم المحايد
/// The toggle's label follows the current state, so the card names the action, not a neutral word.
_ActionSpec _labelFor(_ActionSpec spec, AppUserModel user) {
  if (spec.action != UserCardAction.toggle) return spec;

  return _ActionSpec(
    spec.action,
    user.isActivated ? 'تعطيل' : 'تفعيل',
    user.isActivated ? Icons.block_rounded : Icons.play_circle_outline_rounded,
    spec.code,
  );
}

/// الحماية الذاتية: لا تعطيل ولا حذف ولا منح للذات إلا بمسار الخادم المسموح
/// Self-protection: no self-disable, no self-delete, and self-granting only where the server allows.
bool _isEnabled(UserCardAction action, bool isSelf) {
  if (!isSelf) return true;

  return switch (action) {
    // تعطيل الذات = قفل حسابك فوراً، والخادم ينهي جلساتك — إجراء يجب ألا يكون بضغطة واحدة
    // Disabling yourself locks your own account and the server ends your sessions at once.
    UserCardAction.toggle => false,
    UserCardAction.delete => false,
    // الخادم يرفض تعديل الذات لغير المدير (403)؛ فالمسار الوحيد الآمن هو المدير
    // The server refuses self-edits for non-admins (403), so only an admin may do this.
    UserCardAction.permissions => false,
    UserCardAction.edit => true,
    UserCardAction.activity => true,
  };
}

/// سبب المنع — يظهر في `tooltip` حتى لا يظن المستخدم أن التطبيق معطّل
/// The denial reason, shown as a tooltip so a grey button never reads as a broken app.
String? _blockedReason(UserCardAction action, bool isSelf) {
  if (!isSelf) return null;

  return switch (action) {
    UserCardAction.toggle => 'لا يمكنك تعطيل حسابك الحالي',
    UserCardAction.delete => 'لا يمكنك حذف حسابك الحالي',
    UserCardAction.permissions =>
      'لا يمكنك تعديل صلاحياتك — اطلب من مدير النظام',
    _ => null,
  };
}

/// شارة صغيرة — نفس شكل شارات العملاء لتبقى القائمة مألوفة
/// A small badge — the same shape as the customer list's, keeping the look familiar.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
