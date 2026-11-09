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
import '../../data/repositories/store_result.dart';
import '../providers/items_providers.dart';
import '../utils/report_columns.dart';
import '../utils/report_parameters.dart';
import '../utils/report_totals.dart';
import '../utils/store_export.dart';
import '../widgets/report_columns_sheet.dart';
import '../widgets/report_data_table.dart';
import '../widgets/report_stats_band.dart';
import '../widgets/store_ui.dart';

/// كشف حركة صنف — الصنف الرئيسي بكامل فروعه أو فرع واحد
/// An item movement statement — the main item with all branches, or one branch.
///
/// ── لماذا شاشة مستقلة وليس تبويباً داخل تفصيل الصنف؟ لأن الكشف يُطبع ويُصدَّر ويُقارَن
///    بفترتين، وهذا عمل مراجعة لا تصفّح. التبويب كان يخفي الطباعة والمدى الزمني.
/// ── Why a separate screen instead of a tab inside the item detail? A statement is printed,
///    exported and compared across periods — that is review work, not browsing. A tab hid the
///    date range and the print action.
class ItemMovementScreen extends ConsumerStatefulWidget {
  const ItemMovementScreen({
    super.key,
    required this.sanfNo,
    required this.itemName,
    this.subDno,
    this.subLabel,
  });

  final int sanfNo;
  final String itemName;

  /// فرع محدد: أيقونة كشف الحركة بجانب الصنف الفرعي تفتح فرعه هو فقط
  /// A specific branch: the statement icon beside a sub item opens only that branch.
  final int? subDno;
  final String? subLabel;

  @override
  ConsumerState<ItemMovementScreen> createState() => _ItemMovementScreenState();
}

class _ItemMovementScreenState extends ConsumerState<ItemMovementScreen> {
  DateTime? _from;
  DateTime? _to;
  bool _busy = false;

  /// ترتيب الأعمدة الظاهرة — `null` حتى يغيّره المستخدم فتُطبَّق افتراضيات الكشف
  /// The visible column order — null until the user changes it, then the statement defaults.
  List<String>? _order;

  /// حقول الإحصاءات الظاهرة — `null` تعني «كلها»
  /// The visible statistic fields — null means "all of them".
  List<String>? _statIds;

  /// الأعمدة الأساسية للكشف = أعمدة تقرير الحركة نفسها، فلا يختلف الكشف عن التقرير
  /// The statement's basic columns are the movement report's basics: a statement must not
  /// disagree with the report it came from.
  static const List<String> _statementDefaults = <String>[
    'type',
    'date',
    'doc',
    'qty',
    'cost',
    'value',
    'balance',
    'branch',
    'store',
  ];

  String get _branchLabel => widget.subDno == null
      ? 'كل الفروع'
      : (widget.subLabel ?? 'فرع ${widget.subDno}');

  String get _rangeText {
    if (_from == null && _to == null) return 'كل الفترات';

    final from = _from == null ? 'البداية' : StoreFormat.date(_from);
    final to = _to == null ? 'اليوم' : StoreFormat.date(_to);

    return 'من $from إلى $to';
  }

  ItemStatementKey get _key => (
    sanfNo: widget.sanfNo,
    subDno: widget.subDno,
    from: _from,
    to: _to,
    storeNo: null,
  );

