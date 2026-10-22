import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../employee_portal/domain/portal_section_titles.dart';
import '../../../employee_portal/presentation/widgets/portal_section_scope.dart';
import '../../domain/home_card_size.dart';
import '../../domain/home_shortcut.dart';
import '../../domain/home_shortcut_catalog.dart';
import '../providers/home_layout_notifier.dart';
import '../widgets/home_empty_state.dart';
import '../widgets/home_header.dart';
import '../widgets/home_module_filter.dart';
import '../widgets/home_shortcut_grid.dart';
import '../widgets/home_tokens.dart';
import 'home_customize_screen.dart';

/// الواجهة الرئيسية — مركز تنقّل لا لوحة إحصائيات
/// The home screen — a navigation hub, not a statistics board.
///
/// البطاقات مشتقّة في كل بناء من ثلاثة مصادر فقط: الكتالوج الثابت، ومنح الجلسة الحالية، وتخطيط
/// المستخدم المحفوظ. لا تُخزَّن نتيجة الفلترة، فالمنح تُسحب أثناء الجلسة وتخزين «ما رآه المستخدم»
/// يقدُم فيصير خطأً.
/// Cards are derived on every build from exactly three inputs: the static catalog, the current
/// session's grants, and the stored layout. The filtered result is never persisted — grants are
/// revoked mid-session, and a stored "what the user saw" ages into a wrong answer.
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  /// مرشّح القسم: `null` يعني «الكل»
  /// The section filter; `null` means all.
  String? _sectionFilter;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final layoutState = ref.watch(homeLayoutNotifierProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = HomeTokens.pagePadding(screenWidth);
    final compact = screenWidth < 600;

    // فشل الكتابة لا يُسقط الواجهة: التخصيص يبقى في الذاكرة، والمستخدم يحتاج أن يعرف أنه مؤقت
    // A failed write never drops the UI: the layout stays in memory, and the user must know it is
    // temporary.
    ref.listen(homeLayoutNotifierProvider.select((state) => state.saveFailed), (
      previous,
      next,
    ) {
      if (next && previous != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حفظ التخصيص على هذا الجهاز')),
        );
      }
    });

    final allowed = allowedHomeShortcuts(
      granted: auth.permissions,
      isAdmin: auth.isAdmin,
    );
    final active = layoutState.layout.resolve(allowed);

    // أقسام لها اختصار ظاهر، بترتيب الظهور — تُبنى من النتيجة لا من السجل
    // Sections with a visible shortcut, in display order — derived from the result, not the registry.
    final sectionIds = <String>[];
    for (final shortcut in active) {
      if (!sectionIds.contains(shortcut.sectionId)) {
        sectionIds.add(shortcut.sectionId);
      }
    }

    // مرشّح لم يعد له قسم (أُخفيت بطاقاته) يُهمَل بلا setState داخل البناء
    // A filter whose section vanished is ignored without a setState inside build.
    final filter = sectionIds.contains(_sectionFilter) ? _sectionFilter : null;
    final visible = [
      for (final shortcut in active)
        if (filter == null || shortcut.sectionId == filter) shortcut,
    ];

    // البطاقة المثبّتة وحدها = أخفى المستخدم كل شيء: تُشرح الحالة فوقها ولا تُخفى هي
    // Only the pinned card left means everything else was hidden: explain it above the grid.
    final onlyPinned = active.length == 1 && active.single.pinned;
    final customized =
        layoutState.layout.order.isNotEmpty ||
        layoutState.layout.shown.isNotEmpty ||
        layoutState.layout.hidden.isNotEmpty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: HomeTokens.contentMaxWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeader(
                displayName: auth.user?.displayName ?? 'الموظف',
                branchNo: auth.user?.branchNo,
                onCustomize: _openCustomize,
              ),
              SizedBox(height: compact ? 16 : 22),

              if (layoutState.loading)
                _SkeletonGrid(
                  size: layoutState.layout.size,
                  columns: layoutState.layout.columns,
                )
              else if (active.isEmpty)
                HomeEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'لم تُمنح أي اختصارات بعد',
                  message:
                      'اطلب من مدير النظام منحك صلاحية على الأقل، ثم أعد المحاولة. '
                      'تظهر الاختصارات بحسب صلاحياتك الحالية.',
                  actions: [
                    TextButton.icon(
                      onPressed: _openCustomize,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('تخصيص الاختصارات'),
                    ),
                  ],
                )
              else ...[
                if (sectionIds.length > 1) ...[
                  HomeModuleFilter(
                    sectionIds: sectionIds,
                    selected: filter,
                    onChanged: (id) => setState(() => _sectionFilter = id),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                ],
                if (onlyPinned) ...[
                  _HiddenAllNotice(
                    onReset:
                        () =>
                            ref
                                .read(homeLayoutNotifierProvider.notifier)
                                .reset(),
                  ),
                  const SizedBox(height: 14),
                ],
                if (visible.isEmpty)
                  HomeEmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'لا اختصارات في هذا القسم',
                    message: 'كل اختصارات هذا القسم مخفية أو غير ممنوحة.',
                    actions: [
                      TextButton(
                        onPressed: () => setState(() => _sectionFilter = null),
                        child: const Text('إظهار الكل'),
                      ),
                    ],
                  )
                else
                  HomeShortcutGrid(
                    shortcuts: visible,
                    size: layoutState.layout.size,
                    columns: layoutState.layout.columns,
                    onOpen: _open,
                    onLongPress: _showActions,
                  ),
                if (!customized) ...[
                  SizedBox(height: compact ? 14 : 18),
                  const _FirstRunHint(),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// الاختصارات المرئية الآن — تُقرأ عند الحاجة (ورقة الخيارات) لا في البناء
  /// The currently visible shortcuts — read on demand (the action sheet), not during build.
  List<HomeShortcut> _activeShortcuts() {
    final auth = ref.read(authNotifierProvider);

    return ref
        .read(homeLayoutNotifierProvider)
        .layout
        .resolve(
          allowedHomeShortcuts(
            granted: auth.permissions,
            isAdmin: auth.isAdmin,
          ),
        );
  }

  /// فتح الوجهة حسب نوع هدفها — `switch` شامل على النوع المختوم
  /// Opens the destination by target type — an exhaustive switch on the sealed type.
  Future<void> _open(HomeShortcut shortcut) async {
    switch (shortcut.target) {
      case SectionTarget(sectionId: final sectionId):
        // قناة الهيكل: تغيير `IndexedStack` لا دفع شاشة
        // The shell channel: the IndexedStack moves, no screen is pushed.
        PortalSectionScope.maybeOf(context)?.openSection(sectionId);
      case RouteTarget(location: final location):
        if (!mounted) return;
        await context.push(location);
      case ScreenTarget(build: final builder):
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => builder()));
      case FlowTarget(run: final run):
        await run(context);
    }
  }

  Future<void> _openCustomize() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const HomeCustomizeScreen()),
    );
  }

  /// ضغط مطوّل: إخفاء/تقديم/فتح — تغيير فوري بلا مغادرة الصفحة
  /// Long press: hide/promote/open — an instant change without leaving the page.
  Future<void> _showActions(HomeShortcut shortcut) async {
    final index = _activeShortcuts().indexWhere(
      (item) => item.id == shortcut.id,
    );
    final sectionTitle = PortalSectionTitles.of(shortcut.sectionId);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    shortcut.icon,
                    color: HomeTokens.sectionColor(shortcut.sectionId),
                  ),
                  title: Text(
                    shortcut.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(sectionTitle),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('فتح'),
                  onTap: () => Navigator.pop(sheetContext, 'open'),
                ),
                if (!shortcut.pinned) ...[
                  ListTile(
                    leading: const Icon(Icons.vertical_align_top_rounded),
                    title: const Text('تقديم إلى المقدمة'),
                    enabled: index > 0,
                    onTap: () => Navigator.pop(sheetContext, 'promote'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: const Text('إخفاء من الرئيسية'),
                    onTap: () => Navigator.pop(sheetContext, 'hide'),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('تخصيص الاختصارات…'),
                  onTap: () => Navigator.pop(sheetContext, 'customize'),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
    );

    if (!mounted || action == null) return;
    final notifier = ref.read(homeLayoutNotifierProvider.notifier);

    switch (action) {
      case 'open':
        await _open(shortcut);
      case 'promote':
        await notifier.move(index, 0);
      case 'hide':
        await notifier.toggle(shortcut.id);
      case 'customize':
        await _openCustomize();
    }
  }
}

