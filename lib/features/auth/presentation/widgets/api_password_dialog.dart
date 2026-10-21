import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';

/// حوار كلمة سر إعدادات API — يفتح شاشة إعدادات الخادم فقط بعد التحقق الصحيح
/// API-settings password dialog — gates the server-settings screen behind a correct password.
///
/// التحقق يحاول الخادم أولاً ثم الاحتياط المحلي (يديره `AppConfigNotifier`). عند النجاح يُغلق
/// الحوار ويعيد `true` فيستدعي المُنادي شاشة `/api-settings`. كلمة السر لا تُخزَّن أبداً هنا.
/// Verification tries the server first, then the local fallback (handled by the notifier). On
/// success the dialog pops `true` and the caller opens `/api-settings`. The password is never stored.
class ApiPasswordDialog extends ConsumerStatefulWidget {
  const ApiPasswordDialog({super.key});

  /// عرض الحوار وإرجاع نتيجة التحقق (true = يحق فتح إعدادات الـ API)
  /// Show the dialog and return the verification outcome.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ApiPasswordDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ApiPasswordDialog> createState() => _ApiPasswordDialogState();
}

class _ApiPasswordDialogState extends ConsumerState<ApiPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = 'أدخل كلمة السر للمتابعة');
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    final ok =
        await ref.read(appConfigNotifierProvider.notifier).verifyApiSettingsPassword(password);

    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      // نُمسح الكلمة من الذاكرة ثم نغلق بالنجاح
      // Wipe the field from memory, then close with success.
      _controller.clear();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'كلمة السر غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('كلمة سر إعدادات الـ API'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'هذه الإعدادات محمية. أدخل كلمة السر لفتح إعدادات خادم الـ API.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: _obscure,
              onSubmitted: (_) => _checking ? null : _verify(),
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                errorText: _error,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _checking ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _checking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('تحقّق'),
        ),
      ],
    );
  }
}
