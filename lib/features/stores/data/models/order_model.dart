import 'package:flutter/material.dart';

import '../../../../core/utils/json_value_utils.dart';

/// أنواع مستندات المخازن الثلاثة — نفس المسارات الثلاثة في الخادم والواجهة
/// The three inventory document kinds — the same three routes on both sides.
enum StoreOrderKind {
  receive('receive', 'أوامر التوريد', 'توريد مخزني', Icons.call_received_rounded),
  issue('issue', 'أوامر الصرف', 'صرف مخزني', Icons.call_made_rounded),
  transfer('transfer', 'أوامر التحويل', 'تحويل مخزني', Icons.swap_horiz_rounded);

  const StoreOrderKind(this.code, this.title, this.documentLabel, this.icon);

  /// المقطع المستخدم في المسار (`/stores/receive`)
  /// The path segment (`/stores/receive`).
  final String code;
  final String title;
  final String documentLabel;
  final IconData icon;

  /// هل للمستند مخزن هدف؟ التحويل وحده
  /// Does the document carry a destination store? Only the transfer does.
  bool get hasTargetStore => this == StoreOrderKind.transfer;

  /// هل للمستند طرف (مورد/جهة مستلمة)؟ التحويل لا طرف له
  /// Does the document carry a party? A transfer does not.
  bool get hasParty => this != StoreOrderKind.transfer;

  static StoreOrderKind fromCode(String code) {
    for (final kind in StoreOrderKind.values) {
      if (kind.code == code) return kind;
    }

    return StoreOrderKind.receive;
  }
}

/// سطر مستند مقروء من الخادم — بكل أعمدة المستند المكتبي
/// A document line read from the server — every column the desktop document prints.
///
/// ── المقاسات (طول/عرض) والتصنيف واللون والرف والعبوة والقطعة ليست زينة: المستند المطبوع
///    يعرضها، والمستخدم يقارن الطبعة بالشاشة سطرًا بسطر. أي عمود ناقص هنا يظهر كفراغ في الطبع.
/// ── Sizes, classification, colour, shelf, pack and pieces are not decoration: the printed
///    document carries them and the user compares print against screen line by line. A missing
///    column here shows up as a blank in the printout.
class StoreOrderLineModel {
  const StoreOrderLineModel({
    required this.sanfNo,
    required this.sanfDno,
    this.sanfName,
    this.partNo,
    this.subName,
    this.subPartNo,
    this.subCode,
    this.barcode,
    this.unitName,
    this.unitNo = 0,
    this.typeName,
    this.groupName,
    this.category,
    this.colorName,
    this.colorNo = 0,
    this.shelfNo = 0,
    this.lengthFrom = 0,
    this.lengthTo = 0,
    this.subLen = 0,
    this.subWid = 0,
    this.qty = 0,
    this.price = 0,
    this.total = 0,
    this.cap = 0,
    this.pcs = 0,
    this.stkCost = 0,
    this.sanfCost = 0,
    this.styleNo = 0,
    this.catNo = 0,
    this.seq = 0,
  });

  final int sanfNo;
  final int sanfDno;

  /// اسم الصنف الرئيسي (`SANFS.SANF_NAME`)
  /// The main item name.
  final String? sanfName;
  final String? partNo;

  /// اسم الصنف الفرعي كما يطبعه المستند (`SANFS_D.SANF_DNAME`)
  /// The sub-item name the document actually prints.
  final String? subName;
  final String? subPartNo;
  final String? subCode;
  final String? barcode;
  final String? unitName;
  final int unitNo;

  /// المجموعة الفرعية (`TYPES`) والمجموعة الرئيسية (`GROUP1`) — عمود «التصنيف» في الطبع
  /// Sub group and group — the classification column of the printout.
  final String? typeName;
  final String? groupName;
  final String? category;
  final String? colorName;
  final int colorNo;
  final int shelfNo;

  /// المقاس المخزّن في السطر نفسه: طول ← SIZE_FRM وعرض ← SIZE_TO
  /// The dimensions stored on the line itself: length ← SIZE_FRM, width ← SIZE_TO.
  final double lengthFrom;
  final double lengthTo;

  /// مقاس الصنف الفرعي الحالي — يُستخدم عند الإنشاء لا عند الطبع التاريخي
  /// The sub item's current dimensions — used when building a line, never for history.
  final double subLen;
  final double subWid;
  final double qty;
  final double price;
  final double total;

  /// عبوة (كمية القطع في العبوة) وقطعة (إجمالي القطع)
  /// Pack size and the resulting piece count.
  final double cap;
  final double pcs;

  /// متوسط التكلفة المخزّن في السطر — عمود «المنصرف/متوسط التكلفة» في نموذج الصرف
  /// Stored average cost — the issue form's cost columns.
  final double stkCost;
  final double sanfCost;
  final int styleNo;
  final int catNo;
  final int seq;

