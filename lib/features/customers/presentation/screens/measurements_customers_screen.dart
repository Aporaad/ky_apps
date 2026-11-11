import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_customer_model.dart';
import '../providers/customer_measurement_providers.dart';
import '../widgets/measurement_customer_tile.dart';
import '../widgets/measurement_model_picker_sheet.dart';
import 'measurement_view_screen.dart';

/// الشاشة الأولى في قسم «مقاسات العملاء»: قائمة العملاء والمستفيدين للاختيار
/// The section's first screen: the list of customers and beneficiaries to choose from.
///
/// البحث واحد على ثلاثة معاني كما طلب القسم: اسم العميل، رقم هاتفه، أو اسم المستفيد — الخادم
/// هو من يوسّع النتيجة إلى العميل الذي يملك ذلك المستفيد، فلا بحثان في واجهتين.
/// One search covers the three meanings the section asked for: the customer's name, his phone, or
/// a beneficiary's name. The server widens the match to the customer who owns that beneficiary, so
/// the UI never splits the search across two boxes.
///
/// مصدر البيانات `ACCOUNTS.CUTTING_SALES_BILL_VIEW` مجمّعاً على رقم العميل: يظهر هنا من له موديل
/// واحد على الأقل، ويغيب من لا مقاسات له — وهذا حدّ المصدر لا خطأ التطبيق، وتقول به حالة الفراغ.
/// The source is the cutting-bill view aggregated by customer number: anyone with at least one
/// model appears, and a customer without measurements does not — a limit of the source, stated by
/// the empty state rather than hidden.
class MeasurementsCustomersScreen extends ConsumerStatefulWidget {
  const MeasurementsCustomersScreen({super.key});

  @override
  ConsumerState<MeasurementsCustomersScreen> createState() =>
      _MeasurementsCustomersScreenState();
}

