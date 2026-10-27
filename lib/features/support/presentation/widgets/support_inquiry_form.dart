import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_info.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/support_inquiry_provider.dart';

/// نموذج إرسال استفسار إلى الدعم
/// The inquiry submission form.
///
/// صاحب الجلسة يرى الرسالة فقط (اسمه يأتي من الحساب)، والزائر قبل الدخول يرى الاسم والهاتف
/// أيضاً — نفس الشرط الذي يفرضه الخادم بالضبط، فلا يُرفَض نموذج مكتمل ولا يُقبل نموذج ناقص.
/// A signed-in user sees only the message field (the name comes from the account); a pre-login
/// guest also sees name and phone — the exact condition the server enforces, so a complete form
/// is never refused and an incomplete one never slips through.
class SupportInquiryForm extends ConsumerStatefulWidget {
  const SupportInquiryForm({super.key});

  @override
  ConsumerState<SupportInquiryForm> createState() => _SupportInquiryFormState();
}

class _SupportInquiryFormState extends ConsumerState<SupportInquiryForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  /// تحقق محلي: المشكلة تظهر تحت الحقل مباشرة قبل أي طلب شبكة
  /// Local validation: a problem shows under its own field before any network call.
  String? _nameError;
  String? _phoneError;
  String? _messageError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportInquiryProvider);
    final isAuthenticated = ref.watch(
      authNotifierProvider.select((auth) => auth.isAuthenticated),
    );

    if (state.submitted) return _successPanel(state.ticketId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isAuthenticated) ...[
          _field(
            controller: _name,
            label: 'الاسم',
            error: _nameError,
            onReset: () => setState(() => _nameError = null),
          ),
          _field(
            controller: _phone,
            label: 'رقم الهاتف',
            error: _phoneError,
            keyboardType: TextInputType.phone,
            onReset: () => setState(() => _phoneError = null),
          ),
        ],
        _field(
          controller: _message,
          label: 'نص الاستفسار',
          error: _messageError,
          maxLines: 4,
          onReset: () => setState(() => _messageError = null),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 4),
          _errorBanner(state.errorMessage!),
        ],
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: state.submitting ? null : () => _submit(isAuthenticated),
          icon: state.submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(state.submitting ? 'جارٍ الإرسال…' : 'إرسال الاستفسار'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// لوحة النجاح: مرجع التذكرة + «إرسال استفسار آخر»
  /// The success panel: the ticket reference plus "send another inquiry".
  Widget _successPanel(int? ticketId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 22, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم إرسال استفسارك بنجاح',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          ticketId == null
              ? 'سيتم الرد عليك في أقرب وقت ممكن.'
              : 'سيتم الرد عليك في أقرب وقت ممكن. رقم المتابعة: $ticketId',
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            _message.clear();
            setState(() {
              _messageError = null;
            });
            ref.read(supportInquiryProvider.notifier).reset();
          },
          icon: const Icon(Icons.add_comment_outlined, size: 18),
          label: const Text('إرسال استفسار آخر'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// تحقق محلي مطابق لحدود الخادم ثم إرسال
  /// Local validation matching the server's bounds, then send.
  Future<void> _submit(bool isAuthenticated) async {
    final name = _name.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    final message = _message.text.trim();

    setState(() {
      _nameError = !isAuthenticated && name.length < 2
          ? 'اكتب الاسم (محرفان على الأقل)'
          : null;
      _phoneError = !isAuthenticated && (digits.length < 7 || digits.length > 15)
          ? 'رقم الهاتف من 7 إلى 15 رقماً'
          : null;
      _messageError = message.length < 10
          ? 'اكتب استفسارك (10 محارف على الأقل)'
          : (message.length > 1000 ? 'النص أطول من 1000 محرف' : null);
    });

    if (_nameError != null || _phoneError != null || _messageError != null) {
      return;
    }

    await ref.read(supportInquiryProvider.notifier).submit(
      name: isAuthenticated ? null : name,
      phone: isAuthenticated ? null : digits,
      message: message,
      appVersion: kAppVersion,
      platform: Theme.of(context).platform.name,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? error,
    required VoidCallback onReset,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        // أي تعديل يمسح خطأ الحقل: رسالة حمراء تحت حقل يُكتب فيه تُقرأ كخطأ مستمر
        // Any edit clears the field error: a red line under a field being typed into reads as
        // a standing rejection.
        onChanged: error == null ? null : (_) => onReset(),
        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceSubtle,
          labelStyle: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  /// رسالة رفض الخادم داخل النموذج — لا حوار يفصل المستخدم عن النص الذي كتبه
  /// The server's refusal rendered inline — not a dialog that hides the text the user wrote.
  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
