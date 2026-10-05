import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// أنواع دعم البصمة في الجهاز
enum BiometricCapability {
  notSupported, // الجهاز لا يدعم البصمة أصلاً
  notEnrolled, // الجهاز يدعم لكن لم تُسجَّل بصمة
  fingerprint, // بصمة الإصبع متاحة
  faceId, // التعرف على الوجه متاح
  supported, // مدعوم (نوع غير محدد)
}

/// خدمة المصادقة البيومترية - Wrapper موحّد لـ local_auth
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// فحص شامل لدعم الجهاز للبصمة
  Future<BiometricCapability> checkSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        return BiometricCapability.notSupported;
      }

      final types = await _auth.getAvailableBiometrics();

      if (types.isEmpty) {
        return BiometricCapability.notEnrolled;
      }

      if (types.contains(BiometricType.face)) {
        return BiometricCapability.faceId;
      }

      if (types.contains(BiometricType.fingerprint) ||
          types.contains(BiometricType.strong) ||
          types.contains(BiometricType.weak)) {
        return BiometricCapability.fingerprint;
      }

      return BiometricCapability.supported;
    } catch (_) {
      return BiometricCapability.notSupported;
    }
  }

  /// هل الجهاز يدعم البصمة ومُعدّ للاستخدام؟
  Future<bool> isAvailable() async {
    final cap = await checkSupport();
    return cap != BiometricCapability.notSupported &&
        cap != BiometricCapability.notEnrolled;
  }

  /// طلب المصادقة البيومترية من المستخدم
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true, // لا نسمح بكلمة المرور كبديل
          stickyAuth: true, // يبقى مفتوحاً عند الانتقال بين التطبيقات
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// الأيقونة المناسبة لنوع البصمة المتاحة
  static String getBiometricLabel(BiometricCapability capability) {
    switch (capability) {
      case BiometricCapability.faceId:
        return 'التعرف على الوجه';
      case BiometricCapability.fingerprint:
        return 'بصمة الإصبع';
      default:
        return 'البصمة';
    }
  }
}
