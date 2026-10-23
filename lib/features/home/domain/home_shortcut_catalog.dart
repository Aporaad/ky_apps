import 'package:flutter/material.dart';

import '../../../core/constants/permission_codes.dart';
import '../../../core/utils/permission_check.dart';
import '../../accounts/presentation/screens/account_group_statement_screen.dart';
import '../../accounts/presentation/screens/account_statement_detail_screen.dart';
import '../../accounts/presentation/screens/account_statement_screen.dart';
import '../../accounts/presentation/screens/account_tree_screen.dart';
import '../../accounts/presentation/screens/create_account_screen.dart';
import '../../accounts/presentation/screens/currency_screen.dart';
import '../../admin/presentation/screens/active_sessions_screen.dart';
import '../../admin/presentation/screens/add_user_screen.dart';
import '../../admin/presentation/screens/admin_users_screen.dart';
import '../../admin/presentation/screens/permissions_catalog_screen.dart';
import '../../admin/presentation/screens/security_settings_screen.dart'
    as admin;
import '../../app_config/presentation/screens/app_config_screen.dart';
import '../../customers/presentation/screens/add_customer_screen.dart';
import '../../customers/presentation/screens/all_customers_screen.dart';
import '../../workers/presentation/screens/cutters_list_screen.dart';
import '../../workers/presentation/screens/employees_list_screen.dart';
import '../../workers/presentation/screens/tailors_list_screen.dart';
import '../../workers/presentation/screens/worker_group_work_report_screen.dart';
import '../../services/presentation/screens/config/service_config_screen.dart';
import '../../services/presentation/screens/jobs/jobs_list_screen.dart';
import '../../services/presentation/screens/messaging/sms_log_screen.dart';
import '../../services/presentation/screens/messaging/whatsapp_log_screen.dart';
import '../../services/presentation/screens/providers/providers_list_screen.dart';
import '../presentation/screens/home_customize_screen.dart';
import 'home_shortcut.dart';
import 'home_shortcut_flows.dart';

