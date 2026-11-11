# سجل تطوير قاعدة البيانات (Database Development History)

## [2026-09-08 03:50:01] - مهمة إعداد والتحكم برابط Laravel API من واجهة التطبيق
- لم تتطلب هذه المهمة أي تعديلات أو استعلامات على قاعدة بيانات Oracle أو جداول النظام؛ حيث اقتصرت التعديلات على طبقة واجهة تطبيق فلاتر، التخزين المشفر المحلي للعميل (Flutter Secure Storage)، وعميل شبكة HTTP (Dio).

## [2026-09-08 07:44:50] - استعلامات وعمليات قسم العملاء وكشف الحساب في أوراكل
- **الجداول المستخدمة:**
  1. `ACCOUNTS.CUST`: إدارة بيانات العملاء (`CUST_NO`, `CUST_NAME`, `ADDR`, `TEL1`, `TEL2`, `POSTBOX`, `EMAIL`, `FAX`, `ACC_NO`, `LIMITED_BALANCE`, `PRE_CUST_NAME`, `STOPPING_CUST`).
  2. `ACCOUNTS.ENTRY_MAIN`: القيود والفواتير الرئيسية (`ENTRY_NO`, `ENTRY_DATE`, `DETAILS`, `ENTRY_TYPE_NO`).
  3. `ACCOUNTS.ENTRY_SUB`: القيود الفرعية وأرصدة ومبالغ الحركات (`ENTRY_NO`, `ACC_NO`, `ENTRY_MNT`, `BALANCE_S`, `GIVING`).
  4. `ACCOUNTS.ENTRY_TYPE`: أنواع القيود (`ENTRY_TYPE_NO`, `ENTRY_TYPE_NAME`).
- **العمليات المنفذة عبر Laravel Oracle Connection:**
  - `SELECT`: استعلام جلب العملاء والبحث بالاسم أو الرقم مع التصفح.
  - `INSERT`: إضافة عميل جديد وتوليد `CUST_NO` تلقائياً عبر `MAX(CUST_NO) + 1`.
  - `UPDATE`: تعديل بيانات العميل المختار.
  - `DELETE`: حذف سجل العميل من جدول `ACCOUNTS.CUST`.
  - `STATEMENT JOIN QUERY`: استعلام كشف الحساب التراكمي المربوط بين الجداول الأربعة:
    ```sql
    SELECT ACCOUNTS.ENTRY_SUB.ENTRY_NO,
           SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 1, 1)||SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 7, 4) AS SUB_ENTRY_NO,
           TO_CHAR(ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, 'DD/MM/YYYY') AS ENTRY_DATE,
           ACCOUNTS.ENTRY_TYPE.ENTRY_TYPE_NAME,
           ACCOUNTS.ENTRY_MAIN.DETAILS,
           ACCOUNTS.ENTRY_SUB.BALANCE_S,
           ACCOUNTS.ENTRY_SUB.ENTRY_MNT,
           ACCOUNTS.CUST.CUST_NAME,
           ACCOUNTS.CUST.CUST_NO,
           ACCOUNTS.CUST.ACC_NO
    FROM ACCOUNTS.ENTRY_MAIN, ACCOUNTS.ENTRY_SUB, ACCOUNTS.ENTRY_TYPE, ACCOUNTS.CUST
    WHERE ACCOUNTS.ENTRY_SUB.ACC_NO = ACCOUNTS.CUST.ACC_NO
      AND ACCOUNTS.ENTRY_SUB.GIVING = ACCOUNTS.CUST.CUST_NO
      AND ACCOUNTS.ENTRY_SUB.ENTRY_NO = ACCOUNTS.ENTRY_MAIN.ENTRY_NO
      AND ACCOUNTS.ENTRY_MAIN.ENTRY_TYPE_NO = ACCOUNTS.ENTRY_TYPE.ENTRY_TYPE_NO
      AND ACCOUNTS.CUST.CUST_NO = :custNo
    ORDER BY ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, ACCOUNTS.ENTRY_SUB.ENTRY_NO
    ```

## [2026-09-08 20:13:50] - معالجة ترميز النصوص العربية في Oracle واستعلامات البحث المتقدم وفلترة التواريخ
- **معالجة ترميز Oracle NLS_CHARACTERSET = WE8MSWIN1252:**
  - تم رصد أن بيانات الحقول النصية (`CUST_NAME`, `DETAILS`, `ENTRY_TYPE_NAME`, `ADDR`, `PRE_CUST_NAME`) مخزنة في أوراكل ببايتات Windows-1256 (CP1256).
  - عند قراءة البيانات بواسطة OCI Client، يقوم أوراكل بترجمتها إلى محارف Latin-1 UTF-8 مشوهة (مثل `ÎÇáÏ ÍÓÇä ÇáÑÌæí/127`).
  - تم بناء طبقة معالجة وتحويل ثنائية الاتجاه (Bidirectional Encoding Layer) في `ArabicEncoding.php` تقوم بترجمة كل محرف Latin-1 إلى كود الحرف العربي المطابق له في UTF-8 Unicode، وتحويل النصوص العربية إلى بايتات CP1256 متوافقة عند الإدخال والتعديل في قاعدة البيانات.
- **تحديث استعلامات البحث وفلترة التواريخ:**
  - إضافة شروط البحث عن العملاء بواسطة حقول الهواتف (`TEL1` و `TEL2`) في استعلامات `ACCOUNTS.CUST`.
  - إضافة دعم تصفية الحركات بين تاريخين (`ENTRY_DATE >= :from_date` و `ENTRY_DATE <= :to_date`) مع الحفاظ على تسلسل الرصيد التراكمي وحساب الرصيد الافتتاحي ما قبل تاريخ البداية.

## [2026-09-08 20:28:50] - معالجة استعلامات البحث بالحروف العربية ومطابقتها مع جدول ACCOUNTS.CUST
- **تحويل وسيط استعلام البحث (Search Query Parameter Mapping):**
  - تم تحديث استعلام البحث في `CustomerController.php` ليتم تحويل أي مدخل بحث عربي UTF-8 إلى محارف Latin-1 المقابلة لبايتات Windows-1256 عبر دالة `ArabicEncoding::toOracleSearchChars($search)`.
  - أصبح استعلام SQL في أوراكل يطابق فورياً الأسماء والحقول النصية مثل:
    `WHERE CUST_NAME LIKE '%ÎÇáÏ%' OR CUST_NAME LIKE '%خالد%'`
  - تم اختبار البحث بالحروف العربية المفردة (مثل `ا`) والأسماء المركبة ونجح في إرجاع السجلات بدقة تامة.

## [2026-09-08 20:53:00] - تحسين استجابة واجهات كشف الحساب وتكاملها مع استعلامات أوراكل
- لم تتطلب هذه الخطوة تغييرات في بنية جداول قاعدة البيانات؛ حيث تركزت التعديلات على طبقة العرض والواجهات (Presentation Layer) في تطبيق فلاتر لتتوافق ديناميكياً وبشكل متجاوب بنسبة 100% مع مخرجات استعلامات كشف الحساب من قاعدة البيانات.

## [2026-09-08 22:31:29] - توثيق استعلامات جداول العاملين (TAILOR_EMPLOYEES, CUTTER, TAILOR) وكشف الحساب
- **الجداول المستخدمة:**
  1. `ACCOUNTS.TAILOR_EMPLOYEES`: جدول الموظفين (المفتاح الأساسي: `EMP_NO`، الاسم: `EMP_NAME`، الهاتف: `EMP_PHONE1`، `EMP_PHONE2`، البريد: `EMP_EMAIL`، الحالة: `EMP_STATUS`، رقم الحساب: `ACC_NO`، الوظيفة: `JOP_TYPE`، الفئة: `EMP_CLASS`، نوع الراتب: `WAGES_TYPE`، الراتب: `SALARY`، سعر القطعة: `PIECE_PRICE`).
  2. `ACCOUNTS.CUTTER`: جدول القصاصين (المفتاح الأساسي: `CUTTER_NO`، الاسم: `CUTTER_NAME`، الهاتف: `CUTTER_PHONE1`، الحالة: `CUTTER_STATUS`، رقم الحساب: `ACC_NO`).
  3. `ACCOUNTS.TAILOR`: جدول الخياطين (المفتاح الأساسي: `TAILOR_NO`، الاسم: `TAILOR_NAME`، الهاتف: `TAILOR_PHONE1`، الحالة: `TAILOR_STATUS`، رقم الحساب: `ACC_NO`).
- **استعلام كشف الحساب الموحد المستخدم:**
```sql
SELECT ALL ACCOUNTS.ENTRY_SUB.ENTRY_NO,
       SUBSTR(ACCOUNTS.ENTRY_SUB.ENTRY_NO, 1, 1)||SUBSTR(ACCOUNTS.ENTRY_SUB.ENTRY_NO, 7, 4) AS SUB_ENTRY_NO,
       ENTRY_MAIN.ENTRY_DATE,
       ENTRY_TYPE.ENTRY_TYPE_NAME,
       ENTRY_MAIN.DETAILS,
       ENTRY_SUB.BALANCE_S,
       ENTRY_SUB.ENTRY_MNT
FROM ACCOUNTS.ENTRY_MAIN,
     ACCOUNTS.ENTRY_SUB,
     ACCOUNTS.ENTRY_TYPE
WHERE ENTRY_SUB.ACC_NO = :acc_no
  AND ENTRY_MAIN.ENTRY_DATE BETWEEN TO_DATE(:from_date, 'YYYY-MM-DD') AND TO_DATE(:to_date, 'YYYY-MM-DD')
  AND ENTRY_MAIN.entry_type_no = ENTRY_TYPE.ENTRY_TYPE_no
  AND ACCOUNTS.ENTRY_SUB.ENTRY_NO = ACCOUNTS.ENTRY_MAIN.ENTRY_NO
ORDER BY ENTRY_MAIN.ENTRY_DATE;
```
- **معالجة الترميز العربي:** تطبيق دالة تحويل ومطابقة الترميز Windows-1256 لتصحيح نصوص تفاصيل السندات وأنواع العمليات من قاعدة بيانات أوراكل بدقة.

## [2026-09-08 23:05:42] - تحسين مطابقة حقول أوراكل في استعلامات كشف حساب العاملين
- تحسين التعامل مع كائنات نتائج استعلام أوراكل لدعم أسماء الأعمدة غير الحساسة لحالة الأحرف (Lowercase / Uppercase) كـ `acc_no` و `emp_no` و `emp_name`.
- تحسين تصفية استعلام كشف حساب العاملين بدالة `TRUNC(ACCOUNTS.ENTRY_MAIN.ENTRY_DATE)` لضمان مطابقة النطاق الزمني بالكامل (اليوم والشهر والسنة).

## [2026-09-12 21:10:29] - ربط وتوثيق جداول الشجرة المحاسبية والعملات في Oracle DB
- **جداول الشجرة المحاسبية المرتبطة:**
  1. `ACCOUNTS.ACCOUNT`: جدول الأقسام الرئيسية (المفتاح الأساسي: `ACC_NO`، الاسم: `ACC_NAME`).
  2. `ACCOUNTS.ACC_MAIN`: جدول الحسابات الفرعية (المفتاح: `ACC_SUB`، الأب: `ACC_NO`، الاسم: `SUB_NAME`).
  3. `ACCOUNTS.ACC_SUB`: جدول الحسابات الجزئية (المفتاح: `ACC_PART`، الأب: `ACC_SUB`، الاسم: `PART_NAME`).
  4. `ACCOUNTS.ACC_SUB_GROUP`: جدول مجموعات الحسابات الجزئية (المفتاح: `GROUP_ID`، الأب: `ACC_PART`، الاسم: `ACC_GROUP_NAME`).
  5. `ACCOUNTS.CHART_ACC`: جدول الحسابات المالية (المفتاح: `ACC_NO`، الأب: `GROUP_ID`، الاسم: `ACC_NAME`، الرصيد: `BALANCE`، سقف الرصيد: `LIMITED_BALANCE`، التوقيف: `STOPPING_ACC`).
- **جداول العملات وأسعار الصرف:**
  1. `ACCOUNTS.CURRENCY`: جدول العملات الرئيسي (المفتاح: `CUR_NO`، الاسم: `CUR_NAME`).
  2. `ACCOUNTS.CUR_CODE`: جدول رموز العملات (المفتاح: `CUR_NO`، الرمز: `CODE`، الوحدة الرئيسية: `MAIN_CUR_NAME`، الوحدة الفرعية: `SUB_CUR_NAME`).
  3. `ACCOUNTS.CUR_PRICE`: جدول أسعار الصرف (المفتاح: `CUR_NO`، التسلسل: `SEQ`، السعر: `PRICE`، التاريخ: `DAY_DATE`).
- **استعلامات كشف الحساب والعملات:**
  - استعلام كشف الحساب المالي العادي والمفصل يربط بين `ENTRY_MAIN` و `ENTRY_SUB` و `ENTRY_TYPE` مع احتساب الرصيد التراكمي وتصفية التواريخ.
  - تطبيق استثناء حسابات العملاء ما عدا حساب "عملاء الكبودي للخياطة" برقم الحساب `12310000`.



## [2026-10-17 05:25:00] - إنشاء نموذج بيانات الصلاحيات IBAC في Oracle (مراحل 0 و1)
- **جدول `ACCOUNTS.APP_PERMISSIONS` — كتالوج الصلاحيات** (مفتاح `PERMISSION_ID` من `SEQ_APP_PERMISSIONS` عبر المحفِّز `TRG_APP_PERMISSIONS`، و`PERMISSION_CODE` فريد بنمط `module.action`):
  الأعمدة `PERMISSION_ID NUMBER(6)`, `PERMISSION_CODE VARCHAR2(60)`, `MODULE_CODE VARCHAR2(30)`,
  `ACTION_CODE VARCHAR2(30)`, `NAME_AR VARCHAR2(150)`, `NAME_EN VARCHAR2(150)`, `IS_CORE NUMBER(1) DEFAULT 0`,
  `SORT_ORDER NUMBER(4)`, `IS_ACTIVE NUMBER(1) DEFAULT 1`, `DESCRIPTION_AR VARCHAR2(500)`,
  `CREATED_ON DATE DEFAULT SYSDATE`, `CREATED_BY`, `LAST_UPDATED_ON`, `LAST_UPDATED_BY`.
  القيود: `APP_PERM_PK`، `APP_PERM_CODE_UQ`، `APP_PERM_CORE_CK`، `APP_PERM_ACT_CK`، والفهرس `APP_PERM_MOD_IX (MODULE_CODE, SORT_ORDER)`.
- **جدول `ACCOUNTS.APP_USERS_PERMISSIONS` — منح مباشر للمستخدم (نواة IBAC، بلا أدوار)**:
  `ID NUMBER(9)` (تسلسل `SEQ_APP_USERS_PERM` + محفِّز `TRG_APP_USERS_PERM`)، `USER_ID NUMBER(5)`،
  `PERMISSION_ID NUMBER(6)`، `GRANTED_BY`، `GRANTED_ON DEFAULT SYSDATE`، `EXPIRES_ON` (فراغ = دائم)،
  `IS_ACTIVE NUMBER(1) DEFAULT 1` (0 = مسحوب مع بقاء الأثر)، `NOTE VARCHAR2(200)`.
  القيود: `APP_UQ_PK`، `APP_USER_PERM_UQ (USER_ID, PERMISSION_ID)`، `APP_UQ_USER_FK` إلى `APP_USERS(USER_ID)`
  بـ `ON DELETE CASCADE`، `APP_UQ_PERM_FK`، `APP_UQ_ACTIVE_CK`؛ والفهرسان `APP_UQ_USER_IX (USER_ID, IS_ACTIVE)`
  و`APP_UQ_PERM_IX`.
- **جدول `ACCOUNTS.APP_SETTINGS` — إعدادات الأمان والجلسات**: `SETTING_ID` (تسلسل `SEQ_APP_SETTINGS` +
  محفِّز `TRG_APP_SETTINGS`)، `SETTING_KEY` فريد، `SETTING_VALUE VARCHAR2(500)`، `VALUE_TYPE` داخل
  `int|bool|string|json`، `NAME_AR`، `DESCRIPTION_AR`، `MIN_VALUE`، `MAX_VALUE`، `IS_LOCKABLE`
  (1 = لا يُعدَّل من الواجهة)، `SORT_ORDER`، `UPDATED_BY`، `UPDATED_ON`.
- **جدول `ACCOUNTS.APP_USER_ACTIVITY` — سجل النشاط والتدقيق**: `ACTIVITY_ID` (تسلسل `SEQ_APP_ACTIVITY` +
  محفِّز `TRG_APP_ACTIVITY`)، `USER_ID` (الفاعل، وقد يكون NULL عند فشل دخول باسم مجهول)، `TARGET_USER_ID`،
  `ACTION_CODE` (`login`/`login_failed`/`logout`/`biometric_login`/`users.*`/`sessions.terminate`/`settings.update`/`system.bootstrap`)،
  `MODULE_CODE`، `ENTITY_TYPE`، `ENTITY_ID`، `DESCRIPTION_AR VARCHAR2(1000)`، `STATUS` داخل `success|failed`،
  `IP_ADDRESS VARCHAR2(45)` (يدعم IPv6)، `USER_AGENT`، `PLATFORM`، `CREATED_ON DEFAULT SYSDATE`.
  الفهارس: `APP_ACT_USER_IX`، `APP_ACT_TGT_IX`، `APP_ACT_MOD_IX`. **لا قيد FK على `USER_ID`** حتى لا يُمحى
  سجل تدقيق مستخدم عند حذفه، وحتى يُقبل تسجيل محاولات دخول باسم غير معروف.
- **تعديلات `ACCOUNTS.APP_USERS`**: `USER_PASSWORD` من `VARCHAR2(30)` إلى `VARCHAR2(100)` (تمهيداً للتجزئة
  دون كسر النص الصريح الإرثي)، وعمود جديد `IS_ADMIN NUMBER(1) DEFAULT 0 NOT NULL`.
  أُضيف `SEQ_APP_USERS_ID START WITH 100` **بلا محفِّز** لأن النظام القديم يكتب في الجدول مباشرة؛
  الترحيل يستخدم `SEQ_APP_USERS_ID.NEXTVAL` صراحة. **لا وجود لإطار Laravel migrations هنا** — لا يرحَّل مخطط الأعمال.
- **بذر الكتالوج**: 93 صلاحيّة (17 وحدة): 76 فعلاً + 16 منحاً عاماً للوحدات بصيغة `module.*` + `system.*`.
  47 صلاحية أساسية `IS_CORE=1`. `SORT_ORDER = رقم الوحدة × 100 + رقم الفعل` ليظهر الأساسي قبل الإضافي.
  البذر من `App\Support\PermissionCatalog` نفسه، والمرجع الرقمي موثَّق في `db_commends.md`.
- **بذر الإعدادات (10 مفاتيح)**: `session_idle_minutes=240` (5–10080)، `session_absolute_days=14` (1–365)،
  `session_touch_threshold_minutes=5` (1–60)، `single_active_session_per_device=0`، `password_min_length=4` (4–32)،
  `max_failed_logins=0` (0 = معطّل)، `lockout_minutes=15`، `biometric_login_enabled=1`،
  `activity_log_retention_days=180` (30–3650)، `maintenance_message=''`.
- **تهيئة المدير العام**: `UPDATE ACCOUNTS.APP_USERS SET IS_ADMIN=1, USER_TYPE=1 WHERE USER_ID=1` (المستخدم `arslan`)،
  ومنح صريح لـ `system.*` في `APP_USERS_PERMISSIONS` (الصف `ID=1`) وصف تدقيق `system.bootstrap`.
  الدلالة: `IS_ADMIN` لا يخضع لجدول المنح لذلك لا يمكن إقفال النظام بمسح صلاحية؛ USER_TYPE: `1 = موظف`، `2 = عميل`.
- **معلومتان تقنيتان يجب حفظهما عن هذا المخطط**:
  1. **كتابة العربية عبر اتصال التطبيق يجب أن تمر بـ `toOracleSearchChars()`** لا `encodeForOracle()`:
     اتصال `oracle` معرَّف بـ `charset=AL32UTF8` والقاعدة `WE8MSWIN1252`، فأي إرسال بايتات CP1256 خام يُستبدل
     بعلامة `0xBF` (تحقَّق بـ `DUMP(NAME_AR,1016)`). القراءة تُصلَح بـ `fixMojibake()`/`cleanData()` كما هو قائم.
  2. **لا تُسبق أسماء التسلسلات داخل PL/SQL**: يوجد `VIEW` اسمه `ACCOUNTS` داخل المخطط، و`ACCOUNTS.SEQ_X.NEXTVAL`
     يُفسَّر `عرض.عمود` فيفشل بـ `PLS-00302` ويُبقي المحفِّز `INVALID` (وظهر كـ `ORA-04098` عند أول استخدام).
- **قاموس البيانات**: 4 تعليقات جداول + 45 تعليق عمود ثنائية اللغة (عربي/إنجليزي) عبر `COMMENT ON`.
- **نقطة الاسترجاع**: `ACCOUNTS.APP_USERS_BAK_IBAC` نسخة كاملة من `APP_USERS` قبل أي تعديل؛
  وسكربت التراجع الكامل `kyApp_API/database/oracle/04_ibac_rollback.sql`.


---
## [2026-10-17 07:17:24] - المرحلة 2: أثر طبقة IBAC على القاعدة
- **النموذج المنفذ / AI Model:** Qoder Agent
- **DDL:** لا شيء — لم تُنشأ جداول أو أعمدة جديدة في هذه المرحلة. البنية اكتملت في المرحلة 1
  (`APP_PERMISSIONS`، `APP_USERS_PERMISSIONS`، `APP_SETTINGS`، `APP_USER_ACTIVITY`، `IS_ADMIN`).
- **عمليات كتابة حقيقية نتجت عن الكود:**
  1. `ACCOUNTS.PERSONAL_ACCESS_TOKENS.EXPIRES_AT` صار يُملأ لحظة إصدار التوكن (`SessionPolicy::prime()`)
     بقيمة `created_at + session_idle_minutes`، ويجدّده `slide()` عند كل طلب مصادَق عليه يتجاوز
     عتبة اللمس، دون أي تغيير على مخطط الجدول.
  2. `ACCOUNTS.PERSONAL_ACCESS_TOKENS.LAST_USED_AT` تُكتب مع كل طلب مصادَق عليه بعد تفعيل
     `config('sanctum.last_used_at') = true` — وهي مصدر «آخر نشاط» في شاشة الجلسات النشطة (المرحلة 4).
  3. `ACCOUNTS.APP_USER_ACTIVITY` تستقبل أسطراً جديدة: `login_failed` (محاولة فاشلة، `USER_ID` قد يكون
     NULL)، وتسجيل الخروج، ولاحقاً كل إجراء إداري.
  4. `ACCOUNTS.CACHE` (جدول Laravel) يستخدمه كاش الإعدادات والصلاحيات.
- **قيد أوراكل جديد يجب حفظه:** عمود `CACHE.VALUE` من نوع CLOB، لكن Laravel يكتبه بـ
  `merge into "CACHE" using (select :value as "VALUE" from dual)`، وأوراكل ترفض ربط نص يتجاوز
  **4000 بايت** داخل `FROM dual` ⇒ `ORA-01461`. لذلك:
  - حمولة الكاش تطبَّق عليها سقف **3000 بايت** في `SettingsStore` و`PermissionResolver`.
  - **العربية لا تدخل الكاش**: `SettingsStore::all()` يخزّن الحقول الرقمية/المعرفية فقط،
    و`definitions()` تقرأ `SETTING_NAME_AR`/`DESCRIPTION_AR` من القاعدة مباشرة.
- **تأكيدات بنية مقروءة في هذه المرحلة:** `APP_USERS.USER_PASSWORD = VARCHAR2(100)` و`IS_ADMIN = NUMBER(1)`
  موجودان، و**لا يوجد عمود `USER_NO`** أصلاً (لذا حُذف من `$fillable` لأنه كان قابضاً على فراغ)،
  و`USER_TYPE` رقمي وقيمته `1` للمستخدم الحالي فيطابق قرار D5 (1=موظف، 2=عميل).
- **قراءة إعدادات الأمان الحالية:** 10 صفوف، منها `session_idle_minutes = 240` و`biometric_login_enabled = 1`
  و`max_failed_logins = 0` (معطّل عمداً حتى توفّر عمودَي العدّاد في `APP_USERS` حسب §13 من الخطة).
- **دورة العربية مغلقة ومثبتة:** كتابة `DESCRIPTION_AR` بـ `toOracleSearchChars()` ⇒ `DUMP(...,1016)`
  يعيد `Typ=1 Len=23 CharacterSet=WE8MSWIN1252` ⇒ قراءة بـ `fixMojibake()` تعيد النص العربي سليماً.

---
## [2026-10-18 00:03:42] - المرحلة 3: أثر طبقة إدارة المستخدمين على Oracle
- **لا DDL في هذه المرحلة:** لا جداول ولا أعمدة ولا تسلسلات جديدة. كل ما استُخدم موجود من المرحلتين 1 و2
  (`APP_USERS`، `APP_PERMISSIONS`، `APP_USERS_PERMISSIONS`، `APP_SETTINGS`، `APP_USER_ACTIVITY`،
  `PERSONAL_ACCESS_TOKENS`، `SEQ_APP_USERS_ID`).
- **حالة القاعدة بعد المرحلة (قراءة تدقيقية):** 1 مستخدم و1 منح فعّالة (`system.*` للمدير) و93 صلاحية
  و1 مدير نظام و32 توكنًا و6 أسطر نشاط — أي أن مسار الكتابة الجديد (`PermissionGrantSync::replace()`
  و`store()` و`terminateSessions()`) **لم يُنفَّذ عليه أي سطر فعلي**: الاختبارات مصممة لتتوقف قبل الكتابة.
- **مسارات الكتابة التي أصبحت جاهزة للتنفيذ (تُجرى لأول مرة في المرحلة 8 بيد مستخدم أو باختبار كتابي مصرّح به):**
  - `INSERT INTO ACCOUNTS.APP_USERS (USER_ID, …) VALUES (ACCOUNTS.SEQ_APP_USERS_ID.NEXTVAL, …)` — بلا محفِّز
    لأن النظام القديم يُدخل على الجدول مباشرة، فالتسلسل يُستدعى صراحة.
  - `DELETE FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE USER_ID = :user_id` + `INSERT … (USER_ID, PERMISSION_ID, GRANTED_BY)`
    داخل معاملة واحدة.
  - `UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS SET EXPIRES_AT = SYSDATE - 1 …` لإنهاء جلسة مستخدم فوراً.
- **اكتشاف مهم عن الأعمدة التاريخية الفارغة:** عمود `EXPIRES_AT` الفارغ (NULL) لا يعود `null` دائماً؛
  فـ `selectOne` الخام يُعيده **نصاً فارغاً** عبر اتصال أوراكل، والنموذج يمرّره أحياناً كـ **false**.
  لذلك `SessionPolicy` وُضعت لها `toDate()` موحِّدة، وتأكّد أن `Sanctum\Guard` نفسه محصّن ضد هذه الحالة
  (`! $accessToken->expires_at` تختصر قبل استدعاء أي طريقة).
- **البحث العربي في `APP_USERS`:** `conditions()` تطابق `USER_NAME_EN` بالمحارف اللاتينية و`USER_NAME_AR`
  بوجهيه (`toOracleSearchChars()` والقيمة الخام كما كُتبت)، والفرز العربي يتم على بايتات CP1256 المخزّنة
  كما في بقية الشاشات — لا تغيير في ترميز الجدول.
- **الكتابة العربية:** `store()` تستخدم `toOracleSearchChars()` للأسباب نفسها الموثّقة في نهاية المرحلة 1
  (عميل AL32UTF8 مقابل قاعدة WE8MSWIN1252)، و**ليس** `encodeForOracle()`.
- **أثر تدقيقي باقٍ:** كل تشغيل لحزمة Pest يُضيف أسطر `login_failed` إلى `APP_USER_ACTIVITY`
  (اختبار «bad credentials» في `AuthTest`)؛ أُنشئت في هذه المرحلة المعرّفات 5 و6 و7. حذفها مباشرة رُفض
  من سياسة الموافقات على قاعدة إنتاجية، فإما يُتفق على أمر تنظيف مجدول أو تُترك كأثر تدقيقي طبيعي.
- **قراءة تأكيد الحراسة:** `SELECT COUNT(*) … WHERE IS_ADMIN = 1` = 1 ⇒ حارس «آخر مدير» فعّال ولن يسمح
  بتعطيل أو حذف `USER_ID=1` قبل وجود مدير ثانٍ.

---
## [2026-10-18 02:52:11] - المرحلة 4: أثر الجلسات والإعدادات على Oracle (قراءة فقط)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 02:52:11 · **DDL:** لا شيء · **كتابة:** لا شيء
- **لا تغيير في نموذج البيانات:** المرحلة 4 تعمل على جداول موجودة حصراً —
  `PERSONAL_ACCESS_TOKENS` (قراءة + `EXPIRES_AT`) و`APP_USERS` (انضمام للأسماء والحالة) و
  `APP_SETTINGS` (قراءة) و`APP_USER_ACTIVITY` (سجل عند النجاح/الرفض). لا إنشاء جدول ولا عمود ولا قيد.
