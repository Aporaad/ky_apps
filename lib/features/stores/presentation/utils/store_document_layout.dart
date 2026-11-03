import '../../data/models/order_model.dart';
import '../widgets/store_ui.dart';

/// تعريف نوع المستند — أي الحقول تخص هذا النوع وأيها لا تخصّه أصلاً
/// A document-kind profile — which fields belong to this kind and which do not exist for it.
///
/// ── لماذا تعريف مُعلن لا شروط في الشاشات؟ لأن الأنواع الثلاثة **ليست متطابقة**: التوريد له
///    مورد ورقم مرجع نصي وعملة لكل سطر؛ الصرف له جهة مستلمة ورقم قيد ومتوسط تكلفة؛ التحويل له
///    مخزنان ومسلسلان بلا نوع فاتورة ولا طرف ولا خصم. الشروط المتفرقة تجعل أول تعديل ينسى
///    نوعاً، فتظهر خانة لا معنى لها في مستند — أو يختفي حقل لازم.
/// ── Why a declared profile rather than per-screen conditions? The three kinds are **not**
///    identical: receive has a supplier, a textual reference and a per-line currency; issue has a
///    receiver, an entry no and an average cost; transfer has two stores and two serials with no
///    bill type, no party and no discount. Scattered conditions mean the first edit forgets one
///    kind, and a meaningless box appears on a document — or a required field disappears.
class StoreDocProfile {
  const StoreDocProfile({
    required this.kind,
    required this.title,
    required this.fields,
    this.partyLabel,
    this.partyMetaLabel,
  });

  final StoreOrderKind kind;

  /// عنوان المستند كما يطبعه النظام
  /// The document title as the desktop prints it.
  final String title;

  /// اسم الطرف في هذا النوع («المورد» / «الجهة المستلمة») — null للتحويل
  /// The party label of this kind (supplier / receiver) — null for a transfer.
  final String? partyLabel;

  /// اسم الطرف كما يُكتب في شريط تفاصيل المستند («إسم المورد» / «إسم العميل»)
  /// The party label as written in the document meta strip.
  final String? partyMetaLabel;

  final Map<String, bool> fields;

  bool has(String field) => fields[field] ?? false;

  /// هل للمستند طرف؟
  bool get hasParty => has('party');

  /// هل يُعرض نوع الفاتورة (نقد/آجل)؟
  bool get hasBillType => has('bill_type');

  /// هل يملك رقم مرجع يعرضه؟
  bool get hasReference => has('reference');

  /// هل يُكتب رقم المرجع من التطبيق؟
  bool get referenceWritable => has('reference_writable');

  /// التحويل وحده
  bool get hasTargetStore => has('target_store');
  bool get hasSerials => has('serials');
  bool get hasMovementType => has('movement_type');

  /// الخصم — التحويل بلا خصم
  bool get hasDiscount => has('discount');

  /// متوسط التكلفة في السطور — الصرف والتحويل
  bool get hasLineCost => has('line_cost');

  /// عبوة/قطعة في السطور — التوريد
  bool get hasLinePack => has('line_pack');

  /// هل يملك رأس المستند صفّي عملة؟ (التحويل لا يطبعهما)
  /// Does the header carry the two currency rows? A transfer does not print them.
  bool get hasCurrencyPair => has('currency_pair');

  /// التعريفات الافتراضية — مرآة لجدول `StorePolicy::documents()` في الخادم
  /// The default profiles — a mirror of `StorePolicy::documents()` on the server.
  ///
  /// ── الشاشة لا تنتظر المرجع كي ترسم: المراجع قد تتأخر أو تفشل، والمستند يجب أن يظهر
  ///    بحقوله الصحيحة في كل الحالات. الخادم يبقى الفيصل عند الحفظ.
  /// ── The screen does not wait for the reference endpoint to draw: it may lag or fail, and the
  ///    document must still show its correct fields. The server stays the authority on save.
  static StoreDocProfile of(StoreOrderKind kind) => _defaults[kind]!;

