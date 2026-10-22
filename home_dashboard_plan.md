# خطة تطوير الواجهة الرئيسية — لوحة الاختصارات القابلة للتخصيص

**المشروع:** ky_apps — بوابة الموظف (Flutter / Riverpod 3 / RTL)
**تاريخ الخطة:** 2026-10-22
**الحالة:** خطة للاعتماد — **لم يُنفَّذ أي كود**، ولم يُعدَّل أي ملف من `lib/` أو `test/`.
**النطاق:** العميل فقط. لا تغيير في `kyApp_API/` ولا في مخطط Oracle في هذه الخطة.

---

## 0. الملخص التنفيذي

الواجهة الرئيسية اليوم **ملف من 19 سطراً** يعيد `PortalSectionScaffold` بحالة فارغة ونصّ وعد
(«سيتم هنا عرض ملخص المبيعات…») — بلا بيانات، وبلا زر، وبلا أي طريق للوصول إلى بقية الأقسام
إلا القائمة الجانبية. في المقابل، التطبيق يملك **26 وجهة عاملة** (وثلالة أقسام قيد التطوير)
موزّعة على خمسة أقسام (العملاء، العاملون، الحسابات، الإدارة، الإعدادات) لا يعرف المستخدم بوجود
معظمها، لأنها مدفونة داخل لوحات داخلية.

هذه الخطة تحوّل «الرئيسية» إلى **مركز تنقّل**: شبكة بطاقات **مربّعة** متجاوبة، كل بطاقة تفتح
قسمًا أو شاشة أو تدفّقًا كاملًا (منتقي ← شاشة)، مع **تخصيص كامل** لما يظهر وبأي ترتيب، محفوظ
محليًا لكل مستخدم، ومفلتر دائمًا بصلاحيات IBAC الحالية.

| البند | القيمة |
|---|---|
| اختصارات في الكتالوج | **30** (26 وجهة عاملة + 3 أقسام قيد التطوير + بطاقة التخصيص) |
| تظهر افتراضيًا | 13 + البطاقة الدائمة = **14 بطاقة** |
| ملفات جديدة | 16 (14 في `features/home` + قناة الأقسام + ثوابت العناوين) |
| ملفات معدّلة | 4 |
| اختبارات جديدة | 3 ملفات + توسيع `responsive_layout_test.dart` |
| تبعيات جديدة | **صفر** (لا `shared_preferences`، لا حزمة إعادة ترتيب شبكة) |
| مسارات GoRouter جديدة | **صفر** |
| تغيير الخلفية | **صفر** |
| التقدير | 9 أيام عمل (8.5 تنفيذ + 0.5 احتياطي اختبار يدوي) على 8 مراحل |

---

## 1. ما تحقّقت منه فعليًا (قراءة كود، لا افتراض)

| # | الحقيقة | الدليل |
|---|---|---|
| 1 | الرئيسية حالة فارغة بلا بيانات | `home_dashboard_section.dart` — 19 سطرًا، `PortalSectionScaffold` وحده |
| 2 | المبيعات/التفصيل/المخازن حالات فارغة أيضًا، وأزرار «إضافة/تحديث» فيها `() {}` | `sales_section.dart:10`، `tailoring_section.dart:10`، `stores_section.dart:10`، `data_list_scaffold.dart:128,241` |
| 3 | لا توجد قناة للتنقّل بين الأقسام: `_currentSectionId` حالة محلية تُغيَّر من الدرج/الشريط فقط | `employee_main_layout.dart:29,119,240` |
| 4 | `IndexedStack` يبني الأقسام كلها، في موضعين (جوال/سطح مكتب) | `employee_main_layout.dart:221,354` |
| 5 | سجل الأقسام هو المصدر الوحيد (id/title/icon/viewCodes/الشريط السفلي) | `portal_sections.dart:66–146,164` |
| 6 | لا يوجد أي كود تفضيلات أو تخصيص أو اختصارات في المشروع | بحث `preferences\|تفضيل\|تخصيص\|customiz\|shortcut` → 7 مواضع كلها تعليقات |
| 7 | التخزين المحلي واجهة واحدة: 12 مفتاحًا مسمّى، بلا واجهة JSON عامة | `secure_storage_service.dart:19–35,215–267` |
| 8 | `shared_preferences` غير موجودة أصلًا | `pubspec.yaml:30–54` |
| 9 | `path_provider` بلا تنفيذ ويب، فلا يصلح لتفضيلات (هدف `-d chrome` موثّق) | `pubspec.lock` (لا `path_provider_web`) |
| 10 | القراءة الدفاعية هي النمط: نص تالف ⇒ قيمة افتراضية، لا استثناء | `secure_storage_service.dart:112–130` |
| 11 | نمط الحالة: `Notifier` + `build()` بلا `await` + `Future.microtask` | `auth_notifier.dart:175–190`، `app_config_notifier.dart:87–95` |
| 12 | البطاقات في الإدارة تُبنى من قائمة واحدة، كل بطاقة داخل `PermissionGate` | `management_dashboard_screen.dart:111–127` |
| 13 | لوحات العملاء/العاملين/الحسابات **بلا** بوابات داخلية، الحجب على القسم فقط | `customers_dashboard_screen.dart`، `workers_dashboard_screen.dart:152–190`، `accounts_dashboard_screen.dart` |
| 14 | `SecuritySettingsScreen` اسم مكرّر بين `features/admin` و`features/settings` | مسارَان مختلفان، محتوى مختلف |
| 15 | الشاشات تُدفع أمرِيًّا، والمسارات الخمسة في GoRouter لا تحمل شاشات الميزات | `app_router.dart`، `settings_section.dart:227–231` |

**ملاحظة من الفحص (خارج النطاق، تُسجَّل ولا تُصلَح هنا):** بطاقات لوحة العاملين الثلاث غير محجوبة،
فحامل `cutters.view` وحده يرى بطاقتي «الموظفين» و«الخياطين» ويستطيع فتحهما (الخادم يردّ 403،
فالمشكلة عرضية لا أمنية). تُعالج في تذكرة مستقلة، لأن خلطها بهذه الخطة يوسّع diff المراجعة.

---

## 2. القرارات المعتمدة

