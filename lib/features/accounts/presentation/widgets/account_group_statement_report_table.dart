import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../data/models/account_group_statement_model.dart';
import 'account_statement_report_table.dart';

/// جدول "كشف حساب مجموعة حسابات جزئية" (ميزان المراجعة) - ترويسة ثنائية
/// الطبقات تطابق TRIAL_BALANCE_REPORT.pdf: عمودان مجمّعان "عملة محلية"
/// و"عملة أجنبية" فوق كل منهما "مدين/دائن"، بجانب رقم الحساب واسمها ورمز
/// العملة والرصيد، مع سطر إجمالي عام أسفل الجدول.
///
/// عمود «الرصيد» يعرض دائماً **الرصيد النهائي** للحساب (صافي كل حركاته)، ويُضاف
/// عمود «رصيد الفترة» مباشرةً قبله عند اختيار فترة، فيبقى الرصيد النهائي مقروءاً
/// في كل الحالات بدل أن يطمسه رصيد الفترة.
/// The «balance» column always shows the account's final balance over its whole
/// ledger; the extra «period balance» column appears right before it only when a
/// period is selected, so the final balance is never replaced by the period figure.
///
/// ### لماذا الصفوف كسولة الآن؟ / Why are the rows lazy now?
/// كان الجدول يُبنى كاملاً داخل `Table(children: [...rows.map(...)])`، فطلبُ
/// نطاق فيه 20774 حساباً يخلق نحو 187 ألف خلية — ولكل خلية `ui.Paragraph` أصلي
/// في محرّك الرسم. النتيجة كانت موتاً حتمياً للتطبيق بـ Scudo OOM عند 1.39GB
/// وليس مجرد بطء (انظر user_commends.md 2026-10-26). هنا تُبنى الترويسة وسطر
/// الإجمالي مرة واحدة، والصفوف تُبنى عند ظهورها فقط، فيبقى الذاكن ثابتاً مهما
/// كبر النطاق.
/// Built eagerly, one 20 774-row scope produced ~187k cells — each with a native
/// `ui.Paragraph` — and the process died of Scudo OOM at 1.39 GB. Header and
/// totals are now built once; rows are built only while visible, so memory stays
/// flat no matter how wide the scope is.
///
/// **الارتفاع يجب أن يكون محدوداً** — تُوضع هذه الأداة داخل صندوق بارتفاع
/// معروف (شاشة الكشف تحسبه من المساحة المتاحة). داخل تمرير غير محدود سيرفض
/// `Expanded` التخطيط بصوت عالٍ، وهذا أفضل من العودة الصامتة إلى بناء كل الصفوف.
/// **The parent must supply a bounded height** (the screen computes it from the
/// available space); an unbounded parent fails loudly instead of silently
/// rebuilding every row.
class AccountGroupStatementReportTable extends StatefulWidget {
  final TrialBalanceReport report;

  const AccountGroupStatementReportTable({super.key, required this.report});

  @override
  State<AccountGroupStatementReportTable> createState() =>
      _AccountGroupStatementReportTableState();
}

