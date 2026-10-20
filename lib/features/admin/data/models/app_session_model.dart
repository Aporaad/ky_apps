import '../../../../core/utils/json_value_utils.dart';

/// جلسة (توكن) واحدة من `GET /sessions`
/// One session (token) from `GET /sessions`.
///
/// الجلسات تُقرأ من جدول توكنات Sanctum عند أوراكل، فصفّ الجلسة لا يُحذف مطلقاً: الإنهاء يدفع
/// `EXPIRES_AT` إلى الماضي. لذلك تبقى الجلسات المنتهية مرئية في الشاشة، والتمييز بينها وبين
/// النشطة هو `status` الذي يبنيه الخادم لا حالة الحذف.
/// Sessions are read from Sanctum's token table and are never deleted: terminating pushes
/// EXPIRES_AT into the past. Expired rows therefore stay visible, and status — built server-side,
/// not a deletion flag — is what separates them.
class AppSessionModel {
  final int tokenId;
  final int userId;
  final String? tokenName;
  final String userNameEn;
  final String? userNameAr;
  final int userType;
  final String userTypeLabel;
  final bool isAdmin;
  final bool isActivated;
  final int? branchNo;
  final String? deviceName;
  final String? platform;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final DateTime? expiresAt;

  /// حالة الخادم: `active` أو `expired` أو `disabled`
  /// Server status: `active`, `expired`, or `disabled`.
  final String status;
  final String statusLabel;

  /// هل هذه جلسة هذا الجهاز؟ الخادم يقارن معرّف التوكن الحالي
  /// Is this the current device's session? The server compares the active token id.
  final bool isCurrent;

  const AppSessionModel({
    required this.tokenId,
    required this.userId,
    this.tokenName,
    this.userNameEn = '',
    this.userNameAr,
    this.userType = 1,
    this.userTypeLabel = 'موظف',
    this.isAdmin = false,
    this.isActivated = true,
    this.branchNo,
    this.deviceName,
    this.platform,
    this.createdAt,
    this.lastActivityAt,
    this.expiresAt,
    this.status = 'active',
    this.statusLabel = 'نشطة',
    this.isCurrent = false,
  });

  bool get isActive => status == 'active';

  bool get isEmployee => userType != 2;

  /// الاسم المعروض لصاحب الجلسة
  /// Display name of the session owner.
  String get displayName {
    final arabic = (userNameAr ?? '').trim();
    if (arabic.isNotEmpty) return arabic;
    if (userNameEn.trim().isNotEmpty) return userNameEn.trim();

    return 'مستخدم $userId';
  }

  /// الدقائق المتبقية محسوبة من `expires_at` لا من `minutes_left` الذي يرسله الخادم
  /// Minutes remaining, derived from `expires_at` rather than the server's `minutes_left`.
  ///
  /// `minutes_left` يبنيه الخادم بـ `diffInMinutes(now())` مع `max(0, …)`: أي فرق بين منطقة الخادم
  /// الزمنية ووقت أوراكل المحلي، أو دقائق كسرية مقطوعة، يدفع الفرق إلى السالب أو الصفر فتظهر جلسة
  /// حيّة «0 دقيقة». الحساب هنا يقارن لحظة الانتهاء المرسلة بساعة الجهاز نفسه، وهو ما يطابق ما
  /// يقرّر به `SessionPolicy` فعلياً.
  /// The server computes it as `max(0, diffInMinutes(now()))`, so any server-timezone skew against
  /// Oracle-local time — or truncated fractional minutes — drives it to zero and a live session
  /// reads «0 دقيقة». Here the sent deadline is compared to the device clock, which is the same
  /// quantity SessionPolicy actually decides on.
  int minutesLeftOf(DateTime now) {
    final deadline = expiresAt;
    if (deadline == null) return 0;
    final remaining = deadline.difference(now).inMinutes;

    return remaining > 0 ? remaining : 0;
  }

  /// الوصف الزمني المتبقي للبطاقة: «ساعتان و15 دقيقة» أو «منتهية»
  /// Remaining-time caption for the card: hours and minutes, or «منتهية».
  String remainingLabel(DateTime now) {
    if (!isActive) return statusLabel.isEmpty ? 'منتهية' : statusLabel;
    final minutes = minutesLeftOf(now);
    if (minutes <= 0) return 'على وشك الانتهاء';

    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest دقيقة';
    if (rest == 0) return _hoursLabel(hours);

    return '${_hoursLabel(hours)} و$rest دقيقة';
  }

  /// صيغة الساعات بالعربية مع مراعاة المثنى والجمع
  /// Arabic hours label with dual and plural forms.
  static String _hoursLabel(int hours) {
    if (hours == 1) return 'ساعة';
    if (hours == 2) return 'ساعتان';

    return '$hours ساعة';
  }

  factory AppSessionModel.fromJson(Map<String, dynamic> json) {
    final status = JsonValues.asText(json['status'] ?? json['STATUS']) ?? 'active';

    return AppSessionModel(
      tokenId: JsonValues.asInt(json['token_id'] ?? json['TOKEN_ID']),
      userId: JsonValues.asInt(json['user_id'] ?? json['USER_ID']),
      tokenName: JsonValues.asText(json['token_name'] ?? json['TOKEN_NAME']),
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
          'موظف',
      isAdmin: JsonValues.asBool(json['is_admin'] ?? json['IS_ADMIN']),
      isActivated: JsonValues.asFlag(
        json['is_activated'] ?? json['IS_ACTIVATED'],
        fallback: true,
      ),
      branchNo: JsonValues.asIntOrNull(json['branch_no'] ?? json['BRANCH_NO']),
      deviceName: JsonValues.asArabic(json['device_name'] ?? json['DEVICE_NAME']),
      platform: JsonValues.asText(json['platform'] ?? json['PLATFORM']),
      createdAt: JsonValues.asDate(json['created_at'] ?? json['CREATED_AT']),
      lastActivityAt: JsonValues.asDate(
        json['last_activity_at'] ?? json['LAST_ACTIVITY_AT'],
      ),
      expiresAt: JsonValues.asDate(json['expires_at'] ?? json['EXPIRES_AT']),
      status: status,
      statusLabel:
          JsonValues.asArabic(json['status_label'] ?? json['STATUS_LABEL']) ??
          (status == 'active' ? 'نشطة' : (status == 'disabled' ? 'حساب معطّل' : 'منتهية')),
      isCurrent: JsonValues.asBool(json['is_current'] ?? json['IS_CURRENT']),
    );
  }

  Map<String, dynamic> toJson() => {
    'token_id': tokenId,
    'user_id': userId,
    'token_name': tokenName,
    'user_name_en': userNameEn,
    'user_name_ar': userNameAr,
    'user_type': userType,
    'is_admin': isAdmin,
    'is_activated': isActivated ? 1 : 0,
    'branch_no': branchNo,
    'device_name': deviceName,
    'platform': platform,
    'status': status,
    'is_current': isCurrent,
  };
}
