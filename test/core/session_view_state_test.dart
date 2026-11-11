import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/state/session_view_state.dart';
import 'package:ky_apps/features/auth/presentation/providers/auth_notifier.dart';
import 'package:ky_apps/features/employee_portal/domain/portal_sections.dart';
import 'package:ky_apps/features/stores/presentation/providers/items_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';
import 'package:ky_apps/features/workers/data/models/worker_model.dart';
import 'package:ky_apps/features/workers/presentation/providers/workers_provider.dart';

import '../support/quiet_network.dart';

/// يلتقط `WidgetRef` حياً من داخل الشجرة حتى تُنادى دالتا التفريغ كما يناديهما الهيكل تماماً
/// Captures a live `WidgetRef` from inside the tree so the reset helpers run exactly
/// the way the portal shell calls them — never through a detached container.
///
/// الورقة نفسها لا تقرأ أي مزود: الشبكة تبدأ فقط حين يقرّر الاختبار ذلك داخل
/// `runAsync`، فلا مؤقّتات معلّقة تتبقّى من زمن الاختبار الوهمي.
/// The probe itself reads no provider: requests start only when the test chooses,
/// inside `runAsync`, so no fake-async timers are ever left pending.
class _RefProbe extends StatelessWidget {
  const _RefProbe({required this.onReady});

  final void Function(WidgetRef ref) onReady;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        onReady(ref);
        return const SizedBox.shrink();
      },
    );
  }
}

/// يبني الشجرة ويسلّم `WidgetRef` صالحاً — ثم يعمل داخل زمن حقيقي بلا مؤقّتات وهمية
/// Builds the tree and hands back a usable `WidgetRef`; work then runs in the real
/// async zone, where the quiet network completes instead of piling up fake timers.
Future<void> _withProbe(
  WidgetTester tester, {
  List<String>? log,
  AuthState? auth,
  required Future<void> Function(WidgetRef ref) body,
}) async {
  late WidgetRef captured;

  await tester.pumpWidget(
    quietScope(
      log: log,
      auth: auth,
      child: MaterialApp(home: _RefProbe(onReady: (ref) => captured = ref)),
    ),
  );

  await tester.runAsync(() => body(captured));
}

