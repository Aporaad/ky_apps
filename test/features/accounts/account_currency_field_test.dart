import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/data/models/tree_export_row_model.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:ky_apps/features/accounts/presentation/screens/create_account_screen.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';

/// حقل العملة في نموذج الإنشاء: قائمة عملات جاهزة، لا رقم يُكتب باليد.
/// The account form used to ask for a raw `CUR_NO`. Staff had to memorise the id and
/// got no confirmation that it exists, so a typo became either a nonexistent currency
/// or a silently different one. The field is now a picker over `/accounts/currencies`,
/// and it renders only for the two tables that actually store the column.

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final AuthState _initial;
  @override
  AuthState build() => _initial;
}

AuthState _signedIn() =>
    AuthState(isAuthenticated: true, isAdmin: false).withPermissions(
      PermissionSnapshot(
        userId: 2,
        isAdmin: false,
        permissions: const ['accounts.view', 'accounts.create'],
      ),
    );

class _FakeFormRepo extends AccountRepository {
  _FakeFormRepo({this.currencies = const [], this.currenciesFail = false})
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  final List<CurrencyOptionModel> currencies;
  final bool currenciesFail;

  int currencyCalls = 0;

  @override
  Future<List<AccountModel>> fetchAccounts({CancelToken? cancelToken}) async {
    await Future<void>.delayed(Duration.zero);
    return const [AccountModel(accNo: 1, accName: 'الأصول')];
  }

