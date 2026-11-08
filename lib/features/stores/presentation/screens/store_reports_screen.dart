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
import '../utils/store_export.dart';
import '../widgets/report_columns_sheet.dart';
import '../widgets/report_data_table.dart';
import '../widgets/report_filter_sheet.dart';
import '../widgets/store_ui.dart';

/// تقارير المخازن — عرض حركة أو خلاصة بمعطيات تُختار في نافذة منبثقة
/// The stores reports — a movement view or a summary whose parameters are chosen in a sheet.
///
/// ── النافذة تُفتح تلقائياً عند الدخول: التقرير بلا مدى زمني وبلا مخزن يمسح الـ VIEW كاملة
///    ويُنتج آلاف السطور التي لا يقرأها أحد. الفتح التلقائي يجعل التحديد خطوة لا خياراً.
/// ── The sheet opens automatically on entry: an unbounded, store-less report scans the whole
///    view and returns thousands of rows nobody reads. Auto-opening makes selection a step.
///
/// ── القالب الرسمي واحد للحالتين: ترويسة التطبيق، شريط المعطيات، جدول كسول بأعمدة قابلة
///    للإخفاء، ثم تذييل التوقيعات — وهو نفسه ما يُطبع ويُصدَّر.
/// ── One official template for both kinds: the app letterhead, a parameters band, a lazy
///    table whose columns can be hidden, then the signature footer — and it is the same thing
///    that gets printed and exported.
class StoreReportsScreen extends ConsumerStatefulWidget {
  const StoreReportsScreen({super.key});

  @override
  ConsumerState<StoreReportsScreen> createState() => _StoreReportsScreenState();
}

class _StoreReportsScreenState extends ConsumerState<StoreReportsScreen> {
  bool _busy = false;

  /// الأعمدة الظاهرة — `null` حتى يلمس المستخدم نافذة الأعمدة فتسري الافتراضيات
  /// Visible columns: null until the user touches the columns sheet, then defaults apply.
  Set<String>? _movementColumns;
  Set<String>? _summaryColumns;

  @override
  void initState() {
    super.initState();

    // الفتح التلقائي عند الدخول فقط — والزر يفتحها دائماً بعدها
    // Auto-open on entry only; afterwards the button is what opens it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFilter());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeReportProvider);
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesReportsPrint);
    final canExport = auth.can(Perm.storesReportsExport);
    final hasRows = state.movementRows.isNotEmpty || state.summaryRows.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تقارير المخازن'),
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
    final movementColumns = ReportColumns.visible(
      ReportColumns.movement(),
      _chosenFor(template, _movementColumns),
    );

    final body = <Widget>[];

    // ── التقارير الموسّعة تُعرض أقساماً متتابعة: فرع بعد فرع، وصنف بعد صنف — لأن المراجع
    //    الذي يرى كل الفروع في جدول واحد لا يرى رصيد أي فرع منها على حدة.
    // ── Scoped reports render as successive sections, branch after branch and item after
    //    item: a reviewer looking at every branch in one table sees no branch's balance.
    if (isMovement && template.sectioned && state.sections.length > 1) {
      for (final block in _movementBlocks(template, state, movementColumns)) {
        body.add(block);
      }
    } else if (isMovement) {
      body.add(
        ReportDataTable<StockMovementRow>(
          columns: movementColumns,
          rows: state.movementRows,
        ),
      );
    } else {
      body.add(
        ReportDataTable<StockSummaryRow>(
          columns: ReportColumns.visible(
            ReportColumns.summary(filter.groupBy),
            _chosenFor(template, _summaryColumns),
          ),
          rows: state.summaryRows,
        ),
      );
    }

