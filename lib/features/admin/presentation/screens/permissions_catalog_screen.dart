import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_permission_model.dart';
import '../providers/admin_permissions_catalog_provider.dart';

/// شاشة كتالوج الصلاحيات — قراءة فقط للتدقيق
/// The permissions catalog: a read-only view for auditing.
///
/// لا تحديد ولا حفظ هنا: الشاشة تُجيب على سؤال «ما الأكواد الموجودة أصلاً؟» لمن يراجع منح
/// مستخدم، وأي زر تعديل كان سيجعلها نسخة ثانية من شاشة المنح بسلوك مختلف.
/// No selection and no saving: this screen answers «which codes exist at all?» for someone
/// auditing grants. An edit button here would fork the grant screen into a second, different one.
class PermissionsCatalogScreen extends ConsumerWidget {
  const PermissionsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(permissionsCatalogProvider);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('كتالوج الصلاحيات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(permissionsCatalogProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _Failure(
            message: 'تعذّر تحميل الكتالوج: $error',
            onRetry: () => ref.invalidate(permissionsCatalogProvider),
          ),
          data: (modules) => _CatalogBody(
            modules: modules,
            compact: width < 600,
          ),
        ),
      ),
    );
  }
}

/// جسم الكتالوج: بحث محلي + عدّاد + أقسام
/// The catalog body: local search, a counter, and the sections.
class _CatalogBody extends StatefulWidget {
  final List<AppPermissionModule> modules;
  final bool compact;

  const _CatalogBody({required this.modules, required this.compact});

  @override
  State<_CatalogBody> createState() => _CatalogBodyState();
}

