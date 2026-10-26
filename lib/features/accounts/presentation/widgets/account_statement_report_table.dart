import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';
import '../../../../core/utils/report_letterhead_info.dart';
import '../../../../core/widgets/report_letterhead_branding.dart';
import '../../data/models/chart_account_model.dart';

/// Shared amount formatter — mirrors `customer_statement_screen.dart`'s private
/// `_formatAmount`, exposed here so both the account statement report widgets
/// and the PDF builders (which import this file) stay byte-for-byte consistent.
String formatStatementAmount(double? amount) {
  if (amount == null || amount == 0) return '0';

  final isNegative = amount < 0;
  final absVal = amount.abs();

  final parts = absVal.toStringAsFixed(2).split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];

  final buffer = StringBuffer();
  int count = 0;
  for (int i = integerPart.length - 1; i >= 0; i--) {
    buffer.write(integerPart[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write(',');
    }
  }
  final formattedInt = buffer.toString().split('').reversed.join('');
  final res = decimalPart == '00' ? formattedInt : '$formattedInt.$decimalPart';
  return isNegative ? '-$res' : res;
}

const Color kStatementHeaderBgColor = Color(0xFFD4A853);
const Color kStatementBorderColor = Color(0xFF4B5563);

/// Tiers the same font-size/padding scale already proven in
/// `customer_statement_screen.dart` (isVeryCompact < 450, isCompact < 650),
/// so this feature-local table matches the on-screen density of the customer
/// report exactly at every screen width without touching that feature.
///
/// الأرقام مطابقة حرفياً لجدول كشف العميل: أي تعديل هنا يجب أن يُطبَّق هناك أيضاً
/// حتى يبقى شكل التقارير المالية واحداً على الشاشة وفي PDF.
/// The numbers mirror the customer report table byte-for-byte; a change here
/// must be mirrored there so every financial report still looks the same.
({double header, double data, double vPad, double hPad}) statementTableMetrics(
  double screenWidth,
) {
  final isCompact = screenWidth < 650;
  final isVeryCompact = screenWidth < 450;

  return (
    header: isVeryCompact ? 9.5 : (isCompact ? 10.5 : 11.5),
    data: isVeryCompact ? 8.5 : (isCompact ? 9.5 : 10.5),
    vPad: isVeryCompact ? 3.0 : (isCompact ? 3.5 : 4.5),
    hPad: isVeryCompact ? 1.5 : (isCompact ? 2.5 : 4.0),
  );
}

Widget tableHeaderCell(
  String text, {
  double fontSize = 11,
  double vPad = 6,
  double hPad = 3,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.black,
      ),
    ),
  );
}

Widget tableDataCell(
  String text, {
  bool isCenter = true,
  Color? textColor,
  bool isBold = false,
  double fontSize = 10,
  double vPad = 5,
  double hPad = 5,
  bool fitBox = false,
}) {
  Widget content = Text(
    text,
    textAlign: isCenter ? TextAlign.center : TextAlign.start,
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: textColor ?? Colors.black87,
    ),
  );

  if (fitBox) {
    content = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: isCenter ? Alignment.center : Alignment.centerRight,
      child: content,
    );
  }

  return Padding(
    padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
    child: content,
  );
}

/// الترويسة الرسمية (Letterhead) — شريط بثلاثة أعمدة (عربي يمين / الشعار وسط /
/// إنجليزي يسار) من إعدادات الشركة، ثم اسم الحساب + طابع وقت التقرير +
/// خلايا "من تاريخ/إلى تاريخ"، مطابقة لقالب acc_report.pdf.
class AccountStatementLetterhead extends StatelessWidget {
  final ReportLetterheadInfo letterhead;
  final String accName;
  final int accNo;
  final String? currency;
  final String fromDate;
  final String toDate;

