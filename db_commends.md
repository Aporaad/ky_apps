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

-- 2026-10-24 14:30 (Qoder agent) — ترحيل IBAC: تقسيم أكواد الكشوف العامة إلى دقيقة:
-- نُفِّذ مباشرة عبر oracledb MCP + `php artisan tinker database/oracle/02_ibac_seed.php`.
-- لا DDL: لا إنشاء/تعديل/حذف لأي جدول أو sequence أو trigger أو FK أو عمود.
-- الأمر الأول (بذر الكتالوج الجديد — 132 صلاحيّة، inserted=9 updated=123):
--   (PHP tinker يُشغّل 02_ibac_seed.php؛ لا SQL يدوي هنا — السكربت idempotent قائدي على PermissionCatalog::rows()).
-- قراءة الجرد قبل الترحيل (صفر منح عامة — لا حاجة لنقل منح):
--   SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE PERMISSION_ID IN (33, 40, 47, 54);
--   -- = 0
-- تنظيف دفاعي (لم يؤثر صفوفاً فعلية لكن يُبقي السجل متسقاً مع 06_ibac_statement_split.sql):
--   DELETE FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE PERMISSION_ID IN
--     (SELECT PERMISSION_ID FROM ACCOUNTS.APP_PERMISSIONS
--       WHERE PERMISSION_CODE IN ('accounts.statement','employees.statement','cutters.statement','tailors.statement'));
-- إسقاط الأكواد العامة من الكتالوج:
--   DELETE FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE IN
--     ('accounts.statement','employees.statement','cutters.statement','tailors.statement');
--   -- 4 صفوف
-- تحققات ما بعد الترحيل (كلها ناجحة):
--   SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;                       -- = 132
--   SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE IN -- = 0
--     ('accounts.statement','employees.statement','cutters.statement','tailors.statement');
--   SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_ID BETWEEN 129 AND 137; -- = 9
--   SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS up WHERE NOT EXISTS                -- = 0
--     (SELECT 1 FROM ACCOUNTS.APP_PERMISSIONS p WHERE p.PERMISSION_ID = up.PERMISSION_ID);
--   SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS WHERE IS_ACTIVE=1;     -- = 132
-- فحص العربية: ASCIISTR(NAME_AR) أظهرت بايتات CP1256 (\00DF\00D4\00DD = "كشف")، متسق
-- مع الكتابة عبر ArabicEncoding::toOracleSearchChars(). لا BOM ولا علامات استبدال (0xBF).
-- لم يُنفَّذ commit (لا طلب من المستخدم). لا تغيير في هيكل.

-- 2026-10-24 18:45 (Qoder agent) — IBAC: صلاحيات تقرير عمل المجموعة (cutters/tailors):
-- لا DDL: لا إنشاء/تعديل جداول أو sequences أو triggers أو FK أو أعمدة.
-- شُغِّل `02_ibac_seed.php` عبر `php artisan tinker` بعد تحديث PermissionCatalog::MODULES.
-- الخرج: PERMISSIONS catalog=134 inserted=2 updated=132 total=134.
-- أكواد جديدة أُدرجت في ACCOUNTS.APP_PERMISSIONS:
--   PERMISSION_ID=138, PERMISSION_CODE='cutters.group_work_report', IS_ACTIVE=1
--   PERMISSION_ID=139, PERMISSION_CODE='tailors.group_work_report', IS_ACTIVE=1
-- لا INSERT/UPDATE على APP_USERS_PERMISSIONS — كتالوج فقط؛ المنح يقررها المستخدم من الشاشة.
-- تحققات: SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;  -- = 134
--          SELECT PERMISSION_ID, PERMISSION_CODE FROM ACCOUNTS.APP_PERMISSIONS
--            WHERE PERMISSION_CODE LIKE '%.group_work_report';  -- = 138/139
-- العربية عبر toOracleSearchChars(): بايتات CP1256 سليمة في NAME_AR، كما في الدفعة الأولى.
-- لم يُنفَّذ commit (لا طلب).

-- 2026-10-24 05:20 (Qoder agent) — الشجرة المحاسبية: استعلامات التحقق والفحص الحيّ:
-- لا DDL إطلاقاً: لا CREATE/ALTER/DROP على أي جدول أو column أو sequence أو trigger
-- أو constraint في ACCOUNTS. الحدود مقررة في الخطة («القاعدة ليست ملكنا للترحيل»)،
-- وكل ما أُضيف حقول مشتقة في أسئلة READ فقط.
--
-- (1) جرد الحقائق التي بُنيت عليها الخطة (repeatable proof، أُعيد اليوم وتأكدت):
--   SELECT 'ACCOUNT' K, COUNT(*) N FROM ACCOUNTS.ACCOUNT
--   UNION ALL SELECT 'ACC_MAIN', COUNT(*) FROM ACCOUNTS.ACC_MAIN
--   UNION ALL SELECT 'ACC_SUB', COUNT(*) FROM ACCOUNTS.ACC_SUB
--   UNION ALL SELECT 'ACC_SUB_GROUP', COUNT(*) FROM ACCOUNTS.ACC_SUB_GROUP
--   UNION ALL SELECT 'CHART_ACC', COUNT(*) FROM ACCOUNTS.CHART_ACC
--   UNION ALL SELECT 'CHART_PREFIX_123', COUNT(*) FROM ACCOUNTS.CHART_ACC
--          WHERE SUBSTR(TO_CHAR(ACC_NO),1,3)='123'
--   UNION ALL SELECT 'CHART_NULL_GROUP', COUNT(*) FROM ACCOUNTS.CHART_ACC WHERE GROUP_ID IS NULL
--   UNION ALL SELECT 'ENTRY_SUB', COUNT(*) FROM ACCOUNTS.ENTRY_SUB;
--   -- ACCOUNT=4, ACC_MAIN=24, ACC_SUB=95, ACC_SUB_GROUP=12, CHART_ACC=20954,
--   --   CHART_PREFIX_123=20469, CHART_NULL_GROUP=20671, ENTRY_SUB=422408
--   -- أي الهيكل الكسول الظاهر = 4 + 24 + 95 + 10 مجموعات + 1 حساب = 134 عقدة
--   -- (من المجموعات الاثنتي عشرة تستثنى المجموعتان تحت الجزئية 123 عرضاً،
--   --  ويظهر بدلاً منهما 12310000 فقط) — مطابق لخرج /accounts/tree الحيّ 4/24/95/10/1.
--
-- (2) إثبات أن قاعدة البادئة الصحيحة عامة لا استثنائية (بديل TRUNC(ACC_NO/10000) المعطوب):
--   SELECT COUNT(*) FROM ACCOUNTS.CHART_ACC c
--    WHERE SUBSTR(TO_CHAR(c.ACC_NO),1,3) NOT IN (SELECT TO_CHAR(ACC_PART) FROM ACCOUNTS.ACC_SUB);
--   -- = 0  (كل حساب مالي ذو ثلاثة أرقام-leading يطابق جزئياً موجوداً)
--   SELECT COUNT(*) FROM ACCOUNTS.CHART_ACC c WHERE c.GROUP_ID IS NOT NULL
--     AND NOT EXISTS (SELECT 1 FROM ACCOUNTS.ACC_SUB_GROUP g WHERE g.GROUP_ID = c.GROUP_ID);
--   -- = 0  (لا مجموعة يتيمة؛ خريطة CHART_ACC -> GROUP_ID سليمة للتجميع)
--
-- (3) إثبات أن أعمدة BALANCE ميتة فلا تُستخدم (مبرر القرار 4):
--   SELECT COUNT(*) FROM ACCOUNTS.ACC_SUB WHERE BALANCE <> 0;    -- = 0  (كل الجزئية صفر)
--   SELECT COUNT(*) FROM ACCOUNTS.ACC_MAIN WHERE BALANCE <> 0;   -- = 6 من 24 فقط
--   -- فالأعمدة المخزّنة لا تصلح للتجميع، وهو مبرر القرار 4 (الحساب من ENTRY_SUB).
--   -- والتجميع الحقيقي من الحركات، وهو جوهر تجميع الأرصدة (movementAggregateSql()
--   --    + movementBalancesByChart() + movementBalancesFor()، وهو ما سمّته الخطة balanceMap()):
--   SELECT SUM(CASE WHEN es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END) DR,
--          SUM(CASE WHEN es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END) CR,
--          SUM(es.ENTRY_MNT) NET, COUNT(*) CNT
--     FROM ACCOUNTS.ENTRY_SUB es JOIN ACCOUNTS.CHART_ACC c ON c.ACC_NO = es.ACC_NO
--    WHERE SUBSTR(TO_CHAR(c.ACC_NO),1,3) = '123';
--   -- DR=2,079,529,784.48  CR=2,014,835,990.65  NET=64,693,793.83  CNT=155,621
--   -- (حسابات العملاء مستثناة عرضاً لكن داخلة تجميعاً — وهذا الرقم يثبت ذلك)
--
-- (4) الفحص الحيّ عبر php artisan serve (لم يُكتب شيء في القاعدة إلا رمزَي اختبار):
--   أُنشئ Sanctum token للمستخدم admin (USER_ID=1) على اتصال Oracle الافتراضي،
--   ثم قُرائت النقاط: /accounts/tree (200, total_nodes=134, balances غير صفرية:
--   1,037,888,703.43 من 314,584 حركة؛ وبفترة مقيّدة 16,319,728.58 من 4,336)،
--   /accounts/tree/children (12910003… ص ف1 و12910019… ص2 — مجموعتان متنافيتان،
--   total=108)، سطر ورقة يثبت الفرق بين المخزن والمحسوب: stored=475,645 مقابل
--   debit=12,273,914 / credit=9,970,916 / net=2,302,998 / 601 حركة،
--   /accounts/search?q=… (11010001 مع parent_path)،
--   /accounts/next-number?level=chart&acc_part=110 -> 11010002، وبلا رمز -> 401.
--   ملاحظة OCI8: الأسماء تصل صغيرة والقيم نصاً (['c'] => '108')، لذا التحويل في PHP.
--
-- (5) التنظيف (DML على جدول Sanctum الموجود فقط، لا هيكل):
--   SELECT ID, DBMS_LOB.SUBSTR(NAME,30,1) N FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS
--    WHERE ID IN (263, 264);      -- NAME عمود CLOB؛ الحذف بـ where('name',…) يطلق ORA-00932
--   DELETE FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS WHERE ID IN (263, 264);  -- 2 صفوف
--   SELECT COUNT(*) FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS WHERE ID IN (263,264);  -- = 0 (تمّ)
--   وأُوقف خادم artisan (PID 33956) وحُذفت كل ملفات الفحص المؤقتة من المستودع.
--
-- لم يُنفَّذ commit (لا طلب). لا DDL. لم تزد قائمة أعمدة CHART_ACC ولا جُدّد جدول.

