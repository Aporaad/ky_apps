import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// مزود خدمة التخزين الآمن
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// مزود عميل Dio المركزي
final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(
    storage: storage,
    onUnauthorized: () {
      ref.read(authNotifierProvider.notifier).forceLogout();
    },
  );
});

/// مزود مستودع المصادقة
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(client: client, storage: storage);
});

/// حالة المصادقة
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String selectedUserType; // 'employee' أو 'customer'
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.selectedUserType = 'employee',
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? selectedUserType,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      selectedUserType: selectedUserType ?? this.selectedUserType,
      errorMessage: errorMessage,
    );
  }
}

/// إدارة حالة المصادقة عبر Riverpod Notifier الحديث
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // فحص حالة الدخول في أول بناء
    Future.microtask(() => checkAuthStatus());
    return const AuthState(isLoading: true);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// التحقق من حالة تسجيل الدخول عند بدء التطبيق
  Future<void> checkAuthStatus() async {
    // تحميل وتهيئة رابط الـ API المخصص من الذاكرة المشفرة
    final client = ref.read(dioClientProvider);
    await client.initializeBaseUrl();

    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final cachedUser = await _repository.getCachedUser();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: cachedUser,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
      );
    }
  }

  /// تغيير نوع المستخدم المختار (موظف / عميل)
  void setUserType(String type) {
    state = state.copyWith(selectedUserType: type, errorMessage: null);
  }

  /// تنفيذ عملية تسجيل الدخول
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final response = await _repository.login(
      username: username,
      password: password,
      userType: state.selectedUserType,
    );

    if (response.success && response.user != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response.user,
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        errorMessage: response.message,
      );
      return false;
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  /// تسجيل الخروج الإجباري (عند 401)
  void forceLogout() {
    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
      errorMessage: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً',
    );
  }
}

/// مزود حالة المصادقة الرئيسي
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
