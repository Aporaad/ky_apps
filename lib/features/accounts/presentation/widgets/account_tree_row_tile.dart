import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';
import '../utils/account_tree_flatten.dart';
import '../utils/tree_row_layout.dart';

/// سطر واحد في قائمة الشجرة المسطّحة — بسطر واحد فعلاً، بلا قصّ للاسم.
/// One row of the flattened chart-of-accounts list.
///
/// لماذا أُعيد تصميمه؟ التوزيع القديم كان ثوابت بالبيكسل حول اسم في `Expanded`:
/// رقم ٦٨ + رصيد ٩٦ + ثلاثة أعمدة (٤٦/٧٤/٧٤) + شارة + ثلاثة `IconButton` بمساحة لمس
/// ٤٠×٤٠ لكل واحد منها. على عرض هاتف وبعمق ≥ ٢ كان المتبقّي للاسم أقل من الاسم،
/// فينقطع بنقاط الحذف. الآن القياسات تُحسب من العرض المشترك مع الرأس، والاسم يأخذ
/// الباقي ويصغر بخطه (FittedBox) بدل أن يُقصّ — فكل تفاصيل الحساب تُقرأ في سطر واحد.
///
/// The fixed pixel chrome starved the name. Widths now come from one [TreeRowMetrics]
/// shared with the column header, the name takes the remainder and scales down via
/// [FittedBox] instead of ellipsizing, and the optional parts (columns, badge, action
/// buttons) switch themselves off before the name is ever squeezed out.
class AccountTreeRowTile extends StatelessWidget {
  final AccountTreeRow row;
  final bool expanded;

  /// القياسات المحسوبة من عرض الشاشة والكثافة المختارة.
  final TreeRowMetrics metrics;

  final bool canReveal;
  final bool canEdit;
  final VoidCallback? onTap;

  /// نقرة مزدوجة = كشف مباشر، لنفس السبب الذي من أجله يوجد الزر.
  final VoidCallback? onDoubleTap;
  final VoidCallback? onReveal;
  final VoidCallback? onDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onLoadMore;
  final String? error;

  const AccountTreeRowTile({
    required this.row,
    required this.metrics,
    super.key,
    this.expanded = false,
    this.canReveal = false,
    this.canEdit = false,
    this.onTap,
    this.onDoubleTap,
    this.onReveal,
    this.onDetails,
    this.onEdit,
    this.onLoadMore,
    this.error,
  });

  /// كثافة افتراضية للمعاينة والاختبارات خارج أي سياق.
  AccountTreeRowTile.preview({
    required this.row,
    this.expanded = false,
    this.canReveal = false,
    this.canEdit = false,
    this.onTap,
    this.onDoubleTap,
    this.onReveal,
    this.onDetails,
    this.onEdit,
    this.onLoadMore,
    this.error,
    super.key,
  }) : metrics = TreeRowMetrics.resolve(
         width: 420,
         density: TreeDensity.compact,
       );

  static const double _comfortableHeight = 46;

  @override
  Widget build(BuildContext context) {
    return switch (row.kind) {
      AccountTreeRowKind.loading => _statusRow(
        icon: Icons.hourglass_bottom_rounded,
        text: 'جارٍ تحميل الحسابات…',
        color: AppColors.textMuted,
      ),
      AccountTreeRowKind.loadMore => _statusRow(
        icon: Icons.expand_more_rounded,
        text: 'تحميل حسابات هذه العقدة',
        color: AppColors.primary,
        onTap: onLoadMore,
      ),
      AccountTreeRowKind.rowError => _statusRow(
        icon: Icons.error_outline_rounded,
        text: error ?? 'تعذّر تحميل الحسابات',
        color: AppColors.error,
        onTap: onLoadMore,
      ),
      _ => _dataRow(context),
    };
  }

