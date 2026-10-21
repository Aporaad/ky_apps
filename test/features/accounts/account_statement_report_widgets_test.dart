import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_letterhead_info.dart';
import 'package:ky_apps/core/widgets/report_letterhead_branding.dart';
import 'package:ky_apps/features/accounts/data/models/chart_account_model.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_statement_report_footer.dart';
import 'package:ky_apps/features/accounts/presentation/widgets/account_statement_report_table.dart';

/// هوية الترويسة كما تأتي من إعدادات التطبيق — بالعربية وبالإنجليزية.
/// Letterhead identity as it comes from app config: Arabic and English sides.
const _letterhead = ReportLetterheadInfo(
  companyName: 'الكبودي للخياطة الرجالية',
  companyNameEn: "ALKABODI FOR MEN's TAILORING",
  address: 'صنعاء - شارع الحسن',
  addressEn: 'Al-Hassan Street - Sanaa',
  phone: '780154000',
  website: '',
);

/// بيانات حقيقية من حادثة الفيض: وصف عربي طويل جداً + أرقام كبيرة.
/// Real overflow-incident data: a very long Arabic description + big amounts.
const _longDescription =
    'يقيد على حساب (ايمن زياد الشويع) من حساب نجيب عبدالله القديمي -- من قيمة فاتورة رقم 7091';

const _transactions = [
  AccountTransactionModel(
    entryNo: 4250012432,
    subEntryNo: '42432',
    date: '27/03/2025',
    entryTypeName: 'تسوية ك -دائنة',
    description: _longDescription,
    debit: 28000,
    credit: 0,
    balance: 28000,
  ),
  AccountTransactionModel(
    entryNo: 4250013776,
    subEntryNo: '43776',
    date: '15/04/2025',
    entryTypeName: 'قيد يومية',
    description: 'لكم مقابل المبلغ المقيد عليكم بالغلط بتاريخ 29/03/2025',
    debit: 0,
    credit: 28000,
    balance: 0,
  ),
];

Widget _buildReport() {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: MediaQuery(
      // نفس قيد التطبيق: تكبير خط المستخدم حتى 1.25× (سبب الفيض الأصلي)
      // Same app clamp: user text scale up to 1.25× (the overflow trigger).
      data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
      child: SingleChildScrollView(
        child: Column(
          children: const [
            AccountStatementLetterhead(
              letterhead: _letterhead,
              accName: 'ايمن زياد الشويع',
              accNo: 11010001,
              currency: 'يمني YR',
              fromDate: '2025/03/01',
              toDate: '2025/04/15',
            ),
            AccountStatementReportTable(
              transactions: _transactions,
              openingBalance: 0,
              finalBalance: 0,
              totalDebit: 28000,
              totalCredit: 28000,
            ),
            AccountStatementReportFooter(
              openingBalance: 0,
              totalDebit: 28000,
              totalCredit: 28000,
              finalBalance: 0,
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: _buildReport())));
  await tester.pumpAndSettle();
}

void main() {
  group('Account statement report overflow regression (1.25× text scale)', () {
    // الفيض الأصلي: 157px في ترويسة الجدول + 44px في التذييل على هاتف عادي.
    // The original incident: 157px in the table letterhead + 44px in the footer.
    testWidgets('renders without RenderFlex overflow on a 360px phone',
        (WidgetTester tester) async {
      await _pumpAt(tester, const Size(360, 800));

      expect(tester.takeException(), isNull,
          reason: 'letterhead/footer Rows must flex instead of overflowing');
      // 'من تاريخ:' الخاصة بالترويسة وحدها — تنويه التذييل يقول 'من تاريخ إصداره'
      // Match the letterhead's own label: the footer disclaimer also says 'من تاريخ'.
      expect(find.textContaining('من تاريخ:'), findsOneWidget);
      expect(find.textContaining('توقيع المدير'), findsOneWidget);
    });

    testWidgets('the letterhead carries the configured company identity',
        (WidgetTester tester) async {
      await _pumpAt(tester, const Size(360, 800));

      // نفس المعلومات على الجانبين: العربي بالأرقام الهندية والإنجليزي باللاتينية
      // Same information on both sides: Arabic-Indic digits vs Latin ones.
      expect(find.text('الكبودي للخياطة الرجالية'), findsOneWidget);
      expect(find.text("ALKABODI FOR MEN's TAILORING"), findsOneWidget);
      expect(find.text('صنعاء - شارع الحسن'), findsOneWidget);
      expect(find.text('Al-Hassan Street - Sanaa'), findsOneWidget);
      expect(find.text('هاتف: ٧٨٠١٥٤٠٠٠'), findsOneWidget);
      expect(find.text('Tel: 780154000'), findsOneWidget);
    });

    testWidgets('the letterhead is a three-column band: Arabic | logo | English',
        (WidgetTester tester) async {
      await _pumpAt(tester, const Size(700, 900));

      // الشعار وحده في العمود الأوسط، والكتلتان عن يمينه وعن يساره
      // One logo in the middle column, with the two text blocks either side of it.
      expect(find.byType(ReportLetterheadBranding), findsOneWidget);
      final logo = find.byType(Image);
      expect(logo, findsOneWidget);

      final arabicName = tester.getTopLeft(find.text('الكبودي للخياطة الرجالية'));
      final englishName = tester.getTopLeft(find.text("ALKABODI FOR MEN's TAILORING"));
      final logoLeft = tester.getTopLeft(logo);

      // الشاشة RTL: الكتلة العربية يجب أن تكون أقصى اليمين والإنجليزية أقصى اليسار،
      // والشعار بينهما — وإلا فإن الترويسة انقلبت إلى عمود واحد موسّط.
      expect(arabicName.dx, greaterThan(englishName.dx),
          reason: 'the Arabic block must sit to the right of the English block');
      expect(logoLeft.dx, greaterThan(englishName.dx));
      expect(logoLeft.dx, lessThan(arabicName.dx));
    });

    testWidgets('renders without overflow on a narrow 320px phone',
        (WidgetTester tester) async {
      await _pumpAt(tester, const Size(320, 640));

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without overflow at default 1.0 text scale',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(child: _buildReport()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the long real-world description is fully present',
        (WidgetTester tester) async {
      await _pumpAt(tester, const Size(360, 800));

      // الوصف الطويل يجب أن يظهر كاملاً (ملفوفاً على أسطر) وليس مقطوعاً
      // The long description must be present (wrapped), not clipped away.
      expect(find.textContaining('فاتورة رقم 7091'), findsOneWidget);
    });
  });
}
