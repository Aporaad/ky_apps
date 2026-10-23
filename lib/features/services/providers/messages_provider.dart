import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/message_model.dart';
import '../data/repositories/message_repository.dart';
import '../data/repositories/service_result.dart';
import 'services_providers.dart';

/// قناة الرسائل — تُحدد المستودع والمسار
/// Message channel — selects which repository/base path to use.
enum MessageChannel { sms, whatsapp }

/// حالة سجل الرسائل — تحميل/نجاح/فارغ/خطأ + تبويب الحالة + بحث مُهلَّل
/// Message-log state — loading/empty/error + status tab + debounced search.
class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final String query;

  /// التبويب الحالي: all|pending|sent|failed
  /// Current tab: all|pending|sent|failed.
  final String status;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.status = 'all',
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    String? query,
    String? status,
    bool clearError = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      status: status ?? this.status,
    );
  }
}

/// مُزوِّد سجل الرسائل لكل قناة — يملك إهالة البحث وحارس التسابق وإلغاء الطلب عند dispose
/// Per-channel message-log notifier — debounce, race guard, and cancellation on dispose.
class MessagesNotifier extends Notifier<MessagesState> {
  MessagesNotifier(this.channel);

  final MessageChannel channel;

  Timer? _debounce;
  CancelToken? _cancelToken;
  int _searchVersion = 0;

  MessageRepository get _repo => channel == MessageChannel.sms
      ? ref.read(smsRepositoryProvider)
      : ref.read(whatsappRepositoryProvider);

  @override
  MessagesState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel('disposed');
    });
    Future.microtask(() => load());
    return const MessagesState(isLoading: true);
  }

  /// تحميل السجل بالحالة الحالية — يُلغي الطلب السابق لمنع التسابق
  /// Load the log for the current status — cancels the in-flight request to avoid races.
  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    final version = ++_searchVersion;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.fetchMessages(
        status: state.status,
        search: state.query,
        cancelToken: _cancelToken,
      );
      // نتجاهل أي رد جاء من طلب قديم سبقه طلب أحدث (حارس التسابق)
      // Ignore any response superseded by a newer request (race guard).
      if (version != _searchVersion) return;
      state = state.copyWith(messages: list, isLoading: false);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (version != _searchVersion) return;
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل السجل / Failed to load messages',
      );
    }
  }

  /// تبديل تبويب الحالة ثم إعادة الجلب (الفلترة في WHERE خادميًا)
  /// Switch the status tab then refetch (server-side WHERE filtering).
  void setStatus(String status) {
    if (status == state.status) return;
    state = state.copyWith(status: status);
    load();
  }

  /// بحث بإهالة 300ms
  /// Debounced search (300ms).
  void search(String query) {
    _debounce?.cancel();
    state = state.copyWith(query: query.trim());
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  /// إعادة المحاولة بعد نجاح عملية كتابة
  /// Refresh after a successful write.
  void refresh() => load();

  /// تعديل رسالة منتظرة ثم إعادة الجلب — يُرجع نتيجة الخادم للواجهة لتعرض الرسالة
  /// Update a pending message then reload — returns the server result so the UI can toast it.
  Future<ServiceResult> updateMessage(int id, Map<String, dynamic> payload) async {
    final result = await _repo.update(id, payload);
    if (result.success) load();
    return result;
  }

  /// حذف رسالة منتظرة من الطابور ثم إعادة الجلب
  /// Delete a pending queued message then reload.
  Future<ServiceResult> deleteMessage(int id) async {
    final result = await _repo.delete(id);
    if (result.success) load();
    return result;
  }
}

final messagesProvider = NotifierProvider.family<MessagesNotifier, MessagesState, MessageChannel>(
  MessagesNotifier.new,
);
