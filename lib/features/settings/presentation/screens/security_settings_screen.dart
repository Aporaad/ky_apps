import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/biometric_settings_notifier.dart';

/// شاشة إعدادات الأمان: البصمة، Face ID، وكلمة المرور
/// لا تحتوي على أي إعدادات API - تلك موجودة في api_settings_screen.dart
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bioState = ref.watch(biometricSettingsNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isNarrow = size.width < 600;
    final hPad = isNarrow ? 16.0 : 24.0;
    final scaledAppBarTitle = textScaler.scale(isNarrow ? 16.0 : 18.0).clamp(13.0, 22.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          tooltip: 'رجوع',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الأمان والمصادقة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: scaledAppBarTitle,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── بطاقة المعلومات ──────────────────────────────
                _InfoBanner(textScaler: textScaler, isNarrow: isNarrow),
                const SizedBox(height: 18),

                // ── قسم المقاييس الحيوية ─────────────────────────
                _BiometricCard(
                  bioState: bioState,
                  authState: authState,
                  ref: ref,
                  textScaler: textScaler,
                  isNarrow: isNarrow,
                ),
                const SizedBox(height: 16),

                // ── قسم كلمة المرور ──────────────────────────────
                _PasswordCard(textScaler: textScaler, isNarrow: isNarrow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// شريط المعلومات العلوي
// ─────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _InfoBanner({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledText = textScaler.scale(isNarrow ? 12.0 : 12.5).clamp(10.0, 16.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6D28D9).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6D28D9).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.security_rounded,
            color: Color(0xFF6D28D9),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تفعيل أو إيقاف تسجيل الدخول بالبصمة أو Face ID.',
              style: TextStyle(
                fontSize: scaledText,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// بطاقة المقاييس الحيوية
// ─────────────────────────────────────────────
class _BiometricCard extends StatelessWidget {
  final BiometricSettingsState bioState;
  final AuthState authState;
  final WidgetRef ref;
  final TextScaler textScaler;
  final bool isNarrow;

  const _BiometricCard({
    required this.bioState,
    required this.authState,
    required this.ref,
    required this.textScaler,
    required this.isNarrow,
  });

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(isNarrow ? 14.5 : 15.0).clamp(12.0, 19.0);
    final scaledLabel = textScaler.scale(isNarrow ? 13.0 : 13.5).clamp(11.0, 17.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.0 : 11.5).clamp(9.0, 14.0);
    final scaledMsg = textScaler.scale(isNarrow ? 11.5 : 12.0).clamp(9.5, 15.0);

    final isFaceId = bioState.deviceCapability == BiometricCapability.faceId;
    const purple = Color(0xFF6D28D9);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: purple.withValues(alpha: 0.2)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان القسم
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded,
                    color: purple,
                    size: isNarrow ? 19 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المقاييس الحيوية (البصمة والوجه)',
                    style: TextStyle(
                      fontSize: scaledTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (bioState.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // محتوى بحسب الحالة
            if (bioState.deviceCapability == BiometricCapability.notSupported)
              _StatusNote(
                icon: Icons.info_outline_rounded,
                color: AppColors.textSecondary,
                bgColor: AppColors.surfaceSubtle,
                borderColor: AppColors.border,
                message: 'هذا الجهاز لا يدعم المقاييس الحيوية (البصمة أو Face ID).',
                scaledMsg: scaledMsg,
              )
            else if (bioState.deviceCapability == BiometricCapability.notEnrolled)
              _StatusNote(
                icon: Icons.warning_amber_rounded,
                color: AppColors.warning,
                bgColor: AppColors.warning.withValues(alpha: 0.08),
                borderColor: AppColors.warning.withValues(alpha: 0.3),
                message:
                    'الجهاز يدعم البصمة لكن لم يتم تسجيل أي بصمة في إعدادات النظام. يرجى إعداد البصمة في جهازك أولاً.',
                scaledMsg: scaledMsg,
              )
            else ...[
              // تنبيه إذا لم يكن مسجلاً
              if (!authState.isAuthenticated) ...[
                _StatusNote(
                  icon: Icons.lock_outline_rounded,
                  color: AppColors.info,
                  bgColor: AppColors.info.withValues(alpha: 0.08),
                  borderColor: AppColors.info.withValues(alpha: 0.3),
                  message:
                      'لتفعيل أو إيقاف البصمة، يجب تسجيل الدخول بحسابك أولاً.',
                  scaledMsg: scaledMsg,
                ),
                const SizedBox(height: 12),
              ],

              // مفتاح التفعيل
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  isFaceId
                      ? 'تسجيل الدخول بـ Face ID'
                      : 'تسجيل الدخول ببصمة الإصبع',
                  style: TextStyle(
                    fontSize: scaledLabel,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  bioState.isEnabled
                      ? 'البصمة مفعلة لهذا الجهاز (${bioState.deviceName ?? 'الجهاز الحالي'})'
                      : 'تفعيل تسجيل الدخول التلقائي السريع بالبصمة',
                  style: TextStyle(
                    fontSize: scaledSub,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: bioState.isEnabled,
                activeColor: purple,
                onChanged: (!authState.isAuthenticated || bioState.isLoading)
                    ? null
                    : (val) async {
                        await ref
                            .read(biometricSettingsNotifierProvider.notifier)
                            .toggleBiometric(val);
                      },
              ),

              // رسائل الخطأ والنجاح
              if (bioState.errorMessage != null) ...[
                const SizedBox(height: 8),
                _StatusNote(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.error,
                  bgColor: AppColors.error.withValues(alpha: 0.07),
                  borderColor: AppColors.error.withValues(alpha: 0.3),
                  message: bioState.errorMessage!,
                  scaledMsg: scaledMsg,
                ),
              ],
              if (bioState.successMessage != null) ...[
                const SizedBox(height: 8),
                _StatusNote(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  bgColor: AppColors.success.withValues(alpha: 0.07),
                  borderColor: AppColors.success.withValues(alpha: 0.3),
                  message: bioState.successMessage!,
                  scaledMsg: scaledMsg,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// بطاقة كلمة المرور
// ─────────────────────────────────────────────
class _PasswordCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _PasswordCard({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledTitle = textScaler.scale(isNarrow ? 14.5 : 15.0).clamp(12.0, 19.0);
    final scaledLabel = textScaler.scale(isNarrow ? 13.0 : 13.5).clamp(11.0, 17.0);
    final scaledSub = textScaler.scale(isNarrow ? 11.0 : 11.5).clamp(9.0, 14.0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.warning,
                    size: isNarrow ? 19 : 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'كلمة المرور',
                    style: TextStyle(
                      fontSize: scaledTitle,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                // TODO: تنفيذ تغيير كلمة المرور
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تغيير كلمة المرور',
                            style: TextStyle(
                              fontSize: scaledLabel,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'تحديث كلمة مرور حسابك بكلمة مرور جديدة',
                            style: TextStyle(
                              fontSize: scaledSub,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// مكوّن رسالة الحالة المشتركة
// ─────────────────────────────────────────────
class _StatusNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String message;
  final double scaledMsg;

  const _StatusNote({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.message,
    required this.scaledMsg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: scaledMsg,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
