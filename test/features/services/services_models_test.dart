import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/services/data/models/message_model.dart';
import 'package:ky_apps/features/services/data/models/oracle_job_model.dart';
import 'package:ky_apps/features/services/data/models/provider_model.dart';

/// اختبارات نماذج قسم الخدمات — نقية بلا شبكة: المفاتيح المزدوجة، الأرقام كنص، والموجيباك
/// Services-section model tests — pure, no network: dual-case keys, numbers-as-text, mojibake.
void main() {
  group('ProviderModel.fromJson', () {
    test('reads UPPERCASE Oracle keys', () {
      final m = ProviderModel.fromJson(const {
        'PROVIDER_ID': 7,
        'PROVIDER_NAME': 'مورّد',
        'STATUS': 0,
        'USER_NAME': 'svc',
        'PASSWORD': '***',
        'TYPE': 'SMS',
      });
      expect(m.providerId, 7);
      expect(m.providerName, 'مورّد');
      expect(m.isEnabled, isFalse);
      expect(m.userName, 'svc');
      expect(m.password, '***');
      expect(m.type, 'SMS');
    });

    test('reads lowercase snake_case keys and numeric strings', () {
      // هذا هو ما يرسله الخادم فعلياً (yajra-oci8 يخفض أسماء الأعمدة): مفاتيح snake_case صغيرة،
      // والأرقام قد تصل كنص أو كدوبل. كان النموذج يقرأ camelCase فلا يجد شيئاً — وهذا سبب الخلل.
      // This is what the server actually sends (yajra lowercases column names): snake_case keys,
      // numbers as text or double. The model used to read camelCase and found nothing — the bug.
      final m = ProviderModel.fromJson(const {
        'provider_id': '12',
        'provider_name': 'X',
        'status': 1.0,
      });
      expect(m.providerId, 12);
      expect(m.status, 1);
      expect(m.isEnabled, isTrue);
    });

    test('fixes mojibake (cp1256) in the Arabic name', () {
      // «عربي» مشوّشة بايتات Windows-1256، والنموذج يمرّها عبر ArabicEncodingUtils.fix
      // «عربي» garbled as Windows-1256 bytes; the model runs it through fix().
      final m = ProviderModel.fromJson(const {
        'PROVIDER_ID': 1,
        'PROVIDER_NAME': '\u00DA\u00D1\u00C8\u00ED',
      });
      expect(m.providerName, 'عربي');
    });

    test('empty strings collapse to null', () {
      final m = ProviderModel.fromJson(const {
        'PROVIDER_ID': 1,
        'PROVIDER_NAME': 'n',
        'URL': '   ',
      });
      expect(m.url, isNull);
    });
  });

  group('MessageModel.fromJson', () {
    test('derives status from IS_SENT', () {
      MessageModel mk(String s) =>
          MessageModel.fromJson({'ID': 1, 'IS_SENT': s});
      expect(mk('N').status, MessageStatus.pending);
      expect(mk('Y').status, MessageStatus.sent);
      expect(mk('F').status, MessageStatus.failed);
      expect(mk('x').status, MessageStatus.unknown);
    });

    test('falls back to the list preview when full text is absent', () {
      final m = MessageModel.fromJson(const {
        'id': '5',
        'MSG_TEXT_PREVIEW': 'معاينة…',
      });
      expect(m.id, 5);
      expect(m.msgText, 'معاينة…');
    });

    test('prefers the full text over the preview', () {
      final m = MessageModel.fromJson(const {
        'ID': 5,
        'MSG_TEXT': 'النص الكامل',
        'MSG_TEXT_PREVIEW': 'النص الك…',
      });
      expect(m.msgText, 'النص الكامل');
    });

    test('carries whatsapp-only fields', () {
      final m = MessageModel.fromJson(const {
        'ID': 9,
        'IS_SENT': 'F',
        'FILE_NAME': 'pic.png',
        'ERROR_MSG': 'boom',
      });
      expect(m.fileName, 'pic.png');
      expect(m.errorMsg, 'boom');
      expect(m.status, MessageStatus.failed);
    });
  });

  group('OracleJobModel.fromJson', () {
    test('parses ENABLED as the TRUE/FALSE string Oracle returns', () {
      final on = OracleJobModel.fromJson(const {
        'JOB_NAME': 'SEND_MSG',
        'ENABLED': 'TRUE',
        'REPEAT_INTERVAL': 'freq=secondly;interval=3',
      });
      expect(on.jobName, 'SEND_MSG');
      expect(on.enabled, isTrue);
      expect(on.repeatInterval, 'freq=secondly;interval=3');

      final off = OracleJobModel.fromJson(const {
        'jobName': 'W_SEND_MSG',
        'enabled': 'false',
      });
      expect(off.enabled, isFalse);
    });

    test('empty strings become null', () {
      final j = OracleJobModel.fromJson(const {
        'JOB_NAME': 'X',
        'STATE': '  ',
      });
      expect(j.state, isNull);
    });
  });
}
