# -*- coding: utf-8 -*-
"""توثيق جولة تحسين شاشة استعراض الفاتورة (إضافة فقط).
Append the bill-view refinement round (append-only)."""

import os

ROOT = os.path.dirname(os.path.abspath(__file__))
STAMP = '2026-10-29 03:20'
MODEL = 'Qoder'

TODO = """
---

## {stamp} — التفصيل: تقوية التباين وضبط حقول الأقسام وسجل حركة الأقمشة (OHDID)

- [x] **التباين:** تسميات الحقول صارت `textSecondary` بوزن 600 وحجم 10.5، والقيم `textPrimary` بوزن 700 وحجم 12.5، ورؤوس الجداول بوزن 800، والشارات 11 بوزن 700 — بدل الرمادي الباهت السابق.
- [x] **بيانات الفاتورة:** حُذفت السنة والفرع والمجموعة، وبقيت الحقول في **صفّين فقط** (`TailoringInfoGrid(rows: 2)`) + البيان في خانة كاملة.
- [x] **بيانات العميل:** الاسم في شريط عنوان القسم، والسطر الثاني: الهاتف · رقم العميل · رقم الحساب، وحُذف العنوان.
- [x] **تفاصيل الدفع:** حُذفت سعر العملة والاستحقاق وطريقة الدفع، وبقيت الأرقام الأساسية في صف واحد.
- [x] **الموديلات والمستفيدون:** رأس أعمدة واحد (الموديل · المستفيد · القطع · الملاحظة) ثم صف لكل موديل باسم نوعه فقط، وحُذف رقم الموديل وكلمة «موديل» وحقل المرحلة، والمستفيد الفارغ لا يُعرض له شيء.
- [x] **سجل الحركة صار للقماش (OHDID) لا للموديل:** الخادم يقرأ `v.OHDID` في التفصيل، ومسار الحركة يقبل `ohd_ids` ويرشّح `ct.OHDID`، ويعيد `ohdid` و`executor`. العميل: `CuttingPieceItem.ohdId` · `CuttingMovement.ohdId/executor` · `fetchMovements(ohdIds)` · `CuttingMovementsKey.ohdIds` · `movementOhdIds`.
- [x] **جدول الحركة:** خمسة أعمدة فقط (الحالة · التاريخ · العدد · المنفذ · ملاحظة) وصف واحد لكل حركة.
- [ ] **الأقمشة:** التعديل المطلوب (سطران لكل قماش، أعمدة رقم الطلب/القماش/العرض/اللون/هنش/يارده/السعر ثم القصّاص/الخيّاط/المرحلة، وحذف الرف والمصدر) **لم يُطبَّق**: الملف `model_fabrics_table.dart` ظلّ مشغولاً بتعديل IDE معلّق فرفض كل كتابة. يحتاج المستخدم إلى إغلاق الملف أو تنفيذ «Chat: Recover Pending File Edit» ثم يُطبَّق التعديل.
- [x] **التحقق:** اختبارات التفصيل **54** ناجحة · Pest `Tailoring` **11 ناجحاً / 229 تأكيداً** · `flutter analyze` على التفصيل بلا ملاحظات.

**النموذج:** {model} · **الوقت:** {stamp} · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).
"""

