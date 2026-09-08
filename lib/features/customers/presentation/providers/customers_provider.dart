import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/customer_statement_model.dart';
import '../../data/repositories/customer_repository.dart';

// ================================================================
// Providers
// ================================================================

/// مزود مستودع العملاء
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return CustomerRepository(client: client);
});

/// حالة قائمة العملاء
class CustomersListState {
  final List<CustomerModel> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int page;
  final bool hasMore;

  const CustomersListState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.page = 1,
    this.hasMore = true,
  });

  CustomersListState copyWith({
    List<CustomerModel>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? page,
    bool? hasMore,
    bool clearError = false,
  }) {
    return CustomersListState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Notifier لإدارة قائمة العملاء
class CustomersListNotifier extends Notifier<CustomersListState> {
  @override
  CustomersListState build() {
    Future.microtask(() => loadCustomers());
    return const CustomersListState(isLoading: true);
  }

  CustomerRepository get _repo => ref.read(customerRepositoryProvider);

  /// تحميل قائمة العملاء
  Future<void> loadCustomers({bool refresh = false}) async {
    if (refresh) {
      state = const CustomersListState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list = await _repo.fetchCustomers(
        search: state.searchQuery,
        page: 1,
      );
      state = state.copyWith(
        customers: list,
        isLoading: false,
        page: 1,
        hasMore: list.length >= 100,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل قائمة العملاء: ${e.toString()}',
      );
    }
  }

  /// البحث في قائمة العملاء
  Future<void> search(String query) async {
    final currentQuery = query.trim();
    state = state.copyWith(
      searchQuery: currentQuery,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _repo.fetchCustomers(search: currentQuery, page: 1);
      // تجنب تعارض النتائج القديمة مع الاستعلام الحالي
      if (state.searchQuery == currentQuery) {
        state = state.copyWith(
          customers: list,
          isLoading: false,
          page: 1,
          hasMore: list.length >= 100,
        );
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        return;
      }
      if (state.searchQuery == currentQuery) {
        state = state.copyWith(
          isLoading: false,
          error: 'خطأ في البحث: ${e.toString()}',
        );
      }
    }
  }
}

final customersListProvider =
    NotifierProvider<CustomersListNotifier, CustomersListState>(
      CustomersListNotifier.new,
    );

// ================================================================
// كشف حساب العميل
// ================================================================

class CustomerStatementState {
  final bool isLoading;
  final String? error;
  final List<CustomerStatementModel> rows;
  final Map<String, dynamic>? summary;
  final Map<String, dynamic>? customer;

  const CustomerStatementState({
    this.isLoading = false,
    this.error,
    this.rows = const [],
    this.summary,
    this.customer,
  });

  CustomerStatementState copyWith({
    bool? isLoading,
    String? error,
    List<CustomerStatementModel>? rows,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? customer,
    bool clearError = false,
  }) {
    return CustomerStatementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      rows: rows ?? this.rows,
      summary: summary ?? this.summary,
      customer: customer ?? this.customer,
    );
  }
}

class CustomerStatementNotifier extends Notifier<CustomerStatementState> {
  @override
  CustomerStatementState build() {
    return const CustomerStatementState(isLoading: true);
  }

  CustomerRepository get _repo => ref.read(customerRepositoryProvider);

  Future<void> loadStatement(
    int custNo, {
    String? fromDate,
    String? toDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.fetchStatement(
        custNo,
        fromDate: fromDate,
        toDate: toDate,
      );
      if (result != null) {
        state = state.copyWith(
          isLoading: false,
          rows: result['rows'] as List<CustomerStatementModel>,
          summary: result['summary'] as Map<String, dynamic>?,
          customer:
              result['customer'] != null
                  ? Map<String, dynamic>.from(result['customer'] as dynamic)
                  : null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'لا توجد بيانات لهذا العميل',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل كشف الحساب: ${e.toString()}',
      );
    }
  }
}

final customerStatementProvider =
    NotifierProvider<CustomerStatementNotifier, CustomerStatementState>(
      CustomerStatementNotifier.new,
    );
