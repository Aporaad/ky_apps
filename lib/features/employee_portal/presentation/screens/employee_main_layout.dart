import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/permissions_notifier.dart';
import '../../domain/portal_sections.dart';
import '../widgets/collapsible_side_drawer.dart';
import '../widgets/portal_section_scope.dart';

/// الهيكل الرئيسي لبوابة الموظف المتجاوب بالكامل مع مختلف أحجام الشاشات
/// Main Employee Portal Layout with Responsive Sidebar / Drawer and Top Bar
///
/// هذا الملف لم يعد يعرف أسماء الأقسام: يستورد السجل، يصفّيه بمنح المستخدم الحالية، ثم يرسم
/// ما تبقى. المخزّن هو معرّف القسم لا موضعه، لأن الموضع يتغيّر إذا سحب مديرٌ صلاحية أثناء
/// الجلسة — والمخاطرة بمؤشر رقمي كانت تُبقي المستخدم على قسم آخر بعد كل تحديث صلاحيات.
/// The layout no longer knows section names: it reads the registry, filters it by the current
/// grants, and renders what survives. The stored selection is a section id, not an index, because
/// indexes shift when a manager revokes a permission mid-session — and a stale index used to drop
/// the user onto a different section after every permissions refresh.
class EmployeeMainLayout extends ConsumerStatefulWidget {
  const EmployeeMainLayout({super.key});

  @override
  ConsumerState<EmployeeMainLayout> createState() => _EmployeeMainLayoutState();
}

class _EmployeeMainLayoutState extends ConsumerState<EmployeeMainLayout> {
  /// المعرّف المختار حالياً — من السجل، وليس فهرساً
  /// The selected section id, taken from the registry rather than a numeric position.
  String _currentSectionId = portalSections.first.id;

  /// آخر قسم اختاره المستخدم من الشريط السفلي — يُستخدم حين يكون القسم المفتوح خارج الشريط
  /// The last section picked from the bottom bar — used while the open section is outside the bar.
  String _lastBarSectionId = portalSections.first.id;
  bool _isCollapsed = false;

