import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../providers/items_providers.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';
import 'store_reports_screen.dart';
import 'sub_item_detail_screen.dart';

/// واجهة الأصناف في تبويبين: الرئيسية والفرعية
/// The items screen in two tabs: main items and sub items.
///
/// ── لماذا تبويبان؟ لأن الصنف كائنان في هذا المخطط: رأس `SANFS` يحمل الاسم والسعر والتصنيف،
///    وفروع `SANFS_D` هي التي تحمل الحركة فعلياً. الخلط بينهما في قائمة واحدة كان يجعل البحث
///    غير متوقع: تكتب رقم باركود فتظهر الرؤوس، أو تكتب اسم صنف فتختفي فروعه.
/// ── Why two tabs? An item is two objects here: a SANFS header carrying the name, price and
///    classification, and SANFS_D branches that actually carry movement. Mixing them made search
///    unpredictable: typing a barcode surfaced headers, typing a name hid the branches.
class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final TextEditingController _search = TextEditingController();
  final TextEditingController _subSearch = TextEditingController();

  /// الصنف المعروض في اللوحة الجانبية (تخطيط عريض فقط)
  /// The item shown in the side panel (wide layout only).
  int? _selectedSanfNo;

  /// هل حُسم الإقلاع؟ التصفية الافتراضية تُطبَّق بعد وصول المراجع مرة واحدة
  /// Whether bootstrapping was decided — defaults apply once, after the reference arrives.
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _subSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── الإقلاع: المراجع تُحدد التصفية الافتراضية (نشط · أول مجموعة · أول فرعية).
    //    لو فشلت المراجع لا نُقعد الشاشة فارغة: نحمّل بلا تصفية ليظل المستخدم قادراً على العمل.
    // ── Bootstrapping: the reference decides the default filter (active, first group, its first
    //    sub group). If it fails we must not leave the screen empty: load unfiltered instead.
    final referenceAsync = ref.watch(storeReferenceProvider);

    if (!_bootstrapped && !referenceAsync.isLoading) {
      _bootstrapped = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final reference = referenceAsync.value;

        if (reference == null || reference.groups.isEmpty) {
          ref.read(itemsListProvider.notifier).load();
          ref.read(subItemsListProvider.notifier).load();

          return;
        }

        ref.read(itemsListProvider.notifier).applyDefaults(reference);
        ref.read(subItemsListProvider.notifier).applyDefaults(reference);
      });
    }

    final auth = ref.watch(authNotifierProvider);
    final canCreate = auth.can(Perm.storesItemsCreate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأصناف'),
        actions: [
          // ── الترتيب لكل تبويب لا للرئيسية فقط: تبويب الفروع كان بلا أي خيار فرز أصلاً،
          //    فطلب المستخدم «تصاعدي/تنازلي لكل خيار» يشمل القائمة كلها.
          // ── Sorting for every tab, not just the main one: the branches tab had no sort
          //    option at all, and "asc/desc for every choice" plainly covers both lists.
          if (_tabs.index == 0 || _tabs.index == 1)
            IconButton(
              tooltip: 'ترتيب',
              onPressed: () => _tabs.index == 0
                  ? _openSort(context)
                  : _openSubSort(context),
              icon: const Icon(Icons.sort_rounded),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'الأصناف الرئيسية'),
            Tab(text: 'الأصناف الفرعية'),
          ],
        ),
      ),
      floatingActionButton:
          canCreate && _tabs.index == 0
              ? FloatingActionButton.extended(
                onPressed: () => _openForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('صنف جديد'),
              )
              : null,
      body: TabBarView(
        controller: _tabs,
        children: [_buildMainTab(), _buildSubTab()],
      ),
    );
  }

  // ================================================================
  // تبويب الأصناف الرئيسية
  // The main items tab
  // ================================================================

  Widget _buildMainTab() {
    final state = ref.watch(itemsListProvider);
    final notifier = ref.read(itemsListProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final reference = ref.watch(storeReferenceProvider).value;

    return Column(
      children: [
        _toolbar(
          controller: _search,
          hint: 'بحث بالاسم أو الكود...',
          filtersCount: state.filtersCount,
          onSearch: notifier.search,
          onFilter:
              reference == null
                  ? null
                  : () => _openFilters(context, isSubTab: false),
        ),
        if (state.selectionMode) _selectionBar(state, notifier),
        Expanded(child: _mainBody(state, notifier, auth)),
      ],
    );
  }

  Widget _mainBody(
    ItemsListState state,
    ItemsListNotifier notifier,
    dynamic auth,
  ) {
    if (state.isLoading) return const StoreLoading();

    if (state.error != null) {
      return StoreErrorState(message: state.error!, onRetry: notifier.load);
    }

    if (state.items.isEmpty) {
      return StoreEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'لا توجد أصناف',
        description:
            state.search.isEmpty
                ? 'لا نتائج مطابقة للتصفية الحالية. وسّع المجموعة أو اضغط «مسح التصفية».'
                : 'لا نتائج مطابقة للبحث أو التصفية.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // وضع التحديد المتعدد لا يقبل لوحة تفصيل: كل نقرة يجب أن تصب في التحديد
        // Multi-select mode leaves no room for a detail panel: every tap must select.
        final wide =
            constraints.maxWidth >= ItemDetailScreen.splitBreakpoint &&
            !state.selectionMode;

        final list = Column(
          children: [
            Expanded(child: _mainList(state, notifier, auth)),
            _pager(
              state.page,
              state.pages,
              state.total,
              notifier.goToPage,
              unit: 'صنف',
            ),
          ],
        );

        if (!wide) return list;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: list),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              flex: 6,
              child:
                  _selectedSanfNo == null
                      ? const StoreEmptyState(
                        icon: Icons.touch_app_outlined,
                        title: 'اختر صنفاً',
                        description:
                            'يظهر هنا تفصيل الصنف: بياناته وأصنافه الفرعية وكمياتها.',
                      )
                      : ItemDetailScreen(
                        key: ValueKey<int>(_selectedSanfNo!),
                        sanfNo: _selectedSanfNo!,
                        embedded: true,
                      ),
            ),
          ],
        );
      },
    );
  }

  Widget _mainList(
    ItemsListState state,
    ItemsListNotifier notifier,
    dynamic auth,
  ) {
    final canUpdate = auth.can(Perm.storesItemsUpdate);
    final canDelete = auth.can(Perm.storesItemsDelete);

    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
        itemCount: state.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = state.items[index];

          return _ItemCard(
            item: item,
            selectionMode: state.selectionMode,
            selected: state.selected.contains(item.sanfNo),
            canUpdate: canUpdate,
            canDelete: canDelete,
            onTap: () {
              if (state.selectionMode) {
                notifier.toggleSelected(item.sanfNo);

                return;
              }

              _select(item);
            },
            onDetail: () => _openDetail(context, item),
            onMovement: () => _openMovement(context, item),
            onEdit: () => _openForm(context, item: item),
            onDelete: () => _confirmDelete(context, notifier, item),
          );
        },
      ),
    );
  }

  Widget _selectionBar(ItemsListState state, ItemsListNotifier notifier) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.06),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            'محدد: ${state.selected.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton(
            onPressed: notifier.selectAll,
            child: const Text('تحديد الكل'),
          ),
          TextButton(
            onPressed: notifier.clearSelection,
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // تبويب الأصناف الفرعية
  // The sub items tab
  // ================================================================

  Widget _buildSubTab() {
    final state = ref.watch(subItemsListProvider);
    final notifier = ref.read(subItemsListProvider.notifier);
    final reference = ref.watch(storeReferenceProvider).value;

    return Column(
      children: [
        _toolbar(
          controller: _subSearch,
          hint: 'بحث برقم الفرع أو الصنف أو الباركود...',
          filtersCount: state.filtersCount,
          onSearch: notifier.search,
          onFilter:
              reference == null
                  ? null
                  : () => _openFilters(context, isSubTab: true),
        ),
        Expanded(child: _subBody(state, notifier)),
      ],
    );
  }

  Widget _subBody(SubItemsListState state, SubItemsListNotifier notifier) {
    if (state.isLoading) return const StoreLoading();

    if (state.error != null) {
      return StoreErrorState(message: state.error!, onRetry: notifier.load);
    }

    if (state.rows.isEmpty) {
      return StoreEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'لا أصناف فرعية',
        description:
            state.search.isEmpty
                ? 'لا فروع مطابقة للتصفية الحالية. وسّع المجموعة أو اضغط «مسح التصفية».'
                : 'لا نتائج مطابقة للبحث أو التصفية.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
              itemCount: state.rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sub = state.rows[index];

                return _SubCard(
                  sub: sub,
                  // النقر على الفرع يفتح تفاصيله هو، لا تفاصيل أبيه
                  // Tapping a branch opens the branch, not its parent.
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => SubItemDetailScreen(
                                sanfNo: sub.sanfNo,
                                sanfDno: sub.sanfDno,
                              ),
                        ),
                      ),
                  onMovement:
                      () => Navigator.of(context).push(
                        // ── كشف حركة الفرع = تقرير «حركة صنف فرعي» من تقارير المخازن
                        //    يُفتح مباشرة بمعطياته، لا شاشة كشف منفصلة بقالب أضعف.
                        // ── A branch statement IS the stores-reports "sub item movement"
                        //    template — opened directly with its parameters, not a weaker
                        //    side screen.
                        MaterialPageRoute(
                          builder:
                              (_) => StoreReportsScreen(
                                initialFilter: StoreReportFilter.forBranchStatement(
                                  sanfNo: sub.sanfNo,
                                  sanfDno: sub.sanfDno,
                                  // `sizeLabel` لا يكون فارغاً: يحمل احتياطه داخلها
                                  // sizeLabel is never empty: it carries its own fallback.
                                  branchLabel: sub.name ?? sub.sizeLabel,
                                ),
                              ),
                        ),
                      ),
                  onParent:
                      () =>
                          _openDetailByNo(context, sub.sanfNo, sub.parentName),
                );
              },
            ),
          ),
        ),
        _pager(
          state.page,
          state.pages,
          state.total,
          notifier.goToPage,
          unit: 'فرع',
        ),
      ],
    );
  }

  // ================================================================
  // أدوات مشتركة
  // Shared pieces
  // ================================================================

  /// شريط البحث والتصفية — مشترك بين التبويبين
  /// The search and filter strip — shared by both tabs.
  Widget _toolbar({
    required TextEditingController controller,
    required String hint,
    required int filtersCount,
    required ValueChanged<String> onSearch,
    required VoidCallback? onFilter,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSearch,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: filtersCount > 0,
            label: Text('$filtersCount'),
            child: OutlinedButton.icon(
              onPressed: onFilter,
              icon: const Icon(Icons.filter_list_rounded, size: 17),
              label: const Text('تصفية'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(
    int page,
    int pages,
    int total,
    Future<void> Function(int) goToPage, {
    required String unit,
  }) {
    if (pages <= 1) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'إجمالي $total $unit',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: page > 1 ? () => goToPage(page - 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Text(
            'صفحة $page من $pages · $total $unit',
            style: const TextStyle(fontSize: 11.5),
          ),
          IconButton(
            onPressed: page < pages ? () => goToPage(page + 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // الترتيب — ورشة مشتركة للتبويبين
  // Sorting — one workshop shared by both tabs
  // ================================================================

  /// تسمية اتجاه الترتيب بالعربية — تُعرض بجانب كل خيار وفي الزر
  /// The Arabic caption of the sort direction — shown beside the active option and on the button.
  static String _dirLabel(String dir) => dir == 'desc' ? 'تنازلي' : 'تصاعدي';

  static IconData _dirIcon(String dir) =>
      dir == 'desc' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

  /// ورقة ترتيب موحّدة: الخيار النشط معلَّم، والاتجاه يُبدَّل من رأس الورقة ويُنقل لكل
  /// النقرات التالية، والاختيار يُطبَّق فوراً فيبقى المفتوح هو المختار
  /// One unified sort sheet: the active option is ticked, the direction toggles from the header
  /// and carries into every later pick, and each pick applies immediately so the tick always
  /// reflects what is on screen.
  ///
  /// ── العطل المُصلَح: كانت النسخة القديمة تُعيد الاتجاه إلى «تصاعدي» عند اختيار أي خيار
  ///    (منطق `ascending = true` ثابت)، فلا يمكن الوصول إلى الترتيب التنازلي إطلاقاً رغم أن
  ///    الخادم يقبله منذ زمن.
  /// ── The fixed defect: the old sheet reset every pick to ascending (a hard-coded
  ///    `ascending = true`), so descending was unreachable even though the server has always
  ///    accepted it.
  Future<void> _openSortSheet({
    required String title,
    required String currentSort,
    required String currentDir,
    required List<(String, String)> options,
    required Future<void> Function(String field, String dir) apply,
    required Future<void> Function() toggleDir,
  }) async {
    var sort = currentSort;
    var dir = currentDir;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // تبديل الاتجاه وحده — بلا تغيير الخيار: يعمل حتى قبل اختيار أي خيار
                      // Direction-only toggle — no field change: works even before a pick.
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          toggleDir();
                        },
                        icon: Icon(_dirIcon(dir), size: 17),
                        label: Text(_dirLabel(dir)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                for (final option in options)
                  ListTile(
                    dense: true,
                    selected: option.$1 == sort,
                    leading: Icon(
                      option.$1 == sort
                          ? Icons.check_rounded
                          : Icons.sort_rounded,
                      size: 18,
                      color:
                          option.$1 == sort
                              ? AppColors.primary
                              : AppColors.textMuted,
                    ),
                    // الخيار النشط يحمل سهم الاتجاه نفسه: يُقرأ الوضع الحالي بلا شرح
                    // The active option carries the direction arrow itself: current state reads at a glance.
                    title: Text(
                      option.$1 == sort
                          ? '${option.$2} (${_dirLabel(dir)})'
                          : option.$2,
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      apply(option.$1, dir);
                    },
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
    );
  }

  /// ترتيب قائمة الأصناف الرئيسية
  /// Sort the main items list.
  Future<void> _openSort(BuildContext context) {
    final notifier = ref.read(itemsListProvider.notifier);
    final state = ref.read(itemsListProvider);

    return _openSortSheet(
      title: 'ترتيب الأصناف',
      currentSort: state.sort,
      currentDir: state.dir,
      options: const [
        ('name', 'بالاسم'),
        ('part', 'بالكود'),
        ('no', 'برقم الصنف'),
        ('qty', 'بالرصيد'),
        ('value', 'بالقيمة'),
      ],
      apply: notifier.sortBy,
      toggleDir: notifier.toggleSortDir,
    );
  }

  /// ترتيب تبويب الأصناف الفرعية — نفس الورشة بخيارات الفروع
  /// Sort the sub-items tab — the same workshop with branch options.
  Future<void> _openSubSort(BuildContext context) {
    final notifier = ref.read(subItemsListProvider.notifier);
    final state = ref.read(subItemsListProvider);

    return _openSortSheet(
      title: 'ترتيب الأصناف الفرعية',
      currentSort: state.sort,
      currentDir: state.dir,
      options: const [
        ('parent', 'باسم الصنف الرئيسي'),
        ('no', 'برقم الصنف الفرعي'),
        ('color', 'باللون'),
        ('qty', 'بالرصيد'),
        ('value', 'بالقيمة'),
      ],
      apply: notifier.sortBy,
      toggleDir: notifier.toggleSortDir,
    );
  }

  // ================================================================
  // التصفية
  // Filtering
  // ================================================================

  /// نافذة التصفية — عالية وقابلة للتمرير، وكل قائمة فيها عنصر «الكل» صريح
  /// The filter sheet — tall and scrollable, with an explicit "all" entry in every list.
  ///
  /// ── سبب إعادة كتابتها: النسخة السابقة كانت `Column` بلا تمرير وبلا عناصر «الكل»، فإذا لم
  ///    تحتوِ القائمة على القيمة الحالية انفجر `DropdownButtonFormField` بشرط داخلي (قيمة غير
  ///    موجودة بين العناصر) فتظهر شاشة بيضاء بلا خيارات. هنا القيمة **دائماً** من العناصر نفسها.
  /// ── Why rewritten: the previous version was a non-scrolling Column with no "all" entries, so
  ///    whenever the list did not contain the current value DropdownButtonFormField tripped its
  ///    internal assertion (a value absent from its items) and rendered a blank sheet. Here the
  ///    value is *always* one of the generated items.
  Future<void> _openFilters(
    BuildContext context, {
    required bool isSubTab,
  }) async {
    final reference = ref.read(storeReferenceProvider).value;

    if (reference == null) return;

    final main = ref.read(itemsListProvider);
    final subs = ref.read(subItemsListProvider);

    var group = (isSubTab ? subs.groupNo : main.groupNo)?.toString() ?? 'all';
    var type = (isSubTab ? subs.typeNo : main.typeNo)?.toString() ?? 'all';
    var cat = (isSubTab ? null : main.catNo)?.toString() ?? 'all';
    var unit = (isSubTab ? null : main.unitNo)?.toString() ?? 'all';
    var active = isSubTab ? subs.active : main.active;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setLocal) {
              final types =
                  group == 'all'
                      ? reference.types
                      : reference.typesOfGroup(int.tryParse(group));

              // المجموعة الفرعية تُصفَّر إن لم تعد تابعة للمجموعة المختارة
              // The sub group resets when it no longer belongs to the chosen group.
              if (type != 'all' &&
                  !types.any((row) => row.typeNo.toString() == type)) {
                type = 'all';
              }

              return SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.82,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'تصفية الأصناف',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            isSubTab ? 'الأصناف الفرعية' : 'الأصناف الرئيسية',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (reference.groups.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'لم تُحمَّل المجموعات من الخادم — أعد المحاولة لاحقاً.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            _sheetDropdown(
                              label: 'المجموعة الرئيسية',
                              value: group,
                              items: [
                                ('all', 'كل المجموعات'),
                                for (final row in reference.groups)
                                  (row.groupNo.toString(), row.groupName),
                              ],
                              onChanged:
                                  (value) => setLocal(() {
                                    group = value;
                                    type = 'all';
                                  }),
                            ),
                            const SizedBox(height: 12),
                            _sheetDropdown(
                              label: 'المجموعة الفرعية',
                              value: type,
                              items: [
                                ('all', 'كل المجموعات الفرعية'),
                                for (final row in types)
                                  (row.typeNo.toString(), row.typeName),
                              ],
                              onChanged:
                                  (value) => setLocal(() => type = value),
                            ),
                            if (!isSubTab) ...[
                              const SizedBox(height: 12),
                              _sheetDropdown(
                                label: 'الفئة',
                                value: cat,
                                items: [
                                  ('all', 'كل الفئات'),
                                  for (final row in reference.categories)
                                    (row.id.toString(), row.name),
                                ],
                                onChanged:
                                    (value) => setLocal(() => cat = value),
                              ),
                              const SizedBox(height: 12),
                              _sheetDropdown(
                                label: 'الوحدة',
                                value: unit,
                                items: [
                                  ('all', 'كل الوحدات'),
                                  for (final row in reference.units)
                                    (row.unitNo.toString(), row.unitName),
                                ],
                                onChanged:
                                    (value) => setLocal(() => unit = value),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _sheetDropdown(
                              label: 'الحالة',
                              value: active,
                              items: const [
                                ('all', 'الكل'),
                                ('1', 'نشط'),
                                ('0', 'معطّل'),
                              ],
                              onChanged:
                                  (value) => setLocal(() => active = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);

                                if (isSubTab) {
                                  ref
                                      .read(subItemsListProvider.notifier)
                                      .applyFilters(
                                        groupNo: null,
                                        typeNo: null,
                                        active: 'all',
                                        clearGroup: true,
                                        clearType: true,
                                      );
                                } else {
                                  ref
                                      .read(itemsListProvider.notifier)
                                      .applyFilters(
                                        active: 'all',
                                        clearGroup: true,
                                        clearType: true,
                                        clearCat: true,
                                        clearUnit: true,
                                      );
                                }
                              },
                              child: const Text('مسح التصفية'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);

                                if (isSubTab) {
                                  ref
                                      .read(subItemsListProvider.notifier)
                                      .applyFilters(
                                        groupNo: _asInt(group),
                                        typeNo: _asInt(type),
                                        active: active,
                                        clearGroup: group == 'all',
                                        clearType: type == 'all',
                                      );
                                } else {
                                  ref
                                      .read(itemsListProvider.notifier)
                                      .applyFilters(
                                        groupNo: _asInt(group),
                                        typeNo: _asInt(type),
                                        catNo: _asInt(cat),
                                        unitNo: _asInt(unit),
                                        active: active,
                                        clearGroup: group == 'all',
                                        clearType: type == 'all',
                                        clearCat: cat == 'all',
                                        clearUnit: unit == 'all',
                                      );
                                }
                              },
                              child: const Text('تطبيق'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  static int? _asInt(String value) =>
      value == 'all' ? null : int.tryParse(value);

  /// قائمة منسدلة مضمونة: قيمة واحدة لكل عنصر، وقيمتها من عناصرها دائماً
  /// A guaranteed dropdown: one entry per value, and its value always comes from its own items.
  ///
  /// ── حارسان مثبتان بعطل حقيقي: (١) `DropdownButtonFormField` يرفض أن تتكرر القيمة بين
  ///    العناصر («There should be exactly one item with DropdownButton's value») — وقد حدث فعلاً
  ///    حين قُرئت كل المجموعات 0 فأصبح لديها خمسة عناصر بنفس القيمة `'0'`. (٢) قيمة لا تجد
  ///    عنصراً تُسقط الشرط أيضاً. التكرار يُزال والقيمة تُطابق قبل البناء.
  /// ── Two guards proven by a real defect: (1) DropdownButtonFormField refuses duplicate values
  ///    ("There should be exactly one item with DropdownButton's value") — it fired when every
  ///    group parsed as 0, giving five items with value '0'. (2) A value with no matching item
  ///    trips it too. Duplicates are dropped and the value is matched before building.
  Widget _sheetDropdown({
    required String label,
    required String value,
    required List<(String, String)> items,
    required ValueChanged<String> onChanged,
  }) {
    final seen = <String>{};
    final unique = <(String, String)>[
      for (final row in items)
        if (seen.add(row.$1)) row,
    ];

    final safe = unique.any((row) => row.$1 == value) ? value : unique.first.$1;

    return DropdownButtonFormField<String>(
      value: safe,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: [
        for (final row in unique)
          DropdownMenuItem(
            value: row.$1,
            child: Text(row.$2, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  // ================================================================
  // التنقل والإجراءات
  // Navigation and actions
  // ================================================================

  /// اختيار صنف: في التخطيط العريض يُعرض في اللوحة الجانبية، وعلى الجوال يُنقل إليه
  /// Pick an item: the side panel on wide screens, a pushed screen on phones.
  void _select(ItemModel item) {
    final wide =
        MediaQuery.sizeOf(context).width >= ItemDetailScreen.splitBreakpoint;

    if (!wide) {
      _openDetail(context, item);

      return;
    }

    setState(() => _selectedSanfNo = item.sanfNo);
  }

  Future<void> _openDetail(BuildContext context, ItemModel item) =>
      _openDetailByNo(context, item.sanfNo, item.name);

  Future<void> _openDetailByNo(
    BuildContext context,
    int sanfNo,
    String? name,
  ) async {
    final wide =
        MediaQuery.sizeOf(context).width >= ItemDetailScreen.splitBreakpoint;

    if (wide) {
      setState(() => _selectedSanfNo = sanfNo);

      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(sanfNo: sanfNo)));

    if (!mounted) return;

    ref.read(itemsListProvider.notifier).refreshCurrent();
  }

  /// كشف حركة صنف رئيسي — يفتح تقرير «حركة صنف رئيسي» التابع لتقارير المخازن مباشرة
  /// A main item's statement — opens the stores-reports "main item movement" template at once.
  Future<void> _openMovement(BuildContext context, ItemModel item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => StoreReportsScreen(
              initialFilter: StoreReportFilter.forItemStatement(
                sanfNo: item.sanfNo,
                itemName: item.name,
              ),
            ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {ItemModel? item}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));

    if (!mounted) return;

    ref.read(itemsListProvider.notifier).refreshCurrent();
    ref.read(subItemsListProvider.notifier).load();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ItemsListNotifier notifier,
    ItemModel item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('حذف صنف'),
            content: Text(
              'سيُحذف الصنف «${item.name}» مع أصنافه الفرعية ووحداته. '
              'لا يمكن حذف صنف له حركة مخزنية — عطّله بدلاً من حذفه.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('حذف', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final result = await notifier.remove(item.sanfNo);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'تم حذف الصنف' : result.displayMessage),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }
}

/// بطاقة صنف رئيسي — تخطيط رسمي ثابت: هوية · تصنيف · أرقام · إجراءات
/// A main item card — a fixed, formal layout: identity, classification, numbers, actions.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.selectionMode,
    required this.selected,
    required this.canUpdate,
    required this.canDelete,
    required this.onTap,
    required this.onDetail,
    required this.onMovement,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemModel item;
  final bool selectionMode;
  final bool selected;
  final bool canUpdate;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback onMovement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          selected ? AppColors.primary.withValues(alpha: 0.07) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 19,
                    color: selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              // رمز المجموعة بدل أيقونة عامة: يميّز الأصناف بسرعة في قائمة طويلة
              // A group glyph instead of a generic icon: faster scanning in a long list.
              Container(
                width: 37,
                height: 37,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (item.active ? AppColors.primary : AppColors.warning)
                      .withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: item.active ? AppColors.primary : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.active)
                          const StoreTag(
                            label: 'معطّل',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        'كود ${item.partNo}',                        
                        if (item.typeName != null) item.typeName!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        StoreTag(
                          label: '${item.subs} فرعية',
                          icon: Icons.account_tree_outlined,
                          color: AppColors.info,
                        ),
                        if (item.unitName != null)
                          StoreTag(
                            label: item.unitName!,
                            icon: Icons.straighten_rounded,
                          ),
                        // StoreTag(
                        //   label: StoreFormat.money(item.salePrice),
                        //   icon: Icons.sell_outlined,
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // ── الرصيد يظهر في قائمة الأصناف نفسها: مجموع أرصدة فروعه. لا يُرسل المستخدم إلى
              //    شاشة أخرى ليقرأ رقماً يخصّ الصنف الذي يفتحه.
              // ── The balance lives on the items list itself: the sum of its branches. Nobody is
              //    sent to another screen to read a number about the item they already opened.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    StoreFormat.qty(item.qty),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          item.isNegative
                              ? AppColors.error
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'قيمة ${StoreFormat.money(item.value)}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                tooltip: 'إجراءات',
                icon: const Icon(Icons.more_vert_rounded, size: 19),
                onSelected: (value) {
                  switch (value) {
                    case 'detail':
                      onDetail();
                    case 'movement':
                      onMovement();
                    case 'edit':
                      onEdit();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'detail',
                        child: Text('عرض التفاصيل'),
                      ),
                      const PopupMenuItem(
                        value: 'movement',
                        child: Text('كشف حركة'),
                      ),
                      if (canUpdate)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('تعديل'),
                        ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف'),
                        ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة صنف فرعي في تبويب الفروع
/// A sub item card on the branches tab.
class _SubCard extends StatelessWidget {
  const _SubCard({
    required this.sub,
    required this.onTap,
    required this.onMovement,
    required this.onParent,
  });

  final ItemSubModel sub;
  final VoidCallback onTap;
  final VoidCallback onMovement;
  final VoidCallback onParent;

  @override
  Widget build(BuildContext context) {
    // البطاقة قابلة للنقر كلها: الفرع كيان مستقل له شاشته، والنقر على بطاقة
    // لا يفتح والدَه
    // The whole card is tappable: a branch is its own entity with its own screen, and
    // tapping a card must never open its parent.
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 37,
                height: 37,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${sub.sanfDno}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!sub.active)
                          const StoreTag(
                            label: 'معطّل',
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub.parentName ?? 'صنف ${sub.sanfNo}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        StoreTag(
                          label: sub.colorLabel,
                          icon: Icons.palette_outlined,
                          color: AppColors.info,
                        ),
                        StoreTag(
                          label: sub.sizeLabel,
                          icon: Icons.straighten_rounded,
                        ),
                        if (sub.partNo != null && sub.partNo!.isNotEmpty)
                          StoreTag(label: sub.partNo!),
                      ],
                    ),
                  ],
                ),
              ),
              // ── رصيد الفرع مباشرة: هذا رقمه هو، لا رقم صنفه الأب. مقسوم على الجميع حتى لا
              //    يحتاج المستخدم كشف حركة فرع ليعرف كم بقي منه.
              // ── The branch's own balance, not its parent's. Visible everywhere, so knowing what is
              //    left of a branch never requires opening its statement.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    StoreFormat.qty(sub.qty),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          sub.isNegative
                              ? AppColors.error
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'قيمة ${StoreFormat.money(sub.value)}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'كشف حركة الفرع',
                visualDensity: VisualDensity.compact,
                onPressed: onMovement,
                icon: const Icon(Icons.timeline_rounded, size: 18),
              ),
              IconButton(
                tooltip: 'الصنف الرئيسي',
                visualDensity: VisualDensity.compact,
                onPressed: onParent,
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
