# قائمة المهام (Todo List)
## [2026-09-08 03:34:46] - إعداد والتحكم برابط Laravel API من واجهة التطبيق
- [x] إضافة دوال حفظ واسترجاع عنوان رابط الـ API في `SecureStorageService`.
- [x] تحديث `DioClient` وتهيئة رابط الـ BaseUrl ديناميكياً من التخزين الآمن وتوفير إمكانية تحديثه فورياً.
- [x] إنشاء Notifier / Provider لإدارة إعدادات الـ API وفحص الاتصال بالخادم.
- [x] تصميم وبناء شاشة إعدادات الـ API (`ApiSettingsScreen`) مع:
  - إدخال وتعديل رابط الـ API مع أزرار سريعة للاختيار والتجربة.
  - زر فحص الاتصال بالخادم (`/hello` أو عنوان الـ API) وعرض نتيجة الاستجابة مع مؤشر التحميل وزمن الاستجابة.
  - زر الحفظ مع حوار تأكيد وتحذير بمخاطر التغيير قبل الاعتماد.
- [x] إضافة مسار الشاشة في `GoRouter` (`/api-settings`).
- [x] إضافة أيقونة إعدادات أنيقة أعلى شاشة تسجيل الدخول (`LoginScreen`) تفتح شاشة إعدادات الـ API.
- [x] التحقق واختبار التطبيق والتوثيق في ملفات المشروع.
## [2026-09-08 04:25:01] - حل مشكلة استجابة الواجهات وتجاوز حدود الشاشة (Layout Overflow & Responsiveness)
- [ ] فحص كود `EmployeeMainLayout` والشاشات الفرعية وتحديد أسباب الـ Overflow (في الـ Row والـ Column والـ Sidebar).
- [ ] تطبيق مبادئ التجاوب ومرونة الشاشات (Responsiveness) المحددة في `appsroles.md` (استخدام `LayoutBuilder`, `Breakpoints` بين الهواتف والأجهزة اللوحية وسطح المكتب).
- [ ] تحويل الشريط الجانبي (Sidebar) على الهواتف والشاشات الصغيرة إلى `Drawer` أو `BottomNavigationBar` بدلاً من عرضه كعمود ثابت يضغط على مساحة الشاشة.
- [ ] استخدام `SingleChildScrollView`, `Expanded`, `Flexible`, و `Wrap` لمنع أي RenderFlex Overflow.
- [ ] فحص واختبار التجاوب على مختلف مقاسات الشاشات وتشغيل `flutter test` و `flutter analyze`.
- [ ] توثيق التغييرات في `devloping_history.md` و `DBdevloping_history.md`.
## [2026-09-08 07:19:44] - تطبيق تنسيق كشف حساب العميل المطابق للنموذج المعتمد (شركة الكبودي للخياطة)
- [x] تصحيح استعلام الـ SQL في `CustomerController.php` ليطابق الحقول (`ENTRY_TYPE_NO`) وحساب المدين والدائن والرصيد الافتتاحي والنهائي.
- [x] تصميم ترويسة كشف الحساب المتطابقة (شعار الكبودي، الشعار الهندسي، شريط العنوان وأرقام الهواتف).
- [x] تصميم البيانات الوصفية (اسم العميل، رقم العميل باللون الأحمر، العملة يمني YR، رقم واسم الحساب، نطاق التاريخ).
- [x] بناء جدول كشف الحساب الكلاسيكي المحاسبي باللون الخردلي/الذهبي للأعمدة: [السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد].
- [x] إدراج سطر الرصيد الافتتاحي وسطور الحركات وسطر إجمالي العمليات وسطور الرصيد الافتتاحي والنهائي بتنسيق مطابق للصورة.
- [x] دعم التجاوب والطباعة/المعاينة على مختلف الشاشات (الهاتف، التابلت، الويب).
- [x] اختبار التشغيل وتوثيق التغييرات في ملفات المشروع.
## [2026-09-08 07:44:50] - استكمال وتدقيق كافة متطلبات قسم العملاء
- [x] واجهة لوحة تحكم العملاء الرئيسية مع 5 بطاقات تفاعلية أنيقة وتأثيرات حركية.
- [x] واجهة إضافة عميل مع كافة الحقول (`CUST_NAME`, `ADDR`, `TEL1`, `TEL2`, `POSTBOX`, `EMAIL`, `FAX`, `ACC_NO`, `LIMITED_BALANCE`, `PRE_CUST_NAME`, `STOPPING_CUST`) والتحقق الصارم.
- [x] واجهة تعديل عميل مع اختيار العميل والبحث الفوري وتعبئة النموذج والتحديث.
- [x] واجهة حذف عميل مع البحث واختيار العميل وعرض بطاقة المعاينة وحوار تأكيد الحذف.
- [x] واجهة كشف حساب العميل بالنموذج الرسمي لشركة الكبودي للخياطة المتطابق مع الصورة.
- [x] واجهة كل العملاء مع شبكة/قائمة متجاوبة والبحث الفوري والإجراءات السريعة.
- [x] ربط الواجهات بـ Laravel API وقاعدة بيانات أوراكل واجتياز `flutter analyze` بدون أي خطأ أو تحذير.
## [2026-09-08 08:02:44] - تحسينات متقدمة لقسم العملاء وكشف الحساب
- [x] دعم البحث برقم الهاتف (`TEL1`, `TEL2`) في الواجهة الخلفية (Laravel) وفي تطبيق فلاتر.
- [x] إضافة حقول تصفية كشف الحساب بواسطة نطاق التواريخ (من تاريخ / إلى تاريخ) مع منتقي التواريخ ودعمها في الـ API.
- [x] إصلاح مشاكل تجاوز حدود الشاشة (RenderFlex Overflows) في كشف الحساب وشاشة اختيار العميل وجعلها متجاوبة بالكامل على الهواتف والشاشات المختلفة.
- [x] حل مشكلة ترميز النصوص العربية في قاعدة بيانات Oracle (Windows-1256 / Mojibake) في Laravel API وتطبيق Flutter لضمان قراءة وكتابة نصوص عربية سليمة 100%.
- [x] فحص واختبار التغييرات والتوثيق في ملفات المشروع.

## [2026-09-08 20:53:00] - فتح قائمة اختيار العميل مباشرة من البطاقات وجعل جدول كشف الحساب متجاوباً بالكامل
- [x] تعديل بطاقات لوحة تحكم العملاء (تعديل عميل، حذف عميل، كشف حساب) لفتح شاشة اختيار العميل `CustomerPickerScreen` مباشرة بمجرد النقر، ثم الانتقال الفوري لشاشة الإجراء المحدد فور الاختيار دون أي خطوة وسيطة.
- [x] تحويل جدول وعناصر كشف الحساب `_buildStatementTableLayout` من قياسات ثابتة مع شريط تمرير إلى جدول متجاوب بنسبة 100% مع عرض الشاشة عبر `LayoutBuilder` وأعمدة `FlexColumnWidth` متناسبة، وأحجام خطوط وهوامش متكيفة مع مختلف أحجام الشاشات.
- [x] اجتياز فحص `flutter analyze` بنجاح كامل بدون أي خطأ أو تحذير (`No issues found!`).

## [2026-09-08 22:31:29] - إضافة وتطوير قسم "جاري العاملين" (الموظفين - القصاصين - الخياطين)
- [x] بناء قسم "جاري العاملين" في القائمة الجانبية وتخطيط بوابة الموظف بالكامل مع 3 بطاقات رئيسية تفاعلية.
- [x] إنشاء شاشات إدارة الموظفين (`TAILOR_EMPLOYEES`) والقصاصين (`CUTTER`) والخياطين (`TAILOR`) مع زر إضافة في أعلى كل قائمة.
- [x] إضافة أيقونات الإجراءات المرتبة لكل عامل: (كشف حساب، كشف حضور/عمل، تعديل، تعطيل/تفعيل، حذف).
- [x] بناء شاشة الإضافة والتعديل للعمال ودعم حقول الراتب والمسمى الوظيفي للموظفين.
- [x] بناء شاشة كشف حساب العمال اعتماداً على الاستعلام المخصص مع تصفية التاريخ وتلخيص الرصيد والدائن والمدين.
- [x] تطبيق دوال معالجة وتنسيق النصوص العربية (Windows-1256 / Mojibake) في كل من الـ API والـ Flutter.
- [x] حل كافة أخطاء وتحذيرات المشروع واجتياز فحص `flutter analyze` بنجاح كامل بدون أي أخطاء أو تحذيرات (`No issues found!`).

## [2026-09-08 23:05:42] - إصلاح كشف حساب العاملين ومشاكل البحث
- [x] حل مشكلة عدم العثور على رقم الحساب `ACC_NO` في استعلام كشف حساب العاملين بسبب تطابق أسماء الحقول الصغيرة والكبيرة من استعلام Oracle PDO.
- [x] تفعيل وتحسين استعلام كشف الحساب وتصفية التواريخ (`TRUNC(ENTRY_DATE) BETWEEN ...`) وإرجاع ملخص الحركات والرصيد والبيان العربي بنجاح 100%.
- [x] إضافة مؤقت تأخير تفاعلي (Debounce 300ms) في البحث بقوائم العاملين (الموظفين، القصاصين، الخياطين) لمنع إلغاء الطلبات المتكررة وتجنب استثناءات Dio.
- [x] اجتياز فحص `flutter analyze` بنجاح كامل بدون أي خطأ أو تحذير (`No issues found!`).

## [2026-09-12 21:10:29] - تطوير قسم الحسابات والشجرة المحاسبية والعملات وحل المشاكل
- [x] بناء وتطوير الـ API في Laravel (`AccountController.php` و `CurrencyController.php` وتحديث `routes/api.php`) للتعامل مع حسابات أوراكل والعملات وأسعار الصرف.
- [x] إنشاء طبقة البيانات Data Layer في Flutter: النماذج (`account_model.dart`، `chart_account_model.dart`، `currency_model.dart`) والمستودعات (`account_repository.dart`، `currency_repository.dart`).
- [x] بناء مزودات الحالة Riverpod (`accounts_provider.dart`، `currency_provider.dart`) للشجرة المحاسبية، والحسابات المالية، والعملات، وسجل أسعار الصرف.
- [x] تطوير واجهات المستخدم (UI):
  - لوحة تحكم قسم الحسابات (`accounts_dashboard_screen.dart`) تحتوي بطاقات الخدمات المحاسبية وإحصائيات سريعة.
  - إنشاء حساب جديد (`create_account_screen.dart`) لدعم إنشاء "مجموعة حسابات جزئية" و "حساب مالي" مع السلسلة الهرمية للأب.
  - تعديل حساب مالي (`edit_account_screen.dart`) لتعديل الاسم، الرصيد، سقف الحساب، وخيار التوقيف.
  - كشف حساب مالي (`account_statement_screen.dart`) مشابه لكشف حساب العاملين مع اختيار الحساب وتصفية التواريخ وملخص الرصيد.
  - كشف حساب مفصل (`account_statement_detail_screen.dart`) مع خيارات متقدمة وتصفية المستويات والعملات.
  - الشجرة المحاسبية (`account_tree_screen.dart`) بطريقة تفاعلية مع خيارات البحث، وتوسيع/طي الكل، وتصدير/طباعة، واستثناء حسابات العملاء وإظهار حساب "عملاء الكبودي للخياطة" (12310000) فقط.
  - العملات وأسعار الصرف (`currency_screen.dart`) لإدارة العملات وتحديث أسعار الصرف اليومية وسجل الأسعار السابقة.
- [x] دمج قسم الحسابات بالكامل داخل `AccountsSection` في بوابة الموظفين (`EmployeePortal`).
- [x] حل كافة أخطاء وتحذيرات `current_problems` (تحديث `AppColors.surface`، `WidgetStateProperty`، دوال تنسيق التواريخ بدون حزمة خارجية، واستخدام `withValues`).
- [x] اجتياز فحص `flutter analyze lib` بنجاح تام بدون أي أخطاء أو تحذيرات (`No issues found!`).


## [2026-10-04 06:14:00] - ����� DioException ������ RenderFlex Overflow �� ��� ��������
- [x] ��� CancelToken �� WorkerRepository ��� ������ ������� (_listCancelToken � _statementCancelToken) ���� ����� ����� ����� ������ �� ����� ��� ������.
- [x] ����� RenderFlex overflow �� ���� ������ ��� ������� (_buildPaginationBar) �� worker_statement_screen.dart ��� ����� ���� �� Expanded �� TextOverflow.ellipsis.
- [x] ����� RenderFlex overflow �� �� ������� ������ (��� / ���� / ����) �� workers_list_screen.dart ��� ����� ������� �� Flexible.

## [2026-10-04 23:51:00] - ����� ������ ��������� ������� (Biometric Authentication)
- [ ] **DB**: ����� ���� USER_BIOMETRIC_DEVICES �� Oracle
- [ ] **API**: ����� Model: app/Models/UserBiometricDevice.php
- [ ] **API**: ����� registerBiometric(), biometricLogin(), revokeBiometric() �� AuthController
- [ ] **API**: ����� �������� �� routes/api.php
- [ ] **Flutter**: ����� local_auth, device_info_plus, crypto �� pubspec.yaml
- [ ] **Flutter**: ����� Android Manifest � iOS Info.plist
- [ ] **Flutter**: ����� core/utils/device_id_helper.dart
- [ ] **Flutter**: ����� secure_storage_service.dart (����� biometric keys)
- [ ] **Flutter**: ����� auth/data/models/biometric_status_model.dart
- [ ] **Flutter**: ����� auth_repository.dart (����� biometric methods)
- [ ] **Flutter**: ����� settings/presentation/providers/biometric_settings_notifier.dart
- [ ] **Flutter**: ����� auth_notifier.dart (����� biometric state)
- [ ] **Flutter**: ����� auth/presentation/widgets/biometric_login_button.dart
- [ ] **Flutter**: ����� login_screen.dart (����� �� ������)
- [ ] **Flutter**: ����� api_settings_screen.dart (����� ��� ������� ������)
- [ ] **������**: ������ ���� ��� ���� �����


## [2026-10-05 08:39:00] - ����� ����� ������ ����� ������ ���������
- [x] **����� 1**: ����� ���� �������: portal_section_scaffold.dart ����� ������ �� widget ���� ������� ������ ��� (���� ���/CRUD ������)
- [x] **����� 2 - DataListScaffold**: ����� data_list_scaffold.dart ���� ���� ������ ����� �������� (������ �����ʡ ����� �����ʡ �����) �� ��� ���� ������ ������
- [x] **����� 2 - Settings**: ����� ����� settings_section.dart ����� ������ ����� ��� 3 �����: ����� API� ����/���ɡ ������� ���� (���/���/��� ��)
- [x] **����� 2 - API Screen**: ����� pi_settings_screen.dart ������ ��� ������� API ��� (���� ��� ������ ���ǡ ����� ���� �� settings_section ���)
- [x] **����� 3 - Responsive**: ������� ���� ������� ������� ������ ���� ����� ��� MediaQuery.sizeOf, MediaQuery.textScalerOf, � clamp() �� ���� ��� widgets �������
- [x] **����� ������ �������**: ��� ���� '�������' ������/������ �� ����� collapsible_side_drawer.dart (��� ���� 10 ����� ����� �� 9)
- [x] lutter analyze ? No issues found!

## [2026-10-05 09:40:00] - ضبط وتحسين واجهات الحسابات
- [x] إعادة تصميم واجهة قسم الحسابات الرئيسية (AccountsDashboardScreen) وضبط أحجام العناصر والبطاقات.
- [x] تنظيم الأقسام إلى مجموعات منطقية: التقارير والكشوفات المالية، الهيكل المحاسبي وإدارة الحسابات، ودليل العملات والصرف.
- [x] استبدال البطاقات الضخمة غير المتناسقة ببطاقات منظمة وأنيقة مع أبعاد متوازنة ومؤشرات واضحة وشريط إحصائيات مدمج.
- [x] التحقق من سلامة كود Flutter بالكامل (lutter analyze: No issues found).

## [2026-10-17 05:25:00] - بناء نظام المصادقة والصلاحيات IBAC (المرجع: ibac_permissions_plan.md)
- [x] **مرحلة 0**: تجميد القرارات D1–D9 + نقطة استرجاع `APP_USERS_BAK_IBAC` + فحص صلاحيات Oracle والمسميات المتعارضة + تأكيد بنية جداول CACHE في أوراكل.
- [x] **مرحلة 1 — قاعدة البيانات**: جداول `APP_PERMISSIONS` و`APP_USERS_PERMISSIONS` و`APP_SETTINGS` و`APP_USER_ACTIVITY`.
- [x] **مرحلة 1 — APP_USERS**: توسيع `USER_PASSWORD` إلى 100 + إضافة `IS_ADMIN NUMBER(1) DEFAULT 0 NOT NULL` + `SEQ_APP_USERS_ID` (بلا محفِّز حمايةً للنظام القديم).
- [x] **مرحلة 1 — كائنات مساندة**: 5 تسلسلات + 4 محفِّزات (VALID) + 13 فهرساً + 49 تعليقاً ثنائي اللغة على الجداول والأعمدة.
- [x] **مرحلة 1 — بذر**: 93 صلاحية (17 وحدة، 47 أساسية، 17 منحاً عاماً) + 10 إعدادات أمان، مشتقة كلها من `PermissionCatalog`.
- [x] **مرحلة 1 — تهيئة**: ترقية `USER_ID=1` إلى `IS_ADMIN=1, USER_TYPE=1` + منح `system.*` + صفحة تدقيق `system.bootstrap`.
- [x] **مرحلة 1 — سكربتات قابلة لإعادة التشغيل**: `kyApp_API/database/oracle/{01_ibac_schema.sql, 02_ibac_seed.php, 03_ibac_bootstrap.php, 04_ibac_rollback.sql}`.
- [x] **إصلاحان مكتشفان أثناء التنفيذ**: المحفِّزات لا تقبل `ACCOUNTS.SEQ_X` (يوجد VIEW اسمه ACCOUNTS ⇒ PLS-00302)؛ وكتابة العربية بـ `encodeForOracle()` تُنتج `0xBF` مع عميل AL32UTF8 ⇒ الصحيح `toOracleSearchChars()`.
- [ ] **تصحيح لاحق مطلوب (خارج نطاق المرحلة 1)**: مسارات الكتابة العربية في `CustomerController` و`CurrencyController` و`AccountController` تستخدم `encodeForOracle()` وتُتلف النص — تُحوَّل إلى `toOracleSearchChars()` مع اختبار نهاية-to-نهاية.
- [x] **مرحلة 2 — الخلفية** (اكتملت 2026-10-17 07:17:24 — راجع البلوك أدناه): `PermissionResolver` + `SettingsStore` + `ActivityLogger` + `SessionPolicy` وربط `Sanctum::$accessTokenAuthenticationCallback` في `AppServiceProvider::boot()` + نماذج `Permission`/`UserPermission`/`AppSetting`/`UserActivity` + تحديث `User` (إضافة `IS_ADMIN` وحذف `USER_NO` الوهمي) + تحميل الصلاحيات في `login`/`me` + `EXPIRES_AT` عند إنشاء التوكن.
- [ ] **مرحلة 3 — الخلفية**: `UserAdminController` (قائمة/إنشاء/تحديث/تعطيل/حذف/سجل نشاط/صلاحيات) + `PermissionController` + `EnsurePermission` + 9 مسارات + Pest. *(اكتملت 2026-10-18 00:03:42 — راجع البلوك أدناه؛ 11 مساراً فعلياً لا 9)*
- [x] **مرحلة 4 — الخلفية**: `SessionAdminController` (جلسات نشطة + إنهاء) + `SettingController` (قراءة/حفظ `APP_SETTINGS`) + 5 مسارات + Pest. *(اكتملت 2026-10-18 02:52:11 — راجع البلوك أدناه؛ الإجمالي الفعلي 71 مساراً، وعولجت علّتان مكتومتان في `SettingsStore` من المرحلة 2 وواحدة في `UserAdminController@toggle`)*
- [x] **مرحلة 5+6 — العميل**: `permission_codes.dart` (93 كوداً) + `permission_check.dart` + حقول `AuthState` و`can/canAny/canAll` + مفاتيح التخزين الآمن الجديدة + `PermissionsNotifier` + `PermissionGate` + توحيد ترتيب الأقسام (إصلاح تعارض فهرس الدرج 4↔5) + اختبارات. *(اكتملت 2026-10-19 01:47:33 — التفاصيل في §المرحلة 5+6 أدناه؛ انحراف واحد موثّق: `WidgetsBindingObserver` بدل `AppLifecycleListener`.)*
- [ ] **مرحلة 7 — D3**: إغلاق مسارات الأعمال (`customers`/`workers`/`accounts`/`currencies`/`invoices`/`selectFromTable`) + قائمة ممنوعة للجداول الحساسة + إصلاح مظروف `InvoiceController` + منح ترحيبية للمستخدمين النشطين قبل الإغلاق.
- [ ] **مرحلة 8 — الواجهات**: بطاقات الإدارة الجديدة + إدارة المستخدمين (بحث/فلترة/فرز + زر إضافة أعلى القائمة + أزرار تعديل/صلاحيات/تعطيل/حذف/سجل نشاط لكل بطاقة) + نموذج إنشاء المستخدم وفيه محدد الصلاحيات المنظم حسب الأقسام + شاشة التحكم بصلاحيات المستخدم + الجلسات النشطة + إعدادات الأمان + سجل النشاط.
- [ ] **بوابات الجودة**: `vendor/bin/pint --dirty --format agent` + `php artisan test` + `flutter analyze` (لا مشاكل) + `flutter test`.


---
## [2026-10-17 07:17:24] - المرحلة 2: طبقة IBAC في الخلفية (مكتملة)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 07:17:24 · **الحالة:** منجزة وموثّقة
- **ما أُنجز:**
  - [x] `PermissionCatalog` — 93 صلاحية (17 وحدة) + `arabicName()` لرسائل الرفض ثنائية اللغة.
  - [x] `PermissionResolver` — رفض افتراضي (deny-by-default)، تجاوز المدير عبر `IS_ADMIN` خارج جدول المنح،
    `can/canAny/canAll`، `payloadFor()`، وكاش بسقف 3000 بايت.
  - [x] `SettingsStore` — قراءة/كتابة `APP_SETTINGS` بتحقّق الأنواع والحدود `MIN_VALUE`/`MAX_VALUE`
    و`IS_LOCKABLE`، مع كاش مجرّد من العربية بعد `ORA-01461` و`definitions()` للقراءة الكاملة.
  - [x] `ActivityLogger` — أسطر `APP_USER_ACTIVITY` بعربية سليمة (`toOracleSearchChars`) عبر `success()` و`failed()`.
  - [x] `SessionPolicy` + `prime()` + `slide()` — جلسات انزلاقية بمهلة `session_idle_minutes` دون لمس
    مخطط `PERSONAL_ACCESS_TOKENS`، ومركّبة في `Sanctum::$accessTokenAuthenticationCallback`.
  - [x] `config/sanctum.php` — `expiration` يبقى `null` (مع تحذير موثّق) + `last_used_at => true`.
  - [x] `app/Models/User.php` — `IS_ADMIN` في `$fillable`، `casts()`، `isAdmin()`، وحذف `USER_NO` الوهمي.
  - [x] `app/Http/Middleware/EnsurePermission.php` (أول ملف في المجلد) + اختصار `permission` في `bootstrap/app.php`.
  - [x] `AuthController` — تجهيز التوكن، حزمة `userPayload()` (هوية + `is_admin` + الصلاحيات)، تسجيل
    المحاولات الفاشلة والناجحة، وتفعيل مفتاح `biometric_login_enabled`.
  - [x] `tests/Feature/IbacCoreTest.php` — 12 اختباراً / 60 تحققاً · الإجمالي 21 اختباراً / 83 تحققاً.
- **قرارات مؤجَّلة صراحةً:**
  - [ ] نماذج Eloquent (`AppPermission`/`AppPermissionGrant`/`AppSetting`/`UserActivity`) لم تُنشأ: كل
    الطبقات تستخدم SQL مربوطاً مباشراً على اتصال `oracle`، فلا مستفيد منها الآن (لا كود ميت).
  - [ ] `max_failed_logins` و`single_active_session_per_device` يبقيان معطّلين (`0`) — موضّبان في §13 من
    `ibac_permissions_plan.md` ويحتاجان عمودين إضافيين في `APP_USERS`.
  - [ ] سطر `login_failed` واحد بقي في `APP_USER_ACTIVITY` من `AuthTest` لأن الحذف المباشر رُفض من سياسة
    الموافقات — يحتاج إذناً صريحاً من المستخدم لتنظيفه.
- **التالي (لم يبدأ):** المرحلة 3 — `UserAdminController` + `PermissionController` + 9 مسارات + Pest.

---
## [2026-10-18 00:03:42] - المرحلة 3: إدارة المستخدمين ومنح الصلاحيات (مكتملة)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 00:03:42 · **الحالة:** منجزة وموثّقة
- **ما أُنجز:**
  - [x] `app/Support/PermissionGrantSync.php` — مسار الكتابة الوحيد للمنح: `currentFor()` و`resolve()`
    و`replace()` داخل معاملة (حذف منح المستخدم ثم إدراج كل `PERMISSION_ID` مقبول) مع `forget()` لكاش الحلّ.
  - [x] `UserAdminController` — `index` (بحث بالعربية واللاتينية + فلاتر `status`/`user_type`/`admin_only`
    + فرز بقائمة بيضاء + ترقيم `ROW_NUMBER`) و`show` و`store` و`update` و`toggle` و`destroy` و`activity`.
  - [x] حراس الأمان في `UserAdminController`: 409 اسم مستخدم مكرَّر · 422 تحقق (أدنى طول كلمة مرور من
    `APP_SETTINGS`) · 422 منع حذف/تعطيل الذات · 403 حماية «آخر مدير» · 403 منع التصعيد (لا يُمنح إلا
    ما يملكه المانح فعلياً) · `USER_ID` من `SEQ_APP_USERS_ID.NEXTVAL` · إنهاء الجلسات عند التعطيل والحذف.
  - [x] `PermissionController` — `index` (الكتالوج: 17 وحدة × 93 صلاحية مغلّفة بـ `permission_id`) و`forUser`
    و`syncUser` (يرفض الأكواد المجهولة/المعطّلة 422، ينهي الجلسات افتراضياً، ويسجّل `users.permissions_sync`).
  - [x] `AuthController@myPermissions` — `GET /api/auth/permissions`: الحالة الفعّالة للمستخدم + `is_admin`
    + `session_expires_at`، مع تجاهل كاش الحلّ ليقرأ جدول المنح لحظياً.
  - [x] `routes/api.php` — 11 مساراً جديداً خلف `auth:sanctum` ثم `permission:<code>` (الإجمالي 66 مساراً).
  - [x] `SessionPolicy::toDate()` — قراءة منيعة للتواريخ؛ أوراكل تُعيد العمود الفارغ `false`/`''` لا `null`،
    وكان ذلك يُفجّر `isPast()`/`toDateTimeString()` على الجلسات القديمة.
  - [x] الاختبارات: `UsersAdminTest` (15) + `PermissionSyncTest` (11) — قرابة 26 اختباراً كلها للقراءة
    وفروع الرفض فقط؛ الإجمالي 47 اختباراً / 199 تحققاً.
- **انحرافات موثّقة عن الخطة (§7):**
  - 11 مساراً بدل 9 (أُضيف `GET /auth/permissions` و`GET /permissions` لفصل كتالوج الصلاحيات عن حالة المستخدم).
  - `PermissionGrantSync` طبقة جديدة غير مذكورة في §7.1: توحيد الكتابة في مكان واحد يمنع تباعد المنح والحذف.
  - كتابة العربية في `store()` تستخدم `toOracleSearchChars()` (كما تُثبت المرحلة 1)، لا `encodeForOracle()` التي
    كانت ستُتلف النص مع عميل AL32UTF8.
  - نماذج Eloquent ما زالت مؤجَّلة (نفس قرار المرحلة 2): كل شيء SQL مربوط مباشر على اتصال `oracle`.
- **بوابات الجودة:** `vendor/bin/pint --dirty --format agent` (3 ملفات) · `vendor/bin/pest` = 47/199 ناجح ·
  `php artisan route:list --path=api` = 66 · لم تُنفَّذ أي DDL أو حذف على قاعدة الإنتاج في هذه المرحلة.
- **التالي (لم يبدأ):** المرحلة 4 — `SessionAdminController` + `SettingController` + 5 مسارات + Pest.

---
## [2026-10-18 02:52:11] - المرحلة 4: الجلسات النشطة وإعدادات الأمان (مكتملة)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 02:52:11 · **الحالة:** منجزة وموثّقة
- **ما أُنجز:**
  - `app/Http/Controllers/SessionAdminController.php` (جديد): `index` قائمة الجلسات بمظروف
    `meta {total,page,limit,pages}` (نمط Customer/Worker)، `terminate` بجلسة واحدة، `terminateUser`
    لكل جلسات المستخدم. الفرز الأحدث حركة أولاً بـ `ROW_NUMBER()` (بلا OFFSET في أوراكل 11g)، الاسم
    المقنَّن CLOB يُقرأ بـ `DBMS_LOB.SUBSTR(NAME,60,1)`، والحالة محسوبة في SQL نفسه
    (`disabled` / `expired` / `active`)، و`is_current` من توكن الطلب الحالي.
  - `app/Http/Controllers/SettingController.php` (جديد): `index` يخدم `definitions()` بالقيم
    المحوَّلة لأنواعها مع الحدود والتسميات العربية؛ `update` يحفظ دفعة `{key,value}` في معاملة واحدة،
    ويرفض المفتاح المقفل (`IS_LOCKABLE=1`) بلا صلاحية `settings.security_manage` بـ 403، ويكتب وصفاً
    تدقيقياً «من … إلى …».
  - `app/Support/SettingsStore.php`: إضافة `flush()` للإسقاط الصريح بعد الحفظ أو التراجع.
  - `routes/api.php`: 5 مسارات جديدة خلف `auth:sanctum` + `permission:<code>`
    (`sessions.view` · `sessions.terminate` · `settings.view` · `settings.update`) ⇒ الإجمالي **71**.
  - اختبارات: `tests/Feature/ActiveSessionsTest.php` (12 اختباراً / 152 تحققاً) و
    `tests/Feature/SecuritySettingsTest.php` (10 اختبارات / 98 تحقّقاً) — كلها قراءة أو فروع رفض ترجع
    قبل أي عبارة كتابة.
- **علّلات حقيقية عولجت (كانت مكتومة لأن لا أحد حفظ إعداداً من قبل):**
  1. `SettingsStore::normalize()` استعملت الثابت غير الموجود `FILTER_NULL_ON_UNSET` داخل نطاق
     `App\Support` ⇒ `Undefined constant` و500 عند حفظ أي إعداد من نوع `bool`. استُبدلت بقائمة
     صريحة للمسموح (`1/true/yes/on` و`0/false/no/off/`) مع رفض صريح لغير ذلك بدل الإنزلاق الصامت إلى
     false.
  2. `SettingsStore::set()` ربطت باسم `:by` ⇒ `ORA-01745: invalid host/bind variable name` (كلمة
     محجوزة). أعيدت تسمية المربَطات إلى `:setting_value` و`:updated_by` و`:setting_key`.
  3. نفس `:by` كان في `UserAdminController@toggle` (مسار تعطيل/تفعيل المستخدم) — رُصد بمسح شامل
     لكل أسماء المربَطات وأُعيدت تسميته مع `:next` ⇒ `:activated`.
  4. قاعدة `items.min` كانت ميتة: المصفوفة الفارغة تُسقط `required` أولاً فلا تظهر رسالة
     «إعداد واحد على الأقل» أبداً. صارت `present|array|min:1` فتنفصل الرسالتان بدقّة.
- **قرارات وانحرافات:** الإنهاء يُكتب `EXPIRES_AT = SYSDATE - 1` (لا NULL) كي يمرّ عبر مسار `auth:sanctum`
  المعتاد ويخرج العميل وحده بـ 401؛ لا كشف لقيمة التوكن ولا `ABILITIES` في أي استجابة؛ الإعدادات
  تُقرأ من `APP_SETTINGS` لا من `.env`؛ الحفظ يرسل كل الحقول لا المتغيّرة فقط ليصف السجل التدقيقي
  التغيير الفعلي.
- **أثر جانبي نظيف:** أُنشئ `tests/Feature/TmpDiagTest.php` مؤقتاً لطباعة حمولات 500 تحديدًا للمربَط
  المحجوز، وحُذف بعد تأكيد السبب الجذري.
- **بوابات الجودة:** `vendor/bin/pest` = **69 اختباراً / 449 تحقّقاً ناجحة** ·
  `vendor/bin/pint --dirty --format agent` = passed · `php artisan route:list --path=api` = **71** ·
  لا DDL ولا كتابة على القاعدة (تم تأكيد `APP_SETTINGS` بقيمها العشرة الأصلية).
- **التالي (لم يبدأ):** المرحلة 5+6 — نواة الصلاحيات في Flutter وحجب الأقسام.

## [2026-10-19 01:47:33] - المرحلة 5+6: نواة الصلاحيات في العميل وتوحيد الأقسام (مكتملة)
- **النموذج المنفذ / AI Model:** Qoder Agent · **الوقت:** 01:47:33 · **الحالة:** منجزة وموثّقة
- **ما أُنجز — المرحلة 5 (نواة الصلاحيات):**
  - [x] `lib/core/constants/permission_codes.dart` — 93 كوداً في 17 وحدة، مطابقة **حرفية وبالترتيب**
    لـ `PermissionCatalog::codes()` (تحقق مقارنة آلي: 93/93، `missingInDart=[]`، `missingInPhp=[]`،
    ترتيب متطابق) + `permModuleOrder/Labels/ActionLabels` + `permModuleOf/permActionOf/permModuleTitle`
    + `permWildcardOf()` جديدة لتوليد `module.*` من مصدر واحد.
  - [x] `lib/core/utils/permission_check.dart` — `canCode/canAnyCode/canAllCode` بنفس ترتيب قواعد
    الخادم حرفياً (مدير ⇒ نعم؛ `system.*`؛ الكود الحرفي؛ `module.*`؛ وإلا رفض).
  - [x] `PermissionSnapshot` (`data/models/permission_snapshot_model.dart`) — لقطة الخادم، قراءة
    بمفتاحين (`user_id`/`USER_ID`)، عمود تاريخ فارغ يعود `false` يُفسَّر غياباً، `denied` فارغة،
    و`mergeWith()` تملأ الحقل الغائب فقط.
  - [x] `UserModel` — حقلا `isAdmin` + `permissions` (دمج استجابات `login`/`me`/`biometricLogin`)،
    `userTypeLabel`، و`permissionSet`؛ الأكواد لاتينية فلا تمر على `ArabicEncodingUtils.fix()`.
  - [x] `AuthState` — `permissions/isAdmin/sessionExpiresAt` + `can/canAny/canAll/canSeeSection` +
    `withPermissions()` الكاتب الوحيد للثالوث، و`_parseServerDate` لنص `YYYY-MM-DD HH:MM:SS`.
  - [x] `SecureStorageService` — مفاتيح `ky_user_permissions` و`ky_is_admin` و`ky_session_expires_at`
    مع `savePermissions/getPermissions/saveIsAdmin/getIsAdmin/saveSessionExpiresAt/getSessionExpiresAt`
    و`clearPermissions()`؛ و`clearAll()` تمسح الثلاثة (منح مخزّونة بعد الخروج = واجهة على جلسة ميتة).
  - [x] `AuthRepository.fetchPermissions()` — `GET /auth/permissions` مع `CancelToken`: النجاح يُثبَّت،
    الإلغاء يستعيد الكاش، **ردّ الخادم** (403/401/…) يمسح المنح ويعيد `denied`،تعذر الوصول يبقي الكاش
    لأن الخادم ما زال يرفض كل طلب؛ + `restorePermissions()` لإعادة الإقلاع.
  - [x] `PermissionsNotifier` + `permissionsNotifierProvider` — حالة مزامنة فقط (`isSyncing/hasSynced/
    isStale/lastSyncedAt`) بلا نسخة ثانية من المنح، أرضية 15 ثانية، تحديث عند `resumed`، إلغاء
    الاستدعاء الأقدم، و`refreshNow()` بعد تعديل منح المستخدم نفسه.
  - [x] `PermissionGate` + امتداد `WidgetRef` (`can/canAny/canAll/isSystemAdmin`) — إخفاء افتراضي،
    و`onDenied` للشاشات التي يجب أن تشرح سبب المنع.
- **ما أُنجز — المرحلة 6 (توحيد الأقسام والحجب):**
  - [x] `lib/features/employee_portal/domain/portal_sections.dart` — سجل الأقسام التسعة: معرّف ثابت +
    عنوان + أيقونة + `selectedIcon` + شرط ظهور (`viewCodes`: أي واحد يكفي؛ فارغ = بلا شرط) +
    `showInBottomBar` + `builder` (دوال عليا لأن القائمة `const`).
  - [x] `visiblePortalSections()` — مصدر واحد لاشتقاق القائمة المرئية بالمنطق نفسه.
  - [x] `employee_main_layout.dart` — المخزّن صار **معرّف القسم** لا فهرساً؛ الموضع يُشتق في كل بناء
    ويسقط على أول قسم ظاهر عند سحب صلاحية أثناء الجلسة؛ و`IndexedStack` يبني المرئية فقط (لا شبكة
    لقسم محجوب).
  - [x] `collapsible_side_drawer.dart` — حُذفت قائمته الداخلية (`_menuItems`) وصار يتلقى `sections`.
  - [x] `NoSectionAvailable` — شاشة إرشاد عند صفر أقسام (حماية من `IndexedStack` بلا أطفال).
- **علتان حقيقيتان كشفهما الاختبار الجديد:**
  1. **`NavigationBar` تشترط وجهتين على الأقل** (`destinations.length >= 2`): موظفٌ بقسم واحد في
     الشريط كان يُسقط الاستثناء. الحل: الشريط يغيب تحت وجهتين (`barSections.length < 2 ⇒ null`).
  2. **تجاوز عرض في بطاقة لوحة العملاء** (`customers_dashboard_screen.dart:352`) — حبة النص الفرعي
     كانت تتجاوز البطاقة بـ 42 بكسل على 1280×800؛ صارت `Flexible` + `maxLines: 1` + `ellipsis`.
- **انحراف موثّق عن الخطة (§8.1):** `WidgetsBindingObserver` بدل `AppLifecycleListener` — الأخير ودجت
  `StatefulWidget` ولا يمكن أن يعيش داخل مزود؛ Observer يعطي نفس النتيجة مع تسجيل/إزالة مضمونين في
  `build()`/`ref.onDispose()`، ويتجاهل غياب الـ binding في اختبارات الوحدة.
- **بوابات الجودة:** `flutter analyze` = **No issues found!** · `flutter test` = **44 اختباراً ناجحة**
  (منها `test/ibac_test.dart` الجديد و6 اختبارات حجب في `test/responsive_layout_test.dart`).
- **قراءة Oracle (فقط، بلا كتابة):** `APP_PERMISSIONS` المنشّطة = **93** (مطابقة لنسخة العميل)،
  `APP_USERS_PERMISSIONS` المنشّطة = **1**، و`APP_USERS.IS_ADMIN` موجود.
- **التالي (لم يبدأ):** المرحلة 7 (D3: إغلاق مسارات الأعمال) والمرحلة 8 (واجهات الإدارة الكاملة).

---

## [2026-10-19 02:59:38] المرحلة 7 — إغلاق مسارات الأعمال (القرار D3) · المنفّذ: Qoder Agent

- [x] **الخلفية (`kyApp_API/routes/api.php`)** — كل مسار أعمال صار خلف طبقتين: `auth:sanctum` ثم
  `permission:<code>`. الوحدات: العملاء (6) · جاري العاملين (18 على ثلاث وحدات مستقلة
  `employees`/`cutters`/`tailors`) · الحسابات (12: `view` للقراءة، `create`/`update` للبنود،
  `structure_manage` لهيكل الشجرة، `statement` للكشوف) · العملات (8: `currencies.*` للمفردات و
  `currencies.prices_view`/`prices_manage` للأسعار) · الفواتير (2) · `selectFromTable` بـ `system.*`.
- [x] **السطح العام انخفض إلى 3 مسارات فقط** بت التصميم: `POST /auth/login`،
  `POST /auth/biometric/login`، `GET /hello` (فحص الاتصال الذي تستخدمه شاشة إعدادات الواجهة).
  ستّة مسارات بقيت `auth:sanctum` بلا صلاحية لأنّها ملكية الجلسة نفسها: `logout`, `me`, `user`,
  `auth/permissions`, `biometric/register`, `biometric/revoke` — جعل قراءة المرء لمنحه صلاحيةً كان
  يقفل على مستخدم بلا منح إمكانية معرفة أنه بلا منح.
- [x] **`TableQueryController`** — قائمة رفض جداول (11 جدولاً: اعتمادات/جلسات/بنية داخلية) تُطبَّق
  **قبل** أي استعلام وجود، بـ 403 و`errors.table_name = restricted_table`؛ وتنقيح أعمدة بالمطابقة
  على `PASSWORD`/`DEVICE_TOKEN`/`TOKEN`/`SECRET`/`KEY` لأي جدول مسموح، مع إخراج `redacted_columns`
  في الاستجابة حتى يكون المحذوف معلناً لا صامتاً.
- [x] **`InvoiceController`** — العلة **C5** أغلقت: الغلاف الموحّد (`success`/`message`/`data`/`meta`)
  بدل المصفوفة العارية، و`ArabicEncoding::cleanData()` قبل الإرجاع، وبحث برقم الفواتير أو باسم
  العميل بكلتا الصيغتين، وتصفح يدوي بـ `meta = {total, page, limit, pages}` على وزن `Customer`،
  و`show` يعيد 404 صريحاً بدل `null` عارٍ، وأنواع إرجاع `JsonResponse` معلنة.
- [x] **الاختبارات** — ملف جديد `tests/Feature/BusinessRoutesSealedTest.php` (6): لا مسار عام خارج
  الثلاثة، كل مسار محمي يحمل حارس صلاحيات، عينات 19 فعلاً تردّ 401 بلا جلسة، 14 فعلاً تردّ 403
  بالاسم الصحيح لكل وحدة، المدير يمرّ، والفواتير تُجيب الغلاف الجديد. وتحديث `TableQueryTest`
  (7) ليعكس القفل بدل الافتراض القديم.
- [x] **بوابة الترحيل الآمنة (شرط D3):** لا حاجة لكتابة منح ترحيبية — `APP_USERS` فيه مستخدم واحد
  فقط (`arslan`, `IS_ACTIVATED=1`, `IS_ADMIN=1`)، والمدير يتجاوز جدول المنح، فلا يُطرد مستخدم حقيقي
  عند الإغلاق. **لم يُنفَّذ أي `INSERT`/`UPDATE`/`DELETE` في هذه المرحلة.**
- **بوابات الجودة:** `vendor/bin/pint --dirty` = fixed · `vendor/bin/pest` = **78 اختباراً / 533
  تحقّقاً** ناجحة · `route:list` = **71** (لا مسار جديداً ولا محذوفاً) · `flutter analyze` =
  No issues found! · `flutter test` = 44 ناجحة.
- **التالي (لم يبدأ):** المرحلة 8 — واجهات الإدارة الكاملة (إدارة المستخدمين، الصلاحيات، الجلسات
  النشطة، إعدادات الأمان، سجل النشاط).

---

## [2026-10-19 08:58:40] المرحلة 8 — واجهة الإدارة الكاملة · Qoder Agent

- [x] **الهيكل** — `lib/features/admin/` بـ 36 ملفاً: 7 موديلات كيانات + `AdminResult` و
  `PagedResult` مشتركين، 4 مستودعات Dio، 6 مزوّدين Riverpod (بلا codegen)، 10 شاشات، 9 ودجات،
  و`lib/features/employee_portal/domain/portal_sections.dart` (سجل الأقسام الموحّد، مرحلة 6).
- [x] **لوحة الإدارة** — `ManagementDashboardScreen` بدل الـ placeholder في
  `management_section.dart:15`؛ كل بطاقة داخلها خلف `PermissionGate` بصلاحيتها الخاصة.
- [x] **إدارة المستخدمين (جوهر الطلب)** — `AdminUsersScreen`: بحث بـ debounce 300ms +
  `CancelToken` + فلترة (نوع/حالة/فرع عبر `showAdminFilterSheet`) + فرز + تصفح، والفلترة والفرز
  تُرسل للخادم لا تُشتق محلياً. البطاقة بخمسة أفعال (`UserCardAction`: تعديل/صلاحيات/تعطيل/حذف/
  سجل نشاط)، كل فعل بصلاحية مستقلة، ومنع الأذى عن الذات (`isSelf`) ظاهر.
- [x] **النموذج والمنتقي (D8)** — `UserFormWidget` واحد للإنشاء والتعديل، و
  `PermissionsPickerWidget` مدمج داخله: مجموعات بالأقسام، بحث، «أساسيات القسم» و«تحديد كل
  القسم» و«مسح»، وتظليل ما لا يملكه الممنِح (anti-escalation)، و«تحديد كل القسم» يمنح الأفعال
  الحرفية لا `module.*`.
- [x] **بقية الشاشات** — `AssignPermissionsScreen` · `UserActivityScreen` · `ActiveSessionsScreen`
  (مؤقّت دقيقة واحد للشاشة لا لكل بطاقة) · `SecuritySettingsScreen` (int/bool/string بحدود) ·
  `PermissionsCatalogScreen` · `UserPickerScreen` (منتقي مشترك).
- [x] **الاختبارات** — `test/ibac_test.dart` (20: قواعد الحلّ، سلامة الأكواد، قراءة صفوف أوراكل
  الخام، سجل الأقسام، سلوك المنتقي) + «Admin screens render at both breakpoints» في
  `test/responsive_layout_test.dart` (9 شاشات × 360/1280 = 18 حالة، بمزيفات مستودعات بلا شبكة).
- **البوابات:** `flutter analyze` = No issues found! · `flutter test` = **51 ناجحة / صفر فشل** ·
  الخلفية لم تُمَسّ في هذه المرحلة (لا pint/pest جديدين؛ آخر قياس 78 اختباراً / 533 تحقّقاً).
- **ما يبقى من المرحلة 8:** القبول اليدوي لـ §10 على جهازين (مدير + موظف بمنح جزئية) — يتطلب
  موافقة صريحة على `INSERT`/`UPDATE` في مخطط `ACCOUNTS` الحيّ، ولا يُنفَّذ بلا إذن.

## [2026-10-20 00:45:10] المرحلة 9 — التوثيق والإغلاق النهائي · Qoder Agent

- [x] **إصلاح مسار كتابة العربية (آخر علّة مُتلفة للبيانات)** — `ArabicEncoding::encodeForOracle()`
  كان يربط بايتات CP1256 الخام عبر اتصال `AL32UTF8` فتستبدلها أوراكل بعلامة الاستبدال `0xBF`
  (قياس `DUMP()`: الاسم المركّب من 9 محرفات استقرّ `bf,bf,bf` أي 3 محرفات). حُذف نهائياً، وصار
  `toOracleSearchChars()` المسار الوحيد للكتابة والبحث، وحُوّلت 16 موضعاً:
  `CustomerController` (6) · `AccountController` (4) · `CurrencyController` (6).
- [x] **`SettingsStore`** — قيم `string` تمرّ عبر `toOracleSearchChars()`، والحدّ صار بالمحرف
  (`mb_strlen`) لا بالبايت، فلا تُرفض قيمة عربية طويلة رفضاً ظلماً.
- [x] **تجميد العقد باختبار** — `tests/Unit/ArabicWritePathTest.php` (14 اختباراً / 108 تحقّقاً،
  بلا اتصال أوراكل): الكودبوينت المرتبطة = قائمة بايتات CP1256 حرفياً، لا ربط خام،
  `fixMojibake(toOracleSearchChars(t)) === t`، النصوص ASCII والفارغة وnull لا تُمَسّ،
  و`encodeForOracle()` يبقى محذوفاً.
- [x] **`AGENTS.md` (الجذر)** — حالة IBAC والإدارة، 71 مساراً (3 عامّة / 6 للجلسة / 62 محرساة)،
  جداول IBAC الخمسة وسكربتات `database/oracle/`، سياسة الجلسات وضرورة بقاء `expiration => null`،
  مفاتيح التخزين التسعة، نواة الصلاحيات في العميل وسجل الأقسام الموحّد، قائمة الاختبارات،
  البند **S7** (سقف الكاش 3000 بايت) والبند **C12** (`USER_ID` ≠ `USER_NO`).
- [x] **`kyApp_API/AGENTS.md`** — البنية (11 متحكماً + `EnsurePermission` + 7 أصناف `Support/`)،
  الميزان الأمني بطبقتيه وجرد المسارات، §4 (الظرف، إغلاق `InvoiceController`، شكل `meta` عند
  الإداريين)، §5.1 عقد الكتابة بلا `encodeForOracle`، §5.2 تسلسلات IBAC وشرط التسلسل غير الموصوف
  داخل PL/SQL، سقف الكاش وقيمة DATE الفارغة (`false`)، §6 سياسة الجلسات وIBAC ومنع التصعيد،
  §8 الجداول والسكربتات، §9 أوامر البذر، §10 (11 ملفاً / 92 اختباراً) وسياسة القراءة فقط،
  §12 الحالات المغلقة والجديدة، §14 حالة العمل غير المرتقب، §15 المرجع السريع.
- [x] **التحقق النهائي (قراءة فقط على `ACCOUNTS`)** — 8/8 مُشغِّلات (Triggers) صالحة · `USER_NO` غائب و
  `IS_ADMIN` موجود · الكتالوج 93 والإعدادات 10 والمنح 1 · `session_idle_minutes=240` و
  `session_absolute_days=14` و`session_touch_threshold_minutes=5` · **صفر** اسم عميل يحوي
  `CHR(191)` من أصل 25,406 صفاً (لم تُفسد أي سجلاتٍ العلّة السابقة).
- [x] **البوابات** — `flutter analyze` = No issues found! · `flutter test` = 51 ناجحة ·
  `vendor/bin/pint --dirty` = passed · `php artisan test` = **92 ناجحة / 653 تحقّقاً**.
- **ما يتبقى (موقوف على إذن المستخدم، لا عمل ناقص):** القبول اليدوي لـ §10 على جهازين (يقتضي
  `INSERT`/`UPDATE` في المخطط الحيّ)؛ حواجز إطلاق APK في `android/` (إذن `INTERNET` في
  `AndroidManifest.xml` الرئيسي، `applicationId` حقيقي بدل `com.example.ky_apps`، توقيع فعلي بدل
  debug)؛ والترتيب الصحيح للـ commit — داخل `kyApp_API/` أولاً ثم bump المؤشر في الأب — ولا commit
  بلا طلب صريح.

## [2026-10-20 01:13:30] تتبُعة البوابة: عِلَتا analyze قديمتان في شاشة الدخول/الشعار · Qoder Agent

- [x] **`flutter analyze` لم يكن نظيفاً فعلاً عند أول قياس لهذه المرحلة** (2 مشكلة)، وهي بالضبط ما
  يستلزم الوثيقة لا الصمت: `unused_import` لـ `package:flutter/gestures.dart` في
  `lib/features/auth/presentation/screens/login_screen.dart:1`، و`avoid_unnecessary_containers` على
  غلاف `Container` بلا أي خاصية فعّالة (تنسيقه كان مُعلَّقاً بالكلية) في
  `lib/features/auth/presentation/screens/splash_screen.dart:43`.
- [x] **الإصلاح** — حُذف الاستيراد غير المستخدم، وأُزيل الغلاف فصار `Image.asset` مباشرة بأبعادها
  نفسها (370×300) بلا أي تغيّر بصري، مع تعليق عربي/إنجليزي واحد يشرح لماذا لا غلاف.
- [x] **إعادة القياس** — `flutter analyze` = **No issues found!** · `flutter test` = **51 ناجحة /
  صفر فشل** (لم تتغيّر: الاختبارات لا تتمسّ بشاشة الشعار).
- **الدرس المُستفاد:** لا يُعلَن «البوابات خضراء» بالاعتماد على قياس مرحلة سابقة؛ تُعاد البوابات
  الأربع فعلياً في كل جولة يُكتب فيها أنها خضراء.

## [2026-10-20 04:13:12] إصلاح عِلل الإنتاج الثلاث: إنشاء المستخدم 500 · رموز الجلسات · رموز إعدادات الأمان · Qoder Agent

- [x] **أولاً: فشل إنشاء مستخدم (`POST /api/users` ⇒ 500)** — `prepareGrants()` في
  `UserAdminController` كانت تعيد `[null, null]` عند نجاح المنح، و`store()`/`update()` يختبران
  `$invalid !== []` ثم `return $invalid;`، فأعاد `null` من دالة نوعها `JsonResponse` ⇒ `TypeError`
  على السطر 246 قبل أي `INSERT`. أُصلح العقد: خانة «لا خطأ» صارت `[]` لا `null` (وأُبقيت `null`
  في خانة المنح لحالة «لم تُرسل صلاحيات» في `update`)، مع اختبارين عاكسين عبر `ReflectionMethod`
  في `UsersAdminTest` (نجاح ⇒ `[]` + مُعرِّفات، وأكواد مجهولة ⇒ `JsonResponse` بـ 422).
- [x] **ثانياً: رموز الجلسات النشطة** — `SessionAdminController@index` كان يُصلح الحقول حقلياً داخل
  `shape()` ثم يمرّر الصفحة كلها على `cleanData()` مرة ثانية. صارت `data` ناتج `shape()` مباشرة
  (إصلاح واحد لكل قيمة).
- [x] **ثالثاً: رموز إعدادات الأمان** — `SettingController` كان يُعيد تغليف تسميات
  `SettingsStore::definitions()` المُصلَحة مرة أخرى بـ `cleanData()` في `index()` و`update()`؛ أُزيلت
  الطبقة الزائدة وحُذف استيراد `ArabicEncoding` غير المستخدم. `SettingsStore` يبقى نقطة الإصلاح
  الوحيدة لهذه الحمولة.
- [x] **السبب الجذري — حصانة التكرار في `ArabicEncoding::fixMojibake()`**: نص UTF-8 سليم (يحوي
  عربية U+0600–U+06FF ولا محرفاً في 0x80–0xFF) يُرجع كما هو دون إصلاح. من دونها يقلب الإصلاح
  الثاني بايتات العربية السليمة عبر جدول CP1256 (`موظف` → `ظ…ظˆط¸ظپ`) — وهذا بالضبط ما ظهر في
  الشاشتين. أُضيفت `tests/Unit/ArabicReadPathTest.php` (تشتغل بلا أوراكل) تثبّت: الإصلاح، الثبات
  عند التكرار (فردي وعبر `cleanData`)، واستمرار إصلاح الصفوف المختلطة عربي+تشويه.
- [x] **تحقّق حي قراءةً فقط عبر @oracle** — `USER_NAME_AR` للمستخدم 1 ⇒ «ارسلان» ثابتة عند الإصلاح
  المكرر؛ `NAME_AR` لـ `session_idle_minutes` ⇒ «مهلة خمول الجلسة (بالدقائق)» بنفس الثبات؛
  أعمدة `APP_USERS` الإلزامية (`USER_ID`, `IS_ADMIN` فقط) كلاهما مربوط في إدراج `store()`، فمسار
  الإنشاء سليم بعد إصلاح الإرجاع.
- [x] **البوابات** — `php artisan test` = **114 ناجحة / 759 تحقّقاً** · `vendor/bin/pint --dirty` =
  passed. (العميل Flutter لم يُمَسّ في هذه الجولة.)
- [ ] **الإثبات النهائي لإنشاء المستخدم**: إنشاء مستخدم من واجهة التطبيق، أو بتجربة كتابة مُرجَّعة
  داخل معاملة — عُرضت الثانية فصدّها التنفيذ الآمن لأنها كتابة في القاعدة الحيّة، فتبقى على إذن
  المستخدم الصريح.

---

## مهمة: إدارة إعدادات API الآمنة + التهيئة الديناميكية للتطبيق — 2026-10-20 (المنفّذ: Qoder)

خطة بثلاثة أجزاء: طبقة Oracle/بذر، خلفية Laravel، عميل Flutter. كل الإعدادات النصية/الألوان
في `APP_SETTINGS` القائمة (لا جداول جديدة)، والشعار يُحفظ محلياً على الجهاز فقط.

### الخلفية (Laravel + Oracle) — مكتملة وموثّقة
- [x] **كتالوج الصلاحيات**: وحدة `app_config` جديدة (قبل `system`) — 93←97 كوداً، 17←18 وحدة.
- [x] **فئة دعم `AppConfig.php`**: مصدر وحيد لمفاتيح الهوية/المظهر وقيمها الافتراضية وحمولتها
  العامة (تستثني `api_settings_password` أبداً) + الخطوط المسموحة.
- [x] **متحكم `AppConfigController.php`**: `GET /app-config` (عام)، `PUT /app-config`
  (`app_config.update`)، `POST /app-config/verify-api-password` (عام + `throttle:5,1`)،
  `PUT /app-config/api-password` (`app_config.api_manage`).
- [x] **مسارات `api.php`**: أربع نقاط جديدة؛ `SettingController` يعزل مفاتيح `app_config` عن
  شاشة «إعدادات الأمان» (تصفية في `index`، رفض في `update`).
- [x] **`SettingsStore`**: تمييز `HOT_KEYS` لكاش الأمان + `raw()` لقراءة تجزئة bcrypt بلا إصلاح
  ترميز، حفاظاً على سقف حجم الكاش (ORA-01461).
- [x] **بذر Oracle (02_ibac_seed.php)**: 12 صفاً في `APP_SETTINGS` (شركة/تطبيق/مظهر + كلمة سر
  API مجزّأة bcrypt `IS_LOCKABLE=1`، القيمة `A1.b2.c3.d4`). النتيجة الحيّة: **97 صلاحية / 22 إعداداً**.
- [x] **اختبارات**: `AppConfigTest.php` (9) + تحديث `BusinessRoutesSealedTest`/`IbacCoreTest`
  (97/22)/`PermissionSyncTest` (97/18)/`SecuritySettingsTest`. `php artisan test` أخضر · `pint` نظيف.

### العميل (Flutter) — مكتمل وموثّق
- [x] **الاعتماديات**: `image_picker ^1.1.2` + `path_provider ^2.1.5` (ثم `flutter pub get`).
- [x] **لوحة زمنية `AppPalette` + تفكيك `const`**: الحقول الخمسة في `AppColors` صارت `getters`
  تفوّض إلى `AppPalette`؛ `AppTheme.build()` يبني `ThemeData` من اللوحة والخط المختار. أُزيلت
  `const` من 43 ملفاً (تغيير ميكانيكي) حتى `flutter analyze` = «No issues found!».
- [x] **ميزة `app_config`**: نموذج `AppConfigModel` (snake_case + تحليل hex آمن)، مستودع (شبكة +
  كاش + شعار محلي + تحقّق/تجزئة SHA-256)، مُبلِغ `AppConfigNotifier` (تحميل من الكاش ثم مزامنة،
  حفظ، اختيار شعار، تغيير كلمة سر API).
- [x] **التخزين الآمن**: مفاتيح `ky_app_config` / `ky_app_logo_path` / `ky_api_pw_hash` (تبقى بعد
  `clearAll` وتُمسح في `purgeEverything`).
- [x] **`AppLogo`**: ودجت موحّد (ملف محلي إن وُجد وإلا `assets/logo3.jpg`) استبدل الشعار المثبّت في
  الدخول والبدء.
- [x] **الإقلاع وإعادة التشغيل**: `main()` أصبح async (تهيئة اللوحة من الكاش)، `KyApp` صار
  `ConsumerWidget` يراقب السمة/العنوان، و`RestartWidget` يعيد تركيب الشجرة بعد تغيير الألوان/الخط.
- [x] **بوابة كلمة سر الدخول**: `ApiPasswordDialog` يتحقق من الخادم ثم الاحتياط المحلي قبل فتح
  `/api-settings`. **بوابة الصلاحية بالبوابة**: بطاقة API خلف `app_config.api_manage`، وبطاقة
  تهيئة جديدة خلف `app_config.update` تفتح `AppConfigScreen` (دفع أمرِي).
- [x] **مرآة الصلاحيات**: `permission_codes.dart` أضافت أكواد `app_config.*` + التسميات العربية.
- [x] **اختبارات العميل**: `test/app_config_model_test.dart` (فك/توليد/hex/افتراضيات/copyWith/لوحة).
  `flutter test` = **60 ناجحة** · `flutter analyze` = لا مشاكل.

### ملاحظات أمنية
- كلمة سر API لا تظهر في أي حمولة عامة؛ التحقق عام مُقيّد المعدل يسجّل المحاولات الفاشلة ويعيد
  200 دائماً (يمنع تسريب السبب ويميّز الخطأ عن تعذّر الخادم). الكتابة كلها خلف `auth:sanctum` +
  صلاحية، ومعاملة ذرّية، وسجل تدقيق. الشعار محلي بحت لا يغادر الجهاز.

---

## 2026-10-21 — تقارير الحسابات المالية (Account Financial Reports)

**المهمة:** تنفيذ خطّة كاملة لبناء تقريرين ماليين على غرار تقارير أوراكل القديمة
(`acc_report.RDF` و`TRIAL_BALANCE_REPORT.RDF`) داخل ميزة الحسابات: كشف حساب تفصيلي لرمز
حسابي واحد (CHART_ACC) + كشف مجموعة حسابات جزئية (ميزان مراجعة) مع تقسيم عملة محلية/أجنبية.

**نموذج الذكاء الاصطناعي المنفّذ:** Qoder Agent — خطة `Account_Financial_Reports_1686e067.md`.

### المهام الفرعية (كلها ✓)
- [x] **t1 Backend**: إعادة كتابة `AccountController::getAccountStatement` — مسار `ENTRY_MAIN → ENTRY_SUB → ENTRY_TYPE` (لا يوجد `ACC_TRXN`)، رصيد افتتاحي + رصيد جارٍ لكل سطر، نافذة 15 يوم افتراضية محسوبة من آخر حركة فعلية، ترميز `ArabicEncoding::fixMojibake` على البيان/النوع.
- [x] **t2 Backend**: إضافة `AccountController::getGroupStatement` + مسار `GET /api/accounts/group-statement` خلف `permission:accounts.statement` — تحديد النطاق عبر 4 مستويات (`acc_no`/`acc_sub`/`acc_part`/`group_id`) بأولوية الأعمق، تصنيف محلي/أجنبي عبر `CUR_NO=1` = YR، بدون فترة افتراضية (كل السجل ما لم تُحدَّد).
- [x] **t3 Backend**: تحديث `tests/Feature/BusinessRoutesSealedTest.php` — تغطية المسارين الجديدين، **6 اختبارات / 71 تأكيد** نجحت.
- [x] **t4 Flutter**: إضافة `printing: ^5.13.1` + `pdf: ^3.11.1` إلى `pubspec.yaml` ثم `flutter pub get` (استقرّت على 5.14.3 / 3.11.3).
- [x] **t5 Flutter**: توسيع `chart_account_model.dart` (`AccountTransactionModel` + `entryNo/subEntryNo/entryTypeName`، قراءات dual-case، ملخّص موسّع: `openingBalance/finalBalance/totalDebit/totalCredit/currency/fromDate/toDate/defaulted`)؛ نموذج جديد `account_group_statement_model.dart` (`TrialBalanceRow/TrialBalanceTotals/TrialBalanceReport`).
- [x] **t6 Flutter**: تعديل `fetchAccountStatement` و`fetchGroupStatement` داخل `account_repository.dart` مع `CancelToken`.
- [x] **t7 Flutter**: إعادة بناء `AccountStatementScreen` — ترويسة الشركة بـ`assets/CENTER.JPG`، جدول `Table` بسبعة أعمدة (السند|النوع|تأريخه|البيان|مدين|دائن|الرصيد)، صف الرصيد الافتتاحي، رصيد جارٍ لكل سطر، صندوق الإجماليات + توقيعات + تنويه 15 يوماً، `InteractiveViewer(0.5, 3)` للتكبير، شريط فلاتر قابل للطيّ، أزرار طباعة/تصدير PDF خلف `PermissionGate`.
- [x] **t8 Flutter**: شاشة جديدة `AccountGroupStatementScreen` + `resolveStatementScope()` (دالة نقية بالأولوية groupId>sub>main>account) + بلاطة جديدة في `AccountsDashboardScreen` (ثالثة، أيقونة `account_tree_rounded`).
- [x] **t9 Flutter**: مولّدا PDF عربيان — `account_statement_pdf_builder.dart` (طولي A4، `pw.MultiPage(24)`) و`account_group_statement_pdf_builder.dart` (عرضي `a4.landscape`)، كلاهما يعتمد `report_pdf_fonts.dart` (`PdfGoogleFonts.cairoRegular/cairoBold` مع كاش الحزمة).
- [x] **t10 Testing**: `flutter analyze` = **No issues found!** · `flutter test` = **80 ناجحة** (منها 20 جديدة) · `php artisan route:list --path=api` = 76 مسار · `vendor/bin/pint --dirty` = نظيف · Pest `BusinessRoutesSealedTest` = **6/6 · 71 تأكيد**.
- [x] **t11 Docs**: هذا القسم.

### الاختبارات الجديدة
- `test/features/accounts/group_statement_scope_test.dart` — 8 اختبارات لوحدة `resolveStatementScope` (مستويات/null/أولوية الأعمق/سلسلة المعاملات).
- `test/features/accounts/account_statement_models_test.dart` — قراءات dual-case، تصحيح الترميز CP-1256 (0xDE → ق)، تطبيع عملة فارغة إلى null، تحليل ميزان المراجعة.
- `test/features/accounts/account_group_statement_screen_test.dart` — 3 widget tests (الحالة الفارغة، تبديل الفلاتر، اختيار الحساب الأولى وزرّ الطباعة/التصدير الظاهران).

### قرارات فنية
- **`ACC_TRXN` غير موجود** في `ACCOUNTS` — المسار الحقيقي `ENTRY_MAIN → ENTRY_SUB` مع `ENTRY_TYPE` لكود النوع العربي؛ تم التوثيق في `DBdevloping_history.md`.
- **`SEQ_PRICE` NULL** للحركات المحلية (YR) — التصنيف محلي/أجنبي يعتمد على `CUR_NO = 1` وليس سعر الصرف.
- لا حاجة لإضافة أصول TTF للعربية — الحزمة `printing` تُضمّن Cairo داخل `PdfGoogleFonts`.
- **`pw.Context`** وليس `pw.BuildContext` (typedef `BuildCallback` داخل `pdf` package).
- **`PdfPageFormat.a4.landscape`** getter وليس method.
- الحاشية انتقلت إلى `pw.MultiPage(margin: EdgeInsets.all(24))` لأن `copyWith(marginAll:)` غير متاحة.

### ملاحظات أمنية
- كلا المسارين يحملان `auth:sanctum` + `permission:accounts.statement` — رفض افتراضي بدون صلاحية.
- زرّا الطباعة والتصدير محميّان بـ`PermissionGate` رمزين `accounts.print`/`accounts.export` على العميل؛ الخادم يعيد التحقّق لكل طلب.
- كل نص عربي يمرّ عبر `ArabicEncodingUtils.fix` في النماذج وعبر `ArabicEncoding::fixMojibake` في المتحكم.

---

## [2026-10-21 06:17] دورة حياة الجلسات — حذف فور الانتهاء + خروج قسري فوري

**المطلوب:** (1) الجلسات تتراكم وتظل مسجّلة، (2) لا يُسجَّل خروج المستخدم عند انتهاء جلسته.
**المنفِّذ:** Qoder Agent · **المرجع الزمني:** ساعة القاعدة `SYSDATE` كما أمر المستخدم.

- [x] **توحيد الساعة (أصل المشكلتين معاً):** `SessionPolicy::dbNow()` يزيح ساعة PHP (`UTC`) إلى `SYSDATE` (`+03:00`) بإزاحة تُقاس مرة واحدة في الطلب. قبله: كتابةُ الموعد بـ`now()` تجعل كل جلسة تبدو «منتهية» على شاشة تقارن بـ`SYSDATE`، وكتابةُ `expireTokens` لـ`SYSDATE - 1` تُقرأ في PHP كأنها في المستقبل ~3 ساعات فلا تُرفض الجلسة المنهية أصلاً.
- [x] **حذف الجلسة المنتهية فور رفضها:** `validate()` يمسح التوكن عند انتهاء الخمول وعند تجاوز العمر المطلق عبر `discard()` (بأفضل جهد — الفشل لا يمنع الرفض).
- [x] **كنس شامل `purgeExpired()` بفرعين على ساعة القاعدة:** منتهي الموعد، وقديم بلا موعد مع خمول يتجاوز `session_idle_minutes` (هذا هو التراكم فعلاً: 20 صفاً من سبتمبر/أكتوبر بلا `EXPIRES_AT` تظهر «نشطة» إلى الأبد).
- [x] **أماكن الكنس:** بعد `prime()` في `login` و`biometricLogin`، وفي أول `SessionAdminController::index()`.
- [x] **ترويسة `X-Session-Expires-At`** عبر middleware جديد `AppendSessionExpiry` ملحق بمجموعة `api`، يحمل الموعد الحالي بعد كل تجديد انزلاقي، مع `Access-Control-Expose-Headers` لبناء الويب.
- [x] **العميل — التقاط الموعد:** `AuthInterceptor.onResponse` ← `AuthNotifier.updateSessionDeadline` يحدّث الحالة ويخزّن `ky_session_expires_at`.
- [x] **كلب حراسة محلي:** `Timer.periodic(30s)` **بلا أي طلب شبكة** (أي probe يمدّد الجلسة عند الخادم فيُبطل الخمول) → `forceLogout()` متى تجاوز الموعد وقتُ الجهاز.
- [x] `forceLogout()` صار يمسح التخزين الآمن بنفسه، لأن مسار الحارس لا يمر بـ`ErrorInterceptor`.
- [x] **فحص بداية التطبيق:** جلسة ماتت أثناء إغلاق التطبيق تُغلَق محلياً قبل أي طلب (بدل رسم البوابة ثم إسقاطها).
- [x] **توجيه مركزي:** `KyApp` يراقب `isAuthenticated` (مُصادق ← غير مُصادق) → `appRouter.go('/login')`؛ وأُزيل `context.go('/login')` اليدوي من `employee_main_layout` (مع استيراد `go_router` الذي صار غير مستخدم).
- [x] `minutes_left` في شاشة الجلسات يُقارن بـ`SessionPolicy::dbNow()` لا `now()`.
- [x] **اختبارات:** 4 حالات جديدة في `IbacCoreTest` (ساعة القاعدة = `SYSDATE`، الكنس يمسح الميت ويدع الحيّ، الترويسة موجودة، الترويسة غائبة بلا جلسة/بلا موعد).
- [x] **بوابات الجودة (قيست من جديد لا موروثة):** Pest **127 اختبار / 685 تأشير** ✓ · Pint ✓ · `flutter test` **80** ✓ · `flutter analyze` تحذير واحد **لا علاقة له بالمهمة** (`biometric_login_button.dart:24` — `label` غير مستخدم، داخل ملف يعمله مسار آخر؛ لم يُمَسّ).
- [ ] قرار معلّق للمستخدم: إثبات إنشاء المستخدم من واجهة التطبيق (أو الموافقة على dry-run داخل معاملة rollback) لإغلاق خطأ 500 السابق نهائياً.


---

## 2026-10-21 — إصلاح: انهيار منتقي التاريخ في كشف الحساب المالي (سنة 93422)

**نموذج AI:** Qoder Agent · **الأمر:** «هناك مشكله في عرض كشف حساب مالي قم بحلها».

### السبب الجذري (مُتحقَّق منه بمسبار حي)
1. **خطأ PHP في الخادم** — `AccountController.php:502-503` استخدم `format('YYYY-MM-DD')`. في PHP كل `Y` تُخرِج السنة كاملة، و`M` اسم الشهر، و`D` اسم اليوم — فنتجت `"2025202520252025-MarMar-SatSat"` بدل `"2025-03-16"`. نفس الخطأ كان في `CustomerController.php:446`.
2. **تطبيع Dart على العميل** — `_parseServerDate` حلّل السلسلة المشوهة إلى `DateTime(0, 1, 2025202520252025)` التي يطبّعها Dart إلى **سنة 93422** (تم إثبات ذلك بمسبار `dart run` أعاد `93422-12-11 01:12:58`).
3. **انهيار الـ assertion** — `showDatePicker(initialDate: 93422, lastDate: 2030)` → `'initialDate == null || !initialDate.isAfter(lastDate)'` ينكسر.

### الإصلاحات
- **الخادم** (`AccountController` + `CustomerController`): `format('Y-m-d')` + تحقق نطاق (سنة 1900–2100، شهر 1–12، يوم 1–31) داخل `parseStatementDateToIso`/`parseDateToIso` — أي تاريخ مشوه من عميل قديم يُرفض ويُعامَل كغائب.
- **العميل**: ملف مشترك جديد `lib/features/accounts/presentation/utils/statement_date_parser.dart`:
  - `parseStatementServerDate()` — يرفض أي تاريخ خارج 1900–2100 (يُرجع null)؛ التعبئة التلقائية للفلاتر لا تحدث إلا إذا نجح تحليل التاريخين معاً.
  - `clampToDatePickerRange()` — حارس صلب يقصّ initialDate داخل [firstDate, lastDate] قبل `showDatePicker` في كلتا الشاشتين.
- **اختبارات انحدار**: `test/features/accounts/statement_date_parser_test.dart` — 11 اختباراً تغطي السلسلة المشوهة الحرفية، السنة 93422، صفوف Oracle الفاسدة (سنة 0025)، والتقصّص.

### اكتشاف قاعدة البيانات (قراءة فقط)
- `ENTRY_MAIN` يحتوي صفوفاً بتواريخ فاسدة (سنة 0025) — الحارس الجديد يتجاهلها بدل تسميم الفلاتر.
- استعلامات الفحص موثّقة في `db_commends.md` (بلا أي كتابة).

### التحقق
- `flutter analyze` = نظيف (تحذير واحد قديم غير متصل) · `flutter test` = **91/91** (كانت 80) · `php -l` = سليم · `pint --dirty` = PASS · `php artisan test` = **127 ناجحاً (683 تأكيداً)**.

---

## [2026-10-21 07:32] — تتمة آلية الجلسات (توثيق + اختبار) — Qoder Agent
- [x] `kyApp_API/tests/Feature/ActiveSessionsTest.php`: فحص بنية الصفّ لكل صف موجود + تخطٍّ لطيف عند جدول توكنات فارغ (لم يعد يعتمد على جلسة حيّة كـ fixture)
- [x] `AGENTS.md` (جذر): سطر الجلسات في §14 · §8 (127 اختباراً + حالات `IbacCoreTest` + استثناء `PERSONAL_ACCESS_TOKENS`)
- [x] `kyApp_API/AGENTS.md`: §2 وسطان + مسؤوليات `SessionPolicy` · §3 ترويسة `X-Session-Expires-At` · §6 دورة حياة الجلسة (`dbNow`/`discard`/`purgeExpired`) · §10 الاختبارات · §12 مصيدة C12 وتحديث S5 · §14 حالة الالتزام · §15 مرجع سريع
- [x] `db_commends.md` + `DBdevloping_history.md`: حصر `PERSONAL_ACCESS_TOKENS` (قراءة فقط) وجدول الحالة 22 → 1 → 0
- [x] بوابات الجودة: Pest 127 (125 ناجح + 2 متخطٍّ، 669 تأكيداً) · `pint --dirty` PASS · `flutter test` 91/91 · `flutter analyze` تحذير واحد خارج النطاق (ملف لمهمة أخرى)
- [ ] قرار معلّق للمستخدم: إثبات إصلاح إنشاء المستخدم إما بإنشاء مستخدم من الواجهة أو بالموافقة على تجربة محمية بـ rollback



---

## 2026-10-21 — كلمة سر إعدادات API: تحقّق محلي بالكامل (إصلاح تعذّر الاتصال)
## 2026-10-21 — API-settings password: fully local verification (offline-unreachable fix)

**المشكلة / Problem:** كان التحقق من كلمة سر إعدادات API يحاول الخادم أولاً
(`POST /app-config/verify-api-password`). عند تغيّر رابط الـ API أو انقطاعه تتعذّر
الوصول إليه (connection timeout)، فلا يستطيع المستخدم فتح شاشة إعدادات API لإصلاح
الرابط — وهو تناقض منطقي. كان يظهر خطأ RenderFlex overflow أيضاً في الحوار.
Verification hit the server first; when the URL changed or the server was down the call
timed out, so the user could not open the API-settings screen to fix the URL. A dialog
RenderFlex overflow was reported too.

**الحل / Fix (offline-unreachable):**
- [x] جعل التحقق محلياً بالكامل داخل التطبيق — لا يلمس الشبكة إطلاقاً.
      Fully local verification — never touches the network.
- [x] كلمة السر الافتراضية المضمّنة `A1.b2.c3.d4`؛ تُستخدم ما لم يُخزَّن تجزئة مخصّصة.
      Embedded default `A1.b2.c3.d4`, used until a custom hash is stored.
- [x] تغيير الكلمة يحفظ تجزئة SHA-256 مملّحة محلياً في `flutter_secure_storage` فقط.
      Password change stores a salted SHA-256 hash locally only.
- [x] إزالة ثوابت المسارين `appConfigVerifyApiPassword`/`appConfigApiPassword` من العميل.
      Removed the two endpoint constants from the client.
- [x] إصلاح الفيضان: `SingleChildScrollView` حول محتوى `ApiPasswordDialog`.
      Overflow fixed with a scrollable dialog body.

**الملفات / Files (client only — no DB, no backend route removed):**
`api_constants.dart` · `app_config_repository.dart` · `app_config_notifier.dart` ·
`api_password_dialog.dart`.

**التحقق / Verification:** `flutter analyze` نظيف (تحذير واحد سابق غير متعلق) ·
`flutter test` app_config + api_config ناجح.

---

## 2026-10-21 — كشف حساب مجموعة حسابات جزئية (ميزان المراجعة) — تأكيد اكتمال
## 2026-10-21 — Sub-group accounts statement (trial balance) — status confirmed

**المتطلب / Requirement:** خيارات تحديد القسم/المجموعة أربعة (حساب رئيسي – فرعي –
جزئي – مجموعات الحساب الجزئي) + فترة من/إلى تاريخ، مطابق لـ `TRIAL_BALANCE_REPORT.RDF`
والقالب مطابق لـ `TRIAL_BALANCE_REPORT.pdf`.

**الحالة / Status:** مُنفَّذ بالكامل سابقاً ولا تغيير مطلوب — تم التحقّق فقط.
Already fully implemented; verified only.
- Backend: `AccountController::getGroupStatement` — حلّ نطاق رباعي المستويات + فصل
  عملة محلية (CUR_NO=1) عن أجنبية + فترة اختيارية داخل شرط الربط.
  Route `GET /accounts/group-statement` behind `permission:accounts.statement`, sealed test.
- Flutter: `AccountGroupStatementScreen` (4 قوائم متسلسلة + من/إلى تاريخ + طباعة/PDF)،
  `AccountGroupStatementReportTable` (رأس مزدوج محلي/أجنبي)،
  `buildAccountGroupStatementPdf` (A4 عرضي، خط Cairo)، مطابق للقالب.

---

## 2026-10-21 — ترويسة التقارير المالية + هوية الشركة من الإعدادات
## 2026-10-21 — Financial report letterheads + company identity from app config

**المتطلب / Requirement:** ترويسة «كشف حساب مالي» و«كشف حساب مجموعة حسابات جزئية»
تعرض اسم الشركة وعنوانها ومعلومات تواصلها كما في `acc_report.pdf` /
`TRIAL_BALANCE_REPORT.pdf`.

- [x] `utils/report_letterhead_info.dart` — `ReportLetterheadInfo` + `fromConfig()` +
      `contactLine` (`العنوان | هاتف: … | الموقع: …` مع تجاهل الفارغ).
      Letterhead identity read from `AppConfigModel` (`APP_SETTINGS.company_*`).
- [x] `widgets/report_letterhead_branding.dart` — `ReportLetterheadBranding(info:)` عمود
      موسّط يُلفّ العنوان الطويل بدل أن يفيض عند تكبير الخط 1.25×.
      Centered column so a long address wraps instead of overflowing.
- [x] `utils/report_pdf_letterhead.dart` — `reportPdfLetterheadBranding(info)` مقابلها في PDF.
      The PDF counterpart of the same block, fed by the same object.
- [x] الشاشة (`account_statement_screen`) والمكوّن (`AccountStatementLetterhead`) والمولّدان
      (`buildAccountStatementPdf` / `buildAccountGroupStatementPdf`) كلها تمرّر `letterhead`
      إجبارياً — فما يُرى وما يُطبع من مصدر واحد.
      One required `letterhead` argument through widget, screen and both PDF builders.
- [x] الاختبارات: `report_letterhead_info_test.dart` (4) + اختبار ترويسة في
      `account_statement_report_widgets_test.dart`؛ وتضييق `find.textContaining('من تاريخ')`
      إلى `'من تاريخ:'` لأن تنويه التذييل كان يلتقطه معه (نفس العبارة في مكانين).
      Narrowed the pre-existing finder that matched the footer disclaimer as well.

**التحقق / Verification:** `flutter analyze` نظيف (عدا تحذير سابق غير متعلق) ·
`flutter test` **100/100**.

**ملاحظة / Note:** لا حقل «صندوق بريدي» في `APP_SETTINGS`؛ القالب يطبعه لكن الإعدادات
لا تحمله — يُضاف مفتاح `company_po_box` إن طُلب.

---

## 2026-10-21 — ترويسة التقارير: شريط ثلاثي الأعمدة (تصحيح المطلوب)
## 2026-10-21 — Report letterhead: three-column band (design correction)

**المتطلب / Requirement:** «من جهة اليمين اسم الشركة وتحتها العنوان وأرقام التواصل،
المنتصف شعار الشركة، اليسار اسم الشركة والعنوان وأرقام التواصل بالإنجليزي — كما في الصورة».
Right = Arabic name + address + contact numbers, center = logo, left = the same in English.

- [x] `utils/report_letterhead_info.dart` — حقول إنجليزية (`companyNameEn`, `addressEn`)،
      سطور كل عمود عبر `arabicLines` / `englishLines`، نص الترويسة المطبوعة كافتراضي
      (`kFallbackNameAr/En`, `kFallbackAddressAr/En`, `kFallbackPhone`) عندما يكون
      الإعداد فارغاً، و`toArabicIndicDigits()` لإظهار الهاتف بالأرقام الهندية (٠١٢٣…).
      English fields + per-column line lists + printed-header fallbacks + Arabic-Indic digits.
- [x] `app_config_model.dart` — `companyNameEn` / `companyAddressEn` مع قراءة بفتحتي
      حالة (`company_name_en` / `COMPANY_NAME_EN`) وافتراضي `ALkabodi` وتمريرهما في
      `toJsonForUpdate()` (الخادم يتجاهل المفاتيح غير المعروفة حالياً — بلا أي كسر للحفظ).
- [x] `widgets/report_letterhead_branding.dart` — استبدال العمود الموسّط المرفوض بشريط
      `Row` من ثلاثة `Expanded` بنِسَب (5 : 4 : 5): الكتلة العربية يميناً (بداية RTL)،
      الشعار في المنتصف، الكتلة الإنجليزية يساراً باتجاه LTR صريح. الأحجام مشتقة من
      العرض المتاح داخل `LayoutBuilder` فلا فيضان على 320px عند تكبير خط 1.25×.
- [x] `utils/report_pdf_letterhead.dart` — `reportPdfLetterheadBranding(info, logo:)`
      يرسم نفس الأعمدة الثلاثة في PDF، مع `loadPdfLetterheadLogo()` الذي يحوّل أصل
      الشعار إلى `pw.MemoryImage` ويعيد null بأمان عند تعذّر القراءة.
- [x] إزالة الشعار المكرّر من `AccountStatementLetterhead` ومن ترويسة
      `AccountGroupStatementScreen`؛ وكلاهما يمرّر الشعار المحمّل إلى مولّد الـ PDF.
- [x] لا تغيير في قاعدة البيانات، ولا مسارات API جديدة، ولا جدول جديد.
      No DB change, no new route, no new table.

**اختبارات / Tests:** `report_letterhead_info_test.dart` (8) يغطي الأسطر والافتراضيات
وتحويل الأرقام؛ `account_statement_report_widgets_test.dart` += اختبار موقع الأعمدة
(`arabicName.dx > logoLeft.dx > englishName.dx`) واختبارا عدم الفيضان على 360px و320px.

**التحقق / Verification:** `flutter analyze` نظيف (تحذير واحد سابق غير متعلق في
`biometric_login_button.dart:24`) · `flutter test` ناجح 105/105.


---

### [2026-10-21 11:07] — حقلا الشركة بالإنجليزية في القاعدة + تعميم الترويسة
**النموذج المنفّذ:** Qoder Agent
**المتطلب / Requirement:** «قم باضافه حقلي company_name_en, company_address_en الى جدول APP_SETTINGS
وقم باضافه حقلين لهما في شاشه الاعدادات وقم بتطبيق ترويسه التقرير لتقرير العملاء والعاملين ايضا
customer_statement_screen and the worker statements وقم بالاتصال بقاعده البيانات باستخدام موصل oracledb mcp».

- [x] **القاعدة (oracledb MCP):** إدراج صفَّي `company_name_en` / `company_address_en` في
      `ACCOUNTS.APP_SETTINGS` (id 23/24 من `TRG_APP_SETTINGS`، `SORT_ORDER` 115/125، `VALUE_TYPE=string`،
      `IS_LOCKABLE=0`) + `COMMIT`؛ التحقّق بـ`SELECT` و`DUMP` بايتياً و`LOCAL_TRANSACTION_ID='NONE'`.
- [x] **الخادم:** `AppConfig` — ثابتان + `DEFAULTS` + `WRITABLE_KEYS`؛ `AppConfigController::textLimit()`
      = 300 للعنوانين؛ `IbacCoreTest` عدّ التعريفات 22 → 24.
- [x] **نقل الترويسة إلى `lib/core`:** `report_letterhead_info.dart` / `report_pdf_letterhead.dart` /
      `report_letterhead_branding.dart` + إعادة توجيه مستورِدي الـ accounts والاختبار (`directives_ordering`).
- [x] **شاشة الإعدادات:** حقلا «اسم الشركة بالإنجليزية» و«العنوان بالإنجليزية» مع `ltr` للإدخال،
      وربطهما بالتهيئة/التخلّص/الحفظ عبر `AppConfigModelBuild.fromFields`.
- [x] **تطبيق الترويسة:** `customer_statement_screen` و`worker_statement_screen` يستهلكان
      `ReportLetterheadBranding(info:)` الموصول بالإعداد، بدل الكتل المرسومة يدوياً.
- [x] تنظيف: إزالة `now`/`timestamp` الميّت من `account_statement_report_table.dart`.

**التحقق / Verification:** `flutter analyze` نظيف (تحذير سابق واحد) · `flutter test` **108/108** ·
`php -l` سليم · `pint --dirty` **PASS** · `php artisan test` **127/683**.
**لم يَمَسّ:** لا أعمدة/جداول جديدة، لا `UPDATE`/`DELETE`، لا مسارات API جديدة.


---

### [2026-10-22 09:30] — توحيد ترويسة/تذييل PDF + إصلاح انعكاس أعمدة الجدول + طباعة/تصدير تقارير العملاء والعاملين
**النموذج المنفّذ:** Qoder Agent
**المطلب / Requirement:** آ«أولاً: عند طباعة/تصدير التقرير PDF ينعكس اتجاه جدول التقرير وهذا غلط، وكذلك في كشف حسابات المجموعات الجزئية: عند اختيار حساب جزئي وعدم اختيار مجموعة لا يجلب التقرير. ثانياً: بدلاً من إنشاء ترويسة وتذييل في كل تقرير، أنشئ ترويسة وتذييلين موحّدين لكل التقارير، وتأكد من وجود (الترويسة/التذييل الرسمية – خيارات الطباعة والتصدير – التكبير والتصغير) في كل التقاريرآ».

- [x] **انعكاس أعمدة الجدول (RTL):** `pw.Table` يرسم أطفاله يسار→يمين دائماً بغض النظر عن `textDirection`؛ تم عكس قوائم `TableRow.children` وإعادة ترتيب `columnWidths` في `account_statement_pdf_builder.dart` (7 أعمدة) و`account_group_statement_pdf_builder.dart` (8 أعمدة) عبر مساعد `reversedCells()` الموحد — فتصبح السند يميناً والرصيد يساراً مطابقةً للشاشة.
- [x] **إصلاح عدم تحميل كشف المجموعة:** في `account_group_statement_screen.dart` كان `_onGroupChanged(null)` لا يستدعي `_loadReport()`؛ الآن يُعاد التحميل دائماً ليعود التقرير لمستوى الحساب الجزئي عند إفراغ القائمة.
- [x] **وحدة PDF موحّدة:** ملف جديد `lib/core/utils/report_pdf_page.dart` يوفّر `buildReportPdfHeader` / `buildReportPdfFooter` / `reversedCells` / `pdfTh` / `pdfTd` / `pdfDateRangeRow` / `pdfSignatures` / `ReportPdfColors`؛ ونُقل `report_pdf_fonts.dart` إلى `lib/core/utils`.
- [x] **إعادة هيكلة البنّائين:** `account_statement_pdf_builder.dart` و`account_group_statement_pdf_builder.dart` يستدعيان الترويسة/التذييل الموحّدين (حُذف `_letterhead`/`_pageFooter` المكرّرة).
- [x] **بنّاءان جديدان:** `customer_statement_pdf_builder.dart` و`worker_statement_pdf_builder.dart` بنفس الجدول السباعي والترويسة/التذييل الموحّدين.
- [x] **ربط الطباعة/التصدير + التكبير:** `customer_statement_screen.dart` و`worker_statement_screen.dart` — زرا طباعة/تصدير PDF داخل `PermissionGate` (customers.print/export للملف العميل، accounts.print/export للعامل لعدم وجود أكواد خاصة)، واستبدال نافذة التصدير الوهمية للعامل باستدعاءات حقيقية، ولفّ المحتوى بـ `InteractiveViewer(minScale:0.5, maxScale:3)`.

**التحقق / Verification:** `flutter analyze` (workers/customers/accounts/core) = لا مشاكل · `flutter test` **108/108**.
**لم يَمَسّ:** لا تغييرات قاعدة بيانات، لا حزم جديدة (`printing`/`pdf` موجودان)، لا تعديل ملف الخطة.


---

### [2026-10-22 14:20] — إصلاح نطاق "الحساب الجزئي" في كشف المجموعات + اختيار افتراضي للحساب الرئيسي/الفرعي
**النموذج المنفّذ:** Qoder Agent
**المطلب / Requirement:** آ«عند اختيار حساب جزئي وعدم اختيار مجموعة لا يُجلب التقرير ويظهر خطأ «لا توجد حسابات في هذا النطاق» رغم وجود حسابات؛ وكذلك أريد اختياراً افتراضياً لأول حساب في «حساب رئيسي» و«حساب فرعي» مبدئياً مع إمكانية تغييرهآ».

- [x] **جذر المشكلة (خادم/Oracle):** في `AccountController::getGroupStatement` كان مرشّح المستويات الثلاثة `TRUNC(c.ACC_NO / 10000) = :acc_part` (وفي فرعي/رئيسي صيغة `IN` نفسها). أرقام `CHART_ACC` طولها 8 أو 9 خانات، والحساب الجزئي هو **أول 3 خانات** (مثال `12310000`→123 عملاء، `123110001`→123). القسمة على 10000 تعطي بادئة من 4 خانات فلا تطابق أبداً معرّف الجزء ثلاثي الخانات ⇒ نتيجة فارغة.
- [x] **الإصلاح:** استبدال الصيغة بـ `SUBSTR(TO_CHAR(c.ACC_NO), 1, 3)` (مستقلة عن طول الرقم) في الفروع الثلاثة: `sub` (جزئي) و`main` (فرعي) و`account` (رئيسي). تحقّق بالـ MCP: `SUBSTR(...,1,3) IN (ACC_PART)` يطابق **20954/20954**؛ الفرع `sub` للجزء 123 يُرجع 20469 صفاً (كان صفراً قبل الإصلاح).
- [x] **العميل (Flutter):** في `account_group_statement_screen.dart` إضافة اختيار افتراضي مرّة واحدة عبر `_maybeApplyDefaults(...)`: أول حساب رئيسي ثم أول حساب فرعي تابعه، ثم جلب التقرير لمستوى الفرعي مرّة واحدة (`addPostFrameCallback` لتفادي setState أثناء build).
- [x] **الاختبارات:** تحديث `account_group_statement_screen_test.dart` ليعكس السلوك الجديد (تحميل تلقائي بدل الحالة الفارغة، وفتح القائمة عبر `DropdownButtonFormField`).

**التحقق / Verification:** `flutter analyze` (الشاشة) = لا مشاكل · `php -l` = سليم · `flutter test` **108/108**.
**لم يَمَسّ:** لا DDL/INSERT/DELETE على القاعدة (تحقق للقراءة فقط عبر oracledb MCP)، لا مسارات API جديدة، لا تعديل منطق حلّ النطاق في `group_statement_scope.dart` (كان سليماً).

---

### [2026-10-22 17:10] — الواجهة الرئيسية: لوحة اختصارات مربّعة قابلة للتخصيص
**النموذج المنفّذ:** AutoClaw Agent
**المطلب / Requirement:** «خطة متكاملة لتطوير الواجهة الرئيسية وإضافة اختصارات إليها من جميع
الأقسام وإمكانية تخصيص الاختصارات التي تظهر، على شكل بطائق مربعة مرتبة ومنظمة وبتصميم احترافي».

- [x] **المجال:** `home_shortcut.dart` (هدف مختوم: قسم/شاشة/مسار/تدفّق) + `home_shortcut_catalog.dart`
      (30 بطاقة) + `home_shortcut_flows.dart` (كشف حساب عميل، تعديل عميل، سجل نشاط).
- [x] **الحالة والتخزين:** `HomeLayout` (opt-out للافتراضي وopt-in لغيره، حارس `user_id`)، مستودع
      بلا شبكة، `HomeLayoutNotifier` (حفظ متفائل + سلسلة كتابة + عدّاد نسخة يمنع دهس نقرة المستخدم
      بقراءة تخزين متأخرة)، ومفتاح `ky_home_layout` في `SecureStorageService`.
- [x] **الشبكة:** أعمدة محسوبة بحد أدنى 150dp، نسبة مربّعة 1:1، بطاقة بأيقونة وعنوان من سطرين
      وسطر قسم وشارة «قيد التطوير»، وتحويم/ضغط متحركان.
- [x] **الرئيسية:** ترويسة (تحية + تاريخ عربي يدوي بلا `intl`)، شرائح تصفية الأقسام، الحالات الخمس
      (تحميل/نجاح/تصفية فارغة/الكل مخفي/لا منح)، وتلميح أول تشغيل.
- [x] **التخصيص:** شاشة كاملة بتبويبين وبحث وإعادة ترتيب واستعادة افتراضي، وورقة خيارات بالضغط المطوّل.
- [x] **الهيكل:** `PortalSectionScope` + `_openSection` بفحص صلاحية، وإصلاح مؤشر الشريط السفلي حين
      يكون القسم المفتوح خارج الشريط، واستخراج عناوين الأقسام إلى ثوابت.
- [x] **الاختبارات:** 3 ملفات جديدة (39 اختبارًا) + 7 حالات في `responsive_layout_test.dart`.

**التحقق / Verification:** `flutter analyze` = التحذيران القائمان مسبقًا فقط · `flutter test`
**153 ناجحًا / 3 فاشلة** (الفاشلة الثلاث سابقة للتعديل) · `dart format` على الملفات الجديدة.
**لم يَمَسّ:** لا حزم جديدة، لا مسار GoRouter جديد، لا تغيير في الخلفية أو القاعدة.


## [2026-10-22] تقرير "كشف حساب عمل القصاص / الخياط" (مطابقة FOR_CUTTER_TAILOR / FOR_TAILOR)
- [x] **الباك-إند:** إضافة `fetchWorkReport` في `WorkerController` (جدول `CUTTER_FROM_CALC`/`TAILOR_FROM_CALC` فقط، بدون الكشف المالي) + مفتاحا `work_*` في مصفوفة `TABLES` + غلفا `workReportCutter/workReportTailor`.
- [x] **المسارات:** `GET /workers/cutters/{id}/work-report` و`GET /workers/tailors/{id}/work-report` خلف `permission:cutters.statement`/`tailors.statement` (لا صلاحيات جديدة).
- [x] **الفلاتر:** موديل `worker_work_report_model.dart` + `fetchWorkReport` بالمستودع + `worker_work_report_provider.dart` (CancelToken) + شاشة `worker_work_report_screen.dart` + جدول `worker_work_report_table.dart` + مولّد PDF موحّد.
- [x] **الميزات:** ترويسة/تذييل رسميان من `APP_SETTINGS`، طباعة/تصدير PDF، تكبير/تصغير (InteractiveViewer 0.5–3)، فلاتر تاريخ جاهزة (اليوم/أسبوع/شهر/سنة/كل) + إخفاء الفلتر + زر التحديث. الفترة الافتراضية = اليوم.
- [x] **الأعمدة:** التاريخ | الموديل | العدد | السعر | الإجمالي + سطرا "إجــمالي العدد" و"الإجمــالي".
- [x] **الربط:** زر "كشف عمل" بقائمتي القصاصين/الخياطين يفتح الشاشة (الموظفين يبقى SnackBar).
**التحقق:** `php -l` سليم · `route:list` يظهر المسارين · Pest `BusinessRoutesSealedTest` 6/6 (77 assertion) · `flutter analyze` نظيف للملفات الجديدة · `flutter test` workers 5/5 · تحقق MCP: أسطر CUTTER_FROM_CALC/TAILOR_FROM_CALC مطابقة لسطور الـ PDF.


## [2026-10-22] تعديل: الفترة الافتراضية لكشف عمل القصاص/الخياط = آخر يوم يوجد به سجل
- [x] **الباك-إند:** في `fetchWorkReport` عند عدم إرسال تواريخ أصبح يبحث أولاً عن `MAX(تاريخ العمل)` لربط `ACC_NO` للعامل (استعلام `SELECT TO_CHAR(MAX(...))` عبر نفس JOIN المعتمد) ويعيّن ذلك اليوم (من = إلى) كفترة افتراضية؛ وإن لا توجد سجلات نهائياً يعود لتاريخ اليوم كقيمة آمنة.
- [x] **الفلاتر:** `worker_work_report_screen.dart` لم يعد يملأ التاریخين بالیوم في `initState` (يتركهما فارغين لیحدّدهما الخادم) ثم یعكس الفترة العائدة من `summary.from_date/to_date` على حقول الفلتر عبر `ref.listen` عند أوّل تحميل (`_awaitingDefaultDates` + `_parseDmy`).
**التحقق:** `php -l` سليم · Pint PASS · MCP: قصاص ACC_NO=12910001 وخیاط 12910004 یُرجعان 16/08/2026 مع أسطر فعلیة · `flutter analyze` نظیف · `flutter test` workers 5/5.


## [2026-10-22] إصلاح: تجاوز عرض شاشة كشف العمل + تحذير CORS على طلبات GET
- [x] **الـOverflow:** `RenderFlex overflowed by 26 pixels on the right` كان من تذييل التوقيعات (3 × عرض ثابت 110 = 330px > ~304px على الهاتف). أصبحت الخانات `Expanded` مرنة مع فاصل `double.infinity` ونص وسط قابل للالتفاف.
- [x] **الاستجابة/CORS:** كانت headers الأساسية فرض `Content-Type: application/json` حتى على GET بلا جسم فتثير preflight (OPTIONS). أُزيلت من `BaseOptions` وأُضيف معترض ضبط Content-Type فقط للطلبات ذات الجسم (GET/HEAD تبقى بسيطة).
**التحقق:** `flutter analyze lib/core/network lib/features/workers` نظیف · `flutter test` workers 5/5 · الاستجابة نفسها سليمة (success:true، فترة 16/08/2026 بأسطرها).


## [2026-10-22] تقرير جديد: كشف عمل مجموعة (Group Work Report)
- [x] **الباك-إند:** إضافة groupWorkReportCutter() و groupWorkReportTailor() + etchGroupWorkReport() في WorkerController — يجلب كل أسطر CUTTER_FROM_CALC / TAILOR_FROM_CALC بفترة زمنية (افتراضي آخر 7 أيام) مع اسم العامل.
- [x] **المسارات:** GET /workers/cutters/group-work-report (cutters.statement) + GET /workers/tailors/group-work-report (tailors.statement).
- [x] **الفلاتر-العميل:** موديل +ريبو+بروفايدر+شاشة+جدول 6 أعمدة (الاسم|التاريخ|الموديل|العدد|السعر|الإجمالي) + PDF builder landscape.
- [x] **التنقل:** بطاقة رابعة في WorkersDashboardScreen + اختصار workers.group_work في home_shortcut_catalog.
- [x] **اختبار BusinessRoutesSealedTest:** مساران جديدان في قوائم 401/403.
**التحقق:** route:list يظهر المسارين · Pint PASS · flutter analyze lib/features/workers نظيف · home_shortcut_catalog نظيف.

---

### [2026-10-22 20:30] — كشف المجموعات الجزئية: إضافة الحساب الجزئي كخيار افتراضي (ثالث)
**النموذج المنفّذ:** Qoder Agent
**المطلب / Requirement:** «الوضع الحالي يتم اختيار اول حساب رئيسي وثاني حساب فرعي كخيارات اوليه؛ اريد ان يتم اختيار اول حساب جزئي كخيار اولي ايضا».

- [x] **إصلاح خلل سابق:** كان اختيار أول حساب فرعي مكتوباً `list[1].accSub` (يختار **الثاني** ويرمي `RangeError` عند عنصر واحد) — صُحّح إلى `list.first.accSub`. هذا يفسّر ملاحظة المستخدم «ثاني حساب فرعي».
- [x] **مرحلة ثالثة للاختيار الافتراضي:** توسيع `_maybeApplyDefaults(accountsAsync, accMainAsync, accSubAsync)` بعلم `_autoSelectedAccPart` وثالث سلسلة: أول رئيسي → أول فرعي → **أول جزئي**، ثم جلب التقرير لمستوى الجزئي مرّة واحدة عبر `addPostFrameCallback`.
- [x] **معالجات الحدود:** إن غابت الحسابات الفرعية (firstSub=null) يُجلب التقرير فوراً عند مستوى المتاح؛ وكذلك عند غياب الأجزاء يُجلب عند مستوى الفرعي.
- [x] **الاختبارات:** تحديث اسم/تعليق الاختبار الأول ليشمل `main/sub/part`.
- [x] **إصلاح عائد لمهمة سابقة (غير متعلق):** `home_catalog_test.dart` كان يتوقع 34 اختصاراً بينما الكتالوج صار 35 بعد إضافة `workers.group_work` (مهمة تقرير عمل المجموعة)؛ زُودّا العدد إلى 35 وتسمية الاختبارَين. `flutter test` الكامل = **176/176**.

**التحقق / Verification:** `flutter analyze` (الشاشة) = لا مشاكل · `flutter test test/features/accounts/account_group_statement_screen_test.dart` = **+3 ناجح**.
**لم يَمَسّ:** لا تغيير خادم/قاعدة بيانات (السلوك ضمن حدود الإصلاح المسبوق للـ SUBSTR)، لا حزم جديدة، لا مسارات API.


## [2026-10-22 09:15] اصلاح: تجميع كشف عمل مجموعة لكل (عامل + موديل)
- [x] Backend: GROUP BY worker+style, SUM qty/amount, drop per-row date
- [x] Model: remove date field
- [x] Table widget: 5 columns + total-row valueColumn
- [x] PDF builder: 5 columns RTL
- [x] Screen doc + tests updated
- [x] Verify MCP: 24→10 rows, totals 236/71050 unchanged

---

### [2026-10-22 08:55] — إعادة تصميم البطاقات + خيارات العرض + استكمال الاختصارات
**النموذج المنفّذ:** AutoClaw Agent
**المطلب / Requirement:** «البطاقات غير مرتبة وغير جميلة — أصلحها، وأضف خيارات لحجم البطاقات
وعددها في الصف، وراجع كل الأقسام وأضف الاختصارات الناقصة مثل كشف حساب مجموعة حسابات جزئية».

- [x] **البطاقة:** تعبئة متدرّجة بلون القسم + فاصل لوني + حدّ ملوّن + ظلّ متحرّك + صندوق أيقونة
      بحدّ داخلي + ضغط 0.97.
- [x] **الترويسة:** بطاقة ترحيب متدرّجة بزر «تخصيص» نصّي/أيقوني حسب العرض.
- [x] **تبويب «العرض»:** حجم البطاقة (صغير/متوسط/كبير) وعدد البطاقات في الصف (تلقائي/2..6)
      مع معاينة حيّة وسقف مقروئية 104dp.
- [x] **النموذج نسخة 2:** `size` + `cols` مع ترقية بلوب النسخة 1 بدل إهماله.
- [x] **الكتالوج 30 ⇒ 38:** كشف مجموعة حسابات جزئية، كشف تحليلي مفصل، تعديل حساب (منتقي)،
      إضافة/تعديل مستخدم، منح الصلاحيات، إضافة موظف/قصاص/خياط.
- [x] **الاختبارات:** 63 اختبارًا للميزة (26 نموذجًا + 15 كتالوج + 10 مزوّد + 12 ودجت).

**التحقق / Verification:** `flutter analyze` (ملفات الميزة والقشرة) = **No issues found!** ·
`flutter test` للميزة = **63/63**. المجموعة الكاملة تعثّرت لاحقًا داخل ملفات عمل متوازٍ آخر
(`worker_group_work_report_*`) لا داخل هذه الميزة.

## [2026-10-22 09:44] طھط­ط³ظٹظ†: ط¯ظ…ط¬ ط§ط³ظ… ط§ظ„ط¹ط§ظ…ظ„ ط±ط£ط³ظٹط§ظ‹ ظپظٹ ظƒط´ظپ ط¹ظ…ظ„ ظ…ط¬ظ…ظˆط¹ط©
- [x] Rewrite table widget for rowspan-style merged name (IntrinsicHeight+Row)
- [x] PDF: print name once per group, blank on following rows
- [x] Widget tests (3) + analyze + full workers suite 14/14

## [2026-10-22 10:30] إصلاح وظبط شامل لكل التقارير (توحيد الترويسة/التذييل/مقاس A4 وإصلاح تضارب الياء في الطباعة)
- [x] **R1 إصلاح تضارب حرف الياء في PDF فقط (حل داخل الكود):** helper جديد
      `lib/core/utils/report_pdf_arabic.dart` يوظّف مُشكِّل العربية الداخلي
      (`pdfArabic` + `kPdfShapedTextDirection=ltr`) لتشكيل الكلمات (قطري/حجازي/الشميري)
      إلى صور اتصالّية بترتيب مرئي قبل العرض، فتزول التصادمات. تم تطبيقه مركزياً في
      `report_pdf_page.dart` (عنوان/تذييل/خلايا/تواريخ/توقيعات) و`report_pdf_letterhead.dart`
      وفي النصوص العربية المضمّنة داخل كل مولّدات الـ PDF الستة.
- [x] **R2 توحيد الترويسة (عرض/طباعة/تصدير):** يمين=اسم عربي (محاذاة يمين)، وسط=شعار،
      يسار=اسم إنجليزي (محاذاة يسار)؛ تعديل `_pdfInfoColumn` من center إلى right/left وتوحيد
      نسب الأعمدة إلى 6:3:6 لمطابقة الشاشة.
- [x] **R3 تذييل التوقيعات على كل كشف (عرض/طباعة/تصدير):** widget مشترك
      `report_signature_footer.dart` (ثلاث خانات + إشعار 15 يوماً بنفس نص الـ PDF) أُضيف لكل
      الشاشات، وإضافة `pdfSignatures()` إلى مولّد كشف المجموعة (كان ناقصاً).
- [x] **R4 توحيد مقاس A4 على الشاشة:** widget مشترك `report_a4_sheet.dart` يرسم صفحة A4 كاملة
      بنسبة صحيحة (طولي/عرضي) مع تثبيت التذييل أسفل الورقة؛ اعتمده كل التقارير السبعة.
- [x] **R5 كشف حساب تحليلي مفصل:** مولّد PDF كامل `account_statement_detail_pdf_builder.dart`
      + ربط الطباعة/التصدير الحقيقيين (كان Stub) خلف `PermissionGate`، وتغليفه على الشاشة بـ
      `ReportA4Sheet` + `ReportSignatureFooter`.
- [x] **اختبارات:** `test/core/report_a4_sheet_test.dart` (3) + الإبقاء على `report_pdf_arabic_test.dart`
      وسلسلة workers خضراء. **تحقق:** `flutter analyze` (الملفات المعدّلة) = No issues found! ·
      `flutter test test/core test/features/workers` = 28/28 All tests passed!

---

### [2026-10-22 09:40] — إصلاح خيارات العرض + تصميم البطاقات (نسخة 3)
**النموذج المنفّذ:** AutoClaw Agent
**المطلب / Requirement:** «عدد البطاقات في الصف لا يعمل، وحجم البطاقة لا يغيّر إلا الأيقونة،
والبطاقات وفت والألوان باهتة وغير منسّقة».

- [x] **جذر الأعمدة:** سقف المقروئية كان 104dp فيُقيَّد كل اختيار إلى عمودين على الهاتف — صار 72dp
      مع وضع مصغّر داخل البطاقة.
- [x] **جذر الحجم:** أُضيفت نسبة لكل حجم (1.22 صغير / 1.12 متوسط / 1.0 كبير) فتغيّر البطاقةُ
      ارتفاعها ومحتواها لا أيقونتها فقط.
- [x] **التصميم:** بطاقة بيضاء موحّدة + أيقونة صلبة كبيرة + محاذاة علوية (خط أيقونات واحد) +
      حذف سطر القسم المكرّر + مقاسات مشتقّة من عرض البطاقة + ميزانية ارتفاع تمنع التجاوز.
- [x] **التحقق البصري:** لقطات PNG بخط عربي حقيقي عبر `test/home_visual_test.dart` (مُعلَّق
      افتراضيًا، يُشغَّل بـ `KY_VISUAL=1`) في `test/goldens/`.
- [x] **اختبارات جديدة:** الأعمدة المثبّتة تُغيّر الشبكة، نسبة البطاقة تتغيّر مع الحجم، السقف
      الجديد للأعمدة، ولا تجاوز عند 1.25 أو 4 أعمدة.

**التحقق / Verification:** `flutter analyze` = **No issues found!** · `flutter test` للميزة
**94/94** · المجموعة الكاملة **194 ناجحًا / 0 فاشلة / 4 مُعلَّقة**.

---

### [2026-10-22 11:20] — إصلاح انتكاسات التقارير الثلاثة
**النموذج المنفّذ:** Qoder Agent
**المطلب / Requirement:** «اتجاه الكلمات ينعكس عند الطباعة/التصدير في كل التقارير؛ شاشة
التقرير صارت صغيرة وتذييلها مجمّد (A4 مطلوب في المخرجات لا الشاشة)؛ كشف مجموعة عمل
القصاصين يتجاوز المساحة (RenderFlex 63px)».

- [x] **R1 اتجاه PDF:** `pdfArabic = convert(text).split(' ').reversed.join(' ')` + عرض بـ `ltr`
      لإنتاج ترتيب مرئي RTL صحيح دون عكس مزدوج.
- [x] **R2 حجم الشاشة:** إعادة كتابة `ReportA4Sheet` إلى بطاقة تملأ العرض حتى سقف وبارتفاع
      المحتوى الطبيعي، والتذييل بعد المتن؛ A4 بقي في مخرجات الطباعة/التصدير فقط.
- [x] **تغليف الشاشات:** تحويل `Padding` → `SingleChildScrollView` في 7 شاشات تقارير، وإضافة
      `shrinkWrap + NeverScrollableScrollPhysics` لقائمة الكشف التحليلي.
- [x] **اختبارات:** إعادة كتابة `report_a4_sheet_test.dart` (تحجّم بالمحتوى) + اختبار عكس ترتيب
      الكلمات في `report_pdf_arabic_test.dart`.

**التحقق / Verification:** `flutter analyze` (core+accounts+customers+workers) = **No issues found!** ·
`flutter test test/features/workers test/core` = **31/31 All tests passed!** · لا تغيير Backend/SQL/DDL.

---

### [2026-10-22 10:05] — توسيط محتوى البطاقات
- [x] استبدال المحاذاة العلوية بتوسيط عمودي للكتلة كاملة.
- [x] صندوق عنوان ثابت بسطرين + حجز سطر القسم عند وجود نصّ فقط.
- [x] +2dp لصناديق النصّ لتفادي انطباق العنوان إلى سطر واحد.
- [x] اختبار توازن: |منتصف الكتلة − منتصف البطاقة| < 6dp.

**التحقق:** `flutter analyze` = No issues found! · `flutter test` **198 ناجحًا / 0 فاشلة / 5 معلّقة**.


---

### [2026-10-23 10:30] — قسم جديد: «الخدمات والمزودين» (مزودون/رسائل SMS/واتساب/إعدادات/مهام)
**النموذج المنفّذ:** Qoder Agent
**المطلب / Requirement:** إنشاء قسم في بوابة الموظف يغطي خمس وظائف فوق جداول أوراكل الإرثية
(`PROVIDERS`/`PROVIDERS_DTL`/`SERVICES`/`CORP`/`MSG_QUEUE`/`MSG_ARCHIVE`/`W_MSG_QUEUE`/`W_MSG_ARCHIVE`)
وحزم `*_TAPI` و`DBMS_SCHEDULER`، بصلاحيات IBAC دقيقة «لكل قسم ولكل عملية»، والإرسال عبر الطابور فقط.

**المرحلة 0 — كتالوج الصلاحيات:**
- [x] خمس وحدات جديدة في `PermissionCatalog.php` (`services`/`providers`/`sms`/`whatsapp`/`jobs`) = 30 كودًا → الكتالوج **127**؛ توسيع `humanize()`.
- [x] بثّ الكتالوج عبر `02_ibac_seed.php` (idempotent، بلا DDL).
- [x] مرآة العميل `permission_codes.dart`: ثوابت `Perm.*` + `allPermissionCodes` + `permModuleOrder/Labels` + `permActionLabels`.
- [x] تحديث `IbacCoreTest.php:54` العدد 97 → **127**.

**المرحلة 1 — الخلفية Laravel (`App\Http\Controllers\Services`):**
- [x] `ProviderController` (CRUD + toggle + اشتراكات PROVIDERS_DTL)؛ توليد معرّف `NVL(MAX,0)+1`؛ أقنعة `***` للاعتبارات وكشف خلف `providers.reveal_credentials` موثّق في `ActivityLogger`.
- [x] `MessageChannelController` مجردة + `SmsController`/`WhatsappController` (فلاتر حالة في `WHERE`، Projection للمعاينة، enqueue فقط بـ `IS_SENT='N'`).
- [x] `ServiceConfigController` (CORP singleton UPDATE + SERVICES)؛ `JobController` عبر `DBMS_SCHEDULER`.
- [x] مسارات `api.php` كلها خلف `auth:sanctum` + `permission:<code>`.

**المرحلة 2 — الأمامية Flutter (`lib/features/services/`):**
- [x] 7 نماذج + 7 مستودعات (Dio) + مزوّدي Riverpod (إهالة 300ms + حارس تسابق + CancelToken).
- [x] أدوات `message_status_segments`/`credential_field` + 11 شاشة (لوحة/مزودون/سجلات/تحرير/إعدادات/مهام) بحالاتها الأربع.

**المرحلة 3 — تسجيل القسم:**
- [x] `PortalSectionTitles.services` + حالة `of()`؛ تسجيل `PortalSection(id:'services', viewCodes: [5])` خارج الشريط السفلي؛ `ServicesSection` رقيق فوق اللوحة؛ بطاقات الرئيسية الستّ `defaultOn:false` و`services.section` يعكس `viewCodes` حرفيًا.

**المرحلة 4 — الاختبارات:**
- [x] Dart: `test/features/services/` (نماذج موجيباك/أرقام كنص/مفاتيح مزدوجة، مستودع بمحوّل وهمي، مُزوِّد بإهالة وحارس تسابق) = **19 ناجحًا**.
- [x] Pest: `ServicesSectionTest.php` (401 جلسة، 403 لكل عملية بالاسم، فصل كشف الاعتبارات، غلاف + أقنعة) = **6 ناجحًا**.

**التحقق / Verification:** `flutter analyze lib/features/services lib/features/employee_portal lib/features/home` = **No issues found!** ·
بوابة الاختبارات (`home_catalog`/`ibac`/`home_notifier`/`responsive_layout`) = **89 ناجحًا** ·
`vendor/bin/pint --dirty` = **passed** · `php artisan route:list --path=api` يُظهر كل مسارات القسم محروسة ·
`php artisan test --filter=ServicesSectionTest` = **6 passed**. (الانهيارات الوحيدة في مجموعة
الاختبارات الكاملة تقع في `account_group_statement_screen_test.dart` (خطأ `list[1]` دون فحص طول)
وهي سابقة لهذا العمل ومُثبتة عند HEAD بتخزين تعديلاتنا المؤقت — لا علاقة لها بقسم الخدمات.)

---

## إصلاح خلل عرض قسم «الخدمات والمزودين» — 2026-10-23 07:32 (منفذ: Qoder agent)

**الجذر:** الخادم (yajra-oci8) يُرجع أسماء الأعمدة بحروف صغيرة snake_case (`provider_id`)،
بينما كانت موديلات القسم تقرأ camelCase/UPPERCASE فقط → بيانات فارغة في كل الشاشات.

- [x] **الموديلات (7):** provider/provider_subscription/message/oracle_job/job_run/corp/service → قراءة `UPPER ?? lower_snake` مطابقةً لـ `CustomerModel`.
- [x] **Backend:** `MessageChannelController::index` عند `status=all` كان يقرأ `['ID']` فينهار 500 («Undefined array key "ID"») → قراءة `id` احتياطياً `ID`.
- [x] **Backend:** `ProviderController::toggle` كان يقرأ `['STATUS']` → قراءة `status` أولًا.
- [x] **UI:** إعادة تصميم بلاطات اللوحة (ارتفاع ثابت محسوب + تخطيط أفقي مدمج، بلا تجاوز)، وإصلاح تجاوز ورقة تفاصيل الرسالة (تمرير محّدود الارتفاع)، وجعل الاشتراكات مفهومة (اسم الخدمة + قائمة منسدلة بدل رقم خام).
- [x] **تحديث اختبار النموذج:** اختبار camelCase البالي أعيد توجيهه إلى snake_case الحقيقي (كان يفترض العقد الخاطئ نفسه).
- [ ] **تشغيلي:** يُنشر إصلاح الـ API إلى `ky.alx.luxe` ليختفي انهيار تبويب «الكل» قبل إعادة النشر.

---

## تعديل/حذف الرسائل المنتظرة + ترتيب الأحدث أولاً + توضيح الخدمات — 2026-10-23 08:10 (منفذ: Qoder agent)

- [x] **تعديل/حذف الرسائل:** واجهة ورقة تفاصيل الرسالة صارت تستقبل القناة (`channel`) وتعرض زرَّي
      «تعديل» و«حذف» للرسائل المنتظرة فقط (`IS_SENT='N'`/في الطابور)، خلف صلاحيتَي `sms.update`/`sms.delete`
      و`whatsapp.update`/`whatsapp.delete`. نموذج تحرير داخلي (نص/رقم/عميل) + تأكيد حذف.
- [x] **المستودع:** إضافة `MessageRepository::update` (PUT) و`MessagesNotifier::updateMessage/deleteMessage`
      مع إعادة جلب السجل بعد نجاح الكتابة.
- [x] **الترتيب الأحدث أولاً:** فرز دفاعي في العميل على `created_at` ثم `id` داخل `fetchMessages`،
      وتحديث الخادم `MessageChannelController::index` لترتيب `CREATED_AT DESC, ID DESC` (فردي ومدمج).
- [x] **قاموس الخدمات:** إثراء بطاقات SERVICES لتعرض رقم الخدمة (شارة) + الاسم + النوع بدل الاسم وحده.
- [x] **حقول إعدادات الرسائل:** مصدر البيانات سليم (الخادم يُرجع `corp`/`services` في الجذر والموديلات تقرأ
      snake_case)؛ ظهورُها فارغًا كان من بناءٍ قديم قبل إصلاح الموديلات — تظهر بعد إعادة البناء/النشر.
- [x] **التحقق:** flutter analyze = No issues found! · flutter test (services+home_catalog+ibac) = 54 ناجحًا ·
      pint = passed · Pest ServicesSectionTest = 6 passed.
- [ ] **تشغيلي:** ما زال يلزم نشر تعديلات الـ API (الترتيب + إصلاح `status=all`) على `ky.alx.luxe` وإعادة بناء التطبيق.

---

## تحليل: التطبيق يفتح على «الإعدادات» وتختفي كل الأقسام بعد الخروج/الترك فترة — 2026-10-23 22:12 (منفذ: Qoder agent)

**الحالة:** تشخيص فقط — لم يُنفَّذ أي تعديل كود بعد؛ الخطة معتمدة على خمس مراحل بالأسفل.

**السبب الجذري (P0):** `permissionsNotifierProvider` معرَّف في `lib/features/auth/presentation/providers/permissions_notifier.dart`
ولا يُستهلك في أي ملف بالمشروع (بحث شامل: نتيجة واحدة = السطر الذي يعرّفه). لذلك `PermissionsNotifier.build()` لا يعمل
أبداً، فـ:
1. `GET /auth/permissions` لا يُستدعى أبداً ⇒ `_persistPermissions()` لا يكتب `ky_user_permissions` / `ky_is_admin` ⇒ مفاتيح IBAC فارغة دائماً.
2. مراقب دورة الحياة (`WidgetsBindingObserver` + تحديث عند `resumed`) معطّل بالكامل، رغم أن تصميم IBAC يعتمد عليه لسحب/إضافة المنح أثناء الجلسة.
3. تسجيل الدخول (`AuthRepository.login` / `biometricLogin`) يحفظ التوكن و`ky_user_data` فقط؛ المنح تُطبَّق في الذاكرة وحدها
   (`withPermissions(_snapshotFrom(user))`) فلا أثر لها على القرص.

**تسلسل الحدوث:** توكن صالح على القرص → إقلاع بارد (خروج يدوي/قتل أندرويد للعملية في الخلفية) → `checkAuthStatus()`
يجد `isLoggedIn()==true` → `restorePermissions()` يرجع لقطة فارغة → `isAuthenticated=true` مع `permissions={}` و `isAdmin=false`
→ `visiblePortalSections()` يُرجع قسم «الإعدادات» وحده (حقل `viewCodes` فارغ = بلا شرط ظهور) → `EmployeeMainLayout._indexOfVisible()`
يسقط على الفهرس 0 = الإعدادات. لذلك يبقى الشريط العلوي يقول «متصل» واسم الموظف بينما الأقسام كلها مختفية.
«ترك التطبيق مفتوحاً فترة» هو نفس المسار: أندرويد يقتل العملية فالعودة إقلاع بارد.

**ثغرات مُفاقِمة (P1):**
- [ ] `fetchPermissions()` يُمسح الكاش عند أي رد غير متوقع: `body['success'] != true` أو `data` ليس خريطة ⇒ `_storage.clearPermissions()`
      + لقطة `denied` مع توكن صالح = نفس حالة «الإعدادات فقط»، ولا شيء يعيد تعبئتها (بسبب P0).
- [ ] `ErrorInterceptor` يحوّل الطلب الملغى إلى رد 200 بـ `success:false, cancelled:true` ⇒ `CancelToken.isCancel` لا يعمل
      ⇒ يُمسح التخزين رغم أن الـ notifier يتجاهل النتيجة في الذاكرة (حماية للذاكرة لا للقرص).
- [ ] `_persistPermissions(denied)` يُستدعى في مسار `data` غير الصالح فيكتب قائمة فارغة فوق كاش سليم.
- [ ] `NoSectionAvailable` لا يمكن الوصول إليها أبداً (الإعدادات بلا شرط ظهور يضمن قائمة غير فارغة) ⇒ لا شاشة شرح ولا زر إعادة محاولة.
- [ ] `assign_permissions_screen` لا يستدعي `refreshNow()` بعد تعديل منح المستخدم نفسه (الدالة معرّفة بلا مستدعٍ).
- [ ] `_parseServerDate()` يعامل نص أوراكل المحلي (+03:00) كوقت الجهاز، وانحراف الساعة/المنطقة يطرد المستخدم عند أول نبضة حارس.

**خطة الإصلاح المعتمدة (لم تُنفَّذ):**
- [ ] **مرحلة 1 — تشغيل الدورة:** حفظ المنح عند الدخول (`_persistPermissions`)، واستدعاء `refresh()`/`refreshNow()` بعد استعادة
      الجلسة في `checkAuthStatus()` عندما تكون اللقطة المستعادة فارغة، واستهلاك `permissionsNotifierProvider` في `EmployeeMainLayout`.
- [ ] **مرحلة 2 — تحصين الفشل:** التفريق بين إنكار مؤكد من الخادم (401) والفشل العابر (5xx/شبكة/إلغاء/جسم غير متوقع)؛
      الفشل العابر لا يمسح القرص ولا يلمس `sessionExpiresAt`، وقراءة `cancelled:true` قبل فحص `success`.
- [ ] **مرحلة 3 — شبكة أمان مرئية:** شاشة/شريط «جلسة حيّة بلا صلاحيات مُحمّلة» مع زر إعادة الجلب بدل السقوط الصامت للإعدادات،
      و`refreshNow()` بعد حفظ منح المستخدم نفسه.
- [ ] **مرحلة 4 — تحصين الحارس الزمني:** مقارنة الموعد بإزاحة زمنية نسبية بدل مطابقة ساعتين مختلفتين، وسماح لتجاوز بسيط قبل الطرد.
- [ ] **مرحلة 5 — الاختبارات والتحقق:** اختبار إعادة الاستعادة بعد إقلاع بارد + اختبار عدم الإمحاء عند 5xx/الإلغاء +
      `flutter analyze` = No issues found! و `flutter test`.

---

## تنفيذ: إصلاح «السقوط على الإعدادات واختفاء الأقسام» — المراحل 1–5 كاملة — 2026-10-23 22:40 (منفذ: Qoder agent)

**الحالة:** منفَّذ بالكامل. البوابة لا تسقط على «الإعدادات» بعد اليوم؛ النتيجة إما منح صالحة، أو
شاشة إرشاد صريحة بمخرجَيها، أو إنهاء الجلسة إلى شاشة الدخول وفق سياسة الفشل المعتمَدة.

- [x] **مرحلة 1 — دورة حياة الصلاحيات:** حفظ المنح عند الدخول (`login`/`me`) وجلب
      `GET /auth/permissions` بعد استعادة الجلسة، مع استهلاك `permissionsNotifierProvider` أخيراً
      (كان معرَّفاً وغير مستهلَك = كود ميّت لا ينفّذ الجلب ولا يُلصق مراقب دورة الحياة).
- [x] **مرحلة 2 — تحصين الجلب وسياسة الفشل:** `fetchPermissions` يميّز الإلغاء (CancelToken) عن
      الفشل الحقيقي؛ وبلا لقطة صالحة تُنهى الجلسة إلى الدخول بدل واجهة نصف-حيّة بتوكنٍ حيّ.
- [x] **مرحلة 3 — شبكة أمان مرئية:** `NoSectionAvailable` بعنوان وسبب وزر «إعادة محاولة تحميل
      الصلاحيات» بدل الصمت على «الإعدادات» (القسم الوحيد غير المشروط)، و`refreshNow()` بعد حفظ
      منح المستخدم نفسه في `assign_permissions_screen.dart`.
- [x] **مرحلة 4 — حارس الساعة:** ملف جديد `lib/core/utils/session_clock.dart` يترجم موعد الخادم
      (`X-Session-Expires-At`، بلا علامة منطقة) إلى ساعة الجهاز عبر إزاحة `X-Server-Now` النسبية؛
      لا طرد مبكر عند اختلاف الساعتين، ويتصرّف تصرّفاً تراجعيّاً آمناً مع خادم لا يرسل الترويسة بعد.
- [x] **مرحلة 5 — الاختبارات:** `test/session_expiry_fix_test.dart` (SessionClock + أربع حالات
      ودجت لشبكة الأمان) وتصحيح اختباري التدفق اللذين كانا يقومان على السقوط القديم للإعدادات.

**التحقق:** `flutter analyze` — لا أخطاء في أي ملف مُصلَح (بقيت 3 تحذيرات سابقة غير متعلقة:
`analysis_options.yaml`، `biometric_login_button.dart`، تسمية متغيّر في اختبار العاملين).
`flutter test` — **222 ناجحًا / 5 متخطّاة / 3 إخفاقات**. الإخفاقات الثلاثة سابقة لهذا الإصلاح في
`account_group_statement_screen_test.dart` (السطر `list[1]` عند قائمة بحساب واحد)، وقد أُثبت ذلك
بـ `git stash` على `lib/` فاستمرّت بالفشل، وهي خارج نطاق هذه المهمة.

---

## 2026-10-24 — إخفاء صفحة Laravel الترحيبية عن عنوان الخادم

- [x] تغيير مسار `/` في `routes/web.php` من `view('welcome')` إلى `response('', 204)`.
- [x] حذف `resources/views/welcome.blade.php`.
- [x] التأكد أن فحص الاتصال `/api/hello` (api.php) لم يتأثر.

---

## تعديل سلوك (بناءً على طلب المستخدم): بلا شاشة تنبيه — الخروج الصامت إلى الدخول — 2026-10-24 10:15 (منفذ: Qoder agent)

**الطلب:** «لا أريد أن تظهر شاشة تنبيه بعدم وجود صلاحيات؛ أريد توجيه المستخدم لشاشة تسجيل الدخول
مباشرةً بدون أي تحذير.»

**ما تغيّر عن المرحلة 3 السابقة:** بدلاً من رسم `NoSectionAvailable` (شاشة الإرشاد/إعادة المحاولة)
عند جلسة حيّة بلا أي منح لموظف غير مدير، صار المسار:

- **لم تُحسم اللقطة بعد** (جارٍ الجلب أو أول إطار قبل الرد): انتظار محايد بمؤشر تحميل فقط —
  لا تنبيه، ولا طرد لجلسةٍ منحُها على وشك الوصول.
- **حسم الخادم: لا منح لإطلاق** (غير مدير): إنهاء الجلسة بـ `forceLogout(silent: true)` فيسمع
  `KyApp` سقوط «مُصادق» ويوجّه إلى `/login` بلا أي رسالة على شاشة الدخول.
- ضابط «مرة واحدة» `_noGrantsRedirectScheduled` يمنع تكرار الخروج عند كل إعادة بناء.

**الملفات:** `auth_notifier.dart` (وسم `silent` في `forceLogout` ⇒ `errorMessage = null`)،
`employee_main_layout.dart` (استبدال فرع شاشة الإرشاد بانتظار محايد + توجيه صامت).

**الاختبارات:** `test/session_expiry_fix_test.dart` أُعيدت كتابته ليطابق السلوك الجديد (خروج صامت
مرة واحدة، انتظار محايد عند عدم الحسم، لا أثر لـ `NoSectionAvailable` في هذا المسار).
`flutter analyze` لا أخطاء في ملفات التعديل · `flutter test` = 223 ناجحًا / 5 متخطّاة / 3 إخفاقات
سابقة غير متعلقة (`account_group_statement`).

---

## تعديل سلوك (بناءً على طلب المستخدم): بلا شاشة تنبيه — الخروج الصامت إلى الدخول — 2026-10-24 10:15 (منفذ: Qoder agent)

**الطلب:** «لا أريد أن تظهر شاشة تنبيه بعدم وجود صلاحيات؛ أريد توجيه المستخدم لشاشة تسجيل الدخول
مباشرةً بدون أي تحذير.»

**ما تغيّر عن المرحلة 3 السابقة:** بدلاً من رسم `NoSectionAvailable` (شاشة الإرشاد/إعادة المحاولة)
عند جلسة حيّة بلا أي منح لموظف غير مدير، صار المسار:

- **لم تُحسم اللقطة بعد** (جارٍ الجلب أو أول إطار قبل الرد): انتظار محايد بمؤشر تحميل فقط —
  لا تنبيه، ولا طرد لجلسةٍ منحُها على وشك الوصول.
- **حسم الخادم: لا منح لإطلاق** (غير مدير): إنهاء الجلسة بـ `forceLogout(silent: true)` فيسمع
  `KyApp` سقوط «مُصادق» ويوجّه إلى `/login` بلا أي رسالة على شاشة الدخول.
- ضابط «مرة واحدة» `_noGrantsRedirectScheduled` يمنع تكرار الخروج عند كل إعادة بناء.

**الملفات:** `auth_notifier.dart` (وسم `silent` في `forceLogout` ⇒ `errorMessage = null`)،
`employee_main_layout.dart` (استبدال فرع شاشة الإرشاد بانتظار محايد + توجيه صامت).

**الاختبارات:** `test/session_expiry_fix_test.dart` أُعيدت كتابته ليطابق السلوك الجديد (خروج صامت
مرة واحدة، انتظار محايد عند عدم الحسم، لا أثر لـ `NoSectionAvailable` في هذا المسار).
`flutter analyze` لا أخطاء في ملفات التعديل · `flutter test` = 223 ناجحًا / 5 متخطّاة / 3 إخفاقات
سابقة غير متعلقة (`account_group_statement`).


## [2026-10-24 01:55] الإصدار الأول APK جاهز للنشر — توقيع حقيقي + معرّف نهائي + حواجز الإطلاق · Qoder Agent

**المهمة:** «قم بعمل الاصدار الاول للتطبيق بصيغه APK ويكون جاهز للنشر ومع التوقيع الرقمي وكل مايلزم»

- [x] **مفتاح التوقيع** — `android/ky_release.jks` (alias `ky_apps`، RSA-2048، صلاحية 10٬000 يوم حتى
  2054، DN=`CN=Al-Kaboodi Tailoring...`)؛ البصمة SHA-256‏ `811E477C…DADA5D0F`. بياناته في
  `android/key.properties` — وكلاهما خارج git (`.gitignore` الخاص بـ android كان يغطيهما مسبقاً).
- [x] **معرّف التطبيق النهائي** — `com.alkaboudy.app` (بإملاء المستخدم) بدل `com.example.ky_apps`
  في namespace وapplicationId، مع نقل `MainActivity.kt` إلى الحزمة الجديدة وحذف القديمة.
- [x] **ربط التوقيع في Gradle** — `signingConfigs.create("release")` قارئاً `key.properties`
  (مع تراجع إلى debug إذا غاب الملف حتى لا ينكسر بناء أي جهاز آخر)، وتفعيل
  `isMinifyEnabled`/`isShrinkResources` ‏(R8) مع `proguard-rules.pro` جديد.
- [x] **أذن `INTERNET` في Manifest الرئيسي** — كانت debug-only؛ أضيفت `usesCleartextTraffic="true"`
  لأن عنوان API يُدخل وقت التشغيل (LAN host:port) فلا تصلح قائمة بيضاء ثابتة — موثّق بتعليق.
- [x] **عقبتا بناء تم إصلاحهما:** أسماء Kotlin DSL الجديدة `isMinifyEnabled` (وليس `minifyEnabled`)؛
  و`-dontwarn com.google.android.play.core.**` لأن تغليف Flutter يشير إلى Play Core بلا مكوّنات مؤجّلة.
- [x] **البناء والتحقق** — `flutter build apk --release --split-per-abi` + universal:
  arm64-v8a ‏31.8MB · armeabi-v7a ‏29.9MB · x86_64 ‏33.7MB · universal 87.2MB.
  `apksigner verify` ✓ موقع V2 بالشهادة أعلاه، و`aapt2 dump` يؤكد
  `package=com.alkaboudy.app versionName=1.0.0 versionCode=2001 label=الكبودي minSdk=23`
  (versionCode=2001 هو اشتقاق flutter-tools القياسي لـ `1.0.0+1`).
- [x] **الحزمة النهائية** — `release_artifacts/v1.0.0+1/` (4 ملفات APK بإسماء نظيفة + `mapping.txt`
  لفك تشويش الانهيارات مستقبلاً)؛ أُضيف `release_artifacts/` إلى `.gitignore` الجذر.
- [x] **البوابات** — `flutter analyze` = 3 تحذيرات سابقة غير متعلقة (لا جديدة) ·
  `flutter test` = 222 ناجحًا / 5 متخطّاة / 4 إخفاقات: 3 منها `account_group_statement` (موثقة سابقاً)
  ورابع `api_config_test` **بيئي** — الجهاز يخدم الآن على `192.168.0.9` بينما ثابت الاختبار
  `192.168.0.11`؛ لا علاقة له بتعديلات Android (لم تُمسّ أي ملفات Dart).
- **تنبيهات للنشر:** لا تضيع `ky_release.jks` — بدونه يستحيل تحديث التطبيق المنشور؛ انسخه هو
  و`key.properties` و`mapping.txt` إلى مكان آمن خارج الجهاز. Google Play يتطلب AAB وليس APK —
  إن استُهدف المتجر لاحقاً: `flutter build appbundle --release` بنفس المفتاح.


## [2026-10-24 02:12] توثيق: دليل البناء والتوقيع والإصدارات الكامل · Qoder Agent

**المهمة:** «اعطني شرح مفصل وكامل لكيفية عمل البناء مع التوقيع بطريقة آمنة + كيفية عمل
الإصدارات الجديدة وتحديثه + احفظ الشرح في ملف نصي بالمشروع»

- [x] **الملف:** `android_release_guide.md` (جديد في جذر المشروع، ~310 سطر، عربي مع
  المصطلحات الإنجليزية) — خمسة أجزاء:
  1. آلية التوقيع الآمنة: لماذا، المفردات (jks/alias/بصمة SHA-256)، الملفات الثلاثة
     ومواضعها من git، شرح تدفق Gradle سطراً بسطراً (قراءة key.properties → R8 → التوقيع
     → fallback debug)، سبب المسار المطلق، أوامر `apksigner`/`aapt2` الإلزامية.
  2. الترقيم: `version:` في pubspec → versionName/versionCode، جدول semver المعتمد
     (+N يزيد دائماً)، تجاوز `--build-name/--build-number`.
  3. إجراءات إصدار نسخة جديدة: pre-flight checklist → رفع الإصدار → البناء الثلاث →
     التحقق → التجربة فوق القديمة → الأرشفة مع mapping.txt → التوزيع المباشر → التوثيق.
  4. سيناريوهات حرجة: ضياع المفتاح (لا استعادة — وقاية بالنسخ الاحتياطي)، نسيان كلمة
     السر، رفض التحديث (فحص عكسي مرتّب)، جهاز/مسار جديد، Google Play وPlay App Signing،
     متى يتغير applicationId (أبداً إلا بإملاء).
  5. خلاصة تشغيلية Quick Reference + 5 ثوابت لا تُنكسر.
- [x] **أمان التوثيق:** الدليل **لا يذكر كلمة سر المفتاح إطلاقاً** — يحيل إلى
  `android/key.properties` المحلي ومدير كلمات السر فقط، التزاماً بقاعدة عدم تسجيل الأسرار.
- **ملاحظة:** لم يُنفَّذ أي بناء أو تعديل كود في هذه الجولة — وثيقة مرجعية بحتة.


## [2026-10-24 14:30] توسيع صلاحيات IBAC: كشوف دقيقة + حجب أزرار + طيّ الأقسام · Qoder Agent

**المهمة:** تنفيذ خطة `تطوير_وتوسيع_نظام_الصلاحيات_IBAC` — استبدال أكواد الكشوف
العامة بأكواد دقيقة لكل كشف، إصلاح مشكلة القوائم المنسدلة في شاشة المنتقي، حجب كل
زر/بطاقة/أيقونة وراء صلاحيته، وتحسين واجهتي عرض الصلاحيات (المنتقي والكتالوج).

- [x] **الخادم (kyApp_API):**
  - `PermissionCatalog.php`: استبدال `accounts.statement` بثلاثة أكواد
    (`statement_financial`/`statement_group`/`statement_detail`) واستبدال
    `employees/cutters/tailors.statement` بكشفين لكل قسم (`statement_financial` +
    `statement_work`)؛ عدد الأكواد 127 → 132؛ تحديث `humanize()`.
  - `EnsurePermission.php`: دعم OR عبر `string ...$codes` + تقسيم الفاصلة +
    `PermissionResolver::canAny` — توافق رجعي مع كود واحد.
  - `routes/api.php`: توزيع الأكواد على المسارات المساعدة (chart/tree/…) بمجموعات
    OR، والكشوف بأكوادها الدقيقة.
  - `tests/Feature/IbacCoreTest.php`: العدد 127 → 132.
  - `tests/Feature/BusinessRoutesSealedTest.php`: دعم قائمة الأكواد في assertions.
  - Pint نظيف على كل الملفات الخمسة؛ Pest: تطابق الكتالوج (24 assertion) + فحص
    المسارات نجحا.
- [x] **Oracle (تسليم بلا تنفيذ):**
  - `database/oracle/06_ibac_statement_split.sql` — كتلة PL/SQL: خريطة، ترحيل منح
    الكود العام إلى كل دقيقة مكافئة (لا إنقاص صلاحيات)، حذف المنح العامة وصفوف
    الأكواد العامة، COMMIT؛ بلا literals عربية (تقييد AL32UTF8 driver).
  - `database/oracle/07_ibac_statement_split_verify.sql` — خمسة تحققات: بقايا
    عام=0، وجود التسعة، بلا منح يتيمة، لا حامل عام بلا تغطية، عدد حيّ=132.
  - `02_ibac_seed.php` لا يحتاج تعديل (idempotent، قائدي على `PermissionCatalog::rows`).
- [x] **العميل (Flutter):**
  - `core/constants/permission_codes.dart`: حذف 4 constants عامة، إضافة 9 دقيقة،
    تحديث `allPermissionCodes` بنفس ترتيب الخادم، توسيع `permActionLabels`
    (`statement_financial`/`statement_group`/`statement_detail`/`statement_work`).
  - حجب كامل للأزرار: `accounts_dashboard_screen` (بطاقات كشوف + إضافة/تعديل +
    شجرة + عملات)، `worker_action_icons` (كل أيقونة بكودها)، `workers_dashboard`
    (بطاقات الفئات + «كشف عمل مجموعة»)، `workers_list` (زر الإضافة)،
    `customers_dashboard` (5 بطاقات)، `all_customers_screen` (سطر كل عميل)،
    `account_statement_detail_screen` (طباعة/تصدير بأكوادها).
  - `home_shortcut_catalog`: إعادة ربط الاختصارات الأربعة بالأكواد الجديدة.
- [x] **تحسين الواجهتين (طي الأقسام):**
  - `permissions_picker_widget` + `permission_module_group`: حالة `_collapsed` في
    State الوامض، نقل `expanded`/`onToggleCollapse`/`showCollapseToggle` إلى
    المجموعة، رأس قابل للنقر مع سهم، و«طي الكل/توسيع الكل» في شريط الحالة.
  - `permissions_catalog_screen`: نفس النمط في `_CatalogBodyState` مع
    `_ModuleCard` قابل للطيّ. البحث يُبقي الأقسام مفتوحة قسراً في الشاشتين.
- [x] **بوابة الجودة:** `flutter analyze` نظيف على 6 أدلة معدّلة؛ `flutter test
    test/ibac_test.dart` = 20/20 ناجح؛ `flutter test` كامل = 222 ناجح / 4 إخفاقات
    موثقة مسبقاً (`account_group_statement`) مثبتة بـ `git stash push -- lib`.
- [x] **التوثيق:** إلحاقات في `devloping_history.md` و`user_commends.md` و
    `DBdevloping_history.md` و`db_commends.md` بنفس التاريخ والطابع.
- **لا commit** — لا طلب من المستخدم. **لا تنفيذ SQL** — لا Oracle MCP متاح.


## [2026-10-24 18:45] تكملة IBAC: صلاحيات تقرير عمل المجموعة + تنفيذ الترحيل · Qoder Agent

**المهمة:** بعد تنفيذ الترحيل الأول وإبلاغ المستخدم به، وردت ثلاث مشكلات:
1. **تقرير عمل المجموعة** كان يحمله نفس كود `cutters.statement_work` / `tailors.statement_work` —
   يجب أن تكون له **صلاحية منفصلة** كما طلب المستخدم.
2. شاشة كشف حساب مالي 403 على `/api/accounts/chart/{accNo}/statement` رغم منح `statement_financial` —
   الخادم الحيّ كان لا يزال يقرأ الأكواد العامة القديمة من ملف routes قبل الحفظ؛ يلزم إعادة تشغيل serve.
3. `/api/workers/cutters/group-work-report` 403 بنفس النمط.

- [x] **كتالوج الخادم (`PermissionCatalog.php`):**
  - إضافة `'group_work_report' => 'تقرير عمل مجموعة القصاصين'` لقسم cutters.
  - إضافة `'group_work_report' => 'تقرير عمل مجموعة الخياطين'` لقسم tailors.
  - توسيع `humanize()`: `'group_work_report' => 'Group work report'`.
  - العدد 132 → **134** (127 − 4 عام + 9 دقيق + 2 مجموعة).
- [x] **المسارات (`routes/api.php`):**
  - `/workers/cutters/group-work-report` ← `permission:cutters.group_work_report` (كان `statement_work`).
  - `/workers/tailors/group-work-report` ← `permission:tailors.group_work_report`.
- [x] **اختبارات Pest:**
  - `IbacCoreTest`: العدد 132 → **134** مع تعليق محدّث.
  - `BusinessRoutesSealedTest`: مسارات group-work-report تتوقع الأكواد الجديدة.
  - `vendor/bin/pint` نظيف؛ 33 test / 189 assertion نجحت مقابل Oracle حيّ.
- [x] **Qtـاع قاعدة البيانات (oracledb MCP):**
  - شُغِّل `02_ibac_seed.php` → `inserted=2 updated=132 total=134`.
  - IDs الجديدة: 138 (`cutters.group_work_report`) و 139 (`tailors.group_work_report`).
  - `COUNT(*) = 134` ✓؛ `IS_ACTIVE=1` ✓.
- [x] **Flutter:**
  - `permission_codes.dart`: تعليق المصدر 132 → 134؛ إضافة `cuttersGroupWorkReport`
    و `tailorsGroupWorkReport`؛ ادراجهما في `allPermissionCodes` بنفس ترتيب الخادم؛
    `permActionLabels['group_work_report'] = 'تقرير عمل مجموعة'`.
  - `workers_dashboard_screen.dart`: بطاقة «كشف عمل مجموعة» مشروطة الآن بـ
    `canAny([cuttersGroupWorkReport, tailorsGroupWorkReport])` بدل
    `[cuttersStatementWork, tailorsStatementWork]`.
  - `home_shortcut_catalog.dart`: اختصار `workers.group_work` يحمل الآن الأكواد
    الجديدة بدل أكواد كشف الفرد.
  - `worker_action_icons.dart` unchanged — الأيقونات الفردية ما زالت
    `<apiPath>.statement_work` لأنها كشف فرد لا مجموعة.
- [x] **بوابة الجودة:**
  - `flutter analyze lib` → صفر مشاكل (تحذير biometric سابق غير متعلق).
  - `flutter test test/ibac_test.dart` → 20/20 ناجح.
- **إعادة تشغيل serve:** المسارات الجديدة لا تُحمَّل في `php artisan serve` القديم؛ أوقِف
  وأعد تشغيله (أو `php artisan route:clear` إن استُخدمت الكاش مسبقاً). بعد إعادة
  التشغيل، `/api/accounts/chart/11010001/statement` و`/api/workers/cutters/group-work-report`
  يستجيبان بالأكواد الدقيقة (134 في الكتالوج).


## [2026-10-24 05:20] تطوير الشجرة المحاسبية وإصلاح مشاكلها — خطة من 8 مراحل · Qoder Agent

**المهمة:** لا تظهر كل الأقسام/الحسابات، عرض عشوائي بأسطر ضخمة، تفاصيل ناقصة، أرصدة
الأبناء لا تُجمَّع في الأب، تحميل بطيء ينقطع — مع طباعة/تصدير PDF+Excel، زر «كشف» لكل
سطر، وتوسيع نموذجي الإنشاء والتعديل. القرارات المعتمدة: تحميل كسول مستوى-بمستوى، XLSX
حقيقي، حسابات العملاء (بادئة 123) مستثناة من **العرض** فقط وتبقى في **التجميع**،
والأرصدة تُحسب من `ACCOUNTS.ENTRY_SUB` لا من أعمدة `BALANCE`.

- [x] **المرحلة 0 — التبعيات:** `flutter pub add excel share_plus` (`pubspec.yaml`/`lock` + مُسجِّلات windows المولّدة).
- [x] **المرحلة 1 — واجهات الخادم** (`kyApp_API/app/Http/Controllers/AccountController.php`):
  - `GET /accounts/tree` هيكل كسول ثابت الاستعلامات: **4** أقسام / **24** فرعي / **95** جزئي / **12** مجموعة، كل عقدة تظهر ولو فارغة مع `children_count`/`has_children`/`parent_path`/`code_path`.
  - تجميع الأرصدة (سماّه الخطة `balanceMap()`، ونُفِّذ كـ `movementAggregateSql()` + `movementBalancesByChart()` + `movementBalancesFor()`) يجمع `DR/CR/NET/CNT` من `ENTRY_SUB` (مع `ENTRY_MAIN` عند وجود فترة) ويُرقّي الحسابات بلا مجموعة إلى مستوى `acc_part` — لا اعتماد على `BALANCE` المخزّنة.
  - استثناء العرض: تحت `ACC_PART=123` لا تُعرض المجموعات، ويُعرض `عملاء الكبودي للخياطة (12310000)` وحده، مع احتفاظ التجميع بكل حسابات 123؛ `hidden_accounts` يوضح العدد المقصوص.
  - `GET /accounts/tree/children` أبناء بترقيم Oracle-11g (`ROWNUM` ثلاث طبقات) + `search` عبر `ArabicEncoding::toOracleSearchChars` + ترتيب أبيض-list.
  - `GET /accounts/search` بحث شامل (كل المستويات + المالية) بمسار الأب؛ `GET /accounts/next-number` معاينة الرقم قبل الإنشاء.
- [x] **المرحلة 2 — الإصلاحات:** `TRUNC(c.ACC_NO/10000)` → `SUBSTR(TO_CHAR(c.ACC_NO),1,3)` في `getDetailedStatement`؛ ترقيم الإنشاء `accPart*100000 + (MAX(لاحقة)+1)` (110 → 11010001)؛ حقول `CHART_ACC` كاملة في الإنشاء؛ نقاط هيكلية جديدة خلف `accounts.structure_manage` (`POST/PUT /accounts/main`، `POST/PUT /accounts/sub`، `PUT /accounts/account/{accNo}`، `PUT /accounts/chart/{accNo}`) — **بلا حذف** لعقد هيكلية؛ `BusinessRoutesSealedTest` أخضر.
- [x] **المرحلة 3 — العميل:** `AccountTreeNode` موسّع + `AccountLeafModel` (fromJson مزدوج المفاتيح + `ArabicEncodingUtils.fix`)؛ المستودع (`fetchAccountTree`/`fetchTreeChildren`/`searchAccounts`/`fetchChartAccountDetail`/`fetchNextNumber`/`create*`/`update*`) بمهلة استقبال 30 ث للشجرة؛ `AccountTreeNotifier` (كاش أبناء لكل عقدة، `_searchVersion` ضد السباق، `CancelToken` يُلغى عند `dispose`).
- [x] **المرحلة 4 — الشاشة:** `ListView.builder` واحد فوق `flattenAccountTree`؛ سطر مضغوط (34) / مريح (46)؛ ترويسة أعمدة على الشاشات العريضة؛ شريط فلاتر (بحث خادمي 300ms، قسم، مستوى، إخفاء الصفرية، إظهار الموقوفة، ترتيب، كثافة، توسيع حتى مستوى، تحديث)؛ زر كشف حسب الصلاحية (فردي → مالي، هيكلي → ميزان مجموعة)؛ `account_details_sheet` بكل الحقول؛ الحالات الأربع (skeleton/فراغ/خطأ+إعادة/نجاح) + `RefreshIndicator`؛ FAB بقائمة أربعة أنواع إنشاء.
- [x] **المرحلة 5 — الطباعة والتصدير:** `account_tree_pdf_builder.dart` (A4 RTL بترويسة والتذييل الموحّدين) + `account_tree_xlsx_builder.dart` (ورقة الشجرة + ورقة ملخص) + `group_statement_xlsx_builder.dart`؛ `tree_export_menu.dart` بقائمتين (`TreeExportMenu`, `GroupStatementExportMenu`) تشتركان `_ReportExportActions` (حراسة النقر المزدوج، طباعة/PDF/Excel، مشاركة `share_plus`)؛ حُسفت أزرار الطباعة المكررة من شاشة ميزان المجموعة.
- [x] **المرحلة 6 — نموذجا الإنشاء والتعديل:** `create_account_screen.dart` بأربعة أنواع (مالي/مجموعة/جزئي/فرعي) + سلسلة أبوية تُعيد ضبط النسل + شريط مسار + معاينة الرقم المتوقع + تحقق فوري + `_isSubmitting`؛ `edit_account_screen.dart` يملأ الحقول من `GET /accounts/chart/{accNo}` ويعرض الرصيد المحسوب للقراءة فقط.
- [x] **المرحلة 7 — البوابات:** Pest جديد `tests/Feature/AccountTreeLazyTest.php` (11 اختباراً مقابل Oracle حيّ)؛ الحزمة كاملة **142 passed / 2 skipped / 1073 assertion**؛ `pint --dirty` = passed؛ `flutter analyze` = **No issues found!**؛ `flutter test` = **259 passed / 5 skipped** (منها 32 اختباراً جديداً: نماذج + Notifier + شاشة)؛ فحص حيّ بـ `php artisan serve` على `/accounts/tree` و`/accounts/tree/children` و`/accounts/search` و`/accounts/next-number` (المخرجات في `db_commends.md`).
- [x] **المرحلة 8 — التوثيق:** إلحاقات مؤرَّخة في `todo.md` و`devloping_history.md` و`DBdevloping_history.md` و`user_commends.md` و`db_commends.md`.
- **إصلاحات جانبية كشفتها الاختبارات:** `_maybeApplyDefaults` في شاشة ميزان المجموعة كان يقرأ `list[1]` بدل `list.first` (RangeError عند وجود عنصر واحد)؛ توقّع `test/api_config_test.dart` كان مضيفاً مختلفاً عن المُدخل؛ سطر `analysis_options.yaml` كان `ignore ignore`؛ `label` غير مستعمل في زر البصمة (أصبح tooltip)؛ المُعامل المحلي `_pump` في اختبار جدول تقرير المجموعة أُعيدت تسميته.
- **Git:** لا commit من الوكيل في هذه الجولة. شغل الخادم (المتحكم + المسارات + اختبار الشجرة) سبق حفظه بيد المستخدم في `kyApp_API` بـ `5945166 «اصلاح الصلاحيات وتطوير شجره الحسابات»` (مرجعية الفرع `origin/main`)؛ تظل تطبيعات هذه الجلسة (اختبارات + إصلاحات جانبية) بلا commit حتى يُطلب ذلك.

## [2026-10-24 09:24] إصلاح ثلاث مشكلات في شجرة الحسابات + فتح/إغلاق الحسابات الفرعية · Qoder Agent

**أمر المستخدم (كما ورد):** «اكمل الاصلاح وايضا لاتنسى اضافه امكانيه فتح/اغلاق ظهور الحسابات الفرعيه» ثم «اكمل» — تتمة أمر الإصلاح الثلاثي: قصّ اسم الحساب وكثافة السطر، والطباعة/التصدير اللذان يُخرجان الحسابات الرئيسة فقط، وحقل العملة الذي يجب أن يكون قائمة اختيار.

- [x] **الخادم (`kyApp_API/app/Http/Controllers/AccountController.php` + `routes/api.php`):**
  - `GET /accounts/export-tree` خلف `permission:accounts.export,accounts.print`: إخراج **مسطّح بكل
    المستويات الخمسة المختارة** (`levels=account,main,sub,group,chart`) مع `section` و
    `include_customers` و`hide_zero` و`from_date/to_date`؛ فلترة الأجزاء داخل SQL
    (`SUBSTR(TO_CHAR(ACC_NO),1,3) IN (:part_0,…)` + حارس حساب العملاء) لا في PHP.
  - `GET /accounts/currencies` خلف **صلاحيات الحسابات** (`accounts.view,create,update,structure_manage`)
    لا `currencies.view` — وإلا ظهر النموذج بقائمة فارغة لمستخدم يملك الإنشاء ولا يملك دليل العملات.
  - اختبار جديد `tests/Feature/AccountTreeExportTest.php`: **8 اختبارات / 10,835 assertion** مقابل
    Oracle حيّ (منها تكافؤ رصيد الصف المُصدَّر مع رصيد العقدة في `/accounts/tree`).
- [x] **Flutter — التصدير صار طلباً لا قراءة شاشة:**
  - `data/models/tree_export_row_model.dart` — `TreeExportLevel` (خمسة أكواد + تسميات عربية)،
    `TreeExportScope` (`toQuery()`/`describe()`)، `TreeExportRow` (مفاتيح Oracle كبيرة/صغيرة
    والأرقام نصوصاً + `ArabicEncodingUtils.fix`)، `CurrencyOptionModel`.
  - `presentation/utils/tree_export_adapter.dart` — صفوف الخادم → أسطر عرض، وتذييل يصف
    النطاق الفعلي بالأرقام التي رجعت من الخادم.
  - `presentation/widgets/tree_export_scope_sheet.dart` — نافذة النطاق (مستويات، قسم، عملاء،
    أرصدة صفرية، فترة).
  - `presentation/widgets/tree_export_menu.dart` — **حُذف معامل `rows:`**؛ القائمة تفتح النافذة
    ثم تجلب من الخادم (`_prepareScope`) داخل `_busy`، والإلغاء = لا طلب ولا ملف، ورسالة الخادم
    العربية تصل المستخدم (`_describeFailure`).
- [x] **Flutter — سطر الشجرة:** `presentation/utils/tree_row_layout.dart` (`TreeDensity` بخمس
  كثافات 22/28/34/42/52 + `TreeRowMetrics.resolve` يحسب من العرض المتاح مع أرضية 96px للاسم
  وحذف متدرّج للعناصر الجانبية) و`account_tree_row_tile.dart`: الاسم داخل `Expanded` +
  `FittedBox(fit: BoxFit.scaleDown)` فلا يُقصّ، وفتحات ثابتة `badgeW`/`actionsW`/`handleW`
  يتقاسمها السطر ورأس الأعمدة فلا ينزلق عمود الرصيد بين سطر وآخر، ونقر طويل → التفاصيل حيث تُطفأ الأزرار.
- [x] **Flutter — حقل العملة:** `create_account_screen.dart` استبدل `TextEditingController`
  بـ `int? _currencyNo` وقائمة منسدلة من `accountCurrencyOptionsProvider` (مزوّد جديد في
  `accounts_provider.dart`)؛ تظهر **فقط** لمستويي `main|sub` لأن `CHART_ACC` لا يملك عمود عملة
  و`ACC_SUB_GROUP` لا يقبله في الإنشاء؛ الحقل اختياري مع إعادة محاولة عند فشل الدليل.
- [x] **فتح/إغلاق ظهور الحسابات الفرعية (طلب هذه الجولة):** مبدّل في الـ AppBar
  (`فتح ظهور الحسابات الفرعية` / `إغلاق ظهور الحسابات الفرعية` ← `expandToLevel(3)` /
  `expandToLevel(-1)`)، مقبض فتح/إغلاق لكل سطر هيكلي، ومفتاح «ظهور الحسابات الفرعية»
  + «توسيع حتى مستوى» داخل خيارات العرض.
- [x] **البوابات:** `flutter analyze` = **No issues found!** · `flutter test` = **285 passed /
  5 skipped** (الجديد: `test/features/accounts/account_tree_export_test.dart` و
  `account_currency_field_test.dart`) · `php artisan test --filter=AccountTreeExport` = 8 passed ·
  `--filter=BusinessRoutesSealed` = 6 passed · `vendor/bin/pint --dirty` = passed.
- **حقيقة مكتَشفة تُحسب للاختبارات:** `DropdownButton` يعرض العنصر الذي قيمته `null` بدل
  `hint`، فالامتحان «القسم» يُعرَّف بقيمة عناصره لا بتلميح اسمه؛ وRiverpod 3 يعيد تلقائياً
  محاولة `FutureProvider` الفاشل عشّ مرات (11 طلباً) لذلك تُوقَف إعادة المحاولة في
  `ProviderScope(retry:)` داخل الاختبارات.
- **Git:** لا commit من الوكيل؛ التغييرات في شجرة العمل (Flutter) وفي `kyApp_API` غير مُسلَّمة.
- [x] **إغلاق الجولة (09:51):** أُعيد تشغيل البوابات كلها على الحالة النهائية — `flutter analyze` =
  No issues found! · `flutter test` = 285 passed / 5 skipped · Pest كامل = 150 passed / 2 skipped /
  11,908 assertion · `AccountTreeExport` = 8 passed / 10,835 assertion · `pint --dirty` = passed.
  والتوثيق مكتمل في الملفات الخمسة (`user_commends.md` أُضيف أخيراً بنص الأوامر حرفياً)، وحُذفت
  ملفات الفحص المؤقتة من `.zwork`. لا DDL، لا commit، ولم يُعدَّل ملف الخطة.

---

## [2026-10-24 14:44] جولة إصلاح ثانية — ثلاث مشكلات من الاختبار الحيّ (Qoder Agent)

نصّ الأمر كما ورد: «هناك مشكله عند النقر على زر الفتح والاغلاق ويظهر خطا Another exception was
thrown: Invalid argument: 52 — ثانيا اين خقل اختيار العمله في نموذج انشاء حساب لايوجد — ثالثا هناك
مشكله عند الطباعه او تصدير الشجر ويظهر خطا» + تتبّع Dio للـ 404 على
`GET /api/accounts/export-tree?levels=account,main,sub,group,chart&include_customers=0&hide_zero=0`.

- [x] **المشكلة 1 — انهيار `Invalid argument: 52` عند فتح/إغلاق الفروع.**
      السبب: `_statusRow` في `account_tree_row_tile.dart` كان
      `(_comfortableHeight - 8).clamp(metrics.height, _comfortableHeight)` أي `clamp(52, 46)` على
      الكثافة «الواسعة» (52px)، و`num.clamp` يرمي `ArgumentError` متى كان الحدّ الأدنى > الأعلى.
      أُثبت بالتشغيل المباشرة على VM: `Invalid argument(s): 52.0` من `double.clamp`. صفوف الحالة
      (جارٍ التحميل / تحميل المزيد / خطأ) هي بالتحديد ما يظهر لحظة التوسيع — طابق التقرير.
      الإصلاح: `max` شرطية بدل الـ clamp، مع اختبار انحدار يمشّي أنواع صفوف الحالة الثلاثة ×
      الكثافات الخمسة ويتأكد عدم وجود استثناء وأن الارتفاع ≥ ارتفاع الكثافة.
- [x] **المشكلة 2 — حقل العملة لا يظهر في نموذج إنشاء حساب.**
      السبب: في الجولة السابقة حُصر الحقل في `main|sub`، بينما الحالة الافتراضية للنموذج هي `chart` → لا يظهر
      أبداً للمستخدم العادي. وزاد عليها: على الخادم القديم (192.168.0.9) كان `/accounts/currencies`
      يرجّع 404 فيتدهور الحقل إلى خانة إعادة المحاولة.
      الإصلاح: سطر العملة يُعرض **دائماً** — منتقي عملات عندما يخزّن الجدول `CUR_NO`
      (`ACC_MAIN`/`ACC_SUB`)، وحقل **للقراءة فقط** يعرض العملة الموروثة من `ACC_SUB` الأعلى للحالات
      التي لا تخزّنها (`CHART_ACC`/`ACC_SUB_GROUP` ليس لديهما عملة)، مع تسمية عربية تشرح الوراثة،
      ورسالة 404 خاصة في حالة فشل الجلب.
- [x] **المشكلة 3 — 404 في الطباعة/التصدير: ليس خطأ كود، بل نشرٌ قديم.**
      الأدلة: هذه الآلة IPّها `192.168.0.11` و`Test-Path C:\kyApp_API` = False، بينما مسارات
      تتبّع الخادم الحيّ كلها تحت `C:\kyApp_API` → الـ API على `192.168.0.9` نسخة أخرى أقدم لا
      تعرف `accounts/export-tree` ولا `accounts/currencies`. محلياً: `php artisan route:list
      --path=accounts` يُظهر المسارين، و`bootstrap/cache` لا يحتوي ملف مسارات مُخزَّناً (لا حاجة
      لـ `route:clear` هنا)، وخادم محلي على 8099 أرجع **401** للمسارين مع `Accept: application/json`
      (وليست 404) → المسارات مسجَّلة سليمة. أُضيفت رسالة خطأ عربية مخصّصة لـ 404 في
      `tree_export_menu.dart` توجّه المستخدم لتحديث الـ API بدل الرسالة العمومية.
- [ ] **مفتوح للمستخدم (نشر):** رفع `routes/api.php` + `app/Http/Controllers/AccountController.php`
      إلى جهاز `192.168.0.9` (أو commit+push من `kyApp_API` ثم pull هناك و`php artisan route:clear`)،
      أو تشغيل الخادم من هذا الفرع وتغيير Base URL من إعدادات شاشة الدخول إلى `192.168.0.11:8000`.
- [ ] **مفتوح للمستخدم (تذييل كشف الحساب):** `account_statement_report_footer.dart` معدَّل من قبل
      المستخدم (git `M`، 14:20:23) مع تعطيل كتلة التواقيع/التوقيت → تحذيران في `flutter analyze`
      (`unused_local_variable` سطر 24، `unused_element _SignatureSlot` سطر 155) وفشل اختبار
      `توقيع المدير` في `account_statement_report_widgets_test.dart:109`. لم أُمسَّ الملف لأنه عمل
      جارٍ للمستخدم: إمّا إعادة تفعيل الكتلة أو حذف الكود الميت وضبط الاختبار.
- [x] **البوابات النهائية:** `flutter analyze` = تحذيران فقط وكلاهما من الملف أعلاه (لا شيء من
      تغييراتي) · `flutter test` = **286 passed / 5 skipped / 1 failed** والفشل الوحيد من نفس تعديل
      المستخدم · الملفان المستهدفان = 28 passed · **لا تغيير PHP** هذه الجولة فلم تُجرَ Pest ولا
      Pint · **لا SQL** · **لا DDL** · **لا commit**.
- [x] **تنظيف:** أُوقف خادم الفحص المؤقت (`php artisan serve` على 8099) وحُذفت ملفاته من
      `.zwork` — لم يبقَ إلا `apk_build.log` و`tree_section_new.php` و`.gitignore`.

---

## [2026-10-24 15:20] جولة الإصلاح 3 — حقل العملة مستقلّ لكل حساب مالي (لا وراثة، لا DDL)

**الأمر النصّي للمستخدم:** «ياحيوان اين خقل اختيار العمله في نموذج انشاء حساب لااريد ان يكون
موروث من الحساب الاب اريد اظهار حقل العمله يتم اختيار عمله لكل حساب بشكل مستقل» ثم أوضح:
«لا تضيف اي جدول او اي حقل الذي يحدد عمله الحساب هي الخانه الرابعه من رقم الحساب» و«إلزامي دائماً».

- [x] **التحليل:** تأكيد المتطلب مقابل القاعدة التراثية عبر oracledb MCP (قراءة فقط). القاعدة
      المُثبتة: `ACC_NO = الجزء(3) + رقم العملة(1 = الخانة الرابعة) + التسلسل`. `CURRENCY`:
      1 ريال، 2 دولار، 3 سعودي، 4 يورو (غير مستخدم). لا عمود `CUR_NO` في `CHART_ACC`.
- [x] **الخطأ المكتَشَف:** `nextAccountNumber`/`createChartAccount` كانا يأخذان `MAX(ACC_NO)`
      على الجزء كاملاً، فيقفز أعلى عملة ترتيباً ويمنح رقم عملةٍ لم تُختَر (الجزء 251 ← 25130012
      لحساب طُلب بالريال). إصلاح بنطاق `(جزء, عملة)`: `lo = part*100000 + cur*10000`, `hi = lo+10000`.
- [x] **API (`AccountController.php`):** مساعدان `currencyOfChartNumber()` + `nextChartAccountNumber()`؛
      `cur_no` إلزامي (1..9) في `createChartAccount` مع التحقق من وجوده في `CURRENCY` (404/422)؛
      المعاينة `next-number?level=chart` تطلب `cur_no`؛ كل قراءات الشجرة/البحث/التفاصيل/التصدير
      تُشتقّ `cur_no` من الرقم بدل `null`.
- [x] **Dart — النموذج (`create_account_screen.dart`):** منتقي عملة حقيقي إلزامي للحساب المالي
      (لا خيار «بدون عملة»)، وُضع `_pickCurrency` الذي يعيد المعاينة فور تغيّر العملة؛ بوابة
      `_canPreview` للحساب المالي تتطلب عملة؛ تحقق `_validateParent` يمنع الإرسال بلا عملة؛
      حذف الحقل الموروث؛ المجموعة وحدها تبقى سطراً وصفياً (لا رقم ولا عمود لها).
- [x] **Dart — المستودع/النموذج:** `fetchNextNumber(..., int? curNo)`؛ `createChartAccount(...,
      required int curNo)`؛ إضافة `curNo` إلى `AccountLeafModel` (من الخادم أو اشتقاق محلي من الرقم).
- [x] **Dart — التعديل (`edit_account_screen.dart`):** عرض العملة المشتقة للقراءة فقط (إعادة ترقيم
      حساب قائم تكسر مراجع `ENTRY_SUB`، فلا تُحرَّر).
- [x] **الاختبارات:** Pest — تحديث معاينة `next-number` لتشمل `cur_no` + اختبار «يبقى الترقيم داخل
      نطاق عملته» للجزء 251 بعملات 1/2/3 + رفض 422 بلا عملة. Dart — إعادة كتابة
      `account_currency_field_test.dart`: منتقي إلزامي للمالي، إعادة حساب المعاينة عند الاختيار،
      سطر وصفي للمجموعة.
- [x] **البوابات:** `flutter analyze` = تحذيران فقط وكلاهما في ملف التذييل الذي عدّله المستخدم ·
      `flutter test test/features/accounts/account_currency_field_test.dart` = 7 passed · Pest
      المستهدف = 26 passed (11208 assertions) · `pint --dirty` = passed · **SQL قراءة فقط، لا DDL
      ولا DML** · **لا commit**.
- [x] **فشلان معروفان في الحزمة الكاملة:** (1) `account_statement_report_widgets_test.dart` = من
      تعديل المستخدم لتذييل المطبوعة (خارج نطاق هذه الجولة) · (2) `account_currency_field_test:
      it is optional` = تذبذب خطوط العربية عند تشغيل كل الملفات معاً (يمرّ أخضر حين يُنفَّذ منفرداً
      مرّتين متتاليتين)، لا علاقة له بالمنطق.

---

## [2026-10-25 10:00] الكشوفات الشخصية (مالي + عمل) للموظف الحالي · Qoder Agent

**المهمة:** إضافة كشفين شخصيين يفتحان مباشرة على بيانات الموظف الحالي دون منتقي حساب/عامل:
**كشف حسابي المالي** و**كشف عملي** (خياط/قصاص)، بصلاحيتين IBAC مستقلتين واختصارين في الشاشة
الرئيسية فقط (بلا قسم في الدرج)، مع عمود `ACC_NO` في `APP_USERS` يربط المستخدم بحسابه المالي.

- [x] **قاعدة البيانات (oracledb MCP):** `ALTER TABLE ACCOUNTS.APP_USERS ADD ACC_NO NUMBER`
      (nullable) + تعليق العمود؛ لا foreign key (CHART_ACC خارج السيطرة) ← ربط منطقي
      `APP_USERS.ACC_NO → CHART_ACC.ACC_NO`.
- [x] **الصلاحيات (`PermissionCatalog.php`):** وحدة `my_statement` (name_ar «الكشوفات الشخصية»)،
      core `view`، extra `financial`/`work`، وتوسيع `humanize()`. إعادة بذر `APP_PERMISSIONS` ← 4
      أكواد (IDs 140–143): `my_statement.*`/`.view`/`.financial`/`.work`؛ مزامنة `SEQ_APP_PERMISSIONS`
      فوق 143 (تقنية increment).
- [x] **Backend:** `User.php` ( إضافة `ACC_NO` لـ fillable)؛ `AuthController::userPayload` يضيف
      `acc_no`؛ `MyStatementController.php` جديد ← `financialStatement()` (يقرأ ACC_NO من الجلسة
      حصراً، يعيد شكل `/accounts/chart/{accNo}/statement`) و`workStatement()` (يكتشف خياط/قصاص بعدّ
      صفوف `TAILOR_FROM_CALC.TAILOR_ACC`/`CUTTER_FROM_CALC.CUTTER_ACC`، يعيد شكل
      `/workers/{type}/{id}/work-report` مع `worker.type_label`)؛ مساران خلف
      `permission:my_statement.financial` / `my_statement.work`؛ `UserAdminController` يقبل `acc_no`
      في store/update.
- [x] **Flutter:** `permission_codes.dart` (مرآة: 4 ثوابت + allPermissionCodes/permModuleOrder/
      permModuleLabels/permActionLabels)؛ `UserModel.accNo`؛ ثوتا `/my-statement/financial` و
      `/my-statement/work`؛ ميزة `my_statement/` كاملة (repository يعيد `AccountStatementData`/
      `WorkerWorkReport`، provider بنمط Notifier + فحص accNo null)؛ شاشتان مبسّطتان بلا منتقي
      (`my_financial_statement_screen.dart`، `my_work_statement_screen.dart`)؛ إضافة `typeLabel`
      لـ `WorkerWorkReport`؛ بطاقتا اختصار `my_statement.financial`/`my_statement.work` في
      `home_shortcut_catalog.dart` بـ `sectionId: 'home'` و`defaultOn: false`.
- [x] **البوابات:** `flutter analyze` على الميزة والكتالوج والنموذج = **No issues found!** (تحذيران
      فقط في `account_statement_report_footer.dart` من تعديل المستخدم السابق، خارج النطاق) ·
      `flutter test test/home_catalog_test.dart` = **15 passed** · **لا commit** · لم يُعدَّل ملف الخطة.

---

## 2026-10-24 — حقل «الحساب المالي» (ACC_NO) في واجهة إنشاء/تعديل المستخدم (Claude)

- [x] **Backend (`UserAdminController.php`):** إضافة `u.ACC_NO` إلى `LIST_SQL`، و`ACC_NO` إلى
      `findUser` SELECT، و`'acc_no' => ...` إلى `shape()` — لتُرجع القائمةُ والتفاصيلُ الرقمَ المالي
      فيُعبَّأ النموذج عند التعديل (الكتابة كانت مدعومة سابقاً؛ القراءة هي الناقصة). `php -l` نظيف.
- [x] **Model (`app_user_model.dart`):** حقل `accNo` جديد (ctor / fromJson بقراءة مزدوجة
      `acc_no ?? ACC_NO` / toJson / copyWith) منفصلٌ تماماً عن `cashAccNo`.
- [x] **Picker (`financial_account_picker.dart` — جديد):** `FinancialAccountPickerSheet` +
      `showFinancialAccountPicker()` يعيد استخدام `chartAccountsProvider` (بحث debounced 300ms،
      وأربع حالات: تحميل/خطأ/فارغ/قائمة).
- [x] **Form (`user_form_widget.dart`):** تمييز حقل الصندوق `CASH_ACC_NO` («رقم الحساب النقدي
      (الصندوق)») عن الحقل المالي الجديد `ACC_NO` («الحساب المالي» — قابل للنقر يفتح المنتقي عند
      امتلاك `accounts.view`/`accounts.statement_financial`/مدير، أو حقل رقمي يدوي خلاف ذلك)؛ وربط
      `acc_no` في الـpayload (إنشاء عند غير null، تعديل عند التغيير، وnull يقطع الربط).
- [x] **اختبارات:** backend `UsersAdminTest` +2 (عقد القراءة: الصفوف تحمل `cash_acc_no`+`acc_no`؛
      التفاصيل تُرجع `acc_no`) = **19 passed** · Pint نظيف. Widget test جديد
      `user_form_financial_account_test.dart` = **3 passed**.
- [x] **لا DDL:** عمود `APP_USERS.ACC_NO` موجود مسبقاً من مهمة الكشوفات الشخصية — لا تغيير مخطط.
- [x] **البوابات:** `flutter analyze lib/features/admin` = **No issues found!** (تحذيران سابقان
      خارج النطاق في `account_statement_report_footer.dart`) · **لا commit**.

---

## 2026-10-25 — إصلاح تعذّر بناء Android (تعارض Kotlin) (Claude)

- [x] **التشخيص:** فشل `:share_plus:compileDebugKotlin` — `share_plus 12.0.2` مبنيّ ضد Kotlin
      stdlib 2.2.0، والإعداد يثبّت إضافة Kotlin على 1.9.24 (لا تقرأ metadata أعلى من 2.0.0).
- [x] **الإصلاح:** ترقية `org.jetbrains.kotlin.android` `1.9.24 → 2.2.0` في `android/settings.gradle.kts`
      (متوافق مع Gradle 8.10.2 / AGP 8.7.0 / JDK 21) · لا تعديل كود مصدري ولا قاعدة بيانات.
- [x] **التحقق:** `flutter build apk --debug` = **✓ Built app-debug.apk** · لا commit.

---

## 2026-10-25 (02:45) — بناء الإصدار الثاني v1.1.0+2 (Qoder Agent)

- [x] **الترقية:** `pubspec.yaml` من 1.0.0+1 إلى **1.1.0+2** (دخلت ميزات جديدة بعد v1: توسيع الصلاحيات f670271 + شجرة الحسابات والكشوفات ec37748 → ترقية minor لا patch).
- [x] **تحكيم الإخفاقات السبعة في الاختبارات (قرار المستخدم: إصلاح الاختبارات ثم البناء):**
      - **علة حقيقية مُصلحة في الكود:** زر «حفظ» في `create_account_screen.dart` كان يغلّفه
        `if (repeatable)` بالخطأ فيحرم أنواع main/sub/part من الحفظ → أُزيل الحارس وأصبح الحفظ دائمًا.
      - **تذييل الكشف:** إزالة خانات التواقيع قرار مقصود (commit ec37748) → حُذفت الشيفرة الميتة
        (`_SignatureSlot` + `timestamp`) وتُحدّث اختبار الفيض ليطابق الواقع الجديد.
      - **5 اختبارات قديمة (كتالوج الواجهة توسّع إلى 14 defaultOn):** تحديث home_catalog (13→14)،
        home_notifier (14→15 وإخفاء بطاقة management.users بدل customers.section)،
        responsive (4→2 بطاقات للقارئ فقط، والبطاقة الأولى صارت settings بدل customers).
- [x] **البوابات خضراء:** `flutter analyze` = No issues found! · `flutter test` = 294 All tests passed.
- [x] **البناء الموقّع:** `flutter build apk --release --split-per-abi` (armv7 30.9MB · arm64 32.8MB ·
      x86_64 34.6MB) + universal (90.2MB) بمفتاح v1 نفسه.
- [x] **التحقق:** apksigner — نفس بصمة الشهادة 811E477C…DADA5D0F (CN=Al-Kaboodi) → ترقية مباشرة فوق v1
      تعمل · aapt2 — الحزمة com.alkaboudy.app · versionName 1.1.0 · versionCode (2، 1002، 2002، 4002).
- [x] **الأرشفة:** `release_artifacts/v1.1.0+2/` (مستثنى من git) · **لا commit** (لم يُطلب).

---

## 2026-10-25 — إصلاح كشف حساب العميل: البيان + الرصيد + تنسيق الأعمدة والتكبير (Qoder)

- [x] **عمود البيان:** الاستعلام يجلب `NVL(TRIM(ENTRY_SUB.SUB_DETAILS), ENTRY_MAIN.DETAILS)` → التفصيل الفرعي أولاً، وإن كان فارغاً (NULL أو مسافات) يُؤخذ بيان القيد الرئيسي. تُضغط المسافات المتكررة عبر `normalizeStatementText()`.
- [x] **عمود الرصيد:** إلغاء الاعتماد على `ENTRY_SUB.BALANCE_S` نهائياً (كان رصيد الحساب المالي كاملاً — آلاف العملاء يشتركون في 12310000 — ولا يطابق الترتيب الزمني). الرصيد أصبح تراكمياً محسوباً من `ENTRY_MNT` بشرط الحساب **و** رقم العميل معاً.
- [x] **الرصيد النهائي:** `الافتتاحي + المدين − الدائن` (كان يأخذ آخر `BALANCE_S` للحساب).
- [x] **العقد:** الاستجابة تُرجع `balance` لكل سطر بدل `balance_s`، والموديل `CustomerStatementModel.balance` يقرأ `balance` فقط.
- [x] **التنسيق:** إعادة توزيع أوزان الأعمدة على المحتوى (البيان 3.3، الأرقام 1.2–1.45)، تصغير نص البيانات (8.5/9.5/10.5)، تقليل الحشو، صفّ الافتتاحي في عموده حسب الإشارة، وإزالة الإشارة السالبة من عمود الدائن.
- [x] **التكبير/التصغير:** شريط أدوات عائم (− نسبة٪ + إرجاع) يقود `TransformationController` نفسه المستخدم في Pinch، بمدى 50%–250%.
- [x] **تصحيح جانبي:** الفترات السريعة ومنتقي التاريخ كانا يستخدمان تاريخاً مثبتاً (2026-09-08) → صارا `DateTime.now()`.
- [x] **اختبارات:** `flutter analyze` = No issues found! · `flutter test` = 294 All tests passed · Pint passed · Pest = 157 passed / 4 skipped.

---

## 2026-10-25 (20:54) — إصلاح البيان والرصيد والرصيد النهائي في 4 كشوفات + تكبير/تصغير موحّد (Qoder)

- [x] **مساعد مشترك:** `ArabicEncoding::normalizeStatementText()` = `TRIM` + إصلاح ترميز Windows-1256 + طيّ المسافات؛ بديل لدالة كانت مكرّرة داخل `CustomerController`.
- [x] **كشف حساب مالي** `AccountController::getAccountStatement`: `NVL(TRIM(es.SUB_DETAILS), em.DETAILS)` · حذف `es.BALANCE_S` من الاستعلام · رصيد تراكمي من `ENTRY_MNT` · نهائي = افتتاحي + حركة الفترة · مفتاح السطر `balance`.
- [x] **كشف حساب مالي من شجرة الحسابات:** نفس المسار (`AccountStatementScreen` للأوراق) + `AccountGroupStatementScreen` للعُقد البنيوية (رصيده أصلاً من الحركات) → أُضيف لهما التكبير.
- [x] **كشف حسابي المالي** `MyStatementController::financialStatement`: نفس المعالجة (بيان + رصيد + نهائي) بلا أي عمود مخزَّن.
- [x] **كشف جاري العاملين** `WorkerController::fetchStatement`: استعلام ANSI JOINs، بيان بالـ fallback، مفتاح `balance` بدل `balance_s`، والنهائي من الحركة.
- [x] **موديلات Flutter:** `AccountTransactionModel.balance` يقرأ `balance`/`BALANCE` فقط (أُزيل fallback الـ `BALANCE_S`) · `WorkerStatementModel.balanceS → balance` وتحديث الشاشة وباني PDF.
- [x] **تكبير/تصغير موحّد:** مكوّن جديد `lib/core/widgets/report_zoom_view.dart` (شريط عائم − ٪ + ↺ بمدى 50%–250% يقود نفس `TransformationController` المستخدم في Pinch) وطُبِّق على **8 تقارير**: كشف العميل · كشف حسابي المالي · كشف حساب مالي · كشف مجموعة الحسابات · كشف جاري العاملين · كشف العمل الفردي · كشف العمل الجماعي · كشف العمل من «حسابي».
- [x] **تنسيق الجداول:** توحيد أوزان الأعمدة (`0.85/1.15/1.0/3.3/1.2/1.2/1.45`) وأحجام النص (بيانات 8.5/9.5/10.5) بين كشف الحساب المالي وكشف العاملين وكشف العميل.
- [x] **اختبار:** تحديث `account_statement_models_test.dart` للعقد الجديد + اختبار جديد يثبت تجاهل `BALANCE_S`.
- [x] **التحقق:** `flutter analyze` = No issues found! · `flutter test` = 295 ناجحاً (5 متجاوزة) · Pint passed · Pest = 157 ناجحاً / 4 متجاوزة · تحقق رقمي 20/20 على بيانات حقيقية.
- [x] **تصحيح توثيقي:** عمود نوع القيد هو `ENTRY_TYPE_NO` لا `ETRY_TYPE_NO` (أُثبت بـ ORA-00904) وصُحّح في `DBdevloping_history.md` و`db_commends.md`.

---

## 2026-10-25 (22:13) — تذكّر آخر اسم مستخدم وتعبئته تلقائياً في شاشة الدخول (Qoder)

- [x] **التخزين:** مفتاح مشفّر `ky_last_username` + `saveLastUsername` / `getLastUsername` / `deleteLastUsername` في `SecureStorageService`؛ لا يُحذف في `clearAll()` ويُحذف في `purgeEverything()`.
- [x] **قاعدة القيمة:** دالة نقية `usernameToRemember(canonical, typed)` — الاسم الرسمي من الخادم أولاً ثم النص المكتوب، والمسافات وحدها تعني «لا شيء».
- [x] **الحفظ بعد النجاح فقط:** `login` و`biometricLogin` عبر `_rememberUsername` (كتابة القرص + تحديث الحالة في مكان واحد).
- [x] **الحالة:** `AuthState.lastUsername` يُحمَّل في `checkAuthStatus()` بصيغة الإغلاق في `copyWith`، وينتقل عبر `logout()` و`forceLogout()`.
- [x] **شاشة الدخول:** تعبئة تلقائية في `initState` (بلا وميض) + `ref.listen` يعبّئ الاسم لو وصل بعد بناء الشاشة + `AutofillHints.username` + زر مسح يفرّغ الحقل ويستدعي `forgetLastUsername()`.
- [x] **اختبار جديد:** `test/features/auth/last_username_test.dart` — 13 حالة (القاعدة · البقاء بعد الطرد/الخروج · مسار `login` الحقيقي نجاحاً وفشلاً · تعبئة الشاشة بما فيه الوصول المتأخر).
- [x] **تصحيح جانبي:** `group_statement_xlsx_builder.dart` كان يقرأ `currentBalance` المحذوف → `periodBalance`، وإجمالي «رصيد الحركة» من `totals.periodBalance`، وتحديث اختبار شاشة ميزان المجموعة.
- [x] **التحقق:** `flutter analyze` = No issues found! · `flutter test` = 313 ناجحاً (5 متجاوزة) · لا تغيير على الخادم ولا على قاعدة البيانات.

---

## 2026-10-25 (22:57) — عمود «رصيد الفترة» في ميزان الحسابات الجزئية + تصحيح رصيد الحساب المالي المعروض (Qoder)

- [x] **الخادم — ميزان المجموعة** `AccountController::getGroupStatement`: صار يُرجع في المرور نفسه رصيدين لكل سطر:
  `balance` = الرصيد **النهائي** (صافي كل حركات الحساب بلا أي فلتر تاريخ) و`period_balance` = صافي حركة **الفترة**؛
  شرط التاريخ انتقل من `JOIN` إلى تعبيرات `SUM(CASE WHEN <period> …)` فبقيت الحسابات بلا حركة في الفترة ظاهرة بأصفار.
- [x] **الخادم:** إضافة `has_period` في `data`، جمع `period_balance` في `totals`، وحذف `current_balance` (كان يحمل لقطة
  `CHART_ACC.BALANCE` المتقادمة) — لا مستهلك له بعد الآن.
- [x] **الخادم — رصيد الحساب المالي:** `getChartAccounts` لم يعد يقرأ `CHART_ACC.BALANCE`، بل يحسب الصافي من `ENTRY_SUB`
  عبر `movementBalancesFor($accNos, null, null)`؛ وهذا يُصلح **كل** أماكن عرض الرصيد دفعةً واحدة: قائمة اختيار الحساب
  في «كشف حساب مالي»، وقائمة الحساب في نموذج إنشاء/تعديل المستخدم، ولوحة الحسابات، ودورة اختيار الحساب المالي.
- [x] **الخادم — كشفا الحساب:** `AccountController::getAccountStatement` و`MyStatementController::financialStatement`
  صار `account.balance` = صافي الدفتر التراكمي من `ENTRY_MNT`، وأُزيل عمود `BALANCE` من استعلام الحساب في الاثنين.
- [x] **Flutter — الموديل** `TrialBalanceRow`: `balance` (النهائي) + `periodBalance` (افتراضي 0)، ومستبعد `currentBalance`؛
  `TrialBalanceTotals.periodBalance`، و`TrialBalanceReport.hasPeriod` + `periodLabel` (تسمية صحيحة للفترة أحادية الطرف).
- [x] **Flutter — الجدول** `account_group_statement_report_table.dart`: أعمدة ديناميكية (8 أو 9)، عمود **«رصيد الفترة»**
  يُدرَج قبل **«الرصيد»** مباشرةً فقط عند وجود فلترة فترة، و`columnWidths` تُبنى بحسب ظهوره، وسطر المجاميع مثله.
- [x] **Flutter — PDF و XLSX:** عمود الفترة الشرطي في الاثنين + ترويسة الفترة من `report.periodLabel` + إجمالي رصيد الفترة،
  و`balance` المعنون «الرصيد النهائي»؛ قائمة عرض PDF تُعكس مرة واحدة بدل فهارس يدوية.
- [x] **Flutter — شاشة الكشف:** ترويسة الفترة من `periodLabel`، وشرح أسفل الجدول يوضّح الفرق بين العمودين.
- [x] **إصلاح مشترك:** `pdfDateRangeRow` في `report_pdf_page.dart` كان يطبع «كل الحركات» عند وجود تاريخ واحد فقط؛
  صار يطبع «من تاريخ: X» أو «إلى تاريخ: Y».
- [x] **الاختبارات:** تحديث `account_statement_models_test.dart` (`period_balance` + استقلال الرصيدين + الافتراضي + الفترة
  أحادية الطرف) واختبارَي ودجت جديدين يُثبتان إخفاء/إظهار عمود «رصيد الفترة» في `account_group_statement_screen_test.dart`.
- [x] **التحقق:** `php -l` نظيف · Pint نظيف · `php artisan test` = 157 ناجحاً / 4 متجاوزة (11,947 تأكيداً) ·
  `flutter analyze` = No issues found! · `flutter test` = 308 ناجحاً (5 متجاوزة) · تحقق رقمي على القاعدة الحقيقية **112/112**.
- [x] **دليل تقادم العمود المخزّن:** `CHART_ACC.BALANCE` يخالف مجموع الحركات في **19,126** حساباً من **20,954**،
  و**1,162** حساباً له حركات ومخزّنه صفر (مثال: 41210001 المخزّن −1,493,000,510 vs الحركات −1,801,753,216.78).

---

## 2026-10-26 (00:48) — إصلاح تهنيج التطبيق: ترقيم ميزان المجموعة + مهلة 3 ثوانٍ + تحميل تدريجي + جدول كسول (Qoder)

**التشخيص:** سجل `flutter run` أظهر موت العملية بـ **Scudo OOM** (1,391MB محجوزة · 6,653,649 تخصيصاً ·
«exhausted 256M for size class 7120») لا استثناء Dart ولا خطأ شبكة. السبب: `acc_sub=12` يضم **20,774**
حساباً تُجلب دفعة واحدة بلا ترقيم، ثم تُبنى كلها داخل `Table` غير كسول (≈186,966 خلية × `ui.Paragraph` أصلي).

- [x] **الخادم — ترقيم حقيقي** `AccountController::getGroupStatement`: `page` / `limit` (سقفه 2000، والقيمة `0`
  تعني «كل الصفوف» لمسار التصدير) عبر `ROWNUM` حول نفس الاستعلام المجمّع `$innerSql`.
- [x] **الخادم — إجماليات النطاق كله** استعلام واحد `COUNT(*) + SUM(...)` فوق `{$innerSql}` (بوابة `include_totals`)،
  فأُزيل تجميع الإجماليات صفاً بصف (كان سيضاعف الرقم مع كل صفحة).
- [x] **الخادم — `meta` حقيقية**: `total` · `page` · `limit` · `total_pages` · `has_more` · `totals_included`.
- [x] **الموديل** `TrialBalanceReport`: `total`/`page`/`limit`/`totalPages`/`hasMore` من `meta`، و`isPartial`،
  و`loadRatio`، و`appendPage()` الذي يدمج الأقسام ويُبقي إجماليات الصفحة الأولى.
- [x] **المستودع** `fetchGroupStatement`: معاملات `page` / `limit` / `includeTotals`.
- [x] **الشاشة — مهلة 3 ثوانٍ** `fetchDelay` (افتراضياً `Duration(seconds: 3)`): لا طلب والمستخدم يختار؛
  كل تغيير يلغي المؤقّت والطلب الجاري ويعيد العدّ، والتقرير السابق يُمسح فوراً.
- [x] **الشاشة — تحميل على أقسام** قسم أول 1000 صف يُعرض فوراً ثم بقية الأقسام تُضاف تدريجياً مع شريط تقدّم
  «جارٍ عرض الأقسام تدريجياً — X من Y».
- [x] **الشاشة — حدّ 2000 صف** `kGroupStatementMaxOnScreenRows`: يتوقف التنزيل التلقائي وتظهر بطاقة
  **«النطاق واسع جدًا، اختر مجموعة أدق»** مع **زر تصدير كامل من الخادم** وزر **«عرض كل الصفوف تدريجياً»**.
- [x] **الجدول — صفوف كسولة** ترويسة مثبّتة + `ListView.builder` + سطر إجمالي مثبّت، بنفس `columnWidths`
  فتبقى المحاذاة؛ الذاكرة ثابتة مهما كبر النطاق.
- [x] **التصدير** `GroupStatementExportMenu.fetchFull`: المستند يُبنى من **النطاق كاملاً** (`limit` بلا قيمة)
  لا من الصفوف المعروضة، مع حراسة نقر مزدوج وزر داخل الصفحة (`buttonLabel`).
- [x] **الاختبارات:** `account_group_statement_model_test.dart` (6 حالات: `meta` · الغياب · `has_more: "1"` ·
  الدمج · حفظ الإجماليات · `total=0`) و`account_group_statement_screen_test.dart` (مهلة 3 ثوانٍ · إعادة العدّ ·
  الأقسام · حدّ 2000 · قائمة التصدير · «عرض الكل» · جدول 5000 صف لا يبني إلا المرئي).
- [x] **التحقق:** `php -l` نظيف · Pint نظيف · `php artisan test` = 157 ناجحاً / 4 متجاوزة (11,947 تأكيداً) ·
  `flutter analyze` = No issues found! · `flutter test` = 326 ناجحاً (5 متجاوزة) · تحقق على القاعدة الحقيقية **13/13**
  (صفحة 1: 500 صفاً في 2.58 ثانية · 42 صفحة · تصدير كامل 20,774 صفاً في 3.95 ثانية · الإجماليات = مجموع الصفوف).


---

## 2026-10-26 03:11 — إصلاح: الكشوفات تعرض كل سجلات الفترة (لا 50 سطراً)

**الشكوى:** كل التقارير والكشوفات تعرض عدداً قليلاً من السجلات لا يتجاوز 50، وفترة شهرين تظهر كأنها 30 يوماً فقط.
**السبب الجذري:** `limit` افتراضي 50 في الخادم + `limit: 50` ثابت في المستودع، إضافة إلى مُرقّم 15 صفاً في كشف العاملين.

- [x] **الخادم** `AccountController::getAccountStatement`: غياب `limit` (أو `limit=0`) = **كل حركات الفترة**؛ أي قيمة موجبة تُقيَّد بـ 2000؛ `meta` يفضح `limit/returned/total_pages/has_more`.
- [x] **الخادم** `MyStatementController::financialStatement` (كشف حسابي المالي): نفس العقد تماماً.
- [x] **الخادم** `AccountController::getDetailedStatement`: نفس العقد، وتخطّي غلاف `ROWNUM` كلياً عند غياب الحد.
- [x] **العميل** `AccountRepository.fetchAccountStatement`: `page`/`limit` اختياريان ولا يُرسلان إلا بطلب صريح.
- [x] **الجدول** `AccountStatementReportTable`: صار كسولاً — رأس + رصيد افتتاحي مثبّتان، `ListView.builder` للحركات، سطر الإجمالي مثبّت، وأوزان أعمدة واحدة.
- [x] **جدول عام** `lib/core/widgets/lazy_report_table.dart` لإعادة الاستخدام في بقية الكشوفات.
- [x] **كشف العاملين** `worker_statement_screen.dart`: أُلغي الترقيم المحلي (15/صفحة) وأُلغي زر التنقل؛ كل الحركات تُعرض عبر `LazyReportTable`.
- [x] **كشف العمل** `WorkerWorkReportTable`: صار كسولاً (الرأس وسطرا الإجمالي مثبّتان) — الفترة الطويلة تُعرض كاملة.
- [x] **الاختبارات** `StatementFullPeriodTest` (3 حالات على القاعدة الحقيقية: بلا limit · limit=25 · الكشف الشخصي) و
  `account_statement_repository_test.dart` (3) و`account_statement_lazy_rows_test.dart` (4).
- [x] **التحقق:** `php -l` نظيف · Pint نظيف · `php artisan test` = **160 ناجحاً / 4 متجاوزة (11,964 تأكيداً)** ·
  `flutter analyze` = No issues found! · `flutter test` = **333 ناجحاً (5 متجاوزة)**.

**النموذج:** Qoder · **الوقت:** 2026-10-26 03:11 · **اقتطاع `limit`:** أُزيل · **لا commit** (لم يُطلب) · **لا DDL/DML**.

---

## 2026-10-27 01:50 — شاشة «معلومات البرنامج والدعم» + استفسارات الدعم

**الهدف:** زر ظاهر على شاشة الدخول يفتح شاشة بثلاثة أقسام (بيانات الشركة من القاعدة · معلومات المطور · الاستفسار والدعم)،
مع بقاء إعدادات الـ API سرّية عبر 5 نقرات على اسم المطور + كلمة السر، ونفس الشاشة في إعدادات الموظف بلا بوابة.

### قاعدة البيانات (Oracle 11g)

- [x] **جدول جديد** `ACCOUNTS.APP_SUPPORT_TICKETS` في `kyApp_API/database/oracle/08_app_support_tickets.sql`
  (13 عموداً · قيد `APP_SUP_STATUS_CK` على `new/answered/closed` · فهرسان `APP_SUP_STATUS_IX` و`APP_SUP_USER_IX` ·
  متسلسلة `SEQ_APP_SUPPORT_TICKETS` + مشغّل `TRG_APP_SUPPORT_TICKETS` · وصف `DROP` للتراجع في نهاية الملف).
- [x] **بلا مفتاح أجنبي** على `USER_ID`: الجداول الإرثية تُدار خارج سيطرتنا وحذف مستخدم لا يجوز أن يُفشل الإدراج.
- [x] **مفتاح جديد** `company_services` في بذر `02_ibac_seed.php` داخل `$settings` (`string` · `SORT_ORDER=145` · «نبذة عن خدمات الشركة»).
- [x] **صلاحيات الدعم** في `PermissionCatalog.php`: قسم `support` قبل `my_statement` بفعلين فقط (`view` · `update`) — بلا `create`
  لأن الإرسال خدمة ذاتية تعمل قبل الدخول. الأكواد: `support.*` · `support.view` · `support.update` (المجموع **141** بدل 138).
- [x] **التنفيذ على القاعدة الحقيقية:** الجدول + الفهرسـان + المتسلسلة + مشغّل مُفعَّل · إعادة البذر ⇒ `inserted=3 updated=138 total=141`
  و`company_services sort=145` · اختبار المشغّل أدرج صفاً وأعاد `TICKET_ID` تلقائياً ثم حُذف.

### الخادم

- [x] **`App\Support\AppConfig`:** الثابت `COMPANY_SERVICES` + إضافته إلى `DEFAULTS` و`WRITABLE_KEYS` ⇒ يدخل `publicPayload()` تلقائياً.
- [x] **`AppConfigController::textLimit()`:** `company_services => 400` (سقف العمود 500 بايت، والحدّ يحترم الترميز).
- [x] **`SupportInquiryController`** جديد: `store` (عام، يربط `USER_ID` بتوكن Sanctum اختياري ويشتق الاسم من `USER_NAME_AR`)،
  `index` (ترقيم `ROW_NUMBER` · `meta {total,page,limit,pages}` · بحث بالاسم/الهاتف/النص · `user_name` من `APP_USERS`)،
  `reply` (حالة + رد · 404 إن لم توجد · `REPLIED_BY/REPLIED_ON/UPDATED_ON`).
- [x] **العربية:** كتابة عبر `ArabicEncoding::toOracleSearchChars()` وقراءة عبر `fixMojibake()` في كل مسار.
- [x] **المسارات:** `POST /support/inquiries` عام بـ `throttle:5,1` · `GET` بـ `permission:support.view` · `PUT /{ticketId}` بـ `permission:support.update`.
- [x] **`ActivityLogger`** للإرسال المصادق وللرد، وفشل التسجيل لا يُفشل الطلب.

### العميل (Flutter)

- [x] **ثوابت** `lib/core/constants/app_info.dart`: `kAppVersion='1.1.0'` · `kAppBuildNumber='2'` · اسم المطور ورقمه ورابط واتساب.
- [x] **التهيئة:** حقل `companyServices` في النموذج (قراءة بمفتاحين · `copyWith` · `toJsonForUpdate`) وحقل نصّي 3 أسطر `maxLength: 400` في شاشة إعدادات التطبيق.
- [x] **`AppInfoScreen`** (`allowApiUnlock`) — رأس بالشعار واسم الشركة وشارة النسخة، الأقسام الثلاثة، ثم تذييل النسخة والحقوق.
- [x] **قسم الشركة** يقرأ من `appConfigNotifierProvider` (كاش فوري + مزامنة) مع حالة فراغ وزر تحديث، ويعمل قبل الدخول.
- [x] **قسم المطور:** الاسم هدف النقر الخفي (`DeveloperTapUnlock`: 5 نقرات / 3 ثوانٍ) ثم `ApiPasswordDialog` ثم `ApiSettingsScreen` —
  ولا يُخزَّن أي إذن: العدّاد يُصفَّر بعد النجاح والخروج يُلغي البوابة.
- [x] **قسم الدعم:** أزرار اتصال/واتساب + `SupportInquiryForm` (اسم وهاتف للزائر فقط، تحقق محلي مطابق للخادم، خطأ الخادم inline، لوحة نجاح برقم المتابعة).
- [x] **شاشة الدخول:** حُذف `IconButton` إعدادات الـ API و`_openApiSettingsWithGate`، وأُضيف زر «معلومات البرنامج والدعم» + سطر النسخة.
- [x] **إعدادات الموظف:** عنصر «معلومات التطبيق» يفتح نفس الشاشة بلا `allowApiUnlock`، والـ `trailing` صار `v$kAppVersion`.
- [x] **لوحة الإدارة:** بطاقة سادسة «استفسارات الدعم» + شاشة `SupportInquiriesScreen` (شرائح حالة · بحث مؤجَّل 300 ms ·
  سحب للتحديث · تحميل المزيد · الحالات الأربع · لوحة سفلية للتفاصيل والرد) ومزوّد بنمط `ActiveSessionsNotifier`.
- [x] **مرآة الصلاحيات:** `Perm.supportWildcard/supportView/supportUpdate` + `allPermissionCodes` + ترتيب الأقسام وتسميتها.
- [x] **بيانات الشركة والسجل:** قسم `management` في سجل البوابة وفي كتالوج اختصارات الرئيسية يقبل `support.view` أيضاً.
- [x] **الاعتماديات:** `url_launcher: ^6.3.1` + `queries` في AndroidManifest (`https` و`tel`) — بلا `canLaunchUrl`.

### الاختبارات والتحقق

- [x] **Flutter:** `developer_tap_unlock_test` (7) · `app_info_screen_test` (5) · `support_inquiry_model_test` (7) ·
  `app_config_model_test` (+1 `company_services`) · `last_username_test` (+1: الزر ظاهر وأيقونة الإعدادات غائبة).
- [x] **Pest:** `SupportInquiryTest` (6 حالات / 57 تأكيداً) + تحديث `BusinessRoutesSealedTest` (مسار عام مسموح · 401 · 403 للأكواد)
  و`IbacCoreTest` (141 كوداً · 25 تعريفاً في التهيئة).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **354 ناجحاً (5 متجاوزة)** ·
  `php artisan test --filter='SupportInquiry|BusinessRoutesSealed|IbacCore|AppConfig'` = **37 ناجحاً (262 تأكيداً)** · Pint نظيف.

**النموذج:** Qoder · **الوقت:** 2026-10-27 01:50 · **لا commit** (لم يُطلب) · **DDL/DML:** جدول + متسلسلة + مشغّل + إعادة بذر فقط.

---

## 2026-10-27 02:46 — زر «معلومات البرنامج والدعم» أيقونة في الشريط العلوي

- [x] **العميل:** حذف `OutlinedButton.icon` العريض من بطاقة شاشة الدخول.
- [x] **العميل:** إعادة `AppBar` شفاف (بلا ظل، بلون الخلفية) بأيقونة واحدة في `actions` — أعلى
  اليسار في RTL — `Icons.info_outline_rounded` مع `tooltip: 'معلومات البرنامج والدعم'`.
- [x] **العميل:** إبقاء سطر «الإصدار v1.1.0 (2)» أسفل زر «دخول» (نقل الزر لا حذف معلومة النسخة).
- [x] **الاختبارات:** تحديث حالة `last_username_test.dart` إلى «أيقونة … بلا نص» مع تأكيد وجود الأيقونة
  داخل `AppBar`، وغياب النص المرئي، وغياب `Icons.support_agent_rounded`، وبقاء غياب أيقونة إعدادات الخادم.
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **354 ناجحاً (5 متجاوزة)** ·
  لا تغيير في الخادم أو القاعدة.

**النموذج:** Qoder · **الوقت:** 2026-10-27 02:46 · **لا commit** (لم يُطلب).

---

## 2026-10-27 03:10 — تحسين قسم «معلومات الشركة» (البيانات كلها من القاعدة)

- [x] **العميل:** إعادة كتابة `company_info_section.dart` كبطاقة هوية: كتلة ترويسة (الاسم العربي +
      الإنجليزي) · شبكة بطاقات (العنوان + العنوان الإنجليزي، الموقع الإلكتروني، الهاتف) · لوحة
      «نبذة عن خدماتنا» — وكل قيمة من `appConfigNotifierProvider` أي من `APP_SETTINGS`.
- [x] **العميل:** شبكة متجاوبة: عمودان عند `maxWidth >= 460` داخل `IntrinsicHeight` (ارتفاع متساوٍ
      للبطاقتين) وعمود واحد على الهاتف؛ الحقل الشاغر لا يرسم بطاقة ولا لوحة.
- [x] **العميل:** `ExternalLinks.openMap()` — النقر على العنوان يفتح خرائط جوجل بالبحث عن العنوان
      المخزَّن (بلا إحداثيات ولا عمود جديد).
- [x] **العميل:** تطبيع رقم الهاتف في `buildTelUri()` — الرقم المحلي `780154000` كان يُطلب
      `+780154000`؛ الآن يُكمَّل بمفتاح اليمن `967` ويُحذف صفر البداية/بادئة `00`، والدولي يبقى كما هو.
- [x] **العميل:** حذف `AppInfoRow` من `app_info_card.dart` (كود ميت بعد إعادة الكتابة).
- [x] **العميل:** إزالة اسم الشركة المكرَّر من رأس `AppInfoScreen` (يبقى الشعار + شارة الإصدار).
- [x] **القاعدة:** كتابة `company_services` (140 محرفاً) بعد أن كانت فارغة — عبر `SettingsStore::set()`
      مع تحقق قراءة عكسية (`ROUND_TRIP_OK=1`)؛ `company_website` بقي فارغاً بلا اختراع رابط.
- [x] **الاختبارات:** 3 حالات جديدة (حقول فارغة · بيانات صفرية · تجاوب 360px بلا تجاوز) + 6 حالات
      لتطبيع رقم الهاتف في `external_links_test.dart` + تشديد الحالة الأولى (الاسم مرة واحدة، تسميات
      البطاقات، الاسم الإنجليزي) ⇒ 21 اختباراً لشاشة معلومات البرنامج والدعم ومرفقاتها.
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **363 ناجحاً (5 متجاوزة)** ·
      Pest: `AppConfig` 9 · `IbacCore` 16 · `BusinessRoutesSealed` 6 — كلها ناجحة.

**النموذج:** Qoder · **الوقت:** 2026-10-27 03:10 · **لا DDL** · **DML:** صف `APP_SETTINGS` واحد · **لا commit** (لم يُطلب).


---

## 2026-10-28 08:49 — قسم التفصيل: استعراض فاتورة التفصيل (تنفيذ كامل) + ثلاث واجهات أولية

- [x] **الخادم:** `TailoringController` جديد (قراءة فقط، مغلّف `success/message/data/meta`) بخمسة مسارات خلف `auth:sanctum` + `permission:`:
      `GET /tailoring/bills` · `GET /tailoring/bills/{billNo}/{year}` · `GET .../movements` · `GET /tailoring/reference` · `POST .../activity`.
- [x] **الخادم:** المفتاح المركّب `(BILL_NO, YEAR)` في كل مسار واستعلام — رقم الفاتورة وحده غير فريد، فلا نسخ لنمط `InvoiceController::show`.
- [x] **الخادم:** خانات المال تُحجب من الخادم (`payment: null`) عند غياب `tailoring.payments_view`، والواجهة تُغلقها ببوابة ثانية.
- [x] **الخادم:** ثلاثة أكواد في `PermissionCatalog` (144 = 141 + 3): `tailoring.payments_view` · `tailoring.export` · `tailoring.progress` + تحديث `IbacCoreTest` و`BusinessRoutesSealedTest`.
- [x] **القاعدة:** بذر الصلاحيات (`02_ibac_seed.php` الـ idempotent) — `APP_PERMISSIONS` = **144** صفاً، منها **10** لكودات التفصيل.
- [x] **العميل:** ميزة جديدة `lib/features/tailoring/` = 6 شاشات + 14 ودجت + 7 ملفات نماذج + مستودع + 5 مزودات + مولّد PDF.
- [x] **العميل:** لوحة القسم وقائمة الفواتير (بحث مؤجَّل 300ms · نطاقات زمنية جاهزة · ترقيم لا نهائي) وشاشة الاستعراض بالأقسام الثمانية داخل `ReportZoomView`.
- [x] **العميل:** الطباعة والتصدير عبر `Printing` بالترويسة الموحدة، وكل إجراء يسجّل `tailoring.bill_printed` / `tailoring.bills_exported`.
- [x] **العميل:** النماذج الأولية الثلاثة (إضافة · تعديل · متابعة سير) **قراءة فقط** بلا أي INSERT/UPDATE في جداول الإرث.
- [x] **الربط:** `tailoring_section.dart` ⇒ `TailoringDashboardScreen`، وأربع بطاقات في كتالوج الاختصارات، وإزالة `underDevelopment` من `tailoring.section`.
- [x] **الاختبارات:** `cutting_bill_models_test` (25) · `tailoring_repository_test` (9) · `cutting_bill_view_screen_test` (7) + تحديث `home_catalog_test` و`home_notifier_test` ومرآة `allPermissionCodes`.
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **407 ناجحاً (5 متجاوزة)** · Pest `Tailoring` = **11 اختباراً / 221 تأكيداً** · `vendor/bin/pint --dirty` = **passed**.

**النموذج:** Qoder · **الوقت:** 2026-10-28 08:49 · **لا DDL** · **DML:** 3 صفوف `APP_PERMISSIONS` (بذر) + صفوف `APP_USER_ACTIVITY` من مسارات التدقيق · **لا commit** (لم يُطلب).


---

## 2026-10-29 01:27 — تحسين واجهة استعراض فاتورة التفصيل: صفوف أفقية منضبطة وارتفاع أقل

- [x] **شبكة حقول متناظرة** — `TailoringInfoGrid` أُعيد بناؤها: أعمدة متساوية العرض، إطار وفواصل رأسية وأفقية بين الخانات، وكل خانة «تسمية فوق / قيمة تحت» في سطرين ثابتين، فلا فراغ متبقٍّ في نهاية الصف ولا تفاوت في الارتفاع.
- [x] **بيانات الفاتورة والطلب** — شريط هوية (رقم الفاتورة · اليدوي · التاريخ · مستعجل) ثم عشرة حقول في صف واحد: السنة · الفرع · المجموعة · مرجع الفاتورة · تاريخ التسليم · الاستحقاق · العملة · الحالة · الموديلات · القطع، والبيان في خانة تمتد على الصف.
- [x] **بيانات العميل** — صف واحد: الاسم · الهاتف · هاتف آخر · رقم العميل · رقم الحساب · العنوان.
- [x] **تفاصيل الدفع** — صف واحد: الإجمالي · الخصم · الصافي · المدفوع · مدفوعات أخرى · المتبقي · سعر العملة · الاستحقاق · طريقة الدفع · رقم السند.
- [x] **الموديلات والمستفيدون** — موديل واحد لكل سطر: رقمه · نوع الموديل (قطري/حجازي/عماني…) · المستفيد · عدد القطع · المرحلة · علامة الاختيار. المستفيد الفارغ لا يُعرض له عمود ولا كلمة «بلا مستفيد».
- [x] **المقاسات** — الاثنا عشر مقاساً في صف واحد من خانات مسوّرة بعرض متساوٍ، والفراغ مخفي افتراضياً مع مفتاح «إظهار الكل».
- [x] **المواصفات** — أصبحت خصائص القطعة فقط: نوع الرقبة · نوع الكم · نوع الكباك · الجيوب · نوع الجبزور · نوع الأزرار · عدد الأزرار · جيب الجوال · جيب القلم · نوع الحجازي. وأُزيل منها «نوع الموديل / رقم الشكل / الشكل» لأنها هوية الموديل ومكانها سطر الموديل.
- [x] **الأقمشة** — جدول صفوف أفقية في كل الأحجام (حُذفت بطاقات الجوال)، و**سجل الحركة** كذلك: صف واحد لكل حركة.
- [x] **تقليل الارتفاع** — فاصل الأقسام 6 بكسل وحشو شريط العنوان 5، والمسافة من أول قسم إلى آخر قسم 641 بكسل على شاشة 1280.
- [x] **إصلاح كود مقطوع** — أُعيدت `CuttingBillHeader.branchLabel` المفقودة، وسُدّ نداء `_kvRow` الناقص في مولّد PDF.
- [x] **الاختبارات** — 47 اختبار تفصيل ناجح (منها: كل قسم في سطر واحد، لا تجاوز على عرض 360، لا «بلا مستفيد»، ميزانية ارتفاع 650) والحزمة الكاملة 410 ناجحاً (5 متجاوزة) و`flutter analyze` = لا ملاحظات.

**النموذج:** Qoder · **الوقت:** 2026-10-29 01:27 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-29 02:05 — التفصيل: استكمال تغطية الاختبار وتوضيح حزمة الخادم

- [x] `test/features/tailoring/cutting_bills_list_screen_test.dart` (5 اختبارات): الهوية المركّبة في البطاقة، البحث المؤجَّل (لا طلب قبل 300 مللي)، نطاقات الفلترة الخمسة داخل لوحة الفلترة، الحالة الفارغة التي تشرح حدّ الـ VIEW، وحالة الخطأ مع «إعادة المحاولة».
- [x] `cutting_bill_view_screen_test.dart` صار 13 اختباراً بإضافة: ظهور زرَّي الطباعة والتصدير مع المنح واختفائهما بلا منح (بوابة `tailoring.print`/`tailoring.export`).
- [x] النتيجة: **اختبارات التفصيل 57** · الحزمة الكاملة **418 ناجحاً و5 متجاوزة** · `flutter analyze` = **No issues found!** · Pest `Tailoring` = **11 ناجحاً / 217 تأكيداً**.
- [x] **ملاحظة حزمة الخادم الكاملة:** تشغيل `php artisan test` كاملاً يُظهر فشلَين **سابقين** في `AccountTreeExportTest` (و`AccountTreeLazyTest`) لأنهما يثبّتان عددَي صفوف حيّين (main = 24 · sub = 95) على قاعدة CHART_ACC المتغيّرة، وكل اختبار فيهما يستغرق 4–24 دقيقة على البيانات الحقيقية — لا علاقة لهما بالتفصيل، والملفّان الممسوسان في هذا العمل (`IbacCoreTest` و`BusinessRoutesSealedTest`) ينجحان.

**النموذج:** Qoder · **الوقت:** 2026-10-29 02:05 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-29 04:34 — قسم «مقاسات العملاء» داخل قسم العملاء (تنفيذ كامل)

- [x] **الخادم:** `CustomerMeasurementController` جديد — قراءة فقط من `ACCOUNTS.CUTTING_SALES_BILL_VIEW` بأربعة مسارات خلف `auth:sanctum` + `permission:`: `GET /customers/measurements` · `GET /customers/measurements/{custNo}/models` · `GET /customers/measurements/{custNo}/models/{billNo}/{year}/{seqNo}` · `POST .../activity`.
- [x] **الخادم:** المفتاح رباعي (عميل، فاتورة، سنة، موديل): الموديل هو `SEQ_NO` داخل الفاتورة، ورقم الفاتورة وحده غير فريد؛ و`show` يتحقق من ملكية العميل فيعيد 404 بعلم `not_found_in_view` إن كان الموديل لغير هذا العميل.
- [x] **الخادم:** صنف قراءة موحّد `app/Support/CuttingViewReader.php` (المقاسات L1..L12، المواصفات، التسميات من `GENERAL_LABELS_CODING`، قارئات `num/txt/value/lower/dateTxt`، اسم الحالة من `ORDSTATE`، وتطبيع «لا يوجد» للخيّاط) — ونُقل `TailoringController` إليه بالتفويض بدل تكرار المنطق في متحكمين.
- [x] **الخادم:** قائمة العملاء بثلاثة استعلامات كقائمة فواتير التفصيل (عدّ المجموعات · مفاتيح الصفحة بـ `ROWNUM` المزدوج · تجميع الصفحة فقط)، والبحث في `HAVING` بالتجميع الشرطي على الاسم/الهاتف/المستفيد بالصيغتين (CP1256 وUTF-8) عبر `ArabicEncoding::toOracleSearchChars`.
- [x] **الخادم:** عدّاد التمايز `(BILL_NO*10000+YEAR)*1000000+SEQ_NO` — لأن `MAX(SEQ_NO)` في القاعدة الحيّة 85,120 فأي معامل أصغر من 100,000 يجعل موديلين يتطابقان في `COUNT(DISTINCT …)`.
- [x] **الخادم:** لا خانة مالية في أي استجابة إطلاقاً — القسم مقاسات ومواصفات وأقمشة، فلا يطبعها ولا يمرّرها حتى للمدير.
- [x] **الصلاحيات:** ثلاثة أكواد داخل وحدة `customers` الموجودة (`customers.measurements_view` · `_print` · `_export`)؛ الكتالوج 144 ⇒ **147**؛ البذر idempotent: `inserted=3 updated=144 total=147` والصفوف `PERMISSION_ID` 186–188 بترتيب 409–411.
- [x] **التدقيق:** أحداث جديدة في `APP_USER_ACTIVITY` وحده: `customers.measurements_listed` (لأول صفحة بحث) · `customers.measurements_viewed` · `customers.measurements_printed` · `customers.measurements_exported` — بوحدة `customers` و`entity_type = customer_measurement` و`entity_id = custNo/billNo/year/seqNo`.
- [x] **العميل:** طبقة بيانات جديدة — `measurement_customer_model.dart` و`measurement_model_ref.dart` (بما فيها `MeasurementKey` ومقارنته) و`customer_measurement_repository.dart` (الطبقة الوحيدة التي تلمس Dio) وثلاثة مزودات في `customer_measurement_providers.dart`: قائمة عملاء، وموديلات كمزوّد **عائلة** لكل عميل، وتفصيل `autoDispose.family`.
- [x] **العميل:** بحث مؤجَّل 300ms، `CancelToken` عند الإغلاق، بصمة طلب تمنع طمس النتيجة الأحدث، تحميل لا نهائي قبل النهاية بـ 320px، وسحب للتحديث، والحالات الأربع في كل شاشة.
- [x] **العميل:** الشاشات الثلاث — `measurements_customers_screen.dart` (قائمة العملاء والمستفيدين مع بحث بالاسم/الهاتف/المستفيد وأربعة ترتيبات) ← `customer_models_screen.dart` (موديلات العميل الأحدث أولاً + نطاق زمني + بحث مستفيد) ← `measurement_view_screen.dart` (الأقسام الأربعة).
- [x] **العميل:** شاشة المقاسات داخل `ReportZoomView` (تكبير بالإصبع والأزرار بنسبة حيّة) وزر إظهار/إخفاء الفلترة في الشريط العلوي + طباعة وتصدير خلف `PermissionGate` + تحديث؛ والشريط يحمل مفاتيح الأقسام الثلاثة ومنتقي موديلات الفاتورة وبحث الأقمشة.
- [x] **العميل:** كثافة العرض كما طُلب — حشوة 8–10px و`SizedBox(height: 8)` بين البطاقات، وشبكة حقول أفقية (`TailoringInfoGrid`)، وعند عرض ≥ 980 يصطف المقاسات والمواصفات جنباً إلى جنب والأقمشة تحتها.
- [x] **إعادة استخدام بلا نسخ:** النموذج `CuttingBillDetail`/`CuttingModelItem` وشرائح `ModelMeasurementsGrid` و`ModelSpecsPanel` و`ModelFabricsTable` نفسها (أُضيف لها وسم `showPrice` — `false` هنا، لأن عمود سعر فارغ دائماً أسوأ من عمود مفقود).
- [x] **العميل:** `customer_measurement_pdf_builder.dart` — ترويسة التقارير الموحدة + كتلة العميل/المستفيد + جدول مقاسات بأربعة أزواج في الصف + المواصفات + جدول الأقمشة (بلا سعر) + التذييل والتوقيعات؛ ويطبع السجل كاملاً لا ما كشفته المرشّحات.
- [x] **الربط:** بطاقة «مقاسات العملاء» محروسة بـ `customers.measurements_view` في لوحة العملاء، وبطاقة `customers.measurements` في كتالوج اختصارات الشاشة الرئيسية (`defaultOn: true`) مع تدفّق `openCustomerMeasurements`، ومرآة `allPermissionCodes` وتسميات `permActionLabels`.
- [x] **الاختبارات:** ثلاثة ملفات جديدة في `test/features/customers/` — النماذج (12) والمستودع (8) والشاشة (12) — وتحديث الحرّاس: `home_catalog_test` (16 افتراضياً و`customers.*` = 9) و`home_notifier_test` (17 نشطة) وعدّ الكتالوج في Pest إلى 147 (`IbacCoreTest`, `TailoringTest`).
- [x] **نتائج التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **450 ناجحاً و5 متجاوزة** · Pest `CustomerMeasurement` = **9 / 146 تأكيداً** · Pest `Tailoring` = **11 / 217** · `IbacCore` + `BusinessRoutesSealed` = **22 / 187** · `vendor/bin/pint --dirty` = **passed**.
- [ ] **قيد بيئة متبقٍّ:** لم يكتمل `php artisan test` الشامل في هذا الوقت: اتصال أوراكل المحلي (`localhost:1521/orclrd`) انقطع أثناء التشغيل (`ORA-12514: listener does not currently know of service`) فسقطت الاختبارات التي تلمس القاعدة بسبب الاتصال لا بسبب الكود؛ الحزم الأربع المذكورة مرّت على القاعدة الحيّة قبل الانقطاع، وتُعاد الحزمة الكاملة بعد عودة الاتصال.

**النموذج:** Qoder · **الوقت:** 2026-10-29 04:34 · **لا DDL** · **DML:** بذر 3 صفوف `APP_PERMISSIONS` + صفوف `APP_USER_ACTIVITY` من مسارات التدقيق · **لا commit** (لم يُطلب).


---

## 2026-10-29 06:47 — مراجعة «مقاسات العملاء»: نافذة الموديلات + إعادة هندسة التصميم والحقول

ردّ مستخدم رافض للتصميم الأول؛ نُفِّذ ما طلب كما هو:

- [x] **النافذة المنبثقة:** حُذفت `customer_models_screen.dart` القائمة، وحلّ محلّها
      `widgets/measurement_model_picker_sheet.dart` يفتح بـ `showModalBottomSheet` داخل
      `DraggableScrollableSheet` (88%) من `measurements_customers_screen.dart`، ويعيد الموديل
      المختار فتُدفع شاشة المقاسات بمفتاحه الرباعي. البحث والترتيب والنطاق الزمني كلها داخل النافذة.
- [x] **لوحة تصميم للميزة:** `widgets/measurement_kit.dart` — `MeasurementSectionCard` بترويسة
      متدرجة اللون وأيقونة مليئة، `MeasurementField` (تسمية `textSecondary` w700 / قيمة
      `textPrimary` w800 بحجم أكبر)، `MeasurementFieldGrid` بفواصل رأسية وأفقية حقيقية،
      `MeasurementBadge` بحالة `solid`، و`MeasurementGroupLabel` لعناوين المجموعات.
      الألوان الباهتة (`textMuted` 9.5px) استُبدلت في كل الشاشات.
- [x] **الحقول المحذوفة:** العنوان · مجموعة الحساب · شكل الموديل · رقم الموديل · الفرع — حُذفت من
      الشاشة ومن المطبوع، وأُزيل رقم الموديل من سطر العنوان الثانوي.
- [x] **هوية العميل/المستفيد:** ثلاث مجموعات معنونة (العميل / المستفيد والموديل / الفاتورة والطلب)
      بهاتفين في خانة واحدة ومرحلة ملوّنة للموديل.
- [x] **المواصفات:** خصائص الثوب فقط — نوع الرقبة · نوع الكم · نوع الكباك · الجيوب · نوع الجبزور ·
      نوع الأزرار · عدد الأزرار · جيب الجوال · جيب القلم · نوع الحجازي + الملاحظة؛ ولا نوع موديل
      ولا شكل ولا أرقام الأشكال.
- [x] **الأقمشة:** `widgets/measurement_fabrics_panel.dart` — كل قماش في سطرين:
      (رقم الطلب `OHDID` · القماش · العرض `CLOTH_TYPE` · اللون · هنش · ياردة · السعر `SANF_PRICE`)
      ثم (القصّاص · الخيّاط · المرحلة) بفواصل ولون تمييز؛ حُذف الرف والمصدر، وأصبحت «النوع»
      «العرض» لأن قيمتها الفعلية «عرضية/ضيقة».
- [x] **الخادم:** `detailSql` صار يجلب `OHID, OHDID, SANF_PRICE` وأسماء القصّاص/الخيّاط الرقمية،
      والقطعة تُرسل بـ `ohdid` + `price` (سعر القطعة الذي طلبه المستخدم). إجمالي الفاتورة وخصمها
      وصافيها ما زالت خارج المسار، والاختبار يحرس ذلك.
- [x] **إصلاح أعطال تخطيط:** `Expanded` داخل تمرير أفقي بعرض غير محدود كان يسقط
      (`invalid constraints` / `hasSize`) — صُحّح بحساب العرض صراحة (`LayoutBuilder` + `SizedBox`)
      و`IntrinsicHeight` لصففي كل قماش لأن `CrossAxisAlignment.stretch` لا يعمل داخل تمرير رأسي
      لا محدود.
- [x] **إصلاح طلب مكرّر:** كان `initState` يطلق حملاً ثانياً فوق حمل المزوّد نفسه (طلبان لقائمة
      واحدة) — أُضيف حارس `isLoading` في نافذة الموديلات وقائمة العملاء معاً.
- [x] **شريط الفلترة:** أُعيد إليه مفتاح «المقاسات الفارغة» كمصدر وحيد للحالة (لوحة المقاسات
      تنفّذ فقط)، مع منع ابتلاع مسافة البحث بتتبّع آخر نص أرسله الحقل (`_lastEmitted`).
- [x] **نموذج العميل:** `ohdId` يقرأ المفتاح `ohdid` نفسه الذي يرسله الخادم في قسم التفصيل.
- [x] **اختبارات:** `measurement_model_picker_sheet_test.dart` (4: نافذة لا AppBar، إرجاع المفتاح
      الرباعي، إرسال البحث والترتيب، الحالة الفارغة) وتحديث اختبارات الشاشة إلى 15 (أعمدة الأقمشة
      المطلوبة، غياب الحقول المحذوفة، رف/مصدر غائبان) — **عملاء المقاسات 38 ناجحاً**.
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` الكاملة = **456 ناجحاً و5 متجاوزة**.
- [ ] **متبقٍّ (بيئة):** `php artisan test --filter=CustomerMeasurement` لم يكتمل — اتصال أوراكل
      المحلي ما زال رافضاً (`ORA-12514` على `localhost:1521/orclrd`)؛ اختبارات الخادم التسعة كانت
      قد مرّت على القاعدة الحيّة قبل الانقطاع، وتُعاد بعد عودة الخدمة. المسارات الجديدة في
      `detailSql` لا تُختبر منطقياً قبل ذلك.
- [ ] **متبقٍّ (قاعدة):** تسميا «جيب جانبي» و«جيب الصدر» المذكورتان في الطلب يحتاجان التحقق من
      أعمدة `SALES_DETAILES_SHAPES` عند عودة الاتصال؛ الحالي المعروض هو المثبت فقط.

**النموذج:** Qoder · **الوقت:** 2026-10-29 06:47 · **لا DDL** · **لا DML** (لا كتابة في هذه المراجعة) · **لا commit** (لم يُطلب).

---

## إصلاح ظهور العربية كرموز في طباعة/تصدير كل الكشوفات (PDF) — 2026-10-29

**المُنفِّذ:** Qoder · **الوقت:** 2026-10-29 07:15 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

- [x] تحليل مشترك: كل المولّدات تستخدم `pdfArabic`+`theme`+`kPdfShapedTextDirection`؛ فحص
      `flutter test` أثبت أن Cairo يغطي `U+FE70..U+FEFF` متى توفّر، وأن السبب الجذري هو
      اعتماد تحميل الخط من الإنترنت وقت التشغيل عبر `PdfGoogleFonts` (يفشل على LAN بلا إنترنت
      ← سقوط إلى Helvetica ← العربية رموز).
- [x] تضمين `assets/fonts/Cairo-Regular.ttf` و`Cairo-Bold.ttf` وتسجيل `- assets/fonts/` في `pubspec.yaml`.
- [x] إعادة كتابة `lib/core/utils/report_pdf_fonts.dart` ليقراء من `rootBundle`+`pw.Font.ttf`
      مع إبقاء `PdfGoogleFonts` كـ fallback أخير فقط.
- [x] إضافة `test/core/report_pdf_fonts_test.dart` (تحميل محلي + تغطية كاملة + أن الخط Cairo).
- [x] البوابة: `flutter analyze` = No issues found! · `flutter test` = 458 ناجحاً و5 متجاوزة.

- [ ] **متبقٍّ (تحقّق ميداني):** إعادة بناء APK وتثبيتها على الهاتف ثم تجربة زرّي الطباعة/التصدير
      في كشف واحد على الأقل للتأكد بصرياً أن العربية تظهر صحيحة بعد التضمين المحلي.
- [ ] **متبقٍّ (اختياري):** خط الشاشة (google_fonts) ما زال ينزّل Cairo وقت التشغيل؛ إن ظهرت
      نفس العلة على شاشة بلا إنترنت يُنقل هو أيضاً إلى الأصل المضمّن.

---

## 2026-10-30 23:24 — أيقونات تواصل صغيرة + شاشة دخول على شاشة واحدة

- [x] **العميل:** `ContactIconButton` جديد (دائرة 36px، أيقونة وحدها، `Tooltip` يحمل المعنى) —
      ودجت مشترك بين قسم المطور وشاشة الدخول.
- [x] **العميل (قسم المطور):** صف واحد = الصورة الرمزية + الاسم والوصف + أيقونة اتصال + أيقونة
      واتساب؛ حُذف صف الزرّين العريضين. تلميح الاتصال = `+967 776 422 777`، وتلميح واتساب = «واتساب».
      بوابة النقر الخمسي على الاسم كما هي.
- [x] **العميل (شاشة الدخول):** حُذف سطر «الإصدار» واستُبدل بـ`_CompanyContactBar`: أيقونة اتصال
      وأيقونة واتساب لرقم **الشركة** من `APP_SETTINGS` (`company_phone`)، وتُخفيان معاً إن كان الحقل فارغاً.
- [x] **العميل (الروابط):** `internationalDigits()` + `openWhatsappTo()` — رابط `wa.me` من الأرقام
      الدولية بلا `+` ولا مسافات، ويستفيد منه `buildTelUri` أيضاً.
- [x] **العميل (ملاءمة الشاشة):** `_LoginLayout` يشتق مقياساً من ارتفاع النافذة (0.62..1.0) يضبط
      الشعار والحشوات والفراغات، ويُخفى السطر التعريفي تحت 660px؛ التمرير بقي شبكة أمان فقط.
- [x] **الاختبارات:** 3 حالات جديدة لشاشة الدخول (أيقونتان تحت زر الدخول · غيابهما بلا رقم · البطاقة
      كاملة على 360×640 بلا تمرير) + مجموعة `internationalDigits` + تشديد حالة قسم المطور
      (تلميح بدل نص، سطر واحد).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **462 ناجحاً (5 متجاوزة)** ·
      `test/features/app_info` = 22 ناجحاً · لا تغيير في الخادم أو القاعدة.

**النموذج:** Qoder · **الوقت:** 2026-10-30 23:24 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 02:12 — «مقاسات العملاء»: مراجعة تصميم نهائية + نافذة الموديلات + مواصفات وأقمشة مضبوطة بالقاعدة الحيّة

- [x] **قائمة الموديلات (منبثقة):** لا يظهر نص «بلا مستفيد محدّد» أبداً؛ عند غياب المستفيد يعرض
      السطر اسم العميل نفسه (`MeasurementModelTile.customerName`)، ويُلغى `beneficiaryLabel` من
      النموذج لأن لا مستعمل له بعد الآن. الاختبار: «a model with no beneficiary is titled with
      the customer name».
- [x] **لوحة تصميم عالية التباين (`measurement_kit.dart`):** ترويسة قسم بتدرج Accent فعلي
      (0.34→0.12) وحد سفلي 1.6 وشارة أيقونة مصمتة، عنوان 14w800، تسمية حقل `textSecondary` w700
      وقيمة `textPrimary` w800، وفواصل الشبكة بلون `gridRule` (ثانوي 0.35) لا `border` الباهت —
      وهي دالّة تُقرأ وقت الرسم لأن اللوحة قابلة للتهيئة من الخادم.
- [x] **اسم العميل مرة واحدة:** حُذف من «بيانات العميل» ومن سطور الأقسام الفرعية؛ يبقى في عنوان
      الشاشة فقط، وسطر الحالة يحمل المستفيد/الفاتورة بلا تكرار الاسم.
- [x] **تفاصيل العميل في صف واحد:** `MeasurementFieldGrid(singleRow: true)` بخانات أضيق (96) —
      رقم الهاتف · رقم العميل · رقم الحساب في سطر واحد.
- [x] **المستفيد غائب ⇒ خانة غائبة:** الحقل مشروط بـ `model?.beneficiary != null` فلا يظهر لا
      هو ولا بديله، واخْتُبر ذلك بـ «a model without a beneficiary hides the field instead of announcing it».
- [x] **مواصفات الموديل (بالقاعدة الحيّة عبر موصل oracledb):** بالطلب: نوع الأزرار · نوع الكم ·
      نوع الرقبة · **جيب جانبي** · نوع الجبزور · **جيب الصدر**، ثم نوع الكباك · عدد الأزرار ·
      جيب الجوال · نوع الحجازي. `POCKET_OR_WITHOUT` معبأ في 83,395 من 84,971 صفاً وقيمته
      «جيوب/بدون/جيوب شمال/جيوب يمين» فهو الجيب الجانبي فعلاً؛ `MOBILE_POCKET` معبأ 83,245؛
      `SHAPE_POCKET_UP_NO` هو الأقرب لجيب الصدر (12 صفاً) ويظهر عند وجوده فقط؛ و`PEN_POCKET`
      فارغ في كل الصفوف (0) فأُزيل.
- [x] **الأقمشة:** حُذف عمود الترقيم `#` نهائياً، وحُذف التمرير الأفقي: البطاقة تُبنى بأوزان
      نسبية (`_firstLineWeights`) داخل عرض الشاشة — السطر الأول (رقم الطلب · القماش · العرض ·
      اللون · هنش · ياردة · السعر) والثاني (القصّاص · الخيّاط · المرحلة) بفاصل رأسي لكل خانة.
      «العرض» هو `CLOTH_TYPE` وقيمته الحيّة «عرضية» في 37,077 صفاً (تُثبت صحة التسمية)، و
      `OHDID` يصل 11 رقماً (مثال: 26211325025) فأُعطى نصيباً من العرض قبل اسم القماش.
      حُذف الرف والمصدر من الشاشة والمطبوع معاً.
- [x] **الخادم:** `detailSql` يجلب `OHID, OHDID, SANF_PRICE, CUTTER_NO1, TAILOR_NO1` ومفتاح
      `ohdid` مطابق لما يرسله متحكم التفصيل (النموذج الواحد يقرأ الاثنين)؛ وسعر القطعة هو المال
      الوحيد في المسار — إجماليات الفاتورة ما زالت خارج أي استعلام.
- [x] **تحقق من القاعدة عبر `oracledb` MCP (قراءة فقط):** استعلام التفصيل الكامل أُجري على
      فاتورة حيّة `(19405/2026/82755)` وأعاد 55 صفاً بلا خطأ، وعيّن القيم: `OHDID` و`SANF_PRICE=2000`
      و`CLOTH_TYPE=عرضية` ومسمّيات قصّاص/خيّاط مختلفة لكل قطعة (يُثبت تقسيم السطحين).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **464 ناجحاً (5 متجاوزة)** ·
      `test/features/customers` = **40 ناجحاً**.
- [ ] **متبقٍّ (بيئة):** `php artisan test` لا يزال متعثراً: اتصال التطبيق المحلي
      (`localhost:1521/orclrd`) مرفوض بـ `ORA-12514` بينما الموصل البعيد (`26.160.119.159:1521/orcl`)
      يعمل — لم يُغيَّر `.env` (قرار صاحبة البيئة). عند عودة الاتصال تُعاد حزمة
      `CustomerMeasurement` (9 اختبارات) للتأكد من استجابة HTTP لا SQL فقط.
- [ ] **متبقٍّ (خيار):** «جيب الصدر» لا عمود نصي له في `SALES_DETAILES_SHAPES`؛ المعروض الآن هو
      `SHAPE_POCKET_UP_NO` عند وجوده. إن أراد المستخدم حقلاً نصياً فذلك يحتاج عموداً في القاعدة
      (قرار نموذج إرثي لا يُتخذ من التطبيق).

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:12 · **لا DDL** · **لا DML** (قراءة فقط عبر oracledb MCP) · **لا commit** (لم يُطلب).

---

## 2026-10-31 02:39 — شعار واتساب الرسمي في المواضع الثلاثة

- [x] **الاعتماد:** `font_awesome_flutter: ^10.7.0` في `pubspec.yaml` + `flutter pub get` ناجح
      (`pubspec.lock` محدَّث) — Material Icons لا تحوي شعار واتساب أصلاً.
- [x] **العميل:** `WhatsAppIcon` جديد (شعار العلامة الرسمي، أخضر واتساب، `semanticLabel: 'واتساب'`).
- [x] **العميل (المطور):** أيقونة واتساب في سطر الاسم صارت الشعار الرسمي؛ وأيقونة الاتصال
      `FontAwesomeIcons.phone` لتوافق الوزن البصري.
- [x] **العميل (الاستفسار):** زر «واتساب» في قسم الاستفسار والمساعدة صار الشعار الرسمي.
- [x] **العميل (الدخول):** `_CompanyContactBar` تحتهما: اتصال + واتساب رسمي لرقم الشركة من
      `APP_SETTINGS`، وتُخفيان معاً إن كان الحقل فارغاً؛ وبطاقة الدخول كاملة بلا تمرير (`_LoginLayout`).
- [x] **العميل:** `ContactIconButton` يقبل `Widget icon` بدل `IconData` كي يحمل شعار العلامة.
- [x] **الاختبارات:** `find.byType(WhatsAppIcon)` بدل رموز Material في الشاشتين، و`findsNothing`
      لـ`Icons.chat_rounded`/`chat_outlined`، مع بقاء تأكيدَي الموضع والتلميح.
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **464 ناجحاً (5 متجاوزة)** ·
      اختبارات الشاشتين = **39 ناجحاً** · لا تغيير في الخادم أو القاعدة.

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:39 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 — إصلاح إخفاقات اللقطات البصرية الخمسة للرئيسية + مزامنة أرقام التوثيق

- [x] **الخلل:** `flutter test` على هذا الجهاز أعاد **5 إخفاقات**، كلها في `home_visual_test.dart`
      (`home_mobile` · `home_mobile_small` · `home_mobile_three` · `home_mobile_four` · `home_desktop`).
      السبب أن `KY_VISUAL=1` **مثبّت في بيئة المستخدم**، فاختبارات اللقطات لا تُتجاوز كما يفترض تعليقها.
- [x] **سببان متتاليان:** (1) اللقطات قدُمت بعد توسيع كتالوج اختصارات الرئيسية (بطاقة
      «مقاسات العملاء» و«استعراض فاتورة تفصيل» و«كشف حسابي المالي»)؛ (2) `HomeHeader` يكتب التحية
      والتاريخ من ساعة الجهاز، فأي لقطة تفشل تلقائياً في الغد ولو لم يتغيّر سطر واحد — عيب في الاختبار
      لا في الشاشة.
- [x] **العميل:** `HomeDashboardScreen` يقبل `now` اختيارياً ويُمرّره إلى `HomeHeader`
      (`HomeHeader.now` كان موجوداً أصلاً لغير هذا الغرض؛ التشغيل يبقى `DateTime.now()`).
- [x] **الاختبار:** `home_visual_test.dart` يثبّت `DateTime(2026, 10, 22, 9, 15)` فيمرّ اللقطة
      بعد اليوم نفسه، وأُعيد توليد الصور الخمس في `test/goldens/` وراجعتها بالعين (البطاقة الجديدة
      ظاهرة، والتباعد والألوان سليمة).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **474 ناجحاً، صفر إخفاق**
      (عدد أكبر من 469 السابق لأن الخمسة صارت تُنفَّذ لا تُتجاوز).
- [x] **التوثيق (أرقام كانت قديمة):** `AGENTS.md` = 138 مساراً (6 عام · 6 جلسة · **126** محروس)،
      الكتالوج **147 كوداً / 25 قسماً**؛ و`kyApp_API/AGENTS.md` جرده صُحّح من `route:list` الفعلي:
      customers **10** · workers **22** · accounts **24** · tailoring **5** (كان غائباً) · services على
      `services.update` (لا يوجد `services.create`/`services.delete` في الكتالوج).
- [x] **الخادم (تحقق بلا قاعدة):** `php -l` على `app/`+`routes/`+`database/` سليم · `pint --test` نظيف ·
      `route:list` = 138 مساراً · مرآة الأكواد بين الخادم والعميل **متطابقة 147/147** (لا كود زائد ولا ناقص).
- [ ] **متبقٍّ (بيئة):** `php artisan test` ما زال يسقط بـ `ORA-12514` (خدمة `orclrd` غير مسجّلة على
      المستمع المحلي) — 127 إخفاقاً كلها اتصال لا كود؛ يُعاد عند عودة القاعدة.

**النموذج:** Qoder · **الوقت:** 2026-10-31 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 — تدقيق تنفيذ خطة «مقاسات العملاء» بنداً بنداً + إغلاق الفجوات

- [x] **الجرد:** كل ملفات §5.2 موجودة (`measurement_customer_model` · `measurement_model_ref` ·
      `customer_measurement_repository` · `customer_measurement_providers` ·
      `measurements_customers_screen` · `measurement_view_screen` · `measurement_customer_tile` ·
      `measurement_model_tile` · `measurement_filter_bar` · `customer_measurement_pdf_builder`)،
      و§4.1–§4.4 و§6 و§7 منفّذة. الفروق عن نص الخطة كلها **مطلوبة من المستخدم بعدها** وموثّقة في
      `user_commends.md` 02:12: نافذة الموديلات المنبثقة بدل الشاشة الثابتة، وحذف
      (العنوان · مجموعة الحساب · الشكل · رقم الموديل · الفرع) وتفاصيل العميل في صف واحد.
- [x] **فجوة أُغلقت (بند §4.5):** حدث `customers.measurements_listed` كان يُسجَّل بـ
      `entity_type = customer_measurement`، والجدول المتفق عليه يخصّه `entity: customer` لأن البحث
      يخصّ العميل لا موديلاً. صُحّح في `CustomerMeasurementController::index`.
- [x] **`pint` كامل:** `vendor/bin/pint --test` كان يفشل في ثلاثة ملفات **خارجة عن القسم**
      (`AppendSessionExpiry.php` · `routes/web.php` · `tests/Feature/MyStatementTest.php`) — أُصلحت
      تنسيقياً والآن `{"tool":"pint","result":"passed"}`، و`pint --dirty` نظيف أيضاً.
- [x] **بوابات القسم (بند §7):** `php artisan route:list --path=customers/measurements` = **4 مسارات** ·
      `php -l` للمتحكم نظيف · `flutter analyze` = **No issues found!**.
- [x] **اختبارات الخادم على قاعدة حيّة (بند §4.6) — أقوى دليل حتى الآن:** `localhost:1521/orclrd` ما
      زال مرفوضاً (`ORA-12514`)، فشُغِّلت الحزمة على الموصل البعيد **بتجاوز متغيّرات بيئة للعملية
      وحدها** (`DB_HOST=26.160.119.159`, `DB_SERVICE_NAME=orcl`) بلا أي تغيير في `.env`:
      `CustomerMeasurementTest` = **9 اختبارات / 157 تأكيداً ناجحاً**، و`TailoringTest` +
      `BusinessRoutesSealedTest` + `IbacCoreTest` = **41 ناجحاً** منها كل اختبارات التفصيل والمسارات
      المحروسة.
- [ ] **إخفاق واحد غير متعلق بالقسم:** `IbacCoreTest > the policy clock is the database clock`
      يقارن ساعة أوراكل بساعة PHP بسماحية ثانيتين، وعلى اتصال بعيد (>250ms ذهاباً وإياباً) بلغ
      الفارق **2.05s** فسقط. الحل المقترح عند الطلب: رفع السماحية إلى 5s أو مقارنة على الاتصال المحلي
      فقط — لم يُغيَّر لأنه قرار اختبار قائم لا يخصّ المقاسات.

**النموذج:** Qoder · **الوقت:** 2026-10-31 · **لا DDL** · **DML:** صفوف `APP_USER_ACTIVITY` التي يكتبها
اختبار الطباعة/التصدير وحده · **لا commit** (لم يُطلب).

---

## 2026-10-31 05:17 — قسم الاستفسار يخاطب الشركة، والهوية الافتراضية تعمل بلا اتصال

- [x] **العميل (قسم الاستفسار):** صار `ConsumerWidget` ويقرأ `contactPhone` من
      `appConfigNotifierProvider` بدل `kDeveloperPhone`/`kDeveloperWhatsappUrl` — فالشكوى تصل إلى
      الشركة لا إلى المطوّر. «اتصال» ⇒ `openTel`، و«واتساب» ⇒ `openWhatsappTo` على الرقم نفسه.
- [x] **العميل (تلميح مفيد):** `Tooltip` على الزرّين يحمل الرقم المكتوب (ضغط مطوّل) — ويُثبت في
      الاختبار أن الرقم هو رقم الشركة.
- [x] **العميل (الافتراضي):** `AppConfigModel.defaults()` صار يحمل الهاتف `780154000` والعنوان
      `الجراف- جوار بيت الشايف` (كان الهاتف فارغاً والعنوان يحمل `'967780154000'` بالخطأ).
- [x] **العميل (حل الفراغ):** `static const fallbackCompanyPhone` + `String get contactPhone` —
      أي فراغ قادم من كاش قديم يُصلَح بالافتراضي، فلا تختفي أيقونتا الدخول بانقطاع الـ API.
- [x] **الخادم:** `AppConfig::DEFAULTS` صار يحمل العنوان والهاتف الحقيقيين، فـ`publicPayload` لا
      يُعيد فراغاً لعمود الهاتف أبداً.
- [x] **الاختبارات:** 3 حالات في `app_config_model_test.dart` + حالتان في شاشة المعلومات + حالتان
      في شاشة الدخول (بلا اتصال · رقم فارغ).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **470 ناجحاً (10 متجاوزة)** ·
      `php artisan test --filter=AppConfig` = **9 ناجحاً / 33 تأكيداً** (على القاعدة البعيدة، لأن
      `localhost:1521/orclrd` ما زال `ORA-12514`) · `php -l` نظيف · `pint` نظيف.

**النموذج:** Qoder · **الوقت:** 2026-10-31 05:17 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-31 06:12 — التفصيل: قائمة فواتير منسّقة، تباين أقوى، وأقمشة/حركة بلا تمرير أفقي

- [x] **قائمة اختيار الفاتورة:** البطاقة صارت سطرين: هوية (الرقم/السنة · العميل · حالة التسليم) وفاصل كامل العرض، ثم صف حقول شبكي (التاريخ · الهاتف · الرقم اليدوي · الموديلات · القطع · الصافي) بدل الفقرات المتتابعة. وأُضيف سطر نطاق أعلى القائمة («تُعرض الفواتير المُسندة إلى قصّاص وخيّاط فقط») مع عدّاد النتائج في شارة، وحُوِّلت التلميحات والنصوص إلى `textSecondary` بوزن 600–800.
- [x] **التباين:** التسمية 10.5 بوزن 700، القيمة 13 بوزن 800، رؤوس الجداول 10–10.5 بوزن 800، الشارات 11 بوزن 700، وإطار الشبكة والفواصل 0.9 بكسل بلون الحدّ الكامل بدل الخطوط الشبه الشفافة.
- [x] **بيانات الفاتورة:** جميع حقولها (المرجع · تاريخ التسليم · الاستحقاق · العملة · الحالة · الموديلات · القطع) في **صفّين فقط** عبر `TailoringInfoGrid(rows: 2)`.
- [x] **بيانات العميل:** الاسم ملتصق بعنوان القسم مباشرةً (خيار `titleTrailing` جديد في إطار القسم) لا في أقصى الطرف، ثم صف واحد: الهاتف · رقم العميل · رقم الحساب.
- [x] **تفاصيل الدفع:** الأرقام الأساسية في صف واحد.
- [x] **الأقمشة:** جدول بعشرة أعمدة مرنة (رقم الطلب = `OHDID` · القماش · العرض · اللون · هنش · يارده · السعر ، ثم القصّاص · الخيّاط · المرحلة) بلا عمود «#» ولا رف ولا مصدر، وكل قماش في **سطرين** متطابقين في الشبكة نفسها، و**بلا تمرير أفقي** (الأعمدة تتقاسم عرض البطاقة).
- [x] **سجل الحركة:** للقماش (`OHDID`) لا للموديل، وخمسة أعمدة فقط (الحالة · التاريخ · العدد · المنفذ · ملاحظة) في صف واحد لكل حركة، و**بلا تمرير أفقي**.
- [x] **إصلاح تجاوز:** شريط عنوان القسم صار العنوان وعنصره الملتصق داخل مساحة مرنة واحدة، فاختفى تجاوز 318 بكسل على شاشة 360.
- [x] **التحقق:** اختبارات التفصيل **54** ناجحة · الحزمة الكاملة **470 ناجحاً و10 متجاوزة** · `flutter analyze lib` = **No issues found!** · Pest `Tailoring` **11 ناجحاً / 229 تأكيداً** · pint على ملفات التفصيل = PASS.

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:12 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-31 06:43 — التفصيل: قائمة فواتير مدمجة، أقمشة قابلة للتحديد، وسجل حركة للقماش المختار

- [x] **قائمة اختيار الفاتورة** أُعيدت إلى **قائمة صفوف** لا بطاقات ولا جدول: كل فاتورة سطر واحد منخفض (`الرقم/السنة · العميل · التاريخ · الصافي · حالة التسليم`) بحشو 7 رأسي، والقائمة ممتدة الحواف بفواصل 0.7 بدل الهوامش — عشرات الفواتير في الشاشة الواحدة. وأُزيلت الفواصل الإضافية وسطر النطاق، وبقي عدّاد النتائج في سطر الفلترة.
- [x] **قائمة الأقمشة صارت قابلة للتحديد**: كل قماش كتلة بسطر عنوان (رقم القماش · اسمه · مرحلته) ثم **سطرين**: (رقم الطلب `OHDID` · القماش · العرض · اللون · هنش · يارده · السعر) و(القصّاص · الخيّاط · المرحلة). الحقول أزواج «تسمية: قيمة» داخل `Wrap` تتجاوز تلقائياً مع العرض بلا قصّ ولا تمرير أفقي. الكتلة المختارة تُبرَز بخلفية وشريط جانبي.
- [x] **سجل الحركة للقماش لا للموديل**: اختيار قماش يغيّر السجل إلى سجل `OHDID` ذلك القماش، وعنوان القسم يذكر اسمه ورقمه. ولا سجل بلا اختيار: رسالة صريحة «اختر قماشاً…».
- [x] **جدول الحركة**: خمسة أعمدة فقط (الحالة · التاريخ · العدد · المنفذ · ملاحظة)، رأس واحد وصف لكل حركة، بأعمدة مرنة ونصوص تلتفّ (softWrap) فتظهر كاملة بلا تمرير أفقي.
- [x] **التحقق:** اختبارات التفصيل **55** ناجحة (منها: اختيار القماش الثاني يغيّر السجل من صوف إلى قطن) · الحزمة الكاملة **471 ناجحاً و10 متجاوزة** · `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:43 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-31 07:15 — التفصيل: بطاقات الفواتير وقسم الأقمشة وتفاصيل المقاسات على نمط شاشات «مقاسات العملاء»

- [x] **قائمة اختيار الفاتورة** عادت **بطاقات** كاملة التفاصيل بنفس شكل `MeasurementCustomerTile`: شريط لوني على الحافة · مربّع رقم الفاتورة وسنتها · اسم العميل بخط 13.5/800 · سطر ثانوي (التاريخ · الهاتف · الرقم اليدوي) · عمود يمين بشارات العدّادين (`N موديل` · `N قطعة`) والصافي الأخضر الداكن ونقطة الحالة وسهم الفتح. القائمة `ListView` بمسافة 8 بين البطاقات وحشو 12 — لا جدول ولا صفوف مضغوطة.
- [x] **قسم الأقمشة** بنفس شكل `MeasurementFabricsPanel`: بطاقة لكل قماش بحدود ملوّنة، سطر أول بسبعة أعمدة موزونة (رقم الطلب `OHDID` · القماش · العرض · اللون · هنش · ياردة · السعر) بفواصل رأسية ظاهرة، ثم خط فاصل سميك، ثم سطر ثانٍ (القصّاص · الخيّاط · المرحلة). الخطوط أكبر من الطقم الأصلي (تسمية 9.5/700 وقيمة 13/900) والقيم تُصغَّر تلقائياً بدل القصّ، فلا تمرير أفقي ولا نصّ مخفي. البطاقة قابلة للضغط: اختيارها يغيّر سجل الحركة.
- [x] **قسم تفاصيل المقاسات** بنفس شكل `MeasurementMeasurementsPanel`: شبكة أعمدة متساوية بفواصل رأسية وأفقية (`tailoringGridRule`)، كل خانة تسميتها من `GENERAL_LABELS_CODING` وقيمتها رقم كبير (13/900) مع تصغير تلقائي، ومفتاح «إظهار الكل» في شريط العنوان.
- [x] **جديد:** `presentation/widgets/tailoring_cells.dart` — `TailoringCell` و`TailoringCellRow` و`TailoringCellGrid` (نسخة موسّعة التباين من طقم المقاسات دون المساس به).
- [x] **التحقق:** اختبارات التفصيل **55** ناجحة · الحزمة الكاملة **471 ناجحاً و10 متجاوزة** · `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-10-31 07:15 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-31 09:38 — التفصيل: حقل «العرض» صار رقم القماش (58/45/38) لا كلمة CLOTH_TYPE

- [x] **الخادم:** `detailSql` يربط `ACCOUNTS.MULTI_CLOTHS` على مفتاح القطعة (`BILL_NO`, `YEAR`, `SEQ_NO`, `SEQ_NO1`) ويُعيد `cloth_width`، وعمود العرض يُكتشف مرة واحدة من `ALL_TAB_COLUMNS` بين أسماء محتملة (`CLOTH_WIDTH`, `WIDTH`, `CLOTH_W`, `W`, `CLOTH_SIZE`) — بلا تخمين: إن غاب العمود عادت الخانة `CAST(NULL …)`.
- [x] **العميل:** `CuttingPieceItem.clothWidth` من `cloth_width`، وخلية «العرض» في بطاقة القماش تعرض الرقم (58/45/38) بدل «عرضية/ضيقة».
- [x] **سلوك آمن:** أي فشل في قاموس القاعدة لا يُسقط الفاتورة — الخانة تبقى «—» والبقية تُعرض عادي.
- [x] **التحقق:** اختبارات التفصيل **55** ناجحة · `flutter analyze lib` = **No issues found!** · `php -l` و`pint` على المتحكم = نظيف.
- [!] **غير متحقَّق حياً هذه المرة:** خدمة Oracle عند `localhost:1521/ORCLRD` غير متاحة الآن (`ORA-12514`)، فتعذّر تشغيل Pest `Tailoring` (9 فشل اتصال) وتعذّر تأكيد اسم عمود العرض الفعلي. بمجرد عودة الخدمة يعمل الاكتشاف تلقائياً بلا تعديل كود.

**النموذج:** Qoder · **الوقت:** 2026-10-31 09:38 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 00:20 — iOS: تهيئة المشروع وبناء IPA غير موقَّع + خطة تثبيته على الآيفون

- [x] **القيد:** جهاز المطوّر Windows، ولا يوجد Mac ولا حساب Apple Developer. اعتُمد المسار
      المجاني الوحيد: **Codemagic** (500 دقيقة macOS شهرياً) → IPA **غير موقَّع** → **Sideloadly**
      على ويندوز + **Apple ID مجاني** (صلاحية 7 أيام).
- [x] `ios/Runner/Info.plist`: إضافة `NSAppTransportSecurity` (`NSAllowsArbitraryLoads` +
      `NSAllowsLocalNetworking`) لأن الـAPI يُضبط وقت التشغيل وقد يكون `http` على IP محلي،
      وإذن `NSPhotoLibraryUsageDescription` (غيابه كان **يُنهي التطبيق** عند اختيار الشعار من
      المعرض)، وإذن `NSLocalNetworkUsageDescription`، والاسم الظاهر `الكبودي`.
- [x] `ios/Runner.xcodeproj/project.pbxproj`: `com.example.kyApps` ← `com.alkaboudy.app`
      (3 مواضع + `RunnerTests`)، و`IPHONEOS_DEPLOYMENT_TARGET` 12.0 ← **13.0** (3 مواضع).
- [x] `ios/Podfile` جديد محفوظ في git: `platform :ios, '13.0'` + `use_modular_headers!` +
      `post_install` يوحّد حد كل Pod على 13.0 (كان الملف غائباً ويُولَّد في كل بناء).
- [x] `tools/ios_icons.py` وتوليد **15** أيقونة RGB بلا شفافية من `assets/logo1.png`
      (كانت أيقونة iOS هي شعار Flutter الافتراضي بينما أندرويد يحمل شعار الشركة).
- [x] `codemagic.yaml` جديد: workflow `ios-unsigned` (mac_mini_m2 · Flutter 3.29.3 · Xcode 16.2 ·
      `submodules: false`)، `flutter build ios --release --no-codesign` ثم تغليف `Payload/`
      بـ`zip -qry` وحفظ الـdSYM. لا شهادة ولا كلمة سر Apple في السحابة.
- [x] `ios_release_guide.md` جديد (9 أجزاء) موازٍ لدليل أندرويد: حدود الحساب المجاني، خطوات
      الإصدار والتثبيت، شرط الشبكة وATS، قائمة التجربة على الجهاز، جدول تشخيص الأخطاء،
      وخطة الترقية إلى حساب مدفوع.
- [ ] **متبقٍ على المطوّر (خارج قدرة ويندوز):** ربط المستودع في Codemagic ← Start new build ←
      تنزيل الـIPA ← تثبيته بـSideloadly على الآيفون (الخطوات التفصيلية: §4.3 من الدليل).
- [x] **التحقق:** `flutter analyze` = **No issues found!** · `codemagic.yaml` صالح (فحص YAML) ·
      الأيقونات الـ15 كلها مربّعة وبنمط RGB (بلا قناة alpha).

**النموذج:** Qoder · **الوقت:** 2026-11-01 00:20 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 00:57 — iOS: تصحيح `codemagic.yaml` — المخطط يرفض `clone.submodules`

- [x] **الخطأ الفعلي عند البناء:** `1 validation error in codemagic.yaml: ios-unsigned -> clone:
      extra fields not permitted`.
- [x] **السبب المثبت:** مخطط Codemagic الرسمي (`codemagic.io/codemagic-schema.json`) صارم
      (`additionalProperties: false`) **ولا يوجد فيه مفتاح `clone` إطاراً** على مستوى الـworkflow؛
      الحقول المسموحة فقط: `name` · `instance_type` · `max_build_duration` · `triggering` ·
      `inputs` · `environment` · `integrations` · `cache` · `when` · `working_directory` ·
      `pre_clone_scripts` · `scripts` · `artifacts` · `publishing` · `labels`.
- [x] **الحل:** حُذفت كتلة `clone: submodules: false` نهائياً، ووُضحت بدلها ملاحظة في الملف
      نفسه. الأثر: `kyApp_API` يُجلب تلقائياً عند clone الافتراضي — مستودع عام فلا فشل، وثوانٍ
      فقط من الزمن.
- [x] **تحقق مضاد للخطأ:** فُحصت مفاتيح الملف مفتاحاً مفتاحاً على المخطط الفعلي:
      لا حقول زائدة في الـworkflow ولا في `environment` (`flutter` 3.29.3 · `xcode` "16.2" ·
      `cocoapods` default · `vars`) ولا في `scripts` (`name` + `script` فقط مسموحان فكلاهما صحيح)،
      و`artifacts` قائمة نصوص كما يطلب.
- [x] **توثيق:** أُضيفت في `ios_release_guide.md` §3.3 قاعدة "مخطط صارم — لا مفاتيح غير معروفة
      ولا كتلة clone"، وفي جدول تشخيص الأخطاء §7 صف خاص بهذا الخطأ.
- [x] **التحقق:** `flutter analyze` = **No issues found!** (275.4 ثانية). الخطوة المتبقية: إعادة
      البناء من واجهة Codemagic.

**النموذج:** Qoder · **الوقت:** 2026-11-01 00:57 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:07 — iOS: إغلاق بوابات الجودة وضبط اتساق إصدار النظام

- [x] **`flutter test` (بوابة الخطة §ب-3):** **471 ناجحاً · 10 متجاوزة · 0 فاشل** — لا إخفاق
      جديد مقارنة بالمُوثَّق سابقاً (السجل: `.zwork/ios_gate_test.txt`).
- [x] **`flutter analyze`:** **No issues found!** (275.4 ثانية).
- [x] **اتساق إصدار iOS:** `ios/Flutter/AppFrameworkInfo.plist` ‏`MinimumOSVersion` من 12.0 إلى
      **13.0** ليُطابق `IPHONEOS_DEPLOYMENT_TARGET` و`ios/Podfile` (ثلاثة مواضع برقم واحد — لا
      تُترك متفاوتة).
- [x] **خطوة تشخيص في CI:** أُضيفت أول خطوة في `codemagic.yaml` تطبع إصدارات Xcode المثبتة
      (`ls -1 /Applications | grep -i '^xcode'`) — تُوفّر جولة بناء كاملة إن لم يتوفر 16.2.
- [x] **تحقق آلي (فحص آلي لا بالنظر):**
      - `Info.plist` يُحلَّل كـplist سليم و21 مفتاحاً، وفيه `CFBundleDisplayName=الكبودي` ·
        `NSPhotoLibraryUsageDescription` · `NSLocalNetworkUsageDescription` · `NSFaceIDUsageDescription` ·
        `NSAppTransportSecurity={NSAllowsArbitraryLoads: true, NSAllowsLocalNetworking: true}`.
      - `project.pbxproj`: `com.example` = **0** · `com.alkaboudy.app` = **6** ·
        `IPHONEOS_DEPLOYMENT_TARGET = 13.0` = **3** · `12.0` = **0**.
      - أيقونات: **19** مرجعاً في `Contents.json` كلها موجودة بالمقاس الصحيح ونمط **RGB** بلا شفافية.
      - `codemagic.yaml`: 6 خطوات · تطابق تام مع مخطط Codemagic (لا مفاتيح زائدة).
      - `git check-ignore`: لا شيء من ملفات الخطة مستثنى من git.
- [ ] **متبقٍ خارج قدرة ويندوز (بيانات/عتاد المستخدم):** ربط Codemagic ← بناء ← تثبيت بـSideloadly
      على الآيفون ← تنفيذ قائمة التجربة (§5 من `ios_release_guide.md`).

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:07 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:25 — iOS: إغلاق ثغرتين من README الحزم (Keychain + لغة النظام)

- [x] **الثغرة الأمنية/الوظيفية الأولى:** `flutter_secure_storage_darwin` يفرض صلاحية
      **Keychain Sharing** على iOS؛ بدونها تُعيد الكتابة نجاحاً ظاهرياً بلا تخزين فعلي —
      أي طرد المستخدم لشاشة الدخول في كل إقلاع وإلغاء التسجيل البيومتري. لم تكن الخطة
      تنص عليها ولم يكن للمشروع أي ملف entitlements.
- [x] **الحل:** ملفان جديدان `ios/Runner/DebugProfile.entitlements` و`Release.entitlements`
      يحملان `keychain-access-groups = $(AppIdentifierPrefix)com.alkaboudy.app`، وربطهما بهدف
      `Runner` عبر `CODE_SIGN_ENTITLEMENTS` في إعدادات Debug و Profile و Release، وإضافتهما
      إلى شجرة المشروع كمرجعين حقيقيين.
- [x] **الثغرة الثانية:** `share_plus` يطلب `CFBundleAllowMixedLocalizations` و`CFBundleDevelopmentRegion`.
      أُضيفا مع `CFBundleLocalizations = [ar]` — فتظهر حوارات النظام (أذونات الصور/الشبكة)
      وورقة المشاركة **بالعربية**، وهو ما يقتضيه تطبيق عربي أولاً كان إعلانه `$(DEVELOPMENT_LANGUAGE)` = en.
- [x] **حفظ سلامة ملف Xcode:** التعديل على `project.pbxproj` جرى بسكربت يتحقق من الحقن
      (مطابقة واحدة لكل مرساة) مع الحفاظ على نهايات **CRLF** وتوازن الأقواس — وتم التحقق بعده:
      `CODE_SIGN_ENTITLEMENTS` ×3 ({Profile: DebugProfile, Debug: DebugProfile, Release: Release}) ·
      `CRLF == LF` · الأقواس متوازنة · لا مفاتيح مكررة في `Info.plist`.
- [x] **توثيق:** `ios_release_guide.md` — خريطة الملفات، وجدول التعديلات (+4 صفوف)،
      وتنبيه أن الـentitlements ليست ترفاً، وصف تشخيصي لـ«تسجيل الخروج التلقائي»،
      والثابت رقم 7 في §9.
- [x] **التحقق:** 16 فحصاً آلياً (15 ناجحاً مباشرةً + فحصا الـentitlements أُعيدا بسبب تفسير
      PowerShell لـ`$(` فنجحا) — الملفان يحتويان القيمة الصحيحة فعلاً (plistlib + قراءة مباشرة).
- [ ] **متبقٍ خارج قدرة ويندوز:** البناء على Codemagic ← التثبيت بـSideloadly ← قائمة التجربة §5.

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:25 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:55 — إصلاح فشل البناء: `.gitignore` كان بترميز Windows-1256

- [x] **الخطأ من سجل Codemagic:** `flutter has exited unexpectedly: FileSystemException:
      Failed to decode data using encoding 'utf-8', path = '/Users/builder/clone/.gitignore'`
      مع أثر مكدّس يشير إلى `SwiftPackageManagerGitignoreMigration.migrate`.
- [x] **السبب الجذري:** ملف `.gitignore` في الجذر كان محفوظاً بترميز **cp1256** بسبب سطر تعليق
      عربي واحد، وأداة Flutter تقرأ هذا الملف **بترميز UTF-8 إلزاماً** في كل `flutter build ios`
      فتنهار قبل بدء البناء. لا علاقة للخطأ بأي إعداد iOS.
- [x] **الإصلاح:** حُوّل `.gitignore` إلى UTF-8 بلا BOM مع توحيد نهايات الأسطر على LF.
      **تحقق:** المحتوى مطابق حرفاً بحرف لما كان (51 سطراً · 32 نمطاً)، و`git diff` سطر واحد فقط.
- [x] **منع التكرار:** أداة جديدة `tools/check_encoding.py` (بوابة): تفصح عن الملفات غير UTF-8
      محلياً في ثانية، وتصلحها بـ`--fix`، وتُرجع رمز خروج ≠0 عند وجود ملف حرج معطوب.
      نطاقها الحرج: `.gitignore` · `ios/.gitignore` · `android/.gitignore` · `pubspec.yaml`،
      وتُبلغ عن بقية الملفات النصية للاستزادة (500 ملف).
- [x] **أداة جديدة ثانية:** `tools/ios_audit.py` — تُنفّذ الـ16 فحصاً الآلي التي كنّا ننفذها يدوياً
      (ATS/الأذونات/اللغة/المعرّف/إصدار النظام/ربط Keychain/الأيقونات/ملف البناء/الدليل).
- [x] **توثيق:** `ios_release_guide.md` — بوابة جديدة §4.2.1 للترميز مع نص الخطأ وطريقة إصلاحه،
      وإضافة الأمرين إلى قائمة §4.2، وصف تشخيصي في §7.
- [x] **أخبار مفرحة من السجل:** الآلة وفّرت **Xcode 16.2** (`/Applications/Xcode-16.2.app`) وCocoaPods
      1.16.2، و`flutter pub get` و`flutter analyze` و`pod install` نجحت — أي أن الخطر الأكبر
      (عدم توفر Xcode المطلوب) لم يقع.
- [x] **التحقق الآن:** `tools/ios_audit.py` = **ALL 16 CHECKS PASSED** ·
      `tools/check_encoding.py` = **RESULT: OK** (4 ملفات حرجة + 500 نصي).
- [ ] **الخطوة التالية للمستخدم:** commit + push ‏(‎`.gitignore` + `tools/` + الدليل) ثم إعادة
      `Start new build → ios-unsigned`.

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:55 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:10 — تحصين خط أنابيب البناء: بوابة ترميز داخل CI + تحقق من محتوى الـIPA

- [x] **الخطوة 2 جديدة في `codemagic.yaml` — `Encoding gate`:** تستخدم `iconv -f UTF-8 -t UTF-8`
      على `.gitignore` و`ios/.gitignore` و`android/.gitignore` و`pubspec.yaml`، وتُفشل البناء في
      ثانية برسالة صريحة تشير إلى `python tools/check_encoding.py --fix`. الهدف: نفس عطل الـcp1256
      لا يستهلك مجدداً 15–25 دقيقة صحيحة.
- [x] **الخطوة 8 جديدة — `Verify unsigned IPA`:** تقرأ `Info.plist` **من داخل** `Payload/Runner.app`
      بـ`plutil` (مدمج في macOS بلا اعتماديات) وتفشل إن غاب: معرّف `com.alkaboudy.app` ·
      `NSAllowsArbitraryLoads` · `NSAllowsLocalNetworking` · `NSPhotoLibraryUsageDescription` ·
      `App.framework` · `Flutter.framework`. مبدأها: «البناء نجح» ليس دليلاً على ملف صالح للتثبيت.
- [x] **تحقق من الخطوتين قبل الدفع (مهم):**
      - مطابقة مفاتيح المخطط الرسمي لـworkflow وenvironment وكل خطوة → سليمة.
      - `bash -n` (تحقق صرف) على الأوامر الثمانية → كلها سليمة.
      - **اختبار سلوكي فعلي لبوابة الترميز:** نجحت داخل المستودع (exit 0)، ورفضت مجلداً مؤقتاً
      فيه `.gitignore` بـcp1256 (exit ≠0) مع طباعة السبب وطريقة الإصلاح.
- [x] **توثيق:** `ios_release_guide.md` — جدول جديد §3.2.1 بخطوات الـworkflow الثماني وسبب كل واحدة،
      مع تنبيه أن الخطوة 8 هي مقياس النجاح الحقيقي.
- [x] `tools/ios_audit.py` صار يتحقق من 8 خطوات ومن وجود البوابتين بالاسم، **وصحة أوامرها**
      عبر `bash -n` (17 فحصاً إجمالاً) — فيكشف خطأً نحوياً في خطوة CI قبل الدفع.
- [x] **الحالة:** `ios_audit` = ALL 17 CHECKS PASSED · `check_encoding` = RESULT: OK ·
      تعديلات لم تُدفع بعد (6 ملفات معدّلة + أداتان جديدتان).
- [ ] **الخطوة التالية للمستخدم:** commit + push ثم `Start new build → ios-unsigned`.

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:10 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:23 — فحص جاهزية التثبيت على ويندوز + التأكد أن الإصلاح وصل GitHub

- [x] **تحقق الدفع (أزال لبساً حقيقياً):** `origin/main` المحلي كان قديماً فأظهر أن الإصلاح غير مدفوع؛
      والقياس الصحيح عبر `git ls-remote --heads origin` أظهر أن المستودع البعيد على
      **75f6420** = نفس `HEAD`. إذن Codemagic سيأخذ الإصلاح.
- [x] **قياس جاهزية التثبيت على جهازك (بيانات فعلية لا افتراض):**
      - Sideloadly مثبّت ويعمل (`sideloadly` + `sideloadlydaemon`).
      - iTunes المثبّت هو **نسخة Microsoft Store** (12139.12003.62022.0).
      - لا توجد خدمة `Apple Mobile Device Service` ولا مجلد
        `Common Files\Apple\Mobile Device Support` (منظومة السائق الكلاسيكية غائبة).
      - ويندوز يرى جهازاً باسم `Apple iPhone` بحالة **Unknown** (شاشة مقفلة/غير موثوق/سائق غير مربوط).
- [x] **الأثر:** إن لم يظهر الآيفون داخل Sideloadly فالسبب مُ‑شخَّص مسبقاً — يُثبَّت
      **iTunes الكلاسيكي x64** من apple.com (يجلب AMDS + `usbaapl64`).
- [x] **توثيق:** الدليل — قسم جديد **§4.3.0** «فحص جاهزية ويندوز» بأوامر PowerShell للتحقق،
      وتنبيه في §4.2 أن المرجع الموثوق للدفع هو `git ls-remote` لا `origin/main` المحلي،
      وتحديث صفّي تشخيص `Sideloadly لا يرى الجهاز` و`NP_E_CONN_FAILED`.
- [x] **التحقق:** `ios_audit` = ALL 17 CHECKS PASSED · `check_encoding` = RESULT: OK.
      (ملاحظة: `todo.md` و`devloping_history.md` و`codemagic.yaml` و`tools/` و`.gitignore`
      كانت قد دُفعت في 75f6420، ولم يبقَ غير تحديثات الدليل من هذه الجولة.)
- [ ] **الخطوة التالية:** من Codemagic `Start new build → ios-unsigned` على `main` (المدفوع).

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:23 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:35 — قياس جاهزية الشبكة والـAPI قبل التجربة على الآيفون

- [x] **النتيجة الحاسمة:** الـAPI **متوقف** — لا شيء يستمع على المنفذ 8000 على هذا الجهاز،
      و`http://127.0.0.1:8000/api/hello` يفشل، و`192.168.0.9:8000` (الافتراضي في التطبيق)
      لا يستجيب (timeout). أي محاولة دخول من الآيفون الآن ستنتهي بفشل اتصال **لا علاقة له بالتطبيق**.
- [x] **عناوين الجهاز المقيسة:** `192.168.0.11` (Ethernet) · `192.168.178.176` (Wi‑Fi) ·
      `26.210.208.234` (Radmin VPN) — ولا واحدة منها هي `192.168.0.9` المكتوبة في `api_constants`.
- [x] **نواقص بيئية مقيسة:** لا خدمة Laravel/PHP/NSSM (الموجود `bio-apache0` فقط)،
      ولا قاعدة جدار حماية للمنفذ 8000.
- [x] **سلامة حزم iOS:** فُحصت podspec الحزم الثماني — لا `static_framework` ولا مكتبات مضمّنة،
      فـ`use_frameworks!` + `use_modular_headers!` في Podfile لا يتعارضان مع أي منها.
- [x] **توثيق:** قسم جديد **§5.0.1** في الدليل بجدول القياسات، وأوامر تشغيل الـAPI وقاعدة
      جدار الحماية، والعنوان الصحيح لكل شبكة (واي فاي/إيثرنت) مع قاعدة فصل التشخيص
      (Safari أولاً ثم التطبيق).
- [x] **التحقق:** `ios_audit` = ALL 17 CHECKS PASSED · `check_encoding` = RESULT: OK.
- [ ] **قبل التجربة على الجهاز:** تشغيل الـAPI + قاعدة الجدار + التأكد من Safari على الآيفون.

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:35 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-01 — قسم المخازن (8 وحدات) — التنفيذ الكامل

**النطاق:** أوامر التوريد · أوامر الصرف · أوامر التحويل · المخازن والأمناء · الأصناف
(رئيسية/فرعية) · الوحدات والمجموعات · تقارير المخازن · الجرد.
**قرار المستخدم:** الكتابة في جداول النظام القديم مباشرة/ لا جدول جديد إطلاقاً/ الجرد بلا ترحيل.

### قاعدة البيانات (13 تسلسلاً فقط — بلا أي جدول)

- [x] `kyApp_API/database/oracle/09_stores_sequences.sql` — سكربت idempotent.
- [x] تنفيذ حيّ: 13 تسلسلاً أُنشئت (`SEQ_STORES_RCV` 536 · `ISS` 302 · `TRNM` 265472 ·
      `TRND` 2641710002 · `ITEM` 2184 · `ITEM_D` 101010001014 · `PSANF` 2188 · `STORE` 13 ·
      `GROUP` 10 · `TYPE` 28 · `UNIT` 12 · `CAT` 19 · `KEEPER` 1).
- [x] لا `CREATE TABLE` ولا `ALTER TABLE` (D13).

### الخادم (`kyApp_API`)

- [x] `app/Support/StorePolicy.php` — المخازن المستثناة 2/11/12، خرائط الأنواع، الترقيم، سقف التقرير.
- [x] `app/Support/InventoryLineGuard.php` — تحقق السطور من `SANFS_D` + كفاية الرصيد من `AVVG`.
- [x] `app/Support/PermissionCatalog.php` — 26 كوداً جديداً في وحدة `stores` (147 → 173).
- [x] 8 متحكمات تحت `app/Http/Controllers/Stores/` (المخازن · المرجعيات · الأصناف ·
      التوريد · الصرف · التحويل · التقارير · كشف الجرد).
- [x] `routes/api.php` — 31 مساراً، كل مسار بصلاحيته، والمسارات الحرفية قبل `{kind}`.
- [ ] **متبقٍ على الخادم:** تنفيذ `database/oracle/02_ibac_seed.php` لبذر الأكواد الـ26 في
      `APP_PERMISSIONS` (idempotent) — لازم قبل أن يعمل الحجب على الخادم.

### العميل (`lib/features/stores/`)

- [x] 5 ملفات نماذج + 4 مستودعات + 5 مزودات + 10 شاشات + 2 ويدجت + مولّد تصدير واحد.
- [x] `api_constants.dart` — مسارات القسم كاملة.
- [x] `permission_codes.dart` — 26 ثابتاً + `allPermissionCodes` + `permActionLabels`.
- [x] `portal_sections` — `stores_section.dart` صار يعيد `StoresDashboardScreen`.
- [x] `home_shortcut_catalog.dart` — 10 بطاقات مخازن (9 افتراضية + «المخازن والأمناء»).
- [x] تحديث `home_catalog_test` (25 افتراضية، `{'sales'}` وسمها) و`home_notifier_test` (26 نشِطة).

### البوابات

- [x] `flutter analyze` ⇒ **No issues found!**
- [x] `flutter test` ⇒ **All tests passed** (471 اختباراً قبل اختبارات المخازن + 18 اختباراً جديداً).
- [x] `php -l` على كل ملفات PHP الجديدة ⇒ بلا أخطاء نحوية.
- [ ] `vendor/bin/pint --dirty` — لم يُشغَّل (يتطلب `vendor/` على جهاز الخادم).

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** 13 `CREATE SEQUENCE` · **DML:** لا · **لا commit**.

### تكملة — الاختبارات والبذر (2026-11-01)

- [x] اختبارات Pest الأربعة: `StorePolicyTest` · `StoreOrderWriteTest` · `StoreReportTest` ·
      `StorePermissionTest` ⇒ 20 اختباراً أخضر.
- [x] اختبارات العميل: `store_models_test` · `report_filter_test` · `stock_sheet_test` ·
      `order_line_editor_test` · `item_form_validation_test` ⇒ 33 اختباراً أخضر.
- [x] تحديث `IbacCoreTest` و`TailoringTest` (147 → 173) و`home_catalog_test`/`home_notifier_test`.
- [x] إصلاح تسلسل الكتالوج (`SEQ_APP_PERMISSIONS` كان 186 أمام `MAX=188`) ثم بذر
      `02_ibac_seed.php`: 26 إدراجاً + 147 تحديثاً ⇒ `APP_PERMISSIONS` = 173.
- [x] إصلاح 5 أعطال حقيقية كشفتها الاختبارات: `ORA-00935` في الأرصدة/الجرد ت (ترتيب بـMAX)
      · `MANUAL_BILL_NO` غير موجود · فلتر نوع الحركة كان يرشّح نوع الصنف · `DISCOUNT_ACC`
      بدل `DISCOUNT_ACC_NO` + تطبيع مفاتيح OCI8 · انفجار `RenderFlex` في محرر السطور.
- [x] تحديث سجل `IbacCoreTest` للكتالوج الجديد.
- [ ] `vendor/bin/pint --dirty` لم يُشغّل (غير مطلوب لإغلاق الوحدة).

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** `ALTER SEQUENCE` واحد · **DML:** 26 إدراجاً · **لا commit**.

### تكملة — إغلاق تسلسلات التطبيق وسجل التدقيق (2026-11-01)

- [x] تشخيص جذر فشل `TailoringTest`/`CustomerMeasurementTest`: تسلسل `SEQ_APP_ACTIVITY`
      متأخر 271 رقماً (840 مقابل 569) ⇒ `ActivityLogger` كان يبتلع `ORA-00001` ولا يكتب شيئاً.
- [x] مسبار شامل على 6 أزواج (تسلسل ↔ جدول) — كشف أيضاً `SEQ_APP_USERS_PERM` (على الحد)
      و`SEQ_APP_SETTINGS` (على الحد).
- [x] إصلاح المتأخرات بنمط 11g (`INCREMENT BY gap` ← `NEXTVAL` ← `INCREMENT BY 1`):
      `SEQ_APP_ACTIVITY` ⇒ 842 · `SEQ_APP_USERS_PERM` ⇒ 268 · `SEQ_APP_SETTINGS` ⇒ قفزة واحدة.
- [x] حارس دائم: `kyApp_API/tests/Feature/SequenceIntegrityTest.php` (6 اختبارات dataset +
      اختبار إدراج فعلي داخل معاملة تُتراجع).
- [x] `StoreOrderWriteTest` صار يثبت أيضاً صف التدقيق `stores.receiving_created`.
- [x] حذف سكافيتات مؤقتة من `.zwork/` (3 مسبارات PHP + 4 ملفات مخرجات).
- [x] البوابات: `php artisan test` (المخازن + حارس التسلسلات) = 27/27 ·
      `TailoringTest|CustomerMeasurementTest` = 20/20 · `flutter analyze` = No issues ·
      `flutter test` = All tests passed.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** 3 تسلسلات · **DML:** لا · **لا جدول جديد** · **لا commit**.

### تكملة — جرد الخطة بنداً بنداً وإغلاق ثلاث فجوات (2026-11-01)

- [x] **§7.3 د** — التخطيط الرئيسي-التفصيلي: `ItemDetailScreen.embedded` + `ItemsListScreen._splitBody`
      عند `splitBreakpoint = 900`، والجوال يبقى `Navigator.push`، واللوحة تُلغى في التحديد المتعدد.
- [x] **§7.3 ب** — الإجراءات الجماعية: `invertSelection()` · `removeMany()` · `buildStoreOrderListPdf()`
      + طباعة/تصدير/حذف من شريط التحديد، والحذف خلف تأكيد لأنه فيزيائي.
- [x] **§7.3 أ + §12** — مؤشر «أصناف برصيد سالب»: `SUM(CASE WHEN SUM_TP < 0 ...)` في الخادم،
      `StoreModel.negative` · `StoresState.negativeCount` · بطاقة خامسة في لوحة القسم.
      التحقق الحي: 56 + 36 + 3 = **95** صفاً سالباً.
- [x] اختبارات جديدة: `items_split_test.dart` (3) · `orders_bulk_test.dart` (4).
- [x] **§9 بوابة Pint** — `vendor/bin/pint --dirty --format agent` شُغّل على 16 ملفاً، ثم أُعيد
      تشغيل اختبارات المخازن: 27/27 أخضر.
- [x] البوابات النهائية: `flutter analyze` = No issues · `flutter test` = **511 passed** ·
      `php artisan test` (المخازن + حارس التسلسلات) = 27/27.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

### تكملة — تفاصيل §7.3 (ح) الباقية من كشف الجرد (2026-11-01)

- [x] **تصفية رباعية**: `StockCountFilter` = الكل · بفرق فقط · زيادة · نقص · غير معدَّد،
      في صف شرائح أفقي، مع عدّاد «المعروض/الإجمالي» بجانب البحث.
- [x] **ملاحظة السطر**: `StockSheetState.notes` + `setNote()` + حوار لكل سطر،
      والملاحظة تعيش في الحالة فقط مثل الكمية الفعلية (لا تُرسل ولا تُحفظ).
- [x] **الملاحظة في التصدير**: عمود في XLSX، وعمود في PDF يظهر فقط إن وُجدت ملاحظة.
- [x] اختبارات: فلاتر الزيادة/النقص/غير المعدَّد/الكل + اختبار أن الملاحظة لا تُعدّ سطراً
      ولا تحرّك الفرق ⇒ `flutter test test/features/stores/` = **44 اختباراً أخضر**.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

### ملاحظة صدق — أعطال خارجة عن نطاق المخازن

في التشغيل الكامل للخادم (`php artisan test`) ظهرت **3 اختبارات حمراء لا علاقة لها بالمخازن**:
`AccountTreeExportTest` (اثنان) و`AccountTreeLazyTest` (واحد)، وكلها تفشل بـ
«101 بدل 95» في عدد الحسابات الفرعية. السبب: عدّادات مثبّتة في الاختبار مقابل بيانات
`ACCOUNTS` الحية التي زادت 6 حسابات فرعية أثناء التطوير. ملفات الاختبارين لم تُلمس في هذا العمل
ولا يكتب قسم المخازن في جداول دليل الحسابات إطلاقاً. لم تُعدّل الأرقام المثبتة لأنها خارج
نطاق المهمة وتعديلها يخفي تغيراً في الدليل المالي يحتاج مراجعة من صاحب النظام.

نتيجة التشغيل الكامل: **213 نجحت · 3 فشلت · 1 تخطّي**.

---




---

## 2026-11-02 — استعادة سجل الجولة + إصلاح عرض قوائم أوامر التوريد/الصرف/التحويل

> **ملاحظة أمانة:** عند محاولة إلحاق إدخالات هذه الجولة قُرئ الملف بـ`Get-Content -Raw`
> بترميز ANSI فتحوّلت العربية إلى `ط§ظ„…`، ثم قصّ سكربت الإصلاح من أول سطر فيه تلك البصمة
> فحذف محتوى سابقاً. أُعيد الملفان (`todo.md` و`user_commends.md`) كاملين من آخر commit،
> وأُعيدت إدخالات الجولة من `devloping_history.md` (سليم ولم يُمسّ: +419 سطراً).
> **الدرس:** لا إلحاق عبر PowerShell بلا `[System.IO.File]::AppendAllText` بترميز UTF-8، ولا
> «إصلاح» بقصّ من أول بصمة ترميز — البصمة قد تكون تاريخية ومشروعة.

### إنجازات الجولة (ملخّص مطابق لـ`devloping_history.md`)

- [x] **استكمال أعمدة كشف الجرد** — الفرق الأربعة + ملاحظة السطر.
- [x] **انحرافان موثقان** عن نص الخطة وسببهما (توقيت التدقيق، وحذف الصنف).
- [x] **تطوير أوامر التوريد/الصرف/التحويل:** بطاقات رسمية منظمة · عرض/تقرير مطابق لقالب
 `REPORTS/stors/استعراض التوريد.pdf` بترويسة وتذييل التطبيق · نماذج إضافة/تعديل مطابقة لصور ERP.
- [x] **الشريط السفلي العائم** (FloatingNavBar) + تصحيحان عليه + إزالة المؤشّر العلوي.
- [x] **عطل عاجل:** `ORA-00904 "M"."PROV_BILL"` — خمسة أخطاء متشابكة في القوائم والتفصيل والكتابة
 (عمود المرجع، عملة السطر، و`bindOnlyUsed` لـ`ORA-01036`)، مع سدّ ثغرة اختبار `/stores/issue`.
- [x] **فصل الأنواع الثلاثة:** `StorePolicy::fields()`/`documentProfiles()` في الخادم و`StoreDocProfile`
 في العميل — كل مستند بحقوله لا قالب واحد للجميع (+2 Dart، +2 Pest).

### هذه الجولة: «القائمة لا تعرض شيئاً ويظهر فقط خطأ»

- [x] الخادم كان يردّ `success: true` مع 50 صفاً ⇒ العطب **رسم** لا استعلام.
- [x] السبب: `Row(crossAxisAlignment: stretch)` داخل قائمة بارتفاع غير محدود
 (`orders_list_screen.dart:715`) ⇒ `BoxConstraints forces an infinite height`؛ وبقية أخطاء السجل
 أعراض تالية لنفس البطاقة (`Container:706` / `InkWell:703`).
- [x] الإصلاح: `IntrinsicHeight` حول الصف الخارجي + `mainAxisSize: MainAxisSize.min`، وتعليق يمنع إزالته.
- [x] حارس جديد `test/features/stores/orders_list_screen_test.dart` — 3 اختبارات: البطاقة تُرسم،
 الأنواع الثلاثة تُرسم، وعرض 360px.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` **543** (المخازن 71).

**متبقٍّ (على المستخدم):** `flutter run` ثم **hot restart** أو إعادة بناء الحزمة — تغيير التخطيط
لا يظهر في تطبيق مبني مسبقاً.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **لا commit**.

---

## 2026-11-03 — عطب مستند الأوامر + عطب اختيار الصنف الفرعي

- [x] قراءة السجل: عطلان مستقلان — عطل رسم في شاشة العرض، وعطل `ORA-00904` في تفصيل الصنف.
- [x] **(أ) المستند:** `_borderedGrid` كان يملأ قائمة ثابتة الطول ⇒ `Cannot add to a fixed-length list`
 عند العروض التي لا يقبل فيها عدد الخانات القسمة على عدد الأعمدة (لذا بدا متقطعاً).
- [x] الإصلاح: `toList()` قابلة للنمو في `order_view_screen.dart`.
- [x] حارس جديد: تمرير تسعة عروض (420→1400) والمطالبة بـ`takeException() == null`.
- [x] **تأكيد أن الحارس فعّال:** أُعيد `growable: false` مؤقتاً فسقط الاختبار بنفس رسالة الإنتاج، ثم أُعيد الإصلاح.
- [x] **(ب) الأصناف:** `ACCOUNTS.SANFS` لا يملك `MAIN_COLOR` (الموجود `MCOLOR`، وأيضاً `COLORNO`).
- [x] إصلاح ثلاثة مواضع: `fetchItem` (SELECT) و`store` (INSERT) و`update` (SET).
- [x] العميل: `item_model.dart` يقرأ `MCOLOR` ويُبقي `MAIN_COLOR` احتياطاً.
- [x] حارس جديد: `StoreItemTest.php` — 4 اختبارات: قائمة · تفصيل (17 مفتاحاً) · حركات · دورة كاملة
 (إنشاء ← صنف فرعي ← قراءة ← تعديل ← حذف) داخل معاملة تُلغى.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` **544** · Pest المخازن **21/3312** · pint passed.

**متبقٍّ (على المستخدم):** إعادة تشغيل التطبيق بـ`flutter run` ثم **hot restart** أو إعادة بناء الحزمة؛
وإعادة تشغيل خادم Laravel إن كان يعمل من نسخة قديمة من الكود.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **لا commit**.

---

## 2026-11-03 — تنسيق مستندات الأوامر + إصلاح التصدير والطباعة

- [x] **شريط التفاصيل:** صف واحد موازٍ للجدول بدل شبكة متعددة الصفوف، من مصدر مشترك مع PDF
 (`storeDocumentMeta`).
- [x] **رقم الفاتورة:** يظهر مرة واحدة تحت العنوان، وأُزيل من شريط التفاصيل.
- [x] **حقول الشريط لكل نوع:** التوريد (تاريخ · نوع · مخزن · مورد · عملة · عدد) ·
 الصرف (… عميل …) · التحويل (تاريخ · من مخزن · إلى مخزن · رقم الصرف · رقم التوريد · حساب المخزون · عدد).
- [x] **حذف أعمدة:** رقم الصنف الفرعي · رقم الرف · طول · عرض · التصنيف.
- [x] **الأعمدة الباقية:** 9 مشتركة (رقم الصنف · إسم الصنف · اللون · الوحدة · الكمية · عبوة · قطعة ·
 سعر الصنف · الإجمالي) + متوسط التكلفة للتحويل وحده.
- [x] **بلا تمرير جانبي:** حُذف `SingleChildScrollView` الأفقي؛ الشبكة تُوزَّع على العرض، و`FittedBox`
 يُصغّرها عند الضيق، ودُقّقت حدود الأعمدة (`storeDocumentMinWidth < 700`).
- [x] **التفاصيل المالية:** عمودان متقابلان — يميناً المبلغ كتابةً والبيان، يساراً الإجمالي/الخصم/الصافي.
- [x] **التصدير (عطل الصورة):** `_orderMeta` كان يملأ قائمة ثابتة الطول → `toList()`.
- [x] **عطل ثانٍ كشفه الاختبار الجديد:** `pw.Row(stretch)` في ترويسة `MultiPage` ⇒
 `height (Infinity) exceed a page height`؛ استُبدل بـ`pw.Table` في التفاصيل المالية والشريط.
- [x] **حارس جديد:** `store_export_test.dart` يبني PDF فعلياً للأنواع الثلاثة.
- [x] **تحديث الحراس القائمة:** اختبارات الأعمدة والرؤية أُعيدت كتابتها على المواصفة الجديدة.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` **547** (المخازن 76) · Pest المخازن **21/3317** ·
 pint passed.

**متبقٍّ (على المستخدم):** `flutter run` ثم **hot restart** أو إعادة بناء الحزمة؛ ثم تصدير مستند
واحد للتأكد بصرياً من ترتيب الأعمدة والتفقيط على الورق.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **لا commit**.

---

## 2026-11-03 — تلميع مستند الأوامر (شريط تفاصيل، جدول، تفاصيل مالية، طباعة)

- [x] **شريط التفاصيل:** كل اسم وقيمة داخل `FittedBox(scaleDown)` بلا `ellipsis` — النص يُصغَّر ولا يُبتر،
 والشريط يبقى صفاً واحداً على أي عرض.
- [x] **حذف سطر «تفاصيل الأصناف»** — الجدول يلي الشريط مباشرة.
- [x] **زيادة ارتفاع الصفوف:** حشو رأسي 4 ← 7، وخط 9 ← 9.5.
- [x] **«إسم الصنف» يلتف** (`wrap`) بلا `maxLines` وبلا بتر — يظهر كاملاً دون توسيع الجدول.
- [x] **تقليل التفاصيل المالية:** حشوات وفواصل وخطوط أصغر (11.5 → 10.5، 10.5 → 9.5، 12.5 → 11.5).
- [x] **الطباعة:** السبب = `fromTextArray` يعطي أعمدة متساوية العرض فتتسطر الأسماء ويصبح الصف ~50 نقطة.
 الحل = تمرير `columnWidths` بنِسَب المستند. النتيجة المقاسة: 36 سطراً **3 صفحات ← صفحتان**.
- [x] **فرضيتان قِيستا ورُدَّتا:** تمدد `pw.Column` في ترويسة PDF و`Container(alignment:)` حول الشعار —
 لم تُغيّرا عدد الصفحات، فأُعيد الملفان المشتركان إلى أصلهما.
- [x] **حارس جديد:** 36 سطراً = صفحتان في `store_export_test.dart`، وشريط بلا بتر في `order_view_screen_test.dart`.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` **548** (المخازن 76) · Pest المخازن **21/3317**.

**متبقٍّ (على المستخدم):** `flutter run` ثم **hot restart** أو إعادة بناء الحزمة، ثم تصدير مستند
لصفحتين لمعاينة الورقة.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **لا commit**.

---

## 2026-11-03 — إصلاح فوري: حروف PDF معكوسة + ورقة A4 طولية

- [x] **السبب:** `fromTextArray` يترك `tableDirection`/`headerDirection` فارغين فترث الخلايا `rtl`،
 و`pdfArabic` تُسلّم نصاً مُشكَّلاً بترتيب مرئي ⇒ Bidi يطبّق عكساً ثانياً فتنقلب الحروف والكلمات.
- [x] **الدليل:** العنوان وبطاقات المجاميع (`pw.Text` بـ`kPdfShapedTextDirection`) سليمة، وخلايا
 الجداول وحدها معكوسة.
- [x] **الإصلاح:** `headerDirection`/`tableDirection: kPdfShapedTextDirection` + `cellAlignment: topRight`
 في **خمسة** جداول: سطور المستند · قائمة الأوامر · الحركة · الخلاصة · كشف الجرد.
- [x] **المقاس:** `a4.landscape` ← `a4` (طولية 595×842).
- [x] **تحقق بصري:** عرض المستند بـpdf.js بمقياس 2.5× — المقاس طولي، ورأس الجدول والأسماء العربية سليمة.
- [x] **حارس جديد:** `store_export_test.dart` يفحص `MediaBox` ويرفض أي ورقة غير طولية.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` **549** (المخازن 77).

**نقطة يلزم معرفتها:** نسخ النص من الـ PDF يعطي أشكال عرض بترتيب مرئي (خاصية مشروع قائمة لكل
التقارير)؛ الرسم على الورق صحيح.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **لا commit**.

---

## 2026-11-03 — تطوير واجهة قسم الأصناف (تبويبان · إصلاح التصفية · تفصيل بتبويب واحد)

**النطاق:** تقسيم واجهة الأصناف إلى (الأصناف الرئيسية · الأصناف الفرعية) · تحسين البطاقات ·
إضافة إجراء كشف حركة · إصلاح عطل التصفية (شاشة بيضاء) وعطل زر «صنف جديد» · إعادة بناء شاشة
الاستعراض في تبويب واحد بصفوف ثنائية الحقول وجدول فروع بالأعمدة المطلوبة.

### التشخيص (قبل أي تعديل)

- [x] **عطل التصفية:** النافذة كانت `Column` بلا تمرير وبلا عنصر «الكل»، وأي قيمة لا تجد
      عنصراً في `DropdownButtonFormField` تُسقط شرطاً داخلياً (`assert`) فيظهر المستخدم شاشة
      بيضاء بلا خيارات.
- [x] **عطل «صنف جديد»:** نفس السبب في نموذج الصنف — قيمة قائمة (نوع/نمط) لا تُطابق عناصرها
      بعد تغيير المجموعة أو عند مرجع ناقص ⇒ خطأ فوري عند فتح الشاشة.
- [x] **كمية الصنف الفرعي:** `AVVG` مُجمَّعة على الصنف الرئيسي فقط، فالمصدر الوحيد لكمية الفرع
      هو `ITEM_MOVEMENT_D` عبر `P_CODE` (= `SANFS_D.SANF_DNO`).

### الخادم

- [x] `StoreItemController::fetchSubs` — إضافة `QTY` لكل فرع من تجميع الحركة على `P_CODE`
      مقيَّد بالصنف الرئيسي (رخيص: مسح صنف واحد لا الـ VIEW كاملة).
- [x] `StoreItemController::subIndex` — تبويب الأصناف الفرعية: صفحة + بحث + تصفية مجموعة/فرعية/
      حالة، بلا عمود كمية (توثيق السبب في الكود).
- [x] `StoreItemController::movements` — `P_CODE` و`COLOR_NO/WID/LEN` واسم الفرع ولونه،
      و`QTY_IN/QTY_OUT`، و`meta.totals` (وارد/صادر/صافي/قيمة/عدد الأسطر) محسوبة على كل الصفوف،
      وتصفية `sub_dno` لفرع واحد.
- [x] تطبيع مفاتيح OCI8 إلى أحرف كبيرة في كل قراءات المتحكم (كانت الفرعية والحركة تُرجع
      مفاتيح صغيرة).
- [x] `routes/api.php` — `GET /stores/items/sub` قبل `{sanfNo}`.

### العميل

- [x] `items_list_screen` — **تبويبان**: الرئيسية (تخطيط رئيسي-تفصيلي كما هو) والفرعية (قائمة
      فروع مستقلة ببحث وتصفية وترقيم).
- [x] بطاقات الأصناف أُعيد تنسيقها: رمز المجموعة · الاسم · كود/مجموعة/فرعية · شارات
      (عدد الفروع · الوحدة · السعر) · الكمية والقيمة في موضع ثابت · قائمة إجراءات.
- [x] **إجراء كشف حركة** في قائمة إجراءات كل صنف، وأيقونة كشف حركة على كل فرع.
- [x] `item_movement_screen` (**جديد**) — كشف حركة للصنف الرئيسي بكامل فروعه أو لفرع واحد:
      مدى زمني · مجاميع من الخادم · تكبير · طباعة PDF · تصدير Excel.
- [x] `buildItemStatementPdf` في `store_export.dart` — أعمدة الحركة مع عمود «الفرع».
- [x] **إصلاح التصفية:** نافذة عالية قابلة للتمرير، وكل قائمة فيها «الكل» صريح، وقيمة القائمة
      مضمونة من عناصرها، وتُصفَّر الفرعية عند تغيير المجموعة.
- [x] **التصفية الافتراضية:** نشط فقط · أول مجموعة رئيسية · أول فرعية منها · كل الفئات
      (`applyDefaults` مرة واحدة لكل جلسة في التبويبين).
- [x] **إصلاح «صنف جديد»:** قائمة منسدلة آمنة (قيمة غير موجودة ⇒ غير مختارة بدل الانهيار)،
      وزرع الافتراضيات مرة واحدة، وتسلسل (مجموعة → أول فرعية → أول نمط).
- [x] إعادة بناء شاشة الاستعراض: **تبويب واحد** — بيانات في صفوف بحقلين ثم جدول فروع
      (رقم الصنف · اللون · الكمية) بأيقونة كشف حركة وإجراءات تعديل/حذف، وزر كشف حركة أعلى.

### الاختبارات والبوابات

- [x] `kyApp_API/tests/Feature/StoreItemReadTest.php` (**جديد**) — 4 اختبارات: تبويب الفروع ·
      كمية الفرع من الحركة · مجاميع الكشف من الخادم · تصفية الفرع الواحد ⇒ **4 ناجحة / 288 تأكيداً**.
- [x] تحديث `item_form_validation_test` (افتراضيات النمط + حارسان ضد الانهيار: مرجع فارغ،
      ومجموعة بلا فرعية) وتحديث `items_split_test` (تجاوز تبويب الفروع).
- [x] `flutter analyze` = **No issues found** · `flutter test` = **552 ناجحاً** ·
      اختبارات المخازن الخلفية = 31 ناجحاً (6 ملفات).

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا (قراءة فقط) · **لا جدول جديد** · **لا commit**.

---

### تكملة — إصلاح «الأصناف لا تظهر» وخطأ التصفية (2026-11-03)

**بلاغ المستخدم:** «الاصناف لاتظهر ابدا في القائمه وايضا يظهر خطا عند النقر على زر تصفيه».

- [x] **تشخيص من سجل الجهاز** (لا تخمين): الطلب `items?...&group_no=0&active=1` يُرجع `total: 0`،
      ونص `assert` في `_sheetDropdown` يقول إن القيمة `0` مكررة بين خمسة عناصر.
- [x] **السبب ١:** `clean()` في `StoreReportController` لم تُطبّع مفاتيح OCI8، فـ`/stores/reference`
      يُرجع `group_no` صغيرة، والنماذج تقرأ `GROUP_NO` ⇒ كل مجموعة = 0، وكل فرعية = 0.
- [x] **السبب ٢:** الأرصدة كانت تُطلب من `AVVG` في كل فتح ⇒ **14.6 ثانية** ⇒ مهلة العميل (15 ث).
- [x] **الخادم:** تطبيع المفاتيح في `clean()` (وأصلح وسم «أرشيفي» الذي لم يُضبط قط) ·
      الأرصدة صارت اختيارية `with_stock` · إزالة `fetchBalances` من تفصيل الصنف · تجميعان مفردان
      بدل استعلامات مترابطة لكل صف.
- [x] **العميل:** قراءة مزدوجة الحالة في نماذج المجموعات/الأنواع/الوحدات · إزالة التكرار في
      `_sheetDropdown` · `applyDefaults` تتجاهل المجموعات غير الصالحة · `stockLoaded` يُخفي
      الأرقام بدل صفر كاذب · إزالة الفرز بالكمية/القيمة من القائمة.
- [x] **اختبارات:** `store_reference_parse_test.dart` (5) على الحمولة الحقيقية بمفاتيح صغيرة ·
      `StoreItemReadTest` +2 (حزمة المراجع + التركيبة الافتراضية تُرجع أصنافاً).
- [x] **الأثر:** `the default filter combination` 48.59ث ⇒ **0.14ث** · حزمة القراءة 78ث ⇒ **2.13ث**.
- [x] البوابات: `flutter analyze` نظيف · `flutter test` (المخازن) **85** · Pest **6/313**.

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

### تكملة — الرصيد داخل واجهة الأصناف ومنع تكرار الفرع (2026-11-04)

- [x] **تصحيح اتجاه:** الجولة السابقة جعلت الأرصدة اختيارية لتجنّب المهلة؛ المطلوب كان الرقم
      نفسه في الواجهة نفسها. حُلّت المسألة بمصدر رخيص لا بحذف الميزة.
- [x] **قياس:** `AVVG` = 14,589 مللي مقابل 1,552 مللي لتجميع الحركة بالفرع ⇒ نفس الأرقام بسُبع الزمن.
- [x] **الخادم:** رصيد الصنف = `SUM` أرصدة فروعه (`GROUP BY d.SANF_NO` بعد ربط الحركة بالفرع) ·
      رصيد الفرع في تبويب الفروع مباشرة · مصدر واحد للقائمة والتفصيل والكشف بلا تقييد بالأب.
- [x] **تكرار الفرع:** نفي المصدر البياني (صفر تكرار في `SANFS_D`، `SANFS_COLOR` فريد، استعلام
      التبويب 50/50) ثم منع التكرار بنيوياً: `GROUP BY d.SANF_DNO` + `MAX()` · وطبقة ثانية في
      العميل `_distinctBranches` / `_distinctItems`.
- [x] **الواجهة:** الرصيد والقيمة في بطاقة الرئيسي والفرع · شارة قيمة في التفصيل · رجوع الفرز
      بالرصيد والقيمة · إزالة `STOCK_LOADED`/`with_stock`/`ItemBalanceModel`/`fetchBalances`.
- [x] **اختبارات:** `StoreItemReadTest` +2 (منع تكرار الفرع · تساوي رصيد القائمة مع مجموع الفروع)
      ⇒ **7 ناجحة / 317 تأكيداً** · `flutter test test/features/stores/` = **85** · analyze نظيف.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

### تكملة — شاشة الفرع المستقلة وتوطين الإجراءات (2026-11-04)

- [x] **`sub_item_detail_screen.dart` جديدة:** تفاصيل الفرع وحده — كل خانة عمود من `SANFS_D`
      أو رصيد الفرع من حركته، والصنف الرئيسي رابط وصول في الأسفل لا حقل من بياناته.
- [x] **الخادم:** `fetchSubs` و`subIndex` يُرجعان الآن `SANF_PRICE` · `UNIT_NO` · `UNIT_NAME`
      (`LEFT JOIN UNITS`) · `CAP` · `PARENT_NAME`.
- [x] **عطل خفي:** `ItemSubModel.parentName` كان يقرأ `SANF_NAME` وهو اسم **الفرع** (NOT NULL في
      `SANFS_D`) ⇒ صار يقرأ `PARENT_NAME` أولاً.
- [x] **الرئيسي:** `كشف حركة` + `تعديل` أيقونتان في `AppBar` فقط وحُذف صف الأزرار من الرأس
      (وفي الوضع الجانبي أيقونات اللوحة لأنها بلا شريط) · `صنف فرعي جديد` جوار عنوان القسم ·
      `كود الصنف` حُذف من شبكة البيانات لتكراره كشارة، وأُضيف `إجمالي القيمة`.
- [x] **`widgets/sub_item_dialog.dart` جديدة:** `showSubItemDialog` + `confirmDeleteSubItem`
      مشتركتين بين الشاشتين، مع **منتقي ألوان** من `SANFS_COLOR` بدل كتابة رقم اللون.
- [x] **الاختبارات:** تأكيد أن الفرع يحمل `SANF_PRICE`/`CAP`/`QTY`/`VALUE` ⇒ 7 ناجحة / 321 تأكيداً.
- [x] **البوابات:** `flutter analyze` نظيف · مخازن **85** · الحزمة الكاملة **557** · Pint passed ·
      `dart format` مطبَّق.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

### تكملة — جذر التكرار: `SANFS_COLOR` بصفين لكل لون (2026-11-04)

- [x] **تصحيح منهجي:** التشخيص السابق فشل لأن الفحص جرى على قاعدة غير التي يقرأ منها التطبيق
      (`SERVICE=orcl3`). المسبار جرى من داخل الاختبار على اتصال التطبيق نفسه.
- [x] **الحقيقة:** `SANFS_COLOR` = 54 صفاً / 27 معرّف ⇒ كل لون مكرر، ورابطة عليه تُضاعف الفروع
      (10 صفوف لخمسة فروع). `UNITS` و`SANFS` سليمتان (12/12 و1 لكل صنف).
- [x] **الإصلاح:** استعلامات فردية `MAX()` بدل `LEFT JOIN` للألوان والوحدات وأسماء الفروع في
      `fetchSubs` و`movements` · تجميع رصيد الأب من `DISTINCT SANF_NO, SANF_DNO` ·
      عدّاد الفروع `COUNT(DISTINCT SANF_DNO)`.
- [x] **التحقق:** `subs` 10 ← **5** · `list == sumBranches` لكل أصناف الصفحة · `1991 = 1503.27`
      و`1219 = 162.47` مطابقان لمجموع فروعهما.
- [x] **كشف الحركة:** الأصناف المبلَّغ عنها بلا حركة فعلاً (`mvDb=0`)؛ الرسالة صارت تفرّق بين
      «لا حركة إطلاقاً» و«لا حركة في المدى»، ولا تلوم مدى لم يختره المستخدم.
- [x] **التخطيط:** العنوان والقيمة في سطر واحد بالشاشتين، وحشو الصف 9←7 والفاصل 30←16.
- [x] **حارس دائم:** اختبار جديد يمرّ على كل أصناف الصفحة ويتحقق من عدم التكرار ومن أن رصيد
      القائمة = مجموع الفروع ⇒ **8 ناجحة / 336 تأكيداً** · analyze نظيف · مخازن **85** · Pint مطبَّق.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.



## 2026-11-07 — تطوير قسم تقارير المخازن: معطيات متعدّدة الاختيار + قالب رسمي موحّد

- [x] **نافذة المعطيات (إعادة بناء كاملة):**
      - المخازن → اختيار متعدد بقائمة منسدلة **مطوية**: الخيارات لا تُبنى ولا تُعرض إلا عند
        فتح الحقل، والقيمة الحالية تُقرأ على وجه الحقل دائمًا.
      - نوع الحركة → اختيار متعدد بقائمة منسدلة.
      - المجموعة الرئيسية والمجموعة الفرعية → متعدّد، والفرعيات تتقلّص حسب المجموعات المختارة
        مع **تنقية المحدد القديم** حتى لا يبقى قيد خفيّ يفسد التقرير.
      - الصنف الرئيسي → منتقي بحث يعرض **النشط فقط** (`active=1`).
      - **حقل جديد: الصنف الفرعي** — فروع الصنف المختار إن حُدد، وإلا كل الفروع النشطة.
      - «لاشي» في كل الحقول، ومعناها في الاستعلام «بلا قيد» لا «اختر شيئًا».
      - إضافات مهنية: مدى جاهزة (اليوم/أسبوع/شهر/3 أشهر)، «لاشي / إعادة ضبط» شاملة، مستوى
        تجميع صريح للخلاصة، بحث خدع 300ms و`CancelToken` وحارس سباق داخل المنتقيات.
- [x] **الخادم:** `applyScope` و`balances` يقبلان `store_nos`/`group_nos`/`item_type_nos`
      بروابط `IN` مسمّاة (لا أرقام داخل نص SQL) مع بقاء المفرد القديم؛ `group_by` للخلاصة
      من قائمة بيضاء؛ `SUB_NAME`/`COLOR_NAME` بلقطة فردية لا برابط؛ `subIndex` يقبل `sanf_no`.
- [x] **إصلاح أثناء العمل:** `MAX(m.I_CODE)` في الخلاصة — كان العمود يُقرأ خامًا خارج
      `GROUP BY` المتبدّل فيرمي `ORA-00979` عند أي مستوى تجميع غير «البند × المخزن».
- [x] **القالب الرسمي للتقارير:** `ReportA4Sheet` + `ReportLetterheadBranding` (ترويسة
      التطبيق) + شريط معطيات كامل (كل بُعد مذكور ولو «بلا قيد») + جدول كسول بأعمدة قابلة
      للإخفاء + `ReportSignatureFooter` + `ReportZoomView` للتكبير والتصغير.
- [x] **مطبوع = معروض:** `ReportColumns` تعريف واحد تقرأه الشاشة والـ PDF والـ Excel؛
      الـ PDF بأعمدة المستخدم نفسها مع ترويسة وتذييل رسميين؛ الـ Excel ورقتان (السطور +
      المعطيات والمجاميع)؛ ونُقلت الأداة نفسها إلى **كشف حركة الصنف**.
- [x] **الاختبارات:** عميل جديد `report_template_test.dart` (الأعمدة، المعطيات، ودجت
      المتعدد، تتابع الفرعيات) + تحديث `report_filter_test.dart`؛ الخادم 6 اختبارات جديدة
      في `StoreReportTest.php` (منها حارس «الجمع عند التوسّع» و«لاشي = بلا قيد»).
- [x] **الحصاد:** analyze «No issues found» · مخازن **110** · الكلي **582** (~10 متخطًّى) ·
      Pest تقارير **12/12** · Pint مطابق · **بلا أي commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-07 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.


## 2026-11-08 — إصلاح توقف التطبيق + إعادة بناء قالب التقارير على خمسة مكوّنات

- [x] **انهيار مبدئي (من سجل الجهاز):** `BoxConstraints forces an infinite width` عند عرض
      أي تقرير — السبب `SingleChildScrollView` أفقي كان يعطي `Table` عرضًا لانهائيًا.
      **الحل: حذف التمرير الأفقي كليًا** وامتلاء الجدول للعرض المتاح.
- [x] **انهيار ثانٍ كان مخفيًا خلف الأول:** `type '(StockMovementRow, int) => String' is not a
      subtype of type '(Object, int) => String'` — من `.cast<ReportColumn<Object>>()`.
      **الحل: أنواع حقيقية Generics** في `ReportDataTable<T>` و`_reportPdfTable<T>` و
      `_appendColumns<T>` عبر الشاشة والـ PDF والـ Excel معًا (بلا إمحاء نوع إطلاقًا).
- [x] **القالب صار خمسة مكوّنات لا غير:**
      1) الترويسة الرسمية
      2) **عنوان التقرير** مبني من أضيق بُعد مختار
         (`كشف حركة صنف فرعي : <اسم الفرع>` / `كشف حركة صنف : …` / `مجموعة فرعية` /
          `مجموعة رئيسية` / `كشف حركة المخازن`)، وتحته **الفترة فقط إن خُصّصت**
          (وسم `customPeriod` جديد)، وتحته **«من مخزن: …» فقط إن خُصّصت المخازن**.
      3) جدول الكشف بكل الأعمدة **بنفس عرض الواجهة بلا تمرير جانبي**، والنص كامل بلا
         اقتطاع (الالتفاف بدل `ellipsis`) مع **مقياس خط تلقائي** (11.0 → 7.5 حسب عرض العمود).
      4) **ملخص الجدول** كعنصر مستقل بعد الجدول (عدد السطور/وارد/صادر/الصافي/القيمة).
      5) التذييل الرسمي (توقيعات + إشعار 15 يوماً + توقيت الإصدار).
- [x] **حُذف:** شريط الوسوم أعلى الترويسة (`_paramsBar`) · كتلة «تفاصيل التقرير» (`_metaBlock`)
      · شريط المجاميع السفلي · ترويسة الكشف الجانبية (`_header`) — ومحتواها صار داخل العنوان.
- [x] **الـ PDF/Excel نفس القالب:** رأس PDF = عنوان مركّب + أسطر التخصيص فقط، ثم الجدول ثم
      الملخص ثم `pdfSignatures()`؛ وحُذف `_reportParamsGrid`. ورقة «المعطيات» بقيت في Excel
      فقط (مرجع بيانات لملف يُفتح لاحقًا، لا عنصر بصري في المستند).
- [x] **اختبارات:** +9 جديدة (عنوان بكل الحالات، الفترة/المخازن عند التخصيص، سالب بلون خطر،
      **لا يوجد تمرير أفقي**، تطابق عنوان الشاشة مع المطبوع) وتعديل اختباري البوابة.
- [x] **الحصاد:** analyze **No issues found** · مخازن **120** · الكلي **592** (~10 متخطًّى) ·
      Pint مطابق · **بلا أي commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.


## 2026-11-08 — جدول التقارير يتمدّد على الصفحات (بلا صندوق ثابت بتمرير داخلي)

- [x] **المطلوب:** كامل السجل يُعرض كصفحات مرنة حسب عدد صفوفها، لا كمساحة جدول ثابتة
      يتمرَّر داخلها عموديًا.
- [x] **الواجهة:** `ReportDataTable` صار `StatefulWidget` يبني `Column` من كتل `Table`
      متصلة — ارتفاع الجدول = عدد صفوفه، والتمرير للصفحة وحدها.
      استُبعد `LazyReportTable` من هذا المسار (كان صندوقًا بارتفاع ثابت + ListView داخله).
- [x] **الأمان من نفاد الذاكرة بقي:** دفعات 120 صفاً تُزاد تلقائيًا قرب أسفل الصفحة
      عبر `Scrollable…position`، مع تصفير الدفعة عند تغيير الصفوف/الأعمدة.
- [x] **إصلاح فوري ظهر في الاختبار:** `RangeError (length) … Not in inclusive range 0..1: 2`
      — الدفعة لم تكن تُحصر بعدد الصفوف؛ صار `shown = min(_built, rows.length)`.
- [x] **PDF:** `_reportPdfBlocks<T>` تخرج جدولاً لكل صفحة برأس مكرر (حتى 30 صفاً) لأن
      `pw.Table` في pdf 3.11.3 يمتد ولا يكرر رأسه؛ طُبِّق في تقرير المخازن وكشف الحركة.
- [x] **تنظيف القالب:** حُذفت وسائط `totals`/`rowsHeight` من الودجت (الملخص مكوّن مستقل).
- [x] **اختبار جديد:** `grows with its rows instead of a fixed inner scroller` (40 صفاً —
      لا `Scrollbar`/`ListView` داخل الجدول وكل الصفوف في الشجرة) وتحديث 3 اختبارات.
- [x] **الحصاد:** analyze **No issues found** · مخازن **121** · الكلي **593** (~10 متخطًّى) ·
      **لا تغيير في قاعدة البيانات** · **بلا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.


## 2026-11-09 — تقارير المخازن: الرصيد الحقيقي، أعمدة حرة الترتيب، سطر تجميع، إحصاءات مختصرة، تذييل قسمي

- [x] **المطلوب (سبعة إصلاحات):** عمود الرصيد لا يُظهر شيئًا · إلغاء قفل الأعمدة الأساسية ·
      التحكم بترتيب الأعمدة · إظهار/إخفاء الإحصاءات من نافذة الأعمدة · سطر تجميع في نهاية الجدول ·
      إحصاءات مرتبة ومختصرة · تذييل «توقيع أمين المخزن» للمخازن و«توقيع أمين الصندوق» لبقية الأقسام.
- [x] **الخادم — سبب عمود الرصيد:** `yajra/laravel-oci8` يعيد **مفاتيح الأعمدة بأحرف صغيرة**
      (`p_qty`) والكود كان يقرأ `P_QTY`؛ أُضيف التطبيع `array_change_key_case(…, CASE_UPPER)` في
      `movement` و`summary` وفي مساعدي الرصيد الافتتاحي، فظهر الرصيد الجاري فعليًا.
- [x] **معرّفات الأعمدة:** عمود فرع الخلاصة كان يشارك المجموعة الفرعية المعرّف `sub` فأفسد الترتيب
      والرقائق (خريطة تُزيل التكرار)؛ صار `branch`. و`basic` أُعيد تعريفه «الافتراضي» لا «المقفل».
- [x] **الترتيب:** `ReportColumns.ordered(columns, ids)` يرسم بترتيب المستخدم، ويتجاهل المعرّفات الغريبة،
      ويعود إلى الافتراضي حين لا يبقى شيء · كل سطر في نافذة الأعمدة له سهما أعلى/أسفل.
- [x] **نافذة الأعمدة:** `ReportColumnsSheet` أُعيدت كتابتها لتعيد `ReportColumnsChoice{columnIds, statIds}`
      — اختيار حر لكل عمود + إعادة ترتيب + رقائق للإحصاءات + «إظهار كل الإحصاءات»، وتعطيل «تطبيق»
      إن أُفرغت الأعمدة مع رسالة توضيحية.
- [x] **سطر التجميع:** `ReportDataTable.totals` يرسم صفًا بلون أساسي في نهاية كل جدول (الدراسة،
      الخلاصة، وكل قسم في التقارير المتشعبة). `ReportTotals` تجمع الكميات والقيم فقط — لا التكلفة
      (سعر وحدة) ولا الرصيد (رقم متراكم).
- [x] **الإحصاءات المختصرة:** `ReportStatsBand` + `ReportStatFields` بمعرّفات ثابتة
      (`rows/opening/in/inValue/out/outValue/net/closing/closingValue`) تُعرض رقائق عنوانها صغير
      وقيمتها بارزة، تُخفى بالمعرّف نفسه من نافذة الأعمدة، والقيمة الصفرية لا تُعرض.
- [x] **التذييل:** `ReportSignatureFooter.keeper` و`pdfSignatures(keeper:)` — «توقيع أمين المخزن» في
      تقارير المخازن وكشف الحركة، و«توقيع أمين الصندوق» هو الافتراضي لبقية الشاشات.
- [x] **PDF/Excel:** نفس الترتيب ونفس سطر التجميع ونفس تصفية الإحصاءات ونفس التذييل في
      `buildStoreReportPdf` و`buildItemStatementPdf` (+ الوسيط `statIds`).
- [x] **اختبارات العميل:** مجموعتا `column order` (3) و`totals and statistics` (3)، وإعادة كتابة اختبار
      «الأساسيات لا تُخفى» ليطابق السلوك الجديد بدل القفل.
- [x] **الخادم — اختبار هش أُصلح:** «multiple main groups…» كان يثبّت نافذة 60 يومًا فيتجاوز سقف
      الاقتطاع (5000) مع نمو الحركة؛ صار يجرّب 7/14/30/60 يومًا ويتخطّى بأمانة حين لا تلائم أي نافذة.
- [x] **الحصاد:** analyze **No issues found** · الكلي **610** (~10 متخطًّى) · Pest **16/16**
      (9630 تأكيدًا) · Pint مطابق · **لا DDL ولا DML** · **بلا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.

---

## 2026-11-09 02:43 — إصلاح الطباعة/التصدير الكامل للتقارير الكبيرة (`TooManyPagesException`)

- [x] **العَرَض:** كشف حساب مالي للحساب `38310001` (2026-05-01 → 2026-10-31) لا يُطبَع ولا
      يُصدَّر، و`Unhandled Exception: Instance of 'TooManyPagesException'` من `MultiPage.generate`.
- [x] **السبب الجذري:** `pw.MultiPage` افتراضيه `maxPages = 20`، وهو سقف امتداد **العنصر
      الواحد** (`pw.Table`) لا سقف المستند. الكشف جدول واحد ⇒ أي كشف > 20 صفحة يُسقط التوليد
      كاملاً. **لا موضع من مواضع `pw.MultiPage` كان يمرّر `maxPages`.**
- [x] **الخادم بريء:** `getAccountStatement` يُرجع كل حركات الفترة عند غياب `limit`؛ لا اقتطاع
      في البيانات — العلة في توليد الـ PDF على العميل.
- [x] **الإصلاح الجذري:** `const int kReportPdfMaxPages = 20000` في `lib/core/utils/report_pdf_page.dart`
      (تعريف واحد مشترك + شرح عربي/إنجليزي)، ويُمرَّر في **15 موضعاً** بـ**11 مولّد PDF**.
- [x] **التغطية:** كشف حساب مالي · كشف تحليلي مفصل · ميزان مراجعة مجموعة · شجرة الحسابات ·
      كشف عميل · مقاسات عميل · كشف عامل · كشف عمل · كشف عمل المجموعة · فاتورة تفصيل ·
      مستندات وتقارير المخازن (5 مواضع).
- [x] **لماذا 20000:** ≈ 700 ألف سطر حركة — أضعاف أي دفتر فعلي، ويبقى حدًّا يمنع دوراناً
      لا نهائياً عند خلل تخطيط.
- [x] **حارس جديد:** `test/features/accounts/account_statement_pdf_large_test.dart` — كشف 900
      حركة يُبنى فعلياً، ويُعدّ `/Type /Page` داخله ويُشترط `pages > 20` (كان يرمي قبل الإصلاح).
- [x] **الحصاد:** `flutter analyze` → **No issues found!** · `flutter test` → **613 ناجح**
      (~10 متخطّى) · **لا DDL ولا DML** · **بلا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 02:43 · **DDL:** لا · **DML:** لا · **لا commit**.

---

## 2026-11-09 — إصلاح «الرصيد السابق» وفصل التقارير الهرمية الثلاثة فعلياً (المخازن)

**الشكوى:** «لماذا لا يتم إرجاع قيمة حقل الرصيد السابق؟ وعمود الرصيد يجب أن تكون قيمته الأولية هي
الرصيد السابق للفترة ثم تُجمَّع عليه الحركات. ثانياً تقارير حركة صنف رئيسي / مجموعة فرعية / مجموعة
رئيسية تُعرض بشكل خاطئ وتُعرض مثل تقرير حركة صنف فرعي وهذا غلط».

- [x] **العلة أ — `opening` صفر دائماً:** `movementMeta()` كانت تُنادى بالسطور **الخام**، ومصفوفات
      PHP تُنسخ عند الكتابة، فلم ترَ `SECTION_KEY` أبداً — فانهارت كل الأقسام إلى قسم واحد
      `__all__` بلا عنوان ولا رصيد سابق. الحل: `$stamped = stampMovement(...)` في متغيّر، ثم
      `movementMeta($stamped, ...)`.
- [x] **العلة ب — نطاق الفرع بلا افتتاح:** كان يُمرَّر `[]` مكان الأرصدة. الآن `openingBySection()`
      تعمل في كل نطاق بمفتاح `'__all__'` حين لا يكون هناك عمود تقسيم.
- [x] **العلة ج — التقارير الثلاثة متطابقة:** بوابة الشاشة كانت `state.sections.length > 1`، ولأن
      الخادم أعاد قسماً واحداً دائماً سقطت الثلاثة إلى الجدول المسطّح. الآن **`template.sectioned`
      وحدها** تقرّر التقسيم، فلا يعتمد على عدد الأقسام في البيانات.
- [x] **العلة د — PDF لا يعرض أقساماً:** `buildStoreReportPdf` صار يستقبل `sections` و`opening`،
      ويطبع عنوان كل قسم ثم جدوله ثم إحصاءه، ثم الإحصاء العام.
- [x] **الخادم:** `opening_value` لكل قسم و`closing_value = opening_value + in_value − out_value`،
      و`totals.opening_value`، واستعلام افتتاح واحد يجمع الكمية **والقيمة** معاً.
- [x] **العميل:** `StoreReportScope.sectionLabel/sectionPlural`، `ReportStats.openingValue`،
      `ReportTotals.opening()`, صف **«رصيد سابق»** أعلى كل جدول/قسم، وربط الإحصاء بالسطور
      **بالمفتاح** لا بالفهرس (`ReportSectionHeader.key` + `result.sectionKeys`).
- [x] **التحقق التجريبي:** نافذة `2026-09-01 … 2026-10-31` — الفرع: افتتاح **251711.69** وأول
      `BALANCE_QTY` **251741.69**؛ مجموعة فرعية **136** قسماً لكل منها افتتاحها؛ مجموعة رئيسية: قسم
      `101` افتتاحه **126950.69**. (النافذة من 2026-01-01 تعطي صفراً **بصدق**: الدفاتر تبدأ 2026-04-25.)
- [x] **الاختبارات:** `StoreReportTest` **20 ناجحاً / 20263 تحققاً** (4 جديدة) ·
      `report_template_test.dart` **57 ناجحاً** · `flutter test` **620 ناجحاً** (~10 متخطّى).
- [x] **الحصاد:** `php -l` نظيف · `pint --dirty` نظيف (لم يمسّ إلا ملفات التحقيق المؤقتة المحذوفة) ·
      `flutter analyze` → **No issues found!** · **لا DDL ولا DML** · **بلا commit**.
- [x] **تنظيف:** حُذفت ملفات التحقيق المؤقتة `probe_scopes.php` و`probe_opening.php` و`probe_out.json`.

**قيد معروف متبقٍّ:** الاقتطاع بـ`ROWNUM` يجري على ترتيب «قسم ثم تاريخ»، فتقرير مجموعة رئيسية واسع
قد يُظهر أول مجموعة فرعية فقط (شريط `truncated` ينبّه). إحصاءات القسم تبقى صادقة لأنها من
`$stamped` نفسها (السطور المعروضة)، لكن إعادة تصميم الاقتطاع مؤجَّلة بطلب واعٍ.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا commit**.

---

## 2026-11-09 — إحصاء القسم سطراً واحداً مختصراً + إصلاح انحدار انكسر به البناء

- [x] **إصلاح الأعطال (طلب «اكمل وحل الاخطاء»):** `flutter analyze` كان يعيد **11 خطأ** بعد أن
      فُقدت أجزاء من جولة سابقة في شجرة العمل. أُعيدت ثلاثة مواضع كاملة:
      `ReportTotals.opening(ReportStats)` (صف «رصيد سابق» في عمود الرصيد) ·
      المعاملات الاختيارية الثلاثة لـ`_appendColumns` (`opening` · `heading` · `statsLine`) ·
      و`pw.Double.infinity` → `double.infinity` في مولّد الـ PDF.
- [x] **إحصاء القسم صار سطراً واحداً:** `ReportStatsBand.compact(...)` نمط جديد يرسم العنوان ثم
      **أربعة أرقام** فقط بلا صناديق: السابق · وارد · منصرف · الرصيد الحالي — ويسقط «السطور»
      و«الصافي» وقيم الوارد والمنصرف، فلا يعيد ذيل كل قسم إحصاء التقرير كاملاً.
- [x] **حقول الإحصاء أصغر:** الخانة صارت حشواً `5/2` بدل `6/3`، والعنوان `8.5` بدل `9`، والقيمة
      `10.5` (البازرة `11`) بدل `11/11.5`، والمسافات `4` بدل `5`، وحشو الشريط `7/4` بدل `8/6`.
- [x] **تكافؤ المنافذ:** `ReportStatFields.sectionIds` و`section()` مصدراً واحداً للأربعة،
      و`sectionStatsLine()` صار أربعة حقول لا ستة، والـ PDF يطبعها في شريط رقيق بعنوان القسم
      (`إحصاءات الصنف الفرعي: …`) بخط `7.5`، والـ XLSX يكتب عنوان القسم ثم صف الافتتاح ثم السطور
      ثم التجميع ثم سطر الإحصاء ثم فاصل بين الأقسام.
- [x] **الاختبارات:** 4 جديدة تحرس الأربعة وترتيبها، ونص السطر الحرفي، وإسقاط حقل أخفاه المستخدم،
      وسطراً واحداً بلا حقول تقرير كامل. `report_template_test.dart` **61 ناجحاً** ·
      `test/features/stores/` **149 ناجحاً** · `flutter test` **624 ناجحاً** (~10 متخطّى).
- [x] **الحصاد:** `flutter analyze` → **No issues found!** · **لا DDL ولا DML** · **بلا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا commit**.


---

## 2026-11-09 04:53 — التفصيل: إصلاح تجاوز بطاقات قائمة الفواتير وإظهار اسم العميل كاملاً

- [x] **السبب الجذري:** عمود الأرقام (شارتا العدّ + الصافي + الحالة) كان `Row` غير محدّد العرض داخل `Row` البطاقة، فيزاحم اسم العميل ويتجاوز بـ 2.4–7.5 بكسل (وهو «الخطأ في البداية» الذي ظهر كأشرطة حمراء).
- [x] **العرض صريح:** عمود الأرقام صار `SizedBox(width: 96)`، وشارتا العدّ داخل `Wrap` تلتفّ، وسطر الصافي/الحالة داخل `FittedBox` — فلا تجاوز على أي عرض.
- [x] **الاسم كامل دائماً:** داخل `FittedBox(fit: scaleDown, alignment: centerStart)` في سطر واحد — يصغر الخط بدل أن يُقصّ أو يُنقَّط، ويبقى كاملاً على 320/360/411.
- [x] **سطر البيانات:** التاريخ · الهاتف · اليدوي داخل `Wrap` خاص به فيلتفّ وحده دون أن يزاحم الاسم أو الأرقام.
- [x] **مربّع الرقم:** عرض ثابت 54 مع `FittedBox` للرقم، وأيقونة السهم 13 لتوفير المساحة.
- [x] **اختبار مانع للتكرار:** `a narrow phone width shows the full name without overflowing` — يعرض اسماً طويلاً على 360 بكسل ويتحقق من ظهوره كاملاً ومن `takeException() == null`.
- [x] **التحقق:** اختبارات التفصيل **56** ناجحة · `flutter analyze lib` = **No issues found!**. (فشل واحد في `test/features/stores/report_template_test.dart` — اختبار تقارير المخازن، خارج نطاق التفصيل.)

**النموذج:** Qoder · **الوقت:** 2026-11-09 04:53 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-11-09 05:05 — المخازن: هندسة جدول التقرير (سطر واحد ثابت) وحقول الإحصاء الافتراضية

- [x] **الشكوى الأولى:** عند تكبير الشاشة والخط تخرج رؤوس الأعمدة عن مواضعها وتتشوّه أرقام نهاية
      الجدول. **الجذر:** الخلية كانت تلتفّ (`softWrap: true`)، فتُكسر «المستند» إلى «المستن» و«د»،
      و«-12,985.76» إلى نصفين، فيختلف ارتفاع الصف وتنزاح الخانات بين الرأس والجسم والمجاميع.
- [x] **خلية سطر واحد:** `_Cell` جديدة ترسم كل خانة بـ`maxLines: 1` و`softWrap: false` داخل
      `FittedBox(scaleDown)` — النص يصغُر ليدخل ولا يلتفّ ولا يُقصّ، والارتفاع `cellHeight` واحد
      في الرأس والافتتاح والسطور والمجاميع.
- [x] **ارتفاع يكبر مع خط النظام:** `cellHeight = fontSize × textScaler × 1.55 + padding × 1.6`،
      فيكبر الصف مع تكبير الخط ولا يُقطع الحرف.
- [x] **حجم خط موحّد مقيس:** `_fitFactor` يقيس عناوين الرأس وأرقام الافتتاح والمجاميع فعلياً
      بـ`TextPainter` ويختار **أصغر نسبة** تجعلها في سطر واحد، بحدّ أدنى `0.62`؛ وما شذّ عن القياس
      تصغّره خانته وحدها — فلا تسحب قيمة طويلة واحدة كل أرقام التقرير.
- [x] **أعمدة بالبكسل لا بـ`Flex`:** `_columnWidths` تحسب العروض مرة واحدة من عرض الجدول، وآخر عمود
      يأخذ الباقي، و`FixedColumnWidth` تُستخدم في كل الكتل — فلا يزيح تقريب الكسر عموداً بين كتلتين.
      النتيجة مؤكَّدة باختبار يقارن حدود خانة «الرصيد» في الرأس وفي سطر المجاميع على عرض 1100.
- [x] **الأرقام تُقرأ LTR:** `textDirection: ltr` في الخانات الرقمية، فالسالب يبقى «-4,418.39» ولا
      يُقلب «4,418.39-» مع اتجاه الواجهة العربية.
- [x] **الشكوى الثانية:** حقول الإحصاء الظاهرة افتراضياً صارت خمسة فقط: **السابق · وارد · منصرف ·
      الصافي · الرصيد الحالي** (`ReportStatFields.defaultIds`)، وما عداها — السطور، قيمة الوارد،
      قيمة المنصرف، قيمة الرصيد — مخفي حتى يُظهره المستخدم من «تخصيص»، والاختيار يسري على الشاشة
      والمطبوع معاً لأن `_statIds` تبدأ بالقائمة الافتراضية لا بـ`null`.
- [x] **النافذة تقول ذلك:** سطر «تخصيص» صار يسمّي الخمسة الظاهرة وينبّه أن الباقي مخفي حتى يُختار.
- [x] **الاختبارات:** مجموعة `table geometry` جديدة (4): كل خلية سطر واحد على هاتف 380 مع خط
      ١٫٢٥ · ارتفاع خلية واحد في الرأس والافتتاح والسطور والمجاميع · مسار عمود واحد بين الرأس
      والمجاميع · السالب LTR.
- [x] **الحصاد:** `flutter analyze` → **No issues found!** · `test/features/stores/` **153 ناجحاً** ·
      `flutter test` **629 ناجحاً** (~10 متخطّى) · **لا DDL ولا DML** · **بلا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 05:05 · **DDL:** لا · **DML:** لا · **لا commit**.


---

## 2026-11-09 05:29 — عرض الفاتورة: العميل والدفع في سطر واحد دائماً وضغط بطاقة القماش

- [x] **بيانات العميل:** `TailoringCellGrid(rows: 1)` — عدد الأعمدة من عدد الحقول لا من عرض الشاشة، فالهاتف ورقم العميل ورقم الحساب في **سطر واحد** على 320/360/1024، وكل قيمة داخل `FittedBox` يصغر خطّها بدل أن يُقصّ. والاسم داخل `FittedBox` بجانب العنوان فلا يختفي.
- [x] **تفاصيل الدفع:** `TailoringCellGrid(rows: 1)` لكل الأرقام (الإجمالي · الخصم · الصافي · المدفوع · المدفوعات الأخرى · المتبقي · رقم السند) بحصص متساوية وتسمية/قيمة مقياسيتين — لا عمود يلتفّ ولا نصّ يختفي عند كبر حجم الخط أو المساحة.
- [x] **بطاقة القماش:** وضع `compact` في `TailoringCell` (تسمية سطر واحد بـ`FittedBox` وحشو 3/2 وقيمة 12)، وحذف الحشو الخارجي (1px) وخفض الفاصل بين البطاقات إلى 4 — فاختفى الفراغ أسفل الخلايا وقلّ ارتفاع البطاقة، وكل المحتوى ظاهر ومتجاوب.
- [x] **عنوان القسم:** داخل `FittedBox`، وذيل القسم (الشارة) بسقف عرض 168 وتصغير تلقائي — كبر حجم الخط لا يدفع السطر إلى التجاوز.
- [x] **اختبار جديد:** `a large text scale keeps customer and payment on one row` على 360 بكسل بـ`textScaler: 1.6` يتحقق من سطر واحد للعميل والدفع ومن `takeException() == null`.
- [x] **التحقق:** اختبارات التفصيل **57** ناجحة · `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 05:29 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:10 — الدفع والأقمشة: ارتفاع الصف يتبع المحتوى فقط (لا فراغ أسفل الخلايا)

- [x] **العلة:** صفوف الشبكة كانت `IntrinsicHeight` + `Row(crossAxisAlignment: stretch)`، فتُمدّ كل خلية إلى ارتفاع أطول خلية، ويُدفع النص إلى الأعلى ويبقى شريط فارغ أسفلها — وهو ما ظهر في «تفاصيل الدفع» وفي بطاقة القماش.
- [x] **الإصلاح:** `TailoringCellRow` و`TailoringCellGrid` بُنيتا على `Table` (`defaultVerticalAlignment: top`) — ارتفاع الصف من محتواه، والفواصل الرأسية والأفقية من `TableBorder` فتبقى ظاهرة بطول الصف الكامل.
- [x] **`TailoringCell`:** القيمة داخل `Align(heightFactor: 1)` فلا تتمدد رأسياً، مع بقاء محاذاة الأرقام.
- [x] **بيانات القماش:** خانة «العرض» صارت `clothWidth ?? clothType` — تعرض الرقم (58/45/38) عند توفره، ولا تعود فارغة «—» حين يغيب العمود.
- [x] **اختبار جديد:** `payment and fabric rows hug their content height` — ارتفاع صف الدفع < 64 بكسل وارتفاع صف بيانات القماش < 56 بكسل (برهان على غياب الفراغ).
- [x] **التحقق:** اختبارات التفصيل **58** ناجحة · `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:10 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:31 — الموديلات والمستفيدون: أعمدة مقياسية ومستفيد يعود لاسم العميل، ولون/سعر القماش

- [x] **جدول الموديلات:** أُعيد بناؤه `Table` بأوزان `[2.4, 4.0, 1.4, 4.2]` ورأس واحد، وكل خلية داخل `FittedBox` سطر واحد — لا «الق...» في الرأس ولا اسم مقصوص، والخط يتناسب مع المساحة. والاختيار يتم من الصف نفسه (`rowIndex`) لا بمطابقة النص.
- [x] **المستفيد الفارغ = العميل نفسه:** `ModelSelectorStrip(customerName:)` — إن غاب المستفيد يُعرض اسم العميل الأصلي بلون ثانوي بدل «—».
- [x] **اللون:** `colorText ?? colorNo` — القاعدة تخزّن اللون رقماً في `CLOTHS_COLOR` و`CLOTHS_COLOR2` فارغ، فظهرت «—» سابقاً.
- [x] **السعر:** `SANF_PRICE` كان 0 لبعض الأقمشة بينما القيمة الحقيقية في `SANFPRICE`؛ صار الاستعلام `NVL(v.SANFPRICE, v.SANF_PRICE) AS SANF_PRICE`، والعميل يعرض «—» بدل 0 المضلّل.
- [x] **الملاحظة:** مُدقَّقة حياً: `SALES_DETAILES_SHAPES.NOTES2` هو حامل الملاحظة الوحيد (36,150 صفاً بقيمة)، والخادم يقرأه فعلاً؛ خلوّها لفاتورة معيّنة يعني `NOTES2 = NULL` لتلك القطعة لا خطأ في الكود.
- [x] **اختبار جديد:** `a model with no beneficiary shows the customer name` — الاسم يظهر 3 مرات (العنوان + صفّا الموديل)، ورؤوس الأعمدة كاملة على 360 بكسل، بلا أي تجاوز.
- [x] **التحقق:** اختبارات التفصيل **59** ناجحة · `flutter analyze lib` = **No issues found!** · `pint` على المتحكم = PASS.
- [!] ما يظهر في جهاز المستخدم (سعر 0، لون «—»، ملاحظة «—»، عرض «—») يطابق **خادم API قديم**؛ هذه الحقول تُصلَح من الخادم، فتحتاج إعادة نشر/تشغيل `kyApp_API` ليراها التطبيق.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:31 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:54 — التفصيل: علامة صح للموديل المحدد + ملاحظة الموديل من الـ VIEW

- [x] **علامة الاختيار:** `ModelSelectorStrip` صار بجدول من خمسة أعمدة، أولهما عمود بعرض 24px يحمل
  `check_circle` أخضر في سطر الموديل المحدد وسطراً فارغاً لغيره — والتمييز اللوني للصف باقٍ.
- [x] **`MODEL_NOTES` في `CUTTING_SALES_BILL_VIEW`:** أُعيد إنشاء العرض بـ
  `CREATE OR REPLACE FORCE VIEW` مع إضافة `sales_detailes_shapes.notes2` في آخر قائمة
  SELECT وآخر قائمة الأعمدة (إضافة في النهاية فقط، فلا تنكسر المستهلكات القائمة).
  قياس بعد الإنشاء: العمود موجود، **45,490** صفاً، وعيّنة `bill 6 / seq 60373` تحمل ملاحظة فعلية.
- [x] **الخادم:** `detailSql` صار يقرأ `v.MODEL_NOTES AS NOTES2` بدل `s.NOTES2` — أي أن مصدر
  الملاحظة في الواجهة هو الحقل الجديد في الـ VIEW كما طُلب.
- [x] **الواجهة:** الملاحظة تُعرض في عمود «الملاحظة» من `specs.notes` القادمة من الـ VIEW.
- [x] **التحقق:** Pest `Tailoring` = **11 ناجحاً / 187 تأكيداً** · اختبارات التفصيل **59 ناجحة** ·
  `flutter analyze lib` = **No issues found!** · `pint` = PASS.
- [x] **التوثيق:** أمر الـ DDL ونتائجه مسجّلان في `db_commends.md` و`DBdevloping_history.md`.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:54 · **DDL:** `CREATE OR REPLACE VIEW` (إضافة عمود) · **لا DML** · **لا commit**.


---

## 2026-11-09 07:20 — التفصيل: إزالة خطأ البداية في القائمة + ظهور عمود الملاحظة

- [x] **خطأ «تعذّر جلب فواتير التفصيل» العابر:** سببه طلبان متزامنان — `build()` للمزود كان يطلق
  `Future.microtask(load)` بينما الشاشة تطلق `load()` في `initState`، فالثاني يلغي الأول
  (`CancelToken.cancel`) ويظهر خطأ ثم تُعرض القائمة. أُزيل الإطلاق من `build()` (الشاشة وحدها
  تطلب التحميل)، وأُطفئ `isLoading` عند إبطال الطلب ببصمة أحدث، والخطأ لا يُعرض إلا عندما
  تكون القائمة فارغة.
- [x] **عمود الملاحظة:** تحقّق مباشر أن الخادم يعيدها فعلاً من الـ VIEW:
  `TailoringController::show(6, 2026)` أعاد `specs.notes` بطول **17** حرفاً.
- [x] **الفاتورة التي لا تحمل ملاحظة موديل:** `NOTES2` لها `NULL` فعلاً في القاعدة (فاتورة
  21464)، فأُضيف بديل يعرض **ملاحظة الفاتورة** (`SALES_BILL.DETAILES`) في العمود كما تفعل
  شاشة النظام القديم — فلا يبقى العمود «—» وفي الفاتورة ملاحظة.
- [x] **التحقق:** اختبارات التفصيل **59** ناجحة · Pest `Tailoring` **11/187** ·
  `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 07:20 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 08:08 — التفصيل: الملاحظة من `MODEL_NOTES` فقط + إصلاح جذر خطأ القائمة

- [x] **عمود الملاحظة:** أُزيل بديل «ملاحظة الفاتورة» نهائياً؛ العمود يعرض
  `MODEL_NOTES` من الـ VIEW عبر `specs.notes`، وإن كانت غير موجودة تبقى الخلية **فارغة** بلا
  شرطة ولا نص.
- [x] **جذر خطأ «تعذّر جلب فواتير التفصيل»:** السجل أظهر
  `Undefined array key "ORDSNAME" at CuttingViewReader.php:186` — درايفر أوراكل يعيد المفاتيح
  بحروف صغيرة (`ordsname`) والقراءة كانت بحروف كبيرة، فتحوّلت الملاحظة إلى استثناء يُفشل الطلب
  كله. أُصلحت القراءة لتقبل الحالتين، وصار اسم الحالة غير متوفر ⇒ `null` بدل استثناء.
- [x] **إثبات حيّ:** `TailoringController::index()` أعاد **200** و`success=true` و
  `total=13748` بعد الإصلاح (كان 500).
- [x] **استرجاع تراجع جانبي:** `CuttingBillPayment.balanceLabel` فقد فرع «رصيد مقدم» فأعاد
  الاختبار فشلاً — أُعيد الفرع (`remaining < 0` ⇒ «رصيد مقدم»).
- [x] **التحقق:** Flutter **59** ناجحة · `analyze` نظيف · Pest `Tailoring` **11/187** · `pint` PASS.

**النموذج:** Qoder · **الوقت:** 2026-11-09 08:08 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 09:11 — التفصيل: ملاحظة الموديل كانت تُقرأ من الموضع الخطأ في العميل

- [x] **التشخيص:** استعلام المستخدم `MODEL_NOTES` لـ `bill 21514 / seq 85226` يعيد قيمة،
  والإثبات الحيّ أن المتحكم يعيدها فعلاً: `show(21514, 2026)` ⇒ `models[seq=85226].specs.notes`
  بطول **28** حرفاً. فالخادم والـ VIEW سليمات، والعطب في العميل.
- [x] **الجذر:** `CuttingModelItem.fromJson` كان يمرّر **جذر الموديل** إلى
  `CuttingModelSpecs.fromJson`، بينما الخادم يُعشّن المواصفات داخل `models[i].specs` —
  فقراءة `notes`/`neck_type` من الجذر تُعطي `null` دوماً. الاختبارات القديمة مرّرت المواصفات
  **مسطّحة** في الجذر فنجحت رغم الخلل (Fixture vs Reality).
- [x] **الإصلاح:** تُقرأ المواصفات من `json['specs']` إن وُجدت، وإلا من الجذر (توافق خلفي).
- [x] **اختبار جديد:** `specs are read from the nested server map` بشكل الخادم الحقيقي.
- [x] **قرار المستخدم:** إبقاء تعديلاته على `cutting_bill_detail_model.dart` (بلا فرع «رصيد
  مقدم» وبلا ضمّ المدفوعات الأخرى في `paidTotal`)، وحُدِّث اختبارا الدفع ليطابقا ذلك.
- [x] **التحقق:** Flutter **60** ناجحة · `analyze` نظيف.

**النموذج:** Qoder · **الوقت:** 2026-11-09 09:11 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-09 10:06 — التفصيل: تصحيح الصافي والمتبقي في تفاصيل الدفع

- [x] **التحليل الحيّ (1,200 فاتورة تفصيل):** عمود `NET` في `SALES_BILL` يساوي `TOTAL` الخام في
  **1192/1200** فاتورة ولا ينقص مع الدفع إطلاقاً (فواتير مدفوعة بالكامل NET=TOTAL). إذن NET ليس
  صافياً ولا متبقياً — كان الخادم يقرأه خطأً.
- [x] **الاستنتاج (طابق كل الأمثلة):** الصافي = الإجمالي − الخصم، والمتبقي = الصافي − المدفوع −
  المدفوعات الأخرى. مسدّدة ⇒ متبقٍ 0 (فاتورة 27: 248000−140000−108000=0)، جزئية ⇒ صحيح
  (44: 72000−30000=42000)، بخصم (48: 51000−3000−48000=0).
- [x] **الخادم:** `paymentPayload` صار يحسب `net = total - discount` و`remaining = net - paid -
  others` بدل قراءة عمود NET.
- [x] **الواجهة:** `bill_payment_card` أضاف خلية «مدفوعات أخرى» عند وجودها لتتّضح المعادلة.
- [x] **اختبار Pest جديد:** `payment net and remaining follow the deduced formula` يثبت المتساويتين.
- [x] **التحقق:** Pest `Tailoring` **12 ناجحاً / 189 تأكيداً** · Flutter **60** · `analyze` نظيف ·
  `pint` PASS.

**النموذج:** Qoder · **الوقت:** 2026-11-09 10:06 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-11-10 00:44 — التفصيل: تبسيط تفاصيل الدفع (الإجمالي · العربون · المتبقي فقط)

- [x] **قرار صاحب المؤسسة:** تُعرض ثلاثة حقول فقط — **الإجمالي**، **العربون**، **المتبقي** —
  ويُحذف **الخصم** و**الصافي** و**مدفوعات أخرى**.
- [x] **العربون** = `AMOUNT_PAID` وحده (بلا مدفوعات أخرى). **المتبقي** = `الإجمالي − العربون` فقط،
  بلا خصم ولا صافي ولا أي حساب آخر.
- [x] **الخادم:** `paymentPayload` صار يعيد `total` و`paid` و`remaining = total - paid` فقط
  (حُذف `discount`/`net`/`others_payments` من الحمولة).
- [x] **الواجهة:** `bill_payment_card` يعرض الإجمالي · العربون · المتبقي · رقم السند؛ المتبقي
  أخضر عند ≤0 وأحمر عند موجب.
- [x] **الاختبارات:** Pest `payment shows total, deposit and remaining = total minus deposit only`
  يثبت المتبقي ويؤكد غياب الخصم/الصافي/الأخرى · اختبار الواجهة يؤكد ظهور العربون/المتبقي وغياب
  الخصم/الصافي/مدفوعات أخرى.
- [x] **التحقق:** Pest `Tailoring` **12 ناجحاً / 190 تأكيداً** · Flutter **60** · `analyze` نظيف ·
  `pint` PASS. (لا تغيير قاعدة بيانات هذه الجولة.)

**النموذج:** Qoder · **الوقت:** 2026-11-10 00:44 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).
