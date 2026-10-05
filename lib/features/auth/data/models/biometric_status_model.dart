/// نموذج حالة البصمة المحلية للمستخدم
/// يُخزَّن في الذاكرة المحلية ويُحدَّث عند تفعيل/إلغاء البصمة
class BiometricStatusModel {
  /// هل البصمة مُفعَّلة ومُسجَّلة لهذا الجهاز؟
  final bool isEnabled;

  /// معرّف المستخدم المرتبط بالبصمة
  final int? userId;

  const BiometricStatusModel({
    required this.isEnabled,
    this.userId,
  });

  const BiometricStatusModel.disabled()
      : isEnabled = false,
        userId = null;

  BiometricStatusModel copyWith({
    bool? isEnabled,
    int? userId,
  }) {
    return BiometricStatusModel(
      isEnabled: isEnabled ?? this.isEnabled,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() =>
      'BiometricStatusModel(isEnabled: $isEnabled, userId: $userId)';
}
