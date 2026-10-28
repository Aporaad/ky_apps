import 'tailoring_parse.dart';

/// نوع موديل من قاموس TYPES
/// A model type from the TYPES dictionary.
class TailoringType {
  final int? typeNo;
  final String? typeName;
  final int? groupNo;
  final bool active;

  const TailoringType({
    this.typeNo,
    this.typeName,
    this.groupNo,
    this.active = true,
  });

  factory TailoringType.fromJson(Map<String, dynamic> json) {
    return TailoringType(
      typeNo: tailoringInt(json, 'type_no'),
      typeName: tailoringText(json, 'type_name'),
      groupNo: tailoringInt(json, 'group_no'),
      active: (tailoringInt(json, 'active') ?? 1) != 0,
    );
  }
}

/// شكل موديل من قاموس STYLE
/// A model shape from the STYLE dictionary.
class TailoringStyle {
  final int? shapeStyleNo;
  final String? styleName;
  final int? typeNo;

  const TailoringStyle({this.shapeStyleNo, this.styleName, this.typeNo});

  factory TailoringStyle.fromJson(Map<String, dynamic> json) {
    return TailoringStyle(
      shapeStyleNo: tailoringInt(json, 'shape_style_no'),
      styleName: tailoringText(json, 'style_name'),
      typeNo: tailoringInt(json, 'type_no'),
    );
  }
}

/// حالة سير من قاموس ORDSTATE مع الحالة التالية
/// A workflow stage from the ORDSTATE dictionary, with its successor.
class TailoringStage {
  final int ordsid;
  final String? ordsname;
  final int? nextOrdsid;
  final bool active;

  const TailoringStage({
    this.ordsid = 0,
    this.ordsname,
    this.nextOrdsid,
    this.active = true,
  });

  factory TailoringStage.fromJson(Map<String, dynamic> json) {
    return TailoringStage(
      ordsid: tailoringInt(json, 'ordsid') ?? 0,
      ordsname: tailoringText(json, 'ordsname'),
      nextOrdsid: tailoringInt(json, 'next_ordsid'),
      active: (tailoringInt(json, 'active') ?? 1) != 0,
    );
  }
}

/// المرجعيات المشتركة: تسميات المقاسات + الأنواع + الأشكال + الحالات
/// The shared reference data: measurement labels, types, shapes and stages.
class TailoringReference {
  final Map<String, String> measureLabels;
  final List<TailoringType> types;
  final List<TailoringStyle> styles;
  final List<TailoringStage> stages;

  const TailoringReference({
    this.measureLabels = const {},
    this.types = const [],
    this.styles = const [],
    this.stages = const [],
  });

  /// مرجع فارغ يُستخدم كقيمة ابتدائية قبل وصول البيانات — يمنع تحقق `null` في الشاشات
  /// An empty reference used before data arrives, so screens never check for null.
  static const TailoringReference empty = TailoringReference();

  factory TailoringReference.fromJson(Map<String, dynamic> json) {
    return TailoringReference(
      measureLabels: _readLabels(json['measure_labels']),
      types: (json['types'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TailoringType.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      styles: (json['styles'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TailoringStyle.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      stages: (json['stages'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TailoringStage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

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

  /// الأنواع الفعّالة فقط — القوائم لا تعرض المعطّل
  /// Active types only — the pickers never show disabled entries.
  List<TailoringType> get activeTypes =>
      types.where((t) => t.active && t.typeName != null).toList();

  /// أشكال نوع معيّن، أو كل الأشكال عند غياب النوع
  /// The shapes of one type, or every shape when the type is absent.
  List<TailoringStyle> stylesForType(int? typeNo) {
    if (typeNo == null) {
      return styles.where((s) => s.styleName != null).toList();
    }
    return styles
        .where((s) => s.typeNo == typeNo && s.styleName != null)
        .toList();
  }

  /// الحالات الفعّالة مرتّبة برقمها — تُغذّي خط سير المتابعة
  /// The active stages ordered by number — they feed the progress stepper.
  List<TailoringStage> get activeStages {
    final list = stages.where((s) => s.active).toList()
      ..sort((a, b) => a.ordsid.compareTo(b.ordsid));
    return list;
  }

  /// تسمية مقياس مع الرجوع إلى مفتاحه
  /// A measurement's label, falling back to its key.
  String labelFor(String key) {
    final label = measureLabels[key];
    return label == null || label.trim().isEmpty ? key : label;
  }
}
