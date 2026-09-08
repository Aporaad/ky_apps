import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// نتيجة فحص الاتصال بالخادم
class ApiConnectionTestResult {
  final bool success;
  final String message;
  final int? statusCode;
  final int? latencyMs;

  const ApiConnectionTestResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.latencyMs,
  });
}

/// مستودع إدارة إعدادات الـ API وفحص الاتصال
class ApiConfigRepository {
  final SecureStorageService _storage;

  ApiConfigRepository({required SecureStorageService storage})
      : _storage = storage;

  /// قراءة عنوان الـ API النشط حالياً (من التخزين المشفر أو القيمة الافتراضية)
  Future<String> getActiveApiUrl() async {
    final savedUrl = await _storage.getApiBaseUrl();
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      return savedUrl.trim();
    }
    return ApiConstants.defaultBaseUrl;
  }

  /// حفظ عنوان جديد للـ API
  Future<void> saveApiUrl(String url) async {
    final cleanedUrl = normalizeUrl(url);
    await _storage.saveApiBaseUrl(cleanedUrl);
  }

  /// استعادة العنوان الافتراضي للـ API
  Future<void> resetToDefault() async {
    await _storage.deleteApiBaseUrl();
  }

  /// تنظيف وتنسيق الرابط للتأكد من بنيته الصحيحة
  static String normalizeUrl(String input) {
    var url = input.trim();
    // إزالة السلاش المكرر في النهاية
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// فحص الاتصال بعنوان الـ API المحدد
  Future<ApiConnectionTestResult> testConnection(String targetUrl) async {
    final normalized = normalizeUrl(targetUrl);

    if (normalized.isEmpty) {
      return const ApiConnectionTestResult(
        success: false,
        message: 'يرجى إدخال عنوان خادم صالح للـ API',
      );
    }

    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      return const ApiConnectionTestResult(
        success: false,
        message: 'يجب أن يبدأ الرابط بـ http:// أو https://',
      );
    }

    final testDio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.testTimeout,
        receiveTimeout: ApiConstants.testTimeout,
        headers: {
          'Accept': 'application/json',
        },
        validateStatus: (status) => true,
      ),
    );

    final stopwatch = Stopwatch()..start();

    try {
      // محاولة فحص نقطة النهاية /hello إذا كانت متوفرة
      final testUrl = normalized.endsWith('/api')
          ? '$normalized/hello'
          : normalized;

      final response = await testDio.get(testUrl);
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 400) {
        String detailMessage = 'تم الاتصال بنجاح!';
        if (response.data is Map && response.data['message'] != null) {
          detailMessage = '${response.data['message']}';
        }
        return ApiConnectionTestResult(
          success: true,
          message: 'تم الاتصال بنجاح ($detailMessage)',
          statusCode: response.statusCode,
          latencyMs: latency,
        );
      } else if (response.statusCode == 404) {
        // فحص الرابط الأساسي مباشرة
        final fallbackResponse = await testDio.get(normalized);
        if (fallbackResponse.statusCode != null && fallbackResponse.statusCode! < 500) {
          return ApiConnectionTestResult(
            success: true,
            message: 'تم الوصول إلى الخادم بنجاح (رمز الاستجابة: ${fallbackResponse.statusCode})',
            statusCode: fallbackResponse.statusCode,
            latencyMs: stopwatch.elapsedMilliseconds,
          );
        }
        return ApiConnectionTestResult(
          success: false,
          message: 'الخادم متصل ولكن المسار غير موجود (404 Not Found)',
          statusCode: response.statusCode,
          latencyMs: latency,
        );
      } else {
        return ApiConnectionTestResult(
          success: false,
          message: 'استجاب الخادم برمز خطأ: ${response.statusCode}',
          statusCode: response.statusCode,
          latencyMs: latency,
        );
      }
    } on DioException catch (dioErr) {
      stopwatch.stop();
      String errText;
      switch (dioErr.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errText = 'انتهت مهلة محاولة الاتصال بالخادم. تأكد من أن السيرفر يعمل ومن عنوان IP ورقم المنفذ.';
          break;
        case DioExceptionType.connectionError:
          errText = 'فشل الاتصال بالشبكة أو تعذر الوصول إلى الخادم. تأكد من تشغيل Laravel أو تواجد الجهاز على نفس الشبكة.';
          break;
        default:
          errText = dioErr.message ?? 'حدث خطأ أثناء محاولة فحص الاتصال';
      }
      return ApiConnectionTestResult(
        success: false,
        message: errText,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ApiConnectionTestResult(
        success: false,
        message: 'خطأ غير متوقع: $e',
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      testDio.close();
    }
  }
}
