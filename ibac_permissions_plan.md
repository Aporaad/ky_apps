# خطة تنفيذ نظام المصادقة والصلاحيات بالهوية المباشرة (IBAC) — الإصدار 2

> **Identity-Based Access Control**: الصلاحيات تُمنح للمستخدم مباشرة في `APP_USERS_PERMISSIONS` بدون أدوار (Roles).
> **الحالة:** القرارات معتمدة من صاحب العمل (2026-10-17) — الخطة جاهزة للتنفيذ من الصفر حتى الاكتمال.
> **النطاق:** `ky_apps` (Flutter) + `kyApp_API` (Laravel 12) + Oracle 11g schema `ACCOUNTS`.

### الفهرس
1. ما تم التحقق منه من الواقع · 2. القرارات المعتمدة · 3. المتطلبات والتهيئة · 4. نموذج البيانات · 5. كتالوج الصلاحيات · 6. نظام الجلسات وتجديد التوكن · 7. التصميم الخلفي · 8. التصميم الأمامي · 9. المراحل (0–9) · 10. الاختبار اليدوي · 11. المخاطر · 12. النشر · 13. خارج النطاق · 14. قائمة التحقق

---

## 1. ما تم التحقق منه فعلياً (Oracle MCP + قراءة الكود)

| # | الحقيقة | المصدر | الأثر |
|---|---|---|---|
| 1 | `APP_USERS` موجود؛ **لا يوجد** `APP_PERMISSIONS` ولا `APP_USERS_PERMISSIONS` | `all_tables LIKE 'APP%'` | كل شيء يُبنى من الصفر |
| 2 | `USER_ID NUMBER(5)` مفتاح رئيسي وحيد، **بلا Sequence وبلا Trigger** | `all_constraints` (`APP_USERS_BRW_P1`) + `all_triggers` | إضافة معرّف بلا Trigger على جدول ERP مشترك |
| 3 | `USER_PASSWORD VARCHAR2(30)` وقيمته الحالية نص صريح `"1254"` (4 بايت) | `DUMP(user_password)` | توسيع العمود + إبقاء النص الصريح مؤقتاً (D2) |
| 4 | **`IS_ADMIN` غير موجود** | `all_tab_columns` | يُضاف (D1) |
| 5 | **لا يوجد عمود `USER_NO`** رغم استخدامه في `AuthController@login:53` و`User::$fillable:60` | `all_tab_columns` | استبداله بـ `USER_ID` في كل المواضع (D6) |
| 6 | `USER_TYPE NUMBER(1)`، والمستخدم الوحيد `arslan` قيمته `2` | `SELECT ... FROM APP_USERS` | اعتماد 1=موظف، 2=عميل (D5) + تصحيح صف arslan |
| 7 | `PERSONAL_ACCESS_TOKENS` فيه **`LAST_USED_AT`، `EXPIRES_AT`، `CREATED_AT`** ‏TIMESTAMP(6) | `all_tab_columns` | **لا حاجة لأي DDL للجلسات** |
| 8 | Sanctum `Guard.php:129` يُبطل التوكن عند `expires_at->isPast()`، و`:167` يحدّث `last_used_at` تلقائياً، و`:132` يوفّر `Sanctum::$accessTokenAuthenticationCallback` | `vendor/laravel/sanctum/src/Guard.php` | التجديد الانزلاقي بسياسة واحدة في `AppServiceProvider` |
| 9 | `config/sanctum.php: expiration => null`، والفحص في `Guard.php:128` يقارن بـ **`created_at`** | vendor + config | لا نضبط `expiration` (يكسر شرط «بدون انقطاع») |
| 10 | `CACHE` و`CACHE_LOCKS` موجودان في Oracle ببنية Laravel (`KEY/VALUE/EXPIRATION`) | `all_tables` + `all_tab_columns` | `Cache::remember` متاح للإعدادات ومجموعات الصلاحيات |
| 11 | `ManagementSection` (فهرس 7) placeholder فارغ؛ و`_menuItems` في الـ Drawer **غير مطابق** لـ `_sections` عند 4↔5 | `management_section.dart`, `collapsible_side_drawer.dart:27`, `employee_main_layout.dart:32` | القسم يُبنى + توحيد سجل الأقسام تمهيدي إلزامي |
| 12 | `AuthInterceptor` يرسل Bearer على كل طلب؛ `ErrorInterceptor` عند 401 يمسح التخزين ويستدعي `forceLogout()` | `dio_client.dart`, `error_interceptor.dart` | إنهاء الجلسة من الإدارة يظهر فوراً في العميل بدون كود جديد |
| 13 | صفر مفهوم صلاحيات: لا middleware ولا policies ولا gates؛ `bootstrap/app.php` فارغ تماماً | `bootstrap/app.php` + AGENTS.md | كل إضافة طبقة تحتاج موافقة (موثّقة هنا كمعتمدة D9) |
| 14 | 55 مساراً، منها 5 محمية فقط؛ `selectFromTable` يكشف `APP_USERS` | `routes/api.php` | الإغلاق بعد اكتمال الصلاحيات (D3) |
| 15 | **كتابة العربية عبر `encodeForOracle()` تُتلف البيانات**: اتصال التطبيق `charset=AL32UTF8` وقاعدة البيانات `WE8MSWIN1252`،
     فإرسال بايتات CP1256 الخام يجعل أوراكل يستبدلها بعلامة الاستبدال `0xBF` (تم إثباته بـ `DUMP()` بعد بذر أولي).
     المسار الصحيح للكتابة هو تحويل كل بايت CP1256 إلى محرف لاتيني بنفس الكود (`toOracleSearchChars()`) فيستقر البايت كما تفعل أنظمة الشركة القديمة. | `ArabicEncoding`، §4، §7 | كل مسار كتابة عربي في المشروع يحتاج التصحيح؛ البذر يستخدم الدالة الصحيحة |
| 16 | **يوجد `VIEW` اسمه `ACCOUNTS` داخل مخطط `ACCOUNTS`**: فمرجع PL/SQL مثل `ACCOUNTS.SEQ_X.NEXTVAL` يُقرأ كعمود من العرض ويفشل بـ `PLS-00302`
     ويُنشئ الزناد بحالة `INVALID` (اكتُشف عند أول بذر: `ORA-04098`). المحفِّزات (triggers) القديمة في المشروع تستخدم أسماء تسلسلات غير مسبوقة. | `ALL_OBJECTS (ACCOUNTS = VIEW)`، `ALL_ERRORS` | المحفِّزات الأربعة لـ IBAC تُنشَأ بـ `SEQ_X.NEXTVAL` بلا بادئة مخطط |
| 17 | **حدّ الربط 4000 بايت في كاش أوراكل (`ORA-01461`)**: عمود `CACHE.VALUE` من نوع CLOB، لكن Laravel يكتبه عبر
     `merge into "CACHE" using (select :value as "VALUE" from dual)`، وأوراكل ترفض ربط نص يتجاوز 4000 بايت داخل
     `FROM dual` فيرفع `ORA-01461: can bind a LONG value only for insert into a LONG column`. اكتُشف في المرحلة 2 عند
     أول تخزين لكتلة إعدادات الكاش (~5.4KB محمّلة بالأسماء والأوصاف العربية) — ولو تُرك لانهار كل طلب مصادَق عليه.
     | `ALL_TAB_COLUMNS (CACHE = KEY VARCHAR2/VALUE CLOB/EXPIRATION NUMBER)`، سجل `logs/laravel.log` |
     سقف حمولة الكاش **3000 بايت** في `SettingsStore` و`PermissionResolver`؛ العربية لا تدخل الكاش إطلاقاً —
     `SettingsStore::all()` يخزّن الحقول الرقمية/المعرفية فقط و`definitions()` تقرأ التسميات العربية من القاعدة مباشرة |
| 18 | **الأعمدة التاريخية الفارغة لا تعود `null`**: العمود `DATE` الفارغ في أوراكل يصل عبر اتصال التطبيق أحياناً
     كـ `false` وأحياناً كنص فارغ، حسب مسار القراءة (`selectOne` الخام مقابل نماذج Eloquent). أي استخدام مباشر مثل
     `$token->expires_at->isPast()` أو `?->toDateTimeString()` يفجر الطلب (`Call to a member function … on bool`)،
     والأنكى أن الاستثناء داخل `Sanctum::$accessTokenAuthenticationCallback` يبتلعه `AppServiceProvider` ويعيد قرار
     Sanctum الأصلي **بصمت** ⇒ الجلسات القديمة تُقبل للأبد بلا تجديد ولا انتهاء. اكتُشف في المرحلة 3 عند أول اختبار
     لـ `GET /auth/permissions` على توكن بلا `EXPIRES_AT`.
     | `SELECT * FROM PERSONAL_ACCESS_TOKENS WHERE EXPIRES_AT IS NULL` + `gettype()` على الحالتين |
     دالة توحيد واحدة `SessionPolicy::toDate(mixed): ?Carbon` تمر عبرها كل قراءات `expires_at`/`created_at`؛
     و`Sanctum\Guard` نفسه آمن عملياً لأن شرطه `! $accessToken->expires_at` يختصر قبل استدعاء أي طريقة |
| 19 | **اسم المربَّط لا يجوز أن يكون كلمة محجوزة في أوراكل**: `:by` في
     `SET … UPDATED_BY = :by` يفشل بـ `ORA-01745: invalid host/bind variable name` قبل أي تنفيذ. الأخطر أن العلة
     بقيت مكتومة مرحلتين كاملتين لأن مسار الحفظ لم يُستدعَ من اختبار ولا من واجهة — `SettingsStore::set()` و
     `UserAdminController@toggle` كانا سيُرجعان 500 لأول ضغطة زر حقيقية. نفس العائلة من الأخطاء: مربَّط مُعلَن
     وغير مستخدم في الاستعلام ⇒ `ORA-01008: not all variables bound` (لذلك استعلام العدّ يحذف ربطات `rn_*`
     بـ `array_diff_key`) | أول تنفيذ فعلي لمسار الحفظ في `SecuritySettingsTest`، وطباعة متن الاستجابة
     في `TmpDiagTest` (اختبار تشخيصي مؤقت حُذف بعد تأكيد السبب الجذري) |
     أسماء مربَّطات موسومة بالمجال حصراً (`:setting_value`, `:updated_by`, `:setting_key`, `:activated`)، ومسح
     `grep` دوري لكل أسماء المربَّطات مقابل قائمة الكلمات المحجوزة، وتضييق ربطات كل استعلام إلى ما يستخدمه فعلاً |
| 20 | **ثوابت PHP داخل نطاق أسماء تُحَل محلياً أولاً**: كتابة `filter_var($v, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_UNSET)`
     داخل `namespace App\Support` ترمي `Undefined constant "App\Support\FILTER_NULL_ON_UNSET"` — والثابت أصلاً
     غير موجود في PHP (الصحيح منطقياً `FILTER_NULL_ON_FAILURE`، والأمن منطقياً قائمة صريحة). الأثر: أي إعداد
     `bool` يُرجع 500 | نفس متن تشخيص الاستجابة أعلاه | استُبدل `filter_var` بقائمة قبول/رفض صريحة عبر `match` على نوع
     القيمة ثم `in_array` صارم، فلا إنزلاق صامت إلى `false` لنصوص غريبة مثل `maybe` |
| 21 | **`NavigationBar` يشترط وجهين على الأقل**: التأكيد `destinations.length >= 2` داخل إطار Material 3،
     فمستخدم ممنوحاً لقسم واحد ظاهر في الشريط السفلي كان ينهار عند أول دخول للبوابة. لم يظهر هذا في أي
     اختبار سابق لأن المنحنى السابق كان يفهرس تسعة أقسام دائماً. | `flutter test` أول توسيع لـ
     `responsive_layout_test.dart` بعد توحيد السجل |
     الشريط لا يُرسم إلا إذا كان `barSections.length >= 2`، ويصير `null` بدونه — والقائمة الجانبية
     والـ Drawer لا يشترطان ذلك لأنهما يبنيان من `visible` مباشرة |
| 22 | **شريط العنوان الفرعي في بطاقة العملاء يتجاوز العرض**: `RenderFlex overflowed by 42 pixels` في
     `customers_dashboard_screen.dart` عند عرض النص على عرض جوال، وظهر فقط لما صارت لوحة العملاء هي
     القسم المرئي بعد الحجب. | `flutter test` (نفس التوسيع) |
     أُحيط النص بـ `Flexible` مع `maxLines: 1` و`TextOverflow.ellipsis` بدل تصغير الخط أو فرض عرض ثابت |
| 23 | **انحراف مُقصَّد عن §8.1**: الخطة تنص على `AppLifecycleListener`، والمنفَّذ هو
     `WidgetsBindingObserver` داخل `PermissionsNotifier` نفسه. | كود `permissions_notifier.dart` |
     سلوك مكافئ (تحديث عند `resumed` مع حد 15 ثانية) بلا كائن إضافي يُدار عمره؛ موثّق هنا حتى لا يُقرأ
     لاحقاً كنسيان. عند الإزالة يجب أن تُزال `removeObserver` في `dispose` وإلا تسرّب الذاكرة صامت |
| 24 | **`Wrap` يقيس أبناءه بعرض غير محدود**: كل `Row(mainAxisSize: min)` داخله يفيض عند نصّ طويل — |
     `flutter test` (مجموعة breakpoints على 360) | أربع مواطن في ودجات الإدارة (وقت الجلسة، رقائق
     «أساسيات القسم»، سطر المعلومات، زرّا الإنهاء). المعالج المرجعي: `LayoutBuilder` خارج `Wrap`
     يمرّر `constraints.maxWidth` إلى `ConstrainedBox` ثم `Flexible` + `maxLines: 1` +
     `TextOverflow.ellipsis`؛ والتوسيع إلى `Row` أفقي قابل للتمرير حلّ أسوأ لأنه يخفي المحتوى |
| 25 | **`Override` ليست نوعاً مُصدَّراً** في `flutter_riverpod` 3.3.2: متغيّر `final List<Override> x` |
     `flutter analyze` | يفشل بـ «The name 'Override' isn't a type». قوائم `overrides:` تكتب داخل
     الاستدعاء مباشرة، و`permissionsCatalogProvider.overrideWith((ref) => Future.value(catalog))`
     هو الشكل الصحيح لمزيف `FutureProvider` في الاختبار |
| 26 | **الحقول `late` بلا إسناد في `initState` تنهار عند أول بناء**، ونموذج الإنشاء ينجو بالصدفة |
     `test/ibac_test.dart` + مجموعة breakpoints | لأن `widget.isCreate || _changePassword` يقصر
     التقييم فلا يقرأ الحقل. الصيغة الآمنة هنا: قيمة افتراضية صريحة (`bool _changePassword = false;`)
     بدل `late` — و`late` لا تُستخدم إلا لما يُسنَد في `initState` حكماً |
| 27 | **أزرار الاختصار تُضلل أثناء البحث وعلى الهدف المقفل**: «تحديد كل القسم» كان يظهر محقَّقاً بينما |
     `test/ibac_test.dart` (حالتا search وdisabled) | الشاشة تعرض نتائج مطابقة جزئية، والهدف مديرٌ
     لا يُمنح. القاعدة: أي فعل جماعي يُرسم فقط حين تكون المجموعة المعروضة = المجموعة الكاملة
     (`!isSearchOn && !disabled`)، والاثنين معاً اختباران صريحان لا ملاحظة عابرة |

