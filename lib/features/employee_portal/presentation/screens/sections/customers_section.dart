import 'package:flutter/material.dart';
import '../../../../../features/customers/presentation/screens/customers_dashboard_screen.dart';

/// واجهة قسم العملاء - تعرض لوحة تحكم العملاء الكاملة
class CustomersSection extends StatelessWidget {
  const CustomersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomersDashboardScreen();
  }
}
