# سجل تطوير المشروع (Development History)

## [2026-09-08 03:50:01] - إضافة إمكانية إعداد والتحكم برابط Laravel API من واجهة التطبيق
- **الهدف:** تمكين المستخدم ومسؤول النظام من إعداد وضبط رابط خادم Laravel API من داخل واجهة التطبيق وحفظه في التخزين الآمن بدلاً من القيمة الثابتة، مع فحص الاتصال وتأكيد التغيير.
- **التغييرات المنفذة:**
  1. **التخزين المشفر (`lib/core/storage/secure_storage_service.dart`):**
     - إضافة مفتاح `ky_api_base_url`.
     - إضافة دوال: `saveApiBaseUrl()`, `getApiBaseUrl()`, `deleteApiBaseUrl()`.
     - تعديل دالة `clearAll()` لحذف بيانات الجلسة والمستخدم فقط مع الحفاظ على عنوان الخادم المخصص.
  2. **ثوابت الـ API (`lib/core/constants/api_constants.dart`):**
     - تعريف `defaultBaseUrl` و `testConnectionEndpoint = '/hello'` و `testTimeout`.
  3. **عميل الشبكة (`lib/core/network/dio_client.dart`):**
     - دعم تمرير `baseUrl` ديناميكياً وإضافة دالة `updateBaseUrl(String newUrl)` ودالة `initializeBaseUrl()`.
  4. **مستودع إعدادات الـ API (`lib/features/settings/data/repositories/api_config_repository.dart`):**
     - قراءة وحفظ وتطبيع الرابط وفحص الاتصال بالخادم مع قياس زمن الاستجابة بالميلي ثانية وتفصيل حالات النجاح والخطأ.
  5. **إدارة الحالة عبر Riverpod (`lib/features/settings/presentation/providers/`):**
     - إنشاء `ApiConfigState` و `ApiConfigNotifier` للتحكم بحالة الرابط وفحص الاتصال والحفظ وتحديث الـ DioClient فورياً.
  6. **شاشة إعدادات الـ API (`lib/features/settings/presentation/screens/api_settings_screen.dart`):**
     - واجهة متجاوبة بالكامل تدعم RTL واللغة العربية.
     - حقل إدخال URL مع اختصارات سريعة (الافتراضي، Localhost، Emulator).
     - زر فحص اتصال مع بطاقة نتائج تفاعلية تعرض حالة السيرفر وزمن الاستجابة.
     - زر حفظ مجهز بحوار تحذيري صارم بعنوان: *"تأكيد التغيير والتحذير بمخاطر التغيير"* لمنع التغيير غير المقصود.
  7. **التوجيه وشاشة تسجيل الدخول:**
     - إضافة مسار `/api-settings` إلى موجه التطبيق `appRouter`.
     - إضافة أيقونة إعدادات أنيقة أعلى شاشة تسجيل الدخول `LoginScreen` لفتح شاشة إعدادات الـ API.
  8. **التهيئة التلقائية (`lib/features/auth/presentation/providers/auth_notifier.dart`):**
     - ضمان تهيئة رابط الـ API المخصص من الذاكرة المشفرة عند بدء تشغيل التطبيق وقبل فحص جلسة الدخول.
  9. **الاختبارات:**
     - إضافة اختبارات وحدة في `test/api_config_test.dart` واجتياز كافة الاختبارات بنجاح (`flutter test` و `flutter analyze`).

## [2026-09-08 07:44:50] - تطوير قسم العملاء الشامل وكشف الحساب المعتمد لشركة الكبودي للخياطة
- **الهدف:** بناء وتطوير قسم العملاء المتكامل في تطبيق فلاتر وربطه بخادم Laravel API وقاعدة بيانات أوراكل، وتطبيق تصميم كشف الحساب المتطابق مع النموذج الرسمي المعتمد.
- **التغييرات المنفذة:**
  1. **الخلفية البرمجية (Laravel API & Oracle):**
     - بناء `CustomerController.php` وتوفير مسارات CRUD كاملة:
       - `GET /api/customers` : جلب قائمة العملاء مع البحث والتصفح.
       - `GET /api/customers/{id}` : جلب بيانات عميل محدد.
       - `POST /api/customers` : إضافة عميل جديد وتوليد `CUST_NO` تلقائياً مع التحقق.
       - `PUT /api/customers/{id}` : تعديل بيانات العميل.
       - `DELETE /api/customers/{id}` : حذف العميل.
       - `GET /api/customers/statement/{id}` : استعلام كشف حساب العميل بالربط بين `ENTRY_MAIN`, `ENTRY_SUB`, `ENTRY_TYPE`, `CUST`.
     - تسجيل المسارات في `routes/api.php`.
  2. **طبقة البيانات في Flutter (`lib/features/customers/data/`):**
     - إنشاء `CustomerModel` لدعم جميع حقول العميل في جدول `ACCOUNTS.CUST`.
     - إنشاء `CustomerStatementModel` لدعم حركات كشف الحساب مع حساب المدين والدائن والرصيد التراكمي.
     - إنشاء `CustomerRepository` لدعم جميع اتصالات الشبكة عبر Dio مع معالجة الأخطاء والتطبيع.
  3. **إدارة الحالة (`lib/features/customers/presentation/providers/`):**
     - إنشاء `CustomersListNotifier` و `customersListProvider` لإدارة قائمة العملاء والبحث والفرز.
     - إنشاء `CustomerStatementNotifier` و `customerStatementProvider` لإدارة تحميل كشف الحساب والإجماليات.
  4. **واجهات وشاشات قسم العملاء (`lib/features/customers/presentation/`):**
     - **لوحة تحكم العملاء (`CustomersDashboardScreen`):** واجهة رئيسية تضم 5 بطاقات تفاعلية أنيقة مع تدرجات لونية وتأثيرات ضغط سلسة لكل عملية:
       - **إضافة عميل:** فتح نموذج إضافة عميل جديد.
       - **تعديل عميل:** اختيار عميل عبر شاشة البحث ثم تعديل بياناته.
       - **حذف عميل:** اختيار عميل مع بطاقة تفاصيل وحوار تأكيد الحذف.
       - **كشف حساب:** اختيار عميل وفتح تقرير كشف الحساب.
       - **كل العملاء:** استعراض الشبكة/القائمة الكاملة للعملاء.
     - **نموذج بيانات العميل المشترك (`CustomerFormWidget`):** يضم كافة الحقول (`CUST_NAME`, `ADDR`, `TEL1`, `TEL2`, `POSTBOX`, `EMAIL`, `FAX`, `ACC_NO`, `LIMITED_BALANCE`, `PRE_CUST_NAME`, `STOPPING_CUST`) مع التحقق الصارم وواجهة عربية أنيقة تدعم RTL.
     - **شاشة اختيار العميل المشتركة (`CustomerPickerScreen`):** بحث فوري وعرض تفصيلي للعملاء مع تمييز العملاء الموقوفين.
     - **شاشة إضافة عميل (`AddCustomerScreen`):** إرسال البيانات وحفظها وعرض إشعارات النجاح أو الفشل.
     - **شاشة تعديل عميل (`EditCustomerScreen`):** تعديل البيانات وتحديث القائمة فورياً.
     - **شاشة حذف عميل (`DeleteCustomerScreen`):** معاينة بيانات العميل وتأكيد الحذف عبر حوار أمان مخصص.
     - **شاشة كل العملاء (`AllCustomersScreen`):** عرض متجاوب (Grid في الشاشات العريضة و List في الهواتف) مع بحث فوري وأزرار إجراءات سريعة.
     - **شاشة كشف حساب العميل المطابقة للصورة (`CustomerStatementScreen`):**
       - ترويسة رسمية لشركة الكبودي للخياطة الرجالية (الشعار النصي، شعار K.Y، وبانر العنوان وأرقام الهواتف).
       - شريط البيانات الوصفية (اسم العميل، رقم العميل باللون الأحمر، العملة يمني YR، رقم واسم الحساب، نطاق التاريخ).
       - جدول كشف الحساب المحاسبي باللون الخردلي/الذهبي للأعمدة: [السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد].
       - سطر الرصيد الافتتاحي بالألوان المطابقة (أحمر للمبالغ).
       - سطور الحركات اليومية والمبيعات مع تنسيق فواصل الآلاف.
       - سطر إجمالي العمليات ومربعات الرصيد الافتتاحي والنهائي باللون الذهبي والأحمر.
  5. **ربط بوابة الموظف (`CustomersSection`):**
     - تحديث `customers_section.dart` لعرض `CustomersDashboardScreen` مباشرة داخل البوابة.
  6. **الجودة والتحقق:**
     - تشغيل `flutter analyze` واجتياز الفحص بنجاح تام مع 0 أخطاء و 0 تحذيرات (`No issues found!`).

## [2026-09-08 20:13:50] - إكمال البحث بالهاتف، فلترة التواريخ، وتصحيح ترميز اللغة العربية
- **المشاكل التي تم حلها والتطويرات المنجزة:**
  1. **البحث برقم الهاتف (`TEL1`, `TEL2`):**
     - تم تحديث استعلامات `CustomerController.php` في Laravel لدعم البحث الفوري عن العملاء عبر أرقام هواتفهم بالإضافة إلى الاسم ورقم العميل.
     - تم تحديث شاشة اختيار العميل (`CustomerPickerScreen`) لعرض أرقام الهواتف وتمييزها في البحث بدون أي تأخير.
  2. **فلترة كشف الحساب بالتواريخ (`from_date` / `to_date`):**
     - إضافة شريط فلاتر متقدم في واجهة كشف الحساب (`CustomerStatementScreen`) يحتوي على منتقي تواريخ تفاعلي وأزرار فلترة سريعة (الكل، هذا الشهر، هذا العام).
     - تحديث الـ API لحساب الرصيد الافتتاحي التراكمي للحركات السابقة للنطاق المحدد، وتلخيص مجموع الحركات الدائنة والمدينة ضمن النطاق وحساب الرصيد النهائي بدقة.
  3. **حل مشكلة ترميز أوراكل للعربية (Windows-1256 / Mojibake):**
     - تم تطوير خوارزمية ذكية في `ArabicEncoding.php` تقوم بتحويل بايتات UTF-8 Latin-1 (الناتجة عن تخزين CP1256 في قاعدة بيانات `WE8MSWIN1252`) وترجمتها إلى محارف العربية الأصلية UTF-8.
     - النتيجة: ظهور أسماء العملاء والبيانات وسطور القيود باللغة العربية الواضحة 100% (مثل تحويل `ÎÇáÏ ÍÓÇä ÇáÑÌæí/127` تلقائياً إلى `خالد حسان الرجوي/127`).
     - توفير دعم العكس عند إدخال أو تعديل عميل جديد لحفظه متوافقاً مع قاعدة البيانات.
  4. **إصلاح مشاكل التجاوز والاستجابة (Responsive UI & RenderFlex Fixes):**
     - تم استبدال `ListTile` التقليدي في شاشة اختيار العميل بـ `Container` مخصص متجاوب يمنع أخطاء `Leading widget consumes the entire tile width` و `RenderFlex overflow`.
     - تحسين واجهة كشف الحساب للالتفاف التلقائي على الشاشات الضيقة والشاشات اللمسية وتوفير تمرير أفقي سلس للجدول المحاسبي.
  5. **إصلاح استدعاء Riverpod 3:**
     - تصحيح استدعاء `loadStatement` عبر `ref.read(customerStatementProvider.notifier).loadStatement(...)` وحل أخطاء IDE `[current_problems]`.
     - اجتياز `flutter analyze` بنجاح تام: `No issues found!`.

## [2026-09-08 20:28:50] - تصحيح استعلام البحث بالعربية في أوراكل وإدارة إلغاء طلبات Dio (Debounce)
- **سبب المشكلة السابقة:**
  1. **الاستعلام في أوراكل:** عندما يبحث المستخدم عن حرف أو كلمة عربية (مثل `ا` أو `خالد`)، يرسل المتصفح أو التطبيق النص بصيغة UTF-8. وحيث أن حقل `CUST_NAME` في قاعدة بيانات أوراكل `WE8MSWIN1252` مخزن ببايتات Windows-1256، فإن استعلام `WHERE CUST_NAME LIKE '%ا%'` لم يكن يطابق بايتات أوراكل المخزنة كـ Latin-1، مما تسبب في إرجاع 0 سجلات (`data: []`).
  2. **استثناء `DioException [request cancelled]`:** كان البحث يُرسل طلبات HTTP متتالية مع كل نقرة حرف (`onChanged`)، مما يلغي الطلب السابق (`CancelToken.cancel('new_request')`) ويطلق استثناء داخلي في وضع تصحيح الأخطاء (Debugger).
- **الإصلاحات المنفذة:**
  1. إضافة دالة `toOracleSearchChars` في `ArabicEncoding.php` تقوم بتحويل كلمات البحث العربية UTF-8 إلى المحارف اللاتينية المطابقة لبايتات Windows-1256 في أوراكل.
  2. تحديث استعلام البحث في `CustomerController.php` ليطابق كلاً من المحارف اللاتينية والنصوص العربية، والآن البحث يعيد آلاف السجلات المطابقة بنجاح ودقة فائقة.
  3. إضافة مؤقت تأخير تفاعلي (Debounce 300ms) في `CustomerPickerScreen` لمنع إرسال طلبات مفرطة أثناء الكتابة السريعة.
  4. تحسين `CustomerRepository` و `CustomersListNotifier` لتجاهل استثناءات إلغاء الطلبات بأمان تام وتجنب أي تعارض في حالة السباق (Race Conditions).
## [2026-09-08 20:53:00] - فتح منتقي العملاء مباشرة من بطاقات العمليات وجعل جدول كشف الحساب متجاوباً بنسبة 100%
- **التعديلات المنفذة:**
  1. **الفتح المباشر لشاشة اختيار العميل (`CustomerPickerScreen`):**
     - تحديث بطاقات (تعديل عميل، حذف عميل، كشف حساب) في `CustomersDashboardScreen` لتفتح فورياً شاشة اختيار العميل مع عنوان وأيقونة معبرة عن العملية.
     - بمجرد اختيار العميل، يتم توجيهه مباشرة إلى شاشة الإجراء المطلوبة (`EditCustomerScreen` مع تعبئة بيانات العميل المختار، `DeleteCustomerScreen` مع بطاقة العميل وحوار التأكيد، `CustomerStatementScreen` مع كشف حساب العميل).
     - تم تحديث كل من `EditCustomerScreen` و `DeleteCustomerScreen` لاستقبال `final CustomerModel? customer` في الـ Constructor وتهيئتها فورياً.
  2. **تحويل جدول كشف الحساب إلى تصميم متجاوب بدون شريط تمرير أفقي:**
     - استبدال القياسات الثابتة والـ `SingleChildScrollView(scrollDirection: Axis.horizontal)` بنظام مرن يعتمد على `LayoutBuilder` و `Table` مع أوزان نسبية `FlexColumnWidth` لجميع الأعمدة السبعة: [السند | النوع | تأريخه | البيان | مدين | دائن | الرصيد].
     - إضافة قياسات خطوط وهوامش متكيفة مع العرض المتاح (`isCompact` و `isVeryCompact`) واستخدام `FittedBox` للأرقام المالية لضمان عدم حدوث أي قص أو تجاوز عبر الشاشات الصغيرة والكبيرة.
  3. **الجودة والتحقق:**
     - اجتياز فحص `flutter analyze` بنجاح كامل بدون أي خطأ أو تحذير (`No issues found!`).

## [2026-09-08 22:31:29] - إضافة وتطوير قسم "جاري العاملين" وإصلاح مشاكل Riverpod والمسارات
- **التعديلات المنفذة:**
  1. **إضافة قسم "جاري العاملين" في بوابة الموظف:**
     - تحديث القائمة الجانبية `collapsible_side_drawer.dart` لإضافة بند "جاري العاملين" بأيقونة `groups_2_rounded`.
     - ربط القسم في `employee_main_layout.dart` كقسم رقم 8.
     - إنشاء `workers_section.dart` كحاوية متجاوبة تعرض شاشة لوحة تحكم العاملين `WorkersDashboardScreen`.
  2. **لوحة تحكم العاملين (3 بطاقات):**
     - تصميم 3 بطاقات ملونة وجميلة: (الموظفين `TAILOR_EMPLOYEES`، القصاصين `CUTTER`، الخياطين `TAILOR`).
     - كل بطاقة تعرض أيقونة مخصصة ووصفاً وتنقلاً سلساً إلى الشاشة المعنية.
  3. **شاشات القوائم والإجراءات:**
     - وضع زر إضافة العامل ("إضافة موظف" / "إضافة قصاص" / "إضافة خياط") في أعلى كل قائمة بجانب حقل البحث وفلتر المعطلين.
     - إضافة صف أيقونات إجراءات أنيق ومرتب `WorkerActionIcons`:
       - أيقونة كشف الحساب (تفتح شاشة كشف الحساب مع نطاق التاريخ).
       - أيقونة كشف الحضور للموظفين / كشف العمل للقصاصين والخياطين.
       - أيقونة التعديل (تفتح شاشة التعديل مع تعبئة البيانات مسبقاً).
       - أيقونة التعطيل/التفعيل الفوري مع رسالة تأكيد.
       - أيقونة الحذف مع حوار تأكيد أنيق.
  4. **شاشة كشف حساب العمال:**
     - بناء شاشة `WorkerStatementScreen` متكاملة تتصل بنقطة الـ API وتنفذ استعلام كشف الحساب المحدد بدقة.
     - شريط علوي لملخص الحساب: الرصيد الافتتاحي، إجمالي المدين، إجمالي الدائن، والرصيد النهائي.
     - جدول متجاوب يعرض أرقام السندات، التواريخ، الأنواع، البيان، والمبالغ.
     - تصفية التاريخ (من / إلى) مع أزرار تصفية سريعة.
  5. **تصحيح مشاكل Riverpod والمسارات:**
     - إصلاح مشكلة `WorkersListNotifier` ليورث `Notifier<WorkersListState>` بدلاً من الكلاس غير المتوافق مع Riverpod 3، مع تمرير `WorkerType` عبر الكونستركتور ومزود `NotifierProvider.family`.
     - تصحيح مسارات الاستيراد النسبية في `workers_section.dart`.
     - تنظيف جميع الـ Unused Imports واجتياز فحص `flutter analyze` بنجاح كامل بدون أي خطأ أو تحذير (`No issues found!`).

## [2026-09-08 23:05:42] - إصلاح مشكلة قراءة رقم الحساب لكشف حساب العاملين وإضافة Debounce للبحث
- **سبب المشكلة السابقة:**
  1. في Laravel `WorkerController.php`، تم البحث عن `$worker->ACC_NO` بحروف كبيرة، بينما كائن الـ PDO العائد من استعلام أوراكل يحوي أسماء الحقول بحروف صغيرة `$worker->acc_no`، مما تسبب في إرجاع خطأ `422 (لا يوجد رقم حساب مرتبط بهذا العامل)`.
  2. في تطبيق Flutter، الكتابة السريعة في حقل البحث كانت ترسل طلبات HTTP فورية بدون تأخير تفاعلي (Debounce)، مما يطلق استثناءات إلغاء الطلبات السابقة في Dio.
- **الإصلاحات المنفذة:**
  1. تحديث `WorkerController.php` في دوال `fetchStatement` و `toggleWorker` لدعم قراءة الحقول بالحروف الصغيرة والكبيرة على حد سواء من `$worker` و `(array)$worker`.
  2. تحسين استعلام كشف الحساب وتصفية التواريخ بدالة `TRUNC(ENTRY_DATE)` وتحويل التواريخ بصيغة `TO_CHAR(ENTRY_DATE, 'DD/MM/YYYY')`.
  3. إضافة مؤقت تأخير تفاعلي (Debounce 300ms) في `WorkersListScreen` لإرسال طلب البحث بعد توقف المستخدم عن الكتابة وتفادي إلغاء الطلبات والضغط غير الضروري على الخادم.
  4. فحص واختبار مسارات كشف الحساب والبحث بنجاح واجتياز `flutter analyze` بدون أي خطأ أو تحذير (`No issues found!`).

## [2026-09-12 21:10:29] - تطوير قسم الحسابات والشجرة المحاسبية والعملات وإصلاح كافة المشاكل البرمجية
- **الهدف من التحديث:**
  بناء وتطوير قسم الحسابات بالكامل لربطه بقاعدة بيانات Oracle مع واجهات المستخدم التفاعلية المتطورة:
  1. إنشاء حساب (مجموعة حسابات جزئية وحساب مالي).
  2. تعديل حساب مالي.
  3. كشف حساب عادي.
  4. كشف حساب مفصل مع خيارات تصفية متقدمة.
  5. الشجرة المحاسبية التفاعلية (مع فلترة استثناء العملاء ما عدا "عملاء الكبودي للخياطة" رقم 12310000 وخيارات الطباعة والتصدير والبحث).
  6. إدارة العملات وأسعار الصرف اليومية والتاريخية.
  7. حل كافة الأخطاء والتحذيرات واجتياز `flutter analyze lib` بنجاح كامل بدون أي خطأ أو تحذير (`No issues found!`).

- **التغييرات المنفذة بالتفصيل:**
  1. **الـ Backend (Laravel API):**
     - إنشاء `AccountController.php`: دوال جلب هيكل الشجرة (`ACCOUNT`، `ACC_MAIN`، `ACC_SUB`، `ACC_SUB_GROUP`)، جلب وإنشاء وتعديل الحسابات المالية (`CHART_ACC`)، واستخراج كشف الحساب العادي والمفصل مع معالجة ترميز النصوص العربية (Windows-1256).
     - إنشاء `CurrencyController.php`: دوال إدارة العملات (`CURRENCY` و `CUR_CODE`) وأسعار الصرف وسجل التغيرات السعرية السابقة (`CUR_PRICE`).
     - تسجيل كافة المسارات في `routes/api.php`.
  2. **طبقة البيانات في Flutter (Data Layer):**
     - إنشاء نماذج البيانات: `account_model.dart` (يمثل الشجرة والعقد والمجموعات)، `chart_account_model.dart` (يمثل الحساب المالي وكشوفات الحركات)، و `currency_model.dart` (يمثل العملات وأسعار الصرف).
     - إنشاء مستودعات البيانات: `account_repository.dart` و `currency_repository.dart` عبر عميل Dio المركزي مع دعم إلغاء الطلبات وإدارة الأخطاء.
  3. **مزودات الحالة (Riverpod Providers):**
     - إنشاء `accounts_provider.dart`: يتضمن `AccountTreeNotifier` و `ChartAccountsNotifier` ومزودي السلسلة الهرمية للحسابات الأب المتتالية.
     - إنشاء `currency_provider.dart`: يتضمن `CurrenciesNotifier` وإدارة إضافة وتعديل العملات وأسعار الصرف التاريخية `currencyPricesProvider`.
  4. **واجهات المستخدم (Presentation UI):**
     - `accounts_dashboard_screen.dart`: لوحة تحكم متكاملة ببطاقات ذات تدرج لوني وتصميم حديث وإحصائيات سريعة.
     - `create_account_screen.dart`: واجهة تفاعلية تتيح للمستخدم الاختيار بين إنشاء "حساب مالي" أو "مجموعة حسابات جزئية" مع قوائم منسدلة متسلسلة للأب والتحقق من المدخلات.
     - `edit_account_screen.dart`: واجهة تعديل بيانات الحساب وسقف الرصيد وحالة التوقيف.
     - `account_statement_screen.dart`: شاشة كشف حساب مالي مشابهة لكشف حساب العاملين مع محدد الحساب والتاريخ وبطاقات ملخص الرصيد والدائن والمدين.
     - `account_statement_detail_screen.dart`: شاشة كشف حساب مفصل مع تصفية مستويات الحساب (الكل، قسم رئيسي، فرعي، جزئي، مجموعة، حساب مالي) وتصفية العملات والتواريخ.
     - `account_tree_screen.dart`: شاشة الشجرة المحاسبية التفاعلية، تدعم البحث اللحظي، وتوسيع/طي الكل، وتصدير/طباعة (PDF، Excel)، وتطبيق قاعدة استثناء حسابات العملاء ما عدا حساب "عملاء الكبودي للخياطة" (12310000).
     - `currency_screen.dart`: شاشة عرض بطاقات العملات مع مؤشرات الارتفاع/الانخفاض، وإضافة وتعديل العملات، ونافذة سفلية لإدارة سجل أسعار الصرف التاريخية.
     - دمج `AccountsDashboardScreen` داخل `AccountsSection` في `ky_apps/lib/features/employee_portal/presentation/screens/sections/accounts_section.dart`.
  5. **إصلاح المشاكل والتوافق البرمجي:**
     - استبدال `AppColors.cardBackground` بـ `AppColors.surface` و `lightBackground` بـ `AppColors.surfaceSubtle` لتطابق ثيم التطبيق المعتمد.
     - استبدال `MaterialStateProperty` بـ `WidgetStateProperty` المتوافق مع إصدارات Flutter الحديثة.
     - استبدال استخدام حزمة `intl` بدوال تنسيق محلية احترافية بدون إضافة اعتمادات خارجية غير ضرورية.
     - استبدال `withOpacity` بـ `withValues(alpha: ...)` لمعالجة كافة التحذيرات.
     - إزالة المتغيرات والاستيرادات غير المستخدمة.
     - اجتياز اختبار `flutter analyze lib` بنجاح تام: `No issues found!`.


