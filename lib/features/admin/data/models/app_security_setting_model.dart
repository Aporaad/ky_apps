import '../../../../core/utils/json_value_utils.dart';

/// إعداد أمان واحد من `GET /settings`
/// One security setting from `GET /settings`.
///
/// القيم لا تُخزَّن منطقياً في الواجهة: `value` يصل مطابقاً لـ `value_type` بعد تطبيع
/// `SettingsStore`، وحدود التحقق (`min_value`/`max_value`) تأتي معه في نفس الصف. سبب ذلك أن
/// هذه الحدود بذورها الخادم في المرحلة 1، فأ أي نسخة محلية كانت ستسمح بحفظ قيمة يرفضها الخادم
/// أو بحجب مدى أوسع من الواقع.
/// Values and bounds come from the server, not a client copy: `value` already matches `value_type`
/// after SettingsStore normalises it, and MIN/MAX ride in the same row. Hardcoding them here would
/// let the UI accept what the API rejects, or block a range the API allows.
class AppSecuritySettingModel {
  final int settingId;

  /// مفتاح الإعداد كما في `APP_SETTINGS.KEY_CODE` (`session_idle_minutes`)
  /// The setting key as stored in APP_SETTINGS (`session_idle_minutes`).
  final String key;
  final String nameAr;
  final String? descriptionAr;

  /// نوع القيمة: `int` أو `bool` أو `string` أو `json`
  /// Value type: int, bool, string, or json.
  final String valueType;

  /// القيمة بعد التطبيع: عدد أو منطقية أو نص بحسب `valueType`
  /// The normalised value: num, bool, or String depending on [valueType].
  final dynamic value;

  /// القيمة الخام كما في القاعدة — تُعرض عند الفشل في التحويل حتى لا تختفي بيانات المفاتيح
  /// The raw stored value, kept so an unparseable value is visible instead of silently vanishing.
  final String? rawValue;
  final int? minValue;
  final int? maxValue;

  /// مفتاح مقفل: تعديلُه يحتاج `settings.security_manage` لا `settings.update`
  /// A locked key: changing it needs settings.security_manage, not plain settings.update.
  final bool isLockable;
  final int sortOrder;
  final int? updatedBy;
  final DateTime? updatedOn;

  const AppSecuritySettingModel({
    required this.settingId,
    required this.key,
    required this.nameAr,
    this.descriptionAr,
    required this.valueType,
    this.value,
    this.rawValue,
    this.minValue,
    this.maxValue,
    this.isLockable = false,
    this.sortOrder = 0,
    this.updatedBy,
    this.updatedOn,
  });

  bool get isNumeric => valueType == 'int';

  bool get isBoolean => valueType == 'bool';

  /// النص المعروض للقيمة الحالية في الحقل
  /// The text shown in the field for the current value.
  String get displayValue {
    if (isBoolean) return asBool ? 'مُفعّل' : 'معطّل';
    if (value == null) return rawValue ?? '';

    return value.toString();
  }

  /// القيمة كمنطقية بأمان — أي قراءة غير صريحة تعني false
  /// The value as a bool, safely — anything not explicitly truthy is false.
  bool get asBool => JsonValues.asBool(value);

  /// القيمة كعدد صحيح بأمان، أو null لو لم تكن رقمية
  /// The value as an int, or null when it isn't numeric.
  int? get asInt => JsonValues.asIntOrNull(value);

  /// تلميح الحدود أسفل الحقل: «بين 5 و10080» أو null للمفاتيح بلا مدى
  /// Bounds hint under the field: «بين 5 و10080», or null for keys with no range.
  String? get boundsHint {
    if (!isNumeric) return null;
    final min = minValue;
    final max = maxValue;
    if (min != null && max != null) return 'السماح بين $min و $max';
    if (min != null) return 'الحد الأدنى $min';
    if (max != null) return 'الحد الأعلى $max';

    return null;
  }

  /// هل هذه القيمة خارج الحدود المعلنة؟ التحقق المحلي يسبق الإرسال لتفادي رحلة ذهاب وعودة
  /// Is this value outside the declared bounds? Local validation avoids a wasted round-trip.
  bool isOutOfRange(num? candidate) {
    if (!isNumeric || candidate == null) return false;
    if (minValue != null && candidate < minValue!) return true;
    if (maxValue != null && candidate > maxValue!) return true;

    return false;
  }

  factory AppSecuritySettingModel.fromJson(Map<String, dynamic> json) {
    final type =
        JsonValues.asText(json['value_type'] ?? json['VALUE_TYPE']) ?? 'string';

    return AppSecuritySettingModel(
      settingId: JsonValues.asInt(json['setting_id'] ?? json['SETTING_ID']),
      key: JsonValues.textOrEmpty(json['key'] ?? json['KEY']),
      nameAr: JsonValues.arabicOrEmpty(json['name_ar'] ?? json['NAME_AR']),
      descriptionAr: JsonValues.asArabic(
        json['description_ar'] ?? json['DESCRIPTION_AR'],
      ),
      valueType: type,
      // القيمة التطبيعية تأتي جاهزة من الخادم، فيُعاد نوعها حسب النوع المعلن فقط
      // The server already casts the value; the client only re-reads it per the declared type.
      value: _castValue(json['value'] ?? json['VALUE'], type),
      rawValue: JsonValues.asText(json['raw_value'] ?? json['RAW_VALUE']),
      minValue: JsonValues.asIntOrNull(json['min_value'] ?? json['MIN_VALUE']),
      maxValue: JsonValues.asIntOrNull(json['max_value'] ?? json['MAX_VALUE']),
      isLockable: JsonValues.asBool(json['is_lockable'] ?? json['IS_LOCKABLE']),
      sortOrder: JsonValues.asInt(json['sort_order'] ?? json['SORT_ORDER']),
      updatedBy: JsonValues.asIntOrNull(json['updated_by'] ?? json['UPDATED_BY']),
      updatedOn: JsonValues.asDate(json['updated_on'] ?? json['UPDATED_ON']),
    );
  }

  /// تطابق محلي لـ `SettingsStore::cast()` حتى يظل الحقل قادراً على عرض قيمته
  /// Mirrors `SettingsStore::cast()` so the field can always render its own value.
  static dynamic _castValue(dynamic raw, String type) {
    if (raw == null) return null;

    switch (type) {
      case 'int':
        return JsonValues.asIntOrNull(raw);
      case 'bool':
        return JsonValues.asBool(raw);
      default:
        return JsonValues.asText(raw) ?? raw;
    }
  }

  Map<String, dynamic> toJson() => {
    'setting_id': settingId,
    'key': key,
    'name_ar': nameAr,
    'description_ar': descriptionAr,
    'value_type': valueType,
    'value': value,
    'raw_value': rawValue,
    'min_value': minValue,
    'max_value': maxValue,
    'is_lockable': isLockable,
    'sort_order': sortOrder,
  };

  /// نسخة بقيمة معدّلة محلياً — الحقل المرسل للتحقق قبل الحفظ
  /// A copy with a locally edited value — the field state before saving.
  AppSecuritySettingModel withValue(dynamic newValue) {
    return AppSecuritySettingModel(
      settingId: settingId,
      key: key,
      nameAr: nameAr,
      descriptionAr: descriptionAr,
      valueType: valueType,
      value: _castValue(newValue, valueType),
      rawValue: rawValue,
      minValue: minValue,
      maxValue: maxValue,
      isLockable: isLockable,
      sortOrder: sortOrder,
      updatedBy: updatedBy,
      updatedOn: updatedOn,
    );
  }
}
