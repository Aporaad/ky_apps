import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_user_model.dart';
import '../widgets/user_picker_screen.dart';
import 'active_sessions_screen.dart';
import 'admin_users_screen.dart';
import 'permissions_catalog_screen.dart';
import 'security_settings_screen.dart';
import 'user_activity_screen.dart';

/// بطاقة لوحة الإدارة: العنوان والوصف والرمز واللون وصلاحية الفتح ووجهتها
/// A dashboard card: title, description, icon, colour, the gate code, and where it goes.
class _AdminCard {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String code;

  /// الوجهة المباشرة — تُدفع عند اللمس إن وُجدت
  /// The direct destination, pushed on tap when present.
  final Widget Function()? screen;

  /// أو مسار متعدد الخطوات — كالسجل الذي يختار مستخدماً أولاً ثم يفتح سجله
  /// Or a multi-step route: the trail picks a user before opening its log.
  final Future<void> Function(BuildContext context)? flow;

  const _AdminCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.code,
    this.screen,
    this.flow,
  }) : assert(
         screen != null || flow != null,
         'كل بطاقة تحتاج وجهاً تُفتح عليه',
       );

  Future<void> open(BuildContext context) async {
    final custom = flow;
    if (custom != null) {
      await custom(context);

      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen!()),
    );
  }
}

/// لوحة الإدارة — تحلّ محل `ManagementSection` الفارغة
/// The management dashboard, replacing the empty `ManagementSection`.
///
/// البطاقات تُبنى من قائمة واحدة ثم يُغلَّف كل منها بحاجزه الخاص: إضافة بطاقة جديدة لا تتطلب
/// شروطاً مبعثرة. البطاقة المحجوبة تختفي لا تُطفأ، لأن زرّاً معطّلاً يعلن عن صلاحية محروم منها
/// المستخدم.
/// Cards come from one list and each is wrapped in its own gate, so a new card needs no scattered
/// conditionals. A denied card disappears rather than greys out: a disabled button advertises a
/// capability the user is denied.
///
/// تُرسم داخل `IndexedStack` القسم، فلا `Scaffold` هنا — نفس ما تفعله شاشة العملاء.
/// It renders inside the section's IndexedStack, so there is no Scaffold, exactly like customers.
class ManagementDashboardScreen extends ConsumerWidget {
  const ManagementDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 600 ? 16.0 : 24.0;
    final crossAxisCount = width < 480
        ? 1
        : width < 900
        ? 2
        : 3;

    // هل توجد أي بطاقة مسموحة؟ الحالة الفارغة هنا أمنية: مستخدم بلا أي صلاحية إدارة يجب أن
    // يقرأ تفسيراً لا شبكة بيضاء تُوهم أن النظام معطّل.
    // Is any card allowed? The empty state is a security matter: a user with no admin grant should
    // read an explanation, not stare at a blank grid that looks like an outage.
    final allowed = ref.watch(
      authNotifierProvider.select(
        (auth) =>
            auth.canAny(const [
              Perm.usersView,
              Perm.sessionsView,
              Perm.settingsView,
            ]),
      ),
    );

