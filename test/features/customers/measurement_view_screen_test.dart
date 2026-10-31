import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/customers/data/models/measurement_model_ref.dart';
import 'package:ky_apps/features/customers/data/repositories/customer_measurement_repository.dart';
import 'package:ky_apps/features/customers/presentation/providers/customer_measurement_providers.dart';
import 'package:ky_apps/features/customers/presentation/screens/measurement_view_screen.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_detail_model.dart';

/// شاشة عرض المقاسات على مستودع وهمي: المحروس هو السلوك لا البيانات
/// The measurements screen over a fake repository: behaviour is under test, not data.
///
/// أربع حالات عرض، إظهار الفلترة وإخفاؤها، إخفاء الأقسام بمرشّح الشاشة، واختفاء أزرار
/// الطباعة والتصدير بلا منح — وهي القرارات التي لا يمسكها المترجم ولا اختبار النموذج.
/// The four render states, showing and hiding the filter bar, section visibility through the
/// screen's own filter, and print/export buttons vanishing without their grants — decisions no
/// compiler and no model test can catch.
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

AuthState _grantedState(List<String> grants) =>
    const AuthState(isAuthenticated: true).withPermissions(
      PermissionSnapshot(userId: 1, isAdmin: false, permissions: grants),
    );

class _FakeRepo extends CustomerMeasurementRepository {
  _FakeRepo({this.subject, this.error, this.gate})
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  final MeasurementSubject? subject;
  final Object? error;

  /// عند تعيينه يتوقف التحميل حتى يُفكّ — به تُلتقط حالة الانتظار
  /// When set, loading waits for it, so the loading state can be observed.
  final Completer<void>? gate;

  /// آخر مفتاح طُلب — يُثبت أن الشاشة تطلب الرباعي الكامل لا أجزاءه
  /// The last requested key — proves the screen asks for the whole four-part key.
  MeasurementKey? askedKey;

  /// الأحداث المسجّلة — للاختبار أن الطباعة تُدقَّق ولا تُفشل
  /// Recorded events — to test that printing is audited yet never fails.
  final List<String> activity = [];

  @override
  Future<MeasurementSubject> fetchModel(
    MeasurementKey key, {
    CancelToken? cancelToken,
  }) async {
    askedKey = key;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;

    return subject!;
  }

  @override
  Future<bool> recordActivity(
    MeasurementKey key, {
    required String action,
  }) async {
    activity.add(action);

    return true;
  }
}

const _key = MeasurementKey(custNo: 40, billNo: 35, year: 2023, seqNo: 48);