---

## 2. القرارات المعتمدة (نهائية)

| # | القرار | ما سيُنفَّذ |
|---|---|---|
| **D1** | المدير العام | **`IS_ADMIN NUMBER(1) DEFAULT 0 NOT NULL`** على `APP_USERS` كمرجع حاسم مع تجاوز (bypass) كامل، **و**الاحتفاظ بدلالة `system.*` في المنح. لا يعدّل `IS_ADMIN` إلا مستخدم يملك `IS_ADMIN=1` (منع تصعيد)؛ والنظام لا يُقفل لأن الحقل لا يتبع جدول المنح |
| **D2** | كلمات المرور | **توسيع** `USER_PASSWORD` إلى `VARCHAR2(100)` و**إبقاء النص الصريح مؤقتاً**؛ التجزئة `Hash::make` مؤجَّلة لجولة قادمة (فرع `Hash::check` القائم في `AuthController:82` يبقى سليماً، والسعة الجديدة تهيّئ له بلا DDL لاحقاً) |
| **D3** | إغلاق مسارات الأعمال | **في نفس الإطلاق**، فور اكتمال نظام الصلاحيات وإنشاء صلاحيات لكل الأقسام (المرحلة 7 ليست مؤجَّلة) |
| **D4** | نطاق البيانات بالفرع | **لا** — `BRANCH_NO` عرض/فلترة اختيارية في الواجهة فقط، ولا يدخل في أي استعلام أمني |
| **D5** | دلالة `USER_TYPE` | **1 = موظف (employee)، 2 = عميل (customer)**؛ خريطة صريحة في الخلفية والعميل + `UPDATE APP_USERS SET USER_TYPE=1 WHERE USER_ID=1` (arslan موظف/مدير) |
| **D6** | `USER_NO` | استبداله بـ **`USER_ID`** في: `AuthController@login` (البحث بالرقم)، `User::$fillable`، وحمولة `user` في `login/me/biometricLogin` |
| **D7** | الجلسات | تجديد انزلاقي تلقائي للنشيط **دون شعوره بالانقطاع**؛ وانتهاء الجلسة عند انتهاء المهلة لغير النشيط؛ القيم من جدول **`APP_SETTINGS`** قابل للتعديل من «إعدادات الأمان» (§6) |
| **D8** | واجهة الإدارة | بطاقة «إدارة المستخدمين» → شاشة قائمة المستخدمين (بحث/فلترة/فرز + زر **إضافة مستخدم** أعلى القائمة) وأزرار داخل كل بطاقة: **تعديل · صلاحيات · تعطيل · حذف · سجل نشاط**؛ منح الصلاحيات **داخل نموذج الإنشاء** مرتّبة حسب الأقسام؛ النقر على أيقونة «صلاحيات» يفتح شاشة التحكم بصلاحيات ذلك المستخدم؛ + بطاقتا **«الجلسات النشطة»** و**«إعدادات الأمان»** |
| **D9** | كائنات جديدة معتمدة | `APP_PERMISSIONS`, `APP_USERS_PERMISSIONS`, `APP_SETTINGS`, `APP_USER_ACTIVITY` + عمود `IS_ADMIN` + توسيع `USER_PASSWORD` + `SEQUENCE` للمستخدمين |

---

## 3. المتطلبات والتهيئة (قبل أي كود)

### 3.1 بيئة
- PHP `^8.2.12` + `oci8/pdo_oci` مع Oracle Instant Client 11g (تعارض `oci8_19` الموثّق في `user_commends.md`).
- `composer install` نظيف؛ `php artisan config:show database.default` = `oracle`؛ `CACHE_STORE=database`.
- Flutter `Dart ^3.7.2`، `flutter pub get` — **بلا codegen وبلا اعتماديات جديدة**.
- صلاحية DDL على `ACCOUNTS` عبر موصل Oracle، واتصال LAN بالـ API لتجربة جهاز حقيقي.

### 3.2 فرع العمل وفصل الـ submodule
```bash
git -C ky_apps checkout -b feat/ibac-permissions
git -C ky_apps/kyApp_API checkout -b feat/ibac-permissions
# أي commit داخل kyApp_API أولاً، ثم bump للمؤشر في المستودع الأب
```

### 3.3 نقطة استرجاع قبل DDL (إلزامية)
```sql
CREATE TABLE ACCOUNTS.APP_USERS_BAK_IBAC AS SELECT * FROM ACCOUNTS.APP_USERS;
-- لا حذف لأي بَاك قبل تشغيل النظام عاماً عملياً واحداً على الأقل
```

### 3.4 حدود الأمان التشغيلية
- لا `UPDATE/DELETE/DDL` على جداول الأعمال خارج النصوص المعتمدة في هذه الخطة.
- لا commit لـ `.env` أو كلمات مرور Oracle؛ لا `--no-verify`؛ لا force-push.

---

## 4. نموذج البيانات (Oracle 11g)

قيود مطبَّقة: لا Identity columns، معرّفات ≤ 30 حرفاً، `prefix_schema=accounts`، عربية CP1256.
الملفات: `kyApp_API/database/oracle/01_ibac_schema.sql` · `02_ibac_seed.php` · `03_ibac_bootstrap.php` · `04_ibac_rollback.sql`.
البذر والتهيئة **PHP** لا SQL: موصل أوراكل بترميز عميل AL32UTF8 يحوّل بايتات CP1256 إلى `0xBF` فلا يمكن تمرير العربية من ملف `.sql`؛
وسكربتات PHP تُشتق من `PermissionCatalog` نفسه. تسجيل كل أمر في `db_commends.md`.

### 4.1 تعديل `APP_USERS`

```sql
ALTER TABLE ACCOUNTS.APP_USERS ADD (IS_ADMIN NUMBER(1) DEFAULT 0 NOT NULL);
COMMENT ON COLUMN ACCOUNTS.APP_USERS.IS_ADMIN IS 'مدير النظام - يتجاوز كل الصلاحيات';

ALTER TABLE ACCOUNTS.APP_USERS MODIFY (USER_PASSWORD VARCHAR2(100));   -- D2

UPDATE ACCOUNTS.APP_USERS SET IS_ADMIN = 1, USER_TYPE = 1 WHERE USER_ID = 1;  -- D1 + D5
COMMIT;

-- معرّف المستخدمين الجدد: Sequence صريح **بلا Trigger** (النظام القديم يُدخل على الجدول)
CREATE SEQUENCE ACCOUNTS.SEQ_APP_USERS_ID START WITH 100 INCREMENT BY 1 NOCACHE;
-- قبل التنفيذ: SELECT NVL(MAX(USER_ID),0)+1 FROM ACCOUNTS.APP_USERS;  ← اضبط START WITH فوق الناتج
```
> إضافة عمود بـ `DEFAULT … NOT NULL` على جدول صغير فورية، ولا تكسر إدخالات الـ ERP (يأخذ الافتراضي
> عند تجاهل العمود). مع ذلك تُجرَّب على بيئة التطوير أولاً.

### 4.2 `APP_PERMISSIONS` — كتالوج الصلاحيات

```sql
CREATE TABLE ACCOUNTS.APP_PERMISSIONS (
  PERMISSION_ID   NUMBER(6)     NOT NULL,
  PERMISSION_CODE VARCHAR2(60)  NOT NULL,           -- module.action
  MODULE_CODE     VARCHAR2(30)  NOT NULL,
  ACTION_CODE     VARCHAR2(30)  NOT NULL,
  NAME_AR         VARCHAR2(150) NOT NULL,
  NAME_EN         VARCHAR2(150),
  IS_CORE         NUMBER(1)     DEFAULT 0 NOT NULL, -- 1 = view/create/update/delete
  SORT_ORDER      NUMBER(4)     DEFAULT 0,
  IS_ACTIVE       NUMBER(1)     DEFAULT 1 NOT NULL,
  DESCRIPTION_AR  VARCHAR2(500),
  CREATED_ON      DATE          DEFAULT SYSDATE,
  CREATED_BY      NUMBER(5),
  LAST_UPDATED_ON DATE,
  LAST_UPDATED_BY NUMBER(5),
  CONSTRAINT APP_PERM_PK      PRIMARY KEY (PERMISSION_ID),
  CONSTRAINT APP_PERM_CODE_UQ UNIQUE (PERMISSION_CODE),
  CONSTRAINT APP_PERM_CORE_CK CHECK (IS_CORE IN (0,1)),
  CONSTRAINT APP_PERM_ACT_CK  CHECK (IS_ACTIVE IN (0,1))
);
CREATE INDEX ACCOUNTS.APP_PERM_MOD_IX ON ACCOUNTS.APP_PERMISSIONS (MODULE_CODE, SORT_ORDER);

CREATE SEQUENCE ACCOUNTS.SEQ_APP_PERMISSIONS START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_PERMISSIONS
BEFORE INSERT ON ACCOUNTS.APP_PERMISSIONS FOR EACH ROW
BEGIN
  IF :NEW.PERMISSION_ID IS NULL THEN
    SELECT ACCOUNTS.SEQ_APP_PERMISSIONS.NEXTVAL INTO :NEW.PERMISSION_ID FROM DUAL;
  END IF;
END;
/
```

### 4.3 `APP_USERS_PERMISSIONS` — المنح المباشر للمستخدم (جوهر IBAC)

```sql
CREATE TABLE ACCOUNTS.APP_USERS_PERMISSIONS (
  ID             NUMBER(9)  NOT NULL,
  USER_ID        NUMBER(5)  NOT NULL,
  PERMISSION_ID  NUMBER(6)  NOT NULL,
  GRANTED_BY     NUMBER(5),                       -- الفاعل (تدقيق)
  GRANTED_ON     DATE       DEFAULT SYSDATE,
  EXPIRES_ON     DATE,                            -- NULL = دائم
  IS_ACTIVE      NUMBER(1)  DEFAULT 1 NOT NULL,   -- تعطيل منحنى بلا حذف
  NOTE           VARCHAR2(200),
  CONSTRAINT APP_UQ_PK        PRIMARY KEY (ID),
  CONSTRAINT APP_USER_PERM_UQ UNIQUE (USER_ID, PERMISSION_ID),
  CONSTRAINT APP_UQ_USER_FK   FOREIGN KEY (USER_ID)
      REFERENCES ACCOUNTS.APP_USERS (USER_ID) ON DELETE CASCADE,
  CONSTRAINT APP_UQ_PERM_FK   FOREIGN KEY (PERMISSION_ID)
      REFERENCES ACCOUNTS.APP_PERMISSIONS (PERMISSION_ID),
  CONSTRAINT APP_UQ_ACTIVE_CK CHECK (IS_ACTIVE IN (0,1))
);
CREATE INDEX ACCOUNTS.APP_UQ_USER_IX ON ACCOUNTS.APP_USERS_PERMISSIONS (USER_ID);
CREATE INDEX ACCOUNTS.APP_UQ_PERM_IX ON ACCOUNTS.APP_USERS_PERMISSIONS (PERMISSION_ID);

CREATE SEQUENCE ACCOUNTS.SEQ_APP_USERS_PERM START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_USERS_PERM
BEFORE INSERT ON ACCOUNTS.APP_USERS_PERMISSIONS FOR EACH ROW
BEGIN
  IF :NEW.ID IS NULL THEN
    SELECT ACCOUNTS.SEQ_APP_USERS_PERM.NEXTVAL INTO :NEW.ID FROM DUAL;
  END IF;
END;
/
```

### 4.4 `APP_SETTINGS` — إعدادات الأمان (D7 / D8)

```sql
CREATE TABLE ACCOUNTS.APP_SETTINGS (
  SETTING_ID     NUMBER(6)     NOT NULL,
  SETTING_KEY    VARCHAR2(60)  NOT NULL,
  SETTING_VALUE  VARCHAR2(500),
  VALUE_TYPE     VARCHAR2(20)  DEFAULT 'int' NOT NULL,  -- int|bool|string|json
  NAME_AR        VARCHAR2(150) NOT NULL,
  DESCRIPTION_AR VARCHAR2(500),
  MIN_VALUE      NUMBER(10),
  MAX_VALUE      NUMBER(10),
  IS_LOCKABLE    NUMBER(1)     DEFAULT 0 NOT NULL,      -- 1 = لا يعدَّل من الواجهة
  SORT_ORDER     NUMBER(4)     DEFAULT 0,
  UPDATED_BY     NUMBER(5),
  UPDATED_ON     DATE,
  CONSTRAINT APP_SET_PK      PRIMARY KEY (SETTING_ID),
  CONSTRAINT APP_SET_KEY_UQ  UNIQUE (SETTING_KEY),
  CONSTRAINT APP_SET_TYPE_CK CHECK (VALUE_TYPE IN ('int','bool','string','json'))
);

CREATE SEQUENCE ACCOUNTS.SEQ_APP_SETTINGS START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_SETTINGS
BEFORE INSERT ON ACCOUNTS.APP_SETTINGS FOR EACH ROW
BEGIN
  IF :NEW.SETTING_ID IS NULL THEN
    SELECT ACCOUNTS.SEQ_APP_SETTINGS.NEXTVAL INTO :NEW.SETTING_ID FROM DUAL;
  END IF;
END;
/
```

### 4.5 `APP_USER_ACTIVITY` — سجل نشاط المستخدمين (D8)

```sql
CREATE TABLE ACCOUNTS.APP_USER_ACTIVITY (
  ACTIVITY_ID    NUMBER(11)    NOT NULL,
  USER_ID        NUMBER(5),                             -- الفاعل (NULL عند فشل دخول باسم مجهول)
  TARGET_USER_ID NUMBER(5),                             -- المُستهدَف بالإجراء
  ACTION_CODE    VARCHAR2(60)  NOT NULL,   -- login | login_failed | logout | biometric_login |
                                           -- users.create | users.update | users.toggle | users.delete |
                                           -- users.permissions_sync | sessions.terminate | settings.update
  MODULE_CODE    VARCHAR2(30),
  ENTITY_TYPE    VARCHAR2(40),                           -- app_user | session | setting
  ENTITY_ID      VARCHAR2(60),
  DESCRIPTION_AR VARCHAR2(1000),                         -- نص عربي مُهيّأ يظهر في «سجل نشاط»
  STATUS         VARCHAR2(10)  DEFAULT 'success' NOT NULL,
  IP_ADDRESS     VARCHAR2(45),
  USER_AGENT     VARCHAR2(200),
  PLATFORM       VARCHAR2(20),
  CREATED_ON     DATE          DEFAULT SYSDATE,
  CONSTRAINT APP_ACT_PK        PRIMARY KEY (ACTIVITY_ID),
  CONSTRAINT APP_ACT_STATUS_CK CHECK (STATUS IN ('success','failed'))
);
CREATE INDEX ACCOUNTS.APP_ACT_USER_IX ON ACCOUNTS.APP_USER_ACTIVITY (USER_ID, CREATED_ON);
CREATE INDEX ACCOUNTS.APP_ACT_TGT_IX  ON ACCOUNTS.APP_USER_ACTIVITY (TARGET_USER_ID, CREATED_ON);
CREATE INDEX ACCOUNTS.APP_ACT_MOD_IX  ON ACCOUNTS.APP_USER_ACTIVITY (MODULE_CODE, CREATED_ON);

CREATE SEQUENCE ACCOUNTS.SEQ_APP_ACTIVITY START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE OR REPLACE TRIGGER ACCOUNTS.TRG_APP_ACTIVITY
BEFORE INSERT ON ACCOUNTS.APP_USER_ACTIVITY FOR EACH ROW
BEGIN
  IF :NEW.ACTIVITY_ID IS NULL THEN
    SELECT ACCOUNTS.SEQ_APP_ACTIVITY.NEXTVAL INTO :NEW.ACTIVITY_ID FROM DUAL;
  END IF;
END;
/
```

