## الملخص

المطلوب تقريرين داخل `lib/features/accounts/` ينسخان تقريري أوراكل القدامى (ملفات RDF/PDF) المتوفرين فعلاً في مجلد `REPORTS/`:

- **كشف حسابي مالي** (`acc_report.RDF` / `acc_report.pdf`): دفتر حركات لحساب مالي واحد (`CHART_ACC`) — بأعمدة: السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد، مع رصيد افتتاحي، ورصيد جارٍ لكل سطر، وإجماليات، وترويسة رسمية (Letterhead)، وخانة توقيعات. هذا التقرير له شاشة موجودة (`AccountStatementScreen`) ومسار Backend موجود (`getAccountStatement`)، لكن **كلاهما معطّل حالياً**: الـ Backend يستعلم عن جدول `ACC_TRXN` غير الموجود أصلاً في مخطط `ACCOUNTS` (تم التحقق عبر `oracledb` MCP — الجداول الحقيقية هي `ENTRY_MAIN`/`ENTRY_SUB`/`ENTRY_TYPE`)، فيُرجع الاستجابة فارغة بصمت دون خطأ. هذه الخطة تعيد كتابته ليطابق النمط المجَرَّب المُستخدَم فعلاً في `CustomerController::statement`، وتعيد بناء شاشة Flutter لتطابق قالب RDF/PDF.
- **كشف حساب مجموعة حسابات جزئية** (`TRIAL_BALANCE_REPORT.RDF` / `.pdf`): تقرير جديد بأسلوب ميزان المراجعة يعرض قائمة حسابات `CHART_ACC` متعددة مع إحصائيات مدين/دائن/رصيد، مقسّمة إلى عمودين **عملة محلية / عملة أجنبية**، ويُحدَّد نطاقه عبر اختيار متسلسل من أربع مستويات (حساب رئيسي → حساب فرعي → حساب جزئي → مجموعات الحساب الجزئي)، بدلاً من الاستعلام أحادي الجدول المعطّل حالياً.

يجب أن يكون التقريرين قابلين للطباعة والتصدير إلى PDF، وقابلين للتكبير/التصغير، مع فلتر تواريخ سهل وقابل للإخفاء، وتصميم خطوط/تخطيط متجاوب يعيد نفس شكل القالب المطبوع.

### حقائق أساسية تم التحقق منها من قاعدة البيانات عبر `oracledb` MCP (تُسجَّل في `db_commends.md` عند التنفيذ)
- جدول `ACC_TRXN` **غير موجود**. جداول الحركة الحقيقية: `ENTRY_MAIN(ENTRY_NO, DETAILS, ENTRY_DATE, ENTRY_TYPE_NO)`، و`ENTRY_SUB(SEQ, ENTRY_NO, ACC_NO, ENTRY_MNT, BALANCE_S, SEQ_PRICE, SUB_DETAILS, INVOICE_NO, GIVING)`، و`ENTRY_TYPE(ENTRY_TYPE_NO, ENTRY_TYPE_NAME, ...)` — و`ENTRY_TYPE_NO=100` يقابل "قيد يومية" (وهو النوع الظاهر في `acc_report.pdf`).
- `CHART_ACC(ACC_NO, ACC_NAME, BALANCE, ACC_DATE, SEQ, GROUP_ID, LIMITED_BALANCE, STOPPING_ACC)`.
- جداول العملات: `CURRENCY(CUR_NO, CUR_NAME)`، و`CUR_CODE(CUR_NO, CODE, MAIN_CUR_NAME, SUB_CUR_NAME)` (حيث `CUR_NO=1` = `YR` / "ريال يمني" = العملة المحلية، وكل ما عداها أجنبية)، و`CUR_PRICE(CUR_NO, PRICE, DAY_DATE, SEQ)`. الربط بين `ENTRY_SUB.SEQ_PRICE` ←→ `CUR_PRICE.SEQ` هو ما يعطي كل حركة عملتها — وهذا هو أساس التقسيم إلى "عملة محلية / عملة أجنبية" في تقرير ميزان المراجعة.
- دوال/نماذج الجلب المتسلسلة الموجودة تطابق المستويات الأربعة المطلوبة تماماً كما هي (`fetchAccounts`→`fetchAccMain(accNo)`→`fetchAccSub(accSub)`→`fetchAccSubGroup(accPart)`، وموفّرات `.family` في Riverpod: `parentAccountsProvider`/`parentAccMainProvider`/`parentAccSubProvider`/`parentAccSubGroupProvider` موجودة بالفعل في `accounts_provider.dart`) — تُعاد استخدامها كما هي دون تغيير.
- الثوابت `Perm.accountsStatement`، `Perm.accountsPrint`، `Perm.accountsExport` موجودة بالفعل في `lib/core/constants/permission_codes.dart`.

