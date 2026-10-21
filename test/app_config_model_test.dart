import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/theme/app_palette.dart';
import 'package:ky_apps/features/app_config/data/models/app_config_model.dart';

/// اختبارات نموذج تهيئة التطبيق — فك/توليد/تحليل آمن بلا الاعتماد على الشبكة
/// App-config model tests — parse/serialize/safe-decoding without touching the network.
void main() {
  group('AppConfigModel.fromJson', () {
    test('يقرأ الحمولة المفكوكة مباشرة بمفاتيح snake_case', () {
      final m = AppConfigModel.fromJson({
        'company_name': 'شركةTest',
        'app_name': 'AppTest',
        'theme_primary_color': '#112233',
        'theme_secondary_color': '#445566',
        'theme_background_color': '#778899',
        'theme_text_primary_color': '#AABBCC',
        'theme_text_secondary_color': '#DDEEFF',
        'theme_font_family': 'Tajawal',
      });

      expect(m.companyName, 'شركةTest');
      expect(m.appName, 'AppTest');
      expect(m.primaryColor, const Color(0xFF112233));
      expect(m.secondaryColor, const Color(0xFF445566));
      expect(m.backgroundColor, const Color(0xFF778899));
      expect(m.textPrimaryColor, const Color(0xFFAABBCC));
      expect(m.textSecondaryColor, const Color(0xFFDDEEFF));
      expect(m.fontFamily, 'Tajawal');
    });

    test('يفكّ الغلاف {success,data} كما يقدّمه الخادم', () {
      final m = AppConfigModel.fromJson({
        'success': true,
        'data': {'company_name': 'مغلّف', 'app_name': 'X'},
      });
      expect(m.companyName, 'مغلّف');
      // الحقول الناقصة تسقط للافتراضي بدل الانهيار
      expect(m.fontFamily, 'Cairo');
    });

    test('يتحمّل الألوان غير الصالحة ويسقط للافتراضي', () {
      final m = AppConfigModel.fromJson({
        'theme_primary_color': 'red',
        'theme_secondary_color': '#GGG',
        'theme_background_color': null,
      });
      expect(m.primaryColor, AppPalette.primary);
      expect(m.secondaryColor, AppPalette.accent);
      expect(m.backgroundColor, AppPalette.background);
    });

    test('يتجاهل النصوص الفارغة ويعوّضها بالافتراضي', () {
      final m = AppConfigModel.fromJson({'company_name': '   '});
      expect(m.companyName, 'الكبودي للخياطة الرجالية');
    });

    test('يقرأ الحقول الإنجليزية بفتحتي حالة ويسقط الفارغ للافتراضي', () {
      // الخادم يمرّر صفوف أوراكل الخام فقد تصل المفاتيح بأحرف كبيرة
      // The API proxies raw Oracle rows, so the keys may arrive UPPERCASE.
      final upper = AppConfigModel.fromJson(const {
        'COMPANY_NAME_EN': "ALKABODI FOR MEN's TAILORING",
        'COMPANY_ADDRESS_EN': 'Airport Street - Next to Al-shayef House',
      });
      expect(upper.companyNameEn, "ALKABODI FOR MEN's TAILORING");
      expect(upper.companyAddressEn, 'Airport Street - Next to Al-shayef House');

      // الفراغ يعيد الافتراضي المضمّن فلا يفقد العمود الأيسر اسمه
      // A blank keeps the baked-in default: the left column never loses its name.
      final blank = AppConfigModel.fromJson({'company_name_en': '   '});
      expect(blank.companyNameEn, "ALKABODI FOR MEN's TAILORING");
    });
  });

  group('AppConfigModel.toJsonForUpdate', () {
    test('يحوّل الألوان إلى سداسي #RRGGBB بحروف كبيرة ومفاتيح snake_case', () {
      final defaults = AppConfigModel.defaults();
      final json = defaults.toJsonForUpdate();

      expect(json['theme_primary_color'], '#A27E4E');
      expect(json['theme_secondary_color'], '#0D9488');
      expect(json['theme_background_color'], '#F8FAFC');
      expect(json['theme_text_primary_color'], '#0F172A');
      expect(json['theme_text_secondary_color'], '#475569');
      expect(json['theme_font_family'], 'Cairo');
      // لا يتسرب أي مفتاح حساس عبر حمولة التحديث
      expect(json.containsKey('api_settings_password'), isFalse);
    });

    test('ذهاب-إياب: من JSON إلى JSON يبقى اللون كما هو', () {
      final hex = '#1A2B3C';
      final m = AppConfigModel.fromJson({'theme_primary_color': hex});
      expect(m.toJsonForUpdate()['theme_primary_color'], hex.toUpperCase());
    });

    test('يحمل مفتاحي الاسم والعنوان بالإنجليزية في جسم التحديث', () {
      // هما مفتاحان قابلان للكتابة في `AppConfig::WRITABLE_KEYS` بالخادم
      // Both are writable keys in the server's AppConfig::WRITABLE_KEYS list.
      final m = AppConfigModel.fromJson(const {
        'company_name_en': 'AL-KABOODI TAILORING',
        'company_address_en': 'Hadda Street - Sanaa',
      });
      final json = m.toJsonForUpdate();

      expect(json['company_name_en'], 'AL-KABOODI TAILORING');
      expect(json['company_address_en'], 'Hadda Street - Sanaa');
    });
  });

  test('defaults تطابق لوحة AppPalette الافتراضية', () {
    final d = AppConfigModel.defaults();
    expect(d.primaryColor, AppPalette.primary);
    expect(d.textSecondaryColor, AppPalette.textSecondary);
  });

  test('copyWith يبدّل الحقول المحددة ويُبقي الباقي', () {
    final base = AppConfigModel.defaults();
    final changed = base.copyWith(companyName: 'جديد', fontFamily: 'Amiri');
    expect(changed.companyName, 'جديد');
    expect(changed.fontFamily, 'Amiri');
    // بقية الحقول كما هي
    expect(changed.appName, base.appName);
    expect(changed.primaryColor, base.primaryColor);
  });

  test('applyToPalette يدفع الألوان إلى اللوحة الزمنية', () {
    // بعد التطبيق يجب أن تعكس اللوحة القيم الجديدة
    AppConfigModel.fromJson({'theme_primary_color': '#010203'}).applyToPalette();
    expect(AppPalette.primary, const Color(0xFF010203));
    // نعيد اللوحة للافتراضي حتى لا تتأثر اختبارات أخرى
    AppPalette.resetToDefaults();
    expect(AppPalette.primary, const Color(0xFFA27E4E));
  });
}
