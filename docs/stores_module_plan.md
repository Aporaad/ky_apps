# قسم المخازن — خطة تنفيذ متكاملة

> **حالة الخطة:** معتمدة للتنفيذ (بعد تعديلين بناءً على قرار المستخدم: بلا أي جدول جديد، والجرد بلا حفظ).
> **المخطط:** Flutter client (`lib/`) ← Laravel 12 (`kyApp_API/`) ← Oracle 11g (`ACCOUNTS`).

## 1. الملخص

بناء قسم المخازن كاملاً (8 وحدات فرعية) فوق **جداول Oracle القديمة نفسها**، لأن رصيد المخزون في `ACCOUNTS.AVVG` محسوب آلياً من مستندات الحركة، فأي كتابة في `INVENTORY_RECEIVE` / `INVENTORY_SARF` / `INVENTORY_TRANSM` تنعكس على الكميات فوراً وتظهر في النظام المكتبي.

النتيجة: `lib/features/stores/` جديد (شاشات + مزودات + مستودعات)، و`kyApp_API` بـ 8 متحكمات جديدة و‎26 كود صلاحية. **لا يُنشأ أي جدول جديد ولا يُعدَّل أي جدول قائم** — الكائنات الجديدة الوحيدة هي تسلسلات ترقيم (13 `SEQUENCE`)، والجرد يعمل ككشف عدّ حيّ بلا حفظ (D9).

## 2. حقائق المخطط المكتشفة (تحقّقت حياً عبر موصل `oracledb`)

```
ACCOUNTS.ITEM_MOVE_D      = VIEW  (UNION ALL على كل جداول المستندات)
        └→ ITEM_MOVEMENT_D = VIEW  (يعيد التسمية، يستثني المخازن 2, 11, 12)
                ├→ LAST_COST = VIEW (تكلفة آخر شراء، bill_doc_type = 0)
                └→ AVVG      = VIEW (رصيد صنف × مخزن)
```

| الكائن | الدور في الواجهة | حقائق القيد |
|---|---|---|
| `STORES` (6 صفوف) | المخازن | PK `STORE_NO`، UQ `STORE_NAME`. المخازن **2/11/12 مستثناة من الرصيد** |
| `STORE_EMP` (فارغ) | أمناء المخازن | PK `EMP_NO`(!)، UQ `EMP_NAME`، FK→`STORES` |
| `GROUP1` (9) | المجموعة الرئيسية | PK `GROUP_NO`، UQ `GROUP_NAME` |
| `TYPES` (27) | المجموعة الفرعية | PK `TYPE_NO`، FK `GROUP_NO`، `TYPE_CODE` |
| `CATEGORY` (19) | الفئة (بلد المنشأ) | PK `SEQ`، UQ `CATEGORY`، و`SANFS.CAT_NO` يشير إلى `CATEGORY.CAT_NO` |
| `UNITS` (11) | الوحدة | PK `UNIT_NO`، UQ `UNIT_NAME` |
| `SANFS` (2,183) | **الصنف الرئيسي** | PK `SANF_NO`، **UQ `SANF_NAME`**، **UQ `PART_NO`** |
| `SANFS_D` (9,005) | **الصنف الفرعي** (باركود/لون/مقاس) | PK `SANF_DNO` (حتى `101010001013`)، UQ(`SANF_NO`,`WID`,`LEN`,`COLOR_NO`,`ACTIVE`) |
| `PARTIAL_SANFS` (2,187) | وحدات الصنف وأسعاره | PK(`SANF_NO`,`CAP`)، UQ `SEQ_NO` |
| `INVENTORY_RECEIVE(_DETAILES)` (980/15,740) | أوامر التوريد | UQ(`BILL_NO`,`YEAR`) |
| `INVENTORY_SARF(_DETAILES)` (527/3,769) | أوامر الصرف | UQ(`BILL_NO`,`YEAR`) |
| `INVENTORY_TRANSM` / `_TRANSD` (269/1,944) | أوامر التحويل | PK `TR_INV_M_ID` / `TR_INV_D_ID`. **`TYPENO=4` وارد، `TYPENO=5` منصرف** |
| `TRANS_TYPE` (17) | أنواع الحركة | `TYPE_NO`,`TR_TYPE_ID`,`TYPE_NAME`,`INOUT` |
| `AVVG` (2,856 صفاً / 3 مخازن) | الأرصدة | `SUM_TP`=الكمية، `STK_COST`=تكلفة الوحدة، `SALES_PRICE`، `SUM_PRICE`=القيمة، + GROUP/TYPE/STYLE/CAT |

**مصائد يجب احترامها (مثبتة بالفحص):**

