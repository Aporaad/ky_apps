# خطة إنشاء قسم «الخدمات والمزودين» في بوابة الموظف

> **الحالة:** خطة للاعتماد — لا كود مُنفَّذ بعد.
> **النطاق:** عميل Flutter + واجهة Laravel + كائنات Oracle (صلاحيات، فهارس/تسلسلات اختيارية).
> **المرجع:** `AGENTS.md` (الجذر) و`kyApp_API/AGENTS.md` (الخادم).
> **تاريخ الإعداد:** 2026-10-23 — كل الأرقام الواردة أدناه مقروءة من القاعدة الحيّة في هذا التاريخ.

---

## 1. الملخص التنفيذي

المطلوب قسم جديد في بوابة الموظف باسم **«الخدمات والمزودين»** يجمع خمسة أشياء كانت — حتى الآن — تُدار من
برامج سطح المكتب القديمة أو من داخل Oracle مباشرة:

1. **إدارة المزودين** (`PROVIDERS`) واشتراكاتهم في الخدمات (`PROVIDERS_DTL`).
2. **خدمة الرسائل النصية SMS**: قنواتها وسجل رسائلها (`MSG_QUEUE` / `MSG_ARCHIVE`).
3. **خدمة رسائل واتساب**: قنواتها وسجل رسائلها (`W_MSG_QUEUE` / `W_MSG_ARCHIVE`).
4. **إعدادات الخدمات**: صف الشركة الواحد في `CORP` الذي يقرأه محرك الإرسال، وكتالوج `SERVICES`.
5. **إدارة مهام الإرسال** (`SEND_MSG` / `W_SEND_MSG` / `W_SEND_MSG_F`) مع سجل تشغيلها.

القسم **لا يملك جداول جديدة**، ولا يمسّ الحزم البرمجية القائمة، ولا يغيّر منطق الإرسال. هو **واجهة تحكم
وقراءة** فوق عقد قائم، مع ثلاث إضافات لا مفرّ منها: كتالوج صلاحيات جديد (26 كوداً)، قيد تفرّد على
`PROVIDERS_DTL` يمنع الإرسال المزدوج، وطبقة تحقق تمنع أي تنفيذ DDL عشوائي من شاشة المهام.

**النتيجة المتوقعة:** يستطيع المسؤول تشخيص «لماذا لم تُرسل رسالة؟» من داخل التطبيق في أقل من دقيقة،
بدل فتح SQL Developer؛ ويستطيع تعديل مزود أو إيقاف مهمة دون لمس الخادم.

**الحجم التقديري:** 18–22 يوم عمل لمطوّر واحد (تفصيل في §12).
**المخاطر الأعلى:** أسرار المزودين، وأوامر المهام المجدولة (كلاهما مُعالَج بقرار صريح في §4 و§10).

---

## 2. النطاق

### 2.1 داخل النطاق

| # | البند | ملاحظة |
|---|---|---|
| 1 | قسم واحد في سجل البوابة (`portal_sections.dart`) يظهر حسب الصلاحية | لا يظهر في شريط الجوال السفلي (ممتلئ بخمسة) |
| 2 | شاشة رئيسية للقسم (hub) بخمس بطاقات | كل بطاقة تُحجب بصلاحيتها |
| 3 | مزودون: عرض/إضافة/تعديل/تعطيل/حذف + اشتراكاتهم | الحذف مقيّد بوجود مراجع |
| 4 | قنوات SMS وقنوات واتساب: عرض/إضافة/تعديل/تعطيل/حذف | هي صفوف `PROVIDERS_DTL` نفسها، بعرضٍ من زاويتين |
| 5 | سجل رسائل SMS وأرشيفه، بتبويبات: الكل/المرسلة/المنتظرة/الفاشلة | مع تفاصيل الرسالة وإعادة الإرسال |
| 6 | سجل رسائل واتساب وأرشيفه، بنفس التبويبات + رسالة الخطأ والمرفق | |
| 7 | إعدادات الخدمات: تحرير صف `CORP` الواحد + عرض `SERVICES` | `SANF_TYPE` للقراءة فقط |
| 8 | مهام الإرسال: عرض الحالة، تفعيل/تعطيل، تعديل الجدولة والمهلة، تشغيل فوري، حذف مهام التطبيق، سجل تشغيل مُصفّى | |
| 9 | 26 كود صلاحية جديداً + مرآتها في العميل + عناوين عربية | |
| 10 | خمسة اختصارات في الشاشة الرئيسية | |
| 11 | اختبارات Flutter + Pest للطبقات الجديدة | |

### 2.2 خارج النطاق (صريحاً)

- **لا** إنشاء رسائل جديدة (composer) في هذه المرحلة. العقد يدعمه (`MSG_QUEUE_TAPI.INS_MSG_QUEUE`)،
  لكنه يحتاج قراراً في القوالب ومصدر أرقام العملاء — يُطرح كمرحلة 9 اختيارية (§14، سؤال D6).
- **لا** تعديل على `MSG_QUEUE_TAPI` أو `SendWhatsappAPI` أو `MSG_ARCHIVE_TAPI`.
- **لا** جداول أو Migrations جديدة، ولا `build_runner`/codegen.
- **لا** إدارة كتالوج `SERVICES` كتابةً (إضافة/حذف خدمة) في المرحلة الأولى: حذف خدمة يكسر استعلامات
  الحزم القائمة. تُعرض للقراءة مع تحذير على الصفوف اليتيمة (§3.4 / F3).
- **لا** نقل ملكية الإرسال من Oracle إلى Laravel. التطبيق يقرأ ويكتب إعدادات، ولا يرسل بنفسه.

### 2.3 تفسير المصطلحات (اتفاق على المعنى قبل البناء)

| المصطلح | المعنى في هذه الخطة |
|---|---|
| **مزوّد** | صف في `PROVIDERS`: جهة (EngazSoft، إلخ) لها اسم ونوع وحالة |
| **اشتراك / قناة** | صف في `PROVIDERS_DTL`: ربط مزوّد بخدمة مع بيانات اتصال (URL، مستخدم، سر، توكن) |
| **خدمة** | صف في `SERVICES`: نوع الإرسال (`URL` / `FIREBASE` / `WHATSAPP`) |
| **رسالة منتظرة** | ما يزال في جدول الطابور ولم تُحسم نتيجته |
| **رسالة عالقة** | في الطابور، استُنفدت محاولاتها، فلن يعيد المحرك محاولتها أبداً — تظهر تحت «الفاشلة» |
| **مهمة (job)** | كائن `DBMS_SCHEDULER` باسم `SEND_MSG` أو `W_SEND_MSG` أو `W_SEND_MSG_F` |
| **الأمر** | `JOB_ACTION` — كتلة PL/SQL التي تنفّذها المهمة |

---

## 3. الوضع الراهن المُتحقَّق منه (قاعدة البيانات الحيّة)

### 3.1 الجداول المعنية كما هي فعلاً

| الجدول | المفتاح | الأعمدة المهمة | قيود |
|---|---|---|---|
| `PROVIDERS` | `PROVIDER_ID` (PK) | `PROVIDER_NAME` NOT NULL، `TYPE` NOT NULL (افتراضي `'URL'`)، `STATUS` NOT NULL (افتراضي 1)، `USER_NAME`, `PASSWORD`, `URL`, `CREATED_*`, `UPDATED_*` | لا FK، لا trigger |
| `PROVIDERS_DTL` | `ID` (PK) | `PROVIDER_ID`, `SERVICE_ID`, `STATUS`، `USER_NAME`, `PASSWORD`, `URL`, `BODY`, `TOKEN`, `SEND_ATTEMPT_CNT` (افتراضي 3)، `SENT_ARCHIVE` (افتراضي 0)، تواريخ | لا FK، **لا قيد تفرّد على (PROVIDER_ID, SERVICE_ID)** |
| `SERVICES` | `SERVICE_ID` (PK) | `SERVICE_TYPE` NOT NULL، `SERVICE_NAME` | 3 صفوف فقط |
| `CORP` | **لا مفتاح** | `CORP_NAME` NOT NULL، `CORP_ADDR` NOT NULL، `CORP_TEL1/TEL2` NUMBER(10)، `SANF_TYPE` NOT NULL، `FILE_PATH` | صف واحد فقط |
| `MSG_QUEUE` | `ID` (PK) | `MSG_TEXT` NOT NULL، `MOBILE_NO` NUMBER NOT NULL، `IS_SENT` NOT NULL، `SEND_ATTEMPT`، `SERVICE_ID`, `PROVIDER_ID`, `CUSTOMER_NAME`, تواريخ | لا trigger، **بلا `ERROR_MSG`** |
| `MSG_ARCHIVE` | `ID` (PK) | نفس الأعمدة السابقة | لا `ERROR_MSG` |
| `W_MSG_QUEUE` | `ID` (PK) | نفسها + `FILE_PATH/FILE_NAME/FILE_TYPE/CAPTION/ERROR_MSG`، `IS_SENT` VARCHAR2(5) | |
| `W_MSG_ARCHIVE` | `ID` (PK) | نفسها | |

