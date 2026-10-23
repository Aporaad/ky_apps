import 'message_repository.dart';

/// مستودع الرسائل النصية SMS — المسار `/sms`
/// SMS repository — path `/sms`.
class SmsRepository extends MessageRepository {
  SmsRepository({required super.client}) : super(basePath: '/sms');
}
