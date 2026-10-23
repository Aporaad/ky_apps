import 'message_repository.dart';

/// مستودع رسائل واتساب — المسار `/whatsapp`
/// WhatsApp repository — path `/whatsapp`.
class WhatsappRepository extends MessageRepository {
  WhatsappRepository({required super.client}) : super(basePath: '/whatsapp');
}