void main() {
  group('registry integrity', () {
    test('no phantom section may live in the reset registry', () {
      // معرّف لا وجود له في سجل البوابة يعني مصفّراً لا يُنفَّذ أبداً — صامت وميت
      // An id with no portal counterpart is a reset that can never fire: silent and dead.
      final portalIds = portalSections.map((section) => section.id).toSet();
      final phantom = knownResetSectionIds.difference(portalIds);

      expect(
        phantom,
        isEmpty,
        reason: 'معرّفات لا تقابلها أقسام في portal_sections.dart: $phantom',
      );
    });

    test('every section that holds a searchable list or a report is registered',
        () {
      // الأقسام التي تحتفظ بحالة بحث/معطيات في مزودات الجذر — لا يجوز أن يغيب أحدها
      // The sections that keep search/parameter state in root providers — none may go missing.
      expect(
        knownResetSectionIds,
        containsAll(<String>[
          'home',
          'customers',
          'accounts',
          'stores',
          'tailoring',
          'workers',
          'management',
          'services',
        ]),
      );
    });
  });

  group('leaving a section', () {
    testWidgets('wipes its search and refetches the unfiltered list',
        (tester) async {
      final log = <String>[];

      await _withProbe(tester, log: log, body: (ref) async {
        ref.read(cuttingBillsListProvider.notifier).search('خالد');
        expect(ref.read(cuttingBillsListProvider).query, 'خالد');

        log.clear();

        // القسم الذي غادره المستخدم — لا الذي دخل إليه
        // The section the user left — not the one they entered.
        resetSectionViewState(ref, 'tailoring');
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(
          ref.read(cuttingBillsListProvider).query,
          '',
          reason: 'نص البحث يجب أن يعود فارغاً بعد مغادرة التفصيل',
        );
        expect(
          log,
          isNotEmpty,
          reason: 'الشاشة ما زالت mounted داخل IndexedStack، فلا بد من جلب جديد',
        );
      });
    });

    testWidgets('a section with no transient state is a no-op', (tester) async {
      final log = <String>[];

      await _withProbe(tester, log: log, body: (ref) async {
        log.clear();

        // «المبيعات» بلا مزودات بحث مشتركة — النداء يجب أن يمرّ بسلام
        // "sales" holds no shared search providers — the call must pass quietly.
        resetSectionViewState(ref, 'sales');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(log, isEmpty);
      });
    });
  });

  group('ending the session', () {
    testWidgets('wipes every section at once', (tester) async {
      final log = <String>[];

      await _withProbe(tester, log: log, body: (ref) async {
        // نلوّث أربعة أقسام مختلفة قبل الخروج
        // Dirty four different sections before signing out.
        ref.read(cuttingBillsListProvider.notifier).search('خالد');
        await ref.read(itemsListProvider.notifier).search('محمد');
        await ref.read(storesListProvider.notifier).search('المخزن الرئيسي');
        await ref
            .read(workersListProvider(WorkerType.cutter).notifier)
            .search('سالم');

        // الطلبات السابقة تصل قبل القياس، فتبدأ مرحلة التفريغ بلا طلبات معلّقة
        // The earlier requests land before measuring, so the wipe starts with nothing in flight.
        await Future<void>.delayed(const Duration(milliseconds: 80));

        resetSessionViewState(ref);
        // مهلة أطول: تفريغ كل الأقسام يُنشئ مزودات جديدة قد تُطلق جلبها الأولي
        // A longer pause: wiping every section instantiates fresh providers that may
        // fire their first load, which must settle before the scope is torn down.
        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(ref.read(cuttingBillsListProvider).query, '');
        expect(ref.read(itemsListProvider).search, '');
        expect(ref.read(storesListProvider).search, '');
        expect(
          ref.read(workersListProvider(WorkerType.cutter)).searchQuery,
          '',
        );
      });
    });

    testWidgets('a wipe without reload issues no request at all',
        (tester) async {
      final log = <String>[];

      await _withProbe(tester, log: log, body: (ref) async {
        // قسم التفصيل مزودٌ واحد لا يُنشئ طلباً في build()، فعزله عن الجلب واضح
        // The tailoring section is a single provider that requests nothing in its
        // build(), so isolating "no refetch" is unambiguous here.
        ref.read(cuttingBillsListProvider.notifier).search('خالد');
        await Future<void>.delayed(const Duration(milliseconds: 400));
        log.clear();

        resetSectionViewState(ref, 'tailoring', reload: false);
        await Future<void>.delayed(const Duration(milliseconds: 60));

        expect(ref.read(cuttingBillsListProvider).query, '');
        expect(
          log,
          isEmpty,
          reason: 'نهاية الجلسة تُصفّر بلا أي طلب شبكة — لا معنى لجلب لن يُرى',
        );
      });
    });

    testWidgets('leaves the remembered username untouched', (tester) async {
      // مفتاح `ky_last_username` قرار جهاز لا حالة واجهة — لا يجوز أن يمسّه التفريغ
      // `ky_last_username` is a device decision, not view state — the wipe must not touch it.
      await _withProbe(
        tester,
        auth: stubAdminState(lastUsername: 'خالد'),
        body: (ref) async {
          expect(ref.read(authNotifierProvider).lastUsername, 'خالد');

          resetSectionViewState(ref, 'tailoring');
          await Future<void>.delayed(const Duration(milliseconds: 400));

          expect(
            ref.read(authNotifierProvider).lastUsername,
            'خالد',
            reason: 'تفريغ الواجهة لا يمسّ اسم آخر دخول محفوظ على الجهاز',
          );
        },
      );
    });
  });
}