## [2026-10-04 06:14:00] - ����� DioException ������ RenderFlex �� ��� ��������
- ����� CancelToken �� WorkerRepository ��� _listCancelToken � _statementCancelToken
- ����� Overflow �� pagination bar �� Expanded � TextOverflow.ellipsis
- ����� Overflow �� workers_list_screen.dart �� Flexible ��� ����� Row ������� ������
- �������: worker_repository.dart - worker_statement_screen.dart - workers_list_screen.dart

---
## [2026-10-04 23:41:00] - ����� ������� Biometric Authentication - Claude Sonnet 4.6 (Thinking)
- **������:** ����� ������� ������ �������� ���� ��� ����� ���� ����� ������ ��������� �������
- **������� ������:**
  - ������ AuthController.php, User.php Model, routes/api.php
  - ������ auth_repository.dart, auth_notifier.dart, login_screen.dart, secure_storage_service.dart
  - ������� Oracle DB: NEW_USERS table ����� 15 ���� (�� ���� ���� biometric)
  - ������� ����� Oracle ������� (USER_BIOMETRIC_DEVICES ��� �����)
- **������ ��������:** ����� device_token ����� �� ���� ���� USER_BIOMETRIC_DEVICES + �������� ������� ������ ��� local_auth
- **�������:** ��� ����� ����� ���� 16 ���� � 16 ��� (5 ���� + 11 ����� + ���� DB ����)


---
## [2026-10-05 09:40:00] - ضبط وإعادة تصميم واجهات قسم الحسابات - Gemini 3.7 Flash
- **الملفات المعدلة**:
  - [accounts_dashboard_screen.dart](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/lib/features/accounts/presentation/screens/accounts_dashboard_screen.dart):
    - إعادة بناء وتصميم واجهة الحسابات بالكامل.
    - حل مشكلة البطاقات الضخمة غير الموزونة التي كانت تأخذ ارتفاعاً وعرضاً مفرطاً وتسبب فوضى بصرية في الشاشات.
    - تقسيم الخدمات المحاسبية إلى 3 مجموعات واضحة ومنظمة:
      1. **التقارير والكشوفات المالية**: كشف حساب مالي عام، وكشف حساب تحليلي مفصل.
      2. **الهيكل المحاسبي وإدارة الحسابات**: الشجرة المحاسبية، إضافة حساب جديد، وتعديل بيانات حساب.
      3. **العملات وأسعار الصرف**: دليل العملات وأسعار الصرف وسجل التحديثات.
    - إدراج شريط إحصائيات علوي مدمج ومتناسق (إجمالي الحسابات، العملات المفعلة، أقسام الشجرة).
    - إضافة وسوم توضيحية (Badges) وأيقونات ملونة بألوان هادئة ومتناسقة مع هوية التطبيق.
    - تحسين مربع حوار اختيار الحسابات للتعديل وعرض الكشوفات المباشرة.
- **الفحص والتحقق**: تشغيل lutter analyze والتأكد من خلو المشروع تماماً من أي أخطاء أو تحذيرات (No issues found!).

