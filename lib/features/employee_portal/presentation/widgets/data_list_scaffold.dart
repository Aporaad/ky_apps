import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// إطار عمل متجاوب لشاشات عرض قوائم البيانات فقط
/// يُستخدم في: العملاء، الحسابات، العاملين، الفواتير، إلخ
/// يحتوي على: شريط بحث، فلترة، طباعة، تصدير، إضافة جديد، تحديث
class DataListScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  // أحداث الشريط العلوي
  final VoidCallback? onRefresh;
  final VoidCallback? onAddNew;

  // شريط البحث والفلترة
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilter;
  final VoidCallback? onSort;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;
  final Widget? filterChips;

  // المحتوى
  final Widget? content;
  final String? emptyTitle;
  final String? emptyDescription;
  final VoidCallback? onEmptyAction;
  final String? emptyActionLabel;

  // تحكم في ظهور الأزرار
  final bool showAddButton;
  final bool showRefreshButton;
  final bool showSearchBar;
  final bool showPrintExport;

  const DataListScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onRefresh,
    this.onAddNew,
    this.searchHint,
    this.onSearchChanged,
    this.onFilter,
    this.onSort,
    this.onPrint,
    this.onExport,
    this.filterChips,
    this.content,
    this.emptyTitle,
    this.emptyDescription,
    this.onEmptyAction,
    this.emptyActionLabel,
    this.showAddButton = true,
    this.showRefreshButton = true,
    this.showSearchBar = true,
    this.showPrintExport = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isNarrow = size.width < 600;
    final hPad = isNarrow ? 14.0 : 22.0;
    final vPad = isNarrow ? 12.0 : 18.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (vPad * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── رأس الصفحة ───────────────────────────────
                  _DataListHeader(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    textScaler: textScaler,
                    isNarrow: isNarrow,
                    showAddButton: showAddButton,
                    showRefreshButton: showRefreshButton,
                    onRefresh: onRefresh,
                    onAddNew: onAddNew,
                  ),

                  // ─── شريط البحث والفلترة ──────────────────────
                  if (showSearchBar) ...[
                    SizedBox(height: isNarrow ? 10 : 14),
                    _DataSearchBar(
                      hint: searchHint ?? 'بحث في $title...',
                      onChanged: onSearchChanged,
                      onFilter: onFilter,
                      onSort: onSort,
                      onPrint: onPrint,
                      onExport: onExport,
                      isNarrow: isNarrow,
                      showPrintExport: showPrintExport,
                    ),
                  ],

                  // ─── رقائق الفلترة (اختيارية) ─────────────────
                  if (filterChips != null) ...[
                    const SizedBox(height: 8),
                    filterChips!,
                  ],

                  SizedBox(height: isNarrow ? 10 : 14),

                  // ─── المحتوى ──────────────────────────────────
                  Expanded(
                    child: content ??
                        _DataEmptyState(
                          icon: icon,
                          title: emptyTitle ?? title,
                          description: emptyDescription ?? subtitle,
                          textScaler: textScaler,
                          actionLabel: emptyActionLabel,
                          onAction: onEmptyAction ?? onAddNew,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// رأس الصفحة مع أزرار الإضافة والتحديث
// ─────────────────────────────────────────────
class _DataListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final TextScaler textScaler;
  final bool isNarrow;
  final bool showAddButton;
  final bool showRefreshButton;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddNew;

  const _DataListHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.textScaler,
    required this.isNarrow,
    required this.showAddButton,
    required this.showRefreshButton,
    this.onRefresh,
    this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(isNarrow ? 17.0 : 19.0).clamp(13.0, 24.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.0 : 12.0).clamp(9.5, 15.0);

    final titleWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: isNarrow ? 17 : 20),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: scaledTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: scaledSub,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actionsWidget = Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showRefreshButton)
          OutlinedButton.icon(
            onPressed: onRefresh ?? () {},
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('تحديث'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 10 : 12,
                vertical: isNarrow ? 6 : 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(fontSize: isNarrow ? 12.0 : 13.0),
            ),
          ),
        if (showAddButton)
          ElevatedButton.icon(
            onPressed: onAddNew ?? () {},
            icon: const Icon(Icons.add_rounded, size: 15),
            label: const Text('إضافة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 10 : 14,
                vertical: isNarrow ? 6 : 8,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              textStyle: TextStyle(fontSize: isNarrow ? 12.0 : 13.0),
            ),
          ),
      ],
    );

    final hasActions = showRefreshButton || showAddButton;

    if (!hasActions) return titleWidget;

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleWidget,
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [actionsWidget]),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(child: titleWidget),
        const SizedBox(width: 10),
        actionsWidget,
      ],
    );
  }
}

// ─────────────────────────────────────────────
// شريط البحث والفلترة
// ─────────────────────────────────────────────
class _DataSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;
  final VoidCallback? onSort;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;
  final bool isNarrow;
  final bool showPrintExport;

  const _DataSearchBar({
    required this.hint,
    required this.isNarrow,
    required this.showPrintExport,
    this.onChanged,
    this.onFilter,
    this.onSort,
    this.onPrint,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(fontSize: isNarrow ? 12.5 : 13.5),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: isNarrow ? 12.0 : 13.0,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // زر الفلترة
          _ToolbarIconButton(
            icon: Icons.filter_list_rounded,
            tooltip: 'تصفية',
            onTap: onFilter,
          ),

          // على الشاشات الضيقة: قائمة إضافية
          if (isNarrow && showPrintExport) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 19),
              tooltip: 'خيارات',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {
                if (val == 'sort') onSort?.call();
                if (val == 'print') onPrint?.call();
                if (val == 'export') onExport?.call();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'sort',
                  child: _PopupItem(icon: Icons.sort_rounded, label: 'ترتيب'),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: _PopupItem(icon: Icons.print_outlined, label: 'طباعة'),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: _PopupItem(icon: Icons.download_outlined, label: 'تصدير'),
                ),
              ],
            ),
          ] else if (!isNarrow && showPrintExport) ...[
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.sort_rounded,
              tooltip: 'ترتيب',
              onTap: onSort,
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.print_outlined,
              tooltip: 'طباعة',
              onTap: onPrint,
            ),
            const SizedBox(width: 4),
            _ToolbarIconButton(
              icon: Icons.download_outlined,
              tooltip: 'تصدير',
              onTap: onExport,
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _PopupItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PopupItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// حالة الفراغ مع زر اختياري
// ─────────────────────────────────────────────
class _DataEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final TextScaler textScaler;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DataEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    required this.textScaler,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(15.0).clamp(12.0, 20.0);
    final scaledDesc = textScaler.scale(12.5).clamp(10.0, 16.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scaledTitle,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: scaledDesc,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(actionLabel ?? 'إضافة جديد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
