import 'dart:math' as math;

import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../theme/app_colors.dart';
import 'report_pdf_arabic.dart';

/// شبكة طباعة موحّدة — نسخة طبق الأصل من جدول التقرير على الشاشة
/// The unified print grid — a faithful copy of the on-screen report table.
///
/// ── لماذا ملف مركزي؟ لأن كل تقارير التطبيق كانت تحمل جدولها المطبوع بيدين مختلفتين:
///    الشاشة ترسم رأساً واحداً وخلايا بسطر واحد وعروضاً ثابتة، والمطبوع كان يُجزَّأ
///    جداول كل ثلاثين سطراً — لكل واحد رأسه — فيظهر رأس الجدول في منتصف الصفحة مرات،
///    وينزلق كل عمود حين يُحسب عرضه نسبةً مستقلة في كل كتلة. الشبكة هنا تُنتج
///    `pw.Table` **واحداً** بكل السطور، فتتولّى `MultiPage` تقسيمه ورأسه مرة واحدة.
/// ── Why one central file? Because every report printed its grid with a different hand:
///    the screen draws one head, one line per cell and fixed columns, while the printout
///    was cut into tables of thirty rows each carrying its own head — so the heading
///    reappeared in the middle of a page and every column drifted, its fraction being
///    rounded per block. This grid emits ONE `pw.Table` holding every row: `MultiPage`
///    paginates it and the head is drawn exactly once.
///
/// ── الحدود الوحيدة المسموحة هنا: نصوص وقيم جاهزة للنص. لا نوع ميزة ولا نموذج بيانات
///    يعبر هذه الحدود، حتى تبقى الشبكة مشتركة بين كل التقارير.
/// ── The only currency here is plain display text. No feature type or data model crosses
///    this boundary, which is what keeps the grid shared by every report.

// ─── عمود الشبكة / A grid column ────────────────────────────────────────────────

/// عمود واحد في شبكة الطباعة: عنوانه ونسبته وهل قيمته رقم
/// One print-grid column: its caption, its share of the width, whether it holds figures.
class PdfGridColumn {
  const PdfGridColumn({
    required this.label,
    this.numeric = false,
    this.weight = 1,
  });

  /// عنوان العمود كما يظهر في الرأس — يُشكَّل تلقائياً قبل الرسم
  /// The column caption shown in the head; it is shaped before being drawn.
  final String label;

  /// الأرقام تُحاذاة لآخر السطر وتُقرأ اليسار→يمين، والنصوص لأوّل السطر
  /// Figures are end-aligned and drawn left-to-right; text starts at the reading edge.
  final bool numeric;

  /// النسبة من العرض — نفس أوزان جدول الشاشة كي تتطابق الخانات موضعاً
  /// The share of the width — the screen table's own weights, so cells line up.
  final double weight;
}

// ─── لوحة الألوان المطابقة للشاشة / The screen-matching palette ─────────────────

/// درجات الشبكة مشتقة من `AppColors` لحظة الطباعة: غيّرت السمة تغيّر المطبوع معها.
/// The grid's tones are read from [AppColors] at print time — change the theme and the
/// printout changes with it, exactly as the screen does.
///
/// ── الألوان شبه الشفافة تُسطَّح فوق الأبيض لأن الورقة بيضاء أصلاً، والشفافية في PDF
///    تُنتج طبقات إضافية عند بعض القارئات بلا أي فرق مرئي.
/// ── Translucent tones are flattened over white: paper is white anyway, and PDF alpha
///    only adds layers that some readers render inconsistently for no visual gain.
class PdfGridPalette {
  const PdfGridPalette();

  /// حدود الجدول — نفس رمادي الشاشة الفاتح، لا الحبر الثقيل
  /// The grid rules — the screen's light grey, not heavy ink.
  PdfColor get rule => _solid(AppColors.border);

