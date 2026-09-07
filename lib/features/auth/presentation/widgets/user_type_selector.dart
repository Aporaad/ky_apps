import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// زر تبديل تفاعلي لاختيار نوع المستخدم (موظف / عميل)
/// Interactive toggle selector between Employee and Customer user types
class UserTypeSelector extends StatelessWidget {
  final String selectedType; // 'employee' أو 'customer'
  final ValueChanged<String> onTypeChanged;

  const UserTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeItem(
              context: context,
              type: 'employee',
              title: 'بوابة الموظف',
              icon: Icons.badge_outlined,
              isSelected: selectedType == 'employee',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeItem(
              context: context,
              type: 'customer',
              title: 'بوابة العميل',
              icon: Icons.person_outline,
              isSelected: selectedType == 'customer',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeItem({
    required BuildContext context,
    required String type,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onTypeChanged(type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
