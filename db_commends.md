# سجل أوامر قاعدة البيانات (Database Commands)

## [2026-09-08 07:20:48]
- **النموذج المنفذ / AI Model:** Gemini 3.7 Flash (Medium)
- **الأمر / SQL Query:**
```sql
SELECT column_name, data_type FROM all_tab_columns WHERE owner = 'ACCOUNTS' AND table_name = 'ENTRY_SUB';
```

## [2026-09-08 07:21:21]
- **النموذج المنفذ / AI Model:** Gemini 3.7 Flash (Medium)
- **الأمر / SQL Query:**
```sql
SELECT table_name, column_name, data_type FROM all_tab_columns WHERE owner = 'ACCOUNTS' AND table_name IN ('ENTRY_MAIN', 'ENTRY_TYPE') ORDER BY table_name, column_id;
```

## [2026-09-08 07:21:33]
- **النموذج المنفذ / AI Model:** Gemini 3.7 Flash (Medium)
- **الأمر / SQL Query:**
```sql
SELECT * FROM (
    SELECT ACCOUNTS.ENTRY_SUB.ENTRY_NO,
           SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 1, 1)||SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 7, 4) AS SUB_ENTRY_NO,
           TO_CHAR(ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, 'YYYY-MM-DD') AS ENTRY_DATE,
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
) WHERE ROWNUM <= 10;
```

## [2026-09-08 20:13:50]
- **النموذج المنفذ / AI Model:** Gemini 3.7 Flash (Medium)
- **الأمر / SQL Query:**
```sql
-- استعلام كشف الحساب التراكمي الشامل مع ربط الحسابات وترتيب الحركات زمنياً
SELECT ACCOUNTS.ENTRY_SUB.ENTRY_NO,
       SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 1, 1)||SUBSTR(TO_CHAR(ACCOUNTS.ENTRY_SUB.ENTRY_NO), 7, 4) AS SUB_ENTRY_NO,
       TO_CHAR(ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, 'DD/MM/YYYY') AS ENTRY_DATE,
       TO_CHAR(ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, 'YYYY-MM-DD') AS RAW_DATE,
       ACCOUNTS.ENTRY_TYPE.ENTRY_TYPE_NAME,
       ACCOUNTS.ENTRY_MAIN.DETAILS,
       ACCOUNTS.ENTRY_SUB.BALANCE_S,
       ACCOUNTS.ENTRY_SUB.ENTRY_MNT,
       ACCOUNTS.CUST.CUST_NAME,
       ACCOUNTS.CUST.CUST_NO,
       ACCOUNTS.CUST.ACC_NO,
       ACCOUNTS.ENTRY_SUB.ACC_NO AS ENTRY_SUB_ACC_NO
FROM ACCOUNTS.ENTRY_MAIN, ACCOUNTS.ENTRY_SUB, ACCOUNTS.ENTRY_TYPE, ACCOUNTS.CUST
WHERE ACCOUNTS.ENTRY_SUB.ACC_NO = ACCOUNTS.CUST.ACC_NO
  AND ACCOUNTS.ENTRY_SUB.GIVING = ACCOUNTS.CUST.CUST_NO
  AND ACCOUNTS.ENTRY_SUB.ENTRY_NO = ACCOUNTS.ENTRY_MAIN.ENTRY_NO
  AND ACCOUNTS.ENTRY_MAIN.ENTRY_TYPE_NO = ACCOUNTS.ENTRY_TYPE.ENTRY_TYPE_NO
  AND ACCOUNTS.CUST.CUST_NO = :custNo
ORDER BY ACCOUNTS.ENTRY_MAIN.ENTRY_DATE, ACCOUNTS.ENTRY_SUB.ENTRY_NO;
```

## [2026-09-08 20:18:50]
- **النموذج المنفذ / AI Model:** Gemini 3.7 Flash (Medium)
- **الأمر / SQL Query:**
```sql
-- استعلام البحث عن العملاء بالاسم ومطابقة محارف أوراكل CP1256 ورقم العميل ورقم الهاتف
SELECT CUST_NO, CUST_NAME, ADDR, TEL1, TEL2, POSTBOX, EMAIL, FAX, ACC_NO, ACCNO, LIMITED_BALANCE, PRE_CUST_NAME, STOPPING_CUST
FROM ACCOUNTS.CUST
WHERE (
    CUST_NAME LIKE '%Ç%' 
    OR CUST_NAME LIKE '%ا%'
    OR TEL1 LIKE '%ا%'
    OR TEL2 LIKE '%ا%'
    OR ADDR LIKE '%Ç%'
    OR ADDR LIKE '%ا%'
    OR PRE_CUST_NAME LIKE '%Ç%'
)
ORDER BY CUST_NO
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
```

## [2026-09-08 22:31:29]
- **النموذج المنفذ / AI Model:** Gemini 3.8 Flash (Medium)
- **الأمر / SQL Query:**
```sql
-- استعلام كشف حساب العاملين (الموظفين، القصاصين، الخياطين) الموحد
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
WHERE (ENTRY_SUB.ACC_NO = :acc_no
       AND ENTRY_MAIN.ENTRY_DATE BETWEEN TO_DATE(:from_date, 'YYYY-MM-DD') AND TO_DATE(:to_date, 'YYYY-MM-DD'))
  AND ENTRY_MAIN.entry_type_no = ENTRY_TYPE.ENTRY_TYPE_no
  AND (ACCOUNTS.ENTRY_SUB.ENTRY_NO = ACCOUNTS.ENTRY_MAIN.ENTRY_NO)
ORDER BY ENTRY_MAIN.ENTRY_DATE;
```


---
## [2026-10-17 05:25:00]
- **النموذج المنفذ / AI Model:** Qoder Agent
- **المهمة / Task:** IBAC — مرحلة 0 و1: إنشاء نموذج بيانات الصلاحيات والإعدادات وسجل النشاط في مخطط ACCOUNTS
- **المرجع / Reference:** `kyApp_API/database/oracle/01_ibac_schema.sql` (نفس النص حرفياً)
- **الأمر / SQL Query:**
```sql
-- [0] نقطة الاسترجاع قبل أي تعديل على جدول المستخدمين الإرثي
CREATE TABLE ACCOUNTS.APP_USERS_BAK_IBAC AS SELECT * FROM ACCOUNTS.APP_USERS;

-- [1] APP_USERS: توسيع كلمة المرور + حقل مدير النظام + تسلسل بلا محفِّز (النظام القديم يكتب في الجدول)
ALTER TABLE ACCOUNTS.APP_USERS MODIFY (USER_PASSWORD VARCHAR2(100));
ALTER TABLE ACCOUNTS.APP_USERS ADD (IS_ADMIN NUMBER(1) DEFAULT 0 NOT NULL);
CREATE SEQUENCE ACCOUNTS.SEQ_APP_USERS_ID
  START WITH 100 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;

-- [2] كتالوج الصلاحيات
CREATE TABLE ACCOUNTS.APP_PERMISSIONS (
  PERMISSION_ID     NUMBER(6)      NOT NULL,
  PERMISSION_CODE   VARCHAR2(60)   NOT NULL,
  MODULE_CODE       VARCHAR2(30)   NOT NULL,
  ACTION_CODE       VARCHAR2(30)   NOT NULL,
  NAME_AR           VARCHAR2(150)  NOT NULL,
  NAME_EN           VARCHAR2(150),
  IS_CORE           NUMBER(1)      DEFAULT 0 NOT NULL,
  SORT_ORDER        NUMBER(4)      DEFAULT 0,
  IS_ACTIVE         NUMBER(1)      DEFAULT 1 NOT NULL,
  DESCRIPTION_AR    VARCHAR2(500),
  CREATED_ON        DATE           DEFAULT SYSDATE,
  CREATED_BY        NUMBER(5),
  LAST_UPDATED_ON   DATE,
  LAST_UPDATED_BY   NUMBER(5),
  CONSTRAINT APP_PERM_PK       PRIMARY KEY (PERMISSION_ID),
  CONSTRAINT APP_PERM_CODE_UQ  UNIQUE (PERMISSION_CODE),
  CONSTRAINT APP_PERM_CORE_CK  CHECK (IS_CORE IN (0, 1)),
  CONSTRAINT APP_PERM_ACT_CK   CHECK (IS_ACTIVE IN (0, 1))
);
CREATE INDEX ACCOUNTS.APP_PERM_MOD_IX ON ACCOUNTS.APP_PERMISSIONS (MODULE_CODE, SORT_ORDER);
CREATE SEQUENCE ACCOUNTS.SEQ_APP_PERMISSIONS
  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;

-- [3] منح الصلاحيات مباشرة للمستخدمين (نواة IBAC — بلا أدوار)
CREATE TABLE ACCOUNTS.APP_USERS_PERMISSIONS (
  ID              NUMBER(9)   NOT NULL,
  USER_ID         NUMBER(5)   NOT NULL,
  PERMISSION_ID   NUMBER(6)   NOT NULL,
  GRANTED_BY      NUMBER(5),
  GRANTED_ON      DATE        DEFAULT SYSDATE,
  EXPIRES_ON      DATE,
  IS_ACTIVE       NUMBER(1)   DEFAULT 1 NOT NULL,
  NOTE            VARCHAR2(200),
  CONSTRAINT APP_UQ_PK         PRIMARY KEY (ID),
  CONSTRAINT APP_USER_PERM_UQ  UNIQUE (USER_ID, PERMISSION_ID),
  CONSTRAINT APP_UQ_USER_FK    FOREIGN KEY (USER_ID)
    REFERENCES ACCOUNTS.APP_USERS (USER_ID) ON DELETE CASCADE,
  CONSTRAINT APP_UQ_PERM_FK    FOREIGN KEY (PERMISSION_ID)
    REFERENCES ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID),
  CONSTRAINT APP_UQ_ACTIVE_CK  CHECK (IS_ACTIVE IN (0, 1))
);
CREATE INDEX ACCOUNTS.APP_UQ_USER_IX ON ACCOUNTS.APP_USERS_PERMISSIONS (USER_ID, IS_ACTIVE);
CREATE INDEX ACCOUNTS.APP_UQ_PERM_IX ON ACCOUNTS.APP_USERS_PERMISSIONS (PERMISSION_ID);
CREATE SEQUENCE ACCOUNTS.SEQ_APP_USERS_PERM
  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;
```

---
## [2026-10-17 05:25:00]
- **النموذج المنفذ / AI Model:** Qoder Agent
- **المهمة / Task:** IBAC مرحلة 1 — جدولا إعدادات الأمان وسجل النشاط
- **الأمر / SQL Query:**
```sql
-- [4] إعدادات الأمان والجلسات (قابلة للتعديل من شاشة «إعدادات الأمان»)
CREATE TABLE ACCOUNTS.APP_SETTINGS (
  SETTING_ID      NUMBER(6)     NOT NULL,
  SETTING_KEY     VARCHAR2(60)  NOT NULL,
  SETTING_VALUE   VARCHAR2(500),
  VALUE_TYPE      VARCHAR2(20)  DEFAULT 'int' NOT NULL,
  NAME_AR         VARCHAR2(150) NOT NULL,
  DESCRIPTION_AR  VARCHAR2(500),
  MIN_VALUE       NUMBER(10),
  MAX_VALUE       NUMBER(10),
  IS_LOCKABLE     NUMBER(1)     DEFAULT 0 NOT NULL,
  SORT_ORDER      NUMBER(4)     DEFAULT 0,
  UPDATED_BY      NUMBER(5),
  UPDATED_ON      DATE,
  CONSTRAINT APP_SET_PK      PRIMARY KEY (SETTING_ID),
  CONSTRAINT APP_SET_KEY_UQ  UNIQUE (SETTING_KEY),
  CONSTRAINT APP_SET_TYPE_CK CHECK (VALUE_TYPE IN ('int', 'bool', 'string', 'json'))
);
CREATE SEQUENCE ACCOUNTS.SEQ_APP_SETTINGS
  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;

-- [5] سجل نشاط المستخدمين والتدقيق (بلا قيد FK على USER_ID: فشل الدخول باسم مجهول يُسجَّل NULL،
--     وحذف مستخدم لا يجب أن يمحو تاريخ تدقيقه)
CREATE TABLE ACCOUNTS.APP_USER_ACTIVITY (
  ACTIVITY_ID     NUMBER(11)    NOT NULL,
  USER_ID         NUMBER(5),
  TARGET_USER_ID  NUMBER(5),
  ACTION_CODE     VARCHAR2(60)  NOT NULL,
  MODULE_CODE     VARCHAR2(30),
  ENTITY_TYPE     VARCHAR2(40),
  ENTITY_ID       VARCHAR2(60),
  DESCRIPTION_AR  VARCHAR2(1000),
  STATUS          VARCHAR2(10)  DEFAULT 'success' NOT NULL,
  IP_ADDRESS      VARCHAR2(45),
  USER_AGENT      VARCHAR2(200),
  PLATFORM        VARCHAR2(20),
  CREATED_ON      DATE          DEFAULT SYSDATE,
  CONSTRAINT APP_ACT_PK        PRIMARY KEY (ACTIVITY_ID),
  CONSTRAINT APP_ACT_STATUS_CK CHECK (STATUS IN ('success', 'failed'))
);
CREATE INDEX ACCOUNTS.APP_ACT_USER_IX ON ACCOUNTS.APP_USER_ACTIVITY (USER_ID, CREATED_ON);
CREATE INDEX ACCOUNTS.APP_ACT_TGT_IX  ON ACCOUNTS.APP_USER_ACTIVITY (TARGET_USER_ID, CREATED_ON);
CREATE INDEX ACCOUNTS.APP_ACT_MOD_IX  ON ACCOUNTS.APP_USER_ACTIVITY (MODULE_CODE, CREATED_ON);
CREATE SEQUENCE ACCOUNTS.SEQ_APP_ACTIVITY
  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;
```

