import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/store_model.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';
import 'store_form_screen.dart';

/// إدارة المخازن وأمنائها — تبويبان
/// Store registry and keepers — two tabs.
class StoresListScreen extends ConsumerStatefulWidget {
  const StoresListScreen({super.key});

  @override
  ConsumerState<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends ConsumerState<StoresListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // المزود `NotifierProvider` غير `autoDispose`: آخر نص بحث بقي في
    // `state.search` بعد كل رجوع إلى اللوحة ثم فتح الشاشة من جديد، فتُعرض
    // قائمة مُفلترة خلف حقل فارغ — نفس شكوى البحث العالق التي تعمّ التطبيق.
    // The provider is not autoDispose, so the last search text lived in
    // `state.search` across every dashboard trip and a filtered list kept
    // showing behind a freshly empty field. Wiping here is the same fix as
    // every other sticky-search complaint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(storesListProvider.notifier).resetTransient(reload: true);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final canCreate = auth.can(Perm.storesCreate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المخازن والأمناء'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'المخازن'),
            Tab(text: 'أمناء المخازن'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabs.index == 0
            ? _openStoreForm(context)
            : _openKeeperForm(context, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabs.index == 0 ? 'مخزن جديد' : 'أمين جديد'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StoresTab(
            searchController: _searchController,
            canCreate: canCreate,
            onAdd: () => _openStoreForm(context),
            onEdit: (store) => _openStoreForm(context, store: store),
          ),
          const _KeepersTab(),
        ],
      ),
    );
  }

  Future<void> _openStoreForm(BuildContext context, {StoreModel? store}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoreFormScreen(store: store)),
    );

    if (!mounted) return;

    ref.read(storesListProvider.notifier).load();
  }

  Future<void> _openKeeperForm(BuildContext context, StoreKeeperModel? keeper) async {
    final reference = await ref.read(storeReferenceProvider.future);
    final stores = reference.stores;

    if (!context.mounted) return;

    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مخازن لإسناد الأمين إليها')),
      );

      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => _KeeperDialog(keeper: keeper, stores: stores),
    );
  }
}

/// تبويب المخازن
/// The stores tab.
class _StoresTab extends ConsumerWidget {
  const _StoresTab({
    required this.searchController,
    required this.canCreate,
    required this.onAdd,
    required this.onEdit,
  });

