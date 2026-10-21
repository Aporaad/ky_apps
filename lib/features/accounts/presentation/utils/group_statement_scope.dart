/// يحدد أي وسيط "نطاق" يجب إرساله للخادم في طلب GET /accounts/group-statement،
/// وفق القاعدة المطلوبة بالضبط: أعمق مستوى مختار يفوز.
///
/// - مجموعة مختارة (groupId) ← مستوى المجموعة.
/// - بدون مجموعة لكن حساب جزئي مختار (accPart) ← مستوى الحساب الجزئي
///   (أي أن التقرير يُطبع للحساب الجزئي نفسه).
/// - حساب فرعي فقط (accSub) ← كامل شجرة الحسابات تحت هذا الفرعي.
/// - حساب رئيسي فقط (accNo) ← هذا القسم بالكامل.
/// - لا شيء ← null (يُطلب من المستخدم اختيار حساب رئيسي على الأقل).
///
/// دالة نقية بلا أي اعتماد على Flutter/الشبكة، قابلة لاختبار الوحدة مباشرة.
class StatementScope {
  final String level; // 'group' | 'sub' | 'main' | 'account'
  final int? accNo;
  final int? accSub;
  final int? accPart;
  final int? groupId;

  const StatementScope({
    required this.level,
    this.accNo,
    this.accSub,
    this.accPart,
    this.groupId,
  });

  /// الوسائط الفعلية التي تُرسل للخادم عبر GET /accounts/group-statement —
  /// تُرسل دائماً السلسلة الكاملة من الجذر حتى المستوى المحلول، لأن الخادم
  /// يحلّ الأعمق موجوداً بنفسه (`getGroupStatement`)؛ إرسال السلسلة كاملة
  /// يطابق ما يبنيته بالفعل في `AccountController::getGroupStatement` ولا
  /// يغيّر السلوك (المستوى الأعمق يفوز دائماً هناك أيضاً).
  Map<String, dynamic> toQueryParameters() => {
        if (accNo != null) 'acc_no': accNo,
        if (accSub != null) 'acc_sub': accSub,
        if (accPart != null) 'acc_part': accPart,
        if (groupId != null) 'group_id': groupId,
      };

  bool get isEmpty => level == 'none';
}

StatementScope? resolveStatementScope({
  int? accNo,
  int? accSub,
  int? accPart,
  int? groupId,
}) {
  if (groupId != null) {
    return StatementScope(
      level: 'group',
      accNo: accNo,
      accSub: accSub,
      accPart: accPart,
      groupId: groupId,
    );
  }
  if (accPart != null) {
    return StatementScope(
      level: 'sub',
      accNo: accNo,
      accSub: accSub,
      accPart: accPart,
    );
  }
  if (accSub != null) {
    return StatementScope(
      level: 'main',
      accNo: accNo,
      accSub: accSub,
    );
  }
  if (accNo != null) {
    return StatementScope(level: 'account', accNo: accNo);
  }
  return null;
}
