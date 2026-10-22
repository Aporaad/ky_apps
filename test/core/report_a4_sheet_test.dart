import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/widgets/report_a4_sheet.dart';
import 'package:ky_apps/core/widgets/report_signature_footer.dart';

// ورقة التقرير على الشاشة لم تعد مقاس A4 ثابت: أصبحت بطاقة تملأ العرض حتى سقف
// معقول وتمتد بارتفاع محتواها الطبيعي، والتذييل يأتي بعد المتن فيسند الصفحة كاملة.
// A4 الحقيقي صار حكراً على مخرجات الطباعة/التصدير (PDF) لا على شاشة العرض.
// The on-screen sheet is no longer a fixed A4 page: it is a card that fills the
// width up to a cap and grows to its natural content height, footer after the body.
// Real A4 now belongs to the print/export (PDF) output only, not the screen.
void main() {
  group('ReportA4Sheet — content-sized card, footer at content end', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      double bodyHeight = 40,
      ReportSheetOrientation orientation = ReportSheetOrientation.portrait,
      double? maxPageWidth,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              // تمرير خارجي يحاكي تهيئة كل شاشات التقارير
              // Outer scroll, mirroring every report screen's real wrapper.
              body: SingleChildScrollView(
                child: ReportA4Sheet(
                  orientation: orientation,
                  maxPageWidth: maxPageWidth,
                  header: const Text('LETTERHEAD_BAND'),
                  title: const Text('REPORT_TITLE'),
                  meta: const Text('REPORT_META'),
                  body: SizedBox(height: bodyHeight, child: const Text('BODY')),
                  footer: const ReportSignatureFooter(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Finder pageFrame() => find
        .descendant(
          of: find.byType(ReportA4Sheet),
          matching: find.byType(Container),
        )
        .first;

    testWidgets('renders header, title, meta, body and footer together',
        (tester) async {
      await pumpSheet(tester);

      expect(find.text('LETTERHEAD_BAND'), findsOneWidget);
      expect(find.text('REPORT_TITLE'), findsOneWidget);
      expect(find.text('REPORT_META'), findsOneWidget);
      expect(find.text('BODY'), findsOneWidget);
      // التذييل الموحّد — خانات التوقيع الثلاث + الإشعار
      // The unified footer — three signature slots + the notice line.
      expect(find.text('توقيع المحاسب'), findsOneWidget);
      expect(find.text('توقيع أمين الصندوق'), findsOneWidget);
      expect(find.text('توقيع المدير'), findsOneWidget);
      expect(find.text(ReportSignatureFooter.notice), findsOneWidget);
    });

    testWidgets('footer sits BELOW the body (natural flow, not frozen)',
        (tester) async {
      await pumpSheet(tester);

      final bodyCenter = tester.getCenter(find.text('BODY'));
      final footerCenter = tester.getCenter(find.byType(ReportSignatureFooter));
      // في اتجاه رأسي، التذييل يجب أن يكون أسفل المتن (dy أكبر)
      // In a vertical column the footer must be below the body (greater dy).
      expect(footerCenter.dy, greaterThan(bodyCenter.dy),
          reason: 'التذييل يجب أن يأتي بعد المتن لا العكس');
    });

    testWidgets('fills the width up to the cap regardless of content height',
        (tester) async {
      await pumpSheet(tester, maxPageWidth: 300);

      final size = tester.getSize(pageFrame());
      // العرض = السقف المحدد (البطاقة تملأ المتاحة حتى السقف)
      // Width equals the requested cap — the card fills up to it.
      expect(size.width, closeTo(300, 1));
    });

    testWidgets('height grows with content — not a fixed A4 ratio',
        (tester) async {
      await pumpSheet(tester, maxPageWidth: 400, bodyHeight: 40);
      final short = tester.getSize(pageFrame());

      await pumpSheet(tester, maxPageWidth: 400, bodyHeight: 400);
      final tall = tester.getSize(pageFrame());

      // body أكبر ⇒ ورقة أعلى: الارتفاع تقوده المحتويات لا نسبة صفحة ثابتة
      // A taller body yields a taller sheet: height is content-driven.
      expect(tall.height, greaterThan(short.height));
      // النسبة ليست A4 الطولية (297/210 ≈ 1.4142) — لا صفحة ثابتة على الشاشة
      // The ratio is not the fixed portrait A4 page — no forced page on screen.
      expect(short.height / short.width, isNot(closeTo(297 / 210, 0.01)));
    });

    testWidgets('landscape uses a wider default cap than portrait',
        (tester) async {
      // نافذة أوسع من كلا السقفين حتى يظهر فرق السقف الافتراضي (1000 مقابل 1200)
      // A surface wider than both caps so the default caps (1000 vs 1200) show.
      await tester.binding.setSurfaceSize(const Size(1600, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpSheet(tester, orientation: ReportSheetOrientation.portrait);
      final portrait = tester.getSize(pageFrame());

      await pumpSheet(tester, orientation: ReportSheetOrientation.landscape);
      final landscape = tester.getSize(pageFrame());

      // السقف الافتراضي للعرضي (1200) أكبر من الطولي (1000)
      // The landscape default cap (1200) exceeds the portrait cap (1000).
      expect(landscape.width, greaterThan(portrait.width));
      expect(portrait.width, closeTo(1000, 1));
      expect(landscape.width, closeTo(1200, 1));
    });
  });
}
