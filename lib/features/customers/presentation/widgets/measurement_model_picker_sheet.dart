import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_model_ref.dart';
import '../providers/customer_measurement_providers.dart';
import 'measurement_model_tile.dart';
import 'measurement_range_sheet.dart';

/// موديلات العميل في واجهة منبثقة — لا شاشة ثابتة
/// The customer's models in a popup sheet — never a full screen.
///
/// الاختيار مرحلة وسيطة بين العميل وشاشة المقاسات: كونه شاشة كاملة يعني رحلة «أمام ثم خلف»
/// لكل موديل يراه المستخدم، بينما النافذة المنبثقة تُبقي العميل ظاهرًا خلفها وتُغلق باختياره.
/// Picking a model is an intermediate step between the customer and the measurements: as a full
/// screen it makes the user travel forward-and-back for every model they look at, while the sheet
/// keeps the customer visible behind it and closes on the choice.
///
/// تُرجع البطاقة المختارة أو `null` عند الإغلاق، فيبقى قرار الدفع لشاشة العملاء.
/// It pops the chosen model or `null` on dismiss, so the navigation stays with the caller.
class MeasurementModelPickerSheet extends ConsumerStatefulWidget {
  final int custNo;
  final String custName;
  final String? telNo1;

  /// محور التمرير يملكه الـ sheet نفسه كي يعمل سحب الرأس مع تمرير القائمة على محور واحد
  /// The sheet's own scroll controller, so dragging the header and paging the list share one axis.
  final ScrollController? scrollController;

  const MeasurementModelPickerSheet({
    super.key,
    required this.custNo,
    required this.custName,
    this.telNo1,
    this.scrollController,
  });