    final cards = _cards(context, ref);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(compact: width < 600),
          SizedBox(height: width < 600 ? 18 : 26),
          if (!allowed)
            const _NoAccessNote()
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: crossAxisCount == 1 ? 2.6 : 1.65,
                ),
                itemBuilder: (context, index) => PermissionGate(
                  code: cards[index].code,
                  child: _CardTile(card: cards[index]),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const _SessionHint(),
        ],
      ),
    );
  }

  /// البطاقات الخمس المطلوبة في الخطة (§8.4 أ) بترتيبها
  /// The five cards the plan specifies, in order.
  List<_AdminCard> _cards(BuildContext context, WidgetRef ref) {
    return [
      _AdminCard(
        title: 'إدارة المستخدمين',
        description: 'إنشاء وتعديل وتفعيل حسابات النظام',
        icon: Icons.manage_accounts_outlined,
        color: AppColors.primary,
        code: Perm.usersView,
        screen: () => const AdminUsersScreen(),
      ),
      _AdminCard(
        title: 'الجلسات النشطة',
        description: 'توكنات الدخول المتصلة الآن وإنهاؤها',
        icon: Icons.devices_other_outlined,
        color: AppColors.accent,
        code: Perm.sessionsView,
        screen: () => const ActiveSessionsScreen(),
      ),
      _AdminCard(
        title: 'اعدادات الامان',
        description: 'مدد الجلسات وكلمة المرور والدخول والسجل',
        icon: Icons.shield_outlined,
        color: AppColors.info,
        code: Perm.settingsView,
        screen: () => const SecuritySettingsScreen(),
      ),
      _AdminCard(
        title: 'كتالوج الصلاحيات',
        description: 'قائمة الأكواد كاملة بأقسامها ووصفها',
        icon: Icons.key_outlined,
        color: AppColors.success,
        code: Perm.usersView,
        screen: () => const PermissionsCatalogScreen(),
      ),
      _AdminCard(
        title: 'سجل النشاط',
        description: 'ما نفّذه كل مستخدم من عمليات ناجحة أو مرفوضة',
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        code: Perm.usersActivityView,
        // لا مسار «سجل عام» في الخادم (§7.4): يُختار المستخدم أولاً ثم يُفتح سجله وحده.
        // There is no server-side general trail, so a user is picked first.
        flow: (context) => _openTrail(context),
      ),
    ];
  }

  /// منتقي مستخدم ← سجل نشاط؛ والـ `mounted` إلزامي لأن الشاشة قد تُغلق أثناء الاختيار
  /// Picker then trail; the mounted check is required because the dashboard can be popped away.
  Future<void> _openTrail(BuildContext context) async {
    final picked = await Navigator.of(context).push<AppUserModel>(
      MaterialPageRoute(
        builder: (_) => const UserPickerScreen(
          title: 'سجل النشاط',
          subtitle: 'اختر مستخدماً لعرض سجل عملياته',
        ),
      ),
    );
    if (picked == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserActivityScreen(
          userId: picked.userId,
          userName: picked.displayName,
        ),
      ),
    );
  }
}

/// رأس اللوحة: شارة رمزية وعنوان وتحت-عنوان
/// The dashboard header: a badge, the title, and the caption.
class _Header extends StatelessWidget {
  final bool compact;

  const _Header({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.admin_panel_settings_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإدارة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                compact
                    ? 'الصلاحيات والجلسات وأمان النظام'
                    : 'صلاحيات المستخدمين، الجلسات النشطة، وإعدادات الأمان',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// بطاقة واحدة قابلة للضغط
/// One tappable card.
class _CardTile extends StatelessWidget {
  final _AdminCard card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => card.open(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(card.icon, color: card.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// توضيح حين لا صلاحية إدارة إطلاقاً
/// Explains why the dashboard is empty for a user with no admin grants.
class _NoAccessNote extends StatelessWidget {
  const _NoAccessNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outline, size: 34, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'لا تملك صلاحية الدخول إلى أدوات الإدارة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'اطلب من مدير النظام منحك users.view أو ما يعادلها لتظهر البطاقات.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// تلميح الجلسة الحالية أسفل اللوحة — من `session_expires_at` الذي أرسله الخادم
/// Current-session hint under the dashboard, read from the server's session_expires_at.
class _SessionHint extends ConsumerWidget {
  const _SessionHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiresAt = ref.watch(
      authNotifierProvider.select((auth) => auth.sessionExpiresAt),
    );
    if (expiresAt == null) return const SizedBox.shrink();

    final minutes = expiresAt.difference(DateTime.now()).inMinutes;
    if (minutes <= 0) return const SizedBox.shrink();

    // الدقائق العشر الأولى إنذار بصري: من يقرأ «9 دقائق» يحتاج أن يلمحها قبل أن يضيع عمله
    // The last ten minutes go amber: a reader of «9 minutes» needs to notice before losing work.
    final warning = minutes <= 10;
    final tone = warning ? AppColors.warning : AppColors.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            warning ? Icons.timer_outlined : Icons.info_outline,
            size: 18,
            color: tone,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنتهي جلستك الحالية خلال $minutes دقيقة — تُجدَّد تلقائياً مع كل طلب.',
              style: TextStyle(fontSize: 12.5, color: tone),
            ),
          ),
        ],
      ),
    );
  }
}
