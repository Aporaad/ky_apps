import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/order_model.dart';
import '../providers/stores_providers.dart';
import '../widgets/store_ui.dart';
import 'catalogs_screen.dart';
import 'items_list_screen.dart';
import 'orders_list_screen.dart';
import 'stock_balances_screen.dart';
import 'stock_sheet_screen.dart';
import 'store_reports_screen.dart';
import 'stores_list_screen.dart';

/// لوحة قسم المخازن — الواجهة الأولى عند فتح القسم
/// The stores dashboard — the first screen when the section opens.
///
/// ── لماذا لوحة لا قائمة مباشرة؟ لأن القسم ثمانية أنظمة فرعية، وفتح واحد منها افتراضياً
///    كان سيخفي الآخرين. كل بطاقة محجوبة بصلاحيتها وحدها، والشريط العلوي يعطي صورة فورية
///    عن المخزون قبل أي نقرة.
/// ── Why a dashboard instead of a list? The module holds eight sub-systems, and opening one
///    by default would hide the rest. Each card is gated by its own grant, and the KPI strip
///    gives an instant picture before the first click.
class StoresDashboardScreen extends ConsumerWidget {
  const StoresDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final storesState = ref.watch(storesListProvider);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? 14.0 : 22.0;

    final cards = <Widget>[
      if (auth.can(Perm.storesReceivingView))
        StoreActionCard(
          icon: StoreOrderKind.receive.icon,
          title: 'أوامر التوريد',
          subtitle: 'إدخال بضاعة إلى المخزن',
          color: AppColors.success,
          onTap: () => _push(
            context,
            OrdersListScreen(kind: StoreOrderKind.receive),
          ),
        ),
      if (auth.can(Perm.storesIssuingView))
        StoreActionCard(
          icon: StoreOrderKind.issue.icon,
          title: 'أوامر الصرف',
          subtitle: 'إخراج بضاعة من المخزن',
          color: AppColors.warning,
          onTap: () =>
              _push(context, OrdersListScreen(kind: StoreOrderKind.issue)),
        ),
      if (auth.can(Perm.storesTransferView))
        StoreActionCard(
          icon: StoreOrderKind.transfer.icon,
          title: 'أوامر التحويل',
          subtitle: 'نقل بين المخازن',
          color: AppColors.info,
          onTap: () =>
              _push(context, OrdersListScreen(kind: StoreOrderKind.transfer)),
        ),
      if (auth.can(Perm.storesView))
        StoreActionCard(
          icon: Icons.warehouse_outlined,
          title: 'المخازن والأمناء',
          subtitle: 'بيانات المخازن وأمنائها',
          onTap: () => _push(context, const StoresListScreen()),
        ),
      if (auth.can(Perm.storesItemsView))
        StoreActionCard(
          icon: Icons.inventory_2_outlined,
          title: 'الأصناف',
          subtitle: 'الأصناف الرئيسية والفرعية',
          onTap: () => _push(context, const ItemsListScreen()),
        ),
      if (auth.can(Perm.storesCatalogsView) ||
          auth.can(Perm.storesCatalogsManage))
        StoreActionCard(
          icon: Icons.account_tree_outlined,
          title: 'الوحدات والمجموعات',
          subtitle: 'المجموعات · الوحدات · الفئات',
          onTap: () => _push(context, const CatalogsScreen()),
        ),
      if (auth.can(Perm.storesReportsView))
        StoreActionCard(
          icon: Icons.bar_chart_rounded,
          title: 'تقارير المخازن',
          subtitle: 'حركة الأصناف وخلاصتها',
          onTap: () => _push(context, const StoreReportsScreen()),
        ),
      if (auth.can(Perm.storesReportsView))
        StoreActionCard(
          icon: Icons.inventory_rounded,
          title: 'الأرصدة',
          subtitle: 'رصيد كل صنف في كل مخزن',
          onTap: () => _push(context, const StockBalancesScreen()),
        ),
      if (auth.can(Perm.storesStocktakeView))
        StoreActionCard(
          icon: Icons.fact_check_outlined,
          title: 'الجرد',
          subtitle: 'كشف عدّ استرشادي للطباعة',
          onTap: () => _push(context, const StockSheetScreen()),
        ),
    ];