1. **الرصيد ليس جدولاً**: `AVVG.SUM_TP = ROUND(SUM(p_qty))`، والإشارة تُحدَّد داخل الـ VIEW (توريد `+`، صرف `−`، تحويل وارد `+`، تحويل منصرف `−`). لا يوجد جدول أرصدة نكتب فيه أبداً.
2. **`FLAG_CANCEL` مُهمَل تماماً** في `ITEM_MOVE_D` — مستند مُلغى يظل يؤثر في الرصيد. لذلك **إلغاء/حذف أمر = حذف فيزيائي للصفوف** داخل معاملة.
3. **فرع التحويل في الـ VIEW** يربط بـ `INVENTORY_TRANSD.SIZE_FRM = SANFS_D.LEN` و`SIZE_TO = SANFS_D.WID`. إغفال النسخ يجعل التحويل **لا يظهر إطلاقاً** في الأرصدة.
4. **فرعا التوريد/الصرف** يشترطان `SANF_DNO` موجوداً ومطابقاً لـ `SANFS_D.SANF_DNO` — لا سطر بلا صنف فرعي.
5. `ITEM_MOVEMENT_D` يستثني المخازن 2/11/12 ⇒ لا رصيد لها. المخزن الجديد (13+) يعمل تلقائياً.
6. لا تسلسلات للمستندات ولا للأصناف ⇒ ننشئها، ونقطة البداية من `MAX+1` المقاس: RCV 535 · SARF 301 · TRM 265,471 · TRD 2,641,710,001 · SANF 2,183 · SANF_DNO 1,010,100,010,013.
7. العربية تُخزَّن بايتات CP1256 ⇒ كل كتابة عربية (`SANF_NAME`, `STORE_NAME`, `NOTE`…) تمرّ بـ`ArabicEncoding::toOracleSearchChars`، وكل قراءة بـ`ArabicEncoding::cleanData` ثم `ArabicEncodingUtils.fix` في العميل.
8. `GARD`/`GARD_DETAILES` = الجرد القديم، و`GARD_TYPE=6` **يُحتسب كحركة في `ITEM_MOVE_D`** ⇒ الكتابة فيه تُضاعف الرصيد لو تكرر. لذلك لا نكتب فيه إطلاقاً.

## 3. القرارات الحاكمة

