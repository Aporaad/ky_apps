import 'package:flutter/material.dart';

import '../../../providers/messages_provider.dart';
import 'message_log_screen.dart';

/// شاشة سجل رسائل واتساب — غلاف رفيع فوق سجل القناة الموحّد (مع حقول الملف والخطأ)
/// WhatsApp log screen — a thin wrapper over the unified channel log (with file/error fields).
class WhatsappLogScreen extends StatelessWidget {
  const WhatsappLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessageLogScreen(channel: MessageChannel.whatsapp);
  }
}
