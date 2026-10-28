import 'tailoring_parse.dart';

/// صف واحد في سجل حركة القطع — قراءة تكميلية من CUTING_TRANSD + ORDSTATE
/// One row of the pieces' movement log — a supplementary read of CUTING_TRANSD + ORDSTATE.
///
/// الواجهة تحمل الحالة الحالية فقط بلا تاريخ انتقالات، فلولا هذه القراءة لسقط قسم
/// «سجل حركة الموديل» من الشاشة.
/// The view carries the current stage only with no transition history, so without this read
/// the "model movement log" section would be empty.
class CuttingMovement {
  final int? trInvDId;
  final String? date;
  final DateTime? rawDate;
  final int ordsid;
  final String? ordsName;
  final String? deptName;
  final String? details;
  final double? qty;
  final double? postedQty;
  final double? signedQty;
  final int? seqNo;
  final bool posted;
  final String? createdBy;
  final String? updatedBy;

  const CuttingMovement({
    this.trInvDId,
    this.date,
    this.rawDate,
    this.ordsid = 0,
    this.ordsName,
    this.deptName,
    this.details,
    this.qty,
    this.postedQty,
    this.signedQty,
    this.seqNo,
    this.posted = false,
    this.createdBy,
    this.updatedBy,
  });

  factory CuttingMovement.fromJson(Map<String, dynamic> json) {
    return CuttingMovement(
      trInvDId: tailoringInt(json, 'tr_inv_d_id'),
      date: tailoringDisplayDate(json, 'date', rawKey: 'raw_date'),
      rawDate: tailoringDate(json, 'raw_date'),
      ordsid: tailoringInt(json, 'ordsid') ?? 0,
      ordsName: tailoringText(json, 'ords_name'),
      deptName: tailoringText(json, 'dept_name'),
      details: tailoringText(json, 'details'),
      qty: tailoringDouble(json, 'qty'),
      postedQty: tailoringDouble(json, 'posted_qty'),
      signedQty: tailoringDouble(json, 'signed_qty'),
      seqNo: tailoringInt(json, 'seq_no'),
      posted: (tailoringInt(json, 'posted') ?? 0) != 0,
      createdBy: tailoringText(json, 'created_by'),
      updatedBy: tailoringText(json, 'updated_by'),
    );
  }

  /// الحالة المعروضة: اسم الحالة ثم كودها عند غياب الاسم
  /// The displayed stage: its name, or its code when unnamed.
  String get stageLabel {
    final name = ordsName;
    if (name != null && name.trim().isNotEmpty) return name;
    return ordsid == 0 ? '—' : 'حالة $ordsid';
  }

  /// الترحيل مقروءاً / posting state, readably
  String get postedLabel => posted ? 'مُرحَّل' : 'غير مُرحَّل';

  /// الكميات بصيغة واحدة / the quantities in one phrase
  String get quantityLabel {
    final parts = <String>[
      if (qty != null) 'العدد ${tailoringNumber(qty)}',
      if (postedQty != null) 'مُرحَّل ${tailoringNumber(postedQty)}',
      if (signedQty != null) 'موقّع ${tailoringNumber(signedQty)}',
    ];
    return parts.join(' · ');
  }
}
