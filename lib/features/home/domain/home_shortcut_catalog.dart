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
    icon: Icons.point_of_sale_outlined,
    sectionId: 'sales',
    target: SectionTarget('sales'),
    codes: [Perm.salesView],
    underDevelopment: true,
  ),

  // ── التفصيل / tailoring ──────────────────────────────────
  HomeShortcut(
    id: 'tailoring.section',
    title: 'التفصيل',
    icon: Icons.content_cut_outlined,
    sectionId: 'tailoring',
    target: SectionTarget('tailoring'),
    codes: [Perm.tailoringView],
    underDevelopment: true,
  ),

  // ── العملاء / customers ──────────────────────────────────
  HomeShortcut(
    id: 'customers.section',
    title: 'العملاء',
    icon: Icons.people_outline_rounded,
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
    icon: Icons.groups_2_outlined,
    sectionId: 'workers',
    target: SectionTarget('workers'),
    codes: [Perm.employeesView, Perm.cuttersView, Perm.tailorsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'workers.employees',
    title: 'الموظفون',
    icon: Icons.badge_outlined,
    sectionId: 'workers',
    target: ScreenTarget(EmployeesListScreen.new),
    codes: [Perm.employeesView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'workers.cutters',
    title: 'القصاصون',
    icon: Icons.content_cut_rounded,
    sectionId: 'workers',
    target: ScreenTarget(CuttersListScreen.new),
    codes: [Perm.cuttersView],
  ),
  HomeShortcut(
    id: 'workers.tailors',
    title: 'الخياطون',
    icon: Icons.design_services_outlined,
    sectionId: 'workers',
    target: ScreenTarget(TailorsListScreen.new),
    codes: [Perm.tailorsView],
  ),

  // ── الحسابات / accounts ──────────────────────────────────
  HomeShortcut(
    id: 'accounts.section',
    title: 'الحسابات',
    icon: Icons.account_balance_outlined,
    sectionId: 'accounts',
    target: SectionTarget('accounts'),
    codes: [Perm.accountsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.tree',
    title: 'دليل الحسابات',
    icon: Icons.account_tree_outlined,
    sectionId: 'accounts',
    target: ScreenTarget(AccountTreeScreen.new),
    codes: [Perm.accountsView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.statement',
    title: 'كشف حساب مالي',
    icon: Icons.request_quote_outlined,
    sectionId: 'accounts',
    target: ScreenTarget(AccountStatementScreen.new),
    codes: [Perm.accountsStatement],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.group',
    title: 'ميزان المراجعة',
    icon: Icons.balance_rounded,
    sectionId: 'accounts',
    target: ScreenTarget(AccountGroupStatementScreen.new),
    codes: [Perm.accountsStatement],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'accounts.analysis',
    title: 'كشف تحليلي',
    icon: Icons.analytics_outlined,
    sectionId: 'accounts',
    target: ScreenTarget(AccountStatementDetailScreen.new),
    codes: [Perm.accountsStatement],
  ),
  HomeShortcut(
    id: 'accounts.create',
    title: 'إضافة حساب',
    icon: Icons.create_new_folder_outlined,
    sectionId: 'accounts',
    target: ScreenTarget(CreateAccountScreen.new),
    codes: [Perm.accountsCreate],
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
    icon: Icons.inventory_2_outlined,
    sectionId: 'stores',
    target: SectionTarget('stores'),
    codes: [Perm.storesView],
    underDevelopment: true,
  ),

  // ── الإدارة / management ─────────────────────────────────
  HomeShortcut(
    id: 'management.section',
    title: 'الإدارة',
    icon: Icons.admin_panel_settings_outlined,
    sectionId: 'management',
    target: SectionTarget('management'),
    codes: [Perm.managementView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'management.users',
    title: 'إدارة المستخدمين',
    icon: Icons.manage_accounts_outlined,
    sectionId: 'management',
    target: ScreenTarget(AdminUsersScreen.new),
    codes: [Perm.usersView],
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'management.sessions',
    title: 'الجلسات النشطة',
    icon: Icons.devices_other_outlined,
    sectionId: 'management',
    target: ScreenTarget(ActiveSessionsScreen.new),
    codes: [Perm.sessionsView],
  ),
  // نسخة الإدارة باسم مستعار: يوجد `SecuritySettingsScreen` ثانٍ في `features/settings`
  // The admin copy, imported with a prefix: a second `SecuritySettingsScreen` lives in settings.
  HomeShortcut(
    id: 'management.security',
    title: 'إعدادات الأمان',
    icon: Icons.shield_outlined,
    sectionId: 'management',
    target: ScreenTarget(admin.SecuritySettingsScreen.new),
    codes: [Perm.settingsView],
  ),
  HomeShortcut(
    id: 'management.catalog',
    title: 'كتالوج الصلاحيات',
    icon: Icons.key_outlined,
    sectionId: 'management',
    target: ScreenTarget(PermissionsCatalogScreen.new),
    codes: [Perm.usersView],
  ),
  HomeShortcut(
    id: 'management.activity',
    title: 'سجل النشاط',
    icon: Icons.fact_check_outlined,
    sectionId: 'management',
    target: FlowTarget(openUserActivity),
    codes: [Perm.usersActivityView],
  ),

  // ── الإعدادات / settings ─────────────────────────────────
  // الإعدادات المحلية بلا شرط في السجل، فتبقى كذلك هنا: بطاقة واحدة دائمة لكل مستخدم
  // Local settings are ungated in the registry and stay ungated here — one card for everyone.
  HomeShortcut(
    id: 'settings.section',
    title: 'الإعدادات',
    icon: Icons.settings_outlined,
    sectionId: 'settings',
    target: SectionTarget('settings'),
    defaultOn: true,
  ),
  HomeShortcut(
    id: 'settings.api',
    title: 'إعدادات الاتصال',
    icon: Icons.dns_outlined,
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
    icon: Icons.palette_outlined,
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
    icon: Icons.dashboard_customize_outlined,
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
