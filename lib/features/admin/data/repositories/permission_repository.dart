import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_result.dart';
import '../models/app_permission_model.dart';
import '../../../../core/utils/json_value_utils.dart';

/// منح مستخدم واحد كما يعيدها `GET /users/{id}/permissions`
/// One user's grants as returned by `GET /users/{id}/permissions`.
///
/// الفرق بين `grantedCodes` و`effectiveCodes` هو ما يجعل شاشة المنح صحيحة لمدير: المدير قد لا
/// يملك سطراً واحداً في جدول المنح و`effectiveCodes` عنده هي الكتالوج كله، فلو قرأت الشاشة
/// الأولى وحدها لظهر مديرٌ بلا أي صلاحية.
/// The gap between grantedCodes and effectiveCodes is what makes the grant screen correct for an
/// admin: an admin may hold zero rows in the grant table while effectiveCodes is the whole
/// catalog. Rendering only the first would show an admin with no permissions at all.
class UserGrants {
  final int userId;
  final String userNameEn;
  final String? userNameAr;
  final bool isAdmin;
  final List<String> grantedCodes;
  final List<int> grantedIds;
  final List<String> effectiveCodes;

  const UserGrants({
    required this.userId,
    this.userNameEn = '',
    this.userNameAr,
    this.isAdmin = false,
    this.grantedCodes = const [],
    this.grantedIds = const [],
    this.effectiveCodes = const [],
  });

  /// الاسم المعروض في رأس شاشة المنح
  /// Display name for the grant screen's header.
  String get displayName {
    final arabic = (userNameAr ?? '').trim();
    if (arabic.isNotEmpty) return arabic;
    if (userNameEn.trim().isNotEmpty) return userNameEn.trim();

    return 'مستخدم $userId';
  }

  /// هل الصلاحية ممنوحة فعلاً في الجدول؟ التحديد المبدئي في شاشة المنح يُبنى عليها وحدها
  /// Is the code an actual grant row? The picker's initial selection uses only this.
  bool isSelected(String code) => grantedCodes.contains(code);

  factory UserGrants.fromJson(Map<String, dynamic> json) {
    return UserGrants(
      userId: JsonValues.asInt(json['user_id'] ?? json['USER_ID']),
      userNameEn: JsonValues.textOrEmpty(
        json['user_name_en'] ?? json['USER_NAME_EN'],
      ),
      userNameAr: JsonValues.asArabic(
        json['user_name_ar'] ?? json['USER_NAME_AR'],
      ),
      isAdmin: JsonValues.asBool(json['is_admin'] ?? json['IS_ADMIN']),
      grantedCodes: JsonValues.asStringList(
        json['granted_codes'] ?? json['GRANTED_CODES'],
      ),
      grantedIds: JsonValues.asIntList(json['granted_ids'] ?? json['GRANTED_IDS']),
      effectiveCodes: JsonValues.asStringList(
        json['effective_permissions'] ?? json['EFFECTIVE_PERMISSIONS'],
      ),
    );
  }
}

/// مستودع كتالوج الصلاحيات ومنحها — `/permissions` و`/users/{id}/permissions`
/// Permission catalog and grants repository.
class PermissionRepository {
  final DioClient client;

  PermissionRepository({required this.client});

  /// الكتالوج كاملاً مجمّعاً بالأقسام، بترتيب الخادم (`SORT_ORDER`)
  /// The full catalog grouped by section, in the server's SORT_ORDER.
  ///
  /// الترتيب لا يُعاد هنا: الخادم يبني المجموعات من `PermissionCatalog::grouped()`، فإعادة
  /// الترتيب محلياً تعني مصدرين يتباعدان عند إضافة قسم جديد.
  /// No re-sorting here: the server builds the groups from PermissionCatalog::grouped(), so
  /// reordering locally would create a second source that drifts when a module is added.
  Future<List<AppPermissionModule>> fetchCatalog({
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/permissions',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) return const [];
      final data = body['data'];
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(AppPermissionModule.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const [];
      rethrow;
    }
  }

  /// منح مستخدم، أو null عند 404 — وشاشة المنح تعرض حالة خطأ لا قائمة فراغ
  /// A user's grants, or null on 404 — the grant screen then shows an error, not an empty list.
  Future<UserGrants?> fetchUserGrants(
    int userId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/users/$userId/permissions',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      final data = body['data'];
      if (body['success'] == true && data is Map<String, dynamic>) {
        return UserGrants.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  /// استبدال منح مستخدم بالكامل — قائمة فارغة تعني «سحب كل الصلاحيات»
  /// Replace a user's grants completely — an empty list means revoke everything.
  ///
  /// `logoutOthers` true افتراضياً في الخادم: تغيير المنح دون إنهاء الجلسات يترك جلسة قائمة
  /// تمارس صلاحيات سحبت للتو، فالخادم يدفع `EXPIRES_AT` إلى الماضي والمستخدم يُقفل في طلبه التالي.
  /// logoutOthers defaults true server-side: changing grants without ending sessions would leave a
  /// live token exercising rights just revoked, so the server pushes EXPIRES_AT into the past.
  Future<AdminResult<UserGrants>> syncUserPermissions(
    int userId,
    List<String> codes, {
    bool logoutOthers = true,
  }) async {
    try {
      final resp = await client.dio.put(
        '/users/$userId/permissions',
        data: {'permissions': codes, 'logout_others': logoutOthers},
      );
      final body = resp.data as Map<String, dynamic>;

      return AdminResult.fromBody(
        body,
        statusCode: resp.statusCode ?? 200,
        mapper: UserGrants.fromJson,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر حفظ الصلاحيات / Could not save the permissions',
      );
    }
  }
}
