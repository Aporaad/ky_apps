import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../../../app_info/presentation/screens/app_info_screen.dart';
import '../../../app_info/presentation/utils/external_links.dart';
import '../../../app_info/presentation/widgets/contact_icon_button.dart';
import '../../../app_info/presentation/widgets/whatsapp_icon.dart';
import '../providers/auth_notifier.dart';
import '../widgets/biometric_login_button.dart';
import '../widgets/user_type_selector.dart';

/// شاشة تسجيل الدخول المتجاوبة
/// Responsive Login Screen with UserTypeSelector (Username + Password only)
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  /// هل حقل اسم المستخدم غير فارغ؟ — يتحكم بظهور زر المسح وحده
  /// Whether the username field holds text — drives the clear button's visibility.
  bool _hasUsernameText = false;

  @override
  void initState() {
    super.initState();
    // القيمة وصلت من `AuthNotifier` عند الإقلاع، فتُطبَّق متزامنةً بلا وميض
    // The value was loaded by AuthNotifier at boot, so it is applied synchronously here.
    _restoreUsername();
    _usernameController.addListener(_syncUsernameText);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_syncUsernameText);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// تعبئة الحقل بآخر اسم نجح تسجيله على هذا الجهاز
  /// Prefill the field with the last username that signed in successfully on this device.
  void _restoreUsername() =>
      _applyRemembered(ref.read(authNotifierProvider).lastUsername);

  /// وضع القيمة في الحقل إن كانت صالحة والحقل ما زال فارغاً
  /// Put the value in the field when it is usable and the field is still empty.
  ///
  /// لا تُلمس قيمة كتبها المستخدم: التعبئة التلقائية تملأ فراغاً ولا تستبدل كتابة.
  /// A value the user already typed is never replaced — the prefill only fills a gap.
  void _applyRemembered(String? value) {
    final remembered = value?.trim() ?? '';
    if (remembered.isEmpty || _usernameController.text.isNotEmpty) return;

    _usernameController.text = remembered;
    _usernameController.selection =
        TextSelection.collapsed(offset: remembered.length);
    _hasUsernameText = true;
  }

  /// إعادة البناء عند تغيّر «فارغ/غير فارغ» فقط، لا مع كل ضغطة مفتاح
  /// Rebuild only when the empty↔non-empty state flips, never on every keystroke.
  void _syncUsernameText() {
    final hasText = _usernameController.text.trim().isNotEmpty;
    if (hasText == _hasUsernameText) return;

    setState(() => _hasUsernameText = hasText);
  }

  /// مسح الاسم المحفوظ من الجهاز ومن الحالة — يخدم الأجهزة المشتركة
  /// Forget the stored username on this device and in the state, for shared devices.
  Future<void> _forgetUsername() async {
    _usernameController.clear();
    await ref.read(authNotifierProvider.notifier).forgetLastUsername();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authNotifierProvider.notifier).login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      final userType = ref.read(authNotifierProvider).selectedUserType;
      if (userType == 'employee') {
        context.go('/employee');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بوابة العميل قيد التطوير حالياً'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final success =
        await ref.read(authNotifierProvider.notifier).loginWithBiometric();

    if (success && mounted) {
      final userType = ref.read(authNotifierProvider).selectedUserType;
      if (userType == 'employee') {
        context.go('/employee');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بوابة العميل قيد التطوير حالياً'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  /// فتح شاشة «معلومات البرنامج والدعم» — ومنها وحدها تُتاح بوابة إعدادات الـ API
  /// Open the app-info & support screen — the only place the API-settings gate is live.
  void _openAppInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AppInfoScreen(allowApiUnlock: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    // اسم الشركة من التهيئة — ينعكس فوراً على شاشة الدخول
    // Company name from config — reflects on the login screen immediately.
    final companyName =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.companyName));
    // رقم التواصل الفعّال: `contactPhone` يعود للافتراضي المضمّن إن كانت القيمة المخزَّنة فارغة
    // (كاش قديم أو جهاز جديد بلا اتصال) — فالأيقونتان لا تختفيان لمجرد تعذّر الوصول إلى الـ API.
    // The effective contact number: `contactPhone` falls back to the baked-in default when the
    // stored value is blank (stale cache or a fresh device with no network), so the two icons never
    // disappear just because the API is unreachable.
    final contactPhone =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.contactPhone));

    // مقاسات مشتقة من ارتفاع النافذة: البطاقة كلها على شاشة واحدة بلا تمرير
    // Metrics derived from the window height: the whole card on one screen, no scrolling.
    final metrics = _LoginLayout.of(MediaQuery.sizeOf(context).height);

    // لو وصل الاسم المحفوظ بعد بناء الشاشة (إقلاع بطيء أو فتح مباشر لـ `/login`) يُعبّأ فور وصوله.
    // كانت القيمة تُقرأ مرة واحدة في `initState`، وهذا يترك الحقل فارغاً حين يسبق بناءُ الشاشة
    // قراءةَ التخزين — وهو احتمال حقيقي على الأجهزة البطيئة.
    // If the remembered name lands after this screen is built (slow boot, or a direct `/login`
    // deep link) the field is filled the moment it arrives. Reading it only in `initState` left the
    // field empty whenever the screen was built before secure storage answered.
    ref.listen<String?>(
      authNotifierProvider.select((s) => s.lastUsername),
      (_, next) => _applyRemembered(next),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // شريط علوي بأيقونة واحدة: «معلومات البرنامج والدعم» في أعلى اليسار
      // A one-icon app bar: "app info & support" at the top-left corner.
      //
      // التطبيق عربي RTL، فخانة `actions` تُرسم على اليسار — وهي الجهة المطلوبة. ولا يبقى
      // في الشريط أي طريق إلى إعدادات الـ API: تلك بوابة النقر الخمسي داخل الشاشة نفسها.
      // The app is RTL, so [actions] renders on the left — the requested corner. Nothing in this
      // bar leads to the API settings: that is the five-tap gate inside the screen itself.
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _openAppInfo,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'معلومات البرنامج والدعم',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          // التمرير يبقى شبكة أمان: لوحة المفاتيح أو تكبير الخط 1.25 قد يتجاوز أي حساب
          // Scrolling stays as a safety net: the keyboard or a 1.25 text scale can outgrow any math.
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: metrics.gap(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
                // side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: EdgeInsets.all(metrics.gap(10)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(0),
                          // decoration: BoxDecoration(
                          //   color: AppColors.primary.withValues(alpha: 0.00),
                          //   borderRadius: BorderRadius.circular(0),
                          // ),
                          child: AppLogo(
                            width: metrics.logoWidth,
                            height: metrics.logoHeight,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.gap(18)),
                      // اسم الشركة من التهيئة بدل النص المثبّت
                      // Company name from config instead of a hardcoded literal.
                      Text(
                        companyName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: metrics.gap(6)),
                      Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      // السطر التعريفي يُحذف على الشاشات القصيرة: وجوده يدفع زر الدخول خارج الإطار
                      // The intro line is dropped on short screens: it pushes the sign-in button
                      // off the frame.
                      if (metrics.showSubtitle) ...[
                        SizedBox(height: metrics.gap(6)),
                        Text(
                          'أدخل بيانات حسابك للمتابعة إلى النظام',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(height: metrics.gap(20)),

                      // محدد نوع المستخدم (موظف / عميل)
                      UserTypeSelector(
                        selectedType: authState.selectedUserType,
                        onTypeChanged: (type) {
                          ref
                              .read(authNotifierProvider.notifier)
                              .setUserType(type);
                        },
                      ),
                      SizedBox(height: metrics.gap(18)),

                      // رسالة الخطأ عند فشل الدخول
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: metrics.gap(12)),
                      ],

                      // حقل اسم المستخدم
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          hintText: 'أدخل اسم المستخدم أو رقم الحساب',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          // زر المسح يظهر فقط إن وُجد اسم محفوظ والحقل غير فارغ
                          // The clear button appears only with a stored name and a non-empty field.
                          suffix:
                              authState.lastUsername != null &&
                                  _hasUsernameText
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                  ),
                                  color: AppColors.textSecondary,
                                  tooltip: 'مسح اسم المستخدم المحفوظ',
                                  onPressed: _forgetUsername,
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال اسم المستخدم';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: metrics.gap(12)),

                      // حقل كلمة المرور
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          
                          suffixIcon: (authState.isBiometricEnabled && authState.biometricCapability != BiometricCapability.notSupported && authState.biometricCapability != BiometricCapability.notEnrolled)
                              ? BiometricLoginButton(
                                    capability: authState.biometricCapability,
                                    isLoading: authState.isBiometricLoading,
                                    onPressed: authState.isLoading
                                        ? null
                                        : _handleBiometricLogin
                                  )
                              : null,
                        suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: metrics.gap(18)),

                      // زر تسجيل الدخول مع مؤشر التحميل
                      ElevatedButton(
                        onPressed: (authState.isLoading || authState.isBiometricLoading)
                            ? null
                            : _handleLogin,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('دخول'),
                      ),
                      SizedBox(height: metrics.gap(8)),

                      // أسفل البطاقة: أيقونتا اتصال وواتساب صغيرتان للتواصل مع الشركة، بدل سطر
                      // «الإصدار» الذي انتقل إلى شاشة «معلومات البرنامج والدعم» وحدها.
                      // Under the card: two small call and WhatsApp icons for contacting the company,
                      // replacing the version line that now lives on the app-info screen alone.
                      _CompanyContactBar(phone: contactPhone),

                      // // زر البصمة إذا كانت مفعّلة ومدعومة بالجهاز
                      // if (authState.isBiometricEnabled &&
                      //     authState.biometricCapability !=
                      //         BiometricCapability.notSupported &&
                      //     authState.biometricCapability !=
                      //         BiometricCapability.notEnrolled) ...[
                      //   const SizedBox(height: 20),
                      //   // Row(
                      //   //   children: [
                      //   //     Expanded(child: Divider()),
                      //   //     Padding(
                      //   //       padding: EdgeInsets.symmetric(horizontal: 16),
                      //   //       child: Text(
                      //   //         'أو عبر البصمة',
                      //   //         style: TextStyle(
                      //   //           color: AppColors.textSecondary,
                      //   //           fontSize: 12,
                      //   //         ),
                      //   //       ),
                      //   //     ),
                      //   //     Expanded(child: Divider()),
                      //   //   ],
                      //   // ),
                      //   // const SizedBox(height: 20),
                      //   // BiometricLoginButton(
                      //   //   capability: authState.biometricCapability,
                      //   //   isLoading: authState.isBiometricLoading,
                      //   //   onPressed: authState.isLoading
                      //   //       ? null
                      //   //       : _handleBiometricLogin,
                      //   // ),
                      // ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// مقاسات شاشة الدخول مشتقة من ارتفاع النافذة — كي تُحمَّل البطاقة كاملة في شاشة واحدة