---
## [2026-10-17 05:25:00] - تنفيذ مرحلة 0 و1 من نظام الصلاحيات IBAC — Qoder Agent
- **الخطة المرجعية**: `ibac_permissions_plan.md` (v2) — القرارات D1–D9، كتالوج 17 وحدة / 93 صلاحية، الجلسات الانزلاقية الصامتة، واجهات الإدارة المطلوبة.
- **الملفات المضافة (خلفية Laravel فقط — لم يُمسّ أي كود Flutter بعد)**:
  - [PermissionCatalog.php](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/kyApp_API/app/Support/PermissionCatalog.php):
    - المصدر الوحيد الصحيح لكتالوج الصلاحيات: الوحدات السبع عشرة بأسمائها العربية، والأفعال الأساسية الأربعة
      (`view · create · update · delete`) لكل وحدة ثم الصلاحيات الإضافية من بعدها، تماماً كما طلب المستخدم.
    - يولّد `rows()` الجاهزة للإدراج، و`grouped()` لواجهات اختيار الصلاحيات، و`codes()` و`knows()`
      و`isValidCode()` للتحقق، و`wildcardFor()` لصيغة المنح العام `module.*` و`system.*`.
    - `SORT_ORDER = رقم الوحدة × 100 + رقم الفعل` فيظهر الأساسي قبل الإضافي في أي عرض بلا منطق ترتيب.
  - [01_ibac_schema.sql](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/kyApp_API/database/oracle/01_ibac_schema.sql):
    نص DDL الكامل قابل لإعادة التشغيل، مع تعليق موثّق يمنع تكرار خطأ أسماء التسلسلات المسبوقة.
  - [02_ibac_seed.php](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/kyApp_API/database/oracle/02_ibac_seed.php):
    بذر 93 صلاحية و10 إعدادات أمان مشتقة من `PermissionCatalog` نفسه (لا تباعد بين الخادم والقاعدة)، idempotent،
    واستعلامات مربوطة حصراً، والقيم المحرَّرة من المشغّل لا تُستبدل عند إعادة التشغيل.
  - [03_ibac_bootstrap.php](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/kyApp_API/database/oracle/03_ibac_bootstrap.php):
    49 تعليق قاموس بيانات ثنائي اللغة + ترقية أول مدير نظام بحماية من فقدان الوصول (لا ترقية ثانية إذا وُجد مدير)
    + منح `system.*` + صفحة تدقيق واحدة.
  - [04_ibac_rollback.sql](file:///c:/Users/Mujeeb/Desktop/arslan/ky_apps/kyApp_API/database/oracle/04_ibac_rollback.sql): تراجع كامل مرتّب بعكس الاعتماديات.
- **قرار تنفيذي مهم**: لم تُستخدم Laravel migrations لمخطط الأعمال — لأن `AGENTS.md` يمنع ترحيل مخطط `ACCOUNTS`
  الإرثي من هذا المستودع؛ بدلاً منها سكربتات `database/oracle/*` تُنفَّذ عبر موصل Oracle وتُوثَّق في `db_commends.md`.
- **البذر بـ PHP لا SQL**: موصل Oracle عميل `AL32UTF8` وقاعدة البيانات `WE8MSWIN1252`، فتمرير بايتات CP1256
  من ملف `.sql` يُنتج `0xBF`. المسار الصحيح للكتابة هو `ArabicEncoding::toOracleSearchChars()`.
- **مشكلتان تم إصلاحهما أثناء العمل**:
  1. `ORA-04098 / PLS-00302` على المحفِّزات الأربعة: السبب وجود `VIEW` اسمه `ACCOUNTS` داخل المخطط، فـ
     `ACCOUNTS.SEQ_X.NEXTVAL` يُقرأ كعمود عرض. أُعيد إنشاء المحفِّزات بأسماء تسلسلات غير مسبوقة (كما تفعل
     محفِّزات النظام القديمة) فصارت `VALID`، وتحقّق البذر أن المحفِّز يملأ `ID` و`PERMISSION_ID`.
  2. `ORA-01745` عند إدراج سجل التدقيق: اسم الربط `:desc` يحجز كلمة `DESC`؛ استُبدل بـ `:descr`.
- **مكتشف يجب علاجه في جولة قادمة**: كل مسارات الكتابة العربية في `CustomerController` و`CurrencyController`
  و`AccountController` تستخدم `encodeForOracle()` أي بايتات خام تُستبدل بـ `0xBF` عند الحفظ عبر اتصال AL32UTF8.
- **الفحص والتحقق**: جداول جديدة 4 + `APP_USERS_BAK_IBAC`، تسلسلات 5، محفِّزات 4 بحالة `ENABLED/VALID`،
  فهارس 13، تعليقات 4 جداول + 45 عموداً، `APP_PERMISSIONS=93` (47 أساسية + 17 منحاً عاماً)، `APP_SETTINGS=10`،
  صفر كائن `INVALID`، وتحقّق `DUMP(NAME_AR)` أن العربية مخزّنة بايتات CP1256 سليمة، وإعادة تشغيل السكربتات
  أثبتت idempotency (`ADMIN skipped (admins=1)` و`GRANT already granted`).


---
## [2026-10-17 07:17:24] - المرحلة 2: طبقة IBAC في الخلفية (النواة البرمجية)
- **النموذج المنفذ / AI Model:** Qoder Agent
- **الهدف / Goal:** بناء نواة الصلاحيات والجلسات والإعدادات وسجل النشاط في `kyApp_API` قبل أي واجهة،
  بحيث تُقرأ الصلاحيات من `APP_USERS_PERMISSIONS` ويُدار عمر الجلسة عبر `PERSONAL_ACCESS_TOKENS.EXPIRES_AT`
  دون أي تعديل مخطط على جدول التوكنات.
- **الملفات الجديدة:**
  1. `app/Http/Middleware/EnsurePermission.php` — حارس صلاحية واحد للمعرّف، يعيد 401 بلا مستخدم و403
     مع اسم الصلاحية العربي عند الرفض، وتمرير للمطلب عند المنح. وهو أول ملف في مجلد
      `app/Http/Middleware` (مسموح به في الخطة D9).
  2. `tests/Feature/IbacCoreTest.php` — 12 اختباراً / 60 تحققاً يغطي القاموس والحل وسياسة الجلسات والحارس.
- **الملفات المعدّلة:**
  1. `app/Support/PermissionCatalog.php` — أُضيف `arabicName(string $code)` لرسالة الرفض ثنائية اللغة.
  2. `bootstrap/app.php` — أول محتوى لـ `withMiddleware()`: الاختصار `permission` → `EnsurePermission::class`
     (يُستخدم بصيغة `permission:customers.view`).
  3. `app/Providers/AppServiceProvider.php` — تسجيل `SettingsStore` و`PermissionResolver` و`ActivityLogger`
     و`SessionPolicy` كـ singleton في `register()`، وتركيب `Sanctum::$accessTokenAuthenticationCallback`
     في `boot()` يستدعي `SessionPolicy::validate()` مع fallback آمن (`return $isValid`) عند أي استثناء.
  4. `config/sanctum.php` — إبقاء `expiration => null` مع تحذير موثّق (عربي/إنجليزي) أن تغييره يكسر
     التجديد الانزلاقي لأن `Guard::isValidAccessToken()` يقيس العمر المطلق من `created_at`،
     وإضافة `last_used_at => true` لأن شاشة الجلسات النشطة تعتمد على `LAST_USED_AT`.
  5. `app/Models/User.php` — `IS_ADMIN` إلى `$fillable` وحذف `USER_NO` الوهمي، ودالة `casts()` (رقمنة
     `user_id/is_activated/is_admin/user_type/branch_no/biometric_enabled`) ودالة `isAdmin()`.
  6. `app/Support/SessionPolicy.php` — إضافة `prime()` لمنح التوكن الجديد مهلة `session_idle_minutes`
     كاملة لحظة إصداره، وحذف تعليق `@param PermissionResolver` الخاطئ.
  7. `app/Support/SettingsStore.php` — إعادة تصميم الكاش بعد حادث `ORA-01461`: `MAX_CACHE_BYTES = 3000`
     و`CACHED_FIELDS` رقمية فقط، و`definitions()` تقرأ العربية من القاعدة مباشرة بلا كاش.
  8. `app/Support/PermissionResolver.php` — نفس سقف الـ 3000 بايت على كاش رموز الصلاحيات.
  9. `app/Http/Controllers/AuthController.php` — إعادة كتابة: حقن `PermissionResolver` و`SessionPolicy`
     و`ActivityLogger` عبر المنفذ، وكل من `login` و`biometricLogin` يجهّز التوكن الصادر بـ
     `sessions->prime($accessToken->accessToken)` فور إنشائه، وحملة `user` في الرد تُبنى من
     `userPayload()` (دالة خاصة جديدة) الذي يدمج
     الهوية + `is_admin` + `payloadFor()` (قائمة الصلاحيات و`can_*`)، و`me` يعيد نفس الحزمة، و`logout`
     يسجّل نشاطاً، وكل محاولة دخول فاشلة تُسجَّل في `APP_USER_ACTIVITY` عبر `ActivityLogger`.
- **قرار مؤجَّل ومدروس:** لم تُنشأ نماذج Eloquent (`AppPermission`/`AppPermissionGrant`/`AppSetting`/`UserActivity`)
  لأن كل طبقات IBAC تكتب وتقرأ بـ SQL مربوط مباشر على اتصال `oracle`، فإضافة نماذج بلا مستخدم تعارض
  «لا كود ميت». تُضاف عند الحاجة في مرحلة لاحقة.
- **التحقق نهاية-to-نهاية (قاعدة حيّة):** انظر `db_commends.md` بنفس الطابع الزمني — توكن فحص حصل على
  `EXPIRES_AT = created_at + 240 دقيقة`، وبانقضاء المهلة رفضت `SessionPolicy` الجلسة، وسطر نشاط عربي
  تحقّق بـ `DUMP(...,1016)` أنه بايتات CP1256 سليمة ثم قرئ بـ `fixMojibake()` عربياً صحيحاً.
- **حادث مكتشف وعولج:** `ORA-01461` في `merge into "CACHE"` — عمود `VALUE` من نوع CLOB لكن Laravel
  يمرّره عبر `SELECT :value FROM dual` فترفض أوراكل ربطاً يتجاوز 4000 بايت. لولاه لانهار كل طلب مصادَق
  عليه عند أول قراءة للإعدادات. العالج: كاش صغير ومجرد من العربية (تفصيل في `DBdevloping_history.md`).
- **أثر اختباري باقٍ:** سطر `login_failed` في `APP_USER_ACTIVITY` من `AuthTest` لم يُحذف لأن سياسة
  الموافقات منعت الحذف المباشر على قاعدة إنتاجية؛ وهو أول سجل تدقيقي فعلي لمحاولة دخول فاشلة.
- **بوابات الجودة:** `php -l` (11 ملفاً) بلا أخطاء · `vendor/bin/pint --dirty --format agent` passed ·
  `vendor/bin/pest` = 21 اختباراً ناجحاً (83 تحققاً) · 55 مساراً لم يتغير عددها.

---
## [2026-10-18 00:03:42] - المرحلة 3: إدارة المستخدمين ومنح الصلاحيات (الخلفية) — Qoder Agent
- **ملفات جديدة:**
  - `kyApp_API/app/Support/PermissionGrantSync.php` — الطريق الوحيد لكتابة المنح. ثلاث دوال:
    `currentFor(int $userId)` (يُعيد `{ids, codes}` بعد JOIN مع `APP_PERMISSIONS`)، `resolve(array $codes)`
    (يفصل الصالح عن `unknown` و`inactive` بربط كل كود كـ bind)، و`replace()` داخل
    `DB::connection('oracle')->transaction()` تحذف منح المستخدم ثم تُدرج المقبول وتُنهي كاش الحلّ بـ
    `forget()`. وجود الكتابة في مكان واحد يمنع تباعد «الحذف ثم الإدراج» بين controllerين.
  - `kyApp_API/app/Http/Controllers/UserAdminController.php` — `index`/`show`/`store`/`update`/`toggle`/
    `destroy`/`activity`. ترقيم أوراكل 11g عبر `ROW_NUMBER() OVER (ORDER BY …)` مع كسر تسلسل ثابت
    `x.USER_ID ASC`، وعدّاد المنح بـ `LEFT JOIN (SELECT USER_ID, COUNT(*) … GROUP BY USER_ID)`، وقائمة
    بيضاء `SORTABLE` للفرز، و`conditions()` تبني البحث بالعربية واللاتينية معاً، و`shape()` لا تُمرّر أي
    عمود حساس (لا كلمة مرور ولا `DEVICE_TOKEN`). الحراس: 409 تكرار الاسم، 422 التحقق (طول كلمة المرور من
    `SettingsStore`)، 422 حذف/تعطيل الذات، 403 «آخر مدير»، 403 منع التصعيد في المنح، `SEQ_APP_USERS_ID.NEXTVAL`
    للمعرّف، و`terminateSessions()` تدفع `EXPIRES_AT` إلى الماضي عند التعطيل والحذف.
  - `kyApp_API/app/Http/Controllers/PermissionController.php` — `index` (الكتالوج مقسّم 17 وحدة × 93 كوداً
    مع `permission_id` من القاعدة)، `forUser` (`is_admin` + المنح الحالية + الفعّالة)، `syncUser`
    (يتحقق، يمنع التصعيد، يستدعي `replace()`، يُنهي الجلسات إلا بـ `logout_others=false`، ويسجّل النشاط).
  - `kyApp_API/tests/Feature/UsersAdminTest.php` (15 اختباراً) و`kyApp_API/tests/Feature/PermissionSyncTest.php`
    (11 اختباراً) — كلها للقراءة وفروع الرفض: لا تنشئ مستخدماً ولا تعدّل منحاً على قاعدة حيّة.
- **ملفات مُعدَّلة:**
  - `AuthController.php` — طريقة `myPermissions()` جديدة على `GET /api/auth/permissions` (تتجاهل كاش الحلّ
    بـ `forget()` لتعكس جدول المنح لحظياً + `session_expires_at`)، وإضافة `use Laravel\Sanctum\PersonalAccessToken`.
  - `AppServiceProvider.php` — تسجيل `PermissionGrantSync` كـ singleton.
  - `routes/api.php` — مجموعة IBAC ثانية: 11 مساراً، كلٌّ خلف `auth:sanctum` ثم `permission:<code>` مع
    `->where('userId','[0-9]+')`. الإجمالي 66 مساراً (كان 55).
  - `app/Support/SessionPolicy.php` — إضافة `public static toDate(mixed): ?Carbon` وتمرير قراءات
    `expires_at` و`created_at` الثلاث منها.
- **علاج علل مكتشفة أثناء الاختبار:**
  1. `ORA-00904: "PERMISSION_CODE": invalid identifier` — `currentFor()` كان يقرأ العمود من
     `APP_USERS_PERMISSIONS`؛ الصحيح JOIN مع `APP_PERMISSIONS` على `PERMISSION_ID`.
  2. **«Call to a member function isPast()/toDateTimeString() on bool»** — أوراكل تُعيد العمود التاريخي
     الفارغ كـ `false` أو `''` لا كـ `null`، فالسلسلة الاختيارية تنهار. الأخطر كان في `SessionPolicy`:
     لو حدث الاستثناء هناك لالتقطه `AppServiceProvider` وأعاد قرار Sanctum الأصلي بصمت، فتُقبل الجلسات
     القديمة بلا انتهاء ولا تجديد. العالج: `SessionPolicy::toDate()` توحّد الأشكال الأربعة.
  3. صياغة تحقق في الاختبارات: `assertJsonPath('errors.field[0]', …)` تُعيد دائماً `null` لأن
     `data_get()` لا تفهم الأقواس — الصحيح `errors.field.0`. الأخطاء الثلاثة عولجت، والحمولات كانت سليمة.
- **قرارات وانحرافات:** `PermissionGrantSync` طبقة غير مذكورة في §7.1 من الخطة (مبررة بأمن الكتابة)؛
  11 مساراً بدل 9؛ كتابة العربية في `store()` عبر `toOracleSearchChars()` وليس `encodeForOracle()`؛
  نماذج Eloquent ما زالت مؤجلة (لا كود ميت)؛ عدد المسارات في الخطة كان تقديرياً.
- **أثر جانبي نظيف:** أُثناء التشخيص أُنشئ `tests/Feature/TmpProbeTest.php` مؤقتاً لطباعة حمولات 422،
  وحُذف بعد تأكيد أن الاستجابات صحيحة.
- **بوابات الجودة:** `vendor/bin/pint --dirty --format agent` (ملف تحكم + مسار + اختبار) ·
  `vendor/bin/pest` = **47 اختباراً / 199 تحققاً ناجحة** · `php artisan route:list --path=api` = 66 ·
  لا DDL ولا كتابة على القاعدة في هذه المرحلة.

---
## [2026-10-18 02:52:11] - المرحلة 4: الجلسات النشطة وإعدادات الأمان (الخلفية) — Qoder Agent
- **النطاق:** قسمان إداريان جديدان في الخلفية: قائمة الجلسات الحقيقية مع إنهائها فوراً، وشاشة
  إعدادات الأمان التي تقرأ وتكتب `APP_SETTINGS` بقيودها ونوعها.
- **`app/Http/Controllers/SessionAdminController.php` (جديد):**
  - `index()` — قائمة صفحاتها بـ `ROW_NUMBER()` داخل غلافين (لا `OFFSET/FETCH` في أوراكل 11g) مرتّبة
    بـ `NVL(LAST_USED_AT, CREATED_AT)` تنازلياً. الأعمدة في ثابت `SELECT_COLUMNS` مشروحة:
    `DBMS_LOB.SUBSTR(t.NAME, 60, 1)` لأن `NAME` عمود CLOB لا يُربط في سياق `MERGE/SELECT` كبير،
    و`TO_CHAR` لكل تواريخ حتى لا يصل تاريخ فارغ كـ `false` إلى PHP، و`CASE` يشتق الحالة
    (`disabled` لو `IS_ACTIVATED <> 1`، `expired` لو `EXPIRES_AT <= SYSDATE`، وإلا `active`).
  - `terminate(int $tokenId)` و`terminateUser(int $userId)` — 404 أولاً عبر `findSession()` ثم
    `expireTokens()` التي تنفّذ `UPDATE ACCOUNTS.PERSONAL_ACCESS_TOKENS SET EXPIRES_AT = SYSDATE - 1,
    UPDATED_AT = SYSDATE` (بلا بدائل جدول: أوراكل لا تقبل `UPDATE … t` )، وكلاهما يسجّل
    `sessions.terminate`. الأثر: الطلب التالي للمستخدم يرجع 401 فيأخذه `ErrorInterceptor` إلى
    `clearAll()` ثم `forceLogout()` — أي خروج فوري بلا أي كود عميل جديد.
  - `conditions()` تبني المرشّحات (نوع حامل التوكن، `user_id`، الحالة، والبحث بالعربية واللاتينية على
    `USER_NAME_EN/AR` و`DEVICE_NAME`)، و`countMatching()` تربط ما تستخدمه العبارة فقط
    (`array_diff_key` عن `rn_from/rn_to`) تفادياً لـ `ORA-01008`.
  - `shape()` لا تُخرج أبداً قيمة التوكن ولا `ABILITIES`؛ تعطي `minutes_left` والتسمية العربية للحالة
    و`is_current` من `currentTokenId()`.
- **`app/Http/Controllers/SettingController.php` (جديد):**
  - `index()` — `SettingsStore::definitions()` (قراءة مباشرة من القاعدة: الحمل فيه عربية وسقف كاش
    أوراكل 4000 بايت) مع `value` محوَّلاً لنوعه و`raw_value` والحدود و`is_lockable` و`sort_order`.
  - `update()` — تحقّق `present|array|min:1` على `items` و`items.*.key` مطلوب ≤ 60 و`value` nullable؛
    ثم المفتاح المقفل يحتاج `settings.security_manage` وإلا 403 بـ `errors.locked_keys`؛ ثم معاملة
    واحدة على اتصال `oracle` تمرّ كل عنصر عبر `SettingsStore::set()` الذي يفرض النوع والحدود.
    `null` يعني «لم يُرسل» فيُتخطّى، والنص الفارغ مسحٌ مقصود (`maintenance_message`).
    `InvalidArgumentException` ⇒ 422 بـ `errors.setting` و`flush()`؛ والنجاح يكتب وصفاً تدقيقياً
    «اسم الإعداد من «…» إلى «…»» ويرجع المتغيّرات فقط مع `meta.changed`.
- **`app/Support/SettingsStore.php`:** أُضيفت `flush()` علنية. أصلان جوهريان:
  - `normalize()` كانت `filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_UNSET)` — والثابت
    الأخير غير موجود أصلاً، وفي نطاق `App\Support` اشتُغل كمُعرِّف غير معرّف فأعطى 500 عند حفظ أي
    إعداد `bool`. صارت قائمة صريحة (`match` على النوع ثم `in_array` صارم) ترفض الغريب بدل أن تفسّره
    false بصمت.
  - `set()` كانت تربط `UPDATED_BY = :by` — و`BY` كلمة محجوزة في أوراكل ⇒ `ORA-01745` عند الحفظ.
    أعيدت التسمية إلى `:setting_value` / `:updated_by` / `:setting_key` مع تعليق يمنع تكرار الخطأ.
- **`app/Http/Controllers/UserAdminController.php`:** نفس المسح الشامل لأسماء المربَطات كشف أن
  `toggle()` كانت تستخدم `:by` و`:next` ⇒ كانت ستموت عند أول تعطيل مستخدم من الواجهة. صارت
  `:activated` و`:updated_by`.
- **`routes/api.php` (تعديل):** 5 مسارات جديدة داخل مجموعة `auth:sanctum` ثانية:
  `GET /sessions` (`sessions.view`) · `DELETE /sessions/user/{userId}` و`DELETE /sessions/{tokenId}`
  (`sessions.terminate`، مع `{id}` مقيّد بـ `[0-9]+`) · `GET /settings` (`settings.view`) ·
  `PUT /settings` (`settings.update`). المسار `/sessions/user/…` مُعلَن قبل `/sessions/{tokenId}` حتى
  لا يبتلعه المعرّف العام.
- **الاختبارات:** `ActiveSessionsTest` (401 ×3، 403 ×3 بالاسم، شكل المظروف وعدم تسرّب التوكن،
  مقيّد الحالة والمستخدم، سقف 200، العربية السليمة، 404 على معرّف مجهول، عبارة الإنهاء لا تمسّ صفوفاً
  في الاختبار، و`SessionPolicy::validate()`/`toDate()`) — 12 اختباراً / 152 تحقّقاً.
  `SecuritySettingsTest` (401 ×2، 403 للقراءة والكتابة، شكل التعريفات وأنواعها وحدودها، رفض مفتاح
  مجهول مع بقاء عدد الصفوف 10، رفض قيمة خارج الحدود أو بنوع خاطئ، وأن الدفعة المرفوضة لا تُفسد نسخة
  الكاش) — 10 اختبارات / 98 تحقّقاً.
- **سلامة الاختبارات على قاعدة حيّة:** العنصر المرفوض وُضع أولاً في اختبار «الدفعة المرفوضة» حتى
  يسقط داخل `normalize()` قبل أي عبارة `UPDATE` — لا نكتب ثم نتراجع على قاعدة إرث، بل لا نكتب أصلاً.
- **بوابات الجودة:** `vendor/bin/pest` = **69 اختباراً / 449 تحقّقاً ناجحة** ·
  `vendor/bin/pint --dirty --format agent` = passed · `php artisan route:list --path=api` = **71** ·
  تأكيد قراءة: `APP_SETTINGS` بعشرة صفوف و`UPDATED_BY` فارغ و`password_min_length=4` و
  `session_idle_minutes=240` — لم تتغيّر.
- **التالي (لم يبدأ):** المرحلة 5+6 في Flutter — نواة الصلاحيات، `PermissionGate`، وتوحيد الأقسام.

## [2026-10-19 01:47:33] - المرحلة 5+6: نواة الصلاحيات في Flutter وتوحيد أقسام البوابة — Qoder Agent
**الوقت:** 01:47:33 · **النموذج:** Qoder Agent · **النطاق:** العميل فقط (لا مسار API جديداً، لا DDL)

### الملفات الجديدة
- **`lib/core/constants/permission_codes.dart`** — `class Perm { Perm._(); … }`: 93 ثابتاً موزّعة على
  17 وحدة، كل وحدة تبدأ بـ `xxxWildcard = 'module.*'` ثم `view/create/update/delete` وأفعالها الخاصة
  (`customers.edit_limit`، `accounts.structure_manage`، `currencies.prices_view|prices_manage`،
  `users.permissions_manage|activity_view|admin_flag_manage`، `sessions.terminate`،
  `settings.security_manage`). `allPermissionCodes` بترتيب الكتالوج، و`permModuleOrder`/`permModuleLabels`/
  `permActionLabels` للترويسات، و`permModuleOf/permActionOf/permModuleTitle`، و`permWildcardOf(module)` أُضيفت في نفس الجلسة لتوليد `module.*` من موضع واحد بدل تكرار النص في ثلاث نقاط.
- **`lib/core/utils/permission_check.dart`** — ثلاث دوال مجرّدة بمعاملات مسماة
  (`granted/isAdmin/code|codes`) تعيد نفس قرار `PermissionResolver::can` بالترتيب: مدير ⇒ نعم،
  كود فارغ ⇒ لا، `system.*` ⇒ نعم، الكود الحرفي ⇒ نعم، `module.*` ⇒ نعم، وإلا لا.
  `canAnyCode([])=false` (رفض افتراضي) و`canAllCode([])=true` (لا شيء مطلوب).
- **`lib/features/auth/data/models/permission_snapshot_model.dart`** — الحِمل الواحد الذي يمنعه
  تمرير ثلاث قيم متفرقة من ضياع حقل في مسار. `isEmpty` تتجاهل المنح الفارغة، و`_parseNullableString`
  تعتبر `false` (وهكذا يعود عمود `DATE` الفارغ عبر بعض مسارات القراءة في أوراكل) غياباً لا نصّاً.
- **`lib/features/auth/presentation/providers/permissions_notifier.dart`** — `PermissionsState`
  (حالة المزامنة فقط) + `PermissionsNotifier with WidgetsBindingObserver`: أرضية 15 ثانية بين
  الاستدعاءات، `didChangeAppLifecycleState` يقرأ الحالة الجديدة عند `resumed` فقط، `refresh()` يلغي
  الاستدعاء الأقدم بـ `CancelToken` ولا يكتب شيئاً إن كان الملغي هو صاحبه، ويكتب عبر
  `authNotifierProvider.notifier.applyPermissions(snapshot)` وحده.
- **`lib/core/widgets/permission_gate.dart`** — `PermissionGate` يراقب بـ `select` قرار كود واحد فلا
  يعيد الرسم عند كل تحديث حالة؛ والإخفاء هو الافتراضي لأن الزر المعطّل يعلن وجود ما حُجب. امتداد
  `WidgetRef` (`can/canAny/canAll/isSystemAdmin`) يستخدم `read` لأنه يجيب شرطاً واحداً داخل `build`؛
  القرارات التي يجب أن تُعاد رسمتها عند تغيّر المنح توضع داخل `PermissionGate`.
- **`lib/features/employee_portal/domain/portal_sections.dart`** — السجل الوحيد للأقسام التسعة
  (انظر التفاصيل أدناه).

### الملفات المعدّلة
- **`lib/features/auth/data/models/user_model.dart`** — حقلا `isAdmin`/`permissions` + `permissionSet`
  + `userTypeLabel`؛ `fromJson` يقرأ `is_admin` دفاعياً (bool أو 1/0) و`permissions` كقائمة نصوص،
  و`toJson` يعيدهما حتى لا تُفقد المنح عند تخزين نسخة المستخدم.
- **`lib/core/storage/secure_storage_service.dart`** — ثلاثة مفاتيح جديدة
  (`ky_user_permissions`، `ky_is_admin`، `ky_session_expires_at`) مع قارئات/كاتبات دفاعية،
  `clearPermissions()`، و`clearAll()` صارت تحذف الثلاثة: منح مخزّونة بعد الخروج تُبقي واجهة مرسومة
  على جلسة ميتة. `purgeEverything()` كما هي (`deleteAll`).
- **`lib/core/constants/api_constants.dart`** — `permissions = '/auth/permissions'`.
- **`lib/features/auth/data/repositories/auth_repository.dart`** — `fetchPermissions({cancelToken})`
  بأربعة مسارات مميّزة: نجاح ⇒ تثبيت + حمولة، إلغاء ⇒ استعادة من الكاش بلا توسيم، **الخادم ردّ خطأ**
  ⇒ `clearPermissions()` + `PermissionSnapshot.denied`، تعذّر الوصول ⇒ إبقاء الكاش (الخادم ما زال
  صاحب القرار في كل طلب). `_deriveModules()` تعيد بناء `modules` من الأكواد كما يفعل `payloadFor()`.
- **`lib/features/auth/presentation/providers/auth_notifier.dart`** — حالة IBAC في `AuthState`،
  `applyPermissions()`/`clearPermissions()`، ربط `login` و`loginWithBiometric` بـ
  `withPermissions(_snapshotFrom(response.user!))`، و`logout`/`forceLogout` يبنيان حالة نظيفة مع
  الحفاظ على `selectedUserType` وحقول البصمة. **إصلاح انحدار:** `checkAuthStatus()` كانت تعيد بناء
  `AuthState` من الصفر فتمسح نوع المستخدم المختار على شاشة الدخول؛ صار يُمرَّر
  `selectedUserType: state.selectedUserType`. `copyWith` أبقت دلالة `errorMessage` القديمة (تمسح عند
  كل تحديث) لأن تحويلها إلى خدعة الإغلاق كان يكسر كل مواضع الاستدعاء الموجودة.
- **`lib/features/employee_portal/presentation/screens/employee_main_layout.dart`** — حذف استيراد
  الأقسام التسعة وقائمة `_sections`؛ المخزّن `_currentSectionId`؛ في كل بناء:
  `visiblePortalSections(granted: auth.permissions, isAdmin: auth.isAdmin)` ← `_indexOfVisible` (يسقط
  على الفهرس 0 إن لم يعد المعرّف مرئياً) ← `barSections = visible.where(showInBottomBar)` ←
  `IndexedStack(index: currentIndex, children: [for (s in visible) s.builder(context)])`.
  شريط الجوال يختفي تحت وجهتين، و`NoSectionAvailable` تستقبل صفر أقسام.
- **`lib/features/employee_portal/presentation/widgets/collapsible_side_drawer.dart`** — لا `_menuItems`
  داخلية بعد الآن؛ تستقبل `List<PortalSection> sections` وترسم منها.
- **`lib/features/customers/presentation/screens/customers_dashboard_screen.dart:352`** — حبة النص
  الفرعي صارت داخل `Flexible` مع `maxLines: 1` و`TextOverflow.ellipsis` (كانت تتجاوز البطاقة).

### الاختبارات
- **`test/ibac_test.dart` (جديد)** — 5 مجموعات: تطابق الكتالوج (93 كوداً، بلا تكرار، كل كود
  `module.action` بوحدة مُسمّى، كل وحدة لها wildcard، كل فعل مُسمّى)، قواعد الحلّ (رفض بلا منح، تجاوز
  المدير، `system.*`، الكود الحرفي، `module.*` على وحدته فقط، الكود الفارغ، `canAny([])`/`canAll([])`),
  تحليل `PermissionSnapshot` (snake/أحرف كبيرة/`false` كتاريخ فارغ/`denied`/`mergeWith`)، ربط
  `AuthState` (`withPermissions`، `canSeeSection(null)`، مسح الموعد بخدعة الإغلاق فقط)، حقول `UserModel`،
  وسجل الأقسام (معرّفات فريدة، الشريط ≤ 5، كل قسم يفتح بوحدته، بلا منح ⇒ `settings` فقط، المدير ⇒
  التسعة، «جاري العاملين» بثلاثة سجلات، الترتيب من السجل لا من المنح، ولا فهرس عفا عليه الزمن).
- **`test/responsive_layout_test.dart`** — مجموعة `Portal sections follow the grants` (6 اختبارات)
  عبر `_StubAuthNotifier extends AuthNotifier` يعيد `build()` الحالة مباشرة فلا شبكة ولا لمس
  للتخزين الآمن: مدير على المكتب يرى التسعة ولا شريط، مدير على الجوال ⇒ خمس وجهات، منح مقيّدة
  تخفي الأقسام المحجوبة، وقسم واحد في الشريط ⇒ لا شريط (كان انهياراً حقيقياً).
- **مطابقة الخادم–العميل آلياً:** قارن سكربت مؤقت `PermissionCatalog::codes()` بـ `allPermissionCodes`
  ⇒ 93/93، بلا فرق في المحتوى ولا في الترتيب. حُذف الملف المؤقت بعد التحقق.
- **بوابات:** `flutter analyze` = No issues found! · `flutter test` = 44 ناجحة.
- **قراءة Oracle (لا كتابة):** 93 صلاحية منشّطة، منح منشّطة واحدة، `APP_USERS.IS_ADMIN` موجود.
- **التالي:** المرحلة 7 (D3) ثم المرحلة 8 (واجهات الإدارة).

---

## [2026-10-19 02:59:38] المرحلة 7 — ختم مسارات الأعمال بالصلاحيات (الخلفية فقط) · Qoder Agent

**النطاق:** تعديل في `kyApp_API/` دون أي ملف Dart. العميل لم يتغير لأن `AuthInterceptor` يرسل
`Authorization: Bearer` على كل طلب سلفاً، فمساراً مقفلاً يجد جلسته موجودة أصلاً.
**Scope:** backend-only. The Dart side needed no change because `AuthInterceptor` already attaches the
bearer token to every request, so a sealed route always finds a session present.

### الملفات المعدّلة

- **`kyApp_API/routes/api.php`** — إعادة كتابة مقطع الأعمال بالكامل إلى مجموعات
  `Route::middleware('auth:sanctum')` مع `->middleware('permission:<code>')` على كل فعل:
  - `/customers/**`: `view` للقائمة والتفصيل، `create`/`update`/`delete` للكتابة، و
    `statement` منفصل للكشف — لأن من يرى الأسماء لا يرى أرصدتهم بالضرورة. ترتيب المسارات قدّم
    `{custNo}/statement` على `{custNo}` حتى لا تبتلعه النمط العام.
  - `/workers/{employees,cutters,tailors}/**`: ثلاث وحدات صلاحيات مستقلة فعلياً
    (`employees.*`, `cutters.*`, `tailors.*`) لأن صلاحية إدارة خيّاط لا يجب أن تعني صلاحية إدارة
    قصّاب. الأفعال: `view`/`create`/`update`/`delete`/`toggle`/`statement`.
  - `/accounts/**`: التقسيم على وزن الخطر — قراءة الشجرة `accounts.view`، بنود `CHART_ACC`
    بـ `create`/`update`، تعديل الهيكل نفسه (مجموعات جزئية) بـ `accounts.structure_manage`،
    والكشوف بـ `accounts.statement`.
  - `/currencies/**`: دليل العملات `currencies.view/create/update/delete` وأسعار الصرف
    `currencies.prices_view` و`currencies.prices_manage` — إضافة عملة قوةٌ مغايرةٌ لتغيير سعر
    اليوم الذي تُقيَّم به كل الحركات.
  - `/invoices/**` (2) → `invoices.view`.
  - `/selectFromTable` → `permission:system.*` (أعلى منحنى في الكتالوج) بدل أن يبقى عاماً.
- **`kyApp_API/app/Http/Controllers/TableQueryController.php`** — طبقتا حجب جديدتان:
  `DENIED_TABLES` (11 جدولاً) تُطبَّق قبل استعلام الوجود وترجع 403 مع
  `errors.table_name = ['restricted_table']`، و`DENIED_COLUMNS` (`PASSWORD`, `DEVICE_TOKEN`, `TOKEN`,
  `SECRET`, `KEY`) تُنقّح من صفوف أي جدول مسموح، والرد يصرّح `redacted_columns` كي لا يكون الحذف
  صامتاً. الدالة الخاصة `redactSensitiveColumns(iterable): array` تعيد `[الصفوف, الأسماء المحذوفة]`
  لأن أوراكل يردّ الصفوف `stdClass` فيُحوَّل كل صفّ إلى مصفوفة بلا تغيير ترتيب الأعمدة الباقي.
- **`kyApp_API/app/Http/Controllers/InvoiceController.php`** — العلة **C5** من `AGENTS.md` أُغلقت:
  غلاف موحّد بدل `response()->json($collection)` العاري، و`ArabicEncoding::cleanData()` على البيانات
  (كان اسم العميل يصل مكسور الترميز)، وبحث يدوي (`BILL_NO` رقمياً أو `CUST_NAME` بكلتا الصيغتين عبر
  `toOracleSearchChars`)، وتصفح `page`/`limit` بنفس `meta` الذي يستخدمه `CustomerController`
  (`{total, page, limit, pages}`)، و`show` صار 404 مغلّفاً بدل `null` مجرّد، وأعمدة الاستعلام
  أصبحت ثابت `COLUMNS` مشتركاً بين المسارين بعد أن كان تكرارها حرفياً أول سبب انحرافهما، و`$type`
  hints علنية (`Request`, `int $billNo`, `: JsonResponse`).

### القرارات والعلل

- **لا منح ترحيبية (كانت البند 6 من الخطة):** تحقّق قراءة-only أظهر أن `APP_USERS` يحتوي مستخدماً
  واحداً (`arslan`, `IS_ADMIN=1`, `IS_ACTIVATED=1`)، والمدير يتجاوز جدول المنح في `PermissionResolver`
  قبل أي فحص — فخطر طرد مستخدمين حقيقيين الذي من أجله وُضع ذلك البند غير موجود فعلياً، وتُركت القاعدة
  بلا كتابة. البند يبقى مطلوباً عند أول مستخدم غير مدير يُنشأ في المرحلة 8.
- **مسارات الجلسة الذاتية بقيت بلا صلاحية عمداً** (`logout`, `me`, `user`, `auth/permissions`,
  `biometric/register`, `biometric/revoke`): اشتراط منحٍ لقراءة المرء منحَه يجعل المستخدم بلا صلاحيات
  عاجزاً عن معرفة أنه كذلك، واشتراطها للبصمة يمنع تسجيل الدخول أصلاً.
- **`/api/hello` بقي عاماً** لأنه فحص الاتصال الذي تشغّله شاشة إعدادات الواجهة قبل وجود أي جلسة.

### الاختبارات والبوابات

- **`tests/Feature/BusinessRoutesSealedTest.php`** (جديد، 6 اختبارات / 68 تحقّقاً): عقد السطح العام
  (المسارات العامة = الثلاثة بالضبط، مقارنة مرتّبة لا مجموعة)، وكل مسار محمي يحمل حارس صلاحيات بعد
  استثناء الستة الذاتية، و19 فعلاً غير مصادق ⇒ 401، و14 فعلاً لمستخدم بلا منح ⇒ 403 مع تسمية الكود
  الصحيح لكل وحدة، ومرور المدير على القراءة المختومة، وغلاف الفواتير الجديد (بنية + ترميم عربية
  مشروط بوجود صفوف لأن جدول الإرث قد يكون فارغاً).
- **`tests/Feature/TableQueryTest.php`** — أُعيدت كتابته ليعكس القفل: اختبار 401 بلا جلسة أولاً،
  وبقية الحالات خلف `Sanctum::actingAs` على المدير الحيّ، مع اختباري الرفض الجديدين (جدول ممنوع
  ⇒ 403 حتى للمدير، ولا عمود اعتماد يخرج من جدول مسموح).
- **بوابات:** `vendor/bin/pint --dirty --format agent` = fixed (ملفان) · `vendor/bin/pest` =
  **78 اختباراً / 533 تحقّقاً** ناجحة كلها · `php artisan route:list --path=api` = **71** (لا زيادة
  ولا نقص في العدد — التغيير كان في الطبقات لا في المسارات) · `flutter analyze` = No issues found! ·
  `flutter test` = 44 ناجحة (لم تلمسها هذه المرحلة، جرت للتأكيد).

---

## [2026-10-19 08:59:30] المرحلة 8 — واجهة الإدارة الكاملة (Flutter) · Qoder Agent

### ما بُني

`lib/features/admin/` (36 ملفاً) فوق المسارات الخلفية الـ 17 التي خُططت في المراحل 2–4، بهيكل
`data/{models,repositories}` + `presentation/{providers,screens,widgets}` المطابق لبقية الميزات:

- **الموديلات (7 + 2 مشتركين):** `AppUserModel` · `AppPermissionModel` (+`AppPermissionModule`) ·
  `AppSessionModel` · `AppSecuritySettingModel` · `UserActivityModel` · `AdminResult` ·
  `PagedResult`. كلها تقرأ مفتاحين (`USER_NAME_AR` و`user_name_ar`) لأن الخادم يمرّر صفوف أوراكل
  خاماً في بعض المسارات، وكل حقل عربي يمرّ بـ `JsonValues.asArabic()` → `ArabicEncodingUtils.fix()`
  قبل أن يُعرض، والأرقام تُحلّ بمحللات دفاعية (`asInt`/`asDouble`/`asFlag`) لا بـ `int.parse`.
- **المستودعات (4):** `AdminUserRepository` (`/users` + `/users/{id}` + `/toggle` + `/activity`) ·
  `PermissionRepository` (`/permissions`، `/users/{id}/permissions` GET/PUT) ·
  `SessionRepository` (`/sessions`، `/sessions/{id}`، `/sessions/user/{id}`) ·
  `SecuritySettingRepository` (`/settings` GET/PUT). كلٌّ يستقبل `CancelToken` ويعيد `AdminResult`
  أو `PagedResult` ولا يلمس `Dio` أي طبقة أخرى.
- **المزوّدون (6):** `adminUsersProvider` (التأخير 300ms في الشاشة لا هنا، و`CancelToken` واحد لكل
  طلب جديد يلغي السابق فلا تكتب نتيجة قديمة فوق الأحدث) · `assignPermissionsProvider` ·
  `activeSessionsProvider` · `securitySettingsProvider` ·
  `userActivityProvider` · `permissionsCatalogProvider` كـ `FutureProvider` يُعيد رمي الفشل عمداً
  كي تظهر «إعادة محاولة» بدل مجموعة فارغة توحي أن النظام بلا صلاحيات.
- **الشاشات (10):** `ManagementDashboardScreen` · `AdminUsersScreen` · `UserFormScreen` (+
  `AddUserScreen`/`EditUserScreen` غلافان رفيعان) · `AssignPermissionsScreen` ·
  `UserActivityScreen` · `ActiveSessionsScreen` · `SecuritySettingsScreen` ·
  `PermissionsCatalogScreen` · `UserPickerScreen`.
- **الودجات (9):** `UserCard` (خمسة أفعال، كل فعل بصلاحية) · `UserFormWidget` ·
  `PermissionsPickerWidget` · `PermissionModuleGroup` · `SessionCard` · `ActivityTile` ·
  `SettingTile` · `admin_filter_sheet` (`showAdminFilterSheet`) · `user_picker_screen` (منتقي
  مشترك يسكن `widgets/` لأنه يُستدعى من ثلاث شاشات لا من الموجه).

### قرارات تصميم نُفِّذت كما جُمِّدت

1. **D8 — المنتقي داخل النموذج:** الإنشاء والتعديل يمرّان بنموذج واحد، والمنح تُرسل في نفس طلب
   الحفظ فيطبّقها الخادم ذرّياً؛ لا شاشة منح منفصلة إلّا كمدخل سريع من البطاقة.
2. **D1 — تجاوز المدير خارج جدول المنح:** كل بوابة كتابة تُظهر «مدير النظام» بدل صناديق التحديد
   عندما يكون الهدف مديراً، فلا يُعرض على المستخدم ما لا يستطيع تعديله.
3. **منع التصعيد:** الصف الذي لا يملكه الممنِح يُظلَّل ولا يقبل اللمس (`canGrant`)، والخادم يبقى
   الحاجز الحقيقي بـ `not_held` — التحذير قبل الإرسال لا المفاجأة بعده.
4. **«تحديد كل القسم» لا يرسل `module.*`:** الوايلدكارد أوسع من مجموع أفعال القسم (يغطي ما يُضاف
   لاحقاً) ومدير بلا `system.*` لا يستطيع إرساله أصلاً، فيُرسل الأفعال الحرفية المرئية.
5. **مؤقّت واحد للشاشة:** `ActiveSessionsScreen` يملك `Timer.periodic` واحداً ويمرّر `now` لكل
   بطاقة؛ عشرين بطاقة بعشرين مؤقّت = عشرين مصدراً لإعادة الرسم وأربعين مصدر إلغاء بلا مقابل.
6. **الحجب بالبوابة لا بالشرط:** `PermissionGate` يقرأ من `authNotifierProvider.select(...)` كوداً
   واحداً، فلا إعادة بناء للشاشة كلها عند أي تغيّر في المُنح.

### العلل التي ظهرت من الاختبار لا من القراءة

هذه الجولة أضافت اختبارات ثم أصلحت ما كشفته — لا العكس:

- **`LateError: Field '_changePassword' has not been initialized`** في `UserFormWidget`: الحقل كان
  `late bool` بلا إسناد في `initState`، فكل نموذج تعديل كان ينهار عند أول بناء؛ نموذج الإنشاء كان
  ينجو بالصدفة لأن `widget.isCreate || _changePassword` يقصر التقييم. صار `bool _changePassword =
  false;` — والتعديل لا يرسل كلمة مرور إلا إذا صرّح المستخدم بتغييرها.
- **زرّا «تحديد كل القسم» و«الأساسيات» كانا يظهران أثناء البحث** فيعرض «كل القسم» محقَّقاً بينما
  الشاشة تعرض خمس نتائج فقط، ويظهران أيضاً عندما يكون الهدف مديراً مقفلاً. أُضيف شرط
  `!isSearchOn && !disabled` وحُذف حقل `_QuickRow.disabled` الذي لم يعد له معنى.
- **RenderFlex على الجوال (جملة مواطن):** `Wrap` يقيس أبناءه بعرض غير محدود، فأي `Row` داخله يتجاوز
  الحافة عند نصّ طويل — الوقت المتبقي في `SessionCard` ورقائق «أساسيات القسم» والسطر السريع في
  المنتقي. المعالج الصحيح: `LayoutBuilder` حول `Wrap` يمرّر `maxWidth` إلى `ConstrainedBox` ثم
  `Flexible` حول النص بـ `maxLines: 1` و`overflow: TextOverflow.ellipsis` — لا توسيع الخط ولا
  تصغير الاختبار.
- **رأس `SessionCard`:** شارة «هذه الجلسة» والوقت «ساعتان و20 دقيقة» كانا يأخذان عرضهما الطبيعي
  فيسحقان عمود الاسم إلى 69px ثم يفيضان. صار التوزيع `Expanded(flex: 3)` للهوية و
  `Expanded(flex: 2)` للحالة، مع `Flexible` حول الشارة و`maxLines: 1 + ellipsis` داخل `_Badge` —
  لا عنصر واحد يتجاوز ما أُعطي له.
- **أزرار إنهاء الجلسة** انتقلت من `Row` إلى `Wrap(spacing: 8, runSpacing: 6)` لأن زرين أعرض من
  بطاقة جوال.
- **تسريب لاتينية في تعليق عربي:** «لا كتابة على حالة_after_dispose» في `admin_users_provider.dart`
  صُحِّح إلى «… بعد التفكيك» — قاعدة هذا الملف أن التعليق العربي لا يخلط المحارف.
- **`_List` في `ActiveSessionsScreen`** حُوّل من `ConsumerWidget` إلى `ConsumerStatefulWidget`:
  حوارات التأكيد ورسائل النتيجة تحتاج `context` و`mounted` بعد انتظار المستخدم، وحوار يُجاب بعد
  إلغاء الشاشة كان سيتحدّث على سياق ميت.

### الاختبارات الأمامية (§8.5)

- **`test/ibac_test.dart`** — 20 اختباراً في خمس مجموعات: قواعد الحلّ as-is عن
  `PermissionResolver::can` (مدير ⇒ صحيح، `system.*` ⇒ كل شيء، فعل حرفي، وايلدكارد قسم، رفض
  الافتراض)؛ سلامة مطابقة الأكواد (لا تكرار، كل قسم في `permModuleOrder` له عنوان ووايلدكارد،
  كل فعل حرفي معلن في قسمه)؛ قراءة ما ترسله أوراكل فعلاً (مفاتيح عليا + أرقام نصية `'7'/'1'/'0'` +
  `'ÎÇáÏ'` ⇒ `'خالد'`)؛ سجل الأقسام (معرّفات فريدة، عناوين فريدة، ≤5 في شريط الجوال، كل `viewCodes`
  كوداً حقيقياً)؛ وسلوك المنتقي (التحديد الشامل يرسل أفعالاً حرفية ولا يرسل `customers.*` أبداً،
  الأساسيات تنتقي `isCore`، الاختفاء أثناء البحث والقفلة، ومنح ما لا يملكه الممنِح مستحيل).
- **`test/responsive_layout_test.dart`** — مجموعة «Admin screens render at both breakpoints»:
  9 شاشات × حجمين (360×640 و1280×800) = 18 حالة، بمزيفات مستودعات تمتد من الأصلية وتُبطل كل
  أسلوب عبر `overrideWith` فلا تلمس أي شاشة `Dio` ولا `flutter_secure_storage`، وبتثبيت
  `authNotifierProvider` على جلسة مدير (`isAdmin: true`) حتى تُرسم أزرار الكتابة والحذف ولا يُختبر
  فرع الرفض وحده. البوابة `expect(tester.takeException(), isNull)` هي ما كشف العلل أعلاه.
  شاشة الجلسات تُفكَّك بـ `pumpWidget(const SizedBox())` عمداً وإلا بقي مؤقّت الدقيقة معلّقاً.

### البوابات

`flutter analyze` = **No issues found!** · `flutter test` = **51 ناجحة / صفر فشل** (20 IBAC + 27
responsive/portal + 4 نماذج سابقة) · الخلفية لم تُمَسّ في هذه المرحلة فلم تُعد Pint/Pest (آخر قياس
78 اختباراً / 533 تحقّقاً على 71 مساراً).

### ما لم يُنفَّذ لأنه يحتاج إذناً

القبول اليدوي لـ §10 (مستخدم ثانٍ غير مدير، منح ترحيبية، دورة حياة كاملة، إنهاء جلسة على جهاز
حقيقي، حفظ إعدادات) كلّه كتابة في `ACCOUNTS` الحيّ — متوقف على موافقة صريحة من المستخدم.

---

## [2026-10-20 00:45:10] المرحلة 9 — التوثيق والإغلاق النهائي (مسار كتابة العربية + دليلَي الوكلاء) · Qoder Agent

### ما نُفِّذ ولمسة الكود

- **`kyApp_API/app/Support/ArabicEncoding.php`** — حُذف `encodeForOracle()` بالكامل. كان ينتج سلسلة
  بايتات CP1256 خاماً ويربطها كما هي؛ ولأن اتصال PHP بـ `AL32UTF8` فإن أوراكل تُعيد تفسير تلك البايتات
  كمقاطع UTF-8 غير صالحة وتضع مكانها `0xBF`. القياس المباشر على `خالد سالم` أعطى `bf,bf,bf` — ثلاث
  محرفات بدل تسعة، أي إتلاف للقيمة لا تشويه عرضي. `toOracleSearchChars()` صار المسؤول عن الكتابة
  والبحث معاً: يحوّل كل بايت CP1256 إلى المحرف اللاتيني ذي الكود نفسه (`0xD6` ⇒ `U+00D6`) فيستقر
  البايت في القاعدة كما تفعل صفوف نظام الشركة القديمة، ثم يصلحه `fixMojibake()` عند القراءة.
- **`CustomerController` (6 مواضع) · `AccountController` (4) · `CurrencyController` (6)** —
  استبدال `encodeForOracle(` ← `toOracleSearchChars(` في مسارات الإدراج والتحديث والبحث، ثم
  `vendor/bin/pint --dirty` على الملفات الثلاثة (أعاد تنسيقها كلياً لأن بعضها لم يمرّ على Pint منذ
  إنشائها؛ الفرق الدلالي محصور في الستة عشر استبدالاً).
- **`SettingsStore`** — قيم `string` تمرّ الآن عبر `toOracleSearchChars()`، و`limitToColumn()` يقارن
  بـ `mb_strlen` لا `strlen`: الحدّ سعة عمود بالمحرف، ورسالة الرفض صارت «النص أطول من 500 محرف».
  القراءة السابقة كانت ترفض نصاً عربياً صحيحاً لأن بايتاته أكثر من محرفاته.
- **`tests/Unit/ArabicWritePathTest.php`** (جديد) — 14 اختباراً / 108 تحقّقاً بلا اتصال أوراكل:
  على مجموعة `['خالد','عملاء الكبودي للخياطة','كشف حساب','عبد الله سالم']` يتحقق أن الكودبوينت التي
  تُربط تساوي قائمة البايتات `unpack('C*', iconv('UTF-8','Windows-1256',$t))` حرفياً، وأن
  `fixMojibake(toOracleSearchChars($t)) === $t`، وأن ASCII والفارغ وnull تعود كما هي، وأن
  `method_exists(ArabicEncoding::class,'encodeForOracle')` **false** — أي أن الدالة الآمنة لا يمكن
  أن تعود بصمت.

### دليلَا الوكلاء (مرحلة 9 بند 1)

- **`AGENTS.md` (الجذر)** — تصحيح الحالة (IBAC مطبَّق، الإدارة تعمل، لا RBAC ولا مخطط لها)، جرد
  المسارات إلى 71 (3 عامّة / 6 ملك للجلسة / 62 محرساة بطبقتين)، جداول IBAC الخمسة وسكربتات
  `database/oracle/` الأربعة، سبب بقاء `sanctum.expiration => null` وآلية `SessionPolicy`، مفاتيح
  التخزين الآمن التسعة، نواة الصلاحيات في العميل (`Perm`، `permission_check`، `PermissionGate`،
  `permissionsNotifierProvider`، `portal_sections`)، جدولَي الاختبارات (Flutter 4 ملفات/51، Laravel
  11 ملفاً/92)، وبنود جديدة: **S7** سقف الكاش 3000 بايت، **C12** `USER_ID` ≠ `USER_NO`.
- **`kyApp_API/AGENTS.md`** — البنية الحقيقية (11 متحكماً بأدواره، `Http/Middleware/EnsurePermission`،
  7 أصناف `Support/`، خمسة singleton في `AppServiceProvider` + خطّاف Sanctum)، الميزان الأمني
  بطبقتيه مع مثال من `routes/api.php` و`selectFromTable` المغلق، §4 (الظرف، إغلاق استثناء
  `InvoiceController`، شكلَا `meta`، حدود `UserAdminController`)، §5.1 عقد الكتابة، §5.2 مُشغِّلات IBAC
  وشرط التسلسل **غير الموصوف** داخل PL/SQL (وجود VIEW باسم `ACCOUNTS` داخل schema `ACCOUNTS`)، سقف
  الكاش `ORA-01461`، وعودة Oracle لقيمة DATE الفارغة كـ `false`، §6 سياسة الجلسات والـ IBAC
  (سلّم الحلّ، منع التصعيد، إنهاء الجلسات عند تغيّر المنح، حارس آخر مدير)، §8 الجداول + سكربتات
  `database/oracle/`، §9 أوامر البذر مع تحذير الكتابة، §10 سياسة الاختبارات المقروءة فقط، §12
  الحالات المغلقة والجديدة (S1/S2/S5 وC5 وC10/C11)، §14 واقع العمل غير المرتقب، §15 مرجع سريع مطابق.

### البوابات بعد هذه المرحلة

`flutter analyze` = **No issues found!** · `flutter test` = **51 ناجحة / صفر فشل** ·
`vendor/bin/pint --dirty` = **passed** · `php artisan test` = **92 ناجحة / 653 تحقّقاً** (كانت
641 قبل إضافة `ArabicWritePathTest`).

### ما لم يُنفَّذ لأنه يحتاج إذناً

القبول اليدوي لـ §10 على جهازين، وحواجز إطلاق APK (إذن `INTERNET` في `AndroidManifest.xml` الرئيسي،
`applicationId` حقيقي، توقيع فعلي)، وأي commit — الترتيب الواجب: داخل `kyApp_API/` أولاً ثم bump
المؤشر في الأب. لا شيء من هذا يُعدّ نقصاً في التنفيذ؛ كلها قرارات بيد المستخدم.

---

## [2026-10-20 01:13:30] تتبُعة البوابة — عِلَتا `flutter analyze` قديمتان أُغلقتا · Qoder Agent

عند إعادة قياس البوابات في نهاية المرحلة 9 ظهر `flutter analyze` بـ **مسألتين** بدل «No issues
found!» — أي أن النظافة السابقة لم تعد سارية، وكان يجب ألا تُنقَل كمسلَّمة:

- **`lib/features/auth/presentation/screens/login_screen.dart:1`** — `unused_import`
  لـ `package:flutter/gestures.dart`: استيراد بقي من تجربة قديمة على نص links ولم يعد يُستخدم بعد
  إعادة بناء البطاقة. حُذف السطر وحده.
- **`lib/features/auth/presentation/screens/splash_screen.dart:43`** — `avoid_unnecessary_containers`:
  `Container` يلفّ `Image.asset` بلا أي خاصية فعّالة (كان `padding`/`decoration`/`boxShadow` مكتوبة
  كمعلَّقات لا ككود، فالغلاف كان هيكلًا ميتاً يكلّف طبقة build إضافية). أُزيل الغلاف وصار
  `Image.asset('assets/logo3.jpg', width: 370, height: 300)` عنصراً مباشراً في الـ `Column` بنفس
  الأبعاد تماماً — لا تغيّر بصري — مع تعليق عربي/إنجليزي واحد يمنع إعادة الغلاف بدافع التنسيق.

**إعادة القياس:** `flutter analyze` = **No issues found!** · `flutter test` = **51 ناجحة / صفر فشل**.
الخلفية لم تُمَسّ في هذه التتبّعة فلم تُعَد Pint/Pest (وهما أخضر كما هو موثّق أعلاه: 92 / 653).

**ما تغيّر في طريقة العمل:** البوابات أصبحت تُقاس لا تُستَنتج — أي وثيقة تقول «الأربع خضراء» يجب أن
تكون قد رأته في هذه الجولة، لأن عِلَتَين ساكتتين ظلتا هنا منذ ما قبل مرحلة IBAC دون أن يكشفهما إلا
إعادة تشغيل فعلي.

---

## [2026-10-20 04:13:12] إصلاح عِلل الإنتاج الثلاث: إنشاء المستخدم 500 · الرموز في الجلسات وإعدادات الأمان · Qoder Agent

ثلاث بلاغات من المستخدم في أمر واحد (سجلات Dio مرفقة): فشل إنشاء مستخدم بـ 500، ورموز في شاشة
الجلسات النشطة، ورموز في شاشة إعدادات الأمان. الأول عقد مكسور داخل المتحكم، والثاني والثالث علّة
ترميز واحدة متكررة في موضعين.

### 1) فشل إنشاء المستخدم — `prepareGrants` يرجع `null` في خانة الخطأ عند النجاح

الخطأ `TypeError: store(): Return value must be of type JsonResponse, null returned` (السطر 246) لم
يك له علاقة بأوراكل ولا بالتحقق — بل بعقد داخلي مكسور:

- `prepareGrants(?User $actor, ?array $codes)` كانت تعيد `[null, null]` في مسار النجاح (فروع
  الخطأ فقط كانت تعيد كائن استجابة).
- `store()` و`update()` يفككان `[$grantIds, $invalid]` ويحرسان `if ($invalid !== []) { return $invalid; }`
  — و`null !== []` **صحيحة**، فمسار نجاح المنح أعاد خانة الخطأ `null`، مخالفاً نوع الإرجاع
  `JsonResponse` ومنفجراً قبل أي `INSERT`. الحمولة المبلَّغة (`permissions: ["dashboard.view"]`)
  كانت تصيب هذا المسار بالضبط.

**الإصلاح:** خانة «لا خطأ» = `[]` لا `null` (`return [null, []]`)، مع إبقاء `null` في خانة
المُعرِّفات لحالة «لم تُرسل صلاحيات» في `update()` (الفرق بين «لم تُرسل» و«أُرسلت فارغة»). واختبر
`UsersAdminTest` بالانعكاس (ReflectionMethod): نجاح ⇒ `[]` + مُعرِّفات غير فارغة؛ أكواد مجهولة ⇒
`JsonResponse` بـ 422. السبب في اختيار الانعكاس: الاختبارات مقصودة قراءةً فقط ضد المخطط الحي،
وهذا العقد ينفَّذ في الذاكرة دون أي كتابة.

### 2) رموز الجلسات النشطة — إصلاح مزدوج

`GET /api/sessions` أعاد `user_name_ar":"ط§ط±ط³ظ„ط§ظ†"` بينما `/users` كان سليماً — لأن
`SessionAdminController@index` كان يُصلح كل حقل داخل `shape()` ثم يمرر الصفحة كلها على
`ArabicEncoding::cleanData()` ثانية. إصلاحٌ ثانٍ يمرر *بايتات* UTF-8 السليمة عبر جدول CP1256:
`ارسلان` → `ط§ط±ط³ظ„ط§ظ†`، `موظف` → `ظ…ظˆط¸ظپ`، `نشطة` → `ظ†ط´ط·ط©`.

**الإصلاح:** `data` = ناتج `shape()` مباشرة (إصلاح واحد لكل قيمة). و`ActiveSessionsTest` صار يثبت
مساواة التسميات للقيم المُصلَحة من الصف الخام ولعضوية البدائل النصية العربية (`موظف/عميل`،
`نشطة/منتهية المهلة/حساب معطّل`).

### 3) رموز إعدادات الأمان — نفس العِلّة في `SettingController`

`index()` كان يُعيد تغليف مخرجات `SettingsStore::definitions()` (التسميات مُصلَحة مرة في `fetch()`)
بـ `cleanData()` مرة أخرى، و`update()` كذلك عبر `after()`. **الإصلاح:** إرجاع المخرجات كما هي؛
`SettingsStore` نقطة الإصلاح الوحيدة لهذه الحمولة (قرار معلل: الحمولة عربية وقيمها تتجاوز سقف
كاش أوراكل 3000 بايت أصلاً). حُذف استيراد `ArabicEncoding` غير المستخدم. و`SecuritySettingsTest`
صار يثبت مساواة كل مفتاح لمصدر الإصلاح الوحيد مع مقارنة بصف خام من القاعدة.

### 4) السبب الجذري — `fixMojibake()` لم تكن آمنة من التكرار

حتى مع إصلاح الموضعين، بقي `cleanData()` قنبلة موقوتة: أي متحكم جديد يصلح حقوله حقلياً ثم يمرر
الصفحة على `cleanData()` يعيد العِلّة. أُضيفت حصانة في `fixMojibake()` تسبق كل الخطوات: إذا كان
النص UTF-8 صالحاً **و** يحوي عربية (U+0600–U+06FF) **و** لا يحوي أي محرف في 0x80–0xFF فهو سليم
فعلاً ويُرجع كما هو. هذا معيار آمن لأن التشويه الحقيقي يصل دائماً محملاً بمحرف لاتيني في ذلك
المدى (عبر تحويل العميل AL32UTF8)، أما بايتات CP1256 الخام فليست UTF-8 صالحاً عملياً فلا تختبئ
خلف الحاصرة. عقد القراءة الجديد `tests/Unit/ArabicReadPathTest.php` (يشتغل **بلا** اتصال أوراكل)
يثبت: إصلاح شكل Mojibake اللاتيني، الثبات عند التكرار (مرة ومرتين وعبر `cleanData`)، واستمرار
إصلاح الصفوف المختلطة (عربي سليم + جزء مشوّه).

### تحقّق حي (قراءة فقط) + البوابات

- عبر `tinker` ضد الصفوف الحيّة: `USER_NAME_AR` للمستخدم 1 ⇒ «ارسلان» ثابتة عند الإصلاح المكرر؛
  `NAME_AR` لـ `session_idle_minutes` ⇒ «مهلة خمول الجلسة (بالدقائق)» بنفس الثبات.
- عبارات SQL حرفية في `db_commends.md` (بما فيها استعلام أعمدة `APP_USERS` الإلزامية:
  `USER_ID` و`IS_ADMIN` فقط — وكلاهما مربوط في إدراج `store()`).
- `php artisan test` = **114 ناجحة / 759 تحقّقاً** · `vendor/bin/pint --dirty` = passed.

**لم يُنفَّذ (بحاجة إذن):** إثبات إنشاء المستخدم بتجربة كتابة مُرجَّعة داخل معاملة — صدّها التنفيذ
الآمن لأنها كتابة في القاعدة الحيّة، فالمستخدم هو من يقرر إما التجربة المُرجَّعة أو إنشاء مستخدم
حقيقي من واجهة التطبيق.

---

## 2026-10-20 — إدارة إعدادات API الآمنة + التهيئة الديناميكية (المنفّذ: Qoder)

### خلفية Laravel (`ky_app_API`)
- **`app/Support/PermissionCatalog.php`**: وحدة `app_config` (`view`/`update` + `api_manage`) قبل
  `system`؛ الكتالوج 93←97 كوداً، 17←18 وحدة.
- **`app/Support/AppConfig.php`** (جديد): ثوابت المفاتيح، `DEFAULTS` مطابقة لألوان `AppColors`
  و`#A27E4E`/`#0D9488`/`#F8FAFC`/`#0F172A`/`#475569`، `ALLOWED_FONTS`، `WRITABLE_KEYS`/`COLOR_KEYS`،
  `publicPayload()` يستثني كلمة السر، `keys()` لعزل المفاتيح، و`isValidColor/isValidFont`.
- **`app/Support/SettingsStore.php`**: إضافة `raw()` (قراءة تجزئة bcrypt كما هي بلا `fixMojibake`).
- **`app/Http/Controllers/AppConfigController.php`** (جديد): `publicConfig`، `update` (يرفض مفتاح
  كلمة السر، تحقّق inline، معاملة oracle، `flush`، سجل نشاط)، `verifyApiPassword` (يعيد 200 دائماً،
  يسجّل الفاشل)، `updateApiPassword` (`Hash::make`، `ignoreLock`، لا يعيد التجزئة).
- **`routes/api.php`**: `GET /app-config` + `POST /app-config/verify-api-password` (عام، `throttle:5,1`)؛
  `PUT /app-config` (`permission:app_config.update`) + `PUT /app-config/api-password`
  (`permission:app_config.api_manage`).
- **`app/Http/Controllers/SettingController.php`**: تصفية مفاتيح `AppConfig::keys()` في `index` ورفضها
  في `update` (عزل تام عن شاشة إعدادات الأمان).
- **الاختبارات**: جديد `tests/Feature/AppConfigTest.php` (9)؛ تحديث عدّادات
  `IbacCoreTest`(97/22)، `PermissionSyncTest`(97/18)، `SecuritySettingsTest` (تصفية + عدّ ديناميكي)،
  و`BusinessRoutesSealedTest` (السماح بالنقطتين العامتين الجديدتين). `php artisan test` أخضر · `pint` نظيف.

### عميل Flutter (`lib/`)
- **اعتماديات**: `image_picker ^1.1.2` + `path_provider ^2.1.5` في `pubspec.yaml`.
- **السمة**: `core/theme/app_palette.dart` (جديد) حامل ألوان زمني؛ `app_colors.dart` حوّل الحقول
  الخمسة (+`primaryDark`) إلى `getters`؛ `app_theme.dart` أضاف `build()` يبني من `AppPalette`
  و`GoogleFonts.getFont`، وبقي `lightTheme` مفوّضاً. **تفكيك `const`**: أُزيلت `const` من 43 ملفاً
  تضمّنت الألوان الديناميكية (إصلاح ميكانيكي، البوابة: `flutter analyze` = لا مشاكل).
- **ميزة `app_config/`** (جذرية feature-first): نموذج/مستودع/مُبلِغ — تحميل من الكاش ثم مزامنة الخادم،
  حفظ (PUT) يدفعل الألوان للوحة، اختيار/حفظ شعار محلي، تحقّق كلمة سر (خادم ثم احتياط SHA-256 محلي)،
  وتغيير كلمة سر API.
- **التخزين الآمن**: مفاتيح `ky_app_config`/`ky_app_logo_path`/`ky_api_pw_hash`+dوالها؛ تبقى بعد
  `clearAll` وتستثنى من تسجيل الخروج، وتُمسح في `purgeEverything`.
- **`core/widgets/app_logo.dart`** (جديد): ودجت موحّد يراقب حالة التهيئة (ملف محلي أو `assets/logo3.jpg`)؛
  استبدل `Image.asset` في `login_screen.dart` و`splash_screen.dart`، وأضفى اسم الشركة من التهيئة.
- **`core/widgets/restart_widget.dart`** (جديد) + **`main.dart`**: إقلاع async يهيّئ اللوحة من الكاش،
  `KyApp` صار `ConsumerWidget` (سمة/عنوان من التهيئة)، وإعادة تشغيل كاملة بعد تغيير الألوان/الخط.
- **بوابة الدخول**: `ApiPasswordDialog` يطلب كلمة السر قبل `/api-settings`. **بوابة البوابة**:
  بطاقة API خلف `app_config.api_manage` وبطاقة «تهيئة التطبيق» خلف `app_config.update` تفتح
  `AppConfigScreen` (شركة/تطبيق/خمس ألوان/خط/شعار + تغيير كلمة سر API).
- **مرآة الصلاحيات**: `core/constants/permission_codes.dart` أضافت أكواد `app_config.*` + تسميات عربية.
- **اختبار العميل**: `test/app_config_model_test.dart`. `flutter test` = **60 ناجحة** · `flutter analyze` نظيف.

### قرار تقني مهم (فخّ مُسجّل)
في هذا الإصدار `Color.r/g/b` قيم `double` بين 0.0–1.0؛ تحويلها إلى hex بـ `.toInt()` كان يبتّرها إلى
0 (كل الألوان تصير `#000000`). الصواب: `(v*255).round()`. طُبِّق في `_colorToHex`/`_hex`.

---

## 2026-10-21 — Flutter: تقارير الحسابات المالية (Account Financial Reports)

**نموذج AI:** Qoder Agent · **الخطة:** `Account_Financial_Reports_1686e067.md` · **المهام t4–t10 (Flutter)**.

### التبعية
- `pubspec.yaml`: أُضيف `printing: ^5.13.1` + `pdf: ^3.11.1` — حُلّت إلى 5.14.3 / 3.11.3. `flutter pub get` نظيف.

### النماذج (`lib/features/accounts/data/models/`)
- `chart_account_model.dart` — **توسيع**: `AccountTransactionModel` أصبح يحمل `entryNo` (int?)، `subEntryNo` (String?)، `entryTypeName` (String?)، `date/description/debit/credit/balance` مع قراءات dual-case تغطّي `ENTRY_NO`/`entry_no`, `ENTRY_DATE`/`DATE`/`entry_date`, `DETAILS`/`DESCRIPTION`/`details`, `BALANCE_S`/`BALANCE`/`balance_s`. كل حقل نصّي عربي يمرّ عبر `ArabicEncodingUtils.fix`. `AccountStatementData` أضاف `openingBalance`, `finalBalance`, `totalDebit`, `totalCredit`, `currency` (فارغ→null), `fromDate`, `toDate`, `defaulted` من كتلة `summary`.
- `account_group_statement_model.dart` — **جديد**: `TrialBalanceRow` (accNo/accName/curCode/localDebit/localCredit/foreignDebit/foreignCredit/balance/currentBalance) + `TrialBalanceTotals` + `TrialBalanceReport` مع `scopeLevel/scopeLabel/asOfDate/fromDate/toDate/rows/totals` وثابت `.empty` وgetter `isEmpty`.

### المستودع (`lib/features/accounts/data/repositories/account_repository.dart`)
- `fetchAccountStatement` — تُمرّر الآن `fromDate/toDate/cancelToken` وتُرجع `AccountStatementData` الموسّع.
- `fetchGroupStatement` — **جديد**: GET `/accounts/group-statement` مع باراميترات الاختيار (`acc_no`, `acc_sub`, `acc_part`, `group_id`, `from_date`, `to_date`) + `CancelToken`.

### Utils جديدة (`lib/features/accounts/presentation/utils/`)
- `group_statement_scope.dart` — دالة نقية `resolveStatementScope({accNo, accSub, accPart, groupId})` بالأولوية: group > sub > main > account، وفئة `StatementScope` بـ`toQueryParameters()` تُرجع السلسلة الكاملة للأعلى.
- `report_pdf_fonts.dart` — `ReportPdfFonts.theme()` يُحمّل `PdfGoogleFonts.cairoRegular/cairoBold` مرّة واحدة مع كاش الحزمة.
- `account_statement_pdf_builder.dart` — `buildAccountStatementPdf({account, statement})` بطول A4، `pw.MultiPage(margin: EdgeInsets.all(24), textDirection: pw.TextDirection.rtl)`، ترويسة CENTER.JPG، جدول 7 أعمدة (رصيد افتتاحي + الحركات + الإجماليات)، تذييل صفحة مع الرصيد بالعملة، تنويه 15 يوماً + خانات توقيع.
- `account_group_statement_pdf_builder.dart` — `buildAccountGroupStatementPdf({report})` بعرضي `PdfPageFormat.a4.landscape`، رأس بصفّين (عملة محلية/أجنبية فوق مدين/دائن لكل عمود)، 8 أعمدة + صف إجمالي.

### Widgets (`lib/features/accounts/presentation/widgets/`)
- `account_statement_report_table.dart` — **مُعاد بناؤه**: `formatStatementAmount()` (يعيد استخدام التنسيق في الـ PDF)، `statementTableMetrics(width)` يرجع record على مستويات 450/650، `AccountStatementLetterhead` (CENTER.JPG + طابع زمني + نطاق تاريخ)، جدول 7 أعمدة `Table` بألوان شركة (`kStatementHeaderBgColor = 0xFFD4A853`، `kStatementBorderColor = 0xFF4B5563`). لا `GoogleFonts.cairoTextStyle` — الثيم يطبّق Cairo عالمياً.
- `account_statement_report_footer.dart` — صندوق إجمالي (افتتاحي/مدين/دائن/نهائي) + ثلاث خانات توقيع + تنويه 15 يوماً.
- `account_group_statement_report_table.dart` — **جديد**: جدول ميزان المراجعة 8 أعمدة برأس مزدوج + صف إجمالي «إجمالي حسابات {asOfDate}».

### الشاشات (`lib/features/accounts/presentation/screens/`)
- `account_statement_screen.dart` — **إعادة كتابة كاملة**: AppBar فيه تبديل الفلاتر + `PermissionGate(Perm.accountsPrint)` → طباعة + `PermissionGate(Perm.accountsExport)` → تصدير PDF + تحديث. الجسم: `InteractiveViewer(minScale: 0.5, maxScale: 3)` يغلّف الترويسة + الجدول + التذييل داخل `Card` بـ`ConstrainedBox(maxWidth: 900)`. `_parseServerDate` + التعبئة التلقائية عند `res.defaulted` بنافذة 15 يوماً حول آخر حركة. `_printReport`/`_exportPdf` تستدعي `buildAccountStatementPdf()` ثم `Printing.layoutPdf`/`sharePdf`.
- `account_group_statement_screen.dart` — **جديدة**: `StatefulWidget` بأربع `DropdownButtonFormField<int>` (المستويات A→M→S→G) متسلسلة إعادة الضبط، حقلَي تاريخ اختياريّان («اترك الفترة فارغة لعرض كل الحركات») + تلميح «كل السجل»، زر فلاتر قابل للطيّ، نفس نمط `InteractiveViewer` + Letterhead + جدول الميزان، الطباعة/التصدير خلف `PermissionGate`. `_loadReport()` يستخدم `resolveStatementScope()` ثم `fetchGroupStatement`.
- `accounts_dashboard_screen.dart` — أُضيفت بلاطة ثالثة `_buildModernActionTile` «كشف حساب مجموعة حسابات جزئية» بأيقونة `Icons.account_tree_rounded` وشارة «تقرير» ولون `Color(0xFF00695C)`.

### الاختبارات (20 اختباراً جديداً، 80 ناجحاً إجمالاً)
- `test/features/accounts/group_statement_scope_test.dart` — 8 اختبارات للنطاق.
- `test/features/accounts/account_statement_models_test.dart` — dual-case + تصحيح CP-1256 (0xDE → 'ق') + تطبيع العملة الفارغة + `TrialBalanceReport`.
- `test/features/accounts/account_group_statement_screen_test.dart` — 3 widget tests مع `_StubAuthNotifier extends AuthNotifier` و`_FakeRepo extends AccountRepository`.

### البوابة والصلاحية
- لا شاشة تعرض بلا `PermissionGate` مناسب؛ الطباعة/التصدير مخفيان تماماً بدون صلاحية (وليسا معطّلين فقط).
- الرمز `accounts.statement` مطلوب على كلا المسارين الخلفيّين؛ الرمزَين `accounts.print` / `accounts.export` يقيّدان الأزرار على العميل (الخادم يتحقّق مجدداً).

### أخطاء تقنية تم حلّها أثناء التنفيذ
- PowerShell لا يقبل `&&` → استخدمنا `;`.
- `GoogleFonts.cairoTextStyle()` غير موجودة في google_fonts 6.3.2 → إزالة `DefaultTextStyle` (الثيم يطبّق Cairo أصلاً).
- `pw.BuildContext` خاطئ → الصحيح `pw.Context` (typedef `BuildCallback = Widget Function(Context)`).
- `PdfPageFormat.a4.copyWith(marginAll:)` غير متاحة → نقل الحاشية إلى `pw.MultiPage(margin: EdgeInsets.all(24))`.
- `PdfColors.black87/black54` غير موجودة في pdf 3.11.3 → `PdfColors.grey600` و`PdfColor.fromInt(0xFF6B7280)`.
- `PdfPageFormat.a4.copyWithLandscape()` غير موجودة → `PdfPageFormat.a4.landscape` (getter).
- `DropdownButtonFormField(initialValue: ...)` غير مدعوم في Flutter 3.7 SDK → `value:`.
- وصول ثابت عبر كائن (`m.border`) → استبدال بمسار ثابت مباشر (`_PdfColors.border`).
- قائمة `const [...]` تحتوي استدعاءات دوال → إزالة `const`.
- `_PdfColors.rowStripe` غير مستخدم في builder المجموعة → حذف الحقل.

---

## [2026-10-21 06:17] دورة حياة الجلسات: حذف فور الانتهاء + خروج قسري فوري إلى شاشة الدخول

**المنفِّذ:** Qoder Agent · **البداية:** 04:20 · **النهاية:** 06:17 · **المرجع الزمني:** `SYSDATE`.

### التشخيص الجذري (قبل أي سطر كود)
الخللان اللذان بدوا مستقلين كانا مرجعَين مختلفين للوقت:
- `config/app.php` → `timezone => 'UTC'`، وقاعدة أوراكل تعمل على `+03:00` (قياس: `SYSDATE 03:49` مقابل `UTC 00:49`).
- `SessionPolicy` يكتب ويقرأ بـ`now()` (UTC)، وشاشة الجلسات و`expireTokens()` يستخدمان `SYSDATE`.
- النتيجة (1): موعد مكتوب بـUTC يبدو أمام `SYSDATE` متأخراً ثلاث ساعات ⇒ **كل الجلسات تظهر «منتهية»**.
- النتيجة (2): إنهاء جلسة بـ`SYSDATE - 1` يُقرأ في PHP **في المستقبل** ~3 ساعات ⇒ الجلسة المنهية **تُقبل** ولا يسقط المستخدم، ثم «تُمدّد» من جديد في أول طلب.
- النتيجة (3): التراكم المرصود = 20 صفاً `EXPIRES_AT IS NULL` من سبتمبر/أكتوبر؛ لم تُمسّ منذ عمل السياسة، والشاشة تعرضها «نشطة» لأن `NULL` يعني «بلا انتهاء» عند Sanctum.

### الخادم / `kyApp_API/`
| ملف | التغيير |
|---|---|
| `app/Support/SessionPolicy.php` | `dbNow()` + `clockOffset()` (إزاحة تُقاس مرة لكل طلب من `SELECT TO_CHAR(SYSDATE,...) FROM DUAL`، `0` عند تعذّر القراءة)؛ كل الحسابات الزمنية مرّت عليه؛ `discard()` يمسح التوكن المرفوض في فرعي الانتهاء؛ `purgeExpired()` بفرعين (منتهي الموعد / قديم بلا موعد وخامل تتجاوز المهلة) |
| `app/Http/Controllers/AuthController.php` | `purgeExpired()` بعد `prime()` في `login` (149) و`biometricLogin` (396) |
| `app/Http/Controllers/SessionAdminController.php` | حقن `SessionPolicy` في المنشئ؛ كنس في أول `index()`؛ `minutes_left` يقارن بـ`dbNow()` |
| `app/Http/Middleware/AppendSessionExpiry.php` | **جديد** — `X-Session-Expires-At` على ردود الـAPI المُصادَق عليها + `Access-Control-Expose-Headers`؛ بلا استعلام قاعدة (التوكن محلول في `auth:sanctum`)؛ فشلُه لا يُسقط الرد |
| `bootstrap/app.php` | تسجيل الـmiddleware بـ`$middleware->api(append: …)` |

**لم يُغيَّر `app.timezone`:** تغييره كان يعيد تأريخ كل الأقسام (وفيها الحسابات التي يعمل عليها مسار آخر الآن). الإزاحة محصورة في سياسة الجلسات.

### العميل / `lib/`
| ملف | التغيير |
|---|---|
| `lib/core/network/auth_interceptor.dart` | `onResponse` يلتقط `x-session-expires-at` ويمرّره لنداء `onSessionDeadline` |
| `lib/core/network/dio_client.dart` | بارامتر جديد `onSessionDeadline` يمرر للـinterceptor |
| `lib/features/auth/presentation/providers/auth_notifier.dart` | `dart:async`؛ تمرير الـcallback في `dioClientProvider`؛ `updateSessionDeadline()` يحدّث الحالة ويخزّن `ky_session_expires_at`؛ `_watchdogInterval = 30s` مع `_enforceDeadline()`؛ `_enforceDeadline()` بعد استعادة اللقطة في `checkAuthStatus()`؛ `forceLogout()` يستدعي `clearAll()` |
| `lib/main.dart` | `ref.listen` على `isAuthenticated` في `KyApp`: سقوط من مُصادق إلى غير مُصادق ⇒ `appRouter.go('/login')` (مصدر واحد للمسارات الثلاثة: إنهاء المدير، مهلة الخمول، الخروج العادي) |
| `lib/features/employee_portal/presentation/screens/employee_main_layout.dart` | إزالة `context.go('/login')` اليدوي واستيراد `go_router` غير المستخدم |

### قرارات تصميمية
- **الحارس المحلي لا يشبك أبداً:** أي طلب فحص يمدّد `EXPIRES_AT` انزلاقياً فيبطل مهلة الخمول؛ فالقرار محلي بالكامل والترويسة تغذّيه.
- **الترويسة لا تُمنح حقاً:** الرفض ما زال قرار الخادم عند كل طلب؛ العميل يُخرج المستخدم للراحة ولشاشة الدخول الفورية فقط.
- **`clearAll()` تحفظ البصمة ورابط الـAPI** كما في الخروج العادي، فلا يفقد المستخدم دخوله بالبصمة بسبب انتهاء الخمول.

### التحقق
- `vendor/bin/pest` → **127 passed / 685 assertions** · Pint → passed · `flutter test` → **80 passed** · `flutter analyze` → تحذير واحد خارج النطاق (`lib/features/auth/presentation/widgets/biometric_login_button.dart:24`، متغير `label` غير مستخدم من عمل جارٍ على ملف آخر؛ لم يُلمَس احتراماً لمسار التطوير الموازي).
- قياس بعد الكنس: `PERSONAL_ACCESS_TOKENS` من **22 صفاً** (2 منتهية الموعد + 20 بلا موعد) إلى **صفر منتهية وواحد حيّ**.


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

## [2026-10-21 07:32] — تتمة آلية الجلسات: توثيق `AGENTS.md` وجعل اختبار الجلسات لا يعتمد على صف حيّ
**المنفّذ:** Qoder Agent · **الفرع:** main · **مرتبط بمهمة:** [2026-10-21 06:17] ساعة أوراكل + الحذف الفوري + الخروج القسري

### الدافع
بعد أن صار الكنس يعمل فعلياً أصبحت `ACCOUNTS.PERSONAL_ACCESS_TOKENS` فارغة عندما لا أحد مسجلاً
(فحص 07:32 = 0 صفوف، وكانت 22 صفاً ميّتاً قبل الإصلاح). اختبار بنية قائمة الجلسات كان يستخدم
`assertJsonStructure(['data' => [[…]]])`، وهو يطلب عنصراً أولاً دائماً ⇒ فشل
`Failed asserting that an array has the key 0`. هذا **سلوك صحيح** للواجهة لا انحدار.

### التغييرات
| الملف | التغيير |
|---|---|
| `kyApp_API/tests/Feature/ActiveSessionsTest.php` | فحص البنية صار لكل صف موجود (`toHaveKeys`) + تخطٍّ لطيف عند الجدول الفارغ، بنفس نمط اختبار الأسماء العربية في الملف نفسه. لا كتابة على القاعدة. |
| `AGENTS.md` (جذر) | §14 سطر الجلسات يذكر `dbNow()`/الحذف عند الرفض/`purgeExpired()`/ترويسة `X-Session-Expires-At`/كلب حراسة الموعد · §8 العدد 127 اختباراً + حالات `IbacCoreTest` الجديدة + استثناء `PERSONAL_ACCESS_TOKENS` من قاعدة «القراءة فقط» |
| `kyApp_API/AGENTS.md` | §2 (الوسطان: `EnsurePermission` + `AppendSessionExpiry`، ومسؤوليات `SessionPolicy`) · §3 (الترويسة تسهيلية لا حدّ أمان) · §6 (جدول الحياة مع `discard()`/`purgeExpired()`/`dbNow()` وسبب عدم تغيير `app.timezone`) · §10 (127 + سبب التخطّي + حقيقة أن `PersonalAccessToken` يتبع الاتصال الافتراضي) · §12 (مصيدة **C12** الساعتين المتقابلتين وتحديث **S5**) · §14 (ما هو مُلتزَم فعلاً مقابل ما هو غير مُلتزَم) · §15 |
| `db_commends.md` / `DBdevloping_history.md` | استعلام الحصر القراءة فقط ونتيجته، وجدول حالة الجدول 22 → 1 → 0 |

### قرار
لم يُعَدَّل أي سطر إنتاجي ولم تُمسّ بيانات القاعدة: الاختبار هو الذي صار صحيحاً في الحالتين.
لم يُمسّ أيضاً أي ملف من عمل المهمة الجارية على قسم الحسابات (`AccountController`, `CustomerController`,
`routes/api.php`, `BusinessRoutesSealedTest`) — التعديلات محصورة في ملفات الجلسات والتوثيق.

### التحقق (أعيد قياسه كاملاً في هذه الجولة)
- `php artisan test --compact` = **125 ناجحاً + 2 متخطٍّ (669 تأكيداً)** — 127 اختباراً، لا فشل.
- `vendor/bin/pint --dirty` = **PASS**.
- `flutter analyze` = تحذير واحد **خارج النطاق**: `lib/features/auth/presentation/widgets/biometric_login_button.dart:24` متغير `label` غير مستخدم (جزء من تعديل جارٍ لمهمة أخرى، تُرك كما هو).
- `flutter test` = **91/91 ناجح**.
- Oracle (قراءة فقط): `TOKENS = 0` — لا صفوف ميّتة.



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

## 2026-10-21 — ترويسة التقارير تأخذ هوية الشركة من الإعدادات
## 2026-10-21 — Report letterheads read the company identity from app config

**المتطلب / Requirement:** ترويسة التقريرين الماليين تعرض اسم الشركة والعنوان ومعلومات
التواصل كما في `acc_report.pdf` و`TRIAL_BALANCE_REPORT.pdf` (سطر الاسم فوق سطر
`العنوان | هاتف: …`)، بدل الاكتفاء باسم الحساب والشعار.

**الحالة / Status:** منفَّذ — قراءة من `AppConfigModel` (مفاتيح `APP_SETTINGS.company_*`
عبر `GET /app-config`)، فلا نص شركة مكتوب في الواجهة ولا في مولّد الـ PDF.

**التصميم / Design:**
- `utils/report_letterhead_info.dart` — `ReportLetterheadInfo{companyName,address,phone,website}`
  + `fromConfig(AppConfigModel)` + `contactLine` الذي يجمع الحقول بـ` | ` مع بادئة «هاتف:»
  و«الموقع:» **ويتجاوز الفارغ** فلا فاصل معلّق، + `hasContactLine`.
- `widgets/report_letterhead_branding.dart` — `ReportLetterheadBranding(info:)` عمود موسّط
  (اسم w900/14 فوق سطر تواصل w600/11) فيُلفّ العنوان الطويل بدل أن يفيض عند 1.25×.
- `utils/report_pdf_letterhead.dart` — `reportPdfLetterheadBranding(info)` مقابلتها في PDF
  بنفس الكائن ونفس الترتيب، فمتى نظر المستخدم إلى الترويسة أو طبّعها قرأ النص نفسه.
- الشاشة تراقب `appConfigNotifierProvider.select((s) => s.config)` في `build` (فتنعكس أي
  تعديل هوية فوراً)، بينما يقرأها `ref.read` في `_letterheadInfo()` لمسار الطباعة/التصدير —
  لأن `ref.watch` مسموح داخل `build` فقط.
- الترويسة صارت: الشعار → اسم الشركة → سطر التواصل → عنوان التقرير → الحساب/العملة →
  النطاق والطابع، على الشاشة (كشف حساب مالي + مجموعة الحسابات) وفي مولّدَي الـ PDF.
- `AccountStatementLetterhead` و`buildAccountStatementPdf` و`buildAccountGroupStatementPdf`
  أخذت جميعها عاملاً إجبارياً جديداً `letterhead` — الترويسة المعروضة والتقرير المطبوع
  مصدرُهما الواحد، فلا يتباعدان أبداً.

**الملفات / Files:** `report_letterhead_info.dart` · `report_letterhead_branding.dart` ·
`report_pdf_letterhead.dart` · `account_statement_report_table.dart` ·
`account_statement_pdf_builder.dart` · `account_group_statement_pdf_builder.dart` ·
`account_statement_screen.dart` · `account_group_statement_screen.dart`.

**الاختبارات / Tests:** `report_letterhead_info_test.dart` (4 اختبارات: تركيب سطر التواصل،
تجاوز الفارغ، غياب سطر التواصل، خريطة `fromConfig`) + اختبار ترويسة في
`account_statement_report_widgets_test.dart` يتأكد أن الهوية المعروضة هي نفسها الممَرة.
**إصلاح اختبار سابق:** كان `find.textContaining('من تاريخ')` يلتقط أيضاً تنويه التذييل
«خلال 15 يوماً من تاريخ إصداره» فيجد مرشحين وفشل — ضُيّق إلى `'من تاريخ:'` (النقطتان
الرأسيتان تميّزان حقل الترويسة وحده).

**التحقق / Verification:** `flutter analyze` نظيف (غير تحذير `biometric_login_button.dart:24`
السابق) · `flutter test` **100/100** ناجح.

**ملاحظة / Note:** قالب PDF يعرض أيضاً «صندوق بريدي: 1234» — لا حقل له في `APP_SETTINGS`
(الموجود: `company_name/address/website/phone`)؛ يمكن للمشغّل ضمه إلى حقل العنوان، أو
إضافة مفتاح `company_po_box` إن طُلب.

---

## 2026-10-21 — تصحيح ترويسة التقارير إلى شريط ثلاثي الأعمدة (عربي / شعار / إنجليزي)
## 2026-10-21 — Report letterhead corrected to a three-column band (Arabic / logo / English)

**النموذج المنفّذ:** Qoder Agent · **الوقت:** 2026-10-21 · **النطاق:** عميل Flutter فقط
(شاشتا التقريرَين + مكوّنا الترويسة + نموذجا البيانات) — لا تغيير في الـ API ولا في أوراكل.

**المطلوب (نص الأمر):** الترويسة تكون: يميناً اسم الشركة وتحته العنوان وأرقام التواصل،
في المنتصف شعار الشركة، يساراً الاسم والعنوان وأرقام التواصل بالإنجليزي — كما في الصورة.
الكتلة الموسّطة أحادية السطر التي نُفِّذت سابقاً مرفوضة.

**ما تم / Changes:**
1. `lib/features/accounts/presentation/utils/report_letterhead_info.dart`
   - حقول جديدة `companyNameEn` و`addressEn` (اختيارية بقيمة فارغة، فلا كسر لأي نداء سابق).
   - واجهة الأسطر: `arabicLines` و`englishLines` — الاسم أولاً ثم العنوان ثم سطر الهاتف
     (`هاتف: …` / `Tel: …`) ثم الموقع إن وُجد. لم يعد هناك `contactLine` مفرد.
   - ثوابت الترويسة المطبوعة `kFallbackNameAr/En`, `kFallbackAddressAr/En`, `kFallbackPhone`
     كقيمة بديلة حين يكون الإعداد فارغاً، فلا تُطبع ترويسة أنصاف‑معلومات.
   - دالة `toArabicIndicDigits()` جديدة: تحويل الأرقام اللاتينية إلى هندية (٧٨٠١٥٤٠٠٠ …)
     لمطابقة الجانب العربي من الترويسة المطبوعة؛ باقي المحارف يمر كما هو.
2. `lib/features/app_config/data/models/app_config_model.dart`
   - `companyNameEn` / `companyAddressEn` مع `defaults()` و`fromJson()` بقراءة بفتحتي
     حالة (`company_name_en` ?? `COMPANY_NAME_EN`) عملاً بقاعدة صفوف أوراكل الخام،
     و`toJsonForUpdate()` و`copyWith()`. الافتراضي الإنجليزي للاسم `ALkabodi`.
     ملاحظة أمان توافق: الخادم لا يعرف المفتاحين بعد، و`AppConfig::WRITABLE_KEYS`
     لم يُضف إليهما قصداً — لو أُضيف مفتاح بلا صف في `APP_SETTINGS` لفشل كل حفظ
     بـ«الإعداد غير معروف». إضافة المفتاحين تُجعل لاحقاً مع بذر الصفّين معاً.
3. `lib/features/accounts/presentation/widgets/report_letterhead_branding.dart`
   - إعادة كتابة كاملة: `LayoutBuilder` + `Row` من ثلاثة `Expanded` بنسب 5 : 4 : 5.
     اليمين كتلة عربية `Directionality(rtl)`، الوسط `Image.asset('assets/CENTER.JPG')`،
     اليسار كتلة إنجليزية `Directionality(ltr)` صريحة (وإلا انعكس ترتيب كلماتها داخل RTL).
     `nameSize = width/42` و`detailSize = width/62` مع `clamp` وارتفاع شعار أصغر تحت 380px:
     الترويسة لا تفيض أبداً لأن كل شيء داخل `Expanded`، حتى مع قيد التطبيق 1.25× تكبير خط.
   - خاصيتان جديدتان `logoAsset` و`logoHeight` بدل `nameFontSize`/`contactFontSize`.
4. `lib/features/accounts/presentation/utils/report_pdf_letterhead.dart`
   - `reportPdfLetterheadBranding(info, {logo})` يرسم نفس الشريط بـ`pw.Row`/`pw.Expanded`
     بنفس النِسَب، مع `textDirection` صريح لكل `pw.Text` واتجاه توسيط للمقالات.
   - `loadPdfLetterheadLogo({asset, height})` جديدة: `rootBundle.load` → `pw.MemoryImage`
     → `pw.Image` داخل `pw.SizedBox`؛ تعيد `null` في `try/catch` فلا يفشل توليد التقرير
     بسبب أصل مفقود، ويبقى العمود الأوسط فارغاً بدل ذلك.
5. `widgets/account_statement_report_table.dart` و`screens/account_group_statement_screen.dart`
   - حذف الشعار الموسّط المكرّر (`Center(Image.asset('assets/CENTER.JPG'))`) لأن الشريط
     ثلاثي الأعمدة يرسمه؛ الترويسة الآن `ReportLetterheadBranding(info:, logoHeight:)` فقط.
6. `utils/account_statement_pdf_builder.dart` و`utils/account_group_statement_pdf_builder.dart`
   - تحميل الشعار مرة واحدة قبل `doc.addPage` وتمريره إلى `_letterhead(..., logo)`؛
     بصمة `_letterhead` أضافت معامل `pw.Widget? logo` في المولّدَين (لا تغيير في الاستدعاءات
     العامة: الطباعة والتصدير يمرّران `letterhead` كما كان).

**الاختبارات / Tests:**
- `test/features/accounts/report_letterhead_info_test.dart` — أُعيدت كتابته على الواجهة
  الجديدة: أسطر العمودين، بادئتا `هاتف:`/`Tel:`، أرقام الموقع، الافتراضيات المطبوعة،
  أولوية القيمة المضبوطة (بما فيها `ALkabodi`)، وتحويل `toArabicIndicDigits`.
- `test/features/accounts/account_statement_report_widgets_test.dart` — `_letterhead`
  بالحقول الإنجليزية؛ اختبار جديد **يثبت هندسة الأعمدة** بـ`getTopLeft`:
  `arabicName.dx > logoLeft.dx > englishName.dx` عند 700px (لو رجعت الترويسة إلى عمود
  موسّط لفشل الاختبار)، وتحديث اختبار هوية الشركة ليطابق الأسطر الجديدة.

**التحقق / Verification:** `flutter analyze` — لا issues جديدة (تحذير واحد سابق
غير متعلق). `flutter test` — 105/105 ناجح (كانت 100 + 5 اختبارات جديدة/محدّثة).


### 2026-10-21 08:05 — تصحيح توثيقي لنفس المهمة / documentation correction (same task)
- الافتراضي الإنجليزي للاسم استقر على `ALKABODI FOR MEN's TAILORING` في
  `AppConfigModel.defaults()` وفي `fromJson()` معاً (كان `ALkabodi` أثناء الكتابة أعلاه،
  ثم ضبطه المستخدم يدوياً). الفاصلة في `MEN's` كُتبت داخل سلسلة Dart مزدوجة الاقتباس
  `"..."` لأن السلسلة مفردة الاقتباس لا تستوعبها بلا هروب.
- أصل الشعار في الترويسة استقر على `assets/logo3.jpg` (بديل عن `assets/CENTER.JPG`):
  `ReportLetterheadBranding.logoAsset = 'assets/logo3.jpg'` و`logoHeight = 78` كافتراضي
  واحد للشاشة، و`loadPdfLetterheadLogo(asset: 'assets/logo3.jpg')` للطباعة — فلا يختلف
  ما يُعرض عمّا يُطبع. حُذفت Overrides الارتفاع من الشاشتين ليتحكم الافتراضي وحده.
- التوثيق السابق لم يُحذف ولم يُستبدل؛ هذه إضافة لاحق فقط. Prior text untouched; appended only.


### 2026-10-21 11:07 — تعميم الترويسة + حقلا الشركة بالإنجليزية في الإعدادات
**النموذج المنفّذ:** Qoder Agent · **الأمر:** إضافة `company_name_en`/`company_address_en` إلى
`APP_SETTINGS` وحقلين في شاشة الإعدادات وتطبيق الترويسة على تقريرَي العملاء والعاملين.

#### 1) نقل الترويسة المشتركة إلى `lib/core` (ليست حكراً على الحسابات)
- `utils/report_letterhead_info.dart` → `lib/core/utils/report_letterhead_info.dart`
- `utils/report_pdf_letterhead.dart` → `lib/core/utils/report_pdf_letterhead.dart`
- `widgets/report_letterhead_branding.dart` → `lib/core/widgets/report_letterhead_branding.dart`
- أُعيد توجيه خمسة مستورِدين في `features/accounts` + ملف الاختبار إلى `package:ky_apps/core/...`
  مع ترتيب الاستيرادات (`directives_ordering`)، وحُذفت الملفات القديمة من مجلد الـ accounts.
- **لماذا؟** شريط الترويسة الثلاثي الأعمدة صار تستهلكه الحسابات والعملاء والعاملين (شاشةً وطباعةً)،
  فحُبسه داخل ميزة واحدة كان يجبر الباقي على استيراد عابر للميزات.

#### 2) حقلا الشركة بالإنجليزية في شاشة «إعدادات التطبيق»
- `app_config_screen.dart`: متغيّرا `_companyNameEn`/`_companyAddressEn` (تهيئة/تخلّص/حفظ)،
  وحقلان نصّيان بعد نظيريهما العربيين، و`_textField` اكتسب `bool ltr` لضبط اتجاه الإدخال لاتيني
  للاسم/العنوان الإنجليزيين. الحفظ يمرّهما عبر `AppConfigModelBuild.fromFields`.
- `app_config_model.dart` (سابقٌ لهذا الأمر): `companyNameEn`/`companyAddressEn` بقراءة ثنائية
  المفتاح (`company_name_en`/`COMPANY_NAME_EN`) وافتراضي وتمرير في `toJsonForUpdate()`.

#### 3) تطبيق الترويسة على تقريرَي العملاء والعاملين
- `customer_statement_screen.dart`: حُذفت الكتلة الزخرفية المرسومة يدوياً (1430 → 1203 سطراً) وحُلّت
  محلها `_buildOfficialHeader()` → `ReportLetterheadBranding(info: ReportLetterheadInfo.fromConfig(...))`.
- `worker_statement_screen.dart`: بالمثل (1473 → 1364 سطراً) عبر `_buildReportHeader()`.
- أُضيفت ثلاثة استيرادات لكل شاشة (`core/utils/report_letterhead_info`, `core/widgets/report_letterhead_branding`,
  `app_config/presentation/providers/app_config_notifier`) وأصبح الشريط يقرأ الإعداد مباشرة، فلا
  الحاجة لتمرير `context` اليدوي الذي كان في الكتل القديمة.
- **لا عناوين جديدة داخل الشريط** — العنوان موجود في شريط التطبيق وشريط البيانات؛ الشريط معلومات الشركة فقط.

#### 4) تنظيف تابع
- `account_statement_report_table.dart`: حُذف `now`/`timestamp` الميّتان (بعد إزالة المستخدم طابع
  الزمن من الرأس) وتصحيح تعليق عربي قديم.

#### الاختبارات / التحقق
- `test/core/utils/report_letterhead_info_test.dart` (نُقل من `test/features/accounts/`) += اختبار
  «ما يرسله الخادم يصل إلى كلا العمودين».
- `test/app_config_model_test.dart` += قراءة ثنائية المفتاح للاسم الإنجليزي و`toJsonForUpdate` يحمل المفتاحين.
- `flutter analyze` = نظيف (تحذير واحد سابق في `biometric_login_button.dart:24`) ·
  `flutter test` = **108/108** (كانت 105).


---

## [2026-10-22 09:30] توحيد ترويسة/تذييل PDF وإصلاح انعكاس الأعمدة وربط تقارير العملاء/العاملين
**النموذج:** Qoder Agent

### 1) إصلاح انعكاس اتجاه جدول PDF (RTL)
- الجذر: `pw.Table` في حزمة `pdf` يرسم أطفاله يسار→يمين دائماً بغض النظر عن `MultiPage.textDirection: rtl`، بينما جدول Flutter على الشاشة RTL (العمود 0 يميناً). لذلك ظهر السند يساراً في PDF.
- الحل: عكس قوائم `pw.TableRow.children` وإعادة فهرسة `columnWidths` في البنّائين، عبر مساعد موحّد `reversedCells()` في `core/utils/report_pdf_page.dart`.
- `account_statement_pdf_builder.dart`: 7 أعمدة معكوسة `{0:1.4 الرصيد … 6:0.9 السند}`.
- `account_group_statement_pdf_builder.dart`: 8 أعمدة معكوسة `{0:1.5 الرصيد … 7:1.2 رقم}`.

### 2) إصلاح كشف المجموعة الجزئي
- `account_group_statement_screen.dart`: `_onGroupChanged(int? value)` كان يستدعي `_loadReport()` لغير null فقط؛ الآن يستدعيه دائماً فيعود التقرير لمستوى الحساب الجزئي عند اختيار «— بدون اختيار —». (المنطق الخلفي `resolveStatementScope` كان سليماً.)

### 3) وحدة ترويسة/تذييل PDF موحّدة
- ملف جديد `lib/core/utils/report_pdf_page.dart`: `buildReportPdfHeader` (شريط الترويسة الثلاثي + العنوان + صف بيانات التقرير + حد سفلي)، `buildReportPdfFooter` (العملة + صفحة N/M)، ومساعدي الجدول `reversedCells`/`pdfTh`/`pdfTd` و`pdfDateRangeRow`/`pdfSignatures` و`ReportPdfColors` (ذهبي/رمادي مصدر واحد للحقيقة).
- نُقل `report_pdf_fonts.dart` من `features/accounts` إلى `core/utils` ليُستخدم عابراً للوحدات؛ حُدّثت استعارات البنّائين الأربعة ورتّبت حسب `directives_ordering`.

### 4) بنّاءا PDF لتقارير العملاء والعاملين
- جديد `customer_statement_pdf_builder.dart`: `buildCustomerStatementPdf(...)` بنفس الجدول السباعي والترويسة/التذييل الموحّدين وكتلة التواقيع؛ يعمل بـ `CustomerStatementModel`.
- جديد `worker_statement_pdf_builder.dart`: `buildWorkerStatementPdf(...)` يعرض اسم العامل ونوعه (مقاول/خياط/قاطع) ورقم الحساب؛ يعمل بـ `WorkerStatementModel`.
- كلاهما يستورد `formatStatementAmount` من ودجت تقارير الحسابات (سابقة الاستيراد العابر للوحدات نفسها المتبعة مع الترويسة).

### 5) ربط الطباعة/التصدير + التكبير على الشاشتين
- `customer_statement_screen.dart`: استعارات `printing` + `PermissionGate` + `permission_codes` + البنّاء؛ توابع `_letterheadInfo`/`_printReport`/`_exportPdf`؛ زرا AppBar داخل `PermissionGate(Perm.customersPrint/customersExport)`؛ لفّ المحتوى بـ `InteractiveViewer(minScale:0.5, maxScale:3)`؛ وإزالة معقوفتي `${}` الزائدتين (lint).
- `worker_statement_screen.dart`: حُذفت نافذة `_showExportOptions` الوهمية (كانت تعرض SnackBar فقط) واستُبدلت بـ `_letterheadInfo`/`_buildPdfBytes`/`_printReport`/`_exportPdf` حقيقيين؛ زرا AppBar داخل `PermissionGate(Perm.accountsPrint/accountsExport)` (لا أكواد طباعة خاصة بالعامل)؛ و`InteractiveViewer` حول الجدول؛ وإضافة `import 'dart:typed_data'`.

### الاختبارات / التحقق
- `flutter analyze` على workers/customers/accounts/core = **لا مشاكل**.
- `flutter test` = **108/108** (بدون تغيير عدد الاختبارات؛ لم تُضف حزم).


---

## [2026-10-22 14:20] إصلاح نطاق الحساب الجزئي في كشف المجموعات + اختيار افتراضي للرئيسي/الفرعي
**النموذج:** Qoder Agent

### المشكلة
كشف «مجموعة حسابات جزئية»: عند اختيار حساب جزئي (accPart) بدون اختيار مجموعة، ظهر «لا توجد حسابات في هذا النطاق» رغم وجود الحسابات. كذلك طُلب اختيار افتراضي لأول حساب في «حساب رئيسي» و«حساب فرعي».

### التحليل (بالموصِل oracledb MCP — قراءة فقط)
- بنية `ACC_NO` في `CHART_ACC`: 8 أو 9 خانات؛ الطبقات مشفّرة كبادئة: خانة واحدة للحساب الرئيسي، خانتان للفرعي، **ثلاث خانات للجزئي** (مثال `12310000`→الجزء 123=العملاء، و`123110001` تسعة خانات تبدأ بـ123 أيضاً).
- الصيغة القديمة `TRUNC(c.ACC_NO / 10000)` تعطي بادئة من 4 خانات للأرقام ثمانية الخانات (وليس 3)، فلا تساوي أبداً `ACC_PART` ثلاثي الخانات ⇒ نتيجة فارغة. تأكد بالعدّ: `TRUNC(/10000)=110` أعطى 0 بينما `TRUNC(/100000)=110` أعطى 1، والفرع `main` بنفس العطب (0 مقابل 23).
- `CHART_ACC.GROUP_ID` مُعبّأ في 283 صفاً فقط من 20954، فلا يصلح ربطاً رئيسياً بالجزء.

### الحل (الخادم `AccountController::getGroupStatement`)
- استبدال `TRUNC(c.ACC_NO / 10000)` بصيغة مستقلة عن الطول `SUBSTR(TO_CHAR(c.ACC_NO), 1, 3)` في الفروع الثلاثة (`sub`/`main`/`account`)، مع مطابقة `TO_CHAR(ACC_PART)` في الاستعلامات الفرعية. تحقّق: يطابق 20954/20954، والفرع `sub` للجزء 123 يُرجع 20469 صفاً.

### الحل (العميل `account_group_statement_screen.dart`)
- حقلا علم لمرة واحدة `_autoSelectedAccNo`/`_autoSelectedAccSub` + دالة `_maybeApplyDefaults(accountsAsync, accMainAsync)` تُستدعى داخل `_buildCascadeDropdownRow`: تختار أول حساب رئيسي (دون جلب)، ثم عند وصول قائمة الفرعي تختار أول فرعي وت جلب التقرير مرة واحدة عند مستوى الفرعي. تستخدم `addPostFrameCallback` + `mounted` لتفادي setState أثناء البناء، والأعلام تمنع إعادة فرض الاختيار بعد تدخّل المستخدم.

### الاختبارات
- `test/features/accounts/account_group_statement_screen_test.dart`: استُبدل اختبار «الحالة الفارغة قبل الاختيار» باختبار «الاختيار التلقائي لأول رئيسي/فرعي وتحميل التقرير»؛ واختبار «اختيار الحساب العلوي» يفتح القائمة عبر `find.byType(DropdownButtonFormField<int>).first` ويلتقط عنصر القائمة عبر `.last`؛ وعنوان الشاشة أصبح `findsWidgets` (يظهر في AppBar وفي ترويسة التقرير المحمّل).
- `flutter analyze` (الشاشة) = لا مشاكل · `php -l` = سليم · `flutter test` = **108/108**.

### تصحيح لاحق (نفس المهمة)
- في `_maybeApplyDefaults` كان اختيار أول حساب فرعي مكتوباً `list[1].accSub` (يختار الثاني ويرمي `RangeError`
  عند وجود عنصر واحد)؛ صُحّح إلى `list.first.accSub` التزاماً مع المتطلب «أول حساب في الجدول».
- التحقق بعد التصحيح: `flutter analyze` = لا مشاكل · `flutter test test/features/accounts/account_group_statement_screen_test.dart` = **+3 ناجح**.

## [2026-10-22 17:10] الواجهة الرئيسية: لوحة اختصارات مربّعة قابلة للتخصيص
**النموذج:** AutoClaw Agent

### المطلب
«خطة متكاملة لتطوير الواجهة الرئيسية وإضافة اختصارات إليها من جميع الأقسام وإمكانية تخصيص
الاختصارات التي تظهر، على شكل بطائق مربعة مرتبة ومنظمة وبتصميم احترافي» — ونُفِّذت الخطة
المكتوبة في `home_dashboard_plan.md`.

### ما كان قبل
- `home_dashboard_section.dart` ملف من 19 سطرًا يعيد `PortalSectionScaffold` بحالة فارغة.
- لا قناة للتنقل بين الأقسام: `_currentSectionId` حالة محلية في `EmployeeMainLayout` لا تُغيَّر إلا
  من الدرج/الشريط.
- لا مخزن تفضيلات في المشروع، ولا `shared_preferences`، و`path_provider` بلا تنفيذ ويب.

### ما نُفِّذ
- **ميزة جديدة `lib/features/home/`** (14 ملفًا): مجال (اختصار + هدف مختوم بأربعة أنواع + كتالوج
  30 بطاقة + تدفّقات منتقي←شاشة)، وبيانات (نموذج `HomeLayout` + مستودع بلا شبكة)، وعرض
  (مزوّد `HomeLayoutNotifier` + شاشة الرئيسية + شاشة التخصيص + ستة ودجت).
- **بطاقات مربّعة** (`childAspectRatio: 1`) بعدد أعمدة محسوب بحد أدنى 150dp، فتصمد على 320dp
  وعند تكبير الخط 1.25.
- **اختصارات من كل الأقسام**: 26 وجهة عاملة + 3 أقسام بشارة «قيد التطوير» + بطاقة تخصيص دائمة.
  13 بطاقة في التشكيلة الأولى لمدير النظام، وتنقص تلقائيًا بنقص المنح.
- **تخصيص كامل**: تبويبا «المفعّلة/المتاحة»، إعادة ترتيب بـ `ReorderableListView`، إخفاء/إظهار،
  بحث، واستعادة افتراضي، مع ورقة خيارات بالضغط المطوّل على البطاقة.
- **حفظ محلي** بمفتاح `ky_home_layout` في `SecureStorageService`، بصيغة opt-out للبطاقات
  الافتراضية وopt-in لغيرها (`order` + `shown` + `hidden` + حارس `user_id`)، والبلوب التالف أو
  التابع لمستخدم آخر يعني «أول تشغيل».
- **قناة أقسام** `PortalSectionScope` (InheritedWidget) تلفّ `IndexedStack` في الموضعين، مع فحص
  الصلاحية مرة أخرى عند الطلب، وإصلاح مؤشر الشريط السفلي حين يكون القسم المفتوح خارج الشريط.
- **عناوين الأقسام** استُخرجت إلى `portal_section_titles.dart` ليقرأها السجل والرئيسية معًا بدل نسخها.

### الاختبارات
- `test/home_layout_test.dart` (18): قراءة دفاعية، تطبيع، دمج، ثبات المثبّتة، دورة JSON.
- `test/home_catalog_test.dart` (12): تفرّد المعرّفات، مطابقة الأكواد لمرآة الصلاحيات، مطابقة كل
  `SectionTarget` لـ `viewCodes` في السجل، 13 افتراضيًا، وبطاقة مثبّتة واحدة، وفلترة المنح.
- `test/home_notifier_test.dart` (9): إخفاء/إظهار، ترتيب، استعادة، بلوب تالف، مستخدم آخر، سحب منح،
  وسباق «قراءة أبطأ من نقرة المستخدم».
- `test/responsive_layout_test.dart` (+7): الشبكة على 360×640 و1280×800، مستخدم بصلاحية قراءة
  واحدة، إخفاء الكل، تكبير 1.25، بطاقة قسم تنادي القناة، شاشة التخصيص على مقاسين، والهيكل يفتح
  على الشبكة.

**التحقق / Verification:** `flutter analyze` = **تحذيران قائمان مسبقًا فقط** (خيار `ignore ignore`
في `analysis_options.yaml`، ومتغير غير مستخدم في `biometric_login_button.dart`) · `flutter test` =
**153 ناجحًا / 3 فاشلة**، والفاشلة الثلاث هي نفسها في خط الأساس قبل التعديل
(`account_group_statement_screen_test.dart`) · لا تغيير في `pubspec.yaml` ولا مسار جديد في
`app_router.dart`.
**لم يَمَسّ:** لا تغييرات في `kyApp_API/` ولا في Oracle، ولا حزم جديدة، ولا ملفات الحوكمة.


## [2026-10-22] تقرير كشفي عمل القصاص والخياط — Flutter + Laravel API
**الوصف:** إنشاء تقريري "كشف حساب عمل القصاص" و"كشف حساب عمل الخياط" منسوخين من قالب أوراكل `FOR_CUTTER_TAILOR`/`FOR_TAILOR` مع استخدام جدول **كشف العمل فقط** (لا الكشف المالي ENTRY_MAIN/ENTRY_SUB).
**API (kyApp_API):**
- `WorkerController::fetchWorkReport(type, request, id)` — JOIN على `CUTTER_FROM_CALC`/`TAILOR_FROM_CALC` مع جدول العامل بالـ `ACC_NO` وفلترة `BETWEEN TO_DATE`. السعر = الإجمالي/العدد؛ الإجمالي = `AMT` (قصاص) / `AMT_ALL` (خياط، يشمل ADDCOST). إرجاع envelope موحّد مع worker/data/summary (total_count, total_amount, currency عبر `CUR_CODE`).
- مفاتيح `work_table/work_join_col/work_date_col/work_style_col/work_qty_col/work_total_col` في `TABLES` (cutters/tailors فقط).
- مسارَان خلف `permission:cutters.statement` / `permission:tailors.statement` (إعادة استخدام الصلاحية، لا أكواد IBAC جديدة). تحديث `BusinessRoutesSealedTest` بعينتين. `vendor/bin/pint` نظيف.
**Flutter (lib/features/workers):**
- `data/models/worker_work_report_model.dart` (WorkerWorkRow/WorkerWorkReport، قراءة مزدوجة المفاتيح، أرقام دفاعية، `ArabicEncodingUtils.fix`).
- `repositories/worker_repository.dart`: `fetchWorkReport`.
- `presentation/providers/worker_work_report_provider.dart`: Notifier + CancelToken + `ref.onDispose`.
- `presentation/widgets/worker_work_report_table.dart`: جدول 5 أعمدة RTL برأس ذهبي وسطري إجمالي.
- `presentation/screens/worker_work_report_screen.dart`: افتراضي = اليوم، فلاتر جاهزة، ترويسة/تذييل رسميان، تكبير/تصغير، 4 حالات، طباعة/تصدير خلف `PermissionGate`.
- `presentation/utils/worker_work_report_pdf_builder.dart`: يستخدم الترويسة/التذييل/التوقيعات الموحّدة في `report_pdf_page.dart`.
- `workers_list_screen.dart`: استبدال SnackBar بـ `_goToWorkReport` (دفع الشاشة لـ cutter/tailor).
**النتيجة:** `flutter analyze` نظيف · flutter test workers 5/5 · Pest 6/6 · لا DDL ولا جداول جديدة.
**لم يمسّ:** لا هجرة قاعدة بيانات، لا صلاحيات جديدة، لا مسار GoRouter جديد.


## [2026-10-22] تعديل الفترة الافتراضية لكشف العمل — آخر يوم سجل (بدلاً من اليوم الحالي)
**المطلوب:** عند فتح كشف عمل القصاص/الخياط بدون تواريخ، لا نعرض اليوم الحالي، بل نبحث عن تاريخ آخر سجل عمل فعلي للعامل ونجعله الفترة الافتراضية ونجلب التقرير عليه.
**WorkerController::fetchWorkReport:** نُقلت تعريفات الأعمدة/الجداول قبل منطق التاریخ؛ عند خلوّ `from_date`/`to_date` من الطلب یُنفَّذ `SELECT TO_CHAR(MAX(w.<dateCol>),'YYYY-MM-DD') FROM <calc> w, <reg> r WHERE w.<join>=r.<join> AND r.ACC_NO=:acc` ویُعیَّن الناتج (من = إلى)؛ وإن صفراً سجلات فالاحتیاط `Carbon::today()`. حال إرسال تاریخ واحد فقط یُطابَق للطرفین. لا تغییر في المسارات ولا الصلاحيات.
**Flutter worker_work_report_screen.dart:** `initState` یترک التاریخین null؛ متغيّر `_awaitingDefaultDates` یتتبّع أوّل طلب بلا تواریخ؛ بعد رجوع التقرير یُستخرَج `fromDate/toDate` (dd/mm/yyyy عبر `_parseDmy`) ویُحدَّث حقلا الفلتر بـ `setState` داخل `ref.listen` ليبقى العرض مطابقاً للفترة المعتمدة. لا یمسّ السلوك عند استخدام النطاقات الجاهزة أو التحديد اليدوي.
**النتیجة:** `flutter analyze` نظیف · workers 5/5 · Pint PASS · تحقّق MCP أن الافتراضي 16/08/2026 یُرجع أسطراً حقیقیة.


## [2026-10-22] إصلاح حجم شاشة كشف العمل (تجاوز أفقي) وضجيج CORS في الشبكة
**المشكلة (من سجل المستخدم):** بعد نجاح جلب كشف العمل (القصاص والخیاط) یُرمی `A RenderFlex overflowed by 26 pixels on the right`، وكل طلب GET یطبع تحذیر Dio حول preflight لكون `Content-Type: application/json` غیر ضمن قائمة CORS البسیطة.
**۱) التجاوز — worker_work_report_screen.dart:** سببه صرّف `_signatureFooter`: ثلاثة `_sigSlot` بعرض ثابت `SizedBox(width:110)` داخل `Row` (المجموع 330px) يتجاوز عرض المحتوى على الهاتف (~304px بعد الحواشی). أضحى كل خانة `Expanded` (توزیع متساوٍ على العرض المتاح) مع `Divider` بـ`SizedBox(width: double.infinity)` و`Text(textAlign:center)`، وحُذف `MainAxisAlignment.spaceAround`. عناصر `Expanded` لا تتجاوز أفقیاَ ریاضیاَ. بقیة الشاشة آمنة: شريط البيانات `Wrap` والفلاتر `Expanded` والجدول `LayoutBuilder+Table` بأعمدة مرنة.
**۲) CORS — lib/core/network/dio_client.dart:** أُزيل `Content-Type` من `BaseOptions.headers` (بقي `Accept`) وأُضيف `InterceptorsWrapper.onRequest` یعین `Headers.jsonContentType` فقط عندما یوجد جسم والطرقة لیست GET/HEAD (ویتجنّب الدهس على أنواع multipart/الصریح). الطلبات الأصلیة (POST) ما زالت تصل JSON للـLaravel، أما GET فتصبح بسيطة بلا preflight.
**التحقق:** analyze نظیف على النطاقین · workers 5/5 · المنطق حتمي لإزالة التجاوز (Expanded محدودة بعرض الـRow).