/// حزمة نموذجية: موديل بثلاث قطع وعشرة مقاسات ومواصفة واحدة
/// A typical bundle: one model with three pieces, ten measurements and one spec.
MeasurementSubject _subject({List<MeasurementSibling>? siblings}) {
  return MeasurementSubject(
    custNo: 40,
    detail: CuttingBillDetail.fromJson(const <String, dynamic>{
      'header': {
        'bill_no': 35,
        'year': 2023,
        'cust_no': 40,
        'cust_name': 'تراب الصغير',
        'tel_no1': '777123456',
        'date': '09/02/2023',
        'ords_name': 'قيد التنفيذ',
      },
      'models': [
        {
          'seq_no': 48,
          'beneficiary': 'أحمد',
          'type_name': 'قصيري',
          'shape_name': 'عادي',
          'qty': 1,
          'measurements': {'L1': 58, 'L2': 17, 'L5': 19},
          'specs': {'neck_type': 'مربع'},
          'pieces': [
            {
              'seq_no1': 1,
              'ohdid': 9001,
              'cloth_name': 'قماش صيفي',
              'cloth_type': 'عرضية',
              'color_text': 'أبيض',
              'hinsh': 108,
              'yards': 3,
              'price': 2.28,
              'cutter_name': 'أحمد نصران',
              'tailor_done': 1,
            },
            {
              'seq_no1': 2,
              'ohdid': 9002,
              'cloth_name': 'قماش شتوي',
              'cloth_type': 'ضيقه',
              'color_text': 'كحلي',
              'hinsh': 120,
              'yards': 4,
              'price': 3.5,
              'cutter_name': 'أحمد نصران',
              'tailor_name': 'سالم',
            },
            {
              'seq_no1': 3,
              'ohdid': 9003,
              'cloth_name': 'قماش قطني',
              'tailor_done': 0,
            },
          ],
        },
      ],
      'measure_labels': {'L1': 'الطول', 'L2': 'الكتف', 'L5': 'عرض'},
    }),
    siblings:
        siblings ??
        const [
          MeasurementSibling(seqNo: 48, beneficiary: 'أحمد', selected: true),
          MeasurementSibling(seqNo: 49, beneficiary: 'سالم'),
        ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  Size size = const Size(1200, 900),
  List<String>? grants,
}) async {
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
        customerMeasurementRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        home: MeasurementViewScreen(modelKey: _key, custName: 'تراب الصغير'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the four requested sections with real labels', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    expect(find.text('بيانات العميل والمستفيد'), findsOneWidget);
    expect(find.text('تفاصيل المقاسات'), findsOneWidget);
    expect(find.text('مواصفات الموديل'), findsOneWidget);
    expect(find.text('الأقمشة الخاصة بالموديل'), findsOneWidget);

    // التسميات من GENERAL_LABELS_CODING لا من الشاشة: «الطول» لا L1
    // Labels come from the database dictionary: "الطول", never the raw L1.
    expect(find.text('الطول'), findsWidgets);
    expect(find.text('أحمد'), findsWidgets);

    // التكبير بالإصبع والأزرار: الغلاف الموحّد موجود بلا نسبة مخفية
    // Pinch and button zoom: the shared shell is present with its live percentage.
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('the fabrics show the requested columns in two lines, and nothing else', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    // السطر الأول: رقم الطلب · القماش · العرض · اللون · هنش · ياردة · السعر
    // Line one: order id, cloth, width, colour, hinsh, yards, price.
    // القائمة كلها تُفحص مرة واحدة: الفحص أولاً بأول يُخفي الأعمدة الناقصة خلف أولها
    // Every label is checked in one pass: checking one-by-one hides the rest behind the first miss.
    const firstLine = [
      'رقم الطلب',
      'القماش',
      'العرض',
      'اللون',
      'هنش',
      'ياردة',
      'السعر',
    ];
    final missingFirst = firstLine
        .where((label) => find.text(label).evaluate().isEmpty)
        .toList();
    expect(missingFirst, isEmpty, reason: 'أعمدة ناقصة في السطر الأول');

    // السطر الثاني: القصّاص · الخيّاط · المرحلة
    // Line two: cutter, tailor and stage.
    expect(find.text('القصّاص'), findsWidgets);
    expect(find.text('الخيّاط'), findsWidgets);
    expect(find.text('المرحلة'), findsWidgets);
    expect(find.text('9001'), findsWidgets);
    // الخيّاط غير المسند يُسمّى، ولا يُترك شرطة تُقرأ «لا بيانات»
    // An unassigned tailor is named, never left as a dash that reads as "no data".
    expect(find.text('غير مسند'), findsWidgets);

    // الرف والمصدر محذوفان بطلب صريح
    // Shelf and source are removed on request.
    expect(find.text('الرف'), findsNothing);
    expect(find.text('المصدر'), findsNothing);
  });

  testWidgets('the deleted identity fields never appear', (tester) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    for (final label in ['العنوان', 'مجموعة الحساب', 'شكل الموديل', 'رقم الموديل', 'الفرع']) {
      expect(find.text(label), findsNothing, reason: 'حقل كان يجب حذفه: $label');
    }

    // لا نص اعتذاري عن مستفيد غائب، ولا تكرار لاسم العميل داخل القسم
    // No apologetic "no beneficiary" text anywhere, and no repeated customer name in the body.
    expect(find.text('بلا مستفيد محدّد'), findsNothing);
    expect(find.text('اسم العميل'), findsNothing);
  });

  testWidgets('a model without a beneficiary hides the field instead of announcing it', (
    tester,
  ) async {
    final bare = MeasurementSubject(
      custNo: 40,
      detail: CuttingBillDetail.fromJson(const <String, dynamic>{
        'header': {'bill_no': 35, 'year': 2023, 'cust_no': 40, 'cust_name': 'تراب'},
        'models': [
          {'seq_no': 48, 'type_name': 'قصيري', 'pieces': [{'seq_no1': 1}]},
        ],
      }),
    );
    await _pump(tester, _FakeRepo(subject: bare));

    // خانة المستفيد نفسها غائبة، لا غائبة بقيمتها الفارغة
    // The beneficiary cell is gone entirely, not present-with-an-empty-value.
    expect(find.text('اسم المستفيد'), findsNothing);
    expect(find.text('بلا مستفيد محدّد'), findsNothing);
    expect(find.text('نوع الموديل'), findsOneWidget);
  });

  testWidgets('the filter button shows and hides the filter bar', (
    tester,
  ) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    expect(find.text('بحث في أسماء الأقمشة…'), findsNothing);

    await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
    await tester.pumpAndSettle();

    expect(find.text('بحث في أسماء الأقمشة…'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.filter_alt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('بحث في أسماء الأقمشة…'), findsNothing);
  });

  testWidgets('a section switch hides that section only', (tester) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    // المقاسات ظاهرة أولاً، ثم تُطفأ بمرشّح الشاشة
    // Measurements show first, then the screen's own switch turns them off.
    expect(find.text('الطول'), findsWidgets);

    await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('المقاسات'));
    await tester.pumpAndSettle();

    expect(find.text('الطول'), findsNothing);
    // الأقسام الباقية لم تمسّها المرشّحات — إخفاء قسم لا يخفي غيره
    // The other sections are untouched: hiding one never hides another.
    expect(find.textContaining('الأقمشة'), findsWidgets);
  });

  testWidgets('the fabric search narrows the pieces without another request', (
    tester,
  ) async {
    final repo = _FakeRepo(subject: _subject());
    await _pump(tester, repo);

    await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'قماش صيفي');
    await tester.pumpAndSettle();

    // الفراغ بين الكلمتين يبقى في الحقل: ضبط الحقل على القيمة المقطوغة كان سيأكله
    // The space between the words survives: re-syncing the field to the trimmed value would
    // have eaten it on the very next keystroke.
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller!.text, 'قماش صيفي');

    expect(find.text('قماش صيفي'), findsWidgets);
    expect(find.text('قماش شتوي'), findsNothing);
    // لم تُطلب بيانات جديدة: المرشّح محلي بالكامل
    // No new request: the filter is entirely local.
    expect(repo.askedKey, _key);
  });

  testWidgets('picking a sibling model asks for its own four-part key', (
    tester,
  ) async {
    final repo = _FakeRepo(subject: _subject());
    await _pump(tester, repo);

    await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
    await tester.pumpAndSettle();

    // الشريحة تُلتقط بنوعها: «سالم» يظهر أيضاً كخياط في الأقمشة، والعامّ يطابق اثنين
    // The chip is picked by type: "سالم" is also a tailor name in the fabrics, so a bare text
    // finder would match two widgets.
    await tester.tap(find.widgetWithText(ChoiceChip, 'سالم'));
    await tester.pumpAndSettle();

    // المفتاح الجديد يحتفظ بالعميل والفاتورة ويغيّر رقم الموديل فقط
    // The new key keeps the customer and the bill and changes only the model number.
    expect(repo.askedKey, const MeasurementKey(custNo: 40, billNo: 35, year: 2023, seqNo: 49));
  });

  testWidgets('print and export buttons require their own grants', (
    tester,
  ) async {
    // بلا منح: الزران يختفيان تمامًا — الزر المعطّل يُعلن وجود شيء محجوب
    // Without the grants both buttons are gone: a disabled button advertises what is denied.
    await _pump(
      tester,
      _FakeRepo(subject: _subject()),
      grants: const [Perm.customersMeasurementsView],
    );

    expect(find.byIcon(Icons.print_rounded), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNothing);
    // العرض نفسه لا يحتاج منحًا إضافية: الشاشة تُرسم
    // Viewing needs no extra grant: the screen still renders.
    expect(find.text('الطول'), findsWidgets);
  });

  testWidgets('the print grant shows only the print button', (tester) async {
    await _pump(
      tester,
      _FakeRepo(subject: _subject()),
      grants: const [
        Perm.customersMeasurementsView,
        Perm.customersMeasurementsPrint,
      ],
    );

    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsNothing);
  });

  testWidgets('an admin sees both print and export', (tester) async {
    await _pump(tester, _FakeRepo(subject: _subject()));

    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
  });

  testWidgets('a bill with no model says so instead of failing', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeRepo(
        subject: MeasurementSubject.fromJson(
          const {'header': {'bill_no': 1, 'year': 2023}},
          custNo: 40,
        ),
      ),
    );

    expect(find.text('لا مقاسات لهذا الموديل'), findsOneWidget);
  });

  testWidgets('a model outside the view is explained, not called an error', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeRepo(
        error: const MeasurementException(
          'الموديل غير موجود',
          notFoundInView: true,
        ),
      ),
    );

    expect(find.text('الموديل غير متاح للعرض'), findsOneWidget);
    expect(find.textContaining('لا يعود لهذا العميل'), findsOneWidget);
    expect(find.byIcon(Icons.playlist_remove_rounded), findsOneWidget);
  });

  testWidgets('a network failure offers a retry that reloads', (tester) async {
    final repo = _FakeRepo(
      error: const MeasurementException('تعذّر الوصول إلى الخادم'),
    );
    await _pump(tester, repo);

    expect(find.text('تعذّر تحميل المقاسات'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    // المحاولة تُعيد نفس المفتاح الرباعي لا رقماً مجرّداً
    // The retry asks with the same four-part key, never a bare number.
    expect(repo.askedKey, _key);
  });

  testWidgets('the loading state waits for the bundle', (tester) async {
    final gate = Completer<void>();
    final repo = _FakeRepo(gate: gate, subject: _subject());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(() => _StubAuthNotifier(_adminState())),
          customerMeasurementRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: MeasurementViewScreen(modelKey: _key),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('جارٍ تحميل المقاسات...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('جارٍ تحميل المقاسات...'), findsNothing);
  });
}
