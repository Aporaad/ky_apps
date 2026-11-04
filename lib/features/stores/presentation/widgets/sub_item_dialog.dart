import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/item_model.dart';
import '../providers/items_providers.dart';
import '../providers/stores_providers.dart';
import 'store_ui.dart';

/// حوار الأصناف الفرعية — إنشاء وتعديل بنفس الحقول، مشترك بين الشاشتين
/// The sub-item dialog — create and edit share one form, used by both screens.
///
/// ── لماذا ودالة واحدة لا نسخة في كل شاشة؟ لأن النسخة المكررة تنحرف: شاشة تعدّل اللون بقائمة
///    وشاشة تكتبه رقماً، فيختلف السلوك لنفس الكيان. مصدر واحد يعني سلوكاً واحداً.
/// ── Why one function instead of a copy per screen? Copies drift: one screen would pick the
///    colour from a list and the other would type a number, so the same entity behaves twice.
///    One source means one behaviour.
Future<bool> showSubItemDialog(
  BuildContext context,
  WidgetRef ref, {
  required int sanfNo,
  ItemSubModel? sub,
}) async {
  final reference = ref.read(storeReferenceProvider).value;

  final barcode = TextEditingController(text: sub?.barcode ?? '');
  final len = TextEditingController(text: StoreFormat.qty(sub?.len ?? 0));
  final wid = TextEditingController(text: StoreFormat.qty(sub?.wid ?? 0));
  final price = TextEditingController(
    text: (sub?.price ?? 0).toStringAsFixed(2),
  );

  var colorNo = sub?.colorNo ?? 0;
  String? error;
  var saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder:
              (context, setLocal) => AlertDialog(
                title: Text(
                  sub == null ? 'صنف فرعي جديد' : 'تعديل الصنف الفرعي',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sub != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StoreTag(label: 'رقم الفرع ${sub.sanfDno}'),
                        ),
                      TextField(
                        controller: barcode,
                        decoration: const InputDecoration(
                          labelText: 'الباركود',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: len,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الطول',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: wid,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'العرض',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // اللون من `SANFS_COLOR` لا بكتابة رقم: رقم لون خاطئ يظهر كـ«لون 7» بلا معنى
                      // The colour comes from SANFS_COLOR, not a typed number: a wrong id renders as a
                      // meaningless "colour 7" on every screen that shows the branch.
                      if (reference != null && reference.colors.isNotEmpty)
                        DropdownButtonFormField<int>(
                          value:
                              reference.colors.any(
                                    (row) => row.colorNo == colorNo,
                                  )
                                  ? colorNo
                                  : 0,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'اللون',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('بلا لون'),
                            ),
                            for (final color in reference.colors)
                              DropdownMenuItem(
                                value: color.colorNo,
                                child: Text(
                                  color.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged:
                              (value) => setLocal(() => colorNo = value ?? 0),
                        )
                      else
                        TextField(
                          controller: TextEditingController(
                              text: colorNo.toString(),
                            )
                            ..selection = TextSelection.collapsed(
                              offset: colorNo.toString().length,
                            ),
                          keyboardType: TextInputType.number,
                          onChanged:
                              (value) => colorNo = int.tryParse(value) ?? 0,
                          decoration: const InputDecoration(
                            labelText: 'رقم اللون',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'السعر',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving
                            ? null
                            : () => Navigator.pop(dialogContext, false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed:
                        saving
                            ? null
                            : () async {
                              setLocal(() {
                                saving = true;
                                error = null;
                              });

                              final payload = <String, dynamic>{
                                'barcode': barcode.text.trim(),
                                'len': double.tryParse(len.text.trim()) ?? 0,
                                'wid': double.tryParse(wid.text.trim()) ?? 0,
                                'color_no': colorNo,
                                'price':
                                    double.tryParse(price.text.trim()) ?? 0,
                              };

                              final repository = ref.read(
                                storeItemsRepositoryProvider,
                              );
                              final result =
                                  sub == null
                                      ? await repository.createSub(
                                        sanfNo,
                                        payload,
                                      )
                                      : await repository.updateSub(
                                        sanfNo,
                                        sub.sanfDno,
                                        payload,
                                      );

                              if (!dialogContext.mounted) return;

                              if (result.success) {
                                Navigator.pop(dialogContext, true);

                                return;
                              }

                              setLocal(() {
                                saving = false;
                                error = result.displayMessage;
                              });
                            },
                    child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ'),
                  ),
                ],
              ),
        ),
  );

  barcode.dispose();
  len.dispose();
  wid.dispose();
  price.dispose();

  if (saved != true) return false;

  // التحديث بعد النجاح: اللوحة والقائمة كلاهما يقرأ من نفس المزود
  // Refresh after success: the panel and the list both read the same provider.
  ref.invalidate(itemDetailProvider(sanfNo));
  ref.read(itemsListProvider.notifier).refreshCurrent();

  return true;
}

/// تأكيد حذف صنف فرعي — الحذف فيزيائي والحركة تمنعه
/// Confirming a branch delete — physical, and blocked when movement exists.
Future<bool> confirmDeleteSubItem(
  BuildContext context,
  WidgetRef ref, {
  required int sanfNo,
  required ItemSubModel sub,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: const Text('حذف صنف فرعي'),
          content: Text(
            'سيُحذف الفرع ${sub.sanfDno} نهائياً. '
            'لا يمكن حذف فرع له حركة مخزنية — عطّله بدلاً من حذفه.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
  );

  if (confirmed != true) return false;

  final result = await ref
      .read(storeItemsRepositoryProvider)
      .deleteSub(sanfNo, sub.sanfDno);

  if (!context.mounted) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.success ? 'تم حذف الصنف الفرعي' : result.displayMessage,
      ),
      backgroundColor: result.success ? AppColors.success : AppColors.error,
    ),
  );

  if (result.success) {
    ref.invalidate(itemDetailProvider(sanfNo));
    ref.read(itemsListProvider.notifier).refreshCurrent();
  }

  return result.success;
}