  @override
  Future<List<AccMainModel>> fetchAccMain({
    int? accNo,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return const [AccMainModel(accNo: 1, accSub: 11, subName: 'النقدية')];
  }

  @override
  Future<List<AccSubModel>> fetchAccSub({
    int? accSub,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    // curNo هنا هو ACC_SUB.CUR_NO — العملة التي تُورَّث للحساب المالي تحت هذا الجزئي.
    return const [
      AccSubModel(accSub: 11, accPart: 110, partName: 'الصندوق', curNo: 2),
    ];
  }

  @override
  Future<List<AccSubGroupModel>> fetchAccSubGroup({
    int? accPart,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    return const [AccSubGroupModel(groupId: 5, accPart: 110, accGroupName: 'الأمانة')];
  }

  @override
  Future<int?> fetchNextNumber({
    required String level,
    int? groupId,
    int? accPart,
    int? accSub,
    int? accNo,
    int? curNo,
    CancelToken? cancelToken,
  }) async {
    await Future<void>.delayed(Duration.zero);
    // رقم مطابق للقاعدة: الجزء 110 + العملة (الخانة الرابعة) + تسلسل 0001.
    return 11000000 + (curNo ?? 0) * 10000 + 1;
  }

  @override
  Future<List<TreeExportRow>> fetchTreeExport(
    TreeExportScope scope, {
    CancelToken? cancelToken,
  }) async => const [];

  @override
  Future<List<CurrencyOptionModel>> fetchCurrencyOptions({
    CancelToken? cancelToken,
  }) async {
    currencyCalls++;
    await Future<void>.delayed(Duration.zero);
    if (currenciesFail) throw Exception('offline');
    return currencies;
  }
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required AccountCreateKind kind,
  required AccountRepository repo,
  int? accNo,
  int? accSub,
  int? accPart,
}) async {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      // Riverpod 3 يعيد تلقائياً محاولة FutureProvider فاشل بعشرة backoff
      // متصاعدة (200ms→6.4s): مضخة الأطر تستهلكها كلها فيصبح الدليل 11 طلباً.
      // الطلبات هنا تُقاس لا تُختبر، فتُوقف إعادة المحاولة لتبقى القراءة واضحة.
      // Retries are Riverpod's own behaviour, not what these tests measure.
      retry: (_, _) => null,
      overrides: [
        authNotifierProvider.overrideWith(() => _StubAuthNotifier(_signedIn())),
        accountRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: CreateAccountScreen(
          initialKind: kind,
          initialAccNo: accNo,
          initialAccSub: accSub,
          initialAccPart: accPart,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// قائمة العملة المنسدلة — يُبحث عنها بالنوع وببادئة التسمية معاً: التعميم في Dart
/// covariant، فـ `DropdownButtonFormField<int>` (حقول السلسلة الأبوية) يحقق أيضاً
/// `is DropdownButtonFormField<int?>` وكان سيُطابق أربعة حقول. البادئة «العملة» تلتقط
/// التسميتين: «العملة» (فرعي/جزئي) و«العملة * (الخانة الرابعة…)» (مالي).
/// The picker is matched by type AND label prefix: Dart generics are covariant, so a
/// `DropdownButtonFormField<int>` from the parent chain also passes the type test.
final Finder _currencyPicker = find.byWidgetPredicate(
  (w) =>
      w is DropdownButtonFormField<int?> &&
      (w.decoration.labelText?.startsWith('العملة') ?? false),
);

Future<void> _openPicker(WidgetTester tester) async {
  await tester.ensureVisible(_currencyPicker);
  await tester.pumpAndSettle();
  await tester.tap(_currencyPicker);
  await tester.pumpAndSettle();
}

void main() {
  group('currency field', () {
    testWidgets('is a picker over the directory, not a typed number', (tester) async {
      final repo = _FakeFormRepo(
        currencies: const [
          CurrencyOptionModel(curNo: 1, curName: 'يمني'),
          CurrencyOptionModel(curNo: 2, curName: 'دولار'),
        ],
      );
      await _pumpForm(tester, kind: AccountCreateKind.main, repo: repo);

      // التسمية القديمة «رقم العملة» اختفت: لا يُطلب من المستخدم رقم مجهري.
      expect(find.text('رقم العملة'), findsNothing);

      // الحقل صار قائمة منسدلة لا نصًا: قيمته مرقّمة من الدليل، لا ما كُتب على لوحة.
      // لا عملة وهمية عند الفتح: القيمة تبدأ فارغة حتى لو أخطأ الدليل.
      expect(tester.state<FormFieldState<int?>>(_currencyPicker).value, isNull);
      expect(repo.currencyCalls, 1);

      await _openPicker(tester);

      // القائمة نفسها تُعرض عند الفتح، فتكون أرقام الدليل وأسمائه مرئية معاً:
      // «2 — دولار» يُقروء، بعكس «2» وحدها في الحقل النصي القديم.
      // (الحقل المغلق يبني عنصر القيمة المختارة فقط، ولا خلط مع حقول السلسلة
      // الأبوية لأن find.byType مقارنة نوع دقيقة: `DropdownMenuItem<int>`
      // لا يطابق `DropdownMenuItem<int?>`.)
      final options = tester
          .widgetList<DropdownMenuItem<int?>>(
            find.byType(DropdownMenuItem<int?>),
          )
          .map((i) => i.value)
          .toList();
      expect(options, containsAll(<int?>[1, 2, null]));
      expect(find.text('2 — دولار'), findsWidgets);
      expect(find.text('1 — يمني'), findsWidgets);
    });

    testWidgets('the chosen currency is the one that gets sent', (tester) async {
      final repo = _FakeFormRepo(
        currencies: const [
          CurrencyOptionModel(curNo: 2, curName: 'دولار'),
          CurrencyOptionModel(curNo: 3, curName: 'سعودي'),
        ],
      );
      await _pumpForm(tester, kind: AccountCreateKind.sub, repo: repo);

      await _openPicker(tester);
      await tester.tap(find.text('3 — سعودي').last);
      await tester.pumpAndSettle();

      // الاختيار يُقرأ على الحالة نفسها لا على النص: هو ما سيُرسل كـ CUR_NO.
      expect(tester.state<FormFieldState<int?>>(_currencyPicker).value, 3);
    });

    testWidgets('it is optional, and a failed directory does not block the form', (
      tester,
    ) async {
      // الحقل اختياري: فشل دليل العملات كان سيمنع إنشاء حساب لا يحتاجه أصلاً.
      final repo = _FakeFormRepo(currenciesFail: true);
      await _pumpForm(tester, kind: AccountCreateKind.main, repo: repo);

      expect(find.text('تعذّر جلب العملات — انقر للمحاولة ثانية'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(_currencyPicker, findsNothing);
      expect(repo.currencyCalls, 1);
    });

    testWidgets('the retry on the failed field refetches the directory', (tester) async {
      final repo = _FakeFormRepo(currenciesFail: true);
      await _pumpForm(tester, kind: AccountCreateKind.main, repo: repo);
      expect(repo.currencyCalls, 1);

      // إعادة المحاولة اليدوية هي الطريق الوحيد للطلب ثانية بعد تعطّل الدليل.
      await tester.tap(find.text('تعذّر جلب العملات — انقر للمحاولة ثانية'));
      await tester.pumpAndSettle();
      expect(repo.currencyCalls, 2);
    });

    testWidgets('a chart account gets a mandatory currency picker, not an inherited line', (
      tester,
    ) async {
      // قرار المستخدم: لا وراثة — تُختار العملة لكل حساب مالي بشكل مستقل. لا عمود
      // CUR_NO في CHART_ACC بل الخانة الرابعة من الرقم، فالحقل منتقىً لا سطراً وصفيًا.
      final repo = _FakeFormRepo(
        currencies: const [
          CurrencyOptionModel(curNo: 1, curName: 'يمني'),
          CurrencyOptionModel(curNo: 2, curName: 'دولار'),
        ],
      );
      await _pumpForm(tester, kind: AccountCreateKind.chart, repo: repo);

      // منتقي قابل للتعديل موجود، وتسميته تُوضح أنها الخانة الرابعة من الرقم.
      expect(_currencyPicker, findsOneWidget);
      final dropdown = tester.widget<DropdownButtonFormField<int?>>(_currencyPicker);
      expect(dropdown.decoration.labelText, contains('الخانة الرابعة'));

      // إلزامي: لا خيار «بدون عملة» — لا رقم صحيح بلا عملة.
      await _openPicker(tester);
      expect(find.text('بدون عملة'), findsNothing);
      expect(find.text('2 — دولار'), findsWidgets);
      expect(find.text('1 — يمني'), findsWidgets);
    });

    testWidgets('picking a chart currency re-runs the number preview', (tester) async {
      // العملة خانة من الرقم: اختيارها يجب أن يبدّل الرقم المتوقع فوراً.
      final repo = _FakeFormRepo(
        currencies: const [
          CurrencyOptionModel(curNo: 1, curName: 'يمني'),
          CurrencyOptionModel(curNo: 2, curName: 'دولار'),
        ],
      );
      await _pumpForm(
        tester,
        kind: AccountCreateKind.chart,
        repo: repo,
        accNo: 1,
        accSub: 11,
        accPart: 110,
      );

      // تفعيل «مباشر تحت الجزئي» حتى تكتمل بوابة المعاينة بلا حاجة لمجموعة.
      await tester.tap(find.text('حساب مباشر تحت الجزئي (بلا مجموعة)'));
      await tester.pumpAndSettle();

      // قبل اختيار العملة: لا رقم (البوابة تُبقي المعاينة فارغة).
      expect(find.text('الرقم المتوقع: '), findsOneWidget);
      expect(find.text('—'), findsWidgets);

      await _openPicker(tester);
      await tester.tap(find.text('2 — دولار').last);
      await tester.pumpAndSettle();

      // بعد الاختيار: 110|2|0001 = 11020001 يظهر في الشريط.
      expect(find.text('11020001'), findsOneWidget);
    });

    testWidgets('a group shows where its currency comes from — no picker, no column', (
      tester,
    ) async {
      // المجموعة وحدها لا رقم لها يُرمَّز فيها ولا عمود يخزّنها، فعملتها فعلاً عن
      // الجزئي صاحبها — تُعرض كمعلومة لا كحقل يُملأ، دون أن توحي بأنها قابلة للتغيير.
      await _pumpForm(tester, kind: AccountCreateKind.group, repo: _FakeFormRepo());
      expect(find.text('العملة (عن الحساب الجزئي صاحب المجموعة)'), findsOneWidget);
      expect(_currencyPicker, findsNothing);
    });
  });
}
