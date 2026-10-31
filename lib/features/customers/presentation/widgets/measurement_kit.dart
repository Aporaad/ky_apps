import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// طقم عناصر التصميم المشترك بين شاشات «مقاسات العملاء»
/// The shared design kit of the customer-measurement screens.
///
/// لماذا طقم خاص بالميزة؟ شاشة المقاسات تقرير مضغوط لا نموذج إدخال: تحتاج ترويسة قسم صريحة،
/// وتبايناً عالياً بين التسمية والقيمة، وفواصل تفصل الحقول فعلاً لا فراغاً بصرياً. نسخ هذه
/// القرارات في كل ودجت يعني أربعة شاشات بأربعة أشكال بعد أول تعديل، فهي هنا مرة واحدة.
/// Why a feature-local kit? The measurements screen is a dense report, not a form: it needs an
/// explicit section header, high label/value contrast, and separators that actually separate.
/// Repeating those decisions per widget gives four look-alikes after the first tweak, so they are
/// written once here.
///
/// التباين مقصود: التسمية `textSecondary` بوزن نصف عريض والقيمة `textPrimary` بوزن عريض أكبر
/// منها درجتين، فلا تضيع القيمة في رمادي فاتح كما في الشعار القديم.
/// The contrast is deliberate: the label is `textSecondary` at w600 and the value `textPrimary`
/// two units larger and bold, so a value never drowns in light grey as it did before.
class MeasurementKit {
  MeasurementKit._();

  /// حشوة موحّدة داخل كل بطاقة قسم
  /// One padding for the body of every section card.
  static const double bodyPadding = 10;

  /// مسافة رأسية قصيرة بين الأقسام — الشاشة تقرير طويل Narrow spacing keeps the sheet a report, not a stack of boxes.
  static const double sectionGap = 10;
}

