import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/report_print_identity.dart';

/// تذييل التوقيعات الرسمي الموحّد لكل كشوفات التقارير — ثلاثة خانات توقيع
/// (المحاسب / أمين المخزن أو الصندوق / المدير) + سطر إشعار المراجعة خلال 15 يوماً.
///
/// يُستخدم في الاستعراض على الشاشة داخل [ReportA4Sheet]، وصيغته النصية مطابقة
/// تماماً لما يرسمه `pdfSignatures()` في طباعة/تصدير PDF، فيبقى ما يراه المستخدم
/// وما يُطبع متطابقين.
///
/// ── الخانة الوسطى تتبع القسم: مخازن لها أمين مخزن، وحسابات لها أمين صندوق. اسم
///    غير صاحبه على مستند رسمي يجعله يوقّع ما لا يملكه أو يرفض التوقيع أصلاً.
/// ── The middle slot follows the department: a store has a storekeeper, accounts have a
///    cashier. Putting the wrong title on an official document makes its holder sign what is
///    not theirs — or refuse to sign at all.
///
/// The unified official signature footer for every report: three signature slots
/// (accountant / storekeeper or cashier / manager) plus the 15-day review notice. Rendered on
/// screen inside [ReportA4Sheet]; its wording matches `pdfSignatures()` in the PDF exactly, so
/// what is viewed and what is printed stay identical.
class ReportSignatureFooter extends StatelessWidget {
  const ReportSignatureFooter({
    super.key,
    this.keeper = cashier,
  });

  /// توقيع أمين الصندوق — الأصل في تقارير الحسابات والأقسام الأخرى
  /// The cashier's slot: the default for accounts and every other department.
  static const String cashier = 'توقيع أمين الصندوق';

  /// توقيع أمين المخزن — تقارير المخازن وحدها
  /// The storekeeper's slot: stores reports only.
  static const String storekeeper = 'توقيع أمين المخزن';

  /// خانة الوسط — يمرّرها كل قسم بما يخصّه
  /// The middle slot, passed by each department as it applies to them.
  final String keeper;

  /// نص الإشعار الموحّد — نفس نص الـ PDF حرفياً.
  /// Canonical notice text — byte-for-byte the same as the PDF's.
  static const String notice =
      'يجب مراجعة هذا الكشف خلال 15 يوماً من تاريخ إصداره، وما بعد ذلك يُعتبر معتمداً.';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
        final timestamp =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // سطر الإصدار الرسمي: الوقت + نِسبة الطبع للمستخدم الحالي عند الحاجة.
    // Canonical issue line: the timestamp plus, when a session exists, the printing user.
    final printedBy = ReportPrintIdentity.printedBy;
    final issueLine = printedBy == null
        ? 'توقيت الإصدار: $timestamp'
        : 'توقيت الإصدار: $timestamp    بواسطة: $printedBy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _Slot(label: 'توقيع المحاسب'),
            _Slot(label: keeper),
            const _Slot(label: 'توقيع المدير'),
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
        Text(
                issueLine,
                style: const TextStyle(
                  fontSize: 7,
                  color: Colors.black54,
                ),
              )        
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
