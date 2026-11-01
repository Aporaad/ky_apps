# دليل بناء وإصدار iOS وتجربة التطبيق على الآيفون — تطبيق الكبودي (ky_apps)

> **iOS Release & Sideloading Guide** — موثّق بتاريخ 2026-10-31 · Qoder Agent
> هذا الملف هو المرجع الكامل لكل ما يتعلق بإصدار نسخة iOS وتثبيتها على آيفون حقيقي
> **بمسار مجاني بالكامل** (بلا جهاز Mac، وبلا حساب Apple Developer مدفوع).
> اقرأه كاملاً قبل أي إصدار جديد. نظيره لأندرويد: `android_release_guide.md`.

---

## الجزء الأول: الفرق الجوهري بين iOS وأندرويد

### 1.1 ثلاث حقائق تحكم كل شيء

| الحقيقة | الأثر العملي |
|---|---|
| **بناء iOS يتطلب macOS + Xcode** | جهازك Windows 10/11 — لا يمكن أن ينتج IPA إطلاقاً. البناء يجري **سحابياً**. |
| **التوقيع على iOS ليس مفتاحاً تملكه للأبد** | أندرويد: مفتاح `ky_release.jks` يبقى معك 30 سنة. iOS: شهادة تُصدرها Apple لحسابك وتنتهي (**7 أيام** للحساب المجاني، سنة للمدفوع). |
| **التثبيت خارج المتجر يقبل ملفاً بمخطط `Payload/Runner.app`** | ولذلك نُنتج **IPA غير موقّع** سحابياً، ويوقّعه **Sideloadly** محلياً بالحساب المجاني. |

### 1.2 لماذا هذا المسار هو المجاني الوحيد فعلياً

| الخيار | التكلفة | جهاز Mac مطلوب؟ | النتيجة |
|---|---|---|---|
| **Codemagic + Sideloadly** (المعتمد) | **0** | لا | IPA غير موقّع + تثبيت 7 أيام على جهازك |
| Mac محلي/مستعار + Xcode | 0 إن توفّر | **نعم** | أسرع تجربة تطوير، لكن التثبيت يرتبط بذلك الـMac |
| GitHub Actions (macOS runner) | 0 لكن بحدود ضيقة | لا | بديل احتياطي للبناء فقط (§3.3) |
| MacinCloud / MacStadium | مدفوع بالساعة | (سحابي) | لا يحتاجه هذا المسار |
| Apple Developer Program | **99$/سنة** | لا (بدونه لا TestFlight) | تثبيت سنة + TestFlight + توزيع على العاملين |
| Xcode Cloud | يتطلب عضوية مدفوعة | لا | — |

**الخلاصة:** بـ0 ريال تحصل على «تجربة كاملة على آيفونك»، مقابل قيدين مقبولين:
صلاحية **7 أيام**، ولا يمكن تركيب النسخة على هواتف الآخرين (ذلك يبدأ من 99$/سنة).

---

## الجزء الثاني: كيف يعمل التوقيع على iOS (المفردات)

| المصطلح | ما هو في تطبيقنا |
|---|---|
| **Apple ID** | حسابك العادي (نفس حساب iCloud) — يمنحك «Personal Team» مجاناً |
| **Certificate** | شهادة تطوير يصدرها Sideloadly باسمك من Apple، صالحة 7 أيام (مجاني) / سنة (مدفوع) |
| **Provisioning Profile** | ملف يربط: الشهادة + معرّف التطبيق + **UDID** جهازك. يُولَّد تلقائياً عند التثبيت |
| **Bundle ID** | `com.alkaboudy.app` — **نفس معرّف أندرويد**؛ يُسجَّل في حساب Apple أول مرة فقط |
| **UDID** | البصمة الفريدة لجهازك — لا يمكن تثبيت نسخة تطوير على جهاز غير مسجّل |
| **Developer Mode** | مفتاح في إعدادات iOS (16+) لا بد من تفعيله لقبول التطبيقات الجانبية |
| **Unsigned IPA** | الملف الذي ينتجه Codemagic — بلا شهادة، ولا يُثبَّت قبل توقيعه |

### 2.1 حدود الحساب المجاني (تُحفظ في الذاكرة — لا تُنسى)

| الحد | القيمة | الأثر |
|---|---|---|
| صلاحية التثبيت | **7 أيام** | بعدها يتوقف التطبيق عن الفتح حتى إعادة التوقيع |
| عدد التطبيقات الجانبية | **3** كحد أقصى على الجهاز | احذف ما لا تحتاجه قبل التثبيت |
| App IDs جديدة | **10 كل 7 أيام** | إعادة توقيع نفس التطبيق لا تستهلك رصيداً جديداً |
| TestFlight | **غير متاح** | يتطلب عضوية مدفوعة |
| التوزيع على هواتف العاملين | **غير متاح** | كل جهاز يحتاج تسجيله في حساب مدفوع |

### 2.2 لماذا التوقيع الأسبوعي ليس كارثة

إعادة التوقيع **لا تعيد بناء التطبيق ولا تحذف بياناته**: نفس ملف الـIPA يُوقَّع من جديد في
أقل من دقيقة، ويُثبَّت **فوق** القديم بنفس Bundle ID ونفس Apple ID فتبقى الجلسة والشعار
والإعدادات المحفوظة في الجهاز. وبخاصية **Auto-Refresh** في Sideloadly تُؤتمت العملية
عبر الواي فاي طالما بقي حاسوبك يعمل على نفس الشبكة.

