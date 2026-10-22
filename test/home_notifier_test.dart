import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/data/models/user_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/home/data/models/home_layout.dart';
import 'package:ky_apps/features/home/domain/home_card_size.dart';
import 'package:ky_apps/features/home/presentation/providers/home_layout_notifier.dart';

/// مخزن في الذاكرة: لا قناة منصة ولا قرص
/// An in-memory store: no platform channel and no disk.
class _MemoryStorage extends SecureStorageService {
  String? blob;

  @override
  Future<void> saveHomeLayout(String json) async => blob = json;

  @override
  Future<String?> getHomeLayout() async => blob;

  @override
  Future<void> deleteHomeLayout() async => blob = null;
}

/// مصادقة ثابتة: الحالة تُبنى مباشرة بدل `checkAuthStatus`
/// Fixed auth: the state is built directly instead of running `checkAuthStatus`.
class _StubAuth extends AuthNotifier {
  _StubAuth(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

AuthState _authWith(List<String> codes, {bool isAdmin = false}) {
  return AuthState(
    isAuthenticated: true,
    user: UserModel(
      id: 7,
      username: 'khaled',
      nameAr: 'خالد',
      isAdmin: isAdmin,
    ),
  ).withPermissions(
    PermissionSnapshot(userId: 7, isAdmin: isAdmin, permissions: codes),
  );
}

({ProviderContainer container, _MemoryStorage storage}) _harness({
  bool isAdmin = true,
}) {
  final storage = _MemoryStorage();
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      authNotifierProvider.overrideWith(
        () => _StubAuth(_authWith(const [], isAdmin: isAdmin)),
      ),
    ],
  );
  addTearDown(container.dispose);

  return (container: container, storage: storage);
}

