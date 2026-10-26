import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/biometric_service.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../app_config/presentation/providers/app_config_notifier.dart';
import '../providers/auth_notifier.dart';
import '../widgets/api_password_dialog.dart';
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

  /// بوابة كلمة السر لإعدادات الـ API من شاشة الدخول: تحقق ثم افتح الشاشة إن نجح
  /// API-settings password gate from the login screen: verify first, then open on success.
  Future<void> _openApiSettingsWithGate() async {
    final allowed = await ApiPasswordDialog.show(context);
    if (allowed && mounted) {
      context.push('/api-settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    // اسم الشركة من التهيئة — ينعكس فوراً على شاشة الدخول
    // Company name from config — reflects on the login screen immediately.
    final companyName =
        ref.watch(appConfigNotifierProvider.select((s) => s.config.companyName));

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              // اللون ديناميكي الآن — لا يصلح const على Icon
              // The color is dynamic now — no const on Icon.
              icon: const Icon(Icons.settings_outlined),
              color: AppColors.textSecondary,
              tooltip: 'إعدادات خادم الـ API',
              onPressed: () => _openApiSettingsWithGate(),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          // dragStartBehavior:  DragStartBehavior.down,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
                // side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
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
                            width: 250,
                            height: 170,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                      const SizedBox(height: 8),
                      Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'أدخل بيانات حسابك للمتابعة إلى النظام',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // محدد نوع المستخدم (موظف / عميل)
                      UserTypeSelector(
                        selectedType: authState.selectedUserType,
                        onTypeChanged: (type) {
                          ref
                              .read(authNotifierProvider.notifier)
                              .setUserType(type);
                        },
                      ),
                      const SizedBox(height: 24),

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
                        const SizedBox(height: 16),
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
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 28),

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
