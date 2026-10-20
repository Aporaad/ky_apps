import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/core/utils/permission_check.dart';
import 'package:ky_apps/features/admin/data/models/app_permission_model.dart';
import 'package:ky_apps/features/admin/data/models/app_user_model.dart';
import 'package:ky_apps/features/admin/presentation/providers/admin_permissions_catalog_provider.dart';
import 'package:ky_apps/features/admin/presentation/widgets/permissions_picker_widget.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_sections.dart';

/// كتالوج صغير ثابت — نسخة حرفية من شكل استجابة `/permissions`
/// A small fixed catalog — the exact shape of the `/permissions` response.
///
/// القسم واحد لأن أزرار الدفعات («تحديد كل القسم») تتكرر في كل مجموعة، فمجموعة واحدة تزيل لبس
/// العثور على الزر.
/// One module, because the batch buttons repeat in every group — a single group removes any doubt
/// about which button a finder resolves to.
final List<AppPermissionModule> _catalog = [
  const AppPermissionModule(
    moduleCode: 'customers',
    nameAr: 'العملاء',
    permissions: [
      AppPermissionModel(
        permissionId: 1,
        permissionCode: 'customers.*',
        actionCode: '*',
        nameAr: 'كل صلاحيات العملاء',
      ),
      AppPermissionModel(
        permissionId: 2,
        permissionCode: 'customers.view',
        actionCode: 'view',
        nameAr: 'عرض العملاء',
        isCore: true,
      ),
      AppPermissionModel(
        permissionId: 3,
        permissionCode: 'customers.create',
        actionCode: 'create',
        nameAr: 'إضافة عميل',
        isCore: true,
      ),
      AppPermissionModel(
        permissionId: 4,
        permissionCode: 'customers.statement',
        actionCode: 'statement',
        nameAr: 'كشف حساب العميل',
      ),
    ],
  ),
];

