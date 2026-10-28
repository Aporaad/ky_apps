import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/cutting_bill_summary_model.dart';
import '../widgets/tailoring_action_card.dart';
import 'cutting_bill_add_screen.dart';
import 'cutting_bill_edit_screen.dart';
import 'cutting_bill_progress_screen.dart';
import 'cutting_bills_list_screen.dart';

/// لوحة قسم التفصيل — بطاقات العمليات الأربع، كل بطاقة خلف صلاحيتها
/// The tailoring dashboard — the four action cards, each behind its own grant.
///
/// ثلاث بطاقات تحمل شارة «نموذج أولي» لأن شاشاتها قراءة فقط بلا حفظ؛ إخفاء ذلك عن
/// المستخدم يجعله يتوقع حفظاً لا يحدث.
/// Three cards carry a "prototype" chip because their screens are read-only with no save;
/// hiding that would make the user expect a save that never happens.
class TailoringDashboardScreen extends ConsumerWidget {
  const TailoringDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 16.0 : 24.0;
    final auth = ref.watch(authNotifierProvider);

    final actions = _buildActions(context, auth);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: isMobile ? 18 : 24),
          if (actions.isEmpty)
            _buildNoAccess()
          else
            LayoutBuilder(
              builder: (ctx, constraints) {
                final crossAxisCount = constraints.maxWidth < 480
                    ? 1
                    : constraints.maxWidth < 820
                    ? 2
                    : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: crossAxisCount == 1
                        ? 3.6
                        : (crossAxisCount == 2 ? 2.7 : 2.4),
                  ),
                  itemBuilder: (_, i) => actions[i],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
           Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قسم التفصيل',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'فواتير التفصيل والموديلات والمقاسات والأقمشة',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// لا صلاحيات أصلاً — رسالة صريحة بدل شبكة فارغة صامتة
  /// No grants at all — an explicit message instead of a silent empty grid.
  Widget _buildNoAccess() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child:  Column(
        children: [
          Icon(Icons.lock_outline_rounded, size: 42, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'لا تملك صلاحية على قسم التفصيل',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'راجع مدير النظام لمنحك صلاحيات قسم التفصيل',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, AuthState auth) {
    return [
      if (auth.can(Perm.tailoringView))
        TailoringActionCard(
          title: 'استعراض فاتورة',
          subtitle: 'قائمة الفواتير مع البحث والفلترة والتفاصيل',
          icon: Icons.receipt_long_rounded,
          badge: 'استعراض',
          accent: AppColors.primary,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CuttingBillsListScreen(),
            ),
          ),
        ),
      if (auth.can(Perm.tailoringCreate))
        TailoringActionCard(
          title: 'إضافة فاتورة',
          subtitle: 'نموذج كامل لإنشاء فاتورة تفصيل',
          icon: Icons.add_circle_outline_rounded,
          badge: 'إضافة',
          accent: AppColors.success,
          isPrototype: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CuttingBillAddScreen()),
          ),
        ),
      if (auth.can(Perm.tailoringUpdate))
        TailoringActionCard(
          title: 'تعديل فاتورة',
          subtitle: 'افتح فاتورة موجودة واستعرض نموذج تعديلها',
          icon: Icons.edit_note_rounded,
          badge: 'تعديل',
          accent: AppColors.info,
          isPrototype: true,
          onTap: () => _pickThenOpen(
            context,
            const CuttingBillsListScreen(mode: CuttingBillsListMode.editPicker),
            (bill) => CuttingBillEditScreen(billKey: bill.key),
          ),
        ),
      if (auth.can(Perm.tailoringProgress))
        TailoringActionCard(
          title: 'متابعة سير فاتورة',
          subtitle: 'خط سير الحالات وسجل الحركة الفعلي',
          icon: Icons.timeline_rounded,
          badge: 'متابعة',
          accent: AppColors.warning,
          isPrototype: true,
          onTap: () => _pickThenOpen(
            context,
            const CuttingBillsListScreen(
              mode: CuttingBillsListMode.progressPicker,
            ),
            (bill) => CuttingBillProgressScreen(billKey: bill.key),
          ),
        ),
      if (!auth.can(Perm.tailoringCreate) &&
          !auth.can(Perm.tailoringUpdate) &&
          !auth.can(Perm.tailoringProgress) &&
          auth.can(Perm.tailoringView))
        TailoringActionCard(
          title: 'كروت التفصيل',
          subtitle: 'كل ما هو متاح لك من قسم التفصيل',
          icon: Icons.dashboard_customize_rounded,
          badge: 'عرض',
          accent: AppColors.accent,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CuttingBillsListScreen()),
          ),
        ),
    ];
  }

  /// اختيار فاتورة من القائمة ثم فتح الشاشة المطلوبة عليها
  /// Pick a bill from the list, then open the requested screen on it.
  Future<void> _pickThenOpen(
    BuildContext context,
    Widget listScreen,
    Widget Function(CuttingBillSummary bill) buildTarget,
  ) async {
    final picked = await Navigator.of(context).push<CuttingBillSummary>(
      MaterialPageRoute(builder: (_) => listScreen),
    );

    if (picked == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => buildTarget(picked)),
    );
  }
}