---

## الجزء الثالث: خط الأنابيب (Pipeline)

```
┌──────────── Windows (جهازك) ────────────┐        ┌──────── Codemagic (سحابي macOS) ────────┐
│ 1) flutter analyze + flutter test      │        │                                        │
│ 2) git push  ──────────────────────────┼──────> │ 3) flutter pub get → pod install       │
│                                        │        │ 4) flutter build ios --no-codesign     │
│ 8) Sideloadly: توقيع + تثبيت           │ <──────┤ 5) تغليف Payload/ → ky-apps-x.y.z.ipa │
│    (Apple ID مجاني → 7 أيام)           │  IPA   │    + dSYM (لتفسير أي crash)            │
└───────────────┬────────────────────────┘        └────────────────────────────────────────┘
                │ USB / Wi-Fi
        ┌───────▼────────┐
        │  آيفون (Developer Mode)  │
        └────────────────┘
```

لا كلمة سر Apple ولا شهادة تُرفع إلى Codemagic — البناء بلا توقيع من الطرف إلى الطرف.

### 3.1 خريطة الملفات ذات الصلة

```
ky_apps/
├── codemagic.yaml                       ← workflow البناء غير الموقّع (لا أسرار بداخله)
├── tools/ios_icons.py                   ← يولّد أيقونات iOS الـ15 من assets/logo1.png
├── ios/
│   ├── Podfile                          ← محفوظ في git (platform 13.0 + post_install)
│   ├── Flutter/AppFrameworkInfo.plist   ← MinimumOSVersion = 13.0 (يُطابق الهدف)
│   └── Runner/
│       ├── Info.plist                   ← ATS + أذونات الصور/الشبكة المحلية + الاسم العربي
│       ├── DebugProfile.entitlements    ← Keychain Sharing (إلزامي لـ secure storage)
│       ├── Release.entitlements         ← نفسه للإصدار
│       └── Assets.xcassets/AppIcon.appiconset/   ← 15 أيقونة RGB بلا شفافية
└── ios_release_guide.md                 ← هذا الملف
```

### 3.2 ما عُدِّل في المشروع ولماذا (مرجع سريع)

| الملف | التغيير | السبب |
|---|---|---|
| `ios/Runner/Info.plist` | `NSAppTransportSecurity` → `NSAllowsArbitraryLoads` + `NSAllowsLocalNetworking` | الـAPI يُضبط وقت التشغيل وقد يكون `http` على IP محلي، وATS يمنعه **بصمت** فيفشل كل اتصال |
| `ios/Runner/Info.plist` | `NSPhotoLibraryUsageDescription` | زر «اختيار الشعار» (`image_picker`) — بدونها **ينهار التطبيق** لحظة النقر |
| `ios/Runner/Info.plist` | `NSLocalNetworkUsageDescription` | iOS 14+ يسأل قبل الاتصال بعنوان خاص (`192.168.x.x`) |
| `ios/Runner/Info.plist` | `CFBundleDisplayName = الكبودي` | مطابقة `android:label` |
| `ios/Runner/Info.plist` | `CFBundleDevelopmentRegion = ar` · `CFBundleLocalizations = [ar]` · `CFBundleAllowMixedLocalizations` | حوارات النظام (أذونات الصور/الشبكة) وورقة المشاركة تظهر بالعربية؛ والأخير يطلبه `share_plus` |
| `ios/Runner/DebugProfile.entitlements` + `Release.entitlements` | ملفان جديدان: `keychain-access-groups` | **بدونهما لا يعمل `flutter_secure_storage` على iOS** — تُرجع الكتابة نجاحاً ظاهرياً بلا تخزين فعلي، فيُطرد المستخدم لتسجيل الدخول كل مرة ويُلغى التسجيل البيومتري |
| `project.pbxproj` | `CODE_SIGN_ENTITLEMENTS` في Debug/Profile/Release + مرجعا الملفين في الشجرة | ربط الـentitlements بهدف `Runner` |
| `ios/Flutter/AppFrameworkInfo.plist` | `MinimumOSVersion` 12.0 → 13.0 | توحيد الحد الأدنى بين الهدف والـPodfile وإطار `App.framework` |
| `project.pbxproj` | `com.example.kyApps` → `com.alkaboudy.app` (×3) | `com.example.*` معرّف قالب Flutter وليس هوية الشركة |
| `project.pbxproj` | `IPHONEOS_DEPLOYMENT_TARGET` 12.0 → 13.0 (×3) | كل الحزم تعلن 12.0 كحد أدنى؛ 13.0 يمنع رفض Xcode الحديث |
| `ios/Podfile` | ملف جديد محفوظ في git | حتمية البناء السحابي بدل قالب يُولَّد كل مرة |
| الأيقونات | 15 ملفاً مولّدة من شعار الشركة | كانت شعار Flutter الافتراضي الأزرق |
| `codemagic.yaml` | ملف جديد | بناء IPA غير موقّع على macOS سحابي |

