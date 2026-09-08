import '../../data/repositories/api_config_repository.dart';

/// حالة شاشة وإدارة إعدادات الـ API
class ApiConfigState {
  final String activeApiUrl;
  final bool isLoading;
  final bool isTesting;
  final bool isSaving;
  final ApiConnectionTestResult? testResult;
  final String? errorMessage;
  final String? successMessage;

  const ApiConfigState({
    required this.activeApiUrl,
    this.isLoading = false,
    this.isTesting = false,
    this.isSaving = false,
    this.testResult,
    this.errorMessage,
    this.successMessage,
  });

  ApiConfigState copyWith({
    String? activeApiUrl,
    bool? isLoading,
    bool? isTesting,
    bool? isSaving,
    ApiConnectionTestResult? Function()? testResult,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return ApiConfigState(
      activeApiUrl: activeApiUrl ?? this.activeApiUrl,
      isLoading: isLoading ?? this.isLoading,
      isTesting: isTesting ?? this.isTesting,
      isSaving: isSaving ?? this.isSaving,
      testResult: testResult != null ? testResult() : this.testResult,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }
}