---

## 2026-10-22 — تقرير كشف عمل مجموعة (Group Work Report)

**النموذج المنفذ:** Qoder Agent · **الوقت:** 2026-10-22T19:00 · **النطاق:** عميل Flutter + Laravel API

**ما تم / Changes:**
1. **Backend (WorkerController.php):**
   - groupWorkReportCutter() + groupWorkReportTailor() — نقطتا نهاية لجلب كشف عمل جميع القصاصين أو الخياطين.
   - etchGroupWorkReport(type, request) — دالة داخلية تبني SQL استعلام متعدد العمال (CUTTER_FROM_CALC / TAILOR_FROM_CALC JOIN CUTTER / TAILOR) مع اسم العامل وترتيب حسب الاسم ثم التاريخ.
   - الافتراضي: آخر 7 أيام (Carbon::today()->subDays(6) إلى today).
   - الاستجابة: {success, group, data:[{worker_name, date, style_name, count, unit_price, total}], summary:{total_count, total_amount, from_date, to_date, worker_count}}.
2. **Routes (api.php):**
   - GET /workers/cutters/group-work-report → permission:cutters.statement`n   - GET /workers/tailors/group-work-report → permission:tailors.statement`n3. **Flutter Data:**
   - worker_group_work_report_model.dart: WorkerGroupWorkRow (6 حقول) + WorkerGroupWorkReport (group, dates, rows, totals, workerCount).
   - worker_repository.dart: إضافة etchGroupWorkReport(type, {fromDate, toDate, cancelToken}).
