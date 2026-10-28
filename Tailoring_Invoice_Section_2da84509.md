# قسم التفصيل — خطة التنفيذ

## نطاق العمل والنتيجة المتوقعة

| # | الواجهة | الحالة المستهدفة |
|---|---|---|
| 1 | إضافة فاتورة | نموذج أولي (واجهة كاملة، حفظ معطّل، بلا أي كتابة في القاعدة) |
| 2 | تعديل فاتورة | نموذج أولي (نفس النموذج مُعبّأ مسبقاً، حفظ معطّل) |
| 3 | استعراض فاتورة | **التنفيذ الكامل** — قائمة + بحث + فلترة تاريخ + شاشة استعراض الفاتورة |
| 4 | متابعة سير فاتورة | نموذج أولي (خط سير الحالات من بيانات حقيقية، أزرار الإجراء معطّلة) |

قرارات معتمدة من المستخدم: مصدر بيانات القائمة والتفاصيل = `ACCOUNTS.CUTTING_SALES_BILL_VIEW` حصراً، والنماذج الأولية **قراءة فقط** بلا INSERT/UPDATE.

---

## 1) حقائق قاعدة البيانات المؤكدة (فحص حي عبر موصل oracledb)

**مفتاح الفاتورة مركّب `(BILL_NO, YEAR)`** — `SALES_BILL` فيه 87,345 صفاً مقابل 28,975 رقماً مميزاً، ويوجد فهرس UNIQUE على `(BILL_NO, YEAR)`. لذلك كل مسار/استعلام يستخدم الرقمين معاً، ولا يُعاد استخدام نمط `InvoiceController::show(billNo)` الحالي لأنه يعيد أول صف مطابق.

**بنية البيانات داخل الـ VIEW:** صف واحد لكل «ثوب» (قطعة). التسلسل الهرمي:
`SALES_BILL` ← `SALES_DETAILES_SHAPES` (صف واحد لكل موديل، مفتاحه `SEQ_NO`) ← `MULTI_CLOTHS` (حتى 55 قطعة للموديل، مفتاحها `SEQ_NO1`).
أي: **الموديل** يحمل المستفيد والمقاسات والمواصفات، و**القطعة** تحمل القماش والقصّاص والخيّاط.

**حدود الـ VIEW (مقبولة بقرارك، تُوثَّق في الواجهة):** الـ VIEW يربط `NVL(cutter_no1,0)=cutter.cutter_no` و`NVL(tailor_no1,0)=tailor.tailor_no` بربط داخلي، فيُسقط أي موديل بلا قصّاص. النتيجة: 13,667 فاتورة فقط من أصل 66,827 فاتورة تفصيل. تُعرض ملاحظة صغيرة في رأس القائمة: «تُعرض الفواتير المُسندة لقصّاص وخيّاط»، وحالة فراغ واضحة عندما لا تُوجد الفاتورة في الـ VIEW.

**قراءتان تكميليتان لا مفرّ منهما** (لأن الـ VIEW لا تحمل الأعمدة):
- `SALES_BILL` بصف واحد `(BILL_NO, YEAR)` لخانات الدفع/الطلب غير الموجودة في الـ VIEW: `AMOUNT_PAID, OTHERS_PAYMENTS, IS_GIVING, GIVING_DATE, PAYMENT_METHOD, VOUCHER_NO, TEL_NO2, ADDRESS, REF_NO, URGENT, CUR_NO, CUR_PRICE, BRANCH_NO, CREATED_BY_NAME, LAST_UPDATED_BY_NAME, DETAILES`.
- `CUTING_TRANSD` + `ORDSTATE` (+ `DEPTS`) لسجل الحركة فقط — الـ VIEW يحمل الحالة الحالية `ORDSDID` بلا تاريخ انتقالات.
كل ما عدا ذلك (القائمة، الموديلات، المقاسات، المواصفات، الأقمشة، الحالات) من الـ VIEW حصراً.

**تسميات المقاسات:** الجدول `ACCOUNTS.GENERAL_LABELS_CODING` صف واحد بمصدره الحقيقي:
`L1=الطول، L2=الكتف، L3=طول اليد، L4=الرقبة، L5=العرض، L6=تنزيلة اليد، L7=وسط اليد، L8=الخطوة، L9=طول الجبزور، L10=طول الكبك` و`L11/L12` بلا تسمية.