> **لا توجد أي مفاتيح أجنبية** بين هذه الجداول، ولا تسلسلات خاصة بها، ولا triggers. كل التحقق العلائقي
> يجب أن يكون في التطبيق.

### 3.2 البيانات الحالية (أرقام حقيقية)

| القياس | القيمة | ملاحظة |
|---|---|---|
| `PROVIDERS` | 2 صف، كلاهما `STATUS=1` | الثاني `URL = NULL` |
| `PROVIDERS_DTL` | 5 صفوف | صفّان (4، 5) يشيران إلى خدمتين **غير موجودتين** |
| `SERVICES` | 3 صفوف | `1 SMS BY URL` · `2 SMS BY FIREBASE` (اشتراكها معطّل) · `3 SMS BY WHATSAPP` |
| `CORP` | صف واحد | الاسم والعنوان مخزّنان ببايتات CP1256 (mojibake عند القراءة الخام) |
| `MSG_QUEUE` | **0 صف** | إحصائية `USER_TABLES.NUM_ROWS` تقول 10 — **قديمة، لا تُصدَّق** |
| `MSG_ARCHIVE` | 22,802 صف | منها 22,720 `Y` و82 `N` |
| `W_MSG_QUEUE` | صف واحد `F` | بلا `ERROR_MSG` وبلا `CREATED_AT` |
| `W_MSG_ARCHIVE` | 19 صفاً، كلها `Y` | |
| `APP_PERMISSIONS` | 97 كوداً / 18 قسماً | ستصبح 123 / 23 بعد هذه الخطة |

### 3.3 كيف يعمل الإرسال فعلاً (مقروء من الحزم، لا مفترض)

**SMS — `MSG_QUEUE_TAPI.PUSH_QUEUE` (مهمة `SEND_MSG` كل 3 ثوانٍ):**

1. يقرأ كل صف `MSG_QUEUE.IS_SENT='N'`.
2. يبحث عن صف `PROVIDERS_DTL` نشط يطابق `PROVIDER_ID/SERVICE_ID` **و** `SEND_ATTEMPT <= SEND_ATTEMPT_CNT`.
3. يبني `URL` من قوالب `#USERNAME#` / `#PASSWORD#` / `#MESSAGE#` / `#PHONE_NO#` ثم ينادي Java حسب
   `SERVICES.SERVICE_TYPE` (`URL` / `FIREBASE` / `WHATSAPP`).
4. يزيد `SEND_ATTEMPT`، ويعتبر الرسالة مرسلة عند ورود `0000` أو `success` أو `duplicated` أو 200.
5. **ثم يؤرشف فوراً عبر `MSG_ARCHIVE_TAPI.ARCHIVE_MSG`**، وهذه لا تؤرشف إلا إذا كان
   `IS_SENT='Y'` **و** وُجد اشتراك بـ`SENT_ARCHIVE=1`، ثم تحذف الصف من الطابور.

**النتيجة العملية:** الرسالة الفاشلة **لا تُؤرشف** (شرط `IS_SENT='Y'`)، وتبقى في `MSG_QUEUE` إلى الأبد
بعد استنفاد المحاولات — لأن شرط `SEND_ATTEMPT <= SEND_ATTEMPT_CNT` يمنع إعادة المحاولة ولا شيء يحذفها.
هذه هي «الرسالة العالقة»، وهي أهم ما يجب أن تُظهره الشاشة الجديدة.
(وجود 82 صفاً بـ`N` داخل الأرشيف يعني أنها كُتبت بمسار أقدم؛ لا تُبنى القاعدة عليها.)

**واتساب — `SendWhatsappAPI.PUSH_QUEUE` (مهمة `W_SEND_MSG` كل 20 ثانية):**

1. يقرأ `W_MSG_QUEUE` بحالة `N` و`SEND_ATTEMPT <= 10`.
2. يقرأ الإعداد من `PROVIDERS_DTL` بمفتاح **مثبَّت في الكود**: `NVL(SERVICE_ID,'3')` و`NVL(PROVIDER_ID,'1')`
   — أي أن قناة واتساب الفعلية هي **(مزود 1، خدمة 3)**.
3. `GET_API_CONFIG` يقرأ: `URL → BASE_URL`، **`PASSWORD → SESSION_ID`**، **`TOKEN → API_KEY`**.
4. عند النجاح: يُدرج في `W_MSG_ARCHIVE` ثم **يحذف** صف الطابور. عند الفشل: يحدّث الصف إلى `F`/`NV`
   مع `ERROR_MSG` ويبقى في الطابور.
5. مهمة `W_SEND_MSG_F` (كل 14 دقيقة) تحوّل كل `N` إلى `F` — أي أن أقصى عمر لرسالة منتظرة هو 14 دقيقة.

### 3.4 فجوات وتعارضات مكتشفة (تُعالَج في الخطة)

| # | الفجوة | الأثر | المعالجة |
|---|---|---|---|
| **F1** | لا قيد تفرّد على `(PROVIDER_ID, SERVICE_ID)` | صفّان متطابقان نشطان ⇒ **إرسال الرسالة مرتين** وعدّ محاولتين | تحقق في التطبيق + فهرس فريد (§5.3) |
| **F2** | `MSG_QUEUE` بلا `ERROR_MSG`، والأرشيف لا يستقبل الفاشلة | لا يمكن معرفة **سبب** فشل SMS إطلاقاً | تُعرض المحاولات والحالة فقط، ويُوضَّح ذلك في الواجهة بلا ادّعاء سبب |
| **F3** | صفّا `PROVIDERS_DTL` (4، 5) يشيران إلى خدمتين غير موجودتين (`SERVICES` فيها 1–3 فقط) | اشتراكان «نشطان» لا يرسلان شيئاً، ويظهران في أي شاشة تجمع بلا فحص | تحذير «خدمة غير معروفة» + قرار D4 |
| **F4** | الرسائل العالقة لا يراها أحد اليوم | طابور ينمو بلا حد، ورسائل لا تُرسل بلا إشعار | تبويب «الفاشلة» يشمل العالقة + إجراء تحرير |
| **F5** | مهام الإرسال تُدار من `DBMS_SCHEDULER` مباشرة | تعطيل `SEND_MSG` يوقف كل رسائل الشركة بصمت | شاشة مهام + تحذير قبل كل تغيير + صلاحية مستقلة |
| **F6** | `NUM_ROWS` في `USER_TABLES` قديمة (تقول 10 لطابور فارغ) | عدّادات مضلّلة إن بُنيت على الإحصائية | كل الأعداد بـ`COUNT(*)` لا بالإحصائية |
| **F7** | سجل تشغيل `SEND_MSG` ≈ **21,142 صفاً في 24 ساعة** | أي استعلام بلا تصفية يُغرق الخادم والواجهة | نافذة زمنية إلزامية + ترقيم + فهرس على الطلب |
| **F8** | `CORP_TEL1` من نوع NUMBER(10) وسكانه 9 أرقام محلية | لا يقبل `967…`، و`GET_COMPANY_DETAILS` يستخدمه كرقم جهة الاتصال | تحقق 10 أرقام كحد أقصى، وبلا إضافة مفتاح دولة |

---

## 4. القرارات المعمارية