4. **Flutter State:**
   - worker_group_work_report_provider.dart: Notifier + NotifierProvider مع CancelToken.
5. **Flutter UI:**
   - worker_group_work_report_screen.dart: شاشة كاملة (Dropdown اختيار المجموعة + فلاتر تاريخ + نطاقات جاهزة + InteractiveViewer + ترويسة/تذييل + طباعة/تصدير).
   - worker_group_work_report_table.dart: جدول 6 أعمدة ذهبي بترويسة مطابقة للفور_CUTTER_CALC.pdf.
   - worker_group_work_report_pdf_builder.dart: PDF A4 landscape مع الترويسة الموحدة.
6. **Navigation:**
   - بطاقة رابعة 'كشف عمل مجموعة' في WorkersDashboardScreen.
   - اختصار workers.group_work في home_shortcut_catalog (codes: cuttersStatement, tailorsStatement).
7. **Tests:**
   - إضافة المسارين إلى BusinessRoutesSealedTest.php (401 + 403).

**التحقق:** php artisan route:list --path=group-work = 2 · Pint passed · lutter analyze lib/features/workers/ = No issues · lutter analyze catalog = No issues.

---

## [2026-10-22 20:30] كشف المجموعات الجزئية — إضافة «الحساب الجزئي» كخيار افتراضي ثالث
**النموذج:** Qoder Agent · **النطاق:** عميل Flutter فقط (`account_group_statement_screen.dart`)

