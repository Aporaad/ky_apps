import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../support/data/models/support_inquiry_model.dart';
import '../../../support/data/repositories/support_repository.dart';
import '../../data/models/admin_result.dart';

/// مزود مستودع استفسارات الدعم — نفس المستودع الذي يخدم قسم الزائر في شاشة المعلومات
/// The support-inquiry repository provider — the same repository the guest section uses.
final supportRepositoryAdminProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(client: ref.watch(dioClientProvider));
});

/// حالة قائمة استفسارات الدعم في لوحة الإدارة
/// The support-inquiry list state inside the admin panel.
class SupportInquiriesState {
  final List<SupportInquiryModel> tickets;
  final bool isLoading;
  final String? error;

  /// `all` | `new` | `answered` | `closed`
  final String status;
  final String search;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const SupportInquiriesState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.status = 'all',
    this.search = '',
    this.page = 1,
    this.limit = 50,
    this.total = 0,
    this.pages = 0,
  });

  /// هل توجد صفحة تالية؟ (تُقرأ من `meta.pages` لا من طول القائمة)
  /// Is there a next page? Read from `meta.pages`, never from the list length.
  bool get hasMore => page < pages;

  /// عدد التذاكر التي لم يُردّ عليها في الصفحة الحالية — رقم تقريبي من المحمّل، لا من الخادم
  /// How many unanswered tickets this page holds — a figure from the loaded page, not the server.
  int get openCount => tickets.where((ticket) => ticket.isOpen).length;

  SupportInquiriesState copyWith({
    List<SupportInquiryModel>? tickets,
    bool? isLoading,
    String? error,
    String? status,
    String? search,
    int? page,
    int? limit,
    int? total,
    int? pages,
    bool clearError = false,
  }) {
    return SupportInquiriesState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
    );
  }
}

/// محمّل الاستفسارات — نسخة من نمط `ActiveSessionsNotifier`: إلغاء الطلب السابق برقم إصدار
/// Loads inquiries following the ActiveSessionsNotifier pattern: cancel the superseded request
/// and ignore any answer that arrives after a newer one.
class SupportInquiriesNotifier extends Notifier<SupportInquiriesState> {
  CancelToken? _cancelToken;
  int _requestVersion = 0;

  @override
  SupportInquiriesState build() {
    ref.onDispose(() => _cancelToken?.cancel('provider-disposed'));

    return const SupportInquiriesState();
  }

  SupportRepository get _repo => ref.read(supportRepositoryAdminProvider);

  /// التحميل — تُستدعى من الشاشة بعد البناء لا من `build`
  /// Load — called by the screen after build, never from build itself.
  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    final token = CancelToken();
    _cancelToken = token;
    final version = ++_requestVersion;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.fetchInquiries(
        status: state.status,
        search: state.search,
        page: state.page,
        limit: state.limit,
        cancelToken: token,
      );

      if (version != _requestVersion) return;
      state = state.copyWith(
        tickets: result.items,
        total: result.total,
        pages: result.pages,
        page: result.page,
        limit: result.limit,
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل الاستفسارات: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      if (version != _requestVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل الاستفسارات: $e',
      );
    }
  }

  Future<void> setStatus(String status) async {
    if (status == state.status) return;
    state = state.copyWith(status: status, page: 1);
    await load();
  }

  Future<void> setSearch(String value) async {
    final query = value.trim();
    if (query == state.search) return;
    state = state.copyWith(search: query, page: 1);
    await load();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == state.page) return;
    state = state.copyWith(page: page);
    await load();
  }

  /// الرد / الإغلاق ثم إعادة التحميل — لأن صف الجدول هو مصدر الحالة الوحيد
  /// Reply or close, then reload — the table row is the single source of the ticket's state.
  Future<AdminResult<Map<String, dynamic>>> reply(
    int ticketId, {
    String? reply,
    required String status,
  }) async {
    final result = await _repo.replyToInquiry(
      ticketId,
      reply: reply,
      status: status,
    );
    if (result.success) await load();

    return result;
  }
}

final supportInquiriesProvider =
    NotifierProvider<SupportInquiriesNotifier, SupportInquiriesState>(
      SupportInquiriesNotifier.new,
    );