  const AccountStatementLetterhead({
    super.key,
    required this.letterhead,
    required this.accName,
    required this.accNo,
    required this.currency,
    required this.fromDate,
    required this.toDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: kStatementBorderColor, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الترويسة ثلاثية الأعمدة: الكتلة العربية + الشعار + الكتلة الإنجليزية
          // Three-column band: Arabic block + logo + English block.
          ReportLetterheadBranding(info: letterhead),
          const SizedBox(height: 6),

          Text(
            'كشف حساب مالي',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'الحساب: [$accNo] ${ArabicEncodingUtils.fix(accName)}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (currency != null && currency!.isNotEmpty)
                Text(
                  currency!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // نطاق التاريخ: صفّ واحد على الشاشات الواسعة، وعمود
          // متراكم على الضيقة — النصوص بلا flex كانت تفيض 157px عند تكبير
          // الخط 1.25×. Responsive: one row when wide, stacked column when
          // narrow — the un-flexed texts overflowed at 1.25× text scale.
          LayoutBuilder(
            builder: (context, constraints) {
              final dateRangeText = Text(
                'من تاريخ: $fromDate   إلى تاريخ: $toDate',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    dateRangeText,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: dateRangeText)
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد، مع رصيد افتتاحي
/// وصف حركات ورصيد جارٍ لكل سطر. يتجاوب مع عرض الشاشة عبر `statementTableMetrics`.
///
/// الجدول **كسول (lazy)**: الرأس وصف الرصيد الافتتاحي في جدول ثابت أعلى، وصفوف
/// الحركات في `ListView.builder`، وسطر الإجمالي في جدول ثابت أسفل — والثلاثة
/// تتشارك نفس `columnWidths` فيبقى الانطباع جدولاً واحداً.
///
/// سبب ذلك: كشف الفترة الكاملة قد يحمل آلاف الحركات، وبناؤها كلها في `Table`
/// واحد يُنشئ خلية أصلية لكل نص فينفد heap الجهاز ويُقتل التطبيق (Scudo OOM).
/// The table is **lazy**: a fixed header (column titles + opening balance), a
/// `ListView.builder` for the movement rows, and a fixed totals row — all three
/// sharing one `columnWidths` map so it still reads as a single table. Building
/// thousands of rows into one `Table` allocates a native paragraph per cell and
/// exhausts the device heap (Scudo OOM), which is what this split prevents.
class AccountStatementReportTable extends StatefulWidget {
  final List<AccountTransactionModel> transactions;
  final double openingBalance;
  final double finalBalance;
  final double totalDebit;
  final double totalCredit;

  /// ارتفاع منطقة الصفوف القابلة للتمرير. `null` = يُشتق من الشاشة (55% منها،
  /// محصور بين 240 و760). مرِّره عندما يكون الأب محدد الارتفاع لتعبئة كامل المساحة.
  /// Height of the scrollable rows area. `null` derives it from the screen; pass a
  /// value when the parent already has a bound and the rows should fill it.
  final double? rowsHeight;

  const AccountStatementReportTable({
    super.key,
    required this.transactions,
    required this.openingBalance,
    required this.finalBalance,
    required this.totalDebit,
    required this.totalCredit,
    this.rowsHeight,
  });

  @override
  State<AccountStatementReportTable> createState() =>
      _AccountStatementReportTableState();
}

class _AccountStatementReportTableState
    extends State<AccountStatementReportTable> {
  /// متحكّم تمرير واحد يُمرَّر للـ Scrollbar والـ ListView معاً حتى لا يظهر شريط
  /// تمرير منفصل عن المحتوى. One controller shared by Scrollbar and ListView.
  final ScrollController _scroll = ScrollController();

  /// أوزان الأعمدة: مشتركة بين الشرائح الثلاث، وهي ما يُبقي الأرقام متحاذية.
  /// One column-width map shared by all three slices — this is what keeps the
  /// amounts aligned across separate tables.
  static const Map<int, TableColumnWidth> _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(0.85), // السند
    1: FlexColumnWidth(1.15), // النوع
    2: FlexColumnWidth(1.0), // تأريخه
    3: FlexColumnWidth(3.3), // البيان
    4: FlexColumnWidth(1.2), // مدين
    5: FlexColumnWidth(1.2), // دائن
    6: FlexColumnWidth(1.45), // الرصيد
  };

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// شريحة جدول واحدة (رأس/افتتاحي/صف حركة/إجمالي) بنفس الحدود والأوزان.
  /// One table slice with the shared border and column widths.
  Widget _slice(List<TableRow> rows) {
    return Table(
      border: TableBorder.all(
        color: kStatementBorderColor,
        width: 1,
        style: BorderStyle.solid,
      ),
      columnWidths: _columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  TableRow _headerRow(({double header, double data, double vPad, double hPad}) m) {
    return TableRow(
      decoration: const BoxDecoration(color: kStatementHeaderBgColor),
      children: [
        tableHeaderCell('السند', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('النوع', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('تأريخه', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('البيان', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('مدين', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('دائن', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
        tableHeaderCell('الرصيد', fontSize: m.header, vPad: m.vPad, hPad: m.hPad),
      ],
    );
  }

  /// سطر الرصيد الافتتاحي — ثابت أعلى القائمة، لا يتحرك مع التمرير.
  /// Opening-balance row — pinned above the scrollable rows.
  TableRow _openingRow(
    ({double header, double data, double vPad, double hPad}) m,
  ) {
    final opening = widget.openingBalance;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell(
          'رصيد افتتاحي',
          isCenter: true,
          textColor: const Color(0xFF0369A1),
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
        ),
        tableDataCell(
          formatStatementAmount(opening >= 0 ? opening : 0),
          isCenter: true,
          textColor: const Color(0xFFDC2626),
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(opening < 0 ? opening.abs() : 0),
          isCenter: true,
          textColor: const Color(0xFFDC2626),
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(opening),
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
      ],
    );
  }

  /// سطر حركة — الرصيد الجاري يحسبه الخادم تراكمياً من ENTRY_MNT ولا يُقرأ
  /// من BALANCE_S أبداً. A movement row; its running balance comes from the server
  /// (opening + cumulative period movement), never from the stored BALANCE_S.
  TableRow _dataRow(
    AccountTransactionModel tx,
    ({double header, double data, double vPad, double hPad}) m,
  ) {
    final debitVal = tx.debit ?? 0.0;
    final creditVal = tx.credit ?? 0.0;
    final balVal = tx.balance ?? 0.0;

    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        tableDataCell(
          tx.subEntryNo?.isNotEmpty == true
              ? tx.subEntryNo!
              : (tx.entryNo?.toString() ?? ''),
          isCenter: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          ArabicEncodingUtils.fix(tx.entryTypeName ?? ''),
          isCenter: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
        ),
        tableDataCell(
          tx.date ?? '',
          isCenter: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          ArabicEncodingUtils.fix(tx.description ?? ''),
          isCenter: false,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
        ),
        tableDataCell(
          formatStatementAmount(debitVal),
          isCenter: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(creditVal),
          isCenter: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(balVal),
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
      ],
    );
  }

  /// سطر إجمالي العمليات — ثابت أسفل القائمة.
  /// Totals row — pinned below the scrollable rows.
  TableRow _totalsRow(
    ({double header, double data, double vPad, double hPad}) m,
  ) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
      children: [
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell('', fontSize: m.data, vPad: m.vPad, hPad: m.hPad),
        tableDataCell(
          'اجمالي العمليات',
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
        ),
        tableDataCell(
          formatStatementAmount(widget.totalDebit),
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(widget.totalCredit),
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
        tableDataCell(
          formatStatementAmount(widget.finalBalance),
          isCenter: true,
          isBold: true,
          fontSize: m.data,
          vPad: m.vPad,
          hPad: m.hPad,
          fitBox: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Font family is applied app-wide via `app_theme.dart` (GoogleFonts.getFont
    // on the configured family, Cairo by default) — no per-widget font override
    // needed here, matching how `customer_statement_screen.dart`'s own table
    // relies on the ambient theme instead of re-specifying a family.
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = statementTableMetrics(constraints.maxWidth);

        // ارتفاع منطقة الصفوف: من الأب إن كان محدداً، وإلا نسبة من الشاشة — القائمة
        // внутри Column مفتوح الارتفاع تحتاج ارتفاعاً صريحاً وإلا فشل التخطيط.
        // Row viewport: the parent's bound when it has one, otherwise a share of the
        // screen — a ListView inside an unbounded Column needs an explicit height.
        final rowsHeight = widget.rowsHeight ??
            (constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (MediaQuery.sizeOf(context).height * 0.55)
                    .clamp(240.0, 760.0)
                    .toDouble());

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الرأس + الرصيد الافتتاحي (ثابتان)
              _slice([_headerRow(m), _openingRow(m)]),

              // الحركات — تُبنى عند الظهور فقط، فالذاكرة مستوية مهما كان العدد.
              // Movements — built lazily on appearance, so memory stays flat.
              SizedBox(
                height: rowsHeight,
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scroll,
                    cacheExtent: 600,
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) =>
                        _slice([_dataRow(widget.transactions[index], m)]),
                  ),
                ),
              ),

              // سطر الإجمالي (ثابت)
              _slice([_totalsRow(m)]),
            ],
          ),
        );
      },
    );
  }
}