/// The login screen's metrics derived from the window height, so the whole card fits one screen.
class _LoginLayout {
  const _LoginLayout({
    required this.scale,
    required this.logoWidth,
    required this.logoHeight,
    required this.showSubtitle,
  });

  /// اشتقاق المقاسات من ارتفاع النافذة الكامل (ومعه الشريط العلوي وشريط النظام)
  /// Derive the metrics from the full window height (system chrome and app bar included).
  ///
  /// 140 بكسل تقديرٌ للشريطين اللذين لا تملكهما البطاقة، و700 هي المساحة التي صُمّمت عليها
  /// الشاشة بارتياح؛ فلا تكبير فوق 1.0 (الأحجام الأصلية) ولا تصغير تحت 0.62 (حدّ يبقى مقروءاً).
  /// 140 px stands for the two bars the card never owns, and 700 is the room the screen was
  /// designed for: never above 1.0 (the original sizes) and never below 0.62 (a legible floor).
  factory _LoginLayout.of(double windowHeight) {
    final scale = ((windowHeight - 140) / 700).clamp(0.62, 1.0).toDouble();

    return _LoginLayout(
      scale: scale,
      logoWidth: (250 * scale).clamp(130.0, 250.0).toDouble(),
      logoHeight: (170 * scale).clamp(88.0, 170.0).toDouble(),
      showSubtitle: windowHeight >= 660,
    );
  }

