import '../../data/models/report_model.dart';
import '../../data/models/store_reference.dart';

/// وصف معطيات التقرير
/// One described parameter of a report.
class ReportParameter {
  const ReportParameter(this.label, this.value, {this.isActive = true});

  final String label;
  final String value;

  /// القيد غير الفعّال (كأنواع الحركة في الخلاصة) يُعرض ولا يُحسب قيداً
  /// An inert parameter (movement types inside a summary) is shown but is not a constraint.
  final bool isActive;
}

/// عنوان التقرير الرسمي الموحّد
/// The single official report title.
///
/// ── لماذا عنوان واحد مركّب لا جدول معطيات؟ لأن مستنداً موقّعاً يُقرأ وحده يجب أن يقول
///    «ماذا» في سطر واحد: «كشف حركة صنف فرعي : اسم الفرع». تكرار كل قيد في كتلة قبل الجدول
///    كان يزيح الجدول عن الشاشة ويحوّل المستند إلى نموذج إدخال.
/// ── Why one composed title instead of a parameters table? A signed document must be readable
///    on its own and say "what" in a single line: `a branch movement statement : <branch>`.
///    Repeating every constraint in a block before the table pushed the table off the screen
///    and turned the document back into an input form.
///
/// ── البُعد الأضيق هو العنوان: الفرع ثم الصنف ثم المجموعة الفرعية ثم الرئيسية؛ وهو منطق
///    ترشيح المستخدم نفسه، لا ترتيب مصطنع.
/// ── The narrowest dimension is the title: branch, then item, then sub group, then group —
///    the user's own narrowing order, not an invented one.
class ReportTitle {
  const ReportTitle({
    required this.headline,
    this.period,
    this.stores,
  });

  /// السطر الأول: «كشف حركة صنف فرعي : كذا»
  /// The first line.
  final String headline;

  /// الفترة — تظهر فقط حين خصّصها المستخدم
  /// The period — only when the user customised it.
  final String? period;

  /// «من مخزن: …» — يظهر فقط حين خصّص المخازن
  /// "From store: …" — only when stores were narrowed.
  final String? stores;

  /// سطر كامل لموضع لا يقبل عمودين (رأس PDF المضغوط)
  /// One flat line for places that cannot take two rows.
  String get singleLine => [
    headline,
    if (period != null) period,
    if (stores != null) stores,
  ].whereType<String>().join(' — ');
}

/// بناء عنوان التقرير من معطياته
/// Composing the report title out of its parameters.
class ReportTitles {
  ReportTitles._();

  static ReportTitle of(
    StoreReportFilter filter, {
    StoreReference? reference,
  }) {
    final verb = filter.kind == StoreReportKind.movement
        ? 'كشف حركة'
        : 'خلاصة حركة';

    // الأضيق أولاً: الفرع هو سؤال المستخدم الحقيقي حين يختاره، ولا شيء أعلَى منه
    // Narrowest first: when a branch is chosen that is the user's real question.
    final subject = _subject(filter, reference);

    return ReportTitle(
      headline: subject.$2.isEmpty
          ? '$verb ${subject.$1}'
          : '$verb ${subject.$1} : ${subject.$2}',
      period: filter.customPeriod
          ? '${filter.fromText} — ${filter.toText}'
          : null,
      stores: filter.storeNos.isEmpty
          ? null
          : 'من مخزن: ${_join([
              for (final no in filter.storeNos)
                reference?.storeById(no)?.storeName ?? '$no',
              ])}',
    );
  }

  /// عنوان كشف حركة صنف — نفس قاعدة القالب: الفرع إذا كان الكشف مقيَّداً به وإلا الصنف
  /// The item statement's title — the template's own rule: the branch when the statement is
  /// scoped to one, otherwise the item.
  ///
  /// ── لماذا في طبقة الأدوات لا في الشاشة؟ لأن الكشف والتقرير قالب واحد بمسارين، وأي عنوان
  ///    مستقل لكل منهما يعني أن المستند المطبوع يختلف عن الذي على الشاشة.
  /// ── Why here rather than in the screen? A statement and a report are one template reached
  ///    two ways; a separate title for each would make the printed document differ from the
  ///    one on screen.
  static ReportTitle statement({
    required String itemName,
    required String branchLabel,
    required bool branchOnly,
    String? period,
    String? stores,
  }) {
    return ReportTitle(
      headline: branchOnly
          ? 'كشف حركة صنف فرعي : $branchLabel'
          : 'كشف حركة صنف : $itemName',
      period: period,
      stores: stores,
    );
  }

  /// (وصف البُعد، قيمته) — القيمة قد تكون فارغة حين لا تخصيص يضيق العنوان
  /// (the dimension's words, its value) — the value can be empty when nothing narrows it.
  static (String, String) _subject(
    StoreReportFilter filter,
    StoreReference? reference,
  ) {
    if (filter.sanfDno != null) {
      return ('صنف فرعي', filter.sanfDnoLabel ?? '${filter.sanfDno}');
    }

    if (filter.sanfNo != null) {
      return ('صنف', filter.sanfName ?? '${filter.sanfNo}');
    }

    if (filter.itemTypeNos.length == 1) {
      return (
        'مجموعة فرعية',
        reference?.typeById(filter.itemTypeNos.first)?.typeName ??
            '${filter.itemTypeNos.first}',
      );
    }

    if (filter.itemTypeNos.length > 1) {
      return (
        'مجموعات فرعية',
        _join([
          for (final no in filter.itemTypeNos)
            reference?.typeById(no)?.typeName ?? '$no',
        ]),
      );
    }

    if (filter.groupNos.length == 1) {
      return (
        'مجموعة رئيسية',
        reference?.groupById(filter.groupNos.first)?.groupName ??
            '${filter.groupNos.first}',
      );
    }

    if (filter.groupNos.length > 1) {
      return (
        'مجموعات رئيسية',
        _join([
          for (final no in filter.groupNos)
            reference?.groupById(no)?.groupName ?? '$no',
        ]),
      );
    }

    // لا تخصيص أضيق: التقرير لكل المخازن — والاسم يبقى «المخازن» بلا قيمة تتبعه
    // Nothing narrower: the report covers every store, so the word stands with no value.
    return ('المخازن', '');
  }

  static String _join(List<String> values) => values.join('، ');
}

