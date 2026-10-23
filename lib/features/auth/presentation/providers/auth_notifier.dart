import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../../../core/utils/device_id_helper.dart';
import '../../../../core/utils/permission_check.dart';
import '../../../../core/utils/session_clock.dart';
import '../../data/models/permission_snapshot_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'permissions_notifier.dart';

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
    // موعد الجلسة يصل من ترويسة كل رد، ويُبلَّغ للحارس المحلي في نفس اللحظة التي يجددها الخادم
    // The deadline arrives on every response and goes straight to the watchdog, in the same moment
    // the server slid it.
    onSessionDeadline: (deadline, serverNow) {
      ref
          .read(authNotifierProvider.notifier)
          .updateSessionDeadline(deadline, serverNow: serverNow);
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
///
/// تحمل أيضاً حالة IBAC (المنح وصفة المدير وموعد انتهاء الجلسة) لأن كل قرار حجب في الواجهة
/// يُبنى عليها؛ والخادم يرفض افتراضياً، فالغياب هنا يعني «لا وصول» لا «اسأل لاحقاً».
/// Auth state, extended with the IBAC facts every gating decision reads: grants, the admin flag,
/// and the session deadline. The server denies by default, so absence here means no access.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserModel? user;
  final String selectedUserType; // 'employee' أو 'customer'
  final String? errorMessage;
  final BiometricCapability biometricCapability;
  final bool isBiometricEnabled;
  final bool isBiometricLoading;

  /// الأكواد الممنوحة فعلاً للمستخدم الحالي (فارغة قبل الدخول وبعد أي فشل)
  /// The codes actually granted to the current user (empty before sign-in and after any failure).
  final Set<String> permissions;

  /// صفة مدير النظام — تتجاوز جدول المنح في الخادم والواجهة معاً (قرار D1)
  /// System-admin flag: bypasses the grant table on both sides (decision D1).
  final bool isAdmin;

  /// نهاية الجلسة الحالية بوقت الجهاز؛ null = بلا موعد معلوم (جلسة قديمة أو تركات غير محدّدة)
  /// Current session deadline **on the device clock**; null means nothing was asserted about expiry.
  final DateTime? sessionExpiresAt;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.selectedUserType = 'employee',
    this.errorMessage,
    this.biometricCapability = BiometricCapability.notSupported,
    this.isBiometricEnabled = false,
    this.isBiometricLoading = false,
    this.permissions = const {},
    this.isAdmin = false,
    this.sessionExpiresAt,
  });

  /// هل يملك المستخدم هذه الصلاحية؟ — نفس قواعد `PermissionResolver::can` حرفياً
  /// Does the user hold this permission? The same rules as the server resolver, literally.
  bool can(String code) =>
      canCode(granted: permissions, isAdmin: isAdmin, code: code);

  /// يملك واحدة على الأقل من الأكواد (القائمة الفارغة ترفض اتباعاً للرفض الافتراضي)
  /// Holds at least one code; an empty list denies, matching deny-by-default.
  bool canAny(Iterable<String> codes) =>
      canAnyCode(granted: permissions, isAdmin: isAdmin, codes: codes);

  /// يملك كل الأكواد — للعمليات التي تحتاج صلاحيتين معاً (عرض + تصدير مثلاً)
  /// Holds every code, for actions that need two grants at once (view + export, say).
  bool canAll(Iterable<String> codes) =>
      canAllCode(granted: permissions, isAdmin: isAdmin, codes: codes);

  /// هل القسم ظاهر؟ الأقسام بلا صلاحية قسم (كالإعدادات المحلية) تظهر دائماً
  /// Is this section visible? Sections without a section-level permission (local settings) always are.
  bool canSeeSection(String? code) => code == null || can(code);

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserModel? user,
    String? selectedUserType,
    // تبقى الدلالة القديمة: كل تحديث للحالة يمسح الخطأ ما لم يُرسل خطأ جديد صراحة
    // Kept as before: any state change clears the error unless a new one is supplied.
    String? errorMessage,
    BiometricCapability? biometricCapability,
    bool? isBiometricEnabled,
    bool? isBiometricLoading,
    Set<String>? permissions,
    bool? isAdmin,
    // الحقل الجديد وحده يحتاج خدعة الإغلاق: تمرير null معناه «امسح الموعد» لا «أبقِ القديم»
    // Only the new field needs the closure trick: passing null must clear it, not keep the old one.
    DateTime? Function()? sessionExpiresAt,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      selectedUserType: selectedUserType ?? this.selectedUserType,
      errorMessage: errorMessage,
      biometricCapability: biometricCapability ?? this.biometricCapability,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isBiometricLoading: isBiometricLoading ?? this.isBiometricLoading,
      permissions: permissions ?? this.permissions,
      isAdmin: isAdmin ?? this.isAdmin,
      sessionExpiresAt:
          sessionExpiresAt != null ? sessionExpiresAt() : this.sessionExpiresAt,
    );
  }

  /// تطبيق لقطة صلاحيات على الحالة — المسار الوحيد الذي يكتب هذا الثالوث
  /// Apply an IBAC snapshot to the state — the only path that writes this trio of fields.
  ///
  /// `deadlineOverride` يُمرَّر من استعادة القرص: اللقطة تحمل نص الخادم، والحارس يحتاج الوقت
  /// بساعة الجهاز، فيُمرَّر المحسوب مسبقاً بدل إعادة تفسير النص الخام.
  /// `deadlineOverride` comes from the disk restore: the snapshot carries the server's text, while the
  /// watchdog needs device time, so the already-converted value wins over re-reading the raw text.
  AuthState withPermissions(
    PermissionSnapshot snapshot, {
    DateTime? deadlineOverride,
  }) {
    return copyWith(
      permissions: snapshot.permissions.toSet(),
      isAdmin: snapshot.isAdmin,
      sessionExpiresAt: () =>
          deadlineOverride ??
          SessionClock.resolve(deadlineText: snapshot.sessionExpiresAt),
    );
  }
}

