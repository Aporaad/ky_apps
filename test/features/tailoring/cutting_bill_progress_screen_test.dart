import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_detail_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_summary_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_movement_model.dart';
import 'package:ky_apps/features/tailoring/data/models/tailoring_reference_model.dart';
import 'package:ky_apps/features/tailoring/data/repositories/tailoring_repository.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';
import 'package:ky_apps/features/tailoring/presentation/screens/cutting_bill_progress_screen.dart';

/// Notifier stub: `build()` returns the pre-set admin state, so no storage/Dio call happens.
class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _adminState() =>
    const AuthState(isAuthenticated: true).withPermissions(
      const PermissionSnapshot(
        userId: 1,
        isAdmin: true,
        permissions: <String>[],
      ),
    );

/// مستودع وهمي يسجّل أرقام الطلبات المطلوبة للسجل — لإثبات أنه على مستوى القماش
/// A fake repository that records the requested order ids, proving the log is per fabric.
class _FakeRepo extends TailoringRepository {
  _FakeRepo({
    required this.detail,
    this.reference = TailoringReference.empty,
    this.movements = const [],
  }) : super(
          client: DioClient(
            storage: SecureStorageService(),
            baseUrl: 'http://127.0.0.1',
          ),
        );

  final CuttingBillDetail detail;
  final TailoringReference reference;
  final List<CuttingMovement> movements;

  /// آخر أرقام طلبات طُلب بها السجل — يجب أن تكون قماشاً واحداً لا الفاتورة كلها
  /// The last order ids the log was requested with — one fabric, never the whole bill.
  List<int>? askedOhdIds;

  @override
  Future<CuttingBillDetail> fetchBill(
    int billNo,
    int year, {
    CancelToken? cancelToken,
  }) async =>
      detail;

  @override
  Future<List<CuttingMovement>> fetchMovements(
    int billNo,
    int year,
    List<int> ohdIds, {
    CancelToken? cancelToken,
  }) async {
    askedOhdIds = ohdIds;
    return movements;
  }

  @override
  Future<TailoringReference> fetchReference({CancelToken? cancelToken}) async =>
      reference;
}

const _billKey = CuttingBillKey(billNo: 778, year: 2026);

/// فاتورة بموديلين: الأول للعميل بلا مستفيد، والثاني لمستفيد — وقماش لكل موديل
/// A bill with two models: the first for the customer (no beneficiary), the second for a
/// beneficiary — one fabric each, with distinct order ids and cloth names.
CuttingBillDetail _detail() => CuttingBillDetail.fromJson({
      'header': {
        'bill_no': '778',
        'year': '2026',
        'cust_name': 'سالم الكبودي',
        'ordsdid': '0',
      },
      'payment': null,
      'models': [
        {
          'seq_no': '1',
          'beneficiary': null,
          'type_name': 'قميص',
          'pieces': [
            {
              'seq_no1': '10',
              'ohdid': '101',
              'cloth_name': 'قماش أول',
              'color_text': 'أبيض',
              'cutting_done': '1',
            },
          ],
        },
        {
          'seq_no': '2',
          'beneficiary': 'محمد الأهدل',
          'type_name': 'بنطلون',
          'pieces': [
            {
              'seq_no1': '20',
              'ohdid': '202',
              'cloth_name': 'قماش ثاني',
              'color_no': '3',
              'tailor_done': '1',
            },
          ],
        },
      ],
      'measure_labels': {},
    });

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  Size size = const Size(1200, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(_adminState())),
        tailoringRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: const CuttingBillProgressScreen(billKey: _billKey),
      ),
    ),
  );
}