> **الـentitlements ليست ترفاً:** `SecItemAdd` على iOS يحتاج صلاحية سلسلة مفاتيح للـApp ID. فلتراجعها
> أولاً قبل أي تشخيص لـ«تسجيل الخروج التلقائي» أو «البصمة تطلب التسجيل كل مرة».
> **The entitlements are not optional:** `SecItemAdd` needs the App ID's keychain access group.
> Check them first when diagnosing "logs out on its own" or "biometrics ask to enrol every time".

### 3.2.1 خطوات الـworkflow الثمانية (كلٌّ لها سبب)

| # | الخطوة | لماذا |
|---|---|---|
| 1 | `List available Xcode versions` | يكشف غياب الإصدار المطلوب في الثانية الأولى |
| 2 | `Encoding gate` | يرفض أي ملف حرج بترميز غير UTF-8 برسالة صريحة (بدل انهيار Flutter الغامض) |
| 3 | `flutter pub get` | تنزيل الحزم |
| 4 | `flutter analyze` | بوابة الجودة (الاختبارات محلية لأن بعضها يحتاج عنوان LAN) |
| 5 | `pod install` | إظهار فشل الاعتماديات في خطوة مستقلة واضحة |
| 6 | `flutter build ios --release --no-codesign` | البناء الفعلي بلا توقيع |
| 7 | `Package unsigned IPA` | `Payload/Runner.app` + `zip -qry` (حفظ symlinks) |
| 8 | `Verify unsigned IPA` | يقرأ `Info.plist` **من داخل الحزمة** ويُفشل البناء إن غاب المعرّف أو ATS أو إذن الصور، ويؤكد وجود `App.framework` و`Flutter.framework` |

الخطوة 8 هي مقياس النجاح الحقيقي: "البناء نجح" لا يُثبت أن الملف صالح للتثبيت؛ فقد
تضيع منه قيمة إعداد فيُكتشف العطل على الجهاز بعد كل المصاريف. الآن يُكتشف قبل التنزيل.

### 3.3 إعداد Codemagic أول مرة (خطوات لمرة واحدة)

1. أنشئ حساباً على `codemagic.io` بحساب GitHub (الخطة المجانية: **500 دقيقة/شهر** على Mac mini M2).
2. Add application ← اختر المستودع `Aporaad/ky_apps` ← اختر **Flutter App** ← اختر
   **codemagic.yaml** كمصدر إعدادات (لا تستخدم الـworkflow المُولَّد من الواجهة).
3. Start new build ← workflow `ios-unsigned` ← Branch `main`.
4. الزمن المتوقع للبناء الأول 15–25 دقيقة (CocoaPods تنزّل المكتبات أول مرة)؛ وبعدها
   بفضل الـcache تهبط إلى 8–12 دقيقة.
5. نزّل من صفحة البناء: `ky-apps-<version>-unsigned.ipa` + `Runner.app.dSYM`.

**بديل احتياطي (GitHub Actions):** مستودع خاص على GitHub = 200 دقيقة macOS شهرياً
(مضاعف ×10) ≈ 10–13 بناء فقط. يُنشأ `.github/workflows/ios-unsigned.yml` عند الحاجة فقط.

**قاعدة إلزامية عند تعديل `codemagic.yaml`:** مخطط Codemagic صارم `additionalProperties: false`
ويرفض **أي مفتاح غير معروف** برسالة من نوع `<workflow> -> <key>: extra fields not permitted`
(حدث فعلاً مع `clone.submodules`). الحقول المسموحة على مستوى الـworkflow هي فقط:
`name` · `instance_type` · `max_build_duration` · `triggering` · `inputs` · `environment` ·
`integrations` · `cache` · `when` · `working_directory` · `pre_clone_scripts` · `scripts` ·
`artifacts` · `publishing` · `labels`. وداخل `environment`: `vars` · `groups` · `ios_signing` ·
`android_signing` · `flutter` · `xcode` · `cocoapods` · `node` · `java` · `ruby` · `ndk`…
ولا توجد كتلة `clone` في هذا الملف إطلاقاً (خيارات الجلب تُضبط من واجهة Codemagic).

---

## الجزء الرابع: إصدار نسخة جديدة — خطوة بخطوة

### 4.0 قائمة ما قبل الإصدار

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → لا إخفاق **جديد** (الإخفاقات الموثّقة في `devloping_history.md` فقط)
- [ ] رقم الإصدار في `pubspec.yaml` صحيح (انظر §4.1)
- [ ] لا تغيير غير مقصود في `ios/` أو `android/`
- [ ] `git status` نظيف ثم `git push origin main`

### 4.1 الترقيم

`version: 1.1.0+2` في `pubspec.yaml` هو المصدر الوحيد:
- `1.1.0` → `CFBundleShortVersionString` (ما يراه المستخدم).
- `2` → `CFBundleVersion` (رقم البناء).

| التغيير | مثال | القاعدة |
|---|---|---|
| إصلاح أخطاء | `1.1.0+2` → `1.1.1+3` | patch |
| ميزة جديدة | `1.1.1+3` → `1.2.0+4` | minor |
| تغيير جوهري | `1.2.0+4` → `2.0.0+5` | major |

الرقم بعد `+` **يزيد دائماً** لكل إصدار يُثبَّت على الجهاز. أول إصدار iOS هو
`1.1.0+2` (مطابق لآخر إصدار أندرويد، ولا تعارض بين المنصتين).

