import 'package:flutter/material.dart';

import '../utils/report_letterhead_info.dart';

/// ترويسة التقارير الرسمية بثلاثة أعمدة — كما في الترويسة المطبوعة:
/// اليمين اسم الشركة بالعربية وتحته العنوان وأرقام التواصل، المنتصف شعار الشركة،
/// اليسار الاسم والعنوان وأرقام التواصل بالإنجليزية.
/// The official report letterhead as a three-column band, matching the printed header:
/// right = Arabic company name over its address and contact numbers, center = the company
/// logo, left = the same name/address/contact information in English.
///
/// الأعمدة `Expanded` بنِسَب (5 : 4 : 5) فلا تفيش الترويسة مهما ضاقت الشاشة أو كَبُر
/// خط المستخدم (قيد التطبيق 1.25×)؛ أحجام الخطوط مشتقّة من العرض المتاح.
/// The columns are ratio-sized `Expanded` cells (5 : 4 : 5) so the band never overflows on a
/// narrow screen or under the app's 1.25× text-scale clamp; font sizes derive from the width.
class ReportLetterheadBranding extends StatelessWidget {
  const ReportLetterheadBranding({
    super.key,
    required this.info,
    this.logoAsset = 'assets/logo3.jpg',
    this.logoHeight = 78,
  });

  final ReportLetterheadInfo info;

  /// الشعار في المنتصف — نفس الأصل المستخدم في كل شاشات التطبيق
  /// The centered logo — the same asset used across the app.
  final String logoAsset;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
        final isNarrow = width < 380;

        // مقياس خط متناسب مع عرض العمود: يبقى العنوان مقروءاً على 320px
        // Width-proportional type scale: the name stays readable even at 320 px.
        final nameSize = (width / 42).clamp(8.5, 13.5);
        final detailSize = (width / 62).clamp(7.0, 10.5);
        final gap = isNarrow ? 6.0 : 14.0;
        final boxHeight = isNarrow ? logoHeight * 0.72 : logoHeight;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // اليمين (بداية اتجاه RTL): الكتلة العربية
            // Right side (RTL start): the Arabic block.
            Expanded(
              flex: 6,
              child: _InfoColumn(
                lines: info.arabicLines,
                direction: TextDirection.rtl,
                nameFontSize: nameSize,
                detailFontSize: detailSize,
              ),
            ),
            SizedBox(width: gap),

            // المنتصف: شعار الشركة
            // Center: the company logo.
            Expanded(
              flex: 3,
              child: Center(
                child: Image.asset(
                  logoAsset,
                  height: boxHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SizedBox(height: boxHeight),
                ),
              ),
            ),
            SizedBox(width: gap),

            // اليسار: الكتلة الإنجليزية باتجاه LTR حتى لا ينعكس ترتيب كلماتها
            // Left side: the English block, forced LTR so its word order never mirrors.
            Expanded(
              flex: 6,
              child: _InfoColumn(
                lines: info.englishLines,
                direction: TextDirection.ltr,
                nameFontSize: nameSize-2,
                detailFontSize: detailSize-2,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// عمود معلومات الترويسة: السطر الأول هو اسم الشركة بخط أعرض، وما بعده عنوان/تواصل.
/// One letterhead information column: the first line is the company name in a heavier, larger
/// style; everything after it is address/contact detail.
class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.lines,
    required this.direction,
    required this.nameFontSize,
    required this.detailFontSize,
  });

  final List<String> lines;
  final TextDirection direction;
  final double nameFontSize;
  final double detailFontSize;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: Column(
        // mainAxisSize.min: ارتفاع الصف داخل ترويسة رأسية غير محدود
        // min sizing: the row sits inside an unbounded vertical header.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            Text(
              lines[i],
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: i == 0 ? nameFontSize : detailFontSize,
                fontWeight: i == 0 ? FontWeight.w900 : FontWeight.w600,
                color: i == 0 ? Colors.black : Colors.black87,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
