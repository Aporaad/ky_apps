import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/currency_model.dart';

// ================================================================
// نتيجة عملية العملة
// ================================================================
class CurrencyResult {
  final bool success;
  final String message;
  final dynamic data;

  const CurrencyResult({required this.success, required this.message, this.data});
}

// ================================================================
// مستودع بيانات العملات وأسعار الصرف
// ================================================================
class CurrencyRepository {
  final DioClient client;
  CurrencyRepository({required this.client});

  void cancel() {
    // دعم دالة الإلغاء العامة عند الحاجة
  }

  /// جلب جميع العملات مع بياناتها وآخر سعر صرف
  Future<List<CurrencyModel>> fetchCurrencies({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get('/currencies', cancelToken: cancelToken);
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => CurrencyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// إضافة عملة جديدة
  Future<CurrencyResult> createCurrency(CurrencyModel currency) async {
    try {
      final resp = await client.dio.post('/currencies', data: currency.toJsonForCreate());
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// تعديل عملة
  Future<CurrencyResult> updateCurrency(int curNo, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('/currencies/$curNo', data: data);
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// حذف عملة
  Future<CurrencyResult> deleteCurrency(int curNo) async {
    try {
      final resp = await client.dio.delete('/currencies/$curNo');
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// جلب سجل أسعار الصرف لعملة محددة
  Future<Map<String, dynamic>> fetchPrices(int curNo, {int page = 1, int limit = 30, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/currencies/$curNo/prices',
        queryParameters: {'page': page, 'limit': limit},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? [])
            .map((e) => CurrencyPriceModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'currency': body['currency'],
          'data': list,
          'meta': body['meta'],
        };
      }
      return {'data': [], 'meta': {}};
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return {'data': [], 'meta': {}};
      rethrow;
    }
  }

  /// إضافة سعر صرف جديد
  Future<CurrencyResult> addPrice(int curNo, double price, String dayDate) async {
    try {
      final resp = await client.dio.post(
        '/currencies/$curNo/prices',
        data: {'price': price, 'day_date': dayDate},
      );
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// تعديل سعر صرف
  Future<CurrencyResult> updatePrice(int curNo, int seq, double price, String dayDate) async {
    try {
      final resp = await client.dio.put(
        '/currencies/$curNo/prices/$seq',
        data: {'price': price, 'day_date': dayDate},
      );
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// حذف سعر صرف
  Future<CurrencyResult> deletePrice(int curNo, int seq) async {
    try {
      final resp = await client.dio.delete('/currencies/$curNo/prices/$seq');
      final body = resp.data as Map<String, dynamic>;
      return CurrencyResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return CurrencyResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }
}
