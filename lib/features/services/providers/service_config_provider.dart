import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/corp_model.dart';
import '../data/models/service_model.dart';
import '../data/repositories/service_result.dart';
import 'services_providers.dart';

/// حالة إعدادات الخدمات — CORP + قاموس SERVICES
/// Service-config state — the CORP singleton plus the SERVICES dictionary.
class ServiceConfigState {
  final CorpModel? corp;
  final List<ServiceModel> services;
  final bool isLoading;
  final String? error;

  const ServiceConfigState({
    this.corp,
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  ServiceConfigState copyWith({
    CorpModel? corp,
    List<ServiceModel>? services,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ServiceConfigState(
      corp: corp ?? this.corp,
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ServiceConfigNotifier extends Notifier<ServiceConfigState> {
  @override
  ServiceConfigState build() {
    Future.microtask(() => load());
    return const ServiceConfigState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await ref.read(serviceConfigRepositoryProvider).fetchConfig();
      if (data == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'تعذّر تحميل الإعدادات / Failed to load config',
        );
        return;
      }
      state = ServiceConfigState(
        corp: data['corp'] as CorpModel?,
        services: data['services'] as List<ServiceModel>,
        isLoading: false,
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل الإعدادات / Failed to load config',
      );
    }
  }

  /// حفظ صف CORP الوحيد (singleton بلا مفتاح)
  /// Save the single CORP row (a keyless singleton).
  Future<ServiceResult> saveCorp(Map<String, dynamic> payload) async {
    final result =
        await ref.read(serviceConfigRepositoryProvider).updateCorp(payload);
    if (result.success) await load();
    return result;
  }

  Future<ServiceResult> addService(Map<String, dynamic> payload) async {
    final result =
        await ref.read(serviceConfigRepositoryProvider).createService(payload);
    if (result.success) await load();
    return result;
  }

  Future<ServiceResult> removeService(int id) async {
    final result =
        await ref.read(serviceConfigRepositoryProvider).deleteService(id);
    if (result.success) await load();
    return result;
  }
}

final serviceConfigProvider =
    NotifierProvider<ServiceConfigNotifier, ServiceConfigState>(
  ServiceConfigNotifier.new,
);