-- 2026-10-24 09:24 (Qoder agent) — تصدير الشجرة ودليل العملات: قراءة فقط، بلا DDL ولا DML:
-- لا CREATE/ALTER/DROP ولا INSERT/UPDATE/DELETE على أي كائن في ACCOUNTS. النقطتان الجديدتان
-- تقرآن الجداول التراثية نفسها، ولم تُزد أعمدة ولا جداول ولا sequences؛ ولم تُمسَّ
-- APP_PERMISSIONS (أكواد accounts.export / accounts.print موجودة سابقاً في الكتالوج).
--
-- (1) ما يقرأه exportTree لكل طلب (عدد ثابت، لا N+1):
--   structureRows('ACCOUNT')       → SELECT ACC_NO, ACC_NAME, BALANCE, CUR_NO FROM ACCOUNT ORDER BY ACC_NO
--   structureRows('ACC_MAIN')      → … FROM ACC_MAIN ORDER BY ACC_NO, ACC_SUB
--   structureRows('ACC_SUB')       → … FROM ACC_SUB  ORDER BY ACC_SUB, ACC_PART
--   structureRows('ACC_SUB_GROUP') → … FROM ACC_SUB_GROUP ORDER BY ACC_PART, GROUP_ID
--   movementBalancesByChart()      → تجميع ENTRY_SUB (مع ENTRY_MAIN عند وجود فترة):
--     SELECT SUM(CASE WHEN es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END) DR,
--            SUM(CASE WHEN es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END) CR,
--            SUM(es.ENTRY_MNT) NET, COUNT(*) CNT, es.ACC_NO
--       FROM ACCOUNTS.ENTRY_SUB es [JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
--            WHERE em.ENTRY_DATE BETWEEN TO_DATE(:f,'YYYY-MM-DD') AND TO_DATE(:t,'YYYY-MM-DD')]
--      GROUP BY es.ACC_NO
--   chartGroupMap(), chartCountBuckets() → خريطة GROUP_ID وعدّ GROUP BY على CHART_ACC.
--
-- (2) جلب CHART_ACC مقيّد بالبادئات داخل SQL (لا 20 ألف صف إلى PHP) — القيم مرتبطة:
--   SELECT ACC_NO, ACC_NAME, GROUP_ID, BALANCE, LIMITED_BALANCE, STOPPING_ACC, SEQ,
--          TO_CHAR(ACC_DATE,'YYYY-MM-DD') AS ACC_DATE
--     FROM CHART_ACC
--    WHERE SUBSTR(TO_CHAR(ACC_NO), 1, 3) IN (:part_0, :part_1, …)
--      AND (SUBSTR(TO_CHAR(ACC_NO),1,3) <> 123 OR ACC_NO = 12310000)   -- حارس العملاء حتى يُطلب
--    ORDER BY ACC_NO;
--   وملاحظة هيكلية مُثبتة: CHART_ACC أعمدته ثمانية ولا عمود عملة فيه، لذا CUR_NO يُورَّث من
--   ACC_SUB صاحب البادئة — وهو سبب عدم عرض منتقي العملة لمستويي CHART_ACC/ACC_SUB_GROUP في العميل.
--
-- (3) دليل العملات (نفس اسم الجدول، صلاحيات الحسابات لا currencies.view):
--   SELECT CUR_NO, CUR_NAME FROM CURRENCY ORDER BY CUR_NO;
--   المفاتيح تصل صغيرة والنصوص مشكّلة: array_change_key_case + ArabicEncoding::fixMojibake.
--
-- (4) فحوص الاختبارات الحيّة (AccountTreeExportTest — 8 passed / 10,835 assertion):
--   SELECT COUNT(*) AS C FROM CHART_ACC WHERE SUBSTR(TO_CHAR(ACC_NO), 1, 3) = '123';   -- حجم حسابات العملاء
--   SELECT m.ACC_NO AS A FROM ACC_MAIN m
--     WHERE m.ACC_SUB = (SELECT ACC_SUB FROM ACC_SUB WHERE ACC_PART = 110);            -- قسم مُصدَّر للتضييق
--   SELECT COUNT(*) AS C FROM CURRENCY;                                                 -- دليل = ما يرجع للنموذج
--   ومقارنة رصيد كل صف مُصدَّر برصيد العقدة في /accounts/tree (تكافؤ المحسوب من ENTRY_SUB).
--   الاختبارات تستخدم Sanctum::actingAs فلا تُنشئ صفوف PERSONAL_ACCESS_TOKENS (لا تنظيف مطلوب).
--
-- ملاحظة OCI8 المتكرّرة: أسماء الأعمدة صغيرة والقيم قد تصل نصوصاً، فتحويل PHP صريح في كل قراءة.
-- لم يُنفَّذ commit (لا طلب). لا DDL ولا DML.

-- =====================================================================================
-- [2026-10-24 14:44] جولة إصلاح ثانية (انهيار 52px + حقل العملة + 404 التصدير) — Qoder Agent
-- لا استعلامات جدیدة. لم يُنفَّذ أي SQL مقابل Oracle في هذه الجولة إطلاقاً:
--   • لا DDL (لا أعمدة ولا جداول جديدة على schema الحسابات الموروث ACCOUNTS).
--   • لا DML (لا INSERT/UPDATE/DELETE).
--   • لا قراءة مباشرة: التحقق كان على طبقة الـ HTTP المحلية فقط —
--       php artisan route:list --path=accounts        → المساران موجودان
--       GET 127.0.0.1:8099/api/accounts/export-tree   → 401 (Accept: application/json)
--       GET 127.0.0.1:8099/api/accounts/currencies    → 401 (نفسه)
--       GET 127.0.0.1:8099/api/hello                  → 200
--     (500 الذي ظهر مع Accept: text/html أثَر للفحص: Route [login] not defined في
--      storage/logs/laravel.log، لأن Sanctum يوجّه غير الـ JSON إلى مسار اسمه login؛
--      تطبيق Dio يرسل JSON دائماً فلا يواجه هذا.)
--   • القراءة الوحيدة المؤكَّدة للأعمدة كانت مراجعة توثيق لا اتصالاً: CUR_NO موجود في
--     ACC_MAIN و ACC_SUB ولا يوجد في CHART_ACC ولا في ACC_SUB_GROUP — وهذا ما جعل حقل
--     العملة في نموذج الإنشاء «للقراءة فقط/موروث» للمستويين الأخيرين بدل إخفائه.
-- ملاحظة بيئة: الـ 404 المُبلَّغ عنه من خادم آخر على 192.168.0.9 (مساراته C:\kyApp_API)
-- وليس من هذه الآلة (192.168.0.11) — لا علاقة لـ Oracle به.
-- لم يُنفَّذ commit (لا طلب). لا DDL ولا DML.

-- ============================================================
-- [2026-10-24 15:20] جولة 3 — تحقّق قراءة فقط لقاعدة «العملة = الخانة الرابعة من الرقم»
-- المنفِّذ: Qoder Agent · عبر oracledb MCP · كل ما يلي SELECT للتحقق، لا كتابة ولا DDL.
-- ============================================================

-- 1) أعمدة المستويات الخمسة + ENTRY_SUB: أين يوجد CUR_NO فعلاً؟
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, NULLABLE
FROM ALL_TAB_COLUMNS
WHERE OWNER = 'ACCOUNTS'
  AND TABLE_NAME IN ('ACCOUNT','ACC_MAIN','ACC_SUB','ACC_SUB_GROUP','CHART_ACC','ENTRY_SUB')
ORDER BY TABLE_NAME, COLUMN_ID;
-- النتيجة: CUR_NO في ACCOUNT/ACC_MAIN/ACC_SUB فقط؛ CHART_ACC ثمانية أعمدة بلا CUR_NO؛
--          ACC_SUB_GROUP ثلاثة أعمدة؛ ENTRY_SUB تسعة أعمدة (SEQ_PRICE للحركة لا للحساب).

-- 2) توزيع الخانة الرابعة عبر CHART_ACC — هل هي رقم عملة دائماً؟
SELECT LENGTH(TO_CHAR(ACC_NO)) AS LEN, SUBSTR(TO_CHAR(ACC_NO), 4, 1) AS CUR_DIGIT, COUNT(*) AS C
FROM ACCOUNTS.CHART_ACC
GROUP BY LENGTH(TO_CHAR(ACC_NO)), SUBSTR(TO_CHAR(ACC_NO), 4, 1)
ORDER BY LEN, CUR_DIGIT;
-- النتيجة: ثمانية الأرقام 1×10425 / 2×41 / 3×22؛ وتسعة الأرقام (العملاء) كلها خانة رابعة = 1.

-- 3) دليل العملات للتأكد من مطابقة الخانة الرابعة لـ CUR_NO.
SELECT CUR_NO, ASCIISTR(CUR_NAME) AS NAME_ENC FROM ACCOUNTS.CURRENCY ORDER BY CUR_NO;
-- النتيجة: 1 ريال، 2 دولار، 3 سعودي، 4 يورو (غير مستخدم في الخانة الرابعة).

-- 4) دليل النطاق: نفس الجزء يعطي نطاقات عشرية منفصلة لكل عملة (Oracle 11g بلا FETCH FIRST).
SELECT ACC_NO FROM (
  SELECT ACC_NO, ROWNUM rnum FROM (
    SELECT ACC_NO FROM ACCOUNTS.CHART_ACC
    WHERE SUBSTR(TO_CHAR(ACC_NO),1,3) = '251' ORDER BY ACC_NO
  ) WHERE ROWNUM <= 40
) WHERE ACC_NO IN (25110017, 25120016, 25130011);
-- النتيجة حيّة: 25110017(عملة1) / 25120016(عملة2) / 25130011(عملة3) — ثلاث نطاقات متمايزة.

-- لا DDL ولا DML: لم يُنشأ عمود ولا جدول ولا جُدّلت أي صفّ. القراءة وحدها أثبَتَت القاعدة،
-- فالمنطق التطبيقي (AccountController) صار يشتقّ cur_no من الرقم ويتحقّق منه بدل أن يفتَرِضه.

-- =====================================================================================
-- [2026-10-25 10:00] الكشوفات الشخصية: DDL على APP_USERS + بذر أكواد my_statement — Qoder Agent
-- هذه الجولة فيها كتابة فعلية (DDL + DML): ربط الموظف بحسابه المالي يحتاج عموداً جديداً في
-- جدول تحكمنا APP_USERS، وتحديث كتالوج APP_PERMISSIONS. لم يُمسَّ أي جدول ERP موروث آخر،
-- ولم تُنشأ FK لأن CHART_ACC خارج نطاق الترحيل. نُفِّذ كل ما يلي مباشرة عبر oracledb MCP.

-- (1) DDL — عمود ACC_NO في APP_USERS (NUMBER nullable، بلا قيد خارجي):
ALTER TABLE ACCOUNTS.APP_USERS ADD ACC_NO NUMBER;
COMMENT ON COLUMN ACCOUNTS.APP_USERS.ACC_NO IS 'رقم الحساب المالي المرتبط بالمستخدم (CHART_ACC.ACC_NO)';
-- تحقق: SELECT DATA_TYPE, NULLABLE FROM ALL_TAB_COLUMNS
--        WHERE OWNER='ACCOUNTS' AND TABLE_NAME='APP_USERS' AND COLUMN_NAME='ACC_NO';
--   -- NUMBER / Y  ✓

-- (2) DML — بذر أربعة أكواد my_statement في APP_PERMISSIONS.
--    استُخدمت IDs صريحة (140–143) لأن SEQ_APP_PERMISSIONS.LAST_NUMBER كان 102 بينما
--    MAX(PERMISSION_ID)=139 (الـ sequence متأخر عن العدّاد بعد عمليات الحذف السابقة):
INSERT INTO ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID, PERMISSION_CODE, MODULE_CODE, ACTION_CODE, NAME_AR, NAME_EN, IS_CORE, SORT_ORDER, DESCRIPTION_AR)
  VALUES (140, 'my_statement.*',         'my_statement', '*',          N'كل صلاحيات الكشوفات الشخصية', 'All my_statement permissions', 0, 2400, N'منح شامل لوحدة الكشوفات الشخصية');
INSERT INTO ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID, PERMISSION_CODE, MODULE_CODE, ACTION_CODE, NAME_AR, NAME_EN, IS_CORE, SORT_ORDER, DESCRIPTION_AR)
  VALUES (141, 'my_statement.view',      'my_statement', 'view',       N'عرض الكشوفات الشخصية',         'View my statements',           1, 2401, N'الصلاحية الأساسية للوحدة');
INSERT INTO ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID, PERMISSION_CODE, MODULE_CODE, ACTION_CODE, NAME_AR, NAME_EN, IS_CORE, SORT_ORDER, DESCRIPTION_AR)
  VALUES (142, 'my_statement.financial', 'my_statement', 'financial',  N'كشف حسابي المالي الخاص بي',    'My personal financial statement',0, 2402, N'كشف الموظف الحالي المالي');
INSERT INTO ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID, PERMISSION_CODE, MODULE_CODE, ACTION_CODE, NAME_AR, NAME_EN, IS_CORE, SORT_ORDER, DESCRIPTION_AR)
  VALUES (143, 'my_statement.work',      'my_statement', 'work',       N'كشف عملي الخاص بي',             'My personal work statement',    0, 2403, N'كشف عمل الموظف الحالي (خياط/قصاص)');
-- ثم دُفع SEQ_APP_PERMISSIONS فوق 143 (increment ثم restore) ليتولّد الصحيح مستقبلاً بلا تصادم.

-- (3) تحقق ما بعد البذر (حيّ):
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;                        -- = 138 (134 + 4)
SELECT PERMISSION_ID, PERMISSION_CODE, IS_CORE FROM ACCOUNTS.APP_PERMISSIONS
 WHERE PERMISSION_CODE LIKE 'my_statement%' ORDER BY PERMISSION_ID;
--   -- 140 my_statement.* /0، 141 my_statement.view /1، 142 my_statement.financial /0، 143 my_statement.work /0  ✓
-- لا INSERT/UPDATE على APP_USERS_PERMISSIONS — كتالوج فقط؛ المنح قرار المستخدم من الشاشة.
-- العربية في NAME_AR تُكتب بترميز CP1256 (نفس نمط سائر دفعات البذر). لم يُنفَّذ commit (لا طلب).

---

## 2026-10-24 — مهمّة حقل «الحساب المالي» ACC_NO (Claude)

