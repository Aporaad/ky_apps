/// ثوابت شاشة «معلومات البرنامج والدعم» — مصدر واحد لكل قيمة تُعرض فيها
/// Constants for the app-info & support screen — one source for every value it shows.
///
/// لماذا ملف مستقل؟ لأن رقم الإصدار واسم المطور ورقمه كانت ستُنسخ في أربعة مواضع (شاشة الدخول،
/// شاشة المعلومات، إعدادات الموظف، ولوحة الإدارة) فتتباعد عند أول تحديث. كل قارئ يستورد هذا
/// الملف، وتحديث الإصدار يقع هنا وفي `pubspec.yaml` معاً ولا شيء غيرهما.
/// Why a dedicated file? The version, the developer's name and phone would otherwise be copied
/// into four places (login, app-info, employee settings, management) and drift at the first
/// update. Every reader imports this file; bumping the version means touching this file and
/// `pubspec.yaml`, nothing else.
library;

/// نسخة التطبيق الظاهرة للمستخدم — يجب أن تطابق `version:` في `pubspec.yaml`
/// The user-facing app version — MUST match `version:` in `pubspec.yaml`.
const String kAppVersion = '1.1.0';

/// رقم البناء الظاهر بجانب النسخة — يجب أن يطابق الجزء الثاني بعد `+` في `pubspec.yaml`
/// The build number shown beside the version — MUST match the part after `+` in `pubspec.yaml`.
const String kAppBuildNumber = '2';

/// فاصل الحقوق/النسخة المشترك: `1.1.0 (2)`
/// The shared version badge: `1.1.0 (2)`.
const String kAppVersionBadge = '$kAppVersion ($kAppBuildNumber)';

/// اسم المطور كما يظهر في قسم «معلومات المطور» — وهو هدف النقر الخفي لفتح إعدادات الـ API
/// The developer's name in the "developer info" section — also the hidden tap target that
/// unlocks the API settings.
const String kDeveloperName = 'المهندس ارسلان الشماري';

/// رقم المطور بالصيغة الدولية بلا `+` (يفتح به `tel:` و`wa.me`)
/// The developer's number in international form without `+` (used by `tel:` and `wa.me`).
const String kDeveloperPhone = '967776422777';

/// الرقم بالصيغة المعروضة داخل الواجهة
/// The number in its displayed form inside the UI.
const String kDeveloperPhoneDisplay = '+967 776 422 777';

/// رابط محادثة واتساب المباشرة مع المطور
/// The direct WhatsApp chat URL with the developer.
const String kDeveloperWhatsappUrl = 'https://wa.me/967776422777';