| # | القرار | المبرر |
|---|---|---|
| D1 | الكتابة في جداول النظام القديم داخل `DB::connection('oracle')->transaction()` واحدة لكل مستند | الكميات تتحدث فوراً ويظهر الأمر في البرنامج المكتبي |
| D2 | أرقام المستندات من تسلسلات أوراكل جديدة (`SEQ_STORES_*`)، و`YEAR = TO_CHAR(SYSDATE,'YYYY')` | لا يوجد توليد مركزي؛ التسلسل آمن تحت التزامن؛ الوقت من ساعة أوراكل لا من PHP (توقيت التطبيق UTC) |
| D3 | الحذف **فيزيائي** مع تسجيل نسخة تدقيق قبل الحذف (`APP_USER_ACTIVITY` برقم المستند والمخزن والصافي وعدد السطور) | `FLAG_CANCEL` لا يوقف الأثر على الرصيد (مصيدة #2) |
| D4 | التعديل = استبدال ذري للتفاصيل (حذف + إعادة إدراج) والمجاميع تُحسب على الخادم | لا يُقبل أي مبلغ من العميل؛ الرصيد يُعاد اشتقاقه من الصفوف |
| D5 | التحويل = **مستندان** في معاملة واحدة: `TYPENO=5` صرف من المصدر + `TYPENO=4` توريد للهدف، مع نسخ `LEN/WID` إلى `SIZE_FRM/SIZE_TO` | مطابقة لبنية الـ VIEW ولنمط بيانات النظام الحالية (142 وارد / 144 منصرف) |
| D6 | رفض إنشاء/تعديل أمر على مخزن 2/11/12 بـ422، وعرضها في الشاشات بوسم «أرشيفي» | مستثناة من `ITEM_MOVEMENT_D` |
| D7 | منع الرصيد السالب افتراضياً: الخادم يرفض 422 ويعيد السطور المخالفة مع المتاح؛ التجاوز يحتاج `stores.*` + `allow_negative=true` | 41 رصيداً سالباً حالياً؛ الحماية أهم من المرونة الافتراضية |
| D8 | حذف الصنف ممنوع إن كان له حركة أو أصناف فرعية؛ البديل تعطيل `ACTIVE=0` | يحفظ سلامة المستندات التاريخية |
| D9 | الجرد = **كشف عدّ حيّ** يقارن رصيد النظام (`AVVG`) بالكمية الفعلية داخل الشاشة، قابل للطباعة والتصدير، **بلا حفظ جلسات وبلا أي ترحيل أو أثر على الأرصدة** (قرار المستخدم) | لا جداول جديدة، والكتابة في `GARD` مرفوضة لأن `GARD_TYPE=6` يُحتسب في `ITEM_MOVE_D` فيُضاعف الرصيد لو تكرر |
| D10 | التقارير من `ITEM_MOVEMENT_D` حصراً، بمدى أقصى سنتان | مصدر واحد للأسماء (صنف/مجموعة/نوع/وحدة) ومطابقة تامة لـ AVVG |
| D11 | لا `build_runner`، ولا حزم جديدة، ولا `freezed` | قواعد المشروع |
| D12 | أكواد الصلاحيات تُضاف في الخادم والمرآة في نفس التغيير | يُفرض باختبار `test/ibac_test.dart` |
| D13 | **لا `CREATE TABLE` ولا `ALTER TABLE` إطلاقاً** — الكائنات الجديدة الوحيدة `SEQUENCE` للترقيم | قرار المستخدم؛ يحفظ المخطط القديم كما هو ويمنع أي انحراف بين النظامين |

## 4. قاعدة البيانات — تسلسلات فقط، بلا أي جدول جديد

ملف جديد: `kyApp_API/database/oracle/04_stores_sequences.sql` (idempotent: يتخطى كل تسلسل موجود).

**ما لا يُفعَل هنا:** لا `CREATE TABLE`، ولا `ALTER TABLE`، ولا فهرس جديد، ولا كتابة في `GARD`/`GARD_DETAILES`. كل البيانات في الجداول القائمة، وكل أرصدة المخزون تُشتق من الـ VIEWs.

```sql
-- تسلسلات المستندات والأصناف (نقطة البداية = MAX+1 المقاس)
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_RCV       START WITH 536          INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_ISS       START WITH 302          INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_TRNM      START WITH 265472       INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_TRND      START WITH 2641710002   INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_ITEM      START WITH 2184         INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_ITEM_D    START WITH 101010001014 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_PSANF     START WITH 2188         INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_STORE     START WITH 13           INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_GROUP     START WITH 10           INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_TYPE      START WITH 28           INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_UNIT      START WITH 12           INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_CAT       START WITH 19           INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE ACCOUNTS.SEQ_STORES_KEEPER    START WITH 1            INCREMENT BY 1 NOCACHE;

-- لا CREATE TABLE إطلاقاً (D13): الجرد كشف عدّ حيّ بلا حفظ، والأرصدة من AVVG.
-- No CREATE TABLE at all: the stocktake is a live counting sheet and balances come from AVVG.
```

تُوثَّق كل عبارة أعلاه (مع نتائجها) في `db_commends.md`، ومخططها في `DBdevloping_history.md` وفق قاعدة السجل الإضافي (append-only) — **تسلسلات فقط، ولا جدول واحد**.

## 5. الخادم — `kyApp_API`

### 5.1 الملفات الجديدة

```
app/Support/StorePolicy.php              # المخازن المستثناة، خرائط أنواع المستندات، أرقام المستندات
app/Support/InventoryLineGuard.php       # تحقق السطور: صنف فرعي موجود، وحدة، كمية، رصيد كافٍ
app/Http/Controllers/Stores/StoreController.php
app/Http/Controllers/Stores/StoreCatalogController.php     # المجموعات/الفرعية/الفئات/الوحدات
app/Http/Controllers/Stores/StoreItemController.php        # الأصناف + الفرعية + الوحدات والأسعار
app/Http/Controllers/Stores/StoreOrderController.php       # أساس مشترك (قائمة/عرض/حذف/ترقيم)
app/Http/Controllers/Stores/ReceiveOrderController.php
app/Http/Controllers/Stores/IssueOrderController.php
app/Http/Controllers/Stores/TransferOrderController.php
app/Http/Controllers/Stores/StoreReportController.php      # reference · movement · summary · balances
app/Http/Controllers/Stores/StockSheetController.php       # كشف العدّ الحيّ (بلا حفظ)
```

### 5.2 `StorePolicy` — القيم المرجعية

```php
public const NON_STOCK_STORES = [2, 11, 12];        // مطابق لـ ITEM_MOVEMENT_D
public const DOC_RECEIVE  = ['table' => 'INVENTORY_RECEIVE',  'details' => 'INVENTORY_RECEIVE_DETAILES', 'typeno' => 12, 'seq' => 'SEQ_STORES_RCV'];
public const DOC_ISSUE    = ['table' => 'INVENTORY_SARF',     'details' => 'INVENTORY_SARF_DETAILES',    'typeno' => 13, 'seq' => 'SEQ_STORES_ISS'];
public const DOC_TRANSFER = ['table' => 'INVENTORY_TRANSM',   'details' => 'INVENTORY_TRANSD',           'typeno' => 4,  'seq' => 'SEQ_STORES_TRNM'];
```

### 5.3 المسارات (تُضاف في `routes/api.php`، كل مسار بصلاحيته)

```php
// المخازن والأمناء
GET    /stores                              permission:stores.view          → StoreController@index (مع الأرصدة المجمّعة)
POST   /stores                              permission:stores.create
PUT    /stores/{storeNo}                    permission:stores.update
DELETE /stores/{storeNo}                    permission:stores.delete
GET    /stores/keepers                      permission:stores.keepers_view
POST   /stores/keepers                      permission:stores.keepers_manage
PUT    /stores/keepers/{empNo}              permission:stores.keepers_manage
DELETE /stores/keepers/{empNo}              permission:stores.keepers_manage

// المرجعيات (قوائم منسدلة + إدارة)
GET    /stores/reference                    permission:stores.view          → مخازن · مجموعات/فرعية · فئات · وحدات · أنواع حركة
GET|POST|PUT|DELETE /stores/catalogs/{kind} permission:stores.catalogs_view|stores.catalogs_manage  (kind = groups|types|categories|units)

// الأصناف
GET    /stores/items                        permission:stores.items_view    → قائمة الأصناف الرئيسية (بحث/فرز/تصفية/ترقيم)
GET    /stores/items/{sanfNo}               permission:stores.items_view    → تفصيل + فرعية + وحدات وأسعار + أرصدة
POST   /stores/items                        permission:stores.items_create
PUT    /stores/items/{sanfNo}               permission:stores.items_update
DELETE /stores/items/{sanfNo}               permission:stores.items_delete
POST   /stores/items/{sanfNo}/sub           permission:stores.items_create  → إضافة صنف فرعي (باركود/لون/مقاس)
PUT    /stores/items/{sanfNo}/sub/{sanfDno} permission:stores.items_update
DELETE /stores/items/{sanfNo}/sub/{sanfDno} permission:stores.items_delete
POST   /stores/items/{sanfNo}/units         permission:stores.items_update
GET    /stores/items/{sanfNo}/movements     permission:stores.items_view    → كارت الصنف

// الأوامر (×3: receive | issue | transfer)
GET    /stores/{kind}                       permission:stores.<kind>_view
GET    /stores/{kind}/{no}                  permission:stores.<kind>_view
POST   /stores/{kind}                       permission:stores.<kind>_create
PUT    /stores/{kind}/{no}                  permission:stores.<kind>_update
DELETE /stores/{kind}/{no}                  permission:stores.<kind>_delete

// التقارير والأرصدة
GET    /stores/balances                     permission:stores.reports_view  → من AVVG
GET    /stores/reports/movement             permission:stores.reports_view
GET    /stores/reports/summary              permission:stores.reports_view
POST   /stores/reports/export-log           permission:stores.reports_export

// الجرد — كشف عدّ حيّ فقط، لا حفظ ولا مستند (D9 + D13)
GET    /stores/stock-sheet?store_no=&date=  permission:stores.stocktake_view
       → يرجّع سطور (SANF_NO, PART_NO, ITEM_NAME, UOM_CODE, SUM_TP, STK_COST, VALUE)
         وتُدخل الكميات الفعلية في حالة الشاشة؛ لا نقطة كتابة إطلاقاً.
```

الترتيب مهم: `Route::get('/stores/{kind}')` تُسجَّل **بعد** المسارات الحرفية (`balances`/`reference`/`reports/...`/`stock-sheet`) لتجنّب تعارض المطابقة.

### 5.4 شكل الاستجابة والاصطلاحات

- غلاف `{success, message, data, meta}`، رسائل عربية/إنجليزية.
- ترقيم يدوي `page`/`limit` (افتراضي 100، أقصى 500) و`meta = {total, page, limit, pages}` (نمط `InvoiceController`).
- كل استعلام بحث يبني نسختين من النص عبر `ArabicEncoding::toOracleSearchChars`، وكل قراءة تمرّ `ArabicEncoding::cleanData`.
- كل كتابة/حذف/تعديل يكتب سجلاً في `APP_USER_ACTIVITY` عبر `ActivityLogger->record()` **بعد** نجاح المعاملة (بأكواد: `stores.receiving_created`, `stores.receiving_updated`, `stores.receiving_deleted`, ونظائرها `issuing_*`/`transfer_*`/`items_*`/`catalogs_*`/`keepers_*`). الكشف لا يكتب شيئاً، ويُسجَّل حدثاً واحداً عند الطباعة/التصدير (`stores.stocktake_printed` / `stores.stocktake_exported`).
- `InventoryLineGuard` يتحقق على الخادم من: وجود `SANF_NO` و`SANF_DNO`، تطابقهما، `QTY > 0`، الوحدة موجودة، ومطابقة `SIZE_FRM/SIZE_TO` لـ `LEN/WID` قبل الإدراج في التحويل.

### 5.5 صور الاستعلامات المرجعية

```sql
-- الأرصدة (شاشة المخزون)
SELECT I_CODE, MAX(PART_NO) PART_NO, MAX(ITEM_NAME) ITEM_NAME, MAX(UOM_CODE) UOM_CODE,
       INV_ID, MAX(INVNAME) INVNAME, SUM(SUM_TP) QTY, MAX(STK_COST) COST,
       SUM(SUM_PRICE) VALUE, MAX(GROUPNO) GROUPNO, MAX(GROUP_NAME) GROUP_NAME,
       MAX(TYPE_NO) TYPE_NO, MAX(TYPE_NAME) TYPE_NAME, MAX(CAT) CAT, MAX(CUR_NO) CUR_NO
  FROM ACCOUNTS.AVVG
 GROUP BY I_CODE, INV_ID;

-- عرض الحركة
SELECT m.I_DATE, m.INVOIC_ID DOC_NO, m.TYPE_NO, m.TR_INV_TYPE_NAME TYPE_NAME,
       m.INV_ID, m.INV_NAME, m.I_CODE, m.IT_NAME, m.UOM_CODE,
       CASE WHEN m.P_QTY > 0 THEN m.P_QTY END QTY_IN,
       CASE WHEN m.P_QTY < 0 THEN -m.P_QTY END QTY_OUT,
       m.P_QTY, m.STK_COST, m.P_QTY * m.STK_COST LINE_VALUE
  FROM ACCOUNTS.ITEM_MOVEMENT_D m
 WHERE m.I_DATE BETWEEN :from AND :to
   AND m.INV_ID IN (:stores)            -- الكل أو متعدد
   AND (:grp IS NULL OR m.GROUPNO = :grp)
   AND (:typ IS NULL OR m.TYPE_NO = :typ)
 ORDER BY m.I_DATE, m.INVOIC_ID, m.I_CODE;
```

## 6. الصلاحيات — 26 كوداً جديداً في وحدة `stores`

`PermissionCatalog::MODULES['stores']` (الخادم) + `Perm` و`allPermissionCodes` و`permActionLabels` (العميل):

```php
'core'  => ['view','create','update','delete'],                    // المخازن (كما هي اليوم)
'extra' => [
  'keepers_view' => 'عرض أمناء المخازن',        'keepers_manage' => 'إدارة أمناء المخازن',
  'receiving_view','receiving_create','receiving_update','receiving_delete',
  'issuing_view','issuing_create','issuing_update','issuing_delete',
  'transfer_view','transfer_create','transfer_update','transfer_delete',
  'items_view','items_create','items_update','items_delete',
  'catalogs_view' => 'عرض المجموعات والوحدات والفئات', 'catalogs_manage' => 'إدارة المجموعات والوحدات والفئات',
  'reports_view','reports_print','reports_export',
  'stocktake_view','stocktake_print','stocktake_export',
]
```

- الكتالوج: 147 → **173**، مع `permModuleOrder`/`permModuleLabels` كما هي (وحدة `stores` موجودة) وإضافة تسميات الأفعال المركّبة في `permActionLabels` و`PermissionCatalog::humanize()`.
- التحديث الفعلي: `database/oracle/02_ibac_seed.php` (idempotent) + `PermissionCatalog::count()` في التحقق.
- الحجب في الواجهة عبر `PermissionGate` + `authNotifierProvider.select((a) => a.can(...))`، وفي الخادم عبر `permission:` (الخادم هو الفيصل).

## 7. العميل — `lib/features/stores/`

### 7.1 البنية

```
data/models/       store_model · store_keeper_model · item_model · item_sub_model · item_unit_model
                   group_model · sub_group_model · category_model · unit_model · movement_type_model
                   order_model (أساس: no, year, date, storeNo/To, party, total, discount, net, status, lines)
                   order_line_model · stock_balance_model · movement_row_model · summary_row_model
                   stock_sheet_line_model            (نموذج قراءة فقط — لا نظير محفوظ)
data/repositories/ stores_repository · store_items_repository · store_orders_repository
                   store_reports_repository · stock_sheet_repository
presentation/providers/  stores_providers · items_providers · orders_providers · reports_providers · stock_sheet_providers
presentation/screens/    stores_dashboard_screen
                         stores_list_screen · store_form_screen · store_keepers_screen
                         items_list_screen · item_detail_screen · item_form_screen
                         catalogs_screen
                         receive_orders_screen · receive_order_form_screen · receive_order_view_screen
                         issue_orders_screen · issue_order_form_screen · issue_order_view_screen
                         transfer_orders_screen · transfer_order_form_screen · transfer_order_view_screen
                         stock_balances_screen · store_reports_screen · stock_sheet_screen
presentation/widgets/    item_master_detail_split · item_sub_list · item_units_list · order_line_editor
                         order_totals_bar · document_header_card · store_picker_field · multi_select_chips
                         report_filter_panel · store_report_table · stock_sheet_editor
presentation/utils/      store_report_pdf_builder · store_report_xlsx_builder
                         order_document_pdf_builder · stock_sheet_pdf_builder
```

### 7.2 الاصطلاحات الملزمة

- نماذج يدوية غير قابلة للتعديل: `fromJson` بمفاتيح مزدوجة الحالة (`json['SANF_NO'] ?? json['sanf_no']`)، ومساعدات `_parseInt/_parseDouble/_parseString`، و`copyWith`.
- كل حقل عربي عبر `ArabicEncodingUtils.fix()` (الهاتف والبريد بـ`isArabic: false`).
- `Notifier + NotifierProvider`، حالة أولية + `Future.microtask(() => load())`، `CancelToken` يُلغى عند `dispose`، بحث بـ`debounce 300ms`، حارس `_searchVersion`.
- `dioClientProvider` من `lib/features/auth/presentation/providers/auth_notifier.dart` (لا مزود ثانٍ).
- ثيم `AppColors` فقط، `AppTheme.lightTheme`، `Responsive.isMobile/isTablet/isDesktop`، `withValues(alpha:)`، `MediaQuery.sizeOf`.
- كل شاشة قوائم تعرض الحالات الأربع: تحميل/نجاح/فراغ/خطأ.

### 7.3 الشاشات — التفصيل المطلوب

**أ) لوحة المخازن (`stores_dashboard_screen`)** — عند فتح القسم: 8 بطاقات (أوامر التوريد · أوامر الصرف · أوامر التحويل · المخازن والأمناء · الأصناف · الوحدات والمجموعات · تقارير المخازن · الجرد) + شريط مؤشرات (عدد المخازن، أصناف نشطة، قيمة المخزون من `AVVG`، أصناف برصيد سالب). كل بطاقة محجوبة بصلاحيتها.