  @override
  Widget build(BuildContext context) {
    final statement = ref.watch(itemStatementProvider(_key));
    final auth = ref.watch(authNotifierProvider);
    final canPrint = auth.can(Perm.storesReportsPrint);
    final canExport = auth.can(Perm.storesReportsExport);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كشف حركة الصنف'),
        actions: [
          IconButton(
            tooltip: 'المدى الزمني',
            onPressed: () => _pickRange(context),
            icon: const Icon(Icons.date_range_rounded),
          ),
          IconButton(
            tooltip: 'أعمدة العرض',
            onPressed: _openColumns,
            icon: const Icon(Icons.view_column_rounded),
          ),
          if (canPrint)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _busy ? null : () => _export(statement.value, print: true),
              icon: const Icon(Icons.print_outlined),
            ),
          if (canExport)
            IconButton(
              tooltip: 'تصدير Excel',
              onPressed: _busy ? null : () => _exportXlsx(statement.value),
              icon: const Icon(Icons.ios_share_rounded),
            ),
        ],
      ),
      // لا شريط فوق الترويسة: المستند يبدأ بترويسة التطبيق وينتهي بتذييله الرسمي،
      // فالصنف والفرع صارا مذكورين في عنوان الكشف نفسه
      // No strip above the letterhead: the document starts with the app's letterhead and ends
      // with its official footer, and the item and branch now live in the statement's title.
      body: statement.when(
        loading: () => const StoreLoading(
          message: 'جارٍ تجهيز كشف الحركة...',
        ),
        error: (error, _) => StoreErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(itemStatementProvider(_key)),
        ),
        data: (data) {
          if (data.isEmpty) {
            // ── بلا المدى الزمني في الرسالة حين لا مدى محدداً: «في المدى المحدد» توحي
            //    بأن المستخدم اختار مدى وهو لم يختر، والحقيقة أن الصنف بلا حركة إطلاقاً.
            // ── Do not blame a range the user never picked: "in the selected range" reads
            //    like a filter problem when the truth is the item has no movement at all.
            return StoreEmptyState(
              icon: Icons.timeline_rounded,
              title: 'لا حركات',
              description: _from == null && _to == null
                  ? 'لم يُورَّد هذا الصنف ولا يُصرف منه بعد، فرصيد صفر هنا صحيح لا ناقص. '
                        'اختر مدى زمنياً لعرض ما سبق.'
                  : 'لا حركة في المدى المحدد ($_rangeText). وسّع المدى أو أعد الضبط.',
            );
          }

          return _sheet(data);
        },
      ),
    );
  }

  /// القالب الرسمي للكشف بخمسة مكوّنات: ترويسة · عنوان · جدول · ملخص · تذييل
  /// The statement's official template in five parts: letterhead · title · table · summary · footer.
  ///
  /// ── كان الكشف يُرسم كقائمة بطاقات بلا ترويسة ولا تذييل: نسخة قابلة للقراءة على الهاتف
  ///    لكنها ليست مستنداً يُسلَّم لمحاسب ولا للمراجعة.
  /// ── The statement used to be a list of cards with no letterhead and no footer: readable on
  ///    a phone, but not a document an accountant or a reviewer could be handed.
  Widget _sheet(MovementStatement data) {
    final letterhead = ReportLetterheadInfo.fromConfig(
      ref.read(appConfigNotifierProvider).config,
    );
    final title = _title();

    return ReportZoomView(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ReportA4Sheet(
          orientation: ReportSheetOrientation.landscape,
          maxPageWidth: 1240,
          // 1) الترويسة الرسمية
          header: ReportLetterheadBranding(info: letterhead),
          // 2) عنوان الكشف ثم المدى عند التخصيص فقط
          title: _titleBlock(title),
          // 3) الجدول و4) ملخصه داخل المتن، ثم 5) التذييل الرسمي
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ReportDataTable<StockMovementRow>(
                columns: _visibleColumns(),
                rows: data.rows,
                // سطر التجميع في ذيل الجدول، ثم ملخص الخادم تحته
                // The totals row closes the table; the server's summary follows beneath it.
                totals: ReportTotals.movement(data.rows),
              ),
              const SizedBox(height: 10),
              ReportStatsBand(
                title: 'إحصاءات الكشف',
                fields: ReportStatFields.visible(
                  ReportStatFields.statement(data),
                  _statIds,
                ),
              ),
            ],
          ),
          // الشركة لا تصرف بأنفسها: خانة الوسط في تقارير المخازن لأمين المخزن
          // A company does not hand out stock itself: the middle slot is the storekeeper's.
          footer: const ReportSignatureFooter(
            keeper: ReportSignatureFooter.storekeeper,
          ),
        ),
      ),
    );
  }

  /// عنوان الكشف مبنياً في طبقة الأدوات — نفس ما يطبعه الـ PDF حرفيًا
  /// The statement title built in the utils layer — byte for byte what the PDF prints.
  ReportTitle _title() {
    return ReportTitles.statement(
      itemName: widget.itemName,
      branchLabel: _branchLabel,
      branchOnly: widget.subDno != null,
      // المدى لا يُذكر إلا إذا خصّصه المستخدم: «كل الفترات» هي الافتراضي لا اختيار
      // The range appears only if the user set it: "all periods" is the default, not a choice.
      period: _from == null && _to == null ? null : _rangeText,
    );
  }

  Widget _titleBlock(ReportTitle title) {
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

  /// الأعمدة الفعلية: اختيار المستخدم بترتيبه أو افتراضيات الكشف
  /// The columns in force: the user's order, or the statement's own defaults.
  List<ReportColumn<StockMovementRow>> _visibleColumns() {
    final template = ReportColumns.movement();

    // نوع حقيقي لا محاك: قارئ العمود يقبل صفه بعينه، و`Object` يرمي `is not a subtype`
    // A real type, not an erased one: the reader takes its own row, so Object would throw.
    return ReportColumns.ordered(template, _order ?? _statementDefaults);
  }

  List<String> _columnIds() {
    return [
      for (final column in _visibleColumns())
        column.id,
    ];
  }

  Future<void> _openColumns() async {
    final template = ReportColumns.movement();

    final choice = await ReportColumnsSheet.show(
      context,
      title: 'أعمدة كشف الحركة',
      labels: [for (final column in template) (column.id, column.label)],
      visible: _order ?? _statementDefaults,
      statLabels: ReportStatFields.statementLabels,
      visibleStats: _statIds,
    );

    if (choice == null || !mounted) return;

    setState(() {
      _order = choice.columnIds;
      _statIds = choice.statIds;
    });
  }

  /// اختيار المدى الزمني — بلا مدى يُمسح الـ VIEW كاملة
  /// Pick the date range — an unbounded statement scans the whole view.
  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'مدى كشف الحركة',
      saveText: 'تطبيق',
    );

    if (picked == null) return;

    setState(() {
      _from = picked.start;
      _to = picked.end;
    });
  }

  Future<void> _export(MovementStatement? data, {bool print = false}) async {
    if (data == null || data.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final bytes = await buildItemStatementPdf(
        letterhead: letterhead,
        itemName: widget.itemName,
        branchLabel: _branchLabel,
        rangeText: _rangeText,
        rows: data.rows,
        qtyIn: data.qtyIn,
        qtyOut: data.qtyOut,
        netQty: data.netQty,
        totalValue: data.value,
        // المطبوع نسخة مما على الشاشة، لا جدولاً ثانيًا كُتب بيد أخرى
        // The print is a copy of the screen, not a second table written by another hand.
        columnIds: _columnIds(),
        statIds: _statIds,
        branchOnly: widget.subDno != null,
        customPeriod: _from != null || _to != null,
      );

      final fileName =
          'item-movement-${widget.sanfNo}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تجهيز الكشف: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportXlsx(MovementStatement? data) async {
    if (data == null || data.isEmpty || _busy) return;

    setState(() => _busy = true);

    try {
      final bytes = buildItemStatementXlsx(
        itemName: widget.itemName,
        branchLabel: _branchLabel,
        rangeText: _rangeText,
        rows: data.rows,
        qtyIn: data.qtyIn,
        qtyOut: data.qtyOut,
        netQty: data.netQty,
        totalValue: data.value,
        columnIds: _columnIds(),
      );

      await StoreExporter.shareXlsx(
        bytes: bytes,
        fileName: 'item-movement-${widget.sanfNo}-${StoreExporter.stamp()}.xlsx',
        subject: 'كشف حركة ${widget.itemName}',
      );
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
