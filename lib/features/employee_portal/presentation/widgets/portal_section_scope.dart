import 'package:flutter/widgets.dart';

/// قناة داخلية تسمح لأي قسم بأن يطلب الانتقال إلى قسم آخر دون أن يعرف هيكل البوابة
/// An internal channel letting any section ask to switch to another without knowing the shell.
///
/// الرافعة المطلوبة واحدة: مؤشر `IndexedStack` يعيش داخل حالة `EmployeeMainLayout`، فبطاقة في
/// الرئيسية لا تستطيع تغييره بنفسها. تمرير دالة واحدة عبر الشجرة أرخص من نقل «الموضع» إلى مزوّد،
/// ويُبقي الملكية حيث كانت: الهيكل وحده يقرّر أي قسم يُعرض.
/// Only one lever is needed: the `IndexedStack` index lives in `EmployeeMainLayout`'s state, so a
/// home tile cannot change it alone. Passing one callback down is cheaper than lifting "position"
/// into a provider, and leaves ownership where it was: the shell decides which section is shown.
class PortalSectionScope extends InheritedWidget {
  const PortalSectionScope({
    required this.openSection,
    required super.child,
    super.key,
  });

  /// يطلب عرض القسم بمعرّفه؛ والهيكل يتحقق من صلاحية الظهور قبل الاستجابة
  /// Requests the section with this id; the shell re-checks visibility before obeying.
  final void Function(String sectionId) openSection;

  static PortalSectionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PortalSectionScope>();

  @override
  bool updateShouldNotify(PortalSectionScope oldWidget) =>
      oldWidget.openSection != openSection;
}
