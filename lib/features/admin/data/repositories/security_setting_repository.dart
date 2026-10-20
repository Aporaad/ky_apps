import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_result.dart';
import '../models/app_security_setting_model.dart';

/// مستودع إعدادات الأمان — `/settings` قراءةً وحفظاً
/// Security settings repository — reading and saving `/settings`.
///
/// الحفظ جماعي في طلب واحد: `PUT /settings` يستقبل `items` مطبّقة داخل معاملة أوراكل واحدة،
/// فحفظة «مهلة الخمول + حد كلمة المرور» تُكتب كلها أو لا تُكتب. إرسال كل مفتاح في طلب كان
/// سيترك الإعدادات نصف مطبّقة عند أول فشل — وهذا وضع أمني لا جمالي.
/// Saving is one batch request: PUT /settings takes `items` and applies them inside a single Oracle
/// transaction, so «idle timeout + password minimum» are written all-or-nothing. Per-key requests
/// would leave the security posture half-applied on the first failure.
class SecuritySettingRepository {
  final DioClient client;

  SecuritySettingRepository({required this.client});

  /// كل الإعدادات بترتيب `SORT_ORDER` مع حدودها المطبَّعة
  /// Every setting in SORT_ORDER, with its bounds already normalised server-side.
  Future<List<AppSecuritySettingModel>> fetchSettings({
    CancelToken? cancelToken,
  }) async {
    try {
      final resp = await client.dio.get('/settings', cancelToken: cancelToken);
      final body = resp.data as Map<String, dynamic>;
      if (body['success'] != true) return const [];
      final data = body['data'];
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(AppSecuritySettingModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return const [];
      rethrow;
    }
  }

  /// حفظ مجموعة مفاتيح — يُرجع عدد المفاتيح التي تغيّرت فعلاً
  /// Save a batch of keys — returns how many values actually changed.
  ///
  /// القيم تُرسل كما هي (عدد أو bool أو نص) لأن `SettingsStore::cast()` تقرأ النوع من القاعدة لا
  /// من العميل؛ و`null` عند الخادم يعني «لا تلمس المفتاح» لا «امسحه»، فالحذف الصريح يُرسل نصاً
  /// فارغاً للمفاتيح النصية فقط.
  /// Values are sent as-is because SettingsStore casts by the stored type, not the client's guess.
  /// Note the server reads null as "don't touch", not "clear" — an explicit clear is an empty
  /// string, and only for string keys.
  Future<AdminResult<int>> saveSettings(
    Map<String, dynamic> valuesByKey,
  ) async {
    if (valuesByKey.isEmpty) {
      return const AdminResult<int>(
        success: false,
        message: 'لا تغيير لحفظه / Nothing to save',
      );
    }

    // الترتيب بالـ key ثابت: نفس التعديل يرسل نفس الحمولة، فيسهل تتبعه في سجل التدقيق
    // Keys are sorted so the same edit always sends the same payload, which is easier to audit.
    final keys = valuesByKey.keys.toList()..sort();
    final items = keys
        .map((key) => {'key': key, 'value': valuesByKey[key]})
        .toList(growable: false);

    try {
      final resp = await client.dio.put('/settings', data: {'items': items});
      final body = resp.data as Map<String, dynamic>;
      final meta = body['meta'];
      final raw = meta is Map ? meta['changed'] : null;
      final changed = raw is int ? raw : int.tryParse('${raw ?? ''}') ?? 0;

      return AdminResult<int>(
        success: body['success'] == true,
        message: (body['message'] ?? '').toString(),
        data: changed,
        errors: AdminResult.errorsOf(body),
        statusCode: resp.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return AdminResult.failure(
        e,
        fallback: 'تعذّر حفظ الإعدادات / Could not save the settings',
      );
    }
  }
}
