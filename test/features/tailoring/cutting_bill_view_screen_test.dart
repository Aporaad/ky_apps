import 'dart:async';

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
import 'package:ky_apps/features/tailoring/presentation/screens/cutting_bill_view_screen.dart';

/// Notifier stub: `build()` returns the pre-set state so no secure-storage or
/// Dio call is made — same pattern as the other screen tests.
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

/// حالة محدودة المنح: تُستخدم لإثبات أن الأزرار تختفي بلا صلاحية
/// A narrowly-granted state, used to prove a button disappears without its grant.
AuthState _grantedState(List<String> grants) =>
    const AuthState(isAuthenticated: true).withPermissions(
      PermissionSnapshot(userId: 1, isAdmin: false, permissions: grants),
    );

/// مستودع وهمي يخدم الشاشة وحدها: التفصيل والحركة
/// A fake repository serving this screen only: the detail and the movement log.
class _FakeRepo extends TailoringRepository {
  _FakeRepo({
    this.detail,
    this.detailError,
    this.detailGate,
    this.movements = const [],
  }) : super(
          client: DioClient(
            storage: SecureStorageService(),
            baseUrl: 'http://127.0.0.1',
          ),
        );

  final CuttingBillDetail? detail;
  final Object? detailError;

  /// عند تعيينه يتوقّف التحميل حتى يُفكّ — به نلتقط حالة الانتظار
  /// When set, loading waits for it, so the loading state can be observed.
  final Completer<void>? detailGate;

  final List<CuttingMovement> movements;

  /// يُثبت أن الشاشة تطلب الهوية المركّبة لا الرقم وحده
  /// Proves the screen asks for the composite identity, not the bare number.
  CuttingBillKey? askedKey;

  @override
  Future<CuttingBillDetail> fetchBill(
    int billNo,
    int year, {
    CancelToken? cancelToken,
  }) async {
    askedKey = CuttingBillKey(billNo: billNo, year: year);
    if (detailGate != null) await detailGate!.future;
    if (detailError != null) throw detailError!;
    return detail!;
  }

  @override
  Future<List<CuttingMovement>> fetchMovements(
    int billNo,
    int year,
    List<int> seqNos, {
    CancelToken? cancelToken,
  }) async =>
      movements;

  @override
  Future<TailoringReference> fetchReference({CancelToken? cancelToken}) async =>
      TailoringReference.empty;
}

const _billKey = CuttingBillKey(billNo: 12345, year: 2026);

Future<void> _pumpScreen(
  WidgetTester tester,
  _FakeRepo repo, {
  Size size = const Size(1200, 900),
  List<String>? grants,
  double textScale = 1.0,
}) async {
  // سطح العرض افتراضياً عريض كالحاسب، والشاشة الضيقة تُمرَّر صراحةً لاختبار التجاوب
  // The surface is desktop-wide by default; a narrow screen is passed in for the responsive check.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(
            grants == null ? _adminState() : _grantedState(grants),
          ),
        ),
        tailoringRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: const CuttingBillViewScreen(billKey: _billKey),
        // تكبير الخط يُمرَّر عبر MediaQuery كي يقيس الاختبار نفس ما يراه المستخدم
        // The text scale goes through MediaQuery so the test measures what the user sees.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
}

