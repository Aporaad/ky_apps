import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';
import '../models/permission_snapshot_model.dart';
import '../models/user_model.dart';

/// مستودع إدارة عمليات المصادقة
/// Authentication Repository
class AuthRepository {
  final DioClient _client;
  final SecureStorageService _storage;

  AuthRepository({
    required DioClient client,
    required SecureStorageService storage,
  })  : _client = client,
        _storage = storage;

  /// تسجيل الدخول
  Future<AuthResponse> login({
    required String username,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {
          'username': username,
          'password': password,
          'user_type': userType,
        },
      );

      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (authResponse.success && authResponse.token != null) {
        await _storage.saveToken(authResponse.token!);
        await _storage.saveUserType(userType);
        if (authResponse.user != null) {
          await _storage.saveUserId(authResponse.user!.id);
          await _storage.saveUserData(jsonEncode(authResponse.user!.toJson()));
          // المنح تُكتب هنا أيضاً: الإقلاع البارد التالي يجب أن يرسم الأقسام من القرص
          // Grants are written here too, so the next cold start can paint sections from disk
          await _persistUserPermissions(authResponse.user!);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = 'تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقاً';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMsg = errorData['message'].toString();
      }
      return AuthResponse(success: false, message: errorMsg);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// التحقق مما إذا كان المستخدم مسجل دخول بالفعل
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }

  /// جلب بيانات المستخدم المخزنة محلياً
  Future<UserModel?> getCachedUser() async {
    final data = await _storage.getUserData();
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {
      // تجاهل أخطاء الشبكة أثناء الخروج
    } finally {
      await _storage.clearAll();
    }
  }

  // ── المقاييس الحيوية (Biometric) ────────────────────────────

  /// تسجيل الجهاز للمصادقة البيومترية (POST /auth/biometric/register)
  Future<bool> registerBiometric({
    required String deviceToken,
    required String deviceName,
    required String platform,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.biometricRegister,
        data: {
          'device_token': deviceToken,
          'device_name':  deviceName,
          'platform':     platform,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// تسجيل الدخول بالبصمة (POST /auth/biometric/login)
  Future<AuthResponse> biometricLogin({
    required int userId,
    required String deviceToken,
    required String userType,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.biometricLogin,
        data: {
          'user_id':      userId,
          'device_token': deviceToken,
        },
      );

      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (authResponse.success && authResponse.token != null) {
        await _storage.saveToken(authResponse.token!);
        await _storage.saveUserType(userType);
        if (authResponse.user != null) {
          await _storage.saveUserId(authResponse.user!.id);
          await _storage.saveUserData(
            jsonEncode(authResponse.user!.toJson()),
          );
          // نفس عقد الدخول العادي: البصمة تُرجع المنح نفسها، فتُخزَّن مثلها
          // Same contract as a password sign-in: biometric login carries the same grants
          await _persistUserPermissions(authResponse.user!);
        }
      }

      return authResponse;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMsg = 'فشل تسجيل الدخول بالبصمة، يرجى المحاولة لاحقاً';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMsg = errorData['message'].toString();
      }
      return AuthResponse(success: false, message: errorMsg);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'حدث خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// إلغاء تسجيل البصمة (DELETE /auth/biometric/revoke)
  Future<bool> revokeBiometric() async {
    try {
      await _client.dio.delete(ApiConstants.biometricRevoke);
      await _storage.clearBiometricData();
      await _storage.saveBiometricEnabled(false);
      return true;
    } catch (_) {
      // حتى لو فشل الطلب، نمسح البيانات المحلية
      await _storage.clearBiometricData();
      await _storage.saveBiometricEnabled(false);
      return false;
    }
  }

  // ── حالة الصلاحيات (IBAC) ─────────────────────────────────

  /// جلب الصلاحيات الفعّالية للمستخدم الحالي (GET /auth/permissions)
  /// Fetch the effective IBAC state for the signed-in user.
  ///
  /// تُرجع اللقطة حين أجابت الخادم ببيانات سليمة، و**null** في كل ما عدا ذلك: لا لقطة صالحة.
  /// الفرق جوهري: من قبل كانت حالة الفشل تُخلط مع `PermissionSnapshot.denied` فتُقرأ في المتحكّم
  /// كأنها قرار «لا صلاحيات» وتُمحي الأقسام من الشاشة والتخزين معاً رغم أن التوكن لا يزال صالحاً —
  /// وهو سبب بقاء التطبيق على قسم «الإعدادات» وحده بعد أي انقطاع أو ردّ غريب.
  /// Returns the snapshot when the server answered with a usable payload, and **null** for anything
  /// else — no valid snapshot. The distinction is the whole point: failure used to be conflated with
  /// `PermissionSnapshot.denied`, so the notifier read a network blip as a "no permissions" verdict
  /// and wiped the sections from both the screen and storage while the token was still valid.
  ///
  /// لا يمسح هذا المسار التخزين أبداً: قرار إنهاء الجلسة يتخذه المتحكّم، ومسح التوكن عند 401 يتم في
  /// `ErrorInterceptor`. الطلب الملغى يُحوَّل إلى ردّ 200 مصطنع ({success:false, cancelled:true}) من
  /// نفس المعترض، فلا يكاد `CancelToken.isCancel` يعمل — لذلك تُقرأ إشارة `cancelled` صراحةً هنا.
  /// This path never clears storage: ending the session is the notifier's call, and a 401 wipes the
  /// token inside ErrorInterceptor. A cancelled request arrives as a synthetic 200 from that same
  /// interceptor, so `CancelToken.isCancel` barely fires — hence the explicit `cancelled` read here.
  Future<PermissionSnapshot?> fetchPermissions({CancelToken? cancelToken}) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.permissions,
        cancelToken: cancelToken,
      );

      final body = response.data;
      if (body is! Map<String, dynamic>) return null;

      // إلغاء الطلب ليس معلومة عن الصلاحيات: لا جديد ولا دليل على تغيير المنح
      // A cancellation is not a statement about permissions: nothing new, no evidence of a change
      if (body['cancelled'] == true) return null;
      if (body['success'] != true) return null;

      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;

      final snapshot = PermissionSnapshot.fromJson(data);
      await _persistPermissions(snapshot);

      return snapshot;
    } on DioException {
      // 401: المعترض طهّر التخزين وأسقط الجلسة، وبقية الأخطاء (5xx/شبكة/مهلة/إلغاء) فشل عابر
      // A 401 was already handled by the interceptor; every other error is a transient failure
      return null;
    } catch (_) {
      return null;
    }
  }

  /// قراءة الحالة المخزّنة بعد إعادة تشغيل التطبيق (بلا شبكة)
  /// Read the stored state after a cold start, without touching the network.
  ///
  /// مسار ترميم ضروري: إصدارات سابقة لم تكن تكتب `ky_user_permissions` إطلاقاً (كان مزود المزامنة
  /// لا يُستهلك)، فترك تلك الأجهزة بلا منح يعني إبقاء العطل حيّاً بعد التنصيب الجديد. حزمة المستخدم
  /// المخزّنة تحمل المنح نفسها التي أرسلها الخادم عند الدخول، فتُقرأ منها عند غياب المفاتيح.
  /// A necessary repair path: older builds never wrote `ky_user_permissions` (the sync provider was
  /// never consumed), and leaving those devices grant-less would keep the bug alive after the fix.
  /// The cached user blob carries the very grants the server sent at sign-in, so it is read when the
  /// dedicated keys are missing.
  Future<PermissionSnapshot> restorePermissions() async {
    var codes = await _storage.getPermissions();
    var isAdmin = await _storage.getIsAdmin();
    final expiresAt = await _storage.getSessionExpiresAt();
    final cachedUser = await getCachedUser();

    // الترميم مشروط بغياب الاثنين معاً: مدير بلا أكواد حالة صحيحة لا تُلمس
    // Repair only when both are absent: an admin with no codes is a valid state, left untouched
    if (codes.isEmpty && !isAdmin && cachedUser != null) {
      codes = cachedUser.permissions;
      isAdmin = cachedUser.isAdmin;
      if (codes.isNotEmpty || isAdmin) {
        await _persistPermissions(
          PermissionSnapshot(
            userId: cachedUser.id,
            isAdmin: isAdmin,
            permissions: codes,
            modules: _deriveModules(codes),
          ),
        );
      }
    }

    return PermissionSnapshot(
      userId: cachedUser?.id ?? 0,
      isAdmin: isAdmin,
      permissions: codes,
      modules: _deriveModules(codes),
      sessionExpiresAt: expiresAt,
    );
  }

  /// كتابة لقطة مشتقة من استجابة الدخول — كي لا ينتظر الإقلاع البارد أول طلب شبكة
  /// Persist the snapshot embedded in a sign-in response, so a cold start needs no first request.
  Future<void> _persistUserPermissions(UserModel user) async {
    final codes = user.permissions;

    await _persistPermissions(
      PermissionSnapshot(
        userId: user.id,
        isAdmin: user.isAdmin,
        permissions: codes,
        modules: _deriveModules(codes),
      ),
    );
  }

  /// كتابة الحالة إلى المفاتيح المخصصة — يفرضها مسار واحد فقط حتى لا تتباعد النسخ
  /// Persist the state to its dedicated keys; one write path keeps the copies from diverging.
  ///
  /// الموعد لا يُمسح بغيابه: `sessionExpiresAt` فارغ في لقطة الدخول لأن الموعد يخصّ التوكن لا
  /// الحساب، والمسح هنا كان يمحو موعداً محفوظاً من ترويسة ردّ سابق فيفقد الحارس مرجعه.
  /// An absent deadline does not erase the stored one: a sign-in snapshot carries no deadline (it
  /// belongs to the token, not the account), and clearing it here would wipe a deadline already
  /// learned from a response header and leave the watchdog without a reference.
  Future<void> _persistPermissions(PermissionSnapshot snapshot) async {
    await _storage.savePermissions(snapshot.permissions);
    await _storage.saveIsAdmin(snapshot.isAdmin);

    final deadline = snapshot.sessionExpiresAt;
    if (deadline != null && deadline.isNotEmpty) {
      await _storage.saveSessionExpiresAt(deadline);
    }
  }

  /// الأقسام المشتقة من الأكواد — نفس اشتقاق `payloadFor` في الخادم
  /// Modules derived from codes, mirroring the server's `payloadFor` derivation.
  static List<String> _deriveModules(List<String> codes) {
    final modules = <String>{};

    for (final code in codes) {
      final dot = code.indexOf('.');
      modules.add(dot < 0 ? code : code.substring(0, dot));
    }

    return modules.toList(growable: false);
  }
}
