import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/customers/data/models/measurement_customer_model.dart';
import 'package:ky_apps/features/customers/data/models/measurement_model_ref.dart';

/// نماذج مقاسات العملاء — الصيغة التي تصل بها أوراكل فعلياً
/// Customer-measurement models — in the shape Oracle actually sends.
///
/// المحروس هنا ثلاثة أمور لا يمسكها المترجم: مفاتيح UPPER/snake بأي حالة، وأرقام تصل نصوصاً،
/// وعربية مخزّنة بايتات CP1256 تُرمَّم قبل العرض. والرابع هو المفتاح الرباعي: أي اختصار له
/// يعني أن موديل عميل قد يُعرض باسم عميل آخر.
/// Three things no compiler catches are guarded here: keys in either case, numbers arriving as
/// strings, and Arabic stored as CP1256 bytes that must be repaired before display. The fourth is
/// the four-part key: shortening any part of it means one customer's model could be shown under
/// another customer's name.
void main() {
  group('MeasurementCustomer', () {
    test('reads UPPER keys, string numbers and repaired Arabic together', () {
      final customer = MeasurementCustomer.fromJson(const <String, dynamic>{
        'CUST_NO': '40',
        // بايتات CP1256 لـ «محمد» كما تخزّنها القاعدة الحيّة فعلاً
        // CP1256 bytes for the name, exactly as the live database stores them.
        'CUST_NAME': '\u00E3\u00CD\u00E3\u00CF',
        'TEL_NO1': '777123456',
        'ACC_NO': '12310039',
        'BILLS_COUNT': '12',
        'MODELS_COUNT': '31',
        // المفاتيح التي يرسلها الخادم فعلاً: snake_case بالتسمية ثم الخام
        // The keys the server really sends: snake_case, display form then raw.
        'last_date': '09/02/2023',
        'raw_last_date': '2023-02-09',
      });

      expect(customer.custNo, 40);
      expect(customer.custName, 'محمد');
      expect(customer.telNo1, '777123456');
      expect(customer.accNo, 12310039);
      expect(customer.billsCount, 12);
      expect(customer.modelsCount, 31);
      expect(customer.lastDate, '09/02/2023');
      expect(customer.rawLastDate, isNotNull);
      expect(customer.rawLastDate!.year, 2023);
    });

    test('a snake_case page parses too — the server is the normalising layer', () {
      final customer = MeasurementCustomer.fromJson(const <String, dynamic>{
        'cust_no': 7,
        'cust_name': 'سالم',
        'group_no': 3,
        'models_count': 4,
      });

      expect(customer.custNo, 7);
      expect(customer.groupNo, 3);
      expect(customer.modelsCount, 4);
      // لا تاريخ جاهز: يُقرأ من الخام إن وُجد، ويُترك غائباً إن غاب بلا اختراع
      // With no ready date the raw one is used if present, and absence stays absence.
      expect(customer.lastDate, isNull);
    });

    test('a missing phone or a missing name never becomes an empty cell', () {
      // 4,313 صفاً في القاعدة بلا هاتف: الغياب حالة طبيعية لا استثناء
      // 4,313 live rows have no phone: absence is normal, not exceptional.
      final row = MeasurementCustomer.fromJson(const {
        'cust_no': 7,
        'cust_name': '',
        'models_count': null,
      });

      expect(row.telNo1, isNull);
      expect(row.displayName, 'عميل 7');
      expect(row.modelsCount, 0);
      expect(row.subtitle, contains('0 موديل'));
    });

    test('paging derives hasMore from page and pages', () {
      const full = MeasurementCustomerPage(total: 9007, page: 1, pages: 301);
      const last = MeasurementCustomerPage(total: 5, page: 1, pages: 1);

      expect(full.hasMore, isTrue);
      expect(last.hasMore, isFalse);
    });
  });

  group('MeasurementModelRef', () {
    test('parses a list row and its three flags', () {
      final model = MeasurementModelRef.fromJson(const <String, dynamic>{
        'bill_no': '35',
        'year': '2023',
        'seq_no': '48',
        'beneficiary': 'أحمد الصغير',
        'type_name': 'قصيري',
        'manual_bill_no': '34',
        'qty': '1',
        'pieces_count': '3',
        'cutting_done': '1',
        'tailor_done': '0',
        'handing_done': '0',
        'date': '09/02/2023',
        'raw_date': '2023-02-09',
      });

      expect(model.billNo, 35);
      expect(model.seqNo, 48);
      expect(model.piecesCount, 3);
      expect(model.date, '09/02/2023');
      expect(model.stageLabel, 'تم القص');
      expect(model.isComplete, isFalse);
      expect(model.billLabel, '35 / 2023');
    });

    test('a delivered model reads as delivered, and a blank beneficiary is named', () {
      final delivered = MeasurementModelRef.fromJson(
        const {'bill_no': 1, 'year': 2026, 'seq_no': 2, 'handing_done': 1},
      );
      final blank = MeasurementModelRef.fromJson(
        // 18,846 صفاً بلا مستفيد: البديل الصريح أفضل من شرطة تُقرأ «لا بيانات»
        // 18,846 rows have no beneficiary: an explicit fallback beats a dash.
        const {'bill_no': 1, 'year': 2026, 'seq_no': 2, 'beneficiary': '   '},
      );

      expect(delivered.stageLabel, 'تم التسليم');
      expect(delivered.isComplete, isTrue);
      expect(blank.beneficiary, isNull);
      expect(blank.beneficiaryLabel, 'بلا مستفيد محدّد');
      expect(blank.displayName, 'موديل 2');
    });

    test('the key carries the owner passed in, never a number from the row', () {
      final model = MeasurementModelRef.fromJson(
        const {'bill_no': 35, 'year': 2023, 'seq_no': 48},
      );

      final key = model.keyOf(40);

      expect(key.custNo, 40);
      expect(key.id, '40/35/2023/48');
      // المساواة على المفتاح الكامل: نفس الموديل تحت عميل آخر مفتاحٌ آخر لا مثيل له
      // Equality is the whole key: the same model under another customer is a different key.
      expect(key, isNot(model.keyOf(41)));
      expect(key, model.keyOf(40));
    });
  });

  group('MeasurementSibling', () {
    test('reads the selected flag as a JSON bool, not as a number', () {
      // الخادم يعيد `true`/`false`: قراءة رقمية بحتة كانت ستجعل كل موديل غير محدد
      // The server sends a real bool: a numeric-only read made every chip unselected.
      final selected = MeasurementSibling.fromJson(
        const {'seq_no': 48, 'beneficiary': 'خالد', 'selected': true},
      );
      final other = MeasurementSibling.fromJson(
        const {'seq_no': 49, 'selected': false},
      );

      expect(selected.selected, isTrue);
      expect(other.selected, isFalse);
      expect(selected.label, contains('خالد'));
      expect(other.label, 'موديل 49');
    });

    test('a legacy numeric flag still selects', () {
      final numeric = MeasurementSibling.fromJson(
        const {'seq_no': 1, 'selected': 1},
      );

      expect(numeric.selected, isTrue);
    });
  });

  group('MeasurementSubject', () {
    test('keeps the requested customer and exposes one model plus siblings', () {
      final subject = MeasurementSubject.fromJson(
        const <String, dynamic>{
          'header': {
            'bill_no': 35,
            'year': 2023,
            'cust_no': 40,
            'cust_name': 'تراب',
            'l1': '58',
          },
          'models': [
            {
              'seq_no': '48',
              'beneficiary': 'الصغير',
              'type_name': 'قصيري',
              'measurements': {'L1': '58', 'L2': 17, 'L3': null},
              'specs': {'neck_type': 'عادي'},
              'pieces': [
                {'seq_no1': '48', 'cloth_name': 'قماش صيفي'},
              ],
            },
          ],
          'measure_labels': {'L1': 'الطول', 'L2': 'الكتف'},
          'siblings': [
            {'seq_no': 48, 'selected': true},
            {'seq_no': 49, 'selected': false},
          ],
        },
        custNo: 40,
      );

      expect(subject.custNo, 40);
      expect(subject.detail.header.billNo, 35);
      expect(subject.model?.seqNo, 48);
      expect(subject.hasSiblings, isTrue);
      // المقاس يصل نصاً ويُسقط الفراغ: بقيت خانتان من ثلاث
      // Measurements arrive as strings and blanks drop out: two of three survive.
      expect(subject.model?.measurements.keys, ['L1', 'L2']);
      expect(subject.detail.labelFor('L1'), 'الطول');
      // التنقل بين الإخوة يبقي العميل المطلوب في المفتاح
      // Moving between siblings keeps the requested customer in the key.
      expect(subject.keyFor(49).id, '40/35/2023/49');
    });

    test('an empty model list is an honest absence, not a crash', () {
      final subject = MeasurementSubject.fromJson(
        const {'header': {'bill_no': 1, 'year': 2026}, 'models': []},
        custNo: 9,
      );

      expect(subject.model, isNull);
      expect(subject.hasSiblings, isFalse);
    });
  });
}