### 4.6 بذر الإعدادات

| `SETTING_KEY` | الافتراضي | النوع | الحدود | الدلالة (D7) |
|---|---|---|---|---|
| `session_idle_minutes` | `240` | int | 5 – 10080 | مهلة الخمول: لا نشاط خلالها ⇒ الجلسة تنتهي |
| `session_absolute_days` | `14` | int | 1 – 365 | العمر الأقصى المطلق للجلسة منذ إنشائها |
| `session_touch_threshold_minutes` | `5` | int | 1 – 60 | حدّ كتابة التجديد الانزلاقي (يقلّل كتابات `PERSONAL_ACCESS_TOKENS`) |
| `single_active_session_per_device` | `0` | bool | — | جلسة واحدة لكل مستخدم (تُفعَّل عند اكتمال البنية، §13) |
| `password_min_length` | `4` | int | 4 – 32 | الحد الأدنى لطول كلمة المرور (4 = توافق مع إرث `"1254"`) |
| `max_failed_logins` | `0` | int | 0 – 20 | 0 = معطّل؛ القفل يحتاج عمودَي عدّاد (§11) |
| `lockout_minutes` | `15` | int | 1 – 1440 | مع `max_failed_logins` |
| `biometric_login_enabled` | `1` | bool | — | إتاحة الدخول بالبصمة نظامياً |
| `activity_log_retention_days` | `180` | int | 30 – 3650 | مدة الاحتفاظ بسجل النشاط |
| `maintenance_message` | `` | string | ≤500 | رسالة تظهر عند 503 (اختياري) |

### 4.7 تحقق بعد DDL
```sql
SELECT table_name FROM all_tables WHERE owner='ACCOUNTS' AND table_name LIKE 'APP\_%' ESCAPE '\';
SELECT column_name, data_type, data_length FROM all_tab_columns
 WHERE owner='ACCOUNTS' AND table_name='APP_USERS' AND column_name IN ('IS_ADMIN','USER_PASSWORD');
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;          -- = عدد الكتالوج (§5)
SELECT COUNT(*) FROM ACCOUNTS.APP_SETTINGS;             -- 10
SELECT object_name, status FROM all_objects
 WHERE owner='ACCOUNTS' AND object_name LIKE 'TRG_APP%' AND status <> 'VALID';   -- صفر صفوف
```

### 4.8 التراجع `04_ibac_rollback.sql`
```sql
DROP TABLE ACCOUNTS.APP_USER_ACTIVITY;     DROP SEQUENCE ACCOUNTS.SEQ_APP_ACTIVITY;
DROP TABLE ACCOUNTS.APP_USERS_PERMISSIONS; DROP SEQUENCE ACCOUNTS.SEQ_APP_USERS_PERM;
DROP TABLE ACCOUNTS.APP_PERMISSIONS;       DROP SEQUENCE ACCOUNTS.SEQ_APP_PERMISSIONS;
DROP TABLE ACCOUNTS.APP_SETTINGS;          DROP SEQUENCE ACCOUNTS.SEQ_APP_SETTINGS;
DROP SEQUENCE ACCOUNTS.SEQ_APP_USERS_ID;
-- IS_ADMIN يبقى (عمود غير مؤذٍ)؛ للإزالة الكاملة: ALTER TABLE ACCOUNTS.APP_USERS DROP COLUMN IS_ADMIN;
```

---

## 5. كتالوج الصلاحيات — 17 وحدة / 93 صلاحيّة (76 فعلاً + 16 منحاً عاماً للوحدات + `system.*`)

**القاعدة:** لكل قسم/واجهة تبدأ الأفعال الأساسية الأربعة `view · create · update · delete`
(`IS_CORE=1`) ثم الصلاحيات الإضافية من بعدها.

| الوحدة | الأساسية | الإضافية | يقابلها في الكود |
|---|---|---|---|
| `dashboard` | view | — | `HomeDashboardSection` |
| `sales` | view, create, update, delete | print, export | `SalesSection` |
| `tailoring` | view, create, update, delete | print, deliver | `TailoringSection` (كروت التفصيل) |
| `customers` | view, create, update, delete | statement, print, export, edit_limit | `/customers/**` |
| `employees` | view, create, update, delete | toggle, statement | `/workers/employees/**` |
| `cutters` | view, create, update, delete | toggle, statement | `/workers/cutters/**` |
| `tailors` | view, create, update, delete | toggle, statement | `/workers/tailors/**` |
| `accounts` | view, create, update, delete | structure_manage, statement, print, export | `/accounts/**` |
| `currencies` | view, create, update, delete | prices_view, prices_manage | `/currencies/**` |
| `invoices` | view | print, export | `/invoices/**` |
| `stores` | view, create, update, delete | — | `StoresSection` |
| `reports` | view | export | كشوفات وتقارير |
| `management` | view | — | `ManagementSection` |
| `users` | view, create, update, delete | toggle, permissions_manage, activity_view, admin_flag_manage | `/users/**` (جديد) |
| `sessions` | view | terminate | `/sessions/**` (جديد) |
| `settings` | view, update | security_manage | `/settings/**` (جديد) + شاشات الإعدادات |
| `system` | `system.*` | — | منح عام (دلالة مكمّلة لـ `IS_ADMIN`) |

* **الترقيم:** `SORT_ORDER = moduleIndex*100 + actionIndex` ⇒ الأساسي قبل الإضافي في أي عرض بلا منطق ترتيب في الواجهة.
* **الأسماء العربية** تُولَّد حتمياً من `PermissionCatalog` (مثال `customers.statement → عرض كشف حساب العميل`)
  وتُكتب بـ `ArabicEncoding::toOracleSearchChars()` (وليس `encodeForOracle()` — انظر البندَين 15 و16 في §1)؛ وملف البذر **يُشتق من نفس المصدر** فلا يتباعد الخادم عن العميل.
* **قواعد التسمية:** `<module>.<action>` بحروف صغيرة، نقطة واحدة، ≤ 60؛ Wildcard فقط `module.*` أو `system.*`؛
  لا `*.*` ولا بادئات جزئية (`cust*`) — تُرفض في التحقق.

### منطق التقييم (Resolution)
```
can(user, code):
  user.IS_ADMIN == 1                                 → true     (D1)
  grants contains 'system.*'                         → true     (دلالة احتياطية)
  grants contains code                               → true
  grants contains modulePrefix(code) + '.*'          → true
  وإلا                                               → false    (Deny-by-default)

منح صالح = up.IS_ACTIVE = 1 AND p.IS_ACTIVE = 1
           AND (up.EXPIRES_ON IS NULL OR up.EXPIRES_ON > SYSDATE)
```

---

## 6. نظام الجلسات والتجديد الانزلاقي (D7)

### 6.1 لماذا لا نضبط `sanctum.expiration`
`Guard.php:128` يقارن `created_at` بعدد دقائق `config('sanctum.expiration')` ⇒ عمر **مطلق** ثابت:
لو ضبطناه على 240 دقيقة لطُرد المستخدم النشيط كل 4 ساعات رغم عمله المستمر — وهذا مرفوض صراحةً في طلبك.
لذلك: إبقاء `expiration => null` + بناء السياسة على **`EXPIRES_AT`** الذي يحترمه Sanctum في `Guard.php:129`
(العمود موجود فعلاً في Oracle)، وتحديثه انزلاقياً.

### 6.2 المنطق
```
عند إنشاء التوكن (login / biometricLogin):
    EXPIRES_AT = now + session_idle_minutes      (CREATED_AT يملؤه Sanctum)

عند كل طلب مصادق عليه (Sanctum::$accessTokenAuthenticationCallback → SessionPolicy::validate):
    1) IS_ACTIVATED != 1                            → 401 «هذا الحساب معطل»
    2) EXPIRES_AT <= now                            → 401 «انتهت مدة الخمول، سجّل الدخول مجدداً»
    3) CREATED_AT + session_absolute_days < now     → 401 «انتهت صلاحية الجلسة»
    4) خلاف ذلك → قبول، وإن كان
       EXPIRES_AT < now + idle − touch_threshold   → UPDATE
           LAST_USED_AT = now, EXPIRES_AT = now + idle, UPDATED_AT = now
       (كتابة واحدة لكل جلسة كل ~5 دقائق، لا كتابة على كل طلب)
```
**النتيجة:** النشيط يتجدد توكنه بصمت تام؛ غير النشيط يسقط بعد المهلة، والسقوط يمرّ بالمسار القائم
`ErrorInterceptor` (401) → `clearAll()` → `AuthNotifier.forceLogout()` → `/login`.

### 6.3 التنفيذ (ملفان، بلا middleware إضافي)
```php
// app/Support/SessionPolicy.php
final class SessionPolicy
{
    public function __construct(private SettingsStore $settings) {}

    public function validate(mixed $accessToken, bool $isValid): bool
    {
        if (! $isValid || ! $accessToken) {
            return false;
        }

        $tokenable = $accessToken->tokenable;

        if (! $tokenable || (int) $tokenable->getAttribute('IS_ACTIVATED') !== 1) {
            return false;
        }

        $idle     = (int) $this->settings->get('session_idle_minutes', 240);
        $absolute = (int) $this->settings->get('session_absolute_days', 14);

        if ($accessToken->expires_at && $accessToken->expires_at->isPast()) {
            return false;
        }

        if ($accessToken->created_at && $accessToken->created_at->lt(now()->subDays($absolute))) {
            return false;
        }

        $this->slide($accessToken, $idle);

        return true;
    }

    private function slide(mixed $token, int $idle): void
    {
        $threshold = (int) $this->settings->get('session_touch_threshold_minutes', 5);
        $newExpiry = now()->addMinutes($idle);

        if (! $token->expires_at || $token->expires_at->lt($newExpiry->copy()->subMinutes($threshold))) {
            $token->forceFill(['expires_at' => $newExpiry, 'updated_at' => now()])->saveQuietly();
        }
    }
}
```
```php
// app/Providers/AppServiceProvider.php::boot() — أول تعديل له
Sanctum::$accessTokenAuthenticationCallback = fn ($accessToken, bool $isValid) =>
    app(\App\Support\SessionPolicy::class)->validate($accessToken, $isValid);
```
* `SettingsStore` يقرأ `APP_SETTINGS` بـ `Cache::remember('ky:settings', 300, …)` + `Cache::forget` عند
  كل تعديل ⇒ صفر استعلام إضافي لكل طلب بعد أول قراءة (`CACHE` جاهز).
* **ترحيل ناعم:** الجلسات القديمة (`EXPIRES_AT IS NULL`) تُقبل وتُمنح مهلة كاملة في أول طلب (فرع
  `! $token->expires_at` أعلاه) فلا يُطرد أحد عند النشر.
* **تنبيه Oracle:** `NAME` و`ABILITIES` في `PERSONAL_ACCESS_TOKENS` نوعهما **CLOB** — لا `LIKE` ولا `ORDER BY`
  عليهما؛ اعرض `substr(NAME)` في PHP أو تجاهله في الفلترة.

### 6.4 إنهاء جلسة عنوة من الإدارة (D8)
* `DELETE /api/sessions/{id}` ⇒ `UPDATE … SET EXPIRES_AT = SYSDATE, UPDATED_AT = SYSDATE WHERE ID = :id`
  ⇒ أول طلب من الجهاز يرجع 401 فيُخرج فوراً، والصف يبقى في القائمة بحالة «منتهية».
* `DELETE /api/sessions/user/{userId}` ⇒ إنهاء كل جلسات مستخدم.
* تعطيل/حذف مستخدم ⇒ إنهاء جلساته في نفس العملية (تعديل مباشر على `PERSONAL_ACCESS_TOKENS` حتى يظهر
  الأثر في «الجلسات النشطة» أيضاً).
* `PUT /users/{id}/permissions` بمعامل `logout_others=1` (افتراضي 1) ⇒ إنهاء الجلسات لأن المنح لا يُقرأ
  من التوكن بل من القاعدة لكل طلب.

### 6.5 الإعدادات من الواجهة
`GET /api/settings` (كل الإعدادات بأسمائها العربية وأنواعها وحدودها) و`PUT /api/settings`
(مصفوفة key/value مع تحقق `VALUE_TYPE` و`MIN_VALUE/MAX_VALUE` ورفض `IS_LOCKABLE=1`) خلف
`permission:settings.view` / `permission:settings.security_manage`.

---

## 7. التصميم الخلفي (Laravel 12)

الالتزام بتسطّح المشروع: لا Form Requests، لا API Resources، لا Policies؛ المنطق في Controllers؛
استجابات arrays يدوية بالـ envelope الحالي؛ رسائل ثنائية اللغة. **الطبقات الجديدة معتمدة (D9).**

### 7.1 الملفات الجديدة
```
app/Support/PermissionCatalog.php    مصدر الحقيقة: 17 وحدة × أفعال + أسماء عربية + IS_CORE/SORT_ORDER
app/Support/PermissionResolver.php   منح المستخدم + can() + Wildcard + Cache + memo لكل طلب
app/Support/SessionPolicy.php         §6
app/Support/SettingsStore.php         قراءة/كتابة APP_SETTINGS مع Cache
app/Support/ActivityLogger.php         append إلى APP_USER_ACTIVITY (لا يُفشل الطلب عند خطأ السجل)
app/Http/Middleware/EnsurePermission.php
app/Models/AppPermission.php          Oracle · $timestamps=false · UPPERCASE fillable · getAttribute fallback
app/Models/UserPermission.php          + scopeActive() على IS_ACTIVE/EXPIRES_ON
app/Models/AppSetting.php
app/Models/UserActivity.php
app/Http/Controllers/UserAdminController.php
app/Http/Controllers/PermissionController.php
app/Http/Controllers/SessionAdminController.php
app/Http/Controllers/SettingController.php
tests/Feature/{UsersAdminTest,PermissionSyncTest,SessionPolicyTest,SecuritySettingsTest,ActivityLogTest}.php
database/oracle/{01_ibac_schema.sql, 02_ibac_seed.php, 03_ibac_bootstrap.php, 04_ibac_rollback.sql}
```
تحديث `app/Models/User.php`: إضافة `IS_ADMIN` إلى `fillable`، **حذف `USER_NO`** (D6)، `isAdmin(): bool`،
علاقة `grants(): HasMany\UserPermission`، وإضافة `IS_ADMIN` إلى `casts()/hidden` حسب الحاجة.

### 7.2 الـ middleware وتسجيله
```php
// app/Http/Middleware/EnsurePermission.php
public function handle(Request $request, Closure $next, string $code): Response
{
    $user = $request->user();

    if (! $user) {
        return response()->json(['success' => false, 'message' => 'غير مصرّح / Unauthenticated.'], 401);
    }

    if (! app(PermissionResolver::class)->can($user, $code)) {
        $label = app(PermissionCatalog::class)->arabicName($code);

        return response()->json([
            'success' => false,
            'message' => "لا تملك صلاحية {$label} / Permission denied: {$code}",
            'errors'  => ['permission' => [$code]],
        ], 403);
    }

    return $next($request);
}
```
```php
// bootstrap/app.php — أول تعديل لـ withMiddleware()
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias(['permission' => \App\Http\Middleware\EnsurePermission::class]);
})
```

