import 'package:flutter/material.dart';

/// إلى أين تذهب بطاقة الاختصار
/// Where a shortcut card leads.
///
/// مختوم لأنه يُستهلك في `switch` واحد بلا فرع افتراضي: إضافة نوع هدف جديد تُفشل التحليل حتى
/// يُعالَج، بدل أن تسقط البطاقة صامتة في `else`.
/// Sealed because it is consumed by a single exhaustive `switch`: adding a target type breaks the
/// build until it is handled, instead of dropping the card silently into an `else`.
sealed class HomeShortcutTarget {
  const HomeShortcutTarget();
}

/// قسم داخل البوابة — يتغيّر `IndexedStack` ولا تُدفع شاشة
/// A portal section — the `IndexedStack` moves, no screen is pushed.
class SectionTarget extends HomeShortcutTarget {
  const SectionTarget(this.sectionId);

  final String sectionId;
}

/// شاشة تُدفع أمرِيًّا بالعُرف القائم في المشروع (`Navigator.push`)
/// A screen pushed imperatively, following the project's established convention.
class ScreenTarget extends HomeShortcutTarget {
  const ScreenTarget(this.build);

  /// مرجع بنّاء (`AllCustomersScreen.new`) لا كلاشر، ليبقى الكتالوج `const`
  /// A constructor reference (`AllCustomersScreen.new`), not a closure, so the catalog stays const.
  final Widget Function() build;
}

/// مسار GoRouter قائم — لا مسار جديد يُضاف من أجل الاختصارات
/// An existing GoRouter route — no new route is added for shortcuts.
class RouteTarget extends HomeShortcutTarget {
  const RouteTarget(this.location);

  final String location;
}

/// تدفّق متعدد الخطوات: منتقي ثم شاشة، بنفس نمط بطاقات لوحة الإدارة
/// A multi-step flow: picker then screen, the same shape as the admin dashboard cards.
class FlowTarget extends HomeShortcutTarget {
  const FlowTarget(this.run);

  final Future<void> Function(BuildContext context) run;
}

/// اختصار واحد في الواجهة الرئيسية
/// One shortcut on the home screen.
///
/// الوصف لا يحمل عنوان القسم: العنوان يُقرأ من `PortalSectionTitles` بمعرّف [sectionId]، فلا
/// يوجد عنوان قسم مكتوب مرتين في المشروع.
/// The spec carries no section title: it is read from `PortalSectionTitles` by [sectionId], so no
/// section title is written twice in this project.
class HomeShortcut {
  const HomeShortcut({
    required this.id,
    required this.title,
    required this.icon,
    required this.sectionId,
    required this.target,
    this.codes = const [],
    this.defaultOn = false,
    this.underDevelopment = false,
    this.pinned = false,
  });

  /// معرّف ASCII ثابت (`customers.statement`) — مفتاح التخزين ومفتاح الاختبارات
  /// Stable ASCII id (`customers.statement`) — the storage key and the test key.
  final String id;

  /// عنوان البطاقة كما يقرأه الموظف
  /// The card title as the employee reads it.
  final String title;

  final IconData icon;

  /// معرّف القسم في السجل: للتجميع والتصفية وسطر القسم، لا للتحقق من الصلاحية
  /// The registry section id: for grouping, filtering, and the caption — not for permission checks.
  final String sectionId;

  final HomeShortcutTarget target;

  /// أكواد IBAC: يكفي واحد منها؛ والقائمة الفارغة تعني بلا شرط (كالتخصيص والإعدادات)
  /// IBAC codes: any one is enough; an empty list means ungated (customise, local settings).
  final List<String> codes;

  /// هل يدخل التشكيلة الافتراضية؟ (13 بطاقة عند مدير النظام)
  /// Whether it joins the first-run layout (13 tiles for a system admin).
  final bool defaultOn;

  /// القسم الذي يفتحه ما يزال حالة فارغة — تُرسم شارة «قيد التطوير» بصدق
  /// The section behind it is still an empty state — the card says so with a badge.
  final bool underDevelopment;

  /// لا يُخفى ولا يُرتّب (بطاقة التخصيص): مخرج الطوارئ من تخصيص خاطئ
  /// Never hidden nor reordered (the customise tile): the way out of a bad layout.
  final bool pinned;

  /// بلا شرط صلاحية — يُعرض لكل من يدخل البوابة
  /// Ungated — shown to whoever reaches the portal.
  bool get ungated => codes.isEmpty;
}
