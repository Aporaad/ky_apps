import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/item_model.dart';
import 'package:ky_apps/features/stores/presentation/widgets/order_line_editor.dart';

/// اختبارات محرر سطور المستند — الإجمالي والتحقق من المتاح
/// Document line editor tests — the line total and the availability check.
///
/// ── ما يحرسه هذا الملف: أن المستخدم يرى أن الكمية تتجاوز المتاح **قبل** الإرسال. الخادم يرفض
///    أيضاً، لكن الرفض بعد الحفظ يجعل المستخدم يعيد إدخال سطر كامل بلا سبب ظاهر.
/// ── What this guards: the user sees an over-quantity warning before submitting. The server
///    refuses too, but a refusal after saving forces the user to re-enter a whole line.
void main() {
  ItemModel item({String name = 'قماش تايلندي'}) => ItemModel(
    sanfNo: 666,
    partNo: '20106001',
    name: name,
    unitName: 'ثوب',
  );

  ItemSubModel sub() =>
      ItemSubModel(sanfDno: 2010602208, sanfNo: 666, len: 58, wid: 3, colorNo: 4);

  Widget host(List<OrderLineDraft> lines, {ValueChanged<List<OrderLineDraft>>? onChange}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderLineEditor(
              lines: lines,
              storeNo: 1,
              onChanged: onChange ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('an empty document invites the first line', (tester) async {
    await tester.pumpWidget(host(const []));

    expect(find.text('لا سطور بعد — ابدأ بإضافة صنف'), findsOneWidget);
  });

  testWidgets('the line total is quantity times price', (tester) async {
    final draft = OrderLineDraft(
      item: item(),
      sub: sub(),
      qty: 5,
      price: 100,
    );

    await tester.pumpWidget(host([draft]));

    // 5 × 100 = 500.00 كما يعرضه تنسيق المبالغ
    // 5 × 100 = 500.00 in the app's money format.
    expect(find.text('500.00'), findsOneWidget);
    expect(find.text('الكمية أكبر من المتاح (3)'), findsNothing);
  });

  testWidgets('a line over the available quantity is flagged before saving', (tester) async {
    final over = OrderLineDraft(
      item: item(),
      sub: sub(),
      qty: 9,
      price: 100,
      available: 4,
    );

    await tester.pumpWidget(host([over]));

    expect(find.text('الكمية أكبر من المتاح (4)'), findsOneWidget);
  });

  testWidgets('a line within the available quantity shows what is left', (tester) async {
    final within = OrderLineDraft(
      item: item(),
      sub: sub(),
      qty: 2,
      price: 100,
      available: 12,
    );

    await tester.pumpWidget(host([within]));

    expect(find.text('المتاح في المخزن: 12'), findsOneWidget);
  });

  testWidgets('editing the quantity reports the change upward', (tester) async {
    final draft = OrderLineDraft(item: item(), sub: sub(), qty: 1, price: 100);
    var latest = <OrderLineDraft>[];

    await tester.pumpWidget(host([draft], onChange: (lines) => latest = lines));

    // أول حقل رقمي في السطر هو الكمية
    // The first numeric field on the line is the quantity.
    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.pump();

    expect(latest, isNotEmpty);
    expect(latest.first.qty, 7);
  });

  testWidgets('a line without a store cannot be added', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: OrderLineEditor(
              lines: const [],
              storeNo: null,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // بلا مخزن لا معنى لإضافة سطر: التحقق من المتاح يحتاج مخزناً
    // Without a store a line cannot be validated, so adding is disabled.
    //
    // `TextButton.icon` ينتج صنفاً فرعياً لا `TextButton` بالضبط، فنبحث بالمسند لا بالنوع
    // الصريح — وإلا لم نجد الزر أصلاً.
    // TextButton.icon yields a subclass, not TextButton exactly, so the button is located by
    // predicate rather than by exact type.
    final buttonFinder = find.ancestor(
      of: find.text('إضافة سطر'),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );

    expect(buttonFinder, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(buttonFinder).onPressed, isNull);
  });
}