### 7.3 `PermissionResolver`
```sql
SELECT p.PERMISSION_CODE
  FROM ACCOUNTS.APP_USERS_PERMISSIONS up
  JOIN ACCOUNTS.APP_PERMISSIONS p ON p.PERMISSION_ID = up.PERMISSION_ID
 WHERE up.USER_ID   = :user_id
   AND up.IS_ACTIVE = 1
   AND p.IS_ACTIVE  = 1
   AND (up.EXPIRES_ON IS NULL OR up.EXPIRES_ON > SYSDATE)
```
* استعلام Join واحد (لا N+1) + `Cache::remember("ky:perm:{$userId}", 600)` + `Cache::forget` بعد كل `syncUser`.
* `IS_ADMIN=1` ⇒ الأكواد = الكتالوج النشط كله، و`is_super_admin=true` (يبسّط منطق العميل).

### 7.4 المسارات الجديدة (55 → 71)
```php
Route::middleware('auth:sanctum')->group(function () {
    // حالتي
    Route::get('/auth/permissions', [AuthController::class, 'myPermissions']);

    // الكتالوج والمنح
    Route::get('/permissions',                [PermissionController::class, 'index'])->middleware('permission:users.view');
    Route::get('/users/{userId}/permissions', [PermissionController::class, 'forUser'])->middleware('permission:users.view')->where('userId','[0-9]+');
    Route::put('/users/{userId}/permissions', [PermissionController::class, 'syncUser'])->middleware('permission:users.permissions_manage')->where('userId','[0-9]+');

    // إدارة المستخدمين (D8)
    Route::get('/users',                   [UserAdminController::class, 'index'])->middleware('permission:users.view');
    Route::get('/users/{userId}',          [UserAdminController::class, 'show'])->middleware('permission:users.view')->where('userId','[0-9]+');
    Route::post('/users',                  [UserAdminController::class, 'store'])->middleware('permission:users.create');
    Route::put('/users/{userId}',          [UserAdminController::class, 'update'])->middleware('permission:users.update')->where('userId','[0-9]+');
    Route::patch('/users/{userId}/toggle', [UserAdminController::class, 'toggle'])->middleware('permission:users.toggle')->where('userId','[0-9]+');
    Route::delete('/users/{userId}',       [UserAdminController::class, 'destroy'])->middleware('permission:users.delete')->where('userId','[0-9]+');
    Route::get('/users/{userId}/activity', [UserAdminController::class, 'activity'])->middleware('permission:users.activity_view')->where('userId','[0-9]+');

    // الجلسات النشطة
    Route::get('/sessions',                  [SessionAdminController::class, 'index'])->middleware('permission:sessions.view');
    Route::delete('/sessions/{id}',          [SessionAdminController::class, 'terminate'])->middleware('permission:sessions.terminate')->where('id','[0-9]+');
    Route::delete('/sessions/user/{userId}', [SessionAdminController::class, 'terminateUser'])->middleware('permission:sessions.terminate')->where('userId','[0-9]+');

    // إعدادات الأمان
    Route::get('/settings', [SettingController::class, 'index'])->middleware('permission:settings.view');
    Route::put('/settings', [SettingController::class, 'update'])->middleware('permission:settings.security_manage');
});
```
ثم **المرحلة 7 (D3)** تغلّف المسارات الـ 55 الموجودة كما هو مبيّن في §9.

### 7.5 الأشكال والـ envelope
* مفاتيح `snake_case`؛ قائمة المستخدمين بـ `meta = {total, page, limit, pages}` بأسلوب
  `CustomerController`/`WorkerController` (`DEFAULT_LIMIT=100`, `MAX_LIMIT=500`)؛ **لا توحيد** مع نمط
  `AccountController` (العميل يقرأ الشكلين كما هما).
* معامالات القائمة: `search`, `page`, `limit`, `sort ∈ {user_id,user_name_ar,user_name_en,created_on,is_activated,user_type}`,
  `direction ∈ {asc,desc}`, `status ∈ {all,active,inactive}`, `user_type ∈ {all,1,2}`, `admin_only=0|1`.
* البحث العربي عبر `ArabicEncoding::toOracleSearchChars()` على `USER_NAME_AR` **و** `USER_NAME_EN`.
* حمولة `user` في `login/me/biometricLogin`:
```jsonc
{
  "id": 1, "username": "arslan", "name_ar": "…", "name_en": "arslan",
  "user_type": 1, "user_type_label": "موظف", "branch_no": 1,
  "is_admin": true,
  "permissions": ["users.view", "sessions.view", "..."],
  "is_super_admin": true,
  "session_expires_at": "2026-10-18 12:30:00"
}
```
* **لا** تسريب: `USER_PASSWORD`, `DEVICE_TOKEN` (`$hidden` + `select` صريح في كل استعلام).
* الأكواد: 401 (بلا توكن/جلسة منتهية/حساب معطّل) · 403 (لا صلاحية، تعديل `IS_ADMIN` بغير مدير، سحب آخر مدير)
  · 404 · 409 (اسم مستخدم مستخدم) · 422 (تحقق) · 201 (إنشاء).

### 7.6 عقود `UserAdminController`

| الدالة | سلوك إلزامي |
|---|---|
| `index` | Left join بعدّاد `grants_count`؛ `ORDER BY` بقائمة بيضاء فقط (لا ordering خام من المدخل)؛ pagination يدوي بـ `ROW_NUMBER() OVER (...)` (11g) |
| `show` | بيانات المستخدم + `granted_codes[]` + آخر جلسة/آخر نشاط |
| `store` | تحقق (نمط `CustomerController`): `user_name_en` مطلوب/fريد/≤50 · `user_name_ar` اختياري يمرّ بـ `encodeForOracle` · `user_password` ≥ `password_min_length` (نص صريح مؤقتاً — D2) · `user_type in:1,2` · `is_activated` · `is_admin` يُقبل **فقط** لو `auth->isAdmin()` وإلا 403 (`users.admin_flag_manage`)؛ `USER_ID` من `SEQ_APP_USERS_ID.NEXTVAL`؛ `CREATED_ON/BY`؛ ثم منح `permissions[]` في نفس transaction؛ ثم `ActivityLogger::users.create` |
| `update` | `LAST_UPDATED_ON/BY`؛ كلمة المرور تتغيّر فقط عند إرسالها؛ منع تغيير `user_type`/`is_admin` للذات؛ نفس حاجز `is_admin` |
| `toggle` | سوي `IS_ACTIVATED` 0↔1؛ عند التعطيل: إنهاء كل جلسات المستخدم؛ منع تعطيل الذات؛ حارس آخر مدير |
| `destroy` | منع حذف الذات (422)؛ منع حذف آخر `IS_ADMIN=1` (403)؛ حذف المنح (cascade) + التوكنات؛ سجل نشاط |
| `activity` | `APP_USER_ACTIVITY` حيث `USER_ID = :id OR TARGET_USER_ID = :id` مع `meta` نفسه و`cleanData()` على `DESCRIPTION_AR` |

### 7.7 `PermissionController@syncUser` — الاستبدال الذرّي
```php
DB::connection('oracle')->transaction(function () use ($userId, $ids, $grantedBy) {
    DB::statement('DELETE FROM ACCOUNTS.APP_USERS_PERMISSIONS WHERE USER_ID = ?', [$userId]);

    foreach ($ids as $pid) {
        DB::insert('INSERT INTO ACCOUNTS.APP_USERS_PERMISSIONS (USER_ID, PERMISSION_ID, GRANTED_BY)
                    VALUES (?, ?, ?)', [$userId, $pid, $grantedBy]);
    }
});

Cache::forget("ky:perm:{$userId}");
// ثم: إنهاء جلسات المستخدم (logout_others=1) + ActivityLogger::users.permissions_sync
```
* كل كود يجب أن يكون معروفاً و`IS_ACTIVE=1`، وإلا 422 بـ `errors.unknown_codes`.
* **لا تصعيد:** غير المدير لا يمنح أكواداً لا يملكها، ولا `IS_ADMIN`، ولا يعدّل منح نفسه.
* المدير (`IS_ADMIN=1`) لا يحتاج منحاً — الشاشة تعرض حالته «يمتلك كل الصلاحيات».

### 7.8 `SessionAdminController@index`
```sql
SELECT t.ID, t.TOKENABLE_ID AS user_id, t.CREATED_AT, t.LAST_USED_AT, t.EXPIRES_AT,
       u.USER_NAME_EN, u.USER_NAME_AR, u.IS_ADMIN, u.USER_TYPE, u.BRANCH_NO,
       u.DEVICE_NAME, u.PLATFORM
  FROM ACCOUNTS.PERSONAL_ACCESS_TOKENS t
  JOIN ACCOUNTS.APP_USERS u ON u.USER_ID = t.TOKENABLE_ID
 WHERE t.TOKENABLE_TYPE = 'App\Models\User'
 ORDER BY NVL(t.LAST_USED_AT, t.CREATED_AT) DESC
```
* «الجهاز» من `APP_USERS.DEVICE_NAME/PLATFORM` (عمودان موجودان)؛ الحالة تُحسب في PHP:
  `active` لو `EXPIRES_AT > now` و`IS_ACTIVATED = 1`، وإلا `expired`.

### 7.9 `SettingController` — التحقق
```php
'items'         => ['required', 'array', 'min:1'],
'items.*.key'   => ['required', 'string', 'max:60'],
'items.*.value' => ['nullable'],
```
ثم يدوياً ضد `APP_SETTINGS`: النوع داخل `int|bool|string|json`، القيمة داخل `[MIN_VALUE, MAX_VALUE]`،
`bool ∈ {0,1}`، `string ≤ 500`، رفض `IS_LOCKABLE=1`، `Cache::forget('ky:settings')` + سجل نشاط
`settings.update` بوصف «من … إلى …» بالعربية.

### 7.10 Pest 3
```
UsersAdminTest        401 بلا توكن · 403 بلا users.view · 422 تحقق الإنشاء · 409 تكرار الاسم ·
                      منع حذف/تعطيل الذات · 403 تعديل IS_ADMIN بغير مدير · حارس آخر مدير · شكل meta
PermissionSyncTest    استبدال كامل · رفض كود مجهول · منح IS_ACTIVE=0 مستثنى · EXPIRES_ON منتهي مستثنى ·
                      can() مع system.* و module.* · منع التصعيد · إلغاء Cache بعد syncUser
SessionPolicyTest     تمديد EXPIRES_AT للنشيط · رفض بعد الخمول · رفض بعد العمر المطلق ·
                      رفض IS_ACTIVATED=0 · لا كتابة قبل threshold · قبول الجلسات القديمة (NULL)
SecuritySettingsTest  403 settings.security_manage · 422 خارج الحدود · رفض IS_LOCKABLE · إبطال Cache
ActivityLogTest       تسجيل login/logout/store/sync · فلترة TARGET_USER_ID · pagination
```
* `RefreshDatabase` معطّل (قاعدة إرث) ⇒ تنظيف يدوي في `tearDown` بنطاق معرّفات اختبار
  (`USER_ID BETWEEN 900000 AND 900999`، بعد رفع `START WITH` للتسلسل) أو وسم `@group oracle-live`.
* ملاحظة بيئية: `TableQueryTest` يفشل بلا Oracle حي — ليس انحداراً من صنعنا.

---

## 8. التصميم الأمامي (Flutter / Riverpod 3)

### 8.1 النواة

| الملف | الدور |
|---|---|
| `lib/core/constants/permission_codes.dart` | `class Perm { static const customersView = 'customers.view'; … }` (93) + `permModuleLabels` و`permActionLabels` للعناوين |
| `lib/core/utils/permission_check.dart` | دوال `can/canAny/canAll` + `extension RefX on WidgetRef { bool can(String) }` |
| `lib/features/auth/presentation/providers/permissions_notifier.dart` | `NotifierProvider<PermissionsNotifier, PermissionsState>`؛ `refresh()` → `GET /auth/permissions` مع `CancelToken`؛ `AppLifecycleListener(resumed)` بحد أدنى 15s بين استدعاءين |
| `lib/core/widgets/permission_gate.dart` | `PermissionGate(code:, child:, onDenied:, hide: true)` |
| `lib/core/storage/secure_storage_service.dart` | مفاتيح جديدة `ky_user_permissions` (JSON) و`ky_is_admin` و`ky_session_expires_at` — **تُمسح** في `clearAll()` و`purgeEverything()` |

`AuthState` (`auth_notifier.dart:33`) — إضافة بلا كسر للحقول:
```dart
final Set<String> permissions;
final bool isAdmin;
final DateTime? sessionExpiresAt;

bool can(String code) {
  if (isAdmin) return true;                                     // D1
  if (permissions.contains(code)) return true;
  return permissions.contains('${code.split('.').first}.*');
}
```
* `login` و`loginWithBiometric` و`checkAuthStatus` تعبّئ الحقول من الاستجابة/التخزين ثم تستدعي `refresh()`.
* `UserModel`: `userType` رقمي + `String get userTypeLabel => userType == 2 ? 'عميل' : 'موظف'` (D5)،
  `final bool isAdmin`، و`List<String> permissions`؛ `fromJson` بمفاتيح مزدوجة + `ArabicEncodingUtils.fix`.
* **لا** `build_runner`، **لا** freezed، **لا** اعتماديات جديدة.

### 8.2 إصلاح تمهيدي إلزامي — سجل أقسام موحّد
`lib/features/employee_portal/domain/portal_sections.dart`:
```dart
const List<PortalSection> portalSections = [
  PortalSection('الرئيسية',      Icons.dashboard_outlined,           Perm.dashboardView,  HomeDashboardSection.new),
  PortalSection('المبيعات',      Icons.point_of_sale_outlined,       Perm.salesView,      SalesSection.new),
  PortalSection('التفصيل',        Icons.content_cut_outlined,         Perm.tailoringView,  TailoringSection.new),
  PortalSection('العملاء',        Icons.people_outline_rounded,       Perm.customersView,  CustomersSection.new),
  PortalSection('الحسابات',        Icons.account_balance_outlined,     Perm.accountsView,   AccountsSection.new),
  PortalSection('جاري العاملين',  Icons.groups_2_rounded,             Perm.employeesView,  WorkersSection.new),
  PortalSection('المخازن',        Icons.inventory_2_outlined,         Perm.storesView,     StoresSection.new),
  PortalSection('الإدارة',        Icons.admin_panel_settings_outlined, Perm.managementView, ManagementSection.new),
  PortalSection('الإعدادات',      Icons.settings_outlined,            null,               SettingsSection.new),
];
```
* `employee_main_layout.dart:32` و`collapsible_side_drawer.dart:27` يتغذّيان من هذا السجل فقط ⇒ **يزول
  تضارب الفهرس 4↔5** ويصبح الحجب بالفهرس صحيحاً.
* المعروض = `portalSections.where((s) => s.permission == null || auth.can(s.permission!))`؛
  `_currentIndex` يُطبَّق على القائمة المفلترة، وفقدان صلاحية القسم الحالي أثناء الجلسة يعيد الفهرس إلى 0.