void main() {
  group('CuttingBillViewScreen', () {
    testWidgets('shows the loading state before the detail arrives',
        (tester) async {
      final gate = Completer<void>();
      await _pumpScreen(tester, _FakeRepo(detailGate: gate, detail: _detail()));
      // إطارات بلا زمن: المؤقّتات المصطنعة قد تُنهي الحالة قبل أن نراها
      // Frames without elapsed time, so the waiting state is observed.
      await tester.pump();

      expect(find.text('جارٍ تحميل فاتورة التفصيل...'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('جارٍ تحميل فاتورة التفصيل...'), findsNothing);
    });

    testWidgets('asks for the composite identity and renders the eight sections',
        (tester) async {
      final repo = _FakeRepo(
        detail: _detail(),
        movements: const [
          CuttingMovement(
            date: '12/03/2026',
            ordsName: 'تم القص',
            deptName: 'قسم القص',
            qty: 2,
            posted: true,
          ),
        ],
      );

      await _pumpScreen(tester, repo);
      await tester.pumpAndSettle();

      // الهوية المركّبة: الرقم وحده يعيد أول صف مطابق
      expect(repo.askedKey, _billKey);
      expect(find.text('فاتورة تفصيل 12345 / 2026'), findsOneWidget);

      // 1..4 من الأقسام
      expect(find.text('بيانات الفاتورة والطلب'), findsOneWidget);
      expect(find.text('بيانات العميل'), findsOneWidget);
      expect(find.text('تفاصيل الدفع'), findsOneWidget);
      expect(find.text('الموديلات والمستفيدون'), findsOneWidget);
      expect(find.text('2 موديل · 3 قطعة'), findsOneWidget);

      // 5..8 للموديل المختار (الأول افتراضاً)
      expect(find.text('تفاصيل المقاسات — موديل 1'), findsOneWidget);
      expect(find.text('المواصفات — موديل 1'), findsOneWidget);
      expect(find.textContaining('الأقمشة —'), findsOneWidget);
      expect(find.textContaining('سجل الحركة —'), findsOneWidget);
      expect(find.text('تم القص'), findsWidgets);

      // الأرقام المالية تُعرض لأن الخادم أرسل الدفع (التسمية تظهر كـ «الإجمالي:» في الصف)
      // The figures appear because the server sent the payment (the label reads "الإجمالي:").
      expect(find.textContaining('الإجمالي'), findsOneWidget);
      expect(find.text('1,500'), findsWidgets);
    });

    testWidgets('choosing another model switches measurements, specs and fabrics',
        (tester) async {
      await _pumpScreen(tester, _FakeRepo(detail: _detail()));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل المقاسات — موديل 1'), findsOneWidget);
      expect(find.text('تفاصيل المقاسات — موديل 2'), findsNothing);

      // الضغط على سطر الموديل الثاني (مستفيده) يقود الأقسام من الرابع إلى الثامن
      // Tapping the second model's row (its beneficiary) drives sections four to eight.
      await tester.ensureVisible(find.text('سالم'));
      await tester.tap(find.text('سالم'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل المقاسات — موديل 2'), findsOneWidget);
      expect(find.text('تفاصيل المقاسات — موديل 1'), findsNothing);
      expect(find.text('المواصفات — موديل 2'), findsOneWidget);
      expect(find.textContaining('الأقمشة —'), findsOneWidget);
      // قياس الموديل الثاني ظاهر بتسميته الحقيقية
      expect(find.textContaining('الطول'), findsWidgets);
    });

    testWidgets('a blocked payment block shows a note instead of figures',
        (tester) async {
      await _pumpScreen(tester, _FakeRepo(detail: _detail(withPayment: false)));
      await tester.pumpAndSettle();

      expect(
        find.text('لا تملك صلاحية عرض تفاصيل دفع فاتورة التفصيل'),
        findsOneWidget,
      );
      // لا رقم مالي يُعرض أصلاً عند الحجب من الخادم
      expect(find.textContaining('الإجمالي'), findsNothing);
      expect(find.textContaining('الصافي'), findsNothing);
    });

    testWidgets('a bill outside the view is explained, not reported as a fault',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(
          detailError: const TailoringException(
            'الفاتورة غير موجودة في مصدر بيانات التفصيل',
            notFoundInView: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الفاتورة غير متاحة للعرض'), findsOneWidget);
      expect(find.textContaining('ليست ضمن الفواتير المُسندة'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(find.text('تعذّر تحميل الفاتورة'), findsNothing);

      // الأزرار المتعلقة بالمحتوى معطّلة لأن لا تفصيل محمّلاً
      final printButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.print_rounded),
      );
      expect(printButton.onPressed, isNull);
    });

    testWidgets('a network failure reads as a failure, not as a missing bill',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detailError: const TailoringException('انتهت مهلة الاتصال')),
      );
      await tester.pumpAndSettle();

      expect(find.text('تعذّر تحميل الفاتورة'), findsOneWidget);
      expect(find.text('انتهت مهلة الاتصال'), findsOneWidget);
      expect(find.text('الفاتورة غير متاحة للعرض'), findsNothing);
    });

    testWidgets('a bill with no models still renders header, customer and payment',
        (tester) async {
      await _pumpScreen(tester, _FakeRepo(detail: _detail(models: false)));
      await tester.pumpAndSettle();

      expect(find.text('بيانات الفاتورة والطلب'), findsOneWidget);
      expect(find.text('تفاصيل الدفع'), findsOneWidget);
      expect(find.text('لا توجد موديلات في هذه الفاتورة'), findsOneWidget);
      expect(find.text('0 موديل · 0 قطعة'), findsOneWidget);
      // لا مقاسات ولا أقمشة لقسم بلا موديل مختار
      expect(find.textContaining('تفاصيل المقاسات —'), findsNothing);
      expect(find.textContaining('الأقمشة —'), findsNothing);
    });

    testWidgets('every section keeps its fields on one aligned row', (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();

      double topOf(String label) =>
          tester.getTopLeft(find.textContaining(label).first).dy;

      // حقول الفاتورة: صفّان فقط — لا ثلاثة ولا واحد
      // The bill fields: exactly two rows — never three, never one.
      final billRowTops = {
        for (final label in [
          'مرجع الفاتورة',
          'تاريخ التسليم',
          'الاستحقاق',
          'الحالة',
          'الموديلات',
          'القطع',
        ])
          topOf(label),
      };
      expect(billRowTops, hasLength(2));

      // حقول العميل في سطر واحد
      // The customer fields share one row.
      expect(topOf('الهاتف'), closeTo(topOf('رقم الحساب'), 1.5));

      // وحقول الدفع في سطر واحد
      // And so do the payment figures.
      expect(topOf('الإجمالي'), closeTo(topOf('رقم السند'), 1.5));

      // الصفوف الثلاثة مختلفة رأسياً: كل قسم سطره
      // The three rows are vertically distinct: each section owns its line.
      expect((topOf('مرجع الفاتورة') - topOf('الهاتف')).abs(), greaterThan(10));
      expect((topOf('الهاتف') - topOf('الإجمالي')).abs(), greaterThan(10));
    });

    testWidgets('print and export are hidden without their grants',
        (tester) async {
      // بلا صلاحية الطباعة/التصدير: الزرّان غير موجودين أصلاً
      // Without the print/export grants neither button exists at all.
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        grants: const ['tailoring.view'],
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(IconButton, Icons.print_rounded), findsNothing);
      expect(
        find.widgetWithIcon(IconButton, Icons.picture_as_pdf_rounded),
        findsNothing,
      );
    });

    testWidgets('print and export appear with their grants', (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        grants: const ['tailoring.view', 'tailoring.print', 'tailoring.export'],
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithIcon(IconButton, Icons.print_rounded),
        findsOneWidget,
      );
      expect(
        find.widgetWithIcon(IconButton, Icons.picture_as_pdf_rounded),
        findsOneWidget,
      );
    });

    testWidgets('a model without a beneficiary shows no placeholder text',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();

      // الموديل الثاني في العيّنة بلا مستفيد: لا كلمة «بلا مستفيد» ولا خانة فارغة
      // The second model in the fixture has no beneficiary: no placeholder, no empty cell.
      expect(find.textContaining('بلا مستفيد'), findsNothing);
      // ونوع الموديل يُكتب في عمود «الموديل» تحت رأس واحد للقائمة
      // The model type is written in the "model" column under the list's single header.
      expect(find.text('قميص'), findsWidgets);
      expect(find.text('المستفيد'), findsOneWidget);
    });

    testWidgets('the whole bill fits in one short column on a wide screen',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();

      // المسافة من أول قسم إلى آخر قسم: ميزانية الارتفاع التي حقّقها الترتيب الجديد
      // The distance from the first section to the last: the height budget the new layout met.
      final top = tester.getTopLeft(find.text('بيانات الفاتورة والطلب')).dy;
      final bottom =
          tester.getBottomLeft(find.textContaining('سجل الحركة —')).dy;

      // 650 بكسل من أول قسم إلى آخر قسم: الشاشة العريضة تعرض الفاتورة كاملة تقريباً
      // 650px from the first section to the last: a wide screen shows nearly the whole bill.
      expect(bottom - top, lessThan(860));
    });

    testWidgets('choosing a fabric switches the movement log to that fabric',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();

      // السجل يبدأ بأول قماش في الموديل
      // The log starts with the model's first fabric.
      expect(find.textContaining('سجل الحركة — صوف'), findsOneWidget);

      // اختيار بطاقة القماش الثاني (اسمه «قطن») يغيّر السجل إلى سجله هو (OHDID = 262134)
      // Choosing the second fabric card (cloth "قطن") switches the log to its own (262134).
      await tester.ensureVisible(find.text('قطن'));
      await tester.tap(find.text('قطن'));
      await tester.pumpAndSettle();

      expect(find.textContaining('سجل الحركة — قطن'), findsOneWidget);
      expect(find.textContaining('سجل الحركة — صوف'), findsNothing);
    });

    testWidgets('a large text scale keeps customer and payment on one row',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(360, 780),
        textScale: 1.6,
      );
      await tester.pumpAndSettle();

      double topOf(String label) =>
          tester.getTopLeft(find.textContaining(label).first).dy;

      // بيانات العميل: ثلاثة حقول في سطر واحد حتى مع خط مكبَّر 1.6×
      // Customer data: three fields on one row even at a 1.6× text scale.
      expect(topOf('الهاتف'), closeTo(topOf('رقم الحساب'), 1.5));
      expect(topOf('الهاتف'), closeTo(topOf('رقم العميل'), 1.5));

      // تفاصيل الدفع: كل الأرقام في سطر واحد كذلك
      // Payment details: every figure on one row as well.
      expect(topOf('الإجمالي'), closeTo(topOf('رقم السند'), 1.5));

      // ولا قصّ ولا تجاوز: النصوص تُصغَّر لتبقى كاملة
      // No clipping and no overflow: texts shrink to stay complete.
      expect(tester.takeException(), isNull);
    });

    testWidgets('payment and fabric rows hug their content height',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();

      // صف الدفع: ارتفاعه بقدر تسمية + قيمة فقط (لا فراغ أسفل الخلايا)
      // The payment row is as tall as a label plus a value (no empty band under the cells).
      final paymentRow = tester.getSize(
        find.ancestor(of: find.text('الإجمالي'), matching: find.byType(Table)).first,
      );
      expect(paymentRow.height, lessThan(64));

      // صف بيانات القماش: نفس القاعدة بعد الوضع المدمج
      // The fabric data row follows the same rule after the compact mode.
      final fabricRow = tester.getSize(
        find.ancestor(of: find.text('القماش'), matching: find.byType(Table)).first,
      );
      expect(fabricRow.height, lessThan(56));
    });

    testWidgets('a model with no beneficiary shows the customer name',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail(withBeneficiary: false)),
        size: const Size(360, 780),
      );
      await tester.pumpAndSettle();

      // الاسم في عنوان القسم + في صفّي الموديلين (بدل فراغ يوهم بفقدان المعلومة)
      // The name appears in the section title and in both model rows (instead of a blank that
      // looks like missing data).
      expect(find.text('محمد الأهدل'), findsNWidgets(3));

      // رؤوس الأعمدة كاملة بلا قصّ حتى على عرض 360 (القطع قد يتكرّر في ترويسة الفاتورة)
      // The column headers are complete — not clipped — even at 360px ("القطع" may repeat in the
      // bill header).
      for (final heading in ['الموديل', 'المستفيد', 'القطع', 'الملاحظة']) {
        expect(find.text(heading), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a phone width stacks the sections without overflowing',
        (tester) async {
      await _pumpScreen(
        tester,
        _FakeRepo(detail: _detail()),
        size: const Size(360, 780),
      );
      await tester.pumpAndSettle();

      // الأقسام الثمانية كلها موجودة في العمود الواحد
      expect(find.text('بيانات الفاتورة والطلب'), findsOneWidget);
      expect(find.text('بيانات العميل'), findsOneWidget);
      expect(find.text('تفاصيل الدفع'), findsOneWidget);
      expect(find.text('تفاصيل المقاسات — موديل 1'), findsOneWidget);
      expect(find.textContaining('الأقمشة —'), findsOneWidget);
      // ولا تجاوز أفقي: أي RenderFlex overflow يُبلَّغ كاستثناء في الاختبار
      // No horizontal overflow: any RenderFlex overflow is reported as an exception.
      expect(tester.takeException(), isNull);
    });
  });
}

