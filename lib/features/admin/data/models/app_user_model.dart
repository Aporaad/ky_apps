import '../../../../core/utils/json_value_utils.dart';

/// نموذج مستخدم الإدارة — مطابق لصف `GET /users` و`GET /users/{id}`
/// Admin user model — matches the `GET /users` and `GET /users/{id}` rows.
///
/// المفاتيح snake_case حرفياً لأن `UserAdminController::shape()` يبنيها كذلك، ونفس الدالة تبني
/// صفَّ القائمة وصفَّ التفاصيل، فتوحيد القراءة هنا يعني أن الشاشتين تراهما معاً.
/// Keys are snake_case verbatim because `UserAdminController::shape()` builds them that way and
/// feeds both the list row and the detail row — one reader serves both screens.
///
/// الحقول `grantedCodes`/`grantedIds`/`lastActivityOn` لا تظهر إلا في التفاصيل، فتبقى فارغة في
/// القائمة؛ والاعتماد عليها في شاشة القائمة يعني صفراً دائماً لا خطأً.
/// The grants and last-activity fields only appear on the detail route, so they stay empty in the
/// list — relying on them there would silently show zeroes.
class AppUserModel {
  final int userId;
  final String userNameEn;
  final String? userNameAr;

  /// نوع الحساب: 1 موظف و2 عميل (قرار D5)
  /// Account type: 1 staff, 2 customer (decision D5).
  final int userType;
  final String userTypeLabel;

  /// حالة التفعيل — `IS_ACTIVATED` رقمي في أوراكل فيصل 1/0 لا bool
  /// Activation state — `IS_ACTIVATED` is numeric in Oracle, so it arrives as 1/0.
  final bool isActivated;

  /// صفة مدير النظام (قرار D1): تتجاوز جدول المنح في الخادم والواجهة معاً
  /// System-admin flag (decision D1): bypasses the grant table on both sides.
  final bool isAdmin;

  final int? branchNo;
  final String? note;
  final int? cashAccNo;
  final bool allowBankAcc;
  final bool biometricEnabled;
  final String? deviceName;
  final String? platform;

  /// عدد المنح النشطة — عمود مشتق في استعلام القائمة، لا يُقرأ من جدول المنح في الواجهة
  /// Active grant count — a derived column of the list query, never re-counted client-side.
  final int grantsCount;

  final DateTime? createdOn;
  final int? createdBy;
  final DateTime? lastUpdatedOn;
  final int? lastUpdatedBy;

  /// أكواد المنح الحالية (التفاصيل فقط) — تُحمَّل قبل فتح شاشة المنح أو نموذج التعديل
  /// Current grant codes (detail only) — loaded before opening the assign screen or edit form.
  final List<String> grantedCodes;
  final List<int> grantedIds;
  final DateTime? lastActivityOn;

  const AppUserModel({
    required this.userId,
    required this.userNameEn,
    this.userNameAr,
    this.userType = 1,
    this.userTypeLabel = 'موظف',
    this.isActivated = true,
    this.isAdmin = false,
    this.branchNo,
    this.note,
    this.cashAccNo,
    this.allowBankAcc = false,
    this.biometricEnabled = false,
    this.deviceName,
    this.platform,
    this.grantsCount = 0,
    this.createdOn,
    this.createdBy,
    this.lastUpdatedOn,
    this.lastUpdatedBy,
    this.grantedCodes = const [],
    this.grantedIds = const [],
    this.lastActivityOn,
  });

  /// الاسم المعروض: العربي أولاً ثم اللاتيني ثم رقم المستخدم — لا اسم فارغ أبداً
  /// Display name: Arabic first, then Latin, then the user number — never an empty label.
  String get displayName {
    final arabic = (userNameAr ?? '').trim();
    if (arabic.isNotEmpty) return arabic;
    if (userNameEn.trim().isNotEmpty) return userNameEn.trim();

    return 'مستخدم $userId';
  }

  bool get isEmployee => userType != 2;

  bool get isCustomer => userType == 2;

  /// هل الفروع محجوبة؟ فرع المستخدم الحالي يُعرض في البطاقة للتفريق بين متشابهَي الاسم
  /// Branch label shown on the card to separate users with the same name.
  String get branchLabel => branchNo == null ? 'بلا فرع' : 'فرع $branchNo';