/// تحويل نص تاريخ الخادم إلى وقت، مع إلغاء إزاحة الساعتين إن وُجد مرجع لها
/// Parse the server's date text into device time, cancelling the clock skew when a reference exists
///
/// يُلجأ إلى `SessionClock.resolve` مباشرة: مع `X-Server-Now` تُحسب الإزاحة في لحظة الردّ،
/// وبدونِها (خادم أقدم لم يُنشر له التصحيح بعد) يُفترض تطابق الساعتين كما كان السلوك القديم.
/// Everything goes through `SessionClock.resolve`: with `X-Server-Now` the offset is measured at the
/// instant of the response; without it (an older API build) the clocks are assumed to agree.
DateTime? _resolveDeadline(String? raw, [String? serverNow]) =>
    SessionClock.resolve(deadlineText: raw, serverNowText: serverNow);

/// إدارة حالة المصادقة عبر Riverpod Notifier الحديث
class AuthNotifier extends Notifier<AuthState> {
  /// دورية فحص الموعد — لا طلب شبكة فيها: أي استعلام يمدّد الجلسة عند الخادم فيُبطل الخمول
  /// Watchdog cadence — deliberately network-free: any probe would renew the session server-side
  ///
  /// المهلة نفسها بالساعات، ففحص كل نصف دقيقة يكفي للإخراج «فوراً» دون أن يستهلك شيئاً؛ وزيادته
  /// دقةً لا تُقدم سوى ثوانٍ على قرار لا يتخذه إلا الخادم في النهاية.
  /// The idle window is measured in hours, so a 30-second tick is immediate enough to be honest
  /// while costing nothing; finer ticks would only shave seconds off a call the server still makes.
  static const Duration _watchdogInterval = Duration(seconds: 30);

  Timer? _sessionWatchdog;

