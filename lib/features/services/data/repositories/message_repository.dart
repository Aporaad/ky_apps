import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/message_model.dart';
import 'service_result.dart';

/// مستودع قناة رسائل (SMS أو واتساب) — المسار يختلف حسب القناة
/// Message-channel repository (SMS or WhatsApp) — the base path differs per channel.
class MessageRepository {
  final DioClient client;
  final String basePath;

  MessageRepository({required this.client, required this.basePath});

  /// حالة السلسلة: all|sent|pending|failed
  Future<List<MessageModel>> fetchMessages({
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '$basePath/messages',
        queryParameters: {
          'status': status,
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        final messages = list
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList();
        // ترتيب الأحدث أولاً (دفاعي): نضمنه في العميل حتى لو رتّب الخادم بـ ID فقط؛
        // صيغة CREATED_AT (YYYY-MM-DD HH:MM:SS) مرتّبة لغويًا زمنيًا، ثم بالمعرّف عند التساوي.
        // Newest-first (defensive): sort client-side by created_at then id, so display order is
        // guaranteed regardless of how the server ordered the rows.
        messages.sort((a, b) {
          final byDate = (b.createdAt ?? '').compareTo(a.createdAt ?? '');
          return byDate != 0 ? byDate : b.id.compareTo(a.id);
        });
        return messages;
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  Future<MessageModel?> fetchMessage(int id, {CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '$basePath/messages/$id',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return MessageModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  Future<ServiceResult> enqueue(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post('$basePath/messages', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['ids'],
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  /// تعديل رسالة منتظرة في الطابور — الخادم يرفض ما ليس في QUEUE
  /// Update a pending queued message — the server rejects anything not in the queue.
  Future<ServiceResult> update(int id, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('$basePath/messages/$id', data: data);
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }

  Future<ServiceResult> delete(int id) async {
    try {
      final resp = await client.dio.delete('$basePath/messages/$id');
      final body = resp.data as Map<String, dynamic>;
      return ServiceResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      return ServiceResult(success: false, message: dioErrorMessage(e));
    }
  }
}