void main() {
  group('HomeLayoutNotifier', () {
    test('loads the first-run layout for the signed-in user', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );

      await notifier.load();

      final state = harness.container.read(homeLayoutNotifierProvider);
      expect(state.loading, isFalse);
      expect(state.layout.userId, 7);
      expect(state.layout.hidden, isEmpty);
      expect(notifier.activeShortcuts, hasLength(14));
    });

    test('hiding and restoring a default card leaves no residue', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      await notifier.toggle('customers.section');
      var state = harness.container.read(homeLayoutNotifierProvider);
      expect(state.layout.hidden, contains('customers.section'));
      expect(state.layout.shown, isEmpty);
      expect(
        notifier.activeShortcuts.map((shortcut) => shortcut.id),
        isNot(contains('customers.section')),
      );

      // البلوب المكتوب فعلًا يحتوي الإخفاء — لا الحالة في الذاكرة وحدها
      // The blob actually written holds the hiding — not just the in-memory state.
      final saved = jsonDecode(harness.storage.blob!) as Map<String, dynamic>;
      expect(saved['hidden'], contains('customers.section'));

      await notifier.toggle('customers.section');
      state = harness.container.read(homeLayoutNotifierProvider);
      expect(state.layout.hidden, isEmpty);
      expect(state.layout.shown, isEmpty);
    });

    test('showing a non-default card records it in shown', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      expect(
        notifier.activeShortcuts.map((shortcut) => shortcut.id),
        isNot(contains('sales.section')),
      );

      await notifier.toggle('sales.section');

      final layout = harness.container.read(homeLayoutNotifierProvider).layout;
      expect(layout.shown, contains('sales.section'));
      expect(
        notifier.activeShortcuts.map((shortcut) => shortcut.id),
        contains('sales.section'),
      );
    });

    test('moving a card rewrites the whole active order', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      final before =
          notifier.activeShortcuts.map((shortcut) => shortcut.id).toList();
      await notifier.move(0, 3);

      final after =
          notifier.activeShortcuts.map((shortcut) => shortcut.id).toList();
      expect(after.first, before[1]);
      expect(after[2], before.first);
      expect(after.toSet(), before.toSet());
    });

    test(
      'the pinned card cannot be hidden or moved away from the tail',
      () async {
        final harness = _harness();
        final notifier = harness.container.read(
          homeLayoutNotifierProvider.notifier,
        );
        await notifier.load();

        await notifier.toggle('home.customize');

        final layout =
            harness.container.read(homeLayoutNotifierProvider).layout;
        expect(layout.hidden, isEmpty);
        expect(layout.shown, isEmpty);
        expect(
          notifier.activeShortcuts.map((shortcut) => shortcut.id),
          contains('home.customize'),
        );
      },
    );

    test('size and column preferences are written to the blob', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      await notifier.setSize(HomeCardSize.large);
      await notifier.setColumns(4);

      var layout = harness.container.read(homeLayoutNotifierProvider).layout;
      expect(layout.size, HomeCardSize.large);
      expect(layout.columns, 4);

      final saved = jsonDecode(harness.storage.blob!) as Map<String, dynamic>;
      expect(saved['size'], 'large');
      expect(saved['cols'], 4);

      // قيمة خارج المدى تعود «تلقائي» بدل أن تكسر الشبكة
      // An out-of-range value returns to automatic instead of breaking the grid.
      await notifier.setColumns(9);
      layout = harness.container.read(homeLayoutNotifierProvider).layout;
      expect(layout.columns, HomeLayout.autoColumns);
    });

    test('reset clears order, shown, and hidden', () async {
      final harness = _harness();
      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      await notifier.toggle('sales.section');
      await notifier.toggle('customers.section');
      await notifier.move(0, 2);

      await notifier.reset();

      final layout = harness.container.read(homeLayoutNotifierProvider).layout;
      expect(layout.order, isEmpty);
      expect(layout.shown, isEmpty);
      expect(layout.hidden, isEmpty);
      expect(layout.userId, 7);
    });

    test('a corrupt blob falls back to first run without throwing', () async {
      final harness = _harness();
      harness.storage.blob = '{not json';

      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      final state = harness.container.read(homeLayoutNotifierProvider);
      expect(state.loading, isFalse);
      expect(state.layout.userId, 7);
      expect(state.layout.hidden, isEmpty);
    });

    test('a blob owned by another user never leaks across sessions', () async {
      final harness = _harness();
      harness.storage.blob = jsonEncode({
        'v': 1,
        'user_id': 8,
        'order': ['accounts.section'],
        'hidden': ['customers.section'],
      });

      final notifier = harness.container.read(
        homeLayoutNotifierProvider.notifier,
      );
      await notifier.load();

      final layout = harness.container.read(homeLayoutNotifierProvider).layout;
      expect(layout.userId, 7);
      expect(layout.order, isEmpty);
      expect(layout.hidden, isEmpty);
    });
  });

  group('grants drive visibility, not storage', () {
    test('a withdrawn grant removes the card even when it is in shown', () async {
      // نفس المخزن بين الجلستين: التخطيط يبقى، والمنح وحدها تتغيّر
      // The same store across both sessions: the layout stays, only the grants change.
      final storage = _MemoryStorage();
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authNotifierProvider.overrideWith(
            () => _StubAuth(
              AuthState(
                isAuthenticated: true,
                user: const UserModel(id: 7, username: 'khaled'),
              ).withPermissions(
                const PermissionSnapshot(
                  userId: 7,
                  permissions: [Perm.salesView],
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(homeLayoutNotifierProvider.notifier);
      await notifier.load();
      await notifier.toggle('sales.section');

      expect(
        notifier.activeShortcuts.map((shortcut) => shortcut.id),
        contains('sales.section'),
      );

      // المنح تُبنى من جديد في الجلسة التالية: نفس التخطيط، وقرار عرض مختلف
      // Grants are rebuilt for the next session: same layout, different visibility answer.
      final revoked = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authNotifierProvider.overrideWith(
            () => _StubAuth(
              AuthState(
                isAuthenticated: true,
                user: const UserModel(id: 7, username: 'khaled'),
              ).withPermissions(const PermissionSnapshot(userId: 7)),
            ),
          ),
        ],
      );
      addTearDown(revoked.dispose);
      await revoked.read(homeLayoutNotifierProvider.notifier).load();

      expect(
        revoked
            .read(homeLayoutNotifierProvider.notifier)
            .activeShortcuts
            .map((shortcut) => shortcut.id),
        isNot(contains('sales.section')),
      );
    });
  });
}
