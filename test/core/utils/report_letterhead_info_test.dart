import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_letterhead_info.dart';
import 'package:ky_apps/features/app_config/data/models/app_config_model.dart';

void main() {
  group('ReportLetterheadInfo.arabicLines', () {
    test('lays the name over the address and the Arabic-Indic contact numbers', () {
      const info = ReportLetterheadInfo(
        companyName: 'الكبودي للخياطة الرجالية',
        companyNameEn: 'ALKABODI FOR MEN TAILORING',
        address: 'صنعاء - شارع الحسن',
        addressEn: 'Sanaa - Al-Hassan Street',
        phone: '780154000 - 780164000',
        website: '',
      );

      expect(info.arabicLines, [
        'الكبودي للخياطة الرجالية',
        'صنعاء - شارع الحسن',
        // الأرقام بالهندية كما في الترويسة المطبوعة / Arabic-Indic digits, as printed
        'هاتف: ٧٨٠١٥٤٠٠٠ - ٧٨٠١٦٤٠٠٠',
      ]);
    });

    test('appends the website line only when it is configured', () {
      const info = ReportLetterheadInfo(
        companyName: 'الكبودي',
        address: 'صنعاء',
        phone: '780154000',
        website: 'kabodi.dev',
      );

      expect(info.arabicLines.last, 'الموقع: kabodi.dev');
      expect(info.englishLines.last, 'Web: kabodi.dev');
    });
  });

  group('ReportLetterheadInfo.englishLines', () {
    test('mirrors the Arabic block in Latin script with LTR phone numbers', () {
      const info = ReportLetterheadInfo(
        companyName: 'الكبودي للخياطة الرجالية',
        companyNameEn: "ALKABODI FOR MEN's TAILORING",
        address: 'الجرف - شارع بيت الشايف',
        addressEn: 'Airport Street - Next to Al-shayef House',
        phone: '780154000 - 780164000 - 777430907',
        website: '',
      );

      expect(info.englishLines, [
        "ALKABODI FOR MEN's TAILORING",
        'Airport Street - Next to Al-shayef House',
        'Tel: 780154000 - 780164000 - 777430907',
      ]);
    });
  });

  group('ReportLetterheadInfo printed-header fallbacks', () {
    test('a blank setting falls back to the printed letterhead wording', () {
      const info = ReportLetterheadInfo(
        companyName: '',
        address: '',
        phone: '',
        website: '',
      );

      expect(info.nameAr, ReportLetterheadInfo.kFallbackNameAr);
      expect(info.nameEn, ReportLetterheadInfo.kFallbackNameEn);
      expect(info.addressAr, ReportLetterheadInfo.kFallbackAddressAr);
      expect(info.addressEnOrFallback, ReportLetterheadInfo.kFallbackAddressEn);
      expect(info.phoneNumbers, ReportLetterheadInfo.kFallbackPhone);
      // لا سطر فارغ أبداً في أي من العمودين / neither column ever renders a blank line
      expect(info.arabicLines.every((line) => line.trim().isNotEmpty), isTrue);
      expect(info.englishLines.every((line) => line.trim().isNotEmpty), isTrue);
    });

    test('configured values win over the fallbacks', () {
      const info = ReportLetterheadInfo(
        companyName: 'شركة التجريب',
        companyNameEn: 'Test Company',
        address: 'عنوان التجريب',
        addressEn: 'Test Address',
        phone: '01-0123456',
        website: '',
      );

      expect(info.nameAr, 'شركة التجريب');
      expect(info.nameEn, 'Test Company');
      expect(info.addressAr, 'عنوان التجريب');
      expect(info.addressEnOrFallback, 'Test Address');
      expect(info.phoneNumbers, '01-0123456');
    });
  });

  group('ReportLetterheadInfo.fromConfig', () {
    test('maps the six company fields of the app config', () {
      final config = AppConfigModel.defaults().copyWith(
        companyName: 'شركة الكبودي',
        companyAddress: 'صنعاء - خط المطار',
        companyPhone: '780154000',
        companyWebsite: 'kabodi.dev',
        companyNameEn: 'AL-KABODI CO.',
        companyAddressEn: 'Airport Street',
      );

      final info = ReportLetterheadInfo.fromConfig(config);

      expect(info.companyName, 'شركة الكبودي');
      expect(info.companyNameEn, 'AL-KABODI CO.');
      expect(info.address, 'صنعاء - خط المطار');
      expect(info.addressEn, 'Airport Street');
      expect(info.phone, '780154000');
      expect(info.website, 'kabodi.dev');
    });

    test('the configured English name wins over the letterhead template', () {
      final config = AppConfigModel.defaults();
      final info = ReportLetterheadInfo.fromConfig(config);

      // أي قيمة إنجليزية مضبوطة (ولو الافتراضي المضمّن في النموذج) تتقدّم على نص القالب
      // Any configured English name — even the model's own default — beats the template.
      expect(config.companyNameEn, isNotEmpty);
      expect(info.nameEn, config.companyNameEn);

      // أما العنوان غير المضبوط فيأخذ نص الترويسة المطبوعة
      // A blank English address, on the other hand, falls back to the printed header.
      expect(info.addressEn, isEmpty);
      expect(info.addressEnOrFallback, ReportLetterheadInfo.kFallbackAddressEn);
    });

    test('ما يرسله الخادم يصل إلى كلا العمودين', () {
      // كما تصل الحمولة من `GET /app-config` بعد إضافة صفّي `company_name_en` و
      // `company_address_en` إلى `APP_SETTINGS`.
      // The payload as GET /app-config now answers it, with the two new APP_SETTINGS rows in place.
      final config = AppConfigModel.fromJson(const {
        'company_name': 'الكبودي للخياطة الرجالية',
        'company_name_en': "ALKABODI FOR MEN's TAILORING",
        'company_address': 'الجرف - بيت الشايف',
        'company_address_en': 'Airport Street - Next to Al-shayef House',
        'company_phone': '780154000',
      });

      final info = ReportLetterheadInfo.fromConfig(config);

      expect(info.arabicLines.first, 'الكبودي للخياطة الرجالية');
      expect(info.englishLines, [
        "ALKABODI FOR MEN's TAILORING",
        'Airport Street - Next to Al-shayef House',
        'Tel: 780154000',
      ]);
    });
  });

  group('toArabicIndicDigits', () {
    test('converts only digits and keeps separators untouched', () {
      expect(toArabicIndicDigits('780154000 - 777430907'), '٧٨٠١٥٤٠٠٠ - ٧٧٧٤٣٠٩٠٧');
      expect(toArabicIndicDigits('01-0123456'), '٠١-٠١٢٣٤٥٦');
      expect(toArabicIndicDigits('بدون أرقام'), 'بدون أرقام');
    });
  });
}
