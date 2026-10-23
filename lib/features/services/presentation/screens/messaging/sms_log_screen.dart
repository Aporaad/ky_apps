import 'package:flutter/material.dart';

import '../../../providers/messages_provider.dart';
import 'message_log_screen.dart';

/// شاشة سجل الرسائل النصية SMS — غلاف رفيع فوق سجل القناة الموحّد
/// SMS log screen — a thin wrapper over the unified channel log.
class SmsLogScreen extends StatelessWidget {
  const SmsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessageLogScreen(channel: MessageChannel.sms);
  }
}
