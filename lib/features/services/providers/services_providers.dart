import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_notifier.dart';
import '../data/repositories/job_repository.dart';
import '../data/repositories/provider_repository.dart';
import '../data/repositories/service_config_repository.dart';
import '../data/repositories/sms_repository.dart';
import '../data/repositories/whatsapp_repository.dart';

/// مزوّدة مستودعات قسم الخدمات — Dio مركزي عبر `dioClientProvider`
/// Services-section repository providers — Dio comes from the shared dioClientProvider.
final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  return ProviderRepository(client: ref.watch(dioClientProvider));
});

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return SmsRepository(client: ref.watch(dioClientProvider));
});

final whatsappRepositoryProvider = Provider<WhatsappRepository>((ref) {
  return WhatsappRepository(client: ref.watch(dioClientProvider));
});

final serviceConfigRepositoryProvider = Provider<ServiceConfigRepository>((ref) {
  return ServiceConfigRepository(client: ref.watch(dioClientProvider));
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepository(client: ref.watch(dioClientProvider));
});
