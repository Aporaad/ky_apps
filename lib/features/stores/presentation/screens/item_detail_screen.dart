import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/store_items_repository.dart';
import '../providers/items_providers.dart';
import '../widgets/store_ui.dart';
import '../widgets/sub_item_dialog.dart';
import 'item_form_screen.dart';
import 'store_reports_screen.dart';
import 'sub_item_detail_screen.dart';

/// تفصيل صنف في تبويب واحد: البيانات ثم الأصناف الفرعية بكمياتها
/// An item's detail in a single view: the header data, then its sub items with quantities.
///
/// ── لماذا تبويب واحد؟ كانت خمسة تبويبات (البيانات · الفرعية · الوحدات والأسعار · الأرصدة ·
///    الحركة) تُخفي معلومة يحتاجها المستخدم في اللحظة نفسها: «كم رصيد هذا الفرع؟» كان يعني
///    الانتقال إلى تبويب ثالث ثم العودة. الدمج يجعل الصورة كاملة في تمرير واحد، والحركة صارت
///    كشفاً قابلاً للطباعة بدل جدول مقصوص.
/// ── Why one view? Five tabs (data · subs · units/prices · balances · movement) hid information
///    the user needs at once: "how much of this branch is left?" meant switching to a third tab
///    and back. The merge puts the whole picture in one scroll, and movement became a printable
///    statement instead of a truncated table.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({
    super.key,
    required this.sanfNo,
    this.embedded = false,
  });

  final int sanfNo;

  /// تركيب داخل اللوحة الجانبية على الشاشات العريضة (بلا Scaffold ثانٍ)
  /// Mounted inside the side panel on wide screens (without a second Scaffold).
  final bool embedded;

  /// انتقال التخطيط العريض الذي تركّب هذه اللوحة
  /// The wide layout that mounts this panel.
  static const double splitBreakpoint = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(itemDetailProvider(sanfNo));
    final auth = ref.watch(authNotifierProvider);
    final canUpdate = auth.can(Perm.storesItemsUpdate);

    final body = detail.when(
      loading: () => const StoreLoading(),
      error:
          (error, _) => StoreErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(itemDetailProvider(sanfNo)),
          ),
      data: (bundle) {
        if (bundle == null) {
          return const StoreEmptyState(
            icon: Icons.search_off_rounded,
            title: 'الصنف غير موجود',
          );
        }

        return _ItemBody(sanfNo: sanfNo, bundle: bundle, embedded: embedded);
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          detail.value?.item.name ?? 'صنف $sanfNo',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // ── الإجراءات أيقونات في الشريط العلوي فقط، لا مرة هنا ومرة داخل البطاقة:
          //    تكرار الزر نفسه في موضعين يجعل المستخدم يبحث عن أيهما يضغط.
          // ── Actions live in the app bar as icons only, never also inside the card:
          //    repeating the same button in two places makes the user wonder which one to press.
          // ── كشف الحركة = تقرير «حركة صنف رئيسي» من تقارير المخازن، يُفتح بمعطياته
          //    مباشرة أقساماً لكل فرع مع أرصدتها — لا شاشة كشف موازية بقالب ثانٍ.
          // ── The statement IS the stores-reports "main item movement" template: opened
          //    with its parameters, sectioned per branch with balances — not a parallel
          //    screen with a second-class template.
          IconButton(
            tooltip: 'كشف حركة',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => StoreReportsScreen(
                          initialFilter: StoreReportFilter.forItemStatement(
                            sanfNo: sanfNo,
                            itemName: detail.value?.item.name ?? 'صنف $sanfNo',
                          ),
                        ),
                  ),
                ),
            icon: const Icon(Icons.timeline_rounded),
          ),
          if (canUpdate && detail.value != null)
            IconButton(
              tooltip: 'تعديل الصنف',
              onPressed: () => _editItem(context, ref, detail.value!.item),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: body,
    );
  }

  /// فتح نموذج التعديل ثم تحديث اللوحة والقائمة معاً
  /// Open the edit form, then refresh the panel and the list together.
  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    ItemModel item,
  ) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));

    ref.invalidate(itemDetailProvider(sanfNo));
    ref.read(itemsListProvider.notifier).refreshCurrent();
  }
}

/// جسم التفصيل — بيانات في صفوف ثنائية الخانات ثم جدول الأصناف الفرعية
/// The detail body — two-field rows, then the sub-items table.
class _ItemBody extends ConsumerWidget {
  const _ItemBody({
    required this.sanfNo,
    required this.bundle,
    required this.embedded,
  });