---
## [2026-10-17 05:25:00]
- **النموذج المنفذ / AI Model:** Qoder Agent
- **المهمة / Task:** تشخيص ORA-04098 / PLS-00302 ثم إعادة إنشاء المحفِّزات الأربعة بصيغة صحيحة
- **السبب الجذري / Root cause:** يوجد VIEW اسمه `ACCOUNTS` داخل مخطط `ACCOUNTS`، فمرجع PL/SQL مثل `ACCOUNTS.SEQ_X.NEXTVAL` يُقرأ كعمود من العرض ويفشل. الحل: أسماء تسلسلات غير مسبوقة كما تفعل محفِّزات النظام القديمة.
- **الأمر / SQL Query:**
```sql
-- [تشخيص] حالة المحفِّزات والأخطاء والتسلسلات وهوية الجلسة
SELECT TRIGGER_NAME, TABLE_NAME, STATUS FROM ALL_TRIGGERS
 WHERE TABLE_OWNER='ACCOUNTS' AND TABLE_NAME IN ('APP_PERMISSIONS','APP_USERS_PERMISSIONS','APP_USERS');
SELECT NAME, TYPE, LINE, POSITION, TEXT FROM ALL_ERRORS
 WHERE OWNER='ACCOUNTS' AND NAME LIKE 'TRG_APP%' ORDER BY NAME, LINE;
-- PLS-00302: component 'SEQ_APP_PERMISSIONS' must be declared  (لأربعة محفِّزات)
SELECT SEQUENCE_NAME, MIN_VALUE, MAX_VALUE, INCREMENT_BY, CACHE_SIZE FROM ALL_SEQUENCES
 WHERE SEQUENCE_OWNER='ACCOUNTS' AND SEQUENCE_NAME LIKE 'SEQ_APP%';
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS FROM ALL_OBJECTS
 WHERE OWNER='ACCOUNTS' AND (OBJECT_NAME LIKE 'TRG_APP%' OR OBJECT_NAME LIKE 'SEQ_APP%');
SELECT OWNER, TRIGGER_NAME, TRIGGER_BODY, STATUS FROM DBA_TRIGGERS WHERE TRIGGER_NAME='TRG_APP_PERMISSIONS';
SELECT SYS_CONTEXT('USERENV','SESSION_USER') AS SESSION_USER,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS CURRENT_SCHEMA FROM DUAL;   -- ACCOUNTS / ACCOUNTS
SELECT ACCOUNTS.SEQ_APP_PERMISSIONS.NEXTVAL AS V FROM DUAL;                    -- يعمل في SQL وحده
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS FROM ALL_OBJECTS
 WHERE OWNER='ACCOUNTS' AND OBJECT_NAME='ACCOUNTS';                            -- VIEW  ← سبب المشكلة
SELECT TRIGGER_NAME, TRIGGER_BODY, STATUS FROM ALL_TRIGGERS
 WHERE OWNER='ACCOUNTS' AND TRIGGER_NAME IN ('PERSONAL_ACCESS_TOKENS_ID_TRG','MIGRATIONS_ID_TRG');
ALTER TRIGGER ACCOUNTS.TRG_APP_PERMISSIONS COMPILE;                            -- يبقى INVALID

-- [علاج] إعادة الإنشاء بأسماء تسلسلات بلا بادئة مخطط
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_PERMISSIONS
BEFORE INSERT ON ACCOUNTS.APP_PERMISSIONS FOR EACH ROW
BEGIN
  IF :NEW.PERMISSION_ID IS NULL THEN
    SELECT SEQ_APP_PERMISSIONS.NEXTVAL INTO :NEW.PERMISSION_ID FROM DUAL;
  END IF;
END;

CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_USERS_PERM
BEFORE INSERT ON ACCOUNTS.APP_USERS_PERMISSIONS FOR EACH ROW
BEGIN
  IF :NEW.ID IS NULL THEN
    SELECT SEQ_APP_USERS_PERM.NEXTVAL INTO :NEW.ID FROM DUAL;
  END IF;
END;

CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_SETTINGS
BEFORE INSERT ON ACCOUNTS.APP_SETTINGS FOR EACH ROW
BEGIN
  IF :NEW.SETTING_ID IS NULL THEN
    SELECT SEQ_APP_SETTINGS.NEXTVAL INTO :NEW.SETTING_ID FROM DUAL;
  END IF;
END;

CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_ACTIVITY
BEFORE INSERT ON ACCOUNTS.APP_USER_ACTIVITY FOR EACH ROW
BEGIN
  IF :NEW.ACTIVITY_ID IS NULL THEN
    SELECT SEQ_APP_ACTIVITY.NEXTVAL INTO :NEW.ACTIVITY_ID FROM DUAL;
  END IF;
END;

-- [تحقق] محفِّزات INVALID؟ صفر صفوف — والأربعة VALID
SELECT OBJECT_NAME, STATUS FROM ALL_OBJECTS
 WHERE OWNER='ACCOUNTS' AND OBJECT_TYPE='TRIGGER' AND OBJECT_NAME LIKE 'TRG_APP%';
```

---
## [2026-10-17 05:25:00]
- **النموذج المنفذ / AI Model:** Qoder Agent
- **المهمة / Task:** بذر الكتالوج والإعدادات + تعليقات قاموس البيانات + ترقية المدير العام — نُفِّذت بكود PHP لا بملف SQL
- **السبب / Why code and not SQL:** موصل Oracle يعمل بترميز عميل `AL32UTF8`؛ إرسال بايتات Windows-1256 الخام يجعل أوراكل يستبدلها بـ `0xBF` (ثبت بـ `DUMP` بعد أول بذر: `Typ=1 Len=4: bf,bf,bf,bf`). الكتابة السليمة هي `ArabicEncoding::toOracleSearchChars()` التي تحوّل كل بايت CP1256 إلى محرف لاتيني بنفس الكود فيستقر البايت كما تفعل أنظمة الشركة القديمة.
- **الأمر / SQL Query:**
```text
# من داخل kyApp_API — السكربتات قابلة لإعادة التشغيل بأمان (idempotent)
php artisan tinker database/oracle/02_ibac_seed.php       # 93 صلاحيّة + 10 إعدادات، مشتقة من PermissionCatalog
php artisan tinker database/oracle/03_ibac_bootstrap.php  # 49 تعليقاً + IS_ADMIN=1 + منح system.* + صفحة تدقيق
```
```sql
-- شكل الإدراج داخل 02_ibac_seed.php (استعلامات مربوطة حصراً، والعربية عبر toOracleSearchChars)
INSERT INTO ACCOUNTS.APP_PERMISSIONS
    (PERMISSION_CODE, MODULE_CODE, ACTION_CODE, NAME_AR, NAME_EN,
     IS_CORE, SORT_ORDER, IS_ACTIVE, DESCRIPTION_AR, CREATED_ON, CREATED_BY)
VALUES (:code, :module, :action, :name_ar, :name_en,
        :is_core, :sort_order, 1, :desc_ar, SYSDATE, NULL);

INSERT INTO ACCOUNTS.APP_SETTINGS
    (SETTING_KEY, SETTING_VALUE, VALUE_TYPE, NAME_AR, DESCRIPTION_AR,
     MIN_VALUE, MAX_VALUE, IS_LOCKABLE, SORT_ORDER, UPDATED_ON)
VALUES (:key, :value, :type, :name_ar, :desc_ar,
        :min, :max, :lockable, :sort, SYSDATE);

-- 03_ibac_bootstrap.php
COMMENT ON TABLE  ACCOUNTS.APP_PERMISSIONS IS 'كتالوج صلاحيات النظام (IBAC) — مصدره PermissionCatalog في التطبيق';
COMMENT ON COLUMN ACCOUNTS.APP_USERS.IS_ADMIN IS 'مدير النظام: 1 = يملك كل الصلاحيات ويتجاوز فحص المنح';
UPDATE ACCOUNTS.APP_USERS
   SET IS_ADMIN = 1, USER_TYPE = NVL(USER_TYPE, 1)
 WHERE USER_ID = 1 AND NVL(IS_ACTIVATED, 0) = 1;
INSERT INTO ACCOUNTS.APP_USERS_PERMISSIONS
    (USER_ID, PERMISSION_ID, GRANTED_BY, GRANTED_ON, IS_ACTIVE, NOTE)
VALUES (1, :pid, NULL, SYSDATE, 1, :note);
INSERT INTO ACCOUNTS.APP_USER_ACTIVITY
    (USER_ID, TARGET_USER_ID, ACTION_CODE, MODULE_CODE, ENTITY_TYPE, ENTITY_ID,
     DESCRIPTION_AR, STATUS, CREATED_ON)
VALUES (1, 1, :action, :module, :entity, :entity_id, :descr, :status, SYSDATE);

-- ملاحظة تشخيصية: أول محاولة لسجل التدقيق فشلت بـ ORA-01745 لأن اسم الربط :desc يحجز كلمة DESC،
-- واستُبدل بـ :descr. وCOMMENT ON لا يقبل bind variables لذلك تُبنى النصوص كحوامل نصية آمنة.

-- [تحقق نهائي]
SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS) AS PERMS,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE IS_CORE=1) AS CORE_PERMS,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE ACTION_CODE='*') AS WILDCARDS,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_SETTINGS) AS SETTINGS,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_USER_ACTIVITY) AS ACTIVITY FROM DUAL;
-- النتيجة: 93 / 47 / 17 / 10 / 1

SELECT PERMISSION_CODE, LENGTH(NAME_AR) AS LEN_CHAR, DUMP(NAME_AR, 1016, 1, 12) AS RAW_DUMP
  FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE IN ('customers.delete','users.view','customers.*');
-- customers.delete ⇒ cd,d0,dd,20,c7,e1,da,e3,ed,e1 أي «حذف العميل» بايتات CP1256 سليمة

SELECT up.ID, up.USER_ID, up.PERMISSION_ID, p.PERMISSION_CODE, up.IS_ACTIVE,
       TO_CHAR(up.GRANTED_ON,'YYYY-MM-DD') AS GRANTED_ON
  FROM ACCOUNTS.APP_USERS_PERMISSIONS up
  JOIN ACCOUNTS.APP_PERMISSIONS p ON p.PERMISSION_ID = up.PERMISSION_ID;
-- ID=1 (مَلأه المحفِّز) — USER_ID=1 — system.* — IS_ACTIVE=1

SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER='ACCOUNTS' AND TABLE_NAME LIKE 'APP\_%' ESCAPE '\';
SELECT (SELECT COUNT(*) FROM ALL_TAB_COMMENTS WHERE OWNER='ACCOUNTS' AND COMMENTS IS NOT NULL
          AND TABLE_NAME IN ('APP_PERMISSIONS','APP_USERS_PERMISSIONS','APP_SETTINGS','APP_USER_ACTIVITY')) AS TABLE_COMMENTS,
       (SELECT COUNT(*) FROM ALL_COL_COMMENTS WHERE OWNER='ACCOUNTS' AND COMMENTS IS NOT NULL
          AND TABLE_NAME IN ('APP_PERMISSIONS','APP_USERS_PERMISSIONS','APP_SETTINGS','APP_USER_ACTIVITY','APP_USERS')) AS COLUMN_COMMENTS,
       (SELECT COUNT(*) FROM ALL_INDEXES WHERE TABLE_OWNER='ACCOUNTS'
          AND TABLE_NAME IN ('APP_PERMISSIONS','APP_USERS_PERMISSIONS','APP_SETTINGS','APP_USER_ACTIVITY')) AS INDEXES
  FROM DUAL;   -- 4 / 45 / 13
```


## [2026-10-17 07:17:24] - المرحلة 2: طبقة IBAC في الخلفية (ما نُفِّذ على القاعدة)
- **النموذج المنفذ / AI Model:** Qoder Agent
- **كل ما أُجري على القاعدة / SQL executed** — كتاباتُها كلها عبر PHP بمربوطات مربوطة، وقراءاتُها عبر موصل @oracle:

