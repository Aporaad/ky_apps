import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../accounts/data/models/chart_account_model.dart';
import '../../../workers/data/models/worker_work_report_model.dart';

/// مستودع الكشوفات الشخصية — مالي وعمل — للمستخدم الحالي
/// Personal statements repository — financial and work — for the logged-in user only.
///
/// لا يمرر أي معرّف حساب: الخادم يقرأ ACC_NO من جلسة المستخدم المصادق عليه.
/// Passes no account identifier: the server reads ACC_NO from the authenticated session.
class MyStatementRepository {
  final DioClient client;

  MyStatementRepository({required this.client});

  /// جلب كشف الحساب المالي الشخصي
  /// Fetch the personal financial statement.
  Future<AccountStatementData> fetchMyFinancialStatement({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.myFinancialStatement,
        queryParameters: {
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
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

  /// جلب كشف العمل الشخصي (خياط/قصاص)
  /// Fetch the personal work report (tailor/cutter).
  Future<WorkerWorkReport?> fetchMyWorkReport({
    String? fromDate,
    String? toDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.myWorkStatement,
        queryParameters: {
          if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return WorkerWorkReport.fromJson(body);
      }
      return null;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return null;
      rethrow;
    }
  }
}
