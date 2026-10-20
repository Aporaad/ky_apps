import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_security_setting_model.dart';

/// صف إعداد أمان واحد: تسمية عربية + وصف + حقل تحقّق بحسب النوع
/// One security setting row: Arabic name, description, and a type-driven editor.
///
/// التحقق محلي قبل الإرسال ولا بعد الرفض: `SettingController` يرفض القيمة الخارجة عن المدى،
/// لكن ترك المستخدم يحفظ ثم يقرأ 422 يعني جلسته تحمل قيمة لم تُحفظ. هنا لا تُرسل قيمة خارج
/// `min_value`/`max_value` أصلاً، والحدود نفسها مقروءة من الخادم لا منسوخة في الواجهة.
/// Validation happens before sending: the API does reject out-of-range values, but letting the user
/// save and then read a 422 leaves them believing a value that never persisted. Out-of-range input
/// is never committed here, and the bounds are read from the server rather than copied into the UI.
class SettingTile extends StatefulWidget {
  final AppSecuritySettingModel setting;

  /// القيمة الجارية إن عُدّلت محلياً؛ null تعني لم يُمسّ بعد
  /// The in-flight value if edited; null means it has not been touched yet.
  final dynamic pendingValue;
  final bool editable;
  final ValueChanged<dynamic> onChanged;

  const SettingTile({
    required this.setting,
    required this.pendingValue,
    required this.editable,
    required this.onChanged,
    super.key,
  });

  @override
  State<SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<SettingTile> {
  final TextEditingController _ctrl = TextEditingController();
  String? _fieldError;

  dynamic get _current => widget.pendingValue ?? widget.setting.value;

  bool get _isEdited =>
      widget.pendingValue != null &&
      widget.pendingValue != widget.setting.value;

  @override
  void initState() {
    super.initState();
    _ctrl.text = _textOf(_current);
  }

  @override
  void didUpdateWidget(covariant SettingTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إعادة المزامنة فقط عند تغيّر القيمة من الخارج — بعد حفظ أو إعادة تحميل. الكتابة لا
    // تصل هنا أبداً لأن `_ctrl.text` هو مصدرها بالفعل، وأي مزامنة معها تقلب موضع المؤشر
    // Re-sync only when the value changes from outside — after a save or a reload. Typing never
    // reaches this path, since the controller already holds it; syncing there would move the caret.
    final committed = widget.setting.value;
    if (committed != oldWidget.setting.value ||
        widget.pendingValue != oldWidget.pendingValue) {
      final incoming = _textOf(_current);
      if (incoming != _ctrl.text) _ctrl.text = incoming;
      if (_fieldError != null) _fieldError = null;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.setting.nameAr.isEmpty
                                ? widget.setting.key
                                : widget.setting.nameAr,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (_isEdited) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: AppColors.warning,
                          ),
                        ],
                        if (widget.setting.isLockable) ...[
                          const SizedBox(width: 6),
                          const Tooltip(
                            message:
                                'مفتاح حسّاس: تعديله يحتاج صلاحية إدارة حسّاسة',
                            child: Icon(
                              Icons.lock_rounded,
                              size: 13,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if ((widget.setting.descriptionAr ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.setting.descriptionAr!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      widget.setting.key,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 150, child: _editor(context)),
            ],
          ),
          if (widget.setting.boundsHint != null || _fieldError != null) ...[
            const SizedBox(height: 4),
            Text(
              _fieldError ?? widget.setting.boundsHint!,
              style: TextStyle(
                fontSize: 10.5,
                color: _fieldError != null
                    ? AppColors.error
                    : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// المحرّر بحسب النوع — منطقية بمفتاح، رقمية بحقل محدود، وغير ذلك بنص حر
  /// The editor by type: bool as a switch, int as a bounded field, anything else as free text.
  Widget _editor(BuildContext context) {
    if (widget.setting.isBoolean) {
      return Switch(
        value: _asBoolValue(_current),
        onChanged: widget.editable ? (value) => widget.onChanged(value) : null,
        activeColor: AppColors.primary,
      );
    }

    return TextField(
      controller: _ctrl,
      enabled: widget.editable,
      keyboardType: widget.setting.isNumeric
          ? const TextInputType.numberWithOptions(signed: false)
          : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      textAlign: TextAlign.center,
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        errorText: _fieldError,
        suffixText: widget.setting.isNumeric ? _unitOf(widget.setting.key) : null,
        filled: true,
        fillColor: widget.editable ? Colors.white : AppColors.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isEdited ? AppColors.warning : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  void _onTextChanged(String raw) {
    if (!widget.setting.isNumeric) {
      widget.onChanged(raw.trim().isEmpty ? null : raw);

      return;
    }

    final text = raw.trim();
    final parsed = int.tryParse(text);

    // القيمة غير المقبولة لا تُعتمَد: مصفوفة التعديلات المؤقتة لا تحمل إلا صالحاً، فزر الحفظ لا
    // يرسل ما سيرفضه الخادم ولا تظهر رسالة «حُفظ» كاذبة
    // A rejected value is never committed: the pending map holds only valid entries, so saving
    // cannot send what the API would refuse, and no false «حُفظ» appears.
    final message = switch (true) {
      _ when text.isEmpty => 'القيمة مطلوبة — لا يمكن إرسال حقل فارغ',
      _ when parsed == null => 'أرقام فقط',
      _ when widget.setting.isOutOfRange(parsed) => widget.setting.boundsHint,
      _ => null,
    };

    if (message != _fieldError) setState(() => _fieldError = message);
    if (parsed != null && message == null) widget.onChanged(parsed);
  }

  String _textOf(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? '1' : '0';

    return value.toString();
  }

  bool _asBoolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().trim().toLowerCase();

    return text == '1' || text == 'true' || text == 'yes' || text == 'on';
  }
}

/// وحدة القياس العربية بحسب المفتاح — توضيح السياق لا مصدر التحقق
/// The Arabic unit for this key: context, not validation (bounds come from the server).
String _unitOf(String key) {
  if (key.endsWith('_minutes')) return 'دقيقة';
  if (key.endsWith('_days')) return 'يوم';
  if (key.endsWith('_count') || key.contains('max_')) return 'مرّة';

  return '';
}
