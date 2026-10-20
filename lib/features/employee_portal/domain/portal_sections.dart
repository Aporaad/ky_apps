import 'package:flutter/material.dart';

import '../../../core/constants/permission_codes.dart';
import '../../../core/utils/permission_check.dart';
import '../presentation/screens/sections/accounts_section.dart';
import '../presentation/screens/sections/customers_section.dart';
import '../presentation/screens/sections/home_dashboard_section.dart';
import '../presentation/screens/sections/management_section.dart';
import '../presentation/screens/sections/sales_section.dart';
import '../presentation/screens/sections/settings_section.dart';
import '../presentation/screens/sections/stores_section.dart';
import '../presentation/screens/sections/tailoring_section.dart';
import '../presentation/screens/sections/workers_section.dart';

/// قسم واحد في بوابة الموظف: هويّة ثابتة + عنوان + أيقونة + شرط ظهور + شاشة
/// One employee-portal section: stable id, title, icon, visibility rule, and its screen.
///
/// لماذا السجل مركزي؟ كان نفس القائمة مرسوماً مرتين: تسعة عناصر في القائمة الجانبية وخمسة في
/// شريط الجوال السفلي، وكلاهما يستخدم المؤشر نفسه داخل `IndexedStack` المكوّن من تسعة. اختيار
/// «الحسابات» من الشريط كان يعرض «جاري العاملين». سجل واحد بمعرّفات ثابتة يجعل الموضع اشتقاقاً
/// لا تخزيناً، ويمنح كل قسم شرط ظهور واحد يقرأه الشريطان معاً.
/// The registry exists because the same menu was declared twice — nine entries in the side drawer,
/// five in the mobile bottom bar, both indexing into a nine-child `IndexedStack`. Picking
/// «الحسابات» in the bar therefore showed «جاري العاملين». One registry with stable ids makes the
/// position derived instead of stored, and gives every section a single visibility rule.
///
/// القسم لا يُعرض ولا يُبنى قبل التحقق من شرطه: `IndexedStack` يبني أبناءه جميعاً، فإدراج قسم
/// محجوب يعني تشغيل شبكة قسمٍ لا يراه المستخدم أصلاً.
/// A denied section is excluded from the list, not merely hidden: `IndexedStack` builds every
/// child, so including a hidden one would fire the network calls of a section the user can't reach.
class PortalSection {
  const PortalSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.selectedIcon,
    this.viewCodes = const [],
    this.showInBottomBar = false,
  });

  /// المعرّف الثابت — يُستخدم للعودة إلى نفس القسم بعد تحديث المنح، فلا يُخزَّن موضعٌ يتغيّر
  /// Stable id, used to land on the same section after grants refresh. Position is never stored.
  final String id;
  final String title;
  final IconData icon;

  /// أيقونة الحالة المختارة في شريط الجوال (نسخة `_rounded`)؛ وإن غابت استُخدمت `icon`
  /// Selected-state icon for the mobile bar (the `_rounded` variant); falls back to [icon].
  final IconData? selectedIcon;

  /// أكواد الظهور: يكفي واحد منها؛ والقائمة الفارغة تعني بلا شرط (كالإعدادات المحلية)
  /// Visibility codes: any one is enough. An empty list means ungated (local settings does).
  final List<String> viewCodes;

  /// هل يظهر في شريط الجوال السفلي؟ الشريط يتسع خمسة فقط، والقرار بقائه للمصمم لا للقاعدة
  /// Whether this section belongs in the mobile bottom bar — it holds five, so membership is a
  /// deliberate choice, not a consequence of the registry's order.
  final bool showInBottomBar;

  final WidgetBuilder builder;
}