| # | القرار | المبرر |
|---|---|---|
| **D1** | **لا أسرار عبر HTTP إطلاقاً.** لا يُعاد `PASSWORD`/`TOKEN` في أي استجابة؛ يُعاد مؤشر واحد فقط `credentials_configured`، والكتابة إما «قيمة جديدة» أو «اتركها»، والمسح بعَلَم منفصل | `selectFromTable` يحجب هذه الأعمدة أصلاً؛ وكشفها في مسار جديد ينقض ذلك. من يحتاج القيمة الحقيقية يستخدم أدوات القاعدة بصلاحية DBA |
| **D2** | **لا DDL عشوائي من الواجهة.** شاشة المهام تتعامل مع **قائمة مغلقة** من أسماء المهام، و`JOB_ACTION` **للقراءة فقط**، والإنشاء من **قوالب معتمدة** فقط | `DBMS_SCHEDULER.JOB_ACTION` كتلة PL/SQL تُنفَّذ بصلاحيةDBA: أي حقل نصي حر يعني تنفيذ كود عن بُعد على القاعدة |
| **D3** | **المهام الثلاث القديمة محمية من الحذف**؛ `DELETE` يعمل فقط على مهام ينشئها التطبيق (بادئة `KY_`) | حذف `SEND_MSG` يوقف إرسال الشركة نهائياً ولا يمكن استرجاعه من الواجهة |
| **D4** | **`MAX_RUN_DURATION` + جدولة مبنية من نموذج**، لا نص `REPEAT_INTERVAL` حر | نمنع قيماً غير صالحة تُعطّل المهمة، ونمنح «المهلة» معنى تشغيلياً واضحاً |
| **D5** | **حالة الرسالة مشتقّة، لا عمود واحد** | SMS وواتساب لهما دلالات مختلفة: الطابور/الأرشيف/`F`/`NV` (§5.1) |
| **D6** | **إعادة الإرسال تُنشئ صفاً جديداً** للرسالة المؤرشفة، و**تُصفّر المحاولات** للعالقة فقط | الأرشيف لا يحتوي الصف بعد الإرسال؛ إعادة استخدام المعرّف مستحيلة، وتكرار النص بمعرّف جديد هو الصدق الوحيد الممكن |
| **D7** | **لا جداول جديدة ولا Migrations.** الاستثناء الوحيد: صفوف كتالوج الصلاحيات + فهرس فريد + (اختيارياً) تسلسلات | القاعدة ليست ملكنا (`AGENTS.md §6`)، و`database/migrations` لا تصف Oracle |
| **D8** | **`CORP` هو مصدر الإرسال، و`APP_SETTINGS.company_name` هو مصدر العرض.** تُعرض فروقاتهما بلا دمج تلقائي | دمج الاثنين يعني ترحيل بيانات شركة على الإنتاج؛ الخطة تعرض الفرق وتقترح مزامنة يدوية واحدة |

---

## 5. نموذج البيانات ودلالات الحالات

### 5.1 خريطة الحالة (المصدر الوحيد للحقيقة في الواجهة والخادم)

**SMS**

| التبويب | المصدر | الشرط |
|---|---|---|
| الكل | `MSG_QUEUE` ∪ `MSG_ARCHIVE` | — |
| المنتظرة | `MSG_QUEUE` | `IS_SENT='N'` و`SEND_ATTEMPT < الحد` |
| المرسلة | `MSG_ARCHIVE` | `IS_SENT='Y'` |
| الفاشلة | `MSG_ARCHIVE` (`IS_SENT<>'Y'`) ∪ `MSG_QUEUE` العالقة | + وسم `stuck` للعالقة |
| العالقة | `MSG_QUEUE` | `IS_SENT='N'` و`SEND_ATTEMPT >= الحد` |

الحد = `MAX(SEND_ATTEMPT_CNT)` للاشتراكات النشطة المطابقة بنفس منطق `NVL(PROVIDER_ID, d.PROVIDER_ID)`؛
وإن لم يوجد اشتراك مطابق فالقيمة 3 (الافتراضي في الجدول).

**واتساب**

| التبويب | المصدر | الشرط |
|---|---|---|
| الكل | `W_MSG_QUEUE` ∪ `W_MSG_ARCHIVE` | — |
| المنتظرة | `W_MSG_QUEUE` | `IS_SENT='N'` و`SEND_ATTEMPT <= 10` |
| المرسلة | `W_MSG_ARCHIVE` | `IS_SENT='Y'` |
| الفاشلة | `W_MSG_QUEUE` | `IS_SENT IN ('F','NV')` |
| + أرشيف فاشل | `W_MSG_ARCHIVE` | `IS_SENT IN ('F','NV')` |

> تبويب «الفاشلة» يحمل شارة عدد صغير للعالقة، لأنها الحالة التي لا يعرفها أحد اليوم (F4).

### 5.2 قواعد الكتابة على القاعدة

1. **العربية** في `CORP.CORP_NAME/ADDR` وأي اسم مزود أو خدمة: كتابة بـ
   `ArabicEncoding::toOracleSearchChars()`، وقراءة بـ`fixMojibake()` — كما في `CurrencyController`.
   الرسائل (`MSG_TEXT`) تُقرأ بـ`fixMojibake()` فقط؛ لا تُكتب من التطبيق في هذه المرحلة.
2. **التواريخ**: `SYSDATE` للإنشاء والتعديل، و`TO_CHAR(...,'YYYY-MM-DD HH24:MI:SS')` للعرض،
   و`TO_DATE(:d,'DD/MM/YYYY')` لأي تصفية زمنية من الواجهة (نمط `AccountController`).
3. **الأرقام**: `MOBILE_NO` عمود NUMBER — التحقق `^[0-9]{6,15}$` بلا `+` وبلا صفر بادئ، وتمنع الواجهة
   إرسال `+967` لأن القاعدة ستقصّه أو ترفضه.
4. **المفاتيح**: `PROVIDERS` و`PROVIDERS_DTL` بلا تسلسل. القرار المقترح D-التسلسل في §5.3.
5. **كل استعلام بمعاملات مربوطة (binds)** — لا لصق نصوص، بما في ذلك أسماء المهام.

### 5.3 DDL المقترح (ملف واحد، قابل للتراجع)

```sql
-- 1) منع الإرسال المزدوج (F1). يُنفَّذ بعد فحص التكرارات.
CREATE UNIQUE INDEX UX_PROVIDERS_DTL_PROV_SVC
    ON PROVIDERS_DTL (PROVIDER_ID, SERVICE_ID) ONLINE;

-- 2) تفرّد اسم المزود (اختياري لكنه يمنع «EngazSoft» مرتين)
CREATE UNIQUE INDEX UX_PROVIDERS_NAME ON PROVIDERS (PROVIDER_NAME) ONLINE;

-- 3) تسلسلات اختيارية (D3-ب). لا تُغيَّر أي أداة قائمة:
CREATE SEQUENCE SEQ_PROVIDERS     START WITH 3  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_PROVIDERS_DTL START WITH 6  INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER TRG_PROVIDERS_BI
BEFORE INSERT ON PROVIDERS FOR EACH ROW
BEGIN
  IF :NEW.PROVIDER_ID IS NULL THEN
    -- اسم التسلسل غير مؤهَّل داخل PL/SQL: يوجد VIEW اسمه ACCOUNTS داخل مخطط ACCOUNTS
    SELECT SEQ_PROVIDERS.NEXTVAL INTO :NEW.PROVIDER_ID FROM DUAL;
  END IF;
END;
/

CREATE OR REPLACE TRIGGER TRG_PROVIDERS_DTL_BI
BEFORE INSERT ON PROVIDERS_DTL FOR EACH ROW
BEGIN
  IF :NEW.ID IS NULL THEN
    SELECT SEQ_PROVIDERS_DTL.NEXTVAL INTO :NEW.ID FROM DUAL;
  END IF;
END;
/
```

> إن رفض المستخدم لمس الجداول القديمة (وهو خيار مشروع)، فالبديل في التطبيق: `MAX(ID)+1` داخل معاملة
> واحدة مع إعادة المحاولة ثلاث مرات عند `ORA-00001`. يُوثَّق الاختيار في `db_commends.md` إما/أو.

**فحص ما قبل التنفيذ:**

