import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// مساعد توليد معرّف الجهاز الآمن (Device Token)
/// يولّد SHA-256 hash من UUID الجهاز + salt ثابت للمشروع
class DeviceIdHelper {
  static const String _salt = 'ky_apps_biometric_v1_2026';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// الحصول على device_token المحسوب من معرّف الجهاز
  static Future<String> getDeviceToken() async {
    final rawId = await _getRawDeviceId();
    return _hashId(rawId);
  }

  /// الحصول على اسم الجهاز للعرض
  static Future<String> getDeviceName() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        return '${info.brand} ${info.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  /// المنصة الحالية كنص
  static String getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }

  // ── private ──────────────────────────────────────────────

  static Future<String> _getRawDeviceId() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _deviceInfo.androidInfo;
        // ANDROID_ID هو المعرّف الأكثر ثباتاً
        return info.id.isNotEmpty ? info.id : info.fingerprint;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? info.utsname.machine;
      }
    } catch (_) {}
    return 'fallback_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _hashId(String rawId) {
    final input = '$rawId:$_salt';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