class _CatalogBodyState extends State<_CatalogBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // الأقسام المطويّة — الفتح افتراضي، والطيّ أداة تصفّق لا طقس إخفاء. عند البحث تُفتح
  // الأقسام تلقائياً (يُتجاهل الطيّ) حتى لا يخفى عن المراجع ما طابق بحثه.
  // Collapsed sections: expanded by default; folding is a skimming aid, not an act of hiding.
  // While searching, folding is ignored so a match never hides behind a collapsed header.
  final Set<String> _collapsed = <String>{};
  bool get _allCollapsed =>
      widget.modules.isNotEmpty && _collapsed.length >= widget.modules.length;

  void _toggleModule(String code) => setState(() {
    if (!_collapsed.add(code)) _collapsed.remove(code);
  });

  void _toggleAll() => setState(() {
    if (_allCollapsed) {
      _collapsed.clear();
    } else {
      _collapsed.addAll(widget.modules.map((module) => module.moduleCode));
    }
  });

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// البحث محلي بالكامل: القائمة كلها محمّلة أصلاً، وطلب شبكة لكل حرف هنا بلا معنى
  /// Search is entirely local: the catalog is already loaded, so a request per keystroke is noise.
  List<AppPermissionModule> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.modules;

    return widget.modules
        .map((module) {
          final moduleMatches =
              module.moduleCode.toLowerCase().contains(query) ||
              module.nameAr.toLowerCase().contains(query);
          final rows = module.permissions
              .where(
                (permission) =>
                    permission.permissionCode.toLowerCase().contains(query) ||
                    permission.nameAr.toLowerCase().contains(query),
              )
              .toList(growable: false);

          if (rows.isEmpty && !moduleMatches) return null;

          return AppPermissionModule(
            moduleCode: module.moduleCode,
            nameAr: module.nameAr,
            permissions: moduleMatches ? module.permissions : rows,
          );
        })
        .whereType<AppPermissionModule>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final modules = _filtered;
    final totalCodes = widget.modules.fold<int>(
      0,
      (sum, module) => sum + module.permissions.length,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'ابحث بكود الصلاحية أو باسمها…',
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _query.isEmpty
                      ? '${widget.modules.length} وحدة · $totalCodes صلاحيّة'
                      : '${modules.length} وحدة مطابقة من ${widget.modules.length}'
                        ' · بحث: $_query',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              // زر طي/توسيع الكل — يظهر فقط خارج البحث لأن الأقسام تُفتح تلقائياً أثناءه
              // Collapse/expand-all toggle — only shown outside search, since sections auto-open then.
              if (_query.isEmpty && widget.modules.length > 1)
                TextButton.icon(
                  onPressed: _toggleAll,
                  icon: Icon(
                    _allCollapsed
                        ? Icons.unfold_more_rounded
                        : Icons.unfold_less_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _allCollapsed ? 'توسيع الكل' : 'طي الكل',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: modules.isEmpty
              ? const _NoMatch()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    // أثناء البحث تُفتح الأقسام قسراً حتى لا يختبئ المطابقة خلف طيّ
                    // While searching, sections are forced open so a match never hides behind a fold.
                    final expanded =
                        _query.trim().isNotEmpty ||
                        !_collapsed.contains(module.moduleCode);
                    return _ModuleCard(
                      module: module,
                      compact: widget.compact,
                      expanded: expanded,
                      showToggle: _query.trim().isEmpty,
                      onToggle: () => _toggleModule(module.moduleCode),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// بطاقة قسم: رأس بالرمز اللاتيني ثم صف لكل صلاحية — الرأس قابل للطيّ لتصفّق المراجعة
/// A section card: Latin-code header, then one row per permission. The header folds to help skim.
class _ModuleCard extends StatelessWidget {
  final AppPermissionModule module;
  final bool compact;
  final bool expanded;
  final bool showToggle;
  final VoidCallback onToggle;

  const _ModuleCard({
    required this.module,
    required this.compact,
    required this.expanded,
    required this.showToggle,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final wildcard = module.wildcardPermission;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الرأس كله قابل للنقر — مساحة النقر أكبر من السهم وحده، فالتصفح باللمس أسهل
            // Whole header is tappable — larger hit target than a chevron alone for touch skimming.
            InkWell(
              onTap: showToggle ? onToggle : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Row(
                  children: [
                    Icon(
                      expanded
                          ? Icons.folder_open_rounded
                          : Icons.folder_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        module.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${module.permissions.length}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (showToggle) ...[
                      const SizedBox(width: 4),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              if (wildcard != null) ...[
                const SizedBox(height: 8),
                _PermissionRow(
                  permission: wildcard,
                  tone: AppColors.accent,
                  compact: compact,
                ),
              ],
              const Divider(height: 18),
              for (final permission in module.corePermissions)
                _PermissionRow(permission: permission, compact: compact),
              if (module.extraPermissions.isNotEmpty) ...[
                const SizedBox(height: 4),
                _ExtrasExpander(
                  permissions: module.extraPermissions,
                  compact: compact,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// سطر «صلاحيات أخرى» مطوي — إحدى عشرة صلاحية في قسم واحد تبتلع الشاشة لو فُتحت كلها
/// A folded «other permissions» row — eleven permissions in one section would swallow the screen.
class _ExtrasExpander extends StatelessWidget {
  final List<AppPermissionModel> permissions;
  final bool compact;

  const _ExtrasExpander({required this.permissions, required this.compact});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 4),
      iconColor: AppColors.textMuted,
      collapsedIconColor: AppColors.textMuted,
      title: Text(
        'صلاحيات أخرى (${permissions.length})',
        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
      children: [
        for (final permission in permissions)
          _PermissionRow(permission: permission, compact: compact),
      ],
    );
  }
}

/// صف صلاحية واحدة: الاسم العربي ثم الكود الحرفي بأحرف ثابتة
/// One permission row: the Arabic name, then the literal code in monospace.
class _PermissionRow extends StatelessWidget {
  final AppPermissionModel permission;
  final bool compact;
  final Color? tone;

  const _PermissionRow({
    required this.permission,
    required this.compact,
    this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            permission.isWildcard ? Icons.all_inclusive : Icons.check_rounded,
            size: permission.isWildcard ? 16 : 14,
            color: tone ?? AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tone ?? AppColors.textPrimary,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 1),
                  Text(
                    permission.permissionCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (permission.isCore)
            const Text(
              'أساسية',
              style: TextStyle(fontSize: 10.5, color: AppColors.success),
            )
            else if (!permission.isWildcard)
              const Text(
                'إضافية',
                style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
              ),
        ],
      ),
    );
  }
}

/// لا نتيجة للبحث
/// No search result.
class _NoMatch extends StatelessWidget {
  const _NoMatch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'لا صلاحية يطابق هذا البحث — جرّب بادئة القسم مثل customers أو فعلاً مثل export.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.6),
        ),
      ),
    );
  }
}

/// فشل تحميل الكتالوج
/// A catalog load failure.
class _Failure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _Failure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