### 4.2 دفع الكود وبدء البناء

```powershell
cd c:\Users\Mujeeb\Desktop\arslan\ky_apps
flutter analyze
flutter test
python tools\check_encoding.py   # بوابة الترميز — انظر §4.2.1
python tools\ios_audit.py        # تدقيق آلي لإعدادات iOS — يجب أن ينتهي بـ ALL … CHECKS PASSED
git add -A; git commit -m "iOS: release 1.1.0+2"; git push origin main
# ثم من Codemagic: Start new build → ios-unsigned
```

> **تأكّد أن الدفع وصل فعلاً:** Codemagic يبني من **GitHub** لا من قرصك؛ كوميت محلي غير مدفوع
> لا يغيّر شيئاً في البناء. المرجع الموثوق هو المستودع البعيد لا `origin/main` المحلي القديم:
> `git ls-remote --heads origin` يجب أن يُظهر **نفس هاش `git rev-parse HEAD`**.

### 4.2.1 بوابة الترميز — لا تتخطّاها

`tools/check_encoding.py` يمنع فشلاً حقيقياً شهدناه: ملف `.gitignore` كان بترميز
Windows-1256، وأداة Flutter `SwiftPackageManagerGitignoreMigration` تقرأه بـ UTF-8 إلزاماً
فسقط البناء على macOS برسالة لا تذكر الترميز إطلاقاً:

```
Oops; flutter has exited unexpectedly: "FileSystemException: Failed to decode data
 using encoding 'utf-8', path = '/Users/builder/clone/.gitignore'"
```

الفحص يستغرق أقل من ثانية: فإن أرجع `RESULT: FAILED` نفّذ `--fix` ثم أعد المحاولة:

```powershell
python tools\check_encoding.py --fix
python tools\check_encoding.py      # يجب: RESULT: OK
```

**الاعتياد الوقائي:** أي تحرير لـ`.gitignore` أو أي ملف بنص عربي يجب أن يُحفط بـ**UTF-8**.
محررات ويندوز القديمة تكتب ANSI/Windows-1256 بصمت وتُنتج هذا العطل نفسه.

### 4.3.0 فحص جاهزية ويندوز قبل التثبيت (دقيقة واحدة)

Sideloadly لا يتحدث مع الآيفون إلا عبر منظومة Apple للسائق على ويندوز. نسخة **Microsoft Store**
من iTunes تقدّم `AppleMobileDeviceProcess` ولا تُنشئ خدمة `Apple Mobile Device Service` الكلاسيكية،
وقد يرى ويندوز الجهاز بحالة `Unknown` فلا يظهر في Sideloadly. افحص قبل لصق الـIPA:

```powershell
# 1) هل منظومة السائق الكلاسيكية موجودة؟
Test-Path "C:\Program Files\Common Files\Apple\Mobile Device Support"
Get-Service -Name "Apple Mobile Device Service" -ErrorAction SilentlyContinue

# 2) هل يرى ويندوز الآيفون؟ وما حالته؟
Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue |
  Where-Object { $_.FriendlyName -match "iPhone" } |
  Select-Object FriendlyName, Status
```

- `True` + خدمة `Running` + الحالة `OK` → جاهز.
- المسار `False` أو لا خدمة أو الحالة `Unknown` → ثبّت **iTunes الكلاسيكي x64** من `apple.com`
  (يُثبّت `Apple Mobile Device Support` والسائق `usbaapl64`)، وأزل نسخة Microsoft Store إن تعارضت.
  وتأكد أن شاشة الآيفون مفتوحة وأنك ضغطت **الثقة** على الجهاز.

### 4.3 التثبيت على الآيفون من ويندوز

1. **مرة واحدة:** ثبّت **iTunes بنسخة الويب (x64)** — لا نسخة Microsoft Store
   (النسخة المخزنية تُنتج خطأ `NP_E_CONN_FAILED`). بديل مقبول: تطبيق *Apple Devices*.
2. **مرة واحدة:** ثبّت **Sideloadly** من `sideloadly.io` (مجاني).
3. على الآيفون: `الإعدادات ← الخصوصية والأمان ← وضع المطوّر` = **مفعّل**، ثم
   وصّل الكيبل واضغط **الثقة** على الجهاز.
4. اسحب ملف الـIPA إلى Sideloadly ← أدخل **Apple ID** العادي (يصل رمز 2FA إلى الآيفون)
   ← Sign & Install.
5. أول تشغيل: `الإعدادات ← عام ← VPN وإدارة الأجهزة` ← اضغط حسابك ← **الثقة**.
6. فعّل **Auto-Refresh** في Sideloadly (يعمل عبر الواي فاي مع بقاء الحاسوب يعمل ونفس الشبكة).
7. للتحديث لاحقاً: اسحب الـIPA **الجديد** بنفس الـBundle ID ونفس Apple ID ← يُثبَّت فوق
   القديم وتحتفظ الجلسة والإعدادات.

### 4.3.1 حساب Apple ID المطلوب — ما هو ومن أين تجده

**ما هو:** ليس حساب Apple Developer Program (99$/سنة). هو **حساب Apple العادي** الذي تستخدمه
في iCloud وApp Store على الآيفون نفسه. حين توقّع به، تمنحك Apple فريقاً شخصياً مجانياً
("Personal Team") بشهادة تطوير صالحة **7 أيام**.

