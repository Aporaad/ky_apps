import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../data/models/account_model.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_tree_flatten.dart';
import '../utils/tree_row_layout.dart';
import '../widgets/account_details_sheet.dart';
import '../widgets/account_tree_row_tile.dart';
import '../widgets/tree_export_menu.dart';
import 'account_group_statement_screen.dart';
import 'account_statement_screen.dart';
import 'create_account_screen.dart';
import 'edit_account_screen.dart';

/// شاشة الشجرة المحاسبية — تحميل كسول وأسطر مسطّحة.
/// The chart-of-accounts tree.
///
/// لماذا أُعيدت بناؤها؟ النسخة السابقة كانت تبني `Column` متداخلاً لكل عقدة
/// (21 ألف عقدة في شجرة واحدة)، ببطاقة مستقلة لكل سطر، وتُفلتر حسابات العملاء في
/// العميل، وتقرأ أرصدة الأعمدة المخزّنة الصفرية — فكان العرض بطيئاً ومقصوصاً وفوضوياً.
/// The old screen built a nested `Column` per node with a card per row, filtered
/// customers client-side, and showed the stale stored BALANCE columns. Now: one flat
/// `ListView.builder` over [AccountTreeRow]s, structural skeleton in a single fast
/// request, financial leaves paged per node, and balances rolled up from ENTRY_SUB.
class AccountTreeScreen extends ConsumerStatefulWidget {
  const AccountTreeScreen({super.key});

  @override
  ConsumerState<AccountTreeScreen> createState() => _AccountTreeScreenState();
}

