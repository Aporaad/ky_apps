/// لقطة حالة الصلاحيات كما يقرّ بها الخادم
/// A snapshot of the IBAC state exactly as the server asserts it.
///
/// مصدرها `GET /auth/permissions` (ومنح الدمج في `login`/`me`)، وهي الحِمل الذي يُبنى عليه
/// كل قرار حجب في الواجهة. تُمرَّر ككائن واحد بدل ثلاث قيم متفرقة حتى لا يُنسى حقل في مسار.
/// Produced by `GET /auth/permissions` (and embedded in the sign-in payloads). It travels as one
/// object rather than three loose values so no call site can forget a field.
class PermissionSnapshot {
  final int userId;
  final bool isAdmin;
  final List<String> permissions;
  final List<String> modules;

  /// نهاية الجلسة كنص الخادم `YYYY-MM-DD HH:MM:SS`؛ null تعني بلا نهاية معلومة
  /// The server's session deadline text; null means nothing was asserted about expiry.
  final String? sessionExpiresAt;

  const PermissionSnapshot({
    this.userId = 0,
    this.isAdmin = false,
    this.permissions = const [],
    this.modules = const [],
    this.sessionExpiresAt,
  });

  /// لقطة فارغة = لا صلاحيات، تُستخدم عند الفشل لأن الرفض هو الوضع الآمن
  /// An empty snapshot denies everything; it is the failure value because deny is the safe state.
  static const PermissionSnapshot denied = PermissionSnapshot();

  factory PermissionSnapshot.fromJson(Map<String, dynamic> json) {
    return PermissionSnapshot(
      userId: _parseInt(json['user_id'] ?? json['USER_ID']),
      isAdmin: _parseBool(json['is_admin'] ?? json['IS_ADMIN']),
      permissions: _parseCodes(json['permissions']),
      modules: _parseCodes(json['modules']),
      sessionExpiresAt: _parseNullableString(
        json['session_expires_at'] ?? json['SESSION_EXPIRES_AT'],
      ),
    );
  }

  /// هل اللقطة خالية من أي منح؟ (تُستخدم لتفادي كتابة تخزين بلا معنى)
  /// Is the snapshot completely empty? Used to avoid persisting a meaningless state.
  bool get isEmpty => !isAdmin && permissions.isEmpty && modules.isEmpty;

  /// لقطة مدمجة فوق لقطة سابقة: تُبقي الخادم مصدر القرار، ولا تُرجع الحقول الغائبة إلى الصفر
  /// Merge over a previous snapshot: the server stays the decider, and absent keys are filled
  /// from the older copy only when the new payload omits them entirely.
  PermissionSnapshot mergeWith(PermissionSnapshot fallback) {
    return PermissionSnapshot(
      userId: userId != 0 ? userId : fallback.userId,
      isAdmin: isAdmin || fallback.isAdmin,
      permissions: permissions.isNotEmpty ? permissions : fallback.permissions,
      modules: modules.isNotEmpty ? modules : fallback.modules,
      sessionExpiresAt: sessionExpiresAt ?? fallback.sessionExpiresAt,
    );
  }

  // تحويلات دفاعية: أوراكل تعيد الأرقام نصوصاً والأسماء بأي حالة أحرف
  // Defensive casts: Oracle hands numbers as text and column names in either case.

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == '1' || text == 'true' || text == 'yes';
  }

  static String? _parseNullableString(dynamic value) {
    final text = value?.toString().trim();
    // `false` قيمة أوراكل العمود الفارغ عبر بعض مسارات القراءة — تعتبر فراغاً لا نصّاً
    // false is how some Oracle read paths hand back an empty column: treat it as absent.
    if (text == null || text.isEmpty || text == 'false') return null;
    return text;
  }

  static List<String> _parseCodes(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