**كيف تجده — على الآيفون:**
1. `الإعدادات` ← اضغط **اسمك/صورتك أعلى القائمة** ← البريد الظاهر تحته هو معرّف Apple ID.
2. أو `الإعدادات` ← `App Store` ← اضغط صورة الحساب أعلى ← يظهر البريد.
3. أو من المتصفح: `account.apple.com` ← تسجيل الدخول ← بيانات الحساب.

**إن لم يكن لديك حساب:**
- على الآيفون: `الإعدادات` ← «تسجيل الدخول إلى iPhone» ← «ليس لديك Apple ID؟» ← إنشاء.
- أو من `account.apple.com` ← Create Your Apple ID.
- أي بريد يصلح (Gmail/Outlook...) — لا يلزم بريد iCloud.
- يجب رقم هاتف لاستلام رمز التحقق؛ **التحقق بخطوتين (2FA) إلزامي** لاستخدام الحساب في التوقيع.

**في Sideloadly:** ضع البريد في حقل **Apple ID** ← كلمة السر ← ثم رمز 2FA الذي يظهر على
الآيفون. لا تستخدم «App-Specific Password» (تعمل مع الحسابات المدفوعة فقط وبخيار anisette معطّل).

**تحذيرات عملية:**
- لا يصلح **Managed Apple ID** (حساب مدرسة/شركة) للتوقيع.
- استخدم الحساب الذي تستطيع قبول رمز 2FA على **نفس الآيفون** الذي تُجرّب عليه.
- كل توقيع مجاني ينتهي بعد 7 أيام (انتهاء الشهادة لا يحذف بيانات التطبيق، §2.2).

### 4.4 الأرشفة

```powershell
# أرشيف محلي (خارج git) — احفظ فيه الـIPA ورموز التفكيك لكل إصدار
New-Item -ItemType Directory -Force -Path "release_artifacts\ios-v1.1.0+2" | Out-Null
Copy-Item "<مسار التنزيل>\ky-apps-1.1.0+2-unsigned.ipa" "release_artifacts\ios-v1.1.0+2\"
Copy-Item "<مسار التنزيل>\Runner.app.dSYM.zip"          "release_artifacts\ios-v1.1.0+2\"
```

رموز الـdSYM تُحفظ للأبد لكل إصدار: بدونها لا يمكن قراءة تقارير الانهيار في نسخة release.

### 4.5 التوثيق بعد الإصدار (عرف المشروع)

أضف في **آخر** كل ملف دون حذف أي شيء: `todo.md` · `devloping_history.md` · `user_commends.md`.

---

## الجزء الخامس: تجربة التطبيق على الجهاز (قائمة تحقق)

### 5.0 شرط الشبكة — يُتحقَّق منه **قبل** أي شيء آخر

السبب الأول المتوقع لأي «فشل اتصال» ليس التطبيق بل الشبكة:

1. الخادم يستمع على الشبكة لا على `localhost`:
   `php artisan serve --host 0.0.0.0` (أو خدمة NSSM).
2. جدار حماية ويندوز يسمح بالمنفذ **8000** الوارد من الشبكة المحلية.
3. الآيفون على **نفس شبكة الواي فاي**؛ افتح Safari على الآيفون وجرّب
   `http://<server-ip>:8000/api/hello` — يجب أن يردّ JSON.
4. إن اختلف عنوان الخادم عن `192.168.0.9` (الافتراضي في `api_constants.dart`)،
   عدّله من داخل التطبيق: أيقونة المعلومات ← «معلومات البرنامج والدعم» ← نقر اسم
   المطور **5 مرات** ← كلمة سر إعدادات API.

### 5.0.1 قياس جاهزية الشبكة — حالة مقيسة (2026-11-01 02:35)

نتيجة القياس على جهاز التطوير وقت كتابة هذا القسم:

| القياس | النتيجة |
|---|---|
| عناوين الجهاز IPv4 | `192.168.0.11` (Ethernet) · `192.168.178.176` (Wi‑Fi) · `26.210.208.234` (Radmin VPN) |
| الاستماع على المنفذ 8000 محلياً | **لا شيء** |
| `http://127.0.0.1:8000/api/hello` | **فشل** (تعذر الاتصال) |
| `192.168.0.9:8000` (الافتراضي في التطبيق) | **غير قابل للوصول** (timeout) |
| خدمة Laravel/PHP/NSSM | **غير موجودة** (الموجود فقط `bio-apache0` لجهاز آخر) |
| قاعدة جدار حماية للمنفذ 8000 | **لا قاعدة** — لكن جدار الحماية نفسه **معطّل** على الملفات الثلاثة (Domain/Private/Public = False) ⇒ لا يحجب شيئاً حالياً |

أي أن أي محاولة دخول من الآيفون الآن ستنتهي بفشل اتصال **لسبب خارجي عن التطبيق**. للتجهيز:

```powershell
# 1) تشغيل الـAPI على كل الواجهات (تم فعلاً: يعمل على 0.0.0.0:8000)
cd kyApp_API
php artisan serve --host 0.0.0.0 --port 8000

# 2) التأكد محلياً ومن الشبكة (نتائج مقيسة: 200 على العناوين الثلاثة)
(Invoke-WebRequest "http://127.0.0.1:8000/api/hello" -UseBasicParsing).Content
(Invoke-WebRequest "http://192.168.178.176:8000/api/hello" -UseBasicParsing).Content
```

