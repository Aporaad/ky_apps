import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../data/models/account_group_statement_model.dart';
import '../../data/models/tree_export_row_model.dart';
import '../providers/accounts_provider.dart';
import '../utils/account_group_statement_pdf_builder.dart';
import '../utils/account_tree_flatten.dart';
import '../utils/account_tree_pdf_builder.dart';
import '../utils/account_tree_xlsx_builder.dart';
import '../utils/group_statement_xlsx_builder.dart';
import '../utils/tree_export_adapter.dart';
import 'tree_export_scope_sheet.dart';

/// منع النقر المزدوج مشترك: `_busy` يُعطل القائمة أثناء التوليد — توليد آلاف الأسطر
/// ثقيل، ونقر ثانٍ كان يولّد ملفين ويترك المستخدم ينتظر الاثنين.
/// Shared double-tap guard + file plumbing for every report menu in this feature.
/// Only the builders differ per report, which is why the builders are injected.
///
/// لماذا لم تعد الشجرة تقرأ ما على الشاشة؟ كانت الصفوف المصدَّرة هي `_visibleRows()`
/// نفسها — والشجرة كسولة: الحسابات المالية تُجلب صفحة عند التوسيع فقط. فأي مستند
/// كان يخرج بالحسابات الرئيسة وحدها، أي بموضع تمرير المستخدم لا بدليل الحسابات.
///
/// Export used to serialize the visible scroll position, so a collapsed tree printed
/// its section headers and nothing else. The scope now belongs to the document: the
/// sheet asks which levels to include, and that answer is sent to the server.
class TreeExportMenu extends ConsumerStatefulWidget {
  final String title;
  final String? periodLabel;
  final String? filterNote;

  /// القسم الذي يفلتر به المستخدم شاشته الآن — يقترح كنطاق مبدئي لأنه غالباً يريد
  /// مطبوعة ما يراه أمامه، لكنه يغيّره في النافذة إن شاء.
  /// The section currently filtered on screen, offered as the sheet's starting point.
  final int? defaultSectionAccNo;

  const TreeExportMenu({
    this.title = 'الشجرة المحاسبية',
    this.periodLabel,
    this.filterNote,
    this.defaultSectionAccNo,
    super.key,
  });

  @override
  ConsumerState<TreeExportMenu> createState() => _TreeExportMenuState();
}

class _TreeExportMenuState extends ConsumerState<TreeExportMenu> {
  /// صفوف النطاق الذي جهّزه المستخدم آخر مرة — لا تُقرأ الشجرة إطلاقاً هنا.
  List<AccountTreeRow>? _preparedRows;
  String? _scopeNote;
  CancelToken? _token;

  @override
  void dispose() {
    // نفس convention بقية الشاشات: استجابة متأخرة لا يجوز أن تلمس حالة ميّتة.
    _token?.cancel('غادر المستخدم شاشة الشجرة');
    _token = null;
    super.dispose();
  }

  /// سؤال → طلب → تحويل إلى صفوف العرض. `false` = أوقف التوليد (إلغاء/خطأ/نطاق فاشل).
  /// Ask, fetch, adapt. Returns false when the job must not proceed.
  Future<bool> _prepareScope() async {
    final state = ref.read(accountTreeProvider);
    final initial = TreeExportScope(
      levels: TreeExportLevel.values,
      sectionAccNo: widget.defaultSectionAccNo,
      fromDate: state.fromDate,
      toDate: state.toDate,
    );

    final scope = await showTreeExportScopeSheet(
      context,
      initial: initial,
      sections: state.tree,
      periodLabel: widget.periodLabel,
    );
    if (scope == null || !mounted) return false; // ألغى النافذة: لا طلب ولا ملف

    final token = CancelToken();
    _token = token;
    final List<TreeExportRow> raw;
    try {
      raw = await ref
          .read(accountRepositoryProvider)
          .fetchTreeExport(scope, cancelToken: token);
    } on DioException catch (e) {
      if (mounted) _toast(_describeFailure(e));
      return false;
    } finally {
      _token = null;
    }
    if (!mounted) return false;

    // عدّ المستويات من الرد نفسه: المستند يصف محتواه بدل أن يُخمَّن.
    final levelCounts = <String, int>{};
    for (final row in raw) {
      levelCounts[row.level] = (levelCounts[row.level] ?? 0) + 1;
    }
    final rows = treeExportRowsToDisplay(raw);
    setState(() {
      _preparedRows = rows;
      _scopeNote = describeTreeExport(
        scope: scope,
        totalRows: rows.length,
        levelCounts: levelCounts,
      );
    });
    return true;
  }