**مزالق مؤكدة يجب معالجتها:** العربية مخزّنة CP1256 (كل حقل عربي يمرّ عبر `ArabicEncoding::cleanData` في الخادم و`ArabicEncodingUtils.fix()` في العميل) · `TAILOR_NAME1` قد تكون القيمة الحرفية «لا يوجد» ⇒ تُعرض «غير مسند» · `NET - AMOUNT_PAID` قد يكون سالباً (دفعة مقدمة) ⇒ يُعرض «رصيد مقدم» · الأرقام تعود نصوصاً والمفاتيح snake_case صغيرة ⇒ قراءة مزدوجة الحالة ودوال `_parse*`.

---

## 2) الصلاحيات الجديدة (خادم + عميل)

`kyApp_API/app/Support/PermissionCatalog.php` — قسم `tailoring` يُضاف إلى `extra`:
- `export` → «تصدير بيانات التفصيل»
- `payments_view` → «عرض تفاصيل دفع فاتورة التفصيل»
- `progress` → «متابعة سير فاتورة التفصيل»

الكتالوج 141 ⇒ **144**، ويجب تحديث توقّع `kyApp_API/tests/Feature/IbacCoreTest.php:56`.

`lib/core/constants/permission_codes.dart` — إضافة `tailoringExport`, `tailoringPaymentsView`, `tailoringProgress` + مفاتيحها في `permActionLabels`، وتحديث تعليق العدد في رأس الملف.

بذر القاعدة: تشغيل `php artisan tinker database/oracle/02_ibac_seed.php` (idempotent) — يُسجَّل الأمر والنتيجة في `db_commends.md`.

---

## 3) الخادم (Laravel)

**متحكم جديد** `kyApp_API/app/Http/Controllers/TailoringController.php` (قراءة فقط، مغلّف الردود القياسي `success/message/data/meta`، رسائل عربية/إنجليزية، وكل الاستعلامات مربوطة).

### 3.1 `GET /tailoring/bills` — `permission:tailoring.view`
مدخلات: `search`, `from_date`, `to_date`, `page`, `limit` (افتراضي 50، أقصى 200).
```sql
SELECT BILL_NO, YEAR, TO_CHAR(MAX(DAT),'DD/MM/YYYY') DAT_TXT,
       MAX(MANUAL_BILL_NO) MANUAL_BILL_NO, MAX(CUST_NO) CUST_NO,
       MAX(CUST_NAME) CUST_NAME, MAX(TEL_NO1) TEL_NO1,
       COUNT(DISTINCT SEQ_NO) MODELS_COUNT, COUNT(*) PIECES_COUNT,
       MAX(TOTAL) TOTAL, MAX(DISCOUNT) DISCOUNT, MAX(NET) NET,
       MAX(HANDING_DONE) HANDING_DONE, MAX(ORDSDID) ORDSDID
  FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW
 WHERE (:from IS NULL OR DAT >= :from) AND (:to IS NULL OR DAT < :to + 1)
   AND (:no_search OR BILL_NO = :bill OR MANUAL_BILL_NO = :bill
        OR CUST_NAME LIKE :ar OR CUST_NAME LIKE :plain
        OR TEL_NO1 LIKE :digits
        OR EXISTS (SELECT 1 FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW b2
                    WHERE b2.BILL_NO = BILL_NO AND b2.YEAR = YEAR
                      AND b2.BENEFICIARY_NAME LIKE :ar_b))
 GROUP BY BILL_NO, YEAR
 ORDER BY MAX(DAT) DESC, BILL_NO DESC
```
`meta` بالشكل `{total, page, limit, pages}`. البحث النصي يرسل الصيغتين (UTF-8 و`toOracleSearchChars`) كسائر المتحكمات، والدالة `parseDateToIso()` تُنسخ من `CustomerController`.