  final TextEditingController searchController;
  final bool canCreate;
  final VoidCallback onAdd;
  final void Function(StoreModel store) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storesListProvider);
    final notifier = ref.read(storesListProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final canUpdate = auth.can(Perm.storesUpdate);
    final canDelete = auth.can(Perm.storesDelete);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: notifier.search,
            onChanged: (value) {
              if (value.isEmpty) notifier.search('');
            },
            decoration: InputDecoration(
              hintText: 'بحث باسم المخزن...',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 19),
                onPressed: notifier.load,
                tooltip: 'تحديث',
              ),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const StoreLoading()
              : state.error != null
              ? StoreErrorState(message: state.error!, onRetry: notifier.load)
              : state.stores.isEmpty
              ? StoreEmptyState(
                  icon: Icons.warehouse_outlined,
                  title: 'لا توجد مخازن',
                  description: 'أضف أول مخزن لتبدأ بإدارة الأرصدة والمستندات.',
                  actionLabel: canCreate ? 'مخزن جديد' : null,
                  onAction: canCreate ? onAdd : null,
                )
              : RefreshIndicator(
                  onRefresh: notifier.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                    itemCount: state.stores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final store = state.stores[index];

                      return _StoreCard(
                        store: store,
                        onEdit: canUpdate ? () => onEdit(store) : null,
                        onDelete: canDelete
                            ? () => _confirmDelete(context, ref, store)
                            : null,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    StoreModel store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف مخزن'),
        content: Text(
          'سيُحذف المخزن «${store.storeName}» مع أمنائه. '
          'لا يمكن الحذف إن كان له مستندات أو رصيد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(storesListProvider.notifier).remove(store.storeNo);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success ? 'تم حذف المخزن' : result.displayMessage),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, this.onEdit, this.onDelete});

  final StoreModel store;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: store.archived
              ? AppColors.warning.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.warehouse_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.storeName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'رقم ${store.storeNo}'
                      '${store.location != null ? ' · ${store.location}' : ''}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (store.archived)
                const StoreTag(
                  label: 'أرشيفي',
                  color: AppColors.warning,
                  icon: Icons.archive_outlined,
                ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  tooltip: 'إجراءات',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined, size: 18),
                          title: Text('تعديل'),
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          title: Text(
                            'حذف',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StoreTag(
                label: '${store.items} صنف',
                icon: Icons.inventory_2_outlined,
              ),
              StoreTag(
                label: 'الكمية ${StoreFormat.qty(store.qty)}',
                icon: Icons.straighten_rounded,
                color: AppColors.info,
              ),
              StoreTag(
                label: StoreFormat.money(store.value),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              StoreTag(
                label: '${store.keepers} أمين',
                icon: Icons.person_outline_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          if (store.note != null) ...[
            const SizedBox(height: 7),
            Text(
              store.note!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// تبويب الأمناء
/// The keepers tab.
class _KeepersTab extends ConsumerWidget {
  const _KeepersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(keepersProvider);
    final notifier = ref.read(keepersProvider.notifier);
    final auth = ref.watch(authNotifierProvider);
    final canManage = auth.can(Perm.storesKeepersManage);

    return state.isLoading
        ? const StoreLoading()
        : state.error != null
        ? StoreErrorState(message: state.error!, onRetry: notifier.load)
        : state.keepers.isEmpty
        ? const StoreEmptyState(
            icon: Icons.person_outline_rounded,
            title: 'لا يوجد أمناء مخازن',
            description: 'أضف أميناً وأسنده إلى مخزن ليكون مسؤولاً عنه.',
          )
        : RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: state.keepers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final keeper = state.keepers[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          keeper.empName.isEmpty
                              ? '؟'
                              : keeper.empName.substring(0, 1),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              keeper.empName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'المخزن: ${keeper.storeName ?? keeper.storeNo}'
                              ' · رقم ${keeper.empNo}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          tooltip: 'إجراءات',
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final result =
                                  await notifier.remove(keeper.empNo);

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result.success
                                        ? 'تم حذف الأمين'
                                        : result.displayMessage,
                                  ),
                                  backgroundColor: result.success
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                title: Text(
                                  'حذف',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          );
  }
}

/// حوار إضافة/تعديل أمين مخزن
/// The add/edit keeper dialog.
class _KeeperDialog extends ConsumerStatefulWidget {
  const _KeeperDialog({required this.keeper, required this.stores});

  final StoreKeeperModel? keeper;
  final List<StoreModel> stores;

  @override
  ConsumerState<_KeeperDialog> createState() => _KeeperDialogState();
}

class _KeeperDialogState extends ConsumerState<_KeeperDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.keeper?.empName ?? '',
  );
  late int? _storeNo = widget.keeper?.storeNo ?? widget.stores.first.storeNo;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.keeper == null ? 'أمين مخزن جديد' : 'تعديل أمين المخزن',
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'اسم الأمين',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _storeNo,
              decoration: const InputDecoration(
                labelText: 'المخزن',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final store in widget.stores)
                  DropdownMenuItem(
                    value: store.storeNo,
                    child: Text(
                      store.storeName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _storeNo = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'الاسم مطلوب');

      return;
    }

    if (_storeNo == null) {
      setState(() => _error = 'المخزن مطلوب');

      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref
        .read(keepersProvider.notifier)
        .save(
          empNo: widget.keeper?.empNo,
          payload: {'emp_name': name, 'store_no': _storeNo},
        );

    if (!mounted) return;

    setState(() => _saving = false);

    if (result.success) {
      Navigator.pop(context);
    } else {
      setState(() => _error = result.displayMessage);
    }
  }
}
