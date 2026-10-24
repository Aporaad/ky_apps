import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/repositories/my_statement_repository.dart';

/// صيغة yyyy-MM-dd لكشف الحساب المالي
/// ISO formatter for the financial statement.
String _fmtIso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// صيغة dd/MM/yyyy لكشف العمل (نفس صيغة الخادم)
/// dd/MM/yyyy formatter for the work report (the server's own format).
String _fmtDmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// مزود المستودع — يُحقن عبر DioClient المشترك
/// Repository provider — injected through the shared DioClient.
final myStatementRepositoryProvider = Provider<MyStatementRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MyStatementRepository(client: dioClient);
});

/// حالة كشف الحساب المالي الشخصي
/// Personal financial statement state.
class MyFinancialStatementState {
  final bool isLoading;
  final String? error;
  final dynamic data; // AccountStatementData
  final DateTime? fromDate;
  final DateTime? toDate;

  const MyFinancialStatementState({
    this.isLoading = false,
    this.error,
    this.data,
    this.fromDate,
    this.toDate,
  });

  MyFinancialStatementState copyWith({
    bool? isLoading,
    String? Function()? error,
    dynamic data,
    DateTime? Function()? fromDate,
    DateTime? Function()? toDate,
  }) {
    return MyFinancialStatementState(
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      data: data ?? this.data,
      fromDate: fromDate != null ? fromDate() : this.fromDate,
      toDate: toDate != null ? toDate() : this.toDate,
    );
  }
}

/// Notifier لكشف الحساب المالي الشخصي
/// Notifier for the personal financial statement.
class MyFinancialStatementNotifier extends Notifier<MyFinancialStatementState> {
  @override
  MyFinancialStatementState build() {
    // بدء التحميل عند بناء الحالة (نمط Notifier المشروع)
    Future.microtask(() => load());
    return const MyFinancialStatementState(isLoading: true);
  }

  Future<void> load({DateTime? from, DateTime? to}) async {
    // التحقق من وجود حساب مرتبط
    final authState = ref.read(authNotifierProvider);
    final accNo = authState.user?.accNo;
    if (accNo == null) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'لا يوجد حساب مالي مرتبط بحسابك — تواصل مع الإدارة',
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    final repo = ref.read(myStatementRepositoryProvider);
    try {
      final result = await repo.fetchMyFinancialStatement(
        fromDate: from != null ? _fmtIso(from) : null,
        toDate: to != null ? _fmtIso(to) : null,
      );
      state = MyFinancialStatementState(
        data: result,
        fromDate: from,
        toDate: to,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'خطأ في جلب كشف الحساب: $e',
      );
    }
  }
}

final myFinancialStatementProvider =
    NotifierProvider<MyFinancialStatementNotifier, MyFinancialStatementState>(
  MyFinancialStatementNotifier.new,
);

/// حالة كشف العمل الشخصي
/// Personal work report state.
class MyWorkReportState {
  final bool isLoading;
  final String? error;
  final dynamic report; // WorkerWorkReport?

  const MyWorkReportState({
    this.isLoading = false,
    this.error,
    this.report,
  });
}

/// Notifier لكشف العمل الشخصي
/// Notifier for the personal work report.
class MyWorkReportNotifier extends Notifier<MyWorkReportState> {
  @override
  MyWorkReportState build() {
    Future.microtask(() => load());
    return const MyWorkReportState(isLoading: true);
  }

  Future<void> load({DateTime? from, DateTime? to}) async {
    final authState = ref.read(authNotifierProvider);
    final accNo = authState.user?.accNo;
    if (accNo == null) {
      state = const MyWorkReportState(
        error: 'لا يوجد حساب مالي مرتبط بحسابك — تواصل مع الإدارة',
      );
      return;
    }

    state = const MyWorkReportState(isLoading: true);
    final repo = ref.read(myStatementRepositoryProvider);
    try {
      final result = await repo.fetchMyWorkReport(
        fromDate: from != null ? _fmtDmy(from) : null,
        toDate: to != null ? _fmtDmy(to) : null,
      );
      state = MyWorkReportState(report: result);
    } catch (e) {
      state = MyWorkReportState(
        error: 'خطأ في جلب كشف العمل: $e',
      );
    }
  }
}

final myWorkReportProvider =
    NotifierProvider<MyWorkReportNotifier, MyWorkReportState>(
  MyWorkReportNotifier.new,
);