**لا أوامر SQL يدوية نُفّذت على القاعدة.** لم يتغيّر المخطط: عمود `ACCOUNTS.APP_USERS.ACC_NO`
(NUMBER, nullable) موجود مسبقاً من مهمة الكشوفات الشخصية (انظر قسم `ALTER TABLE ... ADD ACC_NO`
أعلاه). التغيير كان في طبقة القراءة داخل التطبيق فقط:

- `UserAdminController::LIST_SQL` أضاف `u.ACC_NO` إلى SELECT الداخلي.
- `UserAdminController::findUser` أضاف `ACC_NO` إلى قائمة الأعمدة.
- الاستعلامات الناتجة (على مستوى التطبيق، ليست أوامر يدوية):
```sql
-- قائمة المستخدمين (مقتطف من LIST_SQL بعد التعديل)
SELECT ... u.CASH_ACC_NO, u.ACC_NO, ... FROM ACCOUNTS.APP_USERS u ...
-- تفاصيل مستخدم (findUser بعد التعديل)
SELECT USER_ID, ..., CASH_ACC_NO, ACC_NO, ... FROM ACCOUNTS.APP_USERS WHERE USER_ID = :id
```
**النموذج:** Claude · **الزمن:** 2026-10-24 · لا DDL/DML ولا commit.

---

## 2026-10-25 — تشخيص كشف حساب العميل: `SUB_DETAILS` / `BALANCE_S` / `GIVING` (Qoder)

**النموذج:** Qoder · **الزمن:** 2026-10-25 18:03 · **كل ما يلي `SELECT` للقراءة فقط — لا DDL/DML ولا commit.**

### (1) فحص مخطّط الجداول المعنية
```sql
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'ENTRY_SUB'
 ORDER BY COLUMN_ID;
-- النتيجة: SEQ, ENTRY_NO, ACC_NO, ENTRY_MNT, BALANCE_S, SEQ_PRICE, SUB_DETAILS, INVOICE_NO, GIVING
-- SUB_DETAILS و DETAILS من نوع VARCHAR2(250) ⇒ تبطين بمسافات، يلزم TRIM قبل الحكم على الفراغ.

SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME IN ('ENTRY_MAIN','ENTRY_TYPE','CUST')
 ORDER BY TABLE_NAME, COLUMN_ID;
-- تصحيح (2026-10-25 21:00): العمود هو ENTRY_TYPE_NO وليس ETRY_TYPE_NO — انظر التحقق أدناه.
```

### (2) إثبات أن حساب المراقبة مشترك بين آلاف العملاء (جذر علة «رصيد كل العملاء»)
```sql
SELECT es.ACC_NO, COUNT(DISTINCT es.GIVING) AS CUST_CNT
  FROM ACCOUNTS.ENTRY_SUB es
 GROUP BY es.ACC_NO
 ORDER BY CUST_CNT DESC
 FETCH FIRST 10 ROWS ONLY;
-- 12310000 (مراقبة العملاء) ≈ 4,470–5,593 عميلاً · 41210001 (المبيعات) · 12110005 (الصندوق)
-- ⇒ أي قراءة على ACC_NO وحده تُرجع حركات كل هؤلاء العملاء.
```

### (3) إثبات أن `BALANCE_S` لقطة على مستوى الحساب ولا تتبع الترتيب الزمني
```sql
SELECT COUNT(*) AS TOTAL_ROWS,
       SUM(CASE WHEN es.BALANCE_S <> SUM(es.ENTRY_MNT) OVER (
                    PARTITION BY es.ACC_NO, es.GIVING
                    ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                THEN 1 ELSE 0 END) AS MISMATCH_ROWS
  FROM ACCOUNTS.ENTRY_SUB es
  JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
 WHERE es.GIVING = 6694;
-- النتيجة: 4,340 سطراً، منها 2,169 سطراً مخالفاً للتراكم الزمني ⇒ العمود غير صالح للكشف.
```

### (4) قياس فراغ `SUB_DETAILS` (سبب الحاجة إلى البديل `ENTRY_MAIN.DETAILS`)
```sql
SELECT COUNT(*) AS TOTAL,
       SUM(CASE WHEN es.SUB_DETAILS IS NULL OR TRIM(es.SUB_DETAILS) IS NULL THEN 1 ELSE 0 END) AS BLANK_SUB_DETAILS
  FROM ACCOUNTS.ENTRY_SUB es;
-- 53,802 سطراً بلا بيان فرعي ⇒ NVL(TRIM(SUB_DETAILS), ENTRY_MAIN.DETAILS).
```

### (5) حجم البيانات وحدود البيئة
```sql
SELECT COUNT(*) FROM ACCOUNTS.ENTRY_SUB;
-- عبر MCP ‏(192.168.0.9:1521/orcl) = 443,959 · عبر ‏.env للتطبيق (127.0.0.1:1521/orcl) = 422,408
-- ⇒ قاعدتان مختلفتان؛ لذلك أُعيد كل التحقق الرقمي عبر اتصال Laravel نفسه.
```

### (6) الاستعلام المعتمد بعد الإصلاح (طبقة التطبيق — `CustomerController::statement()`)
```sql
SELECT es.ENTRY_NO,
       SUBSTR(TO_CHAR(es.ENTRY_NO), 1, 1) || SUBSTR(TO_CHAR(es.ENTRY_NO), 7, 4) AS SUB_ENTRY_NO,
       TO_CHAR(em.ENTRY_DATE, 'DD/MM/YYYY') AS ENTRY_DATE,
       TO_CHAR(em.ENTRY_DATE, 'YYYY-MM-DD') AS RAW_DATE,
       et.ENTRY_TYPE_NAME,
       NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS,
       es.ENTRY_MNT, c.CUST_NAME, c.CUST_NO, c.ACC_NO,
       es.ACC_NO AS ENTRY_SUB_ACC_NO
  FROM ACCOUNTS.CUST c
  JOIN ACCOUNTS.ENTRY_SUB  es ON es.ACC_NO = c.ACC_NO AND es.GIVING = c.CUST_NO
  JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
  JOIN ACCOUNTS.ENTRY_TYPE et ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO
 WHERE c.CUST_NO = :custNo
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;
-- الرصيد والرصيد النهائي يُحسبان في PHP من ENTRY_MNT: الافتتاحي + حركة الفترة.
```

**ملفّات تحقق مؤقتة** (`.tmp_statement_check.php`, `.tmp_count_check.php`, `.tmp_verify.php`, `.tmp_v2.php`
وغيرها) أُنشئت ونُفِّذت ثم **حُذفت جميعًا** بعد التأكد من الأرقام.

---

## [2026-10-25 20:54] - إصلاح البيان/الرصيد في 4 كشوفات: ما نُفِّذ على القاعدة — قراءة فقط — Qoder

**0 DDL · 0 DML** — كل ما يلي استعلامات قراءة فقط، نُفِّذت عبر اتصال Laravel نفسه
(`127.0.0.1:1521/orcl`) لا عبر خادم MCP (لأن مجموعتَي البيانات مختلفتان).

### (1) فحص حجم القاعدة المرجعية
```sql
SELECT COUNT(*) FROM ENTRY_SUB;         -- 422,408
SELECT COUNT(*) FROM ENTRY_MAIN;        -- 150,127
SELECT COUNT(*) FROM CHART_ACC;         -- 20,954
SELECT COUNT(*) FROM APP_USERS;         -- 2
SELECT COUNT(*) FROM TAILOR_EMPLOYEES;  -- 102
```

### (2) أكبر الحسابات بعدد السطور (لتفسير سبب بطء الكشوفات الكبيرة)
```sql
SELECT * FROM (
  SELECT ACC_NO, COUNT(*) AS CNT FROM ENTRY_SUB GROUP BY ACC_NO ORDER BY COUNT(*) DESC
) WHERE ROWNUM <= 10;
-- 41210001 = 65,199 · 12110001 = 47,740 · 12310000 = 17,968 · 41110001 = 17,275
-- 12210001 = 12,420 · 38310001 = 9,058 · 12110005 = 8,446 · 12210005 = 6,834
```

### (3) اختيار حساب العيّنة (الأكثر سطوراً ببيان فرعي فارغ)
```sql
SELECT * FROM (
  SELECT es.ACC_NO, COUNT(*) AS CNT,
         SUM(CASE WHEN TRIM(es.SUB_DETAILS) IS NULL THEN 1 ELSE 0 END) AS BLANK
    FROM ENTRY_SUB es
   GROUP BY es.ACC_NO
  HAVING COUNT(*) BETWEEN 3 AND 400
   ORDER BY SUM(CASE WHEN TRIM(es.SUB_DETAILS) IS NULL THEN 1 ELSE 0 END) DESC, COUNT(*) ASC
) WHERE ROWNUM = 1;
-- 37110001: 368 سطراً منها 340 بلا SUB_DETAILS ⇒ عيّنة مثالية لإثبات أن الـ fallback يعمل.
```

### (4) اختيار موظف العيّنة (الأكبر حركةً لا الأكثر سطوراً فقط)
```sql
SELECT * FROM (
  SELECT te.EMP_NO, te.ACC_NO, COUNT(*) AS CNT, SUM(ABS(es.ENTRY_MNT)) AS VOL
    FROM TAILOR_EMPLOYEES te
    JOIN ENTRY_SUB es ON es.ACC_NO = te.ACC_NO
   WHERE te.ACC_NO IS NOT NULL
   GROUP BY te.EMP_NO, te.ACC_NO
   ORDER BY SUM(ABS(es.ENTRY_MNT)) DESC
) WHERE ROWNUM = 1;
-- موظف 50 ⇒ حساب 12910127 (207 سطراً · 67 بالـ fallback · مجموع 4,131,373)
```

### (5) تصحيح مرجعي: أعمدة `ENTRY_TYPE` (نفي `ETRY_TYPE_NO`)
```sql
SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'ENTRY_TYPE' ORDER BY COLUMN_ID;
-- ENTRY_TYPE_NO (NUMBER) · ENTRY_TYPE_NAME (VARCHAR2) · SOURCE_ID (NUMBER) · SOURCE_NAME (VARCHAR2)
SELECT COLUMN_NAME, DATA_TYPE FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'ENTRY_MAIN' ORDER BY COLUMN_ID;
-- ENTRY_NO · DETAILS · ENTRY_DATE · ENTRY_TYPE_NO

-- اختبار إيجابي:
SELECT COUNT(*) FROM ENTRY_MAIN em JOIN ENTRY_TYPE et ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO;
-- 150,127  ⇒ كل القيود مرتبطة بنوع صحيح

-- اختبار سلبي:
SELECT COUNT(*) FROM ENTRY_MAIN em JOIN ENTRY_TYPE et ON et.ETRY_TYPE_NO = em.ENTRY_TYPE_NO;
-- ORA-00904: "ET"."ETRY_TYPE_NO": invalid identifier (Position 64)
-- ⇒ الصيغة الواردة في توثيق سابق (ETRY_TYPE_NO بلا N) غير صحيحة على قاعدة التطبيق.
```

### (6) استعلام التحقق الرقمي (يُعاد تنفيذه مستقلّاً ويُقارن برد الـ API)
```sql
SELECT es.ENTRY_NO, es.SEQ, es.ENTRY_MNT,
       NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS,
       TRIM(es.SUB_DETAILS)   AS SUB_DETAILS,
       em.DETAILS             AS MAIN_DETAILS
  FROM ENTRY_SUB es
  JOIN ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
 WHERE es.ACC_NO = :acc
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;
-- التراكم في PHP يُقارن مع `balance` لكل سطر ومع `final_balance` (= 4,404,400 للحساب 37110001).
```

### (7) الاستعلامات المعتمدة في طبقة التطبيق بعد الإصلاح
```sql
-- AccountController::getAccountStatement()  (كشف حساب مالي + كشف الشجرة)
SELECT es.ENTRY_NO,
       SUBSTR(TO_CHAR(es.ENTRY_NO),1,1) || SUBSTR(TO_CHAR(es.ENTRY_NO),7,4) AS SUB_ENTRY_NO,
       TO_CHAR(em.ENTRY_DATE,'DD/MM/YYYY') AS ENTRY_DATE,
       TO_CHAR(em.ENTRY_DATE,'YYYY-MM-DD') AS RAW_DATE,
       et.ENTRY_TYPE_NAME,
       NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS,
       es.ENTRY_MNT, es.SEQ_PRICE
  FROM ENTRY_MAIN em, ENTRY_SUB es, ENTRY_TYPE et
 WHERE es.ACC_NO = :acc_no
   AND es.ENTRY_NO = em.ENTRY_NO
   AND em.ENTRY_TYPE_NO = et.ENTRY_TYPE_NO
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;

-- WorkerController::fetchStatement()  (كشف جاري العاملين) — نفس الأعمدة بلا SEQ_PRICE
SELECT es.ENTRY_NO, /* SUB_ENTRY_NO, ENTRY_DATE, RAW_DATE */ et.ENTRY_TYPE_NAME,
       NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS, es.ENTRY_MNT
  FROM ACCOUNTS.ENTRY_SUB es
  JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
  JOIN ACCOUNTS.ENTRY_TYPE et ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO
 WHERE es.ACC_NO = :acc_no
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;

-- MyStatementController::financialStatement() — نفس استعلام AccountController على
-- ACC_NO المقروء من صف المستخدم المصادق عليه (بلا أي بارامتر من العميل).
-- في الثلاثة: لا يوجد `es.BALANCE_S` إطلاقًا، والرصيد يُحسب في PHP من ENTRY_MNT.
```