## الجانب الخلفي (Laravel — `kyApp_API`، وهو git submodule: يُعمل Commit داخله أولاً ثم تحديث pointer في المستودع الأب)

### 1. إصلاح `AccountController::getAccountStatement` (التقرير 1 — دفتر حركات حساب واحد)
إعادة كتابة جسم الاستعلام (حالياً الأسطر ~439-540) ليحاكي `CustomerController::statement` (الأسطر 294-420، وهو النموذج المرجعي المُجرَّب):
- ربط (Join) `ENTRY_MAIN`، `ENTRY_SUB`، `ENTRY_TYPE` مع فلترة `ENTRY_SUB.ACC_NO = :accNo` (هذا هو سطر دفتر الحساب المالي نفسه، ولا حاجة لربط `GIVING`/الطرف الآخر كما في حالة العميل).
- اختيار `ENTRY_NO` (السند)، `ENTRY_TYPE_NAME` (النوع)، `TO_CHAR(ENTRY_DATE,'DD/MM/YYYY')` (تأريخه)، `DETAILS`/`SUB_DETAILS` (البيان)، `ENTRY_MNT` → يُقسَّم إلى `debit` (عندما يكون موجباً) / `credit` (عندما يكون سالباً، بالقيمة المطلقة)، `BALANCE_S` (الرصيد الجاري).
- حساب `opening_balance` بمرور جميع السطور زمنياً: السطور التي `ENTRY_DATE < from_date` تُحدِّث `opening_balance`/`running_balance` وتُستثنى من القائمة المعروضة (نفس النمط المستخدم حرفياً في `CustomerController::statement`).
- تمرير كل حقل عربي عبر `ArabicEncoding::fixMojibake(...)`.
- إضافة فرع جديد: عند غياب `from_date`/`to_date`، يُجلب `MAX(ENTRY_DATE)` للحساب أولاً وتكون النافذة الافتراضية `[MAX - 30 يوم، MAX]` (القاعدة التي أكّدها المستخدم)، ويُعاد إرسال `from_date`/`to_date`/`defaulted: true` المحلولة داخل `summary` للاستجابة ليتمكن العميل من عرضها/تغييرها يدوياً.
- شكل الاستجابة يحافظ على المظروف (Envelope) الحالي لكن عناصر `transactions[]` تُضيف `entry_no`، `entry_type_name` بجانب `date`/`description`/`debit`/`credit`/`balance` الموجودة، ويُضيف `summary` الحقول `opening_balance`، `final_balance`، `total_debit`، `total_credit`، `currency` (تُحلّ عبر `CUR_PRICE`←`CUR_CODE` لآخر حركة للسحاب عبر `SEQ_PRICE`، وتكون الافتراضية `يمني YR`).

### 2. دالة جديدة `AccountController::getGroupStatement` (التقرير 2 — ميزان المراجعة)
إضافة دالة عامة جديدة + مسار `GET /accounts/group-statement` ← `permission:accounts.statement` في `routes/api.php` (بجانب مساري الكشوف الحاليين، ~الأسطر 315-320).
- تقبل الوسائط: `acc_no` (من ACCOUNT)، `acc_sub` (مفتاح ACC_MAIN)، `acc_part` (مفتاح ACC_SUB)، `group_id` (من ACC_SUB_GROUP)، `from_date`، `to_date` — جميعها اختيارية.
- حلّ النطاق (Scope Resolution) وفق قاعدة المستخدم:
  - إذا وُجد `group_id` ← `WHERE c.GROUP_ID = :group_id`.
  - وإلا إذا وُجد `acc_part` ← `WHERE TRUNC(c.ACC_NO/10000) = :acc_part` (مستوى الحساب الجزئي، أي أن التقرير يُطبع للحساب الجزئي نفسه).
  - وإلا إذا وُجد `acc_sub`/`acc_no` ← يُحلّ للأسفل عبر `ACC_MAIN`/`ACC_SUB` بنفس نمط `getAccountTree()` الحالي تماماً (يُعاد استخدام نمط الـ Join، الأسطر 668-772) للوصول إلى مجموعة الحسابات المالية.
  - إذا لم يوجد أي شيء ← رد 400 برسالة عربية واضحة تطلب اختيار حساب رئيسي على الأقل.
