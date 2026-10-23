import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../providers/messages_provider.dart';
import '../../../providers/services_providers.dart';

/// إنشاء رسالة — إدراج في الطابور فقط (لا إرسال متزامن)؛ يدعم قائمة أرقام وحقول واتساب
/// Compose — enqueue only (no synchronous send); supports a number list and whatsapp file fields.
///
/// الخادم يضع `IS_SENT='N'` وتلتهمه المهمة؛ لذا لا نلمس الشبكة للإرسال هنا إطلاقًا. الأرقام
/// تُقبل مفصولة بفواصل/أسطر وتُرسَّل كقائمة `mobile_nos`.
/// The server sets IS_SENT='N' and the job drains it, so we never hit the network to send here.
/// Numbers accept comma/newline separators and are submitted as a `mobile_nos` list.
class MessageComposeScreen extends ConsumerStatefulWidget {
  const MessageComposeScreen({required this.channel, super.key});

  final MessageChannel channel;

  @override
  ConsumerState<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends ConsumerState<MessageComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numbersCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _providerIdCtrl = TextEditingController();
  final _serviceIdCtrl = TextEditingController();
  // حقول واتساب
  final _fileNameCtrl = TextEditingController();
  final _filePathCtrl = TextEditingController();
  final _fileTypeCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  bool _busy = false;

  bool get _isWhatsapp => widget.channel == MessageChannel.whatsapp;

  @override
  void dispose() {
    for (final c in [
      _numbersCtrl,
      _textCtrl,
      _customerNameCtrl,
      _providerIdCtrl,
      _serviceIdCtrl,
      _fileNameCtrl,
      _filePathCtrl,
      _fileTypeCtrl,
      _captionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _splitNumbers() => _numbersCtrl.text
      .split(RegExp(r'[,\n\s]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final numbers = _splitNumbers();
    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقمًا واحدًا على الأقل')),
      );
      return;
    }

    setState(() => _busy = true);

    final payload = <String, dynamic>{
      'mobile_nos': numbers,
      'msg_text': _textCtrl.text.trim(),
      if (_customerNameCtrl.text.trim().isNotEmpty)
        'customer_name': _customerNameCtrl.text.trim(),
      if (_providerIdCtrl.text.trim().isNotEmpty)
        'provider_id': int.tryParse(_providerIdCtrl.text.trim()),
      if (_serviceIdCtrl.text.trim().isNotEmpty)
        'service_id': int.tryParse(_serviceIdCtrl.text.trim()),
      if (_isWhatsapp) ...{
        if (_fileNameCtrl.text.trim().isNotEmpty) 'file_name': _fileNameCtrl.text.trim(),
        if (_filePathCtrl.text.trim().isNotEmpty) 'file_path': _filePathCtrl.text.trim(),
        if (_fileTypeCtrl.text.trim().isNotEmpty) 'file_type': _fileTypeCtrl.text.trim(),
        if (_captionCtrl.text.trim().isNotEmpty) 'caption': _captionCtrl.text.trim(),
      },
    };

    final repo = _isWhatsapp
        ? ref.read(whatsappRepositoryProvider)
        : ref.read(smsRepositoryProvider);
    final result = await repo.enqueue(payload);

    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      ref.read(messagesProvider(widget.channel).notifier).refresh();
      Navigator.pop(context);
    }
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
        title: Text(_isWhatsapp ? 'إرسال واتساب' : 'إرسال رسالة نصية'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('الأرقام (مفصولة بفواصل أو أسطر) *'),
              TextFormField(
                controller: _numbersCtrl,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '9677xxxxxxxx, 9677xxxxxxxx',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الأرقام مطلوبة' : null,
              ),
              const SizedBox(height: 12),
              _label('نص الرسالة *'),
              TextFormField(
                controller: _textCtrl,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'نص الرسالة مطلوب' : null,
              ),
              const SizedBox(height: 12),
              _label('اسم العميل'),
              TextFormField(controller: _customerNameCtrl, decoration: const InputDecoration()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('معرّف المزود'),
                        TextFormField(
                          controller: _providerIdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('معرّف الخدمة'),
                        TextFormField(
                          controller: _serviceIdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isWhatsapp) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _label('اسم الملف'),
                TextFormField(controller: _fileNameCtrl, decoration: const InputDecoration()),
                const SizedBox(height: 12),
                _label('مسار الملف'),
                TextFormField(controller: _filePathCtrl, decoration: const InputDecoration()),
                const SizedBox(height: 12),
                _label('نوع الملف'),
                TextFormField(controller: _fileTypeCtrl, decoration: const InputDecoration()),
                const SizedBox(height: 12),
                _label('التعليق (Caption)'),
                TextFormField(controller: _captionCtrl, decoration: const InputDecoration()),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.send_rounded),
                label: Text(_busy ? 'جارٍ الإدراج...' : 'إدراج في الطابور'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      );
}