  /// مرة واحدة فقط: بعد توجيه بلا منح إلى الدخول لا نُعيد جدولة الخروج عند كل بناء لاحق
  /// Fire-once: after a no-grants session is redirected to login, later builds must not reschedule it.
  bool _noGrantsRedirectScheduled = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('تسجيل خروج'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      // التوجيه لشاشة الدخول ليس هنا: `KyApp` يراقب الحالة، فأي خروج — عادي أو مُنهى أو بانتهاء
      // المهلة — يسقط من «مُصادق» إلى غيره ويُوجَّه من مكان واحد. تكراره هنا كان يُخفي المسارين
      // الآخرين ويُهدد تنقّلًا على سياق مُنفصَل بعد الحوار.
      // This screen does not navigate: KyApp watches the auth state, so every exit — manual,
      // terminated by an admin, or timed out — drops from signed-in to signed-out and routes in one
      // place. Doing it here too hid the other two paths and risked navigating a disposed context.
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  /// موضع معرّف داخل القائمة المرئية، وأول القائمة إن لم يعد المعرّف مرئياً
  /// Position of an id inside the visible list, falling back to the first visible section.
  ///
  /// السقوط على الأول مقصود: إن سحب مديرٌ صلاحية القسم الحالي أثناء الجلسة فالأفضل قسمٌ ظاهر
  /// بلا بيانات خاطئة، لا شاشة مرسومة لقسمٍ لم يعد للمستخدم حق دخوله.
  /// Falling back to the first section is deliberate: when a manager revokes the current section
  /// mid-session, a visible section beats a screen the user no longer has any right to see.
  int _indexOfVisible(List<PortalSection> visible, String id) {
    for (var i = 0; i < visible.length; i++) {
      if (visible[i].id == id) return i;
    }

    return 0;
  }

  /// الانتقال إلى قسم من داخل قسم آخر (بطاقات الرئيسية) — بالمعرّف لا بالفهرس
  /// Switches sections from within a section (home tiles) — by id, never by index.
  ///
  /// الصلاحية تُفحص هنا مرة أخرى: البطاقة قد تكون رُسمت قبل أن يسحب المدير منحتها، والقناة
  /// لا تثق بمن يناديها.
  /// The grant is re-checked here: the tile may have been drawn before an admin revoked it, and
  /// the channel does not trust its caller.
  void _openSection(String id) {
    if (!mounted) return;
    final auth = ref.read(authNotifierProvider);
    final visible = visiblePortalSections(
      granted: auth.permissions,
      isAdmin: auth.isAdmin,
    );
    if (!visible.any((section) => section.id == id)) return;

    setState(() => _currentSectionId = id);
  }

  /// مؤشر الشريط السفلي: القسم الحالي إن كان في الشريط، وإلا آخر اختيار منه، وإلا الأول
  /// Bottom-bar index: the current section if it sits in the bar, else the last bar choice, else 0.
  ///
  /// الرجوع إلى `0` كان يقول للمستخدم إنه في «الرئيسية» وهو في «المخازن» — خلل قديم يصير
  /// يوميًا بمجرد أن تفتح الرئيسية أقسامًا ليست في الشريط.
  /// Falling back to `0` told the user they were on «الرئيسية» while «المخازن» was open — an old
  /// bug that turns daily once home can open sections the bar does not hold.
  int _barIndexFor(List<PortalSection> barSections, String currentId) {
    final direct = barSections.indexWhere((section) => section.id == currentId);
    if (direct >= 0) return direct;

    final last = barSections.indexWhere(
      (section) => section.id == _lastBarSectionId,
    );

    return last >= 0 ? last : 0;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'الموظف';
    final isMobile = Responsive.isMobile(context);

    // القائمة المرئية مشتقّة في كل بناء: تحديث المنح يغيّرها دون أي إعادة ترتيب يدوية
    // The visible list is derived on every build, so a grants refresh needs no manual rewiring.
    final visible = visiblePortalSections(
      granted: authState.permissions,
      isAdmin: authState.isAdmin,
    );

    if (visible.isEmpty) {
      return NoSectionAvailable(onLogout: _handleLogout);
    }

    // شبكة أمان: جلسة حيّة بلا أي منح تصل.
    // «الإعدادات» هو القسم الوحيد بلا شرط ظهور، فأي تصفية للمنح تُبقيَه وحده تجعل البوابة تبدو
    // كأنها قرار إداري بينما هي لقطة صلاحيات لم تصل. المتطلَّب الآن: لا شاشة تنبيه إطلاقاً —
    // إن لم تكن هناك منح صالحة يُوجَّه المستخدم إلى تسجيل الدخول مباشرةً وبصمت.
    // A live session that loaded no grants used to render as an «الإعدادات»-only portal. The accepted
    // behaviour now: no warning screen at all — with no valid grants the user is sent straight back to
    // the login screen, quietly.
    final onlySettingsVisible =
        visible.length == 1 && visible.single.id == 'settings';
    if (onlySettingsVisible &&
        !authState.isAdmin &&
        authState.permissions.isEmpty) {
      // مراقبة المزود هنا مقصودة مزدوجة: تُبقيه حيّاً فيُرفق مراقب دورة الحياة فتتجدد المنح عند
      // الرجوع من الخلفية، وتصل اللقطة الأولى التي تقرّر إن كان هناك منح أصلاً.
      // Watching the provider keeps the notifier alive (so its lifecycle observer re-syncs on resume)
      // and yields the first snapshot that decides whether any grants exist.
      final sync = ref.watch(permissionsNotifierProvider);

      // لم تُحسم اللقطة بعد (جارٍ الجلب أو أول إطار قبل أي ردّ): لا يجوز طرد جلسةٍ منحُها على وشك
      // الوصول. انتظار محايد بلا تنبيه؛ وفشل الجلب يُنهي الجلسة بنفسه من `PermissionsNotifier`.
      // Not resolved yet: never bounce a session whose grants are about to arrive. A neutral wait, no
      // warning; a failed fetch ends the session itself inside `PermissionsNotifier`.
      if (sync.isSyncing || !sync.hasSynced) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      // حسم الخادم: موظف غير مدير بلا أي منح. لا شاشة تنبيه — إنهاء الجلسة بصمت، فيسمع `KyApp`
      // سقوط «مُصادق» ويوجّه إلى /login بلا أي رسالة.
      // The server confirmed a non-admin with zero grants: end the session silently; KyApp's auth
      // listener drops from signed-in and routes to /login with no message shown.
      if (!_noGrantsRedirectScheduled) {
        _noGrantsRedirectScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(authNotifierProvider.notifier)
              .forceLogout(silent: true);
        });
      }

      // إطار فاصل بلا واجهة حتى يلتقط المستمعُ السقوطَ ويُزيل هذه الشاشة من الشجرة.
      // A single blank frame until the listener tears this screen out of the tree.
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const SizedBox.shrink(),
      );
    }

    final currentIndex = _indexOfVisible(visible, _currentSectionId);

    // شريط الجوال يحمل ما وُسم منه فقط — القائمة الجانبية ترى التسعة كلها
    // The mobile bar carries only the sections flagged for it; the drawer sees the full list.
    final barSections = visible
        .where((section) => section.showInBottomBar)
        .toList(growable: false);

    // قناة الأقسام تُلفّ الشجرة مرة واحدة: كل الأقسام تراها والرئيسية وحدها تستخدمها، فلا
    // يعرف الهيكل من ينادي ولا تحتاج البطاقة إلى معامل يمرّ عبر تسعة أبنائن
    // The section channel wraps the stack once: every section sees it, only home uses it, so the
    // shell never knows the caller and a tile needs no parameter threaded through nine children.
    final portalStack = PortalSectionScope(
      openSection: _openSection,
      child: IndexedStack(
        index: currentIndex,
        children: [for (final section in visible) section.builder(context)],
      ),
    );

    // واجهة القائمة الجانبية المشتركة
    final sideDrawer = CollapsibleSideDrawer(
      sections: visible,
      selectedIndex: currentIndex,
      onIndexChanged: (index) {
        // التخزين بالمعرّف لا بالفهرس: الفهرس ملك هذه القائمة المصفّاة لا السجل الكامل
        // Store the id, not the index — an index belongs to this filtered list, not the registry.
        setState(() {
          _currentSectionId = visible[index].id;
        });
      },
      isCollapsed: isMobile ? false : _isCollapsed,
      isDrawerMode: isMobile,
      onToggleCollapse: () {
        setState(() {
          _isCollapsed = !_isCollapsed;
        });
      },
      onLogout: _handleLogout,
      employeeName: displayName,
    );

    if (isMobile) {
      // 📱 تخطيط الهواتف المحمولة (Mobile Layout)
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: Drawer(width: 280, child: SafeArea(child: sideDrawer)),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: AppColors.primary),
            tooltip: 'القائمة الرئيسية',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بوابة الموظف',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          centerTitle: false,
          actions: [
            if (user?.branchNo != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'فرع ${user!.branchNo}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              onPressed: _handleLogout,
              icon: const Icon(
                Icons.power_settings_new_rounded,
                color: AppColors.error,
                size: 22,
              ),
              tooltip: 'خروج',
            ),
          ],
        ),
        body: portalStack,
        // الشريط يعرض الأقسام المسموح بها والموسومة له فقط: كانت الوجهة الخامسة فيه تقابل
        // الفهرس 4 من تسعة، فكان اختيار «الحسابات» يفتح «جاري العاملين»
        // The bar lists only the sections that are both allowed and flagged for it. Previously its
        // fifth destination indexed the fourth of nine children, so «الحسابات» opened «جاري العاملين».
        //
        // ويغيب تحت وجهتين: `NavigationBar` نفسها تصرخ على أقل من اثنتين، وموظفٌ بمنح قسم واحد
        // في الشريط لا يحتاج شريطاً — الواجهة التي تنهار أسوأ من الواجهة الفارغة.
        // It also disappears below two destinations: `NavigationBar` asserts on fewer than two, and
        // a worker whose grants open one bar section gains nothing from a bar anyway.
        bottomNavigationBar: barSections.length < 2
            ? null
            : NavigationBar(
                selectedIndex: _barIndexFor(
                  barSections,
                  visible[currentIndex].id,
                ),
                onDestinationSelected: (idx) {
                  setState(() {
                    _lastBarSectionId = barSections[idx].id;
                    _currentSectionId = barSections[idx].id;
                  });
                },
                destinations: [
                  for (final section in barSections)
                    NavigationDestination(
                      icon: Icon(section.icon),
                      selectedIcon: Icon(section.selectedIcon ?? section.icon),
                      label: section.title,
                    ),
                ],
              ),
      );
    }

    // 💻 تخطيط الأجهزة اللوحية والمكتبية (Tablet & Desktop Layout)
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          sideDrawer,
          Expanded(
            child: Column(
              children: [
                // الشريط العلوي للشاشات الكبيرة مع حماية تامة ضد التجاوز
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'بوابة الموظف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'متصل',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      if (user?.branchNo != null) ...[
                        Chip(
                          avatar: Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: Text('فرع رقم: ${user!.branchNo}'),
                          backgroundColor: AppColors.surfaceSubtle,
                          side: const BorderSide(color: AppColors.border),
                        ),
                        const SizedBox(width: 12),
                      ],

                      IconButton(
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.power_settings_new_rounded,
                          color: AppColors.error,
                        ),
                        tooltip: 'خروج',
                      ),
                      IconButton(
                        onPressed: _handleLogout,
                        icon: Icon(Icons.key, color: AppColors.primary),
                        tooltip: 'خيارات',
                      ),
                    ],
                  ),
                ),

                Expanded(child: portalStack),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شاشة «لا قسم متاح» — تصلها حالتان: مستخدم بلا أي صلاحية قسم، أو جلسة لم تُحمّل منحها بعد