| # | القرار | البديل المرفوض | السبب |
|---|---|---|---|
| **D1** | الرئيسية تنتمي إلى `employee_portal` وظيفيًا، لكن ملفاتها في مجلد جديد `lib/features/home/` | إبقاء 14 ملفًا داخل `employee_portal` | الهيكل يبقى «قشرة تنقّل»؛ والرئيسية ميزة كاملة (نموذج + مزوّد + شاشة تخصيص). وهو نمط feature-first المعلن في `AGENTS.md §2` |
| **D2** | **لا تبعيات جديدة.** التخزين في `SecureStorageService` بمفتاح جديد | `shared_preferences` / ملف JSON عبر `path_provider` | الأولى تبعية تحتاج موافقة؛ والثانية بلا تنفيذ ويب (حقيقة #9). التخزين الآمن يعمل على Android/iOS/Windows/Web |
| **D3** | نموذج الحفظ **opt-out**: `order` + `hidden`، لا قائمة بيضاء كاملة | حفظ قائمة المعروض وحده | القائمة الكاملة تُجمّد المستخدم على كتالوج اليوم: أي اختصار جديد في إصدار قادم لن يظهر له أبدًا. `hidden` يجعل الجديد يظهر افتراضيًا |
| **D4** | عناوين الأقسام التسعة تُستخرج إلى ثوابت في `portal_section_titles.dart` ويستهلكها السجل والرئيسية معًا | نسخ العناوين داخل كتالوج الرئيسية | «لا عنوان قسم خارج السجل» قاعدة قائمة؛ النسخ يُنتج انحرافًا صامتًا عند أول إعادة تسمية |
| **D5** | كتالوج الرئيسية **لا يستورد** `portal_sections.dart`؛ التطابق يُثبَّت باختبار | استيراد السجل للتحقق من الأكواد وقت التشغيل | يمنع دورة استيراد `portal_sections → home_section → home_screen → portal_sections` |
| **D6** | لا اختصار مباشر لعملية **حذف** (عميل/مستخدم) | بطاقة «حذف عميل» | بطاقة على الصفحة الأولى لعملية لا رجعة فيها = حادث ينتظر وقتًا. الحذف يبقى داخل لوحة القسم |
| **D7** | بطاقة التخصيص **دائمة** ولا تُخفى، وهدفها شاشة التخصيص | إخفاؤها كبقية البطاقات | مخرج الطوارئ من تخصيص خاطئ. وهي أيضًا تضمن ألّا تكون الصفحة فارغة تمامًا |
| **D8** | فتح قسم من الرئيسية عبر `InheritedWidget` (`PortalSectionScope`) | نقل `_currentSectionId` إلى مزوّد Riverpod | تغيير 8 أسطر مقابل إعادة هيكلة حالة القشرة. القناة صريحة، وقابلة للاختبار بمزوّد وهمي |
| **D9** | التخصيص في شاشة كاملة (مدفوعة) بـ `ReorderableListView` | سحب وإفلات داخل الشبكة | سحب الشبكة يحتاج حزمة أو ~250 سطرًا من `Draggable/DragTarget` وحسابات موضع هشّة. `ReorderableListView` أصلي ومُختبَر ومتوافق مع قارئ الشاشة |
| **D10** | شبكة مربّعة بصيغة `childAspectRatio: 1` + عدد أعمدة محسوب بحدّ أدنى 150dp | نسب ثابتة كما في اللوحات الحالية (1.65 / 2.4) | «مربّعة» طلب صريح؛ والحدّ 150 يضمن احتمال عنوان من سطرين عند أقصى تكبير خط (1.25) |
| **D11** | ألوان الأقسام من `AppColors` الدلالية القائمة فقط | ألوان hex جديدة داخل الودجت | قاعدة المشروع: لا لون صلب في ودجت. الموجود يكفي (primary/accent/info/warning/success/secondary/primaryDark) |
| **D12** | الفلترة بالصلاحيات **وقت العرض** فقط، ولا تُخزَّن أبدًا | تخزين ما رآه المستخدم | المنح تتغيّر أثناء الجلسة (`permissionsNotifier` يحدّثها)، والمخزَّن قرارٌ يقدم فيصير خطأً |

---

## 3. المعمارية والملفات

### 3.1 شجرة الملفات الجديدة

```
lib/features/home/
├── data/
│   ├── models/
│   │   └── home_layout.dart              ← نموذج التفضيل (v1, user_id, order, hidden) + resolve()
│   └── repositories/
│       └── home_layout_repository.dart   ← يلفّ التخزين فقط، بلا Dio
├── domain/
│   ├── home_shortcut.dart                ← وصف البطاقة + الهدف (sealed)
│   ├── home_shortcut_catalog.dart        ← الـ30 اختصارًا، const، بلا استيراد للسجل
│   └── home_shortcut_flows.dart          ← الدوال العليا للتدفّقات (منتقي ← شاشة)
└── presentation/
    ├── providers/
    │   └── home_layout_notifier.dart     ← State + Notifier + Provider للمستودع
    ├── screens/
    │   ├── home_dashboard_screen.dart    ← التجميع: ترويسة + فلاتر + شبكة + حالات
    │   └── home_customize_screen.dart    ← شاشة التخصيص (قائمتان + بحث + استعادة)
    └── widgets/
        ├── home_tokens.dart             ← المسافات والأنصاف والظلال (مصدر واحد)
        ├── home_header.dart             ← تحية + تاريخ عربي + زر التخصيص
        ├── home_shortcut_card.dart      ← البطاقة المربّعة (+ شارة «قيد التطوير»)
        ├── home_shortcut_grid.dart      ← حساب الأعمدة + الشبكة + ترتيب RTL
        ├── home_module_filter.dart      ← شرائح تصفية الأقسام
        └── home_empty_state.dart        ← حالتان: لا منح / الكل مخفي
```

### 3.2 الملفات المعدّلة (4) وما يُضاف خارج `features/home` (2)

| الملف | التغيير | الحجم |
|---|---|---|
| `lib/core/storage/secure_storage_service.dart` | مفتاح `ky_home_layout` + ثلاث دوال مسمّاة | ~18 سطرًا |
| `lib/features/employee_portal/domain/portal_sections.dart` | استخدام الثوابت في `title:` فقط | 9 أسطر |
| `lib/features/employee_portal/presentation/screens/sections/home_dashboard_section.dart` | يصبح محوّلًا سطرًا واحدًا إلى `HomeDashboardScreen` | 19 → 9 أسطر |
| `lib/features/employee_portal/presentation/screens/employee_main_layout.dart` | لفّ `IndexedStack` بالقناة + `_openSection` + إصلاح مؤشر الشريط السفلي | ~20 سطرًا |
| **جديد** `lib/features/employee_portal/domain/portal_section_titles.dart` | 9 ثوابت عنوان (D4) | ~15 سطرًا |
| **جديد** `lib/features/employee_portal/presentation/widgets/portal_section_scope.dart` | قناة التنقّل بين الأقسام (D8) | ~20 سطرًا |

### 3.3 قاعدة الحدود

- `home/domain` و`home/data` **لا تعرف Flutter** إلا في `IconData` (ضرورة عرض).
- `home/presentation` لا تعرف `portal_sections.dart`؛ تعرف `PortalSectionScope` وثوابت العناوين.
- `employee_portal` لا يعرف تفاصيل الرئيسية؛ يعرف محوّلًا واحدًا فقط.
- لا شبكة في الميزة كلها. أي `DioClient` يمرّر إليها = خطأ تصميم.

---

## 4. كتالوج الاختصارات (30)

### 4.1 نموذج البطاقة

```dart
/// اختصار واحد في الرئيسية — ثابت، ويُبنى مرة واحدة في الكتالوج
/// One home shortcut — immutable, declared once in the catalog.
class HomeShortcut {
  const HomeShortcut({
    required this.id,          // 'customers.statement' — ASCII، يُستخدم مفتاحًا للتخزين
    required this.title,       // 'كشف حساب عميل'
    required this.icon,
    required this.sectionId,   // مفتاح القسم في السجل: 'customers' — للتجميع والتصفية فقط
    required this.target,
    this.codes = const [],     // أي كود منها يكفي (canAny)؛ فارغة = بلا شرط
    this.defaultOn = false,    // يدخل التشكيلة الافتراضية؟
    this.underDevelopment = false,
    this.pinned = false,       // لا يُخفى ولا يُرتّب (بطاقة التخصيص)
  });
}
```

`sectionId` **ليس** استيرادًا للسجل: هو مفتاح نصّي يُطابق `PortalSection.id`، ويُثبَّت التطابق
باختبار (§10). العنوان والأيقونة هنا حرّان لأن الاختصار قد يكون شاشة داخلية لا قسمًا.

### 4.2 الهدف — أربعة أنواع فقط

```dart
/// إلى أين تذهب البطاقة — مختوم، فالمُعالج يبقى مطابقًا كاملًا (exhaustive)
/// Where a card leads — sealed, so the handler stays exhaustive.
sealed class HomeShortcutTarget { const HomeShortcutTarget(); }

/// قسم داخل البوابة: يتغيّر `IndexedStack` دون أي دفع شاشة
class SectionTarget extends HomeShortcutTarget {
  const SectionTarget(this.sectionId);
  final String sectionId;
}

/// شاشة تُدفع أمرِيًّا (العُرف القائم في المشروع)
class ScreenTarget extends HomeShortcutTarget {
  const ScreenTarget(this.build);
  final Widget Function() build;   // مرجع بنّاء: ScreenTarget(AllCustomersScreen.new)
}

/// مسار GoRouter قائم — لا مسار جديد
class RouteTarget extends HomeShortcutTarget {
  const RouteTarget(this.location);
  final String location;           // '/api-settings' | '/security-settings' فقط
}

/// تدفّق متعدد الخطوات: منتقي ← شاشة (نفس نمط `_AdminCard.flow`)
class FlowTarget extends HomeShortcutTarget {
  const FlowTarget(this.run);
  final Future<void> Function(BuildContext context) run;
}
```

كل التدفّقات دوال عليا في `home_shortcut_flows.dart` لا كلاشرات، ليبقى الكتالوج `const` — نفس
الحجّة المكتوبة في `portal_sections.dart:184`.

### 4.3 الجدول الكامل

الأكواد من `Perm` حصرًا. «افتراضي» = يدخل التشكيلة الأولى.

| # | المعرّف | العنوان | القسم | الهدف | الكود | افتراضي |
|---|---|---|---|---|---|---|
| 1 | `sales.section` | المبيعات | sales | `SectionTarget('sales')` | `sales.view` | ✖ |
| 2 | `tailoring.section` | التفصيل | tailoring | `SectionTarget('tailoring')` | `tailoring.view` | ✖ |
| 3 | `customers.section` | العملاء | customers | `SectionTarget('customers')` | `customers.view` | ✔ |
| 4 | `customers.list` | كل العملاء | customers | `AllCustomersScreen.new` | `customers.view` | ✔ |
| 5 | `customers.add` | إضافة عميل | customers | `AddCustomerScreen.new` | `customers.create` | ✔ |
| 6 | `customers.statement` | كشف حساب عميل | customers | `FlowTarget(openCustomerStatement)` | `customers.statement` | ✔ |
| 7 | `customers.edit` | تعديل عميل | customers | `FlowTarget(openCustomerEdit)` | `customers.update` | ✖ |
| 8 | `workers.section` | جاري العاملين | workers | `SectionTarget('workers')` | أي من `employees.view`/`cutters.view`/`tailors.view` | ✔ |
| 9 | `workers.employees` | الموظفون | employees | `EmployeesListScreen.new` | `employees.view` | ✔ |
| 10 | `workers.cutters` | القصاصون | cutters | `CuttersListScreen.new` | `cutters.view` | ✖ |
| 11 | `workers.tailors` | الخياطون | tailors | `TailorsListScreen.new` | `tailors.view` | ✖ |
| 12 | `accounts.section` | الحسابات | accounts | `SectionTarget('accounts')` | `accounts.view` | ✔ |
| 13 | `accounts.tree` | دليل الحسابات | accounts | `AccountTreeScreen.new` | `accounts.view` | ✔ |
| 14 | `accounts.statement` | كشف حساب مالي | accounts | `AccountStatementScreen.new` | `accounts.statement` | ✔ |
| 15 | `accounts.group` | ميزان المراجعة | accounts | `AccountGroupStatementScreen.new` | `accounts.statement` | ✔ |
| 16 | `accounts.analysis` | كشف تحليلي | accounts | `AccountStatementDetailScreen.new` | `accounts.statement` | ✖ |
| 17 | `accounts.create` | إضافة حساب | accounts | `CreateAccountScreen.new` | `accounts.create` | ✖ |
| 18 | `accounts.currencies` | العملات وأسعار الصرف | currencies | `CurrencyScreen.new` | `currencies.view` | ✖ |
| 19 | `stores.section` | المخازن | stores | `SectionTarget('stores')` | `stores.view` | ✖ |
| 20 | `management.section` | الإدارة | management | `SectionTarget('management')` | `management.view` | ✔ |
| 21 | `management.users` | إدارة المستخدمين | users | `AdminUsersScreen.new` | `users.view` | ✔ |
| 22 | `management.sessions` | الجلسات النشطة | sessions | `ActiveSessionsScreen.new` | `sessions.view` | ✖ |
| 23 | `management.security` | إعدادات الأمان | settings | `AdminSecuritySettingsScreen.new` | `settings.view` | ✖ |
| 24 | `management.catalog` | كتالوج الصلاحيات | users | `PermissionsCatalogScreen.new` | `users.view` | ✖ |
| 25 | `management.activity` | سجل النشاط | users | `FlowTarget(openUserActivity)` | `users.activity_view` | ✖ |
| 26 | `settings.section` | الإعدادات | settings | `SectionTarget('settings')` | — | ✔ |
| 27 | `settings.api` | إعدادات الاتصال | app_config | `RouteTarget('/api-settings')` | `app_config.api_manage` | ✖ |
| 28 | `settings.biometric` | الأمان والبصمة | settings | `RouteTarget('/security-settings')` | — | ✖ |
| 29 | `settings.appconfig` | تهيئة التطبيق | app_config | `AppConfigScreen.new` | `app_config.update` | ✖ |
| 30 | `home.customize` | تخصيص الاختصارات | home | `HomeCustomizeScreen.new` | — | دائمًا (`pinned`) |

**ملاحظات تنفيذية على الجدول:**

- **1، 2، 19** تُرسم بشارة «قيد التطوير» لأن أقسامها حالات فارغة اليوم؛ البطاقة صادقة وتفتح القسم.
  لا نُخفيها: المستخدم يجب أن يعرف أن القسم موجود ومخطط، لا أن يظنه محذوفًا.
- **23** يستورد `security_settings_screen.dart` من `features/admin` باسم مستعار (`as admin`) لتفادي
  التصادم مع نسخة `features/settings` (الحقيقة #14).
- **25** تدفّق: `UserPickerScreen` ثم `UserActivityScreen` — نفس منطق `management_dashboard_screen.dart:180`.
- **6** تدفّق: `CustomerPickerScreen` ثم `CustomerStatementScreen(custNo:, custName:, accNo:)`.
- **7** تدفّق: منتقي ثم `EditCustomerScreen(customer: picked)`.
- **14** يعمل مباشرة بلا معاملات: بلا `initialAccNo` يفتح منتقي حساب داخليًا — مقبول كبطاقة.
- **`CustomerStatementPickerScreen`** (شاشة ميتة، لا مرجع لها) **لا تُستخدم** هنا.

### 4.4 التشكيلة الافتراضية

`defaultOn: true` × 13 + البطاقة الدائمة = **14 بطاقة** عند مدير النظام، وتنقص تلقائيًا بنقص المنح:

```
العملاء · كل العملاء · إضافة عميل · كشف حساب عميل
جاري العاملين · الموظفون
الحسابات · دليل الحسابات · كشف حساب مالي · ميزان المراجعة
الإدارة · إدارة المستخدمين · الإعدادات · تخصيص الاختصارات
```

على شاشة 360dp (عمودان) = 7 صفوف ≈ 1150px تمرير — مقبول لصفحة مركزية.
المستخدم يستطيع تقليصها إلى 4 بطاقات في دقيقة.

---

## 5. التصميم البصري

### 5.1 المخطط السلكي

**جوال (360×640) — عمودان:**

```
┌──────────────────────────────────────────────┐
│  صباح الخير، خالد                    ⚙   ⌕   │  ← تحية + تاريخ + تخصيص
│  الخميس 22 أكتوبر 2026 · فرع 2               │
│                                              │
│  [الكل] [العملاء] [العاملون] [الحسابات] ←    │  ← شرائح تصفية (تمرير أفقي)
│                                              │
│  ┌───────────────┐  ┌───────────────┐        │
│  │  ╭───╮        │  │  ╭───╮        │        │
│  │  │👥 │        │  │  │🧾 │        │        │
│  │  ╰───╯        │  │  ╰───╯        │        │
│  │  العملاء      │  │  كشف حساب     │        │
│  │  العملاء      │  │  العملاء      │        │
│  └───────────────┘  └───────────────┘        │
│  ┌───────────────┐  ┌───────────────┐        │
│  │  ╭───╮        │  │  ╭───╮        │        │
│  │  │➕ │        │  │  │💰 │        │        │
│  │  ╰───╯        │  │  ╰───╯        │        │
│  │  إضافة عميل   │  │  الحسابات     │        │
│  └───────────────┘  └───────────────┘        │
└──────────────────────────────────────────────┘
```

**سطح مكتب (1280) — ستة أعمدة داخل حاوية 1180:**

```
        ┌──────────────────────────────────────────────────────────┐
        │ صباح الخير، خالد                            ⚙  ⌕         │
        │ [الكل] [العملاء] [العاملون] [الحسابات] [الإدارة] [الإعدادات] │
        │ ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐                    │
        │ │ 👥 ││ 🧾 ││ ➕ ││ 💰 ││ 🌳 ││ 📊 │                    │
        │ └────┘└────┘└────┘└────┘└────┘└────┘                    │
        └──────────────────────────────────────────────────────────┘
```

### 5.2 رموز التصميم (مصدر واحد: `home_tokens.dart`)

| الرمز | جوال | تابلت | سطح مكتب |
|---|---|---|---|
| حشو الصفحة الأفقي | 16 | 20 | 24 |
| فراغ الشبكة | 12 | 14 | 16 |
| نصف قطر البطاقة | 16 | 16 | 16 |
| نصف قطر شارة الأيقونة | 14 | 14 | 14 |
| حجم الأيقونة | 22 | 22 | 22 |
| صندوق الأيقونة | 44 | 44 | 44 |
| عنوان البطاقة | 13.5 / w700 | 14 | 14 |
| وصف القسم في البطاقة | 10.5 / `textMuted` | 11 | 11 |
| حدّ السطوع | `border` 1px | نفسه | نفسه |
| ظل الراحة | `black 4% · 8px · (0,2)` | | |
| ظل التحويم | `black 8% · 14px · (0,4)` + حدّ `accent 45%` | | |
| حركة الضغط | `AnimatedScale 0.98 · 120ms` | | |
| أقصى عرض للمحتوى | — | 1180 | 1180 |

كل الألوان تُقرأ من `AppColors` (التي تفوّض خمسة حقول إلى `AppPalette` الزمني)، فتتبع الرئيسية
تهيئة الشركة تلقائيًا. خريطة أقسام → لون:

| القسم | اللون |
|---|---|
| الرئيسية / العملاء / الحسابات | `primary` |
| المبيعات / الموظفون / العملاء الجدد | `success` |
| التفصيل / المخازن / تنبيهات | `warning` |
| الإدارة / الجلسات | `info` |
| الإعدادات / العملات | `accent` |
| كتالوج / سجل | `secondary` |
| تخصيص | `primaryDark` |

### 5.3 معادلة الشبكة المربّعة

```dart
/// عدد الأعمدة يضمن ألّا ينزل ضلع البطاقة تحت 150dp — وهو الحد الذي يحتمل عنوانًا من
/// سطرين عند أقصى تكبير خط مسموح في التطبيق (1.25).
/// Columns are chosen so a tile never drops below 150dp, the size that still fits a two-line
/// title at the app's maximum text scale (1.25).
int homeColumns(double width) {
  const minTile = 150.0;
  const gap = 14.0;
  return ((width + gap) / (minTile + gap)).floor().clamp(2, 6);
}
```

| عرض المحتوى | الأعمدة | ضلع البطاقة |
|---|---|---|
| 288 (جهاز 320) | 2 | 137 |
| 328 (جهاز 360) | 2 | 157 |
| 480 | 3 | 146 |
| 700 | 4 | 164 |
| 980 | 6 | 152 |
| 1180 | 6 | 181 |

تحت 150dp تشترك البطاقة في التكيّف: يُخفى سطر القسم، ويصغر الفراغ بين الأيقونة والعنوان
(`LayoutBuilder` داخل البطاقة على `constraints.maxHeight`).

### 5.4 تشريح البطاقة

```
┌─────────────────────────────┐
│ ╭──────╮          ‹شارة›    │  صندوق 44×44، نصف قطر 14، تعبئة 12% من لون القسم
│ │ 22px │                    │  الشارة: «قيد التطوير» أو عدّاد — نص 9.5
│ ╰──────╯                    │
│                             │  فراغ مرن (Spacer)
│  كشف حساب                   │  13.5 w700، سطران كحد أقصى، ellipsis
│  عميل                       │
│  العملاء                    │  10.5 textMuted — يُخفى تحت 150dp
└─────────────────────────────┘
```

- السطح: `Material(color: Colors.white)` + `InkWell` + `borderRadius 16`، مع `AnimatedScale` عند الضغط.
- التحويم (سطح مكتب فقط): `MouseRegion` يرفع الظل ويشعل الحدّ بـ `accent`.
- التمرير لا يتجاوز 12% تعبئة للأيقونة، ليبقى التباين فوق 4.5:1 على الأبيض.
- `Semantics(button: true, label: '${title} — ${sectionTitle}')`، و`ExcludeSemantics` حول الأيقونة.
- الأيقونة واللون والنص كلها من الكتالوج، لا شرط داخل البطاقة.

### 5.5 الحالات الخمس

| الحالة | العرض |
|---|---|
| تحميل | هيكل عظمي: 6 مربعات رمادية متحركة (`Shimmer` يدوي بـ `AnimatedOpacity`، لا حزمة) |
| نجاح | الشبكة |
| فلترة بلا نتيجة | «لا اختصارات في هذا القسم» + زر «إظهار الكل» |
| الكل مخفي (الكل − الفلترة) | «أخفيت كل الاختصارات» + «استعادة الافتراضي» + «تخصيص» |
| لا منح (كل الأكواد مرفوضة) | «لم تُمنح اختصارات بعد» + شرح + زر تخصيص. **لا تصل عمليًا** لأن بطاقتي الإعدادات والتخصيص غير محجوبتين — لكن الفرع مكتوب صراحة حتى لا يفاجئنا تغيير مستقبلي |

### 5.6 RTL والخط والوصول

- ترتيب الشبكة والفلاتر يتبع `Directionality` العام (RTL): العمود الأول يمينًا. لا `reverse` يدوي.
- التمرير الأفقي لشرائح الفلترة يبدأ من اليمين (`reverse: true` غير مطلوب في RTL؛ يُختبر بصريًا).
- التاريخ العربي يُنسَّق بدالة خاصة داخل `home_header.dart` (بلا ملف إضافي):
  `الخميس 22 أكتوبر 2026` — **بلا `intl`**، فهي تبعية غير معلنة في `pubspec.yaml`.
- التحية حسب ساعة الجهاز: `<12 صباح الخير`، `<17 مساء الخير`، وإلا `مساء النور`. الاسم من
  `authState.user?.displayName` مع `'الموظف'` بديلًا (نفس ما يفعله `employee_main_layout.dart:78`).
- كل مقاسات النص تمرّ عبر `textScaler.scale(...).clamp(...)` كما في بقية الشاشات.
- هدف اللمس ≥ 48dp محقّق تلقائيًا (البطاقة ≥ 137).

---

## 6. التخصيص

### 6.1 نموذج البيانات

```json
{
  "v": 1,
  "user_id": 7,
  "order": ["customers.statement", "customers.section", "accounts.statement"],
  "shown": ["sales.section"],
  "hidden": ["stores.section", "workers.cutters"]
}
```

- `v` — نسخة المخطط: قراءة نسخة مجهولة ⇒ افتراضي (لا ترحيل صامت).
- `user_id` — **حارس ملكية**: بلوب يخصّ مستخدمًا آخر يُعامَل كغائب (جهاز مشترك في محلّ خياطة).
- `order` — الجزء المرتّب يدويًا فقط، وليس القائمة الكاملة.
- `shown` — بطاقات **غير افتراضية** أظهرها المستخدم بنفسه (opt-in).
- `hidden` — بطاقات أخفاها بنفسه، افتراضية كانت أو لا (opt-out).

> **تعديل عند التنفيذ (مقبول ومُوثَّق):** الخطة الأولى اقترحت `order` + `hidden` فقط، وهي تكفي
> لبطاقات التشكيلة الأولى لكنها تُخفي البطاقات غير الافتراضية إلى الأبد (لا سبيل لإظهارها).
> أُضيف `shown` فصار الحفظ **opt-out للافتراضي وopt-in لغيره**: التشكيلة الأولى تظهر بلا تدخّل،
> والبقية تُضاف من تبويب «المتاحة»، والاختصار الجديد في إصدار قادم يظهر إن كان افتراضيًا وإلا
> ينتظر في «المتاحة» — ولا تُجمَّد قائمة بيضاء أبدًا.
> **Change made during implementation:** the original `order` + `hidden` pair covers first-run cards
> but would hide non-default cards forever with no way back. `shown` was added, making storage
> opt-out for defaults and opt-in for the rest.

### 6.2 دلالة الدمج (جوهر D3)

```
المرشّحون = الكتالوج كامل
  ← ترتيب: [order المعروف] ثم [بقية الكتالوج بترتيبه]
  ← رؤية: pinned دائمًا · الافتراضي ما لم يُخفَ · غير الافتراضي إن كان في shown
  ← حذف: hidden (ما لم تكن pinned)
  ← فلترة الصلاحيات: canAnyCode(codes) — وقت العرض فقط، والبطاقة بلا أكواد تمرّ دائمًا
```

النتيجة: اختصار أُضيف في إصدار قادم يظهر تلقائيًا في ذيل قسمه؛ ومعرّف محذوف من الكتالوج
يُهمَل بلا أثر؛ وترتيب المستخدم يصمد أمام إعادة تسمية العناوين.

```dart
/// ترتيب فعلي = ترتيب المستخدم ثم بقية الكتالوج، بلا المخفي — دالة نقية تُختبر وحدها
/// Effective order = the user's order, then the rest of the catalog, minus hidden entries.
List<HomeShortcut> resolveHomeShortcuts(HomeLayout layout, List<HomeShortcut> catalog) {
  final byId = {for (final s in catalog) s.id: s};
  final ordered = <HomeShortcut>[];
  final seen = <String>{};
  for (final id in layout.order) {
    final spec = byId[id];
    if (spec != null && seen.add(id)) ordered.add(spec);
  }
  for (final spec in catalog) {
    if (seen.add(spec.id)) ordered.add(spec);
  }
  return [
    for (final spec in ordered)
      if (spec.pinned || !layout.hidden.contains(spec.id)) spec,
  ];
}
```

### 6.3 رحلات المستخدم الثلاث

| الرحلة | الخطوات | النتيجة |
|---|---|---|
| **سريعة** (الأكثر استخدامًا) | ضغط مطوّل على بطاقة ← ورقة سفلية: «إخفاء» / «تقديم إلى المقدمة» / «تخصيص…» | تغيير فوري بلا مغادرة الصفحة |
| **كاملة** | زر ⚙ في الترويسة ← شاشة التخصيص ← تبويب «المفعّلة» ← سحب للترتيب أو إخفاء ← رجوع | ترتيب كامل محفوظ |
| **إضافة** | شاشة التخصيص ← تبويب «المتاحة» ← بحث ← إضافة | تظهر البطاقة في ذيل الشبكة (أو أعلى «المفعّلة») |

الحفظ **متفائل**: الحالة تتغيّر فورًا، والكتابة تُسلسَل في خلفية (`Future` متسلسلة) مع
`SnackBar` عند الفشل. لا حجب للواجهة على قرص/تخزين.

### 6.4 شاشة التخصيص — تفصيل

```
AppBar: «تخصيص الاختصارات»                        [استعادة الافتراضي]
┌─────────────────────────────────────────────────────────────┐
│  🔍 ابحث عن اختصار…                                          │
│  [ المفعّلة (13) ]   [ المتاحة (17) ]     ← SegmentedButton   │
├─────────────────────────────────────────────────────────────┤
│  ≡  🧾  كشف حساب عميل            العملاء            [إخفاء]  │
│  ≡  👥  العملاء                  العملاء            [إخفاء]  │
│  ≡  💰  الحسابات                 الحسابات           [إخفاء]  │
└─────────────────────────────────────────────────────────────┘
```

- **المفعّلة:** `ReorderableListView.builder` بمقابض سحب (`Icons.drag_handle`)، و`buildDefaultDragHandles: false`
  مع `ReorderableDragStartListener` صريح — يضمن أن السحب لا يسرق ضغط الصف.
- **المتاحة:** `CustomScrollView` مع ترويسات مجموعات (`sectionId`) وصفوف فيها زر `+`.
- **البحث:** ترشيح محلي في الذاكرة بلا تأخير (لا داعي لـ 300ms؛ تلك للشبكة).
- **استعادة الافتراضي:** حوار تأكيد، ثم `order: []` و`hidden: {}` (لا حذف للمفتاح).
- **البطاقة الدائمة** تظهر في «المفعّلة» بلا مفتاح إخفاء وبلا مقبض سحب (مثبّتة في الذيل).
- **حالة فارغة للمتاحة:** «كل الاختصارات مفعّلة» أو «لا اختصارات متاحة لصلاحياتك».
- الشاشة تُدفع بـ `Navigator.push` — **لا مسار جديد** (`AGENTS.md §4`).

### 6.5 الحالات الحدّية المعالجة

| الحالة | السلوك |
|---|---|
| بلوب تالف/مبتور | افتراضي، بلا استثناء (`catch` كما في `getPermissions`) |
| `user_id` مختلف | افتراضي — لا تخصيص مستخدم آخر |
| مستخدم بلا `user.id` (سباق إقلاع) | افتراضي، ولا كتابة حتى يتوفر المعرّف |
| إخفاء 29 بطاقة | بطاقة التخصيص تبقى + حالة فارغة بشرح |
| منح يُسحب أثناء الجلسة | البطاقة تختفي في البناء التالي (`authNotifierProvider` يُراقَب) |
| منح يُضاف | لا تظهر البطاقة إن كانت في `hidden` — قرار المستخدم محفوظ، ويشرحه تبويب «المتاحة» |
| اختصار جديد في إصدار قادم | يظهر في الذيل تلقائيًا (لا قائمة بيضاء) |
| إعادة تثبيت/جهاز جديد | افتراضي (التفضيل محلي، لا مزامنة خادم — قرار صريح) |

---

## 7. الحالة والتخزين

```dart
// secure_storage_service.dart — مفتاح جديد بجوار مفاتيح app_config
static const String _homeLayoutKey = 'ky_home_layout';

/// حفظ تخطيط الرئيسية كنص JSON — تفضيل مستخدم لا حالة جلسة
/// Persist the home layout as JSON — a user preference, not session state.
Future<void> saveHomeLayout(String json) async {
  await _storage.write(key: _homeLayoutKey, value: json);
}

Future<String?> getHomeLayout() async => _storage.read(key: _homeLayoutKey);

Future<void> deleteHomeLayout() async => _storage.delete(key: _homeLayoutKey);
```

**قرار `clearAll`:** المفتاح **يبقى** بعد تسجيل الخروج (مثل `ky_api_base_url` و`ky_app_config`)،
لأن التفضيل يخصّ المستخدم لا الجلسة، وحارس `user_id` يمنع التسريب. `purgeEverything` يمسحه
تلقائيًا (`deleteAll`). يُكتب التعليل في تعليق أعلى المفتاح، أسوة بتعليل IBAC في `clearAll:86–91`.

```dart
final homeLayoutRepositoryProvider = Provider<HomeLayoutRepository>(
  (ref) => HomeLayoutRepository(storage: ref.watch(secureStorageProvider)),
);

class HomeLayoutNotifier extends Notifier<HomeLayoutState> {
  @override
  HomeLayoutState build() {
    Future.microtask(load);                 // لا await في build — نمط المشروع
    return HomeLayoutState.initial();       // تحميل جارٍ + تخطيط فارغ
  }

  Future<void> load() async { /* يقرأ user_id من authNotifierProvider ثم المستودع */ }
  Future<void> toggle(String id) async { /* إخفاء/إظهار ثم حفظ متفائل */ }
  Future<void> move(int from, int to) async { /* إعادة ترتيب ثم حفظ */ }
  Future<void> reset() async { /* order = []، hidden = {} */ }
}
```

- `HomeLayoutState` ثابت + `copyWith` بخدعة الإغلاق لأي حقل قابل للصفر.
- لا `CancelToken` (لا طلب)، لكن الكتابة تُسلسَل عبر `_writeChain` لتفادي تراكب عمليتين سريعتين.
- القراءة الأولى رخيصة (بضع مئات بايت) وتحدث عند كل دخول لأن `IndexedStack` يبني الرئيسية دائمًا —
  وهذا مقبول ومقصود، ولا يُضاف أي نداء شبكة إلى هذا المسار.

---

## 8. الربط بالهيكل

### 8.1 قناة التنقّل بين الأقسام (D8)

```dart
/// قناة داخلية: تسمح لأي قسم بأن يطلب الانتقال إلى قسم آخر دون أن يعرف الهيكل
/// Internal channel: any section can ask to switch to another one without knowing the shell.
class PortalSectionScope extends InheritedWidget {
  const PortalSectionScope({required this.openSection, required super.child, super.key});

  final void Function(String sectionId) openSection;

  static PortalSectionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalSectionScope>();

  @override
  bool updateShouldNotify(PortalSectionScope old) => old.openSection != openSection;
}
```

في `EmployeeMainLayout`:

```dart
/// الانتقال إلى قسم من داخل قسم آخر (بطاقات الرئيسية) — المعرّف لا الفهرس
/// Switch to a section from inside another (home tiles) — by id, never by index.
void _openSection(String id) {
  if (!mounted) return;
  final auth = ref.read(authNotifierProvider);
  final visible = visiblePortalSections(
    granted: auth.permissions,
    isAdmin: auth.isAdmin,
  );
  // قسم سُحبت صلاحيته أثناء الجلسة: تجاهُل هادئ، لا شاشة لقسم ممنوع
  // A section whose grant was revoked mid-session: ignore quietly, never open a denied one.
  if (!visible.any((section) => section.id == id)) return;
  setState(() => _currentSectionId = id);
}
```

ونلفّ `IndexedStack` في الموضعين (221 و354) بـ `PortalSectionScope(openSection: _openSection, child: …)`.
الدالة `_openSection` مستقرة عبر البناء (method tear-off)، فلا يُعاد بناء الأبناء بسبب تغيّر المرجع.
قسم غير مرئي (سُحبت صلاحيته) يُتجاهَل بهدوء — والبطاقة تكون قد اختفت قبل ذلك أصلًا.

### 8.2 إصلاح مؤشر الشريط السفلي (خلل قائم يظهر فورًا مع الرئيسية)

اليوم، فتح قسم ليس في الشريط (المخازن، الإدارة، جاري العاملين) يجعل `barSelectedIndex = -1`
فيُثبَّت المؤشر على `0` (`employee_main_layout.dart:237`) — أي أن الشريط يقول «الرئيسية» والمحتوى
«المخازن». بعد إضافة الرئيسية يصبح هذا الطريق يوميًا، فيُصلح بثلاثة أسطر:

```dart
// القسم المفتوح قد لا يكون في الشريط (9 في الدرج، 5 في الشريط). الرجوع إلى «الأول» كان
// يقول للمستخدم إنه في «الرئيسية» وهو في «المخازن»؛ نحتفظ بآخر اختيار من الشريط بدلًا من ذلك.
String _lastBarSectionId = '';
```

`selectedIndex` = موضع القسم الحالي إن وُجد، وإلا موضع `_lastBarSectionId`، وإلا صفر.

### 8.3 محوّل القسم

```dart
// home_dashboard_section.dart — 9 أسطر، لا منطق
Widget _buildHome(BuildContext _) => const HomeDashboardScreen();
```

السجل يبقى `const`، ولا يُلمس أي `viewCodes` أو `showInBottomBar`.

---

## 9. المراحل (8 مراحل — 9 أيام)

### مرحلة 0 — تثبيت الأساس (0.5 يوم)
- `flutter pub get` ثم **`flutter analyze` + `flutter test` قبل أي تغيير** لتسجيل خط الأساس.
- إنشاء الفرع، وتثبيت `home_tokens.dart` من §5.2.
- **القبول:** «No issues found!» وكل الاختبارات القائمة خضراء قبل السطر الأول من الميزة، وسجلٌّ
  بنتيجة الخط الأساسي يُلحق في `todo.md` (حتى تُفرَّق أي حالة فشل لاحقة عن حالة سابقة).

### مرحلة 1 — التفضيلات والتخزين (1 يوم)
- مفتاح `ky_home_layout` + الدوال الثلاث.
- `HomeLayout` + `fromJson/toJson/copyWith/resolve` دوال نقية.
- `HomeLayoutRepository` + `HomeLayoutNotifier` + المزوّدان.
- **القبول:** `test/home_layout_test.dart` ينجح: تالف، نسخة مجهولة، مستخدم آخر، ترتيب، إخفاء، إعادة افتراضي.

### مرحلة 2 — الكتالوج والأهداف (1 يوم)
- `home_shortcut.dart` (sealed target) + `home_shortcut_catalog.dart` (30) + `home_shortcut_flows.dart`.
- استخراج عناوين الأقسام (`portal_section_titles.dart`) وتحديث السجل.
- **القبول:** `test/home_catalog_test.dart` ينجح: معرّفات فريدة، كل كود موجود في `allPermissionCodes`،
  كل `SectionTarget` يطابق `viewCodes` للسجل، كل `sectionId` معروف، 13 افتراضيًا + الدائمة.

### مرحلة 3 — قناة الأقسام (0.5 يوم)
- `PortalSectionScope` + لفّ `IndexedStack` في الموضعين + `_openSection` + إصلاح مؤشر الشريط.
- **القبول:** من بطاقة «الحسابات» يتغيّر القسم ويُظلَّل في الدرج والشريط؛ القسم غير المرئي لا يفتح.
  اختبارات القشرة القائمة (`Portal sections follow the grants`) تبقى خضراء.

### مرحلة 4 — البطاقة والشبكة (1.5 يوم)
- `HomeShortcutCard` + `HomeShortcutGrid` + `homeColumns` + حالات التحويم/الضغط/الشارة/الوصف.
- **القبول:** لا تجاوز على 320/360/480/768/1024/1280، وعند `textScale 1.25`.

### مرحلة 5 — الترويسة والفلاتر (1 يوم)
- `HomeHeader` (تحية + تاريخ عربي + زر تخصيص) + `HomeModuleFilter` + الشريط العلوي الملوّن الخفيف.
- **القبول:** التاريخ صحيح عربيًا، والتحية تتغيّر بتوقيت الجهاز، والفلترة تعمل مع الإخفاء والصلاحيات.

### مرحلة 6 — شاشة التخصيص (1.5 يوم)
- `HomeCustomizeScreen`: تبويبان، إعادة ترتيب، إخفاء/إظهار، بحث، استعادة افتراضي، حالة فارغة.
- الورقة السفلية للضغط المطوّل على البطاقة.
- **القبول:** إعادة الترتيب تُحفظ بعد إعادة التشغيل، والاستعادة تُرجع التشكيلة الافتراضية.

### مرحلة 7 — التجميع والتلميع (1 يوم)
- `HomeDashboardScreen` يجمع كل ما سبق، ويستبدل `home_dashboard_section.dart`.
- الحالات الخمس (§5.5) + تلميح أول تشغيل («اضغط مطوّلًا…»، يُخفى بعد أول تخصيص).
- **القبول:** سيناريوهات §10.4 تمرّ يدويًا على جهاز Android حقيقي.

### مرحلة 8 — الاختبار والتوثيق (1 يوم)
- إضافة الحالات إلى `test/responsive_layout_test.dart`، وتشغيل البوابات.
- إلحاق ما تم في `devloping_history.md` و`todo.md` (**إلحاق فقط، بلا حذف أو استبدال**).
- **القبول:** `flutter analyze` نظيف، `flutter test` أخضر، ولا تغيير في `pubspec.yaml`.

---

## 10. الاختبارات

### 10.1 منطق نقي — `test/home_layout_test.dart` (جديد)

- `fromJson` على: `null`، نص، JSON تالف، `v` مجهولة، `user_id` مختلف ⇒ افتراضي بلا استثناء.
- `resolve`: ترتيب مخصص يصمد؛ معرّف مجهول يُهمَل؛ مكرّر لا يتكرّر؛ الجديد يظهر في الذيل.
- `hidden` يشمل البطاقة المثبّتة ⇒ تبقى (D7).
- دورة `toJson → fromJson` تُعيد نفس الشيء.

### 10.2 سلامة الكتالوج — `test/home_catalog_test.dart` (جديد)

- لا معرّف مكرّرًا، وكل المعرّفات ASCII بنمط `module.action`.
- كل `codes` موجودة في `allPermissionCodes` (مرآة الكتالوج).
- كل `SectionTarget.sectionId` موجود في `portalSections`، و**`codes` تطابق `viewCodes` حرفيًا** (يُثبّت D5).
- كل `sectionId` له عنوان في `portal_section_titles.dart`.
- عدد الافتراضي = 13، والبطاقة المثبّتة واحدة.
- كل `ScreenTarget` يُبنى بلا استثناء داخل `ProviderScope` وهمي (اختبار دخان).

### 10.3 ودجت — إضافة إلى `test/responsive_layout_test.dart`

نفس نمط `_pumpAdmin:422` و`pumpLayout:533`:

| الحالة | القياس | التوقّع |
|---|---|---|
| مدير نظام، 30 اختصارًا | 360×640 و1280×800 | `takeException()` = null، وعدد البطاقات = المرئي |
| موظف بـ `customers.view` فقط | 360×640 | بطاقات العملاء + الإعدادات + التخصيص فقط |
| كل الاختصارات مخفية | 360×640 | حالة «أخفيت كل الاختصارات» + زر استعادة |
| `textScale 1.25` | 360×640 | لا تجاوز |
| بطاقة قسم ⇒ `SectionTarget` | 360×640 | القناة الوهمية تستقبل `'accounts'` |

### 10.4 سيناريو القبول اليدوي (جهاز حقيقي)

1. دخول كمدير ← الرئيسية تعرض 14 بطاقة، الترتيب من اليمين، بلا تجاوز.
2. إخفاء «المخازن» والضغط على «الحسابات» ← القسم يتغيّر، والدرج يظلّل «الحسابات».
3. خروج ودخول ← الإخفاء محفوظ.
4. دخول مستخدم ثانٍ على الجهاز ← تشكيلته الافتراضية، لا تخصيص الأول.
5. سحب `accounts.view` من لوحة الإدارة ثم `refreshNow` ← بطاقات الحسابات تختفي فورًا.
6. تكبير خط النظام إلى أقصاه ← لا قصّ ولا تجاوز.
7. `flutter run -d chrome` ← التخزين الآمن يعمل والتخصيص يُحفظ بعد التحديث.
8. تلف متعمّد للبلوب (كتابة نص عشوائي في المفتاح) ← الرئيسية تعمل بالافتراضي.

---

## 11. المخاطر والمصائد

| # | الخطر | المعالجة |
|---|---|---|
| R1 | `PortalSectionScaffold` يضع `content` داخل `Expanded`+`IntrinsicHeight`، وشبكة قابلة للتمرير داخلها تُنتج تجاوزًا | الرئيسية **لا** تستخدم `PortalSectionScaffold`؛ `SingleChildScrollView` واحدة بشبكة `shrinkWrap: true, physics: NeverScrollableScrollPhysics()` |
| R2 | `IndexedStack` يبني الرئيسية دائمًا | لا نداء شبكة في مسار البناء؛ قراءة تخزين واحدة رخيصة |
| R3 | دورة استيراد `portal_sections ↔ home` | D5: الرئيسية لا تستورد السجل؛ التطابق باختبار |
| R4 | `SecuritySettingsScreen` مكرّر الاسم | استيراد باسم مستعار `as admin` |
| R5 | مربّع + عنوان عربي طويل + تكبير 1.25 | حدّ 150dp + سطران + `ellipsis` + إخفاء الوصف تحت 150 |
| R6 | بطاقة لقسم غير مرئي (منح مسحوبة) | الفلترة وقت العرض فقط (D12)، و`_openSection` يتجاهل غير المرئي |
| R7 | كتابة متتابعة سريعة تُفسد الملف | سلسلة `Future` واحدة + حفظ متفائل + `SnackBar` عند الفشل |
| R8 | «إخفاء الكل» يُنتج صفحة ميتة | البطاقة المثبّتة + حالة فارغة بمخرجين |
| R9 | نسخ عناوين الأقسام | D4: ثوابت واحدة |
| R10 | إضافة تبعية سهوًا (`shared_preferences` / reorderable grid) | D2 وD9 مكتوبتان، وأي إضافة تحتاج موافقة صريحة |
| R11 | تعطيل بدل إخفاء | `PermissionGate` يخفي؛ وبطاقات الرئيسية تُفلتر قبل البناء |
| R12 | تعارض مع `textScale` العام في `main.dart` | لا نغيّر `builder`؛ نتعامل مع 1.25 كحالة اختبار |

---

## 12. خارج النطاق (بقرار صريح)

- **مؤشرات KPI الحقيقية** (عدد العملاء/العاملين/الفواتير، ملخص اليوم): تحتاج
  `GET /api/dashboard/summary` في `kyApp_API` + تعديل `BusinessRoutesSealedTest` + منح
  `dashboard.view`. **مرحلة 9 اختيارية (2 يوم)** تُفتح بموافقة منفصلة، وتُبنى كصف بطاقات فوق
  الشبكة، بتحميل مؤجّل (كسول) حتى لا تبطئ دخول البوابة.
- **مزامنة التخصيص بين الأجهزة**: يحتاج جدول تفضيلات لكل مستخدم — لا يوجد اليوم، ولا يُنشأ هنا.
- **الوضع الليلي**: لا وجود له في التطبيق أصلًا (`AGENTS.md §11 C10`)، والرئيسية تتبع الوضع القائم.
- **إصلاح بوابات لوحة العاملين** (الحقيقة #15): تذكرة مستقلة.
- **المبيعات/التفصيل/المخازن**: تبقى حالات فارغة؛ الرئيسية تعرضها بشارة «قيد التطوير» بصدق.

---

## 13. قائمة التحقق النهائية (DoD)

- [ ] `flutter analyze` → **No issues found!**
- [ ] `flutter test` → كل الاختبارات القائمة خضراء + الاختبارات الجديدة (ملفان + حالات الشبكة).
- [ ] لا تغيير في `pubspec.yaml`، ولا مسار جديد في `app_router.dart`، ولا كود صلاحية جديد.
- [ ] كل ملف جديد/معدّل يحمل تعليقًا مزدوجًا عربي/إنجليزي `///`.
- [ ] لا لون صلب في أي ودجت من `features/home` (`AppColors` فقط).
- [ ] `MediaQuery.sizeOf` / `textScalerOf` / `withValues` / `WidgetStateProperty` بلا استثناء.
- [ ] البطاقات مربّعة فعليًا (`childAspectRatio: 1`) على 360 و768 و1280.
- [ ] إخفاء/ترتيب/استعادة تعمل بعد إعادة التشغيل، ولا تتسرّب بين مستخدمَي جهاز واحد.
- [ ] سحب صلاحية أثناء الجلسة يُخفي البطاقة دون إعادة تشغيل.
- [ ] `devloping_history.md` و`todo.md` مُلحَقان (لا حذف).
- [ ] **تحديث مقترح للمالك** (لا يفعله الوكيل): صفّ «home dashboard» في `AGENTS.md §1` ينتقل من
      «Placeholder» إلى «Working»، ويُضاف `features/home` إلى شجرة §2.

---

## 14. ملحق: توزيع العمل

| المرحلة | الملفات | أيام |
|---|---|---|
| 0 | `home_tokens.dart` | 0.5 |
| 1 | `home_layout.dart`, `home_layout_repository.dart`, `home_layout_notifier.dart`, `secure_storage_service.dart`, `home_layout_test.dart` | 1 |
| 2 | `home_shortcut.dart`, `home_shortcut_catalog.dart`, `home_shortcut_flows.dart`, `portal_section_titles.dart`, `portal_sections.dart`, `home_catalog_test.dart` | 1 |
| 3 | `portal_section_scope.dart`, `employee_main_layout.dart` | 0.5 |
| 4 | `home_shortcut_card.dart`, `home_shortcut_grid.dart` | 1.5 |
| 5 | `home_header.dart`, `home_module_filter.dart` | 1 |
| 6 | `home_customize_screen.dart`, ورقة الضغط المطوّل | 1.5 |
| 7 | `home_dashboard_screen.dart`, `home_dashboard_section.dart`, `home_empty_state.dart` | 1 |
| 8 | `responsive_layout_test.dart`, `devloping_history.md`, `todo.md` | 1 |
| **المجموع** | **16 جديدًا + 4 معدّلة + 3 اختبارات** | **9** |

> التقدير 8.5 يوم تنفيذ + 0.5 يوم احتياطي للاختبار اليدوي على جهاز حقيقي، وهو البند الذي لا
> يُختصر في هذا المشروع: مشاكل التجاوز والترميز لا تظهر في الاختبارات.