  /// فتح النافذة وإرجاع الموديل المختار — ملفوفة هنا لأن لكل مستدعٍ نفس الحواشي
  /// Opens the sheet and returns the chosen model — wrapped here so every caller gets the same chrome.
  static Future<MeasurementModelRef?> show(
    BuildContext context, {
    required int custNo,
    required String custName,
    String? telNo1,
  }) {
    return showModalBottomSheet<MeasurementModelRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // ارتفاع 88% من الشاشة: القائمة قد تحمل آلاف الموديلات، والتقصير يُلغي الغرض
      // 88% of the screen: a customer can hold thousands of models, and a short sheet defeats that.
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (ctx, scrollCtrl) => MeasurementModelPickerSheet(
          custNo: custNo,
          custName: custName,
          telNo1: telNo1,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  @override
  ConsumerState<MeasurementModelPickerSheet> createState() =>
      _MeasurementModelPickerSheetState();
}

class _MeasurementModelPickerSheetState
    extends ConsumerState<MeasurementModelPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final ScrollController _scroll =
      widget.scrollController ?? ScrollController();
  bool _ownsScroll = false;

  static const Map<String, String> _sorts = {
    'date_desc': 'الأحدث أولاً',
    'date_asc': 'الأقدم أولاً',
    'beneficiary_asc': 'المستفيد (أ - ي)',
  };

  CustomerModelsNotifier get _notifier =>
      ref.read(customerModelsProvider(widget.custNo).notifier);

  @override
  void initState() {
    super.initState();

    if (widget.scrollController == null) {
      _ownsScroll = true;
      // المحور الخارجي لا يُعرف موقعه قبل الإطار الأول، فربط المُستمع يُجّل إليه
      // An outer axis has no position before the first frame, so the listener waits for it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scroll.addListener(_onScroll);
      });
    } else {
      _scroll.addListener(_onScroll);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(customerModelsProvider(widget.custNo));
      _searchCtrl.text = state.query;

      // المزوّد العائلي يبدأ تحميله بنفسه عند أول بناء، والإعادة فوق تحميل جارٍ طلبان لنفس
      // القائمة: الثاني يُلغي الأول في الظل ويضاعف الضغط على أوراكل.
      // The family provider already schedules its own first load; firing again while one is in
      // flight makes two requests for the same list — the second cancels the first and doubles
      // the load on Oracle.
      if (state.isLoading) return;

      if (state.items.isEmpty) {
        _notifier.load();
      } else {
        _notifier.refresh();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    if (_ownsScroll) _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 260) _notifier.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerModelsProvider(widget.custNo));

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildHeader(state),
            _buildFilterRow(state),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  /// رأس النافذة: مقبض سحب + العنوان + الإغلاق
  /// The sheet header: a grab handle, the title and the close action.
  Widget _buildHeader(CustomerModelsState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موديلات ${widget.custName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      state.isLoading
                          ? 'جارٍ التحميل…'
                          : '${state.total} موديل مسجّل · اختر موديلاً لعرض مقاساته',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, size: 20),
                tooltip: 'إغلاق',
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بحث + ترتيب + نطاق زمني في صفين مضغوطين
  /// Search, sort and the date range in two tight rows.
  Widget _buildFilterRow(CustomerModelsState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _notifier.search,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'اسم المستفيد / نوع الموديل / رقم الفاتورة',
              hintStyle: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear_rounded, size: 17),
                      onPressed: () {
                        _searchCtrl.clear();
                        _notifier.search('');
                      },
                    ),
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chipAction(
                label: _sorts[state.sort] ?? 'الأحدث أولاً',
                icon: Icons.sort_rounded,
                active: state.sort != 'date_desc',
                onTap: _openSortMenu,
              ),
              const SizedBox(width: 6),
              _chipAction(
                label: state.hasRange ? _rangeText(state) : 'نطاق التاريخ',
                icon: Icons.date_range_rounded,
                active: state.hasRange,
                onTap: _openRangeSheet,
              ),
              if (state.hasRange || state.query.isNotEmpty) ...[
                const SizedBox(width: 6),
                _chipAction(
                  label: 'مسح',
                  icon: Icons.filter_alt_off_rounded,
                  active: false,
                  tone: AppColors.error,
                  onTap: () {
                    _searchCtrl.clear();
                    _notifier.clearFilters();
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// زر مرشّح صغير — اللون يتغيّر عند التطبيق ليعرف المستخدم أن فلترًا شغّال
  /// A small filter button that changes colour while a filter is actually in force.
  Widget _chipAction({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? tone,
  }) {
    // اللون يُحسم هنا لا في الترويسة: الأساسي ديناميكي فلا يكون قيمة افتراضية ثابتة
    // Resolved in the body: the primary colour is dynamic and cannot be a const default.
    final tint = tone ?? AppColors.primary;
    final color = active ? tint : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: active ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: active ? 0.55 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeText(CustomerModelsState state) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return switch ((state.fromDate, state.toDate)) {
      (final DateTime a, final DateTime b) => '${fmt(a)} — ${fmt(b)}',
      (final DateTime a, null) => 'من ${fmt(a)}',
      (null, final DateTime b) => 'إلى ${fmt(b)}',
      _ => 'نطاق التاريخ',
    };
  }

  Future<void> _openSortMenu() async {
    final state = ref.read(customerModelsProvider(widget.custNo));

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _sorts.entries)
              ListTile(
                dense: true,
                leading: Icon(
                  entry.key == state.sort
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: entry.key == state.sort
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );

    if (chosen != null) await _notifier.setSort(chosen);
  }

  Future<void> _openRangeSheet() async {
    final state = ref.read(customerModelsProvider(widget.custNo));
    final result = await MeasurementRangeSheet.show(
      context,
      from: state.fromDate,
      to: state.toDate,
    );

    if (result == null || !mounted) return;
    await _notifier.setRange(result.from, result.to);
  }

  Widget _buildContent(CustomerModelsState state) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'جارٍ تحميل موديلات العميل...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _notifier.refresh,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(26),
          child: Text(
            'لا موديلات مسجّلة لهذا العميل في بيانات التفصيل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _notifier.refresh,
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, index) {
          if (index >= state.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: state.isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _notifier.loadMore,
                        child: Text(
                          'تحميل المزيد',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
              ),
            );
          }

          final model = state.items[index];

          return MeasurementModelTile(
            model: model,
            // بلا مستفيد يظهر اسم العميل نفسه: «بلا مستفيد محدّد» نص لا يفيده أحد
            // Without a beneficiary the customer's own name shows; "no beneficiary" helps nobody.
            customerName: widget.custName,
            // رقم العميل من هذه النافذة لا من الصف: القائمة محصورة به أصلاً
            // The customer comes from this sheet, never from the row itself.
            onTap: () => Navigator.pop(context, model),
          );
        },
      ),
    );
  }
}
