import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/provider_model.dart';
import '../../../data/repositories/service_result.dart';
import '../../../providers/services_providers.dart';

/// نموذج إنشاء/تعديل مزوّد — الاعتبارات لا تُرسل كأقنعة `***`
/// Provider create/edit form — credentials are never submitted as `***` masks.
///
/// عند التعديل تصل القيم مقنّعة إن لم يملك المستخدم صلاحية الكشف؛ نترك الحقل فارغًا بدل عرض `***`
/// حتى لا تُستبدل القيمة الحقيقية بالقناع. الخادم بدوره يتجاهل أي إرسال يساوي `***`.
/// On edit the values arrive masked without the reveal permission; we leave the field blank rather
/// than show `***`, so a real value is never overwritten by the mask. The server ignores `***` too.
class ProviderFormScreen extends ConsumerStatefulWidget {
  const ProviderFormScreen({this.provider, super.key});

  final ProviderModel? provider;

  bool get isEdit => provider != null;

  @override
  ConsumerState<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends ConsumerState<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late int _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.provider;
    _nameCtrl = TextEditingController(text: p?.providerName ?? '');
    _typeCtrl = TextEditingController(text: p?.type ?? '');
    _urlCtrl = TextEditingController(text: p?.url ?? '');
    // القيم المقنّعة `***` لا تُعبَّأ في الحقول (لا معنى لإعادة إرسالها)
    // Masked `***` values are not prefilled (resending them is meaningless).
    _userCtrl = TextEditingController(
      text: (p?.userName != null && p!.userName != '***') ? p.userName : '',
    );
    _passCtrl = TextEditingController(
      text: (p?.password != null && p!.password != '***') ? p.password : '',
    );
    _status = p?.status ?? 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'provider_name': _nameCtrl.text.trim(),
      'type': _typeCtrl.text.trim(),
      'url': _urlCtrl.text.trim(),
      'status': _status,
    };
    // نُرسل الاعتمادات فقط عند الكتابة الفعلية، لا الأقنعة
    // Send credentials only when actually typed, never the mask.
    if (_userCtrl.text.trim().isNotEmpty) payload['user_name'] = _userCtrl.text.trim();
    if (_passCtrl.text.trim().isNotEmpty) payload['password'] = _passCtrl.text.trim();

    final repo = ref.read(providerRepositoryProvider);
    final ServiceResult result = widget.isEdit
        ? await repo.updateProvider(widget.provider!.providerId, payload)
        : await repo.createProvider(payload);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(widget.isEdit ? 'تعديل مزوّد' : 'إضافة مزوّد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_nameCtrl, 'اسم المزود', Icons.storefront_rounded, required: true),
              const SizedBox(height: 12),
              _field(_typeCtrl, 'النوع', Icons.category_rounded),
              const SizedBox(height: 12),
              _field(_urlCtrl, 'الرابط (URL)', Icons.link_rounded),
              const SizedBox(height: 12),
              _field(_userCtrl, 'اسم المستخدم', Icons.person_rounded),
              const SizedBox(height: 12),
              _field(_passCtrl, 'كلمة المرور', Icons.lock_rounded, obscure: true),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مفعّل'),
                value: _status == 1,
                activeColor: AppColors.success,
                onChanged: (v) => setState(() => _status = v ? 1 : 0),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(widget.isEdit ? 'حفظ التعديلات' : 'إضافة المزوّد'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label مطلوب' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