  /// شريط الرأس — خلفية أساسية شفافة 8% كما في الشاشة
  /// The head band — the screen's 8% primary tint.
  PdfColor get headBand => _tint(AppColors.primary, 0.08);

  /// نص الرأس — الأساسي العريض نفسه
  /// The head text — the same bold primary.
  PdfColor get headText => _solid(AppColors.primary);

  /// شريط الرصيد السابق — أفتح من المجاميع: مقدّمة لا خاتمة
  /// The opening band — lighter than the totals: a preface, not a conclusion.
  PdfColor get openingBand => _tint(AppColors.border, 0.28);

  /// شريط المجاميع — 12% من الأساسي
  /// The totals band — 12% of the primary.
  PdfColor get totalsBand => _tint(AppColors.primary, 0.12);

  /// نص المجاميع
  /// The totals text.
  PdfColor get totalsText => _solid(AppColors.primary);

  /// النص العادي
  /// Ordinary text.
  PdfColor get text => _solid(AppColors.textPrimary);

  /// السالب علامة خطر — كما في الشاشة
  /// A negative is the risk mark, as on screen.
  PdfColor get negative => _solid(AppColors.error);

  /// خلفية شريط الإحصاءات — مثل الشريط على الشاشة
  /// The statistics strip's background — the screen band's own tint.
  PdfColor get statsBand => _tint(AppColors.primary, 0.05);

  /// شريط عنوان القسم — 10% من الأساسي كما ترسمه الشاشة
  /// A section heading's band — the screen's 10% primary.
  PdfColor get sectionBand => _tint(AppColors.primary, 0.10);

  /// النص الباهت (عدد الحركات، العناوين الصغيرة)
  /// Muted text: a section's movement count and small captions.
  PdfColor get muted => _solid(AppColors.textMuted);

  /// اللون الدلالي باسمه — الشاشة والخادم يتقاسمان الأسماء لا كائنات الألوان
  /// A semantic colour by name — screen and data share names, never colour objects.
  PdfColor tone(String name) {
    switch (name) {
      case 'success':
        return _solid(AppColors.success);
      case 'error':
        return _solid(AppColors.error);
      case 'primary':
        return _solid(AppColors.primary);
      default:
        return _solid(AppColors.textPrimary);
    }
  }

  // ‏`.r/.g/.b` تُعطي المكوّنات من 0 إلى 1 مباشرة، وهو ما يطلبه `PdfColor` بالضبط
  // `.r/.g/.b` already yield 0..1 components, which is exactly what PdfColor takes.
  static PdfColor _solid(Color color) => PdfColor(color.r, color.g, color.b);

  static PdfColor _tint(Color color, double alpha) => PdfColor(
    alpha * color.r + (1 - alpha),
    alpha * color.g + (1 - alpha),
    alpha * color.b + (1 - alpha),
  );
}

// ─── هندسة الشبكة / Grid geometry ──────────────────────────────────────────────

const double _minColumn = 14;

/// عروض الأعمدة بالنقاط: نسبة الوزن من العرض، والأخير يلتقط الباقي فيبقى المجموع
/// مساوياً للعرض تماماً.
/// Column widths in points: each weight's share of the width, the last absorbing the
/// remainder so the sum equals the available width exactly.
///
/// ── لماذا ثابتة لا مرنة؟ لأن `pw.Table` يعيد توزيع `FlexColumnWidth` بنسبة مجموعها،
///    فأي فرق تقريب بين كتلة وأخرى يُزيح الأعمدة عن مواضعها — وهو عطل «الأعمدة تخرج
///    من أماكنها». العرض المحسوب مرة واحدة يجعل الرأس والسطور والمجاميع على مسار واحد.
/// ── Fixed, never flex: `pw.Table` re-distributes flex fractions by their sum, so any
///    rounding difference between blocks slides the columns — the reported defect. One
///    computed track keeps the head, the rows and the totals on the same columns.
List<double> pdfGridColumnWidths(
  List<PdfGridColumn> columns,
  double width,
) {
  if (columns.isEmpty) return const <double>[];

  final total = columns.fold<double>(0, (sum, c) => sum + math.max(c.weight, 0));

  final widths = <double>[];
  var used = 0.0;

  for (int i = 0; i < columns.length; i++) {
    final isLast = i == columns.length - 1;
    final share = total <= 0
        ? width / columns.length
        : width * math.max(columns[i].weight, 0) / total;

    // الآخر يأخذ المتبقي لا نسبته: التقريب التراكمي كان يترك شقاً في نهاية السطر
    // The last column takes what is left, not its fraction: cumulative rounding used to
    // leave a sliver at the end of every row.
    final value = isLast
        ? math.max(width - used, _minColumn)
        : math.max(share.floorToDouble(), _minColumn);

    widths.add(value);
    used += value;
  }

  return widths;
}

