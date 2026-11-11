import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── الأقسام: خريطة معرّف القسم إلى مزوداته ─────────────────────────
// Sections: a map from a portal section id to the providers it owns.
//
// السجل هنا هو الشريك الخلفي لـ `portal_sections.dart`: هذا يملك المعرّفات
// نفسه، لكن بمسؤولية واحدة — تفريغ حالة البحث والمعطيات التي خلفها المستخدم
// عند مغادرة القسم. `IndexedStack` في `EmployeeMainLayout` يبقي كل قسم mounted
// طوال الجلسة، فلا `dispose` ولا `initState` جديد عند التبديل، وكانت آخر حالة
// بحثٍ أو تصفيةٍ تبقى معروضة في الحقل بعد كل رجوع. الخريطة وحيدة المصدر
// لتفادي نسيان مزودٍ بعينه عند إضافة قسمٍ جديد.
// This registry is the backend counterpart of `portal_sections.dart`: the same
// ids, but with one job — wiping the search and filter state a user leaves
// behind when they exit a section. `EmployeeMainLayout`'s `IndexedStack` keeps
// every section mounted for the whole session, so no `dispose` or fresh
// `initState` fires on a tab switch and the last search text stayed in every
// field after each return. Keeping the map in one place prevents a new section
// from ever being forgotten.
//
// الموضع متعمّد: ملفات الميزات كثيرة، وكل مزود يحمل سلوكه الخاص بالتصفير،
// فهذا الملف لا يعرف شيئاً عن الحالة الداخلية لأي منها — ينادي `resetTransient`
// على كل مزود ويترك له قرار ما يجب مسحه.
// Deliberately thin: every feature already owns its state and knows how to
// clear it, so this file just calls `resetTransient` on each provider and lets
// each one decide what belongs in "transient".

// ── العملاء / customers ───────────────────────────────────────────
import '../../features/customers/presentation/providers/customer_measurement_providers.dart';
import '../../features/customers/presentation/providers/customers_provider.dart';

// ── الحسابات / accounts ───────────────────────────────────────────
import '../../features/accounts/presentation/providers/accounts_provider.dart';

// ── المخازن: قوائم + كشف جرد + أرصدة + تقارير ─────────────────────
import '../../features/stores/presentation/providers/items_providers.dart';
import '../../features/stores/presentation/providers/orders_providers.dart';
import '../../features/stores/presentation/providers/reports_providers.dart';
import '../../features/stores/presentation/providers/stock_sheet_providers.dart';
import '../../features/stores/presentation/providers/stores_providers.dart';

// ── التفصيل / tailoring ───────────────────────────────────────────
import '../../features/tailoring/presentation/providers/tailoring_providers.dart';

// ── جاري العاملين / workers ───────────────────────────────────────
import '../../features/workers/data/models/worker_model.dart';
import '../../features/workers/presentation/providers/worker_group_work_report_provider.dart';
import '../../features/workers/presentation/providers/worker_work_report_provider.dart';
import '../../features/workers/presentation/providers/workers_provider.dart';

// ── الإدارة / management ──────────────────────────────────────────
import '../../features/admin/presentation/providers/active_sessions_provider.dart';
import '../../features/admin/presentation/providers/admin_users_provider.dart';
import '../../features/admin/presentation/providers/support_inquiries_provider.dart';
import '../../features/admin/presentation/providers/user_activity_provider.dart';

// ── الخدمات / services ────────────────────────────────────────────
import '../../features/services/providers/jobs_provider.dart';
import '../../features/services/providers/messages_provider.dart';
import '../../features/services/providers/providers_provider.dart';

// ── الرئيسية: اختصارات تقود إلى كشوف شخصية
// ── home: shortcuts that push personal statements
import '../../features/my_statement/presentation/providers/my_statement_provider.dart';

/// بصمة كل مصفّر حالة — دالة تأخذ `WidgetRef` وترفضها على المزود المناسب.
/// The shape of every reset — one function that takes a `WidgetRef` and calls
/// `resetTransient` on the notifier it owns.
///
/// `reload` تُمرَّر من الهيكل: true عند تبديل قسم (الشاشة لا تزال mounted)،
/// وfalse عند نهاية الجلسة (لا معنى لإعادة جلب قسمٍ لن يُرى).
/// `reload` is passed down by the shell: true on a section switch (the screen
/// is still mounted and must show fresh rows), false at session end (nothing
/// will look at this state again).
typedef ViewStateReset = void Function(WidgetRef ref, {bool reload});