  static const Map<StoreOrderKind, StoreDocProfile> _defaults = {
    StoreOrderKind.receive: StoreDocProfile(
      kind: StoreOrderKind.receive,
      title: 'فاتورة توريد مخزني',
      partyLabel: 'المورد',
      partyMetaLabel: 'إسم المورد',
      fields: {
        'bill_type': true,
        'reference': true,
        'reference_writable': true,
        'party': true,
        'entry_no': true,
        'discount': true,
        'currency_pair': true,
        'line_currency': true,
        'line_pack': true,
      },
    ),
    StoreOrderKind.issue: StoreDocProfile(
      kind: StoreOrderKind.issue,
      title: 'منصرف مخزني',
      partyLabel: 'الجهة المستلمة',
      partyMetaLabel: 'إسم العميل',
      fields: {
        'bill_type': true,
        'reference': true,
        'party': true,
        'entry_no': true,
        'discount': true,
        'currency_pair': true,
        'line_cost': true,
        'line_available': true,
      },
    ),
    StoreOrderKind.transfer: StoreDocProfile(
      kind: StoreOrderKind.transfer,
      title: 'تحويل مخزني',
      fields: {
        'reference': true,
        'target_store': true,
        'serials': true,
        'movement_type': true,
        'entry_no': true,
        'line_cost': true,
        'line_available': true,
      },
    ),
  };
}

/// تخطيط مستند المخازن — مصدر واحد للأعمدة تقرأ منه الشاشة و PDF معاً
/// The stock-document layout — one column definition read by both the screen and the PDF.
///
/// ── لماذا ملف مستقل؟ لأن شرط هذا العمل هو المطابقة التامة بين ما يُرى وما يُطبع: شاشة تعرض
///    «الإجمالي» في موضع وتطبعه في آخر، أو ترسل «الكمية» قبل «السعر» وتطبعها بعده، تجعل المستخدم
///    يشك في الرقمين معاً ويعيد العدّ يدوياً. قائمة واحدة مشتركة تجعل الانحراف مستحيل بالبناء،
///    لا بالانتباه.
/// ── Why a separate file? Because exact screen↔print parity is the requirement here: a screen
///    that shows the total in one place and prints it elsewhere, or orders quantity before price
///    on one and after on the other, makes the user distrust both figures and recount by hand.
///    One shared list makes drift impossible by construction rather than by attention.
class StoreDocColumn {
  const StoreDocColumn({
    required this.title,
    required this.weight,
    required this.value,
    this.minWidth = 54,
    this.numeric = false,
    this.wrap = false,
  });

  final String title;

  /// النسبة في توزيع العرض — نفس النسبة على الشاشة وفي PDF
  /// The share of the width, identical on screen and in the PDF.
  final double weight;

  /// كيف تُقرأ قيمة هذا العمود من السطر
  /// How this column's value is read off a line.
  final String Function(StoreOrderLineModel line) value;

  /// الحد الأدنى بالبكسل حتى لا يُسحق «إسم الصنف» تحت أي عرض
  /// Minimum width in px so the item name is never crushed at any width.
  final double minWidth;

  /// الأرقام تُحاذى طرفاً ثابتاً لتبقى قابلة للمقارنة عمودياً
  /// Figures keep one alignment so columns of numbers stay comparable.
  final bool numeric;

  /// هل يلتف النص على أكثر من سطر بدل بتره بنقاط؟
  /// Does the text wrap over several lines instead of being clipped with an ellipsis?
  ///
  /// ── يُستعمل لعمود «إسم الصنف» وحده: الاسم الطويل المبتور يجعل المراجع يفتح الصنف في
  ///    شاشة أخرى ليعرف أي سلعة يقرأ، فينفقد الغرض من الورقة. الالتفاف يُطيل الصف قليلاً
  ///    ويُظهر الاسم كاملاً دون توسيع الجدول أو إخفاء أي عمود آخر.
  /// ── Used by the item-name column alone: a truncated name forces the reviewer to open the
  ///    item elsewhere to know which good they are reading. Wrapping shows the full name
  ///    without widening the table or hiding another column.
  final bool wrap;
}

