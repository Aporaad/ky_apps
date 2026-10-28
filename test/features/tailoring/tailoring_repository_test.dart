import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/tailoring/data/repositories/tailoring_repository.dart';

/// مستودع قسم التفصيل على عميل Dio وهمي — الشكل نفسه المستخدم في كشف الحساب
/// The tailoring repository over a fake Dio client — the same shape used by the statement repo.
///
/// المحمي هنا: هوية الفاتورة المركّبة، والفلترة الزمنية، وحجب خانات المال القادم من الخادم.
/// Guarded here: the composite bill identity, the date range and the server-side payment block.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body, {this.status = 200});

  final Object body;
  final int status;

  /// آخر طلب وصل — ندقّق مساره ومعاملاته
  /// The last request seen — its path and parameters are what we assert on.
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

TailoringRepository _repo(_CapturingAdapter adapter) {
  final client = DioClient(
    storage: SecureStorageService(),
    baseUrl: 'http://127.0.0.1',
  );
  // نمسح المعترضات كي لا يلمس `AuthInterceptor` التخزين الآمن في بيئة الاختبار.
  // Interceptors are cleared so AuthInterceptor never touches secure storage here.
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = adapter;
  return TailoringRepository(client: client);
}

/// صفحة واحدة من الخادم: صفّان مع بيانات تصفح نصوصاً كما تصل من أوراكل
/// One server page: two rows plus paging metadata as strings, exactly as Oracle sends it.
Map<String, dynamic> _listBody() => {
      'success': true,
      'message': 'ok',
      'data': [
        {
          'BILL_NO': '12345',
          'YEAR': '2026',
          'MANUAL_BILL_NO': '778',
          'DATE': '11/03/2026',
          'CUST_NAME': 'محمد',
          'TEL_NO1': '777123456',
          'MODELS_COUNT': '2',
          'PIECES_COUNT': '3',
          'NET': '1500',
          'ORDSDID': '3',
        },
        {
          'BILL_NO': '12344',
          'YEAR': '2026',
          'CUST_NAME': 'سالم',
          'MODELS_COUNT': '1',
          'PIECES_COUNT': '1',
          'NET': '400',
        },
      ],
      'meta': {'total': '42', 'page': '1', 'limit': '20', 'pages': '3'},
    };

