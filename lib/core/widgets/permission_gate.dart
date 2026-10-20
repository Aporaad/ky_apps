import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';

/// حاجز الصلاحيات: يعرض ابنه فقط إن كانت الصلاحية ممنوحة
/// Permission gate: renders its child only when the permission is actually granted.
///
/// وجوده كويدجت واحد يمنع نمطين فاشلين متكررين: شرطٌ مكتوب داخل كل شاشة بشكل مختلف، وحجب
/// الواجهة ثم رفض الخادم للعنصر نفسه — فالحجب هنا يقرأ نفس المنح التي طبّقها الخادم للتو.
/// One widget instead of per-screen conditionals, which historically drift and which can show a
/// control the API then refuses. This gate reads the very grants the server just asserted.
///
/// الوضع الافتراضي إخفاء تام (`hide: true`) لأن ظهور زر معطّل يخبر المستخدم بوجود شيء محجوب
/// عنه؛ وشاشات الإدارة التي تحتاج شرح السبب تمرّر `onDenied` بدل ذلك.
/// Hiding is the default because a disabled button advertises a capability the user is denied;
/// admin screens that must explain themselves pass `onDenied` instead.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    required this.code,
    required this.child,
    this.onDenied,
    this.hide = true,
    super.key,
  });

  /// الكود المطلوب (`customers.create`)؛ null تعني بلا شرط فتُعرض الزمرة كما هي
  /// The required code (`customers.create`); null means unconditional passthrough.
  final String? code;
  final Widget child;

  /// بديل يُعرض عند المنع؛ وإن غاب فلا يُعرض شيء مهما كانت قيمة `hide`
  /// The widget shown when denied; if omitted nothing is rendered regardless of `hide`.
  final Widget? onDenied;

  /// مع `hide: false` ووجود `onDenied` يُعرض البديل بدل الطفل؛ ومع غياب البديل يبقى الإخفاء
  /// With `hide: false` and an `onDenied` fallback, the fallback replaces the child; with no
  /// fallback, hiding stays regardless of this flag.
  final bool hide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: إعادة البناء فقط عند تغيّر هذا الكود دون سواه من حالة المصادقة
    // select: rebuild only when this exact decision changes, not on every auth update.
    final allowed = ref.watch(
      authNotifierProvider.select((auth) => code == null || auth.can(code!)),
    );

    if (allowed) return child;
    if (!hide && onDenied != null) return onDenied!;

    return const SizedBox.shrink();
  }
}

/// امتداد الاختصار على `WidgetRef` — نفس أسئلة `AuthState` بلا تكرار قراءة المزود في كل شاشة
/// Convenience on `WidgetRef`: the same questions as `AuthState`, without re-reading the provider.
///
/// يقرأ القراءة الآنية (`read`) لأنه يُستدعى داخل `build` لبناء عنصر مشروط مرة واحدة؛ وإن كان
/// القرار يحتاج إعادة رسم تلقائية عند تحديث المنح فالأداة الصحيحة هي `PermissionGate`.
/// These use `read` because they answer a one-shot condition inside `build`. A decision that must
/// repaint when grants change belongs in `PermissionGate`, which watches instead.
extension PermissionsOnRef on WidgetRef {
  bool can(String code) => read(authNotifierProvider).can(code);

  bool canAny(Iterable<String> codes) => read(authNotifierProvider).canAny(codes);

  bool canAll(Iterable<String> codes) => read(authNotifierProvider).canAll(codes);

  bool get isSystemAdmin => read(authNotifierProvider).isAdmin;
}
