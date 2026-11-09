import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../providers/tailoring_providers.dart';
import '../widgets/bill_list_tile.dart';
import 'cutting_bill_progress_screen.dart';
import 'cutting_bill_view_screen.dart';

/// وضع فتح القائمة: استعراض، أو اختيار فاتورة لنموذج التعديل أو للمتابعة
/// Why the list was opened: browse, or pick a bill for the edit form or the progress screen.
///
/// القائمة واحدة في المواضع الثلاثة — تكرارها ثلاث مرات كان سيثلاث البحث والفلترة والصفحات.
/// One list serves all three entry points; tripling it would triple search, filtering and paging.
enum CuttingBillsListMode {
  view,
  editPicker,
  progressPicker;

  String get title => switch (this) {
    CuttingBillsListMode.view => 'فواتير التفصيل',
    CuttingBillsListMode.editPicker => 'اختر فاتورة للتعديل',
    CuttingBillsListMode.progressPicker => 'اختر فاتورة للمتابعة',
  };

  String get subtitle => switch (this) {
    CuttingBillsListMode.view => 'استعراض فواتير التفصيل الأحدث أولاً',
    CuttingBillsListMode.editPicker => 'حدّد الفاتورة التي تريد تعديل بياناتها',
    CuttingBillsListMode.progressPicker => 'حدّد الفاتورة لتتابع سيرها',
  };
}

/// قائمة فواتير التفصيل — البحث والفلترة الزمنية والتصفح اللانهائي
/// The cutting-bill list — search, date range and infinite paging.
///
/// مصدرها `ACCOUNTS.CUTTING_SALES_BILL_VIEW` حصراً، وهي تُسقط أي فاتورة بلا قصّاص أو
/// خيّاط (نحو 20% تغطية)؛ لذلك تُعرض ملاحظة صريحة في رأس القائمة وحالة فراغ تفسيرية.
/// Its source is `ACCOUNTS.CUTTING_SALES_BILL_VIEW` alone, which drops any bill lacking a
/// cutter or tailor (~20% coverage). A plain note in the list header and an explanatory
/// empty state keep that limit visible instead of silently hiding bills.
class CuttingBillsListScreen extends ConsumerStatefulWidget {
  final CuttingBillsListMode mode;

  const CuttingBillsListScreen({super.key, this.mode = CuttingBillsListMode.view});

  @override
  ConsumerState<CuttingBillsListScreen> createState() =>
      _CuttingBillsListScreenState();
}

