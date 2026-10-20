import 'package:flutter/material.dart';
import '../../data/models/app_user_model.dart';
import 'user_form_screen.dart';

/// غلاف رفيع لشاشة التعديل — يمرّر صف المستخدم إلى نفس نموذج الإنشاء
/// A thin edit wrapper, handing the user row to the same form used for creation.
class EditUserScreen extends StatelessWidget {
  final AppUserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) => UserFormScreen(existing: user);
}
