import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/core/utils/responsive.dart';
import 'package:ky_apps/features/admin/data/models/admin_result.dart';
import 'package:ky_apps/features/admin/data/models/app_permission_model.dart';
import 'package:ky_apps/features/admin/data/models/app_security_setting_model.dart';
import 'package:ky_apps/features/admin/data/models/app_session_model.dart';
import 'package:ky_apps/features/admin/data/models/app_user_model.dart';
import 'package:ky_apps/features/admin/data/models/paged_result.dart';
import 'package:ky_apps/features/admin/data/models/user_activity_model.dart';
import 'package:ky_apps/features/admin/data/repositories/admin_user_repository.dart';
import 'package:ky_apps/features/admin/data/repositories/permission_repository.dart';
import 'package:ky_apps/features/admin/data/repositories/security_setting_repository.dart';
import 'package:ky_apps/features/admin/data/repositories/session_repository.dart';
import 'package:ky_apps/features/admin/presentation/providers/active_sessions_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/admin_permissions_catalog_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/security_settings_provider.dart';
import 'package:ky_apps/features/admin/presentation/screens/active_sessions_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/assign_permissions_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/management_dashboard_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/permissions_catalog_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/security_settings_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/user_activity_screen.dart';
import 'package:ky_apps/features/admin/presentation/screens/user_form_screen.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_sections.dart';
import 'package:ky_apps/features/employee_portal/presentation/screens/employee_main_layout.dart';
import 'package:ky_apps/features/employee_portal/presentation/widgets/portal_section_scope.dart';
import 'package:ky_apps/features/home/data/models/home_layout.dart';
import 'package:ky_apps/features/home/domain/home_card_size.dart';
import 'package:ky_apps/features/home/domain/home_shortcut_catalog.dart';
import 'package:ky_apps/features/home/presentation/providers/home_layout_notifier.dart';
import 'package:ky_apps/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:ky_apps/features/home/presentation/screens/home_customize_screen.dart';
import 'package:ky_apps/features/home/presentation/widgets/home_shortcut_card.dart';

/// مزود مصادقة وهمي للحالات الثابتة — بلا فحص حالة وبلا شبكة
/// Stub auth notifier with a fixed state: no status check, no network.
///
/// يبني الحالة مباشرة بدل `checkAuthStatus()` التي تلمس التخزين الآمن وDio؛ فالاختبار هنا
/// رسمُ الأقسام المسموح بها لا المصادقة.
/// `build()` returns the state directly instead of running `checkAuthStatus()`, which would reach
/// secure storage and Dio. These tests are about which sections get drawn, not about signing in.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

/// حالة مصادقة بمنح معيّنة، بنفس الطريق الذي تسلكه الاستعادة من الخادم
/// An authenticated state carrying given grants, built the same way the real restore path builds it.
AuthState _stateWith({required List<String> codes, bool isAdmin = false}) {
  return const AuthState(isAuthenticated: true).withPermissions(
    PermissionSnapshot(userId: 1, isAdmin: isAdmin, permissions: codes),
  );
}

// ── مرحلة 8: بيانات ثابتة بدل شبكة ──
// Phase 8: fixed data instead of a network.

/// عميل لا يُلمس: كل قراءة في الشاشات تمر عبر المستودعات المزوّفة أدناه
/// A client that is never touched: every read the screens make goes through the fakes below.
final _deadClient = DioClient(
  storage: SecureStorageService(),
  baseUrl: 'http://127.0.0.1',
);

final _adminUser = AppUserModel(
  userId: 1,
  userNameEn: 'arslan',
  userNameAr: 'مدير النظام',
  isAdmin: true,
  branchNo: 1,
);

final _staffUser = AppUserModel(
  userId: 7,
  userNameEn: 'Khaled',
  userNameAr: 'خالد',
  branchNo: 2,
  grantsCount: 3,
  grantedCodes: const [Perm.usersView, Perm.usersToggle, Perm.sessionsView],
  grantedIds: const [81, 85, 90],
);

