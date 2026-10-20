import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/user_activity_model.dart';
import '../providers/user_activity_provider.dart';
import '../widgets/activity_tile.dart';

/// شاشة سجل نشاط مستخدم — الخط الزمني للعمليات التي نفّذها هذا الحساب
/// A user's activity trail: the timeline of operations this account performed.
///
/// النافذة الزمنية تُطبَّق محلياً لأن الخادم لا يقبل معامل تاريخ في `/users/{id}/activity`،
/// ولهذا يبقى العدّاد «المعروض من الإجمالي» صادقاً: يُقال إن التصفية محلية لا أنها فلترة قاعدة.
/// The time window is applied client-side because the endpoint takes no date parameter, and the
/// counter says so: this is a local filter, not a database one.
class UserActivityScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;

  const UserActivityScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends ConsumerState<UserActivityScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(userActivityProvider.notifier).loadFor(widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userActivityProvider);
    final notifier = ref.read(userActivityProvider.notifier);
    final rows = state.visibleRows;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سجل النشاط'),
            Text(
              widget.userName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: const [_DisabledExportButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _WindowChips(window: state.window, onSelect: notifier.setWindow),
            if (!state.isLoading || state.rows.isNotEmpty)
              _Totals(state: state, visible: rows.length),
            Expanded(child: _Trail(state: state, rows: rows, notifier: notifier)),
          ],
        ),
      ),
    );
  }
}

/// رقائق النافذة الزمنية — نمط `customer_statement_screen` نفسه
/// Time-window chips, the same pattern as the customer statement screen.
class _WindowChips extends StatelessWidget {
  final ActivityWindow window;
  final ValueChanged<ActivityWindow> onSelect;

  const _WindowChips({required this.window, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: ActivityWindow.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = ActivityWindow.values[index];
          final selected = option == window;

          return ChoiceChip(
            label: Text(option.label),
            selected: selected,
            onSelected: (_) => onSelect(option),
            showCheckmark: false,
            selectedColor: AppColors.primary.withValues(alpha: 0.14),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          );
        },
      ),
    );
  }
}

/// سطر العدّ: كم سطراً معروضاً من إجمالي السجل، مع تنبيه التصفية المحلية
/// The counter line: rows shown out of the whole trail, flagged as a local filter.
class _Totals extends StatelessWidget {
  final UserActivityState state;
  final int visible;

  const _Totals({required this.state, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.rows.isEmpty) return const SizedBox.shrink();

    final filtered = state.window != ActivityWindow.all;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'عرض $visible من ${state.total} عملية',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          if (filtered)
            const Text(
              'تصفية محلية بالساعة',
              style: TextStyle(fontSize: 11, color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

/// جسم الخط الزمني بالحالات الأربع
/// The timeline body with its four states.
class _Trail extends StatelessWidget {
  final UserActivityState state;
  final List<UserActivityModel> rows;
  final UserActivityNotifier notifier;

  const _Trail({
    required this.state,
    required this.rows,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 10),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => notifier.loadFor(state.userId),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: 70),
          Icon(Icons.inbox_rounded, size: 42, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'لا عمليات في هذه الفترة',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 6),
          Text(
            'لا يُكتب في السجل إلا ما مرّ عبر الـ API، فالنظام القديم لا يُدخِل سطراً هنا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      itemCount: rows.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: state.isLoadingMore
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OutlinedButton.icon(
                      onPressed: notifier.loadMore,
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      label: const Text('تحميل المزيد'),
                    ),
            ),
          );
        }

        return ActivityTile(row: rows[index]);
      },
    );
  }
}

/// زر التصدير/الطباعة مطفأ عمداً — خارج النطاق بقرار صريح (§13) ولا يُيوهم المستخدم أنه يعمل
/// The export/print button, deliberately disabled: it is out of scope (§13) and must not pretend.
class _DisabledExportButton extends StatelessWidget {
  const _DisabledExportButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.print_outlined, color: AppColors.textMuted),
      tooltip: 'الطباعة والتصدير غير مطبَّقَين بعد',
      onPressed: null,
    );
  }
}
