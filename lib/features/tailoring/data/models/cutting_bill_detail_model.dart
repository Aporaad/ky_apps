import 'cutting_bill_summary_model.dart';
import 'cutting_model_item.dart';
import 'tailoring_parse.dart';

/// ترويسة فاتورة التفصيل: بيانات الفاتورة والطلب والعميل
/// The cutting-bill header: invoice, order and customer data.
class CuttingBillHeader {
  final int billNo;
  final int year;
  final int? manualBillNo;
  final String? date;
  final DateTime? rawDate;

  final int? custNo;
  final String custName;
  final String? telNo1;
  final String? telNo2;
  final String? address;
  final int? accNo;
  final int? groupNo;

  /// رقم مرجع الفاتورة في النظام القديم وتاريخ الاستحقاق
  /// The bill's reference number in the legacy system and its due date.
  final String? refNo;
  final String? givingDate;
  final String? details;

  final bool urgent;
  final int? branchNo;
  final int? curNo;
  final double? curPrice;

  final bool handingDone;
  final String? handingDate;

  /// الحالة الحالية للسير مع اسمها من قاموس ORDSTATE
  /// The current workflow stage plus its name from the ORDSTATE dictionary.
  final int ordsdid;
  final String? ordsName;

  final int modelsCount;
  final int piecesCount;

  final String? createdBy;
  final String? lastUpdatedBy;

  const CuttingBillHeader({
    required this.billNo,
    required this.year,
    this.manualBillNo,
    this.date,
    this.rawDate,
    this.custNo,
    this.custName = '',
    this.telNo1,
    this.telNo2,
    this.address,
    this.accNo,
    this.groupNo,
    this.refNo,
    this.givingDate,
    this.details,
    this.urgent = false,
    this.branchNo,
    this.curNo,
    this.curPrice,
    this.handingDone = false,
    this.handingDate,
    this.ordsdid = 0,
    this.ordsName,
    this.modelsCount = 0,
    this.piecesCount = 0,
    this.createdBy,
    this.lastUpdatedBy,
  });

  factory CuttingBillHeader.fromJson(Map<String, dynamic> json) {
    return CuttingBillHeader(
      billNo: tailoringInt(json, 'bill_no') ?? 0,
      year: tailoringInt(json, 'year') ?? 0,
      manualBillNo: tailoringInt(json, 'manual_bill_no'),
      date: tailoringDisplayDate(json, 'date', rawKey: 'raw_date'),
      rawDate: tailoringDate(json, 'raw_date'),
      custNo: tailoringInt(json, 'cust_no'),
      custName: tailoringText(json, 'cust_name') ?? '',
      telNo1: tailoringPlainText(json, 'tel_no1'),
      telNo2: tailoringPlainText(json, 'tel_no2'),
      address: tailoringText(json, 'address'),
      accNo: tailoringInt(json, 'acc_no'),
      groupNo: tailoringInt(json, 'group_no'),
      refNo: tailoringPlainText(json, 'ref_no'),
      givingDate: tailoringPlainText(json, 'giving_date'),
      details: tailoringText(json, 'details'),
      urgent: (tailoringInt(json, 'urgent') ?? 0) != 0,
      branchNo: tailoringInt(json, 'branch_no'),
      curNo: tailoringInt(json, 'cur_no'),
      curPrice: tailoringDouble(json, 'cur_price'),
      handingDone: (tailoringInt(json, 'handing_done') ?? 0) != 0,
      handingDate: tailoringPlainText(json, 'handing_date'),
      ordsdid: tailoringInt(json, 'ordsdid') ?? 0,
      ordsName: tailoringText(json, 'ords_name'),
      modelsCount: tailoringInt(json, 'models_count') ?? 0,
      piecesCount: tailoringInt(json, 'pieces_count') ?? 0,
      createdBy: tailoringText(json, 'created_by'),
      lastUpdatedBy: tailoringText(json, 'last_updated_by'),
    );
  }

  /// هوية الفاتورة المركّبة / the composite bill identity
  CuttingBillKey get key => CuttingBillKey(billNo: billNo, year: year);

  /// «12345 / 2026» / the reference label
  String get referenceLabel => '$billNo / $year';

  /// الرقم اليدوي أو شرطة / the manual number or a dash
  String get manualLabel => manualBillNo == null ? '—' : '$manualBillNo';

  /// وصف الطلب: مستعجل أو عادي / the order urgency
  String get urgencyLabel => urgent ? 'مستعجل' : 'عادي';

  /// اسم الفرع مُقروءاً — يُترك الرقم عند غياب التسمية بدل اختراعها
  /// The branch label, falling back to the number rather than inventing a name.
  String get branchLabel => branchNo == null ? '—' : '$branchNo';
  
  /// هل الفاتورة منتهية التسليم؟ / is the bill fully delivered?
  bool get delivered => handingDone;
}

/// كتلة الدفع — تصل `null` من الخادم عند غياب صلاحية `tailoring.payments_view`
/// The payment block — arrives `null` from the server without `tailoring.payments_view`.
///
/// الحجب على الخادم لا في الواجهة: عند null لا تعرض الشاشة أرقاماً أصلاً.
/// The block is server-side: on null the screen shows no figures at all.
class CuttingBillPayment {
  final double? total;
  final double? discount;
  final double? net;
  final double? paid;
  final double? othersPayments;

  /// الصافي ناقص المدفوع — قد يكون سالباً (دفعة مقدمة)
  /// Net minus paid — it can be negative (an advance payment).
  final double? remaining;

