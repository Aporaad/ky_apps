import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/permission_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/item_model.dart';
import '../providers/items_providers.dart';
import '../widgets/store_ui.dart';
import '../widgets/sub_item_dialog.dart';
import 'item_detail_screen.dart';
import 'item_movement_screen.dart';

/// استعراض صنف فرعي — تفاصيل الفرع وحده، لا تفاصيل أصنه الأب
/// A sub item screen — the branch's own details, never its parent's.
///
/// ── العطل الذي تُصلحه هذه الشاشة: النقر على فرع كان يفتح `ItemDetailScreen` فيعرض بيانات
///    الصنف الرئيسي (فئته، وحدته، أنماطه، عدد فروعه) بينما المستخدم يسأل عن **الفرع**:
///    باركوده ومقاسه ولونه وسعره ورصيده. شاشة لكيانين مختلفين تعني أن أحدهما يُعرض خطأ.
/// ── The defect this screen fixes: tapping a branch opened ItemDetailScreen and showed the
///    parent's data (its category, unit, style, branch count) while the question was about the
///    branch — its barcode, size, colour, price and balance. One screen for two entities means
///    one of them is always shown wrong.
class SubItemDetailScreen extends ConsumerWidget {
  const SubItemDetailScreen({
    super.key,
    required this.sanfNo,
    required this.sanfDno,
  });

  final int sanfNo;
  final int sanfDno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(itemDetailProvider(sanfNo));
    final auth = ref.watch(authNotifierProvider);
    final canUpdate = auth.can(Perm.storesItemsUpdate);
    final canDelete = auth.can(Perm.storesItemsDelete);

    final sub =
        detail.value?.subs.where((row) => row.sanfDno == sanfDno).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // العنوان الفرع نفسه، لا اسمه التجاري فقط: رقم الفرع هو ما يميّزه عن إخوته
        // The branch itself as the title, not just its trade name: the id separates it.
        title: Text(
          sub == null ? 'فرع $sanfDno' : (sub.name ?? 'فرع $sanfDno'),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'كشف حركة الفرع',
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => ItemMovementScreen(
                          sanfNo: sanfNo,
                          itemName: sub?.parentName ?? 'صنف $sanfNo',
                          subDno: sanfDno,
                          subLabel: sub?.name ?? sub?.sizeLabel,
                        ),
                  ),
                ),
            icon: const Icon(Icons.timeline_rounded),
          ),
          if (canUpdate && sub != null)
            IconButton(
              tooltip: 'تعديل الفرع',
              onPressed:
                  () =>
                      showSubItemDialog(context, ref, sanfNo: sanfNo, sub: sub),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canDelete && sub != null)
            IconButton(
              tooltip: 'حذف الفرع',
              onPressed:
                  () => confirmDeleteSubItem(
                    context,
                    ref,
                    sanfNo: sanfNo,
                    sub: sub,
                  ).then((deleted) {
                    if (deleted && context.mounted) Navigator.pop(context);
                  }),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: detail.when(
        loading: () => const StoreLoading(),
        error:
            (error, _) => StoreErrorState(
              message: error.toString(),
              onRetry: () => ref.invalidate(itemDetailProvider(sanfNo)),
            ),
        data: (bundle) {
          if (bundle == null || sub == null) {
            return const StoreEmptyState(
              icon: Icons.qr_code_2_rounded,
              title: 'الصنف الفرعي غير موجود',
              description: 'ربما حُذف هذا الفرع أو انتقل إلى صنف آخر.',
            );
          }

          return _BranchBody(sanfNo: sanfNo, sub: sub);
        },
      ),
    );
  }
}

/// جسم تفاصيل الفرع — رأس ثم شبكة بخانتين في الصف، بلا أي حقل من أبيه
/// The branch body: a header, then a two-field grid. No parent fields at all.
class _BranchBody extends StatelessWidget {
  const _BranchBody({required this.sanfNo, required this.sub});

  final int sanfNo;
  final ItemSubModel sub;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        _headerCard(context),
        const SizedBox(height: 14),
        const StoreSectionHeader(
          title: 'بيانات الصنف الفرعي',
          icon: Icons.qr_code_2_rounded,
        ),
        const SizedBox(height: 8),
        _detailsGrid(context),
      ],
    );
  }

  Widget _headerCard(BuildContext context) {
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
                  sub.name ?? 'فرع ${sub.sanfDno}',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!sub.active)
                const StoreTag(label: 'معطّل', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StoreTag(label: 'فرع ${sub.sanfDno}', icon: Icons.tag_rounded),
              StoreTag(
                label: StoreFormat.qty(sub.qty),
                icon: Icons.inventory_2_outlined,
                color: sub.isNegative ? AppColors.error : AppColors.success,
              ),
              StoreTag(
                label: StoreFormat.money(sub.value),
                icon: Icons.payments_outlined,
              ),
              StoreTag(
                label: sub.colorLabel,
                icon: Icons.palette_outlined,
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ── كل خانة هنا عمود في `SANFS_D` أو رصيد الفرع: لا مجموعة رئيسية ولا نمط ولا عدد فروع،
  ///    لأن تلك حقول الأب وقد كانت تُعرض سابقاً فتُقرأ كأنها وصف الفرع.
  /// ── Every field is a SANFS_D column or the branch's own balance: no main group, no style,
  ///    no branch count — those are the parent's columns and were shown as if they described
  ///    the branch.
  Widget _detailsGrid(BuildContext context) {
    final rows = <(String, String, String, String)>[
      ('رقم الصنف الفرعي', '${sub.sanfDno}', 'الرمز', sub.code ?? '—'),
      ('الكود', sub.partNo ?? '—', 'الباركود', sub.barcode ?? '—'),
      ('الطول', StoreFormat.qty(sub.len), 'العرض', StoreFormat.qty(sub.wid)),
      ('اللون', sub.colorLabel, 'السعر', StoreFormat.money(sub.price)),
      (
        'العبوة',
        sub.cap == 0 ? '1' : StoreFormat.qty(sub.cap),
        'الوحدة',
        sub.unitName ?? '—',
      ),
      (
        'الرصيد',
        StoreFormat.qty(sub.qty),
        'قيمة الرصيد',
        StoreFormat.money(sub.value),
      ),
      ('الحالة', sub.active ? 'نشط' : 'معطّل', 'التصنيف', sub.category ?? '—'),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _field(rows[i].$1, rows[i].$2)),
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.border,
                  ),
                  Expanded(child: _field(rows[i].$3, rows[i].$4)),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.border),
          // الصنف الأب يُعرض كرابط وصول لا كبيان من بيانات الفرع
          // The parent is a navigation link, never a field of the branch.
          InkWell(
            onTap:
                () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailScreen(sanfNo: sanfNo),
                  ),
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الصنف الرئيسي: ${sub.parentName ?? 'صنف $sanfNo'}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// خانة بعنوان وقيمة في سطر واحد — كما في شاشة الصنف الرئيسي
  /// A field with label and value on one line, matching the main item screen.
  Widget _field(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
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
}