  Widget _statusRow({
    required IconData icon,
    required String text,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        // لا `clamp` هنا: `num.clamp(a, b)` يرمي ArgumentError متى كان a > b،
        // والتعبير القديم كان `clamp(metrics.height, 46)` — أي (52 > 46) على الكثافة
        // «الواسعة»، فتنهار الشاشة لحظة النقر على فتح/إغلاق الفروع لأن هذه الصفوف
        // (جارٍ التحميل/تحميل المزيد/خطأ) هي التي تظهر عند التوسيع.
        // A max, not a clamp: clamp throws when lowerLimit > upperLimit, which is
        // exactly what the widest density produced. Status rows are at least as tall
        // as the rows they sit between, and comfortably taller on the tiny ones.
        height: metrics.height > _comfortableHeight - 8
            ? metrics.height
            : _comfortableHeight - 8,
        padding: EdgeInsets.only(
          right: metrics.indentFor(row.depth + 1) + 8,
          left: 12,
        ),
        // AlignmentDirectional يحترم اتجاه الواجهة بلا حاجة لـ context داخل دالة
        // مساعدة لا تستلمه — في RTL يظهر على اليمين كما هو مقصود.
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(BuildContext context) {
    final node = row.node;
    final balance = row.balance ?? 0;
    final hasBalance = balance.abs() >= 0.005;
    final isLeaf = row.kind == AccountTreeRowKind.leaf;
    final expandable = !isLeaf && (node?.hasChildren ?? false);
    final m = metrics;

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      // على الهاتف تُطفأ أزرار الإجراءات لضيق العرض، فتبقى الضغطة الطويلة مدخل
      // التفاصيل والكشف — وإلا صار الكشف عن مجموعة حكراً على الشاشات العريضة.
      // Long-press keeps details/reveal reachable where the action buttons are off.
      onLongPress: onDetails,
      child: Container(
        height: m.height,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          // تلوين خافت للأوراق المالية فقط، ليتميّز الدفتر عن الهيكل بلا ضجيج.
          color: isLeaf
              ? AppColors.surfaceSubtle.withValues(alpha: 0.45)
              : null,
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.6),
          ),
        ),
        child: Row(
          children: [
            // ── مسافة التحديد البصري للمستوى + الخط الإرشادي ──
            SizedBox(width: m.indentFor(row.depth)),
            if (row.depth > 0)
              Container(
                width: 8,
                height: m.height,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.9),
                      width: 1,
                    ),
                  ),
                ),
              ),

            // ── مقبض فتح/إغلاق الأبناء: زر صريح، لا تعتمد على نقر الصف ──
            _ExpandHandle(
              metrics: m,
              expandable: expandable,
              expanded: expanded,
              isLeaf: isLeaf,
              color: row.levelColor,
              onPressed: expandable ? onTap : null,
            ),

            // ── الرقم ──
            SizedBox(
              width: m.codeW,
              child: Text(
                row.code,
                maxLines: 1,
                overflow: TextOverflow.clip,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: m.fontSize,
                  color: AppColors.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // ── الاسم: يأخذ الباقي ويصغر بخطه بدل أن يُقصّ ──
            Expanded(child: _nameText(isLeaf: isLeaf)),

            const SizedBox(width: 4),

            // ── شارة المستوى ──
            if (m.showBadge) ...[
              SizedBox(
                width: m.badgeW,
                child: _LevelBadge(label: row.levelLabel, color: row.levelColor),
              ),
              const SizedBox(width: 6),
            ],

            // ── العدد / مدين / دائن ──
            if (m.showColumns) ...[
              SizedBox(
                width: m.movementsW,
                child: Text(
                  '${node != null ? (node.childrenCount ?? node.children.length) : (row.leaf?.movements ?? 0)}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(fontSize: m.fontSize - 1.5, color: AppColors.textMuted),
                ),
              ),
              _moneyCell(row.debit ?? 0, m.debitW, AppColors.textPrimary, m),
              _moneyCell(row.credit ?? 0, m.creditW, AppColors.textPrimary, m),
              const SizedBox(width: 6),
            ],

            // ── الرصيد المجمَّع ──
            SizedBox(
              width: m.balanceW,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  hasBalance ? formatTreeAmount(balance) : '—',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: m.fontSize,
                    fontWeight: FontWeight.w700,
                    color: hasBalance
                        ? (balance > 0 ? AppColors.success : AppColors.error)
                        : AppColors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),

            // ── أزرار الكشف والتفاصيل والتعديل ──
            // تُحجز في فتحة بعرض ثلاثة أزرار دائماً (m.actionsW): لو خُصص لها قدرها
            // الفعلي لاختلّ عمود الرصيد بين سطر بثلاثة أزرار وسطر بزرّ واحد.
            if (m.showActions)
              SizedBox(width: m.actionsW, child: Row(children: _actions(isLeaf: isLeaf, node: node))),
          ],
        ),
      ),
    );
  }

  /// الاسم كاملاً في سطر واحد: `FittedBox` يصغّر النص بدل قصّه، فاسم طويل مثل
  /// «مدينون من العملاء والممثلون القانونيون» يظل مقروءاً كاملاً على هاتف.
  /// The name is scaled to fit rather than truncated — the whole point of the fix.
  ///
  /// يبدأ من حجم الكثافة نفسه لا من حجم ثابت: وإلا صار الاسم أكبر من أعمدته في
  /// الكثافة الضيقة وأصغر منها في الواسعة، ففسد ميزان السطر الذي تُقرأ به الجدول.
  /// It starts at the density's own font size, so the name ages with its columns.
  Widget _nameText({required bool isLeaf}) {
    final node = row.node;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        row.title,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          fontSize: metrics.nameFontSize,
          fontWeight: isLeaf
              ? FontWeight.w400
              : (node != null && node.level == 'account'
                    ? FontWeight.bold
                    : FontWeight.w600),
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _moneyCell(double value, double width, Color color, TreeRowMetrics m) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value.abs() >= 0.005 ? formatTreeAmount(value) : '—',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.end,
          style: TextStyle(fontSize: m.fontSize, color: color),
        ),
      ),
    );
  }

  /// الأزرار المصغّرة: مساحة اللمس ٢٦ بدل ٤٠، لأن ثلاثة أزرار قياسية كانت تأكل
  /// ثلث عرض السطر على الهاتف. الكشف والتفاصيل يبقيان، والتعديل يُدمج في التفاصيل
  /// على الكثافات الضيقة.
  List<Widget> _actions({required bool isLeaf, required AccountTreeNode? node}) {
    final canEditHere = canEdit && (isLeaf || node?.level == 'chart');
    return [
      const SizedBox(width: 2),
      if (canReveal)
        _MiniAction(
          icon: Icons.remove_red_eye_rounded,
          tooltip: isLeaf ? 'كشف حساب مالي' : 'كشف مجموعة الحسابات',
          color: AppColors.primaryLight,
          metrics: metrics,
          onPressed: onReveal,
        ),
      _MiniAction(
        icon: Icons.info_outline_rounded,
        tooltip: 'تفاصيل الحساب',
        color: AppColors.secondary,
        metrics: metrics,
        onPressed: onDetails,
      ),
      if (canEditHere)
        _MiniAction(
          icon: Icons.edit_outlined,
          tooltip: 'تعديل',
          color: AppColors.warning,
          metrics: metrics,
          onPressed: onEdit,
        ),
    ];
  }
}

