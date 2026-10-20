import 'package:ky_apps/core/utils/arabic_encoding_utils.dart';

/// نموذج بيانات المستخدم المطابق لقاعدة بيانات النظام
/// User data model matching Oracle schema and API response
///
/// أضيفت حالة IBAC (`isAdmin` + `permissions`) لأن استجابات `login` و`me` و`biometricLogin`
/// الثلاث تحملها معاً منذ المرحلة 2؛ تخزينها هنا يجعل المستخدم المخزّن في الذاكرة الآمن مطابقاً
/// لما يقرّ به الخادم، فلا تُبنى الواجهة على تخمين بعد إعادة التشغيل.
/// The IBAC state is carried here because all three sign-in responses ship it together, so the
/// cached user matches what the server asserted and the UI is never rebuilt on a guess.
class UserModel {
  final int id;
  final int? userNo;
  final String username;
  final String? nameAr;
  final String? nameEn;
  final int? userType;
  final int? branchNo;
  final bool isAdmin;
  final List<String> permissions;

  const UserModel({
    required this.id,
    this.userNo,
    required this.username,
    this.nameAr,
    this.nameEn,
    this.userType,
    this.branchNo,
    this.isAdmin = false,
    this.permissions = const [],
  });

  /// الاسم المعروض للمستخدم
  String get displayName {
    if (nameAr != null && nameAr!.trim().isNotEmpty) {
      final fixed = ArabicEncodingUtils.fix(nameAr);
      if (fixed.isNotEmpty) return fixed;
    }
    return (nameEn != null && nameEn!.trim().isNotEmpty) ? nameEn! : username;
  }

  /// تسمية نوع الحساب بالعربية (قرار D5: القيمة 1 لموظف و2 لعميل)
  /// Account type label — decision D5 keeps 1 for staff and 2 for customers.
  String get userTypeLabel => userType == 2 ? 'عميل' : 'موظف';

  /// مجموعة الصلاحيات جاهزة للفحص السريع (`Set` بدل قائمة في كل قرار حجب)
  /// Grants as a set, so each gating decision is an O(1) lookup rather than a list scan.
  Set<String> get permissionSet => permissions.toSet();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:
          (json['id'] is int)
              ? json['id'] as int
              : int.tryParse(json['id'].toString()) ?? 0,
      userNo:
          json['user_no'] != null
              ? (json['user_no'] is int
                  ? json['user_no'] as int
                  : int.tryParse(json['user_no'].toString()))
              : null,
      username: json['username']?.toString() ?? '',
      nameAr: json['name_ar']?.toString(),
      nameEn: json['name_en']?.toString(),
      userType:
          json['user_type'] != null
              ? (json['user_type'] is int
                  ? json['user_type'] as int
                  : int.tryParse(json['user_type'].toString()))
              : null,
      branchNo:
          json['branch_no'] != null
              ? (json['branch_no'] is int
                  ? json['branch_no'] as int
                  : int.tryParse(json['branch_no'].toString()))
              : null,
      // `is_admin` قد يصل bool أو 1/0 حسب مسار القراءة من أوراكل
      // is_admin may arrive as a bool or as 1/0 depending on the Oracle read path.
      isAdmin: _parseBool(json['is_admin']),
      // الأكواد لاتينية بلا عربية: لا تمرّ بـ fix() ولا تحتاج ذلك
      // Codes are ASCII: they neither need nor survive the Arabic repair pass.
      permissions: _parseStringList(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_no': userNo,
      'username': username,
      'name_ar': nameAr,
      'name_en': nameEn,
      'user_type': userType,
      'branch_no': branchNo,
      'is_admin': isAdmin,
      'permissions': permissions,
    };
  }

  /// تحويل قيمة المدير إلى منطقية بصمت آمن: أي شيء غير صريح يعني false
  /// Coerce the admin flag safely: anything not explicitly truthy means false (deny by default).
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      return text == '1' || text == 'true' || text == 'yes';
    }
    return false;
  }

  /// قراءة قائمة الأكواد مع تحمّل أي عنصر غير نصي بدل أن ينفجر العرض
  /// Read the code list, dropping non-string entries instead of throwing at parse time.
  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
