import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// معالج وسيط لحقن التوكن تلقائياً في ترويسات الطلبات، والتقاط موعد انتهاء الجلسة من الردود
/// Interceptor that injects the Bearer token and captures the session deadline from responses.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  /// بلّغ بموعد انتهاء الجلسة كما أرسله الخادم في `X-Session-Expires-At`
  /// Report the deadline the server put on `X-Session-Expires-At`.
  ///
  /// الخادم يجدّد الموعد انزلاقياً مع كل طلب ناجح، فالرد وحده يحمل الموعد الحالي الحقيقي؛
  /// تجاهله يجعل حارس الموعد المحلي يحكم على موعد تسجيل الدخول لا على موعد الجلسة.
  /// The server slides the deadline on every request, so only the response carries the live value;
  /// ignoring it would let the local watchdog judge the sign-in time instead of the session's.
  ///
  /// `serverNow` ترويسة `X-Server-Now` المقابلة: تسمح للعميل بقياس إزاحة الساعتين في لحظة واحدة
  /// فلا يقارن موعداً مكتوباً على ساعة أوراكل بساعة جهازه. غيابها (خادم أقدم) يعني افتراض التطابق.
  /// `serverNow` comes from `X-Server-Now`: it lets the client measure the clock offset at a single
  /// instant instead of comparing an Oracle-clock deadline against a device clock. Absent on older
  /// API builds, where the clocks are assumed to agree.
  final void Function(String deadline, String? serverNow)? onSessionDeadline;

  AuthInterceptor(this._storage, {this.onSessionDeadline});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final deadline = response.headers.value('x-session-expires-at');
    if (deadline != null && deadline.trim().isNotEmpty) {
      // ساعة الخادم اختيارية: غيابها لا يُبطل الموعد، بل يتركه بلا تصحيح إزاحة
      // The server clock is optional: its absence does not void the deadline, it just skips the offset fix.
      final serverNow = response.headers.value('x-server-now');
      onSessionDeadline?.call(deadline.trim(), serverNow?.trim());
    }

    return handler.next(response);
  }
}
