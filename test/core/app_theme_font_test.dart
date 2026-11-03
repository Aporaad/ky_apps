import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/theme/app_palette.dart';
import 'package:ky_apps/core/theme/app_theme.dart';

void main() {
  group('AppTheme — bundled Cairo family (no synthetic bold)', () {
    setUp(AppPalette.resetToDefaults);

    test('default palette (Cairo) resolves the theme family to the bundled Cairo',
        () {
      // الخط الافتراضي Cairo؛ يجب أن تُستخدم العائلة المضمّنة 'Cairo' مباشرة
      // (بوزنها الحقيقي) لا اسم عائلة ناتج من google_fonts عبر الشبكة.
      final theme = AppTheme.build();
      // عائلة السمة تُطبّق على كامل الـ TextTheme؛ نتحقق عبر نمط النص الأساسي.
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Cairo');
      // عنوان AppBar عريض — يجب أن يبقى على عائلة Cairo الحقيقية.
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Cairo');
      expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.bold);
      // نص الأزرار العريض كذلك.
      final btn = theme.elevatedButtonTheme.style?.textStyle
              ?.resolve(const <WidgetState>{}) ??
          const TextStyle();
      expect(btn.fontFamily, 'Cairo');
    });
  });
}
