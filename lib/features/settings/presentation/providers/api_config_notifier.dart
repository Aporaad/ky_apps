import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/api_config_repository.dart';
import 'api_config_state.dart';

/// مزود مستودع إعدادات الـ API
final apiConfigRepositoryProvider = Provider<ApiConfigRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiConfigRepository(storage: storage);
});

/// إدارة حالة إعدادات الـ API وفحص الاتصال بالخادم
class ApiConfigNotifier extends Notifier<ApiConfigState> {
  @override
  ApiConfigState build() {
    // تحميل الرابط النشط عند البداية
    Future.microtask(() => loadActiveUrl());
    return const ApiConfigState(
      activeApiUrl: ApiConstants.defaultBaseUrl,
      isLoading: true,
    );
  }

  ApiConfigRepository get _repository => ref.read(apiConfigRepositoryProvider);
  DioClient get _dioClient => ref.read(dioClientProvider);

  /// تحميل العنوان النشط من الذاكرة المشفرة
  Future<void> loadActiveUrl() async {
    final activeUrl = await _repository.getActiveApiUrl();
    // مزامنة عنوان الـ DioClient
    _dioClient.updateBaseUrl(activeUrl);
    state = state.copyWith(
      activeApiUrl: activeUrl,
      isLoading: false,
    );
  }

  /// فحص الاتصال بعنوان الـ API المدخل
  Future<ApiConnectionTestResult> testConnection(String url) async {
    state = state.copyWith(
      isTesting: true,
      testResult: () => null,
      errorMessage: () => null,
      successMessage: () => null,
    );

    final result = await _repository.testConnection(url);

    state = state.copyWith(
      isTesting: false,
      testResult: () => result,
    );

    return result;
  }

  /// حفظ وتطبيق رابط الـ API الجديد فورياً
  Future<bool> saveApiUrl(String newUrl) async {
    final normalized = ApiConfigRepository.normalizeUrl(newUrl);

    if (normalized.isEmpty || (!normalized.startsWith('http://') && !normalized.startsWith('https://'))) {
      state = state.copyWith(
        errorMessage: () => 'يرجى إدخال عنوان URL يبدأ بـ http:// أو https://',
      );
      return false;
    }

    state = state.copyWith(
      isSaving: true,
      errorMessage: () => null,
      successMessage: () => null,
    );

    try {
      await _repository.saveApiUrl(normalized);
      // تحديث العميل الموحد فورياً
      _dioClient.updateBaseUrl(normalized);

      state = state.copyWith(
        activeApiUrl: normalized,
        isSaving: false,
        successMessage: () => 'تم حفظ وتفعيل رابط الـ API بنجاح',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => 'فشل حفظ العنوان: $e',
      );
      return false;
    }
  }

  /// إعادة تعيين الرابط إلى الافتراضي
  Future<void> resetToDefault() async {
    state = state.copyWith(isSaving: true);
    try {
      await _repository.resetToDefault();
      _dioClient.updateBaseUrl(ApiConstants.defaultBaseUrl);
      state = state.copyWith(
        activeApiUrl: ApiConstants.defaultBaseUrl,
        isSaving: false,
        testResult: () => null,
        successMessage: () => 'تمت استعادة الرابط الافتراضي بنجاح',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => 'فشل استعادة الرابط الافتراضي: $e',
      );
    }
  }

  /// مسح رسائل الحالة ونتائج الفحص
  void clearStatus() {
    state = state.copyWith(
      errorMessage: () => null,
      successMessage: () => null,
      testResult: () => null,
    );
  }
}

/// المزود الرئيسي لإعدادات الـ API
final apiConfigNotifierProvider =
    NotifierProvider<ApiConfigNotifier, ApiConfigState>(ApiConfigNotifier.new);