- لكل `CHART_ACC` داخل النطاق، سطر تجميعي واحد:
  - عند وجود `from_date`/`to_date`: تُجمَّع `ENTRY_SUB` مربوطة بـ `ENTRY_MAIN` (مع فلترة التاريخ) ومجمّعة حسب `CUR_PRICE.CUR_NO` (عبر `SEQ_PRICE`): `local_debit`/`local_credit` = دلاء `CUR_NO = 1`، و`foreign_debit`/`foreign_credit` = المجموع على كل `CUR_NO` الأخرى؛ و`balance = صافي المحلي + صافي الأجنبي` (بالإشارة، مجموع `ENTRY_MNT`).
  - عند غياب التاريخين: نفس التجميع لكن بدون شرط تاريخ (كل السجل التاريخي) — يطابق توضيح المستخدم أن التقرير 2 يعرض إحصائيات على مستوى الحساب لا قيوداً مفردة، وليس له نافذة افتراضية تلقائية.
  - يُجلب أيضاً عمود `CHART_ACC.BALANCE` الحالي لكل حساب لعرضه كمرجع.
- تُجمَّع سطور النتيجة تحت ترويسة قسم واحدة (`مجموعة حسابات: {الاسم}`) باستخدام اسم أعمق مستوى تم اختياره (`ACC_SUB_GROUP.ACC_GROUP_NAME` ← `ACC_SUB.PART_NAME` ← `ACC_MAIN.SUB_NAME` ← `ACCOUNT.ACC_NAME`)، مع سطر إجمالي عام (`الإجمالي`) يجمع مدين/دائن المحلي والأجنبي، محاكاةً لـ `TRIAL_BALANCE_REPORT.pdf`.
- الحقول العربية تُمرّر عبر `ArabicEncoding::fixMojibake`؛ والاستجابة تستخدم المظروف القياسي `{success, data:{scope_label, as_of_date, from_date, to_date, rows:[{acc_no, acc_name, cur_code, local_debit, local_credit, foreign_debit, foreign_credit, balance}], totals:{...}}}`، بشكل `meta` مطابق المتحكمات المجاورة في الحسابات (`{total, page, limit, total_pages, has_more}`) — لا حاجة هنا لترقيم صفحات، يُستخدم `total: count(rows)`.

### 3. تحديث `tests/Feature/BusinessRoutesSealedTest.php`
إضافة مسار محمي جديد واحد إلى `routes/api.php` سيُفشل اختبار عدّ المسارات المختومة (Sealed Routes) — يجب تحديثه (المسار الجديد يجب أن يحمل `auth:sanctum` + `permission:accounts.statement`، وأن يُدرَج في عينات اختبار الـ 403) قبل اعتبار أي شيء آخر في الجانب الخلفي منجزاً.

## عميل Flutter

### 4. اعتماديات جديدة (`pubspec.yaml`)
إضافة حزمتي `printing` و`pdf` (أحدث إصدار مستقر) — هذه أول ميزة طباعة/تصدير PDF في التطبيق كله (تم التأكد: لا توجد أي شاشة أخرى حالياً تنفّذ طباعة/تصدير، لذا لا يوجد شيء يُعاد استخدامه).