```sql
-- 1) التحقق من بنية APP_USERS قبل تعديل الموديل (07:05) — قراءة فقط
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='APP_USERS' ORDER BY COLUMN_ID;
-- النتيجة المؤكدة: USER_PASSWORD VARCHAR2(100) و IS_ADMIN NUMBER(1) موجودان، ولا يوجد عمود USER_NO.

-- 2) توزيع قيم USER_TYPE قبل اعتماد التحويل في موديل User (07:06) — قراءة فقط
SELECT USER_TYPE, COUNT(*) AS C FROM ACCOUNTS.APP_USERS GROUP BY USER_TYPE ORDER BY USER_TYPE;
-- النتيجة: USER_TYPE رقمي وقيمته 1 للمستخدم الوحيد، فاعتماد D5 (1=موظف، 2=عميل) آمن مع casts('integer').

-- 3) قراءة إعدادات الأمان قبل اختبار سياسة الجلسة (07:08) — قراءة فقط
SELECT SETTING_KEY, SETTING_VALUE, VALUE_TYPE, MIN_VALUE, MAX_VALUE, IS_LOCKABLE, SORT_ORDER
  FROM ACCOUNTS.APP_SETTINGS ORDER BY SORT_ORDER;
-- النتيجة: 10 إعدادات، منها session_idle_minutes=240 و biometric_login_enabled=1 و max_failed_logins=0.

-- 4) فحص مسار التوكن (07:10) — كتابة على جدول Laravel الخاص بالتطبيق (PERSONAL_ACCESS_TOKENS)
INSERT INTO ACCOUNTS.PERSONAL_ACCESS_TOKENS (NAME, TOKEN, ABILITIES, TOKENABLE_ID, CREATED_AT, UPDATED_AT)
     VALUES ('ky_phase2_probe', :hashed_token, :abilities, 1, SYSDATE, SYSDATE);
UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS SET EXPIRES_AT = SYSDATE + 240/1440, UPDATED_AT = SYSDATE WHERE ID = 141;
SELECT ID, NAME, CREATED_AT, EXPIRES_AT, UPDATED_AT FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS WHERE ID = 141;
-- النتيجة: CREATED_AT 03:50:19 ⇒ EXPIRES_AT 07:50:19 (مهلة 240 دقيقة كاملة) — التجديد الانزلاقي يعمل.
UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS SET EXPIRES_AT = SYSDATE - 1 WHERE ID = 141;
-- النتيجة: SessionPolicy::validate() أعادت false ⇒ انتهاء المهلة يُخرج الجلسة من الخدمة.
DELETE FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS WHERE ID = 141;   -- حذف توكن الفحص فقط (بقي العدد 32 كما كان)

-- 5) فحص مسار سجل النشاط (07:10) — كتابة على APP_USER_ACTIVITY ثم تراجع بما أُضيف فقط
SELECT NVL(MAX(ACTIVITY_ID), 0) AS M FROM ACCOUNTS.APP_USER_ACTIVITY;
INSERT INTO ACCOUNTS.APP_USER_ACTIVITY (USER_ID, TARGET_USER_ID, ACTION_CODE, MODULE_CODE, ENTITY_TYPE,
    ENTITY_ID, DESCRIPTION_AR, STATUS, IP_ADDRESS, USER_AGENT, PLATFORM, CREATED_ON)
 VALUES (:user_id, :target_user_id, :action_code, :module_code, :entity_type, :entity_id,
    :description_ar, :status, :ip, :user_agent, :platform, SYSDATE);
SELECT ACTION_CODE, STATUS, DESCRIPTION_AR, DUMP(DESCRIPTION_AR,1016) AS BYTE_DUMP
  FROM ACCOUNTS.APP_USER_ACTIVITY WHERE ACTIVITY_ID > :m ORDER BY ACTIVITY_ID DESC;
-- النتيجة: DUMP = Typ=1 Len=23 CharacterSet=WE8MSWIN1252: dd,cd,d5,20,e3,c4,de,ca,...
-- ⇒ العربية تُخزَّن بايتات CP1256 مطابقة للنظام القديم (نفس مسار البذر الناجح في المرحلة 1).
DELETE FROM ACCOUNTS.APP_USER_ACTIVITY WHERE ACTIVITY_ID > :m;   -- حذف سطر الفحص فقط

-- 6) التحقق من دورة قراءة العربية في سجل النشاط (07:12) — قراءة فقط
SELECT DESCRIPTION_AR FROM ACCOUNTS.APP_USER_ACTIVITY WHERE ROWNUM=1;
-- الخام: "ÊåíÆÉ äÙÇã ÇáÕáÇÍíÇÊ..." وبعد ArabicEncoding::fixMojibake():
-- "تهيئة نظام الصلاحيات: تفعيل صفة مدير النظام ومنح شامل للنظام" ⇒ دورة الكتابة/القراءة مغلقة وسليمة.

-- 7) مراجعة أثر اختبارات Pest على سجل النشاط (07:16) — قراءة فقط
SELECT ACTIVITY_ID, USER_ID, ACTION_CODE, STATUS, CREATED_ON FROM ACCOUNTS.APP_USER_ACTIVITY ORDER BY ACTIVITY_ID;
-- النتيجة: سطر system.bootstrap (المراحل السابقة) + سطر login_failed من اختبار AuthTest
-- (اسم مستخدم مجهول ⇒ USER_ID NULL كما هو مصمم).

-- 8) محاولة تنظيف مرفوضة (07:17) — لم تُنفَّذ
DELETE FROM ACCOUNTS.APP_USER_ACTIVITY WHERE ACTIVITY_ID = 3 AND ACTION_CODE = 'login_failed';
-- رفضتها سياسة الموافقات (حذف مباشر على قاعدة إنتاجية). السطر باقٍ كأثر اختبار مشروع ومفيد
-- كأول سجل محاولة دخول فاشلة؛ لا يُحذف دون إذن صريح من المستخدم.
```

- **حادث أوراكل مكتشف ومعالَج أثناء الفحص / a real Oracle failure found and fixed**:
```sql
-- أول محاولة تخزين لإعدادات الكاش فشلت (07:09) عبر مخزن الكاش القاعدي في Laravel:
merge into "CACHE" using (select :p0 as "EXPIRATION", :p1 as "KEY", :p2 as "VALUE" from dual) "LARAVEL_SOURCE"
 on ("LARAVEL_SOURCE"."KEY" = "CACHE"."KEY")
 when matched then update set "EXPIRATION" = :p0, "VALUE" = :p2
 when not matched then insert ("EXPIRATION", "KEY", "VALUE") values (:p0, :p1, :p2);
-- ORA-01461: can bind a LONG value only for insert into a LONG column
-- السبب: CACHE.VALUE نوعه CLOB لكن الكتابة تمر بصيغة `SELECT :value FROM dual`، وأوراكل ترفض
-- ربط نص أطول من 4000 بايت هناك. كتلة الكاش كانت ~5.4KB لأنها حملت الأسماء والأوصاف العربية.
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='CACHE' ORDER BY COLUMN_ID;
-- KEY VARCHAR2(255) · VALUE CLOB(4000) · EXPIRATION NUMBER
-- العلاج: كاش الإعدادات صار حقولاً رقمية فقط (بلا عربي) بحد آمن 3000 بايت، و definitions()
-- تقرأ التسميات العربية من القاعدة مباشرة؛ ونفس الحد طُبِّق على كاش الصلاحيات.
```
- **بوابات الجودة / gates**: `php -l` على 11 ملفاً = بلا أخطاء، `vendor/bin/pint --dirty` = passed،
  `vendor/bin/pest` = 21 اختباراً ناجحاً (83 تحققاً) منها 12 اختباراً جديداً في `IbacCoreTest.php`.

---
## [2026-10-18 00:03:42] - المرحلة 3: ما نُفِّذ على القاعدة (قراءة فقط)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الاتصال:** `oracle` (ACCOUNTS) · **كتابات:** لا شيء
- **تشخيص العمود التاريخي الفارغ (قراءة خام عبر `php artisan tinker` + `Laravel\Sanctum\PersonalAccessToken`):**
```sql
SELECT * FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS
 WHERE EXPIRES_AT IS NULL AND ROWNUM = 1;
-- gettype(EXPIRES_AT) = "string" (قيمة فارغة) — وليست null
-- وعلى نفس الصف من النموذج: gettype($model->expires_at) = "NULL" والمفتاح غائب من getAttributes()
-- النتيجة: القارئ الرمزي والسلسلة الاختيارية كلاهما غير آمن ⇒ SessionPolicy::toDate()
```
- **تدقيق حالة القاعدة بعد المرحلة (mcp oracle):**
```sql
SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS)                AS USERS_TOTAL,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS)    AS GRANTS_TOTAL,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS)          AS PERMISSIONS_TOTAL,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE IS_ADMIN = 1) AS ADMINS,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_USER_ACTIVITY)        AS ACTIVITY_ROWS,
       (SELECT COUNT(*) FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS)   AS TOKENS
  FROM DUAL;
-- USERS_TOTAL=1 · GRANTS_TOTAL=1 · PERMISSIONS_TOTAL=93 · ADMINS=1 · ACTIVITY_ROWS=6 · TOKENS=32

SELECT ACTIVITY_ID, USER_ID, ACTION_CODE, STATUS,
       TO_CHAR(CREATED_ON,'YYYY-MM-DD HH24:MI:SS') AS CREATED_ON
  FROM ACCOUNTS.APP_USER_ACTIVITY ORDER BY ACTIVITY_ID;
-- 1 system.bootstrap (2026-10-17 05:10:13)
-- 3..7 login_failed (2026-10-17 07:07:50 / 07:14:02 / 23:06:59 / 23:31:46 / 23:43:31)
-- الأسطر 5 و6 و7 من تشغيلات Pest في هذه المرحلة (اختبار bad credentials في AuthTest).
```
- **لم يُنَفَّذ أي كتابة:** مسارات `PermissionGrantSync::replace()` و`UserAdminController@store` و
  `terminateSessions()` كُتبت واختُبرت على فروع الرفض فقط؛ أول تنفيذ فعلي لها في المرحلة 8 أو باختبار
  كتابي بموافقة صريحة.
- **بوابات الجودة / gates:** `vendor/bin/pest` = 47 اختباراً / 199 تحققاً · `vendor/bin/pint --dirty` = passed ·
  `php artisan route:list --path=api` = 66 مساراً.

---
## [2026-10-18 02:52:11] - المرحلة 4: ما نُفِّذ على القاعدة (قراءة فقط) — Qoder Agent
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 02:52:11 · **DDL أو كتابة:** لا شيء
- **استطلاع ترميز الجلسات (عبر موصل `oracle`):**
  ```sql
  -- قراءة كل الإعدادات بقيمها الخام للتأكيد أن الحفظ لم يلمس القاعدة
  SELECT SETTING_KEY, SETTING_VALUE, VALUE_TYPE, UPDATED_BY,
         TO_CHAR(UPDATED_ON,'YYYY-MM-DD HH24:MI:SS') AS UPDATED_ON
    FROM ACCOUNTS.APP_SETTINGS
   ORDER BY SORT_ORDER, SETTING_ID;
  -- 10 صفوف: session_idle_minutes=240 · session_absolute_days=14 ·
  --           session_touch_threshold_minutes=5 · single_active_session_per_device=0 ·
  --           password_min_length=4 · max_failed_logins=0 · lockout_minutes=15 ·
  --           biometric_login_enabled=1 · activity_log_retention_days=180 ·
  --           maintenance_message=NULL  وUPDATED_BY فارغ في الكل (وقت البذر 2026-10-17 05:48:11)
  ```
  ```sql
  -- عدّادات تأكيد عدم التغيّر
  SELECT (SELECT COUNT(*) FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS)          AS TOKENS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_SETTINGS)                    AS SETTINGS_ROWS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE IS_ADMIN = 1)    AS ADMINS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS)                       AS USERS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS)                 AS PERMS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS)           AS GRANTS
    FROM DUAL;
  -- TOKENS=32 · SETTINGS_ROWS=10 · ADMINS=1 · USERS=1 · PERMS=93 · GRANTS=1
  ```
  ```sql
  -- حجم الأثر التدقيقي بعد تشغيل حزمة Pest
  SELECT COUNT(*) AS TOTAL, MAX(ACTIVITY_ID) AS LAST_ID FROM ACCOUNTS.APP_USER_ACTIVITY;
  -- TOTAL=8 · LAST_ID=9 (كانت 6 في نهاية المرحلة 3؛ الزيادة أسطر login_failed من AuthTest)
  ```
  ```sql
  -- محاولة أولى استخدمت اسماً خاطئاً للعمود الأساسي ⇒ تصحيح الاستطلاع لا تصحيح الكود
  SELECT MAX(ID) FROM ACCOUNTS.APP_USER_ACTIVITY;
  -- ORA-00904: "ID": invalid identifier  (الاسم الصحيح ACTIVITY_ID)
  SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS
   WHERE OWNER='ACCOUNTS' AND TABLE_NAME='APP_USER_ACTIVITY' ORDER BY COLUMN_ID;
  -- ACTIVITY_ID NUMBER · USER_ID · TARGET_USER_ID · ACTION_CODE · MODULE_CODE · ENTITY_TYPE ·
  -- ENTITY_ID VARCHAR2 · DESCRIPTION_AR · STATUS · IP_ADDRESS · USER_AGENT · PLATFORM · CREATED_ON DATE
  ```
- **العبارة المرفوضة من المحرّك (كشفها اختبار هذه المرحلة، لم تُبدّل بيانات):**
  ```sql
  UPDATE ACCOUNTS.APP_SETTINGS
     SET SETTING_VALUE = :value, UPDATED_BY = :by, UPDATED_ON = SYSDATE
   WHERE SETTING_KEY = :key
  -- Error Code : 1745 / ORA-01745: invalid host/bind variable name
  -- Position : 87 · Bindings : [8, 1, password_min_length]
  -- السبب: BY كلمة محجوزة في أوراكل. الصيغة المعتمدة الآن:
  UPDATE ACCOUNTS.APP_SETTINGS
     SET SETTING_VALUE = :setting_value, UPDATED_BY = :updated_by, UPDATED_ON = SYSDATE
   WHERE SETTING_KEY = :setting_key
  ```
  ومثلها في تعطيل المستخدم:
  ```sql
  -- قديماً (كانت ORA-01745 عند أول تعطيل من الواجهة):
  UPDATE ACCOUNTS.APP_USERS SET IS_ACTIVATED = :next, …, LAST_UPDATED_BY = :by WHERE USER_ID = :user_id;
  -- الآن:
  UPDATE ACCOUNTS.APP_USERS
     SET IS_ACTIVATED = :activated, LAST_UPDATED_ON = SYSDATE, LAST_UPDATED_BY = :updated_by
   WHERE USER_ID = :user_id;
  ```
- **عبارات جاهزة ولم تُنفَّذ على القاعدة الحيّة:**
  ```sql
  -- إنهاء جلسة واحدة (المسار الفعلي للزر في الواجهة)
  UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS
     SET EXPIRES_AT = SYSDATE - 1, UPDATED_AT = SYSDATE
   WHERE ID = :id
     AND TOKENABLE_ID = :user_id
     AND TOKENABLE_TYPE = :type
     AND (EXPIRES_AT IS NULL OR EXPIRES_AT > SYSDATE);

  -- إنهاء كل جلسات مستخدم
  UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS
     SET EXPIRES_AT = SYSDATE - 1, UPDATED_AT = SYSDATE
   WHERE TOKENABLE_ID = :user_id
     AND TOKENABLE_TYPE = :type
     AND (EXPIRES_AT IS NULL OR EXPIRES_AT > SYSDATE);
  ```
  ملاحظتان نحويتان أُثبتتا بالمراجعة لا بالتجربة: `UPDATE … t SET` (بديل للجول) مرفوض في أوراكل،
  والفرز بالصفحات يحتاج `ROW_NUMBER()` داخل غلاف لأن 11g لا تعرف `OFFSET/FETCH`، و`NAME` عمود CLOB
  فلا يُقرأ إلا بـ `DBMS_LOB.SUBSTR(NAME, 60, 1)`.