- **عبارات الكتابة الجاهزة والتي لم تُنفَّذ مرة على القاعدة الحيّة:**
  - `UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS SET EXPIRES_AT = SYSDATE - 1, UPDATED_AT = SYSDATE WHERE …`
    (إنهاء جلسة أو كل جلسات مستخدم). صيغة أوراكل الصحيحة: **بلا بدائل للجول** —
    `UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS t SET …` مرفوضة نحويّاً، والاعتماد على `TOKENABLE_ID`
    مباشرة. الإنهاء لا يمسح الصف ولا يجعل `EXPIRES_AT` فارغاً: دفعه للماضي يبقي أثراً تدقيقياً ويجعل
    الحارس يرفض في الطلب التالي.
  - `UPDATE ACCOUNTS.APP_SETTINGS SET SETTING_VALUE = :setting_value, UPDATED_BY = :updated_by,
    UPDATED_ON = SYSDATE WHERE SETTING_KEY = :setting_key` (حفظ إعداد).
- **اكتشاف أوراكل جديد (سجل في الخطة كبند #19):** اسم المربَط لا يجوز أن يكون كلمة محجوزة.
  `:by` أنتج `ORA-01745: invalid host/bind variable name` عند أول تنفيذ فعلي لحفظ الإعدادات، وظهر في
  موضعين مكتومين لأن لا مسار كتابة كان قد جرى من قبل: `SettingsStore::set()` و`UserAdminController@toggle`
  (مع `:next`). القاعدة العاملة: أسماء مربَطات موسومة بالمجال (`:setting_value`, `:updated_by`,
  `:activated`)؛ والمربَطات غير المستعملة تُزال من مصفوفة الربط قبل الاستعلام العدادي تفادياً
  لـ `ORA-01008: not all variables bound`.
- **قراءة تأكيد سلامة القاعدة بعد المرحلة 4 (كل الأرقام كما كانت):**
  `APP_SETTINGS` = 10 صفوف، `UPDATED_BY` فارغ في الكل، `UPDATED_ON = 2026-10-17 05:48:11` (وقت البذر)،
  `password_min_length = 4`، `session_idle_minutes = 240`، `session_absolute_days = 14`،
  `session_touch_threshold_minutes = 5`، `biometric_login_enabled = 1`.
  `APP_USERS` = 1 (مدير واحد) · `APP_PERMISSIONS` = 93 · `APP_USERS_PERMISSIONS` = 1 ·
  `PERSONAL_ACCESS_TOKENS` = 32 — أي لم يُضَف أي صف ولم يُحذف ولم يُعدَّل.
- **الأثر التدقيقي الوحيد:** `APP_USER_ACTIVITY` ارتفع من 6 إلى 8 صفوف (آخر معرّف 9) بسبب اختبار
  «bad credentials» في `AuthTest` الذي يمرّ بمسار `login_failed` المشروع. سطر الإنهاء التدريبي نفسه
  لم يُنفَّذ؛ فاختبارات الجلسات تغطي فروع 404 و0 صفوف متأثرة فقط.
- **حدود كاش أوراكل باقية:** جدول `CACHE` يرفض مربَطات أطول من 4000 بايت (`ORA-01461`)، لذا نسخة
  `SettingsStore` المخمَّنة تبقى رقمية بلا عربية (سقف 3000 بايت)، و`definitions()` تُقرأ من القاعدة
  في كل فتح لشاشة الإعدادات.

## [2026-10-19 01:47:33] - المرحلة 5+6: أثر نواة الصلاحيات في العميل على Oracle (قراءة فقط)
**النموذج:** Qoder Agent · **الوقت:** 01:47:33 · **لا DDL، لا `UPDATE`، لا `DELETE`**

- **لم تُمسّ القاعدة في هذه المرحلة:** العمل كله في طبقة العميل (`lib/**` و`test/**`). كل ما نُفِّذ
  على `ACCOUNTS` كان استعلام قراءة واحداً للتحقق من أن نسخة العميل لا تنحرف عن الكتالوج المخزَّن.
- **الاستعلام المستعمل:**
  ```sql
  SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE IS_ACTIVE = 1)        AS active_perms,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE IS_ACTIVE = 1)   AS active_grants,
         (SELECT COUNT(*) FROM ALL_TAB_COLUMNS
           WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'APP_USERS'
             AND COLUMN_NAME = 'IS_ADMIN')                                           AS has_is_admin
    FROM DUAL;
  ```
  النتيجة: `ACTIVE_PERMS = 93` · `ACTIVE_GRANTS = 1` · `HAS_IS_ADMIN = 1`.
- **لماذا 93 بالذات؟** لأن `lib/core/constants/permission_codes.dart` نسخة حرفية من
  `PermissionCatalog::codes()`، والعدد هو المفتاح الذي يمنع نمطين فاشلين: كود في الواجهة لا يعرفه
  الخادم (يُرسم زر ثم يُرفض بـ 403)، وكود في القاعدة لا تعرفه الواجهة (صلاحية ممنوحة لا تظهر أبداً).
  قورن المحتوى أيضاً لا العدد فقط: 93 مقابل 93، بلا فرق في العناصر ولا في الترتيب.
- **منح منشّطة واحدة في `APP_USERS_PERMISSIONS`:** هذه المرحلة لا تمنح أحداً — الترخيص الجماعي
  قبل إغلاق المسارات (D3) يبقى في المرحلة 7، وشاشات المنح في المرحلة 8. لذلك لم تُكتب أي صف جديد.
- **قراءة دفاعية تكرّر في العميل لأن أوراكل هكذا تعود:**
  - عمود `DATE` فارغ (`EXPIRES_ON`/`SESSION_EXPIRES_AT` عبر بعض مسارات القراءة) يصل كـ `false` أو
    نص فارغ، لا كـ `null` — لذا `PermissionSnapshot._parseNullableString` يعتبر `false` غياباً.
    لو فُُسّر نصّاً لظهر موعد نهاية جلسة وهمي ورسَم العميل عدّاً تنازلياً لا وجود له في القاعدة.
  - أسماء الأعمدة غير ثابتة الحالة بين PDO والكتالوج، فالقراءة بمفتاحين (`user_id`/`USER_ID`،
    `is_admin`/`IS_ADMIN`، `session_expires_at`/`SESSION_EXPIRES_AT`)، وهي نفس العلة التي جعلت
    `User::getAttribute()` في الخلفية تحمل بديلاً حرفياً.
  - `IS_ADMIN` في `APP_USERS` لا في جدول المنح: قرار D1 (تجاوز المدير خارج الجدول) كي لا تُقفل
    صفة المدير بمنح مسحوبة، ولأن تجاوز الخادم يُختبر بلا صفوف منح.
- **الترميز العربي:** لا جديد. أكواد الصلاحيات لاتينية (`customers.view`) فلا تمر على طبقة الإصلاح
  (`ArabicEncoding`/`ArabicEncodingUtils.fix()`)، والتسميات العربية في `permModuleLabels` و
  `permActionLabels` نص ثابت في العميل لا يُقرأ من `APP_PERMISSIONS.PERMISSION_NAME_AR` — وهذا فرق
  مقصود: شاشة المنح تعرض تسمية الخادم من `arabicName()`، والواجهة تعرض ما يصف الفعل للمستخدم.
- **ما لم يُنفَّذ:** لا استعلامات جديدة ولا فهارس. المسار `GET /api/auth/permissions` يقرأ جدول المنح
  بعد إسقاط نسخة الخادم منه (`forget()` في `myPermissions`)، وكل استدعاء من `PermissionsNotifier`
  يكلّف قراءة واحدة؛ لذا أرضية الـ 15 ثانية في العميل ليست ترفاً بل حدٌّ لعدد القراءات في اليوم.

---

## [2026-10-19 02:59:38] المرجع الصحيح لأعمدة جداول IBAC (فُرض بتصحيح `ORA-00904`) · Qoder Agent

**لماذا هذا القطاع:** وثيقة المرحلة 5+6 في `db_commends.md` حفظت استعلام تحقّق بأسماء أعمدة غير
موجودة (`STATUS = 'ACTIVE'`، `P.ID`، `EXPIRES_AT`)، وحين أُعيد تنفيذها حرفياً الآن ردّ أوراكل
`ORA-00904: "STATUS": invalid identifier` في الموضع 60. الخطأ في الوثيقة لا في الكود —
`PermissionResolver::GRANTS_SQL` يكتب الأسماء الصحيحة منذ المرحلة 2 — لكن هذه الملف هو **مرجع
المخطط** الذي يُبنى عليه كل استعلام لاحق، فاسم خاطئ هنا يتكاثر في كل مكان يُقرأ منه.

### الأعمدة كما تقرّها `ALL_TAB_COLUMNS` (القراءة أدناه هي المرجع، لا الذاكرة)

| الجدول | المفتاح | عمود الحالة | بقية الأعمدة |
|---|---|---|---|
| `APP_PERMISSIONS` | `PERMISSION_ID` (وليس `ID`) | `IS_ACTIVE` رقمي `NOT NULL` (وليس `STATUS` نصياً) | `PERMISSION_CODE`, `MODULE_CODE`, `ACTION_CODE`, `NAME_AR`, `NAME_EN`, `IS_CORE`, `SORT_ORDER`, `DESCRIPTION_AR`, `CREATED_ON`, `CREATED_BY`, `LAST_UPDATED_ON`, `LAST_UPDATED_BY` |
| `APP_USERS_PERMISSIONS` | `ID` | `IS_ACTIVE` رقمي `NOT NULL` | `USER_ID`, `PERMISSION_ID`, `GRANTED_BY`, `GRANTED_ON`, `EXPIRES_ON` (وليس `EXPIRES_AT`), `NOTE` |
| `APP_SETTINGS` | `SETTING_ID` | — (بلا عمود حالة) | `SETTING_KEY`, `SETTING_VALUE`, `VALUE_TYPE`, `NAME_AR`, `DESCRIPTION_AR`, `MIN_VALUE`, `MAX_VALUE`, `IS_LOCKABLE` (`NOT NULL`), `SORT_ORDER`, `UPDATED_BY`, `UPDATED_ON` |

### القواعد المشتقة من هذا التصحيح

1. **الحالة رقمية دائماً في جداولنا:** `IS_ACTIVE = 1` لا `STATUS = 'ACTIVE'`. النمط النصي عرف
   حديث ولا يوجد في هذا المخطط؛ ومن ينسجه على الاستعلام لا يحصل خطأً مسموعاً بل يحصل على مجموعة
   نتائج صامتة حين ينجح الحظ.
2. **انتهاء الصلاحية في جدول المنح `EXPIRES_ON`، وانتهاء الجلسة في جدول Sanctum `EXPIRES_AT`.**
   تشابه الدلالة واختلاف الاسم فخّ واقع: `PERSONAL_ACCESS_TOKENS.EXPIRES_AT` صحيح (عمود Sanctum
   الأصلي) و`APP_USERS_PERMISSIONS.EXPIRES_ON` صحيح (عمودنا) — ولا يجوز تعميم أحدهما على الآخر.
3. **أسماء المفاتيح غير موحّدة عبر المخطط:** `APP_PERMISSIONS.PERMISSION_ID` و
   `APP_USERS_PERMISSIONS.ID` و`APP_SETTINGS.SETTING_ID` و`APP_USERS.USER_ID`. الجدول الوحيد الذي
   يطابق اسمه مختصرًا هو جدول المنح. لهذا تُقرأ `ALL_TAB_COLUMNS` قبل كتابة أي استعلام جديد، لا
   قبل مراجعته.
4. **العبارة الصحيحة للتحقق من حالة الصلاحيات** (وهي التي أنتجت `93 / 1 / 1`):
   ```sql
   SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE IS_ACTIVE = 1) AS ACTIVE_PERMS,
          (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS UP
             JOIN ACCOUNTS.APP_PERMISSIONS P ON P.PERMISSION_ID = UP.PERMISSION_ID
            WHERE P.IS_ACTIVE = 1 AND UP.IS_ACTIVE = 1
              AND (UP.EXPIRES_ON IS NULL OR UP.EXPIRES_ON > SYSDATE)) AS ACTIVE_GRANTS,
          (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS
            WHERE IS_ADMIN = 1 AND IS_ACTIVATED = 1) AS ACTIVE_ADMINS
     FROM DUAL;
   ```
   المنح الصالحة تُعدّ بثلاثة شروط لا بشرط واحد: صلاحية منشّطة، ومنح منشّط، وبلا انتهاء أو لم
   ينتهِ بعد. أي صياغة تسقط أحد الثلاثة تبالغ في عدد الصلاحيات التي يملكها المستخدم فعلياً.

---

## [2026-10-19 02:59:38] المرحلة 7 — ختم المسارات وأثره على القاعدة · Qoder Agent

**لا DDL ولا كتابة.** هذه المرحلة طبقة سلطة في Laravel لا مخطط؛ لم تُزد جداول ولا أعمدة ولا
فهارس، ولم يُنفَّذ `INSERT`/`UPDATE`/`DELETE` واحد على المخطط الإنتاجي.

### قراءة واحدة فقط، وهي التي غيّرت قرار الخطة

```sql
SELECT USER_ID, USER_NAME_EN, USER_TYPE, IS_ACTIVATED, IS_ADMIN FROM ACCOUNTS.APP_USERS ORDER BY USER_ID;
```

النتيجة: صفّ واحد — `USER_ID=1`، `USER_NAME_EN=arslan`، `USER_TYPE=1` (موظف)، `IS_ACTIVATED=1`،
`IS_ADMIN=1`.

**الأثر على البند 6 من الخطة (`05_ibac_bootstrap_grants.php`):** ذلك السكربت كان شرطاً مسبَقاً
للختم كي لا يُطرد مستخدمون حقيقيون عند أول مسار يُقفل. وبما أن القاعدة لا تحتوي إلا مستخدماً واحداً
وهو مدير نظام، فإن `PermissionResolver` يرجع القبول على `IS_ADMIN` **قبل** أي مسح لجدول المنح،
فالسلسلة التي كان السكربت يحمي منها غير موجودة. **حُذف من طريق التنفيذ لا من الخطة**: يعود مطلوباً
لحظياً عند أول `INSERT` في `APP_USERS` لمستخدم غير مدير (المرحلة 8 هي التي تنشئ كذلك المستخدم
من الواجهة).

### أثر الختم على أنماط القراءة

- **`selectFromTable`:** كان يقرأ `USER_TABLES` ثم `SELECT * FROM <أي جدول>`، فصار يرفض 11 جدولاً
  **قبل** استعلام الوجود — أي أن جدول الاعتمادات لم يعد يولّد قراءة أصلاً. الترتيب مقصود: استعلام
  الوجود مكلف بلا طائل حين الاسم وحده يكفي للقرار. والقائمة ليست حماية من الحقن (ذاك كان مغلقاً
  بالفعل بـ `regex` وفحص `USER_TABLES` وسقف `limit`)، بل حماية من **التسريب بالصلاحية** — وهو
  البند **S2** في `AGENTS.md` الذي يُغلق الآن من نصفين: صلاحية `system.*` للمسار، وقائمة رفض للجدول.
- **تنقيح الأعمدة** يعمل على مستوى اسم العمود لا قيمته (`PASSWORD`, `DEVICE_TOKEN`, `TOKEN`,
  `SECRET`, `KEY`)، وهو آمن لأن أسماء هذا المخطط لاتينية ثابتة الحالة في القاموس (`all_tab_columns`)
  وإن وصلت أي حالة أحرف عبر اتصال التطبيق — لذلك المطابقة بعد `strtoupper`.
- **`SALES_BILL`:** قراءة الفواتير صارت مغلفة بـ `ArabicEncoding::cleanData()` بعد أن كانت الأسماء
  العربية تصل كما هي من بايتات `WE8MSWIN1252`. هذا أول مسار أعمال يستفيد من طبقة الترميم، وكان
  الاستثناء الوحيد بينها (البند **C5**). البحث بالاسم يمرّ بـ `toOracleSearchChars()` فيصير بصيغتَي
  البايت كما هو الشرط في §5.1.
- **قراءات الكشوف** (`customers.statement`, `employees/cutters/tailors.statement`,
  `accounts.statement`) لم تتغير عبارة `SQL` فيها إطلاقاً؛ الذي تغيّر هو من يستطيع استدعاءها.

### ملاحظة تشغيلية للقاعدة الحيّة

`PERSONAL_ACCESS_TOKENS` بقيت المصدر الوحيد لحالة الجلسة (لا جدول جلسات لدينا — البند **D7**)،
والختم لم يضف استعلاماً لكل طلب: حارس الصلاحيات يقرأ مجموعة الصلاحيات عبر `PermissionResolver`
المخزَّن في الكاش (بسقف 3000 بايت، البند **17**)، فمساراً مقفلاً يكلّف القراءة نفسها التي كان
يكلّفها مفتوحاً، لا أكثر.

---

## [2026-10-19 06:07:00] المرحلة 8 — أثر واجهة الإدارة على Oracle (قراءة فقط) · Qoder Agent

**لم يُنفَّذ أي `DDL` أو `INSERT` أو `UPDATE` أو `DELETE` في هذه المرحلة.** الواجهات الجديدة تستهلك
الجدول الذي بنيناه في المراحل 1–4 كما هو، والتحقق تمّ بمزيفات مستودعات داخل الاختبارات لا على
القاعدة، فأسفل هي عقود القراءة التي ستُستخدم عند أول قبول يدوي مأذون:

### الجداول التي تقرأها وتكتبها شاشات الإدارة

| الشاشة | الجدول | ما يهمّ المخطط |
|---|---|---|
| لوحة الإدارة / قائمة المستخدمين | `APP_USERS` | الأعمدة `USER_ID` (بديل `USER_NO` — البند **D6**)، `USER_NAME_EN`، `USER_NAME_AR`، `USER_TYPE`، `IS_ACTIVATED`، `IS_ADMIN`، `BRANCH_NO`، `CASH_ACC_NO`، `ALLOW_BANK_ACC`، `BIOMETRIC_ENABLED`. كلُّها رقمية الحالة (`1/0`) لا نصية. |
| منتقي الصلاحيات | `APP_PERMISSIONS` + `APP_USERS_PERMISSIONS` | `IS_ACTIVE = 1` و`EXPIRES_ON` (ليس `EXPIRES_AT`) في جدول المنح؛ `PERMISSION_ID` لا `ID`؛ والمفتاح `ID` يولّده `TRG_APP_USERS_PERM` من `SEQ_APP_USERS_PERM` فلا يُحسب بـ `MAX+1`. |
| الجلسات النشطة | `PERSONAL_ACCESS_TOKENS` | `ID` هو مفتاح الصف ويُصدَّر للعميل باسم `token_id`؛ `EXPIRES_AT` العمود الوحيد الذي تُغيّره الإدارة (إنهاءً وتجديداً انزلاقياً)؛ `NAME` عمود CLOB يُقرأ بـ `DBMS_LOB.SUBSTR(t.NAME, 60, 1)` ولا يدخل `LIKE` ولا `ORDER BY`؛ و`TOKEN` و`ABILITIES` لا تخرجان من أي مسار. الحالة تُشتق في `SQL` بـ `CASE` (اولاً `disabled` من `IS_ACTIVATED`، ثم `expired` من `EXPIRES_AT <= SYSDATE`، وإلا `active`)، والترتيب ثابت بـ `ROW_NUMBER() OVER (ORDER BY NVL(LAST_USED_AT, CREATED_AT) DESC, ID DESC)` ولا يقبل فرزاً من الطلب لأن أي عمود يرسله المستخدم سيدخل العبارة نصاً. |
| سجل النشاط | `APP_USER_ACTIVITY` | أعمدته `USER_ID`, `TARGET_USER_ID`, `ACTION_CODE`, `MODULE_CODE`, `ENTITY_TYPE`, `ENTITY_ID`, `DESCRIPTION_AR`, `STATUS`, `IP_ADDRESS`, `USER_AGENT`, `PLATFORM`, `CREATED_ON` — و`STATUS` نصّ `'success'/'failed'` لا رقم، و`CREATED_ON` تُكتب بـ `SYSDATE` على ساعة أوراكل. |
| إعدادات الأمان | `APP_SETTINGS` | `VALUE_TYPE` (`int`/`bool`/`string`) يحدّد التحقق، و`MIN_VALUE`/`MAX_VALUE` حدود الخادم التي تعيد الواجهة احترامها قبل الإرسال؛ والحفظ `UPDATE` فقط (الصفوف بذورها المرحلة 1)، والمفتاح من `TRG_APP_SETTINGS`. |

### ما فُرض على القراءة بسبب شكل البيانات

- **الحالة أرقام لا كلمات:** `IS_ACTIVATED`/`IS_ADMIN`/`IS_ACTIVE`/`BIOMETRIC_ENABLED` تصل `1/0`،
  والأوصاف العربية (`statusLabel`، `userTypeLabel`) يبنيها الخادم فلا تبني الواجهة قراراً على
  نصّ مستخدم.
- **`IS_CURRENT` ليس عموداً:** تُشتقه الخلفية بمقارنة مفتاح الصف `t.ID` مع توكن الطلب الحالي
  (`SessionAdminController:411`)، فهو وحده الصواب مهما تعدّدت أجهزة المستخدم.
- **الوقت المتبقي يُحسب من `EXPIRES_AT` لا من `minutes_left`:** هذا الأخير `max(0, …)` على ساعة
  الخادم، فيمنح جلسةً حيّة قراءة «0 دقيقة» عند أي انحراف منطقة زمنية — والعمود المرسَل هو المرجع.
- **العربية في `APP_USERS.USER_NAME_AR` و`DESCRIPTION_AR`** بايتات `WE8MSWIN1252`، فكل قراءة تمرّ
  `ArabicEncoding::cleanData()`/`fixMojibake()` → `ArabicEncodingUtils.fix()` في العميل؛ والكتابة
  تمرّ `ArabicEncoding::toOracleSearchChars()` (كما في `UserAdminController:268` و
  `ActivityLogger`) لأن اتصال PHP بـ `AL32UTF8` فلا تصل البايتات الخام وإلا ظهر الاسم mojibake في
  البطاقة وفي سجل النشاط.
- **`MAX(PK)+1` لم يُستخدم في أي جدول IBAC:** `APP_USERS` يُنشأ بـ `SEQ_APP_USERS_ID.NEXTVAL`
  صراحةً في `UserAdminController:797` (بلا Trigger على `APP_USERS` لأن الجدول مشترك مع نظام الإرث
  — معالجة الخطر الموثّق في جدول §11 من الخطة)، و`APP_PERMISSIONS`/`APP_USERS_PERMISSIONS`/`APP_SETTINGS`/
  `APP_USER_ACTIVITY` تُولّد مفاتيحها من triggers (`TRG_APP_PERMISSIONS`، `TRG_APP_USERS_PERM`،
  `TRG_APP_SETTINGS`، `TRG_APP_ACTIVITY`) فتنطبق قاعدة «ذرّي لا سلالي» التي تُصلح البند **C6**
  داخل ما نملكه من جداول دون أن نلمس جداول الأعمال.

### الكتابة المعلّقة على إذن

إنشاء مستخدم ثانٍ غير مدير، ومنحه الترحيبية، وإنهاء جلسة، وحفظ `session_idle_minutes` — كلها
`INSERT`/`UPDATE` على `ACCOUNTS` الحيّ، موقوفة حتى موافقة صريحة. السيناريو وعباراته التحقّقية
محفوظة في `ibac_permissions_plan.md` §10، وتُنفَّذ وتُوثَّق هنا عند الإذن.

---

## [2026-10-20 00:45:10] المرحلة 9 — عقد الكتابة العربية وتحقّق نهائي للمخطط (قراءة فقط) · Qoder Agent

### قاعدة البيانات لم تُعدَّل — هذا التصحيح في طبقة PHP لا في DDL

الحذف كان دالة PHP (`encodeForOracle()`) لا عموداً ولا قيداً، فلم يلزم أي `ALTER`. الأثر على القاعدة
أن مسارات الإدراج/التحديث/البحث في `CUST` و`CHART_ACC` و`CURRENCY`/`CUR_PRICE` و`APP_SETTINGS` صارت
ترسل المحارف اللاتينية المكافئة لبايتات CP1256، وهي نفس الصيغة التي يستخدمها نظام الشركة القديم، فلا
تنشأ صيغة ثالثة داخل العمود.

**البرهان البايتي (قراءة فقط، عبر MCP):**
- شكل القيمة الفاسدة: `CHR(191)||CHR(191)||CHR(191)` ⇒ `Typ=1 Len=3 … bf,bf,bf` — ثلاث محرفات
  استبدال، وهو ما كان ينتجه الربط الخام.
- الشكل الصحيح: `CHR(216)||CHR(225)||CHR(233)||CHR(199)` ⇒ `Typ=1 Len=4 … d8,e1,e9,c7` = «خالد»
  ببايتات WE8MSWIN1252، أي ما يستقر فعلاً عند استخدام `toOracleSearchChars()`.
- صفوف موجودة للشاهد: `DUMP(CUST_NAME,1016)` على `CUST_NO=0` أعطى 21 بايتاً (`da,e3,e1,c7,…`) —
  النظام القديم يخزّن CP1256 حرفياً، فلا يوجد نمط UTF-8 مختلط داخل الأعمدة.

### هل أفسدت العلّة بيانات قائمة؟

لم تُفسد: `SELECT COUNT(*) FROM ACCOUNTS.CUST WHERE CUST_NAME LIKE '%'||CHR(191)||'%'` = **0** من أصل
**25,406** صفاً. لا `0xBF` في أسماء العملاء، فلا حاجة لسيناريو استرجاع أو `UPDATE` تصحيحي — وهما
كانا ليصبحا أخطر من العلّة نفسها.

### تحقّق نهائي لقاعدة IBAC (قراءة فقط)

| الفحص | العبارة | النتيجة |
|---|---|---|
| المُشغِّلات (Triggers) الثمانية صالحة | `ALL_OBJECTS` بـ `OBJECT_TYPE='TRIGGER'` و`STATUS<>'VALID'` | 8 مُشغِّلات، **0 غير صالحة** (لا `PLS-00302`/`ORA-04098`) |
| `USER_NO` زال و`IS_ADMIN` موجود | `ALL_TAB_COLUMNS` على `APP_USERS` | `USER_NO` = 0 · `IS_ADMIN` = 1 |
| الكتالوج والإعدادات والمنح | عدّادات جداول IBAC | `APP_PERMISSIONS` 93 · `APP_SETTINGS` 10 · `APP_USERS_PERMISSIONS` 1 |
| قيم سياسة الجلسات | `APP_SETTINGS` بمفاتيح السياسة | `session_idle_minutes=240` · `session_absolute_days=14` · `session_touch_threshold_minutes=5` (كلها `int`) |

**لماذا هذه الأرقام بالذات:** لأن `SessionPolicy` يقرأها من الجدول لا من الكود، وأي انحراف فيها يغيّر
سلوك الطرد على الأجهزة الحيّة دون أي تعديل في PHP؛ وبقاء `USER_NO` ظاهراً في أي استعلام يعني
`ORA-00904` مباشرة لأن العمود محذوف فيزيائياً.

### الكتابة المعلّقة على إذن

لا جديد معلّق في القاعدة من جهة هذه المرحلة: التصحيح لا يكتب. يبقى معلّقاً ما ورد أعلاه (مستخدم ثانٍ،
منح ترحيبية، إنهاء جلسة، حفظ `session_idle_minutes=1` لدورة الخمول) وكلّه `INSERT`/`UPDATE` على
`ACCOUNTS` الحيّ.

---

## [2026-10-20 04:13:12] تحقّق قراءة فقط: ثبات إصلاح الترميز على صفوف حيّة · Qoder Agent

بعد إضافة حصانة التكرار إلى `ArabicEncoding::fixMojibake()`، طُبّق الإصلاح على صفوف حقيقية
(قراءةً فقط عبر MCP `oracle` و`php artisan tinker`) للتأكد أن الثبات ليس نظرياً:

| الفحص | العبارة | النتيجة |
|---|---|---|
| اسم مستخدم حيّ | `USER_NAME_AR` من `APP_USERS` حيث `USER_ID=1` | إصلاح واحد = «ارسلان» · `fixMojibake(fixMojibake(x)) === fixMojibake(x)` = **ثابت** |
| تسمية إعداد حيّ | `NAME_AR` من `APP_SETTINGS` حيث `SETTING_KEY='session_idle_minutes'` | إصلاح واحد = «مهلة خمول الجلسة (بالدقائق)» · ثابت عند التكرار |
| الإعدادات العشر | قائمة الإعدادات بنوعها وقيمتها | كلها `int`/`bool` عدا `maintenance_message` (`string`, NULL) — فلا عربية تظهر في `raw_value` الذي يُرجع خاماً |
| أعمدة `APP_USERS` الإلزامية | `ALL_TAB_COLUMNS` بـ `NULLABLE='N'` | `USER_ID` و`IS_ADMIN` فقط (`DATA_DEFAULT` للأخير = `'0 '`) — وكلاهما مربوط صراحة في إدراج `store()`، فلا عمود إلزامي غائب عن مسار الإنشاء |

**لماذا هذا مهم:** شاشتا الجلسات وإعدادات الأمان كنّا تعرضان رموزاً لأن إصلاحاً ثانياً مرّ على قيم
مُصلَحة (`موظف` ← بايتاتها UTF-8 تُقلب عبر جدول CP1256 إلى `ظ…ظˆط¸ظپ`). الثبات عند التكرار هو
الدليل الميداني على أن الحصانة تعمل على بيانات الإنتاج الحقيقية لا في الاختبار وحده. العبارات
الحرفية مسجّلة في `db_commends.md`، ولم تُنفَّذ أي كتابة في هذه الجولة.

**ما يبقى على إذن:** تجربة كتابة مُرجَّعة (إنشاء مستخدم داخل معاملة تُلغى) لإثبات مسار `store()`
كاملاً — مُنعت بسياسة التنفيذ الآمنة لأنها كتابة في القاعدة الحيّة، ويبقى البديل إنشاء مستخدم
حقيقي من واجهة التطبيق بعد الإصلاح.

---

## 2026-10-20 — وحدة «إعدادات API والتهيئة الديناميكية» (المنفّذ: Qoder)

**لا مخططات جديدة (No new DDL):** الميزة تُعيد استخدام جدولين قائمين فقط ولا تُنشئ أي جدول —
`APP_SETTINGS` (مفتاح/قيمة/نوع) لتخزين تهيئة التطبيق، و`APP_PERMISSIONS` + `APP_USERS_PERMISSIONS`
لمنح رموز `app_config.*` وفق IBAC. هذا متوافق مع القاعدة «قاعدة أوراكل ليست ours للترحيل».

**توسيع كتالوج الصلاحيات (Permission catalog):** أُضيف模块 `app_config` بأربعة رموز ASCII —
`app_config.*` (النطاق)، `app_config.view` (قراءة الحمولة)، `app_config.update` (تعديل بيانات
الشركة/الشعار/الثيم)، `app_config.api_manage` (تغيير كلمة سر إعدادات الاتصال). ترتب بذلك الكتالوج
من **93 رمزاً/17模块اً** إلى **97 رمزاً/18模块اً**. البذر حيّاً عبر `02_ibac_seed.php`.

**أسطر `APP_SETTINGS` الجديدة (عبر `AppConfig::DEFAULTS`):** معلومات الشركة (`company_name`,
`company_address`, `company_website`, `company_phone`)، اسم التطبيق (`app_name`)، خمسة ألوان الثيم
(`theme_primary_color`=#A27E4E، `theme_secondary_color`=#0D9488، `theme_background_color`=#F8FAFC،
`theme_text_primary_color`=#0F172A، `theme_text_secondary_color`=#475569)، الخط (`theme_font_family`
=Cairo)، و`api_settings_password` — يُبذر **كمجزّأة bcrypt** للكلمة الافتراضية `A1.b2.c3.d4` ولا
يُخزَّن نصاً صريحاً أبداً، ولا يُخرج من `GET /app-config` (حمولة بلا سرّ). صارت القاعدة الحيّة بعد
البذر: **الإعدادات = 22 سطراً**.

**تلميع الكاش (`SettingsStore::HOT_KEYS`):** مفاتيح الثيم/الشركة أُدرجت ضمن المسار الساخن لتُقرأ
بكاش قصير الأمد بدل ضربة أوراكل لكل فتح، مع مراعاة سقف ORA-01461 (٣٠٠٠ بايت) للقيم النصية.

**التحقق الحي (قراءة فقط):** بعد تشغيل `php artisan tinker database/oracle/02_ibac_seed.php` أُحصيت
الكتالوجات: `SELECT COUNT(*) FROM APP_PERMISSIONS` ⇒ **97**، و`SELECT COUNT(*) FROM APP_SETTINGS`
⇒ **22**. لم تُجر أي كتابة يدوية على الجدول business في هذه الجولة خارج سكربت البذر المعتمد.

---

## 2026-10-21 — Oracle: فحص مخطّط تقارير الحسابات (Account Reports Schema Findings)

**نموذج AI:** Qoder Agent · **الأداة:** `oracledb` MCP + `oci8` عبر `yajra/laravel-oci8`.

### اكتشافات المخطّط الحاسمة (لم تكن موثّقة سابقاً)
1. **جدول `ACC_TRXN` غير موجود** داخل `ACCOUNTS`. المحاولة الأولى لكشف الحساب بنيت على `ACC_TRXN` وواجهت `ORA-00942: table or view does not exist`. **المسار الحقيقي** هو:
   ```
   ENTRY_MAIN  ─┐
                ├─►  ENTRY_SUB (DET_NO = ENTRY_NO) ─► ACC_NO ─► CHART_ACC
   ENTRY_SUB   ─┘
   ENTRY_TYPE  ─► كود النوع العربي (TYPE_NAME بعد fixMojibake)
   ```
   أي أن الحركات اليومية تسكن `ENTRY_SUB` لا جدول اختصارات منفصل؛ و`ENTRY_MAIN` يعطي التاريخ ورقم السند الرئيسي.

2. **`CURRENCY` هو جدول رموز العملات، وليس `CUR_CODE` وحده** — `CUR_CODE` يمثّل أزواج أسعار الصرف، بينما `CURRENCY(CUR_NO, CUR_NAME, CUR_SIGN)` هو المرجع. **`CUR_NO = 1` هو اليمنـي المحلي (YR)** — هذا هو الأساس لتصنيف محلي/أجنبي داخل `getGroupStatement`.

3. **`CUR_PRICE.SEQ_PRICE` قد يكون `NULL` للحركات المحلية**. الاعتماد على «هل يوجد سعر صرف؟» لتصنيف محلية/أجنبية يُنتج أخطاءً. **القاعدة الصحيحة**: `CASE WHEN s.CUR_NO = 1 THEN local ELSE foreign END`.

4. **`NLS_CHARACTERSET = WE8MSWIN1252`** (تمّت إعادة التأكيد). كل الحقول النصّية العربية (`DETAILS`, `TYPE_NAME`, `ACC_NAME`, `SUB_NAME`, `PART_NAME`, `ACC_GROUP_NAME`) تعود كـ mojibake Latin-1، ويجب تمريرها عبر `ArabicEncoding::fixMojibake` على الخادم و`ArabicEncodingUtils.fix` على العميل.

### استعلامات الفحص التي تم تنفيذها
```sql
-- للتأكد من وجود ENTRY_SUB والربط مع CHART_ACC
SELECT COUNT(*) FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='ENTRY_SUB';

-- لتأكيد عدم وجود ACC_TRXN
SELECT COUNT(*) FROM ALL_TABLES
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='ACC_TRXN';  -- 0 rows

-- لمعرفة عملة الحسابات المحلية مقابل الأجنبية
SELECT CUR_NO, CUR_NAME, CUR_SIGN FROM ACCOUNTS.CURRENCY ORDER BY CUR_NO;
-- CUR_NO=1 => اليمني المحلي

-- عيّنات لفحص ترميز الحقول
SELECT RAWTOHEX(UTL_RAW.CAST_TO_RAW(TYPE_NAME)) FROM ACCOUNTS.ENTRY_TYPE WHERE ROWNUM<=3;
```

### قرار تصميمي بشأن نافذة كشف الحساب الافتراضية
- **التقرير 1 (مفرد)**: نافذة 15 يوماً **خلف آخر حركة فعلية** للحساب. SQL: `SELECT MAX(ENTRY_DATE) FROM ENTRY_SUB WHERE ACC_NO = :accNo` ثم `:from = MAX - 15d`, `:to = TODAY`. عند عدم وجود حركات → `defaulted=false` والفلاتر فارغة.
- **التقرير 2 (ميزان المجموعة)**: **بلا** نافذة افتراضية — كل السجل التاريخي حتى يُحدّد المستخدم من/إلى. يعكس هذا سلوك `TRIAL_BALANCE_REPORT.RDF` الأصلي.

### ملاحظات الأداء
- استعلام كشف الحساب الفردي يبقي `FETCH FIRST :limit ROWS ONLY` (1000 افتراضياً) لأن `CHART_ACC` المفرد قد يضمّ مئات الآلاف من الحركات عبر سنوات.
- استعلام المجموعة يستخدم `GROUP BY s.ACC_NO, s.CUR_NO` مع `SUM(CASE ...)` للفصل بين العملات، مع `WHERE` تسلسلي يعتمد على أعمق نطاق محدد (`:group_id` → `:acc_part` → `:acc_sub` → `:acc_no`).

### لا تغييرات DDL
هذه المهمة **لم تُنشئ جداول** ولم تُضِف أعمدة — كل التعديلات كانت على طبقة الاستعلام داخل Laravel/Flutter فقط. سجل `db_commends.md` يحتوي على استعلامات SELECT/فحص المخطط فقط.

---

## [2026-10-21 06:17] دورة حياة الجلسات — سلوك كتابة/حذف جديد على `ACCOUNTS.PERSONAL_ACCESS_TOKENS`

**المنفِّذ:** Qoder Agent · **DDL:** لا شيء (لا جدول، لا عمود، لا sequence، لا trigger) · **كتابة:** `DELETE` على البنية التحتية للتوكنات فقط، لا على أي جدول أعمال ERP.

### الجدول المتأثر: `ACCOUNTS.PERSONAL_ACCESS_TOKENS`
الأعمدة المسؤولة عن الجلسة كلها قائمة أصلاً: `EXPIRES_AT`، `LAST_USED_AT`، `CREATED_AT`، `UPDATED_AT` (جميعها `TIMESTAMP(6)`) — لم يُضَف عمود واحد.

### التغير السلوكي (الأهم للقاعدة)
1. **`EXPIRES_AT` يُكتب ويُقارَن الآن على ساعة القاعدة.** سابقاً كان `SessionPolicy` يكتب بتوقيت PHP (`app.timezone = UTC`) بينما `SYSDATE` على `+03:00`، فكل موعد مخزّن كان يبدو متأخراً ثلاث ساعات عند مقارنة القاعدة، وكل إنهاء بـ`SYSDATE - 1` كان يبدو في المستقبل عند قراءة PHP. `SessionPolicy::dbNow()` يقيس الإزاحة من `SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS') FROM DUAL` مرة واحدة في الطلب ويطبّقها.
2. **الصف المنتهي يُحذف، لا يُترك.** `validate()` يمسح التوكن الذي رُفض بانتهاء خمول أو بتجاوز العمر المطلق، و`purgeExpired()` يكنس: (أ) `EXPIRES_AT IS NOT NULL AND EXPIRES_AT < dbNow`، (ب) `EXPIRES_AT IS NULL AND COALESCE(LAST_USED_AT, CREATED_AT) < dbNow - session_idle_minutes`.
3. **فرع (ب) هو علاج التراكم المرصود:** صفّ بلا `EXPIRES_AT` لا يمكن أن «ينتهي» بحساب الموعد، وقد بقي ظاهراً «نشطاً» للأبد. كون الجلسة الحيّة تحصل على موعد من `slide()` في أول طلب بعد عمل السياسة يجعل الصفّ بلا موعد دليلاً على عدم استخدام منذ ذلك الحين.

### حالة البيانات قبل وبعد (قياس مباشر)
| القراءة | قبل | بعد |
|---|---|---|
| إجمالي الصفوف | 22 | 1 |
| `EXPIRES_AT IS NULL` | 20 | 0 |
| منتهية الموعد (`<= SYSDATE`) | 2 | 0 |
| حيّة (`> SYSDATE`) | 0 | 1 |

### ملاحظة تشغيلية لمن يقرأ هذه السطور
الكنس يُجري `DELETE` حقيقياً على بيئة حيّة مشاركة مع النظام القديم — لكنه لا يمسّ إلا ترويسات ميتة (أو خاملة تتجاوز `session_idle_minutes`)، ويُجرى من داخل `SessionPolicy` بأفضل جهد: أي فشل فيه لا يمنع الدخول ولا يُفجّر شاشة الجلسات. جهازٌ لا يزال يحمل توكنًا محذوفًا يستقبل 401 في أول طلب فيمسح تخزينه ويذهب لشاشة الدخول — وهو المسار القائم في العميل، لا مسار جديد.

### لا تغيير على بقية الجداول
`APP_USERS`، `APP_PERMISSIONS`، `APP_USERS_PERMISSIONS`، `APP_SETTINGS`، `APP_USER_ACTIVITY`، `CACHE` — لم تُمَسّ. لا `UPDATE` ولا `INSERT` تنفيذي من هذه المهمة (الكتابة الوحيدة هي `DELETE` التوكنات الميتة الذي هو جوهر الطلب).


---

## 2026-10-21 — SQL فحص انهيار كشف الحساب (قراءة فقط، بلا كتابة)

**نموذج AI:** Qoder Agent · **الأداة:** oracledb MCP — تشخيص انهيار `showDatePicker` (سنة 93422).

### 1) تواريخ حساب 11010001 (سليمة)
```sql
SELECT * FROM (SELECT em.ENTRY_NO,
       TO_CHAR(em.ENTRY_DATE, 'DD/MM/YYYY') AS ENTRY_DATE_FMT,
       TO_CHAR(em.ENTRY_DATE, 'YYYY-MM-DD') AS RAW_DATE,
       DUMP(em.ENTRY_DATE) AS DATE_DUMP
  FROM ENTRY_MAIN em JOIN ENTRY_SUB es ON es.ENTRY_NO = em.ENTRY_NO
 WHERE es.ACC_NO = 11010001
 ORDER BY em.ENTRY_DATE DESC) WHERE ROWNUM <= 5;
-- نتيجتان: 15/04/2025 و 27/03/2025 (DUMP: Typ=12 Len=7 سليم)
```

### 2) الصفوف الفاسدة عبر كل ENTRY_MAIN
```sql
SELECT * FROM (SELECT em.ENTRY_NO,
       TO_CHAR(em.ENTRY_DATE, 'YYYY-MM-DD') AS RAW_DATE, em.ENTRY_DATE
  FROM ENTRY_MAIN em
 WHERE em.ENTRY_DATE > TO_DATE('9999-12-31','YYYY-MM-DD')
    OR em.ENTRY_DATE < TO_DATE('1900-01-01','YYYY-MM-DD')
 ORDER BY em.ENTRY_DATE DESC) WHERE ROWNUM <= 10;
-- وُجدت صفوف بسنة 0025 (مثل ENTRY_NO 4250019965 بتاريخ 0025-06-18)
-- القرار: لا تُصلَح البيانات يدوياً؛ طبقة الحماية الجديدة في التطبيق تتجاهلها.
```

### ملاحظات
- لا `FETCH FIRST n ROWS ONLY` على Oracle 11g (ORA-00933) — استُخدم `WHERE ROWNUM <= n`.
- لم تُنفَّذ أي كتابة/DDL — كلا الاستعلامين SELECT للقراءة فقط.

---

## [2026-10-21 07:32] — حالة `PERSONAL_ACCESS_TOKENS` بعد تفعيل الحذف التلقائي (بلا DDL)
**المنفّذ:** Qoder Agent · **النوع:** behaviour/data observation، لا تغيير مخطط ولا تنفيذ SQL يدوي.

### ما تغيّر في السلوك على القاعدة
- `SessionPolicy::validate()` صار **يحذف** صف التوكن عند الرفض (خمول منتهٍ أو سقف مطلق منتهٍ) بدل تركه `EXPIRES_AT` في الماضي.
- `SessionPolicy::purgeExpired()` يمسح الصفوف الميّتة في فرعين: `EXPIRES_AT < dbNow()`، و`EXPIRES_AT IS NULL AND COALESCE(LAST_USED_AT, CREATED_AT) < dbNow() - idle`. يُستدعى بعد كل دخول (كلمة مرور/بصمة) وفي رأس `SessionAdminController@index`.
- كل حساب الوقت يمر عبر `SessionPolicy::dbNow()` (ساعة أوراكل) — لا `Carbon::now()` — لأن `app.timezone = UTC` مقابل `SYSDATE = +03:00`.

### إحصاء الجدول (قراءة فقط، SQL في `db_commends.md`)
| الوقت | `TOKENS` | بلا موعد | منتهية التاريخ | تراثية خاملة |
|---|---|---|---|---|
| قبل الإصلاح | 22 | 20 | 2 | 0 |
| بعد أول كنس (06:17) | 1 | 0 | 0 | 0 |
| فحص 07:32 | 0 | — | — | — |

الصفوف صفر عند 07:32 لأن لا مستخدم متصلاً الآن — وهذا هو **المؤمل**: الجدول لم يعد يتراكم.
ملاحظة اختبارية: `SUM(CASE …)` فوق مجموعة فارغة يُرجع `NULL` لا `0`.

### الأثر على الاختبارات
`ActiveSessionsTest` كان يفترض وجود صف حقيقي في `PERSONAL_ACCESS_TOKENS` كـ fixture؛ بعد الكنس لم يعد كذلك،
فصار فحص بنية كل صف يُطبَّق على الصفوف الموجودة مع تخطٍّ لطيف عند الجدول الفارغ (نفس نمط اختبار الأسماء العربية).



---

## [2026-10-21 11:07] — مفتاحا الترويسة الإنجليزية في `APP_SETTINGS` (بيانات، بلا DDL)
**المنفِّذ / Executor:** Qoder Agent · **النوع:** إدراج صفوف بيانات في جدول موجود (key-value)، لا تغيير مخطط.
**الطريق / Channel:** موصل `oracledb MCP` مباشرةً على مخطط `ACCOUNTS`.

### ما أُضيف
| `SETTING_ID` | `SETTING_KEY` | `VALUE_TYPE` | `SORT_ORDER` | `IS_LOCKABLE` | `SETTING_VALUE` |
|---|---|---|---|---|---|
| 23 | `company_name_en` | string | 115 | 0 | `ALKABODI FOR MEN's TAILORING` |
| 24 | `company_address_en` | string | 125 | 0 | `Airport Street - Next to Al-shayef House` |

- لا أعمدة جديدة ولا جدول جديد — `APP_SETTINGS` key-value كما هو؛ العدد من **22 إلى 24 صفاً**.
- `SETTING_ID` لم يُذكر صراحةً: `TRG_APP_SETTINGS` (BEFORE INSERT) يمنحه من `SEQ_APP_SETTINGS`؛
  `LAST_NUMBER` كان 23 فلا تصادم.
- `SORT_ORDER` 115/125 لجعل كل مفتاح إنجليزي ملاصقاً لنظيره العربي في شاشة الإعدادات (110←115←120←125).
- التسميات العربية (`NAME_AR`/`DESCRIPTION_AR`) خُزِّنت بايتات Windows-1256 مستعرضة كأحرف لاتينية —
  نفس أسلوب الصفوف 11..22 — وتُصلَح عند القراءة عبر `ArabicEncoding::fixMojibake()`.
- لا `UPDATE` ولا `DELETE` على أي صف قائم.

### الأثر على طبقة التطبيق
- المفتاحان أُضيفا إلى `AppConfig::WRITABLE_KEYS` + `DEFAULTS` على الخادم، و`SettingsStore::set()`
  صار يجد لهما صفاً (وإلا رمى «الإعداد غير معروف»).
- الملف المكافئ القابل للتكرار: `kyApp_API/database/oracle/05_app_settings_company_en.sql`.
- كل SQL (تشخيصي وكاتبي) موثّق حرفياً في `db_commends.md` بنفس الوقت.


## [2026-10-22] كشف عمل القصاص/الخياط — قراءة الجداول (لا DDL)
- **الجداول المستخدمة (قراءة فقط):** `ACCOUNTS.CUTTER_FROM_CALC` (CUTTER_NO, STYLE_NAME, CUTTING_DATE, POST, AMT) و`ACCOUNTS.TAILOR_FROM_CALC` (TAILOR_NO, STYLE_NAME, TAILOR_DATE, POST, AMT, AMT_ALL) + `CUTTER`/`TAILOR` (ACC_NO, CUR_NO) + `CUR_CODE` (CODE, MAIN_CUR_NAME).
- **لا إنشاء/تعديل/حذف:** التقرير يقرأ فقط؛ `AMT` للقصاص = الإجمالي (السعر يُحسب AMT/POST)، `AMT_ALL` للخياط = الإجمالي النهائي (يتضمن ADDCOST2/3).
- **الفلترة:** `CUTTER.ACC_NO=:acc AND CUTTING_DATE BETWEEN TO_DATE(from) AND TO_DATE(to)` — نفس صيغة الـ RDF الأصلي.
- **الترميز:** `STYLE_NAME` مخزّن Windows-1256 ويصل mojibake (مثل `ÞØÑí`)؛ يُصلَح عبر `ArabicEncoding::fixMojibake` بالخادم و`ArabicEncodingUtils.fix` بالعميل.
- **التحقق عبر oracledb MCP:** ACC_NO=12910001 (قصاص) و12910004 (خياط) أرجعا أسطراً مطابقة لقيم PDF المرفق (قطري/حجازي/قطري جاهز + الأسعار 400/700/250/1600...).


## [2026-10-22] الفترة الافتراضية لكشف العمل = MAX(تاريخ العمل) للعامل (قراءة فقط)
- **منطق جدید (قراءة):** تحدید آخرین یوم عمل عبر `SELECT TO_CHAR(MAX(w.CUTTING_DATE/TAILOR_DATE),'YYYY-MM-DD')` بالربط على `ACC_NO` — لا DDL ولا جداول جدیدة.
- **تحقّق oracledb MCP:** قصاص `ACC_NO=12910001` => آخر یوم 2026-08-16 بأسطر (حجازي 8/5600، عُماني 7/2800، قطري 12/4800)؛ خیاط `ACC_NO=12910004` => آخرین یوم 2026-08-16.
- **سلوك آمن:** عند عدم وجود أي سجل للعامل یعود الكود إلى تاریخ الیوم (لا یُرجع خطأ).


## [2026-10-22] لا تغییر في قاعدة البیانات (إصلاح واجهة/شبكة فقط)
- الإصلاح یتعلّق بتجاوز تخطيط في شاشة كشف العمل (Flutter) وبسُلوك ترويسة HTTP في عمیل Dio (CORS) — لا SQL جدید، لا DDL، لا جداول.
- الاستجابة المرجعة من `work-report` تأیّد سلیمة (success:true، الفترة الافتراضیة 16/08/2026 مع الأسطر) قبل وبعد الإصلاح.

---

## [2026-10-22] لا تغییر في قاعدة البیانات (تقریر كشف عمل مجموعة — قراءة فقط)
- تقریر "كشف عمل مجموعة" جدید **یقرأ فقط** من نفس الجدولین المستخدمین فيكشف العمل الفردی:
  `ACCOUNTS.CUTTER_FROM_CALC` (CUTTER_NO, STYLE_NAME, CUTTING_DATE, POST, AMT) و
  `ACCOUNTS.TAILOR_FROM_CALC` (TAILOR_NO, STYLE_NAME, TAILOR_DATE, POST, AMT, AMT_ALL).
- الفرق عن الفردي: **بدون فلترة `r.ACC_NO=:acc`** — یُجلب عمل **جمیع** القصاصین أو **جمیع** الخیاطین.
  یُضاف `r.CUTTER_NAME`/`r.TAILOR_NAME` كالعمود الأول، والترتیب `ORDER BY r.NAME, w.DATE, w.STYLE`.
- صیغة الفلترة الزمنیة تبقى مطابقة لنموذج أوراكل FOR_CUTTER_CALC.RDF:
  `w.CUTTING_DATE BETWEEN TO_DATE(:from,'YYYY-MM-DD') AND TO_DATE(:to,'YYYY-MM-DD')+1-1/86400`.
- **التحقق عبر oracledb MCP:** الفترة `22/06/2026..25/06/2026` أعادت 24 سطراً بمجموع
  `SUM(QTY)=236` و `SUM(TOTAL)=71050` — مطابق تماماً لقيم PDF المرفق (FOR_CUTTER_CALC.pdf).
- **لا DDL، لا sequences، لا triggers جدیدة.** لا سطر ID new.
- **الترميز:** `CUTTER_NAME` و `STYLE_NAME` یصلان mojibake (WE8MSWIN1252) — یُصلَحان
  بـ `ArabicEncoding::fixMojibake()` في الخادم و `ArabicEncodingUtils.fix()` في العميل (مطابق للفردي).
- **الصلاحيات:** `cutters.statement` للمسار `/workers/cutters/group-work-report` و
  `tailors.statement` للمسار `/workers/tailors/group-work-report` — لا أكواد IBAC جدیدة.


## [2026-10-22 09:15] تجميع كشف عمل مجموعة — استعلام READ-only (SELECT/GROUP BY فقط، لا DDL)
- لا تغييرات على مخطط قاعدة البيانات. تم تعديل الاستعلام داخل WorkerController فقط من أسطر لكل سجل إلى تجميع لكل (عامل + موديل).
- تحقق SELECT للقصاصين للفترة 22/06/2026 - 25/06/2026: 10 أسطر مجمّعة، SUM(QTY)=236، SUM(TOTAL)=71050 (مطابق للإجــمالي في FOR_CUTTER_CALC.pdf بعد ضغط 24 سجلاً).


## [2026-10-23 10:30] قسم «الخدمات والمزودين» — لا DDL، قراءة/كتابة عبر TAPI وDBMS_SCHEDULER فقط
**النموذج:** Qoder Agent
- **لا إنشاء جداول أعمال ولا sequences ولا triggers.** الجداول الثمانية موجودة أصلاً في مخطط
  `ACCOUNTS`: `PROVIDERS`, `PROVIDERS_DTL`, `SERVICES`, `CORP`, `MSG_QUEUE`, `MSG_ARCHIVE`,
  `W_MSG_QUEUE`, `W_MSG_ARCHIVE` (تم التحقق عبر oracledb MCP).
- **توليد المعرّف بلا sequence:** `PROVIDERS`/`PROVIDERS_DTL` لا يملكان sequence ولا trigger،
  فتُحسب `NVL(MAX(PROVIDER_ID),0)+1` داخل المتحكّم؛ التسابق مقبول لسجل منخفض التزامن.
- **الإرسال عبر الطابور فقط:** الكتابة إلى `*_QUEUE` بـ `IS_SENT='N'` (عبر `MSG_QUEUE_TAPI` حيث
  وُجد)؛ الإرسال الفعلي (Java `SendMessage`/`WhatsappSender`) يحدث داخل مهمة أوراكل لا في الـ API.
  دلالة `IS_SENT`: N منتظرة (في `*_QUEUE`)، Y مُرسلة، F فاشلة (في `*_ARCHIVE`).
- **CORP singleton بلا عمود مفتاح:** UPDATE لصفّ وحيد بشروط محدّدة داخل نطاق هذا العمل؛ لا محاولة
  إضافة PK.
- **المهام عبر `DBMS_SCHEDULER`:** قائمة/تاريخ من `USER_SCHEDULER_JOBS` و`USER_SCHEDULER_JOB_RUN_DETAILS`
  (قراءة فقط)، و`CREATE_JOB`/`SET_ATTRIBUTE`/`ENABLE`/`DROP_JOB` للتحكم — لا واجهات سطر أوامر ولا
  عامل طابور جديد. المهام الثلاث القائمة مُفعّلة: `SEND_MSG` (كل 3ث)، `W_SEND_MSG` (كل 20ث)،
  `W_SEND_MSG_F` (كل 14د).
- **الترميز:** أعمدة العربية (`PROVIDER_NAME`, `MSG_TEXT`, `CORP.*`, `SERVICES.*`) تصل mojibake
  (WE8MSWIN1252) — تُصلَح بـ `ArabicEncoding::cleanData/fixMojibake` عند القراءة و`toOracleSearchChars`
  عند الكتابة/البحث.
- **بثّ الكتالوج:** شغّلنا `02_ibac_seed.php` (idempotent عبر `PermissionCatalog::rows()`) لإدراج
  30 كودًا جديدًا → 127؛ لم نُنشئ جداول IBAC (موجودة) ولا منحًا أساسية (المدير `IS_ADMIN=1` يتجاوز).

---

### إصلاح خلل قراءة الأعمدة في قسم الخدمات — 2026-10-23 07:32 (Qoder agent)

- **طبيعة البيانات:** `yajra-oci8` يُعيد أسماء أعمدة أوراكل بأحرف صغيرة snake_case (`provider_id`,
  `msg_text_preview`, `job_name`, `corp_name`). لا تغيير في هيكل الجداول؛ التصحيح في طبقة
  القراءة فقط (الموديلات على العميل + سطرين في متحكّمين على الخادم).
- **عطل SQL/PHP:** `MessageChannelController::index` عند `status=all` كان يفرز الصفوف على
  `['ID']` فينهار «Undefined array key "ID"» لأن المفتاح الفعلي `id` — أُصلح بقراءة `id ?? ID`.
  نفس النمط في `ProviderController::toggle` مع `status ?? STATUS`.
- **لا DDL / لا هجرات / لا sequences:** لم يُنشَأ أو يُعدَّل أو يُحذف أي جدول؛ لا يزال توليد
  المعرّفات `NVL(MAX,0)+1` والإدراج في الطوابير فقط بـ `IS_SENT='N'`.

### ترتيب الرسائل الأحدث أولاً + تفعيل تعديل/حذف الطابور — 2026-10-23 08:10 (Qoder agent)

- **لا DDL / لا هجرات:** لا تغيير في هيكل أي جدول. العمل في طبقة الاستعلام والكود فقط.
- **الترتيب:** `MessageChannelController::index` صار `ORDER BY CREATED_AT DESC, ID DESC` لكل مصدر فردي،
  ومفتاح ترتيب مركّب (`CREATED_AT` + `ID` ممدّد بأصفار) لدمج `status=all` — قراءة صغيرة-الأحرف آمنة
  (`created_at ?? CREATED_AT`, `id ?? ID`).
- **كتابة قائمة (UPDATE/DELETE):** مسارات `PUT`/`DELETE /{sms|whatsapp}/messages/{id}` كانت موجودة فعلًا
  وتعمل على جدول `*_QUEUE` فقط (تُرفض صفوف الأرشفة المُرسلة/الفاشلة); لم تُضَف مسارات جديدة — أُضيف
  الربط على جهة العميل (مستودع/notifier/واجهة). لا SQL يدوي مُنفَّذ؛ يتم حصريًا عبر المتحكّم خلف `sms.*`/`whatsapp.*`.

### ترحيل IBAC: استبدال أكواد الكشف العامة بتسعة دقيقة · 2026-10-24 14:30 (Qoder agent)

**السياق:** خطة `تطوير_وتوسيع_نظام_الصلاحيات_IBAC` — أربع أكواد كشف عامة
(`accounts.statement`، `employees/cutters/tailors.statement`) تستبدل بتسعة دقيقة
(3 للحسابات + كشفان لكل قسم من أقسام العاملين الثلاثة).

**DDL:** لا. لم يُنشأ أي جدول ولا عُدّل أي هيكل ولا أُضيف/يُحذف أي sequence أو
trigger أو FK أو column. كل التغيير DML على `ACCOUNTS.APP_PERMISSIONS` فقط
(INSERT/DELETE صفوف)، و`ACCOUNTS.APP_USERS_PERMISSIONS` (DELETE صفّ — لم يوجد).

**ما نُفِّذ بالترتيب (عبر oracledb MCP + `php artisan tinker database/oracle/02_ibac_seed.php`):**

1. **قراءة البداية:** `SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS` → `127`
   (الحالة قبل التوسيع؛ الأكواد الأربعة العامة موجودة برقمي 33/40/47/54).
2. **تشغيل البذر:** `02_ibac_seed.php` — idempotent، قائدي على
   `PermissionCatalog::rows()`. الخرج:
   `PERMISSIONS catalog=132 inserted=9 updated=123 total=136`.
   التسعة الجديدة هم IDs 129..137:
   - `employees.statement_financial` (129)، `employees.statement_work` (130)
   - `cutters.statement_financial` (131)، `cutters.statement_work` (132)
   - `tailors.statement_financial` (133)، `tailors.statement_work` (134)
   - `accounts.statement_financial` (135)، `accounts.statement_group` (136)،
     `accounts.statement_detail` (137).
   العربية كُتبت عبر `ArabicEncoding::toOracleSearchChars()` — فحص
   `ASCIISTR(NAME_AR)` يُظهر بايتات CP1256 (0xDF/0xD4/0xDD = "كشَف")، متسق مع
   النمط الذي يقرأه `fixMojibake` عند العرض.
3. **جرد منح الأكواد العامة قبل الترحيل:**
   `SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE PERMISSION_ID IN
   (33, 40, 47, 54)` → `0`. لا مستخدم يملك أي كود عام، فلا حاجة لترحيل منح.
4. **DELETE منح العامة (أمان دفاعي):**
   `DELETE FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE PERMISSION_ID IN (SELECT
   PERMISSION_ID FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE IN
   ('accounts.statement','employees.statement','cutters.statement','tailors.statement'))`
   — صفر صفوف فعلياً.
5. **DELETE الأكواد العامة من الكتالوج:**
   `DELETE FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE IN (...العامة
   الأربعة...)` — 4 صفوف.
6. **التحقق:**
   - `COUNT(*)` = **132** ✓ (مطابق لـ `PermissionCatalog::count()`).
   - العامة المتبقية = **0** ✓.
   - الدقيقة الموجودة = **9** ✓.
   - منح يتيمة (`NOT EXISTS` إلى APP_PERMISSIONS) = **0** ✓.
   - `IS_ACTIVE=1` = **132** ✓.

**سكربتات التسليم:** `database/oracle/06_ibac_statement_split.sql` و
`database/oracle/07_ibac_statement_split_verify.sql` — كُتبتا لهذا الترحيل؛
لكن نظراً لصفر منح عامة، الترحيل الفعلي تمّ ببضع DELETEs مباشرة عبر MCP مع
تشغيل `02_ibac_seed.php`. السكربت المُسلَّم يبقى صالحاً لإعادة استخدامه إن ظهر
حامل عام في بيئة أخرى.

**Commit:** لا. لم يُطلب. لا تعديل هيكل/DDL — فقط DML على جدول PIM موجود.

### ترحيل IBAC إضافي: صلاحيات تقرير عمل المجموعة · 2026-10-24 18:45 (Qoder agent)

**DDL:** لا.

**DML:**
- `02_ibac_seed.php` شُغِّل مرة ثانية بعد إضافة `cutters.group_work_report` و
  `tailors.group_work_report` في `PermissionCatalog::MODULES['cutters']['extra']`
  و`['tailors']['extra']`. الخرج: `inserted=2 updated=132 total=134`.
- الصفوف الجديدة في `ACCOUNTS.APP_PERMISSIONS`: IDs 138 و139 (IS_ACTIVE=1،
  NAME_AR مكتوبة بـ CP1256 عبر `toOracleSearchChars()`).
- لا `INSERT` يدوي في `APP_USERS_PERMISSIONS` — التوسيع يضيف الأكواد للكتالوج
  فقط؛ المستخدم يقرّر لاحقاً عبر شاشة المنح من يملكها.

**تحقق:** `SELECT COUNT(*) FROM APP_PERMISSIONS = 134` ✓؛ العامة = 0؛ الدقيقة
للكشوف = 9؛ مجموعة العمل = 2؛ منح يتيمة = 0.


## [2026-10-24 05:20] الشجرة المحاسبية: قاعدة البيانات والاستعلامات (بلا DDL إطلاقاً) · Qoder Agent

**الحدود:** لا إنشاء/تعديل/حذف لأي جدول أو عمود أو sequence أو trigger أو FK في schema
`ACCOUNTS` — القاعدة تراثية وليست ملكنا للترحيل. كل ما نُفِّذ هو **استعلامات قراءة**
وأخطاء في كود PHP أُصلحت لتطابق الواقع المخزّن.

**حقائق تم التحقق منها من `ACCOUNTS` الحيّة (oracledb MCP + Pest مقابل نفس القاعدة):**
- `ACCOUNT` = **4** أقسام، `ACC_MAIN` = **24**، `ACC_SUB` = **95**، `ACC_SUB_GROUP` = **12** —
  هذا هو الهيكل كله، وكان لا يظهر منه شيء تقريباً.
- `CHART_ACC` = **20,954** حساباً؛ **20,671** منها `GROUP_ID = NULL`.
- حسابات بادئة `123` (العملاء) = **20,469** حساباً، ومجموعتا 123 هما `5` و`6` فقط؛
  أرصدتها تدخل التجميع وتُستثنى من العرض عدا `12310000` (عملاء الكبودي للخياطة).
- حركة جزء 123: `DR = 2,079,529,784.48` / `CR = 2,014,835,990.65` / `NET = 64,693,793.83`
  على **155,621** سطراً من `ENTRY_SUB` — بينما `ACC_SUB.BALANCE` للجزء 123 = **0**.
- عدد الحسابات لكل مجموعة: `G3 = 108` (الأكبر)، `G4 = 99`، `G7 = 26`، `G8 = 22`، `G2 = 10`،
  `G6 = 8`، `G11 = 4`، `G5 = 2`، `G9 = 2`، `G1 = 1`، `G12 = 1`، `G10 = 0` (مجموعة فارغة
  يجب أن تبقى ظاهرة في الهيكل).
- لا مجموعات يتيمة: كل `CHART_ACC.GROUP_ID` موجود في `ACC_SUB_GROUP`.

**قاعدة التراتب الصحيحة (كانت معطوبة):** `SUBSTR(TO_CHAR(ACC_NO), 1, 3) = ACC_PART`.
الكود القديم كان يستخدم `TRUNC(ACC_NO/10000)` في `getDetailedStatement` وفي ترقيم
الإنشاء، فينتج بادئة رباعية الأرقام (`1231`) لا تطابق `ACC_PART` ثلاثياً (`123`). الصيغة
الصحيحة كانت مستخدمة أصلاً في `getGroupStatement`، فحُدِّت البقية عليها.

**مصدر الأرصدة:** `ENTRY_SUB` وحده. صيغة التجميع المعتمدة في دوال التجميع
(`movementAggregateSql()`/`movementBalancesByChart()`/`movementBalancesFor()` — وهي
ما سمّته الخطة `balanceMap()`) وفي أبناء
الشجرة:
```sql
SELECT es.ACC_NO,
       SUM(CASE WHEN es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END) DR,
       SUM(CASE WHEN es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END) CR,
       SUM(es.ENTRY_MNT) NET, COUNT(*) CNT
FROM ENTRY_SUB es
[INNER JOIN ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
 WHERE em.ENTRY_DATE BETWEEN TO_DATE(:f,'YYYY-MM-DD') AND TO_DATE(:t,'YYYY-MM-DD')]  -- عند الفترة
GROUP BY es.ACC_NO
```
- `ENTRY_MNT` موقّع: الموجب مدين والسالب دائن، وهو نفس تفسير كشوفات المشروع الحالية.
- التجميع يُرقَّى عبر `CHART_ACC(ACC_NO → GROUP_ID)` ثم قواعد البادئة
  (`acc_part = SUBSTR(ACC_NO,1,3)`، `acc_sub ← ACC_SUB.ACC_PART`، `قسم ← ACC_MAIN.ACC_SUB`)،
  والحسابات بلا مجموعة تُرقى إلى مستوى `acc_part`. أعمدة `BALANCE` المخزّنة تُعرض في ورقة
  التفاصيل للمقارنة فقط باسم `stored_balance`.
- `ENTRY_SUB` = **422,408** صفاً، و`ENTRY_SUB_BRW_I1` على `ACC_NO` يجعل الـ JOIN بالتاريخ عملياً؛
  الفترة اختيارية (`from_date`/`to_date` بصيغة `YYYY-MM-DD`).

**ترقيم Oracle-11g (بلا `FETCH FIRST`):** نمط `ROWNUM` ثلاث طبقات كما في `getChartAccounts`
- `SELECT * FROM (SELECT a.*, ROWNUM rnum FROM ( …استعلام الصفوف… ) a WHERE ROWNUM <= :max_row) WHERE rnum > :offset`.

**ترقيم الحساب الجديد (بلا sequence لجدول الحسابات):** `ACC_NO = accPart * 100000 + (MAX(اللاحقة) + 1)`
— التحقق: `110 → 11010002` (معاينة `GET /accounts/next-number` تساوي تماماً ما يفعله
`POST /accounts/chart`)؛ والعقد الهيكلية تأخذ `MAX+1` داخل نطاقها (`ACC_MAIN.ACC_SUB` داخل
القسم، و`ACC_SUB.ACC_PART = ACC_SUB*10 + التالي متاح`).

**OCI8 gotcha موثّق:** أعمدة النتائج تصل **أحرفاً صغيرة** و**نصوصاً** (`SELECT COUNT(*) AS C`
تصل `['c'] => '108'`)؛ لذا كل قراءة خام في المتحكم والاختبارات تفحص المفتاحين وتحوّل
الصريح إلى رقم.

**نتيجة الفحص الحيّ (php artisan serve + رمز Sanctum حقيقي):**
- `GET /api/accounts/tree` → 200، `total_nodes = 134` (4/24/95/10 + حساب عملاء واحد معروض)،
  رصيد `ACCOUNT=1` المحسوب `1,037,888,703.43` على **314,584** حركة.
- بنفس الطلب مع `from_date=2024-01-01&to_date=2024-01-31` → الرصيد `16,319,728.58` على 4,336
  حركة: التقويض بالفترة يعمل.
- `GET /api/accounts/tree/children?level=group&group_id=3` → 200، `total = 108`،
  صفحة 1 تبدأ `12910003` وصفحة 2 تبدأ `12910019` (متصلة بلا تراكب)، والصفيف الكامل يعيد
  `stored_balance = 475,645` مقابل `debit = 12,273,914 / credit = 9,970,916 / balance = 2,302,998`
  على 601 حركة — دليل مباشر على أن العمود المخزّن ميت وأن المحسوب هو الصحيح.
- `GET /api/accounts/search?q=1101` → يعيد `11010001` مع `parent_path`.
- بلا رمز → **401** على `/accounts/tree`.

**عدد الاستعلامات (توضيح دقيق عن رقم الخطة):** قالت الخطة «5 استعلامات» و**النُفِّذ 7
ثابتة العدد** لكل طلب هيكل: أربعة `structureRows` (المستويات الأربعة) +
`movementBalancesByChart` + `chartGroupMap` + `chartCountBuckets` (تجميع `GROUP BY`
واحد على `CHART_ACC` بدل عدّ كل عقدة على حدة). المهم الوظيفي — إلغاء N+1 (كان
~140 استعلاماً) وجعل العدد مستقلاً عن عدد الحسابات — محقق؛ وزمن الاستجابة الحيّ
≈ 1 ث للهيكل الكامل مقابل مهلة 30 ث في المستودع. لم تُزد استعلامات حسب حجم البيانات.

---

## [2026-10-24 09:24] نقطتا `/accounts/export-tree` و`/accounts/currencies` — قراءة فقط، بلا DDL · Qoder Agent

**لا شيء هيكليًا:** لم يُنشأ جدول ولا عمود ولا sequence؛ لم تُعدَّل `APP_PERMISSIONS` ولا
`APP_SETTINGS`. الكودان `accounts.export` و`accounts.print` مستقرّان في الكتالوج منذ الجولة
السابقة، والنقطتان الجديدتان تُقرآن الجداول التراثية نفسها
(`ACCOUNT`/`ACC_MAIN`/`ACC_SUB`/`ACC_SUB_GROUP`/`CHART_ACC`/`ENTRY_SUB`/`CURRENCY`).

**قرارات مقرونة بالقاعدة:**
- **`CHART_ACC` لا يملك عمود عملة** (أعمدته الثمانية: `ACC_NO, ACC_NAME, GROUP_ID, BALANCE,
  LIMITED_BALANCE, STOPPING_ACC, SEQ, ACC_DATE`) — لذا يورَّث `CUR_NO` من الحساب الجزئي صاحب
  البادئة، وفي العميل لا يُعرض منتقي العملة إلا لـ `ACC_MAIN` و`ACC_SUB` (وهما الجدولان اللذان
  يخزّنانه). إنشاء مجموعة/مالية لا يرسل عملة لأن الخادم سيرميها بصمت.
- **التصدير يقرأ من القاعدة لا من حالة الشاشة:** الشجرة كسولة (مستوى-بمستوى) فأسطر العرض لا
  تحتوي إلا ما فتحه المستخدم؛ `exportTree` يجلب `CHART_ACC` بالبادئات المطلوبة فقط —
  `SUBSTR(TO_CHAR(ACC_NO),1,3) IN (:part_0, :part_1, …)` مع ربط القيم (لا إلصاق نصي)،
  وحارس العملاء `SUBSTR(TO_CHAR(ACC_NO),1,3) <> 123 OR ACC_NO = 12310000` إلا بطلب صريح.
- **الأرصدة لا تُقرأ من `BALANCE` المخزّن:** تستخدم النقطة نفس
  `movementBalancesByChart()` + `chartGroupMap()` + `chartCountBuckets()` + `rollUpBalances()`
  التي تستخدمها `/accounts/tree`، واختبار التكافؤ يقارن رصيد كل صف مُصدَّر برصيد العقدة في
  الشجرة مقابل Oracle حيّ — فلا تتباعد المطبوعة عن الشاشة رقمًا.
- **`/accounts/currencies` بصلاحيات الحسابات:** `SELECT CUR_NO, CUR_NAME FROM CURRENCY ORDER BY CUR_NO`
  خلف `accounts.view,create,update,structure_manage` لا `currencies.view`؛ المنطق أن الاستعلام
  يخدم نموذج إنشاء حساب، ومن يملك الإنشاء يجب أن يقرأ الدليل. إعادة تسمية المفاتيح الصغيرة
  (`array_change_key_case`) وإصلاح التشكيل (`ArabicEncoding::fixMojibake`) كما في كل قراءة Oracle.
- **`levels` أبيض-list:** `{account,main,sub,group,chart}`؛ قيم غير معروفة تُسقط، والفارغ =
  الكل. لا يُمرَّر أي مدخل إلى SQL خارج هذه القائمة، والربط دائمًا بالـ bind parameters.

**ما نُفِّذ فعليًا مقابل القاعدة في هذه الجولة (كله `SELECT`):** استعلامات `structureRows`
الأربعة + `movementBalancesByChart` (تجميع `ENTRY_SUB` بفترة اختيارية) + `chartGroupMap` +
`chartCountBuckets` + قراءة `CHART_ACC` بالبادئات + `SELECT CUR_NO, CUR_NAME FROM CURRENCY`،
وفحوص الاختبارات:
```sql
SELECT COUNT(*) AS C FROM CHART_ACC WHERE SUBSTR(TO_CHAR(ACC_NO), 1, 3) = '123';
SELECT m.ACC_NO AS A FROM ACC_MAIN m
 WHERE m.ACC_SUB = (SELECT ACC_SUB FROM ACC_SUB WHERE ACC_PART = 110);
SELECT COUNT(*) AS C FROM CURRENCY;
```
ولا `INSERT/UPDATE/DELETE` إطلاقاً — الاختبارات تستخدم `Sanctum::actingAs` فلا تكتب صفوف
`PERSONAL_ACCESS_TOKENS` (بخلاف جولة الفحص الحيّ السابقة التي أنشأت رمزَين وحذفهما).

**البوابات:** Pest `AccountTreeExportTest` = 8 passed / **10,835 assertion** مقابل Oracle حيّ،
`BusinessRoutesSealedTest` = 6 passed، `pint --dirty` = passed.

---

## [2026-10-24 14:44] جولة إصلاح ثانية — لا DDL ولا DML، وتثبيت حقيقة أعمدة العملة (Qoder Agent)

**لم يُنفَّذ أي أمر مقابل Oracle في هذه الجولة** (لا DDL، لا DML، ولا قراءة مباشرة). ما يلي توثيق
حقيقة مخطط قائمة موجودة مسبقاً هي التي حدّدت شكل الإصلاح في الواجهة، لأن المستخدم بلّغ أن «حقل
اختيار العملة غير موجود» في نموذج إنشاء حساب.

### أعمدة `CUR_NO` في مستويات دليل الحسابات — المرجع الحاسم

| الجدول | `CUR_NO`؟ | النتيجة في نموذج الإنشاء |
|---|---|---|
| `ACC_MAIN` (الحساب الرئيسي — مفتاحه الظاهر `ACC_SUB`) | **نعم** | منتقي عملات حقيقي (`DropdownButtonFormField`) |
| `ACC_SUB` (الحساب الجزئي) | **نعم** | منتقي عملات حقيقي |
| `CHART_ACC` (دليل الحسابات — 8 أعمدة) | **لا** | حقل **للقراءة فقط** يعرض عملة `ACC_SUB` الأعلى |
| `ACC_SUB_GROUP` (المجموعة) | **لا** | حقل **للقراءة فقط** كما أعلاه |
| `CURRENCY` / `CUR_CODE` / `CUR_PRICE` | — | مصدر القائمة (`/accounts/currencies`)؛ لا تغيير عليها |

- **لماذا هذا مهم:** لا يمكن إضافة عمود عملة إلى `CHART_ACC`/`ACC_SUB_GROUP` — المخطط ملك نظام
  ERP آخر ونحن قرّاء له فقط (لا migrations لأعمال `ACCOUNTS`). لذلك كان الحلّ الصحيح هو إظهار
  العملة **الموروثة** بدل إخفاء السطر كله (وهو الخطأ الذي بلّغ عنه المستخدم) وبدل إضافة عمود.
- **المسار الوراثي المستخدم:** الحساب الجزئي المختار (`ACC_PART`) → صفّه من `ACC_SUB` → عموده
  `CUR_NO`، وتُقرأ على جانب العميل عبر `parentAccSubProvider(accSub)`؛ لا استعلام Oracle جديد ولا
  endpoint جديد.
- **`AccountModel` / `AccMainModel` / `AccSubModel`** كلها تعرّف `curNo` أصلاً، فالحقل الموروث لم
  يحتج أي تعديل نموذج أو أي تغيير في مخطط.
- **التصدير/الطباعة:** لا علاقة لـ Oracle بالـ 404 المُبلَّغ عنه — سببه خادم API أقدم على جهاز آخر
  (192.168.0.9، مسارات `C:\kyApp_API`) لا يعرف `accounts/export-tree`. لا تنفيذ SQL جديد لهذا أيضاً.

**خلاصة:** صفر تغيير مخطط، صفر SQL، صفر DDL — التوثيق أعلاه تثبيت لحقيقة قائمة لا اكتشاف جديد.

---

## [2026-10-24 15:20] جولة 3 — عملة الحساب المالي في الخانة الرابعة من رقمه (تثبيت قاعدة، بلا DDL)

**الحقيقة المخطّطية المُثبّتة بالتحقق القراءة فقط عبر oracledb MCP:** جدول `CHART_ACC` لا يملك
عمود `CUR_NO`، وليس خطأً بل تصميم النظام التراثي: **عملة الحساب المالي مشفَّرة في رقم نفسه**.
القاعدة: `ACC_NO = ACC_PART(3 خانات) + CUR_NO(خانة واحدة = الرابعة من اليسار) + التسلسل(4)`.
القراءة من اليسار ثابتة للأرقام ثمانية الأرقام (عادية) وتسعة الأرقام (العملاء 123110000…).
أمر إضافة عمود أو جدول مرفوض صراحةً من المستخدم، فالحلّ كلّه بلا أي DDL.

**التحقق القراءة فقط (Oracle 11g):**
- `ALL_TAB_COLUMNS`: `ACCOUNT`/`ACC_MAIN`/`ACC_SUB` تملك `CUR_NO NUMBER NULLABLE`؛
  `ACC_SUB_GROUP` ثلاثة أعمدة فقط؛ `CHART_ACC` ثمانية أعمدة بلا `CUR_NO`؛ `ENTRY_SUB` تسعة أعمدة
  (`SEQ_PRICE` تحمل سعر العملة في الحركة، لا في الحساب).
- توزيع الخانة الرابعة: `SUBSTR(TO_CHAR(ACC_NO),4,1)` أعطت 1=10425، 2=41، 3=22 (و1 في العملاء
  تسعة الأرقام) — لا قيمة رابعة مستخدمة فعليًا.
- `CURRENCY` (بـ ASCIISTR): 1 ريال، 2 دولار، 3 سعودي، 4 يورو.
- دليل النطاق: الجزء 251 → 25110017(عملة1) / 25120016(عملة2) / 25130011(عملة3)؛ الجزء 121 →
  1212000x و1213000x. أي كل عملة داخل نطاق عشرة آلاف رقم خاص بها.

**تصحيح منطق ترقيم (تطبيقي لا مخطّطي):** كان `MAX(ACC_NO)` على `[part*100000, +100000)` يمتد
عبر كل العملات فيأخذ أعلى عملة ترتيبًا؛ النطاق الصحيح `[part*100000+cur*10000, +10000)` يعزل
كل عملة. أُضيفت قراءة `cur_no` مشتقة من الرقم في كل مسارات الشجرة/البحث/التفاصيل/التصدير.

**خلاصة:** صفر DDL، صفر DML، صفر إنشاء جدول/عمود — استعلامات `SELECT` توثيقية فقط للتحقق،
والمتغيّر الوحيد في القاعدة أنه صار يُقرأ من الرقم ويُتحقّق منه بدل أن يُفتَرَض.

---

## [2026-10-25 10:00] الكشوفات الشخصية: عمود `ACC_NO` في `APP_USERS` + بذر أكواد `my_statement` · Qoder Agent

هذه الجولة نفّذت **DDL وDML حقيقيين** مقابل Oracle عبر oracledb MCP (على خلاف الجولات السابقة
القراءة‑فقط) — لأن ربط الموظف بحسابه المالي يتطلب عموداً جديداً في `APP_USERS` (جدول تحكمنا).

**DDL:**
```sql
ALTER TABLE ACCOUNTS.APP_USERS ADD ACC_NO NUMBER;
COMMENT ON COLUMN ACCOUNTS.APP_USERS.ACC_NO IS 'رقم الحساب المالي المرتبط بالمستخدم (CHART_ACC.ACC_NO)';
```
- `NUMBER` **nullable** (`ALL_TAB_COLUMNS` بعد التنفيذ: `NUMBER/Y`) — العملاء والمدراء بلا حساب
  عامل يبقون `NULL` بلا كسر؛ `AuthController::userPayload` يعيد `acc_no: null` لهم.
- **بلا `FOREIGN KEY`:** `CHART_ACC` مخطط نظام ERP آخر قرّاءٌ له فقط، فالربط منطقي تطبيقياً
  (`APP_USERS.ACC_NO → CHART_ACC.ACC_NO`) لا قيد schema.
- التعبئة يدوياً أو من شاشة إدارة المستخدمين (`UserAdminController` صار يقبل `acc_no`).

**DML — بذر الكتالوج:** أُضيفت وحدة `my_statement` إلى `PermissionCatalog::MODULES` ثم أربعة
INSERT في `ACCOUNTS.APP_PERMISSIONS` (IDs صريحة):
```
140  my_statement.*          IS_CORE=0   (wildcard)
141  my_statement.view       IS_CORE=1   (core)
142  my_statement.financial  IS_CORE=0   (extra)
143  my_statement.work       IS_CORE=0   (extra)
```
- **تزامن الـ sequence:** `SEQ_APP_PERMISSIONS.LAST_NUMBER` كان متأخراً (102) عن
  `MAX(PERMISSION_ID)` (139)، فقورنت الأربعة IDs يدوياً 140–143، ثم دُفع الـ sequence فوق 143
  بتقنية increment‑ثم‑decrement لتجنّب تصادم التوليد اللاحق.
- `NAME_AR` بترميز CP1256 (نفس نمط `WE8MSWIN1252` المتّبع في كل البذر).
- **لا `INSERT` في `APP_USERS_PERMISSIONS`** — المنح قرار المستخدم عبر شاشة الصلاحيات.

**تحقق (SELECT، حيّ):** `COUNT(*) FROM APP_PERMISSIONS` = **138** (134 + 4)؛ الأكواد الأربعة
موجودة بـ `IS_ACTIVE=1`؛ عمود `ACC_NO` في `APP_USERS` بـ `DATA_TYPE=NUMBER`, `NULLABLE=Y`.

**قرارات منطقية مقرونة بالقاعدة:** نقطة `/my-statement/work` لا تملك عمود «نوع» — بل تكتشف
خياط/قصاص بعدّ `TAILOR_FROM_CALC.TAILOR_ACC` مقابل `CUTTER_FROM_CALC.CUTTER_ACC` على `ACC_NO`
للمستخدم؛ والخياط ذو أولوية إن وُجد في كليهما. المخطّط لم يتغيّر لذلك في هذين الجدولين.

---

## 2026-10-24 — حقل «الحساب المالي» ACC_NO في واجهة المستخدم (Claude)

**لا تغيير مخطّطي.** عمود `ACCOUNTS.APP_USERS.ACC_NO` (`NUMBER`, nullable) يبقى كما أُنشئ في مهمة
الكشوفات الشخصية — لا `ALTER` ولا foreign key (علاقة منطقية فقط نحو `CHART_ACC.ACC_NO`).

**الفرق الدلالي بين العمودين (موثَّق لتجنّب الخلط مستقبلاً):**
- `CASH_ACC_NO` = حساب الصندوق/النقد الافتراضي للمستخدم (حقل existed في الواجهة قبل هذه المهمة).
- `ACC_NO` = الحساب المالي في شجرة الحسابات (`CHART_ACC`) الذي تُحلّ منه الكشوفات الشخصية؛ أصبح
  الآن ظاهراً في واجهة إنشاء/تعديل المستخدم عبر منتقي الحسابات المالي.

**ما تغيّر هو طبقة القراءة في `UserAdminController` فقط** (لا القاعدة): `LIST_SQL` و`findUser`
و`shape()` باتت تُرجع `acc_no` ليُعبَّأ النموذج عند التعديل. **النموذج:** Claude · **الزمن:** 2026-10-24.

---

## 2026-10-25 — كشف حساب العميل: إلغاء `ENTRY_SUB.BALANCE_S` والاعتماد على `ACC_NO + GIVING` (Qoder)

**لا تغيير مخطّطي إطلاقاً** — لا `ALTER` ولا `CREATE` ولا `DROP` ولا DML. الجداول المستخدمة
(`CUST`, `ENTRY_SUB`, `ENTRY_MAIN`, `ENTRY_TYPE`) قائمة من نظام ERP القديم، والتعديل كله في **طبقة
القراءة وحساب الرصيد** داخل `CustomerController::statement()`.

### الفهم الجديد للعلاقة بين الحركة والعميل (الأهم)
- `ENTRY_SUB` يربط الحركة بالعميل عبر **عمودين معاً**: `ACC_NO` (الحساب المالي) و`GIVING`
  (رقم العميل). الاعتماد على `ACC_NO` وحده **خطأ بنيوي** لأن حسابات المراقبة مشتركة بين آلاف العملاء:
  `12310000` (حساب مراقبة العملاء) يشترك فيه **~4,470 إلى 5,593** عميلاً، وكذلك `41210001` (المبيعات)
  و`12110005` (الصندوق). لذلك أي قراءة على مستوى الحساب تُرجع حركات الجميع.
- `ENTRY_SUB.BALANCE_S` عمود **لقطة (snapshot) على مستوى الحساب لا العميل**: قيمته مشتركة بين كل
  عملاء الحساب، ولا تتبع الترتيب الزمني للسندات. تحقّق: للعميل 6694 **2,169 سطراً من أصل 4,340** كان
  `BALANCE_S` فيها مخالفاً لمجموع `ENTRY_MNT` التراكمي. ⇒ **قرار: لا يُقرأ هذا العمود في كشف حساب
  العميل مطلقاً**، والرصيد يُشتق رياضياً من `ENTRY_MNT`.
- `ENTRY_SUB.SUB_DETAILS` هو المصدر الأول للبيان، و`ENTRY_MAIN.DETAILS` بديل عند فراغه
  (**53,802 سطراً** في القاعدة لها `SUB_DETAILS` فارغ). العمودان `VARCHAR2(250)` فيأتيان مبطّنين
  بمسافات، فلا بد من `TRIM` قبل الحكم على الفراغ.
- الرصيد النهائي = الرصيد الافتتاحي + مجموع حركة الفترة، ولا يُقرأ من أي عمود مخزَّن.

### الاستعلام المعتمد (طبقة التطبيق، لا أمر يدوي)
```sql
SELECT es.ENTRY_NO,
       SUBSTR(TO_CHAR(es.ENTRY_NO), 1, 1) || SUBSTR(TO_CHAR(es.ENTRY_NO), 7, 4) AS SUB_ENTRY_NO,
       TO_CHAR(em.ENTRY_DATE, 'DD/MM/YYYY') AS ENTRY_DATE,
       TO_CHAR(em.ENTRY_DATE, 'YYYY-MM-DD') AS RAW_DATE,
       et.ENTRY_TYPE_NAME,
       NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS,   -- البيان: الفرعي ثم الرئيسي
       es.ENTRY_MNT, c.CUST_NAME, c.CUST_NO, c.ACC_NO,
       es.ACC_NO AS ENTRY_SUB_ACC_NO
  FROM ACCOUNTS.CUST c
  JOIN ACCOUNTS.ENTRY_SUB  es ON es.ACC_NO  = c.ACC_NO
                             AND es.GIVING  = c.CUST_NO   -- القيد المزدوج: الحساب + العميل
  JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
  JOIN ACCOUNTS.ENTRY_TYPE et ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO
 WHERE c.CUST_NO = :custNo
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;
-- تصحيح (2026-10-25 21:00): عمود النوع في ENTRY_TYPE هو ENTRY_TYPE_NO نفسه الموجود في
-- ENTRY_MAIN؛ الصيغة ETRY_TYPE_NO (بلا N) كانت مأخوذة من نسخة قاعدة أخرى خلف خادم MCP
-- وتُفشل الاستعلام بـ ORA-00904 على قاعدة التطبيق. أعمدة ENTRY_TYPE الفعلية:
-- ENTRY_TYPE_NO · ENTRY_TYPE_NAME · SOURCE_ID · SOURCE_NAME.
```

### التحقق الرقمي (عبر اتصال Laravel لا عبر MCP)
- **6694:** 3,834 سطراً · افتتاحي 0 · مدين 76,414,928 · دائن 66,037,928 · نهائي 10,377,000 ⇒ متوازن.
- **21026 (على حساب المراقبة 12310000):** 19 سطراً فقط = حركاته هو ⇒ تسريب «رصيد كل العملاء» مغلق.
- **6694 لفترة 2024-05-01..2024-05-31:** افتتاحي 247,000 · مدين 12,591,725 · نهائي 12,838,725 ·
  رصيد أول سطر 259,000 — مطابقة للحساب المستقل.
- **قيد بيئي:** MCP أوراكل ⇒ `192.168.0.9:1521/orcl` أما `.env` ⇒ `127.0.0.1:1521/orcl`، والفرق
  443,959 مقابل 422,408 سطراً في `ENTRY_SUB`، فكل الأرقام أعلاه من قاعدة التطبيق.

**المتبقي بنفس النمط القديم (خارج النطاق):** `AccountController::getAccountStatement`,
`MyStatementController`, و`WorkerController::statementEmployee/Cutter/Tailor` تقرأ `BALANCE_S` بعد.
**النموذج:** Qoder · **الزمن:** 2026-10-25 18:03 · لا DDL/DML ولا commit.

---

## [2026-10-25 20:54] - أثر إصلاح الكشوفات الأربعة على القاعدة (قراءة فقط) — Qoder

**لا تغيير في المخطّط:** لا DDL ولا DML. العمل كله في طبقة الاستعلام داخل Laravel، والجداول
`ENTRY_MAIN` / `ENTRY_SUB` / `ENTRY_TYPE` تُقرأ فقط.

### ما تغيّر في طريقة القراءة
- **البيان:** `NVL(TRIM(ENTRY_SUB.SUB_DETAILS), ENTRY_MAIN.DETAILS)` — الأولوية للتفصيل الفرعي،
  وبيان القيد الرئيسي بديل فقط عند الفراغ (NULL أو مسافات). `SUB_DETAILS` نوعه `VARCHAR2` فيأتي
  مبطّناً، فالـ `TRIM` شرط قبل الحكم بالفراغ.
- **`ENTRY_SUB.BALANCE_S` لم يُعد يُقرأ في أي كشف** (لا العميل ولا الحساب ولا الشخصي ولا العاملين)،
  لأنه لقطة على مستوى الحساب كاملاً لا تتبع الترتيب الزمني؛ الرصيد الجاري والنهائي يُشتقّان من
  `ENTRY_MNT` مرتباً بـ `(ENTRY_DATE, ENTRY_NO, SEQ)`.
- **خصوصية كل كشف:** العميل يحتاج `ACC_NO + GIVING = CUST_NO` (حساب المراقبة 12310000 مشترك بين
  آلاف العملاء)، أما كشف الحساب/الشخصي/العاملين فيكفيه `ACC_NO` لأن الحساب يخص طرفاً واحداً.

### أرقام البيئة التي بُني عليها التحقق (قاعدة `.env` = 127.0.0.1:1521/orcl)
| القياس | القيمة |
|---|---|
| `ENTRY_SUB` (سطور) | 422,408 |
| `ENTRY_MAIN` (قيود) | 150,127 |
| `CHART_ACC` (حسابات) | 20,954 |
| `APP_USERS` | 2 |
| `TAILOR_EMPLOYEES` | 102 |
| أكبر حسابات `ENTRY_SUB` | 41210001 = 65,199 · 12110001 = 47,740 · 12310000 = 17,968 |

### الحساب المرجعي المستخدم في التحقق
- **حساب 37110001:** 368 سطراً، منها **340 بلا `SUB_DETAILS`** (أي 92% من البيان يأتي من
  `ENTRY_MAIN.DETAILS`) — وهو أفضل عيّنة لإثبات أن الـ fallback يعمل لا أن الاستعلام يعيد فراغاً.
  مجموع `ENTRY_MNT` = **4,404,400** وهو مطابق تماماً لـ `summary.final_balance` و
  `opening_balance + total_debit - total_credit`، وكل رصيد سطر يطابق التراكم الزمني.
- **موظف 50 ⇒ حساب 12910127:** 207 سطراً، 67 منها بالـ fallback، مجموع الحركات 4,131,373 =
  `final_balance`، ولا مفتاح `balance_s` في أي سطر من الرد.

### تصحيح مرجعي مهم: عمود نوع القيد
```sql
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'ENTRY_TYPE' ORDER BY COLUMN_ID;
-- ENTRY_TYPE_NO · ENTRY_TYPE_NAME · SOURCE_ID · SOURCE_NAME
```
الصيغة `et.ETRY_TYPE_NO` (بلا N) التي وردت في توثيق سابق **خطأ على قاعدة التطبيق** وتُفشل الاستعلام:
`ORA-00904: "ET"."ETRY_TYPE_NO": invalid identifier` (لا يوجد هذا العمود في `ENTRY_TYPE`).
الصحيح `et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO` وقد طُبِّق فعلياً في كل الاستعلامات.

**النموذج:** Qoder · **الزمن:** 2026-10-25 20:54 · **قراءة فقط: 0 DDL · 0 DML · لا commit**.

---

## [2026-10-25 22:13] تذكّر آخر اسم مستخدم — لا تغيير على قاعدة البيانات · Qoder Agent

ميزة تعبئة اسم المستخدم الأخير في شاشة الدخول **محلية بالكامل على جهاز المستخدم**: تُحفظ في
`flutter_secure_storage` على الهاتف تحت المفتاح `ky_last_username`، ولا تُقرأ ولا تُكتب في أوراكل.

- **جداول:** لا جدول جديد، ولا عمود جديد. `APP_USERS` تبقى كما هي (`USER_NAME_EN` / `USER_NAME_AR` هما
  ما يطابقه استعلام الدخول أصلاً، ولا حاجة لعمود «آخر دخول»).
- **SQL المُنفَّذ:** لا شيء — `0 SELECT · 0 DDL · 0 DML`. لم يُفتح اتصال أوراكل في هذه المهمة.
- **السجل التدقيقي:** `APP_USER_ACTIVITY` لا يُكتب فيه شيء إضافي؛ أحداث `login`/`login_failed` كما كانت.
- **`db_commends.md`:** لم يُضف سطر (لا أمر SQL نُفِّذ).
- **الأثر على الخادم:** لا شيء — `kyApp_API` لم يُعدَّل، ولا endpoint جديد.

**النموذج:** Qoder · **الزمن:** 2026-10-25 22:13 · **قراءة/كتابة: 0 · لا commit**.

---

## [2026-10-25 22:57] تقادم `CHART_ACC.BALANCE` — القراءة من الحركات لا من العمود المخزّن · Qoder Agent

هذه المهمة **لم تُنشئ جدولاً ولا عموداً ولا فهرساً**؛ غيّرت **طريقة قراءة** رصيد الحساب المالي فقط.
السبب: قياس على القاعدة الحقيقية أثبت أن `CHART_ACC.BALANCE` **لقطة تاريخية متقادمة** لا تتبع الحركات.

### القياس المرجعي (قراءة فقط)

| المؤشر | القيمة |
|---|---|
| حسابات في `CHART_ACC` | 20,954 |
| مخزّنها غير صفر | 19,198 |
| **تخالف الحركات** | **19,126** |
| **لها حركات ومخزّنها = 0** | **1,162** |
| تطابق تام | 1 (36110007 — مصادفة) |

أمثلة موثّقة:

| الحساب | `CHART_ACC.BALANCE` المخزّن | صافي `SUM(ENTRY_MNT)` |
|---|---|---|
| 41210001 | −1,493,000,510 | **−1,801,753,216.78** |
| 33110003 | 1,944,519,285.84 | **6,541,659.48** |

### القاعدة المعتمدة

- **رصيد الحساب النهائي** = `SUM(ENTRY_SUB.ENTRY_MNT)` لكل سطور الحساب، بلا أي فلتر تاريخ، و`ENTRY_MNT > 0`
  مدين و`ENTRY_MNT < 0` دائن. لا يُقرأ `CHART_ACC.BALANCE` ولا `ENTRY_SUB.BALANCE_S` في أي شاشة بعد اليوم.
- **رصيد الفترة** = نفس المجموع مقيّداً بـ `ENTRY_MAIN.ENTRY_DATE` بين التاريخين، ويُحسب في **نفس المسح**
  عبر `SUM(CASE WHEN <period> …)` لا باستعلام ثانٍ ولا بشرط في `JOIN` (فلا تختفي الحسابات الساكنة).
- المجموعة `GROUP_ID` تربط `ACC_SUB_GROUP.GROUP_ID` بـ `CHART_ACC.GROUP_ID`، والحساب الجزئي هو أول 3 أرقام
  من `ACC_NO` (`SUBSTR(TO_CHAR(ACC_NO),1,3) = TO_CHAR(ACC_PART)`) — لم يتغيّر شيء في بنية الشجرة.

### الاستعلامات المعتمدة الآن (`AccountController`)

```sql
-- getGroupStatement(): مرور واحد ⇒ مدين/دائن الفترة + رصيد الفترة + الرصيد النهائي
SELECT c.ACC_NO, c.ACC_NAME,
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     AND es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_DEBIT,
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     AND es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END), 0) AS LOCAL_CREDIT,
       /* FOREIGN_DEBIT, FOREIGN_CREDIT بنفس القاعدة على cp.CUR_NO <> 1 */
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_NET,
       NVL(SUM(CASE WHEN ({$periodCond}) AND cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS FOREIGN_NET,
       NVL(SUM(CASE WHEN (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_NET_ALL,      -- بلا تاريخ = النهائي
       NVL(SUM(CASE WHEN cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS FOREIGN_NET_ALL      -- بلا تاريخ = النهائي
  FROM CHART_ACC c
  LEFT JOIN (ENTRY_SUB es INNER JOIN ENTRY_MAIN em ON es.ENTRY_NO = em.ENTRY_NO) ON es.ACC_NO = c.ACC_NO
  LEFT JOIN CUR_PRICE cp ON cp.SEQ = es.SEQ_PRICE
  LEFT JOIN CUR_CODE  cc ON cc.CUR_NO = cp.CUR_NO
 WHERE {$scopeWhere}                       -- GROUP_ID / ACC_PART / ACC_SUB / ACC_NO
 GROUP BY c.ACC_NO, c.ACC_NAME             -- بلا c.BALANCE
 ORDER BY c.ACC_NO;

-- getChartAccounts(): الرصيد المعروض بجانب أي حساب مالي (كل قوائم الاختيار)
--   SELECT ... FROM CHART_ACC   (بلا عمود BALANCE)
--   ثم في PHP: نطاقات IN على ENTRY_SUB لكل ACC_NO ⇒ net = SUM(ENTRY_MNT)

-- getAccountStatement() / MyStatementController::financialStatement():
--   SELECT ACC_NO, ACC_NAME, GROUP_ID FROM CHART_ACC WHERE ACC_NO = :no   (بلا BALANCE)
--   و account.balance = تراكم ENTRY_MNT لكل سطور الحساب قبل أي فلتر تاريخ.
```

### التحقق الرقمي على القاعدة الحقيقية

ملف مؤقت `verify_group_statement.php` بُني على إقلاع Laravel (نفس اتصال `.env`) أُنشئ ونُفِّذ ثم **حُذف**:

- **112 فحصاً / 0 فشل.**
- مجموعة `GROUP_ID = 7` = 26 حساباً: `balance` لكل سطر = مجموع حركاته الكلي، و`period_balance` = مجموع
  نافذة 2025، والمجاميع = مجموع السطور، والرصيد **ثابت** قبل الفلترة وبعدها، و`period_balance == balance`
  عند غياب الفلتر.
- الحساب 41210001: `balance` = −1,801,753,216.78 = `SUM(ENTRY_MNT)` ≠ المخزّن −1,493,000,510، وهو الرقم
  نفسه في `GET /accounts/chart` وفي `account.balance` بكشف الحساب.
- التراكم السنوي يثبت أن المخزّن لقطة قديمة: 2023 = −348,326,003 · 2024 = −756,119,835 ·
  2025 = −1,311,157,100.70 · 2026 = −1,801,753,216.78 — ولا يوافق أيَّها الرقم −1,493,000,510.

**النموذج:** Qoder · **الزمن:** 2026-10-25 22:57 · **قراءة فقط: 0 DDL · 0 DML · لا commit**.

---

## [2026-10-26 00:48] — ترقيم ميزان المجموعة: قياس حجم النطاقات + قوالب استعلام الصفحات — Qoder Agent

**لا تغيير على المخطط:** لا جدول ولا عمود ولا فهرس أُضيف. العمل كله في **شكل الاستعلام** وفي **حجم ما يُنقل**
من `ACCOUNTS` إلى التطبيق. القاعدة تبقى ملك نظام آخر ولا تُهاجَر.

### القياس الذي بنى القرار

عُدّت حسابات `CHART_ACC` بحسب أوّل ثلاثة أرقام من `ACC_NO` لكل حساب فرعي (`ACC_SUB`)، على القاعدة الحقيقية:

| الحساب الفرعي | الحساب الجزئي | عدد الحسابات |
|---|---|---|
| `ACC_SUB = 11` | — | **23** |
| `ACC_SUB = 12` | 121 | 10 |
| | 122 | 15 |
| | **123** | **20,469** |
| | 124 | 5 |
| | 127 | 48 |
| | 128 | 8 |
| | 129 | 219 |
| | **مجموع 12** | **20,774** |
| **الإجمالي العام** | | **20,954** |

الاستنتاج: المشكلة ليست في «باقي الحسابات» بل في نطاق واحد (الحساب الجزئي 123 = **98.6%** من كل الشجرة).
أي حل لا يُرقّم هذا النطاق بالذات لن ينجح.

### قالب الترقيم المستخدم (Oracle 11g)

`OFFSET … FETCH NEXT` غير مدعوم قبل 12c، فاستُخدم التفاف `ROWNUM` المزدوج حول الاستعلام المجمّع نفسه:

```sql
SELECT * FROM (
    SELECT a.*, ROWNUM AS RN
      FROM ( *الاستعلام المجمّع كما هو* ) a
     WHERE ROWNUM <= :max_row      -- offset + limit
) WHERE RN > :offset;             -- offset
```

الملاحظات المهمة:
- `ROWNUM` يُمنح **قبل** `ORDER BY` في الطبقة الداخلية، ولذلك وُضع `ORDER BY ACC_NO` **داخل** الاستعلام
  المجمّع ليكون الترتيب ثابتاً بين الصفحات.
- `:max_row` و`:offset` رابطان (bind) لا دمج نصّي — لا حقن SQL.
- عند `limit = 0` (التصدير الكامل) لا تُضاف أي طبقة: يُنفَّذ الاستعلام المجمّع كما هو.

### إجماليات النطاق في استعلام واحد

```sql
SELECT COUNT(*)                                AS TOTAL_ROWS,
       NVL(SUM(LOCAL_DEBIT), 0)                AS LOCAL_DEBIT,
       NVL(SUM(LOCAL_CREDIT), 0)               AS LOCAL_CREDIT,
       NVL(SUM(FOREIGN_DEBIT), 0)              AS FOREIGN_DEBIT,
       NVL(SUM(FOREIGN_CREDIT), 0)             AS FOREIGN_CREDIT,
       NVL(SUM(LOCAL_NET_ALL + FOREIGN_NET_ALL), 0) AS FINAL_BALANCE,
       NVL(SUM(LOCAL_NET + FOREIGN_NET), 0)         AS PERIOD_BALANCE
  FROM ( *نفس الاستعلام المجمّع* ) t;
```

الفائدة المزدوجة: سطر الإجمالي يبقى صحيحاً منذ الصفحة الأولى، و`COUNT(*)` يعطي **عدد صفوف النطاق كاملاً**
قبل تنزيله — وهو الرقم الذي يُقرَّر به «النطاق واسع جداً» على الشاشة.

### قياس الأداء على القاعدة الحقيقية (`acc_no=1&acc_sub=12` = 20,774 حساباً)

| العملية | الزمن | الصفوف | ملاحظة |
|---|---|---|---|
| صفحة 1 (`limit=500`, مع الإجماليات) | 2.58 ث | 500 | استعلامان: صفحة + إجماليات |
| صفحة 2 (`limit=500`, بلا إجماليات) | — | 500 | يبدأ بعد آخر `acc_no` في الأولى، وإجمالياتها صفر |
| الصفحة 42 (الأخيرة) | — | ≤ 500 | `has_more = false` |
| تصدير كامل (`limit=0`) | 3.95 ث | **20,774** | `SUM(rows) == SUM(ENTRY_MNT)` |

وزمن القسم الواحد (2.5–4 ثوانٍ) هو تكلفة الاستعلام التجميعي على `ENTRY_SUB`، ولذلك صار حجم القسم في
الواجهة **1000 صف** بدل 500: نصف عدد الطلبات بنفس التكلفة لكل طلب.

### خلاصة التحقق (13/13)

`page1` (500 · `total=20,774` · `total_pages=42` · `has_more=true`) · `page2` (ترتيب تصاعدي مستمر ·
إجماليات مصفّرة) · الصفحة الأخيرة (`has_more=false`) · `limit=0` يرجّع 20,774 صفاً · `totals.balance` =
مجموع أرصدة الصفوف = `SUM(ENTRY_MNT)` · مجموعة 7 (26 حساباً) ما زالت تعمل بلا تغيير.

**النموذج:** Qoder · **الزمن:** 2026-10-26 00:48 · **قراءة فقط: 0 DDL · 0 DML · لا commit**.

---

## 2026-10-26 03:11 — الكشوفات تقرأ الفترة كاملة (بلا سلّم `limit` افتراضي)

**لا تغيير في البنية:** لا `CREATE`/`ALTER`/`DROP`، ولا تعديل على `APP_*` أو جداول الحسابات. القاعدة للقراءة فقط في هذه المهمة.

**ما تغيّر في طبقة الاستعلام:**

| الاستعلام | قبل | بعد |
|---|---|---|
| `ENTRY_MAIN × ENTRY_SUB × ENTRY_TYPE` (كشف الحساب) | يجلب الدفتر كاملاً ثم `array_slice` على أول 50 صفاً افتراضياً | يجلب الدفتر كاملاً **ويعيد كل صفوف الفترة**، والقصّ فقط عند `limit` موجب صريح (سقفه 2000) |
| كشف الحساب الشخصي (`my-statement/financial`) | نفس السقف الافتراضي 50 | نفس العقد الجديد |
| `CHART_ACC` (كشف الحساب المفصل، بلا `id`) | غلاف `ROWNUM` مزدوج دائم | الغلاف يُبنى فقط عند `limit > 0`؛ بدونه استعلام مسطّح مرتّب بـ `ACC_NO` |
| كشف جاري العاملين (`workers/*/*/statement`) | كان بلا سقف أصلاً | كما هو — الاقتطاع كان في الواجهة (15 صفاً/صفحة) وقد أُزيل |
| كشف العمل (`workers/*/*/work-report`) | بلا سقف | كما هو — الواجهة صارت كسولة |

**اعتبارات الأداء:** الفلترة على الفترة تحدث في SQL (`ENTRY_DATE BETWEEN`)، لكن ترتيب الرصيد الجاري وتحويل الصفوف يتم في PHP؛
لذا زمن الاستجابة يتناسب مع **عدد حركات الفترة** لا مع مساحة الجدول. عند الفترات الضخمة جداً يُنصح بالبحث بحساب محدد أو بفترة أضيق.

**استعلامات تحقق نُفِّذت (قراءة فقط):**

```sql
-- الحساب الأكثر حركةً لاختبار الكشف عليه
SELECT ACC_NO FROM (
    SELECT ACC_NO FROM ACCOUNTS.ENTRY_SUB GROUP BY ACC_NO ORDER BY COUNT(*) DESC
) WHERE ROWNUM = 1;

-- هل يوجد مستخدم مرتبط بحساب مالي؟ (أجاب: لا يوجد ⇒ استُخدم ACC_NO في الذاكرة للاختبار)
SELECT USER_ID, ACC_NO, IS_ADMIN FROM ACCOUNTS.APP_USERS WHERE ACC_NO IS NOT NULL AND ROWNUM <= 5;
```

**نتيجة اختبارات القاعدة الحقيقية:** `StatementFullPeriodTest` = 3/3 ناجحة (17 تأكيداً) — `meta.returned == meta.total` على حساب حقيقي بفترة مفتوحة،
و`limit=25` يقصّ 25 صفاً فقط عند الطلب، والكشف الشخصي بنفس المساواة.

**النموذج:** Qoder · **الوقت:** 2026-10-26 03:11 · **قراءة فقط: 0 DDL · 0 DML · لا commit**.

---

## 2026-10-27 01:50 — جدول `APP_SUPPORT_TICKETS` ومفتاح `company_services` وأكواد الدعم

**ما تغيّر في البنية (DDL منفَّذ فعلياً على `ACCOUNTS`):**

| الكائن | النوع | الوصف |
|---|---|---|
| `APP_SUPPORT_TICKETS` | جدول (13 عموداً) | تذاكر الاستفسار: `TICKET_ID` · `USER_ID` (null = زائر) · `CONTACT_NAME/PHONE` · `MESSAGE` · `STATUS` · `ADMIN_REPLY/REPLIED_BY/REPLIED_ON` · `APP_VERSION` · `PLATFORM` · `CREATED_ON` · `UPDATED_ON` |
| `APP_SUP_PK` | قيد مفتاح أساسي | على `TICKET_ID` |
| `APP_SUP_STATUS_CK` | قيد تحقق | `STATUS IN ('new','answered','closed')` — مطابق لحالات الشاشة والفلترة |
| `APP_SUP_STATUS_IX` | فهرس | `(STATUS, CREATED_ON)` — يخدم شرائح الحالة الأربع وترتيب الأحدث |
| `APP_SUP_USER_IX` | فهرس | `(USER_ID, CREATED_ON)` — يخدم ربط التذكرة بصاحبها |
| `SEQ_APP_SUPPORT_TICKETS` | متسلسلة | `START 1 · INCREMENT 1 · NOCACHE · NOCYCLE` |
| `TRG_APP_SUPPORT_TICKETS` | مشغّل `BEFORE INSERT` | يُسند `TICKET_ID` من المتسلسلة عند غيابه |

**ملف التنفيذ:** `kyApp_API/database/oracle/08_app_support_tickets.sql` (DDL + استعلامات تحقق + تعليقات `DROP` للتراجع).

**قرارات تصميم على مستوى القاعدة:**

1. **لا مفتاح أجنبي** على `USER_ID` — جداول `APP_*` الإرثية تُدار خارج سيطرتنا، وحذف مستخدم لا يجوز أن يُفشل إدراج تذكرة.
2. **اسم المتسلسلة بلا مخطط داخل PL/SQL** (`SEQ_APP_SUPPORT_TICKETS.NEXTVAL`) لأن وجود VIEW باسم `ACCOUNTS` يجعل
   `ACCOUNTS.SEQ_...` يفشل بـ `PLS-00302` — نفس درس `01_ibac_schema.sql`.
3. **لا حذف للتذاكر**: دورة الحياة `new ← answered ← closed`؛ الإغلاق حالة لا حذف صف، فالسجل يبقى للمراجعة.
4. **`MESSAGE`/`ADMIN_REPLY` = 1000 محرف**، والخادم والعميل يفرضان 10..1000 و≤1000 على التوالي.

**مفتاح التهيئة (بلا DDL):**

- `company_services` في `ACCOUNTS.APP_SETTINGS`: `VALUE_TYPE='string'` · `SORT_ORDER=145` · `NAME_AR='نبذة عن خدمات الشركة'` · قيمة ابتدائية فارغة.
- القيمة الفارغة مقصودة: القسم في العميل يخفي سطر «خدماتنا» حتى تُكتب النبذة، بدل نص بديل مضلّل.
- سقف التحرير 400 محرف في الخادم (`AppConfigController::textLimit`) والعميل (`maxLength`) لأن عمود `SETTING_VALUE` = 500 بايت.

**أكواد الصلاحيات (بلا DDL — بذر idempotent):**

- قسم `support` قبل `my_statement` بفعلين: `support.view` («عرض استفسارات الدعم») و`support.update` («الرد على الاستفسار وإغلاقه»).
- **بلا `support.create`**: الإرسال خدمة ذاتية من العميل تعمل قبل الدخول، فتعريفه صلاحية كان سيحجب النموذج عن الزائر.
- أُدرجت في `APP_PERMISSIONS` بإعادة تشغيل `02_ibac_seed.php` ⇒ `inserted=3 · updated=138 · total=141`.

**تحقق نُفِّذ فعلياً:**

```sql
SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';  -- 13
SELECT COUNT(*) FROM USER_INDEXES     WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';  -- 3
SELECT STATUS  FROM USER_TRIGGERS     WHERE TRIGGER_NAME = 'TRG_APP_SUPPORT_TICKETS'; -- ENABLED
-- إدراج اختباري ⇒ TICKET_ID = 1 تلقائياً، ثم حُذف (لا صفوف اختبارية باقية)
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;                                  -- 141
SELECT PERMISSION_CODE FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE LIKE 'support.%';  -- 3 أكواد
```

**الترميز:** كل كتابة عربية عبر `ArabicEncoding::toOracleSearchChars()` وكل قراءة عبر `fixMojibake()`؛
اختبار Pest على القاعدة الحقيقية يُثبت أن نصّاً عربياً يُكتب ويُقرأ سليماً (`fixMojibake(stored) === input`).

**النموذج:** Qoder · **الوقت:** 2026-10-27 01:50 · **DDL: 1 جدول + 2 فهرسان + متسلسلة + مشغّل · DML: إدراج اختباري واحد حُذف · لا commit**.

---

## 2026-10-27 03:10 — تعبئة `company_services` في `APP_SETTINGS` (قيمة واحدة، بلا DDL)

**السبب:** قسم «معلومات الشركة» في العميل أصبح يعرض نبذة الخدمات من `company_services`، والحقل كان
**فارغاً** منذ إنشائه (`VALUE_TYPE='string'`, `SORT_ORDER=145`) — فكانت اللوحة تُخفى ولا يظهر شيء.

**التغيير (DML فقط):**

| المفتاح | قبل | بعد |
|---|---|---|
| `company_services` | `''` (0 محرف) | نبذة 140 محرفاً عن خدمات الخياطة والتفصيل |

**النص المخزَّن:**

> نقدّم خدمات الخياطة والتفصيل الرجالي: أخذ المقاسات، وقصّ وتفصيل الثياب والبدلات، وتنفيذ كروت
> التفصيل حسب الطلب، مع متابعة الطلب حتى التسليم.

**كيف كُتبت:** عبر `SettingsStore::set('company_services', …)` — أي بنفس مسار شاشة إعدادات التطبيق:
`ArabicEncoding::toOracleSearchChars()` ثم `UPDATE … SET UPDATED_ON = SYSDATE`، و`UPDATED_BY = NULL`
لأن الكتابة إدارية لا بشرية. لم يُستخدم SQL عربي مباشر.

**تحقق القراءة العكسية (نُفِّذ فعلياً):**

```sql
SELECT SETTING_KEY, LENGTH(SETTING_VALUE), SORT_ORDER
  FROM ACCOUNTS.APP_SETTINGS WHERE SETTING_KEY = 'company_services';
-- company_services · 140 · 145
-- وأثناء التشغيل: BEFORE_LEN=0 · AFTER_LEN=140 · ROUND_TRIP_OK=1 · PAYLOAD_LEN=140
```

**حدود لم تتغيّر:** العمود `SETTING_VALUE VARCHAR2(500)` · سقف التحرير في الخادم والعميل 400 محرف ·
`company_website` بقي فارغاً (لا رابط مسجَّل، والاختراع ممنوع) · `company_name` و`company_address`
و`company_phone` بقيمها كما هي · لا تغيير في `APP_PERMISSIONS` ولا في أي جدول آخر.

**للتراجع:** `UPDATE ACCOUNTS.APP_SETTINGS SET SETTING_VALUE = NULL WHERE SETTING_KEY = 'company_services';`
— يعيد الحقل فارغاً وتختفي لوحة الخدمات تلقائياً (لم تُنفَّذ).

**النموذج:** Qoder · **الوقت:** 2026-10-27 03:10 · **DDL: 0** · **DML: UPDATE واحد (صف واحد)** · **لا commit**.


---

## 2026-10-28 08:49 — بنية مصدر بيانات التفصيل `ACCOUNTS.CUTTING_SALES_BILL_VIEW`

### التسلسل الهرمي (مقيس حياً)

`SALES_BILL` (الفاتورة) ← `SALES_DETAILES_SHAPES` (صف لكل **موديل**، مفتاحه `SEQ_NO`) ← `MULTI_CLOTHS`
(حتى 55 **قطعة** للموديل، مفتاحها `SEQ_NO1`).

- **الموديل** يحمل: المستفيد `BENEFICIARY_NAME`، النوع، الشكل، المقاسات `L1..L12`، والمواصفات
  (`NECK_TYPE` … `HEGAZI_TYPE`) والأكواد الرقمية (`NECK_SHAPE_NO` وأخواتها) و`NOTES2`.
- **القطعة** تحمل: القماش (`CLOTH_NAME`, `CLOTH_TYPE`, `COLOR_TEXT`)، الهنش/اليارد، مصدر القماش،
  القصّاص (`CUTTER_NO1`, `CUTTER_NAME1`)، الخيّاط (`TAILOR_NO1`, `TAILOR_NAME1`)، وأعلام الإنجاز
  `CUTTING_DONE` / `TAILOR_DONE` / `HANDING_DONE` مع تواريخها، والحالة الحالية `ORDSDID`.
- **صف واحد لكل قطعة** في الـ VIEW.

### أرقام مقيسة (2026-10-28)

| القياس | القيمة |
|---|---|
| صفوف الـ VIEW | **45,199** |
| فواتير مميزة `(BILL_NO, YEAR)` في الـ VIEW | **13,667** |
| صفوف `APP_PERMISSIONS` بعد بذر التفصيل | **144** |
| صفوف `GENERAL_LABELS_CODING` | **1** |
| صفوف `ORDSTATE` | **16** (`ORDSID` = 0..15) |

### حدود الـ VIEW (مقبولة بقرار المستخدم وتُوثَّق في الواجهة)

الـ VIEW يربط `NVL(CUTTER_NO1,0) = CUTTER.CUTTER_NO` و`NVL(TAILOR_NO1,0) = TAILOR.TAILOR_NO` **بربط داخلي**،
فيُسقط أي موديل بلا قصّاص أو خيّاط. النتيجة: تغطية ~20% من فواتير التفصيل (13,667 من أصل 66,827).
تُعرض ملاحظة في رأس القائمة، وحالة فراغ تفسيرية عند فتح فاتورة خارج النطاق — لا إخفاء صامت.

### تسميات المقاسات `GENERAL_LABELS_CODING`

صف واحد: `L1` الطول · `L2` الكتف · `L3` طول اليد · `L4` الرقبة · `L5` العرض · `L6` تنزيلة اليد ·
`L7` وسط اليد · `L8` الخطوة · `L9` طول الجبزور · `L10` طول الكبك، و`L11`/`L12` بلا تسمية
(تُعرض بأسمائها الرمزية كما هي).

### الحالات `ORDSTATE` وقراءتان تكميليتان لا مفرّ منهما

- `ORDSTATE` قاموس الحالات (16 صفاً) يُغذّي خط السير في شاشة المتابعة.
- الـ VIEW يحمل الحالة **الحالية** فقط بلا تاريخ انتقالات ⇒ قراءة تكميلية من `CUTING_TRANSD` + `ORDSTATE`
  (+ `DEPTS`) لسجل الحركة، مربوطة بأرقام `SEQ_NO1` التي يحملها العميل أصلاً.
- خانات الدفع والطلب غير موجودة في الـ VIEW ⇒ قراءة تكميلية واحدة من `SALES_BILL` بصف
  `(BILL_NO, YEAR)` لـ: `AMOUNT_PAID, OTHERS_PAYMENTS, IS_GIVING, GIVING_DATE, PAYMENT_METHOD, VOUCHER_NO,
  TEL_NO2, ADDRESS, REF_NO, URGENT, CUR_NO, CUR_PRICE, BRANCH_NO, CREATED_BY_NAME, LAST_UPDATED_BY_NAME, DETAILES`.

### مزالق الترميز والقيم

- العربية مخزّنة CP1256: كل حقل عربي يمرّ عبر `ArabicEncoding::cleanData` في الخادم و`ArabicEncodingUtils.fix()`
  في العميل.
- `TAILOR_NAME1` قد تحمل القيمة الحرفية «لا يوجد» ⇒ تُطبَّع إلى `null` على الخادم وتُعرض «غير مسند».
- `NET - AMOUNT_PAID` قد يكون سالباً (دفعة مقدمة) ⇒ يُعرض «رصيد مقدم» لا «متبقٍّ».
- الأرقام تعود نصوصاً والمفاتيح snake_case صغيرة والتواريخ قد تحمل `Z` ⇒ التطبيع كله في طبقة النموذج.

**النموذج:** Qoder · **الوقت:** 2026-10-28 08:49 · **لا DDL** · **DML:** بذر 3 صفوف صلاحيات فقط.

---

## 2026-10-29 04:34 — مقاسات العملاء: حقائق مقيسة على `CUTTING_SALES_BILL_VIEW` + 3 صفوف صلاحيات

### الكتابة في القاعدة (كل ما نُفِّذ)

`DDL`: **لا شيء** على أي جدول إرث. `DML`: البذر idempotent المعتاد
`php artisan tinker database/oracle/02_ibac_seed.php` ⇒
`PERMISSIONS catalog=147 inserted=3 updated=144 total=147` و`SETTINGS seeded=23 updated=23`.

الصفوف الجديدة في `ACCOUNTS.APP_PERMISSIONS` (وحدة `customers` الموجودة، بلا وحدة جديدة):

| `PERMISSION_ID` | `PERMISSION_CODE` | `NAME_AR` | `SORT_ORDER` | `IS_CORE` |
|---|---|---|---|---|
| 186 | `customers.measurements_view` | عرض مقاسات العملاء | 409 | 0 |
| 187 | `customers.measurements_print` | طباعة مقاسات العملاء | 410 | 0 |
| 188 | `customers.measurements_export` | تصدير مقاسات العملاء | 411 | 0 |

الكتالوج 144 ⇒ 147؛ و`SORT_ORDER` مشتق آلياً `moduleIndex*100 + actionIndex` (`customers` رابع
وحدة ⇒ الأساس 400)، فبلا تعارض مع `edit_limit` عند 408. لا منح يدوية: المدير `IS_ADMIN = 1`
يتجاوز جدول المنح، ومنح الأفراد تُدار من شاشة الإدارة نفسها لأن الكتالوج هو مصدرها.

### حقائق مقيسة على القاعدة الحيّة (قراءة فقط، 2026-10-29)

| القياس | القيمة |
|---|---|
| صفوف الواجهة | 45,313 |
| عملاء مميّزون (`CUST_NO`) | 9,007 |
| فواتير مميّزة (`BILL_NO, YEAR`) | 13,688 |
| موديلات مميّزة (`BILL_NO, YEAR, SEQ_NO`) | 25,222 |
| أسماء مستفيدين مميّزة | 7,735 |
| أقصى فواتير لعميل واحد | 878 |
| أقصى موديلات لعميل واحد | 2,169 |
| أقصى قطع في موديل واحد | 55 |
| `MAX(BILL_NO)` / `MIN(BILL_NO)` | 28,989 / 6 |
| `MAX(YEAR)` / `MIN(YEAR)` | 2026 / 2023 |
| **`MAX(SEQ_NO)`** | **85,120** |
| `MAX(SEQ_NO1)` | 136,372 |
| صفوف بلا `TEL_NO1` | 4,313 |
| صفوف بلا `BENEFICIARY_NAME` | 18,846 |

### ما قرّره هذا القياس في الكود

1. **`CUST_NO` ⇒ `CUST_NAME` علاقة 1:1** (صفر عميل بأكثر من اسم): التجميع على رقم العميل آمن
   و`MAX(CUST_NAME)` ليس تسكيناً عشوائياً بل الاسم الوحيد.
2. **`(BILL_NO, YEAR, SEQ_NO)` ⇒ `BENEFICIARY_NAME` علاقة 1:1** (صفر تعارض): المستفيد صفة
   الموديل لا صفة القطعة، فيُقرأ من أول صف مجموعة الموديل.
3. **معامل التمايز:** `MAX(SEQ_NO) = 85,120` يمنع استخدام معامل 1,000 في عدّ الموديلات
   المميّز، وإلا تطابق موديلان داخل `COUNT(DISTINCT …)`؛ فيُستخدم `(BILL_NO*10000+YEAR)*1000000+SEQ_NO`
   (`SEQ_FACTOR = 1_000_000`) لأن `SEQ_NO1` يصل 136,372 فالسقف يحتاج ست خانات دائماً.
4. **`TEL_NO1` يغطي 90%** من الصفوف: الهاتف ليس دليلاً موثوقاً وحده، والبحث يبقى على ثلاثة أعمدة
   (اسم/هاتف/مستفيد) ولا يعتمد على الهاتف وحده.
5. **42% من الصفوف بلا مستفيد** (18,846/45,313): الواجهة تعرض «بلا مستفيد محدّد» بدل شرطة تُقرأ
   «لا بيانات»، والبحث بالمستفيد يظلّ عاملاً لأن الشرط داخل `MAX(CASE …)`.
6. **المواصفات النصية ليست في الواجهة:** `NECK_TYPE`, `TIPPER_TYPE`, `COM_CABAK_TYPE`,
   `POCKET_OR_WITHOUT`, `GABZOR_TYPE`, `BUTTON_TYPE`, `BUTTON_NO`, `MOBILE_POCKET`, `PEN_POCKET`,
   `HEGAZI_TYPE`, `NOTES2` وأكواد `SHAPE_*_NO` كلها من `ACCOUNTS.SALES_DETAILES_SHAPES` (ربط على
   `BILL_NO, YEAR, SEQ_NO`)، والعنوان والهاتف الثاني وبيانات الطلب من `ACCOUNTS.SALES_BILL`
      بصفّه الوحيد `(BILL_NO, YEAR)`، واسم الحالة من جدول `ORDSTATE` بعمود `ORDSID`. الاستثناءان
   موثّقان كما في متحكم كروت التفصيل، ولا يمسّ أيٌّ منهما الكتابة.
7. **لا خانات مالية في مسار المقاسات:** الاستعلامات لا تذكر `TOTAL/DISCOUNT/NET/SANF_PRICE`
      أصلاً، فلا مبلغ يصل إلى الواجهة — الحجب في SQL لا في العرض.

### تسميات المقاسات (`GENERAL_LABELS_CODING`)

L1 الطول · L2 الكتف · L3 طول اليد · L4 الرقبة · L5 العرض · L6 تنزيلة اليد · L7 وسط اليد ·
L8 الخصرة · L9 طول الجبزور · L10 طول الكبك · **L11 وL12 فارغتان**.

الواجهة تعرض عشرة مقاسات مسماة وتُظهر مفتاح `L11/L12` حرفياً عند غياب التسمية، ولا تخترع اسماً.

**النموذج:** Qoder · **الوقت:** 2026-10-29 04:34 · **لا DDL** · **DML:** 3 صفوف `APP_PERMISSIONS` (بذر) + صفوف `APP_USER_ACTIVITY` من مسارات التدقيق.

---

## 2026-10-29 06:47 — مقاسات العملاء (مراجعة): أعمدة إضافية في الاستعلام وتوضيح تسميات

**لا `DDL` ولا `DML` في هذه المراجعة** — التغيير في استعلامات القراءة فقط داخل
`CustomerMeasurementController::detailSql()`.

### أعمدة أُضيفت إلى قراءة الموديل الواحد

| العمود | الجدول/الواجهة | الاستعمال في الواجهة |
|---|---|---|
| `OHID` | `CUTTING_SALES_BILL_VIEW` | مفتاح سطر الطلب الأصلي (احتياطي للعرض) |
| `OHDID` | `CUTTING_SALES_BILL_VIEW` | **عمود «رقم الطلب»** الذي يطلبه العاملون في جدول الأقمشة |
| `SANF_PRICE` | `CUTTING_SALES_BILL_VIEW` | **عمود «السعر»** لكل قطعة (نفس ما يعرضه كرت التفصيل) |
| `CUTTER_NO1`, `TAILOR_NO1` | `CUTTING_SALES_BILL_VIEW` | مرسلان مع القطعة لربط المسؤول إن احتاج لاحقاً |

- اسم المفتاح في الـ JSON هو `ohdid` (بلا شرطة) مطابقةً لما يرسله `TailoringController`، لأن
  النموذج الواحد (`CuttingPieceItem`) يقرأ الاثنين معاً؛ اختلاف التسمية كان يجعل «رقم الطلب»
  فارغاً في شاشة المقاسات وموجوداً في كرت التفصيل.
- `CLOTH_TYPE` سُمّيت في الواجهة **«العرض»** لا «النوع»: قيمها الفعلية في القاعدة «عرضية / ضيقة»
  كما ظهر في عيّنة القراءة (`cloth_type: "عرضية"`)، فتسميتها «النوع» كانت تضلّل القارئ.
- `SANFPRICE` (بلا شرطة) وُظّفت احتياطاً في القراءة فقط؛ إجماليات الفاتورة
  (`TOTAL/DISCOUNT/NET/AMOUNT_PAID`) ما زالت **غير مذكورة** في أي استعلام من هذا المسار،
  والاختبار `… with no money` يحرس غيابها.

### ما لم يُحسم ويحتاج عودة الاتصال

- «جيب جانبي» و«جيب الصدر»: العمودان المثبتان النصيان هما `POCKET_OR_WITHOUT` (حالة الجيوب) و
  `MOBILE_POCKET` / `PEN_POCKET`، أما `SHAPE_POCKET_UP_NO` / `SHAPE_POCKET_DOWN_NO` فأكواد
  رقمية لأشكال الجيوب لا نصوص. عند عودة القاعدة تُراجع `ALL_TAB_COLUMNS` لجدول
  `SALES_DETAILES_SHAPES` للتأكد من وجود عمودين نصيين مستقلين للجيب الجانبي والصدر قبل إضافة أي
  تسمية جديدة؛ لا تسمية تُخترع بلا عمود يقابلها.

**النموذج:** Qoder · **الوقت:** 2026-10-29 06:47 · **لا DDL** · **لا DML** (قراءة فقط) · اتصال أوراكل المحلي منقطع (`ORA-12514`) منذ ~05:50 ولم تُنفَّذ استعلامات جديدة.

---

## 2026-10-31 02:12 — حسم أعمدة المواصفات والأقمشة بفحص حيّ عبر موصل `oracledb`

**لا DDL ولا DML** — كل ما يلي `SELECT` للقراءة فقط نفّذه موصل `oracledb` MCP (الاتصال المحلي
للتطبيق ما زال رافضاً `ORA-12514` على `localhost:1521/orclrd`، والموصل يذهب إلى البعيد).

### `ACCOUNTS.SALES_DETAILES_SHAPES` — 53 عموداً، وهذا ما يخصّ المواصفات

| العمود | النوع | معبأ من 84,971 | القرار في الواجهة |
|---|---|---|---|
| `BUTTON_TYPE` | VARCHAR2 | 84,971 | **نوع الأزرار** |
| `BUTTON_NO` | VARCHAR2 | — | **عدد الأزرار** |
| `BUTTONS_NUM` | NUMBER | 8 | مُهمَل (لا يكاد يُملأ) |
| `TIPPER_TYPE` | VARCHAR2 | غالب | **نوع الكم** |
| `NECK_TYPE` | VARCHAR2 | غالب | **نوع الرقبة** |
| `POCKET_OR_WITHOUT` | VARCHAR2 | **83,395** | **جيب جانبي** (القيم: جيوب / بدون / جيوب شمال / جيوب يمين) |
| `MOBILE_POCKET` | VARCHAR2 | 83,245 | **جيب الجوال** (القيم: عادي / عادي+…) |
| `PEN_POCKET` | VARCHAR2 | **0** | حُذف من الشاشة: لا يمتلئ أبداً |
| `GABZOR_TYPE` | VARCHAR2 | غالب | **نوع الجبزور** |
| `COM_CABAK_TYPE` | VARCHAR2 | غالب | **نوع الكباك** |
| `HEGAZI_TYPE` | VARCHAR2 | — | **نوع الحجازي** |
| `SHAPE_POCKET_UP_NO` | NUMBER | **12** | **جيب الصدر** عند وجوده فقط (لا عمود نصي له) |
| `SHAPE_POCKET_DOWN_NO` | NUMBER | 13 | غير معروض (كود شكل بلا قاموس) |
| `NOTES2` | VARCHAR2 | — | الملاحظة في صندوق مميّز |
| `RQUEST_NO`, `OHID`, `OHDID`, `PROD_NO`, `STYL_NO`, `SANF_DNO` | NUMBER | — | معرّفات داخلية |

**الحسم:** لا يوجد في المخطط عمودان نصيان باسم «جيب جانبي» و«جيب الصدر»؛ الجيب الجانبي هو
`POCKET_OR_WITHOUT` بدلالته الفعلية (شمال/يمين)، وجيب الصدر لا أثر نصي له فأقرب ما يُربط به
`SHAPE_POCKET_UP_NO` (12 صفاً فقط). لا تسمية تُخترع بلا عمود، والفارغ لا يُعرض.

### `ACCOUNTS.CUTTING_SALES_BILL_VIEW` — ما يخصّ جدول الأقمشة

- `OHDID` = **رقم الطلب** كما يطلبه المستخدم، وقيمته الحيّة تصل **11 رقماً**
  (مثال مقاس: `26211325025`) — لذلك أُعطي أعرض وزن نسبي في السطر حتى لا يُبتَر بالاقصاء.
- `CLOTH_TYPE` = **العرض** لا النوع: قيمه «عرضية» (37,077)، «عرض44» (5,234)، «عرض» (3,043)،
  فارغ في 42 صفاً فقط. تسمية العمود «النوع» كانت مضلّلة، وصححت إلى «العرض».
- `SANF_PRICE` = سعر القطعة (مثال حيّ: 2000) و`SANFPRICE` حقل آخر (6000 في المثال نفسه):
  المسار يعرض `SANF_PRICE` وحده مطابقةً لكرت التفصيل، ولا يمس إجماليات الفاتورة
  (`TOTAL/DISCOUNT/NET/AMOUNT_PAID`) إطلاقاً.
- `CUTTER_NAME` و`TAILOR_NAME1` **يختلفان من قطعة لأخرى داخل نفس الموديل** (في المثال:
  «أحمد عبد العزيز شرهان» و«مازن ميثاق الصبري» و«خالد محمد الصعواني» لنفس الموديل) — وهذا يبرر
  سطر «المسؤولون والمرحلة» المنفصل لكل قماش بدل دمجهم في رأس الموديل.
- `CONSUMED_CLOTH_QTY_HINSH` = هنش (42) و`CONSUMED_CLOTH_QTY_YARDS` = ياردة (1.17) ✓.

### تنفيذ استعلام التفصيل كما هو في الكود

فُحص `CustomerMeasurementController::detailSql()` حرفياً على المخطط الحيّ للمفتاح
`(BILL_NO=19405, YEAR=2026, SEQ_NO=82755)` فأعاد **55 صفاً** بلا خطأ: الأعمدة المضافة
(`OHID, OHDID, SANF_PRICE, SANFPRICE, CUTTER_NO1, TAILOR_NO1, FIXED_FLEXED, BATCH_NO_PRINT`)
كلها موجودة، وربط `SALES_DETAILES_SHAPES` بـ `(BILL_NO, YEAR, SEQ_NO)` و`STYLE`
بـ `SHAPE_STYLE_NO` لا يُضاعف الصفوف.

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:12 · **لا DDL** · **لا DML** (قراءة فقط عبر oracledb MCP) · اتصال التطبيق المحلي ما زال `ORA-12514`.


---

## 2026-10-31 06:12 — مفتاح سجل حركة الأقمشة: `OHDID` في الـ VIEW و`CUTING_TRANSD`

- `ACCOUNTS.CUTTING_SALES_BILL_VIEW` تحمل `OHDID` و`OHID` إلى جانب `SEQ_NO` و`SEQ_NO1`؛
  صف نموذجي: `bill_no=6, year=2026, seq_no=60373, seq_no1=92456, ohdid=262133`.
- `ACCOUNTS.CUTING_TRANSD` مفتاحها التشغيلي `OHDID`، وأعمدتها: `DDATE, ORDSID, DEPTID,
  DETAILE, QTY, PQTY, SQTY, POST, CANCEL, CREATED_BY_NAME, OHDID, SEQ_NO`.
- قياس: القطعة `ohdid=262133` لها **9** صفوف حركة، و`CREATED_BY_NAME` فيها `null` مع `DEPTID`
  (12/21/22) — لذلك «المنفذ» يُقرأ من اسم القسم ثم رقمه.
- الأثر: مسار الحركة يقبل `ohd_ids` ويرشّح `ct.OHDID IN (...)` بدل `ct.SEQ_NO`، والتفصيل
  يعيد `ohdid` مع كل قطعة ليكون مفتاح السجل في العميل.

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:12 · **لا DDL** · **لا DML** (قراءة فقط).

---

## 2026-11-01 — مخطط قسم المخازن: ثلاثة عشر تسلسلاً وبلا جدول واحد

**ملخص:** قسم المخازن لا يملك جدولاً خاصاً في هذا المخطط، والسبب مقصود: الأرصدة كلها
مشتقة من الـ VIEWs، فإضافة جدول كانت ستخلق مصدر حقيقة ثانياً ينحرف عن الأول.

### سلسلة الاشتقاق المحققة حياً

```
INVENTORY_RECEIVE(_DETAILES) ──┐
INVENTORY_SARF(_DETAILES)    ──┤
INVENTORY_TRANSM/_TRANSD      ──┤
SALES_BILL / BUY_BILL         ──┼─► ITEM_MOVE_D (VIEW · UNION ALL)
RETURN_SALES / RETURN_BUY     ──┤        └─► ITEM_MOVEMENT_D (VIEW · يستثني 2/11/12)
GARD / GARD_DETAILES          ──┘                ├─► LAST_COST (VIEW)
                                                   └─► AVVG (VIEW · رصيد صنف×مخزن)
```

### ما أُنشئ (DDL)

13 `CREATE SEQUENCE` فقط — لا `CREATE TABLE` ولا `ALTER TABLE` ولا فهرس جديد:
`SEQ_STORES_RCV`(536) · `SEQ_STORES_ISS`(302) · `SEQ_STORES_TRNM`(265472) ·
`SEQ_STORES_TRND`(2641710002) · `SEQ_STORES_ITEM`(2184) · `SEQ_STORES_ITEM_D`(101010001014) ·
`SEQ_STORES_PSANF`(2188) · `SEQ_STORES_STORE`(13) · `SEQ_STORES_GROUP`(10) ·
`SEQ_STORES_TYPE`(28) · `SEQ_STORES_UNIT`(12) · `SEQ_STORES_CAT`(19) · `SEQ_STORES_KEEPER`(1).

نقاط البداية = `MAX+1` المقاس على القاعدة الحيّة (INVENTORY_RECEIVE 535 · SARF 301 ·
TR_INM 265,471 · TR_IN_D 2,641,710,001 · SANF 2,183 · SANF_DNO 1,010,100,010,013 ·
PARTIAL_SANFS.SEQ_NO 2,187 · STORES 12 · GROUP1 9 · TYPES 27 · UNITS 11 · CATEGORY 18).

### حقائق المخطط التي تحكم كتابة القسم

1. **`AVVG` = 2,856 صفاً على 3 مخازن (1/3/4) وقيمتها 319,310,696** — وفيها 41 صفاً بكمية سالبة.
2. **`ITEM_MOVEMENT_D` تستثني المخازن 2 · 11 · 12 نصاً**: `store_no NOT IN (11, 12, 2)`.
   لذلك قسم المخازن يرفض إنشاء/تعديل مستند عليها (وإلا حُفظ الأمر بلا أثر في أي رصيد).
3. **`FLAG_CANCEL` غير مقروء في أي فرع من الـ VIEW** ⇒ حذف المستند = حذف فيزيائي للصفوف.
4. **فرع التحويل** يربط `INVENTORY_TRANSD.SIZE_FRM = SANFS_D.LEN` و`SIZE_TO = SANFS_D.WID`،
   ولذلك كل سطر تحويل ينسخهما من الصنف الفرعي.
5. **فرعا التوريد/الصرف** يربطان `SANF_DNO` بالصنف الفرعي؛ `INVENTORY_SARF_DETAILES.SANF_DNO`
   إلزامي في المخطط نفسه.
6. **المستند يحتاج `TYPENO` صحيحاً**: 12 توريد · 13 صرف · 4 تحويل وارد · 5 تحويل منصرف.
7. **`GARD_TYPE = 6` يُدرج كحركة موجبة** في `ITEM_MOVE_D` ⇒ لا يُكتب فيه جرد جديد (يضاعف الرصيد).
8. **`SANFS` يشترط `SANF_NAME` و`PART_NO` فريدين**، و`SANFS_D` يشترط `TYPE_NO` و`SANF_COCE`
   و`SANF_DNAME` و`WID` و`LEN` و`STYL_NO`، و`INVENTORY_RECEIVE` يشترط `DETAILES` و`CUR_NO`
   و`CUR_PRICE` و`SELECT1` و`SANF_NUMS` و`PROV_NAME`.
9. **الربط بـ`STYLE` شرط ظهور**: `ITEM_MOVEMENT_D` تربط `sanfs.styl_no = style.shape_style_no`،
   فصنف بلا نمط لا يظهر في أي حركة ولا رصيد وإن كان موجوداً في `SANFS`.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** 13 تسلسلاً · **DML:** لا · **لا تعديل جداول**.

---

## 2026-11-01 — عطل تسلسل الكتالوج: `SEQ_APP_PERMISSIONS` متأخر عن `MAX(PERMISSION_ID)`

**الحالة المقيسة على قاعدة التطبيق:** `COUNT(*) = 147`، `MAX(PERMISSION_ID) = 188`،
بينما `SEQ_APP_PERMISSIONS.NEXTVAL = 186`.

**الأثر:** كل إدراج جديد في `APP_PERMISSIONS` (أي كود صلاحية جديد لأي قسم) كان يرمي
`ORA-00001` على `APP_PERM_PK`. الملاحظ أن `TRG_APP_PERMISSIONS` سليم ومفعّل، والمشكلة في
قيمة التسلسل نفسها لا في المُشغّل.

**الأصل المقدّر:** إعادة إنشاء/استيراد للكتالوج بمعرّفات صريحة (سكربتات `01` و`03` و`06`)
دون مزامنة التسلسل مع أعلى معرّف.

**الإصلاح (11g بلا `RESTART`):**

```sql
ALTER SEQUENCE SEQ_APP_PERMISSIONS INCREMENT BY 2;
SELECT SEQ_APP_PERMISSIONS.NEXTVAL FROM DUAL;
ALTER SEQUENCE SEQ_APP_PERMISSIONS INCREMENT BY 1;
-- بعدها: NEXTVAL = 190 > MAX = 188
```

**النتيجة:** البذر نجح و`APP_PERMISSIONS` = 173 صفاً (31 لقسم المخازن).

**درس قابل للتطبيق:** أي سكربت يزرع الكتالوج بمعرّفات صريحة يجب أن يُتبعه بمزامنة التسلسل،
وإلا فُتح باب إضافة الصلاحيات مغلقاً بصمت حتى يكتشفه أول قسم جديد.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** تسلسل واحد · **DML:** 26 إدراجاً · **لا جدول جديد**.

---

## 2026-11-01 — تسلسل سجل النشاط كان متأخراً 271 رقماً: التدقيق كان ميتاً بصمت

**كيف انكشف:** اختبارا `TailoringTest` و`CustomerMeasurementTest` يثبتان أن الطباعة/التصدير
يتركان صف نشاط واحداً. بعد إصلاح تسلسل الكتالوج بدأا يفشلان، فقاد التحقيق إلى `ActivityLogger`.

**الحالة المقيسة على قاعدة التطبيق:**

```sql
SELECT COUNT(*) AS C, MAX(ACTIVITY_ID) AS M FROM ACCOUNTS.APP_USER_ACTIVITY;  -- M = 840
SELECT SEQ_APP_ACTIVITY.NEXTVAL AS N FROM DUAL;                              -- N = 569
```

**الأثر (الأخطر في هذا العطل):** `ActivityLogger` يلفّ الإدراج في `try/catch` كي لا يُسقط الطلب
الأصلي، فـ`ORA-00001` على `APP_USER_ACTIVITY_PK` كان **يُبتلع بلا أي تسجيل**. النتيجة أن سجل
التدقيق كله لم يكتب صفاً منذ أن تجاوز `MAX(ACTIVITY_ID)` قيمة التسلسل، وشاشات «سجل النشاط»
في الإدارة كانت تعرض صفوفاً قديمة فقط — أي **تدقيق معطّل يبدو سليماً**.

**مسبار شامل** لستة أزواج (تسلسل ↔ جدول) كشف ثلاثة متأخرة إضافة إلى الكتالوج:

| التسلسل | الجدول | MAX(id) | NEXTVAL | الحالة |
|---|---|---|---|---|
| `SEQ_APP_ACTIVITY` | `APP_USER_ACTIVITY` | 840 | 569 | متأخر 271 ⇒ أُصلح |
| `SEQ_APP_USERS_PERM` | `APP_USERS_PERMISSIONS` | 233 | 232 | على الحد ⇒ أُصلح |
| `SEQ_APP_SETTINGS` | `APP_SETTINGS` | 25 | 25 | على الحد ⇒ أُصلح |
| `SEQ_APP_USERS_ID` | `APP_USERS` | 107 | 108 | سليم |
| `SEQ_APP_SUPPORT_TICKETS` | `APP_SUPPORT_TICKETS` | — | — | سليم |
| `SEQ_APP_PERMISSIONS` | `APP_PERMISSIONS` | 188 | 190 | سليم (بعد الإصلاح السابق) |

> `NEXTVAL` **يتقدم** عند كل قراءة، فالمسبار ليس للقراءة فقط؛ اعتُمدت أول قراءة كمرجع.

**الإصلاح (نمط 11g بلا `RESTART`):** `ALTER SEQUENCE … INCREMENT BY (MAX-NEXT+1)` ثم استدعاء
`NEXTVAL` واحد ثم `INCREMENT BY 1`. النتيجة: `SEQ_APP_ACTIVITY.NEXTVAL = 842`،
`SEQ_APP_USERS_PERM = 268`، وأُكّد الإدراج فعلياً.

**حارس دائم:** `kyApp_API/tests/Feature/SequenceIntegrityTest.php` — اختبار لكل تسلسل
(`NEXTVAL > MAX(id)`) + اختبار إدراج حقيقي في `APP_USER_ACTIVITY` داخل معاملة تُتراجَع.

**درس قابل للتطبيق:** أي طبقة تدقيق "تُسقط" أخطاء الإدراج كي لا تُسقط الطلب الأصلي يجب أن تُبقى
صحيتها مُثبتة باختبار إدراج فعلي، وإلا فإنها تفشل بصمت تام وتظل تبدو عاملة.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** 3 تسلسلات · **DML:** لا · **لا جدول جديد**.

---

## 2026-11-01 — قياس الأرصدة السالبة: 95 صفاً لا 41

**الاستعلام:** تجميع على `ACCOUNTS.AVVG` بعدد صفوف سالبة لكل مخزن
(`SUM(CASE WHEN SUM_TP < 0 THEN 1 ELSE 0 END)`).

```
store 1:  items=572  value=-154,023,387.00  negative=56
store 2:  items=0    value=0.00             negative=0
store 3:  items=106  value=61,980,084.00    negative=36
store 4:  items=36   value=23,985,200.00    negative=3
store 11: items=0    value=0.00             negative=0
store 12: items=0    value=0.00             negative=0
الإجمالي: 95 صفاً سالباً
```

**تصحيح لحقيقة سابقة:** كان مُسجَّلاً سابقاً أن الأرصدة السالبة «41 صفاً» وهو تجميع على
تجميع مختلف. القياس على مستوى صنف×مخزن يعطي **95**، وهو ما تعتمده الواجهة.

**دخولها الخادم:** `StoreController::index` صار يرجع `NEGATIVE` لكل مخزن، و`StoreModel.negative`
يقرأها، و`StoresState.negativeCount` يجمعها على المخازن غير الأرشيفية، ولوحة القسم تعرضها
كمؤشر إنذار (أحمر عند وجود سالب).

**ملاحظة مهمة:** المخزن 1 قيمته **سالبة** (‎-154,023,387) — أي أن رصيد مخزنه الكلي بالسالب
حسب `AVVG`، وهذا يعكس كمية سالبة أكثر من القيمة. لا خطأ في الاستعلام: المخازن 2/11/12
صفر لأن `ITEM_MOVEMENT_D` تستثنيها أصلاً.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-02 — حقائق مخطط جديدة تحكم مستندات المخازن، وتقسيم قاعدة البيانات

### أ) الاكتشاف الأخطر: موصلان، قاعدتان

`oracledb` MCP متصل بخدمة **orcl**، والتطبيق (Laravel/oracle) متصل بخدمة **orcl3**. نفس الاستعلام
أعطى لفاتورة 535: **18 سطراً** عند الموصل و**36 سطراً** عند التطبيق.

**الأثر على هذا المشروع:** كل نقطة بداية لتسلسلات المخازن حُسبت سابقاً من `MAX+1` المقاس على
الموصل، فطلع في قاعدة التطبيق تسلسلان متأخران (`SEQ_STORES_TYPE`: 801 مقابل 28 ·
`SEQ_STORES_UNIT`: 12 على الحد) — أي أن أول إنشاء مجموعة فرعية أو وحدة كان سيفشل بـ`ORA-00001`.
أُصلحا بـ`ALTER SEQUENCE … INCREMENT BY gap` (تفصيلهما في `db_commends.md`).

**درس قابل للتطبيق:** أي قياس على «قاعدة البيانات» يجب أن يُؤخذ من اتصال التطبيق نفسه لا من
موصل جانبي؛ الاختلاف لا يظهر كخطأ، بل كنقطة بداية تسلسل تبدو معقولة.

### ب) حقائق المخطط التي بُني عليها قالب المستند

| الكائن | الحقيقة |
|---|---|
| `CURRENCY` | `CUR_NO`, `CUR_NAME` — ثلاثة صفوف: 1 يمني · 2 دولار · 3 سعودي |
| `SANFS_COLOR` | `COLOR_NO`, `COLOR_NAME`, `COLOR_TYPE` — جدول الألوان، وليس `COLORS`. `COLOR_NO` فريد (فحص التكرار أعاد صفراً) فالربط به لا يُضاعف السطور |
| `CHART_ACC` | `ACC_NO`, `ACC_NAME` — أسماء الحسابات لخانتَي «حساب المخزن / حساب دائن» |
| `INVENTORY_RECEIVE_DETAILES` | تحمل `CAP` (عبوة) و`PCS` (قطعة) و`SHELF_NO` (الرف) و`SIZE_FRM/SIZE_TO` (المقاس المخزّن في السطر) و`CATEGORY` (التصنيف نص) و`COLOR_NO` و`STYLE_NO` و`CAT_NO` و`STK_COST/SANF_COST` |
| `INVENTORY_SARF_DETAILES` | نفس الأعمدة، و`SANF_DNO` إلزامي فيها |
| `INVENTORY_TRANSD` | نفس الأعمدة + `RCVDONE` و`SQTY/SUNIT_NO` و`TOTALD` و`UNIT_NO` الخاص بها |
| `BILL_TYPE` | 1 = نقد · 2 = آجل (مُقيس على البيانات الحيّة) |
| `SELECT1` | 1 أو 2 — خيار «بالعملة المحلية / بعملة الحساب المدين» |
| `INVENTORY_TRANSM` | لا يحمل `CREATED_BY_NAME`: الأسماء تُقرأ من `APP_USERS` بربط `CREATE_BY` / `UPDATE_BY` |
| `INVENTORY_SARF` | **لا عمود رقم مرجع** عندها (`PROV_BILL` للتوريد فقط) — فالحقل يُكتب حيث يوجد وحده |

### ج) المقاسات تُقرأ من السطر لا من الصنف

`SIZE_FRM/SIZE_TO` مخزَّنة في جدول السطور نفسها، وهي ما يطبعه المستند. القراءة من `SANFS_D.LEN/WID`
كانت تجعل المستند التاريخي يتغيّر لو عدّل أحد الصنف الفرعي بعد الحركة.

### د) فاتورة 535: 36 سطراً والإجمالي 606,200 بينما `NET` = 303,100

في قاعدة التطبيق الجدول فيه 36 صفاً مجموعها 606,200، والرأس `TOTAL/NET` = 303,100. الطبعة
المكتبية تعرض الرقمين معاً (الإجمالي من السطور، والصافي من الرأس). القاعدة المعتمدة في
التطبيق: **العرض والطباعة يقرآن قيم الرأس المخزّنة كما تفعل الطبعة**، و**النموذج يحسب المجاميع
من السطور كما يفعل نموذج النظام** — وهما متسقتان في أي مستند يُنشأ من التطبيق.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** تسلسلان · **DML:** لا · **لا جدول جديد**.

---

## 2026-11-02 — جرد فروق المخطط الحقيقية بين الأنواع الثلاثة (أساس اختلافها)

**الطريقة:** قراءة `ALL_TAB_COLUMNS` عبر **اتصال التطبيق** (خدمة orcl3) لا موصل MCP، لأن الموصل خدمة أخرى — وهذا أثبتته أخطاء سابقة.

### أ) الرؤوس (42 · 42 · 48 عموداً)

| النوع | أعمدة يملكها وحده |
|---|---|
| `INVENTORY_RECEIVE` | `PROV_NAME` (ويملك `PROV_NO` و`PROV_BILL` أيضاً) |
| `INVENTORY_SARF` | `CUST_NO`, `CUST_NAME`, `SEQBILL` |
| `INVENTORY_TRANSM` | `TR_INV_M_ID`, `TYPENO`, `CAT_ID`, `GOV_NO`, `STORE_TO`, `COSTCN_ID`, `RCV_DONE`, `CREATE_BY`, `CREATE_DATE`, `UPDATE_BY`, `UPDATE_DATE` |

**ما ينقص كل نوع:** التوريد والصرف بلا أي عمود تحويلي؛ والتحويل **بلا** `PROV_NAME` و`CREATED_BY` و`CREATED_BY_NAME` و`TR_TYPE_ID` و`LAST_UPDATED_BY_NAME` و`CANCEL_NOTE` و`SEQBIL` و`SEQBILL`.

**الأثر:** `CREATED_BY_NAME` و`LAST_UPDATED_BY_NAME` غير موجودين في جدول التحويل، فقراءتهما من مسار مشترك تُسقط نوعه — ولهذا يُقرأ اسماه من `APP_USERS` عبر `CREATE_BY`/`UPDATE_BY`.

### ب) السطور (25 · 23 · 42 عموداً)

| النوع | ما يخصّه |
|---|---|
| `INVENTORY_RECEIVE_DETAILES` | `CURNO`, `CURPRICE` (عملة السطر) + `TOTAL` |
| `INVENTORY_SARF_DETAILES` | `TOTAL` فقط (بلا عملة سطر) |
| `INVENTORY_TRANSD` | `TOTALD` **بدل** `TOTAL`، و`TR_INV_D_ID`, `TR_INV_M_ID`, `TYPENO`, `CAT_ID`, `DDATE`, `GOVNO`, `STORENO`, `STORETO`, `DETAILE`, `DIS_RATE1`, `DISCOUNT1`, `RCVDONE`, `CREATEBY`, `CREATEDATE`, `UPDATEBY`, `UPDATEDATE`, `UNIT_NO`, `SUNIT_NO`, `SQTY` |

**الأثر:** كتابة `CURNO/CURPRICE` في مسار مشترك تُسقط إنشاء الصرف وتفصيله؛ و`TOTAL` غير موجود في `INVENTORY_TRANSD` فالمجموع يُقرأ من `TOTALD`.

### ج) ما بُني على هذا الجرد

`StorePolicy::documents()` صار يعلن لكل نوع حقله: `bill_type` · `reference` (والعمود الذي يحمله: `PROV_BILL` للتوريد و`SEQBILL` للصرف و`PROV_BILL` رقمياً للتحويل) · `reference_writable` · `party` · `target_store` · `serials` · `movement_type` · `entry_no` · `discount` · `currency_pair` · `line_currency` · `line_cost` · `line_pack` · `line_available`.

والمتحكمات تقرأ هذه الأعلام بدل شروط `kind == …`، فيستحيل أن يُقرأ عمود في نوع لا يملكه.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-03 — كميات الأصناف الفرعية: `AVVG` لا تعرفها، و`P_CODE` هو المفتاح

### أ) الحقيقة المكتشفة

`ACCOUNTS.AVVG` مُجمَّعة على **الصنف الرئيسي × المخزن** (`I_CODE, INV_ID`)، ولا يوجد فيها أي
عمود للصنف الفرعي. من يطلب «كمية الفرع» من `AVVG` يحصل على كمية الصنف كاملة أو على صفر.

المصدر الحقيقي هو `ACCOUNTS.ITEM_MOVEMENT_D` عبر `P_CODE`، وهو **يساوي**
`ACCOUNTS.SANFS_D.SANF_DNO` — أُثبت بمقارنة صفوف الحركة بأرقام الفروع الفعلية.

### ب) أعمدة `ITEM_MOVEMENT_D` التي تخص التفصيل

`P_CODE` (الفرع) · `WID` · `LEN` · `COLOR_NO` · `P_QTY` (موجب وارد، سالب صادر) · `STK_COST` ·
`INV_ID` · `INV_NAME` · `BILL_DOC_TYPE` · `TR_INV_TYPE_NAME` · `DOC_NO` · `I_DATE`.

### ج) استعلام كمية الفرع (المُعتمد في الكود)

```sql
LEFT JOIN (
     SELECT m.P_CODE, SUM(m.P_QTY) AS QTY
       FROM ACCOUNTS.ITEM_MOVEMENT_D m
      WHERE m.I_CODE = :sanf_no      -- ← القيد الذي يجعل الاستعلام رخيصاً
      GROUP BY m.P_CODE
) q ON q.P_CODE = d.SANF_DNO
```

**لماذا هذا القيد؟** بلا `m.I_CODE` سيُجمَّع الـ VIEW كاملة (~150 ألف حركة) في كل فتح صنف.
معه يصبح المسح على صنف واحد. القياس على الصنف 567 (115 فرعاً و1,157 حركة) أعاد الكميات فوراً.

### د) أرقام مقاسة على القاعدة الحية

| القياس | النتيجة |
|---|---|
| أكثر الأصناف حركة | الصنف 1990 (7,322 حركة · فرع واحد) |
| أعلى تفرّع | الصنف 567 (1,157 حركة · **115** فرعاً) |
| عدد الأصناف الفرعية في النظام | 9,005 صفاً في `SANFS_D` |
| أول مجموعة رئيسية | `GROUP_NO = 1` — «الأقمشة والمواد الخام» · 5 أنواع · 999 صنفاً |
| أول مجموعة فرعية منها | `TYPE_NO = 101` — «الأقمشة» · 735 صنفاً (724 نشطاً) |
| الفئات | 19 صفاً — تُعرض كلها افتراضياً كما طُلب |
| `COLOR_NO = 0` | شائع في بيانات الفرع ⇒ الواجهة تُظهر بديلاً نصياً بدل «لون 0» |

### هـ) لماذا لا كمية في تبويب الفروع العام

تبويب «الأصناف الفرعية» يعرض 9,005 فرعاً بصفحات. حساب كمية لكل فرع يعني تجميع الـ VIEW كلها
في كل طلب — أي ثانية أو أكثر لكل صفحة. لذلك الكمية تظهر في تفصيل الصنف (مسح مقيَّد) والتبويب
العام يعرض الهوية والمقاس واللون والحالة فقط. هذا مُوثَّق داخل الكود نفسه لمنع «تحسين» لاحق
يُدخل العمود ويقتل زمن الاستجابة.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-03 — قياس حاسم: كل قراءة من `AVVG` تكلّف ~١٣ ثانية

### المشكلة

`/api/stores/items` كان يتجاوز مهلة العميل (١٥ ثانية) فتُفتح شاشة الأصناف فارغة. القياس الفعلي:

| القياس | الزمن |
|---|---|
| `SELECT I_CODE, SUM(SUM_TP), SUM(SUM_PRICE), MAX(STK_COST) FROM ACCOUNTS.AVVG GROUP BY I_CODE` | **14,628 مللي** |
| نفس التجميع مقيَّداً بـ`WHERE I_CODE IN (٥٠ صنفاً)` | **12,780 مللي** |
| `SELECT COUNT(*) FROM ACCOUNTS.SANFS WHERE GROUPNO=1 AND TYPE_NO=101 AND NVL(ACTIVE,1)=1` | 2 مللي |
| `SELECT SANF_NO, COUNT(*) FROM ACCOUNTS.SANFS_D GROUP BY SANF_NO` | 14 مللي |
| استعلام الصفحة كاملاً بلا `AVVG` (روابط + تجميع الفئة + ترقيم) | **12 مللي** |

**الاستنتاج:** التقييد بـ`I_CODE` **لا يُدفع** إلى فروع الـ`UNION ALL` داخل العرض، فيظل العرض
يُجمّع تاريخ الحركة كاملاً قبل الفلترة. أي أن وجود `AVVG` في مسار أي شاشة يجعلها ~١٣ ثانية مهما
ضاق نطاقها.

### ما اعتمدته الشاشات

| الشاشة | مصدر الكمية | الزمن |
|---|---|---|
| قائمة الأصناف | لا شىء (الأرصدة اختيارية بـ`with_stock`) | ~12 مللي |
| تفصيل الصنف | مجموع كميات الفروع من `ITEM_MOVEMENT_D` | ~170 مللي |
| كشف حركة الصنف | `ITEM_MOVEMENT_D` مقيَّداً بالصنف | ~220 مللي |
| أرصدة المخازن والتقارير | `AVVG` (لا بديل — موضوعها الأرصدة) | ~١٣ ثانية (قائم قبل هذا العمل) |

### حقيقة إضافية عن حزمة المراجع

`/api/stores/reference` يُرجع الأعمدة بأسماء **صغيرة** (`group_no`) من منتقي OCI8. كان
`clean()` يمرّرها كما هي، فقرأها العميل `0`. صار `clean()` يُطبّعها إلى أحرف كبيرة — وهذا
صحّح أيضاً `isset($item['STORE_NO'])` الذي لم يكن يتحقق أبداً فلم يُضبط وسم «أرشيفي»
للمخازن 2/11/12.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-04 — بديل `AVVG` لرصيد الأصناف والفروع (مقاس)

### الحقيقة التي اعتمد عليها التصميم

`AVVG` نفسها مشتقة من حركة المخزون، لكنها **تُجمّع كل التاريخ قبل الفلترة**: التقييد بـ`I_CODE`
لا يُدفع إلى داخل فروع `UNION ALL`، فلم يوفّر القيد شيئاً (12,780 مللي مقابل 14,589 مللي).

| الاستعلام | الصفوف | الزمن |
|---|---|---|
| `SELECT I_CODE, SUM(SUM_TP) FROM ACCOUNTS.AVVG GROUP BY I_CODE` | 580 | **14,589 مللي** |
| `SELECT P_CODE, SUM(P_QTY) FROM ACCOUNTS.ITEM_MOVEMENT_D GROUP BY P_CODE` | 2,316 | **1,552 مللي** |
| `SELECT I_CODE, SUM(P_QTY) FROM ACCOUNTS.ITEM_MOVEMENT_D GROUP BY I_CODE` | 583 | **1,700 مللي** |
| صفحة الأصناف (٥٠) بعد استبدال المصدر | 50 | **2,616 مللي** |
| صفحة الفروع (٥٠) مع رصيد كل فرع | 50 | **2,150 مللي** |

### الصيغة المعتمدة

```sql
-- رصيد الصنف الرئيسي = مجموع أرصدة فروعه
LEFT JOIN (
      SELECT d.SANF_NO, SUM(b.QTY) AS QTY, SUM(b.VALUE) AS VALUE, MAX(b.COST) AS COST
        FROM ACCOUNTS.SANFS_D d
        JOIN (SELECT P_CODE,
                     SUM(P_QTY) AS QTY,
                     SUM(P_QTY * STK_COST) AS VALUE,
                     MAX(STK_COST) AS COST
                FROM ACCOUNTS.ITEM_MOVEMENT_D
               GROUP BY P_CODE) b
          ON b.P_CODE = d.SANF_DNO
       GROUP BY d.SANF_NO
) mv ON mv.SANF_NO = s.SANF_NO
```

**نتيجة جوهرية:** لأن القائمة والتفصيل وكشف الحركة تستخدم **نفس** تجميع الحركة بالفرع، فإن
مجموع الفروع = الرصيد المعروض للصنف الأب **بنيوياً**، لا بالصدفة. وهذا ما يفرضه الاختبار
`the default filter combination returns items, not zero` بمقارنة الرقمين فعلياً.

### نفي تكرار الصنف الفرعي من البيانات

| الفحص | النتيجة |
|---|---|
| مجموعات `SANFS_D` المتكررة بـ(`SANF_NO`,`PART_NO`,`LEN`,`WID`,`COLOR_NO`) | **صفر** |
| `SANFS_COLOR` | 27 صفاً / 27 معرّفاً مميزاً (لا تكرار) |
| استعلام تبويب الفروع (صفحة 50) | 50 صفاً / **50** معرّفاً مميزاً |

فالوقاية أُضيفت بنيوياً على طبقتين: `GROUP BY d.SANF_DNO` في الخادم، وإزالة التكرار في المستودع،
مع حارس اختباري يفرض تساوي عدد الصفوف وعدد المعرّفات المميزة.

**ملاحظة:** عمود `COLOR_NO` يساوي 0 في كثير من الفروع، لذلك تعرض الواجهة النص المخزّن بديلاً
(`DCOLOR`/`MCOLOR`) بدل «لون 0».

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-04 — حقائق `SANFS_D` التي تفرز بين الفرع وأبيه

### أ) `SANFS_D.SANF_NAME` ليس اسم الأب

`SANFS_D` فيه عمودان للتسمية، كلاهما `NOT NULL`:

| العمود | معناه |
|---|---|
| `SANF_NAME` | اسم الفرع كما يخزّنه جدول الفروع نفسه — **وليس** اسم الصنف الرئيسي |
| `SANF_DNAME` | الوصف التفصيلي للفرع (وهو ما يُعرض أولاً) |

فالقراءة السابقة `parentName ← SANF_NAME` كانت تجعل شاشة الفرع تعرض تسمية من جدول الفروع
وتنسبها للأب. الصواب: الأب يُجلب صراحةً من `SANFS` بوسم `PARENT_NAME`.

### ب) للفرع قيمته المستقلة عن أبيه

`SANFS_D` يحمل أعمدة تملكها الفروع ولا يرثها من `SANFS`:

```
SANF_PRICE  ·  UNIT_NO  ·  CAP  ·  BUY_PRICE  ·  CUR_NO  ·  CATEGORY
DCOLOR / MCOLOR (نص اللون)  ·  COLOR_NO (مرجع إلى SANFS_COLOR)  ·  DEP  ·  STORNO
```

**الأثر على الواجهة:** شاشة الفرع بلا هذه الأعمدة تعرض حقولاً فارغة، فتبدو كأن الفرع «بلا
بيانات» بينما البيانات موجودة في نفس الصف. لذلك أُضيفت إلى `fetchSubs` و`subIndex` مع
`LEFT JOIN ACCOUNTS.UNITS u ON u.UNIT_NO = d.UNIT_NO`.

### ج) الألوان مرجعها `SANFS_COLOR` وهي فريدة

`SELECT COUNT(*) AS R, COUNT(DISTINCT COLOR_NO) AS D FROM ACCOUNTS.SANFS_COLOR` ⇒ **27 / 27**.
فرابط اللون لا يضاعف الصفوف، و`COLOR_NO = 0` شائع في البيانات لذلك تعرض الواجهة النص
(`DCOLOR`/`MCOLOR`) بديلاً بدل «لون 0».

### د) الرصيد لا مصدر له غير الحركة

تكرار التأكيد لأن هذا هو الأساس الذي تُبنى عليه شاشة الفرع: `AVVG` لا تعرف الأصناف الفرعية
(مفتاحها `I_CODE × INV_ID`)، فرصيد الفرع = `SUM(P_QTY)` من `ITEM_MOVEMENT_D` بمعرّف `P_CODE`،
ورصيد الأب = مجموع فروعه من نفس المصدر.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-04 — `SANFS_COLOR` غير فريد المعرّف: 54 صفاً لـ 27 لوناً

### الحقيقة المقاسة على قاعدة التطبيق (`SERVICE=orcl3`)

```sql
SELECT COUNT(*) AS R, COUNT(DISTINCT COLOR_NO) AS D FROM ACCOUNTS.SANFS_COLOR;
-- R = 54 ، D = 27  ← كل COLOR_NO يتكرر صفّين (يبدو التمييز بـ COLOR_TYPE)

SELECT COUNT(*) AS R, COUNT(DISTINCT UNIT_NO) AS D FROM ACCOUNTS.UNITS;
-- R = D = 12  (فريد، الرابط عليه آمن)

SELECT COUNT(*) AS C FROM ACCOUNTS.SANFS WHERE SANF_NO = 109;
-- C = 1  (المفتاح فعلاً SANF_NO)
```

### الأثر على الاستعلامات

```sql
SELECT COUNT(*) FROM ACCOUNTS.SANFS_D d
  LEFT JOIN ACCOUNTS.SANFS_COLOR sc ON sc.COLOR_NO = d.COLOR_NO
 WHERE d.SANF_NO = 109;                     -- = 10  (الفروع خمسة!)

SELECT COUNT(*) FROM ACCOUNTS.SANFS_D d
  LEFT JOIN ACCOUNTS.UNITS u ON u.UNIT_NO = d.UNIT_NO
 WHERE d.SANF_NO = 109;                     -- = 5   (سليم)
```

**القاعدة المستخلصة:** في هذا المخطط القديم لا تُصدَّق فريدة عمود لم يُتحقق منها. أي
`LEFT JOIN` على جدول وصفي (ألوان/تصنيفات) يضاعف الصفوف بصمت، والمضاعفة تظهر كـ«سطر مكرر»
وكـ**رصيد مضاعف** في الوقت نفسه، لأن التجميع فوق صفوف مكررة يجمع المكرر مرتين.

### القاعدة المعتمدة في الكود بعد هذا

- أسماء الألوان والوحدات وأسماء الفروع: **استعلام فردي بـ`MAX()`** لا رابط.
- تجميع رصيد الأب: يبدأ من `SELECT DISTINCT SANF_NO, SANF_DNO FROM SANFS_D`.
- عدّاد الفروع: `COUNT(DISTINCT SANF_DNO)`.
- وكل رقم يُقارن بمصدره المستقل قبل اعتماده (`list == sumBranches`).

### ملاحظة على `AVVG` مقابل الحركة

`AVVG` تُرجع `1504` و`162` حيث يعطي تجميع الحركة `1503.27` و`162.47`: الفرق هو `ROUND` داخل
تعريف العرض نفسه، لا اختلاف مصدر. الرقم المعتمد في الواجهات هو غير المستدير لأنه أدق، وهو
المجموع الحقيقي لفروعه.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **قراءة فقط**.



## 2026-11-07 — طبقة القراءة في تقارير المخازن: قوائم متعددة ومستويات تجميع (بلا أي DDL)

**لم يُنشَأ أي جدول أو تسلسل أو عمود أو قيد، ولم تُعدَّل بنية إطلاقاً.** التغيير كله في
صياغة استعلامات القراءة فوق الجداول والـ VIEWs القائمة، وفي كيفية ترجمة اختيارات المستخدم
إلى شروط.

### 1) شروط القوائم بدل المفردات (`ITEM_MOVEMENT_D`)

| المعطى | العمود الحقيقي | الوسيط الجديد | الوسيط القديم (ما زال يعمل) |
|---|---|---|---|
| المخازن | `INV_ID` | `store_nos` | `store_no` |
| المجموعة الرئيسية | `GROUPNO` | `group_nos` | `group_no` |
| المجموعة الفرعية للصنف | `TYPE_NO` | `item_type_nos` | `type_no` |
| نوع الحركة | `BILL_DOC_TYPE` | `type_nos` | `type_nos` |
| الصنف الرئيسي | `I_CODE` | `sanf_no` | نفسه |
| الصنف الفرعي | `P_CODE` | `sanf_dno` | نفسه |
| الفئة | عبر `SANFS.CAT_NO` | `cat_no` | نفسه |

- البنية `IN (:gr0, :gr1, …)` بروابط مسمّاة فريدة يولّدها `inClause()`؛ لا رقم مُدمَج داخل
  نص SQL أبداً.
- **التمييز بين `TYPE_NO` و`BILL_DOC_TYPE` يبقى أساسياً:** الأول مجموعة الصنف الفرعية والثاني
  نوع الحركة؛ دمجهما يجعل منتقي «نوع الحركة» يرشّح المجموعة الفرعية فتعود نتيجة فارغة بلا سبب
  ظاهر (عُالج في جلسة سابقة ومُنع بالتسمية الآن).
- «لاشي» تصل كفراغ أو كـ`all` وكلاهما يعني **بلا قيد**: لا يُرسل صفرًا ولا معرّفاً وهمياً.

### 2) مستويات تجميع الخلاصة

`GROUP BY` يتبدّل بين: `I_CODE, INV_ID` (افتراضي) · `INV_ID` · `GROUPNO` · `TYPE_NO` ·
`CAT_NAME`. القيم كلها من `match` حرفي في الكود، فلا يصل أي نص مستخدم إلى SQL.

- **العيب الذي ظهر وأُصلح:** `m.I_CODE` كان في قائمة `SELECT` خامًا؛ مع أي `GROUP BY` لا
  يحتويه ترفضه أوراكل بـ`ORA-00979: not a GROUP BY expression`. صار `MAX(m.I_CODE) AS I_CODE`،
  وهو صحيح أيضاً في الوضع الافتراضي لأن `I_CODE` ضمن مفاتيح التجميع.
- كل الأعمدة الوصفية أُخرِجت بصيغة `MAX(...) AS alias` و`ORDER BY alias` — الدرس نفسه الذي
  أعطى `ORA-00935` حين يتكرر `MAX()` داخل `ORDER BY` في كتلة مجمّعة ملفوفة بـ`ROWNUM`.

### 3) أعمدة الفرع واللون في عرض الحركة

```sql
(SELECT MAX(sd.SANF_DNAME) FROM ACCOUNTS.SANFS_D sd WHERE sd.SANF_DNO = m.P_CODE) AS SUB_NAME,
(SELECT MAX(sc.COLOR_NAME) FROM ACCOUNTS.SANFS_COLOR sc WHERE sc.COLOR_NO = m.COLOR_NO) AS COLOR_NAME
```

- لقطة فردية بـ`MAX()` لا `LEFT JOIN`، والسبب موثّق في الكود: `SANFS_COLOR` فيها 54 صفاً
  لـ27 معرّف لون فقط، فأي رابط على عمود غير فريد **يضاعف سطور الحركة نفسها** — وهو جذر مشكلة
  «الأصناف الفرعية مكرّرة مرّتين» التي رُفعت ثلاث مرات في جلسات سابقة.
- الفهرس الأساسي على `SANF_DNO` يجعل اللقطة أرخص من رابط يفسد العدّ.

### 4) منتقي الفروع (`SANFS_D`)

`subIndex` يقبل الآن `sanf_no` ليُرجع فروع صنف بعينه، مع `active=1` للنشط فقط؛ بلا هذا الوسيط
كان على المستخدم البحث في ~9,005 فرع ليجد فرعاً يعرف رقمه.

### 5) السجل والكتابة

- لا كتابة في أي جدول مخزني: التقارير والأرصدة والجرد قراءة فقط، وسجل الطباعة/التصدير وحده
  يكتب في `APP_ACTIVITY` عبر `SEQ_APP_ACTIVITY` (المُصلَّح سابقاً بعد أن كان متأخراً وأوقف
  السجل كله).
- **لا DDL، لا DML، لا تسلسلات جديدة، لا commit.**


## 2026-11-08 (أ) — إصلاح العرض والقالب: لا مساس ببنية القاعدة ولا باستعلاماتها

**لم يُنشَأ أي جدول/تسلسل/عمود/فهرس/قيد، ولم تُنفَّذ `DDL` ولا `DML`.** الجولة client-side
خالصة: تخطيط Flutter وصياغة PDF/XLSX.

**ما له علاقة مباشرة بطبقة البيانات (للعلم لا للتغيير):**

- **الاستعلامات لم تتغيّر حرفيًا**: نفس `ITEM_MOVEMENT_D` (حركة/خلاصة) و`AVVG` (أرصدة/جرد)
  ومنتقيات `SANFS`/`SANFS_D` التي وثِّقت سابقًا، وبوسيطات `store_nos`/`group_nos`/
  `item_type_nos`/`type_nos`/`group_by` ذاتها.
- **العلاقة بين الواجهة والقاعدة صارت أوضح**: حقل `customPeriod` الجديد على نموذج المعطيات
  **عميل-صرف** — لا يُرسل في `toQuery()` ولا يقرأه الخادم، فهو قرار عرض لا قيد استعلام.
- **سقف الصفوف في الخادم هو ما يجعل البناء التدريجي ضروريًا**: `/stores/reports/movement`
  يرجع حتى 2000 (بحد أقصى 5000)، وأي محاولة لرسم هذا كله خلايا `Text` دفعة واحدة في
  `Table` واحد هي ما كان يقتل التطبيق من قبل — لذلك استُخدمت الدفعات (120) بدل صندوق
  التمرير الداخلي وبدل البناء الكامل دفعة واحدة.
- **المطبوع لا يغيّر شيئًا**: طباعة/تصدير تسجّل على `APP_ACTIVITY` فقط عبر
  `SEQ_APP_ACTIVITY`، وهو ما بقي سليمًا بعد إصلاح التسلسل في الجولات السابقة.

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **DDL:** لا · **DML:** لا · **قراءة فقط**.


## 2026-11-08 — لا تغيير في قاعدة البيانات (تعديل عرض/تخطيط تقارير فقط)

**هذه الجولة client-side خالصة:** لم تُنشَأ جدول ولا تسلسل ولا عمود ولا فهرس، ولم تُنفَّذ
`DDL` ولا `DML`، ولم تتغيّر أي استعلامات قراءة: نفس نصوص `ITEM_MOVEMENT_D` و`AVVG` و`SANFS*`
التي وثِّقت في الجولات السابقة.

**ما تغيّر طبقة العرض وحدها:**

- جدول التقرير على الشاشة لم يعد صندوقًا بارتفاع ثابت بتمرير داخلي (`LazyReportTable`)، بل
  تدفق من كتل `Table` يتمدّد بعدد الصفوف مع بناء تدريجي على دفعات (120) حفاظًا على الذاكرة —
  وهي نفس السبب الذي من أجله حُدّ عدد الصفوف في الخادم أصلًا.
- تصدير الـ PDF صار يوزّع السطور على صفحات المستند مع **تكرار رأس الجدول في كل صفحة**؛
  مقاس الصفحة A4 landscape لم يتغيّر، ولا عدد الصفوف التي تُرجعها الواجهة الخلفية.
- **لا جديد في `db_commends.md` لهذه الجولة:** لم يُرسَل أي أمر إلى أوراكل باستثناء ما ترسله
  التطبيق نفسه عند تشغيل التقارير (قراءة فقط).

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **DDL:** لا · **DML:** لا · **قراءة فقط كالعادة**.


## 2026-11-09 — لا تغيير في المخطط، لكن اكتشاف يخصّ قراءة أعمدة أوراكل (عمود الرصيد)

**لا `DDL` ولا `DML` في هذه الجولة كذلك.** لم يُنشأ جدول ولا عمود ولا فهرس، ولم تُحدَّث أي بيانات؛
التغيير كله في طبقة القراءة داخل `kyApp_API` وفي طبقة العرض داخل Flutter.

### الاكتشاف الذي يهمّ أي استعلام قادم

`schema ACCOUNTS` يبقى كما هو (`ITEM_MOVEMENT_D`، `AVVG`، `INVENTORY_RECEIVE/SARF/TRANSM`، `SANFS*`)،
لكن **درايفر OCI8 يعيد مفاتيح الأعمدة بأحرف صغيرة** (`p_qty`, `p_code`, `net_qty`, `inv_id`) بينما
أسماء الأعمدة في المخطط بأحرف كبيرة. الكود الذي يقرأ `$row['P_QTY']` يحصل على `null` صامت — بلا خطأ
وبلا استثناء — فيظهر العمود فراغًا في الشاشة والمطبوع.

**القاعدة المُلزمة الآن:** أي كود يقرأ صفًا قادمًا من `DB::connection('oracle')` يطبّع المفاتيح أولًا:

```php
$row = array_change_key_case((array) $row, CASE_UPPER);
```

طُبِّقت في `StoreReportController` على مسار الحركة ومسار الخلاصة وعلى مساعدَي الرصيد الافتتاحي،
وفي اختبارات `StoreReportTest` عند فحص الصفوف.

> تنبيه: `ArabicEncoding::cleanData()` يعالج **الترميز** (Windows-1256) فقط، ولا علاقة له بحالة
> المفتاح؛ لا يُغني عن التطبيع أعلاه.

### الاستعلامات التي نُفِّذت (قراءة فقط)

1. حدود نافذة الاختبار: `SELECT TO_CHAR(SYSDATE - n, 'YYYY-MM-DD') AS F, TO_CHAR(SYSDATE, …) AS T FROM DUAL`.
2. اختيار أقل المجموعات حركةً: `SELECT GROUPNO, COUNT(*) … FROM ACCOUNTS.ITEM_MOVEMENT_D … GROUP BY GROUPNO`.
3. ما يرسله التطبيق نفسه عند كل تقرير: قراءة من `ITEM_MOVEMENT_D` / `AVVG` / `SANFS*` بلا كتابة.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **قراءة فقط كالعادة**.

---

## 2026-11-09 (تكملة) — تعريف «الرصيد السابق» لكل قسم، وحدود عمر الدفاتر

**لا `DDL` ولا `DML`.** كل ما يلي توثيق لدلالات المخطط كما تُقرأ الآن في `StoreReportController`.

### 1) الرصيد السابق: تعريف واحد صالح لكل النطاقات

الرصيد السابق لأي قسم = مجموع `ITEM_MOVEMENT_D.P_QTY` لكل الحركات التي تقع **قبل** أول يوم من
الفترة، بعد تقييدها بشروط نطاق التقرير نفسها (المخازن · الأصناف · المجموعات) وبالتجميع على عمود
القسم:

```sql
SELECT <sectionColumn | '__all__'>  AS SK,
       NVL(SUM(m.P_QTY), 0)                AS OPEN_QTY,
       NVL(SUM(m.P_QTY * m.STK_COST), 0)   AS OPEN_VALUE
  FROM ACCOUNTS.ITEM_MOVEMENT_D m
 WHERE <scope predicates>
   AND m.I_DATE < TO_DATE(:open_from, 'YYYY-MM-DD')
 GROUP BY <sectionColumn>;          -- يُحذف GROUP BY في نطاق الفرع
```

- **الكمية والقيمة معاً في استعلام واحد:** القسم قد يحمل مخزوناً بلا حركة داخل الفترة، فلا يجوز أن
  يُصفَّر رصيده القيمي.
- **نطاق الفرع بلا عمود تقسيم:** يُنتج صفاً واحداً مفتاحه `'__all__'`، وهو نفس المفتاح الذي يوسم به
  `stampMovement()` سطوره — وإلا افتُتح عمود الرصيد على صفر.
- **شروط النطاق بلا شرط التاريخ:** تُطبَّق على الاستعلامين بالتساوي، وإلا لم يتطابق نصفا التقرير.

### 2) وحدات الأقسام كما هي في المخطط

| النطاق | عمود القسم في `ITEM_MOVEMENT_D` | المعنى في دفاتر الشركة | مفتاح القسم في JSON |
|---|---|---|---|
| `branch` | — | الصنف الفرعي (تقرير مسطّح واحد) | `__all__` |
| `item` | `P_CODE` (= `SANFS_D.SANF_DNO`) | الفرع | رقم الفرع |
| `subgroup` | `I_CODE` | الصنف الرئيسي | `I_CODE` |
| `group` | `TYPE_NO` | المجموعة الفرعية | `TYPE_NO` |

> تصحيح مهم لقراءة الصف: `m.BILL_DOC_TYPE` يُخرَج باسم `TYPE_NO`، و`m.TYPE_NO` (المجموعة الفرعية)
> يُخرَج باسم `ITEM_TYPE_NO`. الخلط بين الاسمين يجعل التقرير الثالث يُقسَّم على الصنف الرئيسي بدل
> المجموعة الفرعية فيبدو نسخة من التقرير الثاني.

### 3) عمر الدفاتر: نتيجة قياس تهمّ أي اختبار مستقبلي

قياس على الجدول الحقيقي أعطى: **أول حركة 2026-04-25**، آخر حركة 2026-10-31، وعدد الصفوف قبل
2026-01-01 = **صفر**. لذلك أي فترة تبدأ قبل 2026-04-25 تعيد رصيداً سابقاً صفرياً **بصدق**، وليست
عيباً في الاستعلام. اختبارات الرصيد السابق تبني نافذتها من `2026-09-01` حتى يكون للفترة افتتاح فعلي.

### 4) الاستعلامات التي نُفِّذت (قراءة فقط)

```sql
-- 1) حدود عمر الدفاتر
SELECT TO_CHAR(MIN(I_DATE),'YYYY-MM-DD') AS MN,
       TO_CHAR(MAX(I_DATE),'YYYY-MM-DD') AS MX,
       COUNT(*) AS C,
       SUM(CASE WHEN I_DATE < TO_DATE('2026-01-01','YYYY-MM-DD') THEN 1 ELSE 0 END) AS PRE26
  FROM ACCOUNTS.ITEM_MOVEMENT_D;

-- 2) الافتتاح لكل قسم (الصيغة نفسها التي يستخدمها الكود)
SELECT m.P_CODE AS SK, NVL(SUM(m.P_QTY),0) OPEN_QTY, NVL(SUM(m.P_QTY*m.STK_COST),0) OPEN_VALUE
  FROM ACCOUNTS.ITEM_MOVEMENT_D m
 WHERE m.INV_ID = 1 AND m.I_DATE < TO_DATE('2026-09-01','YYYY-MM-DD')
 GROUP BY m.P_CODE;

-- 3) فحص الأقسام التي يعيدها الخادم على كل نطاق (تحقيق مؤقّت حُذف بعد التحقق)
SELECT * FROM ACCOUNTS.ITEM_MOVEMENT_D WHERE I_DATE >= TO_DATE(:from,'YYYY-MM-DD') …;
```

**طريقة التحقق المستخدمة:** تشغيل `StoreReportController::movement` مباشرة عبر نص PHP مؤقّت لكل نطاق
وكتابة الناتج إلى `probe_out.json` ثم مقارنة `meta.sections` بـ`SECTION_KEY` في السطور. أثبت ذلك أن
الخلل كان في بناء الإحصاءات لا في المخطط ولا في الاستعلام. الملفات المؤقتة
(`probe_scopes.php`, `probe_opening.php`, `probe_out.json`) حُذفت بعد التحقق.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-09 (تكملة) — لا مساس بالمخطط: العمل كله في طبقة العرض

**لا `DDL` ولا `DML`، ولا استعلام واحد نُفِّذ في هذه الجولة.** التغيير كله داخل Flutter: شكل
إحصاء القسم (سطر واحد بأربعة أرقام) وحجم خط الحقول، وإعادة ثلاثة تعريفات إلى مكانها بعد أن فُقدت
من شجرة العمل (`ReportTotals.opening` · معاملات `_appendColumns` · `double.infinity`).

### ما يجب أن يعرفه من يمسك الاستعلام لاحقاً

- **إحصاء القسم يُقرأ من `meta.sections[]` كما هو، لا من إعادة تجميع.** السطر المختصر يعرض
  `opening_qty · qty_in · qty_out · closing_qty` من القسم نفسه — وهي الأرقام التي جمعها الخادم من
  السطور المعروضة. أي عميل يعيد جمع السطور بنفسه سيخالفها عند الاقتطاع.
- **`opening_value` لا يُعرض في سطر القسم.** سقط من السطر مع `net_qty` و`qty_in_value` و
  `qty_out_value` لأن سطر القسم يجيب سؤال «من أين بدأ وأين انتهى وكم تحرّك» لا سؤال قيمة المخزون.
  الحقول تبقى في الـ JSON ويقرأها إحصاء التقرير الكامل.
- **حذف حقل من نافذة الأعمدة يحذفه من السطر المختصر أيضاً** (`ReportStatFields.visible` بعد
  `section`)، فلا يظهر على الورق ما أخفاه المستخدم على الشاشة.

### الاستعلامات

**لا شيء.** لم يُرسل أي `SELECT` أو `INSERT` أو `UPDATE` أو `DELETE` في هذه الجولة؛ الاختبارات
كلها على مستوى الواجهة (Dart) وعلى مستوى نص السطر والـ PDF المكتبي.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا استعلام**.

---

## 2026-11-09 05:05 — لا تغيير في المخطط ولا في الاستعلامات: العمل كله في رسم الجدول

**DDL:** لا · **DML:** لا · **SELECT:** لا.

لم يُلمس `ACCOUNTS` في هذه الجولة: لا جدول ولا عمود ولا فهرس، ولا استعلام تحقق. السبب أن ما طُلب
عرضٌ لا بيانات:

1. **هندسة جدول التقرير** — `ReportDataTable` يرسم الخلايا الآن في سطر واحد ثابت الارتفاع
   (`FixedColumnWidth` بدل `FlexColumnWidth`، و`FittedBox(scaleDown)`، وحجم خط مقيس بـ`TextPainter`).
2. **حقول الإحصاء الظاهرة** — خمسة افتراضياً: `opening` · `in` · `out` · `net` · `closing`.

### ما يخصّ قاعدة البيانات في هذا التغيير (للعلم فقط)

- **لا حقل جديد ولا حقل مسقط:** الخمسة الظاهرة هي نفس مفاتيح `meta.totals` و`meta.sections[].stats`
  التي يرسلها `StoreReportController` أصلاً (`opening_qty` · `qty_in` · `qty_out` · `net_qty` ·
  `closing_qty`). التغيير في **الانتقاء** لا في الحساب.
- **الحقول الأربعة المخفية افتراضياً** (`rows` · `qty_in_value` · `qty_out_value` ·
  `closing_value`) تبقى في الـ JSON كما هي، ويقرأها المطبوع إذا أظهرها المستخدم من «تخصيص».
- **لا مساس بـ`opening_qty`:** استعلام `openingBySection()` بقي بلا تغيير، وسطر «رصيد سابق» ما زال
  يقرأ `stats.openingQty` نفسها.

### الاستعلامات

**لا شيء.** لا `SELECT` تحقّق ولا قراءة تجريبية ولا ملف تحقيق مؤقت. الاختبارات الجديدة (4) تعمل على
شجرة الواجهة وحدها: عرض 380 بكسل، مقياس خط ١٫٢٥، وسبعة أعمدة.

**النموذج:** Qoder · **الوقت:** 2026-11-09 05:05 · **DDL:** لا · **DML:** لا · **لا استعلام**.


---

## 2026-11-09 06:54 — `ACCOUNTS.CUTTING_SALES_BILL_VIEW`: عمود `MODEL_NOTES`

- **الغرض:** إتاحة ملاحظة الموديل للواجهة من الـ VIEW بدل قراءة `SALES_DETAILES_SHAPES.NOTES2`
  خارجها، بطلب صريح من المستخدم.
- **ما جرى:** `CREATE OR REPLACE FORCE VIEW` بالتعريف الأصلي نفسه (مستخرج من
  `DBMS_METADATA`) مع إضافة `sales_detailes_shapes.notes2` في آخر قائمة SELECT و
  `"MODEL_NOTES"` في آخر قائمة الأعمدة.
- **القياس قبل/بعد:** التعريف 4,488 حرفاً قبل الإضافة؛ بعد الإنشاء `MODEL_NOTES` موجود،
  صفوف العرض 45,490، وعيّنة `(bill 6, year 2026, seq 60373)` تحمل ملاحظة.
- **أثر على المستهلكات:** إضافة عمود في النهاية فقط ⇒ ترتيب الأعمدة السابق محفوظ،
  و`CustomerMeasurementController` و`TailoringController` يعملان بلا تعديل بنيوي.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:54 · **DDL:** نعم (إضافة عمود) · **DML:** لا.


---

## 2026-11-09 08:08 — ملاحظة تشغيلية على العرض (بلا تغيير بنيوي)

- لا تغيير على `CUTTING_SALES_BILL_VIEW` في هذه الجولة؛ عمود `MODEL_NOTES` المُضاف سابقاً
  هو المصدر الوحيد لملاحظة الموديل.
- ملاحظة فنية: `OCI8` يُرجع أسماء أعمدة `ORDSTATE` بحروف صغيرة (`ordsname`, `ordsid`)،
  والقراءة بحروف كبيرة تُنتج `Undefined array key` في لارافيل — تُقرأ المفاتيح بحالتين دائماً.

**النموذج:** Qoder · **الوقت:** 2026-11-09 08:08 · **DDL:** لا · **DML:** لا.


---

## 2026-11-09 10:06 — دلالة أعمدة المال في `SALES_BILL` (ملاحظة تحليلية، لا تغيير بنيوي)

- `TOTAL`, `DISCOUNT`, `NET`, `AMOUNT_PAID`, `OTHERS_PAYMENTS` كلها NUMBER.
- قياس على 1,200 فاتورة تفصيل: `NET == TOTAL` في 1192، `NET < TOTAL` في 4، `NET > TOTAL` في 4.
  ⇒ عمود `NET` خام (يطابق الإجمالي) ولا يعكس الخصم ولا الدفع، فلا يصح اعتماده صافياً أو متبقياً.
- المتبقي الحقيقي = TOTAL − DISCOUNT − AMOUNT_PAID − OTHERS_PAYMENTS (يُصفّر عند السداد).
- `CUTTING_OR_SLAES` عدد وليس نصاً (قيم 1 و2)، فلا يُفلتَر بـ 'cutting'؛ المصدر الموثوق هو
  مفاتيح `CUTTING_SALES_BILL_VIEW`.

**النموذج:** Qoder · **الوقت:** 2026-11-09 10:06 · **DDL:** لا · **DML:** لا.

---

## 2026-11-10 12:30 — جعل ترتيب تبويب الأصناف الفرعية ديناميكياً في `subIndex`

- **نوع التغيير:** تعديل استعلام `SELECT` في التطبيق (`StoreItemController::subIndex`)؛
  **لا DDL** ولا DML ولا أي أمر نُفِّذ يدوياً على القاعدة.
- **قبل:** كان `ORDER BY` مثبّتاً نصاً على `SANF_NAME, LEN, WID, SANF_DNO` داخل الكتلة
  المجمّعة بـ`GROUP BY d.SANF_DNO, d.SANF_NO` الملفوفة بـ`ROWNUM` للترقيم.
- **بعد:** ترتيب اختياري من المستخدم عبر وسائطين `sort`/`dir` يمرّان عبر **قائمة بيضاء**
  حرفية (`match`) تربط المفتاح بعمود مستعار من الكتلة المجمّعة، فلا يصل أي مدخل حر إلى SQL:
  - `parent`→`SANF_NAME` · `no`→`SANF_DNO` · `color`→`COLOR_NAME` · `qty`→`QTY` · `value`→`VALUE`.
  - بنية `ORDER BY <col> <dir> NULLS LAST, SANF_DNO` — ورقم الفرع حاسم للتكرار فيبقى
    ترتيب الصفحة ثابتاً بين جلبتين متطابقتين (ضروري مع Trقيم `ROWNUM`).
- **الأمان:** اتجاه الترتيب لا يُقرأ مباشرة بل يُختزل إلى `asc`/`desc` فقط؛ وأي `sort`
  غير معروف يرجع إلى `SANF_NAME` (الافتراضي الآمن) الذي يطابق الترتيب القديم تماماً.
- **قيد Oracle المُراعَى:** الترتيب بالأسماء المستعيرة لا بـ`MAX(...)`: داخل كتلة مجمّعة
  ملفوفة بـ`ROWNUM` يرمي `ORDER BY MAX(...)` الخطأ `ORA-00935` — والاختيار الجديد يلتزم به.

**النموذج:** Qoder · **الوقت:** 2026-11-10 12:30 · **DDL:** لا · **DML:** لا.

---

## 2026-11-10 06:05 — المخازن: توحيد قالب الطباعة/التصدير — لا تغيير في المخطط ولا في الاستعلامات

العمل كله في طبقة رسم المستند داخل Flutter (PDF/XLSX)، ولم يلمس أي ملف خادم أو أي SQL.

### ما الذي تغيّر من ناحية البيانات؟

- لا جديد في `ACCOUNTS` ولا في أي استعلام: `ITEM_MOVEMENT_D` و`AVVG` تُقرأ بنفس الصيغة.
- لم يُضف حقل ولا أُعيد حساب رقم: الأرقام المطبوعة هي نفسها `meta.stats` و
  `meta.sections[].stats` ومجاميع السطور التي كانت تُطبع قبل ذلك، والتغيير في **الرسم**
  وفي **اختيار الحقول الظاهرة**.
- `buildStoreReportPdf` صار يستقبل `ReportStats` (الكائن الذي يبني شريط الشاشة)، و
  `buildItemStatementPdf` صار يستقبل `MovementStatement` — ولا أي منهما يُعيد حساب شيء:
  هي نفس كائنات الاستجابة نفسها تُمرَّر كما هي، فالورق يقرأ نفس مصدر الشاشة.

### الحقول الافتراضية الظاهرة في المطبوع والشاشة

| المعرّف | العنوان | مصدر الرقم |
|---|---|---|
| `opening` | السابق | `meta.stats.opening_qty` |
| `in` | وارد | `qty_in` |
| `out` | منصرف | `qty_out` |
| `net` | الصافي | `net_qty` (كان ساقطاً من `defaultIds` وأُعيد) |
| `closing` | الرصيد الحالي | `closing_qty` |

والأربعة الباقية (`rows` · `inValue` · `outValue` · `closingValue`) تبقى مخفية حتى يختارها
المستخدم من «تخصيص»، والاختيار يسري على الشاشة والـ PDF والـ XLSX من نفس القائمة.

### الاستعلامات

**لا شيء.** لم يُرسل أي `SELECT` أو `INSERT` أو `UPDATE` أو `DELETE` في هذه الجولة؛
التحقق كله في اختبارات Dart وعلى بايتات PDF المُولَّدة محلياً.

**النموذج:** Qoder · **الوقت:** 2026-11-10 06:05 · **DDL:** لا · **DML:** لا · **لا استعلام**.

---

## 2026-11-10 07:05 — صفحة التقرير الطولية A4: لا تغيير في المخطط ولا في الاستعلامات

العطل كان في **مقاس صفحة PDF** لا في البيانات: صفحة أفقية (842×595) تُطبع على ورق طولي
فتُصغَّر إلى عرضه ويصير ارتفاعها 420 نقطة من 842 — نصف ورقة محتوى ونصفها بياض.

### من ناحية البيانات

- لا `DDL` ولا `DML` ولا `SELECT`: لم تُمسّ `ACCOUNTS` ولا أي استعلام، ولا أُعيد حساب أي رقم.
- نفس مصدر الأرقام كما في الجولة السابقة: `meta.stats` و`meta.sections[].stats` ومجاميع
  السطور، يمرّها العميل كما هي إلى مولّد المستند.
- الذي تغيّر رقمُ ورقةٍ واحد: `PdfPageFormat.a4.landscape` ← `PdfPageFormat.a4`، ومن
  العرض تشتق عروض الأعمدة (`595.28 − 2×16 = 563.28 نقطة`)، فالنتيجة سطور أكثر في
  الصفحة الواحدة (≈ 34 بدل 20) بلا أي تغيير في القيم.

### الاستعلامات

**لا شيء.** التحقق كان على بايتات PDF محلية (فك ضغط محتوى الصفحات وقراءة `MediaBox`
ومواضع النص)، لا على القاعدة.

**النموذج:** Qoder · **الوقت:** 2026-11-10 07:05 · **DDL:** لا · **DML:** لا · **لا استعلام**.

---

## 2026-11-11 12:00 — أثر توحيد ترتيب الكشوفات المالية (قراءة فقط) · Qoder

**لا تغيير في المخطّط:** لا DDL، لا DML، لا sequences. العمل كله داخل `ORDER BY`
في أربعة استعلامات `SELECT` على `ACCOUNTS.ENTRY_SUB es JOIN ACCOUNTS.ENTRY_MAIN em`.

**الاستعلام المعتمد (بعد التعديل):**
```sql
SELECT es.ENTRY_NO, ... , es.ENTRY_MNT
  FROM ACCOUNTS.ENTRY_SUB es
  JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
  JOIN ACCOUNTS.ENTRY_TYPE et ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO
 WHERE es.ACC_NO = :acc_no
 ORDER BY em.ENTRY_DATE, es.SEQ;
```

**التقرير:** «تسلسل الحركة» فُسِّر بـ `ENTRY_SUB.SEQ` (بطلب صريح من المستخدم)،
لذا حُذف المفتاح الوسيط `es.ENTRY_NO` من `ORDER BY` في الأربعة:
`MyStatementController::financialStatement`، `AccountController::getAccountStatement`
(يخدم الشجرة المحاسبية أيضاً)، `WorkerController::fetchStatement`،
`CustomerController::statement`.

**النموذج:** Qoder · **الوقت:** 2026-11-11 12:00 · **DDL:** لا · **DML:** لا · **لا استعلام يدوي على القاعدة**.