// ── مصفّرات الأقسام / per-section resets ──────────────────────────
//
// كل دالة صغيرة ومحدودة: تقرأ المزود بـ `ref.read` ثم تناديه. `ref.read` — لا
// `watch` — لأن هذه الدوال لا تُستدعى من داخل `build`، ولا يجب أن تُعيد بناء
// أي شيء عند تفريغ حالة قسمٍ غير معروض.
// Every helper is one line long: read the notifier, call it. `read`, never
// `watch` — these run outside `build`, and clearing a hidden section's state
// must not trigger any rebuild.

// ── العملاء / customers ───────────────────────────────────────────
void _resetCustomersList(WidgetRef ref, {bool reload = false}) =>
    ref.read(customersListProvider.notifier).resetTransient(reload: reload);

void _resetMeasurementCustomers(WidgetRef ref, {bool reload = false}) =>
    ref.read(measurementCustomersProvider.notifier)
        .resetTransient(reload: reload);

// ── الحسابات / accounts ───────────────────────────────────────────
void _resetAccountTree(WidgetRef ref, {bool reload = false}) =>
    ref.read(accountTreeProvider.notifier).resetTransient(reload: reload);

void _resetChartAccounts(WidgetRef ref, {bool reload = false}) =>
    ref.read(chartAccountsProvider.notifier).resetTransient(reload: reload);

// ── المخازن / stores ──────────────────────────────────────────────
void _resetStoresList(WidgetRef ref, {bool reload = false}) =>
    ref.read(storesListProvider.notifier).resetTransient(reload: reload);

void _resetItems(WidgetRef ref, {bool reload = false}) =>
    ref.read(itemsListProvider.notifier).resetTransient(reload: reload);

void _resetSubItems(WidgetRef ref, {bool reload = false}) =>
    ref.read(subItemsListProvider.notifier).resetTransient(reload: reload);

void _resetOrders(WidgetRef ref, {bool reload = false}) =>
    ref.read(ordersListProvider.notifier).resetTransient(reload: reload);

void _resetStockSheet(WidgetRef ref, {bool reload = false}) =>
    ref.read(stockSheetProvider.notifier).resetTransient(reload: reload);

void _resetBalances(WidgetRef ref, {bool reload = false}) =>
    ref.read(balancesProvider.notifier).resetTransient(reload: reload);

void _resetStoreReport(WidgetRef ref, {bool reload = false}) =>
    ref.read(storeReportProvider.notifier).resetTransient(reload: reload);

// ── التفصيل / tailoring ───────────────────────────────────────────
void _resetCuttingBills(WidgetRef ref, {bool reload = false}) =>
    ref.read(cuttingBillsListProvider.notifier)
        .resetTransient(reload: reload);

// ── جاري العاملين / workers ───────────────────────────────────────
void _resetWorkersLists(WidgetRef ref, {bool reload = false}) {
  // المزود عائلة على `WorkerType` — الثلاثة يجب أن تُصفَّر معاً لأن نفس
  // الشاشة تفتح أيًّا منها بنفس القسم، فلا معنى لترك قائمة القصّاصين
  // ببحثٍ سابق بينما قائمة الموظفين نظيفة.
  // The provider is a family over `WorkerType`. All three must go together:
  // the same screen opens any one of them, and leaving the cutters tab dirty
  // while the employees tab is clean would just look like a bug.
  for (final type in WorkerType.values) {
    ref.read(workersListProvider(type).notifier)
        .resetTransient(reload: reload);
  }
}

// `reload` لا معنى له في الثلاثة أدناه: كل شاشة منها تُمرّر معطياتها
// الخاصة عند الدخول (`loadStatement` / `load` / `loadReport`)، فلا قائمة
// أساسية يُعاد جلبها. يُقبل الوسيط للاتساق مع بقية المصفّرات فقط.
// `reload` carries no meaning in the three below — each screen passes its own
// arguments on entry (`loadStatement` / `load` / `loadReport`), so there is no
// base list to refetch. The parameter is accepted purely for signature parity.
void _resetWorkerStatement(WidgetRef ref, {bool reload = false}) {
  ref.read(workerStatementProvider.notifier).resetTransient();
}

