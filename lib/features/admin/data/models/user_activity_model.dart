import '../../../../core/utils/json_value_utils.dart';

/// سجل نشاط واحد من `GET /users/{id}/activity` أو السجل العام
/// One activity row from the per-user or general audit trail.
///
/// الصف يُقرأ كما يبنيه `UserAdminController::shapeActivity()`: معرّفات رقمية، وحقل `entity_id`
/// نصّي لأن الجدول يخزّنه كذلك (قد يكون رقم عميل أو رقم حركة أو اسم جدول)، و`description_ar`
/// عربي مُصلَّح في الخادم ثم هنا احتياطاً.
/// The row is read exactly as shapeActivity() builds it: numeric ids, entity_id as text (the column
/// really is text — a customer number, a journal id, or a table name), and Arabic description
/// repaired server-side then again here defensively.
class UserActivityModel {
  final int activityId;

  /// الفاعل — من نفّذ العملية
  /// The actor that performed the action.
  final int? userId;

  /// المستهدف — على من نُفّذت (مخزوّ في مسار إدارة المستخدمين)
  /// The target user, set on the admin-management paths.
  final int? targetUserId;

  /// الكود الكامل للعملية (`users.create`) أو اسم فعل المصادقة (`login_failed`)
  /// The full action code (`users.create`) or an auth verb (`login_failed`).
  final String actionCode;

  /// القسم المستخرج من الكود — للفلترة البصرية دون إعادة تقطيع في كل بطاقة
  /// Module part of the code, pre-read so cards don't re-split it on every repaint.
  final String? moduleCode;
  final String? entityType;
  final String? entityId;
  final String descriptionAr;

  /// `success` أو `failed` — والفاشل هو ما يهم المراجع الأمني
  /// `success` or `failed`; the failed rows are what a security reviewer wants.
  final String status;
  final String? ipAddress;
  final String? platform;
  final DateTime? createdOn;

  const UserActivityModel({
    required this.activityId,
    this.userId,
    this.targetUserId,
    this.actionCode = '',
    this.moduleCode,
    this.entityType,
    this.entityId,
    this.descriptionAr = '',
    this.status = 'success',
    this.ipAddress,
    this.platform,
    this.createdOn,
  });

  bool get isSuccess => status == 'success';

  /// تسمية الحالة بالعربية في الشارة
  /// Arabic status label for the badge.
  String get statusLabel => isSuccess ? 'ناجحة' : 'فاشلة';

  /// القسم للعرض: العمود المُرسل أو بادئة الكود — فلا بطاقة بلا ترويسة
  /// Module for display: the sent column or the code prefix, so no card lacks a header.
  String get moduleLabel {
    final module = (moduleCode ?? '').trim();
    if (module.isNotEmpty) return module;
    final dot = actionCode.indexOf('.');

    return dot > 0 ? actionCode.substring(0, dot) : actionCode;
  }

  factory UserActivityModel.fromJson(Map<String, dynamic> json) {
    return UserActivityModel(
      activityId: JsonValues.asInt(json['activity_id'] ?? json['ACTIVITY_ID']),
      userId: JsonValues.asIntOrNull(json['user_id'] ?? json['USER_ID']),
      targetUserId: JsonValues.asIntOrNull(
        json['target_user_id'] ?? json['TARGET_USER_ID'],
      ),
      actionCode: JsonValues.textOrEmpty(
        json['action_code'] ?? json['ACTION_CODE'],
      ),
      moduleCode: JsonValues.asText(json['module_code'] ?? json['MODULE_CODE']),
      entityType: JsonValues.asText(json['entity_type'] ?? json['ENTITY_TYPE']),
      entityId: JsonValues.asText(json['entity_id'] ?? json['ENTITY_ID']),
      descriptionAr: JsonValues.arabicOrEmpty(
        json['description_ar'] ?? json['DESCRIPTION_AR'],
      ),
      status:
          JsonValues.asText(json['status'] ?? json['STATUS']) ?? 'success',
      ipAddress: JsonValues.asText(json['ip_address'] ?? json['IP_ADDRESS']),
      platform: JsonValues.asText(json['platform'] ?? json['PLATFORM']),
      createdOn: JsonValues.asDate(json['created_on'] ?? json['CREATED_ON']),
    );
  }

  Map<String, dynamic> toJson() => {
    'activity_id': activityId,
    'user_id': userId,
    'target_user_id': targetUserId,
    'action_code': actionCode,
    'module_code': moduleCode,
    'entity_type': entityType,
    'entity_id': entityId,
    'description_ar': descriptionAr,
    'status': status,
    'ip_address': ipAddress,
    'platform': platform,
  };
}
