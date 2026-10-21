import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/account_group_statement_model.dart';
import '../models/account_model.dart';
import '../models/chart_account_model.dart';

// ================================================================
// نتيجة عملية الحساب
// ================================================================
class AccountResult {
  final bool success;
  final String message;
  final dynamic data;

  const AccountResult({
    required this.success,
    required this.message,
    this.data,
  });
}

// ================================================================
// مستودع بيانات الحسابات
// ================================================================
class AccountRepository {
  final DioClient client;

  AccountRepository({required this.client});

  void cancel() {
    // دعم دالة الإلغاء العامة عند الحاجة
  }

  // ============================================================
  // جلب هيكل الشجرة
  // ============================================================

  /// جلب الأقسام الرئيسية (ACCOUNT)
  Future<List<AccountModel>> fetchAccounts({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/account',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب الحسابات الفرعية (ACC_MAIN)
  Future<List<AccMainModel>> fetchAccMain({int? accNo, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/main',
        queryParameters: {if (accNo != null) 'acc_no': accNo},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccMainModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب الحسابات الجزئية (ACC_SUB)
  Future<List<AccSubModel>> fetchAccSub({int? accSub, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/sub',
        queryParameters: {if (accSub != null) 'acc_sub': accSub},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccSubModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب مجموعات الحسابات الجزئي (ACC_SUB_GROUP)
  Future<List<AccSubGroupModel>> fetchAccSubGroup({int? accPart, CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/sub-group',
        queryParameters: {if (accPart != null) 'acc_part': accPart},
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccSubGroupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  /// جلب الشجرة المحاسبية الكاملة
  Future<List<AccountTreeNode>> fetchAccountTree({CancelToken? cancelToken}) async {
    try {
      final resp = await client.dio.get(
        '/accounts/tree',
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['data'] as List? ?? [])
            .map((e) => AccountTreeNode.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return [];
      rethrow;
    }
  }

  // ============================================================
  // الحسابات المالية (CHART_ACC)
  // ============================================================

  /// جلب الحسابات المالية مع بحث وترقيم
  Future<Map<String, dynamic>> fetchChartAccounts({
    String search = '',
    int page = 1,
    int limit = 50,
    int? groupId,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/chart',
        queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
          if (groupId != null) 'group_id': groupId,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final list =
            (body['data'] as List? ?? [])
                .map(
                  (e) => ChartAccountModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();
        return {
          'data': list,
          'meta': body['meta'] as Map<String, dynamic>? ?? {},
        };
      }
      return {'data': [], 'meta': {}};
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return {'data': [], 'meta': {}};
      }
      rethrow;
    }
  }

  /// إنشاء حساب مالي جديد (مجموعة حسابات جزئي)
  Future<AccountResult> createSubGroup({
    required String name,
    required int accPart,
  }) async {
    try {
      final resp = await client.dio.post(
        '/accounts/sub-group',
        data: {'acc_group_name': name, 'acc_part': accPart},
      );
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return AccountResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// إنشاء حساب مالي (CHART_ACC)
  Future<AccountResult> createChartAccount({
    required String name,
    required int groupId,
    double? balance,
    double? limitedBalance,
  }) async {
    try {
      final resp = await client.dio.post(
        '/accounts/chart',
        data: {
          'acc_name': name,
          'group_id': groupId,
          if (balance != null) 'balance': balance,
          if (limitedBalance != null) 'limited_balance': limitedBalance,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
        data: body['data'],
      );
    } catch (e) {
      return AccountResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// تعديل حساب مالي
  Future<AccountResult> updateChartAccount(
    int accNo,
    Map<String, dynamic> data,
  ) async {
    try {
      final resp = await client.dio.put('/accounts/chart/$accNo', data: data);
      final body = resp.data as Map<String, dynamic>;
      return AccountResult(
        success: body['success'] == true,
        message: body['message']?.toString() ?? '',
      );
    } catch (e) {
      return AccountResult(success: false, message: 'خطأ: ${e.toString()}');
    }
  }

  /// كشف حساب مالي
  Future<AccountStatementData> fetchAccountStatement(
    int accNo, {
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/chart/$accNo/statement',
        queryParameters: {
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return AccountStatementData.fromJson(body);
      }
      return const AccountStatementData();
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return const AccountStatementData();
      }
      rethrow;
    }
  }

  /// كشف حساب مفصل
  Future<Map<String, dynamic>> fetchDetailedStatement({
    required String type,
    String? id,
    String? fromDate,
    String? toDate,
    int? curNo,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/statement-detail',
        queryParameters: {
          'type': type,
          if (id != null) 'id': id,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
          if (curNo != null) 'cur_no': curNo,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      return body;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return {};
      rethrow;
    }
  }

  /// كشف حساب مجموعة حسابات جزئية (ميزان المراجعة)
  /// GET /accounts/group-statement — same try/cancel-token/error pattern as the
  /// adjacent statement/detail methods above; scope params are all optional and
  /// the server resolves the deepest one present (see AccountController::getGroupStatement).
  Future<TrialBalanceReport> fetchGroupStatement({
    int? accNo,
    int? accSub,
    int? accPart,
    int? groupId,
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        '/accounts/group-statement',
        queryParameters: {
          if (accNo != null) 'acc_no': accNo,
          if (accSub != null) 'acc_sub': accSub,
          if (accPart != null) 'acc_part': accPart,
          if (groupId != null) 'group_id': groupId,
          if (fromDate != null) 'from_date': fromDate,
          if (toDate != null) 'to_date': toDate,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return TrialBalanceReport.fromJson(body);
      }
      return TrialBalanceReport.empty;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return TrialBalanceReport.empty;
      }
      rethrow;
    }
  }
}
