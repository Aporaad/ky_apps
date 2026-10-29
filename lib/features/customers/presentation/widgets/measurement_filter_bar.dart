import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/measurement_model_ref.dart';

/// حالة فلترة شاشة المقاسات — كائن غير متغيّر واحد
/// The measurements screen's filter state — one immutable object.
///
/// الفلترة هنا عرضية بطبيعتها: أي مقاس مخزّن في القاعدة يبقى كما هو، فالمرشّحات تُخفي ما لا
/// يحتاجه الناظر الآن (قسم غير مقصود، أو أقمشة باسم آخر) ولا تُغيّر شيئاً.
/// These filters are presentational: nothing stored in the database changes. They hide what the
/// reader does not need right now (an uninteresting section, other fabrics) and alter no data.
class MeasurementFilters {
  /// إظهار أقسام العرض — الثلاثة تُعرض وتُطبع حسب طلب الناظر
  /// Which sections are visible — measurements, specs and fabrics.
  final bool showMeasurements;
  final bool showSpecs;
  final bool showFabrics;

  /// بحث داخل أسماء الأقمشة — نص حرّ لا يصل إلى الخادم
  /// A local fabric-name search — free text that never reaches the server.
  final String clothQuery;

  const MeasurementFilters({
    this.showMeasurements = true,
    this.showSpecs = true,
    this.showFabrics = true,
    this.clothQuery = '',
  });

  static const MeasurementFilters defaults = MeasurementFilters();

  /// هل الفلترة مطبّقة فعلاً؟ — تُظهر عدّاداً على زر الفلترة المغلق
  /// Are any filters actually applied? Drives the counter on the collapsed filter button.
  ///
  /// مقارنة بالمفروض الافتراضي لا بحالة فارغة: أي مفتاح مُطفأ أو نص بحث يعني أن المستخدم غيّر
  /// العرض، والمساواة معرّفة يدوياً في `==` أسفل هذا الصنف.
  /// Compared against the default state, not against emptiness: any switch turned off or any
  /// search text means the user changed the view, and equality is defined by hand below.
  bool get isDirty => this != defaults;

  MeasurementFilters copyWith({
    bool? showMeasurements,
    bool? showSpecs,
    bool? showFabrics,
    String? clothQuery,
  }) {
    return MeasurementFilters(
      showMeasurements: showMeasurements ?? this.showMeasurements,
      showSpecs: showSpecs ?? this.showSpecs,
      showFabrics: showFabrics ?? this.showFabrics,
      clothQuery: clothQuery ?? this.clothQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MeasurementFilters &&
      other.showMeasurements == showMeasurements &&
      other.showSpecs == showSpecs &&
      other.showFabrics == showFabrics &&
      other.clothQuery == clothQuery;

  @override
  int get hashCode => Object.hash(
    showMeasurements,
    showSpecs,
    showFabrics,
    clothQuery,
  );
}

/// شريط فلترة شاشة المقاسات — يظهر ويختفي بزر واحد من الـ AppBar
/// The measurements screen's filter bar — shown and hidden by one AppBar button.
///
/// كل عنصر فيه قرار عرض لا قرار بيانات: مفاتيح الأقسام، إظهار الخانات الفارغة، بحث القماش،
/// ومنتقي الموديلات/المستفيدين من نفس الفاتورة (يظهر فقط إن كان لها أكثر من موديل).
/// Every control here is a display decision, not a data one: section switches, blank-slot
/// visibility, the fabric search, and the same-bill model picker (only when the bill has more
/// than one model).
class MeasurementFilterBar extends StatefulWidget {
  final MeasurementFilters value;
  final ValueChanged<MeasurementFilters> onChanged;

  /// إخوة الموديل داخل نفس الفاتورة — فارغ أو واحد يعني بلا منتقي
  /// The bill's other models — empty or single means no picker at all.
  final List<MeasurementSibling> siblings;
  final ValueChanged<int>? onSelectSibling;

  const MeasurementFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.siblings = const [],
    this.onSelectSibling,
  });

  @override
  State<MeasurementFilterBar> createState() => _MeasurementFilterBarState();
}

class _MeasurementFilterBarState extends State<MeasurementFilterBar> {
  /// الحقل يملك نصّه: البحث حرف بحرف بلا انتظار خادم. لكن القيمة تُخزَّن مقطوغة الفراغ،
  /// فلو قورن الحقل بالقيمة مباشرة لأكل المستعرض فراغ كل كلمة يكتب «اسم صنف» بين حرفين.
  /// The field owns its text, so typing is instant with no server call. The stored value is
  /// trimmed, though — comparing the field to it directly would swallow the space of every
  /// two-word fabric name as it is typed.
  late final TextEditingController _clothCtrl =
      TextEditingController(text: widget.value.clothQuery);

