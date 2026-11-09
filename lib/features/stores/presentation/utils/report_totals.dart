import '../../data/models/report_model.dart';
import '../../data/repositories/store_result.dart';
import '../widgets/store_ui.dart';

/// سطر التجميع في نهاية الجدول — مجاميع الأعمدة الكمية والمالية فقط
/// The totals row at the end of the table — only the quantity and money columns are summed.
///
/// ── لماذا لا تُجمع كل الأعمدة الرقمية؟ لأن عمودين لا مجموع لهما معنى: التكلفة سعر وحدة،
///    جمعها يقول رقماً لا يمثّل شيئاً، والرصيد الجاري رقم متراكم، جمعه يضاعف كل حركة
///    سبق أن احتُسبت فيه.
/// ── Not every numeric column adds up: cost is a unit price, so its sum stands for nothing,
///    and the running balance already contains every earlier movement, so summing it would
///    count the same stock again and again. A wrong total is worse than no total.
class ReportTotals {
  ReportTotals._();

  /// مجاميع سطور الحركة — بمعرّفات الأعمدة كي يقرأها الجدول والـ PDF والـ Excel معاً
  /// Movement row totals, keyed by column id so the table, the PDF and Excel all read it.
  static Map<String, String> movement(List<StockMovementRow> rows) {
    double sum(double Function(StockMovementRow row) of) {
      var total = 0.0;

      for (final row in rows) {
        total += of(row);
      }

      return total;
    }

    return {
      'no': '${rows.length}',
      'in': StoreFormat.qty(sum((row) => row.qtyIn)),
      'out': StoreFormat.qty(sum((row) => row.qtyOut)),
      'qty': StoreFormat.qty(sum((row) => row.netQty)),
      'net': StoreFormat.qty(sum((row) => row.netQty)),
      'value': StoreFormat.money(sum((row) => row.lineValue)),
    };
  }

  /// رصيد الفترة السابق — صف يسبق أول حركة في كل جدول وفي كل قسم
  /// The period's opening balance — a row ahead of the first movement in every table and section.
  ///
  /// ── لماذا في عمود `balance`؟ لأن هذا هو العمود الذي يبدأ منه التراكم: أول رقم فيه هو
  ///    الافتتاح، وكل رقم بعده افتتاح + ما تحرّك حتى ذلك السطر. وضعه في عمود آخر يقطع التسلسل.
  /// ── Why the `balance` column? It is the column the run accumulates in: its first figure is
  ///    the opening and every figure after it is the opening plus what moved so far. Any other
  ///    column would break that sequence.
  static Map<String, String> opening(ReportStats stats) {
    return {
      'balance': StoreFormat.qty(stats.openingQty),
      // قيمة الرصيد السابق تظهر حين توجد فعلاً: صفرها ضجيج في سطر واحد
      // The opening value appears only when it exists: a zero there is one line of noise.
      if (stats.openingValue != 0)
        'balanceValue': StoreFormat.money(stats.openingValue),
    };
  }

  /// مجاميع سطور الخلاصة — كل صنف سطر مستقل فرصيد كل الأصناف مجموع صحيح
  /// Summary row totals: each row is a distinct item, so summing balances is meaningful here.
  static Map<String, String> summary(List<StockSummaryRow> rows) {
    double sum(double Function(StockSummaryRow row) of) {
      var total = 0.0;

      for (final row in rows) {
        total += of(row);
      }

      return total;
    }

    return {
      'no': '${rows.length}',
      'opening': StoreFormat.qty(sum((row) => row.openingQty)),
      'in': StoreFormat.qty(sum((row) => row.qtyIn)),
      'out': StoreFormat.qty(sum((row) => row.qtyOut)),
      'net': StoreFormat.qty(sum((row) => row.netQty)),
      'balance': StoreFormat.qty(sum((row) => row.closingQty)),
      'inValue': StoreFormat.money(sum((row) => row.inValue)),
      'outValue': StoreFormat.money(sum((row) => row.outValue)),
      'value': StoreFormat.money(sum((row) => row.netValue)),
      'balanceValue': StoreFormat.money(sum((row) => row.netValue)),
      'lines': '${rows.fold<int>(0, (total, row) => total + row.rowsCount)}',
    };
  }
}

/// حقل إحصائي واحد جاهز للرسم — معرّف ثابت وعنوان مختصر وقيمة ولون
/// One ready-to-draw statistics field — a stable id, a short caption, a value and a colour.
class ReportStatField {
  const ReportStatField(
    this.id,
    this.label,
    this.value,
    this.color, {
    this.emphasis = false,
  });