### 3.2 `GET /tailoring/bills/{billNo}/{year}` — `permission:tailoring.view`
- استعلام واحد على الـ VIEW للفاتورة (كل القطع) ثم تجميع في PHP إلى: `header` + `models[]` (كل موديل: `seq_no`, `beneficiary`, `type_name`, `style_name`, `qty`, `measurements{L1..L12}`, `specs{...}`) + كل موديل يحمل `pieces[]` (`seq_no1`, `cloth_name`, `cloth_type`, `color`, `hinsh`, `yards`, `cutter_name`, `tailor_name`, `cutting_done`, `tailor_done`, `handing_done`).
- قراءة تكميلية واحدة من `SALES_BILL` لبيانات الدفع/الطلب. **إن لم يملك المستخدم `tailoring.payments_view` تُعاد خانات المال `null` من الخادم** (الحجب على الخادم لا في الواجهة).
- تسجيل تدقيق `tailoring.bill_viewed` عبر `ActivityLogger` (`module_code: tailoring`, `entity_type: cutting_bill`, `entity_id: "{billNo}/{year}"`).
- 404 برسالة صريحة عندما لا تُوجد الفاتورة في الـ VIEW (تُترجم في العميل إلى حالة فراغ تفسيرية).

### 3.3 `GET /tailoring/bills/{billNo}/{year}/movements?seq_nos=136043,136044` — `permission:tailoring.view`
```sql
SELECT ct.TR_INV_D_ID, TO_CHAR(ct.DDATE,'DD/MM/YYYY') DDATE_TXT,
       os.ORDSNAME, ct.ORDSID, dp.DEPTNAME, ct.DETAILE,
       ct.QTY, ct.PQTY, ct.SQTY, ct.SEQ_NO, ct.POST,
       ct.CREATED_BY_NAME, ct.UPDATED_BY_NAME
  FROM ACCOUNTS.CUTING_TRANSD ct
  JOIN ACCOUNTS.ORDSTATE os ON os.ORDSID = ct.ORDSID
  LEFT JOIN ACCOUNTS.DEPTS dp ON dp.DEPTID = ct.DEPTID
 WHERE ct.BILL_NO = :bill AND ct.YEAR = :year AND NVL(ct.CANCEL,0) <> 1
   AND ct.SEQ_NO IN (:seq_nos)
 ORDER BY ct.DDATE, ct.TR_INV_D_ID
```
`seq_nos` تأتي من صفوف الـ VIEW التي يحملها العميل فعلاً (أرقام `SEQ_NO1` للموديل المختار) — فلا قراءة إضافية لجداول أخرى.

### 3.4 `GET /tailoring/reference` — `permission:tailoring.view,tailoring.create`
`measure_labels` (من `GENERAL_LABELS_CODING`) + `types` (`TYPES` الفعّالة) + `styles` (`STYLE` الفعّالة). تخدم تسميات المقاسات في شاشة الاستعراض وقوائم نموذج الإضافة معاً.

### 3.5 `POST /tailoring/bills/{billNo}/{year}/activity` — `permission:tailoring.print,tailoring.export`
جسم `{action: "print"|"export"}` ⇒ صف واحد في `APP_USER_ACTIVITY` فقط (`tailoring.bill_printed` / `tailoring.bills_exported`). لا يمسّ أي جدول إرث.

**التحقق من مسار الأعمال:** هذه المسارات الخمسة كلها خلف `auth:sanctum` + `permission:` فلا تتأثر قائمة المسارات العامة في `BusinessRoutesSealedTest.php`، لكن اختبار الحجب الجديد مطلوب (القسم 7).

---

## 4) العميل (Flutter) — مجلد ميزة جديد `lib/features/tailoring/`