  /// آخر نص صدر من هذا الحقل: ما يعادلُه يعني أن الحقل نفسه هو من غيّر القيمة
  /// The last text this field emitted: equal means the field itself caused the change.
  /// `late` لأنه يقرأ `widget`، والتهيئة المباشرة للحقول لا تراه بعد.
  /// It is `late` because it reads `widget`, which an ordinary field initializer cannot see yet.
  late String _lastEmitted = widget.value.clothQuery;

  @override
  void didUpdateWidget(covariant MeasurementFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // يختلف عن آخر ما أرسله الحقل ⇒ جهة أخرى غيّرته (زر إعادة الضبط أو الانتقال إلى موديل
    // آخر)، فيتبع الحقل القيمة. والتطابق يعني أنه كتابتي أنا: لا لمس لموضع المؤشر.
    // Different from what the field last emitted means someone else changed it — the reset
    // button or a model switch — so the field follows the value. Equal means it was my own
    // typing, and the caret is left alone.
    if (widget.value.clothQuery != _lastEmitted) {
      _lastEmitted = widget.value.clothQuery;
      _clothCtrl.text = widget.value.clothQuery;
    }
  }

  @override
  void dispose() {
    _clothCtrl.dispose();
    super.dispose();
  }

  MeasurementFilters get value => widget.value;

  @override
  Widget build(BuildContext context) {
    final siblings = widget.siblings;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── أقسام العرض ────────────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _toggle(
                label: 'المقاسات',
                icon: Icons.straighten_rounded,
                on: value.showMeasurements,
                onTap: () => widget.onChanged(value.copyWith(showMeasurements: !value.showMeasurements)),
              ),
              _toggle(
                label: 'المواصفات',
                icon: Icons.tune_rounded,
                on: value.showSpecs,
                onTap: () => widget.onChanged(value.copyWith(showSpecs: !value.showSpecs)),
              ),
              _toggle(
                label: 'الأقمشة',
                icon: Icons.dry_cleaning_rounded,
                on: value.showFabrics,
                onTap: () => widget.onChanged(value.copyWith(showFabrics: !value.showFabrics)),
              ),
            ],
          ),

          // لا مفتاح «الخانات الفارغة» هنا: بطاقة المقاسات تحمل هذا المفتاح بنفسها في شريط
          // عنوانها، ومصدران للحالة واحدة يعنيان حتماً شاشة تكذب على نفسها.
          // No "blank slots" switch here: the measurements card carries that switch in its own title
          // bar, and two sources for one piece of state means a screen that contradicts itself.

          // ── منتقي الموديل/المستفيد من نفس الفاتورة ─────────────────────────
          // لا منتقي بموديل واحد: شريط اختيار بخيار واحد يوحي بقرار غير موجود
          // A picker with one option is no picker: it suggests a choice that does not exist.
          if (siblings.length > 1 && widget.onSelectSibling != null) ...[
            const SizedBox(height: 8),
            Text(
              'موديلات الفاتورة نفسها',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final sibling in siblings) ...[
                    ChoiceChip(
                      label: Text(sibling.label),
                      selected: sibling.selected,
                      onSelected: (_) => widget.onSelectSibling!(sibling.seqNo),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],

          // ── بحث الأقمشة ────────────────────────────────────────────────────
          const SizedBox(height: 8),
          TextField(
            controller: _clothCtrl,
            onChanged: (text) {
              // القيمة تُحفظ مقطوغة، لكن الحقل يذكر ما أرسله كي لا يُعاد ضبطه خلف كل ضغطة
              // The value is stored trimmed, but the field remembers what it emitted so it is
              // never reset behind the user's own keystrokes.
              _lastEmitted = text.trim();
              widget.onChanged(value.copyWith(clothQuery: text.trim()));
            },
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'بحث في أسماء الأقمشة…',
              hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
            ),
          ),

          // إعادة الضبط: زر نصّي صغير في الصف الأخير من الشريط
          // Reset: a small text button at the bar's end.
          if (value != MeasurementFilters.defaults)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => widget.onChanged(MeasurementFilters.defaults),
                icon: const Icon(Icons.restart_alt_rounded, size: 15),
                label: const Text('إعادة الضبط'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// مفتاح إظهار/إخفاء على شكل شارة قابلة للضغط
  /// A show/hide switch drawn as a tappable badge.
  Widget _toggle({
    required String label,
    required IconData icon,
    required bool on,
    required VoidCallback onTap,
  }) {
    final color = on ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: on
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: on ? color.withValues(alpha: 0.35) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? icon : Icons.visibility_off_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
