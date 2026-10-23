import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/services/data/repositories/message_repository.dart';
import 'package:ky_apps/features/services/data/repositories/provider_repository.dart';

/// اختبارات المستودع — Dio حقيقي بمحوّل adapter وهمي، بلا منصة ولا شبكة
/// Repository tests — a real Dio with a fake adapter, no platform and no network.
///
/// نمسح المعترضات (كي لا يلمس `AuthInterceptor` التخزين الآمن) ونحقن adapter يعيد JSON جاهزًا
/// أو يرمي ما يحاكي الإلغاء/العطل — فنختبر منطق المستودع نفسه لا الشبكة.
/// Interceptors are cleared (so AuthInterceptor never touches secure storage) and a fake adapter
/// returns canned JSON or throws to simulate cancellation/failure — testing the repo's own logic.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.onFetch);

  final ResponseBody Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      onFetch(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body) => ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

DioClient _client(_FakeAdapter adapter) {
  final client = DioClient(storage: SecureStorageService());
  client.dio.interceptors.clear();
  client.dio.httpClientAdapter = adapter;
  return client;
}

void main() {
  group('ProviderRepository', () {
    test('parses the list on success', () async {
      final repo = ProviderRepository(
        client: _client(_FakeAdapter((o) => _json({
              'success': true,
              'data': [
                {'PROVIDER_ID': 1, 'PROVIDER_NAME': 'A', 'STATUS': 1},
                {'PROVIDER_ID': 2, 'PROVIDER_NAME': 'B', 'STATUS': 0},
              ],
            }))),
      );
      final list = await repo.fetchProviders();
      expect(list, hasLength(2));
      expect(list.first.providerId, 1);
      expect(list.last.isEnabled, isFalse);
    });

    test('returns an empty list when success is false', () async {
      final repo = ProviderRepository(
        client: _client(_FakeAdapter((o) => _json({'success': false, 'data': []}))),
      );
      expect(await repo.fetchProviders(), isEmpty);
    });

    test('swallows a cancelled request and returns an empty list', () async {
      final repo = ProviderRepository(
        client: _client(_FakeAdapter(
          (o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.cancel,
          ),
        )),
      );
      expect(await repo.fetchProviders(), isEmpty);
    });

    test('createProvider surfaces the server message', () async {
      final repo = ProviderRepository(
        client: _client(_FakeAdapter((o) => _json({
              'success': true,
              'message': 'تمت الإضافة',
              'provider_id': 42,
            }))),
      );
      final res = await repo.createProvider({'provider_name': 'X'});
      expect(res.success, isTrue);
      expect(res.message, 'تمت الإضافة');
      expect(res.data, 42);
    });

    test('a transport error becomes a failed ServiceResult', () async {
      final repo = ProviderRepository(
        client: _client(_FakeAdapter(
          (o) => throw DioException(
            requestOptions: o,
            type: DioExceptionType.connectionTimeout,
            message: 'timeout',
          ),
        )),
      );
      final res = await repo.createProvider({});
      expect(res.success, isFalse);
      expect(res.message, isNotEmpty);
    });
  });

  group('MessageRepository', () {
    test('enqueues and returns the created ids', () async {
      final repo = MessageRepository(
        client: _client(_FakeAdapter((o) => _json({
              'success': true,
              'message': 'queued',
              'ids': [7, 8],
            }))),
        basePath: '/sms',
      );
      final res = await repo.enqueue({'msg_text': 'hi', 'mobile_no': '0500'});
      expect(res.success, isTrue);
      expect(res.data, [7, 8]);
    });

    test('list parses preview rows and keeps the status code', () async {
      final repo = MessageRepository(
        client: _client(_FakeAdapter((o) => _json({
              'success': true,
              'data': [
                {'ID': 3, 'MSG_TEXT_PREVIEW': 'مرحبًا', 'IS_SENT': 'Y'},
              ],
            }))),
        basePath: '/whatsapp',
      );
      final list = await repo.fetchMessages(status: 'sent');
      expect(list, hasLength(1));
      expect(list.first.id, 3);
      expect(list.first.isSent, 'Y');
    });
  });
}
