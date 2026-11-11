import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_a4_sheet.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../../../core/widgets/report_signature_footer.dart';
import '../../../../core/widgets/report_zoom_view.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';
import '../providers/reports_providers.dart';
import '../providers/stores_providers.dart';
import '../utils/report_columns.dart';
import '../utils/report_parameters.dart';
import '../utils/report_templates.dart';
import '../utils/report_totals.dart';
import '../utils/store_export.dart';
import '../widgets/report_columns_sheet.dart';
import '../widgets/report_data_table.dart';
import '../widgets/report_filter_sheet.dart';
import '../widgets/report_stats_band.dart';
import '../widgets/store_ui.dart';

/// تقارير المخازن — عرض حركة أو خلاصة بمعطيات تُختار في نافذة منبثقة
/// The stores reports — a movement view or a summary whose parameters are chosen in a sheet.
///
/// ── النافذة تُفتح تلقائياً عند الدخول: التقرير بلا مدى زمني وبلا مخزن يمسح الـ VIEW كاملة
///    ويُنتج آلاف السطور التي لا يقرأها أحد. الفتح التلقائي يجعل التحديد خطوة لا خياراً.
/// ── The sheet opens automatically on entry: an unbounded, store-less report scans the whole
///    view and returns thousands of rows nobody reads. Auto-opening makes selection a step.
///
/// ── `initialFilter` هو طريق «كشف حركة» من شاشات الأصناف: النقر على كشف حركة صنف يفتح
///    قالب التقرير نفسه بمعطياته الجاهزة مباشرة — قالب واحد يُعرض ويُطبع ويُصدَّر
///    من باب واحد، لا نسختين بموازين مختلفة تختلان مع الوقت.
/// ── `initialFilter` is how the items screens' "movement statement" arrives: tapping it opens
///    the very report template with its parameters and runs at once — one template rendered,
///    printed and exported from one door, not two diverging copies.
class StoreReportsScreen extends ConsumerStatefulWidget {
  const StoreReportsScreen({super.key, this.initialFilter});

  /// معطيات جاهزة تُنفَّذ فور فتح الشاشة — تستخدمها شاشات الأصناف لكشف الحركة
  /// Parameters to run immediately on open — used by the items screens for statements.
  final StoreReportFilter? initialFilter;

  @override
  ConsumerState<StoreReportsScreen> createState() => _StoreReportsScreenState();
}

class _StoreReportsScreenState extends ConsumerState<StoreReportsScreen> {
  bool _busy = false;

  /// ترتيب الأعمدة الظاهرة لكل نوع — `null` حتى يغيّره المستخدم فتُطبَّق أساسيات القالب
  /// The visible order per kind — null until the user changes it, then the template's basics.
  List<String>? _movementOrder;
  List<String>? _summaryOrder;

  /// حقول الإحصاءات الظاهرة — تبدأ بالخمسة الافتراضية (السابق · وارد · منصرف · الصافي ·
  /// الرصيد الحالي)، وما عداها يبقى متاحاً في «تخصيص» حتى يُظهره المستخدم.
  /// The visible statistic fields — they start on the five defaults (opening · in · out ·
  /// net · closing), and everything else stays available under "customise" until enabled.
  ///
  /// ── لماذا ليست `null` كما كانت؟ لأن `null` كانت تعني «كل الحقول»، فكان شريط التقرير
  ///    يُفتح على تسعة أرقام لا تُقرأ في نظرة. القائمة الافتراضية تُبقي القرار للمستخدم
  ///    لكنها لا تُغرق الشاشة قبل أن يقرّر.
  /// ── Why not `null` as before? `null` meant "every field", so the strip opened on nine
  ///    figures that cannot be read at a glance. The default list leaves the decision to the
  ///    user without flooding the screen before they make it.
  List<String>? _statIds = ReportStatFields.defaultIds;

