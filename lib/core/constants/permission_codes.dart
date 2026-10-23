/// أكواد الصلاحيات المعتمدة — نسخة طبق الأصل من كتالوج الخادم
/// Canonical permission codes — an exact mirror of the server catalog.
///
/// المصدر الحقيقي هو `kyApp_API/app/Support/PermissionCatalog.php` (127 كوداً في 23 قسماً)،
/// وهذه النسخة تُستخدم في الواجهة لتفادي استعلام الشبكة لكل قرار حجب. أي كود يُضاف في الخادم
/// يجب أن يُضاف هنا في نفس الطلب، وإلا ظهر عنصر في الواجهة لا يمرّ على الخادم أو العكس.
/// The server catalog is the source of truth; this mirror exists so gating decisions never need
/// a network round-trip. Add a code here in the same change that adds it server-side.
///
/// نمط الكود `القسم.الفعل`، وبما أن الحجب اتبعاً للهوية فالرفض افتراضي: لا كود ⇒ لا وصول.
/// Code pattern is `module.action`, and access is denied by default: no code means no access.
class Perm {
  Perm._();

  // ── الرئيسية / dashboard ─────────────────────────────────
  static const String dashboardWildcard = 'dashboard.*';
  static const String dashboardView = 'dashboard.view';

  // ── المبيعات / sales ─────────────────────────────────────
  static const String salesWildcard = 'sales.*';
  static const String salesView = 'sales.view';
  static const String salesCreate = 'sales.create';
  static const String salesUpdate = 'sales.update';
  static const String salesDelete = 'sales.delete';
  static const String salesPrint = 'sales.print';
  static const String salesExport = 'sales.export';

  // ── كروت التفصيل / tailoring ─────────────────────────────
  static const String tailoringWildcard = 'tailoring.*';
  static const String tailoringView = 'tailoring.view';
  static const String tailoringCreate = 'tailoring.create';
  static const String tailoringUpdate = 'tailoring.update';
  static const String tailoringDelete = 'tailoring.delete';
  static const String tailoringPrint = 'tailoring.print';
  static const String tailoringDeliver = 'tailoring.deliver';

  // ── العملاء / customers ──────────────────────────────────
  static const String customersWildcard = 'customers.*';
  static const String customersView = 'customers.view';
  static const String customersCreate = 'customers.create';
  static const String customersUpdate = 'customers.update';
  static const String customersDelete = 'customers.delete';
  static const String customersStatement = 'customers.statement';
  static const String customersPrint = 'customers.print';
  static const String customersExport = 'customers.export';
  static const String customersEditLimit = 'customers.edit_limit';

  // ── الموظفين / employees ─────────────────────────────────
  static const String employeesWildcard = 'employees.*';
  static const String employeesView = 'employees.view';
  static const String employeesCreate = 'employees.create';
  static const String employeesUpdate = 'employees.update';
  static const String employeesDelete = 'employees.delete';
  static const String employeesToggle = 'employees.toggle';
  static const String employeesStatement = 'employees.statement';

  // ── القصاصين / cutters ───────────────────────────────────
  static const String cuttersWildcard = 'cutters.*';
  static const String cuttersView = 'cutters.view';
  static const String cuttersCreate = 'cutters.create';
  static const String cuttersUpdate = 'cutters.update';
  static const String cuttersDelete = 'cutters.delete';
  static const String cuttersToggle = 'cutters.toggle';
  static const String cuttersStatement = 'cutters.statement';

  // ── الخياطين / tailors ───────────────────────────────────
  static const String tailorsWildcard = 'tailors.*';
  static const String tailorsView = 'tailors.view';
  static const String tailorsCreate = 'tailors.create';
  static const String tailorsUpdate = 'tailors.update';
  static const String tailorsDelete = 'tailors.delete';
  static const String tailorsToggle = 'tailors.toggle';
  static const String tailorsStatement = 'tailors.statement';

  // ── الحسابات / accounts ──────────────────────────────────
  static const String accountsWildcard = 'accounts.*';
  static const String accountsView = 'accounts.view';
  static const String accountsCreate = 'accounts.create';
  static const String accountsUpdate = 'accounts.update';
  static const String accountsDelete = 'accounts.delete';
  static const String accountsStructureManage = 'accounts.structure_manage';
  static const String accountsStatement = 'accounts.statement';
  static const String accountsPrint = 'accounts.print';
  static const String accountsExport = 'accounts.export';

