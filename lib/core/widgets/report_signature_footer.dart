import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// تذييل التوقيعات الرسمي الموحّد لكل كشوفات التقارير — ثلاثة خانات توقيع
/// (المحاسب / أمين الصندوق / المدير) + سطر إشعار المراجعة خلال 15 يوماً.
///
/// يُستخدم في الاستعراض على الشاشة داخل [ReportA4Sheet]، وصيغته النصية مطابقة
/// تماماً لما يرسمه `pdfSignatures()` في طباعة/تصدير PDF، فيبقى ما يراه المستخدم
/// وما يُطبع متطابقين.
///
/// The unified official signature footer for every report: three signature slots
/// (accountant / cashier / manager) plus the 15-day review notice. Rendered on screen
/// inside [ReportA4Sheet]; its wording matches `pdfSignatures()` in the PDF exactly, so
/// what is viewed and what is printed stay identical.
class ReportSignatureFooter extends StatelessWidget {
  const ReportSignatureFooter({super.key});

  /// نص الإشعار الموحّد — نفس نص الـ PDF حرفياً.
  /// Canonical notice text — byte-for-byte the same as the PDF's.
  static const String notice =
      'يجب مراجعة هذا الكشف خلال 15 يوماً من تاريخ إصداره، وما بعد ذلك يُعتبر معتمداً.';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            _Slot(label: 'توقيع المحاسب'),
            _Slot(label: 'توقيع أمين الصندوق'),
            _Slot(label: 'توقيع المدير'),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          notice,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// خانة توقيع واحد — سطر أفقي + تسمية تحته، موزّعة بالتساوي عبر العرض.
/// One signature slot — a rule with a caption beneath it, evenly sharing the width.
class _Slot extends StatelessWidget {
  const _Slot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: double.infinity,
              child: Divider(color: Color(0xFF6B7280), thickness: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
