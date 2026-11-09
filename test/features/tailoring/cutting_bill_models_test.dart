import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_detail_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_bill_summary_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_model_item.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_movement_model.dart';
import 'package:ky_apps/features/tailoring/data/models/cutting_piece_item.dart';
import 'package:ky_apps/features/tailoring/data/models/tailoring_parse.dart';
import 'package:ky_apps/features/tailoring/data/models/tailoring_reference_model.dart';

/// اختبارات نماذج قسم التفصيل — كل التطبيع الذي يجعل ردّ أوراكل قابلاً للعرض
/// Tailoring model tests — the whole normalisation that makes an Oracle reply displayable.
///
/// العطب المحمي: أوراكل يُرجع المفاتيح بأي حالة، والأرقام نصوصاً، والعربية بايتات CP1256
/// مشوّهة. لو انزلق أي من هذه إلى الواجهة لظهرت الشاشة بأسماء فارغة وأرقام مكسورة.
/// The guard: Oracle returns keys in either case, numbers as strings and Arabic as CP1256
/// mojibake bytes. If any of that leaked into the UI, the screen would show blank names and
/// broken figures.
void main() {
  // ================================================================
  // قراءة الحقول
  // ================================================================
  group('tailoring field readers', () {
    test('finds a key in either case', () {
      expect(tailoringField({'bill_no': 7}, 'bill_no'), 7);
      expect(tailoringField({'BILL_NO': 7}, 'bill_no'), 7);
      expect(tailoringField({'other': 7}, 'bill_no'), isNull);
    });

    test('reads numbers arriving as strings and decimals', () {
      final json = <String, dynamic>{
        'bill_no': '12345',
        'qty': 3,
        'yards': 2.75,
        'net': '1250.5',
        'blank': '   ',
      };

      expect(tailoringInt(json, 'bill_no'), 12345);
      expect(tailoringInt(json, 'qty'), 3);
      expect(tailoringDouble(json, 'yards'), 2.75);
      expect(tailoringDouble(json, 'net'), 1250.5);
      expect(tailoringInt(json, 'missing'), isNull);
      // النص غير الرقمي لا يرمي استثناء — يُقرأ غياباً
      expect(tailoringDouble(json, 'blank'), isNull);
    });

    test('repairs CP1256 mojibake and drops blanks to null', () {
      // بايتات cp1256 لـ «محمد» كما تخزّنها القاعدة فعلاً
      expect(tailoringText({'cust_name': '\u00E3\u00CD\u00E3\u00CF'}, 'cust_name'),
          'محمد');
      // النص السليم يمرّ كما هو بلا لمس
      expect(tailoringText({'cust_name': 'محمد'}, 'cust_name'), 'محمد');
      // الفراغ ليس نصاً فارغاً بل غياب
      expect(tailoringText({'cust_name': '   '}, 'cust_name'), isNull);
      expect(tailoringText({'x': 1}, 'cust_name'), isNull);
      // النص اللاتيني (الهاتف) بلا تصحيح ترميز
      expect(tailoringPlainText({'tel_no1': ' 777123456 '}, 'tel_no1'),
          '777123456');
    });

    test('reads ISO dates carrying Z and formats them for display', () {
      final json = <String, dynamic>{'raw_date': '2026-03-11T00:00:00Z'};

      expect(tailoringDate(json, 'raw_date'), isNotNull);
      expect(tailoringDisplayDate(json, 'date', rawKey: 'raw_date'),
          '11/03/2026');
      // التاريخ الجاهز من الخادم يتقدّم على الخام
      expect(
        tailoringDisplayDate(
          {'date': '05/01/2025', 'raw_date': '2026-03-11T00:00:00Z'},
          'date',
          rawKey: 'raw_date',
        ),
        '05/01/2025',
      );
      expect(tailoringDisplayDate({'raw_date': 'garbage'}, 'date',
          rawKey: 'raw_date'), isNull);
    });

    test('formats numbers with thousands separators and keeps the sign', () {
      expect(tailoringNumber(1234567), '1,234,567');
      expect(tailoringNumber(null), '');
      expect(tailoringNumber(0), '0');
      expect(tailoringNumber(-2500.5, decimals: 2), '-2,500.50');
    });

    test('joins only non-empty parts', () {
      expect(tailoringJoin([null, '', 'أ', '  ', 'ب']), 'أ · ب');
      expect(tailoringJoin([null, '']), '');
      expect(tailoringJoin(['أ', 'ب'], separator: ' — '), 'أ — ب');
    });
  });

  // ================================================================
  // صف قائمة الفواتير والمفتاح المركّب
  // ================================================================
  group('CuttingBillSummary', () {
    test('parses an Oracle row with upper-case keys and string numbers', () {
      final row = CuttingBillSummary.fromJson(<String, dynamic>{
        'BILL_NO': '12345',
        'YEAR': '2026',
        'MANUAL_BILL_NO': '778',
        'DATE': '11/03/2026',
        'RAW_DATE': '2026-03-11T00:00:00Z',
        'CUST_NO': '4102',
        'CUST_NAME': '\u00E3\u00CD\u00E3\u00CF',
        'TEL_NO1': '777123456',
        'MODELS_COUNT': '2',
        'PIECES_COUNT': '5',
        'TOTAL': '1500',
        'DISCOUNT': '0',
        'NET': '1500',
        'HANDING_DONE': '0',
        'ORDSDID': '3',
      });

      expect(row.billNo, 12345);
      expect(row.year, 2026);
      expect(row.manualBillNo, 778);
      expect(row.date, '11/03/2026');
      expect(row.custName, 'محمد');
      expect(row.telNo1, '777123456');
      expect(row.modelsCount, 2);
      expect(row.piecesCount, 5);
      expect(row.ordsdid, 3);
      expect(row.isDelivered, isFalse);
      expect(row.referenceLabel, '12345 / 2026');
      expect(row.manualLabel, '778');
      expect(row.netLabel, '1,500');
    });

    test('falls back to dashes when the optional parts are missing', () {
      final row = CuttingBillSummary.fromJson(<String, dynamic>{
        'bill_no': 9,
        'year': 2026,
        'net': '0',
      });

      expect(row.manualLabel, '—');
      expect(row.custName, '');
      expect(row.isDelivered, isFalse);
      expect(row.netLabel, '0');
    });

    test('the composite key is the identity, not the number alone', () {
      const a = CuttingBillKey(billNo: 12345, year: 2026);
      const b = CuttingBillKey(billNo: 12345, year: 2026);
      const otherYear = CuttingBillKey(billNo: 12345, year: 2025);

      // الرقم وحده يتكرر بين السنوات، فالمفتاح لا يساوي نظيره في سنة أخرى
      // The number repeats across years, so the key must not equal another year's.
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == otherYear, isFalse);
      expect(a.id, '12345/2026');
      expect('$a', '12345/2026');
    });

    test('a page knows whether more rows are waiting', () {
      const first = CuttingBillPage(page: 1, pages: 3, total: 55, limit: 20);
      const last = CuttingBillPage(page: 3, pages: 3, total: 55, limit: 20);

      expect(first.hasMore, isTrue);
      expect(last.hasMore, isFalse);
      expect(const CuttingBillPage().hasMore, isFalse);
      expect(const CuttingBillPage().limit, 50);
    });
  });

  // ================================================================
  // الدفع: الرصيد السالب دفعة مقدمة
  // ================================================================
  group('CuttingBillPayment', () {
    // السلوك الحالي المتعمَّد: الرصيد السالب يُصنَّف دفعة مقدمة عبر isAdvance، لكن تسمية
    // الرصيد تظل «المتبقي» والقيمة تُعرض مطلقة. (لا فرع «رصيد مقدم» في balanceLabel الآن.)
    // Current intended behaviour: a negative balance is still flagged by isAdvance, but the
    // balance label stays «المتبقي» and the value shows absolute (no advance branch now).
    test('a negative balance is flagged as an advance but keeps the due label', () {
      const payment = CuttingBillPayment(
        total: 1500,
        paid: 2000,
        remaining: -500,
      );

      expect(payment.isAdvance, isTrue);
      expect(payment.balanceLabel, 'المتبقي');
      // القيمة تُعرض مطلقة
      expect(payment.balanceValue, '500');
    });

    test('zero balance is settled and a positive one is due', () {
      expect(const CuttingBillPayment(remaining: 0).balanceLabel, 'مسدَّد بالكامل');
      expect(const CuttingBillPayment(remaining: 120).balanceLabel, 'المتبقي');
      expect(const CuttingBillPayment().balanceLabel, '—');
    });

    // السلوك الحالي المتعمَّد: paidTotal = المدفوع فقط، والمدفوعات الأخرى لا تُضمّ.
    // Current intended behaviour: paidTotal is the paid amount alone; other payments are not added.
    test('paid total is the paid amount and excludes other payments', () {
      const payment = CuttingBillPayment(paid: 500, othersPayments: 250);
      expect(payment.paidTotal, 500);
    });

    test('settlement label joins the method with the voucher number', () {
      const payment = CuttingBillPayment(
        paymentMethod: 'نقداً',
        voucherNo: '9001',
      );

      expect(payment.settlementLabel, 'نقداً · سند 9001');
      expect(const CuttingBillPayment(paymentMethod: 'نقداً').settlementLabel,
          'نقداً');
    });
  });

  // ================================================================
  // تفصيل الفاتورة: الترويسة والموديلات
  // ================================================================
  group('CuttingBillDetail', () {
    test('a null payment is a server-side block, not missing data', () {
      final detail = CuttingBillDetail.fromJson(<String, dynamic>{
        'header': {'bill_no': 12345, 'year': 2026},
        'payment': null,
        'models': const [],
        'measure_labels': const {'L1': 'الطول', 'L2': null},
      });

      expect(detail.hasPaymentDetails, isFalse);
      expect(detail.models, isEmpty);
      expect(detail.firstModel, isNull);
      expect(detail.piecesCount, 0);
      // التسمية الفارغة تُسقط، والمقياس بلا تسمية يعود إلى مفتاحه
      expect(detail.measureLabels.keys, ['L1']);
      expect(detail.labelFor('L1'), 'الطول');
      expect(detail.labelFor('L9'), 'L9');
    });

    test('groups pieces under their model and labels the header', () {
      final detail = CuttingBillDetail.fromJson(_detailJson());

      expect(detail.header.billNo, 12345);
      expect(detail.header.referenceLabel, '12345 / 2026');
      expect(detail.header.urgencyLabel, 'مستعجل');
      expect(detail.header.delivered, isFalse);

      expect(detail.models, hasLength(2));
      expect(detail.piecesCount, 3);
      expect(detail.models.first.pieces, hasLength(2));
      expect(detail.models.first.movementSeqNos, [5001, 5002]);
      expect(detail.hasPaymentDetails, isTrue);
    });

    test('a model without type or shape still has a readable name', () {
      final detail = CuttingBillDetail.fromJson(_detailJson());
      final plain = detail.models.last;

      expect(plain.displayName, 'قميص · كلاسيكي');
      expect(
        const CuttingModelItem(seqNo: 4).displayName,
        'موديل 4',
        reason: 'بلا نوع ولا شكل يبقى رقم الموديل هو الاسم / '
            'with no type or shape the number is the name',
      );
    });
  });

  // ================================================================
  // المقاسات والقطع
  // ================================================================
  group('CuttingModelItem', () {
    test('reads L1..L12 from the nested object', () {
      final model = CuttingModelItem.fromJson(<String, dynamic>{
        'seq_no': '1',
        'measurements': {'L1': '58', 'L2': 42.5, 'L12': '104'},
      });

      expect(model.measurements['L1'], 58.0);
      expect(model.measurements['L2'], 42.5);
      expect(model.measurements['L12'], 104.0);
      // غير المسجّل لا يُخزَّن كصفر مضلّل
      expect(model.measurements.containsKey('L3'), isFalse);
      expect(model.filledMeasurementsCount, 3);
    });

    test('falls back to the root map when measurements are not nested', () {
      final model = CuttingModelItem.fromJson(<String, dynamic>{
        'seq_no': 1,
        'l1': '60',
      });

      expect(model.measurements['L1'], 60.0);
    });

    test('the model stage is the lowest of its pieces', () {
      final model = CuttingModelItem.fromJson(<String, dynamic>{
        'seq_no': 1,
        'pieces': [
          {'seq_no1': 1, 'cutting_done': 1, 'tailor_done': 1, 'handing_done': 1},
          {'seq_no1': 2, 'cutting_done': 1, 'tailor_done': 0, 'handing_done': 0},
        ],
      });

      // الموديل لا يُسلَّم قبل آخر قطعة
      expect(model.pieces.first.stage, CuttingPieceStage.delivered);
      expect(model.pieces.last.stage, CuttingPieceStage.cut);
      expect(model.stage, CuttingPieceStage.cut);
      expect(model.piecesCount, 2);
    });

    test('an empty piece list is waiting, not delivered', () {
      const model = CuttingModelItem(seqNo: 1);

      expect(model.stage, CuttingPieceStage.waiting);
      expect(model.piecesCount, 0);
      expect(model.movementSeqNos, isEmpty);
    });

    test('specs expose chips and numeric codes only when present', () {
      final model = CuttingModelItem.fromJson(<String, dynamic>{
        'seq_no': 1,
        'neck_type': 'كلاسيك',
        'neck_shape_no': '12',
        'notes': 'ملاحظة',
      });

      final labels = model.specs.textChips.map((c) => c.$1).toList();
      final codes = model.specs.numericCodes.map((c) => c.$1).toList();

      // المواصفات تُسمّى بوصفها خصائص قطعة: نوع الرقبة، نوع الأزرار…
      // Specs are named as garment properties: neck type, button type…
      expect(labels, ['نوع الرقبة']);
      expect(codes, ['نموذج الرقبة']);
      expect(model.specs.notes, 'ملاحظة');
      expect(model.specs.isEmpty, isFalse);
      expect(const CuttingModelSpecs().isEmpty, isTrue);
    });

    // شكل الخادم الحقيقي: المواصفات معشّنة داخل `specs`، لا مسطّحة في جذر الموديل.
    // The real server shape: specs nested under `specs`, not flat on the model root.
    test('specs are read from the nested server map, not the model root', () {
      final model = CuttingModelItem.fromJson(<String, dynamic>{
        'seq_no': 85226,
        'specs': <String, dynamic>{
          'neck_type': 'كلاسيك',
          'notes': 'ملاحظة الموديل من VIEW',
        },
      });

      expect(model.specs.notes, 'ملاحظة الموديل من VIEW');
      expect(model.specs.neckType, 'كلاسيك');
      expect(model.specs.textChips.map((c) => c.$1).toList(), ['نوع الرقبة']);
    });
  });

  group('CuttingPieceItem', () {
    test('the unassigned tailor has no name, and the stage follows the flags',
        () {
      final piece = CuttingPieceItem.fromJson(<String, dynamic>{
        'seq_no1': '5001',
        'cloth_name': '\u00E3\u00CD\u00E3\u00CF',
        'color_text': 'أزرق',
        'tailor_name': null,
        'cutting_done': '1',
      });

      expect(piece.seqNo1, 5001);
      expect(piece.clothName, 'محمد');
      expect(piece.hasTailor, isFalse);
      expect(piece.stage, CuttingPieceStage.cut);
      expect(piece.label, 'محمد — أزرق');
      expect(const CuttingPieceItem(seqNo1: 3).label, 'قطعة 3');
    });

    test('reads the fabric source and the piece price', () {
      final local = CuttingPieceItem.fromJson(<String, dynamic>{
        'seq_no1': 1,
        'from_local_store': 1,
        'price': '750.5',
      });
      final own = CuttingPieceItem.fromJson(<String, dynamic>{
        'seq_no1': 2,
        'our_selection': 1,
      });

      expect(local.sourceLabel, 'مخزن محلي');
      expect(own.sourceLabel, 'اختيار المعرض');
      expect(local.price, 750.5);
      expect(local.sourceLabel, isNotEmpty);
    });
  });

  // ================================================================
  // سجل الحركة
  // ================================================================
  group('CuttingMovement', () {
    test('reads the stage name, its code fallback and posting state', () {
      final named = CuttingMovement.fromJson(<String, dynamic>{
        'date': '12/03/2026',
        'ordsid': '4',
        'ords_name': 'تم القص',
        'dept_name': 'قسم القص',
        'qty': '2',
        'posted': '1',
      });
      final unnamed = CuttingMovement.fromJson(<String, dynamic>{'ordsid': 5});

      expect(named.stageLabel, 'تم القص');
      expect(named.postedLabel, 'مُرحَّل');
      expect(named.date, '12/03/2026');
      expect(named.quantityLabel, 'العدد 2');
      expect(unnamed.stageLabel, 'حالة 5');
      expect(unnamed.postedLabel, 'غير مُرحَّل');
      expect(const CuttingMovement().stageLabel, '—');
      expect(const CuttingMovement().quantityLabel, '');
    });
  });

  // ================================================================
  // المرجعيات
  // ================================================================
  group('TailoringReference', () {
    test('drops inactive types and shapes without a name', () {
      final reference = TailoringReference.fromJson(<String, dynamic>{
        'measure_labels': {'L1': 'الطول', 'L3': null},
        'types': [
          {'type_no': 1, 'type_name': 'قميص', 'active': '1'},
          {'type_no': 2, 'type_name': 'بنطال', 'active': '0'},
          {'type_no': 3, 'type_name': null},
        ],
        'styles': [
          {'shape_style_no': 11, 'style_name': 'كلاسيكي', 'type_no': 1},
          {'shape_style_no': 12, 'style_name': 'رياضي', 'type_no': 2},
          {'shape_style_no': 13, 'style_name': null, 'type_no': 1},
        ],
        'stages': [
          {'ordsid': 3, 'ordsname': 'تم القص'},
          {'ordsid': 1, 'ordsname': 'تسليم للقص'},
          {'ordsid': 9, 'ordsname': 'معطّلة', 'active': '0'},
        ],
      });

      expect(reference.activeTypes.map((t) => t.typeNo), [1]);
      expect(reference.stylesForType(1), hasLength(1));
      expect(reference.stylesForType(null), hasLength(2));
      // الحالات مرتّبة برقمها لتغذية خط السير
      expect(reference.activeStages.map((s) => s.ordsid), [1, 3]);
      expect(reference.labelFor('L1'), 'الطول');
      expect(reference.labelFor('L3'), 'L3');
      expect(TailoringReference.empty.measureLabels, isEmpty);
    });
  });
}