/// هندسة الجدول المحسوبة: عروض + حجم خط موحد + ارتفاع خلية موحد
/// The computed geometry: widths plus one uniform font size and one uniform cell height.
class PdfGridGeometry {
  PdfGridGeometry._({
    required this.widths,
    required this.fontSize,
    required this.padding,
    required this.rowHeight,
  });

  /// يحسب من العرض وعدد الأعمدة — ونفس سلّم جدول الشاشة مضروباً في 0.75 لأن
  /// النقطة في PDF تساوي 0.75 بكسلاً منطقياً في Flutter، فيتطابق الحَجمان مقاساً.
  /// Derived from the width and the column count — the screen table's own ladder times
  /// 0.75, because one PDF point is 0.75 Flutter logical pixels, so both agree physically.
  factory PdfGridGeometry.compute({
    required List<PdfGridColumn> columns,
    required double width,
    double? fontSize,
  }) {
    final widths = pdfGridColumnWidths(columns, width);
    final perColumn = columns.isEmpty ? width : width / columns.length;

    final base = fontSize ?? _baseFontSize(perColumn);
    final pad = _basePadding(perColumn);

    return PdfGridGeometry._(
      widths: widths,
      fontSize: base,
      padding: pad,
      // ارتفاع واحد لكل الخانات: سطر واحد لا التواء، وصف لا يطول على حساب جاره
      // One height for every cell: a single line that never wraps, and no row growing
      // at its neighbour's expense.
      rowHeight: base * 1.55 + pad * 1.6,
    );
  }

  final List<double> widths;
  final double fontSize;
  final double padding;
  final double rowHeight;

  /// عروض الجدول النهائية — ثابتة بالنقاط، لا نسب
  /// The table's final column widths — fixed points, never fractions.
  Map<int, pw.TableColumnWidth> get columnWidths => {
    for (int i = 0; i < widths.length; i++)
      i: pw.FixedColumnWidth(widths[i]),
  };

  static double _baseFontSize(double perColumn) {
    if (perColumn >= 66) return 8.25; // ≈ 11 px on screen
    if (perColumn >= 51) return 7.5; // ≈ 10 px
    if (perColumn >= 39) return 6.75; // ≈ 9 px
    if (perColumn >= 30) return 6.0; // ≈ 8 px
    return 5.6; // ≈ 7.5 px — the widest reports
  }

  static double _basePadding(double perColumn) {
    if (perColumn >= 51) return 3.75;
    if (perColumn >= 34) return 2.6;
    return 1.5;
  }
}

// ─── الشبكة نفسها / The grid itself ────────────────────────────────────────────