  /// رسالة الخادم إن وجدت — «لا صلاحية» العربية أهم من «DioException [bad response]».
  ///
  /// الـ 404 حالة خاصة: هي لا تعني أن الطلب خاطئ الصياغة بل أن الخادم الذي يعمل
  /// الآن نسخة لا تعرف النقطة أصلاً (checkout أقدم أو خزّان مسارات قديم)، فلا
  /// خيار للمستخدم أن يعرف ذلك وإلا ظنّ أن الطباعة معطلة في التطبيق.
  /// A 404 here means the running API predates the endpoint, not a malformed request.
  String _describeFailure(DioException e) {
    final data = e.response?.data;
    final serverMessage = data is Map && data['message'] is String
        ? data['message'] as String
        : null;
    if (e.response?.statusCode == 404) {
      return 'الخادم الحالي لا يعرف نقطة التصدير (404) — حدِّث الـ API من المستودع '
          'وأعد تشغيل php artisan serve ثم امسح خزّان المسارات (route:clear)';
    }
    return serverMessage ??
        'تعذّر جلب الحسابات المحدّدة — تحقّق من الاتصال أو أعد المحاولة';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReportExportActions(
      title: widget.title,
      printLabel: 'طباعة الشجرة',
      onPrepare: _prepareScope,
      rowCount: () => _preparedRows?.length ?? 0,
      emptyMessage:
          'لم يُرجع هذا النطاق أي صف — اختر مستويات أكثر أو أوقف «إخفاء الأرصدة الصفرية»',
      xlsxFileName: () => accountTreeXlsxFileName(),
      buildPdf: (letterhead) => buildAccountTreePdf(
        letterhead: letterhead,
        rows: _preparedRows ?? const [],
        title: widget.title,
        periodLabel: widget.periodLabel,
        filterNote: _scopeNote ?? widget.filterNote,
      ),
      buildXlsx: () => buildAccountTreeXlsx(
        rows: _preparedRows ?? const [],
        periodLabel: widget.periodLabel,
      ),
    );
  }
}

/// نفس القائمة لميزان مراجعة المجموعة: طباعة / PDF / Excel — الورقتان من نفس
/// المنفذ أعلاه، فلا نسخة ثانية من حراسة النقر المزدوج وكتابة الملف.
/// The very same menu for the group trial balance, so the export plumbing exists once.
class GroupStatementExportMenu extends ConsumerStatefulWidget {
  /// تُقرأ لحظة الضغط ليصدَّر الميزان المعروض لا ما بُنيت عنده الشاشة.
  final TrialBalanceReport Function() report;

  const GroupStatementExportMenu({required this.report, super.key});

  @override
  ConsumerState<GroupStatementExportMenu> createState() =>
      _GroupStatementExportMenuState();
}

class _GroupStatementExportMenuState extends ConsumerState<GroupStatementExportMenu> {
  @override
  Widget build(BuildContext context) {
    return _ReportExportActions(
      title: 'ميزان مجموعة حسابات',
      printLabel: 'طباعة الميزان',
      rowCount: () => widget.report().rows.length,
      xlsxFileName: () => groupStatementXlsxFileName(),
      buildPdf: (letterhead) => buildAccountGroupStatementPdf(
        letterhead: letterhead,
        report: widget.report(),
      ),
      buildXlsx: () => buildGroupStatementXlsx(report: widget.report()),
    );
  }
}

class _ReportExportActions extends ConsumerStatefulWidget {
  final String title;
  final String printLabel;
  final int Function() rowCount;
  final String Function() xlsxFileName;
  final Future<Uint8List> Function(ReportLetterheadInfo letterhead) buildPdf;
  final List<int> Function() buildXlsx;