void main() {
  group('CuttingBillProgressScreen', () {
    testWidgets('renders the five-column bill fabrics table', (tester) async {
      await _pump(tester, _FakeRepo(detail: _detail()));
      await tester.pumpAndSettle();

      // الأعمدة الخمسة فقط
      for (final heading in const [
        'رقم الطلب',
        'الموديل',
        'العميل/المستفيد',
        'اسم القماش',
        'اللون',
      ]) {
        expect(find.text(heading), findsWidgets);
      }

      // الأقمشة وأرقام الطلبات ظاهرة
      expect(find.text('قماش أول'), findsWidgets);
      expect(find.text('قماش ثاني'), findsWidgets);
      expect(find.text('101'), findsWidgets);
      expect(find.text('202'), findsWidgets);

      // لا أعمدة محذوفة: لا سعر ولا عرض ولا هنش في جدول المتابعة
      expect(find.text('العرض'), findsNothing);
      expect(find.text('السعر'), findsNothing);
    });

    testWidgets('shows the customer when a model has no beneficiary',
        (tester) async {
      await _pump(tester, _FakeRepo(detail: _detail()));
      await tester.pumpAndSettle();

      // المستفيد الخاص بالموديل الثاني، واسم العميل الأصلي بدل الفارغ في الأول
      // The second model's beneficiary, and the original customer name for the first.
      expect(find.text('محمد الأهدل'), findsWidgets);
      expect(find.text('سالم الكبودي'), findsWidgets);
    });

    testWidgets('requests the movement log for the selected fabric only',
        (tester) async {
      final repo = _FakeRepo(detail: _detail());
      await _pump(tester, repo);
      await tester.pumpAndSettle();

      // التحديد الافتراضي أول قماش: السجل يُطلب برقم طلبه وحده لا بكل أرقام الفاتورة
      // Default choice is the first fabric: the log is asked with its order id alone.
      expect(repo.askedOhdIds, [101]);
    });

    testWidgets('choosing another fabric re-requests its order id and retitles',
        (tester) async {
      final repo = _FakeRepo(detail: _detail());
      await _pump(tester, repo);
      await tester.pumpAndSettle();

      // اختيار قماش الموديل الثاني عبر الضغط على صفّه في الجدول
      // Pick the second model's fabric by tapping its table row.
      await tester.tap(find.text('قماش ثاني').first);
      await tester.pumpAndSettle();

      // السجل الآن على رقم طلب هذا القماش وحده
      // The log is now keyed to this fabric's order id alone.
      expect(repo.askedOhdIds, [202]);

      // والمخطط والسجل يحملان اسم القماش المحدد
      // And the chart and log titles carry the selected fabric's name.
      expect(
        find.textContaining('مخطط سير القماش — قماش ثاني'),
        findsOneWidget,
      );
      expect(
        find.textContaining('سجل حركة القماش — قماش ثاني'),
        findsOneWidget,
      );
    });

    testWidgets('a narrow screen renders the fabrics table without overflow',
        (tester) async {
      await _pump(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(360, 780),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('رقم الطلب'), findsWidgets);
    });

    testWidgets('the chart shows completed stages plus one upcoming, hides the rest',
        (tester) async {
      // خمس مراحل، والقماش عند المرحلة 2: يُعرض 1·2·3 فقط ويُخفى 4·5 خلف زر إظهار
      // Five stages, the fabric is at stage 2: only 1·2·3 show, 4·5 hide behind a reveal button.
      final reference = TailoringReference(
        stages: [
          for (var i = 1; i <= 5; i++)
            TailoringStage(
              ordsid: i,
              ordsname: 'مرحلة $i',
              nextOrdsid: i < 5 ? i + 1 : null,
            ),
        ],
      );

      final repo = _FakeRepo(
        detail: _detail(),
        reference: reference,
        movements: const [
          CuttingMovement(ordsid: 1, ordsName: 'مرحلة 1', date: '01/11/2026'),
          CuttingMovement(
            ordsid: 2,
            ordsName: 'مرحلة 2',
            date: '02/11/2026',
            executor: 'قسم القص',
          ),
        ],
      );
      await _pump(tester, repo);
      await tester.pumpAndSettle();

      // المنجزة + الحالية + القادمة الواحدة ظاهرة، وما بعدها مخفي
      expect(find.text('مرحلة 1'), findsWidgets);
      expect(find.text('مرحلة 2'), findsWidgets);
      expect(find.text('مرحلة 3'), findsWidgets);
      expect(find.text('مرحلة 4'), findsNothing);
      expect(find.text('مرحلة 5'), findsNothing);

      // بيانات المرحلة بجانب اسمها: التاريخ والمنفّذ من سجل الحركة
      // The stage's data beside its name: date and executor from the movement log.
      expect(find.textContaining('02/11/2026'), findsWidgets);

      // زر الإظهار الصغير ثم الكشف
      expect(find.textContaining('إظهار المراحل التالية'), findsOneWidget);
      await tester.tap(find.textContaining('إظهار المراحل التالية'));
      await tester.pumpAndSettle();

      expect(find.text('مرحلة 4'), findsWidgets);
      expect(find.text('مرحلة 5'), findsWidgets);
    });
  });
}
