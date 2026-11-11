import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/store_reports_repository.dart';

/// مستودع التقارير
/// The reports repository.
final storeReportsRepositoryProvider = Provider<StoreReportsRepository>((ref) {
  return StoreReportsRepository(client: ref.watch(dioClientProvider));
});

// ================================================================
// الأرصدة
// Balances
// ================================================================

class BalancesState {
  const BalancesState({
    this.rows = const [],
    this.isLoading = false,
    this.error,
    this.search = '',
    this.storeNos = const [],
    this.groupNo,
    this.typeNo,
    this.only = 'all',
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.totalQty = 0,
    this.totalValue = 0,
    this.negative = 0,
  });

  final List<StockBalanceRow> rows;
  final bool isLoading;
  final String? error;
  final String search;
  final List<int> storeNos;
  final int? groupNo;
  final int? typeNo;
  final String only;
  final int page;
  final int pages;
  final int total;
  final double totalQty;
  final double totalValue;
  final int negative;

  int get filtersCount {
    var count = 0;
    if (storeNos.isNotEmpty) count++;
    if (groupNo != null) count++;
    if (typeNo != null) count++;
    if (only != 'all') count++;

    return count;
  }

  BalancesState copyWith({
    List<StockBalanceRow>? rows,
    bool? isLoading,
    String? error,
    String? search,
    List<int>? storeNos,
    int? groupNo,
    int? typeNo,
    String? only,
    int? page,
    int? pages,
    int? total,
    double? totalQty,
    double? totalValue,
    int? negative,
    bool clearError = false,
    bool clearGroup = false,
    bool clearType = false,
  }) {
    return BalancesState(
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      storeNos: storeNos ?? this.storeNos,
      groupNo: clearGroup ? null : groupNo ?? this.groupNo,
      typeNo: clearType ? null : typeNo ?? this.typeNo,
      only: only ?? this.only,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      totalQty: totalQty ?? this.totalQty,
      totalValue: totalValue ?? this.totalValue,
      negative: negative ?? this.negative,
    );
  }
}

class BalancesNotifier extends Notifier<BalancesState> {
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  @override
  BalancesState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    Future.microtask(() => load());

    return const BalancesState(isLoading: true);
  }

  StoreReportsRepository get _repository =>
      ref.read(storeReportsRepositoryProvider);

  Future<void> load({bool keepPage = false}) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final version = ++_searchVersion;
    final page = keepPage ? state.page : 1;

    state = state.copyWith(isLoading: true, clearError: true, page: page);

    try {
      final result = await _repository.fetchBalances(
        search: state.search,
        storeNos: state.storeNos,
        groupNo: state.groupNo,
        typeNo: state.typeNo,
        only: state.only,
        page: page,
        cancelToken: _cancelToken,
      );

      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(
        rows: result.rows,
        isLoading: false,
        page: page,
        pages: result.meta['pages'] is num
            ? (result.meta['pages'] as num).toInt()
            : 1,
        total: result.totalRows,
        totalQty: result.meta['qty'] is num ? (result.meta['qty'] as num).toDouble() : 0,
        totalValue:
            result.meta['value'] is num ? (result.meta['value'] as num).toDouble() : 0,
        negative: result.meta['negative'] is num
            ? (result.meta['negative'] as num).toInt()
            : 0,
      );
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      if (!ref.mounted || version != _searchVersion) return;

      state = state.copyWith(isLoading: false, error: storeErrorMessage(error));
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim());

    return load();
  }

  Future<void> applyFilters({
    List<int>? storeNos,
    int? groupNo,
    int? typeNo,
    String? only,
    bool clearGroup = false,
    bool clearType = false,
  }) async {
    state = state.copyWith(
      storeNos: storeNos,
      groupNo: groupNo,
      typeNo: typeNo,
      only: only,
      clearGroup: clearGroup,
      clearType: clearType,
    );

    return load();
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(page: page);

    return load(keepPage: true);
  }

  /// تفريغ البحث والمعطيات عند مغادرة شاشة الأرصدة أو نهاية الجلسة.
  /// Clears the search and every parameter when the balances screen exits.
  ///
  /// الأرصدة صفحة تُحمَّل تلقائياً عند `build()`؛ تبديل التبويب يبقيها mounted
  /// داخل `IndexedStack` فلا يُعاد `build()` — الجلب ضروري لعرض الصفحة الأولى
  /// كاملة بدل آخر مجموعة فلاتر.
  /// Balances auto-load on `build()`, but a tab switch keeps the screen mounted
  /// inside the `IndexedStack` so `build()` never reruns — refetching here is
  /// what replaces the last filter set with the first page again.
  void resetTransient({bool reload = false}) {
    _searchVersion++;
    _cancelToken?.cancel('screen-exited');
    state = const BalancesState(isLoading: true);
    if (reload) Future.microtask(load);
  }
}

