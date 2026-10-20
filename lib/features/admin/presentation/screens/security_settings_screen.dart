import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_security_setting_model.dart';
import '../providers/security_settings_provider.dart';
import '../widgets/setting_tile.dart';

/// مجموعة إعدادات كما تُعرض في الـ `ExpansionTile`
/// A settings group as rendered in one ExpansionTile.
class _Group {
  final String title;
  final IconData icon;
  final Color tone;
  final List<AppSecuritySettingModel> settings;

  const _Group({
    required this.title,
    required this.icon,
    required this.tone,
    required this.settings,
  });
}

/// تجميع المفاتيح بأربع مجموعات كما طلبت الخطة (§8.4 ز)
/// Bucket the keys into the four groups the plan specifies.
///
/// التجميع بمسابقة بادئة المفتاح لا بقائمة نصية ثابتة: البذر في القاعدة قد يضيف مفتاحاً جديداً
/// غداً، وقائمة مكتوبة هنا ستُسقطه بصمت من الشاشة. المفتاح المجهول يقع في «أخرى» فيبقى مرئياً.
/// Bucketing matches on the key prefix rather than a hardcoded key list: the seeded table can gain
/// a key tomorrow, and a list written here would silently drop it. Unknown keys land in «أخرى» so
/// they stay visible.
String _groupTitleOf(String key) {
  if (key.startsWith('session_')) return 'الجلسات';
  if (key.startsWith('password_')) return 'كلمة المرور';
  if (key.startsWith('activity_')) return 'السجل';
  if (key == 'biometric_login_enabled' ||
      key == 'max_failed_logins' ||
      key == 'lockout_minutes') {
    return 'الدخول';
  }

  return 'أخرى';
}

/// شاشة إعدادات الأمان — قراءة وكتابة `APP_SETTINGS` عبر `PUT /settings`
/// The security settings screen: reading and writing APP_SETTINGS through PUT /settings.
///
/// المفاتيح وحدودها تأتي كلها من الخادم: لا مدى مكرر هنا ولا `password_min_length` مكتوب حرفياً،
/// لأن الخادم هو من يرفض القيم ويحدّد الأدنى المسموح (`max(4, …)`).
/// Every key and bound comes from the server: no duplicated range and no literal
/// password_min_length here, because the server is what rejects values and sets the floor.
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securitySettingsProvider);
    final notifier = ref.read(securitySettingsProvider.notifier);
    final canUpdate = ref.watch(
      authNotifierProvider.select((auth) => auth.can(Perm.settingsUpdate)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اعدادات الامان'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                // بلا صلاحية كتابة تظل القراءة ممكنة: المراجعة جزء من العمل اليومي للمدير
                // Reading stays possible without write rights: reviewing is routine admin work.
                onRefresh: notifier.load,
                child: _Body(state: state, notifier: notifier),
              ),
            ),
            _SaveBar(
              state: state,
              notifier: notifier,
              canUpdate: canUpdate,
            ),
          ],
        ),
      ),
    );
  }
}

/// جسم الشاشة بالحالات الأربع
/// The body with its four states.
class _Body extends ConsumerWidget {
  final SecuritySettingsState state;
  final SecuritySettingsNotifier notifier;

  const _Body({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.settings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.settings.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline_rounded, size: 42, color: AppColors.error),
          const SizedBox(height: 10),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          Center(
            child: FilledButton.tonal(
              onPressed: notifier.load,
              child: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (state.settings.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 80),
          Icon(Icons.settings_outlined, size: 42, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'لا إعدادات معروفة',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'جدول APP_SETTINGS بلا صفوف مبذورة بعد — لا يمكن ضبط شيء قبل زراعته.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      );
    }

    final groups = _groupsOf(state.settings);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 20),
      children: [
        const _OwnSessionCard(),
        const SizedBox(height: 12),
        if (!canWrite(ref))
          const _ReadOnlyNote()
        else
          const _AppliesNowNote(),
        const SizedBox(height: 10),
        ...groups.map(
          (group) => _GroupCard(
            group: group,
            state: state,
            notifier: notifier,
          ),
        ),
        if (state.message != null) ...[
          const SizedBox(height: 12),
          _ResultNote(message: state.message!),
        ],
      ],
    );
  }

  /// هل تكتب الشاشة؟ التعديل العادي يحتاج `settings.update` والمقفول `settings.security_manage`
  /// Can the screen write? Ordinary edits need settings.update, locked keys security_manage.
  bool canWrite(WidgetRef ref) => ref.watch(
    authNotifierProvider.select(
      (auth) =>
          auth.can(Perm.settingsUpdate) || auth.can(Perm.settingsSecurityManage),
    ),
  );

  /// تجميع المجموعات بترتيب ثابت حتى لا تقفز الأقسام بين التحديثات
  /// Group with a stable order so the sections cannot jump between refreshes.
  List<_Group> _groupsOf(List<AppSecuritySettingModel> settings) {
    final buckets = <String, List<AppSecuritySettingModel>>{};
    for (final setting in settings) {
      buckets.putIfAbsent(_groupTitleOf(setting.key), () => []).add(setting);
    }

    const order = ['الجلسات', 'كلمة المرور', 'الدخول', 'السجل', 'أخرى'];
    final icons = <String, (IconData, Color)>{
      'الجلسات': (Icons.timer_outlined, AppColors.info),
      'كلمة المرور': (Icons.password_rounded, AppColors.primary),
      'الدخول': (Icons.fingerprint_rounded, AppColors.accent),
      'السجل': (Icons.history_rounded, AppColors.warning),
      'أخرى': (Icons.tune_rounded, AppColors.secondary),
    };

    return [
      for (final title in order)
        if (buckets.containsKey(title))
          _Group(
            title: title,
            icon: icons[title]!.$1,
            tone: icons[title]!.$2,
            settings: buckets[title]!,
          ),
    ];
  }
}

