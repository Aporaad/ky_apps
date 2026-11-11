import 'tailoring_parse.dart';

/// قطعة واحدة (ثوب) داخل موديل — تحمل القماش والقصّاص والخيّاط ومراحل الإنجاز
/// One piece (garment) of a model — carries the fabric, cutter, tailor and stage flags.
///
/// التسمية تحمل «قطعة» لأن النظام القديم يسمّيها ثوباً؛ الواجهة تعرض صفاً لكل قطعة
/// داخل جدول أقمشة الموديل.
/// The entity is a piece ("thawb" in the legacy vocabulary); the view exposes one row
/// per piece, which the model's fabrics table renders as a row.
class CuttingPieceItem {
  /// ترقيم القطعة داخل الفاتورة (SEQ_NO1) — يُستخدم لطلب سجل الحركة
  /// The piece number inside the bill (SEQ_NO1) — used to request its movements.
  final int seqNo1;

  /// رقم طلب القماش (OHDID) — مفتاح سجل حركة هذا القماش في النظام القديم
  /// The fabric order id (OHDID) — the key of this fabric's movement log in the legacy system.
  final int? ohdId;

  /// عرض القماش بالأرقام (58 / 45 / 38) — يُقرأ من `MULTI_CLOTHS` لا من `CLOTH_TYPE`
  /// The numeric cloth width (58 / 45 / 38) — read from MULTI_CLOTHS, not from CLOTH_TYPE.
  final String? clothWidth;

  /// نوع التجهيز (`FIXED_FLEXED`) — نص القاعدة كما هو، مثل «1-ثابت» و«2-مرن»
  /// The preparation type (FIXED_FLEXED) — the stored text as-is, e.g. "1-fixed", "2-flexed".
  final String? fixType;

  /// رقم التطريز (`ENTRY_NO` من MULTI_CLOTHS) — العمود غير معبأ في القاعدة غالباً
  /// The embroidery number (MULTI_CLOTHS.ENTRY_NO) — the column is unused in the database.
  final int? embroideryNo;

  /// خبنة دبل (`HABNA_DUABL`): 1 نعم، 0 لا — والواجهة تُخفي العمود عند 0
  /// Double habna (HABNA_DUABL): 1 yes, 0 no — the UI hides the column when it is 0.
  final int? habnaDuabl;

  final int? sanfNo;
  final int? sanfDno;

  /// بيانات القماش / fabric data
  final String? clothName;
  final String? clothType;
  final int? colorNo;
  final String? colorText;
  final double? hinsh;
  final double? yards;

  /// مصدر القماش: مخزن محلي أو اختيارنا
  /// Fabric source: the local store or our own selection.
  final int? fromLocalStore;
  final int? ourSelection;
  final String? shelfNo;

  /// المسؤولون والمراحل / assignees and stages
  final String? cutterName;
  final int? cutterNo;
  final String? tailorName;
  final int? tailorNo;

  /// أسعار التفصيل والخياطة للقطعة
  /// The per-piece cutting and tailoring prices.
  final double? cuttingPrice;
  final double? tailorPrice;

  final bool cuttingDone;
  final String? cuttingDate;
  final bool tailorDone;
  final String? tailorDate;
  final bool handingDone;
  final String? handingDate;
  final String? handingTime;

  final double? price;

  const CuttingPieceItem({
    required this.seqNo1,
    this.ohdId,
    this.clothWidth,
    this.fixType,
    this.embroideryNo,
    this.habnaDuabl,
    this.sanfNo,
    this.sanfDno,
    this.clothName,
    this.clothType,
    this.colorNo,
    this.colorText,
    this.hinsh,
    this.yards,
    this.fromLocalStore,
    this.ourSelection,
    this.shelfNo,
    this.cutterName,
    this.cutterNo,
    this.tailorName,
    this.tailorNo,
    this.cuttingPrice,
    this.tailorPrice,
    this.cuttingDone = false,
    this.cuttingDate,
    this.tailorDone = false,
    this.tailorDate,
    this.handingDone = false,
    this.handingDate,
    this.handingTime,
    this.price,
  });

