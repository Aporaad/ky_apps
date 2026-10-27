import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../admin/data/models/admin_result.dart';
import '../../../admin/data/models/paged_result.dart';
import '../models/support_inquiry_model.dart';

/// حالات التذكرة التي يعرّفها `SupportInquiryController::conditions()`
/// The ticket statuses `SupportInquiryController::conditions()` actually recognises.
const List<String> kSupportStatuses = ['all', 'new', 'answered', 'closed'];

/// مستودع استفسارات الدعم — الإرسال العام وقائمة الإدارة والرد
/// Support-inquiry repository — the public submit, the admin list, and the reply.
///
/// الإرسال يمرّ على عميل Dio نفسه الذي بُني للشاشة، فالتوكن يُرفق تلقائياً إن وُجد لدى المستخدم
/// (وتذكرة صاحب الجلسة تُربَط بحسابه في الخادم)، ويعمل بلا توكن للزائر قبل الدخول.
/// Submission rides the same Dio client the screen already built, so the token is attached
/// automatically when the user has one (and the server binds that ticket to the account) while
/// still working with no token for a guest before login.
class SupportRepository {
  final DioClient client;

  SupportRepository({required this.client});

  /// إرسال استفسار — يعيد معرّف التذكرة عند النجاح
  /// Submit an inquiry — returns the created ticket id on success.
  Future<AdminResult<Map<String, dynamic>>> submitInquiry({
    String? name,
    String? phone,
    required String message,
    String? appVersion,
    String? platform,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.post(
        ApiConstants.supportInquiries,
        data: {
          // الحقول الفارغة لا تُرسل: الخادم يشتق الاسم من الحساب عند وجود جلسة
          // Blank fields are not sent: the server derives the name from the account.
          if ((name ?? '').trim().isNotEmpty) 'name': name!.trim(),
          if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
          'message': message.trim(),
          if ((appVersion ?? '').trim().isNotEmpty) 'app_version': appVersion!.trim(),
          if ((platform ?? '').trim().isNotEmpty) 'platform': platform!.trim(),
        },
        cancelToken: cancelToken,
      );

      return AdminResult.raw(
        resp.data as Map<String, dynamic>,
        statusCode: resp.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _failure(e, fallback: 'تعذّر إرسال الاستفسار / Could not submit the inquiry');
    }
  }

  /// قائمة الاستفسارات (شاشة الإدارة)
  /// The inquiry list (admin screen).
  Future<PagedResult<SupportInquiryModel>> fetchInquiries({
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get(
        ApiConstants.supportInquiries,
        queryParameters: {
          if (status != 'all' && kSupportStatuses.contains(status)) 'status': status,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'page': page,
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      final body = resp.data as Map<String, dynamic>;

      if (body['success'] == true) {
        return PagedResult.fromJson(body, SupportInquiryModel.fromJson);
      }

      return const PagedResult<SupportInquiryModel>.empty();
    } on DioException catch (e) {
      // الإلغاء ليس خطأً: الشاشة أرسلت طلباً أحدث
      // A cancellation is not an error: the screen issued a newer request.
      if (CancelToken.isCancel(e)) {
        return const PagedResult<SupportInquiryModel>.empty();
      }
      rethrow;
    }
  }

  /// حفظ الرد / إغلاق التذكرة
  /// Save the reply / close the ticket.
  Future<AdminResult<Map<String, dynamic>>> replyToInquiry(
    int ticketId, {
    String? reply,
    required String status,
  }) async {
    try {
      final resp = await client.dio.put(
        '${ApiConstants.supportInquiries}/$ticketId',
        data: {
          'status': status,
          if ((reply ?? '').trim().isNotEmpty) 'reply': reply!.trim(),
        },
      );

      return AdminResult.raw(
        resp.data as Map<String, dynamic>,
        statusCode: resp.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _failure(e, fallback: 'تعذّر حفظ الرد / Could not save the reply');
    }
  }

  /// تفكيك الفشل مع تمييز 429 (المُقيِّد العام) برسالة مفهومة
  /// Unpack a failure, giving the public route's 429 its own readable message.
  AdminResult<Map<String, dynamic>> _failure(
    DioException error, {
    required String fallback,
  }) {
    if (error.response?.statusCode == 429) {
      return const AdminResult(
        success: false,
        message: 'محاولات كثيرة متتالية، حاول بعد قليل / Too many attempts, try later',
        statusCode: 429,
      );
    }

    return AdminResult.failure(error, fallback: fallback);
  }
}
