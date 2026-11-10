import 'cutting_piece_item.dart';
import 'tailoring_parse.dart';

/// المواصفات النصية والأكواد الرقمية للموديل كما تخزّنها القاعدة بلا ترجمة مخترعة
/// The model's spec texts and numeric codes exactly as stored, with no invented labels.
///
/// الأكواد الرقمية (NECK_SHAPE_NO وأخواتها) تُعرض كما هي: ترجمتها إلى أسماء تحتاج قاموساً
/// لا يملكه المشروع الآن، فتحويلها بالتخمين خطأ.
/// The numeric codes are shown as-is: naming them needs a dictionary the project does not
/// have yet, so guessing a translation would be wrong.
class CuttingModelSpecs {
  final String? neckType;
  final String? tipperType;
  final String? comCabakType;
  final String? pocketOrWithout;
  final String? gabzorType;
  final String? buttonType;
  final String? buttonNo;
  final String? mobilePocket;
  final String? penPocket;
  final String? hegaziType;
  final String? notes;

  final int? neckShapeNo;
  final int? shapeGabzorNo;
  final int? shapeComCabakNo;
  final int? shapePocketUpNo;
  final int? shapePocketDownNo;

  const CuttingModelSpecs({
    this.neckType,
    this.tipperType,
    this.comCabakType,
    this.pocketOrWithout,
    this.gabzorType,
    this.buttonType,
    this.buttonNo,
    this.mobilePocket,
    this.penPocket,
    this.hegaziType,
    this.notes,
    this.neckShapeNo,
    this.shapeGabzorNo,
    this.shapeComCabakNo,
    this.shapePocketUpNo,
    this.shapePocketDownNo,
  });

  factory CuttingModelSpecs.fromJson(Map<String, dynamic> json) {
    return CuttingModelSpecs(
      neckType: tailoringText(json, 'neck_type'),
      tipperType: tailoringText(json, 'tipper_type'),
      comCabakType: tailoringText(json, 'com_cabak_type'),
      pocketOrWithout: tailoringText(json, 'pocket_or_without'),
      gabzorType: tailoringText(json, 'gabzor_type'),
      buttonType: tailoringText(json, 'button_type'),
      buttonNo: tailoringText(json, 'button_no'),
      mobilePocket: tailoringText(json, 'mobile_pocket'),
      penPocket: tailoringText(json, 'pen_pocket'),
      hegaziType: tailoringText(json, 'hegazi_type'),
      notes: tailoringText(json, 'notes'),
      neckShapeNo: tailoringInt(json, 'neck_shape_no'),
      shapeGabzorNo: tailoringInt(json, 'shape_gabzor_no'),
      shapeComCabakNo: tailoringInt(json, 'shape_com_cabak_no'),
      shapePocketUpNo: tailoringInt(json, 'shape_pocket_up_no'),
      shapePocketDownNo: tailoringInt(json, 'shape_pocket_down_no'),
    );
  }

  /// الشرائح النصية بترتيب العرض مع تسميتها — الفارغ يُسقط من العرض
  /// The text chips in display order with their labels; blanks are dropped.
  ///
  /// التسميات تصف خصائص القطعة نفسها (رقبة، كم، جيوب، أزرار…) لا هوية الموديل (نوعه وشكله)،
  /// لأن هوية الموديل تُعرض في سطر الموديل بالقسم الرابع.
  /// The labels describe the garment's own properties (neck, sleeve, pockets, buttons…) rather
  /// than the model's identity (type and shape), which is shown on the model line instead.
  List<(String, String)> get textChips {
    final chips = <(String, String)>[
      if (comCabakType != null) ('نوع الكم', comCabakType!),
      if (neckType != null) ('نوع الرقبة', neckType!),
      if (pocketOrWithout != null) ('الجيوب', pocketOrWithout!),
      if (gabzorType != null) ('نوع الجبزور', gabzorType!),
      if (mobilePocket != null) ('جيب الصدر ', mobilePocket!),
      if (buttonType != null) ('نوع الأزرار', buttonType!),
      if (buttonNo != null) ('رقم الأزرار', buttonNo!),    
      if (shapeGabzorNo != null && shapeGabzorNo==1) ('جبزور يد', '✔️'),
      if (tipperType != null) (' فئة الخياط', tipperType!),      
      
        
      // if (penPocket != null) ('جيب القلم', penPocket!),  // لايوجد حاليا 
      // if (hegaziType != null) ('نوع الحجازي', hegaziType!),
    ];
    return chips;
  }

  /// الأكواد الرقمية كما هي / the numeric codes, as they are
  List<(String, int)> get numericCodes {
    final codes = <(String, int)>[
      // if (neckShapeNo != null) ('نموذج الرقبة', neckShapeNo!),      
      // if (shapeComCabakNo != null) ('نموذج الكباك', shapeComCabakNo!),
      // if (shapePocketUpNo != null) ('نموذج الجيب العلوي', shapePocketUpNo!),
      // if (shapePocketDownNo != null) ('نموذج الجيب السفلي', shapePocketDownNo!),
    ];
    return codes;
  }

  /// هل يحمل الموديل أي مواصفة؟ يُستخدم لإظهار حالة فراغ محترمة
  /// Does the model carry any specification? Drives an honest empty state.
  bool get isEmpty =>
      textChips.isEmpty && numericCodes.isEmpty && (notes == null || notes!.isEmpty);
}