/// The "no section available" screen — reached in two cases: a user with no section rights, or a
/// session whose grants have not loaded.
///
/// وجودها ليس ترفيقاً: الحجب الافتراضي يعني أن موظفاً جديداً لم يُمنح بعد يصل إلى بوابة بلا أي
/// قسم، ولو مُرّر فهرسٌ إلى `IndexedStack` فارغ لانهارت الشاشة بدل أن تشرح للمستخدم ما الناقص.
/// مخرجها الأول تسجيل الخروج، وأُضيف ثاني: إعادة محاولة الجلب — فالحالة الثانية ليست قراراً
/// إدارياً بل عطل وصول مؤقت، وترْك المستخدم بلا خيار هو ما حوّل العطل إلى شكوى يومية.
/// This isn't decoration: deny-by-default means a freshly created, not-yet-granted worker arrives at a
/// portal with no sections, and an index into an empty `IndexedStack` would crash the screen instead of
/// explaining what is missing. Logging out is one exit; a retry is the other, because the second case
/// is not an administrative verdict but a transient fetch failure — and offering no option is what
/// turned that failure into a daily complaint.
class NoSectionAvailable extends StatelessWidget {
  const NoSectionAvailable({
    super.key,
    this.onLogout,
    this.onRetry,
    this.isBusy = false,
    this.headline,
    this.details,
  });