* `الإعدادات` بلا صلاحية قسم (إعدادات محلية) ومحتوياتها الحسّاسة خلف `settings.view/update`.

### 8.3 هيكل `lib/features/admin/`
```
lib/features/admin/
├── data/models/
│   ├── app_user_model.dart               USER_ID/user_id مزدوج + fix() + _parseInt/_parseDouble
│   ├── app_permission_model.dart         PERMISSION_ID/CODE/MODULE_CODE/ACTION_CODE/NAME_AR/IS_CORE/SORT_ORDER
│   ├── app_session_model.dart            tokenId/user/device/createdAt/lastUsedAt/expiresAt/status
│   ├── app_security_setting_model.dart   key/value/type/min/max/nameAr/descriptionAr/isLockable
│   └── user_activity_model.dart          actionCode/descriptionAr/status/createdOn/ipAddress
├── data/repositories/
│   ├── admin_user_repository.dart         /users · /users/{id} · POST/PUT/DELETE · PATCH toggle · GET activity
│   ├── permission_repository.dart         /permissions · /users/{id}/permissions GET+PUT
│   ├── session_repository.dart            /sessions · /sessions/{id} · /sessions/user/{id}
│   └── security_setting_repository.dart   /settings GET+PUT
├── presentation/providers/
│   ├── admin_users_provider.dart          Notifier + CancelToken + debounce 300ms + _searchVersion + الفلاتر
│   ├── admin_permissions_catalog_provider.dart  FutureProvider مجمّع بالوحدة (مرتّب SORT_ORDER)
│   ├── assign_permissions_provider.dart   خريطة التحديد + dirty + save(userId, codes)
│   ├── active_sessions_provider.dart
│   ├── security_settings_provider.dart
│   └── user_activity_provider.dart        .family(userId)
├── presentation/screens/
│   ├── management_dashboard_screen.dart        بطاقات الأقسام الإدارية
│   ├── admin_users_screen.dart                 قائمة المستخدمين + بحث/فلترة/فرز + إضافة أعلى
│   ├── user_form_screen.dart                   أساس الإنشاء والتعديل معاً
│   ├── add_user_screen.dart  ·  edit_user_screen.dart   (غلافان رفيعان بنفس نمط customers)
│   ├── assign_permissions_screen.dart          من أيقونة «صلاحيات» في البطاقة
│   ├── user_activity_screen.dart               من زر «سجل نشاط»
│   ├── active_sessions_screen.dart
│   ├── security_settings_screen.dart
│   └── permissions_catalog_screen.dart         قراءة فقط للتدقيق
└── presentation/widgets/
    ├── user_form_widget.dart
    ├── permissions_picker_widget.dart      ★ المكوّن المشترك: داخل نموذج الإنشاء/التعديل وفي شاشة المنح
    ├── permission_module_group.dart         الأساسي بارز + «صلاحيات أخرى» مطوي
    ├── user_card.dart                       البطاقة + الأزرار الخمسة
    ├── user_picker_screen.dart               (نفس نمط CustomerPickerScreen)
    ├── session_card.dart · setting_tile.dart · activity_tile.dart · admin_filter_sheet.dart
```
المسارات حروف ثابتة داخل كل repository (بلا سجل مسارات) — مطابق لـ `customer_repository.dart`.

### 8.4 مواصفات الشاشات (حسب الطلب D8)

**(أ) `management_dashboard_screen.dart`** — يستبدل `ManagementSection`؛ شبكة بطاقات بنفس نمط
`_CustomerActionCard` + `GridView` بـ `crossAxisCount` ‏1/2/3 (`customers_dashboard_screen.dart:33-54`):

| البطاقة | صلاحية | الوجهة |
|---|---|---|
| إدارة المستخدمين | `users.view` | `AdminUsersScreen` |
| الجلسات النشطة | `sessions.view` | `ActiveSessionsScreen` |
| إعدادات الأمان | `settings.view` | `SecuritySettingsScreen` |
| كتالوج الصلاحيات | `users.view` | `PermissionsCatalogScreen` |
| سجل النشاط العام | `users.activity_view` | `UserActivityScreen(userId: null)` |

**(ب) `admin_users_screen.dart`**
* رأس: عنوان «إدارة المستخدمين» + زر **«إضافة مستخدم»** أعلى القائمة (خلف `PermissionGate(Perm.usersCreate)`).
* شريط بحث (debounce 300ms، `Timer` كما في `all_customers_screen.dart:85`) + أيقونات فلترة/فرز؛
  سطر «عرض N من E».
* **الفلترة** (`AdminFilterSheet`): الحالة (الكل/نشط/معطّل) · النوع (موظف/عميل) · المديرون فقط —
  تُرسَل كمعامالات query.
* **الفرز** (`showModalBottomSheet`): الاسم ↑↓ · رقم المستخدم ↑↓ · الحالة · النوع.
* `UserCard`: الاسم العربي (barزة) + الاسم اللاتيني + `رقم 12 · فرع 1` + شارة `نشط/معطّل` +
  شارة `مدير النظام` (`AppColors.accent`) + «صلاحيات: N».
* **أزرار داخل البطاقة**: تعديل · **صلاحيات** (أيقونة درع) · تعطيل/تفعيل · حذف · **سجل نشاط**؛
  كل زر خلف `PermissionGate`، وعلى الشاشات الضيقة تتحوّل إلى `PopupMenuButton`.
* بطاقة المستخدم الحالي: شارة «أنت» وتعطيل زرّي الحذف/التعطيل مع `tooltip` واضح.
* الحالات الأربع إلزامية: تحميل / بيانات / فارغ («لا يوجد مستخدمون مطابقون» + زر مسح الفلاتر) / خطأ + إعادة المحاولة.
* عند العودة من شاشة المنح: `refresh()` للعدّادات؛ ولا منطق محلي للفلترة/الفرز (الخادم مصدر الترتيب).

**(ج) `user_form_screen.dart` + `user_form_widget.dart`**
الحقول: `USER_NAME_EN` · `USER_NAME_AR` · `USER_PASSWORD` (+ تأكيد، تظهر فقط عند الإنشاء أو عند طلب تغييرها) ·
`USER_TYPE` (dropdown: موظف=1 / عميل=2) · `BRANCH_NO` · `IS_ACTIVATED` (`SwitchListTile`) ·
`IS_ADMIN` (`SwitchListTile` يظهر فقط لو `auth.isAdmin`، وإلا يُخفى مع تلميح).

* **منح الصلاحيات داخل النموذج** (`PermissionsPickerWidget`): مجموعة لكل قسم
  (`PermissionModuleGroup`) — صف الأفعال الأربعة الأساسية بارز (chips كبيرة)، ثم «صلاحيات أخرى» داخل
  `ExpansionTile` مطوي؛ «تحديد كل القسم» و«أساسيات القسم»؛ عدّاد أعلى المكوّن وبحث داخلي؛ وكلها مرتّبة
  بـ `SORT_ORDER` ومجمّعة باسم القسم العربي ⇒ **الترتيب والتنظيم حسب الأقسام** كما طُلب.
* القيمة الافتراضية لمستخدم جديد: لا شيء (Deny-by-default) + زر «نسخ صلاحيات من مستخدم» عبر `UserPickerScreen`.
* payload نهائياً بمفاتيح UPPER (`USER_NAME_EN`, `IS_ACTIVATED`, `IS_ADMIN`, `USER_TYPE`) و`permissions: [codes]`
  في نفس الـ POST/PUT ⇒ الخلفية تنفّذ كل شيء في transaction واحد.

**(د) `assign_permissions_screen.dart`** — تُفتح من أيقونة «صلاحيات» في بطاقة المستخدم:
* نفس `PermissionsPickerWidget` محمّلاً بـ `GET /users/{id}/permissions` ⇒ `granted_codes[]`.
* رأس يعرض اسم المستخدم وشارة حسّاسية؛ شريط تقدم «M صلاحيّة ممنوحة».
* حفظ → `PUT /users/{id}/permissions` + `PopScope`/dirty guard + تأكيد «سيتم إنهاء جلسات هذا المستخدم».
* المستخدم `is_admin` ⇒ المجموعة الأولى «مدير النظام — يملك كل الصلاحيات» معطلة بصرياً مع تنبيه.

**(هـ) `user_activity_screen.dart`** — قائمة زمنية `ListView.separated` + `ActivityTile` (الوقت،
`DESCRIPTION_AR`، شارة `success/failed`، IP/النظام)؛ فلترة زمنية (اليوم/الأسبوع/الشهر/مخصص — بنفس نمط
chips في `customer_statement_screen.dart:480`)؛ تحميل بالمزيد (pagination من `meta`)؛ وزر الطباعة/التصدير
يُعرض مطفأ (غير مطبَّق — §13).

**(و) `active_sessions_screen.dart`** — `SessionCard`: المستخدم + الجهاز + بداية الجلسة + آخر استخدام +
**الوقت المتبقي** (Timer.periodic بسيط) + شارة `نشطة/منتهية`؛ فلتر «النشطة فقط»؛ زر «إنهاء الجلسة»
(`sessions.terminate`) بتأكيد؛ وزر «إنهاء كل جلسات هذا المستخدم»؛ وسطر حالة «لا توجد جلسات نشطة».

**(ز) `security_settings_screen.dart`** — مجموعات `ExpansionTile` بنفس نمط بطاقات `settings_section.dart`:
* **الجلسات**: `session_idle_minutes` · `session_absolute_days` · `session_touch_threshold_minutes` · `single_active_session_per_device`
* **كلمة المرور**: `password_min_length`
* **الدخول**: `biometric_login_enabled` · `max_failed_logins` · `lockout_minutes`
* **السجل**: `activity_log_retention_days`

`TextField` للأرقام مع تحقق `MIN_VALUE/MAX_VALUE` محلياً و`Switch` للأنواع `bool`، حفظ `PUT /settings`
خلف `PermissionGate(Perm.settingsSecurityManage)`، ورسالة «يطبَّق على الطلبات التالية مباشرة».
كما تُضاف بطاقة عرض فقط في `/security-settings`: «تنتهي جلستك في …» من `session_expires_at`.

### 8.5 الاختبارات الأمامية
* توسيع `test/responsive_layout_test.dart` (لا harness جديد): ضخّ `ManagementDashboardScreen`,
  `AdminUsersScreen`, `UserFormScreen`, `AssignPermissionsScreen`, `ActiveSessionsScreen`,
  `SecuritySettingsScreen` عند 360×640 و1280×800 مع `expect(takeException(), null)` —
  تجاوز RenderFlex هو نمط الفشل المتكرر في هذا المشروع.
* `test/ibac_test.dart`: `can()` مع `is_admin`/`system.*`/`module.*`/منح منتهٍ؛ `AppUserModel.fromJson`
  بمفاتيح كبيرة/صغيرة وأرقام نصية؛ اسم عربي من بايتات CP1256 يمرّ بـ `fix()`؛ ثبات `portalSections`
  (العدد ومطابقة الفهارس بالـ drawer)؛ اختبار `PermissionsPickerWidget` (تحديد كل قسم/الأساسيات).
* البوابة: `flutter analyze` بلا ملاحظات + `flutter test` أخضر.

---

## 9. المراحل التفصيلية — من الصفر حتى الاكتمال

### مرحلة 0 — التهيئة وتجميد القرارات (0.5 يوم)
1. تثبيت D1–D9 مع صاحب العمل، وتحديداً: إضافة `IS_ADMIN` وتصحيح `USER_TYPE=1` لـ arslan.
2. إنشاء فرعي العمل في المستودع الأب والـ submodule (§3.2).
3. إنشاء `APP_USERS_BAK_IBAC` والتحقق من عدّ صفوفه (§3.3).
4. `composer install` + `php artisan serve --host 0.0.0.0` + `curl /api/hello` + `flutter pub get`.
5. اختبار `Cache::put('ky:test', 1)` على اتصال Oracle للتأكد أن مخزن `CACHE` يعمل.
**قبول:** البيئة تعمل، الفرعان منشآن، البَاك موجود، ولا سطر كود بعيُد بعد.

### مرحلة 1 — طبقة القاعدة (1 يوم)
1. كتابة `01_ibac_schema.sql` (§4.1–§4.5) وتشغيله قطعة قطعة عبر موصل Oracle مع تحقق بعد كل قطعة.
2. بذر `02_ibac_seed.php`: 93 صلاحيّة + 10 إعدادات — **يُشتق من `PermissionCatalog::rows()` مباشرة** (مصدر واحد لا يتباعد)، ثم تعليقات وتهيئة `03_ibac_bootstrap.php`.
3. ترقية arslan: `IS_ADMIN=1, USER_TYPE=1`، ومنح `system.*` اختيارياً للتجربة.
4. تسجيل DDL في `db_commends.md` وبنية الجداول في `DBdevloping_history.md`.
5. تحققات §4.7 + فحص `DUMP(NAME_AR)` للتأكد أن العربية بايتات CP1256 سليمة.
**قبول:** 4 جداول جديدة + 5 sequences + 4 triggers بحالة `ENABLED` و`VALID`؛ `APP_PERMISSIONS=93`؛ `APP_SETTINGS=10`؛ تعليق على 4 جداول و45 عموداً؛ صفر كائن `INVALID`؛
ومنع تكرار التحقق بـ `DUMP(NAME_AR)` أن العربية بايتات CP1256 سليمة (لا `0xBF`). **تم التحقق والتنفيذ بالكامل.**

### مرحلة 2 — الكتالوج والحلّ والجلسات (خلفية) (2 يوم)
1. `PermissionCatalog` (وحدات × أفعال × أسماء عربية × `IS_CORE/SORT_ORDER`) + `arabicName()` + `allCodes()`.
2. `SettingsStore` (قراءة/كتابة + `Cache` + تطبيع حسب `VALUE_TYPE`).
3. `PermissionResolver` (Join واحد + `can()` + `Cache` + `flush(userId)`).
4. `SessionPolicy` وربطه بـ `Sanctum::$accessTokenAuthenticationCallback` في `AppServiceProvider::boot()`.
5. الموديلات الأربعة + تحديث `User` (`IS_ADMIN`، حذف `USER_NO`، `isAdmin()`، `grants()`).
6. `bootstrap/app.php`: alias `permission` + `EnsurePermission`.
7. `AuthController`: توزيع `permissions/is_admin/session_expires_at/user_type_label` في `login/me/biometricLogin`،
   `USER_ID` بدل `USER_NO` (D6)، ضبط `EXPIRES_AT` عند الإصدار، و`ActivityLogger` في login/login_failed/logout/biometric.
8. Pest: `SessionPolicyTest` + `PermissionSyncTest` (الأساس) ثم `vendor/bin/pint --dirty --format agent`.
**قبول:** `/auth/me` يعيد المصفوفة والراية؛ `EXPIRES_AT` يتمدّد في القاعدة مع كل طلب؛ `session_idle_minutes=1`
يرجع 401 بعد الخمول؛ `IS_ADMIN=0` بلا منح ⇒ 403 على أي مسار محمي.

**نتيجة التنفيذ (2026-10-17 07:17:24 — تمّت):**
- القاموس 93 صلاحية على 17 وحدة مع ترتيب أساسي أولاً، و`arabicName('customers.delete')` = «حذف العميل».
- `PermissionResolver` يرفض افتراضياً، و`canAny([])` = false مقابل `canAll([])` = true، و`IS_ADMIN=1` يتجاوز
  جدول المنح (حارس ضد قفل النظام)، و`payloadFor()` يعيد `permissions` + `is_admin` + `can_*`.
