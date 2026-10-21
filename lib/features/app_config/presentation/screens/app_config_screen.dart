import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/permission_gate.dart';
import '../../../../core/widgets/restart_widget.dart';
import '../../data/models/app_config_model.dart';
import '../../presentation/providers/app_config_notifier.dart';

/// شاشة تهيئة التطبيق: هوية الشركة + المظهر (ألوان/خط/شعار) + كلمة سر إعدادات API
/// App configuration screen: company identity + theming (colors/font/logo) + API password.
///
/// تُفتح من قسم الإعدادات خلف `app_config.update`. الاسم/الشعار ينعكسان فوراً؛ تغيير الألوان
/// أو الخط يحفظ ثم يعيد تشغيل التطبيق عبر `RestartWidget` ليشمل كل الشاشات بلا استثناء.
/// Opened from the settings section behind `app_config.update`. Name/logo apply instantly; a color
/// or font change saves then restarts the app via [RestartWidget] so every screen is covered.
class AppConfigScreen extends ConsumerStatefulWidget {
  const AppConfigScreen({super.key});

  @override
  ConsumerState<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends ConsumerState<AppConfigScreen> {
  // ── حقول النصوص / text controllers ───────────────────────
  late final TextEditingController _companyName;
  late final TextEditingController _companyNameEn;
  late final TextEditingController _companyAddress;
  late final TextEditingController _companyAddressEn;
  late final TextEditingController _companyWebsite;
  late final TextEditingController _companyPhone;
  late final TextEditingController _appName;

  // ── مفاتيح الألوان السداسية (تُحرَّر يدوياً) / hex controllers ──
  late final TextEditingController _primaryHex;
  late final TextEditingController _secondaryHex;
  late final TextEditingController _backgroundHex;
  late final TextEditingController _textPrimaryHex;
  late final TextEditingController _textSecondaryHex;

  // ── الحالة اللونية للتحديث الحيّ / live color state ───────
  late Color _primary;
  late Color _secondary;
  late Color _background;
  late Color _textPrimary;
  late Color _textSecondary;
  late String _font;

  // القيم الأصلية لحظة الفتح — لكشف هل تغيّر المظهر (يستدعي إعادة التشغيل)
  // Snapshot taken on open — to detect whether the theme changed (which needs a restart).
  late String _initialThemeSignature;

  bool _saving = false;

  static const List<String> _fallbackFonts = ['Cairo', 'Tajawal', 'Almarai', 'Amiri', 'Changa'];

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigNotifierProvider).config;

    _companyName = TextEditingController(text: config.companyName);
    _companyNameEn = TextEditingController(text: config.companyNameEn);
    _companyAddress = TextEditingController(text: config.companyAddress);
    _companyAddressEn = TextEditingController(text: config.companyAddressEn);
    _companyWebsite = TextEditingController(text: config.companyWebsite);
    _companyPhone = TextEditingController(text: config.companyPhone);
    _appName = TextEditingController(text: config.appName);

    _primary = config.primaryColor;
    _secondary = config.secondaryColor;
    _background = config.backgroundColor;
    _textPrimary = config.textPrimaryColor;
    _textSecondary = config.textSecondaryColor;
    _font = config.fontFamily;

    _primaryHex = TextEditingController(text: _hex(_primary));
    _secondaryHex = TextEditingController(text: _hex(_secondary));
    _backgroundHex = TextEditingController(text: _hex(_background));
    _textPrimaryHex = TextEditingController(text: _hex(_textPrimary));
    _textSecondaryHex = TextEditingController(text: _hex(_textSecondary));

