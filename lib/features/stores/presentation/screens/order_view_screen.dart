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
import '../../data/models/order_model.dart';
import '../../data/repositories/store_orders_repository.dart';
import '../providers/orders_providers.dart';
import '../utils/store_document_layout.dart';
import '../utils/store_export.dart';
import '../widgets/store_ui.dart';
import 'order_form_screen.dart';

/// استعراض مستند مخزني — نسخة طبق الأصل من مستند النظام المكتبي
/// Viewing a stock document — a faithful replica of the desktop document.
///
/// ── لماذا نسخة طبق الأصل لا «بطاقات أنيقة»؟ لأن المستخدم يقارن هذه الشاشة بالطبعة الورقية
///    سطرًا بسطر حين يختلف المخزون. أي اختلاف في الأعمدة أو الترتيب أو المجاميع يجعل المقارنة
///    مستحيلة ويحوّل المستند إلى شيء آخر يشبهه. لذلك: نفس عنوان المستند، نفس أعمدة السطور
///    (بما فيها المقاسات والتصنيف واللون والرف والعبوة والقطعة)، نفس شريط المجاميع، ونفس
///    التفقيط — فوق ترويسة التطبيق الرسمية وتذييله الموحّدين.
/// ── Why a replica rather than prettier cards? When stock disagrees the user compares this
///    screen against the paper line by line. Any difference in columns, order or totals makes
///    that comparison impossible and turns the document into something that merely resembles it.
///    So: same title, same line columns (sizes, classification, colour, shelf, pack, pieces),
///    same totals strip, same amount-in-words — on the app's official letterhead and footer.
class OrderViewScreen extends ConsumerStatefulWidget {
  const OrderViewScreen({super.key, required this.kind, required this.billNo});

  final StoreOrderKind kind;
  final int billNo;

  @override
  ConsumerState<OrderViewScreen> createState() => _OrderViewScreenState();
}

class _OrderViewScreenState extends ConsumerState<OrderViewScreen> {
  bool _busy = false;

  /// خط الورقة الرقيق — لون واحد في كل خانات المستند
  /// The sheet's hairline colour, shared by every box on the document.
  static const Color _rule = Color(0xFFD7CEC2);

  /// تعريف النوع: عنوانه وحقوله — لا شروط متفرقة في الشاشة
  /// The kind's profile: its title and fields — no scattered conditions on the screen.
  StoreDocProfile get _profile => StoreDocProfile.of(widget.kind);

