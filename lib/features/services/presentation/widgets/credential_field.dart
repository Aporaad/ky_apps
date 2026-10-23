import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// حقل اعتبار قابل للكشف محليًا — القيمة قد تصل مقنّعة `***` من الخادم
/// A locally-revealable credential field — the value may already arrive masked `***` from the server.
///
/// مسؤولية العرض فقط: الإخفاء/الإظهار البصري ونسخ القيمة. كشف القيمة الحقيقية يحدث في
/// الخادم خلف صلاحية `providers.reveal_credentials`؛ وإن وصل `***` فلا يوجد ما يُخفى محليًا.
/// This widget only owns presentation: local obscuring and copy. The real reveal happens server-side
/// behind `providers.reveal_credentials`; if the value is already masked there is nothing to unmask.
class CredentialField extends StatefulWidget {
  const CredentialField({
    required this.label,
    this.value,
    this.isMaskedFromServer = false,
    super.key,
  });

  final String label;
  final String? value;

  /// true إن كانت القيمة الواصلة هي `***` (لا يملك المستخدم صلاحية الكشف)
  /// True when the server sent `***` (the user lacks the reveal permission).
  final bool isMaskedFromServer;

  @override
  State<CredentialField> createState() => _CredentialFieldState();
}

class _CredentialFieldState extends State<CredentialField> {
  bool _visible = false;

  bool get _hasValue => widget.value != null && widget.value!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final display = _visible || !widget.isMaskedFromServer
        ? (widget.value ?? '')
        : '••••••';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              widget.label,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              _hasValue ? display : '—',
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.isMaskedFromServer && _hasValue)
            IconButton(
              tooltip: _visible ? 'إخفاء' : 'إظهار',
              iconSize: 18,
              icon: Icon(
                _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              ),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          if (_hasValue && !widget.isMaskedFromServer)
            IconButton(
              tooltip: 'نسخ',
              iconSize: 18,
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.value!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ / Copied')),
                );
              },
            ),
        ],
      ),
    );
  }
}
