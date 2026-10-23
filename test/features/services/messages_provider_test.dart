import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/network/dio_client.dart';
import 'package:ky_apps/core/storage/secure_storage_service.dart';
import 'package:ky_apps/features/services/data/models/message_model.dart';
import 'package:ky_apps/features/services/data/repositories/sms_repository.dart';
import 'package:ky_apps/features/services/providers/messages_provider.dart';
import 'package:ky_apps/features/services/providers/services_providers.dart';

/// اختبار مُزوِّد سجل الرسائل: إهالة البحث (300ms) وحارس التسابق بالرقم الرقمي للنسخة
/// Message-log notifier test: the 300ms search debounce and the version race guard.
///
/// المستودع الوهمي يتأخر حسب تبويب الحالة، فيصل رد قديم بعد رد أحدث — والمنطق يجب أن يتجاهله.
/// The fake repository delays per status tab, so a stale reply can land after a newer one — and the
/// notifier must drop it (the `_searchVersion` guard).
class _FakeMessageRepo extends SmsRepository {
  _FakeMessageRepo()
      : super(client: DioClient(storage: SecureStorageService()));

  final List<String> searches = [];
  final Map<String, Duration> delayByStatus = {};

  @override
  Future<List<MessageModel>> fetchMessages({
    String status = 'all',
    String search = '',
    int page = 1,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    searches.add(search);
    final delay = delayByStatus[status] ?? Duration.zero;
    if (delay > Duration.zero) await Future.delayed(delay);
    // نحترم الإلغاء كما تفعله الشبكة الحقيقية، وإلا انقلب منطق حارس التسابق
    // Honour cancellation like the real network, or the race guard would not be exercised.
    if (cancelToken?.isCancelled == true) {
      throw DioException(
        requestOptions: RequestOptions(path: '/sms/messages'),
        type: DioExceptionType.cancel,
      );
    }
    return [
      MessageModel.fromJson({'ID': 1, 'MSG_TEXT': status, 'IS_SENT': 'Y'}),
    ];
  }
}

ProviderContainer _container(_FakeMessageRepo repo) {
  final container = ProviderContainer(
    overrides: [smsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('search is debounced to a single request with the latest query', () async {
    final repo = _FakeMessageRepo();
    final container = _container(repo);
    container
        .listen(messagesProvider(MessageChannel.sms), (_, __) {})
        .close(); // keep the notifier alive while we drive it manually

    // نترك التحميل الأولي يمر ثم نفرّغ السجل
    await Future.delayed(const Duration(milliseconds: 30));
    repo.searches.clear();

    final notifier =
        container.read(messagesProvider(MessageChannel.sms).notifier);
    notifier.search('a');
    notifier.search('ab');
    notifier.search('abc');

    // لم تُستدعِ الشبكة بعد: الإهالة لم تنقضِ
    expect(repo.searches, isEmpty);

    await Future.delayed(const Duration(milliseconds: 400));
    // استدعاء واحد فقط، بالاستعلام الأخير
    expect(repo.searches, ['abc']);
  });

  test('a stale slower reply is ignored when a newer one lands first', () async {
    final repo = _FakeMessageRepo()
      ..delayByStatus['sent'] = const Duration(milliseconds: 150)
      ..delayByStatus['pending'] = const Duration(milliseconds: 10);
    final container = _container(repo);
    container.listen(messagesProvider(MessageChannel.sms), (_, __) {});

    await Future.delayed(const Duration(milliseconds: 30));

    final notifier =
        container.read(messagesProvider(MessageChannel.sms).notifier);

    // «المرسلة» بطيئة تبدأ أولًا، ثم «المنتظلة» السريعة تلغيها وتتجاوزها
    // The slow 'sent' starts first, then the fast 'pending' supersedes it.
    notifier.setStatus('sent');
    notifier.setStatus('pending');

    // بعد وصول السريعة وقبل وصول البطيئة
    await Future.delayed(const Duration(milliseconds: 60));
    expect(
      container.read(messagesProvider(MessageChannel.sms)).messages.single.msgText,
      'pending',
    );
    expect(container.read(messagesProvider(MessageChannel.sms)).isLoading, isFalse);

    // ننتظر البطيئة لترد — فيجب أن تُتجاهل ولا تُبدّل الحالة
    await Future.delayed(const Duration(milliseconds: 200));
    expect(
      container.read(messagesProvider(MessageChannel.sms)).messages.single.msgText,
      'pending',
      reason: 'a superseded reply must not overwrite the newer state',
    );
  });
}
