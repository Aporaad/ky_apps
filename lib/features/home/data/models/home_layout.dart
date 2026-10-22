import '../../domain/home_card_size.dart';
import '../../domain/home_shortcut.dart';

/// تخطيط الواجهة الرئيسية لمستخدم واحد: الترتيب، وما أُظهر صراحةً، وما أُخفي صراحةً، ومظهر الشبكة
/// One user's home layout: the order, what was explicitly shown, what was explicitly hidden, and
/// the grid's appearance.
///
/// لماذا `shown` و`hidden` معًا؟ لأن لكل بطاقة وضعًا افتراضيًا مختلفًا: بطاقات التشكيلة الأولى
/// تظهر ما لم تُخفَ، وبقية الكتالوج لا تظهر إلا إن أُضيفت. لذا الحفظ **opt-out** للبطاقات
/// الافتراضية و**opt-in** لغيرها، ولا تُخزَّن قائمة بيضاء كاملة — قائمة كهذه تُجمّد المستخدم على
/// كتالوج اليوم، فلا يرى أبدًا اختصارًا أضافه إصدار قادم.
/// Why both sets? Each card has a different resting state: first-run cards show unless hidden, the
/// rest stay out until added. The layout is therefore opt-out for defaults and opt-in for the rest,
/// and no full whitelist is stored — such a list freezes the user on today's catalog, so a shortcut
/// added by a later release would never reach them.
///
/// حارس الملكية: `userId` داخل البلوب. جهاز مشترك في محلّ خياطة لا يجب أن يحمل تخصيص زميل.
/// Ownership guard: `userId` inside the blob. A shared shop device must not carry a colleague's
/// layout.
class HomeLayout {
  const HomeLayout({
    required this.userId,
    this.order = const [],
    this.shown = const {},
    this.hidden = const {},
    this.size = HomeCardSize.medium,
    this.columns = autoColumns,
  });

  /// صاحب التخطيط — يُقارَن بمعرّف الجلسة عند القراءة
  /// The owner — compared against the session's user id on read.
  final int userId;

  /// الجزء المرتّب يدويًا فقط، وليس القائمة الكاملة
  /// Only the manually ordered part, not the whole list.
  final List<String> order;

  /// بطاقات غير افتراضية أظهرها المستخدم بنفسه
  /// Non-default cards the user explicitly showed.
  final Set<String> shown;

  /// بطاقات أخفاها المستخدم بنفسه
  /// Cards the user explicitly hid.
  final Set<String> hidden;

  /// كثافة البطاقة (حشو/أيقونة/خط)
  /// Card density (padding, icon, type).
  final HomeCardSize size;

  /// عدد البطاقات في الصف: `0` تلقائي، وإلا قيمة بين 2 و6
  /// Cards per row: `0` for automatic, otherwise a value between 2 and 6.
  final int columns;

  /// النسخة 2 أضافت `size` و`cols`. النسخة 1 تُقرأ وتُرقّى بدل أن تُهمَل
  /// Version 2 added `size` and `cols`; version 1 is read and upgraded rather than discarded.
  static const int schemaVersion = 2;

  /// قيمة «تلقائي» لعدد الأعمدة
  /// The "automatic" value for the column count.
  static const int autoColumns = 0;

  /// تخطيط ما قبل القراءة: يظهره الهيكل كهيكل عظمي، فلا يهم ما فيه
  /// The pre-read layout: the shell draws a skeleton, so its contents never reach the screen.
  static const HomeLayout empty = HomeLayout(userId: 0);

  /// نسخة أول تشغيل: الافتراضي وحده، بلا أي إخفاء صريح
  /// The first-run layout: defaults only, with no explicit hiding.
  static HomeLayout firstRun(int userId) => HomeLayout(userId: userId);

