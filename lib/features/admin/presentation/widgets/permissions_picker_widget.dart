import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_permission_model.dart';
import '../providers/admin_permissions_catalog_provider.dart';
import 'permission_module_group.dart';

/// المنتقي المشترك بين نموذج المستخدم وشاشة المنح — نسخة واحدة لا نسختان
/// The picker shared by the user form and the assign screen — one implementation, not two.
///
/// سبب المشاركة أن القرار D8 طلب «منح الصلاحيات داخل نموذج الحساب» بنفس تنظيم شاشة المنح. لو
/// كُتبت واجهتان لتباعدتا: شاشة تمنح «كل القسم» وأخرى لا تعرفها، والمنح حسّاس فلا يُحتمل اختلافه.
/// Shared because decision D8 asked for in-form granting with the same layout as the assign
/// screen. Two implementations would drift, and grants are too sensitive to drift.
class PermissionsPickerWidget extends ConsumerStatefulWidget {
  final Set<String> selected;
  final void Function(String code) onToggle;
  final void Function(List<String> codes, bool select) onSetMany;

  /// ما يملكه الممنِح: يُطفأ ما لا يستطيع منحه قبل الإرسال، فالخادم سيرفضه بـ `not_held`
  /// What the grantor holds: rows they cannot grant are dimmed before sending, since the server
  /// would refuse them as not_held.
  final Set<String> grantorPermissions;
  final bool grantorIsAdmin;

  /// تعطيل كامل — لمستخدم مدير النظام: كل الصلاحيات سارية بلا منح، فتعديل القائمة بلا معنى
  /// Fully disabled — for a system-admin target: everything is already effective, so editing
  /// the grant list would be meaningless.
  final bool disabled;

  /// نص مساعد أعلى المكوّن، يختلف بين النموذج («اختبر الأفعال قبل الحفظ») والشاشة
  /// Optional helper line above the picker; it differs between the form and the assign screen.
  final String? hint;

  const PermissionsPickerWidget({
    required this.selected,
    required this.onToggle,
    required this.onSetMany,
    required this.grantorPermissions,
    required this.grantorIsAdmin,
    this.disabled = false,
    this.hint,
    super.key,
  });

  @override
  ConsumerState<PermissionsPickerWidget> createState() =>
      _PermissionsPickerWidgetState();
}

class _PermissionsPickerWidgetState extends ConsumerState<PermissionsPickerWidget> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(permissionsCatalogProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(
            selectedCount: widget.selected.length,
            disabled: widget.disabled,
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.hint!,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          _SearchField(
            controller: _searchCtrl,
            hasQuery: _query.isNotEmpty,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          ),
          const SizedBox(height: 12),
          catalog.when(
            loading: () => const _PickerState(
              icon: Icons.hourglass_top_rounded,
              text: 'جارٍ تحميل كتالوج الصلاحيات…',
            ),
            error: (error, _) => _PickerState(
              icon: Icons.cloud_off_rounded,
              text: 'تعذّر تحميل الصلاحيات. بدون الكتالوج لا يمكن منح شيء.',
              onTap: () => ref.invalidate(permissionsCatalogProvider),
              actionLabel: 'إعادة المحاولة',
            ),
            data: (modules) => _Groups(
              modules: modules,
              query: _query,
              selected: widget.selected,
              disabled: widget.disabled,
              grantorPermissions: widget.grantorPermissions,
              grantorIsAdmin: widget.grantorIsAdmin,
              onToggle: widget.onToggle,
              onSetMany: widget.onSetMany,
            ),
          ),
        ],
      ),
    );
  }
}

/// الترويسة: العنوان + عدّاد الممنوح
/// Header: the title and the granted counter.
class _HeaderRow extends StatelessWidget {
  final int selectedCount;
  final bool disabled;

  const _HeaderRow({required this.selectedCount, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.key_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'الصلاحيات',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: disabled ? AppColors.surfaceSubtle : AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            disabled ? 'مدير النظام' : '$selectedCount صلاحيّة',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: disabled ? AppColors.textMuted : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// حقل البحث الداخلي — لا debounce لأن الفلترة محلية على كتالوج محمّل
/// The internal search box — no debounce, since filtering is local over an already-loaded catalog.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: 'ابحث باسم الصلاحية أو بكودها (مثل customers.create)',
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        suffixIcon: hasQuery
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

/// أزرار عامة على كل الكتالوج: مسح التحديد + مطابقة البحث
/// Catalog-wide actions: clear the selection, and what the search matched.
class _Groups extends StatelessWidget {
  final List<AppPermissionModule> modules;
  final String query;
  final Set<String> selected;
  final bool disabled;
  final Set<String> grantorPermissions;
  final bool grantorIsAdmin;
  final void Function(String code) onToggle;
  final void Function(List<String> codes, bool select) onSetMany;

  const _Groups({
    required this.modules,
    required this.query,
    required this.selected,
    required this.disabled,
    required this.grantorPermissions,
    required this.grantorIsAdmin,
    required this.onToggle,
    required this.onSetMany,
  });

  @override
  Widget build(BuildContext context) {
    final visibleModules = _matchingModules;

    if (visibleModules.isEmpty) {
      return const _PickerState(
        icon: Icons.search_off_rounded,
        text: 'لا توجد صلاحية مطابقة للبحث',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                query.trim().isEmpty
                    ? 'مرّتبة حسب أقسام النظام كما في الخادم'
                    : 'أقسام تحتوي المطابقة',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            if (!disabled && selected.isNotEmpty)
              TextButton(
                onPressed: () => onSetMany(selected.toList(growable: false), false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'مسح كل المحدد',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final module in visibleModules) ...[
          PermissionModuleGroup(
            module: module,
            selected: selected,
            onToggle: onToggle,
            onSetMany: onSetMany,
            disabled: disabled,
            searchQuery: query,
            canGrantOne: (permission) => canGrant(
              permission,
              granted: grantorPermissions,
              isAdmin: grantorIsAdmin,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// الأقسام التي فيها صلاحية مطابقة — والمجموعة الخالية لا تُعرض لأن بطاقتها الفارغة توحي
  /// بقسم بلا صلاحيات
  /// Modules containing a match — an empty group never renders, since its bare card would
  /// suggest the section itself has no permissions.
  List<AppPermissionModule> get _matchingModules {
    if (query.trim().isEmpty) return modules;
    final needle = query.trim().toLowerCase();

    return modules
        .where(
          (module) => module.permissions.any(
            (item) =>
                item.permissionCode.toLowerCase().contains(needle) ||
                item.nameAr.toLowerCase().contains(needle) ||
                (item.nameEn ?? '').toLowerCase().contains(needle),
          ),
        )
        .toList(growable: false);
  }
}

/// حالة داخل المنتقي: رسالة، وقد تحمل زر إعادة محاولة
/// A state inside the picker: a message, optionally with a retry button.
class _PickerState extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _PickerState({
    required this.icon,
    required this.text,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, size: 30, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(actionLabel ?? 'إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