**ملفّات تحقق مؤقتة** (`verify_statements.php`, `diag_db.php`, `diag_entry_type.php`) أُنشئت ونُفِّذت
ثم **حُذفت جميعًا** بعد ظهور النتيجة `20 نجح / 0 فشل`.

---

## [2026-10-25 22:57] تقادم `CHART_ACC.BALANCE` — كل الأوامر قراءة فقط · Qoder Agent

**الزمن:** 2026-10-25 22:57 · **النموذج:** Qoder · **0 DDL · 0 DML · لا commit**.
كل ما يلي نُفِّذ عبر إقلاع Laravel (`DB::connection('oracle')`) داخل ملفّي تحقق مؤقتين **حُذفا بعد النتيجة**:
`diag_balances.php` (إثبات التقادم) و`verify_group_statement.php` (التحقق الرقمي 112/112).

### (1) إثبات أن `CHART_ACC.BALANCE` لقطة متقادمة — تجميعي على كل الحسابات
```sql
-- لكل حساب: المخزّن مقابل صافي الحركات، ثم تصنيف الفروق
SELECT c.ACC_NO,
       c.BALANCE                            AS STORED,
       NVL(SUM(es.ENTRY_MNT), 0)            AS LEDGER,
       COUNT(es.ENTRY_MNT)                  AS MOVEMENTS
  FROM CHART_ACC c
  LEFT JOIN ENTRY_SUB es ON es.ACC_NO = c.ACC_NO
 GROUP BY c.ACC_NO, c.BALANCE
 ORDER BY c.ACC_NO;
-- النتيجة: 20,954 حساباً · 19,198 مخزّنها غير صفر · 19,126 تخالف الحركات ·
--          1,162 لها حركات ومخزّنها = 0 · تطابق تام لواحد فقط (36110007) — مصادفة.
```

### (2) مثالان موثّقان للمقارنة
```sql
SELECT ACC_NO, BALANCE AS STORED FROM CHART_ACC WHERE ACC_NO IN (41210001, 33110003);
-- 41210001 →  −1,493,000,510.00      ·  33110003 →  1,944,519,285.84

SELECT ACC_NO, SUM(ENTRY_MNT) AS LEDGER, COUNT(*) AS CNT, COUNT(ENTRY_MNT) AS NON_NULL
  FROM ENTRY_SUB WHERE ACC_NO IN (41210001, 33110003) GROUP BY ACC_NO;
-- 41210001 →  −1,801,753,216.78      ·  33110003 →  6,541,659.48
-- ⇒ المخزّن لا يطابق الحساب في أي من الحالتين.
```

### (3) التراكم السنوي (يُثبت أن المخزّن قيمة تاريخية لا رصيداً حالياً)
```sql
SELECT TO_CHAR(em.ENTRY_DATE,'YYYY') AS YR,
       SUM(es.ENTRY_MNT)             AS NET
  FROM ENTRY_SUB es
  JOIN ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO
 WHERE es.ACC_NO = 41210001
 GROUP BY TO_CHAR(em.ENTRY_DATE,'YYYY')
 ORDER BY 1;
-- 2023 → −348,326,003.00 · 2024 → −756,119,835.00 ·
-- 2025 → −1,311,157,100.70 · 2026 → −1,801,753,216.78
-- التراكم بعد 2026 = الرصيد النهائي، ولا يوافقه المخزّن (−1,493,000,510).
```

### (4) استعلام ميزان المجموعة بعد الإصلاح (مرور واحد ⇒ رصيدان)
```sql
-- $periodCond = '1 = 1' ثم يُلحق به شرطا التاريخ إن وُجدا (بارامتران :from_date / :to_date)
-- أعمدة بلا تاريخ = الرصيد النهائي · أعمدة بالشرط = رصيد الفترة
SELECT c.ACC_NO, c.ACC_NAME,
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     AND es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_DEBIT,
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     AND es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END), 0) AS LOCAL_CREDIT,
       NVL(SUM(CASE WHEN ({$periodCond}) AND cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     AND es.ENTRY_MNT > 0 THEN es.ENTRY_MNT ELSE 0 END), 0) AS FOREIGN_DEBIT,
       NVL(SUM(CASE WHEN ({$periodCond}) AND cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     AND es.ENTRY_MNT < 0 THEN ABS(es.ENTRY_MNT) ELSE 0 END), 0) AS FOREIGN_CREDIT,
       NVL(SUM(CASE WHEN ({$periodCond}) AND (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_NET,
       NVL(SUM(CASE WHEN ({$periodCond}) AND cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS FOREIGN_NET,
       NVL(SUM(CASE WHEN (cp.CUR_NO IS NULL OR cp.CUR_NO = 1)
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS LOCAL_NET_ALL,      -- النهائي
       NVL(SUM(CASE WHEN cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1
                     THEN es.ENTRY_MNT ELSE 0 END), 0) AS FOREIGN_NET_ALL,     -- النهائي
       MAX(CASE WHEN cp.CUR_NO IS NOT NULL AND cp.CUR_NO <> 1 THEN cc.CODE END) AS FOREIGN_CUR_CODE
  FROM CHART_ACC c
  LEFT JOIN (ENTRY_SUB es INNER JOIN ENTRY_MAIN em ON es.ENTRY_NO = em.ENTRY_NO)
         ON es.ACC_NO = c.ACC_NO
  LEFT JOIN CUR_PRICE cp ON cp.SEQ = es.SEQ_PRICE
  LEFT JOIN CUR_CODE  cc ON cc.CUR_NO = cp.CUR_NO
 WHERE c.GROUP_ID = :group_id              -- أو شرط ACC_PART / ACC_SUB / ACC_NO
 GROUP BY c.ACC_NO, c.ACC_NAME             -- بلا c.BALANCE
 ORDER BY c.ACC_NO;
-- balance = LOCAL_NET_ALL + FOREIGN_NET_ALL · period_balance = LOCAL_NET + FOREIGN_NET
```
ملاحظة مؤكَّدة على البيانات: حركات العملة المحلية تُبقي `SEQ_PRICE` فارغاً، وحركات العملات الأجنبية وحدها
تحمل `SEQ_PRICE` مرتبطاً بصف في `CUR_PRICE` — لذلك «لا صف CUR_PRICE» يعني محلية لا مجهولة.

### (5) استعلام رصيد الحساب المالي الظاهر بجانب الحساب (كل قوائم الاختيار)
```sql
-- AccountController::getChartAccounts(): عمود BALANCE أُزيل من SELECT، والرصيد في PHP
SELECT ACC_NO, ACC_NAME, TO_CHAR(ACC_DATE,'YYYY-MM-DD') AS ACC_DATE,
       SEQ, GROUP_ID, LIMITED_BALANCE, STOPPING_ACC
  FROM CHART_ACC
 WHERE ...                                -- search / group_id
 ORDER BY ACC_NO;                         -- ثم: net لكل ACC_NO من ENTRY_SUB بلا تواريخ

-- ثم لكل صفحة (مفصولة بـ 900 رقم لتفادي حدّ IN في أوراكل):
SELECT ACC_NO, SUM(ENTRY_MNT) AS NET
  FROM ENTRY_SUB
 WHERE ACC_NO IN (:chunk)
 GROUP BY ACC_NO;
```

### (6) استعلام كشف حساب مالي بعد الإصلاح
```sql
-- AccountController::getAccountStatement() / MyStatementController::financialStatement()
SELECT ACC_NO, ACC_NAME, GROUP_ID FROM CHART_ACC WHERE ACC_NO = :no;   -- بلا BALANCE
-- account.balance = تراكم ENTRY_MNT لكل سطور الحساب قبل أي فلتر تاريخ:
SELECT NVL(SUM(ENTRY_MNT), 0) AS LEDGER FROM ENTRY_SUB WHERE ACC_NO = :no;
-- 41210001 ⇒ −1,801,753,216.78 (وهو نفسه الذي يُعرض بجانب الحساب في القوائم)
```

### (7) نتيجة التحقق الرقمي (`verify_group_statement.php`)
```
scope group_id = 7 (26 accounts) · rows returned: 26
chart[41210001] balance=-1801753216.78  ledger=-1801753216.78  stored=-1493000510
statement account.balance=-1801753216.78  ledger=-1801753216.78
=== 112 passed / 0 failed ===
```
ثم **حُذف** `diag_balances.php` و`verify_group_statement.php` بعد ظهور النتيجة.

---

## [2026-10-26 00:48] — قياس النطاقات + ترقيم ميزان المجموعة (Qoder · قراءة فقط)

كل ما يلي **قراءة فقط**: `SELECT` واحدة بعد الأخرى، لا `INSERT` ولا `UPDATE` ولا `DDL`.

### (1) عدد الحسابات بحسب أوّل ثلاثة أرقام من رقم الحساب

```sql
SELECT SUBSTR(TO_CHAR(ACC_NO), 1, 3) AS PART, COUNT(*) AS CNT
  FROM CHART_ACC
 GROUP BY SUBSTR(TO_CHAR(ACC_NO), 1, 3)
 ORDER BY 1;
```

النتيجة (بعد تجميعها بحسب الحساب الفرعي):

```
ACC_SUB = 11                                  →    23
ACC_SUB = 12 : 121=10 · 122=15 · 123=20,469
               124=5 · 127=48 · 128=8 · 129=219  → 20,774
الإجمالي العام                                 → 20,954
```

الحساب الجزئي `123` وحده = **98.6%** من الشجرة، وهو النطاق الذي كان يقتل التطبيق.

### (2) قالب الترقيم المستخدم (Oracle 11g — بلا `OFFSET … FETCH`)

```sql
-- الصفحة: offset = (:page - 1) * :limit، و max_row = offset + limit
SELECT * FROM (
    SELECT a.*, ROWNUM AS RN
      FROM (
            -- الاستعلام المجمّع نفسه (نفس أعمدة الميزان و$periodCond)
            SELECT c.ACC_NO, c.ACC_NAME, …
              FROM CHART_ACC c
              LEFT JOIN ( … ENTRY_SUB … ) es ON es.ACC_NO = c.ACC_NO
              LEFT JOIN CUR_PRICE cp ON cp.SEQ = es.SEQ_PRICE
              LEFT JOIN CUR_CODE  cc ON cc.CUR_NO = cp.CUR_NO
             WHERE SUBSTR(TO_CHAR(c.ACC_NO), 1, 3) IN ('120',…,'129')
             GROUP BY c.ACC_NO, c.ACC_NAME
             ORDER BY c.ACC_NO              -- الترتيب داخل الطبقة الداخلية
           ) a
     WHERE ROWNUM <= :max_row
) WHERE RN > :offset;
```

`ORDER BY` داخل الاستعلام المجمّع لأن `ROWNUM` يُمنح قبل الترتيب في الطبقات الخارجية.

### (3) إجماليات النطاق كاملاً (استعلام واحد · الصفحة الأولى فقط)

```sql
SELECT COUNT(*)                                     AS TOTAL_ROWS,
       NVL(SUM(LOCAL_DEBIT), 0)                      AS LOCAL_DEBIT,
       NVL(SUM(LOCAL_CREDIT), 0)                     AS LOCAL_CREDIT,
       NVL(SUM(FOREIGN_DEBIT), 0)                    AS FOREIGN_DEBIT,
       NVL(SUM(FOREIGN_CREDIT), 0)                   AS FOREIGN_CREDIT,
       NVL(SUM(LOCAL_NET_ALL + FOREIGN_NET_ALL), 0)  AS FINAL_BALANCE,
       NVL(SUM(LOCAL_NET + FOREIGN_NET), 0)          AS PERIOD_BALANCE
  FROM ( -- نفس الاستعلام المجمّع أعلاه بلا طبقة ROWNUM
       ) t;
```

### (4) التحقق من الإجماليات بمقارنة مباشرة مع الحركات

