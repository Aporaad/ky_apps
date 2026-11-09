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


## [2026-10-24 01:55] الإصدار الأول (v1.0.0) بصيغة APK موقع وجاهز للنشر · Qoder Agent

**السياق:** كان البناء السابق لـ release يوقَّع بمفتاح debug افتراضياً، والمعرّف
`com.example.ky_apps` تجريبياً، وأذن `INTERNET` لا تظهر إلا في manifests التطوير — وهي
حواجز إطلاق `android/` الموثقة في `todo.md` سابقة. نُفِّذت كلها الآن بإملاء المستخدم
(المعرّف `com.alkaboudy.app` وكلمة سر المفتاح المختارة منه).

**ما أُنجِز:**

1. **مفتاح التوقيع الرقمي**
   - `android/ky_release.jks` — أنشئ بـ `keytool` (JDK 21): RSA-2048، alias `ky_apps`،
     صلاحية 10٬000 يوم (من 2026-10-24 حتى 2054-03-11)،
     DN: `CN=Al-Kaboodi Tailoring, OU=KY Apps, O=Al-Kaboodi, L=Sanaa, ST=Sanaa, C=YE`.
   - بصمة الشهادة SHA-256: `81:1E:47:7C:85:1A:BA:17:7B:65:04:F0:A5:7B:DA:C0:05:E6:40:00:12:A9:BE:47:6C:57:78:D6:DA:DA:5D:0F`.
   - `android/key.properties` يحمل البيانات الأربع؛ الملفان محجوبان عن git بنمط
     `android/.gitignore` الموجود (`key.properties`, `**/*.keystore`, `**/*.jks`).
2. **`android/app/build.gradle.kts`**
   - استيراد `java.util.Properties` + تحميل `rootProject.file("key.properties")` بشرط وجوده.
   - `namespace` و`applicationId` ⇒ `com.alkaboudy.app`.
   - `signingConfigs { create("release") { … } }` وربطه بـ buildType release مع تراجع إلى
     debug عند غياب الملف (لا يكسر أجهزة أخرى).
   - R8 مفعّل: `isMinifyEnabled = true` و`isShrinkResources = true` مع
     `proguard-android-optimize.txt` + `proguard-rules.pro`.
3. **`android/app/proguard-rules.pro`** (جديد) — keep لـ `io.flutter.**` و`MainActivity`،
   و`-dontwarn com.google.android.play.core.**` (إلزامي: مراجع Flutter embedding إلى
   Play Core بلا deferred components تُفشل R8 بدونه).
4. **نقل `MainActivity.kt`** من `kotlin/com/example/ky_apps/` إلى `kotlin/com/alkaboudy/app/`
   (نفس المحتوى `FlutterFragmentActivity` لدعم biometric، مع تعليق) وحذف الملف القديم —
   لأنه أصبح خارج نطاق namespace ولا يجمع معه.
5. **`android/app/src/main/AndroidManifest.xml`**
   - `<uses-permission android:name="android.permission.INTERNET"/>` في الرئيسي (كانت debug-only).
   - `android:usesCleartextTraffic="true"` مع تعليق ثنائي اللغة: عنوان API يُدخل ويُعدَّل
     وقت التشغيل (LAN IP/_port)، فقائمة النطاقات الثابتة غير عملية؛ التوصية بترحيل الخادم
     إلى HTTPS لاحقاً (جرّبنا شبكة xml allowlist ثم أُهملت لنفس السبب).
6. **`.gitignore` الجذر** — استثناء `release_artifacts/` (ثنائيات كبيرة).

**البناء والناتج** (`flutter build apk --release --split-per-abi` ثم universal):

| الملف | الحجم |
|---|---|
| `alkaboodi-v1.0.0-arm64-v8a.apk` | 31.8MB |
| `alkaboodi-v1.0.0-armeabi-v7a.apk` | 29.9MB |
| `alkaboodi-v1.0.0-x86_64.apk` | 33.7MB |
| `alkaboodi-v1.0.0-universal.apk` | 87.2MB |
| `mapping-v1.0.0.txt` (R8، لفك التشويش) | 10.6MB |

في `release_artifacts/v1.0.0+1/`. Tree-shaking للأيقونات فعّال تلقائياً (−97.6%‏/−99.7%).

**التحقق:** `apksigner verify --print-certs` ⇒ signer DN هو شهادة Al-Kaboodi نفسها
وتطابق بصمة المفتاح (تحذيرات META-INF/*.version اعتيادية من AAR ولا تمس صحة التوقيع V2/V3)؛
`aapt2 dump badging` ⇒ `package name='com.alkaboudy.app' versionName='1.0.0' versionCode='2001'
sdkVersion 23 / targetSdk 35 / label الكبودي`. (versionCode=2001 هو اشتقاق flutter-tools القياسي
من `1.0.0+1` وليس خطأً.)

**البوابات:** `flutter analyze` = 3 تحذيرات سابقة لا جديدة · `flutter test` = 222 ناجحًا /
5 متخطّاة / 4 إخفاقات — 3 منها `account_group_statement` موثقة سابقاً، ورابع `api_config_test`
(يعكس أن API يخدم على `192.168.0.9` بينما الثابت `192.168.0.11`؛ بيئي بحت، لا ملفات Dart عُدلت).

**عقبان واقعيان استهلا إعادة بناء:** (أ) `minifyEnabled` غير موجودة في Kotlin DSL الحديث ⇒
`isMinifyEnabled`؛ (ب) R8 يتعثر بمراجع Play Core المفردة ⇒ `-dontwarn` أعلاه.

**ما يتعمَّدنا عدم فعله:** لا commit (لم يُطلب)؛ لا رفع للمتجر؛ لا تغيير كلمة سر/مفتاح بديل.
**تحذير أبدي:** ضياع `ky_release.jks` يعني استحالة إصدار تحديثات بنفس المعرّف — نسخة آمنة
خارج الجهاز إلزامية.


## [2026-10-24 02:12] إضافة دليل البناء والتوقيع والإصدارات (android_release_guide.md) · Qoder Agent

**الدافع:** بعد إنجاز أول إصدار APK موقع (v1.0.0) في نفس اليوم، طلب المستخدم توثيقاً
مفصّلاً وكاملاً لكيفية عمل البناء مع التوقيع بطريقة آمنة، وكيفية إصدار نسخ جديدة
وتحديث التطبيق — محفوظاً في ملف بالمشروع.

**ما أُنجز:** أُنشئ `android_release_guide.md` في جذر المشروع (~310 أسطر، عربية مع
مصطلحات إنجليزية) مقسّم خمسة أجزاء تشغيلية:

1. **التوقيع الرقمي — لماذا وكيف:** شرح مبسط للأصالة والسلامة، وأن هوية التطبيق =
   مفتاح + معرّف (ولماذا ضياع المفتاح قاتل للتحديثات). جدول المفردات المرتبط بمشروعنا
   فعلياً: `ky_release.jks`، alias `ky_apps`، RSA-2048/SHA384، DN الشركة، بصمة
   SHA-256 الكاملة، صلاحية حتى 2054، مخطّط V2. خريطة الملفات الثلاثة ومواضعها من git
   (المفتاح وkey.properties خارج git بنمطات `android/.gitignore`). شرح تدريجي لتدفق
   Gradle: قراءة key.properties (`build.gradle.kts:13-17`) ← R8 (isMinify/isShrink +
   قواعد proguard-rules.pro وسبب كل سطر فيها) ← التوقيع ← آلية fallback إلى debug عند
   غياب الملف (ولماذا لا تنكسر الأجهزة الأخرى). سبب المسار المطلق لـ storeFile.
   أوامر `apksigner verify --print-certs` و`aapt2 dump badging` الإلزامية وكيفية قراءة
   الخرج (بما فيه أن تحذيرات META-INF عادية).
2. **الترقيم:** مصدر واحد `version: X.Y.Z+N` في pubspec → versionName/versionCode،
   مع رصد حقيقي أن `1.0.0+1` أنتج versionCode=2001 (اشتقاق flutter-tools قياسي).
   جدول semver معتمد للمشروع + القاعدة الذهبية (+N يزيد دائماً ولا يتكرر). تجاوز
   `--build-name/--build-number`.
3. **إجراء إصدار نسخة جديدة:** pre-flight (البوابات + الإخفاقات المقبولة الموثقة) ←
   رفع الإصدار ← `--split-per-abi`/universal/appbundle ← تحقق إلزامي ← تثبيت فوق
   القديمة لاختبار بقاء البيانات ← أرشفة في `release_artifacts/vX/` مع mapping.txt ←
   توزيع مباشر (واتساب/فلاش/شبكة) وشرح «تعارض التوقيع» ← توثيق في الملفات الثلاثة.
4. **سيناريوهات حرجة:** ضياع المفتاح (لا استعادة؛ الحل إعادة توليد + حذف كل الأجهزة
   مع توضيح ما يضيع وما لا يضيع في Oracle + الوقاية بالنسخ الاحتياطي)، نسيان كلمة السر،
   رفض التثبيت (فحص عكسي مرتّب: versionCode ← بصمة ← معرّف ← معمارية)، نقل لجهاز/مسار
   جديد، النشر على Google Play وقرار Play App Signing، ومتى يتغير applicationId (لا).
5. **Quick Reference:** سكربت PowerShell كامل لإصدار من الصفر + 5 ثوابت تشغيلية.

**التزام أمني مقصود:** الدليل لا يذكر كلمة سر المفتاح في أي موضع — يحيل فقط إلى
`android/key.properties` المحلي ومدير كلمات السر، تماشياً مع قاعدة عدم تسجيل الأسرار
في أي ملف موثق.

**الأثر:** لا تعديل كود ولا بناء في هذه الجولة؛ ملف توثيق جديد فقط. لم يُنفَّذ commit
(لا طلب).


## [2026-10-24 14:30] توسيع IBAC: كشوف دقيقة + حجب أزرار + طيّ أقسام الصلاحيات · Qoder Agent

**الدافع:** خطة `تطوير_وتوسيع_نظام_الصلاحيات_IBAC` (مرفقة في المحادثة). ثلاث مشكلات
جوهرية: أكواد كشف عامة تسترهين تفاصيل المستخدم، قوائم المنتقي تنهار بـ 403 لأن
`/accounts/chart` محروس بـ `.view` وحده، وأزرار الشاشات تعرض لمن لا صلاحية له،
بالإضافة إلى ضعف التصفح في شاشتي عرض الصلاحيات عند وجود أقسام كثيرة.

**ما أُنجز — الخادم (kyApp_API):**
1. **`app/Support/PermissionCatalog.php`:** مصفوفة `MODULES` تُستبدل فيها أربعة
   أكواد عامة بتسعة دقيقة:
   - `accounts.statement` → `accounts.statement_financial` +
     `accounts.statement_group` + `accounts.statement_detail`.
   - `employees/cutters/tailors.statement` → `<w>.statement_financial` +
     `<w>.statement_work` لكل قسم.
   `humanize()` يعرف الأفعال الأربعة الجديدة. صافي العدد: −4 + 9 = +5؛ 127 → 132.
2. **`app/Http/Middleware/EnsurePermission.php`:** `handle($request, $next, string
   ...$codes)` + تقسيم الفاصلة + `PermissionResolver::canAny` — التوافق الرجعي
   مع كود واحد محفوظ؛ لا كسر لأي مسار حارسه كود واحد.
3. **`routes/api.php`:** إعادة توزيع الحراسة:
   - `/accounts/chart` ← `accounts.view,accounts.statement_financial`.
   - `/accounts/account|main|sub|sub-group|tree` ← أربع أكواد OR (view +
     structure_manage + statement_group + statement_detail).
   - `/accounts/chart/{accNo}/statement` ← `accounts.statement_financial`؛
     `/accounts/statement-detail` ← `statement_detail`؛ `/accounts/group-statement`
     ← `statement_group`.
   - `/workers/{emp|cut|tai}/{id}/statement` ← `<w>.statement_financial`؛
     `/workers/{cut|tai}/{id}/work-report` وgroup ← `<w>.statement_work`.
4. **`tests/Feature/IbacCoreTest.php`:** العدد المتوقع 127 → 132.
5. **`tests/Feature/BusinessRoutesSealedTest.php`:** العنصر الثالث في كل حالة
   يقبل قائمة أو نص؛ الحلقة تصير `$expected = is_array($code) ? $code : [$code]`.
   تحديث مسارات الكشوف إلى الأكواد الجديدة، والمسارات المتعددة إلى قوائم OR.
6. **Pint:** نظيف على كل الملفات الخمسة. **Pest:** اختبار تطابق الكتالوج (24
   assertion) واختبارا فحص المسارات نجحا؛ `BusinessRoutesSealedTest` الكامل
   يتطلب Oracle حيّ غير متاح هنا — Assertions مُحدّثة لتطابق شكل `errors.permission`
   الجديد (array للمسارات OR، string للمسارات أحادية الكود).

**ما أُنجز — Oracle (تسليم، بلا تنفيذ):**
- `database/oracle/06_ibac_statement_split.sql` — كتلة PL/SQL مجهولة: خريطة
  عام→قائمة دقيق، cursor على الأكواد العامة الأربعة، تكرار على منحها،
  INSERT لكل دقيق مقابل (مع فحص المكرر بـ `l_dup`)؛ ثم DELETE منح العامة
  وصفوف العامة من `APP_PERMISSIONS`؛ RAISE_APPLICATION_ERROR(-20011) إن كان
  دقيق مفقود (يذكّر بالتشغيل بعد البذر)؛ COMMIT في النهاية. لا literals عربية
  (سائق AL32UTF8 يسقطها في CP1256 غير مهيّأ).
- `database/oracle/07_ibac_statement_split_verify.sql` — خمسة تحققات: الأكواد
  العامة المتبقية=0، عرض التسعة الجديدة مع IS_ACTIVE، منح يتيمة=0، حاملو
  العامة غير مغطى=0 (عبر BAK_06)، عدد الأكواد الحيّ=132.
- `02_ibac_seed.php` لا تعديل — idempotent ومُغذّى من `PermissionCatalog::rows()`
  أصلاً، فالتشغيل اللاحق يُدرج التسعة تلقائياً.
- الترقيم 06/07 (لا 05/06): `05_app_settings_company_en.sql` موجود.

**ما أُنجز — العميل (lib/):**
1. **`core/constants/permission_codes.dart`:** حذف 4 constants عامة (`accountsStatement`،
   `employeesStatement`، `cuttersStatement`، `tailorsStatement`)؛ إضافة 9 دقيقة
   مع تعليقات ثنائية اللغة عن سبب التقسيم؛ تحديث `allPermissionCodes` بترتيب
   الكتالوج (wildcard → core → extras لكل قسم)؛ توسيع `permActionLabels` بأربع
   تسميات عربية جديدة. التعليقات المرجعية 127 → 132.
2. **حجب الأزرار — شاشات الحسابات:** `accounts_dashboard_screen.dart` تحوّل
   `_buildModernActionTile` من `Widget` إلى `Widget?` بمعامل `String? permission`؛
   كل بطاقة كشف (مالي/تحليلي/مجموعة) تحمل كودها؛ إضافة/تعديل/شجرة/عملات كذلك؛
   الشبكة `.whereType<Widget>().toList()`. `account_statement_detail_screen.dart`
   — الطباعة/التصدير كانا يستندان `Perm.accountsStatement` القديم؛ استُبدلا
   بـ `Perm.accountsPrint`/`Perm.accountsExport`. الشاشتان الأخريان للمجموعة
   والمالي كانتا محجوبتين أصلاً بشكل صحيح.
3. **حجب العاملين:** `worker_action_icons.dart` أُعيدت كتابته بالكامل من
   StatelessWidget إلى ConsumerWidget؛ قائمة `(String? code, Widget btn)` تُصفّى
   بـ `auth.can` ثم تُعاد لصقها بفواصل `SizedBox(width:4)` بعد التصفية (تجنّب
   فاصل زائد في الآخر). أكواد: `<apiPath>.statement_financial/statement_work/update/toggle/delete`.
   `workers_dashboard_screen.dart` تحوّل ConsumerWidget مع قائمة بطاقات مُرشّحة
   بـ collection-if (`.view` لكل فئة، و`canAny([cutters.statement_work,
   tailors.statement_work])` لبطاقة «كشف عمل مجموعة»)، ورأس القسم + الفواصل
   كلها مشروطة بـ `if (cards.isNotEmpty)`. `workers_list_screen.dart` — زر
   الإضافة مشروط بـ `ref.watch(authNotifierProvider.select((auth) =>
   auth.can('${workerType.apiPath}.create')))`. شاشتا كشف المالي和工作 للعاملين
   كانتا محفوظتين أصلاً.
4. **حجب العملاء:** `customers_dashboard_screen.dart` — StatelessWidget →
   ConsumerWidget مع `_buildActions(BuildContext, AuthState)`، كل بطاقة
   من الخمس (إضافة/تعديل/حذف/كشف/قائمة) خلف كودها. `all_customers_screen.dart`
   — الأزرار المضمّنة (كشف/تعديل) داخل صفوف القائمة لُفّت بـ `PermissionGate`.
   `customer_statement_screen.dart` كان محفوظاً أصلاً.
5. **`home_shortcut_catalog.dart`:** إعادة ربط الاختصارات —
   `accounts.statement`→`accountsStatementFinancial`،
   `accounts.group`→`accountsStatementGroup`،
   `accounts.analysis`→`accountsStatementDetail`،
   `workers.group_work`→`[cuttersStatementWork, tailorsStatementWork]`.
   معرفات الاختصارات (`id`) بقيت كما هي لئلا تنكسر سجلات المستخدم.
6. **طيّ المنتقي (`permission_module_group.dart` + `permissions_picker_widget.dart`):**
   أضيفت `expanded`/`onToggleCollapse`/`showCollapseToggle` إلى المجموعة؛ الرأس
   صار `InkWell` داخل صف يحمل سهم `expand_less`/`expand_more`؛ الجسم كله
   (QuickRow + wildcard + chips + ExtrasTile) داخل `if (expanded)`. الحالة
   `_collapsed: Set<String>` في `_PermissionsPickerWidgetState` مع
   `_toggleModule` و`_toggleAll`، وتمرير عبر `_Groups`. شريط الحالة أضاف زر
   «طي الكل/توسيع الكل» بجانب «مسح كل المحدد». أثناء البحث `expanded`
   يُفرض=true لأن مطابقة البحث خلف رأس مطوي تضرّ بالمراجع.
7. **طيّ الكتالوج (`permissions_catalog_screen.dart`):** نفس النمط في
   `_CatalogBodyState` مع `_collapsed`/`_toggleModule`/`_toggleAll`؛ `_ModuleCard`
   يقبل `expanded`/`showToggle`/`onToggle`؛ رأس tappable مع Chevron وأيقونة
   مجلد تتبدل `folder_outlined`↔`folder_open_rounded`؛ الجسم كامل داخل
   `if (expanded) ...[ ... ]`. «طي الكل» بجانب نص العدّاد.

**البوابات:**
- `flutter analyze lib/features/admin lib/features/accounts lib/features/workers
  lib/features/customers lib/features/home lib/core/constants` → لا مشاكل (0).
- `flutter test test/ibac_test.dart` → 20/20 ناجح؛ بما فيها الاختبارات الأربعة
  لسلوك batch actions في `PermissionsPickerWidget` (ما زالت تنجح لأن
  `_collapsed` افتراضياً فارغ → الأقسام مفتوحة).
- `flutter test` الكامل → 222 ناجح / ~5 متخطاة / 4 إخفاقات في
  `account_group_statement_screen_test.dart` (`RangeError at _maybeApplyDefaults:177`)؛
  مُثبت أنها سابقة لهذا العمل بـ `git stash push -- lib` ثم إعادة تشغيل — نفس
  الإخفاقات تظهر على baseline، والملف `account_group_statement_screen.dart` لم
  يُمسّ في هذه الجلسة.
- **تنبيه:** `flutter analyze lib` يشمل تحذيراً واحداً سابقاً غير متعلق في
  `biometric_login_button.dart:24` (`unused_local_variable`) — ليس من تعديلاتي.

**القرارات المعمولة:**
- `.view` يبقى شرط ظهور القسم في `portal_sections.viewCodes`؛ الأكواد الدقيقة
  تحكم ظهور الأزرار/البطاقات داخل القسم وحراسة مسارات API الخاصة بالكشف، لا
  ظهور القسم نفسه — متسق مع «يتطلب .view».
- الترحيل يمنح حامل الكود العام كل الأكواد الدقيقة المكافئة (لا إنقاص)، تاركاً
  التضييق اليدوي اللاحق عبر شاشة المنح.

**التنفيذ الفعلي على Oracle (نداء مباشر بعد أمر المستخدم):**
- توفّر `oracledb` MCP — الخطة كانت تفترض غيابه. بعد طلب «ارفع الترحيلات إلى
  قاعدة البيانات» شُغِّل `02_ibac_seed.php` (نتج 9 inserts + 123 updates؛
  total=136) ثم جُردت منح العامة (`0`) فحُذفت الأكواد الأربعة العامة.
- التحققات النهائية (عبر MCP): `COUNT(*)=132`، العامة=0، الدقيقة=9، منح يتيمة=0،
  `IS_ACTIVE=1`=132؛ و`ASCIISTR(NAME_AR)` للتسعة الجديدة أظهرت بايتات CP1256
  سليمة (`\00DF\00D4\00DD` = «كشف»).
- بعد الترحيل ظهرت إخفاقات في `PermissionSyncTest` لأن assertions قديمة كانت
  تتوقع 97 كوداً / 18 وحدة — استُبدلت بمرجع ديناميكي
  `PermissionCatalog::count()` و`count(PermissionCatalog::grouped())` حتى لا
  تتقادم مع كل توسيع قادم. Pint نظيف. `IbacCoreTest + BusinessRoutesSealedTest
  + PermissionSyncTest` = 33 test / 189 assertion نجحت كلها مقابل Oracle حيّ.
- `ExampleTest` يفشل بـ `204 !== 200` على `/` — متوقع: قاعدة صريحة للمشروع
  «API-only root»؛ لا علاقة لها بتوسيع IBAC.

**الأثر:** قاعدة البيانات مطابقة للكتالوج الجديد (132)؛ لا commit (لا طلب)؛ 6
ملفات الخادم معدّلة + 2 SQL مسلَّمة (غير منفَّذة لأنها مكررة للفعل اليدوي الآمن)
+ 10 ملفات Flutter.


## [2026-10-24 18:45] IBAC تكملة: صلاحيات تقرير عمل المجموعة + تفسير 403 · Qoder Agent

**الدافع:** بعد إغلاق التوسيع الأول، أبلغ المستخدم بثلاث مشكلات: (1) «كشف عمل
مجموعة» يجب أن تكون له صلاحية منفصلة لا نفس `statement_work` الفردي؛ (2) من يملك
`statement_financial` وحده يفتح المنتقي ويختار حساباً لكنه يصطدم بـ 403 على
`/api/accounts/chart/{accNo}/statement`؛ (3) نفس 403 على
`/api/workers/cutters/group-work-report`. الأخطاء الثلاثة تحمل نصاً عربياً
وكوداً لاتينياً: `errors.permission = ["cutters.statement"]` و`["accounts.statement"]`.

**التشخيص:**
- **الـ 403 ليست من الأكواد الجديدة** — بل من عملية `php artisan serve` التي
  لا تزال في الذاكرة من ما قبل حفظ `routes/api.php`. الأكواد العامة الأربعة
  (IDs 33/40/47/54) حُذفت من `APP_PERMISSIONS` في الترحيل الصباحي، لكن الـ serve
  الحيّ يعرف فقط المسار القديم بحارسه القديم، فيُنتج رسالة 403 تحمل الكود المحذوف.
  المسار في الكود سليم؛ يجب `route:clear` + إعادة تشغيل `serve`.
- **صلاحية مجموعة العمل:** الخطة الأصلية §3 قرّرت «كشف عمل مجموعة» يُقضى بـ
  `cutters.statement_work` **أو** `tailors.statement_work`. طلبُ المستخدم
  يستبدل ذلك بصلاحية مستقلة عن كشف الفرد، وهو أدقّ مع نموذج IBAC: القدرة على
  تصفّح أرشيف الكل ≠ القدرة على فتح سجل فرد واحد.

**ما نُفِّذ:**
1. **الخادم:** `PermissionCatalog.php` أضاف `'group_work_report'` إلى `extra`
   كلٍّ من `cutters` و`tailors`؛ `humanize()` يعرفه بالإنجليزية (`'Group work
   report'`). عدد الكتالوج 132 → **134**. صافي الحركة: −4 عام + 9 دقيق + 2
   مجموعة = **+7** من 127.
2. **`routes/api.php`:** `/workers/cutters/group-work-report` و`/workers/tailors/
   group-work-report` حارسهما الآن `<w>.group_work_report` (كان `<w>.statement_work`).
   مسارات `/workers/{id}/work-report` الفردية بقيت على `<w>.statement_work`.
3. **Oracle:** شُغِّل `02_ibac_seed.php` مرة ثانية؛ `inserted=2 updated=132
   total=134`. IDs 138 (`cutters.group_work_report`) و139 (`tailors.group_work_report`)
   نشطتان في `APP_PERMISSIONS`، و`NAME_AR` مكتوبة بنفس نمط CP1256 السابق.
   **لا تعديل على `APP_USERS_PERMISSIONS`** — كتالوج فقط؛ من يملكها يُمنح من الشاشة.
4. **Flutter:** `permission_codes.dart` أضاف `cuttersGroupWorkReport` و
   `tailorsGroupWorkReport`، وحدّث العدد في التعليق المرجعي، وأدرج الكودين في
   `allPermissionCodes` بنفس ترتيب الخادم، و`permActionLabels['group_work_report']
   = 'تقرير عمل مجموعة'`. `workers_dashboard_screen.dart`: بطاقة «كشف عمل مجموعة»
   مشروطة بـ `canAny([cuttersGroupWorkReport, tailorsGroupWorkReport])` (كان
   `[cuttersStatementWork, tailorsStatementWork]`). `home_shortcut_catalog.dart`:
   اختصار `workers.group_work` بالأكواد الجديدة. `worker_action_icons.dart` لم
   يُمسّ: أيقونات كشف الفرد ما زالت على `<apiPath>.statement_work`.
5. **الاختبارات:** `IbacCoreTest` العدد 132 → 134. `BusinessRoutesSealedTest`:
   `['get', '/api/workers/cutters/group-work-report', 'cutters.group_work_report']`
   و`['get', '/api/workers/tailors/group-work-report', 'tailors.group_work_report']`.
   Pint نظيف؛ `php artisan test --filter="IbacCoreTest|BusinessRoutesSealedTest|PermissionSyncTest"`
   = **33 test / 189 assertion نجحت** مقابل Oracle حيّ.
6. **Flutter gates:** `flutter analyze lib` = 0 مشاكل؛ `flutter test test/ibac_test.dart`
   = 20/20 ناجح.

**ما على المستخدم (لمنفّذ locally):**
- إيقاف `php artisan serve` وإعادة تشغيله على `192.168.0.9:8000`.
- بعد إعادة التشغيل، `route:list` يُظهر `EnsurePermission:accounts.statement_financial`
  و`EnsurePermission:cutters.group_work_report`؛ الطلبتان السابقتان تنجحان إن كان
  للمستخدم الكود المناسب، أو 403 برسالته الصحيحة إن لم يكن.

**الأثر:** قاعدة البيانات + كتالوج الخادم + مساراته + أكواد العميل كلها متسقة
على **134** صلاحية في 23 قسماً. لا commit (لا طلب).


## [2026-10-24 05:20] الشجرة المحاسبية: تحميل كسول، أسطر مسطّحة، تجميع من ENTRY_SUB، تصدير XLSX · Qoder Agent

**الدافع (مشاكل مُشخَّصة بالدليل):** `AccountController::getAccountTree` كان يُسقط أي أب
بلا أبناء، و20,671 حساباً من 20,954 فيها `GROUP_ID = NULL` كانت تُفلتر بـ
`TRUNC(ACC_NO/10000) = ACC_PART` (قسمة رقم ثمانية على 10000 تعطي بادئة رباعية لا تطابق
`ACC_PART` الثلاثي) فلا يكاد يظهر شيء؛ العميل يبني `Column` متداخلاً لكل عقدة مع بطاقة
مستقلة لكل سطر؛ `/accounts/tree` يعيد خمسة حقول فقط؛ أعمدة `BALANCE` كلها أصفار؛
~140 استعلاماً تعشيشياً مقابل مهلة استقبال 15 ث.

**ما نُفِّذ في Flutter (بالمسارات):**

1. **النماذج** — `lib/features/accounts/data/models/account_model.dart`:
   - `AccountTreeNode` صار يحمل `parentPath`, `codePath`, `childrenCount`, `hasChildren`,
     `debit`, `credit`, `movements`, `storedBalance`, `currency`, `stopping`,
     `limitedBalance`, `accDate`, `seq`, `accountCount`, `directCount`, `hiddenAccounts`
     مع `fromJson` يقبل المفتاح صغيراً وكبيراً (`acc_no`/`ACC_NO`) و`ArabicEncodingUtils.fix`
     للنص العربي ومُساعدي `_parseInt/_parseDouble` (Oracle يُرجع الأرقام نصاً).
   - نموذج جديد `AccountLeafModel` للحساب المالي داخل الشجرة (مدين/دائن/صافي/عدد حركات/
     رصيد مخزّن/سقف/موقوف/تاريخ/`seq`/مسار الأب). `net` و`movements` لهما سلاسل احتياط
     (`net → NET → balance → BALANCE` و`movements → MOV_COUNT → mov_count → CNT`) لأن
     غلاف `/accounts/tree/children` يسمّي الصافي `balance` وعدد الحركات `movements`.
2. **المستودع** — `lib/features/accounts/data/repositories/account_repository.dart`:
   `fetchAccountTree({fromDate,toDate})` (بدل `fetchTreeSkeleton` باسمه في الخطة، لإبقاء
   التوافق مع الشاشات الأخرى)، `fetchTreeChildren({level,groupId,accPart,search,sort,dir,
   page,limit,...})` يعيد `TreeChildrenResult` بـ meta الترقيم، `searchAccounts(q)`،
   `fetchChartAccountDetail(accNo)`، `fetchNextNumber(...)`، و`createAccMain/createAccSub/
   createSubGroup/createChartAccount/updateAccount/updateAccMain/updateAccSub/updateSubGroup`.
   نمط `CancelToken.isCancel` والإرجاع الفارغ محفوظ؛ مهلة استقبال 30 ث تُمرَّر كـ
   `Options` محلي لقراءة الهيكل فقط، بلا تغيير `ApiConstants` العام.
3. **الحالة** — `lib/features/accounts/presentation/providers/accounts_provider.dart`:
   `AccountTreeNotifier` + `AccountTreeState` بنفس اسم المزود `accountTreeProvider` (لتبقى
   بقية الشاشات عاملة): `expanded`، `childrenCache`، `childPages/childTotal/childHasMore`،
   `loadingChildren/childErrors`، `toggleExpand` (يجلب الصفحة الأولى للمضيف المالي فقط)،
   `loadMore/reloadNode/expandToLevel/collapse`، `runSearch` بحارس `_searchVersion` يرفض
   النتيجة الأقدم، و`dispose` يلغي رمز الشجرة والبحث معاً.
4. **التسطيح** — `lib/features/accounts/presentation/utils/account_tree_flatten.dart`:
   `AccountTreeRow` (structural/leaf/loading/loadMore/rowError) + `flattenAccountTree` +
   `AccountTreeFilters` + `levelBadgeLabel/levelBadgeColor` + `formatTreeAmount` (بلا intl).
5. **الشاشة** — `lib/features/accounts/presentation/screens/account_tree_screen.dart` (أُعيد
   بناؤها): `ListView.builder` وحيد فوق الصفوف المسطّحة بـ `cacheExtent`؛ سطر مضغوط/مريح؛
   ترويسة أعمدة على العريض؛ شريط فلاتر ورقائق؛ كشف المسار تلقائياً من نتيجة البحث
   (`revealPath`)؛ زر كشف (عين) داخل `PermissionGate` يفتح `AccountStatementScreen` للفردي
   و`AccountGroupStatementScreen` للهيكلي؛ نقر طويل/زر `i` → `account_details_sheet.dart`؛
   الحالات الأربع مع `_TreeSkeletonList` بدل مؤشر التحميل المفرد و`RefreshIndicator`؛
   FAB بقائمة `AccountCreateKind` الأربعة؛ قائمة تصدير في الـ AppBar خلف `accounts.export`.
6. **التصدير** — ملفات جديدة:
   - `presentation/utils/account_tree_pdf_builder.dart` — A4 RTL بأعمدة الرقم|الاسم|المستوى|
     مدين|دائن|الرصيد عبر `ReportLetterheadInfo.fromConfig` + `report_a4_sheet` +
     `report_signature_footer` ووصفة `pdfArabic` للتشكيل.
   - `presentation/utils/account_tree_xlsx_builder.dart` — `.xlsx` بورقتين («الشجرة» بكل
     الأعمدة + مسار الأب + عدد الحركات، و«ملخص» بالعدّادات والمجاميع) بألوان `AppColors`.
   - `presentation/utils/group_statement_xlsx_builder.dart` — ميزان المجموعة بورقتين
     («الميزان» و«ملخص») مع صف المجاميع المنسّق.
   - `presentation/widgets/tree_export_menu.dart` — `TreeExportMenu` و
     `GroupStatementExportMenu` يشتركان `_ReportExportActions` (حارس `_busy` للنقر
     المزدوج، طباعة عبر `Printing.layoutPdf`، PDF عبر `sharePdf`، Excel بكتابة الملف في
     `path_provider` ثم `SharePlus.instance.share`)؛ اسم الملف مؤرَّخ.
   - `presentation/screens/account_group_statement_screen.dart`: حُذفت `_printReport`
     و`_exportPdf` و`_letterheadInfo` المكرّرة، واستُبدلت زرّا الطباعة/PDF بـ
     `GroupStatementExportMenu(report: () => _report)` — الطباعة والتصدير صارا منفذين مرة واحدة.
7. **النماذج Input** — `presentation/screens/create_account_screen.dart` (أُعيد بناؤها):
   منتقي أنواع بأربع بطاقات، سلسلة أبوية `ACCOUNT → ACC_MAIN → ACC_SUB → ACC_SUB_GROUP`
   تعيد ضبط النسل عند تغيير الأب، شريط مسار، معاينة الرقم المتوقع من `/accounts/next-number`
   بنفس قاعدة الخادم، حقول حسب النوع (اسم، عملة، رصيد افتتاحي، سقف، تاريخ، `SEQ`، موقوف)،
   شبكة ثنائية على العريض، وتحقق فوري + `_isSubmitting`.
   `presentation/screens/edit_account_screen.dart`: يحمّل القيم الحالية من
   `GET /accounts/chart/{accNo}` بدل حقول فارغة، ويعرض الرصيد المحسوب للقراءة فقط مع
   الرصيد المخزّن للمقارنة، ويتيح تغيير المجموعة/الموقوفة/السقف/التاريخ.
8. **الصلاحيات والاختصارات** — `lib/core/constants/permission_codes.dart`: أكواد
   `accounts.statement_group` و`accounts.statement_detail` و`accounts.structure_manage`
   و`accounts.print` و`accounts.export` مطابقة للكتالوج؛ `home_shortcut_catalog.dart`
   و`workers_dashboard_screen.dart` أُصلح ارتطام اختصارات/بطاقات بالأكواد الجديدة.

**الاختبارات (Flutter):** `test/features/accounts/account_tree_model_test.dart` (12)،
`account_tree_notifier_test.dart` (12: تحميل/إعادة، خطأ، كاش أبناء، loadMore، reloadNode،
مستوى sub، سباق البحث بطيئ-سريع، إلغاء الرموز عند clearSearch/dispose، findById،
expandToLevel)، `account_tree_screen_test.dart` (8: قائمة مسطّحة واحدة، توسيع كسول، زر
الكشف للفردي مقابل المجموعة، قائمة التصدير حسب الصلاحية، الإدارة، الفراغ/الخطأ، البحث
الخادمي)، وتحديث `account_group_statement_screen_test.dart` للقائمة المشتركة مع اختبار
عنصر «تصدير Excel». **نتيجة البوابات:** `flutter analyze` = No issues found!،
`flutter test` = 259 passed / 5 skipped.

**ملاحظة سلوكية للواجهة:** الأسطر القابلة للكشف تحمل `onDoubleTap`، لذا يؤجّل Flutter
النقرة المفردة ~300ms؛ الاختبارات تنتظر 400ms بعد النقر ثم `pumpAndSettle` لتجاوز
النافذة — وهو ما يجب تكراره في أي اختبار مستقبلي ينقر على أسطر الشجرة.

**إصلاحات جانبية (خارج الشجرة، ظهرت أثناء البوابات):** شاشة ميزان المجموعة كانت تختار
`list[1]` بدل `list.first` في `_maybeApplyDefaults` (RangeError عند عنصر واحد)؛
`test/api_config_test.dart` توقّع مضيفاً لا علاقة له بالمُدخل؛ `analysis_options.yaml`
كان `unnecessary_brace_in_string_interps: ignore ignore`؛ زر البصمة كان فيه `label`
معطّلاً غير مستعمل فصار `tooltip`؛ المُعامل `_pump` في اختبار تقرير عمل المجموعة أُعيدت تسميته
إلى `pumpApp` (مع إزالة BOM أضافته أداة الاستبدال).

**Git:** لا commit من الوكيل. الأكواد الخادميّة للشجرة محفوظة بيد المستخدم في `kyApp_API`
`5945166`؛ التغييرات هنا عاملة في شجرة العمل فقط.

---

## [2026-10-24 09:24] إصلاح ثلاث مشكلات في الشجرة + فتح/إغلاق الفروع · Qoder Agent

**الطلب:** «أولاً حجم وتنسيق العرض غير مظبوط… واسمها يظهر مقصوص… وتوسيع خيارات الكثافة والحجم»
و«ثانياً الطباعه والتصدير يقوم بطباعه الحسابات الرئيسيه فقط… والمفروض تخيير المستخدم بالمستويات»
و«ثالثاً حقل العمله… يجب ان يتم اظهار قائمه العملات المتاحه» ثم «اكمل الاصلاح وايضا لاتنسى اضافه
امكانيه فتح/اغلاق ظهور الحسابات الفرعيه».

### الخادم (`kyApp_API`) — لم يُلمَس أي هيكل جدولي
1. **`AccountController::exportTree`** (`GET /api/accounts/export-tree`، `permission:accounts.export,accounts.print`)
   — إخراج **مسطّح** بطبقات `DEPTH/LEVEL/CODE/NAME/PARENT_PATH/CODE_PATH/DEBIT/CREDIT/BALANCE/MOVEMENTS/CUR_NO/ROOT_ACC_NO`.
   السبب الجذري للعطل: الشاشة تُحمَّل كسولاً مستوى-بمستوى، فالتصدير من حالة الشاشة كان يرى
   الأقسام المفتوحة فقط. الآن الخادم يجيب عن كل المستويات المختارة:
   - `levels` أبيض-list من `{account,main,sub,group,chart}`، والفارغ = كل المستويات (لا مطبوعة صامتة).
   - `section` يضيّق الأجزاء عبر `sectionOfPart()`، و`include_customers`/`hide_zero` و`from_date/to_date`.
   - فلترة `CHART_ACC` داخل SQL: `SUBSTR(TO_CHAR(ACC_NO),1,3) IN (:part_0,…)` + حارس
     `CUSTOMERS_ACC_PART`/`KOBOUDI_CUSTOMER_ACC_NO` — لا 20 ألف صف إلى PHP.
   - الأرصدة من نفس `movementBalancesByChart()` + `rollUpBalances()` المستخدمة في `/accounts/tree`،
     فلا تتباعد المطبوعة عن الشاشة (يثبته اختبار التكافؤ).
   - `CHART_ACC` بلا عمود عملة (ثمانية أعمدة فقط): العملة تُورَّث عن الحساب الجزئي.
2. **`AccountController::getCurrencyOptions`** (`GET /api/accounts/currencies`) —
   `SELECT CUR_NO, CUR_NAME FROM CURRENCY ORDER BY CUR_NO` + `array_change_key_case` +
   `ArabicEncoding::fixMojibake`. صلاحياته هي صلاحيات **الحسابات**
   (`accounts.view,create,update,structure_manage`) لا `currencies.view`: مستخدمُ إنشاءٍ بلا
   دليل عملات كان يرى قائمة فارغة في حقل يطلب منه الاختيار.
3. **`tests/Feature/AccountTreeExportTest.php`** — 8 اختبارات / **10,835 assertion** مقابل Oracle حيّ
   (الختم بالصلاحية، كل المستويات افتراضاً، الاحترام الاختياري، تكافؤ الأرصدة، العملاء،
   تضييق القسم/PDF… إلخ). `pint --dirty` = passed، و`BusinessRoutesSealedTest` = 6 passed.

### العميل (Flutter)
4. **نموذج الصفوف** — `lib/features/accounts/data/models/tree_export_row_model.dart`:
   `TreeExportLevel` (أكواد الخادم نفسها + `labelAr`/`hintAr` + `parseCodes`/`codesOf`)،
   `TreeExportScope` (`.all`، `containsCustomers` الذي يشترط مستوى الأوراق، `describe()`،
   `toQuery()`)، `TreeExportRow` بقراءة مزدوجة المفاتيح ومحوّلات `_parseInt/_parseDouble`
   و`ArabicEncodingUtils.fix` لكل نص عربي، و`CurrencyOptionModel{curNo,curName,display}`.
   `presentation/utils/tree_export_adapter.dart` يحوّل صفوف الخادم إلى أسطر العرض المستخدمة
   في PDF/XLSX، ويبني التذييل من عدّادات المستويات التي رجعت من الخادم فعلاً.
5. **قائمة التصدير** — `presentation/widgets/tree_export_menu.dart` أُعيدت: حُذف معامل `rows:`
   (كان يقرأ `_visibleRows()` من حالة التمرير) وحلّ محله `defaultSectionAccNo` +
   `_prepareScope()` (نافذة النطاق ← `fetchTreeExport` ← تحويل ← وصف)، `_token` يُلغى في
   `dispose()`، `_busy` يغطّي الجلب، والإلغاء = لا طلب. `_ReportExportActions` صار يقبل
   `onPrepare`/`emptyMessage` فتُشارك الحراسة نفسها مع ميزان المجموعة دون تغيير سلوكه.
6. **نافذة النطاق** — `presentation/widgets/tree_export_scope_sheet.dart`: خانات المستويات
   الخمسة، القسم (ممهّد من الشاشة)، حسابات العملاء، إخفاء الأرصدة الصفرية، والفترة.
7. **قياسات السطر** — `presentation/utils/tree_row_layout.dart`: `TreeDensity` بخمس كثافات
   (`ultra 22 / compact 28 / standard 34 / comfortable 42 / relaxed 52`) و`TreeRowMetrics.resolve`
   الذي يشتق العرض النسبي من المتاح مع أرضية 96px للاسم، ثم يُطفئ بالترتيب: الأعمدة → الشارة →
   الأزرار → تضييق الرصيد فالرقم. `badgeW=52` و`actionsW` و`handleW=26` فتحات ثابتة يتقاسمها
   السطر ورأس الأعمدة، فعمود الرصيد لا ينزلق بين سطر ذي زرّين وسطر ذي ثلاثة.
8. **سطر الشجرة** — `presentation/widgets/account_tree_row_tile.dart`: الاسم في `Expanded` +
   `FittedBox(fit: BoxFit.scaleDown)` بحجم خط `metrics.nameFontSize` (يتقادم مع الكثافة بدل 24 ثابتة)
   فلا يُقصّ أبداً؛ `onLongPress: onDetails` لأن الأزرار تُطفأ تحت 500px؛ `_ExpandHandle`
   بمقبض فتح/إغلاق لكل عقدة (`Tooltip`: إظهار/إخفاء الحسابات الفرعية)؛ و`AccountTreeColumnsHeader`
   يقرأ نفس الـ metrics.
9. **فتح/إغلاق الفروع** — `presentation/screens/account_tree_screen.dart`: زرّ الـ AppBar
   `فتح ظهور الحسابات الفرعية`/`إغلاق ظهور الحسابات الفرعية` ← `expandToLevel(3)` /
   `expandToLevel(-1)` (سقف `_autoLoadCap = 30` طلباً)، دورة كثافة بخمس حالات
   (`Icons.format_line_spacing_rounded`)، وخيارات عرض فيها مفتاح «ظهور الحسابات الفرعية»
   و«توسيع حتى مستوى». `responsive.dart` حُذف من الاستيرادات لأن القياسات صارت من `LayoutBuilder`.
10. **حقل العملة** — `presentation/screens/create_account_screen.dart`: `_currencyController`
    صار `int? _currencyNo`، والحقل النصي صار `_currencyField()` (قائمة منسدلة عبر `_dropdown<int?>`
    مع «بدون عملة» وحارس `known` يمنع assert القائمة المنسدلة، وحقل «قيد التحميل» أثناء الجلب، وزر إعادة محاولة
    عند الفشل لأن الحقل اختياري)، ويُعرض **فقط** لـ `main|sub` — وهما الجدولان اللذان يخزّنان
    `CUR_NO`. `accounts_provider.dart` أضاف `accountCurrencyOptionsProvider`.

### الاختبارات والبوابات
11. `test/features/accounts/account_tree_export_test.dart` (نماذج/تخطيط + نافذة النطاق على
    الشاشة: لا طلب قبل التأكيد، كل المستويات عند التأكيد، توريث القسم المحدَّد على الشاشة، إزالة مستوى
    من الطلب، الإلغاء لا يطلب، رفض الخادم يعرض رسالته العربية، فتح/إغلاق الكل، مقبض السطر،
    خمس كثافات بحجمها) و`test/features/accounts/account_currency_field_test.dart` (قائمة لا رقم،
    القيمة المختارة هي المرسلة، الفشل غير مانع، إعادة المحاولة تجلب ثانية، ولا حقل لجدولٍ لا يخزّنه).
12. **نتائج البوابات:** `flutter analyze` = **No issues found!** · `flutter test` =
    **285 passed / 5 skipped** · Pest `AccountTreeExport` = 8 passed · Pest
    `BusinessRoutesSealed` = 6 passed · `pint --dirty` = passed.
13. **ما تعلّمته الاختبارات (وليس أخطاء إنتاجية):** Riverpod 3 يعيد تلقائياً محاولة
    `FutureProvider` الفاشل عشر مرات بتراجع متصاعد (`ProviderContainer.defaultRetry`)، لذا
    تُوقَف في `ProviderScope(retry: …)` داخل الاختبار؛ `DropdownButton` يعرض العنصر ذا القيمة
    `null` بدل `hint`؛ `DropdownButtonFormField` لا يكشف `items/value` كحقول عامة فتُقرأ
    `FormFieldState`؛ `initialValue:` غير موجود قبل Flutter 3.32 (المشروع على 3.29.3/Dart 3.7.2)؛
    `AppColors.textPrimary` قيمةٌ ديناميكية (getter) فلا تصلح داخل `const`.
14. **إصلاح ذاتي أثناء الجلسة:** إعادة كتابة ملف Dart عبر أنبوب نص في PowerShell 5.1 أضاف
    BOM ثم أكل حرف `i` من أول `import` — أُصلح بإعادة كتابة البايتات بترميز `UTF8Encoding($false)`؛
    القاعدة: ملفات Dart تُعدّل بأدوات الملفات لا بأنبوب الطرفية.

**Git:** لا commit من الوكيل؛ لا DDL؛ لم يُعدَّل ملف الخطة.

---

## [2026-10-24 14:44] جولة إصلاح ثانية بعد الاختبار الحيّ — شجرة الحسابات (Qoder Agent)

ثلاث مشكلات بلّغ عنها المستخدم بعد التجربة الحيّة (متصفّح ويب/Chrome حسب `dio_web_adapter` في
التتبّع). التشخيص بالجذر قبل أي تعديل، والدليل مُوثَّق أسفل كل بند.

### 1) انهيار `Another exception was thrown: Invalid argument: 52` عند النقر على فتح/إغلاق الفروع

- **الملف:** `lib/features/accounts/presentation/widgets/account_tree_row_tile.dart` — دالة
  `_statusRow`.
- **الجذر:** `height: (_comfortableHeight - 8).clamp(metrics.height, _comfortableHeight)` مع
  `static const double _comfortableHeight = 46;`. على الكثافة «الواسعة» (`TreeDensity.relaxed` =
  52px) تصبح `clamp(52, 46)` — أي حدٌّ أدنى أكبر من الأعلى — و`num.clamp` يرمي `ArgumentError`
  بدل أن يقيّد القيمة. في الـ VM النص `Invalid argument(s): 52.0` من
  `dart:core-patch/double.dart`، وفي dart2js (الويب) يظهر مختصراً إلى `Invalid argument: 52`
  تماماً كما بلّغ المستخدم. لا موقع في إطار Flutter يرمي نص «Invalid argument»، فالدليل قاطع.
- **الإثبات:** ملف فحص مؤقت `clamp_probe.dart` مشغّل على VM →
  `Unhandled exception: Invalid argument(s): 52.0  #0 double.clamp`.
- **لماذا لحظة التوسيع بالذات:** صفوف الحالة `loading` / `loadMore` / `rowError` هي الوحيدة التي
  تمرّ عبر `_statusRow`، وهي ما يُنتجه النقر على فتح الفرع (جلب الأبناء). لم تظهر على الكثافة
  الافتراضية (`compact` = 28) لأن `clamp(38…)` كانت سليمة.
- **الإصلاح:** استبدال الـ clamp بشرط `max` صريح مع تعليق ثنائي اللغة يشرح سبب منع الـ clamp
  مستقبلاً:
  ```dart
  height: metrics.height > _comfortableHeight - 8 ? metrics.height : _comfortableHeight - 8,
  ```
- **اختبار الانحدار (كان ناقصاً):** `test/features/accounts/account_tree_export_test.dart`
  → «status rows survive every density — the 52px clamp crash»: أنواع صفوف الحالة الثلاثة ×
  الكثافات الخمسة، يتأكد `tester.takeException() == null` وأن ارتفاع السطر ≥ ارتفاع الكثافة.
  الاختبار السابق كان يقيس صفوف **البيانات** فقط — لذلك فات الانهيار.

### 2) حقل اختيار العملة «غير موجود» في نموذج إنشاء حساب

- **الملف:** `lib/features/accounts/presentation/screens/create_account_screen.dart`.
- **الجذر:** في الجولة السابقة ضُمِّن حقل العملة داخل صفّ الرصيد وجُعِل ظهوره مشروطاً بـ
  `_kind == main || _kind == sub` فقط. لكن نوع النموذج الافتراضي هو `chart` (الأكثر استخداماً)،
  فسطر العملة كله كان يختفي عند فتح الشاشة — لا أن المستخدم أخطأ البحث عنه.
- **الحقيقة المرجعية:** `CUR_NO` موجود في `ACC_MAIN` و`ACC_SUB` فقط؛ لا عمود عملة في `CHART_ACC`
  (8 أعمدة) ولا في `ACC_SUB_GROUP`. لذلك لا يمكن «إظهار قائمة العملات» لمستوى لا يخزّنها.
- **الإصلاح (سطر العملة يُعرض دائماً، ولا يختفي أبداً):**
  - `_currencyRow()` يفصل العملة في سطر مستقل خارج صفّ الرصيد، ويقرّر:
    منتقي حقيقي `_currencyField()` للمستويات التي تخزّن العملة، و`_inheritedCurrencyField()`
    للقراءة فقط لغيرها.
  - `_inheritedCurNo` يقرأ العملة الموروثة من `ACC_SUB` الأعلى عبر
    `ref.watch(parentAccSubProvider(_selectedAccSub)).value` (الـ `.value` لا `when()` لأن
    الحقل وصفي ولا يجوز أن يحجب النموذج أو يجمّده).
  - `_inheritedCurrencyField()` يعرض `InputDecorator` بعنوان «العملة (موروثة عن الحساب الجزئي)»
    وأيقونة قفل، بثلاث حالات نصية: «تظهر بعد اختيار الحساب الجزئي» / «بدون عملة على الحساب
    الجزئي» / «`2 — دولار`».
  - `_currencyFieldRetry(Object? error)` تميّز 404 عند فشل `/accounts/currencies` فتقول
    «الخادم لا يعرف /accounts/currencies (404)» بدل «انقر للمحاولة ثانية» وحدها
    (إضافة `import 'package:dio/dio.dart';`).
- **اختبارات:** `test/features/accounts/account_currency_field_test.dart` استُبدل اختبار
  «يظهر فقط للجداول التي تخزّن CUR_NO» باثنين: (أ) سطر العملة لا يغيب أبداً لعرضِ
  `chart|group` مع ظهور الحقل للقراءة فقط واختفاء المنتقي؛ (ب) حساب `chart` يعرض عملة الحساب
  الجزئي الأعلى فعلاً (`2 — دولار`) بعد بذور `accNo/accSub/accPart` تمرَّر إلى الشاشة.

### 3) `404` عند الطباعة/التصدير — تشخيص: ليس خللاً في الكود، بل خادم قديم على جهاز آخر

- **الأدلة الميدانية:**
  - `Get-NetIPAddress` على هذه الآلة = **192.168.0.11**؛ والتتبّع الحيّ يستدعي
    **192.168.0.9**.
  - `Test-Path C:\kyApp_API` على هذه الآلة = **False**، بينما كل إطارات تتبّع استجابة المستخدم
    تحت `C:\kyApp_API\vendor\…` → الخادم الذي يجيب على 192.168.0.9 نسخة checkout أخرى **أقدم**.
  - `php artisan route:list --path=accounts` محلياً يُظهر `api/accounts/export-tree` و
    `api/accounts/currencies`.
  - `bootstrap/cache` يحتوي `.gitignore` و`packages.php` و`services.php` فقط — لا `routes-v7.php`
    مُخزَّناً، فمسح الخزّان ليس الحلّ هنا.
  - خادم فحص مؤقت (`php artisan serve --host 127.0.0.1 --port 8099`) أرجع للمسارين **401**
    مع `Accept: application/json` (وليس 404) → المساران مسجَّلان ويعملان؛ و500 الذي ظهر أول مرة
    كان أثراً للفحص نفسه: `Accept: text/html` جعل Sanctum يحاول إعادة التوجيه إلى اسم مسار
    `login` غير معرَّف (`Route [login] not defined` في `storage/logs/laravel.log`)، وهو سلوك
    معزول عن طلبات التطبيق التي ترسل JSON دائماً.
- **ما عُدّل في الواجهة:** `lib/features/accounts/presentation/widgets/tree_export_menu.dart` —
  `_describeFailure` تخصّص 404 برسالة عربية تدلّ على النشر مباشرة: «الخادم الحالي لا يعرف نقطة
  التصدير (404) — حدِّث الـ API من المستودع وأعد تشغيل php artisan serve ثم امسح خزّان المسارات
  (route:clear)»، بدل رسالة الشبكة العمومية التي أخفت السبب الحقيقي.
- **الإجراء المطلوب من المستخدم (خارج شجرة الكود):** نشر `routes/api.php` +
  `app/Http/Controllers/AccountController.php` على جهاز 192.168.0.9 (أو commit+push للـ submodule
  ثم pull هناك + `php artisan route:clear`)، أو تشغيل الـ API من هذا الفرع وتغيير Base URL من
  إعدادات شاشة الدخول إلى `192.168.0.11:8000`.

### ما لم يُمَسّ (عمل المستخدم الجاري)

`lib/features/accounts/presentation/widgets/account_statement_report_footer.dart` معدَّل من
المستخدم (git `M`، آخر كتابة 2026-10-24 14:20:23، آخر commit `0787cd6`) مع تعطيل أسطر كتلة
التواقيع والتوضيح وتوقيت الإصدار. نتج عنه تحذيران في `flutter analyze`
(`unused_local_variable 'timestamp'` سطر 24، `unused_element '_SignatureSlot'` سطر 155) وفشل
اختبار `account_statement_report_widgets_test.dart:109` الذي يبحث عن `توقيع المدير`. لم أعدّله
ولا أحذف الكود نيابة عن المستخدم؛ القرار له: إعادة تفعيل الكتلة أو حذفها وضبط الاختبار.

### البوابات

`flutter analyze` = تحذيران فقط وكلاهما في الملف أعلاه · `flutter test` = **286 passed / 5 skipped
/ 1 failed** والفشل الوحيد من نفس السبب · `flutter test test/features/accounts` للملفين المستهدفين
= **28 passed** · لا تغيير PHP هذه الجولة (فلا Pest/Pint) · لا SQL · لا DDL · لا commit.

---

## [2026-10-24 15:20] جولة الإصلاح 3 — عملة كل حساب مالي تُختار مستقلّة (بلا وراثة)

**السبب:** رفض المستخدم تصميم الجولة السابقة (حقل موروث للقراءة فقط) وأمر بإظهار حقل عملة
قابل للاختيار لكل حساب مالي بشكل مستقل، وكشف أن العملة = **الخانة الرابعة من رقم الحساب**،
مع «إلزامي دائماً» ومنع إضافة أي عمود أو جدول.

**ما تمّ (Flutter):**
- `create_account_screen.dart`: حقل العملة صار **منتقيًا حقيقيًا إلزاميًا** للحساب المالي
  (`_currencyField` مع `mandatory` يحذف خيار «بدون عملة»)، وتسميته توضح «الخانة الرابعة من
  رقم الحساب». أُلغي `_inheritedCurNo`/`_inheritedCurrencyField`. استُبدل بـ `_pickCurrency`
  الذي يستدعي `_schedulePreview()` ف**تتبدّل المعاينة لحظيًا** مع العملة، وبوابة `_canPreview`
  صارت تتطلب `_currencyNo != null`، وأضيف منع الإرسال بلا عملة في `_validateParent`. بقيت
  المجموعة سطرًا وصفيًا (`_groupCurrencyNote`) لأنها الوحيدة بلا رقم وبلا عمود.
- `account_repository.dart`: `fetchNextNumber` يستقبل `cur_no`، و`createChartAccount` صارت
  `required int curNo` ترسل `cur_no`.
- `account_model.dart`: `AccountLeafModel` أضاف `curNo` (يُقرأ من `cur_no` الخادم أو يُشتق
  محليًا من الرقم عبر `_currencyFromNumber`). `tree_export_adapter.dart` يمرّر `curNo`.
- `edit_account_screen.dart`: شريط **عملة للقراءة فقط** مشتقة من الرقم — تغييرها يعني إعادة
  ترقيم حسابٍ مراجِعُه الحركات قائمة، وهو غير آمن.

**ما تمّ (API — تذكير، التفصيل في DBdevloping_history):** نطاق ترقيم `(جزء, عملة)` بدل MAX
على الجزء كاملًا، و`cur_no` إلزامي في الإنشاء والمعاينة، واشتقاق `cur_no` في كل قراءات الشجرة.

**البوابات:** `flutter analyze` = **تحذيران فقط** وكلاهما في `account_statement_report_footer.dart`
الذي عدّله المستخدم (بلا توقيع المدير) · `flutter test test/features/accounts/account_currency_field_test.dart`
= **7 passed** · Pest المستهدف = **26 passed (11208 assertions)** · `pint --dirty` = **passed** ·
الحزمة الكاملة = **286 passed / 5 skipped / 2 failed** (الفشلان: تعديل المستخدم للمطبوعة،
وتذبذب خطوط العربية لاختبار «it is optional» يمرّ أخضر منفردًا) · **لا DDL ولا DML** · **لا commit**.

---

## [2026-10-25 10:00] الكشوفات الشخصية للموظف الحالي (مالي + عمل) · Qoder Agent

**الطلب:** كشفان يفتحان مباشرة على بيانات الموظف الحالي بلا أي منتقي حساب/عامل: «كشف حسابي
المالي» و«كشف عملي» (خياط/قصاص)، بصلاحيتين IBAC مستقلتين واختصارين في الشاشة الرئيسية فقط
(لا قسم لهما في الدرج)، مع ربط المستخدم بحسابه المالي عبر عمود `ACC_NO` جديد في `APP_USERS`.

**ما تمّ (الخادم `kyApp_API`):**
- `MyStatementController.php` جديد: `financialStatement()` يقرأ `ACC_NO` من المستخدم المصادق
  عليه حصراً (بلا بارامتر من العميل ← لا يمكن رؤية كشف موظف آخر)، ويعيد نفس غلاف
  `/accounts/chart/{accNo}/statement` (`data.account/transactions/summary`)؛ بلا حساب مرتبط ← 422.
  `workStatement()` يكتشف النوع بعدّ صفوف `TAILOR_FROM_CALC.TAILOR_ACC` مقابل
  `CUTTER_FROM_CALC.CUTTER_ACC` (الخياط ذو أولوية)، ويستعلم جدول CALC المطابق ويعيد نفس غلاف
  `/workers/{type}/{id}/work-report` (`worker/data/summary` + `worker.type_label`).
- `routes/api.php`: مساران خلف `auth:sanctum` + `permission:my_statement.financial` و
  `permission:my_statement.work`.
- `PermissionCatalog.php`: وحدة `my_statement` («الكشوفات الشخصية»)، core `view` وextra
  `financial`/`work`، وتوسيع `humanize()`. `User.php`: `ACC_NO` في `$fillable`.
  `AuthController::userPayload`: إضافة `acc_no`. `UserAdminController`: قبول `acc_no` في
  store/update (الـ INSERT + خريطة `$plainWrites`).

**ما تمّ (قاعدة البيانات ← التفاصيل في DBdevloping_history):** `ALTER TABLE ACCOUNTS.APP_USERS
ADD ACC_NO NUMBER` (nullable، بلا foreign key لأن CHART_ACC خارج السيطرة)؛ بذر 4 أكواد في
`APP_PERMISSIONS` (IDs 140–143) ومزامنة `SEQ_APP_PERMISSIONS`.

**ما تمّ (Flutter):** `permission_codes.dart` (مرآة: `myStatement{Wildcard,View,Financial,Work}`
والقوائم)؛ `UserModel.accNo`؛ نقطتا `/my-statement/financial` و`/my-statement/work`؛ ميزة
`my_statement/` كاملة: repository يعيد `AccountStatementData`/`WorkerWorkReport`، provider بنمط
Notifier يفحص `accNo == null` برسالة واضحة؛ شاشتان مبسّطتان بلا منتقي —
`my_financial_statement_screen.dart` (ترويسة ثابتة بدل `_AccountPickerBottomSheet`) و
`my_work_statement_screen.dart` (نفس WorkerWorkReportScreen بلا workerId/workerType، يعرض نوع
العمل من `worker.type_label`). `WorkerWorkReport` أضاف حقلاً اختيارياً `typeLabel`.
`home_shortcut_catalog.dart`: بطاقتان `my_statement.financial` و`my_statement.work` بـ
`sectionId: 'home'` و`defaultOn: false` وأكوادهما المستقلة.

**البوابات:** `flutter analyze` على الميزة + الكتالوج + النموذج = **No issues found!** ·
`flutter test test/home_catalog_test.dart` = **15 passed** · باقي `flutter analyze` = تحذيران
قديمان فقط في `account_statement_report_footer.dart` (تعديل المستخدم السابق، خارج النطاق) ·
**لا commit** · لم يُعدَّل ملف الخطة.

---

## 2026-10-24 — التحقق النهائي + تصحيح `defaultOn` (Claude)

**التصحيح:** أثناء المراجعة الختامية تبيّن أن البطاقتين `my_statement.financial` و
`my_statement.work` في `home_shortcut_catalog.dart` كانتا فعلياً بـ `defaultOn: true`، وهو ما
يخالف بند التوافق في الخطة (سطر 368: الاختصارات الجديدة `defaultOn: false`). تمّ ضبطهما على
`defaultOn: false`. بحسب `home_layout.dart:127` لا تدخل أي بطاقة مجموعة الظهور الافتراضي إلا إذا
كانت `defaultOn || shown` — لذا بطاقتانا (مغلقة افتراضياً ومقيّدة بأكواد `my_statement.*`) لا
تؤثران على أي عدّاد للبطاقات الافتراضية ولا تظهران إلا لمن مُنح الصلاحية.

**التحقق النهائي (أدلة):**
- Backend: `php artisan test` = **155 passed, 4 skipped** (التخطّيات لمسارات بيانات تنتظر ربط
  `ACC_NO` يدوياً في Phase 0.2) · `vendor/bin/pint --dirty` = **passed**.
- `MyStatementTest` 4 passed/2 skipped · `BusinessRoutesSealedTest` 6 passed · `IbacCoreTest` 16
  passed (عدّاد الكتالوج = 138).
- الأمان: `MyStatementController` يقرأ `$accNo` من `$request->user()` حصراً (سطر 38 و257)، وكل
  ربط `:acc_no` منه؛ لا يقبل أي معرّف حساب من العميل (منع-افتراضي).
- قاعدة بيانات التطبيق (127.0.0.1/orcl): عمود `ACC_NO` مُضاف + 4 أذونات `my_statement.*` مزروعة.
- Flutter: `flutter test test/features/my_statement/` = **3 passed** (اختبارات الودجت: لا منتقي
  حساب + رسالة "لا يوجد حساب مرتبط")؛ فحص ملفات الميزة = نظيف.
- المتبقّي في `flutter test`: **284 passed, 5 skipped, 7 failed** — كلها نتيجة تعديلات متزامنة
  غير محفوظة لوكلاء آخرين (إعادة هيكلة الكتالوج `customers.*`/`accounts.*` → false، وإعادة بناء
  footer العملات)؛ لا فشل منها سببه ميزتنا (بطاقتانا `defaultOn: false` تساهمان بصفر).
**لا commit** · لم يُعدَّل ملف الخطة.

---

## 2026-10-24 — حقل «الحساب المالي» (ACC_NO) في واجهة إنشاء/تعديل المستخدم (Claude)

**المطلوب:** تطوير واجهة إنشاء/تعديل المستخدم بإضافة حقل «الحساب المالي» (`ACC_NO`) ينقر عليه
المدير فتُعرض قائمة الحسابات المالية (شجرة الحسابات) فيختار حساباً يُربط بالمستخدم تلقائياً، مع
التفريق الواضح عن حقل «رقم الحساب النقدي» الموجود سابقاً (`CASH_ACC_NO` = حساب الصندوق الافتراضي).

**التحليل:** الخادم كان يكتب `acc_no` في store/update لكنه لا يُرجعه في أي مسار قراءة — فلا يُعبَّأ
النموذج عند التعديل ولا يظهر في القائمة. أُصلحت القراءة فقط.

**التغييرات:**
- Backend `UserAdminController.php`: `LIST_SQL` += `u.ACC_NO`؛ `findUser` SELECT += `ACC_NO`؛
  `shape()` += `'acc_no' => isset(...) ? (int) : null`. تعليق ثنائي اللغة يوضح الفرق بين العمودين.
- Model `app_user_model.dart`: حقل `accNo` (منفصل عن `cashAccNo`) مع قراءة مزدوجة `acc_no ?? ACC_NO`.
- Widget جديد `financial_account_picker.dart`: `FinancialAccountPickerSheet` + `showFinancialAccountPicker()`
  فوق `chartAccountsProvider` (بحث debounced 300ms، أربع حالات عرض).
- `user_form_widget.dart`: إعادة تسمية حقل الصندوق إلى «رقم الحساب النقدي (الصندوق)» + نصّ إرشادي،
  وحقل `_buildFinancialAccountField(canPick)` — منتقي نقرائي عند الصلاحية، أو حقل رقمي يدوي خلافها
  (تفادياً لـ403 لمحرّر يملك `users.update` فقط)؛ وربط `acc_no` في الـpayload بنفس دلالات null.
- اختبارات: `UsersAdminTest` +2 عقد قراءة (**19 passed**، Pint نظيف)؛ widget test جديد
  `user_form_financial_account_test.dart` (**3 passed**): منتقي المدير، حالة «مرتبط بالحساب 500» +
  unlink، والمنفذ الرقمي بلا صلاحية شجرة.

**قاعدة البيانات:** لا DDL/DML — عمود `APP_USERS.ACC_NO` موجود مسبقاً من مهمة الكشوفات الشخصية.
**البوابات:** `flutter analyze lib/features/admin` = **No issues found!** (تحذيران سابقان خارج
النطاق في `account_statement_report_footer.dart`) · **لا commit** (لا طلب) · لا ملف خطة لهذه المهمة.

---

## 2026-10-25 — إصلاح تعذّر بناء Android (تعارض إصدار Kotlin) (Claude)

**العَرَض:** `flutter run`/`flutter build apk` يفشل في `:share_plus:compileDebugKotlin` بعشرات
الأسطر `Class 'kotlin.Unit' was compiled with an incompatible version of Kotlin. The actual metadata
version is 2.2.0, but the compiler version 1.9.x can read versions up to 2.0.0`.

**السبب الجذري:** حزمة `share_plus 12.0.2` (أُضيفت مع ميزة تصدير/مشاركة PDF — ليست من مهمة الحقل
المالي) تُصرَّف ضد Kotlin stdlib **2.2.0**، بينما المشروع يثبّت إضافة Kotlin Gradle على **1.9.24**
في `android/settings.gradle.kts` — مترجم 1.9.x لا يقرأ بيانات وصفية (metadata) أعلى من 2.0.0.

**الإصلاح (سطر واحد، إعداد بناء فقط):** ترقية `org.jetbrains.kotlin.android` من `1.9.24` إلى
`2.2.0` في `android/settings.gradle.kts`. المتطلبات متوافقة: Gradle 8.10.2، AGP 8.7.0، JDK 21،
jvmTarget 11. لا تغيير على الكود المصدري (Dart/PHP) ولا على القاعدة.

**التحقق:** `flutter build apk --debug` = **✓ Built app-debug.apk** (نجح بعد أول تجميع كامل
لـ Kotlin 2.2.0 استغرق ~20 دقيقة؛ التجميعات التالية أذكى/أسرع). التحذيرات المتبقية (`source/target
value 8 is obsolete` من إحدى الحزم، و`x86 targets will be removed`) غير معطِّلة وخارج النطاق.
**لا commit** (لم يُطلب).

---

## 2026-10-25 (02:45) — الإصدار الثاني v1.1.0+2: إصلاحات ثم بناء موقّع (Qoder Agent)

**السياق:** بعد بناء v1.0.0 (commit 33f8752) أُضيفت ميزات كبيرة (توسيع الصلاحيات f670271، شجرة
الحسابات والكشوفات ec37748)، فقرّرنا ترقية **minor** إلى `1.1.0+2`. عند التشغيل الأول لـ `flutter test`
ظهرت 7 إخفاقات؛ قرار المستخدم: «إصلاح الاختبارات ثم البناء».

**الإصلاحات:**
1. **علة إنتاج حقيقية — زر الحفظ:** في `lib/features/accounts/presentation/screens/create_account_screen.dart`
   كان الحارس `if (repeatable)` داخل `_stickyActions()` يغلّف زر «حفظ» الرئيسي بالخطأ (أصله كان لزر
   ثانوي معطّل بالتعليق)، فاختفى الحفظ عن أنواع main/sub/part. أصبح الزر يُرسم لكل الأنواع، وحُذف
   المتغير الميت `repeatable`. اكتُشف بتشخيص مؤقت (dump لشجرة الودجت) ثم حُذف ملف التشخيص.
2. **تنظيف تذييل الكشف:** `account_statement_report_footer.dart` كان يحمل كتلًا معلّقة بالتعليقات منذ
   إزالة التواقيع في ec37748 — حُذفت الشيفرة الميتة (`_SignatureSlot`، متغير `timestamp` غير المستخدم)
   بما يرفع تحذيرَي `flutter analyze`، وحُدّث اختبار الفيض في
   `account_statement_report_widgets_test.dart` ليطالب بصندوق الإجماليات لا بخانة «توقيع المدير».
3. **تحديث 5 توقعات قديمة:** `home_catalog_test.dart` (13→14 افتراضية)، `home_notifier_test.dart`
   (14→15 عند أول تشغيل، واختبار الإخفاء استبدل `customers.section` الذي أضحى opt-in بـ
   `management.users`)، `responsive_layout_test.dart` (منح `customers.view` وحدها تعطي بطاقتين لا أربع،
   والأولى صارت «الإعدادات» لا «العملاء»).

**البوابات:** `flutter analyze` = **No issues found!** · `flutter test` = **294 All tests passed**.

**البناء والتوقيع:** `flutter build apk --release --split-per-abi` → armeabi-v7a (30.9MB)، arm64-v8a
(32.8MB)، x86_64 (34.6MB)؛ و`flutter build apk --release` → universal (90.2MB). كل منها موقّع بـ
`android/ky_release.jks` (نفس شهادة v1 — SHA-256 ‏811E477C851ABA177B6504F0A57BDAC005E6400012A9BE476C5778D6DADA5D0F،
‏CN=Al-Kaboodi Tailoring) فترقية مستخدمي v1 تعمل دون إلغاء التثبيت. تحقّق aapt2:
`com.alkaboudy.app` · versionName ‏1.1.0 · versionCode ‏2 (universal) و1002/2002/4002 (مضاعف ABI لكل معمارية).

**الأرشفة:** النسخ الأربع في `release_artifacts/v1.1.0+2/` (مسار مستثنى في `.gitignore`) — تُرفع للمتجر
يدويًا. **لا commit** للتغييرات الوظيفية (لم يُطلب).

---

## 2026-10-25 (18:03) — إصلاح كشف حساب العميل: البيان + الرصيد + تنسيق الأعمدة والتكبير (Qoder)

**المشكلة كما وردت:** (1) عمود «البيان» يجب أن يُقرأ من `ENTRY_SUB.SUB_DETAILS` وإن كان فارغاً من
`ENTRY_MAIN.DETAILS`؛ (2) عمود «الرصيد» يُحسب خطأً فيعرض رصيد **كل** العملاء، و`balance_s` يجب ألّا
يُعتمد إطلاقاً بل يُحسب من رقم الحساب المالي **مع** رقم العميل، والرصيد النهائي كذلك خطأ؛ (3) أحجام
الأعمدة ومساحاتها وترتيبها وتنسيقها تحتاج إصلاحاً وتصغير نص البيانات مع إمكانية تكبير/تصغير.

### الواجهة الخلفية — `kyApp_API/app/Http/Controllers/CustomerController.php`
1. **الاستعلام (`statement()`):** أُعيدت كتابته بجوينات ANSI على
   `ACCOUNTS.CUST c JOIN ACCOUNTS.ENTRY_SUB es ON es.ACC_NO = c.ACC_NO AND es.GIVING = c.CUST_NO
   JOIN ACCOUNTS.ENTRY_MAIN em ON em.ENTRY_NO = es.ENTRY_NO JOIN ACCOUNTS.ENTRY_TYPE et …`
   مع `WHERE c.CUST_NO = :custNo`. **جذر العلة:** الجوينة السابقة كانت على `ACC_NO` وحده، وحساب
   مراقبة واحد (مثل `12310000`) يشترك فيه آلاف العملاء، فكان الكشف يجلب حركاتهم كلها.
2. **البيان:** `NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS` — الفرعي أولاً ثم الرئيسي عند الفراغ.
3. **الرصيد:** حُذف `es.BALANCE_S` من الاستعلام نهائياً (كان لقطة على مستوى الحساب لا العميل،
   ولا تتبع الترتيب الزمني). صار الرصيد يُحسب تراكمياً من `ENTRY_MNT`:
   `$openingBalance` (ما قبل بداية الفترة) و`$periodMovement`، والسطر = `$openingBalance + $periodMovement`.
4. **الرصيد النهائي:** `$finalBalance = $openingBalance + $periodMovement` بدل أي قيمة من القاعدة.
5. **دالة مساعدة جديدة:** `normalizeStatementText()` توحّد الترميز (`ArabicEncoding::fixMojibake`)
   وتطوي المسافات (`preg_replace('/\s+/u', ' ', …)`) لأن أعمدة `VARCHAR2(250)` تأتي مبطّنة بمسافات.
6. **عقد الاستجابة:** مفتاح السطر أصبح `balance` بدل `balance_s`؛ و`summary.from_date`/`to_date`
   تُنسّقان دائماً `d/m/Y` عبر Carbon؛ و`account_title` أصبح `"{ACC_NO} - {CUST_NAME}"`.

### عميل Flutter
- `lib/features/customers/data/models/customer_statement_model.dart`: `balanceS` → **`balance`**،
  يقرأ `json['BALANCE'] ?? json['balance']` عبر `_parseDouble`.
- `lib/features/customers/presentation/screens/customer_statement_screen.dart`:
  - **تكبير/تصغير:** `TransformationController` + `InteractiveViewer` (0.5×–2.5×، خطوة 0.15) مع شريط
    عائم أسفل يسار يعرض النسبة الحيّة وأزرار (‎−‎، ‎%‎، ‎+‎، إعادة الضبط) ودعم القرص/الإصبعين.
  - **الأعمدة:** أوزان `0.85 / 1.15 / 1.0 / 3.3 / 1.2 / 1.2 / 1.45` لـ
    (السند · النوع · تأريخه · البيان · مدين · دائن · الرصيد) — البيان أخذ أوسع حصة.
  - **الخطوط:** ترويسة `9.5/10.5/11.5` وبيانات `8.5/9.5/10.5` حسب المقاس، وحشو رأسي `3.0–4.5`
    وأفقي `1.5–4.0`، وسماكة حدود `0.8`.
  - **صفّ الافتتاحي:** يُفرز بين المدين/الدائن بحسب إشارته مع إظهار الرصيد في عموده.
  - **الإجمالي:** الدائن يُطبع موجباً (حُذفت الإشارة السالبة) والأرصدة السالبة تُلوّن بالأخضر
    `0xFF15803D`.
  - **تصحيح جانبي:** تواريخ «هذا الشهر/هذه السنة» كانت مثبّتة على `DateTime(2026, 9, 8)` و
    `DateTime(2026, 1, 1)` فأصبحت `DateTime.now()`.
- `lib/features/customers/presentation/utils/customer_statement_pdf_builder.dart`: أوزان الأعمدة
  `1.5 / 1.25 / 1.25 / 3.4 / 1.05 / 1.2 / 0.95`، واستخدام `row.balance`، وشرط الافتتاحي `> 0`.

### التحقق
- **العميل 6694:** 3834 سطراً — افتتاحي 0 · مدين 76,414,928 · دائن 66,037,928 · نهائي 10,377,000 (متوازن).
- **العميل 21026 (على حساب المراقبة 12310000):** 19 سطراً فقط من حركاته هو — إثبات إغلاق تسريب
  «رصيد كل العملاء».
- **فترة 2024-05-01 إلى 2024-05-31 للعميل 6694:** افتتاحي 247,000 · مدين 12,591,725 · نهائي 12,838,725
  ورصيد أول سطر 259,000 — كلها مطابقة للحساب المستقل.
- **البوابات:** `flutter analyze` = **No issues found!** · `flutter test` = **294 ناجحاً (5 متجاوزة)** ·
  `vendor/bin/pint --dirty` = **passed** · `vendor/bin/pest` = **157 ناجحاً / 4 متجاوزة**.

**قيد بيئي مهم:** خادم MCP لأوراكل يشير إلى `192.168.0.9:1521/orcl` بينما `.env` للـ API يشير إلى
`127.0.0.1:1521/orcl`، ومجموعتا البيانات مختلفتان (443,959 مقابل 422,408 سطراً في `ENTRY_SUB`) — لذلك
كل التحقق الرقمي أُجري عبر اتصال Laravel نفسه لا عبر MCP.

**ملاحظة نطاق (لم تُعدّل):** `AccountController::getAccountStatement` و`MyStatementController`
و`WorkerController::statementEmployee/Cutter/Tailor` لا تزال تقرأ `es.BALANCE_S` بالنمط القديم —
مرشّحة لمهمة لاحقة إن طلب المستخدم.

---

## [2026-10-25 20:54] - إصلاح البيان والرصيد والرصيد النهائي في 4 كشوفات + تكبير/تصغير موحّد لكل التقارير — Qoder

استكمال مباشر للمهمة السابقة: نفس ثلاث العلل التي أُصلحت في كشف العميل نُقلت إلى بقية الكشوفات
المالية (`AccountController::getAccountStatement`, `MyStatementController::financialStatement`,
`WorkerController::fetchStatement`)، مع توحيد مكوّن التكبير/التصغير بدل تكراره في كل شاشة.

### الخلفية (Laravel API)
- `app/Support/ArabicEncoding.php`: دالة عامة جديدة
  ```php
  public static function normalizeStatementText(mixed $value): string
  // trim → fixMojibake → preg_replace('/\s+/u', ' ', …) → trim
  ```
  سُحبت من `CustomerController` (حُذفت نسخته الخاصة) وأصبحت الثلاثة الجديدة تستخدمها، فلا يختلف
  نصّ البيان بين كشف وآخر.
- `AccountController::getAccountStatement($request, $accNo)` (كشف حساب مالي + كشف الشجرة):
  - `NVL(TRIM(es.SUB_DETAILS), em.DETAILS) AS DETAILS` وحُذف `es.BALANCE_S` من قائمة الأعمدة.
  - الرصيد: `$openingBalance += $mnt` للحركات قبل الفترة، ثم `$periodMovement += $mnt` و
    `$runningBalance = $openingBalance + $periodMovement`.
  - `'description' => ArabicEncoding::normalizeStatementText(...)` و`'balance' => $runningBalance`
    و`$finalBalance = $openingBalance + $periodMovement`.
- `MyStatementController::financialStatement()`: نفس التحويل حرفياً على حساب المستخدم المرتبط
  (`ACC_NO` وحده — لا يحتاج `GIVING` لأن الحساب شخصي).
- `WorkerController::fetchStatement()`: الاستعلام صار ANSI JOINs
  (`ENTRY_SUB JOIN ENTRY_MAIN JOIN ENTRY_TYPE ON et.ENTRY_TYPE_NO = em.ENTRY_TYPE_NO`)، بلا
  `BALANCE_S`، والترتيب `ORDER BY em.ENTRY_DATE, es.ENTRY_NO, es.SEQ`؛ ومفتاح السطر صار
  `balance` بدل `balance_s`، والتفاصيل `details` عبر المساعد الجديد، والنهائي من الحركة.
  (`AccountController::getDetailedStatement`/`getGroupStatement` كانت أصلاً تحسب الأرصدة من
  الحركات، فلا تغيير فيهما.)

### عميل Flutter
- `lib/core/widgets/report_zoom_view.dart` **(جديد، 196 سطراً)**: المكوّن الوحيد للتكبير.
  ```dart
  ReportZoomView({required Widget child, double minScale = 0.5, double maxScale = 2.5, double step = 0.15})
  ```
  `Stack` فيه `Positioned.fill(InteractiveViewer(transformationController: …))` + شريط عائم أسفل
  يسار (`−` · النسبة الحيّة · `+` · إعادة الضبط)، ويستمع للـ controller فيعكس نسبة الـ Pinch أيضاً.
- طُبِّق على الشاشات الثماني التالية (كل شاشة: إضافة الاستيراد + استبدال
  `InteractiveViewer(minScale: 0.5, maxScale: 3)` بـ `ReportZoomView`):
  `customer_statement_screen.dart` · `my_financial_statement_screen.dart` ·
  `account_statement_screen.dart` · `account_group_statement_screen.dart` ·
  `account_statement_detail_screen.dart` · `worker_statement_screen.dart` ·
  `worker_work_report_screen.dart` · `worker_group_work_report_screen.dart` ·
  `my_work_statement_screen.dart`. المكرّر القديم في كشف العميل (`_zoomScale`/`_applyZoom`/
  `_resetZoom`/`_syncZoomScale` و`dispose`) أُزيل بالكامل (−136 سطراً).
- `chart_account_model.dart`: `AccountTransactionModel.balance` يقرأ `json['balance'] ?? json['BALANCE']`
  فقط — أُزيل احتياط `BALANCE_S`/`balance_s` حتى لا يعود العمود لو ظهر في رد قديم.
- `worker_statement_model.dart`: `balanceS` → **`balance`** (`json['balance'] ?? json['BALANCE']`)،
  وحُدِّث مستخدماه: `worker_statement_screen.dart` (خلية الرصيد الجاري) و
  `worker_statement_pdf_builder.dart`.
- `account_statement_report_table.dart`: أوزان الأعمدة صارت مطابقة لكشف العميل
  `0.85 / 1.15 / 1.0 / 3.3 / 1.2 / 1.2 / 1.45`، ومقاييس النص في `statementTableMetrics`
  صارت (ترويسة 9.5/10.5/11.5 · بيانات 8.5/9.5/10.5 · حشو 3.0–4.5 / 1.5–4.0) — أي أن كشف
  «حسابي المالي» و«حساب مالي» و«ميزان المجموعة» يرثونها تلقائياً.
- `worker_statement_screen.dart`: نفس الأوزان والأحجام في جدول العامل (كان 0.9/1.1/1.2/2.8…
  وبيانات 9.5/11/12) فصار الشكل موحّداً مع بقية الكشوفات.
- `test/features/accounts/account_statement_models_test.dart`: اختبار المفاتيح الكبيرة يقرأ
  `BALANCE` الآن، وأُضيف اختبار «يتجاهل BALANCE_S» يثبّت العقد الجديد.

### التحقق
- `flutter analyze` = **No issues found!** · `flutter test` = **295 ناجحاً (5 متجاوزة)**.
- `vendor/bin/pint --dirty` = **passed** · `vendor/bin/pest` = **157 ناجحاً / 4 متجاوزة**.
- **تحقق رقمي على القاعدة الحقيقية عبر اتصال Laravel (20 فحصاً، كلها ناجحة):**
  - حساب **37110001**: 368 سطراً · 340 منها بلا `SUB_DETAILS` ⇒ أخذت بيان القيد الرئيسي ·
    مجموع الحركات 4,404,400 = `final_balance` · كل رصيد سطر = التراكم الزمني · لا سطر ببيان فارغ.
  - **كشف حسابي المالي** على نفس الحساب: نفس الأرقام حرفياً (اختلاف المسار لا يغيّر النتيجة).
  - موظف **50 / حساب 12910127**: 207 سطراً · 67 منها بالـ fallback · 4,131,373 مجموع =
    `final_balance` · كل الأرصدة مطابقة · لا مفتاح `balance_s` في الرد.
- **تصحيح توثيقي:** `ALL_TAB_COLUMNS` تثبت أن أعمدة `ENTRY_TYPE` هي
  `ENTRY_TYPE_NO · ENTRY_TYPE_NAME · SOURCE_ID · SOURCE_NAME`، وأن
  `et.ETRY_TYPE_NO` تُفشل الاستعلام بـ `ORA-00904` — صُحّحت الملاحظة القديمة في
  `DBdevloping_history.md` و`db_commends.md`.

**النموذج:** Qoder · **الزمن:** 2026-10-25 20:54 · **لا commit** (لم يُطلب) · **لا DDL/DML**.

---

## [2026-10-25 22:13] تذكّر آخر اسم مستخدم — تعبئة تلقائية لحقل الدخول · Qoder Agent

الميزة المطلوبة: بعد نجاح تسجيل الدخول يُحفظ الاسم على الجهاز، ويظهر تلقائياً في حقل «اسم المستخدم»
عند فتح التطبيق أو بعد الخروج. لا تغيير على الخادم ولا على قاعدة البيانات — العمل كله محلي على الجهاز.

### القرار المعماري: الاسم في الحالة لا في الشاشة
`LoginScreen` كان سيقرأ التخزين في `initState` فيظهر الحقل فارغاً لجزء من الثانية ثم يُملأ. لذلك يُقرأ
الاسم **مرة واحدة في `checkAuthStatus()`** ويوضع في `AuthState.lastUsername`، وشاشة البداية تمنح الإقلاع
ثانيتين قبل الانتقال إلى `/login`، فيصل الاسم إلى الحقل متزامناً بلا وميض — وأيضاً يصبح الاختبار ممكناً
باستبدال مزوّد المصادقة وحده.

### ما تغيّر
- `lib/core/storage/secure_storage_service.dart`: مفتاح `ky_last_username` وثلاث دوال
  (`saveLastUsername` · `getLastUsername` · `deleteLastUsername`). النص الفارغ يحذف المفتاح، والقراءة
  تعيد `null` لا `''`. **لم يُضف المفتاح إلى `clearAll()`** — بقاؤه هو الميزة نفسها؛ ويُحذف في
  `purgeEverything()` وحده. الترميز: اسم المستخدم لاتيني (`USER_NAME_EN`) فلا يمرّ بـ `ArabicEncodingUtils.fix`.
  وفي حال أعاد الخادم الاسم العربي وحده يُحفظ كما وصل، وهو ما يطابقه `USER_NAME_AR` حرفياً عند الدخول.
- `lib/features/auth/presentation/providers/auth_notifier.dart`:
  - دالة نقية `usernameToRemember({canonical, typed})` — الاسم الرسمي يفوز، وإلا النص المكتوب بعد `trim`.
  - `AuthState.lastUsername` + `copyWith` بصيغة الإغلاق `String? Function()?` (كنمط `sessionExpiresAt`)،
    لأن `null` يجب أن يعني «امسح» لا «أبقِ القديم» حين يضغط المستخدم زر المسح.
  - `checkAuthStatus()` يقرأ الاسم في بدايته ويضعه في الحالتين (مسجّل/غير مسجّل).
  - `login()` و`loginWithBiometric()`: الحفظ **بعد النجاح فقط** عبر `_rememberUsername` الذي يكتب القرص
    ويُعيد القيمة لوضعها في الحالة — محاولة فاشلة لا تُبدّل الاسم المحفوظ.
  - `logout()` و`forceLogout()`: تمرير `lastUsername: state.lastUsername` في `AuthState` المبني من الصفر،
    وإلا لظهر الاسم بعد إعادة تشغيل التطبيق فقط لا بعد الخروج.
  - `forgetLastUsername()`: يمسح المفتاح والحالة معاً (زر المسح في الحقل).
- `lib/features/auth/presentation/screens/login_screen.dart`: تعبئة الحقل في `initState` مع وضع المؤشر
  في آخر النص، **و`ref.listen` على `AuthState.lastUsername`** يعبّئه لو وصل بعد رسم الشاشة (إقلاع بطيء
  أو فتح مباشر لـ `/login`) — القراءة في `initState` وحدها كانت تترك الحقل فارغاً حين يسبق بناءُ الشاشة
  قراءةَ التخزين. التعبئة لا تستبدل نصاً كتبه المستخدم. وأُضيف `autofillHints: [AutofillHints.username]`
  و`textInputAction: next`، ومستمع خفيف يُعيد البناء عند تغيّر «فارغ/غير فارغ» فقط (لا مع كل ضغطة)،
  وأيقونة `close_rounded` كـ`suffix` تظهر فقط عند وجود اسم محفوظ وحقل غير فارغ. كلمة المرور تبقى فارغة
  دائماً ولا تُحفظ إطلاقاً.
- **لم يُلمس** `auth_repository.dart`: قاعدة الحفظ واحدة في المتحكّم (مالك الحالة)، والمستودع بقي على
  مسؤوليته (التوكن + حزمة المستخدم + المنح).

### تصحيح جانبي غير متعلق بالميزة (كان يعطّل بوابة التحليل قبل البدء)
`flutter analyze` كان يعيد خطأين قديمين من إعادة تسمية سابقة في موديل ميزان المجموعة: الحقل
`currentBalance` حُذف وحلّ محله `balance` (النهائي) و`periodBalance` (حركة الفترة)، لكن
`group_statement_xlsx_builder.dart` بقي يقرأ القديم، و`account_group_statement_screen_test.dart` بقي
يمرّره كمعامل. صُحّح الاثنان إلى `periodBalance` (العمود المعنون «رصيد الحركة»)، وصار إجمالي ذلك العمود
`report.totals.periodBalance` بدل صفر مثبّت.

### الاختبار
- ملف جديد `test/features/auth/last_username_test.dart` (13 حالة):
  - **قاعدة `usernameToRemember`** (3): الاسم الرسمي يفوز · الفارغ يترك المكتوب · المسافات = لا شيء.
  - **`AuthNotifier.lastUsername`** (2): بقاء الاسم بعد `forceLogout` · مسح `forgetLastUsername`
    للمفتاح والحالة.
  - **مسار `login` الحقيقي** (4، بمستودع مصادقة مزيّف و`refreshBiometricStatus` معطَّل لأنه قناة منصة):
    النجاح يحفظ الاسم الرسمي في القرص والحالة · اسم رسمي فارغ يترك ما كتبه المستخدم · محاولة فاشلة
    لا تُبدّل المحفوظ · الخروج العادي يُبقيه جاهزاً لشاشة الدخول التالية.
  - **شاشة الدخول (ودجت)** (4): تعبئة تلقائية · لا تعبئة بلا اسم محفوظ · زر المسح يفرّغ الحقل ·
    تعبئة الاسم الذي يصل **بعد** بناء الشاشة عبر `ref.listen`.
- **التحقق:** `flutter analyze` = **No issues found!** · `flutter test` = **313 ناجحاً (5 متجاوزة)**
  منها **13 حالة جديدة** في ملف الميزة · لا تغيير في PHP ولا في أوراكل.

**النموذج:** Qoder · **الزمن:** 2026-10-25 22:13 · **لا commit** (لم يُطلب) · **لا DDL/DML**.

---

## [2026-10-25 22:57] - «رصيد الفترة» في ميزان الحسابات الجزئية + رصيد الحساب المالي الصحيح — Qoder Agent

**المشكلة:** عند فلترة «كشف حساب مجموعة حسابات جزئية» بفترة، كان عمود «الرصيد» يعرض **رصيد الفترة** فقط،
فيختفي الرصيد النهائي للحساب. وكان الرصيد المعروض بجانب الحساب المالي في كل قوائم الاختيار رقماً مخزّناً
متقادماً لا يطابق حركات الحساب.

**القرار التصميمي:** الرصيد النهائي لا يُقرأ من عمود مخزَّن إطلاقاً، بل من صافي حركات `ENTRY_SUB`. وقد أُثبت
ذلك قياساً على القاعدة الحقيقية: `CHART_ACC.BALANCE` يخالف مجموع الحركات في **19,126** حساباً من **20,954**،
و**1,162** حساباً له حركات ومخزّنه صفر. لذلك صار العمود المخزّن **لا يُعرض** في أي شاشة.

## الخادم — `kyApp_API`

### `AccountController::getGroupStatement()`

- شرط التاريخ خرج من `JOIN` وصار تعبيراً داخل `SUM(CASE WHEN ({$periodCond}) …)`: المرور الواحد يُنتج
  مدين/دائن الفترة + رصيد الفترة + الرصيد النهائي، وتبقى الحسابات التي لا حركة لها في الفترة ظاهرة بأصفار
  (`LEFT JOIN` لم يُلمس، و`$periodCond` يبدأ بـ `1 = 1` عند غياب الفلتر).
- أعمدة جديدة في `SELECT`: `LOCAL_NET_ALL` و`FOREIGN_NET_ALL` (بلا تاريخ) بجانب `LOCAL_NET`/`FOREIGN_NET`
  (بالفترة)، و`GROUP BY c.ACC_NO, c.ACC_NAME` بلا `c.BALANCE`.
- لكل سطر: `balance` = `LOCAL_NET_ALL + FOREIGN_NET_ALL` (النهائي)، `period_balance` = `LOCAL_NET + FOREIGN_NET`.
  و`current_balance` **حُذف** من الرد (كان ناقلاً وحيداً لقيمة `CHART_ACC.BALANCE`).
- `totals` يجمع `balance` و`period_balance`، و`data.has_period` = وجود `from_date` أو `to_date`.

### `AccountController::getChartAccounts()`

```php
$balances = $this->movementBalancesFor(array_column($data, 'acc_no'), null, null);
foreach ($data as $i => $row) {
    $data[$i]['balance'] = $balances[$row['acc_no']]['net'] ?? 0.0;
}
```

حُذف `BALANCE` من `SELECT`. هذا الـ endpoint يغذّي **كل** أماكن عرض رصيد الحساب المالي: قائمة اختيار الحساب
في «كشف حساب مالي»، وقائمة الحساب في نموذج إنشاء/تعديل المستخدم (عبر `chartAccountsProvider`)، ولوحة
الحسابات ودورة اختيار الحساب المالي — فصُحِّحت كلها بتغيير واحد.

### `AccountController::getAccountStatement()` و`MyStatementController::financialStatement()`

مركّم `$ledgerBalance` يجمع `ENTRY_MNT` لكل السطور **قبل** أي فلتر تاريخ، ويُصدر في `account.balance`؛
وأُزيل عمود `BALANCE` من استعلام الحساب في الاثنين (لم يبقَ له قارئ).

## الواجهة — Flutter

- `account_group_statement_model.dart`: `TrialBalanceRow.balance` (النهائي) + `periodBalance` (افتراضي 0)،
  و`TrialBalanceTotals.periodBalance`، و`TrialBalanceReport.hasPeriod` (من `has_period` أو وجود تاريخ)،
  و`periodLabel` الذي يفرّق بين «من … إلى …» و«من تاريخ …» و«إلى تاريخ …» و«كل الحركات».
- `account_group_statement_report_table.dart`: أعمدة ديناميكية — `showPeriod = report.hasPeriod`،
  و`balanceIndex = showPeriod ? 8 : 7`، و`columnWidths` تُبنى شرطياً، فيظهر **«رصيد الفترة»** قبل
  **«الرصيد»** مباشرةً (أزرق `0xFF1D4ED8` لتمييزه عن النهائي الأسود العريض)، وسطر المجاميع يعرض العمودين معاً.
- `account_group_statement_pdf_builder.dart`: قائمة عرض منطقية واحدة تُعكس مرة واحدة (`reversedCells`) بدل
  فهارس يدوية هشّة، مع خلية فترة شرطية وإجماليها، وتسمية العمود الأخير «الرصيد النهائي».
- `group_statement_xlsx_builder.dart`: ترويسة/صفوف/مجاميع ديناميكية، «إجمالي رصيد الفترة» عند الفلترة و
  «إجمالي الرصيد النهائي»، وتاريخ التقرير من `report.periodLabel`.
- `account_group_statement_screen.dart`: ترويسة الفترة من `periodLabel`، ونص إرشادي يشرح الفرق بين العمودين.
- `lib/core/utils/report_pdf_page.dart`: `pdfDateRangeRow` كان يطبع «كل الحركات» عند تحديد تاريخ واحد؛
  صار يطبع الطرف المحدد فقط — إصلاح مشترك يمسّ كل تقارير PDF.

## الاختبار والتحقق

- `test/features/accounts/account_statement_models_test.dart`: `period_balance` في الـ fixtures، واختبارات
  استقلال الرصيدين، والافتراضي صفر، والفترة أحادية الطرف، و`TrialBalanceReport.empty.hasPeriod == false`.
- `test/features/accounts/account_group_statement_screen_test.dart`: اختبارا ودجت يُثبتان غياب «رصيد الفترة»
  بلا فلترة وظهوره بها، مع بقاء قيم الرصيد النهائي معروضة.
- **التحقق:** `php -l` نظيف · Pint نظيف · `php artisan test` = 157 ناجحاً / 4 متجاوزة (11,947 تأكيداً) ·
  `flutter analyze` = No issues found! · `flutter test` = 308 ناجحاً (5 متجاوزة).
- **تحقق رقمي على القاعدة الحقيقية (112/112):** مجموعة `GROUP_ID = 7` (26 حساباً) — `balance` لكل سطر =
  مجموع `ENTRY_MNT` الكلي، و`period_balance` = مجموع نافذة 2025-01-01..2025-12-31، والمجاميع = مجموع
  السطور، والرصيد ثابت بين الفلترين، والحساب 41210001: الحقل = −1,801,753,216.78 = الدفتر ≠ المخزّن
  −1,493,000,510، وهو نفسه في `account.balance` وفي `GET /accounts/chart`.

**النموذج:** Qoder · **الزمن:** 2026-10-25 22:57 · **لا commit** (لم يُطلب) · **لا DDL/DML**.

---

## [2026-10-26 00:48] - إصلاح تهنيج التطبيق: ترقيم الميزان + مهلة 3 ثوانٍ + تحميل تدريجي + جدول كسول — Qoder Agent

**العَرَض:** التطبيق «يتهنّج» ويُقتل عند فتح «كشف حساب مجموعة حسابات جزئية» على نطاق واسع. سجل `flutter run`
كان صريحاً: موت على مستوى النظام لا في Dart —

```
I/Choreographer: Skipped 148 frames!
I/scudo: SizeClassAllocator64: 1095M mapped ... 5732631 allocations; remains 2628147
F/scudo: Scudo OOM: The process has exhausted 256M for size class 7120
signal 3 (SIGQUIT) → tombstoned
```

**السبب الجذري (مقاساً لا مُخمَّناً):** النطاق `acc_no=1&acc_sub=12` يضم **20,774** حساباً (منها الحساب
الجزئي 123 وحده = 20,469). كانت الشاشة تطلبه بلا ترقيم، فـ`jsonDecode` لعشرين ألف صف على الـUI isolate،
ثم يُبنى الجدول **كاملاً** داخل `Table(children: [...rows.map(...)])`: 9 أعمدة × 20,774 صفاً ≈ **186,966 خلية**،
ولكل خلية `ui.Paragraph` أصلي في محرّك الرسم. النتيجة 1.39GB محجوزة وموت حتمي — لا علاقة له بالشبكة ولا بالخادم.

**القرار:** لا علاج تجميلي (تصغير الخط أو إخفاء أعمدة) — ثلاثة تغييرات بنيوية: الترقيم على الخادم، العرض
على أقسام، والصفوف تصير كسولة.

## الخادم — `kyApp_API`

### `AccountController::getGroupStatement()`

- الاستعلام المجمّع صار في متغيّر مستقل `$innerSql` (لم يُغيَّر منطق الأعمدة ولا `$periodCond`)، وأُضيفت
  طبقة ترقيم فوقه:
  ```php
  $limit = $limitValue > 0 ? min(2000, $limitValue) : 0;   // 0 = بلا ترقيم
  if ($limit > 0) {
      $sql = 'SELECT * FROM (
                  SELECT a.*, ROWNUM AS RN FROM ('.$innerSql.') a
                   WHERE ROWNUM <= :max_row
              ) WHERE RN > :offset';
  }
  ```
  `ROWNUM` لا `OFFSET … FETCH` لأن الأول مدعوم في كل إصدارات Oracle 11g والثاني يحتاج 12c.
- **الإجماليات على النطاق كله**: استعلام ثانٍ يلتف حول `{$innerSql}` نفسه (`COUNT(*)` + `SUM(...)`)، مقيَّداً
  بـ`include_totals` ويُنفَّذ في الصفحة الأولى فقط. أُزيل تجميع الإجماليات صفاً بصف لأن الصفحة الثانية كانت
  ستضيف إجمالي النطاق مرة أخرى (تضاعف الأرقام).
- `meta` حقيقية: `total` · `page` · `limit` · `total_pages` · `has_more` · `totals_included`.
  `limit = 0` يرجّع `total` في حقل `limit` إيضاحاً بأن كل الصفوف عادت.

## الواجهة — Flutter

- **`account_group_statement_model.dart`**: `total`/`page`/`limit`/`totalPages`/`hasMore` من `meta` مع سقوط
  آمن لخادم أقدم (بلا `meta` ⇒ `total = rows.length`)، و`isPartial`، و`loadRatio`، و`appendPage()` الذي يدمج
  الأقسام ويحفظ **إجماليات الصفحة الأولى** وحقول النطاق.
- **`account_repository.dart`**: `fetchGroupStatement` يقبل `page`/`limit`/`includeTotals`؛ `limit` بلا قيمة
  تعني «كل الصفوف» ولا تُستخدم إلا في التصدير.
- **`account_group_statement_screen.dart`**:
  - `fetchDelay` افتراضياً **3 ثوانٍ**: `_scheduleLoad()` تُلغي المؤقّت والطلب الجاري (رمز `CancelToken` +
    `_runId` متزايد) وتعيد العدّ مع كل تغيير؛ أثناءها تظهر حالة «بانتظار اكتمال اختيارك» لا مؤشر تحميل كاذب.
    التقرير السابق يُمحى فوراً — أرقام نطاق قديم تحت اسم نطاق جديد أسوأ من الانتظار. زر «تحديث» وحده فوري.
  - قسم أول **1000 صف** يُعرض فوراً، ثم `_streamPages` تُضيف بقية الأقسام واحداً بعد آخر مع شريط تقدّم
    «جارٍ عرض الأقسام تدريجياً — X من Y». خطأ في قسم متأخر لا يمسح ما وصل.
  - **`kGroupStatementMaxOnScreenRows = 2000`**: تجاوزه يوقف التنزيل التلقائي ويُظهر بطاقة
    «النطاق واسع جدًا، اختر مجموعة أدق» مع **تصدير كامل من الخادم** و**عرض كل الصفوف تدريجياً** (المسار
    الثاني يتجاوز الحدّ صراحةً بـ`respectCap: false`).
- **`account_group_statement_report_table.dart`**: صار `StatefulWidget` — ترويسة مثبّتة + `ListView.builder`
  و`Scrollbar` + سطر إجمالي مثبّت. الأجزاء الثلاثة تشترك في نفس `columnWidths` وهذا وحده ما يُبقي المحاذاة
  بينها. **الارتفاع يجب أن يكون محدوداً** (الشاشة تحسبه من المساحة المتاحة بعد خصم الترويسة والتذييل)
  والانفجار بصوت عالٍ أفضل من عودة صامتة إلى بناء كل الصفوف.
- **`tree_export_menu.dart`**: `GroupStatementExportMenu.fetchFull` يجلب النطاق كاملاً (`limit` بلا قيمة)
  قبل توليد المستند، لأن المستند يجب أن يطابق النطاق لا الشاشة؛ و`buttonLabel` يحوّل العنصر من أيقونة في
  شريط التطبيق إلى زر داخل الصفحة (للبطاقة).

## الاختبار والتحقق

- `test/features/accounts/account_group_statement_model_test.dart` (6 حالات): قراءة `meta` · غيابه · `has_more: "1"`
  (نصّ أوراكل) · `appendPage` يحفظ الإجماليات ولا يجمعها · `total = 0` يحفظ الرقم المعروف · اكتمال الدمج.
- `test/features/accounts/account_group_statement_screen_test.dart`: المستودع المزيّف صار **خادماً صغيراً**
  (`scopeRows` + سقف صفحة + `Completer` للبوابة)، فاختُبرت: مهلة 3 ثوانٍ (0 طلب عند 2.9 ثانية) · تغيير ثانٍ
  يعيد العدّ لا يُصطف · قسم أول 1000 ثم إضافة القسم الثاني · حدّ 2000 يوقف التنزيل ويُظهر البطاقة · قائمة
  التصدير تُفتح من الزر · «عرض الكل» ينزّل 3 أقسام · **جدول 5000 صف لا يبني إلا المرئي** (أقل من 60 جدولاً).
- **التحقق:** `php -l` نظيف · Pint نظيف · `php artisan test` = 157 ناجحاً / 4 متجاوزة (11,947 تأكيداً) ·
  `flutter analyze` = No issues found! · `flutter test` = 326 ناجحاً (5 متجاوزة).
- **تحقق على القاعدة الحقيقية (13/13):** صفحة 1 (500) في 2.58 ثانية · `total = 20,774` · `total_pages = 42` ·
  الصفحة 2 تبدأ بعد آخر `acc_no` في الأولى وتصفير إجمالياتها · الصفحة 42 بلا `has_more` · التصدير الكامل
  (`limit=0`) يرجّع 20,774 صفاً في 3.95 ثانية · `totals.balance` = مجموع أرصدة الصفوف = `SUM(ENTRY_MNT)`.

**النموذج:** Qoder · **الزمن:** 2026-10-26 00:48 · **لا commit** (لم يُطلب) · **لا DDL/DML**. 

---

## 2026-10-26 03:11 — الكشوفات: كل صفوف الفترة، بلا سقف 50 ولا ترقيم محلي

**المشكلة كما وصفها المستخدم:** «لا يتم جلب السجلات المطلوبة حسب الفترة، ويعرض عدداً قليلاً لا يتجاوز 50 سجلاً؛ ولو حُددت فترة شهرين تظهر كأنها 30 يوماً» في:
كشف حسابي المالي · كشف حساب عمل · كشف حساب مالي · كشف حساب مالي من شجرة الحسابات · كشف حساب جاري العاملين.

**التشخيص:** لم يكن فلتر التاريخ مُتجاهَلاً — التواريخ تصل وتُفلتر صحيحة. الذي كان يقتطع هو:
1) `AccountController::getAccountStatement` — `$limit = min(200, max(10, limit ?? 50))` ثم `array_slice` بعد جلب الدفتر كاملاً.
2) `MyStatementController::financialStatement` — نفس السقف الافتراضي.
3) `AccountController::getDetailedStatement` — نفس السقف + غلاف `ROWNUM` لا يصلح بلا حد.
4) `AccountRepository.fetchAccountStatement` — `int limit = 50` يُرسل دائماً.
5) `worker_statement_screen.dart` — مُرقّم محلي `_pageSize = 15` يخفي بقية الحركات خلف زر «التالي».

**التعديلات:**

- `kyApp_API/app/Http/Controllers/AccountController.php`
  - `getAccountStatement`: `$limitRaw = query('limit')`؛ `null` أو `''` ⇒ `$limit = 0` ⇒ **بلا ترقيم**؛ الموجب يُقيَّد بـ 2000؛ `$offset` صفر عندما `$limit = 0`؛
    `$transactions = $limit > 0 ? array_slice($allEntries, $offset, $limit) : $allEntries;`؛ و`meta` يحمل `limit` (0 = الكل) و`returned` و`total_pages` و`has_more`.
  - `getDetailedStatement`: نفس المنطق، وغلاف `ROWNUM` يُبنى **فقط** عند `$limit > 0` وإلا `SELECT ACC_NO, ACC_NAME, BALANCE FROM CHART_ACC ORDER BY ACC_NO`.
- `kyApp_API/app/Http/Controllers/MyStatementController.php`
  - `financialStatement`: نفس عقد `limit` (غيابه = كل حركات الفترة) ونفس `meta`. `workStatement` لم يكن مُرقّماً أصلاً.
- `lib/features/accounts/data/repositories/account_repository.dart`
  - `fetchAccountStatement({... int? page, int? limit})` — لا يُرسل `page`/`limit` إلا عند تمريرهما صراحةً.
- `lib/features/accounts/presentation/widgets/account_statement_report_table.dart` (إعادة بناء)
  - من `StatelessWidget` يبني `Table` واحداً بعدد الصفوف إلى `StatefulWidget` كسول: `_slice()` للرأس/الافتتاحي/الإجمالي،
    و`ListView.builder(cacheExtent: 600)` للحركات داخل `SizedBox` بارتفاع مشتق (55% من الشاشة محصور 240..760) أو `rowsHeight`،
    وخريطة `_columnWidths` واحدة تُبقي الأرقام متحاذية بين الشرائح الثلاث.
- `lib/core/widgets/lazy_report_table.dart` (جديد)
  - `LazyReportTable(headerRows, footerRows, rowCount, rowBuilder, columnWidths, rowsHeight?, borderColor)` — نفس البنية الكسولة قابلة لإعادة الاستخدام.
- `lib/features/workers/presentation/screens/worker_statement_screen.dart`
  - حُذف `_pageSize`/`_currentPage`/`_buildPaginationBar`/شريط التنقل، وأُلغي معامل `isFirstPage` بعد أن لم يبقَ ترقيم؛
    `_buildStatementTableLayout` يعيد `LazyReportTable` (رأس ذهبي `0xFFD4A853` · افتتاحي `0xFF0369A1` · إجماليات `0xFFF3F4F6`) ويعرض كل صفوف الفترة.
- `lib/features/workers/presentation/widgets/worker_work_report_table.dart`
  - صار كسولاً عبر `LazyReportTable`: رأس + سطرا الإجمالي مثبّتان، الصفوف تُبنى عند ظهورها، والأعمدة الخمسة بأوزانها السابقة.

**الاختبارات المضافة:**

- `kyApp_API/tests/Feature/StatementFullPeriodTest.php` (Pest 3، على قاعدة Oracle الحقيقية):
  - «كل الحركات عند غياب limit»: `meta.limit === 0` · `meta.returned === meta.total` · `count(transactions) === total` · `has_more === false`.
  - «الترقيم فقط عند طلب حد موجب»: `limit=25` ⇒ 25 صفاً و`has_more === total > 25`.
  - «الكشف الشخصي»: مدير + `ACC_NO` مُسنَد في الذاكرة (بلا كتابة في القاعدة) ⇒ نفس المساواة.
- `test/features/accounts/account_statement_repository_test.dart`: الفترة تُرسل ولا `limit`/`page` عند عدم الترقيم · 120 صفاً تصل كاملة · الحد الصريح يُمرَّر.
- `test/features/accounts/account_statement_lazy_rows_test.dart`: 3000 حركة ⇒ أقل من 80 جدولاً حياً · آخر صف غير مبني قبل التمرير · التمرير يُظهره ·
  `LazyReportTable` مع 5000 صف يبقي الرأس والتذييل مثبّتين.

**التحقق (بوابات):** `php -l` نظيف · `vendor\bin\pint --dirty` نظيف بعد إصلاح تلقائي لملف الاختبار · `php artisan test` = **160 ناجحاً / 4 متجاوزة (11,964 تأكيداً)** ·
`flutter analyze` = **No issues found! (58.8s)** · `flutter test` = **333 ناجحاً / 5 متجاوزة**.

**ملاحظة:** قائمة «كشف عمل المجموعة» (`WorkerGroupWorkReportTable`) بقيت جدولاً عادياً لأنها تدمج خلايا اسم العامل رأسياً؛
ولا يوجد فيها اقتطاع من الخادم. أي تحويلها لاحقاً إلى كسول يتطلب حساب امتداد الدمج مسبقاً.

**النموذج:** Qoder · **الوقت:** 2026-10-26 03:11 · **لا commit** (لم يُطلب).

---

## 2026-10-27 01:50 — شاشة «معلومات البرنامج والدعم» + استفسارات الدعم (عميل + خادم)

> المرجع: خطة `App_Info_and_Support_Screen_dd420571.md`. تفاصيل القاعدة في `DBdevloping_history.md`
> و`db_commends.md`، والطلب الأصلي في `user_commends.md`، وقائمة المهام في `todo.md` بنفس الطابع الزمني.

**الهدف:** إزالة فتح إعدادات الـ API من شاشة الدخول، وإضافة شاشة معلومات برنامج بثلاثة أقسام
(معلومات الشركة · معلومات المطور · الاستفسار والدعم)، مع بوابة خفية (5 نقرات على اسم المطور خلال 3 ثوانٍ
+ كلمة السر) لإعدادات الـ API، ونموذج استفسار يُخزَّن في قاعدة البيانات ويُدار من لوحة الإدارة.

### الخادم (`kyApp_API/`)

**ملفات جديدة:**

- `database/oracle/08_app_support_tickets.sql` — جدول `ACCOUNTS.APP_SUPPORT_TICKETS`
  (13 عموداً · PK · قيد حالة · فهرسان · متسلسلة · مشغّل) مع ملف تراجع كتعليقات `DROP` في آخره.
- `app/Http/Controllers/SupportInquiryController.php` — ثلاثة أفعال: `store` (عام، يربط `USER_ID`
  إن وُجد توكن صالح وإلا يُخزَّن كزائر، ويشتق الاسم من `USER_NAME_AR` عند الجلسة) ·
  `index` (قائمة إدارية بـ `status`/`search`/`page`/`limit` و`meta` بشكل `UserAdminController`) ·
  `reply` (يحفظ `ADMIN_REPLY`/`REPLIED_BY`/`REPLIED_ON` ويحوّل الحالة إلى `answered`/`closed`).
  كل نص عربي يُكتب بـ `ArabicEncoding::toOracleSearchChars()` ويُقرأ بـ `fixMojibake()`،
  وكل الاستعلامات مربوطة (bind) بلا لصق نصي، و`ActivityLogger` للإرسال المصادق والرد دون إفشال الطلب.
- `tests/Feature/SupportInquiryTest.php` — 6 حالات (إرسال زائر ناقص/ناجح، ربط الجلسة،
  حرمان 403 للمفتاحين، رد صالح/غير صالح، وتحقّق بنيوي من `throttle:5,1` على المسار العام).

**ملفات معدّلة:**

- `app/Support/AppConfig.php` — `public const COMPANY_SERVICES = 'company_services';` مع إضافته إلى
  `DEFAULTS` و`WRITABLE_KEYS` ⇒ يدخل تلقائياً في `publicPayload()`.
- `app/Http/Controllers/AppConfigController.php` — `textLimit()` يقيّد `company_services` بـ 400 محرف
  (حد دفاعي تحت سعة العمود 500 بايت).
- `app/Support/PermissionCatalog.php` — قسم `support` قبل `my_statement` بـ `view`/`update` فقط
  (لا `create`، فالإرسال خدمة ذاتية عامة) ⇒ الكتالوج 138 ⇒ **141** كوداً.
- `database/oracle/02_ibac_seed.php` — صف `company_services` في `$settings`
  (`VALUE_TYPE='string'`, `NAME_AR='نبذة عن خدمات الشركة'`, `SORT_ORDER=145`).
- `routes/api.php` — `POST /support/inquiries` عام بـ `throttle:5,1`، و`GET /support/inquiries`
  بـ `permission:support.view`، و`PUT /support/inquiries/{ticketId}` بـ `permission:support.update`
  داخل `auth:sanctum`.
- `tests/Feature/BusinessRoutesSealedTest.php` — المسار العام الجديد في قائمة المسموح، وعيّنتا
  401/403 للمسارين المحميين.
- `tests/Feature/IbacCoreTest.php` — العدد `138` ⇒ `141` (24 قسماً).

### العميل (Flutter)

**ثوابت ونماذج مشتركة (جديدة):**

- `lib/core/constants/app_info.dart` — `kAppVersion`/`kAppBuildNumber` (مصدر واحد يُحدَّث مع
  `pubspec.yaml`) و`kDeveloperName`/`kDeveloperPhone`/`kDeveloperWhatsappUrl`، و`kAppVersionBadge`
  لشارة `v1.1.0 (2)`.
- ثوابت معدّلة: `app_colors.dart` (+`whatsapp`)، `api_constants.dart` (+`supportInquiries`)،
  `permission_codes.dart` (`support.*`/`support.view`/`support.update` + الترتيب + التسمية،
  وتحديث تعليق الترويسة إلى 141 كوداً في 24 قسماً).

**تهيئة التطبيق:**

- `app_config_model.dart` — حقل `companyServices` (مُنشئ/`defaults`/`fromJson` بمفتاحين/`copyWith`/
  `toJsonForUpdate`)، و`app_config_screen.dart` — حقل `maxLines: 3` `maxLength: 400` تحت حقل الهاتف.

**شاشة معلومات البرنامج (جديدة): `lib/features/app_info/`**

- `presentation/screens/app_info_screen.dart` — `ConsumerStatefulWidget` بمعامل `allowApiUnlock`
  (true من شاشة الدخول فقط)؛ `Scaffold` + `AppBar('معلومات البرنامج والدعم')` + `SingleChildScrollView`
  بعرض أقصى 760؛ رأس (شعار + اسم الشركة + شارة الإصدار) ثم الأقسام الثلاثة ثم تذييل.
  `_handleDeveloperUnlock`: حماية `allowApiUnlock` ⇒ `registerTap()` ⇒ `ApiPasswordDialog.show`
  ⇒ `Navigator.push(ApiSettingsScreen())` — بلا أي حالة فتح مخزَّنة، فكل دخول يحتاج 5 نقرات + الرمز.
- `presentation/widgets/app_info_card.dart` — بطاقة موحّدة (`BorderRadius` 14، حد `AppColors.border`،
  رأس 15/عريض بأيقونة داخل مربع ملوّن شفاف). `tint` من نوع `Color?` لأن `AppColors.primary` دالّة
  وقت التشغيل لا ثابت، و`surface`/`border`/`info`/`whatsapp` ثوابت.
- `presentation/widgets/company_info_section.dart` — الاسم/العنوان العربي/الإنجليزي/الموقع/الهاتف/النبذة
  من `appConfigNotifierProvider` (كاش فوري ثم مزامنة) مع حالات تحميل وفراغ وزر تحديث.
- `presentation/widgets/developer_info_section.dart` — اسم المطور (هدف النقر الخفي عبر
  `onDeveloperNameTap`) ورقم الهاتف كزر `tel:` وزر واتساب بلون `AppColors.whatsapp`.
- `presentation/widgets/support_inquiry_section.dart` — نص تعريفي + أزرار اتصال/واتساب + النموذج.
- `presentation/utils/developer_tap_unlock.dart` — منطق نقي: `required: 5`، `window: 3s`،
  `registerTap()` يعيد `true` مرة واحدة ويُصفّر العدّاد، وفجوة أطول من النافذة تُصفّره
  (التصفير يحدث عند النقرة التالية لا بمؤقّت خلفي).
- `presentation/utils/external_links.dart` — `openUrl`/`openTel`/`openWhatsapp` عبر `url_launcher`
  مع `try/catch` ورسالة «تعذّر فتح الرابط» بدل الانهيار، وبلا `canLaunchUrl`.

**ميزة الدعم (جديدة): `lib/features/support/`**

- `data/models/support_inquiry_model.dart` — قراءة مزدوجة الحالة (`ticket_id`/`TICKET_ID`)،
  `_parseInt`/`_parseString`، تمرير كل نص عبر `ArabicEncodingUtils.fix()`، و`statusLabel`/`statusColor`.
- `data/repositories/support_repository.dart` — `submitInquiry`/`fetchInquiries`/`replyToInquiry`
  مع `CancelToken`، وقراءة `message` من الغلاف، وتمييز 429 برسالة «محاولات كثيرة، حاول لاحقاً».
- `presentation/providers/support_inquiry_provider.dart` — `{submitting, submitted, errorMessage}`.
- `presentation/widgets/support_inquiry_form.dart` — تحقق محلي قبل الشبكة (اسم ≥ 2 · هاتف 7..15 رقماً ·
  رسالة 10..1000)؛ الزائر يرى الاسم/الهاتف، وصاحب الجلسة يرى الرسالة وحدها لأن الخادم يشتق الاسم من
  `USER_NAME_AR` — نفس الشرط الذي يفرضه الخادم فلا يُرفض نموذج مكتمل ولا يُقبل ناقص؛ ولوحة نجاح مع
  «إرسال استفسار آخر»، وأخطاء الخادم inline.

**شاشات معدّلة:**

- `auth/presentation/screens/login_screen.dart` — حُذف `AppBar` وأيقونة إعدادات الـ API و
  `_openApiSettingsWithGate`؛ وأُضيف `OutlinedButton.icon('معلومات البرنامج والدعم')` أسفل زر «دخول»
  مع سطر `الإصدار v$kAppVersionBadge`، يفتح `AppInfoScreen(allowApiUnlock: true)`.
- `employee_portal/.../sections/settings_section.dart` — عنصر «معلومات التطبيق» يفتح `AppInfoScreen()`
  **بدون** `allowApiUnlock`، و`trailing` صار `v$kAppVersion` بدل النص المثبّت.

**لوحة الإدارة (جديدة/معدّلة):**

- `admin/presentation/providers/support_inquiries_provider.dart` (جديد) — حالة قائمة بنمط
  `active_sessions_provider` (فلتر حالة، بحث، صفحة، `hasMore`، `CancelToken`، `_requestVersion`).
- `admin/presentation/screens/support_inquiries_screen.dart` (جديد) — `PermissionGate(supportView)`،
  شرائح حالة، بحث مؤجَّل 300 ms، سحب للتحديث، تحميل المزيد، الحالات الأربع، وتفاصيل في
  `showModalBottomSheet` بحقل رد وأزرار «تم الرد»/«إغلاق» خلف `PermissionGate(supportUpdate)`.
- `management_dashboard_screen.dart` — بطاقة سادسة «استفسارات الدعم» وإضافة `Perm.supportView`
  إلى `canAny`.
- `employee_portal/domain/portal_sections.dart` — قسم `management`: `[managementView, supportView]`.
- `home/domain/home_shortcut_catalog.dart` — نفس المرآة في `codes` حتى يبقى اختبار
  `home_catalog_test` متوافقاً مع سجل بوابة الموظف (كان يفشل قبله).

**المنصات:**

- `pubspec.yaml` — `url_launcher: ^6.3.1`.
- `android/app/src/main/AndroidManifest.xml` — `VIEW/https` و`VIEW/tel` داخل `<queries>` الحالي
  (بلا `canLaunchUrl` فلم يُحتج لإعداد iOS).

### الاختبارات

**جديدة:** `test/features/app_info/developer_tap_unlock_test.dart` (7 حالات: 5 نقرات ⇒ true،
4 ⇒ false، فجوة > 3s تُصفّر عند النقرة التالية، تصفير بعد النجاح) ·
`test/features/app_info/app_info_screen_test.dart` (5 حالات: عرض الأقسام الثلاثة ببيانات شركة
مُستبدَلة · 5 نقرات مع `allowApiUnlock: true` ⇒ حوار كلمة السر · مع `false` ⇒ لا شيء ·
إرسال فارغ ⇒ أخطاء تحقق بلا طلب شبكة) · `test/features/support/support_inquiry_model_test.dart`
(7 حالات: مفتاحان، إصلاح العربية، تسميات/ألوان الحالة).

**مضافة إلى ملفات قائمة:** `test/app_config_model_test.dart` (قراءة/كتابة `company_services`
مع القيمة الفارغة) · `test/features/auth/last_username_test.dart` (زر «معلومات البرنامج والدعم»
موجود · أيقونة `Icons.settings_outlined` وتلميحها غائبان · سطر الإصدار ظاهر).

**التحقق (بوابات):**

- `flutter analyze` = **No issues found!**
- `flutter test` = **354 ناجحاً / 5 متجاوزة — All tests passed!**
- `php -l app/Http/Controllers/SupportInquiryController.php` نظيف · `vendor/bin/pint --dirty` نظيف.
- `php artisan test --filter='SupportInquiry|BusinessRoutesSealed|IbacCore|AppConfig'`
  = **37 ناجحاً (262 تأكيداً)**.
- `php artisan route:list --path=support` = **3 مسارات** (POST عام · GET محمي · PUT محمي).

**ملاحظات تنفيذية:** إخفاء زر إعدادات الـ API لا يُغني عن الحماية الخادمية — المسار ما زال محمياً
بـ `permission:app_config.update` وكلمة السر في العميل تُتحقّق من الخادم. وإعادة تشغيل
`02_ibac_seed.php` لازمة على كل بيئة جديدة لإدراج مفتاح `company_services` وأكواد `support`.

**النموذج:** Qoder · **الوقت:** 2026-10-27 01:50 · **لا DDL/DML من العميل** · **لا commit** (لم يُطلب).

---

## 2026-10-27 02:46 — زر «معلومات البرنامج والدعم» صار أيقونة في أعلى يسار الشريط العلوي

**الطلب:** نقل زر «معلومات البرنامج والدعم» من بطاقة شاشة الدخول إلى أعلى يسار الشريط العلوي
وإظهاره أيقونةً فقط بلا نص.

### الملفات المعدّلة

- `lib/features/auth/presentation/screens/login_screen.dart`
  - عاد `AppBar` إلى الشاشة لكنه شريط أيقونة واحدة: `backgroundColor: AppColors.background`,
    `elevation: 0`, `scrolledUnderElevation: 0`, `surfaceTintColor: Colors.transparent` — فلا كتلة
    بصرية فوق الشعار. الشاشة عربية RTL، فخانة `actions` تُرسم على **اليسار** وهو الموضع المطلوب.
  - `IconButton(Icons.info_outline_rounded)` بـ `tooltip: 'معلومات البرنامج والدعم'` ويستدعي
    `_openAppInfo()` نفسه (لا منطق مكرّر).
  - حُذف `OutlinedButton.icon` العريض من البطاقة (وكان يحمل `Icons.support_agent_rounded`).
  - **بقي** سطر `الإصدار v$kAppVersionBadge` أسفل زر «دخول»: المطلوب نقل الزر لا حذف معلومة النسخة،
    فحُذف تباعد واحد (`SizedBox(height: 8)`) وأُبقي النص مكانه.
- `test/features/auth/last_username_test.dart`
  - الحالة أُعيدت صياغتها إلى «أيقونة معلومات البرنامج والدعم في الشريط العلوي بلا نص» وتؤكد الآن:
    `Icons.info_outline_rounded` موجود مرة واحدة · `find.byTooltip('معلومات البرنامج والدعم')` موجود ·
    `find.text('معلومات البرنامج والدعم')` **غائب** (أيقونة فقط) · `Icons.support_agent_rounded` غائب ·
    الأيقونة داخل `find.byType(AppBar)` عبر `find.descendant` لا داخل البطاقة · أيقونة
    `Icons.settings_outlined` وتلميحها ما زالا غائبين · سطر النسخة ما زال ظاهراً.

### ما لم يتغيّر

- بوابة إعدادات الـ API: ما زالت خمس نقرات على اسم المطور خلال ثلاث ثوانٍ في `AppInfoScreen` ثم
  `ApiPasswordDialog` — لا طرح ولا مسار مباشر من الشريط، ولا حالة فتح مخزَّنة.
- عنصر «معلومات التطبيق» في إعدادات الموظف يفتح الشاشة نفسها بـ `allowApiUnlock: false` كما هو.
- لا تغيير في الخادم ولا في قاعدة البيانات ولا في الأصول.

### التحقق

- `flutter analyze` = **No issues found!** (93.5s).
- `flutter test test/features/auth/last_username_test.dart test/features/app_info` = **26 ناجحاً**.
- `flutter test` (كامل) = **354 ناجحاً / 5 متجاوزة — All tests passed!**

**النموذج:** Qoder · **الوقت:** 2026-10-27 02:46 · **لا DDL/DML** · **لا commit** (لم يُطلب).

---

## 2026-10-27 03:10 — قسم «معلومات الشركة» صار بطاقة هوية رسمية تُغذّيها قاعدة البيانات

**الطلب:** تحسين قسم «معلومات الشركة» في شاشة «معلومات البرنامج والدعم» ليعرض الاسم والعنوان والموقع
ومعلومات التواصل ولمحة عن الخدمات، مع جلْب كل القيم من قاعدة البيانات.

### العميل — `lib/features/app_info/`

- `presentation/widgets/company_info_section.dart` — **إعادة كتابة** القسم (365 سطراً بدل 190):
  - `_CompanyData`: كائن قيمة يحمل الحقول السبعة مطبَّعة (`trim`) مع `isEmpty` واحدة تقرّر حالة الفراغ،
    فلا تتكرّر شروط «هل الحقل فارغ؟» في كل مكان.
  - `_CompanyDetails`: كتلة الهوية ثم الشبكة ثم لوحة الخدمات.
    - **كتلة الهوية:** شريط عمودي بلون `AppColors.primary` على جهة البداية (`BorderDirectional(start:)`
      — اليمين في RTL) ثم `company_name` بخط 14.5 عريض و`company_name_en` تحته بخط 10.5 لاتيني
      بتباعد حروف — ترتيب الترويسة المطبوعة نفسها.
    - **الشبكة:** `_grid()` تختار عمودين عند `maxWidth >= 460` وعموداً واحداً دونه. في وضع العمودين
      تُبنى صفوفاً داخل `IntrinsicHeight` + `Row(stretch)` + `Expanded` كي يتساوى ارتفاع بطاقتي الصف
      (بطاقة العنوان أطول بسبب سطرها الإنجليزي، وبدون التساوي تبدو الشبكة مكسورة).
  - `_CompanyTile`: بطاقة بيان واحدة على خلفية `AppColors.surfaceSubtle` — أيقونة وتسمية في الأعلى ثم
    القيمة، مع رمز إجراء في الطرف (خريطة/رابط/اتصال) ولون `AppColors.accent` حين تكون فعّالة.
    التسمية `maxLines: 1` مع `ellipsis` فلا تتجاوز على أي عرض.
  - `_ServicesPanel`: لوحة مصبوغة (`primary` بشفافية 0.055 + حدّ 0.16) بأيقونة `checkroom_rounded`
    وعنوان «نبذة عن خدماتنا» ونص `company_services` بتباعد أسطر 1.75.
  - `_CompanyEmptyState`: حالة الفراغ السابقة كما هي (لا بيانات أصلاً) لكنها صارت widget مستقلة.
  - حُذف بناء الأسطر القديم، وحُذفت فقرة «خدماتنا» المنفصلة (اندمجت في اللوحة).
- `presentation/utils/external_links.dart`:
  - أُضيف `openMap(context, address)`: يفتح
    `https://www.google.com/maps/search/?api=1&query=<العنوان>` بعد `Uri.encodeComponent`.
    لا إحداثيات ولا عمود lat/long جديد: البحث النصي يفتح الخريطة على أقرب مطابقة.
    الرابط يمرّ عبر `_launch` المشتركة (رسالة فشل واحدة موحّدة) ويستفيد من `scheme="https"` المعلَن
    مسبقاً في `<queries>` على أندرويد.
  - `openTel` صار يبني رابطه من `buildTelUri(phone)` — دالة نقية تُطبّع الرقم: رقم `APP_SETTINGS`
    محلي (`780154000`) كان يتحوّل إلى `+780154000` أي رقم لا وجود له. التطبيع يحذف `00` البادئة
    والصفر المحلي، ويترك الرقم الذي يحمل `967` أو 12 خانة كما هو، ويعيد `null` حين لا أرقام.
    (`kDeveloperPhone` = 967776422777 يمرّ سليماً كما هو، وهو مُثبَت باختبار.)
- `presentation/widgets/app_info_card.dart` — حُذف `AppInfoRow` بالكامل (171 سطراً): آخر مستهلك له
  كان القسم القديم، وتركه كان كوداً ميتاً. بقيت `AppInfoCard` وحدها.
- `presentation/screens/app_info_screen.dart` — `_header()` لم يعد يأخذ اسم الشركة ولم يعد يرسمه:
  الشعار ثم شارة الإصدار فقط، لأن البطاقة تحته تعرض الاسم فصار يُرسم **مرة واحدة** في النافذة
  (كان يُرسم مرتين على مسافة 20 بكسل). التذييل ما زال يستعمل الاسم في سطر الحقوق.

### العميل — الاختبارات

- `test/features/app_info/app_info_screen_test.dart`:
  - `useLargeSurface` → `useSurface(tester, [Size])`، و`pumpScreen` صار يقبل `config` و`surface`،
    و`fullConfig()` مرجعاً لكل الحقول مضبوطة.
  - الحالة الأولى صارت أدق: الاسم `findsOneWidget` (لا `findsWidgets`) + تسميات «العنوان»
    و«الموقع الإلكتروني» و«الهاتف» و«نبذة عن خدماتنا» + الاسم الإنجليزي من القاعدة.
  - **3 حالات جديدة:** الحقول الفارغة لا ترسم بطاقات ولا لوحة خدمات · بلا أي بيانات تظهر حالة الفراغ
    (لا بطاقة صامتة) · على شاشة 360px تنزل الشبكة إلى عمود واحد بلا استثناء تجاوز
    (`tester.takeException()` = null) مع تأكيد تراكم البطاقات رأسياً.
- `test/features/app_info/external_links_test.dart` — **ملف جديد**: 6 حالات لتطبيع رقم الهاتف
  (محلي 9 خانات · صفر بادئة · `967` مسبقاً · `+`/مسافات/`00` · `kDeveloperPhone` · بلا أرقام).

### قاعدة البيانات (بلا DDL)

- `ACCOUNTS.APP_SETTINGS` → `company_services`: كانت فارغة (0 محرف) فكانت اللوحة تُخفى دائماً.
  كُتبت نبذة واقعية 140 محرفاً عبر مسار التطبيق نفسه (`SettingsStore::set()` ⇒
  `ArabicEncoding::toOracleSearchChars()` ثم `UPDATE`)، وتحقّقت القراءة العكسية
  (`ROUND_TRIP_OK=1`, `PAYLOAD_LEN=140`). السقف 400 محرف (العمود 500 بايت) كما هو.
- `company_website` بقي فارغاً: لا رابط موقع مسجَّل ولم نخترع واحداً؛ بطاقته لا تُرسم حتى يُكتب.

### ما لم يتغيّر

- شاشة إعدادات التطبيق وحقولها (`company_services` بحد 400) — لا تعديل عليها.
- الخادم: لا ملف PHP تغيّر (لا `AppConfig`، لا متحكم، لا مسار)؛ القراءة ما زالت `GET /app-config` العامة.
- بوابة النقر الخمسي على اسم المطور و`allowApiUnlock` كما هي، وقسم المطور والاستفسار كما هما.
- الأصول والصلاحيات واللغة: لا تغيير.

### التحقق

- `flutter analyze` = **No issues found!** (17.5s).
- `flutter test` (كامل) = **363 ناجحاً / 5 متجاوزة — All tests passed!** (كان 354؛ +9 حالات).
- `flutter test test/features/app_info` = **21 ناجحاً** (15 شاشة + 6 تطبيع رقم).
- `php artisan test --filter=AppConfig` = **9 ناجحاً (33 تأكيداً)** · `IbacCore` = **16 (77)** ·
  `BusinessRoutesSealed` = **6 (95)**.

**النموذج:** Qoder · **الوقت:** 2026-10-27 03:10 · **لا DDL** · **DML: صف واحد في `APP_SETTINGS`** ·
**لا commit** (لم يُطلب).


---

## 2026-10-28 08:49 — قسم التفصيل: استعراض فاتورة تفصيل كامل + ثلاث واجهات أولية (Flutter + Laravel)

### الخادم (Laravel)

- `kyApp_API/app/Http/Controllers/TailoringController.php` — متحكم جديد **قراءة فقط**، مغلّف الردود القياسي،
  والاستعلامات كلها مربوطة (bind) بلا لصق نصي:
  - `index` قائمة مُجمَّعة `GROUP BY BILL_NO, YEAR` بالأحدث أولاً، مع البحث في
    (رقم الفاتورة · الرقم اليدوي · اسم العميل · الهاتف · اسم المستفيد عبر `EXISTS`) والفلترة الزمنية والتصفح.
  - `show` يعيد `header` + `models[]` (الموديل يحمل المستفيد والمقاسات والمواصفات) وكل موديل يحمل
    `pieces[]` (القطعة تحمل القماش والقصّاص والخيّاط وأعلام الإنجاز) — التجميع في PHP على صفوف الـ VIEW.
  - `movements` سجل الحركة من `CUTING_TRANSD` + `ORDSTATE` بأرقام القطع التي يحملها العميل فعلاً.
  - `reference` تسميات المقاسات من `GENERAL_LABELS_CODING` + الأنواع + الأشكال + الحالات.
  - `activity` صف واحد في `APP_USER_ACTIVITY` فقط، ولا يمسّ أي جدول إرث.
- حجب خانات المال: عند غياب `tailoring.payments_view` يعود `payment = null` من الخادم وتُعاد المفاتيح `null`
  صراحةً — الحجب على الخادم لا في الواجهة وحدها.
- `PermissionCatalog.php` ثلاثة أكواد في قسم `tailoring` (`payments_view` · `export` · `progress`) ⇒ **144**،
  و`IbacCoreTest` و`BusinessRoutesSealedTest` محدّثان.
- `routes/api.php` خمسة مسارات، كلها خلف `auth:sanctum` + `permission:` وبقيود regex على رقم الفاتورة والسنة.
- الطُعم: «لا يوجد» في `TAILOR_NAME1` تُطبَّع إلى `null` على الخادم (`normalizeTailorName`).

### العميل (Flutter)

- ميزة جديدة `lib/features/tailoring/`:
  - `data/models/` — `cutting_bill_summary_model` · `cutting_bill_detail_model` · `cutting_model_item` ·
    `cutting_piece_item` · `cutting_movement_model` · `tailoring_reference_model` · `tailoring_parse`.
  - `data/repositories/tailoring_repository.dart` — قراءة فقط + `TailoringException(notFoundInView)` لتمييز
    404 «خارج نطاق الـ VIEW» عن خطأ الشبكة، و`recordActivity` لا يُفشل الإجراء.
  - `presentation/providers/tailoring_providers.dart` — القائمة (`NotifierProvider` بحث مؤجَّل + حارس بصمة
    الطلب + `CancelToken`)، التفصيل والحركة (`FutureProvider.autoDispose.family`)، والمرجعيات.
  - `presentation/screens/` — لوحة القسم · قائمة الفواتير (ثلاثة أنماط: استعراض/منتقي تعديل/منتقي متابعة) ·
    شاشة الاستعراض · النماذج الأولية الثلاثة.
  - `presentation/widgets/` — 14 ودجت: ترويسة الفاتورة، بطاقة العميل، بطاقة الدفع، شريط الموديلات،
    شبكة المقاسات، لوحة المواصفات، جدول الأقمشة، جدول الحركة، خط السير، بطاقة القائمة، نموذج الإدخال،
    شريط الحفظ الأولي، بطاقة القسم/الشريحة، وبطاقة الإجراء.
  - `presentation/utils/cutting_bill_pdf_builder.dart` — PDF بالترويسة الموحدة (`report_pdf_page` +
    `report_pdf_arabic` + `report_pdf_fonts`) وجداول بأعمدة معكوسة وتذييل توقيعات.
- الربط بالواجهة الرئيسية: `tailoring_section.dart` يعيد `TailoringDashboardScreen`، وأربع بطاقات جديدة
  (`tailoring.bills` مفعّلة افتراضياً، `tailoring.add`, `tailoring.edit`, `tailoring.progress`)،
  وإزالة `underDevelopment` من `tailoring.section`.
- سجلات التدقيق: `tailoring.bill_viewed` عند الفتح، `tailoring.bill_printed` و`tailoring.bills_exported`
  عند الطباعة والتصدير — كلها في `APP_USER_ACTIVITY` بلا أي كتابة في جداول الإرث.

### مزالق حقيقية أُصلحت في هذه الجولة

1. **`AppColors` ديناميكية:** `primary`/`accent`/`background`/`textPrimary`/`textSecondary`/`primaryDark`
   هي `static get` تقرأ `AppPalette` وقت التشغيل، فلا تصلح داخل تعبير `const` ولا كقيمة افتراضية لمَعامل
   `const`. أُزيل `const` من 15 ملفاً (54 موضعاً) وحُوّل `accent`/`color` في `TailoringSectionCard` و
   `TailoringChip` إلى `null` مع بديل وقت البناء.
2. **`AsyncValue.valueOrNull` غير موجودة في riverpod 3.3.2** ⇒ استُخدمت `.value`.
3. **`CuttingBillKey key` يتعارض مع `Widget.key`** ⇒ حقل الهوية اسمه `billKey` في الشاشات الثلاث.
4. `ReportZoomView` في `core/widgets/` لا `core/utils/`.
5. **مرآة الصلاحيات:** الأكواد الثلاثة أُضيفت إلى `Perm` ولم تُضف إلى `allPermissionCodes`، فأسقطها
   `home_catalog_test` — أُضيفت في موضعها من ترتيب الكتالوج.
6. **مجموعة الافتراضيات** ارتفعت إلى 15 `defaultOn` (بعد `tailoring.bills`) و16 نشِطة في أول تشغيل،
   فحُدِّث `home_notifier_test`.

**النموذج:** Qoder · **الوقت:** 2026-10-28 08:49 · **لا commit** (لم يُطلب).


---

## 2026-10-29 01:27 — قسم التفصيل: إعادة تنسيق شاشة استعراض الفاتورة في صفوف أفقية

### المشكلة كما وصفها المستخدم

تقليل الارتفاع نُفّذ سابقاً بتوزيع الحقول «متدفّقاً» بعرض نصّها، فظهرت الحقول في صفوف غير
متناظرة ولا واضحة الحدود، وشملت المواصفاتُ هويةَ الموديل، وعُرضت كلمة «بلا مستفيد»، وكانت
الأقمشة والحركة بطاقات على الجوال.

### ما تغيّر في العميل (Flutter)

- `presentation/widgets/tailoring_section_card.dart`
  - `TailoringInfoGrid` أُعيد بناؤها: عدد أعمدة ثابت لكل صف يُحسب من العرض، خانات
    `Expanded` متساوية، إطار خارجي وفواصل رأسية وأفقية رقيقة، وخيار `singleRow` لصف واحد
    على الشاشات العريضة.
  - `TailoringInfoTile` صارت «تسمية فوق / قيمة تحت» بسطر ثابت لكل منهما (قصّ بثلاث نقاط)،
    فترتفع الخانات المتجاورة على خطّ واحد.
- `bill_header_card.dart` — شريط هوية + عشرة حقول في صف واحد + البيان في خانة كاملة.
- `bill_customer_card.dart` — ست خانات في صف واحد (`singleRow`).
- `bill_payment_card.dart` — عشرة أرقام في صف واحد، وأُزيلت شارة الرصيد المكرّرة.
- `model_selector_strip.dart` — سطر لكل موديل: رقم · نوع · مستفيد · قطع · مرحلة · علامة
  اختيار. حُذفت كلمة «بلا مستفيد» وحُذفت بطاقات العرض العريضة والتمرير الأفقي.
- `model_measurements_grid.dart` — اثنا عشر مقياساً في صف واحد من خانات مسوّرة.
- `model_specs_panel.dart` — مواصفات القطعة فقط (نوع الرقبة/الكم/الكباك/الجبزور/الأزرار،
  الجيوب، جيب الجوال والقلم، الحجازي) وأُزيلت هوية الموديل، والأكواد الرقمية في حاشية سطر.
- `model_fabrics_table.dart` / `model_movements_table.dart` — الجدول هو الشكل الوحيد في كل
  الأحجام (حُذفت `_PieceCard` و`_MovementCard`)، مع تمرير أفقي عند الحاجة.
- `data/models/cutting_model_item.dart` — تسميات المواصفات صارت وصفية: «نوع الرقبة»،
  «نوع الكم»، «نوع الكباك»، «نوع الجبزور»، «نوع الأزرار»، «نوع الحجازي».
- `presentation/screens/cutting_bill_view_screen.dart` — الأقسام 1–4 بعرض الصف كاملاً
  (سطر واحد لكل قسم)، ثم المقاسات والمواصفات جنباً إلى جنب، ثم الأقمشة والحركة.

### إصلاحات كود مقطوع وُجدت أثناء العمل

1. `CuttingBillHeader.branchLabel` كان تعليقه موجوداً وبقيّة السطر محذوفة، فمنع التجميع —
   أُعيد تعريفه: `branchNo == null ? '—' : '$branchNo'`.
2. `_kvRow('الرقم اليدوي', header.manualLabel)` في مولّد PDF كان ينادي دالة بأربعة معاملات
   بمعاملَين — أُكمل إلى `('الرقم اليدوي', header.manualLabel, 'السنة', '${header.year}')`.
3. `const TextStyle(color: AppColors.textSecondary)` غير صالح لأن `textSecondary` ديناميكي —
   أُزيل `const` من أربعة مواضع.

### الاختبارات

- `cutting_bill_view_screen_test.dart`: صف واحد لكل من الفاتورة والعميل والدفع (إحداثي رأس
  متساوٍ)، غياب كلمة «بلا مستفيد»، وجود «نوع الموديل»، ميزانية ارتفاع 650 بكسل، ولا تجاوز
  على عرض 360 بكسل.
- النتيجة: 47 اختبار تفصيل ناجح · الحزمة الكاملة 410 ناجحاً و5 متجاوزة · `flutter analyze`
  بلا ملاحظات.

**النموذج:** Qoder · **الوقت:** 2026-10-29 01:27 · **لا commit** (لم يُطلب).


---

## 2026-10-29 02:05 — التفصيل: تغطية اختبار قائمة الفواتير وأزرار الطباعة/التصدير

- `test/features/tailoring/cutting_bills_list_screen_test.dart` (جديد) — مستودع وهمي يخدم
  صفحة أو خطأً ويسجّل آخر بحث: يثبت عرض «رقم / سنة» والعميل والعدّ والصافي، وأن البحث
  لا يُرسل قبل 300 مللي ثانية، وأن نطاقات (اليوم/الأسبوع/الشهر/السنة/الكل) داخل لوحة
  «فلترة بالتاريخ»، وأن الفراغ يشرح حدّ الـ VIEW، وأن الخطأ يعطي «إعادة المحاولة».
- `test/features/tailoring/cutting_bill_view_screen_test.dart` — أُضيف `grants` إلى مساعد
  الضخّ وحالتان: `tailoring.view` وحدها ⇒ زرّا الطباعة والتصدير غير موجودين، ومع
  `tailoring.print`/`tailoring.export` يظهران. (اختبار واحد أُعيد تقسيمه إلى اختبارين لأن
  إعادة ضخّ `ProviderScope` داخل الاختبار نفسه تُبقي المزوّد القديم.)
- النتيجة: 57 اختبار تفصيل ناجح · 418 في الحزمة الكاملة (5 متجاوزة) · `flutter analyze`
  بلا ملاحظات · Pest `Tailoring` 11 ناجحاً / 217 تأكيداً.
- ملاحظة مسجّلة: فشل `AccountTreeExportTest`/`AccountTreeLazyTest` في الحزمة الكاملة سابق
  ومستقل — تثبيت أعداد صفوف حيّة على CHART_ACC، ومدة كل اختبار 4–24 دقيقة.

**النموذج:** Qoder · **الوقت:** 2026-10-29 02:05 · **لا commit** (لم يُطلب).

---

## 2026-10-29 04:34 — قسم «مقاسات العملاء»: ثلاث شاشات من واجهة التفصيل إلى العميل

**المسار الجديد:** لوحة العملاء ⇒ «مقاسات العملاء» ⇒ قائمة العملاء ⇒ موديلات العميل ⇒ شاشة المقاسات.
كل البيانات من `ACCOUNTS.CUTTING_SALES_BILL_VIEW` عبر المسارات الجديدة
`/customers/measurements*`، ولا كتابة في أي جدول إرث.

### الطبقات الجديدة في `lib/features/customers/`

- `data/models/measurement_customer_model.dart` — `MeasurementCustomer` (رقم العميل، الاسم،
  الهاتف، الحساب، عدد الفواتير والموديلات، آخر تاريخ) و`MeasurementCustomerPage`.
- `data/models/measurement_model_ref.dart` — `MeasurementKey` الرباعي بمساواة على `id`،
  `MeasurementModelRef` مع `keyOf(custNo)` (رقم العميل يُمرَّر من القائمة ولا يُشتق من الصف)،
  `MeasurementSibling` الذي يقرأ علامة `selected` كـ **bool** (قراءة رقمية بحتة كانت تجعل كل
  خيار غير محدد)، و`MeasurementSubject(custNo, detail, siblings)`.
- `data/repositories/customer_measurement_repository.dart` — الطبقة الوحيدة التي تلمس Dio،
  وخطؤه `MeasurementException` يحمل `notFoundInView` كما في قسم التفصيل: الفاتورة خارج الواجهة
  حالة تُشرح، لا خطأ رابط.
- `presentation/providers/customer_measurement_providers.dart` — `Notifier` للقائمة،
  و`NotifierProvider.family` للموديلات (بحث عميل «أ» لا يظهر في شاشة عميل «ب» عند الرجوع)،
  و`FutureProvider.autoDispose.family` للتفصيل لأن المقاسات بيانات شخصية فلا تبقى في الذاكرة
  بعد إغلاق الشاشة. البحث مؤجَّل 300ms، و`CancelToken` عند التصريف، وبصمة طلب تشمل رقم العميل.

### الشاشات والودجتات

- `measurements_customers_screen.dart` — بحث واحد يغطي الاسم والهاتف واسم المستفيد (الخادم يوسّع
  المطابقة إلى صاحب المستفيد)، وأربعة ترتيبات، وشريط عدّ، وتحديث بالسحب.
- `customer_models_screen.dart` — موديلات العميل الأحدث أولاً مع نطاق زمني (نفس لوحة النطاقات
  الجاهزة في قائمة الفواتير) وبحث المستفيد/النوع/رقم الفاتورة وتحميل لا نهائي.
- `measurement_view_screen.dart` — الأقسام الأربعة بترتيبها: بيانات العميل والمستفيد · المقاسات ·
  مواصفات الموديل · الأقمشة. `ReportZoomView` للتكبير بالإصبع والأزرار، وزر فلترة يظهر ويخفي
  الشريط (مع نقطة على الزر حين مرشّح مطبّق والشريط مغلق)، وطباعة وتصدير خلف `PermissionGate`
  بأكواد المقاسات، وتحديث بـ `ref.invalidate`، وحارس `_busy` يمنع الضغط المزدوج.
- `widgets/measurement_subject_card.dart` — العميل والمستفيد في كتلة واحدة: الطلب كان «بيانات
  العميل/المستفيد» لا قسمين، ومن تُؤخذ مقاساته قد لا يكون صاحب الفاتورة.
- `widgets/measurement_filter_bar.dart` — `MeasurementFilters` غير متغيّر بمساواة صريحة، ومفاتيح
  الأقسام الثلاثة، ومنتقي موديلات الفاتورة، وبحث الأقمشة. **لا** مفتاح «الخانات الفارغة» هنا:
  بطاقة المقاسات تحمل هذا المفتاح في شريط عنوانها، ومصدران لحالة واحدة يعنيان شاشة تناقض نفسها.
  الحقل يحتفظ بآخر ما أرسله (`_lastEmitted`) حتى لا يأكل إعادة-الضبط فراغ «قماش صيفي».
- `utils/customer_measurement_pdf_builder.dart` — ترويسة التقارير الموحّدة، وجدول مقاسات بأربعة
  أزواج في الصف، وأقمشة **بلا عمود سعر**، وتذييل توقيع. يطبع السجل كاملاً: المرشّحات أداة قراءة،
  وطباعة سجل ناقص لأن فلترًا نسيانه يجعل الخطأ في الورق لا في الشاشة.

### إعادة استخدام بلا نسخة موازية

النماذج `CuttingBillDetail`/`CuttingModelItem` وشرائح `ModelMeasurementsGrid` و`ModelSpecsPanel`
و`ModelFabricsTable` كلها من قسم التفصيل — والخادم يعيد المفاتيح نفسها عمداً. أُضيف إلى
`ModelFabricsTable` وسم `showPrice` بقيمة افتراضية `true` فلم يتغيّر سلوك شاشة الفاتورة؛ الشاشة
الجديدة تمرّر `false` لأن عموداً فارغاً دائماً أسوأ من عمود مفقود.

### الصلاحيات والاختصارات والاختبارات

- `lib/core/constants/permission_codes.dart` — ثلاثة أكواد `customers.measurements_*` في `Perm`
  و`allPermissionCodes` و`permActionLabels`، وتحديث رأس الملف إلى 147 كوداً و25قسماً (كانت 24
  قديماً قبل وحدة الكشوفات الشخصية).
- بطاقة `customers.measurements` في كتالوج اختصارات الرئيسية (`defaultOn: true`) مع
  `openCustomerMeasurements` كدالة عليا ليبقى الكتالوج `const`، وبطاقة محروسة في لوحة العملاء.
- اختبارات جديدة: `test/features/customers/customer_measurement_models_test.dart` (12) و
  `customer_measurement_repository_test.dart` (8) و`measurement_view_screen_test.dart` (12).
- حرّاس مُحدَّثة: `home_catalog_test` (16 افتراضية، `customers.*` = 9) و`home_notifier_test`
  (17 نشطة) — والبطاقة بكود أدقّ من `customers.view` فلم تتغيّر قائمة «من يملك customers.view».
- ملاحظة اختبارية: حالتا المنح فُصلتا في اختبارين لأن إعادة ضخّ `ProviderScope` داخل الاختبار
  نفسه تُبقي المزوّد القديم — نفس ما وُثّق في اختبارات التفصيل.

**النتيجة:** `flutter analyze` بلا ملاحظات · `flutter test` 450 ناجحاً و5 متجاوزة · Pest
`CustomerMeasurement` 9 اختبارات / 146 تأكيداً · Pest `Tailoring` 11 / 217 · `IbacCore` +
`BusinessRoutesSealed` 22 / 187 · `pint --dirty` passed.

**النموذج:** Qoder · **الوقت:** 2026-10-29 04:34 · **لا commit** (لم يُطلب).

---

## 2026-10-29 06:47 — مقاسات العملاء (مراجعة): منبثقة الاختيار + تباين عالٍ + حقول مضبوطة

### الملاحة: شاشة أقل، نافذة أكثر

- حُذفت `customer_models_screen.dart`: قائمة الموديلات مرحلة وسيطة بين العميل والتقرير، فجعلها
  شاشة كاملة كان يحوّل كل نظرة على موديل إلى رحلة «أمام ثم خلف».
- `widgets/measurement_model_picker_sheet.dart` يفتح من `measurements_customers_screen.dart`
  بـ `showModalBottomSheet` + `DraggableScrollableSheet` (0.88 من الشاشة) ويُرجع
  `MeasurementModelRef` نفسه، فيُبنى مفتاح الشاشة التالية بـ `keyOf(custNo)` — رقم العميل من
  الشاشة المستضيفة لا من الصف.
- داخل النافذة: رأس بمقبض سحب وإغلاق، بحث مؤجَّل، شريحتا ترتيب ونطاق، عدّاد نتائج، تحميل لا
  نهائي، وحالات تحميل/خطأ/فراغ تشرح نفسها.
- لوحة النطاق الزمني صارت مشتركة: `widgets/measurement_range_sheet.dart` (كانت نسخة خاصة بالشاشة
  المحذوفة)، وحدود `showDatePicker` تصحّح `initialDate` الخارج عن الحدود — انهيار هذا السجل
  موثّق سابقاً في التطبيق.

### التصميم: لوحة للميزة بدل ألوان باهتة متفرقة

`widgets/measurement_kit.dart` هو مصدر الشكل الوحيد لهذه الشاشات:

- `MeasurementSectionCard`: ترويسة بتدرج لوني فعلي للأيقونة والعنوان (لا شريط بشفافية 7%)،
  وظل خفيف، وسطر ثانوي يحمل اسم العميل/المستفيد فلا تكرّر الحقول ذلك.
- `MeasurementField`: التسمية `textSecondary` بوزن 700، والقيمة `textPrimary` بوزن 800 وأكبر
  حجمًا؛ الفراغ يبقى باهتاً عمداً حتى لا تنافس الخانة الغائبة الموجودة.
- `MeasurementFieldGrid`: أعمدة متساوية بفواصل رأسية وأفقية بـ 1px — «الفاصل بين الحقول» مطلوب
  نصاً ولا يُترك للفراغ.
- `MeasurementBadge` بوضع `solid` للحالة الحالية، و`MeasurementGroupLabel` لترويسات المجموعات.
- البطاقات في القائمتين (العملاء والموديلات) صارت بشريط لوني جانبي + قيمة داكنة + شارة مرحلة.

### الحقول: ما يُعرض وما يُحذف

- محذوف نهائياً من الشاشة والمطبوع: العنوان، مجموعة الحساب، شكل الموديل، رقم الموديل، الفرع
  (واختبار يثبت غيابها: «الحقول المحذوفة لا تظهر»).
- هوية العميل/المستفيد ثلاث مجموعات: العميل (اسم، رقم، هاتف — الهاتفان في خانة، حساب) ·
  المستفيد والموديل (مستفيد، نوع، قطع، مرحلة ملوّنة) · الفاتورة والطلب (تاريخ، يدوي، حالة،
  استحقاق، مرجع، بيان).
- المواصفات = خصائص الثوب فقط: نوع الرقبة، نوع الكم، نوع الكباك، الجيوب، نوع الجبزور، نوع
  الأزرار، عدد الأزرار، جيب الجوال، جيب القلم، نوع الحجازي، والملاحظة في صندوق مميّز. لا نوع
  موديل ولا شكل ولا أرقام أشكال.
- الأقمشة `measurement_fabrics_panel.dart`: بطاقة لكل قماش بسطرين —
  الأول: رقم الطلب (`OHDID`) · القماش · العرض · اللون · هنش · ياردة · السعر؛
  الثاني: القصّاص · الخيّاط · المرحلة. حُذف الرف والمصدر، وأُعيد تسمية «النوع» إلى «العرض» لأن
  قيمة العمود في القاعدة «عرضية/ضيقة» لا نوع قماش.

### أخطاء صُحّحت أثناء المراجعة

- `Expanded` داخل `SingleChildScrollView` أفقي بعرض غير محدود → `invalid constraints` وسقوط
  التخطيط: صار العرض محسوباً بـ `LayoutBuilder` + `SizedBox(width:)`.
- `CrossAxisAlignment.stretch` داخل عمود في تمرير رأسي لا محدود → نفس السقوط: لُفّ بـ
  `IntrinsicHeight`.
- طلبان متطابقان عند أول فتح (حمل المزوّد + حمل `initState`) → حارس `if (state.isLoading) return;`
  في نافذة الموديلات وقائمة العملاء.
- ابتلاع مسافة البحث داخل حقل الأقمشة (مقارنة الحقل بقيمة `trim`-ed) → تتبّع `_lastEmitted`.
- ألوان ديناميكية داخل `const` → فُصلت إلى وقت الرسم (`accent ?? AppColors.primary`) لأن
  `AppColors.primary/textPrimary/...` معرّفات `get` لا ثوابت.

### الاختبارات

- جديد `test/features/customers/measurement_model_picker_sheet_test.dart` (4): النافذة تُفتح فوق
  المستضيف بلا `AppBar`، الاختيار يُغلقها ويعيد `40/35/2023/49`، البحث والترتيب يذهبان إلى
  الخادم، والحالة الفارغة تشرح نفسها.
- `measurement_view_screen_test.dart` صار 15 اختباراً: الأقسام الأربعة بتسمياتها، أعمدة الأقمشة
  المطلوبة سطراً بسطر، غياب «الرف/المصدر»، وغياب الحقول المحذوفة الخمسة.
- **النتيجة:** `flutter analyze` = No issues found! · `flutter test` = **456 ناجحاً و5 متجاوزة** ·
  حزمة العملاء **38**. حزمة Pest لم تكتمل: انقطاع اتصال أوراكل المحلي (`ORA-12514`).

**النموذج:** Qoder · **الوقت:** 2026-10-29 06:47 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## إصلاح ظهور العربية كرموز في طباعة/تصدير كل الكشوفات (PDF) — 2026-10-29

**المُنفِّذ:** Qoder · **الوقت:** 2026-10-29 07:15 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

### العطب وأثره
- كل الكشوفات (كشف حساب مالي/تحليلي، كشف عميل، كشف عامل، ميزان مجموعة، شجرة الحسابات، كشف
  العمل، والمقاسات/فواتير التفصيل) كانت تُخرج ملف PDF سليماً تقنياً لكن **كل نص عربي يظهر على
  شكل رموز** عند الطباعة أو التصدير.

### التحليل (بأدلّة لا بالحدس)
- الشيفرة المشتركة (`pdfArabic` + `kPdfShapedTextDirection` + `Document(theme:)`) موجودة في كل
  المولّدات بلا استثناء، واختبار `report_pdf_arabic_test.dart` يمرّ.
- فحص عملي عبر `flutter test` على خط Cairo الذي يجلبه `PdfGoogleFonts`: جدول الرموز (cmap) يغطي
  صور العربية الاتصالّية `U+FE70..U+FEFF` (صفر رمز مفقود) — أي أن التشكيل والخط **سليمان متى
  توفّر الخط**.
- نقطة الفشل الوحيدة المشتركة: `ReportPdfFonts` كان يحمّل Cairo عبر `PdfGoogleFonts.cairoRegular()`
  الذي **ينزّله من الإنترنت وقت التشغيل** (`fonts.gstatic.com`). في نشر هذا المشروع على LAN بلا
  إنترنت (الهاتف يصل إلى API محلياً فقط) يفشل التنزيل، فيسقط المستند إلى Helvetica الافتراضي الذي
  لا يحوي صور العربية، فتظهر العربية رموزاً بينما الأرقام/الإنجليزي سليمة.

### الحل
- **تضمين خط Cairo محلياً**: وُضع `assets/fonts/Cairo-Regular.ttf` و`assets/fonts/Cairo-Bold.ttf`
  (نفس البايتات التي يجلبها المُحمِّل، ومستخرجة من مسار الإنتاج نفسه).
- تسجيل الدليل في `pubspec.yaml` تحت `assets: - assets/fonts/`.
- إعادة كتابة `lib/core/utils/report_pdf_fonts.dart`: `regular`/`bold` أصبحا يقرآن من `rootBundle`
  ثم `pw.Font.ttf(...)`، مع إبقاء `PdfGoogleFonts` كـ **fallback** أخير فقط إذا تعذّرت قراءة الأصل.
  لا تغيير في أي مولّد تقارير — الإصلاح في نقطة التحميل المشتركة وحدها.

### الاختبار
- جديد `test/core/report_pdf_fonts_test.dart`: يثبت أن `rootBundle` يقرأ Cairo من الحزمة محلياً
  (دون أي شبكة)، وأن التغطية كاملة لكل كلمات الكشوفات، وأن `theme()` يُرجع Cairo وليس Helvetica.
- **النتيجة:** `flutter analyze` = No issues found! · `flutter test` = **458 ناجحاً و5 متجاوزة**.

---

## 2026-10-30 23:24 — أيقونات تواصل صغيرة في سطر اسم المطور، وشاشة دخول على شاشة واحدة

**الطلب:** أزرار الاتصال/واتساب في «معلومات المطور» تصير أيقونتين صغيرتين في سطر الاسم نفسه، وسطر
«الإصدار» أسفل شاشة الدخول يُستبدل بأيقونتي اتصال وواتساب للتواصل مع الشركة، مع ضبط شاشة الدخول
لتظهر كاملة بلا تمرير.

### العميل — ودجت مشترك جديد

- `lib/features/app_info/presentation/widgets/contact_icon_button.dart` — **ملف جديد**:
  `ContactIconButton` دائرة 36px (`Material` + `InkWell(customBorder: CircleBorder)`)، خلفية
  `color.withValues(alpha: 0.12)` وأيقونة بنصف القطر، و`Tooltip` يحمل المعنى لأن الزر بلا نص.
  السبب: الموضعان (سطر المطور وأسفل شاشة الدخول) يحتاجان الشكل نفسه، فلا يُكرَّر.

### العميل — قسم المطور

- `lib/features/app_info/presentation/widgets/developer_info_section.dart`:
  - الصف صار واحداً: `CircleAvatar` ثم `Expanded(GestureDetector(الاسم + «تطوير وبرمجة التطبيق»))`
    ثم أيقونة الاتصال ثم أيقونة واتساب — وهو الترتيب المطلوب «بنفس سطر الاسم».
  - حُذف صف الزرّين العريضين (`OutlinedButton.icon` للهاتف و`ElevatedButton.icon` لواتساب).
  - تلميح الاتصال هو الرقم كما يُقرأ `+967 776 422 777` — فالمعلومة لم تُفقد وإنما انتقلت إلى
    التلميح، وتلميح واتساب كلمة «واتساب». هدف النقر الخفي (خمس نقرات على الاسم) لم يتغيّر.

### العميل — شاشة الدخول

- `lib/features/auth/presentation/screens/login_screen.dart`:
  - حُذف نص `الإصدار v$kAppVersionBadge` من أسفل البطاقة (وحُذف معه استيراد `app_info.dart`)،
    وما زال ظاهراً في شارة وتذييل شاشة «معلومات البرنامج والدعم».
  - أُضيف `_CompanyContactBar(phone: companyPhone)`: أيقونتا اتصال وواتساب للتواصل مع **الشركة**،
    ورقمها من `appConfigNotifierProvider.select((s) => s.config.companyPhone)` أي من `APP_SETTINGS`.
    الحقل الفارغ يُخفيهما كلياً (`SizedBox.shrink`) بدل أيقونتين عاطلتين.
  - **ملاءمة الشاشة الواحدة:** `_LoginLayout.of(MediaQuery.sizeOf(context).height)` يشتق مقياساً
    متصلاً `(height - 140) / 700` محدوداً بين 0.62 و1.0، يُطبَّق على ارتفاع/عرض الشعار وحشوة البطاقة
    وكل الفراغات الرأسية؛ و`showSubtitle` يخفي «أدخل بيانات حسابك للمتابعة إلى النظام» تحت 660px.
    الـ`SingleChildScrollView` بقي شبكة أمان (لوحة المفاتيح، تكبير الخط 1.25، الشاشات الصغيرة جداً).
  - أُزيلت الحشوة الثابتة `EdgeInsets.all(10)` واستُبدلت بـ`metrics.gap(10)`.

### العميل — الروابط الخارجية

- `lib/features/app_info/presentation/utils/external_links.dart`:
  - `internationalDigits(phone)` دالة نقية عامة (تُطبّع الرقم وتُرجع الأرقام الدولية بلا `+`)،
    صار `buildTelUri` يستعملها، وأُضيف `openWhatsappTo(context, phone)` الذي يبني
    `https://wa.me/<digits>` — لأن `wa.me` لا يقبل `+` ولا مسافات.

### الاختبارات

- `test/features/app_info/app_info_screen_test.dart`: حالة قسم المطور صارت تثبت أن الرقم **تلميح**
  لا نص (`findsNothing` للنص، `findsOneWidget` للتلميح)، وأنه لا نص «واتساب» داخل البطاقة
  (`find.descendant` على `DeveloperInfoSection`)، وأن الأيقونتين على ارتفاع الاسم نفسه (فرق < 16px)
  ومحاذيتان تماماً لإحداهما الأخرى — أي سطر واحد لا سطرين.
- `test/features/app_info/external_links_test.dart`: مجموعة جديدة `internationalDigits` (أرقام
  `wa.me` بلا `+` ولا مسافات · رقم محلي · رقم بصفر بادئة · فراغ ⇒ `null`).
- `test/features/auth/last_username_test.dart`: `_StubAppConfig` صار يقبل `companyPhone`، و`pumpLogin`
  يمرّره؛ وسطر النسخة صار مؤكَّد الغياب. **3 حالات جديدة:** الأيقونتان موجودتان وتحت زر «دخول»
  مباشرة · غيابهما حين لا رقم · بطاقة الدخول كاملة على 360×640 (`Card.bottom <= 640`, بلا استثناء
  تجاوز، وكل العناصر ظاهرة). استُورد `AppLogo` للتأكد من رسم الشعار.

### ما لم يتغيّر

- لا تغيير في الخادم ولا في قاعدة البيانات ولا في الأصول: الرقم يقرأ من `company_phone` القائم.
- بوابة النقر الخمسي، وشاشة «معلومات البرنامج والدعم»، وقسم الاستفسار، وبطاقة معلومات الشركة كما هي.
- `kAppVersion` و`kAppVersionBadge` ما زالا مستعملين في شاشة المعلومات والتذييل.

### التحقق

- `flutter analyze` = **No issues found!** (66.1s).
- `flutter test` (كامل) = **462 ناجحاً / 5 متجاوزة — All tests passed!**
- `flutter test test/features/app_info` = **22 ناجحاً**.

**النموذج:** Qoder · **الوقت:** 2026-10-30 23:24 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 02:12 — مقاسات العملاء: التباين، صف واحد، وخانات لا تُختَرع

### قائمة الموديلات المنبثقة

- `MeasurementModelTile` صار يستقبل `customerName`: بلا مستفيد ⇒ العنوان هو اسم العميل نفسه،
  ولا نص «بلا مستفيد محدّد» في أي مكان. حُذف `beneficiaryLabel` من `MeasurementModelRef` بعد أن
  لم يبق له قارئ — الحقل الميت يبقى خطأً صامتاً إلى أول من يظن أنه مستعمل.

### لوحة `measurement_kit.dart` (تباين أعلى)

- `MeasurementSectionCard`: تدرج Accent (0.34 → 0.12) بدل شريط 7%، حد سفلي 1.6، أيقونة مصمتة،
  عنوان 14w800، وإطار البطاقة 1.2 بشفافية 0.45.
- `MeasurementField`: تسمية w700 بحجم 9.5 بلون `textSecondary` (#475569) وقيمة w800 بحجم 12.5
  بلون `textPrimary`؛ الغائب يبقى `textMuted` عمداً. وضع `dense` (8.5/11 وحشو 5/3) لصفوف الأقمشة.
- `gridRule`: فواصل الشبكة بلون `secondary` بشفافية 0.35 بدل `AppColors.border` (#E2E8F0) الذي
  لا يُرى على الأبيض؛ دالّة لا ثابتاً لأن اللوحة تُهيّأ من الخادم.
- `MeasurementFieldGrid(singleRow: …)`: «العميل» ثلاثة أرقام في صف واحد كما طُلب.

### الأقسام

- **بيانات العميل والمستفيد:** اسم العميل محذوف (يظهر في عنوان الشاشة وحده)؛ مجموعتان تاليتان
  بعناوين: المستفيد والموديل (خانة المستفيد مشروطة بوجوده) والفاتورة والطلب.
- **مواصفات الموديل:** بقائمة المستخدم نفسها — نوع الأزرار، نوع الكم، نوع الرقبة، **جيب جانبي**،
  نوع الجبزور، **جيب الصدر** — ثم نوع الكباك وعدد الأزرار وجيب الجوال والحجازي.
  «جيب جانبي» = `POCKET_OR_WITHOUT` (معبأ 83,395/84,971 وقيم «جيوب/بدون/جيوب شمال/جيوب يمين»)،
  و«جيب الصدر» = `SHAPE_POCKET_UP_NO` عند وجوده فقط، و`PEN_POCKET` أُزيل: فارغ في كل الصفوف.
- **الأقمشة:** بلا عمود ترقيم وبلا تمرير أفقي. لكل قماش سطران بأوزان نسبية:
  (رقم الطلب · القماش · العرض · اللون · هنش · ياردة · السعر) ثم (القصّاص · الخيّاط · المرحلة)
  مع خلية «المرحلة» بشارة ملوّنة وتسمية مثل بقية الخانات، وفاصل 1.2 بين السطرين.
  «العرض» = `CLOTH_TYPE` (قيمته الحيّة «عرضية» 37,077 مرة)، ورقم الطلب = `OHDID` (11 رقماً في
  الحيّ) فأُوسع عليه قبل اسم القماش. الرف والمصدر محذوفان من الشاشة ومن الـ PDF معاً.
- **الـ PDF:** جدول الأقمشة بنفس الأعمدة المطلوبة (رقم الطلب · القماش · العرض · اللون · هنش ·
  ياردة · السعر · القصّاص · الخيّاط · المرحلة) وبلا رف/مصدر؛ وكتلة الهوية بلا الحقول المحذوفة.

### إصلاحات وسلوكيات

- تكرار الطلب عند أول فتح (حمل المزوّد + حمل `initState`) — حارس `isLoading` في شاشة العملاء
  ونافذة الموديلات معاً.
- ابتلاع مسافة البحث في حقل الأقمشة — تتبّع `_lastEmitted` بدل مقارنة الحقل بقيمة مقطوعة.
- ألوان ديناميكية داخل `const`: فُصلت إلى وقت الرسم (`accent ?? AppColors.primary`)، وجُعلت
  `MeasurementGroupLabel`/`MeasurementBadge` بلا قيم افتراضية ثابتة.
- `Expanded` داخل تمرير أفقي غير محدود و`CrossAxisAlignment.stretch` داخل عمود غير محدود:
  صُحّحا بالحساب الصريح للعرض ثم بـ `IntrinsicHeight`، والأول أُزيل أصلاً حين صار العرض بلا تمرير.

### الاختبارات

- `test/features/customers/` = **40 ناجحاً**: النماذج 13، المستودع 8، الشاشة 16 (سطرا الأقمشة
  وأعمدتهما، غياب الحقول المحذوفة، إخفاء خانة المستفيد، عدم تكرار الاسم)، النافذة 5.
- `flutter analyze` = **No issues found!** · `flutter test` = **464 ناجحاً / 5 متجاوزة**.
- تعذّر تشغيل Pest: اتصال التطبيق بـ `localhost:1521/orclrd` مرفوض (`ORA-12514`)؛ تحقق القاعدة
  في هذه الجولة تم قراءةً عبر موصل `oracledb` على الخادم البعيد، بما في ذلك تنفيذ استعلام التفصيل
  كاملاً على فاتورة حيّة (55 صفاً).

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:12 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 02:39 — شعار واتساب الرسمي بدل الفقاعة العامة في المواضع الثلاثة

**الطلب:** أيقونة واتساب في «معلومات المطور» وفي «الاستفسار والمساعدة» تُرسم بالشعار الرسمي لا
بـ`Icons.chat_outlined`، مع تأكيد أيقونتي الاتصال/واتساب أسفل شاشة الدخول وبقاء البطاقة في شاشة واحدة.

### الاعتماد الجديد

- `pubspec.yaml`: `font_awesome_flutter: ^10.7.0` — **السبب:** Material Icons لا تحوي شعار واتساب
  مطلقاً، والفقاعة العامة لا تُقرأ كواتساب. الخط يُقلَّم عند البناء (`--tree-shake-icons`) إلى
  الرموز المستعملة فقط، فالكلفة الفعلية رمزان لا أكثر.
- `flutter pub get` نُفِّذ بنجاح و`pubspec.lock` يحمل الحزمة، فالبناء اللاحق يعمل بلا شبكة.

### العميل — ودجت الشعار

- `lib/features/app_info/presentation/widgets/whatsapp_icon.dart` — **ملف جديد**: `WhatsAppIcon`
  يرسم `FontAwesomeIcons.whatsapp` بلون `AppColors.whatsapp` افتراضاً وبـ`semanticLabel: 'واتساب'`
  (الشعار بلا نص فيُعلَن لقارئ الشاشة). موضع واحد للحقيقة: أي تغيير للشعار لاحقاً يقع هنا وحده.

### العميل — المواضع الثلاثة

- `developer_info_section.dart`: أيقونة التواصل صارت `WhatsAppIcon` بدل `Icons.chat_outlined`،
  وأيقونة الاتصال صارت `FontAwesomeIcons.phone` (17px) لتوافق الوزن البصري للشعار المجاور.
- `support_inquiry_section.dart`: زر «واتساب» في قسم الاستفسار صار `WhatsAppIcon(size: 18)`
  بدل `Icons.chat_rounded`/`chat_outlined`؛ وزر «اتصال» بقي `Icons.call_outlined` لأنه زر بنص.
- `login_screen.dart` → `_CompanyContactBar`: الأيقونتان كما هما (اتصال/واتساب لرقم الشركة من
  `APP_SETTINGS`) وأيقونة واتساب صارت الشعار الرسمي، والاتصال `FontAwesomeIcons.phone`.
- `contact_icon_button.dart`: حقل الرمز تغيّر من `IconData` إلى `Widget icon` — لأن شعار العلامة
  ليس `IconData` أصلاً. تعليق صريح يشرح السبب داخل الملف.

### الاختبارات

- `test/features/auth/last_username_test.dart`: تأكيدات أيقونات Material استُبدلت بـ
  `find.byType(WhatsAppIcon)` و`findsNothing` لـ`Icons.chat_rounded`/`chat_outlined`، مع بقاء
  تأكيدَي التلميح والموضع تحت زر «دخول».
- `test/features/app_info/app_info_screen_test.dart`: `WhatsAppIcon` داخل `DeveloperInfoSection`
  موجود مرة واحدة، ولا أثر لأي رمز دردشة عام في الشاشة كلها.

### التحقق

- `flutter analyze` = **No issues found!** (28.3s).
- `flutter test` (كامل) = **464 ناجحاً / 5 متجاوزة — All tests passed!**
- `flutter test test/features/app_info test/features/auth/last_username_test.dart` = **39 ناجحاً**.

**النموذج:** Qoder · **الوقت:** 2026-10-31 02:39 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 — اللقطات البصرية للرئيسية: تاريخ مثبّت وإعادة توليد

### المشكلة

`flutter test` على هذا الجهاز أعاد خمسة إخفاقات في `test/home_visual_test.dart` — لأن
`KY_VISUAL=1` مثبّت في بيئة المستخدم، فاللقطات لم تُتجاوز كما يفترض تعليقها. والصور نفسها كانت
قديمةً بعد توسيع كتالوج الاختصارات، وكانت تفشل أيضاً لأن ترويسة الرئيسية تكتب التاريخ والتحية من
ساعة الجهاز فتتغيّر اللقطة كل يوم بلا أي تغيير في التصميم.

### التغييرات

- `lib/features/home/presentation/screens/home_dashboard_screen.dart`: حقل `now` اختياري يُمرَّر
  إلى `HomeHeader` (وفي التشغيل يبقى `null` فيُقرأ `DateTime.now()`). لا سلوك جديد للمستخدم.
- `test/home_visual_test.dart`: `_pinnedNow = DateTime(2026, 10, 22, 9, 15)` يُمرَّر في كل لقطة،
  فأصبحت اللقطة قابلة للتكرار في أي يوم.
- `test/goldens/home_mobile.png` · `home_mobile_small.png` · `home_mobile_three.png` ·
  `home_mobile_four.png` · `home_desktop.png`: أُعيد توليدها (`--update-goldens`) بعد تحديث
  الكتالوج (بطاقة «مقاسات العملاء» وغيرها) ورُوجعت بالعين.

### الاختبارات

- `flutter analyze` = **No issues found!** · `flutter test` (كامل) = **474 ناجحاً، صفر إخفاق**.
- `php -l` على `app/`+`routes/`+`database/` سليم · `pint --test` نظيف · `route:list` = 138 مساراً.
- مرآة أكواد الصلاحيات: الخادم 147 والعميل 147 — بلا فرق في أي اتجاه.

**النموذج:** Qoder · **الوقت:** 2026-10-31 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

---

## 2026-10-31 05:17 — قسم الاستفسار يخاطب الشركة، وهوية الشركة تعمل بلا اتصال

**الطلب:** بيانات التواصل في «الاستفسار والمساعدة» تخصّ الشركة لا المطور، وأيقونات التواصل أسفل شاشة
الدخول يجب ألا تختفي عند تعذّر الاتصال بالـ API بل تعود إلى المعلومات الافتراضية للشركة.

### العيوب المكتشفة (بأدلّة من الشيفرة)

1. `support_inquiry_section.dart` كان يستدعي `kDeveloperPhone` و`kDeveloperWhatsappUrl` — أي أن شكوى
   العميل تذهب إلى المطوّر لا إلى الشركة.
2. `AppConfigModel.defaults()` كان يحمل `companyPhone: ''` **و**`companyAddress: '967780154000'`
   (الرقم الدولي موضوعاً في حقل العنوان)، فمسار «بلا خادم وبلا كاش» لا يحمل أي رقم ⇒
   `_CompanyContactBar` يعيد `SizedBox.shrink` وتختفي الأيقونتان.
3. `AppConfig::DEFAULTS` في الخادم كان يحمل العنوان والهاتف فارغين كذلك.

### العميل

- `lib/features/app_config/data/models/app_config_model.dart`:
  - `static const String fallbackCompanyPhone = '780154000';` — مصدر واحد للرقم الافتراضي.
  - `String get contactPhone` — المخزَّن، وإن كان فارغاً فالثابت أعلاه. مبرَّر: الخادم نفسه يُعوّض
    الصف الفارغ بالافتراضي في `publicPayload`، فأي فراغ يصل العميل هو بيانات قديمة تُصلَح.
  - `defaults()`: العنوان `'الجراف- جوار بيت الشايف'` والهاتف `fallbackCompanyPhone` بدل الفراغ
    والرقم الموضوع في حقل العنوان، مع تعليق يشرح أن هذه هي هوية الشركة حين يُفتح التطبيق بلا شبكة.
- `lib/features/app_info/presentation/widgets/support_inquiry_section.dart`:
  - من `StatelessWidget` إلى `ConsumerWidget`، والرقم من
    `appConfigNotifierProvider.select((s) => s.config.contactPhone)`.
  - «اتصال» ⇒ `ExternalLinks.openTel(context, phone)`، و«واتساب» ⇒
    `ExternalLinks.openWhatsappTo(context, phone)` (رابط `wa.me` من الأرقام المطبَّعة).
  - `Tooltip` على الزرّين يحمل الرقم المكتوب — يكشف الرقم بالضغط المطوّل، ويُتيح للاختبار إثبات أنه
    رقم *الشركة* لا رقم المطوّر.
  - حُذف استيراد `core/constants/app_info.dart` من هذا الملف: لا ثوابت مطوّر فيه بعد اليوم.
- `lib/features/auth/presentation/screens/login_screen.dart`: `_CompanyContactBar(phone: contactPhone)`
  بدل `companyPhone`، وتعليق يوضّح أن الأيقونتين لا تسقطان بانقطاع الـ API. وبقي حارس الفراغ في
  الودجت كتحقّق من مدخلاته.

### الخادم

- `kyApp_API/app/Support/AppConfig.php`: `COMPANY_ADDRESS` و`COMPANY_PHONE` في `DEFAULTS` صارا
  القيمتين الحقيقيتين، فالحمولة العامة لا تُعيد فراغاً لعمود الهاتف أبداً. لا تغيير في
  `publicPayload` ولا في `WRITABLE_KEYS` ولا في سقوف `AppConfigController::textLimit`.
- `02_ibac_seed.php` لا يتأثر: يحدّث التسميات والنطاقات فقط ويُبقي قيم المشغّل كما هي.

### الاختبارات

- `test/app_config_model_test.dart` — مجموعة **«هوية الشركة تعمل بلا اتصال»** (3 حالات): الافتراضي
  يحمل الهاتف والعنوان · `contactPhone` يعوّض الفراغ (كاش قديم) · يحترم الرقم المخزَّن.
- `test/features/app_info/app_info_screen_test.dart` — حالتان: تلميح القسم يكشف رقم *الشركة*
  (`777000111`) لا رقم المطوّر · رقم فارغ يعود إلى `fallbackCompanyPhone`.
- `test/features/auth/last_username_test.dart` — `_StubAppConfig` صار يقبل `AppConfigModel?` حيث
  `null` = الافتراضي؛ وحالتان: «بلا اتصال بالأي بي آي تظهر الأيقونتان من الهوية الافتراضية»،
  و«رقم فارغ يعود إلى الافتراضي لا إلى الاختفاء» (بديلاً لحالة الاختفاء القديمة).

### التحقق

- `flutter analyze` = **No issues found!** (35.1s).
- `flutter test` (كامل) = **470 ناجحاً / 10 متجاوزة — All tests passed!**
- `flutter test test/features/app_info test/features/auth/last_username_test.dart test/app_config_model_test.dart`
  = **57 ناجحاً**.
- `php artisan test --filter=AppConfig` = **9 ناجحاً (33 تأكيداً)** — نُفِّذ على القاعدة البعيدة
  (`DB_HOST`/`DB_SERVICE_NAME` للعملية وحدها) لأن `localhost:1521/orclrd` ما زال `ORA-12514`.
- `php -l app/Support/AppConfig.php` نظيف · `pint --dirty` = **passed**.

**النموذج:** Qoder · **الوقت:** 2026-10-31 05:17 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).


---

## 2026-10-31 06:12 — التفصيل: إعادة تنسيق قائمة الفواتير وتقوية التباين وتفكيك التمرير الأفقي

### العميل (Flutter)

- `widgets/bill_list_tile.dart` — أُعيد بناؤه: سطر هوية (شارة «رقم / سنة» بوزن 800 · اسم
  العميل 14/800 · شارة الحالة)، فاصل 0.9 بكسل، ثم `TailoringInfoGrid(singleRow: true)` بخانات
  (التاريخ · الهاتف · الرقم اليدوي · الموديلات · القطع · الصافي). أُزيلت العبارات الملتصقة
  مثل «يدوي 778» و«2 موديل · 3 قطعة».
- `screens/cutting_bills_list_screen.dart` — سطر نطاق جديد فوق البحث (أيقونة معلومات + نصّ
  الحدّ + شارة عدد النتائج)، وتلميحات وعناوين بتباين أعلى (11.5–12 بوزن 600)، وحشو القائمة
  12 ومسافة 8 بين البطاقات، وإزالة عدّاد مكرّر من سطر الفلترة.
- `widgets/tailoring_section_card.dart` — خيار `titleTrailing` (عنصر ملتصق بالعنوان)، والعنوان
  داخل `Expanded(Row(Flexible(title), Flexible(titleTrailing)))` فلا تجاوز على أي عرض؛
  والقيمة 13/800 والتسمية 10.5/700، وإطار الشبكة والفواصل 0.9 بلون الحدّ الكامل.
- `widgets/bill_customer_card.dart` — الاسم عبر `titleTrailing` بجانب عنوان القسم مباشرةً.
- `widgets/bill_header_card.dart` — الحقول في صفّين عبر `rows: 2`.
- `widgets/model_fabrics_table.dart` — أُعيد بناؤه: عشرة أعمدة مرنة تناسب العرض المتاح (بلا
  `SingleChildScrollView` أفقي)، عمود «رقم الطلب» = `ohdid`، حذف «#» والرف والمصدر، وسطران
  لكل قماش (بيانات القياس في الأول، القصّاص/الخيّاط/المرحلة في الثاني).
- `widgets/model_movements_table.dart` — أُزيل التمرير الأفقي وضُبطت أعمدة مرنة، وجدول
  بخمسة أعمدة (الحالة · التاريخ · العدد · المنفذ · ملاحظة).

### الاختبارات المحدَّثة

- `cutting_bills_list_screen_test.dart`: العدّادات خانتان («الموديلات» و«القطع»)، والرقم اليدوي
  تسمية + قيمة.
- `cutting_bill_view_screen_test.dart`: أربع خانات لبيانات الفاتورة في صفّين (قياس ارتفاع أقل
  من 860 بكسل)، وعمود المستفيد برأس واحد.

### النتيجة

54 اختبار تفصيل ناجح · 470 في الحزمة الكاملة (10 متجاوزة) · `flutter analyze lib` بلا ملاحظات ·
Pest `Tailoring` 11/229 · pint PASS.

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:12 · **لا commit** (لم يُطلب).


---

## 2026-10-31 06:43 — التفصيل: قائمة صفوف مدمجة، أقمشة قابلة للتحديد، وسجل لكل قماش

### ما رُفض وأُعيد بناؤه

رفض المستخدم بطاقات القائمة السابقة (سطر هوية + شبكة حقول) لأنها بدت جدولاً وتستهلك ارتفاعاً،
ورفض جدول الأقمشة/الحركة ذا التمرير. فأُعيد البناء كالتالي:

- `widgets/bill_list_tile.dart` — صف قائمة واحد: شارة «رقم / سنة» · اسم العميل (مرن) ·
  التاريخ · الصافي (عرض 74) · نقطة حالة + نصّها. بلا إطار ولا بطاقة.
- `screens/cutting_bills_list_screen.dart` — `ListView.separated` بحشو صفر وفاصل 0.7،
  وحذف `_scopeLine`، وإعادة عدّاد النتائج إلى سطر الفلترة.
- `widgets/model_fabrics_table.dart` — قائمة كتل قابلة للتحديد: سطر عنوان + سطرَي حقول
  (`Wrap` من «تسمية: قيمة») بلا `Table` وبلا `SingleChildScrollView`؛ تُبلّغ عن الاختيار
  عبر `onSelected(ohdId)` وتُبرز المختار.
- `widgets/model_movements_table.dart` — `ohdId` واحد للقماش المختار (أو `ohdIds` لعرض على
  مستوى الفاتورة)، توصيف خمسة أعمدة في صفوف `Row` مرنة ونصوص ملتفّة، ورسالة «اختر قماشاً…»
  عند غياب الاختيار، وعنوان يذكر اسم القماش ورقمه.
- `screens/cutting_bill_view_screen.dart` — حالة جديدة `_selectedFabricOhd` تُصفَّر عند تغيير
  الموديل وتُغذّي بطاقتَي الأقمشة والحركة، والافتراضي أول قماش في الموديل.

### الاختبارات

- جديد: «choosing a fabric switches the movement log to that fabric» — السجل يبدأ بصوف ثم
  يتحوّل إلى قطن عند اختيار القماش الثاني.
- محدَّث: قائمة الفواتير تُتحقَّق من الحقول الجديدة (التاريخ/الصافي/الحالة) بدل العدّادات،
  وعنوان سجل الحركة صار يُطابق بـ`textContaining('سجل الحركة —')`.
- النتيجة: 55 اختبار تفصيل · 471 في الحزمة الكاملة · `flutter analyze lib` بلا ملاحظات.

**النموذج:** Qoder · **الوقت:** 2026-10-31 06:43 · **لا commit** (لم يُطلب).


---

## 2026-10-31 07:15 — التفصيل: محاكاة شكل شاشات المقاسات في القائمة والأقمشة والمقاسات

### لماذا

رُفض التصميمان السابقان (صفوف قائمة مضغوطة، وجدول أقمشة عشرة أعمدة) لأنهما بدَوا جدولاً ضيقاً
بلا معلومات. المرجع المطلوب صار شاشات «مقاسات العملاء» الموجودة في المشروع.

### ما نُفِّذ

- `widgets/bill_list_tile.dart` — أُعيد بناؤه على هيئة `MeasurementCustomerTile`: `Material` +
  `InkWell` + حدود 11 + شريط لوني 4px + مربّع رقم/سنة + اسم العميل + سطر بيانات
  (تاريخ/هاتف/يدوي) + عمود شارات (`N موديل`, `N قطعة`) + الصافي + نقطة حالة + سهم.
- `screens/cutting_bills_list_screen.dart` — `ListView.separated` بحشو `12/10/12/16` وفاصل 8
  بدل الصفوف الممتدة الحواف.
- `presentation/widgets/tailoring_cells.dart` (جديد) — `TailoringCell` (تسمية 9.5/700 وقيمة
  13/900 مع `FittedBox`)، `TailoringCellRow` بأوزان وخطوط، `TailoringCellGrid` بأعمدة متساوية
  وصفوف مفصولة، و`tailoringGridRule` كقاعدة الطقم.
- `widgets/model_fabrics_table.dart` — بطاقة لكل قماش كـ`MeasurementFabricsPanel`: سطر أول
  بأوزان `[2.4, 2.2, 1.3, 1.3, 0.9, 1.0, 1.3]` وخلفية ملوّنة، خط 1.2، ثم سطر
  (القصّاص · الخيّاط · المرحلة) بأوزان `[2.4, 2.4, 1.6]`؛ التحديد يلوّن البطاقة ويُبرزها.
- `widgets/model_measurements_grid.dart` — عنوان «تفاصيل المقاسات — موديل N» وشبكة
  `TailoringCellGrid(minCellWidth: 88)` بخانات رقمية، مع مفتاح «إظهار الكل».
- اختبارات: عنوان المقاسات صار «تفاصيل المقاسات — …»، واختيار القماش يتم بالنقر على اسمه
  («قطن») في بطاقته، وبطاقة الفاتورة تُتحقَّق من الرقم والعدّادين.

### النتيجة

55 اختبار تفصيل · 471 في الحزمة الكاملة (10 متجاوزة) · `flutter analyze lib` بلا ملاحظات.

**النموذج:** Qoder · **الوقت:** 2026-10-31 07:15 · **لا commit** (لم يُطلب).


---

## 2026-10-31 09:38 — التفصيل: عرض القماش من `MULTI_CLOTHS` بدل كلمة النوع

- كان `العرض` يُملأ من `CLOTH_TYPE` (عرضية/عادية) لأن الواجهة لا تحمل رقماً، والمطلوب رقم
  القماش الحقيقي (58/45/38).
- `TailoringController`: ثابتان جديدان (`TABLE_MULTI_CLOTHS`, `CLOTH_WIDTH_CANDIDATES`)،
  ودالة `clothWidthColumn()` تكتشف العمود مرة واحدة من `ALL_TAB_COLUMNS` بـ`try/catch`،
  و`detailSql()` تبني `LEFT JOIN` و`SELECT … AS CLOTH_WIDTH` شرطياً، و`pieceRow` تُضيف
  `cloth_width`.
- `cutting_piece_item.dart`: حقل `clothWidth` يُقرأ بـ`tailoringPlainText(json,'cloth_width')`.
- `model_fabrics_table.dart`: خلية «العرض» تستخدم `piece.clothWidth` (رقم) وتترك `—` عند غيابه.
- الاختبارات: عنوان قسم الأقمشة صار يُطابَق بـ`textContaining('الأقمشة —')` لأن المستخدم أضاف
  اسم النوع إلى العنوان.

**النموذج:** Qoder · **الوقت:** 2026-10-31 09:38 · **لا commit** (لم يُطلب).

---

## 2026-11-01 00:20 — iOS: أول تهيئة للمنصة — معرّف الحزمة، ATS، الأذونات، الأيقونة، وبناء سحابي غير موقَّع

- **المشكلة الجذرية:** بناء iOS وتوقيعه يتطلبان macOS + Xcode، وجهاز التطوير Windows ولا يملك
  Mac ولا حساب Apple Developer. الحل المُعتمد: فصل البناء عن التوقيع — بناء سحابي على
  **Codemagic** (خطة مجانية: 500 دقيقة Mac mini M2 شهرياً) يُنتج **IPA غير موقَّع**، ثم توقيع
  وتثبيت محليان على ويندوز عبر **Sideloadly** بحساب **Apple ID مجاني** (شهادة تطوير + profile
  صالح **7 أيام**، 3 تطبيقات كحد أقصى، بلا TestFlight).
- **`ios/Runner/Info.plist`:** أُضيفت ثلاث كتل — `NSAppTransportSecurity`
  (`NSAllowsArbitraryLoads` + `NSAllowsLocalNetworking`) لأن `ApiConstants.defaultBaseUrl`
  يبدأ بـ`http://` ويُعدَّل وقت التشغيل، وATS يحجب كل طلب بصمت؛ `NSPhotoLibraryUsageDescription`
  لأن `app_config_repository.pickAndSaveLogo()` يستدعي `ImagePicker.pickImage(source: gallery)`
  وiOS يُنهي التطبيق بلا هذا المفتاح؛ `NSLocalNetworkUsageDescription` لطلب إذن iOS 14+
  عند الاتصال بعنوان خاص. وتغيّر `CFBundleDisplayName` من `Ky Apps` إلى `الكبودي`
  لمطابقة `android:label`.
- **`ios/Runner.xcodeproj/project.pbxproj`:** `PRODUCT_BUNDLE_IDENTIFIER` من
  `com.example.kyApps` (قالب Flutter) إلى **`com.alkaboudy.app`** في الإعدادات الثلاث
  Debug/Profile/Release، ومثله لهدف `RunnerTests` → `com.alkaboudy.app.RunnerTests`.
  و`IPHONEOS_DEPLOYMENT_TARGET` من 12.0 إلى **13.0** في المواضع الثلاثة (تحقّق من podspec
  كل الحزم: أعلى حد أدنى مطلوب هو 12.0، فـ13.0 لا يكسر شيئاً ويمنع رفض Xcode الحديث).
- **`ios/Podfile` (جديد):** لم يكن موجوداً أصلاً (يُولَّده Flutter عند أول build على macOS).
  حُفظ في git بـ`platform :ios, '13.0'` و`use_frameworks!` + `use_modular_headers!` وبلوك
  `post_install` يفرض `IPHONEOS_DEPLOYMENT_TARGET = 13.0` على كل Pod، ليكون البناء السحابي
  حتمياً بدل الاعتماد على قالب متغير.
- **الأيقونة:** كانت `AppIcon.appiconset/Icon-App-1024x1024@1x.png` شعار **Flutter** الأزرق
  (تأكيد بصري). أُنشئ `tools/ios_icons.py` (Pillow) الذي يقصّ الشفافية المحيطة بـ
  `assets/logo1.png` (3000×3000 RGBA)، ويوسّط الشعار على خلفية بيضاء بحشوة 8%، ويُصدّر
  **15** مقاساً بنمط **RGB** (بلا قناة alpha — شرط iOS)، بأسماء وقياسات مطابقة تماماً لـ
  `Contents.json` القائم (لم يُعدَّل).
- **`codemagic.yaml` (جديد):** workflow `ios-unsigned` على `mac_mini_m2`، مثبّت بـ
  `flutter: 3.29.3` و`xcode: "16.2"` (مطابقة الأدوات المحلية)، و`clone: submodules: false`
  (بناء iOS لا يحتاج `kyApp_API/` فيُوفَّر وقت ويُجتنَب فشل `node_modules/vendor`).
  الخطوات: `pub get` → `flutter analyze` → `pod install` →
  `flutter build ios --release --no-codesign` → تغليف يدوي
  (`Payload/Runner.app` ثم `zip -qry` للحفاظ على symlinks داخل Frameworks).
  Artifacts: الـIPA + `Runner.app.dSYM` + سجلات xcodebuild. **لا publishing ولا secrets.**
  ملاحظة: لم يُشغَّل `flutter test` داخل CI عن قصد لأن بعض الاختبارات تعتمد على عنوان API
  على الشبكة المحلية وتفشل في بيئة معزولة؛ البوابة تبقى محلية قبل الدفع.
- **`ios_release_guide.md` (جديد، 9 أجزاء):** نظير دليل أندرويد — مقارنة المنصتين، شرح
  الشهادة والـprofile والـUDID، حدود الحساب المجاني، خطوات الإصدار والتثبيت، شرط الشبكة
  وتفسير ATS، قائمة تجربة من 13 بنداً، جدول تشخيص (iTunes المخزني، Developer Mode، الثقة،
  3 تطبيقات، 10 App IDs، توافق Xcode)، وخطة الترقية إلى حساب 99$ مع الحفاظ على نفس Bundle ID.
- **لم يُمسّ:** `lib/` و`android/` و`kyApp_API/` و`pubspec.yaml` (الإصدار يبقى `1.1.0+2`
  لأول بناء iOS — لا تعارض بين المنصتين ولا حاجة لزيادة رقم البناء).
- **التحقق:** `flutter analyze` = No issues found! · فحص YAML يمرّ ويُظهر 5 خطوات و3 artifacts ·
  الأيقونات الـ15 كلها مربّعة وRGB.
- **غير متحقَّق حتى الآن:** أول بناء فعلي على Codemagic يحتاج ربط المستودع بحساب Codemagic
  ودفع `main` — ثم تُسجَّل الزمن والأخطاء الحقيقية في إدخال لاحق.

**النموذج:** Qoder · **الوقت:** 2026-11-01 00:20 · **لا commit** (لم يُطلب).

---

## 2026-11-01 00:57 — تصحيح: `codemagic.yaml` مرفوض من مخطط Codemagic (`clone` غير مدعوم أصلاً)

- **الخطأ الذي أرجعه codemagic.io:** `1 validation error in codemagic.yaml: ios-unsigned -> clone
  → extra fields not permitted`.
- **السبب المثبت (لا تخمين):** نُزّل مخططهم الرسمي `codemagic.io/codemagic-schema.json` وفُحص
  برمجياً؛ تعريف `Workflow` عنده `additionalProperties: false` وحقوله هي فقط:
  `name, instance_type, max_build_duration, triggering, inputs, environment, integrations, cache,
  when, working_directory, pre_clone_scripts, scripts, artifacts, publishing, labels` — أي أن
  **`clone` ليس مفتاحاً معروفاً على مستوى الـworkflow أصلاً** (خيارات الجلب تُضبط من الواجهة،
  لا من الملف)، لذلك كان خطأ إضافتها من الأصل.
- **الإصلاح:** حُذفت كتلة `clone: submodules: false` واستُبدلت بتعليق يشرح المنع. الأثر الجانبي
  المقبول: المستودع الفرعي `kyApp_API` سيُجلب مع الـclone الافتراضي؛ وهو مستودع عام (GitHub)
  فلا يفشل الجلب، والتكلفة ثوانٍ فقط. لا يوجد بديل مدعوم لإيقاف الجلب من داخل `codemagic.yaml`.
- **تحقق مضاد للخطأ قبل إعادة البناء:** فُحصت مفاتيح ملفنا على المخطط الفعلي — workflow بلا
  حقول زائدة، و`environment` بمفاتيح مسموحة فقط (`flutter`, `xcode`, `cocoapods`, `vars`)،
  و`scripts` تستخدم `name` + `script` وهما المسموحان في تعريف `BuildScript` (بقية المسموح:
  `ignore_failure`, `on_failure`, `when`, `working_directory`, `test_report`)، و`artifacts`
  قائمة نصوص.
- **توثيق:** `ios_release_guide.md` §3.3 صار يحوي قائمة الحقول المسموحة وقاعدة "لا كتلة clone"،
  و§7 يحوي صفاً لهذا الخطأ بعينه.
- **لم يُمسّ:** `pubspec.yaml` (لا زيادة رقم إصدار — لم يتغير أي كود Dart)، ولا `lib/` ولا `android/`.
- **التحقق:** `flutter analyze` = No issues found! (275.4 ثانية) · `codemagic.yaml` يُحلَّل كـYAML
  ويطابق حقول المخطط المسموحة.

**النموذج:** Qoder · **الوقت:** 2026-11-01 00:57 · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:07 — iOS: إغلاق بوابات الجودة + توحيد إصدار النظام على 13.0 في المواضع الثلاثة

- **`ios/Flutter/AppFrameworkInfo.plist`:** ‏`MinimumOSVersion` من `12.0` إلى `13.0`. الملف هو
  قالب `Info.plist` لإطار `App.framework` المحزوم، فبقاؤه على 12.0 يجعل الإطار يعلن حداً أدنى
  مختلفاً عن التطبيق (`IPHONEOS_DEPLOYMENT_TARGET = 13.0`) وعن `ios/Podfile` (`platform :ios,
  '13.0'`). المصدر الواحد الآن في ثلاثة ملفات برقم واحد: **13.0**.
- **`codemagic.yaml`:** أُضيفت أول خطوة تشخيصية `ls -1 /Applications | grep -i '^xcode' || true`
  تطبع إصدارات Xcode المثبتة على آلة البناء؛ فائدتها أن `xcode: "16.2"` إذا لم يكن
  متاحاً يفشل البناء برسالة متأخرة بعد دقائق، وهذه الخطوة تكشفه في الثانية الأولى وتُظهر
  القائمة التي يُختار منها.
- **`flutter test` (بوابة الخطة §ب-3):** `+471 ~10: All tests passed!` — 471 ناجحاً و10 متجاوزة
  و0 فاشل. هذا يعيد تأكيد البوابة الموثقة في `android_release_guide.md` §3.0 (لم يبق أي إخفاق
  قائم). السجل الكامل في `.zwork/ios_gate_test.txt`.
- **`flutter analyze`:** No issues found! (275.4 ثانية).
- **تدقيق آلي لسلامة الملفات (لا اعتماد على المراجعة البصرية):**
  - `Info.plist` يُقرأ بـ`plistlib` بلا خطأ (21 مفتاحاً)، والقيم المتحققة: الاسم العربي،
    إذن الصور، إذن الشبكة المحلية، Face ID، و`NSAppTransportSecurity` بالقيمتين المطلوبتين.
  - `project.pbxproj`: عدد `com.example` = 0، و`com.alkaboudy.app` = 6 (Runner ×3 + RunnerTests
    ×3)، و`IPHONEOS_DEPLOYMENT_TARGET = 13.0` = 3، و`12.0` = 0.
  - `AppIcon.appiconset`: الـ19 مرجعاً في `Contents.json` كلها ملفات موجودة، بمقاس = size×scale،
    ونمط RGB (بلا alpha) — أي أن مجموعة الأيقونات متسقة مع الفهرس تماماً.
  - `codemagic.yaml`: 6 خطوات، وفحص كل المفاتيح على مخطط Codemagic الرسمي = لا مفاتيح زائدة.
  - `git check-ignore` على كل ملفات الخطة = لا شيء مستثنى (ستُدفع كلها مع أول commit).
- **لم يُمسّ:** `lib/` · `android/` · `kyApp_API/` · `pubspec.yaml` (الإصدار `1.1.0+2` كما هو).
- **ما لا يمكن التحقق منه من ويندوز (بصراحة):** نجاح البناء الفعلي على macOS، وتوقيع الـIPA،
  وتشغيل التطبيق على الجهاز — كلها تتطلب Codemagic/آيفون، وقائمة تجربتها في
  `ios_release_guide.md` §5.

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:07 · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:25 — iOS: صلاحية Keychain (ثغرة تُفقد الجلسة بصمت) + لغة النظام العربية

- **كيف اكتُشفت:** مراجعة README كل حزمة iOS في مخزن pub المحلي (مصدر رسمي لا تخمين):
  `flutter_secure_storage_darwin-0.3.2` و`share_plus-12.0.2` و`local_auth_darwin-1.6.0`
  و`image_picker_ios-0.8.13` و`printing-5.14.3` و`url_launcher_ios-6.3.4`.
- **الثغرة (1):** README يقول حرفياً إنه يجب إضافة **Keychain Sharing** في
  `Runner/DebugProfile.entitlements` و`Runner/Release.entitlements` مع `keychain-access-groups`،
  وأن إغفالها (أو إغفال اسم App Group) يؤدي إلى «values appearing to be written successfully
  but never actually being written at all». الأثر على تطبيقنا: `ky_auth_token` و`ky_user_permissions`
  و`ky_session_expires_at` تُكتب بلا خطأ ولا تُحفظ، فيُطرد المستخدم لكل شاشة الدخول عند كل إقلاع
  ويُلغى تسجيل `local_auth` البيومتري. المشروع لم يكن فيه أي ملف entitlements إطلاقاً.
- **الحل (1):** ملفان جديدان (`ios/Runner/DebugProfile.entitlements` و`Release.entitlements`) بمحتوى
  `keychain-access-groups = ['$(AppIdentifierPrefix)com.alkaboudy.app']`، وربطهما بـ
  `CODE_SIGN_ENTITLEMENTS` في إعدادات هدف `Runner` الثلاث (Debug/Profile → DebugProfile،
  Release → Release)، مع إضافة مرجعيهما في `PBXFileReference` وفي أبناء مجموعة `Runner`
  ليظهرا في شجرة Xcode.
- **تنفيذ التعديل على `project.pbxproj`:** الملف حساس للتبويبات ونهايات الأسطر (تأكدنا أنه
  **CRLF خالص**: 616 = 616). كُتب سكربت لمرة واحدة يبني الأنماط بـ`\t` و`\r\n`، ويؤكد
  `assert count == 1` لكل مرساة، ويُدرج الأسطر الثلاثة، ثم حُذف السكربت بعد النجاح (684 حرفاً أُضيفت).
- **الثغرة (2):** README `share_plus` يطلب `CFBundleAllowMixedLocalizations` و`CFBundleDevelopmentRegion`.
  أُضيفا، وغُيّر `CFBundleDevelopmentRegion` من `$(DEVELOPMENT_LANGUAGE)` (يحل إلى `en`) إلى `ar`
  مع `CFBundleLocalizations = ['ar']` — فصار التطبيق معلناً نفسه عربياً وحده، فتظهر أذونات
  الصور/الشبكة وورقة المشاركة بالعربية حتى على جهاز إنجليزي (الواجهة أصلاً مفروضة بالعربية).
- **تحقق بعد التعديل (آلي):** `CODE_SIGN_ENTITLEMENTS` ×3 مربوطة بالإعدادات الصحيحة ·
  `CRLF == LF` (623/623) · الأقواس `{}` و`()` متوازنة · `Info.plist` يُحلّل بـ23 مفتاحاً بلا مفتاح مكرر ·
  الملفان يُقرآن بـplistlib ويحملان القيمة الصحيحة · الـ19 أيقونة سليمة · `AppFrameworkInfo` = 13.0 ·
  `codemagic.yaml` 6 خطوات مطابقة للمخطط · الدليل 18066 حرفاً.
- **ملاحظة أداة:** فحصان ظهرا فاشلين مؤقتاً ليس لعيب في الملفين بل لنفسير PowerShell للنص
  `$(AppIdentifierPrefix)` كتعبير فرعي داخل سلسلة مزدوجة الأقواس؛ أُعيد الفحص بقراءة مباشرة فنجحا.
- **لم يُمسّ:** `lib/` · `android/` · `pubspec.yaml` (الإصدار `1.1.0+2`).

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:25 · **لا commit** (لم يُطلب).

---

## 2026-11-01 01:55 — فشل `flutter build ios` على Codemagic: `.gitignore` بترميز cp1256

- **الخطأ كما ورد في السجل:**
  `Oops; flutter has exited unexpectedly: "FileSystemException: Failed to decode data using
  encoding 'utf-8', path = '/Users/builder/clone/.gitignore'"`، والأثر يشير إلى
  `SwiftPackageManagerGitignoreMigration.migrate (swift_package_manager_gitignore_migration.dart:45)`
  من `buildXcodeProject (src/ios/mac.dart:174)` — أي أنه يقع **قبل** أن تبدأ ترجمة Xcode.
- **التشخيص:** فُحصت بايتات كل ملف تقرأه أدوات البناء؛ النتيجة: `.gitignore` في الجذر بترميز
  **cp1256**، والسبب سطر تعليق عربي واحد:
  `# ملفات مخرجات الإصدارات الموقعة (APK) - كبيرة الحجم ولا تحكم` (بايتاته `\xe3\xe1\xdd\xc7\xca` = «ملفات»).
  أداة Flutter تستدعي `readAsStringSync()` بدون تحديد ترميز، فيفترض UTF-8 ويرمي استثناءً.
  ملفان آخران بنفس الترميز (`flutter_test_out.txt` و`php_test_full.txt`) لكنهما سجلان لا يقرأهما أي أداة،
  فتُركا كما هما احتراماً لقاعدة عدم تغيير البيانات السابقة.
- **الإصلاح:** تحويل `.gitignore` إلى UTF-8 بلا BOM وتوحيد نهايات الأسطر على LF. **التحقق:** المحتوى
  مطابقاً حرفاً بحرف لما كان قبل التحويل (51 سطراً، 32 نمطاً، مقارنة آلية) و`git diff` = سطر واحد.
- **منع التكرار (أداتان جديدتان):**
  - `tools/check_encoding.py`: بوابة ترميز. تفحص الملفات الحرجة (`.gitignore`، `ios/.gitignore`،
    `android/.gitignore`، `pubspec.yaml`) وتُوسّع التحذير إلى 500 ملف نصي متتبع، وتصلح بـ`--fix`،
    وتُرجع رمز خروج 1 عند بقاء ملف حرج معطوب — فنكتشف السبب محلياً بدل جولة بناء.
  - `tools/ios_audit.py`: تحويل الـ16 فحصاً اليدوي إلى أمر واحد قابل للتكرار قبل كل إصدار.
- **توثيق:** `ios_release_guide.md` — §4.2 صار يحوي الأمرين، وقسم جديد §4.2.1 يشرح هذا الفشل
  بعينه ونص رسالته وطريقة إصلاحه، وصف تشخيصي في جدول §7.
- **ما تأكّد من السجل (يزيل مخاطر سبق توثيقها):** الآلة وفّرت Xcode **16.2**
  (`/Applications/Xcode-16.2.app`، Build 16C5032a) وCocoaPods **1.16.2**، ونجحت خطوات
  `flutter pub get` و`flutter analyze` و`pod install` قبل خطوة البناء. فخطر "Xcode المطلوب غير متوفر"
  الذي حذرنا منه في §7 لم يقع، وFlutter 3.29.3 عمل على Xcode 16.2 كما هو المتوقع.
- **التحقق النهائي:** `tools/ios_audit.py` = ALL 16 CHECKS PASSED (رمز خروج 0) ·
  `tools/check_encoding.py` = RESULT: OK (4 حرجة + 500 نصي).
- **لم يُمسّ:** `lib/` · `android/` · `ios/**` · `pubspec.yaml` — الإصلاح ملف واحد في الجذر + أداتان.

**النموذج:** Qoder · **الوقت:** 2026-11-01 01:55 · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:10 — بوابتان جديدتان في codemagic.yaml: ترميز قبل البناء، وتحقق من الـIPA بعده

- **الدافع:** جولة البناء السابقة سقطت في ثانية على ملف بترميز خاطئ بعد أن استهلكت دقائق في التجهيز،
  والأسوأ أن رسالة الفشل لم تذكر الترميز. وأيضاً: نجاح `flutter build ios` لا يُثبت أن الحزمة
  تحمل فعلاً إعداداتها (وهي أعطال لا تظهر إلا على الجهاز بعد التثبيت).
- **الخطوة الثانية (جديدة) — `Encoding gate`:**
  `for f in .gitignore ios/.gitignore android/.gitignore pubspec.yaml; do iconv -f UTF-8 -t UTF-8 "$f"; done`
  مع `set -e`؛ تفشل في الثانية الأولى وترشد إلى `python tools/check_encoding.py --fix`.
- **الخطوة الثامنة (جديدة) — `Verify unsigned IPA`:** بعد التغليف مباشرة تقرأ
  `Payload/Runner.app/Info.plist` بـ`plutil -extract ... raw` (مدمج في macOS، فلا اعتمادية على
  Python) وتشترط: `CFBundleIdentifier = com.alkaboudy.app` · `NSAllowsArbitraryLoads = true` ·
  `NSAllowsLocalNetworking = true` · وجود وصف إذن الصور · وجود `Frameworks/App.framework`
  و`Frameworks/Flutter.framework`. وتطبع أيضاً الإصدار ورقم البناء والاسم للمطابقة البصرية.
- **التحقق قبل الدفع (ثلاث طبقات):**
  1. مطابقة مفاتيح المخطط الرسمي (workflow/environment/script) — لا مفاتيح زائدة.
  2. `bash -n` على نصوص الخطوات الثماني — بلا أخطاء نحوية.
  3. **اختبار سلوكي** لبوابة الترميز: نُفّذت داخل المستودع → exit 0؛ ثم في مجلد مؤقت فيه
     `.gitignore` مُرمّز cp1256 → exit ≠0 مع طباعة "is not valid UTF-8" وسطر الإصلاح.
     هذا يمنع أن تكون البوابة "سليمة نحوياً ولا تفعل شيئاً".
- **أثر على الأدوات/الوثائق:** `tools/ios_audit.py` صار يشترط 8 خطوات ووجود البوابتين بالأسم،
  **ويُجري `bash -n` على نص كل خطوة** (17 فحصاً إجمالاً — وقد أثبت جدواه فوراً: كشف سطراً
  نحوياً خاطئاً تسلل أثناء التعديل وأُزيل قبل الدفع)؛ و`ios_release_guide.md` اكتسب جدولاً
  جديداً §3.2.1 يشرح الخطوات الثماني وسبب كل واحدة.
- **ما لم يتغير:** لا مساس بـ`ios/**` ولا `lib/` ولا `android/` ولا `pubspec.yaml` — التغيير في ملف
  البناء والوثائق والتوثيق فقط.
- **النتيجة الحالية:** `tools/ios_audit.py` = ALL 17 CHECKS PASSED ·
  `tools/check_encoding.py` = RESULT: OK · العمل لم يُدفع بعد.

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:10 · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:23 — فحص جاهزية جهاز التثبيت (بيانات مقيسة) وتصحيح لبس الدفع

- **لبس أُزيل بقياس صحيح:** `git log origin/main..HEAD` كان فارغاً و`origin/main` المحلي يشير إلى
  الكوميت القديم، فبدا أن الإصلاح غير مدفوع. المرجع الحقيقي هو المستودع البعيد:
  `git ls-remote --heads origin` = **75f64201451b444a3640b8153f5aa35663ae3aac** وهو نفس `HEAD`.
  إذن البناء سيطّلع على الإصلاح. (المحلي `origin/main` لم يُحدَّث بـfetch — ليس دليلاً على عدم الدفع.)
- **قياس جاهزية ويندوز للتثبيت (أمراً بأمر، لا افتراضاً):**
  - `sideloadly` (PID) و`sideloadlydaemon` يعملان، ومجلد `%APPDATA%\Sideloadly` موجود.
  - `Get-AppxPackage *Apple*` → `AppleInc.iTunes 12139.12003.62022.0` أي **نسخة Microsoft Store**.
  - `Test-Path "C:\Program Files\Common Files\Apple\Mobile Device Support"` → **False**،
    و`Get-Service -Name Apple*` → **لا خدمة** (لا `Apple Mobile Device Service`).
  - `Get-PnpDevice` يُظهر `Apple iPhone` بحالة **Unknown** (لا OK) — أي أن الجهاز مرئي لويندوز
    لكن عقدة الجهاز غير مكتملة: شاشة مقفلة/غير موثوق/سائق غير مربوط.
- **الاستنتاج العملي:** إن أبلغ Sideloadly أنه لا يرى الجهاز، فالسبب معروف مسبقاً وهو غياب منظومة
  السائق الكلاسيكية: يُثبّت iTunes الكلاسيكي x64 من apple.com (يجلب AMDS و`usbaapl64`)،
  وأُزل نسخة المتجر إن تعارضت — وهو ما ينصّ عليه FAQ الجزء «Sideloadly does not show my device».
- **توثيق:** `ios_release_guide.md` — قسم جديد **§4.3.0** بأوامر الفحص الثلاثة وقراءة نتائجها،
  وتنبيه في §4.2 أن معيار «وصل الدفع» هو `git ls-remote` لا `origin/main` المحلي،
  وتحديث صفّي التشخيص (`Sideloadly لا يرى الجهاز` / `NP_E_CONN_FAILED`) بالإحالة إلى §4.3.0.
- **حالة المستودع:** ما عدا `ios_release_guide.md` وتحديثات هذه الجولة الوثائقية، كل شيء
  (`.gitignore` · `codemagic.yaml` · `tools/` · التوثيق السابق) مدفوع في 75f6420.
- **التحقق:** `tools/ios_audit.py` = ALL 17 CHECKS PASSED · `tools/check_encoding.py` = RESULT: OK.

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:23 · **لا commit** (لم يُطلب).

---

## 2026-11-01 02:35 — قياس جاهزية الشبكة: الـAPI متوقف والفايروول غير مُعدّ

- **قياسات مباشرة (لا افتراض):**
  - `Get-NetIPAddress` → `192.168.0.11` (Ethernet) · `192.168.178.176` (Wi‑Fi) ·
    `26.210.208.234` (Radmin VPN). **لا وجود لعنوان `192.168.0.9`** المكتوب في
    `ApiConstants.defaultBaseUrl` بين عناوين هذا الجهاز.
  - `Get-NetTCPConnection -LocalPort 8000 -State Listen` → **لا نتيجة**.
  - `Invoke-WebRequest http://127.0.0.1:8000/api/hello` → **فشل** (تعذر الاتصال).
  - `Test-NetConnection 192.168.0.9 -Port 8000` → **False** (timeout).
  - `Get-Service` (laravel/php/nginx/nssm) → لا خدمة؛ الموجود `bio-apache0` فقط.
  - `Get-NetFirewallRule` (8000/laravel/php) → **لا قاعدة**.
- **الأثر:** أي اختبار دخول من الآيفون سيعطي «فشل اتصال» وهو **عطل بيئي** لا علاقة له بـiOS
  ولا بإعدادات ATS التي أُضيفت. ولأن الجهاز على شبكتين مختلفتين (‎192.168.0.x‎ إيثرنت
  و‎192.168.178.x‎ واي فاي)، يجب أن يُختار عنوان **نفس شبكة الهاتف** لا غيره.
- **سلامة حزم iOS (تحقق إضافي):** قُرئت podspec الحزم الثماني (printing · share_plus ·
  flutter_secure_storage_darwin · local_auth_darwin · image_picker_ios · url_launcher_ios ·
  path_provider_foundation · device_info_plus): لا `static_framework` ولا `vendored_frameworks`،
  والاعتمادية الوحيدة `Flutter` (و`LinkPresentation` ضعيفة لـshare_plus) — فـ`use_frameworks!`
  + `use_modular_headers!` لا يُنتجان تعارضاً في `pod install` (وقد نجح فعلاً في البناء السابق).
- **توثيق:** `ios_release_guide.md` — قسم جديد **§5.0.1** يحمل جدول القياسات وأوامر
  `php artisan serve --host 0.0.0.0 --port 8000` و`New-NetFirewallRule` للمنفذ 8000،
  وأمر تحقق محلي، وقاعدة عملية: اختبر من Safari على الآيفون أولاً لفصل عطل الشبكة عن عطل التطبيق.
- **لم يُمسّ:** `lib/` و`android/` و`ios/**` و`pubspec.yaml`.

**النموذج:** Qoder · **الوقت:** 2026-11-01 02:35 · **لا commit** (لم يُطلب).

---

## 2026-11-01 — قسم المخازن: تنفيذ الوحدات الثمانية كاملةً (عميل + خادم)

**المرجع:** `docs/stores_module_plan.md` (معتمد بعد تعديلين: لا جدول جديد · الجرد بلا ترحيل).

### الفكرة الحاكمة

رصيد المخزون `ACCOUNTS.AVVG` محسوب من الـ VIEWs (`ITEM_MOVE_D` ← `ITEM_MOVEMENT_D`)،
فلا يوجد جدول أرصدة نكتب فيه. لذلك كل مستند يُكتب في جداوله القديمة داخل معاملة واحدة،
فيتحرك الرصيد فوراً ويظهر في البرنامج المكتبي.

### الخادم — ملفات جديدة

- `app/Support/StorePolicy.php` — `NON_STOCK_STORES = [2, 11, 12]` (مطابق لـ`ITEM_MOVEMENT_D`)،
  خرائط المستندات الثلاثة (typeno/التسلسل/الطرف)، الترقيم من التسلسلات، سقف التقرير 731 يوماً.
- `app/Support/InventoryLineGuard.php` — كل سطر يُفحص ويُثرى قبل الكتابة: وجود `SANF_DNO` تحت
  الصنف، `QTY > 0`، وكفاية الرصيد من `AVVG` للصرف والتحويل. **سبب وجوده:** الـ VIEW تربط السطر
  بالصنف الفرعي بـ`SANF_DNO`، وبالتحويل أيضاً بـ`SIZE_FRM/SIZE_TO = LEN/WID`؛ إغفال أي شرط يعطي
  مستنداً صامتاً بلا أثر على الرصيد — وهو أسوأ من الفشل.
- `app/Http/Controllers/Stores/` — ثمانية متحكمات:
  `StoreController` (مخازن + أمناء) · `StoreCatalogController` (مجموعات/أنواع/فئات/وحدات) ·
  `StoreItemController` (صنف + فرعي + وحدات) · `StoreOrderController` (أساس التوريد/الصرف) ·
  `ReceiveOrderController` · `IssueOrderController` · `TransferOrderController` ·
  `StoreReportController` (reference/balances/movement/summary) · `StockSheetController` (قراءة فقط).
- `routes/api.php` — 31 مساراً تحت `/stores`، كل مسار بصلاحيته، والحرفية قبل `{kind}`.

### قرارات تنفيذية مهمة

1. **التحويل = مستندان في معاملة واحدة**: `TYPENO=5` من المصدر + `TYPENO=4` إلى الهدف،
   مع نسخ `LEN/WID` إلى `SIZE_FRM/SIZE_TO` إجبارياً. القائمة تعرض النسخة الصادرة فقط.
2. **الحذف فيزيائي**: `ITEM_MOVE_D` لا يقرأ `FLAG_CANCEL`، فالإلغاء الناعم كان سيُبقي
   المستند مؤثراً على الرصيد. السجل يُكتب في `APP_USER_ACTIVITY` بعد نجاح المعاملة.
3. **حذف الصنف** مسموح فقط إن لم يكن له أي حركة (تُحذف أصنافه الفرعية ووحداته معه أولاً)،
   وإلّا يُوجّه المستخدم إلى التعطيل (`ACTIVE = 0`).
4. **المخازن 2/11/12** مستثناة من الأرصدة في الـ VIEW، فالخادم يرفض بـ422 إنشاء/تعديل مستند عليها.
5. **الرصيد السالب** يُعرض بوسم أحمر، ويرفض الخادم الصرف الذي يزيده إلا بمنح شامل + `allow_negative`.
6. **الجرد كشف حي بلا حفظ** (قرار المستخدم): لا نقطة كتابة في `StockSheetController` إطلاقاً،
   والكمية الفعلية تعيش في مزود الواجهة فقط.

### العميل — `lib/features/stores/`

- `data/models/`: `store_model` · `item_model` · `store_reference` (يشمل `STYLE`) ·
  `order_model` (و`StoreOrderKind`) · `report_model` (يشمل `StoreReportFilter`).
- `data/repositories/`: `stores_repository` · `store_items_repository` · `store_orders_repository` ·
  `store_reports_repository` + `store_result` (`StoreResult`/`StorePage`).
- `presentation/providers/`: `stores_providers` · `items_providers` · `orders_providers` ·
  `reports_providers` · `stock_sheet_providers`. كل جلب يحمل `CancelToken` + حارس
  `ref.mounted` بعد كل `await` (منعاً لـ`UnmountedRefException` عند مغادرة الشاشة).
- `presentation/screens/`: لوحة القسم · المخازن والأمناء · المرجعيات · الأصناف (قائمة/تفصيل/نموذج) ·
  الأوامر الثلاثة (قائمة/نموذج/عرض مشتركة بالمعامل) · الأرصدة · التقارير · كشف الجرد.
- `presentation/widgets/`: `store_ui` (تنسيقات وحالات) · `order_line_editor` (منتقي صنف→فرعي).
- `presentation/utils/store_export.dart`: PDF للمستند والتقارير وكشف الجرد + XLSX + طباعة/مشاركة.

### واجهات المستخدم المطلوبة (متحققة)

- الأوامر الثلاثة: قائمة + زر إنشاء + إجراءات (عرض/تعديل/حذف) + تحديد متعدد + بحث/فرز/تصفية.
- الأصناف: قائمة الرئيسية مع إجراءات، وفتح الصنف يعرض الفرعية والوحدات والأرصدة والحركة.
- التقارير: نافذة تحديد **تُفتح تلقائياً** (نوع/تاريخ/مخازن متعددة/مجموعة→فرعية/فئة/صنف/
  أنواع حركة متعددة تظهر ل «عرض حركة» فقط) ثم جدول بالتكبير والطباعة والتصدير.
- الجرد: كشف عدّ بفرق وقيمة فرق وتصفية «بفرق فقط» وطباعة/تصدير وتنبيه ثابت بعدم الترحيل.

### التوثيق و الاختبارات

- `docs/stores_module_plan.md` (الخطة المعتمدة) · `09_stores_sequences.sql`.
- اختبارات جديدة: `test/features/stores/store_models_test.dart` · `stock_sheet_test.dart` (18 اختباراً).
- تحديث `test/home_catalog_test.dart` و`test/home_notifier_test.dart` بعد إضافة بطاقات المخازن.

**البوابات:** `flutter analyze` = No issues found · `flutter test` = All tests passed ·
`php -l` على كل ملفات PHP = بلا أخطاء.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## 2026-11-01 (تكملة) — اختبارات الخادم والعميل، وأربعة أعطال حقيقية كشفتها

### أ) ما أُضيف من اختبارات (وفق §9 من الخطة)

**الخادم (Pest):** `tests/Unit/StorePolicyTest.php` (ثوابت السياسة والكتالوج) ·
`tests/Feature/StoreOrderWriteTest.php` (كتابة فعلية داخل معاملة تُلغى + كفاية الرصيد +
رفض المخزن الأرشيفي والسطر بلا صنف فرعي) · `tests/Feature/StoreReportTest.php` (حدود المدى،
الخلاصة، وثبات جداول المستندات أثناء الجرد) · `tests/Feature/StorePermissionTest.php`
(401/403/200 + التأكد أن كل مسار مخازن يحمل `permission:`). النتيجة: 20 اختباراً أخضر.

**العميل (flutter_test):** `store_models_test.dart` · `report_filter_test.dart` ·
`stock_sheet_test.dart` · `order_line_editor_test.dart` · `item_form_validation_test.dart`
(33 اختباراً)، وتحديث `home_catalog_test`/`home_notifier_test`،
و`IbacCoreTest`/`TailoringTest` (147 → 173).

### ب) أعطال حقيقية كشفتها الاختبارات وأُصلحت

1. **`ORA-00935` في الأرصدة والجرد** — `ORDER BY MAX(INVNAME), MAX(ITEM_NAME)` داخل كتلة
   مجمّعة محاطة بغلاف `ROWNUM`: أوراكل تدمج الكتلة فيتداخل التجميع. الحل: الترتيب بالأسماء
   المستعارة (`ORDER BY ITEM_NAME, INV_ID`) في `StoreReportController::balances`
   و`StockSheetController::index`.
2. **`ORA-00904` في تقرير الحركة** — `ITEM_MOVEMENT_D` لا تحمل `MANUAL_BILL_NO`؛
   الصحيح `DOC_NO AS MANUAL_BILL_NO`.
3. **فلتر «نوع الحركة» كان يرشّح نوع الصنف** — `TYPE_NO` في الـ VIEW هو نوع الصنف الفرعي
   (`sanfs.type_no`)، ونوع الحركة هو `BILL_DOC_TYPE`. كان المنتقي يعيد تقريراً فارغاً بلا
   سبب ظاهر. صُحّح الفلتر والإخراج (‏`BILL_DOC_TYPE AS TYPE_NO` و`TYPE_NO AS ITEM_TYPE_NO`)
   في التقارير وكارت الصنف.
4. **`ORA-00904` في قائمة المخازن** — عمود `STORES` اسمه `DISCOUNT_ACC` لا `DISCOUNT_ACC_NO`
   (كان يظهر في القراءة والإدراج والتعديل معاً)، ثم `Undefined array key "STORE_NO"` لأن
   منتقي OCI8 يعيد المفاتيح صغيرة الحروف — أُضيف تطبيع المفاتيح.
5. **انفجار تخطيط في محرر السطور** — `StoreSectionHeader` يحمل `Expanded` داخله وكان موضوعاً
   في `Row` بلا `Expanded`، فيصير عرضه غير محدود ويُرمى `RenderFlex ... unbounded`. صُحّح
   بتعليفه في `Expanded` — وهو عطل يظهر على أي هاتف لا في الاختبار فقط.

### ج) تشغيل البذر (المرحلة 1)

`php artisan tinker --execute="require '.../02_ibac_seed.php';"` بعد إصلاح تسلسل الكتالوج:
**173 كوداً** (26 الجديدة + 147 محدّثة)، و`stores` = 31 كوداً.

**البوابات:** `php artisan test` (اختبارات المخازن) = 20/20 · `flutter analyze` = No issues found ·
`flutter test` = All tests passed (522).

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## 2026-11-01 (تكملة ثانية) — إصلاح سجل التدقيق الميت وحارس التسلسلات

### أ) العطل الحقيقي الخامس (غير مرئي من أي بوابة)

بعد إصلاح تسلسل الكتالوج، فشل اختباران قائمان (`TailoringTest` · `CustomerMeasurementTest`)
يثبتان أن الطباعة والتصدير يتركان صف نشاط واحداً. السبب:

```
MAX(ACTIVITY_ID) = 840   |   SEQ_APP_ACTIVITY.NEXTVAL = 569
```

فتسلسل **سجل النشاط** كان متأخراً 271 رقماً، و`ActivityLogger` يبتلع `ORA-00001` في `try/catch`
كي لا يُسقط الطلب الأصلي — أي أن **سجل التدقيق كله لم يكتب صفاً منذ ذلك الحين**، وشاشات
سجل النشاط في الإدارة كانت تعرض صفوفاً قديمة فقط. عطل لا تلتقطه بوابة ولا شكوى مستخدم.

كشف مسبار شامل ثلاث تسلسلات أخرى على الحد أو متأخرة (`SEQ_APP_USERS_PERM` ·
`SEQ_APP_SETTINGS`)، فأُصلحت كلها بنمط 11g (`INCREMENT BY gap` ← `NEXTVAL` ← `INCREMENT BY 1`).

### ب) حارس دائم

`kyApp_API/tests/Feature/SequenceIntegrityTest.php`: اختبار لكل تسلسل من الستة
(`NEXTVAL > MAX(id)`) + اختبار إدراج حقيقي في `APP_USER_ACTIVITY` داخل معاملة تُتراجَع
(لا أثر يُترك). أي تسلسل يتخلف مستقبلاً يُسقط الاختبار قبل النشر.

### ج) تأكيد التدقيق من داخل اختبار الكتابة

`StoreOrderWriteTest` صار يثبت أيضاً أن إنشاء أمر توريد يكتب صفاً في `APP_USER_ACTIVITY`
بـ`ACTION_CODE = 'stores.receiving_created'` — أي أن الطلب ليس مجرد كتابة مخزنية بل عملية
مدقّقة، وأن التدقيق نفسه حي.

### د) البوابات النهائية

- `php artisan test --filter="StorePolicy|StoreOrderWrite|StoreReport|StorePermission|SequenceIntegrity"`
  ⇒ **27 passed (3285 assertions)**.
- `php artisan test --filter="TailoringTest|CustomerMeasurementTest"` ⇒ **20 passed (351 assertions)**.
- `flutter analyze` ⇒ **No issues found!** · `flutter test` ⇒ **All tests passed** (exit 0).

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## 2026-11-01 (تكملة ثالثة) — إغلاق فجوات الخطة: التخطيط الرئيسي-التفصيلي والإجراءات الجماعية ومؤشر السالب

جرد بنود الخطة بنداً بنداً كشف ثلاث فجوات حقيقية في العميل، فأُغلقت:

### ١) التخطيط الرئيسي-التفصيلي للأصناف (§7.3 د)

الخطة تطلب «قائمة + لوحة تفصيل جنباً إلى جنب» على الشاشات العريضة. كانت الشاشة تُدفع
لشاشة تفصيل كاملة دائماً (صحيح على الجوال، خطأ على سطح المكتب).

- `ItemDetailScreen` صار يقبل `embedded` ويُعيد المحتوى بلا `Scaffold`/شريط تطبيق ثانٍ،
  وأضيف زر التعديل إلى رأس اللوحة لأن اللوحة الجانبية بلا `AppBar`.
- `ItemsListScreen._splitBody` يستخدم `LayoutBuilder`: عند عرض أعرض من `splitBreakpoint = 900`
  تُعرض القائمة واللوحة معاً، وتُلغى اللوحة في وضع التحديد المتعدد (كل نقرة يجب أن تُحدد).
- على الجوال يبقى السلوك كما هو: `Navigator.push`.

### ٢) الإجراءات الجماعية في قوائم الأوامر (§7.3 ب)

كان شريط التحديد يحمل «تحديد الكل/مسح» فقط. أُضيف:

- `OrdersListNotifier.invertSelection()` — **عكس** محصور في الصفحة المعروضة، لأن الحذف فيزيائي
  فتوسيع التحديد إلى صفحات لم يفتحها المستخدم يجعل ضغطة واحدة تمسح ما لم يره.
- `OrdersListNotifier.removeMany()` — حذف جماعي تُجمع نتيجته بدل إسقاط الدفعة كلها عند أول فشل.
- `buildStoreOrderListPdf()` — مولّد PDF لقائمة رؤوس المستندات المحددة (طباعة جماعية)،
  ومعه تصدير عبر `StoreExporter.sharePdf`.
- الإجراءات الثلاثة محجوبة بالصلاحية، والحذف خلف تأكيد صريح.

### ٣) مؤشر «أصناف برصيد سالب» (§7.3 أ + §12 خطر 4)

كان الشريط يعرض أربعة مؤشرات ولا يعرض الأرصدة السالبة إلا **داخل** شاشة الأرصدة.
أُضيف من الخادم إلى الشاشة:

- `StoreController::index`: `SUM(CASE WHEN SUM_TP < 0 THEN 1 ELSE 0 END) AS NEGATIVE`
  في التجميع على `AVVG`، و`NVL(st.NEGATIVE, 0) AS NEGATIVE` في الاختيار.
- `StoreModel.negative` (تحليل مزدوج المفاتيح) و`StoresState.negativeCount`.
- بطاقة خامسة في لوحة القسم بلون خطأ عند وجود أرصدة سالبة، والنقر يفتح شاشة الأرصدة.
- **التحقق الحي:** المخزن 1 = 56 صفاً سالباً · 3 = 36 · 4 = 3، والإجمالي **95** صفاً.

### ٤) الاختبارات المستجدة

- `test/features/stores/items_split_test.dart` — 3 اختبارات: اللوحة على العريض، غيابها على
  الجوال، والحدّ فوق 768.
- `test/features/stores/orders_bulk_test.dart` — 4 اختبارات: عكس التحديد، عكسه مرتين،
  ما يتلقاه الإجراء الجماعي، ومسح التحديد.
- `flutter test test/features/stores/` ⇒ **40 اختباراً أخضر**.

### ٥) بوابة Pint المشغّلة

`vendor/bin/pint --dirty --format agent` شُغّل أخيراً: **16 ملفاً** (توحيد نهايات الأسطر،
مواضع الأقواس، مسافات المشغّلات). أُعيد تشغيل اختبارات المخازن بعده: **27/27 أخضر**.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## 2026-11-01 (تكملة رابعة) — استكمال أعمدة كشف الجرد (الفرق الأربعة + ملاحظة السطر)

### أ) تصفية الفرق صارت أربعة بدل واحد (§7.3 ح)

كان هناك مفتاح واحد «بفرق فقط». صار `enum StockCountFilter`:
`all` · `variance` · `surplus` · `shortage` · `uncounted`، وتُعرض كشرائح أفقية
(`ChoiceChip`) مع عدّاد «المعروض/الإجمالي» بجانب البحث.

- `visibleRows` تُرشّح حسب النوع، والفرق يُقاس على السطور المُعدَّدة فقط: سطر لم يُلمس
  لا «فرقاً» فيه. لغير المعدَّد تصفية مستقلة.
- `onlyVariance` بقيت **getterاً** للتوافق، و`toggleOnlyVariance()` صار تبديلاً سريعاً.

### ب) ملاحظة السطر (§7.3 ح)

- `StockSheetState.notes` + `noteOf()` + `hasNotes` + `setNote()` في المزود.
- زر ملاحظة بجانب كل سطر يفتح حواراً؛ النص يُعرض تحت الفرق في السطر.
- **الملاحظة تعيش في الحالة فقط** مثل الكمية الفعلية: لا تُرسل ولا تُحفظ — وهذا شرط D9.
- في التصدير: عمود «ملاحظة السطر» في XLSX دائماً، وفي PDF **فقط** إن وُجدت ملاحظة.

### ج) الاختبارات

- `stock_sheet_test.dart`: تصفية الزيادة/النقص منفصلين، و«بفرق فقط» يحتفظ بالاثنين،
  و«غير معدَّد» يعطي السطور غير الملموسة، و«الكل» يبقي الكل، واختبار أن الملاحظة
  **لا تُعدّ سطراً ولا تحرّك الفرق**.
- `flutter test test/features/stores/` ⇒ **44 اختباراً أخضر** · `flutter analyze` = No issues.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## 2026-11-01 (تكملة خامسة) — انحرافان موثقان عن نص الخطة، وسببهما

الجرد النهائي للخطة كشف بندين نُفّذا بقراءة مختلفة عن نصّهما الحرفي. لم يُغيَّر السلوك
لأن الحرف فيهما يتعارض مع بند آخر من الخطة نفسها:

### ١) D8 — حذف صنف له أصناف فرعية

نص الخطة: «حذف الصنف ممنوع إن كان له حركة **أو أصناف فرعية**».

**التطبيق:** ممنوع إن كان له **حركة** (422 برسالة عربية تعدّ الحركات وتوجه للتعطيل)،
وإن لم يكن له حركة يُحذف ومعه فرعياته ووحداته (الأبناء أولاً احتراماً للمفاتيح الأجنبية).

**السبب:** §7.3 (د) من الخطة نفسها تفرض أن إنشاء الصنف يُنشئ **أول صنف فرعي في نفس النموذج**
(لأن `SANFS_D` شرط لظهور الصنف في المستندات). معنى ذلك أن كل صنف له فرعي واحد على الأقل،
فلو رُفض الحذف عند وجود فرعي لصار كود `stores.items_delete` ميتاً لا يعمل أبداً، وتعلق
أي صنف أُنشئ بالخطأ بلا وسيلة تنظيف. الحماية الحقيقية هي الحركة، وهي مفروضة.

### ٢) D3 — توقيت سطر التدقيق عند الحذف

نص الخطة: «تسجيل نسخة تدقيق **قبل** الحذف».

**التطبيق:** يُكتب سطر التدقيق **بعد نجاح المعاملة** (وفي الكود تعليق صريح بذلك).

**السبب:** الهدف المعلن في D3 هو أن يكون الحذف **قابلاً للمراجعة**. الكتابة داخل معاملة
الحذف نفسه تُلغى مع التراجع (فيسقط السطر عند الفشل)، والكتابة قبل المعاملة تُنتج تدقيقاً
لحذف قد لا يحدث. الكتابة بعد النجاح تُعطي السلوك المطلوب (كل حذف ناجح له سطر، وكل فشل
بلا سطر) — وهو ما يثبته `StoreOrderWriteTest` بفحص `ACTION_CODE = 'stores.receiving_created'`.

**الحد المخبول:** لو ماتت العملية بين commit الحذف وكتابة السطر، يسقط سطر واحد. لا يمكن
سد هذه الثغرة إلا بكتابة السطر داخل المعاملة نفسها، وهذا قرار يحتاج تأكيداً من صاحب النظام
لأنه يغيّر شكل العزل. مُسجّل هنا لاكثر ما هو مُنفَّذ فعلاً.

**النموذج:** Qoder · **الوقت:** 2026-11-01 · **لا commit** (لم يُطلب).

---

## إصلاح ظهور حرف «ص» مشوّهًا/مدموجًا في PDF (عطب الموضع الطرفي في dart_pdf) — 2026-11-02

**المُنفِّذ:** Qoder · **الوقت:** 2026-11-02 10:20 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

### العطب
- حرف «ص» تحديدًا (ونظرائه: ض ط ظ ع غ ح، وأي حرف طرفي) كان يظهر في كل كشوفات/تقارير PDF
  بلا ذيله اليميني الذي يربطه بالسابق، فيبدو مشوّهًا ومدموجًا مع الحرف السابق. بقية الحروف
  كانت تتأثر نفس التأثير لكن الفارق البصري شبه معدوم (isolated ≈ final)، أما ص فضربه واضح.

### التحليل بأدلّة
- فحص جدول `_arabicSubstitionA` في الحزمة `pdf` 3.11.3: الترتيب في تعليق الصف هو
  `(isolated, final, initial, medial)`، بينما القيم المُخزّنة فعليًا وفق Unicode هي
  `(isolated, initial, medial, final)` — أكدناه بـ codepoints.net: U+FEBA = Sad
  **Isolated**، U+FEBB = Sad **Initial**، U+FEBC = Sad **Medial**، U+FEBD = Sad
  **Final** (وليس كما يدّعي dart_pdf).
- المُشكِّل يطلب الطرفي عبر `array[1]` فيحصل على المعزول (FEBA)، ويطلب الإبداعي عبر
  `array[2]` فيحصل على الإبداعي (FEBB) — صحيح بالصدفة. الوسطي `array[3]` = FEBC — صحيح
  بالصدفة. المعزول لا يُقرأ من الجدول إطلاقًا (الموضع 0 يُرجع نقطة الأساس U+0635).
- الخلاصة: **كل FE_x0 في الناتج = طرفي ملتبس**، والحل: تحويله إلى FE_x3 (أو FE_x1
  للحروف ذات النموذجين). القاعدة: `final = isolated + (entryLength − 1)`.

### الحل
- إضافة خريطة ثابتة `_finalFormFix` في `lib/core/utils/report_pdf_arabic.dart`: كل
  نقطة معزولة ↔ طرفيتها الحقيقية، 35 مدخلاً (11 حرفًا ذا نموذجين + 24 حرفًا ذا أربعة).
- دالة `_applyFinalFormFix` تمشي على runes الناتج بعد `arabic_shaper.convert(text)` وقبل
  عكس ترتيب الكلمات. المسار مختصر: إذا لم تظهر أي نقطة في الخريطة تُترك كما هي (الأرقام
  والإنجليزي لا تتأثر).
- استثناء مقصود: الألف المقصورة U+FEF0→U+FEF1 لم تُضمَّن لأن Cairo المضمّن لا يغطي FEF1
  (أكدناه باختبار)، والفارق البصري بين معزولها وطرفيها معدوم. إبقاؤها كما هو أنجع من
  تقديم مربع فارغ بدلًا منها.

### الاختبار
- تحديث `test/core/report_pdf_arabic_test.dart` بمجموعة جديدة «final-form fix» بأربعة
  اختبارات: ص في «النص» → U+FEBD · ص في «مواصفات» تبقى على U+FEBB (وسط/إبداعي سليم)
  · عينة عشرة حروف طرفية · استثناء الألف المقصورة.
- **النتيجة:** `flutter analyze` = No issues found! · `flutter test` = **536 ناجحًا و10 متجاوزة**.

---

## 2026-11-02 — تطوير أوامر التوريد/الصرف/التحويل: بطاقات رسمية، وعرض مطابق للقالب، ونماذج مطابقة للصور

**المطلوب:** (1) تحسين بطاقات القوائم ترتيباً وتنسيقاً وعرضاً رسمياً، (2) شاشات العرض والتقارير
مثل قالب `استعراض التوريد.pdf` بالظبط مع ترويسة التطبيق وتذييله الرسميين، (3) نماذج الإضافة
والتعديل مثل صور النظام المكتبي.

### أ) الخادم — بيانات المستند الكاملة

- `StoreOrderController::fetchHeader`: كل خانات الرأس — `BILL_TYPE` و`SELECT1` و`PROV_BILL`
  و`ENTRY_NO` و`DIS_RATE` و`ACC_NO/ACC_NO1/ACC_NO2` **بأسمائها** من `CHART_ACC`، وصفّا عملة
  بأسمائهما من `CURRENCY`، وشريط التدقيق كامل (`CREATED_BY_NAME` و`THE_TIME` و`LAST_UPDATED_*`).
- `StoreOrderController::fetchLines`: أعمدة القالب كلها — `PCS` و`CAP` و`SHELF_NO` و`SIZE_FRM/SIZE_TO`
  و`CATEGORY` و`COLOR_NO` باسمه من `SANFS_COLOR`، واسم الصنف الفرعي وكوده وباركوده من `SANFS_D`،
  والتصنيف من `TYPES`/`GROUP1`، ومتوسط التكلفة `STK_COST/SANF_COST`.
  **المقاسات تُقرأ من السطر نفسه لا من الصنف الفرعي**: المستند التاريخي لا يتغيّر بتعديل الصنف.
- `index`: أضافت `BILL_TYPE` و`DIS_RATE` و`ENTRY_NO` و`PROV_BILL` و`CUR_NAME` و`THE_TIME`
  وأعمدة التعديل، و`QTY` المجمّعة — وهي ما تحتاجه البطاقة الرسمية.
- **الحفظ:** `insertHeader` صارت تكتب نوع الفاتورة واختيار العملة ونسبة الخصم والحسابين وصفا
  العملة، و`حساب المخزن` يأخذ قيمته الافتراضية من `STORES.INV_ACC_NO` كما يفعل النظام.
  قائمة الأعمدة تُبنى ديناميكياً لأن `PROV_BILL` موجود في التوريد وغير موجود في الصرف.
- `insertLines` صارت تحفظ `PCS` و`SHELF_NO` و`SIZE_FRM/SIZE_TO` و`CATEGORY` (بترميز CP1256).
- `InventoryLineGuard`: يثري السطر بالفرعي والعبوة والتصنيف ويشتق `PCS = الكمية × العبوة`.
- `TransferOrderController`: نفس الإثراء للرأس والسطور والقائمة، وحفظ الخصم والحسابين واختيار
  العملة، وقراءة أسماء المستخدمين من `APP_USERS` (جدول التحويل لا يملك عمود اسم).
- **عطل كتابة صامت أُصلح:** سطر التحويل كان يكتب `'تحويل مخزني'` خاماً في `DETAILE` بلا
  `ArabicEncoding::toOracleSearchChars`، فيظهر mojibake في النظام المكتبي.
- `GET /stores/accounts` جديد (بحث في `CHART_ACC`، 30 صفاً، بلا أرصدة) خلف صلاحيات الأوامر.
- `/stores/reference` أضاف `currencies` و`colors` و`bill_types`.

### ب) العميل — مصدر واحد للقالب

- `presentation/utils/store_document_layout.dart` جديد: `StoreDocColumn` +
  `storeDocumentColumns(kind)` + `storeDocumentMinWidth`. **الشاشة و PDF يقرآن نفس القائمة**،
  فاستحالة انحراف الطبعة عن العرض مضمونة بالبناء لا بالانتباه.
- `core/utils/arabic_number_words.dart` جديد: تفقيط المبلغ بالعربية. يعطي 303100 →
  «ثلاثمائة و ثلاثة ألف و مائة ﷼ يمني» مطابقة لطبعة النظام حرفياً، مع الجمع بين 3-10
  (`ثلاثة آلاف`) والتثنية (`ألفان`) وتقديم الآحاد على العشرات، والكسر كوحدة صغرى.
- `order_view_screen.dart`: إعادة كتابة كاملة — `ReportZoomView` + `ReportA4Sheet` أفقي +
  `ReportLetterheadBranding` (ترويسة التطبيق الرسمية) + عنوان المستند + شبكة خانات الرأس +
  جدول السطور بكل الأعمدة (رأس ذهبي `#D4A853` وحدود ونِسَب `FlexColumnWidth`) + شريط المجاميع
  الأربعة + سطر التفقيط + البيان + `ReportSignatureFooter` (التذييل الرسمي).
- `buildStoreOrderPdf`: أُعيد بناؤه على نفس القالب — رأس موحّد، خانات رأس بجدول، جدول سطور
  بكل الأعمدة (معكوس لأن `pw.Table` يرسم LTR)، مجاميع + تفقيط، توقيعات، وتذييل بترقيم الصفحات.
- `orders_list_screen`: بطاقة رسمية بشريط نوع ملوّن، وعنوان برقم المستند، وشبكة ثلاث خانات
  متساوية بحدود (`IntrinsicHeight`)، وشريط مجاميع (الإجمالي/الخصم بالنسبة/الصافي)، والبيان
  بسطر واحد، وذيل تدقيق (من أدخل ومتى، ومن عدّل)، و**إجراءات ظاهرة** بدل قائمة منسدلة مخفية.
- `order_form_screen`: إعادة كتابة كاملة مطابقة للصور — رأس بكل الخانات، صفا عملة بسعرين،
  خيار العملة المحاسبية براديو، مُنتقي حساب بنافذة بحث، لوحة مجاميع بنسبة الخصم، شريط
  الإدخال/التعديل، وزر «جديد» يفرّغ النموذج.
- `order_line_editor`: `OrderLineDraft` صار يحمل العبوة والرف والتصنيف واللون والوحدة، والسطر
  يعرض شريط خواص بأعمدة النظام، وحقل عبوة قابل للتعديل يرفض الصفر، والقطعة تُشتق.
- نماذج: `StoreOrderModel` و`StoreOrderLineModel` و`ItemSubModel` و`StoreReference` موسَّعة
  بالحقول الجديدة، بمفاتيح مزدوجة الحالة وتحليل دفاعي و`ArabicEncodingUtils.fix` للعربية.

### ج) البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` (الحزمة) | **536 نجحت · 10 متجاوزة** |
| `flutter test test/features/stores/` | **61 اختباراً** (منها 15 جديدة للقالب والتفقيط) |
| `php artisan test --filter="StoreOrderWrite\|StorePermission"` | **8 نجحت** |
| `php artisan test --filter="StorePermission\|StoreReport"` | **10 نجحت / 3182 تأكيداً** |
| `vendor/bin/pint --dirty` | ملف واحد، ثم إعادة التحقق أخضر |

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **لا commit** (لم يُطلب).

---

## 2026-11-02 12:00 — شريط التنقل السفلي العائم (FloatingNavBar)

### ما تغيّر

- ودجت جديد `lib/features/employee_portal/presentation/widgets/floating_nav_bar.dart`: كبسولة داكنة
  عائمة (`navBarDark`) بحواف كاملة الاستدارة وظل سفلي، أيقونات خطية من السجل المركزي بلا تسميات،
  مؤشّر علوي صغير بلون التطبيق الأساسي (`AppColors.primary`) ينزلق بين التبويبات عبر
  `TweenAnimationBuilder` (260ms)، وهالة بيضاء شفافة حول الأيقونة المحددة.
- الاتجاه RTL محترم تلقائياً لأن المؤشّر يستخدم `Align` الذي يقرأ `Directionality` من السياق.
- لونان ثابتان جديدان في `AppColors`: `navBarDark = 0xFF2E3A4F` و`navBarIcon = 0xFFA7B2C5` —
  التزاماً بقاعدة عدم كتابة الألوان داخل الودجتات.
- `employee_main_layout.dart`: مُستبدلت `NavigationBar` بـ `FloatingNavBar` مع بقاء كل المنطق:
  الأقسام الموسومة `showInBottomBar` بعد تصفية المنح، تخزين معرّف القسم لا الفهرس، وخفاء الشريط
  كلياً عند أقل من وجهتين.
- `test/responsive_layout_test.dart`: تحديث ثلاث تأكيدات من `NavigationDestination` إلى
  `FloatingNavBar` (موجود/غير موجود)، لأن الودجت الجديد لا يستخدم وجهات Material.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` (employee_portal + theme + الاختبار) | **No issues found!** |
| `flutter test test/responsive_layout_test.dart test/session_expiry_fix_test.dart` | **53 ناجحاً** |
| `flutter test test/ibac_test.dart` | **20 ناجحاً** |

**النموذج:** Qoder · **الوقت:** 2026-11-02 12:00 · **لا DDL** · **لا DML** · **لا commit**.

> **تصحيح أرقام البوابات (نفس الجلسة، 2026-11-02):** بعد إضافة order_view_screen_test.dart وإعادة التحقق النهائي: lutter test = **537 ناجحاً و10 متجاوزة**، وlutter test test/features/stores/ = **66 اختباراً**، وphp artisan test (المخازن + حارس التسلسلات) = **27 نجحت / 3287 تأكيداً** بعد Pint. الأرقام أعلاه مأخوذة من تشغيل أوسط لا من النهائي.

---

## 2026-11-02 12:30 — تصحيحان على الشريط السفلي العائم

### أ) الألوان تتبع السمة الزمنية (لا لون ثابت)

- أُزيل اللونان الثابتان `navBarDark`/`navBarIcon` من `AppColors`؛ كانا يعاكسان تهيئة التطبيق
  القادمة من الخادم عبر `AppPalette`.
- `FloatingNavBar` صار يقرأ كل ألوانه من `AppColors` الزمني: جسم الكبسولة `surface` مع حدود
  `border`، الأيقونة المحددة والمؤشّر العلوي `primary`، غير المحددة `textSecondary`، والظل
  مشتق من `textPrimary` الشفاف بدل أسود ثابت.

### ب) انعكاس المؤشّر العلوي في RTL

- كان المؤشّر العلوي يوضع بالإحداثي الفيزيائي `Alignment(x, -1)`، بينما صفّ الأيقونات يترتّب
  حسب الاتجاه (الفهرس 0 يميناً في RTL)، فكان المؤشّر يشير إلى التبويب المقابل للمحدد.
- استُبدل بـ `AlignmentDirectional(x, -1)` ليقرأ الاتجاه من السياق ويصطفّ فوق التبويب الصحيح.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` (employee_portal + theme + الاختبار) | **No issues found!** |
| `flutter test test/responsive_layout_test.dart` | **44 ناجحاً** |

**النموذج:** Qoder · **الوقت:** 2026-11-02 12:30 · **لا DDL** · **لا DML** · **لا commit**.

---

## 2026-11-02 13:00 — إزالة المؤشّر العلوي من الشريط السفلي العائم

- طُلب حذف المؤشّر الصغير الذي يظهر فوق التبويب المحدد. حُذف كلاس `_SlidingIndicator`
  بالكامل مع ثوابت مقاساته (`_indicatorWidth`/`_indicatorHeight`) والـ `Positioned` الذي يستدعيه.
- أُزيلت طبقة الـ `Stack` والمساحة العلوية الإضافية (`_barHeight + 12`) التي كانت مخصّصة
  للمؤشّر؛ صار الودجت يرسم الكبسولة (`DecoratedBox` + `Row`) مباشرة بارتفاع `_barHeight`.
- تحديد التبويب النشط يبقى واضحاً عبر هالة `primary` الشفافة ولون الأيقونة الأساسي.

| البوابة | النتيجة |
|---|---|
| `flutter analyze` (floating_nav_bar.dart) | **No issues found!** |
| `flutter test test/responsive_layout_test.dart` | **44 ناجحاً** |

**النموذج:** Qoder · **الوقت:** 2026-11-02 13:00 · **لا DDL** · **لا DML** · **لا commit**.

---

## إصلاح تشوّه العربية في الواجهة (عناوين ونصوص عريضة وحروف «و» «ص») — عريض اصطناعي

**المُنفِّذ:** Qoder · **الوقت:** 2026-11-02 13:40 · **لا DDL** · **لا DML** · **لا commit** (لم يُطلب).

### العطب
- في واجهات النظام نفسها (وليس التقارير): النصوص العريضة والعناوين وحروف مثل «و» و«ص»
  تظهر مشوّهة/مدموجة. الصورة المرفقة (لوحة مفاتيح/اختصارات الرئيسية) تُظهر ذلك في العناوين.

### السبب الجذري
- السمة في `lib/core/theme/app_theme.dart` كانت تبني العائلة عبر
  `GoogleFonts.getFont(font).fontFamily` ثم تُطبّقها على كامل الـ TextTheme بـ
  `.apply(fontFamily:)`. هذا يُحمّل وزن Cairo **العادي (400)** فقط؛ أما الأنماط العريضة
  (headline/title بوزن 700) فتطلب Cairo-Bold من نفس العائلة دون أن يكون مُسجّلاً،
  فيُطبّق محرّك Flutter **عريضًا اصطناعيًا (synthetic bold)** بتوسيم/تسمين الحروف —
  والعربية متّصلة، فيتداخل الرسم وتدمج الحروف، ويظهر واضحًا في حروف ذات كُتل/عُقد مثل
  «و» و«ص». وعلى LAN بلا إنترنت يفشل تنزيل google_fonts أصلًا فتسوء الحالة.

### الحل
- **تحويل Cairo إلى عائلة خط Flutter حقيقية مضمّنة**: أُعلن في `pubspec.yaml` قسم
  `fonts:` لعائلة `Cairo` بوزنين فعليين: `Cairo-Regular.ttf` (400) و`Cairo-Bold.ttf`
  (700) — وهما الملفان المضمّنان سابقًا في `assets/fonts/` لنفس مسار التقارير.
- في `app_theme.dart`: عند اختيار Cairo تُستخدم العائلة المضمّنة `'Cairo'` مباشرة
  (بلا google_fonts وبلا تنزيل شبكي)، وبقية الخطوط المختارة (Tajawal/Almarai/…)
  تبقى عبر google_fonts كما هي. أُضيف مساعدان `_isBundledCairo` و`_font` يوحّدان بناء
  TextStyle لكل من AppBar/الأزرار/الحقول. الآن الوزن 700 يجد وجه Cairo-Bold الحقيقي
  فلا يوجد عريض اصطناعي، وتُحلّ المشكلة بصرياً.

### الاختبار
- جديد `test/core/app_theme_font_test.dart`: يتحقق أن عائلة السمة الافتراضية = `'Cairo'`
  المضمّنة وأن عنوان AppBar العريض ونص الأزرار على العائلة نفسها.
- **النتيجة:** `flutter analyze` = No issues found! · `flutter test` = **538 ناجحًا و10 متجاوزة**.

---

## 2026-11-02 (عاجل) — عطل كسر قوائم وتفصيل وكتابة أوامر الصرف

**الشكوى:** قائمة أوامر الصرف لا تعرض شيئاً وتُرجع `ORA-00904` على العمود `M.PROV_BILL`.

### الجذر

أضفتُ أعمدة رأس المستند إلى استعلام مشترك بين التوريد والصرف، لكن **المخطط القديم غير متماثل**:

- `PROV_BILL` موجود في `INVENTORY_RECEIVE` وغير موجود في `INVENTORY_SARF`.
- `CURNO`/`CURPRICE` موجودان في `INVENTORY_RECEIVE_DETAILES` وغير موجودين في `INVENTORY_SARF_DETAILES`.

فأي عمود يُكتب ثابتاً في المسار المشترك يُسقط النوع الآخر كله.

### خمسة أعطال لا عطل واحد

1. **القائمة** (`index`): `m.PROV_BILL` ثابت ⇒ ORA-00904 ⇒ شاشة فراغ. هذا ما رآه المستخدم.
2. **رأس التفصيل** (`fetchHeader`): نفس العمود ثابتاً ⇒ تفصيل الصرف كان مكسوراً هو الآخر.
3. **سطور التفصيل** (`fetchLines`): `d.CURNO, d.CURPRICE` ثابتان ⇒ تفصيل الصرف 500.
4. **الكتابة** (`insertLines`): نفس العمودين في الإدراج ⇒ **حفظ أمر صرف كان مستحيلاً**، ولم يره أحد لأن لا اختبار يكتب صرفاً.
5. **الروابط الزائدة**: بعد جعل الأعمدة اختيارية بقيت أسماء `party_bill`/`cur_no`/`cur_price` في مصفوفة الربط بلا مقابل في النص، ومنتقي OCI8 لا يتجاهل الزائد بل يرمي `ORA-01036: illegal variable name/number`.

### الإصلاح

- `referenceColumn(): ?string` + `referenceSelect()` + `referenceSetClause()`: المرجع يُذكر حيث يوجد فقط (التوريد)، ويُسمّى `PARTY_BILL` على الجانبين فلا يختلف عقد العميل بين النوعين.
- `lineCurrencyColumns(): array` + `lineCurrencySelect()`: عملتا السطر تُضافان لسطور التوريد فقط، و`insertLines` تبني قائمة أعمدة ديناميكية.
- `bindOnlyUsed($sql, $binds)`: تُسقِط أي رابط غير موجود في النص قبل `update` و`insert` والسطور — مطابقة الربط للنص شرط في OCI8 لا تفصيل جمالي.
- عميل Dart: `partyBill` تقرأ `PARTY_BILL` ثم `party_bill` ثم `PROV_BILL` للتوافق مع الاستجابة القديمة.

### اختبارات تسدّ الثغرة التي سمحت بالعطل

- `StorePermissionTest` — «the three order lists answer an administrator with a real envelope» و«the document detail reads for every kind that has documents»: اختبار الصلاحيات القديم كان يفتح المخازن والأصناف والتقارير فقط، ولا نداء واحداً على `/stores/issue`، فمرّ العطل أخضر.
- `StoreOrderWriteTest` — «every document kind can be created, read back and deleted»: إنشاء ثم قراءة ثم حذف لكل نوع داخل معاملة تُتراجع. هذا الاختبار هو الذي كشف عطلَي ORA-00904 و ORA-01036 في مسار كتابة الصرف.

### التحقق

| البوابة | النتيجة |
|---|---|
| `php artisan test` (المخازن + حارس التسلسلات) | **30 نجحت / 3366 تأكيداً** |
| السيرفر الحيّ على `127.0.0.1:8000` | 10 مسارات ⇒ **HTTP 200 success=yes** (القوائم الثلاث، التفصيل الثلاث، المرجع، الحسابات، الأصناف، المخازن) |
| `flutter analyze` | **No issues found!** |
| `flutter test` | **538 ناجحاً · 10 متجاوزة** |
| `vendor/bin/pint` | مطبَّق على الملفات الأربعة المعدَّلة |

### نظافة قاعدة العميل

أنشأت المسبارات توكنات فحص لتجربة المسارات الحيّة؛ **حُذفت كلها (0 باقٍ)**. التنظيف كشف حقيقة أوراكلية: عمود `NAME` في `PERSONAL_ACCESS_TOKENS` نوعه **CLOB**، فالمقارنة بـ`=` ترمي `ORA-00932`، ويلزم `DBMS_LOB.SUBSTR(NAME, 4000, 1) LIKE …`.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **لا جدول جديد** · **لا commit** (لم يُطلب).

---

## 2026-11-02 (تكملة) — فصل الأنواع الثلاثة: كل مستند بحقوله لا قالب واحد للجميع

**المطلوب:** «ركز أن كلاً من أوامر التوريد/الصرف/التحويل يختلف عن الآخر وليسوا متطابقين في كل الحقول».

**المشكلة في التنفيذ السابق:** كان هناك قالب واحد مع شرطين فقط (`reference`، وعملة السطر). أما بقية الفوارق فكانت مكتوبة كشروط متفرقة في الشاشات، والنتيجة أنها إما لا تظهر أو تظهر في نوع لا يملكها.

### أ) البدء بجرد المخطط لا بالتخمين

قرأتُ `ALL_TAB_COLUMNS` عبر **اتصال التطبيق** للجداول الستة، فظهر أن الأنواع مختلفة بنيوياً لا شكلياً:
`PROV_BILL` للتوريد فقط · `SEQBILL` للصرف · `STORE_TO`/`TYPENO`/`TR_INV_M_ID` للتحويل ·
`CURNO`/`CURPRICE` لسطور التوريد فقط · `TOTALD` بدل `TOTAL` في سطور التحويل ·
والتحويل بلا `CREATED_BY_NAME` ولا `LAST_UPDATED_BY_NAME` أصلاً.
(التفصيل الكامل في `DBdevloping_history.md`.)

### ب) الخادم: تعريف صريح لكل نوع

- `StorePolicy::documents()` لكل نوع: `title` + `fields` تعلن:
  `bill_type` · `reference` (وعموده) · `reference_writable` · `party` (واسمه) ·
  `target_store` · `serials` · `movement_type` · `entry_no` · `discount` ·
  `currency_pair` · `line_currency` · `line_cost` · `line_pack` · `line_available`.
- `StorePolicy::fieldsOf(kind)` و`StorePolicy::documentProfiles()` — الأولى تقرأها المتحكمات، والثانية تُعرض للعميل في `/stores/reference`.
- `StoreOrderController` لم يبقَ فيه شرط `kind == receive`:
  `referenceColumn()` و`referenceWritable()` و`lineCurrencyColumns()` تُشتق كلها من `fieldsOf`.
  حُذفت التعريفات المكررة من `ReceiveOrderController`.
- `reference_writable` جديد: التوريد فقط. الصرف يعرض `SEQBILL` **للقراءة** لأنه رقم تسلسلي داخلي لا نص مرجعي — وكتابته تنتهك نوع العمود.

### ج) العميل: وصف مرآة + أعمدة لكل نوع

- `StoreDocProfile` جديد في `store_document_layout.dart`: مرآة لجدول الخادم مع `hasX` لكل علم، وتعريفات افتراضية حتى ترسم الشاشة قبل وصول المراجع (الخادم يبقى الفيصل عند الحفظ).
- `storeDocumentColumns` أضحت **ثلاث قوائم** تُبنى من دوال صغيرة:
  • التوريد: يضم **عبوة/قطعة** و**لا** متوسط تكلفة.
  • الصرف: يضم **متوسط التكلفة** و**لا** عبوة، ومع **رقم الرف**.
  • التحويل: عمود **التكلفة** بدل «سعر الصنف»، وبلا **رقم رف** وبلا **عبوة/قطعة**، وبمتوسط التكلفة.
- `order_view_screen`: العنوان والخانات والمجاميع من الوصف — التحويل لا يعرض «نوع الفاتورة» ولا «نسبة الخصم %» ولا «مبلغ الخصم» ولا صف العملة، ويعرض «مسلسل المنصرف/الوارد».
- `order_form_screen`: كل خانة تظهر حيث توجد فقط — نوع الفاتورة للتوريد/الصرف، رقم المرجع **قابل للتحرير في التوريد فقط**، صفا العملة والخيار المحاسبي للتوريد/الصرف، الخصم للتوريد/الصرف، ولا خانات عملة/خصم للتحويل.
- `store_export.dart` (PDF): نفس الوصف يقود الرأس والمجاميع، والأعمدة من نفس الدالة — فالطبعة تختلف باختلاف النوع كما تختلف الشاشة، ولا يمكن أن تنحرف إحداهما.

### د) اختبارات تُثبت الاختلاف لا التشابه

- Dart: «the three kinds are genuinely different documents, not one list renamed» — تثبت وجود/غياب أعمدة محددة في كل نوع، وأن أي قائمتين ليستا متطابقتين.
- Dart: «the profiles declare different header fields per kind» — تثبت أن التحويل بلا `hasBillType`/`hasDiscount`/`hasCurrencyPair`، وأن مرجع الصرف غير قابل للكتابة.
- Pest: «each document kind declares its own fields and they differ» و«the client-facing profiles expose the same distinctions» — تثبت تطابق ما يعلنه الخادم مع ما يراه العميل.

### هـ) البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **540 ناجحاً · 10 متجاوزة** (اختبارات المخازن **68**) |
| `php artisan test` (المخازن + حارس التسلسلات) | **32 نجحت / 3398 تأكيداً** |
| `vendor/bin/pint --dirty` | **passed** |

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit** (لم يُطلب).


---

## 2026-11-02 · إصلاح: قائمة أوامر التوريد/الصرف/التحويل تعرض خطأً أحمر بدل البطاقات

**التصنيف:** عطب واجهة (تخطيط Flutter) — **لا** عطب شبكة ولا استعلام.

### التشخيص

سجل الجهاز أظهر أن الخادم يردّ سليماً:

```
GET /api/stores/transfer?page=1&limit=50&sort=date&dir=desc  →  200
{"success":true,"message":"تم جلب أوامر التحويل ...","data":[ ... 50 صفاً ... ]}
```

ثم مباشرة:

```
════════ Exception caught by rendering library ════════
BoxConstraints forces an infinite height.
The offending constraints were: BoxConstraints(0.0<=w<=Infinity, h=Infinity)
The relevant error-causing widget was:
  Row  .../orders_list_screen.dart:715:18
```

وبعده سلسلة `RenderBox was not laid out: ... hasSize` كلها تشير إلى نفس البطاقة
(`Container:706`, `InkWell:703`) — أي أنها **أعراض تالية لخطأ واحد** لا أخطاء مستقلة.

### السبب الجذري

في `_OrderCard` كان شريط النوع (`Container(width: 4, color: _accent)`) داخل:

```dart
Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...])
```

وهذا `Row` ابن مباشر لعنصر قائمة (`ListView`) **بارتفاع غير محدود**. مع `stretch`
يطلب `Row` من أبنائه أن يتمدّدوا إلى ارتفاعه، وارتفاعه غير محدود ⇒ يُمرَّر
`h=Infinity` إلى شريط النوع ⇒ `BoxConstraints forces an infinite height` ⇒ إطار
الخطأ الأحمر يغطي الشاشة.

### الإصلاح

`lib/features/stores/presentation/screens/orders_list_screen.dart` — تغليف `Row`
بـ`IntrinsicHeight` (فيتحدّد الارتفاع من أطول ابن)، وإضافة
`mainAxisSize: MainAxisSize.min` للعمود الداخلي، مع تعليق عربي/إنجليزي يشرح لماذا
`IntrinsicHeight` **ضروري** حتى لا يُزال لاحقاً:

```dart
child: IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(width: 4, color: _accent),   // شريط النوع
      Expanded(child: Padding(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, ...))),
    ],
  ),
),
```

> `_infoRow` و`_moneyRow` كانا مغلّفين بـ`IntrinsicHeight` أصلاً، ولذلك لم يظهر
> الخطأ فيهما. الناقص كان **الصف الخارجي** للبطاقة.

### الحارس الجديد (سبب مرور العطب سابقاً)

اختبارات المزوّد والنموذج لا ترى أخطاء التخطيط إطلاقاً؛ ولا يوجد اختبار كان
يُركّب شاشة القائمة. أُضيف `test/features/stores/orders_list_screen_test.dart`:

| الاختبار | يحرس |
|---|---|
| `the card is drawn instead of a red layout error` | `takeException()` يعود `null` + بيانات المستند تظهر فعلاً |
| `every kind renders its card without a layout fault` | الأنواع الثلاثة (توريد/صرف/تحويل) — لكل منها فروع في نفس البطاقة |
| `the same screen renders on a phone width` | عرض 360px: الشريط لا يسحق المحتوى |

البيانات مزروعة في `OrdersListState` (بما فيها `created_by_name: null` و`detailes: null`
للصرف) لتغطية الفروع الفارغة.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **543 ناجحاً** (+3) · 10 متجاوزة · اختبارات المخازن **71** |
| `php artisan test` | لم تُمسّ PHP هذه الجولة |

### تنبيه تشغيلي

هذا تغيير **Dart في التخطيط**؛ لا يظهر في تطبيق مبني مسبقاً. يلزم
`flutter run` (ثم **hot restart** لا hot reload فقط) أو إعادة بناء/تثبيت الحزمة.

**النموذج:** Qoder · **الوقت:** 2026-11-02 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit** (لم يُطلب).

---

## 2026-11-03 · إصلاح: مستند التوريد/الصرف/التحويل لا يُرسم + `ORA-00904 MAIN_COLOR` عند اختيار صنف

**عطلان مستقلان في سجل واحد** — لا علاقة لأحدهما بالآخر، ولا بالشبكة.

### (أ) مستند التوريد/الصرف/التحويل: `Cannot add to a fixed-length list`

```
════════ Exception caught by widgets library ════════
The following UnsupportedError was thrown building LayoutBuilder:
Unsupported operation: Cannot add to a fixed-length list
The relevant error-causing widget was:
    LayoutBuilder  .../order_view_screen.dart:440:12
#1  _OrderViewScreenState._borderedGrid.<anonymous closure> (order_view_screen.dart:452)
```

**السبب:** في `_borderedGrid` كان المقطع يُبنى بقائمة **ثابتة الطول** ثم يُملأ:

```dart
final slice = cells.skip(start).take(columns).toList(growable: false);
while (slice.length < columns) {
  slice.add(('', ''));   // ← يرمي: القائمة ثابتة الطول
}
```

الشبكة توزّع الخانات على `clamp(2, 6)` عموداً بحسب العرض. فإذا كان عدد الخانات **لا يقبل
القسمة** على عدد الأعمدة يلزم ملء الصف الناقص، وعندها فقط ينفجر الرسم. لذلك ظهر العطب
«متقطعاً»: مستند بعينه على عرض بعينه يفشل، وآخر يعمل — وهو أخطر أنواع الأعطال لأنه يُظنّ
عشوائياً أو مرتبطاً بالبيانات.

**الإصلاح:** `toList()` (قابلة للنمو) + تعليق عربي/إنجليزي يوضح أن الملء هو سبب الحاجة لها.

**الحارس:** اختبار جديد `the meta grid survives every column count` في
`test/features/stores/order_view_screen_test.dart` يمرّ على تسعة عروض (420 → 1400) فتُنتج
2–6 أعمدة، ويطالب `takeException()` أن يكون `null` عند كل عرض.
**تحقّق من أن الحارس ليس فارغاً:** أُعيد العطب مؤقتاً (`growable: false`) فسقط الاختبار
بالرسالة نفسها حرفياً `Unsupported operation: Cannot add to a fixed-length list`، ثم أُعيد الإصلاح.

### (ب) الأصناف: `ORA-00904: "S"."MAIN_COLOR": invalid identifier`

```
{"success":false,"message":"تعذر جلب الصنف / Failed to retrieve the item.",
 "error":"ORA-00904: \"S\".\"MAIN_COLOR\": invalid identifier"}
```

**السبب:** الكود كان ينادي عموداً غير موجود. فحص `ALL_TAB_COLUMNS` على **قاعدة التطبيق** أثبت:

| الجدول | الأعمدة الحقيقية للون | `MAIN_COLOR` |
|---|---|---|
| `ACCOUNTS.SANFS` (37 عموداً) | `MCOLOR`, `COLORNO` | **غير موجود** |
| `ACCOUNTS.SANFS_D` (41 عموداً) | `DCOLOR`, `COLOR_NO`, `MCOLOR` | **غير موجود** |

**ثلاثة مواضع في `StoreItemController` كانت ستنفجر، لا واحداً:**

| الموضع | الأثر | الحالة |
|---|---|---|
| `fetchItem()` — قائمة SELECT | تفصيل الصنف 500 عند اختيار أي صنف فرعي | **ظاهر للمستخدم** |
| `store()` — قائمة أعمدة INSERT | إنشاء صنف مستحيل | كان سيسقط لاحقاً |
| `update()` — `SET ... = :mcolor` | تعديل صنف مستحيل | كان سيسقط لاحقاً |

**الإصلاح:** `MCOLOR` في المواضع الثلاثة، والعميل `item_model.dart` يقرأ `MCOLOR` أولاً ويُبقي
`MAIN_COLOR` كاحتياط لخادم أقدم.

**الحارس:** `kyApp_API/tests/Feature/StoreItemTest.php` (جديد) — 4 اختبارات تغطي المسار كاملاً:
القائمة · التفصيل (يطالب بـ17 مفتاحاً بينها `MCOLOR`) · الحركات · إنشاء صنف ← إضافة صنف فرعي ←
قراءته في التفصيل ← تعديله ← حذفه. كل الكتابة داخل معاملة تُلغى، فلا يبقى صنف اختباري.
**لماذا فاتت سابقاً؟** اختبارات الصلاحيات تفحص البوابة (401/403) لا جسم الاستعلام، ولم يكن
هناك اختبار `GET /stores/items/{id}` إطلاقاً.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **544 ناجحاً · 10 متجاوزة** |
| `php artisan test` (المخازن: أصناف + كتابة + صلاحيات + تقارير) | **21 نجحت / 3312 تأكيداً** |
| `vendor/bin/pint --dirty` | **passed** |

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit** (لم يُطلب).

---

## 2026-11-03 · إعادة تنسيق مستندات التوريد/الصرف/التحويل + إصلاح التصدير

**الطلب:** تحسين واجهة العرض (شريط تفاصيل بصف واحد، أعمدة محددة، بلا تمرير جانبي، تفاصيل مالية بعمودين)
وإصلاح خطأ الطباعة/التصدير الظاهر في الصورة: «تعذر التصدير: `Unsupported operation: Cannot add to a fixed-length list`».

### (أ) شاشة العرض — ما تغيّر

| البند | قبل | بعد |
|---|---|---|
| رقم الفاتورة | يُكرَّر: عنوان + «رقم الفاتورة» أول خانة في شبكة الرأس | مرة واحدة تحت العنوان فقط |
| شريط التفاصيل | شبكة 2–6 أعمدة تمتد صفوفاً | **صف واحد** موازٍ لجدول السطور، من مصدر مشترك مع PDF |
| أعمدة السطور | 14 عموداً (مقاسات، تصنيف، رقم فرعي، رف…) | **9 أعمدة**: رقم الصنف · إسم الصنف · اللون · الوحدة · الكمية · عبوة · قطعة · سعر الصنف · الإجمالي (+ `متوسط التكلفة` للتحويل وحده = 10) |
| العرض الضيق | `SingleChildScrollView` أفقي | بلا تمرير: الشبكة تُوزَّع على العرض المتاح، وإن ضاق يُصغَّر الجدول كله (`FittedBox`) |
| التفاصيل المالية | شريط مجاميع + سطر بيان منفصل | عمودان متقابلان: **يميناً** المبلغ كتابةً ثم البيان، **يساراً** الإجمالي · مبلغ الخصم · صافي المبلغ |

**حقول شريط التفاصيل لكل نوع:**

| النوع | الحقول |
|---|---|
| التوريد | تاريخ الفاتورة · نوع الفاتورة · إسم المخزن · إسم المورد · العملة · العدد |
| الصرف | تاريخ الفاتورة · نوع الفاتورة · إسم المخزن · إسم العميل · العملة · العدد |
| التحويل | تاريخ الفاتورة · من مخزن · إلى مخزن · رقم الصرف · رقم التوريد · حساب المخزون · العدد |

> «رقم الصرف» = `TR_INV_M_ID` (سند المنصرف) و«رقم التوريد» = التوأم الوارد لنفس الفاتورة —
> وهما المسلسلان اللذان يعرضهما نموذج التحويل المكتبي.

**مصدر واحد لا اثنان:** أُضيفت `storeDocumentMeta(kind, header)` في `store_document_layout.dart`
تُغذّي الشاشة و PDF معاً، حتى لا ينحرف المطبوع عن المعروض بعد أي تعديل لاحق (كما أُضيفت
`storeDiscountText` لصياغة الخصم مع نسبته).

### (ب) التصدير — ثلاثة أعطال متراكبة، لا عطل واحد

1. **`Cannot add to a fixed-length list`** (المُبلَّغ في الصورة): `_orderMeta` في `store_export.dart`
   كان يملأ الصف الناقص على `toList(growable: false)` → إصلاحه بـ`toList()` القابلة للنمو.
2. **`height (Infinity) exceed a page height`**: بعد الإصلاح كان التوليد يفشل لأن `pw.Row` مع
   `CrossAxisAlignment.stretch` يحتاج ارتفاعاً معلوماً وترويسة `MultiPage` بلا ارتفاع محدود.
   استُبدل الصف بجدول `pw.Table` (يحسب الارتفاع من أطول خلية) في شريط التفاصيل وفي التفاصيل المالية،
   مع عكس الخانات لأن `pw.Table` يرسم LTR دائماً.
3. **غياب أي اختبار للتصدير**: أُضيف `test/features/stores/store_export_test.dart` يبني الـ PDF فعلياً
   للأنواع الثلاثة (خطوط عربية من الأصول، ترويسة، جدول، تفاصيل مالية، توقيعات) ويتحقق من توقيع
   `%PDF-` وحجم معقول. **هذا الاختبار هو ما كشف العطل الثاني** قبل أن يصل إلى المستخدم.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **547 ناجحاً · 10 متجاوزة** (اختبارات المخازن 76) |
| `php artisan test` (المخازن) | **21 نجحت / 3317 تأكيداً** |
| `vendor/bin/pint --dirty` | **passed** |

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit** (لم يُطلب).

---

## 2026-11-03 · تلميع مستند المخزن: شريط تفاصيل كامل النصوص، جدول أكثف، وملء صفحات PDF

**الطلب:** (1) شريط تفاصيل بصف واحد تظهر نصوصه كاملة دون حجب حرف مهما ضاقت الشاشة، (2) حذف سطر
«تفاصيل الأصناف» وزيادة ارتفاع الصفوف وإظهار «إسم الصنف» كاملاً بلا توسيع الجدول ولا إخفاء عمود،
(3) تقليل ارتفاع التفاصيل المالية وحجم نصوصها، (4) إصلاح الطباعة: الجدول ينتهي في نصف الورقة
والباقي في صفحة أخرى.

### (1) شريط التفاصيل

`_metaCell` صار يعرض الاسم والقيمة داخل `FittedBox(fit: BoxFit.scaleDown)` بلا `ellipsis`:
النص **يُصغَّر** ليدخل كاملاً بدل أن يُبتر بنقاط. الخلايا `Expanded` داخل صف واحد مع
`IntrinsicHeight`، فالشريط يبقى سطراً واحداً على أي عرض، وكل نصوصه مقروءة بالكامل.

### (2) جدول السطور

| البند | التغيير |
|---|---|
| سطر «تفاصيل الأصناف» | **حُذف** — الجدول يلي الشريط مباشرة |
| ارتفاع الصف | الحشو الرأسي 4 ← **7**، وحجم الخط 9 ← 9.5 |
| «إسم الصنف» | صار عموداً **يلتف** (`StoreDocColumn.wrap`) بلا `maxLines` وبلا `ellipsis`، فيظهر كاملاً ولا يُبتر منه حرف، دون توسيع الجدول أو إخفاء أي عمود |

### (3) التفاصيل المالية

حشوة «المبلغ كتابةً» 7 ← 5، والتفقيط 11.5 ← 10.5، والبيان 10.5 ← 9.5، وخانات الأرقام
6 ← 4 و 11.5/12.5 ← 10.5/11.5، والفواصل 7 ← 4 — أقصر وأهدأ بصرياً مع بقاء التقابل بين العمودين.

### (4) الطباعة — السبب المقاس، لا المُخمَّن

قِيست المشكلة بعدّ الصفحات فعلياً في اختبار (مستند 36 سطراً):

| الحالة | صفحات |
|---|---|
| قبل الإصلاح | **3** |
| بعد الإصلاح | **2** |

**السبب:** `pw.TableHelper.fromTextArray` يعطي كل عمود **عرضاً متساوياً** افتراضياً. فبعرض الصفحة
الأفقية (798 نقطة) يصيب عمود الاسم ~80 نقطة، فيتسطر الاسم على أربعة أسطر ويصبح الصف ~50 نقطة،
فتحتمل الصفحة الأولى خمسة سطور فقط ويُدفع الباقي لصفحة ثالثة مع فراغ أسفل الورقة.

**الإصلاح:** تمرير `columnWidths` بنِسَب المستند نفسها (`StoreDocColumn.weight`) — 9.55/10.55
مجموعاً — فصار عمود الاسم ~217 نقطة والصف ~20 نقطة، فامتلأت الصفحة الأولى (≥17 سطراً) وصار
المستند صفحتين.

**وجُرِّبت فرضيتان أخريان وقِيستا فرُدَّتا** (فلم تُتركا في الكود):
`pw.Column` في ترويسة PDF يتمدد افتراضياً، و`Container(alignment:)` حول الشعار — كلاهما لم يغيّر
عدد الصفحات بعد القياس، فأُعيد الملفان المشتركان (`report_pdf_page.dart`، `report_pdf_letterhead.dart`)
إلى أصلهما، وبقي الإصلاح محصوراً في قسم المخازن.

أُضيف إلى `store_export_test.dart` حارس عدد الصفحات (36 سطراً = صفحتان)، وحارس في
`order_view_screen_test.dart` يثبت أن سطر «تفاصيل الأصناف» غائب وأن الاسم لا يُبتر.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **548 ناجحاً · 10 متجاوزة** (المخازن 76) |
| `php artisan test` (المخازن) | **21 نجحت / 3317 تأكيداً** |
| `vendor/bin/pint --dirty` | **passed** (لا تغيير PHP هذه الجولة) |

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit** (لم يُطلب).

---

## 2026-11-03 · إصلاح طباعة المستند: حروف عربية معكوسة + ورقة A4 طولية

**الشكوى:** بعد التلميع، خرجت الطباعة بحروف معكوسة («ﻢ ﻳﺪﻧﻠﻴﺎﺕ ﻗﻄﻘﻂ ﻳﺒﺎﺑﺶ ﺭ» بدل «شبابي طقطق تايلندي ملون»)
وبورقة أفقية صغيرة، والمطلوب A4 **طولية** بنصوص سليمة.

### السبب — مقاس لا مُخمَّن

`pw.TableHelper.fromTextArray` يترك معاملَي `headerDirection` و`tableDirection` **بلا قيمة**،
فترث خلايا الجدول اتجاه الصفحة (`rtl`). والنص يصل إلى الجدول **مُشكَّلاً ومرتَّباً مرئياً** مسبقاً من
`pdfArabic()` — وهي تعكس ترتيب الكلمات لتصل إلى الترتيب المرئي الصحيح وتُعرض بـ`ltr`. فتمرير نص
بترتيب مرئي إلى محرك rtl يجعله يطبّق Bidi **مرة ثانية**، فينقلب النص كاملاً: الكلمات بترتيب معاكس
والحروف معكوسة داخل كل كلمة.

**الدليل من الصورة:** العنوان (يمرّ عبر `pw.Text` بـ`textDirection: kPdfShapedTextDirection`) ظهر
سليماً، وبطاقات المجاميع (الإجمالي/الخصم/الصافي) ظهرت سليمة، بينما **خلايا الجدول وحدها** ظهرت
معكوسة — وهذا يطابق السبب تماماً.

### الإصلاح

في كل جداول `store_export.dart` (خمسة: سطور المستند · قائمة الأوامر · الحركة · الخلاصة · كشف الجرد):

```dart
headerDirection: kPdfShapedTextDirection,
tableDirection: kPdfShapedTextDirection,
cellAlignment: pw.Alignment.topRight,   // ltr يقلب topLeft إلى محاذاة يسار، فتُثبَّت يميناً
```

وأُضيف `pdfArabic` المناسب للخلايا النصية.

**حجم الورقة:** `PdfPageFormat.a4.landscape` ← `PdfPageFormat.a4` (طولية 595×842). الأفقي كان
يُصغّر المستند عند الطباعة على ورق طولي.

### التحقق البصري

وُلّد مستند 36 سطراً ثم عُرض فعلياً بـpdf.js بمقياس 2.5× وفحص بعين:

| البند | النتيجة |
|---|---|
| المقاس | **595×842** (A4 طولية) ✔ |
| سطر رأس الجدول (يمين←يسار) | رقم الصنف · إسم الصنف · اللون · الوحدة · الكمية · عبوة · قطعة · سعر الصنف · الإجمالي ✔ |
| شريط التفاصيل | تاريخ الفاتورة · نوع الفاتورة · إسم المخزن · إسم المورد · العملة · العدد ✔ |
| اسم الصنف | «ملون تايلندي طقطق شبابي رقم 0» متّصلاً صحيحاً بلا انعكاس ✔ |

**حارس جديد:** `store_export_test.dart` يقرأ `MediaBox` ويوجب أن يكون الارتفاع أكبر من العرض وبعرض
595 وارتفاع 842 — فلو عاد أحدهم للأفقي يسقط الاختبار.

### ملاحظة على طبقة النص

نسخ النص من ملف PDF يُنتج أشكال العرض (presentation forms) بترتيب مرئي لأن هذه طريقة هذا المشروع
في تشكيل العربية (`pdfArabic`)؛ الرسم على الورق صحيح، لكن النص المنسوخ يبدو معكوساً في المحرر.
هذه خاصية قائمة في كل تقارير المشروع لا علاقة لها بهذا التعديل.

### البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` | **549 ناجحاً · 10 متجاوزة** (المخازن 77) |
| `php artisan test` (المخازن) | **21 نجحت / 3317 تأكيداً** (لا تغيير PHP) |

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

## 2026-11-03 — تطوير واجهة قسم الأصناف: تبويبان · إصلاح التصفية · تفصيل بتبويب واحد

### أ) الأعطال التي شُخّصت أولاً (قبل أي تعديل)

**١) «شاشة بيضاء بلا خيارات» في التصفية:** النافذة كانت `Column` بلا تمرير، وكل قائمة منسدلة
خالية من عنصر «الكل». و`DropdownButtonFormField` يتحقق في `assert` من أن قيمته موجودة **مرة
واحدة بالضبط** بين عناصره؛ فأي قيمة لا تجد عنصراً (مجموعة تغيّرت، فرعية لم تعد تابعة، مرجع
ناقص) تُسقط الشرط فتُبنى النافذة بلا محتوى.

**٢) انهيار زر «صنف جديد»:** نفس الآلية في `item_form_screen`. وكانت الافتراضيات تُزرع داخل
`build` في كل مرة، فلا يُضمن أن القيمة الحالية من العناصر المعروضة.

**٣) كمية الصنف الفرعي:** `AVVG` مُجمَّعة على الصنف الرئيسي (`I_CODE`) ولا تعرف الأصناف الفرعية
إطلاقاً. المصدر الوحيد لكمية الفرع هو `ITEM_MOVEMENT_D` عبر `P_CODE` = `SANFS_D.SANF_DNO`.

### ب) الخادم (`StoreItemController` + مسار جديد)

- `fetchSubs` يجلب `QTY` لكل فرع من تجميع الحركة **مقيَّداً بالصنف الرئيسي**
  (`WHERE m.I_CODE = :sanf_no`) بدل تجميع الـ VIEW كاملة.
- `subIndex` جديد: تبويب الأصناف الفرعية على مستوى النظام — صفحة + بحث (رقم/باركود/اسم/اسم
  الصنف الأب) + تصفية مجموعة/فرعية/حالة. **بلا عمود كمية** لأن حسابها لـ 9,005 فرعاً يعني تجميع
  الـ VIEW كلها في كل طلب؛ الكمية في تفصيل الصنف حيث المسح مقيَّد.
- `movements` أُعيد بناؤه: `P_CODE` و`COLOR_NO/WID/LEN` واسم الفرع من `SANFS_D` ولونه من
  `SANFS_COLOR`، و`QTY_IN/QTY_OUT`، و`meta.totals` (وارد/صادر/صافي/قيمة/عدد الأسطر) محسوبة
  **على كل الصفوف** لا على الصفحة، وتصفية `sub_dno` لفرع واحد.
- تطبيع مفاتيح OCI8 إلى أحرف كبيرة في كل قراءات المتحكم: كانت `fetchSubs`/`movements`/`subIndex`
  تُرجع مفاتيح صغيرة (`SANF_DNO` تصل `sanf_dno`)، وهو نفس الفخ الذي ضرب قائمة المخازن سابقاً.
- `routes/api.php`: `GET /stores/items/sub` مسار حرفي قبل `{sanfNo}`.

### ج) العميل

**`items_list_screen` — تبويبان:**
- الرئيسية: تخطيط رئيسي-تفصيلي كما هو على العروض ≥ 900 بكسل، مع بطاقات أعيد تنسيقها.
- الفرعية: قائمة فروع مستقلة (بحث/تصفية/ترقيم)، كل بطاقة تعرض رقم الفرع ولونه ومقاسه والصنف الأب.

**البطاقات:** رمز المجموعة بدل أيقونة عامة · الاسم · سطر «كود · مجموعة · فرعية» · شارات
(عدد الفروع · الوحدة · السعر) · الكمية والقيمة في **موضع ثابت** يمين/يسار كل بطاقة · قائمة
إجراءات (عرض التفصيل · **كشف حركة** · تعديل · حذف).

**التصفية:** نافذة عالية (82% من الشاشة) قابلة للتمرير، وكل قائمة تحمل «الكل» صريحاً، والقيمة
المارّة إلى القائمة تُطابق عناصرها دائماً (حارس `safe`)، وتُصفَّر الفرعية عند تغيير المجموعة،
وإن كانت المجموعات فارغة ظهر تنبيه بدل قائمة صامتة.

**التصفية الافتراضية (`applyDefaults`):** نشط فقط · أول مجموعة رئيسية · أول مجموعة فرعية منها ·
كل الفئات — تُطبَّق **مرة واحدة** لكل جلسة في التبويبين، وفشل المراجع لا يُقعد الشاشة فارغة
(تحميل بلا تصفية).

**`item_movement_screen` (جديد):** كشف حركة للصنف الرئيسي بكامل فروعه أو لفرع واحد: مدى زمني ·
شريط مجاميع من الخادم · تكبير (`ReportZoomView`) · طباعة PDF · تصدير Excel · أربع حالات
(تحميل/نجاح/فراغ/خطأ).

**`item_detail_screen` أُعيد بناؤه:** تبويب واحد بدل خمسة:
- ترويسة: الاسم · الشارات · أزرار (كشف حركة · صنف فرعي جديد · تعديل).
- البيانات: **سبعة صفوف، كل صف حقلان** بفاصل رأسي.
- الأصناف الفرعية: جدول بأعمدة (رقم الصنف · اللون · الكمية) + أيقونة كشف حركة لكل فرع + قائمة
  إجراءات (تعديل/حذف) + حوار إضافة/تعديل فرع.

**`store_export.dart`:** `buildItemStatementPdf` — جدول الحركة مع عمود «الفرع» ومجاميع في التذييل.

**`item_form_screen`:** القائمة المنسدلة آمنة (قيمة غير موجودة ⇒ غير مختارة)، والافتراضيات تُزرع
مرة واحدة بحارس `_seeded`، والتسلسل صار كاملاً: مجموعة ⇒ أول فرعية ⇒ أول نمط.

### د) الاختبارات

- `kyApp_API/tests/Feature/StoreItemReadTest.php` (جديد، 4 اختبارات): تبويب الفروع يُرجع فروعاً
  حقيقية بترقيم · كمية الفرع مشتقة من الحركة (لا صفرية) · مجاميع الكشف من الخادم وعدد الأسطر
  يتجاوز الصفحة · تصفية `sub_dno` تُضيِّق لفرع واحد. **4 ناجحة / 288 تأكيداً**.
- `item_form_validation_test`: تحديث اختبار النمط (صار يُزرع تلقائياً) + حارسان ضد الانهيار:
  **مرجع فارغ تماماً** يفتح النموذج بلا استثناء، و**مجموعة رئيسية بلا فرعية** تبقى قابلة للاستخدام.
- `items_split_test`: تجاوز `subItemsListProvider` بمزود مزروع كي لا يُطلق طلب شبكة.

### هـ) البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test` (الحزمة الكاملة) | **552 ناجحاً · 10 متجاوزة** |
| `flutter test test/features/stores/` | **80 ناجحاً** |
| `php artisan test` (اختبارات المخازن الستة) | **31 ناجحاً** |

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

## 2026-11-03 — إصلاح جذري: الأصناف لا تظهر أبداً + خطأ زر التصفية

> **بلاغ المستخدم:** «الاصناف لاتظهر ابدا في القائمه وايضا يظهر خطا عند النقر على زر تصفيه».
> الدليل: سجل تشغيل الجهاز (S901N) مع نص `assert` كامل.

### أ) السبب الأول — كل مجموعة تُقرأ صفراً (قائمة فارغة)

من السجل:
```
GET /api/stores/items?page=1&limit=50&group_no=0&active=1&sort=name&dir=asc
→ {"success":true,"data":[],"meta":{"total":0,...}}
```

`/api/stores/reference` كان يُرجع **مفاتيح صغيرة** (`group_no` · `type_no` · `unit_no`) لأن منتقي
OCI8 يعيدها كذلك، و`StoreReportController::clean()` لم تُطبّعها. النماذج في العميل تقرأ
`GROUP_NO` فلم تجدها ⇒ `asInt(null) = 0` ⇒ كل مجموعة 0 وكل فرعية 0 ⇒ `applyDefaults` تبني
تصفية على المجموعة صفر ⇒ لا صف واحد.

**الإصلاح على طبقتين:**
1. **الخادم:** `clean()` تُطبّع المفاتيح إلى أحرف كبيرة قبل أي قراءة. وأصلح هذا عطلاً ثانياً
   كان مخفياً: `isset($item['STORE_NO'])` لم يكن يتحقق أبداً ⇒ وسم «أرشيفي» للمخازن 2/11/12
   لم يُضبط قط.
2. **العميل:** قراءة مزدوجة الحالة في `StoreGroupModel` و`StoreTypeModel` و`StoreUnitModel`
   (تُدمج مع `StoreStyleModel`/`StoreCategoryModel`/`StoreMovementModel` التي كانت مزدوجة أصلاً).
3. **حارس إضافي:** `applyDefaults` تتجاهل المجموعات ذوات الأرقام غير الصالحة وتحمّل بلا تصفية
   بدل قائمة فارغة.

### ب) السبب الثاني — `assert` في القائمة المنسدلة

```
There should be exactly one item with [DropdownButton]'s value: 0.
items.where((item) => item.value == value).length == 1  ← فشل
at _ItemsListScreenState._sheetDropdown (items_list_screen.dart:770)
```

لأن كل مجموعة صارت `0`، بُنيت القائمة المنسدلة من **خمسة عناصر بقيمة `'0'`** ⇒ الـ`assert`.
**الإصلاح:** `_sheetDropdown` تُزيل القيم المكررة قبل البناء، وتُطابق قيمة الحقل مع العناصر،
وتُعيد أول عنصر متاح بدل الانفجار.

### ج) السبب الثالث — `AVVG` تكلّف ١٣ ثانية لكل استعلام (مهلة العميل)

من السجل أيضاً: `DioException [receive timeout]` على `/api/stores/items` (مهلة ١٥ ثانية).

قياس عبر مسبار فعلي على القاعدة:

| القياس | الزمن |
|---|---|
| `SELECT … FROM AVVG GROUP BY I_CODE` | **14,628 مللي** |
| نفس التجميع مقيَّداً بـ`I_CODE IN (٥٠ صنفاً)` | **12,780 مللي** |
| `COUNT(*)` مع تصفية | 2 مللي |
| تجميع `SANFS_D` | 14 مللي |
| استعلام الصفحة بلا `AVVG` | **12 مللي** |

الخلاصة: **أي** قراءة من `AVVG` ≈ ١٣ ثانية، لأنها تُجمّع تاريخ الحركة كاملاً قبل الفلترة.

**الإصلاح:**
- `index()`: صارت الأرصدة **اختيارية** (`with_stock`)، وتُضمّ فقط عند الفرز بالكمية/القيمة.
  الصف يعلن `STOCK_LOADED = 0` فتخفي الواجهة الأرقام بدل صفر كاذب.
- `show()`: أُزيل استعلام الأرصدة نهائياً؛ إجمالي رصيد الصنف يُجمع من **كميات فروعه** وهي نفس
  المصدر الذي تُبنى منه `AVVG` (`ITEM_MOVEMENT_D`) ⇒ لا فقد في الدقة.
- حُذف `fetchBalances` (صار ميتاً).
- أُزيل الفرز بالكمية/القيمة من قائمة الأصناف (كل خيار منها كان يفتح خطأ مهلة)، وبقي في شاشة
  «أرصدة المخازن» حيث الرصيد هو موضوع الشاشة.
- استُبدلت الاستعلامات المترابطة لكل صف (عدد الفروع · اسم الفئة) بتجميعين مفردين.
- `ORDER BY` وترقيم الصفحات كما هما؛ التصفية الافتراضية (نشط · أول مجموعة · أول فرعية) تعمل
  الآن على أرقام حقيقية: **724 صنفاً** بدل صفر.

### د) الاختبارات الجديدة (حراس على السبب لا على الأعراض)

- `test/features/stores/store_reference_parse_test.dart` (جديد، 5 اختبارات): تفكيك الحمولة
  **الحقيقية بمفاتيح صغيرة** من السجل، وتحقّق أن الأرقام 1/101/201/4/3 لا أصفاراً، وأن المجموعة
  الأولى تُرجع فرعيتها، وأن المفاتيح الكبيرة ما زالت تعمل، وأن المخزن الأرشيفي يُوسم.
- `StoreItemReadTest` (+2 اختبارات): حزمة المراجع تحمل مفاتيح عليا وأرقاماً حقيقية ووسم الأرشيف،
  و**التركيبة الافتراضية تُرجع أصنافاً لا صفراً**، مع تأكيد `STOCK_LOADED = 0` و`QTY = null`.

### هـ) الأثر الزمني المقاس

| الاختبار | قبل | بعد |
|---|---|---|
| `the default filter combination returns items` | 48.59 ث | **0.14 ث** |
| `a branch keeps a quantity derived from the movement view` | 21.86 ث | **0.17 ث** |
| حزمة `StoreItemReadTest` كاملة | 78.05 ث | **2.13 ث** |

### و) البوابات

- `flutter analyze` = **No issues found**
- `flutter test test/features/stores/` = **85 ناجحاً**
- `php artisan test --filter=StoreItemReadTest` = **6 ناجحة / 313 تأكيداً**

**النموذج:** Qoder · **الوقت:** 2026-11-03 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

## 2026-11-04 — الرصيد داخل واجهة الأصناف + منع تكرار الصنف الفرعي

> **بلاغ المستخدم:** «يجب عرض الرصيد بواجهة الأصناف، لا أريد الذهاب لواجهة أرصدة المخازن.
> الأصناف الرئيسية: يتم جمع أرصدة الأصناف الفرعية التابعة لها كامل ويعرض الإجمالي كرصيد للصنف
> الرئيسي. الأصناف الفرعية: يعرض الرصيد الخاص بها مباشرة. وهناك مشكلة في عرض الأصناف الفرعية:
> يكرر الصنف الفرعي مرتين».
> **تصحيح لاتجاه الجولة السابقة:** الجولة السابقة جعلت الأرصدة اختيارية في القائمة؛ هذا حلّ المهلة
> لكنه حرم المستخدم من الرقم الذي طلبه. أُصلح بجلب الرقم من مصدر رخيص لا بحذفه.

### أ) الرصيد الآن من `ITEM_MOVEMENT_D` مباشرة، لا من `AVVG`

قِيس على القاعدة الحيّة:

| المصدر | الزمن |
|---|---|
| تجميع `AVVG` الكامل (المصدر السابق) | **14,589 مللي** ⇒ مهلة العميل |
| تجميع الحركة بالفرع `P_CODE` | **1,552 مللي** |
| تجميع الحركة بالصنف `I_CODE` | **1,700 مللي** |
| صفحة الأصناف + الرصيد من الحركة | **2,616 مللي** ✅ |
| صفحة الفروع + رصيد كل فرع | **2,150 مللي** ✅ |

نفس الأرقام، سُبع الزمن، لأن `AVVG` نفسها مشتقة من الحركة — والقياس أثبت أن التقييد بـ`I_CODE`
**لا يُدفع** إلى فروع الـ`UNION ALL` داخل العرض، فلم يكن للقيد أي فائدة زمنية.

### ب) التعريف المطلوب صار هو التنفيذ

- **الصنف الرئيسي** = مجموع أرصدة فروعه: تجميع الحركة بالفرع، ثم ربطه بـ`SANFS_D` وتجميعه
  بالأب (`GROUP BY d.SANF_NO`).
- **الصنف الفرعي** = رصيده مباشرة من حركته هو.
- **مصدر واحد للثلاث شاشات** (القائمة · التفصيل · كشف الحركة) بلا تقييد بالصنف الأب، فتتطابق
  الأرقام بنيوياً: المجموع = الإجمالي المعروض. وأُثبت ذلك باختبار يقارن الرقمين فعلياً.

### ج) تكرار الصنف الفرعي مرتين

التحقيق نفى مصدر البيانات: صفر تكرار في `SANFS_D` بنفس الهوية، و`SANFS_COLOR` فريد (27/27)،
واستعلام التبويب أعاد 50 صفاً بـ50 معرّفاً مميزاً. أي أن التكرار عرضي لا بياناتي، ولم يُترك
للصدفة:

1. **الخادم:** استعلام التبويب صار `GROUP BY d.SANF_DNO, d.SANF_NO` مع `MAX()` لبقية الحقول —
   أي رابط 1:N مستقبلي يُدمج في صف واحد، فتستحيل المضاعفة بنيوياً. والترتيب بالأسماء المستعارة
   (درس `ORA-00935` السابق محفوظ).
2. **العميل:** `_distinctBranches` / `_distinctItems` + `_uniqueBy` في المستودع — طبقة ثانية
   تمنع ظهور المعرّف نفسه مرتين في أي قائمة.
3. **حارس دائم:** `the sub items tab never repeats a branch` يفرض أن عدد الصفوف = عدد المعرّفات
   المميزة.

### د) ما رُجع إلى الواجهة

- الأرقام (الرصيد + القيمة) في بطاقة الصنف الرئيسي — بلا شرطة ولا «اذهب إلى شاشة الأرصدة».
- الرصيد والقيمة في بطاقة كل فرع.
- شارة قيمة الرصيد في تفصيل الصنف، و`ItemDetail.totalValue` من مجموع الفروع.
- خيارا الفرز **بالرصيد** و**بالقيمة** إلى قائمة الأصناف (ممكن الآن لأن مصدر الرصيد رخيص).
- أُزيل `STOCK_LOADED` و`with_stock` و`ItemBalanceModel` و`fetchBalances`: صارت dead code،
  والقيمة `0` الكاذبة التي صُمّم الحارس لأجلها لم تعد واردة.

### هـ) البوابات

| البوابة | النتيجة |
|---|---|
| `flutter analyze` | **No issues found!** |
| `flutter test test/features/stores/` | **85 ناجحاً** |
| `php artisan test --filter=StoreItemReadTest` | **7 ناجحة / 317 تأكيداً** |
| `php -l` على المتحكم والاختبار | بلا أخطاء |

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

## 2026-11-04 — شاشة الفرع المستقلة + توطين الإجراءات في شريط الأصناف الرئيسي

> **بلاغ المستخدم:** «واجهة استعراض صنف رئيسي: زر تعديل وزر كشف حركة يتم عرضهم في الشريط العلوي
> كأيقونة فقط ولا يتم تكرارهم، وزر صنف فرعي جديد يتم إظهاره في الأسفل بجانب عنوان قسم الأصناف
> الفرعية. حقل كود الصنف يتم إخفاؤه من قسم بيانات الصنف لأنه يظهر أعلى ولا داعي لتكراره.
> أما واجهة استعراض صنف فرعي فهي تعرض تفاصيل الصنف الرئيسي وهذه غلط، ويجب أن تظهر تفاصيل
> الصنف الفرعي فقط».

### أ) العطل الأخطر: الفرع ما كانت له شاشة أصلاً

لم تكن هناك شاشة لتفاصيل الفرع: النقر على فرع كان يفتح `ItemDetailScreen` الذي يعرض أعمدة
`SANFS` — المجموعة الرئيسية، الفئة، النمط، عدد الأصناف الفرعية، سعر الصنف الأب. فتظهر بيانات
كيانٍ آخر تحت عنوان «تفاصيل الصنف الفرعي». هذا ليس تنسيقاً سيئاً، هذا عرض خاطئ للبيانات.

**الحل:** `sub_item_detail_screen.dart` جديدة، كل خانة فيها عمود من `SANFS_D` أو رصيد الفرع:

| الخانة | العمود |
|---|---|
| رقم الصنف الفرعي · الرمز · الكود · الباركود | `SANF_DNO` · `SANF_COCE` · `PART_NO` · `BARACOCE` |
| الطول · العرض | `LEN` · `WID` |
| اللون · السعر | `COLOR_NO`→`SANFS_COLOR` · `SANF_PRICE` |
| العبوة · الوحدة | `CAP` · `UNIT_NO`→`UNITS` |
| الرصيد · قيمة الرصيد | حركة الفرع عبر `P_CODE` |
| الحالة · التصنيف | `ACTIVE` · `CATEGORY` |

والأب يظهر **كرابط وصول** في الأسفل (`pushReplacement`) لا كحقل من حقول الفرع.

### ب) أعمدة كانت مفقودة وأُضيفت من الخادم

`fetchSubs` و`subIndex` ما كانا يُرجعان `SANF_PRICE` ولا `UNIT_NO`/`UNIT_NAME` ولا `CAP`، فلو
اُكتفي بالتبويب لظهرت خانات الفرع فارغة. أُضيفت مع `LEFT JOIN ACCOUNTS.UNITS`، و`PARENT_NAME`
موسوماً باسمه:

- **عطل خفي صحّح:** `ItemSubModel.parentName` كان يقرأ `SANF_NAME`، و`SANFS_D.SANF_NAME` هو اسم
  **الفرع** نفسه (عمود NOT NULL في الجدول) — فكان تفصيل الفرع يعرض اسم أبيه كأنه اسمه. صار
  يقرأ `PARENT_NAME` أولاً.

### ج) توطين الإجراءات في شاشة الرئيسي (بلا تكرار)

- **`كشف حركة` و`تعديل`**: أيقونتان في `AppBar` فقط. حُذف صف `ElevatedButton`/`OutlinedButton`
  من بطاقة الرأس، لأن الزر في موضعين يجعل المستخدم يبحث عن أيهما يضغط.
- **الوضع الجانبي (شاشات عريضة)**: لا يملك `AppBar`، فتحمل اللوحة أيقوناتها نفسها — بلا تكرار
  على أي حال.
- **`صنف فرعي جديد`**: انتقل من رأس الصنف إلى جوار عنوان قسم «الأصناف الفرعية» (مع العدّاد)،
  لأن من يضيف فرعاً يفكر في الفروع.
- **`كود الصنف`**: حُذف من شبكة «بيانات الصنف» لأنه ظاهر فوق كشارة `كود …`؛ وأُعيدت أزواج
  الحقول إلى سبعة صفوف بحقلين، مع إضافة `إجمالي القيمة` بدل الخانة الحرة.

### د) ودالة واحدة للحوار، لا نسخة في كل شاشة

`widgets/sub_item_dialog.dart` (جديدة): `showSubItemDialog` و`confirmDeleteSubItem` تستعملهما
الشاشتان. النسخة المكررة تنحرف حتماً: كانت إحداها تكتب «رقم اللون» كرقم حر، فصار **منتقي ألوان**
من `SANFS_COLOR` مع بديل رقمي حين لا تصل المراجع — ورقم لون خاطئ كان يظهر كـ«لون 7» بلا معنى
في كل شاشة تعرض الفرع.

### هـ) الاختبارات والبوابات

- `the sub items tab answers a paged envelope with real branches` يُتحقّق الآن أن الفرع يحمل
  `SANF_PRICE` و`CAP` و`QTY` و`VALUE` ⇒ **7 ناجحة / 321 تأكيداً** · Pint: passed
- `flutter analyze` = **No issues found** · `flutter test test/features/stores/` = **85 ناجحاً**
- `dart format` مطبَّق على الملفات الستة المتغيرة.

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.

---

## 2026-11-04 — الجذر الحقيقي للتكرار والرصيد المضاعف: `SANFS_COLOR` ليس فريداً

> **بلاغ المستخدم:** الرصيد لا يظهر في قائمتي الأصناف، والفروع تتكرر مرتين، وتفاصيل الفرع ما
> زالت تعرض بيانات الأب، وكشف الحركة لا يُظهر شيئاً.

### أ) كيف شُخِّص — بلا تخمين

التشخيص السابق فشل لسبب واحد: **فحصت قاعدة غير التي يقرأ منها التطبيق**. اتصال `oracle` في
التطبيق `SERVICE=orcl3`، بينما موصل MCP كان على نسخة أخرى أعطت `SANFS_COLOR` = 27/27 فريدة.
على قاعدة التطبيق نفسها:

```
SANFS_COLOR rows            = 54
SANFS_COLOR distinct COLOR_NO = 27      ← كل لون بصفين
join SANFS_D ← SANFS_COLOR  = 10 صفوف لخمسة فروع
join SANFS_D ← UNITS        = 5  (سليم)
join SANFS_D ← SANFS        = 5  (سليم)
```

**هذا هو التكرار منذ أول بلاغ.** الرابطة على عمود غير فريد تُضاعف كل صنف فرعي.

### ب) أثره لم يكن تجميلياً

| العَرَض | السبب الحقيقي |
|---|---|
| «الصنف الفرعي مكرر مرتين» | 10 صفوف لخمسة فروع من رابط اللون |
| «رصيد الصنف الرئيسي غير حقيقي» | `totalQty` بالتفصيل = مجموع الفروع = **مضاعف** |
| «تبويب الفروع سليم» | صدفة: أضفت `GROUP BY d.SANF_DNO` سابقاً فدمج التكرار |
| «كشف حركة لا يُظهر شيئاً» | الأصناف المفتَّحة (`109` · `1780` · `1258` · `1441`) **رصيدها صفر وليس لها أي حركة** — الرسالة كانت تُلمّح إلى مدى زمني لم يُختر |

### ج) الإصلاح: لا روابط على أعمدة وصفية

`fetchSubs` و`movements` صارت **استعلامات فردية** بدل `LEFT JOIN`:

```sql
(SELECT MAX(sc.COLOR_NAME) FROM ACCOUNTS.SANFS_COLOR sc WHERE sc.COLOR_NO = d.COLOR_NO) AS COLOR_NAME,
(SELECT MAX(u.UNIT_NAME)   FROM ACCOUNTS.UNITS u        WHERE u.UNIT_NO  = d.UNIT_NO)  AS UNIT_NAME,
(SELECT MAX(sd.SANF_DNAME) FROM ACCOUNTS.SANFS_D sd     WHERE sd.SANF_DNO = m.P_CODE)  AS SUB_NAME
```

وتجميع رصيد الأب يبدأ من **فروع مميزة**: `(SELECT DISTINCT SANF_NO, SANF_DNO FROM SANFS_D)`،
وعدّاد الفروع `COUNT(DISTINCT SANF_DNO)` — فالرقم محصّن ضد تكرار البيانات لا معتمد على نظافتها.

### د) التحقق — أرقام من قاعدة التطبيق نفسها

```
item 109     list=0         subs=5  sumBranches=0         OK | mvDb=0    mvRows=0
item 1991    list=1503.27   subs=5  sumBranches=1503.27   OK | mvDb=156  mvRows=50
item 1219    list=162.47    subs=1  sumBranches=162.47    OK | mvDb=40   mvRows=40
```

`subs` صار 5 بدل 10، و`list == sumBranches` لكل صنف — وهو تعريف المستخدم الحرفي للرصيد.
(الفارق عن `AVVG` هو `ROUND` داخل العرض نفسه: `1504` مقابل `1503.27`؛ الرقم المعتمد أدق.)

### هـ) بقية الطلبات في هذه الجولة

- **الحقول**: العنوان والقيمة **في سطر واحد** في الشاشتين، وحشو الصف 9 ← 7 والفاصل الرأسي 30 ← 16.
- **تفاصيل الفرع**: شاشته المستقلة قائمة الآن ولا تعرض قائمة الفروع الأخرى.
- **رسالة «لا حركات»** صريحة: تفرّق بين صنف بلا حركة إطلاقاً وصنف لا حركة في المدى المحدد.
- **حارس دائم**: `the item detail never repeats a branch and its balance equals the sum of branches`
  يمرّ على كل أصناف الصفحة ويتحقق من الأمرين معاً.

### و) البوابات

| البوابة | النتيجة |
|---|---|
| `php -l` (بعد Pint) | بلا أخطاء |
| `php artisan test --filter=StoreItemReadTest` | **8 ناجحة / 336 تأكيداً** |
| `flutter analyze` | **No issues found** |
| `flutter test test/features/stores/` | **85 ناجحاً** |
| `vendor/bin/pint --dirty` | fixed (ملف واحد) وأُعيد الاختبار بعده |

**النموذج:** Qoder · **الوقت:** 2026-11-04 · **DDL:** لا · **DML:** لا · **لا جدول جديد** · **لا commit**.



## 2026-11-07 — قسم تقارير المخازن: نافذة معطيات متعدّدة الاختيار وقالب رسمي موحّد

**السياق:** طلب المستخدم تطوير قسم التقارير على محورين: معطيات التقرير (تصفية أفقية حقيقية)
وقوالب التقارير (مستند يُطبع ويُصدَّر كما يُرى). نُفّذ المحوران معًا لأن قالبًا بلا معطيات
متعددة يبقى تقريرًا أحادي البُعد.

### أولًا — نافذة المعطيات (`widgets/report_filter_sheet.dart`، جديد)

استُبدلت النافذة القديمة التي كانت تعرض قائمة المخازن كـ`FilterChip` مكشوفة (وهي التي
«تُظهر شاشة بيضاء بلا خيارات» حين تضيق الشاشة بستة حقول مفتوحة) بحقول موحّدة:

- **`MultiSelectField` (`widgets/multi_select_field.dart`، جديد):** زر واحد يعرض ملخّص
  الاختيار دائمًا (`لاشي` · `الكل (n)` · أسماء المحددين · `س +2`)، واللوحة بمربعات اختيار
  وبحث و«لاشي» و«الكل» **لا تُبنى أصلاً وهي مغلقة**. هذا هو المطلوب حرفيًا: إخفاء القائمة
  وإظهارها فقط عند فتح الحقل — مع فائدة إضافية أن قائمة بمئات الأصناف لا تدفع الأزرار خارج
  الشاشة (سقف 220px بتمرير داخلي).
- الحقول: المخازن (متعدد) · المجموعة الرئيسية (متعدد) · المجموعة الفرعية (متعدد، تتابع
  المختارة منها) · الفئة (مفرد + لاشي) · الصنف الرئيسي (منتقي بحث، **النشط فقط**) ·
  **الصنف الفرعي (جديد)** · نوع الحركة (متعدد، يظهر في «عرض حركة» فقط).
- **«لاشي» قيمة صريحة:** تمسح المحدّد وتُترجم في الاستعلام إلى «بلا قيد»؛ لا يُرسل رقم وهمي
  أبداً (وهو خطأ الفلاتر الكلاسيكي الذي كان يعيد تقريرًا فارغًا بلا سبب ظاهر).
- **تنقية المحدد القديم:** تغيير المجموعات الرئيسية يُسقط الفرعيات التي لم تعد تنتمي إليها؛
  بلا هذا الشرط يبقى قيد خفيّ في `item_type_nos` فيوسّع التقرير أو يُفرّغه بلا تفسير.
- **مسح الأب يُبطل الابن:** اختيار صنف رئيسي مختلف يمسح الفرع المختار، لأن فرعًا لأبٍ آخر
  لا معنى له في نفس الاستعلام.
- **منتقيات بخليط واحد (`_SearchPicker`):** بحث خدع 300ms + `CancelToken` + عدّاد إصدار
  يحرس السباق (الطلب الأقدم يصل بعد الأحدث)، و«لاشي» أول السطر دائمًا.
- إضافات: مدىً جاهزة (اليوم/أسبوع/شهر/3 أشهر) و«لاشي / إعادة ضبط» تمسح كل القيود دفعة واحدة.

### ثانيًا — الخادم (`StoreReportController.php`، `StoreItemController.php`)

- `applyScope()` و`balances()` يمرّان الآن عبر `scopeList()` + `inClause()`: قوائم للمخازن
  والمجموعات والفرعيات بأنواعها، مع بقاء الوسيطات المفردة القديمة مدعومة فلا ينكسر مستهلك.
  الروابط مسمّاة (`:gr0`, `:it1`, `:tn2`) ولا رقم داخل نص SQL.
- فصل واضح بين `item_type_nos` (= `m.TYPE_NO`، المجموعة الفرعية للصنف) و`type_nos`
  (= `m.BILL_DOC_TYPE`، نوع الحركة) — خلطهما كان source of empty reports في جلسة سابقة.
- الخلاصة: `group_by` بمستويات `item|store|group|subgroup|category` من `match` حرفي (لا
  حقن أعمدة)، و`ORDER BY` بالأسماء المستعارة تفاديًا لـ`ORA-00935`.
- عرض الحركة: عمودا `SUB_NAME` و`COLOR_NAME` بلقطة فردية `(SELECT MAX(...) …)`. السبب موثّق
  في مكانه: `SANFS_COLOR` غير فريدة على `COLOR_NO`، فرابط `LEFT JOIN` يضاعف سطور الحركة نفسها.
- `subIndex`: وسيط `sanf_no` لمنتقي الفروع + النشط فقط.

**إصلاح ظهر بسبب الاختبار لا بسبب المستخدم:** قائمة `SELECT` في الخلاصة كانت تقرأ
`m.I_CODE` خامًا بينما `GROUP BY` يتبدّل، فألقى `ORA-00979: not a GROUP BY expression` عند
أي مستوى غير «البند × المخزن». صار `MAX(m.I_CODE) AS I_CODE` (صحيح عند مستوى البند أيضًا
لأنه ضمن المفاتيح).

### ثالثًا — قالب التقرير الرسمي

- **عمود واحد لكل المستهلكين (`utils/report_columns.dart`، جديد):** 17 عمودًا للحركة و13
  للخلاصة، لكل عمود `id`/عنوان/وزن/قارئ `(row, index)`. القارئ يستقبل الفهرس فيصبح عمود «م.»
  جزءًا من القالب لا حالة خاصة في الشاشة. تعريف مشترك هو الضمان الوحيد أن ما يراه المستخدم هو
  ما يطبعه ويصدّره — وهي القاعدة التي كُسرت مرارًا في تقارير القسم.
- **`widgets/report_data_table.dart` (جديد):** الجدول الكسول الموحّد (رأس مثبّت + صفوف عند
  الظهور + سطر مجاميع مثبّت) داخل تمرير أفقي بسقف عرض منطقي؛ الأرقام تُحاذى يسارًا والنصوص
  يمينًا، والقيم السالبة تظهر بلون الخطر (الرصيد السالب علامة مراجعة في المخزون).
- **`widgets/report_columns_sheet.dart` (جديد):** إظهار/إخفاء الأعمدة بـ«الكل» و«لاشي»؛
  «لاشي» هنا = الافتراضي، والقالب يرفض الجدول بلا أعمدة بالعودة إلى الافتراضي.
- **`utils/report_parameters.dart` (جديد):** وصف موحّد لمعطيات التقرير يقرأ منه شريط الشاشة
  وترويسة الـ PDF وورقة الـ Excel. كل بُعد مذكور حتى «بلا قيد»، وأنواع الحركة في الخلاصة
  تُعلَّم «غير مطبَّقة» بدل أن تُعرض كشرط وهو لا يعمل.
- **الشاشة (`store_reports_screen.dart`):** `ReportZoomView` (تكبير/تصغير بنسبة ظاهرة) ←
  `SingleChildScrollView` ← `ReportA4Sheet` بترويسة `ReportLetterheadBranding` (ترويسة
  التطبيق الرسمية) وشريط معطيات كامل وجدول الأعمدة المختارة و`ReportSignatureFooter`
  (تذييل التوقيعات الرسمي). الأزرار: تصفية · أعمدة · طباعة · تصدير PDF/Excel (محروسة
  بالمسموح `stores.reports_printed` / `stores.reports_exported`).
- **كشف حركة الصنف (`item_movement_screen.dart`):** انتقل من قائمة بطاقات إلى القالب الرسمي
  نفسه (ترويسة + معطيات + جدول أعمدة + تذييل توقيعات + تكبير + أعمدة قابلة للإخفاء).

### رابعًا — التصدير

- `buildStoreReportPdf`: ترويسة رسمية بشريط معطيات كامل (كان سطرَين فقط من تسعة)، ثم شريط
  مجاميع، ثم جدول بالأعمدة المختارة نفسها، ثم `pdfSignatures()`. الخلاصة: **المطبوع نسخة
  المعروض لا جدولًا ثانيًا**. حُذف `_movementTable`/`_summaryTable` اليدويان اللذان كانا
  مصدر الاختلاف.
- `buildStoreReportXlsx` (جديد): ورقة السطور بنفس الأعمدة والمجاميع + ورقة «المعطيات»
  (كل قيد + عدد السطور + وارد/صادر/القيمة) — ملف يُفتح بعد أسبوع بلا فترة ولا مخازن لا يُحكم عليه.
- `buildItemStatementPdf`: أعمدة القالب المشترك + توقيعات، و`buildItemStatementXlsx` (جديد).

### خامسًا — الاختبارات

- `test/features/stores/report_template_test.dart` (جديد): أعمدة لكل بُعد ينتجه معطٍ، ترقيم
  بالوضع لا بالمحتوى، الفرع يظهر فقط إن حملت الحركة فرعًا، رفض الجدول الفارغ، تبدّل عنوان
  الخلاصة مع مستوى التجميع، طباعة كل الأبعاد بصيغة «بلا قيد»، حلّ المعرّفات إلى أسماء المرجع
  مع رجوع للرقم إذا غاب، «غير مطبَّقة» للأنواع في الخلاصة، ودجت المتعدد (مطوية قبل الفتح،
  ملخّص بدل الفراغ، «الكل (n)»، مسح سريع، إرسال المجموعة بعد التبديل)، وتتابع الفرعيات
  (تضييق، «لاشي» = بلا قيد، ولا تكرار لمجموعة فرعية مشتركة).
- `report_filter_test.dart`: تحديث للقوائم المتعددة + حارس أن المفرد لم يعد يُرسل + مستوى
  التجميع يظهر في الخلاصة وحدها + عدّاد القيود الفعلية + مسح الصنف يسحب اسمه واسم فرعه.
- `StoreReportTest.php`: مخازن متعددة، مجموعات متعددة بحارس **الجمع** (معًا = مجموع كل واحدة
  وحدها؛ أي رابط مضاعِف يخرقه) بنافذة من ساعة أوراكل ومجموعات قليلة الحركة حتى لا يقتطعها
  سقف الـ 5000، «لاشي = بلا قيد»، أعمدة الفرع/اللون، مستويات التجميع، ومستوى مجهول لا يصل
  إلى SQL.

### سادسًا — ملاحظات تنفيذ

- حُذف `_ColumnsSheet` من الشاشة بعد تحويله إلى ودجت عامة، وحُذف `storeList()` من المتحكم
  بعد استبداله بـ`scopeList()`، وحُذف `orderedColumnIds` غير المستخدم.
- الإصلاحان اللذان كانا من تعديل يدوي للمستخدم في `item_detail_screen.dart` أُبقيَا كما هما
  مع تصفيف التنسيق فقط (`child` أخيرًا، وإزالة `??` ميتة بعد أن صار `colorLabel` يحمل
  احتياطه داخله).
- **لا جداول جديدة، لا DDL، لا DML، لا commit.**


## 2026-11-08 (أ) — إصلاح توقف التطبيق عند إنشاء تقرير + قالب على خمسة مكوّنات

### أولًا — الانهياران اللذان أوقفا التطبيق (من سجل الجهاز المرفوع)

1. **`BoxConstraints forces an infinite width`** عند أول تقرير: كان `ReportDataTable` يلفّ
   `LazyReportTable` داخل `SingleChildScrollView(Axis.horizontal)`، والتمرير الأفقي يعطي الطفل
   عرضًا لانهائيًا بينما `Table` يوزّن `FlexColumnWidth` على عرض متاح.
   **الحذف لا الإصلاح:** أُلغي التمرير الأفقي كليًا؛ الجدول يأخذ عرض الصفحة دائمًا.
2. **`type '(StockMovementRow, int) => String' is not a subtype of type '(Object, int) => String'`**
   — كان محجوبًا خلف الانهيار الأول (لم تُبنَ أي خلية قبله). السبب `.cast<ReportColumn<Object>>()`
   على قائمة أعمدة: **أنواع Dart عامة ليست آمنة عند إمحاء نوع داخل دالة قارئ** — الدالة التي
   تقبل `StockMovementRow` ليست دالة تقبل `Object`، والأنواع تُتحقق وقت التشغيل هنا.
   **الحل: Generics حقيقية** عبر كل المسارات: `ReportDataTable<T>` و`_reportPdfTable<T>` و
   `_reportPdfBlocks<T>` و`_appendColumns<T>`، فلا شاشة ولا PDF ولا Excel يرى نوعًا محاكًا.
3. حُذفت أكوام ميتة نتجت عن التطوير المتتابع: `_paramsBar`/`_metaBlock`/`_totalsFor`/
   `_title(State)` من الشاشة، و`_header`/`_sheetMeta`/`_totals` من كشف الحركة، و
   `_reportParamsGrid` من الـ PDF.

### ثانيًا — قالب التقرير صار خمسة مكوّنات لا غير

1. **الترويسة الرسمية** — `ReportLetterheadBranding` (نفس ما يُطبع).
2. **عنوان التقرير فقط** — `ReportTitles.of(...)` يبنيه من **أضيق بُعد مختار**:
   `كشف حركة صنف فرعي : <اسم الفرع>` ← `كشف حركة صنف : …` ← `مجموعة فرعية` ← `مجموعة رئيسية`
   ← `كشف حركة المخازن`؛ وتحته **الفترة فقط إذا خصّصها المستخدم** (وسم `customPeriod` جديد على
   `StoreReportFilter` يقرره منتقي المعطيات نفسها)، وتحته **«من مخزن: …» فقط إذا خصّص المخازن**.
   المنطق كله في `utils/report_parameters.dart` ليستخدمه Screen وPDF من مصدر واحد.
3. **جدول الكشف** بكل الأعمدة **بعرض الواجهة نفسه بلا تمرير جانبي**، والنص كامل بلا `ellipsis`
   مع مقياس خط يشتق تلقائيًا من (العرض ÷ عدد الأعمدة): 11.0 → 7.5pt.
4. **ملخص الجدول** عنصر مستقل بعد الجدول: عدد السطور · وارد · صادر · الصافي · القيمة.
5. **التذييل الرسمي** — `ReportSignatureFooter` على الشاشة، `pdfSignatures()` في المطبوع.

### ثالثًا — توثيق فني يبقى مهمًا

- `pw.FontWeight.bold` ليس ثابتًا في pdf 3.11.3، و`PdfColor` بلا `withValues` → لا `const`
  لتلك الأنماط (درس تكرر ثلاث مرات في هذه الجولة).
- `AppColors.borderColor`/`cardBackground` غير موجودة: الصحيح `border`/`surface`، و`primary`
  و`textSecondary` و`textPrimary` قيم مشتقة فلا تصلح داخل `const`.
- الميمكس `_SearchPicker<T extends ConsumerStatefulWidget>`: القيد يجب أن يكون
  `ConsumerStatefulWidget` لا `StatefulWidget` لأن `ConsumerState<T>` يشترطه.
- حارس الانحدار الجديد: اختبار **لا يوجد `SingleChildScrollView` أفقي داخل الجدول**، واختبار
  **عنوان الشاشة = عنوان المطبوع**، لأن كلا الانهيارين مرّ من بوابات سابقة بفحص التعريف لا بالتخطيط.

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **البوابات:** analyze نظيف · مخازن 120 · الكلي 592.


## 2026-11-08 — قالب التقارير: جدول يتمدّد على الصفحات بدل صندوق ثابت بتمرير داخلي

**الطلب:** كامل السجل يُعرض كصفحات مرنة حسب صفوفه، لا كمساحة جدول ثابتة يتمرَّر عموديًا داخلها.

### أولًا — جدول الواجهة (`widgets/report_data_table.dart`)

- استُبدل `LazyReportTable` (صندوق بارتفاع ثابت 55% من الشاشة مع `ListView` + `Scrollbar`
  داخلي) بـ**تدفق طبيعي**: `Column` من كتل `Table` متتابعة تأخذ عرض الصفحة كاملاً ويمتد
  ارتفاعها بعدد صفوفها، والتمرير كله للصفحة نفسها لا لنافذة داخلها.
- **حفظ الذاكرة بقي كما هو السبب:** الصفوف تُبنى على دفعات 120 وتُزاد تلقائيًا عندما يقترب
  القارئ من أسفل الصفحة (`Scrollable.maybeOf(context)!.position` + مسافة تحضير 600px)، لأن
  بناء آلاف الخلايا دفعة واحدة كان يقتل التطبيق (`ui.Paragraph` لكل خلية).
- توحيد `columnWidths` بين كل الكتل يبقّي الجدول **جدولًا واحدًا متصلًا** لا مخططات منفصلة،
  والرأس يظهر مرة واحدة في الأعلى (الملخص مكوّن مستقل بعد الجدول).
- تصفير الدفعة عند قدوم صفوف أو أعمدة جديدة — `didUpdateWidget` — فلا يبقى العرض مقصوصًا
  عند آخر حالة.
- **حُذف** من الودجت `totals` و`rowsHeight`: لم يعودا عنصرين في القالب (الملخص مستقل)،
  وحُذف `_totalCell` و`_Styles.widths` اليتيم.

### ثانيًا — تصحيح انفجار ظهر فورًا في الاختبار

`RangeError (length): Invalid value: Not in inclusive range 0..1: 2` — الحلقة كانت تستخدم
`_built` خامًا دون حصره بعدد الصفوف الفعلي، فتُبنى فهرسات خارج النهاية عند السجلات الصغيرة.
الحل `shown = min(_built, rows.length)` في الحلقة وفي شريط «عرض المزيد»، وتهيئة `_built`
بـ`min(_chunk, rows.length)` في `initState` و`didUpdateWidget`.

### ثالثًا — الـ PDF (`utils/store_export.dart`)

`pw.Table` في حزمة pdf 3.11.3 **يمتد عبر الصفحات تلقائيًا** (`SpanningWidget`) ولا يكرّر رأسه
(لا يوجد `repeatHeader` في هذه النسخة)، لذلك استُبدل `_reportPdfTable` بـ`_reportPdfBlocks<T>`
التي تُخرج **جدولاً لكل صفحة**: رأس الجدول + حتى 30 صفاً، فتبقى الأعمدة معروفة في كل صفحة من
المستند المطبوع. الكتلة إن تجاوزت صفحة امتدت وحدها فلا يضيع صف. وأُضيف `_pdfHeadRow<T>`.
المُستخدِمان: `buildStoreReportPdf` و`buildItemStatementPdf` ينشرون الكتل الآن.

### رابعًا — الاختبارات (+1 جديد، وتحديث 3)

- `grows with its rows instead of a fixed inner scroller`: 40 صفًا — لا `Scrollbar` ولا
  `ListView` داخل الجدول، وكل الصفوف موجودة في الشجرة (`صنف 39` ترقيم 40).
- أُزيلت وسائط `totals:` من اختبارات القالب بعد حذفها من الودجت.
- **النتيجة:** analyze «No issues found» · مخازن **121 ناجحة** · الكلي **593** (~10 متخطًّى) ·
  **بلا أي commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-08 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.


## 2026-11-09 — تقارير المخازن: رصيد حقيقي، أعمدة حرة الترتيب، سطر تجميع، إحصاءات مختصرة، وتذييل قسمي

### أولًا — عمود الرصيد الفارغ (خادم `kyApp_API`)

السبب لم يكن في SQL ولا في العميل: `yajra/laravel-oci8` يعيد **مفاتيح الأعمدة بأحرف صغيرة**
(`p_qty`, `seq`, `net_qty`)، بينما كود `StoreReportController` كان يقرأ `P_QTY` و`P_CODE` و`NET_QTY`،
فيصل `$row['P_QTY']` غير معرَّف ويُطبع العمود فراغًا. أُضيف التطبيع
`array_change_key_case((array) $row, CASE_UPPER)` في مسار الحركة ومسار الخلاصة وفي مساعدَي الرصيد
الافتتاحي، ثم يُعاد السطر كما هو فيظل العميل يقرأ المفاتيح الكبيرة والصغيرة معًا (`json['A'] ?? json['a']`).

> ملاحظة للذاكرة: `ArabicEncoding::cleanData()` يعالج الترميز فقط ولا يغيّر حالة المفتاح.

### ثانيًا — معرّفات الأعمدة والترتيب (`utils/report_columns.dart`)

- عمود فرع الخلاصة كان يحمل المعرّف `sub` نفسه الذي تحمله المجموعة الفرعية، فكانت خريطة الترتيب
  تُزيل أحدهما والرقيقة تتكرر؛ صار `branch` مع تعليق ثنائي اللغة يوضح قاعدة **المعرّف الفريد**.
- أُضيف `ReportColumns.ordered<T>(columns, ids)`: يبني خريطة معرّف→عمود، ثم يرسم بترتيب المستخدم،
  ويتجاهل أي معرّف لا يخصّ القالب، ويعود إلى `ReportColumns.defaultIds` حين لا يبقى شيء — جدول بلا
  أعمدة مستحيل.
- `ReportTemplates`: `basic` صار «تظهر أول مرة ويستطيع المستخدم إخفاءها أو إعادة ترتيبها»،
  و`defaultIds` صارت `List<String>`، وحُذفت `visibleIds` (كانت تربط العرض بالقالب فيمنع الترتيب).

### ثالثًا — نافذة الأعمدة (`widgets/report_columns_sheet.dart`، إعادة كتابة)

تعيد الآن `ReportColumnsChoice{columnIds, statIds}`:

- كل سطر عمود = `Checkbox` + عنوان + سهمَي **أعلى/أسفل** لإعادة الترتيب (`_move`).
- قسم ثانٍ للرقائق: حقول الإحصاءات بمعرّفات ثابتة + زر «إظهار كل الإحصاءات».
- «تطبيق» يُعطَّل حين لا يبقى عمود واحد، مع رسالة: «اختر عموداً واحداً على الأقل — الجدول بلا أعمدة
  لا يقول شيئاً».
- التهيئة كلها في `initState` (بلا `late` على الحقول يحسب من `widget` قبل إسناده).

### رابعًا — سطر التجميع (`utils/report_totals.dart` + `widgets/report_data_table.dart`)

- `ReportTotals.movement/summary` يجمع الكميات والقيم فقط. **لا التكلفة** (سعر وحدة) و**لا الرصيد
  الجاري** (رقم متراكم أصلًا) — جمعهما يعطي رقمًا كاذبًا.
- `ReportDataTable` صار يقبل `totals` ويرسم صفًا بلون `AppColors.primary` شفاف وخط `w800`، ويكتب
  «الإجمالي» في أول خانة فارغة بدل تركه خاليًا.

### خامسًا — شريط الإحصاءات المختصر (`widgets/report_stats_band.dart`، جديد)

`ReportStatFields` (في `report_totals.dart`) يبني الحقول بمعرّفات ثابتة
(`rows/opening/in/inValue/out/outValue/net/closing/closingValue`) لكل من `ReportStats` و
`MovementStatement`، و`visible(fields, ids)` يرشّحها — `null` = الكل، `[]` = لا شيء.
`ReportStatsBand` يعرضها رقائق في شريط واحد: عنوان 9pt باهت وقيمة 11pt عريضة، والقيمة الصفرية
(مثل `closingValue = 0`) لا تُبنى أصلًا فلا تُضجّ الشريط.

### سادسًا — التذييل بحسب القسم

- `ReportSignatureFooter({keeper})` مع ثابتين: `cashier` («توقيع أمين الصندوق») و`storekeeper`
  («توقيع أمين المخزن»)؛ المخازن وكشف الحركة تمرّران `storekeeper`، وبقية الشاشات تبقى على الافتراضي.
- في PDF: `pdfSignatures({keeper})` — نفس القاعدة في `buildStoreReportPdf` و`buildItemStatementPdf`.

### سابعًا — التكافؤ في PDF وExcel (`utils/store_export.dart`)

- `buildStoreReportPdf(…, statIds:)` و`buildItemStatementPdf(…, statIds:)`.
- الأعمدة تُرسم بـ`ReportColumns.ordered` بالترتيب نفسه، وسطر التجميع يُبنى من `ReportTotals`،
  وشريط الإحصاءات يُرشَّح بالمعرّفات المختارة (`_reportTotalsStrip` و`_statementSummaryStrip`).
- حُذف `_reportTotals` و`_statementTotals` المحليان (تكرار لمنطق `ReportTotals`).
- `buildItemStatementXlsx` ومسار XLSX في تقرير المخازن يستعملان `ReportTotals` نفسها.

### ثامنًا — الاختبارات والبوابات

- مجموعتان جديدتان في `test/features/stores/report_template_test.dart`: `column order` (3 اختبارات:
  ترتيب المستخدم، إسقاط المعرّف الغريب، الرجوع للافتراضي) و`totals and statistics` (3: جمع الحركة بلا
  تكلفة/رصيد، جمع الخلاصة مع الرصيد الختامي بلا تكلفة، معرّفات الإحصاءات وإخفاء الصفر).
- اختبار «الأساسيات لا تُخفى» أُعيد بناؤه ليطابق السلوك الجديد (تفرّد المعرّفات + `defaultIds == basic`).
- **الخادم:** اختبار «multiple main groups…» كان يثبّت نافذة 60 يومًا فيتجاوز سقف الاقتطاع (5000) مع
  نمو الحركة، فصار يجرّب 7/14/30/60 يومًا ويتوقف عند أول نافذة غير مقتطعة، ويتخطّى برسالة صريحة إن
  لم تلائم أي نافذة — بدل أن يفشل بسبب حجم البيانات.
- **النتيجة:** analyze «No issues found» · الكلي **610** (~10 متخطًّى) · Pest **16/16** (9630 تأكيدًا) ·
  Pint مطابق · **بلا أي commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا جداول جديدة** · **لا commit**.

---

## 2026-11-09 02:43 — إصلاح «التقرير الكبير لا يُطبَع ولا يُصدَّر» في **كل** تقارير PDF

### العَرَض من المستخدم

طباعة/تصدير كشف حساب مالي (الحساب `38310001` من `2026-05-01` إلى `2026-10-31`) كانت تفشل
كلياً بلا أي رسالة، مع هذا الأثر:

```
E/flutter: Unhandled Exception: Instance of 'TooManyPagesException'
#0  MultiPage.generate.<anonymous closure> (package:pdf/src/widgets/multi_page.dart:260:11)
#3  buildAccountStatementPdf (.../account_statement_pdf_builder.dart:40:7)
#4  _AccountStatementScreenState._printReport (.../account_statement_screen.dart:167:19)
```

### السبب الجذري (مُتحقَّق من كود الحزمة لا من التخمين)

`pdf-3.11.3/lib/src/widgets/multi_page.dart`:

```dart
this.maxPages = 20,           // ← الافتراضي 20 فقط
...
assert(() {
  if (sameCount++ > maxPages) throw TooManyPagesException(...);
  return true;
}());
```

- `sameCount` يزيد عند كل محاولة تخطيط **لا تُكمل العنصر**، ويُصفَّر عند إكماله (`sameCount = 0`).
  فهو يقيس امتداد **العنصر الواحد القابل للامتداد** (`SpanningWidget`) لا عدد صفحات المستند.
- `pw.Table` عنصر قابل للامتداد، والكشف يمرَّر كجدول **واحد** فيه كل الحركات.
- ⇒ أي كشف يتجاوز ~20 صفحة (نحو 700 حركة) يرمي `TooManyPagesException` **قبل** إنشاء الصفحة
  21، فيسقط `doc.save()` بالكامل: لا طباعة، لا تصدير، ولا رسالة للمستخدم.
- الأثر في كود التطبيق: **لم يكن أيٌّ من 15 موضع `pw.MultiPage` يمرّر `maxPages`**، فكلها
  كانت واقعة تحت السقف الافتراضي.
- الخادم **بريء**: `AccountController::getAccountStatement` يُرجع كل حركات الفترة عند غياب
  `limit` (لا اقتطاع)، فالبيانات كاملة والعلة في التوليد على العميل.

### أين أُصلح (التغطية: 15 موضعاً في 11 مولّداً)

| الملف | المواضع |
|---|---|
| `lib/core/utils/report_pdf_page.dart` | **جديد**: `const int kReportPdfMaxPages = 20000` + شرحه |
| `accounts/.../account_statement_pdf_builder.dart` | 1 |
| `accounts/.../account_statement_detail_pdf_builder.dart` | 1 |
| `accounts/.../account_group_statement_pdf_builder.dart` | 1 |
| `accounts/.../account_tree_pdf_builder.dart` | 1 |
| `customers/.../customer_statement_pdf_builder.dart` | 1 |
| `customers/.../customer_measurement_pdf_builder.dart` | 1 |
| `workers/.../worker_statement_pdf_builder.dart` | 1 |
| `workers/.../worker_work_report_pdf_builder.dart` | 1 |
| `workers/.../worker_group_work_report_pdf_builder.dart` | 1 |
| `tailoring/.../cutting_bill_pdf_builder.dart` | 1 |
| `stores/.../store_export.dart` | 5 (أمر مستند + تقرير حركة + جرد + كشف صنف) |

كل موضع صار يمرّر `maxPages: kReportPdfMaxPages` مع تعليق عربي/إنجليزي يوضّح العلة،
والتعريف واحد مشترك فلا تتفرّق القيمة بين الملفات.

### لماذا 20000 وليس `null` أو رقماً بلا حد

- ≈ 700 ألف سطر حركة (نحو 35 سطراً في صفحة A4) — أضعاف أي دفتر أستاذ فعلي.
- يبقى حدًّا يمنع دوراناً لا نهائياً عند خلل تخطيط (الحرس الأصلي للحزمة) بدل تعليقه.
- لا حاجة لترقيم/تقسيم يدوي للبيانات: `MultiPage` يقسم الجدول تلقائياً، والترويسة والتذييل
  يتكرران في كل صفحة، ورقم الصفحة `صفحة X من Y` يُحسب بعدد الصفحات الكامل.

### الحارس (اختبار انحدار جديد)

`test/features/accounts/account_statement_pdf_large_test.dart` — 3 اختبارات تبني PDF فعلياً:

1. كشف قصير (12 حركة) يخرج ملفاً صالحاً — ضبط عدم الانحدار.
2. **كشف 900 حركة**: يتحقّق أن الملف خرج، وتُعدّ كائنات `/Type /Page` داخله، ويُشترط
   `pages > 20` (كان يرمي قبل الإصلاح) وأن العدد يتبع حجم البيانات لا أن يتوقف عند 21.
3. `kReportPdfMaxPages` أكبر بكثير من الافتراضي 20.

### الحصاد

- `flutter analyze` → **No issues found!**
- `flutter test` → **613 ناجح** (~10 متخطّى)، منها 3 جديدة.
- **لا تغيير في قاعدة البيانات** (لا DDL ولا DML)، **ولا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 02:43 · **DDL:** لا · **DML:** لا · **لا commit**.

---

# 2026-11-09 — الرصيد السابق والتقارير الهرمية الثلاثة (المخازن)

## الشكوى

المستخدم رفض ما سُلِّم في الجولة السابقة برسالتين صريحتين:

1. **«لماذا لا يتم إرجاع قيمة حقل الرصيد السابق؟»** — وعمود الرصيد يجب أن تكون قيمته الأولية هي
   رصيد الفترة السابق ثم تُجمَّع عليه الحركات.
2. **«حركة صنف رئيسي / مجموعة فرعية / مجموعة رئيسية تُعرض بشكل خاطئ، تُعرض مثل تقرير حركة صنف
   فرعي»** — والعقد المطلوب: كل تقرير يُقسَّم على وحدته الأدنى بصف إحصاء في نهاية كل قسم، وإحصاء
   ختامي على كل الوحدات (الفرع · الصنف الرئيسي · المجموعة الفرعية على الترتيب).

## التشخيص

أثبت تحقيق مؤقّت (`probe_scopes.php` على قاعدة oracle الحية) أن كل نطاق يعود بـ
`sections_count: 1` ومحتواه `{"key":"__all__","label":"","opening":0}` رغم أن كل سطر يحمل
`SECTION_KEY` صحيحاً. فالعيب ليس في البيانات بل في أربعة مواضع متسلسلة:

| # | الموضع | العلة |
|---|---|---|
| أ | `movementMeta($clean, …)` | استلم السطور **الخام**. مصفوفات PHP تُنسخ عند الكتابة، فما وسمه `stampMovement()` لم يرجع للمستدعي، فلم تُقرأ `SECTION_KEY` البتة وانهارت الأقسام كلها إلى `__all__` بلا عنوان ولا افتتاح. |
| ب | `movement()` — نطاق الفرع | كان يُمرَّر `[]` مكان الأرصدة: «الفرع تقرير واحد فلا افتتاح له» — وهو عين ما شكا منه المستخدم. |
| ج | `store_reports_screen.dart` | بوابة التقسيم كانت `state.sections.length > 1`؛ وبما أن الخادم أعاد قسماً واحداً دائماً، سقطت التقارير الثلاثة كلها إلى الجدول المسطّح. فبدت الثلاثة نسخة من الصنف الفرعي. |
| د | `buildStoreReportPdf` | لم يكن يستقبل أقساماً أصلاً: يُطبع جدول واحد مهما كان النطاق. |

## الإصلاح

### الخادم — `StoreReportController`

- `movement()`: `$stamped = $this->stampMovement($clean, …)` في **متغيّر** قبل بناء الإحصاءات، ثم
  `movementMeta($stamped, …)`. تعليق في الموضع نفسه يشرح النسخ عند الكتابة لمن يعيد هذا الخطأ.
- `openingBySection()`: استعلام واحد لكل النطاقات، مفتاحه `'__all__' AS SK` حين لا يوجد عمود تقسيم
  و`GROUP BY` حين يوجد؛ ويجمع **الكمية والقيمة** معاً (`SUM(P_QTY)` و`SUM(P_QTY * STK_COST)`).
- `stampMovement()`: رصيد القسم يبدأ من افتتاحه كمّاً وقيمةً لا من الصفر.
- `movementMeta()`: كل قسم يحمل `opening_qty` و`opening_value` و`closing_value =
  opening_value + qty_in_value − qty_out_value`، والإجمالي يحمل `opening_value`.

### العميل

- `report_model.dart`: `StoreReportScope.sectionLabel` (الصنف الفرعي / الصنف الرئيسي / المجموعة
  الفرعية) و`sectionPlural` (…/الأصناف الرئيسية/المجموعات الفرعية)، و`ReportStats.openingValue`.
- `store_reports_repository.dart`: `sectionKeys` — المفاتيح بجانب العناوين من نفس القائمة.
- `reports_providers.dart`: `ReportSectionHeader.key` إلزامي، وإحصاء كل قسم يُطابق سطوره **بالمفتاح**
  لا بالفهرس (الفهرس كان يربط إحصاء قسم بسطور قسم آخر عند أي اختلاف في الترتيب).
- `report_totals.dart` + `report_data_table.dart`: `ReportTotals.opening()` وصف **«رصيد سابق»** أعلى
  الجدول وأعلى كل قسم، بنفس قاعدة العمود الأول الفارغ التي يستخدمها صف الإجماليات.
- `store_reports_screen.dart`: البوابة صارت `template.sectioned` وحدها؛ عنوان كل قسم
  `'${scope.sectionLabel}: ${section.label}'`؛ شريط إحصاء القسم `إحصاءات <sectionLabel>`؛ والشريط
  الختامي `إحصاءات التقرير — إجمالي كل <sectionPlural>`.
- `store_export.dart`: PDF وXLSX يطبعان الأقسام وعنوان كل قسم وصف «رصيد سابق» وإحصاءه، مع استخراج
  `sectionStatsLine()` مشتركاً فلا يتباعد نص الشاشة عن نص المستند.

## التحقق التجريبي (قراءة فقط على oracle)

| النطاق | الأقسام | الافتتاح | أول `BALANCE_QTY` |
|---|---|---|---|
| فرع (مخزن 1) | 1 (`__all__`) | **251711.69** | **251741.69** ✔ (الافتتاح + 30) |
| صنف 1991 | قسم لكل فرع | افتتاح مستقل لكل فرع | يبدأ من افتتاحه ✔ |
| مجموعة فرعية | **136** | مثلاً 6.05 و7.55 و2478.9 | يبدأ من افتتاحه ✔ |
| مجموعة رئيسية | قسم `101` | **126950.69** | يبدأ من افتتاحه ✔ |

النافذة `2026-01-01 … 2026-10-31` تعطي افتتاحاً صفراً **بصدق** لا بخلل: تحقيق مستقل أثبت أن أول
حركة في الدفاتر `2026-04-25`، فلا يوجد رصيد قبل 2026. لذلك بُنيت اختبارات الافتتاح على نافذة
`2026-09-01`.

## الاختبارات المضافة

- **Pest** (`StoreReportTest.php`، 4 اختبارات جديدة): قسم لكل فرع في نطاق الصنف الرئيسي؛ وحدات
  المجموعة الفرعية هي الأصناف الرئيسية؛ وحدات المجموعة الرئيسية هي `TYPE_NO` لا الصنف الرئيسي؛
  ونطاق الفرع يعيد افتتاحاً **غير صفري** وقيمة افتتاحية، مع `first_balance == opening + P_QTY` في
  كل قسم (مساعد `sectionOpenings()` يفحص أول سطر من كل قسم مقابل إحصائه).
- **Dart** (`report_template_test.dart`، 3 مجموعات): وحدة القسم لكل نطاق وتفرّدها عن اسم التقرير؛
  أن الافتتاح هو أول رقم في عمود الرصيد وأن صف «رصيد سابق» يُرسم فوق أول حركة؛ وأن المفاتيح تُقرأ
  بجانب العناوين فتُطابق الإحصاءات سطورها.

## الحصاد

- `php -l` → لا أخطاء · `pint --dirty --format agent` → نظيف (لم يمسّ إلا ملفات التحقيق المحذوفة).
- `php artisan test --filter=StoreReport` → **20 ناجحاً / 20263 تحققاً**.
- `flutter analyze` → **No issues found!** · `flutter test` → **620 ناجحاً** (~10 متخطّى).
- حُذفت ملفات التحقيق المؤقتة: `probe_scopes.php`, `probe_opening.php`, `probe_out.json`.
- **لا DDL ولا DML · بلا commit.**

## قيد معروف

الاقتطاع بـ`ROWNUM` يعمل على ترتيب «قسم ثم تاريخ»، فتقرير مجموعة رئيسية يتجاوز السقف (5000) قد
يُظهر أول مجموعة فرعية وحدها. إحصاءات كل قسم تبقى صادقة لأنها تُحسب من السطور المعروضة نفسها،
وشريط `truncated` ينبّه المستخدم. إعادة تصميم الاقتطاع (نافذة لكل قسم أو سقف لكل قسم) قرار مؤجَّل
بوعي، لا إغفال.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا commit**.

---

# 2026-11-09 (تكملة) — إحصاء القسم سطراً واحداً، وإصلاح انحدار أوقف البناء

## 1) الأعطال: أحد عشر خطأ تحليل في ثلاثة مواضع

`flutter analyze` كان يعيد 11 خطأً لأن أجزاءً من جولة سابقة لم تكن في شجرة العمل:

| الموضع | ما كان ناقصاً | الأثر |
|---|---|---|
| `ReportTotals` | `opening(ReportStats)` | أربعة مواضع تناديها (الشاشة ×3 والمصدّر ×1) فلم تُبنَ |
| `_appendColumns` | المعاملات `opening` · `heading` · `statsLine` | الـ XLSX كان يمرّرها فترفض |
| `_pdfSectionStats` | `pw.Double.infinity` (لا وجود لها في `pdf`) | خطأ ترجمة في مولّد الـ PDF |

أُعيدت الثلاثة كما كانت: `opening` تكتب `balance` (كمية الافتتاح) و`balanceValue` عند وجود قيمة،
و`_appendColumns` تكتب عنوان القسم ثم الرأس ثم صف «رصيد سابق» ثم السطور ثم التجميع ثم سطر الإحصاء
ثم سطراً فارغاً يفصل قسمين.

## 2) إحصاء القسم: سطر واحد بأربعة أرقام

المستخدم طلب ألا يُعاد إحصاء التقرير كاملاً تحت كل قسم، وأن يُصغَّر خط الحقول ومساحتها.

- **`ReportStatFields.sectionIds`** = `opening · in · out · closing` — الأربعة التي تُسأل عن
  القسم: من أين بدأ، وكم دخل، وكم خرج، وأين انتهى.
- **`ReportStatFields.section(stats)`** يبنيها بالترتيب الثابت، ويقرأ أرقامه من `_figures()` نفسها
  التي يقرأ منها `of()`، فلا يفترق رقمان متطابقان بين القسم والتقرير.
- **`ReportStatsBand.compact(...)`** نمط جديد: `Wrap` واحد فيه العنوان ثم أربعة أرقام بلا صناديق
  ولا إطارات، بخط `8` للعنوان و`9.5` للقيمة، وحشو `7/2`، وزوايا سفلية فقط ليلتصق بذيل الجدول.
- **الشاشة:** القسم صار `ReportStatsBand.compact` بـ`ReportStatFields.section`، والمسافة قبله `4`
  وبعده `14` بدل `8/16`.
- **المطبوع والمصدَّر:** `sectionStatsLine()` صار أربعة حقول لا ستة (سقط `net` و`closingValue`)،
  والـ PDF يطبعها في شريط رقيق بعنوان القسم وبخط `7.5`، والـ XLSX يكتب النص نفسه بعنوانه.

## 3) تصغير حقول الإحصاء عموماً

`_StatChip`: الحشو `6/3` → `5/2`، العنوان `9` → `8.5`، القيمة `11`/`11.5` → `10.5`/`11`،
المسافة داخل الخانة `4` → `3`. والشريط: الحشو `8/6` → `7/4`، `Wrap` `5/5` → `4/4`، والمسافة تحت
العنوان `5` → `4`. هذا يخصّ تقرير الحركة والشاشات الأخرى التي تستخدم الشريط الكامل.

## 4) الاختبارات

أربعة اختبارات في `test/features/stores/report_template_test.dart` (مجموعة `section statistics`):

1. `ReportStatFields.section` يعيد الأربعة بترتيبها ولا يحوي `rows`/`net`/`inValue`/`outValue`/`closingValue`.
2. نص السطر حرفياً: `السابق 240 · الوارد 50 · المنصرف 30 · الرصيد الحالي 260` ولا «الصافي» ولا «قيمة».
3. حقل أخفاه المستخدم يسقط وحده: `['opening','closing']` → `السابق 240 · الرصيد الحالي 260`.
4. `ReportStatsBand.compact` يرسم سطراً واحداً بلا استثناء ولا حقول تقرير كامل.

## 5) الحصاد

- `flutter analyze` → **No issues found!**
- `report_template_test.dart` → **61 ناجحاً** · `test/features/stores/` → **149 ناجحاً** ·
  `flutter test` → **624 ناجحاً** (~10 متخطّى).
- **لا تغيير في قاعدة البيانات** (لا DDL ولا DML)، **ولا commit**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 · **DDL:** لا · **DML:** لا · **لا commit**.


---

## 2026-11-09 04:53 — التفصيل: بطاقة قائمة الفواتير بلا تجاوز واسم كامل مصغَّر الخط

### العَرَض

`A RenderFlex overflowed by 2.4–7.5 pixels on the right` في
`bill_list_tile.dart` على سطر `Row` واحد، واسم العميل يظهر مقصوصاً («ين القريع»)،
وسطر البيانات يتشابك مع عمود الأرقام.

### العلة

`_counters()` كانت `Column` بأبناء غير محدّدي العرض (شارتان + صف صافي/حالة) داخل `Row`
البطاقة، واسم العميل في `Expanded` بلا تصغير. عند ضيق الشاشة يطلب عمود الأرقام أكثر من
حصّته فيتجاوز السطر.

### الإصلاح

- `SizedBox(width: 96)` لعمود الأرقام، و`Wrap(alignment: end)` للشارتين.
- `FittedBox(scaleDown)` لسطر (الصافي · الحالة) ولسطر الاسم ومربّع الرقم.
- سطر البيانات في `Wrap` مستقل بمسافات 8 و`runSpacing: 1`.
- تقليص أيقونة السهم إلى 13 وحشو البطاقة إلى 8 و8.

### الاختبار

اختبار جديد على عرض 360 بكسل باسم طويل (`عبدالرحمن محمد الأهدل الشميري`) يتحقق من ظهوره
كاملاً ومن انعدام أي استثناء. النتيجة: 56 اختبار تفصيل ناجح و`flutter analyze lib` نظيف.

**النموذج:** Qoder · **الوقت:** 2026-11-09 04:53 · **لا commit** (لم يُطلب).

---

# 2026-11-09 05:05 — المخازن: جدول التقرير سطرٌ واحد ثابت الارتفاع، وحقول الإحصاء خمسة افتراضياً

### العَرَض

على الهاتف مع تكبير خط النظام: رؤوس الأعمدة تخرج عن مواضعها وتتشوّه — «المستند» تظهر «المستن»/«د» —
وأرقام نهاية الجدول تتكسّر («12,985.7» ثم «6»)، ويختلف ارتفاع الصف من صف لآخر. وعند تكبير الشاشة
يزداد الأمر ظهوراً لأن حجم الخط المختار من العرض يكبُر أيضاً.

### العلة — ثلاثة أسباب متراكبة

1. **الالتفاف:** كل خلية كانت `Text(softWrap: true)`، فحين يعجز النص عن خانته يكسر الكلمة عند
   أي موضع — والرقم يُقسم بين سطرين فيُقرأ خطأً.
2. **قياس الرسم بلا مقياس الخط:** حجم الخط كان يُشتق من عرض الشاشة وحدها، وتكبير النظام ١٫٢٥ يُكبّر
   الحرف ٢٥٪ بعدها، فتضيق الخانة على نصها.
3. **تقريب الكسر بين الكتل:** كل كتلة (الرأس · الافتتاح · السطور · المجاميع) جدولٌ مستقل،
   و`FlexColumnWidth` يقرّب كسر البكسل في كل واحدة على حدة — فينزاح عمود عن عمود بمقدار بكسل.

### الإصلاح — `report_data_table.dart`

| ما تغيّر | كيف |
|---|---|
| خانة `_Cell` | `maxLines: 1` + `softWrap: false` + `FittedBox(scaleDown)` — النص يصغُر ليدخل، لا يلتفّ ولا يُقصّ |
| ارتفاع موحّد | `cellHeight = fontSize × textScaler × 1.55 + padding × 1.6` — الصف يكبُر مع الخط ولا يقطع الحرف |
| حجم موحّد مقيس | `_fitFactor` يقيس عناوين الرأس وأرقام الافتتاح والمجاميع بـ`TextPainter` ويأخذ **أصغر نسبة**، بحدّ أدنى `0.62` |
| أعمدة بالبكسل | `_columnWidths` تحسب `FixedColumnWidth` مرة واحدة، وآخر عمود يأخذ الباقي، مع كاش مفتاحه العرض + الأوزان |
| أرقام LTR | `textDirection: ltr` في الخانات الرقمية فالسالب يبقى في أوله |
| محاذاة | `_alignOf`: النص من أول السطر، والرقم من طرفه، ورأس العمود الرقمي في الوسط |

### حقول الإحصاءات

- `ReportStatFields.defaultIds` = **السابق · وارد · منصرف · الصافي · الرصيد الحالي**.
- `_statIds` في `store_reports_screen` تبدأ بهذه القائمة لا بـ`null` (وكان `null` يعني «كل الحقول»
  فتفتح الشريط على تسعة أرقام).
- البقية (السطور · قيمة الوارد · قيمة المنصرف · قيمة الرصيد) تبقى متاحة في «تخصيص» وغير ظاهرة حتى
  تُختار — والاختيار يسري على الشاشة والمطبوع لأن الـ PDF يستقبل `_statIds` نفسها.
- كشف حركة صنف واحد (`item_movement_screen`) لم يُمسّ: حقوله الخمسة كلها معنى في كشفٍ لا رصيد سابق
  له ولا رصيد جالٍ.

### ملاحظة على الاختبار

خط الاختبار في `flutter_test` مربّع (عرض الحرف 1em)، فقياس «هل ضغط التصغير العنوان؟» لا يعكس خط
Cairo في التطبيق؛ لذلك يحرس الاختبار **الثوابت** لا الرقم: سطر واحد لكل خلية، وارتفاع خلية واحد في
الكتل الأربع، ومسار عمود واحد بين الرأس والمجاميع، والسالب LTR.

### النتيجة

`flutter analyze` → **No issues found!** · `test/features/stores/` **153 ناجحاً** (4 جديدة) ·
`flutter test` **629 ناجحاً** (~10 متخطّى) · **لا تغيير في قاعدة البيانات**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 05:05 · **لا commit** (لم يُطلب).


---

## 2026-11-09 05:29 — التفصيل: سطر واحد للعميل والدفع وضغط خلايا الأقمشة

### العَرَض

- «بيانات العميل» تنكسر إلى صفين عند ضيق الشاشة (سطر للهاتف/رقم العميل وآخر لرقم الحساب).
- «تفاصيل الدفع» تتجاوز حدودها عند كبر حجم الخط أو المساحة، وبعض العناوين تختفي.
- بطاقة القماش فيها فراغ ميّت أسفل الخلايا (خلايا قصيرة مجاورة لخلايا طويلة) وارتفاع زائد.

### الإصلاح

- `tailoring_cells.dart`: `TailoringCell` صار يدعم `compact` (تسمية سطر واحد عبر `FittedBox`،
  حشو 3/2، قيمة 12، مسافة 1)، فاختلف ارتفاع الخلايا عن بعضها واختفى التمدد الفارغ.
- `bill_customer_card.dart` و`bill_payment_card.dart`: استُبدلتا `TailoringCellGrid(rows: 1)`
  بدل `TailoringInfoGrid` بحساب الأعمدة بالعرض — الآن الأعمدة تساوي عدد الحقول دائماً.
- `tailoring_section_card.dart`: العنوان داخل `FittedBox`، والذيل بسقف 168 مع `FittedBox`
  فلا تجاوز عند تكبير الخط.
- `model_fabrics_table.dart`: كل خلايا القماش `compact: true`، حشو خارجي صفر، فاصل 4 بين
  البطاقات.

### الاختبار

اختبار جديد بمقياس خط 1.6× على 360: يثبت بقاء العميل والدفع في سطر واحد وانعدام أي تجاوز.
النتيجة: 57 اختبار تفصيل · `flutter analyze lib` نظيف.

**النموذج:** Qoder · **الوقت:** 2026-11-09 05:29 · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:10 — التفصيل: صفوف جدولية بارتفاع المحتوى بدل صفوف ممدودة

- `tailoring_cells.dart`:
  - `TailoringCellRow` صار `Table` بصف واحد وأوزان `FlexColumnWidth` وحدود رأسية — لا
    `IntrinsicHeight` ولا `stretch`.
  - `TailoringCellGrid` صار `Table` واحداً لكل الشبكة بحدود كاملة (`TableBorder.all`
    مع `borderRadius`)، وصفوفه تُبنى من الخلايا مباشرة.
  - `TailoringCell`: القيمة داخل `Align(heightFactor: 1)` فلا تتمدد رأسياً.
- `model_fabrics_table.dart`: خانة «العرض» تُعرض من `clothWidth` وإلا `clothType` — استعادة
  المعلومة بدل الشرطة عند غياب عمود العرض في القاعدة.
- الاختبارات: `payment and fabric rows hug their content height` يقيس ارتفاعات الصفوف فعلياً.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:10 · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:31 — الموديلات والأقمشة: أعمدة لا تُقصّ، اسم العميل بديلاً، ولون/سعر صحيحان

### الخادم

- `detailSql`: `NVL(v.SANFPRICE, v.SANF_PRICE) AS SANF_PRICE` — القيمة الحقيقية في
  `SANFPRICE` (قياس حيّ: `sanf_price=0` و`sanfprice=10000` لنفس القماش).

### العميل

- `model_selector_strip.dart` — إعادة بناء كاملة على `Table`: رأس واحد، أوزان صريحة، وكل
  خلية `FittedBox` سطر واحد (لا قصّ)، والاختيار بفهرس الصف، وخيار `customerName` يعرض اسم
  العميل عند غياب المستفيد.
- `cutting_bill_view_screen.dart` — يمرّر `detail.header.custName` إلى الشريط.
- `model_fabrics_table.dart` — اللون `colorText ?? colorNo`، والسعر صفر يُعرض «—».
- الاختبارات: `a model with no beneficiary shows the customer name`.

### حقائق قاعدة البيانات (قياس حيّ)

- `CLOTHS_COLOR = "2"` و`CLOTHS_COLOR2 = NULL` ⇒ اللون يُقرأ رقماً.
- `SANF_PRICE = 0` و`SANFPRICE = 10000` ⇒ الأول ليس السعر المعروض.
- `SALES_DETAILES_SHAPES.NOTES2` هو عمود الملاحظة الوحيد، وبعض الصفوف `NULL` فعلاً.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:31 · **لا commit** (لم يُطلب).


---

## 2026-11-09 06:54 — التفصيل: صح على الموديل المحدد وملاحظة الموديل من العرض

### قاعدة البيانات

- استُخرج تعريف العرض من `DBMS_METADATA.GET_DDL` (4,488 حرفاً)، وأُضيف عمود واحد في نهايته:
  في قائمة SELECT: `sales_detailes_shapes.notes2`، وفي قائمة الأعمدة: `"MODEL_NOTES"`.
- نُفِّذ `CREATE OR REPLACE FORCE VIEW "ACCOUNTS"."CUTTING_SALES_BILL_VIEW" (...) AS SELECT ...`
  — الإضافة في النهاية تحفظ ترتيب الأعمدة القديم فلا تتأثر `CustomerMeasurementController`
  ولا بقية الاستعلامات.
- التحقق بعد الإنشاء: `HAS_MODEL_NOTES=YES`، إجمالي الصفوف 45,490، وعيّنة
  `(6, 2026, 60373)` تعيد نصّ ملاحظة حقيقياً.

### الخادم

- `TailoringController::detailSql`: `s.PEN_POCKET, s.HEGAZI_TYPE, v.MODEL_NOTES AS NOTES2` —
  الملاحظة تُقرأ من الـ VIEW وليس من الجدول مباشرةً (الجدول ما زال مصدر بقية المواصفات).

### العميل

- `model_selector_strip.dart`: عمود أول ثابت 24px فيه `check_circle_rounded` أخضر للسطر
  المحدد، ورأس الجدول يعرض خلية فارغة فوقه؛ أوزان الأعمدة أُزيحت بمقدار عمود واحد.

### التحقق

Pest `Tailoring` 11/187 · Flutter 59 · analyze نظيف · pint PASS.

**النموذج:** Qoder · **الوقت:** 2026-11-09 06:54 · **DDL:** إضافة عمود `MODEL_NOTES` للعرض · **لا commit**.


---

## 2026-11-09 07:20 — التفصيل: طلب واحد للقائمة وملاحظة تعود للفاتورة عند غيابها

### خطأ البداية (تحليل وإصلاح)

- `CuttingBillsListNotifier.build()` كان ينفّذ `Future.microtask(load)`، و`initState` في الشاشة
  ينفّذ `load()`/`refresh()` أيضاً ⇒ طلبان، والثاني يلغي الأول عبر `_cancelToken.cancel()`،
  فيُلتقط خطأ عابر قبل أن يعيد الطلب الناجح القائمة.
- الإصلاح:
  - حُذف الإطلاق من `build()`؛ الشاشة وحدها تطلب التحميل الأول.
  - عند فشل بصمة الطلب (تجاوزه أحدث) يُطفأ `isLoading/isLoadingMore` فلا تعلق الشاشة.
  - `_buildContent`: الخطأ يُعرض فقط إذا كانت `state.items.isEmpty`، فلا يغطي قائمة ظاهرة.

### عمود الملاحظة

- إثبات حيّ أن الخادم يعيدها من الـ VIEW:
  `app(TailoringController::class)->show(6, 2026)` ⇒ `specs.notes` بطول 17 حرفاً.
- الفاتورة التي اشتكى منها المستخدم (21464) تحمل `NOTES2 = NULL` لموديلاتها، وفيها ملاحظة
  فاتورة في `SALES_BILL.DETAILES`؛ فأُضيف `billNote` إلى `ModelSelectorStrip` كبديل للعمود —
  وهو نفس سلوك شاشة النظام القديم.

**النموذج:** Qoder · **الوقت:** 2026-11-09 07:20 · **لا commit** (لم يُطلب).


---

## 2026-11-09 08:08 — التفصيل: إزالة بديل ملاحظة الفاتورة وإصلاح ORDSNAME الذي يُسقط القائمة

### الواجهة

- `ModelSelectorStrip`: حُذف `billNote` وبديله؛ خلية «الملاحظة» تعرض
  `models[i].specs.notes` (أي `MODEL_NOTES` من العرض)، وإن كانت `null` تمرّر نصاً فارغاً
  فتظهر الخلية فارغة تماماً كما طلب المستخدم.
- `cutting_bill_view_screen.dart`: أُزيل تمرير `billNote`.

### الخادم (السبب الحقيقي للخطأ الأحمر في القائمة)

- `storage/logs/laravel.log`: `Undefined array key "ORDSNAME"` في
  `App\Support\CuttingViewReader::orderStateName()` سطر 186، مكرراً في كل طلب فتح قائمة.
  السبب: `OCI8` يعيد أسماء الأعمدة بحروف صغيرة (`ordsname`)، والقراءة كانت `$row['ORDSNAME']`
  فترفع `ErrorException` (لارافيل يحوّل التحذير إلى استثناء) ⇒ 500 ⇒ رسالة
  «تعذّر جلب فواتير التفصيل».
- الإصلاح: `$data['ORDSNAME'] ?? $data['ordsname'] ?? ...` مع إرجاع `null` عند الغياب.
- إثبات: `index()` أعاد `STATUS=200 · SUCCESS=true · TOTAL=13748`.

### تراجع جانبي أُعيد

- `cutting_bill_detail_model.dart`: `balanceLabel` فقد فرع `remaining < 0` («رصيد مقدم»)،
  فأُعيد ليطابق الاختبار والسلوك المعتمد.

**النموذج:** Qoder · **الوقت:** 2026-11-09 08:08 · **لا commit** (لم يُطلب).


---

## 2026-11-09 09:11 — التفصيل: قراءة المواصفات من عشّان الخادم لا من جذر الموديل

### السبب (عميل لا خادم)

- الإثبات الحيّ: `_probe` لـ `bill 21514 / seq 85226` — الـ VIEW يعيد `MODEL_NOTES` بطول 28،
  والمتحكم يعيد `models[85226].specs.notes` بطول 28. إذن الخادم سليم.
- العطب: `CuttingModelItem.fromJson` كان يستدعي `CuttingModelSpecs.fromJson(json)` حيث `json`
  هو **جذر الموديل**، بينما البنية الحقيقية تضع `notes` و`neck_type` تحت `json['specs']`
  (انظر `TailoringController::groupModels` السطر `'specs' => $this->specs($row)`).
- لماذا لم يكشفه الاختبار؟ لأن الـ fixture كان يكتب المواصفات مسطّحة في الجذر، فتطابق parser
  مع fixture لا مع الخادم.

### الإصلاح

- `cutting_model_item.dart`: `specs: CuttingModelSpecs.fromJson(json['specs'] is Map ?
  Map<String,dynamic>.from(json['specs']) : json)` — يعشّن من `specs` ويرجع للجذر توافقاً.
- اختبار جديد `specs are read from the nested server map, not the model root`.

### قرار المستخدم (اختبارات الدفع)

- أبقى المستخدم نموذجه بلا فرع «رصيد مقدم» وبلا جمع `othersPayments` في `paidTotal`؛
  فحُدِّث اختبارا الدفع: الرصيد السالب ⇒ `balanceLabel` «المتبقي» و`isAdvance` صحيح،
  و`paidTotal` = المدفوع فقط.

### التحقق

Flutter **60** ناجحة · `flutter analyze lib` = **No issues found!**.

**النموذج:** Qoder · **الوقت:** 2026-11-09 09:11 · **لا commit** (لم يُطلب).


---

## 2026-11-09 10:06 — التفصيل: الصافي والمتبقي يُحسبان ولا يُقرآن من عمود NET

### العلة

- `paymentPayload` كان: `net = NET` و`remaining = NET - AMOUNT_PAID`.
- التحليل الحيّ على 1,200 فاتورة: `NET == TOTAL` في 1192، و`NET < TOTAL` في 4 فقط، أي أن NET
  نسخة من الإجمالي الخام ولا يتتبّع الدفع. لذا كان الصافي يتجاهل الخصم، والمتبقي يتجاهل الخصم
  والمدفوعات الأخرى ⇒ قيم خاطئة.

### المعادلة المستنتجة (مُتحقَّق منها على كل عيّنة)

- الصافي = TOTAL − DISCOUNT
- المتبقي = الصافي − AMOUNT_PAID − OTHERS_PAYMENTS  (تُطرح القناتان ليصفرّ عند السداد)

### ما تغيّر

- `TailoringController::paymentPayload`: حساب `net` و`remaining` بالمعادلة، مع الحفاظ على دلالة
  null (إن غاب الإجمالي والخصم ⇒ الصافي null).
- `bill_payment_card.dart`: خلية «مدفوعات أخرى» مشروطة، وشرح المعادلة بتعليقات.
- `TailoringTest.php`: اختبار متساويتين على أول فاتورة في القائمة.

### التحقق

Pest 12/189 · Flutter 60 · analyze نظيف · pint PASS.

**النموذج:** Qoder · **الوقت:** 2026-11-09 10:06 · **لا commit** (لم يُطلب).