  /// هل وصلت منح التفاصيل؟ false في صفوف القائمة — والفرق يمنع «صلاحيات: 0» الخاطئ
  /// Did the detail grants arrive? False for list rows — the distinction prevents a wrong
  /// «صلاحيات: 0» rendering.
  bool get hasGrantDetail => grantedCodes.isNotEmpty || grantedIds.isNotEmpty;

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    // قراءة مزدوجة الحالة: الخادم يرسل snake_case، لكن أي مسار يمرّر صف أوراكل الخام يصل UPPER
    // Dual-case reads: the controller sends snake_case, but any raw Oracle row would be UPPER.
    return AppUserModel(
      userId: JsonValues.asInt(json['user_id'] ?? json['USER_ID']),
      userNameEn: JsonValues.textOrEmpty(
        json['user_name_en'] ?? json['USER_NAME_EN'],
      ),
      userNameAr: JsonValues.asArabic(
        json['user_name_ar'] ?? json['USER_NAME_AR'],
      ),
      userType: JsonValues.asInt(
        json['user_type'] ?? json['USER_TYPE'],
        fallback: 1,
      ),
      userTypeLabel:
          JsonValues.asArabic(json['user_type_label']) ??
          ((json['user_type'] ?? json['USER_TYPE']) == 2 ? 'عميل' : 'موظف'),
      isActivated: JsonValues.asFlag(
        json['is_activated'] ?? json['IS_ACTIVATED'],
      ),
      isAdmin: JsonValues.asBool(json['is_admin'] ?? json['IS_ADMIN']),
      branchNo: JsonValues.asIntOrNull(json['branch_no'] ?? json['BRANCH_NO']),
      note: JsonValues.asArabic(json['note'] ?? json['NOTE']),
      cashAccNo: JsonValues.asIntOrNull(
        json['cash_acc_no'] ?? json['CASH_ACC_NO'],
      ),
      allowBankAcc: JsonValues.asFlag(
        json['allow_bank_acc'] ?? json['ALLOW_BANK_ACC'],
      ),
      biometricEnabled: JsonValues.asFlag(
        json['biometric_enabled'] ?? json['BIOMETRIC_ENABLED'],
      ),
      deviceName: JsonValues.asArabic(json['device_name'] ?? json['DEVICE_NAME']),
      platform: JsonValues.asText(json['platform'] ?? json['PLATFORM']),
      grantsCount: JsonValues.asInt(
        json['grants_count'] ?? json['GRANTS_COUNT'] ?? json['grant_count'],
      ),
      createdOn: JsonValues.asDate(json['created_on'] ?? json['CREATED_ON']),
      createdBy: JsonValues.asIntOrNull(
        json['created_by'] ?? json['CREATED_BY'],
      ),
      lastUpdatedOn: JsonValues.asDate(
        json['last_updated_on'] ?? json['LAST_UPDATED_ON'],
      ),
      lastUpdatedBy: JsonValues.asIntOrNull(
        json['last_updated_by'] ?? json['LAST_UPDATED_BY'],
      ),
      grantedCodes: JsonValues.asStringList(
        json['granted_codes'] ?? json['GRANTED_CODES'],
      ),
      grantedIds: JsonValues.asIntList(json['granted_ids'] ?? json['GRANTED_IDS']),
      lastActivityOn: JsonValues.asDate(
        json['last_activity_on'] ?? json['LAST_ACTIVITY_ON'],
      ),
    );
  }

  /// نسخة قابلة للتخزين والعرض — المفاتيح كما يرسلها الخادم لا كما خزّنها العميل
  /// A storable/renderable map — keyed exactly as the server sends it.
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'user_name_en': userNameEn,
    'user_name_ar': userNameAr,
    'user_type': userType,
    'user_type_label': userTypeLabel,
    'is_activated': isActivated ? 1 : 0,
    'is_admin': isAdmin,
    'branch_no': branchNo,
    'note': note,
    'cash_acc_no': cashAccNo,
    'allow_bank_acc': allowBankAcc ? 1 : 0,
    'biometric_enabled': biometricEnabled ? 1 : 0,
    'device_name': deviceName,
    'platform': platform,
    'grants_count': grantsCount,
    'granted_codes': grantedCodes,
    'granted_ids': grantedIds,
  };

  AppUserModel copyWith({
    int? userId,
    String? userNameEn,
    String? userNameAr,
    int? userType,
    String? userTypeLabel,
    bool? isActivated,
    bool? isAdmin,
    int? branchNo,
    String? note,
    int? cashAccNo,
    bool? allowBankAcc,
    bool? biometricEnabled,
    String? deviceName,
    String? platform,
    int? grantsCount,
    DateTime? createdOn,
    int? createdBy,
    DateTime? lastUpdatedOn,
    int? lastUpdatedBy,
    List<String>? grantedCodes,
    List<int>? grantedIds,
    DateTime? Function()? lastActivityOn,
  }) {
    return AppUserModel(
      userId: userId ?? this.userId,
      userNameEn: userNameEn ?? this.userNameEn,
      userNameAr: userNameAr ?? this.userNameAr,
      userType: userType ?? this.userType,
      userTypeLabel: userTypeLabel ?? this.userTypeLabel,
      isActivated: isActivated ?? this.isActivated,
      isAdmin: isAdmin ?? this.isAdmin,
      branchNo: branchNo ?? this.branchNo,
      note: note ?? this.note,
      cashAccNo: cashAccNo ?? this.cashAccNo,
      allowBankAcc: allowBankAcc ?? this.allowBankAcc,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      grantsCount: grantsCount ?? this.grantsCount,
      createdOn: createdOn ?? this.createdOn,
      createdBy: createdBy ?? this.createdBy,
      lastUpdatedOn: lastUpdatedOn ?? this.lastUpdatedOn,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      grantedCodes: grantedCodes ?? this.grantedCodes,
      grantedIds: grantedIds ?? this.grantedIds,
      // خدعة الإغلاق: null يجب أن «يمسح» الموعد لا أن يبقيه — موعد آخر نشاط قد ينتهي بالحذف
      // Closure trick: null must clear the deadline, not keep it — last activity can end as null.
      lastActivityOn:
          lastActivityOn != null ? lastActivityOn() : this.lastActivityOn,
    );
  }
}
