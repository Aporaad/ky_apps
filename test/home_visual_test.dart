import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/auth/data/models/permission_snapshot_model.dart';
import 'package:ky_apps/features/auth/data/models/user_model.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/employee_portal/presentation/widgets/portal_section_scope.dart';
import 'package:ky_apps/features/home/data/models/home_layout.dart';
import 'package:ky_apps/features/home/domain/home_card_size.dart';
import 'package:ky_apps/features/home/presentation/providers/home_layout_notifier.dart';
import 'package:ky_apps/features/home/presentation/screens/home_dashboard_screen.dart';

/// لقطات بصرية للرئيسية بخط عربي حقيقي — أداة مراجعة، لا اختبار انحدار
/// Visual snapshots of the home screen with a real Arabic font — a review tool, not a regression
/// test.
///
/// تُشغَّل فقط عند طلبها صراحةً: `KY_VISUAL=1 flutter test --update-goldens test/home_visual_test.dart`.
/// السبب: مقارنة الصور تتأثر بخط النظام ونظام التشغيل، فتشغيلها في كل بناء يكسر المجموعة على
/// جهاز آخر بلا سبب. الصور الناتجة في `test/goldens/` للمراجعة فقط.
/// They run only when asked for explicitly, because pixel comparison depends on the system font and
/// OS and would break the suite on another machine for no reason. The output in `test/goldens/` is
/// for review only.

class _StubAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState(
    isAuthenticated: true,
    user: const UserModel(
      id: 7,
      username: 'arslan',
      nameAr: 'أرسلان',
      branchNo: 1,
      isAdmin: true,
    ),
  ).withPermissions(const PermissionSnapshot(userId: 7, isAdmin: true));
}

class _StubLayout extends HomeLayoutNotifier {
  _StubLayout(this._state);

  final HomeLayoutState _state;

  @override
  HomeLayoutState build() => _state;
}

Future<void> _loadArabicFont() async {
  final file = File('C:\\Windows\\Fonts\\tahoma.ttf');
  if (!file.existsSync()) return;

  final bytes = await file.readAsBytes();
  final loader = FontLoader('Tahoma')
    ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _pump(WidgetTester tester, Size size, HomeLayout layout) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_StubAuth.new),
        homeLayoutNotifierProvider.overrideWith(
          () => _StubLayout(HomeLayoutState(layout: layout)),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Tahoma',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFA27E4E),
            primary: const Color(0xFFA27E4E),
            secondary: const Color(0xFF0D9488),
          ),
        ),
        home: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: PortalSectionScope(
            openSection: (_) {},
            child: const HomeDashboardScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// تُشغَّل اللقطات عند `KY_VISUAL=1` فقط
/// Snapshots run only with `KY_VISUAL=1`.
final bool _visual = Platform.environment['KY_VISUAL'] == '1';

void main() {
  setUpAll(_loadArabicFont);

  testWidgets('home mobile', skip: !_visual, (tester) async {
    await _pump(tester, const Size(390, 844), HomeLayout.firstRun(7));

    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/home_mobile.png'),
    );
  });

  testWidgets('home mobile small cards', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const HomeLayout(userId: 7, size: HomeCardSize.small, columns: 3),
    );

    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/home_mobile_small.png'),
    );
  });

  testWidgets('home mobile three columns medium', skip: !_visual, (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(390, 844),
      const HomeLayout(userId: 7, columns: 3),
    );

    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/home_mobile_three.png'),
    );
  });

  testWidgets('home mobile four columns', skip: !_visual, (tester) async {
    await _pump(
      tester,
      const Size(390, 844),
      const HomeLayout(userId: 7, size: HomeCardSize.small, columns: 4),
    );

    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/home_mobile_four.png'),
    );
  });

  testWidgets('home desktop', skip: !_visual, (tester) async {
    await _pump(tester, const Size(1280, 800), HomeLayout.firstRun(7));

    await expectLater(
      find.byType(HomeDashboardScreen),
      matchesGoldenFile('goldens/home_desktop.png'),
    );
  });
}
