import 'package:flutter/material.dart';

import '../../../../home/presentation/screens/home_dashboard_screen.dart';

/// واجهة قسم الرئيسية — محوّل رفيع إلى شاشة الرئيسية
/// The home section — a thin adapter onto the home screen.
///
/// كان هذا الملف هو الشاشة نفسها (19 سطرًا تعيد `PortalSectionScaffold` بحالة فارغة). الشاشة
/// الآن في `features/home`، وهذا الملف يحفظ عقد السجل: `builder` ثابت (top-level) وباني `const`،
/// فلا يتغيّر `portalSections` ولا يُعاد بناء الأقسام بسبب مرجع دالة جديد.
/// This file used to be the screen itself (19 lines returning an empty scaffold). The screen now
/// lives in `features/home`, and this file preserves the registry's contract: a top-level const
/// builder, so `portalSections` stays untouched and sections never rebuild on a new reference.
class HomeDashboardSection extends StatelessWidget {
  const HomeDashboardSection({super.key});

  @override
  Widget build(BuildContext context) => const HomeDashboardScreen();
}