  final String id;
  final String label;
  final String value;

  /// ألوان الدلالة بأسماء لا بكائنات: هذا الملف مجرّد من Flutter فلا يستورد سمة التطبيق
  /// Semantic colours by name rather than by object: this file stays Flutter-free.
  final String color;

  /// الأرقام النهائية تُبرز والسائرها يبقى في مستواه
  /// Final figures get emphasis; the rest keeps their normal weight.
  final bool emphasis;

  /// هل يحمل هذا الحقل رقماً يستحق العرض أصلاً
  /// Whether this field carries a figure worth drawing at all.
  bool get isEmpty => value.trim().isEmpty;
}

/// حقول الإحصاءات: عناوينها المختصرة وبناؤها من إحصاء الخادم
/// The statistics fields: their compact captions and their build from the server's stats.
///
/// ── المعرّف ثابت ومشترك بين الشاشة ونافذة الأعمدة والمطبوع: إخفاء حقل في الواجهة ثم
///    رؤيته في الـ PDF خطأ في الثقة لا في التنسيق.
/// ── One stable id shared by the screen, the columns sheet and the printout: hiding a field
///    on screen and still seeing it in the PDF breaks trust, not layout.
class ReportStatFields {
  ReportStatFields._();

  /// العناوين المختصرة بترتيبها الثابت — «السابق» و«الرصيد الحالي» لا «الرصيد السابق كمية»
  /// The compact captions in their fixed order: short enough to sit in one tidy strip.
  static const List<(String, String)> labels = <(String, String)>[
    ('rows', 'السطور'),
    ('opening', 'السابق'),
    ('in', 'وارد'),
    ('inValue', 'قيمة الوارد'),
    ('out', 'منصرف'),
    ('outValue', 'قيمة المنصرف'),
    ('net', 'الصافي'),
    ('closing', 'الرصيد الحالي'),
    ('closingValue', 'قيمة الرصيد'),
  ];

  /// معرّفات تقرير الحركة والخلاصة — كلها متاحة، لكن الظاهر منها افتراضياً خمسة فقط
  /// The movement/summary ids — all of them are available, yet only five show by default.
  static const List<String> allIds = <String>[
    'rows',
    'opening',
    'in',
    'inValue',
    'out',
    'outValue',
    'net',
    'closing',
    'closingValue',
  ];

  /// الحقول الظاهرة افتراضياً — الخمسة التي يقرأها أمين المخزن في كل تقرير
  /// The fields shown by default — the five a storekeeper reads on every report.
  ///
  /// ── لماذا خمسة لا تسعة؟ لأن قيم الوارد والمنصرف والرصيد وعدد السطور إضافات: تقرير
  ///    يُفتح على تسعة أرقام لا يُقرأ في نظرة، والقارئ يريد أولاً «من أين بدأ، وكم دخل
  ///    وخرج، وما صافيه، وأين انتهى». والبقية تبقى متاحة في «تخصيص» فتُظهر عند الحاجة.
  /// ── Why five rather than nine? Inbound value, outbound value, the closing value and the
  ///    line count are extras: a report that opens on nine figures cannot be read at a glance,
  ///    and the reader first wants "where it started, what came in and out, its net, where it
  ///    ended". The rest stay available under "customise" and appear when they are asked for.
  static const List<String> defaultIds = <String>[
    'opening',
    'in',
    'out',    
    'closing',
  ];

  /// عناوين كشف حركة صنف واحد: لا رصيد سابق فيه ولا رصيد جالٍ، فحقول الخلاصة لا تخصّه
  /// A single item's statement has no opening and no closing, so the summary fields do not fit it.
  static const List<(String, String)> statementLabels = <(String, String)>[
    ('rows', 'السطور'),
    ('in', 'وارد'),
    ('out', 'منصرف'),
    ('net', 'الصافي'),
    ('value', 'القيمة'),
  ];

  static const List<String> statementIds = <String>[
    'rows',
    'in',
    'out',
    'net',
    'value',
  ];

  /// حقول التقرير من إحصاء الخادم — والقيمة الصفرية لا تُعرض إلا إذا كانت رقماً مطلوباً
  /// The report's fields from the server stats; a zero value is dropped unless it is a
  /// quantity the report always carries.
  static List<ReportStatField> of(ReportStats stats) {
    final values = _figures(stats);

    return [
      for (final (id, label) in labels)
        if (values[id] != null)
          ReportStatField(
            id,
            label,
            values[id]!.$1,
            values[id]!.$2,
            emphasis: values[id]!.$3,
          ),
    ];
  }

