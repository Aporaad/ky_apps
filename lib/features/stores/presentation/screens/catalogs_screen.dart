import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/store_reference.dart';
import '../../data/repositories/store_result.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';

/// الوحدات والمجموعات: المجموعات [رئيسية/فرعية] · الوحدات · الفئات
/// Units and groups: main/sub groups · units · categories.
///
/// ── لماذا شجرة في تبويب المجموعات؟ لأن «المجموعة الفرعية» لا معنى لها بلا أبيها؛ عرضها
///    كقائمة مسطحة يجعل نوعين باسم متشابه من مجموعتين مختلفتين غير قابلين للتمييز.
/// ── Why a tree for groups? A sub group has no meaning without its parent; a flat list would
///    make two similarly named types from different groups indistinguishable.
class CatalogsScreen extends ConsumerStatefulWidget {
  const CatalogsScreen({super.key});

  @override
  ConsumerState<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends ConsumerState<CatalogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final state = ref.watch(catalogsProvider);
    final canManage = auth.can(Perm.storesCatalogsManage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الوحدات والمجموعات'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'المجموعات'),
            Tab(text: 'الوحدات'),
            Tab(text: 'الفئات'),
          ],
        ),
      ),
      body: state.isLoading
          ? const StoreLoading()
          : state.error != null
          ? StoreErrorState(
              message: state.error!,
              onRetry: ref.read(catalogsProvider.notifier).load,
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _GroupsTab(canManage: canManage),
                _UnitsTab(canManage: canManage),
                _CategoriesTab(canManage: canManage),
              ],
            ),
    );
  }
}

/// تبويب المجموعات: كل مجموعة رئيسية وتحتها أنواعها
/// The groups tab: every main group with its sub types underneath.
class _GroupsTab extends ConsumerWidget {
  const _GroupsTab({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogsProvider);

    if (state.groups.isEmpty) {
      return StoreEmptyState(
        icon: Icons.account_tree_outlined,
        title: 'لا توجد مجموعات',
        actionLabel: canManage ? 'مجموعة جديدة' : null,
        onAction: canManage
            ? () => _openForm(context, ref, kind: 'groups', title: 'مجموعة رئيسية جديدة')
            : null,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      children: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openForm(
                      context,
                      ref,
                      kind: 'groups',
                      title: 'مجموعة رئيسية جديدة',
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('مجموعة رئيسية'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openForm(
                      context,
                      ref,
                      kind: 'types',
                      title: 'مجموعة فرعية جديدة',
                      groups: state.groups,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('مجموعة فرعية'),
                  ),
                ),
              ],
            ),
          ),
        for (final group in state.groups)
          _GroupTile(
            group: group,
            types: state.types
                .where((type) => type.groupNo == group.groupNo)
                .toList(growable: false),
            canManage: canManage,
          ),
      ],
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({
    required this.group,
    required this.types,
    required this.canManage,
  });

  final StoreGroupModel group;
  final List<StoreTypeModel> types;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.folder_outlined, size: 19, color: AppColors.primary),
        title: Text(
          group.groupName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${types.length} مجموعة فرعية · ${group.items} صنف',
          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
        ),
        trailing: canManage
            ? PopupMenuButton<String>(
                tooltip: 'إجراءات',
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _openForm(
                      context,
                      ref,
                      kind: 'groups',
                      title: 'تعديل المجموعة',
                      id: group.groupNo,
                      initialName: group.groupName,
                    );
                  } else if (value == 'delete') {
                    await _run(
                      context,
                      () => ref
                          .read(catalogsProvider.notifier)
                          .remove('groups', group.groupNo),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('تعديل')),
                  PopupMenuItem(value: 'delete', child: Text('حذف')),
                ],
              )
            : null,
        children: [
          for (final type in types)
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.subdirectory_arrow_left_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              title: Text(
                type.typeName,
                style: const TextStyle(fontSize: 12.5),
              ),
              subtitle: Text(
                'رقم ${type.typeNo} · ${type.items} صنف',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
              trailing: canManage
                  ? PopupMenuButton<String>(
                      tooltip: 'إجراءات',
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _openForm(
                            context,
                            ref,
                            kind: 'types',
                            title: 'تعديل المجموعة الفرعية',
                            id: type.typeNo,
                            initialName: type.typeName,
                            groups: ref.read(catalogsProvider).groups,
                            groupNo: type.groupNo,
                          );
                        } else if (value == 'delete') {
                          await _run(
                            context,
                            () => ref
                                .read(catalogsProvider.notifier)
                                .remove('types', type.typeNo),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    )
                  : null,
            ),
          if (types.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'لا مجموعات فرعية تحت هذه المجموعة',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// تبويب الوحدات
/// The units tab.
class _UnitsTab extends ConsumerWidget {
  const _UnitsTab({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogsProvider);

    return _SimpleCatalogList(
      title: 'الوحدات',
      items: [
        for (final unit in state.units)
          _CatalogRow(
            id: unit.unitNo,
            name: unit.unitName,
            subtitle: '${unit.items} صنف',
          ),
      ],
      kind: 'units',
      canManage: canManage,
      emptyTitle: 'لا توجد وحدات',
    );
  }
}

/// تبويب الفئات
/// The categories tab.
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogsProvider);

    return _SimpleCatalogList(
      title: 'الفئات',
      items: [
        for (final category in state.categories)
          _CatalogRow(
            id: category.id,
            name: category.name,
            subtitle: 'رقم ${category.catNo ?? category.id} · ${category.items} صنف',
          ),
      ],
      kind: 'categories',
      canManage: canManage,
      emptyTitle: 'لا توجد فئات',
    );
  }
}