/// كتالوج صغير بقسمين: يكفي أن يكون شكل الاستجابة حرفياً لأن الشاشة تعرض الترتيب لا العدد
/// A two-module catalog: only the response shape needs to be literal, screens show order not size.
final _catalog = [
  const AppPermissionModule(
    moduleCode: 'users',
    nameAr: 'إدارة المستخدمين',
    permissions: [
      AppPermissionModel(
        permissionId: 80,
        permissionCode: 'users.*',
        actionCode: '*',
        nameAr: 'كل صلاحيات المستخدمين',
      ),
      AppPermissionModel(
        permissionId: 81,
        permissionCode: 'users.view',
        actionCode: 'view',
        nameAr: 'عرض المستخدمين',
        isCore: true,
      ),
      AppPermissionModel(
        permissionId: 85,
        permissionCode: 'users.toggle',
        actionCode: 'toggle',
        nameAr: 'تفعيل وتعطيل',
        isCore: true,
      ),
      AppPermissionModel(
        permissionId: 87,
        permissionCode: 'users.activity_view',
        actionCode: 'activity_view',
        nameAr: 'سجل النشاط',
      ),
    ],
  ),
  const AppPermissionModule(
    moduleCode: 'sessions',
    nameAr: 'الجلسات النشطة',
    permissions: [
      AppPermissionModel(
        permissionId: 90,
        permissionCode: 'sessions.view',
        actionCode: 'view',
        nameAr: 'عرض الجلسات',
        isCore: true,
      ),
    ],
  ),
];

/// جلسات حول لحظة الاختبار: المنتهية تبقى مرئية بحالتها، والدقيقة تُحسب من `expires_at`
/// Sessions around the test instant: an expired row stays visible, and the countdown reads expires_at.
List<AppSessionModel> _sessionsAt(DateTime now) => [
  AppSessionModel(
    tokenId: 501,
    userId: 1,
    userNameEn: 'arslan',
    userNameAr: 'مدير النظام',
    deviceName: 'Pixel 7',
    platform: 'android',
    createdAt: now.subtract(const Duration(hours: 2)),
    lastActivityAt: now,
    expiresAt: now.add(const Duration(hours: 3, minutes: 20)),
    isCurrent: true,
  ),
  AppSessionModel(
    tokenId: 502,
    userId: 7,
    userNameEn: 'Khaled',
    userNameAr: 'خالد',
    platform: 'windows',
    createdAt: now.subtract(const Duration(days: 1)),
    expiresAt: now.subtract(const Duration(hours: 4)),
    status: 'expired',
    statusLabel: 'منتهية',
  ),
];

/// مفاتيح تغطي المجموعات الأربع في شاشة الأمان
/// Keys that cover all four groups in the security screen.
const _settings = [
  AppSecuritySettingModel(
    settingId: 1,
    key: 'session_idle_minutes',
    nameAr: 'مدة خمول الجلسة',
    valueType: 'int',
    value: 240,
    minValue: 5,
    maxValue: 10080,
    sortOrder: 1,
  ),
  AppSecuritySettingModel(
    settingId: 2,
    key: 'password_min_length',
    nameAr: 'أقل طول لكلمة المرور',
    valueType: 'int',
    value: 8,
    minValue: 6,
    maxValue: 32,
    sortOrder: 2,
  ),
  AppSecuritySettingModel(
    settingId: 3,
    key: 'biometric_login_enabled',
    nameAr: 'الدخول بالبصمة',
    valueType: 'bool',
    value: true,
    isLockable: true,
    sortOrder: 3,
  ),
  AppSecuritySettingModel(
    settingId: 4,
    key: 'activity_retention_days',
    nameAr: 'مدة الاحتفاظ بالسجل',
    valueType: 'int',
    value: 90,
    minValue: 7,
    maxValue: 3650,
    sortOrder: 4,
  ),
];

class _FakeUserRepo extends AdminUserRepository {
  _FakeUserRepo() : super(client: _deadClient);