    final activeStores =
        storesState.stores.where((store) => !store.archived).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── الترويسة ────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'المخازن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'أوامر التوريد والصرف والتحويل والأصناف والتقارير',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── مؤشرات سريعة ──────────────────────────────
          // لا دائرة تحميل دوّارة هنا: المؤشرات تُرسم بقيمها الحالية (أصفاراً قبل وصول
          // البيانات) لأن أي مؤشر غير محدَّد المدة يمنع `pumpAndSettle` في الاختبارات
          // ويُحدث وميضاً في الاستخدام العادي.
          // No indeterminate spinner here: the tiles render whatever values are known
          // (zeros before data arrives). An endless animation would break pumpAndSettle and
          // flash on every entry.
          LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 560
                    ? 2
                    : 2;
                final spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: width,
                      child: StoreKpiTile(
                        icon: Icons.warehouse_rounded,
                        label: 'مخازن فعّالة',
                        value: '${activeStores.length}',
                        hint: storesState.archivedCount > 0
                            ? '${storesState.archivedCount} أرشيفي'
                            : 'بلا مخازن أرشيفية',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StoreKpiTile(
                        icon: Icons.payments_outlined,
                        label: 'قيمة المخزون',
                        value: StoreFormat.money(storesState.totalValue),
                        hint: 'من رصيد AVVG',
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StoreKpiTile(
                        icon: Icons.groups_2_outlined,
                        label: 'أمناء المخازن',
                        value:
                            '${activeStores.fold<int>(0, (sum, store) => sum + store.keepers)}',
                        hint: 'موزّعون على المخازن',
                        color: AppColors.info,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StoreKpiTile(
                        icon: Icons.inventory_outlined,
                        label: 'أصناف في المخازن',
                        value:
                            '${activeStores.fold<int>(0, (sum, store) => sum + store.items)}',
                        hint: 'صفوف أرصدة قائمة',
                        color: AppColors.warning,
                      ),
                    ),
                    //  الرصيد السالب مؤشر إنذار: 41 صفاً سالباً موجود في القاعدة، وإخفاؤه يجعل
                    //  الفرق يظهر في الجرد كأنه عجز غير معروف السبب. الرابط يفتح الأرصدة مُصفّاة.
                    //  Negative stock is a warning KPI: 41 such rows exist and hiding them makes
                    //  the gap look unexplained during stocktaking. Tapping opens the filtered list.
                    SizedBox(
                      width: width,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: auth.can(Perm.storesReportsView)
                            ? () => _push(context, const StockBalancesScreen())
                            : null,
                        child: StoreKpiTile(
                          icon: Icons.trending_down_rounded,
                          label: 'أصناف برصيد سالب',
                          value: '${storesState.negativeCount}',
                          hint: storesState.negativeCount > 0
                              ? 'تحتاج مراجعة'
                              : 'لا أرصدة سالبة',
                          color: storesState.negativeCount > 0
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 18),

          // ─── بطاقات الأقسام ────────────────────────────
          const StoreSectionHeader(
            title: 'أقسام المخازن',
            icon: Icons.apps_rounded,
          ),
          const SizedBox(height: 10),
          if (cards.isEmpty)
            const StoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'لا توجد أقسام متاحة',
              description:
                  'لم تُمنح أي صلاحية من صلاحيات قسم المخازن. راجع مدير النظام.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1000
                    ? 3
                    : constraints.maxWidth >= 640
                    ? 2
                    : 1;
                final spacing = 10.0;
                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final card in cards)
                      SizedBox(width: width, child: card),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),

          // تذكير بقاعدة الأرشيف — تُعرض دائماً لأن غيابها يجعل الأرقام غير مفهومة
          // A permanent note about archived stores: without it the numbers mislead.
          if (storesState.archivedCount > 0)
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'المخازن الأرشيفية لا تدخل في حساب الأرصدة ولا تُنشأ عليها مستندات، '
                      'ظهورها في القوائم للتذكير فقط.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
