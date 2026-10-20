import 'package:flutter/material.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json_value_utils.dart';
import '../../data/models/user_activity_model.dart';

/// سطر سجل نشاط واحد — الوحدة الزمنية في شاشة «سجل النشاط»
/// One audit row — the time-unit of the activity screen.
///
/// السطر يعرض الوصف العربي أولاً لأن الغرض من الشاشة قراءة بشرية لا مطابقة أكواد، ثم الكود
/// الحرفي أسفله تصديقاً: المراجع الأمني يحتاج أن يرى `users.permissions_manage` لا أن يثق وحده
/// بترجمة الواجهة. والفاشل يُميَّز بلون وحدٍ لأن فلترة المحاولات المرفوضة هي السؤال الأول.
/// The Arabic description leads because this screen is read by a human, with the literal code under
/// it for verification — a security reviewer needs to see users.permissions_manage, not to trust the
/// UI's translation alone. Failed rows are coloured on their own, since «what was refused» is the
/// first question asked of an audit trail.
class ActivityTile extends StatelessWidget {
  final UserActivityModel row;

  /// إظهار الفاعل — في سجل مستخدم واحد يكون الفاعل ثابتاً فلا يُكرَّر بلا معنى
  /// Show the actor: in a single user's trail the actor is constant and repeating it is noise.
  final bool showActor;

  const ActivityTile({required this.row, this.showActor = false, super.key});

  @override
  Widget build(BuildContext context) {
    final color = row.isSuccess ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 42,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.descriptionAr.isEmpty ? _fallbackLabel() : row.descriptionAr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Meta(
                      icon: Icons.access_time_rounded,
                      text: JsonValues.formatDate(row.createdOn),
                    ),
                    _Meta(
                      icon: Icons.qr_code_rounded,
                      text: row.actionCode.isEmpty ? '—' : row.actionCode,
                      isCode: true,
                    ),
                    if (showActor && row.userId != null)
                      _Meta(
                        icon: Icons.person_rounded,
                        text: 'من المستخدم ${row.userId}',
                      ),
                    if (row.targetUserId != null &&
                        row.targetUserId != row.userId)
                      _Meta(
                        icon: Icons.person_outline_rounded,
                        text: 'على المستخدم ${row.targetUserId}',
                      ),
                    if (row.ipAddress != null)
                      _Meta(icon: Icons.lan_rounded, text: row.ipAddress!),
                    if (row.platform != null)
                      _Meta(
                        icon: Icons.devices_other_rounded,
                        text: row.platform!,
                      ),
                    if (row.entityId != null && row.entityId!.isNotEmpty)
                      _Meta(
                        icon: Icons.link_rounded,
                        text:
                            '${row.entityType ?? 'كيان'}: ${row.entityId}',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              row.statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// وصف احتياطي من الكود نفسه — سجل بلا `description_ar` يبقى مقروءاً لا فارغاً
  /// A label derived from the code, so a row without a description stays readable.
  String _fallbackLabel() {
    final code = row.actionCode;
    if (code.isEmpty) return 'عملية غير موصوفة';
    final module = permModuleOf(code);
    final action = permActionOf(code);
    final moduleTitle = permModuleLabels[module];
    final actionLabel = permActionLabels[action];
    if (moduleTitle == null || actionLabel == null) return code;

    return '$moduleTitle — $actionLabel';
  }
}

/// قطعة بيانات صغيرة تحت الوصف: وقت، كود، IP، جهاز، كيان
/// The small facts under the description: time, code, ip, device, entity.
class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isCode;

  const _Meta({
    required this.icon,
    required this.text,
    this.isCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            color: isCode ? AppColors.primary : AppColors.textSecondary,
            fontFamily: isCode ? 'monospace' : null,
            fontWeight: isCode ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
