import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';

/// شريط سفلي ثابت بزر حفظ معطّل — يخدم شاشتي الإضافة والتعديل معاً
/// The fixed bottom bar with a disabled save button — shared by the add and edit screens.
///
/// الزر يبقى داخل بوابته الصلاحية حتى يرى المستخدم بلا صلاحية «غير مصرّح» لا زراً ميتاً بلا سبب.
/// The button stays inside its permission gate so a user without the grant sees "not permitted"
/// rather than a dead button with no explanation.
///
/// التعطيل مقصود ومعلَن: النماذج الأولية قراءة فقط ولا ترسل أي طلب إلى الخادم.
/// The disabled state is intentional and stated: the prototypes are read-only and send
/// no request to the server.
class PrototypeSaveBar extends StatelessWidget {
  /// كود الصلاحية الذي يُغلّف الزر
  /// The permission code that wraps the button.
  final String permissionCode;

  /// نص الزر / the button's text
  final String label;

  /// سبب التعطيل المعروض بجانب الزر
  /// The disablement reason shown next to the button.
  final String note;

  const PrototypeSaveBar({
    super.key,
    required this.permissionCode,
    required this.label,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, size: 15, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
          const SizedBox(width: 8),
          PermissionGate(
            code: permissionCode,
            child: ElevatedButton.icon(
              // الحفظ معطّل صراحةً: نموذج أولي لا يكتب في النظام
              // Saving is explicitly disabled: the prototype writes nothing into the system.
              onPressed: null,
              icon: const Icon(Icons.save_rounded, size: 17),
              label: Text(label, style: const TextStyle(fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                disabledForegroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