### 5. النماذج (`lib/features/accounts/data/models/chart_account_model.dart` + ملف جديد `account_group_statement_model.dart`)
- توسيع `AccountTransactionModel` بإضافة `entryNo`، `entryTypeName`، `subEntryNo` (قراءة المفاتيح بحالتَيها Upper/Lower + تطبيق `ArabicEncodingUtils.fix` على الحقول النصية فقط، مطابقةً لاتفاقيات `CustomerStatementModel` الحالية).
- توسيع `AccountStatementData` ليُظهر `openingBalance`، `finalBalance`، `totalDebit`، `totalCredit`، `currency`، `fromDate`، `toDate` (تُحلّل من `summary`)، كلها عبر مساعدَي `_parseInt`/`_parseDouble` الحاليين.
- نماذج جديدة `TrialBalanceRow`/`TrialBalanceReport` تحاكي شكل استجابة `getGroupStatement` JSON، بنفس اتفاقيات التحليل الدفاعي وإصلاح الترميز العربي.

### 6. المستودع (`lib/features/accounts/data/repositories/account_repository.dart`)
- تعديل فقط طريقة تحليل استجابة `fetchAccountStatement` (بدون تغيير الرابط، للخلف التوافقي مع الحقول المضافة في النقطة المعاد كتابتها).
- إضافة `fetchGroupStatement({int? accNo, int? accSub, int? accPart, int? groupId, String? fromDate, String? toDate, CancelToken? cancelToken})` ← `TrialBalanceReport`، بنفس نمط try/cancel-token/الأخطاء المستخدم في الدوال المجاورة.

### 7. الشاشة: `AccountStatementScreen` (التقرير 1) — إعادة بناء الجسم
- استبدال قائمة البطاقات `ListView.builder` (الأسطر ~329-450) بجدول واحد قابل للتمرير والتكبير بترويسة رسمية (Letterhead Table) يعيد إنتاج `acc_report.pdf`: شعار في المنتصف (`assets/CENTER.JPG`، معلن مسبقاً في assets داخل `pubspec.yaml`) + سطر اسم الشركة/الحساب + طابع وقت التقرير + خلايا ترويسة "من تاريخ/إلى تاريخ"، بترويسة الأعمدة السبعة بالضبط (`السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد`) باستخدام **نفس اللون الخردلي للترويسة** (`Color(0xFFD4A853)`) ونفس منطق تحجيم الخط/الكثافة (Compact Tiers) المُجرَّب حالياً في `customer_statement_screen.dart` (الأسطر ~1037-1077) — سيُنسخ هذا النمط إلى ملف Widget محلي جديد `lib/features/accounts/presentation/widgets/account_statement_report_table.dart` (محلي على مستوى الـ Feature، دون المساس بميزة العملاء أو `lib/core/widgets`، لإبقاء هذا التغيير محصوراً).
- سطر الرصيد الافتتاحي (`رصيد افتتاحي`)، ورصيد جارٍ لكل سطر، وتذييل إجماليات نهائي (`الرصيد الافتتاحي / إجمالي العمليات / الرصيد النهائي`)، وتذييل توقيعات (`توقيع المحاسب | توقيع أمين الصندوق | توقيع المدير` + سطر إخلاء المسؤولية 15 يوم + ترقيم الصفحات)، كـ Widget جديد `account_statement_report_footer.dart`.
- الإبقاء على شريط الفلتر الحالي (منتقي الحساب + زرّي التاريخ) مع إضافة زر تبديل "إخفاء/إظهار الفلترة" (`bool _filtersVisible`)، وإلغاء سلوك التاريخ الفارغي الافتراضي بحيث تُملأ التواريخ تلقائياً من نافذة الـ 30 يوم التي يحدّها الـ API (`summary.defaulted`)، ولفّ الجدول بالكامل داخل `InteractiveViewer(minScale: 0.5, maxScale: 3)` للتكبير باللمس/التمرير.
- إضافة زرّين في AppBar مغلَّفين بـ `PermissionGate`: طباعة (`Perm.accountsPrint`) وتصدير PDF (`Perm.accountsExport`)، يستدعيان مساعد مشترك جديد `account_statement_pdf_builder.dart` يعيد بناء نفس هيكل الجدول/التذييل داخل `Document`/`Page` من حزمة `pdf` باستخدام عناصر `pw` (نص عربي RTL عبر خط Cairo/عربي TTF مضمّن — يُعاد استخدام أصل Cairo المحمّل مسبقاً من `google_fonts` بتحميله في `Font.ttf` الخاص بحزمة `pdf` عند أول استخدام، مع تخزينه مؤقتاً في متغير static). زر الطباعة يستخدم `Printing.layoutPdf(...)`؛ والتصدير يستخدم `Printing.sharePdf(...)` (يعمل على Android/iOS/Web/Windows وهي المنصات المدعومة أصلاً في المشروع).

