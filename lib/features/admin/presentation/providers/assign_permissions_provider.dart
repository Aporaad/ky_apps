import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/admin_result.dart';
import '../../data/repositories/permission_repository.dart';
import 'admin_permissions_catalog_provider.dart';

/// حالة شاشة منح الصلاحيات
/// State of the grant-permissions screen.
class AssignPermissionsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? saveError;
  final UserGrants? user;

  /// التحديد الجاري — أكواد حرفية كما ستُرسل للخادم
  /// The working selection — literal codes exactly as they will be sent.
  final Set<String> selected;

  /// نقطة المرجع بعد التحميل أو بعد آخر حفظ، منها تُحسب «تغيّر شيء؟»
  /// The baseline after loading or the last save; dirty-ness is measured against it.
  final Set<String> baseline;

  const AssignPermissionsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.saveError,
    this.user,
    this.selected = const {},
    this.baseline = const {},
  });

  /// هل غيّر المستخدم شيئاً؟ يمنع الإغلاق بلا حفظ ويُفعّل زر الحفظ
  /// Did anything change? Guards the back navigation and enables the save button.
  bool get isDirty => !_sameSet(selected, baseline);

  int get selectedCount => selected.length;

  bool isSelected(String code) => selected.contains(code);

  AssignPermissionsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? saveError,
    UserGrants? user,
    Set<String>? selected,
    Set<String>? baseline,
    bool clearError = false,
  }) {
    return AssignPermissionsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      saveError: clearError ? null : saveError ?? this.saveError,
      user: user ?? this.user,
      selected: selected ?? this.selected,
      baseline: baseline ?? this.baseline,
    );
  }

  /// مقارنة مجموعتين من غير ترتيب — `Set.equals` غير موجود في Dart
  /// Compare two sets ignoring order — Dart has no Set.equals.
  static bool _sameSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }

    return true;
  }
}

/// مُحمِّل منح مستخدم وتبديلها وحفظها — تشترك فيه شاشة المنح ومنتقي النموذج
/// Loads, toggles, and saves one user's grants — shared by the grant screen and the form picker.
///
/// لماذا مزود واحد بحالة «المستخدم الحالي» بدل `.family(userId)` كما اقترحت الخطة؟ لأن هذا
/// المشروع يستخدم هذا النمط أصلاً في كشف الحساب (`customerStatementProvider` يحمل المعرّف في
/// دالة التحميل)، ولا توجد شاشتا منح مفتوحتان في وقت واحد على نسختين من نفس المزود.
/// One provider holding the current user id rather than a .family(userId) as the plan sketched:
/// this app already does exactly that for statements, and two grant screens are never open at once.
class AssignPermissionsNotifier extends Notifier<AssignPermissionsState> {
  @override
  AssignPermissionsState build() => const AssignPermissionsState();

  PermissionRepository get _repo => ref.read(permissionRepositoryProvider);

  /// تحميل منح مستخدم — التحديد المبدئي من `grantedCodes` لا من `effectiveCodes`
  /// Load a user's grants — the initial selection comes from grantedCodes, not effectiveCodes.
  ///
  /// الفرق جوهري للمدير: `effectiveCodes` عنده تساوي الكتالوج كله (قرار D1 يتجاوز جدول المنح)،
  /// فلو بُني التحديد عليها لكان حفظٌ بلا تغيير = إعادة كتابة 93 سطراً في جدول المنح.
  /// The difference matters for admins: effectiveCodes is the whole catalog for them, so seeding
  /// from it would turn a no-op save into rewriting 93 grant rows.
  Future<void> load(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final grants = await _repo.fetchUserGrants(userId);
      if (grants == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'لم يُعثر على هذا المستخدم / User not found',
        );

        return;
      }

      final selected = grants.grantedCodes.toSet();
      state = state.copyWith(
        isLoading: false,
        user: grants,
        selected: selected,
        baseline: selected,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'تعذّر تحميل الصلاحيات: $e',
      );
    }
  }

  /// تهيئة من نموذج الإنشاء: لا منح بعد، والكتالوج يُعرض كله للاختيار
  /// Seed from the create form: nothing granted yet, with the whole catalog selectable.
  void seedFromForm(List<String> codes) {
    final selected = codes.toSet();
    state = state.copyWith(
      selected: selected,
      baseline: const {},
      isLoading: false,
      clearError: true,
    );
  }

  void toggle(String code) {
    final next = Set<String>.from(state.selected);
    if (!next.remove(code)) next.add(code);
    state = state.copyWith(selected: next, clearError: true);
  }

  void setCodes(Iterable<String> codes, {bool on = true}) {
    final next = Set<String>.from(state.selected);
    for (final code in codes) {
      if (on) {
        next.add(code);
      } else {
        next.remove(code);
      }
    }
    state = state.copyWith(selected: next, clearError: true);
  }

  /// سحب كل الأكواد — زر «مسح التحديد» في رأس شاشة المنح
  /// Revoke everything — the «clear selection» action in the grant screen header.
  void clearAll() => state = state.copyWith(selected: const {});

  /// حفظ الاستبدال الكامل — الخادم ذرّي: حذف ثم إدراج، وينهي جلسات المستخدم افتراضياً
  /// Save the full replacement — atomic server-side, and it ends the user's sessions by default.
  Future<AdminResult<UserGrants>> save(int userId, {bool logoutOthers = true}) async {
    if (state.isSaving) {
      return const AdminResult<UserGrants>(
        success: false,
        message: 'الحفظ جارٍ بالفعل / A save is already running',
      );
    }

    state = state.copyWith(isSaving: true, clearError: true);
    final result = await _repo.syncUserPermissions(
      userId,
      state.selected.toList(growable: false),
      logoutOthers: logoutOthers,
    );

    if (result.success) {
      // نقطة المرجع تُحدَّث إلى المرسل: الحفظ نجاحٌ حتى لو أعد الخادم ترتيب الأكواد
      // The baseline becomes what was sent — a save is a save even if the server reorders codes.
      final saved = state.selected;
      state = state.copyWith(
        isSaving: false,
        selected: saved,
        baseline: saved,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        isSaving: false,
        saveError: result.displayMessage,
      );
    }

    return result;
  }
}

final assignPermissionsProvider =
    NotifierProvider<AssignPermissionsNotifier, AssignPermissionsState>(
      AssignPermissionsNotifier.new,
    );
