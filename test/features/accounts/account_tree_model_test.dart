import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/arabic_encoding_utils.dart';
import 'package:ky_apps/features/accounts/data/models/account_model.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart'
    show AccountTreeNotifier;
import 'package:ky_apps/features/accounts/presentation/utils/account_tree_flatten.dart';

/// اختبارات نماذج الشجرة والتسطيح — لا Dio ولا شبكة: فقط ما يصل من الغلاف
/// `{success,data,meta}` وخريطة الحقول المزدوجة.
/// Pure parsing/flatten tests: the dual-case key mapping Oracle/Laravel produce and
/// the flat row list the tree screen renders.
void main() {
  // محارف داخل نطاق CP1256 (0x80–0xFF) يعيد المصحح طيّها إلى العربية، فأي نص عربي
  // سليم يمرّ كما هو بلا تغيير.
  const mojibakeName = '\u00C7\u00E3\u00E1\u00E3\u00C7\u00E5';

  group('AccountTreeNode.fromJson', () {
    test('reads the lowercase Laravel envelope keys', () {
      final node = AccountTreeNode.fromJson({
        'id': 'sub_1291',
        'level': 'sub',
        'name': 'حسابات الأمانة',
        'acc_no': 5,
        'acc_sub': 12,
        'acc_part': 1291,
        'parent_path': 'الأصول / حسابات فرعية',
        'code_path': '5 / 12 / 1291',
        'stored_balance': 0,
        'cur_no': 1,
        'debit': 1500.25,
        'credit': 500.25,
        'balance': 1000.0,
        'movements': 42,
        'account_count': 77,
        'direct_count': 5,
        'hidden_accounts': 70,
        'children_count': 2,
        'has_children': true,
        'limited_balance': 99.5,
        'stopping_acc': 0,
        'seq': 3,
        'acc_date': '2024-01-09',
        'children': [
          {'id': 'group_3', 'level': 'group', 'group_id': 3, 'name': 'موظفون'},
        ],
      });

      expect(node.id, 'sub_1291');
      expect(node.level, 'sub');
      expect(node.name, 'حسابات الأمانة');
      expect(node.accPart, 1291);
      expect(node.parentPath, 'الأصول / حسابات فرعية');
      expect(node.codePath, '5 / 12 / 1291');
      expect(node.debit, 1500.25);
      expect(node.credit, 500.25);
      expect(node.balance, 1000.0);
      expect(node.movements, 42);
      expect(node.accountCount, 77);
      expect(node.directCount, 5);
      expect(node.hiddenAccounts, 70);
      expect(node.childrenCount, 2);
      expect(node.hasChildren, isTrue);
      expect(node.limitedBalance, 99.5);
      expect(node.isStoppped, isFalse);
      expect(node.seq, 3);
      expect(node.accDate, '2024-01-09');
      expect(node.children, hasLength(1));
      expect(node.children.first.groupId, 3);
    });

    test('reads upper-cased Oracle keys with the same result', () {
      final node = AccountTreeNode.fromJson({
        'ID': 'chart_11010001',
        'LEVEL': 'chart',
        'NAME': 'نقدية',
        'ACC_NO': 11010001,
        'DEBIT': '800',
        'CREDIT': '300',
        'BALANCE': '500',
        'MOV_COUNT': 7,
        'STORED_BALANCE': '0',
        'HAS_CHILDREN': false,
        'STOPPING_ACC': 1,
      });

      expect(node.id, 'chart_11010001');
      expect(node.level, 'chart');
      expect(node.accNo, 11010001);
      // أرقام DECIMAL تصل نصوصاً من Oracle — اليhelper يحوّلها بلا انفجار
      expect(node.debit, 800.0);
      expect(node.credit, 300.0);
      expect(node.balance, 500.0);
      expect(node.movements, 7);
      expect(node.storedBalance, 0.0);
      expect(node.isStoppped, isTrue);
      expect(node.isLeaf, isTrue);
    });

    test('repairs mojibake Arabic coming from the CP1256 column', () {
      final node = AccountTreeNode.fromJson({
        'id': 'acc_1',
        'level': 'account',
        'name': mojibakeName,
        'parent_path': mojibakeName,
      });

      expect(node.name, ArabicEncodingUtils.fix(mojibakeName));
      expect(node.name, isNot(mojibakeName));
      expect(node.parentPath, ArabicEncodingUtils.fix(mojibakeName));
      // نص عربي سليم لا يُمسّ
      final clean = AccountTreeNode.fromJson({
        'id': 'acc_2',
        'level': 'account',
        'name': 'الأصول الثابتة',
      });
      expect(clean.name, 'الأصول الثابتة');
    });

    test('direct_count alone makes a node expandable', () {
      // حسابات مباشرة بلا مجموعة: children فارغة في الهيكل وhas_children صحيح
      final node = AccountTreeNode.fromJson({
        'id': 'sub_110',
        'level': 'sub',
        'name': 'أراضي',
        'acc_part': 110,
        'direct_count': 12,
        'children': <dynamic>[],
      });

      expect(node.hasChildren, isTrue);
      expect(node.children, isEmpty);
      expect(AccountTreeNotifier.isFinancialHost(node), isTrue);
    });

    test('filterBySearch keeps only matching descendants', () {
      final root = AccountTreeNode.fromJson({
        'id': 'acc_1',
        'level': 'account',
        'name': 'الأصول',
        'has_children': true,
        'children': [
          {
            'id': 'main_11',
            'level': 'main',
            'name': 'أصول ثابتة',
            'children': [
              {'id': 'sub_110', 'level': 'sub', 'name': 'أراضي', 'acc_part': 110},
              {'id': 'sub_111', 'level': 'sub', 'name': 'مباني', 'acc_part': 111},
            ],
          },
        ],
      });

      final filtered = root.filterBySearch('مبان');

      expect(filtered.children.first.children.map((c) => c.id), ['sub_111']);
      expect(root.children.first.children, hasLength(2));
    });
  });

  group('AccountLeafModel.fromJson', () {
    test('maps the children endpoint row with computed balances', () {
      final leaf = AccountLeafModel.fromJson({
        'id': 'chart_12910001',
        'level': 'chart',
        'acc_no': 12910001,
        'name': 'موظف تجريبي',
        'group_id': 3,
        'debit': 1000.0,
        'credit': 250.5,
        'balance': 749.5,
        'movements': 4,
        'stored_balance': 0.0,
        'limited_balance': 5000.0,
        'stopping_acc': 0,
        'seq': 11,
        'acc_date': '2024-05-01',
        'parent_path': 'الأمانة / موظفون',
      });

      expect(leaf.accNo, 12910001);
      expect(leaf.accName, 'موظف تجريبي');
      expect(leaf.debit, 1000.0);
      expect(leaf.credit, 250.5);
      expect(leaf.net, 749.5);
      expect(leaf.movements, 4);
      expect(leaf.limitedBalance, 5000.0);
      expect(leaf.stopped, isFalse);
      expect(leaf.parentPath, 'الأمانة / موظفون');
    });

    test('reads raw Oracle aggregate aliases and the name fallback', () {
      final leaf = AccountLeafModel.fromJson({
        'ACC_NO': 11010001,
        'ACC_NAME': mojibakeName,
        'DR': '50',
        'CR': '20',
        'NET': '30',
        'CNT': 2,
        'BALANCE': '0',
        'STOPPING_ACC': 1,
      });

      expect(leaf.accName, ArabicEncodingUtils.fix(mojibakeName));
      expect(leaf.debit, 50.0);
      expect(leaf.credit, 20.0);
      expect(leaf.net, 30.0);
      expect(leaf.movements, 2);
      expect(leaf.storedBalance, 0.0);
      expect(leaf.stopped, isTrue);
    });
  });

  group('flattenAccountTree', () {
    AccountTreeNode structural({
      String id = 'acc_1',
      String level = 'account',
      double? balance = 100,
      List<AccountTreeNode> children = const [],
      int? directCount,
    }) => AccountTreeNode(
      id: id,
      name: 'عقدة $id',
      level: level,
      balance: balance,
      directCount: directCount,
      hasChildren: children.isNotEmpty || directCount != null,
      children: children,
    );

    test('emits structural rows and stops at un-expanded nodes', () {
      final child = structural(id: 'main_11', level: 'main');
      final root = structural(id: 'acc_1', children: [child]);

      final rows = flattenAccountTree(
        tree: [root],
        expanded: const {},
        childrenCache: const {},
        loadingChildren: const {},
        childHasMore: const {},
        filters: const AccountTreeFilters(),
      );

      expect(rows, hasLength(1));
      expect(rows.single.kind, AccountTreeRowKind.structural);
      expect(rows.single.depth, 0);

      final expandedRows = flattenAccountTree(
        tree: [root],
        expanded: const {'acc_1'},
        childrenCache: const {},
        loadingChildren: const {},
        childHasMore: const {},
        filters: const AccountTreeFilters(),
      );

      expect(expandedRows.map((r) => r.node?.id), ['acc_1', 'main_11']);
      expect(expandedRows.last.depth, 1);
    });

    test('renders lazily loaded leaves plus a load-more row', () {
      final group = structural(id: 'group_3', level: 'group');
      final root = structural(id: 'acc_1', children: [group]);
      const leaves = [
        AccountLeafModel(accNo: 12910001, accName: 'أول', net: 10),
        AccountLeafModel(accNo: 12910002, accName: 'ثانٍ', net: 20),
      ];

      final rows = flattenAccountTree(
        tree: [root],
        expanded: const {'acc_1', 'group_3'},
        childrenCache: const {'group_3': leaves},
        loadingChildren: const {},
        childHasMore: const {'group_3': true},
        filters: const AccountTreeFilters(),
      );

      final leafRows = rows
          .where((r) => r.kind == AccountTreeRowKind.leaf)
          .toList();
      expect(leafRows, hasLength(2));
      expect(leafRows.first.code, '12910001');
      expect(leafRows.first.title, 'أول');
      expect(rows.last.kind, AccountTreeRowKind.loadMore);
      expect(rows.last.hostId, 'group_3');
    });

    test('a host with no cache yet shows the in-flight row', () {
      final sub = structural(id: 'sub_110', level: 'sub', directCount: 5);
      final root = structural(id: 'acc_1', children: [sub]);

      final rows = flattenAccountTree(
        tree: [root],
        expanded: const {'acc_1', 'sub_110'},
        childrenCache: const {},
        loadingChildren: const {'sub_110'},
        childHasMore: const {},
        filters: const AccountTreeFilters(),
      );

      expect(rows.last.kind, AccountTreeRowKind.loading);
      expect(rows.last.hostId, 'sub_110');
    });

    test('hide-zero-balances and maxLevel filter the flat list', () {
      final zero = structural(id: 'main_12', level: 'main', balance: 0);
      final root = structural(id: 'acc_1', children: [zero]);

      final filtered = flattenAccountTree(
        tree: [root],
        expanded: const {'acc_1'},
        childrenCache: const {},
        loadingChildren: const {},
        childHasMore: const {},
        filters: const AccountTreeFilters(hideZeroBalances: true),
      );
      expect(filtered.map((r) => r.node?.id), ['acc_1']);

      final capped = flattenAccountTree(
        tree: [root],
        expanded: const {'acc_1'},
        childrenCache: const {},
        loadingChildren: const {},
        childHasMore: const {},
        filters: const AccountTreeFilters(maxLevel: 0),
      );
      expect(capped, hasLength(1));
    });

    test('formatTreeAmount groups thousands and keeps the sign', () {
      expect(formatTreeAmount(1234567.5), '1,234,567.50');
      expect(formatTreeAmount(-99.9), '-99.90');
      expect(formatTreeAmount(0), '0.00');
    });
  });
}