HISTORY = """
---

## {stamp} — التفصيل: تباين أقوى، صفوف أقل، وسجل حركة لكل قماش

### الخادم (Laravel)

- `TailoringController::detailSql` يقرأ `v.OHDID`، و`pieceRow` يعيد `ohdid` مع كل قطعة.
- `movements` يقبل `ohd_ids` (أرقام طلبات الأقمشة) بدل `seq_nos`، ويرشّح
  `ct.OHDID IN (...)` بعد التحقق من `BILL_NO`/`YEAR` و`NVL(CANCEL,0) <> 1`.
- `movementRow` يعيد `ohdid` و`executor` = `CREATED_BY_NAME` ثم `DEPTNAME` ثم رقم القسم.
- `TailoringTest`: اختبار الحركة صار يقرأ `ohdid` من قطع التفصيل ويطلب بها، ويؤكد وجود
  `ohdid` و`executor` في كل صف، ويؤكد رفض الطلب بلا `ohd_ids` (422).

### العميل (Flutter)

- `cutting_piece_item.dart`: حقل `ohdId` من `ohdid`.
- `cutting_movement_model.dart`: `ohdId` و`executor`، ومقروءات `executorLabel` و`qtyLabel`
  و`noteLabel` و`dateLabel` لأعمدة الجدول الخمسة.
- `cutting_model_item.dart`: `movementOhdIds` (أرقام طلبات الأقمشة) بجانب `movementSeqNos`.
- `tailoring_repository.dart`: `fetchMovements(..., ohdIds)` يُرسل `ohd_ids`.
- `tailoring_providers.dart`: `CuttingMovementsKey(ohdIds)` والمزود يمرّرها.
- `model_movements_table.dart`: يعيد `ohdid`/`executor`، وجدول من خمسة أعمدة (الحالة ·
  التاريخ · العدد · المنفذ · ملاحظة)، ورسالة فراغ «لا توجد أقمشة تحمل رقم طلب».
- `cutting_bill_progress_screen.dart`: يبني `ohdIds` من قطع الفاتورة.
- `tailoring_section_card.dart`: تباين أقوى (تسمية 10.5/600 بلون ثانوي، قيمة 12.5/700،
  شارة 11/700) وخيار `rows` في شبكة الحقول لفرض صفّين.
- `bill_header_card.dart`: حذف السنة/الفرع/المجموعة وفرض صفّين.
- `bill_customer_card.dart`: الاسم في شريط العنوان، وحقول السطر الثاني ثلاثة، وحذف العنوان.
- `bill_payment_card.dart`: حذف سعر العملة والاستحقاق وطريقة الدفع.
- `model_selector_strip.dart`: رأس أعمدة واحد وصف لكل موديل باسم نوعه، وحذف الرقم والمرحلة.

### ما لم يُطبَّق بعد وسببه

`model_fabrics_table.dart` ظلّ مشغولاً بتعديل IDE معلّق (operationId متكرر) فرفضت كل كتابة
عليه. التعديل المطلوب موصوف في todo.md وينتظر تحرير الملف.

### الاختبارات

- `cutting_bill_view_screen_test.dart`: صفّان لبيانات الفاتورة (عدد إحداثيات رأس مختلف = 2)،
  سطر واحد للعميل والدفع، اختيار الموديل الثاني بالنقر على مستفيده، وجود رأس «المستفيد»،
  وقياس ارتفاع أقل من 700 بكسل.
- `tailoring_repository_test.dart`: الحركة تُطلب بـ`ohd_ids` وتقرأ `ohdid` و`executor`.
- النتيجة: 54 اختبار تفصيل ناجح · Pest 11/229 · `flutter analyze` على التفصيل نظيف.

**النموذج:** {model} · **الوقت:** {stamp} · **لا commit** (لم يُطلب).
"""

DBHISTORY = """
---

## {stamp} — مصدر سجل حركة الأقمشة: `OHDID` في الـ VIEW و`CUTING_TRANSD`

### ما تم قياسه حياً

- `ACCOUNTS.CUTTING_SALES_BILL_VIEW` تحمل **`OHDID`** و`OHID` إلى جانب `SEQ_NO` و`SEQ_NO1`؛
  وصف نموذجي: `bill_no=6, year=2026, seq_no=60373, seq_no1=92456, ohdid=262133`.
- `ACCOUNTS.CUTING_TRANSD` مفتاحها التشغيلي **`OHDID`** (وليس `SEQ_NO`)، وأعمدتها تشمل
  `DDATE, ORDSID, ORDID, DEPTID, DETAILE, QTY, PQTY, SQTY, POST, CANCEL, CREATED_BY_NAME`.
- قياس: القطعة `ohdid=262133` لها **9** صفوف حركة في `CUTING_TRANSD`، وكل صف يحمل
  `CREATED_BY_NAME = null` و`DEPTID` (12/21/22) — لذلك «المنفذ» يُقرأ من اسم القسم عند
  غياب الاسم.

### أثر ذلك على الاستعلام

```sql
SELECT ct.TR_INV_D_ID, TO_CHAR(ct.DDATE,'DD/MM/YYYY') DDATE_TXT,
       os.ORDSNAME, ct.ORDSID, dp.DEPTNAME, ct.DETAILE, ct.QTY,
       ct.PQTY, ct.SQTY, ct.SEQ_NO, ct.OHDID, ct.POST,
       ct.CREATED_BY_NAME, ct.UPDATED_BY_NAME
  FROM ACCOUNTS.CUTING_TRANSD ct
  JOIN ACCOUNTS.ORDSTATE os ON os.ORDSID = ct.ORDSID
  LEFT JOIN ACCOUNTS.DEPTS dp ON dp.DEPTID = ct.DEPTID
 WHERE ct.BILL_NO = :bill_no AND ct.YEAR = :year
   AND NVL(ct.CANCEL,0) <> 1
   AND ct.OHDID IN (:ohd0, :ohd1, ...)
 ORDER BY ct.DDATE, ct.TR_INV_D_ID
```

**النموذج:** {model} · **الوقت:** {stamp} · **لا DDL** · **لا DML** (قراءة فقط).
"""

