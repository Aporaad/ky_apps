import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/permission_codes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/permission_gate.dart';
import '../../../data/models/corp_model.dart';
import '../../../data/models/service_model.dart';
import '../../../providers/service_config_provider.dart';

/// شاشة إعدادات الخدمات — تحرير CORP (settings_manage) وقاموس SERVICES (update)
/// Service-config screen — edit the CORP singleton (settings_manage) and the SERVICES dictionary.
///
/// الفصل مقصود: تحرير بيانات الشركة أخطر من عرض القاموس، لذا لكلٍ بوابته. الحقول تُعرض للقراءة
/// لمن يملك services.view، وتصبح قابلة للتحرير فقط مع صلاحية الحفظ.
/// Split on purpose: editing CORP is riskier than reading SERVICES, so each has its own gate. Fields
/// are readable with services.view but only editable with the save permission.
class ServiceConfigScreen extends ConsumerStatefulWidget {
  const ServiceConfigScreen({super.key});

  @override
  ConsumerState<ServiceConfigScreen> createState() => _ServiceConfigScreenState();
}

class _ServiceConfigScreenState extends ConsumerState<ServiceConfigScreen> {
  bool _initialized = false;

  final _corpName = TextEditingController();
  final _corpAddr = TextEditingController();
  final _corpTel1 = TextEditingController();
  final _corpTel2 = TextEditingController();
  final _sanfType = TextEditingController();
  final _filePath = TextEditingController();

  @override
  void dispose() {
    _corpName.dispose();
    _corpAddr.dispose();
    _corpTel1.dispose();
    _corpTel2.dispose();
    _sanfType.dispose();
    _filePath.dispose();
    super.dispose();
  }

  void _seed(CorpModel? corp) {
    if (_initialized || corp == null) return;
    _corpName.text = corp.corpName ?? '';
    _corpAddr.text = corp.corpAddr ?? '';
    _corpTel1.text = corp.corpTel1 ?? '';
    _corpTel2.text = corp.corpTel2 ?? '';
    _sanfType.text = corp.sanfType?.toString() ?? '';
    _filePath.text = corp.filePath ?? '';
    _initialized = true;
  }

  Future<void> _saveCorp() async {
    final res = await ref.read(serviceConfigProvider.notifier).saveCorp({
      'corp_name': _corpName.text.trim(),
      'corp_addr': _corpAddr.text.trim(),
      if (_corpTel1.text.trim().isNotEmpty) 'corp_tel1': _corpTel1.text.trim(),
      if (_corpTel2.text.trim().isNotEmpty) 'corp_tel2': _corpTel2.text.trim(),
      if (_sanfType.text.trim().isNotEmpty) 'sanf_type': int.tryParse(_sanfType.text.trim()),
      'file_path': _filePath.text.trim(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceConfigProvider);
    _seed(state.corp);

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
        title: const Text('إعدادات الخدمات'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(serviceConfigProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.corp == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.corp == null
              ? Center(child: Text(state.error!, style: TextStyle(color: AppColors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SectionCard(
                      title: 'بيانات الشركة (CORP)',
                      icon: Icons.business_rounded,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(_corpName, 'اسم الشركة'),
                          _field(_corpAddr, 'العنوان'),
                          _field(_corpTel1, 'هاتف 1', number: true),
                          _field(_corpTel2, 'هاتف 2', number: true),
                          _field(_sanfType, 'نوع الفوترة (SANF)', number: true),
                          _field(_filePath, 'مسار الملفات'),
                          const SizedBox(height: 8),
                          PermissionGate(
                            code: Perm.servicesSettingsManage,
                            child: ElevatedButton.icon(
                              onPressed: _saveCorp,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('حفظ بيانات الشركة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ServicesPanel(services: state.services),
                  ],
                ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );
}

/// لوحة قاموس SERVICES — عرض + إضافة/حذف خلف services.update
/// The SERVICES dictionary panel — view plus add/delete behind services.update.
class _ServicesPanel extends ConsumerStatefulWidget {
  const _ServicesPanel({required this.services});

  final List<ServiceModel> services;

  @override
  ConsumerState<_ServicesPanel> createState() => _ServicesPanelState();
}

class _ServicesPanelState extends ConsumerState<_ServicesPanel> {
  Future<void> _add() async {
    final name = await _askText('اسم الخدمة الجديد');
    if (name == null || name.trim().isEmpty) return;
    final res = await ref.read(serviceConfigProvider.notifier).addService({
      'service_name': name.trim(),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
  }

  Future<void> _delete(ServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف خدمة'),
        content: Text('حذف «${s.serviceName}»؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final res = await ref.read(serviceConfigProvider.notifier).removeService(s.serviceId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
    }
  }

  Future<String?> _askText(String label) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'قاموس الخدمات (SERVICES)',
      icon: Icons.category_rounded,
      trailing: PermissionGate(
        code: Perm.servicesUpdate,
        child: IconButton(
          tooltip: 'إضافة خدمة',
          icon: const Icon(Icons.add_rounded),
          onPressed: _add,
        ),
      ),
      child: widget.services.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('لا توجد خدمات مسجلة', style: TextStyle(color: AppColors.textMuted)),
            )
          : Column(
              children: [
                for (final s in widget.services)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text('${s.serviceId}',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    // رقم + اسم + نوع الخدمة — تفاصيل واضحة بدل الاسم وحده
                    // Service number + name + type — explicit details instead of name alone.
                    title: Text(
                      s.serviceName.isEmpty ? 'خدمة بلا اسم' : s.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'رقم: ${s.serviceId}'
                      '${(s.serviceType != null && s.serviceType!.isNotEmpty) ? ' • النوع: ${s.serviceType}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    trailing: PermissionGate(
                      code: Perm.servicesUpdate,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.error),
                        onPressed: () => _delete(s),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
