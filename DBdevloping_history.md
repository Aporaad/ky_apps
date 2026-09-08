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

