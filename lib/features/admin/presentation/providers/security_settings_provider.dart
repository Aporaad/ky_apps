import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/admin_result.dart';
import '../../data/models/app_security_setting_model.dart';
import '../../data/repositories/security_setting_repository.dart';

/// مزود مستودع إعدادات الأمان
/// Security settings repository provider.
final securitySettingRepositoryProvider = Provider<SecuritySettingRepository>((
  ref,
) {
  return SecuritySettingRepository(client: ref.watch(dioClientProvider));
});

/// حالة شاشة إعدادات الأمان
/// Security settings screen state.
class SecuritySettingsState {
  final List<AppSecuritySettingModel> settings;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? message;

  /// التعديلات المحلية قبل الحفظ: المفتاح → القيمة الجديدة
  /// Local edits before saving: key → the new value.
  final Map<String, dynamic> pending;

  const SecuritySettingsState({
    this.settings = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.message,
    this.pending = const {},
  });

  bool get isDirty => pending.isNotEmpty;

  int get pendingCount => pending.length;

  /// هل غيّرت قيمة هذا المفتاح؟ لعرض نقطة «غير محفوظ» بجانب الحقل وحده
  /// Did this key change? Drives the unsaved dot on that field only.
  bool isEdited(String key) => pending.containsKey(key);

  /// القيمة الجارية للعرض: التعديل المحلي إن وُجد، وإلا قيمة الخادم
  /// The value to render: the local edit if any, otherwise the server's value.
  dynamic currentValueOf(AppSecuritySettingModel setting) =>
      pending.containsKey(setting.key)
      ? pending[setting.key]
      : setting.value;

  SecuritySettingsState copyWith({
    List<AppSecuritySettingModel>? settings,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? message,
    Map<String, dynamic>? pending,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return SecuritySettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
      pending: pending ?? this.pending,
    );
  }
}

/// محمّل الإعدادات وحافظها — الحفظ دفعة واحدة عند الخادم
/// Loads and saves the settings — saving is one batch call server-side.
class SecuritySettingsNotifier extends Notifier<SecuritySettingsState> {
  @override
  SecuritySettingsState build() {
    Future.microtask(load);

    return const SecuritySettingsState(isLoading: true);
  }

  SecuritySettingRepository get _repo =>
      ref.read(securitySettingRepositoryProvider);

  /// تحميل كل المفاتيح — والحدود (`min_value`/`max_value`) تأتي معها من القاعدة
  /// Load every key — bounds arrive with each row from the database, never hardcoded here.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final settings = await _repo.fetchSettings();
      state = state.copyWith(
        settings: settings,
        isLoading: false,
        clearError: true,
        // أي تحميل جديد يلغي التعديلات غير المحفوظة عمداً: المرجع تغيّر
        // A fresh load drops unsaved edits deliberately — the baseline changed underneath.
        pending: const {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل إعدادات الأمان: $e',
      );
    }
  }

  /// تسجيل تعديل محلي — لا يكتب شيئاً قبل زر الحفظ
  /// Record a local edit — nothing is written until the save button.
  void edit(String key, dynamic value) {
    AppSecuritySettingModel? original;
    for (final setting in state.settings) {
      if (setting.key == key) {
        original = setting;
        break;
      }
    }
    final next = Map<String, dynamic>.from(state.pending);

    // العودة للقيمة الأصلية تمسح المفتاح من التعديلات: الحفظ لا يعيد كتابة ما لم يتغيّر
    // Reverting to the original removes the key: saving never rewrites an unchanged value.
    if (original != null && _sameValue(original.value, value)) {
      next.remove(key);
    } else {
      next[key] = value;
    }

    state = state.copyWith(pending: next, clearMessage: true);
  }

  /// تجاهل كل التعديلات المحلية
  /// Discard every local edit.
  void resetPending() =>
      state = state.copyWith(pending: const {}, clearMessage: true);

  /// حفظ الدفعة — يعيد عدد المفاتيح المغيّرة ورسالة الخادم للعرض
  /// Save the batch — returns how many keys changed, with the server's message.
  Future<AdminResult<int>> save() async {
    if (state.pending.isEmpty) {
      return const AdminResult<int>(
        success: false,
        message: 'لا تغيير لحفظه / Nothing to save',
      );
    }
    if (state.isSaving) {
      return const AdminResult<int>(
        success: false,
        message: 'الحفظ جارٍ / A save is already running',
      );
    }

    state = state.copyWith(isSaving: true, clearError: true, clearMessage: true);
    final result = await _repo.saveSettings(state.pending);

    if (result.success) {
      // إعادة تحميل بدل الدمج المحلي: الخادم قد يطبّع القيمة أو يرفض مفتاحاً مقفلاً
      // Reload rather than merge locally: the server may normalise a value or reject a locked key.
      state = state.copyWith(isSaving: false, message: result.message);
      await load();
    } else {
      state = state.copyWith(isSaving: false, error: result.displayMessage);
    }

    return result;
  }

  /// مقارنة قيمة الخادم بالتعديل المحلي للأعداد والمنطقية والنص
  /// Compare a server value against a local edit for ints, bools, and strings.
  static bool _sameValue(dynamic original, dynamic candidate) {
    if (original is num && candidate is num) {
      return original.toDouble() == candidate.toDouble();
    }
    if (original is bool || candidate is bool) {
      return (original == true) == (candidate == true);
    }

    return (original?.toString() ?? '') == (candidate?.toString() ?? '');
  }
}

final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>(
      SecuritySettingsNotifier.new,
    );