- `SessionPolicy` مركّبة في `Sanctum::$accessTokenAuthenticationCallback`؛ توكن فحص حيّ حصل على
  `EXPIRES_AT = created_at + 240 دقيقة`، وبانقضائها رفضت الجلسة ⇒ التجديد الانزلاقي ومهلة الخمول يعملان
  **بلا أي تعديل على مخطط `PERSONAL_ACCESS_TOKENS`** (`expiration` بقي `null` عمداً).
- `EnsurePermission` مختبَر الحالتين: 401 بلا مستخدم و403 برسالة عربية اسمية، والتمرير عند المنح.
- سجل النشاط: كتابة عربية بـ `toOracleSearchChars()` تحقّق بـ `DUMP(...,1016)` أنها CP1256، وقراءة بـ
  `fixMojibake()` تعيد العربية سليمة (دورة مغلقة).
- **انحراف مُقرّ عن البند 5:** لم تُنشأ الموديلات الأربعة ولا علاقة `grants()` — كل الطبقات تكتب/تقرأ SQL
  مربوطاً مباشراً على اتصال `oracle`، فعدم إنشاء نماذج بلا مستفيد التزام بمبدأ «لا كود ميت»؛ تُضاف عند الحاجة.
- **حادث مُعالَج:** `ORA-01461` في كاش `CACHE` (انظر البند 17 في §1) — فرض سقف 3000 بايت وإخراج العربية من الكاش.
- **البوابات:** `php -l` نظيف على 11 ملفاً، `pint --dirty` passed، `pest` = 21 اختباراً / 83 تحققاً
  (12 منها في `tests/Feature/IbacCoreTest.php`)، وعدد المسارات لم يتغيّر (55).

### مرحلة 3 — API إدارة المستخدمين والمنح (2 يوم)
1. `UserAdminController` بكل حواجز §7.6 (index/show/store/update/toggle/destroy/activity).
2. `PermissionController` (index/forUser/syncUser) بtransaction §7.7 + منع التصعيد.
3. 9 مسارات + تحقق نمط A برسائل ثنائية + `meta {total,page,limit,pages}`.
4. Pest: `UsersAdminTest` + `ActivityLogTest` + تكملة `PermissionSyncTest`؛ Pint؛ `route:list` = 64.
5. تجربة curl: توكن مدير كامل + توكن مستخدم بلا صلاحيات.
**قبول:** دورة حياة كاملة على Oracle الحقيقي (إنشاء بمنح ← عرض ← تعديل ← تعطيل ← سجل نشاط ← حذف)،
والرفض 403 صحيح لكل مسار.

**نتيجة التنفيذ (2026-10-18 00:03:42 — اكتمل الكود والاختبارات؛ دورة الحياة الحيّة تنتظر إذناً بالكتابة):**
- `UserAdminController` بكل حواجز §7.6، و`PermissionController` (§7.7) بمسار كتابة وحيد للمنح عبر
  `PermissionGrantSync` — وهو **طبقة إضافية غير واردة في §7.1**، سببها توحيد الحذف/الإدراج في معاملة واحدة
  ومنع تباعد المنح بين قارئ وكاتب.
- المسارات **11** لا 9 (`GET /auth/permissions` و`GET /permissions` فُصلتا)، فـ `route:list` = **66** لا 64.
- كتابة العربية في `store()` بـ `toOracleSearchChars()` (البند 15)، لا `encodeForOracle()` كما يقطع §7.6.
- حواجز مُثبتة بالاختبارات: 401 بلا جلسة، 403 برسالة عربية اسمية لكل مسار، 409 تكرار الاسم، 422 التحقق
  و«حذف/تعطيل الذات» والأكواد المجهولة/المعطّلة، 403 منع التصعيد، و«آخر مدير» (`COUNT(IS_ADMIN)=1` حيّاً).
- علّتان عُولجتا: `ORA-00904` في `currentFor()` (خطأ مصدر العمود)، والبند **18** (تواريخ أوراكل الفارغة).
- الاختبارات الجديدة (26) كلها قراءة وفروع رفض: **لم تُكتب أي صفوف** في `APP_USERS` أو
  `APP_USERS_PERMISSIONS` (تأكيد حي: 1 مستخدم، 1 منحة، 93 صلاحية، 6 أسطر نشاط).
- **ما لم يُنفَّذ بعد من بند القبول:** دورة الحياة الكاملة على قاعدة حقيقية (إنشاء بمنح ← تعديل ← تعطيل ←
  سجل ← حذف) وتجربة curl بتوكن مستخدم بلا صلاحيات — لأنها `INSERT/UPDATE/DELETE` على مخطط إنتاجي، وتحتاج
  إذناً صريحاً من المستخدم؛ تُجرى فور الموافقة أو تُدرج ضمن المرحلة 8.
- **البوابات:** `pint --dirty` passed، `pest` = **47 اختباراً / 199 تحققاً** ناجحة، `route:list` = 66.

### مرحلة 4 — API الجلسات والإعدادات (1.5 يوم)
1. `SessionAdminController` بالاستعلام §7.8 (مراعاة الأعمدة CLOB) + terminate/terminateUser.
2. `SettingController` مع التحقق المزدوج §7.9 + إبطال Cache + سجل نشاط.
3. 5 مسارات؛ `route:list` = **71**؛ Pest: `SecuritySettingsTest` + حالات الجلسات.
4. اختبار حي: جلسة مستخدم ثانٍ تُنهى من arslan ⇒ أول طلب منه 401.
**قبول:** القائمة تطابق `PERSONAL_ACCESS_TOKENS`؛ الإنهاء فوري؛ تغيير `session_idle_minutes` يسري على
الجلسات القائمة في الطلب التالي.

**نتيجة التنفيذ (2026-10-18 02:52:11 — اكتمل الكود والاختبارات؛ الاختبار الحيّ للجلسات ينتظر إذناً بالكتابة):**
- `SessionAdminController` (§7.8) كما خُطط مع تحيّطين فرضتهما أوراكل 11g: الصفحات بـ `ROW_NUMBER()`
  داخل غلافين بدل `OFFSET/FETCH`، و`NAME` العنقودي CLOB يُقرأ بـ `DBMS_LOB.SUBSTR(t.NAME, 60, 1)`،
  والحالة (`active`/`expired`/`disabled`) تُشتق في `CASE` داخل الاستعلام بدل PHP حتى يبقى الفرز
  بمرشّح الحالة ممكناً. البند **18** معمول به: كل التواريخ تخرج `TO_CHAR` وتمرّ بـ `SessionPolicy::toDate()`.
- `SettingController` (§7.9): التحقق المزدوج (نوع + حدود من `APP_SETTINGS` نفسه)، بوابة
  `settings.security_manage` للمفاتيح `IS_LOCKABLE=1` (403 بـ `errors.locked_keys`)، معاملة واحدة للدفعة،
  `flush()` بعد الحفظ وبعد التراجع، وسجل نشاط وصفي «من … إلى …». أضيفت `SettingsStore::flush()` علنية
  لأن `set()` يُسقط الكاش قبل معرفة نتيجة المعاملة.
- الإنهاء بكتابة `EXPIRES_AT = SYSDATE - 1` (البند الخاص بعدم تركه NULL) ⇒ 401 في الطلب التالي، ومسار
  العميل الموجود (`ErrorInterceptor` → `clearAll()` → `forceLogout()`) يتكفل بالخروج الفوري بلا كود جديد.
- المسارات **5** بالضبط، و`route:list` = **71** مطابق للتقدير. `DELETE /sessions/user/{userId}` مُعلَن قبل
  `DELETE /sessions/{tokenId}` حتى لا يبتلعه النمط العام.
- علّلات مكتومة من المرحلة 2 عولجت: البند **19** (`:by` ⇒ `ORA-01745` في `SettingsStore::set()` و
  `UserAdminController@toggle`) والبند **20** (ثابت `FILTER_NULL_ON_UNSET` غير الموجود ⇒ 500 لكل حفظ
  `bool`). وأُزيلت قاعدة تحقّق ميتة: `items.min` خلف `required` ⇒ صارت `present|array|min:1`.
- الاختبارات الجديدة (22: `ActiveSessionsTest` 12 و`SecuritySettingsTest` 10) كلها قراءة وفروع رفض،
  والعنصر المرفوض مرتّب أولاً كي تسقط الدفعة في `normalize()` **قبل** أي عبارة `UPDATE`.
- **ما لم يُنفَّذ بعد من بند القبول:** البند 4 (جلسة مستخدم ثانٍ تُنهى فعلياً وتخرج بأول طلب 401)
  ودورة الحياة الكاملة للكتابة على `APP_SETTINGS` — يحتاجان `INSERT/UPDATE` على مخطط إنتاجي، أي
  إذناً صريحاً من المستخدم؛ تُجرى فور الموافقة أو ضمن المرحلة 8.
- **البوابات:** `pint --dirty` passed، `pest` = **69 اختباراً / 449 تحقّقاً** ناجحة، `route:list` = 71،
  وتأكيد حيّ أن `APP_SETTINGS` لم تتغيّر (10 صفوف، `UPDATED_BY` فارغ، `password_min_length=4`،
  `session_idle_minutes=240`) وأن `PERSONAL_ACCESS_TOKENS` = 32 كما كانت.

### مرحلة 5 — نواة الصلاحيات في العميل (1.5 يوم)
1. `permission_codes.dart` (93 كوداً مطابقاً) + `permission_check.dart`.
2. `AuthState` الحقول الجديدة + `can/canAny/canAll` + التعبئة في `login/biometric/checkAuthStatus`.
3. `SecureStorageService` المفاتيح الجديدة ومسحها في `clearAll()`/`purgeEverything()` + `AuthRepository`.
4. `PermissionsNotifier` + `AppLifecycleListener` (resumed → refresh، حد 15s) + `GET /auth/permissions`.
5. `PermissionGate` + `test/ibac_test.dart`.
**قبول:** `flutter analyze` نظيف؛ `ref.can(...)` صحيح لمستخدمين مختلفين؛ لا انقطاع في التدفق العادي.

**نتيجة التنفيذ (2026-10-19 01:47:33 — اكتملت بالكامل؛ لا كتابة على القاعدة):**
- `permission_codes.dart` يحمل **93 كوداً مطابقاً** لكتالوج الخادم، والدليل ليس العدّ وحده بل المحتوى
  والترتيب: مقارنة نصّية ثنائية أعطت `missingInDart = []` و`missingInPhp = []` و`firstOrderDiffIndex = -1`
  (الترتيب مُعتبر أيضاً لأن شاشة اختيار الصلاحيات في المرحلة 8 تعرض الأكواد بترتيب الكتالوج).
  أضيف `permWildcardOf(module)` لأن بناء `module.*` يدوياً في ثلاث مواضع هو طريقة مؤكدة لتوليد رمز
  لا يعرفه الخادم.
- `permission_check.dart` يعيد إنتاج نفس ترتيب قواعد `PermissionResolver::can` حرفياً:
  `userId <= 0` ⇒ رفض؛ `isAdmin` ⇒ قبول؛ `system.*` ⇒ قبول؛ الرمز الصريح ⇒ قبول؛ `module.*` ⇒ قبول؛
  وإلا رفض. `canAny([]) = false` و`canAll([]) = true` — لأن قائمة فارغة ليست طلباً على شيء.
- `AuthState` صار الحامل الوحيد للثلاثية (`permissions`, `isAdmin`, `sessionExpiresAt`) عبر
  `withPermissions(snapshot)`، و`copyWith` يمسح `sessionExpiresAt` **فقط** عند الطلب الصريح (الحيلة
  القفلية `String? Function()?`) حتى لا يفسد التجديد الانزلاقي أي تحديث حالة عارض.
- `PermissionsNotifier` **لا يخزن منحاً مستنسخة**: يحمل بيانات التزامن فقط (متى آخر تحديث، هل هو قديم)
  ويكتب في `AuthState` عبر `applyPermissions()`. هذه النقطة مقصودة: مصدران للحقيقة في الصلاحيات يعني
  حجباً يقرأ من مكان وتنفيذاً يقرأ من آخر.
- سياسة التحديث تحمي التوافر دون أن توهن الأمان: **خطأ من الخادم** (401/403/422) ⇒ تمسح المنح المخزّنة
  لأن الخادم أنكرها صراحة؛ **فشل النقل** (انقطاع/مهلة) ⇒ تبقى المنح لأن الخادم ما زال يفحص كل طلب
  فردي، وإلا لانهارت البوابة كلها عند أول تقطّع شبكة.
- `SecureStorageService` لا يضيف مفتاحاً جديداً للصلاحيات — تُقرأ من `ky_user_data` المضمَّن في
  استجابة الدخول، لأن تخزينها منفصلاً يعني احتمال بقاء منح مسحوبة بعد `clearAll()`.
- **علّتان عالجتاهما أثناء التوصيف:** (أ) `checkAuthStatus()` كان يعيد بناء `AuthState` من الصفر
  فيسقط `selectedUserType` إلى `employee` — أي أن شاشة الدخول تفقد اختيارها بعد كل تحديث للجلسة؛
  أُضيف الحفاظ الصريح مع تعليق ثنائي اللغة. (ب) `flutter analyze` كشف مسار استيراد خاطئاً في
  `permissions_notifier.dart` (`../../../data/models` بدل `../../data/models`) و`isStale` مكتوباً
  كقفل بدل قيمة منطقية وتداخل اسم معامل التجديد مع الاسم المحجوز `state`.
- **البوابات:** `flutter analyze` = No issues found! · `flutter test` ناجح كلياً، و`test/ibac_test.dart`
  يغطي الكتالوج (5) وقواعد الحل (7) وتحليل اللقطة (4) وحجب `AuthState` (3) و`UserModel` (2).
- **ما لم يُنفَّذ من بند القبول:** التحقق الحيّ على جهازين بصلاحيات مختلفة مؤجَّل إلى المرحلة 7/8
  لأنه يحتاج منْحاً فعلياً في `APP_USERS_PERMISSIONS` (كتابة تحتاج إذناً).

### مرحلة 6 — توحيد الأقسام وحجب الـ Drawer (1 يوم)
1. `portal_sections.dart` + تحويل `employee_main_layout.dart` و`collapsible_side_drawer.dart` لتغذية واحدة.
2. حجب الأقسام بصلاحية `*.view` + معالجة رجوع الفهرس + بقاء الشريط العلوي (الفرع/متصل/خروج).
3. إخفاء البطاقات الفرعية داخل كل dashboard (`customers_dashboard_screen.dart:109`) بـ `PermissionGate`.
4. اختبار: مستخدم بلا صلاحيات يرى «الرئيسية + الإعدادات» فقط، و`GET /customers` من جهازه ⇒ 403.
5. `flutter analyze` + توسيع `responsive_layout_test.dart` وإصلاح أي RenderFlex.
**قبول:** صفر تباعد فهرسي (اختبار `portalSections`)، وحجب متطابق في الواجهة والخادم.

