import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/home_layout.dart';
import '../../data/repositories/home_layout_repository.dart';
import '../../domain/home_shortcut.dart';
import '../../domain/home_shortcut_catalog.dart';

/// مستودع تخطيط الرئيسية — يعتمد التخزين الآمن وحده
/// The home-layout repository — depends on secure storage alone.
final homeLayoutRepositoryProvider = Provider<HomeLayoutRepository>((ref) {
  return HomeLayoutRepository(storage: ref.watch(secureStorageProvider));
});

/// حالة تخطيط الرئيسية
/// Home-layout state.
class HomeLayoutState {
  const HomeLayoutState({
    required this.layout,
    this.loading = false,
    this.saveFailed = false,
  });

  final HomeLayout layout;

  /// القراءة الأولى من التخزين جارية — الهيكل يرسم هيكلًا عظميًا
  /// The first read from storage is in flight — the shell draws a skeleton.
  final bool loading;

  /// آخر كتابة فشلت؛ التخطيط في الذاكرة ما يزال صالحًا لهذه الجلسة
  /// The last write failed; the in-memory layout is still valid for this session.
  final bool saveFailed;

  HomeLayoutState copyWith({
    HomeLayout? layout,
    bool? loading,
    bool? saveFailed,
  }) {
    return HomeLayoutState(
      layout: layout ?? this.layout,
      loading: loading ?? this.loading,
      saveFailed: saveFailed ?? this.saveFailed,
    );
  }
}

/// إدارة تخطيط الرئيسية: تحميل، إخفاء/إظهار، ترتيب، واستعادة الافتراضي
/// Home-layout management: load, hide/show, reorder, and reset.
class HomeLayoutNotifier extends Notifier<HomeLayoutState> {
  late final HomeLayoutRepository _repository;

  /// سلسلة كتابة واحدة: نقرتان سريعتان لا تكتبان فوق بعضهما بترتيب مقلوب
  /// One write chain: two quick taps never write over each other out of order.
  Future<void> _writeChain = Future<void>.value();

  bool _alive = true;

  /// عدّاد تعديلات المستخدم: قراءة تخزين بدأت قبل النقرة لا يجوز أن تدهسها بعدها
  /// A user-edit counter: a storage read that started before the tap must not overwrite it after.
  int _revision = 0;

  @override
  HomeLayoutState build() {
    _repository = ref.read(homeLayoutRepositoryProvider);
    _alive = true;
    ref.onDispose(() => _alive = false);
    // لا `await` في `build` — نمط المشروع: الحالة الابتدائية فورًا والتحميل لاحقًا
    // No `await` in `build` — the project's pattern: initial state now, load later.
    Future<void>.microtask(load);

    return const HomeLayoutState(layout: HomeLayout.empty, loading: true);
  }

  /// الاختصارات المرئية الآن: الكتالوج ∩ المنح ∩ التخطيط
  /// The shortcuts visible right now: catalog ∩ grants ∩ layout.
  List<HomeShortcut> get activeShortcuts {
    final auth = ref.read(authNotifierProvider);

    return state.layout.resolve(
      allowedHomeShortcuts(granted: auth.permissions, isAdmin: auth.isAdmin),
    );
  }

  /// القراءة الأولى: بلا مستخدم معرّف لا يوجد ما يُحمَّل، وبلا استثناء
  /// The first read: without a user id there is nothing to load, and no exception either.
  Future<void> load() async {
    final revision = _revision;
    try {
      final userId = ref.read(authNotifierProvider).user?.id;
      if (userId == null) {
        if (_alive) state = state.copyWith(loading: false);

        return;
      }

      final layout = await _repository.load(userId);
      if (!_alive || revision != _revision) return;
      state = HomeLayoutState(layout: layout);
    } catch (_) {
      // التخزين غير متاح على هذه المنصة؟ الافتراضي يعمل، والتخصيص يبقى في الذاكرة
      // Storage unavailable on this platform? Defaults still work; customisation stays in memory.
      if (_alive) state = state.copyWith(loading: false);
    }
  }