  /// تجهيز مسبق اختياري: يجمع بيانات المستند قبل أي توليد، ويرجع false لإلغاء
  /// العملية بهدوء (مستخدم ألغى نافذة النطاق، أو رفض الخادم الطلب).
  /// Optional pre-flight. Reports that need server data ask for it here, so a
  /// cancelled dialog never burns a request and a failed one never writes a file.
  final Future<bool> Function()? onPrepare;

  /// رسالة الصفوف الفارغة تخص كل تقرير: الشجرة لم تعد «توسيع عقدة»، فالمصدر القاعدة.
  final String emptyMessage;

  const _ReportExportActions({
    required this.title,
    required this.printLabel,
    required this.rowCount,
    required this.xlsxFileName,
    required this.buildPdf,
    required this.buildXlsx,
    this.onPrepare,
    this.emptyMessage = 'لا توجد صفوف للتصدير — وسّع عقدة أو أزل الفلاتر',
  });

  @override
  ConsumerState<_ReportExportActions> createState() => _ReportExportActionsState();
}

class _ReportExportActionsState extends ConsumerState<_ReportExportActions> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      // تصدير Excel صلاحيةُ تصدير، والطباعة صلاحيةُ طباعة — لا يظهر عنصر يرفضه الخادم
      code: ref.can(Perm.accountsExport) || ref.can(Perm.accountsPrint)
          ? null
          : Perm.accountsExport,
      child: PopupMenuButton<_ExportAction>(
        enabled: !_busy,
        tooltip: 'طباعة وتصدير',
        icon: Icon(
          _busy ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
          size: 20,
        ),
        onSelected: _onSelected,
        itemBuilder: (context) => [
          if (ref.can(Perm.accountsPrint))
            PopupMenuItem(
              value: _ExportAction.print,
              child: _MenuRow(
                icon: Icons.print_outlined,
                label: widget.printLabel,
                hint: 'A4 عبر الطابعة',
              ),
            ),
          if (ref.can(Perm.accountsExport))
            const PopupMenuItem(
              value: _ExportAction.pdf,
              child: _MenuRow(
                icon: Icons.picture_as_pdf_outlined,
                label: 'تصدير PDF',
                hint: 'مشاركة ملف PDF',
              ),
            ),
          if (ref.can(Perm.accountsExport))
            const PopupMenuItem(
              value: _ExportAction.xlsx,
              child: _MenuRow(
                icon: Icons.grid_on_rounded,
                label: 'تصدير Excel',
                hint: 'xlsx بورقتين',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onSelected(_ExportAction action) async {
    if (_busy) return;
    // `_busy` قبل التجهيز لا بعده: جلب آلاف الأسطر من القاعدة بطيء، ونقر ثانٍ
    // في أثنائه كان سيطلب نسختين من نفس النطاق ويكتب ملفاً فوق ملف.
    // The guard covers the fetch too, not just the document generation.
    setState(() => _busy = true);
    try {
      final prepare = widget.onPrepare;
      if (prepare != null && !await prepare()) return;
      if (!mounted) return;

      final count = widget.rowCount();
      if (count == 0) {
        _toast(widget.emptyMessage);
        return;
      }

      if (action == _ExportAction.xlsx) {
        await _exportXlsx(count);
      } else {
        final letterhead = ReportLetterheadInfo.fromConfig(
          ref.read(appConfigNotifierProvider).config,
        );
        final bytes = await widget.buildPdf(letterhead);
        final pdfName = widget.xlsxFileName().replaceAll('.xlsx', '.pdf');
        if (action == _ExportAction.print) {
          await Printing.layoutPdf(onLayout: (_) async => bytes, name: pdfName);
        } else {
          await Printing.sharePdf(bytes: bytes, filename: pdfName);
        }
      }
    } catch (e) {
      _toast('فشل التصدير: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// كتابة ملف XLSX إلى مساحة التطبيق ثم مشاركته — الحزمة وحدها لا تلمس القرص.
  Future<void> _exportXlsx(int count) async {
    final bytes = widget.buildXlsx();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${widget.xlsxFileName()}',
    );
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: widget.title,
        text: '${widget.title} — $count سطر',
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum _ExportAction { print, pdf, xlsx }

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.hint});

  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          hint,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
