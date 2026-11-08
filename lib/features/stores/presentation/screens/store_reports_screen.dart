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

    // نوعان حقيقيان لا نوع محاك واحد: قارئ العمود دالة تستقبل صفها بعينه، وإمحاؤه
    // بـ`Object` يرمي `is not a subtype` عند أول خلية تُرسم
    // Two real types, never one erased type: a column's reader takes its own row, and erasing
    // it to Object throws "is not a subtype" on the first cell drawn.
    final table = isMovement
        ? ReportDataTable<StockMovementRow>(
            columns: ReportColumns.visible(
              ReportColumns.movement(),
              _movementChosen,
            ),
            rows: state.movementRows,
          )
        : ReportDataTable<StockSummaryRow>(
            columns: ReportColumns.visible(
              ReportColumns.summary(filter.groupBy),
              _summaryChosen(filter.groupBy),
            ),
            rows: state.summaryRows,
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
              table,
              const SizedBox(height: 10),
              _summaryBand(state),
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

  /// ملخص الجدول — الرقم والقيمة من الخادم لا من المرئي
  /// The table summary — server figures, never the visible slice.
  Widget _summaryBand(StoreReportState state) {
    final isMovement = state.kind == StoreReportKind.movement;
    final count = isMovement
        ? state.movementRows.length
        : state.summaryRows.length;

    final cells = <(String, String, Color)>[
      ('عدد السطور', '$count', AppColors.textPrimary),
      ('وارد', StoreFormat.qty(state.totalIn), AppColors.success),
      ('صادر', StoreFormat.qty(state.totalOut), AppColors.error),
      ('الصافي', StoreFormat.qty(state.totalIn - state.totalOut), AppColors.textPrimary),
      ('القيمة', StoreFormat.money(state.totalValue), AppColors.primary),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
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
    );
  }

  /// الأعمدة المختارة لنوع الحركة — الافتراضي ما لم يلمس المستخدم شيئاً
  /// The chosen movement columns: the defaults until the user touches anything.
  Set<String> get _movementChosen {
    final template = ReportColumns.movement();

    return _movementColumns ?? ReportColumns.defaultIds(template).toSet();
  }

  /// الأعمدة المختارة للخلاصة — تتبع مستوى التجميع لأن عنوان العمود الأول يتبدّل
  /// The chosen summary columns: they follow the aggregation level, since the first column's
  /// caption changes with it.
  Set<String> _summaryChosen(StoreReportGroupBy level) {
    final template = ReportColumns.summary(level);

    return _summaryColumns ?? ReportColumns.defaultIds(template).toSet();
  }

  /// معرّفات الأعمدة الظاهرة — تُمرَّرة للتصدير فيطابق المطبوع ما على الشاشة
  /// The visible column ids, passed to the exporters so the print matches the screen.
  List<String> _columnIds(StoreReportFilter filter) {
    if (filter.kind == StoreReportKind.movement) {
      return [
        for (final column in ReportColumns.visible(
          ReportColumns.movement(),
          _movementChosen,
        ))
          column.id,
      ];
    }

    return [
      for (final column in ReportColumns.visible(
        ReportColumns.summary(filter.groupBy),
        _summaryChosen(filter.groupBy),
      ))
        column.id,
    ];
  }

  // ─────────────────────────── الأعمدة ───────────────────────────
  Future<void> _openColumns() async {
    final state = ref.read(storeReportProvider);
    final filter = state.filter;

    if (filter == null) return;

    final isMovement = filter.kind == StoreReportKind.movement;
    final template = isMovement
        ? ReportColumns.movement()
        : ReportColumns.summary(filter.groupBy);
    final chosen = Set<String>.from(
      (isMovement ? _movementColumns : _summaryColumns) ??
          ReportColumns.defaultIds(template),
    );

    final next = await ReportColumnsSheet.show(
      context,
      labels: [for (final column in template) (column.id, column.label)],
      defaults: ReportColumns.defaultIds(template),
      initial: chosen,
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