  final VoidCallback? onLogout;

  /// إعادة الجلب — تُعرض حين لم تصل الصلاحيات، وتغيب حين أجابت الخادم فعلاً برفض
  /// Re-fetch — offered while grants have not arrived; absent when the server truly answered "none".
  final VoidCallback? onRetry;

  /// مزامنة جارية: spinner بدل الأزرار، حتى لا يُنقر طلب مكرر أثناء طلب حيّ
  /// A sync in flight: a spinner instead of buttons, so no duplicate fetch is tapped.
  final bool isBusy;

  /// نصّان قابلان للتخصيص: الحالة الإدارية وحالة «لم تصل البيانات» — نفس التخطيط
  /// Two overridable strings: the administrative case and the not-loaded case, same layout.
  final String? headline;
  final String? details;

  static const String _defaultHeadline = 'لم تُمنح بعد أي صلاحية دخول';
  static const String _defaultDetails =
      'يرجى مراجعة مدير النظام لتفعيل صلاحياتك، ثم تسجيل الخروج والدخول مجدداً';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBusy
                      ? Icons.cloud_sync_outlined
                      : Icons.lock_outline_rounded,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  headline ?? _defaultHeadline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details ?? _defaultDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.6,
                  ),
                ),
                if (isBusy) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                ] else if (onRetry != null) ...[
                  // زر إعادة المحاولة هو المخرج الثاني: فشل الجلب كان يُترك بلا أي خيار
                  // The retry is the second exit: a fetch failure used to be left with no option at all
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة محاولة تحميل الصلاحيات'),
                  ),
                ],
                if (!isBusy && onLogout != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('تسجيل الخروج'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
