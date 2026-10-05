import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../../../core/utils/device_id_helper.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

/// مزود خدمة فحص وتوثيق المقاييس الحيوية
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// حالة إعدادات المقاييس الحيوية في التطبيق
class BiometricSettingsState {
  final BiometricCapability deviceCapability;
  final bool isEnabled;
  final bool isLoading;
  final String? deviceName;
  final String? platform;
  final String? errorMessage;
  final String? successMessage;

  const BiometricSettingsState({
    this.deviceCapability = BiometricCapability.notSupported,
    this.isEnabled = false,
    this.isLoading = false,
    this.deviceName,
    this.platform,
    this.errorMessage,
    this.successMessage,
  });

  BiometricSettingsState copyWith({
    BiometricCapability? deviceCapability,
    bool? isEnabled,
    bool? isLoading,
    String? deviceName,
    String? platform,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return BiometricSettingsState(
      deviceCapability: deviceCapability ?? this.deviceCapability,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage:
          successMessage != null ? successMessage() : this.successMessage,
    );
  }
}

/// إدارة حالة وتفعيل/تعطيل المقاييس الحيوية
class BiometricSettingsNotifier extends Notifier<BiometricSettingsState> {
  @override
  BiometricSettingsState build() {
    Future.microtask(() => loadSettings());
    return const BiometricSettingsState(isLoading: true);
  }

  BiometricService get _biometricService => ref.read(biometricServiceProvider);
  AuthRepository get _authRepository => ref.read(authRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);

  /// تحميل إعدادات البصمة الحالية وفحص دعم الجهاز
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    final capability = await _biometricService.checkSupport();
    final isEnabled = await _storage.getBiometricEnabled();
    final deviceName = await DeviceIdHelper.getDeviceName();
    final platform = DeviceIdHelper.getPlatform();

    state = state.copyWith(
      deviceCapability: capability,
      isEnabled: isEnabled,
      isLoading: false,
      deviceName: deviceName,
      platform: platform,
    );
  }

  /// تفعيل أو تعطيل البصمة للمستخدم الحالي
  Future<bool> toggleBiometric(bool enable) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      successMessage: () => null,
    );

    if (enable) {
      // 1. فحص دعم الجهاز
      final capability = await _biometricService.checkSupport();
      if (capability == BiometricCapability.notSupported) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () =>
              'هذا الجهاز لا يدعم المقاييس الحيوية (البصمة/التعرف على الوجه).',
        );
        return false;
      }
      if (capability == BiometricCapability.notEnrolled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () =>
              'لم يتم تسجيل أي بصمة في إعدادات الهاتف. يرجى إضافة بصمة في جهازك أولاً.',
        );
        return false;
      }

      // 2. التحقق من البصمة محلياً
      final authenticated = await _biometricService.authenticate(
        reason: 'يرجى تأكيد بصمتك لتفعيل تسجيل الدخول البيومتري',
      );
      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () => 'تم إلغاء أو فشل التحقق من البصمة.',
        );
        return false;
      }

      // 3. جلب معرّف الجهاز واسمه
      final deviceToken = await DeviceIdHelper.getDeviceToken();
      final deviceName = await DeviceIdHelper.getDeviceName();
      final platform = DeviceIdHelper.getPlatform();

      // 4. تسجيل البصمة في السيرفر عبر الـ API
      final success = await _authRepository.registerBiometric(
        deviceToken: deviceToken,
        deviceName: deviceName,
        platform: platform,
      );

      if (success) {
        await _storage.saveBiometricEnabled(true);
        final user = await _authRepository.getCachedUser();
        if (user != null) {
          await _storage.saveUserId(user.id);
        }

        ref.read(authNotifierProvider.notifier).refreshBiometricStatus();

        state = state.copyWith(
          isEnabled: true,
          isLoading: false,
          successMessage: () =>
              'تم تفعيل تسجيل الدخول بالبصمة بنجاح لهذا الجهاز.',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: () =>
              'فشل تسجيل البصمة على السيرفر، يرجى المحاولة لاحقاً.',
        );
        return false;
      }
    } else {
      // إلغاء تفعيل البصمة
      final success = await _authRepository.revokeBiometric();
      await _storage.saveBiometricEnabled(false);
      await _storage.clearBiometricData();

      ref.read(authNotifierProvider.notifier).refreshBiometricStatus();

      state = state.copyWith(
        isEnabled: false,
        isLoading: false,
        successMessage: () => 'تم إلغاء تفعيل تسجيل الدخول بالبصمة بنجاح.',
      );
      return success;
    }
  }

  /// مسح رسائل الحالة
  void clearStatus() {
    state = state.copyWith(
      errorMessage: () => null,
      successMessage: () => null,
    );
  }
}

/// مزود إعدادات المقاييس الحيوية
final biometricSettingsNotifierProvider =
    NotifierProvider<BiometricSettingsNotifier, BiometricSettingsState>(
  BiometricSettingsNotifier.new,
);
