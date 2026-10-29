import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_model_ref.dart';
import '../providers/customer_measurement_providers.dart';
import '../widgets/measurement_model_tile.dart';
import 'measurement_view_screen.dart';

/// الشاشة الثانية: موديلات العميل السابقة — الأحدث أولاً
/// The second screen: the customer's previous models — newest first.
///
/// كل بطاقة موديل تفتح شاشة المقاسات بمفتاحها الرباعي (عميل، فاتورة، سنة، موديل)، فلا يُطلب
/// موديل بغير صاحبه حتى لو نقر مستخدم على زر التحديث بعد رجوع القائمة.
/// Each card opens the measurements screen with its four-part key (customer, bill, year, model),
/// so no model is ever requested without its owner — even after a refresh tapped after the list
/// navigated back.
class CustomerModelsScreen extends ConsumerStatefulWidget {
  final int custNo;
  final String custName;
  final String? telNo1;

  const CustomerModelsScreen({
    super.key,
    required this.custNo,
    required this.custName,
    this.telNo1,
  });

  @override
  ConsumerState<CustomerModelsScreen> createState() =>
      _CustomerModelsScreenState();
}

class _CustomerModelsScreenState extends ConsumerState<CustomerModelsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const Map<String, String> _sorts = {
    'date_desc': 'الأحدث أولاً',
    'date_asc': 'الأقدم أولاً',
    'beneficiary_asc': 'المستفيد (أ - ي)',
  };

  /// حالة هذا العميل وحده — المزوّد عائلة، فلا تسرب بحث بين شاشة عميل وأخرى
  /// This customer's state alone — the provider is a family, so no search leaks between screens.
  CustomerModelsState get _state =>
      ref.watch(customerModelsProvider(widget.custNo));

  CustomerModelsNotifier get _notifier =>
      ref.read(customerModelsProvider(widget.custNo).notifier);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchCtrl.text = _state.query;
      if (_state.items.isEmpty) {
        _notifier.load();
      } else {
        _notifier.refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final remaining =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    if (remaining < 320) _notifier.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.checkroom_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'موديلات ${widget.custName}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.telNo1 == null
                        ? 'اختر الموديل لعرض مقاساته · عميل ${widget.custNo}'
                        : '${widget.telNo1} · عميل ${widget.custNo}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _notifier.search(_searchCtrl.text),
            icon: const Icon(Icons.search_rounded, size: 21),
            tooltip: 'بحث',
          ),
          _buildSortButton(state),
          IconButton(
            onPressed: _notifier.refresh,
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(state),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildSortButton(CustomerModelsState state) {
    return PopupMenuButton<String>(
      tooltip: 'ترتيب',
      icon: const Icon(Icons.sort_rounded, size: 21),
      initialValue: state.sort,
      onSelected: _notifier.setSort,
      itemBuilder: (_) => [
        for (final entry in _sorts.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                if (entry.key == state.sort)
                  const Icon(Icons.check_rounded, size: 16)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(entry.value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  /// شريط البحث + الفلترة الزمنية + عدّ النتائج
  /// The search field, the date filter and the result count.
  Widget _buildFilterBar(CustomerModelsState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _notifier.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اسم المستفيد / نوع الموديل / رقم الفاتورة',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _notifier.search('');
                      },
                    ),
              filled: true,
              fillColor: AppColors.surfaceSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _openRangeSheet,
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: const Text(
                  'فلترة بالتاريخ',
                  style: TextStyle(fontSize: 11.5),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.hasRange
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  side: BorderSide(
                    color: state.hasRange
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (state.hasRange) ...[
                const SizedBox(width: 8),
                Expanded(child: _rangeLabel(state)),
                IconButton(
                  onPressed: () => _notifier.setRange(null, null),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'مسح الفلتر',
                  visualDensity: VisualDensity.compact,
                  color: AppColors.error,
                ),
              ] else
                const Spacer(),
              if (!state.isLoading && state.error == null)
                Text(
                  '${state.total} موديل',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _rangeLabel(CustomerModelsState state) {
    final text = switch ((state.fromDate, state.toDate)) {
      (final DateTime a, final DateTime b) => '${_fmt(a)} — ${_fmt(b)}',
      (final DateTime a, null) => 'من ${_fmt(a)}',
      (null, final DateTime b) => 'إلى ${_fmt(b)}',
      _ => '',
    };

    return Text(
      text,
      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// لوحة النطاق الزمني — نفس سلوك لوحة فواتير التفصيل (نطاقات جاهزة + تاريخان)
  /// The range sheet — the same behaviour as the cutting-bill list's (quick ranges + two dates).
  Future<void> _openRangeSheet() async {
    final state = ref.read(customerModelsProvider(widget.custNo));
    final result = await showModalBottomSheet<_DateRange>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RangeSheet(from: state.fromDate, to: state.toDate),
    );

    if (result == null || !mounted) return;
    await _notifier.setRange(result.from, result.to);
  }

  Widget _buildContent(CustomerModelsState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل موديلات العميل...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _notifier.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
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

    if (state.isEmpty) return _buildEmptyState(state);

    return RefreshIndicator(
      onRefresh: _notifier.refresh,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index >= state.items.length) return _buildLoadMoreRow(state);
          final model = state.items[index];

          return MeasurementModelTile(
            model: model,
            // رقم العميل يُمرَّر من هذه الشاشة لا من الصف: القائمة محصورة فيه أصلاً
            // The customer comes from this screen, not from the row: the list is already scoped.
            onTap: () => _openModel(model.keyOf(widget.custNo)),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreRow(CustomerModelsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: state.isLoadingMore
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _notifier.loadMore,
                child: const Text(
                  'تحميل المزيد',
                  style: TextStyle(fontSize: 12),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(CustomerModelsState state) {
    final filtered = state.query.isNotEmpty || state.hasRange;

    final (icon, title, description) = filtered
        ? (
            Icons.search_off_rounded,
            'لا موديلات مطابقة',
            state.query.isNotEmpty
                ? 'لم تُطابق «${state.query}» أي موديل لهذا العميل ضمن'
                      '${state.hasRange ? ' الفترة المحددة' : ''}. جرّب اسم المستفيد أو رقم الفاتورة.'
                : 'لا موديلات لهذا العميل في الفترة المحددة. وسّع النطاق أو امسح الفلتر.',
          )
        : (
            Icons.checkroom_rounded,
            'لا موديلات مسجّلة',
            'لا توجد فواتير تفصيل مُسندة إلى قصّاص وخيّاط لهذا العميل، وهي الفواتير التي تحمل '
                'المقاسات في مصدر البيانات.',
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  _notifier.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('مسح الفلاتر'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openModel(MeasurementKey key) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementViewScreen(
          modelKey: key,
          custName: widget.custName,
        ),
      ),
    );
  }
}

/// نتيجة اختيار النطاق الزمني / the chosen date range
class _DateRange {
  final DateTime? from;
  final DateTime? to;

  const _DateRange({this.from, this.to});
}

/// لوحة النطاق الزمني: نطاقات جاهزة + تاريخان يدويان
/// The range sheet: quick ranges plus two manual dates.
class _RangeSheet extends StatefulWidget {
  final DateTime? from;
  final DateTime? to;

  const _RangeSheet({this.from, this.to});

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// النطاقات الجاهزة تُغلق اللوحة فوراً لأنها قرار مكتمل
  /// Quick ranges close the sheet immediately: they are a complete decision.
  void _quick(String type) {
    final now = DateTime.now();
    final (DateTime? from, DateTime? to) = switch (type) {
      'month' => (DateTime(now.year, now.month - 1, 1), now),
      'quarter' => (now.subtract(const Duration(days: 90)), now),
      'year' => (DateTime(now.year, 1, 1), now),
      'all' => (null, null),
      _ => (null, null),
    };
    Navigator.of(context).pop(_DateRange(from: from, to: to));
  }

  /// حدود الاختيار معلنة صراحة: `showDatePicker` تفشل إذا تجاوز `initialDate` الحدود، وقد
  /// سُجّل هذا الانهيار في التحليل السابق للتطبيق.
  /// The bounds are explicit: `showDatePicker` fails when `initialDate` falls outside them, and
  /// that crash is a recorded part of this app's history.
  Future<void> _pick(bool isFrom) async {
    final first = DateTime(2000);
    final last = DateTime(2100);
    final current = (isFrom ? _from : _to) ?? DateTime.now();
    final initial = current.isBefore(first) || current.isAfter(last)
        ? DateTime.now()
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'اختر تاريخ البداية' : 'اختر تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'تحديد',
    );
    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فلترة بالتاريخ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('الشهر الماضي', 'month'),
              _quickChip('الثلاثة أشهر', 'quarter'),
              _quickChip('هذه السنة', 'year'),
              _quickChip('الكل', 'all'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dateField('من تاريخ', _from, () => _pick(true))),
              const SizedBox(width: 10),
              Expanded(
                child: _dateField('إلى تاريخ', _to, () => _pick(false)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_from != null && _to != null && _from!.isAfter(_to!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تاريخ البداية بعد تاريخ النهاية'),
                        ),
                      );

                      return;
                    }
                    Navigator.of(context).pop(_DateRange(from: _from, to: _to));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, String type) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      onPressed: () => _quick(type),
      backgroundColor: AppColors.surfaceSubtle,
      side: const BorderSide(color: AppColors.border),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_rounded,
              size: 15,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value == null ? label : _fmt(value),
                style: TextStyle(
                  fontSize: 12,
                  color: value == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
