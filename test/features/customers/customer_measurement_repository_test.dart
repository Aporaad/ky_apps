import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/customers/data/models/measurement_model_ref.dart';
import 'package:ky_apps/features/customers/data/repositories/customer_measurement_repository.dart';

/// مستودع مقاسات العملاء على عميل Dio وهمي — نفس نمط مستودع قسم التفصيل
/// The measurements repository over a fake Dio client — the tailoring repository's own pattern.
///
/// المحروس هنا: المسارات رباعية المفتاح، ومعاملات البحث والترتيب والنطاق الزمني بصيغتها التي
/// يفهمها الخادم، ومغلّف `success`، وتمييز 404 «خارج الواجهة» عن خطأ رابط، وأن التسجيل لا
/// يُفشل الطباعة.
/// Guarded: the four-part paths, the search/sort/date parameters in the form the server reads, the
/// `success` envelope, 404-"outside the view" told apart from a bad URL, and auditing never
/// failing a print.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body, {this.status = 200});

  final Object body;
  final int status;

  RequestOptions? captured;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    calls++;

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

CustomerMeasurementRepository _repo(_CapturingAdapter adapter) {
  final client = DioClient(
    storage: SecureStorageService(),
    baseUrl: 'http://127.0.0.1',
  );
  // المعترضات تُزال كي لا يلمس `AuthInterceptor` التخزين الآمن في بيئة الاختبار.
  // Interceptors are cleared so AuthInterceptor never touches secure storage here.
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = adapter;

  return CustomerMeasurementRepository(client: client);
}

/// صفحة عملاء بأرقام نصوصاً كما ترسلها أوراكل عبر الخادم
/// A customer page with numbers as text, as Oracle sends them through the server.
Map<String, dynamic> _customersBody() => const <String, dynamic>{
  'success': true,
  'message': 'ok',
  'data': [
    {
      'cust_no': '40',
      'cust_name': 'تراب الصغير',
      'tel_no1': '777123456',
      'acc_no': '12310039',
      'bills_count': '12',
      'models_count': '31',
      'last_date': '09/02/2023',
      'raw_last_date': '2023-02-09',
    },
  ],
  'meta': {'total': '9007', 'page': '1', 'limit': '30', 'pages': '301'},
};

