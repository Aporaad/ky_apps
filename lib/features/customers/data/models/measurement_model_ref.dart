import '../../../tailoring/data/models/cutting_bill_detail_model.dart';
import '../../../tailoring/data/models/cutting_model_item.dart';
import '../../../tailoring/data/models/tailoring_parse.dart';

/// مفتاح موديل واحد — رباعي لأن أياً من أجزائه لا يُغني عن الباقي
/// One model's key — four parts, because no part implies another.
///
/// رقم الفاتورة وحده غير فريد (نفس الرقم يتكرر عبر السنوات)، والموديل يُعرَّف بـ `SEQ_NO`
/// داخل فاتورة بعينها، وصاحب المقاسات عميلٌ بعينه. الخادم يرفض أي تركيبة لا يملكها هذا
/// العميل بهذه الفاتورة بهذه السنة، فلا يُعرض مقاس شخص باسم شخص آخر.
/// A bill number is not unique (it repeats across years), a model is SEQ_NO inside one bill, and
/// the measurements belong to one customer. The server rejects any combination this customer does
/// not own in that bill and year, so nobody's measurements are ever shown under another name.
class MeasurementKey {
  final int custNo;
  final int billNo;
  final int year;
  final int seqNo;

  const MeasurementKey({
    required this.custNo,
    required this.billNo,
    required this.year,
    required this.seqNo,
  });

  /// شكل ثابت لمقارنة المفاتيح وللمسار على الخادم
  /// A stable shape used to compare keys and to build the server path.
  String get id => '$custNo/$billNo/$year/$seqNo';

  @override
  bool operator ==(Object other) => other is MeasurementKey && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// صف موديل في قائمة العميل — مختصر يوصل إلى شاشة المقاسات
/// One model row of the customer's list — a summary that leads into the measurements screen.
class MeasurementModelRef {
  final int billNo;
  final int year;
  final int seqNo;

  /// المستفيد قد يكون فارغاً (18,846 صفاً من أصل 45,313 بلا مستفيد)، فيُعرض بديلٌ صريح
  /// The beneficiary can be blank (18,846 of 45,313 live rows), so an explicit fallback shows.
  final String? beneficiary;
  final String? typeName;
  final int? shapeStyleNo;
  final int? manualBillNo;
  final int qty;
  final int piecesCount;

  /// أعلام سير الموديل — تُعرض كشارة حالة واحدة لا كثلاثة حقول
  /// The model's workflow flags, shown as one status chip rather than three fields.
  final bool cuttingDone;
  final bool tailorDone;
  final bool handingDone;
  final String? date;
  final DateTime? rawDate;

  const MeasurementModelRef({
    required this.billNo,
    required this.year,
    required this.seqNo,
    this.beneficiary,
    this.typeName,
    this.shapeStyleNo,
    this.manualBillNo,
    this.qty = 0,
    this.piecesCount = 0,
    this.cuttingDone = false,
    this.tailorDone = false,
    this.handingDone = false,
    this.date,
    this.rawDate,
  });

  factory MeasurementModelRef.fromJson(Map<String, dynamic> json) {
    return MeasurementModelRef(
      billNo: tailoringInt(json, 'bill_no') ?? 0,
      year: tailoringInt(json, 'year') ?? 0,
      seqNo: tailoringInt(json, 'seq_no') ?? 0,
      beneficiary: tailoringText(json, 'beneficiary'),
      typeName: tailoringText(json, 'type_name'),
      shapeStyleNo: tailoringInt(json, 'shape_style_no'),
      manualBillNo: tailoringInt(json, 'manual_bill_no'),
      qty: tailoringInt(json, 'qty') ?? 0,
      piecesCount: tailoringInt(json, 'pieces_count') ?? 0,
      cuttingDone: (tailoringInt(json, 'cutting_done') ?? 0) != 0,
      tailorDone: (tailoringInt(json, 'tailor_done') ?? 0) != 0,
      handingDone: (tailoringInt(json, 'handing_done') ?? 0) != 0,
      date: tailoringDisplayDate(json, 'date', rawKey: 'raw_date'),
      rawDate: tailoringDate(json, 'raw_date'),
    );
  }

  /// هوية الفاتورة المركّبة كما تُعرض: «35 / 2023»
  /// The composite bill identity as displayed: "35 / 2023".
  String get billLabel => '$billNo / $year';

  /// مفتاح شاشة التفصيل مع العميل المالك — رقم العميل لا يُشتق من الصف بل من القائمة التي
  /// تُعرض له أصلاً، فلو اشتُقّع لكان صفٌ بلا عميل سببُ عرض مقاسات شخص آخر.
  /// The detail screen's key with its owner: the customer number is never inferred from a row —
  /// it comes from the list already scoped to that customer, so a row alone cannot leak one
  /// person's measurements under another's name.
  MeasurementKey keyOf(int custNo) => MeasurementKey(
    custNo: custNo,
    billNo: billNo,
    year: year,
    seqNo: seqNo,
  );

  /// اسم الموديل: النوع ثم الشكل ثم رقمه — لا خانة فارغة بلا بديل
  /// The model's name: type, then its number — never an empty cell without a fallback.
  String get displayName {
    final named = typeName;

    return (named == null || named.isEmpty) ? 'موديل $seqNo' : named;
  }

