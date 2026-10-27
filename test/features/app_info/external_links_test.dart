import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/app_info.dart';
import 'package:ky_apps/features/app_info/presentation/utils/external_links.dart';

/// اختبارات تحويل رقم الهاتف إلى رابط `tel:` — دالة نقية بلا منصة ولا إطلاق فعلي
/// Tests for turning a stored phone number into a `tel:` URI — a pure function, no platform
/// channel and no actual launch.
void main() {
  group('ExternalLinks.buildTelUri', () {
    test('الرقم المحلي يأخذ مفتاح الدولة 967', () {
      // 780154000 كما هو مخزَّن في APP_SETTINGS — بدونه يصير +780154000 رقمًا لا وجود له
      // 780154000 as stored in APP_SETTINGS — without the code it becomes +780154000, which dials
      // nothing.
      final uri = ExternalLinks.buildTelUri('780154000');

      expect(uri, isNotNull);
      expect(uri!.scheme, 'tel');
      expect(uri.path, '+967780154000');
    });

    test('صفر البداية يُحذف قبل إضافة المفتاح', () {
      expect(ExternalLinks.buildTelUri('0776422777')?.path, '+967776422777');
    });

    test('الرقم الذي يحمل 967 مسبقاً يبقى كما هو', () {
      expect(ExternalLinks.buildTelUri('967776422777')?.path, '+967776422777');
    });

    test('المسافات والرمز + وبادئة 00 تُنقّى', () {
      expect(ExternalLinks.buildTelUri('+967 776 422 777')?.path, '+967776422777');
      expect(ExternalLinks.buildTelUri('00967 776 422 777')?.path, '+967776422777');
      expect(ExternalLinks.buildTelUri('(967) 776-422-777')?.path, '+967776422777');
    });

    test('هاتف المطور في ثوابت التطبيق يبقى سليماً بعد التطبيع', () {
      expect(ExternalLinks.buildTelUri(kDeveloperPhone)?.path, '+967776422777');
    });

    test('بلا أرقام لا يُبنى رابط', () {
      expect(ExternalLinks.buildTelUri(null), isNull);
      expect(ExternalLinks.buildTelUri(''), isNull);
      expect(ExternalLinks.buildTelUri('   '), isNull);
      expect(ExternalLinks.buildTelUri('لا رقم هنا'), isNull);
    });
  });
}