  // ── العملات / currencies ─────────────────────────────────
  static const String currenciesWildcard = 'currencies.*';
  static const String currenciesView = 'currencies.view';
  static const String currenciesCreate = 'currencies.create';
  static const String currenciesUpdate = 'currencies.update';
  static const String currenciesDelete = 'currencies.delete';
  static const String currenciesPricesView = 'currencies.prices_view';
  static const String currenciesPricesManage = 'currencies.prices_manage';

  // ── الفواتير / invoices ──────────────────────────────────
  static const String invoicesWildcard = 'invoices.*';
  static const String invoicesView = 'invoices.view';
  static const String invoicesPrint = 'invoices.print';
  static const String invoicesExport = 'invoices.export';

  // ── المخازن / stores ─────────────────────────────────────
  static const String storesWildcard = 'stores.*';
  static const String storesView = 'stores.view';
  static const String storesCreate = 'stores.create';
  static const String storesUpdate = 'stores.update';
  static const String storesDelete = 'stores.delete';

  // ── التقارير / reports ───────────────────────────────────
  static const String reportsWildcard = 'reports.*';
  static const String reportsView = 'reports.view';
  static const String reportsExport = 'reports.export';

  // ── الإدارة / management ─────────────────────────────────
  static const String managementWildcard = 'management.*';
  static const String managementView = 'management.view';

  // ── إدارة المستخدمين / users ─────────────────────────────
  static const String usersWildcard = 'users.*';
  static const String usersView = 'users.view';
  static const String usersCreate = 'users.create';
  static const String usersUpdate = 'users.update';
  static const String usersDelete = 'users.delete';
  static const String usersToggle = 'users.toggle';
  static const String usersPermissionsManage = 'users.permissions_manage';
  static const String usersActivityView = 'users.activity_view';
  static const String usersAdminFlagManage = 'users.admin_flag_manage';

  // ── الجلسات النشطة / sessions ────────────────────────────
  static const String sessionsWildcard = 'sessions.*';
  static const String sessionsView = 'sessions.view';
  static const String sessionsTerminate = 'sessions.terminate';

  // ── إعدادات الأمان / settings ────────────────────────────
  static const String settingsWildcard = 'settings.*';
  static const String settingsView = 'settings.view';
  static const String settingsUpdate = 'settings.update';
  static const String settingsSecurityManage = 'settings.security_manage';

  // ── إعدادات التطبيق / app_config ─────────────────────────
  /// هوية الشركة والمظهر وإعدادات اتصال API
  /// Company identity, theming, and API connection settings.
  static const String appConfigWildcard = 'app_config.*';
  static const String appConfigView = 'app_config.view';
  static const String appConfigUpdate = 'app_config.update';
  static const String appConfigApiManage = 'app_config.api_manage';

  // ── الخدمات والمزودون / services ─────────────────────────
  static const String servicesWildcard = 'services.*';
  static const String servicesView = 'services.view';
  static const String servicesUpdate = 'services.update';
  static const String servicesSettingsManage = 'services.settings_manage';

  // ── إدارة المزودين / providers ───────────────────────────
  static const String providersWildcard = 'providers.*';
  static const String providersView = 'providers.view';
  static const String providersCreate = 'providers.create';
  static const String providersUpdate = 'providers.update';
  static const String providersDelete = 'providers.delete';
  static const String providersToggle = 'providers.toggle';
  static const String providersSubscriptionsManage = 'providers.subscriptions_manage';
  static const String providersRevealCredentials = 'providers.reveal_credentials';

  // ── خدمة الرسائل النصية / sms ────────────────────────────
  static const String smsWildcard = 'sms.*';
  static const String smsView = 'sms.view';
  static const String smsCreate = 'sms.create';
  static const String smsUpdate = 'sms.update';
  static const String smsDelete = 'sms.delete';
  static const String smsToggle = 'sms.toggle';

  // ── خدمة رسائل واتساب / whatsapp ─────────────────────────
  static const String whatsappWildcard = 'whatsapp.*';
  static const String whatsappView = 'whatsapp.view';
  static const String whatsappCreate = 'whatsapp.create';
  static const String whatsappUpdate = 'whatsapp.update';
  static const String whatsappDelete = 'whatsapp.delete';
  static const String whatsappToggle = 'whatsapp.toggle';

  // ── إدارة المهام الزمنية / jobs ──────────────────────────
  static const String jobsWildcard = 'jobs.*';
  static const String jobsView = 'jobs.view';
  static const String jobsCreate = 'jobs.create';
  static const String jobsUpdate = 'jobs.update';
  static const String jobsDelete = 'jobs.delete';
  static const String jobsToggle = 'jobs.toggle';