/// جدول تقرير واحد للطباعة: رأس + رصيد سابق + سطور + مجاميع، في `pw.Table` واحدة
/// A report's single print table: head, opening, rows and totals inside ONE `pw.Table`.
///
/// ── الرأس يُرسم مرة واحدة: `TableRow.repeat` مُطفأ افتراضياً، والجدول كامل يُمَرَّر
///    إلى `MultiPage` فيتقسّم على الصفحات بلا أي رأس ثانٍ في وسط ورقة.
/// ── The head is drawn once: `TableRow.repeat` stays off and the whole table is handed to
///    `MultiPage`, which splits it across pages without dropping a second head mid-sheet.
/// ── كل خانة `FittedBox(scaleDown)` على سطر واحد: النص يصغُر ليدخل بدل أن يلتفّ، فيبقى
///    السطر مستوياً والارتفاع موحداً — وهو المطلوب حرفياً من «نفس سطر وحجم الخلية».
/// ── Every cell is a one-line `FittedBox(scaleDown)`: text shrinks to fit instead of
///    wrapping, so rows stay level and every cell keeps the same height.
pw.Table pdfReportGrid({
  required List<PdfGridColumn> columns,
  required List<List<String>> rows,
  required double width,
  List<String>? opening,
  List<String>? totals,
  PdfGridPalette palette = const PdfGridPalette(),
  double? fontSize,
}) {
  final geo = PdfGridGeometry.compute(
    columns: columns,
    width: width,
    fontSize: fontSize,
  );

  return pw.Table(
    border: pw.TableBorder.all(color: palette.rule, width: 0.6),
    columnWidths: geo.columnWidths,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: <pw.TableRow>[
      // 1) الرأس — مرة واحدة في أول الجدول لا في أول كل صفحة
      // 1) the head — once at the top of the table, not at the top of every page.
      pw.TableRow(
        children: [
          for (int i = 0; i < columns.length; i++)
            _gridCell(
              columns[i].label,
              columns[i],
              geo: geo,
              palette: palette,
              band: palette.headBand,
              color: palette.headText,
              bold: true,
              header: true,
            ),
        ],
      ),
      // 2) رصيد الفترة السابقة — يلصق بعد أول حركة مباشرة
      // 2) the previous period's balance, glued right before the first movement.
      if (opening != null)
        pw.TableRow(
          children: [
            for (int i = 0; i < columns.length; i++)
              _gridCell(
                _cellAt(opening, i),
                columns[i],
                geo: geo,
                palette: palette,
                band: palette.openingBand,
                color: palette.text,
                bold: true,
              ),
          ],
        ),
      // 3) السطور
      // 3) the rows.
      for (final row in rows)
        pw.TableRow(
          children: [
            for (int i = 0; i < columns.length; i++)
              _gridCell(
                _cellAt(row, i),
                columns[i],
                geo: geo,
                palette: palette,
                color: _figureColor(_cellAt(row, i), columns[i], palette),
                bold: _isNegative(_cellAt(row, i), columns[i]),
              ),
          ],
        ),
      // 4) سطر المجاميع داخل الجدول نفسه — لا جدولاً ثانياً يعرض أعمدة مختلفة
      // 4) the totals row inside the same table — never a second table with its own widths.
      if (totals != null)
        pw.TableRow(
          children: [
            for (int i = 0; i < columns.length; i++)
              _gridCell(
                _cellAt(totals, i),
                columns[i],
                geo: geo,
                palette: palette,
                band: palette.totalsBand,
                color: palette.totalsText,
                bold: true,
              ),
          ],
        ),
    ],
  );
}

