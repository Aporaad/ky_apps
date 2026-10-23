import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/permission_codes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/permission_gate.dart';
import '../../../data/models/provider_subscription_model.dart';
import '../../../data/models/service_model.dart';
import '../../../providers/providers_provider.dart';
import '../../../providers/service_config_provider.dart';
import '../../../providers/services_providers.dart';
import '../../widgets/credential_field.dart';

/// اشتراكات مزوّد (PROVIDERS_DTL) — قائمة + إضافة/حذف خلف providers.subscriptions_manage
/// A provider's subscriptions — list plus add/delete behind providers.subscriptions_manage.
class ProviderSubscriptionsScreen extends ConsumerWidget {
  const ProviderSubscriptionsScreen({
    required this.providerId,
    required this.providerName,
    super.key,
  });

  final int providerId;
  final String providerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(providerSubscriptionsProvider(providerId));
    // خريطة معرّف الخدمة => اسمها لجعل الاشتراكات مفهومة بدل عرض رقم خام
    // id→name map from the SERVICES dictionary, so subscriptions read as names not bare ids.
    final services = ref.watch(serviceConfigProvider).services;
    final nameById = {for (final s in services) s.serviceId: s.serviceName};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('اشتراكات $providerName'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(providerSubscriptionsProvider(providerId)),
          ),
        ],
      ),
      floatingActionButton: PermissionGate(
        code: Perm.providersSubscriptionsManage,
        child: FloatingActionButton(
          onPressed: () => _openAddForm(context, ref),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('فشل تحميل الاشتراكات', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(providerSubscriptionsProvider(providerId)),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (subs) => subs.isEmpty
            ? const Center(
                child: Text('لا توجد اشتراكات لهذا المزود',
                    style: TextStyle(color: AppColors.textMuted)),
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(providerSubscriptionsProvider(providerId)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SubscriptionCard(
                    sub: subs[i],
                    serviceName: nameById[subs[i].serviceId],
                    onDelete: () => _confirmDelete(context, ref, subs[i]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProviderSubscriptionModel sub,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الاشتراك'),
        content: const Text('حذف هذا الاشتراك نهائيًا؟'),
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
      final res =
          await ref.read(providerRepositoryProvider).deleteSubscription(sub.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
        if (res.success) ref.invalidate(providerSubscriptionsProvider(providerId));
      }
    }
  }

  void _openAddForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SubscriptionFormSheet(
        services: ref.read(serviceConfigProvider).services,
        onSubmit: (payload) async {
          final res = await ref
              .read(providerRepositoryProvider)
              .createSubscription(providerId, payload);
          if (res.success) {
            if (context.mounted) Navigator.pop(context);
            ref.invalidate(providerSubscriptionsProvider(providerId));
          }
          return res.message;
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.sub,
    required this.onDelete,
    this.serviceName,
  });

  final ProviderSubscriptionModel sub;
  final VoidCallback onDelete;
  final String? serviceName;

  bool get _masked => sub.password == '***' || sub.userName == '***' || sub.token == '***';

  @override
  Widget build(BuildContext context) {
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
              // اسم الخدمة المقروء إن توفر، وإلا رقم المعرّف كاحتياط
              // The readable service name when known, else the id as a fallback.
              Expanded(
                child: Text(
                  serviceName != null
                      ? serviceName!
                      : 'خدمة #${sub.serviceId ?? '—'}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (sub.isEnabled ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sub.isEnabled ? 'مفعّل' : 'موقوف',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: sub.isEnabled ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const Spacer(),
              PermissionGate(
                code: Perm.providersSubscriptionsManage,
                child: IconButton(
                  tooltip: 'حذف',
                  iconSize: 20,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          CredentialField(label: 'اسم المستخدم', value: sub.userName, isMaskedFromServer: _masked),
          CredentialField(label: 'كلمة المرور', value: sub.password, isMaskedFromServer: _masked),
          CredentialField(label: 'Token', value: sub.token, isMaskedFromServer: _masked),
          if (sub.url != null)
            CredentialField(label: 'URL', value: sub.url, isMaskedFromServer: false),
        ],
      ),
    );
  }
}

/// نموذج إضافة اشتراك — يُرسل service_id (مطلوب) وباقي الحقول اختيارية
/// Add-subscription form — sends the required service_id plus optional fields.
class _SubscriptionFormSheet extends StatefulWidget {
  const _SubscriptionFormSheet({required this.onSubmit, this.services = const []});

  final Future<String> Function(Map<String, dynamic> payload) onSubmit;
  final List<ServiceModel> services;

  @override
  State<_SubscriptionFormSheet> createState() => _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState extends State<_SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  int? _serviceId;
  int _status = 1;
  bool _busy = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الخدمة أولاً')),
      );
      return;
    }
    setState(() => _busy = true);
    final payload = <String, dynamic>{
      'service_id': _serviceId,
      'status': _status,
      if (_urlCtrl.text.trim().isNotEmpty) 'url': _urlCtrl.text.trim(),
      if (_userCtrl.text.trim().isNotEmpty) 'user_name': _userCtrl.text.trim(),
      if (_passCtrl.text.trim().isNotEmpty) 'password': _passCtrl.text.trim(),
      if (_tokenCtrl.text.trim().isNotEmpty) 'token': _tokenCtrl.text.trim(),
    };
    final message = await widget.onSubmit(payload);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('إضافة اشتراك',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // قائمة منسدلة للخدمات بدل إدخال رقم خام — أوضح وأقل عرضة للخطأ
            // A service dropdown instead of a raw id — clearer and less error-prone.
            DropdownButtonFormField<int>(
              value: _serviceId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الخدمة *'),
              items: [
                for (final s in widget.services)
                  DropdownMenuItem<int>(
                    value: s.serviceId,
                    child: Text('${s.serviceName}  (${s.serviceId})',
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _serviceId = v),
              validator: (v) => v == null ? 'الخدمة مطلوبة' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'URL')),
            const SizedBox(height: 10),
            TextFormField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
            const SizedBox(height: 10),
            TextFormField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
            const SizedBox(height: 10),
            TextFormField(controller: _tokenCtrl, decoration: const InputDecoration(labelText: 'Token')),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('مفعّل'),
              value: _status == 1,
              onChanged: (v) => setState(() => _status = v ? 1 : 0),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(_busy ? 'جارٍ الحفظ...' : 'حفظ الاشتراك'),
            ),
          ],
        ),
      ),
    );
  }
}