  /// إخفاء بطاقة ظاهرة أو إظهار بطاقة مخفية — البطاقة المثبّتة لا تتغيّر
  /// Hides a visible card or shows a hidden one — the pinned card never changes.
  Future<void> toggle(String id) async {
    final shortcut = _shortcutById(id);
    if (shortcut == null || shortcut.pinned) return;

    final layout = state.layout;
    final shown = {...layout.shown};
    final hidden = {...layout.hidden};

    if (layout.isVisible(shortcut)) {
      hidden.add(id);
      shown.remove(id);
    } else if (shortcut.defaultOn) {
      // إعادة بطاقة افتراضية إلى وضعها الأصلي: تكفي إزالتها من `hidden`، ولا حاجة لتسجيلها
      // في `shown` — وإلا امتلأ المخزون بمعرّفات لا تعني شيئًا.
      // Restoring a default card to its resting state only needs the `hidden` removal; recording
      // it in `shown` too would fill storage with ids that mean nothing.
      hidden.remove(id);
      shown.remove(id);
    } else {
      shown.add(id);
      hidden.remove(id);
    }

    await _persist(layout.copyWith(shown: shown, hidden: hidden));
  }

  /// إعادة ترتيب المفعّلة: تُكتب كاملة ثم يتبعها ما كان مخفيًا بترتيبه القديم
  /// Reorders the active list: written whole, then whatever was hidden follows in its old order.
  ///
  /// كتابة القائمة كاملة مقصودة: كتابة زوج متبادل فقط تُنتج ترتيبًا لا يُعاد إنتاجه بعد إخفاء
  /// بطاقة وإظهارها. وما كان مخفيًا يبقى في الذيل حتى لا يفقد موضعه عند إظهاره لاحقًا.
  /// Writing the whole list is deliberate: swapping a pair alone yields an order that cannot be
  /// reproduced after hiding and re-showing a card. Hidden entries stay at the tail so they keep
  /// their place when shown again.
  Future<void> move(int oldIndex, int newIndex) async {
    final active = activeShortcuts;
    if (oldIndex < 0 || oldIndex >= active.length) return;
    if (newIndex < 0 || newIndex > active.length) return;
    if (oldIndex == newIndex) return;

    final ids = [for (final shortcut in active) shortcut.id];
    final moved = ids.removeAt(oldIndex);
    final target = (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(
      0,
      ids.length,
    );
    ids.insert(target, moved);

    final tail = state.layout.order.where((id) => !ids.contains(id));
    await _persist(state.layout.copyWith(order: [...ids, ...tail]));
  }

  /// استعادة الافتراضي: التشكيلة الأولى وحدها، بلا إخفاء ولا ترتيب مخصص
  /// Restores the default: the first-run set only, with no hiding and no custom order.
  Future<void> reset() async {
    final userId = _userId();
    if (userId == null) return;

    await _persist(HomeLayout.firstRun(userId));
  }

  /// حفظ متفائل: الحالة أولًا، والكتابة في الخلفية، والفشل يُعلَن لا يُخفى
  /// Optimistic save: state first, write in the background, and a failure is reported, not hidden.
  Future<void> _persist(HomeLayout next) async {
    // بلوب بلا مالك يرفضه القارئ في الجلسة التالية، فلا يُكتب من الأصل
    // An ownerless blob is rejected by the next read, so it is never written at all.
    final owner = next.userId != 0 ? next.userId : _userId();
    final layout =
        owner == null
            ? next
            : HomeLayout(
              userId: owner,
              order: next.order,
              shown: next.shown,
              hidden: next.hidden,
            );

    _revision++;
    state = state.copyWith(layout: layout, loading: false, saveFailed: false);
    if (owner == null) return;

    _writeChain = _writeChain.then((_) async {
      try {
        await _repository.save(layout);
      } catch (_) {
        if (_alive) state = state.copyWith(saveFailed: true);
      }
    });

    await _writeChain;
  }

  HomeShortcut? _shortcutById(String id) {
    for (final shortcut in homeShortcutCatalog) {
      if (shortcut.id == id) return shortcut;
    }

    return null;
  }

  int? _userId() {
    final fromLayout = state.layout.userId;
    if (fromLayout != 0) return fromLayout;

    return ref.read(authNotifierProvider).user?.id;
  }
}

final homeLayoutNotifierProvider =
    NotifierProvider<HomeLayoutNotifier, HomeLayoutState>(
      HomeLayoutNotifier.new,
    );