```sql
SELECT PROVIDER_ID, SERVICE_ID, COUNT(*) FROM PROVIDERS_DTL
 GROUP BY PROVIDER_ID, SERVICE_ID HAVING COUNT(*) > 1;   -- يجب أن يعود فارغاً

SELECT * FROM SESSION_PRIVS WHERE PRIVILEGE IN ('CREATE JOB','CREATE ANY JOB','MANAGE SCHEDULER');
-- متحقق: الثلاثة متاحة لحساب ACCOUNTS (عبر دور DBA) — لازمة لشاشة المهام.
```

---

## 6. الصلاحيات

### 6.1 الوحدات الجديدة (5 وحدات، 26 كوداً)

| الوحدة | العنوان العربي | عدد الأكواد | لماذا وحدة مستقلة |
|---|---|---|---|
| `providers` | المزودون | 6 + منح عام | بيانات اعتماد التجّار |
| `sms` | الرسائل النصية | 4 + منح عام | تشغيل قناة قديمة حساسة |
| `whatsapp` | رسائل واتساب | 4 + منح عام | قناة أحدث وأكثر عرضة للأعطال |
| `jobs` | مهام الإرسال | 5 + منح عام | الأخطر: توقيف إرسال الشركة |
| `service_settings` | إعدادات الخدمات | 2 + منح عام | تعديل هوية الشركة عند الإرسال |

### 6.2 جدول الأكواد الكامل (يُضاف إلى `PermissionCatalog::MODULES` ومرآته)

| الكود | الاسم العربي | يحمي |
|---|---|---|
| `providers.view` | عرض المزودين والاشتراكات | قوائم المزودين |
| `providers.create` | إضافة مزود | `POST /providers` |
| `providers.update` | تعديل مزود | `PUT /providers/{id}` |
| `providers.delete` | حذف مزود | `DELETE /providers/{id}` |
| `providers.toggle` | تفعيل أو تعطيل مزود | `PATCH .../toggle` |
| `providers.credentials_manage` | إدارة بيانات اعتماد المزود | كتابة `PASSWORD` في `PROVIDERS` |
| `sms.view` | عرض قنوات SMS وسجل رسائلها | قنوات SMS + السجل |
| `sms.manage` | إضافة وتعديل قنوات SMS | كتابة `PROVIDERS_DTL` لخدمات SMS |
| `sms.retry` | إعادة إرسال رسالة SMS | إعادة الإرسال/تحرير العالقة |
| `sms.export` | تصدير سجل SMS | CSV |
| `whatsapp.view` | عرض قنوات واتساب وسجل رسائلها | نفسها لقناة واتساب |
| `whatsapp.manage` | إضافة وتعديل قنوات واتساب | كتابة قناة `SERVICE_TYPE='WHATSAPP'` |
| `whatsapp.retry` | إعادة إرسال رسالة واتساب | إعادة الإرسال |
| `whatsapp.export` | تصدير سجل واتساب | CSV |
| `jobs.view` | عرض المهام وحالتها | قائمة المهام |
| `jobs.manage` | تعديل جدولة المهام وتفعيلها | `PUT` + `toggle` |
| `jobs.run` | تشغيل مهمة فوراً | `RUN_JOB` (يرسل فعلاً!) |
| `jobs.delete` | حذف مهام التطبيق | مهام `KY_*` فقط |
| `jobs.log_view` | عرض سجل تشغيل المهام | تفاصيل التشغيل والأخطاء |
| `service_settings.view` | عرض إعدادات الخدمات | `CORP` + `SERVICES` |
| `service_settings.update` | تعديل إعدادات الخدمات | كتابة `CORP` |

**العدد النهائي:** 21 كوداً صريحاً + 5 منح عامة = **26 صفاً**. الكتالوج: 97 → **123**، والأقسام 18 → **23**.

**ترتيب `SORT_ORDER`:** تُضاف الوحدات الخمس **بين `app_config` و`system`**، فتحتفظ الوحدات القائمة
بأرقامها ولا يتغيّر إلا `system`.

**العناوين في مرآة العميل** (`permission_codes.dart`): `permModuleOrder` + `permModuleLabels` +
أفعال جديدة في `permActionLabels`: `manage` → «إدارة»، `retry` → «إعادة إرسال»، `run` → «تشغيل فوري»،
`log_view` → «سجل التشغيل»، `credentials_manage` → «بيانات الاعتماد».

### 6.3 خريطة المسار → الكود (تُغذّي `BusinessRoutesSealedTest`)

| المجموعة | المسارات | الكود |
|---|---|---|
| المزودون | 6 مسارات CRUD/toggle + قائمة اشتراكات | `providers.*` كما في §6.2 |
| قنوات SMS | 5 | `sms.manage` (والقراءة `sms.view`) |
| رسائل SMS | قائمة/تفاصيل/تصدير | `sms.view` / `sms.export` |
| إعادة إرسال SMS | 1 | `sms.retry` |
| قنوات واتساب | 5 | `whatsapp.manage` / `whatsapp.view` |
| رسائل واتساب | 3 + إعادة إرسال | `whatsapp.view` / `whatsapp.export` / `whatsapp.retry` |
| المهام | قائمة | `jobs.view` |
| | سجل التشغيل | `jobs.log_view` |
| | تعديل/تفعيل | `jobs.manage` |
| | تشغيل فوري | `jobs.run` |
| | إنشاء/حذف | `jobs.manage` / `jobs.delete` |
| الإعدادات | قراءة/كتابة/كتالوج | `service_settings.view` / `service_settings.update` |

كل مسار يحمل `auth:sanctum` + `permission:<code>` صريحاً — لا استثناء، لأن اختبار الحماية يمرّ على
`routes/api.php` ويتأكد أن كل مسار غير عام يحمل حارساً.

### 6.4 أثر على الكاش (يجب قياسه لا افتراضه)

`PermissionResolver::MAX_CACHE_BYTES = 3000`، وتجاوزها **لا يُفشل الطلب** بل يتخطى الكاش ويقرأ من
القاعدة كل مرة. إضافة 26 كوداً تدفع المستخدم الممنوح بالكتالوج كاملاً فوق الحد ⇒ كل طلب مصادَق يصير
استعلاماً إضافياً. الإجراء: قياس `strlen(serialize($codes))` لمستخدم كامل الصلاحيات قبل/بعد، وتوثيق
النتيجة. إن تجاوزت 3000 بفارق كبير يُرفع الحد إلى 3500 (> 4000 ممنوع: `ORA-01461`).

---

## 7. واجهات API

### 7.1 المبادئ

- غلاف موحّد: `{success, message, data, meta}`، وأخطاء `{success:false, message, errors:{}}`.
- ترقيم يدوي: `page` / `limit` (سقف 100)، و`meta = {total, page, limit, pages}` — نمط
  `Customer/AdminUsers` لا نمط `Account/Currency`.
- كل الاستعلامات مربوطة، وكل اسم مهمة يُفحص بقائمة بيضاء قبل أي نداء `DBMS_SCHEDULER`.
- منع الأسرار (D1) في كل استجابة وسجل.
- `404` صريح عند غياب الصف، `409` عند رفض الحذف لوجود مراجع، `422` للأخطاء الحقلية.

### 7.2 جدول المسارات (35 مساراً)

