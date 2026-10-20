import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_session_model.dart';
import '../../data/models/app_user_model.dart';
import '../providers/active_sessions_provider.dart';
import '../widgets/session_card.dart';
import '../widgets/user_picker_screen.dart';

/// شاشة الجلسات النشطة — توكنات Sanctum كما يراها الخادم
/// The sessions screen: Sanctum tokens as the server reports them.
///
/// مؤقّت واحد للشاشة كلها لا لكل بطاقة: العشرون بطاقة كانت ستصنع عشرين مصدراً لإعادة الرسم كل
/// دقيقة، والوقت المتبقي حسابٌ على `expires_at` لا حالة تحتاج تنبيهاً مستقلاً.
/// One timer for the whole screen rather than one per card: twenty cards would be twenty rebuild
/// sources every minute, and remaining time is arithmetic on expires_at, not independent state.
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _ticker;
  Timer? _debounce;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // الدقة الدقيقة تكفي: المتبقي يُعرض بالساعات والدقائق لا بالثواني
    // A minute of resolution is enough — the remaining time is shown in hours and minutes.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    Future.microtask(() => ref.read(activeSessionsProvider.notifier).load());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(activeSessionsProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeSessionsProvider);
    final notifier = ref.read(activeSessionsProvider.notifier);
    final canTerminate = ref.watch(
      authNotifierProvider.select((auth) => auth.can(Perm.sessionsTerminate)),
    );
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الجلسات النشطة'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width < 600 ? 12 : 20,
            vertical: 10,
          ),
          child: Column(
            children: [
              _UserFilter(notifier: notifier, focusedUserId: state.userId),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم المستخدم أو رقمه…',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
              const SizedBox(height: 8),
              _StatusChips(status: state.status, onSelect: notifier.setStatus),
              const SizedBox(height: 6),
              _Summary(state: state),
              Expanded(child: _List(state: state, notifier: notifier, now: _now, canTerminate: canTerminate)),
            ],
          ),
        ),
      ),
    );
  }
}

/// فلتر المستخدم — يضيّق الشاشة على جلسات شخص واحد عبر `focusUser`
/// The user filter: narrows the screen to one person's sessions through focusUser.
class _UserFilter extends ConsumerWidget {
  final ActiveSessionsNotifier notifier;
  final int? focusedUserId;

  const _UserFilter({required this.notifier, required this.focusedUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Text(
            focusedUserId == null
                ? 'كل المستخدمين'
                : 'مقتصرة على المستخدم رقم $focusedUserId',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        if (focusedUserId != null)
          TextButton(
            onPressed: () => notifier.focusUser(null),
            child: const Text('إلغاء التضييق'),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await Navigator.of(context).push<AppUserModel>(
              MaterialPageRoute(
                builder: (_) => const UserPickerScreen(
                  title: 'جلسات مستخدم',
                  subtitle: 'اختر مستخدماً لعرض جلساته',
                ),
              ),
            );
            if (picked == null || !context.mounted) return;
            await notifier.focusUser(picked.userId);
          },
          icon: const Icon(Icons.person_search_rounded, size: 18),
          label: const Text('مستخدم'),
        ),
      ],
    );
  }
}

/// رقائق الحالة — الحالة تُرسل للخادم لأن الصف المنتهي يبقى مرئياً في الجدول
/// Status chips: the filter is a query param, since expired rows stay visible in the table.
class _StatusChips extends StatelessWidget {
  final String status;
  final ValueChanged<String> onSelect;

  const _StatusChips({required this.status, required this.onSelect});