```
data/models/   cutting_bill_summary_model.dart · cutting_bill_detail_model.dart
               cutting_model_item.dart · cutting_piece_item.dart
               cutting_movement_model.dart · tailoring_reference_model.dart
data/repositories/tailoring_repository.dart
presentation/providers/tailoring_providers.dart
presentation/screens/  tailoring_dashboard_screen.dart
                       cutting_bills_list_screen.dart
                       cutting_bill_view_screen.dart
                       cutting_bill_add_screen.dart      (نموذج أولي)
                       cutting_bill_edit_screen.dart     (نموذج أولي)
                       cutting_bill_progress_screen.dart (نموذج أولي)
presentation/widgets/  bill_header_card.dart · bill_customer_card.dart · bill_payment_card.dart
                       model_selector_strip.dart · model_measurements_grid.dart
                       model_specs_panel.dart · model_fabrics_table.dart
                       model_movements_table.dart · workflow_stepper.dart
                       bill_list_tile.dart
presentation/utils/cutting_bill_pdf_builder.dart
```
لا تبعيات pubspec جديدة: `printing`, `pdf`, `excel`, `share_plus`, `dio`, `flutter_riverpod` موجودة.

**المزودات** (بنمط المشروع: `build()` لا ينتظر + `CancelToken` + حراسة نسخة البحث):
`tailoringRepositoryProvider` · `cuttingBillsListProvider` (`NotifierProvider` بحالة `{items, isLoading, error, query, from, to, page, hasMore, total}`) · `cuttingBillDetailProvider` (`FutureProvider.autoDispose.family<CuttingBillDetail, CuttingBillKey>`) · `cuttingMovementsProvider` (`FutureProvider.autoDispose.family`) · `tailoringReferenceProvider` (`FutureProvider`).

### 4.1 لوحة القسم — `tailoring_dashboard_screen.dart`
تُستدعى من `tailoring_section.dart` (الذي يعيد حالياً `DataListScaffold` فارغاً). نفس تصميم `customers_dashboard_screen.dart`: ترويسة + شبكة بطاقات، وأربع بطاقات:
`استعراض فاتورة` (`tailoring.view`) · `إضافة فاتورة` (`tailoring.create`) · `تعديل فاتورة` (`tailoring.update`) · `متابعة سير فاتورة` (`tailoring.progress`) — والثلاث الأخيرة تحمل شارة «نموذج أولي».

### 4.2 قائمة الفواتير — `cutting_bills_list_screen.dart`
- بحث مؤجَّل 300ms بترقيم صفحات لا نهائي، تلميح: «رقم الفاتورة / الرقم اليدوي / اسم العميل / الهاتف / المستفيد».
- شريط فلترة زمنية (من/إلى + نطاقات جاهزة: اليوم، الأسبوع، الشهر، السنة، الكل) بنمط `my_work_statement_screen.dart`.
- بطاقة الفاتورة: رقم الفاتورة + الرقم اليدوي، التاريخ، العميل، الهاتف، عدد الموديلات/القطع، الصافي، شارة الحالة (`ORDSDID`).
- الحالات الأربع (تحميل/نجاح/فراغ/خطأ مع إعادة المحاولة)، وسطر توضيحي عن نطاق الـ VIEW في حالة الفراغ.
- الضغط على البطاقة ⇒ `CuttingBillViewScreen` (دفع أمرِي بـ `Navigator.push` كالعُرف).