class _AccountGroupStatementReportTableState
    extends State<AccountGroupStatementReportTable> {
  // وحدة تحكم واحدة للقائمة: تُفيد شريط التمرير، وتبقى بعد إضافة صفحات جديدة
  // حتى يظل موضع المستخدم كما هو أثناء التحميل التدريجي.
  // One controller serves the scrollbar and survives page appends, so the user's
  // reading position is kept while more pages stream in.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return LayoutBuilder(
      builder: (context, constraints) {
        final m = statementTableMetrics(constraints.maxWidth);
        final headerFontSize = m.header * 0.9;

        // عمود الفترة وجوده مرتبط بالفلترة؛ وعمود الرصيد يبقى الأخير دائماً
        // The period column exists only under a date filter; balance stays last.
        final showPeriod = report.hasPeriod;
        final balanceIndex = showPeriod ? 8 : 7;

        // نفس نسب الأعمدة تمرّ إلى الترويسة وكل صف وسطر الإجمالي: بها فقط
        // يتطابق محاذاة الأرقام رغم أن كل صف جدول مستقل.
        // The SAME column widths are handed to the header, every row and the
        // totals row — that is what keeps the figures aligned across three
        // separate tables.
        final columnWidths = <int, TableColumnWidth>{
          0: const FlexColumnWidth(1.2), // رقم الحساب
          1: const FlexColumnWidth(3.2), // إسم الحساب
          2: const FlexColumnWidth(0.8), // العملة
          3: const FlexColumnWidth(1.4), // مدين محلي
          4: const FlexColumnWidth(1.4), // دائن محلي
          5: const FlexColumnWidth(1.4), // مدين أجنبي
          6: const FlexColumnWidth(1.4), // دائن أجنبي
          if (showPeriod) 7: const FlexColumnWidth(1.4), // رصيد الفترة
          balanceIndex: const FlexColumnWidth(1.5), // الرصيد النهائي
        };

        Widget slice(List<TableRow> rows) => Table(
              border: TableBorder.all(
                color: kStatementBorderColor,
                width: 1,
                style: BorderStyle.solid,
              ),
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows,
            );

        Widget head(String text) => tableHeaderCell(
              text,
              fontSize: headerFontSize,
              vPad: m.vPad,
              hPad: m.hPad,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) الترويسة المثبّتة (لا تتحرك مع الصفوف) / pinned header
            slice([
              TableRow(
                decoration: const BoxDecoration(color: kStatementHeaderBgColor),
                children: [
                  head('رقم الحساب'),
                  head('إسم الحساب'),
                  head('العملة'),
                  head('عملة محلية'),
                  const SizedBox(height: 4),
                  head('عملة أجنبية'),
                  const SizedBox(height: 4),
                  if (showPeriod) head('رصيد الفترة'),
                  head('الرصيد'),
                ],
              ),
              TableRow(
                decoration: const BoxDecoration(color: kStatementHeaderBgColor),
                children: [
                  head(''),
                  head(''),
                  head(''),
                  head('مدين'),
                  head('دائن'),
                  head('مدين'),
                  head('دائن'),
                  if (showPeriod) head(''),
                  head(''),
                ],
              ),
            ]),

            // 2) الصفوف — تُبنى عند ظهورها فقط / rows built on demand
            Expanded(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scroll,
                  // هامش التخزين المسبق يقلّل ظهور الصفوف بيضاء أثناء السحب السريع.
                  // Pre-cache a screenful so fast dragging never shows blank rows.
                  cacheExtent: 600,
                  itemCount: report.rows.length,
                  itemBuilder: (context, index) => _buildRow(
                    report.rows[index],
                    m: m,
                    showPeriod: showPeriod,
                    columnWidths: columnWidths,
                  ),
                ),
              ),
            ),

            // 3) سطر الإجمالي العام — مثبّت أسفل الجدول دائماً
            // The grand-total line stays pinned under the list.
            slice([
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                children: [
                  tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
                  tableDataCell(
                    'إجمالي حسابات ${report.asOfDate}',
                    isCenter: true,
                    isBold: true,
                    fontSize: m.data,
                    vPad: m.vPad,
                    hPad: m.hPad,
                  ),
                  tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
                  tableDataCell(formatStatementAmount(report.totals.localDebit),
                      isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(report.totals.localCredit),
                      isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(report.totals.foreignDebit),
                      isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  tableDataCell(formatStatementAmount(report.totals.foreignCredit),
                      isBold: true, fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
                  if (showPeriod)
                    tableDataCell(formatStatementAmount(report.totals.periodBalance),
                        isBold: true,
                        textColor: const Color(0xFF1D4ED8),
                        fontSize: m.data,
                        vPad: m.vPad,
                        hPad: m.hPad,
                        fitBox: true),
                  tableDataCell(
                    formatStatementAmount(report.totals.balance),
                    isBold: true,
                    textColor: const Color(0xFFDC2626),
                    fontSize: m.data,
                    vPad: m.vPad,
                    hPad: m.hPad,
                    fitBox: true,
                  ),
                ],
              ),
            ]),
          ],
        );
      },
    );
  }

  /// صف بيانات واحد كجدول مستقل يشترك في نفس نسب الأعمدة مع الترويسة.
  /// A single data row as its own table, sharing the header's column widths.
  Widget _buildRow(
    TrialBalanceRow row, {
    required ({double header, double data, double vPad, double hPad}) m,
    required bool showPeriod,
    required Map<int, TableColumnWidth> columnWidths,
  }) {
    return Table(
      border: TableBorder.all(
        color: kStatementBorderColor,
        width: 1,
        style: BorderStyle.solid,
      ),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: [
            tableDataCell(
              row.accNo.toString(),
              fontSize: m.data,
              vPad: m.vPad,
              hPad: m.hPad,
              fitBox: true,
            ),
            tableDataCell(
              ArabicEncodingUtils.fix(row.accName),
              isCenter: false,
              fontSize: m.data,
              vPad: m.vPad,
              hPad: m.hPad,
            ),
            tableDataCell(
              row.curCode,
              fontSize: m.data,
              vPad: m.vPad,
              hPad: m.hPad,
            ),
            tableDataCell(formatStatementAmount(row.localDebit),
                fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
            tableDataCell(formatStatementAmount(row.localCredit),
                fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
            tableDataCell(formatStatementAmount(row.foreignDebit),
                fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
            tableDataCell(formatStatementAmount(row.foreignCredit),
                fontSize: m.data, vPad: m.vPad, hPad: m.hPad, fitBox: true),
            if (showPeriod)
              tableDataCell(formatStatementAmount(row.periodBalance),
                  isBold: true,
                  textColor: const Color(0xFF1D4ED8),
                  fontSize: m.data,
                  vPad: m.vPad,
                  hPad: m.hPad,
                  fitBox: true),
            tableDataCell(formatStatementAmount(row.balance),
                isBold: true,
                fontSize: m.data,
                vPad: m.vPad,
                hPad: m.hPad,
                fitBox: true),
          ],
        ),
      ],
    );
  }
}