  static const List<(String, String)> _options = [
    ('all', 'الكل'),
    ('active', 'النشطة فقط'),
    ('expired', 'المنتهية'),
    ('disabled', 'حساب معطّل'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((option) {
        final selected = option.$1 == status;

        return ChoiceChip(
          label: Text(option.$2),
          selected: selected,
          onSelected: (_) => onSelect(option.$1),
          showCheckmark: false,
          selectedColor: AppColors.accent.withValues(alpha: 0.16),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.accent : AppColors.textSecondary,
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// سطر الملخص: النشطة من الإجمالي — وهو ما يبرر وجود الشاشة أصلاً
/// The summary line: how many are live out of the total, which is the screen's whole point.
class _Summary extends StatelessWidget {
  final ActiveSessionsState state;

  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.sessions.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${state.activeCount} جلسة نشطة من ${state.total} · صفحة ${state.page} من ${state.pages == 0 ? 1 : state.pages}',
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}

/// قائمة الجلسات بالحالات الأربع وأزرار الإنهاء
/// The sessions list: four states plus the termination actions.
class _List extends ConsumerStatefulWidget {
  final ActiveSessionsState state;
  final ActiveSessionsNotifier notifier;
  final DateTime now;
  final bool canTerminate;

  const _List({
    required this.state,
    required this.notifier,
    required this.now,
    required this.canTerminate,
  });

  @override
  ConsumerState<_List> createState() => _ListState();
}

/// الحالة لا الودجت: نوافذ الحوار ورسائل النتيجة تحتاج `context` و`mounted` بعد انتظار المستخدم،
/// و`ConsumerWidget` لا يملك أياً منهما — فحوارٌ مفتوح عند إلغاء الشاشة كان سيتراجع برسالة على
/// سياقٍ ميت.
/// The state, not the widget: the dialogs and result toasts need `context` and `mounted` after
/// waiting on the user, and a ConsumerWidget has neither — a dialog answered after the screen was
/// dismissed would have spoken to a dead context.
class _ListState extends ConsumerState<_List> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = widget.notifier;
    final now = widget.now;
    final canTerminate = widget.canTerminate;

    if (state.isLoading && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 10),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: notifier.load,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.sessions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 70),
          const Icon(
            Icons.wifi_off_rounded,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'لا توجد جلسات مطابقة',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'لا دخول مفتوحاً الآن عند هذا الفلتر — أي جلسة تُنهى تبقى في السجل بحالة منتهية.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          if (state.status != 'all') ...[
            const SizedBox(height: 14),
            Center(
              child: FilledButton.tonal(
                onPressed: () => notifier.setStatus('all'),
                child: const Text('عرض كل الحالات'),
              ),
            ),
          ],
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: state.sessions.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.sessions.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () => notifier.goToPage(state.page + 1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text('الصفحة التالية (${state.page + 1}/${state.pages})'),
                ),
              ),
            );
          }
          final session = state.sessions[index];

          return SessionCard(
            session: session,
            now: now,
            canTerminate: canTerminate,
            onTerminate: () => _terminate(session),
            onTerminateUser: () => _terminateUser(session),
          );
        },
      ),
    );
  }

  /// إنهاء جلسة واحدة — والجلسة الحالية تُحذّر بأنها ستُخرجك أنت
  /// Terminating one session — with a warning when it is the viewer's own.
  Future<void> _terminate(AppSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنهاء الجلسة'),
        content: Text(
          session.isCurrent
              ? 'هذه جلستك أنت: سيُطلب منك تسجيل الدخول من جديد في هذه اللحظة.'
              : 'ستُنهى جلسة «${session.displayName}» على ${_deviceLabel(session)} فوراً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await widget.notifier.terminate(session.tokenId);
    if (!mounted) return;
    _toast(result.success ? AppColors.success : AppColors.error, result.displayMessage);
  }

  /// إنهاء كل جلسات مستخدم — الإجراء بعد تعطيل حساب أو سحب صلاحيات
  /// Ending every session of a user — the follow-up after deactivating or stripping rights.
  Future<void> _terminateUser(AppSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إنهاء كل جلسات المستخدم'),
        content: Text(
          'ستُنهى جميع جلسات «${session.displayName}» المفتوحة على أي جهاز، وسيعيد الدخول '
          'بتحديد صلاحياته من جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('إنهاء الكل'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await widget.notifier.terminateUser(session.userId);
    if (!mounted) return;
    _toast(result.success ? AppColors.success : AppColors.error, result.displayMessage);
  }

  void _toast(Color tone, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: tone,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// وصف الجهاز للأمان: بلا اسم جهاز يُقال «جهاز غير معروف» لا يُترك السطر فارغاً
  /// The device description: an unknown device is stated, not left blank.
  static String _deviceLabel(AppSessionModel session) {
    final device = (session.deviceName ?? '').trim();
    if (device.isNotEmpty) return device;
    final platform = (session.platform ?? '').trim();

    return platform.isNotEmpty ? platform : 'جهاز غير معروف';
  }
}