void main() {
  group('fetchCustomers', () {
    test('calls the measurement path and parses the paging envelope', () async {
      final adapter = _CapturingAdapter(_customersBody());
      final page = await _repo(adapter).fetchCustomers();

      expect(adapter.captured!.path, '/customers/measurements');
      expect(page.total, 9007);
      expect(page.page, 1);
      expect(page.pages, 301);
      expect(page.hasMore, isTrue);
      expect(page.items.single.custNo, 40);
      expect(page.items.single.modelsCount, 31);
    });

    test('sends search and sort, and drops an empty search entirely', () async {
      final adapter = _CapturingAdapter(_customersBody());
      await _repo(adapter).fetchCustomers(search: '  خالد ', sort: 'name_asc');

      expect(adapter.captured!.queryParameters['search'], 'خالد');
      expect(adapter.captured!.queryParameters['sort'], 'name_asc');

      await _repo(adapter).fetchCustomers(search: '   ');
      expect(adapter.captured!.queryParameters.containsKey('search'), isFalse);
    });

    test('a failed envelope becomes a readable error, not an empty list', () async {
      final adapter = _CapturingAdapter(
        const {'success': false, 'message': 'انتهت الجلسة'},
      );

      expect(
        _repo(adapter).fetchCustomers(),
        throwsA(
          isA<MeasurementException>().having(
            (e) => e.displayMessage,
            'message',
            'انتهت الجلسة',
          ),
        ),
      );
    });
  });

  group('fetchModels', () {
    test('scopes the path to the customer and formats dates as ISO', () async {
      final adapter = _CapturingAdapter(const <String, dynamic>{
        'success': true,
        'data': [
          {'bill_no': '35', 'year': '2023', 'seq_no': '48', 'pieces_count': '3'},
        ],
        'meta': {'total': 1, 'page': 1, 'limit': 30, 'pages': 1},
      });

      final page = await _repo(adapter).fetchModels(
        custNo: 40,
        fromDate: DateTime(2023, 2, 1),
        toDate: DateTime(2023, 2, 28),
      );

      expect(adapter.captured!.path, '/customers/measurements/40/models');
      expect(adapter.captured!.queryParameters['from_date'], '2023-02-01');
      expect(adapter.captured!.queryParameters['to_date'], '2023-02-28');
      expect(page.items.single.seqNo, 48);
      expect(page.hasMore, isFalse);
    });
  });

  group('fetchModel', () {
    const key = MeasurementKey(custNo: 40, billNo: 35, year: 2023, seqNo: 48);

    test('builds the subject and keeps the requested customer as owner', () async {
      final adapter = _CapturingAdapter(const <String, dynamic>{
        'success': true,
        'data': {
          'header': {'bill_no': 35, 'year': 2023, 'cust_no': 40},
          'models': [
            {'seq_no': 48, 'measurements': {'L1': 58}},
          ],
          'measure_labels': {'L1': 'الطول'},
          'siblings': [
            {'seq_no': 48, 'selected': true},
          ],
        },
      });

      final subject = await _repo(adapter).fetchModel(key);

      expect(
        adapter.captured!.path,
        '/customers/measurements/40/models/35/2023/48',
      );
      expect(subject.custNo, 40);
      expect(subject.model?.measurements['L1'], 58);
      expect(subject.siblings.single.selected, isTrue);
    });

    test('a 404 is read as "outside the view", not as a broken link', () async {
      // bills لا تظهر في الواجهة ليست أخطاء مسار: الحالة تُشرح لا تُرمى
      // Bills outside the view are not routing errors: the state is explained, not thrown.
      final adapter = _CapturingAdapter(
        const <String, dynamic>{
          'success': false,
          'message': 'الموديل غير موجود',
          'not_found_in_view': true,
        },
        status: 404,
      );

      await expectLater(
        _repo(adapter).fetchModel(key),
        throwsA(
          isA<MeasurementException>()
              .having((e) => e.notFoundInView, 'notFoundInView', isTrue)
              .having((e) => e.displayMessage, 'message', 'الموديل غير موجود'),
        ),
      );
    });

    test('a cancelled request is rethrown, never swallowed into data', () async {
      final adapter = _CapturingAdapter(_customersBody());
      final repo = _repo(adapter);
      final token = CancelToken();
      token.cancel('screen closed');

      await expectLater(
        repo.fetchModel(key, cancelToken: token),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('recordActivity', () {
    test('posts the action to the audit path', () async {
      final adapter = _CapturingAdapter(
        const {'success': true, 'message': 'ok'},
      );

      final ok = await _repo(adapter).recordActivity(
        const MeasurementKey(custNo: 40, billNo: 35, year: 2023, seqNo: 48),
        action: 'print',
      );

      expect(ok, isTrue);
      expect(
        adapter.captured!.path,
        '/customers/measurements/40/models/35/2023/48/activity',
      );
      // `options.data` خريطة قبل التحويل: المقارنة بالمحتوى لا بنوع النقل
      // options.data is still the map at adapter level, so the assertion is on content.
      expect(adapter.captured!.data, <String, String>{'action': 'print'});
    });

    test('an audit failure returns false and never throws at the caller', () async {
      // التدقيق لا يُفشل الطباعة: الخطأ صامت بقيمة منطقية
      // Auditing never fails the print: the failure is silent but answerable.
      final adapter = _CapturingAdapter(
        const {'success': false, 'message': 'nope'},
        status: 500,
      );

      final ok = await _repo(adapter).recordActivity(
        const MeasurementKey(custNo: 1, billNo: 1, year: 2026, seqNo: 1),
        action: 'export',
      );

      expect(ok, isFalse);
    });
  });
}
