import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/worker_model.dart';
import '../providers/workers_provider.dart';

/// شاشة إضافة أو تعديل بيانات عامل
class AddEditWorkerScreen extends ConsumerStatefulWidget {
  final WorkerType workerType;
  final WorkerModel? existingWorker;

  const AddEditWorkerScreen({
    super.key,
    required this.workerType,
    this.existingWorker,
  });

  @override
  ConsumerState<AddEditWorkerScreen> createState() => _AddEditWorkerScreenState();
}

class _AddEditWorkerScreenState extends ConsumerState<AddEditWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phone1Ctrl;
  late final TextEditingController _phone2Ctrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _accNoCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _piecePriceCtrl;
  late final TextEditingController _jobTypeCtrl;
  late final TextEditingController _empClassCtrl;
  late final TextEditingController _wagesTypeCtrl;
  String _status = 'فعال';

  bool get _isEdit => widget.existingWorker != null;

  @override
  void initState() {
    super.initState();
    final w = widget.existingWorker;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _phone1Ctrl = TextEditingController(text: w?.phone1 ?? '');
    _phone2Ctrl = TextEditingController(text: w?.phone2 ?? '');
    _emailCtrl = TextEditingController(text: w?.email ?? '');
    _notesCtrl = TextEditingController(text: w?.notes ?? '');
    _accNoCtrl = TextEditingController(text: w?.accNo?.toString() ?? '');
    _salaryCtrl = TextEditingController(text: w?.salary?.toString() ?? '');
    _piecePriceCtrl = TextEditingController(text: w?.piecePrice?.toString() ?? '');
    _jobTypeCtrl = TextEditingController(text: w?.jobType ?? '');
    _empClassCtrl = TextEditingController(text: w?.empClass ?? '');
    _wagesTypeCtrl = TextEditingController(text: w?.wagesType ?? '');
    _status = w?.status ?? 'فعال';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phone1Ctrl.dispose();
    _phone2Ctrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    _accNoCtrl.dispose();
    _salaryCtrl.dispose();
    _piecePriceCtrl.dispose();
    _jobTypeCtrl.dispose();
    _empClassCtrl.dispose();
    _wagesTypeCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.workerType) {
      case WorkerType.employee:
        return const Color(0xFF1E3A8A);
      case WorkerType.cutter:
        return const Color(0xFF065F46);
      case WorkerType.tailor:
        return const Color(0xFF7C2D12);
    }
  }

  String get _typeLabel => widget.workerType.label;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final workerData = WorkerModel(
      id: widget.existingWorker?.id ?? 0,
      name: _nameCtrl.text.trim(),
      phone1: _phone1Ctrl.text.trim().isEmpty ? null : _phone1Ctrl.text.trim(),
      phone2: _phone2Ctrl.text.trim().isEmpty ? null : _phone2Ctrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      status: _status,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      accNo: _accNoCtrl.text.trim().isEmpty ? null : int.tryParse(_accNoCtrl.text.trim()),
      type: widget.workerType,
      jobType: _jobTypeCtrl.text.trim().isEmpty ? null : _jobTypeCtrl.text.trim(),
      empClass: _empClassCtrl.text.trim().isEmpty ? null : _empClassCtrl.text.trim(),
      wagesType: _wagesTypeCtrl.text.trim().isEmpty ? null : _wagesTypeCtrl.text.trim(),
      salary: _salaryCtrl.text.trim().isEmpty ? null : double.tryParse(_salaryCtrl.text.trim()),
      piecePrice: _piecePriceCtrl.text.trim().isEmpty ? null : double.tryParse(_piecePriceCtrl.text.trim()),
    );

    final repo = ref.read(workerRepositoryProvider);
    final result = _isEdit
        ? await repo.updateWorker(workerData)
        : await repo.createWorker(workerData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.success),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          _isEdit ? 'تعديل $_typeLabel' : 'إضافة $_typeLabel',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('حفظ'),
              style: TextButton.styleFrom(foregroundColor: _accentColor),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // قسم البيانات الأساسية
                    _SectionHeader(
                      title: 'البيانات الأساسية',
                      color: _accentColor,
                    ),
                    const SizedBox(height: 12),

                    // اسم العامل
                    _FormField(
                      label: 'الاسم *',
                      controller: _nameCtrl,
                      hint: 'أدخل اسم $_typeLabel',
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),

                    // رقم الهاتف 1 و 2
                    Row(
                      children: [
                        Expanded(
                          child: _FormField(
                            label: 'هاتف 1',
                            controller: _phone1Ctrl,
                            hint: 'رقم الهاتف الأول',
                            isArabic: false,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FormField(
                            label: 'هاتف 2',
                            controller: _phone2Ctrl,
                            hint: 'رقم الهاتف الثاني',
                            isArabic: false,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // البريد الإلكتروني
                    _FormField(
                      label: 'البريد الإلكتروني',
                      controller: _emailCtrl,
                      hint: 'example@email.com',
                      isArabic: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    // رقم الحساب
                    _FormField(
                      label: 'رقم الحساب (ACC_NO)',
                      controller: _accNoCtrl,
                      hint: 'رقم حساب العامل في الدفتر',
                      isArabic: false,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // الحالة
                    _buildStatusRow(),
                    const SizedBox(height: 12),

                    // ملاحظات
                    _FormField(
                      label: 'ملاحظات',
                      controller: _notesCtrl,
                      hint: 'أي ملاحظات إضافية',
                      maxLines: 2,
                    ),

                    // حقول خاصة بالموظفين فقط
                    if (widget.workerType == WorkerType.employee) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'بيانات الراتب والوظيفة',
                        color: _accentColor,
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        label: 'نوع الوظيفة',
                        controller: _jobTypeCtrl,
                        hint: 'مثال: محاسب، مدير...',
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        label: 'درجة الموظف',
                        controller: _empClassCtrl,
                        hint: 'درجة وظيفية',
                      ),
                      const SizedBox(height: 12),
                      _FormField(
                        label: 'نوع الراتب',
                        controller: _wagesTypeCtrl,
                        hint: 'شهري / يومي / قطعة',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _FormField(
                              label: 'الراتب',
                              controller: _salaryCtrl,
                              hint: '0.00',
                              isArabic: false,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FormField(
                              label: 'سعر القطعة',
                              controller: _piecePriceCtrl,
                              hint: '0.00',
                              isArabic: false,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة $_typeLabel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        const Text(
          'الحالة:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        _StatusChip(
          label: 'فعال',
          isSelected: _status == 'فعال',
          color: AppColors.success,
          onTap: () => setState(() => _status = 'فعال'),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'معطل',
          isSelected: _status == 'معطل',
          color: AppColors.error,
          onTap: () => setState(() => _status = 'معطل'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool isRequired;
  final bool isArabic;
  final TextInputType? keyboardType;
  final int maxLines;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.isRequired = false,
    this.isArabic = true,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceSubtle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
              : null,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
