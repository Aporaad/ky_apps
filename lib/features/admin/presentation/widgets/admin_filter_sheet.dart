import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// حالة الفلترة كما تختارها الشاشة — نسخة واحدة تمر عبر الورقة والفرز
/// The filter selection as the screen sets it — one shape shared by the sheet and the sort menu.
class AdminUserFilterChoice {
  final String status;
  final String userType;
  final bool adminOnly;

  const AdminUserFilterChoice({
    required this.status,
    required this.userType,
    required this.adminOnly,
  });

  const AdminUserFilterChoice.none()
    : status = 'all',
      userType = 'all',
      adminOnly = false;

  /// عدد الفلاتر المفتوحة — يُظهر الرقم على أيقونة الفلترة فلا يُنسى فلترٌ فعّال
  /// How many filters are on — the badge keeps an active filter from being forgotten.
  int get activeCount {
    var count = 0;
    if (status != 'all') count++;
    if (userType != 'all') count++;
    if (adminOnly) count++;

    return count;
  }

  bool get isNone => activeCount == 0;
}

/// خيارات الحالة: مطابقة تماماً لقيم `UserAdminController::conditions`
/// Status options — exactly the values `UserAdminController::conditions` accepts.
const List<_Choice> _statusChoices = [
  _Choice('all', 'الكل'),
  _Choice('active', 'نشط'),
  _Choice('inactive', 'معطّل'),
];

/// خيارات النوع: '1' موظف و'2' عميل (قرار D5)
/// Type options: 1 staff, 2 customer (decision D5).
const List<_Choice> _userTypeChoices = [
  _Choice('all', 'الكل'),
  _Choice('1', 'موظف'),
  _Choice('2', 'عميل'),
];

/// صفوف الفرز: العمود والاتجاه معاً، مطابقة لبيضاء `SORTABLE` في الخادم
/// Sort rows: column and direction together, mirroring the server's SORTABLE whitelist.
const List<_Choice> _sortChoices = [
  _Choice('user_name_ar', 'الاسم العربي'),
  _Choice('user_name_en', 'الاسم اللاتيني'),
  _Choice('user_id', 'رقم المستخدم'),
  _Choice('created_on', 'تاريخ الإنشاء'),
  _Choice('is_activated', 'الحالة'),
  _Choice('user_type', 'النوع'),
];

/// خيار واحد (قيمة + تسمية) — بنية خاصة بالملف لأن التسميات لا تُستخدم خارج الشاشات
/// A single value/label pair — file-private, since these labels never leave these sheets.
class _Choice {
  final String value;
  final String label;

  const _Choice(this.value, this.label);
}

/// ورقة فلترة المستخدمين — تُفتح من أيقونة الفلترة في شريط البحث
/// The user filter sheet, opened from the search bar's filter icon.
///
/// القيمة تُرجع عبر `Navigator.pop` ولا تكتب في المزود مباشرة: الشاشة هي من يستدعي
/// `applyFilters`، فتبقى مسؤولية تغيير الحالة في مكان واحد ويمكن اختبار الورقة بلا شبكة.
/// The choice is returned via `Navigator.pop` rather than written into the provider here: the
/// screen is what calls `applyFilters`, so state mutation stays in one place and the sheet is
/// unit-testable without a network.
class AdminFilterSheet extends StatefulWidget {
  final AdminUserFilterChoice initial;

  const AdminFilterSheet({required this.initial, super.key});

  @override
  State<AdminFilterSheet> createState() => _AdminFilterSheetState();
}

class _AdminFilterSheetState extends State<AdminFilterSheet> {
  late String _status = widget.initial.status;
  late String _userType = widget.initial.userType;
  late bool _adminOnly = widget.initial.adminOnly;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 14),
            Text(
              'تصفية قائمة المستخدمين',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _ChoiceGroup(
              label: 'الحالة',
              choices: _statusChoices,
              selected: _status,
              onSelected: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 14),
            _ChoiceGroup(
              label: 'نوع الحساب',
              choices: _userTypeChoices,
              selected: _userType,
              onSelected: (value) => setState(() => _userType = value),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _adminOnly,
              onChanged: (value) => setState(() => _adminOnly = value),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'المديرون فقط',
                style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'إظهار من يملك صفة مدير النظام',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _status = 'all';
                      _userType = 'all';
                      _adminOnly = false;
                    }),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: const Text('إعادة تعيين'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _apply,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('تطبيق'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _apply() {
    Navigator.pop(
      context,
      AdminUserFilterChoice(
        status: _status,
        userType: _userType,
        adminOnly: _adminOnly,
      ),
    );
  }
}

/// قائمة chips لزمرة فلترة واحدة
/// A chip row for one filter group.
class _ChoiceGroup extends StatelessWidget {
  final String label;
  final List<_Choice> choices;
  final String selected;
  final ValueChanged<String> onSelected;

  const _ChoiceGroup({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final choice in choices)
              _FilterChip(
                label: choice.label,
                isSelected: choice.value == selected,
                onTap: () => onSelected(choice.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// شريحة اختيار مفردة — نفس الشكل في الفرز والفلترة فلا تتعلم الشاشة نمطين
/// A single-select chip — one shape for both sorting and filtering.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// مقبض الورقة — إشارة بصرية أن السحب يغلق
/// The sheet handle — the visual cue that dragging closes it.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// فتح ورقة الفلترة وإرجاع الاختيار — null يعني أن المستخدم أغلق بلا تغيير
/// Open the filter sheet and return the choice; null means it was dismissed untouched.
Future<AdminUserFilterChoice?> showAdminFilterSheet(
  BuildContext context,
  AdminUserFilterChoice initial,
) {
  return showModalBottomSheet<AdminUserFilterChoice>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => AdminFilterSheet(initial: initial),
  );
}

/// فتح ورقة الفرز — تُرجاع (عمود، اتجاه) وتُمرَّر للمزوّد كما هي
/// Open the sort sheet; the returned (column, direction) pair goes straight to the notifier.
Future<({String column, String direction})?> showUserSortSheet(
  BuildContext context, {
  required String sort,
  required String direction,
}) {
  return showModalBottomSheet<({String column, String direction})>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SortSheet(
      sort: sort,
      direction: direction,
    ),
  );
}

class _SortSheet extends StatefulWidget {
  final String sort;
  final String direction;

  const _SortSheet({required this.sort, required this.direction});

  @override
  State<_SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends State<_SortSheet> {
  late String _sort = widget.sort;
  late String _direction = widget.direction;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 16 + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 14),
            Text(
              'ترتيب القائمة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'الترتيب عند الخادم، والضغط على العمود نفسه تعكس الاتجاه',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final choice in _sortChoices)
                      _SortTile(
                        label: choice.label,
                        isActive: choice.value == _sort,
                        direction: _direction,
                        onTap: () => setState(() {
                          // العمود نفسه يعكس الاتجاه كما تفعل `sortBy` في المزود
                          // Tapping the active column flips direction, exactly as sortBy does.
                          if (_sort == choice.value) {
                            _direction = _direction == 'asc' ? 'desc' : 'asc';
                          } else {
                            _sort = choice.value;
                            _direction = 'asc';
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => Navigator.pop(
                context,
                (column: _sort, direction: _direction),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('تطبيق الترتيب'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final String direction;
  final VoidCallback onTap;

  const _SortTile({
    required this.label,
    required this.isActive,
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(
        isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        size: 20,
        color: isActive ? AppColors.primary : AppColors.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isActive
          ? Icon(
              direction == 'asc'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 18,
              color: AppColors.primary,
            )
          : null,
    );
  }
}
