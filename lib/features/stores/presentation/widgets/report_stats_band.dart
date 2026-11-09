import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../utils/report_totals.dart';

/// شريط الإحصاءات المختصر — حقول صغيرة مرتّبة لا جملة أرقام متناثرة
/// The compact statistics strip — small tidy fields instead of a scatter of figures.
///
/// ── لماذا خانات لا سطر نصي في **الشريط الكامل**؟ لأن «الرصيد السابق: 12 · إجمالي الوارد: 40 …»
///    يجعل العين تبحث عن الفاصل بين كل رقمين، وتضيع المقارنة بين الوارد والمنصرف وهي أصل السؤال.
///    الخانة تفصل بالحدّ والوزن، فيُقرأ الشريط في نظرة واحدة.
/// ── Why boxes rather than one sentence in the **full strip**? "Opening: 12 · In: 40 …" leaves the
///    eye hunting for each separator and loses the inbound-versus-outbound comparison that is the
///    whole question. A box separates by border and weight, so the strip reads in one glance.
///
/// ── والحقول تأتي من `ReportStatFields` بالمعرّف نفسه الذي تخفيه نافذة الأعمدة، فلا يظهر
///    على الشاشة حقل أخفاه المستخدم ولا يغيب حقل طلبه.
/// ── The fields come from `ReportStatFields` under the same ids the columns sheet hides, so
///    no hidden field reappears and no requested one goes missing.
///
/// ── نمط `compact` مخصّص لإحصاء **القسم** داخل التقارير المتشعبة: أربعة أرقام في سطر واحد
///    يلتصق بذيل جدول القسم، لأن القسم يُقرأ في سياقه لا كتقرير مستقل.
/// ── The `compact` mode serves a **section's** statistics inside the sectioned reports: four
///    figures on one line glued to the foot of that section's table, because a section is read
///    in its own context rather than as a standalone report.
class ReportStatsBand extends StatelessWidget {
  const ReportStatsBand({
    super.key,
    required this.title,
    required this.fields,
  }) : compact = false;

  /// سطر إحصاء واحد في ذيل جدول القسم — عنوان صغير ثم الأرقام بجواره
  /// One statistics line at the foot of a section's table — a small caption beside the figures.
  const ReportStatsBand.compact({
    super.key,
    required this.title,
    required this.fields,
  }) : compact = true;

  final String title;
  final List<ReportStatField> fields;

  /// هل يُرسم سطراً واحداً أم شريطاً بخانات
  /// Whether it is drawn as one line or as a strip of boxes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      // الحشو رقيق في النمطين: الإحصاء تابع للجدول لا قسمٌ ثانٍ بجانبه
      // The padding stays thin in both modes: the statistics belong to the table, not beside it.
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: compact ? 0.04 : 0.05),
        // السطر المختصر يُغلق ذيل الجدول، فيأخذ زوايا سفلية فقط
        // The compact line closes the table's foot, so it keeps bottom corners only.
        borderRadius: compact
            ? const BorderRadius.vertical(bottom: Radius.circular(3))
            : BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: compact ? _line() : _strip(),
    );
  }

  /// السطر الواحد: العنوان ثم الأرقام بلا صناديق — لا التفاف إلا عند ضيق حقيقي
  /// The single line: the caption then the figures with no boxes — wraps only when truly tight.
  Widget _line() {
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          title,
          // لا const: `primary` قيمة مشتقة من لوحة الألوان لا ثابت
          // No const: primary is a derived palette value, not a literal.
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
        ),
        for (final field in fields) _InlineStat(field: field),
      ],
    );
  }

  /// الشريط الكامل: عنوان ثم خانات متساوية الوزن البصري
  /// The full strip: a caption then boxes of equal visual weight.
  Widget _strip() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final field in fields) _StatChip(field: field),
          ],
        ),
      ],
    );
  }
}

/// رقم داخل السطر المختصر: عنوان باهت صغير ثم قيمة بارزة — بلا إطار ولا حشو
/// A figure inside the compact line: a faint small caption then a prominent value — no frame.
class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.field});

  final ReportStatField field;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      // RTL صريح: العنوان قبل الرقم في القراءة العربية
      // Explicit RTL: the caption reads before its figure in Arabic.
      textDirection: TextDirection.rtl,
      children: [
        Text(
          field.label,
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          field.value,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: field.emphasis ? FontWeight.w800 : FontWeight.w700,
            color: _StatPalette.colorOf(field.color),
          ),
        ),
      ],
    );
  }
}

/// خانة إحصاء واحدة: عنوان صغير فوق قيمة بارزة، بعرض محتواها لا بعرض الشريط
/// One statistics chip: a small caption above a prominent value, as wide as its content.
class _StatChip extends StatelessWidget {
  const _StatChip({required this.field});

  final ReportStatField field;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            field.value,
            style: TextStyle(
              fontSize: field.emphasis ? 10 : 9.5,
              fontWeight: field.emphasis ? FontWeight.w800 : FontWeight.w700,
              color: _StatPalette.colorOf(field.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// لون الحقل من اسمه الدلالي — لا كائن لون يعبر حدود ملفات الأدوات
/// A field's colour from its semantic name — no colour object crosses a utils boundary.
class _StatPalette {
  _StatPalette._();

  static Color colorOf(String name) {
    switch (name) {
      case 'success':
        return AppColors.success;
      case 'error':
        return AppColors.error;
      case 'primary':
        return AppColors.primary;
      default:
        return AppColors.textPrimary;
    }
  }
}