class _CatalogRow {
  const _CatalogRow({required this.id, required this.name, this.subtitle});

  final int id;
  final String name;
  final String? subtitle;
}

class _SimpleCatalogList extends ConsumerWidget {
  const _SimpleCatalogList({
    required this.title,
    required this.items,
    required this.kind,
    required this.canManage,
    required this.emptyTitle,
  });

  final String title;
  final List<_CatalogRow> items;
  final String kind;
  final bool canManage;
  final String emptyTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return StoreEmptyState(
        icon: Icons.list_alt_rounded,
        title: emptyTitle,
        actionLabel: canManage ? 'إضافة' : null,
        onAction: canManage
            ? () => _openForm(context, ref, kind: kind, title: 'إضافة إلى $title')
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: items.length + (canManage ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (canManage && index == 0) {
          return OutlinedButton.icon(
            onPressed: () =>
                _openForm(context, ref, kind: kind, title: 'إضافة إلى $title'),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('إضافة إلى $title'),
          );
        }

        final row = items[canManage ? index - 1 : index];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (row.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.subtitle!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  tooltip: 'إجراءات',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _openForm(
                        context,
                        ref,
                        kind: kind,
                        title: 'تعديل',
                        id: row.id,
                        initialName: row.name,
                      );
                    } else if (value == 'delete') {
                      await _run(
                        context,
                        () => ref
                            .read(catalogsProvider.notifier)
                            .remove(kind, row.id),
                      );
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// حوار إضافة/تعديل عنصر مرجعي
/// The add/edit catalog entry dialog.
Future<void> _openForm(
  BuildContext context,
  WidgetRef ref, {
  required String kind,
  required String title,
  int? id,
  String? initialName,
  List<StoreGroupModel>? groups,
  int? groupNo,
}) async {
  final nameController = TextEditingController(text: initialName ?? '');
  var selectedGroup = groupNo ?? (groups?.isNotEmpty == true ? groups!.first.groupNo : null);
  String? error;
  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    errorText: error,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (kind == 'types' && groups != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedGroup,
                    decoration: const InputDecoration(
                      labelText: 'المجموعة الرئيسية',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final group in groups)
                        DropdownMenuItem(
                          value: group.groupNo,
                          child: Text(
                            group.groupName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => selectedGroup = value),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        setState(() => error = 'الاسم مطلوب');

                        return;
                      }

                      setState(() {
                        saving = true;
                        error = null;
                      });

                      final payload = <String, dynamic>{
                        'name': name,
                        if (kind == 'types') 'group_no': selectedGroup,
                      };

                      final notifier = ref.read(catalogsProvider.notifier);
                      final StoreResult result = id == null
                          ? await notifier.create(kind, payload)
                          : await notifier.update(kind, id, payload);

                      if (!context.mounted) return;

                      setState(() => saving = false);

                      if (result.success) {
                        Navigator.pop(context);
                      } else {
                        setState(() => error = result.displayMessage);
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        );
      },
    ),
  );

  nameController.dispose();
}

/// تنفيذ عملية حذف وإظهار نتيجتها
/// Run a delete and surface its outcome.
Future<void> _run(BuildContext context, Future<StoreResult> Function() action) async {
  final result = await action();

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.success ? 'تم الحذف' : result.displayMessage),
      backgroundColor: result.success ? AppColors.success : AppColors.error,
    ),
  );
}
