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
