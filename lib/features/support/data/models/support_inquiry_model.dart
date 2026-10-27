import 'dart:ui' show Color;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_encoding_utils.dart';

/// نموذج تذكرة استفسار دعم قادم من `GET /support/inquiries`
/// A support-inquiry ticket as served by `GET /support/inquiries`.
///
/// القراءة مزدوجة الحالة لأن الخادم يمرّر صفوف أوراكل الخام أحياناً بأحرف كبيرة، والعربية
/// تمرّ على [ArabicEncodingUtils.fix] لأن العمود يخزّن بايتات CP1256 كما في كل الجداول الإرثية.
/// Reads tolerate both key cases because the API sometimes proxies raw Oracle rows, and every
/// Arabic string passes through [ArabicEncodingUtils.fix] since the column stores CP1256 bytes
/// like every other legacy table.
class SupportInquiryModel {
  const SupportInquiryModel({
    required this.ticketId,
    this.userId,
    this.userName,
    this.contactName,
    this.contactPhone,
    this.message = '',
    this.status = 'new',
    this.adminReply,
    this.repliedBy,
    this.repliedOn,
    this.appVersion,
    this.platform,
    this.createdOn,
    this.updatedOn,
  });

  final int ticketId;

  /// معرّف صاحب التذكرة — `null` للزائر قبل الدخول
  /// The ticket owner's id — null for a pre-login guest.
  final int? userId;

  /// اسم صاحب الجلسة من `APP_USERS.USER_NAME_AR` (يكون `null` للزائر)
  /// The signed-in owner's name from `APP_USERS.USER_NAME_AR` (null for a guest).
  final String? userName;
  final String? contactName;
  final String? contactPhone;
  final String message;

  /// `new` | `answered` | `closed` — مطابقة لقيد `APP_SUP_STATUS_CK`
  /// One of new / answered / closed, matching the `APP_SUP_STATUS_CK` constraint.
  final String status;
  final String? adminReply;
  final int? repliedBy;
  final String? repliedOn;
  final String? appVersion;
  final String? platform;
  final String? createdOn;
  final String? updatedOn;

  factory SupportInquiryModel.fromJson(Map<String, dynamic> json) {
    return SupportInquiryModel(
      ticketId: _parseInt(json['ticket_id'] ?? json['TICKET_ID']) ?? 0,
      userId: _parseInt(json['user_id'] ?? json['USER_ID']),
      userName: _fixOrNull(json['user_name'] ?? json['USER_NAME']),
      contactName: _fixOrNull(json['contact_name'] ?? json['CONTACT_NAME']),
      contactPhone: _parseString(json['contact_phone'] ?? json['CONTACT_PHONE']),
      message: _fixOrEmpty(json['message'] ?? json['MESSAGE']),
      status: (_parseString(json['status'] ?? json['STATUS']) ?? 'new')
          .toLowerCase(),
      adminReply: _fixOrNull(json['admin_reply'] ?? json['ADMIN_REPLY']),
      repliedBy: _parseInt(json['replied_by'] ?? json['REPLIED_BY']),
      repliedOn: _parseString(json['replied_on'] ?? json['REPLIED_ON']),
      appVersion: _parseString(json['app_version'] ?? json['APP_VERSION']),
      platform: _parseString(json['platform'] ?? json['PLATFORM']),
      createdOn: _parseString(json['created_on'] ?? json['CREATED_ON']),
      updatedOn: _parseString(json['updated_on'] ?? json['UPDATED_ON']),
    );
  }

  /// الاسم المعروض: اسم الحساب إن وُجد، وإلا الاسم الذي كتبه الزائر
  /// The name to show: the account name when present, otherwise what the guest typed.
  String get displayName {
    final account = (userName ?? '').trim();
    if (account.isNotEmpty) return account;

    return (contactName ?? '').trim();
  }

  /// تسمية الحالة بالعربية كما تعرضها الشرائح والبطاقات
  /// The Arabic status label used by the filter chips and cards.
  String get statusLabel {
    switch (status) {
      case 'answered':
        return 'تم الرد';
      case 'closed':
        return 'مغلق';
      default:
        return 'جديد';
    }
  }

  /// لون شارة الحالة — من لوحة الألوان الموحدة، لا لون مكتوب في الشاشة
  /// The status badge color, taken from the shared palette rather than a literal in the screen.
  Color get statusColor {
    switch (status) {
      case 'answered':
        return AppColors.success;
      case 'closed':
        return AppColors.textMuted;
      default:
        return AppColors.warning;
    }
  }

  /// هل التذكرة ما زالت بحاجة إلى إجراء؟ (تُستخدم لعدّ «الجديد» في الشاشة)
  /// Does the ticket still need action? Used to count the "new" chip.
  bool get isOpen => status == 'new';

  /// هل سبق الرد عليها بنص فعلي؟
  /// Has it actually been answered with text?
  bool get hasReply => (adminReply ?? '').trim().isNotEmpty;

  static int? _parseInt(dynamic value) {
    if (value == null || value == false) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  /// إصلاح العربية مع الحفاظ على `null` — `ArabicEncodingUtils.fix` تعيد `''` للفراغ
  /// Repair Arabic while preserving null — `ArabicEncodingUtils.fix` returns '' for blanks.
  static String? _fixOrNull(dynamic value) {
    final text = _parseString(value);
    if (text == null) return null;

    return ArabicEncodingUtils.fix(text);
  }

  static String _fixOrEmpty(dynamic value) => _fixOrNull(value) ?? '';
}
