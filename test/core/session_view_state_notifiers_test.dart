import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/active_sessions_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/support_inquiries_provider.dart';
import 'package:ky_apps/features/admin/presentation/providers/user_activity_provider.dart';
import 'package:ky_apps/features/customers/presentation/providers/customer_measurement_providers.dart';
import 'package:ky_apps/features/customers/presentation/providers/customers_provider.dart';
import 'package:ky_apps/features/my_statement/presentation/providers/my_statement_provider.dart';
import 'package:ky_apps/features/services/providers/jobs_provider.dart';
import 'package:ky_apps/features/services/providers/messages_provider.dart';
import 'package:ky_apps/features/services/providers/providers_provider.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/data/models/report_model.dart';
import 'package:ky_apps/features/stores/presentation/providers/items_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/orders_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/reports_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stock_sheet_providers.dart';
import 'package:ky_apps/features/stores/presentation/providers/stores_providers.dart';
import 'package:ky_apps/features/tailoring/presentation/providers/tailoring_providers.dart';
import 'package:ky_apps/features/workers/data/models/worker_model.dart';
import 'package:ky_apps/features/workers/presentation/providers/worker_group_work_report_provider.dart';
import 'package:ky_apps/features/workers/presentation/providers/worker_work_report_provider.dart';
import 'package:ky_apps/features/workers/presentation/providers/workers_provider.dart';

import '../support/quiet_network.dart';

/// وعاء مزودات بشبكة صامتة — كل مزود هنا غير `autoDispose`، فحالته تعيش في الجذر
/// A container on the quiet network — every provider here is non-autoDispose, so its
/// state lives in the root scope, which is exactly why the reset exists.
ProviderContainer _container() {
  final container = quietContainer();
  addTearDown(container.dispose);
  return container;
}

/// التاريخ بأثر رجعي — معطيات تقارير لا تعتمد على اليوم
/// A backdated range — report parameters independent of today.
DateTime _day(int day) => DateTime(2026, 3, day);

