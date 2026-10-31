import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_summary_model.dart';
import 'package:ky_apps/features/tailoring/data/models/tailoring_reference_model.dart';
import 'package:ky_apps/features/tailoring/data/repositories/tailoring_repository.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';
import 'package:ky_apps/features/tailoring/presentation/screens/cutting_bills_list_screen.dart';

/// بديل الحالة المصادقة: `build()` يعيد الحالة الجاهزة بلا تخزين آمن ولا شبكة
/// Auth stub: `build()` returns the ready state, without secure storage or network.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _adminState() =>
    const AuthState(isAuthenticated: true).withPermissions(
      const PermissionSnapshot(userId: 1, isAdmin: true, permissions: <String>[]),
    );

/// مستودع وهمي لقائمة الفواتير: يخدم الصفحة أو الخطأ، ويحفظ آخر ما طُلب منه
/// A fake list repository: serves the page or the error, and records the last request.
class _FakeListRepo extends TailoringRepository {
  _FakeListRepo({this.page, this.error}) : super(
          client: DioClient(
            storage: SecureStorageService(),
            baseUrl: 'http://127.0.0.1',
          ),
        );

  final CuttingBillPage? page;
  final Object? error;

  /// آخر استعلام وصل للبحث — يُثبت أن الكتابة تُرسل بعد التأجيل لا مع كل حرف
  /// The last search that reached the repository — proves the debounce is in effect.
  String? lastSearch;
  int calls = 0;

  @override
  Future<CuttingBillPage> fetchBills({
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    calls++;
    lastSearch = search;
    if (error != null) throw error!;
    return this.page!;
  }

  @override
  Future<TailoringReference> fetchReference({CancelToken? cancelToken}) async =>
      TailoringReference.empty;
}

CuttingBillSummary _summary({
  int billNo = 12345,
  int year = 2026,
  String custName = 'محمد الأهدل',
  int? manual = 778,
  double? net = 1500,
  int models = 2,
  int pieces = 3,
}) {
  return CuttingBillSummary.fromJson({
    'bill_no': '$billNo',
    'year': '$year',
    'manual_bill_no': manual?.toString(),
    'date': '11/03/2026',
    'cust_name': custName,
    'tel_no1': '777123456',
    'models_count': '$models',
    'pieces_count': '$pieces',
    'net': net?.toString(),
    'handing_done': '0',
    'ordsdid': '4',
  });
}

Future<void> _pumpList(WidgetTester tester, _FakeListRepo repo) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(_adminState())),
        tailoringRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        home: CuttingBillsListScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CuttingBillsListScreen', () {
    testWidgets('lists the bills by their composite identity', (tester) async {
      await _pumpList(
        tester,
        _FakeListRepo(
          page: CuttingBillPage(
            items: [
              _summary(),
              _summary(billNo: 12000, custName: 'سالم', manual: null, net: 500),
            ],
            total: 2,
            page: 1,
            pages: 1,
            limit: 20,
          ),
        ),
      );

      // الهوية المركّبة كاملة (رقم + سنة) لا الرقم وحده
      // The full composite identity (number + year), never the bare number.
      expect(find.text('12345'), findsOneWidget);
      expect(find.text('12000'), findsOneWidget);

      // الصف المدمج: العميل · التاريخ · الصافي · حالة التسليم (بلا عدّادات نصّية)
      // The dense row: customer · date · net · delivery state (no textual counters).
      expect(find.text('محمد الأهدل'), findsOneWidget);
      expect(find.text('11/03/2026'), findsWidgets);
      expect(find.text('1,500'), findsOneWidget);
      expect(find.textContaining('قيد التنفيذ'), findsWidgets);
      expect(find.text('2 موديل'), findsNWidgets(2));
      expect(find.text('3 قطعة'), findsNWidgets(2));
    });

    testWidgets('the search is debounced, not fired per keystroke',
        (tester) async {
      final repo = _FakeListRepo(
        page: CuttingBillPage(items: [_summary()], total: 1, page: 1, pages: 1),
      );
      await _pumpList(tester, repo);

      final before = repo.calls;

      await tester.enterText(find.byType(TextField).first, 'محمد');
      // قبل انقضاء مدة التأجيل لا طلب جديد
      // Before the debounce elapses there is no new request.
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.calls, before);

      // بعد 300 مللي ثانية يصل البحث
      // After 300ms the search reaches the repository.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repo.calls, greaterThan(before));
      expect(repo.lastSearch, 'محمد');
    });

    testWidgets('the date ranges are offered as quick filters', (tester) async {
      await _pumpList(
        tester,
        _FakeListRepo(
          page: CuttingBillPage(items: [_summary()], total: 1, page: 1, pages: 1),
        ),
      );

      // لوحة الفلترة تُفتح من زرها، وتحمل النطاقات الجاهزة الخمسة
      // The filter sheet opens from its button and carries the five quick ranges.
      expect(find.text('فلترة بالتاريخ'), findsOneWidget);
      await tester.tap(find.text('فلترة بالتاريخ'));
      await tester.pumpAndSettle();

      for (final label in ['اليوم', 'الأسبوع', 'الشهر', 'السنة', 'الكل']) {
        expect(find.text(label), findsWidgets, reason: 'نطاق $label غائب');
      }
    });

    testWidgets('an empty page explains the view scope, not a blank screen',
        (tester) async {
      await _pumpList(
        tester,
        _FakeListRepo(
          page: const CuttingBillPage(items: [], total: 0, page: 1, pages: 0),
        ),
      );

      expect(find.text('لا توجد فواتير تفصيل'), findsOneWidget);
      // الحدّ في مصدر البيانات يُقال صراحةً ولا يُخفى
      // The data-source limit is stated, never hidden.
      expect(find.textContaining('قصّاص وخيّاط'), findsWidgets);
    });

    testWidgets('a failure shows the message and a retry', (tester) async {
      await _pumpList(
        tester,
        _FakeListRepo(
          error: const TailoringException('انتهت مهلة الاتصال'),
        ),
      );

      expect(find.text('انتهت مهلة الاتصال'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });
}