> جدار الحماية على هذا الجهاز معطّل بالكامل، فلا حاجة لإضافة قاعدة للمنفذ 8000 الآن. إن أُعيد
> تفعيله لاحقاً تصبح القاعدة لازمة:
> `New-NetFirewallRule -DisplayName "ky API 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow`

**ثم من Safari على الآيفون** استخدم عنوان **نفس الشبكة التي عليها الهاتف**:
- إن كان الآيفون على الواي فاي `192.168.178.x` ← `http://192.168.178.176:8000/api/hello`
- إن كان على شبكة الإيثرنت `192.168.0.x` ← `http://192.168.0.11:8000/api/hello`

وبعد نجاح الرد في Safari، أدخل نفس العنوان + `/api` في إعدادات التطبيق (§5.0-4).
اختبار الشبكة من Safari أولاً يفصل «عطل الشبكة» عن «عطل التطبيق» في خطوة واحدة.

#### قياس لاحق: سبب 500 هو خدمة Oracle خاطئة في `.env`

بعد تشغيل الـAPI ظهر أن `/api/hello` يعمل (200) بينما `/api/app-config` يعطي **500**. السبب
من سجل Laravel والأداة المساعدة `yajra/laravel-pdo-via-oci8`:

```
ORA-12514: TNS:listener does not currently know of service requested in connect descriptor
SERVICE_NAME = orclrd   ← قيمة .env الحالية
```

واختبار الخدمات بنفس بيانات `.env` (بلا طباعة كلمة السر) أعطى:

| الخدمة | النتيجة |
|---|---|
| `ORCL` | **نجح** — 499 جدولاً لمخطط `ACCOUNTS` |
| `ORCL3` | نجح — 500 جدولاً لمخطط `ACCOUNTS` |
| `ORCL2` | فشل: `ORA-01017` بيانات اعتماد غير صحيحة |
| `orclrd` · `XE` · `FREE` | فشل: `ORA-12514` غير مسجّلة على المستمع |

وبعد التجاوز للعملية وحدها (`DB_SERVICE_NAME=ORCL` دون لمس `.env`) عاد `/api/app-config`
بـ**200** وبيانات حقيقية (`الكبودي للخياطة الرجالية`).

**طريقتان لتعمل التجربة:**
1. **دائم:** في `kyApp_API/.env` غيّر السطر إلى `DB_SERVICE_NAME=ORCL` (أو `ORCL3`) وأعد تشغيل الخادم.
   هذا هو العقد الموثّق في `kyApp_API/AGENTS.md` (`DB_SERVICE_NAME=orcl`).
2. **مؤقت (بلا تعديل):** شغّل الخادم بتجاوز بيئة للعملية فقط:
   ```powershell
   cd kyApp_API; $env:DB_SERVICE_NAME="ORCL"; php artisan serve --host 0.0.0.0 --port 8000
   ```

اختر الخدمة التي تحمل **بيانات العمل الحالية**: `ORCL` و`ORCL3` كلاهما يملك مخطط `ACCOUNTS`
ولكنهما مجموعتان مختلفتان (499 مقابل 500 جدولاً), والقرار لصاحب البيئة.

### 5.1 القائمة

- [ ] **الأيقونة والاسم:** شعار الشركة، والاسم «الكبودي» تحته.
- [ ] **شاشة الدخول:** عربية/RTL، اسم المستخدم السابق مُعبّأ تلقائياً.
- [ ] **إعداد API:** تعديل الرابط + زر فحص الاتصال (`/hello`) ينجح.
- [ ] **الدخول:** بمستخدم موظف حقيقي.
- [ ] **الجلسة:** إغلاق التطبيق وفتحه → ما زال داخلاً + عدّاد الانتهاء الخامل يعمل.
- [ ] **البيومتري:** تسجيل الجهاز (Face ID/Touch ID) ← خروج ← دخول بالبصمة.
- [ ] **IBAC:** مستخدم بلا صلاحية لا يرى القسم إطلاقاً (لا يُعطَّل فقط).
- [ ] **الأقسام:** العملاء، الحسابات، التفصيل، جاري العاملين، المخازن، الإدارة.
- [ ] **التقارير:** فتح كشف ← تصدير PDF ← ورقة المشاركة/الطباعة تظهر بشكل صحيح.
- [ ] **الشعار من المعرض:** يظهر **طلب إذن الصور** ثم يعود الشعار للظهور (اختبار
      `NSPhotoLibraryUsageDescription` — لو نُسي، انهار التطبيق هنا).
- [ ] **الشبكة:** وضع الطيران ← رسائل خطأ واضحة ← استعادة الاتصال بلا إعادة تشغيل.
- [ ] **الشاشة الصغيرة:** iPhone SE + أكبر حجم خط — لا `RenderFlex overflow`.
- [ ] **الخط:** ملاحظة معروفة — `google_fonts` يحمّل Cairo من الإنترنت أول مرة؛
      على شبكة معزولة عن الإنترنت يظهر خط احتياطي (لا يؤثر على الوظائف).