  final int sanfNo;
  final ItemDetail bundle;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final item = bundle.item;

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 12, 14, embedded ? 20 : 90),
      children: [
        _headerCard(context, ref, item, auth),
        const SizedBox(height: 14),
        const StoreSectionHeader(
          title: 'بيانات الصنف',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 8),
        _detailsGrid(item),
        const SizedBox(height: 16),
        _subsSection(context, ref, auth),
      ],
    );
  }

  /// رأس اللوحة: الاسم · الشارات · أزرار كشف الحركة والتعديل والإضافة
  /// The panel header: name, tags, and the statement/edit/add actions.
  Widget _headerCard(
    BuildContext context,
    WidgetRef ref,
    ItemModel item,
    dynamic auth,
  ) {
    final canUpdate = auth.can(Perm.storesItemsUpdate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!item.active)
                const StoreTag(label: 'معطّل', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StoreTag(
                label: 'كود ${item.partNo}',
                icon: Icons.qr_code_rounded,
              ),
              StoreTag(
                label: StoreFormat.qty(bundle.totalQty),
                icon: Icons.inventory_2_outlined,
                color:
                    bundle.totalQty < 0 ? AppColors.error : AppColors.success,
              ),
              // قيمة الرصيد من نفس المصدر: مجموع قيم الفروع
              // Stock value from the same source: the branches rolled up.
              StoreTag(
                label: StoreFormat.money(bundle.totalValue),
                icon: Icons.payments_outlined,
              ),
              StoreTag(
                label: '${bundle.subs.length} فرع',
                icon: Icons.account_tree_outlined,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // في التخطيط الجانبي لا يوجد شريط علوي، فتحمل اللوحة أيقوناتها بنفسها
          // In the side panel there is no app bar, so the panel carries its own icons.
          if (embedded)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'كشف حركة',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      () => Navigator.of(context).push(
                        // نفس الطريق في التخطيط العريض: القالب نفسه بمعطياته
                        // The same path on the wide layout: the very template, preset.
                        MaterialPageRoute(
                          builder:
                              (_) => StoreReportsScreen(
                                initialFilter: StoreReportFilter.forItemStatement(
                                  sanfNo: sanfNo,
                                  itemName: item.name,
                                ),
                              ),
                        ),
                      ),
                  icon: const Icon(Icons.timeline_rounded, size: 19),
                ),
                if (canUpdate)
                  IconButton(
                    tooltip: 'تعديل الصنف',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ItemFormScreen(item: item),
                        ),
                      );

                      ref.invalidate(itemDetailProvider(sanfNo));
                      ref.read(itemsListProvider.notifier).refreshCurrent();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// شبكة البيانات — **خانتان في كل صف**، وبلا كود الصنف لأنه ظاهر فوق كشارة
  /// The data grid — two fields per row, and no part number: it is already a tag up top.
  ///
  /// ── تكرار الحقل في الشاشة نفسها (شارة + خانة) يُضعف الثقة بالبقية: المستخدم يسأل أي
  ///    النسختين هي الصحيحة إن اختلفتا بصرياً.
  /// ── Repeating a field in the same screen (a tag and a cell) weakens trust in the rest:
  ///    the reader wonders which copy is authoritative.
  Widget _detailsGrid(ItemModel item) {
    final rows = <(String, String, String, String)>[
      (        
        'المجموعة الرئيسية',
        item.groupName ?? '—',
        'الرمز',
        item.sanfCode ?? '—',
      ),
      (
        'المجموعة الفرعية',
        item.typeName ?? '—',
        'الفئة',
        item.categoryName ?? '—',
      ),
      ( 'النمط', item.styleName ?? '—','الوحدة', item.unitName ?? '—',),
      (
        'سعر الشراء',
        StoreFormat.money(item.buyPrice),
        'سعر البيع',
        StoreFormat.money(item.salePrice),
        
      ),
      (
        'معامل التحويل',
        item.cap == 0 ? '1' : StoreFormat.qty(item.cap),
        'اللون الأساسي',
        item.mainColor ?? '1',
      ),
      (
        'عدد الأصناف الفرعية',
        '${bundle.subs.length}',
        'الحالة',
        item.active ? 'نشط' : 'معطّل',
        
      ),
      (
        'إجمالي الرصيد',
        StoreFormat.qty(bundle.totalQty),
        'إجمالي القيمة',
        StoreFormat.money(bundle.totalValue),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                spacing: 2,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // `child` أخيراً في استدعاء Widget — قاعدة التنسيق في المشروع
                  // `child` last in a widget invocation — the project's style rule.
                  Expanded(flex: 4, child: _field(rows[i].$1, rows[i].$2)),
                  // Container(
                  //   width: 1,
                  //   height: 1,
                  //   padding: const EdgeInsets.all(1),
                  //   margin: const EdgeInsets.symmetric(horizontal: 1,vertical: 1),
                  //   color: AppColors.border,
                  //   child: Text('|')
                  // ),
                  Expanded(flex: 2, child: _field(rows[i].$3, rows[i].$4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// خانة بعنوان وقيمة **في سطر واحد** — الطلب الصريح للمستخدم لتقليص الارتفاع
  /// A field with its label and value **on one line** — the user's explicit ask, and it
  /// halves the height of the section on a phone.
  Widget _field(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// قسم الأصناف الفرعية — الأعمدة المطلوبة: رقم الصنف · اللون · الكمية + إجراءات
  /// The sub-items section — the requested columns: number · colour · quantity, plus actions.
  Widget _subsSection(BuildContext context, WidgetRef ref, dynamic auth) {
    final canUpdate = auth.can(Perm.storesItemsUpdate);
    final canDelete = auth.can(Perm.storesItemsDelete);
    final canCreate = auth.can(Perm.storesItemsCreate);
    final subs = bundle.subs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── زر الإضافة عند عنوان القسم لا في رأس الصنف: من يضيف فرعاً يفكر في الفروع،
        //    والزر بعيد عن مكانه يجوب الشاشة بحثاً عنه.
        // ── Add sits on the section title, not the item header: whoever adds a branch is
        //    thinking about branches, and a button elsewhere makes them hunt for it.
        Row(
          children: [
            const Expanded(
              child: StoreSectionHeader(
                title: 'الأصناف الفرعية',
                icon: Icons.account_tree_outlined,
              ),
            ),
            Text(
              '${subs.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            if (canCreate)
              TextButton.icon(
                onPressed:
                    () => showSubItemDialog(context, ref, sanfNo: sanfNo),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'صنف فرعي جديد',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (subs.isEmpty)
          const StoreEmptyState(
            icon: Icons.qr_code_2_rounded,
            title: 'لا أصناف فرعية',
            description:
                'بلا صنف فرعي لا يمكن توريد الصنف أو صرفه ولا يظهر في الأرصدة.',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // ترويسة الجدول
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: _HeadCell('رقم الصنف')),
                      Expanded(flex: 3, child: _HeadCell('اللون')),
                      Expanded(flex: 2, child: _HeadCell('الكمية', end: true)),
                      SizedBox(
                        width: 96,
                        child: _HeadCell('إجراءات', end: true),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < subs.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  _subRow(context, ref, subs[i], canUpdate, canDelete),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _subRow(
    BuildContext context,
    WidgetRef ref,
    ItemSubModel sub,
    bool canUpdate,
    bool canDelete,
  ) {
    // ── السطر يفتح تفاصيل الفرع نفسه: كان يفتح شاشة الصنف الرئيسي فتُعرض بيانات الأب
    //    (فئته ونمطه وعدد فروعه) كأنها وصف الفرع.
    // ── The row opens the branch's own detail. It used to open the parent screen, so the
    //    parent's category, style and branch count were presented as if they described the branch.
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (_) =>
                      SubItemDetailScreen(sanfNo: sanfNo, sanfDno: sub.sanfDno),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${sub.sanfDno}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${sub.sizeLabel}${sub.partNo != null ? ' · ${sub.partNo}' : ''}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                // `colorLabel` تحمل الاحتياط داخلها («1» عند انعدام اللون)، فلا ?? هنا
                // colorLabel already carries its own fallback, so no ?? belongs here.
                sub.colorLabel,
                style: const TextStyle(fontSize: 11.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                StoreFormat.qty(sub.qty),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      sub.isNegative ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(
              width: 96,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'كشف حركة الفرع',
                    visualDensity: VisualDensity.compact,
                    onPressed:
                        () => Navigator.of(context).push(
                          // فرع بعينه = قالب «حركة صنف فرعي»: جدول واحد برصيد جارٍ
                          // One exact branch = the "sub item movement" template: one
                          // flat table with its running balance.
                          MaterialPageRoute(
                            builder:
                                (_) => StoreReportsScreen(
                                  initialFilter: StoreReportFilter.forBranchStatement(
                                    sanfNo: sanfNo,
                                    sanfDno: sub.sanfDno,
                                    // `sizeLabel` لا يكون فارغاً: يحمل احتياطه داخلها
                                    // sizeLabel is never empty: it carries its own fallback.
                                    branchLabel: sub.name ?? sub.sizeLabel,
                                  ),
                                ),
                          ),
                        ),
                    icon: const Icon(Icons.timeline_rounded, size: 18),
                  ),
                  if (canUpdate || canDelete)
                    PopupMenuButton<String>(
                      tooltip: 'إجراءات',
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showSubItemDialog(
                            context,
                            ref,
                            sanfNo: sanfNo,
                            sub: sub,
                          );

                          return;
                        }

                        if (value == 'delete') {
                          await confirmDeleteSubItem(
                            context,
                            ref,
                            sanfNo: sanfNo,
                            sub: sub,
                          );
                        }
                      },
                      itemBuilder:
                          (context) => [
                            if (canUpdate)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('تعديل'),
                              ),
                            if (canDelete)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                          ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// خلية ترويسة الجدول
/// A table header cell.
class _HeadCell extends StatelessWidget {
  const _HeadCell(this.label, {this.end = false});

  final String label;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}