| # | المسار | الطريقة | الصلاحية | الوظيفة |
|---|---|---|---|---|
| 1 | `/services/providers` | GET | `providers.view` | قائمة + بحث + تصفية حالة |
| 2 | `/services/providers/{id}` | GET | `providers.view` | تفاصيل مزود |
| 3 | `/services/providers` | POST | `providers.create` | إضافة |
| 4 | `/services/providers/{id}` | PUT | `providers.update` | تعديل |
| 5 | `/services/providers/{id}/toggle` | PATCH | `providers.toggle` | تفعيل/تعطيل |
| 6 | `/services/providers/{id}` | DELETE | `providers.delete` | حذف (409 إن ارتبط باشتراك أو تاريخ رسائل) |
| 7 | `/services/providers/{id}/subscriptions` | GET | `providers.view` | اشتراكات المزود (قراءة) |
| 8 | `/services/sms/channels` | GET | `sms.view` | قنوات SMS |
| 9 | `/services/sms/channels` | POST | `sms.manage` | إضافة قناة |
| 10 | `/services/sms/channels/{id}` | PUT | `sms.manage` | تعديل |
| 11 | `/services/sms/channels/{id}/toggle` | PATCH | `sms.manage` | تفعيل/تعطيل |
| 12 | `/services/sms/channels/{id}` | DELETE | `sms.manage` | حذف (409 إن كان هناك رسائل معلّقة مرتبطة) |
| 13 | `/services/sms/messages` | GET | `sms.view` | السجل + التبويبات + `meta.counts` |
| 14 | `/services/sms/messages/{id}` | GET | `sms.view` | تفاصيل |
| 15 | `/services/sms/messages/{id}/retry` | POST | `sms.retry` | تحرير عالقة / إعادة إرسال مؤرشفة |
| 16 | `/services/sms/messages/export` | GET | `sms.export` | CSV (سقف 5000 صف) |
| 17–25 | `/services/whatsapp/...` | نفس البنية | `whatsapp.*` | قنوات + سجل + تفاصيل + إعادة + تصدير |
| 26 | `/services/jobs` | GET | `jobs.view` | المهام الثلاث + الصحة |
| 27 | `/services/jobs/{jobName}/runs` | GET | `jobs.log_view` | سجل التشغيل (نافذة زمنية إلزامية) |
| 28 | `/services/jobs/{jobName}/toggle` | PATCH | `jobs.manage` | ENABLE/DISABLE |
| 29 | `/services/jobs/{jobName}` | PUT | `jobs.manage` | الجدولة + المهلة |
| 30 | `/services/jobs/{jobName}/run` | POST | `jobs.run` | RUN_JOB |
| 31 | `/services/jobs` | POST | `jobs.manage` | إنشاء من قالب معتمد باسم `KY_*` |
| 32 | `/services/jobs/{jobName}` | DELETE | `jobs.delete` | حذف مهام `KY_*` فقط |
| 33 | `/services/settings` | GET | `service_settings.view` | `CORP` + كتالوج `SERVICES` |
| 34 | `/services/settings` | PUT | `service_settings.update` | كتابة `CORP` |
| 35 | `/services/catalog` | GET | `service_settings.view` | `SERVICES` + صفوف يتيمة |

### 7.3 أمثلة حمولات

**`GET /services/providers?page=1&limit=20`**

```json
{
  "success": true,
  "data": [
    {
      "provider_id": 1,
      "provider_name": "EngazSoft",
      "type": "URL",
      "url": "http://185.11.8.51/engazsms/?",
      "status": 1,
      "subscriptions_count": 3,
      "credentials_configured": true,
      "updated_at": null
    }
  ],
  "meta": { "total": 2, "page": 1, "limit": 20, "pages": 1 }
}
```

**`GET /services/sms/messages?status=failed&page=1`**

```json
{
  "success": true,
  "data": [
    {
      "id": 28698,
      "source": "archive",
      "status": "failed",
      "mobile_no": "770498342",
      "message_text": "عزيزنا العميل، كرتكم جاهز",
      "customer_name": null,
      "provider_id": 1,
      "service_id": 1,
      "send_attempt": 3,
      "attempt_limit": 3,
      "can_retry": true,
      "created_at": "2026-10-20 09:14:02",
      "updated_at": "2026-10-20 09:15:40"
    }
  ],
  "meta": {
    "total": 82, "page": 1, "limit": 50, "pages": 2,
    "counts": { "all": 22802, "sent": 22720, "pending": 0, "failed": 82 }
  }
}
```

**`GET /services/jobs`**

```json
{
  "success": true,
  "data": [
    {
      "job_name": "W_SEND_MSG",
      "label": "إرسال رسائل واتساب",
      "channel": "whatsapp",
      "enabled": true,
      "state": "SCHEDULED",
      "interval_human": "كل 20 ثانية",
      "repeat_interval": "FREQ=SECONDLY;INTERVAL=20;BYDAY=SAT,MON,TUE,WED,THU,FRI,SUN",
      "job_action": "begin\nSendWhatsappAPI.push_queue;\nend;",
      "last_start": "2026-10-23 00:04:50",
      "next_run": "2026-10-23 00:05:10",
      "run_count": 84802,
      "failure_count": 234,
      "last_status": "FAILED",
      "health": "warn",
      "protected": true
    }
  ]
}
```

**`PATCH /services/jobs/SEND_MSG/toggle`** → `{"enabled": false}` ثم تنفيذ
`BEGIN DBMS_SCHEDULER.DISABLE(name => :n); END;`

**`PUT /services/jobs/SEND_MSG`**

```json
{ "every": 5, "unit": "seconds", "days": ["SAT","SUN","MON","TUE","WED","THU","FRI"], "max_run_minutes": 2 }
```

**`GET /services/settings`**

```json
{
  "success": true,
  "data": {
    "corp_name": "مركز الكبودي للخياطة",
    "corp_addr": "خُط المطار جوار بيت الشايف",
    "corp_tel1": "777430907",
    "corp_tel2": null,
    "file_path": null,
    "sanf_type": 2,
    "brand_company_name": "الكبودي للخياطة الرجالية",
    "name_mismatch": true,
    "services": [
      { "service_id": 1, "service_name": "SMS BY URL", "service_type": "URL", "channels": 1 },
      { "service_id": 2, "service_name": "SMS BY FIREBASE", "service_type": "FIREBASE", "channels": 1 },
      { "service_id": 3, "service_name": "SMS BY WHATSAPP", "service_type": "WHATSAPP", "channels": 1 }
    ],
    "orphan_subscriptions": [
      { "id": 4, "provider_id": 1, "service_id": 4, "status": 1 },
      { "id": 5, "provider_id": 1, "service_id": 5, "status": 1 }
    ]
  }
}
```

### 7.4 قواعد التحقق (422)

| الحقل | القاعدة |
|---|---|
| `provider_name` | مطلوب، 2–250، بلا رموز تحكم |
| `type` | `in:URL,FIREBASE,WHATSAPP,API` |
| `url` | `nullable|url|max:1000` — ويُقبل `#USERNAME#` ورفاقها كقوالب في URL الاشتراك |
| `user_name` | `nullable|max:80` (و1000 في الاشتراك) |
| `password` | `nullable|max:250` — غيابه يعني «اترك الحالي»، والمسح يتم بعَلَم `clear_secret` منفصل |
| `service_id` | `exists:SERVICES` (فحص استعلام لأن Oracle بلا FK) |
| `send_attempt_cnt` | `integer|min:0|max:20` |
| `sent_archive` | `boolean` |
| `status` | `in:0,1` |
| `corp_tel1/2` | `nullable|digits_between:6,10` |
| `every` | `integer|min:1|max:3600` |
| `jobName` | `^[A-Z][A-Z0-9_]{0,29}$` **و** موجود في القائمة البيضاء |

---

## 8. تطبيق Flutter

### 8.1 البنية والملفات

```
lib/features/services/
├── data/
│   ├── models/
│   │   ├── provider_model.dart              ← fromJson/toJson/copyWith + _parseInt/_parseString
│   │   ├── service_channel_model.dart       ← صف PROVIDERS_DTL + اسم الخدمة ونوعها
│   │   ├── message_log_model.dart           ← صف موحّد للطابور/الأرشيف
│   │   ├── message_page_model.dart          ← data + meta.counts
│   │   ├── scheduled_job_model.dart
│   │   ├── job_run_model.dart
│   │   └── corp_settings_model.dart
│   └── repositories/
│       ├── providers_repository.dart
│       ├── sms_repository.dart
│       ├── whatsapp_repository.dart
│       ├── jobs_repository.dart
│       └── service_settings_repository.dart
└── presentation/
    ├── providers/
    │   ├── providers_notifier.dart
    │   ├── channels_notifier.dart
    │   ├── message_log_notifier.dart        ← واحد بمعامل MessagingKind
    │   ├── jobs_notifier.dart
    │   └── service_settings_notifier.dart
    ├── screens/
    │   ├── services_hub_screen.dart
    │   ├── providers_list_screen.dart
    │   ├── provider_form_screen.dart
    │   ├── provider_subscriptions_screen.dart
    │   ├── messaging_screen.dart            ← تبويبان: القنوات | السجل (SMS/WA)
    │   ├── message_detail_screen.dart
    │   ├── jobs_screen.dart
    │   ├── job_schedule_screen.dart
    │   ├── job_runs_screen.dart
    │   └── service_settings_screen.dart
    └── widgets/
        ├── provider_card.dart
        ├── channel_card.dart
        ├── message_tile.dart
        ├── message_status_badge.dart
        ├── job_card.dart
        ├── health_pill.dart
        └── secret_field.dart
```

