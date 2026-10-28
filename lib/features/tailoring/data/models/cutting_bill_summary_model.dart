import 'tailoring_parse.dart';

/// صف واحد في قائمة فواتير التفصيل
/// One row in the cutting-bill list.
///
/// هوية الفاتورة مركّبة (الرقم، السنة) لأن `BILL_NO` وحده يتكرر بين السنوات؛ لذا
/// [CuttingBillKey] هو مفتاح التنقل والمزودات لا الرقم وحده.
/// The bill identity is the composite (number, year) because `BILL_NO` repeats across
/// years; hence [CuttingBillKey] — not the bare number — is the navigation and provider key.
class CuttingBillSummary {
  final int billNo;
  final int year;

  /// الرقم اليدوي المطبوع على الكرت / the manual number printed on the card
  final int? manualBillNo;

  /// التاريخ الجاهز للعرض (يوم/شهر/سنة)
  /// The display date (DD/MM/YYYY).
  final String? date;

  /// التاريخ الخام ISO للفلترة والمقارنة
  /// The raw ISO date for filtering and comparison.
  final DateTime? rawDate;

  final int? custNo;
  final String custName;
  final String? telNo1;

  final int modelsCount;
  final int piecesCount;

  final double? total;
  final double? discount;
  final double? net;

  final int? handingDone;
  final int ordsdid;

  const CuttingBillSummary({
    required this.billNo,
    required this.year,
    this.manualBillNo,
    this.date,
    this.rawDate,
    this.custNo,
    this.custName = '',
    this.telNo1,
    this.modelsCount = 0,
    this.piecesCount = 0,
    this.total,
    this.discount,
    this.net,
    this.handingDone,
    this.ordsdid = 0,
  });

  factory CuttingBillSummary.fromJson(Map<String, dynamic> json) {
    return CuttingBillSummary(
      billNo: tailoringInt(json, 'bill_no') ?? 0,
      year: tailoringInt(json, 'year') ?? 0,
      manualBillNo: tailoringInt(json, 'manual_bill_no'),
      date: tailoringDisplayDate(json, 'date', rawKey: 'raw_date'),
      rawDate: tailoringDate(json, 'raw_date'),
      custNo: tailoringInt(json, 'cust_no'),
      custName: tailoringText(json, 'cust_name') ?? '',
      telNo1: tailoringPlainText(json, 'tel_no1'),
      modelsCount: tailoringInt(json, 'models_count') ?? 0,
      piecesCount: tailoringInt(json, 'pieces_count') ?? 0,
      total: tailoringDouble(json, 'total'),
      discount: tailoringDouble(json, 'discount'),
      net: tailoringDouble(json, 'net'),
      handingDone: tailoringInt(json, 'handing_done'),
      ordsdid: tailoringInt(json, 'ordsdid') ?? 0,
    );
  }

  /// مفتاح الهوية المركّبة / the composite identity key
  CuttingBillKey get key => CuttingBillKey(billNo: billNo, year: year);

  /// هل تم تسليم الفاتورة بالكامل؟
  /// Is the bill fully delivered?
  bool get isDelivered => (handingDone ?? 0) != 0;

  /// «12345 / 2026» — الشكل المستخدم في كل الشاشات والتقارير
  /// "12345 / 2026" — the shape used across every screen and report.
  String get referenceLabel => '$billNo / $year';

  /// الرقم اليدوي أو شرطة عند غيابه
  /// The manual number, or a dash when absent.
  String get manualLabel => manualBillNo == null ? '—' : '$manualBillNo';

  /// الصافي منسّقاً / the net total, formatted
  String get netLabel => tailoringNumber(net);
}

/// هوية الفاتورة المركّبة — مفتاح كل مزود وتنقل
/// The composite bill identity — the key of every provider and navigation.
class CuttingBillKey {
  final int billNo;
  final int year;

  const CuttingBillKey({required this.billNo, required this.year});

  /// «12345/2026» — نفس الشكل الذي يبنيه الخادم في `entity_id`
  /// "12345/2026" — the same shape the server builds into `entity_id`.
  String get id => '$billNo/$year';

  @override
  bool operator ==(Object other) =>
      other is CuttingBillKey && other.billNo == billNo && other.year == year;

  @override
  int get hashCode => Object.hash(billNo, year);

  @override
  String toString() => id;
}

/// صفحة من قائمة الفواتير: الصفوف مع بيانات التصفح
/// One page of the bill list: the rows plus paging metadata.
class CuttingBillPage {
  final List<CuttingBillSummary> items;
  final int total;
  final int page;
  final int pages;
  final int limit;

  const CuttingBillPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 0,
    this.limit = 50,
  });

  bool get hasMore => page < pages;
}