/// كتالوج اختصارات الواجهة الرئيسية — ثلاثون بطاقة، مصدرها الوحيد هذا الملف
/// The home-screen shortcut catalog — thirty cards, declared here and nowhere else.
///
/// القواعد التي يحرسها الاختبار (`test/home_catalog_test.dart`) لا تُكتب هنا مرتين:
/// - كل `id` فريد وبصيغة `module.action`، وكل كود صلاحية موجود في مرآة الكتالوج.
/// - كل `SectionTarget` يحمل `viewCodes` الخاصة بقسمه في السجل حرفيًا — فلا يُفتح قسم بكود
///   أخفّ من كوده الحقيقي، والعكس.
/// - الأقسام التي ما تزال حالات فارغة تُوسم `underDevelopment` ولا تُخفى.
/// Rules the catalog test pins, so they are not restated here:
/// - Every id is unique and `module.action`-shaped, and every permission code exists in the mirror.
/// - Every `SectionTarget` carries its registry `viewCodes` verbatim — never a weaker code.
/// - Sections that are still empty states stay visible with an `underDevelopment` badge.
///
/// الثابت `const` لأن كل الأهداف مراجع بنّاءات ودوال عليا (لا كلاشرات).
/// The list is `const` because every target is a constructor or top-level function reference.
const List<HomeShortcut> homeShortcutCatalog = [
  // ── المبيعات / sales ─────────────────────────────────────
  HomeShortcut(
    id: 'sales.section',
    title: 'المبيعات',
    icon: Icons.point_of_sale_rounded,
    sectionId: 'sales',
    target: SectionTarget('sales'),
    codes: [Perm.salesView],
    underDevelopment: true,
  ),

  // ── التفصيل / tailoring ──────────────────────────────────
  HomeShortcut(
    id: 'tailoring.section',
    title: 'التفصيل',
    icon: Icons.content_cut_rounded,
    sectionId: 'tailoring',
    target: SectionTarget('tailoring'),
    codes: [Perm.tailoringView],
    underDevelopment: true,
  ),

  // ── العملاء / customers ──────────────────────────────────
  HomeShortcut(
    id: 'customers.section',
    title: 'العملاء',
    icon: Icons.people_rounded,
    sectionId: 'customers',
    target: SectionTarget('customers'),
    codes: [Perm.customersView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'customers.list',
    title: 'كل العملاء',
    icon: Icons.format_list_bulleted_rounded,
    sectionId: 'customers',
    target: ScreenTarget(AllCustomersScreen.new),
    codes: [Perm.customersView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'customers.add',
    title: 'إضافة عميل',
    icon: Icons.person_add_alt_1_rounded,
    sectionId: 'customers',
    target: ScreenTarget(AddCustomerScreen.new),
    codes: [Perm.customersCreate],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'customers.statement',
    title: 'كشف حساب عميل',
    icon: Icons.receipt_long_rounded,
    sectionId: 'customers',
    target: FlowTarget(openCustomerStatement),
    codes: [Perm.customersStatement],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'customers.edit',
    title: 'تعديل عميل',
    icon: Icons.edit_note_rounded,
    sectionId: 'customers',
    target: FlowTarget(openCustomerEdit),
    codes: [Perm.customersUpdate],
  ),

  // ── جاري العاملين / workers ──────────────────────────────
  // «جاري العاملين» يغطي ثلاث سجلات، فظهوره يكفي فيه أي واحد ممنوح — نفس قاعدة السجل
  // «جاري العاملين» spans three registries, so any one of their view codes is enough.
  HomeShortcut(
    id: 'workers.section',
    title: 'جاري العاملين',
    icon: Icons.groups_2_rounded,
    sectionId: 'workers',
    target: SectionTarget('workers'),
    codes: [Perm.employeesView, Perm.cuttersView, Perm.tailorsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'workers.employees',
    title: 'الموظفين',
    icon: Icons.badge_rounded,
    sectionId: 'workers',
    target: ScreenTarget(EmployeesListScreen.new),
    codes: [Perm.employeesView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'workers.cutters',
    title: 'القصاصين',
    icon: Icons.content_cut_rounded,
    sectionId: 'workers',
    target: ScreenTarget(CuttersListScreen.new),
    codes: [Perm.cuttersView],
  ),
  HomeShortcut(
    id: 'workers.tailors',
    title: 'الخياطين',
    icon: Icons.design_services_rounded,
    sectionId: 'workers',
    target: ScreenTarget(TailorsListScreen.new),
    codes: [Perm.tailorsView],
  ),
  HomeShortcut(
    id: 'workers.group_work',
    title: 'كشف عمل مجموعة',
    icon: Icons.summarize_rounded,
    sectionId: 'workers',
    target: ScreenTarget(WorkerGroupWorkReportScreen.new),
    codes: [Perm.cuttersStatement, Perm.tailorsStatement],
  ),

  HomeShortcut(
    id: 'workers.add_employee',
    title: 'إضافة موظف',
    icon: Icons.person_add_alt_rounded,
    sectionId: 'workers',
    target: ScreenTarget(buildAddEmployeeScreen),
    codes: [Perm.employeesCreate],
  ),
  HomeShortcut(
    id: 'workers.add_cutter',
    title: 'إضافة قصاص',
    icon: Icons.content_cut_rounded,
    sectionId: 'workers',
    target: ScreenTarget(buildAddCutterScreen),
    codes: [Perm.cuttersCreate],
  ),
  HomeShortcut(
    id: 'workers.add_tailor',
    title: 'إضافة خياط',
    icon: Icons.design_services_rounded,
    sectionId: 'workers',
    target: ScreenTarget(buildAddTailorScreen),
    codes: [Perm.tailorsCreate],
  ),

  // ── الحسابات / accounts ──────────────────────────────────
  HomeShortcut(
    id: 'accounts.section',
    title: 'الحسابات',
    icon: Icons.account_balance_rounded,
    sectionId: 'accounts',
    target: SectionTarget('accounts'),
    codes: [Perm.accountsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.tree',
    title: 'دليل الحسابات',
    icon: Icons.account_tree_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(AccountTreeScreen.new),
    codes: [Perm.accountsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.statement',
    title: 'كشف حساب مالي',
    icon: Icons.request_quote_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(AccountStatementScreen.new),
    codes: [Perm.accountsStatement],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.group',
    title: 'كشف مجموعة حسابات جزئية',
    icon: Icons.balance_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(AccountGroupStatementScreen.new),
    codes: [Perm.accountsStatement],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.analysis',
    title: 'كشف حساب تحليلي مفصل',
    icon: Icons.analytics_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(AccountStatementDetailScreen.new),
    codes: [Perm.accountsStatement],
  ),
  HomeShortcut(
    id: 'accounts.create',
    title: 'إضافة حساب',
    icon: Icons.create_new_folder_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(CreateAccountScreen.new),
    codes: [Perm.accountsCreate],
  ),
  HomeShortcut(
    id: 'accounts.edit',
    title: 'تعديل بيانات حساب',
    icon: Icons.edit_document,
    sectionId: 'accounts',
    target: FlowTarget(openAccountEdit),
    codes: [Perm.accountsUpdate],
  ),
  HomeShortcut(
    id: 'accounts.currencies',
    title: 'العملات وأسعار الصرف',
    icon: Icons.currency_exchange_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(CurrencyScreen.new),
    codes: [Perm.currenciesView],
  ),

  // ── المخازن / stores ─────────────────────────────────────
  HomeShortcut(
    id: 'stores.section',
    title: 'المخازن',
    icon: Icons.inventory_2_rounded,
    sectionId: 'stores',
    target: SectionTarget('stores'),
    codes: [Perm.storesView],
    underDevelopment: true,
  ),

  // ── الإدارة / management ─────────────────────────────────
  HomeShortcut(
    id: 'management.section',
    title: 'الإدارة',
    icon: Icons.admin_panel_settings_rounded,
    sectionId: 'management',
    target: SectionTarget('management'),
    codes: [Perm.managementView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'management.users',
    title: 'إدارة المستخدمين',
    icon: Icons.manage_accounts_rounded,
    sectionId: 'management',
    target: ScreenTarget(AdminUsersScreen.new),
    codes: [Perm.usersView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'management.add_user',
    title: 'إضافة مستخدم',
    icon: Icons.person_add_alt_rounded,
    sectionId: 'management',
    target: ScreenTarget(AddUserScreen.new),
    codes: [Perm.usersCreate],
  ),
  HomeShortcut(
    id: 'management.edit_user',
    title: 'تعديل مستخدم',
    icon: Icons.edit_rounded,
    sectionId: 'management',
    target: FlowTarget(openUserEdit),
    codes: [Perm.usersUpdate],
  ),
  HomeShortcut(
    id: 'management.grants',
    title: 'منح الصلاحيات',
    icon: Icons.verified_user_rounded,
    sectionId: 'management',
    target: FlowTarget(openUserGrants),
    codes: [Perm.usersPermissionsManage],
  ),
  HomeShortcut(
    id: 'management.sessions',
    title: 'الجلسات النشطة',
    icon: Icons.devices_other_rounded,
    sectionId: 'management',
    target: ScreenTarget(ActiveSessionsScreen.new),
    codes: [Perm.sessionsView],
  ),
  // نسخة الإدارة باسم مستعار: يوجد `SecuritySettingsScreen` ثانٍ في `features/settings`
  // The admin copy, imported with a prefix: a second `SecuritySettingsScreen` lives in settings.
  HomeShortcut(
    id: 'management.security',
    title: 'إعدادات الأمان',
    icon: Icons.shield_rounded,
    sectionId: 'management',
    target: ScreenTarget(admin.SecuritySettingsScreen.new),
    codes: [Perm.settingsView],
  ),
  HomeShortcut(
    id: 'management.catalog',
    title: 'كتالوج الصلاحيات',
    icon: Icons.key_rounded,
    sectionId: 'management',
    target: ScreenTarget(PermissionsCatalogScreen.new),
    codes: [Perm.usersView],
  ),
  HomeShortcut(
    id: 'management.activity',
    title: 'سجل النشاط',
    icon: Icons.fact_check_rounded,
    sectionId: 'management',
    target: FlowTarget(openUserActivity),
    codes: [Perm.usersActivityView],
  ),

  // ── الخدمات والمزودين / services ─────────────────────────
  // بطاقات القسم كلها `defaultOn:false`: تظهر في التخصيص ولا تُحصى ضمن الافتراضية المحروسة
  // Every services card is `defaultOn:false`: it surfaces in customization, not in the guarded default.
  HomeShortcut(
    id: 'services.section',
    title: 'الخدمات والمزودين',
    icon: Icons.category_rounded,
    sectionId: 'services',
    target: SectionTarget('services'),
    // تُطابق `viewCodes` السجل حرفيًا — خمسة أكواد، لا أُنقص ولا أزيد
    // Mirrors the registry viewCodes verbatim — five codes, neither fewer nor more.
    codes: [
      Perm.servicesView,
      Perm.providersView,
      Perm.smsView,
      Perm.whatsappView,
      Perm.jobsView,
    ],
  ),
  HomeShortcut(
    id: 'providers.list',
    title: 'المزودون',
    icon: Icons.local_shipping_rounded,
    sectionId: 'services',
    target: ScreenTarget(ProvidersListScreen.new),
    codes: [Perm.providersView],
  ),
  HomeShortcut(
    id: 'sms.log',
    title: 'سجل الرسائل النصية',
    icon: Icons.sms_rounded,
    sectionId: 'services',
    target: ScreenTarget(SmsLogScreen.new),
    codes: [Perm.smsView],
  ),
  HomeShortcut(
    id: 'whatsapp.log',
    title: 'سجل رسائل واتساب',
    icon: Icons.whatshot_rounded,
    sectionId: 'services',
    target: ScreenTarget(WhatsappLogScreen.new),
    codes: [Perm.whatsappView],
  ),
  HomeShortcut(
    id: 'services.config',
    title: 'إعدادات الخدمات',
    icon: Icons.tune_rounded,
    sectionId: 'services',
    target: ScreenTarget(ServiceConfigScreen.new),
    codes: [Perm.servicesView],
  ),
  HomeShortcut(
    id: 'jobs.manage',
    title: 'إدارة المهام الزمنية',
    icon: Icons.schedule_rounded,
    sectionId: 'services',
    target: ScreenTarget(JobsListScreen.new),
    codes: [Perm.jobsView],
  ),

  // ── الإعدادات / settings ─────────────────────────────────
  // الإعدادات المحلية بلا شرط في السجل، فتبقى كذلك هنا: بطاقة واحدة دائمة لكل مستخدم
  // Local settings are ungated in the registry and stay ungated here — one card for everyone.
  HomeShortcut(
    id: 'settings.section',
    title: 'الإعدادات',
    icon: Icons.settings_rounded,
    sectionId: 'settings',
    target: SectionTarget('settings'),
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'settings.api',
    title: 'إعدادات الاتصال',
    icon: Icons.dns_rounded,
    sectionId: 'settings',
    target: RouteTarget('/api-settings'),
    codes: [Perm.appConfigApiManage],
  ),
  HomeShortcut(
    id: 'settings.biometric',
    title: 'الأمان والبصمة',
    icon: Icons.fingerprint_rounded,
    sectionId: 'settings',
    target: RouteTarget('/security-settings'),
  ),
  HomeShortcut(
    id: 'settings.appconfig',
    title: 'تهيئة التطبيق',
    icon: Icons.palette_rounded,
    sectionId: 'settings',
    target: ScreenTarget(AppConfigScreen.new),
    codes: [Perm.appConfigUpdate],
  ),

  // ── الرئيسية / home ──────────────────────────────────────
  // مثبّتة: لا تُخفى ولا تُرتّب، فهي مخرج الطوارئ من تخصيص خاطئ
  // Pinned: never hidden nor reordered — the way out of a bad layout.
  HomeShortcut(
    id: 'home.customize',
    title: 'تخصيص الاختصارات',
    icon: Icons.dashboard_customize_rounded,
    sectionId: 'home',
    target: ScreenTarget(HomeCustomizeScreen.new),
    // `pinned` وحدها تكفي: البطاقة ظاهرة دائمًا، و`defaultOn` هنا كانت ستُحصى مرتين
    // `pinned` alone is enough: the card is always visible, and `defaultOn` would double-count it.
    pinned: true,
  ),
];

/// الاختصارات التي تُعرض لمستخدمٍ بمنح معيّنة، بترتيب الكتالوج
/// The shortcuts shown to a user holding these grants, in catalog order.
///
/// الفلترة هنا لا في الكتالوج: الكتالوج ثابت، والمنح تتغيّر أثناء الجلسة. ولا تُخزَّن النتيجة
/// أبدًا — تخزين «ما رآه المستخدم» يقدُم فيصير خطأً بعد أول سحب صلاحية.
/// Filtering happens here, not in the catalog: the catalog is static while grants move mid-session.
/// The result is never persisted — a stored "what the user saw" ages into a wrong answer.
List<HomeShortcut> allowedHomeShortcuts({
  required Set<String> granted,
  required bool isAdmin,
}) {
  return [
    for (final shortcut in homeShortcutCatalog)
      // البطاقة بلا أكواد ممنوحة للجميع، و`canAnyCode` يعيد false على قائمة فارغة
      // An ungated card is granted to everyone, and `canAnyCode` answers false on an empty list.
      if (shortcut.ungated ||
          canAnyCode(granted: granted, isAdmin: isAdmin, codes: shortcut.codes))
        shortcut,
  ];
}