final balancesProvider = NotifierProvider<BalancesNotifier, BalancesState>(
  BalancesNotifier.new,
);

// ================================================================
// تقرير الحركة والخلاصة
// Movement and summary report
// ================================================================

class StoreReportState {
  const StoreReportState({
    this.filter,
    this.isLoading = false,
    this.error,
    this.movementRows = const [],
    this.summaryRows = const [],
    this.totalIn = 0,
    this.totalOut = 0,
    this.totalValue = 0,
    this.stats = const ReportStats(),
    this.sections = const [],
    this.truncated = false,
    this.hasRun = false,
  });

  /// المعطيات المستخدمة في آخر تشغيل — ترويسة الطباعة تقرأ منها
  /// The parameters of the last run — the printed header reads them.
  final StoreReportFilter? filter;
  final bool isLoading;
  final String? error;
  final List<StockMovementRow> movementRows;
  final List<StockSummaryRow> summaryRows;
  final double totalIn;
  final double totalOut;
  final double totalValue;

  /// الإحصاءات الكاملة للتقرير: السابق والوارد والمنصرف والصافي والحالي كمية وقيمة
  /// The report's full statistics: opening, in, out, net and closing, quantity and value.
  final ReportStats stats;

  /// أقسام التقرير الموسّع — عنوان وإحصاء لكل قسم بترتيبه
  /// The sections of a scoped report — a label and statistics per section, in order.
  final List<ReportSectionHeader> sections;
  final bool truncated;

  /// هل نُفِّذ تقرير واحد على الأقل؟ (يميّز «لم يعرض بعد» عن «لا نتائج»)
  /// Has any report been run? (distinguishes "not yet" from "no results").
  final bool hasRun;

  StoreReportKind get kind => filter?.kind ?? StoreReportKind.movement;

  bool get isEmpty =>
      hasRun && movementRows.isEmpty && summaryRows.isEmpty && !isLoading;

  StoreReportState copyWith({
    StoreReportFilter? filter,
    bool? isLoading,
    String? error,
    List<StockMovementRow>? movementRows,
    List<StockSummaryRow>? summaryRows,
    double? totalIn,
    double? totalOut,
    double? totalValue,
    ReportStats? stats,
    List<ReportSectionHeader>? sections,
    bool? truncated,
    bool? hasRun,
    bool clearError = false,
  }) {
    return StoreReportState(
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      movementRows: movementRows ?? this.movementRows,
      summaryRows: summaryRows ?? this.summaryRows,
      totalIn: totalIn ?? this.totalIn,
      totalOut: totalOut ?? this.totalOut,
      totalValue: totalValue ?? this.totalValue,
      stats: stats ?? this.stats,
      sections: sections ?? this.sections,
      truncated: truncated ?? this.truncated,
      hasRun: hasRun ?? this.hasRun,
    );
  }
}

/// عنوان قسم وإحصاؤه — يقرّرهما الخادم لا الشاشة
/// A section's label and statistics — decided by the server, not the screen.
class ReportSectionHeader {
  const ReportSectionHeader({
    required this.key,
    required this.label,
    required this.stats,
  });