  /// معامل التصغير الرأسي (0.62 .. 1.0)
  /// The vertical shrinking factor (0.62 .. 1.0).
  final double scale;

  final double logoWidth;
  final double logoHeight;

  /// هل يظهر «أدخل بيانات حسابك للمتابعة إلى النظام»؟ — يُخفى على الشاشات القصيرة
  /// Whether the intro line is shown — it is dropped on short screens.
  final bool showSubtitle;

  /// فراغ رأسي بنسبته من المقياس
  /// A vertical gap scaled by the factor.
  double gap(double natural) => natural * scale;
}

/// أيقونتا التواصل مع الشركة أسفل بطاقة الدخول — رقم الشركة يأتي من `APP_SETTINGS`
/// The two company-contact icons under the login card — the number comes from `APP_SETTINGS`.
///
/// لماذا هنا؟ الزائر قبل الدخول لا يملك أي وسيلة للتواصل: لا شاشة استفسار مفتوحة ولا رقم ظاهر.
/// الأيقونتان تفتحان الاتصال وواتساب مباشرة على رقم الشركة نفسه الذي تعرضه بطاقة معلوماتها.
/// Why here? A visitor who has not signed in has no way to reach anyone: no open inquiry screen
/// and no visible number. The two icons dial and open WhatsApp on the very number the company card
/// displays.
class _CompanyContactBar extends StatelessWidget {
  const _CompanyContactBar({required this.phone});

  /// رقم الشركة كما هو مخزَّن — يُطبَّع داخل `ExternalLinks` (محلي أو دولي)
  /// The stored company number — normalised inside [ExternalLinks] (local or international).
  final String phone;

  @override
  Widget build(BuildContext context) {
    // حارس على مدخلات الودجت وحدها: مُرَّر الرقم من `contactPhone` فلا يكون فارغاً في الواقع،
    // لكن ودجت لا يرسم زرّاً عاطلاً أبداً مهما كان مُدخله.
    // A guard on the widget's own input: the caller passes `contactPhone`, which is never blank in
    // practice, yet the widget refuses to draw a dead button whatever it is handed.
    if (phone.trim().isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ContactIconButton(
          icon: Icon(
            FontAwesomeIcons.phone,
            size: 17,
            color: AppColors.primary,
          ),
          tooltip: 'اتصال بالشركة',
          color: AppColors.primary,
          onPressed: () => ExternalLinks.openTel(context, phone),
        ),
        const SizedBox(width: 10),
        ContactIconButton(
          // شعار واتساب الرسمي (لا فقاعة دردشة عامة)
          // The official WhatsApp mark (not a generic chat bubble).
          icon: const WhatsAppIcon(),
          tooltip: 'واتساب الشركة',
          color: AppColors.whatsapp,
          onPressed: () => ExternalLinks.openWhatsappTo(context, phone),
        ),
      ],
    );
  }
}