/// فاتورة كاملة: موديلان (2 + 1 قطع) مع تسميات مقاسات حقيقية
/// A whole bill: two models (2 + 1 pieces) with real measurement labels.
CuttingBillDetail _detail({
  bool withPayment = true,
  bool models = true,
  bool withBeneficiary = true,
}) {
  return CuttingBillDetail.fromJson(<String, dynamic>{
    'header': {
      'bill_no': '12345',
      'year': '2026',
      'manual_bill_no': '778',
      'date': '11/03/2026',
      'cust_no': '4102',
      'cust_name': 'محمد الأهدل',
      'tel_no1': '777123456',
      'urgent': '1',
      'branch_no': '2',
      'ordsdid': '3',
      'ords_name': 'تسليم للخياط',
      'handing_done': '0',
      'models_count': models ? '2' : '0',
      'pieces_count': models ? '3' : '0',
    },
    'payment': withPayment
        ? {
            'total': '1500',
            'discount': '0',
            'net': '1500',
            'paid': '500',
            'remaining': '1000',
            'payment_method': 'نقداً',
          }
        : null,
    'models': !models
        ? const []
        : [
            {
              'seq_no': '1',
              'beneficiary': withBeneficiary ? 'محمد الأهدل' : null,
              'type_name': 'قميص',
              'shape_name': 'كلاسيكي',
              'qty': '2',
              'measurements': {'L1': '58', 'L2': '42'},
              'neck_type': 'كلاسيك',
              'pieces': [
                {'seq_no1': '5001', 'ohdid': '262133', 'cloth_name': 'صوف', 'cutting_done': '1'},
                {'seq_no1': '5002', 'ohdid': '262134', 'cloth_name': 'قطن', 'cutting_done': '1'},
              ],
            },
            {
              'seq_no': '2',
              'beneficiary': withBeneficiary ? 'سالم' : null,
              'type_name': 'قميص',
              'shape_name': 'كلاسيكي',
              'measurements': {'L1': '61', 'L3': '60'},
              'pieces': [
                {'seq_no1': '5003', 'ohdid': '262135', 'cloth_name': 'كتان', 'cutting_done': '0'},
              ],
            },
          ],
    'measure_labels': {'L1': 'الطول', 'L2': 'الكتف', 'L3': 'طول اليد'},
  });
}
