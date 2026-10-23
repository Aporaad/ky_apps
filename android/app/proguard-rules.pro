# قواعد ProGuard/R8 المخصصة لإصدار Release
# Custom ProGuard/R8 rules for the release build.
#
# Flutter ورفاقه من المكتبات يوفرون قواعد consumer افتراضية تلقائياً،
# Flutter and its plugins ship their own consumer rules automatically,
# لذلك نكتفي هنا بإضافة الحماية الخاصة بمكونات التطبيق.
# so only app-specific keeps are added here.

# حماية أذونات/فئات بيئات Android المستخدمة عبر reflection من الإزالة
# Keep Android classes referenced reflectively (biometric / embedding).
-keep class io.flutter.** { *; }
-keep class com.alkaboudy.app.MainActivity { *; }

# تجاهل مراجع Play Core غير الموجودة — التطبيق لا يستخدم المكوّنات المؤجّلة
# (deferred components) لكن تغليف Flutter يشير إليها في كود غير مفعّل.
# Ignore missing Play Core references: the app has no deferred components,
# but Flutter embedding classes reference Play Core in unused code paths.
-dontwarn com.google.android.play.core.**