/// بناء حالة الملقّات مع مراقبة نقرات الدفعات
/// Builds the picker while recording the batch callbacks.
Widget _picker({
  required Set<String> selected,
  required void Function(List<String> codes, bool select) onSetMany,
  void Function(String code)? onToggle,
  Set<String> grantor = const {},
  bool grantorIsAdmin = false,
  bool disabled = false,
}) {
  return ProviderScope(
    overrides: [
      permissionsCatalogProvider.overrideWith((ref) => Future.value(_catalog)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PermissionsPickerWidget(
            selected: selected,
            onToggle: onToggle ?? (_) {},
            onSetMany: onSetMany,
            grantorPermissions: grantor,
            grantorIsAdmin: grantorIsAdmin,
            disabled: disabled,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('IBAC decision rules (mirror of PermissionResolver::can)', () {
    test('a system admin holds everything outside the grant table', () {
      // قرار D1: التجاوز خارج جدول المنح، فصفحة صلاحيات فارغة لا تسلب المدير شيئاً
      // Decision D1: the bypass lives outside the grant table, so an empty grant row changes nothing.
      expect(
        canCode(granted: {}, isAdmin: true, code: Perm.settingsSecurityManage),
        isTrue,
      );
    });

    test('system.* grants every code', () {
      expect(
        canCode(
          granted: {Perm.systemWildcard},
          isAdmin: false,
          code: Perm.usersDelete,
        ),
        isTrue,
      );
    });

    test('an exact code grants only itself', () {
      final granted = {Perm.customersView};
      expect(canCode(granted: granted, isAdmin: false, code: Perm.customersView), isTrue);
      expect(
        canCode(granted: granted, isAdmin: false, code: Perm.customersDelete),
        isFalse,
      );
    });

    test('a module wildcard covers its actions and nothing else', () {
      final granted = {Perm.customersWildcard};
      expect(
        canCode(granted: granted, isAdmin: false, code: Perm.customersStatement),
        isTrue,
      );
      expect(canCode(granted: granted, isAdmin: false, code: Perm.accountsView), isFalse);
    });

    test('no grant means no access — deny is the final answer', () {
      expect(canCode(granted: {}, isAdmin: false, code: Perm.dashboardView), isFalse);
      expect(canCode(granted: {}, isAdmin: false, code: ''), isFalse);
    });

    test('compound actions resolve through the module prefix', () {
      final granted = {Perm.currenciesPricesView};
      expect(
        canCode(granted: granted, isAdmin: false, code: Perm.currenciesPricesView),
        isTrue,
      );
      expect(
        canCode(granted: granted, isAdmin: false, code: Perm.currenciesPricesManage),
        isFalse,
      );
    });

    test('canAnyCode and canAllCode keep the deny-by-default asymmetry', () {
      // قائمة فارغة في `any` تعني رفضاً (لا شيء يُرضيها)، وفي `all` تعني قبولاً (لا شيء مطلوب)
      // An empty list denies for `any` (nothing satisfies it) and accepts for `all` (nothing asks).
      expect(canAnyCode(granted: {}, isAdmin: false, codes: const []), isFalse);
      expect(canAllCode(granted: {}, isAdmin: false, codes: const []), isTrue);
      expect(
        canAnyCode(
          granted: {Perm.customersView},
          isAdmin: false,
          codes: const [Perm.customersDelete, Perm.customersView],
        ),
        isTrue,
      );
      expect(
        canAllCode(
          granted: {Perm.customersView},
          isAdmin: false,
          codes: const [Perm.customersView, Perm.customersDelete],
        ),
        isFalse,
      );
    });
  });

  group('The client code mirror is internally consistent', () {
    test('codes are unique and every module in the order has a wildcard and a label', () {
      // هذه الاختبارات تمسك ما لا يمسكه مترجم: كود مكتوب مرتين أو قسم نُسيت تسميته
      // These catch what no compiler can: a code listed twice, or a module with no label.
      expect(allPermissionCodes.toSet().length, allPermissionCodes.length);

      for (final module in permModuleOrder) {
        expect(
          allPermissionCodes,
          contains(permWildcardOf(module)),
          reason: 'القسم $module بلا كود شامل في المرآة',
        );
        expect(permModuleLabels[module], isNotNull, reason: 'القسم $module بلا تسمية');
      }

      expect(permModuleOrder.toSet().length, permModuleLabels.length);
    });

    test('every literal action belongs to a declared module', () {
      for (final code in allPermissionCodes) {
        expect(
          permModuleOrder,
          contains(permModuleOf(code)),
          reason: 'الكود $code في قسم غير معلن',
        );
        expect(permActionOf(code), isNotEmpty);
      }
    });

    test('module and action helpers split compound actions correctly', () {
      expect(permModuleOf('users.permissions_manage'), 'users');
      expect(permActionOf('users.permissions_manage'), 'permissions_manage');
      expect(permModuleTitle('sessions.view'), 'الجلسات النشطة');
      expect(permModuleTitle('unknown_module.view'), 'unknown_module');
    });
  });

  group('AppUserModel parses what Oracle actually sends', () {
    test('UPPER keys, numbers as text, and CP1256 Arabic all survive', () {
      // 'ÎÇáÏ' هي بايتات «خالد» CP1256 كما تصل من ORCL بترميز WE8MSWIN1252 — هذا هو الخطأ رقم 1
      // في المشروع، وإن سقطت طبقة الإصلاح ظهرت الأسماء هكذا في الشاشة.
      // 'ÎÇáÏ' is «خالد» as CP1256 bytes; the #1 recurring bug in this project.
      final user = AppUserModel.fromJson({
        'USER_ID': '7',
        'USER_NAME_AR': 'ÎÇáÏ',
        'USER_NAME_EN': 'Khaled',
        'USER_TYPE': '2',
        'IS_ACTIVATED': '0',
        'IS_ADMIN': 1,
        'BRANCH_NO': '1',
        'GRANTS_COUNT': '3',
        'ALLOW_BANK_ACC': 0,
        'BIOMETRIC_ENABLED': 1,
      });

      expect(user.userId, 7);
      expect(user.displayName, 'خالد');
      expect(user.isCustomer, isTrue);
      expect(user.isEmployee, isFalse);
      expect(user.isActivated, isFalse);
      expect(user.isAdmin, isTrue);
      expect(user.branchNo, 1);
      expect(user.branchLabel, 'فرع 1');
      expect(user.grantsCount, 3);
      expect(user.allowBankAcc, isFalse);
      expect(user.biometricEnabled, isTrue);
    });

    test('snake_case detail rows carry their grants', () {
      final user = AppUserModel.fromJson({
        'user_id': 12,
        'user_name_en': 'Noor',
        'user_type': 1,
        'is_activated': 1,
        'granted_codes': ['users.view', 'users.toggle'],
        'granted_ids': [81, 85],
      });

      expect(user.displayName, 'Noor');
      expect(user.hasGrantDetail, isTrue);
      expect(user.grantedCodes, ['users.view', 'users.toggle']);
      expect(user.grantedIds, [81, 85]);
    });

    test('a list row has no grants, and an unnamed user still has a label', () {
      // الفرق بين «لا منح» و«لم نحمّل المنح» هو ما يمنع «صلاحيات: 0» على بطاقة القائمة
      // The gap between "no grants" and "grants not loaded" is what stops a false «صلاحيات: 0».
      final row = AppUserModel.fromJson(const {'USER_ID': '4'});
      expect(row.hasGrantDetail, isFalse);
      expect(row.grantsCount, 0);
      expect(row.displayName, 'مستخدم 4');
      expect(row.isEmployee, isTrue, reason: 'النوع الافتراضي موظف (قرار D5)');
    });
  });

  group('The portal registry only references real codes', () {
    test('ids and titles are unique, and the bottom bar stays inside five', () {
      expect(portalSections.map((section) => section.id).toSet().length,
          portalSections.length);
      expect(portalSections.map((section) => section.title).toSet().length,
          portalSections.length);

      // الشريط السفلي يستوعب خمس وجهات؛ سادسة كانت ستكسر `NavigationBar`
      // The bar holds five destinations; a sixth would have broken `NavigationBar`.
      expect(
        portalSections.where((section) => section.showInBottomBar).length,
        lessThanOrEqualTo(5),
      );
    });

    test('every visibility rule is a code the catalog can actually grant', () {
      // كود مكتوب بخطأ إملائي في `viewCodes` يعني قسماً لا يظهر لأحد مهما مُنح — صمتاً
      // A typo in viewCodes means a section no grant can ever reveal — silently.
      for (final section in portalSections) {
        for (final code in section.viewCodes) {
          expect(
            allPermissionCodes,
            contains(code),
            reason: 'قسم ${section.id} يشترط كوداً غير موجود: $code',
          );
        }
      }
    });
  });

  group('PermissionsPickerWidget batch actions', () {
    testWidgets('selecting a whole section sends literal actions, never the wildcard', (
      tester,
    ) async {
      // السبب أمني: `customers.*` أوسع من مجموع أفعالها لأنها تغطي كل فعل يُضاف لاحقاً،
      // والخادم يرفضها على غير المدير — فالزر يجب أن يمنح ما يراه المستخدم فقط.
      // A wildcard is broader than the sum of its actions and a non-admin cannot send it anyway.
      final calls = <List<Object>>[];
      await tester.pumpWidget(
        _picker(
          selected: {},
          onSetMany: (codes, select) => calls.add([codes, select]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('تحديد كل القسم'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      final sent = (calls.single.first as List<String>).toSet();
      expect(sent, {
        Perm.customersView,
        Perm.customersCreate,
        Perm.customersStatement,
      });
      expect(sent.contains(Perm.customersWildcard), isFalse);
      expect(calls.single.last, isTrue);
    });

    testWidgets('the basics shortcut sends only core actions', (tester) async {
      final calls = <List<Object>>[];
      await tester.pumpWidget(
        _picker(
          selected: {},
          onSetMany: (codes, select) => calls.add([codes, select]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('الأساسيات'));
      await tester.pumpAndSettle();

      expect((calls.single.first as List<String>).toSet(), {
        Perm.customersView,
        Perm.customersCreate,
      });
    });

    testWidgets('batch buttons vanish while searching', (tester) async {
      // نتائج أوسع مما يراه المستخدم = قرار بمنح لم يره أحد؛ فالزر يُخفى لا يُعطَّل
      // Batch effects would be wider than the filtered view, so the buttons hide.
      await tester.pumpWidget(_picker(selected: {}, onSetMany: (_, __) {}));
      await tester.pumpAndSettle();
      expect(find.text('تحديد كل القسم'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'customers.statement');
      await tester.pumpAndSettle();

      expect(find.text('تحديد كل القسم'), findsNothing);
      expect(find.text('الأساسيات'), findsNothing);
    });

    testWidgets('a permission the grantor does not hold stays ungrantable', (
      tester,
    ) async {
      // منع التصعيد في الواجهة قبل الإرسال: الخادم يرفض بـ not_held، والشاشة تُظلل السطر
      // Anti-escalation shown before sending; the server would refuse it as not_held.
      final toggled = <String>[];
      await tester.pumpWidget(
        _picker(
          selected: {},
          onSetMany: (_, __) {},
          onToggle: toggled.add,
          grantor: const {Perm.customersView},
        ),
      );
      await tester.pumpAndSettle();

      // الشريحة تعرض الاسم العربي والتلميح يحمل الكود، فالعثور يكون على الاسم
      // The chip shows the Arabic label and the tooltip carries the code, so search by the label.
      final chip = find.ancestor(
        of: find.text('إضافة عميل'),
        matching: find.byType(InkWell),
      );
      await tester.tap(chip, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(toggled, isEmpty);
      expect(
        canGrant(
          const AppPermissionModel(
            permissionId: 3,
            permissionCode: 'customers.create',
            actionCode: 'create',
            nameAr: 'إضافة عميل',
          ),
          granted: const {Perm.customersView},
          isAdmin: false,
        ),
        isFalse,
      );
      expect(
        canGrant(
          const AppPermissionModel(
            permissionId: 3,
            permissionCode: 'customers.create',
            actionCode: 'create',
            nameAr: 'إضافة عميل',
          ),
          granted: const {Perm.customersWildcard},
          isAdmin: false,
        ),
        isTrue,
      );
    });

    testWidgets('a system-admin target renders the picker locked', (tester) async {
      // مدير النظام يتجاوز جدول المنح (D1)، فتحديد صلاحيات له يعني قائمة لا يقرؤها أحد
      // Editing grants for an admin would build a list nothing reads.
      await tester.pumpWidget(
        _picker(selected: {}, onSetMany: (_, __) {}, disabled: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('مدير النظام'), findsOneWidget);
      expect(find.text('تحديد كل القسم'), findsNothing);
    });
  });
}