class _AccountTreeScreenState extends ConsumerState<AccountTreeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  AccountTreeFilters _filters = const AccountTreeFilters();

  /// الكثافة المختارة — خمس مستويات بدل مفتاح ثنائي، تُحسب منها قياسات السطر كلها.
  /// Five densities instead of a two-state switch. The row metrics derive from it,
  /// so height, font and column widths move together.
  TreeDensity _density = TreeDensity.compact;
  bool _filtersVisible = true;

  /// نتائج البحث خادمية: البحث داخل 20 ألف حساب بلا تحميل الشجرة كلها.
  List<AccountTreeRow> _searchRows = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── البحث مع تأنٍّ 300ms ───────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(accountTreeProvider.notifier).runSearch(value);
      setState(() => _filters = _filters.copyWith(search: value));
    });
  }

  // ─── الصفوف المعروضة ────────────────────────────────────────────────────────
  List<AccountTreeRow> _visibleRows(AccountTreeState state) {
    if (_filters.search.trim().isNotEmpty) {
      // أثناء البحث: نتائج الخادم مسطّحة بالفعل، مع مسار الأب لكل نتيجة
      // While searching, the server results (each with its parent path) are the list.
      return _searchRows;
    }
    return flattenAccountTree(
      tree: state.tree,
      expanded: state.expanded,
      childrenCache: state.childrenCache,
      loadingChildren: state.loadingChildren,
      childHasMore: state.childHasMore,
      filters: _filters,
    );
  }

  void _syncSearchRows(AccountTreeState state) {
    final query = _filters.search.trim();
    if (query.isEmpty) {
      if (_searchRows.isNotEmpty) setState(() => _searchRows = const []);
      return;
    }
    final rows = <AccountTreeRow>[];
    for (final node in state.searchResults) {
      rows.add(AccountTreeRow.structural(node: node, depth: 0));
    }
    if (!_sameRows(rows)) {
      setState(() => _searchRows = rows);
    }
  }

  bool _sameRows(List<AccountTreeRow> other) {
    if (other.length != _searchRows.length) return false;
    for (var i = 0; i < other.length; i++) {
      if (other[i].node?.id != _searchRows[i].node?.id) return false;
    }
    return true;
  }

  // ─── الإجراءات ──────────────────────────────────────────────────────────────
  Future<void> _toggle(AccountTreeNode node) =>
      ref.read(accountTreeProvider.notifier).toggleExpand(node);

  void _openStatement(AccountTreeRow row) {
    final node = row.node;
    final leaf = row.leaf;

    if (leaf != null || node?.level == 'chart') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountStatementScreen(
            initialAccNo: leaf?.accNo ?? node?.accNo,
            initialAccName: row.title,
          ),
        ),
      );
      return;
    }

    if (node != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountGroupStatementScreen(
            initialAccNo: node.accNo,
            initialAccSub: node.accSub,
            initialAccPart: node.accPart,
            initialGroupId: node.groupId,
          ),
        ),
      );
    }
  }

  void _openEdit(int accNo, String accName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditAccountScreen(accNo: accNo, accName: accName),
      ),
    ).then((changed) {
      if (changed == true) {
        ref.read(accountTreeProvider.notifier).loadTree(keepExpansion: true);
      }
    });
  }

  void _openCreate(AccountCreateKind kind) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAccountScreen(initialKind: kind),
      ),
    ).then((created) {
      if (created == true) {
        ref.read(accountTreeProvider.notifier).loadTree(keepExpansion: true);
      }
    });
  }

  /// زر الكشف: فردي → كشف مالي (statement_financial)، وهيكل → كشف مجموعات
  /// (statement_group). الصلاحية تحدد الظهور فلا يُعرض زر يرفضه الخادم.
  bool _canReveal(AccountTreeRow row) {
    final isLeaf = row.kind == AccountTreeRowKind.leaf ||
        row.node?.level == 'chart';
    return isLeaf
        ? ref.can(Perm.accountsStatementFinancial)
        : ref.can(Perm.accountsStatementGroup);
  }

  String? get _periodLabel {
    final state = ref.read(accountTreeProvider);
    if (state.fromDate == null && state.toDate == null) return null;
    return '${state.fromDate ?? '…'} ← ${state.toDate ?? '…'}';
  }

  String get _filterNote {
    final parts = <String>[];
    if (_filters.sectionAccNo != null) parts.add('القسم ${_filters.sectionAccNo}');
    if (_filters.maxLevel != null) parts.add('أقصى مستوى ${_filters.maxLevel! + 1}');
    if (_filters.hideZeroBalances) parts.add('إخفاء الأرصدة الصفرية');
    if (!_filters.showStopped) parts.add('إخفاء الموقوفة');
    if (_filters.search.trim().isNotEmpty) parts.add('بحث: ${_filters.search}');
    return parts.join(' • ');
  }

  // ─── البناء ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountTreeProvider);
    _syncSearchRows(state);
    final rows = _visibleRows(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الشجرة المحاسبية',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          PermissionGate(
            code: Perm.accountsExport,
            // لا `rows:` بعد الآن: المطبوعة تُطلب من الخادم بنطاق يسأله المستخدم،
            // لا من حالة الشجرة الكسولة التي كانت تطبع الأقسام فقط.
            child: TreeExportMenu(
              periodLabel: _periodLabel,
              filterNote: _filterNote,
              defaultSectionAccNo: _filters.sectionAccNo,
            ),
          ),
          // فتح/إغلاق ظهور الحسابات الفرعية بلمسة واحدة، وزر المستويات لتحديد أعمق.
          // One-tap expand/collapse of every branch, plus the level picker for depth.
          // The chip that used to hold this lives inside the filters bar, which is
          // itself hideable — so the control was not always on screen at all.
          IconButton(
            icon: Icon(
              state.expanded.isEmpty
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
              size: 20,
            ),
            tooltip: state.expanded.isEmpty
                ? 'فتح ظهور الحسابات الفرعية'
                : 'إغلاق ظهور الحسابات الفرعية',
            onPressed: _toggleExpandAll,
          ),
          IconButton(
            icon: const Icon(Icons.format_line_spacing_rounded, size: 20),
            tooltip: 'كثافة الأسطر: ${_density.labelAr}',
            onPressed: _cycleDensity,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: 'خيارات العرض',
            onPressed: _showDisplayOptions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'تحديث الشجرة',
            onPressed: () => ref.read(accountTreeProvider.notifier).loadTree(),
          ),
        ],
      ),
      // LayoutBuilder مرة واحدة: الرأس والأسطر يقرآن نفس القياسات، فتتطابق الأعمدة.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = TreeRowMetrics.resolve(
            width: constraints.maxWidth,
            density: _density,
          );

          return Column(
            children: [
              _buildSearchBar(state),
              if (_filtersVisible) _buildFilterChipsBar(state),
              if (metrics.showColumns && rows.isNotEmpty)
                AccountTreeColumnsHeader(metrics: metrics),
              Expanded(child: _buildBody(state, rows, metrics)),
            ],
          );
        },
      ),
      floatingActionButton: PermissionGate(
        code: Perm.accountsCreate,
        child: FloatingActionButton.extended(
          onPressed: _showCreateSheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة'),
        ),
      ),
    );
  }

  /// تدوير الكثافة عبر مستوياتها الخمسة — نفس الزر الذي كان يقلب حالتين فقط.
  void _cycleDensity() {
    final next = TreeDensity.values[(_density.index + 1) % TreeDensity.values.length];
    setState(() => _density = next);
  }

  /// فتح كل الفروع أو طيّها. الفتح حتى مستوى المجموعات (3) لأن الحسابات المالية
  /// تُجلب كسولاً لكل عقدة، وطيّ الكل هو عكس الزر نفسه.
  /// Opens every branch down to group level, or collapses all. Financial leaves are
  /// fetched lazily per node, so "expand everything" means the deepest structural
  /// level — pulling 20k ledger rows would hang the screen, not fill it.
  void _toggleExpandAll() {
    final notifier = ref.read(accountTreeProvider.notifier);
    if (ref.read(accountTreeProvider).expanded.isEmpty) {
      notifier.expandToLevel(3);
    } else {
      notifier.expandToLevel(-1);
    }
  }

  Widget _buildSearchBar(AccountTreeState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      color: AppColors.surface,
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'بحث شامل برقم أو اسم (كل المستويات)…',
          hintStyle: const TextStyle(fontSize: 12.5),
          prefixIcon: state.isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          suffixIcon: _filters.search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                    ref.read(accountTreeProvider.notifier).clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChipsBar(AccountTreeState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _sectionDropdown(state),
            const SizedBox(width: 6),
            _levelDropdown(),
            const SizedBox(width: 6),
            _sortDropdown(state),
            const SizedBox(width: 6),
            _toggleChip(
              label: 'إخفاء الصفرية',
              icon: Icons.visibility_off_outlined,
              selected: _filters.hideZeroBalances,
              onSelected: (v) =>
                  setState(() => _filters = _filters.copyWith(hideZeroBalances: v)),
            ),
            _toggleChip(
              label: 'إظهار الموقوفة',
              icon: Icons.stop_circle_outlined,
              selected: _filters.showStopped,
              onSelected: (v) =>
                  setState(() => _filters = _filters.copyWith(showStopped: v)),
            ),
            if (_filters.hasActiveFilter)
              TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  ref.read(accountTreeProvider.notifier).clearSearch();
                  setState(() => _filters = const AccountTreeFilters());
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('مسح الفلاتر', style: TextStyle(fontSize: 11)),
              ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'توسيع حتى مستوى محدد',
              child: ActionChip(
                avatar: const Icon(Icons.unfold_more_rounded, size: 15),
                label: const Text('توسيع', style: TextStyle(fontSize: 11)),
                onPressed: _showExpandLevelsSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionDropdown(AccountTreeState state) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<int?>(
          value: _filters.sectionAccNo,
          hint: const Text('القسم', style: TextStyle(fontSize: 11)),
          style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
          borderRadius: BorderRadius.circular(8),
          items: [
            const DropdownMenuItem(value: null, child: Text('كل الأقسام')),
            ...state.tree.map(
              (n) => DropdownMenuItem(
                value: n.accNo,
                child: Text('${n.accNo ?? ''} — ${n.name}'),
              ),
            ),
          ],
          onChanged: (v) =>
              setState(() => _filters = _filters.copyWith(sectionAccNo: v)),
        ),
      ),
    );
  }

  Widget _levelDropdown() {
    const labels = {
      null: 'كل المستويات',
      0: 'الأقسام فقط',
      1: 'حتى الفرعي',
      2: 'حتى الجزئي',
      3: 'حتى المجموعات',
    };
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<int?>(
          value: _filters.maxLevel,
          hint: const Text('المستوى', style: TextStyle(fontSize: 11)),
          style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
          borderRadius: BorderRadius.circular(8),
          items: [
            for (final entry in labels.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (v) =>
              setState(() => _filters = _filters.copyWith(maxLevel: v)),
        ),
      ),
    );
  }

  Widget _sortDropdown(AccountTreeState state) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<String>(
          value: state.sort,
          style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
          borderRadius: BorderRadius.circular(8),
          items: const [
            DropdownMenuItem(value: 'acc_no', child: Text('ترتيب: الرقم')),
            DropdownMenuItem(value: 'name', child: Text('ترتيب: الاسم')),
            DropdownMenuItem(value: 'balance', child: Text('ترتيب: الرصيد')),
          ],
          onChanged: (v) {
            if (v == null) return;
            ref
                .read(accountTreeProvider.notifier)
                .setSort(v, v == 'balance' ? 'desc' : 'asc');
          },
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        avatar: Icon(icon, size: 14, color: selected ? AppColors.primary : AppColors.textMuted),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildBody(AccountTreeState state, List<AccountTreeRow> rows, TreeRowMetrics metrics) {
    if (state.isLoading && state.tree.isEmpty) {
      return const _TreeSkeletonList();
    }

    if (state.error != null && state.tree.isEmpty) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(accountTreeProvider.notifier).loadTree(),
      );
    }

    if (rows.isEmpty) {
      return _EmptyState(
        filtered: _filters.hasActiveFilter,
        onClear: () {
          _searchCtrl.clear();
          ref.read(accountTreeProvider.notifier).clearSearch();
          setState(() => _filters = const AccountTreeFilters());
        },
      );
    }

    final searching = _filters.search.trim().isNotEmpty;

    return RefreshIndicator(
      onRefresh: () => ref.read(accountTreeProvider.notifier).loadTree(keepExpansion: false),
      child: state.isSearching && searching
          ? const _SearchPendingBanner()
          : _rowList(state, rows, searching: searching, metrics: metrics),
    );
  }

  Widget _rowList(
    AccountTreeState state,
    List<AccountTreeRow> rows, {
    required bool searching,
    required TreeRowMetrics metrics,
  }) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      cacheExtent: 600,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final node = row.node;

        if (row.kind == AccountTreeRowKind.loadMore) {
          final host = searching ? null : state.findById(row.hostId ?? '');
          return AccountTreeRowTile(
            row: row,
            metrics: metrics,
            onLoadMore: host == null
                ? null
                : () => ref.read(accountTreeProvider.notifier).loadChildren(host),
          );
        }

        if (row.kind == AccountTreeRowKind.loading) {
          return AccountTreeRowTile(row: row, metrics: metrics);
        }

        final err = row.hostId == null ? null : state.childError(row.hostId!);
        if (row.kind == AccountTreeRowKind.rowError) {
          final host = state.findById(row.hostId ?? '');
          return AccountTreeRowTile(
            row: row,
            metrics: metrics,
            error: err,
            onLoadMore: host == null
                ? null
                : () => ref.read(accountTreeProvider.notifier).reloadNode(host),
          );
        }

        final expanded = node != null && state.expanded.contains(node.id);

        return AccountTreeRowTile(
          row: row,
          metrics: metrics,
          expanded: expanded,
          canReveal: _canReveal(row),
          canEdit: ref.can(Perm.accountsUpdate) &&
              (row.kind == AccountTreeRowKind.leaf || node?.level == 'chart'),
          onTap: () {
            if (searching && node != null) {
              // نتيجة بحث: توسيع المسار إليها ثم إظهارها داخل الهيكل
              ref.read(accountTreeProvider.notifier).revealPath(node);
              ref.read(accountTreeProvider.notifier).clearSearch();
              _searchCtrl.clear();
              setState(() => _filters = _filters.copyWith(search: ''));
              return;
            }
            if (node != null && node.hasChildren) {
              _toggle(node);
            } else if (row.kind == AccountTreeRowKind.leaf) {
              showAccountDetailsSheet(
                context,
                row: row,
                onReveal: (_, target) => _openStatement(target),
                onEdit: (_, accNo, name) => _openEdit(accNo, name),
              );
            }
          },
          onDoubleTap: _canReveal(row) ? () => _openStatement(row) : null,
          onReveal: _canReveal(row) ? () => _openStatement(row) : null,
          onDetails: () => showAccountDetailsSheet(
            context,
            row: row,
            onReveal: (_, target) => _openStatement(target),
            onEdit: (_, accNo, name) => _openEdit(accNo, name),
          ),
          onEdit: (row.kind == AccountTreeRowKind.leaf || node?.level == 'chart')
              ? () {
                  final accNo = row.leaf?.accNo ?? node?.accNo;
                  if (accNo != null) _openEdit(accNo, row.title);
                }
              : null,
          onLoadMore: () {
            final host = state.findById(row.hostId ?? '');
            if (host != null) {
              ref.read(accountTreeProvider.notifier).loadMore(host);
            }
          },
        );
      },
    );
  }

  // ─── نوافذ الخيارات ─────────────────────────────────────────────────────────
  void _showDisplayOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── الكثافة: خمسة مستويات بدل مفتاح ثنائي ───
                // Preview of the row height per option — a name like «كثافة مريحة»
                // does not convey 42 px, the sample line does.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'كثافة الأسطر وحجمها',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                for (final density in TreeDensity.values)
                  RadioListTile<TreeDensity>(
                    value: density,
                    groupValue: _density,
                    dense: true,
                    title: Text(
                      density.labelAr,
                      style: TextStyle(fontSize: 13 + density.fontSize * 0.25),
                    ),
                    subtitle: Text(density.hintAr, style: const TextStyle(fontSize: 10.5)),
                    onChanged: (v) {
                      if (v != null) setState(() => _density = v);
                      Navigator.pop(sheetContext);
                    },
                  ),
                const Divider(height: 1),
                // ─── فتح/إغلاق ظهور الحسابات الفرعية ───
                ListTile(
                  leading: const Icon(Icons.unfold_more_rounded),
                  title: const Text('ظهور الحسابات الفرعية'),
                  subtitle: Text(
                    ref.read(accountTreeProvider).expanded.isEmpty
                        ? 'مغلقة — اضغط لفتح كل الفروع'
                        : 'مفتوحة — اضغط لإغلاق كل الفروع',
                  ),
                  trailing: Switch(
                    value: ref.read(accountTreeProvider).expanded.isNotEmpty,
                    onChanged: (_) {
                      Navigator.pop(sheetContext);
                      _toggleExpandAll();
                    },
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showExpandLevelsSheet();
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('إظهار شريط الفلاتر'),
                  value: _filtersVisible,
                  onChanged: (v) => setState(() => _filtersVisible = v),
                ),
                ListTile(
                  leading: const Icon(Icons.filter_alt_outlined),
                  title: const Text('فترة الأرصدة المجمّعة'),
                  subtitle: Text(_periodLabel ?? 'كامل السجل التاريخي'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showPeriodSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpandLevelsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in const {
                0: 'توسيع الأقسام',
                1: 'توسيع حتى الفرعي',
                2: 'توسيع حتى الجزئي',
                3: 'توسيع حتى المجموعات',
                -1: 'طي الكل',
              }.entries)
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(entry.value),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ref
                        .read(accountTreeProvider.notifier)
                        .expandToLevel(entry.key);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPeriodSheet() async {
    final picked = await showModalBottomSheet<_PeriodPick>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _PeriodPickerSheet(),
    );
    if (picked == null) return;
    await ref
        .read(accountTreeProvider.notifier)
        .loadTree(fromDate: picked.from, toDate: picked.to);
  }

  void _showCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final kind in AccountCreateKind.values)
                ListTile(
                  leading: Icon(accountCreateIcon(kind)),
                  title: Text(accountCreateTitle(kind)),
                  subtitle: Text(accountCreateHint(kind)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openCreate(kind);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── حالات العرض الأربع / the four mandatory states ───────────────────────────
class _TreeSkeletonList extends StatelessWidget {
  const _TreeSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: 16,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, i) => Container(
        height: 32,
        margin: EdgeInsets.only(right: (i % 4) * 14.0, left: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
            const SizedBox(height: 10),
            const Text(
              'تعذّر تحميل الشجرة المحاسبية',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onClear});

  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filtered ? Icons.filter_alt_off_outlined : Icons.account_tree_outlined,
            size: 42,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            filtered ? 'لا نتائج مطابقة للفلاتر' : 'لا توجد حسابات في الهيكل',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          if (filtered) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('مسح الفلاتر'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchPendingBanner extends StatelessWidget {
  const _SearchPendingBanner();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 30),
        Center(
          child: Text(
            'جارٍ البحث في الحسابات…',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// منتقي فترة الأرصدة: null = كامل السجل، وإلا مدى تاريخين يجمّع الأبناء داخلهما.
class _PeriodPick {
  final String? from;
  final String? to;
  const _PeriodPick(this.from, this.to);
}

class _PeriodPickerSheet extends ConsumerStatefulWidget {
  const _PeriodPickerSheet();

  @override
  ConsumerState<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends ConsumerState<_PeriodPickerSheet> {
  DateTime? _from;
  DateTime? _to;

  static String? _iso(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'فترة تجميع الأرصدة',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'بدون فترة: كل الحركات التاريخية. مع فترة: تُجمَّع حركات الفترة فقط.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _from ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _from = d);
                    },
                    child: Text(_from == null ? 'من…' : _iso(_from)!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _to ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _to = d);
                    },
                    child: Text(_to == null ? 'إلى…' : _iso(_to)!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const _PeriodPick(null, null)),
                    child: const Text('كامل السجل'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _PeriodPick(_iso(_from), _iso(_to))),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// أنواع الإنشاء الأربعة معروفة في create_account_screen.dart (AccountCreateKind)
// لتفادي حلقة استيراد: الشاشة تملك الحقول، والشجرة تستورد المنتقي فقط.
// The four create kinds live with the form that owns their fields; the tree imports
// them rather than re-declaring them, so the dependency stays one-way.
