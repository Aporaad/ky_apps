import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_result.dart';
import '../models/app_user_model.dart';
import '../models/paged_result.dart';
import '../models/user_activity_model.dart';

/// أعمدة الفرز التي يسمح بها `UserAdminController::SORTABLE`
/// The sort columns `UserAdminController::SORTABLE` actually accepts.
///
/// أي اسم آخر لا ينفجر — الخادم يرجع لـ `user_id` — لكنه يعطي ترتيباً مختلفاً عن الظاهر في
/// الشاشة، فالقائمة هنا مطابقة للبيضاء لا للاختصار.
/// Any other name doesn't fail (the server falls back to user_id) but silently sorts differently
/// from what the picker shows, so this list mirrors the whitelist, not a shorthand.
const List<String> kUserSortableColumns = [
  'user_id',
  'user_name_ar',
  'user_name_en',
  'created_on',
  'is_activated',
  'user_type',
];

/// مستودع إدارة المستخدمين — `/users` بكل أفعاله وسجل نشاطه
/// User administration repository — all of `/users` plus its activity trail.
///
/// المسارات حروف ثابتة داخل المستودع (نمط `customer_repository.dart`) بلا سجل مسارات مركزي:
/// هذا المشروع لا يزال يعرف مسار كل ميزة في مستودعها، وإدراج سجل هنا سيجعل المصدرين يتباعدان.
/// Paths are literal here (the customer repository's pattern) — this project still keeps each
/// feature's routes in its own repository, and a central registry would create two sources of truth.
class AdminUserRepository {
  final DioClient client;

  AdminUserRepository({required this.client});

  /// قائمة المستخدمين مع البحث والفلترة والفرز والتصفح
  /// The user list with search, filters, sorting, and pagination.
  ///
  /// الفلاتر تُرسل للخادم ولا تُطبَّق محلياً: الترقيم والفرز «حسب الحالة» يحتاجان نفس ترتيب
  /// `ORDER BY` الذي يراه المستخدم، والتقطيع المحلي لصفحة واحدة يخدع العدّاد.
  /// Filters go to the server instead of being applied locally: paging and a sort by status need
  /// the same ORDER BY the user sees, and slicing one page locally would lie about the totals.
  Future<PagedResult<AppUserModel>> fetchUsers({
    String search = '',
    String status = 'all',
    String userType = 'all',
    bool adminOnly = false,
    String sort = 'user_id',
    String direction = 'asc',
    int page = 1,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/users',
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (status != 'all') 'status': status,
          if (userType != 'all') 'user_type': userType,
          if (adminOnly) 'admin_only': 1,
          'sort': kUserSortableColumns.contains(sort) ? sort : 'user_id',
          'direction': direction == 'desc' ? 'desc' : 'asc',
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return PagedResult.fromJson(
          body,
          AppUserModel.fromJson,
        );
      }

      return const PagedResult<AppUserModel>.empty();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const PagedResult<AppUserModel>.empty();
      // الأخطاء الأخرى تمر للمزوّد: شاشة الإدارة تُظهر حالة خطأ مع إعادة محاولة، لا قائمة فارغة
      // Other errors reach the notifier: an admin screen shows a retryable error, not an empty list.
      rethrow;
    }
  }

  /// مستخدم واحد بمنحه وآخر نشاطه — يُحمَّل قبل نموذج التعديل أو شاشة المنح
  /// One user with its grants and last activity — loaded before the edit form or grant screen.
  Future<AppUserModel?> fetchUser(
    int userId, {
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/users/$userId',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      final data = body['data'];
      if (body['success'] == true && data is Map<String, dynamic>) {
        return AppUserModel.fromJson(data);
      }

      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  /// إنشاء مستخدم مع منحُه في نفس الطلب (ذرّية واحدة في الخادم)
  /// Create a user together with its grants — one atomic server-side transaction.
  Future<AdminResult<AppUserModel>> createUser(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await client.dio.post('/users', data: payload);
      final body = resp.data as Map<String, dynamic>;

      return AdminResult.fromBody(
        body,
        statusCode: resp.statusCode ?? 201,
        mapper: AppUserModel.fromJson,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر إنشاء المستخدم / Could not create the user',
      );
    }
  }

  /// تعديل مستخدم — تُرسل المفاتيح المتغيّرة فقط (دلالة `sometimes` في الخادم)
  /// Update a user — only changed keys are sent, matching the server's `sometimes` rules.
  Future<AdminResult<AppUserModel>> updateUser(
    int userId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await client.dio.put('/users/$userId', data: payload);
      final body = resp.data as Map<String, dynamic>;

      return AdminResult.fromBody(
        body,
        statusCode: resp.statusCode ?? 200,
        mapper: AppUserModel.fromJson,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر حفظ التعديلات / Could not save the changes',
      );
    }
  }

  /// تفعيل/تعطيل — الخادم يُنهي جلسات المستخدم المعطَّل في نفس العملية
  /// Toggle activation — the server ends that user's sessions in the same operation.
  ///
  /// الحمولة خام `Map` لا نموذج مستخدم: الخادم يعيد `{user_id, is_activated, sessions_ended}`
  /// فقط، وتحويله لنموذج كامل كان سيملأ الاسم والفرع بقيم فارغة تُعرض خطأً في البطاقة.
  /// The payload is a raw map, not a user model: the server returns only those three facts, and
  /// forcing them into AppUserModel would fabricate an empty name and branch on the card.
  Future<AdminResult<Map<String, dynamic>>> toggleUser(int userId) async {
    try {
      final resp = await client.dio.patch('/users/$userId/toggle');
      final body = resp.data as Map<String, dynamic>;

      return AdminResult.raw(body, statusCode: resp.statusCode ?? 200);
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر تغيير حالة المستخدم / Could not change the user state',
      );
    }
  }

  /// حذف مستخدم — يمسح منحَه وتوكناته ويُبقي سجل التدقيق
  /// Delete a user — clears its grants and tokens but keeps the audit trail.
  Future<AdminResult<Map<String, dynamic>>> deleteUser(int userId) async {
    try {
      final resp = await client.dio.delete('/users/$userId');
      final body = resp.data as Map<String, dynamic>;

      return AdminResult.raw(body, statusCode: resp.statusCode ?? 200);
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر حذف المستخدم / Could not delete the user',
      );
    }
  }

  /// سجل نشاط مستخدم، مرتّباً `CREATED_ON DESC` في الخادم
  /// A user's activity trail, ordered CREATED_ON DESC by the server.
  Future<PagedResult<UserActivityModel>> fetchActivity(
    int userId, {
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/users/$userId/activity',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return PagedResult.fromJson(
          body,
          UserActivityModel.fromJson,
        );
      }

      return const PagedResult<UserActivityModel>.empty();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const PagedResult<UserActivityModel>.empty();
      }
      rethrow;
    }
  }
}