/// خانة واحدة: ارتفاع ثابت، حشو أفقي، وسطر واحد يتقلّص عند الضيق
/// One cell: a fixed height, horizontal padding, and a single line that shrinks when tight.
pw.Widget _gridCell(
  String text,
  PdfGridColumn column, {
  required PdfGridGeometry geo,
  required PdfGridPalette palette,
  required bool bold,
  PdfColor? band,
  PdfColor? color,
  bool header = false,
}) {
  final value = text.trim();
  final align = _gridAlign(column, header: header);

  return pw.Container(
    // الارتفاع ثابت حتى في الخانة الفارغة: صف بلا نص لا يقلّ عن إخوته
    // The height holds even in an empty cell: a textless row is never shorter than its brothers.
    height: geo.rowHeight,
    color: band,
    padding: pw.EdgeInsets.symmetric(horizontal: geo.padding),
    // والخانة الفارغة تُترك بلا `FittedBox`: طفل بحجم صفر يجعل نسبته قسمة على صفر،
    // فينهار المستند بـ«NaN» في مصفوفة التحويل عند الحفظ لا عند الرسم
    // An empty cell skips `FittedBox`: a zero-sized child turns its aspect ratio into a
    // division by zero, and the document dies on a NaN in the transform matrix at save time.
    child: value.isEmpty
        ? pw.SizedBox.shrink()
        : pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: align,
            child: pw.Text(
              pdfArabic(value),
              maxLines: 1,
              softWrap: false,
              // الأرقام يسار→يمين حتى لا تُقلب الإشارة، والعربية مُشكَّلة مسبقاً فلا
              // يحتاج المحرك إعادة ترتيب
              // Figures read left-to-right so a minus never flips; the Arabic is already
              // shaped, so the engine must not re-order it.
              textDirection: kPdfShapedTextDirection,
              style: pw.TextStyle(
                fontSize: geo.fontSize,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color ?? palette.text,
                height: 1.15,
              ),
            ),
          ),
  );
}

/// محاذاة الخانة: النصوص لأول السطر، والأرقام لآخره، ورأس العمود الرقمي في الوسط —
/// وهي محاذاة مطلقة (يمين/يسار) لأن النص المُشكَّل يُرسم اتجاهاً ltr.
/// Cell alignment: text at the reading edge, figures at the line's end, and a numeric
/// heading in the middle — absolute (left/right) because pre-shaped text is painted ltr.
pw.Alignment _gridAlign(PdfGridColumn column, {required bool header}) {
  if (!column.numeric) return pw.Alignment.centerRight;

  return header ? pw.Alignment.center : pw.Alignment.centerLeft;
}

bool _isNegative(String text, PdfGridColumn column) =>
    column.numeric && text.trim().startsWith('-');

PdfColor _figureColor(
  String text,
  PdfGridColumn column,
  PdfGridPalette palette,
) => _isNegative(text, column) ? palette.negative : palette.text;

/// قيمة آمنة لفهرس خارج النطاق: صف أقصر من رأسه لا يفجّر الطباعة
/// Bounds-safe lookup: a row shorter than the head never crashes the print.
String _cellAt(List<String> cells, int index) =>
    index < cells.length ? cells[index] : '';

// ─── شريط الإحصاءات / The statistics strip ─────────────────────────────────────

/// خانة إحصاء واحدة — عنوان دلالي وقيمة وحقل لوني
/// One statistics field: a caption, its value and a semantic colour name.
class PdfStatBox {
  const PdfStatBox(
    this.label,
    this.value, {
    this.tone = 'neutral',
    this.emphasis = false,
  });

  final String label;
  final String value;

  /// 'success' · 'error' · 'primary' · 'neutral' — نفس أسماء الشاشة
  /// The screen's own tone names.
  final String tone;

  /// الرقم النهائي يُبرز
  /// Final figures get emphasis.
  final bool emphasis;
}