### المطلب
«الوضع الحالي يتم اختيار اول حساب رئيسي وثاني حساب فرعي كخيارات اوليه؛ اريد ان يتم اختيار اول حساب جزئي كخيار اولي ايضا».

### ما نُفِّذ
- **إصلاح خلل قائم:** كان اختيار أول حساب فرعي مكتوباً `list[1].accSub` — يختار الثاني (وهو ما لاحظه المستخدم) ويرمي `RangeError` عند وجود عنصر واحد؛ صُحّح إلى `list.first.accSub`.
- **سلسلة اختيار افتراضي من ثلاث مراحل** في `_maybeApplyDefaults(accountsAsync, accMainAsync, accSubAsync)` مع علم جديد `_autoSelectedAccPart`: أول رئيسي (دون جلب) ثم أول فرعي (دون جلب) ثم أول جزئي وبعده `_loadReport()` عند مستوى الجزئي مرّة واحدة.
- **معالجات حدود:** إن غابت قائمة الفرعي (`firstSub == null`) يُجلب التقرير فوراً؛ وإن غابت قائمة الأجزاء يُجلب عند مستوى الفرعي المتاح. الانتقالات كلها عبر `addPostFrameCallback` + فحص `mounted`، والأعلام تمنع إعادة الفرض بعد تدخّل المستخدم.
- **الاستدعاء:** مُرِّر `accSubAsync` (من `parentAccSubProvider(_accSub)`) إلى `_maybeApplyDefaults` داخل `_buildCascadeDropdownRow`.
- **اختبار:** تحديث اسم وتعليق الاختبار الأول إلى `main/sub/part`.

