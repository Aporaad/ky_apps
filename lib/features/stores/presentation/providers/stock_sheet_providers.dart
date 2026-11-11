import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/report_model.dart';
import '../../data/repositories/store_reports_repository.dart';
import 'reports_providers.dart';

/// تصفية سطور كشف الجرد
/// The stock-count line filter.
///
/// ── الفرق لا يُقاس إلا على السطور المُعدَّدة: سطر لم يُلمس حقلُه لا «فرقاً» فيه أصلاً. لذلك
///    «زيادة» و«نقص» و«بفرق» تُستثني غير المعدَّد، وله تصفية مستقلة.
/// ── Variance is only meaningful on counted lines: an untouched line has none. So surplus,
///    shortage and variance all exclude uncounted lines, which get their own filter.
enum StockCountFilter {
  all('الكل'),
  variance('بفرق فقط'),
  surplus('زيادة'),
  shortage('نقص'),
  uncounted('غير معدَّد');

  const StockCountFilter(this.label);

  final String label;
}

/// حالة كشف الجرد — الكميات الفعلية تعيش هنا فقط ولا تُرسل إلى أي خادم
/// The stocktake state — counted quantities live here only and are never sent anywhere.
///
/// ── هذا هو الفرق الجوهري بين هذا الكشف وتقرير الأرصدة: الأرصدة تأتي من `AVVG`، أما
///    «الكمية الفعلية» فهي إدخال بشري مؤقت. لا تُحفظ، ولا تُرسل، ولا تُنشئ مستنداً —
///    فتحديث الشاشة أو إغلاقها يعني إعادة العدّ.
/// ── This is what separates the sheet from a balance report: balances come from AVVG while
///    the counted quantity is temporary human input. It is never saved, never uploaded and
///    never becomes a document, so refreshing or closing the screen means a fresh count.
class StockSheetState {
  const StockSheetState({
    this.rows = const [],
    this.counted = const {},
    this.notes = const {},
    this.isLoading = false,
    this.error,
    this.search = '',
    this.storeNos = const [],
    this.groupNo,
    this.date,
    this.countFilter = StockCountFilter.all,
    this.truncated = false,
    this.hasRun = false,
  });

  final List<StockSheetRow> rows;

  /// الكمية الفعلية لكل سطر — المفتاح `sanfNo|storeNo`
  /// The counted quantity per line, keyed by `sanfNo|storeNo`.
  final Map<String, double> counted;

  /// ملاحظة السطر — تعيش في الحالة فقط مثل الكمية الفعلية، ولا تُحفظ ولا تُرسل
  /// The per-line note — state only, exactly like the counted quantity: never saved, never sent.
  final Map<String, String> notes;
  final bool isLoading;
  final String? error;
  final String search;
  final List<int> storeNos;
  final int? groupNo;
  final DateTime? date;

  /// تصفية «بفرق فقط» — الفرق يعني اختلاف الكمية الفعلية عن رصيد النظام
  /// "Variance only": the counted quantity differs from the system quantity.
  final StockCountFilter countFilter;
  final bool truncated;
  final bool hasRun;

  bool get onlyVariance => countFilter == StockCountFilter.variance;

  double countedOf(StockSheetRow row) => counted[row.key] ?? row.systemQty;

  String noteOf(StockSheetRow row) => notes[row.key] ?? '';

  /// هل في الكشف ملاحظة واحدة على الأقل؟ يُستخدم لإخفاء عمود الملاحظات في التصدير
  /// Whether any line carries a note — used to drop the notes column from exports.
  bool get hasNotes => notes.values.any((note) => note.trim().isNotEmpty);

  /// الفرق = الفعلي − رصيد النظام (موجب زيادة، سالب نقص)
  /// Variance = counted − system (positive surplus, negative shortage).
  double varianceOf(StockSheetRow row) => countedOf(row) - row.systemQty;

  double varianceValueOf(StockSheetRow row) => varianceOf(row) * row.cost;

  /// السطر لم يُعدّ بعد (المستخدم لم يلمس الحقل)
  /// The line has not been counted yet (the field was never touched).
  bool isCounted(StockSheetRow row) => counted.containsKey(row.key);

  int get countedLines => counted.length;

  int get varianceLines =>
      rows.where((row) => isCounted(row) && varianceOf(row) != 0).length;

  double get varianceValue =>
      rows.fold(0, (sum, row) => sum + (isCounted(row) ? varianceValueOf(row) : 0));

  List<StockSheetRow> get visibleRows {
    if (countFilter == StockCountFilter.all) return rows;

    return rows.where((row) {
      final counted = isCounted(row);
      final variance = varianceOf(row);

      return switch (countFilter) {
        // الفرق يُقاس على السطور المُعدَّدة فقط: سطر لم يُلمس لا «فرقاً» فيه
        // Variance applies to counted lines only: an untouched line has no variance.
        StockCountFilter.variance => counted && variance != 0,
        StockCountFilter.surplus => counted && variance > 0,
        StockCountFilter.shortage => counted && variance < 0,
        StockCountFilter.uncounted => !counted,
        StockCountFilter.all => true,
      };
    }).toList(growable: false);
  }

