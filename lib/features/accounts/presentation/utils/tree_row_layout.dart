import 'package:flutter/material.dart';

/// كثافة أسطر الشجرة وخريطة عرض الأعمدة المشتركة بين السطر ورأس الأعمدة.
/// Tree row density levels and the shared column-width map.
///
/// لماذا هذا الملف؟ كان السطر يوزّع عرضه على ثوابت بالبيكسل (رقم ٦٨، رصيد ٩٦، ثلاثة
/// أعمدة ٤٦/٧٤/٧٤، وثلاثة أزرار ٤٠×٤٠) ويضع الاسم في `Expanded`. على الهاتف وفي
/// المستويات العميقة كان ما يتبقّى للاسم أقل من اسم نفسه، فيظهر مقصوصاً بنقاط الحذف
/// — وهي الشكوى التي رفعها المستخدم: «الاسم يظهر مقصوص».
///
/// The old row gave every fixed part a hardcoded pixel width and handed the leftovers
/// to the name. On a phone, at depth ≥ 2, the remainder was smaller than the name, so
/// the name always ellipsized. Layout is now proportional and resolved once per width,
/// and the header and the rows read the *same* metrics object — which also fixes the
/// column drift the two had (the header used 78 px for the code, the row used 68).
enum TreeDensity {
  /// أصغر كثافة: سطر واحد لكل حساب بأقل ارتفاع ممكن.
  ultra(22, 9.5, 'فائقة الضغط', '22px — أكبر عدد صفوف'),
  compact(28, 10.5, 'مضغوطة', '28px'),
  standard(34, 11.5, 'قياسية', '34px'),
  comfortable(42, 12.5, 'مريحة', '42px'),
  relaxed(52, 14.0, 'واسعة', '52px — أوضح للقراءة');

  const TreeDensity(this.height, this.fontSize, this.labelAr, this.hintAr);

  /// ارتفاع السطر بالبيكسل.
  final double height;

  /// حجم الخط الأساسي للسطر — يتقادم مع الكثافة لا مستقلّاً عنها.
  final double fontSize;
  final String labelAr;
  final String hintAr;

  /// توافق مع الحالة القديمة (`bool compact`) كي لا تُكسر الاختبارات القائمة.
  static TreeDensity fromCompact(bool compact) =>
      compact ? TreeDensity.compact : TreeDensity.comfortable;
}

/// قياسات سطر واحدة محسوبة من عرض متاح — يتشاركها السطر ورأس الأعمدة.
/// One row's resolved geometry for a given viewport width.
@immutable
class TreeRowMetrics {
  const TreeRowMetrics({
    required this.density,
    required this.width,
    required this.codeW,
    required this.balanceW,
    required this.debitW,
    required this.creditW,
    required this.movementsW,
    required this.nameW,
    required this.indentStep,
    required this.maxIndent,
    required this.badgeW,
    required this.showColumns,
    required this.showActions,
    required this.showBadge,
  });

  final TreeDensity density;
  final double width;

  /// عرض عمود الرقم: يكفي ٩ أرقام (حسابات العملاء تسعة أرقام فعلاً).
  final double codeW;
  final double balanceW;
  final double debitW;
  final double creditW;
  final double movementsW;

  /// الاسم يأخذ الباقي — محسوب لا مفترض، ولهذا لا يُقصّ.
  final double nameW;
  final double indentStep;

  /// أقصى تعداد مستويات يُدفع عنه إزاحة: أعمق شجرة هنا ٤، وما بعده يظل مقروءاً.
  final int maxIndent;

  /// عرض شارة المستوى المحجوز. ثابت عن قصد: الرأس يرسم «المستوى» فوقه، ولو تُرك
  /// العرض لمحتوى النص لانزلق كل ما بعده عمودياً بين سطر وآخر.
  final double badgeW;
  final bool showColumns;
  final bool showActions;
  final bool showBadge;

  /// ارتفاع السطر الحالي.
  double get height => density.height;

  double get fontSize => density.fontSize;

  /// جانب زر الإجراء المصغّر — تُشتق منه مساحة الأزرار كلها.
  double get actionSide => (density.height * 0.86).clamp(22.0, 30.0);

  /// فتحة الأزرار محجوزة لثلاثة دائماً: لو حُجز بالعدد الفعلي لكل سطر لانزلق
  /// عمود الرصيد بين سطر وآخر — فسطرٌ بزرّين يختلف عن سطر بثلاثة.
  /// A constant slot for up to three buttons, so the balance column stays one straight
  /// line whether a row can reveal, edit, both, or neither.
  double get actionsW => showActions ? actionSide * 3 + 2 : 0;

