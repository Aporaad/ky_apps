import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/customers/data/models/measurement_customer_model.dart';
import 'package:ky_apps/features/customers/data/models/measurement_model_ref.dart';
import 'package:ky_apps/features/customers/data/repositories/customer_measurement_repository.dart';
import 'package:ky_apps/features/customers/presentation/providers/customer_measurement_providers.dart';
import 'package:ky_apps/features/customers/presentation/screens/measurement_view_screen.dart';
import 'package:ky_apps/features/customers/presentation/screens/measurements_customers_screen.dart';
import 'package:ky_apps/features/customers/presentation/widgets/measurement_model_picker_sheet.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_detail_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_model_item.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_piece_item.dart';

/// لقطات بصرية لمقاسات العملاء بخط عربي حقيقي — أداة مراجعة، لا اختبار انحدار
/// Visual snapshots of the customer-measurements screens with a real Arabic font — a review tool,
/// not a regression test.
///
/// تُشغَّل فقط عند الطلب صراحةً:
/// `KY_VISUAL=1 flutter test --update-goldens test/features/customers/measurements_visual_test.dart`
/// السبب نفسه الذي عند `home_visual_test.dart`: مقارنة البكسل تعتمد على خط النظام ونظام
/// التشغيل، وتفعيلها في كل بناء يكسر المجموعة على جهاز آخر بلا سبب.
/// Run only on demand, for the same reason as home_visual_test.dart: pixel comparison depends on
/// the system font and OS, and enabling it in every build would break the suite elsewhere for no
/// reason.
///
/// الغرض هنا تحديدًا: الطلب الثاني على هذه الشاشة كان «التصميم مرفوض والألوان باهتة»، وهو حكم
/// بصري لا تثبته `find.text`. الصور في `test/goldens/` تُفحص بالعين قبل أي ادعاء.
/// The point here is specific: the complaint on this screen was "the design is rejected and the
/// colours are faded", which is a visual verdict that `find.text` cannot prove. The images under
/// test/goldens/ get looked at before anything is claimed.

/// اللقطات عند `KY_VISUAL=1` فقط / snapshots run only with KY_VISUAL=1.
final bool _visual = Platform.environment['KY_VISUAL'] == '1';

class _StubAuth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true).withPermissions(
        const PermissionSnapshot(userId: 1, isAdmin: true, permissions: <String>[]),
      );
}

/// بيانات بشبه حقيقية: أسماء عربية، مقاسات مسماة، وأقمشة بمسؤولين مختلفين لكل قطعة
/// Near-real data: Arabic names, labelled measurements, and fabrics whose assignee changes per
/// piece — the exact shape the redesigned sections have to hold.
class _FakeRepo extends CustomerMeasurementRepository {
  _FakeRepo()
    : super(
        client: DioClient(
          storage: SecureStorageService(),
          baseUrl: 'http://127.0.0.1',
        ),
      );