/// بطاقة قسم: شريط عنوان بلون Accent كامل + جسم أبيض
/// A section card: a solid accent title bar over a white body.
class MeasurementSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  /// `null` تعني اللون الأساسي وقت الرسم: الأساسي ديناميكي فلا يصلح قيمة افتراضية `const`
  /// `null` means the primary colour at paint time: that colour is dynamic, so it cannot be a
  /// `const` default value.
  final Color? accent;
  final Widget child;

  /// عنصر في طرف شريط العنوان (شارة عدد، مفتاح إظهار…)
  /// A trailing item in the title bar (a count chip, a visibility switch…).
  final Widget? trailing;

  /// سطر ثانوي تحت العنوان — يُستخدم لاسم العميل/المستفيد فلا تُكرّر المعلومة داخل الحقول
  /// A subtitle line under the title — used for the customer/beneficiary so fields never repeat it.
  final String? subtitle;

  /// شارة في طرف العنوان — تُرسم دائماً أبيض على Accent لأن الترويسة صارت مصمتة
  /// A title-bar badge, always drawn white-on-accent now that the header itself is solid.
  final String? trailingText;

  const MeasurementSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.accent,
    this.trailing,
    this.trailingText,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // اللون يُحسم وقت الرسم لا في سياق const: اللون الديناميكي لا يصلح ثابتاً
    // The colour is resolved at paint time, never in a const context: a dynamic colour cannot be.
    final tone = accent ?? AppColors.primary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              // ترويسة مصمتة بالكامل: الشريط الشفاف—even at 20%—كان يبدو «باهتاً» على الورق
              // الأبيض، والحكم البصري الذي رُفض التصميم من أجله لا يُصلَح بشفافية أقل.
              // A fully solid header: a translucent strip — even at 20% — still reads as faded on
              // white, and the visual verdict that rejected the design is not fixed by less alpha.
              gradient: LinearGradient(
                colors: [tone, tone.withValues(alpha: 0.82)],
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (trailingText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      trailingText!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (trailing != null)
                  trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(MeasurementKit.bodyPadding),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// خانة حقل: تسمية صغيرة نصف عريضة وفوقها قيمة عريضة داكنة
/// A field cell: a small semi-bold label over a bold, dark value.
class MeasurementField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData? icon;

  /// لون القيمة — يُترك افتراضياً داكناً، ويُلوَّن فقط للدلالات (مرحلة، تأكيد…)
  /// The value colour: dark by default, tinted only where it carries meaning.
  final Color? valueColor;

  /// خانات الأرقام (الهنش/اليارد/السعر) تُحاذى يساراً كي تُقرأ الأعمدة تقميماً
  /// Numeric cells align left so a column of figures reads like a column.
  final bool numeric;

  /// وضع مضغوط لسلاسل الأعمدة الطويلة (الأقمشة): كل عمود داخل عرض الشاشة بلا تمرير أفقي
  /// The dense mode for wide row shapes (fabrics): every column fits the screen, no horizontal
  /// scrolling to reach the rest of them.
  final bool dense;

  const MeasurementField({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.valueColor,
    this.numeric = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = (value == null || value!.trim().isEmpty) ? '—' : value!.trim();
    final isBlank = text == '—';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 8,
        vertical: dense ? 3 : 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: dense ? 9.5 : 11, color: AppColors.textSecondary),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    // التسمية مرئية لا «باهتة»: ثانوي غامق بدل الباهت الفاتح
                    // The label is legible, not faded: the dark secondary tone, never the pale one.
                    fontSize: dense ? 8 : 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  // في الصفوف السبعة على الجوال تسمية من كلمتين («رقم الطلب») لا تتّسع في سطر:
                  // سطران للعنوان أرخص من بتر الكلمة إلى «رقم الطلـ».
                  // In a seven-column phone row a two-word label does not fit one line: wrapping
                  // the caption is cheaper than truncating it to "رقم الطلـ".
                  maxLines: dense ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // في الوضع المضغوط تُصغَّر القيمة لتتّسع بدل أن تُقصّ: رقم الطلب 11 رقماً واسم القماش
          // طويل، والقصّ يخفي معلومة كاملة — أما التصغير فيُبقيها مقروءة داخل عرض الشاشة.
          // In dense mode the value shrinks to fit instead of being clipped: an 11-digit order id
          // and a long cloth name would otherwise lose real content to an ellipsis.
          if (dense)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isBlank
                        ? AppColors.textMuted
                        : (valueColor ?? AppColors.textPrimary),
                  ),
                ),
              ),
            )
          else
            Text(
              text,
              textAlign: numeric ? TextAlign.end : TextAlign.start,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                // الفراغ يبقى باهتاً عمداً: القيمة الغائبة لا تنافس الموجودة
                // Blanks stay pale on purpose: an absent value must not compete with a real one.
                color: isBlank
                    ? AppColors.textMuted
                    : (valueColor ?? AppColors.textPrimary),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// لون فواصل شبكة الحقول — رمادي مائل للزرقة واضح على الأبيض
/// The field-grid rule colour: a blue-grey that is actually visible on white.
///
/// `AppColors.border` (‏#E2E8F0) شبه شفاف على شاشة هاتف، والطلب كان فواصل تُميِّز الحقول لا
/// فراغاً يُخمَّن. دالّة تُقرأ وقت الرسم لأن اللوحة قابلة للتهيئة من الخادم.
/// AppColors.border (#E2E8F0) is nearly invisible on a phone; the request was for rules that
/// separate fields, not whitespace left to guesswork. A getter, since the palette is configurable.
Color get gridRule => AppColors.secondary.withValues(alpha: 0.35);

/// شبكة حقول متناظرة: أعمدة متساوية بفواصل رأسية وصفوف بفواصل أفقية
/// The field grid: equal columns divided by real vertical rules, rows by horizontal ones.
class MeasurementFieldGrid extends StatelessWidget {
  final List<Widget> fields;

  /// أقل عرض للخانة؛ يحدّد عدد الأعمدة على الجوال والحاسب
  /// The minimum cell width, which decides the column count on phone and desktop.
  final double minCellWidth;

  /// صف واحد عند اتساع المكان لكل الحقول: تفاصيل العميل ثلاثة أرقام، وصفّهن في سطرين
  /// يضاعف الارتفاع بلا معلومة إضافية.
  /// One row when the width can hold every field: the customer block is three numbers, and
  /// splitting them over two lines doubles the height for nothing.
  final bool singleRow;

  const MeasurementFieldGrid({
    super.key,
    required this.fields,
    this.minCellWidth = 118,
    this.singleRow = false,
  });

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        var columns = (constraints.maxWidth / minCellWidth)
            .floor()
            .clamp(1, fields.length);

        if (singleRow && constraints.maxWidth >= 600) {
          columns = fields.length;
        }

        final rows = <Widget>[];
        for (var start = 0; start < fields.length; start += columns) {
          rows.add(
            _row(fields.sublist(start, (start + columns).clamp(0, fields.length)), columns),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: gridRule, width: 1.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Container(height: 1, color: gridRule),
                rows[i],
              ],
            ],
          ),
        );
      },
    );
  }

  /// صف واحد: خانات متساوية بينها خط رأسي، والصف الناقص يُملأ بفراغ لا يتمدد
  /// One row: equal cells with a vertical rule, and the short last row padded so cells stay put.
  Widget _row(List<Widget> cells, int columns) {
    final children = <Widget>[];

    for (var i = 0; i < cells.length; i++) {
      if (i > 0) children.add(Container(width: 1, color: gridRule));
      children.add(Expanded(child: cells[i]));
    }

    for (var i = cells.length; i < columns; i++) {
      children.add(const Expanded(child: SizedBox()));
    }

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// شارة دلالية صغيرة (مرحلة، حالة، عدد) بلون نصّي صريح لا شفاف
/// A small semantic chip (stage, status, count) with solid text, not translucent ink.
class MeasurementBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// `null` = الأساسي وقت الرسم — لون ديناميكي لا يُكتب كقيمة افتراضية ثابتة
  /// `null` means the primary at paint time; a dynamic colour cannot be a const default.
  final Color? color;
  final bool solid;

  /// `solid: true` تعني خلفية كاملة اللون — تُستخدم للحالة الحالية كي لا تُقرأ اقتراحاً
  /// A solid fill marks the current stage, so it never reads as a suggestion.
  const MeasurementBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: solid ? tone : tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tone.withValues(alpha: solid ? 1 : 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 11,
              color: solid ? Colors.white : tone,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: solid ? Colors.white : tone,
            ),
          ),
        ],
      ),
    );
  }
}

/// عنوان مجموعة داخل القسم — يفصل حقول العميل عن حقول الطلب بصرياً
/// A group caption inside a section — it separates customer fields from order fields by name.
class MeasurementGroupLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const MeasurementGroupLabel({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 5),
      child: Row(
        children: [
          Container(width: 3, height: 12, color: tone),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: tone,
              letterSpacing: 0.3,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8, left: 6),
              child: Container(height: 1, color: tone.withValues(alpha: 0.18)),
            ),
          ),
        ],
      ),
    );
  }
}
