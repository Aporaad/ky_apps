import '../../../tailoring/data/models/tailoring_parse.dart';

/// صف عميل في قائمة «مقاسات العملاء» — تجميع على الواجهة لا سجل جدول العملاء
/// A row of the customer-measurements list — an aggregate over the view, not a customer record.
///
/// العميل هنا يظهر لأنه فصّل سابقاً: المصدر `ACCOUNTS.CUTTING_SALES_BILL_VIEW` مجمّعاً على
/// `CUST_NO`، فكل صف يحمل عدد فواتيره وموديلاته وآخر نشاط له. عميل بلا أي موديل لا يظهر في
/// هذا القسم أصلاً لأنه لا مقاسات له.
/// A customer appears here because he has tailoring history: the source is the cutting-bill view
/// aggregated by CUST_NO, so every row carries its bill count, model count and last activity. A
/// customer with no model never appears — he has no measurements to show.
class MeasurementCustomer {
  final int custNo;
  final String custName;

  /// هاتف الواجهة (`TEL_NO1`) — 4,313 صفاً منه فارغ في القاعدة الحيّة، فيجوز غيابه
  /// The view's phone (`TEL_NO1`) — blank on 4,313 live rows, so absence is normal.
  final String? telNo1;
  final int? accNo;
  final int? groupNo;
  final int billsCount;
  final int modelsCount;

  /// تاريخ آخر فاتورة بصيغتي العرض والخام (للترتيب الزمني في الواجهة)
  /// The latest bill date in display and raw forms (for UI sorting).
  final String? lastDate;
  final DateTime? rawLastDate;

  const MeasurementCustomer({
    required this.custNo,
    required this.custName,
    this.telNo1,
    this.accNo,
    this.groupNo,
    this.billsCount = 0,
    this.modelsCount = 0,
    this.lastDate,
    this.rawLastDate,
  });

  factory MeasurementCustomer.fromJson(Map<String, dynamic> json) {
    return MeasurementCustomer(
      custNo: tailoringInt(json, 'cust_no') ?? 0,
      // الاسم عربي في الأصل، و`tailoringText` يرمّم ترميز CP1256 قبل العرض.
      // The name is Arabic, and `tailoringText` repairs the CP1256 bytes before display.
      custName: tailoringText(json, 'cust_name') ?? '',
      // الهاتف نص غير عربي: تصحيح الترميز قد يفسد الأرقام، فيُقرأ كما هو.
      // A phone is not Arabic: the encoding repair could corrupt digits, so it is read as-is.
      telNo1: tailoringPlainText(json, 'tel_no1'),
      accNo: tailoringInt(json, 'acc_no'),
      groupNo: tailoringInt(json, 'group_no'),
      billsCount: tailoringInt(json, 'bills_count') ?? 0,
      modelsCount: tailoringInt(json, 'models_count') ?? 0,
      lastDate: tailoringDisplayDate(json, 'last_date', rawKey: 'raw_last_date'),
      rawLastDate: tailoringDate(json, 'raw_last_date'),
    );
  }

  /// عنوان مختصر عند غياب الاسم — لا تُعرض خانة فارغة بلا بديل
  /// A fallback title when the name is missing — an empty cell is never shown bare.
  String get displayName => custName.isEmpty ? 'عميل $custNo' : custName;

  /// سطر القائمة الثانوي: الهاتف ثم عدد الموديلات
  /// The list's secondary line: the phone, then the model count.
  String get subtitle {
    final parts = <String>[
      if (telNo1 != null) telNo1!,
      '$modelsCount موديل',
      if (billsCount > 0) '$billsCount فاتورة',
    ];

    return parts.join(' · ');
  }
}

/// صفحة قائمة العملاء مع بيانات التصفح
/// The customer page with its paging metadata.
///
/// `hasMore` تُشتق من الصفحة وعدد الصفحات لأن المغلّف هنا بصيغة قسم التفصيل
/// (`total, page, limit, pages`) كما في المتحكمات المجاورة.
/// `hasMore` is derived from page and pages, because this section uses the tailoring envelope
/// shape (`total, page, limit, pages`), matching its neighbouring controllers.
class MeasurementCustomerPage {
  final List<MeasurementCustomer> items;
  final int total;
  final int page;
  final int pages;
  final int limit;

  const MeasurementCustomerPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pages = 0,
    this.limit = 30,
  });

  bool get hasMore => page < pages;
}