    _initialThemeSignature = _themeSignature();
  }

  @override
  void dispose() {
    _companyName.dispose();
    _companyNameEn.dispose();
    _companyAddress.dispose();
    _companyAddressEn.dispose();
    _companyWebsite.dispose();
    _companyPhone.dispose();
    _appName.dispose();
    _primaryHex.dispose();
    _secondaryHex.dispose();
    _backgroundHex.dispose();
    _textPrimaryHex.dispose();
    _textSecondaryHex.dispose();
    super.dispose();
  }

  String _themeSignature() =>
      [_hex(_primary), _hex(_secondary), _hex(_background), _hex(_textPrimary),
        _hex(_textSecondary), _font].join('|');

  Future<void> _save() async {
    final updated = AppConfigModelBuild.fromFields(
      companyName: _companyName.text.trim(),
      companyNameEn: _companyNameEn.text.trim(),
      companyAddress: _companyAddress.text.trim(),
      companyAddressEn: _companyAddressEn.text.trim(),
      companyWebsite: _companyWebsite.text.trim(),
      companyPhone: _companyPhone.text.trim(),
      appName: _appName.text.trim(),
      primary: _primary,
      secondary: _secondary,
      background: _background,
      textPrimary: _textPrimary,
      textSecondary: _textSecondary,
      font: _font,
    );

    setState(() => _saving = true);
    final notifier = ref.read(appConfigNotifierProvider.notifier);
    final ok = await notifier.saveConfig(updated);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      final message = ref.read(appConfigNotifierProvider).errorMessage ??
          'تعذّر حفظ الإعدادات';
      _snack(message, AppColors.error);
      return;
    }

    _snack('تم حفظ إعدادات التطبيق', AppColors.success);

    // تغيير الألوان/الخط يستدعي إعادة تشغيل ليُطبَّق على كل الشاشات
    // A color/font change needs a restart to reach every screen.
    if (_themeSignature() != _initialThemeSignature) {
      final saved = ref.read(appConfigNotifierProvider).config;
      RestartWidget.restart(() => AppConfigNotifier.applyPalette(saved));
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appConfigNotifierProvider);
    final fonts = state.allowedFonts.isEmpty ? _fallbackFonts : state.allowedFonts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التطبيق'),
      ),
      body: PermissionGate(
        code: Perm.appConfigUpdate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('معلومات الشركة'),
            _textField(_companyName, 'اسم الشركة'),
            // الحقول الإنجليزية تُرسم من اليسار لأنها نص لاتيني، وتظهر في العمود
            // الأيسر من ترويسة التقارير المطبوعة.
            // The English fields are typed left-to-right: they fill the left column of the
            // printed report letterhead.
            _textField(_companyNameEn, 'اسم الشركة بالإنجليزية', ltr: true),
            _textField(_companyAddress, 'العنوان'),
            _textField(_companyAddressEn, 'العنوان بالإنجليزية', ltr: true),
            _textField(_companyWebsite, 'الموقع الإلكتروني'),
            _textField(_companyPhone, 'الهاتف', phone: true),
            _textField(_appName, 'اسم التطبيق'),

            const SizedBox(height: 24),
            _sectionTitle('الشعار'),
            _logoSection(),

            const SizedBox(height: 24),
            _sectionTitle('المظهر — الألوان'),
            _colorField('الأساسي', _primary, _primaryHex, (c, h) {
              setState(() { _primary = c; _primaryHex.text = h; });
            }),
            _colorField('الثانوي', _secondary, _secondaryHex, (c, h) {
              setState(() { _secondary = c; _secondaryHex.text = h; });
            }),
            _colorField('الخلفية', _background, _backgroundHex, (c, h) {
              setState(() { _background = c; _backgroundHex.text = h; });
            }),
            _colorField('النص الرئيسي', _textPrimary, _textPrimaryHex, (c, h) {
              setState(() { _textPrimary = c; _textPrimaryHex.text = h; });
            }),
            _colorField('النص العادي', _textSecondary, _textSecondaryHex, (c, h) {
              setState(() { _textSecondary = c; _textSecondaryHex.text = h; });
            }),

            const SizedBox(height: 16),
            _sectionTitle('الخط'),
            _fontField(fonts),

            const SizedBox(height: 24),
            _sectionTitle('كلمة سر إعدادات API'),
            const _ApiPasswordSection(),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ الإعدادات'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool phone = false,
    bool ltr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: phone ? TextInputType.phone : TextInputType.text,
        // النص اللاتيني يحتاج اتجاهًا صريحًا وإلا ورَدَ مقلوبًا داخل واجهة RTL
        // Latin text needs an explicit direction, otherwise it renders mirrored in an RTL app.
        textDirection: ltr ? TextDirection.ltr : null,
        inputFormatters: phone
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))]
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _logoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const AppLogo(width: 180, height: 120),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await ref
                      .read(appConfigNotifierProvider.notifier)
                      .pickAndSaveLogo();
                  if (!mounted) return;
                  _snack(
                    ok ? 'تم تحديث الشعار' : 'لم يتم اختيار صورة',
                    ok ? AppColors.success : AppColors.warning,
                  );
                },
                icon: const Icon(Icons.image_rounded),
                label: const Text('اختيار شعار'),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () async {
                await ref.read(appConfigNotifierProvider.notifier).resetLogo();
                if (!mounted) return;
                _snack('أُعيد الشعار الافتراضي', AppColors.info);
              },
              child: const Text('افتراضي'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _colorField(
    String label,
    Color current,
    TextEditingController hexController,
    void Function(Color, String) onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              // مربع المعاينة — الضغط يفتح لوحة الألوان الجاهزة
              // Preview swatch — tap opens the preset picker.
              InkWell(
                onTap: () => _pickPreset(label, onChange),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: current,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: hexController,
                  maxLength: 7,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
                  ],
                  onChanged: (v) {
                    final color = AppPalette.parseHex(v, current);
                    setState(() {}); // تحديث المعاينة / refresh preview
                    onChange(color, _hex(color));
                  },
                  decoration: const InputDecoration(
                    hintText: '#RRGGBB',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// لوحة ألوان جاهزة — بدون حزمة إضافية، تلتزم بالقاعدة «بلا اعتماديات زائدة»
  /// A preset color sheet — no extra package, honoring the "no needless deps" rule.
  void _pickPreset(
    String label,
    void Function(Color, String) onChange,
  ) {
    const presets = <Color>[
      Color(0xFFA27E4E), Color(0xFF0D9488), Color(0xFFF8FAFC), Color(0xFF0F172A),
      Color(0xFF475569), Color(0xFF7C2D12), Color(0xFF1D4ED8), Color(0xFF15803D),
      Color(0xFFB91C1C), Color(0xFF7E22CE), Color(0xFFEA580C), Color(0xFFFFFFFF),
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final color in presets)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onChange(color, _hex(color));
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fontField(List<String> fonts) {
    return DropdownButtonFormField<String>(
      value: _font,
      decoration: const InputDecoration(labelText: 'عائلة الخط'),
      items: [
        for (final f in fonts)
          DropdownMenuItem<String>(value: f, child: Text(f)),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _font = value);
      },
    );
  }

  /// تحويل `Color` إلى سداسي `#RRGGBB`大写 للاستعراض والتخزين
  /// Convert a [Color] to an uppercase `#RRGGBB` string for display and storage.
  static String _hex(Color color) {
    // r/g/b doubles في هذا الإصدار — ضرب في 255 مع تقريب
    // r/g/b are doubles in this SDK — scale by 255 with rounding.
    String two(double v) =>
        (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return ('#${two(color.r)}${two(color.g)}${two(color.b)}').toUpperCase();
  }
}

/// جسر بناء نموذج التهيئة من الحقول الخام — يبقي منطق الشاشة منعزلاً عن النموذج
/// Builds the config model from raw field values — keeps the screen logic off the model.
class AppConfigModelBuild {
  AppConfigModelBuild._();

  static AppConfigModel fromFields({
    required String companyName,
    required String companyNameEn,
    required String companyAddress,
    required String companyAddressEn,
    required String companyWebsite,
    required String companyPhone,
    required String appName,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color textPrimary,
    required Color textSecondary,
    required String font,
  }) {
    // نمرّر عبر hex موحّد حتى يلتقط النموذج القيم بدقة كما يراها المستخدم
    // Round-trip through a normalized hex so the model captures exactly what the user sees.
    String hex(Color c) {
      String two(double v) =>
          (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      return '#${two(c.r)}${two(c.g)}${two(c.b)}';
    }

    return AppConfigModel.fromJson({
      'company_name': companyName,
      'company_name_en': companyNameEn,
      'company_address': companyAddress,
      'company_address_en': companyAddressEn,
      'company_website': companyWebsite,
      'company_phone': companyPhone,
      'app_name': appName,
      'theme_primary_color': hex(primary),
      'theme_secondary_color': hex(secondary),
      'theme_background_color': hex(background),
      'theme_text_primary_color': hex(textPrimary),
      'theme_text_secondary_color': hex(textSecondary),
      'theme_font_family': font,
    });
  }
}

/// قسم تغيير كلمة سر إعدادات API — يظهر فقط لحامل `app_config.api_manage`
/// API-settings password section — visible only to holders of `app_config.api_manage`.
class _ApiPasswordSection extends ConsumerStatefulWidget {
  const _ApiPasswordSection();

  @override
  ConsumerState<_ApiPasswordSection> createState() => _ApiPasswordSectionState();
}

class _ApiPasswordSectionState extends ConsumerState<_ApiPasswordSection> {
  final _newPassword = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _newPassword.text;
    if (value.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمة السر قصيرة جداً (4 أحرف على الأقل)')),
      );
      return;
    }
    setState(() => _busy = true);
    final ok =
        await ref.read(appConfigNotifierProvider.notifier).setApiPassword(value);
    if (!mounted) return;
    setState(() => _busy = false);
    _newPassword.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم تحديث كلمة سر إعدادات API' : 'تعذّر تحديث كلمة السر'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      code: Perm.appConfigApiManage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة سر جديدة لإعدادات API'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _submit,
            icon: const Icon(Icons.lock_rounded),
            label: Text(_busy ? 'جارٍ التحديث…' : 'تغيير كلمة السر'),
          ),
        ],
      ),
    );
  }
}
