import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/responsive.dart';
import 'package:ky_apps/features/employee_portal/presentation/screens/employee_main_layout.dart';

void main() {
  group('Responsive Breakpoints Tests', () {
    testWidgets('Responsive correctly identifies mobile breakpoint', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isTrue);
              expect(Responsive.isTablet(context), isFalse);
              expect(Responsive.isDesktop(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('Responsive correctly identifies desktop breakpoint', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(Responsive.isMobile(context), isFalse);
              expect(Responsive.isDesktop(context), isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('EmployeeMainLayout renders without overflow on mobile screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EmployeeMainLayout(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // لا يوجد أي استثناء في الـ layout أو RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('بوابة الموظف'), findsOneWidget);
    });

    testWidgets('EmployeeMainLayout renders without overflow on desktop screen (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EmployeeMainLayout(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('بوابة الموظف'), findsOneWidget);
    });
  });
}