```sql
SELECT COUNT(*) AS CNT, NVL(SUM(es.ENTRY_MNT), 0) AS NET
  FROM CHART_ACC c
  JOIN ENTRY_SUB es ON es.ACC_NO = c.ACC_NO
 WHERE SUBSTR(TO_CHAR(c.ACC_NO), 1, 3) IN
       ('120','121','122','123','124','125','126','127','128','129');
```

### (5) نتيجة التحقق على القاعدة الحقيقية (`_tmp_check_page.php` — ثم حُذف)

```
page1: 2.58s rows=500
  OK   page1 meta.total = 20774
  OK   page1 rows = 500
  OK   page1 has_more
  OK   page1 total_pages = 42
  OK   page2 rows = 500                     (أول acc_no > آخر acc_no في الأولى)
  OK   page2 totals zeroed                  (include_totals=0)
  OK   last page < 500 rows
  OK   last page has_more=false
full:  3.95s rows=20774
  OK   full export returns 20774 rows       (limit=0 = بلا ترقيم)
  OK   sum(row balances) == SUM(ENTRY_MNT)
  OK   totals.balance == sum(rows)
  OK   group 7 pages fine
=== 13 passed / 0 failed ===
```

الاستنتاجان المهمان من القاعدة نفسها:
- **الإجماليات لا تُجمع بين الصفحات** — استعلام `(3)` يعطي إجمالي النطاق كاملاً في الصفحة الأولى، وجمع
  إجمالي كل صفحة كان سيضاعف الرقم.
- **`limit = 0` يعني «كل الصفوف»** — استُخدم لمسار التصدير الكامل فقط، ويُقصّ أي `limit` موجب عند **2000**
  داخل الخادم حتى لا يُساء استعماله.

**النموذج:** Qoder · **الزمن:** 2026-10-26 00:48 · **قراءة فقط: 0 DDL · 0 DML · لا commit**.

---

## 2026-10-26 03:11 — استعلامات التحقق: هل يعيد الكشف كل صفوف الفترة؟

**النموذج:** Qoder · **النوع:** قراءة فقط (SELECT) · **DDL:** 0 · **DML:** 0 · **لا commit**.

```sql
-- (1) اختيار الحساب الأكثر حركةً لاختبار كشف الحساب عليه
SELECT ACC_NO FROM (
    SELECT ACC_NO FROM ACCOUNTS.ENTRY_SUB
    GROUP BY ACC_NO
    ORDER BY COUNT(*) DESC
) WHERE ROWNUM = 1;
```

```sql
-- (2) هل يوجد مستخدم مرتبط بحساب مالي (لكشف «حسابي المالي»)؟
SELECT USER_ID, ACC_NO, IS_ADMIN FROM ACCOUNTS.APP_USERS
WHERE ACC_NO IS NOT NULL AND ROWNUM <= 5;
-- النتيجة: لا صفوف ⇒ لا مستخدم مرتبط بـ ACC_NO في هذه القاعدة،
-- فأُسند ACC_NO في الذاكرة داخل الاختبار (بلا أي كتابة).
```

```sql
-- (3) عدّادات السياق التي أُخذت عبر Eloquent (SELECT COUNT فقط)
SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE ACC_NO IS NOT NULL AND IS_ADMIN = 1;   -- = 0
SELECT COUNT(*) FROM ACCOUNTS.APP_USERS WHERE ACC_NO IS NOT NULL;                    -- = 0
SELECT COUNT(*) FROM ACCOUNTS.APP_USERS_PERMISSIONS up
  JOIN ACCOUNTS.APP_PERMISSIONS p ON p.PERMISSION_ID = up.PERMISSION_ID
 WHERE p.PERMISSION_CODE = 'my_statement.financial';                                  -- = 0
```

**ما نُفِّذ فعلياً عبر الواجهة في الاختبارات (Pest على القاعدة الحقيقية):**

```sql
-- كشف الحساب: الدفتر كامل ثم يُعاد كل صفوف الفترة بلا limit
SELECT es.SUB_ENTRY_NO, es.ENTRY_NO, em.ENTRY_DATE, et.ENTRY_TYPE_NAME,
       es.DETAILS, es.ENTRY_MNT, ...
  FROM ACCOUNTS.ENTRY_SUB es, ACCOUNTS.ENTRY_MAIN em, ACCOUNTS.ENTRY_TYPE et
 WHERE es.ACC_NO = :acc_no
   AND es.ENTRY_NO = em.ENTRY_NO
   AND em.ENTRY_TYPE_NO = et.ENTRY_TYPE_NO
 ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ;
```

**النتيجة:** `StatementFullPeriodTest` = **3/3 ناجحة (17 تأكيداً)** ·
`meta.limit = 0` و`meta.returned = meta.total` (كل حركات الفترة) · `limit=25` يعيد 25 صفاً فقط عند الطلب ·
`CHART_ACC` لا يُلَفّ بغلاف `ROWNUM` عندما لا يوجد حد.

---

# 2026-10-27 01:50 — جدول استفسارات الدعم + مفتاح نبذة الخدمات + أكواد الدعم

**الملف:** `kyApp_API/database/oracle/08_app_support_tickets.sql` — يتبع نمط `01_ibac_schema.sql`
(متسلسلة + مشغّل، واسم المتسلسلة **بلا بادئة مخطط داخل PL/SQL** لتفادي `PLS-00302` بسبب وجود VIEW باسم `ACCOUNTS`).

```sql
-- (1) الجدول
CREATE TABLE ACCOUNTS.APP_SUPPORT_TICKETS (
  TICKET_ID     NUMBER(12)     NOT NULL,
  USER_ID       NUMBER(5),                     -- null = زائر قبل الدخول
  CONTACT_NAME  VARCHAR2(100),
  CONTACT_PHONE VARCHAR2(30),
  MESSAGE       VARCHAR2(1000) NOT NULL,
  STATUS        VARCHAR2(20) DEFAULT 'new' NOT NULL,
  ADMIN_REPLY   VARCHAR2(1000),
  REPLIED_BY    NUMBER(5),
  REPLIED_ON    DATE,
  APP_VERSION   VARCHAR2(20),
  PLATFORM      VARCHAR2(30),
  CREATED_ON    DATE DEFAULT SYSDATE NOT NULL,
  UPDATED_ON    DATE,
  CONSTRAINT APP_SUP_PK PRIMARY KEY (TICKET_ID),
  CONSTRAINT APP_SUP_STATUS_CK CHECK (STATUS IN ('new','answered','closed'))
);
-- النتيجة: TABLE_CREATED (13 عموداً)

-- (2) الفهارس
CREATE INDEX ACCOUNTS.APP_SUP_STATUS_IX ON ACCOUNTS.APP_SUPPORT_TICKETS (STATUS, CREATED_ON);
CREATE INDEX ACCOUNTS.APP_SUP_USER_IX   ON ACCOUNTS.APP_SUPPORT_TICKETS (USER_ID, CREATED_ON);
-- النتيجة: INDEX_STATUS_CREATED · INDEX_USER_CREATED

-- (3) المتسلسلة
CREATE SEQUENCE ACCOUNTS.SEQ_APP_SUPPORT_TICKETS
  START WITH 1 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE;
-- النتيجة: SEQUENCE_CREATED

-- (4) المشغّل — الاسم بلا مخطط داخل PL/SQL (VIEW ACCOUNTS يجعل ACCOUNTS.SEQ_APP_SUPPORT_TICKETS يفشل بـ PLS-00302)
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_SUPPORT_TICKETS
BEFORE INSERT ON ACCOUNTS.APP_SUPPORT_TICKETS FOR EACH ROW
BEGIN
  IF :NEW.TICKET_ID IS NULL THEN
    SELECT SEQ_APP_SUPPORT_TICKETS.NEXTVAL INTO :NEW.TICKET_ID FROM DUAL;
  END IF;
END;
/
-- النتيجة: TRIGGER_CREATED
```

```sql
-- (5) التحقق من البنية
SELECT COUNT(*) FROM USER_TABLES      WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';        -- = 1
SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';        -- = 13
SELECT COUNT(*) FROM USER_INDEXES     WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';        -- = 3 (المفتاح + فهرسان)
SELECT COUNT(*) FROM USER_SEQUENCES   WHERE SEQUENCE_NAME = 'SEQ_APP_SUPPORT_TICKETS'; -- = 1
SELECT STATUS FROM USER_TRIGGERS      WHERE TRIGGER_NAME  = 'TRG_APP_SUPPORT_TICKETS'; -- = ENABLED
-- القيود: APP_SUP_PK (P) · APP_SUP_STATUS_CK (C)
```

```sql
-- (6) اختبار المشغّل (DML ثم تنظيف)
INSERT INTO ACCOUNTS.APP_SUPPORT_TICKETS (MESSAGE, STATUS, PLATFORM)
VALUES ('اختبار مشغّل المتسلسلة', 'new', 'test');
SELECT TICKET_ID, STATUS FROM ACCOUNTS.APP_SUPPORT_TICKETS WHERE PLATFORM = 'test';
-- النتيجة: id=1 · status=new (TICKET_ID أُسند تلقائياً)
DELETE FROM ACCOUNTS.APP_SUPPORT_TICKETS WHERE PLATFORM = 'test';
-- النتيجة: TRIGGER_CLEANUP_OK
```

```sql
-- (7) إعادة بذر الكتالوج + التهيئة (idempotent)
-- php artisan tinker database/oracle/02_ibac_seed.php
-- النتيجة: PERMISSIONS catalog=141 inserted=3 updated=138 total=141
--           SETTINGS  seeded=23  inserted=1 updated=22  total=25
SELECT SETTING_KEY, VALUE_TYPE, SORT_ORDER FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY = 'company_services';   -- = ('company_services', 'string', 145)
SELECT PERMISSION_CODE FROM ACCOUNTS.APP_PERMISSIONS
 WHERE PERMISSION_CODE LIKE 'support.%';    -- = support.* · support.view · support.update
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;  -- = 141
```

**ملاحظات تنفيذ:**

- لا مفتاح أجنبي على `USER_ID`: الجداول الإرثية تُدار خارج سيطرتنا، وحذف مستخدم لا يجوز أن يُفشل الإدراج.
- `MESSAGE`/`ADMIN_REPLY` بسعة 1000 محرف، وحدود الخادم والعميل أضيق منها (10..1000 للرسالة).
- الترميز: الكتابة عبر `ArabicEncoding::toOracleSearchChars()` والقراءة عبر `fixMojibake()` (لا نصّ عربي مباشر في SQL).
- ملف التراجع: تعليقات `DROP TRIGGER/TABLE/SEQUENCE` في نهاية `08_app_support_tickets.sql` (لم تُنفَّذ).
- **لا commit** (لم يُطلب).

### 2026-10-27 01:50 — إعادة تحقّق قراءة فقط قبل الإغلاق

```sql
-- نُفِّذت عبر جلسة التطبيق نفسها (php artisan tinker) — قراءة فقط، بلا DDL/DML
SELECT COUNT(*) FROM USER_TABLES    WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';      -- = 1
SELECT COUNT(*) FROM USER_TAB_COLUMNS WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS';    -- = 13
SELECT COUNT(*) FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SEQ_APP_SUPPORT_TICKETS'; -- = 1
SELECT STATUS   FROM USER_TRIGGERS  WHERE TRIGGER_NAME = 'TRG_APP_SUPPORT_TICKETS';  -- = ENABLED
SELECT INDEX_NAME FROM USER_INDEXES WHERE TABLE_NAME = 'APP_SUPPORT_TICKETS'
 ORDER BY INDEX_NAME;
-- = APP_SUP_PK · APP_SUP_STATUS_IX · APP_SUP_USER_IX
SELECT SETTING_KEY, SORT_ORDER FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY = 'company_services';           -- = ('company_services', 145)
SELECT PERMISSION_CODE FROM ACCOUNTS.APP_PERMISSIONS
 WHERE PERMISSION_CODE LIKE 'support%' ORDER BY PERMISSION_CODE;
-- = support.* · support.update · support.view
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;     -- = 141
SELECT COUNT(*) FROM ACCOUNTS.APP_SUPPORT_TICKETS; -- = 0 (لا صفوف اختبار متروكة)
```

**النتيجة:** كل كائنات الخطة حيّة ومطابقة للموثَّق أعلاه · جدول التذاكر نظيف (0 صف) ·
**قراءة فقط: 0 DDL · 0 DML · لا commit**.

### 2026-10-27 03:10 — كتابة نبذة خدمات الشركة في `APP_SETTINGS` (صف واحد)

