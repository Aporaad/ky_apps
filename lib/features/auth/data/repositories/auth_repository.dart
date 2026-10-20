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
  /// التفرقة الحساسة هنا: إن **أجابت** الخادم بخطأ (401/403/500) فالمنح تُسقط ويُرجع رفض شامل،
  /// لأن الخادم أعلمنا أن الحالة لم تعد صحيحة. أما إن تعذّر الوصول أصلاً (شبكة، مهلة، خادم موصول
  /// حديثاً) فتبقى آخر لقطة معروفة بلا إبادة: القرار الأمني ينفّذه الخادم في كل طلب على أي حال،
  /// وإلا تحوّل انقطاع الواي فاي في المحل إلى تطبيق مقفل بلا أقسام حتى إعادة التشغيل.
  /// The split that matters: if the server *answered* with an error the grants are dropped — the
  /// server told us the state is no longer valid. If it was unreachable at all (network, timeout,
  /// a server still starting) the last known snapshot survives, because the server still enforces
  /// every call and a Wi-Fi hiccup would otherwise lock the app until a restart.
  /// Cancelling a request on dispose is neither of those: it simply returns what is stored.
  Future<PermissionSnapshot> fetchPermissions({CancelToken? cancelToken}) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.permissions,
        cancelToken: cancelToken,
      );

      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        await _storage.clearPermissions();
        return PermissionSnapshot.denied;
      }

      final data = body['data'];
      final snapshot = data is Map<String, dynamic>
          ? PermissionSnapshot.fromJson(data)
          : PermissionSnapshot.denied;

      await _persistPermissions(snapshot);

      return snapshot;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return restorePermissions();
      }

      if (e.response != null) {
        await _storage.clearPermissions();
        return PermissionSnapshot.denied;
      }

      // بلا إجابة من الخادم: النسخة المخزّنة هي أفضل معلومة متوفرة، والمهلة تُعلَم في المتحكّم
      // No answer from the server: the cached copy is the best known truth; staleness is flagged
      // by the notifier, not by wiping access.
      return restorePermissions();
    } catch (_) {
      await _storage.clearPermissions();
      return PermissionSnapshot.denied;
    }
  }

  /// قراءة الحالة المخزّنة بعد إعادة تشغيل التطبيق (بلا شبكة)
  /// Read the stored state after a cold start, without touching the network.
  Future<PermissionSnapshot> restorePermissions() async {
    final codes = await _storage.getPermissions();
    final isAdmin = await _storage.getIsAdmin();
    final expiresAt = await _storage.getSessionExpiresAt();
    final cachedUser = await getCachedUser();

    return PermissionSnapshot(
      userId: cachedUser?.id ?? 0,
      isAdmin: isAdmin,
      permissions: codes,
      modules: _deriveModules(codes),
      sessionExpiresAt: expiresAt,
    );
  }

  /// كتابة الحالة إلى المفاتيح المخصصة — يفرضها مسار واحد فقط حتى لا تتباعد النسخ
  /// Persist the state to its dedicated keys; one write path keeps the copies from diverging.
  Future<void> _persistPermissions(PermissionSnapshot snapshot) async {
    await _storage.savePermissions(snapshot.permissions);
    await _storage.saveIsAdmin(snapshot.isAdmin);
    await _storage.saveSessionExpiresAt(snapshot.sessionExpiresAt);
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
