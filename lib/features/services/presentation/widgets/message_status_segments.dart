import 'package:flutter/material.dart';

/// شرائح تبويب حالة الرسائل — الكل/المرسلة/المنتظرة/الفاشلة
/// Message status segments — all/sent/pending/failed.
///
/// القيم تطابق وسيط `status` في الخادم حرفيًا، فالفلترة تحدث في `WHERE` لا بعد الجلب.
/// The values match the server's `status` param exactly, so filtering happens in WHERE, not in Dart.
class MessageStatusSegments extends StatelessWidget {
  const MessageStatusSegments({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const Map<String, String> _labels = {
    'all': 'الكل',
    'sent': 'المرسلة',
    'pending': 'المنتظرة',
    'failed': 'الفاشلة',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<String>(
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        showSelectedIcon: false,
        segments: [
          for (final entry in _labels.entries)
            ButtonSegment<String>(
              value: entry.key,
              label: Text(entry.value),
            ),
        ],
      ),
    );
  }
}
