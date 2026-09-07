/// نموذج بيانات المستخدم المطابق لقاعدة بيانات النظام
/// User data model matching Oracle schema and API response
class UserModel {
  final int id;
  final int? userNo;
  final String username;
  final String? nameAr;
  final String? nameEn;
  final int? userType;
  final int? branchNo;

  const UserModel({
    required this.id,
    this.userNo,
    required this.username,
    this.nameAr,
    this.nameEn,
    this.userType,
    this.branchNo,
  });

  /// الاسم المعروض للمستخدم
  String get displayName => nameAr ?? nameEn ?? username;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      userNo: json['user_no'] != null
          ? (json['user_no'] is int
              ? json['user_no'] as int
              : int.tryParse(json['user_no'].toString()))
          : null,
      username: json['username']?.toString() ?? '',
      nameAr: json['name_ar']?.toString(),
      nameEn: json['name_en']?.toString(),
      userType: json['user_type'] != null
          ? (json['user_type'] is int
              ? json['user_type'] as int
              : int.tryParse(json['user_type'].toString()))
          : null,
      branchNo: json['branch_no'] != null
          ? (json['branch_no'] is int
              ? json['branch_no'] as int
              : int.tryParse(json['branch_no'].toString()))
          : null,
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
    };
  }
}