  // ── النظام / system ──────────────────────────────────────
  /// منح شامل: من يملك `system.*` يملك كل شيء (نفس قاعدة `PermissionResolver::can`)
  /// The all-encompassing grant: `system.*` covers every code (same rule as the server resolver).
  static const String systemWildcard = 'system.*';
}

/// كل الأكواد بترتيب الكتالوج — تُستخدم لاختبار التطابق مع الخادم
/// Every code in catalog order — used by the client/server parity test.
const List<String> allPermissionCodes = [
  Perm.dashboardWildcard,
  Perm.dashboardView,
  Perm.salesWildcard,
  Perm.salesView,
  Perm.salesCreate,
  Perm.salesUpdate,
  Perm.salesDelete,
  Perm.salesPrint,
  Perm.salesExport,
  Perm.tailoringWildcard,
  Perm.tailoringView,
  Perm.tailoringCreate,
  Perm.tailoringUpdate,
  Perm.tailoringDelete,
  Perm.tailoringPrint,
  Perm.tailoringDeliver,
  Perm.customersWildcard,
  Perm.customersView,
  Perm.customersCreate,
  Perm.customersUpdate,
  Perm.customersDelete,
  Perm.customersStatement,
  Perm.customersPrint,
  Perm.customersExport,
  Perm.customersEditLimit,
  Perm.employeesWildcard,
  Perm.employeesView,
  Perm.employeesCreate,
  Perm.employeesUpdate,
  Perm.employeesDelete,
  Perm.employeesToggle,
  Perm.employeesStatement,
  Perm.cuttersWildcard,
  Perm.cuttersView,
  Perm.cuttersCreate,
  Perm.cuttersUpdate,
  Perm.cuttersDelete,
  Perm.cuttersToggle,
  Perm.cuttersStatement,
  Perm.tailorsWildcard,
  Perm.tailorsView,
  Perm.tailorsCreate,
  Perm.tailorsUpdate,
  Perm.tailorsDelete,
  Perm.tailorsToggle,
  Perm.tailorsStatement,
  Perm.accountsWildcard,
  Perm.accountsView,
  Perm.accountsCreate,
  Perm.accountsUpdate,
  Perm.accountsDelete,
  Perm.accountsStructureManage,
  Perm.accountsStatement,
  Perm.accountsPrint,
  Perm.accountsExport,
  Perm.currenciesWildcard,
  Perm.currenciesView,
  Perm.currenciesCreate,
  Perm.currenciesUpdate,
  Perm.currenciesDelete,
  Perm.currenciesPricesView,
  Perm.currenciesPricesManage,
  Perm.invoicesWildcard,
  Perm.invoicesView,
  Perm.invoicesPrint,
  Perm.invoicesExport,
  Perm.storesWildcard,
  Perm.storesView,
  Perm.storesCreate,
  Perm.storesUpdate,
  Perm.storesDelete,
  Perm.reportsWildcard,
  Perm.reportsView,
  Perm.reportsExport,
  Perm.managementWildcard,
  Perm.managementView,
  Perm.usersWildcard,
  Perm.usersView,
  Perm.usersCreate,
  Perm.usersUpdate,
  Perm.usersDelete,
  Perm.usersToggle,
  Perm.usersPermissionsManage,
  Perm.usersActivityView,
  Perm.usersAdminFlagManage,
  Perm.sessionsWildcard,
  Perm.sessionsView,
  Perm.sessionsTerminate,
  Perm.settingsWildcard,
  Perm.settingsView,
  Perm.settingsUpdate,
  Perm.settingsSecurityManage,
  Perm.appConfigWildcard,
  Perm.appConfigView,
  Perm.appConfigUpdate,
  Perm.appConfigApiManage,
  Perm.servicesWildcard,
  Perm.servicesView,
  Perm.servicesUpdate,
  Perm.servicesSettingsManage,
  Perm.providersWildcard,
  Perm.providersView,
  Perm.providersCreate,
  Perm.providersUpdate,
  Perm.providersDelete,
  Perm.providersToggle,
  Perm.providersSubscriptionsManage,
  Perm.providersRevealCredentials,
  Perm.smsWildcard,
  Perm.smsView,
  Perm.smsCreate,
  Perm.smsUpdate,
  Perm.smsDelete,
  Perm.smsToggle,
  Perm.whatsappWildcard,
  Perm.whatsappView,
  Perm.whatsappCreate,
  Perm.whatsappUpdate,
  Perm.whatsappDelete,
  Perm.whatsappToggle,
  Perm.jobsWildcard,
  Perm.jobsView,
  Perm.jobsCreate,
  Perm.jobsUpdate,
  Perm.jobsDelete,
  Perm.jobsToggle,
  Perm.systemWildcard,
];

