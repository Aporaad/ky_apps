import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/permission_codes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/permission_gate.dart';
import '../../../data/models/provider_model.dart';
import '../../../providers/providers_provider.dart';
import 'provider_form_screen.dart';
import 'provider_subscriptions_screen.dart';

/// قائمة المزودين — بحث مُهلَّل + تبديل حالة + دخول الاشتراكات، خلف بوابات providers.*
/// Providers list — debounced search + status toggle + subscriptions, gated by providers.*.
class ProvidersListScreen extends ConsumerStatefulWidget {
  const ProvidersListScreen({super.key});

  @override
  ConsumerState<ProvidersListScreen> createState() => _ProvidersListScreenState();
}

class _ProvidersListScreenState extends ConsumerState<ProvidersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('المزودون'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(providersListProvider.notifier).load(),
          ),
        ],
      ),
      floatingActionButton: PermissionGate(
        code: Perm.providersCreate,
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProviderFormScreen()),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (q) =>
                  ref.read(providersListProvider.notifier).search(q),
              decoration: InputDecoration(
                hintText: 'بحث باسم المزود أو النوع...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(providersListProvider.notifier).search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(ProvidersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _ErrorState(
        message: state.error!,
        onRetry: () => ref.read(providersListProvider.notifier).load(),
      );
    }
    if (state.providers.isEmpty) {
      return const _EmptyState();
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(providersListProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ProviderCard(provider: state.providers[i]),
      ),
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({required this.provider});

  final ProviderModel provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: provider.isEnabled
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                child: Text(
                  '#${provider.providerId}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: provider.isEnabled ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.providerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (provider.type != null)
                      Text(
                        provider.type!,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              _StatusChip(enabled: provider.isEnabled),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // تعديل خلف providers.update، والاشتراكات خلف providers.subscriptions_manage
              // Edit under providers.update; subscriptions under providers.subscriptions_manage.
              PermissionGate(
                code: Perm.providersUpdate,
                child: _Action(
                  icon: Icons.edit_rounded,
                  label: 'تعديل',
                  color: AppColors.accent,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderFormScreen(provider: provider),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PermissionGate(
                code: Perm.providersSubscriptionsManage,
                child: _Action(
                  icon: Icons.subscriptions_rounded,
                  label: 'الاشتراكات',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProviderSubscriptionsScreen(
                        providerId: provider.providerId,
                        providerName: provider.providerName,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PermissionGate(
                code: Perm.providersToggle,
                child: IconButton(
                  tooltip: provider.isEnabled ? 'تعطيل' : 'تفعيل',
                  iconSize: 20,
                  icon: Icon(
                    provider.isEnabled
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    color: provider.isEnabled ? AppColors.success : AppColors.textMuted,
                  ),
                  onPressed: () => _confirmToggle(context, ref),
                ),
              ),
              PermissionGate(
                code: Perm.providersDelete,
                child: IconButton(
                  tooltip: 'حذف',
                  iconSize: 20,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmToggle(BuildContext context, WidgetRef ref) async {
    final res = await ref
        .read(providersListProvider.notifier)
        .toggle(provider.providerId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المزود'),
        content: Text('حذف «${provider.providerName}» نهائيًا؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await ref
          .read(providersListProvider.notifier)
          .delete(provider.providerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        enabled ? 'مفعّل' : 'موقوف',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.error),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined, size: 56, color: AppColors.textMuted),
          SizedBox(height: 14),
          Text('لا يوجد مزودون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