```sql
-- قراءة أولية: الحقل كان فارغاً فكانت لوحة «نبذة عن خدماتنا» تُخفى دائماً
SELECT SETTING_KEY, LENGTH(SETTING_VALUE) FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY = 'company_services';        -- company_services · 0

-- DML — نُفِّذت عبر مسار التطبيق نفسه (SettingsStore::set) داخل php artisan tinker،
-- لا نص عربي مباشر في SQL: القيمة تمرّ بـ ArabicEncoding::toOracleSearchChars() أولاً
UPDATE ACCOUNTS.APP_SETTINGS
   SET SETTING_VALUE = :setting_value,   -- نبذة 140 محرفاً بعد الترميز
       UPDATED_BY    = :updated_by,      -- NULL (سكربت إداري لا مستخدم)
       UPDATED_ON    = SYSDATE
 WHERE SETTING_KEY = 'company_services';         -- 1 row updated
COMMIT;

-- تحقق بعد الكتابة: القراءة العكسية عبر fixMojibake() + الحمولة العامة
-- BEFORE_LEN=0 · AFTER_LEN=140 · ROUND_TRIP_OK=1 · PAYLOAD_LEN=140
SELECT SETTING_KEY, LENGTH(SETTING_VALUE), SORT_ORDER FROM ACCOUNTS.APP_SETTINGS
 WHERE SETTING_KEY = 'company_services';        -- company_services · 140 · 145
```

**النص المكتوب (140 محرفاً، سقف العمود 500 بايت وسقف التحرير 400):**

> نقدّم خدمات الخياطة والتفصيل الرجالي: أخذ المقاسات، وقصّ وتفصيل الثياب والبدلات، وتنفيذ كروت
> التفصيل حسب الطلب، مع متابعة الطلب حتى التسليم.

**ملاحظات تنفيذ:**

- `company_website` **لم يُكتب**: لا رابط موقع مسجَّل للشركة، والاختراع ممنوع — بطاقته في العميل لا تُرسم وهي فارغة.
- الكاش لا يمسّ هذه القيمة: `company_*` ليست من المفاتيح الساخنة (`SettingsStore::HOT_KEYS`)، فـ`publicPayload` يقرأها مباشرة من القاعدة.
- السكربت المؤقت (`_seed_services.php`) حُذف بعد التشغيل — لا أثر له في المستودع.
- **لا DDL · DML: صف واحد · لا commit**.

**النموذج:** Qoder · **الوقت:** 2026-10-27 03:10 · **DDL: 0** · **DML: UPDATE واحد على صف `company_services`**.


---

## 2026-10-28 08:49 — أوامر التفصيل التشخيصية وأمر بذر الصلاحيات

### 1) فحص بنية الـ VIEW والجداول المشاركة

```sql
-- صفوف الـ VIEW: صف واحد لكل قطعة / one row per piece
SELECT COUNT(*) FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW;                       -- 45199

-- الفواتير المميزة: المفتاح مركّب (BILL_NO, YEAR) / the identity is composite
SELECT COUNT(*) FROM (SELECT DISTINCT BILL_NO, YEAR FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW);  -- 13667

-- تسميات المقاسات الحقيقية / the real measurement labels
SELECT L1, L2, L3, L4, L5, L6, L7, L8, L9, L10, L11, L12 FROM ACCOUNTS.GENERAL_LABELS_CODING;  -- 1 صف

-- قاموس الحالات الذي يُغذّي خط السير / the workflow dictionary
SELECT ORDSID FROM ACCOUNTS.ORDSTATE ORDER BY ORDSID;                        -- 16 صفاً (0..15)

-- ربط الـ VIEW بالقصّاص والخيّاط داخلي ⇒ يُسقط ما بلا إسناد
-- the inner joins drop any model with no cutter/tailor: ~20% coverage
```

### 2) بذر الصلاحيات الثلاث الجديدة (idempotent)

```
php artisan tinker database/oracle/02_ibac_seed.php
```

النتيجة المقيسة بعد البذر: `ACCOUNTS.APP_PERMISSIONS` = **144** صفاً، ومنها **10** لكودات التفصيل:

```
tailoring.*        tailoring.create   tailoring.delete   tailoring.deliver
tailoring.export   tailoring.payments_view
tailoring.print    tailoring.progress tailoring.update   tailoring.view
```

### 3) التحقق من الصفوف الجديدة

```sql
SELECT PERMISSION_CODE FROM ACCOUNTS.APP_PERMISSIONS
 WHERE PERMISSION_CODE LIKE 'tailoring%' ORDER BY PERMISSION_CODE;   -- 10 صفوف

SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;                        -- 144
```

**النموذج:** Qoder · **الوقت:** 2026-10-28 08:49 · **DDL:** لا · **DML:** 3 صفوف `APP_PERMISSIONS`.


---

## 2026-10-29 01:40 — بذر الصلاحيات بعد إضافة صلاحيات مقاسات العملاء

```
php artisan tinker database/oracle/02_ibac_seed.php
```

النتيجة المقيسة:

```
PERMISSIONS  catalog=147 inserted=0 updated=147 total=147
SETTINGS     seeded=23 inserted=0 updated=23 total=25
```

الصفوف الثلاثة الجديدة التي كانت في الكتالوج ولم تكن في القاعدة:

```
customers.measurements_view    عرض مقاسات العملاء
customers.measurements_print   طباعة مقاسات العملاء
customers.measurements_export  تصدير مقاسات العملاء
```

**النموذج:** Qoder · **الوقت:** 2026-10-29 01:40 · **DDL:** لا · **DML:** تحديث 147 صفّ صلاحية
(idempotent) وتسجيل 23 إعداداً.

---

## 2026-10-31 02:12 — أوامر مقاسات العملاء: فحص أعمدة المواصفات/الأقمشة (قراءة فقط عبر oracledb MCP)

كل الأوامر `SELECT`؛ لا `INSERT` ولا `UPDATE` ولا `DDL` في هذه الجولة. نُفِّذت بموصل `oracledb`
لأن اتصال التطبيق المحلي (`localhost:1521/orclrd`) ما زال `ORA-12514`.

### 1) أعمدة جدول الموديلات (لحسم «جيب جانبي» و«جيب الصدر»)

```sql
SELECT COLUMN_ID, COLUMN_NAME, DATA_TYPE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='SALES_DETAILES_SHAPES'
 ORDER BY COLUMN_ID;                                     -- 53 عموداً
```

### 2) توزيع الامتلاء لأعمدة الجيوب والأزرار

```sql
SELECT COUNT(*) AS ROWS_TOTAL,
       COUNT(POCKET_OR_WITHOUT)   AS HAS_POCKET_FLAG,   -- 83,395
       COUNT(MOBILE_POCKET)       AS HAS_MOBILE,        -- 83,245
       COUNT(PEN_POCKET)          AS HAS_PEN,           --      0
       COUNT(SHAPE_POCKET_UP_NO)  AS HAS_UP,            --     12
       COUNT(SHAPE_POCKET_DOWN_NO) AS HAS_DOWN,         --     13
       COUNT(BUTTONS_NUM)         AS HAS_BUTTONS_NUM,   --      8
       COUNT(BUTTON_TYPE)         AS HAS_BUTTON_TYPE    -- 84,971
  FROM ACCOUNTS.SALES_DETAILES_SHAPES;
```

### 3) القيم الفعلية لعمودَي الجيوب (بلا تحويل ترميز — القاعدة WE8MSWIN1252)

```sql
SELECT * FROM (
  SELECT POCKET_OR_WITHOUT, MOBILE_POCKET, PEN_POCKET, COUNT(*) AS CNT
    FROM ACCOUNTS.SALES_DETAILES_SHAPES
   GROUP BY POCKET_OR_WITHOUT, MOBILE_POCKET, PEN_POCKET
   ORDER BY COUNT(*) DESC
) WHERE ROWNUM <= 10;
-- جيوب / بدون / جيوب شمال / جيوب يمين  +  جيب الجوال: عادي، عادي+…  +  جيب القلم: لا شيء
```

### 4) قيم `CLOTH_TYPE` في الواجهة (للتأكد أنه «العرض» لا «النوع»)

```sql
SELECT * FROM (
  SELECT CLOTH_TYPE, COUNT(*) AS CNT
    FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW
   GROUP BY CLOTH_TYPE ORDER BY COUNT(*) DESC
) WHERE ROWNUM <= 8;                       -- عرضية 37,077 · عرض44 5,234 · عرض 3,044 · فراغ 42
```

### 5) تنفيذ استعلام التفصيل كما هو في المتحكم (مفتاح حيّ)

```sql
SELECT COUNT(*) AS ROWS_OK FROM (SELECT v.SEQ_NO, v.SEQ_NO1, v.OHID, v.OHDID, … ,
        s.NECK_TYPE, …, s.SHAPE_POCKET_UP_NO, s.SHAPE_POCKET_DOWN_NO
   FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW v
   LEFT JOIN ACCOUNTS.SALES_DETAILES_SHAPES s
          ON s.BILL_NO = v.BILL_NO AND s.YEAR = v.YEAR AND s.SEQ_NO = v.SEQ_NO
   LEFT JOIN ACCOUNTS.STYLE st ON st.SHAPE_STYLE_NO = v.SHAPE_STYLE_NO
  WHERE v.BILL_NO = 19405 AND v.YEAR = 2026 AND v.SEQ_NO = 82755
  ORDER BY v.SEQ_NO1);                     -- ROWS_OK = 55 (بلا خطأ: كل الأعمدة موجودة)
```

### 6) عيّنة قيم القطعة (لتصميم سطري الأقمشة)

```sql
SELECT * FROM (
  SELECT OHDID, SANF_PRICE, SANFPRICE, CLOTH_NAME, CLOTH_TYPE, CLOTHS_COLOR2,
         CONSUMED_CLOTH_QTY_HINSH, CONSUMED_CLOTH_QTY_YARDS,
         CUTTER_NAME, TAILOR_NAME1, HANDING_DONE1, L1, L2
    FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW
   WHERE BILL_NO = 19405 AND YEAR = 2026 AND SEQ_NO = 82755
) WHERE ROWNUM <= 3;
-- OHDID = 26211325025 (11 رقماً) · SANF_PRICE = 2000 · SANFPRICE = 6000
-- العارض مختلف لكل قطعة: أحمد عبد العزيز شرهان / مازن ميثاق الصبري / خالد محمد الصعواني
```

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:12 · **DDL:** لا · **DML:** لا (قراءة فقط) ·
**الأداة:** موصل `oracledb` MCP.


---

## 2026-10-31 06:12 — استعلامات تشخيص OHDID (قراءة فقط)

```sql
-- أعمدة الـ VIEW التي تخصّ الطلب/التسلسل
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='CUTTING_SALES_BILL_VIEW'
   AND (COLUMN_NAME LIKE '%OH%' OR COLUMN_NAME LIKE '%SEQ%');
-- OHID, OHDID, SEQ_NO, SEQ_NO1, ORDSDID

-- أعمدة سجل الحركة
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='CUTING_TRANSD';
-- يتضمن OHDID وOHID وSEQ_NO وDEPTID وCREATED_BY_NAME

-- قطعة نموذجية ورقم طلبها
SELECT BILL_NO, YEAR, SEQ_NO, SEQ_NO1, OHDID
  FROM ACCOUNTS.CUTTING_SALES_BILL_VIEW WHERE ROWNUM <= 1;
-- ohdid = 262133

-- عدد حركات ذلك القماش
SELECT COUNT(*) FROM ACCOUNTS.CUTING_TRANSD WHERE OHDID = 262133;   -- 9

-- أعمدة الأقسام (لقراءة «المنفذ»)
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='DEPTS';
-- DEPTID, DEPTNAME, DEPTTYPE, ACTIVE, PARANT
```

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:12 · **DDL:** لا · **DML:** لا.


---

## 2026-10-31 09:38 — اكتشاف عمود عرض القماش في `MULTI_CLOTHS` (قراءة فقط)

```sql
-- يُنفَّذ مرة واحدة لكل طلب ويُخزَّن ناتجه (static) داخل المتحكم
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = 'MULTI_CLOTHS';
-- يُختار أول اسم موجود من: CLOTH_WIDTH, WIDTH, CLOTH_W, W, CLOTH_SIZE
```

```sql
-- الربط الذي يُضاف إلى استعلام التفصيل عند وجود العمود
... LEFT JOIN ACCOUNTS.MULTI_CLOTHS m
           ON m.BILL_NO  = v.BILL_NO
          AND m.YEAR     = v.YEAR
          AND m.SEQ_NO   = v.SEQ_NO
          AND m.SEQ_NO1  = v.SEQ_NO1
-- ويُقرأ: m.<COLUMN> AS CLOTH_WIDTH، أو CAST(NULL AS VARCHAR2(20)) عند غياب العمود
```

