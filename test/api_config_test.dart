import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/api_constants.dart';
import 'package:ky_apps/features/settings/data/repositories/api_config_repository.dart';

void main() {
  group('ApiConfigRepository Tests', () {
    test('normalizeUrl removes trailing slashes and trims', () {
      // التوقع كان يشير لمضيف مختلف عن المُدخل: normalizeUrl تُنظّف الشرطات فقط
      // ولا تُبدّل المضيف — نفس قيمة `ApiConstants.defaultBaseUrl` الحالية.
      // The expectation named a different host than the input: normalizeUrl trims
      // and strips trailing slashes, it never rewrites the host.
      expect(
        ApiConfigRepository.normalizeUrl('  http://192.168.0.9:8000/api/  '),
        'http://192.168.0.9:8000/api',
      );
      expect(
        ApiConfigRepository.normalizeUrl('http://localhost:8000///'),
        'http://localhost:8000',
      );
    });

    test('ApiConstants defaults are properly defined', () {
      expect(ApiConstants.defaultBaseUrl, isNotEmpty);
      expect(ApiConstants.baseUrl, ApiConstants.defaultBaseUrl);
      expect(ApiConstants.testConnectionEndpoint, '/hello');
    });
  });
}
