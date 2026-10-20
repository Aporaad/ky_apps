import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_user_model.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/user_form_widget.dart';

/// شاشة نموذج المستخدم — أساس الإنشاء والتعديل معاً
/// The user form screen — the single basis for both create and edit.
///
/// عند التعديل تُقرأ تفاصيل المستخدم من `GET /users/{id}` قبل رسم النموذج: صفوف القائمة لا
/// تحمل `granted_codes`، ولو بُني النموذج على صف قائمة لظهرت كل المنح فارغة ثم مُسحت كلها
/// عند أول حفظ. هذا الفرق بين «لا شيء ممنوح» و«لم نُحمّل بعد» هو سبب التحميل هنا لا في القائمة.
/// On edit the detail row is fetched first, because list rows carry no granted_codes — building
/// the form from one would show zero grants and then wipe every grant on the first save.
class UserFormScreen extends ConsumerStatefulWidget {
  /// null تعني إنشاء مستخدم جديد
  /// Null means creating a new user.
  final AppUserModel? existing;

  const UserFormScreen({super.key, this.existing});

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  AppUserModel? _detail;
  bool _loadingDetail = false;
  String? _loadError;
  String? _banner;
  bool _saved = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final source = widget.existing;
    // صفوف القائمة تأتي بلا منح: التفاصيل مطلوبة قبل رسم النموذج
    // List rows arrive without grants, so the detail must be loaded before the form renders.
    if (source != null && !source.hasGrantDetail) {
      _loadingDetail = true;
      Future.microtask(() => _loadDetail(source.userId));
    } else {
      _detail = source;
    }
  }

  Future<void> _loadDetail(int userId) async {
    try {
      final detail = await ref.read(adminUserRepositoryProvider).fetchUser(userId);
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _detail = detail;
        _loadError = detail == null ? 'لم يُعثر على المستخدم / User not found' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _loadError = 'تعذّر تحميل المستخدم: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(
      authNotifierProvider.select((auth) => auth.user?.id),
    );
    final isSelf = _isEdit && currentUserId == widget.existing!.userId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مستخدم' : 'مستخدم جديد'),
      ),
      body: SafeArea(
        child: _loadingDetail
            ? const Center(child: CircularProgressIndicator())
            : _body(isSelf: isSelf),
      ),
    );
  }

  Widget _body({required bool isSelf}) {
    if (_loadError != null) {
      return _LoadFailure(message: _loadError!, onRetry: () {
        final id = widget.existing?.userId;
        if (id == null) return;
        setState(() {
          _loadingDetail = true;
          _loadError = null;
        });
        _loadDetail(id);
      });
    }

    final detail = _detail;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        if (_banner != null) ...[
          _FormBanner(message: _banner!, onClose: () => setState(() => _banner = null)),
          const SizedBox(height: 12),
        ],
        UserFormWidget(
          // مفتاح بالقيمة: يعيد بناء النموذج عند إعادة تحميل التفاصيل حتى لا تبقى الحقول
          // ببيانات قديمة بعد محاولة فاشلة ثم نجاح
          // Value key: the form rebuilds when the detail reloads, so stale field values cannot
          // survive a failed-then-retried load.
          key: ValueKey(detail?.userId ?? 'create'),
          existing: detail,
          isSelf: isSelf,
          onValidationError: (message) => setState(() => _banner = message),
          onSubmit: (payload) => _submit(payload, isSelf: isSelf),
        ),
      ],
    );
  }

  /// الإرسال فعلاً: يكتب عند الخادم، ثم يغلق الشاشة عند النجاح فقط
  /// The actual submit: writes server-side, then closes the screen only on success.
  Future<void> _submit(Map<String, dynamic> payload, {required bool isSelf}) async {
    final repo = ref.read(adminUserRepositoryProvider);
    final id = widget.existing?.userId;
    final result = id == null
        ? await repo.createUser(payload)
        : await repo.updateUser(id, payload);

    if (!mounted || _saved) return;

    if (!result.success) {
      // رسالة الخادم تُعرض كما هي: 409 يقول «الاسم مستخدم» و403 يسمّي الصلاحية الناقصة،
      // وأي صياغة محلية كانت ستخفي القرار الأمني بدل أن تشرحه
      // The server text is shown verbatim: 409 names the taken username and 403 names the missing
      // code, while any local rewording would hide the security decision instead of explaining it.
      setState(() => _banner = result.displayMessage);

      return;
    }

    _saved = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message.trim().isEmpty ? 'تم الحفظ' : result.message.trim()),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }
}

/// شريط خطأ النموذج — فوق الحقول مباشرة لأن السبب قد يكون اسمًا مكرراً أو رفض صلاحية
/// The form error banner, above the fields since the cause is usually a taken name or a denial.
class _FormBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _FormBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

/// تعذّر تحميل صف التفاصيل — إعادة المحاولة أرخص من نموذج ينشأ على بيانات ناقصة
/// The detail row failed to load — retrying beats a form built on missing data.
class _LoadFailure extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailure({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
