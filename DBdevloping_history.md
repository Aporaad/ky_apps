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