/// أقسام بوابة الموظف بترتيب العرض — المصدر الوحيد للقائمين والشاشات معاً
/// The portal sections in display order — the only source for both menus and for the screens.
const List<PortalSection> portalSections = [
  PortalSection(
    id: 'home',
    title: 'الرئيسية',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    builder: _buildHome,
    viewCodes: [Perm.dashboardView],
    showInBottomBar: true,
  ),
  PortalSection(
    id: 'sales',
    title: 'المبيعات',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
    builder: _buildSales,
    viewCodes: [Perm.salesView],
    showInBottomBar: true,
  ),
  PortalSection(
    id: 'tailoring',
    title: 'التفصيل',
    icon: Icons.content_cut_outlined,
    selectedIcon: Icons.content_cut_rounded,
    builder: _buildTailoring,
    viewCodes: [Perm.tailoringView],
    showInBottomBar: true,
  ),
  PortalSection(
    id: 'customers',
    title: 'العملاء',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.person_rounded,
    builder: _buildCustomers,
    viewCodes: [Perm.customersView],
    showInBottomBar: true,
  ),
  // «جاري العاملين» يغطي ثلاث سجلات (موظفون/قصاصون/خياطون)، فظهوره يكفي فيه أي واحد ممنوح
  // «جاري العاملين» spans three registries, so any one of their view codes is enough to show it.
  PortalSection(
    id: 'workers',
    title: 'جاري العاملين',
    icon: Icons.groups_2_rounded,
    builder: _buildWorkers,
    viewCodes: [
      Perm.employeesView,
      Perm.cuttersView,
      Perm.tailorsView,
    ],
  ),
  PortalSection(
    id: 'accounts',
    title: 'الحسابات',
    icon: Icons.account_balance_outlined,
    selectedIcon: Icons.account_balance_rounded,
    builder: _buildAccounts,
    viewCodes: [Perm.accountsView],
    showInBottomBar: true,
  ),
  PortalSection(
    id: 'stores',
    title: 'المخازن',
    icon: Icons.inventory_2_outlined,
    builder: _buildStores,
    viewCodes: [Perm.storesView],
  ),
  PortalSection(
    id: 'management',
    title: 'الإدارة',
    icon: Icons.admin_panel_settings_outlined,
    builder: _buildManagement,
    viewCodes: [Perm.managementView],
  ),
  PortalSection(
    id: 'settings',
    title: 'الإعدادات',
    icon: Icons.settings_outlined,
    builder: _buildSettings,
  ),
];

/// بحث قسم بمعرّفه في السجل الكامل — لتحويل معرّف الشريط السفلي إلى موضع في القائمة المرئية
/// Look up a section by id across the whole registry, to map a bottom-bar id to a visible index.
PortalSection? portalSectionById(String id) {
  for (final section in portalSections) {
    if (section.id == id) return section;
  }

  return null;
}

/// الأقسام التي يراها مستخدمٌ بمنح معيّنة، بترتيب السجل
/// The sections a user holding these grants can see, in registry order.
///
/// الشريطان يبنيان قائمتهما من هذه الدالة وحدها، بالمنطق الذي يطبّقه الخادم نفسه، فلا يختلف
/// الجانبي والسفلي على ما هو ظاهر.
/// Both bars build their list here and nowhere else, using the server's own rule, so the drawer
/// and the bottom bar can never disagree about what is visible.
List<PortalSection> visiblePortalSections({
  required Set<String> granted,
  required bool isAdmin,
}) {
  return portalSections
      .where(
        (section) =>
            section.viewCodes.isEmpty ||
            canAnyCode(
              granted: granted,
              isAdmin: isAdmin,
              codes: section.viewCodes,
            ),
      )
      .toList(growable: false);
}

// البناؤات دوال عليا لا كلاشرات: القائمة `const`، والدالة المرجعية وحدها تصلح داخل ثابت
// Top-level functions instead of closures: the registry is `const`, and only a function reference
// can be a constant expression. Each screen has a const constructor, so nothing rebuilds per frame.
Widget _buildHome(BuildContext _) => const HomeDashboardSection();
Widget _buildSales(BuildContext _) => const SalesSection();
Widget _buildTailoring(BuildContext _) => const TailoringSection();
Widget _buildCustomers(BuildContext _) => const CustomersSection();
Widget _buildWorkers(BuildContext _) => const WorkersSection();
Widget _buildAccounts(BuildContext _) => const AccountsSection();
Widget _buildStores(BuildContext _) => const StoresSection();
Widget _buildManagement(BuildContext _) => const ManagementSection();
Widget _buildSettings(BuildContext _) => const SettingsSection();
