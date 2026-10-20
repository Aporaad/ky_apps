import 'package:flutter/material.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_permission_model.dart';
import '../providers/admin_permissions_catalog_provider.dart';

/// مجموعة صلاحيات قسم واحد — اللبنة التي يكررها المنتقي لكل قسم في الكتالوج
/// One section's permission group — the unit the picker repeats for every catalog module.
///
/// التخطيط ثابت على ثلاث طبقات لأن الخطة تطلبه: رأس فيه اسم القسم وعدّاده، صف الأفعال الأساسية
/// بارز، ثم «صلاحيات أخرى» مطوي. والطيات ليست تجميلاً: أقسام بـ 11 صلاحية كانت ستدفع الشاشة
/// كلها للأسفل وتحول دون رؤية الأقسام التالية.
/// Three tiers as the plan specifies: header with title and counter, a prominent core-action row,
/// then a folded «صلاحيات أخرى». The folding is not decoration — an 11-permission module would
/// otherwise push every later section off screen.
class PermissionModuleGroup extends StatelessWidget {
  final AppPermissionModule module;
  final Set<String> selected;
  final void Function(String code) onToggle;

  /// تحديد/إلغاء مجموعة أكواد دفعة واحدة — «كل القسم» و«الأساسيات» و«مسح»
  /// Set or clear a batch of codes at once: whole section, basics, or none.
  final void Function(List<String> codes, bool select) onSetMany;

  /// صلاحيات الممنِح نفسه — ما لا يملكه يُعطَّل بصرياً بدل أن يرفضه الخادم لاحقاً
  /// The grantor's own permissions: ungrantable rows are dimmed rather than sent and refused.
  final bool Function(AppPermissionModel permission) canGrantOne;

  /// تعطيل كامل للمجموعة — يُستخدم لمستخدم يملك صفة مدير النظام فتصبح المنح الزائدة بلا معنى
  /// Whole-group disable — used for a system admin, where extra grants mean nothing.
  final bool disabled;

  /// رسالة البحث: تطابق الاسم العربي أو اللاتيني أو الكود، وتُطوى المجموعة الفارغة
  /// Search text: matches the Arabic name, English name, or code; empty groups get hidden.
  final String searchQuery;

