import '../../../../core/utils/arabic_encoding_utils.dart';

/// حالة الرسالة المشتقّة من `IS_SENT` (N منتظرة، Y مُرسلة، F فاشلة)
/// Message status derived from `IS_SENT` (N pending, Y sent, F failed).
enum MessageStatus { pending, sent, failed, unknown }

/// نموذج رسالة موحّد لقناتي SMS وواتساب — حقول الملف اختيارية للواتساب
/// Unified message model for SMS & WhatsApp — file fields are whatsapp-only.
class MessageModel {
  final int id;
  final String msgText;
  final String? mobileNo;
  final String isSent;
  final int? serviceId;
  final int? providerId;
  final String? customerName;
  final int? sendAttempt;
  final String? createdAt;

  // حقول واتساب / whatsapp-only fields
  final String? filePath;
  final String? fileName;
  final String? fileType;
  final String? caption;
  final String? errorMsg;

  const MessageModel({
    required this.id,
    this.msgText = '',
    this.mobileNo,
    this.isSent = 'N',
    this.serviceId,
    this.providerId,
    this.customerName,
    this.sendAttempt,
    this.createdAt,
    this.filePath,
    this.fileName,
    this.fileType,
    this.caption,
    this.errorMsg,
  });

  MessageStatus get status {
    switch (isSent.toUpperCase()) {
      case 'N':
        return MessageStatus.pending;
      case 'Y':
        return MessageStatus.sent;
      case 'F':
        return MessageStatus.failed;
      default:
        return MessageStatus.unknown;
    }
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // الخادم يُرجع حروفًا صغيرة snake_case (`msg_text_preview`). القائمة تُرجع معاينة والتفاصيل النص الكامل.
    return MessageModel(
      id: _parseInt(json['ID'] ?? json['id']) ?? 0,
      msgText: ArabicEncodingUtils.fix(
        json['MSG_TEXT'] ?? json['msg_text'] ?? json['MSG_TEXT_PREVIEW'] ?? json['msg_text_preview'],
      ),
      mobileNo: _parseString(json['MOBILE_NO'] ?? json['mobile_no'], isArabic: false),
      isSent: (_parseString(json['IS_SENT'] ?? json['is_sent'], isArabic: false)) ?? 'N',
      serviceId: _parseInt(json['SERVICE_ID'] ?? json['service_id']),
      providerId: _parseInt(json['PROVIDER_ID'] ?? json['provider_id']),
      customerName: _parseString(json['CUSTOMER_NAME'] ?? json['customer_name']),
      sendAttempt: _parseInt(json['SEND_ATTEMPT'] ?? json['send_attempt']),
      createdAt: _parseString(json['CREATED_AT'] ?? json['created_at'], isArabic: false),
      filePath: _parseString(json['FILE_PATH'] ?? json['file_path'], isArabic: false),
      fileName: _parseString(json['FILE_NAME'] ?? json['file_name']),
      fileType: _parseString(json['FILE_TYPE'] ?? json['file_type'], isArabic: false),
      caption: _parseString(json['CAPTION'] ?? json['caption']),
      errorMsg: _parseString(json['ERROR_MSG'] ?? json['error_msg']),
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String? _parseString(dynamic v, {bool isArabic = true}) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return isArabic ? ArabicEncodingUtils.fix(s) : s;
  }
}
