import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/permission_check.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/app_user_model.dart';
import '../providers/security_settings_provider.dart';
import 'permissions_picker_widget.dart';

/// نموذج إنشاء/تعديل مستخدم — نسخة واحدة للحالتين كما يفعل نموذج العميل
/// The create/edit user form — one implementation for both, as the customer form does.
///
/// النموذج يملك الحالة والتحقق ويسلّم حمولة جاهزة إلى `onSubmit`. السبب أن الخادم يعامل هذه
/// المفاتيح معاملة `sometimes`: ما لا يُرسل لا يُمسّ، فالتمييز بين «لم يتغيّر» و«تُرك فارغاً»
/// يجب أن يحدث حيث توجد الحقول وقيمها الأصلية، لا في شاشة لا ترى إلا النتيجة.
/// The form owns state and validation and hands a finished payload to onSubmit, because the API
/// treats these keys as `sometimes`: an unsent key is left untouched. Telling "unchanged" from
/// "cleared" must happen where the fields and their original values live, not in a screen that
/// only sees the outcome.
class UserFormWidget extends ConsumerStatefulWidget {
  /// null تعني إنشاء
  /// Null means create.
  final AppUserModel? existing;

  /// تعديل الذات: الخادم يرفض مفتاح النوع وراية الإدارة، فلا يُرسلا ولا يُعرضا
  /// Self-edit: the server refuses the type and admin-flag keys, so neither is sent nor offered.
  final bool isSelf;

  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final void Function(String message) onValidationError;

  const UserFormWidget({
    required this.onSubmit,
    required this.onValidationError,
    this.existing,
    this.isSelf = false,
    super.key,
  });

  bool get isCreate => existing == null;

  @override
  ConsumerState<UserFormWidget> createState() => _UserFormWidgetState();
}

