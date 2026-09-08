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