**ب) الأوامر الثلاثة (توريد/صرف/تحويل)** — نفس القالب:
- قائمة: `DataListScaffold` + بحث (رقم/طرف/ملاحظة) + فرز (التاريخ/الرقم/الصافي) + تصفية (المخزن، الفترة، الحالة) + **وضع تحديد متعدد** (تحديد الكل/عكس) مع إجراءات جماعية (طباعة/تصدير/حذف بصلاحية).
- كل صف: رقم-سنة، التاريخ، المخزن (والهدف في التحويل)، الطرف، عدد الأصناف، الصافي، شارة حالة، وقائمة إجراءات (عرض · تعديل · حذف) + سحب لأسفل للتحديث.
- نموذج الإنشاء/التعديل: بطاقة ترويسة (المخزن، التاريخ، المورد/العميل/المخزن الهدف، الملاحظة) + محرر سطور (اختيار صنف من منتقي بحث بالكود/الاسم → يظهر الأصناف الفرعية، الوحدة والكمية والسعر والإجمالي، زر حذف سطر) + شريط مجاميع (الإجمالي، الخصم، الصافي) + تحقق فوري (المتاح مقابل المطلوب) + حفظ/إلغاء.
- شاشة العرض: مستند مطبوع (ترويسة الشركة الموحّدة + سطور + مجاميع + توقيعات) مع طباعة/PDF وتصدير.

