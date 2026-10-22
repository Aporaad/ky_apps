import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../employee_portal/domain/portal_section_titles.dart';
import '../../domain/home_shortcut.dart';
import '../../domain/home_shortcut_catalog.dart';
import '../providers/home_layout_notifier.dart';
import '../widgets/home_tokens.dart';

/// شاشة تخصيص الاختصارات: ما يظهر، وبأي ترتيب
/// The shortcut customisation screen: what shows, and in which order.
///
/// تبويبان لا سحب داخل الشبكة: `ReorderableListView` الأصلي يعطي مقابض سحب وقارئ شاشة مجانًا،
/// بينما سحب الشبكة يحتاج حزمة أو حساب مواضع هشًّا لكل قياس.
/// Two tabs rather than in-grid dragging: the stock `ReorderableListView` brings drag handles and
/// screen-reader support for free, while grid dragging needs a package or fragile per-size maths.
class HomeCustomizeScreen extends ConsumerStatefulWidget {
  const HomeCustomizeScreen({super.key});

  @override
  ConsumerState<HomeCustomizeScreen> createState() =>
      _HomeCustomizeScreenState();
}

class _HomeCustomizeScreenState extends ConsumerState<HomeCustomizeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showActive = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final layoutState = ref.watch(homeLayoutNotifierProvider);
    final allowed = allowedHomeShortcuts(
      granted: auth.permissions,
      isAdmin: auth.isAdmin,
    );
    final active = layoutState.layout.resolve(allowed);
    final available = [
      for (final shortcut in allowed)
        if (!layoutState.layout.isVisible(shortcut)) shortcut,
    ];
    final query = _query.trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تخصيص الاختصارات'),
        actions: [
          TextButton.icon(
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: const Text('استعادة الافتراضي'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن اختصار…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon:
                        _query.isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'مسح البحث',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text('المفعّلة (${active.length})'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text('المتاحة (${available.length})'),
                    ),
                  ],
                  selected: {_showActive ? 0 : 1},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    setState(() => _showActive = selection.first == 0);
                  },
                ),
              ),
              Expanded(
                child:
                    _showActive
                        ? _buildActiveList(active, query)
                        : _buildAvailableList(available, query),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── التبويب الأول: المفعّلة ────────────────────────────────
  // Tab one: active.

  Widget _buildActiveList(List<HomeShortcut> active, String query) {
    final filtered = _filter(active, query);
    if (filtered.isEmpty) {
      return _Note(
        icon: Icons.visibility_off_outlined,
        title:
            query.isEmpty
                ? 'لا اختصارات مفعّلة'
                : 'لا نتيجة مطابقة في المفعّلة',
        message:
            query.isEmpty
                ? 'أضف اختصارات من تبويب «المتاحة».'
                : 'جرّب كلمة أخرى أو امسح البحث.',
      );
    }

    // أثناء البحث تُعطَّل إعادة الترتيب: مؤشرات القائمة المصفّاة لا تُطابق القائمة الكاملة
    // Reordering pauses during search: filtered indices do not match the full list.
    if (query.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: filtered.length,
        itemBuilder:
            (context, index) => _ActiveRow(
              shortcut: filtered[index],
              showHandle: false,
              onHide:
                  () => ref
                      .read(homeLayoutNotifierProvider.notifier)
                      .toggle(filtered[index].id),
            ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      buildDefaultDragHandles: false,
      itemCount: filtered.length,
      onReorder:
          (oldIndex, newIndex) => ref
              .read(homeLayoutNotifierProvider.notifier)
              .move(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final shortcut = filtered[index];

        return _ActiveRow(
          key: ValueKey('active-${shortcut.id}'),
          shortcut: shortcut,
          index: index,
          showHandle: !shortcut.pinned,
          onHide:
              () => ref
                  .read(homeLayoutNotifierProvider.notifier)
                  .toggle(shortcut.id),
        );
      },
    );
  }

  // ── التبويب الثاني: المتاحة ───────────────────────────────
  // Tab two: available.

  Widget _buildAvailableList(List<HomeShortcut> available, String query) {
    final filtered = _filter(available, query);
    if (filtered.isEmpty) {
      return _Note(
        icon: Icons.done_all_rounded,
        title:
            query.isEmpty
                ? 'كل الاختصارات مفعّلة'
                : 'لا نتيجة مطابقة في المتاحة',
        message:
            query.isEmpty
                ? 'لم يبق اختصار متاح لصلاحياتك الحالية.'
                : 'جرّب كلمة أخرى أو امسح البحث.',
      );
    }

    final rows = <Widget>[];
    String? lastSection;
    for (final shortcut in filtered) {
      if (shortcut.sectionId != lastSection) {
        lastSection = shortcut.sectionId;
        rows.add(_GroupHeader(title: PortalSectionTitles.of(lastSection)));
      }
      rows.add(
        _AvailableRow(
          key: ValueKey('available-${shortcut.id}'),
          shortcut: shortcut,
          onAdd:
              () => ref
                  .read(homeLayoutNotifierProvider.notifier)
                  .toggle(shortcut.id),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: rows,
    );
  }

  /// ترشيح محلي بالعناوين وأسماء الأقسام — بلا تأخير لأن لا شبكة هنا
  /// Local filtering over titles and section names — no debounce because there is no network here.
  List<HomeShortcut> _filter(List<HomeShortcut> list, String query) {
    if (query.isEmpty) return list;

    return [
      for (final shortcut in list)
        if (shortcut.title.contains(query) ||
            PortalSectionTitles.of(shortcut.sectionId).contains(query))
          shortcut,
    ];
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('استعادة الافتراضي'),
            content: const Text(
              'سيُعاد ترتيب الاختصارات وتظهر التشكيلة الأولى فقط. هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('استعادة'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(homeLayoutNotifierProvider.notifier).reset();
  }
}

// ── صفوف القوائم ─────────────────────────────────────────────
// List rows.

/// صف اختصار مفعّل: أيقونة، عنوان، قسم، إخفاء، ومقبض سحب
/// An active-shortcut row: icon, title, section, hide, and a drag handle.
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({
    super.key,
    required this.shortcut,
    required this.showHandle,
    required this.onHide,
    this.index,
  });

  final HomeShortcut shortcut;
  final bool showHandle;
  final VoidCallback onHide;
  final int? index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 10, end: 4),
          leading: _RowIcon(shortcut: shortcut),
          title: Text(
            shortcut.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            PortalSectionTitles.of(shortcut.sectionId),
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (shortcut.pinned)
                const Tooltip(
                  message: 'بطاقة دائمة',
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.push_pin_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onHide,
                  tooltip: 'إخفاء',
                  icon: Icon(
                    Icons.visibility_off_outlined,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (showHandle && index != null)
                ReorderableDragStartListener(
                  index: index!,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف اختصار متاح: زر إضافة صريح
/// An available-shortcut row: an explicit add action.
class _AvailableRow extends StatelessWidget {
  const _AvailableRow({super.key, required this.shortcut, required this.onAdd});

  final HomeShortcut shortcut;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsetsDirectional.only(start: 10, end: 6),
          leading: _RowIcon(shortcut: shortcut),
          title: Text(
            shortcut.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            PortalSectionTitles.of(shortcut.sectionId),
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          trailing: IconButton(
            onPressed: onAdd,
            tooltip: 'إضافة إلى الرئيسية',
            icon: Icon(
              Icons.add_circle_outline_rounded,
              size: 21,
              color: HomeTokens.sectionColor(shortcut.sectionId),
            ),
          ),
        ),
      ),
    );
  }
}

/// أيقونة الصف داخل صندوق ملوّن صغير
/// The row icon inside a small tinted box.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.shortcut});

  final HomeShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final color = HomeTokens.sectionColor(shortcut.sectionId);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(shortcut.icon, size: 18, color: color),
    );
  }
}

/// ترويسة مجموعة في تبويب «المتاحة»
/// A group header in the "available" tab.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// ملاحظة مركزية بدل قائمة فارغة
/// A centred note in place of an empty list.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