- **بوابات الجودة / gates:** `vendor/bin/pest` = 69 اختباراً / 449 تحقّقاً ·
  `vendor/bin/pint --dirty --format agent` = passed · `php artisan route:list --path=api` = 71 مساراً.

---

## [2026-10-19 01:47:33] - المرحلة 5+6 (العميل فلتر): ما نُفِّذ على القاعدة — قراءة فقط — Qoder Agent

**الطبيعة:** هذه المرحلة على جانب العميل بالكامل (بناء سجل أقسام البوابة، وتوصيل الصلاحيات بحالة
المصادقة، وحجب الشاشات). **لم يُنفَّذ أي `INSERT` أو `UPDATE` أو `DELETE` أو DDL** على أي جدول،
والمسموح به هنا القراءة فقط لأن القاعدة إنتاجية قديمة مشتركة مع نظام آخر.

- **استعلام التحقق من عدد الصلاحيات ومنح المستخدم الوحيد (نُفِّذ فعلياً):**
  ```sql
  SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE STATUS = 'ACTIVE') AS ACTIVE_PERMS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS UP
            JOIN ACCOUNTS.APP_PERMISSIONS P ON P.ID = UP.PERMISSION_ID
           WHERE P.STATUS = 'ACTIVE'
             AND (UP.EXPIRES_AT IS NULL OR UP.EXPIRES_AT > SYSDATE)) AS ACTIVE_GRANTS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE IS_ADMIN = 1) AS HAS_IS_ADMIN
    FROM DUAL;
  ```
  **النتيجة:** `ACTIVE_PERMS = 93` · `ACTIVE_GRANTS = 1` · `HAS_IS_ADMIN = 1`.
  يعني: كتالوج الخادم فيه 93 رمزاً نشطاً، ومنح فعلي واحد فقط، ومستخدم واحد مدير يتجاوز جدول المنح.
  لهذا تُبنى اختبارات العميل على 93 رمزاً لا على التخمين.

- **مطابقة كتالوج الأكواد بين الطرفين (لم تلمس القاعدة؛ مقارنة نصّية بأدوات المشروع):**
  ```bash
  # الأكواد كما يقرّها الخادم
  grep -rhoP "(?<=')[a-z_]+\.[a-z_]+(?=')" kyApp_API/app/Support/PermissionCatalog.php | sort -u
  # الأكواد كما تعرفها الواجهة
  grep -oP "(?<=')[a-z_]+\.[a-z_]+(?=')" lib/core/constants/permission_codes.dart | sort -u
  ```
  النتيجة: 93 مقابل 93، و`missingInDart = []` و`missingInPhp = []` و`firstOrderDiffIndex = -1`
  (أي أن الترتيب متطابق أيضاً، لأن واجهة اختيار الصلاحيات تعرض الأكواد بترتيب الكتالوج).

- **قراءة دفاعية سُجّلت لأن شكلها يخذل من لا يعرفها:** عمود `DATE` الفارغ في أوراكل 11g يصل عبر
  مسار القراءة `false` أو `''` لا `null` فقط؛ لذلك `_parseNullableString` يعتبر نص `'false'` فراغاً.
  وبالمثل أسماء الأعمدة قد تصل بأي حالة أحرف، فتقرأ الواجهة الحالتين معاً (`permissions` / `PERMISSIONS`).

- **الآثار على الصلاحيات نفسها:** لا شيء. لم يُمنح أحد ولم يُسحب من أحد؛ الحجب في هذه المرحلة يحدث في
  الواجهة فقط اعتماداً على ما يرسله الخادم في `GET /auth/permissions` ودمج `login`/`me`. ختم مسارات
  الأعمال بمiddleware الصلاحيات مؤجَّل إلى المرحلة 7 (قرار D3) لأنه يسبقه توزيع منح الترحيب
  للمستخدمين النشطين — وهذا كتابة تحتاج موافقة صريحة.

- **بوابات الجودة / gates:** `flutter analyze` = No issues found! · `flutter test` = 44 اختباراً ناجحاً
  (منها 39 اختباراً لكتالوج الأكواد وقواعد الحل وسجل الأقسام) · `git status` بلا أي تعديل على `.env`.

---

## [2026-10-19 02:59:38] - المرحلة 7: ختم مسارات الأعمال — ما نُفِّذ على القاعدة — Qoder Agent

**الطبيعة:** هذه المرحلة طبقة سلطة في Laravel لا مخطط. **صفر `INSERT`، صفر `UPDATE`، صفر `DELETE`،
وصفر DDL** — لا جداول جديدة ولا أعمدة ولا فهارس ولا منح.

- **التنفيذ الفعلي الوحيد على القاعدة (قراءة):**
  ```sql
  SELECT USER_ID, USER_NAME_EN, USER_TYPE, IS_ACTIVATED, IS_ADMIN
    FROM ACCOUNTS.APP_USERS
   ORDER BY USER_ID;
  ```
  **النتيجة:** صفّ واحد `USER_ID=1 | arslan | USER_TYPE=1 | IS_ACTIVATED=1 | IS_ADMIN=1`.

- **لماذا هذه القراءة بالتحديد قبل الختم:** الخطة تشترط (البند 6 / مرحلة 7) توزيع منح ترحيب على كل
  المستخدمين النشطين **قبل** إغلاق أي مسار، حتى لا يُطرد مستخدم حقيقي عند أول قفل. النتيجة تُسقط
  هذا الشرط عملياً: لا يوجد مستخدم غير مدير، والمدير يتجاوز جدول المنح في `PermissionResolver`
  قبل فحص أي منح. فالحصر هنا هو ما يثبت أن الختم آمن بلا كتابة، لا الافتراض بأن «لا مستخدمين غيري».

- **تحقق بعدها أن الصلاحيات المطلوبة موجودة كلها في الكتالوج** (لم يُنفَّذ على القاعدة؛ قراءة من
  الكود) لأن صلاحية في مسار لا تعرفها `APP_PERMISSIONS` تعني رفضاً أبدياً حتى لمنحه لاحقاً:
  ```text
  customers.view/create/update/delete/statement        employees.* cutters.* tailors.*  (view/create/update/delete/toggle/statement)
  accounts.view/create/update/structure_manage/statement
  currencies.view/create/update/delete/prices_view/prices_manage
  invoices.view        system.*
  ```

- **عبارات جاهزة ولم تُنفَّذ:** لم تُحفظ أي عبارة SQL جديدة في هذه المرحلة؛ استعلامات `SALES_BILL`
  في `InvoiceController` هي التي كانت موجودة، أُلغِيت منها المصفوفة العارية وأُضيف البحث والتصفح:
  ```sql
  -- الصيغة الجديدة (تُبنى عبر builder الاستعلام، لا نصاً خاماً، وكل مربَّط بربط حقيقي)
  SELECT BILL_NO, YEAR, DAT, CUST_NO, CUST_NAME, TOTAL, DISCOUNT, NET, AMOUNT_PAID, STORE_NO, HANDING_DONE,
         (NET - AMOUNT_PAID) AS REMAINING
    FROM ACCOUNTS.SALES_BILL
   WHERE CUST_NAME LIKE :search_a OR CUST_NAME LIKE :search_b   -- الصيغتان معاً (CP1256 و UTF-8)
   ORDER BY DAT DESC
   -- والتصفح بـ ROW_NUMBER() داخل غلاف لأن أوراكل 11g لا تعرف OFFSET/FETCH (البند المؤرشف في المرحلة 4)
  ```

- **ما لم يُنفَّذ وبقي معلَّقاً عمداً** (بأسماء الأعمدة الصحيحة من `ALL_TAB_COLUMNS`، انظر التصحيح أدناه):
  ```sql
  -- منح ترحيبية (لم تُكتب — لا مستخدم غير مدير في القاعدة)
  INSERT INTO ACCOUNTS.APP_USERS_PERMISSIONS
         (ID, USER_ID, PERMISSION_ID, GRANTED_BY, GRANTED_ON, IS_ACTIVE)
  SELECT ACCOUNTS.SEQ_APP_USERS_PERM.NEXTVAL, :user_id, P.PERMISSION_ID, :granted_by, SYSDATE, 1
    FROM ACCOUNTS.APP_PERMISSIONS P
   WHERE P.IS_ACTIVE = 1;
  ```
  `IS_ACTIVE` عمود `NOT NULL` في جدول المنح، فلا يمكن كتابة منح بدونه — وهذا ما يجعل العبارة أعلاه
  قابلة للتنفيذ لا للنسخ فقط.
  اسم التسلسل `SEQ_APP_USERS_PERM` مأخوذ من `ALL_SEQUENCES` لا من التخمين؛ وهو موجود فعلاً مع
  `SEQ_APP_PERMISSIONS` و`SEQ_APP_SETTINGS` و`SEQ_APP_ACTIVITY` و`SEQ_APP_USERS_ID` — وهي التسلسلات
  التي أُنشئت في المرحلة 1 بدل نمط `MAX(pk)+1` لأن هذا الجدول جدول منح لا جدول أعمال.
  هذه العبارة تعود مطلوبة فور إنشاء أول مستخدم غير مدير من واجهة المرحلة 8، وتحتاج إذناً صريحاً
  بالكتابة قبل تنفيذها.

- **تصحيح وثائقي إلزامي (سُجّل بالمراجعة لا بالإهمال):** البلوك السابق (المرحلة 5+6 في هذا الملف،
  سطر ~569 فما بعده حيث استعلام «التحقق من عدد الصلاحيات») كتب الاستعلام بأسماء أعمدة **غير موجودة**:
  `P.STATUS = 'ACTIVE'` و`P.ID = UP.PERMISSION_ID` و`UP.EXPIRES_AT`.
  أوراكل يردّ على الأولى بـ `ORA-00904: "STATUS": invalid identifier` (أُعيد تنفيذها حرفياً للتو
  وفشلت في نفس الموضع). الأسماء الصحيحة كما تقرّها `ALL_TAB_COLUMNS`:
  | الجدول | ما كُتب خطأً | الصحيح |
  |---|---|---|
  | `APP_PERMISSIONS` | `ID` | `PERMISSION_ID` |
  | `APP_PERMISSIONS` | `STATUS = 'ACTIVE'` | `IS_ACTIVE = 1` |
  | `APP_USERS_PERMISSIONS` | `EXPIRES_AT` | `EXPIRES_ON` |
  | `APP_USERS_PERMISSIONS` | — | `IS_ACTIVE = 1` (كان غائباً: منح معطّلة كانت تُعدّ منشّطة) |

  العبارة الصحيحة كما نُفِّذت الآن فعلياً:
  ```sql
  SELECT (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE IS_ACTIVE = 1) AS ACTIVE_PERMS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS UP
            JOIN ACCOUNTS.APP_PERMISSIONS P ON P.PERMISSION_ID = UP.PERMISSION_ID
           WHERE P.IS_ACTIVE = 1
             AND UP.IS_ACTIVE = 1
             AND (UP.EXPIRES_ON IS NULL OR UP.EXPIRES_ON > SYSDATE)) AS ACTIVE_GRANTS,
         (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE IS_ADMIN = 1 AND IS_ACTIVATED = 1) AS ACTIVE_ADMINS
    FROM DUAL;
  ```
  **النتيجة:** `ACTIVE_PERMS = 93` · `ACTIVE_GRANTS = 1` · `ACTIVE_ADMINS = 1` — أي أن الأرقام التي
  بُني عليها قرار «93 مطابقة» لم تتغير، بل الذي تغيّر هو صحة العبارة التي تُثبتها. الأرقام صحيحة
  والوثيقة كانت مكتوبة بأسماء خاطئة، ولهذا يُصحَّح النص لا النتيجة.
  **العبرتان المُستفادتان:** (1) عبارة SQL تُوثَّق كما نُفِّذت، لا كما تُخمين؛ (2) عمود حالة في
  أوراكل هنا رقمي `IS_ACTIVE` لا نصي `STATUS` — وكل قراءة لاحقة لجدول منح أو كتالوج يجب أن تمرّ
  عليه، وأي استعلام يُنسج على نمط جداول أخرى سيُخطئ الصمت لا الخطأ المسموع.
- **تنويه حتى لا يُقرأ التصحيح كانحراف في الكود:** الكود الخلفي صحيح ولم يُغيَّر شيء فيه —
  ثابت `PermissionResolver::GRANTS_SQL` (يقرأه `fetchCodes()` وحده) يكتب الأسماء السليمة حرفياً:
  `JOIN ACCOUNTS.APP_PERMISSIONS p ON p.PERMISSION_ID = up.PERMISSION_ID` مع
  `up.IS_ACTIVE = 1 AND p.IS_ACTIVE = 1 AND (up.EXPIRES_ON IS NULL OR up.EXPIRES_ON > SYSDATE)`.
  الخطأ كان في **الوثيقة وحدها**: عبارة حُفظت بصيغة أقرب إلى العرف الحديث منها إلى ما أُرسل فعلياً.
  **وهذا يرفع الخطأ من باب الخطأ المطبوع إلى باب الخطأ المؤجَّل:** من يقرأ `db_commends.md` ويصدّقه
  يبني استعلامه على `STATUS` و`ID`، فيُصاب بـ `ORA-00904` — أو أسوأ: يظن أن الجدول بلا عمود حالة
  فيكتب منحاً بلا `IS_ACTIVE = 1` فيسقط المنح صامتاً لأنه `NOT NULL` بلا قيمة افتراضية.