**ج) المخازن والأمناء** — تبويبان: المخازن (بطاقات: الاسم، الموقع، الملاحظة، الحسابات الأربعة، وسم «أرشيفي»، قيمة المخزون والعدد؛ إجراءات عرض/تعديل/حذف + إضافة مخزن) والأمناء (أمين ↔ مخزن عبر `STORE_EMP`).

**د) الأصناف (الأهم)**
- `items_list_screen`: قائمة **الأصناف الرئيسية** ببحث/فرز (الكود/الاسم/المجموعة) وتصفية (مجموعة رئيسية → فرعية · فئة · وحدة · الحالة) + إجراءات (عرض · تعديل · حذف) بجانب كل صنف + زر «صنف جديد».
- `item_detail_screen`: عند اختيار صنف تُعرض الأصناف **الفرعية** التابعة له (باركود، لون، مقاس، السعر، الحالة) + تفاصيل أخرى في تبويبات: البيانات الأساسية · الوحدات والأسعار (`PARTIAL_SANFS`) · الأرصدة في المخازن (`AVVG`) · الحركة (كارت الصنف).
- تخطيط عريض: قائمة + لوحة تفصيل جنباً إلى جنب (`item_master_detail_split`)؛ على الجوال: انتقال لشاشة التفصيل.
- `item_form_screen`: بيانات الصنف + أول صنف فرعي + أول وحدة/سعر في نموذج واحد (لأن `SANFS` تتطلب `SANF_NAME`/`PART_NO` فريدين و`SANFS_D` مطلوب للمستندات). تحقق مسبق لتفادي انتهاك قيود `SANFS_BRW_U12`/`SANFS_U01`.
- الحذف: ممنوع عند وجود حركة أو أصناف فرعية ⇒ رسالة توجّه للتعطيل (D8).