/// شريط إحصاءات المطبوع — نفس خانات الشاشة: إطار بلون أساسي فاتر وعناوين باهتة
/// The printout's statistics strip — the screen's very chips: a pale primary frame with
/// faint captions and prominent values.
///
/// ── كان المطبوع سطر نص واحد بصياغة مختلفة («صادر» بدل «المنصرف»): ورقة لا تطابق
///    الشاشة في اللفظ لا تُوثَق منها الأرقام.
/// ── The printout used to be one sentence worded differently («صادر» where the screen
///    reads «المنصرف»); a sheet that disagrees with the screen in wording makes its own
///    figures untrustworthy.
pw.Widget pdfStatsStrip({
  required String title,
  required List<PdfStatBox> fields,
  bool compact = false,
  PdfGridPalette palette = const PdfGridPalette(),
}) {
  if (fields.isEmpty) return pw.SizedBox.shrink();

  return pw.Container(
    padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: compact ? 1.5 : 3),
    decoration: pw.BoxDecoration(
      color: palette.statsBand,
      border: pw.Border.all(color: palette.rule, width: 0.6),
      borderRadius: pw.BorderRadius.circular(compact ? 2 : 4),
    ),
    child: pw.Wrap(
      // العنوان أولاً حيث تبدأ القراءة العربية
      // The caption first, where Arabic reading begins.
      children: [
        if (title.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5, bottom: 1),
            child: pw.Text(
              pdfArabic(title),
              textDirection: kPdfShapedTextDirection,
              style: pw.TextStyle(
                fontSize: compact ? 6 : 6.5,
                fontWeight: pw.FontWeight.bold,
                color: palette.headText,
              ),
            ),
          ),
        for (final field in fields)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: compact
                ? _statInline(field, palette)
                : _statChip(field, palette),
          ),
      ],
    ),
  );
}

/// رقم داخل السطر المختصر: عنوان باهت ثم قيمة بارزة — بلا إطار ولا حشو
/// A figure in the compact line: a faint caption then a prominent value — no frame.
pw.Widget _statInline(PdfStatBox field, PdfGridPalette palette) {
  // الصف داخل صفحة rtl: أول عنصر يُرسم أقصى اليمين، فيقرأ العنوان قبل قيمته كما على الشاشة
  // A row on an rtl page draws its first child at the far right, so the caption reads
  // before its value exactly as the screen does.
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        pdfArabic(field.label),
        textDirection: kPdfShapedTextDirection,
        style: const pw.TextStyle(
          fontSize: 5.5,
          color: PdfColors.grey600,
        ),
      ),
      pw.SizedBox(width: 2),
      pw.Text(
        pdfArabic(field.value),
        textDirection: kPdfShapedTextDirection,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: palette.tone(field.tone),
        ),
      ),
    ],
  );
}

/// خانة إحصاء: عنوان باهت ثم قيمة بارزة داخل إطار أبيض رفيع
/// A statistics chip: a faint caption then a prominent value inside a thin white frame.
pw.Widget _statChip(PdfStatBox field, PdfGridPalette palette) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: palette.rule, width: 0.5),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    // rtl: العنوان أولاً في أقصى اليمين ثم القيمة إلى يساره — نفس قراءة الشاشة
    // RTL: the caption is the rightmost child and the value follows to its left — the
    // screen's very reading order.
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          pdfArabic(field.label),
          textDirection: kPdfShapedTextDirection,
          // لا const: `pw.FontWeight` ليس ثابت ترجمة في هذه النسخة من الحزمة
          // No const: `pw.FontWeight` is not a compile-time constant in this pdf version.
          style: pw.TextStyle(
            fontSize: 6,
            fontWeight: pw.FontWeight.normal,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(width: 2),
        pw.Text(
          pdfArabic(field.value),
          textDirection: kPdfShapedTextDirection,
          style: pw.TextStyle(
            fontSize: field.emphasis ? 8 : 7.5,
            fontWeight: pw.FontWeight.bold,
            color: palette.tone(field.tone),
          ),
        ),
      ],
    ),
  );
}

// ─── عرض محتوى الورقة / The sheet's content width ───────────────────────────────

/// العرض المتاح للمحتوى بعد هامشي الصفحة: هو المقياس الذي تُحسب عليه عروض الأعمدة،
/// فلا يُحسب العرض على ورقة ويُطبع على أخرى.
/// The width left for content after the page margins — the very measure the column widths
/// are computed from, so nothing is sized on one sheet and printed on another.
double pdfGridContentWidth(PdfPageFormat format, {required double sideMargin}) =>
    math.max(format.width - sideMargin * 2, 100);