### 5.2 ملاحظات سلوك خاصة بـiOS (لا تظهر في أندرويد)

رُصدت من مراجعة الكود وحزم iOS نفسها — تُوفّر وقتاً في التشخيص أثناء التجربة:

1. **معرّف الجهاز البيومتري يتغيّر إذا حُذف التطبيق:**
   `DeviceIdHelper` يبني `device_token` من `identifierForVendor` على iOS، وهذا المعرّف يتبدّل
   حين تُزال كل تطبيقات المطوّر نفسه من الجهاز. لذلك **أعد التوقيع بالتثبيت فوق القديم**
   (كما في §4.3) ولا تحذف التطبيق لتجربة نسخة جديدة، إلا إذا كنت مستعداً لإعادة تسجيل البصمة.
2. **اسم الجهاز في شاشة الجلسات سيبدو «iPhone» فقط:**
   `device_info_plus` يحتاج entitlement خاصاً (`com.apple.developer.device-information.user-assigned-device-name`)
   ليُعيد الاسم الذي اختاره المستخدم؛ بدونه يعود بـ`iPhone`. الأثر تجميلي فقط في سجل الأجهزة.
3. **ورقة المشاركة على iPad لا تعمل في هذا الإصدار:**
   استدعاءات `Printing.sharePdf` و`SharePlus.instance.share` لا تمرّر `sharePositionOrigin`،
   وهو **إلزامي على iPad** فقط (ينهار الـpopover بدونهما)، بينما لا يلزم على iPhone.
   التطبيق معلن كـuniversal (`TARGETED_DEVICE_FAMILY = "1,2"`)، فاختبر على الآيفون كما هو مقصود؛
   وإذا اعتمدت iPad لاحقاً فأضف المستطيل المرجع للزر في كل موضع تصدير.
4. **الطباعة (`Printing.layoutPdf`) تفتح حوار AirPrint:**
   بلا طابعة متاحة سيظهر الحوار فارغاً — هذا **ليس** خطأً في التطبيق؛ لاختبار التصدير نفسه استخدم زر
   «تصدير/مشاركة» (share sheet) الذي لا يحتاج طابعة.

---

## الجزء السادس: ملاحظات الأمان

1. **ATS=ArbitraryLoads مبرَّر مؤقتاً:** لأن `ApiConstants.defaultBaseUrl` هو `http://…`
   ويُعدَّل من داخل التطبيق. عند نشر الخادم على **HTTPS** يُحذف المفتاح بالكامل من
   `ios/Runner/Info.plist` (يصبح iOS يقبل الاتصال المشفّر وحده — وهو الأفضل أمنياً).
2. **لا أسرار في المستودع ولا في السحابة:** لا شهادة iOS ولا كلمة سر Apple تُحفظ في
   المشروع أو Codemagic؛ بيانات الحساب تُدخل يدوياً في Sideloadly على جهازك فقط.
3. **التوقيع المجاني لا يُستخدم للتوزيع:** لا يُمنح الـIPA الموقّع بيد غيرك — تسجيل
   الأجهزة وحدود المدة تجعل ذلك غير عملي أصلاً.
4. **بيانات التطبيق الحساسة** (التوكن، رابط API، الصلاحيات) تبقى في Keychain عبر
   `flutter_secure_storage` — لا تُنقل إلى `SharedPreferences` على iOS أيضاً. وهذا يبقى صحيحاً
   **فقط** ما دامت `keychain-access-groups` معلنة في `ios/Runner/*.entitlements`: بدونها
   يقول النظام «تم الحفظ» ولا يحفظ، فيضيع التوكن فعلياً بين إقلاعين.

---

## الجزء السابع: استكشاف الأخطاء