**الالتزامات المتوارثة:** `Notifier` + `NotifierProvider`، `Future.microtask` في `build()`، `CancelToken`
يُلغى عند dispose، بحث بـ`_searchVersion` وتأخير 300 مللي، `copyWith` بغلاف للقيم القابلة للصفر،
`ArabicEncodingUtils.fix()` على كل نص عربي، وقراءة مزدوجة الحالة للمفاتيح (`json['PROVIDER_NAME'] ?? json['provider_name']`).

### 8.2 الشاشات

**1) `services_hub_screen.dart`** — واجهة القسم.
شريط علوي: عنوان + حالة مختصرة. خمس بطاقات (تُبنى فقط إن ملك المستخدم كودها):
المزودون (عدد النشطين) · الرسائل النصية (شارة عدّاد المنتظرة والعالقة) · واتساب (نفسه) · مهام الإرسال
(أخضر/كهرماني/أحمر) · إعدادات الخدمات.
البطاقات تُحمّل عدّاداتها بشكل مستقل، فلا تعطّل بطاقةٌ فاشلة بقية الشاشة.

**2) `providers_list_screen.dart`**
بحث (اسم/URL) + تصفية (الكل/نشط/معطّل) + ترتيب. جدول على سطح المكتب، بطاقات على الجوال.
أعمدة: الاسم، النوع، الحالة، عدد الاشتراكات، آخر تحديث. إجراءات: تعديل، تعطيل، حذف، «الاشتراكات».

**3) `provider_form_screen.dart`**
الاسم، النوع (قائمة)، URL، المستخدم، السر (`SecretField`: «اتركه فارغاً للإبقاء على الحالي»)، الحالة.
تحذير عند الحفظ إن كان المزود مستخدماً في قناة نشطة.

**4) `provider_subscriptions_screen.dart`**
صفوف `PROVIDERS_DTL` الخاصة بالمزود مع اسم الخدمة ونوعها. كل صف: الحالة، عدد المحاولات، الأرشفة،
وجود سر/توكن. الصفوف اليتيمة تُعرض بوسم أحمر «خدمة غير معروفة (#4)» بلا إجراءات تعديل.

**5) `messaging_screen.dart`** — تُستدعى بـ`MessagingKind.sms` أو `.whatsapp`.
تبويب «القنوات»: بطاقات القناة (المزود، الخدمة، الحالة، المحاولات، الأرشفة) + إضافة/تعديل/تعطيل/حذف.
تبويب «السجل»: شرائح الحالة الأربع + بحث (رقم/اسم عميل/نص) + نطاق تاريخ + قائمة لا نهائية/صفحات.
شارة كل شريحة من `meta.counts`. لكل صف: الرقم، مقتطف النص، الحالة، الزمن، المحاولات.

**6) `message_detail_screen.dart`**
النص الكامل (بعد الإصلاح)، الرقم، المزود/الخدمة، المحاولات والحد، التواريخ، ورسالة الخطأ (واتساب فقط)،
والمرفق (اسم/نوع). زر «إعادة إرسال» يظهر فقط عند `can_retry` وملك `*.retry`، مع حوار تأكيد يشرح:
«ستُنشأ رسالة جديدة وقد يصل العميل إشعاران إن كانت الأولى قد وصلت».

**7) `jobs_screen.dart`**
ثلاث بطاقات. لكل مهمة: الاسم العربي، الحالة، «كل 3 ثوانٍ»، آخر تشغيل، التالي، التشغيلات، الإخفاقات،
آخر حالة. أزرار: تفعيل/تعطيل، الجدولة، تشغيل الآن، السجل، حذف (معطّل للمهام المحمية).
حوار تأكيد قبل التعطيل/التشغيل يذكر الأثر: «سيتوقف إرسال كل رسائل SMS حتى تُعيد التفعيل».

**8) `job_schedule_screen.dart`**
`every` + الوحدة (ثانية/دقيقة/ساعة) + أيام الأسبوع + المهلة القصوى بالدقائق.
معاينة نصية لـ`REPEAT_INTERVAL` الناتج قبل الحفظ. حقل الأمر `JOB_ACTION` **معروض للقراءة فقط**.

**9) `job_runs_screen.dart`**
مرشّح زمني إلزامي (آخر ساعة/24 ساعة/7 أيام/مخصص) + تصفية بالحالة + ترقيم. أعمدة: الوقت، الحالة، المدة،
رمز الخطأ، نص الخطأ. تنبيه ثابت: العدد كبير (≈21 ألف صف يومياً لـ`SEND_MSG`).

**10) `service_settings_screen.dart`**
نموذج `CORP` (الاسم، العنوان، الهاتف 1/2، مسار الملف) + `SANF_TYPE` للقراءة فقط + بطاقة تحذير:
«هذه القيم يقرأها محرك واتساب مباشرة». جدول `SERVICES` للقراءة + قسم «اشتراكات يتيمة» إن وُجدت.
شريط فروق الاسم بين `CORP` و`app_config` مع زر مزامنة اختياري.

### 8.3 الحالات الأربع (إلزامية لكل شاشة بيانات)

| الحالة | التمثيل |
|---|---|
| تحميل | هيكل عظمي/مؤشر مع تعطيل الإجراءات |
| نجاح | القائمة |
| فارغ | نص يشرح **السبب** (لا يوجد مزودون بعد / لا رسائل في هذا التصنيف) + إجراء مقترح |
| خطأ | الرسالة + «إعادة المحاولة» + رمز الطلب إن وُجد |

### 8.4 RTL والخط والأحجام

- `Directionality` تأتي من `MaterialApp` (ar_SA)؛ لا تُفرض محلياً.
- لا ألوان جديدة داخل الودجات: تُضاف الحالات إلى `AppColors` (مثلاً `success/warning/danger` إن لم تكن موجودة).
- `Responsive.isMobile(context)` للتبديل بين البطاقات والجدول؛ نقطة إضافية محلية عند 600px للجداول العريضة.
- `MediaQuery.sizeOf` و`color.withValues` و`WidgetStateProperty` (لا الصيغ المهجورة).
- احترام تقييد مقياس النص 0.85–1.25 القائم في `KyApp` — لا تُبنى صفوف بأطوال ثابتة.

### 8.5 إدارة الحالة

- `providersNotifierProvider` (NotifierProvider) — قائمة + تصفية + بحث.
- `channelsProvider(kind)` — عائلة `NotifierProvider.family` أو نافذتان منفصلتان.
- `messageLogProvider(MessagingQuery)` — يجب أن يكون المفتاح قابلاً للمقارنة (`==`/`hashCode`) وإلا أُعيد البناء بلا داعٍ.
- `jobsProvider` + مؤقّت تحديث اختياري كل 30 ثانية أثناء فتح الشاشة فقط (يُلغى عند dispose).
- `serviceSettingsProvider`.

---

## 9. التكامل مع البوابة والرئيسية

### 9.1 سجل الأقسام

في `lib/features/employee_portal/domain/portal_sections.dart` يُضاف بعد `stores` وقبل `management`:

```dart
PortalSection(
  id: 'services',
  title: PortalSectionTitles.services,
  icon: Icons.hub_outlined,
  selectedIcon: Icons.hub_rounded,
  builder: _buildServices,
  viewCodes: [
    Perm.providersView,
    Perm.smsView,
    Perm.whatsAppView,
    Perm.jobsView,
    Perm.serviceSettingsView,
  ],
),
```

- `showInBottomBar` تبقى `false` (الشريط خمسة، والاختبار يثبّت ذلك).
- `PortalSectionTitles.services = 'الخدمات والمزودين'` + حالة في `of()`.
- `_buildServices` دالة عليا تُعيد `ServicesHubScreen` (نمط `management_section.dart`).
- `lib/features/employee_portal/presentation/screens/sections/services_section.dart` ملف رقيق يعيد التوجيه.

### 9.2 اختصارات الرئيسية

خمسة إدخالات في `home_shortcut_catalog.dart`:

