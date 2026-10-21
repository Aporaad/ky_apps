import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/app_config_model.dart';

/// مستودع تهيئة التطبيق — الشبكة + الكاش الآمن + ملف الشعار المحلي
/// App-config repository — network + secure cache + local logo file.
class AppConfigRepository {
  AppConfigRepository({
    required DioClient client,
    required SecureStorageService storage,
  }) : _client = client,
       _storage = storage;

  final DioClient _client;
  final SecureStorageService _storage;

  /// كلمة سر إعدادات API الافتراضية — محلية بالكامل داخل التطبيق
  /// Default API-settings password — fully local inside the app itself.
  ///
  /// تُستخدم ما لم يُعيَّن كلمة أخرى عبر [setApiPassword]؛ التحقق لا يلمس الخادم أبداً
  /// لأن شاشة إعدادات API يجب أن تُفتح حتى عندما يكون رابط الـ API خاطئ أو غير متصل،
  /// وإلا استحال إصلاح الرابط من داخل التطبيق.
  /// Used until another password is set via [setApiPassword]; verification never touches the
  /// server, because the API-settings screen must open even when the API URL is wrong or down.
  static const String defaultApiSettingsPassword = 'A1.b2.c3.d4';

  /// اسم الملف الثابت للشعار داخل مجلد مستندات التطبيق
  /// Fixed logo filename inside the app-documents directory.
  static const String _logoFileName = 'ky_app_logo.img';

  Dio get _dio => _client.dio;

  // ── الشبكة / network ─────────────────────────────────────

  /// جلب التهيئة العامة (نقطة نهاية عامة، بلا مصادقة) — null عند أي فشل شبكة
  /// Fetch the public config (a public endpoint). Returns null on any network failure.
  Future<AppConfigModel?> fetchPublicConfig() async {
    try {
      final response = await _dio.get<dynamic>(ApiConstants.appConfig);
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return AppConfigModel.fromJson(body);
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// حفظ التهيئة عبر `PUT /app-config` (يتطلب `app_config.update` على الخادم)
  /// Save config via PUT (requires the `app_config.update` grant server-side).
  Future<AppConfigModel> updateConfig(AppConfigModel config) async {
    final response = await _dio.put<dynamic>(
      ApiConstants.appConfig,
      data: config.toJsonForUpdate(),
    );
    final body = response.data;
    if (body is Map<String, dynamic> && body['success'] == true) {
      // الخادم يعيد الحمولة المحفوظة — نثق بها أكثر من قيمنا المحلية
      // The server echoes the saved payload; trust it over our local copy.
      return AppConfigModel.fromJson(body);
    }
    // لم يعد بالحمولة المعتادة — نعيد النموذج المُرسَل كما هو
    // No standard payload returned — send back what we submitted.
    return config;
  }

  // ── الكاش الآمن / secure cache ───────────────────────────

  /// قراءة التهيئة من الكاش (null = لا كاش بعد) — لا يفشل أبداً على بيانات تالفة
  /// Read cached config (null if none); never throws on corrupt data.
  Future<AppConfigModel?> loadFromCache() async {
    final raw = await _storage.getAppConfig();
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppConfigModel.fromJson(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// كتابة التهيئة إلى الكاش بصيغة JSON (من الحمولة العامة)
  /// Persist the config cache as JSON (from the public payload).
  Future<void> saveToCache(AppConfigModel config) async {
    await _storage.saveAppConfig(jsonEncode(config.toJsonForUpdate()));
  }

  /// قراءة/كتابة التجزئة المحلية لكلمة سر API
  /// Read/write the local API-password hash.
  Future<String?> loadLocalPasswordHash() => _storage.getApiPasswordHash();
  Future<void> saveLocalPasswordHash(String hash) =>
      _storage.saveApiPasswordHash(hash);

  /// تعيين كلمة سر جديدة لإعدادات API — تُخزَّن مجزّأة محلياً فقط (بلا خادم)
  /// Set a new API-settings password — stored as a hash locally only (never via the server).
  Future<void> setApiPassword(String newPassword) async {
    await _storage.saveApiPasswordHash(_localPasswordHash(newPassword));
  }

  /// التحقق المحلي من كلمة سر إعدادات API — مقابل التجزئة المخزّنة أو الافتراضية
  /// Verify the API-settings password locally — against the stored hash, or the built-in
  /// default when nothing was ever set. This is deliberately offline-first: no network call.
  Future<bool> verifyLocally(String password) async {
    final stored = await _storage.getApiPasswordHash();
    if (stored == null || stored.isEmpty) {
      // لا كلمة مخصّصة بعد — الكلمة الافتراضية المضمّنة هي الصحيحة
      // No custom password yet — the embedded default is the valid one.
      return password == defaultApiSettingsPassword;
    }
    return _localPasswordHash(password) == stored;
  }

  // ── الشعار المحلي / local logo ───────────────────────────

  /// اختيار صورة من الجهاز وحفظها في مجلد المستندات، ثم تخزين مسارها — يعيد المسار أو null
  /// Pick an image from the device, copy it into the documents directory, store its path.
  /// Returns the saved path, or null if the user cancelled / the copy failed.
  Future<String?> pickAndSaveLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final tempFile = File(picked.path);
    if (!tempFile.existsSync()) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final target = File('${docsDir.path}/$_logoFileName');
    await tempFile.copy(target.path);

    await _storage.saveAppLogoPath(target.path);
    return target.path;
  }

  /// مسار الشعار المحلي الحالي (null = استخدام الأصل المضمّن `assets/logo3.jpg`)
  /// The current local logo path (null means use the bundled asset).
  Future<String?> getLogoPath() => _storage.getAppLogoPath();

  /// إعادة الشعار إلى الافتراضي المضمّن — تحذف الملف والمسار المخزّن
  /// Reset to the bundled default — deletes the local file and its stored path.
  Future<void> clearLogo() async {
    final path = await _storage.getAppLogoPath();
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // حذف الملف فشل — نمسح المسار على أي حال حتى لا يُقرأ مجدداً
        // File removal failed — still drop the path so it is never read again.
      }
    }
    await _storage.deleteAppLogoPath();
  }

  // ── التجزئة المحلية / local digest ───────────────────────

  /// SHA-256 مع ملح ثابت — نفس روح نمط رمز الجهاز في `device_id_helper`
  /// Salted SHA-256 — same spirit as the device-token pattern in `device_id_helper`.
  static String _localPasswordHash(String password) {
    return _sha256Hex('$password:ky_apps_api_pw_local_v1_2026');
  }

  /// تجزئة SHA-256 لنص UTF-8 إلى سداسي صغير
  /// SHA-256 of a UTF-8 string, as lowercase hex.
  static String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
