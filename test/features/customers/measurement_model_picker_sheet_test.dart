import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/customers/data/models/measurement_model_ref.dart';
import 'package:ky_apps/features/customers/data/repositories/customer_measurement_repository.dart';
import 'package:ky_apps/features/customers/presentation/providers/customer_measurement_providers.dart';
import 'package:ky_apps/features/customers/presentation/widgets/measurement_model_picker_sheet.dart';

/// نافذة اختيار الموديل — منبثقة لا شاشة ثابتة
/// The model picker — a popup sheet, not a pushed screen.
///
/// المحروس: النافذة تُفتح من شاشة العملاء وتُغلق بالاختيار مع إعادة الموديل كاملاً بمفتاحه
/// الرباعي، وأن الأزرار والمحتوى يعملان بلا شبكة (المستودع وهمي)، وأن الحالة الفارغة تقول
/// سببها بدل أن تصمت.
/// Guarded: the sheet opens over the customer list and closes on a choice, returning the whole
/// model with its four-part key; it works with no network (a fake repository); and the empty
/// state says why instead of staying silent.
class _FakeRepo extends CustomerMeasurementRepository {
  _FakeRepo({this.items = const [], this.total = 0})
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  final List<MeasurementModelRef> items;
  final int total;

  /// كل ما طلبته النافذة من الخادم — للتحقق أن البحث والترتيب يذهبان فعلاً
  /// Everything the sheet asked the server for — to assert search and sort really travel.
  final List<String> requests = [];

  @override
  Future<MeasurementModelsPage> fetchModels({
    required int custNo,
    String search = '',
    DateTime? fromDate,
    DateTime? toDate,
    String sort = 'date_desc',
    int page = 1,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    requests.add('$custNo|$search|$sort|$page');

    return MeasurementModelsPage(
      items: items,
      total: total == 0 ? items.length : total,
      page: page,
      pages: 1,
      limit: limit,
    );
  }
}

MeasurementModelRef _model({int seqNo = 48, String? beneficiary = 'أحمد'}) {
  return MeasurementModelRef.fromJson({
    'bill_no': 35,
    'year': 2023,
    'seq_no': seqNo,
    'beneficiary': beneficiary,
    'type_name': 'قصيري',
    'pieces_count': 3,
    'date': '09/02/2023',
    'raw_date': '2023-02-09',
    'cutting_done': 1,
    'tailor_done': 1,
    'handing_done': 0,
  });
}

/// مضيف يفتح النافذة ويعرض نتيجة الاختيار — به يُقاس «النافذة تُرجع القيمة»
/// A host that opens the sheet and shows what came back — that is how "the sheet returns a
/// value" is measured, rather than assumed.
Future<void> _pumpHost(
  WidgetTester tester,
  _FakeRepo repo,
) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerMeasurementRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: const Locale('ar'),
        home: const _HostScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _HostScreen extends StatefulWidget {
  const _HostScreen();

  @override
  State<_HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<_HostScreen> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                final chosen = await MeasurementModelPickerSheet.show(
                  context,
                  custNo: 40,
                  custName: 'تراب الصغير',
                  telNo1: '777123456',
                );

                if (chosen != null && mounted) {
                  setState(() => _picked = chosen.keyOf(40).id);
                }
              },
              child: const Text('اختيار موديل'),
            ),
            if (_picked != null) Text('مفتاح مختار: $_picked'),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('the picker opens as a popup and lists the customer models', (
    tester,
  ) async {
    final repo = _FakeRepo(
      items: [_model(), _model(seqNo: 49, beneficiary: 'سالم')],
      total: 2,
    );
    await _pumpHost(tester, repo);

    expect(find.text('موديلات تراب الصغير'), findsNothing);

    await tester.tap(find.text('اختيار موديل'));
    await tester.pumpAndSettle();

    // منبثقة: لا AppBar ولا شاشة في سجل التنقل — الظهور فوق المستضيف نفسه
    // A popup: no AppBar and no pushed route — it paints over the host itself.
    expect(find.text('موديلات تراب الصغير'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('أحمد'), findsOneWidget);
    expect(find.text('سالم'), findsOneWidget);
    expect(find.textContaining('2 موديل مسجّل'), findsOneWidget);

    // الطلب ذهب بمفتاح العميل وترتيبه الافتراضي: لا قائمة تُعرض بالظن
    // The request carried the customer and the default sort: a list is never shown on a guess.
    expect(repo.requests, ['40||date_desc|1']);
  });

  testWidgets('choosing a model closes the sheet and returns its composite key', (
    tester,
  ) async {
    final repo = _FakeRepo(items: [_model(seqNo: 49, beneficiary: 'سالم')]);
    await _pumpHost(tester, repo);

    await tester.tap(find.text('اختيار موديل'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('سالم'));
    await tester.pumpAndSettle();

    // النافذة أُغلقت والمفتاح رباعي: عميل/فاتورة/سنة/موديل
    // The sheet is gone and the key is four-part: customer/bill/year/model.
    expect(find.text('سالم'), findsNothing);
    expect(find.text('مفتاح مختار: 40/35/2023/49'), findsOneWidget);
  });

  testWidgets('search and sort are sent to the server, not filtered locally', (
    tester,
  ) async {
    final repo = _FakeRepo(items: [_model()]);
    await _pumpHost(tester, repo);

    await tester.tap(find.text('اختيار موديل'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'خالد');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repo.requests.last, '40|خالد|date_desc|1');

    await tester.tap(find.text('الأحدث أولاً'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المستفيد (أ - ي)'));
    await tester.pumpAndSettle();

    expect(repo.requests.last, '40|خالد|beneficiary_asc|1');
  });

  testWidgets('a model with no beneficiary is titled with the customer name', (
    tester,
  ) async {
    // 18,846 صفاً من 45,313 بلا مستفيد: القائمة تعرض اسم العميل نفسه، لا خانة اعتذار
    // 18,846 of 45,313 rows carry no beneficiary: the list shows the customer's own name, not
    // an apology where the title should be.
    await _pumpHost(tester, _FakeRepo(items: [_model(beneficiary: null)]));
    await tester.tap(find.text('اختيار موديل'));
    await tester.pumpAndSettle();

    expect(find.text('تراب الصغير'), findsWidgets);
    expect(find.textContaining('بلا مستفيد'), findsNothing);
  });

  testWidgets('an empty customer says so in the sheet itself', (tester) async {
    await _pumpHost(tester, _FakeRepo());
    await tester.tap(find.text('اختيار موديل'));
    await tester.pumpAndSettle();

    expect(
      find.text('لا موديلات مسجّلة لهذا العميل في بيانات التفصيل'),
      findsOneWidget,
    );
  });
}
