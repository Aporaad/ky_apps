import 'package:flutter/material.dart';
import 'user_form_screen.dart';

/// غلاف رفيع لشاشة الإنشاء — بنفس نمط `add_customer_screen.dart`
/// A thin create wrapper, matching the shape of add_customer_screen.dart.
///
/// يبقى الغلاف منفصلاً لأن شاشة العملاء تفعل ذلك: أي استدعاء خارجي (`AddUserScreen()`) يظل
/// صحيحاً لو تغيّر النموذج الداخلي لاحقاً، بدل تعديل كل نقطة استدعاء.
/// The wrapper stays separate because the customers feature does the same: external call sites
/// keep working if the underlying form changes, without touching every call site.
class AddUserScreen extends StatelessWidget {
  const AddUserScreen({super.key});

  @override
  Widget build(BuildContext context) => const UserFormScreen();
}
