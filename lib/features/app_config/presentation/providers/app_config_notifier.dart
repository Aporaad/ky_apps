import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_config_model.dart';
import '../../data/repositories/app_config_repository.dart';

/// مزود مستودع تهيئة التطبيق — يعتمد عميل Dio والتخزين الآمن المجاورين
/// App-config repository provider — depends on the shared Dio client and secure storage.
final appConfigRepositoryProvider = Provider<AppConfigRepository>((ref) {
  return AppConfigRepository(
    client: ref.watch(dioClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

/// حالة تهيئة التطبيق كما تراها الواجهة
/// The app-config state as the UI sees it.
class AppConfigState {
  const AppConfigState({
    required this.config,
    this.loading = true,
    this.saving = false,
    this.logoPath,
    this.allowedFonts = const ['Cairo'],
    this.errorMessage,
    this.syncedWithServer = false,
  });

  /// التهيئة الفعّالة (الهوية + المظهر)
  final AppConfigModel config;

  /// جارٍ التحميل الأول (من الكاش/الخادم)
  final bool loading;

  /// جارٍ الحفظ إلى الخادم
  final bool saving;

  /// مسار ملف الشعار المحلي (null = الأصل المضمّن)
  final String? logoPath;

  /// الخطوط المسموحة كما أعلنها الخادم
  final List<String> allowedFonts;

  /// رسالة خطأ آخر عملية (null = لا خطأ)
  final String? errorMessage;

  /// هل تمّت مزامنة القيم مع الخادم في هذه الجلسة
  final bool syncedWithServer;

  AppConfigState copyWith({
    AppConfigModel? config,
    bool? loading,
    bool? saving,
    String? Function()? logoPath,
    List<String>? allowedFonts,
    String? Function()? errorMessage,
    bool? syncedWithServer,
  }) {
    return AppConfigState(
      config: config ?? this.config,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      logoPath: logoPath != null ? logoPath() : this.logoPath,
      allowedFonts: allowedFonts ?? this.allowedFonts,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      syncedWithServer: syncedWithServer ?? this.syncedWithServer,
    );
  }
}

/// مُبلِغ حالة تهيئة التطبيق — يهيّئ من الكاش فوراً ثم يزامن مع الخادم
/// App-config notifier — hydrates from cache instantly, then syncs with the server.
///
/// الاسم/الشعار ينعكسان فوراً؛ الألوان والخط تُدفع إلى `AppPalette` لكن تطبيقها الكامل
/// يحتاج إعادة تشغيل (يقرّرها المستدعي عبر `RestartWidget`) لتفادي الانقلاب أثناء الجلسة.
/// Name/logo apply immediately; colors/font are pushed to `AppPalette` but fully take effect
/// only after a restart (the caller triggers `RestartWidget`) to avoid mid-session jank.
class AppConfigNotifier extends Notifier<AppConfigState> {
  late final AppConfigRepository _repository;
  CancelToken? _cancelToken;

  @override
  AppConfigState build() {
    _repository = ref.read(appConfigRepositoryProvider);
    // نبدأ من الافتراضي ثم نملأ من الكاش/الخادم بشكل غير متزامن داخل microtask
    // Start from defaults, then hydrate from cache/server asynchronously via a microtask.
    Future.microtask(load);
    return AppConfigState(config: AppConfigModel.defaults());
  }

  /// تحميل أول: الكاش أولاً (تجربة فورية) ثم مزامنة الخادم في الخلفية
  /// Initial load: cache first (instant), then background server sync.
  Future<void> load() async {
    final cached = await _repository.loadFromCache();
    final logoPath = await _repository.getLogoPath();
    if (cached != null) {
      // نطبّق الكاش على اللوحة فوراً حتى يُبنى ThemeData الصح عند الإقلاع
      // Apply the cache to the palette now so the boot theme is already correct.
      cached.applyToPalette();
      state = state.copyWith(
        config: cached,
        logoPath: () => logoPath,
        loading: false,
      );
    } else {
      state = state.copyWith(logoPath: () => logoPath, loading: false);
    }

    await refreshFromServer();
  }

  /// مزامنة من الخادم (نقطة عامة) — لا يغيّر الألوان المطبّقة دون إعادة تشغيل
  /// Sync from the server (public endpoint). Does not restyle live colors without a restart.
  Future<void> refreshFromServer() async {
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;

    try {
      final remote = await _repository.fetchPublicConfig();
      if (remote == null) {
        // بلا اتصال/فشل: نُبقي الكاش أو الافتراضي دون رسالة مرعبة للمستخدم
        // Offline/failed: keep cache or defaults without scaring the user.
        return;
      }
      await _repository.saveToCache(remote);
      state = state.copyWith(
        config: remote,
        syncedWithServer: true,
        errorMessage: () => null,
      );
    } catch (_) {
      // الخطأ في القراءة العامة غير حرج — نتجاهله بهدوء ونحتفظ بالكاش
      // A public-read failure is non-critical — keep the cache silently.
    } finally {
      if (_cancelToken == token) _cancelToken = null;
    }
  }

  /// حفظ التهيئة إلى الخادم ثم تطبيقها (يدفع الألوان إلى اللوحة ويخزّن الكاش)
  /// Save to the server, then apply locally (push colors to the palette and cache).
  /// يعيد true عند النجاح؛ الألوان تستدعي إعادة تشغيل من المستدعي.
  /// Returns true on success; a color/font change requires the caller to restart.
  Future<bool> saveConfig(AppConfigModel updated) async {
    state = state.copyWith(saving: true, errorMessage: () => null);
    try {
      final saved = await _repository.updateConfig(updated);
      await _repository.saveToCache(saved);
      // نُدفع الألوان للوحة الآن؛ المستدعي يستدعي إعادة التشغيل لتطبيق السمة كاملة
      // Push colors to the palette now; the caller triggers the restart to restyle.
      saved.applyToPalette();
      state = state.copyWith(
        config: saved,
        saving: false,
        syncedWithServer: true,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        saving: false,
        errorMessage: () => _describeError(e),
      );
      return false;
    }
  }

  /// اختيار شعار وحفظه محلياً وتحديث الحالة (ينعكس فوراً بلا إعادة تشغيل)
  /// Pick + save a logo locally and update state (applies immediately, no restart).
  Future<bool> pickAndSaveLogo() async {
    try {
      final path = await _repository.pickAndSaveLogo();
      if (path == null) return false; // ألغى المستخدم
      state = state.copyWith(logoPath: () => path);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: () => _describeError(e));
      return false;
    }
  }

  /// إعادة الشعار للافتراضي المضمّن
  /// Reset the logo to the bundled default.
  Future<void> resetLogo() async {
    await _repository.clearLogo();
    state = state.copyWith(logoPath: () => null);
  }

  /// التحقق من كلمة سر إعدادات API: الخادم أولاً ثم الاحتياط المحلي عند تعذّر الوصول
  /// Verify the API-settings password: server first, then the local fallback if unreachable.
  Future<bool> verifyApiSettingsPassword(String password) async {
    final result = await _repository.verifyApiPassword(password);
    if (result.serverReached) {
      return result.verified;
    }
    // الخادم غير متاح — نعتمد على التجزئة المحلية المخزّنة (إن وُجدت)
    // Server unreachable — rely on the stored local hash, if any.
    return _repository.verifyLocally(password);
  }

  /// تغيير كلمة سر إعدادات API وحفظ التجزئة المحلية للاحتياط دون اتصال
  /// Change the API-settings password and store the local fallback hash.
  Future<bool> setApiPassword(String newPassword) async {
    try {
      final localHash = await _repository.updateApiPassword(newPassword);
      await _repository.saveLocalPasswordHash(localHash);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: () => _describeError(e));
      return false;
    }
  }

  /// تهيئة اللوحة من الحالة الحالية (تُستدعى داخل `main()` قبل runApp)
  /// Seed the palette from current state (called in `main()` before runApp).
  static void applyPalette(AppConfigModel config) => config.applyToPalette();

  /// ترجمة استثنائية Dio إلى رسالة عربية مختصرة
  /// Translate a Dio exception into a short Arabic message.
  String _describeError(Object error) {
    if (error is DioException) {
      if (CancelToken.isCancel(error)) return 'تم إلغاء العملية';
      if (error.response?.statusCode == 403) {
        return 'لا تملك صلاحية تعديل إعدادات التطبيق';
      }
      if (error.response?.statusCode == 422) {
        return 'بيانات غير صالحة — تحقق من الألوان والخط';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'تعذّر الاتصال بالخادم';
      }
    }
    return 'حدث خطأ غير متوقع';
  }
}

/// مزود حالة تهيئة التطبيق العام
/// The global app-config state provider.
final appConfigNotifierProvider =
    NotifierProvider<AppConfigNotifier, AppConfigState>(AppConfigNotifier.new);

/// تهيئة `AppPalette` مبكراً من الكاش قبل أول بناء للسمة (يُستدعى في `main()`)
/// Seed [AppPalette] early from cache before the first theme build (called in `main()`).
Future<AppConfigModel> bootstrapAppConfig() async {
  final storage = SecureStorageService();
  final repository =
      AppConfigRepository(client: DioClient(storage: storage), storage: storage);
  final cached = await repository.loadFromCache();
  final config = cached ?? AppConfigModel.defaults();
  config.applyToPalette();
  return config;
}