  StockSheetState copyWith({
    List<StockSheetRow>? rows,
    Map<String, double>? counted,
    Map<String, String>? notes,
    bool? isLoading,
    String? error,
    String? search,
    List<int>? storeNos,
    int? groupNo,
    DateTime? date,
    StockCountFilter? countFilter,
    bool? truncated,
    bool? hasRun,
    bool clearError = false,
    bool clearGroup = false,
  }) {
    return StockSheetState(
      rows: rows ?? this.rows,
      counted: counted ?? this.counted,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      search: search ?? this.search,
      storeNos: storeNos ?? this.storeNos,
      groupNo: clearGroup ? null : groupNo ?? this.groupNo,
      date: date ?? this.date,
      countFilter: countFilter ?? this.countFilter,
      truncated: truncated ?? this.truncated,
      hasRun: hasRun ?? this.hasRun,
    );
  }
}

class StockSheetNotifier extends Notifier<StockSheetState> {
  CancelToken? _cancelToken;

  @override
  StockSheetState build() {
    ref.onDispose(() => _cancelToken?.cancel());

    return StockSheetState(date: DateTime.now());
  }

  StoreReportsRepository get _repository =>
      ref.read(storeReportsRepositoryProvider);

  /// تحميل الكشف — لا يمسّ أي جدول مخزني
  /// Load the sheet — touches no inventory table.
  Future<void> load({
    List<int>? storeNos,
    int? groupNo,
    DateTime? date,
    bool clearGroup = false,
  }) async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    state = state.copyWith(
      storeNos: storeNos,
      groupNo: groupNo,
      date: date,
      clearGroup: clearGroup,
      isLoading: true,
      clearError: true,
      counted: const {},
    );

    try {
      final result = await _repository.fetchStockSheet(
        storeNos: state.storeNos,
        groupNo: state.groupNo,
        search: state.search,
        date: state.date,
        cancelToken: _cancelToken,
      );

      // المزود قد يُغلق أثناء جلب الكشف (خروج من الشاشة)
      // The provider may be disposed while the sheet is loading (leaving the screen).
      if (!ref.mounted) return;

      state = state.copyWith(
        rows: result.rows,
        isLoading: false,
        truncated: result.truncated,
        hasRun: true,
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

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim());

    return load();
  }

  /// تفريغ كل شيء في الكشف: البحث والمخازن والمجموعة وتاريخ الجرد والكميات
  /// المضافة والملاحظات.
  /// Clears everything the sheet held: search, stores, group, count date, and
  /// both counted quantities and notes.
  ///
  /// الكمية الفعلية والملاحظة إدخالان بشريان مؤقتان لا يُحفظان ولا يُرسلان،
  /// والخروج من الشاشة يعني إعادة العدّ من الصفر — هذا نصّ الوعاء في أعلاه.
  /// The counted quantity and the note are temporary human input — never
  /// saved, never sent — so leaving the sheet means starting the count again,
  /// exactly as the class documentation promises.
  void resetTransient({bool reload = false}) {
    _cancelToken?.cancel('screen-exited');
    state = StockSheetState(date: DateTime.now());
    if (reload) {
      Future.microtask(() => load(storeNos: const [], clearGroup: true));
    }
  }

  /// تسجيل كمية فعلية لسطر واحد
  /// Record a counted quantity for one line.
  void setCounted(StockSheetRow row, double value) {
    final counted = {...state.counted};
    counted[row.key] = value;

    state = state.copyWith(counted: counted);
  }

  /// مسح عدّ سطر واحد ليعود إلى رصيد النظام
  /// Clear one line back to its system quantity.
  void clearCounted(StockSheetRow row) {
    final counted = {...state.counted}..remove(row.key);

    state = state.copyWith(counted: counted);
  }

  /// تسجيل ملاحظة سطر — تعيش في الحالة فقط مثل الكمية الفعلية
  /// Record a line note — state only, like the counted quantity.
  ///
  /// ── الملاحظة موجودة لسبب عملي: «الفرق لأن الصندوق تالف» تختلف عن «الفرق لأن العدّ ناقص»،
  ///    والمراجع يحتاج قراءة السبب في الكشف المطبوع لا سؤال من عدّ.
  /// ── The note exists for a practical reason: "short because the box was damaged" is not the
  ///    same as "short because the count is incomplete", and a reviewer needs the reason printed.
  void setNote(StockSheetRow row, String note) {
    final notes = {...state.notes};
    final trimmed = note.trim();

    if (trimmed.isEmpty) {
      notes.remove(row.key);
    } else {
      notes[row.key] = trimmed;
    }

    state = state.copyWith(notes: notes);
  }

  void clearAllCounted() => state = state.copyWith(counted: const {});

  void setCountFilter(StockCountFilter filter) =>
      state = state.copyWith(countFilter: filter);

  /// تبديل سريع بين «الكل» و«بفرق فقط» (الزر القديم)
  /// Quick toggle between "all" and "variance only" (the original chip).
  void toggleOnlyVariance() => setCountFilter(
    state.onlyVariance ? StockCountFilter.all : StockCountFilter.variance,
  );

  /// تسجيل حدث الطباعة/التصدير — سجل نشاط فقط
  /// Log the print/export event — an activity row only.
  Future<void> logExport(String action) async {
    await _repository.logAction(
      path: '/stores/stock-sheet/log',
      action: action,
      extra: {
        'date': state.date == null
            ? ''
            : StoreReportsRepository.dateText(state.date!),
        'stores': state.storeNos.isEmpty ? 'الكل' : state.storeNos.join(','),
      },
    );
  }
}

final stockSheetProvider = NotifierProvider<StockSheetNotifier, StockSheetState>(
  StockSheetNotifier.new,
);
