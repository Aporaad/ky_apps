import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/provider_model.dart';
import '../data/models/provider_subscription_model.dart';
import '../data/repositories/service_result.dart';
import 'services_providers.dart';

/// حالة قائمة المزودين — تحميل/نجاح/فارغ/خطأ + بحث مُهلَّل مع حارس تسابق
/// Providers-list state — loading/empty/error + debounced search with a race guard.
class ProvidersState {
  final List<ProviderModel> providers;
  final bool isLoading;
  final String? error;
  final String query;

  const ProvidersState({
    this.providers = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  ProvidersState copyWith({
    List<ProviderModel>? providers,
    bool? isLoading,
    String? error,
    String? query,
    bool clearError = false,
  }) {
    return ProvidersState(
      providers: providers ?? this.providers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
    );
  }
}

class ProvidersListNotifier extends Notifier<ProvidersState> {
  Timer? _debounce;
  CancelToken? _cancelToken;

  /// رقم نسخة البحث — نتجاهل أي رد أجدّ منه طلباً قديماً (حارس التسابق)
  /// Search version — drop any response older than the latest request (race guard).
  int _searchVersion = 0;

  @override
  ProvidersState build() {
    ref.onDispose(() {
      _debounce?.cancel();
      _cancelToken?.cancel('disposed');
    });
    Future.microtask(() => load());
    return const ProvidersState(isLoading: true);
  }

  Future<void> load() async {
    _cancelToken?.cancel('superseded');
    _cancelToken = CancelToken();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await ref
          .read(providerRepositoryProvider)
          .fetchProviders(search: state.query, cancelToken: _cancelToken);
      state = state.copyWith(providers: list, isLoading: false);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'فشل تحميل المزودين / Failed to load providers',
      );
    }
  }

  /// بحث بإهالة 300ms — يقلل ضغط الشبكة أثناء الكتابة
  /// Debounced search (300ms) — trims network pressure while typing.
  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    state = state.copyWith(query: trimmed);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchVersion++;
      load();
    });
  }

  int get searchVersion => _searchVersion;

  /// تبديل حالة المزود ثم إعادة الجلب حتى تعكس القائمة الحالة الجديدة
  /// Toggle a provider then reload so the list reflects the new status.
  Future<ServiceResult> toggle(int providerId) async {
    final res = await ref.read(providerRepositoryProvider).toggleProvider(providerId);
    if (res.success) await load();
    return res;
  }

  /// حذف مزود ثم إزالته من القائمة
  /// Delete a provider then reload.
  Future<ServiceResult> delete(int providerId) async {
    final res = await ref.read(providerRepositoryProvider).deleteProvider(providerId);
    if (res.success) await load();
    return res;
  }
}

final providersListProvider = NotifierProvider<ProvidersListNotifier, ProvidersState>(
  ProvidersListNotifier.new,
);

/// اشتراكات مزوّد — autoDispose بعائلة المعرّف، فلا يبقى حيًا بلا شاشة
/// Provider subscriptions — autoDispose keyed by id, so nothing lingers without a screen.
final providerSubscriptionsProvider = FutureProvider.autoDispose
    .family<List<ProviderSubscriptionModel>, int>((ref, providerId) async {
  return ref.read(providerRepositoryProvider).fetchSubscriptions(providerId);
});

/// تفاصيل مزوّد واحد (قد تتضمن اعتبارات مكشوفة إن سُمح) — autoDispose
/// Single-provider detail (may include revealed credentials when permitted) — autoDispose.
final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderModel?, int>((ref, providerId) async {
  return ref.read(providerRepositoryProvider).fetchProvider(providerId);
});