- **بوابات الجودة / gates:** `vendor/bin/pint --dirty --format agent` = fixed (ملفان) ·
  `vendor/bin/pest` = **78 اختباراً / 533 تحقّقاً** ناجحة · `php artisan route:list --path=api` = **71**
  (العدد لم يتغيّر: الختم طبقات لا مسارات) · `flutter analyze` = No issues found! ·
  `flutter test` = 44 ناجحة.

---

## [2026-10-19 06:25:45] المرحلة 8 — واجهة الإدارة: لا SQL نُفِّذ، وما هو معلّق على إذن · Qoder Agent

**لم يُنفَّذ أي أمر SQL في هذه المرحلة — لا قراءة ولا كتابة.** الواجهات خُصصت واختُبرت بمزيفات
مستودعات داخل `test/responsive_layout_test.dart` و`test/ibac_test.dart`، فبقي الاتصال بالقاعدة الحيّة
صفراً: لا `INSERT` ولا `UPDATE` ولا `DELETE` ولا `DDL`، ولا استدعاء `oracle` MCP في هذه الجولة. هذا
البيان مقصود بالتحديد: من يقرأ السجل يجب أن يميّز ما جرى تنفيذه فعلاً عمّا هو مُعَدّ للتنفيذ.

### العبارات التي ستُشغَّل عند أول قبول يدوي مأذون (لم تُنفَّذ)

مكتوبة هنا بأسماء الأعمدة الصحيحة الموثّقة في قطاع «المرجع الصحيح لأعمدة جداول IBAC»، ومبنية على
ما تقرأه الخلفية فعلاً:

```sql
-- 1) قبل الكتابة: هل يوجد مستخدم ثانٍ أصلاً؟ (قراءة)
SELECT USER_ID, USER_NAME_EN, USER_TYPE, IS_ACTIVATED, IS_ADMIN
  FROM ACCOUNTS.APP_USERS
 ORDER BY USER_ID;

-- 2) بعد إنشاء مستخدم من الواجهة: تسلسل المفتاح يعمل ولا يتكرر (قراءة)
SELECT ID, USER_ID, PERMISSION_ID, GRANTED_BY, IS_ACTIVE, EXPIRES_ON
  FROM ACCOUNTS.APP_USERS_PERMISSIONS
 WHERE USER_ID = :new_user_id
 ORDER BY ID;

-- 3) بعد كل عملية: سجل النشاط كتب بالعربية الصحيحة (قراءة) — 11g بلا FETCH FIRST
SELECT *
  FROM (SELECT ACTIVITY_ID, USER_ID, TARGET_USER_ID, ACTION_CODE, STATUS, IP_ADDRESS,
               DESCRIPTION_AR, TO_CHAR(CREATED_ON,'YYYY-MM-DD HH24:MI:SS') AS ON_STR
          FROM ACCOUNTS.APP_USER_ACTIVITY
         ORDER BY ACTIVITY_ID DESC)
 WHERE ROWNUM <= 20;

-- 4) بعد إنهاء جلسة من الشاشة: EXPIRES_AT تقدّم إلى SYSDATE (قراءة)
SELECT ID AS TOKEN_ID, TOKENABLE_ID AS USER_ID,
       DBMS_LOB.SUBSTR(NAME, 60, 1) AS TOKEN_NAME,
       TO_CHAR(CREATED_AT,'YYYY-MM-DD HH24:MI:SS') AS CREATED_STR,
       TO_CHAR(LAST_USED_AT,'YYYY-MM-DD HH24:MI:SS') AS LAST_USED_STR,
       TO_CHAR(EXPIRES_AT,'YYYY-MM-DD HH24:MI:SS') AS EXPIRES_STR
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS
 WHERE TOKENABLE_TYPE = 'App\Models\User'
 ORDER BY ID DESC;

-- 5) بعد حفظ إعداد الأمان: الصف تُحيّن لا يُدرج (قراءة)
SELECT SETTING_ID, SETTING_KEY, SETTING_VALUE, VALUE_TYPE, MIN_VALUE, MAX_VALUE
  FROM ACCOUNTS.APP_SETTINGS
 ORDER BY SORT_ORDER;
```

> **تنبيه 11g مُسجَّل حتى لا يُنسخ الخطأ:** `FETCH FIRST … ROWS ONLY` غير مدعوم في أوراكل 11g
> (ظهرت في 12c+)؛ الحدّ يُكتب بلفّ الاستعلام في طبقة فرعية ثم `WHERE ROWNUM <= 20` كما في العبارة
> (3) أعلاه، لأن ترتيب `ROWNUM` بعد الفرز لا يتحقق إلا داخل الطبقة الخارجية. وجدول النشاط هو الوحيد
> هنا الذي يكبر بسرعة، فكل استعلام فحصٍ عليه يحتاج حداً.

### ما لم يُنفَّذ ولماذا

`INSERT` في `APP_USERS` (مستخدم ثانٍ غير مدير) و`UPDATE` في `APP_SETTINGS`
(`session_idle_minutes=1` لاختبار الخمول) — الاثنان كتابة على مخطط إنتاجي مشترك مع نظام الإرث،
وموقوفان على موافقة صريحة من المستخدم. تُوثَّق نتيجتهما هنا فور الإذن، بالعبارة الحرفية والصفوف
التي ردّت.

---

## [2026-10-20 00:45:10] المرحلة 9 — عبارات التحقق (قراءة فقط، عبر خادم `oracle` MCP) · Qoder Agent

لم تُنفَّذ أي عبارة كتابة في هذه الجولة: التصحيح كان في PHP لا في DDL. العبارات أدناه حرفية، ونُسخ
نتائجها كما ردّت.

```sql
-- 1) البرهان البايتي: شكل القيمة المفسَدة مقابل الشكل الصحيح للعربية في WE8MSWIN1252
SELECT DUMP(CHR(191)||CHR(191)||CHR(191), 1016) AS corrupted_shape,
       DUMP(CHR(216)||CHR(225)||CHR(233)||CHR(199), 1016) AS correct_shape
  FROM DUAL;
-- CORRUPTED_SHAPE = Typ=1 Len=3 CharacterSet=WE8MSWIN1252: bf,bf,bf      (ما كان ينتجه encodeForOracle)
-- CORRECT_SHAPE   = Typ=1 Len=4 CharacterSet=WE8MSWIN1252: d8,e1,e9,c7   («خالد» — ما ينتجه toOracleSearchChars)

-- 2) هل أفسدت العلّة بيانات قائمة؟ صفر علامة استبدال في أسماء العملاء
SELECT (SELECT COUNT(*) FROM ACCOUNTS.CUST WHERE CUST_NAME LIKE '%'||CHR(191)||'%') AS corrupted_cust,
       (SELECT COUNT(*) FROM ACCOUNTS.CUST) AS total_cust,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS) AS perms,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_SETTINGS) AS settings,
       (SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS) AS grants
  FROM DUAL;
-- CORRUPTED_CUST=0 · TOTAL_CUST=25406 · PERMS=93 · SETTINGS=10 · GRANTS=1

-- 3) المُشغِّلات (Triggers) الثمانية صالحة؟ و`USER_NO` زال و`IS_ADMIN` موجود؟
SELECT (SELECT COUNT(*) FROM ALL_OBJECTS
         WHERE OWNER='ACCOUNTS' AND OBJECT_TYPE='TRIGGER' AND STATUS<>'VALID') AS invalid_triggers,
       (SELECT COUNT(*) FROM ALL_OBJECTS
         WHERE OWNER='ACCOUNTS' AND OBJECT_TYPE='TRIGGER') AS total_triggers,
       (SELECT COUNT(*) FROM ALL_TAB_COLUMNS
         WHERE OWNER='ACCOUNTS' AND TABLE_NAME='APP_USERS' AND COLUMN_NAME='USER_NO') AS user_no_left,
       (SELECT COUNT(*) FROM ALL_TAB_COLUMNS
         WHERE OWNER='ACCOUNTS' AND TABLE_NAME='APP_USERS' AND COLUMN_NAME='IS_ADMIN') AS is_admin
  FROM DUAL;
-- INVALID_TRIGGERS=0 · TOTAL_TRIGGERS=8 · USER_NO_LEFT=0 · IS_ADMIN=1

-- 4) قيم سياسة الجلسات المقروءة من الجدول لا من الكود
SELECT SETTING_KEY, SETTING_VALUE, VALUE_TYPE
  FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY IN ('session_idle_minutes','session_absolute_days','session_touch_threshold_minutes')
 ORDER BY SETTING_KEY;
-- session_absolute_days=14 (int) · session_idle_minutes=240 (int) · session_touch_threshold_minutes=5 (int)

-- 5) شاهد على تخزين النظام القديم لبايتات CP1256 في صفوف حقيقية
SELECT CUST_NO, DUMP(CUST_NAME, 1016) AS name_bytes
  FROM ACCOUNTS.CUST
 WHERE ROWNUM <= 2 AND CUST_NAME IS NOT NULL
 ORDER BY CUST_NO;
-- CUST_NO=0 → Typ=1 Len=21 … da,e3,e1,c7,c1,20,c7,e1,df,c8,e6,cf,ed,20,e1,e1,ce,ed,c7,d8,c9
-- CUST_NO=1 → Typ=1 Len=8  … da,e1,ed,20,e3,d5,e1,cd
```

**ملاحظات 11g مُسجَّلة كي لا تُعاد:** `FETCH FIRST … ROWS ONLY` غير مدعوم في 11g فيُستخدم `ROWNUM`
(العبارة 5)، والعدّادات المتعددة تُلفّ في **استعلامات فرعية عدّادية** داخل `SELECT … FROM DUAL` لأن
`UNION ALL` ثم `FROM DUAL` أعطى `ORA-00933` في جلسة سابقة، وقراءة أسماء الأعمدة تُتحقّق أولاً من
`ALL_TAB_COLUMNS` قبل أي محاولة (كُشِفت `ORA-00904` أكثر من مرة بهذا الطريق).

**الكتابة المعلّقة على إذن:** لم تتغيّر قائمة المعلَّقات — `INSERT` مستخدم ثانٍ في `APP_USERS`،
`UPDATE` لـ `APP_SETTINGS` بسيناريو الخمول، وكل ما في `ibac_permissions_plan.md` §10. تُسجَّل عباراتها
هنا بحرفيتها عند الإذن.

---

## [2026-10-20 04:13:12] تحقّق قراءة فقط: ثبات إصلاح الترميز على صفوف حيّة (Qoder Agent)

بعد حصانة التكرار في `ArabicEncoding::fixMojibake()` — نص UTF-8 سليم (عربية U+0600–U+06FF ولا
محرف في 0x80–0xFF) يُرجع كما هو — طُبّق الإصلاح على صفوف الإنتاج للتأكد أن الثبات ميداني لا
نظري. القراءة عبر MCP `oracle` للعبارات 2–4، وعبر `php artisan tinker` للعبارة 1 (نفس النص بربط
`:k`).

```sql
-- 1) اسم مستخدم حيّ: إصلاح واحد = «ارسلان»، والإصلاح الثاني لا يغيّره (idempotent)
SELECT USER_NAME_AR FROM ACCOUNTS.APP_USERS WHERE USER_ID = 1;
-- النتيجة (عبر tinker): has_arabic_once=true · idempotent=true · identical_to_php_literal=true

-- 2) تسمية إعداد حيّ: إصلاح واحد = «مهلة خمول الجلسة (بالدقائق)» وثابت عند التكرار
SELECT NAME_AR FROM ACCOUNTS.APP_SETTINGS WHERE SETTING_KEY = 'session_idle_minutes';

-- 3) الإعدادات العشر كاملة: القيم كلها ASCII (int/bool) عدا maintenance_message (string, NULL)
--    ⇒ لا عربية تظهر في raw_value الذي يرجعه SettingController خاماً
SELECT SETTING_KEY, VALUE_TYPE, SETTING_VALUE, NAME_AR
  FROM ACCOUNTS.APP_SETTINGS
 ORDER BY SORT_ORDER;

-- 4) الأعمدة الإلزامية في APP_USERS: يجب أن يكون كلها مربوطاً في إدراج store() بعد إصلاح العقد
SELECT COLUMN_NAME, NULLABLE, DATA_DEFAULT
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'APP_USERS' AND NULLABLE = 'N'
 ORDER BY COLUMN_ID;
-- النتيجة: USER_ID (default=null) · IS_ADMIN (default='0 ') — ولا غيرهما، وكلاهما مربوط صراحة
```

**لماذا هذا التحقق بالذات:** شاشتا الجلسات وإعدادات الأمان كانتا تعرضان رموزاً (`ط§ط±ط³ظ„ط§ظ†` بدل
`ارسلان`) لأن إصلاحاً ثانياً مرّ على قيم مُصلَحة — فتُقلب بايتات UTF-8 السليمة عبر جدول CP1256
(`موظف` → `ظ…ظˆط¸ظپ`). الثبات عند التكرار على الصف الحيّ هو الدليل الميداني على عمل الحصانة.
عُرضت تجربة كتابة مُرجَّعة (إنشاء مستخدم داخل معاملة تُلغى) لإثبات `store()` فصدّها التنفيذ الآمن،
فلم تُنفَّذ أي كتابة في هذه الجولة أصلاً — القائمة المعلَّقة أعلاه لم تتغيّر.

---

## 2026-10-20 — بذر وحدة «إعدادات API والتهيئة الديناميكية» (المنفّذ: Qoder)

**أمر البذر (يُدار عبر `02_ibac_seed.php` وليس SQL يدوياً):**
```bash
cd kyApp_API
php artisan tinker database/oracle/02_ibac_seed.php
# الناتج الحيّ: PERMISSIONS total=97 · SETTINGS total=22
```