### 8. الشاشة: `AccountGroupStatementScreen` (التقرير 2) — ملف جديد
`lib/features/accounts/presentation/screens/account_group_statement_screen.dart`:
- أربع قوائم منسدلة متسلسلة موصولة بالموفّرات الموجودة: `parentAccountsProvider` ← `parentAccMainProvider(accNo)` ← `parentAccSubProvider(accSub)` ← `parentAccSubGroupProvider(accPart)` (الأخيرة اختيارية/قابلة للتخطي، ويُطبَّق ذلك داخل دالة الحل نفسها وليس بتعطيل الـ Widget).
- دالة نقية صغيرة `resolveStatementScope(...)` تشفّر القاعدة المطلوبة بالضبط: مجموعة مختارة ← مستوى المجموعة؛ بدون مجموعة لكن حساب جزئي مختار ← مستوى الحساب الجزئي؛ حساب فرعي فقط ← كامل شجرة الحسابات تحت هذا الفرعي؛ حساب رئيسي فقط ← هذا القسم بالكامل. تُكتب لها اختبار وحدة (Unit Test) في `test/` (انظر الخطوة 10).
- سطر نطاق تواريخ بنفس نمط التقرير 1 السهل/القابل للإخفاء (الافتراضي: كلاهما فارغ، أي "كل الحركات"، لأن التقرير 2 ليس له افتراضي تلقائي وفق توضيح المستخدم).
- جدول يعيد إنتاج ترويسة `TRIAL_BALANCE_REPORT.pdf` ثنائية الطبقة: `إسم الحساب | مدين | دائن` مكرّرة تحت عنوانين مجمّعين `عملة محلية` و`عملة أجنبية`، بجانب عمودي `رقم الحساب` ورمز العملة، مع سطر إجمالي جزئي لكل قسم ("الإجمالي ...") وسطر إجمالي عام ("إجمالي حسابات {asOfDate}").
- نفس تكبير `InteractiveViewer`، ونفس إجراءات الطباعة/التصدير المغلَّفة بـ `PermissionGate`، مع إعادة استخدام `account_group_statement_pdf_builder.dart` جديد بنفس مساعد تحميل الخط.
- تسجيل التنقّل: إضافة بلاطة (Tile) ثالثة "كشف حساب مجموعة حسابات جزئية" في `accounts_dashboard_screen.dart` (بجانب البلاطتين الحاليتين "كشف حساب مالي" و"كشف حساب تحليلي مفصل"، ~الأسطر 325-355) تدفع `AccountGroupStatementScreen`. تبقى شاشة `AccountStatementDetailScreen` كما هي دون تغيير أو إلغاء (خارج نطاق هذه الخطة) لأنها تخدم غرضاً مختلفاً، وهذه الخطة لا يجب أن تحذف بصمت وظيفة عاملة.

### 9. جولة التصميم المتجاوب والخطوط
يجب أن يستخدم جسم التقريرين الجديدين/المُعاد بناؤهما `Responsive.isMobile(context)` والاتفاقية المحلية الموجودة `isNarrow = width < 600` لاختيار أحجام خطوط الأعمدة/الحشوات (محاكاة منطق `isVeryCompact`/`isCompact` المستخدم فعلاً في `customer_statement_screen.dart`)، بحيث يطابق التخطيط المطبوع/المُصدَّر النموذج الورقي عند كل حجم شاشة، بدلاً من الانحناء إلى قائمة بطاقات على الهواتف.

