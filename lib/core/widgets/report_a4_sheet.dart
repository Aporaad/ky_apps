import 'package:flutter/material.dart';

/// اتجاه ورقة التقرير على الشاشة — يُستخدم فقط لاختيار السقف الأقصى للعرض؛
/// مقاس A4 الحقيقي يُطبَّق في مخرجات الطباعة/التصدير (PDF) وليس على الشاشة.
/// On-screen orientation — used only to pick the max content width. The real A4
/// page size is applied in the print/export (PDF) output, NOT on the screen.
enum ReportSheetOrientation { portrait, landscape }

/// صفحة التقرير الموحّدة على الشاشة: بطاقة بيضاء بعرض يملأ المساحة المتاحة (إلى
/// سقف معقول)، تمتد بطول محتوياتها فعلياً، والتذييل يأتي في نهاية المحتوى ويتحرك
/// معه عند التمرير الطبيعي للصفحة كاملة — لا تجميد للتذييل ولا تصغير للتقرير.
///
/// The unified on-screen report page: a white card that fills the available width
/// (up to a sensible cap), grows to its real content height, and places the footer
/// at the END of the content so it scrolls with the whole page — no frozen footer
/// and no shrunken report. A4 sizing belongs to the PDF output only.
///
/// يُغلَّف داخل `InteractiveViewer` + `SingleChildScrollView` في كل شاشة تقرير
/// (تمرير طبيعي + تكبير/تصغير).
/// Meant to sit inside each report screen's `InteractiveViewer` + outer
/// `SingleChildScrollView` (natural scrolling + pinch zoom).
class ReportA4Sheet extends StatelessWidget {
  const ReportA4Sheet({
    super.key,
    this.header,
    required this.body,
    this.orientation = ReportSheetOrientation.portrait,
    this.title,
    this.meta,
    this.footer,
    this.maxPageWidth,
  });

  /// شريط الترويسة الرسمي (ReportLetterheadBranding عادةً). اختياري.
  /// The official letterhead band (normally a [ReportLetterheadBranding]). Optional.
  final Widget? header;

  /// متن التقرير (الجدول) — يُرسم بحجمه الطبيعي ضمن عمود الصفحة.
  /// The report body (the table) — laid out at its natural height inside the page.
  final Widget body;

  final ReportSheetOrientation orientation;

  /// عنوان التقرير المختار بين الترويسة والجسم.
  /// Optional report title shown between the letterhead and the body.
  final Widget? title;

  /// شريط بيانات التقرير (الحساب/الفترة/العملة…).
  /// Optional report meta band (account / period / currency …).
  final Widget? meta;

  /// التذييل الرسمي (توقيعات + إشعار 15 يوماً) — يأتي في نهاية المحتوى.
  /// The official footer (signatures + 15-day notice) — placed after the content.
  final Widget? footer;

  /// السقف الأقصى لعرض البطاقة بالبكسل.
  /// Optional max card width in px.
  final double? maxPageWidth;

  @override
  Widget build(BuildContext context) {
    // عرض منطقي يملأ الشاشة حتى سقف معقول؛ الطول = طول المحتوى الطبيعي.
    // Width fills the screen up to a cap; height is the content's natural height.
    final cap = maxPageWidth ??
        (orientation == ReportSheetOrientation.portrait ? 1000.0 : 1200.0);

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: cap),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1) الترويسة الرسمية الموحّدة / official letterhead
            if (header != null) ...[header!, const SizedBox(height: 8)],
            // 2) عنوان التقرير / report title
            if (title != null) ...[title!, const SizedBox(height: 8)],
            // 3) شريط البيانات / meta band
            if (meta != null) ...[meta!, const SizedBox(height: 12)],
            // 4) المتن بحجمه الطبيعي / body at natural size
            body,
            // 5) التذييل الرسمي في نهاية المحتوى / footer after the content
            if (footer != null) ...[const SizedBox(height: 14), footer!],
          ],
        ),
      ),
    );
  }
}
