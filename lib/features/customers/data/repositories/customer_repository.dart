import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_model.dart';
import '../models/customer_statement_model.dart';

/// نتيجة عملية العميل
class CustomerResult {
  final bool success;
  final String message;
  final dynamic data;

  const CustomerResult({
    required this.success,
    required this.message,
    this.data,
  });
}

/// مستودع بيانات العملاء - يتصل بالـ API وسيرفر أوراكل
/// Customer repository - connects to API and Oracle server
class CustomerRepository {
  final DioClient client;
  CancelToken? _cancelToken;

  CustomerRepository({required this.client});

  /// إلغاء الطلبات الجارية
  void cancel() {
    _cancelToken?.cancel('cancelled');
    _cancelToken = null;
  }

  CancelToken _newToken() {
    _cancelToken?.cancel('new_request');
    _cancelToken = CancelToken();
    return _cancelToken!;
  }

  /// جلب قائمة العملاء مع البحث والتصفح
  Future<List<CustomerModel>> fetchCustomers({
    String search = '',
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final resp = await client.dio.get(
        '/customers',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
        cancelToken: _newToken(),
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list = (body['data'] as List? ?? []);
        return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب عميل واحد بالرقم
  Future<CustomerModel?> fetchCustomer(int custNo) async {
    try {
      final resp = await client.dio.get('/customers/$custNo', cancelToken: _newToken());
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        return CustomerModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }

  /// إضافة عميل جديد
  Future<CustomerResult> createCustomer(Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.post('/customers', data: data);
      final body = resp.data as Map<String, dynamic>;
      return CustomerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: body['cust_no'],
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ?? e.message ?? 'خطأ في الشبكة';
      return CustomerResult(success: false, message: msg.toString());
    }
  }

  /// تعديل عميل موجود
  Future<CustomerResult> updateCustomer(int custNo, Map<String, dynamic> data) async {
    try {
      final resp = await client.dio.put('/customers/$custNo', data: data);
      final body = resp.data as Map<String, dynamic>;
      return CustomerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ?? e.message ?? 'خطأ في الشبكة';
      return CustomerResult(success: false, message: msg.toString());
    }
  }

  /// حذف عميل
  Future<CustomerResult> deleteCustomer(int custNo) async {
    try {
      final resp = await client.dio.delete('/customers/$custNo');
      final body = resp.data as Map<String, dynamic>;
      return CustomerResult(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data as Map<String, dynamic>?)?['message'] ?? e.message ?? 'خطأ في الشبكة';
      return CustomerResult(success: false, message: msg.toString());
    }
  }

  /// كشف حساب عميل مع دعم التصفية بنطاق التاريخ
  Future<Map<String, dynamic>?> fetchStatement(
    int custNo, {
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final resp = await client.dio.get(
        '/customers/$custNo/statement',
        queryParameters: {
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        },
        cancelToken: _newToken(),
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final rows = (body['data'] as List? ?? [])
            .map((e) => CustomerStatementModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {
          'customer': body['customer'],
          'rows': rows,
          'summary': body['summary'],
        };
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }
}
