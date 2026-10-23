import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/oracle_job_model.dart';
import '../../../providers/jobs_provider.dart';

/// نموذج إنشاء/تعديل مهمة DBMS_SCHEDULER — المهلة والأمر (الاسم ثابت عند التعديل)
/// Create/edit a DBMS_SCHEDULER job — interval and action (the name is fixed on edit).
///
/// عند التعديل لا يغيّر الخادم الاسم (SET_ATTRIBUTE على سطر موجود)، فتحقلُ الاسم يُعطَّل. الأمر
/// PL/SQL block نصٌ حر؛ والمهلة بصيغة تكرار أوراكل مثل `freq=interval;interval=3`.
/// On edit the server changes attributes in place, never the name, so the name field is disabled. The
/// action is free PL/SQL; the interval uses Oracle syntax like `freq=interval;interval=3`.
class JobFormScreen extends ConsumerStatefulWidget {
  const JobFormScreen({this.job, super.key});

  final OracleJobModel? job;

  bool get isEdit => job != null;

  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _intervalCtrl;
  late final TextEditingController _actionCtrl;
  late bool _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final j = widget.job;
    _nameCtrl = TextEditingController(text: j?.jobName ?? '');
    _intervalCtrl = TextEditingController(text: j?.repeatInterval ?? 'freq=interval;interval=60');
    _actionCtrl = TextEditingController(text: j?.jobAction ?? '');
    _enabled = j?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _intervalCtrl.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final notifier = ref.read(jobsProvider.notifier);
    final result = widget.isEdit
        ? await notifier.update(widget.job!.jobName, {
            'repeat_interval': _intervalCtrl.text.trim(),
            'job_action': _actionCtrl.text.trim(),
          })
        : await notifier.create({
            'job_name': _nameCtrl.text.trim(),
            'repeat_interval': _intervalCtrl.text.trim(),
            'job_action': _actionCtrl.text.trim(),
            'enabled': _enabled,
          });

    if (!mounted) return;
    setState(() => _busy = false);
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
        title: Text(widget.isEdit ? 'تعديل مهمة' : 'إنشاء مهمة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                enabled: !widget.isEdit,
                decoration: const InputDecoration(
                  labelText: 'اسم المهمة',
                  helperText: 'معرّف أوراكل: يبدأ بحرف، ثم حروف/أرقام/underscore',
                ),
                validator: (v) {
                  if (widget.isEdit) return null;
                  if (v == null || v.trim().isEmpty) return 'اسم المهمة مطلوب';
                  final ok = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,127}$').hasMatch(v.trim());
                  return ok ? null : 'اسم غير صالح';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _intervalCtrl,
                decoration: const InputDecoration(
                  labelText: 'المهلة (REPEAT_INTERVAL)',
                  helperText: 'مثال: freq=interval;interval=60',
                ),
                validator: (v) => widget.isEdit
                    ? null
                    : (v == null || v.trim().isEmpty)
                        ? 'المهلة مطلوبة'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionCtrl,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'أمر المهمة (JOB_ACTION)',
                  helperText: 'كتلة PL/SQL، مثال: BEGIN MSG_QUEUE_TAPI.PUSH_QUEUE; END;',
                ),
                validator: (v) => widget.isEdit
                    ? null
                    : (v == null || v.trim().isEmpty)
                        ? 'أمر المهمة مطلوب'
                        : null,
              ),
              if (!widget.isEdit)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('تفعيل عند الإنشاء'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_busy ? 'جارٍ الحفظ...' : (widget.isEdit ? 'حفظ التعديلات' : 'إنشاء المهمة')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
