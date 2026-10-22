/// حجم بطاقة الاختصار — تفضيل مستخدم، لا ثابت تصميم
/// Shortcut-card size — a user preference, not a design constant.
///
/// يعيش في طبقة المجال لأن النموذج المحفوظ يحتاج قراءته وكتابته؛ والقياسات الرقمية هنا يستهلكها
/// `home_tokens` وحده. الفصل يمنع أن يعتمد `data/` على `presentation/` بسبب enum واحد.
/// It lives in the domain layer because the stored model reads and writes it; the numeric metrics
/// are consumed only by `home_tokens`. The split keeps `data/` from depending on `presentation/`
/// over a single enum.
///
/// الحجم لا يغيّر «عدد الأعمدة» مباشرة: عندما يكون العدد تلقائيًا يشتقّه من [minTile]، وعندما
/// يثبّته المستخدم يبقى الحجم مؤثرًا في الحشو والأيقونة والخط. الفصل بينهما مقصود: من يريد
/// «أربعة في الصف» لا يجب أن يخسر تكبير النص.
/// Size does not set the column count directly: when the count is automatic it is derived from
/// [minTile], and when the user pins it, size still drives padding, icon, and type. The split is
/// deliberate — asking for four per row must not silently cost larger text.
enum HomeCardSize {
  small(
    label: 'صغير',
    minTile: 120,
    ratio: 1.22,
    iconBox: 34,
    iconSize: 18,
    titleSize: 12.5,
    padding: 9,
    gap: 10,
    showCaption: false,
  ),
  medium(
    label: 'متوسط',
    minTile: 150,
    ratio: 1.12,
    iconBox: 42,
    iconSize: 21,
    titleSize: 14,
    padding: 12,
    gap: 14,
    showCaption: true,
  ),
  large(
    label: 'كبير',
    minTile: 180,
    ratio: 1,
    iconBox: 54,
    iconSize: 27,
    titleSize: 16,
    padding: 14,
    gap: 18,
    showCaption: true,
  );

  const HomeCardSize({
    required this.label,
    required this.minTile,
    required this.ratio,
    required this.iconBox,
    required this.iconSize,
    required this.titleSize,
    required this.padding,
    required this.gap,
    required this.showCaption,
  });

  final String label;
  final double minTile;

  /// نسبة العرض إلى الارتفاع: صغير أعرض قليلًا، وكبير أطول — فيتغيّر الحجم المرئي فعلًا
  /// Width-to-height ratio: small is a little wider, large is taller — so size visibly changes.
  ///
  /// بدونها كان «الحجم» يبدّل الأيقونة وحدها، لأن البطاقة مربّعة وعرضها محكوم بعدد الأعمدة.
  /// Without it, "size" only swapped the icon, because the tile was square and its width was
  /// dictated by the column count.
  final double ratio;

  final double iconBox;
  final double iconSize;
  final double titleSize;
  final double padding;
  final double gap;

  /// سطر القسم يظهر في الأحجام المتوسطة والكبيرة فقط — الصغير يحمل عنوانًا وحده
  /// The section caption shows for medium and large only; small carries the title alone.
  final bool showCaption;

  /// قراءة القيمة المخزّنة؛ أي نص غير معروف يعني المتوسط
  /// Reads a stored value; any unknown name falls back to medium.
  static HomeCardSize fromName(Object? raw) {
    final name = raw?.toString();
    for (final size in HomeCardSize.values) {
      if (size.name == name) return size;
    }

    return HomeCardSize.medium;
  }
}
