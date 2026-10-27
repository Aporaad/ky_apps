import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/theme/app_colors.dart';
import 'package:ky_apps/features/support/data/models/support_inquiry_model.dart';

/// اختبارات نموذج تذكرة الدعم — قراءة مزدوجة الحالة، إصلاح العربية، وتسميات الحالة
/// Support ticket model tests — dual-case reads, Arabic repair, and status labels.
void main() {
  group('SupportInquiryModel.fromJson', () {
    test('يقرأ المفاتيح snake_case كما يقدّمها الخادم', () {
      final m = SupportInquiryModel.fromJson(const {
        'ticket_id': 42,
        'user_id': 7,
        'user_name': 'خالد',
        'contact_phone': '777123456',
        'message': 'الطلب متأخر عن الموعد',
        'status': 'new',
        'app_version': '1.1.0',
        'platform': 'android',
        'created_on': '2026-02-01 09:30:00',
      });

      expect(m.ticketId, 42);
      expect(m.userId, 7);
      expect(m.userName, 'خالد');
      expect(m.contactPhone, '777123456');
      expect(m.message, 'الطلب متأخر عن الموعد');
      expect(m.status, 'new');
      expect(m.appVersion, '1.1.0');
      expect(m.platform, 'android');
      expect(m.createdOn, '2026-02-01 09:30:00');
      expect(m.displayName, 'خالد');
    });

    test('يقرأ المفاتيح الكبيرة أيضاً (صفوف أوراكل الخام)', () {
      final m = SupportInquiryModel.fromJson(const {
        'TICKET_ID': '15',
        'CONTACT_NAME': 'سالم',
        'MESSAGE': 'استفسار عن الفاتورة',
        'STATUS': 'ANSWERED',
      });

      expect(m.ticketId, 15);
      expect(m.displayName, 'سالم');
      expect(m.message, 'استفسار عن الفاتورة');

      // الحالة تُطبَّع إلى أحرف صغيرة فتُطابق قيد الجدول والمقارنات
      // The status is normalised to lowercase so it matches the table's check constraint.
      expect(m.status, 'answered');
    });

    test('يمرّر العربية على مصحّح الترميز — لا نصّ مشوّه في الواجهة', () {
      // بايتات CP1256 مقروءة كأنها لاتينية — الشكل الذي يصل من الجدول فعلاً
      // CP1256 bytes read as Latin — the shape that really leaves the legacy table.
      final mangled = 'ÇáØáÈ ãĘÃÎŃ';

      final m = SupportInquiryModel.fromJson({'message': mangled});

      expect(m.message, isNot(mangled));
      expect(m.message, isNot(equals('')));
    });

    test('تذكرة زائر: لا مستخدم ولا هاتف ولا اسم حساب', () {
      final m = SupportInquiryModel.fromJson(const {
        'ticket_id': 3,
        'message': 'رسالة الزائر من شاشة الدخول',
      });

      expect(m.userId, isNull);
      expect(m.userName, isNull);
      expect(m.displayName, '');
      expect(m.isOpen, isTrue);
      expect(m.hasReply, isFalse);
    });

    test('الاسم المعروض يفضّل اسم الحساب على ما كتبه الزائر', () {
      final m = SupportInquiryModel.fromJson(const {
        'ticket_id': 4,
        'user_name': 'منى',
        'contact_name': 'اسم مكتوب',
      });

      expect(m.displayName, 'منى');

      // بلا اسم حساب يُعرض المكتوب
      // Without an account name the typed one is shown.
      final guest = SupportInquiryModel.fromJson(const {
        'ticket_id': 5,
        'contact_name': 'اسم مكتوب',
      });
      expect(guest.displayName, 'اسم مكتوب');
    });

    test('statusLabel وstatusColor لكل حالة', () {
      SupportInquiryModel of(String status) =>
          SupportInquiryModel(ticketId: 1, status: status);

      expect(of('new').statusLabel, 'جديد');
      expect(of('answered').statusLabel, 'تم الرد');
      expect(of('closed').statusLabel, 'مغلق');

      expect(of('new').statusColor, AppColors.warning);
      expect(of('answered').statusColor, AppColors.success);
      expect(of('closed').statusColor, AppColors.textMuted);

      // أي حالة غير معروفة تسقط إلى «جديد» بدل شارة فارغة
      // An unknown status falls back to "new" rather than an empty badge.
      expect(of('weird').statusLabel, 'جديد');
    });

    test('hasReply يعتمد على نص فعلي لا على وجود الصف', () {
      expect(
        const SupportInquiryModel(ticketId: 1, adminReply: '   ').hasReply,
        isFalse,
      );
      expect(
        const SupportInquiryModel(ticketId: 1, adminReply: 'تم الحل').hasReply,
        isTrue,
      );
    });
  });
}
