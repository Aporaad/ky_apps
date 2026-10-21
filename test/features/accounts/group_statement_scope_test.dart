import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/accounts/presentation/utils/group_statement_scope.dart';

void main() {
  group('resolveStatementScope', () {
    test('returns null when nothing is selected', () {
      expect(
        resolveStatementScope(),
        isNull,
      );
    });

    test('resolves to level=account when only accNo is present', () {
      final scope = resolveStatementScope(accNo: 5);
      expect(scope, isNotNull);
      expect(scope!.level, 'account');
      expect(scope.accNo, 5);
      expect(scope.accSub, isNull);
      expect(scope.accPart, isNull);
      expect(scope.groupId, isNull);
    });

    test('resolves to level=main when only accSub is present', () {
      final scope = resolveStatementScope(accSub: 12);
      expect(scope, isNotNull);
      expect(scope!.level, 'main');
    });

    test('resolves to level=main when accNo + accSub only', () {
      final scope = resolveStatementScope(accNo: 5, accSub: 12);
      expect(scope!.level, 'main');
      expect(scope.accNo, 5);
      expect(scope.accSub, 12);
    });

    test('resolves to level=sub for main+sub+part without group (rule per plan)', () {
      final scope = resolveStatementScope(accNo: 5, accSub: 12, accPart: 1291);
      expect(scope!.level, 'sub');
      expect(scope.accPart, 1291);
      expect(scope.groupId, isNull);
    });

    test('resolves to level=group when a group is picked (rule per plan)', () {
      final scope = resolveStatementScope(
          accNo: 5, accSub: 12, accPart: 1291, groupId: 44);
      expect(scope!.level, 'group');
      expect(scope.groupId, 44);
    });

    test('group wins over deeper levels if all four are provided', () {
      final scope = resolveStatementScope(
          accNo: 1, accSub: 2, accPart: 3, groupId: 4);
      expect(scope!.level, 'group');
      expect(scope.groupId, 4);
    });

    test('toQueryParameters sends the full chain up to the resolved level', () {
      final scope = resolveStatementScope(
          accNo: 5, accSub: 12, accPart: 1291, groupId: 44);
      expect(scope!.toQueryParameters(), {
        'acc_no': 5,
        'acc_sub': 12,
        'acc_part': 1291,
        'group_id': 44,
      });
    });
  });
}