### التحقق
- `flutter analyze` (الشاشة) = لا مشاكل · `flutter test ...account_group_statement_screen_test.dart` = **+3 ناجح**.
- لا تغيير خادم/قاعدة بيانات، لا حزم جديدة، لا مسارات API جديدة.


## [2026-10-22 08:49] Group Work Report - Final verification pass
- Tailors group (22/06-25/06/2026): 75 rows, 17 workers, count=235, amount=329600, Arabic decoded (ابراهيم الصعفااني / قطري جاهز)
- Cutters default window (no dates sent): from=16/10/2026 to=22/10/2026 (exactly today-6 to today, 7-day span verified)
- Empty period (01/01-02/01/2000): success=true, 0 rows, response structure keys = success, group, data, summary; summary keys = total_count, total_amount, from_date, to_date, worker_count
- Flutter unit tests: 11/11 passed under test/features/workers/ (6 new group-report + 5 existing individual)
- Backend sealed-routes test: 6 passed / 83 assertions (up from 77)
- Temp PHP verification script removed



## [2026-10-22 09:15] Group Work Report — Aggregation fix (group by worker + style)
- Problem: report listed one row per work record, repeating the worker name across many dates/styles. Requirement changed to aggregate.
- Backend WorkerController.fetchGroupWorkReport: SQL now GROUP BY worker name + style, SUM(QTY), SUM(TOTAL); removed WORK_DATE from SELECT; unit_price = group total / group count (zero-safe). Date range stays in summary only.
- Response rows drop the per-record date field: {worker_name, style_name, count, unit_price, total}.
- Flutter: removed WorkerGroupWorkRow.date; table + PDF reduced to 5 columns (الاسم|الموديل|العدد|السعر|الإجمالي); total rows place value in العدد / الإجمالي columns via valueColumn.
- Screen doc + tests updated (6/6 group tests, 11/11 workers suite). flutter analyze clean, pint passed.
- Verified via oracledb MCP (22/06-25/06/2026): 24 records collapse to 10 worker+style rows; grand totals unchanged 236 / 71050.

## [2026-10-22 08:55] إعادة تصميم بطاقات الرئيسية + خيارات الحجم والأعمدة + استكمال الكتالوج
**النموذج:** AutoClaw Agent

### المطلب
«تصميم وشكل البطاقات غير مرتب وغير جميل — أصلحه وحسّنه. وأضف في واجهة التخصيص خيارات للتحكم
بحجم البطاقات وعدد البطاقات في كل صف. وهناك أقسام واختصارات ناقصة (مثل كشف حساب مجموعة حسابات
جزئية) راجع كل الأقسام والشاشات وأضف المتبقي. وتأكد من تنفيذ الخطة بالكامل.»

### ما تغيّر

**1) البطاقة (إعادة تصميم كاملة)**
- تعبئة متدرّجة بلون القسم بدل مستطيل أبيض مسطّح، تنطلق من زاوية الأيقونة وتتلاشى إلى الأبيض.
- فاصل لوني رفيع فوق العنوان، وحدّ ملوّن يتوهّج عند التحويم، وظلّ ناعم يرتفع معه.
- صندوق أيقونة بحدّ داخلي خفيف، وأحجام محسوبة من الحجم المختار بدل أرقام مبعثرة.
- ضغط متحرّك 0.97 والموجة محصورة داخل الزوايا.

**2) الترويسة**
بطاقة ترحيب بتدرّج خفيف (primary ← accent ← أبيض) تحمل الشارة والتحية والتاريخ وزر «تخصيص»
(نصّي على الواسع، أيقوني على الجوال).

**3) خيارات العرض (تبويب ثالث «العرض»)**
- **حجم البطاقة:** صغير/متوسط/كبير — يضبط الحشو وصندوق الأيقونة وحجم العنوان والمسافات.
- **عدد البطاقات في الصف:** تلقائي/2/3/4/5/6 — يُطبَّق حيث تتّسع الشاشة ويُقيَّد بسقف
  `minReadableTile = 104dp` حتى لا تصير البطاقة أضيق من نصّها.
- **معاينة حيّة** تستخدم نفس ودجت الشبكة والبطاقة، وتُظهر العدد الفعلي قبل الحفظ.
- الحفظ في نفس بلوب التخطيط بترقية من نسخة 1 (لا إهمال للبلوب القديم).

**4) الكتالوج: 30 ⇒ 38**
- تصحيح تسميتين: «كشف مجموعة حسابات جزئية» و«كشف حساب تحليلي مفصل».
- إضافة: تعديل بيانات حساب (منتقي ← نموذج)، إضافة/تعديل مستخدم، منح الصلاحيات،
  إضافة موظف/قصاص/خياط.
- بطاقة «كشف عمل مجموعة» أُضيفت من عمل متوازٍ في المستودع على نفس الملف، وأُبقيت.

### الاختبارات
- 26 اختبارًا للنموذج (منها ترقية v1، قيم الحجم/الأعمدة، سقف الأعمدة).
- 15 للكتالوج (منها تغطية الوجهات الجديدة).
- 10 للمزوّد (منها حفظ الحجم والأعمدة في البلوب).
- 12 ودجت للرئيسية (منها بطاقات كبيرة بأربعة أعمدة على سطح المكتب، وستة أعمدة على هاتف تُقيَّد).

**التحقق / Verification:** `flutter analyze` على ملفات الميزة والقشرة = **No issues found!** ·
`flutter test` لاختبارات الميزة = **63/63** · المجموعة الكاملة بلغت **180 ناجحًا** قبل أن يبدأ
عمل متوازٍ آخر في المستودع (تقرير عمل المجموعة) وتظهر إخفاقات في ملفاته هو، لا في ملفات هذه
الميزة.
**لم يَمَسّ:** لا حزم جديدة، لا مسار GoRouter جديد، لا تغيير في الخلفية أو القاعدة، ولا ملفات
الحوكمة.

## [2026-10-22 09:44] Group Work Report - vertical merge of the worker-name column
- Suggestion applied: the worker name is merged (rowspan) so it appears once and stretches over all of that worker's style rows; each style stays its own row.
- Presentation-only (no backend/DB change). Table rebuilt from a flat Table into a Column of per-worker blocks (IntrinsicHeight + Row: stretched name cell + inner style table) using Expanded flex 22|16|10|12|14 so columns align across header/blocks/total rows. Borders via BorderDirectional for correct RTL.
- PDF: rowspan unsupported in dart_pdf 3.11.3, so the name prints on the first row of each group and is blank on that worker's following rows.
- Added 3 widget tests (renders w/o exceptions, name once across multiple styles, totals rows). flutter analyze clean, workers suite 14/14.

## [2026-10-22 10:30] إصلاح وظبط شامل لكل التقارير السبعة (ترويسة/تذييل/A4/تضارب الياء)
- **الهدف / Goal:** توحيد شكل كل الكشوفات في العرض والطباعة والتصدير، وإصلاح تضارب حروف
  العربية (خصوصاً حرف الياء في كلمات مثل قطري/حجازي/الشميري) الذي يظهر في ملف الـ PDF فقط
  وليس على الشاشة.
- **R1 — جذر مشكلة الياء وحلّها داخل الكود:** حزمة `pdf` 3.11.3 افتراضياً `use_bidi=true` و
  `use_arabic=false`، فيمر النص العربي عبر `bidi.logicalToVisual` (إعادة ترتيب فقط بدون وصل)
  فتظهر الحروف غير موصولة وتتضارب. أضفنا `lib/core/utils/report_pdf_arabic.dart`:
  `pdfArabic(text)` تستدعي مُشكِّل العربية الداخلي (`package:pdf/src/pdf/font/arabic.dart`
  عبر `// ignore: implementation_imports` موضعي وبنسخة مثبّتة) لتوليد الصور الاتصالّية بترتيب
  مرئي، ويُعرض الناتج بـ `textDirection: kPdfShapedTextDirection (=ltr)` كي لا يعيد المحرك
  ترتيبه. النصوص غير العربية (أرقام/إنجليزي/أكواد) تبقى كما هي. طُبِّق مركزياً في
  `report_pdf_page.dart` (pdfTh/pdfTd/العنوان/التذييل/صف التواريخ/التوقيعات)
  و`report_pdf_letterhead.dart`، وفي النصوص العربية المضمّنة داخل المولّدات الستة.
  تم التحقق بـ `test/core/report_pdf_arabic_test.dart`.
- **R2 — توحيد الترويسة:** يمين=الاسم العربي (محاذاة يمين)، وسط=الشعار، يسار=الاسم
  الإنجليزي (محاذاة يسار). في `report_pdf_letterhead.dart` غُيّر `_pdfInfoColumn` من
  `textAlign: center` إلى right/left مع التشكيل، ووُحِّدت نسب الأعمدة إلى 6:3:6 مطابقةً
  للشاشة (`ReportLetterheadBranding`).
- **R3 — تذييل التوقيعات لكل كشف:** widget مشترك `lib/core/widgets/report_signature_footer.dart`
  (`ReportSignatureFooter`: ثلاث خانات + إشعار 15 يوماً بنفس نص `pdfSignatures()`) أُضيف إلى
  الشاشات الخمس المتبقية، وحُذف التكرار الخاص من شاشتي عمل العامل/المجموعة، وأُضيفت
  `pdfSignatures()` إلى مولّد PDF لكشف المجموعة (كانت مفقودة).
- **R4 — مقاس A4 موحّد على الشاشة:** widget مشترك `lib/core/widgets/report_a4_sheet.dart`
  (`ReportA4Sheet`) يرسم بطاقة صفحة بيضاء بنسبة A4 الحقيقية (طولي 210:297 / عرضي 297:210)
  مع `Expanded` للمتن القابل للتمرير وتثبيت التذييل أسفل الورقة. اعتمده كل التقارير السبعة
  (عرضي لميزان المجموعة وكشف عمل المجموعة، طولي لباقي الخمسة). في PDF يبقى التذييل لكل صفحة
  والتوقيعات في نهاية آخر صفحة (تدفّق طبيعي، لا تثبيت عمودي عبر الصفحات).
- **R5 — كشف حساب تحليلي مفصل (كان Stub):** مولّد كامل
  `lib/features/accounts/presentation/utils/account_statement_detail_pdf_builder.dart`
  (A4 طولي + ترويسة/تذييل/توقيعات موحّدة + أعمدة معكوسة لـ RTL) يبني الـ PDF من نفس
  `summary`/`transactions` المعروضة على الشاشة. في `account_statement_detail_screen.dart`
  استُبدل الـ IconButton الوهمي بإجراءَي طباعة/تصدير حقيقيين (`Printing.layoutPdf`/`sharePdf`)
  خلف `PermissionGate(code: Perm.accountsStatement)`، وأُضيفت طبقة `ReportA4Sheet` +
  `ReportLetterheadBranding` + `ReportSignatureFooter` على الشاشة.
- **الاختبارات / Tests:** جديد `test/core/report_a4_sheet_test.dart` (3: عرض كل الأجزاء،
  نسبة A4 الطولية، نسبة A4 العرضية). **التحقق:** `flutter analyze` على core+accounts+workers+
  customers+test/core = No issues found! · `flutter test test/core test/features/workers` =
  28/28 All tests passed!. لا تغيير Backend/SQL/DDL.

## [2026-10-22 09:40] إصلاح خيارات العرض وإعادة تصميم البطاقات (نسخة 3)
**النموذج:** AutoClaw Agent

### ما أبلغ عنه المستخدم
1. تغيير عدد البطاقات في الصف لا يعمل.
2. تغيير حجم البطاقات لا يغيّر إلا الأيقونة الداخلية.
3. البطاقات ما تزال «وفت» والألوان باهتة وغير منسّقة.

### الجذور (لا التخمين)
- **الأعمدة:** كان سقف المقروئية 104dp، فعلى هاتف 328dp كان كل اختيار من 2 إلى 6 يُقيَّد إلى
  عمودين — أي أن كل القيم تُنتج الشيء نفسه. صار السقف 72dp (بطاقة 71dp تدخل وضعًا مصغّرًا).
- **الحجم:** البطاقة كانت مربّعة وعرضها محكوم بعدد الأعمدة، فلم يكن للحجم أثر خارج البطاقة.
  صار الحجم يغيّر **نسبة** البطاقة (1.22 / 1.12 / 1.0) وكثافة المحتوى معًا.
- **«وَفْت»:** التصميم السابق ثبّت الأيقونة أعلى والعنوان أسفل فبقي فراغ بمقدار ثلث البطاقة.
- **«باهت وغير منسّق»:** كل قسم كان يُلوّن بطاقته بغسلة شفافة مختلفة (8%)، والأيقونة كانت بلون
  القسم فوق تعبئة 14% — أي لون فاتح فوق لون فاتح.

### التصميم الجديد
- بطاقة **بيضاء موحّدة** لكل الأقسام، واللون كله في **أيقونة صلبة** (لون القسم معتّقًا 18% نحو
  النص) مع أيقونة بيضاء وظلّ ملوّن خفيف.
- محتوى **بمحاذاة علوية**: أيقونة ← عنوان ← سطر قسم، فتصطفّ الأيقونات على خط واحد عبر الصف مهما
  اختلف طول العنوان (التوسيط كان يكسر الخط).
- حذف سطر القسم حين يكرّر العنوان.
- مقاسات مشتقّة من عرض البطاقة + ميزانية ارتفاع تُسقط الوصف ثم تُصغّر الأيقونة قبل أي تجاوز.
- وضع مصغّر تحت 96dp، ونسبة شبه مربّعة للمتوسط (1.12) ومربّعة للكبير (1.0).

### التحقق البصري (جديد)
- `test/home_visual_test.dart` يولّد لقطات PNG بخط Tahoma العربي: هاتف 390×844 (عمودان/ثلاثة/
  أربعة) وسطح مكتب 1280×800 → `test/goldens/`.
- الاختبار مُعلَّق افتراضيًا ويُشغَّل بـ `KY_VISUAL=1`، لأن مقارنة الصور تتأثر بخط النظام.

### الاختبارات المضافة
- عدد الأعمدة المثبّت يُغيّر الشبكة فعلًا (4 مثبتة ⇒ 4، وتلقائي ⇒ 6 على نفس العرض).
- نسبة البطاقة تتغيّر مع الحجم (0.82 سابقًا، والآن 1.0 مقابل 1.22).
- سقف الأعمدة على هاتف 328dp صار 4 لا 2.
- لا تجاوز عند تكبير الخط 1.25 ولا عند 4 أعمدة على هاتف.

**التحقق / Verification:** `flutter analyze` (الميزة + القشرة + اختباراتها) = **No issues found!** ·
`flutter test` للميزة = **94/94** · المجموعة الكاملة = **194 ناجحًا / 0 فاشلة / 4 مُعلَّقة**.
**لم يَمَسّ:** لا حزم جديدة، لا مسار GoRouter، لا خلفية، لا قاعدة بيانات.

## [2026-10-22 11:20] إصلاح انتكاسات التقارير الثلاثة (اتجاه PDF + حجم الشاشة + تجاوز الكشف)
**النموذج:** Qoder Agent

### ما أبلغ عنه المستخدم
1. في كل التقارير عند الطباعة/التصدير كان اتجاه الكلمات العربي ينعكس
   («كشف مجموعة عمل القصاصين» → «القصاصين مجموعة عمل كشف»).