class _UserFormWidgetState extends ConsumerState<UserFormWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameEnCtrl = TextEditingController();
  final TextEditingController _nameArCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _branchCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _cashAccCtrl = TextEditingController();

  late int _userType;
  late bool _isActivated;
  late bool _isAdmin;
  late bool _allowBankAcc;
  /// مفتوح بdefault مغلق: التعديل لا يرسل كلمة مرور إلا لو صرّح المستخدم بتغييرها
  /// Off by default: an edit never sends a password unless the user opts in to changing it.
  bool _changePassword = false;

  /// المنح كما يحددها المنتقي: تُرسل مع نفس الطلب فينفذها الخادم في معاملة واحدة
  /// The picker's selection: sent with the same request, so the server applies it atomically.
  late Set<String> _selected;

  /// خط أساس المنح عند الفتح — بدونه صار كل حفظ يعيد كتابة منحاً لم يمسّها أحد
  /// The grant baseline at open: without it every save rewrote grants nobody touched.
  late final Set<String> _grantBaseline;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.existing;
    _nameEnCtrl.text = user?.userNameEn ?? '';
    _nameArCtrl.text = user?.userNameAr ?? '';
    _branchCtrl.text = user?.branchNo?.toString() ?? '';
    _cashAccCtrl.text = user?.cashAccNo?.toString() ?? '';
    _noteCtrl.text = user?.note ?? '';
    _userType = user?.userType ?? 1;
    _isActivated = user?.isActivated ?? true;
    _isAdmin = user?.isAdmin ?? false;
    _allowBankAcc = user?.allowBankAcc ?? false;
    _selected = {...?user?.grantedCodes};
    _grantBaseline = {...?user?.grantedCodes};
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _branchCtrl.dispose();
    _noteCtrl.dispose();
    _cashAccCtrl.dispose();
    super.dispose();
  }

  /// هل يُطلب إدخال كلمة مرور الآن؟ الإنشاء دائماً، والتعديل فقط عند تفعيل التغيير
  /// Is a password required right now? Always on create, on edit only when a change is requested.
  bool get _passwordRequired => widget.isCreate || _changePassword;

  @override
  Widget build(BuildContext context) {
    // قرار الممنِح من نفس حالة المصادقة: من لا يملك `users.admin_flag_manage` لا يرى المفتاح،
    // ومن لا يملك صلاحية القسم لا يستطيع منحها — فلا 403 بعد عمل كامل
    // The grantor's own decisions come from the same auth state: without admin_flag_manage the
    // switch never appears, and an unheld code cannot be granted — no 403 after finished work.
    final grantor = ref.watch(
      authNotifierProvider.select((auth) => auth.permissions),
    );
    final grantorIsAdmin = ref.watch(
      authNotifierProvider.select((auth) => auth.isAdmin),
    );
    final canManageAdminFlag = canCode(
      granted: grantor,
      isAdmin: grantorIsAdmin,
      code: Perm.usersAdminFlagManage,
    );

    final minLength = _passwordMinLength();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FormSectionTitle(label: 'هوية الحساب'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nameEnCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'اسم المستخدم (لاتيني) *',
              helperText: 'الاسم الذي يُسجَّل به الدخول',
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'اسم المستخدم مطلوب';
              if (text.length < 2) return 'حرفان على الأقل';
              if (text.length > 50) return 'لا يزيد على 50 محرفاً';

              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameArCtrl,
            decoration: const InputDecoration(
              labelText: 'الاسم بالعربية',
              helperText: 'الاسم كما يظهر في القوائم',
            ),
            validator: (value) {
              if ((value ?? '').trim().length > 120) {
                return 'لا يزيد على 120 محرفاً';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          const _FormSectionTitle(label: 'الدخول'),
          const SizedBox(height: 10),
          if (!widget.isCreate)
            SwitchListTile(
              value: _changePassword,
              onChanged: (value) => setState(() => _changePassword = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'الكلمة الحالية تبقى كما هي إن لم تفعّل هذا',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
              activeColor: AppColors.primary,
            ),
          if (widget.isCreate || _changePassword) ..._passwordFields(minLength),
          const SizedBox(height: 16),
          const _FormSectionTitle(label: 'التصنيف والحالة'),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _userType,
            decoration: const InputDecoration(labelText: 'نوع الحساب'),
            items: const [
              DropdownMenuItem(value: 1, child: Text('موظف')),
              DropdownMenuItem(value: 2, child: Text('عميل')),
            ],
            onChanged: widget.isSelf ? null : (value) =>
                setState(() => _userType = value ?? 1),
          ),
          if (widget.isSelf) ...[
            const SizedBox(height: 6),
            const Text(
              'لا يمكنك تعديل نوع حسابك: الخادم يرفضه لمنع التصعيد الذاتي',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 6),
          SwitchListTile(
            value: _isActivated,
            onChanged: (value) => setState(() => _isActivated = value),
            contentPadding: EdgeInsets.zero,
            title: const Text('الحساب مفعّل', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              _isActivated
                  ? 'يستطيع الدخول واستخدام صلاحياته الممنوحة'
                  : 'لن يستطيع الدخول، وستُنهى جلساته الحالية',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
            activeColor: AppColors.success,
          ),
          if (canManageAdminFlag && !widget.isSelf) ...[
            const SizedBox(height: 4),
            PermissionGate(
              code: Perm.usersAdminFlagManage,
              child: SwitchListTile(
                value: _isAdmin,
                onChanged: (value) => setState(() => _isAdmin = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('مدير النظام', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  'تجاوز كامل لجدول المنح (قرار D1). آخر مدير في النظام لا يمكن إسقاط صفته',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                activeColor: AppColors.accent,
              ),
            ),
          ] else if (widget.existing?.isAdmin == true && !widget.isSelf) ...[
            const SizedBox(height: 4),
            const _ReadOnlyNote(
              text: 'هذا الحساب مدير نظام. لا تملك صلاحية تغيير صفة الإدارة فلم يُعرض المفتاح.',
            ),
          ],
          const SizedBox(height: 16),
          const _FormSectionTitle(label: 'بيانات إضافية'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _branchCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'رقم الفرع'),
            validator: _optionalInt('رقم الفرع يجب أن يكون رقماً غير سالب'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cashAccCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'رقم الحساب النقدي'),
            validator: _optionalInt('رقم الحساب يجب أن يكون رقماً غير سالب'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ملاحظة'),
            validator: (value) {
              if ((value ?? '').trim().length > 100) {
                return 'الملاحظة لا تزيد على 100 محرف';
              }

              return null;
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _allowBankAcc,
            onChanged: (value) => setState(() => _allowBankAcc = value),
            contentPadding: EdgeInsets.zero,
            title: const Text('السماح بالحساب المصرفي', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 18),
          PermissionsPickerWidget(
            selected: _selected,
            onToggle: _toggleCode,
            onSetMany: _setMany,
            grantorPermissions: grantor,
            grantorIsAdmin: grantorIsAdmin,
            disabled: _isAdmin,
            hint: _isAdmin
                ? 'مدير النظام يملك كل الصلاحيات تجاوزاً، فاختيار أدناه لا يغيّر شيئاً ولا يُرسل'
                : 'اختر أفعال كل قسم حسب الحاجة. الأساسيات هي العرض والإضافة والتعديل والحذف.',
          ),
          const SizedBox(height: 20),
          _SubmitBar(
            submitting: _submitting,
            isCreate: widget.isCreate,
            grantsChanged: !_sameGrants,
            willSendGrants: !_isAdmin && !_sameGrants,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  /// حقلا كلمة المرور والتأكيد — لا تغيير ضمني في وضع التعديل
  /// Password and confirmation fields — never an implicit change in edit mode.
  List<Widget> _passwordFields(int minLength) {
    return [
      const SizedBox(height: 10),
      TextFormField(
        controller: _passwordCtrl,
        obscureText: true,
        decoration: InputDecoration(
          labelText: widget.isCreate ? 'كلمة المرور *' : 'كلمة المرور الجديدة *',
          helperText: 'لا أقل من $minLength محرفاً',
        ),
        validator: (value) {
          final text = value ?? '';
          if (text.isEmpty) return _passwordRequired ? 'كلمة المرور مطلوبة' : null;
          if (text.length < minLength) {
            return 'كلمة المرور أقصر من $minLength محرفاً';
          }
          if (text.length > 100) return 'كلمة المرور طويلة جداً';

          return null;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _confirmCtrl,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور *'),
        validator: (value) {
          if (!_passwordRequired) return null;
          if ((value ?? '') != _passwordCtrl.text) {
            return 'التأكيد لا يطابق كلمة المرور';
          }

          return null;
        },
      ),
    ];
  }

  /// الحد الأدنى لكلمة المرور: يُقرأ من `settings.view` عند توفره، والأرضية 4 كحساب الخادم
  /// The password minimum: read from settings when visible, otherwise the server's own floor of 4.
  ///
  /// أرضية 4 لا منعٌ لكلمة صحيحة: `min_length` في المتحكم هو `max(4, الإعداد)`، فأي قراءة أقل
  /// من الإعداد تنتج رسالة 422 باسم الحد الحقيقي بدل أن تُحجب القيمة.
  /// Four never blocks a valid password: the controller uses max(4, setting), so a fallback below
  /// the real minimum only means the server's own 422 names the true bound.
  int _passwordMinLength() {
    for (final item in ref.watch(securitySettingsProvider).settings) {
      if (item.key == 'password_min_length') {
        final value = item.asInt;
        if (value != null && value >= 4) return value;
      }
    }

    return 4;
  }

  bool get _sameGrants =>
      _selected.length == _grantBaseline.length &&
      _selected.every(_grantBaseline.contains);

  void _toggleCode(String code) => setState(() {
    if (_selected.contains(code)) {
      _selected.remove(code);
    } else {
      _selected.add(code);
    }
  });

  void _setMany(List<String> codes, bool select) => setState(() {
    for (final code in codes) {
      if (select) {
        _selected.add(code);
      } else {
        _selected.remove(code);
      }
    }
  });

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      widget.onValidationError('أكمل الحقول الناقصة أعلاه');

      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_buildPayload());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// الحمولة بمفاتيح `snake_case` مطابقة لما يتحقق منه المتحكم فعلاً
  /// The payload keyed exactly as the controller validates it.
  ///
  /// في التعديل تُرسل المفاتيح المتغيّرة فقط، ومن بينها `permissions` فقط إن فُتح المنتقي أو
  /// غُيّر: إرسالها دائماً كان سيمسح منح مستخدمٍ لم يفتح القائمة أصلاً.
  /// In edit mode only changed keys go out — permissions included only when the selection really
  /// moved; always sending it would wipe the grants of a user whose picker never opened.
  Map<String, dynamic> _buildPayload() {
    final payload = <String, dynamic>{
      'user_name_en': _nameEnCtrl.text.trim(),
      'user_name_ar': _nameArCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
      'allow_bank_acc': _allowBankAcc ? 1 : 0,
      'is_activated': _isActivated ? 1 : 0,
    };

    final branch = _intOrNull(_branchCtrl.text);
    if (branch != null) payload['branch_no'] = branch;
    final cashAcc = _intOrNull(_cashAccCtrl.text);
    if (cashAcc != null) payload['cash_acc_no'] = cashAcc;

    if (widget.isCreate) {
      payload['user_password'] = _passwordCtrl.text;
      payload['user_type'] = _userType;
      payload['is_admin'] = _isAdmin ? 1 : 0;
      // المدير لا يحتاج منحاً: تجاوز الخادم يغطي كل شيء، ومجموعة منح فارغة أدق للمراجعة
      // An admin needs no grants: the server-side bypass covers everything, and an empty grant
      // row set is the honest audit state.
      payload['permissions'] = _isAdmin ? const <String>[] : _selected.toList();

      return payload;
    }

    final user = widget.existing!;

    if (_changePassword && _passwordCtrl.text.isNotEmpty) {
      payload['user_password'] = _passwordCtrl.text;
    }
    if (!widget.isSelf && _userType != user.userType) {
      payload['user_type'] = _userType;
    }
    if (!widget.isSelf && _isAdmin != user.isAdmin) {
      payload['is_admin'] = _isAdmin ? 1 : 0;
    }
    if (!_isAdmin && !_sameGrants) {
      payload['permissions'] = _selected.toList();
    }

    return payload;
  }

  static int? _intOrNull(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    return int.tryParse(text);
  }

  FormFieldValidator<String> _optionalInt(String message) {
    return (value) {
      final text = (value ?? '').trim();
      if (text.isEmpty) return null;
      final parsed = int.tryParse(text);
      if (parsed == null || parsed < 0) return message;

      return null;
    };
  }
}

/// عنوان قسم داخل النموذج
/// A section title inside the form.
class _FormSectionTitle extends StatelessWidget {
  final String label;

  const _FormSectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 15,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// ملاحظة تشرح حقلاً لم يُعرض: صلاحيات محدودة لا خلل في الواجهة
/// A note for a field that was not offered: limited permissions, not a broken UI.
class _ReadOnlyNote extends StatelessWidget {
  final String text;

  const _ReadOnlyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط الحفظ مع ملخص ما سيُرسل فعلياً
/// The save bar, stating what will actually be sent.
class _SubmitBar extends StatelessWidget {
  final bool submitting;
  final bool isCreate;
  final bool grantsChanged;
  final bool willSendGrants;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.submitting,
    required this.isCreate,
    required this.grantsChanged,
    required this.willSendGrants,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isCreate && !grantsChanged)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'لم تتغيّر الصلاحيات: لن يُرسل أي تعديل على المنح الحالية',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        if (!isCreate && grantsChanged && !willSendGrants)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'الحساب مدير نظام: لن تُرسل قائمة المنح لأن التجاوز يغطي كل الأفعال',
              style: TextStyle(fontSize: 11, color: AppColors.warning),
            ),
          ),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  isCreate
                      ? Icons.person_add_alt_1_rounded
                      : Icons.save_rounded,
                  size: 18,
                ),
          label: Text(
            isCreate ? 'إنشاء المستخدم' : 'حفظ التعديلات',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