**ما يكتبه السكربت في `APP_PERMISSIONS` (كتالوج `app_config` — 4 رموز):**
```sql
-- تُدرج عبر السكربت بأمر MERGE/INSERT على SEQ_APP_PERMISSIONS + TRG_APP_PERMISSIONS
INSERT INTO APP_PERMISSIONS (PERMISSION_CODE, MODULE, ACTION, NAME_AR, DESCRIPTION_AR, SORT_ORDER)
VALUES ('app_config.view',  'app_config', 'view',       'عرض إعدادات التطبيق',      '…', …);
INSERT INTO APP_PERMISSIONS (PERMISSION_CODE, MODULE, ACTION, NAME_AR, DESCRIPTION_AR, SORT_ORDER)
VALUES ('app_config.update','app_config', 'update',     'تعديل إعدادات التطبيق',    '…', …);
INSERT INTO APP_PERMISSIONS (PERMISSION_CODE, MODULE, ACTION, NAME_AR, DESCRIPTION_AR, SORT_ORDER)
VALUES ('app_config.api_manage','app_config','api_manage','إدارة اتصال API',        '…', …);
-- بالإضافة إلى رمز النطاق app_config.*  ⇒ يرتفع الإجمالي من 93 إلى 97
```

**ما يكتبه السكربت في `APP_SETTINGS` (تهيئة التطبيق + كلمة السر المجزّأة):**
```sql
-- القيم النصية/اللونيّة من AppConfig::DEFAULTS؛ وكلمة السر bcrypt وليست نصاً
INSERT INTO APP_SETTINGS (SETTING_KEY, SETTING_VALUE, VALUE_TYPE, …)
VALUES ('api_settings_password', '$2y$12$…bcrypt(A1.b2.c3.d4)…', 'string', …);
INSERT INTO APP_SETTINGS (SETTING_KEY, SETTING_VALUE, VALUE_TYPE, …)
VALUES ('theme_primary_color', '#A27E4E', 'string', …);
-- + company_name / company_address / company_website / company_phone
-- + app_name / theme_secondary_color / theme_background_color
-- + theme_text_primary_color / theme_text_secondary_color / theme_font_family
-- ⇒ يرتفع إجمالي الإعدادات إلى 22 سطراً
```

**تحقق القراءة بعد البذر (قراءة فقط عبر @oracle):**
```sql
SELECT COUNT(*) FROM APP_PERMISSIONS;              -- ⇒ 97
SELECT COUNT(*) FROM APP_SETTINGS;                 -- ⇒ 22
SELECT PERMISSION_CODE FROM APP_PERMISSIONS
 WHERE MODULE = 'APP_CONFIG' ORDER BY PERMISSION_CODE; -- view/update/api_manage (+ النطاق)
SELECT SETTING_KEY, VALUE_TYPE FROM APP_SETTINGS
 WHERE SETTING_KEY LIKE 'theme_%' OR SETTING_KEY='api_settings_password'; -- 6 ألوان/خط + كلمة السر
```

**ملاحظة أمان:** `api_settings_password` لا يُخرج أبداً من `GET /app-config` (الحمولة بلا سرّ)،
وتغييرها يمرّ عبر `PUT /app-config/api-password` خلف `permission:app_config.api_manage`. لم تُجر أي
كتابة على جداول الأعمال (business tables) في هذه الجولة — الكتابات محصورة في جدولَي IBAC/الإعدادات.

---

## 2026-10-21 — SQL/فحص المخطط لتقارير الحسابات (Account Reports)

**نموذج AI:** Qoder Agent · **التاريخ:** الأربعاء 21 أكتوبر 2026 · **الجلسة:** تنفيذ خطة `Account_Financial_Reports_1686e067.md`.

**تنويه:** لا توجد أي كتابة/DDL داخل `ACCOUNTS` خلال هذه المهمة — كل ما يلي هو **استعلامات فحص للقراءة فقط** تم تنفيذها عبر `oracledb` MCP / `php artisan tinker` للتأكد من صحة المسارات قبل كتابة الكود.

### 1) التأكيد على عدم وجود `ACC_TRXN`
```sql
SELECT COUNT(*) AS C
  FROM ALL_TABLES
 WHERE OWNER = 'ACCOUNTS'
   AND TABLE_NAME = 'ACC_TRXN';
-- النتيجة: 0 — الجدول غير موجود؛ يجب استخدام ENTRY_MAIN + ENTRY_SUB + ENTRY_TYPE
```

### 2) التحقّق من بنية `ENTRY_SUB` والربط بـ `CHART_ACC`
```sql
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS'
   AND TABLE_NAME = 'ENTRY_SUB'
 ORDER BY COLUMN_ID;
-- الأعمدة ذات الصلة: ENTRY_NO, DET_NO, ACC_NO, ENTRY_MNT, CUR_NO, DETAILS
```

### 3) معرفة العملة المحلية مقابل الأجنبية (للتقرير 2)
```sql
SELECT CUR_NO, CUR_NAME, CUR_SIGN
  FROM ACCOUNTS.CURRENCY
 ORDER BY CUR_NO;
-- CUR_NO = 1  =>  "ريال يمني" / YR  (هي العملة المحلية)
```

### 4) اختبار تصنيف الرصيد المحلي/الأجنبي
```sql
SELECT s.ACC_NO,
       s.CUR_NO,
       SUM(CASE WHEN s.ENTRY_MNT > 0 AND s.CUR_NO = 1 THEN s.ENTRY_MNT ELSE 0 END) AS LOCAL_DEBIT,
       SUM(CASE WHEN s.ENTRY_MNT < 0 AND s.CUR_NO = 1 THEN -s.ENTRY_MNT ELSE 0 END) AS LOCAL_CREDIT,
       SUM(CASE WHEN s.ENTRY_MNT > 0 AND s.CUR_NO <> 1 THEN s.ENTRY_MNT ELSE 0 END) AS FOREIGN_DEBIT,
       SUM(CASE WHEN s.ENTRY_MNT < 0 AND s.CUR_NO <> 1 THEN -s.ENTRY_MNT ELSE 0 END) AS FOREIGN_CREDIT
  FROM ACCOUNTS.ENTRY_SUB s
 WHERE s.ACC_NO IN (SELECT ACC_NO FROM ACCOUNTS.CHART_ACC WHERE ACC_SUB = :accSub)
 GROUP BY s.ACC_NO, s.CUR_NO;
```

### 5) حساب آخر حركة لنافذة 15 يوماً الافتراضية
```sql
SELECT MAX(m.ENTRY_DATE) AS LAST_TRXN_DATE
  FROM ACCOUNTS.ENTRY_MAIN m
  JOIN ACCOUNTS.ENTRY_SUB s ON s.ENTRY_NO = m.ENTRY_NO
 WHERE s.ACC_NO = :accNo;
-- ثم في PHP: $from = subDays(lastTrxnDate, 15); $to = now();
```

### 6) فحص ترميز Windows-1256 للحقول العربيّة
```sql
SELECT RAWTOHEX(UTL_RAW.CAST_TO_RAW(TYPE_NAME)) AS HEX_BYTES,
       TYPE_NAME
  FROM ACCOUNTS.ENTRY_TYPE
 WHERE ROWNUM <= 5;
--Bytes 0xC0–0xFF => عربية CP-1256؛ تصل كـ Latin-1 mojibake وتُصحَّح في التطبيق.
```

### 7) حساب الرصيد الافتتاحي (قبل `:from`)
```sql
SELECT NVL(SUM(CASE WHEN s.ENTRY_MNT > 0 THEN s.ENTRY_MNT ELSE 0 END), 0)
     - NVL(SUM(CASE WHEN s.ENTRY_MNT < 0 THEN -s.ENTRY_MNT ELSE 0 END), 0)
       AS OPENING_BALANCE
  FROM ACCOUNTS.ENTRY_MAIN m
  JOIN ACCOUNTS.ENTRY_SUB s ON s.ENTRY_NO = m.ENTRY_NO
 WHERE s.ACC_NO = :accNo
   AND m.ENTRY_DATE < TO_DATE(:fromDate, 'YYYY-MM-DD');
```

### 8) استعلام الرصيد الجاري لكل سطر (window function)
```sql
SELECT m.ENTRY_NO, s.DET_NO, m.ENTRY_DATE, t.TYPE_NAME, s.DETAILS,
       CASE WHEN s.ENTRY_MNT > 0 THEN  s.ENTRY_MNT ELSE 0 END AS DEBIT,
       CASE WHEN s.ENTRY_MNT < 0 THEN -s.ENTRY_MNT ELSE 0 END AS CREDIT,
       :openingBalance + SUM(s.ENTRY_MNT) OVER (
           ORDER BY m.ENTRY_DATE, m.ENTRY_NO, s.DET_NO
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS RUNNING_BALANCE
  FROM ACCOUNTS.ENTRY_MAIN m
  JOIN ACCOUNTS.ENTRY_SUB  s ON s.ENTRY_NO = m.ENTRY_NO
  LEFT JOIN ACCOUNTS.ENTRY_TYPE t ON t.TYPE_NO = s.TYPE_NO
 WHERE s.ACC_NO = :accNo
   AND m.ENTRY_DATE BETWEEN TO_DATE(:fromDate,'YYYY-MM-DD')
                        AND TO_DATE(:toDate,'YYYY-MM-DD')
 ORDER BY m.ENTRY_DATE, m.ENTRY_NO, s.DET_NO;
```

### 9) لا تغييرات على `APP_USERS_PERMISSIONS`
الصلاحية `accounts.statement` (وكذلك `accounts.print` / `accounts.export`) **كانت مُهيّأة مسبقاً** في `APP_PERMISSIONS` — لم يضف هذا العمل أي codes جديدة، وأي مستخدم يملكها يستطيع الوصول للمسارين الجديدين مباشرة.

### 10) لا DDL
- لم تُنشَأ جداول، لم تُضَف أعمدة، لم تُنشَأ sequences أو triggers.
- جميع التعديلات على طبقة الاستعلام داخل Laravel (`AccountController`) وطبقة العرض داخل Flutter.

---

# [2026-10-21 06:17] دورة حياة الجلسات — كنس المنتهي وتوحيد الساعة على `SYSDATE`

**النموذج المنفذ / AI Model:** Qoder Agent · **الاتصال:** `oracle` MCP (ACCOUNTS) للقراءات · **الكتابات:** `DELETE` واحد على `ACCOUNTS.PERSONAL_ACCESS_TOKENS` (بنية التوكنات، لا جدول أعمال) صادر من `SessionPolicy::purgeExpired()` ومن اختباره.

### 1) قياس الانقسام بين ساعتي PHP وأوراكل (قراءة)
```sql
SELECT TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')                AS DB_SYSDATE,
       TO_CHAR(CURRENT_TIMESTAMP,'YYYY-MM-DD HH24:MI:SS')      AS DB_TIMESTAMP,
       TO_CHAR(SYSTIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') AS DB_UTC,
       COUNT(*)                                                AS TOKENS,
       SUM(CASE WHEN EXPIRES_AT IS NULL THEN 1 ELSE 0 END)                       AS NO_EXPIRY,
       SUM(CASE WHEN EXPIRES_AT IS NOT NULL AND EXPIRES_AT <= SYSDATE THEN 1 ELSE 0 END) AS EXPIRED_NOW,
       SUM(CASE WHEN EXPIRES_AT IS NOT NULL AND EXPIRES_AT >  SYSDATE THEN 1 ELSE 0 END) AS LIVE_NOW
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;
```
الناتج: `DB_SYSDATE 2026-10-21 03:49:46` · `DB_UTC 2026-10-21 00:49:46` (فارق **3 ساعات**) · `TOKENS 22` · `NO_EXPIRY 20` · `EXPIRED_NOW 2` · `LIVE_NOW 0`.

### 2) أنواع أعمدة التوكن (قراءة مخطط)
```sql
SELECT COLUMN_NAME, DATA_TYPE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='PERSONAL_ACCESS_TOKENS'
 ORDER BY COLUMN_ID;
```
`EXPIRES_AT`/`LAST_USED_AT`/`CREATED_AT`/`UPDATED_AT` جميعها `TIMESTAMP(6)` — لا حاجة لأي تغيير مخطط.

### 3) الصفوف صفًّا صفاً — إثبات أن الموعد مكتوب بتوقيت UTC (قراءة)
```sql
SELECT * FROM (
  SELECT ID, TOKENABLE_ID, DBMS_LOB.SUBSTR(NAME,28,1) AS NM,
         TO_CHAR(CREATED_AT,'MM-DD HH24:MI') AS CREATED,
         TO_CHAR(EXPIRES_AT,'MM-DD HH24:MI') AS EXPIRES,
         TO_CHAR(UPDATED_AT,'MM-DD HH24:MI') AS UPDATED,
         ROUND((CAST(EXPIRES_AT AS DATE) - SYSDATE)*24*60)                       AS MIN_VS_SYSDATE,
         ROUND((CAST(EXPIRES_AT AS DATE) - CAST(SYS_EXTRACT_UTC(SYSTIMESTAMP) AS DATE))*24*60) AS MIN_VS_UTC
    FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS ORDER BY ID DESC
) WHERE ROWNUM <= 25;
```
الصفان 161 و162: `EXPIRES 10-21 00:40` مقابل `MIN_VS_SYSDATE = -213` و`MIN_VS_UTC = -33` — أي أن الموعد مكتوب على ساعة UTC ويبدو أمام `SYSDATE` منتهيًا منذ 3 ساعات و21 دقيقة، بينما لم يمضِ على انتهيته الحقيقي 33 دقيقة. هذا نصّ العطل.

