import 'package:flutter_test/flutter_test.dart';
import 'package:ky_apps/features/stores/data/models/store_model.dart';
import 'package:ky_apps/features/stores/data/models/store_reference.dart';

/// اختبارات قراءة حزمة المراجع — عطل حقيقي كان يُفرغ قائمة الأصناف
/// Reference bundle parsing tests — a real defect that emptied the items list.
///
/// ── العطل: منتقي OCI8 يعيد أسماء الأعمدة صغيرة (`group_no`)، والنماذج كانت تقرأ `GROUP_NO`
///    فقط. النتيجة أن كل مجموعة تُقرأ `0`، وكل مجموعة فرعية `0`، فتُطلب أصناف المجموعة صفر
///    فتأتي القائمة فارغة — ثم تُبنى القائمة المنسدلة بعناصر متطابقة القيمة فينهار
///    `DropdownButtonFormField` على `assert`.
/// ── The defect: the OCI8 driver returns lowercase column names (`group_no`) while the models
///    read `GROUP_NO` only. Every group therefore parsed as 0 and every sub group as 0, so the
///    app requested items of group zero — an empty list — and the dropdown was built from
///    duplicate values, tripping DropdownButtonFormField's assert.
void main() {
  /// الحمولة الحقيقية كما وصلت من الخادم (مفاتيح صغيرة) — مقتطف من السجل
  /// The real payload as it arrived from the server (lowercase keys) — a snippet from the log.
  final lowercasePayload = <String, dynamic>{
    'stores': [
      {'store_no': '1', 'store_name': 'المحل الرئيسي', 'keepers': '0'},
      {'store_no': '2', 'store_name': 'مخزن قبرص', 'keepers': '0'},
    ],
    'groups': [
      {'group_no': '1', 'group_name': 'الاقمشة والمواد الخام'},
      {'group_no': '2', 'group_name': 'ثياب جاهزة'},
    ],
    'types': [
      {'type_no': '101', 'type_name': 'الاقمشة', 'group_no': '1'},
      {'type_no': '201', 'type_name': 'ثياب رجالي', 'group_no': '2'},
    ],
    'categories': [
      {'seq': '4', 'cat_no': '4', 'category': 'صيني'},
    ],
    'units': [
      {'unit_no': '3', 'unit_name': 'ثوب'},
    ],
    'styles': [
      {
        'id': '10101',
        'name': 'قماش عرض 58',
        'code': 'A1',
        'group_no': '1',
        'type_no': '101',
      },
    ],
    'excluded_stores': [2, 11, 12],
  };

  test('lowercase server keys still parse into real identifiers', () {
    final reference = StoreReference.fromJson(lowercasePayload);

    // الأرقام يجب أن تكون حقيقية لا أصفاراً
    // The identifiers must be real numbers, never zeros.
    expect(reference.groups.map((group) => group.groupNo), [1, 2]);
    expect(reference.groups.first.groupName, 'الاقمشة والمواد الخام');
    expect(reference.types.map((type) => type.typeNo), [101, 201]);
    expect(reference.types.first.typeName, 'الاقمشة');
    expect(reference.types.first.groupNo, 1);
    expect(reference.categories.single.id, 4);
    expect(reference.categories.single.name, 'صيني');
    expect(reference.units.single.unitNo, 3);
    expect(reference.units.single.unitName, 'ثوب');
    expect(reference.styles.single.id, 10101);
    expect(reference.styles.single.typeNo, 101);
  });

  test('the first group resolves its own sub groups', () {
    final reference = StoreReference.fromJson(lowercasePayload);

    // هذا هو ما يبنيه `applyDefaults`: أول مجموعة ← أول فرعية تابعة لها
    // This is what applyDefaults builds: the first group, then its first sub group.
    final group = reference.groups.first;
    final types = reference.typesOfGroup(group.groupNo);

    expect(types, hasLength(1));
    expect(types.first.typeNo, 101);
    expect(types.first.groupNo, group.groupNo);
  });

  test('uppercase keys keep working unchanged', () {
    // الخادم صار يُطبّع المفاتيح، لكن القارئ يبقى مزدوج الحالة كشبكة أمان
    // The server now normalises keys, but the reader stays dual-case as a safety net.
    final reference = StoreReference.fromJson({
      'groups': [
        {'GROUP_NO': '7', 'GROUP_NAME': 'مواد ومستلزمات اخرى'},
      ],
      'types': [
        {'TYPE_NO': '701', 'TYPE_NAME': 'مواد', 'GROUP_NO': '7'},
      ],
      'units': [
        {'UNIT_NO': '5', 'UNIT_NAME': 'كيلو'},
      ],
    });

    expect(reference.groups.single.groupNo, 7);
    expect(reference.groups.single.groupName, 'مواد ومستلزمات اخرى');
    expect(reference.types.single.typeNo, 701);
    expect(reference.units.single.unitNo, 5);
  });

  test('an archived store is flagged when the server marks it', () {
    final stores = StoreReference.fromJson({
      'stores': [
        {
          'STORE_NO': '2',
          'STORE_NAME': 'مخزن قبرص',
          'KEEPERS': '0',
          'ARCHIVED': '1',
        },
      ],
    });

    final store = stores.stores.single;

    expect(store.storeNo, 2);
    expect(store.archived, isTrue);
    expect(store.acceptsDocuments, isFalse);
    expect(stores.usableStores, isEmpty);
  });

  test('a store row without the archived flag stays usable', () {
    const store = StoreModel(storeNo: 1, storeName: 'المحل الرئيسي');

    expect(store.archived, isFalse);
    expect(store.acceptsDocuments, isTrue);
  });
}
