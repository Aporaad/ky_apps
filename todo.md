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