  /// إعادة الأساسيات المحلية — ترتيب الأعمدة وحقول الإحصاءات
  /// Restore the local view choices to the template's basics.
  ///
  /// الشاشة تُدفع فتُبنى حالة جديدة في كل فتح، وهذه الحقول تعود أساسياتها عند
  /// الإنشاء أصلاً؛ التصفير الصريح هنا يخدم مساراً آخر: لو بقيت الشاشة مراكمةً
  /// فوق قسم أُعيد تصفير مزوده، فلا يبقى عرضٌ اختاره المستخدم من جلسة سبقة.
  /// The screen is pushed, so a fresh state already carries the defaults; wiping them
  /// explicitly here covers the other path — a report left open above a section whose
  /// provider was just reset must not keep a previous visit's column choices.
  void _resetLocalViewChoices() {
    _movementOrder = null;
    _summaryOrder = null;
    _statIds = ReportStatFields.defaultIds;
  }

  @override
  void initState() {
    super.initState();

    // ── تفريغ حالة المزود قبل أي شيء: هذه الشاشة تُدفع في المراكر من لوحة
    //    المخازن ومن شاشات الأصناف، لكنها تشارك نفس `storeReportProvider`
    //    غير المُصفَّى. بلا هذا التفريغ، يظهر آخر تقرير شغّله المستخدم في أول
    //    إطار من الدخول — وهو جذر شكوى المعطيات العالقة في كل واجهة التقارير.
    // ── Wipe the provider before anything else. This screen is pushed on top of
    //    both the stores dashboard and the item screens, yet shares one
    //    non-autoDispose `storeReportProvider`; without this, the last report the
    //    user ran flashes up on the very first frame of every new visit.
    //
    // التصفير مؤجَّل إلى ما بعد الإطار: تعديل مزود أثناء بناء الشجرة يُطلق
    // شرط Riverpod «modify a provider while the widget tree is building».
    // The wipe waits for the frame: mutating a provider mid-build trips Riverpod's
    // debug assertion, which fired on every single open in debug mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(storeReportProvider.notifier);
      _resetLocalViewChoices();
      notifier.resetTransient();

      // ── معطيات جاهزة: يُنفَّذ التقرير مباشرة بلا نافذة انتظار — جاء المستخدم من
      //    «كشف حركة صنف» وقد حدد سؤاله بالفعل، وإعادة سؤاله إهانة للسياق.
      //    بلا معطيات: الفتح التلقائي للنافذة كما كان، والزر يفتحها دائماً بعدها.
      // ── With preset parameters the report runs at once: the user arrived from an item's
      //    "movement statement" having already asked the question — asking it again insults
      //    the context. Without them, the auto-open sheet behaves exactly as before.
      if (widget.initialFilter != null) {
        notifier.run(widget.initialFilter!);

        return;
      }

      _openFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeReportProvider);
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesReportsPrint);
    final canExport = auth.can(Perm.storesReportsExport);
    final hasRows = state.movementRows.isNotEmpty || state.summaryRows.isNotEmpty;

    // ── الكشف القادم بمعطيات جاهزة يعرض نفسه باسمه: «كشف حركة صنف رئيسي» لا
    //    «تقارير المخازن» العام — العنوان الذي يفتح عليه المستخدم هو ما يتوقع قراءته.
    // ── A preset statement names itself in the app bar: "main item movement statement", not
    //    the generic "Stores reports" — the title the user tapped is the title they expect.
    final presetScope = widget.initialFilter?.scope;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          presetScope == StoreReportScope.item
              ? 'كشف حركة صنف رئيسي'
              : presetScope == StoreReportScope.branch
                  ? 'كشف حركة صنف فرعي'
                  : 'تقارير المخازن',
        ),
        actions: [
          IconButton(
            tooltip: 'معطيات التقرير',
            onPressed: _openFilter,
            icon: const Icon(Icons.tune_rounded),
          ),
          // الأعمدة أداة لا زينة: نفس القالب يعرض الحركة بتسعة أعمدة أو بثمانية عشر
          // Columns are a tool, not a decoration: the same template serves nine or eighteen.
          IconButton(
            tooltip: 'أعمدة العرض',
            onPressed: hasRows || state.filter != null ? _openColumns : null,
            icon: const Icon(Icons.view_column_rounded),
          ),
          if (canPrint)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _busy || !hasRows ? null : () => _export(print: true),
              icon: const Icon(Icons.print_outlined),
            ),
          if (canExport)
            PopupMenuButton<String>(
              tooltip: 'تصدير',
              enabled: hasRows && !_busy,
              onSelected: (value) async {
                if (value == 'pdf') await _export();
                if (value == 'xlsx') await _exportXlsx();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('مشاركة PDF')),
                PopupMenuItem(value: 'xlsx', child: Text('مشاركة Excel')),
              ],
            ),
        ],
      ),
      body: _body(state),
    );
  }

  // ─────────────────────────── متن الشاشة ───────────────────────────
  Widget _body(StoreReportState state) {
    final notifier = ref.read(storeReportProvider.notifier);

    if (state.filter == null) {
      return StoreEmptyState(
        icon: Icons.tune_rounded,
        title: 'حدّد معطيات التقرير',
        description:
            'نوع التقرير والفترة والمخازن والمجموعات والفئات والأصناف والأصناف الفرعية '
            'وأنواع الحركة — وكلها تحتمل «لاشي».',
        actionLabel: 'معطيات التقرير',
        onAction: _openFilter,
      );
    }

    if (state.isLoading) {
      return const StoreLoading(message: 'جارٍ تجهيز التقرير...');
    }

    if (state.error != null) {
      return StoreErrorState(
        message: state.error!,
        onRetry: () => notifier.run(state.filter!),
      );
    }

    if (state.isEmpty) {
      // رسالة صادقة: لا نتائج مطابقة مع ذكر ما ضيّق التقرير فعلاً
      // An honest empty state: no matching rows, naming whatever actually narrowed the report.
      return StoreEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا نتائج مطابقة',
        description: ReportTitles.of(
          state.filter!,
          reference: ref.read(storeReferenceProvider).value,
        ).singleLine,
        actionLabel: 'تعديل المعطيات',
        onAction: _openFilter,
      );
    }

    return _sheet(state);
  }

  /// القالب الرسمي بخمسة مكوّنات لا غير: ترويسة · عنوان · جدول · ملخص · تذييل
  /// The official template with exactly five parts: letterhead · title · table · summary · footer.
  ///
  /// ── لا شريط وسوم فوق الترويسة ولا جدول معطيات قبل الجدول: كلاهما كان يزيح المتن
  ///    ويحوّل المستند إلى نموذج إدخال، والمعلومة التي كان يحملها صارت في العنوان نفسه.
  /// ── No chip bar above the letterhead and no parameter table before the grid: both pushed
  ///    the body down and turned the document back into an input form, and the one fact they
  ///    carried now lives in the title itself.
  Widget _sheet(StoreReportState state) {
    final filter = state.filter!;
    final reference = ref.watch(storeReferenceProvider).value;
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.watch(appConfigNotifierProvider).config,
    );

    final isMovement = filter.kind == StoreReportKind.movement;
    final template = ReportTemplates.of(filter);

    // نوعان حقيقيان لا نوع محاك واحد: قارئ العمود دالة تستقبل صفها بعينه، وإمحاؤه
    // بـ`Object` يرمي `is not a subtype` عند أول خلية تُرسم
    // Two real types, never one erased type: a column's reader takes its own row, and erasing
    // it to Object throws "is not a subtype" on the first cell drawn.
    final movementColumns = ReportColumns.ordered(
      ReportColumns.movement(),
      _orderFor(template, isMovement: true),
    );

    final summaryColumns = ReportColumns.ordered(
      ReportColumns.summary(filter.groupBy),
      _orderFor(template, isMovement: false),
    );

    final body = <Widget>[];

    // ── التقارير الموسّعة تُعرض أقساماً متتابعة: فرع بعد فرع، وصنف بعد صنف — لأن المراجع
    //    الذي يرى كل الفروع في جدول واحد لا يرى رصيد أي فرع منها على حدة.
    // ── Scoped reports render as successive sections, branch after branch and item after
    //    item: a reviewer looking at every branch in one table sees no branch's balance.
    //
    // ── الشرط هو `sectioned` وحده: انتظار أكثر من قسم كان يُسقط التقرير إلى جدول واحد مسطّح
    //    في أي نطاق أعطى قسماً واحداً، فيبدو «حركة صنف رئيسي» مطابقاً لـ«حركة صنف فرعي» —
    //    وهو الخلط الذي تُبنى هذه التقارير الأربعة لتمييزه.
    // ── The condition is `sectioned` alone: waiting for more than one section dropped the
    //    report back to a single flat table whenever a scope yielded one section, making an
    //    item statement look exactly like a branch statement — the very confusion these four
    //    reports exist to remove.
    if (isMovement && template.sectioned) {
      for (final block in _movementBlocks(template, state, movementColumns)) {
        body.add(block);
      }
    } else if (isMovement) {
      body.add(
        ReportDataTable<StockMovementRow>(
          columns: movementColumns,
          rows: state.movementRows,
          // رصيد الفترة السابقة أول الجدول ثم تتراكم الحركات عليه
          // The pre-period balance opens the table, and the movements accumulate on it.
          opening: _statIds == null || _statIds!.contains('opening')
              ? ReportTotals.opening(state.stats)
              : null,
          // سطر التجميع في نهاية الجدول للكميات والقيم، وما لا مجموع له يبقى فارغاً
          // The totals row at the table's end for quantities and values; the rest stays blank.
          totals: ReportTotals.movement(state.movementRows),
        ),
      );
    } else {
      body.add(
        ReportDataTable<StockSummaryRow>(
          columns: summaryColumns,
          rows: state.summaryRows,
          totals: ReportTotals.summary(state.summaryRows),
        ),
      );
    }

    // إحصاءات نهاية التقرير — totals الخادم لا مجموع ما على الشاشة، والحقول كما اختارها المستخدم
    // The closing statistics are the server's totals, never a sum of what is on screen, and
    // only the fields the user kept.
    body.add(
      ReportStatsBand(
        // في التقرير الموسّع هذا الإحصاء مجموع **كل** الأقسام لا آخرها: «إجمالي كل الأصناف
        // الفرعية» في حركة الصنف الرئيسي، وهكذا لكل نطاق بعنوانه
        // In a sectioned report this band sums EVERY section, not the last one — "the total of
        // all sub items" in an item statement, and so on, each scope under its own caption.
        title: isMovement && template.sectioned
            ? 'إحصاءات التقرير — إجمالي كل ${filter.scope.sectionPlural}'
            : 'إحصاءات التقرير',
        fields: ReportStatFields.visible(
          ReportStatFields.of(state.stats),
          _statIds,
        ),
      ),
    );

    return ReportZoomView(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ReportA4Sheet(
          orientation: ReportSheetOrientation.landscape,
          maxPageWidth: 1240,
          // 1) الترويسة الرسمية
          header: ReportLetterheadBranding(info: letterhead),
          // 2) عنوان التقرير ثم الفترة والمخازن عند التخصيص فقط
          title: _title(state, filter, reference),
          // 3) الجدول و 4) ملخصه — مكوّنان متتابعان داخل المتن
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...body,
              if (state.truncated) ...[
                const SizedBox(height: 6),
                Text(
                  'تنبيه: النتائج مقتطعة عند حدّ السطور — ضيّق الفترة أو المخازن.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          // 5) التذييل الرسمي — مخازن: أمين المخزن لا أمين الصندوق
          // 5) the official footer — stores: the storekeeper's slot, not the cashier's.
          footer: const ReportSignatureFooter(
            keeper: ReportSignatureFooter.storekeeper,
          ),
        ),
      ),
    );
  }

  /// أقسام الحركة: عنوان القسم ثم جدوله ثم إحصاء ذلك القسم وحده
  /// A movement section: its heading, its table, and that section's own statistics.
  ///
  /// ── الإحصاء يُقرن بالقسم بمفتاحه لا بموضعه: قسم بلا حركة في المدى لا يصل أصلاً، ومقارنته
  ///    بالموضع تُزيح إحصاء كل قسم يليه فيُقرأ رصيد فرع تحت اسم فرع آخر.
  /// ── Statistics are joined to their section by key, never by position: a section with no
  ///    movement arrives nowhere at all, and positional matching shifts every later section's
  ///    figures — one branch's balance printed under another branch's name.
  List<Widget> _movementBlocks(
    ReportTemplate template,
    StoreReportState state,
    List<ReportColumn<StockMovementRow>> columns,
  ) {
    final openingOn = _statIds == null || _statIds!.contains('opening');

    return [
      for (final section in _sectionsOf(state)) ...[
        _sectionHeading(section, state),
        ReportDataTable<StockMovementRow>(
          columns: columns,
          rows: section.rows,
          // افتتاح القسم قبل أول حركة فيه: به يبدأ عمود الرصيد داخل هذا القسم
          // The section's opening before its first movement: the balance column of this
          // section starts here.
          opening: openingOn ? ReportTotals.opening(section.stats) : null,
          // تجميع القسم من سطوره هو: مجموع فرع لا يخبر عن فرع آخر
          // A section's totals come from its own rows: one branch's sum says nothing of another.
          totals: ReportTotals.movement(section.rows),
        ),
        const SizedBox(height: 4),
        ReportStatsBand.compact(
          // العنوان باسم وحدة القسم في هذا النطاق: «إحصاءات الصنف الفرعي» داخل حركة صنف
          // رئيسي، و«إحصاءات المجموعة الفرعية» داخل حركة مجموعة رئيسية
          // The caption names this scope's section unit: "sub-item statistics" inside an item
          // statement, "sub-group statistics" inside a main-group one.
          title:'',// 'إحصاءات ${state.filter!.scope.sectionLabel}',
          // أربعة أرقام فقط في سطر واحد: السابق · وارد · منصرف · الرصيد الحالي. إحصاء القسم
          // لا يُعاد فيه كل ما في إحصاء التقرير، وإلا صار لكل فرع تقريراً كاملاً في سطرين.
          // Four figures on one line only: opening · in · out · closing. A section does not
          // repeat the whole report summary, or every branch becomes a report of its own.
          fields: ReportStatFields.visible(
            ReportStatFields.section(section.stats),
            _statIds,
          ),
        ),
        const SizedBox(height: 14),
      ],
    ];
  }

  /// تقسيم سطور التقرير إلى أقسامه — الشاشة والـ PDF والـ Excel تقرأ التقسيم نفسه
  /// Split the report's rows into its sections — screen, PDF and Excel read one split.
  ///
  /// ── الترتيب من الخادم لا من الشاشة: السطور مرتّبة بقسمها ثم بتاريخها أصلاً
  /// ── The order comes from the server: rows already arrive section-major, then by date.
  List<ReportSection<StockMovementRow>> _sectionsOf(StoreReportState state) {
    final order = <String>[];
    final buckets = <String, List<StockMovementRow>>{};

    for (final row in state.movementRows) {
      final key = row.sectionKey.isEmpty ? '__all__' : row.sectionKey;

      if (!buckets.containsKey(key)) {
        order.add(key);
        buckets[key] = <StockMovementRow>[];
      }

      buckets[key]!.add(row);
    }

    return [
      for (final key in order)
        ReportSection<StockMovementRow>(
          key: key,
          label: _labelOf(key, state, buckets[key]!),
          rows: buckets[key]!,
          stats: _statsOf(key, state) ?? const ReportStats(),
        ),
    ];
  }

  /// إحصاء قسم بمفتاحه من بيانات الخادم
  /// A section's statistics by its key, straight from the server's meta.
  ReportStats? _statsOf(String key, StoreReportState state) {
    for (final section in state.sections) {
      if (section.key == key) return section.stats;
    }

    // قسم بلا إحصاء في الرد (مفتاح غائب) لا يورث إحصاء جاره
    // A section with no statistics in the reply inherits nothing from its neighbour.
    return null;
  }

  Widget _sectionHeading(
    ReportSection<StockMovementRow> section,
    StoreReportState state,
  ) {
    final scope = state.filter!.scope;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // العنوان يُسمّى بما هو: «الصنف الفرعي: قماش شاهر» أو «المجموعة الفرعية: الأقمشة»
              // The heading names what it is: "sub item: Shaher cloth" or "sub group: fabrics".
              '${scope.sectionLabel}: ${section.label}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            '${section.rows.length} حركة',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// عنوان قسم: من السطور أولاً، ومن بيانات الخادم احتياطاً، ثم مفتاحه
  /// A section's label: from its rows first, from the server's meta as a fallback, then its key.
  String _labelOf(
    String key,
    StoreReportState state,
    List<StockMovementRow> rows,
  ) {
    final fromRow = rows.isEmpty ? '' : rows.first.sectionLabel.trim();

    if (fromRow.isNotEmpty) return fromRow;

    for (final section in state.sections) {
      if (section.key == key && section.label.trim().isNotEmpty) {
        return section.label.trim();
      }
    }

    return key;
  }

  Widget _title(
    StoreReportState state,
    StoreReportFilter filter,
    StoreReference? reference,
  ) {
    final title = ReportTitles.of(filter, reference: reference);

    return Column(
      children: [
        Text(
          title.headline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        // الفترة لا تُذكر إلا إذا خصّصها المستخدم: المدى الافتراضي جزء من معنى التقرير
        // The range appears only when customised: the default window is part of the meaning.
        if (title.period != null) ...[
          const SizedBox(height: 3),
          Text(
            title.period!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (title.stores != null) ...[
          const SizedBox(height: 2),
          Text(
            title.stores!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  /// ترتيب الأعمدة الظاهرة: اختيار المستخدم إن وُجد، وإلا أساسيات القالب
  /// The visible column order: the user's own if set, otherwise the template's basics.
  ///
  /// ── «الأساسي» نقطة بداية لا قفل: التقرير يفتح على الأعمدة السبعة التي يقرأها الميدان،
  ///    ثم يبقى للمستخدم أن يخفي منها ما لا يخصّه ويقدّم ما يهمّه.
  /// ── "Basic" is a starting point, not a lock: the report opens on the seven columns the
  ///    floor reads, and the user may hide what does not apply and bring forward what does.
  List<String> _orderFor(ReportTemplate template, {required bool isMovement}) {
    return (isMovement ? _movementOrder : _summaryOrder) ?? template.defaultIds;
  }

  /// الأقسام التي يراها المُصدِّر — فارغة في التقرير المسطّح أو الخلاصة
  /// The sections an exporter sees — empty for a flat statement or a summary.
  ///
  /// ── `sectioned` وحده يحكم: التقرير المسطّح يُصدَّر جدولاً واحداً بسطر افتتاحه، والموسّع
  ///    يُصدَّر أقساماً — وهو الفرق بعينه بين «حركة صنف فرعي» و«حركة صنف رئيسي».
  /// ── `sectioned` alone decides: a flat statement exports as one table with its opening line,
  ///    a scoped one as sections — exactly the difference between the two movement reports.
  List<ReportSection<StockMovementRow>> _sectionsFor(StoreReportState state) {
    final filter = state.filter;

    if (filter == null ||
        filter.kind != StoreReportKind.movement ||
        !filter.scope.sectioned) {
      return const [];
    }

    return _sectionsOf(state);
  }

  /// معرّفات الأعمدة الظاهرة — تُمرَّرة للتصدير فيطابق المطبوع ما على الشاشة
  /// The visible column ids, passed to the exporters so the print matches the screen.
  List<String> _columnIds(StoreReportFilter filter) {
    final template = ReportTemplates.of(filter);

    final columns = filter.kind == StoreReportKind.movement
        ? ReportColumns.ordered(
            ReportColumns.movement(),
            _orderFor(template, isMovement: true),
          )
        : ReportColumns.ordered(
            ReportColumns.summary(filter.groupBy),
            _orderFor(template, isMovement: false),
          );

    return [
      for (final column in columns)
        column.id,
    ];
  }

  // ─────────────────────────── الأعمدة ───────────────────────────
  Future<void> _openColumns() async {
    final filter = ref.read(storeReportProvider).filter;

    if (filter == null) return;

    final report = ReportTemplates.of(filter);
    final isMovement = filter.kind == StoreReportKind.movement;
    final all = isMovement
        ? ReportColumns.movement()
        : ReportColumns.summary(filter.groupBy);

    // لا `cast<Object>` هنا: الأعمدة أنواعها الحقيقية، ولو مُحيَت لانفجر القارئ وقت الرسم.
    // No `cast<Object>` here: columns keep their real types — erasing them explodes at paint.
    final labels = <(String, String)>[
      for (final column in all) (column.id, column.label),
    ];

    final choice = await ReportColumnsSheet.show(
      context,
      labels: labels,
      visible: _orderFor(report, isMovement: isMovement),
      statLabels: ReportStatFields.labels,
      visibleStats: _statIds,
      title: isMovement ? 'أعمدة تقرير الحركة' : 'أعمدة تقرير الخلاصة',
    );

    if (choice == null) return;

    setState(() {
      if (isMovement) {
        _movementOrder = choice.columnIds;
      } else {
        _summaryOrder = choice.columnIds;
      }

      _statIds = choice.statIds;
    });
  }

  // ─────────────────────────── النافذة ───────────────────────────
  Future<void> _openFilter() async {
    final reference = ref.read(storeReferenceProvider).value;

    if (reference == null) return;

    final current =
        ref.read(storeReportProvider).filter ??
        StoreReportFilter(
          from: DateTime.now().subtract(const Duration(days: 30)),
          to: DateTime.now(),
        );

    final result = await ReportFilterSheet.show(
      context,
      initial: current,
      reference: reference,
    );

    if (result == null || !mounted) return;

    await ref.read(storeReportProvider.notifier).run(result);
  }

  // ─────────────────────────── التصدير ───────────────────────────
  Future<void> _export({bool print = false}) async {
    final state = ref.read(storeReportProvider);

    if (state.filter == null || _busy) return;

    if (state.movementRows.isEmpty && state.summaryRows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا نتائج للتصدير')));

      return;
    }

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      // الأعمدة الظاهرة تُصدَّر كما هي — المطبوع نسخة مما يُرى لا جدولاً ثابتاً
      // The visible columns are exported as seen: the print is a copy of the screen, not a
      // hard-coded table.
      final bytes = await buildStoreReportPdf(
        letterhead: letterhead,
        filter: state.filter!,
        reference: ref.read(storeReferenceProvider).value,
        movementRows: state.movementRows,
        summaryRows: state.summaryRows,
        // إحصاء الخادم نفسه الذي يقرأه شريط الشاشة: لا رقم يُصاغ بيد ثانية للورق
        // The very server statistics the screen strip reads — no figure re-worded for paper.
        stats: state.stats,
        columnIds: _columnIds(state.filter!),
        // حقول الإحصاءات التي يهتم بها المستخدم — يخفيها في المطبوع كما أخفاها في الشاشة
        // The statistic fields the user cares about — hidden in print as they are on screen.
        statIds: _statIds,
        // التقسيم نفسه الذي على الشاشة: المطبوع نسخة منها لا جدول واحد يمحو الأقسام
        // The very split shown on screen: the printout is a copy, never one table that
        // erases the sections.
        sections: _sectionsFor(state),
        opening: ReportTotals.opening(state.stats),
      );

      final fileName =
          'store-report-${state.filter!.kind.code}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
        await ref.read(storeReportProvider.notifier).logExport('print');
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
        await ref.read(storeReportProvider.notifier).logExport('export');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر التصدير: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportXlsx() async {
    final state = ref.read(storeReportProvider);

    if (state.filter == null || _busy) return;

    setState(() => _busy = true);

    try {
      final bytes = buildStoreReportXlsx(
        filter: state.filter!,
        reference: ref.read(storeReferenceProvider).value,
        movementRows: state.movementRows,
        summaryRows: state.summaryRows,
        totalIn: state.totalIn,
        totalOut: state.totalOut,
        totalValue: state.totalValue,
        columnIds: _columnIds(state.filter!),
        sections: _sectionsFor(state),
        opening: ReportTotals.opening(state.stats),
      );

      await StoreExporter.shareXlsx(
        bytes: bytes,
        fileName: 'store-report-${StoreExporter.stamp()}.xlsx',
        subject: 'تقرير مخازن — ${state.filter!.kind.label}',
      );

      await ref.read(storeReportProvider.notifier).logExport('export');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر التصدير: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
