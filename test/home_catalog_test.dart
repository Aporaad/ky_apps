import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/constants/permission_codes.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_section_titles.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_sections.dart';
import 'package:ky_apps/features/home/domain/home_shortcut.dart';
import 'package:ky_apps/features/home/domain/home_shortcut_catalog.dart';

/// الاختصارات المسموحة كمعرّفات، بترتيب الكتالوج — أوضح في رسائل الفشل
/// The allowed shortcuts as ids, in catalog order — clearer in failure messages.
List<String> allowedIds({required Set<String> granted, bool isAdmin = false}) {
  return allowedHomeShortcuts(
    granted: granted,
    isAdmin: isAdmin,
  ).map((shortcut) => shortcut.id).toList(growable: false);
}

void main() {
  group('catalog integrity', () {
    test('holds thirty shortcuts with unique ASCII ids', () {
      expect(homeShortcutCatalog, hasLength(30));

      final ids = homeShortcutCatalog.map((shortcut) => shortcut.id).toList();
      expect(ids.toSet(), hasLength(ids.length));

      final pattern = RegExp(r'^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$');
      for (final id in ids) {
        expect(pattern.hasMatch(id), isTrue, reason: 'bad id shape: $id');
      }
    });

    test('thirteen shortcuts are on by default, and exactly one is pinned', () {
      final defaults = homeShortcutCatalog.where(
        (shortcut) => shortcut.defaultOn,
      );

      expect(defaults, hasLength(13));
      expect(homeShortcutCatalog.where((s) => s.pinned), hasLength(1));
      expect(
        homeShortcutCatalog.firstWhere((s) => s.pinned).id,
        'home.customize',
      );
    });

    test('the three empty sections are flagged, not hidden', () {
      final flagged =
          homeShortcutCatalog
              .where((shortcut) => shortcut.underDevelopment)
              .map((shortcut) => shortcut.sectionId)
              .toSet();

      expect(flagged, {'sales', 'tailoring', 'stores'});
    });

    test('every permission code exists in the catalog mirror', () {
      final known = allPermissionCodes.toSet();

      for (final shortcut in homeShortcutCatalog) {
        for (final code in shortcut.codes) {
          expect(
            known.contains(code),
            isTrue,
            reason: '${shortcut.id} uses an unknown code: $code',
          );
        }
      }
    });

    test('every shortcut points at a registered section with a title', () {
      final sectionIds = portalSections.map((section) => section.id).toSet();

      for (final shortcut in homeShortcutCatalog) {
        expect(
          sectionIds.contains(shortcut.sectionId),
          isTrue,
          reason:
              '${shortcut.id} uses an unknown section: ${shortcut.sectionId}',
        );
        expect(
          PortalSectionTitles.of(shortcut.sectionId),
          isNot(shortcut.sectionId),
          reason: '${shortcut.sectionId} has no title constant',
        );
      }
    });

    test('a section shortcut carries its registry view codes verbatim', () {
      for (final shortcut in homeShortcutCatalog) {
        final target = shortcut.target;
        if (target is! SectionTarget) continue;

        final section = portalSections.firstWhere(
          (item) => item.id == target.sectionId,
        );

        expect(
          shortcut.sectionId,
          target.sectionId,
          reason: '${shortcut.id} filters under a different section',
        );
        expect(
          shortcut.codes.toSet(),
          section.viewCodes.toSet(),
          reason:
              '${shortcut.id} does not mirror the registry viewCodes of '
              '${target.sectionId}',
        );
      }
    });

    test('every screen target builds a widget without a network', () {
      for (final shortcut in homeShortcutCatalog) {
        final target = shortcut.target;
        if (target is! ScreenTarget) continue;

        expect(target.build(), isA<Widget>(), reason: shortcut.id);
      }
    });

    test('route targets are app-router paths', () {
      for (final shortcut in homeShortcutCatalog) {
        final target = shortcut.target;
        if (target is! RouteTarget) continue;

        expect(target.location.startsWith('/'), isTrue, reason: shortcut.id);
        expect(
          const ['/api-settings', '/security-settings'],
          contains(target.location),
          reason: '${shortcut.id} invents a route the router does not declare',
        );
      }
    });
  });

  group('allowedHomeShortcuts', () {
    test('a system admin gets all thirty', () {
      expect(allowedIds(granted: const {}, isAdmin: true), hasLength(30));
    });

    test('a user with no grants keeps only the ungated cards', () {
      expect(allowedIds(granted: const {}), [
        'settings.section',
        'settings.biometric',
        'home.customize',
      ]);
    });

    test('customers.view opens the two read cards plus the ungated ones', () {
      expect(allowedIds(granted: const {Perm.customersView}), [
        'customers.section',
        'customers.list',
        'settings.section',
        'settings.biometric',
        'home.customize',
      ]);
    });

    test('a module wildcard covers the write cards of that module', () {
      final ids = allowedIds(granted: const {'customers.*'});

      expect(ids, containsAll(<String>['customers.add', 'customers.edit']));
      expect(ids, hasLength(8));
    });

    test('an unknown code grants nothing', () {
      expect(allowedIds(granted: const {'customers.fly'}), [
        'settings.section',
        'settings.biometric',
        'home.customize',
      ]);
    });

    test('the customize card is never filtered out', () {
      for (final granted in <Set<String>>[
        const {},
        const {Perm.salesView},
        const {Perm.systemWildcard},
      ]) {
        expect(
          allowedIds(granted: granted),
          contains('home.customize'),
          reason: 'granted: $granted',
        );
      }
    });
  });
}