  @override
  Future<PagedResult<AppUserModel>> fetchUsers({
    String search = '',
    String status = 'all',
    String userType = 'all',
    bool adminOnly = false,
    String sort = 'user_id',
    String direction = 'asc',
    int page = 1,
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    return PagedResult(
      items: [_adminUser, _staffUser],
      total: 2,
      page: 1,
      limit: limit,
      pages: 1,
    );
  }

  @override
  Future<AppUserModel?> fetchUser(
    int userId, {
    CancelToken? cancelToken,
  }) async {
    return userId == _staffUser.userId ? _staffUser : _adminUser;
  }

  @override
  Future<AdminResult<AppUserModel>> createUser(
    Map<String, dynamic> payload,
  ) async {
    return const AdminResult<AppUserModel>(
      success: true,
      message: 'تم إنشاء المستخدم / User created',
    );
  }

  @override
  Future<AdminResult<AppUserModel>> updateUser(
    int userId,
    Map<String, dynamic> payload,
  ) async {
    return const AdminResult<AppUserModel>(
      success: true,
      message: 'تم الحفظ / Saved',
    );
  }

  @override
  Future<AdminResult<Map<String, dynamic>>> toggleUser(int userId) async {
    return const AdminResult<Map<String, dynamic>>(
      success: true,
      message: 'تم تغيير الحالة / State changed',
      data: <String, dynamic>{},
    );
  }

  @override
  Future<AdminResult<Map<String, dynamic>>> deleteUser(int userId) async {
    return const AdminResult<Map<String, dynamic>>(
      success: true,
      message: 'تم الحذف / Deleted',
      data: <String, dynamic>{},
    );
  }

  @override
  Future<PagedResult<UserActivityModel>> fetchActivity(
    int userId, {
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    final now = DateTime.now();

    return PagedResult(
      items: [
        UserActivityModel(
          activityId: 1,
          userId: userId,
          actionCode: 'users.update',
          moduleCode: 'users',
          descriptionAr: 'تعديل بيانات مستخدم',
          createdOn: now,
        ),
        UserActivityModel(
          activityId: 2,
          userId: userId,
          actionCode: 'auth.login_failed',
          moduleCode: 'auth',
          descriptionAr: 'محاولة دخول بكلمة مرور خاطئة',
          status: 'failed',
          createdOn: now.subtract(const Duration(days: 3)),
        ),
      ],
      total: 2,
      page: 1,
      limit: limit,
      pages: 1,
    );
  }
}

class _FakePermissionRepo extends PermissionRepository {
  _FakePermissionRepo() : super(client: _deadClient);

  @override
  Future<List<AppPermissionModule>> fetchCatalog({
    CancelToken? cancelToken,
  }) async {
    return _catalog;
  }

  @override
  Future<UserGrants?> fetchUserGrants(
    int userId, {
    CancelToken? cancelToken,
  }) async {
    return UserGrants(
      userId: userId,
      userNameEn: _staffUser.userNameEn,
      userNameAr: _staffUser.userNameAr,
      grantedCodes: _staffUser.grantedCodes,
      grantedIds: _staffUser.grantedIds,
      effectiveCodes: _staffUser.grantedCodes,
    );
  }

  @override
  Future<AdminResult<UserGrants>> syncUserPermissions(
    int userId,
    List<String> codes, {
    bool logoutOthers = true,
  }) async {
    return const AdminResult<UserGrants>(
      success: true,
      message: 'تم حفظ الصلاحيات / Permissions saved',
    );
  }
}

class _FakeSessionRepo extends SessionRepository {
  _FakeSessionRepo() : super(client: _deadClient);

  @override
  Future<PagedResult<AppSessionModel>> fetchSessions({
    int? userId,
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    return PagedResult(
      items: _sessionsAt(DateTime.now()),
      total: 2,
      page: 1,
      limit: limit,
      pages: 1,
    );
  }

  @override
  Future<AdminResult<Map<String, dynamic>>> terminateSession(
    int tokenId,
  ) async {
    return const AdminResult<Map<String, dynamic>>(
      success: true,
      message: 'أُنهيت الجلسة / Session terminated',
      data: <String, dynamic>{},
    );
  }

  @override
  Future<AdminResult<Map<String, dynamic>>> terminateUserSessions(
    int userId,
  ) async {
    return const AdminResult<Map<String, dynamic>>(
      success: true,
      message: 'أُنهيت كل الجلسات / All sessions terminated',
      data: <String, dynamic>{},
    );
  }
}

class _FakeSettingRepo extends SecuritySettingRepository {
  _FakeSettingRepo() : super(client: _deadClient);

  @override
  Future<List<AppSecuritySettingModel>> fetchSettings({
    CancelToken? cancelToken,
  }) async {
    return _settings;
  }

  @override
  Future<AdminResult<int>> saveSettings(
    Map<String, dynamic> valuesByKey,
  ) async {
    return AdminResult<int>(
      success: true,
      message: 'حُفظت الإعدادات / Settings saved',
      data: valuesByKey.length,
    );
  }
}

/// كل شاشات الإدارة تُحمَّل من الخادم: المزوّفات تُلغي الشبكة، والمزوّد المزيف يفتح كل البوابات
/// Every admin screen loads from the server: the fakes cancel the network, and the stub auth opens
/// all the gates.
Future<void> _pumpAdmin(
  WidgetTester tester,
  Widget screen, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // مدير نظام: البوابات كلها مفتوحة، فتُرسَم أزرار الكتابة والحذف ولا يُختبر فرع الرفض وحده
        // A system admin opens every gate, so the write buttons render too, not just the denial path.
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(_stateWith(codes: const [], isAdmin: true)),
        ),
        adminUserRepositoryProvider.overrideWith((ref) => _FakeUserRepo()),
        permissionRepositoryProvider.overrideWith(
          (ref) => _FakePermissionRepo(),
        ),
        sessionRepositoryProvider.overrideWith((ref) => _FakeSessionRepo()),
        securitySettingRepositoryProvider.overrideWith(
          (ref) => _FakeSettingRepo(),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Responsive Breakpoints Tests', () {
    testWidgets('Responsive correctly identifies mobile breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isTrue);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('Responsive correctly identifies desktop breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets(
      'EmployeeMainLayout renders without overflow on mobile screen (360x640)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: EmployeeMainLayout())),
        );

        await tester.pumpAndSettle();

        // لا يوجد أي استثناء في الـ layout أو RenderFlex overflow
        expect(tester.takeException(), isNull);
        expect(find.text('بوابة الموظف'), findsOneWidget);
      },
    );

    testWidgets(
      'EmployeeMainLayout renders without overflow on desktop screen (1280x800)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: EmployeeMainLayout())),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('بوابة الموظف'), findsOneWidget);
      },
    );
  });

  group('Portal sections follow the grants', () {
    Future<void> pumpLayout(
      WidgetTester tester, {
      required Size size,
      required AuthState state,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(() => _StubAuthNotifier(state)),
          ],
          child: const MaterialApp(home: EmployeeMainLayout()),
        ),
      );

      await tester.pumpAndSettle();
    }

    testWidgets('a system admin sees all nine sections on desktop', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        size: const Size(1280, 800),
        state: _stateWith(codes: const [], isAdmin: true),
      );

      expect(tester.takeException(), isNull);

      // على المكتب لا شريط سفلي أصلاً: القائمة الجانبية وحدها ترى السجل كاملاً
      // Desktop has no bottom bar at all; only the side drawer renders the whole registry.
      // `findsWidgets` لا `One`: القسم المبنى داخل `IndexedStack` يعيد كتابة عنوانه في رأسه
      // Widgets rather than one: each built section repeats its own title in its header.
      for (final section in portalSections) {
        expect(find.text(section.title), findsWidgets, reason: section.id);
      }

      expect(find.byType(NavigationDestination), findsNothing);
    });

    testWidgets('a system admin gets five destinations on mobile', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        size: const Size(360, 640),
        state: _stateWith(codes: const [], isAdmin: true),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      expect(find.text('الحسابات'), findsWidgets);
    });

    testWidgets('restricted grants hide sections from the navigation', (
      tester,
    ) async {
      await pumpLayout(
        tester,
        size: const Size(1280, 800),
        state: _stateWith(
          codes: const [Perm.customersView, Perm.employeesView],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('العملاء'), findsWidgets);
      expect(find.text('جاري العاملين'), findsWidgets);

      // الأقسام غير الممنوحة لا تُرسم ولا تُبنى: إدراجها في `IndexedStack` كان يشغّل شبكتها
      // Denied sections are excluded, not hidden — keeping them in the IndexedStack fired their
      // network calls for a screen the user could never open.
      expect(find.text('المخازن'), findsNothing);
      expect(find.text('المبيعات'), findsNothing);
      expect(find.text('الحسابات'), findsNothing);
    });

    testWidgets('one bar section leaves no bar at all', (tester) async {
      // كان هذا شكل الانهيار: واجهة المستخدم بقسمٍ مسموح واحد تبني شريطاً بوجهة واحدة،
      // و`NavigationBar` تصرّخ عند أقل من اثنتين
      // This was the crash shape: a user with one allowed bar section built a one-destination bar,
      // and `NavigationBar` asserts on fewer than two.
      await pumpLayout(
        tester,
        size: const Size(360, 640),
        state: _stateWith(codes: const [Perm.dashboardWildcard]),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('بوابة الموظف'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNothing);
    });

    testWidgets('the guidance screen explains a portal with no sections', (
      tester,
    ) async {
      // هذه الشاشة لا يصلها التصميم عبر البوابة: «الإعدادات» بلا شرط ظهور فيبقى قسم واحد دائماً.
      // تُختبر مباشرة لأنها فرع الدفاع ضد `IndexedStack` فارغ — لا عن حالة واقعية الآن.
      // The layout can't reach this screen today: «الإعدادات» is ungated, so one section always
      // survives. It is a defence against an empty IndexedStack, so it is tested directly.
      await tester.pumpWidget(
        const MaterialApp(home: NoSectionAvailable(onLogout: null)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('لم تُمنح بعد أي صلاحية دخول'), findsOneWidget);
      expect(find.text('تسجيل الخروج'), findsNothing);
    });
  });

  group('Admin screens render at both breakpoints', () {
    // تجاوز RenderFlex هو نمط الفشل المتكرر هنا، فلا دليل على السلامة أقوى من رسم الشاشة عند
    // 360×640 و1280×800 ثم مطالبته بصفر استثناءات.
    // Overflow is this project's recurring failure mode, so no check is stronger than drawing the
    // screen at both sizes and demanding zero exceptions.
    const mobile = Size(360, 640);
    const desktop = Size(1280, 800);

    for (final size in const [mobile, desktop]) {
      final tag = size.width < 700 ? 'mobile' : 'desktop';

      testWidgets('management dashboard — $tag', (tester) async {
        // الشاشة بلا Scaffold: تُرسم داخل قسم البوابة، فـ Scaffold للاختبار لا لها
        // The dashboard has no Scaffold of its own because it renders inside a portal section.
        await _pumpAdmin(
          tester,
          const Scaffold(body: ManagementDashboardScreen()),
          size: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('إدارة المستخدمين'), findsWidgets);
      });

      testWidgets('users list — $tag', (tester) async {
        await _pumpAdmin(tester, const AdminUsersScreen(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('خالد'), findsOneWidget);
      });

      testWidgets('create form — $tag', (tester) async {
        await _pumpAdmin(tester, const UserFormScreen(), size: size);

        expect(tester.takeException(), isNull);
      });

      testWidgets('edit form with its grants loaded — $tag', (tester) async {
        await _pumpAdmin(
          tester,
          UserFormScreen(existing: _staffUser),
          size: size,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('grant screen — $tag', (tester) async {
        await _pumpAdmin(
          tester,
          const AssignPermissionsScreen(userId: 7, userName: 'خالد'),
          size: size,
        );

        expect(tester.takeException(), isNull);
        expect(find.text('إدارة المستخدمين'), findsWidgets);
      });

      testWidgets('activity trail — $tag', (tester) async {
        await _pumpAdmin(
          tester,
          const UserActivityScreen(userId: 7, userName: 'خالد'),
          size: size,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('sessions — $tag', (tester) async {
        await _pumpAdmin(tester, const ActiveSessionsScreen(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('Pixel 7'), findsOneWidget);

        // تفكيك الشاشة عمداً: مؤقّت الدقيقة الذي يُحدّث الوقت المتبقي يبقى معلّقاً وإلا
        // The screen is torn down on purpose: its one-minute ticker would otherwise stay pending.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('security settings — $tag', (tester) async {
        await _pumpAdmin(tester, const SecuritySettingsScreen(), size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('الجلسات'), findsWidgets);
      });

      testWidgets('permissions catalog — $tag', (tester) async {
        await _pumpAdmin(tester, const PermissionsCatalogScreen(), size: size);

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Home dashboard', () {
    const mobile = Size(360, 640);
    const desktop = Size(1280, 800);

    testWidgets('a system admin sees the shortcut grid on mobile', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: mobile,
        auth: _stateWith(codes: const [], isAdmin: true),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShortcutCard), findsAtLeastNWidgets(6));
      expect(find.textContaining('الموظف'), findsWidgets);
    });

    testWidgets('a system admin sees the shortcut grid on desktop', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: desktop,
        auth: _stateWith(codes: const [], isAdmin: true),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShortcutCard), findsAtLeastNWidgets(12));
    });

    testWidgets('a read-only user gets five cards, not thirty', (tester) async {
      // سطح مرتفع عمدًا: الشبكة كسولة داخل `SingleChildScrollView`، فالبطاقة الخامسة تحت
      // الطيّة لا تُبنى — والعدّ على سطح قصير كان سيقيس التمرير لا الصلاحيات.
      // A tall surface on purpose: the grid is lazy inside the scroll view, so the fifth card
      // below the fold is never built — counting on a short surface would measure scrolling.
      await _pumpHome(
        tester,
        size: const Size(360, 1200),
        auth: _stateWith(codes: const [Perm.customersView]),
      );

      expect(tester.takeException(), isNull);
      // أربع لا خمس: «الأمان والبصمة» مسموحة لكنها ليست في التشكيلة الأولى، فهي في «المتاحة»
      // Four, not five: «الأمان والبصمة» is allowed but not a first-run card, so it waits in
      // the "available" tab until the user adds it.
      expect(find.byType(HomeShortcutCard), findsNWidgets(4));
      expect(find.text('إضافة عميل'), findsNothing);
      expect(find.text('كشف حساب عميل'), findsNothing);
    });

    testWidgets('hiding everything keeps the pinned card and explains why', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: mobile,
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: HomeLayout(
          userId: 1,
          hidden: {
            for (final shortcut in homeShortcutCatalog)
              if (!shortcut.pinned) shortcut.id,
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShortcutCard), findsOneWidget);
      expect(
        find.text('أخفيت كل الاختصارات — يمكنك استعادتها الآن.'),
        findsOneWidget,
      );
    });

    testWidgets('survives the maximum allowed text scale on mobile', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: mobile,
        auth: _stateWith(codes: const [], isAdmin: true),
        textScale: 1.25,
      );

      expect(tester.takeException(), isNull);
    });

    for (final entry in {'mobile': mobile, 'desktop': desktop}.entries) {
      testWidgets('the customise screen renders — ${entry.key}', (
        tester,
      ) async {
        await _pumpCustomize(tester, size: entry.value);

        expect(tester.takeException(), isNull);
        expect(find.text('تخصيص الاختصارات'), findsOneWidget);
        expect(find.textContaining('المفعّلة'), findsWidgets);
      });
    }

    testWidgets('pinning four columns actually changes the grid', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(1200, 900),
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: const HomeLayout(userId: 1, columns: 4),
      );

      expect(_gridColumns(tester), 4);
    });

    testWidgets('automatic columns give six at the same width', (tester) async {
      await _pumpHome(
        tester,
        size: const Size(1200, 900),
        auth: _stateWith(codes: const [], isAdmin: true),
      );

      expect(_gridColumns(tester), 6);
    });

    testWidgets('a large size changes the tile ratio, not just the icon', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(1200, 900),
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: const HomeLayout(userId: 1, size: HomeCardSize.large),
      );

      expect(_gridRatio(tester), HomeCardSize.large.ratio);
    });

    testWidgets('a small size changes the tile ratio the other way', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: const Size(1200, 900),
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: const HomeLayout(userId: 1, size: HomeCardSize.small),
      );

      expect(_gridRatio(tester), HomeCardSize.small.ratio);
    });

    testWidgets('card content is vertically centred', (tester) async {
      await _pumpHome(
        tester,
        size: const Size(390, 844),
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: const HomeLayout(userId: 1, columns: 3),
      );

      final card = find.byType(HomeShortcutCard).first;
      final cardRect = tester.getRect(card);
      final iconRect = tester.getRect(
        find.descendant(of: card, matching: find.byType(Icon)).first,
      );
      final textRect = tester.getRect(
        find.descendant(of: card, matching: find.byType(Text)).last,
      );

      // منتصف الكتلة (أعلى الأيقونة إلى أسفل آخر نص) يجب أن يقع قرب منتصف البطاقة
      // The block's midpoint (icon top to last text bottom) must sit near the card's centre.
      final blockCentre = (iconRect.top + textRect.bottom) / 2;
      expect((blockCentre - cardRect.center.dy).abs(), lessThan(6));
    });

    testWidgets('the display tab exposes size and columns', (tester) async {
      await _pumpCustomize(tester, size: mobile);

      await tester.tap(find.text('العرض'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('حجم البطاقة'), findsOneWidget);
      expect(find.text('عدد البطاقات في الصف'), findsOneWidget);
    });

    testWidgets('large cards with four pinned columns render on desktop', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        size: desktop,
        auth: _stateWith(codes: const [], isAdmin: true),
        layout: const HomeLayout(
          userId: 1,
          size: HomeCardSize.large,
          columns: 4,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShortcutCard), findsAtLeastNWidgets(6));
    });

    testWidgets(
      'six pinned columns clamp down on a phone instead of breaking',
      (tester) async {
        await _pumpHome(
          tester,
          size: mobile,
          auth: _stateWith(codes: const [], isAdmin: true),
          layout: const HomeLayout(
            userId: 1,
            size: HomeCardSize.small,
            columns: 6,
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeShortcutCard), findsAtLeastNWidgets(6));
      },
    );

    testWidgets('the portal shell opens on the home grid', (tester) async {
      tester.view.physicalSize = desktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () =>
                  _StubAuthNotifier(_stateWith(codes: const [], isAdmin: true)),
            ),
          ],
          child: const MaterialApp(home: EmployeeMainLayout()),
        ),
      );
      await tester.pumpAndSettle();

      // الهيكل يفتح على «الرئيسية» ويستبدل الحالة الفارغة القديمة بالشبكة
      // The shell opens on «الرئيسية» and replaces the old empty state with the grid.
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeShortcutCard), findsAtLeastNWidgets(6));
    });

    testWidgets('a section card asks the shell for that section', (
      tester,
    ) async {
      String? opened;
      await _pumpHome(
        tester,
        size: mobile,
        auth: _stateWith(codes: const [Perm.customersView]),
        openSection: (id) => opened = id,
      );

      await tester.tap(find.byType(HomeShortcutCard).first);
      await tester.pumpAndSettle();

      // البطاقة الأولى في هذه المنح هي «العملاء» — هدفها قسم لا شاشة
      // The first card under these grants is «العملاء» — a section target, not a screen.
      expect(opened, 'customers');
    });
  });
}