class _CuttingBillsListScreenState extends ConsumerState<CuttingBillsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    // المزود يعيش خارج الشاشة، فالتحميل الأول يُطلب صراحة عند كل فتح كي لا تُعرض قائمة
    // قديمة بحث سابق ما زال مطبّقاً عليها.
    // The provider outlives the screen, so the first load is requested on each open so a
    // previous search is never silently still applied.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(cuttingBillsListProvider.notifier);
      _searchCtrl.text = ref.read(cuttingBillsListProvider).query;
      if (ref.read(cuttingBillsListProvider).items.isEmpty) {
        notifier.load();
      } else {
        notifier.refresh();
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

  /// تحميل الصفحة التالية قبل الوصول إلى آخر عنصر بهامش صغير
  /// Load the next page shortly before reaching the end.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final remaining = _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    if (remaining < 320) {
      ref.read(cuttingBillsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cuttingBillsListProvider);

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
              Icons.receipt_long_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mode.title,
                    style:  TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.mode.subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
            onPressed: () => ref.read(cuttingBillsListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(state),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  /// شريط البحث + فلتر التاريخ + سطر النطاق والعدد
  /// The search bar, the date filter and the range/count line.
  Widget _buildSearchBar(CuttingBillsListState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (q) =>
                ref.read(cuttingBillsListProvider.notifier).search(q),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'رقم الفاتورة / الرقم اليدوي / العميل / الهاتف / المستفيد',
              hintStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(cuttingBillsListProvider.notifier).search('');
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
                label: Text('فلترة بالتاريخ', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.hasRange
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  side: BorderSide(
                    color: state.hasRange ? AppColors.primary : AppColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (state.hasRange) ...[
                const SizedBox(width: 8),
                Expanded(child: _rangeLabel(state)),
                IconButton(
                  onPressed: () =>
                      ref.read(cuttingBillsListProvider.notifier).setRange(null, null),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'مسح الفلتر',
                  visualDensity: VisualDensity.compact,
                  color: AppColors.error,
                ),
              ] else
                const Spacer(),
              // عدّاد النتائج في سطر الفلترة نفسه: لا سطر إضافي يستهلك ارتفاعاً
              // The result count lives on the filter line itself: no extra row eating height.
              if (!state.isLoading && state.error == null)
                Text(
                  '${state.total} فاتورة',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeLabel(CuttingBillsListState state) {
    final from = state.fromDate;
    final to = state.toDate;
    final text = switch ((from, to)) {
      (final DateTime a, final DateTime b) => '${_fmt(a)} — ${_fmt(b)}',
      (final DateTime a, null) => 'من ${_fmt(a)}',
      (null, final DateTime b) => 'إلى ${_fmt(b)}',
      _ => '',
    };

    return Text(
      text,
      style:  TextStyle(fontSize: 11, color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// لوحة الفلترة: نطاقات جاهزة + تاريخان يدويان
  /// The filter sheet: quick ranges plus two manual dates.
  Future<void> _openRangeSheet() async {
    final state = ref.read(cuttingBillsListProvider);
    final result = await showModalBottomSheet<({DateTime? from, DateTime? to})>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _RangeSheet(from: state.fromDate, to: state.toDate),
    );

    if (result == null || !mounted) return;
    await ref.read(cuttingBillsListProvider.notifier).setRange(result.from, result.to);
  }

  Widget _buildContent(CuttingBillsListState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل فواتير التفصيل...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // الخطأ يُعرض فقط عندما لا توجد صفوف: خطأ عابر أثناء تحديث قائمة ظاهرة لا يغطّيها
    // The error shows only when there are no rows: a transient error while a visible list is
    // refreshing must not cover it.
    if (state.error != null && state.items.isEmpty) {
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
                style:  TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(cuttingBillsListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
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

    if (state.isEmpty) return _buildEmptyState(state);

    return RefreshIndicator(
      onRefresh: () => ref.read(cuttingBillsListProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollCtrl,
        // بطاقات مفصولة بمساحة: القائمة تتنفّس كما في قائمة عملاء المقاسات
        // Cards separated by spacing: the list breathes exactly like the measurements customers list.
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index >= state.items.length) return _buildLoadMoreRow(state);
          final bill = state.items[index];
          return BillListTile(bill: bill, onTap: () => _openBill(bill));
        },
      ),
    );
  }

  Widget _buildLoadMoreRow(CuttingBillsListState state) {
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
                onPressed: () =>
                    ref.read(cuttingBillsListProvider.notifier).loadMore(),
                child: Text('تحميل المزيد', style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }

  /// حالة فراغ تفسيرية: البحث أو الفلتر أو حدود الـ VIEW — كل حالة بنصّها
  /// An explanatory empty state: search, filter or the view's scope — each with its own text.
  Widget _buildEmptyState(CuttingBillsListState state) {
    final (icon, title, description) = switch (state) {
      final s when s.query.isNotEmpty => (
        Icons.search_off_rounded,
        'لا نتائج للبحث',
        'لم تُطابق «${s.query}» أي فاتورة. جرّب رقم الفاتورة أو اسم العميل أو رقم الهاتف.',
      ),
      final s when s.hasRange => (
        Icons.event_busy_rounded,
        'لا فواتير في هذه الفترة',
        'لا توجد فواتير مسندة داخل النطاق المحدد. وسّع الفترة أو امسح الفلتر.',
      ),
      _ => (
        Icons.content_cut_rounded,
        'لا توجد فواتير تفصيل',
        'تُعرض في هذا القسم الفواتير المُسندة إلى قصّاص وخيّاط فقط. الفواتير غير المسندة '
            'لا تظهر هنا، وهذا حدّ في مصدر البيانات لا خطأ في التطبيق.',
      ),
    };

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
              style:  TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style:  TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            if (state.query.isNotEmpty || state.hasRange) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  ref.read(cuttingBillsListProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text('مسح البحث والفلتر'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// فتح الفاتورة حسب وضع القائمة
  /// Open the bill according to the list's mode.
  void _openBill(CuttingBillSummary bill) {
    switch (widget.mode) {
      case CuttingBillsListMode.view:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CuttingBillViewScreen(billKey: bill.key)),
        );
      case CuttingBillsListMode.editPicker:
        // نموذج التعديل نموذج أولي: البطاقة تُحتاج لاختيار الفاتورة فقط
        // The edit form is a prototype: the card is needed only to pick the bill.
        Navigator.of(context).pop(bill);
      case CuttingBillsListMode.progressPicker:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CuttingBillProgressScreen(billKey: bill.key),
          ),
        );
    }
  }
}

/// لوحة اختيار النطاق الزمني
/// The date-range selection sheet.
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
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// النطاقات الجاهزة تُغلق اللوحة فوراً لأنها قرار مكتمل
  /// Quick ranges close the sheet immediately: they are a complete decision.
  void _quick(String type) {
    final now = DateTime.now();
    final (DateTime? from, DateTime? to) = switch (type) {
      'today' => (now, now),
      'week' => (now.subtract(const Duration(days: 7)), now),
      'month' => (DateTime(now.year, now.month, 1), now),
      'year' => (DateTime(now.year, 1, 1), now),
      _ => (null, null),
    };
    Navigator.of(context).pop((from: from, to: to));
  }

  Future<void> _pick(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
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
              _quickChip('اليوم', 'today'),
              _quickChip('الأسبوع', 'week'),
              _quickChip('الشهر', 'month'),
              _quickChip('السنة', 'year'),
              _quickChip('الكل', 'all'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _dateField('من تاريخ', _from, () => _pick(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateField('إلى تاريخ', _to, () => _pick(false))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text('إلغاء'),
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
                    Navigator.of(context).pop((from: _from, to: _to));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('تطبيق'),
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
            const Icon(Icons.event_rounded, size: 15, color: AppColors.textMuted),
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
