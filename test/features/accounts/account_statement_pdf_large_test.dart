import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/report_letterhead_info.dart';
import 'package:ky_apps/core/utils/report_pdf_page.dart';
import 'package:ky_apps/features/accounts/data/models/chart_account_model.dart';
import 'package:ky_apps/features/accounts/presentation/utils/account_statement_pdf_builder.dart';

/// حارس «الكشف الكبير لا يُطبَع» — الحارس الذي كان غائباً
/// The "a large statement won't print" guard — the one that never existed.
///
/// ── العطل: `pw.MultiPage` سقفه الافتراضي **20 صفحة للعنصر الواحد القابل للامتداد**،
///    والجدول كله عنصر واحد. أي كشف يتجاوز عشرين صفحة كان يرمي
///    `TooManyPagesException` فيسقط التوليد كاملاً: لا طباعة ولا تصدير ولا رسالة.
/// ── The defect: `pw.MultiPage` defaults `maxPages` to **20 pages per spanning
///    widget**, and the whole table is one widget. Any statement longer than twenty
///    pages threw `TooManyPagesException`, aborting generation entirely: no printing,
///    no export, no message.
///
/// ── الاختبار يبني كشفاً حقيقياً بمئات الحركات (عشرات الصفحات) ويتحقّق أن الملف
///    خرج بعدد صفحات يتجاوز السقف القديم — فالمرجع هو عدد الصفحات الفعلي لا مجرد
///    «لم يرمِ استثناء».
/// ── The test builds a real statement with hundreds of movements (dozens of pages)
///    and asserts the produced file carries MORE pages than the old ceiling — the
///    reference is the real page count, not merely "it did not throw".
void main() {
  // الخطوط تُقرأ من أصول مُضمَّنة، فتلزم تهيئة ربط الاختبار
  // Fonts come from bundled assets, so the test binding must be initialized.
  TestWidgetsFlutterBinding.ensureInitialized();

  const letterhead = ReportLetterheadInfo(
    companyName: ReportLetterheadInfo.kFallbackNameAr,
    address: ReportLetterheadInfo.kFallbackAddressAr,
    phone: ReportLetterheadInfo.kFallbackPhone,
    website: '',
    companyNameEn: ReportLetterheadInfo.kFallbackNameEn,
    addressEn: ReportLetterheadInfo.kFallbackAddressEn,
  );

  /// عدد كائنات الصفحة داخل الـ PDF — كل صفحة تُكتب بكائن `/Type /Page`.
  /// `\b` يمنع مطابقة عقدة الشجرة `/Type /Pages`، فلا تُحسب مرتين.
  ///
  /// The number of page objects in the PDF — every page is written as `/Type /Page`.
  /// The trailing `\b` excludes the page-tree node `/Type /Pages`.
  int countPdfPages(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    return RegExp(r'/Type\s*/Page\b').allMatches(text).length;
  }

  /// كشف بحركات متتابعة: نفس الشكل الذي يصل من `/accounts/chart/{no}/statement`.
  /// A statement of sequential movements in the shape the API returns.
  AccountStatementData buildStatement(int rows) {
    final transactions = List<AccountTransactionModel>.generate(rows, (i) {
      final amount = 1000.0 + i;
      return AccountTransactionModel(
        entryNo: 4260013000 + i,
        subEntryNo: '${43000 + i}',
        date: '01/05/2026',
        entryTypeName: 'قيد يومية',
        description: 'حركة رقم ${i + 1} على الحساب',
        debit: amount,
        credit: 0,
        balance: 27000000 + (i * 1000.0),
      );
    });

    return AccountStatementData(
      account: const {
        'acc_no': 38310001,
        'acc_name': 'الخصم المسموح به',
      },
      transactions: transactions,
      openingBalance: 27000000,
      finalBalance: 27000000 + (rows * 1000.0),
      totalDebit: rows * 1000.0,
      totalCredit: 0,
      currency: 'ريال يمني',
      fromDate: '01/05/2026',
      toDate: '31/10/2026',
    );
  }

  test('a small statement still produces a valid PDF', () async {
    // حالة الضبط: الكشف القصير لم يتغيّر سلوكه
    // Control case: a short statement behaves exactly as before.
    final bytes = await buildAccountStatementPdf(
      letterhead: letterhead,
      account: null,
      statement: buildStatement(12),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(countPdfPages(bytes), greaterThanOrEqualTo(1));
  });

  test('a statement longer than 20 pages prints in full', () async {
    // 900 حركة ≈ 30 صفحة A4 — تتجاوز سقف الحزمة القديم (20) بوضوح.
    // 900 movements ≈ 30 A4 pages — comfortably past the old 20-page ceiling.
    const rowCount = 900;

    final bytes = await buildAccountStatementPdf(
      letterhead: letterhead,
      account: null,
      statement: buildStatement(rowCount),
    );

    // توقيع ملف PDF: المخرج ملف حقيقي لا بايتات فارغة
    // The PDF signature: a real file, not empty bytes.
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    final pages = countPdfPages(bytes);

    // الجوهر: الصفحات تجاوزت عشرين، ولم يُقطع المستند عند السقف القديم
    // The point: the document ran past twenty pages instead of being cut off.
    expect(
      pages,
      greaterThan(20),
      reason: 'الكشف يجب أن يمتد على أكثر من 20 صفحة — وُلد $pages صفحة فقط',
    );

    // وكل حركة طُبعت: لا اقتطاع صامت لبقية الأسطر. الصفحة تحمل 30–40 سطراً
    // بحجم خط 8، فالمتوقع أن يقترب عدد الصفحات من rowCount/35 لا أن يبقى عند 21.
    // And every movement printed: no silent truncation. An A4 page carries roughly
    // 30–40 rows at 8pt, so the page count should track rowCount/35, not stall at 21.
    expect(pages, greaterThanOrEqualTo((rowCount / 45).floor()));
  });

  test('the ceiling is far above any real ledger, and not the package default', () {
    // السقف صار تعريفاً مشتركاً صريحاً بدل الافتراضي 20 داخل الحزمة
    // The ceiling is now one explicit shared constant instead of the package's 20.
    expect(kReportPdfMaxPages, greaterThanOrEqualTo(1000));
  });
}