**نتيجة التنفيذ (2026-10-19 01:47:33 — اكتملت بالكامل؛ لا كتابة على القاعدة):**
- `lib/features/employee_portal/domain/portal_sections.dart` صار **المصدر الوحيد** لتعريف الأقسام
  التسعة: لكل قسم `id` نصي ثابت، و`title`، و`icon`، و`builder`، و`viewCodes` (يكفي واحد منها لإظهار
  القسم؛ القائمة الفارغة تعني قسماً غير مشروط مثل الإعدادات)، و`showInBottomBar`. الدوال البنّاءة
  دوال عليا (`_buildHome` …) لأن القائمة نفسها `const`.
- **العلة التاريخية البند 11 زالت بالبناء لا بالمراقبة:** `_menuItems` حُذفت من
  `collapsible_side_drawer.dart` وصار يتغذى على `List<PortalSection>`، و`employee_main_layout.dart`
  استبدل `_currentIndex` بـ `_currentSectionId`. الفهرس الآن يُشتق من القائمة المرئية
  (`_indexOfVisible`) لا من جدول يدوي، فمستخدم ممنوحاً لقسم واحد لا يفهرس إلى طفل غير موجود.
  الاختبار `the module wildcard opens its section on mobile too` يثبّت بالضبط هذا المنحنى.
- **الحجب إخراجٌ لا إخفاءٌ:** `IndexedStack` يبني كل أبنائه مهما كان الفهرس، فلو بقي القسم الممنوع
  في القائمة لَشبّك طلبه على الخادم عند كل دخول للبوابة لمستخدم لا يستطيع فتحه أصلاً.
  `visiblePortalSections(granted, isAdmin)` تُرجع المسموح فقط، و`children: [for (final s in visible) s.builder(context)]`.
- **البند 21 و22 (هما سبب إضافة الصفّين إلى §1):** الشريط السفلي لا يُرسم بأقل من وجهين
  (`barSections.length < 2 ⇒ null`) لأن Material يشترط `destinations.length >= 2`؛ وشريط بطاقة
  العملاء أُصلح بتغليف نصه بـ `Flexible` + `maxLines: 1` + `ellipsis`.
- **`NoSectionAvailable`** شاشة إرشاد عامة (وليست حالة خطأ): تُرسم عندما تكون `visible` فارغة، وتحافظ
  على الشريط العلوي وزر الخروج، وتشرح أن الدخول لم يُمنح بعد بدل أن تترك المستخدم أمام واجهة صمّاء.
- **البند 6 من المتطلبات (إخفاء البطاقات الفرعية بـ `PermissionGate`) مؤجَّل عمداً إلى المرحلة 8:**
  البطاقات الفرعية تعيش داخل لوحاتٍ هي نفسها مواضع فارغة مُخطَّطة (المبيعات/التفصيل/المخازن/الإدارة)،
  فبوابتها تُركَّب عند بناء شاشتها الحقيقية لا الآن — والتعليق هذا مسجَّل في `devloping_history.md`.
- **البوابات:** `flutter analyze` = No issues found! · `flutter test` = **44/44** · توسيع
  `responsive_layout_test.dart` بمجموعة «Portal sections follow the grants»: مدير النظام يرى الأقسام
  التسعة وخمسة وجوه على الجوال، والمنح المقيّدة تُخرج الأقسام من الشريطين، وقسم واحد في الشريط يترك
  الشريط بلا رسم، وشاشة الإرشاد تُبنى وحدها.

### مرحلة 7 — إغلاق مسارات الأعمال (D3) (2 يوم)
**الترتيب بوحدات، وكل وحدة تحتاج تأكيد أن صلاحياتها ممنوحة لمستخدمين حقيقيين:**
1. `/customers/**` (6) → `auth:sanctum` + `customers.*`.
2. `/workers/**` (18) → `employees.* / cutters.* / tailors.*`.
3. `/accounts/**` (12) → `accounts.*`؛ `/currencies/**` (8) → `currencies.*`.
4. `/invoices/**` (2) → `invoices.view` **+** إصلاح C5 (envelope + `ArabicEncoding`) في نفس التعديل.
5. `/selectFromTable` → `permission:system.*` + قائمة رفض جداول (`APP_USERS`, `PERSONAL_ACCESS_TOKENS`,
   `CACHE`, `CACHE_LOCKS`, `MIGRATIONS`, `JOBS`, `FAILED_JOBS`) ورفض أعمدة حساسة.
   يبقى عاماً: `/hello`, `/auth/login`, `/auth/biometric/login` (بالتصميم).
6. `05_ibac_bootstrap_grants.php`: منح كل المستخدمين النشطين الكتالوج كاملاً حتى لا يُطرد مستخدمون حقيقيون،
   ثم تُقلَّص المنح إدارياً من الواجهة تدريجياً.
7. Pest لكل وحدة + regression على جهازين بصلاحيات مختلفة + `flutter analyze`.
**قبول:** `route:list` يُظهر `auth:sanctum` على 21+55−6 = 70 من 71 مساراً (المستثنَون الثلاثة عامون
بتصميم + `/hello`)؛ صفر مسار أعمال عام؛ كل مستخدم يعمل داخل منح فقط.

**نتيجة التنفيذ (2026-10-19 02:59:38 — اكتمل الختم؛ صفر كتابة على القاعدة):**
- **السطح العام = 3 مسارات لا 4:** `POST /auth/login`، `POST /auth/biometric/login`، `GET /hello`.
  الاختبار `no business route is public any more` يجعل هذه القائمة **عقداً** لا ملاحظة: أي مسار أعمال
  يُضاف لاحقاً بلا `auth:sanctum` يفشل البناء كله، والمقارنة بقائمة مرتّبة لا بمجموعة حتى لا ينجح
  الترتيب الحظي.
- **العدد بقي 71** لأن الختم طبقات لا مسارات — وهذا بالضبط ما يجب أن يظهر في البوابات: لا endpoint
  جديداً ولا محذوفاً، فقط من يستطيع النداء عليه.
- **تقسيم الصلاحيات على وزن الخطر لا على وزن الملف:** كشف العميل `customers.statement` منفصل عن
  `customers.view`؛ أسعار الصرف `currencies.prices_view`/`prices_manage` منفصلة عن دليل العملات؛
  إعادة تشكيل الشجرة `accounts.structure_manage` منفصلة عن بنود `accounts.create/update`؛ والسجلات
  الثلاثة للعاملين ثلاث وحدات (`employees`/`cutters`/`tailors`) لا وحدة `workers` واحدة — لأن
  «مدير جاري العاملين» صلاحية كتلة واحدة تمنح الخيّاط سلطة على القصاصين.
- **البند 6 من المرحلة (منح الترحيب) سقط بشرطه لا بخطأ:** `APP_USERS` فيه مستخدم واحد
  (`arslan`, `IS_ADMIN=1`, `IS_ACTIVATED=1`)، والمدير يُقبل في `PermissionResolver::can` قبل مسح
  جدول المنح، فلا مستخدم حقيقي يُطرد. البند يبقى **معلّقاً بحدٍّ واضح**: أول `INSERT` في `APP_USERS`
  لمستخدم غير مدير (وهو ما ستفعله واجهة المرحلة 8) يجعله إلزامياً قبل منحه أي صلاحية.
- **مسارات الجلسة الذاتية الستة بقيت `auth:sanctum` بلا `permission:`** بقرار صريح ومُختبَر:
  `logout`، `me`، `user`، `auth/permissions`، `biometric/register`، `biometric/revoke`. اشتراط منح
  لقراءة المرء منحَه يجعل المستخدم بلا صلاحيات عاجزاً عن معرفة أنه كذلك، واشتراطها للتسجيل بالبصمة
  يمنع الدخول أصلاً. الاختبار `every sealed business route also carries a permission guard` يستثني
  هذه الستة صراحةً، فإضافة سابع إلى القائمة قرارُ تصميم لا ملاحظة عابرة.
- **`selectFromTable` أُغلق من نصفين:** `permission:system.*` (البوابة) + `DENIED_TABLES` من 11
  جدولاً (القرار الداخلي)، تُطبَّق **قبل** استعلام `USER_TABLES` فجدول الاعتمادات لا يولّد قراءة
  أصلاً؛ و`DENIED_COLUMNS` ينقّح `PASSWORD`/`DEVICE_TOKEN`/`TOKEN`/`SECRET`/`KEY` من أي جدول مسموح،
  وتُعلن النتيجة في `redacted_columns` حتى لا يكون الحذف صامتاً. البند **S2** أُغلق عند هذا الحد:
  الحقن كان مغلقاً من قبل، والناقص كان السلطة والقائمة.
- **البند C5 أُغلق:** `InvoiceController` صار غلافاً موحّداً + `ArabicEncoding::cleanData()` + بحث
  بكلتا صيغتَي البايت + تصفحاً بـ `meta` على وزن `CustomerController` + `404` مغلّفاً بدل `null`
  عارٍ + أعمدة مشتركة في ثابت `COLUMNS` (كان التكرار الحرفي أول سبب انحراف المسارين).
- **علّتان جديدتان من الاختبار لا من الكود:** `'data' => [[...]]` في `assertJsonStructure` تفشل على
  جدول إرث فارغ — فالبنية العامة تُثبت الآن وفحص مفاتيح الصفّ مشروط بوجود صفّ؛
  و`toBeCanonicalizing` ليست وسيلة Pest 3 — والمقارنة صارت بـ `sort` ثم `toBe`.
- **تصحيح وثائقي فرضه إعادة تنفيذ:** استعلام التحقق المحفوظ في الجولة السابقة كان مكتوباً بأسماء
  أعمدة غير موجودة (`STATUS`، `P.ID`، `EXPIRES_AT` في جدول المنح)؛ إعادة تشغيله ردّت
  `ORA-00904`. صُحِّحت الوثيقة وأُضيف قطاع مرجعي للأعمدة في `DBdevloping_history.md`. **الكود كان
  صحيحاً طوال الوقت** — `PermissionResolver::GRANTS_SQL` يكتب `IS_ACTIVE`/`PERMISSION_ID`/`EXPIRES_ON`
  منذ المرحلة 2، فالخلل في المحفوظ لا في المنفَّذ، والنتيجة `93 / 1 / 1` لم تتغيّر.
- **البوابات:** `vendor/bin/pint --dirty --format agent` = fixed (ملفان) · `vendor/bin/pest` =
  **78 اختباراً / 533 تحقّقاً** ناجحة (منها 6 جديدة في `BusinessRoutesSealedTest` و7 في
  `TableQueryTest` المعاد) · `route:list` = **71** · `flutter analyze` = No issues found! ·
  `flutter test` = 44 ناجحة.
- **ما لم يُنفَّذ من بند القبول:** التحقق الحيّ على جهازين بصلاحيات مختلفة — يحتاج مستخدماً ثانياً
  غير مدير، أي كتابة في `APP_USERS`، وهو موكل للمرحلة 8 بإذن صريح.

### مرحلة 8 — واجهة الإدارة الكاملة (3.5 يوم)
1. `data/models` (5) + `data/repositories` (4) + `providers` (6).
2. `ManagementDashboardScreen` واستبدال `ManagementSection` placeholder.
3. **`AdminUsersScreen`**: بحث debounce 300ms + `CancelToken` + `_searchVersion` + فلترة + فرز + بطاقات
   بأزرار (تعديل/صلاحيات/تعطيل/حذف/سجل نشاط) + زر «إضافة مستخدم» أعلى القائمة — جوهر الطلب.
4. `UserFormScreen/Widget` + **`PermissionsPickerWidget` داخل النموذج** (مرتّب ومنظّم حسب الأقسام).
5. `AssignPermissionsScreen` · `UserActivityScreen` · `ActiveSessionsScreen` · `SecuritySettingsScreen`
   · `PermissionsCatalogScreen` · `UserPickerScreen`.
6. اختبارات overflow والشاشات + عدم كتابة أي لون يدوياً (كل الألوان في `AppColors`).
**قبول:** §10 يُنفَّذ حرفياً على جهاز حقيقي بلا استثناءات وبلا RenderFlex.

### مرحلة 9 — التوثيق والإطلاق (1 يوم)
1. تحديث `AGENTS.md` الجذري (§2 الشجرة، §5 المسارات 71، §6 الجداول الجديدة، §11 إسقاط C9/scope) و
   `kyApp_API/AGENTS.md` (§3 المسارات، `permission` alias، `SessionPolicy`، `IS_ADMIN`، `USER_ID` بدل `USER_NO`).
2. `devloping_history.md` + `todo.md` بحالة الإنجاز؛ `db_commends.md` مكتمل بالـ DDL.
3. حواجز الإطلاق في AGENTS §9: إضافة `INTERNET` إلى `AndroidManifest.xml` الرئيسي، `applicationId`
   غير `com.example.ky_apps`، توقيع release حقيقي — **لا يُوزَّع APK قبلها**.
4. commit داخل `kyApp_API` أولاً ثم push، ثم bump المؤشر في `ky_apps` (رسائل عربية بنفس نمط السجل،
   بلا `--no-verify`).
**قبول:** البوابات الأربع خضراء + توثيق مطابق للواقع + إصدار قابل للتوزيع.

**الإجمالي ≈ 15 يوم عمل.** (مرحلة 8 تتوازي مع 7؛ والمرحلة 7 مشروطة باكتمال 1–6.)

---

## 10. السيناريو المرجعي للإثبات اليدوي (Acceptance)

1. arslan (مدير) → Drawer → **الإدارة** → **إدارة المستخدمين** → زر **إضافة مستخدم**.
2. تعبئة الاسم العربي/اللاتيني/كلمة المرور/النوع «موظف»/الفرع + تحديد الصلاحيات **داخل النموذج**:
   `dashboard.view`, `customers.view`, `customers.create`, `accounts.view` → حفظ ⇒ **201**.
3. تحقق في Oracle: 4 صفوف في `APP_USERS_PERMISSIONS` بـ `GRANTED_BY=1`؛ وصف `APP_USER_ACTIVITY` بنوع `users.create`.
4. تسجيل دخول بالجهاز الثاني ⇒ Drawer يعرض الرئيسية/العملاء/الحسابات فقط.
5. داخل العملاء: «إضافة عميل» ظاهر؛ «تعديل/حذف/كشف حساب» **مخفية**؛ و`PUT /customers/1` يدوياً ⇒ **403** بشكل envelope.
6. زر **صلاحيات** في البطاقة → منح `customers.update` → تأكيد «سيتم إنهاء جلساته» → الحفظ ⇒ بعد
   `refresh()` يظهر زر التعديل (أو يُطرد ويُعيد الدخول لو logout_others=1).
7. زر **تعطيل** ⇒ `EXPIRES_AT=SYSDATE` في جلساته ⇒ طلبه التالي 401 ⇒ العميل يقفز إلى `/login` تلقائياً.
8. زر **سجل نشاط** ⇒ كل ما سبق معروضاً بالعربية: الوقت + الوصف + success/failed + IP.
9. **الجلسات النشطة**: الجلسة الثانية تظهر بوقت متبقٍ؛ إنهائها ⇒ خروج فوري من الجهاز.
10. **إعدادات الأمان**: `session_idle_minutes=1` ⇒ بعد دقيقتين 401 «انتهت مدة الخمول»؛ ثم `240` والعمل
    30 دقيقة ⇒ **بلا أي انقطاع** (التجديد الانزلاقي يعمل) و`EXPIRES_AT` يتمدّد في القاعدة.
