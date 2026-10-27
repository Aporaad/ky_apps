import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/app_info/presentation/utils/developer_tap_unlock.dart';

/// اختبارات عدّاد النقر الخفي — منطق نقي بلا واجهة ولا ساعة حقيقية
/// Tests for the hidden tap counter — pure logic, no widgets and no real clock.
void main() {
  /// ساعة يدوية: كل تقدّم للوقت يقع بقرار الاختبار لا بقرار جدول التشغيل
  /// A manual clock: time only moves when the test says so.
  ({DeveloperTapUnlock unlock, void Function(Duration) advance}) harness() {
    var now = DateTime(2026, 1, 1, 12);
    final unlock = DeveloperTapUnlock(now: () => now);

    return (
      unlock: unlock,
      advance: (delta) => now = now.add(delta),
    );
  }

  group('DeveloperTapUnlock', () {
    test('خمس نقرات متتالية تفتح البوابة مرة واحدة', () {
      final h = harness();

      // الأربع الأولى لا تفتح شيئاً — الافتراضي خمس
      // The first four open nothing — the default is five.
      for (var i = 0; i < 4; i++) {
        expect(h.unlock.registerTap(), isFalse);
      }
      expect(h.unlock.registerTap(), isTrue);
    });

    test('العدّاد يُصفَّر بعد النجاح فلا يُفتح بنقرة سادسة', () {
      final h = harness();

      for (var i = 0; i < 5; i++) {
        h.unlock.registerTap();
      }

      expect(h.unlock.count, 0);
      expect(h.unlock.registerTap(), isFalse);
    });

    test('أربع نقرات لا تكفي ولو تكررت إلى ما لا نهاية', () {
      final h = harness();

      for (var round = 0; round < 5; round++) {
        for (var i = 0; i < 4; i++) {
          expect(h.unlock.registerTap(), isFalse);
        }
        // نقرة خامسة تُتمّ الجولة وتُصفّر العدّاد
        // The fifth tap completes the round and resets the counter.
        expect(h.unlock.registerTap(), isTrue);
      }
    });

    test('فجوة أطول من النافذة تُصفّر العدّاد عند النقرة التالية', () {
      final h = harness();

      // أربع نقرات ثم انتظار 4 ثوانٍ: النافذة ثلاث ثوانٍ فقط
      // Four taps, then a four-second wait: the window is only three seconds.
      for (var i = 0; i < 4; i++) {
        h.unlock.registerTap();
      }
      h.advance(const Duration(seconds: 4));

      // العدّاد يُصفَّر عند وصول النقرة لا بالوقت وحده: لا مؤقّت يعمل في الخلفية
      // The counter resets when the next tap arrives, not by time alone: nothing ticks in
      // the background.
      expect(h.unlock.registerTap(), isFalse);
      expect(h.unlock.count, 1);
    });

    test('النقرات داخل النافذة تُجمَع ولو تباعدت ثانيتين', () {
      final h = harness();

      for (var i = 0; i < 4; i++) {
        h.unlock.registerTap();
        h.advance(const Duration(seconds: 2));
      }

      // الثانية الأخيرة ما زالت داخل النافذة منذ النقرة السابقة
      // The last tap is still within the window measured from the previous one.
      expect(h.unlock.registerTap(), isTrue);
    });

    test('الدالة المخصّصة تحترم العدد والنافذة الممرّرين', () {
      var now = DateTime(2026, 1, 1, 12);
      final unlock = DeveloperTapUnlock(
        required: 3,
        window: const Duration(milliseconds: 500),
        now: () => now,
      );

      expect(unlock.registerTap(), isFalse);
      expect(unlock.registerTap(), isFalse);
      expect(unlock.registerTap(), isTrue);

      // نافذة نصف ثانية: تجاوزها يبدأ جولة جديدة من نقرة واحدة
      // A half-second window: overrunning it starts a fresh round at one tap.
      unlock.registerTap();
      now = now.add(const Duration(milliseconds: 600));
      expect(unlock.registerTap(), isFalse);
      expect(unlock.count, 1);
    });

    test('reset يمحو العدّاد يدوياً (تغيير شاشة أو تغيير جلسة)', () {
      final h = harness();

      h.unlock.registerTap();
      h.unlock.registerTap();
      h.unlock.reset();

      expect(h.unlock.count, 0);
      expect(h.unlock.registerTap(), isFalse);
    });
  });
}