/// نص معطيات التقرير الموحّد — تستخدمه ورقة «المعطيات» في Excel وحدها
/// The unified parameters text — used only by the Excel "parameters" sheet now.
///
/// ── بقيت هنا لأن ملف Excel يُفتح مجرّداً بعد أسبوع بلا ترويسة ولا عنوان مقروء على الشاشة،
///    فمصدر البيانات يحتاج فترة ومخازن وأعمدة مكتوبة نصاً. أما المستند المطبوع فلا يحملها.
/// ── It stays because an Excel file gets opened a week later with no letterhead and no
///    on-screen title: a data source needs its period, stores and columns written out. The
///    printed document carries none of that.
class ReportParameters {
  ReportParameters._();

  /// قيمة «لاشي» كما تُطبع — صريحة لا فراغ قابل للتأويل
  /// How "None" prints: explicit, never a blank open to interpretation.
  static const String unconstrained = 'بلا قيد';

  static List<ReportParameter> of(
    StoreReportFilter filter, {
    StoreReference? reference,
  }) {
    return [
      ReportParameter('نوع التقرير', filter.kind.label),
      ReportParameter(
        'الفترة',
        '${filter.fromText} — ${filter.toText}',
      ),
      ReportParameter(
        'المخازن',
        _names(
          filter.storeNos,
          (id) => reference?.storeById(id)?.storeName ?? '$id',
        ),
      ),
      ReportParameter(
        'المجموعة الرئيسية',
        _names(
          filter.groupNos,
          (id) => reference?.groupById(id)?.groupName ?? '$id',
        ),
      ),
      ReportParameter(
        'المجموعة الفرعية',
        _names(
          filter.itemTypeNos,
          (id) => reference?.typeById(id)?.typeName ?? '$id',
        ),
      ),
      ReportParameter(
        'الفئة',
        filter.catNo == null
            ? unconstrained
            : reference?.categoryById(filter.catNo!)?.name ?? '${filter.catNo}',
      ),
      ReportParameter(
        'الصنف الرئيسي',
        filter.sanfNo == null
            ? unconstrained
            : filter.sanfName ?? '${filter.sanfNo}',
      ),
      ReportParameter(
        'الصنف الفرعي',
        filter.sanfDno == null
            ? unconstrained
            : filter.sanfDnoLabel ?? '${filter.sanfDno}',
      ),
      // أنواع الحركة لا دور لها في الخلاصة: تُعرض معلَّمة لا مقيدة حتى لا يقرأها المحاسب
      // شرطاً وهو ليس كذلك
      // Movement types play no part in a summary: they are printed as inert so an accountant
      // cannot read them as a condition they are not.
      if (filter.usesMovementTypes)
        ReportParameter(
          'أنواع الحركة',
          _names(
            filter.movementTypeNos,
            (id) => reference?.movementTypeById(id)?.typeName ?? '$id',
          ),
        )
      else
        const ReportParameter(
          'أنواع الحركة',
          'غير مطبَّقة في الخلاصة',
          isActive: false,
        ),
      if (filter.usesGroupBy)
        ReportParameter('مستوى التجميع', filter.groupBy.label),
    ];
  }

  static String _names(List<int> ids, String Function(int) nameOf) {
    if (ids.isEmpty) return unconstrained;

    return [
      for (final id in ids) nameOf(id),
    ].join('، ');
  }
}
