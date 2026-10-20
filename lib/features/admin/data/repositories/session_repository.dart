import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_result.dart';
import '../models/app_session_model.dart';
import '../models/paged_result.dart';

/// حالات الفلترة التي يعرّفها `SessionAdminController::conditions()`
/// The filter values SessionAdminController::conditions() actually recognises.
const List<String> kSessionStatuses = ['all', 'active', 'expired', 'disabled'];

/// مستودع الجلسات النشطة — `/sessions` بكل أفعاله
/// Active sessions repository.
///
/// لا مسار لقراءة جلسة واحدة في الخادم: القائمة وحدها، فالتصميم هنا لا يخترع endpoint غير
/// موجود. الإنهاء لا يحذف الصف: يدفع `EXPIRES_AT` إلى الماضي، ولهذا تبقى الجلسات المنتهية
/// مرئية في الشاشة وتُميَّز بـ `status`.
/// There is no single-session route on the server, so this layer does not invent one. Terminating
/// never deletes a row — it pushes EXPIRES_AT into the past — which is why expired sessions stay
/// visible and are distinguished only by status.
class SessionRepository {
  final DioClient client;

  SessionRepository({required this.client});

  /// قائمة الجلسات مع الفلترة والبحث والتصفح
  /// The session list with filtering, search, and pagination.
  Future<PagedResult<AppSessionModel>> fetchSessions({
    int? userId,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/sessions',
        queryParameters: {
          // المعرّف يُرسل فقط إن كان موجباً: الصفر يعني «بلا فلتر» في الخادم
          // Send the id only when positive: zero means "no filter" server-side.
          if (userId != null && userId > 0) 'user_id': userId,
          if (status != 'all' && kSessionStatuses.contains(status)) 'status': status,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return PagedResult.fromJson(
          body,
          AppSessionModel.fromJson,
        );
      }

      return const PagedResult<AppSessionModel>.empty();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const PagedResult<AppSessionModel>.empty();
      }
      rethrow;
    }
  }

  /// إنهاء جلسة واحدة بمعرّف التوكن
  /// Terminate one session by token id.
  Future<AdminResult<Map<String, dynamic>>> terminateSession(int tokenId) async {
    try {
      final resp = await client.dio.delete('/sessions/$tokenId');

      return AdminResult.raw(
        resp.data as Map<String, dynamic>,
        statusCode: resp.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر إنهاء الجلسة / Could not terminate the session',
      );
    }
  }

  /// إنهاء كل جلسات مستخدم — يُستخدم بعد تعطيل الحساب أو سحب صلاحياته
  /// Terminate every session of a user — used after deactivating or stripping rights.
  Future<AdminResult<Map<String, dynamic>>> terminateUserSessions(
    int userId,
  ) async {
    try {
      final resp = await client.dio.delete('/sessions/user/$userId');

      return AdminResult.raw(
        resp.data as Map<String, dynamic>,
        statusCode: resp.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر إنهاء جلسات المستخدم / Could not end the user sessions',
      );
    }
  }
}
