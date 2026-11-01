import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/item_model.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/data/models/store_model.dart';
import 'package:ky_apps/features/stores/data/repositories/store_result.dart';

/// اختبارات نماذج قسم المخازن — قراءة دفاعية من صفوف أوراكل
/// Stores model tests — defensive parsing of Oracle rows.
///
/// ── ما تحرسه هذه الاختبارات: أعمدة أوراكل تصل نصوصاً وأحياناً بمفاتيح صغيرة الحروف،
///    والواجهة يجب أن تصمد أمام ذلك بدل أن تنفجر عند أول قيمة `null`.
/// ── What these guard: Oracle columns arrive as text (and sometimes with lowercase keys);
///    the client must survive that instead of throwing on the first null.
void main() {
  group('StoreModel', () {
    test('reads uppercase Oracle keys and flags an archived store', () {
      final store = StoreModel.fromJson({
        'STORE_NO': 11,
        'STORE_NAME': 'مخزن سابق',
        'ITEMS': '0',
        'QTY': '0',
        'VALUE': '0',
        'KEEPERS': '0',
        'ARCHIVED': 1,
      });

      expect(store.storeNo, 11);
      expect(store.storeName, 'مخزن سابق');
      expect(store.archived, isTrue);
      expect(store.acceptsDocuments, isFalse);
    });

    test('accepts lowercase keys and numeric strings', () {
      final store = StoreModel.fromJson({
        'store_no': '3',
        'store_name': 'مخزن البيت',
        'qty': '120.5',
        'value': '5000',
      });

      expect(store.storeNo, 3);
      expect(store.qty, 120.5);
      expect(store.value, 5000);
      expect(store.acceptsDocuments, isTrue);
    });
  });

  group('ItemSubModel', () {
    test('renders the legacy size label without trailing zeros', () {
      final sub = ItemSubModel.fromJson({
        'SANF_DNO': 2010602208,
        'SANF_NO': 656,
        'LEN': 58,
        'WID': 3,
        'COLOR_NO': 4,
      });

      expect(sub.sizeLabel, '58×3');
    });

    test('falls back to zero for a missing dimension', () {
      final sub = ItemSubModel.fromJson({'SANF_DNO': 1, 'SANF_NO': 1});

      expect(sub.sizeLabel, '0×0');
    });
  });

  group('StoreOrderKind', () {
    test('only the transfer carries a destination store', () {
      expect(StoreOrderKind.transfer.hasTargetStore, isTrue);
      expect(StoreOrderKind.receive.hasTargetStore, isFalse);
      expect(StoreOrderKind.issue.hasTargetStore, isFalse);
    });

    test('the transfer has no party, the other two do', () {
      expect(StoreOrderKind.transfer.hasParty, isFalse);
      expect(StoreOrderKind.receive.hasParty, isTrue);
      expect(StoreOrderKind.issue.hasParty, isTrue);
    });

    test('round-trips through its route code', () {
      for (final kind in StoreOrderKind.values) {
        expect(StoreOrderKind.fromCode(kind.code), kind);
      }
    });
  });

  group('StoreOrderModel', () {
    test('builds the reference from number and year', () {
      final order = StoreOrderModel.fromJson({
        'BILL_NO': 535,
        'YEAR': 2026,
        'NET': '303100',
        'STORE_NO': 4,
      });

      expect(order.reference, '535-2026');
      expect(order.net, 303100);
    });
  });

  group('StoreResult', () {
    test('surfaces the first field error instead of the generic message', () {
      final result = StoreResult.fromBody({
        'success': false,
        'message': 'بيانات غير صالحة',
        'errors': {
          'store_name': ['يوجد مخزن بنفس الاسم'],
        },
      });

      expect(result.success, isFalse);
      expect(result.displayMessage, 'يوجد مخزن بنفس الاسم');
    });

    test('falls back to the message when there are no field errors', () {
      final result = StoreResult.fromBody({
        'success': false,
        'message': 'المخزن أرشيفي',
      });

      expect(result.displayMessage, 'المخزن أرشيفي');
    });
  });
}