class _MeasurementsCustomersScreenState
    extends ConsumerState<MeasurementsCustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  /// أوضاع الترتيب المعروضة — نفس قيم `sort` التي يقبلها الخادم
  /// The sort options shown — the exact `sort` values the server accepts.
  static const Map<String, String> _sorts = {
    'date_desc': 'الأحدث نشاطاً',
    'date_asc': 'الأقدم نشاطاً',
    'name_asc': 'الاسم (أ - ي)',
    'name_desc': 'الاسم (ي - أ)',
  };

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);

    // المزوّد يعيش بعد الشاشة، فيُصفَّر ثم يُطلب تحميل نظيف: قائمة قديمة
    // بنتيجة بحث سابق — حتى مع إعادة ضبط الحقل — توحي بأن البحث لم يعمل.
    // التصفير يسبق الملء، فلا تعود `_searchCtrl.text = state.query
    // تنسخ «خالد» من الجلسة السابقة إلى حقلٍ يُفترض أن يبدأ فارغاً.
    // The provider outlives the screen, so it is wiped before a fresh load.
    // Resyncing the field alone was never enough: `_searchCtrl.text = state.query
    // just copied "خالد" from the previous session into a field that should
    // have started empty, and the stale filtered list underneath made the
    // search look broken.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(measurementCustomersProvider.notifier);
      notifier.resetTransient();
      _searchCtrl.clear();
      notifier.load();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// تحميل الصفحة التالية قبل نهاية القائمة بهامش صغير
  /// Load the next page shortly before the list ends.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final remaining =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.position.pixels;
    if (remaining < 320) {
      ref.read(measurementCustomersProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(measurementCustomersProvider);

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
              Icons.straighten_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مقاسات العملاء',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'اختر العميل لعرض موديلاته السابقة ومقاساتها',
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
          // زر البحث اليدوي إلى جوار المؤجَّل آلياً: نفس قاعدة بقية قوائم التطبيق، لمن يلصق
          // نصاً ولا يريد انتظار المؤقّت.
          // A manual search button beside the debounced one — the app's established rule, for the
          // user who pastes text and will not wait for the timer.
          IconButton(
            onPressed: () => ref
                .read(measurementCustomersProvider.notifier)
                .search(_searchCtrl.text),
            icon: const Icon(Icons.search_rounded, size: 21),
            tooltip: 'بحث',
          ),
          _buildSortButton(state),
          IconButton(
            onPressed: () =>
                ref.read(measurementCustomersProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 21),
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

  /// قائمة الترتيب — القيمة الفعّالة تُعلَّم بشارة، فيعرف القارئ ترتيبه الحالي من الزر نفسه
  /// The sort menu — the active value is check-marked, so the button alone shows the order in use.
  Widget _buildSortButton(MeasurementCustomersState state) {
    return PopupMenuButton<String>(
      tooltip: 'ترتيب',
      icon: const Icon(Icons.sort_rounded, size: 21),
      initialValue: state.sort,
      onSelected: (value) =>
          ref.read(measurementCustomersProvider.notifier).setSort(value),
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

  Widget _buildSearchBar(MeasurementCustomersState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (q) =>
                ref.read(measurementCustomersProvider.notifier).search(q),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'اسم العميل / رقم الهاتف / اسم المستفيد',
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
                        ref
                            .read(measurementCustomersProvider.notifier)
                            .search('');
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _sorts[state.sort] ?? 'الأحدث نشاطاً',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (!state.isLoading && state.error == null)
                Text(
                  '${state.total} عميل',
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

  Widget _buildContent(MeasurementCustomersState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'جارٍ تحميل العملاء...',
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
                onPressed: () =>
                    ref.read(measurementCustomersProvider.notifier).refresh(),
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
      onRefresh: () =>
          ref.read(measurementCustomersProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index >= state.items.length) return _buildLoadMoreRow(state);
          final customer = state.items[index];

          return MeasurementCustomerTile(
            customer: customer,
            onTap: () => _openCustomer(customer),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreRow(MeasurementCustomersState state) {
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
                    ref.read(measurementCustomersProvider.notifier).loadMore(),
                child: const Text(
                  'تحميل المزيد',
                  style: TextStyle(fontSize: 12),
                ),
              ),
      ),
    );
  }

  /// حالة فراغ تشرح نفسها: بحث لا يطابق، أو مصدر لا يغطي هذا العميل
  /// A self-explaining empty state: a search with no match, or a source that excludes a customer.
  Widget _buildEmptyState(MeasurementCustomersState state) {
    final (icon, title, description) = state.query.isNotEmpty
        ? (
            Icons.search_off_rounded,
            'لا نتائج للبحث',
            'لم تُطابق «${state.query}» أي عميل له موديلات تفصيل. جرّب جزءاً من الاسم أو رقم '
                'الهاتف أو اسم المستفيد.',
          )
        : (
            Icons.straighten_rounded,
            'لا توجد عملاء بمقاسات',
            'يعرض هذا القسم العملاء الذين فُصّلت لهم ثياب ومسندة إلى قصّاص وخيّاط فقط، لأن '
                'مصدر البيانات واجهة التفصيل. العميل بلا موديل لا يظهر هنا — وهذا حدّ المصدر لا '
                'خطأ في التطبيق.',
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
            if (state.isFiltered) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  ref.read(measurementCustomersProvider.notifier).clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('مسح البحث'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// الخطوة التالية: موديلات هذا العميل في نافذة منبثقة، ثم مقاسات الموديل المختار
  /// The next step: this customer's models in a popup sheet, then the chosen model's measurements.
  ///
  /// القائمة وسيطة بين العميل والتقرير، فجعلُها شاشة كاملة كان يحوّل كل استعراض موديل إلى رحلة
  /// «أمام ثم خلف»؛ النافذة تُبقي العميل ظاهرًا خلفها وتُغلق باختيار واحد.
  /// The model list is intermediate between the customer and the report, so making it a full
  /// screen turned every model looked at into a forward-and-back trip; the sheet keeps the
  /// customer visible behind it and closes on a single choice.
  Future<void> _openCustomer(MeasurementCustomer customer) async {
    final picked = await MeasurementModelPickerSheet.show(
      context,
      custNo: customer.custNo,
      custName: customer.displayName,
      telNo1: customer.telNo1,
    );

    if (picked == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeasurementViewScreen(
          modelKey: picked.keyOf(customer.custNo),
          custName: customer.displayName,
        ),
      ),
    );
  }
}
