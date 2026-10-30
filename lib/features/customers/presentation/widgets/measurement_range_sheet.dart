import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// نطاق زمني مختار / a chosen date range
class MeasurementRange {
  final DateTime? from;
  final DateTime? to;

  const MeasurementRange({this.from, this.to});
}

/// لوحة النطاق الزمني المشتركة — نطاقات جاهزة وتاريخان يدويان
/// The shared date-range sheet: quick ranges plus two manual dates.
///
/// وُظّفت في لوحة واحدة لأن قائمة الموديلات وواجهة المقاسات تسألان السؤال نفسه؛ والنسخ في
/// مكانين يعني أن أول تعديل لنطاق سيُطبَّق على أحدهما فقط.
/// One sheet because the model list and the measurements view ask the same question; two copies
/// would mean the first range tweak lands in only one of them.
class MeasurementRangeSheet extends StatefulWidget {
  final DateTime? from;
  final DateTime? to;

  const MeasurementRangeSheet({super.key, this.from, this.to});

  static Future<MeasurementRange?> show(
    BuildContext context, {
    DateTime? from,
    DateTime? to,
  }) {
    return showModalBottomSheet<MeasurementRange>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => MeasurementRangeSheet(from: from, to: to),
    );
  }

  @override
  State<MeasurementRangeSheet> createState() => _MeasurementRangeSheetState();
}

class _MeasurementRangeSheetState extends State<MeasurementRangeSheet> {
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// النطاقات الجاهزة تُغلق اللوحة فوراً لأنها قرار مكتمل
  /// Quick ranges close the sheet immediately: they are a complete decision.
  void _quick(String type) {
    final now = DateTime.now();
    final (DateTime? from, DateTime? to) = switch (type) {
      'month' => (DateTime(now.year, now.month - 1, 1), now),
      'quarter' => (now.subtract(const Duration(days: 90)), now),
      'year' => (DateTime(now.year, 1, 1), now),
      'all' => (null, null),
      _ => (null, null),
    };

    Navigator.of(context).pop(MeasurementRange(from: from, to: to));
  }

  /// الحدود معلنة صراحة مع تصحيح `initialDate` خارجها: `showDatePicker` ينفجر إذا تجاوز
  /// التاريخ المبدئي الحدود، وقد سُجّل هذا الانهيار في تاريخ التطبيق.
  /// The bounds are explicit and the initial date is clamped into them: `showDatePicker` throws
  /// when `initialDate` falls outside, a crash this app has already recorded once.
  Future<void> _pick(bool isFrom) async {
    final first = DateTime(2000);
    final last = DateTime(2100);
    final current = (isFrom ? _from : _to) ?? DateTime.now();
    final initial = current.isBefore(first) || current.isAfter(last)
        ? DateTime.now()
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: isFrom ? 'اختر تاريخ البداية' : 'اختر تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'تحديد',
    );

    if (picked == null) return;
    setState(() => isFrom ? _from = picked : _to = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'فلترة بالتاريخ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _quickChip('الشهر الماضي', 'month'),
              _quickChip('الثلاثة أشهر', 'quarter'),
              _quickChip('هذه السنة', 'year'),
              _quickChip('الكل', 'all'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField('من تاريخ', _from, () => _pick(true))),
              const SizedBox(width: 8),
              Expanded(child: _dateField('إلى تاريخ', _to, () => _pick(false))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_from != null && _to != null && _from!.isAfter(_to!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تاريخ البداية بعد تاريخ النهاية'),
                        ),
                      );

                      return;
                    }

                    Navigator.of(context).pop(
                      MeasurementRange(from: _from, to: _to),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String label, String type) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      onPressed: () => _quick(type),
      backgroundColor: AppColors.surfaceSubtle,
      side: const BorderSide(color: AppColors.border),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          color: value == null ? AppColors.surfaceSubtle : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value == null ? AppColors.border : AppColors.primary,
            width: value == null ? 1 : 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 15,
              color: value == null ? AppColors.textMuted : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value == null ? label : _fmt(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: value == null ? FontWeight.w600 : FontWeight.w800,
                  color: value == null
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