  /// قراءة دفاعية: تالف أو نسخة مجهولة أو مستخدم آخر ⇒ أول تشغيل، ولا استثناء أبدًا
  /// Defensive read: corrupt, unknown version, or another user ⇒ first run, never throwing.
  factory HomeLayout.fromJson(Object? raw, {required int userId}) {
    if (raw is! Map) return HomeLayout.firstRun(userId);

    final version = _asInt(raw['v']);
    // نسخة 1 مقبولة: ترقيتها تعني القيم الافتراضية للحقلين الجديدين، لا فقدان التخصيص
    // Version 1 is accepted: upgrading it means defaults for the two new fields, not data loss.
    if (version != 1 && version != schemaVersion) {
      return HomeLayout.firstRun(userId);
    }
    if (_asInt(raw['user_id']) != userId) return HomeLayout.firstRun(userId);

    return HomeLayout(
      userId: userId,
      order: _asIds(raw['order']),
      shown: _asIds(raw['shown']).toSet(),
      hidden: _asIds(raw['hidden']).toSet(),
      size: HomeCardSize.fromName(raw['size']),
      columns: _asColumns(raw['cols']),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'user_id': userId,
    'order': order,
    'shown': shown.toList(growable: false),
    'hidden': hidden.toList(growable: false),
    'size': size.name,
    'cols': columns,
  };

  HomeLayout copyWith({
    List<String>? order,
    Set<String>? shown,
    Set<String>? hidden,
    HomeCardSize? size,
    int? columns,
    int? userId,
  }) {
    return HomeLayout(
      userId: userId ?? this.userId,
      order: order ?? this.order,
      shown: shown ?? this.shown,
      hidden: hidden ?? this.hidden,
      size: size ?? this.size,
      columns: columns ?? this.columns,
    );
  }

  /// هل البطاقة ظاهرة بموجب التخطيط وحده (بلا نظر إلى الصلاحيات)؟
  /// Whether the card is visible under this layout alone (permissions aside).
  bool isVisible(HomeShortcut shortcut) {
    if (shortcut.pinned) return true;
    if (hidden.contains(shortcut.id)) return false;

    return shortcut.defaultOn || shown.contains(shortcut.id);
  }

  /// الترتيب الفعلي = ترتيب المستخدم ثم بقية الكتالوج، بلا غير الظاهر — دالة نقية
  /// Effective order = the user's order, then the rest of the catalog, minus invisible entries.
  ///
  /// معرّف لم يعد في الكتالوج يُهمَل بلا أثر، والمكرّر لا يتكرّر. النتيجة تُرشَّح بالصلاحيات
  /// خارج هذا النموذج، وقت العرض.
  /// An id that left the catalog is dropped silently and duplicates never repeat. The result is
  /// permission-filtered outside this model, at render time.
  List<HomeShortcut> resolve(List<HomeShortcut> catalog) {
    final byId = {for (final shortcut in catalog) shortcut.id: shortcut};
    final seen = <String>{};
    final ordered = <HomeShortcut>[];

    for (final id in order) {
      final shortcut = byId[id];
      if (shortcut != null && seen.add(id)) ordered.add(shortcut);
    }
    for (final shortcut in catalog) {
      if (seen.add(shortcut.id)) ordered.add(shortcut);
    }

    return [
      for (final shortcut in ordered)
        if (isVisible(shortcut)) shortcut,
    ];
  }

  /// [value] كعدد صحيح — الخادم و`jsonDecode` قد يعيدان نصًّا
  /// [value] as an int — the server and `jsonDecode` may hand back text.
  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value == null) return null;

    return int.tryParse(value.toString());
  }

  /// عدد أعمدة صالح أو «تلقائي» — أي قيمة خارج المدى تعود تلقائية بدل أن تكسر الشبكة
  /// A valid column count or "automatic" — an out-of-range value falls back rather than breaking
  /// the grid.
  static int _asColumns(Object? value) {
    final parsed = _asInt(value);
    if (parsed == null) return autoColumns;
    if (parsed < 2 || parsed > 6) return autoColumns;

    return parsed;
  }

  /// قائمة معرّفات منظّفة: نصوص فقط، بلا فراغات، بلا تكرار، وبالترتيب
  /// A cleaned id list: strings only, no blanks, no duplicates, order preserved.
  static List<String> _asIds(Object? raw) {
    if (raw is! List) return const [];

    final seen = <String>{};
    final ids = <String>[];
    for (final item in raw) {
      if (item == null) continue;
      final id = item.toString().trim();
      if (id.isEmpty) continue;
      if (seen.add(id)) ids.add(id);
    }

    return ids;
  }
}