void main() {
  // ================================================================
  // قائمة الفواتير
  // ================================================================
  group('TailoringRepository.fetchBills', () {
    test('sends the search, the period and the paging', () async {
      final adapter = _CapturingAdapter(_listBody());
      final page = await _repo(adapter).fetchBills(
        search: '  محمد  ',
        fromDate: DateTime(2026, 3, 1),
        toDate: DateTime(2026, 3, 31),
        page: 2,
        limit: 20,
      );

      final options = adapter.captured!;
      final params = options.queryParameters;

      expect(options.path, '/tailoring/bills');
      // الفترة بصيغة YYYY-MM-DD التي يقبلها الخادم
      expect(params['search'], 'محمد');
      expect(params['from_date'], '2026-03-01');
      expect(params['to_date'], '2026-03-31');
      expect(params['page'], 2);
      expect(params['limit'], 20);

      expect(page.items, hasLength(2));
      expect(page.items.first.billNo, 12345);
      expect(page.items.first.referenceLabel, '12345 / 2026');
      // بيانات التصفح النصية تُقرأ أرقاماً
      expect(page.total, 42);
      expect(page.pages, 3);
      expect(page.hasMore, isTrue);
    });

    test('an empty search and no period send no unused parameters', () async {
      final adapter = _CapturingAdapter(_listBody());
      await _repo(adapter).fetchBills();

      final params = adapter.captured!.queryParameters;
      expect(params.containsKey('search'), isFalse);
      expect(params.containsKey('from_date'), isFalse);
      expect(params.containsKey('to_date'), isFalse);
      expect(params['page'], 1);
    });

    test('a refused body becomes a readable tailoring error', () async {
      final adapter = _CapturingAdapter({
        'success': false,
        'message': 'لا تملك صلاحية استعراض الفواتير',
      });

      expect(
        () => _repo(adapter).fetchBills(),
        throwsA(
          isA<TailoringException>().having(
            (e) => e.displayMessage,
            'displayMessage',
            'لا تملك صلاحية استعراض الفواتير',
          ),
        ),
      );
    });
  });

  // ================================================================
  // فاتورة واحدة
  // ================================================================
  group('TailoringRepository.fetchBill', () {
    test('asks for the composite identity, never the number alone', () async {
      final adapter = _CapturingAdapter({
        'success': true,
        'data': {
          'header': {'bill_no': 12345, 'year': 2026, 'cust_name': 'محمد'},
          'payment': null,
          'models': [
            {
              'seq_no': 1,
              'pieces': [
                {'seq_no1': 5001, 'cutting_done': 1},
              ],
            },
          ],
          'measure_labels': {'L1': 'الطول'},
        },
      });

      final detail = await _repo(adapter).fetchBill(12345, 2026);

      // المفتاح المركّب في المسار: الرقم وحده يعيد أول صف مطابق
      expect(adapter.captured!.path, '/tailoring/bills/12345/2026');
      expect(detail.header.billNo, 12345);
      expect(detail.header.year, 2026);
      // الخادم لم يرسل الدفع ⇒ محجوب لا ناقص
      expect(detail.hasPaymentDetails, isFalse);
      expect(detail.models.single.movementSeqNos, [5001]);
      expect(detail.labelFor('L1'), 'الطول');
    });

    test('a 404 outside the view is flagged, not reported as a network fault',
        () async {
      final adapter = _CapturingAdapter(
        {
          'success': false,
          'message': 'الفاتورة غير موجودة في مصدر بيانات التفصيل',
          'not_found_in_view': true,
        },
        status: 404,
      );

      await expectLater(
        _repo(adapter).fetchBill(1, 2026),
        throwsA(
          isA<TailoringException>()
              .having((e) => e.notFoundInView, 'notFoundInView', isTrue)
              .having(
                (e) => e.displayMessage,
                'displayMessage',
                'الفاتورة غير موجودة في مصدر بيانات التفصيل',
              ),
        ),
      );
    });
  });

  // ================================================================
  // سجل الحركة
  // ================================================================
  group('TailoringRepository.fetchMovements', () {
    test('sends the piece numbers of the rows the client already holds',
        () async {
      final adapter = _CapturingAdapter({
        'success': true,
        'data': [
          {
            'tr_inv_d_id': 88,
            'date': '12/03/2026',
            'ordsid': 4,
            'ords_name': 'تم القص',
            'qty': 2,
            'posted': 1,
          },
        ],
      });

      final rows = await _repo(adapter).fetchMovements(12345, 2026, [5001, 5002]);

      expect(adapter.captured!.path, '/tailoring/bills/12345/2026/movements');
      expect(adapter.captured!.queryParameters['seq_nos'], '5001,5002');
      expect(rows, hasLength(1));
      expect(rows.single.stageLabel, 'تم القص');
      expect(rows.single.postedLabel, 'مُرحَّل');
    });

    test('no piece numbers means no request at all', () async {
      final adapter = _CapturingAdapter({'success': true, 'data': []});

      final rows = await _repo(adapter).fetchMovements(1, 2026, const []);

      expect(rows, isEmpty);
      expect(adapter.calls, 0);
    });
  });

  // ================================================================
  // المرجعيات والنشاط
  // ================================================================
  group('TailoringRepository reference and activity', () {
    test('reads the labels, types, shapes and stages', () async {
      final adapter = _CapturingAdapter({
        'success': true,
        'data': {
          'measure_labels': {'L1': 'الطول'},
          'types': [
            {'type_no': 1, 'type_name': 'قميص'},
          ],
          'styles': [
            {'shape_style_no': 11, 'style_name': 'كلاسيكي', 'type_no': 1},
          ],
          'stages': [
            {'ordsid': 1, 'ordsname': 'تسليم للقص'},
          ],
        },
      });

      final reference = await _repo(adapter).fetchReference();

      expect(adapter.captured!.path, '/tailoring/reference');
      expect(reference.labelFor('L1'), 'الطول');
      expect(reference.activeTypes.single.typeName, 'قميص');
      expect(reference.stylesForType(1).single.styleName, 'كلاسيكي');
      expect(reference.activeStages.single.ordsname, 'تسليم للقص');
    });

    test('records print/export as one activity row', () async {
      final adapter = _CapturingAdapter({'success': true, 'data': null});

      final ok = await _repo(adapter).recordActivity(12345, 2026,
          action: 'print');

      expect(ok, isTrue);
      expect(adapter.captured!.method, 'POST');
      expect(adapter.captured!.path, '/tailoring/bills/12345/2026/activity');
      expect(adapter.captured!.data, {'action': 'print'});
    });

    test('a failed audit never fails the action it describes', () async {
      final adapter = _CapturingAdapter(
        {'success': false, 'message': 'boom'},
        status: 500,
      );

      final ok = await _repo(adapter).recordActivity(1, 2026, action: 'export');

      expect(ok, isFalse);
    });
  });
}