  const PermissionModuleGroup({
    required this.module,
    required this.selected,
    required this.onToggle,
    required this.onSetMany,
    required this.canGrantOne,
    this.disabled = false,
    this.searchQuery = '',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visible = _visiblePermissions;
    if (visible.isEmpty) return const SizedBox.shrink();

    final core = visible
        .where((item) => item.isCore && !item.isWildcard)
        .toList(growable: false);
    final extras = visible
        .where((item) => !item.isCore && !item.isWildcard)
        .toList(growable: false);
    final wildcard = visible.where((item) => item.isWildcard).toList();

    final allCodes = sectionActionCodes(module);
    final coreCodes = sectionCoreCodes(module);
    final selectedHere = allCodes.where(selected.contains).length;
    final isFull =
        allCodes.isNotEmpty && selectedHere == allCodes.length && !isSearchOn;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selectedHere > 0 ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: module.title,
              moduleCode: module.moduleCode,
              selectedHere: selectedHere,
              total: allCodes.length,
              isFull: isFull,
              disabled: disabled,
            ),
            if (coreCodes.isNotEmpty && !isSearchOn && !disabled) ...[
              const SizedBox(height: 6),
              _QuickRow(
                isFull: isFull,
                selectedHere: selectedHere,
                onSelectAll: () => onSetMany(allCodes, !isFull),
                onSelectCore: () =>
                    onSetMany(coreCodes, !_onlyCoreSelected(coreCodes)),
                onClear: () => onSetMany(allCodes, false),
              ),
            ],
            const SizedBox(height: 10),
            if (wildcard.isNotEmpty)
              _PermissionChip(
                permission: wildcard.first,
                isSelected: selected.contains(wildcard.first.permissionCode),
                grantable: canGrantOne(wildcard.first),
                disabled: disabled,
                isWildcard: true,
                onTap: () => onToggle(wildcard.first.permissionCode),
              ),
            if (core.isNotEmpty) ...[
              const SizedBox(height: 10),
              // العرض الأقصى لكل شريحة من LayoutBuilder: `Wrap` يعطي أبناءه عرضاً غير محدود،
              // فاسم صلاحية طويل كان يتجاوز البطاقة بدل أن يُقطع
              // Each chip gets the card's width as its budget: Wrap measures children unbounded, so
              // a long permission name would run past the card instead of truncating.
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final permission in core)
                      _PermissionChip(
                        permission: permission,
                        isSelected: selected.contains(permission.permissionCode),
                        grantable: canGrantOne(permission),
                        disabled: disabled,
                        maxWidth: constraints.maxWidth,
                        onTap: () => onToggle(permission.permissionCode),
                      ),
                  ],
                ),
              ),
            ],
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 4),
              _ExtrasTile(
                count: extras.length,
                selectedCount: extras
                    .where((item) => selected.contains(item.permissionCode))
                    .length,
                childrenBuilder: (maxWidth) => [
                  for (final permission in extras)
                    _PermissionChip(
                      permission: permission,
                      isSelected: selected.contains(permission.permissionCode),
                      grantable: canGrantOne(permission),
                      disabled: disabled,
                      maxWidth: maxWidth,
                      onTap: () => onToggle(permission.permissionCode),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// هل يعمل بحثٌ الآن؟ عند البحث تُخفى الأزرار الجامعة لأن نتائجها أوسع مما يراه المستخدم
  /// Is a search active? While searching, the batch buttons hide: their effect is wider than
  /// what is on screen, and a «تحديد الكل» that silently adds invisible codes is a mislead.
  bool get isSearchOn => searchQuery.trim().isNotEmpty;

  /// الصلاحيات المطابقة للبحث داخل هذا القسم، بترتيب الخادم
  /// This section's search-matched permissions, keeping server order.
  List<AppPermissionModel> get _visiblePermissions {
    if (!isSearchOn) return module.permissions;
    final needle = searchQuery.trim().toLowerCase();

    return module.permissions
        .where(
          (item) =>
              item.permissionCode.toLowerCase().contains(needle) ||
              item.nameAr.toLowerCase().contains(needle) ||
              (item.nameEn ?? '').toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  bool _onlyCoreSelected(List<String> coreCodes) {
    if (coreCodes.isEmpty) return false;

    return coreCodes.every(selected.contains);
  }
}

/// ترويسة المجموعة: الاسم + المعرّف + عدّاد «m من n» + شارة «كل القسم»
/// Group header: title, module code, an «m of n» counter, and the whole-section badge.
class _Header extends StatelessWidget {
  final String title;
  final String moduleCode;
  final int selectedHere;
  final int total;
  final bool isFull;
  final bool disabled;

  const _Header({
    required this.title,
    required this.moduleCode,
    required this.selectedHere,
    required this.total,
    required this.isFull,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          disabled
              ? Icons.lock_rounded
              : selectedHere > 0
              ? Icons.shield_rounded
              : Icons.shield_outlined,
          size: 18,
          color: disabled
              ? AppColors.textMuted
              : selectedHere > 0
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: disabled ? AppColors.textMuted : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isFull)
          const _Badge(label: 'كل القسم', color: AppColors.success)
        else if (selectedHere > 0)
          _Badge(
            label: '$selectedHere من $total',
            color: AppColors.primary,
          ),
        const SizedBox(width: 6),
        Text(
          moduleCode,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textMuted,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// صف الأزرار السريعة للقسم
/// The section's quick-action row.
///
/// لا يُرسم أصلاً عند البحث أو عند المجموعة المقفلة، فلا حاجة لأي حارس داخلي هنا.
/// It never renders while searching or when the group is locked, so no inner guards are needed.
class _QuickRow extends StatelessWidget {
  final bool isFull;
  final int selectedHere;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectCore;
  final VoidCallback onClear;

  const _QuickRow({
    required this.isFull,
    required this.selectedHere,
    required this.onSelectAll,
    required this.onSelectCore,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    // `Wrap` لا `Row`: الأزرار الثلاثة معاً أعرض من بطاقة الجوال، و`Spacer` كان يدفع «مسح» خارج
    // الحافة.
    // A Wrap, not a Row: the three buttons together are wider than a phone card, and a Spacer
    // would have pushed «مسح» past the edge.
    return Wrap(
      spacing: 12,
      runSpacing: 0,
      children: [
        _QuickButton(
          label: isFull ? 'إلغاء كل القسم' : 'تحديد كل القسم',
          onTap: onSelectAll,
        ),
        _QuickButton(label: 'الأساسيات', onTap: onSelectCore),
        if (selectedHere > 0)
          _QuickButton(label: 'مسح', onTap: onClear, isDestructive: true),
      ],
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _QuickButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isDestructive ? AppColors.error : AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 11.5)),
    );
  }
}

/// «صلاحيات أخرى» مطوي — الأفعال غير الأساسية في قسم
/// The folded «صلاحيات أخرى» — a section's non-core actions.
class _ExtrasTile extends StatelessWidget {
  final int count;
  final int selectedCount;

  /// بناء الشرائح بالعرض المتاح فعلياً — لنفس سبب `LayoutBuilder` في صفّ الأساسيات
  /// The chips are built with the width actually available, same reason as the core row.
  final List<Widget> Function(double maxWidth) childrenBuilder;

  const _ExtrasTile({
    required this.count,
    required this.selectedCount,
    required this.childrenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 6, bottom: 2),
      initiallyExpanded: selectedCount > 0,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        selectedCount > 0
            ? 'صلاحيات أخرى ($count) — ممنوحة $selectedCount'
            : 'صلاحيات أخرى ($count)',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: childrenBuilder(constraints.maxWidth),
          ),
        ),
      ],
    );
  }
}

/// شريحة صلاحية واحدة: تسمية عربية + الكود + علامة اختيار، أو إطفاء إن لم تُمنح للممنِح
/// One permission chip: Arabic label, code, and a tick — dimmed when the grantor cannot grant it.
class _PermissionChip extends StatelessWidget {
  final AppPermissionModel permission;
  final bool isSelected;
  final bool grantable;
  final bool disabled;
  final bool isWildcard;
  final VoidCallback onTap;

  /// ميزانية العرض من `Wrap` المحيط — بلا هذه الحدود كان اسم صلاحية طويل يخرج من البطاقة
  /// The width budget from the surrounding Wrap; without it a long name escapes the card.
  final double maxWidth;

  const _PermissionChip({
    required this.permission,
    required this.isSelected,
    required this.grantable,
    required this.disabled,
    required this.onTap,
    this.isWildcard = false,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = disabled || !grantable;
    final color = blocked
        ? AppColors.textMuted
        : isSelected
        ? AppColors.primary
        : AppColors.textSecondary;
    final background = blocked
        ? AppColors.surfaceSubtle
        : isSelected
        ? AppColors.primary.withValues(alpha: 0.1)
        : Colors.white;

    final chip = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: InkWell(
        onTap: blocked ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected && !blocked ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected && !blocked
                    ? Icons.check_circle_rounded
                    : isWildcard
                    ? Icons.all_inclusive_rounded
                    : Icons.circle_outlined,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  permission.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                // التسمية العربية للفعل، وكوده اللاتيني إن كان الكتالوج جديداً بلا تسمية
                // The action's Arabic label, or its latin code when a new action has no label yet.
                permActionLabels[permActionOf(permission.permissionCode)] ??
                    permActionOf(permission.permissionCode),
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // التلميح يحمل الكود الحرفي دائماً: الممنِح يقرأ تسمية عربية لكنه يدقق بكود، والتسميات
    // تتكرر بين الأقسام («عرض» في عشرة أقسام) فلا تمييز بلا كود
    // The tooltip always carries the literal code: the grantor reads an Arabic label but audits by
    // code, and labels repeat across sections («عرض» appears in ten of them).
    return Tooltip(
      message: blocked && !disabled
          ? '${permission.permissionCode} — لا تملكها فلا تستطيع منحها'
          : permission.permissionCode,
      child: chip,
    );
  }
}

/// شارة صغيرة ملوّنة تُستخدم في الترويسات
/// A small coloured badge used in headers.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
