import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/api_config_notifier.dart';

/// شاشة إعدادات خادم الـ API فقط
/// تُعرض من شاشة تسجيل الدخول ومن قسم الإعدادات (تبويبة API)
/// لا تحتوي على أي إعدادات أخرى (البصمة والمظهر موجودة في قسم الإعدادات الرئيسي)
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
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    if (!_isDirty && mounted) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  // فحص الاتصال
  // ──────────────────────────────────────────────
  Future<void> _handleTestConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnack('يرجى إدخال رابط الـ API أولاً', AppColors.warning);
      return;
    }
    await ref.read(apiConfigNotifierProvider.notifier).testConnection(url);
  }

  // ──────────────────────────────────────────────
  // حفظ الإعدادات
  // ──────────────────────────────────────────────
  Future<void> _showConfirmationAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    final targetUrl = _urlController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmChangeDialog(targetUrl: targetUrl),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(apiConfigNotifierProvider.notifier)
          .saveApiUrl(targetUrl);

      if (success && mounted) {
        setState(() => _isDirty = false);
        _showSnack('تم حفظ رابط الـ API الجديد بنجاح ✓', AppColors.success);
      }
    }
  }

  // ──────────────────────────────────────────────
  // إعادة الضبط إلى الافتراضي
  // ──────────────────────────────────────────────
  Future<void> _handleResetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('استعادة الرابط الافتراضي'),
        content: const Text(
          'هل تريد إعادة تعيين رابط الـ API إلى الرابط الافتراضي؟',
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

    if (confirmed == true && mounted) {
      await ref.read(apiConfigNotifierProvider.notifier).resetToDefault();
      _urlController.text = ApiConstants.defaultBaseUrl;
      setState(() => _isDirty = false);
      _showSnack('تمت استعادة رابط الـ API الافتراضي', AppColors.info);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(apiConfigNotifierProvider);
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final isNarrow = size.width < 600;
    final hPad = isNarrow ? 16.0 : 24.0;
    final scaledTitle = textScaler.scale(isNarrow ? 16.0 : 18.0).clamp(13.0, 22.0);
    final scaledLabel = textScaler.scale(isNarrow ? 13.0 : 14.0).clamp(11.0, 18.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          tooltip: 'رجوع',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'إعدادات خادم API',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: scaledTitle,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
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
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── بطاقة المعلومات ──────────────────────────
                  _InfoCard(textScaler: textScaler, isNarrow: isNarrow),
                  const SizedBox(height: 18),

                  // ── البطاقة الرئيسية لإدخال الرابط ──────────
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // عنوان البطاقة
                          Row(
                            children: [
                              Icon(
                                Icons.dns_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'عنوان الـ API الأساسي (Base URL)',
                                  style: TextStyle(
                                    fontSize: scaledLabel,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // حقل الإدخال
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _urlController,
                              style: TextStyle(
                                fontSize: textScaler.scale(13.5).clamp(11.0, 17.0),
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'http://192.168.0.11:8000/api',
                                hintStyle: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: textScaler.scale(12.5).clamp(10.0, 16.0),
                                  color: AppColors.textMuted,
                                ),
                                prefixIcon: Icon(
                                  Icons.link_rounded,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: _urlController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 17),
                                        onPressed: () {
                                          _urlController.clear();
                                          setState(() => _isDirty = true);
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'يرجى إدخال عنوان خادم الـ API';
                                }
                                final t = val.trim();
                                if (!t.startsWith('http://') &&
                                    !t.startsWith('https://')) {
                                  return 'يجب أن يبدأ العنوان بـ http:// أو https://';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // اختصارات سريعة
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _QuickChip(
                                icon: Icons.refresh,
                                label: 'الافتراضي',
                                onTap: () {
                                  _urlController.text = ApiConstants.defaultBaseUrl;
                                  setState(() => _isDirty = true);
                                },
                              ),
                              _QuickChip(
                                icon: Icons.computer,
                                label: '127.0.0.1',
                                onTap: () {
                                  _urlController.text = 'http://127.0.0.1:8000/api';
                                  setState(() => _isDirty = true);
                                },
                              ),
                              _QuickChip(
                                icon: Icons.phone_android,
                                label: '10.0.2.2',
                                onTap: () {
                                  _urlController.text = 'http://10.0.2.2:8000/api';
                                  setState(() => _isDirty = true);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // زر الفحص
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: state.isTesting ? null : _handleTestConnection,
                            icon: state.isTesting
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.wifi_find_rounded),
                            label: Text(
                              state.isTesting
                                  ? 'جاري فحص الاتصال...'
                                  : 'فحص الاتصال بالخادم',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // نتيجة الفحص
                          if (state.testResult != null) ...[
                            const SizedBox(height: 12),
                            _TestResultCard(result: state.testResult!),
                          ],

                          const Divider(height: 28),

                          // زر الحفظ
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: state.isSaving ? null : _showConfirmationAndSave,
                            icon: state.isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              state.isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── الرابط النشط حالياً ───────────────────────
                  _ActiveUrlCard(activeUrl: state.activeApiUrl, textScaler: textScaler),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// بطاقة المعلومات
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final TextScaler textScaler;
  final bool isNarrow;

  const _InfoCard({required this.textScaler, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final scaledText = textScaler.scale(isNarrow ? 12.0 : 12.5).clamp(10.0, 16.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(              
              'اكتب الرابط بالصيغة: http://ip:port/api\nمثال: http://192.168.1.1:8000/api',
              style: TextStyle(
                fontSize: scaledText-5,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// اختصار سريع للرابط
// ─────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─────────────────────────────────────────────
// بطاقة نتيجة الفحص
// ─────────────────────────────────────────────
class _TestResultCard extends StatelessWidget {
  final dynamic result;

  const _TestResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = result.success as bool;
    final Color color = isSuccess ? AppColors.success : AppColors.error;
    final IconData icon =
        isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess ? 'نجح الاتصال بالخادم' : 'فشل الاتصال بالخادم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
              if (result.latencyMs != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const SizedBox(height: 6),
          Text(
            result.message as String,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
          if (!isSuccess) ...[
            const SizedBox(height: 6),
            Text(
              'تأكد من تشغيل الخادم واتصال الشبكة.',
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

// ─────────────────────────────────────────────
// بطاقة الرابط النشط
// ─────────────────────────────────────────────
class _ActiveUrlCard extends StatelessWidget {
  final String activeUrl;
  final TextScaler textScaler;

  const _ActiveUrlCard({required this.activeUrl, required this.textScaler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 16),
              SizedBox(width: 6),
              Text(
                'الرابط النشط حالياً:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              activeUrl,
              style: TextStyle(
                fontSize: textScaler.scale(11.5).clamp(9.5, 15.0),
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
    );
  }
}

// ─────────────────────────────────────────────
// حوار تأكيد تغيير الرابط
// ─────────────────────────────────────────────
class _ConfirmChangeDialog extends StatelessWidget {
  final String targetUrl;

  const _ConfirmChangeDialog({required this.targetUrl});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'تأكيد التغيير',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              '⚠️ تنبيه:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تغيير رابط الـ API سيؤثر على جميع عمليات التطبيق فوراً.\n'
              'في حال كان الرابط غير صحيح، لن تتمكن من تسجيل الدخول.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      targetUrl,
                      style: TextStyle(
                        fontSize: 11.5,
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('إلغاء',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('تأكيد وحفظ'),
        ),
      ],
    );
  }
}