DBCOMMENTS = """
---

## {stamp} — استعلامات تشخيص OHDID (قراءة فقط)

```sql
-- أعمدة الـ VIEW التي تخصّ الطلب/التسلسل
SELECT COLUMN_NAME FROM ALL_TAB_COLUMNS
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='CUTTING_SALES_BILL_VIEW'
   AND (COLUMN_NAME LIKE '%OH%' OR COLUMN_NAME LIKE '%SEQ%');
-- النتيجة: OHID, OHDID, SEQ_NO, SEQ_NO1, ORDSDID → OHDID موجود في الـ VIEW

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
 WHERE OWNER='ACCOUNTS' AND TABLE_NAME='DEPTS';   -- DEPTID, DEPTNAME, DEPTTYPE, ACTIVE, PARANT
```

**النموذج:** {model} · **الوقت:** {stamp} · **DDL:** لا · **DML:** لا.
"""

USER = """
---

## {stamp} — أمر تعديل تنسيق شاشة الاستعراض (نصّ الأمر كما ورد)

> اولا تبيان النصوص والبيانات باهت وغير واضح قم بتقويه تباين النصوص وعناوين الحقول والبيانات
> بيانات الفاتوره : يتم حذف حقول (السنه-الفرع-المجموعه) وبقيه الحقول يتم اظهارها بصفين فقط
> وبشكل مرتب ومنسق وواضح
> بيانات العميل : اسم العميل يظهر بجانب عنوان القسم «بيانات العميل» والهاتف ورقم العميل ورقم
> الحساب تظهر بالسطر الثاني وحقل العنوان يتم حذفه نهائيا
> تفاصيل الدفع : يتم حذف حقول (سعر العمله -حقل الاستحقاق -حقل طريقه الدفع) ويتم عرض البقية
> بسطر واحد
> الموديلات والمستفيدون : اسماء الاعمده (الموديل-المستفيد-القطع-الملاحظه) تظهر مره واحده
> براس القائمه، والخانه الاولى اسم نوع الموديل فقط وحذف كلمه موديل والرقم وحقل المرحله
> الاقمشة : الاعمده (رقم الطلب-القماش-العرض-اللون-هنش-يارده-السعر-القصاص-الخياط-المرحله)
> ورقم الطلب هو ohdid في الـ VIEW وحذف الرف والمصدر، وكل قماش في سطرين
> سجل الحركه : يكون لكل قماش (ohdid) وليس لكل موديل، والاعمده (الحاله-التاريخ-العدد-المنفذ-
> ملاحظه) فقط، بصف واحد لكل حركه

**النموذج:** {model} · **الوقت:** {stamp}.
"""

BLOCKS = [
    ('todo.md', TODO),
    ('devloping_history.md', HISTORY),
    ('DBdevloping_history.md', DBHISTORY),
    ('db_commends.md', DBCOMMENTS),
    ('user_commends.md', USER),
]


def append(name, block):
    path = os.path.join(ROOT, name)
    with open(path, 'rb') as handle:
        data = handle.read()

    crlf = data.count(b'\r\n')
    nl = '\r\n' if crlf * 2 > data.count(b'\n') else '\n'

    text = block.format(stamp=STAMP, model=MODEL).replace('\n', nl)
    if not text.endswith(nl):
        text += nl

    with open(path, 'ab') as handle:
        if not data.endswith(b'\n'):
            handle.write(nl.encode('utf-8'))
        handle.write(nl.encode('utf-8'))
        handle.write(text.encode('utf-8'))

    print('appended %-24s +%d bytes' % (name, len(text.encode('utf-8'))))


for file_name, body in BLOCKS:
    append(file_name, body)