  final int? isGiving;
  final String? givingDate;
  final String? paymentMethod;
  final String? voucherNo;
  final int? currencyNo;
  final double? currencyPrice;

  const CuttingBillPayment({
    this.total,
    this.discount,
    this.net,
    this.paid,
    this.othersPayments,
    this.remaining,
    this.isGiving,
    this.givingDate,
    this.paymentMethod,
    this.voucherNo,
    this.currencyNo,
    this.currencyPrice,
  });

  factory CuttingBillPayment.fromJson(Map<String, dynamic> json) {
    return CuttingBillPayment(
      total: tailoringDouble(json, 'total'),
      discount: tailoringDouble(json, 'discount'),
      net: tailoringDouble(json, 'net'),
      paid: tailoringDouble(json, 'paid'),
      othersPayments: tailoringDouble(json, 'others_payments'),
      remaining: tailoringDouble(json, 'remaining'),
      isGiving: tailoringInt(json, 'is_giving'),
      givingDate: tailoringPlainText(json, 'giving_date'),
      paymentMethod: tailoringText(json, 'payment_method'),
      voucherNo: tailoringText(json, 'voucher_no'),
      currencyNo: tailoringInt(json, 'currency_no'),
      currencyPrice: tailoringDouble(json, 'currency_price'),
    );
  }

  /// هل الرصيد سالب؟ ساعتها يُسمّى «رصيد مقدم» لا «متبقٍّ»
  /// Is the balance negative? Then it reads as an advance, not an amount due.
  bool get isAdvance => (remaining ?? 0) < 0;

  /// المدفوع كاملاً (مع المدفوعات الأخرى)
  /// The full paid amount, including the other payments.
  double get paidTotal => (paid ?? 0) + (othersPayments ?? 0);

  /// تسمية الرصيد: متبقٍّ / رصيد مقدم / مسدَّد
  /// The balance label: due / advance / settled.
  String get balanceLabel {
    if (remaining == null) return '—';
    if (isAdvance) return 'رصيد مقدم';
    if (remaining == 0) return 'مسدَّد بالكامل';
    return 'المتبقي';
  }

  /// قيمة الرصيد المطلقة منسّقة للعرض
  /// The absolute balance, formatted for display.
  String get balanceValue => tailoringNumber((remaining ?? 0).abs());

  /// طريقة الدفع مع رقم السند — تُضمّ في سطر واحد بالواجهة
  /// The payment method with the voucher number, joined for one line in the UI.
  String get settlementLabel {
    final parts = <String?>[
      paymentMethod,
      if (voucherNo != null) 'سند $voucherNo',
    ];
    return tailoringJoin(parts);
  }
}

/// تفصيل فاتورة كامل: الترويسة + الدفع + الموديلات بتسميات مقاساتها
/// A full bill detail: header, payment and models with their measurement labels.
class CuttingBillDetail {
  final CuttingBillHeader header;

  /// `null` تعني حجباً من الخادم لا نقص بيانات
  /// `null` means a server-side block, not missing data.
  final CuttingBillPayment? payment;

  final List<CuttingModelItem> models;

  /// تسميات المقاسات L1..L12 من GENERAL_LABELS_CODING
  /// Measurement labels L1..L12 from GENERAL_LABELS_CODING.
  final Map<String, String> measureLabels;

  const CuttingBillDetail({
    required this.header,
    this.payment,
    this.models = const [],
    this.measureLabels = const {},
  });

  factory CuttingBillDetail.fromJson(Map<String, dynamic> json) {
    final paymentJson = json['payment'];

    return CuttingBillDetail(
      header: CuttingBillHeader.fromJson(
        Map<String, dynamic>.from(json['header'] as Map? ?? const {}),
      ),
      payment: paymentJson is Map
          ? CuttingBillPayment.fromJson(Map<String, dynamic>.from(paymentJson))
          : null,
      models: (json['models'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CuttingModelItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      measureLabels: _readLabels(json['measure_labels']),
    );
  }

  /// التسميات تصل كائناً مفاتيحه L1..L12 وبعضها `null` — تُسقط الفراغات
  /// The labels arrive as an object keyed L1..L12, some `null`; blanks are dropped.
  static Map<String, String> _readLabels(dynamic raw) {
    if (raw is! Map) return const {};
    final labels = <String, String>{};

    raw.forEach((key, value) {
      if (value == null) return;
      final text = tailoringText({'v': value}, 'v');
      if (text != null) labels[key.toString()] = text;
    });

    return labels;
  }

  /// هل توجد بيانات مالية معروضة أصلاً؟ (الصلاحية)
  /// Are any figures displayable at all? (the grant)
  bool get hasPaymentDetails => payment != null;

  /// الموديل الأول يُختار تلقائياً عند الفتح إن وُجد
  /// The first model is selected automatically on open when one exists.
  CuttingModelItem? get firstModel => models.isEmpty ? null : models.first;

  /// مجموع القطع من كل الموديلات
  /// The piece total across every model.
  int get piecesCount =>
      models.fold(0, (sum, model) => sum + model.piecesCount);

  /// تسمية مقياس واحد مع الرجوع إلى مفتاحه عند غياب التسمية
  /// One measurement's label, falling back to its key when unnamed.
  String labelFor(String key) {
    final label = measureLabels[key];
    return label == null || label.trim().isEmpty ? key : label;
  }
}