## الاختبارات
- في `test/`: التوسعة بـ (أ) اختبار وحدة Dart نقي لـ `resolveStatementScope` يغطي كل التركيبات الأربعة للاختيار بما فيها "رئيسي+فرعي+جزئي بدون مجموعة" ← مستوى جزئي، و"+مجموعة" ← مستوى مجموعة؛ (ب) اختبار `fromJson` للحقول الجديدة/المُوسَّعة في النماذج بما فيها القراءة بحالتَي المفتاح (`ENTRY_NO` مقابل `entry_no`) وإصلاح الترميز العربي؛ (ج) اختبار Widget لشاشة `AccountGroupStatementScreen` يغطي حالات التحميل/الفراغ/الخطأ وتبديل إخفاء/إظهار الفلتر.
- تشغيل `flutter analyze` حتى تظهر "No issues found!" وتشغيل `flutter test`.
- في `kyApp_API`: تشغيل `php artisan route:list --path=api` للتأكد من 72 مساراً (بدل 71)، وتحديث `BusinessRoutesSealedTest`، وتشغيل `vendor/bin/pint --dirty --format agent` ومجموعة اختبارات Pest.

## التوثيق (مفروض بقواعد المشروع الدائمة — إضافة فقط دون حذف أو استبدال، مع إدراج طابع زمني لكل قيد)
- `todo.md`: إضافة قائمة مهام هذه الخطة تحت قسم جديد بالتاريخ.
- `devloping_history.md`: إضافة تغييرات جانب Flutter للتقريرين.
- `kyApp_API/devloping_history.md` (نسخة الـ submodule الخاصة): إضافة تغييرات المتحكمين والمسارين الجديدين.
- `DBdevloping_history.md`: إضافة نتائج فحص المخطط من `oracledb` MCP (عدم وجود `ACC_TRXN`، مسار الربط الحقيقي عبر `ENTRY_*`، اكتشاف جدول رموز العملات، افتراض `CUR_NO=1`=YR) لأن هذه الخطة تغيّر طريقة قراءة التطبيق لأوراكل حتى دون تنفيذ أي DDL.
- `db_commends.md`: إضافة كل عبارة SQL للقراءة فقط التي تُنفَّذ عبر `oracledb` MCP أثناء التنفيذ، مع الطابع الزمني واسم النموذج الذي نفّذها.
- `user_commends.md`: إضافة طلب المستخدم هذا نصّه كما ورد (النص العربي)، مع الطابع الزمني واسم نموذج الذكاء الاصطناعي المنفّذ للخطة.
- `kyApp_API/db_commends.md` أيضاً إذا نُفِّذ أي SQL عبر أدوات الـ submodule الخاصة.

## افتراضات يجب التأكد منها قبل/أثناء التنفيذ (معلَّمة، غير معطِّلة)
1. `CUR_NO = 1` (`YR` / "ريال يمني") تُعامَل كـ "عملة محلية" في كل التقرير الثاني لتقسيم الأعمدة؛ وكل العملات الأخرى تدخل في دلاء "عملة أجنبية". لا يوجد عمود علامة مثل `IS_LOCAL` في `CURRENCY`/`CUR_CODE` يمكن اشتقاق ذلك منه ديناميكياً.
2. دفتر التقرير الأول يستخدم `ENTRY_SUB.ACC_NO = :accNo` مباشرةً كسطور حركة الحساب نفسه (دون ربط إضافي بعمود `GIVING`، على عكس حالة العميل) — سيُتحقق من ذلك مقابل بيانات حقيقية لأحد حسابات `CHART_ACC` المعروفة (مثل `12910217` الظاهر في عيّنة `acc_report.pdf`) مقابل سطور `ENTRY_SUB` الفعلية قبل الاعتماد النهائي.
3. نافذة الـ 30 يوم الافتراضية للتقرير 1 تُحسب في الخادم فقط عندما لا يرسل العميل أي تواريخ؛ وأي اختيار تاريخ يدوي من العميل يتقدم دائماً على الافتراضي.
4. تشكيل النص العربي في ملف PDF المُصدَّر (الاتصال الصحيح للحروف وترتيبها في الملف الناتج) يُعالَج بضمّن خط TTF يدعم العربية فعلياً داخل حزمة `pdf` بدلاً من الاعتماد على Helvetica الافتراضي — هذه هي النقطة المعروفة بالصعبة في توليد PDF عربي من جهة العميل، وتحصل على فحص خاص بها أثناء التنفيذ (خطة بديلة: إعادة استخدام نهج تصوير شجرة الـ Widget المُصيَّرة أصلاً إلى PDF عبر `Printing.printWidget`/`RepaintBoundary` إذا ثبت أن التشكيل النصي المباشر عبر عناصر `pw` غير موثوق).