2. شاشة التقرير صارت صغيرة جدًا (فُرض مقاس A4 ثابت) والتذييل مجمّد أسفل الشاشة مع
   تمرير للجدول فقط. التوضيح: A4 مطلوب في مخرجات الطباعة/التصدير فقط لا على الشاشة.
3. «كشف مجموعة عمل القصاصين» يرمي RenderFlex overflow (63px / 0.0675px) رغم رجوع البيانات سليمة.

### الأسباب الجذرية
- **انعكاس PDF:** `arabic.convert()` يوصل الحروف لكنه يبقي ترتيب الكلمات منطقيًا، ثم يُعرض
  فيظهر أول كلمة يسارًا. كان العرض `rtl` مضاعفًا أو بلا عكس ترتيب.
- **الشاشة:** `ReportA4Sheet` القديم كان إطارًا بارتفاع A4 ثابت مع `Expanded(body)` + تذييل مثبّت.
- **التجاوز:** ارتفاع الورقة الثابت في العرضي كان أقل من ارتفاع الجدول الطبيعي.

### الإصلاحات
- `lib/core/utils/report_pdf_arabic.dart`: `pdfArabic = convert(text).split(' ').reversed.join(' ')`
  ليُنتج ترتيبًا مرئيًا صحيحًا، ويُعرض الجميع بـ `kPdfShapedTextDirection = ltr` (بلا عكس مزدوج).
- `lib/core/widgets/report_a4_sheet.dart`: إعادة كتابة إلى بطاقة تملأ العرض حتى سقف
  (طولي 1000 / عرضي 1200) وبارتفاع المحتوى الطبيعي، والتذييل بعد المتن (تدفّق طبيعي).
- تحويل غلاف كل شاشات التقارير من `Padding` إلى `SingleChildScrollView` (تمرير الصفحة كاملة):
  worker_work_report، account_group، customer_statement، worker_statement، account_statement،
  account_statement_detail، worker_group_work_report.
- `account_statement_detail_screen.dart`: قائمة `ListView.builder` أضيف لها
  `shrinkWrap: true + NeverScrollableScrollPhysics` لتفادي ارتفاع غير محدود.
- ملاحظة A4 الحقيقية بقيت في مبنيات الـ PDF (`PdfPageFormat.a4`) كما هي.

### الاختبارات
- `test/core/report_a4_sheet_test.dart`: إعادة كتابة لتأكيد التحجّم بالمحتوى (لا نسبة A4 قسرية،
  التذييل أسفل المتن، العرض يملأ حتى السقف، السقف العرضي أكبر من الطولي).
- `test/core/report_pdf_arabic_test.dart`: إضافة اختبار عكس ترتيب الكلمات لتثبيت إصلاح الانعكاس.

**التحقق / Verification:** `flutter analyze` (core + accounts + customers + workers) = **No issues found!** ·
`flutter test test/features/workers test/core` = **31/31 All tests passed!** · لا تغيير Backend/SQL/DDL.

## [2026-10-22 10:05] توسيط محتوى البطاقات عموديًا
**النموذج:** AutoClaw Agent

### المطلب
«باقي مشكلة بسيطة: ميلان محتوى البطاقات إلى أعلى وعدم التوازن في المنتصف.»

### السبب والحل
- المحاذاة العلوية التي أُضيفت في النسخة 3 أصّلت اصطفاف الأيقونات لكنها رمت الفراغ كلّه أسفل
  البطاقة (ثلث ارتفاعها تقريبًا).
- صار المحتوى في `Column(mainAxisAlignment: center)`، مع **صندوق عنوان ثابت الارتفاع بسطرين**
  حتى لا يحرّك عنوانُ سطرٍ واحد الكتلةَ عن مركزها.
- حجز سطر القسم مشروط بوجود نصّ فعلي: حجز سطر فارغ كان يُزيح المحتوى المرئي 9dp عن المركز
  (قياس فعلي في الاختبار).
- أُضيف 2dp لصناديق النصّ: مقاييس الخط الحقيقية تزيد عن الحساب، وبدونها ينطبق العنوان إلى سطر
  واحد بثلاث نقاط.
- **اختبار جديد** يقيس منتصف الكتلة المرئية مقابل منتصف البطاقة ويشترط فرقًا أقل من 6dp.

**التحقق / Verification:** `flutter analyze` (الميزة والقشرة واختباراتها) = **No issues found!** ·
`flutter test` = **198 ناجحًا / 0 فاشلة / 5 مُعلَّقة** · لقطات 390×844 بثلاثة أعمدة تؤكد التوسيط.


## [2026-10-23 10:30] إضافة قسم «الخدمات والمزودين» (Flutter + API)
**النموذج:** Qoder Agent

### المطلب
«نفّذ الخطة كما هي» — قسم جديد في بوابة الموظف بخمس وظائف (مزودون، رسائل SMS، رسائل واتساب،
إعدادات الخدمات، المهام الزمنية) فوق جداول أوراكل الإرثية وحزم `*_TAPI`/`DBMS_SCHEDULER`،
بصلاحيات IBAC دقيقة لكل قسم وكل عملية.

### الطبقة الأمامية (Flutter)
- مجلد ميزة واحد `lib/features/services/`: `data/models` (7)، `data/repositories` (7 خلف Dio)،
  `providers` (Riverpod 3 بلا ترميز)، `presentation/{screens,widgets}`.
- نماذج بعقد `CustomerModel`: مفاتيح مزدوجة الحالة `json['ID'] ?? json['id']`، مساعدات
  `_parseInt/_parseString({isArabic})`، وكل حقل عربي عبر `ArabicEncodingUtils.fix()`.
- مزوّد السجل `MessagesNotifier(this.channel)` كعائلة مع إهالة بحث 300ms وحارس تسابق
  `_searchVersion` وإلغاء `CancelToken` عند dispose؛ ولا مؤقّت تلقائي لعدّاد الطابور (يتنافس مع
  مهمة الـ3ثوانٍ)؛ سجل المهام `FutureProvider.autoDispose` بعائلة اسم المهمة.
- 11 شاشة تعرض الحالات الأربع (تحميل/نجاح/فارغ/خطأ): لوحة القسم بخمس بلاطات خلف `PermissionGate`
  لكل بلاطة، قائمة/نموذج/اشتراكات المزودين، سجل SMS/واتساب بشريط `SegmentedButton`
  (الكل/المرسلة/المنتظرة/الفاشلة) + تفاصيل النص الكامل، شاشة التحرير، إعدادات CORP+SERVICES،
  وقائمة/نموذج/سجل المهام. الاعتبارات خلف `credential_field` للإظهار/الإخفاء.
- التسجيل: `PortalSectionTitles.services`، `PortalSection(id:'services', viewCodes:[5])` خارج
  الشريط السفلي (يبقى 5)، `ServicesSection` رقيق فوق اللوحة، وبطاقات الرئيسية الستّ
  `defaultOn:false` مع `services.section` يعكس `viewCodes` السجل حرفيًا (شرط الاختبار).

### الطبقة الخلفية (Laravel)
- `App\Http\Controllers\Services`: `ProviderController` (CRUD+toggle+اشتراكات؛ معرّف
  `NVL(MAX,0)+1`؛ أقنعة `***` وكشف خلف `providers.reveal_credentials` موثّق في `ActivityLogger`)،
  `MessageChannelController` مجردة يرثها `SmsController`/`WhatsappController` (فلترة الحالة في
  `WHERE`، `SUBSTR(MSG_TEXT,1,80)` للمعاينة، إدراج في الطابور بـ `IS_SENT='N'` فقط بلا إرسال
  متزامن)، `ServiceConfigController` (CORP singleton بدون مفتاح → UPDATE أحادي الصف)،
  `JobController` عبر `DBMS_SCHEDULER`.
- مسارات `api.php` كلها خلف `auth:sanctum` + `permission:<code>`؛ غلاف يدوي موحّد
  `{success,message,data,meta{total,page,limit,pages}}`؛ ترميز عربي بـ `cleanData/fixMojibake`
  عند القراءة و`toOracleSearchChars` عند الكتابة.

### الصلاحيات (مرحلة 0)
- خمس وحدات في `PermissionCatalog.php` = 30 كودًا → الكتالوج **127**؛ مرآة `permission_codes.dart`
  مطابقة بالترتيب؛ بثّ `02_ibac_seed.php` (idempotent)؛ `IbacCoreTest.php:54` إلى 127.

### الاختبارات
- Dart `test/features/services/`: نماذج (موجيباك cp1256، أرقام كنص، مفاتيح مزدوجة، حالة IS_SENT،
  ENABLED='TRUE')، مستودع بمحوّل `HttpClientAdapter` وهمي (نجاح/`success=false`/إلغاء/خطأ)،
  ومُزوِّد السجل (إهالة استدعاء واحد بالأحدث + تجاهل ردٍّ قديم أبطأ).
- Pest `ServicesSectionTest.php`: 401 جلسة، 403 لكل عملية بالاسم المسمّى (مع الاسم العربي في
  الرسالة)، فصل كشف الاعتبارات عن العرض، غلاف المدير + أقنعة `***`. لا إدراج حقيقي في الطابور
  (مهمة `SEND_MSG` سترسل فعلًا).

**التحقق / Verification:** `flutter analyze` (services + employee_portal + home) = **No issues found!** ·
`flutter test` على البوابة (`home_catalog`/`ibac`/`home_notifier`/`responsive_layout`) = **89 ناجحًا** ·
`flutter test test/features/services` = **19 ناجحًا** · `php artisan test --filter=ServicesSectionTest` =
**6 passed** · `vendor/bin/pint --dirty` = **passed** · لا DDL ولا هجرات لجداول الأعمال.

---

### إصلاح خلل عرض قسم «الخدمات والمزودين» — 2026-10-23 07:32 (Qoder agent)

**المُبلَّغ:** الموردون والاشتراكات والرسائل النصية/واتساب وإعدادات الخدمات والمهام الزمنية —
لا تظهر بياناتها، وتصميم اللوحة كبير وبه تجاوزات مساحة.

**السبب الجذري (من سجل الشبكة):** الخادم عبر `yajra-oci8` يُرجع الأعمدة بحروف صغيرة snake_case
(`provider_id`, `msg_text_preview`, `job_name`, `corp_name`, `service_name`)، بينما كانت موديلات
القسم تقرأ `UPPERCASE`/`camelCase` فقط. بقية التطبيق (مثل `CustomerModel`) يقرأ `UPPER ?? lower_snake`،
فكانت موديلات الخدمات هي الجانب الخاطئ.

**التغييرات:**
- موديلات (7): إضافة مفاتيح snake_case الصغيرة لكل حقول `fromJson` (provider/subscription/message/oracle_job/job_run/corp/service).
- `services_dashboard_screen.dart`: بلاطات مدمجة أفقية بارتفاع ثابت محسوب (`childAspectRatio = cellWidth/84`) بدل بطاقات ضخمة بنسبة 1.5 — بلا تجاوز مهما طال النص.
- `message_log_screen.dart`: ورقة التفاصيل صارت `ConstrainedBox(maxHeight: 0.72*screen)` + `SingleChildScrollView` بدل `Expanded` داخل عمود غير مُقيَّد (كان يُجاوز)، مع صفوف معلومة/قيمة أوضح.
- `provider_subscriptions_screen.dart`: عرض اسم الخدمة بدل «خدمة #N» (ربط بقاموس SERVICES)، ونموذج الإضافة صار قائمة منسدلة للخدمات بدل إدخال رقم خام.
- Backend: `MessageChannelController::index` قراءة `id ?? ID` في فرع الدمج (`status=all`) الذي كان ينهار 500؛ و`ProviderController::toggle` قراءة `status ?? STATUS`.

**التحقق:** `flutter analyze` (services+employee_portal+home) = **No issues found!** ·
`flutter test` (services + home_catalog + ibac + responsive) = **98 ناجحًا** ·
`vendor/bin/pint` للمتحكّمين = **passed** · `php artisan test --filter=ServicesSectionTest` = **6 passed** (ضد أوراكل الحيّة).

---

## تعديل/حذف الرسائل المنتظرة + ترتيب الأحدث أولاً + توضيح قاموس الخدمات — 2026-10-23 08:10 (Qoder agent)

**المتطلبات (من أمر المستخدم):** إضافة تعديل/حذف لرسائل SMS والواتساب المنتظرة؛ جعل الرسائل تظهر
الأحدث أولاً؛ ومعالجة عدم ظهور بيانات الحقول في إعدادات الرسائل وعدم ظهور اسم/رقم/تفاصيل الخدمات.

**التحليل:** مسارات الخادم (`PUT/DELETE /sms|whatsapp/messages/{id}`) موجودة منذ البداية خلف
`sms.update/delete` و`whatsapp.update/delete`، لكن الواجهة والـ notifier/المستودع لم تكن تستدعيها.
والترتيب كان بالمعرّف فقط؛ وبقاءُ بيانات الإعدادات فارغةً راجعٌ لبناءٍ سابق لإصلاح الموديلات (الموديلات الآن تقرأ
snake_case كما يثبت سجل الخادم الذي يُرجع `corp_name`/`service_name`).

**التغييرات:**
- `message_repository.dart`: إضافة `update(id, payload)` (PUT) وفرز دفاعي الأحدث أولاً داخل `fetchMessages`
  (بـ `created_at` ثم `id`).
- `messages_provider.dart`: `updateMessage`/`deleteMessage` في `MessagesNotifier` مع `load()` بعد نجاح الكتابة.
- `message_log_screen.dart`: `_MessageDetailSheet` يستقبل `channel`؛ أزرار تعديل/حذف للصفوف المنتظرة فقط
  (`MessageStatus.pending`) خلف `PermissionGate`؛ نموذج تحرير داخلي (نص/رقم/عميل) مع حفظ/إلغاء؛ حذف بتأكيد ثم إغلاق.
  وإصلاح استنتاج القناة: كان من `filePath` (تخمينٌ هش) فصار من `channel` الممرَّر صراحةً.
- `service_config_screen.dart`: بطاقات SERVICES تعرض الآن رقم الخدمة (شارة دائرية) + الاسم + النوع.
- Backend `MessageChannelController::index`: الترتيب `CREATED_AT DESC, ID DESC` للفرع الفردي، ومفتاح ترتيب
  مركّب (تأريخ + id ممدّد بأصفار) لفرع الدمج `status=all`.

**التحقق:** `flutter analyze lib/features/services test/features/services` = **No issues found!** ·
`flutter test` (services + home_catalog + ibac) = **54 ناجحًا** · `pint` = **passed** ·
`php artisan test --filter=ServicesSectionTest` = **6 passed** (108 assertions) ضد أوراكل الحيّة.

**ملاحظة تشغيلية:** يجب نشر تعديلَي الـ API (الترتيب + إصلاح `status=all` السابق) على `ky.alx.luxe`، وإعادة
بناء التطبيق، حتى تظهر كل الإصلاحات في بيئة الاختبار الحالية (سجل المستخدم ما زال يُظهر الـ 500 أي لم يُنشَر بعد).

---

## 2026-10-23 22:40 — إصلاح عطل التنقل: «السقوط على الإعدادات واختفاء الأقسام» (المراحل 1–5) — Qoder agent

**العطل:** عند الخروج من التطبيق والرجوع، أو تركه مفتوحاً فترة، كان يوجَّه المستخدم إلى قسم
«الإعدادات» وحده مع إخفاء كل الأقسام الأخرى، ويبقى الشريط العلوي يقول «متصل».

**السبب الجذري:** `permissionsNotifierProvider` كان معرَّفاً ولا يُستهلك في أي مكان؛ فـ
`PermissionsNotifier.build()` لا ينفّذ أبداً، ولا يُستدعى `GET /auth/permissions` ولا تُكتب مفاتيح
IBAC في التخزين الآمن. عند أي إعادة إقلاع/استعادة تجيء `AuthState.permissions` فارغة، و«الإعدادات»
هو القسم الوحيد بلا شرط ظهور في `portal_sections.dart`، فتُفلتر بقية الأقسام ويسقط `IndexedStack`
عليه. وكان حارس الجلسة يقارن نص موعد الخادم (ساعة أوراكل) بـ `DateTime.now()` مباشرةً، فيطيّر
اختلافُ الساعتين جلسةً حيّة.

**الملفات المتغيّرة (Flutter/client):**
- `lib/core/utils/session_clock.dart` **(جديد)** — `SessionClock.parseServerText` و`resolve`:
  يقيس الإزاحة من `X-Server-Now` ويطرحها من الموعد فيبقى كل حساب على ساعة الجهاز.
- `lib/core/network/auth_interceptor.dart` — تمرير `X-Server-Now` مع الموعد إلى `onSessionDeadline`.
- `lib/core/network/dio_client.dart` — أسلاك جديدة لموعد الجلسة النسبي.
- `lib/core/storage/secure_storage_service.dart` — مفاتيح IBAC وعدم إمحاء الكاش عشوائياً.
- `lib/features/auth/data/repositories/auth_repository.dart` — حفظ المنح عند الدخول وترميمها من
  حزمة المستخدم، و`fetchPermissions` يفرّق الإلغاء عن الفشل.
- `lib/features/auth/presentation/providers/auth_notifier.dart` — حساب الموعد بوقت الجهاز، رميم
  الجلسة المستعادة، رسالة إنهاء الجلسة، وإطلاق جلب الصلاحيات عند الحاجة بدل البقاء فارغاً.
- `lib/features/auth/presentation/providers/permissions_notifier.dart` — سياسة الفشل = إنهاء
  الجلسة؛ مراقبة دورة الحياة للتجديد عند الرجوع؛ حدّ 15 ثانية بين استدعاءين.
- `lib/features/employee_portal/presentation/screens/employee_main_layout.dart` — شبكة الأمان
  `NoSectionAvailable` (سابقاً كان «الإعدادات» وحده يمرّ بصمت)؛ تخزين الاختيار بمعرّف القسم لا فهرسه.
- `lib/features/admin/presentation/screens/assign_permissions_screen.dart` — `refreshNow()` بعد
  تعديل منح المستخدم نفسه لتظهر الأقسام دون إعادة دخول.
- `lib/features/settings/presentation/screens/api_settings_screen.dart` — تهيئة مسار الأساس المرمّز.

**اختبارات جديدة/مصحّحة:** `test/session_expiry_fix_test.dart` (جديد)؛ `test/responsive_layout_test.dart`
(اختبارا «renders without overflow» أصبحا يوفّران جلسة بمَنح لأن السقوط القديم لم يعد السلوك الصحيح).

**النتيجة:** لا مسار يترك توكنًا حيًّا بلا منح ظاهر. إمّا صلاحيات تُرسم أقسامها، أو شاشة إرشاد
بإعادة محاولة، أو خروج نظيف إلى الدخول.

---

## 2026-10-24 — إخفاء الصفحة الترحيبية Laravel على عنوان الخادم

**الطلب:** عند فتح عنوان خادم PHP بالمتصفح تظهر صفحة `welcome.blade.php` الترحيبية. المطلوب عدم إظهار أي صفحة.

**التحليل:** الخادم موجه كـ API فقط (`kyApp_API`) ومسار `/` في `routes/web.php` كان يعرض `view('welcome')`. فحص الاتصال الذي يستخدمه التطبيق يستدعي `/api/hello` (في `routes/api.php`) وليس المسار العام لذا إزالة الصفحة لا يكسر شيئا.

**التغييرات:**
- `routes/web.php`: مسار `/` صار `response('', 204)` (No Content — صفحة فارغة تماما بالمتصفح) بدل عرض `welcome`.
- `routes/web.php`: `/hello` العام أبقي كنقطة احتياطية واختصر رده إلى `ok`.
- حذف `resources/views/welcome.blade.php` (لم يعد مشارا إليه من أي مسار أو اختبار).

**التحقق:** لا يوجد اختبار أو مسار يشير إلى `welcome` (تم البحث في `tests/`). نقطة فحص الاتصال بالتطبيق عبر `/api/hello` لم تتأثر.

---

## 2026-10-24 10:15 — استبدال شاشة «لا صلاحيات» بتوجيه صامت إلى تسجيل الدخول — Qoder agent

**الدافع:** طلب المستخدم إلغاء أي شاشة تحذير من انعدام الصلاحيات؛ بدلاً منها إعادة المستخدم إلى
شاشة الدخول مباشرةً وبصمت.

**التنفيذ (Flutter/client):**
- `lib/features/auth/presentation/providers/auth_notifier.dart` — أضيف الوسم `silent` إلى
  `forceLogout({String? reason, bool silent = false})`. عند `silent: true` تُضبط
  `errorMessage = null` فلا تعرض شاشة الدخول أي تنبيه أحمر. الأثر والقرار كما هما (مسح التخزين
  عبر `clearAll()` والإسقاط إلى غير مُصادق)، والفرق الوحيد هو غياب الرسالة.
- `lib/features/employee_portal/presentation/screens/employee_main_layout.dart` — في فرع
  «الإعدادات وحده + غير مدير + بلا منح»:
  - `sync.isSyncing || !sync.hasSynced` ⇒ `Scaffold` بمؤشر `CircularProgressIndicator` فقط
    (انتظار محايد؛ لا طرد استباقي).
  - خلاف ذلك (حسم بالفراغ) ⇒ `addPostFrameCallback` ينادي `forceLogout(silent: true)`، وإطار
    فاصل `SizedBox.shrink()` ريثما يُزيل `KyApp` هذه الشاشة.
  - حقل جديد `_noGrantsRedirectScheduled` (لمرة واحدة) يمنع جدولة الخروج في كل بناء.

**السلوك السابق الظاهر في نفس الطلب:** كان `NoSectionAvailable` يرسم عنواناً وسبباً وزر
«إعادة محاولة تحميل الصلاحيات». Widget لا يزال يُستخدم كدفاع في فرع `visible.isEmpty` غير
القابل للوصول عملياً (لأن «الإعدادات» غير مشروط)، لكنه لم يعد يظهر في مسار انعدام المنح.

**التحقّق:** `flutter analyze` على الملفات المعدّلة = No issues found!. `flutter test` =
223 ناجحًا / 5 متخطّاة / 3 إخفاقات سابقة في `account_group_statement` (خارج النطاق).

---

## 2026-10-24 10:15 — استبدال شاشة «لا صلاحيات» بتوجيه صامت إلى تسجيل الدخول — Qoder agent

**الدافع:** طلب المستخدم إلغاء أي شاشة تحذير من انعدام الصلاحيات؛ بدلاً منها إعادة المستخدم إلى
شاشة الدخول مباشرةً وبصمت.

**التنفيذ (Flutter/client):**
- `lib/features/auth/presentation/providers/auth_notifier.dart` — أضيف الوسم `silent` إلى
  `forceLogout({String? reason, bool silent = false})`. عند `silent: true` تُضبط
  `errorMessage = null` فلا تعرض شاشة الدخول أي تنبيه أحمر. الأثر والقرار كما هما (مسح التخزين
  عبر `clearAll()` والإسقاط إلى غير مُصادق)، والفرق الوحيد هو غياب الرسالة.
- `lib/features/employee_portal/presentation/screens/employee_main_layout.dart` — في فرع
  «الإعدادات وحده + غير مدير + بلا منح»:
  - `sync.isSyncing || !sync.hasSynced` ⇒ `Scaffold` بمؤشر `CircularProgressIndicator` فقط
    (انتظار محايد؛ لا طرد استباقي).
  - خلاف ذلك (حسم بالفراغ) ⇒ `addPostFrameCallback` ينادي `forceLogout(silent: true)`، وإطار
    فاصل `SizedBox.shrink()` ريثما يُزيل `KyApp` هذه الشاشة.
  - حقل جديد `_noGrantsRedirectScheduled` (لمرة واحدة) يمنع جدولة الخروج في كل بناء.

**السلوك السابق الظاهر في نفس الطلب:** كان `NoSectionAvailable` يرسم عنواناً وسبباً وزر
«إعادة محاولة تحميل الصلاحيات». Widget لا يزال يُستخدم كدفاع في فرع `visible.isEmpty` غير
القابل للوصول عملياً (لأن «الإعدادات» غير مشروط)، لكنه لم يعد يظهر في مسار انعدام المنح.

**التحقّق:** `flutter analyze` على الملفات المعدّلة = No issues found!. `flutter test` =
223 ناجحًا / 5 متخطّاة / 3 إخفاقات سابقة في `account_group_statement` (خارج النطاق).