  @override
  AuthState build() {
    // فحص حالة الدخول ودعم البصمة في أول بناء
    Future.microtask(() => checkAuthStatus());

    // حارس واحد living مع المزوّد: يُلغى عند انتهائه فلا يبقى مؤقّت بعد `ProviderScope` مغلق
    // One guard living with the provider: cancelled on dispose, so no timer outlives the scope.
    _sessionWatchdog?.cancel();
    _sessionWatchdog = Timer.periodic(_watchdogInterval, (_) => _enforceDeadline());
    ref.onDispose(() => _sessionWatchdog?.cancel());

    return const AuthState(isLoading: true);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  SecureStorageService get _storage => ref.read(secureStorageProvider);
  BiometricService get _biometricService => BiometricService();

  /// استقبال موعد الجلسة من ترويسة الخادم وتحديث الحارس المحلي به
  /// Take the session deadline from the server header and re-arm the local watchdog with it.
  ///
  /// لا يُقارن الحارس بموعد تسجيل الدخول لأن الخادم يجدّد `EXPIRES_AT` انزلاقياً مع كل طلب ناجح،
  /// فذلك الموعد القديم يطرد مستخدماً نشيطاً بعد مهلة واحدة من دخوله. والتخزين يأتي هنا أيضاً حتى
  /// يبقى الموعد صحيحاً لو أُغلق التطبيق ثم فُتح وهو ما زال خاملًا.
  /// The guard must not fall back to the sign-in time: the server slides EXPIRES_AT on every request,
  /// so the stale value would evict an active user after one idle window. It is persisted here too, so
  /// the deadline is still correct when the app closes and reopens while the session idles.
  ///
  /// يُخزَّن الموعد بصيغتين: نصّ الخادم الخام (للعرض وللتوافق مع الإصدارات السابقة) ووقت الجهاز
  /// المحسوب (وهو ما يقرؤه الحارس بعد إعادة التشغيل). الثاني هو التصحيح: بدونه كان أي اختلاف بين
  /// ساعة أوراكل (+03:00) وساعة الجهاز يقرر مصير الجلسة.
  /// Two forms are stored: the server's raw text (display + backward compatibility) and the converted
  /// device time — which is what the watchdog reads after a restart. The second is the correction:
  /// without it, any disagreement between the Oracle clock and the device clock decided the session.
  void updateSessionDeadline(String raw, {String? serverNow}) {
    final deadline = _resolveDeadline(raw, serverNow);
    if (deadline == null || !state.isAuthenticated) return;

    if (state.sessionExpiresAt == deadline) return;

    state = state.copyWith(sessionExpiresAt: () => deadline);
    unawaited(_persistDeadlines(raw, deadline));
  }

  /// حفظ صيغتي الموعد معاً — مسار كتابة واحد حتى لا تتباعد النسخة الخام عن المحوَّلة
  /// Persist both deadline forms through one path so the raw text and the converted time diverge never.
  Future<void> _persistDeadlines(String raw, DateTime deviceDeadline) async {
    await _storage.saveSessionExpiresAt(raw.trim());
    await _storage.saveSessionDeadlineLocal(deviceDeadline.toIso8601String());
  }

  /// انتهى الموعد؟ — الفحص الوحيد المستخدم من الحارس ومن فحص البداية
  /// Has the deadline passed? The single check used by both the watchdog and the startup probe.
  bool _deadlinePassed(DateTime? deadline) =>
      deadline != null && !DateTime.now().isBefore(deadline);

  /// إن انتهت الجلسة فالخروج الآن، لا عند أول طلب
  /// If the session is over, sign out now — not on the next request.
  void _enforceDeadline() {
    if (!state.isAuthenticated) return;
    if (!_deadlinePassed(state.sessionExpiresAt)) return;

    forceLogout();
  }

  /// تحديث حالة ودعم البصمة
  Future<void> refreshBiometricStatus() async {
    final capability = await _biometricService.checkSupport();
    final isEnabled = await _storage.getBiometricEnabled();
    state = state.copyWith(
      biometricCapability: capability,
      isBiometricEnabled: isEnabled,
    );
  }

  /// التحقق من حالة تسجيل الدخول عند بدء التطبيق
  /// Check the sign-in state on app start.
  ///
  /// الصلاحيات تُستعاد من التخزين الآمن فوراً حتى تُرسم الأقسام بلا انتظار الشبكة، ثم يتكفّل
  /// `PermissionsNotifier` بتحديثها من الخادم حالما يُستهلك أول مرة.
  /// Grants come back from secure storage immediately so sections render without waiting on the
  /// network; `PermissionsNotifier` then refreshes them from the server on first use.
  ///
  /// الحارس يقرأ وقت الجهاز المحفوظ لا نصّ الخادم: النص القديم كان يُفسَّر بساعة الجهاز مباشرةً
  /// فأي انحراف بينهما يطرد المستخدم عند أول نبضة أو يُبقيه بعد الموعد.
  /// The watchdog reads the stored device time, not the server's text: interpreting raw server text on
  /// the device clock meant any skew either evicted the user on the first tick or kept them past it.
  Future<void> checkAuthStatus() async {
    // تحميل وتهيئة رابط الـ API المخصص من الذاكرة المشفرة
    final client = ref.read(dioClientProvider);
    await client.initializeBaseUrl();

    await refreshBiometricStatus();

    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final cachedUser = await _repository.getCachedUser();
      final snapshot = await _repository.restorePermissions();

      // تدرّج آمن: موعد بوقت الجهاز إن وُجد، وإلا نصّ الخادم كما كان (تنصيب قديم أو تركة بلا تحويل)
      // Safe gradation: a device-clock deadline when stored, otherwise the raw server text as before
      final localDeadline = _resolveDeadline(
        await _storage.getSessionDeadlineLocal(),
      );
      final restoredDeadline =
          localDeadline ?? _resolveDeadline(snapshot.sessionExpiresAt);

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        user: cachedUser,
        // اختيار نوع المستخدم على شاشة الدخول يبقى كما هو: إعادة البناء من الصفر كانت
        // تعيده إلى «موظف» وتمسح ما اختاره المستخدم قبل اكتمال الفحص
        // The login screen's user-type choice survives: rebuilding from scratch reset it to
        // 'employee' and discarded whatever was picked before this check finished.
        selectedUserType: state.selectedUserType,
        biometricCapability: state.biometricCapability,
        isBiometricEnabled: state.isBiometricEnabled,
      ).withPermissions(snapshot, deadlineOverride: restoredDeadline);

      // انتهت أثناء إغلاق التطبيق؟ تُغلق محلياً قبل أي طلب: الموعد استُعيد من التخزين المشفّر،
      // وانتظار 401 يعني رسم البوابة كاملة ثم إسقاطها
      // A session that expired while the app was closed ends here, before any request: the deadline
      // came back from secure storage, and waiting for a 401 would draw the whole portal first.
      _enforceDeadline();

      // جلسة حيّة بلا أي منح على القرص؟ تُطلَب مزامنة فوراً بدل رسم بوابة نصف فارغة.
      // الحالة متوقعة فقط على تنصيبات قديمة لم تكتب المنح إطلاقاً؛ والتوصيف المعتمَد: فشل
      // التحقق يُنهي الجلسة إلى شاشة الدخول، لا يترك واجهة صامتة على «الإعدادات».
      // A live session with no grants on disk syncs at once instead of painting a hollow portal.
      // Only older builds can land here (they never persisted grants); the accepted policy sends a
      // failed verification to the login screen rather than leaving a silent settings-only UI.
      if (state.isAuthenticated && !state.isAdmin && state.permissions.isEmpty) {
        unawaited(ref.read(permissionsNotifierProvider.notifier).refresh());
      }
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        permissions: const {},
        isAdmin: false,
        sessionExpiresAt: () => null,
      );
    }
  }

  /// تطبيق حالة IBAC القادمة من الخادم على حالة المصادقة — الكاتب الوحيد لهذا الثالوث
  /// Apply a server-side IBAC snapshot to the auth state; the only writer of those three fields.
  ///
  /// يُحفظ موعد الجلسة الحالي: الترويسة مرّت بالفعل عبر `updateSessionDeadline` وحوّلت الإزاحة،
  /// أما حقل `session_expires_at` داخل اللقطة فنصّ خام على ساعة أوراكل — استبداله كان يفسد
  /// التصحيح ويعيد الطرد المبكّر.
  /// The current deadline is preserved: the header already went through `updateSessionDeadline` and
  /// had its offset removed, while the snapshot's own field is raw Oracle-clock text — letting it win
  /// would undo the correction and bring the early eviction back.
  void applyPermissions(PermissionSnapshot snapshot) {
    state = state.withPermissions(
      snapshot,
      deadlineOverride: state.sessionExpiresAt,
    );
  }

  /// إسقاط الصلاحيات محلياً (خروج، 401، أو فشل تحديث مؤكد)
  /// Drop the local grants: logout, a 401, or a refresh that reported nothing.
  void clearPermissions() {
    state = state.copyWith(
      permissions: const {},
      isAdmin: false,
      sessionExpiresAt: () => null,
    );
  }

  /// تغيير نوع المستخدم المختار (موظف / عميل)
  void setUserType(String type) {
    state = state.copyWith(selectedUserType: type, errorMessage: null);
  }

  /// تنفيذ عملية تسجيل الدخول العادي
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
      await refreshBiometricStatus();
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        user: response.user,
        errorMessage: null,
      ).withPermissions(_snapshotFrom(response.user!));
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

  /// تسجيل الدخول بالمقاييس الحيوية (البصمة / التعرف على الوجه)
  Future<bool> loginWithBiometric() async {
    state = state.copyWith(isBiometricLoading: true, errorMessage: null);

    final isEnabled = await _storage.getBiometricEnabled();
    if (!isEnabled) {
      state = state.copyWith(
        isBiometricLoading: false,
        errorMessage: 'لم يتم تفعيل تسجيل الدخول بالبصمة على هذا الجهاز',
      );
      return false;
    }

    final userId = await _storage.getUserId();
    if (userId == null) {
      state = state.copyWith(
        isBiometricLoading: false,
        errorMessage:
            'يرجى تسجيل الدخول أولاً وتفعيل البصمة من شاشة الإعدادات',
      );
      return false;
    }

    // التحقق المحلي على الهاتف
    final authenticated = await _biometricService.authenticate(
      reason: 'يرجى تأكيد بصمتك لتسجيل الدخول إلى النظام',
    );
    if (!authenticated) {
      state = state.copyWith(
        isBiometricLoading: false,
      );
      return false;
    }

    // استخراج معرّف الجهاز المشفر
    final deviceToken = await DeviceIdHelper.getDeviceToken();

    final response = await _repository.biometricLogin(
      userId: userId,
      deviceToken: deviceToken,
      userType: state.selectedUserType,
    );

    if (response.success && response.user != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        isBiometricLoading: false,
        user: response.user,
        errorMessage: null,
      ).withPermissions(_snapshotFrom(response.user!));
      return true;
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        isBiometricLoading: false,
        errorMessage: response.message,
      );
      return false;
    }
  }

  /// تسجيل الخروج
  /// Log out: the session ends, and so does every cached grant with it.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _repository.logout();
    await refreshBiometricStatus();
    state = AuthState(
      selectedUserType: state.selectedUserType,
      biometricCapability: state.biometricCapability,
      isBiometricEnabled: state.isBiometricEnabled,
    );
  }

  /// تسجيل الخروج الإجباري (عند 401 أو انتهاء الموعد محلياً أو فشل التحقق من المنح)
  /// Forced logout: a 401, an expired local deadline, or a failed permission verification.
  ///
  /// يمسح التخزين بنفسه لأن مسار الحارس لا يمر بـ `ErrorInterceptor`: بلا ذلك يبقى التوكن على
  /// الجهاز ويُستعاد «مسجّل الدخول» عند أول إعادة تشغيل بعد الخروج. `clearAll()` تُبقي أثر البصمة
  /// ورابط الـ API كما في الخروج العادي، فلا يفقد المستخدم دخوله بالبصمة بسبب انتهاء الخمول.
  /// It wipes storage itself because the watchdog path never touches ErrorInterceptor: otherwise the
  /// token survives on the device and the next app start reads back as "signed in". clearAll keeps
  /// the biometric enrollment and the API URL, exactly as a normal logout does, so an idle timeout
  /// never costs the user their fingerprint sign-in.
  void forceLogout({String? reason, bool silent = false}) {
    unawaited(_storage.clearAll());

    state = AuthState(
      selectedUserType: state.selectedUserType,
      biometricCapability: state.biometricCapability,
      isBiometricEnabled: state.isBiometricEnabled,
      // `reason` ظاهري بحت: القرار وأثره واحدان، والفرق فقط أن المستخدم يرى سبب الشاشة
      // `reason` is display-only: the decision and its effect are identical, the difference is that
      // the user is told why the login screen appeared.
      // `silent` يترك شاشة الدخول بلا أي تنبيه: يُستخدم حين لا يملك الجلسة أي منح أصلاً، فيُعاد
      // المستخدم إلى الدخول بهدوء بدل إظهار رسالة تحذير.
      // `silent` leaves the login screen with no message at all — used when a session simply holds
      // no grants, so the user is returned to sign-in quietly instead of being shown a warning.
      errorMessage: silent
          ? null
          : (reason ?? 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً'),
    );
  }

  /// لقطة أولية من حمولة المستخدم في استجابة الدخول
  /// Seed snapshot from the user payload of a sign-in response.
  ///
  /// استجابات `login` و`biometricLogin` تحمل المنح نفسها التي يحملها `GET /auth/permissions`
  /// (منذ المرحلة 2)، فلا تبرُر الواجهة بقسم قبل أن تصل اللقطة. موعد انتهاء الجلسة يبقى مجهولاً
  /// حتى التحديث الأول لأنّه يخصّ التوكن لا الحساب.
  /// Sign-in responses already embed the same grants as the permissions endpoint, so the UI is
  /// never naked before the first refresh. The session deadline stays unknown until that refresh,
  /// since it belongs to the token rather than the account.
  PermissionSnapshot _snapshotFrom(UserModel user) {
    return PermissionSnapshot(
      userId: user.id,
      isAdmin: user.isAdmin,
      permissions: user.permissions,
    );
  }
}

/// مزود حالة المصادقة الرئيسي
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