void _resetWorkerWorkReport(WidgetRef ref, {bool reload = false}) {
  ref.read(workerWorkReportProvider.notifier).resetTransient();
}

void _resetWorkerGroupWorkReport(WidgetRef ref, {bool reload = false}) {
  ref.read(workerGroupWorkReportProvider.notifier).resetTransient();
}

// ── الإدارة / management ──────────────────────────────────────────
void _resetAdminUsers(WidgetRef ref, {bool reload = false}) =>
    ref.read(adminUsersProvider.notifier).resetTransient(reload: reload);

void _resetActiveSessions(WidgetRef ref, {bool reload = false}) =>
    ref.read(activeSessionsProvider.notifier).resetTransient(reload: reload);

void _resetUserActivity(WidgetRef ref, {bool reload = false}) {
  // `reload` لا معنى: الشاشة تدعو `loadFor(userId)` في كل بناء.
  // `reload` is meaningless — the screen calls `loadFor(userId)` on every
  // build, so there is no in-place reload to trigger here.
  ref.read(userActivityProvider.notifier).resetTransient();
}

void _resetSupportInquiries(WidgetRef ref, {bool reload = false}) =>
    ref.read(supportInquiriesProvider.notifier)
        .resetTransient(reload: reload);

// ── الخدمات / services ────────────────────────────────────────────
void _resetProvidersList(WidgetRef ref, {bool reload = false}) =>
    ref.read(providersListProvider.notifier).resetTransient(reload: reload);

void _resetMessages(WidgetRef ref, {bool reload = false}) {
  // عائلة لكل قناة (`sms` / `whatsapp`) — كلاهما يُصفَّر معاً لأن نفس
  // التبويب في قسم الخدمات يفتح القناتين ورقيّاً واحدٍ لا يُرى.
  // A family per channel (`sms` / `whatsapp`) — both are wiped together
  // because the same tab in services touches either, and a half-clean
  // channel would look like a bug.
  for (final channel in MessageChannel.values) {
    ref.read(messagesProvider(channel).notifier)
        .resetTransient(reload: reload);
  }
}

void _resetJobs(WidgetRef ref, {bool reload = false}) =>
    ref.read(jobsProvider.notifier).resetTransient(reload: reload);

// ── الرئيسية / home shortcuts ─────────────────────────────────────
void _resetMyFinancialStatement(WidgetRef ref, {bool reload = false}) {
  // الشاشة تعيد التحميل بنفسها في `initState`؛ هنا التفريغ فقط.
  // The screen reloads itself in `initState`; this only wipes.
  ref.read(myFinancialStatementProvider.notifier).resetTransient();
}

void _resetMyWorkStatement(WidgetRef ref, {bool reload = false}) {
  ref.read(myWorkReportProvider.notifier).resetTransient();
}

