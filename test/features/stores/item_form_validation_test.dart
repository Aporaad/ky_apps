import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/store_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/stores/presentation/screens/item_form_screen.dart';

/// اختبارات نموذج الصنف — الشروط التي بلاها لا يظهر الصنف في أي رصيد
/// Item form tests — the conditions without which an item never reaches a balance.
///
/// ── النمط (`styl_no`) ليس حقلاً تجميلياً: الـ VIEW تربط `sanfs.styl_no` بـ`style.shape_style_no`،
///    فصنف بلا نمط يُحفظ ويبقى غير مرئي في كل تقرير وكل رصيد. النموذج يجب أن يمنعه.
/// ── The style is not cosmetic: the movement view joins sanfs.styl_no to
///    style.shape_style_no, so an item without one saves and stays invisible in every report
///    and every balance. The form must refuse it.
void main() {
  const reference = StoreReference(
    stores: [
      StoreModel(storeNo: 1, storeName: 'المحل الرئيسي'),
    ],
    groups: [
      StoreGroupModel(groupNo: 1, groupName: 'الأقمشة والمواد الخام'),
    ],
    types: [
      StoreTypeModel(typeNo: 101, typeName: 'الأقمشة', groupNo: 1),
    ],
    categories: [
      StoreCategoryModel(id: 4, name: 'صيني', catNo: 4),
    ],
    units: [
      StoreUnitModel(unitNo: 3, unitName: 'ثوب'),
    ],
    styles: [
      StoreStyleModel(id: 10101, name: 'قماش عرض 58', typeNo: 101, groupNo: 1),
      StoreStyleModel(id: 20101, name: 'ثياب جاهز رجالي', typeNo: 201, groupNo: 2),
    ],
  );

  Widget host() {
    return ProviderScope(
      overrides: [
        storeReferenceProvider.overrideWith((ref) async => reference),
      ],
      child: const MaterialApp(home: ItemFormScreen()),
    );
  }

  /// زر الحفظ داخل النموذج — يُبحث بالمسند لأن `ElevatedButton.icon` ينتج صنفاً فرعياً
  /// The form's save button, located by predicate because ElevatedButton.icon is a subclass.
  Finder saveButton() => find.ancestor(
    of: find.text('حفظ'),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );

  /// سطح اختبار طويل: النموذج ListView بطيء البناء، وزر الحفظ آخر عناصره فلا يُبنى
  /// أصلاً في مقاس الهاتف الافتراضي — و`ensureVisible` يحتاج عنصراً موجوداً.
  /// A tall surface: the form is a lazily built ListView and the save button is its last
  /// child, so it is never built at the default phone size — and ensureVisible needs an
  /// element that already exists.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('saving without a name or part number is refused locally', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(saveButton());
    await tester.pump();

    expect(find.text('اسم الصنف وكوده مطلوبان'), findsOneWidget);
  });

  testWidgets('an item without a style is refused before reaching the server', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'قماش اختبار');
    await tester.enterText(find.byType(TextField).at(1), '999000111');

    await tester.tap(saveButton());
    await tester.pump();

    // النمط ما زال غير مختار ⇒ رسالة تشرح أن النمط شرط ظهور
    // The style is still unset ⇒ the message explains it is the visibility condition.
    expect(
      find.textContaining('النمط مطلوبة'),
      findsOneWidget,
    );
  });

  test('the style list offers only the styles of the selected sub group', () {
    // النوع الافتراضي في النموذج هو 101، فنمط 20101 (لنوع 201) لا يجوز أن يُعرض
    // The form's default type is 101, so style 20101 (type 201) must not be offered.
    final shown = reference.stylesOfType(101).map((style) => style.id).toList();

    expect(shown, contains(10101));
    expect(shown, isNot(contains(20101)));

    // ونوع 201 يعطي نمطه وحده
    // Type 201 yields its own style only.
    expect(
      reference.stylesOfType(201).map((style) => style.id).toList(),
      [20101],
    );
  });
}