    // إحصاءات نهاية التقرير — totals الخادم لا مجموع ما على الشاشة
    // The closing statistics are the server's totals, never a sum of what is on screen.
    body.add(_statsBand(state.stats, title: 'إحصاءات التقرير'));

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
          // 5) التذييل الرسمي
          footer: const ReportSignatureFooter(),
        ),
      ),
    );
  }

  /// أقسام حركة صنف: عنوان القسم ثم جدول ثم إحصاء ذلك القسم
  /// A movement section: its heading, its table, and that section's own statistics.
  List<Widget> _movementBlocks(
    ReportTemplate template,
    StoreReportState state,
    List<ReportColumn<StockMovementRow>> columns,
  ) {
    final order = <String>[];
    final buckets = <String, List<StockMovementRow>>{};

    // الترتيب من الخادم لا من الشاشة: السطور مرتّبة بقسمها ثم بتاريخها أصلاً
    // The order comes from the server: rows already arrive section-major, then by date.
    for (final row in state.movementRows) {
      final key = row.sectionKey.isEmpty ? '__all__' : row.sectionKey;

      if (!buckets.containsKey(key)) {
        order.add(key);
        buckets[key] = <StockMovementRow>[];
      }

      buckets[key]!.add(row);
    }

    return [
      for (int i = 0; i < order.length; i++) ...[
        _sectionHeading(order[i], buckets[order[i]]!, state, i),
        ReportDataTable<StockMovementRow>(
          columns: columns,
          rows: buckets[order[i]]!,
        ),
        const SizedBox(height: 8),
        _statsBand(
          i < state.sections.length ? state.sections[i].stats : const ReportStats(),
          title: 'إحصاءات القسم',
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  Widget _sectionHeading(
    String key,
    List<StockMovementRow> rows,
    StoreReportState state,
    int index,
  ) {
    final fromRow = rows.first.sectionLabel.trim();
    final fromMeta = index < state.sections.length
        ? state.sections[index].label.trim()
        : '';
    final label = fromRow.isNotEmpty
        ? fromRow
        : fromMeta.isNotEmpty
        ? fromMeta
        : state.filter!.scope.label;

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
              '${state.filter!.scope == StoreReportScope.item ? 'الفرع' : 'القسم'}: $label',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          Text(
            '${rows.length} حركة',
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

  /// شريط الإحصاءات — السابق والوارد والمنصرف والصافي والحالي، كمية وقيمة
  /// The statistics band: opening, inbound, outbound, net and closing, quantity and value.
  ///
  /// ── الأرقام من الخادم وحده: الرصيد السابق لا يُعرف من السطور المعروضة، ولو حُسب هنا
  ///    لكان رقمًا من تأليف الواجهة.
  /// ── Every figure comes from the server: the opening balance cannot be known from the
  ///    visible rows, so computing it here would be the screen inventing a number.
  Widget _statsBand(ReportStats stats, {required String title}) {
    final cells = <(String, String, Color)>[      
      ('الرصيد السابق', StoreFormat.qty(stats.openingQty), AppColors.textPrimary),
      ('إجمالي الوارد', StoreFormat.qty(stats.qtyIn), AppColors.success),
      (
        'قيمة الوارد',
        stats.qtyInValue == 0 ? '—' : StoreFormat.money(stats.qtyInValue),
        AppColors.success,
      ),
      ('إجمالي المنصرف', StoreFormat.qty(stats.qtyOut), AppColors.error),
      (
        'قيمة المنصرف',
        stats.qtyOutValue == 0 ? '—' : StoreFormat.money(stats.qtyOutValue),
        AppColors.error,
      ),
      ('صافي الفترة', StoreFormat.qty(stats.netQty), AppColors.textPrimary),
      ('الرصيد الحالي', StoreFormat.qty(stats.closingQty), AppColors.primary),
      if (stats.closingValue != 0)
        ('قيمة الرصيد', StoreFormat.money(stats.closingValue), AppColors.primary),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            // لا const: `primary` قيمة مشتقة من لوحة الألوان لا ثابت
            // No const: primary is a derived palette value, not a literal.
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final cell in cells)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      '${cell.$1}: ',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      cell.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cell.$3,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// الأعمدة الظاهرة لقالب: الأساسية دائماً + ما اختاره المستخدم من الاختيارية
  /// The columns a template shows: the basics always, plus whatever the user picked.
  ///
  /// ── الأساسية لا تُخفى: إخفاء «الرصيد» من تقرير حركة يترك مستنداً لا يقول أين انتهى
  ///    الأمر، والقالب هو من يحدّد ماذا يبقى لا المستخدم.
  /// ── The basics cannot be hidden: hiding "balance" from a movement report leaves a document
  ///    that never says where things ended up. The template decides what stays, not the user.
  Set<String> _chosenFor(ReportTemplate template, Set<String>? chosen) {
    return {
      ...template.basic,
      if (chosen != null)
        for (final id in chosen)
          if (template.optional.contains(id)) id,
    };
  }

  /// معرّفات الأعمدة الظاهرة — تُمرَّرة للتصدير فيطابق المطبوع ما على الشاشة
  /// The visible column ids, passed to the exporters so the print matches the screen.
  List<String> _columnIds(StoreReportFilter filter) {
    final template = ReportTemplates.of(filter);

    final columns = filter.kind == StoreReportKind.movement
        ? ReportColumns.visible(
            ReportColumns.movement(),
            _chosenFor(template, _movementColumns),
          )
        : ReportColumns.visible(
            ReportColumns.summary(filter.groupBy),
            _chosenFor(template, _summaryColumns),
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

    // الأساسية تُعرض موصولة دائماً: القالب هو من يحدّدها لا القائمة المنسدلة
    // The basics are always shown and always on: the template defines them, not the sheet.
    // لا `cast<Object>` هنا: الأعمدة أنواعها الحقيقية، ولو مُحيَت لانفجر القارئ وقت الرسم.
    // No `cast<Object>` here: columns keep their real types — erasing them explodes at paint.
    final labels = <(String, String)>[
      for (final column in all)
        if (report.basic.contains(column.id) ||
            report.optional.contains(column.id))
          (column.id, column.label),
    ];

    final next = await ReportColumnsSheet.show(
      context,
      labels: labels,
      locked: report.basic,
      defaults: report.basic,
      initial: _chosenFor(report, isMovement ? _movementColumns : _summaryColumns),
    );

    if (next == null) return;

    setState(() {
      if (isMovement) {
        _movementColumns = next;
      } else {
        _summaryColumns = next;
      }
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
        totalIn: state.totalIn,
        totalOut: state.totalOut,
        totalValue: state.totalValue,
        columnIds: _columnIds(state.filter!),
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