11. حواجز الأمان: إزالة `IS_ADMIN` عن نفسي ⇒ 403؛ حذف المستخدم الحالي ⇒ 422؛ تعطيل آخر مدير ⇒ 403؛
    منح `foo.bar` ⇒ 422 مع `errors.unknown_codes`؛ مستخدم غير مدير يحاول `is_admin=1` ⇒ 403.
12. **العربية**: أسماء المستخدمين والصلاحيات والإعدادات وسجل النشاط سليمة في كل شاشة عبر السلسلة
    DB → `ArabicEncoding::cleanData()` → JSON → `ArabicEncodingUtils.fix()` → widget.
13. البوابات: `flutter analyze` · `flutter test` · `vendor/bin/pint --dirty --format agent` · `vendor/bin/pest`.

---

## 11. المخاطر والمعالجات

| الخطر | المعالج في هذه الخطة |
|---|---|
| قفل النظام بفقد آخر مدير | `IS_ADMIN` خارج جدول المنح + حارس «آخر مدير» + منع حذف/تعطيل/سحب للذات + بَاك §3.3 |
| طرد المستخدمين عند إغلاق مسارات الأعمال | `05_ibac_bootstrap_grants.php` (منح كامل) + الإغلاق في مرحلة 7 بعد اكتمال الواجهات (D3) |
| كتابة على `PERSONAL_ACCESS_TOKENS` كل طلب | عتبة `session_touch_threshold_minutes` ⇒ ~1 كتابة لكل جلسة كل 5 دقائق + `saveQuietly` |
| الجلسات القديمة `EXPIRES_AT IS NULL` | ترحيل ناعم: تُقبل وتُمنح مهلة كاملة في أول طلب (§6.3) |
| ضبط `sanctum.expiration` مستقبلاً يكسر السلوك | يُترك `null` + تعليق صريح في `config/sanctum.php` يمنع تغييره |
| أعمدة CLOB في جدول التوكنات | لا `LIKE/ORDER BY` على `NAME/ABILITIES`؛ العرض في PHP (§7.8) |
| `CACHE` اسم جدول ERP؟ | بنية Laravel مؤكدة (§1.10)؛ ومع ذلك يُختبر `Cache::put` في مرحلة 0.5 |
| mojibake (الخطأ C1 المتكرر) | **كتابة:** `toOracleSearchChars()` (بايتات CP1256 الخام تُستبدل بـ `0xBF` لأن العميل AL32UTF8) — **قراءة:** `cleanData()` — **عميل:** `fix()` في كل موديل Dart + البند 12 في §10 |
| زناد لا يُترجم لأن `ACCOUNTS` اسم عرض أيضاً | أسماء التسلسلات داخل PL/SQL تُذكر **غير مسبوقة** (`SEQ_X.NEXTVAL`)؛ انظر البند 16 في §1 |
| Trigger على `APP_USERS` يكسر الـ ERP | لا Trigger؛ `SEQ_APP_USERS_ID.NEXTVAL` صراحة في `store` |
| سباق `MAX+1` | Sequences لكل الكائنات الجديدة |
| تضارب فهرس Drawer (4↔5) مع الحجب | `portal_sections.dart` قبل أي حجب (مرحلة 6) |
| تصعيد صلاحيات من مستخدم متوسط | `IS_ADMIN` لا يمنحه إلا مدير + رفض منح أكواد غير مملوكة + `users.permissions_manage` منفصلة |
| نمو `APP_USER_ACTIVITY` | فهرسات على `CREATED_ON` + `activity_log_retention_days` + `php artisan app:prune-activity` مجدول (مرحلة 9 اختيارياً) |
| تغيّر الصلاحيات لا يسري (توكن لا ينتهي) | قراءة الخادم لكل طلب + `Cache::forget` + إنهاء الجلسات بعد `syncUser` |
| كسر `USER_NO` بعد D6 | إزالة من `fillable` (يمنع ORA-00904 عند الإنشاء) + تعديل الاستعلام في `login:53` + توثيق في `AGENTS.md` |
| `password_min_length=4` ضعف تشفيري | قرار مؤقت صريح (D2)؛ التجزئة مؤجَّلة ومدرجة في §13 |
| إصلاح `InvoiceController` يغيّر شكل الاستجابة | يُنفَّذ كإصلاح مقصود (C5) في مرحلة 7 مع اختبار، لا كعرض جانبي |
| أزرار كثيرون داخل البطاقة على الجوال | `PopupMenuButton` عند `width < 600` (نفس نمط `DataListScaffold`) |

---

## 12. خطة النشر

1. **N-1**: مرحلة 1 (DDL) على بيئة التطوير + مراجعة تحققات §4.7 مع صاحب العمل.
2. **N-1**: مراحل 2–6 على فرع التطوير؛ الخلفية **غير مغلقة** ⇒ لا انقطاع لأي جهاز قديم.
3. **N**: دمج مرحلة 8 (واجهات الإدارة) مع مرحلة 7 (الإغلاق) + المنح التأسيسية في **نفس الإطلاق**.
4. **N**: توزيع الـ APK المحدث **قبل** تفعيل الإغلاق على خادم الإنتاج (أو بعد تأكيد تحديث كل الأجهزة).
5. **N+1**: تقليص المنح التأسيسية تدريجياً حسب الأدوار الواقعية من شاشة إدارة المستخدمين.
6. **rollback**: `04_ibac_rollback.sql` + `git revert` لمسارات `routes/api.php` + استرجاع `APP_USERS` من البَاك إن لزم.

---

## 13. خارج النطاق (بقرار صريح)

* **الأدوار (Roles)** — المطلوب IBAC ومنح مباشر؛ لا `app_roles` ولا `app_role_permissions`.
* **تشفير كلمات المرور** — مؤجَّل (D2)؛ وما تم الآن توسيع العمود فقط مع إبقاء النص الصريح.
* **نطاق البيانات بالفرع** — لا (D4).
* `single_active_session_per_device` و`max_failed_logins` التنفيذيان: يحتاجان عمودين على `APP_USERS`
  (`FAILED_ATTEMPTS`, `LOCKED_UNTIL`) ⇒ الإعدادات موجودة وقيمتها `0/معطّل` حتى تُعتمد الإضافة.
* تصدير/طباعة سجل النشاط وكتالوج الصلاحيات (أزرار معروضة مطفأة).
* حزمة خارجية (`spatie/laravel-permission`)، أي codegen (freezed/json_serializable/build_runner)،
  اعتماديات Dart/PHP جديدة.
* توحيد `meta` الباجينيشن أو حدود `limit` بين الـ controllers (يكسر العميل).
* RBAC الذي توهمه تسمية `roles.md` — لا وجود له ولا يُبنى الآن.
* Dark theme / تبديل اللغة / تحويل شاشات الميزات إلى `app_router.dart`.
* تتبع جلسات جهازي دقيق (device fingerprint) — «الجهاز» يُقرأ من `APP_USERS.DEVICE_NAME/PLATFORM` فقط.

---

## 14. قائمة التحقق النهائية (DoD)

```bash
# قاعدة بيانات (Oracle MCP)
SELECT COUNT(*) FROM ACCOUNTS.APP_PERMISSIONS;                     -- 93
SELECT COUNT(*) FROM ACCOUNTS.APP_SETTINGS;                         -- 10
SELECT column_name FROM all_tab_columns
 WHERE owner='ACCOUNTS' AND table_name='APP_USERS' AND column_name='IS_ADMIN';   -- صف واحد
SELECT object_name FROM all_objects
 WHERE owner='ACCOUNTS' AND object_name LIKE 'TRG_APP%' AND status<>'VALID';      -- صفر صفوف

# الخلفية (kyApp_API)
php artisan route:list --path=api                                   -- 71، والمحماية auth:sanctum مطبّقة
vendor/bin/pint --dirty --format agent
vendor/bin/pest --filter=UsersAdmin
vendor/bin/pest --filter=PermissionSync
vendor/bin/pest --filter=SessionPolicy
vendor/bin/pest --filter=SecuritySettings
vendor/bin/pest                                                     -- كامل (عدا TableQueryTest البيئي)

# العميل (ky_apps)
flutter analyze                                                     -- No issues found!
flutter test                                                        -- أخضر + اختبارات overflow للإدارة
```

- [ ] §10 بخطواته الـ 13 مُنفَّذ على جهازين: مدير وموظف بمنح جزئية.
- [ ] `IS_ADMIN=0` ومنح فارغ ⇒ لا قسم أعمال ظاهر **ولا** أي مسار أعمال يعمل.
- [ ] التجديد الانزلاقي مُثبَت (طلب كل دقيقتين لمد 30 دقيقة ⇒ صفر 401) والخمول ⇒ 401 برسالة عربية.
- [ ] «إدارة المستخدمين»: إضافة/تعديل/تعطيل/حذف + بحث/فلترة/فرز + أزرار البطاقة الخمسة تعمل.
- [ ] الصلاحيات تُمنح داخل نموذج الإنشاء، وتُعدَّل من زر «صلاحيات» في البطاقة، ومرتبّة حسب الأقسام.
- [ ] «الجلسات النشطة» و«إعدادات الأمان» و«سجل نشاط» تقرأ وتكتب في القاعدة وتؤثر فوراً.
- [ ] العربية سليمة من Oracle إلى الـ widget في كل الكيانات الجديدة.
- [ ] مسارات الأعمال مغلقة (D3) عدا المستثنَين بتصميم، مع منح تأسيسية لا تطرد مستخدماً حقيقياً.
- [ ] لا ملف توثيق جديد خارج `AGENTS.md` / `todo.md` / `db_commends.md` / `devloping_history.md`.
- [ ] commit داخل `kyApp_API` ثم push ثم bump المؤشر في `ky_apps` (رسائل عربية، بلا `--no-verify`).

---

## 15. نتيجة المرحلة 8 والانحرافات المُقصَدة عن §8 · [2026-10-19 06:50:30] · Qoder Agent

### الحالة

- **الأكواد: مكتملة.** `lib/features/admin/` (36 ملفاً: 7 موديلات + `AdminResult`/`PagedResult`،
  4 مستودعات، 6 مزوّدين، 10 شاشات، 9 ودجات) + `ManagementDashboardScreen` بدل الـ placeholder.
- **البوابات:** `flutter analyze` = No issues found! · `flutter test` = **51 ناجحة / صفر فشل**
  (`test/ibac_test.dart` 20 + `test/responsive_layout_test.dart` 27 ومنها 18 حالة شاشات × حجمين).
- **القبول اليدوي §10: لم يُنفَّذ.** كل خطوة فيه كتابة في `ACCOUNTS` الحيّ، وهي موقوفة على إذن
  صريح؛ ولم يُشغَّل أي SQL في هذه المرحلة (لا قراءة ولا كتابة) — الاختبارات بمزيفات مستودعات.
- **لم يُنفَّذ أي commit** (لا أمر به)، والتنفيذ جرى على `main` بلا فرع `feat/ibac-permissions`
  خلافاً لـ §3.2 — انحراف تشغيلي مُعلَن لا تقني.

### انحرافات §8 المنفَّذة بقرار (لكل منها سبب، ولكل واحدة مقابل)

| §  | ما قالته الخطة | ما نُفِّذ | السبب |
|---|---|---|---|
| 8.1/7 | حمولة المنح `codes` | `{'permissions': [...], 'logout_others': bool}` في الكتابة، و`granted_codes` في القراءة | الخادم هو من يُحدّد العقد؛ أي شكل آخر يعني ترجمة صامتة داخل المستودع |
| 8.3 | `user_activity_provider.dart` بـ `.family(userId)` | `Notifier` واحد + `loadFor(userId)` يحمل `userId` في الحالة | `family` مع `CancelToken` تصنع نسخة حالة لكل مستخدم وتُبقي بعضها حياً بعد الخروج؛ الشكل الواحد يلغى ويُمحى في `dispose` |
| 8.3 | `_searchVersion` في `adminUsersProvider` | `CancelToken` واحد يُلغى عند كل طلب جديد | الإلغاء يقتل السباق من مصدره؛ العدد الطوبولوجي كان سيظل يحتاج فحصاً بعد الردّ |
| 8.3 | مزوّد نشاط عام لكل الشاشات | لا مسار `/activity` عام؛ السجل على `/users/{id}/activity` فقط | تسجيل عام كان يتطلب صلاحية `system.*` أو تسريب نشاط مستخدمين لغيرهم |
| 8.1 | helpers متفرقة في كل موديل | `JsonValues` (قراءة مزدوجة الحالة + `asArabic`) و`AdminResult` و`PagedResult` مشتركة | أربع موديلات تقرأ نفس الانحراف الأبجدي؛ النسخ يعني أربعة مواضع إصلاح لكل خطأ |
| 8.4 | «تحديد كل القسم» يرسل `module.*` | يرسل الأفعال الحرفية للقسم | الوايلدكارد أوسع من مجموع أفعاله، وغير المدير لا يملك إرساله أصلاً (`not_held`) |
| 8.4 | `SwitchListTile(activeThumbColor:)` | `activeColor` | `activeThumbColor` غير موجود في Material الذي يبني عليه Flutter 3.7؛ `activeColor` هو الاسم القائم |
| 8.4 | الفرز بـ `sort` نصّي واحد | `applySort(String column, String direction)` + `UserSortSpec` | الفرز على الاسم العربي وحده لا يكفي، والخادم يقبل عموداً واتجاهاً؛ إضافة البنية في المزوّد أرخص من تغيير العقد لاحقاً |
| 8.4 | قائمة الجلسات بمؤقّت لكل بطاقة | `Timer.periodic` واحد في الشاشة يمرّر `now` | عشرون بطاقة = عشرون مصدراً لإعادة الرسم وعشرون مصدر إلغاء؛ والدقة المطلوبة دقيقة واحدة للعرض كله |

### انحرافات أُصلحت في نفس الجولة (لا تُترك كدَين)

1. `bool _changePassword = false;` بدل `late` — كان يُسقط كل نموذج تعديل بـ `LateError`.
2. `!isSearchOn && !disabled` على شريط الاختصار في `PermissionModuleGroup` — كان يوحي بأن
   «كل القسم» محقَّق بينما القائمة مفلترة، ويعرض أزراراً على هدف مقفل.
3. أربع مواطن `RenderFlex` على 360 (`LayoutBuilder` + `ConstrainedBox` + `Flexible` + `Wrap`)
   — البند **24** في §1.
4. `_List` في `ActiveSessionsScreen` صار `ConsumerStatefulWidget` — `context`/`mounted` بعد
   انتظار حوار التأكيد.
5. تعليق لاتيني مسرّب في `admin_users_provider.dart` صُحِّح (قاعدة التعليق العربي المزدوج).

### ما تبقّى لإغلاق المشروع

- **§10 حرفياً على جهازين** (مدير + موظف بمنح جزئية) بعد إذن الكتابة.
- **المرحلة 9:** تحديث `AGENTS.md` الجذري و`kyApp_API/AGENTS.md` (71 مساراً، الجداول الخمسة،
  `IS_ADMIN`، `USER_ID`)، وحواجز الإطلاق في AGENTS §9 (`INTERNET`، `applicationId`، توقيع release).
- **دَين موثّق من §5.1:** تحويل مسارات الكتابة في `Customer`/`Currency`/`Account` إلى
  `toOracleSearchChars()` (تم في `UserAdminController` و`ActivityLogger`، ولم يُمسّ جداول الأعمال).