| id | العنوان | الهدف | الأكواد |
|---|---|---|---|
| `services.section` | الخدمات والمزودين | `SectionTarget('services')` | **نفس** قائمة `viewCodes` حرفياً |
| `services.providers` | المزودون | `ScreenTarget(ProvidersListScreen.new)` | `providers.view` |
| `services.sms` | الرسائل النصية | `buildSmsMessagingScreen` | `sms.view` |
| `services.whatsapp` | رسائل واتساب | `buildWhatsappMessagingScreen` | `whatsapp.view` |
| `services.jobs` | مهام الإرسال | `ScreenTarget(JobsScreen.new)` | `jobs.view` |

- لا `defaultOn` لأي منها (يبقى عدّ الافتراضيات 13 كما يثبّته الاختبار).
- `SectionTarget` يحمل أكواد السجل حرفياً — قاعدة يفرضها `test/home_catalog_test.dart`.
- الشاشات تُفتح بـ`Navigator.push` كبقية الأقسام، لا مسارات جديدة في `app_router.dart`.

---

## 10. الأمان

| # | الخطر | الضابط |
|---|---|---|
| T1 | كشف أسرار المزودين | لا تُعاد في أي استجابة؛ `credentials_configured` فقط؛ السجل لا يطبع الحمولة؛ `selectFromTable` يحجبها أصلاً |
| T2 | تنفيذ PL/SQL عبر شاشة المهام | قائمة أسماء بيضاء + قوالب مغلقة + `JOB_ACTION` للقراءة فقط + فحص `^[A-Z][A-Z0-9_]{0,29}$` |
| T3 | تعطيل/حذف مهمة حرجة | صلاحية `jobs.manage` مستقلة، حوار تأكيد، حماية `SEND_MSG`/`W_SEND_MSG`/`W_SEND_MSG_F` من الحذف |
| T4 | إرسال مزدوج | فهرس فريد + تحقق تطبيقي + رفض 409 |
| T5 | تلف العربية عند الكتابة | `toOracleSearchChars` حصراً + اختبار كتابة/قراءة على `CORP` |
| T6 | تزوير مدخلات SQL | binds في كل استعلام، وأسماء الجداول/المهام من ثوابت لا من الطلب |
| T7 | حساب القاعدة يملك DBA | لا يُصلَح في هذه المرحلة، لكنه يُوثَّق: أي ثغرة في الـAPI تعني القاعدة كلها. المسار الآمن لاحقاً: مستخدم قاعدة بأقل صلاحية (`CREATE JOB` + DML على الجداول المعنية) |
| T8 | تسريب أرقام العملاء في التصدير | `*.export` صلاحية مستقلة + سجل نشاط عبر `ActivityLogger` عند كل تصدير |

**سجل النشاط:** كل عملية كتابة (مزود، قناة، إعدادات، مهمة، إعادة إرسال) تُسجَّل بـ`ActivityLogger`
(`USER_ID`, `ACTION_TYPE`, `DESCRIPTION_AR`, `STATUS`) — نفس نمط `UserAdminController`.

---

## 11. الاختبارات

### 11.1 Flutter

| الملف | التغطية |
|---|---|
| `test/services_models_test.dart` (جديد) | `fromJson` بمفاتيح UPPER وحقول رقمية كنصوص (`'7'`)، وتصحيح mojibake، و`copyWith` |
| `test/services_status_test.dart` (جديد) | خريطة الحالة: طابور/أرشيف/عالقة/`F`/`NV` — بلا شبكة |
| `test/ibac_test.dart` (توسيع) | الأكواد الجديدة موجودة في المرآة، كل وحدة لها عنوان وwildcard، الترتيب مطابق، لا تكرار |
| `test/responsive_layout_test.dart` (توسيع) | رسم الشاشات الجديدة على 360×640 و1280×800 والتأكد `takeException() == null` |
| `test/home_catalog_test.dart` (قائم) | يمرّ كما هو إن لم نضف `defaultOn`؛ ويُضاف تحقق أن `services.section` تحمل أكواد السجل |

### 11.2 Laravel (Pest 3)

| الملف | التغطية | ملاحظة |
|---|---|---|
| `tests/Feature/IbacCoreTest.php` (تحديث) | `PermissionCatalog::count() === 123` + تعليق يشرح الفرق | تعديل مشروع: الرقم ثابتة كتالوج لا اختبار مُضعَّف |
| `tests/Feature/ProviderRoutesTest.php` | 401 بلا توكن، 403 بكود ناقص، 422 للحقول، 409 لحذف مرتبط، **وأن `password` لا يظهر في الاستجابة** | كتابة مزود تجريبي على القاعدة الحيّة ممنوعة: تُختبر مسارات الرفض فقط |
| `tests/Feature/MessagingLogRoutesTest.php` | 401/403، تحقق أن `status` غير المعروف يعطي 422، وشكل الاستجابة على بيانات قائمة | قراءة فقط |
| `tests/Unit/MessageStatusTest.php` | بناء شرط الحالة (SQL fragment) لكل تبويب بلا قاعدة | |
| `tests/Feature/JobsRoutesTest.php` | رفض أي اسم خارج القائمة البيضاء (422) قبل أي DDL، ورفض `DELETE SEND_MSG` بـ409 | لا إنشاء/حذف فعلي في الاختبار |
| `tests/Feature/ServiceSettingsTest.php` | 401/403 و422 على الهاتف/الاسم | **لا** يُختبر الحفظ على `CORP` الحقيقي |
| `tests/Feature/BusinessRoutesSealedTest.php` (قائم) | يتحقق تلقائياً أن كل مسار جديد يحمل `permission:` | يجب أن يمرّ بلا تعديل |

### 11.3 فحص يدوي (مصفوفة القبول)

1. مستخدم بلا أي كود من الخدمات: القسم غير موجود في الدرج، والرئيسية بلا بطاقات، والمسارات 403.
2. مستخدم بـ`sms.view` فقط: يرى القسم وبطاقة SMS، ولا يرى أزرار الإضافة/الإعادة.
3. تعطيل `SEND_MSG` ثم إرسال رسالة تجريبية: تتوقف، والعدّاد يظهر معطّلاً، ثم يُعاد التفعيل.
4. رسالة عالقة (بمحاولات ≥ الحد): تظهر تحت «الفاشلة» بوسم عالقة، و«إعادة الإرسال» تعيدها للطابور.
5. عربي في `CORP`: يُحفظ ويُقرأ سليماً في الشاشة وفي `GET_COMPANY_DETAILS`.
6. `W_SEND_MSG` بحالة فشل: تظهر كهرمانية في البطاقة، وسجل التشغيل يعرض `ORA-04063` بنصه.

---

## 12. المراحل ومعايير القبول

| المرحلة | العمل | المخرجات | معيار القبول | التقدير |
|---|---|---|---|---|
| **0** | اعتماد القرارات D1–D8 + إجابة §14 | هذه الوثيقة موقّعة | لا بند مفتوح يمنع البدء | 0.5 يوم |
| **1** | كتالوج الصلاحيات: `PermissionCatalog` + `permission_codes.dart` + سكربت البذر `06_services_permissions.php` + التراجع | 123 كوداً في القاعدة والمرآة | `SELECT COUNT(*) FROM APP_PERMISSIONS` = 123، واختبار التطابق يمرّ | 1 يوم |
| **2** | أساس الخادم: `Support/MessageStatus`، `Support/SchedulerJobs`، `Support/ServiceChannel`، تسجيل المسارات | مسارات محمية تُعيد 403/401 صحيحاً | `BusinessRoutesSealedTest` يمرّ | 1.5 يوم |
| **3** | API المزودين والاشتراكات | 7 مسارات | 401/403/422/409 مؤكدة، ولا سر في أي استجابة | 2 يوم |
| **4** | API الرسائل (SMS + واتساب) مع التبويبات والتصدير وإعادة الإرسال | 18 مساراً | عدّادات `meta.counts` مطابقة لاستعلام يدوي على القاعدة | 3 أيام |
| **5** | API المهام + سجل التشغيل | 7 مسارات | رفض الأسماء غير المصرح بها قبل أي نداء Scheduler | 2 يوم |
| **6** | API الإعدادات + الكتالوج | 3 مسارات | حفظ `CORP` يعيد العربية سليمة | 1 يوم |
| **7** | طبقة بيانات Flutter (نماذج/مستودعات/مزوّدات) | الملفات + اختبارات النماذج | `flutter analyze` نظيف | 2 يوم |
| **8** | الشاشات العشر + الودجات | واجهة كاملة | الحالات الأربع في كل شاشة، بلا overflow | 5 أيام |
| **9** | التكامل: السجل + الرئيسية + شاشة المنح | القسم يظهر ويُحجب صحيحاً | سيناريوهات §11.3 (1) و(2) | 1 يوم |
| **10** | الاختبارات والضبط | كل الاختبارات خضراء | `flutter analyze` + `flutter test` + `pest` + `pint` | 2.5 يوم |
| **11** | التوثيق والتسليم | تحديث `devloping_history.md` و`db_commends.md` و`AGENTS.md` (عدد الأقسام/الأكواد) | مراجعة نهائية | 1 يوم |