  /// عنوان المستند كما يطبعه النظام: «فاتورة توريد مخزني» / «منصرف مخزني» / «تحويل مخزني»
  /// The document title exactly as the desktop prints it.
  String get _docTitle => _profile.title;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(
      orderDetailProvider((kind: widget.kind, billNo: widget.billNo)),
    );
    final auth = ref.watch(authNotifierProvider);
    final canEdit = auth.can(_updateCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$_docTitle ${widget.billNo}'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'تعديل',
              onPressed: () => _openEdit(),
              icon: const Icon(Icons.edit_outlined),
            ),
          IconButton(
            tooltip: 'طباعة',
            onPressed: _busy ? null : () => _export(detail.value, print: true),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'مشاركة PDF',
            onPressed: _busy ? null : () => _export(detail.value),
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const StoreLoading(),
        error: (error, _) => StoreErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(
            orderDetailProvider((kind: widget.kind, billNo: widget.billNo)),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const StoreEmptyState(
              icon: Icons.description_outlined,
              title: 'المستند غير موجود',
            );
          }

          final letterhead = ReportLetterheadInfo.fromConfig(
            ref.watch(appConfigNotifierProvider).config,
          );

          // التكبير + التمرير الطبيعي: الورقة بطول محتواها لا بمقاس A4 على الشاشة
          // Zoom plus natural scrolling: the sheet grows with its content on screen.
          return ReportZoomView(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: ReportA4Sheet(
                orientation: ReportSheetOrientation.landscape,
                maxPageWidth: 1240,
                header: ReportLetterheadBranding(info: letterhead),
                title: _sheetTitle(data.header),
                meta: _metaBlock(data.header),
                body: _body(data),
                footer: const ReportSignatureFooter(),
              ),
            ),
          );
        },
      ),
    );
  }

  /// الكود الذي يحرّر هذا النوع من المستندات — صريح لا مركّب من نص
  /// The grant that edits this document kind, written out rather than string-built.
  String get _updateCode => switch (widget.kind) {
    StoreOrderKind.receive => Perm.storesReceivingUpdate,
    StoreOrderKind.issue => Perm.storesIssuingUpdate,
    StoreOrderKind.transfer => Perm.storesTransferUpdate,
  };

  // ───────────────────────────── رأس الورقة ─────────────────────────────

  Widget _sheetTitle(StoreOrderModel header) {
    return Column(
      children: [
        Text(
          _docTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'رقم ${header.reference}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// شريط تفاصيل المستند: صف واحد موازٍ لجدول السطور
  /// The document detail strip: one row, parallel to the lines table.
  ///
  /// ── لماذا صف واحد؟ لأن كل خانة تُقرأ مقابل السطر الذي تحتها؛ وأي التفاف إلى صف ثانٍ يقطع
  ///    هذه المقابلة. والحقول نفسها تُقرأ من المصدر المشترك مع PDF فلا يختلف المطبوع عن الشاشة.
  /// ── رقم الفاتورة مقصود غيابه هنا: يُكتب تحت العنوان مرة واحدة فلا يتكرر الرقم مرتين.
  /// ── Why one row? Each box is read against the line beneath it; wrapping to a second row
  ///    breaks that correspondence. The fields come from the source shared with the PDF.
  /// ── The invoice number is deliberately absent: it is written once under the title.
  Widget _metaBlock(StoreOrderModel header) {
    final cells = storeDocumentMeta(widget.kind, header);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cells.length; index++) ...[
            if (index > 0) Container(width: 1, color: _rule),
            Expanded(
              flex: _metaFlex(cells[index].$1),
              child: _metaCell(cells[index].$1, cells[index].$2),
            ),
          ],
        ],
      ),
    );
  }

  /// وزن كل خانة: العدد رقم صغير، وأسماء المخازن والأطراف تحتاج عرضاً أوسع
  /// Per-box weight: the count is a small number; store and party names need room.
  int _metaFlex(String label) => switch (label) {
    'العدد' => 2,
    'تاريخ الفاتورة' => 5,
    'نوع الفاتورة' || 'العملة' || 'رقم الصرف' || 'رقم التوريد' => 4,
    _ => 7,
  };

  Widget _metaCell(String label, String value) {
    // ── FittedBox لا ellipsis: النص يُصغَّر ليدخل كاملاً بدل أن يُبتر بنقاط.
    //    رقم مسلسل أو اسم مخزن مختصر يضلّل المراجع أكثر من خط أصغر.
    // ── FittedBox rather than an ellipsis: the text shrinks so every letter stays visible
    //    instead of being cut. A truncated serial or store name misleads more than small type.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────── متن الورقة ─────────────────────────────

  Widget _body(StoreOrderDetail data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _linesTable(data.lines),
        const SizedBox(height: 8),
        _financialBlock(data.header),
      ],
    );
  }

  /// أعمدة السطور — من مصدر التخطيط المشترك، فلا تنفصل الشاشة عن الطباعة
  /// The line columns — taken from the shared layout, so screen and print cannot diverge.
  List<StoreDocColumn> get _columns => storeDocumentColumns(widget.kind);

  /// جدول السطور: رأس ذهبي موحّد + حدود لكل خلية + بلا تمرير جانبي
  /// The lines table: the unified gold header, a border per cell, and no horizontal scrolling.
  Widget _linesTable(List<StoreOrderLineModel> lines) {
    final columns = _columns;

    if (lines.isEmpty) {
      return const StoreEmptyState(
        icon: Icons.list_alt_rounded,
        title: 'لا سطور',
        description: 'هذا المستند بلا أصناف — لا يمكن أن يكون قد حرّك أي رصيد.',
      );
    }

    /// الجدول بعرض معطى — الدالة المحلية تسمح بتصغيره بدل تمريره أفقياً
    /// The table at a given width — the local builder allows scaling it instead of panning.
    Widget sheet(double width) {
      return SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Table(
              border: TableBorder.all(
                color: const Color(0xFF9CA3AF),
                width: 0.5,
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              // النِّسَب هي ما يجعل الأعمدة تتوزع كما في الطبعة، والحجز الأدنى يمنع
              // سحق «إسم الصنف» حين تضيق الورقة.
              // The ratios distribute columns as the printout does; the reserved minimum keeps
              // the item name from being crushed when the sheet narrows.
              columnWidths: {
                for (var i = 0; i < columns.length; i++)
                  i: FlexColumnWidth(columns[i].weight),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFD4A853)),
                  children: [
                    for (final column in columns)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 3,
                        ),
                        child: Text(
                          column.title,
                          textAlign: column.numeric
                              ? TextAlign.left
                              : TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
                for (var index = 0; index < lines.length; index++)
                  TableRow(
                    decoration: BoxDecoration(
                      color: index.isOdd
                          ? const Color(0xFFF9FAFB)
                          : Colors.white,
                    ),
                    children: [
                      for (final column in columns)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 3,
                          ),
                          child: Text(
                            column.value(lines[index]),
                            textAlign: column.numeric
                                ? TextAlign.left
                                : TextAlign.right,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight:
                                  column.numeric && column.title == 'الإجمالي'
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                            // ── عمود «إسم الصنف» يلتف حتى يظهر كاملاً ولا يُبتر منه حرف،
                            //    وبقية الأعمدة سطر واحد لأن أرقامها لا تُختصر بحاجة.
                            // ── The item name wraps so no letter is cut; the other columns stay
                            //    single-line because their figures never need a second line.
                            maxLines: column.wrap ? null : 1,
                            softWrap: column.wrap,
                            overflow: column.wrap
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
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

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4B5563)),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // الحد الكافي يمنع نزول أي عمود تحت حدّه الأدنى — وإلا قُطع «إسم الصنف»
          // The required width stops any column falling under its floor, or the name is clipped.
          final required = storeDocumentMinWidth(columns);

          // ── لا تمرير جانبي: الأعمدة التسعة تُوزّع على العرض المتاح كما هي؛ وإن ضاق عن
          //    حدّها الأدنى تُصغَّر الشبكة كلها بدل بتر الأعمدة أو دفع المستخدم للتمرير أفقياً.
          // ── No horizontal scrolling: the nine columns share the available width; if it is
          //    narrower than the floor, the whole grid scales down instead of being cut or
          //    forcing the user to pan sideways.
          if (constraints.maxWidth >= required) {
            return sheet(constraints.maxWidth);
          }

          return FittedBox(
            fit: BoxFit.fitWidth,
            alignment: AlignmentDirectional.center,
            child: sheet(required),
          );
        },
      ),
    );
  }

  /// التفاصيل المالية: عمودان متقابلان — يميناً المبلغ كتابةً والبيان، ويساراً الأرقام
  /// The money block: two facing columns — words and description right, figures left.
  ///
  /// ── لماذا عمودان؟ لأن الطبعة تفصل «ماذا يعنيه المبلغ» عن «كم هو»؛ حشر الخمسة حقول في
  ///    سطر واحد يفرض تمريراً أو خطاً دقيقاً. هنا يُقرأ البيان كاملاً ويبقى الرقم بارزاً.
  /// ── Why two columns? The printout separates what the amount *means* from how much it is;
  ///    cramming five fields on one line forces scrolling or a tiny font. Here the description
  ///    reads in full while the figures stay prominent.
  Widget _financialBlock(StoreOrderModel header) {
    final figures = <(String, String, bool)>[
      ('الإجمالي', StoreFormat.money(header.total), false),
      ('مبلغ الخصم', storeDiscountText(header), false),
      ('صافي المبلغ', StoreFormat.money(header.net), true),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // اليمين في RTL هو الابن الأول
          // The right-hand column is the first child under RTL.
          Expanded(flex: 6, child: _wordsBox(header)),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final figure in figures)
                  _moneyBox(figure.$1, figure.$2, emphasise: figure.$3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// المبلغ كتابةً ثم البيان — أطول حقلين، فلهما العمود الأوسع
  /// The amount in words then the description — the two longest fields, hence the wider column.
  Widget _wordsBox(StoreOrderModel header) {
    final note = header.detailes;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _smallLabel('المبلغ كتابةً'),
          const SizedBox(height: 2),
          Text(
            StoreFormat.amountInWords(header.net, currencyName: header.curName),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Divider(height: 1, color: _rule),
            const SizedBox(height: 4),
            _smallLabel('البيان'),
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(fontSize: 9.5, color: AppColors.textPrimary),
            ),
          ],
        ],
      ),
    );
  }

  /// خانة رقم مالي: الاسم إلى اليمين والقيمة إلى اليسار فيُقرأ الاثنان من موضع ثابت
  /// A money box: label right, figure left, so both are read from one stable position.
  Widget _moneyBox(String label, String value, {required bool emphasise}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasise ? const Color(0xFFFDF8EE) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: emphasise ? AppColors.primary : _rule),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasise ? 11.5 : 10.5,
              fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600,
              color: emphasise ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }

  // ───────────────────────────── الإجراءات ─────────────────────────────

  Future<void> _openEdit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderFormScreen(kind: widget.kind, billNo: widget.billNo),
      ),
    );

    if (!mounted) return;

    ref.invalidate(orderDetailProvider((kind: widget.kind, billNo: widget.billNo)));
    ref.read(ordersListProvider.notifier).load(keepPage: true);
  }

  Future<void> _export(StoreOrderDetail? data, {bool print = false}) async {
    if (data == null || _busy) return;

    setState(() => _busy = true);

    try {
      final letterhead = ReportLetterheadInfo.fromConfig(
        ref.read(appConfigNotifierProvider).config,
      );

      final bytes = await buildStoreOrderPdf(
        letterhead: letterhead,
        kind: widget.kind,
        header: data.header,
        lines: data.lines,
      );

      final fileName =
          'store-${widget.kind.code}-${data.header.reference}-${StoreExporter.stamp()}.pdf';

      if (print) {
        await StoreExporter.print(bytes: bytes, fileName: fileName);
      } else {
        await StoreExporter.sharePdf(bytes: bytes, fileName: fileName);
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
}