/// أعمدة سطور المستند — مجموعة واحدة مشتركة، والتحويل يزيد عليها عموداً واحداً
/// The document line columns — one shared set, and a transfer adds exactly one column.
///
/// ── التسعة التي يراها المراجع في كل مستند: رقم الصنف · إسمه · اللون · الوحدة · الكمية ·
///    عبوة · قطعة · سعر الصنف · الإجمالي. وقد أُسقطت أعمدة المقاسات والتصنيف ورقم الصنف
///    الفرعي ورقم الرف لأنها لا تُسأل عند المراجعة وتُضيّق الجدول حتى يلزم تمرير جانبي.
/// ── The nine a reviewer reads on every document: item no · name · colour · unit · qty ·
///    pack · pieces · price · total. Sizes, classification, sub-item no and shelf were dropped:
///    they are not what a review asks, and they narrowed the table until it needed side-scrolling.
///
/// ── والتحويل وحده يزيد **متوسط التكلفة**: هو السؤال الذي يخص نقل قيمة بين مخزنين،
///    ولا معنى له في توريد أو صرف.
/// ── A transfer alone adds **average cost**: the question a value moving between two warehouses
///    raises, and one that means nothing on a receive or an issue.
List<StoreDocColumn> storeDocumentColumns(StoreOrderKind kind) {
  return [
    _code(),
    _name(),
    _colour(),
    _unit(),
    _qty(),
    _pack(),
    _pieces(),
    _price(),
    _lineTotal(),
    // ── التحويل وحده يُظهر متوسط التكلفة: هو سؤال المراجع على نقل بين مخزنين
    //    («بكم انتقلت البضاعة؟»)، ولا معنى له في توريد أو صرف.
    // ── A transfer alone shows the average cost: the question a movement between two
    //    warehouses raises ("at what cost did it move?"). Receive/issue carry no such column.
    if (kind == StoreOrderKind.transfer) _avgCost(),
  ];
}

// ── الأعمدة المشتركة / shared columns ───────────────────────────────────────

StoreDocColumn _code() => StoreDocColumn(
  title: 'رقم الصنف',
  weight: 1.0,
  value: (l) => l.partNo ?? '—',
  minWidth: 56,
);

StoreDocColumn _name() => StoreDocColumn(
  title: 'إسم الصنف',
  weight: 2.6,
  value: (l) => l.displayName,
  minWidth: 120,
  wrap: true,
);

StoreDocColumn _colour() => StoreDocColumn(
  title: 'اللون',
  weight: 0.9,
  value: (l) => l.colorName ?? '—',
  minWidth: 46,
);

StoreDocColumn _unit() => StoreDocColumn(
  title: 'الوحدة',
  weight: 0.7,
  value: (l) => l.unitName ?? '—',
  minWidth: 38,
);

StoreDocColumn _qty() => StoreDocColumn(
  title: 'الكمية',
  weight: 0.8,
  value: (l) => StoreFormat.qty(l.qty),
  numeric: true,
  minWidth: 44,
);

/// عبوة وقطعة — عمودان في **كل** الأنواع الثلاثة
/// Pack and pieces — two columns on **all** three kinds.
///
/// ── العبوة حجم الوحدة (كم قطعة فيها) والقطعة العدد الفعلي؛ المستخدم يورد بعبوات
///    ويصرف بقطع، فيحتاجهما معاً في كل مستند ليقرأ الحركة كما حدثت.
/// ── Pack is the unit size, pieces the actual count; goods arrive by the pack and leave by
///    the piece, so both belong on every document.
StoreDocColumn _pack() => StoreDocColumn(
  title: 'عبوة',
  weight: 0.65,
  value: (l) => StoreFormat.qty(l.cap),
  numeric: true,
  minWidth: 36,
);

StoreDocColumn _pieces() => StoreDocColumn(
  title: 'قطعة',
  weight: 0.7,
  value: (l) => StoreFormat.qty(l.pcs),
  numeric: true,
  minWidth: 38,
);

StoreDocColumn _price() => StoreDocColumn(
  title: 'سعر الصنف',
  weight: 1.05,
  value: (l) => StoreFormat.money(l.price),
  numeric: true,
  minWidth: 58,
);