**الإجمالي:** 18–22 يوم عمل. المراحل 1–6 خادم، 7–9 عميل، ويمكن تنفيذ 3–6 بالتوازي مع 7–8 بعد المرحلة 2.

---

## 13. المخاطر والمزالق

| # | الخطر | الاحتمال | الأثر | التخفيف |
|---|---|---|---|---|
| R1 | تعديل مهمة إرسال أثناء ذروة العمل يوقف رسائل | متوسط | عالٍ | حوار تأكيد + سجل نشاط + إمكانية الرجوع بالقيم القديمة المعروضة |
| R2 | تعارض كتابة `CORP` مع برنامج قديم يقرأه | منخفض | متوسط | تحرير حقول محددة فقط، و`UPDATE` بلا `INSERT` |
| R3 | فهرس فريد يفشل لوجود تكرار | منخفض | متوسط | فحص مسبق إلزامي في §5.3 |
| R4 | بطء سجل التشغيل | عالٍ إن أُهمل | متوسط | نافذة زمنية إلزامية + `ROW_NUMBER` + سقف 50 صفاً |
| R5 | توقف الكاش عن العمل بعد 26 كوداً | متوسط | منخفض | قياس وتوثيق (§6.4) |
| R6 | اختلاف معنى `PASSWORD` بين المزود والقناة | متوسط | عالٍ | تسمية الحقل في واجهة واتساب «معرّف الجلسة (SESSION_ID)» مع تلميح |
| R7 | صفوف يتيمة تُربك المستخدم | مؤكد | منخفض | وسم صريح + قرار D4 |
| R8 | اختبارات Pest على قاعدة حيّة تُفسد بيانات | منخفض | عالٍ | كل اختبارات الكتابة ممنوعة؛ الرفض فقط |

---

## 14. قرارات مطلوبة من المستخدم

| # | السؤال | التوصية |
|---|---|---|
| **D1** | حذف المهام الثلاث القديمة من الواجهة: ممنوع أم مسموح بتأكيد مزدوج؟ | **ممنوع** (409). الحذف لمهام `KY_*` فقط |
| **D2** | تعديل `JOB_ACTION` نصياً من الواجهة؟ | **ممنوع**. قوالب مغلقة فقط |
| **D3** | تسلسلات + triggers على `PROVIDERS`/`PROVIDERS_DTL`، أم `MAX+1` مع إعادة محاولة؟ | التسلسلات (تصلح C6) — تحتاج موافقة لأنها DDL على جدولين قديمين |
| **D4** | الصفان اليتيمان 4 و5: تُضاف خدمتان 4 و5 إلى `SERVICES`، أم يُحذف الصفان؟ | تُحذف الصفوف إن كانتا تجربتين؛ وإلا تُضاف الخدمتان بنوعيهما |
| **D5** | `CORP` مقابل اسم الشركة في `APP_SETTINGS`: أيّهما يُعتمد؟ | `CORP` للإرسال، و`APP_SETTINGS` للعرض، مع إظهار الفرق ومزامنة يدوية |
| **D6** | إضافة «إنشاء رسالة» (composer) الآن؟ | لاحقاً — مرحلة مستقلة بعد استقرار السجل |
| **D7** | هل يُسمح لغير المدير برؤية سجل الرسائل كاملاً (أرقام العملاء)؟ | `sms.view` تمنحه؛ وإن كانت الخصوصية مطلوبة يُضاف `sms.log_view` منفصل |

---

## 15. ملاحق

### 15.1 استعلامات تحقق سريعة (قبل وبعد)

```sql
-- عدّادات الحالة الفعلية (لا تعتمد على NUM_ROWS)
SELECT 'QUEUE' S, IS_SENT, COUNT(*) FROM MSG_QUEUE  GROUP BY IS_SENT
UNION ALL
SELECT 'ARCHIVE', IS_SENT, COUNT(*) FROM MSG_ARCHIVE GROUP BY IS_SENT;

SELECT IS_SENT, COUNT(*) FROM W_MSG_QUEUE   GROUP BY IS_SENT
UNION ALL
SELECT IS_SENT, COUNT(*) FROM W_MSG_ARCHIVE GROUP BY IS_SENT;

-- الرسائل العالقة (المحاولات استُنفدت وما زالت في الطابور)
SELECT q.ID, q.MOBILE_NO, q.SEND_ATTEMPT,
       (SELECT MAX(d.SEND_ATTEMPT_CNT) FROM PROVIDERS_DTL d
         WHERE d.STATUS = 1
           AND d.PROVIDER_ID = NVL(q.PROVIDER_ID, d.PROVIDER_ID)
           AND d.SERVICE_ID  = NVL(q.SERVICE_ID,  d.SERVICE_ID)) AS ATTEMPT_LIMIT
  FROM MSG_QUEUE q
 WHERE q.IS_SENT = 'N';

-- صحة المهام
SELECT JOB_NAME, ENABLED, STATE, RUN_COUNT, FAILURE_COUNT,
       TO_CHAR(LAST_START_DATE,'YYYY-MM-DD HH24:MI:SS') LAST_START,
       TO_CHAR(NEXT_RUN_DATE ,'YYYY-MM-DD HH24:MI:SS') NEXT_RUN
  FROM USER_SCHEDULER_JOBS
 WHERE JOB_NAME IN ('SEND_MSG','W_SEND_MSG','W_SEND_MSG_F');
```

### 15.2 خريطة الملفات القائمة التي ستُعدَّل

| الملف | التغيير |
|---|---|
| `lib/core/constants/permission_codes.dart` | +26 كوداً، +5 وحدات، +5 أفعال، +5 عناوين |
| `kyApp_API/app/Support/PermissionCatalog.php` | +5 وحدات و21 فعلاً، بترتيب قبل `system` |
| `kyApp_API/database/oracle/06_services_permissions.php` | جديد — بذر idempotent بنمط `02_ibac_seed.php` |
| `kyApp_API/routes/api.php` | +35 مساراً محمياً |
| `kyApp_API/tests/Feature/IbacCoreTest.php` | 97 → 123 |
| `lib/features/employee_portal/domain/portal_sections.dart` | قسم `services` |
| `lib/features/employee_portal/domain/portal_section_titles.dart` | عنوان + حالة |
| `lib/features/employee_portal/presentation/screens/sections/services_section.dart` | جديد |
| `lib/features/home/domain/home_shortcut_catalog.dart` | 5 اختصارات |
| `lib/features/home/domain/home_shortcut_flows.dart` | دالتا فتح SMS/واتساب |
| `test/ibac_test.dart`, `test/responsive_layout_test.dart` | توسيع |
| `AGENTS.md`, `devloping_history.md`, `db_commends.md` | توثيق ما نُفِّذ فعلاً وأرقامه |

### 15.3 ما لا تفعله هذه الخطة (قائمة سلبية صريحة)

- لا `flutter pub add` ولا تبعيات جديدة.
- لا `build_runner` ولا freezed/json_serializable.
- لا مسارات في `app_router.dart` — الشاشات تُدفع بـ`Navigator.push`.
- لا `context.go('/login')` داخل أي شاشة — التوجيه مركزي في `KyApp`.
- لا تعديل على `MSG_QUEUE_TAPI` / `SENDWHATSAPPAPI` / `MSG_ARCHIVE_TAPI`.
- لا `DELETE`/`UPDATE` على جداول ERP (`CUST`, `ENTRY_MAIN`, …).
- لا أسرار في الاستجابات ولا في السجلات.
- لا `git commit` ولا `push` قبل مراجعة المستخدم.
