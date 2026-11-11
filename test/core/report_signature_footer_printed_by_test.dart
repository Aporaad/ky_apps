import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/widgets/report_signature_footer.dart';
import 'package:ky_apps/core/utils/report_print_identity.dart';

// حرّاس سطر «بواسطة» في التذييل الرسمي الموحّد: من يطبع المستند يُنسب إليه بالاسم،
// وبلا جلسة لا تظهر النسبة إطلاقاً (مستند رسمي لا يوقّع باسم مجهول).
// Guards for the «بواسطة» credit in the unified official footer: the printer is named on the
// document, and with no session the credit never appears — an official document is never
// attributed to an unknown printer.
void main() {
  Widget host() => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: const ReportSignatureFooter()),
        ),
      );

  tearDown(() => ReportPrintIdentity.clear());

  testWidgets('credits the printing user beside the issue timestamp',
      (tester) async {
    ReportPrintIdentity.set('محمد الشرفي');

    await tester.pumpWidget(host());

    // السطر كامل: التوقيت ثم بواسطة — كلاهما في نص واحد أسفل التذييل
    // One line at the footer's end: the timestamp then the printer's name.
    expect(find.textContaining('توقيت الإصدار:'), findsOneWidget);
    expect(find.textContaining('بواسطة: محمد الشرفي'), findsOneWidget);
  });

  testWidgets('omits the credit when nobody is signed in', (tester) async {
    ReportPrintIdentity.clear();

    await tester.pumpWidget(host());

    expect(find.textContaining('توقيت الإصدار:'), findsOneWidget);
    expect(find.textContaining('بواسطة'), findsNothing);
  });

  test('blank names are normalised to no identity', () {
    ReportPrintIdentity.set('   ');
    expect(ReportPrintIdentity.printedBy, isNull);

    ReportPrintIdentity.set('خالد');
    expect(ReportPrintIdentity.printedBy, 'خالد');
  });
}