/// حالة تخطيط ثابتة: لا تخزين ولا قرص في الاختبار
/// A fixed layout state: no storage and no disk in the test.
class _StubHomeLayoutNotifier extends HomeLayoutNotifier {
  _StubHomeLayoutNotifier(this._initial);

  final HomeLayoutState _initial;

  @override
  HomeLayoutState build() => _initial;
}

/// يقرأ عدد أعمدة الشبكة الفعلية من الـ delegate
/// Reads the grid's actual column count from its delegate.
int _gridColumns(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView).first);
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

  return delegate.crossAxisCount;
}

/// يقرأ نسبة البطاقة الفعلية من الـ delegate
/// Reads the tile's actual aspect ratio from the delegate.
double _gridRatio(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView).first);
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

  return delegate.childAspectRatio;
}

/// يحمّل شاشة التخصيص بنفس المنح والتخطيط الثابتين
/// Pumps the customise screen with the same fixed grants and layout.
Future<void> _pumpCustomize(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(_stateWith(codes: const [], isAdmin: true)),
        ),
        homeLayoutNotifierProvider.overrideWith(
          () => _StubHomeLayoutNotifier(
            HomeLayoutState(layout: HomeLayout.firstRun(1)),
          ),
        ),
      ],
      child: const MaterialApp(home: HomeCustomizeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// يحمّل الرئيسية على قياس معيّن بمنح وتخطيط ثابتين، ويُوصّلها بقناة أقسام وهمية
/// Pumps home at a given size with fixed grants and layout, wired to a fake section channel.
Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required AuthState auth,
  HomeLayout? layout,
  void Function(String sectionId)? openSection,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  final state = HomeLayoutState(layout: layout ?? HomeLayout.firstRun(1));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(auth)),
        homeLayoutNotifierProvider.overrideWith(
          () => _StubHomeLayoutNotifier(state),
        ),
      ],
      child: MaterialApp(
        builder:
            textScale == 1
                ? null
                : (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child ?? const SizedBox.shrink(),
                ),
        home: Scaffold(
          body: PortalSectionScope(
            openSection: openSection ?? (_) {},
            child: const HomeDashboardScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