/// يترك الطلبات الفورية تُكمل قبل تفكيك الوعاء — لا كتابة على مزود مفكوك
/// Lets the in-flight requests finish before the container is torn down, so no
/// notifier writes state on a disposed Ref.
Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('customers section', () {
    test('the customers list returns to its first-visit state', () async {
      final container = _container();
      final notifier = container.read(customersListProvider.notifier);

      await notifier.search('خالد');
      expect(container.read(customersListProvider).searchQuery, 'خالد');

      notifier.resetTransient();

      final state = container.read(customersListProvider);
      expect(state.searchQuery, '');
      expect(state.customers, isEmpty);
      expect(state.page, 1);

      await _flush();
    });

    test('the measurements list returns to its first-visit state', () async {
      final container = _container();
      final notifier = container.read(measurementCustomersProvider.notifier);

      notifier.search('خالد');
      expect(container.read(measurementCustomersProvider).query, 'خالد');

      notifier.resetTransient();

      final state = container.read(measurementCustomersProvider);
      expect(state.query, '');
      expect(state.items, isEmpty);
      expect(state.page, 1);

      await _flush();
    });
  });

  group('accounts section', () {
    test('the account tree drops its search and date range', () async {
      final container = _container();
      final notifier = container.read(accountTreeProvider.notifier);

      await notifier.runSearch('خالد');
      expect(container.read(accountTreeProvider).searchQuery, 'خالد');

      notifier.resetTransient();

      final state = container.read(accountTreeProvider);
      expect(state.searchQuery, '');
      expect(state.fromDate, isNull);
      expect(state.toDate, isNull);

      await _flush();
    });

    test('the chart accounts list drops its search', () async {
      final container = _container();
      final notifier = container.read(chartAccountsProvider.notifier);

      await notifier.loadAccounts(search: 'خالد');
      expect(container.read(chartAccountsProvider).search, 'خالد');

      notifier.resetTransient();

      expect(container.read(chartAccountsProvider).search, '');

      await _flush();
    });
  });

  group('stores section', () {
    test('the stores list drops its search', () async {
      final container = _container();
      final notifier = container.read(storesListProvider.notifier);

      await notifier.search('المخزن الرئيسي');
      expect(container.read(storesListProvider).search, 'المخزن الرئيسي');

      notifier.resetTransient();

      expect(container.read(storesListProvider).search, '');

      await _flush();
    });

    test('items and sub items drop their searches together', () async {
      final container = _container();

      await container.read(itemsListProvider.notifier).search('قميص');
      await container.read(subItemsListProvider.notifier).search('قميص');

      container.read(itemsListProvider.notifier).resetTransient();
      container.read(subItemsListProvider.notifier).resetTransient();

      expect(container.read(itemsListProvider).search, '');
      expect(container.read(subItemsListProvider).search, '');

      await _flush();
    });

    test('the orders list clears its filters but keeps the bound document kind',
        () async {
      final container = _container();
      final notifier = container.read(ordersListProvider.notifier);

      notifier.bind(StoreOrderKind.issue);
      await notifier.search('خالد');
      expect(container.read(ordersListProvider).search, 'خالد');

      notifier.resetTransient(reload: true);

      final state = container.read(ordersListProvider);
      // النوع مِلْك الشاشة لا فلتر المستخدم: تصفيره كان سيعيد الشاشة إلى «توريد»
      // The kind belongs to the screen, not to the user's filter — clearing it would
      // silently bounce the screen back to "receive".
      expect(state.kind, StoreOrderKind.issue);
      expect(state.search, '');
      expect(state.storeNo, isNull);
      expect(state.from, isNull);
      expect(state.to, isNull);

      await _flush();
    });

    test('the stock sheet drops its search and store scope', () async {
      final container = _container();
      final notifier = container.read(stockSheetProvider.notifier);

      await notifier.search('قميص');
      expect(container.read(stockSheetProvider).search, 'قميص');

      notifier.resetTransient();

      final state = container.read(stockSheetProvider);
      expect(state.search, '');
      expect(state.storeNos, isEmpty);
      expect(state.groupNo, isNull);

      await _flush();
    });

    test('the balances report drops its search', () async {
      final container = _container();
      final notifier = container.read(balancesProvider.notifier);

      await notifier.search('قميص');
      expect(container.read(balancesProvider).search, 'قميص');

      notifier.resetTransient();

      expect(container.read(balancesProvider).search, '');

      await _flush();
    });

    test('the store report forgets its parameters and rows', () async {
      final container = _container();
      final notifier = container.read(storeReportProvider.notifier);

      final filter = StoreReportFilter(from: _day(1), to: _day(28));
      await notifier.run(filter);
      expect(container.read(storeReportProvider).filter, isNotNull);

      notifier.resetTransient();

      final state = container.read(storeReportProvider);
      expect(state.filter, isNull);
      expect(state.hasRun, isFalse);
      expect(state.movementRows, isEmpty);
      expect(state.summaryRows, isEmpty);

      await _flush();
    });
  });

  group('tailoring section', () {
    test('the cutting bills list drops its search and date range', () async {
      final container = _container();
      final notifier = container.read(cuttingBillsListProvider.notifier);

      notifier.search('خالد');
      await notifier.setRange(_day(1), _day(28));

      expect(container.read(cuttingBillsListProvider).query, 'خالد');
      expect(container.read(cuttingBillsListProvider).hasRange, isTrue);

      notifier.resetTransient();

      final state = container.read(cuttingBillsListProvider);
      expect(state.query, '');
      expect(state.hasRange, isFalse);
      expect(state.items, isEmpty);

      await _flush();
    });
  });

  group('workers section', () {
    test('all three worker families are wiped together', () async {
      final container = _container();

      for (final type in WorkerType.values) {
        await container.read(workersListProvider(type).notifier).search('خالد');
      }

      // مصفّر واحد يُنظّف العائلة كلها — نفس ما تفعله الخريطة في `session_view_state`
      // One reset cleans the whole family — exactly what the map in `session_view_state` does.
      for (final type in WorkerType.values) {
        container.read(workersListProvider(type).notifier).resetTransient();
      }

      await _flush();

      for (final type in WorkerType.values) {
        final state = container.read(workersListProvider(type));
        expect(state.searchQuery, '', reason: 'نوع ${type.name} لم يُصفَّر');
        expect(state.workers, isEmpty);
        expect(state.type, type);
      }
    });

    test('the three worker statements forget their payloads', () async {
      final container = _container();

      container.read(workerStatementProvider.notifier).resetTransient();
      final statement = container.read(workerStatementProvider);
      expect(statement.rows, isEmpty);
      expect(statement.summary, isNull);
      expect(statement.worker, isNull);
      expect(statement.isLoading, isFalse);

      container.read(workerWorkReportProvider.notifier).resetTransient();
      expect(container.read(workerWorkReportProvider).report, isNull);

      container.read(workerGroupWorkReportProvider.notifier).resetTransient();
      expect(container.read(workerGroupWorkReportProvider).report, isNull);

      await _flush();
    });
  });

  group('management section', () {
    test('the admin users list drops its search and filters', () async {
      final container = _container();
      final notifier = container.read(adminUsersProvider.notifier);

      await notifier.setSearch('خالد');
      expect(container.read(adminUsersProvider).search, 'خالد');

      notifier.resetTransient();

      final state = container.read(adminUsersProvider);
      expect(state.search, '');
      expect(state.users, isEmpty);
      expect(state.page, 1);

      await _flush();
    });

    test('the active sessions list drops its search', () async {
      final container = _container();
      final notifier = container.read(activeSessionsProvider.notifier);

      await notifier.setSearch('خالد');
      expect(container.read(activeSessionsProvider).search, 'خالد');

      notifier.resetTransient();

      expect(container.read(activeSessionsProvider).search, '');
    });

    test('the support inbox drops its search', () async {
      final container = _container();
      final notifier = container.read(supportInquiriesProvider.notifier);

      await notifier.setSearch('خالد');
      expect(container.read(supportInquiriesProvider).search, 'خالد');

      notifier.resetTransient();

      expect(container.read(supportInquiriesProvider).search, '');
    });

    test('the activity log returns to the whole timeline', () async {
      final container = _container();
      final notifier = container.read(userActivityProvider.notifier);

      await notifier.loadFor(7);
      notifier.setWindow(ActivityWindow.today);
      expect(container.read(userActivityProvider).window, ActivityWindow.today);

      notifier.resetTransient();

      expect(container.read(userActivityProvider).window, ActivityWindow.all);
    });
  });

  group('services section', () {
    test('the providers list drops its search', () async {
      final container = _container();
      final notifier = container.read(providersListProvider.notifier);

      notifier.search('خالد');
      expect(container.read(providersListProvider).query, 'خالد');

      notifier.resetTransient();

      await _flush();

      expect(container.read(providersListProvider).query, '');
    });

    test('both message channels drop their search', () async {
      final container = _container();

      for (final channel in MessageChannel.values) {
        container.read(messagesProvider(channel).notifier).search('خالد');
      }

      for (final channel in MessageChannel.values) {
        container.read(messagesProvider(channel).notifier).resetTransient();
      }

      await _flush();

      for (final channel in MessageChannel.values) {
        expect(
          container.read(messagesProvider(channel)).query,
          '',
          reason: 'قناة ${channel.name} لم تُصفَّر',
        );
      }
    });

    test('the jobs list narrows back to the messaging jobs', () async {
      final container = _container();
      final notifier = container.read(jobsProvider.notifier);

      notifier.toggleShowAll(true);
      expect(container.read(jobsProvider).showAll, isTrue);

      notifier.resetTransient();

      await _flush();

      expect(container.read(jobsProvider).showAll, isFalse);
    });
  });

  group('home shortcuts', () {
    test('the personal statements are emptied at session end', () async {
      final container = _container();

      container.read(myFinancialStatementProvider.notifier).resetTransient();
      final financial = container.read(myFinancialStatementProvider);
      expect(financial.fromDate, isNull);
      expect(financial.toDate, isNull);
      expect(financial.data, isNull);

      container.read(myWorkReportProvider.notifier).resetTransient();
      expect(container.read(myWorkReportProvider).report, isNull);

      await _flush();
    });
  });
}