/// خريطة معرّف بوابة القسم إلى قائمة مصفّراته — مطابقة لمعرّفات
/// `portal_sections.dart`، وأي معرّف جديد هنا يجب أن يُضاف هناك أيضاً.
/// The map from a portal section id to its list of resets — matching the ids
/// in `portal_sections.dart` exactly, so a new section here must appear there
/// too (and vice versa) or the two registries will drift.
///
/// لماذا خريطة نصّية لا حقول داخل `PortalSection`؟ لأن السجل يهدف إلى وصف
/// ما يُرى (العنوان والأيقونة والصلاحية والشاشة) بينما هذه الخريطة وصلة
/// بين البنية المعمارية للمزودات وهيكل التنقل — مزج الاثنين كان سيجعل أي
/// تعديلٍ على المزودات تغييراً في تعريف القسم.
/// Why a plain map rather than a field on `PortalSection`? That class is
/// about what a user sees (title, icon, grant, screen). This map is wiring
/// between provider architecture and navigation shell — merging the two
/// would turn every provider refactor into a section-registry change.
const Map<String, List<ViewStateReset>> _sectionResets = {
  'home': [
    // كشف حسابي وكشف عملي دفعان من اختصارات الرئيسية لا من قسمٍ في الدرج،
    // لكن حالة كل منهما تعيش في مزود الجذر فتحتاج تفريغاً عند الخروج من الجلسة.
    // Both personal statements are pushed from home shortcuts rather than a
    // drawer section, yet each holds its state in a root provider and must be
    // cleared at session end.
    _resetMyFinancialStatement,
    _resetMyWorkStatement,
  ],
  'customers': [
    _resetCustomersList,
    _resetMeasurementCustomers,
  ],
  'accounts': [
    _resetAccountTree,
    _resetChartAccounts,
  ],
  'stores': [
    _resetStoresList,
    _resetItems,
    _resetSubItems,
    _resetOrders,
    _resetStockSheet,
    _resetBalances,
    _resetStoreReport,
  ],
  'tailoring': [
    _resetCuttingBills,
  ],
  'workers': [
    _resetWorkersLists,
    _resetWorkerStatement,
    _resetWorkerWorkReport,
    _resetWorkerGroupWorkReport,
  ],
  'management': [
    _resetAdminUsers,
    _resetActiveSessions,
    _resetUserActivity,
    _resetSupportInquiries,
  ],
  'services': [
    _resetProvidersList,
    _resetMessages,
    _resetJobs,
  ],
  // sales / settings لا تحمل أي حالة بحث أو معطيات في مزودات مشتركة:
  // الأولى placeholder، والثانية local prefs.
  // sales / settings hold no cross-screen search or filter state: the first is
  // a placeholder, the second local preferences.
};

/// تفريغ حالة البحث/الفلاتر لكل مزودات قسمٍ بعينه.
/// Wipes the transient search/filter state held by one portal section.
///
/// يستدعيه `EmployeeMainLayout` عند تغيّر القسم المختار — يُمرَّر القسم
/// الذي **غادره** المستخدم، لا الذي دخل إليه. `reload: true` لأن الشاشة
/// القديمة لا تزال mounted داخل `IndexedStack` ولن تعيد جلب نفسها.
/// Called by `EmployeeMainLayout` when the active section changes — the section
/// the user **left**, not the one they entered. `reload: true` because the
/// outgoing screen is still mounted inside the `IndexedStack` and won't refetch
/// itself on return.
void resetSectionViewState(
  WidgetRef ref,
  String sectionId, {
  bool reload = true,
}) {
  final resets = _sectionResets[sectionId];
  if (resets == null) return; // home / sales / settings — nothing to clear.

  for (final reset in resets) {
    reset(ref, reload: reload);
  }
}

/// تفريغ حالة كل الأقسام في آنٍ واحد — المسار الموحد لنهاية الجلسة.
/// Wipes every section's transient state in one call — the single path for
/// session end.
///
/// لماذا مكان واحد؟ التوجيه عند خروج المستخدم مركزي في `KyApp` (ثلاث مخرج:
/// إنهاء المدير، مهلة الخمول، الخروج العادي)، وكل مخرج يجب أن يُنظّف
/// بنفس الدرجة. تكرار التنظيف في كل شاشة يعني مساراً يُنسى دائماً — وهو
/// نفس الخطأ الذي أبقي شاشة ميتة مرسومة بعد انتهاء الجلسة.
/// One place because routing on sign-out is already centralised in `KyApp`
/// and the session ends three ways (admin termination, idle timeout, manual
/// logout). Every exit must clean up equally; repeating this across screens
/// is how one path always ends up missed — the exact bug class that used to
/// leave a dead session's portal on screen.
///
/// `reload: false` — بعد الخروج لن يعود المستخدم إلى أي قسم، فإعادة
/// جلب أي قائمة مجرد هدر للشبكة.
/// `reload: false` — after sign-out the user cannot land on any section in
/// this session, so refetching anything would just burn bandwidth.
void resetSessionViewState(WidgetRef ref) {
  for (final entry in _sectionResets.entries) {
    for (final reset in entry.value) {
      reset(ref, reload: false);
    }
  }
}

/// الاختبار يستعلم عن الأقسام المسجّلة — للتأكد أن إضافة قسم جديد لا تُنسى
/// هنا. مطابقة لمعرّفات `portalSections` شرطٌ لازم.
/// Exposed for the guard test — so a new section is never added to the drawer
/// without also appearing here. Sync with `portalSections` is a hard rule.
Set<String> get knownResetSectionIds => _sectionResets.keys.toSet();