/// موديل واحد داخل فاتورة التفصيل: المستفيد + المقاسات + المواصفات + القطع
/// One model inside a cutting bill: beneficiary, measurements, specs and pieces.
class CuttingModelItem {
  /// رقم الموديل داخل الفاتورة (SEQ_NO)
  /// The model number inside the bill (SEQ_NO).
  final int seqNo;

  final String? beneficiary;
  final String? typeName;
  final String? shapeName;
  final int? shapeStyleNo;

  /// عدد القطع في الموديل — يأتي من صف الموديل، ويُصحح إلى عدد القطع الفعلي عند الصفر
  /// The piece count from the model row, corrected to the real piece count when zero.
  final int qty;

  /// المقاسات L1..L12 مفهرسة بمفاتيح الخادم كما هي
  /// Measurements L1..L12 keyed exactly as the server sends them.
  final Map<String, double?> measurements;

  final CuttingModelSpecs specs;
  final List<CuttingPieceItem> pieces;

  const CuttingModelItem({
    required this.seqNo,
    this.beneficiary,
    this.typeName,
    this.shapeName,
    this.shapeStyleNo,
    this.qty = 0,
    this.measurements = const {},
    this.specs = const CuttingModelSpecs(),
    this.pieces = const [],
  });

  factory CuttingModelItem.fromJson(Map<String, dynamic> json) {
    return CuttingModelItem(
      seqNo: tailoringInt(json, 'seq_no') ?? 0,
      beneficiary: tailoringText(json, 'beneficiary'),
      typeName: tailoringText(json, 'type_name'),
      shapeName: tailoringText(json, 'shape_name'),
      shapeStyleNo: tailoringInt(json, 'shape_style_no'),
      qty: tailoringInt(json, 'qty') ?? 0,
      measurements: _readMeasurements(json),
      // الخادم يُعشّن المواصفات داخل `specs`، فلا تُقرأ من جذر الموديل وإلا بقيت فارغة.
      // الاختبارات القديمة تمرّرها مسطّحة في الجذر، لذا يُقبل الموضعان.
      // The server nests specs under `specs`; reading them from the model root left them blank.
      // Older tests pass them flat at the root, so both shapes are accepted.
      specs: CuttingModelSpecs.fromJson(
        json['specs'] is Map
            ? Map<String, dynamic>.from(json['specs'] as Map)
            : json,
      ),
      pieces: (json['pieces'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CuttingPieceItem.fromJson)
          .toList(),
    );
  }

  /// قراءة L1..L12 من كائن `measurements` مع الرجوع إلى الجذر احتياطاً
  /// Read L1..L12 from the `measurements` object, falling back to the root map.
  static Map<String, double?> _readMeasurements(Map<String, dynamic> json) {
    final nested = json['measurements'];
    final source = nested is Map
        ? Map<String, dynamic>.from(nested)
        : const <String, dynamic>{};
    final result = <String, double?>{};

    for (var i = 1; i <= 12; i++) {
      final key = 'L$i';
      final value = tailoringDouble(source, key) ??
          (source.isEmpty ? tailoringDouble(json, key) : null);
      if (value != null) result[key] = value;
    }

    return result;
  }

  /// عدد القطع الفعلي (يحتمي من صفر مضلّل في صف الموديل)
  /// The real piece count, guarding against a misleading zero on the model row.
  int get piecesCount => pieces.length;

  /// القطع التي تحمل رقماً صالحاً — أساس طلب سجل الحركة
  /// The pieces carrying a usable number — the basis of the movement request.
  List<int> get movementSeqNos =>
      pieces.map((p) => p.seqNo1).where((n) => n > 0).toList();

  /// أرقام طلبات الأقمشة (OHDID) — مفتاح سجل الحركة: الحركة للقماش لا للموديل
  /// The fabric order ids (OHDID) — the movement key: the log belongs to the fabric, not
  /// the model.
  List<int> get movementOhdIds =>
      pieces.map((p) => p.ohdId).whereType<int>().where((n) => n > 0).toList();

  /// أرقام القطع (SEQ_NO1) للعرض في رأس الموديل
  /// The piece numbers (SEQ_NO1) shown in the model header.
  String get piecesRangeLabel =>
      pieces.isEmpty ? '' : '${pieces.length} قطعة';

  /// مرحلة الموديل: أدنى مرحلة بين قطعه، لأن الموديل لا يُسلَّم قبل آخر قطعة
  /// The model's stage: the lowest of its pieces, since a model is not delivered
  /// before its last piece.
  CuttingPieceStage get stage {
    if (pieces.isEmpty) return CuttingPieceStage.waiting;
    final rank = {
      CuttingPieceStage.waiting: 0,
      CuttingPieceStage.cut: 1,
      CuttingPieceStage.tailored: 2,
      CuttingPieceStage.delivered: 3,
    };
    var lowest = pieces.first.stage;
    for (final piece in pieces.skip(1)) {
      if ((rank[piece.stage] ?? 0) < (rank[lowest] ?? 0)) lowest = piece.stage;
    }
    return lowest;
  }

  /// اسم الموديل للعرض: النوع ثم الشكل ثم رقم الموديل
  /// The model's display name: type, then shape, then its number.
  String get displayName {
    final named = tailoringJoin([typeName, shapeName]);
    return named.isEmpty ? 'موديل $seqNo' : named;
  }

  /// المقاسات الفارغة تُخفى افتراضياً، وهذا هو عددها الفعلي
  /// Blanks are hidden by default; this is how many actually carry a value.
  int get filledMeasurementsCount => measurements.length;
}
