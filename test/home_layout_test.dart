import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/home/data/models/home_layout.dart';
import 'package:ky_apps/features/home/domain/home_shortcut.dart';

/// اختصار اصطناعي للاختبار — لا يلمس الكتالوج الحقيقي ولا يستورد شاشة
/// A synthetic shortcut for tests — touches neither the real catalog nor any screen.
HomeShortcut spec(
  String id, {
  bool defaultOn = false,
  bool pinned = false,
  String sectionId = 'customers',
}) {
  return HomeShortcut(
    id: id,
    title: id,
    icon: Icons.circle_outlined,
    sectionId: sectionId,
    target: const SectionTarget('customers'),
    defaultOn: defaultOn,
    pinned: pinned,
  );
}

void main() {
  group('HomeLayout.fromJson', () {
    test('null means first run and never throws', () {
      final layout = HomeLayout.fromJson(null, userId: 9);

      expect(layout.userId, 9);
      expect(layout.order, isEmpty);
      expect(layout.shown, isEmpty);
      expect(layout.hidden, isEmpty);
    });

    test('non-map payload means first run', () {
      expect(HomeLayout.fromJson('garbage', userId: 9).order, isEmpty);
      expect(HomeLayout.fromJson(42, userId: 9).order, isEmpty);
      expect(HomeLayout.fromJson(<String>[], userId: 9).order, isEmpty);
    });

    test('an unknown schema version means first run', () {
      final layout = HomeLayout.fromJson({
        'v': 99,
        'user_id': 9,
        'order': ['a'],
      }, userId: 9);

      expect(layout.order, isEmpty);
    });

    test('a blob owned by another user is ignored on a shared device', () {
      final layout = HomeLayout.fromJson({
        'v': 1,
        'user_id': 8,
        'order': ['a'],
        'hidden': ['b'],
      }, userId: 9);

      expect(layout.userId, 9);
      expect(layout.order, isEmpty);
      expect(layout.hidden, isEmpty);
    });

    test('numeric text is accepted for v and user_id', () {
      final layout = HomeLayout.fromJson({
        'v': '1',
        'user_id': '9',
        'order': ['customers.section'],
      }, userId: 9);

      expect(layout.order, ['customers.section']);
    });

    test('order is cleaned: no blanks, no duplicates, order preserved', () {
      final layout = HomeLayout.fromJson({
        'v': 1,
        'user_id': 9,
        'order': ['b', 'a', 'b', '   ', null, 5],
      }, userId: 9);

      expect(layout.order, ['b', 'a', '5']);
    });

    test('shown and hidden accept a list and become sets', () {
      final layout = HomeLayout.fromJson({
        'v': 1,
        'user_id': 9,
        'shown': ['a', 'a', 'b'],
        'hidden': ['c'],
      }, userId: 9);

      expect(layout.shown, {'a', 'b'});
      expect(layout.hidden, {'c'});
    });
  });

  group('HomeLayout.resolve', () {
    final catalog = [
      spec('a', defaultOn: true),
      spec('b'),
      spec('c', pinned: true),
      spec('d', defaultOn: true),
    ];

    test(
      'first run shows the defaults plus the pinned card, in catalog order',
      () {
        final visible = HomeLayout.firstRun(1).resolve(catalog);

        expect(visible.map((shortcut) => shortcut.id), ['a', 'c', 'd']);
      },
    );

    test('hiding a default removes it', () {
      final layout = HomeLayout(userId: 1, hidden: {'a'});

      expect(layout.resolve(catalog).map((s) => s.id), ['c', 'd']);
    });

    test('showing a non-default adds it after the defaults', () {
      final layout = HomeLayout(userId: 1, shown: {'b'});

      expect(layout.resolve(catalog).map((s) => s.id), ['a', 'b', 'c', 'd']);
    });

    test('the pinned card survives even when it is in hidden', () {
      final layout = HomeLayout(userId: 1, hidden: {'c'});

      expect(layout.resolve(catalog).map((s) => s.id), contains('c'));
    });

    test('user order wins, unknowns are ignored, duplicates never repeat', () {
      final layout = HomeLayout(userId: 1, order: ['d', 'ghost', 'd', 'a']);

      expect(layout.resolve(catalog).map((s) => s.id), ['d', 'a', 'c']);
    });

    test('a catalog entry unknown to the layout lands at the end', () {
      final layout = HomeLayout(userId: 1, order: ['d']);

      expect(layout.resolve(catalog).map((s) => s.id), ['d', 'a', 'c']);
    });

    test('isVisible follows default, shown, and hidden', () {
      final layout = HomeLayout(userId: 1, shown: {'b'}, hidden: {'a'});

      expect(layout.isVisible(catalog[0]), isFalse);
      expect(layout.isVisible(catalog[1]), isTrue);
      expect(layout.isVisible(catalog[2]), isTrue);
      expect(layout.isVisible(catalog[3]), isTrue);
    });
  });

  group('HomeLayout JSON round trip', () {
    test('every field survives toJson then fromJson', () {
      const original = HomeLayout(
        userId: 7,
        order: ['b', 'a'],
        shown: {'b'},
        hidden: {'c'},
      );

      final restored = HomeLayout.fromJson(original.toJson(), userId: 7);

      expect(restored.order, original.order);
      expect(restored.shown, original.shown);
      expect(restored.hidden, original.hidden);
    });

    test('firstRun has nothing hidden or shown', () {
      final layout = HomeLayout.firstRun(5);

      expect(layout.userId, 5);
      expect(layout.order, isEmpty);
      expect(layout.shown, isEmpty);
      expect(layout.hidden, isEmpty);
      expect(layout.toJson()['v'], HomeLayout.schemaVersion);
    });
  });
}
