import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/permission_snapshot_model.dart';
import 'auth_notifier.dart';

/// حالة مزامنة الصلاحيات — لا تحمل المنح نفسها (مصدرها الوحيد `AuthState`)
/// Permission sync status — it never holds the grants themselves; `AuthState` is their only home.
///
/// وجود حالة منفصلة يجعل «متى آخر تحديث» و«هل فشو التحديث» معروَضين في الواجهة دون أن يتحول
/// كل قسم إلى نسخة ثانية من الحقيقة تتباعد عن الأولى.
/// Keeping sync status apart means "last refreshed" and "refresh failed" are visible without the
/// app growing a second copy of the truth that drifts from the first.
class PermissionsState {
  final bool isSyncing;
  final bool hasSynced;

  /// true عند آخر فشل (ردّ الخادم بخطأ أو قطعه للجلسة) — تعرضه الشاشات الإدارية تلميحاً هادئاً
  /// Set when the server answered with an error; admin screens show it as a quiet hint.
  final bool isStale;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const PermissionsState({
    this.isSyncing = false,
    this.hasSynced = false,
    this.isStale = false,
    this.lastSyncedAt,
    this.errorMessage,
  });

  PermissionsState copyWith({
    bool? isSyncing,
    bool? hasSynced,
    bool? isStale,
    DateTime? Function()? lastSyncedAt,
    String? Function()? errorMessage,
  }) {
    return PermissionsState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasSynced: hasSynced ?? this.hasSynced,
      isStale: isStale ?? this.isStale,
      lastSyncedAt:
          lastSyncedAt != null ? lastSyncedAt() : this.lastSyncedAt,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

/// مزود مزامنة الصلاحيات مع مراقبة دورة حياة التطبيق
/// Permissions sync notifier, kept fresh by the app's lifecycle.
///
/// لماذا التحديث عند الرجوع من الخلفية؟ شاشة «صلاحيات المستخدم» تُعدّل منحاً حيّة، وإنهاء جلسة
/// من شاشة «الجلسات النشطة» يُخرج المستخدم فوراً. لو اعتمد العميل على لقطة الدخول وحدها بقي
/// الموظف يرى أقساماً سحبت منه وأزراراً يرفضها الخادم بـ 403. الكاش المحلي يُبقي الواجهة مرسومة
/// أثناء انقطاع الشبكة، والخادم يبقى صاحب القرار في كل طلب.
/// Why refresh on resume: the grant screen edits live grants and the session screen can end a
/// session instantly. With only the sign-in snapshot the worker would keep seeing sections that
/// were revoked and buttons the API answers with 403. The local copy keeps the UI drawn during a
/// network drop, while the server remains the final decider on every request.
///
/// الحد الأدنى بين استدعاءين 15 ثانية: الرجوع من الخلفية يتكرر مرات كثيرة في اليوم، وكل
/// استدعاء يقرأ جدول المنح بعد إسقاط نسخة الخادم منه (`forget()` في `myPermissions`).
/// The 15 s floor exists because resume fires constantly and each call re-reads the grant table
/// after dropping the server-side cache copy.
///
/// سياسة الفشل المعتمَدة: إن لم تصل لقطة صالحة تُنهى الجلسة إلى شاشة الدخول. البديل القديم كان
/// يرسم بوابة بلا أقسام مع توكن حيّ — واجهة نصف-ميّتة لا يستطيع المستخدم أن يفعل فيها شيئاً،
/// وهي بالضبط ما كان يرمي بالتطبيق على «الإعدادات» وحده. الآن: إمّا منح صالحة أو شاشة دخول.
/// Accepted failure policy: without a valid snapshot the session ends at the login screen. The old
/// alternative drew a section-less portal over a live token — a half-dead UI the user could not act
/// on, and precisely what used to drop the app onto «الإعدادات» alone. Now: either valid grants or
/// the login screen.
class PermissionsNotifier extends Notifier<PermissionsState>
    with WidgetsBindingObserver {
  static const Duration minRefreshGap = Duration(seconds: 15);

  CancelToken? _cancelToken;
  DateTime? _lastAttemptAt;
  bool _observerAttached = false;

  @override
  PermissionsState build() {
    _attachObserver();

    // الاستهلاك الأول للّقطة هو ما يطلق أول مزامنة: لا انتظار شبكة في أول إطار
    // First use of the snapshot is what triggers the initial sync — no network wait in frame one.
    Future.microtask(() => refresh());

    ref.onDispose(() {
      _cancelToken?.cancel('شاشة/جلسة أُغلقت / provider disposed');
      if (_observerAttached) {
        WidgetsBinding.instance.removeObserver(this);
        _observerAttached = false;
      }
    });

    return const PermissionsState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // التحديث عند الرجوع للأمام فقط: الخلفية والانتقال لا يستحقان قراءة القاعدة
    // Refresh only on return to foreground: backgrounding and transitions earn no DB read.
    if (state != AppLifecycleState.resumed) return;

    final last = _lastAttemptAt;
    if (last != null &&
        DateTime.now().difference(last) < minRefreshGap) {
      return;
    }

    refresh();
  }

  /// جلب آخر حالة من الخادم وتطبيقها — يُرجع اللقطة التي استقرّت عليها الواجهة
  /// Pull the effective state from the server and apply it, returning what the UI settled on.
  Future<PermissionSnapshot> refresh() async {
    final auth = ref.read(authNotifierProvider);

    // بلا جلسة لا معنى للاستدعاء: المسار محميّ بـ `auth:sanctum` فسيرجع 401 ويُربك المستخدم
    // With no session the call is pointless: the route is auth-guarded, so it would 401 and confuse.
    if (!auth.isAuthenticated) {
      return PermissionSnapshot.denied;
    }

    final repository = ref.read(authRepositoryProvider);

    _cancelToken?.cancel('تحديث أحدث يستبدله / superseded refresh');
    final token = CancelToken();
    _cancelToken = token;
    _lastAttemptAt = DateTime.now();

    state = state.copyWith(isSyncing: true);

    final snapshot = await repository.fetchPermissions(cancelToken: token);

    // إلغاء الطلب يعني أن شاشة أخرى/استدعاءً أحدث تولى الأمر: لا نكتب حالة ولا نُنهي جلسة
    // ولا نرفع وسماً — الإلغاء قرار داخلي لا خبر عن الصلاحيات ولا عن الجلسة
    // A cancelled call means a newer refresh took over: write nothing, end nothing, flag nothing —
    // cancelling is an internal decision, not news about grants or about the session.
    if (token.isCancelled) {
      return _snapshotOf(ref.read(authNotifierProvider));
    }

    if (identical(token, _cancelToken)) {
      _cancelToken = null;
    }

    // لا لقطة صالحة: فشل شبكة أو ردّ غير متوقع أو إنكار من الخادم. القرار المعتمَد هو إنهاء
    // الجلسة لا ترك واجهة نصف حيّة؛ والتخزين يُمسح في `forceLogout` فلا تُستعاد الحالة الفارغة
    // No valid snapshot: a network failure, an unexpected body, or a server denial. The accepted
    // call is to end the session rather than keep a half-alive UI; storage is cleared by
    // `forceLogout`, so the empty state cannot come back on the next start.
    if (snapshot == null) {
      state = state.copyWith(
        isSyncing: false,
        isStale: true,
        lastSyncedAt: () => DateTime.now(),
        errorMessage: () => 'تعذّر التحقق من الصلاحيات، تم إنهاء الجلسة',
      );
      ref.read(authNotifierProvider.notifier).forceLogout(
        reason: 'تعذّر التحقق من الصلاحيات أو انتهت الجلسة، يرجى تسجيل الدخول مجدداً',
      );

      return PermissionSnapshot.denied;
    }

    ref.read(authNotifierProvider.notifier).applyPermissions(snapshot);

    state = state.copyWith(
      isSyncing: false,
      hasSynced: true,
      // منح فارغة لمستخدم ليس مديراً = لا صلاحيات فعلاً؛ الوسم هنا خبر للقارئ لا فشل جلب
      // An empty grant set for a non-admin really means no access: flagged as fact, not as a fetch error
      isStale: snapshot.isEmpty && !snapshot.isAdmin,
      lastSyncedAt: () => DateTime.now(),
      errorMessage: () => null,
    );

    return snapshot;
  }

  /// إسقاط الحالة الحالية إلى لقطة — تُستخدم حين يلغى الطلب فلا جديد يُبلَّغ
  /// Project the current auth state as a snapshot — used when a call is cancelled and nothing new is known.
  PermissionSnapshot _snapshotOf(AuthState auth) {
    return PermissionSnapshot(
      userId: auth.user?.id ?? 0,
      isAdmin: auth.isAdmin,
      permissions: auth.permissions.toList(growable: false),
    );
  }

  /// إجبار التحديث بعد تعديل صلاحيات المستخدم نفسه من شاشة الإدارة
  /// Force a refresh after editing the signed-in user's own grants from the admin screen.
  Future<PermissionSnapshot> refreshNow() {
    _lastAttemptAt = null;
    return refresh();
  }

  void _attachObserver() {
    if (_observerAttached) return;

    // في اختبارات الوحدة لا يوجد ربط واجهة، فالتسجيل بلا معنى ولا يجوز أن يُفشل البناء
    // Without a binding (unit tests) observing is meaningless, so don't crash the build.
    try {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    } catch (_) {
      _observerAttached = false;
    }
  }
}

/// مزود حالة المزامنة — تُستهلك منه الشاشات الإدارية «متى آخر تحديث»
/// Sync-status provider, consumed by admin screens for "last refreshed".
final permissionsNotifierProvider =
    NotifierProvider<PermissionsNotifier, PermissionsState>(
      PermissionsNotifier.new,
    );