/// هيكل عظمي ساكن — بلا حركة متكررة، فلا يُعلّق `pumpAndSettle` في الاختبارات
/// A static skeleton — no repeating animation, so `pumpAndSettle` never hangs in tests.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({required this.size, required this.columns});

  final HomeCardSize size;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolved = HomeTokens.columns(
          constraints.maxWidth,
          size: size,
          fixed: columns,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: resolved * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: resolved,
            crossAxisSpacing: size.gap,
            mainAxisSpacing: size.gap,
            childAspectRatio: size.ratio,
          ),
          itemBuilder:
              (context, index) => DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
              ),
        );
      },
    );
  }
}

/// تنبيه «أخفيت كل الاختصارات» — يظهر فوق البطاقة المثبّتة لا بدلًا منها
/// The "you hid everything" notice — shown above the pinned card, never instead of it.
class _HiddenAllNotice extends StatelessWidget {
  const _HiddenAllNotice({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'أخفيت كل الاختصارات — يمكنك استعادتها الآن.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
            ),
          ),
          TextButton(
            onPressed: onReset,
            child: const Text('استعادة الافتراضي'),
          ),
        ],
      ),
    );
  }
}

/// تلميح أول تشغيل — يختفي بعد أول تخصيص لأن ظهوره مشتق من التخطيط نفسه
/// The first-run hint — it disappears after the first customisation because its visibility is
/// derived from the layout itself.
class _FirstRunHint extends StatelessWidget {
  const _FirstRunHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.touch_app_outlined,
          size: 15,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'اضغط مطوّلًا على أي بطاقة لإخفائها أو إعادة ترتيبها',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: MediaQuery.textScalerOf(
                context,
              ).scale(11).clamp(9.5, 14),
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
