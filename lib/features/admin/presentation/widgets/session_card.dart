import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/json_value_utils.dart';
import '../../data/models/app_session_model.dart';

/// بطاقة جلسة (توكن) واحدة في شاشة الجلسات النشطة
/// One session (token) card in the active-sessions screen.
///
/// الوقت المتبقي يُحسب من `now` الذي تمرره الشاشة لا من مؤقّت داخل كل بطاقة: عشرون بطاقة بعشرين
/// `Timer.periodic` تعني عشرين إعادة رسم متزامنة وأربعين مصدراً للإلغاء، ومؤقّت واحد في الشاشة
/// يعيد بناء القائمة كلها بدقة ثانية واحدة كافية للعرض.
/// Remaining time comes from the screen's `now`, not a per-card timer: twenty cards would mean
/// twenty periodic timers and twenty rebuild sources. One screen timer rebuilds the whole list at
/// a precision the display does not need to beat.
class SessionCard extends StatelessWidget {
  final AppSessionModel session;
  final DateTime now;
  final bool canTerminate;
  final VoidCallback onTerminate;
  final VoidCallback onTerminateUser;

  const SessionCard({
    required this.session,
    required this.now,
    required this.canTerminate,
    required this.onTerminate,
    required this.onTerminateUser,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final active = session.isActive;
    final minutes = session.minutesLeftOf(now);

    // قرب النهاية إنذار بصري: المستخدم الذي يقرأ «5 دقائق» يحتاج أن يلمحها قبل أن يقرأ البطاقة
    // Imminence is a visual alarm: «5 دقائق» should be caught in a glance, not read.
    final isUrgent = active && minutes > 0 && minutes <= 10;
    final accent = !session.isActivated
        ? AppColors.error
        : !active
        ? AppColors.textMuted
        : isUrgent
        ? AppColors.warning
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: session.isCurrent ? AppColors.primary : AppColors.border,
          width: session.isCurrent ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _deviceIcon(session.platform),
                  size: 19,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              // توزيع المساحة بنسبة ٣:٢ بين العامودين: لا شارة «هذه الجلسة» ولا وقت
              // «ساعتان و٢٠ دقيقة» يسحقان مساحة الاسم أو يتجاوزان حافة البطاقة.
              // The two sides share the row by ratio instead of one taking its natural width: a
              // long status label or remaining-time caption can no longer starve the name column
              // nor run past the card.
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            session.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (session.isCurrent) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: _Badge(
                              label: 'هذه الجلسة',
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مستخدم ${session.userId} · ${session.userTypeLabel}'
                      '${session.branchNo == null ? '' : ' · فرع ${session.branchNo}'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Badge(label: session.statusLabel, color: accent),
                    const SizedBox(height: 5),
                    Text(
                      session.remainingLabel(now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // العرض الأقصى من LayoutBuilder: `Wrap` يقيس أبناءه بقدر ما يريدون، فسطرٌ طويل كالوقت
          // كان يتجاوز حافة البطاقة بدل أن يُقطع.
          // The max width comes from a LayoutBuilder because Wrap measures its children with
          // unbounded width, so a long line would run past the card instead of truncating.
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Fact(
                  icon: Icons.router_rounded,
                  maxWidth: constraints.maxWidth,
                  text: session.deviceName?.trim().isNotEmpty == true
                      ? session.deviceName!.trim()
                      : 'جهاز غير مُسمّى',
                ),
                _Fact(
                  icon: Icons.login_rounded,
                  maxWidth: constraints.maxWidth,
                  text: 'بداية ${JsonValues.formatDate(session.createdAt)}',
                ),
                _Fact(
                  icon: Icons.schedule_rounded,
                  maxWidth: constraints.maxWidth,
                  text: 'آخر استخدام ${JsonValues.formatDate(session.lastActivityAt)}',
                ),
                if (session.tokenName?.trim().isNotEmpty == true)
                  _Fact(
                    icon: Icons.vpn_key_rounded,
                    maxWidth: constraints.maxWidth,
                    text: 'اسم التوكن ${session.tokenName!.trim()}',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // الزران معاً أعرض من بطاقة الجوال، و`Row` يتجاوز؛ `Wrap` ينقل الثاني لسطر
          // Two buttons are wider than a phone card, so they flow instead of overflowing.
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (canTerminate) ...[
                _TerminateButton(session: session, onTap: onTerminate),
                OutlinedButton.icon(
                  onPressed: onTerminateUser,
                  icon: const Icon(Icons.group_off_rounded, size: 16),
                  label: const Text('جلسات هذا المستخدم'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ] else
                const Text(
                  'لا تملك صلاحية إنهاء الجلسات — العرض فقط',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// أيقونة بحسب النظام: الجوال واللوحي يظهران مختلفين فينفرق المتصل من الحاسوب
  /// A per-platform icon, so a laptop session is distinguishable at a glance from a phone's.
  static IconData _deviceIcon(String? platform) {
    final text = (platform ?? '').toLowerCase();
    if (text.contains('windows') || text.contains('desktop')) {
      return Icons.desktop_windows_rounded;
    }
    if (text.contains('ios') || text.contains('android')) {
      return Icons.smartphone_rounded;
    }
    if (text.contains('web') || text.contains('chrome')) {
      return Icons.language_rounded;
    }

    return Icons.devices_other_rounded;
  }
}

/// زر الإنهاء — «هذه الجلسة» يحذّر لأن إنهاءها يُخرج المستخدم نفسه
/// The terminate button; ending your own session logs you out, so it is labelled as such.
class _TerminateButton extends StatelessWidget {
  final AppSessionModel session;
  final VoidCallback onTap;

  const _TerminateButton({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCurrent = session.isCurrent;
    final already = !session.isActive;

    return TextButton.icon(
      onPressed: already ? null : onTap,
      icon: Icon(
        already ? Icons.do_not_disturb_on_rounded : Icons.power_settings_new_rounded,
        size: 16,
      ),
      label: Text(
        already ? 'منتهية أصلاً' : (isCurrent ? 'إنهاء جلستي' : 'إنهاء الجلسة'),
      ),
      style: TextButton.styleFrom(
        foregroundColor: already
            ? AppColors.textMuted
            : (isCurrent ? AppColors.warning : AppColors.error),
        disabledForegroundColor: AppColors.textMuted.withValues(alpha: 0.6),
        backgroundColor: already
            ? Colors.transparent
            : (isCurrent
                  ? AppColors.warning.withValues(alpha: 0.08)
                  : AppColors.error.withValues(alpha: 0.06)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

/// معلومة قصيرة بأيقونة
/// A short fact with an icon.
class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  /// أقصى عرض مسموح — يرثه من `Wrap` حتى تُقطع المعلومة الطويلة بدل أن تخرج من البطاقة
  /// The width budget from the surrounding Wrap, so a long fact truncates instead of escaping.
  final double maxWidth;

  const _Fact({
    required this.icon,
    required this.text,
    this.maxWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة الحالة الصغيرة
/// The small status badge.
class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