/// ترتيب الأقسام كما تعرضه شاشة المنح — مطابق لـ `SORT_ORDER` في الخادم
/// Section display order, matching the server's `SORT_ORDER`.
const List<String> permModuleOrder = [
  'dashboard',
  'sales',
  'tailoring',
  'customers',
  'employees',
  'cutters',
  'tailors',
  'accounts',
  'currencies',
  'invoices',
  'stores',
  'reports',
  'management',
  'users',
  'sessions',
  'settings',
  'app_config',
  'services',
  'providers',
  'sms',
  'whatsapp',
  'jobs',
  'system',
];

/// عناوين الأقسام بالعربية — عمود الترويسة في شاشة «التحكم بصلاحيات المستخدم»
/// Arabic section titles used as group headers in the permission control screen.
const Map<String, String> permModuleLabels = {
  'dashboard': 'الرئيسية',
  'sales': 'المبيعات',
  'tailoring': 'كروت التفصيل',
  'customers': 'العملاء',
  'employees': 'الموظفين',
  'cutters': 'القصاصين',
  'tailors': 'الخياطين',
  'accounts': 'الحسابات',
  'currencies': 'العملات',
  'invoices': 'الفواتير',
  'stores': 'المخازن',
  'reports': 'التقارير',
  'management': 'الإدارة',
  'users': 'إدارة المستخدمين',
  'sessions': 'الجلسات النشطة',
  'settings': 'إعدادات الأمان',
  'app_config': 'إعدادات التطبيق',
  'services': 'الخدمات والمزودين',
  'providers': 'إدارة المزودين',
  'sms': 'خدمة الرسائل النصية',
  'whatsapp': 'خدمة رسائل واتساب',
  'jobs': 'إدارة المهام الزمنية',
  'system': 'النظام',
};

/// تسميات الأفعال — شارة صغيرة بجانب كل صلاحية في شاشة المنح
/// Action labels shown as a chip beside each code in the grant screen.
const Map<String, String> permActionLabels = {
  '*': 'كل الصلاحيات',
  'view': 'عرض',
  'create': 'إضافة',
  'update': 'تعديل',
  'delete': 'حذف',
  'print': 'طباعة',
  'export': 'تصدير',
  'statement': 'كشف حساب',
  'toggle': 'تفعيل/تعطيل',
  'deliver': 'تسليم',
  'edit_limit': 'تعديل السقف',
  'structure_manage': 'إدارة الهيكل',
  'prices_view': 'عرض الأسعار',
  'prices_manage': 'إدارة الأسعار',
  'permissions_manage': 'إدارة الصلاحيات',
  'activity_view': 'سجل النشاط',
  'admin_flag_manage': 'صفة المدير',
  'terminate': 'إنهاء الجلسة',
  'security_manage': 'إدارة حساسة',
  'api_manage': 'إدارة اتصال API',
  'settings_manage': 'إدارة إعدادات الخدمات',
  'subscriptions_manage': 'إدارة الاشتراكات',
  'reveal_credentials': 'إظهار بيانات الدخول',
};

/// اسم القسم المستخرج من الكود (`customers.view` ⇒ `customers`)
/// The module part of a code (`customers.view` ⇒ `customers`).
String permModuleOf(String code) {
  final dot = code.indexOf('.');
  return dot < 0 ? code : code.substring(0, dot);
}

/// الفعل المستخرج من الكود، مع دعم الأفعال المركّبة (`prices_view`)
/// The action part of a code, including underscored compound actions.
String permActionOf(String code) {
  final dot = code.indexOf('.');
  return dot < 0 ? '*' : code.substring(dot + 1);
}

/// العنوان العربي الجاهز للترويسة، أو الكود الخام لأي قسم بلا تسمية
/// Arabic section title, or the raw code for any module that has no label.
String permModuleTitle(String code) {
  final module = permModuleOf(code);
  return permModuleLabels[module] ?? module;
}

/// كود المنح العام لقسم: `customers` ⇒ `customers.*`
/// The module-wide wildcard code: `customers` ⇒ `customers.*`.
///
/// يُبنى هنا لا يُخزَّن: القاعدة أن `*` هو الفعل الوحيد المسموح بتوسّطه، فلا يوجد كود آخر
/// بصيغة `module.*` في الكتالوج سوى هذا النمط.
/// Built rather than stored, because `*` is the only action that wildcard-grants a module.
String permWildcardOf(String module) => '$module.*';
