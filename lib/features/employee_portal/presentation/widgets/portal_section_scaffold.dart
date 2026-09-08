import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

/// إطار عمل متجاوب لأقسام بوابة الموظف يتكيف مع كافة مقاسات الشاشات
/// Responsive Section Scaffold for Employee Portal preventing all overflows
class PortalSectionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? searchHint;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddNew;
  final VoidCallback? onFilter;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;
  final ValueChanged<String>? onSearchChanged;
  final Widget? content;
  final String? emptyTitle;
  final String? emptyDescription;

  const PortalSectionScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.searchHint,
    this.onRefresh,
    this.onAddNew,
    this.onFilter,
    this.onPrint,
    this.onExport,
    this.onSearchChanged,
    this.content,
    this.emptyTitle,
    this.emptyDescription,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final verticalPadding = isMobile ? 16.0 : 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (verticalPadding * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. شريط العنوان والأزرار المتجاوب
                  _buildResponsiveHeader(isCompact),
                  const SizedBox(height: 16),

                  // 2. شريط البحث والفلترة المتجاوب
                  _buildResponsiveSearchBar(isCompact),
                  const SizedBox(height: 16),

                  // 3. مساحة المحتوى الرئيسية
                  Expanded(
                    child: content ?? _buildDefaultEmptyContent(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// رأس القسم المتجاوب: يتحول من Row إلى Column على الشاشات الصغيرة
  Widget _buildResponsiveHeader(bool isCompact) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actionsWidget = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onRefresh ?? () {},
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('تحديث'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAddNew ?? () {},
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('إضافة جديد'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleWidget,
          const SizedBox(height: 12),
          actionsWidget,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleWidget),
        const SizedBox(width: 16),
        actionsWidget,
      ],
    );
  }

  /// شريط البحث والفرز والفلترة المتجاوب مع تجميع الخيارات الإضافية في قائمة منسدلة على الشاشات الضيقة
  Widget _buildResponsiveSearchBar(bool isCompact) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: searchHint ?? 'بحث في $title...',
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // زر الفلترة السريعة
          IconButton.outlined(
            onPressed: onFilter ?? () {},
            icon: const Icon(Icons.filter_list_rounded, size: 18),
            tooltip: 'تصفية',
            visualDensity: VisualDensity.compact,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
            ),
          ),

          if (isCompact) ...[
            const SizedBox(width: 4),
            // قائمة الخيارات الإضافية على الشاشات الضيقة
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              tooltip: 'المزيد من الخيارات',
              onSelected: (val) {
                if (val == 'print') onPrint?.call();
                if (val == 'export') onExport?.call();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('طباعة'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('تصدير البيانات'),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onPrint ?? () {},
              icon: const Icon(Icons.print_outlined, size: 18),
              tooltip: 'طباعة',
              visualDensity: VisualDensity.compact,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: onExport ?? () {},
              icon: const Icon(Icons.download_outlined, size: 18),
              tooltip: 'تصدير',
              visualDensity: VisualDensity.compact,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بطاقة الحالة الافتراضية
  Widget _buildDefaultEmptyContent() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle ?? 'بيانات $title جاهزة للربط مع قاعدة بيانات Oracle',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyDescription ?? 'يمكن استعراض الجداول والاستعلام عنها عبر API أوراكل',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
