import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/account_group_statement_model.dart';
import '../../data/models/account_model.dart';
import '../../data/repositories/account_repository.dart';
import '../providers/accounts_provider.dart';
import '../utils/group_statement_scope.dart';
import '../utils/statement_date_parser.dart';
import '../widgets/account_group_statement_report_table.dart';
import '../widgets/tree_export_menu.dart';

/// سقف الصفوف التي تُجلب تلقائياً إلى الشاشة. تجاوزه لا يمنع التقرير، لكنه
/// يوقف التنزيل التلقائي ويعرض «النطاق واسع جدًا، اختر مجموعة أدق» مع زر
/// تصدير كامل من الخادم وزر صريح لعرض كل الصفوف تدريجياً.
/// Rows fetched automatically before the "scope too wide" banner appears.
const int kGroupStatementMaxOnScreenRows = 2000;

String _formatDateDash(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String _formatDateSlash(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// شاشة "كشف حساب مجموعة حسابات جزئية" (ميزان المراجعة) - التقرير 2.
/// أربع قوائم منسدلة متسلسلة + نطاق تواريخ اختياري (بلا افتراضي تلقائي، خلافًا
/// للتقرير الأول) يعرض كل الحركات عند تركه فارغًا، مطابق لـ TRIAL_BALANCE_REPORT.pdf.
///
/// ### كيف تُعالَج النطاقات الكبيرة؟ / How are large scopes handled?
/// نطاق واحد قد يضم عشرين ألف حساب. الجلب كان دفعة واحدة فمات التطبيق بـ OOM
/// (انظر user_commends.md 2026-10-26)، لذا صار المسار:
/// 1. الترقية على الخادم (`page`/`limit`) والإجماليات تُحسب على النطاق كله مرة واحدة.
/// 2. مهلة 3 ثوانٍ بعد آخر تغيير في الاختيار — لا طلب والمستخدم ما زال يختار.
/// 3. الصفحة الأولى تُعرض فوراً، ثم تُضاف بقية الأقسام صفحةً بعد صفحة أمام عينه.
/// 4. تجاوز 2000 صف يوقف الإضافة التلقائية ويطلب نطاقاً أدق + تصديراً كاملاً.
/// A single scope can hold 20 000 accounts; fetching it in one shot killed the
/// app with an OOM. The path is now: server pagination + scope-wide totals →
/// a 3 s quiet period after the last selection → page 1 shown at once, the rest
/// appended chunk by chunk → beyond 2000 rows the automatic download stops and
/// the screen asks for a narrower scope with a full server-side export.
class AccountGroupStatementScreen extends ConsumerStatefulWidget {
  /// التهيئة من الشجرة المحاسبية: العقدة تمرّر سلسلتها الكاملة (أعمق مستوى يفوز)
  /// فيُفتح الكشف عليها مباشرة بدل بدء التصفّح من أول حساب في الشجرة.
  /// Seeded from the tree: the tapped node passes its whole chain — the deepest
  /// level wins — so the trial balance opens on it instead of defaulting to the
  /// first section.
  final int? initialAccNo;
  final int? initialAccSub;
  final int? initialAccPart;
  final int? initialGroupId;

  /// المهلة بين آخر تغيير في الاختيار وبدء الجلب. >= 3 ثوانٍ شرطٌ من المستخدم
  /// («انتضار اختيار المستخدم حساب»)، وقابلة للتقصير في الاختبارات فقط.
  /// Quiet period between the last selection and the fetch — the 3 s floor is a
  /// product requirement; tests shrink it instead of faking time.
  final Duration fetchDelay;

  /// نفس المهلة الافتراضية، منشورة ليستعملها الاختبار والشاشات الأخرى.
  /// The default quiet period, exposed for tests and sibling screens.
  static const Duration defaultFetchDelay = Duration(seconds: 3);

  const AccountGroupStatementScreen({
    this.initialAccNo,
    this.initialAccSub,
    this.initialAccPart,
    this.initialGroupId,
    this.fetchDelay = defaultFetchDelay,
    super.key,
  });

  @override
  ConsumerState<AccountGroupStatementScreen> createState() =>
      _AccountGroupStatementScreenState();
}

class _AccountGroupStatementScreenState
    extends ConsumerState<AccountGroupStatementScreen> {
  /// حجم القسم الواحد: صفحة أولى أثقل (تحسب الإجماليات)، وكل قسم بعدها استعلام
  /// تجميعي واحد. 1000 توازن بين زمن الاستجابة (2.5-4 ثانية للقسم) وعدد الطلبات
  /// (نطاق 20774 حساباً = 21 قسماً بدل 42 بحجم 500).
  /// Chunk size: 1000 balances responsiveness against round trips (a 20 774-row
  /// scope becomes 21 chunks instead of 42 at 500).
  static const int _pageSize = 1000;

  /// المساحة المحجوزة داخل الورقة للترويسة والعنوان وسطر الفترة والتذييل — بها
  /// يُحسب ارتفاع منطقة الصفوف القابلة للتمرير.
  /// Sheet space reserved for the letterhead, title, period line and footer, so
  /// the scrollable rows area gets a real height instead of an unbounded one.
  static const double _sheetChromeHeight = 340;

  int? _accNo;
  int? _accSub;
  int? _accPart;
  int? _groupId;

  DateTime? _fromDate;
  DateTime? _toDate;

  bool _filtersVisible = true;
  TrialBalanceReport _report = TrialBalanceReport.empty;
  String? _error;

  // ── حالة الجلب / fetch state ──────────────────────────────────────────
  /// مؤقّت المهلة (3 ثوانٍ) — يُلغى ويُعاد مع كل تغيير في الاختيار.
  Timer? _debounce;

  /// رمز إلغاء الطلب الجاري — يمنع استجابة نطاق سابق من الرسم فوق نطاق جديد.
  CancelToken? _token;

  /// رقم التشغيل: يزداد مع كل طلب ويُقارن عند كل استجابة. أرخص وأدق من مقارنة
  /// الوسائط، ويمنع «setState بعد التخلص» من الجذر.
  /// Monotonic run id compared on every response — the race guard.
  int _runId = 0;

  /// داخل مهلة الانتظار: لا طلب بعد، والشاشة تقول ذلك صراحة.
  bool _pending = false;

  /// طلب فعلي قيد التنفيذ (الصفحة الأولى).
  bool _isLoading = false;

  /// تنزيل بقية الأقسام بعد ظهور الصفحة الأولى.
  bool _isStreaming = false;

  /// تجاوز المستخدم لحدّ العرض الآمن صراحةً («عرض كل الصفوف تدريجياً»).
  bool _showAllRequested = false;

  // أعلام التهيئة التلقائية للاختيار الافتراضي (أول حساب رئيسي ثم أول فرعي ثم أول
  // جزئي) مرة واحدة فقط حتى لا يُفرض الاختيار مجدداً بعد تدخّل المستخدم.
  // One-shot flags for the initial auto-selection (first main → first sub → first
  // part) so the default is never re-imposed after the user interacts.
  bool _autoSelectedAccNo = false;
  bool _autoSelectedAccSub = false;
  bool _autoSelectedAccPart = false;

  /// هل النطاق الحالي أوسع من حدّ العرض والتنزيل التلقائي؟
  /// True while the scope is wider than the automatic download cap.
  bool get _isTooWide =>
      !_showAllRequested && _report.total > kGroupStatementMaxOnScreenRows;

  @override
  void initState() {
    super.initState();
    // مجلوبة من عقدة في الشجرة → النطاق معلوم مسبقاً، فتُعطَّل التلقائية الثلاث
    // وإلا استبدل التصفّح التلقائي اختيار المستخدم فور أول بناء.
    final seeded = widget.initialGroupId != null ||
        widget.initialAccPart != null ||
        widget.initialAccSub != null ||
        widget.initialAccNo != null;
    if (!seeded) return;

    _accNo = widget.initialAccNo;
    _accSub = widget.initialAccSub;
    _accPart = widget.initialAccPart;
    _groupId = widget.initialGroupId;
    _autoSelectedAccNo = true;
    _autoSelectedAccSub = true;
    _autoSelectedAccPart = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleLoad();
    });
  }

  @override
  void dispose() {
    // مؤقّت معلّق بعد مغادرة الشاشة كان سيطلب شبكةً ثم يلمس حالة ميتة.
    // A pending timer after disposal would fire a request into a dead state.
    _debounce?.cancel();
    _token?.cancel('غادر المستخدم شاشة الكشف');
    _token = null;
    super.dispose();
  }

  /// إبطال أي جلب جارٍ فوراً: رقم تشغيل جديد + إلغاء الرمز.
  /// Aborts any in-flight fetch: new run id plus a cancelled token.
  void _abortInFlight() {
    _runId++;
    _token?.cancel('تغيّر نطاق التقرير');
    _token = null;
  }

  /// جدولة جلب بعد آخر تغيير في الاختيار (مهلة 3 ثوانٍ).
  ///
  /// الشرط من المستخدم: لا نطلب شيئاً والمستخدم ما زال يختار حساباً. كل تغيير
  /// يلغي المؤقّت ويبدأ الثواني من جديد، ويلغي أي طلب جارٍ حتى لا تتنافس
  /// استجابتان على نفس الشاشة. التقرير السابق يُمسح فوراً لأن أرقام نطاق قديم
  /// تحت اسم نطاق جديد أسوأ من الانتظار.
  /// Debounced fetch: every selection restarts the quiet period and cancels any
  /// in-flight request. The previous report is cleared at once — showing an old
  /// scope's figures under a new scope's name is worse than waiting.
  void _scheduleLoad() {
    _debounce?.cancel();
    _abortInFlight();
    setState(() {
      _pending = true;
      _isLoading = false;
      _isStreaming = false;
      _showAllRequested = false;
      _report = TrialBalanceReport.empty;
      _error = null;
    });
    _debounce = Timer(widget.fetchDelay, () {
      if (mounted) _loadReport();
    });
  }

  /// جلب الصفحة الأولى ثم متابعة بقية الأقسام تدريجياً.
  ///
  /// الصفحة الأولى وحدها تحمل الإجماليات (محسوبة على النطاق كله في الخادم)،
  /// فسطر الإجمالي صحيح منذ اللحظة الأولى وبقية الصفحات تُضاف للعرض فقط.
  /// Only page 1 asks for totals — they already cover the whole scope, so the
  /// grand-total line is correct before the remaining chunks arrive.
  Future<void> _loadReport() async {
    final scope = resolveStatementScope(
      accNo: _accNo,
      accSub: _accSub,
      accPart: _accPart,
      groupId: _groupId,
    );
    if (scope == null) {
      _abortInFlight();
      setState(() {
        _pending = false;
        _isLoading = false;
        _isStreaming = false;
        _report = TrialBalanceReport.empty;
        _error = 'يجب اختيار حساب رئيسي على الأقل لتحديد نطاق التقرير';
      });
      return;
    }

    _debounce?.cancel();
    _abortInFlight();
    final token = CancelToken();
    _token = token;
    final runId = _runId;
    final repo = ref.read(accountRepositoryProvider);

    setState(() {
      _pending = false;
      _isLoading = true;
      _isStreaming = false;
      _showAllRequested = false;
      _error = null;
      _report = TrialBalanceReport.empty;
    });

    try {
      final first = await repo.fetchGroupStatement(
        accNo: scope.accNo,
        accSub: scope.accSub,
        accPart: scope.accPart,
        groupId: scope.groupId,
        fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
        toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
        page: 1,
        limit: _pageSize,
        includeTotals: true,
        cancelToken: token,
      );
      if (!mounted || runId != _runId) return;

      // نطاق أوسع من الحدّ: نعرض القسم الأول فقط ونطلب من المستخدم تضييق النطاق
      // أو التصدير من الخادم أو تجاوز الحدّ صراحةً — لا نُنزل 20 ألف صف تلقائياً.
      final tooWide = first.total > kGroupStatementMaxOnScreenRows;
      setState(() {
        _report = first;
        _isLoading = false;
        _isStreaming = !tooWide && first.hasMore;
      });
      if (tooWide || !first.hasMore) return;
      await _streamPages(repo, scope, first, runId, token);
    } on DioException catch (e) {
      if (!mounted || runId != _runId || CancelToken.isCancel(e)) return;
      _showFailure(e);
    } catch (e) {
      if (!mounted || runId != _runId) return;
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _error = 'خطأ في جلب التقرير: $e';
      });
    }
  }

  /// تنزيل بقية الأقسام قسمًا بعد قسم وإضافتها للجدول أمام المستخدم.
  ///
  /// `respectCap` هو الفرق بين المسارين: التحميل التلقائي يتوقف عند
  /// `kGroupStatementMaxOnScreenRows` احتياطاً (لو كان عدد النطاق غير معروف
  /// مسبقاً)، أما «عرض كل الصفوف» فطلبٌ صريح من المستخدم فلا سقف له. خطأ في
  /// قسم متأخر لا يمسح الأقسام التي وصلت — الشاشة تبقى قابلة للقراءة والتصدير.
  /// `respectCap` is the whole difference between the two paths: the automatic
  /// path stops defensively at the cap, while the explicit "show all" request
  /// has no cap. A late failure never wipes the chunks already on screen.
  Future<void> _streamPages(
    AccountRepository repo,
    StatementScope scope,
    TrialBalanceReport first,
    int runId,
    CancelToken token, {
    bool respectCap = true,
  }) async {
    var acc = first;
    var page = first.page;
    try {
      while (acc.hasMore) {
        // الحدّ يُقاس بعد الإضافة، فيُسمح بالقسم الذي يعبر به لا قبله.
        // The cap stops the NEXT chunk, so an explicit request can finish.
        if (respectCap && acc.rows.length >= kGroupStatementMaxOnScreenRows) {
          break;
        }
        page += 1;
        final next = await repo.fetchGroupStatement(
          accNo: scope.accNo,
          accSub: scope.accSub,
          accPart: scope.accPart,
          groupId: scope.groupId,
          fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
          toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
          page: page,
          limit: _pageSize,
          includeTotals: false,
          cancelToken: token,
        );
        if (!mounted || runId != _runId) return;
        // قسم فارغ مع has_more=true يعني حلقة لا تنتهي — نتوقف فوراً.
        // An empty chunk that claims more pages would loop forever.
        if (next.rows.isEmpty) break;

        acc = acc.appendPage(next);
        setState(() {
          _report = acc;
          _isStreaming = acc.hasMore &&
              !(respectCap &&
                  acc.rows.length >= kGroupStatementMaxOnScreenRows);
        });
      }
    } on DioException catch (e) {
      if (!mounted || runId != _runId || CancelToken.isCancel(e)) return;
      setState(() => _isStreaming = false);
      _toast('تعذّر إكمال بقية الأقسام: ${_describeError(e)}');
    } finally {
      if (mounted && runId == _runId) {
        setState(() => _isStreaming = false);
        if (identical(_token, token)) _token = null;
      }
    }
  }

  /// «عرض كل الصفوف تدريجياً» — تجاوز صريح لحدّ العرض الآمن.
  ///
  /// الجدول صار كسولاً فلا تتأثر الذاكرة بعدد الصفوف؛ التكلفة الحقيقية هي طلب
  /// كل قسم (استعلام تجميعي كامل). لذلك لا نبدأها تلقائياً على نطاق واسع بل
  /// بقرار المستخدم.
  /// Rows are virtualized now, so memory no longer scales with the row count —
  /// only the number of chunk requests does. Hence an explicit user choice.
  Future<void> _showAll() async {
    if (_isStreaming || _report.isEmpty) return;
    final scope = resolveStatementScope(
      accNo: _accNo,
      accSub: _accSub,
      accPart: _accPart,
      groupId: _groupId,
    );
    if (scope == null) return;

    final token = CancelToken();
    _token = token;
    final runId = _runId;
    setState(() {
      _showAllRequested = true;
      _isStreaming = true;
    });
    await _streamPages(
      ref.read(accountRepositoryProvider),
      scope,
      _report,
      runId,
      token,
      // طلب صريح: بلا سقف — المستخدم اختار تحمّل بقية الأقسام.
      // Explicit request: no cap, the user accepted the extra work.
      respectCap: false,
    );
  }

  /// جلب النطاق كاملاً بلا ترقيم — يُستهلك في التصدير فقط (Excel/PDF/طباعة).
  /// Fetches the whole scope unpaginated; consumed only by the export menu.
  Future<TrialBalanceReport> _fetchFullReport() {
    final scope = resolveStatementScope(
      accNo: _accNo,
      accSub: _accSub,
      accPart: _accPart,
      groupId: _groupId,
    );
    if (scope == null) return Future.value(TrialBalanceReport.empty);

    return ref.read(accountRepositoryProvider).fetchGroupStatement(
          accNo: scope.accNo,
          accSub: scope.accSub,
          accPart: scope.accPart,
          groupId: scope.groupId,
          fromDate: _fromDate != null ? _formatDateDash(_fromDate!) : null,
          toDate: _toDate != null ? _formatDateDash(_toDate!) : null,
          // بلا `limit`: الخادم يعيد كل الصفوف (مسار التصدير الكامل).
          includeTotals: true,
        );
  }

  /// رسالة الخادم إن وجدت — «لا صلاحية» العربية أهم من «DioException [bad response]».
  /// Server message when present — the Arabic one beats a transport error string.
  String _describeError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.response?.statusCode == 404) {
      return 'الخادم الحالي لا يعرف الترقيم (404) — حدِّث الـ API وأعد تشغيله';
    }
    return e.message ?? 'خطأ في الاتصال';
  }

  void _showFailure(DioException e) {
    final message = 'خطأ في جلب التقرير: ${_describeError(e)}';
    setState(() {
      _isLoading = false;
      _isStreaming = false;
      _error = message;
    });
    _toast(message, isError: true);
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onAccNoChanged(int? value) {
    setState(() {
      _accNo = value;
      _accSub = null;
      _accPart = null;
      _groupId = null;
    });
    if (value != null) _scheduleLoad();
  }

  void _onAccSubChanged(int? value) {
    setState(() {
      _accSub = value;
      _accPart = null;
      _groupId = null;
    });
    if (value != null) _scheduleLoad();
  }

  void _onAccPartChanged(int? value) {
    setState(() {
      _accPart = value;
      _groupId = null;
    });
    if (value != null) _scheduleLoad();
  }

  void _onGroupChanged(int? value) {
    setState(() => _groupId = value);
    // إعادة التحميل دائماً حتى عند التفرير (null) — يجب أن يعود التقرير
    // لمستوى الحساب الجزئي إذا لم تُختر مجموعة
    // Always reload — even when clearing to null, the report must fall back
    // to the accPart-level scope when no group is selected.
    _scheduleLoad();
  }

  /// يطبّق الاختيار الافتراضي مرة واحدة عند تحميل القوائم: أول حساب رئيسي، ثم
  /// أول حساب فرعي تابعه، ثم أول حساب جزئي تابعه، وبعدها يُجلب التقرير لمستوى
  /// الجزئي مباشرة.
  /// Applies the one-shot default selection: first main account → first sub
  /// account under it → first partial account under that, then loads the report
  /// at the partial scope.
  void _maybeApplyDefaults(
    AsyncValue<List<AccountModel>> accountsAsync,
    AsyncValue<List<AccMainModel>>? accMainAsync,
    AsyncValue<List<AccSubModel>>? accSubAsync,
  ) {
    // المرحلة 1: اختيار أول حساب رئيسي دون جلب بعد (ننتظر الفرعي ثم الجزئي).
    // Stage 1: pick the first main without loading yet — we wait for sub, then part.
    if (!_autoSelectedAccNo) {
      final list = accountsAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccNo = true;
      if (list.isNotEmpty && _accNo == null) {
        final firstAccNo = list.first.accNo;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _accNo = firstAccNo);
        });
      }
      return;
    }

    // المرحلة 2: اختيار أول حساب فرعي (بدون جلب — ننتظر الجزئي).
    // Stage 2: pick the first sub without loading yet — we wait for the part.
    if (!_autoSelectedAccSub && _accNo != null && accMainAsync != null) {
      final list = accMainAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccSub = true;
      // الأول حرفياً: `[1]` كان يقفز فوق أول عنصر وينهار RangeError عندما يكون
      // الحساب الفرعي الوحيد — قائمة من عنصر واحد حالة طبيعية في قاعدة البيانات.
      // Take the first entry literally: `[1]` skipped it and threw a RangeError
      // whenever there was only one sub account, which is common.
      final firstSub = list.isNotEmpty ? list.first.accSub : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _accSub = firstSub);
        // إن لم توجد حسابات فرعية، لا يوجد مستوى جزئي نُجلب له — نجدول فوراً.
        // No sub accounts exist, so there is no part to wait for — schedule now.
        if (firstSub == null) _scheduleLoad();
      });
      return;
    }

    // المرحلة 3: اختيار أول حساب جزئي ثم جدولة الجلب.
    // Stage 3: pick the first partial account then schedule the fetch.
    if (!_autoSelectedAccPart && _accSub != null && accSubAsync != null) {
      final list = accSubAsync.asData?.value;
      if (list == null) return; // ما يزال يُحمَّل / still loading
      _autoSelectedAccPart = true;
      final firstPart = list.isNotEmpty ? list.first.accPart : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _accPart = firstPart);
        _scheduleLoad();
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    // نقصّ initialDate داخل نطاق الـ picker احتياطاً — الـ assertion الخاص
    // بـ Material ينهار إذا تجاوز التاريخ المبدئي firstDate/lastDate.
    // Clamp the initial date into the picker's legal range as a hard guard:
    // Material asserts initialDate ∈ [firstDate, lastDate].
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);
    final initial = clampToDatePickerRange(
      (isFrom ? _fromDate : _toDate) ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _scheduleLoad();
    }
  }

  /// الطباعة والتصدير في قائمة واحدة مشتركة مع الشجرة (`GroupStatementExportMenu`)؛
  /// ترويسة التقرير وقراءة البايْتات تُداران داخل القائمة نفسها لحظة الضغط.
  /// Print/PDF/Excel live in the menu shared with the tree, which reads `_report`
  /// at tap time — no duplicated byte-generation code here.

  @override
  Widget build(BuildContext context) {
    // أي صف على الشاشة يكفي لإظهار التصدير: المستند يُبنى عند الضغط من النطاق
    // الكامل الذي يطلبه `_fetchFullReport` من الخادم، لا من الصفوف المعروضة.
    // Any row on screen is enough to offer export: the document is built from the
    // full scope fetched on tap, never from the rows currently displayed.
    final canExport = !_report.isEmpty && _error == null;

    // تراقب الهوية كما تُعدَّل من شاشة التهيئة فتنعكس على الترويسة فوراً
    // Watches the configured identity so a branding edit repaints the letterhead at once.
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider.select((s) => s.config)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'كشف حساب مجموعة حسابات جزئية',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
                _filtersVisible ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 20),
            tooltip: _filtersVisible ? 'إخفاء الفلترة' : 'إظهار الفلترة',
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
          ),
          if (canExport) ...[
            GroupStatementExportMenu(
              report: () => _report,
              fetchFull: _fetchFullReport,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'تحديث',
            onPressed: _loadReport,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filtersVisible) _buildFilterBar(),
          // شريط تقدّم التحميل التدريجي — يظهر فقط أثناء عمل فعلي بالشبكة.
          // Progressive progress bar, only while the network is genuinely busy.
          if (_isLoading || _isStreaming) _buildProgressStrip(),
          if (_isTooWide) _buildTooWideCard(),
          Expanded(child: _buildBody(letterhead)),
        ],
      ),
    );
  }

  /// شريط تقدّم: قيمة معلومة أثناء إضافة الأقسام (`loaded/total`)، ودائرة
  /// غير محددة قبل أن يعرف الخادم عدد الصفوف.
  /// Determinate while chunks stream in, indeterminate until the total is known.
  Widget _buildProgressStrip() {
    final streaming = _isStreaming;
    final loaded = _report.rows.length;
    final total = _report.total;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: streaming && total > 0 ? _report.loadRatio : null,
              minHeight: 5,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            streaming && total > 0
                ? 'جارٍ عرض الأقسام تدريجياً — $loaded من $total حساب'
                : 'جارٍ جلب التقرير…',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  /// بطاقة «النطاق واسع جدًا» — تظهر بدل التنزيل التلقائي لنطاق يتجاوز الحدّ،
  /// ومعها المسارات الثلاثة المتاحة: تضييق النطاق، تصدير كامل من الخادم، أو
  /// عرض كل الصفوف تدريجياً بقرار صريح.
  /// The "scope too wide" banner replaces the automatic download and offers the
  /// three real options: narrow the scope, full server export, or stream all.
  Widget _buildTooWideCard() {
    final total = _report.total;
    final showing = _report.rows.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'النطاق واسع جدًا، اختر مجموعة أدق',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'هذا النطاق يضم $total حساب — عُرض منها $showing فقط لتفادي إثقال الجهاز. '
            'اختر مجموعة أو حسابًا جزئيًا لعرضه كاملاً على الشاشة، أو صدّر التقرير '
            'كاملاً من الخادم.',
            style: const TextStyle(
                fontSize: 11.5, color: Color(0xFF92400E), height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // التصدير الكامل: نفس قائمة الطباعة/PDF/Excel لكن بجلب النطاق كله
              // أولاً، فهي الزر المطلوب في هذه الحالة.
              GroupStatementExportMenu(
                report: () => _report,
                fetchFull: _fetchFullReport,
                buttonLabel: 'تصدير كامل من الخادم',
              ),
              OutlinedButton.icon(
                onPressed: _isStreaming ? null : _showAll,
                icon: const Icon(Icons.unfold_more_rounded, size: 17),
                label: Text(
                  _isStreaming ? 'جارٍ عرض الأقسام…' : 'عرض كل الصفوف تدريجياً',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCascadeDropdownRow(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: _fromDate != null ? _formatDateSlash(_fromDate!) : 'من تاريخ',
                  hasValue: _fromDate != null,
                  icon: Icons.calendar_today,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateButton(
                  label: _toDate != null ? _formatDateSlash(_toDate!) : 'إلى تاريخ',
                  hasValue: _toDate != null,
                  icon: Icons.event_outlined,
                  onTap: () => _pickDate(isFrom: false),
                ),
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    _scheduleLoad();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.clear_rounded,
                        color: AppColors.error, size: 16),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            // توضيح دلالة العمودين: مدين/دائن ورصيد الفترة للفترة المختارة،
            // والرصيد عمود ثابت يعرض الرصيد النهائي للحساب في كل الحالات.
            // DR/CR and the period balance follow the filter; «الرصيد» is always the
            // account's final balance.
            'اترك الفترة فارغة لعرض كل الحركات عبر كامل السجل التاريخي. '
            'عند تحديد فترة يُضاف عمود «رصيد الفترة»، ويبقى عمود «الرصيد» للرصيد النهائي للحساب',
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCascadeDropdownRow() {
    final accountsAsync = ref.watch(parentAccountsProvider);
    final accMainAsync =
        _accNo != null ? ref.watch(parentAccMainProvider(_accNo)) : null;
    final accSubAsync = _accSub != null ? ref.watch(parentAccSubProvider(_accSub)) : null;
    final accGroupAsync =
        _accPart != null ? ref.watch(parentAccSubGroupProvider(_accPart)) : null;

    // اختيار افتراضي لأول حساب رئيسي ثم أول فرعي ثم أول جزئي عند التحميل الأولي
    // Default-select the first main, then the first sub, then the first part on load.
    _maybeApplyDefaults(accountsAsync, accMainAsync, accSubAsync);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _cascadeDropdown<AccountModel>(
          label: 'حساب رئيسي',
          items: accountsAsync.asData?.value ?? const [],
          selectedId: _accNo,
          idOf: (e) => e.accNo,
          labelOf: (e) => '${e.accNo} - ${ArabicEncodingUtils.fix(e.accName)}',
          isLoading: accountsAsync.isLoading,
          onChanged: _onAccNoChanged,
        ),
        if (accMainAsync != null)
          _cascadeDropdown<AccMainModel>(
            label: 'حساب فرعي',
            items: accMainAsync.asData?.value ?? const [],
            selectedId: _accSub,
            idOf: (e) => e.accSub,
            labelOf: (e) => ArabicEncodingUtils.fix(e.subName),
            isLoading: accMainAsync.isLoading,
            onChanged: _onAccSubChanged,
          ),
        if (accSubAsync != null)
          _cascadeDropdown<AccSubModel>(
            label: 'حساب جزئي',
            items: accSubAsync.asData?.value ?? const [],
            selectedId: _accPart,
            idOf: (e) => e.accPart,
            labelOf: (e) => ArabicEncodingUtils.fix(e.partName),
            isLoading: accSubAsync.isLoading,
            onChanged: _onAccPartChanged,
          ),
        if (accGroupAsync != null)
          _cascadeDropdown<AccSubGroupModel>(
            label: 'مجموعات الحساب الجزئي (اختياري)',
            items: accGroupAsync.asData?.value ?? const [],
            selectedId: _groupId,
            idOf: (e) => e.groupId,
            labelOf: (e) => ArabicEncodingUtils.fix(e.accGroupName),
            isLoading: accGroupAsync.isLoading,
            onChanged: _onGroupChanged,
            allowClear: true,
          ),
      ],
    );
  }

  Widget _cascadeDropdown<T>({
    required String label,
    required List<T> items,
    required int? selectedId,
    required int Function(T) idOf,
    required String Function(T) labelOf,
    required bool isLoading,
    required ValueChanged<int?> onChanged,
    bool allowClear = false,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      child: isLoading
          ? const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : DropdownButtonFormField<int>(
              value: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: label,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              items: [
                if (allowClear)
                  const DropdownMenuItem<int>(
                      value: null, child: Text('— بدون اختيار —')),
                ...items.map(
                  (item) => DropdownMenuItem<int>(
                    value: idOf(item),
                    child: Text(
                      labelOf(item),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ],
              onChanged: onChanged,
            ),
    );
  }

  Widget _buildBody(ReportLetterheadInfo letterhead) {
    if (_accNo == null) {
      return _buildEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'لم يُختر نطاق بعد',
        subtitle: 'اختر حساباً رئيسياً على الأقل لعرض ميزان المراجعة',
      );
    }
    // داخل مهلة الاختيار: لا طلب بعد. نقولها صريحة بدل مؤشر تحميل كاذب.
    // Inside the quiet period: no request yet — say so instead of faking a load.
    if (_pending) {
      return _buildEmptyState(
        icon: Icons.timer_outlined,
        title: 'بانتظار اكتمال اختيارك',
        subtitle: 'يُجلب التقرير تلقائياً بعد '
            '${widget.fetchDelay.inSeconds} ثوانٍ من آخر تغيير في الاختيار. '
            'اضغط «تحديث» للجلب الآن.',
      );
    }
    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        title: 'تعذّر جلب التقرير',
        subtitle: _error!,
      );
    }
    if (_report.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'لا توجد حسابات في هذا النطاق',
        subtitle: 'النطاق المحدد لا يحتوي أي حسابات مالية مسجلة',
      );
    }

    return _buildReportSheet(letterhead);
  }

  /// الورقة كما تُطبع: ترويسة + عنوان + سطر الفترة، ثم منطقة جداول قابلة للتمرير،
  /// ثم التذييل — كلها داخل ورقة A4 واحدة قابلة للتكبير.
  ///
  /// ارتفاع منطقة الجداول محسوب من المساحة المتاحة (لا من عدد الصفوف): الجدول
  /// كسول ويحتاج ارتفاعاً معروفاً، والورقة تحتاج تذييلاً يقع بعد المحتوى. الطرح
  /// هنا هو «كلفة» الترويسة والعنوان والتذييل داخل الورقة.
  /// The report sheet as printed: letterhead, title and period line, then a
  /// scrollable table area, then the footer. The table gets an explicit height
  /// computed from the available space — a lazy list needs a bounded box, and
  /// the sheet needs a footer that still lands after the content.
  Widget _buildReportSheet(ReportLetterheadInfo letterhead) {
    return ReportZoomView(
      // تمرير طبيعي للصفحة كاملة مع تذييل في نهاية المحتوى (لا A4 على الشاشة)
      // Natural full-page scroll with the footer at content end (no on-screen A4).
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableHeight =
              (constraints.maxHeight - _sheetChromeHeight).clamp(240.0, 760.0);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ReportA4Sheet(
              orientation: ReportSheetOrientation.landscape,
              maxPageWidth: 1100,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLetterheadBand(letterhead),
                  // الجدول داخل صندوق بارتفاع محدود: ترويسة مثبّتة + صفوف كسولة
                  // + سطر إجمالي مثبّت، ولا يُبنى صفّ إلا عند ظهوره.
                  // Bounded box: pinned header + lazy rows + pinned totals, and a
                  // row is only built when it becomes visible.
                  SizedBox(
                    height: tableHeight.toDouble(),
                    child: AccountGroupStatementReportTable(report: _report),
                  ),
                ],
              ),
              footer: const ReportSignatureFooter(),
            ),
          );
        },
      ),
    );
  }

  /// كتلة الترويسة على الشاشة: الشعار والكتلتان من إعدادات التطبيق، ثم عنوان
  /// التقرير واسم النطاق وسطر الفترة والتاريخ.
  /// On-screen letterhead: branding from app config, then the title, scope name
  /// and period/date line.
  Widget _buildLetterheadBand(ReportLetterheadInfo letterhead) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF4B5563), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الترويسة ثلاثية الأعمدة: الكتلة العربية + الشعار + الكتلة
          // الإنجليزية، من إعدادات التطبيق — نفس الكائن الذي يذهب إلى PDF
          // Three-column band (Arabic / logo / English) from app config —
          // the same object handed to the PDF.
          ReportLetterheadBranding(info: letterhead),
          const SizedBox(height: 6),
          const Text(
            'كشف حساب مجموعة حسابات جزئية',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(
            'مجموعة حسابات: ${ArabicEncodingUtils.fix(_report.scopeLabel)}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  // نص الفترة الموحّد (يحتمل تاريخاً واحداً فقط)
                  // Shared period label, one-sided dates included.
                  _report.periodLabel,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black87),
                ),
              ),
              Text(
                'بتاريخ: ${_report.asOfDate}',
                style: const TextStyle(
                    fontSize: 10.5, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required bool hasValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              hasValue ? AppColors.primary.withValues(alpha: 0.06) : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                hasValue ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 14, color: hasValue ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: hasValue ? AppColors.primary : AppColors.textMuted,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
