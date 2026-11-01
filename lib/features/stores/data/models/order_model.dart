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

/// سطر مستند مقروء من الخادم
/// A document line read back from the server.
class StoreOrderLineModel {
  const StoreOrderLineModel({
    required this.sanfNo,
    required this.sanfDno,
    this.sanfName,
    this.partNo,
    this.unitName,
    this.qty = 0,
    this.price = 0,
    this.total = 0,
    this.cap = 0,
    this.seq = 0,
  });

  final int sanfNo;
  final int sanfDno;
  final String? sanfName;
  final String? partNo;
  final String? unitName;
  final double qty;
  final double price;
  final double total;
  final double cap;
  final int seq;

  factory StoreOrderLineModel.fromJson(Map<String, dynamic> json) {
    final qty = JsonValues.asDoubleOrNull(json['QTY'] ?? json['qty']) ?? 0;
    final price = JsonValues.asDoubleOrNull(json['SANF_PRICE'] ?? json['sanf_price']) ?? 0;

    return StoreOrderLineModel(
      sanfNo: JsonValues.asInt(json['SANF_NO'] ?? json['sanf_no']),
      sanfDno: JsonValues.asInt(json['SANF_DNO'] ?? json['sanf_dno']),
      sanfName: JsonValues.asArabic(json['SANF_NAME'] ?? json['sanf_name']),
      partNo: JsonValues.asText(json['PART_NO'] ?? json['part_no']),
      unitName: JsonValues.asArabic(json['UNIT_NAME'] ?? json['unit_name']),
      qty: qty,
      price: price,
      total: JsonValues.asDoubleOrNull(json['TOTAL'] ?? json['total']) ??
          (qty * price),
      cap: JsonValues.asDoubleOrNull(json['CAP'] ?? json['cap']) ?? 0,
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
    this.sanfNums = 0,
    this.total = 0,
    this.discount = 0,
    this.net = 0,
    this.detailes,
    this.createdOn,
    this.createdByName,
    this.lines = 0,
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
  final int sanfNums;
  final double total;
  final double discount;
  final double net;
  final String? detailes;
  final DateTime? createdOn;
  final String? createdByName;

  /// عدد السطور كما يعيده الخادم في القائمة (بلا تحميلها)
  /// The line count the server returns in the list (without loading the lines).
  final int lines;
  final bool posted;

  /// هوية المستند للعرض: `رقم-سنة`
  /// The display identity: `number-year`.
  String get reference => '$billNo-$year';

  String get dateLabel => JsonValues.formatDate(date, withTime: false);

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
      sanfNums: JsonValues.asInt(json['SANF_NUMS'] ?? json['sanf_nums']),
      total: JsonValues.asDoubleOrNull(json['TOTAL'] ?? json['total']) ?? 0,
      discount: JsonValues.asDoubleOrNull(json['DISCOUNT'] ?? json['discount']) ?? 0,
      net: JsonValues.asDoubleOrNull(json['NET'] ?? json['net']) ?? 0,
      detailes: JsonValues.asArabic(json['DETAILES'] ?? json['detailes']),
      createdOn: JsonValues.asDate(json['CREATED_ON'] ?? json['created_on']),
      createdByName: JsonValues.asArabic(
        json['CREATED_BY_NAME'] ?? json['created_by_name'],
      ),
      lines: JsonValues.asInt(json['LINES'] ?? json['lines']),
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
