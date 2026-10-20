/// منطق فحص الصلاحية المجرد — نفس قواعد `PermissionResolver::can` في الخادم
/// Pure permission-checking logic — the same rules as the server's `PermissionResolver::can`.
///
/// الهدف من وجود الدوال هنا لا في `AuthState` فقط: أن تُختبر وحدتها بلا واجهة ولا شبكة،
/// وأن يكون مسار الحجب في الواجهة نسخة حرفية من مسار القرار في الخادم. أي اختلاف بينهما
/// يعني شاشة تُظهر زراً ثم يرفضه الـ API — وهذا أسوأ من الحجب الزائد.
/// These helpers exist apart from `AuthState` so they are unit-testable without UI or network,
/// and so the client decision is a literal copy of the server one. Any divergence would show a
/// button the API then refuses — worse than over-blocking.
///
/// القواعد بالترتيب (الرفض هو الجواب الأخير):
///  1) مدير النظام يملك كل شيء خارج جدول المنح (قرار D1).
///  2) `system.*` منح شامل.
///  3) الكود الحرفي ممنوح.
///  4) منح القسم كاملاً `module.*`.
///  5) وإلا: لا.
/// Rules in order: admin bypass, `system.*`, exact code, `module.*` wildcard, then false.
library;

import '../constants/permission_codes.dart';

/// هل تمنح هذه المجموعة صلاحيةَ [code]؟
/// Does this grant set satisfy [code]?
bool canCode({
  required Set<String> granted,
  required bool isAdmin,
  required String code,
}) {
  if (isAdmin) return true;
  if (code.isEmpty) return false;
  if (granted.contains(Perm.systemWildcard)) return true;
  if (granted.contains(code)) return true;

  final module = permModuleOf(code);
  if (module != code && granted.contains(permWildcardOf(module))) return true;

  return false;
}

/// يملك واحدة على الأقل — القائمة الفارغة تعني رفضاً اتباعاً للرفض الافتراضي
/// Holds at least one code. An empty list denies, consistent with deny-by-default.
bool canAnyCode({
  required Set<String> granted,
  required bool isAdmin,
  required Iterable<String> codes,
}) {
  if (codes.isEmpty) return false;

  for (final code in codes) {
    if (canCode(granted: granted, isAdmin: isAdmin, code: code)) return true;
  }

  return false;
}

/// يملك كل الأكواد — القائمة الفارغة تعني «لا شيء مطلوب» فتُقبل على طلب فارغ صريح
/// Holds every code. An empty list means nothing was required, so it is accepted.
bool canAllCode({
  required Set<String> granted,
  required bool isAdmin,
  required Iterable<String> codes,
}) {
  for (final code in codes) {
    if (!canCode(granted: granted, isAdmin: isAdmin, code: code)) return false;
  }

  return true;
}
