import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/auth/data/models/user_model.dart';
import 'package:ky_apps/features/auth/data/models/auth_response.dart';

void main() {
  group('Auth Models Unit Tests', () {
    test('UserModel fromJson maps correctly', () {
      final json = {
        'id': 15,
        'user_no': 101,
        'username': 'waleed',
        'name_ar': 'وليد النقيب',
        'name_en': 'waleed',
        'user_type': 2,
        'branch_no': 1,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 15);
      expect(user.username, 'waleed');
      expect(user.nameAr, 'وليد النقيب');
      expect(user.displayName, 'وليد النقيب');
    });

    test('AuthResponse fromJson maps successfully', () {
      final json = {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح',
        'token': 'mock_token_123',
        'user': {
          'id': 1,
          'username': 'admin',
        },
      };

      final response = AuthResponse.fromJson(json);

      expect(response.success, true);
      expect(response.token, 'mock_token_123');
      expect(response.user?.username, 'admin');
    });
  });
}
