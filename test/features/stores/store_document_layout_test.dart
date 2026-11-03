import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/core/utils/arabic_number_words.dart';
import 'package:ky_apps/features/stores/data/models/order_model.dart';
import 'package:ky_apps/features/stores/presentation/utils/store_document_layout.dart';

/// اختبارات قالب المستند: الأعمدة المشتركة والتفقيط وقراءة الحقول الجديدة
/// Document-template tests: the shared columns, the amount in words, and the new field parsing.
///
/// ── ما يحرسه هذا الملف فعلياً هو شرط الطلب: أن الشاشة والطبعة تقرآن نفس القائمة. لو انقلبت
///    الأعمدة في واحدة منهما لقال المستخدم «الطبعة غلط» وهو لا يقصد رقمًا بل ترتيباً.
/// ── What this really guards is the requirement itself: screen and print read one list. If the
///    columns flipped in either, the user would say "the printout is wrong" meaning order, not a figure.
void main() {
  StoreOrderLineModel line({
    double qty = 7,
    double price = 6500,
    double cap = 1,
    double len = 55,
    double wid = 17,
  }) => StoreOrderLineModel(
    sanfNo: 567,
    sanfDno: 2010100231,
    sanfName: 'ملون تايلندي',
    partNo: '20101002',
    subName: 'ملون تايلندي طقطق',
    subPartNo: '2001-17',
    unitName: 'ثوب',
    category: 'تايلندي',
    colorName: 'أبيض',
    shelfNo: 0,
    lengthFrom: len,
    lengthTo: wid,
    qty: qty,
    price: price,
    total: qty * price,
    cap: cap,
    pcs: qty * cap,
  );

  group('document columns', () {
    List<String> titlesOf(StoreOrderKind kind) =>
        storeDocumentColumns(kind).map((column) => column.title).toList();

    test('the document carries exactly the nine reviewed columns', () {
      // ── التسعة المطلوبة حرفياً وبهذا الترتيب على الشاشة وفي المطبوع
      // ── The nine required columns exactly, in this order on screen and in print.
      expect(titlesOf(StoreOrderKind.receive), [
        'رقم الصنف',
        'إسم الصنف',
        'اللون',
        'الوحدة',
        'الكمية',
        'عبوة',
        'قطعة',
        'سعر الصنف',
        'الإجمالي',
      ]);
    });

    test('the columns a reviewer never asks about are gone', () {
      // ── المحذوفة صراحةً: رقم الصنف الفرعي ورقم الرف وحجما الصنف وتصنيفه. أي واحد منها
      //    يعود يُضيّق الجدول حتى يلزم تمرير جانبي — وهو ما طُلب إزالته.
      // ── Explicitly dropped: sub-item no, shelf no, sizes and classification. Any one of
      //    them returning re-narrows the table until side-scrolling comes back.
      const dropped = ['رقم الصنف الفرعي', 'رقم الرف', 'طول', 'عرض', 'التصنيف'];

      for (final kind in StoreOrderKind.values) {
        final titles = titlesOf(kind);

        for (final title in dropped) {
          expect(titles, isNot(contains(title)), reason: '$kind ما زال يطبع «$title»');
        }
      }
    });

    test('the three kinds share the nine columns, and only the transfer adds a cost', () {
      final receive = titlesOf(StoreOrderKind.receive);
      final issue = titlesOf(StoreOrderKind.issue);
      final transfer = titlesOf(StoreOrderKind.transfer);

      // الثلاثة تعرض الأساس الواجب نفسه — المستخدم يقرأ المستند بالطريقة ذاتها
      // All three show the same required set, so the document reads the same way everywhere.
      expect(issue, equals(receive));
      expect(transfer.sublist(0, receive.length), equals(receive));

      // والتحويل وحده يزيد متوسط التكلفة: سؤال نقل قيمة بين مخزنين
      // A transfer alone adds the average cost: the value moving between two warehouses.
      expect(transfer.length, receive.length + 1);
      expect(transfer.last, 'متوسط التكلفة');
      expect(receive, isNot(contains('متوسط التكلفة')));
      expect(issue, isNot(contains('متوسط التكلفة')));
    });

    test('the detail strip carries the required fields and never repeats the number', () {
      final header = StoreOrderModel(
        billNo: 535,
        year: 2026,
        date: DateTime(2026, 10, 31),
        storeNo: 4,
        storeName: 'مخزن بضاعة جاهزة للبيع',
        storeTo: 1,
        storeToName: 'المحل الرئيسي',
        partyName: 'تسوية حساب انتاج الجاهز',
        billType: 2,
        sanfNums: 36,
        curName: 'يمني',
        trInvMId: 265471,
        accName: 'مخزون البضاعة',
      );

      List<String> labels(StoreOrderKind kind) =>
          storeDocumentMeta(kind, header).map((cell) => cell.$1).toList();

      expect(labels(StoreOrderKind.receive), [
        'تاريخ الفاتورة',
        'نوع الفاتورة',
        'إسم المخزن',
        'إسم المورد',
        'العملة',
        'العدد',
      ]);

      expect(labels(StoreOrderKind.issue), [
        'تاريخ الفاتورة',
        'نوع الفاتورة',
        'إسم المخزن',
        'إسم العميل',
        'العملة',
        'العدد',
      ]);

      expect(labels(StoreOrderKind.transfer), [
        'تاريخ الفاتورة',
        'من مخزن',
        'إلى مخزن',
        'رقم الصرف',
        'رقم التوريد',
        'حساب المخزون',
        'العدد',
      ]);

      // ── رقم الفاتورة يُكتب تحت العنوان مرة واحدة، فلا يتكرر داخل الشريط
      // ── The invoice number is written once under the title, never inside the strip.
      for (final kind in StoreOrderKind.values) {
        expect(labels(kind), isNot(contains('رقم الفاتورة')));
        expect(
          storeDocumentMeta(kind, header).map((cell) => cell.$2),
          isNot(contains(header.reference)),
          reason: '$kind يكرر رقم المستند في الشريط',
        );
      }
    });

    test('the profiles declare different header fields per kind', () {
      final receive = StoreDocProfile.of(StoreOrderKind.receive);
      final issue = StoreDocProfile.of(StoreOrderKind.issue);
      final transfer = StoreDocProfile.of(StoreOrderKind.transfer);

      // التوريد: نوع فاتورة + مرجع قابل للتحرير + خصم + عملة لكل سطر
      // Receive: bill type, an editable reference, discount, and a per-line currency.
      expect(receive.hasBillType, isTrue);
      expect(receive.referenceWritable, isTrue);
      expect(receive.hasDiscount, isTrue);
      expect(receive.hasLinePack, isTrue);

      // الصرف: نوع فاتورة وخصم، ومرجعه للقراءة فقط (رقم تسلسلي داخلي)
      // Issue: bill type and discount, and its reference is read-only (an internal serial).
      expect(issue.hasBillType, isTrue);
      expect(issue.hasReference, isTrue);
      expect(issue.referenceWritable, isFalse);
      expect(issue.hasLineCost, isTrue);

      // التحويل: بلا نوع فاتورة ولا خصم ولا عملة، وبمخزنين ومسلسلين
      // Transfer: no bill type, no discount, no currency — but two stores and two serials.
      expect(transfer.hasBillType, isFalse);
      expect(transfer.hasDiscount, isFalse);
      expect(transfer.hasCurrencyPair, isFalse);
      expect(transfer.hasTargetStore, isTrue);
      expect(transfer.hasSerials, isTrue);
      expect(transfer.hasParty, isFalse);
    });

    test('a line prints its sub item name, not the main item name', () {
      final columns = storeDocumentColumns(StoreOrderKind.receive);
      final nameColumn = columns.firstWhere((c) => c.title == 'إسم الصنف');

      // المستند المكتبي يطبع اسم الفرعي: هو ما يُصرف ويُورد فعلياً
      // The document prints the sub-item name — that is what is actually moved.
      expect(nameColumn.value(line()), 'ملون تايلندي طقطق');
    });

    test('a line prints the sub item name, colour, unit, quantity, price and total', () {
      final columns = storeDocumentColumns(StoreOrderKind.receive);
      String valueOf(String title) =>
          columns.firstWhere((c) => c.title == title).value(line());

      // الاسم الفرعي هو ما يُورد ويُصرف فعلياً
      // The sub-item name is what actually moves.
      expect(valueOf('إسم الصنف'), 'ملون تايلندي طقطق');
      expect(valueOf('رقم الصنف'), '20101002');
      expect(valueOf('اللون'), 'أبيض');
      expect(valueOf('الوحدة'), 'ثوب');
      expect(valueOf('الكمية'), '7');
      expect(valueOf('عبوة'), '1');
      expect(valueOf('قطعة'), '7');
      expect(valueOf('سعر الصنف'), '6,500.00');
      expect(valueOf('الإجمالي'), '45,500.00');
    });

    test('the minimum width keeps every column above its own floor and fits the sheet', () {
      for (final kind in StoreOrderKind.values) {
        final columns = storeDocumentColumns(kind);
        final width = storeDocumentMinWidth(columns);

        // ── الحد المطلوب يجب أن يبقى دون عرض الورقة (1240) بهامش كبير، وإلا عاد
        //    التمرير الجانبي الذي طُلب إنهاؤه.
        // ── The floor must stay well under the sheet width (1240), otherwise the side-scrolling
        //    the user asked to remove comes back.
        expect(width, lessThan(700), reason: '$kind يحتاج عرضاً يفرض تمريراً');

        final totalWeight = columns.fold<double>(
          0,
          (sum, column) => sum + column.weight,
        );

        for (final column in columns) {
          expect(
            width * column.weight / totalWeight,
            greaterThanOrEqualTo(column.minWidth - 0.0001),
            reason: '${column.title} انزل عن حدّه الأدنى',
          );
        }
      }
    });
  });

  group('amount in words', () {
    test('the invoice figure 303100 spells the printed line', () {
      // 303,100 → «ثلاثمائة وثلاثة ألف ومائة ﷼ يمني» كما في طبعة النظام
      // Exactly the line the desktop prints under the net box.
      expect(
        ArabicNumberWords.amount(303100),
        'ثلاثمائة و ثلاثة ألف و مائة ﷼ يمني',
      );
    });

    test('thousands use the plural between three and ten', () {
      expect(ArabicNumberWords.amount(3000, currency: ''), 'ثلاثة آلاف');
      expect(ArabicNumberWords.amount(2000, currency: ''), 'ألفان');
      expect(ArabicNumberWords.amount(1000, currency: ''), 'ألف');
      expect(ArabicNumberWords.amount(11000, currency: ''), 'أحد عشر ألف');
    });

    test('units come before tens, the way Arabic reads them', () {
      expect(ArabicNumberWords.amount(21, currency: ''), 'واحد و عشرون');
      expect(ArabicNumberWords.amount(55, currency: ''), 'خمسة و خمسون');
    });

    test('a fraction is spelled as the minor unit, zero is not printed', () {
      expect(ArabicNumberWords.amount(100.5), 'مائة ﷼ يمني و خمسون هللة');
      expect(ArabicNumberWords.amount(100), 'مائة ﷼ يمني');
    });

    test('zero and negatives stay readable instead of empty', () {
      expect(ArabicNumberWords.amount(0), 'صفر ﷼ يمني');
      expect(ArabicNumberWords.amount(-5), contains('سالب'));
    });
  });

  group('header parsing for the document template', () {
    test('bill type and currency basis are read from the legacy keys', () {
      final header = StoreOrderModel.fromJson({
        'BILL_NO': '535',
        'YEAR': '2026',
        'BILL_TYPE': '2',
        'SELECT1': '2',
        'DIS_RATE': '0',
        'CUR_NO': '1',
        'CUR_NAME': 'Ãíãäí',
        'CUR_PRICE': '1',
        'ENTRY_NO': '5260006766',
        'PROV_BILL': '963',
        'THE_TIME': '04:38:40 PM',
      });

      expect(header.billTypeLabel, 'آجل');
      expect(header.selectOne, 2);
      expect(header.curName, isNotNull);
      expect(header.entryNo, 5260006766);
      expect(header.partyBill, '963');
      expect(header.createdStamp, contains('04:38:40 PM'));
    });

    test('a cash bill reads as نقد and never as the default of credit', () {
      expect(StoreOrderModel.fromJson({'BILL_NO': 1, 'YEAR': 2026}).billTypeLabel, 'نقد');
      expect(
        StoreOrderModel.fromJson({'BILL_NO': 1, 'YEAR': 2026, 'BILL_TYPE': 2}).billTypeLabel,
        'آجل',
      );
    });

    test('the edit strip only appears when the document was actually edited', () {
      final fresh = StoreOrderModel.fromJson({'BILL_NO': 1, 'YEAR': 2026});
      final edited = StoreOrderModel.fromJson({
        'BILL_NO': 1,
        'YEAR': 2026,
        'LAST_UPDATED_ON': '2026-10-31T00:00:00.000Z',
        'LAST_UPDATED_BY_NAME': 'محمد',
      });

      expect(fresh.hasEditStamp, isFalse);
      expect(edited.hasEditStamp, isTrue);
    });

    test('line pieces fall back to quantity when no pack was recorded', () {
      final bare = StoreOrderLineModel.fromJson({
        'SANF_NO': 1,
        'SANF_DNO': 2,
        'QTY': '9',
        'SANF_PRICE': '10',
        'TOTAL': '90',
      });

      // عبوة غير مسجّلة تعني قطعة = كمية، لا صفرًا يُطبع في المستند
      // An unrecorded pack means pieces = quantity, never a zero printed on the document.
      expect(bare.cap, 0);
      expect(bare.pcs, 9);
    });
  });
}