  factory CuttingPieceItem.fromJson(Map<String, dynamic> json) {
    return CuttingPieceItem(
      seqNo1: tailoringInt(json, 'seq_no1') ?? 0,
      ohdId: tailoringInt(json, 'ohdid'),
      clothWidth: tailoringPlainText(json, 'cloth_width'),
      fixType: tailoringText(json, 'fix_type'),
      embroideryNo: tailoringInt(json, 'embroidery_no'),
      habnaDuabl: tailoringInt(json, 'habna_duabl'),
      sanfNo: tailoringInt(json, 'sanf_no'),
      sanfDno: tailoringInt(json, 'sanf_dno'),
      clothName: tailoringText(json, 'cloth_name'),
      clothType: tailoringText(json, 'cloth_type'),
      colorNo: tailoringInt(json, 'color_no'),
      colorText: tailoringText(json, 'color_text'),
      hinsh: tailoringDouble(json, 'hinsh'),
      yards: tailoringDouble(json, 'yards'),
      fromLocalStore: tailoringInt(json, 'from_local_store'),
      ourSelection: tailoringInt(json, 'our_selection'),
      shelfNo: tailoringText(json, 'shelf_no'),
      cutterName: tailoringText(json, 'cutter_name'),
      cutterNo: tailoringInt(json, 'cutter_no'),
      tailorName: tailoringText(json, 'tailor_name'),
      tailorNo: tailoringInt(json, 'tailor_no'),
      cuttingPrice: tailoringDouble(json, 'cutting_price'),
      tailorPrice: tailoringDouble(json, 'tailor_price'),
      cuttingDone: (tailoringInt(json, 'cutting_done') ?? 0) != 0,
      cuttingDate: tailoringPlainText(json, 'cutting_date'),
      tailorDone: (tailoringInt(json, 'tailor_done') ?? 0) != 0,
      tailorDate: tailoringPlainText(json, 'tailor_date'),
      handingDone: (tailoringInt(json, 'handing_done') ?? 0) != 0,
      handingDate: tailoringPlainText(json, 'handing_date'),
      handingTime: tailoringPlainText(json, 'handing_time'),
      price: tailoringDouble(json, 'price'),
    );
  }

  /// هل تحمل القطعة «خبنة دبل»؟ 1 فقط تعني نعم — صفر أو غياب يُخفيان العمود
  /// Does this piece carry a double habna? Only 1 means yes; 0 or absent hides the column.
  bool get hasDoubleHabna => (habnaDuabl ?? 0) == 1;

  /// مرحلة القطعة الحالية مقروءة من أعلام الإنجاز الثلاثة
  /// The piece's current stage, read from its three completion flags.
  ///
  /// الترتيب مقصود: التسليم يتجاوز الخياطة، والخياطة تتجاوز القص.
  /// The order is intentional: delivery outranks tailoring, tailoring outranks cutting.
  CuttingPieceStage get stage {
    if (handingDone) return CuttingPieceStage.delivered;
    if (tailorDone) return CuttingPieceStage.tailored;
    if (cuttingDone) return CuttingPieceStage.cut;
    return CuttingPieceStage.waiting;
  }

  /// الخيّاط غير المسند: القيمة الحرفية «لا يوجد» تصل `null` من الخادم.
  /// The unassigned tailor: the literal "لا يوجد" arrives as `null` from the server.
  bool get hasTailor => tailorName != null && tailorName!.trim().isNotEmpty;

  /// وصف متفصّل للقطع يُستخدم في مفتاح التحديد بالقائمة
  /// A detailed piece label used as the selection key in lists.
  String get label {
    final parts = <String>[
      if (clothName != null) clothName!,
      if (colorText != null) colorText!,
    ];
    return parts.isEmpty ? 'قطعة $seqNo1' : parts.join(' — ');
  }

  /// مصدر القماش مقروءاً / the fabric source, readably
  String get sourceLabel {
    if (ourSelection == 1) return 'اختيار المعرض';
    if (fromLocalStore == 1) return 'مخزن محلي';
    return '';
  }
}

/// مراحل القطعة / the piece stages
enum CuttingPieceStage {
  waiting('بانتظار القص'),
  cut('تم القص'),
  tailored('تم الخياطة'),
  delivered('تم التسليم');

  const CuttingPieceStage(this.label);

  final String label;
}
