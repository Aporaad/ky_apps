import '../../../../core/utils/json_value_utils.dart';

/// صلاحية واحدة من كتالوج `GET /permissions`
/// One permission from the `GET /permissions` catalog.
///
/// الكتالوج يُقرأ من الخادم لا من نسخة الواجهة (`permission_codes.dart`) لأن الواجهة هنا تحتاج
/// معرّف القاعدة (`permission_id`) وترتيب `sort_order` واسماً عربياً لكل فعل — وهي بيانات بذرتها
/// المرحلة 1، فأي قائمة محلية كانت ستتباعد عنها.
/// The catalog comes from the server, not the client-side code mirror, because this screen needs the
/// database id, the sort order, and the Arabic label seeded in phase 1. A local list would drift.
class AppPermissionModel {
  final int permissionId;
  final String permissionCode;
  final String actionCode;
  final String nameAr;
  final String? nameEn;

  /// الفعل الأساسي (عرض/إضافة/تعديل/حذف) — يُعرض بارزاً قبل «صلاحيات أخرى»
  /// Core action (view/create/update/delete) — shown above the «صلاحيات أخرى» group.
  final bool isCore;
  final int sortOrder;

  const AppPermissionModel({
    required this.permissionId,
    required this.permissionCode,
    required this.actionCode,
    required this.nameAr,
    this.nameEn,
    this.isCore = false,
    this.sortOrder = 0,
  });

  /// هل هي منح القسم كامل (`module.*`)؟ تُعرض وحدها في رأس المجموعة وتتلوّى تحتها الأفعال
  /// Is this the module-wide wildcard? It sits at the group head, above the individual actions.
  bool get isWildcard => actionCode == '*';

  /// التسمية الجاهزة للعرض: العربي ثم اللاتيني ثم الكود — لا خانة فارغة في الشاشة
  /// Display label: Arabic, then English, then the raw code — never an empty cell.
  String get label {
    final arabic = nameAr.trim();
    if (arabic.isNotEmpty) return arabic;
    final english = (nameEn ?? '').trim();

    return english.isNotEmpty ? english : permissionCode;
  }

  factory AppPermissionModel.fromJson(Map<String, dynamic> json) {
    return AppPermissionModel(
      permissionId: JsonValues.asInt(
        json['permission_id'] ?? json['PERMISSION_ID'],
      ),
      permissionCode: JsonValues.textOrEmpty(
        json['permission_code'] ?? json['PERMISSION_CODE'],
      ),
      actionCode:
          JsonValues.asText(json['action_code'] ?? json['ACTION_CODE']) ??
          JsonValues.asText(
            json['permission_code'] ?? json['PERMISSION_CODE'],
          )?.split('.').last ??
          '',
      nameAr: JsonValues.arabicOrEmpty(json['name_ar'] ?? json['NAME_AR']),
      nameEn: JsonValues.asText(json['name_en'] ?? json['NAME_EN']),
      isCore: JsonValues.asFlag(json['is_core'] ?? json['IS_CORE']),
      sortOrder: JsonValues.asInt(json['sort_order'] ?? json['SORT_ORDER']),
    );
  }

  Map<String, dynamic> toJson() => {
    'permission_id': permissionId,
    'permission_code': permissionCode,
    'action_code': actionCode,
    'name_ar': nameAr,
    'name_en': nameEn,
    'is_core': isCore ? 1 : 0,
    'sort_order': sortOrder,
  };
}

/// مجموعة قسم واحد في الكتالوج: معرّف القسم + عنوانه + صلاحياته بترتيب الخادم
/// One catalog section: module code, Arabic title, and its permissions in server order.
class AppPermissionModule {
  final String moduleCode;
  final String nameAr;

  /// الصلاحيات كما رتّبها الخادم (wildcard أولاً ثم الأساسية ثم الإضافية)
  /// Permissions exactly as the server ordered them (wildcard, core, then extras).
  final List<AppPermissionModel> permissions;

  const AppPermissionModule({
    required this.moduleCode,
    required this.nameAr,
    required this.permissions,
  });

  /// الأفعال الأساسية الظاهرة مباشرة في رأس المجموعة
  /// Core actions shown directly in the group header.
  List<AppPermissionModel> get corePermissions =>
      permissions.where((item) => item.isCore).toList(growable: false);

  /// الباقي داخل «صلاحيات أخرى» المطوي — حتى لا تبتلع مجموعة بـ 11 صلاحية الشاشةَ كلها
  /// The rest, folded under «صلاحيات أخرى» so an 11-permission module cannot swallow the screen.
  List<AppPermissionModel> get extraPermissions =>
      permissions.where((item) => !item.isCore).toList(growable: false);

  /// منح القسم كامل، وقد لا يوجد في قسم بلا wildcard
  /// The module-wide grant, absent in any module without a wildcard.
  AppPermissionModel? get wildcardPermission {
    for (final permission in permissions) {
      if (permission.isWildcard) return permission;
    }

    return null;
  }

  /// عنوان العرض: العربي من الكتالوج، وإن غاب يُترك معرّف القسم كما هو
  /// Display title: the catalog's Arabic, falling back to the raw module code.
  String get title => nameAr.trim().isNotEmpty ? nameAr.trim() : moduleCode;

  factory AppPermissionModule.fromJson(Map<String, dynamic> json) {
    final rows = json['permissions'] ?? json['PERMISSIONS'];

    return AppPermissionModule(
      moduleCode: JsonValues.textOrEmpty(
        json['module_code'] ?? json['MODULE_CODE'],
      ),
      nameAr: JsonValues.arabicOrEmpty(json['name_ar'] ?? json['NAME_AR']),
      permissions: rows is List
          ? rows
                .whereType<Map<String, dynamic>>()
                .map(AppPermissionModel.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'module_code': moduleCode,
    'name_ar': nameAr,
    'permissions': permissions.map((item) => item.toJson()).toList(),
  };
}