/// مقبض توسيع/طيّ الأبناء — يظهر كسهم للعقد القابلة للتوسيع، وكنقطة للأوراق.
/// The explicit open/close affordance for a node's children. A row tap also toggles,
/// but a tap target that gives no visual hint is why users could not find it.
class _ExpandHandle extends StatelessWidget {
  const _ExpandHandle({
    required this.metrics,
    required this.expandable,
    required this.expanded,
    required this.isLeaf,
    required this.color,
    this.onPressed,
  });

  final TreeRowMetrics metrics;
  final bool expandable;
  final bool expanded;
  final bool isLeaf;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final iconSize = (metrics.fontSize + 3).clamp(12.0, 20.0);

    return SizedBox(
      width: TreeRowMetrics.handleW,
      height: metrics.height,
      child: expandable
          ? Tooltip(
              message: expanded ? 'إخفاء الحسابات الفرعية' : 'إظهار الحسابات الفرعية',
              waitDuration: const Duration(milliseconds: 600),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(5),
                child: Center(
                  child: AnimatedRotation(
                    // دوران السهم بدل تبديل أيقونتين: حالة الفهم أرخص من حالة التخمين.
                    turns: expanded ? 0.25 : -0.25,
                    duration: const Duration(milliseconds: 140),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: iconSize,
                      color: color,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Icon(
                isLeaf
                    ? Icons.bookmark_border_rounded
                    : Icons.horizontal_rule_rounded,
                size: (metrics.height * 0.72).clamp(12.0, 20.0),
                color: color.withValues(alpha: 0.75),
              ),
            ),
    );
  }
}

/// زر إجراء مصغّر بنفس وظيفة IconButton بمساحة لمس أصغر للجدول المضغوط.
class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.metrics,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final TreeRowMetrics metrics;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // نفس metrics.actionSide الذي تُشتق منه فتحة الأزرار (actionsW)، فلا يخرج الصف
    // عن الفتحة المحجوزة له في رأس العمود.
    final side = metrics.actionSide;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: side,
          height: side,
          child: Icon(
            icon,
            size: (metrics.fontSize + 4).clamp(12.0, 18.0),
            color: onPressed == null ? color.withValues(alpha: 0.35) : color,
          ),
        ),
      ),
    );
  }
}

