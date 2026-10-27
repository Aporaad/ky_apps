import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../support/data/models/support_inquiry_model.dart';
import '../providers/support_inquiries_provider.dart';

/// شاشة إدارة استفسارات الدعم — ما يكتبه الموظفون والزوار في شاشة «معلومات البرنامج والدعم»
/// The support-inquiry admin screen — what employees and visitors write on the app-info screen.
///
/// القراءة والرد مقصوران على حاملي `support.view` و`support.update`: القائمة تُغلَّف بحاجز في
/// الشاشة، وأزرار الرد في اللوحة السفلية تُغلَّف بحاجزها الخاص — فيبقى «العرض بلا رد» حالة
/// ممكنة شرعاً (مشرف يقرأ ولا يجيب) لا ثغرة.
/// Reading and replying are gated by `support.view` and `support.update`: the list carries the
/// screen-level gate, and the reply buttons in the bottom sheet carry their own — so "may read,
/// may not answer" stays a legitimate state, not a hole.
class SupportInquiriesScreen extends ConsumerStatefulWidget {
  const SupportInquiriesScreen({super.key});

  @override
  ConsumerState<SupportInquiriesScreen> createState() =>
      _SupportInquiriesScreenState();
}

class _SupportInquiriesScreenState extends ConsumerState<SupportInquiriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(supportInquiriesProvider.notifier).load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// البحث مؤجَّل 300 ms — كل ضغطة مفتاح كانت ستصنع طلب قائمة كامل
  /// Search is debounced by 300 ms — every keystroke would otherwise fire a full list request.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(supportInquiriesProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportInquiriesProvider);
    final notifier = ref.read(supportInquiriesProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('استفسارات الدعم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: PermissionGate(
        code: Perm.supportView,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width < 600 ? 12 : 20,
              vertical: 10,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الهاتف أو نص الاستفسار…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _StatusChips(status: state.status, onSelect: notifier.setStatus),
                const SizedBox(height: 6),
                _Summary(state: state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: notifier.load,
                    child: _List(state: state, notifier: notifier),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// رقائق الحالة — الفلترة عند الخادم لا في الذاكرة، فالمغلقة لا تزاحم الجديدة
/// Status chips: filtering happens server-side, so closed tickets never crowd out new ones.
class _StatusChips extends StatelessWidget {
  final String status;
  final ValueChanged<String> onSelect;

  const _StatusChips({required this.status, required this.onSelect});

  static const List<(String, String)> _options = [
    ('all', 'الكل'),
    ('new', 'جديد'),
    ('answered', 'تم الرد'),
    ('closed', 'مغلق'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((option) {
        final selected = option.$1 == status;

        return ChoiceChip(
          label: Text(option.$2),
          selected: selected,
          onSelected: (_) => onSelect(option.$1),
          showCheckmark: false,
          selectedColor: AppColors.accent.withValues(alpha: 0.16),
          labelStyle: TextStyle(
            fontSize: 12.5,
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }
}

/// سطر الملخص: الإجمالي في القاعدة وما ظهر في هذه الصفحة
/// The summary line: the server total and what this page actually shows.
class _Summary extends StatelessWidget {
  final SupportInquiriesState state;

  const _Summary({required this.state});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        state.total == 0
            ? 'لا استفسارات مطابقة'
            : 'الإجمالي ${state.total} — المعروض ${state.tickets.length}'
                  '${state.pages > 1 ? ' (صفحة ${state.page}/${state.pages})' : ''}',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}

/// الحالات الأربع: تحميل / خطأ / فراغ / نجاح
/// The four states: loading, error, empty, and success.
class _List extends StatelessWidget {
  final SupportInquiriesState state;
  final SupportInquiriesNotifier notifier;

  const _List({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tickets.isEmpty) {
      return ListView(
        // السحب للتحديث يحتاج قائمة قابلة للتمرير حتى لو لم يوجد صف
        // Pull-to-refresh needs a scrollable even when no row exists.
        children: [
          const SizedBox(height: 80),
          _Placeholder(
            icon: Icons.cloud_off_rounded,
            title: 'تعذّر تحميل الاستفسارات',
            note: state.error!,
            color: AppColors.error,
            action: FilledButton.icon(
              onPressed: notifier.load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
    }

    if (state.tickets.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          _Placeholder(
            icon: Icons.inbox_rounded,
            title: 'لا استفسارات في هذه الحالة',
            note: 'الاستفسارات التي يرسلها الموظفون والزوار تظهر هنا مباشرة.',
            color: AppColors.textMuted,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: state.tickets.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == state.tickets.length) {
          return _MoreBar(state: state, notifier: notifier);
        }

        final ticket = state.tickets[index];

        return _TicketTile(
          ticket: ticket,
          onTap: () => _openTicket(context, ticket),
        );
      },
    );
  }

  /// التفاصيل والرد في لوحة سفلية — نفس التذكرة تراها كاملة وتجيب عليها بلا شاشة ثالثة
  /// Details and reply in a bottom sheet — one ticket, read and answered, with no third screen.
  Future<void> _openTicket(
    BuildContext context,
    SupportInquiryModel ticket,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _TicketSheet(ticket: ticket, notifier: notifier),
    );
  }
}

/// شريط «تحميل المزيد» — يظهر فقط عند وجود صفحة تالية
/// The "load more" bar, shown only when a next page exists.
class _MoreBar extends StatelessWidget {
  final SupportInquiriesState state;
  final SupportInquiriesNotifier notifier;

  const _MoreBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (!state.hasMore) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : OutlinedButton.icon(
                onPressed: () => notifier.goToPage(state.page + 1),
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text('تحميل المزيد'),
              ),
      ),
    );
  }
}

/// بطاقة تذكرة واحدة في القائمة
/// One ticket row in the list.
class _TicketTile extends StatelessWidget {
  final SupportInquiryModel ticket;
  final VoidCallback onTap;

  const _TicketTile({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = ticket.displayName.isEmpty ? 'زائر' : ticket.displayName;
    final phone = (ticket.contactPhone ?? '').trim();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(ticket: ticket),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#${ticket.ticketId}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.call_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    (ticket.createdOn ?? '').trim(),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SupportInquiryModel ticket;

  const _StatusBadge({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final color = ticket.statusColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ticket.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// لوحة التفاصيل والرد
/// The details-and-reply sheet.
class _TicketSheet extends ConsumerStatefulWidget {
  final SupportInquiryModel ticket;
  final SupportInquiriesNotifier notifier;

  const _TicketSheet({required this.ticket, required this.notifier});

  @override
  ConsumerState<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<_TicketSheet> {
  late final TextEditingController _replyCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _replyCtrl = TextEditingController(text: widget.ticket.adminReply ?? '');
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.displayName.isEmpty
                        ? 'استفسار #${ticket.ticketId}'
                        : ticket.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(ticket: ticket),
              ],
            ),
            const SizedBox(height: 6),
            _metaLine(ticket),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ticket.message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (ticket.hasReply) ...[
              const SizedBox(height: 12),
              Text(
                'الرد السابق',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket.adminReply!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 14),
            PermissionGate(
              code: Perm.supportUpdate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _replyCtrl,
                    maxLines: 3,
                    maxLength: 1000,
                    style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'نص الرد',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surfaceSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _save(status: 'answered'),
                          icon: _saving
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.reply_rounded, size: 18),
                          label: const Text('تم الرد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _save(status: 'closed'),
                          icon: const Icon(Icons.lock_outline_rounded, size: 18),
                          label: const Text('إغلاق'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// سطر البيانات الوصفية: الرقم والهاتف والنسخة والمنصة والتاريخ
  /// The metadata line: id, phone, app version, platform, and date.
  Widget _metaLine(SupportInquiryModel ticket) {
    final parts = <String>[
      '#${ticket.ticketId}',
      if ((ticket.contactPhone ?? '').trim().isNotEmpty) ticket.contactPhone!,
      if ((ticket.appVersion ?? '').trim().isNotEmpty) 'v${ticket.appVersion}',
      if ((ticket.platform ?? '').trim().isNotEmpty) ticket.platform!,
      if ((ticket.createdOn ?? '').trim().isNotEmpty) ticket.createdOn!,
    ];

    return Text(
      parts.join(' • '),
      textDirection: TextDirection.ltr,
      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
    );
  }

  /// الحفظ — التحقق المحلي يسبق الطلب: «تم الرد» بلا نص يرفضه الخادم بـ 422
  /// Save — local validation precedes the request: "answered" with no text is a server 422.
  Future<void> _save({required String status}) async {
    final reply = _replyCtrl.text.trim();

    if (status == 'answered' && reply.isEmpty) {
      setState(() => _error = 'اكتب نص الرد أولاً');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.notifier.reply(
      widget.ticket.ticketId,
      reply: reply,
      status: status,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.success) {
      setState(() => _error = result.displayMessage);
      return;
    }

    Navigator.of(context).pop();
  }
}

/// حالة فارغة/خطأ واحدة الشكل — أيقونة وعنوان وملاحظة وزر اختياري
/// One shared empty/error layout: icon, title, note, and an optional action.
class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String note;
  final Color color;
  final Widget? action;

  const _Placeholder({
    required this.icon,
    required this.title,
    required this.note,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              note,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}