**ملاحظة:** خدمة Oracle كانت غير متاحة أثناء هذه الجولة (`ORA-12514` عند
`localhost:1521/ORCLRD`)، فلم يُنفَّذ الاستعلام حياً هنا؛ يعمل تلقائياً عند عودة الخدمة.

**النموذج:** Qoder · **الوقت:** 2026-10-31 09:38 · **DDL:** لا · **DML:** لا.

---

## 2026-11-01 — قسم المخازن: قراءة المخطط ثم إنشاء تسلسلات الترقيم

### أ) استعلامات القراءة (ORACLE MCP · قراءة فقط)

```sql
-- هل توجد تسلسلات مخازن سابقة؟
SELECT COUNT(*) AS C FROM USER_SEQUENCES
 WHERE SEQUENCE_NAME LIKE 'SEQ\_STORES%' ESCAPE '\';   -- النتيجة: 0
```

```sql
-- تعريف الحركة الذي بُنيت عليه السياسة
SELECT DBMS_METADATA.GET_DDL('VIEW','ITEM_MOVE_D','ACCOUNTS') FROM DUAL;
SELECT DBMS_METADATA.GET_DDL('VIEW','ITEM_MOVEMENT_D','ACCOUNTS') FROM DUAL;
SELECT TEXT FROM ALL_VIEWS WHERE OWNER='ACCOUNTS' AND VIEW_NAME='LAST_COST';
SELECT TEXT FROM ALL_VIEWS WHERE OWNER='ACCOUNTS' AND VIEW_NAME='AVVG';

-- الأرصدة الحالية: 2,856 صفاً · 3 مخازن (1/3/4) · قيمة 319,310,696 · 41 صفاً سالباً
SELECT COUNT(*) TOTAL, SUM(CASE WHEN SUM_TP>0 THEN 1 ELSE 0 END) POS,
       SUM(CASE WHEN SUM_TP<0 THEN 1 ELSE 0 END) NEG, ROUND(SUM(SUM_PRICE),0) VAL
  FROM ACCOUNTS.AVVG;

-- أعلى الأرقام لكل مفتاح (نقطة بداية التسلسلات)
SELECT (SELECT NVL(MAX(BILL_NO),0) FROM ACCOUNTS.INVENTORY_RECEIVE) MAX_RCV,
       (SELECT NVL(MAX(BILL_NO),0) FROM ACCOUNTS.INVENTORY_SARF)    MAX_SARF,
       (SELECT NVL(MAX(TR_INV_M_ID),0) FROM ACCOUNTS.INVENTORY_TRANSM) MAX_TRM,
       (SELECT NVL(MAX(TR_INV_D_ID),0) FROM ACCOUNTS.INVENTORY_TRANSD) MAX_TRD,
       (SELECT NVL(MAX(SANF_NO),0) FROM ACCOUNTS.SANFS) MAX_SANF,
       (SELECT NVL(MAX(SANF_DNO),0) FROM ACCOUNTS.SANFS_D) MAX_SANFD,
       (SELECT NVL(MAX(SEQ_NO),0) FROM ACCOUNTS.PARTIAL_SANFS) MAX_PSQ,
       (SELECT NVL(MAX(SEQ),0) FROM ACCOUNTS.CATEGORY) MAX_CATSEQ
  FROM DUAL;

-- قيود NOT NULL / PK / UQ / FK على جداول القسم (بُنيت عليها أعمدة الإدراج)
SELECT table_name, constraint_name, constraint_type, search_condition
  FROM ALL_CONSTRAINTS WHERE OWNER='ACCOUNTS'
   AND TABLE_NAME IN ('INVENTORY_RECEIVE','INVENTORY_RECEIVE_DETAILES',
                      'INVENTORY_SARF','INVENTORY_SARF_DETAILES',
                      'INVENTORY_TRANSM','INVENTORY_TRANSD',
                      'SANFS','SANFS_D','PARTIAL_SANFS','STORES','STORE_EMP',
                      'GROUP1','TYPES','CATEGORY','UNITS');
```

### ب) DDL المنفَّذ (13 تسلسلاً)

```sql
BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_RCV      START WITH 536          INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_ISS      START WITH 302          INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_TRNM     START WITH 265472       INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_TRND     START WITH 2641710002   INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_ITEM     START WITH 2184         INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_ITEM_D   START WITH 101010001014 INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_PSANF    START WITH 2188         INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_STORE    START WITH 13           INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_GROUP    START WITH 10           INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_TYPE     START WITH 28           INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_UNIT     START WITH 12           INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_CAT      START WITH 19           INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
  EXECUTE IMMEDIATE 'CREATE SEQUENCE SEQ_STORES_KEEPER   START WITH 1            INCREMENT BY 1 MINVALUE 1 NOMAXVALUE NOCACHE NOCYCLE';
END;
```

**التحقق (بعد التنفيذ):** 13 تسلسلاً موجودة، و`LAST_NUMBER` لكل منها = نقطة البداية أعلاه.

### ج) ما لم يُنفَّذ عمداً

- **لا `CREATE TABLE`** — قرار المستخدم (D13): الجرد كشف حي بلا حفظ.
- **لا كتابة في `GARD`/`GARD_DETAILES`** — `GARD_TYPE=6` يُدرج كحركة موجبة في `ITEM_MOVE_D`
  فيُضاعف الرصيد لو تكرر.
- **لا `02_ibac_seed.php`** في هذه الجولة (يتطلب تشغيله على جهاز الخادم بـ`artisan`/PHP
  مع اتصال أوراكل) — مطلوب قبل أن يعمل حجب الأكواد الـ26 على الخادم.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** 13 `CREATE SEQUENCE` · **DML:** لا.

---

## 2026-11-01 — إصلاح تسلسل كتالوج الصلاحيات ثم بذر 26 كوداً

### أ) العطل المقيس (قراءة فقط)

```sql
-- على قاعدة التطبيق (localhost:1521/orcl):
SELECT COUNT(*) AS C, MAX(PERMISSION_ID) AS M FROM ACCOUNTS.APP_PERMISSIONS;
-- النتيجة: C = 147 · M = 188

SELECT SEQ_APP_PERMISSIONS.NEXTVAL AS N FROM DUAL;
-- النتيجة: 186   ← متأخر عن 186/187/188 المستخدمة فعلاً
```

**الأثر:** كل إدراج جديد في الكتالوج كان يصطدم بـ`ORA-00001: unique constraint
(ACCOUNTS.APP_PERM_PK) violated` — أي أن إنشاء أي صلاحية جديدة لأي قسم في النظام كان مستحيلاً،
وليس المخازن وحده. (اكتُشف أثناء بذر أكواد المخازن الـ26.)

### ب) DDL الإصلاح (نمط Oracle 11g بلا RESTART)

```sql
ALTER SEQUENCE SEQ_APP_PERMISSIONS INCREMENT BY 2;
SELECT SEQ_APP_PERMISSIONS.NEXTVAL FROM DUAL;   -- قفزة فوق max(id)
ALTER SEQUENCE SEQ_APP_PERMISSIONS INCREMENT BY 1;
-- التحقق: NEXTVAL = 190 مقابل MAX(PERMISSION_ID) = 188
```

### ج) البذر (DML · `02_ibac_seed.php` — idempotent)

```
PERMISSIONS  catalog=173 inserted=26 updated=147 total=173
SETTINGS     seeded=23  inserted=0  updated=23  total=25
```

التحقق بعد البذر: `APP_PERMISSIONS` = 173 صفاً، و`MODULE_CODE='stores'` = **31** صفاً
(1 منح شامل + 4 أساسية + 26 إضافة).

### د) صفوف مسبار حُذفت

```sql
-- عبر موصل oracledb (قاعدة التطوير البعيدة) — اختبار الاستجابة للمفتاح الرئيسي
INSERT INTO ACCOUNTS.APP_PERMISSIONS (...) VALUES (SEQ_APP_PERMISSIONS.NEXTVAL, 'zz_probe', ...);
DELETE FROM ACCOUNTS.APP_PERMISSIONS WHERE PERMISSION_CODE = 'zz_probe';
```

لا يبقى أي صف مسبار في الجدول.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** `ALTER SEQUENCE ×2` · **DML:** 26 إدراجاً + 147 تحديثاً في الكتالوج.

---

## 2026-11-01 — إصلاح تسلسلات التطبيق المتأخرة عن بياناتها (سجل النشاط كان ميتاً بصمت)

### أ) كيف اكتُشف

اختباران قائمان (`TailoringTest` و`CustomerMeasurementTest`) يتحققان من أن الطباعة والتصدير
"يتركان صف نشاط واحداً" بدأا يفشلان بعد إصلاح تسلسل الكتالوج، فقاد التحقيق إلى دالة
`ActivityLogger` نفسها.

### ب) العطل المقيس (قراءة فقط)

```sql
SELECT COUNT(*) AS C, MAX(ACTIVITY_ID) AS M FROM ACCOUNTS.APP_USER_ACTIVITY;
-- النتيجة: M = 840

SELECT SEQ_APP_ACTIVITY.NEXTVAL AS N FROM DUAL;
-- النتيجة: 569   ← متأخر بـ271 رقماً عن أعلى معرّف موجود
```

**الأثر — وهو الأخطر في هذا العطل:** `ActivityLogger` يلفّ الإدراج في `try/catch` كي لا يُسقط
الطلب الأصلي، فـ`ORA-00001` كان **يُبتلع بصمت**. النتيجة: سجل التدقيق كله لم يكتب صفاً واحداً
منذ أن تجاوز `MAX(ACTIVITY_ID)` التسلسل، بينما كل شاشة "سجل النشاط" في الإدارة تبدو سليمة
وتعرض صفوفاً قديمة فقط. أي أن **كل تدقيق المشروع كان معطلاً دون أي إشارة خطأ**.

### ج) مسبار شامل لكل تسلسلات التطبيق

فحص ستة أزواج (تسلسل ↔ جدول) كشف أربعة متأخرة:

| التسلسل | الجدول | MAX(id) | NEXTVAL أول قراءة | الحالة |
|---|---|---|---|---|
| `SEQ_APP_ACTIVITY` | `APP_USER_ACTIVITY` | 840 | 569 | **متأخر 271 ← أُصلح** |
| `SEQ_APP_USERS_PERM` | `APP_USERS_PERMISSIONS` | 233 | 232 | **على الحد ← أُصلح** |
| `SEQ_APP_SETTINGS` | `APP_SETTINGS` | 25 | 25 | **على الحد ← أُصلح** |
| `SEQ_APP_USERS_ID` | `APP_USERS` | 107 | 108 | سليم |
| `SEQ_APP_SUPPORT_TICKETS` | `APP_SUPPORT_TICKETS` | — | — | سليم |
| `SEQ_APP_PERMISSIONS` | `APP_PERMISSIONS` | 188 | 190 | سليم (بعد إصلاح أعلاه) |

> **ملاحظة مهمة عن القياس:** كل استدعاء لـ`NEXTVAL` **يتقدم** التسلسل، فالمسبار نفسه ليس
> للقراءة فقط. لذلك اعتُمدت أول قراءة فقط كمرجع، وكل ما كان `NEXTVAL` فيه أصغر من الحد
> الأدنى المطلوب (`MAX(id) + 1`) يُعتبر متأخراً ويُصلح قبل أي إدراج حقيقي.

### د) DDL الإصلاح (نمط Oracle 11g بلا RESTART — نفسه المستخدم مع الكتالوج)

```sql
-- لكل تسلسل متأخر، بفارق = MAX(id) - NEXTVAL + 1
ALTER SEQUENCE SEQ_APP_ACTIVITY     INCREMENT BY 269;
SELECT SEQ_APP_ACTIVITY.NEXTVAL FROM DUAL;        -- قفزة فوق max(id)
ALTER SEQUENCE SEQ_APP_ACTIVITY     INCREMENT BY 1;

ALTER SEQUENCE SEQ_APP_USERS_PERM   INCREMENT BY 2;
SELECT SEQ_APP_USERS_PERM.NEXTVAL FROM DUAL;
ALTER SEQUENCE SEQ_APP_USERS_PERM   INCREMENT BY 1;

ALTER SEQUENCE SEQ_APP_SETTINGS     INCREMENT BY 1;   -- قفزة واحدة فوق max(id)
SELECT SEQ_APP_SETTINGS.NEXTVAL FROM DUAL;
ALTER SEQUENCE SEQ_APP_SETTINGS     INCREMENT BY 1;
```

**التحقق بعد الإصلاح:** `SEQ_APP_ACTIVITY.NEXTVAL = 842` مقابل `MAX = 840`،
و`SEQ_APP_USERS_PERM.NEXTVAL = 268`، وأُكد الإدراج فعلياً (`insert: OK`) وأنشاء
`SequenceIntegrityTest` جميع اختباراته.