  /// مرحلة الموديل من أعلام الإنجاز — التسليم يتجاوز الخياطة والخياطة تتجاوز القص
  /// The model's stage from its flags: delivery outranks tailoring, tailoring outranks cutting.
  String get stageLabel {
    if (handingDone) return 'تم التسليم';
    if (tailorDone) return 'تم الخياطة';
    if (cuttingDone) return 'تم القص';

    return 'بانتظار القص';
  }

  /// هل الموديل مكتمل؟ — تُستخدم للون الشارة لا لنصّها
  /// Is the model complete? Used for the chip's colour, not its text.
  bool get isComplete => handingDone;
}

/// صفحة موديلات العميل / the customer's model page
class MeasurementModelsPage {
  final List<MeasurementModelRef> items;
  final int total;
  final int page;
  final int pages;
  final int limit;

  const MeasurementModelsPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 0,
    this.limit = 30,
  });

  bool get hasMore => page < pages;
}

/// موديل أخو داخل نفس الفاتورة — يُستخدم لتنقّل شريط الفلترة بلا طلب إضافي
/// A sibling model inside the same bill — lets the filter bar move without another request.
class MeasurementSibling {
  final int seqNo;
  final String? beneficiary;
  final String? typeName;
  final int piecesCount;
  final String? date;

  /// أيهما المعروض الآن — الخادم يحدّدها لأن knows the requested key
  /// Which one is on screen: the server marks it, since it knows the requested key.
  final bool selected;

  const MeasurementSibling({
    required this.seqNo,
    this.beneficiary,
    this.typeName,
    this.piecesCount = 0,
    this.date,
    this.selected = false,
  });

  factory MeasurementSibling.fromJson(Map<String, dynamic> json) {
    // العلامة تصل `bool` من JSON لا رقماً: قراءة رقمية بحتة كانت تجعلها `false` دائماً.
    // The flag arrives as a JSON bool, not a number: a purely numeric read would make it always
    // false, silently hiding which model is on screen.
    final flag = tailoringField(json, 'selected');

    return MeasurementSibling(
      seqNo: tailoringInt(json, 'seq_no') ?? 0,
      beneficiary: tailoringText(json, 'beneficiary'),
      typeName: tailoringText(json, 'type_name'),
      piecesCount: tailoringInt(json, 'pieces_count') ?? 0,
      date: tailoringPlainText(json, 'date'),
      selected: flag is bool ? flag : (tailoringInt(json, 'selected') ?? 0) != 0,
    );
  }

  /// تسمية الزر في شريط الفلترة: المستفيد أو النوع أو الرقم
  /// The filter bar's chip label: beneficiary, else type, else the number.
  String get label {
    final named = tailoringJoin([beneficiary, typeName]);

    return named.isEmpty ? 'موديل $seqNo' : named;
  }
}

/// حزمة التفصيل: فاتورة بموديلها المختار + إخوته + رقم العميل المطلوب
/// The detail bundle: a bill with its selected model, its siblings, and the requested customer.
///
/// `detail` نموذج قسم التفصيل نفسه — الخادم يعيد المفاتيح ذاتها عمداً، فتُعاد استخدام
/// بطاقات المقاسات والمواصفات والأقمشة بدل نسخة موازية تنفصل لاحقاً عن الأصل.
/// `detail` is the tailoring feature's own model: the server sends the same keys on purpose so the
/// measurement, spec and fabric cards are reused instead of a parallel copy that would drift.
class MeasurementSubject {
  /// رقم العميل كما طُلب — يُحرس في الواجهة أيضاً عند التنقل بين الإخوة
  /// The customer as requested — also guarded in the UI when moving between siblings.
  final int custNo;

  final CuttingBillDetail detail;
  final List<MeasurementSibling> siblings;

  const MeasurementSubject({
    required this.custNo,
    required this.detail,
    this.siblings = const [],
  });

  factory MeasurementSubject.fromJson(
    Map<String, dynamic> json, {
    required int custNo,
  }) {
    // رقم العميل يُمرَّر من المُستدعي لا من الاستجابة: الطلب هو ما يملكه، والخادم يرفض أي
    // موديل لا يعود لهذا العميل بردّ 404 قبل أن يصل شيء إلى هنا.
    // The customer number comes from the caller, not the payload: the request is what owns it, and
    // the server rejects any model that does not belong to this customer with a 404 before
    // anything reaches here.
    return MeasurementSubject(
      custNo: custNo,
      detail: CuttingBillDetail.fromJson(json),
      siblings: (json['siblings'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => MeasurementSibling.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// الموديل المعروض — القائمة تحمل واحداً، والصفحة تُبني عليه
  /// The shown model: the list carries exactly one, and the screen is built on it.
  CuttingModelItem? get model => detail.firstModel;

  /// هل إخوة الموديل متعددون؟ — وحدها تفتح منتقي المستفيد في شريط الفلترة
  /// Are there sibling models? Only then does the filter bar offer the beneficiary picker.
  bool get hasSiblings => siblings.length > 1;

  /// مفتاح الإخوة بنفس العميل المطلوب (المفتاح القادم لا يغيّر العميل)
  /// Sibling keys keep the requested customer — switching models never switches owners.
  MeasurementKey keyFor(int seqNo) =>
      MeasurementKey(custNo: custNo, billNo: detail.header.billNo, year: detail.header.year, seqNo: seqNo);
}