**هـ) الوحدات والمجموعات** — `catalogs_screen` بثلاثة تبويبات (المجموعات [رئيسية/فرعية شجرية] · الوحدات · الفئات) بإضافة/تعديل/حذف وحماية المرجعية (منع حذف مجموعة لها أنواع أو أصناف).

**و) الأرصدة** — `stock_balances_screen` من `AVVG`: بحث/تصفية (مخزن، مجموعة/فرعية، فئة، «الموجب فقط/السالبي فقط») + مجاميع تذييل + تصدير/طباعة.

**ز) التقارير** — `store_reports_screen`:
1. عند الفتح تُعرض **نافذة تحديد منبثقة** (`report_filter_panel` داخل `showModalBottomSheet`/`showDialog`): نوع التقرير (**عرض حركة** | **خلاصة**)، التاريخ من–إلى، المخازن (الكل/متعدد)، المجموعة الرئيسية → الفرعية، الفئة، الصنف الرئيسي → الفرعي، ونوع الحركة (متعدد، **يظهر في «عرض حركة» فقط**). زر «عرض التقرير» معطّل حتى تصح المدخلات (`من ≤ إلى`).
2. جدول التقرير: أعمدة الحركة (التاريخ · المستند · نوع الحركة · المخزن · الكود · الصنف · الوحدة · وارد · صادر · الرصيد المتحرك · التكلفة · القيمة) أو أعمدة الخلاصة (الصنف · الوحدة · وارد · صادر · الرصيد · متوسط التكلفة · قيمة الرصيد)، مع صفوف مجاميع.
3. أدوات الاستعراض: **تكبير/تصغير** (`ReportZoomView`)، **طباعة** (`Printing.layoutPdf` + `report_pdf_page` + `report_pdf_letterhead`)، **تصدير PDF** و**Excel** (`store_report_xlsx_builder`)، و`LazyReportTable` للصفوف الكبيرة.
4. بوابة: `reports_view` للعرض، `reports_print` للطباعة، `reports_export` للتصدير.

