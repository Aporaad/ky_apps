import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/home/data/models/home_layout.dart';
import 'package:ky_apps/features/home/domain/home_card_size.dart';
import 'package:ky_apps/features/home/domain/home_shortcut.dart';
import 'package:ky_apps/features/home/presentation/widgets/home_tokens.dart';

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

  group('HomeLayout appearance preferences', () {
    test('first run is medium and automatic', () {
      final layout = HomeLayout.firstRun(3);

      expect(layout.size, HomeCardSize.medium);
      expect(layout.columns, HomeLayout.autoColumns);
    });

    test('a version 1 blob upgrades instead of being discarded', () {
      final layout = HomeLayout.fromJson({
        'v': 1,
        'user_id': 9,
        'order': ['customers.statement'],
        'hidden': ['stores.section'],
      }, userId: 9);

      expect(layout.order, ['customers.statement']);
      expect(layout.hidden, {'stores.section'});
      expect(layout.size, HomeCardSize.medium);
      expect(layout.columns, HomeLayout.autoColumns);
    });

    test('size and columns survive the round trip', () {
      const original = HomeLayout(
        userId: 9,
        size: HomeCardSize.large,
        columns: 4,
      );

      final restored = HomeLayout.fromJson(original.toJson(), userId: 9);

      expect(restored.size, HomeCardSize.large);
      expect(restored.columns, 4);
    });

    test('an unknown size name falls back to medium', () {
      final layout = HomeLayout.fromJson({
        'v': 2,
        'user_id': 9,
        'size': 'giant',
      }, userId: 9);

      expect(layout.size, HomeCardSize.medium);
    });

    test('a column count outside 2..6 becomes automatic', () {
      for (final bad in <Object?>[1, 7, 'x', null]) {
        final layout = HomeLayout.fromJson({
          'v': 2,
          'user_id': 9,
          'cols': bad,
        }, userId: 9);

        expect(layout.columns, HomeLayout.autoColumns, reason: 'cols: $bad');
      }
    });

    test('numeric text for cols is accepted', () {
      final layout = HomeLayout.fromJson({
        'v': 2,
        'user_id': 9,
        'cols': '3',
      }, userId: 9);

      expect(layout.columns, 3);
    });
  });

  group('HomeTokens.columns', () {
    test('automatic derives the count from width and size', () {
      expect(HomeTokens.columns(328, size: HomeCardSize.medium), 2);
      expect(HomeTokens.columns(1216, size: HomeCardSize.medium), 6);
      expect(HomeTokens.columns(800, size: HomeCardSize.small), 6);
    });

    test('a pinned count is honoured while the tiles stay readable', () {
      expect(HomeTokens.columns(1216, size: HomeCardSize.medium, fixed: 4), 4);
      expect(HomeTokens.columns(640, size: HomeCardSize.small, fixed: 6), 6);
    });

    test('a pinned count is capped on a narrow screen', () {
      // 328dp: أربعة أعمدة تعني ضلعًا 71dp (الوضع المصغّر)، وأكثر من ذلك يُقيَّد
      // 328dp: four columns means 71dp tiles (micro mode); beyond that the count is capped.
      expect(HomeTokens.columns(328, size: HomeCardSize.small, fixed: 6), 4);
      expect(HomeTokens.columns(328, size: HomeCardSize.medium, fixed: 2), 2);
    });

    test('never returns fewer than two or more than six columns', () {
      expect(HomeTokens.columns(200, size: HomeCardSize.large, fixed: 1), 2);
      expect(HomeTokens.columns(4000, size: HomeCardSize.small, fixed: 9), 6);
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