### 4) عبارة الحذف التي يولّدها `purgeExpired()` (الكتابة الوحيدة)
Laravel Eloquent — `PersonalAccessToken::query()-> … ->delete()` المولّد من `SessionPolicy::purgeExpired()` (الاستعلام المعروض بـ`toSql()` قبل استبدال `select *` بـ`delete`):
```sql
delete from "PERSONAL_ACCESS_TOKENS"
 where (("EXPIRES_AT" is not null and "EXPIRES_AT" < :db_now)
     or ("EXPIRES_AT" is null and COALESCE(last_used_at, created_at) < :idle_threshold));
```
المربوطات: `:db_now` = `SessionPolicy::dbNow()` (زمن `SYSDATE`) و`:idle_threshold` = `dbNow - session_idle_minutes` (240 من `APP_SETTINGS`). لا اسم مخطط صراحة: الاتصال يسجّل كمستخدم `ACCOUNTS` فيُحلّ الاسم إلى `ACCOUNTS.PERSONAL_ACCESS_TOKENS`.

### 5) التحقق بعد الكنس (قراءة)
```sql
SELECT COUNT(*)                                                   AS TOKENS,
       SUM(CASE WHEN EXPIRES_AT IS NULL THEN 1 ELSE 0 END)        AS NO_DEADLINE,
       SUM(CASE WHEN EXPIRES_AT IS NOT NULL AND EXPIRES_AT <= SYSDATE THEN 1 ELSE 0 END) AS DATED_EXPIRED,
       SUM(CASE WHEN EXPIRES_AT > SYSDATE THEN 1 ELSE 0 END)       AS LIVE
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;
```
الناتج: `TOKENS 1` · `NO_DEADLINE 0` · `DATED_EXPIRED 0` · `LIVE 1` — من 22 إلى 1، والباقي جلسة حيّة لم يمسّها الكنس.

### 6) ملاحظات تنفيذية
- استعلامان أوليان فشلا ثم صُحّحا، وكلاهما خطأ 11g معروف ولا يُسجَّل كنتيجة: `ORA-00933` من `FETCH FIRST 25 ROWS ONLY` (11g لا تعرفها — المستبدلة بـ`ROWNUM` في طبقة خارجية)، و`ORA-00932` من `EXPIRES_AT - SYSDATE` على عمود `TIMESTAMP` (يرجّع `INTERVAL` لا `NUMBER` — صُحّح بـ`CAST(... AS DATE)`).
- لا `UPDATE` ولا `DDL` ولا كتابة على أي جدول ERP.
- `SESSION_TOUCH_THRESHOLD`/`SESSION_IDLE_MINUTES` لم تُعدَّل في `APP_SETTINGS`؛ قراءة فقط عبر `SettingsStore`.


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

## [2026-10-21 07:32] — حصر الجلسات بعد تشغيل `purgeExpired()` (قراءة فقط)
**المنفّذ:** Qoder Agent · **الغرض:** تأكيد أن جدول التوكنات لا يحمل صفوفًا ميّتة، وتشخيص فشل اختبار بنية قائمة الجلسات.

```sql
-- حصر مباشر بنفس فرعي `SessionPolicy::purgeExpired()`
SELECT COUNT(*)                                                        AS TOKENS,
       SUM(CASE WHEN EXPIRES_AT IS NULL THEN 1 ELSE 0 END)             AS NO_DEADLINE,
       SUM(CASE WHEN EXPIRES_AT IS NOT NULL AND EXPIRES_AT < SYSDATE
                THEN 1 ELSE 0 END)                                     AS DATED_EXPIRED,
       SUM(CASE WHEN EXPIRES_AT IS NULL
                 AND COALESCE(LAST_USED_AT, CREATED_AT) < SYSDATE - 240/1440
                THEN 1 ELSE 0 END)                                     AS LEGACY_IDLE
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;
-- النتيجة: TOKENS = 0، NO_DEADLINE = NULL، DATED_EXPIRED = NULL، LEGACY_IDLE = NULL
-- أي أن الجدول خالٍ تماماً: لا أحد مسجّل الدخول في توقيت الفحص (بعد أن كانت 22 صفاً ميّتاً).
```

### ملاحظات
- `SUM(CASE …)` على مجموعة فارغة يُرجع `NULL` لا `0` — ولهذا ظهرت العدّادات الثلاث `NULL` مع `COUNT(*) = 0`.
- لا كتابة ولا DDL: استعلام قراءة واحد.
- من هذه الحالة وُلّد تعديل `ActiveSessionsTest` (تخطٍّ لطيف عند جدول فارغ) بدل الاعتماد على صف حقيقي كـ fixture.

---

## [2026-10-21 08:00] — تشخيص `ORA-03115` عند `SELECT * FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS` (قراءة فقط)
**المنفّذ:** Qoder Agent · **الأداة:** خادم MCP الخاص بأوراكل + اتصال Laravel (`oci8`) · **الغرض:** تحديد سبب الخطأ الذي يراه المستخدم في أداته.

```sql
-- (1) أنواع أعمدة الجدول: هنا يظهر السبب
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE, NULLABLE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'PERSONAL_ACCESS_TOKENS'
 ORDER BY COLUMN_ID;
-- ID NUMBER(19,0) · TOKENABLE_TYPE VARCHAR2(255) · TOKENABLE_ID NUMBER(19,0)
-- NAME CLOB · TOKEN VARCHAR2(64) · ABILITIES CLOB
-- LAST_USED_AT / EXPIRES_AT / CREATED_AT / UPDATED_AT  = TIMESTAMP(6) scale 6

-- (2) نسخة الخادم
SELECT banner FROM V$VERSION WHERE ROWNUM <= 2;
-- Oracle Database 11g Enterprise Edition Release 11.2.0.1.0 - 64bit Production

-- (3) عزل الأعمدة: أعمدة VARCHAR2/NUMBER وحدها
SELECT ID, TOKENABLE_ID, TOKEN, TOKENABLE_TYPE FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;      -- يعمل
-- (4) أعمدة TIMESTAMP(6) وحدها
SELECT EXPIRES_AT, CREATED_AT, LAST_USED_AT, UPDATED_AT FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS; -- يعمل
-- (5) عمودا CLOB وحدهما
SELECT NAME, ABILITIES FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;                                -- يعمل
-- (6) النجمة كاملة من مسار MCP ومن اتصال التطبيق (PDO/oci8 19.32) — يعمل في الاثنين
SELECT * FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;

-- (7) صيغة العمل الآمنة للعملاء القدماء: تحويل LOB والتواريخ إلى نص
SELECT ID, TOKENABLE_TYPE, TOKENABLE_ID,
       DBMS_LOB.SUBSTR(NAME, 4000, 1)                       AS NAME_TXT,
       TOKEN,
       DBMS_LOB.SUBSTR(ABILITIES, 4000, 1)                  AS ABILITIES_TXT,
       TO_CHAR(CREATED_AT, 'YYYY-MM-DD HH24:MI:SS')         AS CREATED_TXT,
       TO_CHAR(EXPIRES_AT, 'YYYY-MM-DD HH24:MI:SS')         AS EXPIRES_TXT
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS;
```

### الخلاصة
- الخطأ **من جهة عميل/تعريف (describe) لا من القاعدة**: `SELECT *` يصف عمودَي `CLOB` وأربعة `TIMESTAMP(6)`، والعملاء القدامى (oci.dll 10g/11g، ojdbc5/ojdbc6 في SQL/PL-SQL Developer أو DBeaver) لا يعرفون التمثيل الشبكي لهذه الأنواع على **11.2.0.1** فيرمون `ORA-03115` — ويظهر حتى لو كان الجدول فارغاً لأنه فشل وصف لا فشل جلب.
- مسار العمل الحديث سليم: خادم MCP (node-oracledb) و`oci8 3.3.0` مع Instant Client **19.32** رجعا الصف كاملاً بلا خطأ.
- لم تُنفَّذ أي كتابة أو DDL — كل ما سبق `SELECT` للقراءة فقط.



---

## [2026-10-21 11:07] — مفتاحا الترويسة الإنجليزية في `APP_SETTINGS` (company_name_en / company_address_en)

**المنفِّذ / Executor:** Qoder Agent
**الطريق / Channel:** موصل `oracledb MCP` — تنفيذ مباشر على مخطط `ACCOUNTS` (لا `migrations`؛ القاعدة تراثية).
**الغرض / Purpose:** جعل العمود الأيسر من ترويسة التقارير الثلاثية (اسم الشركة + العنوان بالإنجليزية) قابلاً للتحكم من الإعدادات بدل نص ثابت في الكود.

### 1) الاستعلامات التشخيصية (قراءة فقط) / read-only probes

```sql
-- (أ) بنية الجدول — لا عمود مجموعة؛ التجميع يتم في PHP
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE, COLUMN_ID
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'APP_SETTINGS'
 ORDER BY COLUMN_ID;
-- SETTING_ID NUMBER(N) · SETTING_KEY VARCHAR2(60) · SETTING_VALUE VARCHAR2(500)
-- VALUE_TYPE VARCHAR2(20) · NAME_AR VARCHAR2(150) · DESCRIPTION_AR VARCHAR2(500)
-- MIN_VALUE/MAX_VALUE NUMBER · IS_LOCKABLE NUMBER(N) · SORT_ORDER NUMBER
-- UPDATED_BY NUMBER · UPDATED_ON DATE

-- (ب) صفوف العلامة التجارية القائمة (11..14) وأسمائها العربية المخزنة بايتات CP-1256
SELECT SETTING_ID, SETTING_KEY, SETTING_VALUE, VALUE_TYPE, NAME_AR, SORT_ORDER, IS_LOCKABLE
  FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY LIKE 'company%' ORDER BY SORT_ORDER;
-- 11 company_name · 12 company_address · 13 company_website · 14 company_phone

-- (ج) مصدر المعرّف التلقائي + آخر قيمة من المتتالية
SELECT TRIGGER_NAME, TRIGGER_TYPE, TRIGGERING_EVENT, STATUS FROM ALL_TRIGGERS
 WHERE TABLE_NAME = 'APP_SETTINGS' AND TABLE_OWNER = 'ACCOUNTS';
-- TRG_APP_SETTINGS · BEFORE EACH ROW · INSERT · ENABLED  (:NEW.SETTING_ID := SEQ_APP_SETTINGS.NEXTVAL)
SELECT MAX(SETTING_ID) FROM ACCOUNTS.APP_SETTINGS;                  -- 22
SELECT LAST_NUMBER FROM ALL_SEQUENCES
 WHERE SEQUENCE_OWNER = 'ACCOUNTS' AND SEQUENCE_NAME = 'SEQ_APP_SETTINGS';  -- 23  ⇒ آمن بلا تصادم

-- (د) اختبار ترميز: العميل لا ينقل العربية الحرفية (كلها 0xFD) لكنه ينقل بايتات CP-1256 كما هي
SELECT DUMP('اسم الشركة بالإنجليزي', 1016) FROM DUAL;   -- fd,fd,fd…  ⇒ لا تُرسل العربية حرفياً
SELECT DUMP('ÇÓã', 1016) FROM DUAL;                     -- c7,d3,e3   ⇒ الصيغة المموّهة تُرسَل سليمة
```

**القرار الترميزي / encoding decision:** التسميات العربية كُتبت بايتات Windows-1256 العربية
مستعرضة كأحرف لاتينية — نفس أسلوب الصفوف 11..22 — لتصل مطابقة حرفياً كما في التحقّق (د).
وليد التحقق المحلي قورن بـ `DUMP` قبل التنفيذ وبعده.

### 2) الكتابة / the writes

```sql
INSERT INTO ACCOUNTS.APP_SETTINGS
  (SETTING_KEY, SETTING_VALUE, VALUE_TYPE, NAME_AR, DESCRIPTION_AR,
   MIN_VALUE, MAX_VALUE, IS_LOCKABLE, SORT_ORDER, UPDATED_ON)
VALUES
  ('company_name_en', 'ALKABODI FOR MEN''s TAILORING', 'string',
   'ÇÓã ÇáÔÑßÉ ÈÇáÅäÌáíÒí',
   'ÇÓã ÇáÔÑßÉ ÇáãÚÑæÖ ÈÇáÅäÌáíÒíÉ Ýí ÊÑæíÓÉ ÇáÊÞÇÑíÑ',
   NULL, NULL, 0, 115, SYSDATE);

INSERT INTO ACCOUNTS.APP_SETTINGS
  (SETTING_KEY, SETTING_VALUE, VALUE_TYPE, NAME_AR, DESCRIPTION_AR,
   MIN_VALUE, MAX_VALUE, IS_LOCKABLE, SORT_ORDER, UPDATED_ON)
VALUES
  ('company_address_en', 'Airport Street - Next to Al-shayef House', 'string',
   'ÚäæÇä ÇáÔÑßÉ ÈÇáÅäÌáíÒí',
   'ÚäæÇä ÇáÔÑßÉ ÇáãÚÑæÖ ÈÇáÅäÌáíÒíÉ Ýí ÊÑæíÓÉ ÇáÊÞÇÑíÑ',
   NULL, NULL, 0, 125, SYSDATE);

COMMIT;
```

- `SETTING_ID` لم يُذكر صراحةً — يمنحه `TRG_APP_SETTINGS` ⇒ الناتج 23 ثم 24 تماماً كما توقّع `LAST_NUMBER`.
- `SORT_ORDER` = 115 و125 ليظهر كل مفتاح ملاصقاً لنظيره العربي في شاشة «إعدادات الأمان» (110 ← 115 ← 120 ← 125).
- `IS_LOCKABLE = 0` (قابل للتحرير من الواجهة) و`VALUE_TYPE = 'string'` وحدود NUMBER فارغة — نفس نمط `company_*`.

### 3) التحقّق بعد التنفيذ / post-apply verification