  /// الاسم المعروض في السطر: الفرعي أولاً لأنه ما يُقرأ في المستند المكتبي
  /// Display name: the sub item wins, because that is what the desktop document shows.
  String get displayName => subName ?? sanfName ?? 'صنف $sanfNo';

  /// المقاس كما يُطبع: «طول × عرض» أو شرطة فارغة إن لم يُسجّل مقاس
  /// Sizes as printed: `length × width`, or a dash when none was recorded.
  String get sizeLabel {
    final from = lengthFrom > 0 ? _trim(lengthFrom) : null;
    final to = lengthTo > 0 ? _trim(lengthTo) : null;

    if (from == null && to == null) return '—';
    if (to == null) return from!;
    if (from == null) return to;

    return '$from × $to';
  }

  /// رقم بلا أصفار زائدة: 55.0 → «55» و 1.25 → «1.25». النموذج لا يستورد ودجت عرض
  /// A number without trailing zeros. The model must not import a presentation widget.
  static String _trim(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);

    return value
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  factory StoreOrderLineModel.fromJson(Map<String, dynamic> json) {
    final qty = JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0;
    final price =
        JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ?? 0;
    final cap = JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0;

    return StoreOrderLineModel(
      sanfNo: JsonValues.asInt(json['SANF_NO'] ?? json['sanf_no']),
      sanfDno: JsonValues.asInt(json['SANF_DNO'] ?? json['sanf_dno']),
      sanfName: JsonValues.asArabic(json['SANF_NAME'] ?? json['sanf_name']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      subName: JsonValues.asArabic(json['SUB_NAME'] ?? json['sub_name']),
      subPartNo: JsonValues.asText(json['SUB_PART_NO'] ?? json['sub_part_no']),
      subCode: JsonValues.asText(json['SUB_CODE'] ?? json['sub_code']),
      barcode: JsonValues.asText(json['SUB_BARCODE'] ?? json['sub_barcode']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
      unitNo: JsonValues.asInt(json['UNIT_NO'] ?? json['unit_no']),
      typeName: JsonValues.asArabic(json['TYPE_NAME'] ?? json['type_name']),
      groupName: JsonValues.asArabic(json['GROUP_NAME'] ?? json['group_name']),
      category: JsonValues.asArabic(json['CATEGORY'] ?? json['category']),
      colorName: JsonValues.asArabic(json['COLOR_NAME'] ?? json['color_name']),
      colorNo: JsonValues.asInt(json['COLOR_NO'] ?? json['color_no']),
      shelfNo: JsonValues.asInt(json['SHELF_NO'] ?? json['shelf_no']),
      lengthFrom:
          JsonValues.asDoubleOrNull(json['SIZE_FRM'] ?? json['size_frm']) ?? 0,
      lengthTo: JsonValues.asDoubleOrNull(json['SIZE_TO'] ?? json['size_to']) ?? 0,
      subLen: JsonValues.asDoubleOrNull(json['SUB_LEN'] ?? json['sub_len']) ?? 0,
      subWid: JsonValues.asDoubleOrNull(json['SUB_WID'] ?? json['sub_wid']) ?? 0,
      qty: qty,
      price: price,
      total: JsonValues.asDoubleOrNull(json['TOTAL'] ?? json['total']) ??
          (qty * price),
      cap: cap,
      // القطعة = الكمية × العبوة؛ والخادم يرسل PCS فعلياً عند وجودها
      // Pieces = quantity × pack; the server sends PCS when it is recorded.
      pcs: JsonValues.asDoubleOrNull(json['PCS'] ?? json['pcs']) ??
          (cap > 0 ? qty * cap : qty),
      stkCost:
          JsonValues.asDoubleOrNull(json['STK_COST'] ?? json['stk_cost']) ?? 0,
      sanfCost:
          JsonValues.asDoubleOrNull(json['SANF_COST'] ?? json['sanf_cost']) ?? 0,
      styleNo: JsonValues.asInt(json['STYLE_NO'] ?? json['style_no']),
      catNo: JsonValues.asInt(json['CAT_NO'] ?? json['cat_no']),
      seq: JsonValues.asInt(json['SEQ'] ?? json['seq']),
    );
  }
}

/// رأس مستند: توريد · صرف · تحويل
/// A document header: receive · issue · transfer.
class StoreOrderModel {
  const StoreOrderModel({
    required this.billNo,
    required this.year,
    this.date,
    this.storeNo = 0,
    this.storeName,
    this.storeTo,
    this.storeToName,
    this.partyNo,
    this.partyName,
    this.partyBill,
    this.entryNo = 0,
    this.billType = 1,
    this.selectOne = 1,
    this.sanfNums = 0,
    this.total = 0,
    this.discountRate = 0,
    this.discount = 0,
    this.net = 0,
    this.curNo = 1,
    this.curName,
    this.curPrice = 1,
    this.curNo1 = 1,
    this.curName1,
    this.curPrice1 = 1,
    this.accNo = 0,
    this.accName,
    this.accNo1 = 0,
    this.accName1,
    this.accNo2 = 0,
    this.accName2,
    this.detailes,
    this.createdOn,
    this.createdByName,
    this.theTime,
    this.lastUpdatedOn,
    this.lastUpdatedByName,
    this.lastUpdateTime,
    this.lines = 0,
    this.qtySum = 0,
    this.trInvMId = 0,
    this.inboundId = 0,
    this.posted = false,
  });

  final int billNo;
  final int year;
  final DateTime? date;
  final int storeNo;
  final String? storeName;
  final int? storeTo;
  final String? storeToName;
  final int? partyNo;
  final String? partyName;

  /// رقم المرجع عند الطرف (`PROV_BILL`) — يظهر في ترويسة المستند المكتبي
  /// The counterparty reference number shown on the desktop document header.
  final String? partyBill;

  /// رقم القيد المحاسبي (`ENTRY_NO`) — خانة مقروءة في المستند، لا يُحرَّر من التطبيق
  /// The accounting entry number: readable on the document, never edited from the app.
  final int entryNo;

  /// نوع الفاتورة: 1 نقد · 2 آجل (`BILL_TYPE`)
  /// Bill type: 1 cash · 2 credit.
  final int billType;

  /// أي عملة تُحتسب بها المبالغ: 1 محلية · 2 عملة الحساب المدين (`SELECT1`)
  /// Which currency the amounts are reckoned in: 1 local · 2 the ledger account's currency.
  final int selectOne;
  final int sanfNums;
  final double total;
  final double discountRate;
  final double discount;
  final double net;

  /// صفا العملة: الأساسية والثانية — كما في رأس المستند المكتبي
  /// The two currency rows of the desktop header.
  final int curNo;
  final String? curName;
  final double curPrice;
  final int curNo1;
  final String? curName1;
  final double curPrice1;

  /// حساب المخزن وحساب الطرف المقابل وحساب ثالث (يظهر في الصرف)
  /// Store account, the counter account, and a third one the issue document carries.
  final int accNo;
  final String? accName;
  final int accNo1;
  final String? accName1;
  final int accNo2;
  final String? accName2;
  final String? detailes;
  final DateTime? createdOn;
  final String? createdByName;

  /// شريط التدقيق كما يعرضه ذيل النموذج: تاريخ الإدخال + المستخدم + الوقت + التعديل
  /// The audit strip at the foot of the form: entry date, user, time, and the edit row.
  final String? theTime;
  final DateTime? lastUpdatedOn;
  final String? lastUpdatedByName;
  final String? lastUpdateTime;

  /// عدد السطور كما يعيده الخادم في القائمة (بلا تحميلها)
  /// The line count the server returns in the list (without loading the lines).
  final int lines;

  /// إجمالي الكمية كما يعيده الخادم في القائمة
  /// The total quantity the server returns in the list.
  final double qtySum;

  /// معرّف رأس التحويل وشقيقه الوارد (`TR_INV_M_ID`) — خانتا «المسلسل» في نموذج التحويل
  /// The transfer master id and its inbound twin — the two "serial" fields of the form.
  final int trInvMId;
  final int inboundId;
  final bool posted;

  /// هوية المستند للعرض: `رقم-سنة`
  /// The display identity: `number-year`.
  String get reference => '$billNo-$year';

  String get dateLabel => JsonValues.formatDate(date, withTime: false);

  /// تسمية نوع الفاتورة كما في النظام المكتبي
  /// The bill-type label, as the desktop names it.
  String get billTypeLabel => billType == 2 ? 'آجل' : 'نقد';

  /// تاريخ الإدخال للعرض: التاريخ + الوقت المخزّن نصياً (`THE_TIME`) إن وُجد
  /// Entry stamp: the date plus the stored time text when present.
  String get createdStamp {
    final date = dateLabel;
    final time = JsonValues.textOrEmpty(theTime);

    return time.isEmpty ? date : '$date — $time';
  }

  /// هل عُدّل المستند بعد إنشائه؟ ذيل النموذج يعرض صف التعديل فقط عند وجوده
  /// Was the document edited? The form footer only shows the edit row when there is one.
  bool get hasEditStamp => lastUpdatedOn != null || lastUpdatedByName != null;

  factory StoreOrderModel.fromJson(Map<String, dynamic> json) {
    return StoreOrderModel(
      billNo: JsonValues.asInt(json['BILL_NO'] ?? json['bill_no']),
      year: JsonValues.asInt(json['YEAR'] ?? json['year']),
      date: JsonValues.asDate(json['DAT'] ?? json['dat']),
      storeNo: JsonValues.asInt(json['STORE_NO'] ?? json['store_no']),
      storeName: JsonValues.asArabic(json['STORE_NAME'] ?? json['store_name']),
      storeTo: JsonValues.asIntOrNull(json['STORE_TO'] ?? json['store_to']),
      storeToName: JsonValues.asArabic(
        json['STORE_TO_NAME'] ?? json['store_to_name'],
      ),
      partyNo: JsonValues.asIntOrNull(json['PARTY_NO'] ?? json['party_no']),
      partyName: JsonValues.asArabic(json['PARTY_NAME'] ?? json['party_name']),
      partyBill: JsonValues.asText(
        json['PARTY_BILL'] ?? json['party_bill'] ?? json['PROV_BILL'],
      ),
      entryNo: JsonValues.asInt(json['ENTRY_NO'] ?? json['entry_no']),
      billType: JsonValues.asInt(json['BILL_TYPE'] ?? json['bill_type'], fallback: 1),
      selectOne: JsonValues.asInt(json['SELECT1'] ?? json['select1'], fallback: 1),
      sanfNums: JsonValues.asInt(json['SANF_NUMS'] ?? json['sanf_nums']),
      total: JsonValues.asDoubleOrNull(json['TOTAL'] ?? json['total']) ?? 0,
      discountRate:
          JsonValues.asDoubleOrNull(json['DIS_RATE'] ?? json['dis_rate']) ?? 0,
      discount: JsonValues.asDoubleOrNull(json['DISCOUNT'] ?? json['discount']) ?? 0,
      net: JsonValues.asDoubleOrNull(json['NET'] ?? json['net']) ?? 0,
      curNo: JsonValues.asInt(json['CUR_NO'] ?? json['cur_no'], fallback: 1),
      curName: JsonValues.asArabic(json['CUR_NAME'] ?? json['cur_name']),
      curPrice:
          JsonValues.asDoubleOrNull(json['CUR_PRICE'] ?? json['cur_price']) ?? 1,
      curNo1: JsonValues.asInt(json['CUR_NO1'] ?? json['cur_no1'], fallback: 1),
      curName1: JsonValues.asArabic(json['CUR_NAME1'] ?? json['cur_name1']),
      curPrice1:
          JsonValues.asDoubleOrNull(json['CUR_PRICE1'] ?? json['cur_price1']) ?? 1,
      accNo: JsonValues.asInt(json['ACC_NO'] ?? json['acc_no']),
      accName: JsonValues.asArabic(json['ACC_NAME'] ?? json['acc_name']),
      accNo1: JsonValues.asInt(json['ACC_NO1'] ?? json['acc_no1']),
      accName1: JsonValues.asArabic(json['ACC_NAME1'] ?? json['acc_name1']),
      accNo2: JsonValues.asInt(json['ACC_NO2'] ?? json['acc_no2']),
      accName2: JsonValues.asArabic(json['ACC_NAME2'] ?? json['acc_name2']),
      detailes: JsonValues.asArabic(json['DETAILES'] ?? json['detailes']),
      createdOn: JsonValues.asDate(json['CREATED_ON'] ?? json['created_on']),
      createdByName: JsonValues.asArabic(
        json['CREATED_BY_NAME'] ?? json['created_by_name'],
      ),
      theTime: JsonValues.asText(json['THE_TIME'] ?? json['the_time']),
      lastUpdatedOn: JsonValues.asDate(
        json['LAST_UPDATED_ON'] ?? json['last_updated_on'],
      ),
      lastUpdatedByName: JsonValues.asArabic(
        json['LAST_UPDATED_BY_NAME'] ?? json['last_updated_by_name'],
      ),
      lastUpdateTime: JsonValues.asText(
        json['LAST_UPDATE_TIME'] ?? json['last_update_time'],
      ),
      lines: JsonValues.asInt(json['LINES'] ?? json['lines']),
      qtySum: JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0,
      trInvMId: JsonValues.asInt(json['TR_INV_M_ID'] ?? json['tr_inv_m_id']),
      inboundId: JsonValues.asInt(json['INBOUND_ID'] ?? json['inbound_id']),
      posted: JsonValues.asFlag(json['FLAG_POST'] ?? json['flag_post']),
    );
  }

  /// طرف المستند كما يُعرض في القائمة (اسم المخزن الهدف للتحويل)
  /// The display party: the destination store for a transfer.
  String partyLabel(StoreOrderKind kind) {
    if (kind.hasParty) return partyName ?? '—';

    return storeToName ?? '—';
  }
}