  /// مفتاح القسم كما يحمله كل سطر في `sectionKey` — به تُقرن الإحصاءات بالسطور
  /// The section key as every row carries it in `sectionKey` — the pair used to join the
  /// statistics to their rows.
  final String key;
  final String label;
  final ReportStats stats;
}

class StoreReportNotifier extends Notifier<StoreReportState> {
  CancelToken? _cancelToken;

  @override
  StoreReportState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    return const StoreReportState();
  }

  StoreReportsRepository get _repository =>
      ref.read(storeReportsRepositoryProvider);

  /// تشغيل التقرير بمعطيات النافذة المنبثقة
  /// Run the report with the filter sheet's parameters.
  Future<void> run(StoreReportFilter filter) async {
    if (!filter.isValid) {
      state = state.copyWith(
        filter: filter,
        isLoading: false,
        error: 'تاريخ البداية بعد تاريخ النهاية',
      );

      return;
    }

    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      filter: filter,
      isLoading: true,
      clearError: true,
      movementRows: const [],
      summaryRows: const [],
    );

    try {
      if (filter.kind == StoreReportKind.movement) {
        final result = await _repository.fetchMovement(
          filter,
          cancelToken: _cancelToken,
        );

        if (!ref.mounted) return;

        state = StoreReportState(
          filter: filter,
          isLoading: false,
          hasRun: true,
          movementRows: result.rows,
          totalIn: result.totalIn,
          totalOut: result.totalOut,
          totalValue: result.totalValue,
          stats: result.stats,
          sections: [
            for (var i = 0; i < result.sectionLabels.length; i++)
              ReportSectionHeader(
                key: i < result.sectionKeys.length ? result.sectionKeys[i] : '',
                label: result.sectionLabels[i],
                stats: result.sectionStats[i],
              ),
          ],
          truncated: result.truncated,
        );

        return;
      }

      final result = await _repository.fetchSummary(
        filter,
        cancelToken: _cancelToken,
      );

      if (!ref.mounted) return;

      state = StoreReportState(
        filter: filter,
        isLoading: false,
        hasRun: true,
        summaryRows: result.rows,
        totalIn: result.totalIn,
        totalOut: result.totalOut,
        totalValue: result.totalValue,
        stats: result.stats,
        truncated: result.truncated,
      );
    } catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      if (!ref.mounted) return;

      state = state.copyWith(
        isLoading: false,
        hasRun: true,
        error: storeErrorMessage(error),
      );
    }
  }

  /// تحديث المعطيات دون تشغيل (تعديل النافذة)
  /// Update the parameters without running (while editing the sheet).
  void updateFilter(StoreReportFilter filter) =>
      state = state.copyWith(filter: filter);

  /// تسجيل طباعة/تصدير التقرير
  /// Log the report print/export event.
  Future<void> logExport(String action) async {
    final filter = state.filter;

    await _repository.logAction(
      path: '/stores/reports/export-log',
      action: action,
      extra: {
        'report': filter?.kind.code ?? 'movement',
        'from': filter?.fromText ?? '',
        'to': filter?.toText ?? '',
      },
    );
  }

  /// تفريغ معطيات التقرير والنتائج عند مغادرة الشاشة.
  /// Clears the parameters and the rows when the report screen exits.
  ///
  /// لا `reload`: تقرير بلا معطيات لا يُنفَّذ، والمعطيات نفسها هي القرار
  /// الذي على المستخدم اتخاذه من النافذة المنبثقة عند العودة.
  /// No `reload` — a report without parameters cannot run, and the parameters
  /// themselves are the decision the user must re-take in the sheet on return.
  void resetTransient({bool reload = false}) {
    // `reload` مقصود به اتساق التوقيع مع بقية المزودات؛ تقرير بلا معطيات
    // لا معنى له أصلاً فلا يُعاد جلبه.
    // `reload` is kept only to align the signature with every other notifier;
    // an unparameterised report has nothing to refetch.
    _cancelToken?.cancel('screen-exited');
    state = const StoreReportState();
  }
}

final storeReportProvider = NotifierProvider<StoreReportNotifier, StoreReportState>(
  StoreReportNotifier.new,
);