| العرض | السبب | الحل |
|---|---|---|
| `Sideloadly` لا يرى الجهاز | نسخة iTunes من Microsoft Store (لا خدمة AMDS) | تحقق من §4.3.0 ثم ثبّت iTunes الكلاسيكي x64 |
| `NP_E_CONN_FAILED` | نفس السبب أعلاه | نفس الحل |
| `Developer Mode disabled` | iOS 16+ يتطلب تفعيله | الإعدادات ← الخصوصية والأمان ← وضع المطوّر |
| التطبيق لا يفتح: «Untrusted Developer» | الحساب غير موثوق | الإعدادات ← عام ← VPN وإدارة الأجهزة ← الثقة في الحساب |
| التطبيق يتوقف بعد 7 أيام | انتهاء الشهادة المجانية | أعد التوقيع بنفس الـIPA (أو فعّل Auto-Refresh) |
| `maximum App ID limit … 10 App IDs every 7 days` | حدّ Apple للحساب المجاني | انتظر أياماً أو استخدم Apple ID آخر |
| `maximum number of installed apps using a free developer profile` | 3 تطبيقات كحد أقصى | احذف تطبيقاً جانبياً من الجهاز |
| `DeviceNotSupportedByThinning` | الجهاز غير مدعوم في الملف | فعّل «Remove limitation on supported devices» في الخيارات المتقدمة |
| فشل بناء: CocoaPods / Xcode غير متاح | إصدار Xcode المطلوب غير موجود على الآلة | سجل البناء يعرض **قائمة الإصدارات المتاحة** — غيّر `xcode` في `codemagic.yaml` إلى أقربها إلـ`16.2` |
| `<workflow> -> <key>: extra fields not permitted` | مفتاح غير معروف في `codemagic.yaml` | راجع قائمة الحقول المسموحة في §3.3، واعلم أنه لا توجد كتلة `clone` |
| فشل بناء: `IPHONEOS_DEPLOYMENT_TARGET` | Pod يطلب إصداراً أعلى | تأكد أن `ios/Podfile` موجود ومحفوظ (فيه `post_install` يوحّد 13.0) |
| **التطبيق يعمل لكن كل الطلبات تفشل** | ATS يحجب `http`، أو الخادم/الجدار الناري | تحقق من `NSAppTransportSecurity` في الـ`Info.plist`، ثم من Safari على الآيفون (§5.0) |
| **انهيار لحظة اختيار الشعار** | `NSPhotoLibraryUsageDescription` محذوف | أعده إلى `Info.plist` وأعد البناء |
| **تسجيل الخروج التلقائي عند كل إقلاع / البطاقة البيومترية تُلغى** | `keychain-access-groups` غير مربوطة بالهدف | تأكد من وجود الملفَّين وأن `CODE_SIGN_ENTITLEMENTS` مضبوط في الإعدادات الثلاث (وأن Sideloadly وقّع بنفس App ID) |
| **`flutter has exited unexpectedly: FileSystemException: Failed to decode data using encoding 'utf-8', path = '.gitignore'`** | ملف بترميز Windows-1256 (محرر ويندوز قديم) — لا علاقة له بـiOS | `python tools\check_encoding.py --fix` ثم ادفع وأعد البناء |
| **ورقة المشاركة لا تظهر على iPad** | `sharePositionOrigin` إلزامي على iPad ولم يُمرَّر | لا يخص الآيفون؛ أضف المستطيل المرجعي للزر في كل موضع تصدير قبل اعتماد iPad (§5.2-3) |
| **`ORA-12514` من الـAPI** | `.env` يشير إلى خدمة غير مسجّلة (`orclrd`) | استخدم `DB_SERVICE_NAME=ORCL` (أو `ORCL3`) — انظر §5.0.1 |
| العربية تظهر رموزاً | تحويل الترميز (خادم/عميل) أو خط غير محمّل | نفس تشخيص نسخة أندرويد — راجع `DBdevloping_history.md` |

---

## الجزء الثامن: الترقية إلى حساب Apple Developer مدفوع (99$/سنة)

ماذا يتغير عند الشراء:

| البند | مجاني | مدفوع |
|---|---|---|
| صلاحية التثبيت | 7 أيام | سنة كاملة |
| TestFlight (توزيع للعاملين) | لا | نعم (100 مستخدم داخلي) |
| Ad Hoc (100 جهاز) | لا | نعم |
| App Store | لا | نعم |
| عدد التطبيقات الجانبية | 3 | لا حد |

**ما يجب الحفاظ عليه عند الترقية:** نفس **Bundle ID** (`com.alkaboudy.app`) — يُنقل
بلا مشاكل إلى الحساب الجديد لأنه لم يُسجَّل في حساب مدفوع سابق. ونفس الـApple ID إن أمكن
(أو يُستخدم الحساب الجديد في Sideloadly/Xcode بلا تغيير في المشروع). عندها تتحول خطوة
`--no-codesign` إلى بناء موقّع كامل (`codesign` عبر شهادة الحساب) ويمكن رفع الـIPA إلى
TestFlight مباشرة، وتُحدَّث هذه الوثيقة.

---

## الجزء التاسع: الخلاصة التشغيلية (Quick Reference)

```powershell
# === إصدار iOS جديد ===
# 1) pubspec.yaml → version: 1.1.1+3  (الرقم بعد + يزيد دائماً)
flutter analyze
flutter test
git add -A; git commit -m "iOS: release 1.1.1+3"; git push origin main
# 2) Codemagic → Start new build → ios-unsigned  (≈8–25 دقيقة)
# 3) نزّل ky-apps-1.1.1+3-unsigned.ipa + Runner.app.dSYM.zip
# 4) Sideloadly → اسحب الـIPA → Apple ID المجاني → Sign & Install
# 5) أرشيف: release_artifacts\ios-v1.1.1+3\
# 6) وثّق في todo.md / devloping_history.md / user_commends.md
# 7) تجربة على الجهاز حسب §5
```

**ثوابت لا تُنكسر:**
1. `Bundle ID = com.alkaboudy.app` — لا يُغيَّر (تغييره = تطبيق مختلف تماماً).
2. لا بناء iOS من ويندوز — دائماً عبر Codemagic (`codemagic.yaml`).
3. لا أسرار Apple في git ولا في Codemagic.
4. `NSPhotoLibraryUsageDescription` يبقى في `Info.plist` ما دام زر اختيار الشعار موجوداً.
5. `NSAllowsArbitraryLoads` يُزال عند نشر الخادم على HTTPS.
6. الـdSYM يُحفظ لكل إصدار موزَّع.
7. `keychain-access-groups` يبقى في `ios/Runner/DebugProfile.entitlements` و`Release.entitlements`
   ومربوطاً بـ`CODE_SIGN_ENTITLEMENTS` في الإعدادات الثلاث — حذفه يُفسد الجلسة والبيومترية بصمت.