**ح) الجرد (`stock_sheet_screen`) — كشف عدّ بلا حفظ (D9 + D13)**
- اختيار المخزن (الكل/متعدد) وتاريخ العدّ → يُجلب الرصيد من `AVVG` سطراً لكل صنف × مخزن.
- أعمدة: الكود · الصنف · الوحدة · رصيد النظام · **الكمية الفعلية** (حقل إدخال) · الفرق (محسوب) · تكلفة الوحدة · قيمة الفرق · ملاحظة السطر.
- الكمية الفعلية تعيش في **حالة الشاشة فقط** (Notifier محلي) — لا تُرسل ولا تُخزَّن ولا تُنشئ مستنداً؛ تحديث الشاشة يعني إعادة العدّ.
- شريط ملخص: عدد السطور · سطور مُعدَّدة · سطور بفرق · صافي قيمة الفرق.
- تصفية «بفرق فقط / موجب / سالب / غير معدَّد»، وطباعة/تصدير الكشف (PDF + Excel) بترويسة الشركة وتوقيعي أمين المخزن والمراجع.
- تنبيه ثابت أعلى الشاشة: «كشف جرد استرشادي — لا يُرحَّل ولا يغيّر الأرصدة». ولا يوجد زر ترحيل إطلاقاً.

## 8. الاختصارات في الشاشة الرئيسية

في `lib/features/home/domain/home_shortcut_catalog.dart` تُضاف 8 بطاقات بقسم `stores`:
`stores.receiving` · `stores.issuing` · `stores.transfer` · `stores.items` · `stores.catalogs` · `stores.balances` · `stores.reports` · `stores.stocktake` — كل بطاقة بأكوادها الحقيقية (`SectionTarget('stores')` للوحة، و`ScreenTarget(...)` لما يفتح شاشة مباشرة)، و`stores.section` تُحدَّث بحذف `underDevelopment: true`.
تحديثات الاختبارات المرتبطة: `test/home_catalog_test.dart` (عدد البطاقات، قائمة الأقسام الموسومة تصبح `{'sales'}` فقط، عدد الافتراضية 16 → 24 مع بقاء «واحدة مثبّتة»)، وتحديث الـgoldens عند تشغيل `KY_VISUAL=1`.

## 9. الاختبارات وبوابات الجودة

**الخادم (Pest):**
- `tests/Unit/StorePolicyTest.php` — المخازن المستثناة، خرائط الأنواع، حدود التقارير.
- `tests/Feature/StoreOrderWriteTest.php` — معاملة كاملة (إنشاء/تعديل/حذف) داخل `DB::transaction` تُلغى في النهاية، والتحقق من ظهور السطور في `ITEM_MOVEMENT_D` ومن رفض المخزن الأرشيفي ومن رفض السطر بلا `SANF_DNO`.
- `tests/Feature/StoreReportTest.php` — مدى التاريخ، تعدد المخازن، وجود `GROUP BY` صحيح للخلاصة، وكشف الجرد (`stock-sheet`) لا ينشئ ولا يعدّل أي صف.
- `tests/Feature/StorePermissionTest.php` — 403 لكل كود غائب.
- البوابة: `vendor/bin/pint --dirty --format agent` ثم `php artisan test`.

**العميل (flutter_test):**
- `test/features/stores/store_models_test.dart` (تحليل دفاعي + مفاتيح مزدوجة + إصلاح العربية).
- `test/features/stores/item_form_validation_test.dart` · `order_line_editor_test.dart` (المجاميع والتحقق من المتاح).
- `test/features/stores/report_filter_test.dart` (ظهور نوع الحركة في «عرض حركة» فقط، وتعطيل العرض عند مدى خاطئ).
- `test/features/stores/stock_sheet_test.dart` — حساب الفرق وقيمة الفرق، والتصفية «بفرق فقط»، والتأكد من أن الشاشة لا تنادي أي نقطة كتابة.
- `test/ibac_test.dart` — تحديث الكتالوج (173) والتزامن.
- `test/home_catalog_test.dart` — كما في §8.
- البوابة: `flutter analyze` ⇒ «No issues found!» ثم `flutter test`.

