import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/permission_codes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/permission_gate.dart';
import '../../../data/models/message_model.dart';
import '../../../providers/messages_provider.dart';
import '../../../providers/services_providers.dart';
import '../../widgets/message_status_segments.dart';
import 'message_compose_screen.dart';

/// سجل رسائل قناة واحدة — تبويب الحالة + معاينة النص + تفاصيل كاملة + زر إرسال
/// A single channel's message log — status tabs + text preview + full detail + send.
///
/// لا مؤقّت تلقائي: الطابور تستهلكه مهمة أوراكل كل ثوانٍ، فالسحب للتحديث يكفي ويمنع التنافس.
/// No auto-timer: the Oracle job drains the queue every few seconds, so pull-to-refresh is enough
/// and avoids racing the job.
class MessageLogScreen extends ConsumerStatefulWidget {
  const MessageLogScreen({required this.channel, super.key});

  final MessageChannel channel;

  @override
  ConsumerState<MessageLogScreen> createState() => _MessageLogScreenState();
}

class _MessageLogScreenState extends ConsumerState<MessageLogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool get _isWhatsapp => widget.channel == MessageChannel.whatsapp;

  String get _title => _isWhatsapp ? 'رسائل واتساب' : 'الرسائل النصية';

  String get _composeCode =>
      _isWhatsapp ? Perm.whatsappCreate : Perm.smsCreate;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider(widget.channel));
    final notifier = ref.read(messagesProvider(widget.channel).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.refresh,
          ),
        ],
      ),
      floatingActionButton: PermissionGate(
        code: _composeCode,
        child: FloatingActionButton(
          heroTag: 'compose_${widget.channel.name}',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MessageComposeScreen(channel: widget.channel),
            ),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.send_rounded),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (q) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => notifier.search(q));
              },
              decoration: InputDecoration(
                hintText: 'بحث باسم العميل أو الرقم...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          MessageStatusSegments(
            value: state.status,
            onChanged: notifier.setStatus,
          ),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  Widget _buildBody(MessagesState state, MessagesNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: notifier.refresh, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (state.messages.isEmpty) {
      return const Center(
        child: Text('لا توجد رسائل', style: TextStyle(color: AppColors.textMuted)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => notifier.refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _MessageTile(
          message: state.messages[i],
          showFile: _isWhatsapp,
          onTap: () => _openDetail(context, state.messages[i]),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, MessageModel message) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MessageDetailSheet(message: message),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.showFile,
    required this.onTap,
  });

  final MessageModel message;
  final bool showFile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.msgText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.mobileNo ?? '—'}${message.customerName != null ? ' • ${message.customerName}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  if (showFile && message.fileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '📎 ${message.fileName}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  if (showFile && message.status == MessageStatus.failed && message.errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        message.errorMsg!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(status: message.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MessageStatus.pending => ('منتظرة', AppColors.warning),
      MessageStatus.sent => ('مُرسلة', AppColors.success),
      MessageStatus.failed => ('فاشلة', AppColors.error),
      MessageStatus.unknown => ('غير معروفة', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

/// تفاصيل الرسالة بالنص الكامل — تُجلب من الخادم عند فتحها
/// Message detail with full text — fetched from the server on open.
class _MessageDetailSheet extends ConsumerStatefulWidget {
  const _MessageDetailSheet({required this.message});

  final MessageModel message;

  @override
  ConsumerState<_MessageDetailSheet> createState() => _MessageDetailSheetState();
}

class _MessageDetailSheetState extends ConsumerState<_MessageDetailSheet> {
  late Future<MessageModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<MessageModel?> _load() async {
    // نص القائمة معاينة فقط؛ التفاصيل تجلب النص الكامل من نفس القناة
    // The list shows only a preview; detail fetches the full text from the same channel.
    final isWa = widget.message.status != MessageStatus.unknown &&
        widget.message.filePath != null;
    final repo = isWa
        ? ref.read(whatsappRepositoryProvider)
        : ref.read(smsRepositoryProvider);
    return repo.fetchMessage(widget.message.id);
  }

  @override
  Widget build(BuildContext context) {
    // ورقة محّدودة الارتفاع قابلة للتمرير — تجنّب تجاوز Expanded داخل عمود غير مُقيَّد.
    // Height-bounded scrollable sheet — avoids the Expanded-in-unbounded-Column overflow.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: FutureBuilder<MessageModel?>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final m = snap.data ?? widget.message;
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('تفاصيل الرسالة #${m.id}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        _StatusBadge(status: m.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow('إلى', m.mobileNo ?? '—'),
                    if (m.customerName != null)
                      _DetailRow('العميل', m.customerName!),
                    if (m.serviceId != null)
                      _DetailRow('معرّف الخدمة', '${m.serviceId}'),
                    if (m.providerId != null)
                      _DetailRow('معرّف المزوّد', '${m.providerId}'),
                    if (m.sendAttempt != null)
                      _DetailRow('محاولات الإرسال', '${m.sendAttempt}'),
                    if (m.createdAt != null) _DetailRow('التاريخ', m.createdAt!),
                    if (m.fileName != null) _DetailRow('الملف', m.fileName!),
                    if (m.errorMsg != null)
                      _DetailRow('خطأ', m.errorMsg!, isError: true),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 6),
                    const Text('نص الرسالة',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SelectableText(
                      m.msgText.isEmpty ? '—' : m.msgText,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// صف معلومة/قيمة في تفاصيل الرسالة — تخطيط ثابت يمنع الالتباس والتجاوز
/// A label/value detail row in the message sheet — stable layout, no wrapping surprises.
class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value, {this.isError = false});

  final String label;
  final String value;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isError ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