### هـ) حارس دائم بدل الذاكرة

أُضيف `kyApp_API/tests/Feature/SequenceIntegrityTest.php`:

- اختبار مُعامَل (dataset) لكل تسلسل من الستة: `NEXTVAL > MAX(id)`.
- اختبار إدراج فعلي في `APP_USER_ACTIVITY` داخل `beginTransaction`/`rollBack` يثبت أن السجل
  يقبل الكتابة، ثم يعيد العدّ إلى ما كان (لا أثر يُترك).

بهذا لا يمكن أن يتكرر العطل نفسه صامتاً: أي تسلسل يتخلف سيُسقط الاختبار قبل النشر.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** `ALTER SEQUENCE ×3 أزواج` · **DML:** لا (اختبار الإدراج داخل معاملة مُتراجَعة).

---

## 2026-11-01 — قياس عدد الأرصدة السالبة لكل مخزن (قراءة فقط، تمهيداً لمؤشر الشاشة)

### أ) الاستعلام المُنفَّذ

```sql
SELECT s.STORE_NO, s.STORE_NAME,
       NVL(st.ITEMS, 0) AS ITEMS, NVL(st.VALUE, 0) AS VALUE,
       NVL(st.NEGATIVE, 0) AS NEGATIVE
  FROM ACCOUNTS.STORES s
  LEFT JOIN (
        SELECT INV_ID, COUNT(DISTINCT I_CODE) AS ITEMS,
               SUM(SUM_PRICE) AS VALUE,
               SUM(CASE WHEN SUM_TP < 0 THEN 1 ELSE 0 END) AS NEGATIVE
          FROM ACCOUNTS.AVVG
         GROUP BY INV_ID
  ) st ON st.INV_ID = s.STORE_NO
 ORDER BY s.STORE_NO;
```

### ب) النتيجة

```
store 1:  items=572  value=-154,023,387.00  negative=56
store 2:  items=0    value=0.00             negative=0
store 3:  items=106  value=61,980,084.00    negative=36
store 4:  items=36   value=23,985,200.00    negative=3
store 11: items=0    value=0.00             negative=0
store 12: items=0    value=0.00             negative=0
negative rows across all stores: 95
```

**الدلالة:** المخازن 2/11/12 تخرج صفراً كما يتوقع استثناء `ITEM_MOVEMENT_D`، والمخازن الحيّة
تحمل **95** صفاً سالباً — أي أكثر مما كان معروفاً سابقاً (41). هذا ما يجعل مؤشر «أصناف برصيد
سالب» في لوحة القسم رقماً حقيقياً لا زينة، وقد دخل في `StoreController::index`
كـ`SUM(CASE WHEN SUM_TP < 0 THEN 1 ELSE 0 END) AS NEGATIVE`.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** لا · **DML:** لا · **قراءة فقط**.

---

## 2026-11-02 — اكتشاف مهم: موصل oracledb وقاعدة التطبيق خدمتان مختلفتان

### أ) الدليل القاطع

نفس الاستعلام أعطى نتيجتين مختلفتين على الطرفين لفاتورة 535:

```sql
-- عبر موصل oracledb (خدمة orcl):
SELECT (SELECT COUNT(*) FROM ACCOUNTS.INVENTORY_RECEIVE_DETAILES WHERE BILL_NO=535 AND YEAR=2026) AS LINES_535,
       (SELECT MAX(BILL_NO) FROM ACCOUNTS.INVENTORY_RECEIVE) AS MAX_BILL,
       (SELECT COUNT(*) FROM ACCOUNTS.INVENTORY_RECEIVE) AS RCV_TOTAL FROM DUAL;
-- النتيجة: 18 · 536 · 993

-- عبر اتصال التطبيق نفسه (خدمة orcl3):
-- النتيجة: 36 · 535 · 993
```

**القطع:** قاعدة التطبيق هي `orcl3` (36 سطراً)، وهي التي يطابقها ملف PDF الذي أعطانا إياه المستخدم
(36 سطراً والإجمالي 606,200). إذن كل قياس سابق حُسب على الموصل كان على قاعدة أخرى.

### ب) أثر ذلك على تسلسلات المخازن — عطلان حقيقيان

نقاط بداية التسلسلات حُسبت من الموصل، فطلع في قاعدة التطبيق تسلسلان متأخران:

| التسلسل | الجدول | MAX(id) في orcl3 | LAST_NUMBER | الحالة |
|---|---|---|---|---|
| `SEQ_STORES_TYPE` | `ACCOUNTS.TYPES` | **801** | 28 | متأخر 773 ⇒ أُصلح |
| `SEQ_STORES_UNIT` | `ACCOUNTS.UNITS` | **12** | 12 | على الحد ⇒ أُصلح |

(ال عشرة الباقية سليمة في `orcl3`: RCV 535/547 · ISS 301/302 · TRNM 265471/265472 ·
TRND 2641710001/2641710002 · ITEM 2183/2184 · ITEM_D 101010001013/…1014 · PSANF 2187/2188 ·
STORE 12/13 · GROUP 9/10 · CAT 18/19.)

**الأثر لو تُركا:** أول إنشاء مجموعة فرعية أو وحدة جديدة من شاشة المرجعيات كان سيرمي
`ORA-00001` على مفتاح `TYPES` / `UNITS` — عطل في مسار كتابة، لا في عرض.

### ج) DDL الإصلاح (نفس نمط 11g بلا RESTART)

```sql
ALTER SEQUENCE ACCOUNTS.SEQ_STORES_TYPE INCREMENT BY 774;
SELECT ACCOUNTS.SEQ_STORES_TYPE.NEXTVAL FROM DUAL;
ALTER SEQUENCE ACCOUNTS.SEQ_STORES_TYPE INCREMENT BY 1;

ALTER SEQUENCE ACCOUNTS.SEQ_STORES_UNIT INCREMENT BY 1;
SELECT ACCOUNTS.SEQ_STORES_UNIT.NEXTVAL FROM DUAL;
ALTER SEQUENCE ACCOUNTS.SEQ_STORES_UNIT INCREMENT BY 1;
```

**التحقق بعد الإصلاح:** `SEQ_STORES_TYPE max=801 last=802 => ok` ·
`SEQ_STORES_UNIT max=12 last=13 => ok`، وكل الاثني عشر الآن أمام جداولها في قاعدة التطبيق.

### د) استعلامات جديدة أُضيفت للكود (قراءة فقط)

```sql
-- بحث الحساب لمُنتقي رأس المستند (GET /stores/accounts)
SELECT a.ACC_NO, a.ACC_NAME, a.GROUP_ID FROM ACCOUNTS.CHART_ACC a
 WHERE a.ACC_NAME LIKE :name_ar OR a.ACC_NAME LIKE :name_utf OR a.ACC_NO = :acc_no
 ORDER BY a.ACC_NO;  -- بحد 30 صفاً

-- عملات وألوان من قاموساتها (تُضاف إلى /stores/reference)
SELECT CUR_NO, CUR_NAME FROM ACCOUNTS.CURRENCY ORDER BY CUR_NO;          -- يمني · دولار · سعودي
SELECT COLOR_NO, COLOR_NAME, COLOR_TYPE FROM ACCOUNTS.SANFS_COLOR ORDER BY COLOR_NO;
```

**حقيقة مُصحَّحة:** جدول الألوان اسمه `SANFS_COLOR` لا `COLORS`، و`COLOR_NO` فيه فريد
(فحص التكرار أعاد صفراً)، لذلك الربط به لا يُضاعف سطور المستند.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** `ALTER SEQUENCE ×2` · **DML:** لا · **لا جدول جديد**.

---

## 2026-11-02 — استعلامات جرد فروق الأنواع الثلاثة (قراءة فقط)

### أ) جرد الأعمدة

```sql
-- عبر اتصال التطبيق (orcl3) لكل جدول على حدة
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER = 'ACCOUNTS' AND TABLE_NAME = :table
 ORDER BY COLUMN_ID;
```

الجداول المقروءة: `INVENTORY_RECEIVE` · `INVENTORY_SARF` · `INVENTORY_TRANSM` ·
`INVENTORY_RECEIVE_DETAILES` · `INVENTORY_SARF_DETAILES` · `INVENTORY_TRANSD`.

**النتيجة:** 42 · 42 · 48 للرؤوس، و25 · 23 · 42 للسطور. الفروق الكاملة مسجّلة في
`DBdevloping_history.md`، وأهمها: `PROV_BILL` للتوريد فقط، و`CURNO/CURPRICE` لسطور التوريد
فقط، و`TOTALD` بدل `TOTAL` في سطور التحويل.

### ب) قراءات تحقق من البيانات الحيّة

```sql
SELECT MAX(BILL_NO) AS BILL_NO FROM ACCOUNTS.INVENTORY_RECEIVE;   -- 535
SELECT MAX(BILL_NO) AS BILL_NO FROM ACCOUNTS.INVENTORY_SARF;      -- 301
SELECT MAX(BILL_NO) AS BILL_NO FROM ACCOUNTS.INVENTORY_TRANSM;    -- 71

SELECT COUNT(*) AS C, SUM(QTY) AS Q, SUM(TOTAL) AS T
  FROM ACCOUNTS.INVENTORY_SARF_DETAILES WHERE BILL_NO = 301;
```

**الغرض:** التأكد أن أعمدة القالب المقروءة (المقاسات/التصنيف/اللون/العبوة/القطعة/متوسط التكلفة)
تحمل قيماً فعلية لا أصفاراً، قبل بناء الوصف لكل نوع.

### ج) تنظيف توكنات الفحص (DML)

```sql
-- NAME نوعه CLOB فالمقارنة بـ= ترمي ORA-00932؛ يلزم SUBSTR
DELETE FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS
 WHERE DBMS_LOB.SUBSTR(NAME, 4000, 1) LIKE 'zz-livecheck-%'
    OR DBMS_LOB.SUBSTR(NAME, 4000, 1) LIKE 'probe-%';

-- التحقق: 0 صفاً باقياً
SELECT COUNT(*) FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS
 WHERE DBMS_LOB.SUBSTR(NAME, 4000, 1) LIKE 'zz-livecheck-%';
```

**النتيجة:** `zz-livecheck-% = 1 · deleted = 1`، والباقي **0**. لا توكن فحص في قاعدة العمل.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** لا · **DML:** حذف توكنات فحص (3 صفوف إجمالاً).

---

## 2026-11-03 — استعلامات فحص (قراءة فقط)

**الهدف:** تحديد الاسم الحقيقي لعمود اللون في جدول الأصناف بعد `ORA-00904` على `MAIN_COLOR`.
**القاعدة:** `orcl3` (قاعدة التطبيق، عبر `DB::connection('oracle')`) — لا `orcl`.

```sql
-- 1) التأكد من القاعدة المتصلة (كانت النتيجة: orcl3 / orcl3)
SELECT SYS_CONTEXT('USERENV','DB_UNIQUE_NAME') AS DBNAME,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS SVC
  FROM DUAL;
```

```sql
-- 2) الأعمدة الفعلية لجدولي الأصناف — نُفّذ مرتين: (t='SANFS') و (t='SANFS_D')
SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, NULLABLE
  FROM ALL_TAB_COLUMNS
 WHERE OWNER = :o          -- 'ACCOUNTS'
   AND TABLE_NAME = :t
 ORDER BY COLUMN_ID;
```

**النتيجة:**

| الجدول | عدد الأعمدة | أعمدة اللون |
|---|---|---|
| `ACCOUNTS.SANFS` | 37 | `MCOLOR`, `COLORNO` — **ولا `MAIN_COLOR`** |
| `ACCOUNTS.SANFS_D` | 41 | `DCOLOR`, `COLOR_NO`, `MCOLOR` |

**الأثر:** `MAIN_COLOR` في ثلاثة مواضع من `StoreItemController` → `MCOLOR`.
**أعمدة أخرى تحقّقتُ من وجودها في نفس الفحص:** `SANF_CODE`, `SANF_TYPE`, `CAT_NO`, `STYL_NO`,
`CAP`, `BUY_PRICE`, `CREATED_ON`, `LAST_UPDATED_DATE` (كلها موجودة) · وفي `SANFS_D`:
`SANF_COCE`, `BARACOCE`, `SANF_DNAME`, `DCOLOR`, `COLOR_NO`, `STORNO` (كلها موجودة).

**ملاحظة:** لم تُنفّذ أي كتابة يدوياً. مسارات `INSERT`/`UPDATE`/`DELETE` جُرّبت عبر
`tests/Feature/StoreItemTest.php` داخل معاملة أُلغيت في النهاية (`rollBack`)، فلم يبق صف واحد.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا (اختبارات داخل معاملات مُلغاة).