  /// هل يسع الاسم اسمه المعتاد؟ إن لم يسع فالخط يصغر درجة بدل أن يُقصّ.
  double get nameFontSize => nameW < _minComfortableName
      ? density.fontSize - 1
      : density.fontSize;

  /// الاسم يحتاج هذا القدر ليُقرأ بلا حذف؛ تحته تُطفأ الزوائد اختيارياً.
  static const double _minComfortableName = 130;

  /// أدنى عرض مقبول للاسم — لا يُقبل أن يصبح السطر بلا اسم مهما ضاق العرض.
  static const double _nameFloor = 96;

  /// يبني القياسات من العرض المتاح، ويطفئ الاختياري بالترتيب حتى يأخذ الاسم حقه.
  /// Resolves the layout. Optional chrome is switched off in priority order
  /// (columns → badge → actions → one icon) until the name clears its floor, so the
  /// account name is the last thing to lose space, as it should be.
  static TreeRowMetrics resolve({
    required double width,
    required TreeDensity density,
  }) {
    // تدرّج الكثافة: الشاشة الضيقة تحتاج إزاحة أقل من اللوحة العريضة.
    final indentStep = (density.height * 0.32).clamp(5.0, 11.0);
    const maxIndent = 4;
    const badgeW = 52.0;

    // مساحة الأزرار تُحجز كاملة ولو ظهر أقلّ منها — نفس ما يقرأه actionsW، وإلا
    // خرج الرصيد في غير موضعه الذي حدده رأس العمود.
    final actionsW = (density.height * 0.86).clamp(22.0, 30.0) * 3 + 2;

    var showColumns = width >= 780;
    var showBadge = width >= 880;
    var showActions = width >= 500;

    // ثوابت لا تُساوم: الحشوة + الإزاحة + مقبض التوسيع + الفواصل.
    double fixed = 12 + (indentStep * maxIndent) + handleW + 12;

    // الرقم والرصيد proportional: نسبة من العرض بحدّين، فالرقم تسعة أرقام والرصيد
    // قد يبلغ مليارات (أرصدة هذا الدليل تتجاوز المليار فعلاً).
    double codeW = (width * 0.17).clamp(46.0, 96.0);
    double balanceW = (width * 0.18).clamp(56.0, 124.0);
    double debitW = (width * 0.11).clamp(40.0, 76.0);
    double creditW = (width * 0.11).clamp(40.0, 76.0);
    double movementsW = (width * 0.09).clamp(34.0, 64.0);

    double nameOf() {
      var left = width - fixed - codeW - balanceW - 8;
      if (showColumns) left -= debitW + creditW + movementsW + 12;
      if (showBadge) left -= badgeW + 6;
      if (showActions) left -= actionsW;
      return left;
    }

    // إطفاء الاختياري بالترتيب حتى يبلغ الاسم أرضيته.
    while (nameOf() < _nameFloor) {
      if (showColumns) {
        showColumns = false;
        continue;
      }
      if (showBadge) {
        showBadge = false;
        continue;
      }
      if (showActions) {
        showActions = false;
        continue;
      }
      // لا شيء اختياري تبقّى: الرصيد هو التالي بالضبط، فالاسم لا يُقصّ أبداً.
      balanceW = (balanceW * 0.82).clamp(44.0, 124.0);
      codeW = (codeW * 0.9).clamp(38.0, 96.0);
      if (balanceW <= 44.5 && codeW <= 38.5) break;
    }

    return TreeRowMetrics(
      density: density,
      width: width,
      codeW: codeW,
      balanceW: balanceW,
      debitW: debitW,
      creditW: creditW,
      movementsW: movementsW,
      nameW: nameOf(),
      indentStep: indentStep,
      maxIndent: maxIndent,
      badgeW: badgeW,
      showColumns: showColumns,
      showActions: showActions,
      showBadge: showBadge,
    );
  }

  /// عرض مقبض فتح/إغلاق الأبناء — ثابت ومتاح للرأس والسطر معاً.
  static const double handleW = 26;

  /// إزاحة مستوى معيّن، محصورة في `maxIndent`.
  double indentFor(int depth) => (depth > maxIndent ? maxIndent : depth) * indentStep;
}
