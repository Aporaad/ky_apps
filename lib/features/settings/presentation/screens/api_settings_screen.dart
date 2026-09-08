import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/api_config_notifier.dart';

/// شاشة إعدادات والتحكم برابط Laravel API
class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final activeUrl = ref.read(apiConfigNotifierProvider).activeApiUrl;
    _urlController = TextEditingController(text: activeUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// فحص الاتصال بالعنوان المكتوب
  Future<void> _handleTestConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رابط الـ API أولاً قبل الفحص'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    await ref.read(apiConfigNotifierProvider.notifier).testConnection(url);
  }

  /// حوار تأكيد التغيير والتحذير بمخاطر التغيير
  Future<void> _showConfirmationAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    final targetUrl = _urlController.text.trim();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تأكيد التغيير والتحذير بمخاطر التغيير',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ تنبيه تقني هام:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تغيير عنوان خادم الـ API سيؤدي إلى توجيه كافة عمليات النظام (تسجيل الدخول، التحقق، المزامنة، واسترجاع البيانات) إلى العنوان الجديد فوراً.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'في حال كان العنوان غير صالح أو الخادم غير مستجيب، فلن تتمكن من تسجيل الدخول أو استخدام التطبيق.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetUrl,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          textDirection: TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'هل أنت متأكد من رغبتك في اعتماد وتطبيق هذا التغيير؟',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'إلغاء الأمر',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('تأكيد وتطبيق التغيير'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(apiConfigNotifierProvider.notifier)
          .saveApiUrl(targetUrl);

      if (success && mounted) {
        setState(() {
          _isDirty = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم حفظ وتطبيق رابط الـ API الجديد بنجاح في التطبيق',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// إعادة تعيين للعنوان الافتراضي
  Future<void> _handleResetToDefault() async {
    final bool? confirmReset = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('استعادة الإعداد الافتراضي'),
            content: const Text(
              'هل تريد إعادة تعيين رابط الـ API إلى الرابط الافتراضي للمشروع؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('استعادة'),
              ),
            ],
          ),
    );

    if (confirmReset == true && mounted) {
      await ref.read(apiConfigNotifierProvider.notifier).resetToDefault();
      _urlController.text = ApiConstants.defaultBaseUrl;
      setState(() {
        _isDirty = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت استعادة رابط الـ API الافتراضي بنجاح'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiConfigNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'إعدادات خادم API',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
          tooltip: 'رجوع',
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'استعادة الرابط الافتراضي',
            onPressed: state.isSaving ? null : _handleResetToDefault,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة التوضيح والمعلومات
                  Card(
                    elevation: 0,
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'يمكنك من هذه الشاشة تغيير عنوان خادم الـ API وفحص الاتصال به قبل اعتماده، لتسهيل التبديل بين بيئات التطوير، الشبكة المحلية، أو الخادم السحابي. \n تاكد من كتابه الرابط بالصيغة [https://ip:port/api] كلمه /api  مهمة ',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // بطاقة الإعدادات الرئيسية
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.dns_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'عنوان رابط الـ API الأساسي (Base URL)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // حقل إدخال الرابط
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _urlController,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'http://192.168.0.11:8000/api',
                                hintStyle: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                                prefixIcon: const Icon(
                                  Icons.link_rounded,
                                  color: AppColors.primary,
                                ),
                                suffixIcon:
                                    _urlController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _urlController.clear();
                                            setState(() => _isDirty = true);
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                if (!_isDirty) {
                                  setState(() => _isDirty = true);
                                }
                              },
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال عنوان خادم الـ API';
                                }
                                final trimmed = val.trim();
                                if (!trimmed.startsWith('http://') &&
                                    !trimmed.startsWith('https://')) {
                                  return 'يجب أن يبدأ العنوان بـ http:// أو https://';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // اختصارات سريعة للعناوين الشائعة
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.refresh, size: 16),
                                label: const Text('الافتراضي'),
                                onPressed: () {
                                  _urlController.text =
                                      ApiConstants.defaultBaseUrl;
                                  setState(() => _isDirty = true);
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.computer, size: 16),
                                label: const Text('127.0.0.1 (محلي)'),
                                onPressed: () {
                                  _urlController.text =
                                      'http://127.0.0.1:8000/api';
                                  setState(() => _isDirty = true);
                                },
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.phone_android,
                                  size: 16,
                                ),
                                label: const Text('10.0.2.2 (محاكي)'),
                                onPressed: () {
                                  _urlController.text =
                                      'http://10.0.2.2:8000/api';
                                  setState(() => _isDirty = true);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // زر فحص الاتصال
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                state.isTesting ? null : _handleTestConnection,
                            icon:
                                state.isTesting
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                    : const Icon(Icons.wifi_find_rounded),
                            label: Text(
                              state.isTesting
                                  ? 'جاري فحص الاتصال بالخادم...'
                                  : 'فحص الاتصال بالخادم (Test Connection)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // عرض نتيجة فحص الاتصال
                          if (state.testResult != null) ...[
                            _buildTestResultCard(state.testResult!),
                            const SizedBox(height: 16),
                          ],

                          const Divider(height: 28),

                          // زر حفظ الإعدادات مع الحوار التحذيري
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                state.isSaving
                                    ? null
                                    : _showConfirmationAndSave,
                            icon:
                                state.isSaving
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(Icons.save_rounded),
                            label: Text(
                              state.isSaving
                                  ? 'جاري الحفظ والتطبيق...'
                                  : 'حفظ الإعدادات',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // تفاصيل الرابط المطبق حالياً
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'الرابط النشط حالياً في النظام:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.activeApiUrl,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقة عرض تفاصيل نتيجة فحص الاتصال
  Widget _buildTestResultCard(dynamic result) {
    final bool isSuccess = result.success;
    final Color color = isSuccess ? AppColors.success : AppColors.error;
    final IconData icon =
        isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                isSuccess ? 'نجح الاتصال بالخادم!' : 'فشل الاتصال بالخادم!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
              const Spacer(),
              if (result.latencyMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${result.latencyMs} ms',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (!isSuccess) ...[
            const SizedBox(height: 8),
            const Text(
              'نصائح للحل: تأكد من تشغيل خادم \nوتأكد من اتصال الشبكه.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