  /// الأرقام من إحصاء واحد — مصدر واحد للتقرير وللقسم فلا يفترق رقمان متطابقان
  /// The figures from one set of statistics — one source for the report and the section, so
  /// two identical figures can never diverge.
  static Map<String, (String, String, bool)> _figures(ReportStats stats) {
    return <String, (String, String, bool)>{
      'rows': ('${stats.rows}', 'neutral', false),
      'opening': (StoreFormat.qty(stats.openingQty), 'neutral', false),
      'in': (StoreFormat.qty(stats.qtyIn), 'success', false),
      'inValue': (StoreFormat.money(stats.qtyInValue), 'success', false),
      'out': (StoreFormat.qty(stats.qtyOut), 'error', false),
      'outValue': (StoreFormat.money(stats.qtyOutValue), 'error', false),
      'net': (StoreFormat.qty(stats.netQty), 'neutral', false),
      'closing': (StoreFormat.qty(stats.closingQty), 'primary', true),
      // قيمة الرصيد تظهر حين يوجد رصيد قيمة فعلاً: صفرها ضجيج في شريط مختصر
      // The closing value appears only when a value balance exists: a zero is strip noise.
      if (stats.closingValue != 0)
        'closingValue': (StoreFormat.money(stats.closingValue), 'primary', true),
    };
  }

  /// حقول كشف حركة صنف — من مجاميع الخادم للكشف نفسه
  /// An item statement's fields, from the statement's own server totals.
  static List<ReportStatField> statement(MovementStatement data) {
    final values = <String, (String, String, bool)>{
      'rows': ('${data.lines}', 'neutral', false),
      'in': (StoreFormat.qty(data.qtyIn), 'success', false),
      'out': (StoreFormat.qty(data.qtyOut), 'error', false),
      'net': (StoreFormat.qty(data.netQty), 'neutral', false),
      'value': (StoreFormat.money(data.value), 'primary', true),
    };

    return [
      for (final (id, label) in statementLabels)
        if (values[id] != null)
          ReportStatField(
            id,
            label,
            values[id]!.$1,
            values[id]!.$2,
            emphasis: values[id]!.$3,
          ),
    ];
  }

  /// حقول إحصاء القسم المختصر — أربعة أرقام فقط في سطر واحد
  /// The compact section statistics — exactly four figures on one line.
  ///
  /// ── إحصاء القسم ليس نسخة مصغّرة من إحصاء التقرير: التقرير يُسأل عنه «كم دخل وكم خرج
  ///    وما قيمته»، أما القسم فيُسأل سؤالاً واحداً: «من أين بدأ وأين انتهى، وكم تحرّك بينهما».
  ///    لذلك تُعرض هذه الأربعة وحدها، ويسقط «السطور» و«الصافي» وقيم الوارد والمنصرف.
  /// ── A section's statistics are not a shrunk copy of the report's: the report answers "how
  ///    much came in, how much left, what is it worth", while a section answers one question —
  ///    "where did it start, where did it end, how much moved in between". So only these four
  ///    are drawn, and "rows", "net" and the inbound/outbound values drop out.
  static const List<String> sectionIds = <String>[
    'opening',
    'in',
    'out',
    'closing',
  ];

  /// إحصاءات القسم المختصرة بالترتيب الثابت: السابق · وارد · منصرف · الرصيد الحالي
  /// The compact section fields in their fixed order: opening · in · out · closing.
  ///
  /// ── ترتيب ثابت لا ترتيب الاختيار: القارئ يقارن قسمين متتاليين بعينه، فاختلاف الترتيب
  ///    بين قسم وقسم يجعله يقرأ «المنصرف» مكان «الوارد».
  /// ── A fixed order, never the selection order: the reader compares two consecutive
  ///    sections at a glance, and a shifting order makes them read outbound as inbound.
  static List<ReportStatField> section(ReportStats stats) {
    final values = _figures(stats);

    return [
      for (final (id, label) in labels)
        if (sectionIds.contains(id) && values[id] != null)
          ReportStatField(
            id,
            label,
            values[id]!.$1,
            values[id]!.$2,
            emphasis: values[id]!.$3,
          ),
    ];
  }

  /// تصفية الحقول بالمعرّفات الظاهرة — `null` تعني «كل الحقول»
  /// Filter the fields by the visible ids — null means "every field".
  static List<ReportStatField> visible(
    List<ReportStatField> fields,
    List<String>? ids,
  ) {
    if (ids == null) return fields;

    return [
      for (final field in fields)
        if (ids.contains(field.id)) field,
    ];
  }
}