  @override
  Future<MeasurementCustomerPage> fetchCustomers({
    String search = '',
    String sort = 'date_desc',
    int page = 1,
    int limit = 30,
    CancelToken? cancelToken,
  }) async {
    return MeasurementCustomerPage(
      items: const [
        MeasurementCustomer(
          custNo: 40,
          custName: 'تراب الصغير',
          telNo1: '777123456',
          accNo: 12310039,
          billsCount: 12,
          modelsCount: 31,
          lastDate: '09/02/2026',
        ),
        MeasurementCustomer(
          custNo: 118,
          custName: 'محمد صالح الشوعي',
          telNo1: '733445566',
          accNo: 12310118,
          billsCount: 4,
          modelsCount: 7,
          lastDate: '02/02/2026',
        ),
        MeasurementCustomer(
          custNo: 240,
          custName: 'سالم بن ناصر',
          accNo: 12310240,
          billsCount: 2,
          modelsCount: 2,
          lastDate: '28/01/2026',
        ),
      ],
      total: 9007,
      page: 1,
      pages: 301,
      limit: 30,
    );
  }

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
    return MeasurementModelsPage(
      items: const [
        MeasurementModelRef(
          billNo: 19405,
          year: 2026,
          seqNo: 82755,
          beneficiary: 'أحمد الصغير',
          typeName: 'قصيري',
          piecesCount: 3,
          cuttingDone: true,
          tailorDone: true,
          date: '09/02/2026',
        ),
        MeasurementModelRef(
          billNo: 19312,
          year: 2026,
          seqNo: 82741,
          typeName: 'حجازي',
          piecesCount: 1,
          cuttingDone: true,
          date: '27/01/2026',
        ),
        MeasurementModelRef(
          billNo: 18120,
          year: 2025,
          seqNo: 76033,
          beneficiary: 'عبد الله الصغير',
          typeName: 'عماني',
          piecesCount: 2,
          cuttingDone: true,
          tailorDone: true,
          handingDone: true,
          date: '14/09/2025',
        ),
      ],
      total: 31,
      page: 1,
      pages: 2,
      limit: 30,
    );
  }

  @override
  Future<MeasurementSubject> fetchModel(
    MeasurementKey key, {
    CancelToken? cancelToken,
  }) async {
    return MeasurementSubject(
      custNo: key.custNo,
      detail: CuttingBillDetail(
        header: const CuttingBillHeader(
          billNo: 19405,
          year: 2026,
          manualBillNo: 4412,
          date: '09/02/2026',
          custNo: 40,
          custName: 'تراب الصغير',
          telNo1: '777123456',
          accNo: 12310039,
          givingDate: '16/02/2026',
          ordsName: 'قيد الخياطة',
        ),
        models: const [
          CuttingModelItem(
            seqNo: 82755,
            beneficiary: 'أحمد الصغير',
            typeName: 'قصيري',
            qty: 3,
            measurements: {
              'L1': 58,
              'L2': 17,
              'L3': 24,
              'L4': 15,
              'L5': 19,
              'L6': 9.5,
              'L7': 6,
              'L8': 28,
              'L9': 42,
              'L10': 26.5,
            },
            specs: CuttingModelSpecs(
              neckType: 'مربع',
              tipperType: 'عادي',
              comCabakType: 'كباب',
              pocketOrWithout: 'جيوب شمال',
              gabzorType: 'عادي',
              buttonType: 'كباس',
              buttonNo: '8',
              mobilePocket: 'عادي',
              notes: 'تسليم بعد الأسبوع الثاني — بدون حزام',
            ),
            pieces: [
              CuttingPieceItem(
                seqNo1: 1,
                ohdId: 26211325025,
                clothName: 'قماش جودة ع58',
                clothType: 'عرضية',
                colorText: 'أبيض',
                hinsh: 42,
                yards: 1.17,
                cutterName: 'صالح مجيب الشمری',
                tailorName: 'أحمد عبد العزيز شرهان',
                cuttingDone: true,
                tailorDone: true,
                price: 2000,
              ),
              CuttingPieceItem(
                seqNo1: 2,
                ohdId: 26211325053,
                clothName: 'قماش جودة ع58',
                clothType: 'عرضية',
                colorText: 'كحلي',
                hinsh: 42,
                yards: 1.17,
                cutterName: 'صالح مجيب الشمری',
                tailorName: 'مازن ميثاق الصبري',
                cuttingDone: true,
                price: 2000,
              ),
              CuttingPieceItem(
                seqNo1: 3,
                ohdId: 26211325012,
                clothName: 'قماش صيفي خفيف',
                clothType: 'عرض',
                colorText: 'بيج',
                hinsh: 36,
                yards: 1.02,
                cutterName: 'صالح مجيب الشمری',
                cuttingDone: true,
                price: 1750,
              ),
            ],
          ),
        ],
        measureLabels: const {
          'L1': 'الطول',
          'L2': 'الكتف',
          'L3': 'طول اليد',
          'L4': 'الرقبة',
          'L5': 'العرض',
          'L6': 'تنزيلة اليد',
          'L7': 'وسط اليد',
          'L8': 'الخصرة',
          'L9': 'طول الجبزور',
          'L10': 'طول الكبك',
        },
      ),
      siblings: const [
        MeasurementSibling(
          seqNo: 82755,
          beneficiary: 'أحمد الصغير',
          typeName: 'قصيري',
          piecesCount: 3,
          selected: true,
        ),
        MeasurementSibling(
          seqNo: 82756,
          beneficiary: 'صغير البيت',
          typeName: 'قصيري',
          piecesCount: 1,
        ),
      ],
    );
  }

  @override
  Future<bool> recordActivity(
    MeasurementKey key, {
    required String action,
  }) async => true;
}

Future<void> _loadArabicFont() async {
  final file = File('C:\\Windows\\Fonts\\tahoma.ttf');
  if (!file.existsSync()) return;

  final bytes = await file.readAsBytes();
  final loader = FontLoader('Tahoma')
    ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget child,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_StubAuth.new),
        customerMeasurementRepositoryProvider.overrideWithValue(_FakeRepo()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Tahoma',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7C2D12),
            primary: const Color(0xFF7C2D12),
            secondary: const Color(0xFF0D9488),
          ),
        ),
        home: Scaffold(backgroundColor: const Color(0xFFF8FAFC), body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _key = MeasurementKey(custNo: 40, billNo: 19405, year: 2026, seqNo: 82755);

void main() {
  setUpAll(_loadArabicFont);

  testWidgets('customers list — desktop', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(1280, 900),
      const MeasurementsCustomersScreen(),
    );

    await expectLater(
      find.byType(MeasurementsCustomersScreen),
      matchesGoldenFile('../../goldens/measurements_customers_desktop.png'),
    );
  });

  testWidgets('customers list — phone', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const MeasurementsCustomersScreen(),
    );

    await expectLater(
      find.byType(MeasurementsCustomersScreen),
      matchesGoldenFile('../../goldens/measurements_customers_phone.png'),
    );
  });

  testWidgets('model picker sheet — phone', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const MeasurementModelPickerSheet(
        custNo: 40,
        custName: 'تراب الصغير',
        telNo1: '777123456',
      ),
    );

    await expectLater(
      find.byType(MeasurementModelPickerSheet),
      matchesGoldenFile('../../goldens/measurements_model_picker.png'),
    );
  });

  // الطول يترك كل الأقسام ظاهرة دفعة واحدة: ما يُراجع بالعين هو الترتيب والتباين لا الزر
  // The tall surface leaves every section visible at once: what is being judged is order and
  // contrast, not a button.
  testWidgets('measurements view — desktop', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(1280, 1100),
      const MeasurementViewScreen(modelKey: _key, custName: 'تراب الصغير'),
    );

    await expectLater(
      find.byType(MeasurementViewScreen),
      matchesGoldenFile('../../goldens/measurements_view_desktop.png'),
    );
  });

  testWidgets('measurements view — phone full height', skip: !_visual, (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(390, 2200),
      const MeasurementViewScreen(modelKey: _key, custName: 'تراب الصغير'),
    );

    await expectLater(
      find.byType(MeasurementViewScreen),
      matchesGoldenFile('../../goldens/measurements_view_phone.png'),
    );
  });
}