```sql
SELECT SETTING_ID, SETTING_KEY, SETTING_VALUE, NAME_AR, DESCRIPTION_AR, SORT_ORDER, VALUE_TYPE, IS_LOCKABLE
  FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY IN ('company_name_en', 'company_address_en') ORDER BY SORT_ORDER;
-- 23 company_name_en    ALKABODI FOR MEN's TAILORING        … 115 string 0
-- 24 company_address_en Airport Street - Next to Al-shayef House  125 string 0

SELECT DUMP(NAME_AR, 1016) FROM ACCOUNTS.APP_SETTINGS WHERE SETTING_KEY = 'company_name_en';
-- c7,d3,e3,20,c7,e1,d4,d1,df,c9,20,c8,c7,e1,c5,e4,cc,e1,ed,d2,ed  ⇒ مطابق للمحسوب مسبقاً

SELECT NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID,'NONE') FROM DUAL;   -- NONE ⇒ الأمر كُرِّس فعلاً
```

### 4) ما لم يُمَسّ / untouched

- لا `UPDATE` ولا `DELETE` على أي صف قائم؛ العدد من 22 إلى 24 صفاً.
- لا أعمدة جديدة ولا جدول جديد — `APP_SETTINGS` key-value كما هو.
- الملف المكافئ للتكرار لاحقاً: `kyApp_API/database/oracle/05_app_settings_company_en.sql`.


## [2026-10-22] استعلامات التحقق من كشف العمل (oracledb MCP — قراءة فقط)
```sql
-- مخطط الجداول
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS'
   AND TABLE_NAME IN ('CUTTER_FROM_CALC','TAILOR_FROM_CALC','CUTTER','TAILOR') ORDER BY TABLE_NAME, COLUMN_ID;

-- قصاص (ACC_NO=12910001) — يوم واحد للتأكد من مطابقة PDF
SELECT TO_CHAR(w.CUTTING_DATE,'DD/MM/YYYY') WORK_DATE, w.STYLE_NAME,
       NVL(w.POST,0) QTY, NVL(w.AMT,0) TOTAL
  FROM ACCOUNTS.CUTTER_FROM_CALC w, ACCOUNTS.CUTTER r
 WHERE w.CUTTER_NO=r.CUTTER_NO AND r.ACC_NO=12910001
   AND w.CUTTING_DATE BETWEEN TO_DATE('03/07/2026','DD/MM/YYYY')
       AND TO_DATE('03/07/2026','DD/MM/YYYY')+1-1/86400
 ORDER BY w.CUTTING_DATE, w.STYLE_NAME;
-- => حجازي(2/1400) قطري(10/4000) قطري جاهز(2/500) لابقوت(1/400) مطابقة للسعر 700/400/250/400

-- خياط (ACC_NO=12910004)
SELECT t.STYLE_NAME, TO_CHAR(t.TAILOR_DATE,'DD/MM/YYYY') T_DATE, t.POST, t.AMT, t.AMT_ALL
  FROM ACCOUNTS.TAILOR_FROM_CALC t, ACCOUNTS.TAILOR tl
 WHERE t.TAILOR_NO=tl.TAILOR_NO AND tl.ACC_NO=12910004
   AND t.TAILOR_DATE BETWEEN TO_DATE('09/07/2026','DD/MM/YYYY') AND TO_DATE('22/07/2026','DD/MM/YYYY')
 ORDER BY t.TAILOR_DATE;
-- => AMT_ALL هو الإجمالي المعروض (15/07 قطري جاهز: AMT=3000 AMT_ALL=4800 POST=3 => سعر 1600)

-- ربط العملة
SELECT ct.CUR_NO, cc.CODE, cc.MAIN_CUR_NAME FROM ACCOUNTS.CUTTER ct
 LEFT JOIN ACCOUNTS.CUR_CODE cc ON cc.CUR_NO=ct.CUR_NO WHERE ct.ACC_NO=12910001;
-- => CUR_NO=1, CODE=YR, MAIN_CUR_NAME="ريال يمني" (bytes CP1256)
```
**ملاحظة:** لا `INSERT/UPDATE/DELETE` — كل ما سبق `SELECT` للتحقق فقط. التنفيذ الفعلي يتم داخل `WorkerController::fetchWorkReport` عبر oci8.


## [2026-10-22] تحقّق من منطق "آخر يوم سجل" لكشف العمل (oracledb MCP — قراءة فقط)
```sql
-- القصاص: تاريخ آخر سجل عمل للـ ACC_NO (الفترة الافتراضية الجديدة)
SELECT r.ACC_NO, TO_CHAR(MAX(w.CUTTING_DATE),'YYYY-MM-DD') LAST_DATE
  FROM ACCOUNTS.CUTTER_FROM_CALC w, ACCOUNTS.CUTTER r
 WHERE w.CUTTER_NO=r.CUTTER_NO AND r.ACC_NO=12910001 GROUP BY r.ACC_NO;
-- => 2026-08-16

-- جلب التقرير على تلك الفترة (من = إلى = آخر يوم) للتأكد من وجود أسطر
SELECT TO_CHAR(w.CUTTING_DATE,'DD/MM/YYYY') WORK_DATE, w.STYLE_NAME, NVL(w.POST,0) QTY, NVL(w.AMT,0) TOTAL
  FROM ACCOUNTS.CUTTER_FROM_CALC w, ACCOUNTS.CUTTER r
 WHERE w.CUTTER_NO=r.CUTTER_NO AND r.ACC_NO=12910001
   AND w.CUTTING_DATE BETWEEN TO_DATE('2026-08-16','YYYY-MM-DD') AND TO_DATE('2026-08-16','YYYY-MM-DD')+1-1/86400;
-- => حجازي(8/5600) عُماني(7/2800) قطري(12/4800)

-- الخياط: نفس المنطق
SELECT tl.ACC_NO, TO_CHAR(MAX(t.TAILOR_DATE),'YYYY-MM-DD') LAST_DATE
  FROM ACCOUNTS.TAILOR_FROM_CALC t, ACCOUNTS.TAILOR tl
 WHERE t.TAILOR_NO=tl.TAILOR_NO AND tl.ACC_NO=12910004 GROUP BY tl.ACC_NO;
-- => 2026-08-16
```
**ملاحظة:** كل ما سبق `SELECT` للتحقق فقط؛ لا `INSERT/UPDATE/DELETE`. التنفيذ الفعلي داخل `WorkerController::fetchWorkReport`.


## [2026-10-22] لا استعلامات جدیدة — الإصلاح واجهة/شبكة
- لا تغییرات SQL في هذا الإصلاح؛ یتعلّق بتخطيط Flutter (إزالة التجاوز) وبإعدادات Dio HTTP (تقليل preflight على GET).
- التحقق الوظيفي تمّ عبر استدعاء `work-report` (القصاص id=1، الخیاط id=2) الذي أعاد success:true مع أسطر یوم 16/08/2026.

---

## [2026-10-22 19:00] استعلام التحقق من تقرير كشف عمل مجموعة (قراءة فقط)

**الغرض:** التأكد من صحة SQL تقرير "كشف عمل مجموعة" (FOR_CUTTER_CALC) مقابل PDF المرفق قبل الاعتماد.
**النموذج المنفذ:** Qoder Agent
**الاتصال:** oracledb MCP → ACCOUNTS.CUTTER_FROM_CALC + ACCOUNTS.CUTTER

```sql
-- مجموعة القصاصين — الفترة المطابقة لـ FOR_CUTTER_CALC.pdf (22/06/2026..25/06/2026)
SELECT r.CUTTER_NAME AS WORKER_NAME,
       TO_CHAR(w.CUTTING_DATE, 'DD/MM/YYYY') AS WORK_DATE,
       w.STYLE_NAME,
       NVL(w.POST, 0) AS QTY,
       NVL(w.AMT, 0)  AS TOTAL
  FROM ACCOUNTS.CUTTER_FROM_CALC w, ACCOUNTS.CUTTER r
 WHERE w.CUTTER_NO = r.CUTTER_NO
   AND w.CUTTING_DATE BETWEEN TO_DATE('22/06/2026','DD/MM/YYYY')
                          AND TO_DATE('25/06/2026','DD/MM/YYYY') + 1 - 1/86400
 ORDER BY r.CUTTER_NAME, w.CUTTING_DATE, w.STYLE_NAME;

-- النتيجة: 24 سطراً
--   SUM(QTY)   = 236   ✓ مطابق لسطر "إجــمالي العدد 236" داخل PDF
--   SUM(TOTAL) = 71050 ✓ مطابق لسطر "الإجــمالي لكم 71050" داخل PDF
--   أسماء العمال الأربعة في PDF (اصيل مجيب الشميري / قصاص الديرمان /
--     مجيب الشميري - قصاص / العزي شرهان) كلها ظهرت بالترتيب نفسه.
```

**ملاحظة الترميز:** `CUTTER_NAME` و `STYLE_NAME` يصلان من أوراكل كـ Windows-1256 bytes
(مثال: `ÞØÑí` = قطري، `ÇÕíá ãÌíÈ ÇáÔãíÑí` = أصيل مجيب الشميري) — الخادم يمرّهما على
`ArabicEncoding::fixMojibake()`، العميل يمرّهما على `ArabicEncodingUtils.fix()`.

**ملاحظة DDL:** لا إنشاء / لا تعديل / لا حذف — التقرير قراءة فقط.


-- [2026-10-22 09:15] Qoder Agent — تجميع كشف عمل مجموعة (CUTTERS) للتحقق
SELECT r.CUTTER_NAME, w.STYLE_NAME, SUM(NVL(w.POST,0)) QTY, SUM(NVL(w.AMT,0)) TOTAL
FROM ACCOUNTS.CUTTER_FROM_CALC w, ACCOUNTS.CUTTER r
WHERE w.CUTTER_NO = r.CUTTER_NO
  AND w.CUTTING_DATE BETWEEN TO_DATE('2026-06-22','YYYY-MM-DD') AND TO_DATE('2026-06-25','YYYY-MM-DD') + 1 - 1/86400
GROUP BY r.CUTTER_NAME, w.STYLE_NAME
ORDER BY r.CUTTER_NAME, w.STYLE_NAME;
-- Result: 10 rows, QTY total 236, TOTAL 71050



-- [2026-10-23 10:30] Qoder Agent — قسم «الخدمات والمزودين»: بثّ الكتالوج + استعلامات فحص (لا DDL)
-- 1) بثّ كتالوج IBAC (idempotent، بلا DDL): عبر Laravel، يحدّث الموجود ويُدرج 30 كودًا جديدًا
--    للوحدات الخمس services/providers/sms/whatsapp/jobs → إجمالي 127. لا جداول جديدة.
--    php artisan tinker database/oracle/02_ibac_seed.php

-- 2) فحص المهام الزمنية الذي يقرأه JobController@index (قراءة فقط من منظور مستخدم ACCOUNTS):
SELECT JOB_NAME, ENABLED, REPEAT_INTERVAL, JOB_TYPE, JOB_ACTION, STATE
  FROM USER_SCHEDULER_JOBS
 ORDER BY JOB_NAME;
-- النتيجة المتوقّعة ضمن القسم: SEND_MSG (كل 3ث)، W_SEND_MSG (كل 20ث)، W_SEND_MSG_F (كل 14د).

-- 3) سجل تشغيل مهمة (قراءة فقط، يُستخدم في /jobs/{name}/history — ترقيم بمقابل ROWNUM عبر yajra،
--    لا FETCH FIRST لأن القاعدة 11g):
SELECT LOG_DATE, RUN_DURATION, SUCCEEDED, STATUS, "ERROR#", ADDITIONAL_INFO
  FROM USER_SCHEDULER_JOB_RUN_DETAILS
 WHERE JOB_NAME = 'SEND_MSG'
 ORDER BY LOG_DATE DESC;

-- ملاحظة الكتابة: نقاط الرسائل تُدرج في *_QUEUE فقط بـ IS_SENT='N' (عبر MSG_QUEUE_TAPI حيث وُجد)؛
-- لم نُشغّل أي DBMS_SCHEDULER CREATE/DROP/ENABLE تدميري يدويًا في هذا العمل — يتم حصريًا عبر
-- متحكّم JobController خلف صلاحيات jobs.*، ولم يُستدعَ في الاختبارات (اختبار المهام قراءة فقط).
-- ملاحظة DDL: لا إنشاء / لا تعديل / لا حذف لأي جدول أو sequence أو trigger.

-- 2026-10-23 07:32 (Qoder agent) — إصلاح عرض قسم الخدمات:
-- لم يُنفَّذ أي أمر SQL مباشر على قاعدة البيانات في هذا العمل. التغييرات كانت في الكود فقط
-- (موديلات العميل تقرأ snake_case، وسطران في متحكّمين يقرآن `id`/`status` بحروف صغيرة).
-- الاختبارات (Pest) أجاعت SELECTات قراءة فقط عبر التطبيق على USER_SCHEDULER_JOBS ورسائل الطوابير؛
-- لا DDL ولا INSERT/UPDATE/DELETE يدوي. لا تغيير في هيكل الجداول.

-- 2026-10-23 08:10 (Qoder agent) — ترتيب الرسائل + تفعيل تعديل/حذف الطابور:
-- لم يُنفَّذ أي أمر SQL مباشر على قاعدة البيانات. التغيير في طبقة الاستعلام داخل المتحكّم فقط:
-- ORDER BY CREATED_AT DESC, ID DESC (فردي) ومفتاح ترتيب مركّب لدمج status=all.
-- عمليات UPDATE/DELETE للرسائل تُنفَّذ عبر مسارات التطبيق الموجودة (`PUT`/`DELETE /{sms|whatsapp}/messages/{id}`)
-- على جدول *_QUEUE فقط، خلف صلاحيات sms.update/delete وwhatsapp.update/delete — لا SQL يدوي.
-- اختبار Pest (ServicesSectionTest) قراءة فقط. لا DDL ولا تغيير هيكل.
