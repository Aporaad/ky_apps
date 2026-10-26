import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/accounts/data/repositories/account_repository.dart';

/// اختبارات كشف الحساب: هل يُرسل المستودع `limit` من نفسه؟
/// Statement repo tests: does the repository inject a `limit` on its own?
///
/// العطل الذي نحميه: `limit: 50` ثابت في المستودع كان يجعل الخادم يعيد 50 سطراً
/// فقط، فيبدو فلتر الفترة مُتجاهَلاً. الآن `limit` لا يُرسل إلا إذا طلبه المستدعي.
/// Regression under guard: a hardcoded `limit: 50` made the server return only 50
/// rows, so a chosen period looked ignored. `limit` is now sent only on request.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body);

  final Map<String, dynamic> body;
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// ردّ الخادم: 120 حركة داخل الفترة — أكثر بكثير من السقف القديم (50).
/// Server reply: 120 movements in the period — far beyond the old cap of 50.
Map<String, dynamic> _statementBody({int rows = 120}) => {
      'success': true,
      'message': 'ok',
      'data': {
        'account': {'acc_no': 11010001, 'acc_name': 'حساب اختبار'},
        'transactions': [
          for (var i = 1; i <= rows; i++)
            {
              'entry_no': 4250000000 + i,
              'sub_entry_no': '${40000 + i}',
              'date': '0${(i % 9) + 1}/03/2025',
              'entry_type_name': 'قيد يومية',
              'description': 'حركة رقم $i',
              'debit': i.isEven ? 1000 : 0,
              'credit': i.isEven ? 0 : 1000,
              'balance': 0,
            },
        ],
        'summary': {
          'opening_balance': 0,
          'final_balance': 0,
          'total_debit': 60000,
          'total_credit': 60000,
          'total_records': rows,
          'currency': 'يمني YR',
          'from_date': '2025-03-01',
          'to_date': '2025-04-30',
          'defaulted': false,
        },
      },
      'meta': {
        'total': rows,
        'page': 1,
        'limit': 0,
        'returned': rows,
        'total_pages': 1,
        'has_more': false,
      },
    };

AccountRepository _repo(_CapturingAdapter adapter) {
  final client = DioClient(storage: SecureStorageService());
  // نمسح المعترضات كي لا يلمس `AuthInterceptor` التخزين الآمن في بيئة الاختبار.
  // Interceptors are cleared so AuthInterceptor never touches secure storage here.
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = adapter;
  return AccountRepository(client: client);
}

void main() {
  group('AccountRepository.fetchAccountStatement', () {
    test('sends the period and NO limit when the caller does not page', () async {
      final adapter = _CapturingAdapter(_statementBody());
      final data = await _repo(adapter).fetchAccountStatement(
        11010001,
        fromDate: '2025-03-01',
        toDate: '2025-04-30',
      );

      final params = adapter.captured!.queryParameters;
      // الفترة تمرَّر كما هي، ولا سقف صفوف من طرف العميل.
      // The period travels as-is, with no client-side row cap.
      expect(params['from_date'], '2025-03-01');
      expect(params['to_date'], '2025-04-30');
      expect(params.containsKey('limit'), isFalse,
          reason: 'إرسال limit هو ما كان يقصّ الكشف إلى 50 سطراً / '
              'sending limit is what truncated the statement to 50 rows');
      expect(params.containsKey('page'), isFalse);

      // كل صفوف الرد تصل إلى الكشف — لا اقتطاع في الطريق.
      // Every row of the reply reaches the statement — nothing is dropped.
      expect(data.transactions, hasLength(120));
      expect(data.transactions.first.description, contains('حركة رقم 1'));
      expect(data.transactions.last.description, contains('حركة رقم 120'));
      expect(data.totalRecords, 120);
    });

    test('forwards an explicit limit only when the caller asks for paging',
        () async {
      final adapter = _CapturingAdapter(_statementBody(rows: 25));
      await _repo(adapter).fetchAccountStatement(
        11010001,
        fromDate: '2025-03-01',
        toDate: '2025-04-30',
        page: 2,
        limit: 25,
      );

      final params = adapter.captured!.queryParameters;
      expect(params['page'], 2);
      expect(params['limit'], 25);
    });

    test('an empty period still returns the whole reply (no implicit 50)', () async {
      final adapter = _CapturingAdapter(_statementBody(rows: 90));
      final data = await _repo(adapter).fetchAccountStatement(11010001);

      expect(adapter.captured!.queryParameters.containsKey('limit'), isFalse);
      expect(data.transactions, hasLength(90));
    });
  });
}
