import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/permission_check.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_permission_model.dart';
import '../../data/repositories/permission_repository.dart';

/// مزود مستودع الصلاحيات — تشاركه شاشة الكتالوج ونموذج المستخدم وشاشة المنح
/// Permission repository provider — shared by the catalog screen, the user form, and the picker.
final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PermissionRepository(client: ref.watch(dioClientProvider));
});

/// كتالوج الصلاحيات كاملًا مجمّعاً بالأقسام، كما بذوره الخادم
/// The permission catalog, grouped by section exactly as the server seeded it.
///
/// `FutureProvider` لا Notifier: الكتالوج قراءة واحدة ثابتة في الجلسة، ونسخة منه تُستهلك في ثلاثة
/// أماكن. الفشل يُرمى عمدياً كي تعرض الشاشات حالة خطأ مع «إعادة محاولة» بدل مجموعة فارغة تبدو
/// كأن النظام بلا صلاحيات — وهو أسوأ من الخطأ لأنه يقود لمنح صفري.
/// A FutureProvider, not a Notifier: the catalog is one stable read reused by three screens.
/// Failures are rethrown on purpose so screens show a retry error instead of an empty set, which
/// would read as "the system has no permissions" and invite granting nothing at all.
final permissionsCatalogProvider =
    FutureProvider<List<AppPermissionModule>>((ref) async {
      final repo = ref.watch(permissionRepositoryProvider);

      return repo.fetchCatalog(cancelToken: CancelToken());
    });

/// فهرسة الكود → الصلاحية، للبحث السريع في شريط البحث داخل المنتقي
/// Code → permission index for the picker's search box.
Map<String, AppPermissionModel> catalogByCode(
  List<AppPermissionModule> catalog,
) {
  final index = <String, AppPermissionModel>{};
  for (final module in catalog) {
    for (final permission in module.permissions) {
      if (permission.permissionCode.isNotEmpty) {
        index[permission.permissionCode] = permission;
      }
    }
  }

  return index;
}

/// كل الأكواد غير الشاملة (الأفعال الحرفية) — تُستخدم لـ «تحديد كل القسم»
/// Every non-wildcard code — used by «select whole section».
///
/// السبب أمني لا تجميلي: منح `module.*` صلاحيةٌ أوسع من مجموع أفعالها لأنها تغطي كل فعل يُضاف
/// لاحقاً، ومديرٌ بلا `system.*` لا يستطيع إرسالها أصلاً (يرفضها الخادم بـ `not_held`). التحديد
/// الشامل هنا يمنح الأفعال الحرفية المرئية، وهو ما يقرؤه المستخدم فعلاً على الشاشة.
/// Granting a wildcard is broader than the sum of its actions — it covers codes added later — and a
/// non-admin cannot send one anyway (the server rejects it as not_held). Selecting a whole section
/// therefore grants the visible literal actions, which is what the user actually sees.
List<String> sectionActionCodes(AppPermissionModule module) {
  return module.permissions
      .where((permission) => !permission.isWildcard)
      .map((permission) => permission.permissionCode)
      .toList(growable: false);
}

/// الأفعال الأساسية لقسم — «أساسيات القسم» في زر واحد
/// A section's core actions — the «section basics» shortcut.
List<String> sectionCoreCodes(AppPermissionModule module) {
  return module.permissions
      .where((permission) => permission.isCore && !permission.isWildcard)
      .map((permission) => permission.permissionCode)
      .toList(growable: false);
}

/// هل يغطي هذا التحديد القسم كاملًا؟ لعرض شارة «كل القسم» بدل تسعة صناديق محقّقة
/// Does this selection cover the whole section? Shows one badge instead of nine ticked boxes.
bool isSectionFullySelected(
  AppPermissionModule module,
  Set<String> selected,
) {
  final codes = sectionActionCodes(module);
  if (codes.isEmpty) return false;

  return codes.every(selected.contains);
}

/// ما يملكه الممنِح من هذا القسم — لتظليل ما لا يستطيع منحه (لا تصعيد)
/// What the granting user holds in this section, so ungrantable rows can be dimmed (no escalation).
///
/// الخادم هو الحاجز الحقيقي ويرفض بـ `not_held`؛ هذه القراءة تجعل الواجهة تحذّر قبل الإرسال بدل
/// أن تفاجئ المستخدم برسالة خطأ بعد عملٍ كامل.
/// The server is the real barrier and answers with not_held; this only warns before sending
/// instead of surprising the user with an error after they finish a whole form.
bool canGrant(
  AppPermissionModel permission, {
  required Set<String> granted,
  required bool isAdmin,
}) {
  if (isAdmin) return true;
  // صلاحية الفعل تُمنح إن كان الممنِح يملكها أو يملك القسم أو `system.*`
  // An action is grantable if the actor holds it, holds the module, or holds system.*.
  if (canCode(granted: granted, isAdmin: false, code: permission.permissionCode)) {
    return true;
  }

  return canCode(
    granted: granted,
    isAdmin: false,
    code: '${permission.permissionCode.split('.').first}.*',
  );
}