### 4.3 شاشة استعراض الفاتورة — `cutting_bill_view_screen.dart` (الهدف الأساسي)
`Scaffold` + `AppBar` بأزرار: طباعة (`Perm.tailoringPrint`) · تصدير PDF (`Perm.tailoringExport`) · تحديث · فلترة/معلومات.
الجسم: `ReportZoomView` (تكبير/تصغير بالإصبع وبالأزرار ونسبة ظاهرة — نفس غلاف كل التقارير) يحتوي عموداً قابلاً للتمرير:
1. **بيانات الفاتورة والطلب** — رقم الفاتورة، الرقم اليدوي، التاريخ، السنة، المجموعة، الفرع، عاجل، تاريخ التسليم، البيان.
2. **بيانات العميل** — الرقم، الاسم، الهاتفان، العنوان، رقم الحساب.
3. **تفاصيل الدفع** — مغلّفة بـ `PermissionGate(code: Perm.tailoringPaymentsView)`: الإجمالي، الخصم، الصافي، المدفوع، المتبقي (أو «رصيد مقدم» عند السالب)، الاستحقاق، طريقة الدفع، رقم السند.
4. **الموديلات والمستفيدون** — `model_selector_strip`: كتلة لكل موديل (رقم الموديل، نوع الموديل، المستفيد، عدد القطع)، والاختيار يقود الأقسام 5–7.
5. **المقاسات** — `model_measurements_grid`: شبكة L1..L12 بتسمياتها من `reference`، تُخفي الفارغ افتراضياً مع مفتاح «إظهار الكل».
6. **المواصفات** — `model_specs_panel`: `type_name`/`style_name`، ثم شرائح نصية لـ `NECK_TYPE, TIPPER_TYPE, COM_CABAK_TYPE, POCKET_OR_WITHOUT, GABZOR_TYPE, BUTTON_TYPE, BUTTON_NO, MOBILE_POCKET, PEN_POCKET, HEGAZI_TYPE` وملاحظة `NOTES2`، ثم الأكواد الرقمية للنماذج (`SHAPE_STYLE_NO, NECK_SHAPE_NO, SHAPE_GABZOR_NO, SHAPE_COM_CABAK_NO, SHAPE_POCKET_UP_NO, SHAPE_POCKET_DOWN_NO`) كما هي بلا ترجمة مخترعة.
7. **الأقمشة** — `model_fabrics_table`: صف لكل قطعة (رقم الثوب، اسم القماش، نوعه، اللون، هنش/يارد، مصدر القماش، الرف، السعر).
8. **سجل الحركة** — `model_movements_table` يُحمَّل عند فتح القسم من `cuttingMovementsProvider` (تاريخ، الحالة، العدد، القسم، ملاحظة، ترحيل).
تخطيط متجاوب: عمود واحد على الجوال، عمودان (بيانات/مال يميناً والموديلات يساراً) على الحاسب.

### 4.4 الطباعة والتصدير — `cutting_bill_pdf_builder.dart`
يبني PDF بالترويسة الموحدة عبر `report_pdf_page.dart` + `report_pdf_arabic.dart` (تشكيل العربية وعكس ترتيب الكلمات) + `report_pdf_fonts.dart`، والترويسة من `ReportLetterheadInfo.fromConfig(appConfigNotifierProvider)`. المحتوى: ترويسة + كتلة الفاتورة/العميل + كتلة الدفع + جدول الموديلات بأعمدته المعكوسة (`reversedCells`) + جدول الأقمشة + تذييل التوقيعات. الأزرار: `Printing.layoutPdf` للطباعة و`Printing.sharePdf` للتصدير، وكل منهما يستدعي مسار التدقيق 3.5 بلا انتظار.

### 4.5 النماذج الأولية
- **إضافة**: قسم عميل (`customer_picker_screen` الموجود) + بيانات الطلب + موديل واحد قابل للتكرار (مستفيد، نوع/شكل من `reference`، شبكة مقاسات بالتسميات الحقيقية، أقمشة) + شريط ثابت «نموذج أولي — الحفظ غير مفعّل»، وزر الحفظ معطّل داخل `PermissionGate(code: Perm.tailoringCreate)`.
- **تعديل**: نفس النموذج مُعبّأ من تفاصيل فاتورة حقيقية، قراءة فقط، بنر «نموذج أولي» داخل `PermissionGate(code: Perm.tailoringUpdate)`.
- **متابعة السير**: `workflow_stepper` بمراحل `ORDSTATE` (تسليم للقص → تم القص → استلام من القص → تجهيز 1 → تسليم للخياط → تم الخياط → استلام من الخياط → تجهيز 2 → تم التسليم) مع حالة كل قطعة من الـ VIEW، وجدول الحركة الفعلي، وبنر «قيد التطوير»، وبوابة `Perm.tailoringProgress`.

---

## 5) الربط بالواجهة الرئيسية والقسم

- `lib/features/employee_portal/presentation/screens/sections/tailoring_section.dart` ⇒ `TailoringDashboardScreen` (بدل `DataListScaffold`).
- `lib/features/home/domain/home_shortcut_catalog.dart`:
  - إزالة `underDevelopment: true` من `tailoring.section`.
  - إضافة: `tailoring.bills` (استعراض فاتورة ⇒ `CuttingBillsListScreen`، `defaultOn: true`)، `tailoring.add`، `tailoring.progress`، `tailoring.edit` — جميعها `sectionId: 'tailoring'` وبأكوادها الحقيقية (`ScreenTarget` بمرجع بنّاء فقط ليبقى الكتالوج `const`).