StoreDocColumn _lineTotal() => StoreDocColumn(
  title: 'الإجمالي',
  weight: 1.15,
  value: (l) => StoreFormat.money(l.total),
  numeric: true,
  minWidth: 64,
);

/// متوسط التكلفة المخزّن في السطر — هو ما يقارن به المراجع تكلفة الصنف الجارية
/// The stored average cost — what a reviewer compares a line against.
StoreDocColumn _avgCost() => StoreDocColumn(
  title: 'متوسط التكلفة',
  weight: 1.0,
  value: (l) => StoreFormat.money(l.stkCost > 0 ? l.stkCost : l.price),
  numeric: true,
  minWidth: 62,
);

/// شريط تفاصيل المستند — صف واحد من (اسم · قيمة) يقرأه الشاشة و PDF معاً
/// The document meta strip — a single row of (label · value) read by screen and PDF alike.
///
/// ── لماذا دالة مشتركة؟ لأن الشاشة والمطبوع كانا يجمعان الخانات بتسلسلين مستقلين، فأول
///    تعديل على أحدهما يُنتج مستنداً يختلف عن طبعته. مصدر واحد يجعل الانحراف مستحيلاً.
/// ── Why one shared function? Screen and print used to assemble the boxes in two independent
///    sequences, so the first edit to one produced a document that disagreed with its printout.
///    A single source makes that drift impossible.
///
/// ── الحقول المطلوبة لكل نوع، ورقم الفاتورة **ليس منها**: يُكتب تحت العنوان مرة واحدة
///    فلا يتكرر رقم المستند في مكانين.
/// ── The fields each kind requires; the invoice number is **not** among them — it is written
///    once under the title, so the document number never appears twice.
List<(String, String)> storeDocumentMeta(
  StoreOrderKind kind,
  StoreOrderModel header,
) {
  final profile = StoreDocProfile.of(kind);
  final party = profile.partyMetaLabel ?? 'الطرف';

  return [
    ('تاريخ الفاتورة', header.dateLabel),
    if (profile.hasBillType) ('نوع الفاتورة', header.billTypeLabel),
    if (profile.hasTargetStore) ...[
      ('من مخزن', header.storeName ?? '—'),
      ('إلى مخزن', header.storeToName ?? '—'),
      // المسلسلان: المنصرف من المخزن المرسل والوارد فيه
      // The two serials: the one leaving the source store and the one entering it.
      ('رقم الصرف', header.trInvMId > 0 ? '${header.trInvMId}' : '—'),
      ('رقم التوريد', header.inboundId > 0 ? '${header.inboundId}' : '—'),
      ('حساب المخزون', header.accName ?? '—'),
    ] else ...[
      ('إسم المخزن', header.storeName ?? '${header.storeNo}'),
      (party, header.partyName ?? '—'),
      ('العملة', header.curName ?? 'يمني'),
    ],
    ('العدد', '${header.sanfNums}'),
  ];
}

/// مبلغ الخصم مع نسبته إن وُجدت — صياغة واحدة على الشاشة وفي المطبوع
/// The discount amount with its rate when present — one wording on screen and in print.
String storeDiscountText(StoreOrderModel header) {
  final amount = StoreFormat.money(header.discount);

  if (header.discountRate <= 0) return amount;

  return '$amount  (${StoreFormat.qty(header.discountRate)}%)';
}

/// عرض الجدول الأدنى الذي لا ينزل أي عمود فيه تحت حدّه
/// The minimum table width at which no column falls under its own floor.
///
/// العمود ذو النسبة w يأخذ `width × w / ΣW`، فيجب `width ≥ minWidth × ΣW / w` لكل عمود.
/// A column of weight w receives `width × w / ΣW`, so `width ≥ minWidth × ΣW / w` for every one.
double storeDocumentMinWidth(List<StoreDocColumn> columns) {
  final totalWeight = columns.fold<double>(
    0,
    (sum, column) => sum + column.weight,
  );

  var required = 0.0;

  for (final column in columns) {
    final needed = column.minWidth * totalWeight / column.weight;

    if (needed > required) required = needed;
  }

  return required;
}
