import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/portal_sections.dart';

/// قائمة جانبية تفاعلية قابلة للتوسيع والطي (Expand / Collapse)
/// Collapsible Side Navigation Drawer with Arabic RTL support
///
/// القائمة تأتي من الخارج (`sections`) ولا يعلن هذا الودجت أي عنوان أو أيقونة بنفسه: السجل
/// المركزي هو صاحب القرار، وهو من يُصفّى حسب الصلاحيات قبل أن يصل إلى هنا.
/// The list arrives from outside: this widget declares no titles or icons of its own. The central
/// registry owns them and is already filtered by permission before it gets here.
class CollapsibleSideDrawer extends StatelessWidget {
  final List<PortalSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;
  final String employeeName;

  final bool isDrawerMode;

  const CollapsibleSideDrawer({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onLogout,
    required this.employeeName,
    this.isDrawerMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = isDrawerMode ? double.infinity : (isCollapsed ? 76.0 : 250.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'الكبودي للخياطة الرجالية',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  onPressed:
                      isDrawerMode
                          ? () => Navigator.of(context).maybePop()
                          : onToggleCollapse,
                  icon: Icon(
                    isDrawerMode
                        ? Icons.close_rounded
                        : (isCollapsed
                            ? Icons.keyboard_double_arrow_left_rounded
                            : Icons.keyboard_double_arrow_right_rounded),
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  tooltip:
                      isDrawerMode
                          ? 'إغلاق القائمة'
                          : (isCollapsed ? 'توسيع القائمة' : 'طي القائمة'),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final item = sections[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: () {
                      onIndexChanged(index);
                      if (isDrawerMode) {
                        Navigator.of(context).maybePop();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            isCollapsed
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                          ),
                          if (!isCollapsed) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    employeeName.isNotEmpty ? employeeName[0] : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'موظف ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    tooltip: 'تسجيل الخروج',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