/// فاتورة كاملة من صفوف الـ VIEW: موديلان، الأول بقطعتين
/// A whole bill out of view rows: two models, the first with two pieces.
Map<String, dynamic> _detailJson() => <String, dynamic>{
      'header': {
        'bill_no': '12345',
        'year': '2026',
        'manual_bill_no': '778',
        'date': '11/03/2026',
        'cust_no': '4102',
        'cust_name': '\u00E3\u00CD\u00E3\u00CF',
        'tel_no1': '777123456',
        'urgent': '1',
        'branch_no': '2',
        'ordsdid': '3',
        'ords_name': 'تسليم للخياط',
        'handing_done': '0',
        'models_count': '2',
        'pieces_count': '3',
      },
      'payment': {
        'total': '1500',
        'discount': '0',
        'net': '1500',
        'paid': '500',
        'remaining': '1000',
      },
      'models': [
        {
          'seq_no': '1',
          'beneficiary': '\u00E3\u00CD\u00E3\u00CF',
          'type_name': 'قميص',
          'shape_name': 'كلاسيكي',
          'qty': '2',
          'measurements': {'L1': '58', 'L2': '42'},
          'neck_type': 'كلاسيك',
          'pieces': [
            {
              'seq_no1': '5001',
              'cloth_name': '\u00E3\u00CD\u00E3\u00CF',
              'tailor_name': null,
              'cutting_done': '1',
              'tailor_done': '1',
            },
            {
              'seq_no1': '5002',
              'cloth_name': 'صوف',
              'tailor_name': 'خالد',
              'cutting_done': '1',
              'tailor_done': '0',
            },
          ],
        },
        {
          'seq_no': '2',
          'beneficiary': 'سالم',
          'type_name': 'قميص',
          'shape_name': 'كلاسيكي',
          'measurements': {'L1': '61'},
          'pieces': [
            {'seq_no1': '5003', 'cutting_done': '0'},
          ],
        },
      ],
      'measure_labels': {'L1': 'الطول', 'L2': 'الكتف'},
    };