- تحديث `test/home_catalog_test.dart`: عدد الافتراضيات (14 ⇒ الجديد) و«الأقسام الموسومة قيد التطوير» تصبح `{'sales','stores'}` بدل `{'sales','tailoring','stores'}`.

---

## 6) سجلات النشاط والتدقيق

كلها في `APP_USER_ACTIVITY` عبر `ActivityLogger` (لا يفشل الطلب عند فشل السجل):
`tailoring.bill_viewed` (فتح فاتورة) · `tailoring.bill_printed` · `tailoring.bills_exported`. تُعرض تلقائياً في شاشة نشاط المستخدم لأنها تقرأ `module_code`/`action_code` من الصف مباشرة.

---

## 7) الاختبار وبوابات الجودة

- **Flutter:** `test/features/tailoring/cutting_bill_models_test.dart` (تحليل JSON بمفاتيح صغيرة/نصوص رقمية/عربية مشوّهة)، `tailoring_repository_test.dart` (Dio وهمي — نمط `account_statement_repository_test.dart`)، `cutting_bill_view_screen_test.dart` (تحميل/خطأ/فراغ/نجاح + تبديل الموديل يغيّر المقاسات)، وتحديث `test/home_catalog_test.dart`.
- **Pest:** `kyApp_API/tests/Feature/TailoringTest.php` — 401 بلا جلسة، 403 بلا منح، 200 للمدير، شكل `meta`، 404 لفاتورة غير موجودة، وحجب خانات المال عند غياب `tailoring.payments_view`. تحديث `IbacCoreTest.php` (144).
- **البوابات:** `flutter analyze` ⇒ «No issues found!» · `flutter test` · `vendor/bin/pint --dirty --format agent` · `php artisan test --filter=Tailoring` ثم الحزمة الكاملة.

---

## 8) التوثيق الإلزامي (قواعد المشروع)

بالإضافة بعد آخر سطر في كل ملف دون حذف أو استبدال، مع الوقت ونموذج التنفيذ:
`todo.md` (المهام) · `devloping_history.md` (تغييرات Flutter/الخادم) · `DBdevloping_history.md` (بنية الـ VIEW وتجميع الموديل/القطعة، `GENERAL_LABELS_CODING`، `ORDSTATE`، ومحدودية الـ VIEW) · `user_commends.md` (نص الأمر) · `db_commends.md` (أوامر SELECT التشخيصية وأمر بذر الصلاحيات).

---

## 9) ترتيب التنفيذ

1. كتالوج الصلاحيات (خادم + عميل) + بذرها + تحديث `IbacCoreTest`.
2. `TailoringController` + المسارات الخمسة + التدقيق.
3. هيكل ميزة Flutter: النماذج + المستودع + المزودات.
4. لوحة القسم + قائمة الفواتير.
5. شاشة الاستعراض (الأقسام 1–8) + غلاف التكبير.
6. مولّد PDF + الطباعة/التصدير + مسار التدقيق.
7. النماذج الأولية الثلاثة.
8. الربط: `tailoring_section.dart` + كتالوج الاختصارات + تحديث اختبار الكتالوج.
9. الاختبارات، البوابات، والتوثيق.

## 10) مخاطر معروفة (موثّقة مسبقاً)

- **تغطية الـ VIEW 20%** — الفواتير غير المُسندة لقصّاص/خيّاط لا تظهر؛ تُعالَج برسالة واضحة لا بإخفاء صامت.
- `BILL_NO` غير فريد ⇒ المفتاح المركّب في كل مسار، وأي نسخ لنمط `InvoiceController` الحالي خطأ.
- خانات الدفع والحركة تحتاج القراءتين التكميليتين الموصوفتين في القسم 1؛ رفضهما يعني حجب «تفاصيل الدفع» و«سجل الحركة» كلياً.
- قيم «لا يوجد» والمبالغ السالبة والتواريخ التي تعود ISO مع `Z` تُطبَّع في طبقة النموذج لا في الواجهة.