/// بطاقة مجموعة واحدة — مفتوحة أولاً لأنها الشاشة الوحيدة في قسمها
/// One group card, expanded since it is the only screen in its section.
class _GroupCard extends ConsumerWidget {
  final _Group group;
  final SecuritySettingsState state;
  final SecuritySettingsNotifier notifier;

  const _GroupCard({
    required this.group,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: group.tone.withValues(alpha: 0.12),
          child: Icon(group.icon, size: 20, color: group.tone),
        ),
        title: Text(
          group.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
        ),
        subtitle: Text(
          '${group.settings.length} مفتاح',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                for (final setting in group.settings)
                  SettingTile(
                    setting: setting,
                    pendingValue: state.currentValueOf(setting),
                    editable: _editableFor(setting, ref),
                    onChanged: (value) => notifier.edit(setting.key, value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// المفتاح المقفل يحتاج صلاحية أعلى، وبدونها يبقى ظاهراً للقراءة: التدقيق يتطلب رؤية
  /// القيمة الجارية حتى على من لا يملك تعديلها.
  /// A locked key needs the higher grant; without it the tile stays read-only, since auditing
  /// requires seeing the current value even for someone who cannot change it.
  bool _editableFor(AppSecuritySettingModel setting, WidgetRef ref) {
    final required = setting.isLockable
        ? Perm.settingsSecurityManage
        : Perm.settingsUpdate;

    return ref.watch(authNotifierProvider.select((auth) => auth.can(required)));
  }
}

/// بطاقة «تنتهي جلستك في …» من `session_expires_at` الذي أرسله `/auth/me`
/// The «your session ends in …» card, from the deadline /auth/me asserted.
class _OwnSessionCard extends ConsumerWidget {
  const _OwnSessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiresAt = ref.watch(
      authNotifierProvider.select((auth) => auth.sessionExpiresAt),
    );
    if (expiresAt == null) return const SizedBox.shrink();

    final minutes = expiresAt.difference(DateTime.now()).inMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom_rounded,
            size: 22,
            color: minutes <= 0 ? AppColors.error : AppColors.info,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جلستك الحالية',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  minutes <= 0
                      ? 'انتهت — ستُطرد عند أول طلب بلا صلاحية.'
                      : 'تنتهي خلال $minutes دقيقة، وتُجدَّد تلقائياً مع كل طلب.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// تلميح «يُطبَّق مباشرة» — حتى لا يظن المدير أن الحفظ يتطلب إعادة تشغيل
/// The «applies immediately» hint, so a save is not mistaken for a restart requirement.
class _AppliesNowNote extends StatelessWidget {
  const _AppliesNowNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, size: 18, color: AppColors.info),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'يطبَّق الحفظ على الطلبات التالية مباشرة — الجلسات المفتوحة تبقى بمدة إنشائها.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// توضيح القراءة فقط حين لا صلاحية كتابة
/// The read-only explanation when there is no write grant.
class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: AppColors.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'أنت تقرأ فقط: الحفظ يحتاج settings.update، والمفاتيح المقفلة settings.security_manage.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

/// رسالة نجاح الحفظ من الخادم
/// The server's save-success message.
class _ResultNote extends StatelessWidget {
  final String message;

  const _ResultNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// توضيح يظهر بدل زر الحفظ لمن يقرأ ولا يكتب
/// The note that replaces the save button for a reader without write rights.
class _LockedSaveNote extends StatelessWidget {
  const _LockedSaveNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'بلا صلاحية حفظ',
      style: TextStyle(fontSize: 12.5, color: AppColors.error),
    );
  }
}

/// شريط الحفظ السفلي: لا يُعرض إلا مع تغيير محلي وصلاحية كتابة
/// The bottom save bar — shown only with a local edit and write rights.
class _SaveBar extends StatelessWidget {
  final SecuritySettingsState state;
  final SecuritySettingsNotifier notifier;
  final bool canUpdate;

  const _SaveBar({
    required this.state,
    required this.notifier,
    required this.canUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.isDirty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${state.pendingCount} مفتاح معدَّل بانتظار الحفظ',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: state.isSaving ? null : notifier.resetPending,
              child: const Text('تجاهل'),
            ),
            const SizedBox(width: 8),
            // بصلاحية الحفظ فقط: زرّ يظهر بلا صلاحية يعني رحلة ذهاب وعودة إلى 403
            // The button appears only with the grant: showing it otherwise buys a round trip to 403.
            if (canUpdate) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: state.isSaving ? null : () => _save(context),
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
                label: const Text('حفظ'),
              ),
            ] else
              const _LockedSaveNote(),
          ],
        ),
      ),
    );
  }

  /// الحفظ مع تأكيد: هذه المفاتيح تحدد من يبقى داخل النظام ومتى يُطرد
  /// Saving with confirmation: these keys decide who stays signed in and for how long.
  Future<void> _save(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حفظ إعدادات الأمان'),
        content: const Text(
          'تغيير مدد الجلسات أو سياسات الدخول يؤثر على كل من متصل الآن عند أول طلب قادم.',
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
    );
    if (confirmed != true || !context.mounted) return;

    final result = await notifier.save();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.displayMessage),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