/// شارة المستوى — نص قصير ملوّن يجعل بنية السطر مقروءة بلا توسيع.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      // العرض يأتي من m.badgeW لا من طول النص: فتتساوى أعمدة «رئيسي/فرعي/جزئي/
      // مجموعة/حساب» ويصير المستوى نفسه قابلًا للمقارنة سطرًا بسطر.
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// ترويسة أعمدة الشاشات العريضة — تقرأ نفس `TreeRowMetrics` التي يقرأها السطر.
/// Reads the very same metrics object as the rows, which is why the columns line up.
/// The old header hardcoded its own widths (78 px for the code against the row's 68),
/// so the labels drifted from the numbers they described.
class AccountTreeColumnsHeader extends StatelessWidget {
  const AccountTreeColumnsHeader({required this.metrics, super.key});

  final TreeRowMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final m = metrics;

    Widget cell(String text, double width, {bool end = false}) => SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: end ? TextAlign.end : TextAlign.start,
        overflow: TextOverflow.clip,
        maxLines: 1,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );

    return Container(
      // نفس حشوة السطر تماماً (6 أفقياً) لتتطابق الأعمدة مع أرقامها.
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          // الرأس يصطفّ مع السطر الأول (عمق ٠): المقبض وحده قبل عمود الرقم، لأن
          // الأسطر الأعمق تُزاح بمقدار مستواها — وهذا هو المتوقع في الشجرة.
          // Aligned to depth 0; deeper rows indent by design.
          const SizedBox(width: TreeRowMetrics.handleW),
          cell('الرقم', m.codeW),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'الاسم',
              maxLines: 1,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (m.showBadge) ...[cell('المستوى', m.badgeW), const SizedBox(width: 6)],
          if (m.showColumns) ...[
            cell('العدد', m.movementsW),
            cell('مدين', m.debitW, end: true),
            cell('دائن', m.creditW, end: true),
            const SizedBox(width: 6),
          ],
          cell('الرصيد', m.balanceW, end: true),
          if (m.showActions) SizedBox(width: m.actionsW),
        ],
      ),
    );
  }
}
