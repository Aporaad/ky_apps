import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/auth/presentation/providers/permissions_notifier.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_section_titles.dart';
import 'package:ky_apps/features/employee_portal/presentation/screens/employee_main_layout.dart';
import 'package:ky_apps/features/employee_portal/presentation/widgets/collapsible_side_drawer.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_summary_model.dart';
import 'package:ky_apps/features/tailoring/data/models/tailoring_reference_model.dart';
import 'package:ky_apps/features/tailoring/data/repositories/tailoring_repository.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';

import '../support/quiet_network.dart';

/// صلاحيات خاملة: البنية الحقيقيّة تجدول مزامنة شبكية في `build()` لا مكان لها هنا
/// Idle permissions: the real notifier schedules a network sync in `build()`,
/// which a layout test has no business waiting for.
class _IdlePermissionsNotifier extends PermissionsNotifier {
  @override
  PermissionsState build() =>
      const PermissionsState(hasSynced: true, isSyncing: false);
}

/// مستودع تفصيل وهمي بلا شبكة — الجلب بعد التبديل يُقاس هنا لا عبر Dio
/// A network-free tailoring repository: the refetch after a switch is counted
/// here, never through Dio.
class _FakeTailoringRepo extends TailoringRepository {
  _FakeTailoringRepo()
      : super(client: DioClient(storage: SecureStorageService()));

  final List<String> searches = [];

  @override
  Future<CuttingBillPage> fetchBills({
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    searches.add(search);
    return const CuttingBillPage(items: [], total: 0, page: 1, pages: 0);
  }

  @override
  Future<TailoringReference> fetchReference({CancelToken? cancelToken}) async =>
      TailoringReference.empty;
}

/// يبنى الهيكل على مكتب عريض حتى يظهر الدرج بعناوينه لا بأيقوناته فقط
/// Pumps the portal on a wide desktop so the drawer renders its titles, not just icons.
Future<WidgetRef> _pumpPortal(
  WidgetTester tester,
  _FakeTailoringRepo repo,
) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  late WidgetRef captured;

  await tester.pumpWidget(
    ProviderScope(
      // التجاوزات مكتوبة حرفياً: نوع `Override` غير مُصدَّر من `flutter_riverpod`،
      // فلا يمكن تمريرها كقائمة جاهزة من الملف المساعد
      // The overrides are written out in place: `Override` is not exported by
      // `flutter_riverpod`, so they cannot be passed in as a prepared list.
      overrides: [
        dioClientProvider.overrideWithValue(quietDioClient()),
        secureStorageProvider.overrideWithValue(SecureStorageService()),
        authNotifierProvider.overrideWith(() => StubAuthNotifier(stubAdminState())),
        permissionsNotifierProvider.overrideWith(
          () => _IdlePermissionsNotifier(),
        ),
        tailoringRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Consumer(
          builder: (context, ref, _) {
            captured = ref;
            return const EmployeeMainLayout();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return captured;
}

/// نصّ القسم داخل الدرج وحده — الرئيسية تعرض العناوين نفسها على بطاقاتها
/// The section label inside the drawer only — the home dashboard prints the same
/// titles on its cards, so an unscoped finder would be ambiguous.
Finder _drawerItem(String title) {
  return find.descendant(
    of: find.byType(CollapsibleSideDrawer),
    matching: find.text(title),
  );
}

void main() {
  group('portal tab switch', () {
    testWidgets('leaving a section wipes the search it left behind',
        (tester) async {
      final repo = _FakeTailoringRepo();
      final ref = await _pumpPortal(tester, repo);

      // الدخول إلى التفصيل ثم البحث — نفس ما يفعله المستخدم تماماً
      // Enter tailoring, then search — exactly the user's own path.
      await tester.tap(_drawerItem(PortalSectionTitles.tailoring));
      await tester.pumpAndSettle();

      ref.read(cuttingBillsListProvider.notifier).search('خالد');
      await tester.pump();
      expect(ref.read(cuttingBillsListProvider).query, 'خالد');

      // المغادرة إلى العملاء: التفصيل يبقى mounted داخل `IndexedStack`،
      // فالنظافة لا تأتي من `dispose` بل من قناة التبديل الوحيدة
      // Leaving to customers: tailoring stays mounted inside the `IndexedStack`,
      // so cleanliness comes not from `dispose` but from the one switch channel.
      await tester.tap(_drawerItem(PortalSectionTitles.customers));
      await tester.pumpAndSettle();

      expect(
        ref.read(cuttingBillsListProvider).query,
        '',
        reason: 'خرج المستخدم من التفصيل، فيجب أن يُمحى بحثه',
      );
      expect(
        repo.searches.last,
        '',
        reason: 'الشاشة لا تزال mounted، فلا بد من جلب القائمة كاملة من جديد',
      );
    });

    testWidgets('staying on the same section wipes nothing', (tester) async {
      final repo = _FakeTailoringRepo();
      final ref = await _pumpPortal(tester, repo);

      await tester.tap(_drawerItem(PortalSectionTitles.tailoring));
      await tester.pumpAndSettle();

      ref.read(cuttingBillsListProvider.notifier).search('خالد');
      // انتظار انقضاء تأجيل الـ 300ms: ما يبقى من فرق في العدّ هو جلبٌ سببه التبديل وحده
      // Wait out the 300 ms debounce: any later difference in the counter can then
      // only be a switch-caused fetch.
      await tester.pump(const Duration(milliseconds: 400));

      final before = repo.searches.length;

      // الضغط على نفس التبويب مجدداً — لا تفريغ ولا جلب إضافي
      // Tapping the same tab again — no wipe, no extra fetch.
      await tester.tap(_drawerItem(PortalSectionTitles.tailoring));
      await tester.pumpAndSettle();

      expect(ref.read(cuttingBillsListProvider).query, 'خالد');
      expect(repo.searches.length, before);
    });
  });
}