## 10. التوثيق (إلزامي وفق قواعد المشروع)

- `todo.md` — قائمة مهام مؤرَّخة لكل مرحلة (§11) دون حذف السابق.
- `devloping_history.md` — سجل تغييرات العميل والخادم بالملفات والأسباب.
- `DBdevloping_history.md` — التسلسلات الثلاثة عشر (**بلا أي جدول**)، والاستعلامات التي أثبتت الحقائق (AVVG = 2,856 صفاً / 319,310,696؛ استثناء 2/11/12؛ ارتباط `SIZE_FRM/SIZE_TO`؛ سبب رفض الكتابة في `GARD`).
- `db_commends.md` — كل عبارة DDL/DML نُفِّذت مع وقتها.
- `user_commends.md` — نص أمر المستخدم كما هو مع الوقت (بما فيه قراري «لا جداول جديدة» و«الجرد بلا ترحيل»).
- `docs/stores_module_plan.md` — هذا الملف.

## 11. ترتيب التنفيذ

| المرحلة | المحتوى | بوابة الخروج |
|---|---|---|
| 0 | التسلسلات الثلاثة عشر + توثيق DB (بلا أي جدول) | سكربت يعمل مرة واحدة ويُسجّل |
| 1 | `StorePolicy` + `PermissionCatalog` (26 كوداً) + بذر `APP_PERMISSIONS` + مرآة العميل | `ibac_test` أخضر |
| 2 | مرجعيات المخازن/المجموعات/الوحدات/الفئات/الأمناء (خادم + عميل) | شاشة المخازن تعمل |
| 3 | الأصناف (رئيسي/فرعي/وحدات) + كارت الصنف | شاشة الأصناف بتخطيط رئيسي-تفصيلي |
| 4 | أوامر التوريد ثم الصرف ثم التحويل (كاتب مستندات مشترك) | إنشاء أمر يظهر في `AVVG` ويُحذف بلا أثر |
| 5 | الأرصدة + التقارير (نافذة التحديد، حركة/خلاصة، طباعة/تصدير/تكبير) | تقرير يعمل بكل المعطيات |
| 6 | الجرد (كشف عدّ حيّ، فرق، تصفية، طباعة/تصدير — بلا حفظ) | كشف يعمل ويُطبع ولا يغيّر أي رصيد |
| 7 | الاختصارات + لوحة القسم + الصلاحيات على كل عنصر + سجلات النشاط | `home_catalog_test` + تحقق يدوي لكل كود |
| 8 | الاختبارات، `flutter analyze`، `flutter test`، `pint`، والتوثيق | كل البوابات خضراء |

## 12. المخاطر والاحتياطات

1. **الكتابة في قاعدة مشتركة**: كل عملية مستند داخل معاملة واحدة، وكل حذف يوثَّق أولاً في `APP_USER_ACTIVITY`؛ تُجرَّب المرحلة 4 أولاً على مستند وهمي داخل معاملة تُلغى قبل الإطلاق.
2. **أرقام المستندات**: تُولَّد من التسلسلات لا من `MAX+1` في PHP (تجنّب تصادم `UQ(BILL_NO,YEAR)`).
3. **التحويل لا يظهر في الرصيد** إن أُغفل نسخ `LEN/WID` → `SIZE_FRM/SIZE_TO`؛ يفرضه `InventoryLineGuard` ويُختبر في Pest.
4. **الرصيد السالب** (41 صفاً حالياً): يُعرض بوسم أحمر، ويُرفض الصرف الذي يزيده إلا بمنح شامل + `allow_negative`.
5. **الأداء**: `ITEM_MOVEMENT_D` ≈ 150 ألف حركة؛ كل تقرير يُقيَّد بمدى زمني (أقصى سنتين) وبمخازن؛ التقارير لا تُنفَّذ بلا مدى.
6. **قيود التفرّد على الأصناف** (`SANF_NAME`, `PART_NO`) تسبب `ORA-00001` غير مفهومة → تُفحص قبل الإدراج وتُعاد رسالة عربية واضحة.

## 13. مؤجَّل بقرار المستخدم

- **حفظ جلسات الجرد وأرشفتها**: مؤجَّل، ولا يُنشأ له جدول. عند الحاجة يُعاد فتح الموضوع بثلاثة مسارات: (أ) جدول تطبيقي جديد (مرفوض حالياً)، (ب) استخدام `GARD`/`GARD_DETAILES` مع معالجة مضاعفة `GARD_TYPE=6`، (ج) استيراد مستندات التسوية الجاهزة. حتى ذلك الحين: الكشف للعرض والطباعة فقط.
- **ترحيل فروق الجرد إلى المخزون**: مؤجَّل مع النقطة أعلاه؛ البديل اليدوي الحالي هو إدخال أمر توريد (زيادة) أو أمر صرف (نقص) من الشاشتين الموجودتين.
