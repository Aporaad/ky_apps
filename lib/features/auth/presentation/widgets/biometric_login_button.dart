import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/biometric_service.dart';

/// زر تسجيل الدخول بالمقاييس الحيوية (بصمة الإصبع أو التعرف على الوجه)
class BiometricLoginButton extends StatelessWidget {
  final BiometricCapability capability;
  final bool isLoading;
  final VoidCallback? onPressed;

  const BiometricLoginButton({
    super.key,
    required this.capability,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = capability == BiometricCapability.faceId
        ? Icons.face_rounded
        : Icons.fingerprint_rounded;

    final String label = capability == BiometricCapability.faceId
        ? 'تسجيل الدخول بـ Face ID'
        : 'تسجيل الدخول بالبصمة';

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Icon(icon, size: 24, color: AppColors.primary),
      label: Text(
        isLoading ? 'جاري التحقق...' : label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
